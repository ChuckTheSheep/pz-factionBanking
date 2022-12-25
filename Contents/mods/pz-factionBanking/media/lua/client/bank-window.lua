require "ISUI/ISPanelJoypad"
require "bank-globalModDataClient"
require "luautils"

---@class bankWindow : ISPanel
bankWindow = ISPanelJoypad:derive("bankWindow")


function bankWindow:initialise()
    ISPanelJoypad.initialise(self)
    local btnWid = 100
    local btnHgt = 25
    local pad = 10

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

    local yOffset = self.selectFaction.y+self.selectFaction.height+15

    local buttonW = btnWid/1.7
    self.transferProceed = ISButton:new(self.width-buttonW-pad, yOffset, buttonW, btnHgt-4, getText("IGUI_CONFIRM"), self, bankWindow.onClick)
    self.transferProceed.internal = "CONFIRM"
    self.transferProceed.borderColor = {r=1, g=1, b=1, a=0.4}
    self.transferProceed:initialise()
    self.transferProceed:instantiate()
    self:addChild(self.transferProceed)

    yOffset = yOffset+self.transferProceed.height+pad
    self.transferTypeSwitch = ISButton:new(pad, yOffset, btnWid/3, btnHgt-4, getText("IGUI_WITHDRAW"), self, nil)
    self.transferTypeSwitch.borderColor = {r=1, g=1, b=1, a=0.4}
    self.transferTypeSwitch.current = "withdraw"
    self.transferTypeSwitch.displayBackground = false
    self.transferTypeSwitch:initialise()
    self.transferTypeSwitch:instantiate()
    self:addChild(self.transferTypeSwitch)

    self.transferEntry = ISTextEntryBox:new("", self.transferTypeSwitch.x+self.transferTypeSwitch.width-1, yOffset, self.width-(pad*2)-self.transferTypeSwitch.width, btnHgt-4)
    self.transferEntry.font = UIFont.Small
    self.transferEntry.onTextChange = bankWindow.transferEntryChange
    self.transferEntry:initialise()
    self.transferEntry:instantiate()
    self:addChild(self.transferEntry)

    self.withdrawSlider = ISSliderPanel:new(pad, self.transferProceed.y, self.width-self.transferProceed.width-(pad*3), btnHgt-4, self, nil)
    self.withdrawSlider:initialise()
    self.withdrawSlider:instantiate()
    self:addChild(self.withdrawSlider)

    self.no = ISButton:new((self.width/2)-(btnWid/2), self:getHeight()-pad-btnHgt, btnWid, btnHgt, getText("UI_Cancel"), self, bankWindow.onClick)
    self.no.internal = "CANCEL"
    self.no.borderColor = {r=1, g=1, b=1, a=0.4}
    self.no:initialise()
    self.no:instantiate()
    self:addChild(self.no)

    self.fresh = true
end


function bankWindow:transferEntryChange()
    local s = bankWindow.instance
    if not s then return end
    if s.withdrawSlider then
        local bankBalance = (s.currentAccount and s.currentAccount.amount) or 0
        local value = tonumber(s.transferEntry:getInternalText())
        if not value then return end
        if value<0 then s:setTransferTypeSwitch("withdraw") else s:setTransferTypeSwitch("deposit") end
        s.withdrawSlider:setCurrentValue(bankBalance+value)
    end
    triggerEvent("BANKING_ClientModDataReady")
end


function bankWindow:updateTransferTypeSwitch()
    if self.transferTypeSwitch.current == "deposit" then
        self.transferTypeSwitch:setTitle(getText("IGUI_DEPOSIT"))
    end
    if self.transferTypeSwitch.current == "withdraw" then
        self.transferTypeSwitch:setTitle(getText("IGUI_WITHDRAW"))
    end
    local value = tonumber(self.transferEntry:getInternalText())
    if value then self.transferEntry:setText(tostring(value)) end
end


function bankWindow:setTransferTypeSwitch(typeSetTo)
    self.transferTypeSwitch.current = typeSetTo
    self:updateTransferTypeSwitch()
end


