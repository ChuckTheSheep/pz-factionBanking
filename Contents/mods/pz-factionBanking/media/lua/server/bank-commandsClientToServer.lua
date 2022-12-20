LuaEventManager.AddEvent("BANKING_ServerModDataReady")

local function onClientCommand(_module, _command, _player, _data)
    --if getDebug() then print("Received command from " .. _player:getUsername() .." [".._module..".".._command.."]") end

    if _module ~= "bank" then return end
    _data = _data or {}

    if _command == "ImportBanks" then
        _internal.copyAgainst(GLOBAL_BANK_ACCOUNTS, _data.banks)
        triggerEvent("BANKING_ServerModDataReady")
    end

    --[[
    if _command == "getOrSetWallet" then
        print("SETTING PLAYER WALLET: ".._data.playerID.."  for user:".._data.steamID)
        local playerID, steamID, playerUsername = _data.playerID, _data.steamID, _data.playerUsername
        WALLET_HANDLER.getOrSetPlayerWallet(playerID,steamID,playerUsername)
        triggerEvent("BANKING_ServerModDataReady")
    end
    --]]

    if _command == "transferFunds" then
        local transferValue, factionID = _data.transferValue, _data.factionID
        local playerObj, playerID, playerUsername = _data.playerObj, _data.playerID, _data.playerUsername
        ACCOUNTS_HANDLER.validateRequest(playerObj,playerID,playerUsername,transferValue,factionID)
    end


    if _command == "assignBank" then

        local bankID, x, y, z, mapObjName = _data.bankID, _data.x, _data.y, _data.z, _data.mapObjName
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
                if objMD and objMD.factionBankObjID and not GLOBAL_BANK_ACCOUNTS[objMD.factionBankObjID] then objMD.factionBankObjID = nil end

                if _command ~= "clearStoreFromMapObj" and objMD and objMD.factionBankObjID then
                    print("WARNING: ".._command.." failed: Matching object ID: ("..GLOBAL_BANK_ACCOUNTS[object:getModData().factionBankObjID].name.."); bypassed.")
                else
                    foundObjToApplyTo = object
                end
            end
        end

        if not foundObjToApplyTo then print("ERROR: No foundObjToApplyTo.") return end
        foundObjToApplyTo:getModData().factionBankObjID = bankID
        triggerEvent("BANKING_ServerModDataReady")
    end

end
Events.OnClientCommand.Add(onClientCommand)--/client/ to server

local function onServerModDataReady() sendServerCommand("bank", "severModData_received", {}) end
Events.BANKING_ServerModDataReady.Add(onServerModDataReady)