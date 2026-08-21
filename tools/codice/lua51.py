# -*- coding: utf-8 -*-
"""Compila y ejecuta archivos con el Lua 5.1 REAL, el mismo que usa WoW.

Mi interprete local es 5.4, asi que no sirve para hablar de limites de 5.1. Aqui se carga
lua51.dll directamente y se usa su compilador, que es la unica autoridad sobre si un archivo
"peta" o no.
"""
import ctypes
import sys

DLL = r"C:\Users\marco\Desktop\noggit_sql\noggit_bindless\lua51.dll"

lua = ctypes.CDLL(DLL)
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.luaL_loadfile.restype = ctypes.c_int
lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
lua.lua_pcall.restype = ctypes.c_int
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]


def _error(L):
    msg = lua.lua_tolstring(L, -1, None)
    return (msg or b"?").decode("utf-8", "replace")


def compila(ruta):
    """Solo compila. Devuelve (ok, mensaje)."""
    L = lua.luaL_newstate()
    if not L:
        return False, "no se pudo crear el estado"
    try:
        lua.luaL_openlibs(L)
        if lua.luaL_loadfile(L, ruta.encode("utf-8")) != 0:
            return False, _error(L)
        return True, "compila"
    finally:
        lua.lua_close(L)


def ejecuta(ruta):
    """Compila Y ejecuta, que es lo que hace WoW al cargar el addon."""
    L = lua.luaL_newstate()
    if not L:
        return False, "no se pudo crear el estado"
    try:
        lua.luaL_openlibs(L)
        if lua.luaL_loadfile(L, ruta.encode("utf-8")) != 0:
            return False, "al compilar: " + _error(L)
        if lua.lua_pcall(L, 0, 0, 0) != 0:
            return False, "al ejecutar: " + _error(L)
        return True, "carga"
    finally:
        lua.lua_close(L)


if __name__ == "__main__":
    for ruta in sys.argv[1:]:
        ok, msg = ejecuta(ruta)
        print(("  OK  " if ok else " PETA ") + ruta + "  -> " + msg)