function bankWindow:setTransferAmount(val)

    local walletBalance = getWalletBalance(self.player) or 0
    local bankBalance = (self.currentAccount and self.currentAccount.amount) or 0

    if self.withdrawSlider and not self.transferEntry:isFocused() then
        self.withdrawSlider:setValues( 0, walletBalance+bankBalance, 0.01, 0.5, true)
        if val then self.withdrawSlider:setCurrentValue(val) end
    end
    if self.transferEntry and not self.transferEntry:isFocused() then
        local exchange = self.withdrawSlider:getCurrentValue()
        local transferAmount = tostring(exchange-bankBalance)

        local formatted = string.format("%.2f", transferAmount)
        formatted = formatted:gsub("%.00", "")

        if exchange < bankBalance then
            self:setTransferTypeSwitch("withdraw")
        else
            self:setTransferTypeSwitch("deposit")
        end
        self.transferEntry:setText(formatted)
    end
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


function bankWindow:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
end

function bankWindow:forceUpdate()
    self.withdrawSlider.lastWalletBalance = -1
    self.withdrawSlider.lastBankBalance = -1
    self.selectFaction.lastSelected = 1
    triggerEvent("BANKING_ClientModDataReady")
end


function bankWindow:render()

    local fontH = getTextManager():MeasureFont(self.font)
    local playerFaction = Faction.getPlayerFaction(self.player)
    local managed = (isAdmin() or isCoopHost() or getDebug())
    local blocked = true

    local mapObjModData = (self.mapObject and self.mapObject:getModData())
    local bankingFactionID = mapObjModData.factionBankID
    self.currentAccount = CLIENT_BANK_ACCOUNTS[(bankingFactionID~=false and bankingFactionID) or playerFaction:getName()]

    --print("playerFactionID:"..tostring( (playerFaction and playerFaction:getName()) or nil) )
    --print("bankingFactionID:"..tostring(bankingFactionID))
    --print("currentAccountID:"..tostring((bankingFactionID~=false and bankingFactionID) or playerFaction:getName()))

    if not managed then
        local bankName = mapObjModData.factionBankID.." "..getText("IGUI_BANK")
        self:drawText(bankName, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, bankName)/2), self.selectFaction.y, 1,1,1,1, UIFont.Medium)
    end

    local blockingMessage = getText("IGUI_BANKLOCKED")

    if not playerFaction then
        blockingMessage = getText("IGUI_NOFACTION")
    else
        if bankingFactionID==false or playerFaction:getName()==bankingFactionID then
            blocked = false
        end
    end
    self.selectFaction:setVisible(managed)

    local currentWalletBalance, currentBankBalance = (getWalletBalance(self.player) or 0), (self.currentAccount and self.currentAccount.amount) or 0

    if blocked then
        self.blocker:drawText(blockingMessage, self.width/2-(getTextManager():MeasureStringX(UIFont.Small, blockingMessage)/2), (self.height*0.66)-fontH, 1,1,1,1, UIFont.Small)
    else
        local pad = 10
        local textY = self.no.y-(fontH*2)-(pad*2)

        local walletBalText = getText("IGUI_WALLETBALANCE")
        walletBalText = walletBalText..":\n".._internal.numToCurrency(currentWalletBalance)
        self:drawText(walletBalText, pad*1.5, textY, 1,1,1,0.7, UIFont.Small)

        local bankBalText = getText("IGUI_ACCOUNTBALANCE")
        bankBalText = bankBalText..":\n".._internal.numToCurrency(currentBankBalance)
        self:drawTextRight(bankBalText, self.width-(pad*1.5), textY, 1,1,1,1, UIFont.Small)
    end

    self.blocker:setVisible(blocked)

    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self.no:bringToTop()
    self.selectFaction:bringToTop()

    self.withdrawSlider.lastWalletBalance = self.withdrawSlider.lastWalletBalance or -1
    self.withdrawSlider.lastBankBalance = self.withdrawSlider.lastBankBalance or -1

    if self and self.withdrawSlider and (currentWalletBalance~=self.withdrawSlider.lastWalletBalance or currentBankBalance~=self.withdrawSlider.lastBankBalance) then
        self.withdrawSlider.lastWalletBalance = currentWalletBalance
        self.withdrawSlider.lastBankBalance = currentBankBalance
    end

    self:setTransferAmount((self.fresh and currentBankBalance) or nil)
    self.fresh = nil

    local value = tonumber(self.transferEntry:getInternalText())
    if not value or (value<0 and math.abs(value)>currentBankBalance) or (value>currentWalletBalance) then
        self.transferEntry.borderColor = {r=1, g=0, b=0, a=0.6}
    else
        self.transferEntry.borderColor = {r=1, g=1, b=1, a=0.4}
    end

    self.selectFaction.lastSelected = self.selectFaction.lastSelected or 1
    local currentFactionSelected = self.selectFaction.selected
    if self.selectFaction.selected~=1 and self.selectFaction.lastInput ~= currentFactionSelected then
        if self.selectFaction.selected == #self.selectFaction.options then
            local x, y, z, mapObjName = self.mapObject:getX(), self.mapObject:getY(), self.mapObject:getZ(), _internal.getMapObjectName(self.mapObject)
            sendClientCommand("bank", "removeBank", { x=x, y=y, z=z, mapObjName=mapObjName })
            self:setVisible(false)
            self:removeFromUIManager()
        end

        self.selectFaction.lastSelected = currentFactionSelected

        local factionSelectedName = self.selectFaction:getSelectedText()
        local faction = Faction.getFaction(factionSelectedName)
        if faction then
            local x, y, z, mapObjName = self.mapObject:getX(), self.mapObject:getY(), self.mapObject:getZ(), _internal.getMapObjectName(self.mapObject)
            sendClientCommand("bank", "assignBank", { bankID=factionSelectedName, x=x, y=y, z=z, mapObjName=mapObjName })
        end
    end
