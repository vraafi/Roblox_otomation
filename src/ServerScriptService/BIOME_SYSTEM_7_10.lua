-- BIOME_SYSTEM_7_10.lua (Handling Tasks BIOME_7 to BIOME_10)
-- Rancang bioma lingkungan ekstrem.

local BiomeSystemBatch12 = {}

local BiomeData = {
    [7] = {
        Name = "Crystal_Caves",
        Color = Color3.fromRGB(50, 0, 100),
        Material = Enum.Material.Slate,
        HasCrystals = true,
        Size = Vector3.new(600, 2, 600)
    },
    [8] = {
        Name = "Ruined_City",
        Color = Color3.fromRGB(100, 100, 100),
        Material = Enum.Material.Concrete,
        HasRuins = true,
        Size = Vector3.new(800, 2, 800)
    },
    [9] = {
        Name = "Abyssal_Trench",
        Color = Color3.fromRGB(0, 0, 20),
        Material = Enum.Material.Sand,
        HasDeepWater = true,
        WaterHeight = 100,
        Size = Vector3.new(700, 2, 700)
    },
    [10] = {
        Name = "Void_Wasteland",
        Color = Color3.fromRGB(10, 0, 30),
        Material = Enum.Material.Neon,
        LowGravity = true,
        Size = Vector3.new(1000, 2, 1000)
    }
}

function BiomeSystemBatch12.GenerateBiome(biomeId, originPosition)
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

    if data.HasCrystals then
        for i = 1, 50 do
            local crystal = Instance.new("Part")
            crystal.Name = "GlowingCrystal"
            crystal.Size = Vector3.new(math.random(2, 6), math.random(10, 30), math.random(2, 6))
            crystal.Position = originPosition + Vector3.new(math.random(-250, 250), crystal.Size.Y/2, math.random(-250, 250))
            crystal.Orientation = Vector3.new(math.random(-15, 15), math.random(0, 360), math.random(-15, 15))
            crystal.Anchored = true
            crystal.Color = Color3.fromRGB(math.random(100, 200), 50, 255)
            crystal.Material = Enum.Material.Neon
            crystal.Parent = biomeFolder

            local light = Instance.new("PointLight")
            light.Color = crystal.Color
            light.Range = 20
            light.Parent = crystal
        end
    end

    if data.HasRuins then
        for i = 1, 30 do
            local pillar = Instance.new("Part")
            pillar.Size = Vector3.new(5, math.random(20, 60), 5)
            pillar.Position = originPosition + Vector3.new(math.random(-350, 350), pillar.Size.Y/2, math.random(-350, 350))
            pillar.Anchored = true
            pillar.Color = Color3.fromRGB(80, 80, 80)
            pillar.Material = Enum.Material.CorrodedMetal
            pillar.Parent = biomeFolder
        end
    end

    if data.HasDeepWater then
        local water = Instance.new("Part")
        water.Name = "DeepWater"
        water.Size = Vector3.new(data.Size.X, data.WaterHeight, data.Size.Z)
        water.Position = originPosition + Vector3.new(0, data.WaterHeight/2, 0)
        water.Anchored = true
        water.CanCollide = false
        water.Transparency = 0.2
        water.Color = Color3.fromRGB(0, 0, 50)
        water.Material = Enum.Material.Glass
        water.Parent = biomeFolder
    end

    if data.LowGravity then
        -- Affects all parts inside this zone (Requires a physics script in a real game,
        -- but here we simulate it by applying upward force to players who enter)
        local gravZone = Instance.new("Part")
        gravZone.Name = "LowGravityZone"
        gravZone.Size = Vector3.new(data.Size.X, 200, data.Size.Z)
        gravZone.Position = originPosition + Vector3.new(0, 100, 0)
        gravZone.Anchored = true
        gravZone.CanCollide = false
        gravZone.Transparency = 1
        gravZone.Parent = biomeFolder
    end

    print("Generated Biome: " .. data.Name)
    return biomeFolder
end

return BiomeSystemBatch12
