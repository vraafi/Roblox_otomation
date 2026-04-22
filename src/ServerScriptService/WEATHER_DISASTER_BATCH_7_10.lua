-- WEATHER_DISASTER_BATCH_7_10.lua (Handling Tasks WEATHER_DISASTER_7 to WEATHER_DISASTER_10)
-- Rancang sistem cuaca dan bencana alam yang mempengaruhi bioma.

local WeatherDisasterBatch26 = {}

local WeatherData = {
    [7] = {
        Name = "Solar_Flare",
        Color = Color3.fromRGB(255, 255, 200),
        DamagePerTick = 12,
        Duration = 40,
        SlowDebuff = 1.0,
        SpecialEffect = "Blindness"
    },
    [8] = {
        Name = "Abyssal_Rift",
        Color = Color3.fromRGB(20, 0, 50),
        DamagePerTick = 25,
        Duration = 60,
        SlowDebuff = 0.4, -- Massive slow due to gravity pull
        SpecialEffect = "GravityPull"
    },
    [9] = {
        Name = "Crystal_Shatter",
        Color = Color3.fromRGB(200, 150, 255),
        DamagePerTick = 15, -- Sharp shrapnel in the wind
        Duration = 45,
        SlowDebuff = 0.9,
    },
    [10] = {
        Name = "The_Apex_Wipe",
        Color = Color3.fromRGB(0, 0, 0),
        DamagePerTick = 9999, -- Instant death if caught
        Duration = 10,
        SlowDebuff = 0.1,
        SpecialEffect = "ServerWipe"
    }
}

function WeatherDisasterBatch26.TriggerDisaster(disasterId, targetAreaCenter, areaRadius)
    local data = WeatherData[disasterId]
    if not data then return end

    print("CRITICAL WARNING: " .. data.Name .. " has begun!")

    local effectPart = Instance.new("Part")
    effectPart.Name = "WeatherEffect_" .. data.Name
    effectPart.Shape = Enum.PartType.Cylinder
    effectPart.Size = Vector3.new(areaRadius * 2, 500, areaRadius * 2)
    effectPart.Position = targetAreaCenter + Vector3.new(0, 250, 0)
    effectPart.Orientation = Vector3.new(0, 0, 90)
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 0.5
    effectPart.Color = data.Color
    effectPart.Material = Enum.Material.Neon
    effectPart.Parent = workspace

    local isActive = true

    task.delay(data.Duration, function()
        isActive = false
        effectPart:Destroy()
        print(data.Name .. " has dissipated.")
    end)

    task.spawn(function()
        while isActive and effectPart.Parent do
            task.wait(1)

            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local charPos = player.Character.HumanoidRootPart.Position
                    local dx = charPos.X - targetAreaCenter.X
                    local dz = charPos.Z - targetAreaCenter.Z
                    local distSq = (dx * dx) + (dz * dz)

                    if distSq <= (areaRadius * areaRadius) then
                        local humanoid = player.Character:FindFirstChild("Humanoid")
                        if humanoid then
                            if data.DamagePerTick > 0 then
                                humanoid:TakeDamage(data.DamagePerTick)
                            end

                            if data.SpecialEffect == "GravityPull" then
                                -- Pull player towards center
                                local pullDir = (Vector3.new(targetAreaCenter.X, charPos.Y, targetAreaCenter.Z) - charPos).Unit
                                player.Character:PivotTo(player.Character:GetPivot() + (pullDir * 5))
                            end
                        end
                    end
                end
            end
        end
    end)

    return effectPart
end

return WeatherDisasterBatch26
