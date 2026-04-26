-- STREET_LIGHTS_BATCH.lua
-- Rancang 20 tipe street light unik untuk Century-Class O'Neill Orbital Habitat.

local StreetLightSystem = {}

-- Array defining 20 distinct street light types tailored for an O'Neill Cylinder
local LightData = {
    [1] = { Name = "Standard_Arcology_Lamp", Height = 15, LightColor = Color3.fromRGB(255, 244, 214), Range = 40, Brightness = 2, Style = "Modern" },
    [2] = { Name = "Zero_G_Axis_Beacon", Height = 50, LightColor = Color3.fromRGB(150, 200, 255), Range = 100, Brightness = 5, Style = "SciFi" },
    [3] = { Name = "Agricultural_UV_Lamp", Height = 20, LightColor = Color3.fromRGB(200, 50, 255), Range = 30, Brightness = 3, Style = "Industrial" },
    [4] = { Name = "Regolith_Pathway_Light", Height = 5, LightColor = Color3.fromRGB(255, 150, 50), Range = 15, Brightness = 1, Style = "Rustic" },
    [5] = { Name = "Maglev_Track_Illuminator", Height = 10, LightColor = Color3.fromRGB(50, 255, 255), Range = 60, Brightness = 4, Style = "Neon" },
    [6] = { Name = "Habitat_Valley_Floodlight", Height = 80, LightColor = Color3.fromRGB(255, 255, 255), Range = 200, Brightness = 8, Style = "Industrial" },
    [7] = { Name = "Sabatier_Reactor_Warning_Light", Height = 12, LightColor = Color3.fromRGB(255, 0, 0), Range = 25, Brightness = 3, Style = "Warning" },
    [8] = { Name = "Holographic_Ad_Pillar", Height = 25, LightColor = Color3.fromRGB(255, 100, 200), Range = 35, Brightness = 2, Style = "Cyberpunk" },
    [9] = { Name = "Water_Reclamation_Glow", Height = 8, LightColor = Color3.fromRGB(0, 150, 255), Range = 20, Brightness = 1.5, Style = "Subtle" },
    [10] = { Name = "O'Neill_Curve_Uplight", Height = 2, LightColor = Color3.fromRGB(255, 250, 240), Range = 150, Brightness = 6, Style = "Architectural" },
    [11] = { Name = "Nanotube_Strut_Marker", Height = 5, LightColor = Color3.fromRGB(0, 255, 100), Range = 10, Brightness = 1, Style = "Minimalist" },
    [12] = { Name = "Fusion_Hub_Ambient", Height = 40, LightColor = Color3.fromRGB(255, 200, 100), Range = 80, Brightness = 4, Style = "Warm" },
    [13] = { Name = "Aeroponic_Mist_Lamp", Height = 15, LightColor = Color3.fromRGB(100, 255, 150), Range = 25, Brightness = 2, Style = "Organic" },
    [14] = { Name = "Drone_Swarm_Dock_Light", Height = 10, LightColor = Color3.fromRGB(255, 255, 0), Range = 30, Brightness = 2.5, Style = "Industrial" },
    [15] = { Name = "Chevron_Mirror_Reflector", Height = 100, LightColor = Color3.fromRGB(255, 255, 255), Range = 300, Brightness = 10, Style = "Colossal" },
    [16] = { Name = "Residential_Alley_Sconce", Height = 8, LightColor = Color3.fromRGB(255, 220, 180), Range = 15, Brightness = 1.2, Style = "Classic" },
    [17] = { Name = "AIMP_Sensor_Node_Light", Height = 3, LightColor = Color3.fromRGB(0, 50, 255), Range = 5, Brightness = 0.8, Style = "Cyberpunk" },
    [18] = { Name = "Thermal_Radiator_Glow", Height = 20, LightColor = Color3.fromRGB(255, 50, 0), Range = 40, Brightness = 3, Style = "Warning" },
    [19] = { Name = "Asteroid_Slag_Miner_Lamp", Height = 30, LightColor = Color3.fromRGB(200, 200, 150), Range = 70, Brightness = 5, Style = "Rugged" },
    [20] = { Name = "L4_Lagrange_Beacon", Height = 150, LightColor = Color3.fromRGB(255, 0, 255), Range = 500, Brightness = 10, Style = "Colossal" }
}

function StreetLightSystem.SpawnLight(typeId, position)
    local data = LightData[typeId]
    if not data then return end

    local model = Instance.new("Model")
    model.Name = data.Name

    -- The Main Pole/Structure
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(1, data.Height, 1)
    pole.Position = position + Vector3.new(0, data.Height/2, 0)
    pole.Anchored = true
    pole.Material = Enum.Material.Metal
    pole.Color = Color3.fromRGB(50, 50, 55)
    pole.Parent = model

    -- The Luminaire (Bulb housing)
    local bulb = Instance.new("Part")
    bulb.Name = "Luminaire"
    bulb.Shape = Enum.PartType.Ball
    bulb.Size = Vector3.new(2, 2, 2)
    bulb.Position = pole.Position + Vector3.new(0, data.Height/2, 0)
    bulb.Anchored = true
    bulb.Material = Enum.Material.Neon
    bulb.Color = data.LightColor
    bulb.Parent = model

    -- The Actual Light Source
    local pointLight = Instance.new("PointLight")
    pointLight.Color = data.LightColor
    pointLight.Range = data.Range
    pointLight.Brightness = data.Brightness
    pointLight.Shadows = true
    pointLight.Parent = bulb

    -- Add specific visual flairs based on Style
    if data.Style == "Warning" then
        -- Blinking logic for warning lights
        task.spawn(function()
            while model.Parent do
                pointLight.Enabled = not pointLight.Enabled
                bulb.Transparency = pointLight.Enabled and 0 or 0.8
                task.wait(1)
            end
        end)
    elseif data.Style == "Cyberpunk" or data.Style == "Neon" then
        local beam = Instance.new("Beam")
        -- Requires attachments to work perfectly, but we simulate neon aesthetic by making the pole emit light too
        pole.Material = Enum.Material.Neon
        pole.Color = data.LightColor
    end

    model.PrimaryPart = pole
    model.Parent = workspace

    return model
end

-- Generates a procedural street along a given vector with a specific light type
function StreetLightSystem.GenerateStreetAvenue(lightTypeId, startPos, directionVector, length, spacing)
    local count = math.floor(length / spacing)
    local dir = directionVector.Unit

    for i = 0, count do
        local spawnPos = startPos + (dir * (i * spacing))
        StreetLightSystem.SpawnLight(lightTypeId, spawnPos)
    end
    print("Generated an avenue of " .. count .. " " .. LightData[lightTypeId].Name .. "s.")
end

return StreetLightSystem
