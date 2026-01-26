AVCS = AVCS or {}

-- Copy and override the vanilla ISUninstallVehiclePart to block unauthorized users
if not AVCS.oISUninstallVehiclePart then
    AVCS.oISUninstallVehiclePart = ISUninstallVehiclePart.new
end

function ISUninstallVehiclePart:new(character, part, workTime)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowUninstallParts")

	if checkResult then
		return AVCS.oISUninstallVehiclePart(self, character, part, workTime)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISUninstallVehiclePart(self, character, part, workTime)
	end
	if isClient() then
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	end
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISTakeGasolineFromVehicle to block unauthorized users
if not AVCS.oISTakeGasolineFromVehicle then
    AVCS.oISTakeGasolineFromVehicle = ISTakeGasolineFromVehicle.new
end

function ISTakeGasolineFromVehicle:new(character, part, item, otherItems)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowSiphonFuel")

	if checkResult then
		return AVCS.oISTakeGasolineFromVehicle(self, character, part, item, otherItems)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISTakeGasolineFromVehicle(self, character, part, item, otherItems)
	end
	if isClient() then
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	end
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISTakeEngineParts to block unauthorized users
if not AVCS.oISTakeEngineParts then
    AVCS.oISTakeEngineParts = ISTakeEngineParts.new
end

function ISTakeEngineParts:new(character, part, item, maxTime)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowTakeEngineParts")

	if checkResult then
		return AVCS.oISTakeEngineParts(self, character, part, item, maxTime)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISTakeEngineParts(self, character, part, item, maxTime)
	end
	if isClient() then
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	end
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISDeflateTire to block unauthorized users
if not AVCS.oISInflateTire then
    AVCS.oISInflateTire = ISInflateTire.new
end

function ISInflateTire:new(character, part, item, psiTarget)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowInflatTires")

	if checkResult then
		return AVCS.oISInflateTire(self, character, part, item, psiTarget)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISInflateTire(self, character, part, item, psiTarget)
	end
	if isClient() then
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	end
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISDeflateTire to block unauthorized users
if not AVCS.oISDeflateTire then
    AVCS.oISDeflateTire = ISDeflateTire.new
end

function ISDeflateTire:new(character, part, psiTarget)
	local checkResult = AVCS.getPublicPermission(part:getVehicle(), "AllowDeflatTires")

	if checkResult then
		return AVCS.oISDeflateTire(self, character, part, psiTarget)
	end

	checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISDeflateTire(self, character, part, psiTarget)
	end
	if isClient() then
		character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
	end
	local temp = {
		ignoreAction = true
	}
	return temp
end

-- Copy and override the vanilla ISSmashVehicleWindow to block unauthorized users
if not AVCS.oISSmashVehicleWindow then
    AVCS.oISSmashVehicleWindow = ISSmashVehicleWindow.new
end

function ISSmashVehicleWindow:new(character, part)
	local checkResult = AVCS.checkPermission(character, part:getVehicle())
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISSmashVehicleWindow(self, character, part)
	else
		if isClient() then
			character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
		end
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

function ISOpenVehicleDoor:new(character, vehicle, part)
	local tempID = string.lower(part:getId())
	if not AVCS.matchTrunkPart(tempID) then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, part)
	end

	local checkResult = AVCS.getPublicPermission(vehicle, "AllowOpeningTrunk")

	if checkResult then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, part)
	end

	checkResult = AVCS.checkPermission(character, vehicle)
	checkResult = AVCS.getSimpleBooleanPermission(checkResult)

	if checkResult then
		return AVCS.oISOpenVehicleDoor(self, character, vehicle, part)
	end
    if isClient() then
	    character:setHaloNote(getText("IGUI_AVCS_Vehicle_No_Permission"), 250, 250, 250, 300)
    end
	local temp = {
		ignoreAction = true
	}
	return temp
end