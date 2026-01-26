--[[
	Some codes referenced from
	CarWanna - https://steamcommunity.com/workshop/filedetails/?id=2801264901
	Vehicle Recycling - https://steamcommunity.com/sharedfiles/filedetails/?id=2289429759
	K15's Mods - https://steamcommunity.com/id/KI5/myworkshopfiles/?appid=108600
--]]

if not isClient() and isServer() then
	return
end

function AVCS.updateClientClaimVehicle(arg)
	-- A desync has occurred, this shouldn't happen
	-- We will request full data from server
	if AVCS.dbByVehicleSQLID == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end

	AVCS.dbByVehicleSQLID[arg.VehicleID] = {
		OwnerPlayerID = arg.OwnerPlayerID,
		ClaimDateTime = arg.ClaimDateTime,
		CarModel = arg.CarModel,
		LastLocationX = arg.LastLocationX,
		LastLocationY = arg.LastLocationY,
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
	-- A desync has occurred, this shouldn't happen
	-- We will request full data from server
	if AVCS.dbByVehicleSQLID == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end
	
	if AVCS.dbByVehicleSQLID[arg.VehicleID] == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end
	
	AVCS.dbByVehicleSQLID[arg.VehicleID] = nil
	AVCS.dbByPlayerID[arg.OwnerPlayerID][arg.VehicleID] = nil
end

function AVCS.updateClientVehicleCoordinate(arg)
	-- A desync has occurred, this shouldn't happen
	-- We will request full data from server
	if AVCS.dbByVehicleSQLID == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end

	if AVCS.dbByVehicleSQLID[arg.VehicleID] == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end

	AVCS.dbByVehicleSQLID[arg.VehicleID].LastLocationX = arg.LastLocationX
	AVCS.dbByVehicleSQLID[arg.VehicleID].LastLocationY = arg.LastLocationY
	AVCS.dbByVehicleSQLID[arg.VehicleID].LastLocationUpdateDateTime = arg.LastLocationUpdateDateTime
end

function AVCS.updateClientLastLogon(arg)
	if AVCS.dbByPlayerID == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end

	if AVCS.dbByPlayerID[arg.PlayerID] == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end

	AVCS.dbByPlayerID[arg.PlayerID].LastKnownLogonTime = arg.LastKnownLogonTime
end

function AVCS.forcesyncClientGlobalModData()
	ModData.request("AVCSByVehicleSQLID")
	ModData.request("AVCSByPlayerID")
end

function AVCS.updateClientSpecifyVehicleUserPermission(arg)
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
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
	end
end

-- Vehicle ModData does not update immediately, workaround to force sync
function AVCS.registerClientVehicleSQLID(arg)
	local vehicleObj = getVehicleById(arg[1])
	if vehicleObj then
		vehicleObj:getModData().SQLID = arg[2]
	end
end

AVCS.OnServerCommand = function(moduleName, command, arg)
	if moduleName == "AVCS" and command == "updateClientClaimVehicle" then
		AVCS.updateClientClaimVehicle(arg)
	elseif moduleName == "AVCS" and command == "updateClientUnclaimVehicle" then
		AVCS.updateClientUnclaimVehicle(arg)
	elseif moduleName == "AVCS" and command == "updateClientVehicleCoordinate" then
		AVCS.updateClientVehicleCoordinate(arg)
	elseif moduleName == "AVCS" and command == "updateClientLastLogon" then
		AVCS.updateClientLastLogon(arg)
	elseif moduleName == "AVCS" and command == "forcesyncClientGlobalModData" then
		AVCS.forcesyncClientGlobalModData()
	elseif moduleName == "AVCS" and command == "updateClientSpecifyVehicleUserPermission" then
		AVCS.updateClientSpecifyVehicleUserPermission(arg)
	elseif moduleName == "AVCS" and command == "registerClientVehicleSQLID" then
		AVCS.registerClientVehicleSQLID(arg)
	end
end

local function openClientUserManager()
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

local function openClientAdminManager()
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
    context:addOption(getText("ContextMenu_AVCS_ClientUserUI"), worldObjects, openClientUserManager, nil)
	local avcs_tempAccess = string.lower(getPlayer():getAccessLevel())
	if (avcs_tempAccess == "gm") or (avcs_tempAccess == "moderator") or (avcs_tempAccess == "admin") or (not isClient() and not isServer()) then
		context:addOption(getText("ContextMenu_AVCS_AdminUserUI"), worldObjects, openClientAdminManager, nil)
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
	Events.OnTick.Remove(AVCS.AfterGameStart)
end

Events.OnReceiveGlobalModData.Add(AVCS.ClientOnReceiveGlobalModData)
Events.OnTick.Add(AVCS.AfterGameStart)
Events.OnPreFillWorldObjectContextMenu.Add(AVCS.ClientOnPreFillWorldObjectContextMenu)
Events.EveryHours.Add(AVCS.ClientEveryHours)