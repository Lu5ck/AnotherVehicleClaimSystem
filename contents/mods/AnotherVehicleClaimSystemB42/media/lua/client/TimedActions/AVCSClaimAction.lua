require "TimedActions/ISBaseTimedAction"

-- By adding this action, we can utilize the base game log system
ISAVCSVehicleClaimAction = ISBaseTimedAction:derive("ISAVCSVehicleClaimAction")

function ISAVCSVehicleClaimAction:isValid()
    return self.vehicle and not self.vehicle:isRemovedFromWorld()
end

function ISAVCSVehicleClaimAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function ISAVCSVehicleClaimAction:update()
    self.character:faceThisObject(self.vehicle)
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
    if not self.character:getEmitter():isPlaying(self.sound) then
        self.sound = self.character:playSound("AVCSClaimSound")
    end
end

function ISAVCSVehicleClaimAction:start()
    self:setActionAnim("VehicleWorkOnMid")
    self.sound = self.character:playSound("AVCSClaimSound")
end

function ISAVCSVehicleClaimAction:stop()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
end

function ISAVCSVehicleClaimAction:perform()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end
	
	sendClientCommand(self.character, "AVCS", "claimVehicle", { vehicle = self.vehicle:getId() })
    
    if SandboxVars.AVCS.RequireTicket then
	    local form = self.character:getInventory():getFirstTypeRecurse("AVCSClaimOrb")
	    form:getContainer():Remove(form)
    end

    if UdderlyVehicleRespawn and SandboxVars.AVCS.UdderlyRespawn then
        UdderlyVehicleRespawn.SpawnRandomVehicleAtRandomZoneInRandomCell()
    end

    ISBaseTimedAction.perform(self)
end

function ISAVCSVehicleClaimAction:new(character, vehicle)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.stopOnWalk = true
    o.stopOnRun = true
    o.character = character
    o.vehicle = vehicle
    o.maxTime = 480
    
    if character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end