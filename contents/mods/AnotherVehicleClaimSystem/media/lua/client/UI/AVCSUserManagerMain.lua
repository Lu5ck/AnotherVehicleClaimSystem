local padTop = getTextManager():getFontHeight(UIFont.NewSmall) + 1
local padLeft = 10
local padRight = 10
local padBottom = 10
local tabBtnSize = 30
-- Set as global local variable instead of "self" variable because not something meant to be modified by outside codess
local prevTabBtn
local prevListVehiclesSelected = 1

AVCS.UI.UserManagerMain = ISCollapsableWindow:derive("AVCS.UI.UserManagerMain")

function AVCS.UI.UserManagerMain:initialise()
	ISCollapsableWindow.initialise(self)
end

function AVCS.UI.UserManagerMain:btnUnclaim_onConfirmClick(btn, _, _)
    if btn.internal == "NO" then return end
    local temp = self
    sendClientCommand(getPlayer(), "AVCS", "unclaimVehicle", { self.listVehicles.items[self.listVehicles.selected].item })
    self.listVehicles:removeItemByIndex(self.listVehicles.selected)

    local dbPlayers = ModData.get("AVCSByPlayerID")
    local dbVehicles = ModData.get("AVCSByVehicleSQLID")
    if self.listVehicles.selected ~= 0 then
        self.vehiclePreview.javaObject:fromLua2("setVehicleScript", "previewVeh", dbVehicles[self.listVehicles.items[self.listVehicles.selected].item].CarModel)
        self.lblVehicleOwnerInfo:setName(dbVehicles[self.listVehicles.items[self.listVehicles.selected].item].OwnerPlayerID)
        self.lblVehicleExpireInfo:setName(os.date("%d-%b-%y", (dbPlayers[dbVehicles[self.listVehicles.items[self.listVehicles.selected].item].OwnerPlayerID].LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60))))
        self.lblVehicleLocationInfo:setName(dbVehicles[self.listVehicles.items[self.listVehicles.selected].item].LastLocationX .. ", " .. dbVehicles[self.listVehicles.items[self.listVehicles.selected].item].LastLocationY)
        self.lblVehicleLastLocationUpdateInfo:setName(os.date("%d-%b-%y", (dbVehicles[self.listVehicles.items[self.listVehicles.selected].item].LastLocationUpdateDateTime)))
        self.btnUnclaim:setEnable(true)
    else
        self.listVehicles:addItem(getText("IGUI_AVCS_User_Manager_listVehicles_NoVehicle"), nil)
        self.vehiclePreview.javaObject:fromLua2("setVehicleScript", "previewVeh", "")
        self.lblVehicleOwnerInfo:setName("-")
        self.lblVehicleExpireInfo:setName("-")
        self.lblVehicleLocationInfo:setName("-")
        self.lblVehicleLastLocationUpdateInfo:setName("-")
        self.btnUnclaim:setEnable(false)
    end
end

function AVCS.UI.UserManagerMain:btnUnclaim_onClick()
    local message = "Confirm"
    if self.modDialog ~= nil then
        self.modDialog:close()
        self.modDialog:removeFromUIManager()
        self.modDialog = nil
    end
    self.modDialog = ISModalDialog:new((getCore():getScreenWidth() / 2) - (250 / 2), (getCore():getScreenHeight() / 2) - (100 / 2), 250, 100, message, true, self, AVCS.UI.UserManagerMain.btnUnclaim_onConfirmClick, getPlayer():getPlayerNum(), nil)
    self.modDialog:initialise()
    self.modDialog:addToUIManager()
end

function AVCS.UI.UserManagerMain:tabBtn_onClick(btn)
    -- Don't do anything if user keep smashing the button
    if btn == prevTabBtn then
        return
    end
    -- Change bg color of active tab
    btn:setBackgroundRGBA(0.3, 0.3, 0.3, 1)
    prevTabBtn:setBackgroundRGBA(0, 0, 0, 1)
    prevTabBtn = btn
    self:updateListVehicles()
