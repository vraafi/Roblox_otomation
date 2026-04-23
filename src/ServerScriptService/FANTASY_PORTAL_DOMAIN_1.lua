-- FANTASY_PORTAL_DOMAIN_1.lua
-- Rancang domain portal fantasi: maks 4 pemain, solo setelah 30 detik, 2.5 jam wipe meteor.

local PortalDomain = {}

local WIPE_TIMER = 2.5 * 60 * 60 -- 2.5 hours in seconds
local MATCHMAKING_WAIT = 30 -- seconds

local ActiveDomains = {}

function PortalDomain.Initialize()
    PortalDomain.CreateVisualPortal(Vector3.new(0, 1005, -50))
end

function PortalDomain.CreateVisualPortal(position)
    local portal = Instance.new("Part")
    portal.Name = "FantasyPortal_Entrance"
    portal.Shape = Enum.PartType.Cylinder
    portal.Size = Vector3.new(2, 10, 10)
    portal.Position = position
    portal.Orientation = Vector3.new(0, 0, 90)
    portal.Anchored = true
    portal.CanCollide = false
    portal.Material = Enum.Material.Neon
    portal.Color = Color3.fromRGB(150, 0, 255)
    portal.Parent = workspace

    -- Visual Particle Effect
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(Color3.fromRGB(200, 100, 255))
    particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
    particles.Rate = 50
    particles.Speed = NumberRange.new(5, 10)
    particles.Parent = portal

    -- Touch event for matchmaking
    local debounce = {}
    portal.Touched:Connect(function(hit)
        local player = game.Players:GetPlayerFromCharacter(hit.Parent)
        if player and not debounce[player.UserId] then
            debounce[player.UserId] = true
            PortalDomain.JoinMatchmaking(player)
            task.delay(2, function() debounce[player.UserId] = nil end)
        end
    end)
end

local MatchmakingQueue = {}

function PortalDomain.JoinMatchmaking(player)
    -- Simple queue system
    table.insert(MatchmakingQueue, player)
    print(player.Name .. " joined portal queue.")

    if #MatchmakingQueue == 1 then
        -- Start the 30s timer for the first person
        task.delay(MATCHMAKING_WAIT, function()
            if #MatchmakingQueue > 0 then
                PortalDomain.StartDomain()
            end
        end)
    elseif #MatchmakingQueue == 4 then
        -- Max players reached, start immediately
        PortalDomain.StartDomain()
    end
end

function PortalDomain.StartDomain()
    local domainId = "Domain_" .. tostring(os.time())
    local playersInMatch = {}

    for i = 1, math.min(4, #MatchmakingQueue) do
        table.insert(playersInMatch, table.remove(MatchmakingQueue, 1))
    end

    ActiveDomains[domainId] = {
        Players = playersInMatch,
        StartTime = os.time(),
    }

    print("Started domain " .. domainId .. " with " .. #playersInMatch .. " players.")

    -- Teleport players to the Macro-Biome (Kalimantan)
    -- In a real game, you would spawn a new instance of the macro-biome far away.
    -- Here we teleport them to the center of the existing Kalimantan generation zone.
    local domainSpawn = Vector3.new(0, 100, 0) -- High enough to not clip into mountains, physics will drop them

    for _, player in ipairs(playersInMatch) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            -- Safely pivot the character to prevent breaking weld joints
            player.Character:PivotTo(CFrame.new(domainSpawn + Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))))
        end
    end

    -- Start Wipe Timer
    task.delay(WIPE_TIMER, function()
        PortalDomain.TriggerMeteorWipe(domainId, domainSpawn)
    end)
end

function PortalDomain.TriggerMeteorWipe(domainId, position)
    print("WIPE TRIGGERED FOR DOMAIN: " .. domainId)

    -- Visual Meteor
    local meteor = Instance.new("Part")
    meteor.Shape = Enum.PartType.Ball
    meteor.Size = Vector3.new(100, 100, 100)
    meteor.Position = position + Vector3.new(0, 2000, 0)
    meteor.Material = Enum.Material.Neon
    meteor.Color = Color3.fromRGB(255, 50, 0)
    meteor.Anchored = true
    meteor.Parent = workspace

    -- Animate falling
    for i = 1, 100 do
        meteor.Position = meteor.Position - Vector3.new(0, 20, 0)
        task.wait(0.05)
    end

    -- Kill everyone left
    local domainData = ActiveDomains[domainId]
    if domainData then
        for _, player in ipairs(domainData.Players) do
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.Health = 0 -- Failed to extract, death by meteor
            end
        end
    end

    meteor:Destroy()
    ActiveDomains[domainId] = nil
end

return PortalDomain
