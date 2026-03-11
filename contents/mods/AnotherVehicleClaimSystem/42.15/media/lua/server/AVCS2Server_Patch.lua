require "AVCS2Server.lua"

if isClient() and not isServer() then
	return
end

AVCS.patch = AVCS.patch or {}

AVCS.patch.onClientCommand = function(moduleName, command, playerObj, arg)
	if moduleName == "AVCS" and command == "getAVCSDB" then
        sendServerCommand(playerObj, "AVCS", "getAVCSDB", {AVCS.dbByVehicleSQLID, AVCS.dbByPlayerID})
	end
end

Events.OnClientCommand.Add(AVCS.patch.onClientCommand)