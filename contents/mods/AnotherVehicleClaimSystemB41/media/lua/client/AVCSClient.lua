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

function AVCS.forcesyncClientGlobalModData(arg)
	if getPlayer():getUsername() == arg[1] then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
	end
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
		AVCS.forcesyncClientGlobalModData(arg)
	elseif moduleName == "AVCS" and command == "updateClientSpecifyVehicleUserPermission" then
		AVCS.updateClientSpecifyVehicleUserPermission(arg)
	end
end

local function openClientUserManager()
	if AVCS.UI.UserInstance ~= nil then
		AVCS.UI.UserInstance:close()
	end

	local width = 650
    local height = 350

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

	local width = 955
    local height = 500

    local x = getCore():getScreenWidth() / 2 - (width / 2)
    local y = getCore():getScreenHeight() / 2 - (height / 2)

    AVCS.UI.AdminInstance = AVCS.UI.AdminManagerMain:new(x, y, width, height)
    AVCS.UI.AdminInstance:initialise()
    AVCS.UI.AdminInstance:addToUIManager()
    AVCS.UI.AdminInstance:setVisible(true)
end

local function OnPreFillWorldObjectContextMenu(player, context, worldObjects, test)
    context:addOption(getText("ContextMenu_AVCS_ClientUserUI"), worldObjects, openClientUserManager, nil)
	if (string.lower(getPlayer():getAccessLevel()) ~= "none") or (not isClient() and not isServer()) then
		context:addOption(getText("ContextMenu_AVCS_AdminUserUI"), worldObjects, openClientAdminManager, nil)
	end
end

local function OnConnected()
	-- Get the latest Global ModData to work with
	ModData.request("AVCSByVehicleSQLID")
	ModData.request("AVCSByPlayerID")

	sendClientCommand(getPlayer(), "AVCS", "updateLastKnownLogonTime", nil)
end

local function OnReceiveGlobalModData(key, modData)
	if key == "AVCSByVehicleSQLID" then
		AVCS.dbByVehicleSQLID = modData
	end
	if key == "AVCSByPlayerID" then
		AVCS.dbByPlayerID = modData
	end
end

local function EveryHours()
	if AVCS.dbByPlayerID[getPlayer():getUsername()] ~= nil then
		sendClientCommand(getPlayer(), "AVCS", "updateLastKnownLogonTime", nil)
	end
end

Events.OnPreFillWorldObjectContextMenu.Add(OnPreFillWorldObjectContextMenu)
Events.EveryHours.Add(EveryHours)
Events.OnReceiveGlobalModData.Add(OnReceiveGlobalModData)
Events.OnConnected.Add(OnConnected)
Events.OnServerCommand.Add(AVCS.OnServerCommand)