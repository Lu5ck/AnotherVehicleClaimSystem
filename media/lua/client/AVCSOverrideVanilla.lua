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
    modal:initialise()
    modal:addToUIManager()
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
    modal:initialise()
    modal:addToUIManager()
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
	--option.toolTip = toolTip		-- FIXME option is not init
	if type(checkResult) == "boolean" then		
		if checkResult == true then
			local playerInv = player:getInventory()
			-- Free car
			option = context:addOption(getText("ContextMenu_AVCS_ClaimVehicle"), player, claimCfmDialog, vehicle)

			if playerInv:getItemCount("Base.AVCSClaimForm") < 1 then
				toolTip.description = getText("Tooltip_AVCS_Needs") .. " <RGB:1,0,0>" .. getItemNameFromFullType("Base.AVCSClaimForm") .. " " .. playerInv:getItemCount("Base.AVCSClaimForm") .. "/1"
				option.notAvailable = true
			else
				toolTip.description = getText("Tooltip_AVCS_Needs") .. " <RGB:0,1,0>" .. getItemNameFromFullType("Base.AVCSClaimForm") .. " " .. playerInv:getItemCount("Base.AVCSClaimForm") .. "/1"
				option.notAvailable = false
			end
			option.toolTip = toolTip
		elseif checkResult == false then
			-- Not supported vehicle
			option = context:addOption(getText("ContextMenu_AVCS_UnsupportedVehicle"), player, claimCfmDialog, vehicle)
			toolTip.description = getText("Tooltip_AVCS_Unsupported")
			option.notAvailable = true
		end
	elseif checkResult.permissions == true then
		-- Owned car
		option = context:addOption(getText("ContextMenu_AVCS_UnclaimVehicle"), player, unclaimCfmDialog, vehicle)
		toolTip.description = getText("Tooltip_AVCS_Owner") .. ": " .. checkResult.ownerid
		option.notAvailable = false
	elseif checkResult.permissions == false then
		-- Owned car
		option = context:addOption(getText("ContextMenu_AVCS_UnclaimVehicle"), player, unclaimCfmDialog, vehicle)
		toolTip.description = getText("Tooltip_AVCS_Owner") .. ": " .. checkResult.ownerid
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
	-- 0 is driver seat, I think
	-- We only care about driver seat
    if seat ~= 0 then
		return AVCS.oIsEnterVehicle(self, character, vehicle, seat)
	else
		local checkResult = AVCS.checkPermission(character, vehicle)
		checkResult = AVCS.getSimpleBooleanPermission(checkResult)

		if checkResult then
			return AVCS.oIsEnterVehicle(self, character, vehicle, seat)
		else
			self.character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
			local temp = {
				ignoreAction = true
			}
			return temp
		end
	end
end

-- Copy and override the vanilla ISSwitchVehicleSeat to block unauthorized users
if not AVCS.oISSwitchVehicleSeat then
    AVCS.oISSwitchVehicleSeat = ISSwitchVehicleSeat.new
end

function ISSwitchVehicleSeat:new(character, seatTo)
	-- 0 is driver seat, I think
	-- We only care about driver seat
    if seatTo ~= 0 then
		return AVCS.oISSwitchVehicleSeat(self, character, seatTo)
	else
		local checkResult = AVCS.checkPermission(character, character:getVehicle())
		checkResult = AVCS.getSimpleBooleanPermission(checkResult)

		if checkResult then
			return AVCS.oISSwitchVehicleSeat(self, character, seatTo)
		else
			self.character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
			local temp = {
				ignoreAction = true
			}
			return temp
		end
	end
end

-- Copy and override the vanilla ISAttachTrailerToVehicle to block unauthorized users
if not AVCS.oISAttachTrailerToVehicle then
    AVCS.oISAttachTrailerToVehicle = ISAttachTrailerToVehicle.new
end

