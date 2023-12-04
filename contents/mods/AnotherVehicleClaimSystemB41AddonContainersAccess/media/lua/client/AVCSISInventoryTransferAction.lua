AVCS.oISInventoryTransferActionValid = ISInventoryTransferAction.isValid

function ISInventoryTransferAction:isValid()
    if not self.srcContainer then return AVCS.oISInventoryTransferActionValid(self) end

    local vehiclePart = self.srcContainer:getVehiclePart()
    if vehiclePart then
        local checkResult = AVCS.getPublicPermission(vehiclePart:getVehicle(), "AllowContainersAccess")
        -- If public allowed, we don't have to check other permissions
        if not checkResult then
            checkResult = AVCS.checkPermission(self.character, vehiclePart:getVehicle())
            checkResult = AVCS.getSimpleBooleanPermission(checkResult)
        end

        if checkResult then return AVCS.oISInventoryTransferActionValid(self)
        else return false end
    end

    return AVCS.oISInventoryTransferActionValid(self)
end