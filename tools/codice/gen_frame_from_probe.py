# -*- coding: utf-8 -*-
"""Convierte una captura de HarfordFrameProbe en Lua que RECREA ese frame.

Motivo: reproducir a mano un frame nativo mirando un volcado lleva a rellenar huecos a ojo.
Con la sonda ampliada (cada objeto tiene `uid` y cada anclaje guarda `relativeUid`) el arbol
es reconstruible mecanicamente: este script emite el Lua, sin inventar ni un valor.

Uso:
    python tools/codice/gen_frame_from_probe.py <captura.json> <clave> [--out fichero.lua]
                                                 [--only-visible] [--root-name Nombre]

Emite un modulo con `Build(parent)` que crea las piezas y devuelve una tabla `parts` indexada
por uid, para que la logica (datos, clics, refresco) se escriba aparte y no se mezcle con el
skin generado.
"""
import argparse
import io
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

BS = chr(92)


def num(v, default=0.0):
    try:
        return float(v)
    except Exception:
        return default


def lua_str(value):
    """Literal Lua seguro: las rutas de textura llevan barras invertidas."""
    text = str(value)
    text = text.replace(BS, BS + BS).replace('"', BS + '"')
    return '"' + text + '"'


def fmt(value):
    """Numero con hasta 2 decimales, sin cola de ceros (los volcados traen 446.99996)."""
    n = round(num(value), 2)
    if abs(n - round(n)) < 0.01:
        return str(int(round(n)))
    return ('%.2f' % n).rstrip('0').rstrip('.')


def fmt_coord(value):
    """Coordenadas de textura: hacen falta TODOS los decimales. Redondear 0.650390625 a 0.65
    desplaza el recorte y descuadra el arte, que es justo lo que se quiere evitar."""
    n = num(value)
    if abs(n - round(n)) < 1e-9:
        return str(int(round(n)))
    return ('%.9f' % n).rstrip('0').rstrip('.')


