-- MONSTERS_BATCH.lua (Handling Tasks MONSTER_1 to MONSTER_6)
-- Rancang monster unik untuk bioma.

local MonsterSystem = {}

local MonsterData = {
    [1] = {
        Name = "Goblin_Scavenger",
        Health = 100,
        Damage = 15,
        Speed = 18,
        DropCoreLevel = 1,
        Color = Color3.fromRGB(50, 150, 50),
        MeshId = "rbxassetid://1060481268", -- Placeholder Goblin Mesh
    },
    [2] = {
        Name = "Wolf_Alpha",
        Health = 150,
        Damage = 25,
        Speed = 22,
        DropCoreLevel = 2,
        Color = Color3.fromRGB(100, 100, 100),
        MeshId = "rbxassetid://1060481268", -- Placeholder Wolf Mesh
    },
    [3] = {
        Name = "Rock_Golem",
        Health = 500,
        Damage = 40,
        Speed = 10,
        DropCoreLevel = 4,
        Color = Color3.fromRGB(130, 130, 130),
        MeshId = "rbxassetid://1060481268", -- Placeholder Golem Mesh
    },
    [4] = {
        Name = "Flame_Sprite",
        Health = 80,
        Damage = 35,
        Speed = 20,
        DropCoreLevel = 3,
        Color = Color3.fromRGB(255, 100, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://1060481268",
    },
    [5] = {
        Name = "Troll_Brute",
        Health = 800,
        Damage = 60,
        Speed = 14,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(40, 100, 40),
        MeshId = "rbxassetid://1060481268",
    },
    [6] = {
        Name = "Elder_Dragon",
        Health = 5000,
        Damage = 150,
        Speed = 30,
        DropCoreLevel = 9,
        Color = Color3.fromRGB(200, 0, 0),
        MeshId = "rbxassetid://1060481268",
    }
}

function MonsterSystem.SpawnMonster(id, position)
    local data = MonsterData[id]
    if not data then return end

    -- In Roblox, standard AI uses a rig with a Humanoid.
    -- For simplicity and performance in procedurally generated worlds, we build a basic part representation
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

    -- Very Basic AI Loop
    task.spawn(function()
        while humanoid.Health > 0 and model.Parent do
            task.wait(2)
            -- Find nearest player
            local target = nil
            local dist = 100 -- Aggro range
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
                if dist < 5 then
                    -- Attack (simplified)
                    local targetHum = target.Parent:FindFirstChild("Humanoid")
                    if targetHum then
                        targetHum:TakeDamage(data.Damage)
                    end
                end
            end
        end

        -- Death logic
        if humanoid.Health <= 0 then
            print(data.Name .. " died! Dropped Core Level " .. data.DropCoreLevel)
            -- Spawn core physical item here
        end
    end)

    return model
end

return MonsterSystem
