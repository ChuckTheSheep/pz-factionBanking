require "bank-window"
require "shop-contextMenu"
local _internal = require "shop-shared"

local CONTEXT_HANDLER = {}

---@param worldObject IsoObject
---@param playerObj IsoPlayer|IsoGameCharacter
function CONTEXT_HANDLER.browseBank(worldObjects, playerObj, worldObject, factionID)
    --local playerFaction = Faction.getPlayerFaction(playerObj)
    --local bankFaction = Faction.getFaction(factionID)
    --if not playerFaction or not (isAdmin() or isCoopHost() or getDebug()) then print(" ERROR: non-admin accessed context menu meant for assigning banks.") return end
    worldObject:getModData().factionBankID = worldObject:getModData().factionBankID or true
    bankWindow:onBrowse(factionID or true, worldObject)
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

    local playerIsFactionOwner = Faction.getPlayerFaction(playerObj)
    if playerIsFactionOwner then playerIsFactionOwner = playerIsFactionOwner:getOwner()==playerObj:getUsername() end

    for i=0,square:getObjects():size()-1 do
        ---@type IsoObject
        local object = square:getObjects():get(i)
        if object and (not instanceof(object, "IsoWorldInventoryObject")) then
            local factionID = object:getModData().factionBankID

            if factionID and factionID~=true and not Faction.factionExist(factionID) then
                object:getModData().factionBankID = nil
                object:transmitModData()
                factionID = nil
            end

            if factionID or playerIsFactionOwner or (isAdmin() or isCoopHost() or getDebug()) then
                validObjects[object] = factionID or false
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

        for worldObject,factionID in pairs(validObjects) do
            local objectName = _internal.getWorldObjectDisplayName(worldObject)
            if objectName then
                local contextText = objectName.." [ "..getText("ContextMenu_ASSIGN_BANK").." ]"
                if factionID==true then factionID = getText("IGUI_PUBLIC") end
                if factionID then contextText = getText("ContextMenu_BANK_AT").." "..(factionID.." "..getText("IGUI_BANK") or objectName) end
                currentMenu:addOptionOnTop(contextText, worldObjects, CONTEXT_HANDLER.browseBank, playerObj, worldObject, factionID)
            end
        end
    end

end
Events.OnFillWorldObjectContextMenu.Add(CONTEXT_HANDLER.generateContextMenu)