function ISAttachTrailerToVehicle:new(character, vehicleA, vehicleB, attachmentA, attachmentB)
	local checkResultA = AVCS.checkPermission(character, vehicleA)
	local checkResultB = AVCS.checkPermission(character, vehicleB)
	checkResultA = AVCS.getSimpleBooleanPermission(checkResultA)
	checkResultB = AVCS.getSimpleBooleanPermission(checkResultB)

	if checkResultA and checkResultB then
		return AVCS.oISAttachTrailerToVehicle(self, character, vehicleA, vehicleB, attachmentA, attachmentB)
	else
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		local temp = {
			ignoreAction = true
		}
		return temp
	end
end

-- Copy and override the vanilla ISDetachTrailerFromVehicle to block unauthorized users
if not AVCS.oISDetachTrailerFromVehicle then
    AVCS.oISDetachTrailerFromVehicle = ISDetachTrailerFromVehicle.new
end

function ISDetachTrailerFromVehicle:new(character, vehicle, attachment)
	local checkResult = AVCS.checkPermission(character, vehicle)
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISDetachTrailerFromVehicle(self, character, vehicle, attachment)
	else
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		local temp = {
			ignoreAction = true
		}
		return temp
	end
end

-- Copy and override the vanilla ISUninstallVehiclePart to block unauthorized users
if not AVCS.oISUninstallVehiclePart then
    AVCS.oISUninstallVehiclePart = ISUninstallVehiclePart.new
end

function ISUninstallVehiclePart:new(character, part, time)
	local checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISUninstallVehiclePart(self, character, part, time)
	else
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		local temp = {
			ignoreAction = true
		}
		return temp
	end
end

-- Copy and override the vanilla ISTakeGasolineFromVehicle to block unauthorized users
if not AVCS.oISTakeGasolineFromVehicle then
    AVCS.oISTakeGasolineFromVehicle = ISTakeGasolineFromVehicle.new
end

function ISTakeGasolineFromVehicle:new(character, part, item, time)
	local checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISTakeGasolineFromVehicle(self, character, part, item, time)
	else
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		local temp = {
			ignoreAction = true
		}
		return temp
	end
end

-- Copy and override the vanilla ISTakeEngineParts to block unauthorized users
if not AVCS.oISTakeEngineParts then
    AVCS.oISTakeEngineParts = ISTakeEngineParts.new
end

function ISTakeEngineParts:new(character, part, item, time)
	local checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISTakeEngineParts(self, character, part, item, time)
	else
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		local temp = {
			ignoreAction = true
		}
		return temp
	end
end

-- Copy and override the vanilla ISDeflateTire to block unauthorized users
if not AVCS.oISDeflateTire then
    AVCS.oISDeflateTire = ISDeflateTire.new
end

function ISDeflateTire:new(character, part, psi, time)
	local checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISDeflateTire(self, character, part, psi, time)
	else
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		local temp = {
			ignoreAction = true
		}
		return temp
	end
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
	local checkResult = AVCS.checkPermission(character, vehicle)
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	-- Exiting from seat
	if type(partOrSeat) == "number" then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, partOrSeat)
	end

	-- Opening from outside
	local tempID = string.lower(partOrSeat:getId())
	if tempID ~= "trunkdoor" and tempID ~= "doorrear" then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, partOrSeat)
	end

	if checkResult then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, partOrSeat)
	else
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		local temp = {
			ignoreAction = true
		}
		return temp
	end
end

-- Copy and override the Vehicle Repair Overhaul ISVehicleSalvage to block unauthorized users
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2757712197
if ISVehicleSalvage then
	if not AVCS.oISVehicleSalvage then
		AVCS.oISVehicleSalvage = ISVehicleSalvage.new
	end

	function ISVehicleSalvage:new(character, vehicle)
		local checkResult = AVCS.checkPermission(character, vehicle)
		checkResult = AVCS.getSimpleBooleanPermission(checkResult)
	
		if checkResult then
			return AVCS.oISVehicleSalvage(self, character, vehicle)
		else
			character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
			local temp = {
				ignoreAction = true
			}
			return temp
		end
	end
end