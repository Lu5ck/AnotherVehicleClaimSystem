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
Global variables that is accessed frequently
sortedPlayerTimeoutClaim is a table sorted in last known logon time timestamp and associoated player id
dbByVehicleSQLID store the ModData AVRByVehicleID
dbAVCSByPlayerID store the ModData AVRByPlayerID
--]]
AVCS.sortedPlayerTimeoutClaim = nil
AVCS.dbByVehicleSQLID = nil
AVCS.dbAVCSByPlayerID = nil

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
- <LastLocationUpdateDateTime>

ModData AVRByPlayerID is stored like this
<OwnerPlayerID>
- <LastKnownLogonTime>
- <Vehicle SQL ID 1>
- <Vehicle SQL ID 2>
and so on
--]]

function AVCS.claimVehicle(playerObj, vehicleID)
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
	if AVCS.dbByVehicleSQLID[vehicleObj:getSqlId()] then
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
		AVCS.dbByVehicleSQLID[vehicleObj:getSqlId()] = {
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
		ModData.add("AVCSByVehicleSQLID", AVCS.dbByVehicleSQLID)
		
		if not AVCS.dbAVCSByPlayerID[playerObj:getUsername()] then
			AVCS.dbAVCSByPlayerID[playerObj:getUsername()] = {
				[vehicleObj:getSqlId()] = true,
				LastKnownLogonTime = getTimestamp()
			}

			-- New player, insert it to the cache, theorically should be the latest entry
			AVCS.sortedPlayerTimeoutClaim[AVCS.dbAVCSByPlayerID[playerObj:getUsername()].LastKnownLogonTime] = {}
			table.insert(AVCS.sortedPlayerTimeoutClaim[AVCS.dbAVCSByPlayerID[playerObj:getUsername()].LastKnownLogonTime], playerObj:getUsername())
			
		else
			AVCS.dbAVCSByPlayerID[playerObj:getUsername()][vehicleObj:getSqlId()] = true
			AVCS.dbAVCSByPlayerID[playerObj:getUsername()][LastKnownLogonTime] = getTimestamp()
		end
		
		-- Store the updated ModData --
		ModData.add("AVCSByPlayerID", AVCS.dbAVCSByPlayerID)
		
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

-- vehicleID is SQL ID
function AVCS.unclaimVehicle(playerObj, vehicleID)
	if AVCS.dbByVehicleSQLID[vehicleID] then
		local ownerPlayerID = AVCS.dbByVehicleSQLID[vehicleID].OwnerPlayerID
		AVCS.dbByVehicleSQLID[vehicleID] = nil
		
		-- Store the updated ModData --
		ModData.add("AVCSByVehicleSQLID", AVCS.dbByVehicleSQLID)
		
		if AVCS.dbAVCSByPlayerID[ownerPlayerID][vehicleID] then
			AVCS.dbAVCSByPlayerID[ownerPlayerID][vehicleID] = nil
			AVCS.dbAVCSByPlayerID[ownerPlayerID][LastKnownLogonTime] = getTimestamp()
		end

		-- If the player has 0 vehicle, remove it completely
		local tempCount = 0
		for i, v in pairs(AVCS.dbAVCSByPlayerID[ownerPlayerID]) do
			tempCount = tempCount + 1
			if tempCount >= 2 then
				break
			end
		end
		
		if tempCount == 1 then
			AVCS.dbAVCSByPlayerID[ownerPlayerID] = nil
		end

		-- Store the updated ModData --
		ModData.add("AVCSByPlayerID", AVCS.dbAVCSByPlayerID)
		
		-- Careful the cap
		local tempArr = {
			VehicleID = vehicleID,
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

-- Update Player Logon Time
function AVCS.updateLastKnownLogonTime(playerObj)
	if AVCS.dbAVCSByPlayerID[playerObj:getUsername()] ~= nil then
		AVCS.dbAVCSByPlayerID[playerObj:getUsername()].LastKnownLogonTime = getTimestamp()
	end
	ModData.add("AVCSByPlayerID", AVCS.dbAVCSByPlayerID)
end

AVCS.onClientCommand = function(moduleName, command, playerObj, vehicleID)
	if moduleName == "AVCS" and command == "claimVehicle" then
		AVCS.claimVehicle(playerObj, vehicleID)
	elseif moduleName == "AVCS" and command == "unclaimVehicle" then
		-- Game send integer as array...
		-- So we do vehicleID[1] to get SQL ID
		if type(vehicleID[1]) ~= "number" then
			return
		end
		if SandboxVars.AVCS.ServerSideChecking then
			local checkResult = AVCS.checkPermission(playerObj, vehicleID[1])

			if type(checkResult) == "boolean" then
				if checkResult == false then
					-- Using vanilla logging function, write to a log with suffix AVCS
					-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
					-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
					writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to unclaim without permission [" .. playerObj:getUsername() .. "] [" .. AVCS.dbByVehicleSQLID[vehicleID[1]].CarModel .. "] [" .. AVCS.dbByVehicleSQLID[vehicleID[1]].LastLocationX .. "," .. AVCS.dbByVehicleSQLID[vehicleID[1]].LastLocationY .. "]")
					return
				end
			elseif checkResult.permissions == false then
				-- Using vanilla logging function, write to a log with suffix AVCS
				-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
				-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
				writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to unclaim without permission [" .. playerObj:getUsername() .. "] [" .. AVCS.dbByVehicleSQLID[vehicleID[1]].CarModel .. "] [" .. AVCS.dbByVehicleSQLID[vehicleID[1]].LastLocationX .. "," .. AVCS.dbByVehicleSQLID[vehicleID[1]].LastLocationY .. "]")
				return
			end
		end
		AVCS.unclaimVehicle(playerObj, vehicleID[1])
	elseif moduleName == "AVCS" and command == "updateLastKnownLogonTime" then
		AVCS.updateLastKnownLogonTime(playerObj)
	end
end

-- Remove given player ID from DBs completely
-- This hopefully thororughly remove the player from server-side Global ModData
-- We don't really need to care about client-side AVCSByPlayerID Global ModData as client will always get new fresh set onConnected
-- We do need to care about server-side as we don't want the AVCSByPlayerID to be bloated which will slow down other functions
function AVCS.removePlayerCompletely(playerID)
	if AVCS.dbAVCSByPlayerID[playerID] ~= nil then
		for k, v in pairs(AVCS.dbAVCSByPlayerID[playerID]) do
			if k ~= "LastKnownLogonTime" then
				AVCS.dbByVehicleSQLID[k] = nil
				local tempArr = {
					VehicleID = k,
					OwnerPlayerID = playerID
				}
				ModData.add("AVCSByVehicleSQLID", AVCS.dbByVehicleSQLID)
				sendServerCommand("AVCS", "updateClientUnclaimVehicle", tempArr)
			end
		end
		AVCS.dbAVCSByPlayerID[playerID] = nil
		ModData.add("AVCSByPlayerID", AVCS.dbAVCSByPlayerID)
	end
end

--[[
Transform dbAVCSByPlayerID into
[LastKnownLogonTime] = { PlayerID1, PlayerID2 }
--]]
local function createSortedPlayerTimeoutClaim()
	local temp = {}
	for _, v in pairs(AVCS.dbAVCSByPlayerID) do
		table.insert(temp, v)
	end
	table.sort(temp, function(a, b) return a.LastKnownLogonTime < b.LastKnownLogonTime end)

	AVCS.sortedPlayerTimeoutClaim = {}
	-- Group LastKnownLogonTime together
	-- Unlikely to have same LastKnownLogonTime but if it does, it will cause errors
	for _, v in ipairs(temp) do
		local playerID
		for i, k in pairs(AVCS.dbAVCSByPlayerID) do
			if k == v then
				playerID = i
				break
			end
		end
		if AVCS.sortedPlayerTimeoutClaim[v.LastKnownLogonTime] == nil then
			AVCS.sortedPlayerTimeoutClaim[v.LastKnownLogonTime] = {}
		end
		table.insert(AVCS.sortedPlayerTimeoutClaim[v.LastKnownLogonTime], playerID)
	end
end

function AVCS.doClaimTimeout()
	if AVCS.sortedPlayerTimeoutClaim ~= nil then
		local tempRebuild = false
		for varTime, v in pairs(AVCS.sortedPlayerTimeoutClaim) do
			-- If yet to expire
			if getTimestamp() - varTime < (SandboxVars.AVCS.ClaimTimeout * 60 * 60) then
				return
			end
			for _, k in ipairs(AVCS.sortedPlayerTimeoutClaim[varTime]) do
				if AVCS.dbAVCSByPlayerID[k] ~= nil then
					-- The sorted cache is not always updated, we simply perform final verification here
					if AVCS.dbAVCSByPlayerID[k].LastKnownLogonTime - varTime > (SandboxVars.AVCS.ClaimTimeout * 60 * 60) then
						AVCS.removePlayerCompletely(k)
					else
						-- Cache does not reflect current state, rebuild the cache again
						-- This shouldn't happen often and is faster to rebuild than to attempt to insert while keeping it sorted
						tempRebuild = true
					end
				end
			end
			AVCS.sortedPlayerTimeoutClaim[varTime] = nil
		end
		if tempRebuild == true then
			createSortedPlayerTimeoutClaim()
		end
	end
end

local function OnServerStarted()
	-- When Mod first added to server
	if not ModData.exists("AVCSByVehicleSQLID") then ModData.create("AVCSByVehicleSQLID") end
	if not ModData.exists("AVCSByPlayerID") then ModData.create("AVCSByPlayerID") end

	-- Set global variable as this is frequently accessed
	AVCS.dbByVehicleSQLID = ModData.get("AVCSByVehicleSQLID")
	AVCS.dbAVCSByPlayerID = ModData.get("AVCSByPlayerID")

	-- Create a sorted table
	if AVCS.sortedPlayerTimeoutClaim == nil then
		createSortedPlayerTimeoutClaim()
	end
end

Events.EveryTenMinutes.Add(AVCS.doClaimTimeout)
Events.OnServerStarted.Add(OnServerStarted)
Events.OnClientCommand.Add(AVCS.onClientCommand)