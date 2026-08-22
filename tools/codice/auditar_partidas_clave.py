# -*- coding: utf-8 -*-
"""Busca terminos clave partidos por el OCR en los datos del addon.

Es el complemento de palabras_partidas.py, que descarta un corte cuando el segundo trozo
es una palabra real: por eso se le escapaba "Sabidu ria" (ria existe, es un estuario) o
"conju ro". Aqui la lista es cerrada y son palabras que el juego repite sin parar, asi que
cualquier corte dentro de una de ellas es errata segura.
Se ejecuta desde la raiz del proyecto."""
import io,re,sys,glob
sys.stdout.reconfigure(encoding='utf-8')
# terminos que el juego usa constantemente: si aparecen partidos es errata segura, aunque
# el segundo trozo sea una palabra real ("Sabidu ria" -> "ria" existe, y por eso el
# detector generico lo descartaba)
CLAVE = ["Fuerza","Destreza","Constitución","Inteligencia","Sabiduría","Carisma","salvación",
         "competencia","característica","conjuro","criatura","ataque","daño","acción",
         "reacción","ventaja","desventaja","descanso","armadura","modificador","objetivo",
         "concentración","radiante","necrótico","psíquico","contundente","perforante","cortante"]
FICH = glob.glob("Harford/**/*.lua", recursive=True)
tot = 0
for f in FICH:
    d = io.open(f, encoding="utf-8").read()
    for w in CLAVE:
        for corte in range(3, len(w) - 1):
            pat = re.escape(w[:corte]) + r"\s+" + re.escape(w[corte:])
            for m in re.finditer(pat, d):
                print("  %-34s %-14s -> %s" % (f.split("/")[-1], repr(m.group(0)), w))
                tot += 1
print("terminos clave partidos:", tot)
