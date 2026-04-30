-- Contest Arbiter
-- LogLan 2026 – Turnier Regelprüfung
-- Version 0.1.0

local ADDON_NAME = "ContestArbiter"

-- ============================================================
-- Hauptfenster
-- ============================================================
local mainFrame = CreateFrame("Frame", "ContestArbitrFrame", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(420, 520)
mainFrame:SetPoint("CENTER")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
mainFrame:Hide()

mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainFrame.title:SetPoint("LEFT", mainFrame.TitleBg, "LEFT", 5, 0)
mainFrame.title:SetText("Contest Arbiter  |  Ruleset: LogLan 2026")

-- ============================================================
-- ScrollFrame
-- ============================================================
local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -28)
scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -26, 32)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(380, 900)
scrollFrame:SetScrollChild(content)

-- ============================================================
-- UI Hilfsfunktionen
-- ============================================================
local fontStrings = {}
local yOffset = 0

local function resetUI()
    for _, fs in ipairs(fontStrings) do
        fs:SetText("")
    end
    fontStrings = {}
    yOffset = -8
end

local function addHeader(text, color, current, max, tooltip)
    local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOffset)
    fs:SetText((color or "|cffffd100") .. text .. "|r")
    table.insert(fontStrings, fs)
    if current ~= nil and max ~= nil then
        local pts = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        pts:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, yOffset)
        pts:SetText((color or "|cffffd100") .. current .. "|r / " .. max .. " Punkte")
        table.insert(fontStrings, pts)
    end
    -- Info-Button mit Tooltip
    if tooltip then
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(16, 16)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 8 + fs:GetStringWidth() + 6, yOffset)
        local icon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        icon:SetAllPoints()
        icon:SetText("|cff00ccff[?]|r")
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(text, 1, 0.82, 0)
            GameTooltip:AddLine(" ")
            for _, line in ipairs(tooltip) do
                GameTooltip:AddLine(line, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    yOffset = yOffset - 20
    local line = content:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.8, 0, 0.4)
    line:SetSize(370, 1)
    line:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOffset)
    yOffset = yOffset - 8
end

local function addRow(label, current, max)
    local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOffset)
    fs:SetText(label)
    table.insert(fontStrings, fs)
    local pts = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pts:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, yOffset)
    if max ~= nil then
        pts:SetText("|cffffd100" .. current .. "|r / " .. max .. " Punkte")
    else
        pts:SetText(tostring(current))
    end
    table.insert(fontStrings, pts)
    yOffset = yOffset - 18
end

local function addKORow(tag, label, status, statusColor)
    local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOffset)
    fs:SetText((statusColor or "|cffffffff") .. tag .. "|r |cffffd100" .. label .. "|r")
    table.insert(fontStrings, fs)
    local st = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    st:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, yOffset)
    st:SetText("|cffffd100" .. status .. "|r")
    table.insert(fontStrings, st)
    yOffset = yOffset - 20
end

local function addSpacer()
    yOffset = yOffset - 8
end

-- ============================================================
-- Punkte berechnen
-- ============================================================
local function getProfPoints()
    local total = 0
    local prof1, prof2, _, fishing, cooking, firstAid = GetProfessions()
    local function pts(idx)
        if not idx then return 0 end
        local _, _, rank = GetProfessionInfo(idx)
        if rank >= 150 then return 2 elseif rank >= 75 then return 1 end
        return 0
    end
    total = pts(prof1) + pts(prof2) + pts(fishing) + pts(cooking)
    local function pts1(idx)
        if not idx then return 0 end
        local _, _, rank = GetProfessionInfo(idx)
        return rank >= 150 and 1 or 0
    end
    total = total + pts1(firstAid)
    return total
end

