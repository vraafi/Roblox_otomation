-- MONSTERS_BATCH_47_56.lua (Handling Tasks MONSTER_47 to MONSTER_56)
-- Rancang monster unik untuk bioma.

local MonsterSystemBatch6 = {}

local MonsterData = {
    [47] = {
        Name = "Radiant_Stag",
        Health = 350,
        Damage = 40,
        Speed = 30,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(255, 255, 200),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268", -- Placeholder
        Biome = "Forest",
        SpecialAbility = "HealAura"
    },
    [48] = {
        Name = "Cave_Troll",
        Health = 750,
        Damage = 70,
        Speed = 16,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(80, 80, 90),
        Material = Enum.Material.Slate,
        MeshId = "rbxassetid://1060481268",
        Biome = "Cave"
    },
    [49] = {
        Name = "Dune_Crawler",
        Health = 220,
        Damage = 35,
        Speed = 22,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(210, 180, 140),
        Material = Enum.Material.Sand,
        MeshId = "rbxassetid://1060481268",
        Biome = "Desert",
        SpecialAbility = "Burrow"
    },
    [50] = {
        Name = "Goliath_Beetle",
        Health = 1200,
        Damage = 55,
        Speed = 10,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(20, 50, 20),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://1060481268",
        Biome = "Jungle"
    },
    [51] = {
        Name = "Abyssal_Watcher",
        Health = 800,
        Damage = 110,
        Speed = 20,
        DropCoreLevel = 7,
        Color = Color3.fromRGB(10, 10, 40),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "PortalDomain",
        SpecialAbility = "FearAura"
    },
    [52] = {
        Name = "Coral_Golem",
        Health = 600,
        Damage = 60,
        Speed = 14,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(255, 127, 80),
        Material = Enum.Material.Pebble,
        MeshId = "rbxassetid://1060481268",
        Biome = "Flood"
    },
    [53] = {
        Name = "Blight_Hound",
        Health = 180,
        Damage = 45,
        Speed = 26,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(100, 150, 50),
        Material = Enum.Material.Plastic,
        MeshId = "rbxassetid://1060481268",
        Biome = "Swamp",
        SpecialAbility = "PoisonBite"
    },
    [54] = {
        Name = "Ember_Sprite",
        Health = 80,
        Damage = 25,
        Speed = 35,
        DropCoreLevel = 1,
        Color = Color3.fromRGB(255, 150, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
        Biome = "Volcano",
        SpecialAbility = "Flight"
    },
    [55] = {
        Name = "Wind_Weaver",
        Health = 400,
        Damage = 80,
        Speed = 28,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(200, 255, 255),
        Material = Enum.Material.ForceField,
        MeshId = "rbxassetid://1060481268",
        Biome = "WeatherDisaster",
        SpecialAbility = "Flight"
    },
    [56] = {
        Name = "Obsidian_Colossus",
        Health = 3500,
        Damage = 180,
        Speed = 8,
        DropCoreLevel = 9,
        Color = Color3.fromRGB(20, 20, 20),
        Material = Enum.Material.Slate,
        MeshId = "rbxassetid://1060481268",
        Biome = "Volcano",
        SpecialAbility = "Quake"
    }
}

function MonsterSystemBatch6.SpawnMonster(id, position)
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

return MonsterSystemBatch6
