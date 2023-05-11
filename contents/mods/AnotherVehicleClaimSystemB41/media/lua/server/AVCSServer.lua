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
--]]
AVCS.sortedPlayerTimeoutClaim = nil
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

-- Common functions
function AVCS.sortCacheNow()
	table.sort(AVCS.sortedPlayerTimeoutClaim, function(a, b) return a.ExpiryTime < b.ExpiryTime end)
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

-- vehicleID is vehicle object ID
function AVCS.claimVehicle(playerObj, vehicleID)
	local vehicleObj = getVehicleById(vehicleID.vehicle)

	-- Assign Object ModData, workaround for SQL ID not being consistent for client-side and server-side
	-- As such, we imprint the server-side SQL ID onto the vehicle parts at this point of time
	-- Oddly, vehicle itself cannot hold ModData
	local tempPart = AVCS.getMulePart(vehicleObj)
	if tempPart == false or tempPart == nil then return end
	if tempPart:getModData().SQLID == nil then
		tempPart:getModData().SQLID = tonumber(getTimestamp() .. vehicleObj:getSqlId())

		-- Force sync, users will get fresh mod data as they load into the cell
		-- But we want users who already in cell to get this data as well
		vehicleObj:transmitPartModData(tempPart)
	end

	vehicleID = tempPart:getModData().SQLID

	-- Make sure is not already claimed
	-- Only SQL ID is persistent, vehicleID is created on runtime
	if AVCS.dbByVehicleSQLID[vehicleID] then
		-- Using vanilla logging function, write to a log with suffix AVCS
		-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
		-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to claim already owned vehicle [Username] [Base.ExtremeCar] [13026,1215]
		if playerObj ~= nil then
			writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to claim already owned vehicle [" .. playerObj:getUsername() .. "] [" .. vehicleObj:getScript():getFullName() .. "] [" .. math.floor(vehicleObj:getX()) .. "," .. math.floor(vehicleObj:getY()) .. "]")
			sendServerCommand("AVCS", "forcesyncClientGlobalModData", { playerObj:getUsername() })
		end
	else
		AVCS.dbByVehicleSQLID[vehicleID] = {
			OwnerPlayerID = playerObj:getUsername(),
			ClaimDateTime = getTimestamp(),
			CarModel = vehicleObj:getScript():getFullName(),
			LastLocationX = math.floor(vehicleObj:getX()),
			LastLocationY = math.floor(vehicleObj:getY()),
			LastLocationUpdateDateTime = getTimestamp()
		}
		
		-- Minimum data to send to clients
		local tempArr = {
			VehicleID = vehicleID,
			OwnerPlayerID = playerObj:getUsername(),
			ClaimDateTime = getTimestamp(),
			CarModel = vehicleObj:getScript():getFullName(),
			LastLocationX = math.floor(vehicleObj:getX()),
			LastLocationY = math.floor(vehicleObj:getY()),
			LastLocationUpdateDateTime = getTimestamp()
		}
		
		-- Store the updated ModData --
		ModData.add("AVCSByVehicleSQLID", AVCS.dbByVehicleSQLID)
		
		if not AVCS.dbByPlayerID[playerObj:getUsername()] then
			AVCS.dbByPlayerID[playerObj:getUsername()] = {
				[vehicleID] = true,
				LastKnownLogonTime = getTimestamp()
			}

			-- New player, insert it to the cache, theorically should be the latest entry
			table.insert(AVCS.sortedPlayerTimeoutClaim, {ExpiryTime = (AVCS.dbByPlayerID[playerObj:getUsername()].LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60)), OwnerPlayerID = playerObj:getUsername()})
		else
			AVCS.dbByPlayerID[playerObj:getUsername()][vehicleID] = true
			AVCS.dbByPlayerID[playerObj:getUsername()].LastKnownLogonTime = getTimestamp()
		end
		
		-- Store the updated ModData --
		ModData.add("AVCSByPlayerID", AVCS.dbByPlayerID)
		
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
		
		if AVCS.dbByPlayerID[ownerPlayerID][vehicleID] then
			AVCS.dbByPlayerID[ownerPlayerID][vehicleID] = nil
		end

		-- If the player has 0 vehicle, remove it completely
		local tempCount = 0
		for k, v in pairs(AVCS.dbByPlayerID[ownerPlayerID]) do
			if k ~= "LastKnownLogonTime" then
				tempCount = tempCount + 1
			end
			if tempCount >= 1 then
				break
			end
		end
		
		if tempCount == 0 then
			AVCS.dbByPlayerID[ownerPlayerID] = nil
		end

		-- Store the updated ModData --
		ModData.add("AVCSByPlayerID", AVCS.dbByPlayerID)
		
		-- Case sensitive
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
		if playerObj ~= nil then
			sendServerCommand("AVCS", "forcesyncClientGlobalModData", { playerObj:getUsername() })
		end
	end
