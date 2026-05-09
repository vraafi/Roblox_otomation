-- Main.server.lua
-- Central server bootstrapper. Loads all systems, registers all items,
-- generates the world, and runs optimized game loops.

print("--- INITIALIZING ABSOLUTE APEX SERVER ---")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ============================================================
-- 1. REMOTE EVENTS (created before anything else to avoid races)
-- ============================================================
local events = ReplicatedStorage:FindFirstChild("Events")
if not events then
    events = Instance.new("Folder")
    events.Name   = "Events"
    events.Parent = ReplicatedStorage
end

local function ensureEvent(name, isFunction)
    if not events:FindFirstChild(name) then
        local ev = isFunction and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
        ev.Name   = name
        ev.Parent = events
    end
end

-- All remote events declared once, here, at server start
ensureEvent("ItemPickedUp",       false)
ensureEvent("FireWeapon",         false)
ensureEvent("ThrowGrenade",       false)
ensureEvent("NewMailAlert",       false)
ensureEvent("UpdateVitals",       false)
ensureEvent("UpdateLimbHUD",      false)
ensureEvent("UpdateStatusEffects",false)
ensureEvent("SeasonChanged",      false)
ensureEvent("MeteorWarning",      false)
ensureEvent("ReloadWeapon",       true)
ensureEvent("PackAmmo",           true)
ensureEvent("UseMedicalItem",     true)
ensureEvent("UseGearSkill",       true)
ensureEvent("MarketRequest",      true)
ensureEvent("OpenNPCShop",        false)  -- fires to client: (npcType string)

-- ============================================================
-- 2. LOAD CORE SYSTEMS
-- ============================================================
local StatSystem      = require(ReplicatedStorage:WaitForChild("StatSystem"))
local InventorySystem = require(ReplicatedStorage:WaitForChild("InventorySystem"))
local ItemDatabase    = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local HealthSystem    = require(ReplicatedStorage:WaitForChild("HealthSystem"))

local PlayerManager      = require(ServerScriptService:WaitForChild("PlayerManager"))
local ExtractionManager  = require(ServerScriptService:WaitForChild("ExtractionManager"))
local CombatManager      = require(ServerScriptService:WaitForChild("CombatManager"))
local AudioSystem        = require(ServerScriptService:WaitForChild("AUDIO_SYSTEM_1"))
local DailyLogSystem     = require(ServerScriptService:WaitForChild("DAILY_LOG_SYSTEM_1"))
local SpaceshipLobby     = require(ServerScriptService:WaitForChild("LOBBY_SPACESHIP_1"))
local SpaceshipMarket    = require(ServerScriptService:WaitForChild("SPACESHIP_MARKET"))
local PortalDomain       = require(ServerScriptService:WaitForChild("FANTASY_PORTAL_DOMAIN_1"))
local FleaMarketSystem   = require(ServerScriptService:WaitForChild("FleaMarketSystem"))
local LobbyStashSystem   = require(ServerScriptService:WaitForChild("LobbyStashSystem"))
local MailSystem         = require(ServerScriptService:WaitForChild("MailSystem"))
local LendingSystem      = require(ServerScriptService:WaitForChild("LendingSystem"))
local ExplosivesManager  = require(ServerScriptService:WaitForChild("ExplosivesManager"))
local GunsmithSystem     = require(ServerScriptService:WaitForChild("GunsmithSystem"))

-- Initialize systems
CombatManager.Initialize()
DailyLogSystem.Initialize()
AudioSystem.Initialize()
SpaceshipLobby.Initialize()
SpaceshipMarket.Initialize()   -- activates NPC sell/buy logic (no extra NPCs spawned — lobby handles them)
PortalDomain.Initialize()
FleaMarketSystem.Initialize()
LobbyStashSystem.Initialize()
MailSystem.Initialize()
LendingSystem.Initialize()
ExplosivesManager.Initialize()

print("[Main] Core systems initialized.")

-- ============================================================
-- 3. REGISTER ALL ITEMS / ARMORS / WEAPONS / BACKPACKS
-- ============================================================
local function registerBatch(moduleName)
    local ok, mod = pcall(function()
        return require(ServerScriptService:WaitForChild(moduleName, 3))
    end)
    if ok and mod and mod.RegisterItems then
        mod.RegisterItems()
    elseif not ok then
        warn("[Main] Failed to load batch: " .. moduleName .. " — " .. tostring(mod))
    end