end

function AVCS.UI.UserManagerMain:listVehiclesOnMouseDown(x, y)
    ISScrollingListBox.onMouseDown(self, x, y)
    if self.selected ~= prevListVehiclesSelected then
        prevListVehiclesSelected = self.selected
        -- self.items
        -- self.selected
        -- self.parent
        AVCS.UI.UserManagerMain:listVehiclesOnSelectedChange(self.parent, self.items, self.selected)
    end
end

function AVCS.UI.UserManagerMain:listVehiclesOnJoypadDirUp()
    ISScrollingListBox.onJoypadDirUp(self)
    if self.selected ~= prevListVehiclesSelected then
        prevListVehiclesSelected = self.selected
    end
end

function AVCS.UI.UserManagerMain:listVehiclesOnJoypadDirDown()
    ISScrollingListBox.onJoypadDirDown(self)
    if self.selected ~= prevListVehiclesSelected then
        prevListVehiclesSelected = self.selected
    end
end

function AVCS.UI.UserManagerMain:updateListVehicles()
    local dbPlayers = ModData.get("AVCSByPlayerID")
    local dbVehicles = ModData.get("AVCSByVehicleSQLID")
    self.listVehicles:clear()
    prevListVehiclesSelected = 1

    if prevTabBtn.internal == "tabPersonal" then
        if dbPlayers[getPlayer():getUsername()] == nil or #dbPlayers[getPlayer():getUsername()] == 1 then
            self.listVehicles:addItem(getText("IGUI_AVCS_User_Manager_listVehicles_NoVehicle"), nil)
            self.vehiclePreview.javaObject:fromLua2("setVehicleScript", "previewVeh", "")
        else
            for k, v in pairs(dbPlayers[getPlayer():getUsername()]) do
                if k ~= "LastKnownLogonTime" then
                    -- Get get rid of the prefix, not all prefix start with "Base." so we look for first dot instead
                    local carFullName = dbVehicles[k].CarModel
                    local index = string.find(carFullName, "%.")
                    
                    --  Reuse the variable, no biggie
                    carFullName = getTextOrNull("IGUI_VehicleName" .. string.sub(carFullName, index + 1, string.len(carFullName)))

                    if carFullName then
                        self.listVehicles:addItem(carFullName, k)
                    else
                        self.listVehicles:addItem(dbVehicles[k].CarModel, k)
                    end
                end
            end
        end
    elseif prevTabBtn.internal == "tabSafehouse" then
        local safehouseObj = SafeHouse.hasSafehouse(getPlayer():getUsername())
        if safehouseObj then
            local tempPlayers = safehouseObj:getPlayers()
            for i = 0, tempPlayers:size() - 1 do
                if tempPlayers:get(i) ~= getPlayer():getUsername() then
                    for k, v in pairs(dbPlayers[tempPlayers:get(i)]) do
                        if k ~= "LastKnownLogonTime" then
                            -- Get get rid of the prefix, not all prefix start with "Base." so we look for first dot instead
                            local carFullName = dbVehicles[k].CarModel
                            local index = string.find(carFullName, "%.")
                            
                            --  Reuse the variable, no biggie
                            carFullName = getTextOrNull("IGUI_VehicleName" .. string.sub(carFullName, index + 1, string.len(carFullName)))

                            if carFullName then
                                self.listVehicles:addItem(carFullName, k)
                            else
                                self.listVehicles:addItem(dbVehicles[k].CarModel, k)
                            end
                        end
                    end
                end
            end
            
        end
    elseif prevTabBtn.internal == "tabFaction" then
        local factionObj = Faction.getPlayerFaction(getPlayer():getUsername())
        if factionObj then
            -- Owner and Members are not in the same list
            -- Dirty codings
            if factionObj:getOwner() ~= getPlayer():getUsername() then
                for k, v in pairs(dbPlayers[factionObj:getOwner()]) do
                    if k ~= "LastKnownLogonTime" then
                        -- Get get rid of the prefix, not all prefix start with "Base." so we look for first dot instead
                        local carFullName = dbVehicles[k].CarModel
                        local index = string.find(carFullName, "%.")
                        
                        --  Reuse the variable, no biggie
                        carFullName = getTextOrNull("IGUI_VehicleName" .. string.sub(carFullName, index + 1, string.len(carFullName)))

                        if carFullName then
                            self.listVehicles:addItem(carFullName, k)
                        else
                            self.listVehicles:addItem(dbVehicles[k].CarModel, k)
                        end
                    end
                end
            end

            local tempPlayers = factionObj:getPlayers()
            for i = 0, tempPlayers:size() - 1 do
                if tempPlayers:get(i) ~= getPlayer():getUsername() then
                    for k, v in pairs(dbPlayers[tempPlayers:get(i)]) do
                        if k ~= "LastKnownLogonTime" then
                            -- Get get rid of the prefix, not all prefix start with "Base." so we look for first dot instead
                            local carFullName = dbVehicles[k].CarModel
                            local index = string.find(carFullName, "%.")
                            
                            --  Reuse the variable, no biggie
                            carFullName = getTextOrNull("IGUI_VehicleName" .. string.sub(carFullName, index + 1, string.len(carFullName)))

                            if carFullName then
                                self.listVehicles:addItem(carFullName, k)
                            else
                                self.listVehicles:addItem(dbVehicles[k].CarModel, k)
                            end
                        end
                    end
                end
            end
        end
    end

    if #self.listVehicles.items > 0 then
        self.vehiclePreview.javaObject:fromLua2("setVehicleScript", "previewVeh", dbVehicles[self.listVehicles.items[1].item].CarModel)
        self.lblVehicleOwnerInfo:setName(dbVehicles[self.listVehicles.items[1].item].OwnerPlayerID)
        self.lblVehicleExpireInfo:setName(os.date("%d-%b-%y", (dbPlayers[dbVehicles[self.listVehicles.items[1].item].OwnerPlayerID].LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60))))
        self.lblVehicleLocationInfo:setName(dbVehicles[self.listVehicles.items[1].item].LastLocationX .. ", " .. dbVehicles[self.listVehicles.items[1].item].LastLocationY)
        self.lblVehicleLastLocationUpdateInfo:setName(os.date("%d-%b-%y", (dbVehicles[self.listVehicles.items[1].item].LastLocationUpdateDateTime)))
        self.btnUnclaim:setEnable(true)
    else
        self.listVehicles:addItem(getText("IGUI_AVCS_User_Manager_listVehicles_NoVehicle"), nil)
        self.vehiclePreview.javaObject:fromLua2("setVehicleScript", "previewVeh", "")
        self.lblVehicleOwnerInfo:setName("-")
        self.lblVehicleExpireInfo:setName("-")
        self.lblVehicleLocationInfo:setName("-")
        self.lblVehicleLastLocationUpdateInfo:setName("-")
        self.btnUnclaim:setEnable(false)
    end
