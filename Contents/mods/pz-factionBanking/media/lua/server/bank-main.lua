require "bank-globalModDataServer"
require "bank-shared"
require "shop-main"

ACCOUNTS_HANDLER = {}
---@class account Pseudo-Object
local account = {}
account.faction = false
account.factionLocked = true
account.amount = 0
account.usedByHistory = {}
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
    for factionName,accountActual in pairs(GLOBAL_BANK_ACCOUNTS) do
        if accountActual.dead and accountActual.usedByHistory[playerID] then
            local amount = accountActual.usedByHistory[playerID]

            local playerWallet = WALLET_HANDLER.getOrSetPlayerWallet(playerID)
            if not playerWallet then print("ERROR: ACCOUNTS_HANDLER.parseDeadAccounts: No valid player wallet") return end

            if (amount ~= 0) then
                amount = math.min(amount,accountActual.amount)
                accountActual.amount = accountActual.amount-amount
                playerWallet.amount = playerWallet.amount+amount
            end

            accountActual.usedByHistory[playerID] = nil
        end
    end
end

function ACCOUNTS_HANDLER.getOrSetFactionAccount(faction,factionLocked)
    local matchingAccount = GLOBAL_BANK_ACCOUNTS[faction] or ACCOUNTS_HANDLER.new(faction)
    matchingAccount.factionLocked = matchingAccount.factionLocked or factionLocked
    return matchingAccount
end

---@param playerObj IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
function ACCOUNTS_HANDLER.validateRequest(playerObj,playerID,requestAmount)

    local playerWallet = WALLET_HANDLER.getOrSetPlayerWallet(playerID)
    if not playerWallet then print("ERROR: ACCOUNTS_HANDLER.validateRequest: No valid player wallet") return end

    local faction = Faction.getPlayerFaction(playerObj)
    if not faction then return end
    local factionAccount = ACCOUNTS_HANDLER.getOrSetFactionAccount(faction)

    if (requestAmount ~= 0 ) and faction then
        --deposits = negative, withdraws = positive
        playerWallet.amount = playerWallet.amount-requestAmount
        factionAccount.amount = factionAccount.amount+requestAmount
    end
end