-- ============================================================
-- UI aufbauen
-- ============================================================
local function buildUI()
    resetUI()
    local totalPoints = 0

    -- LEVEL
    local lvl = UnitLevel("player")
    addHeader("Level", nil, lvl, 60)
    totalPoints = totalPoints + lvl
    addSpacer()

    -- BERUFE
    local prof1, prof2, _, fishing, cooking, firstAid = GetProfessions()
    local function profPts(idx, maxPts)
        if not idx then return 0 end
        local _, _, rank = GetProfessionInfo(idx)
        if rank >= 150 then return math.min(2, maxPts)
        elseif rank >= 75 then return math.min(1, maxPts) end
        return 0
    end
    local function profRow(idx, maxPts)
        if not idx then return end
        local name, _, rank = GetProfessionInfo(idx)
        local p = profPts(idx, maxPts)
        addRow("  " .. name .. " (" .. rank .. ")", p, maxPts)
    end

    -- Hauptberufe (max 3 Pkt)
    local hauptTotal = math.min(3, profPts(prof1, 2) + profPts(prof2, 2))
    addHeader("Hauptberufe", nil, hauptTotal, 3, {
        "Herstellungsberuf:",
        "  ab Skill 75  -> 1 Punkte",
        "  ab Skill 150 -> 2 Punkte",
        " ",
        "Sammelberuf:",
        "  ab Skill 150 -> 1 Punkte",
    })
    profRow(prof1, 2)
    profRow(prof2, 2)
    addSpacer()

    -- Nebenberufe (max 5 Pkt)
    local nebenTotal = profPts(fishing, 2) + profPts(cooking, 2) + profPts(firstAid, 1)
    addHeader("Nebenberufe", nil, nebenTotal, 5, {
        "Angeln:      ab Skill 150 -> 2 Punkte",
        "Kochen:      ab Skill 150 -> 2 Punkte",
        "Erste Hilfe: ab Skill 150 -> 1 Punkte",
    })
    profRow(fishing, 2)
    profRow(cooking, 2)
    profRow(firstAid, 1)
    totalPoints = totalPoints + hauptTotal + nebenTotal
    addSpacer()

    -- DUNGEONS
    addHeader("Dungeons", nil, 0, 7, {
        "- Nur mit Gildenmitgliedern betreten.",
        "- Ein einziger Dungeon zaehlt zur Wertung.",
        "- Alle Spieler muessen ueberleben.",
        "  Stirbt einer: keine Punkte.",
        "- Screenshot von jedem Mitspieler",
        "  am Anfang und am Ende erforderlich.",
        " ",
        "Die Hoehlen des Wehklagens  - 4 Punkte",
        "Burg Schattenfang           - 7 Punkte",
        "Tiefschwarze Grotte         - 5 Punkte",
        "Die Todesminen              - 5 Punkte",
    })
    addRow("  Die Hoehlen des Wehklagens", 0, 4)
    addRow("  Burg Schattenfang", 0, 7)
    addRow("  Tiefschwarze Grotte", 0, 5)
    addRow("  Die Todesminen", 0, 5)
    addSpacer()

    -- FOLIANTEN & BÜCHER
    addHeader("Folianten & Buecher", nil, 0, 1)
    addRow("  Der gestohlene Foliant", 0, 1)
    addSpacer()

    -- GEBIETE
    addHeader("Gebiete entdeckt", nil, 0, 19)
    addRow("  Tirisfal", 0, 1)
    addRow("  Mulgore", 0, 1)
    addRow("  Durotar", 0, 1)
    addRow("  Brachland", 0, 2)
    addRow("  Silberwald", 0, 2)
    addRow("  Steinkrallengebirge", 0, 3)
    addRow("  Tausend Nadeln", 0, 3)
    addRow("  Eschental", 0, 3)
    addRow("  Vorgebirge des Huegellands", 0, 3)
    addSpacer()

    -- GESAMTPUNKTE
    local sumLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sumLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOffset)
    sumLabel:SetText("|cffffd100Gesamtpunkte|r")
    table.insert(fontStrings, sumLabel)
    local sumValue = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sumValue:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, yOffset)
    sumValue:SetText("|cffffd100" .. totalPoints .. " Punkte|r")
    table.insert(fontStrings, sumValue)
    yOffset = yOffset - 24
    addSpacer()

    -- KO KRITERIEN
    addHeader("KO-Kriterien", "|cffffd100")

    -- 24h Timer
    local startTime = ContestArbitrDB and ContestArbitrDB.startTime
    if startTime then
        local elapsed = GetServerTime() - startTime
        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        local s = elapsed % 60
        local timeStr = string.format("%02d:%02d:%02d von 24:00:00", h, m, s)
        if elapsed > 86400 then
            addKORow("[VERSTOSS]", "Spielzeit", timeStr, "|cffff0000")
        elseif elapsed >= 85800 then
            addKORow("[WARNUNG]", "Spielzeit", timeStr, "|cffffff00")
        else
            addKORow("[OK]", "Spielzeit", timeStr, "|cff00ff00")
        end
    else
        addKORow("[?]", "Spielzeit", "Nicht gestartet", "|cffffff00")
    end

    -- Hardcore
    local hardcore = C_GameRules.IsHardcoreActive()
    addKORow(hardcore and "[OK]" or "[VERSTOSS]", "Hardcore Modus",
        hardcore and "Aktiv" or "Inaktiv",
        hardcore and "|cff00ff00" or "|cffff0000")

    -- Self-Found
    local selfFound = C_GameRules.IsSelfFoundAllowed()
    addKORow(selfFound and "[OK]" or "[VERSTOSS]", "Self-Found",
        selfFound and "Aktiv" or "Inaktiv",
        selfFound and "|cff00ff00" or "|cffff0000")

    -- ADDONS
    addSpacer()
    local seen = ContestArbitrDB and ContestArbitrDB.addonSeen or {}
    local seenCount = 0
    for _ in pairs(seen) do seenCount = seenCount + 1 end
    local totalAddonCount = seenCount + 1 -- +1 fuer ContestArbiter selbst

    addHeader("Addons (" .. totalAddonCount .. ")", "|cffffd100", nil, nil, {
        "Keine weiteren Addons erlaubt.",
    })

    -- ContestArbiter selbst
    addKORow("[OK]", "  " .. ADDON_NAME, "aktiv", "|cff00ff00")

    -- Alle anderen Addons
    local now = GetServerTime()
    for name, data in pairs(seen) do
        local total = (data.totalSeconds or 0)
        if data.lastCheck then
            total = total + (now - data.lastCheck)
        end
        local h = math.floor(total / 3600)
        local m = math.floor((total % 3600) / 60)
        local s = total % 60
        local timeStr = string.format("%02d:%02d:%02d", h, m, s)
        local suffix = data.active and "" or " (deaktiviert)"
        local isVerstoss = total > 60
        local tag = isVerstoss and "[VERSTOSS]" or "[WARNUNG]"
        local col = isVerstoss and "|cffff0000" or "|cffffff00"
        addKORow(tag, "  " .. name .. suffix, timeStr, col)
    end
