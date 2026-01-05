-- This is the script for room/lobby management of "Incorporate"
-- made with goal of simplifying the representation of room data accross scripts and with the UI
-- Does not focus on optomization as servers contain <25 players and this is definitely performant enough.
-- Meant to be understood by any dev if they choose to join the team!

local tps = game:GetService("TeleportService")
local remotes = game.ReplicatedStorage.Remotes
local rooms = game.ReplicatedStorage.RoomData
local gamePlace = 17824641591
local teleportQueue = {}

remotes.TeleportRoom.OnServerEvent:Connect(function(plr, room)
	if(not teleportQueue[plr.Name]) then
		table.insert(teleportQueue, plr.Name)
		local players = {}
		local teleportOptions = Instance.new("TeleportOptions")
		local teleportData = {
			Host=plr.UserId,
			MapSize=room.MapSize.Value,
			StartingCash=room.StartingCash.Value,
		}
        
		for i,v in pairs(room.Players:GetChildren()) do
			local partyMember:Player = game.Players[v.Name]
			local CompanyColor = partyMember.CompanyColor.Value
			table.insert(players, partyMember)
			teleportData[partyMember.UserId.."R"] = CompanyColor.R
			teleportData[partyMember.UserId.."G"] = CompanyColor.G
			teleportData[partyMember.UserId.."B"] = CompanyColor.B
			local Inventory = partyMember:FindFirstChild("Inventory")
			if(Inventory:GetAttribute("EquipSlot1") ~= nil) then
				teleportData[partyMember.UserId.."EquipSlot1"] = partyMember:FindFirstChild("Inventory"):GetAttribute("EquipSlot1")
			else
				teleportData[partyMember.UserId.."EquipSlot1"] = "none"
			end
			teleportData[partyMember.UserId.."EquipSlot2"] = partyMember:FindFirstChild("Inventory"):GetAttribute("EquipSlot2")
			teleportData[partyMember.UserId.."EquipSlot3"] = partyMember:FindFirstChild("Inventory"):GetAttribute("EquipSlot3")
			teleportData[partyMember.UserId.."EquipSlot4"] = partyMember:FindFirstChild("Inventory"):GetAttribute("EquipSlot4")
		end
		teleportOptions:SetTeleportData(teleportData)
		teleportOptions.ShouldReserveServer = true
		tps:TeleportAsync(gamePlace, players, teleportOptions)
	end
end)

function adjustPlayerNums(room, numLeaving)
	for i,v in pairs(room.Players:GetChildren()) do
		if(v.Value > numLeaving) then
			v.Value-=1
		end
	end
end

game.Players.PlayerAdded:Connect(function(plr)
	local RoomTag = Instance.new("ObjectValue") -- will prevent play button from going back to lobbies
	RoomTag.Name = "Room"
	RoomTag.Parent = plr
end)

remotes.CreateRoom.OnServerEvent:Connect(function(plr, roomData)
	if(rooms:FindFirstChild(plr.Name.."'s Room")==nil) then
		local newRoom = Instance.new("Folder")
		newRoom.Name = plr.Name.."'s Room"
		local maxPlayers = Instance.new("IntValue")
		maxPlayers.Name = "MaxPlayers"
		maxPlayers.Value = roomData.maxPlayers
		local mapSize = Instance.new("IntValue")
		mapSize.Name = "MapSize"
		mapSize.Value = roomData.mapSize
		local startingCash = Instance.new("IntValue")
		startingCash.Name = "StartingCash"
		startingCash.Value = roomData.startingCash
		local players = Instance.new("Folder")
		players.Name = "Players"
		local host = Instance.new("IntValue")
		host.Name = plr.Name
		host.Value = 1
		-- Parents must be set after as childAdded is used to determine room creation*
		maxPlayers.Parent = newRoom
		mapSize.Parent = newRoom
		startingCash.Parent = newRoom
		players.Parent = newRoom
		host.Parent = players
		newRoom.Parent = rooms -- Last place specifically
		plr.Room.Value = newRoom
		wait(3)
	end
end)

remotes.JoinRoom.OnServerEvent:Connect(function(plr, room)
	room = rooms:FindFirstChild(room)
	local playerStore = Instance.new("IntValue")
	playerStore.Name = plr.Name
	playerStore.Value = #room.Players:GetChildren() + 1
	playerStore.Parent = room.Players
	plr.Room.Value = room
end)

remotes.LeaveRoom.OnServerEvent:Connect(function(plr, room)
	local playerNum = room.Players:FindFirstChild(plr.Name).Value
	room.Players:FindFirstChild(plr.Name):Destroy()
	adjustPlayerNums(room,playerNum)
end)

remotes.CloseRoom.OnServerEvent:Connect(function(plr)
	for i,v in pairs(plr.Room.Value.Players:GetChildren()) do
		remotes.KickedFromRoom:FireClient(game.Players:FindFirstChild(v.Name))
	end
	rooms:WaitForChild(plr.Name.."'s Room"):Destroy()
end)