end


function bankWindow:onClick(button)

    local x, y, z, mapObjName = self.mapObject:getX(), self.mapObject:getY(), self.mapObject:getZ(), _internal.getMapObjectName(self.mapObject)

    if button.internal == "CANCEL" then
        self:setVisible(false)
        self:removeFromUIManager()
    end

    if button.internal == "CONFIRM" then
        local value = self.withdrawSlider:getCurrentValue()
        if value then

            --if not SandboxVars.ShopsAndTraders.PlayerWallets then return end
            local playerModData = self.player:getModData()
            if not playerModData then print("WARN: Player without modData.") return end
            local walletID = playerModData.wallet_UUID
            if not walletID then print("- No Player wallet_UUID.") return end

            local currentBankBalance = (self.currentAccount and self.currentAccount.amount) or 0
            local pUsername = self.player:getUsername()

            local faction = Faction.getPlayerFaction(self.player)
            if not faction then print("ERROR: No player faction for: "..pUsername)  return end

            if value > currentBankBalance then --deposit
                value = _internal.floorCurrency(value-currentBankBalance)
                print("deposit value:"..value)
                sendClientCommand("bank", "transferFunds", {playerID=walletID, playerUsername=pUsername, transferValue=value, factionID=faction:getName()})
            elseif value < currentBankBalance then --withdraw
                value = _internal.floorCurrency(currentBankBalance-value)
                print("withdraw value:"..value)
                sendClientCommand("bank", "transferFunds", {playerID=walletID, playerUsername=pUsername, transferValue=0-value, factionID=faction:getName()})
            end
        end
    end
end


function bankWindow:RestoreLayout(name, layout) ISLayoutManager.DefaultRestoreWindow(self, layout) end
function bankWindow:SaveLayout(name, layout) ISLayoutManager.DefaultSaveWindow(self, layout) end

function bankWindow:new(x, y, width, height, player, factionID, mapObj)
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
    o.factionID = factionID
    o.moveWithMouse = true
    bankWindow.instance = o
    return o
end


function bankWindow:onBrowse(factionID, mapObj)
    if bankWindow.instance and bankWindow.instance:isVisible() then
        bankWindow.instance:setVisible(false)
        bankWindow.instance:removeFromUIManager()
    end

    triggerEvent("BANKING_ClientModDataReady")

    local ui = bankWindow:new(50,50,250,200, getPlayer(), factionID, mapObj)
    ui:initialise()
    ui:addToUIManager()
end


