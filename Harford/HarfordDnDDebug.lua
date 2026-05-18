HarfordDnDDebug = HarfordDnDDebug or {}
HarfordDnDDebug.enabled = HarfordDnDDebug.enabled == true

function HarfordDnDDebug.Log(...)
    if not HarfordDnDDebug.enabled then
        return
    end
    print("[HarfordDnD]", ...)
end
