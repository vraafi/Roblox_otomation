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
        -- Arena Breakout Advanced Stats
        Firepower = 35,
        Accuracy = 75,
        Range = 120, -- Effective Range in meters
        Stability = 65, -- Recoil control
        Ergonomics = 55, -- Aim down sight speed & stamina drain
        RateOfFire = 800, -- Rounds per minute
        MagazineSize = 30,
        Weight = 3.5,
        Value = 1200,
        ModSlots = {"Muzzle", "Optic", "Foregrip", "Stock", "Magazine"},
        Color = Color3.fromRGB(30, 30, 30),
        MeshId = "rbxassetid://602494917"
    },
    [2] = {
        Id = "AK74N_Standard",
        Name = "AK-74N",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 4,
        GridHeight = 2,
        Firepower = 42,
        Accuracy = 68,
        Range = 100,
        Stability = 50,
        Ergonomics = 48,
        RateOfFire = 600,
        MagazineSize = 30,
        Weight = 3.8,
        Value = 900,
        ModSlots = {"Muzzle", "Optic", "Handguard", "Stock", "Magazine"},
        Color = Color3.fromRGB(50, 40, 30),
        MeshId = "rbxassetid://114425114"
    },
    [3] = {
        Id = "Glock17_Standard",
        Name = "Glock 17",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 2,
        GridHeight = 1,
        Firepower = 22,
        Accuracy = 45,
        Range = 30,
        Stability = 75,
        Ergonomics = 90, -- Very fast handling
        RateOfFire = 400,
        MagazineSize = 17,
        Weight = 0.9,
        Value = 350,
        ModSlots = {"Muzzle", "Optic", "Magazine"},
        Color = Color3.fromRGB(20, 20, 20),
        MeshId = "rbxassetid://602494917"
    },
    [4] = {
        Id = "Remington_870",
        Name = "Remington 870 Shotgun",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 4,
        GridHeight = 1,
        Firepower = 120,
        Accuracy = 20,
        Range = 15,
        Stability = 30,
        Ergonomics = 40,
        RateOfFire = 60, -- Pump action
        MagazineSize = 6,
        Weight = 3.2,
        Value = 600,
        ModSlots = {"Muzzle", "Optic", "Pump"},
        Color = Color3.fromRGB(40, 40, 40),
        MeshId = "rbxassetid://602494917"
    },
    [5] = {
        Id = "AWM_Sniper",
        Name = "AWM Sniper Rifle",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 5,
        GridHeight = 2,
        Firepower = 150,
        Accuracy = 98,
        Range = 250,
        Stability = 20,
        Ergonomics = 25, -- Slow heavy sniper
        RateOfFire = 40,
        MagazineSize = 5,
        Weight = 6.5,
        Value = 4500,
        ModSlots = {"Muzzle", "Optic", "Stock"},
        Color = Color3.fromRGB(50, 60, 50),
        MeshId = "rbxassetid://382103444"
    },
    [6] = {
        Id = "MP5_Standard",
        Name = "MP5 SMG",
        Type = "Weapon",
        SubType = "ModernFirearm",
        GridWidth = 3,
        GridHeight = 2,
        Firepower = 25,
        Accuracy = 60,
        Range = 50,
        Stability = 85,
        Ergonomics = 80,
        RateOfFire = 800,
        MagazineSize = 30,
        Weight = 2.5,
        Value = 850,
        ModSlots = {"Muzzle", "Optic", "Foregrip", "Magazine"},
        Color = Color3.fromRGB(20, 20, 20),
        MeshId = "rbxassetid://444453051"
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
                -- In a real gunsmith, we calculate the dynamic stats from the specific instantiated weapon,
                -- accounting for stability dropoff, ergonomics aim time, etc.
                humanoid:TakeDamage(data.Firepower)
                return true, "Hit " .. model.Name .. " for " .. tostring(data.Firepower)
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
    prompt.ObjectText = data.Name .. " (FP: " .. data.Firepower .. ")"
    prompt.Parent = part

    prompt.Triggered:Connect(function(player)
        print(player.Name .. " looted " .. data.Name)
        part:Destroy()
    end)

    return part
end

return ModernWeaponBatch23
