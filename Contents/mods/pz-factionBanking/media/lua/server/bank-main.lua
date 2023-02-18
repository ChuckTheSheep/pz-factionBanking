require "bank-globalModDataServer"
require "shop-commandsClientToServer"
require "bank-shared"
require "shop-main"

ACCOUNTS_HANDLER = {}
---@class account Pseudo-Object
local account = {}
account.faction = false
account.owner = false
account.amount = 0
account.usedByHistory = {} --[PID] = {username=false,balance=0}
account.dead = false

---Faction.getPlayerFaction(getPlayer())
---Faction.getFaction(string)
--faction:isMember(username)
--faction:isOwner(username)

function ACCOUNTS_HANDLER.new(faction)
    if not faction then print("ERROR: account:new - No faction provided.") return end
    local newAccount = copyTable(account)
    newAccount.faction = faction
    GLOBAL_BANK_ACCOUNTS[newAccount.faction] = newAccount
end

function ACCOUNTS_HANDLER.parseDeadAccounts(playerObj,playerID)
    local removeEntries = {}
    for factionName,accountActual in pairs(GLOBAL_BANK_ACCOUNTS) do
        if accountActual then
            
            local factionActual = Faction.getFaction(factionName)
            if not factionActual or (factionActual and (account.owner ~= factionActual:getOwner() )) then
                accountActual.dead = true
                accountActual.faction = accountActual.faction.."\[DEAD\]"
            end
            
            if accountActual.dead and accountActual.usedByHistory[playerID] then
                local amount = accountActual.usedByHistory[playerID].balance

                local playerWallet = WALLET_HANDLER.getOrSetPlayerWallet(playerID)
                if not playerWallet then print("ERROR: ACCOUNTS_HANDLER.parseDeadAccounts: No valid player wallet") return end

                if (amount ~= 0 and accountActual.amount > 0) then
                    amount = math.min(amount,accountActual.amount)
                    accountActual.amount = accountActual.amount-amount
                    playerWallet.amount = playerWallet.amount+amount
                end

                accountActual.usedByHistory[playerID] = nil
            end

            if accountActual.amount <= 0 then table.insert(removeEntries, factionName) end
        end
    end
    --remove empty and dead entries
    for _,factionID in pairs(removeEntries) do GLOBAL_BANK_ACCOUNTS[factionID] = nil end
end

function ACCOUNTS_HANDLER.getOrSetFactionAccount(faction)
    local matchingAccount = GLOBAL_BANK_ACCOUNTS[faction] or ACCOUNTS_HANDLER.new(faction)
    return matchingAccount
end

---@param playerObj IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
function ACCOUNTS_HANDLER.validateRequest(playerObj,playerID,playerUsername,requestAmount,factionID,directDeposit)

    local playerWallet = WALLET_HANDLER.getOrSetPlayerWallet(playerID)
    if not playerWallet then print("ERROR: ACCOUNTS_HANDLER.validateRequest: No valid player wallet") return end
    if not factionID then print("WARN: ACCOUNTS_HANDLER.validateRequest: No factionID provided") return end

    local factionAccount = ACCOUNTS_HANDLER.getOrSetFactionAccount(factionID)
    if not factionAccount then print("ERROR: ACCOUNTS_HANDLER.validateRequest: No valid factionAccount") return end

    if requestAmount ~= 0 then
        --deposits = negative, withdraws = positive
        factionAccount.amount = _internal.floorCurrency(factionAccount.amount+requestAmount)

        if (not directDeposit or requestAmount<0) then
            WALLET_HANDLER.validateMoneyOrWallet(playerWallet,playerObj,0-requestAmount)
        end

        local balanceBefore = (account.usedByHistory[playerID] and account.usedByHistory[playerID].balance) or 0
        account.usedByHistory[playerID] = {username=playerUsername,balance=balanceBefore+requestAmount}
        triggerEvent("SHOPPING_ServerModDataReady")
        triggerEvent("BANKING_ServerModDataReady")
    end
end
