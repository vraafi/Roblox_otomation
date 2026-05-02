-- ITEMS_BATCH_67_76.lua (Handling Tasks ITEM_67 to ITEM_76)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch19 = {}

local LootItemsData = {
    [67] = {
        Id = "Scrap_Electronics",
        Name = "Scrap Electronics",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 22,
        Color = Color3.fromRGB(80, 80, 90),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://602522771" -- Placeholder
    },
    [68] = {
        Id = "Crystal_Skull",
        Name = "Crystal Skull",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 3500,
        Color = Color3.fromRGB(200, 200, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://430338781"
    },
    [69] = {
        Id = "Welding_Goggles",
        Name = "Welding Goggles",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 75,
        Color = Color3.fromRGB(30, 30, 30),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://382103444"
    },
    [70] = {
        Id = "Blood_Pack",
        Name = "Blood Pack Type O",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 120,
        Color = Color3.fromRGB(150, 0, 0),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://634289194"
    },
    [71] = {
        Id = "Ancient_Compass",
        Name = "Ancient Compass",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 500,
        Color = Color3.fromRGB(184, 134, 11),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://382103444"
    },
    [72] = {
        Id = "Gun_Cleaning_Kit",
        Name = "Gun Cleaning Kit",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 180,
        Color = Color3.fromRGB(60, 60, 60),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://645065406"
    },
    [73] = {
        Id = "Exotic_Spice",
        Name = "Jar of Exotic Spice",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 850,
        Color = Color3.fromRGB(255, 100, 50),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://444453051"
    },
    [74] = {
        Id = "Rusted_Keys",
        Name = "Ring of Rusted Keys",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 15,
        Color = Color3.fromRGB(120, 80, 40),
        Material = Enum.Material.CorrodedMetal,
        MeshId = "rbxassetid://634289194"
    },
    [75] = {
        Id = "Drone_Propeller",
        Name = "Drone Propeller Blade",
        GridWidth = 1,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 90,
        Color = Color3.fromRGB(200, 200, 200),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://164478144"
    },
    [76] = {
        Id = "Void_Core_Fragment",
        Name = "Void Core Fragment",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 5000,
        Color = Color3.fromRGB(50, 0, 100),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://515665809"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch19.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 67, 76 do
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
    print("Registered Loot Items 67-76 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch19.SpawnPhysicalItem(id, position)
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

return LootItemSystemBatch19
