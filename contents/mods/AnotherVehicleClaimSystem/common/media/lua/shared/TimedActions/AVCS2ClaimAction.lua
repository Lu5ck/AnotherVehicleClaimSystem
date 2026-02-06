require "TimedActions/ISBaseTimedAction"

-- By adding this action, we can utilize the base game log system
ISAVCSVehicleClaimAction = ISBaseTimedAction:derive("ISAVCSVehicleClaimAction")

function ISAVCSVehicleClaimAction:isValid()
    if SandboxVars.AVCS.RequireTicket then
        local form = self.character:getInventory():getFirstType("AVCS.ClaimOrb")
        if not form then return false end
    end
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

    ISBaseTimedAction.perform(self)
end

function ISAVCSVehicleClaimAction:complete()
    AVCS.claimVehicle(self.character, { vehicle = self.vehicle:getId() })
    if SandboxVars.AVCS.RequireTicket then
	    local invItem = self.character:getInventory():getFirstType("AVCS.ClaimOrb")
        local invItemContainer = invItem:getContainer()
	    invItemContainer:Remove(invItem)
        sendRemoveItemFromContainer(invItemContainer, invItem)
    end

    return true
end

function ISAVCSVehicleClaimAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 240
end

function ISAVCSVehicleClaimAction:new(character, vehicle)
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