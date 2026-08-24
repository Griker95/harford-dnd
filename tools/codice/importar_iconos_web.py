# -*- coding: utf-8 -*-
"""Importa los iconos de la web (harfordweb) al catalogo del addon.

Sentido web -> addon. NO toca la web. La web MANDA: si un id tiene icono alli, ese gana sobre el
que tuviera el addon. Lo que la web no cubre se conserva tal cual, para no perder nada.

    python tools/codice/importar_iconos_web.py            # informe, no escribe
    python tools/codice/importar_iconos_web.py --escribir # aplica sobre HarfordIconCatalog.lua
    python tools/codice/importar_iconos_web.py --lista    # ademas vuelca el inventario completo

Que se reescribe de `HarfordIconCatalog.lua`:
  - `Catalog.features`   : id de rasgo -> icono.
  - `Catalog.spells`     : id de conjuro -> LISTA de candidatos; el de la web va el PRIMERO y se
                           conservan los que ya hubiera detras (los resuelve HarfordCompendioIconMap
                           con LibRPMedia, asi que un candidato de mas no estorba).
  - `Catalog.subclasses` : clase -> subclase -> icono.
Que NO se toca:
  - `Catalog.names`, que es el fallback POR NOMBRE y no tiene equivalente en la web.
  - Las funciones del final del fichero.
  - Los `icon = "..."` en linea de los ficheros de datos: el catalogo ya tiene prioridad sobre
    ellos en `HarfordDnDData.GetFeatureIcon`, asi que importar aqui basta para que mande la web.

OJO: que un icono este en la web no garantiza que exista en el cliente de Epsilon (AGENTS.md:
las texturas retail que faltan salen en verde). Validar en juego con `GetFileIDFromPath`.
"""
import io, os, re, sys, json, glob

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(AQUI, '..', '..')) + '/'
WEB = 'C:/Users/marco/Documents/harfordweb/js/'
CATALOGO = RAIZ + 'Harford/Compendium/HarfordIconCatalog.lua'

ESCRIBIR = '--escribir' in sys.argv
LISTA = '--lista' in sys.argv


# ---------------------------------------------------------------- lectura de la web
def carga_web(nombre):
    ruta = WEB + nombre
    if not os.path.exists(ruta):
        print('  (falta %s)' % nombre)
        return None
    s = io.open(ruta, encoding='utf-8').read()
    # Los auxiliares abren con "window.X = window.X || {};" y DESPUES publican el literal.
    # El primer '{' del fichero es ese '{}' vacio, no el dato.
    for apertura, cierre in (('= [', ']'), ('= {', '}')):
        i = s.find(apertura)
        while i >= 0:
            try:
                return json.loads(s[i + 2:s.rfind(cierre) + 1])
            except Exception:
                i = s.find(apertura, i + 1)
    print('  (%s: no parsea)' % nombre)
    return None


