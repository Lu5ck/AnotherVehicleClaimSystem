--[[
	Some codes referenced from
	CarWanna - https://steamcommunity.com/workshop/filedetails/?id=2801264901
	Vehicle Recycling - https://steamcommunity.com/sharedfiles/filedetails/?id=2289429759
	K15's Mods - https://steamcommunity.com/id/KI5/myworkshopfiles/?appid=108600
--]]

-- Generic Functions that can be used by either client or server
AVCS = AVCS or {}
AVCS.UI = AVCS.UI or {}

--[[
Global variables that is accessed frequently
Both client-side and server-side have this same name variables
Important to initialise these variables accordingly in both side
dbByVehicleSQLID store the ModData AVRByVehicleID
dbAVCSByPlayerID store the ModData AVRByPlayerID
]]
AVCS.dbByVehicleSQLID = nil
AVCS.dbByPlayerID = nil

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

function AVCS.getVehicleID(vehicleObj)
    if not vehicleObj then return nil end

    local vehicleID = vehicleObj:getModData().SQLID
    if vehicleID then
        return vehicleID
    elseif isServer() or (not isServer() and not isClient()) then
        vehicleID = tonumber(getTimestamp() .. vehicleObj:getSqlId())
        vehicleObj:getModData().SQLID = vehicleID
        vehicleObj:transmitModData()
		--sendServerCommand("AVCS", "registerClientVehicleSQLID", {vehicleObj:getId(), vehicleObj:getModData().SQLID})
        return vehicleID
    end

    return nil
end

function AVCS.checkMaxClaim(playerObj)
	if (not isClient() and not isServer()) or playerObj:getRole():hasCapability(Capability.ManipulateVehicle) then
		return true
	end

	if AVCS.dbByPlayerID[playerObj:getUsername()] == nil then return true end

	-- No easy way to get size other than count one by one, for key-value pair table
	local tempSize = 0
	for k, v in pairs(AVCS.dbByPlayerID[playerObj:getUsername()]) do
		tempSize = tempSize + 1
	end

	if tempSize - 1 >= SandboxVars.AVCS.MaxVehicle then
		return false
	else
		return true
	end
end

