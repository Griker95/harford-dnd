---
name: harford-debug
description: Anade un comando de diagnostico temporal al addon HarfordDebug siguiendo el patron RegisterCommand del proyecto. Usar cuando haga falta un probe, un dump o una comprobacion in-game que no pertenece a los modulos de gameplay.
---

# Comando de diagnóstico en HarfordDebug

Los diagnósticos temporales van SIEMPRE en el addon `HarfordDebug/` con
`HarfordDebug.RegisterCommand`, **nunca** en módulos de gameplay del core ni de Admin.
Se invocan en juego con `/harford debug run <nombre> [args]` (requiere `/harford debug on`).

## Patrón

```lua
HarfordDebug.RegisterCommand("minombre", function(args)
    -- args llega como string (puede ser ""); parsear aqui lo que haga falta.
    -- El handler corre bajo pcall: un error se imprime, no revienta el cliente.
    Print("resultado: " .. tostring(algo))
end, "Descripcion breve de que comprueba")
```

- Firma real: `RegisterCommand(name, handler, helpText)` (HarfordDebug/HarfordDebug.lua:78).
  El `helpText` sale en el listado de comandos; escribirlo siempre, en español.
- `Print` es el helper local del fichero (prefijo de debug propio); no usar
  `DEFAULT_CHAT_FRAME:AddMessage` directo ni `HarfordChat.Print` (ese es para mensajes de
  usuario del core).
- Dependencias del core SIEMPRE comprobadas en runtime: `if HarfordDnDStore and ... then`.
  HarfordDebug es opcional (`RequiredDeps: Harford`) pero el core puede haber cambiado.

## Dónde colocarlo

- Comandos generales: `HarfordDebug/HarfordDebug.lua`, junto a los de su tema.
- Verificación estructural por lotes: `HarfordDebug/HarfordDebugVerify.lua` (la batería de
  `/harford debug run verificar`).
- Probes de frames nativos: ya existen `probeframe*`; no duplicar. `HarfordFrameProbe` es
  pesado (presupuesto de nodos) — no añadir capturas automáticas.

## Reglas que ya costaron

- Un comando de debug NO muta estado de gameplay salvo que su nombre lo grite (`svclean`,
  `aboutfix`); los probes son de solo lectura.
- Acumuladores de diagnóstico (logs, dumps) van a `HarfordDebugSettings`, no a las
  SavedVariables del core, y se limpian por `svclean debug`.
- Si el diagnóstico confirma una limitación o patrón nuevo de Epsilon, actualizar
  `AGENTS.md` en el mismo lote.
- Cuando el comando deje de hacer falta, RETIRARLO: los temporales que se quedan son ruido
  en `ListCommands`.
