require "TimedActions/ISBaseTimedAction"

-- By adding this action, we can utilize the base game log system
ISAVCSVehicleUnclaimAction = ISBaseTimedAction:derive("ISAVCSVehicleUnclaimAction")

function ISAVCSVehicleUnclaimAction:isValid()
    return self.vehicle and not self.vehicle:isRemovedFromWorld()
end

function ISAVCSVehicleUnclaimAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function ISAVCSVehicleUnclaimAction:update()
    self.character:faceThisObject(self.vehicle)
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
    if not self.character:getEmitter():isPlaying(self.sound) then
        self.sound = self.character:playSound("AVCSClaimSound")
    end
end

function ISAVCSVehicleUnclaimAction:start()
    self:setActionAnim("VehicleWorkOnMid")
    self.sound = self.character:playSound("AVCSClaimSound")
end

function ISAVCSVehicleUnclaimAction:stop()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
end

function ISAVCSVehicleUnclaimAction:perform()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end

    ISBaseTimedAction.perform(self)
end

function ISAVCSVehicleUnclaimAction:complete()
    local vehicleID = AVCS.getVehicleID(self.vehicle)
    if SandboxVars.AVCS.ServerSideChecking then
        local checkResult = AVCS.checkPermission(self.character, vehicleID)

        if type(checkResult) == "boolean" then
            if checkResult == false then
                -- Using vanilla logging function, write to a log with suffix AVCS
                -- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
                -- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
                writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to unclaim without permission [" .. self.character:getUsername() .. "] [" .. AVCS.dbByVehicleSQLID[vehicleID].CarModel .. "] [" .. AVCS.dbByVehicleSQLID[vehicleID].LastLocationX .. "," .. AVCS.dbByVehicleSQLID[vehicleID].LastLocationY .. "]")

                -- Possible desync has occurred, force sync the user
                sendServerCommand(self.character, "AVCS", "forcesyncClientGlobalModData", {})
                return true
            end
        elseif checkResult.permissions == false then
            -- Using vanilla logging function, write to a log with suffix AVCS
            -- Datetime, Unix Time, Warning message, offender username, vehicle full name, coordinate
            -- [26-03-23 22:23:36.671] [1679840616] Warning: Attempting to unclaim without permission [Username] [Base.ExtremeCar] [13026,1215]
            writeLog("AVCS", "[" .. getTimestamp() .. "] Warning: Attempting to unclaim without permission [" .. self.character:getUsername() .. "] [" .. AVCS.dbByVehicleSQLID[vehicleID].CarModel .. "] [" .. AVCS.dbByVehicleSQLID[vehicleID].LastLocationX .. "," .. AVCS.dbByVehicleSQLID[vehicleID].LastLocationY .. "]")

            -- Possible desync has occurred, force sync the user
            sendServerCommand(self.character, "AVCS", "forcesyncClientGlobalModData", {})
            return true
        end
    end

    AVCS.unclaimVehicle(self.character, vehicleID)
    if SandboxVars.AVCS.ReturnTicket and SandboxVars.AVCS.RequireTicket then
        local invItem = self.character:getInventory():AddItem("AVCS.ClaimOrb")
        sendAddItemToContainer(self.character:getInventory(), invItem)
    end

    return true
end

function ISAVCSVehicleUnclaimAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 125
end

function ISAVCSVehicleUnclaimAction:new(character, vehicle)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.stopOnWalk = true
    o.stopOnRun = true
    o.character = character
    o.vehicle = vehicle
    o.maxTime = o:getDuration()

    return o
end