end

-- Update Player Logon Time
function AVCS.updateLastKnownLogonTime(playerObj)
	if AVCS.dbByPlayerID[playerObj:getUsername()] ~= nil then
		AVCS.dbByPlayerID[playerObj:getUsername()].LastKnownLogonTime = getTimestamp()

		local tempArr = {
			PlayerID = playerObj:getUsername(),
			LastKnownLogonTime = AVCS.dbByPlayerID[playerObj:getUsername()].LastKnownLogonTime,
		}
		sendServerCommand("AVCS", "updateClientLastLogon", tempArr)
		ModData.add("AVCSByPlayerID", AVCS.dbByPlayerID)
	end
end

function AVCS.updateSpecifyVehicleUserPermission(arg)

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
		ModData.add("AVCSByVehicleSQLID", AVCS.dbByVehicleSQLID)
		sendServerCommand("AVCS", "updateClientSpecifyVehicleUserPermission", arg)
	end
end

-- Database might become inconsistent with one another due to whatever reasons
-- Using AVCSByVehicleSQLID as base, we will rebuild the Database on server start
function AVCS.rebuildDB()
	local tempDB = {}
	for k, v in pairs(AVCS.dbByVehicleSQLID) do
		if not tempDB[v.OwnerPlayerID] then
			tempDB[v.OwnerPlayerID] = {}
		end

		tempDB[v.OwnerPlayerID][k] = true
		if AVCS.dbByPlayerID[v.OwnerPlayerID].LastKnownLogonTime then
			tempDB[v.OwnerPlayerID].LastKnownLogonTime = AVCS.dbByPlayerID[v.OwnerPlayerID].LastKnownLogonTime
		else
			tempDB[v.OwnerPlayerID].LastKnownLogonTime = getTimestamp()
		end
	end

	AVCS.dbByPlayerID = tempDB
	ModData.add("AVCSByPlayerID", AVCS.dbByPlayerID)
end

AVCS.onClientCommand = function(moduleName, command, playerObj, arg)
	if moduleName == "AVCS" and command == "claimVehicle" then
		AVCS.claimVehicle(playerObj, arg)
	elseif moduleName == "AVCS" and command == "unclaimVehicle" then
		-- Game send everything as table...
		-- So we do arg[1] to get SQL ID
		if SandboxVars.AVCS.ServerSideChecking then
			local checkResult = AVCS.checkPermission(playerObj, arg[1])

			if type(checkResult) == "boolean" then
				if checkResult == false then
					-- Using vanilla logging function, write to a log with suffix AVCS
					-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
					-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
					writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to unclaim without permission [" .. playerObj:getUsername() .. "] [" .. AVCS.dbByVehicleSQLID[arg[1]].CarModel .. "] [" .. AVCS.dbByVehicleSQLID[arg[1]].LastLocationX .. "," .. AVCS.dbByVehicleSQLID[arg[1]].LastLocationY .. "]")

					-- Possible desync has occurred, force sync the user
					sendServerCommand("AVCS", "forcesyncClientGlobalModData", { playerObj:getUsername() })
					return
				end
			elseif checkResult.permissions == false then
				-- Using vanilla logging function, write to a log with suffix AVCS
				-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
				-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
				writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to unclaim without permission [" .. playerObj:getUsername() .. "] [" .. AVCS.dbByVehicleSQLID[arg[1]].CarModel .. "] [" .. AVCS.dbByVehicleSQLID[arg[1]].LastLocationX .. "," .. AVCS.dbByVehicleSQLID[arg[1]].LastLocationY .. "]")

				-- Possible desync has occurred, force sync the user
				sendServerCommand("AVCS", "forcesyncClientGlobalModData", { playerObj:getUsername() })
				return
			end
		end
		AVCS.unclaimVehicle(playerObj, arg[1])
	elseif moduleName == "AVCS" and command == "updateLastKnownLogonTime" then
		AVCS.updateLastKnownLogonTime(playerObj)
	elseif moduleName == "AVCS" and command == "updateSpecifyVehicleUserPermission" then
		-- arg should be table of a lot of things
		-- VehicleID
		-- Permission types like AllowDrive, AllowPassenger
		if SandboxVars.AVCS.ServerSideChecking then
			local checkResult = AVCS.checkPermission(playerObj, arg.VehicleID)

			if type(checkResult) == "boolean" then
				if checkResult == false then
					-- Using vanilla logging function, write to a log with suffix AVCS
					-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
					-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
					writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to modify specific vehicle permissions without permission [" .. playerObj:getUsername() .. "] [" .. AVCS.dbByVehicleSQLID[arg.VehicleID].CarModel .. "]")

					-- Possible desync has occurred, force sync the user
					sendServerCommand("AVCS", "forcesyncClientGlobalModData", { playerObj:getUsername() })
					return
				end
			elseif checkResult.permissions == false then
				-- Using vanilla logging function, write to a log with suffix AVCS
				-- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
				-- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
				writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to modify specific vehicle permissions without permission [" .. playerObj:getUsername() .. "] [" .. AVCS.dbByVehicleSQLID[arg.VehicleID].CarModel .. "]")

				-- Possible desync has occurred, force sync the user
				sendServerCommand("AVCS", "forcesyncClientGlobalModData", { playerObj:getUsername() })
				return
			end
		end
		AVCS.updateSpecifyVehicleUserPermission(arg)
	elseif moduleName == "AVCS" and command == "rebuildDB" then
		if playerObj:getAccessLevel() == "admin" then
			AVCS.rebuildDB()
		end
	end
