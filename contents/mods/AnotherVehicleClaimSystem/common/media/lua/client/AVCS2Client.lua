--[[
	Some codes referenced from
	CarWanna - https://steamcommunity.com/workshop/filedetails/?id=2801264901
	Vehicle Recycling - https://steamcommunity.com/sharedfiles/filedetails/?id=2289429759
	K15's Mods - https://steamcommunity.com/id/KI5/myworkshopfiles/?appid=108600
--]]

if not isClient() and isServer() then
	return
end

AVCS.trackVehicleCoordinateDateTime = AVCS.trackVehicleCoordinateDateTime or nil

function AVCS.checkClientGlobalDbExist()
	if not AVCS.dbByVehicleSQLID then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return false
	end

	if not AVCS.dbByPlayerID then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return false
	end

	return true
end

function AVCS.updateClientClaimVehicle(arg)
	if not AVCS.checkClientGlobalDbExist() then return end

	AVCS.dbByVehicleSQLID[arg.VehicleID] = {
		OwnerPlayerID = arg.OwnerPlayerID,
		ClaimDateTime = arg.ClaimDateTime,
		CarModel = arg.CarModel,
		LastLocationX = arg.LastLocationX,
		LastLocationY = arg.LastLocationY,
		LastLocationZ = arg.LastLocationZ,
		LastLocationUpdateDateTime = arg.LastLocationUpdateDateTime
	}

	if not AVCS.dbByPlayerID[arg.OwnerPlayerID] then
		AVCS.dbByPlayerID[arg.OwnerPlayerID] = {
			[arg.VehicleID] = true,
			LastKnownLogonTime = getTimestamp()
		}
	else
		AVCS.dbByPlayerID[arg.OwnerPlayerID][arg.VehicleID] = true
		AVCS.dbByPlayerID[arg.OwnerPlayerID].LastKnownLogonTime = getTimestamp()
	end
end

function AVCS.updateClientUnclaimVehicle(arg)
	if not AVCS.checkClientGlobalDbExist() then return end

	if AVCS.dbByVehicleSQLID[arg.VehicleID] and AVCS.dbByPlayerID[arg.OwnerPlayerID][arg.VehicleID] then
		AVCS.dbByVehicleSQLID[arg.VehicleID] = nil
		AVCS.dbByPlayerID[arg.OwnerPlayerID][arg.VehicleID] = nil
	else
		AVCS.forcesyncClientGlobalModData(nil)
	end
end

function AVCS.updateClientVehicleCoordinate(arg)
	if not AVCS.checkClientGlobalDbExist() then return end

	AVCS.updateVehicleCoordinate(arg)
end

function AVCS.updateClientLastLogon(arg)
	if not AVCS.checkClientGlobalDbExist() then return end

	if AVCS.dbByPlayerID[arg.PlayerID] then
		AVCS.dbByPlayerID[arg.PlayerID].LastKnownLogonTime = arg.LastKnownLogonTime
	else
		AVCS.forcesyncClientGlobalModData(nil)
	end
end

function AVCS.forcesyncClientGlobalModData(arg)
	ModData.request("AVCSByVehicleSQLID")
	ModData.request("AVCSByPlayerID")
end

function AVCS.updateClientSpecifyVehicleUserPermission(arg)
	if not AVCS.checkClientGlobalDbExist() then return end

	if AVCS.dbByVehicleSQLID[arg.VehicleID] then
		for k, v in pairs(arg) do
			if k ~= "VehicleID" then
				if v then
					AVCS.dbByVehicleSQLID[arg.VehicleID][k] = v
				else
					AVCS.dbByVehicleSQLID[arg.VehicleID][k] = nil
				end
			end
		end
	else
		AVCS.forcesyncClientGlobalModData(nil)
	end
end

-- B41 workaround, unused code incase B42 broken again
-- Vehicle ModData does not update immediately, workaround to force sync
function AVCS.registerClientVehicleSQLID(arg)
	local vehicleObj = getVehicleById(arg[1])
	if vehicleObj then
		vehicleObj:getModData().SQLID = arg[2]
	end
end

AVCS.OnServerCommand = function(moduleName, command, playerObj, args)
    if moduleName == "AVCS" then
        if AVCS[command] then
            AVCS[command](playerObj, args)
        end
    end
end

function AVCS.openClientUserManager()
	if AVCS.UI.UserInstance ~= nil then
		AVCS.UI.UserInstance:close()
	end

	local width = math.floor(650 * AVCS.getUIFontScale())
    local height = math.floor(350 * AVCS.getUIFontScale())

    local x = getCore():getScreenWidth() / 2 - (width / 2)
    local y = getCore():getScreenHeight() / 2 - (height / 2)

    AVCS.UI.UserInstance = AVCS.UI.UserManagerMain:new(x, y, width, height)
    AVCS.UI.UserInstance:initialise()
    AVCS.UI.UserInstance:addToUIManager()
    AVCS.UI.UserInstance:setVisible(true)
