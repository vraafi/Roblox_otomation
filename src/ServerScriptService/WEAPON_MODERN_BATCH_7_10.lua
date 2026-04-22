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
        Damage = 20,
        FireRate = 0.04, -- Extremely fast
        MagazineSize = 50,
        Range = 200,
        Weight = 2.6,
        Value = 1800,
        Color = Color3.fromRGB(20, 20, 20),
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [8] = {
        Id = "Desert_Eagle",
        Name = "Desert Eagle .50 AE",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 2,
        GridHeight = 1,
        Damage = 85,
        FireRate = 0.4,
        MagazineSize = 7,
        Range = 150,
        Weight = 2.0,
        Value = 1500,
        Color = Color3.fromRGB(192, 192, 192),
        MeshId = "rbxassetid://1060481268"
    },
    [9] = {
        Id = "M249_SAW",
        Name = "M249 LMG",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 5,
        GridHeight = 2,
        Damage = 35,
        FireRate = 0.08,
        MagazineSize = 100,
        Range = 600,
        Weight = 7.5, -- Very heavy
        Value = 3500,
        Color = Color3.fromRGB(50, 55, 45),
        MeshId = "rbxassetid://1060481268"
    },
    [10] = {
        Id = "Vector_45",
        Name = "Kriss Vector .45",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 3,
        GridHeight = 2,
        Damage = 28,
        FireRate = 0.05,
        MagazineSize = 25,
        Range = 180,
        Weight = 2.7,
        Value = 2200,
        Color = Color3.fromRGB(30, 30, 30),
        MeshId = "rbxassetid://1060481268"
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
                Damage = data.Damage,
                FireRate = data.FireRate,
                MagazineSize = data.MagazineSize,
                Range = data.Range,
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
                humanoid:TakeDamage(data.Damage)
                return true, "Hit " .. model.Name .. " for " .. tostring(data.Damage)
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
    prompt.ObjectText = data.Name .. " (Dmg: " .. data.Damage .. ")"
    prompt.Parent = part

    prompt.Triggered:Connect(function(player)
        print(player.Name .. " looted " .. data.Name)
        part:Destroy()
    end)

    return part
end

return ModernWeaponBatch24
