-- GENERADO por tools/codice/gen_frame_from_probe.py a partir de una captura de
-- HarfordFrameProbe. NO editar a mano: regenerar desde la captura.
-- Solo SKIN (piezas, anclajes, texturas, fuentes). La logica va en su propio modulo
-- y accede a las piezas por su uid en la tabla `parts`.

HarfordCraftSkin = HarfordCraftSkin or {}

function HarfordCraftSkin.Build(parent)
    local parts = { byUid = {} }
    local p = parts
    -- Frame TradeSkillFrame
    p[1] = parent
    -- Frame root.f3
    p[2] = CreateFrame("Frame", nil, p[1])
    p[2]:SetSize(325, 410)
    p[2]:SetPoint("TOPLEFT", p[1], "TOPLEFT", 4, -80)
    p[3] = p[2]:CreateTexture(nil, "BACKGROUND", nil, -5)
    p[3]:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", "REPEAT", "REPEAT")  -- fileID 374154
    p[3]:SetHorizTile(true)
    p[3]:SetVertTile(true)
    p[3]:SetPoint("TOPLEFT", p[2], "TOPLEFT", 0, 0)
    p[3]:SetPoint("BOTTOMRIGHT", p[2], "BOTTOMRIGHT", 0, 0)

    -- Frame root.f3.f1
    p[4] = CreateFrame("Frame", nil, p[2])
    p[4]:SetPoint("TOPLEFT", p[2], "TOPLEFT", 0, 0)
    p[4]:SetPoint("BOTTOMRIGHT", p[2], "BOTTOMRIGHT", 0, 0)
    p[5] = p[4]:CreateTexture(nil, "BORDER", nil, -5)
    p[5]:SetAtlas("UI-Frame-InnerTopLeft")
    p[5]:SetSize(6, 6)
    p[5]:SetPoint("TOPLEFT", p[4], "TOPLEFT", 0, 0)

    p[6] = p[4]:CreateTexture(nil, "BORDER", nil, -5)
    p[6]:SetAtlas("UI-Frame-InnerTopRight")
    p[6]:SetSize(6, 6)
    p[6]:SetPoint("TOPRIGHT", p[4], "TOPRIGHT", 0, 0)

    p[7] = p[4]:CreateTexture(nil, "BORDER", nil, -5)
    p[7]:SetAtlas("UI-Frame-InnerBotLeftCorner")
    p[7]:SetSize(6, 6)
    p[7]:SetPoint("BOTTOMLEFT", p[4], "BOTTOMLEFT", 0, -1)

    p[8] = p[4]:CreateTexture(nil, "BORDER", nil, -5)
    p[8]:SetAtlas("UI-Frame-InnerBotRight")
    p[8]:SetSize(6, 6)
    p[8]:SetPoint("BOTTOMRIGHT", p[4], "BOTTOMRIGHT", 0, -1)

    p[9] = p[4]:CreateTexture(nil, "BORDER", nil, -5)
    p[9]:SetAtlas("_UI-Frame-InnerTopTile")
    p[9]:SetHorizTile(true)
    p[9]:SetVertTile(true)
    p[9]:SetPoint("TOPLEFT", p[5], "TOPRIGHT", 0, 0)
    p[9]:SetPoint("TOPRIGHT", p[6], "TOPLEFT", 0, 0)

    p[10] = p[4]:CreateTexture(nil, "BORDER", nil, -5)
    p[10]:SetAtlas("_UI-Frame-InnerBotTile")
    p[10]:SetHorizTile(true)
    p[10]:SetVertTile(true)
    p[10]:SetPoint("BOTTOMLEFT", p[7], "BOTTOMRIGHT", 0, 0)
    p[10]:SetPoint("BOTTOMRIGHT", p[8], "BOTTOMLEFT", 0, 0)

    p[11] = p[4]:CreateTexture(nil, "BORDER", nil, -5)
    p[11]:SetAtlas("!UI-Frame-InnerLeftTile")
    p[11]:SetHorizTile(true)
    p[11]:SetVertTile(true)
    p[11]:SetPoint("TOPLEFT", p[5], "BOTTOMLEFT", 0, 0)
    p[11]:SetPoint("BOTTOMLEFT", p[7], "TOPLEFT", 0, 0)

    p[12] = p[4]:CreateTexture(nil, "BORDER", nil, -5)
    p[12]:SetAtlas("!UI-Frame-InnerRightTile")
    p[12]:SetHorizTile(true)
    p[12]:SetVertTile(true)
    p[12]:SetPoint("TOPRIGHT", p[6], "BOTTOMRIGHT", 0, 0)
    p[12]:SetPoint("BOTTOMRIGHT", p[8], "TOPRIGHT", 0, 0)

    parts.byUid["root.f3.f1"] = p[4]

    parts.byUid["root.f3"] = p[2]

    -- Frame root.f4
    p[13] = CreateFrame("Frame", nil, p[1])
    p[13]:SetSize(335, 390)
    p[13]:SetPoint("TOPRIGHT", p[1], "TOPRIGHT", -6, -80)
    p[14] = p[13]:CreateTexture(nil, "BACKGROUND", nil, -5)
    p[14]:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", "REPEAT", "REPEAT")  -- fileID 374154
    p[14]:SetHorizTile(true)
    p[14]:SetVertTile(true)
    p[14]:SetPoint("TOPLEFT", p[13], "TOPLEFT", 0, 0)
    p[14]:SetPoint("BOTTOMRIGHT", p[13], "BOTTOMRIGHT", 0, 0)

    -- Frame root.f4.f1
    p[15] = CreateFrame("Frame", nil, p[13])
    p[15]:SetPoint("TOPLEFT", p[13], "TOPLEFT", 0, 0)
    p[15]:SetPoint("BOTTOMRIGHT", p[13], "BOTTOMRIGHT", 0, 0)
    p[16] = p[15]:CreateTexture(nil, "BORDER", nil, -5)
    p[16]:SetAtlas("UI-Frame-InnerTopLeft")
    p[16]:SetSize(6, 6)
    p[16]:SetPoint("TOPLEFT", p[15], "TOPLEFT", 0, 0)

    p[17] = p[15]:CreateTexture(nil, "BORDER", nil, -5)
    p[17]:SetAtlas("UI-Frame-InnerTopRight")
    p[17]:SetSize(6, 6)
    p[17]:SetPoint("TOPRIGHT", p[15], "TOPRIGHT", 0, 0)

    p[18] = p[15]:CreateTexture(nil, "BORDER", nil, -5)
    p[18]:SetAtlas("UI-Frame-InnerBotLeftCorner")
    p[18]:SetSize(6, 6)
    p[18]:SetPoint("BOTTOMLEFT", p[15], "BOTTOMLEFT", 0, -1)

    p[19] = p[15]:CreateTexture(nil, "BORDER", nil, -5)
    p[19]:SetAtlas("UI-Frame-InnerBotRight")
    p[19]:SetSize(6, 6)
    p[19]:SetPoint("BOTTOMRIGHT", p[15], "BOTTOMRIGHT", 0, -1)

    p[20] = p[15]:CreateTexture(nil, "BORDER", nil, -5)
    p[20]:SetAtlas("_UI-Frame-InnerTopTile")
    p[20]:SetHorizTile(true)
    p[20]:SetVertTile(true)
    p[20]:SetPoint("TOPLEFT", p[16], "TOPRIGHT", 0, 0)
    p[20]:SetPoint("TOPRIGHT", p[17], "TOPLEFT", 0, 0)

    p[21] = p[15]:CreateTexture(nil, "BORDER", nil, -5)
    p[21]:SetAtlas("_UI-Frame-InnerBotTile")
    p[21]:SetHorizTile(true)
    p[21]:SetVertTile(true)
    p[21]:SetPoint("BOTTOMLEFT", p[18], "BOTTOMRIGHT", 0, 0)
    p[21]:SetPoint("BOTTOMRIGHT", p[19], "BOTTOMLEFT", 0, 0)

    p[22] = p[15]:CreateTexture(nil, "BORDER", nil, -5)
    p[22]:SetAtlas("!UI-Frame-InnerLeftTile")
    p[22]:SetHorizTile(true)
    p[22]:SetVertTile(true)
    p[22]:SetPoint("TOPLEFT", p[16], "BOTTOMLEFT", 0, 0)
    p[22]:SetPoint("BOTTOMLEFT", p[18], "TOPLEFT", 0, 0)

    p[23] = p[15]:CreateTexture(nil, "BORDER", nil, -5)
    p[23]:SetAtlas("!UI-Frame-InnerRightTile")
    p[23]:SetHorizTile(true)
    p[23]:SetVertTile(true)
    p[23]:SetPoint("TOPRIGHT", p[17], "BOTTOMRIGHT", 0, 0)
    p[23]:SetPoint("BOTTOMRIGHT", p[19], "TOPRIGHT", 0, 0)

    parts.byUid["root.f4.f1"] = p[15]

    parts.byUid["root.f4"] = p[13]

    -- StatusBar root.f7
    p[24] = CreateFrame("StatusBar", nil, p[1])
    p[24]:SetSize(447, 14)
    p[24]:SetPoint("TOP", p[1], "TOP", 0, -33)
    p[24]:SetStatusBarTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")  -- fileID 136570
    p[24]:SetMinMaxValues(0, 300)
    p[24]:SetOrientation("HORIZONTAL")
    p[24]:SetStatusBarColor(0, 0, 1, 0.5)
    p[25] = p[24]:CreateTexture(nil, "OVERLAY", nil, 0)
    p[25]:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")  -- fileID 136571
    p[25]:SetTexCoord(0.007843, 0.043136999, 0.193547994, 0.774192989)
    p[25]:SetSize(9, 20)
    p[25]:SetPoint("LEFT", p[24], "LEFT", -3, 0)

    p[26] = p[24]:CreateTexture(nil, "OVERLAY", nil, 0)
    p[26]:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")  -- fileID 136571
    p[26]:SetTexCoord(0.043136999, 0.007843, 0.193547994, 0.774192989)
    p[26]:SetSize(9, 20)
    p[26]:SetPoint("RIGHT", p[24], "RIGHT", 3, 0)

    p[27] = p[24]:CreateTexture(nil, "OVERLAY", nil, 0)
    p[27]:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")  -- fileID 136571
    p[27]:SetTexCoord(0.113725998, 0.149019599, 0.193547994, 0.774192989)
    p[27]:SetPoint("TOPLEFT", p[25], "TOPRIGHT", 0, 0)
    p[27]:SetPoint("BOTTOMRIGHT", p[26], "BOTTOMLEFT", 0, 0)

    p[28] = p[24]:CreateFontString(nil, "OVERLAY")
    p[28]:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    p[28]:SetTextColor(1, 1, 1)
    p[28]:SetJustifyH("CENTER")
    p[28]:SetJustifyV("MIDDLE")
    -- texto original: Blacksmithing 1/300
    p[28]:SetSize(109, 9)
    p[28]:SetPoint("CENTER", p[24], "CENTER", 0, 0)

    p[29] = p[24]:CreateTexture(nil, "BACKGROUND", nil, 0)
    p[29]:SetTexCoord(0, 1, 0, 1)
    p[29]:SetPoint("TOPLEFT", p[24], "TOPLEFT", 0, 0)
    p[29]:SetPoint("BOTTOMRIGHT", p[24], "BOTTOMRIGHT", 0, 0)

    p[30] = p[24]:CreateTexture(nil, "BACKGROUND", nil, 0)
    p[30]:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")  -- fileID 136570
    p[30]:SetTexCoord(0, 0.003333333, 0, 1)
    p[30]:SetVertexColor(0, 0, 1, 0.5)
    p[30]:SetPoint("TOPLEFT", p[24], "TOPLEFT", 0, 0)
    p[30]:SetPoint("TOPRIGHT", p[24], "TOPRIGHT", -445.51, 0)
    p[30]:SetPoint("BOTTOMLEFT", p[24], "BOTTOMLEFT", 0, 0)
    p[30]:SetPoint("BOTTOMRIGHT", p[24], "BOTTOMRIGHT", -445.51, 0)

    parts.byUid["root.f7"] = p[24]

    parts.byUid["root"] = p[1]
    return parts
end
