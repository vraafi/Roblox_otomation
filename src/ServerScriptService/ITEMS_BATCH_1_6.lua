-- ITEMS_BATCH_1_6.lua (Handling Tasks ITEM_1 to ITEM_6)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch12 = {}

local LootItemsData = {
    [1] = {
        Id = "Scrap_Metal",
        Name = "Scrap Metal",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 5,
        Color = Color3.fromRGB(150, 150, 150),
        Material = Enum.Material.CorrodedMetal,
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [2] = {
        Id = "Gold_Watch",
        Name = "Gold Watch",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 150,
        Color = Color3.fromRGB(255, 215, 0),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [3] = {
        Id = "Car_Battery",
        Name = "Car Battery",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 300,
        Color = Color3.fromRGB(20, 20, 20),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [4] = {
        Id = "Fuel_Canister",
        Name = "Fuel Canister",
        GridWidth = 2,
        GridHeight = 3,
        Weight = math.random(1, 10),
        Value = 80,
        Color = Color3.fromRGB(200, 50, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [5] = {
        Id = "GPU_Card",
        Name = "GPU Card",
        GridWidth = 2,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 800,
        Color = Color3.fromRGB(50, 50, 50),
        Material = Enum.Material.Slate,
        MeshId = "rbxassetid://1060481268"
    },
    [6] = {
        Id = "Encrypted_FlashDrive",
        Name = "Encrypted Flash Drive",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 1500,
        Color = Color3.fromRGB(20, 150, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch12.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 1, 6 do
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
    print("Registered Loot Items 1-6 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch12.SpawnPhysicalItem(id, position)
    -- Find data by ID
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
        print(player.Name .. " picked up " .. data.Name .. " (Worth $" .. data.Value .. ")")
        -- Call InventorySystem to add to Tetris Grid here
        part:Destroy()
    end)

    return part
end

return LootItemSystemBatch12
