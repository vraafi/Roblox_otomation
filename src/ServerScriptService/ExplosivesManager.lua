-- ExplosivesManager.lua
-- Handles physical grenade throwing, blast radius calculation, and visual effects.

local ExplosivesManager = {}
local Debris = game:GetService("Debris")

-- Item Database mapping for explosive properties
local ExplosiveStats = {
    ["Tear_Gas_Grenade"] = { Radius = 20, Damage = 15, Duration = 8, Type = "Gas", Color = Color3.fromRGB(150, 150, 150) },
    -- Future expansion for Frag Grenades, Molotovs, etc.
}

function ExplosivesManager.Initialize()
    local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    if not events then return end

    local throwEvent = Instance.new("RemoteEvent")
    throwEvent.Name = "ThrowGrenade"
    throwEvent.Parent = events

    throwEvent.OnServerEvent:Connect(ExplosivesManager.HandleThrow)
    print("Explosives Manager Initialized.")
end

function ExplosivesManager.HandleThrow(player, itemId, targetPosition)
    local stats = ExplosiveStats[itemId]
    if not stats then return end

    -- Verify inventory (Arena Breakout mechanics: throwing consumes the item)
    local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
    local playerData = PlayerManager.ActivePlayers[player.UserId]
    if not playerData then return end

    local hasItem = false
    for i, item in ipairs(playerData.Inventory.Items) do
        if item == itemId then
            hasItem = true
            table.remove(playerData.Inventory.Items, i)
            break
        end
    end
    if not hasItem then return end

    -- Physics Throw
    local char = player.Character
    if not char or not char:FindFirstChild("RightHand") then return end

    local grenade = Instance.new("Part")
    grenade.Size = Vector3.new(1, 1, 1)
    grenade.Shape = Enum.PartType.Cylinder
    grenade.Color = Color3.fromRGB(50, 50, 50)
    grenade.Position = char.RightHand.Position
    grenade.Parent = workspace

    -- Calculate trajectory arc
    local startPos = grenade.Position
    local direction = (targetPosition - startPos).Unit
    local distance = (targetPosition - startPos).Magnitude
    local force = math.min(distance * 2, 100) -- Cap throw strength

    grenade.Velocity = (direction * force) + Vector3.new(0, force * 0.5, 0)

    -- Detonation Timer
    task.delay(3, function()
        ExplosivesManager.Detonate(grenade, stats)
    end)
end

function ExplosivesManager.Detonate(grenadePart, stats)
    local blastCenter = grenadePart.Position
    grenadePart:Destroy()

    -- Visuals
    local blastPart = Instance.new("Part")
    blastPart.Shape = Enum.PartType.Ball
    blastPart.Size = Vector3.new(stats.Radius * 2, stats.Radius * 2, stats.Radius * 2)
    blastPart.Position = blastCenter
    blastPart.Anchored = true
    blastPart.CanCollide = false
    blastPart.Transparency = 0.5
    blastPart.Color = stats.Color
    blastPart.Material = Enum.Material.Neon
    blastPart.Parent = workspace

    Debris:AddItem(blastPart, stats.Duration)

    -- Damage Loop (For Gas/Fire that persists over time)
    task.spawn(function()
        local ticks = stats.Duration
        while ticks > 0 and blastPart.Parent do
            task.wait(1)
            ticks = ticks - 1

            -- Damage Players
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (p.Character.HumanoidRootPart.Position - blastCenter).Magnitude
                    if d <= stats.Radius then
                        p.Character.Humanoid:TakeDamage(stats.Damage)
                    end
                end
            end

            -- Damage Monsters
            for _, model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") and model:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(model) then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    if root then
                        local d = (root.Position - blastCenter).Magnitude
                        if d <= stats.Radius then
                            model.Humanoid:TakeDamage(stats.Damage)
                        end
                    end
                end
            end
        end
    end)
end

return ExplosivesManager
