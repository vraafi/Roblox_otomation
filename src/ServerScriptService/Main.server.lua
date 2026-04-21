local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerDataManager = require(ServerScriptService:WaitForChild("PlayerDataManager"))
local InventorySystem = require(ReplicatedStorage.Shared:WaitForChild("InventorySystem"))
local DestinyBoard = require(ReplicatedStorage.Shared:WaitForChild("DestinyBoard"))

local serverDestinyBoard = DestinyBoard.new()

Players.PlayerAdded:Connect(function(player)
    print("Player joined: " .. player.Name)

    -- Initialize basic data
    PlayerDataManager.InitializePlayer(player)

    -- Initialize individual systems
    local playerData = PlayerDataManager.GetPlayerData(player)
    if playerData then
        -- A basic hook-up example, real setup would be more complex
        playerData.Inventory = InventorySystem.new(100) -- Example capacity
        print("Initialized Albion systems for " .. player.Name)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    print("Player left: " .. player.Name)
    -- In a real scenario, we'd save data here
end)
