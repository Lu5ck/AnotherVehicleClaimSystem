local pad = 10
local optionSets = {}

AVCS.UI.UserPermissionPanel = ISPanel:derive("AVCS.UI.UserPermissionPanel")

function AVCS.UI.UserPermissionPanel:initialise()
	ISPanel.initialise(self)
end

function AVCS.UI.UserPermissionPanel:close()
	ISPanel.close(self)
end

function AVCS.UI.UserPermissionPanel:prerender()
    ISPanel.prerender(self)
end

function AVCS.UI.UserPermissionPanel:btnCancel_onClick(btn)
    self.close(self)
end

function AVCS.UI.UserPermissionPanel:btnConfirm_onClick(btn)
    if AVCS.dbByVehicleSQLID[self.vehicleID] then
        local temp = {}
        local count = 0
        for i = 1, #self.lblSet do
            local test
            temp[self.chkBox[i].internal] = self.chkBox[i]:isSelected(1)

            -- Counting for changes. Empty table will returns as nil, we need boolean
            if AVCS.dbByVehicleSQLID[self.vehicleID][self.chkBox[i].internal] then
                test = true
            else
                test = false
            end
            if test ~= self.chkBox[i]:isSelected(1) then
                count = count + 1
            end
        end
        
        -- Only send command if there's changes, prevent malicious spamming
        if count > 0 then
            temp.VehicleID = self.vehicleID
            sendClientCommand(getPlayer(), "AVCS", "updateSpecifyVehicleUserPermission", temp)
        end
    end

    self.close(self)
end

function AVCS.UI.UserPermissionPanel:addSets(text, name)
    local top = pad + getTextManager():getFontHeight(UIFont.NewSmall)
    local lblpadleft = pad + 10
    local i = #self.lblSet + 1

    self.lblSet[i] = ISLabel:new(lblpadleft, 12 + ((getTextManager():getFontHeight(UIFont.NewSmall) + 5) * i), getTextManager():getFontHeight(UIFont.NewSmall), text, 1, 1, 1, 1, UIFont.NewSmall, true)
    self.lblSet[i]:initialise()
    self.lblSet[i]:instantiate()
    self:addChild(self.lblSet[i])

    self.chkBox[i] = ISTickBox:new(self.width - getTextManager():getFontHeight(UIFont.NewSmall) - 20, 12 + ((getTextManager():getFontHeight(UIFont.NewSmall) + 5) * i), getTextManager():getFontHeight(UIFont.NewSmall), getTextManager():getFontHeight(UIFont.NewSmall), "", nil, nil)
    self.chkBox[i].internal = name
    self.chkBox[i]:initialise();
    self.chkBox[i]:instantiate();
    self.chkBox[i]:addOption("");
    self:addChild(self.chkBox[i]);
    
    if AVCS.dbByVehicleSQLID[self.vehicleID][name] then
        self.chkBox[i]:setSelected(1, true)
    end
end

function AVCS.UI.UserPermissionPanel:createChildren()
    local btnWidth = 50
    local bthHeight = 30

    self.btnCancel = ISButton:new(self.width / 2 - btnWidth - 15, self.height - bthHeight - pad, btnWidth, bthHeight, "Cancel", self, AVCS.UI.UserPermissionPanel.btnCancel_onClick)
    self.btnCancel.internal = "btnCancel"
    self.btnCancel.borderColor = {r=0.5, g=0.5, b=0.5, a=1}
    self.btnCancel.backgroundColor = {r=0, g=0, b=0, a=1}
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self.btnCancel:setEnable(true)
    self:addChild(self.btnCancel)

    self.btnConfirm = ISButton:new(self.width / 2 + 15, self.height - bthHeight - pad, btnWidth, bthHeight, "OK", self, AVCS.UI.UserPermissionPanel.btnConfirm_onClick)
    self.btnConfirm.internal = "btnConfirm"
    self.btnConfirm.borderColor = {r=0.5, g=0.5, b=0.5, a=1}
    self.btnConfirm.backgroundColor = {r=0, g=0, b=0, a=1}
    self.btnConfirm:initialise()
    self.btnConfirm:instantiate()
    self.btnConfirm:setEnable(true)
    self:addChild(self.btnConfirm)

    local lblpadleft = pad + 10
    local lblwidth = getTextManager():MeasureStringX(UIFont.NewSmall, getText("IGUI_AVCS_User_Permissions_lblPublicPermissions"))
    self.lblPublicPermissions = ISLabel:new((self.width / 2) - (lblwidth / 2), pad, getTextManager():getFontHeight(UIFont.NewSmall), getText("IGUI_AVCS_User_Permissions_lblPublicPermissions"), 1, 1, 1, 1, UIFont.NewSmall, true)
    self.lblPublicPermissions:initialise()
    self.lblPublicPermissions:instantiate()
    self:addChild(self.lblPublicPermissions)

    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowDrive"), "AllowDrive")
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowPassenger"), "AllowPassenger")
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowSiphonFuel"), "AllowSiphonFuel")
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowUninstallParts"), "AllowUninstallParts")
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowAttachVehicle"), "AllowAttachVehicle")
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowDetechVehicle"), "AllowDetechVehicle")
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowTakeEngineParts"), "AllowTakeEngineParts")
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowOpeningTrunk"), "AllowOpeningTrunk")
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowInflatTires"), "AllowInflatTires")
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowDeflatTires"), "AllowDeflatTires")
end

function AVCS.UI.UserPermissionPanel:new(x, y, width, height, vehicleID)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.background = true
    o.backgroundColor = {r=0, g=0, b=0, a=1}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.width = width
    o.height = height
    o.moveWithMouse = false
    o.vehicleID = vehicleID
    o.lblSet = {}
    o.chkBox = {}
    return o
end