-- MONSTERS_BATCH_27_36.lua (Handling Tasks MONSTER_27 to MONSTER_36)
-- Rancang monster unik untuk bioma.

local MonsterSystemBatch4 = {}

local MonsterData = {
    [27] = {
        Name = "Plague_Rat",
        Health = 50,
        Damage = 15,
        Speed = 22,
        DropCoreLevel = 1,
        Color = Color3.fromRGB(80, 70, 60),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://645065406",
        Biome = "CityRuins",
        SpecialAbility = "DiseaseBite"
    },
    [28] = {
        Name = "Giant_Mantis",
        Health = 280,
        Damage = 60,
        Speed = 20,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(100, 200, 50),
        Material = Enum.Material.Grass,
        MeshId = "rbxassetid://430338781",
        Biome = "Jungle"
    },
    [29] = {
        Name = "Obsidian_Gargoyle",
        Health = 700,
        Damage = 55,
        Speed = 15,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(30, 30, 30),
        Material = Enum.Material.Slate,
        MeshId = "rbxassetid://602522771",
        Biome = "Volcano",
        SpecialAbility = "Flight"
    },
    [30] = {
        Name = "Spectral_Knight",
        Health = 450,
        Damage = 85,
        Speed = 18,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(200, 200, 255),
        Material = Enum.Material.ForceField,
        MeshId = "rbxassetid://444453051",
        Biome = "Ruins",
        SpecialAbility = "Intangible"
    },
    [31] = {
        Name = "Deep_Sea_Lurker",
        Health = 600,
        Damage = 70,
        Speed = 12,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(0, 50, 100),
        Material = Enum.Material.Ice,
        MeshId = "rbxassetid://515665809",
        Biome = "Flood",
        SpecialAbility = "Camouflage"
    },
    [32] = {
        Name = "Ash_Fiend",
        Health = 150,
        Damage = 40,
        Speed = 24,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(100, 100, 100),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://123456789",
        Biome = "Volcano"
    },
    [33] = {
        Name = "Mutated_Bear",
        Health = 850,
        Damage = 95,
        Speed = 16,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(120, 60, 20),
        Material = Enum.Material.Wood,
        MeshId = "rbxassetid://430338781",
        Biome = "Forest"
    },
    [34] = {
        Name = "Sand_Gargantua",
        Health = 1200,
        Damage = 110,
        Speed = 10,
        DropCoreLevel = 6,
        Color = Color3.fromRGB(200, 180, 100),
        Material = Enum.Material.Sand,
        MeshId = "rbxassetid://164478144",
        Biome = "Desert",
        SpecialAbility = "Quake"
    },
    [35] = {
        Name = "Astral_Serpent",
        Health = 2000,
        Damage = 150,
        Speed = 30,
        DropCoreLevel = 8,
        Color = Color3.fromRGB(150, 50, 255),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://515665809",
        Biome = "PortalDomain",
        SpecialAbility = "Flight"
    },
    [36] = {
        Name = "Bone_Crawler",
        Health = 180,
        Damage = 45,
        Speed = 26,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(220, 220, 220),
        Material = Enum.Material.Marble,
        MeshId = "rbxassetid://372630511",
        Biome = "Cave"
    }
}

function MonsterSystemBatch4.SpawnMonster(id, position)
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

return MonsterSystemBatch4
