-- InventoryWindow.lua
local frame, editBox

-- 1. CREACIÓN DE LA INTERFAZ
frame = CreateFrame("Frame", "InventoryWindow", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(400, 400)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("Inventory Exporter - Dreamlust Guild")

-- Registro para cerrar con ESC
tinsert(UISpecialFrames, "InventoryWindow")

-- ScrollFrame
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

-- EditBox
editBox = CreateFrame("EditBox", nil, scrollFrame)
editBox:SetMultiLine(true)
editBox:SetMaxLetters(999999)
editBox:SetFontObject("ChatFontNormal")
editBox:SetWidth(350)
editBox:SetAutoFocus(false)
editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() frame:Hide() end)
editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

scrollFrame:SetScrollChild(editBox)
frame:Hide()

-- 2. LÓGICA DE PROCESAMIENTO (iditem:cantidad)
local function AddItemsFromBag(bagID, inventoryMap)
    local slots = C_Container.GetContainerNumSlots(bagID)
    for slot = 1, slots do
        local info = C_Container.GetContainerItemInfo(bagID, slot)
        if info and info.itemID then
            local itemID = info.itemID
            -- Acumular cantidad total por ID
            inventoryMap[itemID] = (inventoryMap[itemID] or 0) + info.stackCount
        end
    end
end

local function BuildInventoryText()
    local inventoryMap = {} 
    local lines = {}
    
    -- OBTENER NOMBRE DEL PERSONAJE
    local playerName = UnitName("player")

    -- Mochilas (0-5)
    for bag = 0, 5 do AddItemsFromBag(bag, inventoryMap) end

    -- Banco (si está abierto)
    if BankFrame and BankFrame:IsShown() then
        AddItemsFromBag(-1, inventoryMap)
        for bag = 6, 12 do AddItemsFromBag(bag, inventoryMap) end
        AddItemsFromBag(-3, inventoryMap)
    end

    -- Obtener IDs para ordenar
    local sortedIDs = {}
    for itemID in pairs(inventoryMap) do
        table.insert(sortedIDs, itemID)
    end
    table.sort(sortedIDs)

    -- Formato de objetos: iditem:cantidad (sin espacios)
    for _, itemID in ipairs(sortedIDs) do
        table.insert(lines, itemID .. ":" .. inventoryMap[itemID])
    end

    -- Unimos todos los objetos con ";"
    local itemsText = table.concat(lines, ";")
    
    -- Resultado final: "NombrePersonaje id1:cant;id2:cant..."
    return playerName .. ";" .. itemsText
end

local function ShowInventory()
    local text = BuildInventoryText()
    frame:Show()
    editBox:SetText(text)
    editBox:SetFocus()
    editBox:HighlightText()
end

-- 3. COMANDOS Y EVENTOS
SLASH_OPENWINDOW1 = "/ie"
SlashCmdList["OPENWINDOW"] = function()
    ShowInventory()
end

local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("BANKFRAME_OPENED")
eventHandler:RegisterEvent("BANKFRAME_CLOSED")
eventHandler:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventHandler:SetScript("OnEvent", function(self)
    if frame:IsShown() then
        local text = BuildInventoryText()
        editBox:SetText(text)
    end
end)