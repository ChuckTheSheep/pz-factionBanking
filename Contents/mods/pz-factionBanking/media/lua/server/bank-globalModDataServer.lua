---Credit to Konijima (Konijima#9279) for clearing up networking :thumbsup:
require "bank-commandsClientToServer"
GLOBAL_BANK_ACCOUNTS = {}

local function banksModDataInit(isNewGame)
    GLOBAL_BANK_ACCOUNTS = ModData.getOrCreate("BANK_ACCOUNTS")
    if not isNewGame then triggerEvent("BANKING_ServerModDataReady") end
end

Events.OnInitGlobalModData.Add(banksModDataInit)
