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
    local listWidh = (self.width / 2)-15
    local listHeight = (self.height*0.6)

    local storeName = "new store"
    if self.bankObj then storeName = self.bankObj.name end

    self.manageStoreName = ISTextEntryBox:new(storeName, 10, 10, self.width-20, btnHgt)
    self.manageStoreName:initialise()
    self.manageStoreName:instantiate()
    self.manageStoreName.font = UIFont.Medium
    self.manageStoreName.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self:addChild(self.manageStoreName)

    self.yourCartData = ISScrollingListBox:new(10, 80, listWidh, listHeight)
    self.yourCartData:initialise()
    self.yourCartData:instantiate()
    self.yourCartData:setOnMouseDownFunction(self, self.onCartItemSelected)
    self.yourCartData.itemheight = 30
    self.yourCartData.selected = 0
    self.yourCartData.joypadParent = self
    self.yourCartData.font = UIFont.NewSmall
    self.yourCartData.doDrawItem = self.drawCart
    self.yourCartData.onMouseUp = self.yourOfferMouseUp
    self.yourCartData.drawBorder = true
    self:addChild(self.yourCartData)

    self.storeStockData = ISScrollingListBox:new(self.width-listWidh-10, self.yourCartData.y, listWidh, listHeight)
    self.storeStockData:initialise()
    self.storeStockData:instantiate()
    self.storeStockData:setOnMouseDownFunction(self, self.onStoreItemSelected)
    self.storeStockData.itemheight = 30
    self.storeStockData.selected = 0
    self.storeStockData.joypadParent = self
    self.storeStockData.font = UIFont.NewSmall
    self.storeStockData.doDrawItem = self.drawStock
    self.storeStockData.drawBorder = true
    self:addChild(self.storeStockData)

    self:displayStoreStock()

    local manageStockButtonsX = (self.storeStockData.x+self.storeStockData.width)
    local manageStockButtonsY = self.storeStockData.y+self.storeStockData.height
    self.addStockBtn = ISButton:new(manageStockButtonsX-22, manageStockButtonsY+5, btnHgt-3, btnHgt-3, "+", self, storeWindow.onClick)
    self.addStockBtn.internal = "ADDSTOCK"
    self.addStockBtn:initialise()
    self.addStockBtn:instantiate()
    self:addChild(self.addStockBtn)

    self.addStockEntry = ISTextEntryBox:new("", self.storeStockData.x, self.addStockBtn.y, self.storeStockData.width-self.addStockBtn.width-3, self.addStockBtn.height)
    self.addStockEntry.font = UIFont.Medium
    self.addStockEntry:initialise()
    self.addStockEntry:instantiate()
    self.addStockEntry.onTextChange = storeWindow.addItemEntryChange
    self:addChild(self.addStockEntry)

    self.addStockPrice = ISTextEntryBox:new("0", self.addStockEntry.x+10, self.addStockEntry.y+self.addStockEntry.height+3, 30, self.addStockBtn.height)
    self.addStockPrice.font = UIFont.Small
    self.addStockPrice.tooltip = getText("IGUI_CURRENCY_TOOLTIP")
    self.addStockPrice:initialise()
    self.addStockPrice:instantiate()
    self:addChild(self.addStockPrice)

    self.addStockQuantity = ISTextEntryBox:new("0", self.addStockPrice.x+self.addStockPrice.width+20, self.addStockPrice.y, 30, self.addStockBtn.height)
    self.addStockQuantity.font = UIFont.Small
    self.addStockQuantity.tooltip = getText("IGUI_STOCK_TOOLTIP")
    self.addStockQuantity:initialise()
    self.addStockQuantity:instantiate()
    self:addChild(self.addStockQuantity)

    self.addStockBuyBackRate = ISTextEntryBox:new("0", self.addStockQuantity.x+self.addStockQuantity.width+20, self.addStockQuantity.y, 30, self.addStockBtn.height)
    self.addStockBuyBackRate.font = UIFont.Small
    self.addStockBuyBackRate.tooltip = getText("IGUI_RATE_TOOLTIP")
    self.addStockBuyBackRate:initialise()
    self.addStockBuyBackRate:instantiate()
    self:addChild(self.addStockBuyBackRate)

    self.categorySet = ISTickBox:new(self.addStockBuyBackRate.x+self.addStockBuyBackRate.width+10, self.addStockBuyBackRate.y, 18, 18, "", self, nil)
    self.categorySet.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.categorySet.tooltip = getText("IGUI_STOCKCATEGORY_TOOLTIP")
    self.categorySet:initialise()
    self.categorySet:instantiate()
    self.categorySet.selected[1] = false
    self.categorySet:addOption(getText("IGUI_STOCKCATEGORY"))
    self:addChild(self.categorySet)

    self.resell = ISTickBox:new(self.addStockBuyBackRate.x+self.addStockBuyBackRate.width+10, self.categorySet.y+self.categorySet.height+2, 18, 18, "", self, nil)
    self.resell.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.resell.tooltip = getText("IGUI_IGUI_RESELL_TOOLTIP")
    self.resell:initialise()
    self.resell:instantiate()
    self.resell.selected[1] = SandboxVars.ShopsAndTraders.TradersResellItems
    self.resell:addOption(getText("IGUI_RESELL"))
    self:addChild(self.resell)

    self.alwaysShow = ISTickBox:new(self.addStockBuyBackRate.x+self.addStockBuyBackRate.width+10, self.resell.y+self.resell.height+2, 18, 18, "", self, nil)
    self.alwaysShow.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.alwaysShow.tooltip = getText("IGUI_ALWAYSSHOW_TOOLTIP")
    self.alwaysShow:initialise()
    self.alwaysShow:instantiate()
    self.alwaysShow.selected[1] = false
    self.alwaysShow:addOption(getText("IGUI_ALWAYSSHOW"))
    self:addChild(self.alwaysShow)

    self.purchase = ISButton:new(self.storeStockData.x + self.storeStockData.width - (math.max(btnWid, getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_PURCHASE")) + 10)), self:getHeight() - padBottom - btnHgt, btnWid, btnHgt - 3, getText("IGUI_PURCHASE"), self, storeWindow.onClick)
    self.purchase.internal = "PURCHASE"
    self.purchase.borderColor = {r=1, g=1, b=1, a=0.4}
    self.purchase:initialise()
    self.purchase:instantiate()
    self:addChild(self.purchase)

    self.manageBtn = ISButton:new((self.width/2)-45, 70-btnHgt, 70, 25, getText("IGUI_MANAGESTORE"), self, storeWindow.onClick)
    self.manageBtn.internal = "MANAGE"
    self.manageBtn:initialise()
    self.manageBtn:instantiate()
    self:addChild(self.manageBtn)

    local restockHours = ""
    if self.bankObj then restockHours = tostring(self.bankObj.restockHrs) end
    self.restockHours = ISTextEntryBox:new(restockHours, self.width-60, 70-btnHgt, 50, self.addStockBtn.height)
    self.restockHours.font = UIFont.Medium
    self.restockHours.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.restockHours:initialise()
    self.restockHours:instantiate()
    self:addChild(self.restockHours)

    self.clearStore = ISButton:new(self.manageBtn.x+self.manageBtn.width+4, self.manageBtn.y+6, 10, 14, "X", self, storeWindow.onClick)
    self.clearStore.internal = "CLEAR_STORE"
    self.clearStore.font = UIFont.NewSmall
    self.clearStore.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.clearStore.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.clearStore.tooltip = getText("IGUI_DISCONNECT_STORE")
    self.clearStore:initialise()
    self.clearStore:instantiate()
    self:addChild(self.clearStore)


    self.blocker = ISPanel:new(0,0, self.width, self.height)
    self.blocker.moveWithMouse = true
    self.blocker:initialise()
    self.blocker:instantiate()
    self.blocker:drawRect(0, 0, self.blocker.width, self.blocker.height, 0.8, 0, 0, 0)
    local blockingMessage = getText("IGUI_STOREBEINGMANAGED")
    self.blocker:drawText(blockingMessage, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, blockingMessage) / 2), (self.height / 3) - 5, 1,1,1,1, UIFont.Medium)
    self:addChild(self.blocker)

    self.no = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, getText("UI_Cancel"), self, storeWindow.onClick)
    self.no.internal = "CANCEL"
    self.no.borderColor = {r=1, g=1, b=1, a=0.4}
    self.no:initialise()
    self.no:instantiate()
    self:addChild(self.no)

    local acbWidth = (self.width/2)+64
    local btnBuffer = 2
    local buttonW = (acbWidth/2)-btnBuffer
    local delBtnW = (buttonW/3)

    self.assignComboBox = ISComboBox:new((self.width/2)-(acbWidth/2)+(delBtnW/4)+2, (self.height/2)-1, acbWidth, 22)
    self.assignComboBox.borderColor = { r = 1, g = 1, b = 1, a = 0.4 }
    self.assignComboBox:initialise()
    self.assignComboBox:instantiate()
    self:addChild(self.assignComboBox)
    self:populateComboList()

    local acb = self.assignComboBox

    self.aBtnDel = ISButton:new(acb.x-delBtnW-2, acb.y, delBtnW, acb.height, getText("IGUI_DELETEPRESET"), self, storeWindow.onClick)
    self.aBtnDel.internal = "DELETE_STORE_PRESET"
    self.aBtnDel.font = UIFont.NewSmall
    self.aBtnDel.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.aBtnDel.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
    self.aBtnDel:initialise()
    self.aBtnDel:instantiate()
    self:addChild(self.aBtnDel)

    self.aBtnConnect = ISButton:new(acb.x, acb.y-29, buttonW, 25, getText("IGUI_CONNECTPRESET"), self, storeWindow.onClick)
    self.aBtnConnect.internal = "CONNECT_TO_STORE"
    self.aBtnConnect:initialise()
    self.aBtnConnect:instantiate()
    self:addChild(self.aBtnConnect)

    self.aBtnCopy = ISButton:new(self.aBtnConnect.x+buttonW+(btnBuffer*2), acb.y-29, buttonW, 25, getText("IGUI_COPYPRESET"), self, storeWindow.onClick)
    self.aBtnCopy.internal = "COPY_STORE"
    self.aBtnCopy:initialise()
    self.aBtnCopy:instantiate()
    self:addChild(self.aBtnCopy)


    self.importBtn = ISButton:new(self.aBtnDel.x, acb.y-29, self.aBtnDel.width, 25, getText("IGUI_IMPORT"), self, storeWindow.onClick)
    self.importBtn.internal = "IMPORT_EXPORT_STORES"
    self.importBtn.borderColor = { r = 1, g = 1, b = 1, a = 0.7 }
    self.importBtn.textColor = { r = 1, g = 1, b = 1, a = 0.7 }
    self.importBtn.toggled = false
    self.importBtn:initialise()
    self.importBtn:instantiate()
    self:addChild(self.importBtn)

    self.importCancel = ISButton:new(self.aBtnDel.x, self.aBtnDel.y, self.aBtnDel.width, 25, getText("UI_Cancel"), self, storeWindow.onClick)
    self.importCancel.font = UIFont.NewSmall
    self.importCancel.internal = "IMPORT_EXPORT_CANCEL"
    self.importCancel.borderColor = { r = 1, g = 1, b = 1, a = 0.7 }
    self.importCancel.textColor = { r = 1, g = 1, b = 1, a = 0.7 }
    self.importCancel:initialise()
    self.importCancel:instantiate()
    self:addChild(self.importCancel)

    local iTMargin = 4
    local importTextX = self.importBtn.x+self.importBtn.width+iTMargin
    self.importText = ISTextEntryBox:new("", importTextX, iTMargin, self:getWidth() - importTextX-iTMargin, self:getHeight()-(iTMargin*2))
    self.importText.backgroundColor = {r=0, g=0, b=0, a=0.8}
    self.importText:initialise()
    self.importText:instantiate()
    self.importText:setMultipleLine(true)
    self.importText.javaObject:setMaxLines(15)
    --self.entry.javaObject:setMaxTextLength(self.maxTextLength)
    self:addChild(self.importText)

