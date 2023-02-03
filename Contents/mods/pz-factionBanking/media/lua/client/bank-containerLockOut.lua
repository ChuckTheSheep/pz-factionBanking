require "ISUI/ISInventoryPane"
require "ISUI/ISInventoryPage"

local containerLockOut = require "shop-containerLockOut"

local containerLockOut_canInteract = containerLockOut.canInteract
function containerLockOut.canInteract(worldObject)

    local canViewBefore = containerLockOut_canInteract(worldObject)
    local canView = canViewBefore

    if not worldObject then return canViewBefore end

    local factionBankID = worldObject and worldObject:getModData().factionBankID
    if factionBankID then
        canView = false
        if (isAdmin() or isCoopHost() or getDebug()) then canView = true end
    end

    return (canViewBefore and canView)
end