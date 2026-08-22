# -*- coding: utf-8 -*-
"""Equipo de aventureros del Manual del Jugador que faltaba en el compendio.

Precio y peso son los de la tabla del capitulo 5 (el PDF los trae aplanados y con
erratas de OCR: "21b", "l po", asi que van como datos). La DESCRIPCION no se escribe
aqui: la pone `phb_equipo.py` desde el texto del propio manual, y si el Libro 1
reprecia el objeto, su precio manda (lo aplica extract_equipment).
"""

# (nombre, categoria, precio, peso)
FALTAN = [
    ("Abrojos (bolsa de 20)", "Equipo de aventuras", "1 po", "2 lb"),
    ("Aljaba", "Equipo de aventuras", "1 po", "1 lb"),
    ("Ariete portátil", "Equipo de aventuras", "4 po", "35 lb"),
    ("Balanza de mercader", "Equipo de aventuras", "5 po", "3 lb"),
    ("Bolas de metal (bolsa de 1.000)", "Equipo de aventuras", "1 po", "2 lb"),
    ("Bolsa", "Equipo de aventuras", "5 pp", "1 lb"),
    ("Barril", "Equipo de aventuras", "2 po", "70 lb"),
    ("Caña de pescar", "Equipo de aventuras", "1 po", "4 lb"),
    ("Cesta", "Equipo de aventuras", "4 pp", "2 lb"),
    ("Cofre", "Equipo de aventuras", "5 po", "25 lb"),
    ("Cubo", "Equipo de aventuras", "5 pc", "2 lb"),
    ("Cuerno para beber", "Equipo de aventuras", "2 pp", "2 lb"),
    ("Escala de cuerda (3 metros)", "Equipo de aventuras", "1 po", "10 lb"),
    ("Estuche para virotes de ballesta", "Equipo de aventuras", "1 po", "1 lb"),
    ("Frasco o jarra", "Equipo de aventuras", "2 pc", "1 lb"),
    ("Lámpara", "Equipo de aventuras", "5 pp", "1 lb"),
    ("Libro de conjuros", "Canalizadores", "50 po", "3 lb"),
    ("Manta", "Equipo de aventuras", "5 pp", "3 lb"),
    ("Olla de hierro", "Equipo de aventuras", "2 po", "10 lb"),
    ("Papel (hoja)", "Equipo de aventuras", "2 pp", "—"),
    ("Perfume (vial)", "Equipo de aventuras", "5 po", "—"),
    ("Pinchos de hierro (10)", "Equipo de aventuras", "1 po", "5 lb"),
    ("Polipasto", "Equipo de aventuras", "1 po", "5 lb"),
    ("Ropas comunes", "Equipo de aventuras", "5 pp", "3 lb"),
    ("Ropas de calidad", "Equipo de aventuras", "15 po", "4 lb"),
    ("Ropas de viaje", "Equipo de aventuras", "2 po", "4 lb"),
    ("Ropas de disfraz", "Equipo de aventuras", "5 po", "4 lb"),
    ("Saco", "Equipo de aventuras", "1 pc", "1/2 lb"),
    ("Silbato de supervivencia", "Equipo de aventuras", "5 pc", "—"),
    ("Tienda para dos personas", "Equipo de aventuras", "2 po", "20 lb"),
    ("Tiza (1 trozo)", "Equipo de aventuras", "1 pc", "—"),
    ("Trampa para cazar", "Equipo de aventuras", "5 po", "25 lb"),
    ("Utensilios de cocina", "Equipo de aventuras", "2 pp", "1 lb"),
    ("Útiles de escalada", "Herramientas", "25 po", "12 lb"),
    ("Palanqueta", "Equipo de aventuras", "2 po", "5 lb"),
    ("Barda", "Monturas", "x4 el precio de la armadura", "x2 el peso de la armadura"),
]
