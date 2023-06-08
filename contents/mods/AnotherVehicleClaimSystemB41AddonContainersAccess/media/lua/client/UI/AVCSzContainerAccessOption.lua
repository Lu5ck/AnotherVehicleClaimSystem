if not AVCS.oAVCSUserPermissionPanelcreateChildren then
    AVCS.oAVCSUserPermissionPanelcreateChildren = AVCS.UI.UserPermissionPanel.createChildren
end

function AVCS.UI.UserPermissionPanel:createChildren()
    AVCS.oAVCSUserPermissionPanelcreateChildren(self)
    self:addSets(getText("IGUI_AVCS_User_Permissions_lblAllowContainersAccess"), "AllowContainersAccess")
end