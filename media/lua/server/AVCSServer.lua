--[[
	Some codes referenced from
	CarWanna - https://steamcommunity.com/workshop/filedetails/?id=2801264901
	Vehicle Recycling - https://steamcommunity.com/sharedfiles/filedetails/?id=2289429759
	K15's Mods - https://steamcommunity.com/id/KI5/myworkshopfiles/?appid=108600
--]]

if isClient() and not isServer() then
	return
end
--[[
It is impossible to get real time coordinate of vehicles
Vehicle object is not readily obtainable and vehicle DB is not accessible via mod codes
Vehicles.LowerCondition is the only function that simply make sense
All vehicles will have conditions losses as you use it thus this will be called
--]]
if not AVCS.oLowerCondition then
    AVCS.oLowerCondition = Vehicles.LowerCondition
end

function Vehicles.LowerCondition(vehicle, part, elapsedMinutes)
	AVCS.oLowerCondition(vehicle, part, elapsedMinutes)
	AVCS.updateVehicleCoordinate(vehicle)
end

--[[
The global modData is basically the database for this vehicle claiming mod
This global moddata is actively shared with the clients
The clients will do most of the checking which help keep the server light

There are two ModData which is storing it by Vehicle SQL ID or Player ID
I have both because I want to minimize looping to perform differnt things

ModData AVRByVehicleID is stored like this
<Vehicle SQL ID>
- <OwnerPlayerID>
- <ClaimDateTime>
- <CarModel>
- <LastLocationX>
- <LastLocationY>

ModData AVRByPlayerID is stored like this
<OwnerPlayerID>
- <Vehicle SQL ID 1>
- <Vehicle SQL ID 2>
and so on
--]]

function AVCS.claimVehicle(playerObj, vehicleID)
	local tempDB = ModData.get("AVCSByVehicleSQLID")
	local vehicleObj = getVehicleById(vehicleID.vehicle)

	-- Assign Object ModData, workaround for SQL ID not being consistent for client-side and server-side
	-- As such, we imprint the server-side SQL ID onto the vehicle parts at this point of time
	-- Oddly, vehicle itself cannot hold ModData
	local tempPart = AVCS.getMulePart(vehicleObj)
	if tempPart == false or tempPart == nil then return end
	if tempPart:getModData().SQLID == nil then
		tempPart:getModData().SQLID = vehicleObj:getSqlId()

		-- Force sync, users will get fresh mod data as they load into the cell
		-- But we want users who already in cell to get this data as well
		vehicleObj:transmitPartModData(tempPart)
	end

	-- Make sure is not already claimed
	-- Only SQL ID is persistent, vehicleID is created on runtime
	if tempDB[vehicleObj:getSqlId()] then
		-- Using vanilla logging function, write to a log with suffix AVCS
		-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
		-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to claim already owned vehicle [Username] [Base.ExtremeCar] [13026,1215]
		if playerObj ~= nil then
			writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to claim already owned vehicle [" .. playerObj:getUsername() .. "] [" .. vehicleObj:getScript():getFullName() .. "] [" .. math.floor(vehicleObj:getX()) .. "," .. math.floor(vehicleObj:getY()) .. "]")
		end
		-- Desync has occurred, force sync everyone
		--ModData.transmit("AVCSByVehicleSQLID")
		--ModData.transmit("AVCSByPlayerID")
	else
		tempDB[vehicleObj:getSqlId()] = {
			OwnerPlayerID = playerObj:getUsername(),
			ClaimDateTime = getTimestamp(),
			CarModel = vehicleObj:getScript():getFullName(),
			LastLocationX = math.floor(vehicleObj:getX()),
			LastLocationY = math.floor(vehicleObj:getY()),
			LastLocationUpdateDateTime = getTimestamp()
		}
		
		-- Minimum data to send to clients
		local tempArr = {
			VehicleID = vehicleObj:getSqlId(),
			OwnerPlayerID = playerObj:getUsername(),
			ClaimDateTime = getTimestamp(),
			CarModel = vehicleObj:getScript():getFullName(),
			LastLocationX = math.floor(vehicleObj:getX()),
			LastLocationY = math.floor(vehicleObj:getY()),
			LastLocationUpdateDateTime = getTimestamp()
		}
		
		-- Store the updated ModData --
		ModData.add("AVCSByVehicleSQLID", tempDB)
		
		tempDB = ModData.get("AVCSByPlayerID")
		if not tempDB[playerObj:getUsername()] then
			tempDB[playerObj:getUsername()] = {
				[vehicleObj:getSqlId()] = true
			}
		else
			tempDB[playerObj:getUsername()][vehicleObj:getSqlId()] = true
		end
		
		-- Store the updated ModData --
		ModData.add("AVCSByPlayerID", tempDB)
		
		--[[ Send the updated ModData to all clients
		ModData.transmit("AVCSByVehicleSQLID")
		ModData.transmit("AVCSByPlayerID")
		You could transmit the entire Global ModData but that can become bandwidth expensive
		So, we will send the bare minimum instead. We hope this won't be desynced
		Clients will always obtain be latest global ModData onConnected
		--]] 
		sendServerCommand("AVCS", "updateClientClaimVehicle", tempArr)
	end