end

function AVCS.UI.UserManagerMain:listVehiclesOnSelectedChange(parent, items, selected)
    local vehicleSQLID = items[selected].item
    if vehicleSQLID == nil then return end

    local dbVehicles = ModData.get("AVCSByVehicleSQLID")
    parent.vehiclePreview.javaObject:fromLua2("setVehicleScript", "previewVeh", dbVehicles[vehicleSQLID].CarModel)
end

-- Create on-demand buttons
function AVCS.UI.UserManagerMain:addTabButtons(btnName, bgImage, x, y)
    local i = #self.tabButtons + 1
    local top = getTextManager():getFontHeight(UIFont.NewSmall) + 1

    self.tabButtons[i] = ISButton:new(x, y, tabBtnSize, tabBtnSize, "", self, AVCS.UI.UserManagerMain.tabBtn_onClick)
    self.tabButtons[i].internal = btnName
    self.tabButtons[i].anchorTop = true
    self.tabButtons[i].anchorBottom = true
    self.tabButtons[i].borderColor = {r=0.5, g=0.5, b=0.5, a=1}
    self.tabButtons[i].backgroundColor = {r=0, g=0, b=0, a=1}
    self.tabButtons[i].displayBackground = true
	self.tabButtons[i]:setImage(bgImage)
	self.tabButtons[i]:setTextureRGBA(1, 0, 0, 1)
    self.tabButtons[i]:initialise()
    self.tabButtons[i]:instantiate()
    self.tabButtons[i]:setEnable(true)
    self:addChild(self.tabButtons[i])
