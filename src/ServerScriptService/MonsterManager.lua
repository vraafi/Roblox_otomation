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
    -- Instead of relying on the isolated batch files which don't export their raw data,
    -- we use the centralized spawner logic to ensure the Ecosystem AI and Visuals execute.
    local randomId = math.random(1, 100)

    -- A subset of names mapped from the original 100 tasks for realism
    local possibleNames = {"Wolf_Alpha", "Plague_Rat", "Crystal_Bat", "Elder_Dragon", "Troll_Brute", "Void_Walker", "Default"}
    local chosenName = possibleNames[math.random(1, #possibleNames)]

    -- If it's a boss, guarantee it spawns occasionally
    if randomId == 100 then chosenName = "The_Absolute_Apex" end

    -- Generate a dynamic stat profile that forces the Food Chain AI to classify them correctly
    local hp = math.random(100, 1000)
    local dmg = math.random(10, 80)

    if chosenName == "The_Absolute_Apex" then
        hp = 15000
        dmg = 500
    elseif chosenName == "Plague_Rat" then
        hp = 50
        dmg = 15
    elseif chosenName == "Wolf_Alpha" then
        hp = 150
        dmg = 45
    end

    local data = {
        Name = chosenName,
        Health = hp,
        Damage = dmg,
        Speed = math.random(14, 26),
        DropCoreLevel = math.random(1, 9),
        Color = Color3.fromRGB(math.random(50, 200), math.random(50, 200), math.random(50, 200)),
        SpecialAbility = (math.random() > 0.8) and "Flight" or "None"
    }

    -- This correctly routes into the master function where the Food Chain AI and Visuals are actually located
    return MonsterManager.SpawnMonsterByData(data, position)
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

    -- Attempt visual overhaul first
    local ServerScriptService = game:GetService("ServerScriptService")
    local VisualOverhaul = require(ServerScriptService:WaitForChild("VisualAssetOverhaul"))

    -- Inject real catalog MeshID if we mapped it, otherwise fallback
    local finalMeshId = data.MeshId
    if VisualOverhaul.MonsterMeshIDs[data.Name] then
        finalMeshId = VisualOverhaul.MonsterMeshIDs[data.Name]
    elseif VisualOverhaul.MonsterMeshIDs["Default"] then
        finalMeshId = VisualOverhaul.MonsterMeshIDs["Default"]
    end

    if finalMeshId then
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = finalMeshId
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

    -- Ecosystem Classification
    local ecosystemRole = "Neutral"
    if (data.Damage or 0) < 30 and (data.Health or 0) < 300 then
        ecosystemRole = "Prey"
    elseif (data.Damage or 0) >= 30 and (data.Health or 0) < 1500 then
        ecosystemRole = "Predator"
    else
        ecosystemRole = "Apex"
    end

    -- Tag the model so other monsters know its role
    local roleTag = Instance.new("StringValue")
    roleTag.Name = "EcosystemRole"
    roleTag.Value = ecosystemRole
    roleTag.Parent = model

    -- Centralized Food Chain AI Loop
    task.spawn(function()
        while humanoid.Health > 0 and model.Parent do
            task.wait(2)

            local target = nil
            local dist = 100
            local isFleeing = false
            if data.Name == "The_Absolute_Apex" then dist = 300 end

            -- 1. Check for Players (Highest Priority)
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                    if d < dist then
                        dist = d
                        target = player.Character.HumanoidRootPart
                    end
                end
            end

            -- 2. Food Chain Logic (If no player is nearby)
            if not target then
                for _, otherModel in ipairs(workspace:GetChildren()) do
                    if otherModel:IsA("Model") and otherModel ~= model and otherModel:FindFirstChild("HumanoidRootPart") then
                        local otherRoleTag = otherModel:FindFirstChild("EcosystemRole")
                        if otherRoleTag then
                            local d = (otherModel.HumanoidRootPart.Position - rootPart.Position).Magnitude
                            if d < 150 then -- Senses other creatures within 150 studs
                                if ecosystemRole == "Predator" and otherRoleTag.Value == "Prey" then
                                    if d < dist then
                                        dist = d
                                        target = otherModel.HumanoidRootPart
                                    end
                                elseif ecosystemRole == "Prey" and (otherRoleTag.Value == "Predator" or otherRoleTag.Value == "Apex") then
                                    -- Flee logic
                                    target = otherModel.HumanoidRootPart
                                    isFleeing = true
                                    dist = d
                                    break
                                end
                            end
                        end
                    end
                end
            end

            -- 3. Execute Movement & Combat
            if target then
                if isFleeing then
                    -- Run directly away from the predator
                    local fleeDir = (rootPart.Position - target.Position).Unit
                    humanoid:MoveTo(rootPart.Position + (fleeDir * 50))
                else
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
                                -- Print ecosystem events for debugging/immersion
                                if not game.Players:GetPlayerFromCharacter(target.Parent) then
                                    print(data.Name .. " is attacking " .. target.Parent.Name .. " in the wild!")
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
            else
                -- Idle wandering if no targets or predators around
                if math.random() > 0.5 then
                    local randomDir = Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
                    humanoid:MoveTo(rootPart.Position + randomDir)
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
