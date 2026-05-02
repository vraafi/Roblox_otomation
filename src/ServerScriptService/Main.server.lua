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
local FleaMarketSystem = require(ServerScriptService:WaitForChild("FleaMarketSystem"))
local LobbyStashSystem = require(ServerScriptService:WaitForChild("LobbyStashSystem"))
local MailSystem = require(ServerScriptService:WaitForChild("MailSystem"))
local LendingSystem = require(ServerScriptService:WaitForChild("LendingSystem"))
local ExplosivesManager = require(ServerScriptService:WaitForChild("ExplosivesManager"))
local GunsmithSystem = require(ServerScriptService:WaitForChild("GunsmithSystem"))

-- Fix RemoteEvent Race Condition: Create RemoteEvents immediately
local events = ReplicatedStorage:FindFirstChild("Events")
if not events then
    events = Instance.new("Folder")
    events.Name = "Events"
    events.Parent = ReplicatedStorage
end
local pickupEvent = events:FindFirstChild("ItemPickedUp")
if not pickupEvent then
    pickupEvent = Instance.new("RemoteEvent")
    pickupEvent.Name = "ItemPickedUp"
    pickupEvent.Parent = events
end

-- Initialize Core Systems
CombatManager.Initialize()
DailyLogSystem.Initialize()
AudioSystem.Initialize()
SpaceshipLobby.Initialize()
PortalDomain.Initialize()
FleaMarketSystem.Initialize()
LobbyStashSystem.Initialize()
MailSystem.Initialize()
LendingSystem.Initialize()
ExplosivesManager.Initialize()

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
registerBatch("ITEMS_BATCH_BACKPACKS")

print("ItemDatabase fully populated. Total defined: 132 objects.")

-- 3. Procedural World Generation (Biomes & Initial Spawns)
task.spawn(function()
    -- Wait a moment to ensure workspace is ready
    task.wait(2)

    -- Generate the massive Tropical Kalimantan Island macro-biome
    local MacroBiome = require(ServerScriptService:WaitForChild("MACRO_BIOME_KALIMANTAN"))
    MacroBiome.GenerateIsland()

    -- Register an extraction zone in the center of the island
    ExtractionManager.RegisterExtractionZone("Kalimantan_Extract_Alpha", Vector3.new(0, 0, 0), 50)

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
        -- Sum up health from the limbs for the Roblox humanoid display
        local totalMax = 0
        local totalCurrent = 0
        for _, limb in pairs(playerData.HealthProfile.Limbs) do
            totalMax = totalMax + 100 -- approximate or read from HealthSystem
            totalCurrent = totalCurrent + limb.Current
        end
        humanoid.MaxHealth = totalMax
        humanoid.Health = totalCurrent

        humanoid.Died:Connect(function()
            PlayerManager.HandlePlayerDeath(player.UserId)
        end)

        -- Fall Damage tracking
        local fallStartY = 0
        humanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Freefall then
                fallStartY = character:GetPivot().Position.Y
            elseif newState == Enum.HumanoidStateType.Landed then
                local fallEndY = character:GetPivot().Position.Y
                local distanceFallen = fallStartY - fallEndY

                if distanceFallen > 3.5 then -- Only calculate if falling more than 1 meter (3.5 studs)
                    PlayerManager.ApplyFallDamage(player, distanceFallen)
                end
            end
        end)
    end)
end)

print("--- ABSOLUTE APEX SERVER RUNNING ---")
local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
if not events then
    events = Instance.new("Folder")
    events.Name = "Events"
    events.Parent = game:GetService("ReplicatedStorage")
end

local function ensureEvent(name, isFunction)
    if not events:FindFirstChild(name) then
        local ev = isFunction and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
        ev.Name = name
        ev.Parent = events
    end
end

ensureEvent("FireWeapon", false)
ensureEvent("ReloadWeapon", true)
ensureEvent("PackAmmo", true)
ensureEvent("UseMedicalItem", true)
ensureEvent("ThrowGrenade", false)
ensureEvent("UseGearSkill", true)
ensureEvent("NewMailAlert", false)
ensureEvent("UpdateVitals", false)
ensureEvent("UpdateLimbHUD", false)
ensureEvent("UpdateStatusEffects", false)


-- Status synchronization loop
task.spawn(function()
    while task.wait(0.5) do
        for _, player in pairs(game.Players:GetPlayers()) do
            local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
            local playerData = PlayerManager.ActivePlayers[player.UserId]
            if playerData and playerData.HealthProfile then
                local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
                if events then
                    local updateLimb = events:FindFirstChild("UpdateLimbHUD")
                    if updateLimb then
                        local uiData = {}
                        for limbName, data in pairs(playerData.HealthProfile.Limbs) do
                            uiData[limbName] = {
                                CurrentHP = data.Current,
                                MaxHP = require(game.ReplicatedStorage.HealthSystem).Limbs[limbName].Max,
                                Status = data.IsBlackedOut and "Destroyed" or "Healthy"
                            }
                        end
                        updateLimb:FireClient(player, uiData)
                    end

                    local updateStatus = events:FindFirstChild("UpdateStatusEffects")
                    if updateStatus then
                        updateStatus:FireClient(player, playerData.HealthProfile.StatusEffects)
                    end

                    local updateVitals = events:FindFirstChild("UpdateVitals")
                    if updateVitals then
                        -- Send (health, maxHealth, mana, maxMana)
                        -- Health is summed up from limbs
                        local currentHP = 0
                        local maxHP = 0
                        for _, data in pairs(playerData.HealthProfile.Limbs) do
                            currentHP = currentHP + data.Current
                        end
                        for _, data in pairs(require(game.ReplicatedStorage.HealthSystem).Limbs) do
                            maxHP = maxHP + data.Max
                        end
                        updateVitals:FireClient(player, currentHP, maxHP, playerData.CurrentMana, playerData.TotalStats.MaxMana)
                    end
                end
            end
        end
    end
end)
