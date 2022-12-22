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
    local padBottom = 10
    local x = (self.width / 2)-15
    local y = (self.height*0.6)

    local bankName = "Bank"
    if self.bankObj then bankName = self.bankObj.faction.." "..getText("IGUI_BANK") end

    self.manageFaction = ISTextEntryBox:new(bankName, 10, 10, self.width-20, btnHgt)
    self.manageFaction:initialise()
    self.manageFaction:instantiate()
    self.manageFaction.font = UIFont.Medium
    self.manageFaction.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self:addChild(self.manageFaction)

    self.factionLocked = ISTickBox:new(self.x+10, self.y+10, 18, 18, "", self, nil)
    self.factionLocked.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.factionLocked.tooltip = getText("IGUI_FACTIONLOCKED_TOOLTIP")
    self.factionLocked:initialise()
    self.factionLocked:instantiate()
    self.factionLocked.selected[1] = true
    self.factionLocked:addOption(getText("IGUI_FACTIONLOCKED"))
    self:addChild(self.factionLocked)

    self.blocker = ISPanel:new(0,0, self.width, self.height)
    self.blocker.moveWithMouse = true
    self.blocker:initialise()
    self.blocker:instantiate()
    self.blocker:drawRect(0, 0, self.blocker.width, self.blocker.height, 0.8, 0, 0, 0)
    self:addChild(self.blocker)
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
end

function bankWindow:render()

    if self.mapObject and self.mapObject:getModData().bankObjID then self.bankObj = CLIENT_BANK_ACCOUNTS[self.mapObject:getModData().bankObjID] end
    if self.bankObj and self.mapObject and not self.mapObject:getModData().bankObjID then self.bankObj = nil end

    local z = 15
    local fontH = getTextManager():MeasureFont(self.font)

    local player = getPlayer()
    local playerFaction = Faction.getPlayerFaction(player)
    local isOwner = playerFaction and playerFaction:isOwner(player:getUsername())
    local managed = (isAdmin() or isCoopHost() or getDebug())
    local blocked = true

    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)

    if not managed then
        local bankName = getText("IGUI_BANK")
        if self.bankObj then bankName = self.bankObj.faction.." "..bankName end
        self:drawText(bankName, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, bankName)/2), z, 1,1,1,1, UIFont.Medium)
    end

    if playerFaction and self.bankObj and (not self.bankObj.factionLocked) or (self.bankObj.factionLocked and playerFaction==Faction.getFaction(self.bankObj.faction)) then
        blocked = false
    end
    self.factionLocked:setVisible((managed or isOwner) and not blocked)
    self.manageFaction:setVisible((managed or isOwner) and not blocked)

    local blockingMessage = getText("IGUI_BANKLOCKED")
    if not playerFaction then blockingMessage = getText("IGUI_NOFACTION") end

    if blocked then
        self.blocker:drawText(blockingMessage, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, blockingMessage) / 2), (self.height / 3) - 5, 1,1,1,1, UIFont.Medium)
    else
        local balanceText = getText("IGUI_BALANCE")
        self:drawText(balanceText, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, balanceText)/2), z+fontH, 1,1,1,1, UIFont.Medium)
    end

    self.blocker:setVisible(blocked)

    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self.no:bringToTop()
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

function bankWindow:new(x, y, width, height, player, bankObj, mapObj)
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
    o.bankObj = bankObj
    o.moveWithMouse = true
    bankWindow.instance = o
    return o
end


function bankWindow:onBrowse(bankObj, mapObj)
    if bankWindow.instance and bankWindow.instance:isVisible() then
        bankWindow.instance:setVisible(false)
        bankWindow.instance:removeFromUIManager()
    end

    triggerEvent("BANKING_ClientModDataReady")

    local ui = bankWindow:new(50,50,555,555, getPlayer(), bankObj, mapObj)
    ui:initialise()
    ui:addToUIManager()
end


