-- ARMOR_BATCH_1_6.lua (Handling Tasks ARMOR_1 to ARMOR_6)
-- Rancang armor unik (modern dan fantasy). WAJIB tentukan dimensi Tetris.
-- You Are What You Wear: Core Level dictates Mana capacity.

local ArmorSystemBatch22 = {}

local ArmorData = {
    [1] = {
        Id = "Tactical_Rig_T1",
        Name = "Basic Tactical Rig",
        Type = "Armor",
        Slot = "Chest",
        GridWidth = 2,
        GridHeight = 2,
        HealthBonus = 120,
        DefenseBonus = 25,
        ManaBonus = 0,
        CoreLevel = 0, -- Modern armor, no magic
        Weight = 6.0,
        Color = Color3.fromRGB(40, 45, 40),
        MeshId = "rbxassetid://444453051"
    },
    [2] = {
        Id = "Scout_Helmet_T1",
        Name = "Scout Helmet",
        Type = "Armor",
        Slot = "Head",
        GridWidth = 2,
        GridHeight = 2,
        HealthBonus = 40,
        DefenseBonus = 15,
        ManaBonus = 0,
        CoreLevel = 0,
        Weight = 2.5,
        Color = Color3.fromRGB(60, 60, 60),
        MeshId = "rbxassetid://382103444"
    },
    [3] = {
        Id = "Novice_Mage_Robe_T2",
        Name = "Novice Mage Robe",
        Type = "Armor",
        Slot = "Chest",
        GridWidth = 2,
        GridHeight = 3,
        HealthBonus = 50,
        DefenseBonus = 10,
        ManaBonus = 150,
        CoreLevel = 2, -- Powered by Level 2 Core
        Weight = 2.0,
        Color = Color3.fromRGB(50, 100, 255),
        MeshId = "rbxassetid://164478144"
    },
    [4] = {
        Id = "Spellweaver_Hat_T3",
        Name = "Spellweaver Hat",
        Type = "Armor",
        Slot = "Head",
        GridWidth = 2,
        GridHeight = 2,
        HealthBonus = 20,
        DefenseBonus = 5,
        ManaBonus = 250,
        CoreLevel = 3,
        Weight = 1.0,
        Color = Color3.fromRGB(150, 50, 255),
        MeshId = "rbxassetid://645065406"
    },
    [5] = {
        Id = "Heavy_Juggernaut_T4",
        Name = "Juggernaut Plate",
        Type = "Armor",
        Slot = "Chest",
        GridWidth = 3,
        GridHeight = 3,
        HealthBonus = 400,
        DefenseBonus = 80,
        ManaBonus = 0,
        CoreLevel = 0,
        Weight = 25.0, -- Extremely heavy, will slow player down based on StatSystem
        Color = Color3.fromRGB(30, 30, 30),
        MeshId = "rbxassetid://372630511"
    },
    [6] = {
        Id = "Paladin_Cuirass_T5",
        Name = "Paladin Cuirass",
        Type = "Armor",
        Slot = "Chest",
        GridWidth = 2,
        GridHeight = 3,
        HealthBonus = 250,
        DefenseBonus = 60,
        ManaBonus = 100,
        CoreLevel = 5, -- Hybrid modern/fantasy
        Weight = 18.0,
        Color = Color3.fromRGB(200, 200, 200),
        MeshId = "rbxassetid://123456789"
    }
}

function ArmorSystemBatch22.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 1, 6 do
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
    print("Registered Armors 1-6 into ItemDatabase.")
end

function ArmorSystemBatch22.SpawnPhysicalItem(id, position)
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

return ArmorSystemBatch22
