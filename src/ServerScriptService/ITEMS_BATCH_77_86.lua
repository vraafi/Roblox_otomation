-- ITEMS_BATCH_77_86.lua (Handling Tasks ITEM_77 to ITEM_86)
-- Rancang item loot unik. WAJIB tentukan dimensi Tetris (contoh: 1x2).

local LootItemSystemBatch20 = {}

local LootItemsData = {
    [77] = {
        Id = "Military_Helmet_Scrap",
        Name = "Damaged Military Helmet",
        GridWidth = 2,
        GridHeight = 2,
        Value = 85,
        Color = Color3.fromRGB(60, 80, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [78] = {
        Id = "Biohazard_Suit_Filter",
        Name = "Biohazard Filter",
        GridWidth = 1,
        GridHeight = 2,
        Value = 350,
        Color = Color3.fromRGB(200, 200, 50),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268"
    },
    [79] = {
        Id = "Cursed_Dagger",
        Name = "Cursed Dagger",
        GridWidth = 1,
        GridHeight = 2,
        Value = 1800,
        Color = Color3.fromRGB(150, 0, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    },
    [80] = {
        Id = "Gold_Tooth_Extract",
        Name = "Extracted Gold Tooth",
        GridWidth = 1,
        GridHeight = 1,
        Value = 200,
        Color = Color3.fromRGB(255, 215, 0),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [81] = {
        Id = "Ancient_Parchment",
        Name = "Ancient Parchment",
        GridWidth = 1,
        GridHeight = 1,
        Value = 500,
        Color = Color3.fromRGB(220, 200, 150),
        Material = Enum.Material.Fabric,
        MeshId = "rbxassetid://1060481268"
    },
    [82] = {
        Id = "Signal_Jammer",
        Name = "Signal Jammer",
        GridWidth = 2,
        GridHeight = 2,
        Value = 1200,
        Color = Color3.fromRGB(40, 40, 40),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [83] = {
        Id = "Tear_Gas_Canister",
        Name = "Empty Tear Gas Canister",
        GridWidth = 1,
        GridHeight = 2,
        Value = 25,
        Color = Color3.fromRGB(180, 180, 180),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [84] = {
        Id = "Enchanted_Rune",
        Name = "Enchanted Rune Stone",
        GridWidth = 1,
        GridHeight = 1,
        Value = 2500,
        Color = Color3.fromRGB(100, 50, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    },
    [85] = {
        Id = "Rusty_Lockpick",
        Name = "Rusty Lockpick Set",
        GridWidth = 1,
        GridHeight = 1,
        Value = 45,
        Color = Color3.fromRGB(120, 100, 80),
        Material = Enum.Material.CorrodedMetal,
        MeshId = "rbxassetid://1060481268"
    },
    [86] = {
        Id = "Void_Essence",
        Name = "Vial of Void Essence",
        GridWidth = 1,
        GridHeight = 1,
        Value = 4500,
        Color = Color3.fromRGB(50, 0, 100),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268"
    }
}

-- Integrates these items into the master ItemDatabase we created earlier
function LootItemSystemBatch20.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 77, 86 do
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
    print("Registered Loot Items 77-86 into ItemDatabase.")
end

-- Procedurally spawns the physical 3D item in the world for players to pick up
function LootItemSystemBatch20.SpawnPhysicalItem(id, position)
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

return LootItemSystemBatch20
