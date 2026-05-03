-- ITEMS_BATCH_BACKPACKS.lua
-- Defines the Backpacks and Safe Cases required for Arena Breakout inventory logic.

local BackpackBatch = {}

local BackpackData = {
    [1] = {
        Id = "Sling_Bag",
        Name = "Sling Bag",
        Type = "Backpack",
        GridWidth = 2,
        GridHeight = 2,
        InventoryWidth = 2,  -- How much space it provides when equipped
        InventoryHeight = 3, -- 6 slots total
        Weight = 0.6,
        Value = 500,
        Color = Color3.fromRGB(100, 100, 100),
        MeshId = "rbxassetid://444453051"
    },
    [2] = {
        Id = "Simple_Backpack",
        Name = "Simple Backpack",
        Type = "Backpack",
        GridWidth = 2,
        GridHeight = 3,
        InventoryWidth = 2,
        InventoryHeight = 4, -- 8 slots total
        Weight = 0.8,
        Value = 1200,
        Color = Color3.fromRGB(50, 80, 50),
        MeshId = "rbxassetid://123456789"
    },
    [3] = {
        Id = "Canvas_Backpack",
        Name = "Canvas Backpack",
        Type = "Backpack",
        GridWidth = 3,
        GridHeight = 3,
        InventoryWidth = 3,
        InventoryHeight = 3, -- 9 slots total
        Weight = 1.2,
        Value = 2500,
        Color = Color3.fromRGB(200, 180, 140),
        MeshId = "rbxassetid://645065406"
    },
    [4] = {
        Id = "Camping_Backpack",
        Name = "Heavy Camping Backpack",
        Type = "Backpack",
        GridWidth = 4,
        GridHeight = 4,
        InventoryWidth = 5,
        InventoryHeight = 5, -- 25 slots total
        Weight = 3.5,
        Value = 8000,
        Color = Color3.fromRGB(40, 60, 40),
        MeshId = "rbxassetid://430338781"
    },
    [5] = {
        Id = "Rush_Tactical_Bag",
        Name = "Rush Tactical Bag",
        Type = "Backpack",
        GridWidth = 4,
        GridHeight = 5,
        InventoryWidth = 4,
        InventoryHeight = 6, -- 24 slots total (taller, thinner)
        Weight = 2.8,
        Value = 12000,
        Color = Color3.fromRGB(20, 20, 20),
        MeshId = "rbxassetid://602494917"
    },
    [6] = {
        Id = "Cowhide_Backpack",
        Name = "Cowhide Leather Backpack",
        Type = "Backpack",
        GridWidth = 5,
        GridHeight = 5,
        InventoryWidth = 5,
        InventoryHeight = 7, -- 35 slots total
        Weight = 4.0,
        Value = 25000,
        Color = Color3.fromRGB(120, 70, 30),
        MeshId = "rbxassetid://602522771"
    }
}

function BackpackBatch.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for _, data in ipairs(BackpackData) do
        ItemDatabase.Items[data.Id] = {
            Id = data.Id,
            Name = data.Name,
            Type = data.Type,
            GridWidth = data.GridWidth,   -- Size it takes UP in an inventory
            GridHeight = data.GridHeight,
            InventoryWidth = data.InventoryWidth,   -- Size it GIVES when equipped
            InventoryHeight = data.InventoryHeight,
            Weight = data.Weight,
            Value = data.Value
        }
    end
    print("Registered Backpacks into ItemDatabase.")
end

return BackpackBatch
