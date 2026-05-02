-- ITEMS_BATCH_7_16.lua (Handling Tasks ITEM_7 to ITEM_16)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch13 = {}

local LootItemsData = {
    [7] = {
        Id = "Medical_Syringe",
        Name = "Medical Syringe",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 45,
        Color = Color3.fromRGB(200, 200, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://123456789" -- Placeholder
    },
    [8] = {
        Id = "Rusty_Gears",
        Name = "Rusty Gears",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 12,
        Color = Color3.fromRGB(130, 80, 50),
        Material = Enum.Material.CorrodedMetal,
        MeshId = "rbxassetid://382103444"
    },
    [9] = {
        Id = "Electric_Motor",
        Name = "Electric Motor",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 180,
        Color = Color3.fromRGB(100, 100, 100),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://645065406"
    },
    [10] = {
        Id = "Silver_Chain",
        Name = "Silver Chain",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 200,
        Color = Color3.fromRGB(220, 220, 220),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://382103444"
    },
    [11] = {
        Id = "Ancient_Tome",
        Name = "Ancient Tome",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 500,
        Color = Color3.fromRGB(80, 40, 20),
        Material = Enum.Material.Wood,
        MeshId = "rbxassetid://123456789"
    },
    [12] = {
        Id = "Mana_Crystal_Shard",
        Name = "Mana Crystal Shard",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 350,
        Color = Color3.fromRGB(50, 150, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://515665809"
    },
    [13] = {
        Id = "Military_Rations",
        Name = "MRE",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 25,
        Color = Color3.fromRGB(60, 80, 40),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://515665809"
    },
    [14] = {
        Id = "Weapon_Parts",
        Name = "Weapon Parts",
        GridWidth = 2,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 110,
        Color = Color3.fromRGB(50, 50, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://114425114"
    },
    [15] = {
        Id = "Golden_Chalice",
        Name = "Golden Chalice",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 1200,
        Color = Color3.fromRGB(255, 200, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://634289194"
    },
    [16] = {
        Id = "Intelligence_Folder",
        Name = "Intel Folder",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 850,
        Color = Color3.fromRGB(200, 180, 150),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://634289194"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch13.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 7, 16 do
        local data = LootItemsData[i]
        if data then
            ItemDatabase.Items[data.Id] = {
                Id = data.Id,
                Name = data.Name,
                Type = "ValuableLoot",
                GridWidth = data.GridWidth,
                GridHeight = data.GridHeight,
                Value = data.Value
            }
        end
    end
    print("Registered Loot Items 7-16 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch13.SpawnPhysicalItem(id, position)
    local data = nil
    for _, v in pairs(LootItemsData) do
        if v.Id == id then
            data = v
            break
        end
    end

    if not data then return end

    local part = Instance.new("Part")
    part.Name = data.Name
    -- Make the physical size roughly match its tetris scale (1 stud per grid slot)
    part.Size = Vector3.new(data.GridWidth, 0.5, data.GridHeight)
    part.Position = position
    part.Color = data.Color
    part.Material = data.Material
    part.Parent = workspace

    if data.MeshId then
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = data.MeshId
        mesh.Scale = part.Size -- Scale mesh to fit the grid dimensions
        mesh.Parent = part
    end

    -- In a real Roblox game, you would add a ProximityPrompt here
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pick Up"
    prompt.ObjectText = data.Name
    prompt.Parent = part

    prompt.Triggered:Connect(function(player)
        print(player.Name .. " picked up " .. data.Name .. " (Worth $" .. data.Value .. ", Size: " .. data.GridWidth .. "x" .. data.GridHeight .. ")")
        -- Call InventorySystem to add to Tetris Grid here
        part:Destroy()
    end)

    return part
end

return LootItemSystemBatch13
