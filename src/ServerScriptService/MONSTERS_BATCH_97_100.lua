-- MONSTERS_BATCH_97_100.lua (Handling Tasks MONSTER_97 to MONSTER_100)
-- Final 4 monsters to complete the 100 monster requirement!

local MonsterSystemBatch11 = {}

local MonsterData = {
    [97] = {
        Name = "Plague_Harvester",
        Health = 900,
        Damage = 75,
        Speed = 16,
        DropCoreLevel = 5,
        Color = Color3.fromRGB(80, 120, 80),
        Material = Enum.Material.CorrodedMetal,
        MeshId = "rbxassetid://114425114", -- Placeholder
        Biome = "CityRuins",
        SpecialAbility = "PoisonCloud"
    },
    [98] = {
        Name = "Crystal_Drake",
        Health = 3000,
        Damage = 180,
        Speed = 26,
        DropCoreLevel = 8,
        Color = Color3.fromRGB(200, 150, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://382103444",
        Biome = "Cave",
        SpecialAbility = "Flight"
    },
    [99] = {
        Name = "Ember_Behemoth",
        Health = 5000,
        Damage = 250,
        Speed = 12,
        DropCoreLevel = 9,
        Color = Color3.fromRGB(255, 80, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://114425114",
        Biome = "Volcano",
        SpecialAbility = "Quake"
    },
    [100] = {
        Name = "The_Absolute_Apex",
        Health = 15000,
        Damage = 500,
        Speed = 30,
        DropCoreLevel = 9,
        Color = Color3.fromRGB(0, 0, 0),
        Material = Enum.Material.ForceField,
        MeshId = "rbxassetid://444453051",
        Biome = "PortalDomain",
        SpecialAbility = "Teleport" -- The final boss monster
    }
}

function MonsterSystemBatch11.SpawnMonster(id, position)
    local data = MonsterData[id]
    if not data then return end

    local model = Instance.new("Model")
    model.Name = data.Name

    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(4, 5, 4)

    if data.Name == "The_Absolute_Apex" then
        rootPart.Size = Vector3.new(12, 15, 12) -- Massive boss size
    end

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
        if data.Name == "The_Absolute_Apex" then
            mesh.Scale = Vector3.new(3, 3, 3)
        end
        mesh.Parent = rootPart
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = data.Health
    humanoid.Health = data.Health
    humanoid.WalkSpeed = data.Speed
    humanoid.Parent = model

    model.PrimaryPart = rootPart
    model.Parent = workspace

    task.spawn(function()
        while humanoid.Health > 0 and model.Parent do
            task.wait(2)

            local target = nil
            local dist = 100
            if data.Name == "The_Absolute_Apex" then dist = 300 end -- Boss sees further

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
                    if dist < 18 then
                        local targetHum = target.Parent:FindFirstChild("Humanoid")
                        if targetHum then targetHum:TakeDamage(data.Damage) end
                    end
                else
                    humanoid:MoveTo(target.Position)
                    local attackRange = 6
                    if data.Name == "The_Absolute_Apex" then attackRange = 15 end

                    if dist < attackRange then
                        local targetHum = target.Parent:FindFirstChild("Humanoid")
                        if targetHum then targetHum:TakeDamage(data.Damage) end
                    end
                end

                if data.SpecialAbility == "Teleport" and dist > 25 and dist < 100 then
                    if math.random() > 0.6 then
                        rootPart:PivotTo(target.CFrame + Vector3.new(0, 10, 0))
                    end
                end
            end
        end

        if humanoid.Health <= 0 then
            print(data.Name .. " died! Dropped Core Level " .. data.DropCoreLevel)
            local coreDrop = Instance.new("Part")
            coreDrop.Name = "Monster_Core_T" .. tostring(data.DropCoreLevel)
            coreDrop.Shape = Enum.PartType.Ball
            coreDrop.Size = Vector3.new(2, 2, 2)
            coreDrop.Position = rootPart.Position
            coreDrop.Material = Enum.Material.Neon
            coreDrop.Color = Color3.fromRGB(255, 255 - (data.DropCoreLevel * 20), 0)
            coreDrop.Parent = workspace
        end
    end)

    return model
end

return MonsterSystemBatch11
