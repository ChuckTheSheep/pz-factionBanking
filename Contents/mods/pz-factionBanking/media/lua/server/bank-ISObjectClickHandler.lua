require "ISObjectClickHandler"

local ISObjectClickHandler_doClick = ISObjectClickHandler.doClick
function ISObjectClickHandler.doClick(object, x, y)
    if not object then return end
    local factionBankID = object and object:getModData().factionBankID
    if not factionBankID then ISObjectClickHandler_doClick(object, x, y) end
end
