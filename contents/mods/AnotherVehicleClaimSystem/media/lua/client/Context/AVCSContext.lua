function AVCSContextMenu(_, context, worldObjects)
    context:addOption(getText("IGUI_AVCS_OpenMenu"), worldObjects, AVCSItemsListViewer.OnOpenPanel, nil)
end


Events.OnPreFillWorldObjectContextMenu.Add(AVCSContextMenu)
