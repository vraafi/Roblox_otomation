-- BIOME_SYSTEM_1_6.lua (Handling Tasks BIOME_1 to BIOME_6)
-- Rancang bioma lingkungan ekstrem.

local BiomeSystem = {}

local BiomeData = {
    [1] = {
        Name = "Flood_Zone",
        Color = Color3.fromRGB(20, 50, 100),
        Material = Enum.Material.Ice, -- Simulate deep water slickness
        HasWater = true,
        WaterHeight = 15,
        Size = Vector3.new(500, 2, 500)
    },
    [2] = {
        Name = "Volcano_Crater",
        Color = Color3.fromRGB(80, 20, 20),
        Material = Enum.Material.Slate,
        HasLava = true,
        Size = Vector3.new(400, 2, 400)
    },
    [3] = {
        Name = "Scorched_Desert",
        Color = Color3.fromRGB(210, 180, 140),
        Material = Enum.Material.Sand,
        Weather = "Sandstorm",
        Size = Vector3.new(800, 2, 800)
    },
    [4] = {
        Name = "Toxic_Swamp",
        Color = Color3.fromRGB(40, 60, 20),
        Material = Enum.Material.Mud,
        HasPoisonGas = true,
        Size = Vector3.new(600, 2, 600)
    },
    [5] = {
        Name = "Frozen_Mountain",
        Color = Color3.fromRGB(240, 255, 255),
        Material = Enum.Material.Ice,
        Weather = "Blizzard",
        Size = Vector3.new(500, 100, 500) -- Tall
    },
    [6] = {
        Name = "Overgrown_Jungle",
        Color = Color3.fromRGB(10, 80, 20),
        Material = Enum.Material.Grass,
        DenseFoliage = true,
        Size = Vector3.new(700, 2, 700)
    }
}

function BiomeSystem.GenerateBiome(biomeId, originPosition)
    local data = BiomeData[biomeId]
    if not data then return end

    local biomeFolder = Instance.new("Folder")
    biomeFolder.Name = "Biome_" .. data.Name
    biomeFolder.Parent = workspace

    -- Main Floor
    local floor = Instance.new("Part")
    floor.Name = "Ground"
    floor.Size = data.Size
    floor.Position = originPosition
    floor.Anchored = true
    floor.Color = data.Color
    floor.Material = data.Material
    floor.Parent = biomeFolder

    -- Procedural Features
    if data.HasWater then
        local water = Instance.new("Part")
        water.Name = "FloodWater"
        water.Size = Vector3.new(data.Size.X, data.WaterHeight, data.Size.Z)
        water.Position = originPosition + Vector3.new(0, data.WaterHeight/2, 0)
        water.Anchored = true
        water.CanCollide = false
        water.Transparency = 0.5
        water.Color = Color3.fromRGB(0, 100, 255)
        water.Material = Enum.Material.Glass
        water.Parent = biomeFolder
    end

    if data.HasLava then
        -- Generate Lava Pools
        for i = 1, 15 do
            local pool = Instance.new("Part")
            pool.Name = "LavaPool"
            pool.Shape = Enum.PartType.Cylinder
            pool.Size = Vector3.new(1, math.random(20, 50), math.random(20, 50))
            pool.Position = originPosition + Vector3.new(math.random(-150, 150), 1, math.random(-150, 150))
            pool.Orientation = Vector3.new(0, 0, 90)
            pool.Anchored = true
            pool.Color = Color3.fromRGB(255, 50, 0)
            pool.Material = Enum.Material.Neon
            pool.Parent = biomeFolder

            -- Lava touch damage logic
            pool.Touched:Connect(function(hit)
                local humanoid = hit.Parent:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:TakeDamage(5) -- 5 damage per tick
                end
            end)
        end
    end

    if data.DenseFoliage then
        -- Procedurally generate trees (Asset IDs would normally go here)
        for i = 1, 100 do
            local tree = Instance.new("Part")
            tree.Size = Vector3.new(2, math.random(20, 40), 2)
            tree.Position = originPosition + Vector3.new(math.random(-300, 300), tree.Size.Y/2, math.random(-300, 300))
            tree.Anchored = true
            tree.Color = Color3.fromRGB(80, 60, 40)
            tree.Material = Enum.Material.Wood
            tree.Parent = biomeFolder

            local leaves = Instance.new("Part")
            leaves.Shape = Enum.PartType.Ball
            leaves.Size = Vector3.new(15, 15, 15)
            leaves.Position = tree.Position + Vector3.new(0, tree.Size.Y/2, 0)
            leaves.Anchored = true
            leaves.Color = Color3.fromRGB(20, 100, 30)
            leaves.Material = Enum.Material.Grass
            leaves.Parent = biomeFolder
        end
    end

    if data.HasPoisonGas then
        -- Create gas zones
        local gas = Instance.new("Part")
        gas.Name = "PoisonGas"
        gas.Size = Vector3.new(data.Size.X, 20, data.Size.Z)
        gas.Position = originPosition + Vector3.new(0, 10, 0)
        gas.Anchored = true
        gas.CanCollide = false
        gas.Transparency = 0.7
        gas.Color = Color3.fromRGB(150, 255, 50)
        gas.Material = Enum.Material.Neon
        gas.Parent = biomeFolder

        -- Gas damage loop
        task.spawn(function()
            while gas.Parent do
                task.wait(2)
                for _, player in ipairs(game.Players:GetPlayers()) do
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        -- Simplified: If they are within the X/Z bounds
                        local pos = player.Character.HumanoidRootPart.Position
                        if pos.Y < originPosition.Y + 20 then
                            local dx = math.abs(pos.X - originPosition.X)
                            local dz = math.abs(pos.Z - originPosition.Z)
                            if dx < data.Size.X/2 and dz < data.Size.Z/2 then
                                player.Character.Humanoid:TakeDamage(2)
                            end
                        end
                    end
                end
            end
        end)
    end

    print("Generated Biome: " .. data.Name)
    return biomeFolder
end

return BiomeSystem