# ---------------------------------------------------------------- ids renombrados
# El addon aplico la convencion <abrevClase>_<abrevSub>_<cosa> a 63 rasgos que se nombraban solo
# por su subclase (`afliccion_drenar_alma` -> `bru_afl_drenar_alma`). La WEB conserva los ids
# viejos y NO se toca desde aqui: es su fuente y la mantiene otro flujo.
#
# Esta tabla traduce al leer, para que el cruce de iconos siga funcionando con la web sin cambios.
# Cuando la web adopte los ids nuevos, cada entrada deja de encontrar su viejo y se vuelve inerte;
# entonces se puede borrar la tabla entera.
ALIAS_WEB = {
    'feat_abrazo_vacio': 'abrazo_vacio',
    'feat_acechador': 'acechador',
    'feat_actor': 'actor',
    'feat_adepto_armas_fuego': 'adepto_armas_fuego',
    'feat_adepto_metamagia': 'adepto_metamagia',
    'feat_adepto_sobrenatural': 'adepto_sobrenatural',
    'feat_afortunado': 'afortunado',
    'feat_agilidad_robusta': 'agilidad_robusta',
    'feat_alerta': 'alerta',
    'feat_amigo_criaturas': 'amigo_criaturas',
    'feat_apresador': 'apresador',
    'feat_artillero_dote': 'artillero_dote',
    'feat_atacante_carga': 'atacante_carga',
    'feat_atacante_salvaje': 'atacante_salvaje',
    'feat_atleta': 'atleta',
    'feat_azote_magos': 'azote_magos',
    'feat_centinela': 'centinela',
    'feat_cocinero': 'cocinero',
    'feat_combatiente_dos_armas': 'combatiente_dos_armas',
    'feat_combatiente_montado': 'combatiente_montado',
    'feat_cortador': 'cortador',
    'feat_depredador_endurecido': 'depredador_endurecido',
    'feat_duelista_defensivo': 'duelista_defensivo',
    'feat_duro': 'duro',
    'feat_envenenador': 'envenenador',
    'feat_experto_armas_fuego': 'experto_armas_fuego',
    'feat_experto_ballestas': 'experto_ballestas',
    'feat_experto_habilidades': 'experto_habilidades',
    'feat_explorador_mazmorras': 'explorador_mazmorras',
    'feat_fortaleza_enana': 'fortaleza_enana',
    'feat_furia_orca': 'furia_orca',
    'feat_gran_maestro_armas': 'gran_maestro_armas',
    'feat_guia_espiritual': 'guia_espiritual',
    'feat_habilidoso': 'habilidoso',
    'feat_herencia_darnassiana': 'herencia_darnassiana',
    'feat_iniciado_artificiero': 'iniciado_artificiero',
    'feat_iniciado_combate': 'iniciado_combate',
    'feat_iniciado_magia': 'iniciado_magia',
    'feat_lanzador_combate': 'lanzador_combate',
    'feat_lanzador_preciso': 'lanzador_preciso',
    'feat_lanzador_ritual': 'lanzador_ritual',
    'feat_lider_inspirador': 'lider_inspirador',
    'feat_ligeramente_acorazado': 'ligeramente_acorazado',
    'feat_linguista': 'linguista',
    'feat_maestro_armaduras_medias': 'maestro_armaduras_medias',
    'feat_maestro_armaduras_pesadas': 'maestro_armaduras_pesadas',
    'feat_maestro_armas': 'maestro_armas',
    'feat_maestro_armas_asta': 'maestro_armas_asta',
    'feat_maestro_armas_exoticas': 'maestro_armas_exoticas',
    'feat_maestro_armas_pesadas': 'maestro_armas_pesadas',
    'feat_maestro_escudero': 'maestro_escudero',
    'feat_maestro_escudos': 'maestro_escudos',
    'feat_mago_de_batalla': 'mago_de_batalla',
    'feat_maton_taberna': 'maton_taberna',
    'feat_mejor_quimica': 'mejor_quimica',
    'feat_mente_aguda': 'mente_aguda',
    'feat_moderadamente_acorazado': 'moderadamente_acorazado',
    'feat_movil': 'movil',
    'feat_muy_acorazado': 'muy_acorazado',
    'feat_observador': 'observador',
    'feat_perforador': 'perforador',
    'feat_precision_elfica': 'precision_elfica',
    'feat_prodigio': 'prodigio',
    'feat_rencor_faccion': 'rencor_faccion',
    'feat_resiliente': 'resiliente',
    'feat_resistencia_tauren': 'resistencia_tauren',
    'feat_resistente': 'resistente',
    'feat_sanador': 'sanador',
    'feat_telepata': 'telepata',
    'feat_telequinetico': 'telequinetico',
    'feat_teletransporte_arcano': 'teletransporte_arcano',
    'feat_tirador_primera': 'tirador_primera',
    'feat_tocado_hadas': 'tocado_hadas',
    'feat_tocado_sombras': 'tocado_sombras',
    'feat_triturador': 'triturador',
    'feat_versado_armas': 'versado_armas',
    'feat_versado_elemento': 'versado_elemento',
    'bru_nigromancia_del_vacio_nivel_6': 'brujo_nigromancia_del_vacio_nivel_6',
    'bru_nigromancia_del_vacio_nivel_7': 'brujo_nigromancia_del_vacio_nivel_7',
    'cdm_forja_de_runas_superior': 'caballero_mu_forja_de_runas_superior',
    'cdm_sin_muerte': 'caballero_mu_sin_muerte',
    'cdm_voluntad_de_la_tumba': 'caballero_mu_voluntad_de_la_tumba',
    'caz_acechador': 'cazador_acechador',
    'caz_aspecto_de_lo_salvaje': 'cazador_aspecto_de_lo_salvaje',
    'caz_conocimiento_del_depredador': 'cazador_conocimiento_del_depredador',
    'dh_alas_demoniacas': 'cazador_demo_alas_demoniacas',
    'dh_cuerpo_atemporal': 'cazador_demo_cuerpo_atemporal',
    'dh_destreza_illidari': 'cazador_demo_destreza_illidari',
    'dh_evasion': 'cazador_demo_evasion',
    'dh_mirada_reveladora': 'cazador_demo_mirada_reveladora',
    'dh_preparado': 'cazador_demo_preparado',
    'dh_purificado_por_las_llamas': 'cazador_demo_purificado_por_las_llamas',
    'dh_resiliencia_abisal': 'cazador_demo_resiliencia_abisal',
    'dh_un_cazador_por_encima_de_todo': 'cazador_demo_un_cazador_por_encima_de_todo',
    'caz_sentidos_agudizados': 'cazador_sentidos_agudizados',
    'cdm_san_comando_oscuro': 'cdm_comando_oscuro',
    'cdm_esc_conjuros_3': 'cdm_escarcha_conjuros_3',
    'cdm_esc_conjuros_5': 'cdm_escarcha_conjuros_5',
    'cdm_san_escudo_sangre': 'cdm_escudo_sangre',
    'cdm_esc_golpe_escarcha': 'cdm_golpe_escarcha',
    'cdm_esc_maquina_matar': 'cdm_maquina_matar',
    'cdm_pro_portador_plagas': 'cdm_portador_plagas',
    'cdm_pro_conjuros_3': 'cdm_profana_conjuros_3',
    'cdm_pro_conjuros_5': 'cdm_profana_conjuros_5',
    'cdm_san_conjuros_3': 'cdm_sangre_conjuros_3',
    'cdm_san_conjuros_5': 'cdm_sangre_conjuros_5',
    'dru_alma_del_bosque': 'druida_alma_del_bosque',
    'dru_cuerpo_atemporal': 'druida_cuerpo_atemporal',
    'gue_accion_adicional': 'guerrero_accion_adicional',
    'gue_arquetipo_marcial': 'guerrero_arquetipo_marcial',
    'gue_ataque_extra': 'guerrero_ataque_extra',
    'gue_ataque_extra_2': 'guerrero_ataque_extra_2',
    'gue_estilo_combate': 'guerrero_estilo_combate',
    'gue_furia_interna': 'guerrero_furia_interna',
    'gue_segundo_aliento': 'guerrero_segundo_aliento',
    'pal_pro_conjuros_3': 'pal_proteccion_conjuros_3',
    'pal_pro_conjuros_5': 'pal_proteccion_conjuros_5',
    'pal_ret_conjuros_3': 'pal_represion_conjuros_3',
    'pal_ret_conjuros_5': 'pal_represion_conjuros_5',
    'pal_sag_conjuros_3': 'pal_sagrado_conjuros_3',
    'pal_sag_conjuros_5': 'pal_sagrado_conjuros_5',
    'pal_aura_de_coraje': 'paladin_aura_de_coraje',
    'pal_toque_purificador': 'paladin_toque_purificador',
    'pic_anticipacion': 'picaro_anticipacion',
    'pic_esquivo': 'picaro_esquivo',
    'pic_evasion': 'picaro_evasion',
    'pic_golpe_de_suerte': 'picaro_golpe_de_suerte',
    'sac_dis_conjuros_1': 'sac_disciplina_conjuros_1',
    'sac_dis_conjuros_3': 'sac_disciplina_conjuros_3',
    'sac_dis_conjuros_5': 'sac_disciplina_conjuros_5',
    'sac_sag_conjuros_1': 'sac_sagrado_conjuros_1',
    'sac_sag_conjuros_3': 'sac_sagrado_conjuros_3',
    'sac_sag_conjuros_5': 'sac_sagrado_conjuros_5',
    'sac_som_conjuros_1': 'sac_sombra_conjuros_1',
    'sac_som_conjuros_3': 'sac_sombra_conjuros_3',
    'sac_som_conjuros_5': 'sac_sombra_conjuros_5',
    'bru_afl_aflicciones_inestables': 'afliccion_aflicciones_inestables',
    'bru_afl_aflicciones_potentes': 'afliccion_aflicciones_potentes',
    'bru_afl_drenar_alma': 'afliccion_drenar_alma',
    'bru_dem_furia_demoniaca': 'demonologia_furia_demoniaca',
    'bru_dem_grimorio_de_supremacia': 'demonologia_grimorio_de_supremacia',
    'bru_dem_somos_legion': 'demonologia_somos_legion',
    'bru_des_infierno': 'destruccion_infierno',
    'bru_des_llamas_de_xerrath': 'destruccion_llamas_de_xerrath',
    'bru_des_resolucion_inquebrantable': 'destruccion_resolucion_inquebrantable',
    'caz_bes_vinculo_del_companero': 'bestias_vinculo_del_companero',
    'caz_pun_aspecto_del_aguila': 'punteria_aspecto_del_aguila',
    'caz_pun_ataque_multiple': 'punteria_ataque_multiple',
    'caz_pun_enfoque_del_tirador': 'punteria_enfoque_del_tirador',
    'caz_sup_camuflaje_natural': 'supervivencia_camuflaje_natural',
    'caz_sup_contraataque_marcado': 'supervivencia_contraataque_marcado',
    'caz_sup_terminos_de_compromiso': 'supervivencia_terminos_de_compromiso',
    'cdm_esc_corazon_congelado': 'escarcha_corazon_congelado',
    'cdm_esc_garras_de_hielo': 'escarcha_garras_de_hielo',
    'cdm_esc_invierno_implacable': 'escarcha_invierno_implacable',
    'cdm_esc_pilar_de_escarcha': 'escarcha_pilar_de_escarcha',
    'cdm_san_arma_runica_danza': 'sangre_arma_runica_danza',
    'cdm_san_golpe_al_corazon': 'sangre_golpe_al_corazon',
    'cdm_san_purgatorio': 'sangre_purgatorio',
    'cdm_san_tormenta_de_huesos': 'sangre_tormenta_de_huesos',
    'dh_ven_aura_de_inmolacion': 'venganza_aura_de_inmolacion',
    'dh_ven_ultimo_recurso': 'venganza_ultimo_recurso',
    'dru_eq_bendicion_de_los_ancestros': 'equilibrio_bendicion_de_los_ancestros',
    'dru_eq_encarnacion_elegido_de_elune': 'equilibrio_encarnacion_elegido_de_elune',
    'dru_eq_influencia_astral': 'equilibrio_influencia_astral',
    'dru_fer_afinidad_superior_feral_o_guar': 'feral_afinidad_superior_feral_o_guar',
    'dru_fer_encarnacion_guardian_de_las_ti': 'feral_encarnacion_guardian_de_las_ti',
    'dru_fer_mutilacion_brutal': 'feral_mutilacion_brutal',
    'dru_res_corteza_de_hierro': 'restauracion_corteza_de_hierro',
    'dru_res_encarnacion_arbol_de_vida': 'restauracion_encarnacion_arbol_de_vida',
    'dru_res_guardia_cenarion': 'restauracion_guardia_cenarion',
    'dru_res_rejuvenecimiento': 'restauracion_rejuvenecimiento',
    'dru_res_tranquilidad': 'restauracion_tranquilidad',
    'gue_arm_calma_mortal': 'armas_calma_mortal',
    'gue_arm_golpe_colosal': 'armas_golpe_colosal',
    'gue_arm_golpes_de_oportunidad': 'armas_golpes_de_oportunidad',
    'gue_arm_grito_de_mando': 'armas_grito_de_mando',
    'gue_fur_berserker_enloquecido': 'furia_berserker_enloquecido',
    'gue_fur_critico_devastador': 'furia_critico_devastador',
    'gue_fur_furia_focalizada': 'furia_furia_focalizada',
    'gue_fur_sed_de_sangre': 'furia_sed_de_sangre',
    'gue_pro_golpes_atenuados': 'proteccion_golpes_atenuados',
    'gue_pro_interceptar': 'proteccion_interceptar',
    'gue_pro_nunca_te_rindas': 'proteccion_nunca_te_rindas',
    'gue_pro_presencia_inspiradora': 'proteccion_presencia_inspiradora',
    'mago_esc_anillo_de_escarcha': 'escarcha_anillo_de_escarcha',
    'mago_esc_manos_de_escarcha': 'escarcha_manos_de_escarcha',
    'mago_fue_combustion': 'fuego_combustion',
    'mago_fue_prender': 'fuego_prender',
    'monje_cer_brebajes_elusivos': 'cervecero_brebajes_elusivos',
    'monje_cer_elaboracion_ligera': 'cervecero_elaboracion_ligera',
    'monje_tej_anillo_de_paz': 'tejedor_anillo_de_paz',
    'monje_tej_estatua_del_dragon_de_jade': 'tejedor_estatua_del_dragon_de_jade',
    'sac_dis_absolucion_penitencia': 'disciplina_absolucion_penitencia',
    'sac_dis_castigo': 'disciplina_castigo',
    'sac_dis_claridad_de_voluntad': 'disciplina_claridad_de_voluntad',
    'sac_dis_expiacion': 'disciplina_expiacion',
    'sac_som_mente_dominante': 'sombra_mente_dominante',
    'sac_som_rendicion_a_la_locura': 'sombra_rendicion_a_la_locura',
}

