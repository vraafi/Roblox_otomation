-- ITEMS_BATCH_27_36.lua (Handling Tasks ITEM_27 to ITEM_36)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch15 = {}

local LootItemsData = {
    [27] = {
        Id = "Gunpowder_Flask",
        Name = "Gunpowder Flask",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 55,
        Color = Color3.fromRGB(80, 80, 80),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [28] = {
        Id = "Spark_Plug",
        Name = "Spark Plug",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 15,
        Color = Color3.fromRGB(200, 200, 200),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [29] = {
        Id = "Encrypted_HDD",
        Name = "Encrypted HDD",
        GridWidth = 2,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 2500,
        Color = Color3.fromRGB(30, 30, 30),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [30] = {
        Id = "Platinum_Ring",
        Name = "Platinum Ring",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 850,
        Color = Color3.fromRGB(229, 228, 226),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [31] = {
        Id = "Kevlar_Scrap",
        Name = "Kevlar Scrap",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 120,
        Color = Color3.fromRGB(50, 50, 40),
        Material = Enum.Material.Fabric,
        MeshId = "rbxassetid://1060481268"
    },
    [32] = {
        Id = "Healing_Herb",
        Name = "Healing Herb",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 60,
        Color = Color3.fromRGB(50, 200, 50),
        Material = Enum.Material.Grass,
        MeshId = "rbxassetid://1060481268"
    },
    [33] = {
        Id = "Telescope_Lens",
        Name = "Telescope Lens",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 320,
        Color = Color3.fromRGB(200, 255, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268"
    },
    [34] = {
        Id = "Dragon_Scale",
        Name = "Dragon Scale",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 1500,
        Color = Color3.fromRGB(200, 20, 20),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    },
    [35] = {
        Id = "Military_Radio",
        Name = "Military Radio",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 450,
        Color = Color3.fromRGB(40, 60, 40),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [36] = {
        Id = "Gold_Bar",
        Name = "Gold Bar",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 5000,
        Color = Color3.fromRGB(255, 215, 0),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch15.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 27, 36 do
        local data = LootItemsData[i]
        if data then
            ItemDatabase.Items[data.Id] = {
                Id = data.Id,
                Name = data.Name,
                Type = "ValuableLoot",
                GridWidth = data.GridWidth,
                GridHeight = data.GridHeight or 1,
                Value = data.Value
            }
        end
    end
    print("Registered Loot Items 27-36 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch15.SpawnPhysicalItem(id, position)
    local data = nil
    for _, v in pairs(LootItemsData) do
        if v.Id == id then
            data = v
            break
        end
    end

    if not data then return end

    local height = data.GridHeight or 1

    local part = Instance.new("Part")
    part.Name = data.Name
    -- Make the physical size roughly match its tetris scale (1 stud per grid slot)
    part.Size = Vector3.new(data.GridWidth, 0.5, height)
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
        print(player.Name .. " picked up " .. data.Name .. " (Worth $" .. data.Value .. ", Size: " .. data.GridWidth .. "x" .. height .. ")")
        -- Call InventorySystem to add to Tetris Grid here
        part:Destroy()
    end)

    return part
end

return LootItemSystemBatch15
