require "TimedActions/ISBaseTimedAction"

-- By adding this action, we can utilize the base game log system
isAVCSVehicleClaimAction = ISBaseTimedAction:derive("isAVCSVehicleClaimAction")

function isAVCSVehicleClaimAction:isValid()
    return self.vehicle and not self.vehicle:isRemovedFromWorld()
end

function isAVCSVehicleClaimAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function isAVCSVehicleClaimAction:update()
    self.character:faceThisObject(self.vehicle)
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
    if not self.character:getEmitter():isPlaying(self.sound) then
        self.sound = self.character:playSound("Hammering")
    end
end

function isAVCSVehicleClaimAction:start()
    self:setActionAnim("VehicleWorkOnMid")
    self.sound = self.character:playSound("Hammering")
end

function isAVCSVehicleClaimAction:stop()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
end

function isAVCSVehicleClaimAction:perform()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end
	
	sendClientCommand(self.character, "AVCS", "claimVehicle", { vehicle = self.vehicle:getId() })

	--local form = self.character:getInventory():getFirstTypeRecurse("AVCSClaimForm")
	--form:getContainer():Remove(form)

    if UdderlyVehicleRespawn and SandboxVars.AVCS.UdderlyRespawn then
        UdderlyVehicleRespawn.SpawnRandomVehicleAtRandomZoneInRandomCell()
    end

    ISBaseTimedAction.perform(self)
end

function isAVCSVehicleClaimAction:new(character, vehicle)
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