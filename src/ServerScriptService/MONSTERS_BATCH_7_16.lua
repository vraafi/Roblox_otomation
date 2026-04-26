-- MONSTERS_BATCH_7_16.lua (Handling Tasks MONSTER_7 to MONSTER_16)
-- Rancang monster unik untuk bioma.

local MonsterSystemBatch2 = {}

local MonsterData = {
    [7] = {
        Name = "Swamp_Crawler",
        Health = 120,
        Damage = 20,
        Speed = 14,
        DropCoreLevel = 1,
        Color = Color3.fromRGB(30, 80, 30),
        MeshId = "rbxassetid://1060481268", -- Placeholder Creature Mesh
        Biome = "Flood",
        SpecialAbility = "PoisonStrike"
    },
    [8] = {
        Name = "Desert_Scorpion",
        Health = 200,
        Damage = 45,
        Speed = 16,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(200, 150, 50),
        MeshId = "rbxassetid://1060481268",
        Biome = "Desert",
        SpecialAbility = "VenomSting"
    },
    [9] = {
        Name = "Frost_Wraith",
        Health = 180,
        Damage = 30,
        Speed = 20,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(150, 200, 255),
        Material = Enum.Material.Ice,
        MeshId = "rbxassetid://1060481268",
        Biome = "Mountain",
        SpecialAbility = "ChillAura"
    },
    [10] = {
        Name = "Jungle_Stalker",
        Health = 250,
        Damage = 50,
        Speed = 24,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(10, 60, 10),
        MeshId = "rbxassetid://1060481268",
        Biome = "Forest"
    },
    [11] = {
        Name = "Void_Walker",
        Health = 400,
        Damage = 70,
        Speed = 18,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(50, 0, 100),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "PortalDomain",
        SpecialAbility = "Teleport"
    },
    [12] = {
        Name = "Cave_Spider",
        Health = 90,
        Damage = 25,
        Speed = 22,
        DropCoreLevel = 1,
        Color = Color3.fromRGB(20, 20, 20),
        MeshId = "rbxassetid://1060481268",
        Biome = "Mountain"
    },
    [13] = {
        Name = "Lava_Behemoth",
        Health = 1000,
        Damage = 85,
        Speed = 12,
        DropCoreLevel = 6,
        Color = Color3.fromRGB(255, 60, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "Mountain"
    },
    [14] = {
        Name = "Toxic_Slime",
        Health = 300,
        Damage = 15,
        Speed = 10,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(100, 255, 100),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268",
        Biome = "Flood"
    },
    [15] = {
        Name = "Storm_Elemental",
        Health = 600,
        Damage = 65,
        Speed = 26,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(200, 200, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "WeatherDisaster",
        SpecialAbility = "LightningStrike"
    },
    [16] = {
        Name = "Shadow_Assassin",
        Health = 350,
        Damage = 90,
        Speed = 28,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(10, 10, 10),
        MeshId = "rbxassetid://1060481268",
        Biome = "PortalDomain"
    }
}

function MonsterSystemBatch2.SpawnMonster(id, position)
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
                humanoid:MoveTo(target.Position)

                -- Teleport Ability Example (Void Walker)
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

return MonsterSystemBatch2
