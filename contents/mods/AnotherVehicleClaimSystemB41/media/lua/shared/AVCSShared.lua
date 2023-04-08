--[[
	Some codes referenced from
	CarWanna - https://steamcommunity.com/workshop/filedetails/?id=2801264901
	Vehicle Recycling - https://steamcommunity.com/sharedfiles/filedetails/?id=2289429759
	K15's Mods - https://steamcommunity.com/id/KI5/myworkshopfiles/?appid=108600
--]]

-- Generic Functions that can be used by either client or server
AVCS = AVCS or {}
AVCS.UI = AVCS.UI or {}

-- Ordered list of parts that cannot be removed by typical means
-- We will store server-side SQL ID in one of those
--[[
AVCS.muleParts = AVCS.muleParts or {
	"GloveBox",
	"TruckBed",
	"TruckBedOpen",
	"TrailerTrunk",
	"M101A3Trunk", -- K15 Vehicles
	"Engine"
}
--]]
-- Ingame debugger is unreliable but this does work
function AVCS.getMulePart(vehicleObj)
	AVCS.matchTrunkPart("trunkdoor")
	local tempPart = false
	-- Split by ";"
	for s in string.gmatch(SandboxVars.AVCS.MuleParts, "([^;]+)") do
		-- Trim leading and trailing white spaces
		tempPart = vehicleObj:getPartById(s:match("^%s*(.-)%s*$"))
		if tempPart then
			return tempPart
		end
	end
	return tempPart
end

function AVCS.matchTrunkPart(strTrunk)
	if strTrunk == nil then
		return false
	end

	if type(strTrunk) == "string" and string.len(strTrunk) > 0 then
		for s in string.gmatch(SandboxVars.AVCS.TrunkParts, "([^;]+)") do
			if string.lower(s:match("^%s*(.-)%s*$")) == string.lower(strTrunk) then
				return true
			end
		end
	end
	return false
end

function AVCS.checkMaxClaim(playerObj)
	-- Privileged users has no limit
	if string.lower(playerObj:getAccessLevel()) ~= "none" then
		return true
	end

	local tempDB = ModData.get("AVCSByPlayerID")
	if tempDB[playerObj:getUsername()] == nil then return true end

	-- No easy way to get size other than count one by one, for key-value pair table
	local tempSize = 0
	for k, v in pairs(tempDB[playerObj:getUsername()]) do
		tempSize = tempSize + 1
	end

	if tempSize - 1 >= SandboxVars.AVCS.MaxVehicle then
		return false
	else
		return true
	end
end

--[[
Was thinking if this should be a simple boolean function or more
Then, I wanted to show the owner name as tooltip in the context menu
So I decided to make it more...

false = unsupported vehicle
true = unowned
table / array = owned and permission
--]]

