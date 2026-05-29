-- Constantes y fabricas UI pequenas usadas por la ficha Harford DnD.

HarfordDnDUI = HarfordDnDUI or {}

HarfordDnDUI.TEX = {
    PARCH  = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
    ROCK   = "Interface\\FrameGeneral\\UI-Background-Rock",
    MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble",
    WHITE  = "Interface\\Buttons\\WHITE8x8",
    BOOK   = "Interface\\Icons\\INV_Misc_Book_09",
    QMARK  = "Interface\\Icons\\inv_misc_dice_02",
    STR    = "Interface\\Icons\\Ability_Warrior_StrengthOfArms",
    SHIELD = "Interface\\Icons\\INV_Shield_06",
    EYE    = "Interface\\Icons\\Ability_EyeOfTheOwl",
    ATK    = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
    CAMPFIRE = "Interface\\Icons\\ability_racial_makecamp",
    HOURGLASS = "Interface\\Icons\\INV_Misc_PocketWatch_01",
}

HarfordDnDUI.SECTION_TEX = {
    TOP = HarfordDnDUI.TEX.PARCH,
    ABI = HarfordDnDUI.TEX.PARCH,
    SAV = HarfordDnDUI.TEX.ROCK,
    ATK = HarfordDnDUI.TEX.PARCH,
    SKL = HarfordDnDUI.TEX.PARCH,
}

HarfordDnDUI.LAYOUT = {
    FRAME_W = 420,
    FRAME_H = 405,
    FRAME_X = -210,
    FRAME_Y = 0,

    SEC_X = 14,
    SEC_W = 392,

    TOP_Y = -44,
    TOP_H = 126,

    TAB_Y = -176,
    TAB_H = 28,

    PANEL_Y = -208,
    PANEL_H = 183,
}

function HarfordDnDUI.SetFrameBackground(frame, texturePath, alpha)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -13)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -7, 7)
    bg:SetTexture(texturePath)
    bg:SetAlpha(alpha or 1)
    return bg
end

function HarfordDnDUI.CreateSection(parent, titleText, iconPath, x, y, w, h, bgTexture, bgAlpha)
    local tex = HarfordDnDUI.TEX
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    section:SetSize(w, h)

    local bg = section:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(section)
    bg:SetTexture(bgTexture or tex.PARCH)
    bg:SetAlpha(bgAlpha or 0.9)

    local border = section:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", 0, 0)
    border:SetTexture(tex.WHITE)
    border:SetAlpha(0.10)

    local header = CreateFrame("Frame", nil, section)
    header:SetPoint("TOPLEFT", 8, -6)
    header:SetPoint("TOPRIGHT", -8, -6)
    header:SetHeight(20)

    local icon
    if iconPath then
        icon = header:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", 0, 0)
        icon:SetTexture(iconPath)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("LEFT", icon and 20 or 0, 0)
    title:SetText(titleText or "")

    local sep = section:CreateTexture(nil, "BORDER")
    sep:SetPoint("TOPLEFT", 8, -28)
    sep:SetPoint("TOPRIGHT", -8, -28)
    sep:SetHeight(1)
    sep:SetTexture(tex.WHITE)
    sep:SetAlpha(0.20)

    return section
end

function HarfordDnDUI.MakeButton(parent, text, w, h, x, y, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end
