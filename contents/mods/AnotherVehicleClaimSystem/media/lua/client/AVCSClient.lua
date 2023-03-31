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
	local tempDB = ModData.get("AVCSByVehicleSQLID")
	
	-- A desync has occurred, this shouldn't happen
	-- We will request full data from server
	if tempDB == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end

	tempDB[arg.VehicleID] = {
		OwnerPlayerID = arg.OwnerPlayerID,
		ClaimDateTime = arg.ClaimDateTime,
		CarModel = arg.CarModel,
		LastLocationX = arg.LastLocationX,
		LastLocationY = arg.LastLocationY,
		LastLocationUpdateDateTime = arg.LastLocationUpdateDateTime
	}
	-- Store the updated ModData --
	ModData.add("AVCSByVehicleSQLID", tempDB)
		
	tempDB = ModData.get("AVCSByPlayerID")
	if not tempDB[arg.OwnerPlayerID] then
		tempDB[arg.OwnerPlayerID] = {
			[arg.VehicleID] = true,
			LastKnownLogonTime = getTimestamp()
		}
	else
		tempDB[arg.OwnerPlayerID][arg.VehicleID] = true
		tempDB[arg.OwnerPlayerID].LastKnownLogonTime = getTimestamp()
	end
	
	-- Store the updated ModData --
	ModData.add("AVCSByPlayerID", tempDB)
end

function AVCS.updateClientUnclaimVehicle(arg)
	local tempDB = ModData.get("AVCSByVehicleSQLID")
	
	-- A desync has occurred, this shouldn't happen
	-- We will request full data from server
	if tempDB == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end
	
	if tempDB[arg.VehicleID] == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end
	
	tempDB[arg.VehicleID] = nil
		
	-- Store the updated ModData --
	ModData.add("AVCSByVehicleSQLID", tempDB)
		
	tempDB = ModData.get("AVCSByPlayerID")
	tempDB[arg.OwnerPlayerID][arg.VehicleID] = nil

	-- Store the updated ModData --
	ModData.add("AVCSByPlayerID", tempDB)
end

function AVCS.updateClientVehicleCoordinate(arg)
	local tempDB = ModData.get("AVCSByVehicleSQLID")

	-- A desync has occurred, this shouldn't happen
	-- We will request full data from server
	if tempDB == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end

	if tempDB[arg.VehicleID] == nil then
		ModData.request("AVCSByVehicleSQLID")
		ModData.request("AVCSByPlayerID")
		return
	end

	tempDB[arg.VehicleID].LastLocationX = arg.LastLocationX
	tempDB[arg.VehicleID].LastLocationY = arg.LastLocationY
	tempDB[arg.VehicleID].LastLocationUpdateDateTime = arg.LastLocationUpdateDateTime

	-- Store the updated ModData --
	ModData.add("AVCSByVehicleSQLID", tempDB)
end

-- Apparently getOnlinePlayers() only obtain nearby players and not all online players
-- Thus this function will not be utilized as I wanted to, I will just leave it here
function AVCS.updateClientLastKnownLogonTime()
	local onlinePlayers = getOnlinePlayers()
	local tempDB = ModData.get("AVCSByPlayerID")
	local tempCount = 0
	for i = 1, onlinePlayers:size() then
		if tempDB[onlinePlayers:get(i)] ~= nil then
			tempDB[onlinePlayers:get(i)].LastKnownLogonTime = getTimestamp()
			tempCount = tempCount + 1
		end
	end

	if tempCount ~= 0 then
		ModData.add("AVCSByPlayerID", tempDB)
	end
end

AVCS.OnServerCommand = function(moduleName, command, arg)
	if moduleName == "AVCS" and command == "updateClientClaimVehicle" then
		AVCS.updateClientClaimVehicle(arg)
	elseif moduleName == "AVCS" and command == "updateClientUnclaimVehicle" then
		AVCS.updateClientUnclaimVehicle(arg)
	elseif moduleName == "AVCS" and command == "updateClientVehicleCoordinate" then
		AVCS.updateClientVehicleCoordinate(arg)
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
		ModData.add("AVCSByVehicleSQLID", modData)
	end
	if key == "AVCSByPlayerID" then
		ModData.add("AVCSByPlayerID", modData)
	end
end

local function EveryTenMinutes()
	local tempDB = ModData.get("AVCSByPlayerID")
	if tempDB[getPlayer()] ~= nil then
		sendClientCommand(getPlayer(), "AVCS", "updateLastKnownLogonTime", nil)
	end
end

Events.EveryTenMinutes.Add(EveryTenMinutes)
Events.OnReceiveGlobalModData.Add(OnReceiveGlobalModData)
Events.OnConnected.Add(OnConnected)
Events.OnServerCommand.Add(AVCS.OnServerCommand)