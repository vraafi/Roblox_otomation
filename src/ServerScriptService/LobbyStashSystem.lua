-- LobbyStashSystem.lua
-- Manages the persistent, upgradeable player stash in the Spaceship Lobby (Arena Breakout style).

local LobbyStashSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DailyLogSystem = require(ServerScriptService:WaitForChild("DAILY_LOG_SYSTEM_1"))

-- Format: { [UserId] = { Rows = 10, Cols = 10, Items = {} } }
LobbyStashSystem.PlayerStashes = {}

-- Prices for upgrading the stash size
local UPGRADE_PRICES = {
    [1] = { Cost = 5000, NewRows = 15 },
    [2] = { Cost = 15000, NewRows = 20 },
    [3] = { Cost = 50000, NewRows = 30 }
}

function LobbyStashSystem.Initialize()
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then
        events = Instance.new("Folder")
        events.Name = "Events"
        events.Parent = ReplicatedStorage
    end

    local stashUpgradeEvent = events:FindFirstChild("StashUpgradeRequest")
    if not stashUpgradeEvent then
        stashUpgradeEvent = Instance.new("RemoteFunction")
        stashUpgradeEvent.Name = "StashUpgradeRequest"
        stashUpgradeEvent.Parent = events
    end

    stashUpgradeEvent.OnServerInvoke = LobbyStashSystem.HandleUpgradeRequest

    game.Players.PlayerAdded:Connect(LobbyStashSystem.LoadStash)
    game.Players.PlayerRemoving:Connect(LobbyStashSystem.SaveStash)

    print("Lobby Stash System initialized.")
end

function LobbyStashSystem.LoadStash(player)
    -- In a real game, this uses DataStoreService to load persistent data
    LobbyStashSystem.PlayerStashes[player.UserId] = {
        Level = 0,
        Rows = 10,
        Cols = 10,
        Items = {}
    }
end

function LobbyStashSystem.SaveStash(player)
    -- Use DataStoreService here to save
    LobbyStashSystem.PlayerStashes[player.UserId] = nil
end

function LobbyStashSystem.HandleUpgradeRequest(player)
    local stash = LobbyStashSystem.PlayerStashes[player.UserId]
    if not stash then return false, "Stash data not loaded." end

    local nextLevel = stash.Level + 1
    local upgradeData = UPGRADE_PRICES[nextLevel]

    if not upgradeData then
        return false, "Stash is already at maximum level."
    end

    local pData = _G.PlayerEconomies and _G.PlayerEconomies[player.UserId]
    if not pData then return false, "Economy data missing." end

    if pData.TotalDollars >= upgradeData.Cost then
        pData.TotalDollars = pData.TotalDollars - upgradeData.Cost
        stash.Level = nextLevel
        stash.Rows = upgradeData.NewRows
        print(player.Name .. " upgraded their Lobby Stash to Level " .. nextLevel .. " for $" .. upgradeData.Cost)
        return true, "Stash upgraded successfully! New Capacity: " .. stash.Cols .. "x" .. stash.Rows
    else
        return false, "Not enough Dollars. Need $" .. upgradeData.Cost
    end
end

-- When a player successfully extracts, call this to transfer items from their Backpack to the Stash
function LobbyStashSystem.DepositExtractedLoot(player, inventory)
    local stash = LobbyStashSystem.PlayerStashes[player.UserId]
    if not stash then return end

    -- In a real game, we'd calculate grid geometry here.
    -- For now, just append items to the list.
    for _, itemId in ipairs(inventory.Items) do
        table.insert(stash.Items, itemId)
    end

    -- Empty the player's active raid inventory (excluding equipped gear and safe case)
    inventory.Items = {}

    print(player.Name .. " deposited their extracted loot into the Lobby Stash.")
end

return LobbyStashSystem