def iconos_de_la_web():
    iconos = {}
    for fichero in ['compendium-data.js', 'compendium-dotes.js', 'compendium-equipment.js',
                    'compendium-languages.js', 'compendium-professions.js']:
        d = carga_web(fichero)
        if d is None:
            continue
        def anda(n):
            if isinstance(n, dict):
                i, ic = n.get('id'), n.get('icon')
                if isinstance(i, str) and isinstance(ic, str) and ic:
                    iconos.setdefault(i, ic)
                for v in n.values():
                    anda(v)
            elif isinstance(n, list):
                for v in n:
                    anda(v)
        anda(d)
    # Los ids que el addon renombro heredan el icono de su nombre anterior en la web.
    for nuevo, viejo in ALIAS_WEB.items():
        if nuevo not in iconos and viejo in iconos:
            iconos[nuevo] = iconos[viejo]
    return iconos


# ---------------------------------------------------------------- lectura del addon
def bloque(texto, nombre):
    """Devuelve (inicio, fin, contenido) del cuerpo de `Catalog.<nombre> = { ... }`."""
    m = re.search(r'Catalog\.%s\s*=\s*\{' % nombre, texto)
    if not m:
        return None
    i = m.end()
    prof, j = 1, i
    while prof > 0 and j < len(texto):
        if texto[j] == '{':
            prof += 1
        elif texto[j] == '}':
            prof -= 1
        j += 1
    return (i, j - 1, texto[i:j - 1])


