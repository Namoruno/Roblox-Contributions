local RemoteShield = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local rateLimits = {}
local playerStates = {}

-- CONFIGURATION
local DEFAULT_WALK_SPEED = 16
local MAX_LEGAL_SPEED = 28 -- Accounts for ping/jitter
local MAX_AIR_TIME = 3.0   -- Seconds allowed in air before flagging
local RAY_FLOOR_DIST = 12  -- How far down to look for a floor

-- Initialize Player Tracking
local function monitorPlayer(player)
	player.CharacterAdded:Connect(function(char)
		local root = char:WaitForChild("HumanoidRootPart")
		playerStates[player.UserId] = {
			LastPos = root.Position,
			MaxSpeed = DEFAULT_WALK_SPEED,
			AirTime = 0,
			Flags = 0,
			IsActive = true
		}
	end)
end

Players.PlayerAdded:Connect(monitorPlayer)
Players.PlayerRemoving:Connect(function(p) playerStates[p.UserId] = nil end)

-- HEARTBEAT MONITOR (The Engine)
RunService.Heartbeat:Connect(function(dt)
	for _, player in ipairs(Players:GetPlayers()) do
		local state = playerStates[player.UserId]
		local char = player.Character
		if state and state.IsActive and char and char:FindFirstChild("HumanoidRootPart") then
			local root = char.HumanoidRootPart
			local currentPos = root.Position
			
			-- 1. SPEED & NOCLIP CHECK
			local moveDistance = (currentPos - state.LastPos).Magnitude
			local maxAllowed = (state.MaxSpeed * dt) + 0.8 -- 0.8 is the "Lag Buffer"
			
			-- If speed is -1, bypass all movement checks
			if state.MaxSpeed ~= -1 then
				-- Check for Noclip (Raycast from LastPos to CurrentPos)
				local wallParams = RaycastParams.new()
				wallParams.FilterDescendantsInstances = {char}
				local wallHit = workspace:Raycast(state.LastPos, currentPos - state.LastPos, wallParams)
				
				if wallHit and wallHit.Instance.CanCollide then
					-- They walked through a solid wall!
					root.CFrame = CFrame.new(state.LastPos)
				elseif moveDistance > maxAllowed then
					-- Moving too fast! Rubberband them back.
					root.CFrame = CFrame.new(state.LastPos)
				else
					state.LastPos = currentPos
				end

				-- 2. FLY DETECTION
				local floorParams = RaycastParams.new()
				floorParams.FilterDescendantsInstances = {char}
				local floorHit = workspace:Raycast(root.Position, Vector3.new(0, -RAY_FLOOR_DIST, 0), floorParams)
				
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				local isFalling = humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.FallingDown)
				
				if not floorHit and isFalling then
					state.AirTime += dt
					if state.AirTime > MAX_AIR_TIME then
						warn("[SHIELD] Fly detect: " .. player.Name)
						-- Potential Action: Force fall or Reset character
						-- root.Anchored = false 
					end
				else
					state.AirTime = 0
				end
			else
				-- Speed is -1 (Infinite), just update position without checking
				state.LastPos = currentPos
			end
		end
	end
end)

--- API FOR DEVELOPERS ---

-- Change speed limit (e.g., 16 for walk, 40 for sprint, 100 for car, -1 for infinite)
function RemoteShield.SetSpeedLimit(player, newLimit)
	if playerStates[player.UserId] then
		playerStates[player.UserId].MaxSpeed = newLimit
		playerStates[player.UserId].AirTime = 0 -- Reset airtime when switching states
	end
end

-- Secure RemoteEvents with rate limits and type validation
function RemoteShield.SecureConnect(remoteEvent, callback, options)
	options = options or {}
	return remoteEvent.OnServerEvent:Connect(function(player, ...)
		local args = {...}
		local now = os.clock()
		if not rateLimits[player.UserId] then rateLimits[player.UserId] = 0 end
		
		-- Rate Limit
		if now - rateLimits[player.UserId] < (options.Cooldown or 0.1) then return end
		rateLimits[player.UserId] = now
		
		-- Type Check
		if options.ExpectedTypes then
			for i, t in ipairs(options.ExpectedTypes) do
				if typeof(args[i]) ~= t then return end
			end
		end
		
		callback(player, unpack(args))
	end)
end

return RemoteShield