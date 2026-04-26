-- WEATHER_DISASTER_BATCH_1_6.lua (Handling Tasks WEATHER_DISASTER_1 to WEATHER_DISASTER_6)
-- Rancang sistem cuaca dan bencana alam yang mempengaruhi bioma.

local WeatherDisasterBatch25 = {}

local WeatherData = {
    [1] = {
        Name = "Acid_Rain",
        Color = Color3.fromRGB(150, 255, 50),
        DamagePerTick = 5,
        Duration = 60, -- Seconds
        SlowDebuff = 0.8
    },
    [2] = {
        Name = "Meteor_Shower",
        Color = Color3.fromRGB(255, 50, 0),
        DamagePerTick = 100, -- High damage if hit by blast
        Duration = 30,
        SlowDebuff = 1.0
    },
    [3] = {
        Name = "Blizzard",
        Color = Color3.fromRGB(220, 240, 255),
        DamagePerTick = 2,
        Duration = 90,
        SlowDebuff = 0.5 -- Very slow movement
    },
    [4] = {
        Name = "Sandstorm",
        Color = Color3.fromRGB(210, 180, 140),
        DamagePerTick = 1,
        Duration = 120,
        SlowDebuff = 0.7 -- Reduced visibility and speed
    },
    [5] = {
        Name = "Mana_Storm",
        Color = Color3.fromRGB(200, 100, 255),
        DamagePerTick = 0, -- Doesn't deal health damage
        ManaDrainPerTick = 20, -- Drains player mana
        Duration = 45,
        SlowDebuff = 1.0
    },
    [6] = {
        Name = "Toxic_Fog",
        Color = Color3.fromRGB(80, 120, 50),
        DamagePerTick = 8,
        Duration = 70,
        SlowDebuff = 0.85
    }
}

function WeatherDisasterBatch25.TriggerDisaster(disasterId, targetAreaCenter, areaRadius)
    local data = WeatherData[disasterId]
    if not data then return end

    print("WARNING: " .. data.Name .. " has begun!")

    -- Procedural Visual Effect based on type
    -- Create base boundary for the weather system
    local effectPart = Instance.new("Part")
    effectPart.Name = "WeatherEffect_" .. data.Name
    effectPart.Shape = Enum.PartType.Cylinder
    effectPart.Size = Vector3.new(areaRadius * 2, 200, areaRadius * 2)
    effectPart.Position = targetAreaCenter + Vector3.new(0, 100, 0)
    effectPart.Orientation = Vector3.new(0, 0, 90)
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1 -- Hide the cylinder itself
    effectPart.Parent = workspace

    -- Inject realistic particle emitters via Visual Overhaul
    local ServerScriptService = game:GetService("ServerScriptService")
    local VisualOverhaul = require(ServerScriptService:WaitForChild("VisualAssetOverhaul"))
    VisualOverhaul.CreateWeatherParticles(data.Name, effectPart)

    local isActive = true

    -- Cleanup after duration
    task.delay(data.Duration, function()
        isActive = false
        effectPart:Destroy()
        print(data.Name .. " has dissipated.")
    end)

    -- Effect Loop
    task.spawn(function()
        while isActive and effectPart.Parent do
            task.wait(1) -- Tick rate

            -- Meteor visual generation logic
            if data.Name == "Meteor_Shower" then
                local meteor = Instance.new("Part")
                meteor.Shape = Enum.PartType.Ball
                meteor.Size = Vector3.new(10, 10, 10)
                meteor.Position = targetAreaCenter + Vector3.new(math.random(-areaRadius, areaRadius), 200, math.random(-areaRadius, areaRadius))
                meteor.Color = Color3.fromRGB(255, 60, 0)
                meteor.Material = Enum.Material.Neon
                meteor.Anchored = false
                meteor.Parent = workspace

                -- Cleanup meteor
                task.delay(3, function() if meteor then meteor:Destroy() end end)
            end

            -- Damage / Debuff Application
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local charPos = player.Character.HumanoidRootPart.Position
                    -- Check if player is within the disaster cylinder
                    local dx = charPos.X - targetAreaCenter.X
                    local dz = charPos.Z - targetAreaCenter.Z
                    local distSq = (dx * dx) + (dz * dz)

                    if distSq <= (areaRadius * areaRadius) then
                        local humanoid = player.Character:FindFirstChild("Humanoid")
                        if humanoid then
                            if data.DamagePerTick > 0 then
                                humanoid:TakeDamage(data.DamagePerTick)
                            end

                            -- In a real integration, we would interface with PlayerManager.lua
                            -- to apply the SlowDebuff to their StatSystem.MoveSpeed, and deduct Mana.
                            -- e.g., if data.ManaDrainPerTick > 0 then PlayerManager.DrainMana(player, data.ManaDrainPerTick) end
                        end
                    end
                end
            end
        end
    end)

    return effectPart
end

return WeatherDisasterBatch25