def ids_del_libro():
    """id -> nombre, de todo lo que el addon puede pedirle un icono al catalogo."""
    # Entre `id` y `name` puede haber cualquier cosa (`level`, `icon`, `cast`...). Acotado a la
    # misma entrada -- sin llaves en medio -- para no saltar al rasgo siguiente.
    RE = re.compile(r'\{\s*id\s*=\s*"([a-z_0-9]+)"\s*,([^{}]{0,240}?)name\s*=\s*"([^"]+)"')
    rasgos = {}
    ficheros = sorted(glob.glob(RAIZ + 'Harford/DnD/Data/Classes/*.lua'))
    ficheros += [RAIZ + 'Harford/DnD/Data/HarfordDnDRaces.lua',
                 RAIZ + 'Harford/DnD/Data/HarfordDnDBackgrounds.lua',
                 RAIZ + 'Harford/DnD/Data/HarfordDnDFeats.lua']
    for f in ficheros:
        if not os.path.exists(f):
            continue
        s = io.open(f, encoding='utf-8').read()
        for m in RE.finditer(s):
            rasgos.setdefault(m.group(1), m.group(3))
    comp = RAIZ + 'HarfordCompendioData/HarfordCompendioData.lua'  # salio de Harford/
    conjuros = {}
    if os.path.exists(comp):
        s = io.open(comp, encoding='utf-8').read()
        for m in re.finditer(r'id = "([a-z_0-9]+)",(.{0,200}?)name = "([^"]+)"', s, re.S):
            conjuros.setdefault(m.group(1), m.group(3))
    return rasgos, conjuros


