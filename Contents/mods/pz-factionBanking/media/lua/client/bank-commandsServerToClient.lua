local _internal = require "shop-shared"

LuaEventManager.AddEvent("BANKING_ClientModDataReady")

local function onClientModDataReady()
    if not isClient() then
        _internal.copyAgainst(GLOBAL_BANK_ACCOUNTS, CLIENT_BANK_ACCOUNTS)
    else
        ModData.request("BANK_ACCOUNTS")
    end
end
Events.BANKING_ClientModDataReady.Add(onClientModDataReady)


local function onServerCommand(_module, _command, _data)
    if _module ~= "bank" then return end
    _data = _data or {}

    if _command == "severModData_received" then onClientModDataReady() end

end
Events.OnServerCommand.Add(onServerCommand)
