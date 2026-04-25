-- TelemetrySpy.server.lua
-- Automatically deployed agent spy that monitors the server for errors, voids, and kicks.
-- Sends payload to the VPS Telemetry Server via HttpService.

local HttpService = game:GetService("HttpService")
local ScriptContext = game:GetService("ScriptContext")
local Players = game:GetService("Players")

local TELEMETRY_URL = "http://localhost:5000/telemetry" -- Replace with actual VPS IP when deployed
local IS_STUDIO = game:GetService("RunService"):IsStudio()

-- Telemetry logging function
local function sendTelemetry(logType, message, details)
    local payload = {
        type = logType,
        message = message,
        details = details or {},
        timestamp = os.time()
    }

    local jsonPayload = HttpService:JSONEncode(payload)

    -- In Studio, we might not have HTTP access enabled, or localhost might refuse
    -- Wrap in pcall to avoid breaking the game if telemetry server is unreachable
    task.spawn(function()
        local success, err = pcall(function()
            HttpService:PostAsync(TELEMETRY_URL, jsonPayload, Enum.HttpContentType.ApplicationJson, false)
        end)

        if not success then
            -- Fallback to local warning if telemetry server fails
            warn("[TELEMETRY SPY OFFLINE CACHE]: " .. logType .. " - " .. message)
        end
    end)
end

-- 1. Catch Server Errors
ScriptContext.Error:Connect(function(message, trace, script)
    sendTelemetry("SERVER_ERROR", message, {
        trace = trace,
        scriptName = script and script.GetFullName and script:GetFullName() or "Unknown"
    })
end)

-- 2. Detect Unnatural Kicks / Instant Disconnects
local joinTimes = {}

Players.PlayerAdded:Connect(function(player)
    joinTimes[player.UserId] = os.clock()

    -- 3. Detect Voids / Early Deaths
    player.CharacterAdded:Connect(function(character)
        local spawnTime = os.clock()

        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.Died:Connect(function()
                local timeAlive = os.clock() - spawnTime
                if timeAlive < 3 then
                    sendTelemetry("RAPID_DEATH", "Player " .. player.Name .. " died in " .. string.format("%.2f", timeAlive) .. "s. Possible void spawn.", {
                        playerId = player.UserId,
                        timeAlive = timeAlive
                    })
                end
            end)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    local joinTime = joinTimes[player.UserId]
    if joinTime then
        local playDuration = os.clock() - joinTime
        if playDuration < 2 then
            sendTelemetry("INSTANT_DISCONNECT", "Player " .. player.Name .. " left after " .. string.format("%.2f", playDuration) .. "s. Check PlayerAdded scripts or kick logic.", {
                playerId = player.UserId,
                playDuration = playDuration
            })
        end
    end
    joinTimes[player.UserId] = nil
end)

-- Set up listener for Client Telemetry (forwarding)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "Events"
    eventsFolder.Parent = ReplicatedStorage
end

local clientTelemetryEvent = eventsFolder:FindFirstChild("ClientTelemetryLog")
if not clientTelemetryEvent then
    clientTelemetryEvent = Instance.new("RemoteEvent")
    clientTelemetryEvent.Name = "ClientTelemetryLog"
    clientTelemetryEvent.Parent = eventsFolder
end

clientTelemetryEvent.OnServerEvent:Connect(function(player, logType, message, details)
    -- Add player info to client logs for context
    details = details or {}
    details.sourcePlayer = player.Name
    sendTelemetry("CLIENT_" .. logType, message, details)
end)

print("[Telemetry Spy] Server module active and monitoring.")
