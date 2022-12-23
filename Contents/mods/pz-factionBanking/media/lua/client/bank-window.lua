require "ISUI/ISPanelJoypad"
require "bank-globalModDataClient"
require "luautils"

---@class bankWindow : ISPanel
bankWindow = ISPanelJoypad:derive("bankWindow")

bankWindow.messages = {}
bankWindow.CoolDownMessage = 300
bankWindow.MaxItems = 20


function bankWindow:initialise()
    ISPanelJoypad.initialise(self)
    local btnWid = 100
    local btnHgt = 25
    local pad = 10

    local bankName = "No Faction Set"
    if self.bankAccount then bankName = self.bankAccount.faction end

    self.blocker = ISPanel:new(0,0, self.width, self.height)
    self.blocker.moveWithMouse = true
    self.blocker:initialise()
    self.blocker:instantiate()
    self.blocker:drawRect(0, 0, self.blocker.width, self.blocker.height, 0.8, 0, 0, 0)
    self:addChild(self.blocker)

    self.manageFaction = ISTextEntryBox:new(bankName, pad, pad, self.width-20, btnHgt-4)
    self.manageFaction:initialise()
    self.manageFaction:instantiate()
    self.manageFaction.font = UIFont.Medium
    self.manageFaction.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.manageFaction.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self:addChild(self.manageFaction)

    self.factionLocked = ISTickBox:new(10, self.manageFaction.y+self.manageFaction.height, 18, 18, "", self, nil)
    self.factionLocked.tooltip = getText("IGUI_FACTIONLOCKED_TOOLTIP")
    self.factionLocked:initialise()
    self.factionLocked:instantiate()
    self.factionLocked.selected[1] = true
    self.factionLocked:addOption(getText("IGUI_FACTIONLOCKED"))
    self:addChild(self.factionLocked)

    self.delete = ISButton:new(self.width-btnWid-pad, self:getHeight()-pad-btnHgt, btnWid, btnHgt, getText("IGUI_REMOVE"), self, bankWindow.onClick)
    self.delete.internal = "DELETE"
    self.delete.borderColor = {r=1, g=1, b=1, a=0.4}
    self.delete:initialise()
    self.delete:instantiate()
    self:addChild(self.delete)

    self.no = ISButton:new((self.width/2)-(btnWid/2), self:getHeight()-pad-btnHgt, btnWid, btnHgt, getText("UI_Cancel"), self, bankWindow.onClick)
    self.no.internal = "CANCEL"
    self.no.borderColor = {r=1, g=1, b=1, a=0.4}
    self.no:initialise()
    self.no:instantiate()
    self:addChild(self.no)
end


function bankWindow:update()
    if not self.player or not self.mapObject or (math.abs(self.player:getX()-self.mapObject:getX())>2) or (math.abs(self.player:getY()-self.mapObject:getY())>2) then
        self:setVisible(false)
        self:removeFromUIManager()
        return
    end
end


function bankWindow:validateElementColor(e)
    if not e then return end
    if e==self.addStockQuantity and self.categorySet.selected[1] == true then
        e.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.3 }
        e.textColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.3 }
        return
    end

    if e.enable then
        if not self.addStockEntry.enable then
            e.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.3 }
            e.textColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.3 }
        else
            e.borderColor = { r = 1, g = 1, b = 1, a = 0.8 }
            e.textColor = { r = 1, g = 1, b = 1, a = 0.8 }
        end
    else
        e.borderColor = { r = 1, g = 0, b = 0, a = 0.8 }
        e.textColor = { r = 1, g = 0, b = 0, a = 0.8 }
    end
end


function bankWindow:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)

end

