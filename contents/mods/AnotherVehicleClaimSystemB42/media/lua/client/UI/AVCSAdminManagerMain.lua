local padTop = getTextManager():getFontHeight(UIFont.NewSmall) + 1

AVCS.UI.AdminManagerMain = ISCollapsableWindow:derive("AVCS.UI.AdminManagerMain")

function AVCS.UI.AdminManagerMain:listDataOnMouseDown(x, y)
	if #self.items == 0 then return end
	local row = self:rowAt(x, y)

	if row > #self.items then
		row = #self.items
	end

	if row < 1 then
        -- In vanilla, they change selection to first item if click on blank place which is silly
		return
	end

    -- Ignores if same selection
    if row == self.selected then
        return
    end

	getSoundManager():playUISound("UISelectListItem")

	self.selected = row

	if self.onmousedown then
		self.onmousedown(self.target, self.items[self.selected].item)
	end

    self.parent.listOnSelectionChange(self.parent)
end

function AVCS.UI.AdminManagerMain:listOnSelectionChange()
    self.btnViewSafehouse:setEnable(false)
    self.btnViewFaction:setEnable(false)
    self.btnModifyPermissions:setEnable(false)
    self.btnDelete:setEnable(false)

    if self.panelModify ~= nil then
        self.panelModify:close()
        self.panelModify:removeFromUIManager()
        self.panelModify = nil
    end

    if self.modDialog ~= nil then
        self.modDialog:close()
        self.modDialog:removeFromUIManager()
        self.modDialog = nil
    end

    if self.listData.count > 0 and (string.lower(getPlayer():getAccessLevel()) == "admin" or (not isClient() and not isServer())) then
        self.btnModifyPermissions:setEnable(true)
        self.btnDelete:setEnable(true)
        if SafeHouse.hasSafehouse(self.listData.items[self.listData.selected].item.OwnerPlayerID) then
            self.btnViewSafehouse:setEnable(true)
        end
        if Faction.getPlayerFaction(self.listData.items[self.listData.selected].item.OwnerPlayerID) then
            self.btnViewFaction:setEnable(true)
        end
    end
end

function AVCS.UI.AdminManagerMain:drawData(y, item, alt)
    -- Apparently, you need to manually draw text into the columns, so programming friendly!
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end
    
    local a = 0.9;

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5);
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local iconX = 4
    local iconSize = FONT_HGT_SMALL;
    local xoffset = 10;

    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)

    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item.OwnerPlayerID, xoffset, y + 4, 1, 1, 1, a, self.font)
    self:clearStencilRect()

    clipX = self.columns[2].size
    clipX2 = self.columns[3].size
    self.javaObject:DrawTextureScaledColor(nil, self.columns[2].size, y, 1, self.itemheight, self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a)
    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item.vehicleID, self.columns[2].size + xoffset, y + 4, 1, 1, 1, a, self.font)
    self:clearStencilRect()

    clipX = self.columns[3].size
    clipX2 = self.columns[4].size
    self.javaObject:DrawTextureScaledColor(nil, self.columns[3].size, y, 1, self.itemheight, self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a)
    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item.carFullName, self.columns[3].size + xoffset, y + 4, 1, 1, 1, a, self.font)
    self:clearStencilRect()

    clipX = self.columns[4].size
    clipX2 = self.columns[5].size
    self.javaObject:DrawTextureScaledColor(nil, self.columns[4].size, y, 1, self.itemheight, self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a)
    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item.ClaimDateTime, self.columns[4].size + xoffset, y + 4, 1, 1, 1, a, self.font)
    self:clearStencilRect()

    clipX = self.columns[5].size
    clipX2 = self.columns[6].size
    self.javaObject:DrawTextureScaledColor(nil, self.columns[5].size, y, 1, self.itemheight, self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a)
    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item.Location, self.columns[5].size + xoffset, y + 4, 1, 1, 1, a, self.font)
    self:clearStencilRect()

    self.javaObject:DrawTextureScaledColor(nil, self.columns[6].size, y, 1, self.itemheight, self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a)
    self:drawText(item.item.ExpireOn, self.columns[6].size + xoffset, y + 4, 1, 1, 1, a, self.font)

    return y + self.itemheight;

end

