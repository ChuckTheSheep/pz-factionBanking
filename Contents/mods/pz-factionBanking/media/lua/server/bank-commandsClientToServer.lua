LuaEventManager.AddEvent("BANKING_ServerModDataReady")

local function onClientCommand(_module, _command, _player, _data)
    --if getDebug() then print("Received command from " .. _player:getUsername() .." [".._module..".".._command.."]") end

    if _module ~= "bank" then return end
    _data = _data or {}

    if _command == "ImportBanks" then
        _internal.copyAgainst(GLOBAL_BANK_ACCOUNTS, _data.banks)
        triggerEvent("BANKING_ServerModDataReady")
    end

    if _command == "getOrSetWallet" then
        print("SETTING PLAYER WALLET: ".._data.playerID.."  for user:".._data.steamID)
        local playerID, steamID, playerUsername = _data.playerID, _data.steamID, _data.playerUsername
        WALLET_HANDLER.getOrSetPlayerWallet(playerID,steamID,playerUsername)
        triggerEvent("BANKING_ServerModDataReady")
    end

    if _command == "transferFunds" then
        local giverID, give, receiverID, receive = _data.giver, _data.give, _data.receiver, _data.receive
        local giverWallet, receiverWallet

        if giverID then giverWallet = WALLET_HANDLER.getOrSetPlayerWallet(giverID) end
        if receiverID then receiverWallet = WALLET_HANDLER.getOrSetPlayerWallet(receiverID) end

        if giverWallet and receiverWallet then
            if give then
                giverWallet.amount = giverWallet.amount-give
                receiverWallet.amount = receiverWallet.amount+give
            end
            if receive then
                giverWallet.amount = giverWallet.amount+receive
                receiverWallet.amount = receiverWallet.amount-receive
            end
        else
            if not receiverWallet then print("ERROR: transferFunds: No valid receiverWallet") end
            if not giverWallet then print("ERROR: transferFunds: No valid giverWallet") end
        end
        triggerEvent("BANKING_ServerModDataReady")
    end


    if _command == "assignStore" or _command == "copyStorePreset" or _command == "connectStorePreset" or _command == "clearStoreFromMapObj" then

        local storeID, x, y, z, mapObjName = _data.storeID, _data.x, _data.y, _data.z, _data.mapObjName
        local sq = getSquare(x, y, z)
        if not sq then print("ERROR: Could not find square for assigning store.") return end

        local objects = sq:getObjects()
        if not objects then print("ERROR: Could not find objects for assigning store.") return end

        local foundObjToApplyTo

        for i=0,objects:size()-1 do
            ---@type IsoObject|MapObjects
            local object = objects:get(i)
            if object and (not instanceof(object, "IsoWorldInventoryObject")) and _internal.getMapObjectName(object)==mapObjName then

                local objMD = object:getModData()
                if objMD and objMD.storeObjID and not GLOBAL_STORES[objMD.storeObjID] then objMD.storeObjID = nil end

                if _command ~= "clearStoreFromMapObj" and objMD and objMD.storeObjID then
                    print("WARNING: ".._command.." failed: Matching object ID: ("..GLOBAL_STORES[object:getModData().storeObjID].name.."); bypassed.")
                else
                    foundObjToApplyTo = object
                end
            end
        end

        if not foundObjToApplyTo then print("ERROR: No foundObjToApplyTo.") return end

        if _command == "connectStorePreset" then
            STORE_HANDLER.connectStoreByID(foundObjToApplyTo,storeID)
        elseif _command == "clearStoreFromMapObj" then
            STORE_HANDLER.clearStoreFromObject(foundObjToApplyTo)
        else --assign or copy
            STORE_HANDLER.copyStoreOntoObject(foundObjToApplyTo,storeID,true)
        end
        triggerEvent("BANKING_ServerModDataReady")
    end

end
Events.OnClientCommand.Add(onClientCommand)--/client/ to server

local function onServerModDataReady() sendServerCommand("bank", "severModData_received", {}) end
Events.BANKING_ServerModDataReady.Add(onServerModDataReady)