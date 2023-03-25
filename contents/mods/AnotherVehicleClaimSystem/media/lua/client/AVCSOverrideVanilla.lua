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
        ISTimedActionQueue.add(isAVCSVehicleClaimAction:new(player, vehicle))
    end
end

local function claimCfmDialog(player, vehicle)
    local message = string.format("Confirm", vehicle:getScript():getName())
    local playerNum = player:getPlayerNum()
    local modal = ISModalDialog:new(0, 0, 300, 150, message, true, player, claimVehicle, playerNum, vehicle)
    modal:initialise();
    modal:addToUIManager();
end

local function unclaimVehicle(player, button, vehicle)
    if button.internal == "NO" then return end
    if luautils.walkAdj(player, vehicle:getSquare()) then
        ISTimedActionQueue.add(isAVCSVehicleUnclaimAction:new(player, vehicle))
    end
end

local function unclaimCfmDialog(player, vehicle)
    local message = string.format("Confirm", vehicle:getScript():getName())
    local playerNum = player:getPlayerNum()
    local modal = ISModalDialog:new(0, 0, 300, 150, message, true, player, unclaimVehicle, playerNum, vehicle)
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
	if type(checkResult) == "boolean" then
		if checkResult == true then
			-- Free car
			option = context:addOption(getText("ContextMenu_AVCS_ClaimVehicle"), player, claimCfmDialog, vehicle)
			toolTip = ISToolTip:new()
			toolTip:initialise()
			toolTip:setVisible(false)
			option.toolTip = toolTip
			option.notAvailable = false
			
			--if not player:getInventory():containsTypeRecurse("AVCSClaimForm") then
			--	option.notAvailable = true
			--end
		elseif checkResult == false then
			-- Not supported vehicle
			option = context:addOption(getText("ContextMenu_AVCS_ClaimVehicle"), player, claimCfmDialog, vehicle)
			toolTip = ISToolTip:new()
			toolTip:initialise()
			toolTip:setVisible(false)
			option.toolTip = toolTip
			option.notAvailable = true
		end
	elseif checkResult.permissions == true then
		-- Owned car
		option = context:addOption(getText("ContextMenu_AVCS_UnclaimVehicle"), player, unclaimCfmDialog, vehicle)
		toolTip = ISToolTip:new()
		toolTip:initialise()
		toolTip:setVisible(false)
		option.toolTip = toolTip
		option.notAvailable = false
	elseif checkResult.permissions == false then
		-- Owned car
		option = context:addOption(getText("ContextMenu_AVCS_UnclaimVehicle"), player, unclaimCfmDialog, vehicle)
		toolTip = ISToolTip:new()
		toolTip:initialise()
		toolTip:setVisible(false)
		option.toolTip = toolTip
		option.notAvailable = true
	end

	-- Must not be towing or towed
	if vehicle:getVehicleTowedBy() ~= nil or vehicle:getVehicleTowing() ~= nil then
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

-- Copy and override the vanilla ISEnterVehicle to block unauthorized users
if not AVCS.oIsEnterVehicle then
    AVCS.oIsEnterVehicle = ISEnterVehicle.isValid
end

function ISEnterVehicle:isValid()
	-- 0 is driver seat, I think
	-- We only care about driver seat
    if self.seat ~= 0 then
		return AVCS.oIsEnterVehicle(self)
	else
		local checkResult = AVCS.checkPermission(self.character, self.vehicle)
		if type(checkResult) == "boolean" then
			if checkResult == true then
				return AVCS.oIsEnterVehicle(self)
			end
		elseif checkResult.permissions == true then
			return AVCS.oIsEnterVehicle(self)
		end
	end

	self.character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	return false
end

-- Copy and override the vanilla ISSwitchVehicleSeat to block unauthorized users
if not AVCS.oISSwitchVehicleSeat then
    AVCS.oISSwitchVehicleSeat = ISSwitchVehicleSeat.isValid
end

function ISSwitchVehicleSeat:isValid()
	-- 0 is driver seat, I think
	-- We only care about driver seat
	if self.seatTo == 0 then
		local checkResult = AVCS.checkPermission(self.character, self.vehicle)
		if type(checkResult) == "boolean" then
			if checkResult == true then
				return AVCS.oISSwitchVehicleSeat(self)
			end
		elseif checkResult.permissions == true then
			return AVCS.oISSwitchVehicleSeat(self)
		else
			self.character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
			return false
		end
	else
		return AVCS.oISSwitchVehicleSeat(self)
	end
end

-- Copy and override the vanilla ISAttachTrailerToVehicle to block unauthorized users
-- ISAttachTrailerToVehicle:isValid loops like mad, not good. No choice but to use this
if not AVCS.oISAttachTrailerToVehicle then
    AVCS.oISAttachTrailerToVehicle = ISAttachTrailerToVehicle.perform
end

function ISAttachTrailerToVehicle:perform()
	local checkResultA = AVCS.checkPermission(self.character, self.vehicleA)
	local checkResultB = AVCS.checkPermission(self.character, self.vehicleB)

	if type(checkResultA) ~= "boolean" then
		if checkResultA.permissions == true then
			checkResultA = true
		else
			checkResultA = false
		end
	end

	if type(checkResultB) ~= "boolean" then
		if checkResultB.permissions == true then
			checkResultB = true
		else
			checkResultB = false
		end
	end

	if checkResultA and checkResultB then
		AVCS.oISAttachTrailerToVehicle(self)
	else
		self.character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		ISBaseTimedAction.stop(self)
	end
end

-- Copy and override the vanilla ISDetachTrailerFromVehicle to block unauthorized users
-- ISDetachTrailerFromVehicle:isValid loops like mad, not good. No choice but to use this
if not AVCS.oISDetachTrailerFromVehicle then
    AVCS.oISDetachTrailerFromVehicle = ISDetachTrailerFromVehicle.perform
end

function ISDetachTrailerFromVehicle:perform()
	local checkResult = AVCS.checkPermission(self.character, self.vehicle)

	if type(checkResult) ~= "boolean" then
		if checkResult.permissions == true then
			checkResult = true
		else
			checkResult = false
		end
	end

	if checkResult then
		AVCS.oISDetachTrailerFromVehicle(self)
	else
		self.character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		ISBaseTimedAction.stop(self)
	end
end

-- Copy and override the vanilla ISUninstallVehiclePart to block unauthorized users
if not AVCS.oISUninstallVehiclePart then
    AVCS.oISUninstallVehiclePart = ISUninstallVehiclePart.isValid
end

function ISUninstallVehiclePart:isValid()
	local checkResult = AVCS.checkPermission(self.character, self.vehicle)

	if type(checkResult) ~= "boolean" then
		if checkResult.permissions == true then
			checkResult = true
		else
			checkResult = false
		end
	end

	if checkResult then
		return AVCS.oISUninstallVehiclePart(self)
	else
		self.character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		return false
	end
end
