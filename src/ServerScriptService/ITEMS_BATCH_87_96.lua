-- ITEMS_BATCH_87_96.lua (Handling Tasks ITEM_87 to ITEM_96)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch21 = {}

local LootItemsData = {
    [87] = {
        Id = "Military_Dog_Tags",
        Name = "Military Dog Tags",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 250,
        Color = Color3.fromRGB(150, 150, 150),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [88] = {
        Id = "Empty_Mana_Flask",
        Name = "Empty Mana Flask",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 10,
        Color = Color3.fromRGB(180, 200, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268"
    },
    [89] = {
        Id = "Heavy_Duty_Jack",
        Name = "Heavy Duty Jack",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 420,
        Color = Color3.fromRGB(200, 50, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [90] = {
        Id = "Geiger_Counter",
        Name = "Geiger Counter",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 850,
        Color = Color3.fromRGB(220, 220, 50),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [91] = {
        Id = "Demon_Horn",
        Name = "Demon Horn",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 1500,
        Color = Color3.fromRGB(150, 0, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    },
    [92] = {
        Id = "Cigarette_Pack",
        Name = "Pack of Cigarettes",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 45,
        Color = Color3.fromRGB(200, 200, 200),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [93] = {
        Id = "Industrial_Bleach",
        Name = "Industrial Bleach",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 110,
        Color = Color3.fromRGB(220, 220, 220),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [94] = {
        Id = "Diamond_Necklace",
        Name = "Diamond Necklace",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 2800,
        Color = Color3.fromRGB(200, 255, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268"
    },
    [95] = {
        Id = "Gun_Powder",
        Name = "Gun Powder",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 60,
        Color = Color3.fromRGB(30, 30, 30),
        Material = Enum.Material.Sand,
        MeshId = "rbxassetid://1060481268"
    },
    [96] = {
        Id = "Encrypted_Drive",
        Name = "Military Encrypted Drive",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 3500,
        Color = Color3.fromRGB(20, 20, 30),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch21.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 87, 96 do
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
    print("Registered Loot Items 87-96 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch21.SpawnPhysicalItem(id, position)
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

return LootItemSystemBatch21
