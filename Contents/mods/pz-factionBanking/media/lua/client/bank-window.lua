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

    self.selectFaction = ISComboBox:new(pad, pad, self.width-20, btnHgt-4)
    self.selectFaction.borderColor = { r = 1, g = 1, b = 1, a = 0.4 }
    self.selectFaction:initialise()
    self.selectFaction:instantiate()
    self:addChild(self.selectFaction)
    self:populateComboList()

    --[[
    self.manageFaction = ISTextEntryBox:new(bankName, pad, pad, self.width-20, btnHgt-4)
    self.manageFaction:initialise()
    self.manageFaction:instantiate()
    self.manageFaction.font = UIFont.Medium
    self.manageFaction.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.manageFaction.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self:addChild(self.manageFaction)
    --]]

    self.factionLocked = ISTickBox:new(10, self.selectFaction.y+self.selectFaction.height, 18, 18, "", self, nil)
    self.factionLocked.tooltip = getText("IGUI_FACTIONLOCKED_TOOLTIP")
    self.factionLocked:initialise()
    self.factionLocked:instantiate()
    self.factionLocked.selected[1] = true
    self.factionLocked:addOption(getText("IGUI_FACTIONLOCKED"))
    self:addChild(self.factionLocked)

    self.no = ISButton:new((self.width/2)-(btnWid/2), self:getHeight()-pad-btnHgt, btnWid, btnHgt, getText("UI_Cancel"), self, bankWindow.onClick)
    self.no.internal = "CANCEL"
    self.no.borderColor = {r=1, g=1, b=1, a=0.4}
    self.no:initialise()
    self.no:instantiate()
    self:addChild(self.no)
end

function bankWindow:populateComboList()
    self.selectFaction:clear()
    self.selectFaction:addOptionWithData("NONE", false)

    local factions = Faction.getFactions()
    if factions then
        for i=0,factions:size()-1 do
            ---@type Faction
            local faction = factions:get(i)
            local factionName = faction:getName()
            if faction then
                self.selectFaction:addOption(factionName)
                if self.mapObject then
                    local bankID = self.mapObject:getModData().factionBankID
                    if bankID and bankID==factionName then self.selectFaction:select(bankID) end
                end
            end
        end
    end

    self.selectFaction:addOptionWithData("REMOVE", false)
    if (not self.selectFaction.selected) or (self.selectFaction.selected > #self.selectFaction.options) then self.selectFaction.selected = 1 end
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

    local mapObjModData
    if self.mapObject then
        mapObjModData = self.mapObject:getModData()
        if mapObjModData and mapObjModData.factionBankID then self.bankAccount = CLIENT_BANK_ACCOUNTS[mapObjModData.factionBankID] end
        if self.bankAccount and not mapObjModData.factionBankID then self.bankAccount = nil end
    end

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
        if (not mapObjModData.factionLocked) or (mapObjModData.factionLocked and playerFaction==Faction.getFaction(self.bankAccount.faction)) then
            blocked = false
        end
    end

    self.factionLocked:setVisible((managed or isOwner))
    self.selectFaction:setVisible((managed or isOwner))

    local blockingMessage = getText("IGUI_BANKLOCKED")
    if not playerFaction then blockingMessage = getText("IGUI_NOFACTION") end

    if blocked then
        self.blocker:drawText(blockingMessage, self.width/2 - (getTextManager():MeasureStringX(UIFont.Small, blockingMessage) / 2), (self.height*0.66)-fontH, 1,1,1,1, UIFont.Small)
    else

        local balanceText = getText("IGUI_BALANCE")
        local balanceAmount = 0

        if self.bankAccount and self.bankAccount.amount then balanceAmount = self.bankAccount.amount end
        balanceText = balanceText..": ".._internal.numToCurrency(balanceAmount)
        self:drawText(balanceText, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, balanceText)/2), (self.height*0.66)-fontH, 1,1,1,1, UIFont.Medium)
    end

    self.blocker:setVisible(blocked)

    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self.no:bringToTop()
    self.factionLocked:bringToTop()
    self.selectFaction:bringToTop()

    self.selectFaction.lastSelected = self.selectFaction.lastSelected or -1
    self.factionLocked.lastInput = self.factionLocked.lastInput or ""

    local currentFactionSelected, currentFLInput = self.selectFaction.selected, self.factionLocked.selected[1]
    local needUpdate = (self.selectFaction.lastInput ~= currentFactionSelected) or (self.factionLocked.lastInput ~= self.factionLocked.selected[1])

    if needUpdate then
        if self.selectFaction.selected == #self.selectFaction.options then
            local x, y, z, mapObjName = self.mapObject:getX(), self.mapObject:getY(), self.mapObject:getZ(), _internal.getMapObjectName(self.mapObject)
            sendClientCommand("bank", "removeBank", { x=x, y=y, z=z, mapObjName=mapObjName })
            self:setVisible(false)
            self:removeFromUIManager()
        end

        self.selectFaction.lastSelected = currentFactionSelected
        self.factionLocked.lastInput = self.factionLocked.selected[1]

        local factionSelectedName = self.selectFaction:getSelectedText()
        local faction = Faction.getFaction(factionSelectedName)
        if faction then
            local x, y, z, mapObjName = self.mapObject:getX(), self.mapObject:getY(), self.mapObject:getZ(), _internal.getMapObjectName(self.mapObject)
            sendClientCommand("bank", "assignBank", { bankID=factionSelectedName, factionLocked=currentFLInput, x=x, y=y, z=z, mapObjName=mapObjName })
        end
    end
end


function bankWindow:onClick(button)

    local x, y, z, mapObjName = self.mapObject:getX(), self.mapObject:getY(), self.mapObject:getZ(), _internal.getMapObjectName(self.mapObject)

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


