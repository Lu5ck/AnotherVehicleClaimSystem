--[[
	Some codes referenced from
	CarWanna - https://steamcommunity.com/workshop/filedetails/?id=2801264901
	Vehicle Recycling - https://steamcommunity.com/sharedfiles/filedetails/?id=2289429759
	K15's Mods - https://steamcommunity.com/id/KI5/myworkshopfiles/?appid=108600
]]--

if not isClient() and isServer() then
	return
end

require "ISUI/ISModalDialog"
require "luautils"

local function claimVehicle(player, button, vehicle)
    if button.internal == "NO" then return end
    if luautils.walkAdj(player, vehicle:getSquare()) then
        ISTimedActionQueue.add(ISAVCSVehicleClaimAction:new(player, vehicle))
    end
end

local function claimCfmDialog(player, vehicle)
    local message = string.format("Confirm", vehicle:getScript():getName())
    local playerNum = player:getPlayerNum()
    local modal = ISModalDialog:new((getCore():getScreenWidth() / 2) - (300 / 2), (getCore():getScreenHeight() / 2) - (150 / 2), 300, 150, message, true, player, claimVehicle, playerNum, vehicle)
    modal:initialise();
    modal:addToUIManager();
end

local function unclaimVehicle(player, button, vehicle)
    if button.internal == "NO" then return end
    if luautils.walkAdj(player, vehicle:getSquare()) then
        ISTimedActionQueue.add(ISAVCSVehicleUnclaimAction:new(player, vehicle))
    end
end

local function unclaimCfmDialog(player, vehicle)
    local message = string.format("Confirm", vehicle:getScript():getName())
    local playerNum = player:getPlayerNum()
    local modal = ISModalDialog:new((getCore():getScreenWidth() / 2) - (300 / 2), (getCore():getScreenHeight() / 2) - (150 / 2), 300, 150, message, true, player, unclaimVehicle, playerNum, vehicle)
    modal:initialise();
    modal:addToUIManager();
end

-- Copy and override the vanilla menu to add our context menu in
function AVCS.addOptionToMenuOutsideVehicle(player, context, vehicle)
	-- Ignore wrecks
	if string.match(string.lower(vehicle:getScript():getName()), "burnt") or string.match(string.lower(vehicle:getScript():getName()), "smashed") then
		return
	end

	local checkResult = AVCS.checkPermission(player, vehicle)
	local option
	local toolTip
	toolTip = ISToolTip:new()
	toolTip:initialise()
	toolTip:setVisible(false)

	if type(checkResult) == "boolean" then
		if checkResult == true then
			local playerInv = player:getInventory()
			-- Free car
			option = context:addOption(getText("ContextMenu_AVCS_ClaimVehicle"), player, claimCfmDialog, vehicle)
			option.toolTip = toolTip
			if playerInv:getItemCount("Base.AVCSClaimOrb") < 1 and SandboxVars.AVCS.RequireTicket then
				toolTip.description = getText("Tooltip_AVCS_Needs") .. " <LINE><RGB:1,0.2,0.2>" .. getItemNameFromFullType("Base.AVCSClaimOrb") .. " " .. playerInv:getItemCount("Base.AVCSClaimOrb") .. "/1"
				option.notAvailable = true
			else
				if AVCS.checkMaxClaim(player) then
					if SandboxVars.AVCS.RequireTicket then
						toolTip.description = getText("Tooltip_AVCS_Needs") .. " <LINE><RGB:0.2,1,0.2>" .. getItemNameFromFullType("Base.AVCSClaimOrb") .. " " .. playerInv:getItemCount("Base.AVCSClaimOrb") .. "/1"
					else
						toolTip.description = getText("Tooltip_AVCS_ClaimVehicle")
					end
					option.notAvailable = false
				else
					toolTip.description = "<RGB:0.2,1,0.2>" .. getText("Tooltip_AVCS_ExceedLimit")
					option.notAvailable = true
				end
			end
		elseif checkResult == false then
			-- Not supported vehicle
			option = context:addOption(getText("ContextMenu_AVCS_UnsupportedVehicle"), player, claimCfmDialog, vehicle)
			option.toolTip = toolTip
			toolTip.description = getText("Tooltip_AVCS_Unsupported")
			option.notAvailable = true
		end
	elseif checkResult.permissions == true then
		-- Owned car
		option = context:addOption(getText("ContextMenu_AVCS_UnclaimVehicle"), player, unclaimCfmDialog, vehicle)
		option.toolTip = toolTip
		toolTip.description = getText("Tooltip_AVCS_Owner") .. ": " .. checkResult.ownerid .. " <LINE>" .. getText("Tooltip_AVCS_Expire") .. ": " .. os.date("%d-%b-%y, %H:%M:%S", (checkResult.LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60)))
		option.notAvailable = false
	elseif checkResult.permissions == false then
		-- Owned car
		option = context:addOption(getText("ContextMenu_AVCS_UnclaimVehicle"), player, unclaimCfmDialog, vehicle)
		option.toolTip = toolTip
		toolTip.description = getText("Tooltip_AVCS_Owner") .. ": " .. checkResult.ownerid .. " <LINE>" .. getText("Tooltip_AVCS_Expire") .. ": " .. os.date("%d-%b-%y, %H:%M:%S", (checkResult.LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60)))
		option.notAvailable = true
	end

	-- Must not be towing or towed
	if vehicle:getVehicleTowedBy() ~= nil or vehicle:getVehicleTowing() ~= nil then
		toolTip.description = getText("Tooltip_AVCS_Towed")
		option.notAvailable = true
	end
