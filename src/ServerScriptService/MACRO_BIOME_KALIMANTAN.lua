-- MACRO_BIOME_KALIMANTAN.lua
-- Generates a massive, island-shaped procedural biome with rotating seasons and deadly meteor events.

local MacroBiome = {}

local ServerScriptService = game:GetService("ServerScriptService")
local MonsterManager = require(ServerScriptService:WaitForChild("MonsterManager"))
local FurnitureSystem = require(ServerScriptService:WaitForChild("FURNITURE_BATCH_1_10"))
local WeatherSystem = require(ServerScriptService:WaitForChild("WEATHER_DISASTER_BATCH_1_6"))
local ExtremeWeatherSystem = require(ServerScriptService:WaitForChild("WEATHER_DISASTER_BATCH_7_10"))

-- Roblox max part size is 2048 studs. 1 stud ~ 0.28 meters.
-- 1330km is astronomically large for a single Roblox instance (floating point breakdown occurs past 100,000 studs).
-- We will simulate the "Kalimantan" proportion using a massive chunk grid of 2000x2000 parts.
local CHUNK_SIZE = 2000
local GRID_WIDTH = 13 -- Represents the 1330 width proportion
local GRID_LENGTH = 10 -- Represents the 960 length proportion

local Seasons = {"Spring", "Dry", "Rain", "Winter"}
local CurrentSeasonIndex = 1

