-- MONSTERS_BATCH_37_46.lua (Handling Tasks MONSTER_37 to MONSTER_46)
-- Rancang monster unik untuk bioma.

local MonsterSystemBatch5 = {}

local MonsterData = {
    [37] = {
        Name = "Crystal_Behemoth",
        Health = 1500,
        Damage = 95,
        Speed = 10,
        DropCoreLevel = 6,
        Color = Color3.fromRGB(150, 100, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://164478144",
        Biome = "Cave",
        SpecialAbility = "ReflectMagic"
    },
    [38] = {
        Name = "Fungal_Hulk",
        Health = 900,
        Damage = 65,
        Speed = 14,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(120, 80, 150),
        Material = Enum.Material.Grass,
        MeshId = "rbxassetid://114425114",
        Biome = "Swamp",
        SpecialAbility = "SporeCloud"
    },
    [39] = {
        Name = "Infernal_Imp",
        Health = 120,
        Damage = 45,
        Speed = 28,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(200, 0, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://602494917",
        Biome = "Volcano",
        SpecialAbility = "Fireball"
    },
    [40] = {
        Name = "Thunder_Wyrm",
        Health = 1800,
        Damage = 130,
        Speed = 35,
        DropCoreLevel = 7,
        Color = Color3.fromRGB(100, 200, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://372630511",
        Biome = "WeatherDisaster",
        SpecialAbility = "Flight"
    },
    [41] = {
        Name = "Glacial_Colossus",
        Health = 2500,
        Damage = 160,
        Speed = 8,
        DropCoreLevel = 8,
        Color = Color3.fromRGB(200, 240, 255),
        Material = Enum.Material.Ice,
        MeshId = "rbxassetid://444453051",
        Biome = "Mountain"
    },
    [42] = {
        Name = "Void_Stalker",
        Health = 400,
        Damage = 100,
        Speed = 26,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(30, 0, 60),
        Material = Enum.Material.ForceField,
        MeshId = "rbxassetid://602494917",
        Biome = "PortalDomain",
        SpecialAbility = "Invisibility"
    },
    [43] = {
        Name = "Mutated_Hound",
        Health = 250,
        Damage = 50,
        Speed = 24,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(80, 80, 80),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://114425114",
        Biome = "CityRuins"
    },
    [44] = {
        Name = "Desert_Mirage",
        Health = 300,
        Damage = 75,
        Speed = 20,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(255, 200, 150),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://602494917",
        Biome = "Desert",
        SpecialAbility = "Intangible"
    },
    [45] = {
        Name = "Swamp_Leviathan",
        Health = 3000,
        Damage = 200,
        Speed = 12,
        DropCoreLevel = 9,
        Color = Color3.fromRGB(10, 40, 10),
        Material = Enum.Material.Mud,
        MeshId = "rbxassetid://645065406",
        Biome = "Flood",
        SpecialAbility = "Submerge"
    },
    [46] = {
        Name = "Ironclad_Centurion",
        Health = 1100,
        Damage = 85,
        Speed = 15,
        DropCoreLevel = 6,
        Color = Color3.fromRGB(120, 120, 130),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://114425114",
        Biome = "Ruins"
    }
}

function MonsterSystemBatch5.SpawnMonster(id, position)
    local data = MonsterData[id]
    if not data then return end

    local model = Instance.new("Model")
    model.Name = data.Name

    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(4, 5, 4)
    rootPart.Position = position
    rootPart.Color = data.Color
    rootPart.Material = data.Material or Enum.Material.Plastic
    rootPart.Parent = model

    if data.SpecialAbility == "Invisibility" then
        rootPart.Transparency = 0.9
    end

    if data.SpecialAbility == "Intangible" then
        rootPart.Transparency = 0.5
        rootPart.CanCollide = false
    end

    if data.SpecialAbility == "Flight" then
        rootPart.Position = rootPart.Position + Vector3.new(0, 15, 0)
        local bodyPos = Instance.new("BodyPosition")
        bodyPos.Position = rootPart.Position
        bodyPos.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyPos.Parent = rootPart
    end

    if data.MeshId then
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = data.MeshId
        mesh.Parent = rootPart
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = data.Health
    humanoid.Health = data.Health
    humanoid.WalkSpeed = data.Speed
    humanoid.Parent = model

    model.PrimaryPart = rootPart
    model.Parent = workspace

    -- Very Basic AI Loop with abilities
    task.spawn(function()
        while humanoid.Health > 0 and model.Parent do
            task.wait(2)

            local target = nil
            local dist = 100
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                    if d < dist then
                        dist = d
                        target = player.Character.HumanoidRootPart
                    end
                end
            end

            if target then
                if data.SpecialAbility == "Flight" then
                    local bp = rootPart:FindFirstChildOfClass("BodyPosition")
                    if bp then
                        bp.Position = target.Position + Vector3.new(0, 15, 0)
                    end
                else
                    humanoid:MoveTo(target.Position)
                end

                if dist < 6 then
                    local targetHum = target.Parent:FindFirstChild("Humanoid")
                    if targetHum then
                        targetHum:TakeDamage(data.Damage)
                    end
                end
            end
        end

        if humanoid.Health <= 0 then
            print(data.Name .. " died! Dropped Core Level " .. data.DropCoreLevel)

            -- Procedurally Generate the Physical Core Drop
            local coreDrop = Instance.new("Part")
            coreDrop.Name = "Monster_Core_T" .. tostring(data.DropCoreLevel)
            coreDrop.Shape = Enum.PartType.Ball
            coreDrop.Size = Vector3.new(1.5, 1.5, 1.5)
            coreDrop.Position = rootPart.Position
            coreDrop.Material = Enum.Material.Neon
            coreDrop.Color = Color3.fromRGB(255, 255 - (data.DropCoreLevel * 20), 0)
            coreDrop.Parent = workspace
        end
    end)

    return model
end

return MonsterSystemBatch5