end


function bankWindow:isBeingManaged()
    if self.bankObj and self.bankObj.isBeingManaged then return true end
    return false
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



function bankWindow:displayOrderTotal()
    local x = self.yourCartData.x
    local y = self.yourCartData.y+self.yourCartData.height
    local w = self.yourCartData.width
    local fontH = getTextManager():MeasureFont(self.font)
    local h = fontH+(fontH/2)

    local balanceColor = { normal = {r=1, g=1, b=1, a=0.9}, red = {r=1, g=0.2, b=0.2, a=0.9}, green = {r=0.2, g=1, b=0.2, a=0.9} }
    self:drawRect(x, y+4, w, h, 0.9, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)

    local totalLine = getText("IGUI_TOTAL")..": "
    self:drawText(totalLine, x+10, y+(fontH/2), balanceColor.normal.r, balanceColor.normal.g, balanceColor.normal.b, balanceColor.normal.a, self.font)

    local totalForTransaction = self:getOrderTotal()
    local textForTotal = _internal.numToCurrency(math.abs(totalForTransaction))
    local tColor = balanceColor.normal
    if totalForTransaction < 0 then tColor, textForTotal = balanceColor.green, "+"..textForTotal
    elseif totalForTransaction > 0 then tColor, textForTotal = balanceColor.red, "-"..textForTotal
    else textForTotal = " "..textForTotal end
    local xOffset = getTextManager():MeasureStringX(self.font, textForTotal)+15
    self:drawText(textForTotal, w-xOffset+5, y+(fontH/2), tColor.r, tColor.g, tColor.b, tColor.a, self.font)
    self:drawRectBorder(x, y+4, w, h, 0.9, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    if SandboxVars.ShopsAndTraders.PlayerWallets then
        self:drawRect(x, y+h+8, w, h, 0.9, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
        local walletBalance = getWalletBalance(self.player)
        local walletBalanceLine = getText("IGUI_WALLETBALANCE")..": ".._internal.numToCurrency(walletBalance)
        local bColor = balanceColor.normal
        if (walletBalance-totalForTransaction) < 0 then bColor = balanceColor.red end
        self:drawText(walletBalanceLine, x+10, y+h+4+(fontH/2), bColor.r, bColor.g, bColor.b, bColor.a, self.font)

        local walletBalanceAfter = walletBalance-totalForTransaction
        local sign = " "
        if walletBalanceAfter < 0 then sign = "-" end
        local wbaText = sign.._internal.numToCurrency(math.abs(walletBalanceAfter))
        local xOffset2 = getTextManager():MeasureStringX(self.font, wbaText)+15
        self:drawText(wbaText, w-xOffset2+5, y+h+4+(fontH/2), 0.7, 0.7, 0.7, 0.7, self.font)
        self:drawRectBorder(x, y+h+8, w, h, 0.9, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    end
end


function bankWindow:prerender()
    local z = 15
    local splitPoint = 100
    local x = 10
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)


    if not self:isBeingManaged() then
        local bankName = getText("IGUI_BANK")
        if self.bankObj then bankName = self.bankObj.name..bankName end
        self:drawText(bankName, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, bankName)/2), z, 1,1,1,1, UIFont.Medium)

        if self.bankObj then
            local restockingIn = tostring(self.bankObj.nextRestock)
            if restockingIn then self:drawTextRight(getText("IGUI_RESTOCK_HR", restockingIn), self.width-10, 10, 0.9,0.9,0.9,0.8, UIFont.NewSmall) end
        end

    else
        local cat = "category:"
        local catX = getTextManager():MeasureStringX(UIFont.Small, cat)+4

        if self.categorySet.selected[1] == true then
            local addStockEntryColor = self.addStockEntry.textColor
            self.addStockEntry:setX(self.storeStockData.x+catX)
            self.addStockEntry:setWidth(self.storeStockData.width-self.addStockBtn.width-3-catX)
            self:drawText(cat, self.storeStockData.x+1, self.addStockEntry.y-1, addStockEntryColor.r,addStockEntryColor.g,addStockEntryColor.b,addStockEntryColor.a, UIFont.Small)
        else
            self.addStockEntry:setX(self.storeStockData.x)
            self.addStockEntry:setWidth(self.storeStockData.width-self.addStockBtn.width-3)
        end

        self:validateElementColor(self.addStockPrice)
        local color = self.addStockPrice.textColor
        self:drawText(getText("IGUI_CURRENCY_PREFIX"), self.addStockPrice.x-12, self.addStockPrice.y, color.r,color.g,color.b,color.a, UIFont.Small)
        self:drawText(" "..getText("IGUI_CURRENCY_SUFFIX"), self.addStockPrice.x+self.addStockPrice.width+12, self.addStockPrice.y, color.r,color.g,color.b,color.a, UIFont.Small)

        self:validateElementColor(self.addStockQuantity)
        color = self.addStockQuantity.textColor
        self:drawText(getText("IGUI_STOCK"), self.addStockQuantity.x-12, self.addStockQuantity.y, color.r,color.g,color.b,color.a, UIFont.Small)

        self:validateElementColor(self.addStockBuyBackRate)
        color = self.addStockBuyBackRate.textColor
        self:drawText(getText("IGUI_RATE"), self.addStockBuyBackRate.x-14, self.addStockBuyBackRate.y, color.r,color.g,color.b,color.a, UIFont.Small)
    end


    self:drawText(getText("IGUI_YOURCART"), self.yourCartData.x+10, self.yourCartData.y - 32, 1,1,1,1, UIFont.Small)

    local yourItems = getText("IGUI_TradingUI_Items", #self.yourCartData.items, storeWindow.MaxItems)
    self:drawText(yourItems, self.yourCartData.x+10, self.yourCartData.y - 20, 1,1,1,1, UIFont.Small)

    local stockTextX = (self.storeStockData.x+(self.storeStockData.width/2))-(getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_STORESTOCK"))/2)
    self:drawText(getText("IGUI_STORESTOCK"), stockTextX, self.storeStockData.y - 26, 1,1,1,1, UIFont.Small)

    z = z + 30
end


function bankWindow:updateButtons()

    self.purchase.enable = false
    self.manageBtn.enable = false
    self.clearStore.enable = false
    self.addStockBtn.enable = false
    self.categorySet.enable = false
    self.alwaysShow.enable = false
    self.resell.enable = false

    self.importText.enable = false
    self.importCancel.enable = false

    self.assignComboBox.enable = false
    self.aBtnCopy.enable = false
    self.aBtnConnect.enable = false
    self.aBtnConnect.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.7 }
    self.importBtn.enable = false
    self.importBtn.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.7 }
    self.aBtnDel.enable = false
    self.aBtnDel.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.7 }

    if not self.bankObj then
        if self.importBtn.toggled==true then
            self.importText.enabled = true
            self.importCancel.enable = true
        end
        self.assignComboBox.enable = true
        self.aBtnCopy.enable = true
        self.importBtn.enable = true
        self.importBtn.borderColor = { r = 1, g = 1, b = 1, a = 0.7 }
        if self.assignComboBox.selected~=1 then
            self.aBtnConnect.enable = true
            self.aBtnConnect.borderColor = { r = 1, g = 1, b = 1, a = 0.7 }
            self.aBtnDel.enable = true
            self.aBtnDel.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
        end
        return
    end

    if (isAdmin() or isCoopHost() or getDebug()) then
        self.manageBtn.enable = true
        if self:isBeingManaged() then
            self.clearStore.enable = true
            self.addStockBtn.enable = true
            self.categorySet.enable = true
            self.alwaysShow.enable = true
            self.resell.enable = true
        end
    end
