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
		LastLocationY = arg.LastLocationY
	}
	-- Store the updated ModData --
	ModData.add("AVCSByVehicleSQLID", tempDB)
		
	tempDB = ModData.get("AVCSByPlayerID")
	if not tempDB[arg.OwnerPlayerID] then
		tempDB[arg.OwnerPlayerID] = {
			[arg.VehicleID] = true
		}
	else
		tempDB[arg.OwnerPlayerID][arg.VehicleID] = true
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

	-- Store the updated ModData --
	ModData.add("AVCSByVehicleSQLID", tempDB)
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
end

local function OnReceiveGlobalModData(key, modData)
	if key == "AVCSByVehicleSQLID" then
		ModData.add("AVCSByVehicleSQLID", modData)
	end
	if key == "AVCSByPlayerID" then
		ModData.add("AVCSByPlayerID", modData)
	end
end

Events.OnReceiveGlobalModData.Add(OnReceiveGlobalModData)
Events.OnConnected.Add(OnConnected)
Events.OnServerCommand.Add(AVCS.OnServerCommand)