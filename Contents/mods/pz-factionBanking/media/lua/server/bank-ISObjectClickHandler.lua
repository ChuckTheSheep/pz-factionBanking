require "ISObjectClickHandler"

local function validBankObject(mapObject)
    local canView = true
    local bankObjID = mapObject:getModData().bankObjID
    if bankObjID then
        local bankObj = GLOBAL_STORES[bankObjID]
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
        local bankObjID = object:getModData().bankObjID
        if bankObjID then allow = validBankObject(object) end
    end
    if allow then ISObjectClickHandler_doClick(object, x, y) end
end
