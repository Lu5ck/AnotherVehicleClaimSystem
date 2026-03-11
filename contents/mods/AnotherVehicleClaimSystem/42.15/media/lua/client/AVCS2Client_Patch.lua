require "AVCS2Client.lua"

if not isClient() and isServer() then
	return
end

AVCS.patch = AVCS.patch or {}

AVCS.patch.ModDataRequest = ModData.request

-- Deear modders, if an error occur here
-- It is not this override fault
-- You threw a nil into it
ModData.request = function(key, ...)
    if tostring(key) == "AVCSByVehicleSQLID" then
        sendClientCommand(getPlayer(), "AVCS", "getDBAVCSByVehicleSQLID", nil)
		return
	end

	if tostring(key) == "AVCSByPlayerID" then
		sendClientCommand(getPlayer(), "AVCS", "getDBAVCSByPlayerID", nil)
		return
	end

	return AVCS.patch.ModDataRequest(key, ...)
end

AVCS.patch.OnServerCommand = function(moduleName, command, arg)
	if moduleName == "AVCS" and command == "getDBAVCSByVehicleSQLID" then
		AVCS.dbByVehicleSQLID = arg[1]
	elseif moduleName == "AVCS" and command == "getDBAVCSByPlayerID" then
		AVCS.dbByPlayerID = arg[1]
	end
end

Events.OnTick.Remove(AVCS.AfterGameStart)
function AVCS.AfterGameStart()
	Events.OnServerCommand.Add(AVCS.patch.OnServerCommand)
	Events.OnServerCommand.Add(AVCS.OnServerCommand)
	sendClientCommand(getPlayer(), "AVCS", "getDBAVCSByVehicleSQLID", nil)
	sendClientCommand(getPlayer(), "AVCS", "getDBAVCSByPlayerID", nil)
	sendClientCommand(getPlayer(), "AVCS", "updateLastKnownLogonTime", nil)
	Events.OnTick.Remove(AVCS.AfterGameStart)
end
Events.OnTick.Add(AVCS.AfterGameStart)