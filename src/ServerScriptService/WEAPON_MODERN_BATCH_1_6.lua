-- WEAPON_MODERN_BATCH_1_6.lua (Handling Tasks MODERN_WEAPON_1 to MODERN_WEAPON_6)
-- Rancang senjata api modern Raycast. WAJIB tentukan dimensi Tetris.

local ModernWeaponBatch23 = {}

local WeaponData = {
    [1] = {
        Id = "M4A1_Standard",
        Name = "M4A1 Assault Rifle",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 4,
        GridHeight = 2,
        Damage = 35,
        FireRate = 0.08,
        MagazineSize = 30,
        Range = 500,
        Weight = 3.5,
        Value = 1200,
        Color = Color3.fromRGB(30, 30, 30),
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [2] = {
        Id = "AK74N_Standard",
        Name = "AK-74N",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 4,
        GridHeight = 2,
        Damage = 42,
        FireRate = 0.1,
        MagazineSize = 30,
        Range = 400,
        Weight = 3.8,
        Value = 900,
        Color = Color3.fromRGB(50, 40, 30),
        MeshId = "rbxassetid://1060481268"
    },
    [3] = {
        Id = "Glock17_Standard",
        Name = "Glock 17",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 2,
        GridHeight = 1,
        Damage = 22,
        FireRate = 0.15,
        MagazineSize = 17,
        Range = 100,
        Weight = 0.9,
        Value = 350,
        Color = Color3.fromRGB(20, 20, 20),
        MeshId = "rbxassetid://1060481268"
    },
    [4] = {
        Id = "Remington_870",
        Name = "Remington 870 Shotgun",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 4,
        GridHeight = 1,
        Damage = 120, -- Up close, huge damage
        FireRate = 0.8,
        MagazineSize = 6,
        Range = 50, -- Very short effective range
        Weight = 3.2,
        Value = 600,
        Color = Color3.fromRGB(40, 40, 40),
        MeshId = "rbxassetid://1060481268"
    },
    [5] = {
        Id = "AWM_Sniper",
        Name = "AWM Sniper Rifle",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 5,
        GridHeight = 2,
        Damage = 150,
        FireRate = 1.5,
        MagazineSize = 5,
        Range = 2000,
        Weight = 6.5,
        Value = 4500,
        Color = Color3.fromRGB(50, 60, 50),
        MeshId = "rbxassetid://1060481268"
    },
    [6] = {
        Id = "MP5_Standard",
        Name = "MP5 SMG",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 3,
        GridHeight = 2,
        Damage = 25,
        FireRate = 0.06,
        MagazineSize = 30,
        Range = 150,
        Weight = 2.5,
        Value = 850,
        Color = Color3.fromRGB(20, 20, 20),
        MeshId = "rbxassetid://1060481268"
    }
}

function ModernWeaponBatch23.RegisterItems()
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
                Damage = data.Damage,
                FireRate = data.FireRate,
                MagazineSize = data.MagazineSize,
                Range = data.Range,
                Weight = data.Weight,
                Value = data.Value
            }
        end
    end
    print("Registered Modern Weapons 1-6 into ItemDatabase.")
end

-- Simulates server-side Raycast combat verification
function ModernWeaponBatch23.FireWeapon(player, weaponId, origin, direction)
    -- In a real scenario, CombatManager would route here for ModernFirearms
    local data = nil
    for _, w in pairs(WeaponData) do
        if w.Id == weaponId then data = w break end
    end

    if not data then return false, "Weapon not found" end

    -- Perform Server Raycast
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
                -- Calculate Arena Breakout style damage
                -- Typically we'd check armor here, but for simplicity we apply base damage
                humanoid:TakeDamage(data.Damage)
                return true, "Hit " .. model.Name .. " for " .. tostring(data.Damage)
            end
        end
    end

    return false, "Missed"
end

function ModernWeaponBatch23.SpawnPhysicalItem(id, position)
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

return ModernWeaponBatch23
