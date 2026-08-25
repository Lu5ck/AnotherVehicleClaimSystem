require "AVCS2Server"

if isClient() and not isServer() then
	return
end

AVCS.claimTimeoutCache = AVCS.claimTimeoutCache or nil

function AVCS.sortClaimTimeoutCache()
	table.sort(AVCS.claimTimeoutCache, function(a, b) return a.ExpiryTime < b.ExpiryTime end)
end

function AVCS.buildClaimTimeoutCache()
	AVCS.claimTimeoutCache = {}
	for k, v in pairs(AVCS.dbByPlayerID) do
		AVCS.addToClaimTimeoutCache(k)
	end

	AVCS.sortClaimTimeoutCache()
end

function AVCS.getExpiryDateTime(playerID)
	if playerID and AVCS.dbByPlayerID[playerID] then
		return AVCS.dbByPlayerID[playerID].LastKnownLogonTime + (SandboxVars.AVCS.ClaimTimeout * 60 * 60)
	end
	return false
end

function AVCS.addToClaimTimeoutCache(playerID)
	if playerID and AVCS.dbByPlayerID[playerID] then
		local expiryDateTime = AVCS.getExpiryDateTime(playerID)
		table.insert(AVCS.claimTimeoutCache, {ExpiryTime = expiryDateTime, OwnerPlayerID = playerID})
	end
end

function AVCS.doClaimTimeout()
	local varIndex = 1
	local needSort = false
	-- As we dealing with indexes, we want to control the index value as we increment to avoid removing wrong index
	while varIndex <= #AVCS.claimTimeoutCache do
		if getTimestamp() > AVCS.claimTimeoutCache[varIndex].ExpiryTime then
			if AVCS.dbByPlayerID[AVCS.claimTimeoutCache[varIndex].OwnerPlayerID] ~= nil then
				-- Cache is not always up-to-date, validate the actual
				local curExpiryDateTime = AVCS.getExpiryDateTime(AVCS.claimTimeoutCache[varIndex].OwnerPlayerID)
				if getTimestamp() > curExpiryDateTime then
					AVCS.removePlayerCompletely(AVCS.claimTimeoutCache[varIndex].OwnerPlayerID)
					table.remove(AVCS.claimTimeoutCache, varIndex)
				else
					-- Update the expiry time
					AVCS.claimTimeoutCache[varIndex].ExpiryTime = curExpiryDateTime
					needSort = true
					varIndex = varIndex + 1
				end
			else
				-- User no longer exist, remove from index
				table.remove(AVCS.claimTimeoutCache, varIndex)
			end
		else
			-- Since sorted, assume everybody else has not expired
			break
		end
	end

	if needSort then
		AVCS.sortClaimTimeoutCache()
	end
end
Events.EveryTenMinutes.Add(AVCS.doClaimTimeout)