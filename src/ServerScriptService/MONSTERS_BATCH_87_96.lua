-- MONSTERS_BATCH_87_96.lua (Handling Tasks MONSTER_87 to MONSTER_96)
-- Rancang monster unik untuk bioma.

local MonsterSystemBatch10 = {}

local MonsterData = {
    [87] = {
        Name = "Dusk_Widow",
        Health = 300,
        Damage = 60,
        Speed = 26,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(40, 20, 60),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://430338781", -- Placeholder
        Biome = "Forest",
        SpecialAbility = "WebTrap"
    },
    [88] = {
        Name = "Molten_Juggernaut",
        Health = 2200,
        Damage = 140,
        Speed = 12,
        DropCoreLevel = 8,
        Color = Color3.fromRGB(255, 40, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://430338781",
        Biome = "Volcano",
        SpecialAbility = "Quake"
    },
    [89] = {
        Name = "Tundra_Stalker",
        Health = 400,
        Damage = 75,
        Speed = 22,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(220, 255, 255),
        Material = Enum.Material.Ice,
        MeshId = "rbxassetid://645065406",
        Biome = "Mountain",
        SpecialAbility = "Camouflage"
    },
    [90] = {
        Name = "Swamp_Behemoth",
        Health = 1800,
        Damage = 110,
        Speed = 14,
        DropCoreLevel = 7,
        Color = Color3.fromRGB(40, 60, 20),
        Material = Enum.Material.Mud,
        MeshId = "rbxassetid://602494917",
        Biome = "Swamp"
    },
    [91] = {
        Name = "Crystal_Mantis",
        Health = 450,
        Damage = 85,
        Speed = 28,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(150, 100, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://372630511",
        Biome = "Cave"
    },
    [92] = {
        Name = "Sand_Wraith",
        Health = 350,
        Damage = 65,
        Speed = 24,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(210, 190, 140),
        Material = Enum.Material.ForceField,
        MeshId = "rbxassetid://515665809",
        Biome = "Desert",
        SpecialAbility = "Intangible"
    },
    [93] = {
        Name = "Abyssal_Knight",
        Health = 1200,
        Damage = 100,
        Speed = 16,
        DropCoreLevel = 6,
        Color = Color3.fromRGB(30, 0, 50),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://114425114",
        Biome = "PortalDomain",
        SpecialAbility = "LifeSteal"
    },
    [94] = {
        Name = "Storm_Raptor",
        Health = 280,
        Damage = 70,
        Speed = 35,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(200, 200, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://164478144",
        Biome = "WeatherDisaster",
        SpecialAbility = "Flight"
    },
    [95] = {
        Name = "Ruin_Guardian",
        Health = 2000,
        Damage = 125,
        Speed = 10,
        DropCoreLevel = 7,
        Color = Color3.fromRGB(120, 120, 120),
        Material = Enum.Material.Slate,
        MeshId = "rbxassetid://444453051",
        Biome = "CityRuins"
    },
    [96] = {
        Name = "Void_Leviathan",
        Health = 8000,
        Damage = 400,
        Speed = 8,
        DropCoreLevel = 9,
        Color = Color3.fromRGB(10, 0, 20),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://645065406",
        Biome = "PortalDomain",
        SpecialAbility = "Teleport"
    }
}

function MonsterSystemBatch10.SpawnMonster(id, position)
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

    if data.SpecialAbility == "Camouflage" then
        rootPart.Transparency = 0.8
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
                            if data.SpecialAbility == "LifeSteal" then
                                humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (data.Damage * 0.5))
                            end
                        end
                    end
                end

                -- Teleport Ability
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

return MonsterSystemBatch10
