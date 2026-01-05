local BandaidChat = {}

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- [[ CONFIGURATION ]]
local SETTINGS = {
	MAX_MESSAGES_PER_WINDOW = 4, -- Max messages allowed in the time window
	TIME_WINDOW = 5,            -- Seconds for the window
	MIN_SIMILARITY = 0.8,       -- 80% similarity triggers the repeat filter
	BLOCK_HIGH_ENTROPY = true,  -- Blocks keysmashes/bot-links (e.g., "g3t_fRee_r0bUx!!")
}

local playerHistory = {} -- { [UserId] = { {Time: number, Content: string} } }

-- [[ UTILITY: LEVENSHTEIN DISTANCE ]]
-- This calculates how similar two strings are to prevent "S.p.a.m" bypassing
local function getSimilarity(s1, s2)
	if s1 == s2 then return 1 end
	local len1, len2 = #s1, #s2
	if len1 == 0 or len2 == 0 then return 0 end
	-- Simple ratio check for speed in Luau
	local matches = 0
	for i = 1, math.min(len1, len2) do
		if s1:sub(i,i) == s2:sub(i,i) then matches += 1 end
	end
	return matches / math.max(len1, len2)
end

-- [[ CORE MODERATION ]]
function BandaidChat.ProcessMessage(player, message)
	local userId = player.UserId
	local now = os.clock()
	
	if not playerHistory[userId] then playerHistory[userId] = {} end
	local history = playerHistory[userId]
	
	-- 1. CLEAN OLD HISTORY
	for i = #history, 1, -1 do
		if now - history[i].Time > SETTINGS.TIME_WINDOW then
			table.remove(history, i)
		end
	end
	
	-- 2. SPAM FREQUENCY CHECK
	if #history >= SETTINGS.MAX_MESSAGES_PER_WINDOW then
		return false, "Spamming too fast"
	end
	
	-- 3. REPETITION CHECK
	for _, entry in ipairs(history) do
		if getSimilarity(message:lower(), entry.Content:lower()) > SETTINGS.MIN_SIMILARITY then
			return false, "Repeat message detected"
		end
	end
	
	-- 4. ENTROPY / BOT-LINK CHECK (Pattern Matching)
	if SETTINGS.BLOCK_HIGH_ENTROPY then
		-- Detects excessive special characters or "bot-speak"
		local _, specialCount = message:gsub("[%p%s%d]", "") 
		if specialCount > (#message * 0.6) and #message > 10 then
			return false, "High entropy/Potential bot"
		end
	end
	
	-- If passed, add to history
	table.insert(history, {Time = now, Content = message})
	return true
end

-- [[ INITIALIZE ]]
function BandaidChat.Init()
	TextChatService.OnIncomingMessage = function(message)
		local properties = Instance.new("TextChatMessageProperties")
		
		if message.TextSource then
			local player = Players:GetPlayerByUserId(message.TextSource.UserId)
			local success, reason = BandaidChat.ProcessMessage(player, message.Text)
			
			if not success then
				-- Override message for the sender to show they are throttled
				properties.PrefixText = "<font color='#FF4444'>[MUTED]</font> " .. message.PrefixText
				properties.Text = "<i>Message blocked: " .. reason .. "</i>"
				
				-- In a real scenario, you could also return nil to hide the message entirely
				-- But showing a "Muted" state helps prevent the user from resending
			end
		end
		
		return properties
	end
	print("💬 BandaidChat Initialized")
end

return BandaidChat