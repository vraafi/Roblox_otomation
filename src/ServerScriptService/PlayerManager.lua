-- PlayerManager.lua
-- Manages players, their state, and ties Stats and Inventory together.

local PlayerManager = {}

-- Fallbacks for non-Roblox env testing
local StatSystem = require(script.Parent.Parent.ReplicatedStorage.StatSystem)
local InventorySystem = require(script.Parent.Parent.ReplicatedStorage.InventorySystem)
local HealthSystem = require(script.Parent.Parent.ReplicatedStorage.HealthSystem)

PlayerManager.ActivePlayers = {}

function PlayerManager.SpawnPlayer(playerId)
    -- Prevent wiping existing inventory if they already exist (e.g. respawning in lobby after extract)
    if PlayerManager.ActivePlayers[playerId] then
        local existingData = PlayerManager.ActivePlayers[playerId]
        existingData.CurrentHealth = existingData.TotalStats.MaxHealth
        existingData.Status = "Alive"
        return existingData
    end

    -- Create new inventory for brand new players
    local inv = InventorySystem.NewInventory()

    -- Base naked stats initially
    local stats = StatSystem.CalculateTotalStats(inv.Equipped)

    local playerData = {
        Id = playerId,
        Inventory = inv,
        TotalStats = stats,
        CurrentHealth = stats.MaxHealth,
        CurrentMana = stats.MaxMana,
        Status = "Alive"
    }

    PlayerManager.ActivePlayers[playerId] = playerData
    return playerData
end

-- Called when a player equips or unequips gear
function PlayerManager.UpdatePlayerStats(playerId)
    local playerData = PlayerManager.ActivePlayers[playerId]
    if not playerData then return end

    -- Recalculate based on 'You are what you wear'
    local newStats = StatSystem.CalculateTotalStats(playerData.Inventory.Equipped)

    -- Adjust current health/mana to not exceed new maximums
    playerData.CurrentHealth = math.min(playerData.CurrentHealth, newStats.MaxHealth)
    playerData.CurrentMana = math.min(playerData.CurrentMana, newStats.MaxMana)

    -- If they had 0 mana and equipped a mage robe, they don't get free mana, it must regenerate or use potion
    -- But if max health drops below current health, current health is clamped above.

    playerData.TotalStats = newStats
end

function PlayerManager.ApplyFallDamage(player, fallDistanceStuds)
    local playerData = PlayerManager.ActivePlayers[player.UserId]
    if not playerData then return end

    -- 1 meter is roughly 3.5 studs in Roblox
    local fallDistanceMeters = fallDistanceStuds / 3.5

    local fallResult = StatSystem.CalculateFallDamage(fallDistanceMeters)

    if fallResult.LegDamage > 0 then
        local ServerScriptService = game:GetService("ServerScriptService")
        local SpaceshipLobby = require(ServerScriptService:WaitForChild("LOBBY_SPACESHIP_1"))

        -- Attempt to apply damage specifically to the Left/Right Leg in the Arena Breakout Limb System
        if SpaceshipLobby.ApplyDamage then
            -- Randomly pick a leg
            local hitLeg = math.random() > 0.5 and "LeftLeg" or "RightLeg"
            SpaceshipLobby.ApplyDamage(player, hitLeg, fallResult.LegDamage)
            print(player.Name .. " took " .. fallResult.LegDamage .. " damage to " .. hitLeg .. " from falling " .. string.format("%.1f", fallDistanceMeters) .. "m.")
        else
            -- Fallback if Lobby system isn't loaded
            playerData.CurrentHealth = math.max(0, playerData.CurrentHealth - fallResult.LegDamage)
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.Health = playerData.CurrentHealth
            end
        end

        if fallResult.BrokenLeg then
            playerData.Status = "BrokenLeg"
            print(player.Name .. " suffered a BROKEN LEG.")
            -- Force walk speed down severely
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.WalkSpeed = 5
            end
        end
    end
end

-- Handles death (Arena Breakout logic: lose everything un-secured)
-- Handles death (Arena Breakout logic: lose everything un-secured, keep Safe Case)
function PlayerManager.HandlePlayerDeath(playerId)
    local playerData = PlayerManager.ActivePlayers[playerId]
    if not playerData then return end

    playerData.Status = "Dead"

    -- Drop all regular items in inventory and equipped gear to a physical loot box in the world
    -- (In a real Roblox script, spawn a Model with a ProximityPrompt here)

    -- Preserve Safe Case contents
    local preservedSafeCase = playerData.Inventory.SafeCase

    -- Wipe inventory
    playerData.Inventory = InventorySystem.NewInventory()

    -- Restore Safe Case contents
    playerData.Inventory.SafeCase = preservedSafeCase

    PlayerManager.UpdatePlayerStats(playerId)

    print("Player " .. playerId .. " died. Lost gear, but kept Safe Case items.")
end


function PlayerManager.UseMedicalItem(playerId, itemId, targetLimb)
    local playerData = PlayerManager.ActivePlayers[playerId]
    if not playerData then return false, "Player not found" end

    local itemData = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase).GetItem(itemId)
    if not itemData or itemData.Type ~= "Consumable" then return false, "Invalid item" end

    -- In a real game, remove from inventory here.

    local ServerScriptService = game:GetService("ServerScriptService")
    local SpaceshipLobby = require(ServerScriptService:WaitForChild("LOBBY_SPACESHIP_1"))

    if SpaceshipLobby.PlayerHealthData and SpaceshipLobby.PlayerHealthData[playerId] then
        local healthData = SpaceshipLobby.PlayerHealthData[playerId]

        if itemData.StopsBleeding then
            for i, ailment in ipairs(healthData.Ailments) do
                if ailment == "Bleeding" then
                    table.remove(healthData.Ailments, i)
                    break
                end
            end
        end

        if itemData.FixesLimb and targetLimb and healthData[targetLimb] then
            if healthData[targetLimb].Status == "Destroyed" then
                healthData[targetLimb].Status = "Healthy"
                healthData[targetLimb].CurrentHP = 1 -- Barely fixed

                -- Remove broken bone ailments related to this limb
                for i = #healthData.Ailments, 1, -1 do
                    if healthData.Ailments[i] == "Broken" .. targetLimb then
                        table.remove(healthData.Ailments, i)
                    end
                end

                return true, "Fixed " .. targetLimb
            end
        end

        if itemData.HealAmount > 0 and targetLimb and healthData[targetLimb] then
             if healthData[targetLimb].Status ~= "Destroyed" then
                 healthData[targetLimb].CurrentHP = math.min(healthData[targetLimb].MaxHP, healthData[targetLimb].CurrentHP + itemData.HealAmount)
                 return true, "Healed " .. targetLimb
             else
                 return false, "Cannot heal a destroyed limb without surgery."
             end
        end
    end

    return true, "Item used"
end
return PlayerManager