function AVCS.checkPermission(playerObj, vehicleObj)
	local vehicleSQL = nil
	if type(vehicleObj) ~= "number" then
		local tempPart = AVCS.getMulePart(vehicleObj)

		-- Vehicle claiming not supported on this vehicle, likely a modded vehicle with non standard parts
		if tempPart == false or tempPart == nil then
			return false
		end

		vehicleSQL = tempPart:getModData().SQLID
	else
		vehicleSQL = vehicleObj
	end

	-- If doesn't contain server-side SQL ID ModData,  it means yet to be imprinted therefore naturally unclaimed
	if vehicleSQL == nil then
		return true
	end

	local vehicleDB = ModData.get("AVCSByVehicleSQLID")
	local playerDB = ModData.get("AVCSByPlayerID")

	-- Ownerless
	if vehicleDB[vehicleSQL] == nil then
		return true
	end
	
	-- Privileged users
	if string.lower(playerObj:getAccessLevel()) ~= "none" then
		local details = {
			permissions = true,
			ownerid = vehicleDB[vehicleSQL].OwnerPlayerID,
			LastKnownLogonTime = playerDB[vehicleDB[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
		}
		return details
	end

	-- Owner
	if vehicleDB[vehicleSQL].OwnerPlayerID == playerObj:getUsername() then
		local details = {
			permissions = true,
			ownerid = playerObj:getUsername(),
			LastKnownLogonTime = playerDB[playerObj:getUsername()].LastKnownLogonTime
		}
		return details
	end
	
	-- Faction Members
	if SandboxVars.AVCS.AllowFaction then
		local factionObj = Faction.getPlayerFaction(vehicleDB[vehicleSQL].OwnerPlayerID)
		if factionObj then
			if factionObj:getOwner() == playerObj:getUsername() then
				local details = {
					permissions = true,
					ownerid = vehicleDB[vehicleSQL].OwnerPlayerID,
					LastKnownLogonTime = playerDB[vehicleDB[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
				}
				return details
			end

			local tempPlayers = factionObj:getPlayers()
			for i = 0, tempPlayers:size() - 1 do
				if tempPlayers:get(i) == playerObj:getUsername() then
					local details = {
						permissions = true,
						ownerid = vehicleDB[vehicleSQL].OwnerPlayerID,
						LastKnownLogonTime = playerDB[vehicleDB[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
					}
					return details
				end
			end
		end
	end
	
	-- Safehouse Members
	if SandboxVars.AVCS.AllowSafehouse then
		local safehouseObj = SafeHouse.hasSafehouse(vehicleDB[vehicleSQL].OwnerPlayerID)
		if safehouseObj then
			local tempPlayers = safehouseObj:getPlayers()
			for i = 0, tempPlayers:size() - 1 do
				if tempPlayers:get(i) == playerObj:getUsername() then
					local details = {
						permissions = true,
						ownerid = vehicleDB[vehicleSQL].OwnerPlayerID,
						LastKnownLogonTime = playerDB[vehicleDB[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
					}
					return details
				end
			end
		end
	end
	
	-- No permission
	local details = {
		permissions = false,
		ownerid = vehicleDB[vehicleSQL].OwnerPlayerID,
		LastKnownLogonTime = playerDB[vehicleDB[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
	}
	return details
end

-- Simple function to convert detailed result of checkPermission into simple true or false
-- Mainly used by override functions to check basic access to vehicle
-- false which is to indicate unsupported vehicle is always returned as true in this case
function AVCS.getSimpleBooleanPermission(details)
	if type(details) == "boolean" then
		if details == false then
			details = true
		end
	end
	if type(details) ~= "boolean" then
		if details.permissions == true then
			return true
		else
			return false
		end
	end
	return details
end

function AVCS.updateVehicleCoordinate(vehicleObj)
	-- Server call, must be extreme efficient as this is called extreme frequently
	-- Do not use loop here
	if isServer() and not isClient() then
		local tempDB = ModData.get("AVCSByVehicleSQLID")
		if tempDB[vehicleObj:getSqlId()] ~= nil then
			if tempDB[vehicleObj:getSqlId()].LastLocationX ~= math.floor(vehicleObj:getX()) or tempDB[vehicleObj:getSqlId()].LastLocationY ~= math.floor(vehicleObj:getY()) then
				tempDB[vehicleObj:getSqlId()].LastLocationX = math.floor(vehicleObj:getX())
				tempDB[vehicleObj:getSqlId()].LastLocationY = math.floor(vehicleObj:getY())
				tempDB[vehicleObj:getSqlId()].LastLocationUpdateDateTime = getTimestamp()
				ModData.add("AVCSByVehicleSQLID", tempDB)
				local tempArr = {
					VehicleID = vehicleObj:getSqlId(),
					LastLocationX = math.floor(vehicleObj:getX()),
					LastLocationY = math.floor(vehicleObj:getY()),
					LastLocationUpdateDateTime = getTimestamp()
				}
				sendServerCommand("AVCS", "updateClientVehicleCoordinate", tempArr)
			end
		end
	-- Client call
	-- No plan to do client call as server seems sufficient for now
	else
	end
end