function AVCS.UI.AdminManagerMain:listDataDrawText(str, x, y, r, g, b, a, font)
	if self.javaObject ~= nil then
		if font ~= nil then
			self.javaObject:DrawText(font, tostring(str), x, y, r, g, b, a);
		else
			self.javaObject:DrawText(UIFont.Small, tostring(str), x, y, r, g, b, a);
		end
	end
end

function AVCS.UI.AdminManagerMain:filterStringCompare(mainText, compareText)
    return checkStringPattern(compareText) and string.match(string.lower(mainText), string.lower(compareText))
end

function AVCS.UI.AdminManagerMain:onFilterChange()
    self.parent.listData:clear()
    for k, v in ipairs(self.parent.varData) do
        local add = true
        if not AVCS.UI.AdminManagerMain:filterStringCompare(v.OwnerPlayerID, self.parent.textFilterUsername:getInternalText()) then
            add = false
        end
        if add then
            if not AVCS.UI.AdminManagerMain:filterStringCompare(v.carFullName, self.parent.textFilterVehicleName:getInternalText()) then
                add = false
            end
        end
        if add then
            self.parent.listData:addItem(v.OwnerPlayerID, v)
        end
    end
end

function AVCS.UI.AdminManagerMain:initList()
    -- We sort by player first, than sort by display name of the car model
    -- Ultimately, we will have a vehicle ID list sorted in the way we want

    -- Build a table sorted by username then by vehicle name
    local tempTable = {}
    for k, v in pairs(AVCS.dbByPlayerID) do
        for ak, av in pairs(v) do
            if ak ~= "LastKnownLogonTime" then
                local carFullName = AVCS.dbByVehicleSQLID[ak].CarModel
                local index = string.find(carFullName, "%.")
                carFullName = getTextOrNull("IGUI_VehicleName" .. string.sub(carFullName, index + 1, string.len(carFullName)))
                if not carFullName  then
                    carFullName = AVCS.dbByVehicleSQLID[ak].CarModel
                end
                table.insert(tempTable, {OwnerPlayerID = k, carFullName = carFullName,  vehicleID = ak, ExpireOn = os.date("%d-%b-%y, %H:%M:%S", (AVCS.dbByPlayerID[k].LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60))), Location = AVCS.dbByVehicleSQLID[ak].LastLocationX .. "," .. AVCS.dbByVehicleSQLID[ak].LastLocationY, ClaimDateTime = os.date("%d-%b-%y, %H:%M:%S", AVCS.dbByVehicleSQLID[ak].ClaimDateTime)})
            end
        end
    end

    if #tempTable > 0 then
        table.sort(tempTable, function (a,b)
            if a.OwnerPlayerID == b.OwnerPlayerID then
                return a.carFullName < b.carFullName
            else
                return a.OwnerPlayerID < b.OwnerPlayerID
            end
        end)

        for k, v in ipairs(tempTable) do
            self.listData:addItem(v.OwnerPlayerID, v)
        end

        self.varData = tempTable
    end
end

function AVCS.UI.AdminManagerMain:initialise()
	ISCollapsableWindow.initialise(self)
end

