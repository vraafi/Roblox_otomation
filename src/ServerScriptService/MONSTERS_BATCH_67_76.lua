-- MONSTERS_BATCH_67_76.lua (Handling Tasks MONSTER_67 to MONSTER_76)
-- Rancang monster unik untuk bioma.

local MonsterSystemBatch8 = {}

local MonsterData = {
    [67] = {
        Name = "Abyssal_Leech",
        Health = 400,
        Damage = 25,
        Speed = 16,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(20, 10, 40),
        Material = Enum.Material.Mud,
        MeshId = "rbxassetid://1060481268", -- Placeholder
        Biome = "Flood",
        SpecialAbility = "LifeSteal"
    },
    [68] = {
        Name = "Obsidian_Scarab",
        Health = 600,
        Damage = 45,
        Speed = 20,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(30, 30, 35),
        Material = Enum.Material.Slate,
        MeshId = "rbxassetid://1060481268",
        Biome = "Volcano"
    },
    [69] = {
        Name = "Wind_Djinn",
        Health = 800,
        Damage = 85,
        Speed = 30,
        DropCoreLevel = 6,
        Color = Color3.fromRGB(200, 255, 255),
        Material = Enum.Material.ForceField,
        MeshId = "rbxassetid://1060481268",
        Biome = "WeatherDisaster",
        SpecialAbility = "Flight"
    },
    [70] = {
        Name = "Rot_Stalker",
        Health = 350,
        Damage = 55,
        Speed = 24,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(80, 100, 40),
        Material = Enum.Material.Wood,
        MeshId = "rbxassetid://1060481268",
        Biome = "Swamp",
        SpecialAbility = "Invisibility"
    },
    [71] = {
        Name = "Crystal_Gargoyle",
        Health = 900,
        Damage = 95,
        Speed = 14,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(150, 100, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://1060481268",
        Biome = "Cave",
        SpecialAbility = "Flight"
    },
    [72] = {
        Name = "Dune_Worm",
        Health = 1500,
        Damage = 140,
        Speed = 18,
        DropCoreLevel = 7,
        Color = Color3.fromRGB(220, 180, 120),
        Material = Enum.Material.Sand,
        MeshId = "rbxassetid://1060481268",
        Biome = "Desert",
        SpecialAbility = "Burrow"
    },
    [73] = {
        Name = "Frost_Bite_Spider",
        Health = 250,
        Damage = 60,
        Speed = 28,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(200, 230, 255),
        Material = Enum.Material.Ice,
        MeshId = "rbxassetid://1060481268",
        Biome = "Mountain"
    },
    [74] = {
        Name = "Ember_Drake",
        Health = 1100,
        Damage = 110,
        Speed = 22,
        DropCoreLevel = 6,
        Color = Color3.fromRGB(255, 60, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "Volcano",
        SpecialAbility = "Flight"
    },
    [75] = {
        Name = "Void_Annihilator",
        Health = 4000,
        Damage = 250,
        Speed = 10,
        DropCoreLevel = 9,
        Color = Color3.fromRGB(20, 0, 40),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "PortalDomain",
        SpecialAbility = "FearAura"
    },
    [76] = {
        Name = "Toxic_Horror",
        Health = 700,
        Damage = 65,
        Speed = 15,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(100, 255, 100),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "CityRuins",
        SpecialAbility = "PoisonCloud"
    }
}

function MonsterSystemBatch8.SpawnMonster(id, position)
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
                        if data.SpecialAbility == "LifeSteal" then
                            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (data.Damage * 0.5))
                        end
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

return MonsterSystemBatch8