class Emitter:
    def __init__(self, only_visible=False):
        self.lines = []
        self.only_visible = only_visible
        self.var_by_uid = {}
        self.counter = 0

    def w(self, text=''):
        self.lines.append(text)

    def new_var(self, prefix):
        # Nada de locals: Lua 5.1 solo admite 200 por funcion y un frame nativo tiene miles de
        # piezas. Cada una vive en la tabla `p` (alias de parts) indexada por numero.
        self.counter += 1
        return 'p[%d]' % self.counter

    # -- anclajes ---------------------------------------------------------
    def emit_points(self, var, node, parent_var):
        points = node.get('points') or []
        if not points:
            return
        for p in points:
            if not isinstance(p, dict) or p.get('point') in (None, '...'):
                continue
            target = None
            uid = p.get('relativeUid')
            if uid and uid in self.var_by_uid:
                target = self.var_by_uid[uid]
            elif p.get('relativeTo'):
                # objeto con nombre fuera del arbol capturado (UIParent, otro frame)
                target = '_G[%s] or %s' % (lua_str(p['relativeTo']), parent_var)
            else:
                target = parent_var
            self.w('    %s:SetPoint(%s, %s, %s, %s, %s)'
                   % (var, lua_str(p['point']), target, lua_str(p.get('relativePoint') or p['point']),
                      fmt(p.get('x')), fmt(p.get('y'))))

    def emit_size(self, var, node):
        w, h = node.get('absWidth'), node.get('absHeight')
        # Con dos o mas anclajes el tamano lo determinan ellos: fijarlo pelearia con el layout.
        if len([p for p in (node.get('points') or []) if isinstance(p, dict)]) >= 2:
            return
        if w and h and num(w) > 0 and num(h) > 0:
            self.w('    %s:SetSize(%s, %s)' % (var, fmt(w), fmt(h)))

    # -- regiones ---------------------------------------------------------
    def emit_texture(self, r, parent_var):
        var = self.new_var('tex')
        layer = (r.get('drawLayer') or ['ARTWORK', 0])
        level = layer[1] if len(layer) > 1 and layer[1] is not None else 0
        self.w('    %s = %s:CreateTexture(nil, %s, nil, %s)'
               % (var, parent_var, lua_str(layer[0]), int(num(level))))
        if r.get('uid'):
            self.var_by_uid[r['uid']] = var

        if r.get('atlas'):
            self.w('    %s:SetAtlas(%s)' % (var, lua_str(r['atlas'])))
        else:
            tex = r.get('texture')
            fid = r.get('textureFileID')
            if isinstance(tex, str) and not tex.isdigit():
                self.w('    %s:SetTexture(%s)' % (var, lua_str(tex)))
            elif fid or (isinstance(tex, str) and tex.isdigit()):
                self.w('    %s:SetTexture(%s)' % (var, int(num(fid or tex))))

        tc = r.get('texCoord')
        if isinstance(tc, list) and len(tc) == 8:
            vals = [fmt_coord(v) for v in tc]
            # ULx,ULy,LLx,LLy,URx,URy,LRx,LRy -> si esta alineado, la forma corta de 4
            if vals[0] == vals[2] and vals[4] == vals[6] and vals[1] == vals[5] and vals[3] == vals[7]:
                self.w('    %s:SetTexCoord(%s, %s, %s, %s)' % (var, vals[0], vals[4], vals[1], vals[3]))
            else:
                self.w('    %s:SetTexCoord(%s)' % (var, ', '.join(vals)))

        vc = r.get('vertexColor')
        if isinstance(vc, list) and len(vc) >= 3 and any(abs(num(c) - 1) > 0.01 for c in vc[:4]):
            self.w('    %s:SetVertexColor(%s, %s, %s, %s)'
                   % (var, fmt(vc[0]), fmt(vc[1]), fmt(vc[2]), fmt(vc[3]) if len(vc) > 3 else '1'))
        if r.get('blendMode') and r['blendMode'] != 'BLEND':
            self.w('    %s:SetBlendMode(%s)' % (var, lua_str(r['blendMode'])))
        if num(r.get('desaturation')) > 0:
            self.w('    %s:SetDesaturated(true)' % var)

        self.emit_size(var, r)
        self.emit_points(var, r, parent_var)
        if r.get('visible') is False or r.get('shown') is False:
            self.w('    %s:Hide()' % var)
        self.w()
        return var

    def emit_fontstring(self, r, parent_var):
        var = self.new_var('fs')
        layer = (r.get('drawLayer') or ['OVERLAY', 0])
        self.w('    %s = %s:CreateFontString(nil, %s)' % (var, parent_var, lua_str(layer[0])))
        if r.get('uid'):
            self.var_by_uid[r['uid']] = var
        font = r.get('font')
        if isinstance(font, list) and font and font[0]:
            flags = font[2] if len(font) > 2 and font[2] else ''
            self.w('    %s:SetFont(%s, %s, %s)'
                   % (var, lua_str(font[0]), fmt(font[1] if len(font) > 1 else 12), lua_str(flags)))
        col = r.get('textColor')
        if isinstance(col, list) and len(col) >= 3:
            self.w('    %s:SetTextColor(%s, %s, %s)' % (var, fmt(col[0]), fmt(col[1]), fmt(col[2])))
        if r.get('justifyH'):
            self.w('    %s:SetJustifyH(%s)' % (var, lua_str(r['justifyH'])))
        if r.get('justifyV'):
            self.w('    %s:SetJustifyV(%s)' % (var, lua_str(r['justifyV'])))
        if r.get('wordWrap') is False:
            self.w('    %s:SetWordWrap(false)' % var)
        # El texto es DATO, no skin: se deja como comentario para que lo ponga la logica.
        if r.get('text'):
            self.w('    -- texto original: %s' % str(r['text'])[:60].replace('\n', ' '))
        self.emit_size(var, r)
        self.emit_points(var, r, parent_var)
        self.w()
        return var

    # -- frames -----------------------------------------------------------
    def emit_frame(self, node, parent_var, depth=0):
        if self.only_visible and node.get('visible') is False:
            return None
        otype = node.get('objectType') or 'Frame'
        var = self.new_var({'Button': 'btn', 'StatusBar': 'bar', 'Slider': 'sld',
                            'ScrollFrame': 'scr', 'EditBox': 'eb'}.get(otype, 'f'))
        self.w('    -- %s %s' % (otype, node.get('name') or node.get('uid') or ''))
        self.w('    %s = CreateFrame(%s, nil, %s)' % (var, lua_str(otype), parent_var))
        if node.get('uid'):
            self.var_by_uid[node['uid']] = var
        self.emit_size(var, node)
        self.emit_points(var, node, parent_var)
        if node.get('frameStrata') and depth == 0:
            self.w('    %s:SetFrameStrata(%s)' % (var, lua_str(node['frameStrata'])))

        sb = node.get('statusBar')
        if isinstance(sb, dict):
            t = sb.get('texture') or {}
            if t.get('atlas'):
                self.w('    %s:SetStatusBarAtlas(%s)' % (var, lua_str(t['atlas'])))
            elif t.get('texture') is not None:
                tex = t['texture']
                self.w('    %s:SetStatusBarTexture(%s)'
                       % (var, lua_str(tex) if isinstance(tex, str) and not str(tex).isdigit()
                          else int(num(t.get('textureFileID') or tex))))
            mm = sb.get('minMax')
            if isinstance(mm, list) and len(mm) >= 2:
                self.w('    %s:SetMinMaxValues(%s, %s)' % (var, fmt(mm[0]), fmt(mm[1])))
            if sb.get('orientation'):
                self.w('    %s:SetOrientation(%s)' % (var, lua_str(sb['orientation'])))
            col = sb.get('color')
            if isinstance(col, list) and len(col) >= 3:
                self.w('    %s:SetStatusBarColor(%s, %s, %s, %s)'
                       % (var, fmt(col[0]), fmt(col[1]), fmt(col[2]),
                          fmt(col[3]) if len(col) > 3 else '1'))

        for r in node.get('regions') or []:
            if not isinstance(r, dict):
                continue
            if self.only_visible and r.get('visible') is False:
                continue
            if r.get('objectType') == 'Texture':
                self.emit_texture(r, var)
            elif r.get('objectType') == 'FontString':
                self.emit_fontstring(r, var)

        for child in node.get('children') or []:
            if isinstance(child, dict):
                self.emit_frame(child, var, depth + 1)

        self.w('    parts.byUid[%s] = %s' % (lua_str(node.get('uid') or var), var))
        self.w()
        return var


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('json_file')
    ap.add_argument('key', help='clave dentro del json (p.ej. "sel")')
    ap.add_argument('--out', default=None)
    ap.add_argument('--only-visible', action='store_true')
    ap.add_argument('--module', default='HarfordGeneratedSkin')
    args = ap.parse_args()

    data = json.load(io.open(args.json_file, encoding='utf-8'))
    # La clave admite "Frame/etiqueta" (volcado de export_probe.lua) o una clave suelta.
    node = data
    for part in args.key.split('/'):
        node = node[part]
    tree = node.get('tree') if isinstance(node, dict) and 'tree' in node else node

    em = Emitter(only_visible=args.only_visible)
    em.w('-- GENERADO por tools/codice/gen_frame_from_probe.py a partir de una captura de')
    em.w('-- HarfordFrameProbe. NO editar a mano: regenerar desde la captura.')
    em.w('-- Solo SKIN (piezas, anclajes, texturas, fuentes). La logica va en su propio modulo')
    em.w('-- y accede a las piezas por su uid en la tabla `parts`.')
    em.w('')
    em.w('%s = %s or {}' % (args.module, args.module))
    em.w('')
    em.w('function %s.Build(parent)' % args.module)
    em.w('    local parts = { byUid = {} }')
    em.w('    local p = parts')
    em.emit_frame(tree, 'parent')
    em.w('    return parts')
    em.w('end')

    out = args.out or (args.module + '.lua')
    io.open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(em.lines) + '\n')
    print('generado %s (%d lineas, %d piezas)' % (out, len(em.lines), len(em.var_by_uid)))


if __name__ == '__main__':
    main()