function AVCS.UI.AdminManagerMain:createChildren()
    ISCollapsableWindow.createChildren(self)

    self.listData = ISScrollingListBox:new(40, 20 + padTop + getTextManager():getFontHeight(UIFont.NewSmall), self.width - 50, 360);
    self.listData:initialise()
    self.listData:instantiate()
    self.listData.joypadParent = self
    self.listData.doDrawItem = self.drawData
    self.listData.onMouseDown = self.listDataOnMouseDown
    self.listData.drawText = self.listDataDrawText
    self.listData.drawBorder = true
    -- Total width 840
    self.listData:addColumn(getText("IGUI_AVCS_Admin_Manager_listUsername"), 0) -- 150 width, 126 width actual text
    self.listData:addColumn(getText("IGUI_AVCS_Admin_Manager_listVehicleID"), 150) -- 70 width, title is 55 width actual
    self.listData:addColumn(getText("IGUI_AVCS_Admin_Manager_listCarName"), 270) -- 300 width, 46 characters max, we will cut off if too long
    self.listData:addColumn(getText("IGUI_AVCS_Admin_Manager_listClaimedDate"), 570) -- 120 width, 103 width actual text
    self.listData:addColumn(getText("IGUI_AVCS_Admin_Manager_listLocation"), 690) -- 80 width, 74 width actual
    self.listData:addColumn(getText("IGUI_AVCS_Admin_Manager_listExpireon"), 770) -- 120 width, 103 width actual text
    self:addChild(self.listData)
    self.listData:setFont(UIFont.NewSmall, 5)

    self.lblFilter = ISLabel:new(41, self.listData:getBottom() + 10, getTextManager():getFontHeight(UIFont.NewLarge), getText("IGUI_AVCS_Admin_Manager_lblFilter"), 1, 1, 1, 1, UIFont.NewLarge, true)
    self.lblFilter:initialise()
    self.lblFilter:instantiate()
    self:addChild(self.lblFilter)

    -- Just to use it as visual header
    self.listFilterHeader = ISScrollingListBox:new(40, self.lblFilter:getBottom() + 24, 452, 0)
    self.listFilterHeader:initialise()
    self.listFilterHeader:instantiate()
    self.listFilterHeader.drawBorder = true
    self.listFilterHeader:addColumn(getText("IGUI_AVCS_Admin_Manager_listUsername"), 0) -- 150 width, 126 width actual text
    self.listFilterHeader:addColumn(getText("IGUI_AVCS_Admin_Manager_listCarName"), 150) -- 300 width, 46 characters max
    self:addChild(self.listFilterHeader)
    self.listFilterHeader:setFont(UIFont.NewSmall, 5)
    
    self.textFilterUsername = ISTextEntryBox:new("", 40, self.listFilterHeader:getBottom(), 151, getTextManager():getFontHeight(UIFont.NewMedium))
    self.textFilterUsername.font = UIFont.NewMedium
    self.textFilterUsername:initialise()
    self.textFilterUsername:instantiate()
    self.textFilterUsername.onTextChange = self.onFilterChange
    self.textFilterUsername.target = self
    self.textFilterUsername:setClearButton(true)
    self:addChild(self.textFilterUsername)

    self.textFilterVehicleName = ISTextEntryBox:new("", 190, self.listFilterHeader:getBottom(), 302, getTextManager():getFontHeight(UIFont.NewMedium))
    self.textFilterVehicleName.font = UIFont.NewMedium
    self.textFilterVehicleName:initialise()
    self.textFilterVehicleName:instantiate()
    self.textFilterVehicleName.onTextChange = self.onFilterChange
    self.textFilterVehicleName.target = self
    self:addChild(self.textFilterVehicleName)

    local tempImage

    tempImage = getTexture("media/ui/avcs_safehouse.png")
    self.btnViewSafehouse = ISButton:new(6, 11 + getTextManager():getFontHeight(UIFont.NewSmall) , 30, 30, "", self, self.btnOnClick)
    self.btnViewSafehouse.internal = "btnViewSafehouse"
    self.btnViewSafehouse.borderColor = {r=0.5, g=0.5, b=0.5, a=1}
    self.btnViewSafehouse.backgroundColor = {r=0, g=0, b=0, a=1}
    self.btnViewSafehouse.displayBackground = true
	self.btnViewSafehouse:setImage(tempImage)
	self.btnViewSafehouse:setTextureRGBA(1, 0, 0, 1)
    self.btnViewSafehouse:initialise()
    self.btnViewSafehouse:instantiate()
    self.btnViewSafehouse:setEnable(false)
    self.btnViewSafehouse:setTooltip(getText("IGUI_AVCS_Admin_Manager_btnViewSafehouse_Tooltip"))
    self:addChild(self.btnViewSafehouse)

    tempImage = getTexture("media/ui/avcs_factions.png")
    self.btnViewFaction = ISButton:new(6, 46 + getTextManager():getFontHeight(UIFont.NewSmall) , 30, 30, "", self, self.btnOnClick)
    self.btnViewFaction.internal = "btnViewFaction"
    self.btnViewFaction.borderColor = {r=0.5, g=0.5, b=0.5, a=1}
    self.btnViewFaction.backgroundColor = {r=0, g=0, b=0, a=1}
    self.btnViewFaction.displayBackground = true
	self.btnViewFaction:setImage(tempImage)
	self.btnViewFaction:setTextureRGBA(1, 0, 0, 1)
    self.btnViewFaction:initialise()
    self.btnViewFaction:instantiate()
    self.btnViewFaction:setEnable(false)
    self.btnViewFaction:setTooltip(getText("IGUI_AVCS_Admin_Manager_btnViewFaction_Tooltip"))
    self:addChild(self.btnViewFaction)

    tempImage = getTexture("media/ui/avcs_modify.png")
    self.btnModifyPermissions = ISButton:new(6, 81 + getTextManager():getFontHeight(UIFont.NewSmall) , 30, 30, "", self, self.btnOnClick)
    self.btnModifyPermissions.internal = "btnModifyPermissions"
    self.btnModifyPermissions.borderColor = {r=0.5, g=0.5, b=0.5, a=1}
    self.btnModifyPermissions.backgroundColor = {r=0, g=0, b=0, a=1}
    self.btnModifyPermissions.displayBackground = true
	self.btnModifyPermissions:setImage(tempImage)
	self.btnModifyPermissions:setTextureRGBA(1, 0, 0, 1)
    self.btnModifyPermissions:initialise()
    self.btnModifyPermissions:instantiate()
    self.btnModifyPermissions:setEnable(false)
    self.btnModifyPermissions:setTooltip(getText("IGUI_AVCS_Admin_Manager_btnModifyPermissions_Tooltip"))
    self:addChild(self.btnModifyPermissions)

    tempImage = getTexture("media/ui/avcs_delete.png")
    self.btnDelete = ISButton:new(6, 116 + getTextManager():getFontHeight(UIFont.NewSmall) , 30, 30, "", self, self.btnOnClick)
    self.btnDelete.internal = "btnDelete"
    self.btnDelete.borderColor = {r=0.5, g=0.5, b=0.5, a=1}
    self.btnDelete.backgroundColor = {r=0, g=0, b=0, a=1}
    self.btnDelete.displayBackground = true
	self.btnDelete:setImage(tempImage)
	self.btnDelete:setTextureRGBA(1, 0, 0, 1)
    self.btnDelete:initialise()
    self.btnDelete:instantiate()
    self.btnDelete:setEnable(false)
    self.btnDelete:setTooltip(getText("IGUI_AVCS_Admin_Manager_btnDelete_Tooltip"))
    self:addChild(self.btnDelete)

    self:initList()
    self.listOnSelectionChange(self)
