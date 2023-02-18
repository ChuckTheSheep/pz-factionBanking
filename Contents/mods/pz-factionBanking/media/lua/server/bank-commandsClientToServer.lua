LuaEventManager.AddEvent("BANKING_ServerModDataReady")

local function onClientCommand(_module, _command, _player, _data)
    --if getDebug() then print("Received command from " .. _player:getUsername() .." [".._module..".".._command.."]") end

    if _module ~= "bank" then return end
    _data = _data or {}

    if _command == "transferFunds" then
        local transferValue, factionID, directDeposit = _data.transferValue, _data.factionID, _data.directDeposit
        local playerID, playerUsername = _data.playerID, _data.playerUsername
        ACCOUNTS_HANDLER.validateRequest(_player,playerID,playerUsername,transferValue,factionID,directDeposit)
    end

    if _command == "removeBank" then

        local x, y, z, worldObjName = _data.x, _data.y, _data.z, _data.worldObjName
        local sq = getSquare(x, y, z)
        if not sq then print("ERROR: Could not find square for assigning bank.") return end

        local objects = sq:getObjects()
        if not objects then print("ERROR: Could not find objects for assigning bank.") return end

        local foundObjToApplyTo
        for i=0,objects:size()-1 do
            ---@type IsoObject
            local object = objects:get(i)
            if object and (not instanceof(object, "IsoWorldInventoryObject")) and _internal.getWorldObjectName(object)==worldObjName then
                foundObjToApplyTo = object
            end
        end
        if not foundObjToApplyTo then print("ERROR: removeBank: No foundObjToApplyTo : "..worldObjName) return end

        foundObjToApplyTo:getModData().factionBankID = nil
        foundObjToApplyTo:transmitModData()
        triggerEvent("BANKING_ServerModDataReady")
    end

    if _command == "assignBank" then

        local bankID, x, y, z, worldObjName = _data.bankID, _data.x, _data.y, _data.z, _data.worldObjName
        local sq = getSquare(x, y, z)
        if not sq then print("ERROR: Could not find square for assigning bank.") return end

        local objects = sq:getObjects()
        if not objects then print("ERROR: Could not find objects for assigning bank.") return end

        local foundObjToApplyTo

        for i=0,objects:size()-1 do
            ---@type IsoObject
            local object = objects:get(i)
            if object and (not instanceof(object, "IsoWorldInventoryObject")) and _internal.getWorldObjectName(object)==worldObjName then

                local accObj = GLOBAL_BANK_ACCOUNTS[object:getModData().factionBankID]
                local objMD = object:getModData()
                if objMD and objMD.factionBankID and (not accObj or (accObj and accObj.dead)) then
                    objMD.factionBankID = nil
                    object:transmitModData()
                end

                foundObjToApplyTo = object
            end
        end

        if not foundObjToApplyTo then print("ERROR: assignBank: No foundObjToApplyTo : "..worldObjName) return end
        ACCOUNTS_HANDLER.getOrSetFactionAccount(bankID)
        foundObjToApplyTo:getModData().factionBankID = bankID
        foundObjToApplyTo:transmitModData()
        triggerEvent("BANKING_ServerModDataReady")
    end

end
Events.OnClientCommand.Add(onClientCommand)--/client/ to server

local function onServerModDataReady() sendServerCommand("bank", "severModData_received", {}) end
Events.BANKING_ServerModDataReady.Add(onServerModDataReady)