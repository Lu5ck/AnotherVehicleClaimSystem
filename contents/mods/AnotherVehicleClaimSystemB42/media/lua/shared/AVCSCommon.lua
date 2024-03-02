--[[
AVCS Generic functions
All are local functions thus to use this, you must require this lua
TODO: Not utilized, WIP
--]]

-- Ingame debugger is unreliable but this does work
local function AVCSgetMulePart(vehicleObj)
    if vehicleObj then
        -- Split by ";"
        for s in string.gmatch(SandboxVars.AVCS.MuleParts, "([^;]+)") do
            -- Trim leading and trailing white spaces
            local tempPart = vehicleObj:getPartById(s:match("^%s*(.-)%s*$"))
            if tempPart then
                return tempPart
            end
        end
        return nil
    else
        return nil
    end
end

local function AVCSgetVehicleID(muleObj)
    if muleObj then
        return muleObj:getModData().SQLID
    else
        return nil
    end
end

-- Returns boolean for set status
-- You have to do transmitPartModData if needed
local function AVCSsetVehicleID(muleObj, arg)
    if muleObj and isServer() and type(arg) == "number" then
        muleObj:getModData().SQLID = arg
        return true
    else
        return false
    end
end

local function AVCShasVehicleID(vehicleID)
    if type(vehicleID) == "number" then
        if AVCS.dbByVehicleSQLID[vehicleID] then
            return true
        else
            return false
        end
    else
        return false
    end
end

local function AVCSgetVehicleOwnerID(vehicleID)
    if vehicleID then
        if type(vehicleID) == "number" then
            return AVCS.dbByVehicleSQLID[vehicleID].OwnerPlayerID
        else
            return nil
        end
    else
        return nil
    end
end

local function AVCSgetVehicleLocation(vehicleID)
    if vehicleID then
        if type(vehicleID) == "number" then
            return {X = AVCS.dbByVehicleSQLID[vehicleID].LastLocationX, Y = AVCS.dbByVehicleSQLID[vehicleID].LastLocationY}
        else
            return nil
        end
    else
        return nil
    end
end

-- Returns boolean for set status
local function AVCSsetVehicleLocation(vehicleID, x, y)
    if vehicleID then
        if type(vehicleID) == "number" and type(x) == "number" and type(y) == "number" then
            AVCS.dbByVehicleSQLID[vehicleID].LastLocationX = x
            AVCS.dbByVehicleSQLID[vehicleID].LastLocationY = y
            return true
        else
            return false
        end
    else
        return false
    end
end

local function AVCSgetUserLogonTime(username)
    if username then
        if AVCS.dbByPlayerID[username] then
            return AVCS.dbByPlayerID[username].LastKnownLogonTime
        else
            return nil
        end
    else
        return nil
    end
end

local function AVCSsetUserLogonTime(username, arg)
    if username then
        if AVCS.dbByPlayerID[username] then
            AVCS.dbByPlayerID[username].LastKnownLogonTime = arg
        else
            return false
        end
    else
        return false
    end
end