end

-- Remove given player ID from DBs completely
-- This hopefully thororughly remove the player from server-side Global ModData
-- We don't really need to care about client-side AVCSByPlayerID Global ModData as client will always get new fresh set onConnected
-- We do need to care about server-side as we don't want the AVCSByPlayerID to be bloated which will slow down other functions
function AVCS.removePlayerCompletely(playerID)
	if AVCS.dbByPlayerID[playerID] ~= nil then
		for k, v in pairs(AVCS.dbByPlayerID[playerID]) do
			if k ~= "LastKnownLogonTime" then
				AVCS.unclaimVehicle(nil, k)
			end
		end
	end
end

--[[
Transform dbAVCSByPlayerID into array of {LastKnownLogonTime, OwnerPlayerID}
--]]
local function createSortedPlayerTimeoutClaim()
	local temp = {}
	for k, v in pairs(AVCS.dbByPlayerID) do
		table.insert(temp, {ExpiryTime = (v.LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60)), OwnerPlayerID = k})
	end

	AVCS.sortedPlayerTimeoutClaim = temp
	AVCS.sortCacheNow()
end

function AVCS.doClaimTimeout()
	local varIndex = 1
	local needSort = false
	-- As we dealing with indexes, we want to control the index value as we increment to avoid removing wrong index
	while varIndex <= #AVCS.sortedPlayerTimeoutClaim do
		if getTimestamp() > AVCS.sortedPlayerTimeoutClaim[varIndex].ExpiryTime then
			if AVCS.dbByPlayerID[AVCS.sortedPlayerTimeoutClaim[varIndex].OwnerPlayerID] ~= nil then
				-- Cache is not always up-to-date, validate the actual
				if getTimestamp() > (AVCS.dbByPlayerID[AVCS.sortedPlayerTimeoutClaim[varIndex].OwnerPlayerID].LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60)) then
					AVCS.removePlayerCompletely(AVCS.sortedPlayerTimeoutClaim[varIndex].OwnerPlayerID)
					table.remove(AVCS.sortedPlayerTimeoutClaim, varIndex)
				else
					-- Update the expiry time
					AVCS.sortedPlayerTimeoutClaim[varIndex].ExpiryTime = (AVCS.dbByPlayerID[AVCS.sortedPlayerTimeoutClaim[varIndex].OwnerPlayerID].LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60))
					needSort = true
					varIndex = varIndex + 1
				end
			else
				-- User no longer exist, remove from index
				table.remove(AVCS.sortedPlayerTimeoutClaim, varIndex)
			end
		else
			-- Since sorted, assume everybody else has not expired
			break
		end
	end

	if needSort then
		AVCS.sortCacheNow()
	end
end

local function OnInitGlobalModData(isNewGame)
	-- When Mod first added to server
	if not ModData.exists("AVCSByVehicleSQLID") then ModData.create("AVCSByVehicleSQLID") end
	if not ModData.exists("AVCSByPlayerID") then ModData.create("AVCSByPlayerID") end

	-- Set global variable as this is frequently accessed
	AVCS.dbByVehicleSQLID = ModData.get("AVCSByVehicleSQLID")
	AVCS.dbByPlayerID = ModData.get("AVCSByPlayerID")

	if SandboxVars.AVCS.RebuildDB then
		AVCS.rebuildDB()
	end

	createSortedPlayerTimeoutClaim()
end

Events.OnInitGlobalModData.Add(OnInitGlobalModData)
Events.EveryTenMinutes.Add(AVCS.doClaimTimeout)
Events.OnClientCommand.Add(AVCS.onClientCommand)