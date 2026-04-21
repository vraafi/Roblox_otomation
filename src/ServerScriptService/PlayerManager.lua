-- PlayerManager.lua
-- Manages players, their state, and ties Stats and Inventory together.

local PlayerManager = {}

-- Fallbacks for non-Roblox env testing
local StatSystem = require(script.Parent.Parent.ReplicatedStorage.StatSystem)
local InventorySystem = require(script.Parent.Parent.ReplicatedStorage.InventorySystem)

PlayerManager.ActivePlayers = {}

function PlayerManager.SpawnPlayer(playerId)
    -- Create new inventory
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

-- Handles death (Arena Breakout logic: lose everything un-secured)
function PlayerManager.HandlePlayerDeath(playerId)
    local playerData = PlayerManager.ActivePlayers[playerId]
    if not playerData then return end

    playerData.Status = "Dead"

    -- Drop all items in inventory and equipped gear to a physical loot box in the world
    -- (In a real Roblox script, spawn a Model with a ProximityPrompt here)

    -- Wipe inventory
    playerData.Inventory = InventorySystem.NewInventory()
    PlayerManager.UpdatePlayerStats(playerId)

    print("Player " .. playerId .. " died and lost all their gear.")
end

return PlayerManager
