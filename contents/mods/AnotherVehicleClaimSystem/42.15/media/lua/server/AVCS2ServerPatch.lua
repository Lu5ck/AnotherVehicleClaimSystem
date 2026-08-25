require "AVCS2Server.lua"

if isClient() and not isServer() then
	return
end

AVCS.patch = AVCS.patch or {}

AVCS.patch.onClientCommand = function(moduleName, command, playerObj, arg)
	if moduleName == "AVCS" and command == "getDBAVCSByVehicleSQLID" then
        sendServerCommand(playerObj, "AVCS", "getDBAVCSByVehicleSQLID", {AVCS.dbByVehicleSQLID})
	elseif moduleName == "AVCS" and command == "getDBAVCSByPlayerID" then
		sendServerCommand(playerObj, "AVCS", "getDBAVCSByPlayerID", {AVCS.dbByPlayerID})
	end
end

Events.OnClientCommand.Add(AVCS.patch.onClientCommand)