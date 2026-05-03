-- ARMOR_BATCH_7_10.lua (Handling Tasks ARMOR_7 to ARMOR_10)
-- Rancang armor unik (modern dan fantasy). WAJIB tentukan dimensi Tetris.

local ArmorSystemBatch23 = {}

local ArmorData = {
    [7] = {
        Id = "Void_Walker_Cloak_T7",
        Name = "Void Walker Cloak",
        Type = "Armor",
        Slot = "Chest",
        GridWidth = 2,
        GridHeight = 3,
        HealthBonus = 180,
        DefenseBonus = 35,
        ManaBonus = 380,
        CoreLevel = 7,
        Weight = 1.5,
        Color = Color3.fromRGB(30, 0, 50),
        MeshId = "rbxassetid://164478144"
    },
    [8] = {
        Id = "Altyn_Helmet_T0",
        Name = "Altyn Heavy Helmet",
        Type = "Armor",
        Slot = "Head",
        GridWidth = 2,
        GridHeight = 2,
        HealthBonus = 150,
        DefenseBonus = 45,
        ManaBonus = 0,
        CoreLevel = 0,
        Weight = 4.0,
        Color = Color3.fromRGB(80, 90, 80),
        MeshId = "rbxassetid://645065406"
    },
    [9] = {
        Id = "Apex_Sorcerer_Robes_T9",
        Name = "Apex Sorcerer Robes",
        Type = "Armor",
        Slot = "Chest",
        GridWidth = 2,
        GridHeight = 3,
        HealthBonus = 120,
        DefenseBonus = 20,
        ManaBonus = 800,
        CoreLevel = 9,
        Weight = 1.0,
        Color = Color3.fromRGB(150, 0, 0),
        MeshId = "rbxassetid://430338781"
    },
    [10] = {
        Id = "Apex_Warlord_Armor_T9",
        Name = "Apex Warlord Armor",
        Type = "Armor",
        Slot = "Chest",
        GridWidth = 3,
        GridHeight = 3,
        HealthBonus = 1000,
        DefenseBonus = 150,
        ManaBonus = 50,
        CoreLevel = 9,
        Weight = 35.0,
        Color = Color3.fromRGB(10, 10, 10),
        MeshId = "rbxassetid://515665809"
    }
}

function ArmorSystemBatch23.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 7, 10 do
        local data = ArmorData[i]
        if data then
            ItemDatabase.Items[data.Id] = {
                Id = data.Id,
                Name = data.Name,
                Type = data.Type,
                Slot = data.Slot,
                GridWidth = data.GridWidth,
                GridHeight = data.GridHeight,
                HealthBonus = data.HealthBonus,
                DefenseBonus = data.DefenseBonus,
                ManaBonus = data.ManaBonus,
                CoreLevel = data.CoreLevel,
                Weight = data.Weight
            }
        end
    end
    print("Registered Final Armors 7-10 into ItemDatabase.")
end

function ArmorSystemBatch23.SpawnPhysicalItem(id, position)
    local data = nil
    for _, v in pairs(ArmorData) do
        if v.Id == id then
            data = v
            break
        end
    end

    if not data then return end

    local part = Instance.new("Part")
    part.Name = data.Name
    part.Size = Vector3.new(data.GridWidth, 1, data.GridHeight)
    part.Position = position
    part.Color = data.Color
    part.Material = Enum.Material.Plastic
    part.Parent = workspace

    if data.MeshId then
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = data.MeshId
        mesh.Scale = part.Size
        mesh.Parent = part
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Equip/Loot"
    prompt.ObjectText = data.Name .. " (Def: " .. data.DefenseBonus .. " | Mana: " .. data.ManaBonus .. ")"
    prompt.Parent = part

    prompt.Triggered:Connect(function(player)
        print(player.Name .. " interacted with " .. data.Name)
        -- Call InventorySystem/PlayerManager to equip and recalculate stats
        part:Destroy()
    end)

    return part
end

return ArmorSystemBatch23