function AVCS.getPublicPermission(vehicleObj, type)
	local vehicleSQL = AVCS.getVehicleID(vehicleObj)
	if vehicleSQL then
		if AVCS.dbByVehicleSQLID and AVCS.dbByVehicleSQLID[vehicleSQL] then
			if AVCS.dbByVehicleSQLID[vehicleSQL][type] then
				return AVCS.dbByVehicleSQLID[vehicleSQL][type]
			else
				return false
			end
		else
			return true
		end
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
		vehicleSQL = AVCS.getVehicleID(vehicleObj)
	else
		vehicleSQL = vehicleObj
	end

	-- If doesn't contain server-side SQL ID ModData,  it means yet to be imprinted therefore naturally unclaimed
	if vehicleSQL == nil then
		return true
	end

	-- Ownerless
	if AVCS.dbByVehicleSQLID[vehicleSQL] == nil then
		return true
	end

	if (not isClient() and not isServer()) or playerObj:getRole():hasCapability(Capability.ManipulateVehicle) then
		local details = {
			permissions = true,
			ownerid = AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID,
			LastKnownLogonTime = AVCS.dbByPlayerID[AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
		}
		return details
	end

	-- Owner
	if AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID == playerObj:getUsername() then
		local details = {
			permissions = true,
			ownerid = playerObj:getUsername(),
			LastKnownLogonTime = AVCS.dbByPlayerID[playerObj:getUsername()].LastKnownLogonTime
		}
		return details
	end
	
	-- Faction Members
	if SandboxVars.AVCS.AllowFaction then
		local factionObj = Faction.getPlayerFaction(AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID)
		if factionObj then
			if factionObj:getOwner() == playerObj:getUsername() then
				local details = {
					permissions = true,
					ownerid = AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID,
					LastKnownLogonTime = AVCS.dbByPlayerID[AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
				}
				return details
			end

			local tempPlayers = factionObj:getPlayers()
			for i = 0, tempPlayers:size() - 1 do
				if tempPlayers:get(i) == playerObj:getUsername() then
					local details = {
						permissions = true,
						ownerid = AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID,
						LastKnownLogonTime = AVCS.dbByPlayerID[AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
					}
					return details
				end
			end
		end
	end
	
	-- Safehouse Members
	if SandboxVars.AVCS.AllowSafehouse then
		local safehouseObj = SafeHouse.hasSafehouse(AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID)
		if safehouseObj then
			local tempPlayers = safehouseObj:getPlayers()
			for i = 0, tempPlayers:size() - 1 do
				if tempPlayers:get(i) == playerObj:getUsername() then
					local details = {
						permissions = true,
						ownerid = AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID,
						LastKnownLogonTime = AVCS.dbByPlayerID[AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
					}
					return details
				end
			end
		end
	end
	
	-- No permission
	local details = {
		permissions = false,
		ownerid = AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID,
		LastKnownLogonTime = AVCS.dbByPlayerID[AVCS.dbByVehicleSQLID[vehicleSQL].OwnerPlayerID].LastKnownLogonTime
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

function AVCS.getUpdateVehicleCoordinate(vehicle, vehicleID)
    local curX = math.floor(vehicle:getX())
    local curY = math.floor(vehicle:getY())
    local curZ = math.floor(vehicle:getZ())

	if not vehicleID then
		vehicleID = AVCS.getVehicleID(vehicle)
	end
    if AVCS.dbByVehicleSQLID[vehicleID].LastLocationX ~= curX or AVCS.dbByVehicleSQLID[vehicleID].LastLocationY ~= curY or AVCS.dbByVehicleSQLID[vehicleID].LastLocationZ ~= curZ then
        AVCS.dbByVehicleSQLID[vehicleID].LastLocationX = curX
        AVCS.dbByVehicleSQLID[vehicleID].LastLocationY = curY
        AVCS.dbByVehicleSQLID[vehicleID].LastLocationZ = curZ
        AVCS.dbByVehicleSQLID[vehicleID].LastLocationUpdateDateTime = getTimestamp()

        local tempArr = {
            VehicleID = vehicleID,
            LastLocationX = curX,
            LastLocationY = curY,
            LastLocationZ = curZ,
            LastLocationUpdateDateTime = AVCS.dbByVehicleSQLID[vehicleID].LastLocationUpdateDateTime
        }
        return tempArr
    end
    return nil
end

function AVCS.updateVehicleCoordinate(args)
	if not args and not args.VehicleID and not args.LastLocationX and not args.LastLocationY and not args.LastLocationZ and not args.LastLocationUpdateDateTime then return end
    if AVCS.dbByVehicleSQLID[args.VehicleID] then
        AVCS.dbByVehicleSQLID[args.VehicleID].LastLocationX = args.LastLocationX
        AVCS.dbByVehicleSQLID[args.VehicleID].LastLocationY = args.LastLocationY
        AVCS.dbByVehicleSQLID[args.VehicleID].LastLocationZ = args.LastLocationZ
        AVCS.dbByVehicleSQLID[args.VehicleID].LastLocationUpdateDateTime = args.LastLocationUpdateDateTime

        -- Exclude client, includes server / sp / self host
        if not (isClient() and not isServer()) then
            ModData.add("AVCSByVehicleSQLID", AVCS.dbByVehicleSQLID)
        end
    end
end

function AVCS.getUIFontScale()
	-- Size 1 is 100% aka default
	-- Size 2 is 125% aka 1x
	-- Size 3 is 150% aka 2x
	-- Size 4 is 175% aka 3x
	-- Size 5 is 200% aka 4x
	return 1 + (getCore():getOptionFontSize() - 1) / 4
end