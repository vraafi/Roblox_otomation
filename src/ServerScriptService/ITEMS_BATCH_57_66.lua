-- ITEMS_BATCH_57_66.lua (Handling Tasks ITEM_57 to ITEM_66)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch18 = {}

local LootItemsData = {
    [57] = {
        Id = "Empty_Syringe",
        Name = "Empty Syringe",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 5,
        Color = Color3.fromRGB(200, 200, 200),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [58] = {
        Id = "Gas_Mask_Filter",
        Name = "Gas Mask Filter",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 150,
        Color = Color3.fromRGB(60, 60, 60),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [59] = {
        Id = "Military_Flashlight",
        Name = "Military Flashlight",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 85,
        Color = Color3.fromRGB(40, 50, 40),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [60] = {
        Id = "Cursed_Amulet",
        Name = "Cursed Amulet",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 2000,
        Color = Color3.fromRGB(100, 0, 150),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    },
    [61] = {
        Id = "Car_Jack",
        Name = "Car Jack",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 300,
        Color = Color3.fromRGB(200, 50, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [62] = {
        Id = "Purified_Water",
        Name = "Purified Water Bottle",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 40,
        Color = Color3.fromRGB(150, 200, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268"
    },
    [63] = {
        Id = "Drone_Camera",
        Name = "Drone Camera Module",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 550,
        Color = Color3.fromRGB(30, 30, 30),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [64] = {
        Id = "Gold_Tooth",
        Name = "Gold Tooth",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 250,
        Color = Color3.fromRGB(255, 215, 0),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [65] = {
        Id = "Tear_Gas_Grenade",
        Name = "Tear Gas Grenade",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 180,
        Color = Color3.fromRGB(150, 150, 150),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [66] = {
        Id = "Server_Rack",
        Name = "Server Rack Blade",
        GridWidth = 2,
        GridHeight = 3,
        Weight = math.random(1, 10),
        Value = 1800,
        Color = Color3.fromRGB(50, 50, 60),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch18.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 57, 66 do
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
    print("Registered Loot Items 57-66 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch18.SpawnPhysicalItem(id, position)
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

return LootItemSystemBatch18
