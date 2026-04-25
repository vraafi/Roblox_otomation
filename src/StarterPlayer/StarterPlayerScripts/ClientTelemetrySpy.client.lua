-- ClientTelemetrySpy.client.lua
-- Monitors client-side errors and UI spam, reporting back to the Server Telemetry Spy.

local ScriptContext = game:GetService("ScriptContext")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local clientTelemetryEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ClientTelemetryLog")

-- 1. Catch Client Errors
ScriptContext.Error:Connect(function(message, trace, script)
    clientTelemetryEvent:FireServer("ERROR", message, {
        trace = trace,
        scriptName = script and script.GetFullName and script:GetFullName() or "Unknown"
    })
end)

-- 2. Detect UI Spam
local uiCreationTimes = {}
local SPAM_THRESHOLD_COUNT = 5
local SPAM_THRESHOLD_TIME = 1.0 -- seconds

local function monitorUI()
    local playerGui = player:WaitForChild("PlayerGui")

    playerGui.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ScreenGui") or descendant:IsA("Frame") and descendant.Parent == playerGui then
            local now = os.clock()
            table.insert(uiCreationTimes, now)

            -- Clean up old entries
            for i = #uiCreationTimes, 1, -1 do
                if now - uiCreationTimes[i] > SPAM_THRESHOLD_TIME then
                    table.remove(uiCreationTimes, i)
                end
            end

            if #uiCreationTimes > SPAM_THRESHOLD_COUNT then
                clientTelemetryEvent:FireServer("UI_SPAM_WARNING", "UI Spam detected. " .. #uiCreationTimes .. " elements created within 1 second. Player vision may be blocked.", {
                    latestElement = descendant.Name
                })
                -- Clear list to prevent spamming the telemetry server itself
                uiCreationTimes = {}
            end
        end
    end)
end

-- Initialize UI monitor
task.spawn(monitorUI)

print("[Telemetry Spy] Client module active and monitoring.")
