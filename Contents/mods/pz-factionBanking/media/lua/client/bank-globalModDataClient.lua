---Credit to Konijima (Konijima#9279) for clearing up networking :thumbsup:
require "bank-commandsServerToClient"
require "shop-globalModDataClient"
require "shop-shared"

CLIENT_BANK_ACCOUNTS = {}

local function initGlobalModData(isNewGame)

    if isClient() then
        if ModData.exists("BANK_ACCOUNTS") then ModData.remove("BANK_ACCOUNTS") end
    end

    CLIENT_BANK_ACCOUNTS = ModData.getOrCreate("BANK_ACCOUNTS")

    triggerEvent("BANKING_ClientModDataReady")
end
Events.OnInitGlobalModData.Add(initGlobalModData)


---@param name string
---@param data table
local function receiveGlobalModData(name, data)
    if name == "BANK_ACCOUNTS" then
        _internal.copyAgainst(CLIENT_BANK_ACCOUNTS,data)
    end
end
Events.OnReceiveGlobalModData.Add(receiveGlobalModData)