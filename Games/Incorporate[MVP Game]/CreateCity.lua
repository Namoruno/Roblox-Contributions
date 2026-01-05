-- For all intents and purposes in the portfolio, this file stands as a DSA project.

-- Creating a city with blocks and intersections to give the feel of uniqueness to each game
-- This ensures that players must think on their feet. 

local intersections = {}
local roads = {} 
function addIntersection(VectorThreeValue)
	if not intersections[VectorThreeValue] then
		intersections[VectorThreeValue] = true
	end
end
function addRoad(VectorThreeValue, turn)
	if not roads[VectorThreeValue] then
		roads[VectorThreeValue] = turn
	end
end

function createNewGrid(size, root)
	local noiseDisplacement = math.random()
	local gridFolder = Instance.new("Folder")
	local ServerPlotChance = size.X/(size.X*20)
	gridFolder.Name = "Grid-"..workspace.Plots.Grids.Value
	gridFolder.Parent=game.Workspace.Plots
	for gridX = size.X, 0, -1  do
		for gridZ = size.Y, 0, -1 do
			if(math.random() < ServerPlotChance) then -- decide to create server gen building
				local ServerBuilding = game.ReplicatedStorage.Buildings.Apartments:Clone()
				ServerBuilding.Name = "Building"..gridX.."-"..gridZ
				ServerBuilding.Parent = gridFolder
				ServerBuilding:MoveTo(Vector3.new(root.X+(gridX * 32), 0.5, root.Z+(gridZ * 32)))
				if(gridX == size.X) then
					addRoad(Vector3.new(ServerBuilding.Land.Position.X+32, 0, root.Z+(gridZ * 32)), false)
				elseif gridX == 0 then
					addRoad(Vector3.new(ServerBuilding.Land.Position.X-32, 0, root.Z+(gridZ * 32)), false)
				end
				if(gridZ == size.Y) then
					addRoad(Vector3.new(root.X+(gridX * 32), 0, ServerBuilding.Land.Position.Z+32), true)
				elseif gridZ == 0 then
					addRoad(Vector3.new(root.X+(gridX * 32), 0, ServerBuilding.Land.Position.Z-32), true)
				end
			else -- decide to create purchaseable plot
				local plot = game.ReplicatedStorage.Plot:Clone()
				plot.Name = "Plot"..gridX.."-"..gridZ
				plot.Parent = gridFolder
				plot.Cost.Value = math.floor(math.noise((gridX/size.X/25)+noiseDisplacement, (gridZ/size.Y/25)+noiseDisplacement)*1500+5000)
				plot.Land.PriceGUI.Label.Text = "$"..math.floor(math.noise((gridX/size.X/25)+noiseDisplacement, (gridZ/size.Y/25)+noiseDisplacement)*1500+5000)
				plot.Land.Position = Vector3.new(root.X+(gridX * 32), 0.5, root.Z+(gridZ * 32))
				if(gridX == size.X) then
					addRoad(Vector3.new(plot.Land.Position.X+32, 0, root.Z+(gridZ * 32)), false)
				elseif gridX == 0 then
					addRoad(Vector3.new(plot.Land.Position.X-32, 0, root.Z+(gridZ * 32)), false)
				end
				if(gridZ == size.Y) then
					addRoad(Vector3.new(root.X+(gridX * 32), 0, plot.Land.Position.Z+32), true)
				elseif gridZ == 0 then
					addRoad(Vector3.new(root.X+(gridX * 32), 0, plot.Land.Position.Z-32), true)
				end
			end
		end
	end
	addIntersection(Vector3.new(root.X - 32, 0, root.Z - 32))
	addIntersection(Vector3.new((root.X + 32)+size.X*32, 0, (root.Z + 32)+size.Y*32))
	addIntersection(Vector3.new(root.X - 32, 0, (root.Z + 32)+size.Y*32))
	addIntersection(Vector3.new((root.X + 32)+size.X*32, 0, root.Z - 32))
end

function createIntersections(list)
	for i,v in pairs(intersections) do
		local intersection = game.ReplicatedStorage.Intersection:Clone()
		intersection.Parent = workspace.Roads
		intersection:MoveTo(i)
	end
end
function createRoads(list)
	for i,v in pairs(roads) do
		local road = game.ReplicatedStorage.Road:Clone()
		road.Parent = workspace.Roads
		road:MoveTo(i)
		if(v) then
			road:PivotTo(road.PrimaryPart.CFrame * CFrame.Angles(0,math.rad(90),0))
		end
	end
end

game.Players.PlayerAdded:Connect(function(plr)
	local JoinData = plr:GetJoinData().TeleportData
	if(JoinData.Host == plr.UserId) then
		local firstGridSize = Vector2.new(JoinData.MapSize,JoinData.MapSize)
		local firstGridRoot = Vector3.new(0,0,0)
		local secondGridSize = Vector2.new(firstGridSize.X+1, math.random(2,firstGridSize.Y-1))
		local secondGridRoot = Vector3.new(firstGridSize.X*32+64+firstGridRoot.X, 0, firstGridSize.Y*32+64+firstGridRoot.Z)
		local thirdGridSize = Vector2.new(firstGridSize.X, secondGridSize.Y)
		local thirdGridRoot = Vector3.new(firstGridRoot.X, 0, secondGridRoot.Z)
		local fourthGridSize = Vector2.new(firstGridSize.X+1, firstGridSize.Y)
		local fourthGridRoot = Vector3.new(secondGridRoot.X,0, firstGridRoot.Z)
		createNewGrid(firstGridSize, firstGridRoot)
		createNewGrid(secondGridSize, secondGridRoot)
		createNewGrid(thirdGridSize,thirdGridRoot)
		createNewGrid(fourthGridSize, fourthGridRoot)
		createIntersections(intersections)
		createRoads(roads)
		game.Workspace.Plots.Grids:Destroy() -- get rid of evidence coz it ugly
	end
end)