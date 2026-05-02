-- WEAPON_MODERN_BATCH_7_10.lua (Handling Tasks MODERN_WEAPON_7 to MODERN_WEAPON_10)
-- Rancang senjata api modern Raycast. WAJIB tentukan dimensi Tetris.

local ModernWeaponBatch24 = {}

local WeaponData = {
    [7] = {
        Id = "P90_Standard",
        Name = "P90 SMG",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 3,
        GridHeight = 2,
        Firepower = 20,
        Accuracy = 65,
        Range = 80,
        Stability = 90,
        Ergonomics = 85,
        RateOfFire = 900,
        MagazineSize = 50,
        Weight = 2.6,
        Value = 1800,
        ModSlots = {"Optic", "Muzzle"},
        Color = Color3.fromRGB(20, 20, 20),
        MeshId = "rbxassetid://123456789" -- Placeholder
    },
    [8] = {
        Id = "Desert_Eagle",
        Name = "Desert Eagle .50 AE",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 2,
        GridHeight = 1,
        Firepower = 85,
        Accuracy = 55,
        Range = 50,
        Stability = 30, -- Huge recoil
        Ergonomics = 60,
        RateOfFire = 200,
        MagazineSize = 7,
        Weight = 2.0,
        Value = 1500,
        ModSlots = {"Optic", "Magazine"},
        Color = Color3.fromRGB(192, 192, 192),
        MeshId = "rbxassetid://382103444"
    },
    [9] = {
        Id = "M249_SAW",
        Name = "M249 LMG",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 5,
        GridHeight = 2,
        Firepower = 35,
        Accuracy = 60,
        Range = 150,
        Stability = 70,
        Ergonomics = 15, -- Terrible handling speed
        RateOfFire = 800,
        MagazineSize = 100,
        Weight = 7.5, -- Very heavy
        Value = 3500,
        ModSlots = {"Optic", "Muzzle", "Bipod"},
        Color = Color3.fromRGB(50, 55, 45),
        MeshId = "rbxassetid://602494917"
    },
    [10] = {
        Id = "Vector_45",
        Name = "Kriss Vector .45",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 3,
        GridHeight = 2,
        Firepower = 28,
        Accuracy = 65,
        Range = 60,
        Stability = 95, -- Almost no recoil
        Ergonomics = 75,
        RateOfFire = 1100,
        MagazineSize = 25,
        Weight = 2.7,
        Value = 2200,
        ModSlots = {"Optic", "Muzzle", "Foregrip", "Magazine"},
        Color = Color3.fromRGB(30, 30, 30),
        MeshId = "rbxassetid://382103444"
    }
}

function ModernWeaponBatch24.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 7, 10 do
        local data = WeaponData[i]
        if data then
            ItemDatabase.Items[data.Id] = {
                Id = data.Id,
                Name = data.Name,
                Type = data.Type,
                SubType = data.SubType,
                GridWidth = data.GridWidth,
                GridHeight = data.GridHeight,
                Firepower = data.Firepower,
                Accuracy = data.Accuracy,
                Range = data.Range,
                Stability = data.Stability,
                Ergonomics = data.Ergonomics,
                RateOfFire = data.RateOfFire,
                MagazineSize = data.MagazineSize,
                ModSlots = data.ModSlots,
                Weight = data.Weight,
                Value = data.Value
            }
        end
    end
    print("Registered Modern Weapons 7-10 into ItemDatabase.")
end

-- Simulates server-side Raycast combat verification
function ModernWeaponBatch24.FireWeapon(player, weaponId, origin, direction)
    local data = nil
    for _, w in pairs(WeaponData) do
        if w.Id == weaponId then data = w break end
    end

    if not data then return false, "Weapon not found" end

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
                humanoid:TakeDamage(data.Firepower)
                return true, "Hit " .. model.Name .. " for " .. tostring(data.Firepower)
            end
        end
    end

    return false, "Missed"
end

function ModernWeaponBatch24.SpawnPhysicalItem(id, position)
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
    part.Material = Enum.Material.Metal
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
    prompt.ObjectText = data.Name .. " (FP: " .. data.Firepower .. ")"
    prompt.Parent = part

    prompt.Triggered:Connect(function(player)
        print(player.Name .. " looted " .. data.Name)
        part:Destroy()
    end)

    return part
end

return ModernWeaponBatch24