end

function AVCS.unclaimVehicle(playerObj, sqlId)





	local tempDB = ModData.get("AVCSByVehicleSQLID")
	--local vehicleObj = getVehicleById(vehicleID.vehicle)
	if tempDB[sqlId] then
		local ownerPlayerID = tempDB[sqlId].OwnerPlayerID
		tempDB[sqlId] = nil
		
		-- Store the updated ModData --
		ModData.add("AVCSByVehicleSQLID", tempDB)
		
		tempDB = ModData.get("AVCSByPlayerID")
		if tempDB[ownerPlayerID][sqlId] then
			tempDB[ownerPlayerID][sqlId] = nil
		end
		
		-- Store the updated ModData --
		ModData.add("AVCSByPlayerID", tempDB)
		
		local tempArr = {
			VehicleID = sqlId,
			OwnerPlayerID = ownerPlayerID
		}
		
		--[[ Send the updated ModData to all clients
		ModData.transmit("AVCSByVehicleSQLID")
		ModData.transmit("AVCSByPlayerID")
		You could transmit the entire Global ModData but that can become bandwidth expensive
		So, we will send the bare minimum instead. We hope this won't be desynced
		Clients will always obtain be latest global ModData onConnected
		--]]
		
		sendServerCommand("AVCS", "updateClientUnclaimVehicle", tempArr)
	else
		-- Desync has occurred, force sync everyone
		--ModData.transmit("AVCSByVehicleSQLID")
		--ModData.transmit("AVCSByPlayerID")
	end
end


function AVCS.findVehicle(playerObj, vehicleID)

	-- coordinates.

	--local cell = getWorld():getCell():getGridSquare(vehicleID.x, vehicleID.y, 0)

	print("Trying to get cell from server")
	local cell = getCell()
	print(cell)
	local gridSq = cell:getGridSquare(vehicleID.x, vehicleID.y, 0)


	local secondChell = gridSq:getCell()
	print(secondChell)



	--local vehicles = cell:getVehicles()

	-- local c = getCell()
	-- local g = c:getGridSquare(11707, 6704, 0)
	-- print(g)

	-- -- get sqlid from each vehicle until we find the one we need.

	-- for i = 0, #vehicles:size() - 1 do
	-- 	print(vehicles:get(i))
	-- end







end

AVCS.onClientCommand = function(moduleName, command, playerObj, vehicleID)
	if moduleName == "AVCS" and command == "claimVehicle" then
		AVCS.claimVehicle(playerObj, vehicleID)
	elseif moduleName == "AVCS" and command == "unclaimVehicle" then
		if SandboxVars.AVCS.ServerSideCheckUnclaim then

			-- TODO fix check permission, we can't fetch the vehicle from here like this in some cases
			local checkResult = AVCS.checkPermission(playerObj, getVehicleById(vehicleID.vehicle))
			if type(checkResult) == "boolean" then
				if checkResult == false then
					-- Using vanilla logging function, write to a log with suffix AVCS
					-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
					-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
					local vehicleObj = getVehicleById(vehicleID.vehicle)
					writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to unclaim without permission [" .. playerObj:getUsername() .. "] [" .. vehicleObj:getScript():getFullName() .. "] [" .. math.floor(vehicleObj:getX()) .. "," .. math.floor(vehicleObj:getY()) .. "]")
				end
			elseif checkResult.permissions == false then
				-- Using vanilla logging function, write to a log with suffix AVCS
				-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
				-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
				local vehicleObj = getVehicleById(vehicleID.vehicle)
				writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to unclaim without permission [" .. playerObj:getUsername() .. "] [" .. vehicleObj:getScript():getFullName() .. "] [" .. math.floor(vehicleObj:getX()) .. "," .. math.floor(vehicleObj:getY()) .. "]")
			end
		end



		AVCS.unclaimVehicle(playerObj, vehicleID.sqlId)
	end


end

local function OnServerStarted()
	-- When Mod first added to server
	if not ModData.exists("AVCSByVehicleSQLID") then ModData.create("AVCSByVehicleSQLID") end
	if not ModData.exists("AVCSByPlayerID") then ModData.create("AVCSByPlayerID") end
end

Events.OnServerStarted.Add(OnServerStarted)
Events.OnClientCommand.Add(AVCS.onClientCommand)