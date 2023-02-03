local clickHandler = require "shop-ISObjectClickHandler"

local clickHandler_canInteract = clickHandler.canInteract
function clickHandler.canInteract(worldObject)

    local canView = clickHandler_canInteract(worldObject)

    if not worldObject then return canView end

    local factionBankID = worldObject and worldObject:getModData().factionBankID
    if factionBankID then
        canView = false
        if (isAdmin() or isCoopHost() or getDebug()) then canView = true end
    end

    return canView
end
