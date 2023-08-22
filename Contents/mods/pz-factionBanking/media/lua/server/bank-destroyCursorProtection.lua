require "BuildingObjects/ISDestroyCursor"
--local _internal = require "shop-shared"

local _canDestroy = ISDestroyCursor.canDestroy
function ISDestroyCursor:canDestroy(object)

    local original = _canDestroy(self, object)

    local objectModData = object:getModData()
    if objectModData then
        local bankObjID = objectModData.factionBankID
        if bankObjID then
            local bankObj = GLOBAL_BANK_ACCOUNTS[bankObjID]
            if bankObj then--and not _internal.canManageStore(storeObj,self.character) then
                return false
            end
        end
    end

    return original
end