function MacroBiome.GenerateIsland()
    print("Initiating Macro-Biome Generation: Project KALIMANTAN...")
    local islandFolder = Instance.new("Folder")
    islandFolder.Name = "Kalimantan_Island"
    islandFolder.Parent = workspace

    -- Very rough grid mask approximating the shape of Kalimantan/Borneo
    -- 1 = Land, 0 = Ocean
    local islandMask = {
        {0,0,0,1,1,1,1,0,0,0},
        {0,0,1,1,1,1,1,1,0,0},
        {0,1,1,1,1,1,1,1,1,0},
        {1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,0},
        {0,1,1,1,1,1,1,1,0,0},
        {0,0,1,1,1,1,0,0,0,0},
        {0,0,0,1,1,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0}
    }

    -- Generate Chunks
    for x = 1, #islandMask do
        for z = 1, #(islandMask[x]) do
            if islandMask[x][z] == 1 then
                local chunkX = (x - (#islandMask/2)) * CHUNK_SIZE
                local chunkZ = (z - (#islandMask[1]/2)) * CHUNK_SIZE

                local chunk = Instance.new("Part")
                chunk.Name = "Chunk_" .. x .. "_" .. z
                chunk.Size = Vector3.new(CHUNK_SIZE, 50, CHUNK_SIZE)
                chunk.Position = Vector3.new(chunkX, 0, chunkZ)
                chunk.Anchored = true
                chunk.Color = Color3.fromRGB(34, 139, 34) -- Tropical Green
                chunk.Material = Enum.Material.Grass
                chunk.Parent = islandFolder

                -- Seed Monsters
                if math.random() > 0.5 then
                    local randomMonsterId = math.random(1, 100)
                    local spawnPos = Vector3.new(chunkX + math.random(-500, 500), 50, chunkZ + math.random(-500, 500))
                    MonsterManager.SpawnMonsterByData({
                        Name = "Island_Beast_"..randomMonsterId,
                        Health = 200, Damage = 25, Speed = 16, DropCoreLevel = math.random(1, 5),
                        Color = Color3.new(1,0,0), SpecialAbility = "None"
                    }, spawnPos)
                end

                -- Seed Furniture (Ruins/Loot points)
                if math.random() > 0.7 then
                    local randomFurnitureId = math.random(1, 10)
                    local spawnPos = Vector3.new(chunkX + math.random(-500, 500), 25, chunkZ + math.random(-500, 500))
                    FurnitureSystem.SpawnFurniture(randomFurnitureId, spawnPos, math.random(0, 360))
                end
            end
        end
    end

    print("Macro-Biome Generation Complete.")

    -- Start Dynamic Loops
    MacroBiome.StartSeasonLoop(islandFolder)
    MacroBiome.StartMeteorLoop()
end

function MacroBiome.StartSeasonLoop(islandFolder)
    task.spawn(function()
        while true do
            task.wait(300) -- Change season every 5 minutes
            CurrentSeasonIndex = CurrentSeasonIndex + 1
            if CurrentSeasonIndex > #Seasons then CurrentSeasonIndex = 1 end
            local newSeason = Seasons[CurrentSeasonIndex]

            print("Season changed to: " .. newSeason)

            -- Apply visual changes to the island based on season
            for _, chunk in ipairs(islandFolder:GetChildren()) do
                if chunk.Name:match("Chunk") then
                    if newSeason == "Winter" then
                        chunk.Color = Color3.fromRGB(240, 255, 255)
                        chunk.Material = Enum.Material.Ice
                    elseif newSeason == "Rain" then
                        chunk.Color = Color3.fromRGB(20, 80, 20)
                        chunk.Material = Enum.Material.Mud
                    elseif newSeason == "Dry" then
                        chunk.Color = Color3.fromRGB(210, 180, 140)
                        chunk.Material = Enum.Material.Sand
                    elseif newSeason == "Spring" then
                        chunk.Color = Color3.fromRGB(34, 139, 34)
                        chunk.Material = Enum.Material.Grass
                    end
                end
            end
        end
    end)
end

function MacroBiome.StartMeteorLoop()
    task.spawn(function()
        while true do
            task.wait(math.random(60, 180)) -- Random meteor every 1 to 3 minutes

            -- Pick a random chunk coordinate (rough estimation of island bounds)
            local targetX = math.random(-GRID_WIDTH/2, GRID_WIDTH/2) * CHUNK_SIZE
            local targetZ = math.random(-GRID_LENGTH/2, GRID_LENGTH/2) * CHUNK_SIZE
            local strikeZone = Vector3.new(targetX, 0, targetZ)

            print("METEOR WARNING: Incoming strike at " .. tostring(strikeZone))

            -- Visual warning (shadow)
            local shadow = Instance.new("Part")
            shadow.Shape = Enum.PartType.Cylinder
            shadow.Size = Vector3.new(1, 400, 400) -- Massive blast radius
            shadow.Position = strikeZone + Vector3.new(0, 51, 0)
            shadow.Orientation = Vector3.new(0, 0, 90)
            shadow.Anchored = true
            shadow.CanCollide = false
            shadow.Transparency = 0.5
            shadow.Color = Color3.fromRGB(0, 0, 0)
            shadow.Parent = workspace

            task.wait(3) -- 3 seconds to run

            -- The Strike
            local meteor = Instance.new("Part")
            meteor.Shape = Enum.PartType.Ball
            meteor.Size = Vector3.new(100, 100, 100)
            meteor.Position = strikeZone
            meteor.Anchored = true
            meteor.Color = Color3.fromRGB(255, 50, 0)
            meteor.Material = Enum.Material.Neon
            meteor.Parent = workspace

            -- Obliterate everything in radius
            local blastRadiusSq = 200 * 200

            -- Kill Players
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local pos = player.Character.HumanoidRootPart.Position
                    local distSq = (pos.X - strikeZone.X)^2 + (pos.Z - strikeZone.Z)^2
                    if distSq <= blastRadiusSq then
                        player.Character.Humanoid.Health = 0
                        print(player.Name .. " was obliterated by a meteor.")
                    end
                end
            end

            -- Kill Monsters
            for _, model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") and model:FindFirstChild("Humanoid") then
                    -- Exclude players
                    if not game.Players:GetPlayerFromCharacter(model) then
                        local root = model:FindFirstChild("HumanoidRootPart")
                        if root then
                            local distSq = (root.Position.X - strikeZone.X)^2 + (root.Position.Z - strikeZone.Z)^2
                            if distSq <= blastRadiusSq then
                                model.Humanoid.Health = 0
                                print("Monster obliterated by meteor.")
                            end
                        end
                    end
                end
            end

            task.wait(1)
            shadow:Destroy()
            meteor:Destroy()
        end
    end)
end

return MacroBiome