end

local batches = {
    "ITEMS_BATCH_1_6",   "ITEMS_BATCH_7_16",  "ITEMS_BATCH_17_26",
    "ITEMS_BATCH_27_36", "ITEMS_BATCH_37_46", "ITEMS_BATCH_47_56",
    "ITEMS_BATCH_57_66", "ITEMS_BATCH_67_76", "ITEMS_BATCH_77_86",
    "ITEMS_BATCH_87_96", "ITEMS_BATCH_97_100","ITEMS_BATCH_BACKPACKS",
    "ARMOR_BATCH_1_6",   "ARMOR_BATCH_7_10",
    "WEAPON_MODERN_BATCH_1_6",  "WEAPON_MODERN_BATCH_7_10",
    "WEAPON_FANTASY_BATCH_1_6", "WEAPON_FANTASY_BATCH_7_10",
    "MONSTERS_BATCH_1_6",  "MONSTERS_BATCH_7_16",  "MONSTERS_BATCH_17_26",
    "MONSTERS_BATCH_27_36","MONSTERS_BATCH_37_46",  "MONSTERS_BATCH_47_56",
    "MONSTERS_BATCH_57_66","MONSTERS_BATCH_67_76",  "MONSTERS_BATCH_77_86",
    "MONSTERS_BATCH_87_96","MONSTERS_BATCH_97_100",
    "BIOME_SYSTEM_1_6",   "BIOME_SYSTEM_7_10",
    "WEATHER_DISASTER_BATCH_1_6", "WEATHER_DISASTER_BATCH_7_10",
}

for _, name in ipairs(batches) do
    registerBatch(name)
end

print("[Main] All 132+ item/monster/biome entries registered.")

-- ============================================================
-- 4. WORLD GENERATION (deferred, after workspace settles)
-- ============================================================
task.spawn(function()
    task.wait(2)

    local MacroBiome = require(ServerScriptService:WaitForChild("MACRO_BIOME_KALIMANTAN"))
    MacroBiome.GenerateIsland()

    -- Register extraction zones
    ExtractionManager.RegisterExtractionZone("Kalimantan_Extract_Alpha", Vector3.new(0, 0, 0), 50)
    ExtractionManager.RegisterExtractionZone("Kalimantan_Extract_Beta",  Vector3.new(1500, 0, -1200), 50)
    ExtractionManager.RegisterExtractionZone("Kalimantan_Extract_Gamma", Vector3.new(-1800, 0, 800), 50)

    -- Spaceship lobby furniture
    local FurnitureSys = require(ServerScriptService:WaitForChild("FURNITURE_BATCH_1_10"))
    FurnitureSys.SpawnFurniture(1,  Vector3.new(10,  1002, 10),  0)   -- Stash Box
    FurnitureSys.SpawnFurniture(2,  Vector3.new(25,  1002, 10),  90)  -- Gun Rack
    FurnitureSys.SpawnFurniture(3,  Vector3.new(40,  1002, 10),  0)   -- Medical Fridge
    FurnitureSys.SpawnFurniture(8,  Vector3.new(-10, 1002, 20),  180) -- Alchemy Table
    FurnitureSys.SpawnFurniture(10, Vector3.new(0,   1002, -20), 0)   -- Apex Storage Core

    -- Spaceship ambient lighting
    local LightSys = require(ServerScriptService:WaitForChild("STREET_LIGHTS_BATCH"))
    LightSys.GenerateStreetAvenue(2, Vector3.new(-500, 4000, 0), Vector3.new(1, 0, 0), 1000, 100)
    LightSys.GenerateStreetAvenue(5, Vector3.new(0, 1005, 50),   Vector3.new(1, 0, 0), 200, 20)
    LightSys.SpawnLight(7, Vector3.new(50, 1002, -50))

    print("[Main] World generation complete.")
end)

