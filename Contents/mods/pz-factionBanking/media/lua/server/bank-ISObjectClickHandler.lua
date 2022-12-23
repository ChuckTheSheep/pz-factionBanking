require "ISObjectClickHandler"

local function validBankObject(mapObject)
    local canView = true
    local factionBankID = mapObject:getModData().factionBankID
    if factionBankID then
        local bankObj = GLOBAL_STORES[factionBankID]
        --TODO: Check faction for access.
        if bankObj.isBeingManaged and (isAdmin() or isCoopHost() or getDebug()) then canView = true end
        canView = false
    end
    return canView
end

local ISObjectClickHandler_doClick = ISObjectClickHandler.doClick
function ISObjectClickHandler.doClick(object, x, y)
    local allow = true
    if object then
        local factionBankID = object:getModData().factionBankID
        if factionBankID then allow = validBankObject(object) end
    end
    if allow then ISObjectClickHandler_doClick(object, x, y) end
end