end

function AVCS.UI.UserManagerMain:createChildren()
    ISCollapsableWindow.createChildren(self)

    -- Create a visual left pane where buttons will sit in
    local leftPaneHolderWidth = 40
    self.leftPaneHolder = ISPanel:new(0, padTop, leftPaneHolderWidth, self.height - 1 - getTextManager():getFontHeight(UIFont.NewSmall), "", self, AVCS.UI.UserManagerMain.btnUnclaim_onClick)
    --self.leftPaneHolder.displayBackground = true
    --self.leftPaneHolder.backgroundColor = {r=0, g=0, b=0, a=1}
    self.leftPaneHolder:initialise()
    self.leftPaneHolder:instantiate()
    self:addChild(self.leftPaneHolder)

    -- Create Selection List
    local listVehiclesStartX = 40
    local listVehiclesWidth = 250
    self.listVehicles = ISScrollingListBox:new(leftPaneHolderWidth + 1, padTop + 1, listVehiclesWidth, self.height - padTop - 1)
    self.listVehicles.onMouseDown = self.listVehiclesOnMouseDown
    self.listVehicles.onJoypadDirUp = self.listVehiclesOnJoypadDirUp
    self.listVehicles.onJoypadDirDown = self.listVehiclesOnJoypadDirDown
    self.listVehicles:initialise()
    self.listVehicles:instantiate()
    self:addChild(self.listVehicles)
    self.listVehicles:setFont(UIFont.NewSmall, 5)

    -- Create Vehicle Preview
    self.vehiclePreview = ISUI3DScene:new(leftPaneHolderWidth + 1 + listVehiclesWidth + 1, padTop, self.width - leftPaneHolderWidth - 1 - listVehiclesWidth - 1, self.height - padTop)
    self.vehiclePreview:initialise()
    self.vehiclePreview:instantiate()
    self.vehiclePreview:setAnchorTop(false)
    self.vehiclePreview:setAnchorRight(false)
    self.vehiclePreview:setAnchorBottom(true)
    self.vehiclePreview:setView("Right")
    self.vehiclePreview.javaObject:fromLua1("setZoom", 4)
    self.vehiclePreview.javaObject:fromLua1("setDrawGrid", false)
    self.vehiclePreview.javaObject:fromLua1("createVehicle", "previewVeh")
    self.vehiclePreview.javaObject:fromLua2("setVehicleScript", "previewVeh", "")
    self:addChild(self.vehiclePreview)

    -- Create Label for Vehicle Info
    self.lblVehicleOwner = ISLabel:new(leftPaneHolderWidth + 1 + listVehiclesWidth + 1 + 5, padTop + 1, getTextManager():getFontHeight(UIFont.NewSmall), getText("IGUI_AVCS_User_Manager_lblVehicleOwner"), 1, 1, 1, 1, UIFont.NewSmall, true)
    self.lblVehicleOwner:initialise()
    self.lblVehicleOwner:instantiate()
    self:addChild(self.lblVehicleOwner)

    self.lblVehicleOwnerInfo = ISLabel:new(leftPaneHolderWidth + 1 + listVehiclesWidth + 1 + 5, padTop + 1 + ((getTextManager():getFontHeight(UIFont.NewSmall)) * 1) + (1 * 1), getTextManager():getFontHeight(UIFont.NewSmall), "", 0.2, 1, 0.2, 1, UIFont.NewSmall, true)
    self.lblVehicleOwnerInfo:initialise()
    self.lblVehicleOwnerInfo:instantiate()
    self:addChild(self.lblVehicleOwnerInfo)

    self.lblVehicleExpire = ISLabel:new(leftPaneHolderWidth + 1 + listVehiclesWidth + 1 + 5, padTop + 1 + ((getTextManager():getFontHeight(UIFont.NewSmall)) * 2) + (1 * 2), getTextManager():getFontHeight(UIFont.NewSmall), getText("IGUI_AVCS_User_Manager_lblVehicleExpire"), 1, 1, 1, 1, UIFont.NewSmall, true)
    self.lblVehicleExpire:initialise()
    self.lblVehicleExpire:instantiate()
    self:addChild(self.lblVehicleExpire)

    self.lblVehicleExpireInfo = ISLabel:new(leftPaneHolderWidth + 1 + listVehiclesWidth + 1 + 5, padTop + 1 + ((getTextManager():getFontHeight(UIFont.NewSmall)) * 3) + (1 * 3), getTextManager():getFontHeight(UIFont.NewSmall), "", 0.2, 1, 0.2, 1, UIFont.NewSmall, true)
    self.lblVehicleExpireInfo:initialise()
    self.lblVehicleExpireInfo:instantiate()
    self:addChild(self.lblVehicleExpireInfo)

    self.lblVehicleLocation = ISLabel:new(leftPaneHolderWidth + 1 + listVehiclesWidth + 1 + 5 + 230, padTop + 1, getTextManager():getFontHeight(UIFont.NewSmall), getText("IGUI_AVCS_User_Manager_lblVehicleLocation"), 1, 1, 1, 1, UIFont.NewSmall, true)
    self.lblVehicleLocation:initialise()
    self.lblVehicleLocation:instantiate()
    self:addChild(self.lblVehicleLocation)

    self.lblVehicleLocationInfo = ISLabel:new(leftPaneHolderWidth + 1 + listVehiclesWidth + 1 + 5 + 230, padTop + 1 + ((getTextManager():getFontHeight(UIFont.NewSmall)) * 1) + (1 * 1), getTextManager():getFontHeight(UIFont.NewSmall), "", 0.2, 1, 0.2, 1, UIFont.NewSmall, true)
    self.lblVehicleLocationInfo:initialise()
    self.lblVehicleLocationInfo:instantiate()
    self:addChild(self.lblVehicleLocationInfo)

    self.lblVehicleLastLocationUpdate = ISLabel:new(leftPaneHolderWidth + 1 + listVehiclesWidth + 1 + 5 + 230, padTop + 1 + ((getTextManager():getFontHeight(UIFont.NewSmall)) * 2) + (1 * 2), getTextManager():getFontHeight(UIFont.NewSmall), getText("IGUI_AVCS_User_Manager_lblVehicleLastLocationUpdate"), 1, 1, 1, 1, UIFont.NewSmall, true)
    self.lblVehicleLastLocationUpdate:initialise()
    self.lblVehicleLastLocationUpdate:instantiate()
    self:addChild(self.lblVehicleLastLocationUpdate)

    self.lblVehicleLastLocationUpdateInfo = ISLabel:new(leftPaneHolderWidth + 1 + listVehiclesWidth + 1 + 5 + 230, padTop + 1 + ((getTextManager():getFontHeight(UIFont.NewSmall)) * 3) + (1 * 3), getTextManager():getFontHeight(UIFont.NewSmall), "", 0.2, 1, 0.2, 1, UIFont.NewSmall, true)
    self.lblVehicleLastLocationUpdateInfo:initialise()
    self.lblVehicleLastLocationUpdateInfo:instantiate()
    self:addChild(self.lblVehicleLastLocationUpdateInfo)

    -- Add tab buttons to function with list box
    local tempImage
    tempImage = getTexture("media/ui/avcs_personal.png")
    self:addTabButtons("tabPersonal", tempImage, 5, getTextManager():getFontHeight(UIFont.NewSmall) + 1 + 5)
    self.tabButtons[1]:setTooltip(getText("IGUI_AVCS_User_Manager_tabButton_Personal_Tooltip"))
    -- Set this as default tab button
    self.tabButtons[1]:setBackgroundRGBA(0.3, 0.3, 0.3, 1)
    prevTabBtn = self.tabButtons[1]
    
    if SandboxVars.AVCS.AllowSafehouse then
        --if SafeHouse.hasSafehouse(getPlayer()) then
            tempImage = getTexture("media/ui/avcs_safehouse.png")
            local y = getTextManager():getFontHeight(UIFont.NewSmall) + 1 + 5
            y = y + (tabBtnSize * #self.tabButtons) + 5
            self:addTabButtons("tabSafehouse", tempImage, 5, y)
            self.tabButtons[#self.tabButtons]:setTooltip(getText("IGUI_AVCS_User_Manager_tabButton_Safehouse_Tooltip"))
        --end
    end
    if SandboxVars.AVCS.AllowFaction then
        --if Faction.isAlreadyInFaction(getPlayer()) then
            tempImage = getTexture("media/ui/avcs_factions.png")
            local y = getTextManager():getFontHeight(UIFont.NewSmall) + 1 + 5
            y = y + (tabBtnSize * #self.tabButtons) + 5
            if #self.tabButtons > 1 then
                y = y + ((#self.tabButtons - 1) * 5)
            end
            self:addTabButtons("tabFaction", tempImage, 5, y)
            self.tabButtons[#self.tabButtons]:setTooltip(getText("IGUI_AVCS_User_Manager_tabButton_Faction_Tooltip"))
        --end
    end

    -- Create unclaim button
    local y = getTextManager():getFontHeight(UIFont.NewSmall) + 1 + 5
    y = y + (tabBtnSize * #self.tabButtons) + 5
    if #self.tabButtons > 1 then
        y = y + ((#self.tabButtons - 1) * 5)
    end
    self.btnUnclaim = ISButton:new(5, y, tabBtnSize, tabBtnSize, "", self, AVCS.UI.UserManagerMain.btnUnclaim_onClick)
    self.btnUnclaim.internal = "btnUnclaim"
    self.btnUnclaim.anchorTop = false
    self.btnUnclaim.anchorBottom = true
    self.btnUnclaim.borderColor = {r=0.5, g=0.5, b=0.5, a=1}
    self.btnUnclaim.backgroundColor = {r=0, g=0, b=0, a=1}
    self.btnUnclaim.displayBackground = true
    self.btnUnclaim:setTooltip(getText("IGUI_AVCS_User_Manager_btnUnclaim_Tooltip"))
	self.btnUnclaim:setImage(getTexture("media/ui/avcs_delete.png"))
	self.btnUnclaim:setTextureRGBA(1, 0, 0, 1)
    self.btnUnclaim:initialise()
    self.btnUnclaim:instantiate()
    self.btnUnclaim:setEnable(false)
    self:addChild(self.btnUnclaim)

    self:updateListVehicles()
end

function AVCS.UI.UserManagerMain:close()
    ISCollapsableWindow.close(self)
    if AVCS.UI.UserInstance then AVCS.UI.UserInstance = nil end
    self:removeFromUIManager()

    if self.modDialog ~= nil then
        self.modDialog:close()
        self.modDialog:removeFromUIManager()
        self.modDialog = nil
    end
end

function AVCS.UI.UserManagerMain:prerender()
	ISCollapsableWindow.prerender(self)
end

function AVCS.UI.UserManagerMain:render()
	ISCollapsableWindow.render(self)
end

function AVCS.UI.UserManagerMain:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.showBackground = false
    o.backgroundColor = {r=0.15, g=0.15, b=0.15, a=1.0}
	o.showBorder = true
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.title = getText("IGUI_AVCS_User_Manager_Title")
    o.width = width
    o.height = height
	o.visibleTarget	= o
    o.moveWithMouse = true
    o.pin = true
    o.tabButtons = {}
    o:setResizable(false)
	o:setDrawFrame(true)
    return o
end