-- ============================================================
-- 5. PLAYER LIFECYCLE
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    -- Initialize player data on join (before character)
    local playerData = PlayerManager.SpawnPlayer(player.UserId)

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")

        -- Apply limb-based health pool
        if playerData and playerData.HealthProfile then
            local totalCurrent, totalMax = 0, 0
            for _, limb in pairs(playerData.HealthProfile.Limbs) do
                totalCurrent = totalCurrent + limb.Current
                totalMax     = totalMax + 100
            end
            humanoid.MaxHealth = totalMax
            humanoid.Health    = totalCurrent
        end

        -- Death handler
        humanoid.Died:Connect(function()
            PlayerManager.HandlePlayerDeath(player.UserId)
        end)

        -- Fall damage
        local fallStartY = 0
        humanoid.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Freefall then
                fallStartY = character:GetPivot().Position.Y
            elseif newState == Enum.HumanoidStateType.Landed then
                local fallen = fallStartY - character:GetPivot().Position.Y
                if fallen > 3.5 then
                    PlayerManager.ApplyFallDamage(player, fallen)
                end
            end
        end)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Clean up player data to prevent memory leaks
    if PlayerManager.ActivePlayers then
        PlayerManager.ActivePlayers[player.UserId] = nil
    end
end)

-- ============================================================
-- 6. OPTIMIZED EXTRACTION LOOP
-- ============================================================
-- Runs every 0.1s (throttled) instead of every Heartbeat frame.
-- Caches references outside the loop.
local extractionAccum = 0
RunService.Heartbeat:Connect(function(dt)
    extractionAccum = extractionAccum + dt
    if extractionAccum < 0.1 then return end
    extractionAccum = 0

    for zoneId, zone in pairs(ExtractionManager.ActiveZones) do
        for playerId, playerData in pairs(PlayerManager.ActivePlayers) do
            local plr = Players:GetPlayerByUserId(playerId)
            if plr and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local pos   = root.Position
                    local zPos  = zone.Position
                    local distSq = (pos.X - zPos.X) ^ 2 + (pos.Z - zPos.Z) ^ 2
                    local inZone = distSq <= (zone.Radius * zone.Radius)

                    if inZone then
                        zone.PlayersExtracting[playerId] = (zone.PlayersExtracting[playerId] or 0) + 0.1
                        if zone.PlayersExtracting[playerId] >= 10 then
                            ExtractionManager.ExtractPlayer(playerId, playerData)
                            zone.PlayersExtracting[playerId] = nil
                        end
                    else
                        zone.PlayersExtracting[playerId] = nil
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- 7. STATUS SYNC LOOP (0.5s, cached module references)
-- ============================================================
task.spawn(function()
    -- Cache module references OUTSIDE the loop (critical perf fix)
    local updateLimbEv   = events:WaitForChild("UpdateLimbHUD",       10)
    local updateStatusEv = events:WaitForChild("UpdateStatusEffects",  10)
    local updateVitalsEv = events:WaitForChild("UpdateVitals",         10)
    local limbs          = HealthSystem.Limbs

    while task.wait(0.5) do
        for _, plr in ipairs(Players:GetPlayers()) do
            local pData = PlayerManager.ActivePlayers[plr.UserId]
            if pData and pData.HealthProfile then
                -- Limb HUD
                if updateLimbEv then
                    local uiData = {}
                    for limbName, limbData in pairs(pData.HealthProfile.Limbs) do
                        local maxHP = (limbs[limbName] and limbs[limbName].Max) or 100
                        uiData[limbName] = {
                            CurrentHP = limbData.Current,
                            MaxHP     = maxHP,
                            Status    = limbData.IsBlackedOut and "Destroyed" or
                                        (limbData.Current < maxHP * 0.4 and "Injured" or "Healthy"),
                        }
                    end
                    updateLimbEv:FireClient(plr, uiData)
                end

                -- Status effects
                if updateStatusEv then
                    updateStatusEv:FireClient(plr, pData.HealthProfile.StatusEffects)
                end

                -- Vitals (HP + mana)
                if updateVitalsEv then
                    local curHP, maxHP = 0, 0
                    for _, lData in pairs(pData.HealthProfile.Limbs) do
                        curHP = curHP + lData.Current
                    end
                    for _, lDef in pairs(limbs) do
                        maxHP = maxHP + lDef.Max
                    end
                    updateVitalsEv:FireClient(plr,
                        curHP, maxHP,
                        pData.CurrentMana or 0,
                        (pData.TotalStats and pData.TotalStats.MaxMana) or 0
                    )
                end
            end
        end
    end
end)

print("--- ABSOLUTE APEX SERVER RUNNING ---")
