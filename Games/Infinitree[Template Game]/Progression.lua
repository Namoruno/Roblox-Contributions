-- SERVICES
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------
-- GAME CONFIGURATION (The "Tree")
--------------------------------------------------------------------------------
-- Add new currencies or upgrades here. The script handles the math automatically.
local GAME_TREE = {
	Currencies = {
		["Leaves"] = { Amount = 10, BaseIncome = 1 },
		["Bark"]   = { Amount = 0,  BaseIncome = 0 },
		["Roots"]  = { Amount = 0,  BaseIncome = 0 },
	},
	
	-- Passive boosts: Producers (higher tier) boost Consumers (lower tier)
	Interactions = {
		{ Producer = "Bark", Consumer = "Leaves", Multiplier = 0.5 } -- 1 Bark adds 0.5 Leaves/sec
	},

	Upgrades = {
		{
			Id = "Fertilizer",
			Target = "Leaves",
			Operation = "Addition", -- Adds to the per-second rate
			Amount = 2,
			Cost = 10,
			CurrencyUsed = "Leaves",
			Predecessors = {}, -- Always unlocked
		},
		{
			Id = "Photosynthesis",
			Target = "Leaves",
			Operation = "Multiplication", -- Multiplies the final output
			Amount = 1.5,
			Cost = 50,
			CurrencyUsed = "Leaves",
			Predecessors = {"Fertilizer"}, -- Visible only after buying Fertilizer
		},
		{
			Id = "StrongBark",
			Target = "Bark",
			Operation = "Addition",
			Amount = 1,
			Cost = 100,
			CurrencyUsed = "Leaves",
			Predecessors = {"Photosynthesis"},
		}
	}
}

--------------------------------------------------------------------------------
-- PLAYER STATE (In a real game, load this from a DataStore)
--------------------------------------------------------------------------------
local PlayerData = {
	Currencies = GAME_TREE.Currencies,
	UpgradesBought = {} -- List of IDs: {"Fertilizer", "Photosynthesis"}
}

--------------------------------------------------------------------------------
-- THE TICK LOGIC (The Engine)
--------------------------------------------------------------------------------

-- Calculates exactly how much of a specific currency is generated per second
local function calculateIncome(currencyName)
	local cfg = PlayerData.Currencies[currencyName]
	if not cfg then return 0 end
	
	-- 1. Start with Base Income
	local income = cfg.BaseIncome
	
	-- 2. Add Passive Growth from other currencies (Interactions)
	for _, interaction in pairs(GAME_TREE.Interactions) do
		if interaction.Consumer == currencyName then
			local producerAmount = PlayerData.Currencies[interaction.Producer].Amount
			income += (producerAmount * interaction.Multiplier)
		end
	end
	
	-- 3. Apply Upgrades (Addition first, then Multiplication)
	local multiplier = 1
	for _, upgradeId in pairs(PlayerData.UpgradesBought) do
		-- Find the upgrade definition in the tree
		for _, upg in pairs(GAME_TREE.Upgrades) do
			if upg.Id == upgradeId and upg.Target == currencyName then
				if upg.Operation == "Addition" then
					income += upg.Amount
				elseif upg.Operation == "Multiplication" then
					multiplier *= upg.Amount
				end
			end
		end
	end
	
	return income * multiplier
end

-- The main loop function
local function onTick(dt)
	for currencyName, _ in pairs(PlayerData.Currencies) do
		local perSecond = calculateIncome(currencyName)
		PlayerData.Currencies[currencyName].Amount += perSecond * dt
	end
end

-- Connect to Heartbeat (standard Roblox tick function)
RunService.Heartbeat:Connect(onTick)

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS (For UI or Interaction)
--------------------------------------------------------------------------------

-- Call this function when a player clicks a "Buy" button
local function tryPurchaseUpgrade(upgradeId)
	-- Find upgrade data
	local upgradeData = nil
	for _, upg in pairs(GAME_TREE.Upgrades) do
		if upg.Id == upgradeId then upgradeData = upg break end
	end
	
	if not upgradeData then return false end
	
	-- Check Predecessors
	for _, req in pairs(upgradeData.Predecessors) do
		local owned = false
		for _, bought in pairs(PlayerData.UpgradesBought) do
			if bought == req then owned = true break end
		end
		if not owned then return false end -- Missing requirement
	end
	
	-- Check Cost
	local currency = PlayerData.Currencies[upgradeData.CurrencyUsed]
	if currency.Amount >= upgradeData.Cost then
		currency.Amount -= upgradeData.Cost
		table.insert(PlayerData.UpgradesBought, upgradeId)
		print("Successfully bought: " .. upgradeId)
		return true
	end
	
	return false
end

--------------------------------------------------------------------------------
-- TESTING (Optional: Simulates buying to see the numbers go up)
--------------------------------------------------------------------------------
task.wait(2)
tryPurchaseUpgrade("Fertilizer") -- Buy the first upgrade automatically for testing

-- Print totals every 2 seconds to the output
while true do
	print("--- InfiniTree Status ---")
	for name, data in pairs(PlayerData.Currencies) do
		print(name .. ": " .. math.floor(data.Amount))
	end
	task.wait(2)
end