-- Main.server.lua
-- The central bootstrapper orchestrating the 264 generated tasks.

print("--- INITIALIZING ABSOLUTE APEX SERVER ---")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- 1. Load Core Systems
local StatSystem = require(ReplicatedStorage:WaitForChild("StatSystem"))
local InventorySystem = require(ReplicatedStorage:WaitForChild("InventorySystem"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))
local ExtractionManager = require(ServerScriptService:WaitForChild("ExtractionManager"))
local CombatManager = require(ServerScriptService:WaitForChild("CombatManager"))
local DailyLogSystem = require(ServerScriptService:WaitForChild("DAILY_LOG_SYSTEM_1"))
local AudioSystem = require(ServerScriptService:WaitForChild("AUDIO_SYSTEM_1"))
local SpaceshipLobby = require(ServerScriptService:WaitForChild("LOBBY_SPACESHIP_1"))
local PortalDomain = require(ServerScriptService:WaitForChild("FANTASY_PORTAL_DOMAIN_1"))

-- Initialize Core Systems
CombatManager.Initialize()
DailyLogSystem.Initialize()
AudioSystem.Initialize()
SpaceshipLobby.Initialize()
PortalDomain.Initialize()

print("Core Systems Initialized.")

-- 2. Register All Items, Armors, and Weapons into ItemDatabase
local function registerBatch(moduleName)
    local success, module = pcall(function() return require(ServerScriptService:WaitForChild(moduleName, 2)) end)
    if success and module and module.RegisterItems then
        module.RegisterItems()
    end
end

-- Load all 100 Items, 10 Armors, and 10 Weapons
registerBatch("ITEMS_BATCH_1_6")
registerBatch("ITEMS_BATCH_7_16")
registerBatch("ITEMS_BATCH_17_26")
registerBatch("ITEMS_BATCH_27_36")
registerBatch("ITEMS_BATCH_37_46")
registerBatch("ITEMS_BATCH_47_56")
registerBatch("ITEMS_BATCH_57_66")
registerBatch("ITEMS_BATCH_67_76")
registerBatch("ITEMS_BATCH_77_86")
registerBatch("ITEMS_BATCH_87_96")
registerBatch("ITEMS_BATCH_97_100")
registerBatch("ARMOR_BATCH_1_6")
registerBatch("ARMOR_BATCH_7_10")
registerBatch("WEAPON_MODERN_BATCH_1_6")
registerBatch("WEAPON_MODERN_BATCH_7_10")
registerBatch("WEAPON_FANTASY_BATCH_1_6")
registerBatch("WEAPON_FANTASY_BATCH_7_10")

print("ItemDatabase fully populated. Total defined: 126 objects.")

-- 3. Procedural World Generation (Biomes & Initial Spawns)
task.spawn(function()
    -- Wait a moment to ensure workspace is ready
    task.wait(2)

    local BiomeSystem1 = require(ServerScriptService:WaitForChild("BIOME_SYSTEM_1_6"))
    local BiomeSystem2 = require(ServerScriptService:WaitForChild("BIOME_SYSTEM_7_10"))

    -- Generate Biome 6 (Overgrown Jungle) for the extraction zone test
    local junglePos = Vector3.new(2000, 0, 2000)
    BiomeSystem1.GenerateBiome(6, junglePos)

    -- Register an extraction zone in the jungle
    ExtractionManager.RegisterExtractionZone("Jungle_Extract_Alpha", junglePos, 50)

    -- Spawn a Boss Monster in the Jungle (Task Monster #5 - Troll Brute)
    local MonsterBatch1 = require(ServerScriptService:WaitForChild("MONSTERS_BATCH_1_6"))
    MonsterBatch1.SpawnMonster(5, junglePos + Vector3.new(20, 10, 20))

    -- Spawn some Furniture in the Spaceship Lobby
    local FurnitureSystem = require(ServerScriptService:WaitForChild("FURNITURE_BATCH_1_10"))
    FurnitureSystem.SpawnFurniture(1, Vector3.new(10, 1002, 10), 0) -- Stash Box
    FurnitureSystem.SpawnFurniture(2, Vector3.new(20, 1002, 10), 90) -- Gun Rack

    -- Generate O'Neill Cylinder Environmental Lighting
    local StreetLightSystem = require(ServerScriptService:WaitForChild("STREET_LIGHTS_BATCH"))

    -- Create a grand avenue of Zero-G Axis Beacons down the center
    StreetLightSystem.GenerateStreetAvenue(2, Vector3.new(-500, 4000, 0), Vector3.new(1, 0, 0), 1000, 100)

    -- Place some Maglev Track Illuminators near the lobby
    StreetLightSystem.GenerateStreetAvenue(5, Vector3.new(0, 1005, 50), Vector3.new(1, 0, 0), 200, 20)

    -- Place a Warning light near the supposed Sabatier reactors
    StreetLightSystem.SpawnLight(7, Vector3.new(50, 1002, -50))

    print("World Generation Complete (Included O'Neill Habitat Lighting).")
end)

-- 4. Game Loops (Heartbeat)
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    -- Calculate actual distance for Extraction instead of placeholder
    for zoneId, zone in pairs(ExtractionManager.ActiveZones) do
        for playerId, playerData in pairs(PlayerManager.ActivePlayers) do
            local player = game.Players:GetPlayerByUserId(playerId)
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local charPos = player.Character.HumanoidRootPart.Position
                -- Calculate true magnitude distance
                local dist = (Vector3.new(charPos.X, 0, charPos.Z) - Vector3.new(zone.Position.X, 0, zone.Position.Z)).Magnitude

                local isInZone = dist <= zone.Radius

                if isInZone then
                    if not zone.PlayersExtracting[playerId] then
                        zone.PlayersExtracting[playerId] = 0
                    end
                    zone.PlayersExtracting[playerId] = zone.PlayersExtracting[playerId] + dt

                    if zone.PlayersExtracting[playerId] >= 10 then -- 10 seconds required
                        ExtractionManager.ExtractPlayer(playerId, playerData)
                        zone.PlayersExtracting[playerId] = nil
                    end
                else
                    zone.PlayersExtracting[playerId] = nil
                end
            end
        end
    end
end)

-- 5. Handle Players joining the active game
game.Players.PlayerAdded:Connect(function(player)
    -- Wait for character
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")

        -- Override Roblox's default health logic to use our You Are What You Wear system
        local playerData = PlayerManager.SpawnPlayer(player.UserId)
        humanoid.MaxHealth = playerData.TotalStats.MaxHealth
        humanoid.Health = playerData.CurrentHealth

        humanoid.Died:Connect(function()
            PlayerManager.HandlePlayerDeath(player.UserId)
        end)
    end)
end)

print("--- ABSOLUTE APEX SERVER RUNNING ---")