def subclases_del_libro():
    """classId -> [subclassId]. La primera subclase de cada fichero es la propia clase."""
    fuera = {}
    for f in sorted(glob.glob(RAIZ + 'Harford/DnD/Data/Classes/*.lua')):
        s = io.open(f, encoding='utf-8').read()
        mc = re.search(r'id = "([a-z_]+)", name = "[^"]+"', s)
        if not mc:
            continue
        classId = mc.group(1)
        m = re.search(r'subclasses\s*=\s*\{', s)
        if not m:
            continue
        i = m.end()
        prof, j = 1, i
        while prof > 0 and j < len(s):
            if s[j] == '{':
                prof += 1
            elif s[j] == '}':
                prof -= 1
            j += 1
        fuera[classId] = re.findall(r'id = "([a-z_]+)", name = "[A-Z]', s[i:j])
    return fuera


# ---------------------------------------------------------------- generacion
def escribe_features(mapa):
    lineas = []
    for k in sorted(mapa):
        lineas.append('    %s = "%s",' % (k, mapa[k]))
    return '\n' + '\n'.join(lineas) + '\n'


def escribe_spells(mapa):
    lineas = []
    for k in sorted(mapa):
        cands = ', '.join('"%s"' % c for c in mapa[k])
        lineas.append('    %s = { %s },' % (k, cands))
    return '\n' + '\n'.join(lineas) + '\n'


