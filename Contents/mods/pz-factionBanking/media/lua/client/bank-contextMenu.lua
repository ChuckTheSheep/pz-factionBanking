require "bank-window"

local CONTEXT_HANDLER = {}

---@param mapObject MapObjects|IsoObject
function CONTEXT_HANDLER.browseBank(worldObjects, playerObj, mapObject, bankAccount)
    if not (isAdmin() or isCoopHost() or getDebug()) then print(" ERROR: non-admin accessed context menu meant for assigning banks.") return end
    bankWindow:onBrowse(bankAccount, mapObject)
end


function CONTEXT_HANDLER.generateContextMenu(playerID, context, worldObjects)
    local playerObj = getSpecificPlayer(playerID)
    local square

    for _,v in ipairs(worldObjects) do square = v:getSquare() end
    if not square then return end

    if (math.abs(playerObj:getX()-square:getX())>2) or (math.abs(playerObj:getY()-square:getY())>2) then return end

    local validObjects = {}
    local validObjectCount = 0

    triggerEvent("BANKING_ClientModDataReady")

    for i=0,square:getObjects():size()-1 do
        ---@type IsoObject|MapObjects
        local object = square:getObjects():get(i)
        if object and (not instanceof(object, "IsoWorldInventoryObject")) then

            if object:getModData().factionBankID then
                local account = CLIENT_BANK_ACCOUNTS[object:getModData().factionBankID]
                if not account then object:getModData().factionBankID = nil end
            end

            if object:getModData().factionBankID or (isAdmin() or isCoopHost() or getDebug()) then
                validObjects[object] = CLIENT_BANK_ACCOUNTS[object:getModData().factionBankID] or false
                validObjectCount = validObjectCount+1
            end
        end
    end

    local currentMenu = context
    if validObjectCount > 0 then
        if validObjectCount>1 then
            local mainMenu = context:addOptionOnTop(getText("ContextMenu_BANKS"), worldObjects, nil)
            local subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(mainMenu, subMenu)
            currentMenu = subMenu
        end

        for mapObject,bankAccount in pairs(validObjects) do
            local objectName = _internal.getMapObjectDisplayName(mapObject)
            if objectName then
                local contextText = objectName.." [ "..getText("ContextMenu_ASSIGN_BANK").." ]"
                if bankAccount then
                    contextText = getText("ContextMenu_BANK_AT").." "..(bankAccount.name or objectName)
                end
                currentMenu:addOptionOnTop(contextText, worldObjects, CONTEXT_HANDLER.browseBank, playerObj, mapObject, bankAccount)
            end
        end
    end

end
Events.OnFillWorldObjectContextMenu.Add(CONTEXT_HANDLER.generateContextMenu)
