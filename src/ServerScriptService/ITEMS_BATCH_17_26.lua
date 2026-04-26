-- ITEMS_BATCH_17_26.lua (Handling Tasks ITEM_17 to ITEM_26)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch14 = {}

local LootItemsData = {
    [17] = {
        Id = "Copper_Wire",
        Name = "Copper Wire",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 18,
        Color = Color3.fromRGB(184, 115, 51),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [18] = {
        Id = "Duct_Tape",
        Name = "Duct Tape",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 25,
        Color = Color3.fromRGB(160, 160, 160),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [19] = {
        Id = "Tool_Kit",
        Name = "Tool Kit",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 350,
        Color = Color3.fromRGB(200, 50, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [20] = {
        Id = "Antique_Vase",
        Name = "Antique Vase",
        GridWidth = 2,
        GridHeight = 3,
        Weight = math.random(1, 10),
        Value = 1500,
        Color = Color3.fromRGB(150, 200, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268"
    },
    [21] = {
        Id = "Broken_LCD",
        Name = "Broken LCD Screen",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 40,
        Color = Color3.fromRGB(20, 20, 20),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268"
    },
    [22] = {
        Id = "Morphine_Injector",
        Name = "Morphine Injector",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 250,
        Color = Color3.fromRGB(255, 255, 255),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [23] = {
        Id = "Water_Filter",
        Name = "Water Filter",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 180,
        Color = Color3.fromRGB(200, 200, 200),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [24] = {
        Id = "Ruby_Gemstone",
        Name = "Ruby Gemstone",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 2000,
        Color = Color3.fromRGB(255, 20, 20),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    },
    [25] = {
        Id = "Canned_Meat",
        Name = "Canned Meat",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 35,
        Color = Color3.fromRGB(180, 180, 150),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [26] = {
        Id = "Drone_Battery",
        Name = "Military Drone Battery",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 950,
        Color = Color3.fromRGB(80, 80, 80),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch14.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 17, 26 do
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
    print("Registered Loot Items 17-26 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch14.SpawnPhysicalItem(id, position)
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

return LootItemSystemBatch14
