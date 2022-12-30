require "ISUI/ISInventoryPane"
require "ISUI/ISInventoryPage"

local containerLockOut = require "shop-containerLockOut"

local containerLockOut_canInteract = containerLockOut.canInteract
function containerLockOut.canInteract(mapObject)

    local canViewBefore = containerLockOut_canInteract(mapObject)
    local canView = canViewBefore

    if not mapObject then return canViewBefore end

    local factionBankID = mapObject and mapObject:getModData().factionBankID
    if factionBankID then
        canView = false
        if (isAdmin() or isCoopHost() or getDebug()) then canView = true end
    end

    return (canViewBefore and canView)
end