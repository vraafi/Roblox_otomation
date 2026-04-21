-- MONSTERS_BATCH_17_26.lua (Handling Tasks MONSTER_17 to MONSTER_26)
-- Rancang monster unik untuk bioma.

local MonsterSystemBatch3 = {}

local MonsterData = {
    [17] = {
        Name = "Sand_Worm",
        Health = 300,
        Damage = 55,
        Speed = 18,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(194, 178, 128), -- Sand color
        Material = Enum.Material.Sand,
        MeshId = "rbxassetid://1060481268", -- Placeholder
        Biome = "Desert",
        SpecialAbility = "Burrow"
    },
    [18] = {
        Name = "Crystal_Bat",
        Health = 60,
        Damage = 20,
        Speed = 35,
        DropCoreLevel = 1,
        Color = Color3.fromRGB(200, 100, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268",
        Biome = "Cave",
        SpecialAbility = "Flight"
    },
    [19] = {
        Name = "Magma_Hound",
        Health = 220,
        Damage = 45,
        Speed = 28,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(255, 50, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "Volcano"
    },
    [20] = {
        Name = "Abyssal_Horror",
        Health = 1500,
        Damage = 120,
        Speed = 10,
        DropCoreLevel = 7,
        Color = Color3.fromRGB(10, 0, 30),
        Material = Enum.Material.Slate,
        MeshId = "rbxassetid://1060481268",
        Biome = "PortalDomain",
        SpecialAbility = "FearAura"
    },
    [21] = {
        Name = "Forest_Ent",
        Health = 800,
        Damage = 75,
        Speed = 8,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(50, 100, 20),
        Material = Enum.Material.Wood,
        MeshId = "rbxassetid://1060481268",
        Biome = "Forest"
    },
    [22] = {
        Name = "Ice_Troll",
        Health = 600,
        Damage = 60,
        Speed = 15,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(200, 230, 255),
        Material = Enum.Material.Ice,
        MeshId = "rbxassetid://1060481268",
        Biome = "Mountain"
    },
    [23] = {
        Name = "Venomous_Toad",
        Health = 150,
        Damage = 35,
        Speed = 12,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(80, 160, 50),
        Material = Enum.Material.Pebble,
        MeshId = "rbxassetid://1060481268",
        Biome = "Swamp",
        SpecialAbility = "PoisonSpit"
    },
    [24] = {
        Name = "Steel_Automaton",
        Health = 900,
        Damage = 50,
        Speed = 14,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(150, 150, 160),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268",
        Biome = "Ruins"
    },
    [25] = {
        Name = "Blood_Seeker",
        Health = 250,
        Damage = 80,
        Speed = 25,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(180, 0, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "PortalDomain"
    },
    [26] = {
        Name = "Lightning_Bird",
        Health = 120,
        Damage = 40,
        Speed = 40,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(255, 255, 100),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "WeatherDisaster",
        SpecialAbility = "Flight"
    }
}

function MonsterSystemBatch3.SpawnMonster(id, position)
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

return MonsterSystemBatch3
