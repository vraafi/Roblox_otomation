-- WEAPON_FANTASY_BATCH_1_6.lua (Handling Tasks FANTASY_WEAPON_1 to FANTASY_WEAPON_6)
-- Rancang senjata sihir/melee fantasy. WAJIB dimensi Tetris. Konsumsi Mana.

local FantasyWeaponBatch24 = {}

local WeaponData = {
    [1] = {
        Id = "Initiate_Fire_Staff",
        Name = "Initiate's Fire Staff",
        Type = "Weapon",
        SubType = "MagicWand",
        GridWidth = 1,
        GridHeight = 4,
        BaseDamage = 45,
        ManaCost = 15,
        CoreLevelRequired = 1,
        Range = 100,
        Weight = 1.5,
        Value = 500,
        Color = Color3.fromRGB(200, 50, 0),
        Material = Enum.Material.Wood,
        MeshId = "rbxassetid://444453051"
    },
    [2] = {
        Id = "Adept_Frost_Staff",
        Name = "Adept's Frost Staff",
        Type = "Weapon",
        SubType = "MagicWand",
        GridWidth = 1,
        GridHeight = 4,
        BaseDamage = 65,
        ManaCost = 25,
        CoreLevelRequired = 3,
        Range = 120,
        Weight = 1.8,
        Value = 1200,
        Color = Color3.fromRGB(150, 200, 255),
        Material = Enum.Material.Ice,
        MeshId = "rbxassetid://164478144"
    },
    [3] = {
        Id = "Master_Cursed_Staff",
        Name = "Master's Cursed Staff",
        Type = "Weapon",
        SubType = "MagicWand",
        GridWidth = 2,
        GridHeight = 4,
        BaseDamage = 110,
        ManaCost = 45,
        CoreLevelRequired = 6,
        Range = 80,
        Weight = 2.2,
        Value = 4500,
        Color = Color3.fromRGB(50, 0, 100),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://164478144"
    },
    [4] = {
        Id = "Broadsword_T1",
        Name = "Iron Broadsword",
        Type = "Weapon",
        SubType = "Melee",
        GridWidth = 1,
        GridHeight = 3,
        BaseDamage = 35,
        ManaCost = 0, -- Melee doesn't use mana
        CoreLevelRequired = 0,
        Range = 5,
        Weight = 3.0,
        Value = 200,
        Color = Color3.fromRGB(150, 150, 150),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://645065406"
    },
    [5] = {
        Id = "Bloodletter_T5",
        Name = "Bloodletter Dagger",
        Type = "Weapon",
        SubType = "Melee",
        GridWidth = 1,
        GridHeight = 2,
        BaseDamage = 75,
        ManaCost = 0,
        CoreLevelRequired = 0,
        Range = 4,
        Weight = 1.2,
        Value = 2800,
        Color = Color3.fromRGB(180, 20, 20),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://372630511"
    },
    [6] = {
        Id = "Grandmaster_Arcane_Staff",
        Name = "Grandmaster's Arcane Staff",
        Type = "Weapon",
        SubType = "MagicWand",
        GridWidth = 2,
        GridHeight = 5,
        BaseDamage = 180,
        ManaCost = 80,
        CoreLevelRequired = 8,
        Range = 150,
        Weight = 3.5,
        Value = 15000,
        Color = Color3.fromRGB(255, 100, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://382103444"
    }
}

function FantasyWeaponBatch24.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 1, 6 do
        local data = WeaponData[i]
        if data then
            ItemDatabase.Items[data.Id] = {
                Id = data.Id,
                Name = data.Name,
                Type = data.Type,
                SubType = data.SubType,
                GridWidth = data.GridWidth,
                GridHeight = data.GridHeight,
                BaseDamage = data.BaseDamage,
                ManaCost = data.ManaCost,
                CoreLevelRequired = data.CoreLevelRequired,
                Range = data.Range,
                Weight = data.Weight,
                Value = data.Value
            }
        end
    end
    print("Registered Fantasy Weapons 1-6 into ItemDatabase.")
end

-- Simulates server-side combat verification for Magic & Melee
function FantasyWeaponBatch24.FireWeapon(player, weaponId, origin, direction, currentMana)
    local data = nil
    for _, w in pairs(WeaponData) do
        if w.Id == weaponId then data = w break end
    end

    if not data then return false, "Weapon not found" end

    -- Check Mana for Magic Weapons
    if data.SubType == "MagicWand" then
        if currentMana < data.ManaCost then
            return false, "Not enough mana. Equip armor with a higher Core Level."
        end
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local rayResult = workspace:Raycast(origin, direction.Unit * data.Range, raycastParams)

    if rayResult then
        local hitPart = rayResult.Instance
        local model = hitPart:FindFirstAncestorOfClass("Model")

        if model then
            local humanoid = model:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:TakeDamage(data.BaseDamage)
                return true, "Hit " .. model.Name .. " for " .. tostring(data.BaseDamage), data.ManaCost
            end
        end
    end

    return false, "Missed", data.ManaCost
end

function FantasyWeaponBatch24.SpawnPhysicalItem(id, position)
    local data = nil
    for _, v in pairs(WeaponData) do
        if v.Id == id then data = v break end
    end
    if not data then return end

    local part = Instance.new("Part")
    part.Name = data.Name
    part.Size = Vector3.new(data.GridWidth * 0.8, 0.5, data.GridHeight * 0.8)
    part.Position = position
    part.Color = data.Color
    part.Material = data.Material
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
    local promptTxt = data.Name .. " (Dmg: " .. data.BaseDamage .. ")"
    if data.ManaCost > 0 then
        promptTxt = promptTxt .. " [Mana: " .. data.ManaCost .. "]"
    end
    prompt.ObjectText = promptTxt
    prompt.Parent = part

    prompt.Triggered:Connect(function(player)
        print(player.Name .. " looted " .. data.Name)
        part:Destroy()
    end)

    return part
end

return FantasyWeaponBatch24
