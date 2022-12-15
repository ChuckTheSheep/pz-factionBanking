require "shop-shared"

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
    if _module ~= "shop" then return end
    _data = _data or {}

    if _command == "severModData_received" then onClientModDataReady() end

    if _command == "withdraw" then
        local moneyTypes = _internal.getMoneyTypes()
        local type = moneyTypes[ZombRand(#moneyTypes)+1]
        local money = InventoryItemFactory.CreateItem(type)
        generateMoneyValue(money, _data.value)
        getPlayer():getInventory():AddItem(money)
    end

end
Events.OnServerCommand.Add(onServerCommand)