end

-- ============================================================
-- Refresh Button
-- ============================================================
local refreshBtn = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
refreshBtn:SetSize(100, 22)
refreshBtn:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 8)
refreshBtn:SetText("Aktualisieren")
refreshBtn:SetScript("OnClick", function()
    buildUI()
end)

-- ============================================================
-- Slash Commands
-- ============================================================
SLASH_CONTESTARBITER1 = "/contestarbiter"
SLASH_CONTESTARBITER2 = "/ca"
SlashCmdList["CONTESTARBITER"] = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        buildUI()
        mainFrame:Show()
    end
end

-- ============================================================
-- Addon geladen
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == ADDON_NAME then
        ContestArbitrDB = ContestArbitrDB or {}
        if not ContestArbitrDB.startTime then
            ContestArbitrDB.startTime = GetServerTime()
        end
        -- Fremde Addons tracken: aktive Zeit aufsummieren
        ContestArbitrDB.addonSeen = ContestArbitrDB.addonSeen or {}
        local now = GetServerTime()
        -- Migration: altes Format (number) auf neues Format (table) umstellen
        for name, data in pairs(ContestArbitrDB.addonSeen) do
            if type(data) ~= "table" then
                ContestArbitrDB.addonSeen[name] = { firstSeen = data, totalSeconds = 0 }
            end
        end
        -- Aktive Zeit seit letztem Login für bekannte Addons aufaddieren
        for name, data in pairs(ContestArbitrDB.addonSeen) do
            if data.lastCheck then
                data.totalSeconds = (data.totalSeconds or 0) + (now - data.lastCheck)
                data.lastCheck = nil
            end
        end
        -- Aktuell aktive Addons erfassen
        for i = 1, GetNumAddOns() do
            local name, _, _, enabled = GetAddOnInfo(i)
            if enabled and name ~= ADDON_NAME then
                if not ContestArbitrDB.addonSeen[name] then
                    ContestArbitrDB.addonSeen[name] = { firstSeen = now, totalSeconds = 0 }
                end
                ContestArbitrDB.addonSeen[name].lastCheck = now
                ContestArbitrDB.addonSeen[name].active = true
            else
                if ContestArbitrDB.addonSeen[name] then
                    ContestArbitrDB.addonSeen[name].active = false
                end
            end
        end
        print("|cffffd100Contest Arbiter|r geladen. /ca zum Oeffnen.")
    end
end)