end

function AVCS.UI.AdminManagerMain:btnOnClick(btn)
    if btn.internal ~= "btnViewSafehouse" and btn.internal ~= "btnViewFaction" and btn.internal ~= "btnModifyPermissions" and btn.internal ~= "btnDelete" then
        return
    end

    if self.panelModify ~= nil then
        self.panelModify:close()
        self.panelModify:removeFromUIManager()
        self.panelModify = nil
    end

    if self.modDialog ~= nil then
        self.modDialog:close()
        self.modDialog:removeFromUIManager()
        self.modDialog = nil
    end

    if btn.internal == "btnViewSafehouse" then
        local safehouseUI = ISSafehouseUI:new(getCore():getScreenWidth() / 2 - 250,getCore():getScreenHeight() / 2 - 225, 500, 450, SafeHouse.hasSafehouse(self.listData.items[self.listData.selected].item.OwnerPlayerID), getPlayer())
        safehouseUI:initialise()
        safehouseUI:addToUIManager()
    elseif btn.internal == "btnViewFaction"  then
        local factionUI = ISFactionUI:new(getCore():getScreenWidth() / 2 - 250, getCore():getScreenHeight() / 2 - 225, 500, 450, Faction.getPlayerFaction(self.listData.items[self.listData.selected].item.OwnerPlayerID), getPlayer())
        factionUI:initialise()
        factionUI:addToUIManager()
    elseif btn.internal == "btnModifyPermissions" then
        self.panelModify = AVCS.UI.UserPermissionPanel:new((getCore():getScreenWidth() / 2) - (200 / 2), (getCore():getScreenHeight() / 2) - (300 / 2), 200, 300, self.listData.items[self.listData.selected].item.vehicleID)
        self.panelModify:initialise()
        self.panelModify:addToUIManager()
        self.panelModify:setVisible(true)
    elseif btn.internal == "btnDelete" then
        local message = "Confirm"
        self.modDialog = ISModalDialog:new((getCore():getScreenWidth() / 2) - (250 / 2), (getCore():getScreenHeight() / 2) - (100 / 2), 250, 100, message, true, self, AVCS.UI.AdminManagerMain.btnUnclaim_onConfirmClick, getPlayer():getPlayerNum(), nil)
        self.modDialog:initialise()
        self.modDialog:addToUIManager()
    end