end

if not AVCS.oMenuOutsideVehicle then
    AVCS.oMenuOutsideVehicle = ISVehicleMenu.FillMenuOutsideVehicle
end

function ISVehicleMenu.FillMenuOutsideVehicle(player, context, vehicle, test)
    AVCS.oMenuOutsideVehicle(player, context, vehicle, test)
    AVCS.addOptionToMenuOutsideVehicle(getSpecificPlayer(player), context, vehicle)
end

--[[
Overriding vanilla actions functions by copying the orginal functions then check permissions before calling the original
Avoid overriding isValid as that function is called on every validation which happen on every tick until action is completed
--]]

-- Copy and override the vanilla ISEnterVehicle to block unauthorized users
if not AVCS.oIsEnterVehicle then
    AVCS.oIsEnterVehicle = ISEnterVehicle.new
end

function ISEnterVehicle:new(character, vehicle, seat)
	-- For non-driver seats, driver seat is 0
    if seat ~= 0 then
		if AVCS.getPublicPermission(vehicle, "AllowPassenger") then
			return AVCS.oIsEnterVehicle(self, character, vehicle, seat)
		end
	end

	if seat == 0 then
		if AVCS.getPublicPermission(vehicle, "AllowDrive") then
			return AVCS.oIsEnterVehicle(self, character, vehicle, seat)
		end
	end
	
	local checkResult = AVCS.checkPermission(character, vehicle)
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oIsEnterVehicle(self, character, vehicle, seat)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISSwitchVehicleSeat to block unauthorized users
if not AVCS.oISSwitchVehicleSeat then
    AVCS.oISSwitchVehicleSeat = ISSwitchVehicleSeat.new
end

