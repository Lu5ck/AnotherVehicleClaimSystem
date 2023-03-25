--[[
	Some codes referenced from
	CarWanna - https://steamcommunity.com/workshop/filedetails/?id=2801264901
	Vehicle Recycling - https://steamcommunity.com/sharedfiles/filedetails/?id=2289429759
	K15's Mods - https://steamcommunity.com/id/KI5/myworkshopfiles/?appid=108600
--]]

-- Generic Functions that can be used by either client or server
AVCS = AVCS or {}

-- Ordered list of parts that cannot be removed by typical means
-- We will store server-side SQL ID in one of those
AVCS.muleParts = AVCS.muleParts or {
	"GloveBox",
	"TruckBed",
	"TruckBedOpen",
	"TrailerTrunk",
	"M101A3Trunk", -- K15 Vehicles
	"Engine"
}

-- Ingame debugger is unreliable but this does work
function AVCS.getMulePart(vehicleObj)
	local tempPart = false
	if vehicleObj then
		for i, v in ipairs(AVCS.muleParts) do
			tempPart = vehicleObj:getPartById(v)
			if tempPart then
				return tempPart
			end
		end
	end
	return tempPart
end

function AVCS.checkMaxClaim(playerObj)
	-- Privileged users has no limit
	if not string.lower(playerObj:getAccessLevel()) == "none" then
		return true
	end

	local tempDB = ModData.get("AVCSByPlayerID")
	if #tempDB[playerObj.getUsername()] >= SandboxVars.AVCS.MaxVehicle then
		return false
	else
		return true
	end
end

--[[
Was thinking if this should be a simple boolean function or more
Then, I wanted to show the owner name as tooltip in the context menu
So I decided to make it more...
--]]

function AVCS.checkPermission(playerObj, vehicleObj)
	local tempPart = AVCS.getMulePart(vehicleObj)
	local vehicleSQL = tempPart:getModData().SQLID
	local vehicleDB = ModData.get("AVCSByVehicleSQLID")

	-- Vehicle claiming not supported on this vehicle, likely a modded vehicle with non standard parts
	if tempPart == false or tempPart == nil then
		return false
	end

	-- If doesn't contain server-side SQL ID ModData,  it means yet to be imprinted therefore naturally unclaimed
	if vehicleSQL == nil then
		return true
	end

	-- Ownerless
	if vehicleDB[vehicleSQL] == nil then
		return true
	end
	
	-- Privileged users
	if not string.lower(playerObj:getAccessLevel()) == "none" then
		local details = {
			permissions = true,
			ownerid = vehicleDB[vehicleSQL].OwnerPlayerID
		}
		return details
	end

	-- Owner
	if vehicleDB[vehicleSQL].OwnerPlayerID == playerObj:getUsername() then
		local details = {
			permissions = true,
			ownerid = playerObj:getUsername()
		}
		return details
	end
	
	-- Faction Members
	if SandboxVars.AVCS.AllowFaction then
		local ownerObj = getPlayerByUserName(vehicleDB[vehicleSQL].OwnerPlayerID)
		if Faction.isAlreadyInFaction(ownerObj) then
			local factionObj = getPlayerFaction(ownerObj)
			local factionPlayers = factionObj.getPlayers()
			for i, v in ipairs(factionPlayers) do
				if v == playerObj:getUsername() then
					local details = {
						permissions = true,
						ownerid = vehicleDB[vehicleSQL].OwnerPlayerID
					}
					return details
				end
			end
		end
	end
	
	-- Safehouse Members
	if SandboxVars.AVCS.AllowSafehouse then
		local safehouseObj = alreadyHaveSafehouse(vehicleDB[vehicleSQL].OwnerPlayerID)
		if safehouseObj then
			for i, v in ipairs(safehouseObj.getPlayers()) do
				if v == playerObj:getUsername() then
					local details = {
						permissions = true,
						ownerid = vehicleDB[vehicleSQL].OwnerPlayerID
					}
					return details
				end
			end
		end
	end
	
	-- No permission
	local details = {
		permissions = false,
		ownerid = vehicleDB[vehicleSQL].OwnerPlayerID
	}
	return details
end