end

function AVCS.UI.AdminManagerMain:btnUnclaim_onConfirmClick(btn, _, _)
    if btn.internal == "NO" then return end
    sendClientCommand(getPlayer(), "AVCS", "unclaimVehicle", { self.listData.items[self.listData.selected].item.vehicleID })
    self.removeUsernameVehicleID(self, self.listData.items[self.listData.selected].item.OwnerPlayerID, self.listData.items[self.listData.selected].item.vehicleID)
    self.listData:removeItemByIndex(self.listData.selected)
    self.listOnSelectionChange(self)
end

function AVCS.UI.AdminManagerMain:removeUsernameVehicleID(OwnerPlayerID, vehicleID)
    -- Binary seaerch, should be more efficient than typical for-loop when data get huge
    -- We want to avoid worst case scenario of data looping from start to end
    -- Only works for sorted list
    local varStart = 1
    local varEnd = #self.varData
    local varFound = 0

    while varStart <= varEnd do
        local varMid = math.floor((varStart + varEnd) / 2)
        if self.varData[varMid].OwnerPlayerID == OwnerPlayerID then
            if self.varData[varMid].vehicleID == vehicleID then
                table.remove(self.varData, varMid)
                return
            end
            varFound = varMid
            break
        elseif self.varData[varMid].OwnerPlayerID < OwnerPlayerID then
            varStart = varMid + 1
        else
            varEnd = varMid - 1
        end
    end

    -- Found the OwnerPlayerID but not vehicleID
    -- We will look at the adjucent data
    if varFound ~= 0 then
        local varTop = varFound + 1
        local varBottom = varFound - 1
        while true do
            if varTop <= #self.varData then
                if self.varData[varTop].OwnerPlayerID == OwnerPlayerID then
                    if self.varData[varTop].vehicleID == vehicleID then
                        table.remove(self.varData, varTop)
                        return
                    end
                    varTop = varTop + 1
                else
                    varTop = #self.varData + 1
                end
            end

            if varBottom ~= 0 then
                if self.varData[varBottom].OwnerPlayerID == OwnerPlayerID then
                    if self.varData[varBottom].vehicleID == vehicleID then
                        table.remove(self.varData, varBottom)
                        return
                    end
                    varBottom = varBottom - 1
                else
                    varBottom = 0
                end
            end

            -- There's nothing! Why is this even called?!
            if varTop > #self.varData and varBottom == 0 then
                break
            end
        end
    end
end

function AVCS.UI.AdminManagerMain:close()
    ISCollapsableWindow.close(self)

    if self.panelModify ~= nil then
        self.panelModify:close()
        self.panelModify:removeFromUIManager()
        self.panelModify = nil
    end

    if self.modDialog ~= nil then
        self.modDialog:close()
        self.modDialog:removeFromUIManager()
        self.modDialog = nil
    end
    
    if AVCS.UI.AdminInstance then AVCS.UI.AdminInstance = nil end
    self:removeFromUIManager()
end

function AVCS.UI.AdminManagerMain:prerender()
	ISCollapsableWindow.prerender(self)
end

function AVCS.UI.AdminManagerMain:render()
	ISCollapsableWindow.render(self)
end

function AVCS.UI.AdminManagerMain:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.showBackground = false
    o.backgroundColor = {r=0.15, g=0.15, b=0.15, a=1.0}
	o.showBorder = true
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.title = getText("IGUI_AVCS_Admin_Manager_Title")
    o.width = width
    o.height = height
	o.visibleTarget	= o
    o.moveWithMouse = true
    o.pin = true
    o.varData = {}
    o:setResizable(false)
	o:setDrawFrame(true)
    return o
end
