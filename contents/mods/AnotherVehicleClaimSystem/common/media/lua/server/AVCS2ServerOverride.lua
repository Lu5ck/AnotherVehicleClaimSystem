if isClient() and not isServer() then
	return
end

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
    local vehicleID = AVCS.getVehicleID(vehicle)
    if vehicleID and AVCS.dbByVehicleSQLID[vehicleID] then
        local tempArr = AVCS.getUpdateVehicleCoordinate(vehicle, vehicleID)
        if tempArr then
            AVCS.updateVehicleCoordinate(tempArr)
            sendServerCommand("AVCS", "updateClientVehicleCoordinate", tempArr)
        end
    end

	return AVCS.oLowerCondition(vehicle, part, elapsedMinutes)
end