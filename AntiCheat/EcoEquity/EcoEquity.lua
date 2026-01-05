local EquityService = {}

-- [[ CONFIGURATION ]]
local SETTINGS = {
	DATA_VARIABLE = "Gold", -- WHAT to watch
	CHECK_INTERVAL = 60,    -- FREQUENCY to check
	MIN_VALUE_THRESHOLD = 100, -- PERCENT to begin tracking
}

local playerSnapshots = {} 

-- [[ THE FORMULA SECTION ]]
-- modify to change HOW a player is flagged.
local function checkForInconsistency(oldValue, newValue, deltaTime)
	local change = newValue - oldValue
	
	-- FORMULA 1: PERCENTAGE GROWTH
	-- (Current - Previous) / Previous
	local growthRate = change / math.max(oldValue, 1)
	local MAX_GROWTH_PERCENT = 1.5 -- 150% growth allowed per interval
	
	-- FORMULA 2: FLAT CAP (Optional)
	-- Useful for "Maximum possible gold per minute"
	--local MAX_FLAT_GAIN = 5000 
	
	-- EVALUATION logic
	if growthRate > MAX_GROWTH_PERCENT then
		return true, string.format("Unusual Growth: %.1f%%", growthRate * 100)
	end
	
	--if change > MAX_FLAT_GAIN then
		--return true, string.format("Flat Cap Exceeded: +%d", change)
	--end

	return false, nil
end

-- [[ CORE LOGIC ]]
function EquityService.Start(player, valueObject)
	-- Initialize
	playerSnapshots[player.UserId] = {
		LastValue = valueObject.Value,
		LastCheck = os.clock()
	}

	task.spawn(function()
		while player and player.Parent do
			task.wait(SETTINGS.CHECK_INTERVAL)
			
			local current = valueObject.Value
			local snapshot = playerSnapshots[player.UserId]
			
			if snapshot and current > SETTINGS.MIN_VALUE_THRESHOLD then
				local delta = os.clock() - snapshot.LastCheck
				
				-- Apply the Formula
				local isSuspect, reason = checkForInconsistency(snapshot.LastValue, current, delta)
				
				if isSuspect then
					EquityService.OnFlagged(player, reason, current)
				end
			end
			
			-- Update snapshot
			if snapshot then
				snapshot.LastValue = current
				snapshot.LastCheck = os.clock()
			end
		end
	end)
end

-- [[ CALLBACK ]]
-- Decide punishment, bwahahaha...
function EquityService.OnFlagged(player, reason, currentAmount)
	warn(string.format("⚠️ [EQUITY ALERT] Player: %s | Reason: %s | Current %s: %d", 
		player.Name, reason, SETTINGS.DATA_VARIABLE, currentAmount))
	
	-- Example: player:Kick("Economy Inconsistency Detected")
end

return EquityService