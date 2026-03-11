require "AVCS2Client.lua"

if not isClient() and isServer() then
	return
end

AVCS.patch = AVCS.patch or {}

AVCS.patch.OnServerCommand = function(moduleName, command, arg)
	if moduleName == "AVCS" and command == "getAVCSDB" then
		AVCS.dbByVehicleSQLID = arg[1]
		AVCS.dbByPlayerID = arg[2]
	end
end

function AVCS.forcesyncClientGlobalModData()
	sendClientCommand(getPlayer(), "AVCS", "getAVCSDB", nil)
end

Events.OnTick.Remove(AVCS.AfterGameStart)
function AVCS.AfterGameStart()
	Events.OnServerCommand.Add(AVCS.patch.OnServerCommand)
	Events.OnServerCommand.Add(AVCS.OnServerCommand)
	sendClientCommand(getPlayer(), "AVCS", "getAVCSDB", nil)
	sendClientCommand(getPlayer(), "AVCS", "updateLastKnownLogonTime", nil)
	Events.OnTick.Remove(AVCS.AfterGameStart)
end
Events.OnTick.Add(AVCS.AfterGameStart)