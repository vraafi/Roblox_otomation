-- WEAPON_FANTASY_BATCH_7_10.lua (Handling Tasks FANTASY_WEAPON_7 to FANTASY_WEAPON_10)
-- Rancang senjata sihir/melee fantasy. WAJIB dimensi Tetris. Konsumsi Mana.

local FantasyWeaponBatch25 = {}

local WeaponData = {
    [7] = {
        Id = "Holy_Staff_T6",
        Name = "Holy Staff",
        Type = "Weapon",
        SubType = "MagicWand",
        GridWidth = 2,
        GridHeight = 5,
        BaseDamage = 60, -- Low damage, but high healing utility conceptually
        ManaCost = 35,
        CoreLevelRequired = 6,
        Range = 100,
        Weight = 2.0,
        Value = 5500,
        Color = Color3.fromRGB(255, 255, 200),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268" -- Placeholder
    },
    [8] = {
        Id = "Glaive_T4",
        Name = "Steel Glaive",
        Type = "Weapon",
        SubType = "Melee",
        GridWidth = 1,
        GridHeight = 4,
        BaseDamage = 65,
        ManaCost = 0,
        CoreLevelRequired = 0,
        Range = 8,
        Weight = 4.5,
        Value = 1200,
        Color = Color3.fromRGB(150, 150, 160),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268"
    },
    [9] = {
        Id = "Nature_Staff_T7",
        Name = "Nature Staff",
        Type = "Weapon",
        SubType = "MagicWand",
        GridWidth = 2,
        GridHeight = 4,
        BaseDamage = 95,
        ManaCost = 40,
        CoreLevelRequired = 7,
        Range = 110,
        Weight = 1.6,
        Value = 7500,
        Color = Color3.fromRGB(50, 180, 50),
        Material = Enum.Material.Wood,
        MeshId = "rbxassetid://1060481268"
    },
    [10] = {
        Id = "Apex_Scythe_T9",
        Name = "The Apex Scythe",
        Type = "Weapon",
        SubType = "Melee",
        GridWidth = 3,
        GridHeight = 5,
        BaseDamage = 250,
        ManaCost = 20, -- Uses some mana for magical slashes
        CoreLevelRequired = 9,
        Range = 12,
        Weight = 8.0,
        Value = 35000,
        Color = Color3.fromRGB(20, 0, 40),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268"
    }
}

function FantasyWeaponBatch25.RegisterItems()
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
                BaseDamage = data.BaseDamage,
                ManaCost = data.ManaCost,
                CoreLevelRequired = data.CoreLevelRequired,
                Range = data.Range,
                Weight = data.Weight,
                Value = data.Value
            }
        end
    end
    print("Registered Final Fantasy Weapons 7-10 into ItemDatabase.")
end

-- Simulates server-side combat verification for Magic & Melee
function FantasyWeaponBatch25.FireWeapon(player, weaponId, origin, direction, currentMana)
    local data = nil
    for _, w in pairs(WeaponData) do
        if w.Id == weaponId then data = w break end
    end

    if not data then return false, "Weapon not found" end

    -- Check Mana for Magic Weapons
    if data.ManaCost > 0 then
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

function FantasyWeaponBatch25.SpawnPhysicalItem(id, position)
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

return FantasyWeaponBatch25