end


function storeWindow:validateAddStockEntry()
    local entryText = self.addStockEntry:getInternalText()
    if not entryText or entryText=="" then return false end
    local itemDict = getItemDictionary()
    if self.categorySet.selected[1] == true then if itemDict.categories[entryText] then return true end
    else if getScriptManager():getItem(entryText) then return true end
    end
    return false
end


function storeWindow:render()

    if self.mapObject and self.mapObject:getModData().bankObjID then self.bankObj = CLIENT_STORES[self.mapObject:getModData().bankObjID] end
    if self.bankObj and self.mapObject and not self.mapObject:getModData().bankObjID then self.bankObj = nil end

    self:updateButtons()
    self:updateTooltip()

    self:displayStoreStock()

    local managed = false
    if self:isBeingManaged() then
        managed = true
        self.manageBtn.textColor = { r = 1, g = 0, b = 0, a = 0.7 }
        self.manageBtn.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
        self.storeStockData.borderColor = { r = 1, g = 0, b = 0, a = 0.7 }
    else
        self.manageBtn.textColor = { r = 1, g = 1, b = 1, a = 0.4 }
        self.manageBtn.borderColor = { r = 1, g = 1, b = 1, a = 0.4 }
        self.storeStockData.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9}
    end

    local blocked = false
    if not (isAdmin() or isCoopHost() or getDebug()) then
        self.manageBtn:setVisible(false)
        if managed then blocked = true end
    end
    if not (self.bankObj) then
        self:populateComboList()
        blocked = true
    end

    local shouldSeeStorePresetOptions = (not self.bankObj) and (isAdmin() or isCoopHost() or getDebug())
    self.assignComboBox:setVisible(shouldSeeStorePresetOptions)
    self.aBtnConnect:setVisible(shouldSeeStorePresetOptions)
    self.aBtnDel:setVisible(shouldSeeStorePresetOptions)
    self.importBtn:setVisible(shouldSeeStorePresetOptions)
    self.aBtnCopy:setVisible(shouldSeeStorePresetOptions)

    self.importText:setVisible(shouldSeeStorePresetOptions and self.importBtn.toggled)
    self.importCancel:setVisible(shouldSeeStorePresetOptions and self.importBtn.toggled)

    if not (shouldSeeStorePresetOptions and self.importBtn.toggled) then self:displayOrderTotal() end

    self.addStockBtn:setVisible(managed and not blocked)
    self.manageStoreName:setVisible(managed and not blocked)
    self.addStockEntry:setVisible(managed and not blocked)
    self.addStockPrice:setVisible(managed and not blocked)
    self.addStockQuantity:setVisible(managed and not blocked)
    self.addStockBuyBackRate:setVisible(managed and not blocked)
    self.clearStore:setVisible(managed and not blocked)
    self.restockHours:setVisible(managed and not blocked)
    self.categorySet:setVisible(managed and not blocked)
    self.alwaysShow:setVisible(managed and not blocked)
    self.resell:setVisible(managed and not blocked)

    self.manageStoreName:isEditable(not blocked)
    self.addStockEntry:isEditable(not blocked)
    self.addStockPrice:isEditable(not blocked)
    self.addStockQuantity:isEditable(not blocked and (self.categorySet.selected[1] == false))
    self.addStockBuyBackRate:isEditable(not blocked)

    self.importText:isEditable(shouldSeeStorePresetOptions and self.importBtn.toggled)

    local purchaseValid = (getWalletBalance(self.player)-self:getOrderTotal()) >= 0
    self.purchase.enable = (not managed and not blocked and #self.yourCartData.items>0 and purchaseValid)
    local gb = 1
    if not purchaseValid then gb = 0 end
    self.purchase.textColor = { r = 1, g = gb, b = gb, a = 0.7 }
    self.purchase.borderColor = { r = 1, g = gb, b = gb, a = 0.7 }

    if self.addStockBtn:isVisible() then

        local elements = {self.addStockBtn, self.addStockEntry, self.addStockPrice, self.addStockQuantity, self.addStockBuyBackRate}

        self.addStockEntry.enable = self:validateAddStockEntry()

        self.addStockPrice.enable = (self.addStockPrice:getInternalText()=="" or tonumber(self.addStockPrice:getInternalText()))
        self.addStockQuantity.enable = (self.addStockQuantity:getInternalText()=="" or tonumber(self.addStockQuantity:getInternalText()))

        if self.categorySet.selected[1] == true then self.addStockQuantity:setText("") end

        local convertedBuyBackRate = tonumber(self.addStockBuyBackRate:getInternalText())
        self.addStockBuyBackRate.enable = (self.addStockBuyBackRate:getInternalText()=="" or (convertedBuyBackRate and (convertedBuyBackRate < 100 or convertedBuyBackRate > 0)))
        self.addStockBtn.enable = (self.addStockEntry.enable and self.addStockPrice.enable and (self.addStockQuantity.enable or self.categorySet.selected[1] == true) and self.addStockBuyBackRate.enable)

        for _,e in pairs(elements) do self:validateElementColor(e) end
    end

    self.blocker:setVisible(blocked)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self.no:bringToTop()
    self.assignComboBox:bringToTop()
    self.aBtnConnect:bringToTop()
    self.aBtnDel:bringToTop()
    self.aBtnCopy:bringToTop()

    self.importBtn:bringToTop()
    self.importCancel:bringToTop()
    self.importText:bringToTop()
end


function storeWindow:onClick(button)

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

    if button.internal == "CLEAR_STORE" and self.bankObj and self:isBeingManaged() then
        sendClientCommand("shop", "clearStoreFromMapObj", { storeID=self.bankObj.ID, x=x, y=y, z=z, mapObjName=mapObjName })
    end

    if button.internal == "MANAGE" then
        local newName
        local restockHrs
        local store = self.bankObj
        if store then
            if self:isBeingManaged() then
                store.isBeingManaged = false
                newName = self.manageStoreName:getInternalText()
                restockHrs = tonumber(self.restockHours:getInternalText())
                self.bankObj.name = newName
            else
                self.manageStoreName:setText(store.name)
                store.isBeingManaged = true
            end
            sendClientCommand("shop", "setStoreIsBeingManaged", {isBeingManaged=store.isBeingManaged, storeID=store.ID, storeName=newName, restockHrs=restockHrs})
        end
    end

    if button.internal == "ADDSTOCK" then
        local store = self.bankObj
        if not store then return end
        if not self:isBeingManaged() then return end
        if not self.addStockBtn.enable then return end

        if not self:validateAddStockEntry() then return end

        local newEntry = self.addStockEntry:getInternalText()
        if not newEntry then return end

        if self.categorySet.selected[1] == true then
            newEntry = "category:"..newEntry
        else
            local script = getScriptManager():getItem(newEntry)
            if script then newEntry = script:getFullName() end
        end

        local price = 0
        if self.addStockPrice.enable and self.addStockPrice:getInternalText() then price = tonumber(self.addStockPrice:getInternalText()) end

        local quantity = 0
        if self.addStockQuantity.enable and self.addStockQuantity:getInternalText() then quantity = tonumber(self.addStockQuantity:getInternalText()) end

        local buybackRate = 0
        if self.addStockBuyBackRate.enable and self.addStockBuyBackRate:getInternalText() then buybackRate = tonumber(self.addStockBuyBackRate:getInternalText()) end

        local reselling = self.resell.selected[1]

        sendClientCommand("shop", "listNewItem", { isBeingManaged=store.isBeingManaged, alwaysShow = (self.alwaysShow.selected[1] or false),
        item=newEntry, price=price, quantity=quantity, buybackRate=buybackRate, reselling=reselling, storeID=store.ID, x=x, y=y, z=z, mapObjName=mapObjName })
    end

    if button.internal == "CANCEL" then
        self:setVisible(false)
        self:removeFromUIManager()
    end

    if button.internal == "PURCHASE" then self:finalizeDeal() end


    if button.internal == "IMPORT_EXPORT_CANCEL" then
        self.importBtn:setTitle(getText("IGUI_IMPORT"))
        self.importBtn.toggled = false
    end

    if button.internal == "EXPORT_CLIPBOARD" then
        Clipboard.setClipboard(_internal.tableToString(CLIENT_STORES))
    end

    if button.internal == "IMPORT_EXPORT_STORES" then

        if self.importBtn.toggled then
            self.importBtn.toggled = false
            self.importBtn:setTitle(getText("IGUI_IMPORT"))
            local tbl = _internal.stringToTable(self.importText:getText())

            if (not tbl) or (type(tbl)~="table") then
                print("ERROR: STORES MASS EXPORT FAILED.")
                return
            end

            sendClientCommand("shop", "ImportStores", {stores=tbl})
            --if getDebug() then print("FINAL:\n".._internal.tableToString(tbl)) end

        else

            self.importText:setText(_internal.tableToString(CLIENT_STORES))
            self.importBtn:setTitle(getText("IGUI_EXPORT"))
            self.importBtn.toggled = true
        end

    end
end


function storeWindow:finalizeDeal()
    if not self.bankObj then return end
    local itemToPurchase = {}
    local itemsToSell = {}

    for i,v in ipairs(self.yourCartData.items) do
        if type(v.item) == "string" then
            table.insert(itemToPurchase, v.item)
        else
            local itemType, _, _ = self:rtrnTypeIfValid(v.item)
            if itemType then
                if isMoneyType(itemType) then
                    local value = v.item:getModData().value
                    local pID = self.player:getModData().wallet_UUID
                    sendClientCommand("shop", "transferFunds", {giver=nil, give=value, receiver=pID, receive=nil})
                else
                    table.insert(itemsToSell, itemType)
                end
                ---@type IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
                self.player:getInventory():Remove(v.item)
            end
        end
    end

    local walletID = getOrSetWalletID(self.player)
    if not walletID then print("ERROR: finalizeDeal: No Wallet ID for "..self.player:getUsername()..", aborting.") return end
    self.yourCartData:clear()

    sendClientCommand(self.player,"shop", "processOrder", { playerID=walletID, storeID=self.bankObj.ID, buying=itemToPurchase, selling=itemsToSell })
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
    o.selectedItem = nil
    o.pendingRequest = false
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


