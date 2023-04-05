require "TimedActions/ISBaseTimedAction"

-- By adding this action, we can utilize the base game log system
isAVCSVehicleUnclaimAction = ISBaseTimedAction:derive("isAVCSVehicleUnclaimAction")

function isAVCSVehicleUnclaimAction:isValid()
    return self.vehicle and not self.vehicle:isRemovedFromWorld()
end

function isAVCSVehicleUnclaimAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function isAVCSVehicleUnclaimAction:update()
    self.character:faceThisObject(self.vehicle)
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
    if not self.character:getEmitter():isPlaying(self.sound) then
        self.sound = self.character:playSound("Hammering")
    end
end

function isAVCSVehicleUnclaimAction:start()
    self:setActionAnim("VehicleWorkOnMid")
    self.sound = self.character:playSound("Hammering")
end

function isAVCSVehicleUnclaimAction:stop()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
end

function isAVCSVehicleUnclaimAction:perform()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end

    if SandboxVars.AVCS.ReturnTicket then
        self.character:getInventory():AddItem("Base.AVCSClaimOrb")
    end

	local tempPart = AVCS.getMulePart(self.vehicle)
	sendClientCommand(self.character, "AVCS", "unclaimVehicle", { tempPart:getModData().SQLID })

    if UdderlyVehicleRespawn and SandboxVars.AVCS.UdderlyRespawn then
        UdderlyVehicleRespawn.SpawnRandomVehicleAtRandomZoneInRandomCell()
    end

    ISBaseTimedAction.perform(self)
end

function isAVCSVehicleUnclaimAction:new(character, vehicle)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.stopOnWalk = true
    o.stopOnRun = true
    o.character = character
    o.vehicle = vehicle
    o.maxTime = 600
    
    if character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end