LuaEventManager.AddEvent("BANKING_ServerModDataReady")

local function onClientCommand(_module, _command, _player, _data)
    --if getDebug() then print("Received command from " .. _player:getUsername() .." [".._module..".".._command.."]") end

    if _module ~= "bank" then return end
    _data = _data or {}

    if _command == "transferFunds" then
        print("transferFunds")
        local transferValue, factionID = _data.transferValue, _data.factionID
        local playerObj, playerID, playerUsername = _data.playerObj, _data.playerID, _data.playerUsername
        ACCOUNTS_HANDLER.validateRequest(playerObj,playerID,playerUsername,transferValue,factionID)
    end

    if _command == "removeBank" then

        local x, y, z, mapObjName = _data.x, _data.y, _data.z, _data.mapObjName
        local sq = getSquare(x, y, z)
        if not sq then print("ERROR: Could not find square for assigning bank.") return end

        local objects = sq:getObjects()
        if not objects then print("ERROR: Could not find objects for assigning bank.") return end

        local foundObjToApplyTo
        for i=0,objects:size()-1 do
            ---@type IsoObject|MapObjects
            local object = objects:get(i)
            if object and (not instanceof(object, "IsoWorldInventoryObject")) and _internal.getMapObjectName(object)==mapObjName then
                local objMD = object:getModData()
                if objMD and objMD.factionBankID then
                    foundObjToApplyTo = object
                end
            end
        end
        if not foundObjToApplyTo then print("ERROR: No foundObjToApplyTo.") return end
        local foundObjToApplyToModData = foundObjToApplyTo:getModData()
        foundObjToApplyToModData.factionBankID = nil
        foundObjToApplyToModData.factionBankLocked = nil
        foundObjToApplyTo:transmitModData()
        triggerEvent("BANKING_ServerModDataReady")
    end

    if _command == "assignBank" then

        local bankID, x, y, z, mapObjName, factionLocked = _data.bankID, _data.x, _data.y, _data.z, _data.mapObjName, _data.factionLocked
        local sq = getSquare(x, y, z)
        if not sq then print("ERROR: Could not find square for assigning bank.") return end

        local objects = sq:getObjects()
        if not objects then print("ERROR: Could not find objects for assigning bank.") return end

        local foundObjToApplyTo

        for i=0,objects:size()-1 do
            ---@type IsoObject|MapObjects
            local object = objects:get(i)
            if object and (not instanceof(object, "IsoWorldInventoryObject")) and _internal.getMapObjectName(object)==mapObjName then

                local accObj = GLOBAL_BANK_ACCOUNTS[object:getModData().factionBankID]
                local objMD = object:getModData()
                if objMD and objMD.factionBankID and not accObj then
                    objMD.factionBankID = nil
                end
                if objMD and objMD.factionBankID and accObj then
                    print("WARNING: ".._command.." failed: Matching object ID: ("..accObj.name.."); bypassed.")
                else
                    foundObjToApplyTo = object
                end
            end
        end

        if not foundObjToApplyTo then print("ERROR: No foundObjToApplyTo.") return end
        ACCOUNTS_HANDLER.getOrSetFactionAccount(bankID)
        local foundObjToApplyToModData = foundObjToApplyTo:getModData()
        foundObjToApplyToModData.factionBankID = bankID
        foundObjToApplyToModData.factionBankLocked = factionLocked
        foundObjToApplyTo:transmitModData()
        triggerEvent("BANKING_ServerModDataReady")
    end

end
Events.OnClientCommand.Add(onClientCommand)--/client/ to server

local function onServerModDataReady() sendServerCommand("bank", "severModData_received", {}) end
Events.BANKING_ServerModDataReady.Add(onServerModDataReady)