end

function AVCS.openClientAdminManager()
	if AVCS.UI.AdminInstance ~= nil then
		AVCS.UI.AdminInstance:close()
	end

	local width = math.floor(955 * AVCS.getUIFontScale())
    local height = math.floor(500 * AVCS.getUIFontScale())

    local x = getCore():getScreenWidth() / 2 - (width / 2)
    local y = getCore():getScreenHeight() / 2 - (height / 2)

    AVCS.UI.AdminInstance = AVCS.UI.AdminManagerMain:new(x, y, width, height)
    AVCS.UI.AdminInstance:initialise()
    AVCS.UI.AdminInstance:addToUIManager()
    AVCS.UI.AdminInstance:setVisible(true)
end

function AVCS.ClientOnPreFillWorldObjectContextMenu(player, context, worldObjects, test)
    context:addOption(getText("ContextMenu_AVCS_ClientUserUI"), worldObjects, AVCS.openClientUserManager, nil)

	if (not isClient() and not isServer()) or getPlayer():getRole():hasCapability(Capability.ManipulateVehicle) then
		local contextMenu = nil
		local subMenu = nil

		if #context.options > 0 then
			for i = 1, #context.options, 1 do
				local option = context.options[i];
				if option.name == "Admin [Mods]" then
					contextMenu = option
					subMenu = context:getSubMenu(contextMenu.subOption)
					break
				end
			end
		end

		if not contextMenu then
			contextMenu = context:addOption("Admin [Mods]", worldObjects, nil, nil)
			subMenu = ISContextMenu:getNew(context)
			context:addSubMenu(contextMenu, subMenu)
		end
		subMenu:addOption(getText("ContextMenu_AVCS_AdminUserUI"), worldObjects, AVCS.openClientAdminManager, nil)
	end
end

function AVCS.ClientOnReceiveGlobalModData(key, modData)
	if key == "AVCSByVehicleSQLID" then
		AVCS.dbByVehicleSQLID = modData
	end
	if key == "AVCSByPlayerID" then
		AVCS.dbByPlayerID = modData
	end
end

function AVCS.trackVehicleCoordinateTick()
    local player = getPlayer()
    if player:isDriving() and getTimestamp() - AVCS.trackVehicleCoordinateDateTime >= SandboxVars.AVCS.VehicleCoordinateUpdateThrottle then
        local vehicle = player:getVehicle()
        if vehicle then
			local vehicleID = AVCS.getVehicleID(vehicle)
            if vehicleID and AVCS.dbByVehicleSQLID and AVCS.dbByVehicleSQLID[vehicleID] then
                local tempArr = AVCS.getUpdateVehicleCoordinate(vehicle, vehicleID)
                if tempArr then
                    sendClientCommand(player, "AVCS", "updateServerVehicleCoordinate", tempArr)
                end
            end

            vehicle = vehicle:getVehicleTowing()
            vehicleID = AVCS.getVehicleID(vehicle)
            if vehicleID and AVCS.dbByVehicleSQLID and AVCS.dbByVehicleSQLID[vehicleID] then
                local tempArr = AVCS.getUpdateVehicleCoordinate(vehicle, vehicleID)
                if tempArr then
                    sendClientCommand(player, "AVCS", "updateServerVehicleCoordinate", tempArr)
                end
            end
        end
        AVCS.trackVehicleCoordinateDateTime = getTimestamp()
    end
end

function AVCS.ClientEveryHours()
	if AVCS.dbByPlayerID[getPlayer():getUsername()] ~= nil then
		sendClientCommand(getPlayer(), "AVCS", "updateLastKnownLogonTime", nil)
	end
end

function AVCS.AfterGameStart()
	ModData.request("AVCSByVehicleSQLID")
	ModData.request("AVCSByPlayerID")
	sendClientCommand(getPlayer(), "AVCS", "updateLastKnownLogonTime", nil)
	Events.OnServerCommand.Add(AVCS.OnServerCommand)
    AVCS.trackVehicleCoordinateDateTime = getTimestamp()
    Events.OnTick.Add(AVCS.trackVehicleCoordinateTick)
	Events.OnTick.Remove(AVCS.AfterGameStart)
end

Events.OnReceiveGlobalModData.Add(AVCS.ClientOnReceiveGlobalModData)
Events.OnTick.Add(AVCS.AfterGameStart)
Events.OnPreFillWorldObjectContextMenu.Add(AVCS.ClientOnPreFillWorldObjectContextMenu)
Events.EveryHours.Add(AVCS.ClientEveryHours)