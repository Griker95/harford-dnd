# -*- coding: utf-8 -*-
"""Inventario de TODO lo que declaran los XML nativos, para contrastarlo con nuestro codigo.

No intenta decidir si algo esta bien: saca la lista completa de propiedades declaradas por
elemento (tamano, anclajes, color, texCoords, herencia, oculto, alphaMode, capa) para poder
revisarlas una a una. Lo que la sonda MIDE no vale como sustituto: mide el resultado en ingles
y con el frame visible, no la declaracion.
"""
import io, re, sys, xml.etree.ElementTree as ET
sys.stdout.reconfigure(encoding='utf-8')

NS = '{http://www.blizzard.com/wow/ui/}'


def limpia(t):
    return t.replace(NS, '')


def anclajes(el):
    out = []
    anchors = el.find(NS + 'Anchors')
    if anchors is None:
        return out
    for a in anchors.findall(NS + 'Anchor'):
        p = a.get('point', '?')
        rel = a.get('relativeTo') or a.get('relativeKey') or ''
        rp = a.get('relativePoint', '')
        x, y = a.get('x'), a.get('y')
        off = a.find(NS + 'Offset')
        if off is not None:
            d = off.find(NS + 'AbsDimension')
            if d is not None:
                x, y = d.get('x'), d.get('y')
        out.append("%s->%s.%s(%s,%s)" % (p, rel.split('.')[-1] or '$parent', rp or p,
                                         x or 0, y or 0))
    return out


def tamano(el):
    s = el.find(NS + 'Size')
    if s is None:
        return None
    if s.get('x') is not None:
        return (s.get('x'), s.get('y'))
    d = s.find(NS + 'AbsDimension')
    if d is not None:
        return (d.get('x'), d.get('y'))
    return None


def color(el):
    c = el.find(NS + 'Color')
    if c is None:
        return None
    return "r%s g%s b%s a%s" % (c.get('r', '?'), c.get('g', '?'), c.get('b', '?'), c.get('a', '1'))


def texcoords(el):
    t = el.find(NS + 'TexCoords')
    if t is None:
        return None
    return "L%s R%s T%s B%s" % (t.get('left'), t.get('right'), t.get('top'), t.get('bottom'))


def recorre(el, ruta, capa, salida):
    tipo = limpia(el.tag)
    if tipo in ('Frame', 'Button', 'StatusBar', 'ScrollFrame', 'Slider', 'CheckButton',
                'EditBox', 'Texture', 'FontString', 'ModelScene', 'PlayerModel'):
        nombre = el.get('name') or el.get('parentKey') or '(anon)'
        info = {
            'tipo': tipo, 'nombre': nombre, 'ruta': ruta,
            'inherits': el.get('inherits'), 'size': tamano(el), 'anchors': anclajes(el),
            'color': color(el), 'texcoords': texcoords(el), 'file': el.get('file'),
            'atlas': el.get('atlas'), 'hidden': el.get('hidden'),
            'alphaMode': el.get('alphaMode'), 'capa': capa,
            'justifyH': el.get('justifyH'), 'justifyV': el.get('justifyV'),
            'text': el.get('text'), 'virtual': el.get('virtual'),
            'useParentLevel': el.get('useParentLevel'),
        }
        salida.append(info)
        ruta = ruta + '/' + nombre
    for hijo in el:
        etiqueta = limpia(hijo.tag)
        nueva_capa = capa
        if etiqueta == 'Layer':
            nueva_capa = hijo.get('level', capa)
        recorre(hijo, ruta, nueva_capa, salida)


def informe(camino, filtro=None):
    texto = io.open(camino, encoding='utf-8').read()
    # El volcado de Townlong parte la primera etiqueta en dos lineas.
    texto = texto.replace('\n..\\..\\FrameXML\\UI.xsd">', ' ">', 1)
    raiz = ET.fromstring(texto)
    salida = []
    recorre(raiz, '', '?', salida)
    print("=" * 100)
    print("%s  (%d elementos declarados)" % (camino.split('/')[-1], len(salida)))
    print("=" * 100)
    for e in salida:
        if filtro and filtro not in (e['ruta'] + '/' + e['nombre']):
            continue
        partes = []
        if e['inherits']:
            partes.append("hereda=%s" % e['inherits'])
        if e['size']:
            partes.append("size=%sx%s" % e['size'])
        else:
            partes.append("size=(SIN DECLARAR)")
        if e['file']:
            partes.append("file=%s" % e['file'].split('\\')[-1])
        if e['atlas']:
            partes.append("atlas=%s" % e['atlas'])
        if e['color']:
            partes.append("color=%s" % e['color'])
        if e['texcoords']:
            partes.append("tc=%s" % e['texcoords'])
        if e['alphaMode']:
            partes.append("alphaMode=%s" % e['alphaMode'])
        if e['hidden']:
            partes.append("HIDDEN")
        if e['justifyH']:
            partes.append("jH=%s" % e['justifyH'])
        if e['justifyV']:
            partes.append("jV=%s" % e['justifyV'])
        if e['useParentLevel']:
            partes.append("useParentLevel")
        if e['capa'] not in ('?', None):
            partes.append("capa=%s" % e['capa'])
        print("  [%-10s] %-30s %s" % (e['tipo'], e['nombre'][:30], "  ".join(partes)))
        for a in e['anchors']:
            print("               %s" % a)


if __name__ == '__main__':
    for c in sys.argv[1:]:
        informe(c)