function bankWindow:render()

    if self.mapObject and self.mapObject:getModData().factionBankID then self.bankAccount = CLIENT_BANK_ACCOUNTS[self.mapObject:getModData().factionBankID] end
    if self.bankAccount and self.mapObject and not self.mapObject:getModData().factionBankID then self.bankAccount = nil end

    local fontH = getTextManager():MeasureFont(self.font)

    local player = getPlayer()
    local playerFaction = Faction.getPlayerFaction(player)
    local isOwner = playerFaction and playerFaction:isOwner(player:getUsername())
    local managed = (isAdmin() or isCoopHost() or getDebug())
    local blocked = true

    if not managed then
        local bankName = getText("IGUI_BANK")
        if self.bankAccount then bankName = self.bankAccount.faction.." "..bankName end
        self:drawText(bankName, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, bankName)/2), 25, 1,1,1,1, UIFont.Medium)
    end

    if (playerFaction and self.bankAccount and self.bankAccount~=false) then
        if (not self.bankAccount.factionLocked) or (self.bankAccount.factionLocked and playerFaction==Faction.getFaction(self.bankAccount.faction)) then
            blocked = false
        end
    end

    self.factionLocked:setVisible((managed or isOwner))
    self.delete:setVisible((managed or isOwner))
    self.manageFaction:setVisible((managed or isOwner))

    local blockingMessage = getText("IGUI_BANKLOCKED")
    if not playerFaction then blockingMessage = getText("IGUI_NOFACTION") end

    if blocked then
        self.blocker:drawText(blockingMessage, self.width/2 - (getTextManager():MeasureStringX(UIFont.Small, blockingMessage) / 2), (self.height*0.66)-fontH, 1,1,1,1, UIFont.Small)
    else
        local balanceText = getText("IGUI_BALANCE")
        self:drawText(balanceText..":", self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, balanceText)/2), (self.height*0.66)-fontH, 1,1,1,1, UIFont.Medium)
    end

    self.blocker:setVisible(blocked)

    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self.no:bringToTop()
    self.delete:bringToTop()
    self.factionLocked:bringToTop()
    self.manageFaction:bringToTop()

    self.manageFaction.lastInput = self.manageFaction.lastInput or ""
    self.factionLocked.lastInput = self.factionLocked.lastInput or ""

    local currentMFInput = self.manageFaction:getInternalText()
    local currentFLInput = self.factionLocked.selected[1]
    local needUpdate = (self.manageFaction.lastInput ~= currentMFInput) or (self.factionLocked.lastInput ~= self.factionLocked.selected[1])

    if needUpdate then
        self.manageFaction.lastInput = currentMFInput
        local faction = Faction.getFaction(currentMFInput)

        if faction then
            self.manageFaction.textColor = { r = 1, g = 1, b = 1, a = 0.8 }
            self.manageFaction.borderColor = { r = 1, g = 1, b = 1, a = 0.8 }
            local x, y, z, mapObjName = self.mapObject:getX(), self.mapObject:getY(), self.mapObject:getZ(), _internal.getMapObjectName(self.mapObject)
            sendClientCommand("bank", "assignBank", { bankID=currentMFInput, factionLocked=currentFLInput, x=x, y=y, z=z, mapObjName=mapObjName })
        else
            self.manageFaction.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
            self.manageFaction.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
        end

    end
end


function bankWindow:onClick(button)

    local x, y, z, mapObjName = self.mapObject:getX(), self.mapObject:getY(), self.mapObject:getZ(), _internal.getMapObjectName(self.mapObject)

    if button.internal == "CONNECT_TO_STORE" or button.internal == "COPY_STORE" or button.internal == "DELETE_STORE_PRESET" then

        local currentAssignSelection = self.assignComboBox:getOptionData(self.assignComboBox.selected)

        if button.internal == "COPY_STORE" and self.assignComboBox.selected==1 then
            sendClientCommand("shop", "assignStore", { x=x, y=y, z=z, mapObjName=mapObjName })
        else
            if self.assignComboBox.selected~=1 then
                if button.internal == "COPY_STORE" then
                    sendClientCommand("shop", "copyStorePreset", { storeID=currentAssignSelection, x=x, y=y, z=z, mapObjName=mapObjName })

                elseif button.internal == "DELETE_STORE_PRESET" then
                    sendClientCommand("shop", "deleteStorePreset", { storeID=currentAssignSelection })

                elseif button.internal == "CONNECT_TO_STORE" then
                    sendClientCommand("shop", "connectStorePreset", { storeID=currentAssignSelection, x=x, y=y, z=z, mapObjName=mapObjName })

                end
            end

        end
    end


    if button.internal == "CANCEL" then
        self:setVisible(false)
        self:removeFromUIManager()
    end

    if button.internal == "DEPOSIT" then
    end

    if button.internal == "WITHDRAW" then
    end
end


function bankWindow:RestoreLayout(name, layout) ISLayoutManager.DefaultRestoreWindow(self, layout) end
function bankWindow:SaveLayout(name, layout) ISLayoutManager.DefaultSaveWindow(self, layout) end

function bankWindow:new(x, y, width, height, player, bankAccount, mapObj)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2)
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    player:StopAllActionQueue()
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.listHeaderColor = {r=0.4, g=0.4, b=0.4, a=0.3}
    o.width = width
    o.height = height
    o.player = player
    o.mapObject = mapObj
    o.bankAccount = bankAccount
    o.moveWithMouse = true
    bankWindow.instance = o
    return o
end


function bankWindow:onBrowse(bankAccount, mapObj)
    if bankWindow.instance and bankWindow.instance:isVisible() then
        bankWindow.instance:setVisible(false)
        bankWindow.instance:removeFromUIManager()
    end

    triggerEvent("BANKING_ClientModDataReady")

    local ui = bankWindow:new(50,50,250,175, getPlayer(), bankAccount, mapObj)
    ui:initialise()
    ui:addToUIManager()
end


