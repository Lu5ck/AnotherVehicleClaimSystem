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

    if SandboxVars.AVCS.ReturnTicket and SandboxVars.AVCS.RequireTicket then
        self.character:getInventory():AddItem("Base.AVCSClaimOrb")
    end

	local tempPart = AVCS.getMulePart(self.vehicle)
	sendClientCommand(self.character, "AVCS", "unclaimVehicle", { tempPart:getModData().SQLID })

    if UdderlyVehicleRespawn and SandboxVars.AVCS.UdderlyRespawn then
        UdderlyVehicleRespawn.SpawnRandomVehicleAtRandomZoneInRandomCell()
    end

    ISBaseTimedAction.perform(self)
end

function ISAVCSVehicleUnclaimAction:new(character, vehicle)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.stopOnWalk = true
    o.stopOnRun = true
    o.character = character
    o.vehicle = vehicle
    o.maxTime = 250
    
    if character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end