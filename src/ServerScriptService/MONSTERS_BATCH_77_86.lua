-- MONSTERS_BATCH_77_86.lua (Handling Tasks MONSTER_77 to MONSTER_86)
-- Rancang monster unik untuk bioma.

local MonsterSystemBatch9 = {}

local MonsterData = {
    [77] = {
        Name = "Iron_Weaver",
        Health = 350,
        Damage = 40,
        Speed = 26,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(100, 100, 110),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://372630511",
        Biome = "Ruins",
        SpecialAbility = "WebTrap"
    },
    [78] = {
        Name = "Lava_Serpent",
        Health = 800,
        Damage = 95,
        Speed = 22,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(255, 60, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://382103444",
        Biome = "Volcano",
        SpecialAbility = "Submerge"
    },
    [79] = {
        Name = "Storm_Caller",
        Health = 450,
        Damage = 85,
        Speed = 20,
        DropCoreLevel = 6,
        Color = Color3.fromRGB(200, 200, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://444453051",
        Biome = "WeatherDisaster",
        SpecialAbility = "LightningStrike"
    },
    [80] = {
        Name = "Abyssal_Crawler",
        Health = 280,
        Damage = 65,
        Speed = 28,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(10, 0, 30),
        Material = Enum.Material.Slate,
        MeshId = "rbxassetid://123456789",
        Biome = "PortalDomain"
    },
    [81] = {
        Name = "Venom_Spire",
        Health = 600,
        Damage = 50,
        Speed = 0, -- Stationary
        DropCoreLevel = 3,
        Color = Color3.fromRGB(50, 150, 50),
        Material = Enum.Material.Grass,
        MeshId = "rbxassetid://164478144",
        Biome = "Swamp",
        SpecialAbility = "PoisonCloud"
    },
    [82] = {
        Name = "Glacial_Hound",
        Health = 320,
        Damage = 45,
        Speed = 32,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(200, 240, 255),
        Material = Enum.Material.Ice,
        MeshId = "rbxassetid://430338781",
        Biome = "Mountain"
    },
    [83] = {
        Name = "Desert_Phantom",
        Health = 200,
        Damage = 80,
        Speed = 24,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(255, 200, 150),
        Material = Enum.Material.ForceField,
        MeshId = "rbxassetid://114425114",
        Biome = "Desert",
        SpecialAbility = "Intangible"
    },
    [84] = {
        Name = "Crystal_Goliath",
        Health = 2500,
        Damage = 160,
        Speed = 10,
        DropCoreLevel = 8,
        Color = Color3.fromRGB(150, 100, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://114425114",
        Biome = "Cave",
        SpecialAbility = "ReflectMagic"
    },
    [85] = {
        Name = "Blight_Swarm",
        Health = 150,
        Damage = 20,
        Speed = 35,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(50, 80, 20),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://634289194",
        Biome = "Forest",
        SpecialAbility = "Flight"
    },
    [86] = {
        Name = "Void_Overlord",
        Health = 5000,
        Damage = 300,
        Speed = 12,
        DropCoreLevel = 9,
        Color = Color3.fromRGB(40, 0, 80),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://602494917",
        Biome = "PortalDomain",
        SpecialAbility = "Teleport"
    }
}

function MonsterSystemBatch9.SpawnMonster(id, position)
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
                    -- Account for flight height in attack range
                    if dist < 18 then
                        local targetHum = target.Parent:FindFirstChild("Humanoid")
                        if targetHum then
                            targetHum:TakeDamage(data.Damage)
                        end
                    end
                else
                    if data.Speed > 0 then
                        humanoid:MoveTo(target.Position)
                    end
                    if dist < 6 then
                        local targetHum = target.Parent:FindFirstChild("Humanoid")
                        if targetHum then
                            targetHum:TakeDamage(data.Damage)
                        end
                    end
                end

                -- Teleport Ability Example
                if data.SpecialAbility == "Teleport" and dist > 20 and dist < 80 then
                    if math.random() > 0.7 then
                        rootPart:PivotTo(target.CFrame + Vector3.new(0, 5, 0))
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

return MonsterSystemBatch9
