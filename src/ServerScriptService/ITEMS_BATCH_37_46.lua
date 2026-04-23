-- ITEMS_BATCH_37_46.lua (Handling Tasks ITEM_37 to ITEM_46)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch16 = {}

local LootItemsData = {
    [37] = {
        Id = "Ceramic_Plates",
        Name = "Ceramic Plates",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 180,
        Color = Color3.fromRGB(200, 200, 190),
        Material = Enum.Material.Marble,
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [38] = {
        Id = "Magic_Scroll",
        Name = "Magic Scroll",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 400,
        Color = Color3.fromRGB(220, 200, 150),
        Material = Enum.Material.Fabric,
        MeshId = "rbxassetid://1060481268"
    },
    [39] = {
        Id = "Titanium_Ingot",
        Name = "Titanium Ingot",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 1200,
        Color = Color3.fromRGB(190, 190, 200),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [40] = {
        Id = "Screwdriver",
        Name = "Screwdriver",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 20,
        Color = Color3.fromRGB(200, 50, 50),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [41] = {
        Id = "Alien_Artifact",
        Name = "Alien Artifact",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 3500,
        Color = Color3.fromRGB(50, 255, 100),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    },
    [42] = {
        Id = "Painkillers",
        Name = "Painkillers",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 150,
        Color = Color3.fromRGB(255, 255, 255),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [43] = {
        Id = "Car_Alternator",
        Name = "Car Alternator",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 220,
        Color = Color3.fromRGB(80, 80, 80),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [44] = {
        Id = "Demon_Blood",
        Name = "Vial of Demon Blood",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 850,
        Color = Color3.fromRGB(150, 0, 0),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268"
    },
    [45] = {
        Id = "CPU_Processor",
        Name = "CPU Processor",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 400,
        Color = Color3.fromRGB(50, 150, 50),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [46] = {
        Id = "Encrypted_Tablet",
        Name = "Encrypted Tablet",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 2800,
        Color = Color3.fromRGB(30, 30, 30),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch16.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 37, 46 do
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
    print("Registered Loot Items 37-46 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch16.SpawnPhysicalItem(id, position)
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

return LootItemSystemBatch16
