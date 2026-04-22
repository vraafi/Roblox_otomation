-- ITEMS_BATCH_47_56.lua (Handling Tasks ITEM_47 to ITEM_56)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch17 = {}

local LootItemsData = {
    [47] = {
        Id = "Military_Binoculars",
        Name = "Military Binoculars",
        GridWidth = 2,
        GridHeight = 1,
        Value = 280,
        Color = Color3.fromRGB(40, 60, 40),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [48] = {
        Id = "Silver_Pocket_Watch",
        Name = "Silver Pocket Watch",
        GridWidth = 1,
        GridHeight = 1,
        Value = 180,
        Color = Color3.fromRGB(192, 192, 192),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [49] = {
        Id = "Thermal_Camera",
        Name = "Thermal Camera",
        GridWidth = 2,
        GridHeight = 2,
        Value = 1200,
        Color = Color3.fromRGB(50, 50, 50),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [50] = {
        Id = "Glow_Sticks",
        Name = "Pack of Glow Sticks",
        GridWidth = 1,
        GridHeight = 2,
        Value = 15,
        Color = Color3.fromRGB(150, 255, 50),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    },
    [51] = {
        Id = "Ancient_Coin",
        Name = "Ancient Coin",
        GridWidth = 1,
        GridHeight = 1,
        Value = 400,
        Color = Color3.fromRGB(200, 150, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [52] = {
        Id = "Radioactive_Isotope",
        Name = "Radioactive Isotope",
        GridWidth = 1,
        GridHeight = 2,
        Value = 3500,
        Color = Color3.fromRGB(50, 255, 100),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    },
    [53] = {
        Id = "Welding_Torch",
        Name = "Welding Torch",
        GridWidth = 2,
        GridHeight = 2,
        Value = 150,
        Color = Color3.fromRGB(180, 50, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [54] = {
        Id = "Surgical_Kit",
        Name = "Surgical Kit",
        GridWidth = 2,
        GridHeight = 2,
        Value = 850,
        Color = Color3.fromRGB(220, 220, 220),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [55] = {
        Id = "Bone_Fragment",
        Name = "Bone Fragment",
        GridWidth = 1,
        GridHeight = 1,
        Value = 30,
        Color = Color3.fromRGB(240, 240, 230),
        Material = Enum.Material.Marble,
        MeshId = "rbxassetid://1060481268"
    },
    [56] = {
        Id = "Encrypted_Radio",
        Name = "Encrypted Comm Radio",
        GridWidth = 1,
        GridHeight = 2,
        Value = 600,
        Color = Color3.fromRGB(30, 30, 40),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch17.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 47, 56 do
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
    print("Registered Loot Items 47-56 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch17.SpawnPhysicalItem(id, position)
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

return LootItemSystemBatch17