def escribe_subclases(mapa):
    lineas = []
    for clase in sorted(mapa):
        pares = ', '.join('%s = "%s"' % (s, mapa[clase][s]) for s in sorted(mapa[clase]))
        lineas.append('    %s = { %s },' % (clase, pares))
    return '\n' + '\n'.join(lineas) + '\n'


def main():
    web = iconos_de_la_web()
    rasgos, conjuros = ids_del_libro()
    subclases = subclases_del_libro()

    cat = io.open(CATALOGO, encoding='utf-8').read()
    b_feat = bloque(cat, 'features')
    b_spell = bloque(cat, 'spells')
    b_sub = bloque(cat, 'subclasses')
    if not (b_feat and b_spell and b_sub):
        print('No se reconocieron las tablas del catalogo; aborto.')
        return 1

    viejo_feat = dict(re.findall(r'(\w+)\s*=\s*"([^"]+)"', b_feat[2]))
    viejo_spell = {}
    for m in re.finditer(r'(\w+)\s*=\s*\{([^}]*)\}', b_spell[2]):
        viejo_spell[m.group(1)] = re.findall(r'"([^"]+)"', m.group(2))
    viejo_sub = {}
    for m in re.finditer(r'(\w+)\s*=\s*\{([^}]*)\}', b_sub[2]):
        viejo_sub[m.group(1)] = dict(re.findall(r'(\w+)\s*=\s*"([^"]+)"', m.group(2)))

    # --- features: la web manda; lo que no cubre, se conserva.
    nuevo_feat = dict(viejo_feat)
    cambiados, anadidos = [], []
    for fid in rasgos:
        ic = web.get(fid)
        if not ic:
            continue
        if fid not in nuevo_feat:
            anadidos.append((fid, ic))
            nuevo_feat[fid] = ic
        elif nuevo_feat[fid] != ic:
            cambiados.append((fid, nuevo_feat[fid], ic))
            nuevo_feat[fid] = ic

    # --- spells: el de la web va el PRIMERO, los candidatos previos detras.
    nuevo_spell = {k: list(v) for k, v in viejo_spell.items()}
    s_cambiados, s_anadidos = [], []
    for sid in conjuros:
        ic = web.get(sid)
        if not ic:
            continue
        previos = [c for c in nuevo_spell.get(sid, []) if c != ic]
        if sid not in nuevo_spell:
            s_anadidos.append((sid, ic))
        elif nuevo_spell[sid][:1] != [ic]:
            s_cambiados.append((sid, nuevo_spell[sid][0] if nuevo_spell[sid] else '-', ic))
        nuevo_spell[sid] = [ic] + previos

    # --- subclases: la web publica el icono con el id de la subclase suelto.
    nuevo_sub = {c: dict(v) for c, v in viejo_sub.items()}
    sub_cambios = []
    for clase, subs in subclases.items():
        for sub in subs:
            ic = web.get(sub)
            if not ic:
                continue
            antes = nuevo_sub.get(clase, {}).get(sub)
            if antes != ic:
                sub_cambios.append((clase, sub, antes or '-', ic))
                nuevo_sub.setdefault(clase, {})[sub] = ic

    print('IMPORTACION DE ICONOS  (web -> addon)')
    print('  web: %d ids con icono' % len(web))
    print()
    print('  features : %d anadidos, %d cambiados  (total %d)'
          % (len(anadidos), len(cambiados), len(nuevo_feat)))
    print('  spells   : %d anadidos, %d cambiados  (total %d)'
          % (len(s_anadidos), len(s_cambiados), len(nuevo_spell)))
    print('  subclases: %d cambios' % len(sub_cambios))
    print()
    if cambiados:
        print('  Ejemplos de icono SUSTITUIDO por el de la web:')
        for fid, a, b in cambiados[:10]:
            print('     %-34s %-32s -> %s' % (fid, a, b))
        print()

    sin_icono = [(k, v) for k, v in sorted(rasgos.items())
                 if k not in nuevo_feat and k not in web]
    sin_conj = [(k, v) for k, v in sorted(conjuros.items()) if k not in nuevo_spell]
    print('  QUEDAN SIN ICONO: %d rasgos, %d conjuros' % (len(sin_icono), len(sin_conj)))

    if LISTA:
        destino = os.path.join(AQUI, '_iconos_inventario.csv')
        with io.open(destino, 'w', encoding='utf-8', newline='\n') as fh:
            fh.write('tipo;id;nombre;icono_addon;icono_web;resultado;estado\n')
            for k, v in sorted(rasgos.items()):
                a, w = viejo_feat.get(k), web.get(k)
                r = nuevo_feat.get(k)
                estado = 'sin icono' if not r else ('nuevo de la web' if not a and w else
                         ('sustituido por la web' if w and a != w else 'del addon'))
                fh.write('rasgo;%s;%s;%s;%s;%s;%s\n' % (k, v, a or '', w or '', r or '', estado))
            for k, v in sorted(conjuros.items()):
                a = (viejo_spell.get(k) or [''])[0]
                w = web.get(k)
                r = (nuevo_spell.get(k) or [''])[0]
                estado = 'sin icono' if not r else ('nuevo de la web' if not a and w else
                         ('sustituido por la web' if w and a != w else 'del addon'))
                fh.write('conjuro;%s;%s;%s;%s;%s;%s\n' % (k, v, a, w or '', r, estado))
        print('  lista completa -> %s' % destino)

    if not ESCRIBIR:
        print()
        print('  (informe; nada escrito. Repite con --escribir para aplicar)')
        return 0

    salida = (cat[:b_feat[0]] + escribe_features(nuevo_feat) + cat[b_feat[1]:b_spell[0]]
              + escribe_spells(nuevo_spell) + cat[b_spell[1]:b_sub[0]]
              + escribe_subclases(nuevo_sub) + cat[b_sub[1]:])
    io.open(CATALOGO, 'w', encoding='utf-8', newline='\n').write(salida)
    print()
    print('  escrito %s' % CATALOGO)
    return 0


if __name__ == '__main__':
    sys.exit(main())
