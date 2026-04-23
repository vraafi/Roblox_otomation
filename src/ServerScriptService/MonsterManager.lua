-- MonsterManager.lua
-- Centralized manager for spawning and handling AI logic for all 100 monsters.

local MonsterManager = {}

-- Because we generated the monster data in chunks, we need to assemble a master dictionary here
-- Simulated master data dictionary until batches are fully refactored
MonsterManager.MasterData = {}

function MonsterManager.Initialize()
    local ServerScriptService = game:GetService("ServerScriptService")

    -- In Roblox Luau, if a module doesn't explicitly return a table we can scrape, we must parse it.
    -- However, since the batches returned an interface with 'SpawnMonster' and not raw data,
    -- we will instead redirect SpawnRandomMonster to explicitly trigger the exact batch scripts.
    print("MonsterManager initialized to act as a unified spawn router.")
end

function MonsterManager.SpawnRandomMonster(position)
    local randomId = math.random(1, 100)
    local ServerScriptService = game:GetService("ServerScriptService")

    -- Determine which batch file holds this ID
    local targetBatch
    if randomId <= 6 then targetBatch = "MONSTERS_BATCH_1_6"
    elseif randomId <= 16 then targetBatch = "MONSTERS_BATCH_7_16"
    elseif randomId <= 26 then targetBatch = "MONSTERS_BATCH_17_26"
    elseif randomId <= 36 then targetBatch = "MONSTERS_BATCH_27_36"
    elseif randomId <= 46 then targetBatch = "MONSTERS_BATCH_37_46"
    elseif randomId <= 56 then targetBatch = "MONSTERS_BATCH_47_56"
    elseif randomId <= 66 then targetBatch = "MONSTERS_BATCH_57_66"
    elseif randomId <= 76 then targetBatch = "MONSTERS_BATCH_67_76"
    elseif randomId <= 86 then targetBatch = "MONSTERS_BATCH_77_86"
    elseif randomId <= 96 then targetBatch = "MONSTERS_BATCH_87_96"
    else targetBatch = "MONSTERS_BATCH_97_100" end

    -- Execute the actual batch script to spawn the genuine monster
    local success, module = pcall(function() return require(ServerScriptService:WaitForChild(targetBatch)) end)
    if success and module and module.SpawnMonster then
        -- This guarantees we get the exact visual, name, and abilities from the 100 generated tasks
        -- Example: Crystal Bat, Sand Worm, The Absolute Apex
        return module.SpawnMonster(randomId, position)
    else
        warn("MonsterManager Failed to load batch " .. targetBatch)
    end
end

function MonsterManager.SpawnMonsterByData(data, position)
    if not data then return end

    local model = Instance.new("Model")
    model.Name = data.Name

    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(4, 5, 4)
    if data.Name == "The_Absolute_Apex" then
        rootPart.Size = Vector3.new(12, 15, 12)
    end
    rootPart.Position = position
    rootPart.Color = data.Color or Color3.new(1, 1, 1)
    rootPart.Material = data.Material or Enum.Material.Plastic
    rootPart.Parent = model

    -- Visual Abilities
    if data.SpecialAbility == "Invisibility" then rootPart.Transparency = 0.9 end
    if data.SpecialAbility == "Intangible" then
        rootPart.Transparency = 0.5
        rootPart.CanCollide = false
    end
    if data.SpecialAbility == "Camouflage" then rootPart.Transparency = 0.8 end

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
        if data.Name == "The_Absolute_Apex" then mesh.Scale = Vector3.new(3, 3, 3) end
        mesh.Parent = rootPart
    end

    local humanoid = Instance.new("Humanoid")
    -- CRITICAL FIX: Prevent instant death when no Head part is attached
    humanoid.RequiresNeck = false
    humanoid.MaxHealth = data.Health or 100
    humanoid.Health = data.Health or 100
    humanoid.WalkSpeed = data.Speed or 16
    humanoid.Parent = model

    model.PrimaryPart = rootPart
    model.Parent = workspace

    -- Centralized AI Loop
    task.spawn(function()
        while humanoid.Health > 0 and model.Parent do
            task.wait(2)

            local target = nil
            local dist = 100
            if data.Name == "The_Absolute_Apex" then dist = 300 end

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
                    if bp then bp.Position = target.Position + Vector3.new(0, 15, 0) end
                    if dist < 18 then
                        local targetHum = target.Parent:FindFirstChild("Humanoid")
                        if targetHum then targetHum:TakeDamage(data.Damage or 10) end
                    end
                else
                    humanoid:MoveTo(target.Position)
                    local attackRange = 6
                    if data.Name == "The_Absolute_Apex" then attackRange = 15 end

                    if dist < attackRange then
                        local targetHum = target.Parent:FindFirstChild("Humanoid")
                        if targetHum then
                            targetHum:TakeDamage(data.Damage or 10)
                            if data.SpecialAbility == "LifeSteal" then
                                humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + ((data.Damage or 10) * 0.5))
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

        -- Death Logic & Cleanup
        if humanoid.Health <= 0 then
            print((data.Name or "Monster") .. " died! Dropped Core Level " .. tostring(data.DropCoreLevel or 1))

            local coreDrop = Instance.new("Part")
            coreDrop.Name = "Monster_Core_T" .. tostring(data.DropCoreLevel or 1)
            coreDrop.Shape = Enum.PartType.Ball
            coreDrop.Size = Vector3.new(1.5, 1.5, 1.5)
            coreDrop.Position = rootPart.Position
            coreDrop.Material = Enum.Material.Neon
            coreDrop.Color = Color3.fromRGB(255, 255 - ((data.DropCoreLevel or 1) * 20), 0)
            coreDrop.Parent = workspace

            -- CRITICAL FIX: Prevent memory leaks
            model:Destroy()
        end
    end)

    return model
end

return MonsterManager