function ISSwitchVehicleSeat:new(character, seatTo)
	-- For non-driver seats, driver seat is 0
    if seatTo ~= 0 then
		if AVCS.getPublicPermission(character:getVehicle(), "AllowPassenger") then
			return AVCS.oISSwitchVehicleSeat(self, character, seatTo)
		end
	end

	if seatTo == 0 then
		if AVCS.getPublicPermission(character:getVehicle(), "AllowDrive") then
			return AVCS.oISSwitchVehicleSeat(self, character, seatTo)
		end
	end

	local checkResult = AVCS.checkPermission(character, character:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISSwitchVehicleSeat(self, character, seatTo)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISAttachTrailerToVehicle to block unauthorized users
if not AVCS.oISAttachTrailerToVehicle then
    AVCS.oISAttachTrailerToVehicle = ISAttachTrailerToVehicle.new
end

function ISAttachTrailerToVehicle:new(character, vehicleA, vehicleB, attachmentA, attachmentB)
	local checkResultA = AVCS.getPublicPermission(vehicleA, "AllowAttachVehicle")
	local checkResultB = AVCS.getPublicPermission(vehicleB, "AllowAttachVehicle")

	if checkResultA and checkResultB then
		return AVCS.oISAttachTrailerToVehicle(self, character, vehicleA, vehicleB, attachmentA, attachmentB)
	end

	checkResultA = AVCS.checkPermission(character, vehicleA)
	checkResultB = AVCS.checkPermission(character, vehicleB)
	checkResultA = AVCS.getSimpleBooleanPermission(checkResultA)
	checkResultB = AVCS.getSimpleBooleanPermission(checkResultB)

	if checkResultA and checkResultB then
		return AVCS.oISAttachTrailerToVehicle(self, character, vehicleA, vehicleB, attachmentA, attachmentB)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISDetachTrailerFromVehicle to block unauthorized users
if not AVCS.oISDetachTrailerFromVehicle then
    AVCS.oISDetachTrailerFromVehicle = ISDetachTrailerFromVehicle.new
end

function ISDetachTrailerFromVehicle:new(character, vehicle, attachment)
	local checkResult = AVCS.getPublicPermission(vehicle, "AllowDetechVehicle")

	if checkResult then
		return AVCS.oISDetachTrailerFromVehicle(self, character, vehicle, attachment)
	end

	checkResult = AVCS.checkPermission(character, vehicle)
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISDetachTrailerFromVehicle(self, character, vehicle, attachment)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISUninstallVehiclePart to block unauthorized users
if not AVCS.oISUninstallVehiclePart then
    AVCS.oISUninstallVehiclePart = ISUninstallVehiclePart.new
end

function ISUninstallVehiclePart:new(character, part, time)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowUninstallParts")

	if checkResult then
		return AVCS.oISUninstallVehiclePart(self, character, part, time)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISUninstallVehiclePart(self, character, part, time)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISTakeGasolineFromVehicle to block unauthorized users
if not AVCS.oISTakeGasolineFromVehicle then
    AVCS.oISTakeGasolineFromVehicle = ISTakeGasolineFromVehicle.new
end

function ISTakeGasolineFromVehicle:new(character, part, item, time)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowSiphonFuel")

	if checkResult then
		return AVCS.oISTakeGasolineFromVehicle(self, character, part, item, time)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISTakeGasolineFromVehicle(self, character, part, item, time)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISTakeEngineParts to block unauthorized users
if not AVCS.oISTakeEngineParts then
    AVCS.oISTakeEngineParts = ISTakeEngineParts.new
end

function ISTakeEngineParts:new(character, part, item, time)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowTakeEngineParts")

	if checkResult then
		return AVCS.oISTakeEngineParts(self, character, part, item, time)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISTakeEngineParts(self, character, part, item, time)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISDeflateTire to block unauthorized users
if not AVCS.oISInflateTire then
    AVCS.oISInflateTire = ISInflateTire.new
end

function ISInflateTire:new(character, part, item, psi, time)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowInflatTires")

	if checkResult then
		return AVCS.oISInflateTire(self, character, part, item, psi, time)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISInflateTire(self, character, part, item, psi, time)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISDeflateTire to block unauthorized users
if not AVCS.oISDeflateTire then
    AVCS.oISDeflateTire = ISDeflateTire.new
end

function ISDeflateTire:new(character, part, psi, time)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowDeflatTires")

	if checkResult then
		return AVCS.oISDeflateTire(self, character, part, psi, time)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISDeflateTire(self, character, part, psi, time)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISSmashVehicleWindow to block unauthorized users
if not AVCS.oISSmashVehicleWindow then
    AVCS.oISSmashVehicleWindow = ISSmashVehicleWindow.new
end

function ISSmashVehicleWindow:new(character, part, open)
	local checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISSmashVehicleWindow(self, character, part, open)
	else
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		local temp = {
			ignoreAction = true
		}
		return temp
	end
end

-- Copy and override the vanilla ISOpenVehicleDoor to block unauthorized users
if not AVCS.oISOpenVehicleDoor then
    AVCS.oISOpenVehicleDoor = ISOpenVehicleDoor.new
end

function ISOpenVehicleDoor:new(character, vehicle, partOrSeat)
	-- Exiting from seat
	if type(partOrSeat) == "number" then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, partOrSeat)
	end

	-- Opening from outside
	local tempID = string.lower(partOrSeat:getId())
	if not AVCS.matchTrunkPart(tempID) then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, partOrSeat)
	end

	local checkResult = AVCS.getPublicPermission(vehicle, "AllowOpeningTrunk")

	if checkResult then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, partOrSeat)
	end

	checkResult = AVCS.checkPermission(character, vehicle)
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, partOrSeat)
	end

	character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	local temp = {
		ignoreAction = true
	}
	return temp
end