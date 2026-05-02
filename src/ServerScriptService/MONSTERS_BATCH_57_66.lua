-- MONSTERS_BATCH_57_66.lua (Handling Tasks MONSTER_57 to MONSTER_66)
-- Rancang monster unik untuk bioma.

local MonsterSystemBatch7 = {}

local MonsterData = {
    [57] = {
        Name = "Plague_Toad",
        Health = 250,
        Damage = 30,
        Speed = 14,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(50, 100, 50),
        Material = Enum.Material.Pebble,
        MeshId = "rbxassetid://372630511", -- Placeholder
        Biome = "Swamp",
        SpecialAbility = "PoisonCloud"
    },
    [58] = {
        Name = "Crystal_Crawler",
        Health = 400,
        Damage = 50,
        Speed = 22,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(150, 200, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://123456789",
        Biome = "Cave",
        SpecialAbility = "ReflectMagic"
    },
    [59] = {
        Name = "Sun_Scorpion",
        Health = 300,
        Damage = 65,
        Speed = 18,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(255, 200, 50),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://515665809",
        Biome = "Desert",
        SpecialAbility = "BlindAura"
    },
    [60] = {
        Name = "Bramble_Fiend",
        Health = 150,
        Damage = 45,
        Speed = 24,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(100, 150, 50),
        Material = Enum.Material.Wood,
        MeshId = "rbxassetid://602494917",
        Biome = "Forest"
    },
    [61] = {
        Name = "Void_Terror",
        Health = 1200,
        Damage = 130,
        Speed = 16,
        DropCoreLevel = 7,
        Color = Color3.fromRGB(50, 0, 80),
        Material = Enum.Material.ForceField,
        MeshId = "rbxassetid://634289194",
        Biome = "PortalDomain",
        SpecialAbility = "Teleport"
    },
    [62] = {
        Name = "Tidal_Serpent",
        Health = 800,
        Damage = 90,
        Speed = 28,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(50, 100, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://602522771",
        Biome = "Flood",
        SpecialAbility = "Submerge"
    },
    [63] = {
        Name = "Rust_Golem",
        Health = 600,
        Damage = 55,
        Speed = 12,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(150, 100, 50),
        Material = Enum.Material.CorrodedMetal,
        MeshId = "rbxassetid://114425114",
        Biome = "CityRuins"
    },
    [64] = {
        Name = "Lava_Crawler",
        Health = 350,
        Damage = 75,
        Speed = 20,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(255, 100, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://114425114",
        Biome = "Volcano"
    },
    [65] = {
        Name = "Frost_Wolf",
        Health = 280,
        Damage = 50,
        Speed = 30,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(200, 240, 255),
        Material = Enum.Material.Ice,
        MeshId = "rbxassetid://515665809",
        Biome = "Mountain"
    },
    [66] = {
        Name = "Thunder_Bird",
        Health = 450,
        Damage = 85,
        Speed = 35,
        DropCoreLevel = 6,
        Color = Color3.fromRGB(255, 255, 100),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://645065406",
        Biome = "WeatherDisaster",
        SpecialAbility = "Flight"
    }
}

function MonsterSystemBatch7.SpawnMonster(id, position)
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

                -- Teleport Ability Example (Void Terror)
                if data.SpecialAbility == "Teleport" and dist > 20 and dist < 80 then
                    if math.random() > 0.7 then
                        rootPart.Position = target.Position + Vector3.new(0, 5, 0)
                    end
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

return MonsterSystemBatch7
