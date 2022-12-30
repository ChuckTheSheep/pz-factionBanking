local clickHandler = require "shop-ISObjectClickHandler"

local clickHandler_canInteract = clickHandler.canInteract
function clickHandler.canInteract(mapObject)

    local canView = clickHandler_canInteract(mapObject)

    if not mapObject then return canView end

    local factionBankID = mapObject and mapObject:getModData().factionBankID
    if factionBankID then
        canView = false
        if (isAdmin() or isCoopHost() or getDebug()) then canView = true end
    end

    return canView
end
