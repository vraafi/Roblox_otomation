-- DAILY_LOG_SYSTEM_1.lua
-- Rancang sistem log harian untuk pemain dengan batas $1,000 per hari.

local DailyLogSystem = {}

local DataStoreService = game:GetService("DataStoreService")
local DailyLogStore = DataStoreService:GetDataStore("DailyLogData_v1")

local DAILY_LIMIT = 1000

function DailyLogSystem.Initialize()
    game.Players.PlayerAdded:Connect(DailyLogSystem.OnPlayerAdded)
    game.Players.PlayerRemoving:Connect(DailyLogSystem.OnPlayerRemoving)
end

function DailyLogSystem.OnPlayerAdded(player)
    local success, data = pcall(function()
        return DailyLogStore:GetAsync(tostring(player.UserId))
    end)

    if success then
        if not data then
            data = {
                LastLogDay = os.date("!%Y-%j"),
                DailyDollarsEarned = 0,
            }
        else
            local currentDay = os.date("!%Y-%j")
            if data.LastLogDay ~= currentDay then
                data.LastLogDay = currentDay
                data.DailyDollarsEarned = 0
            end
        end

        local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
        local pData = PlayerManager.ActivePlayers[player.UserId]
        if pData then
            pData.DailyLog = data
        end
    else
        warn("Failed to load daily log for player " .. player.Name)
    end
end

function DailyLogSystem.OnPlayerRemoving(player)
    local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
    local pData = PlayerManager.ActivePlayers[player.UserId]
    if pData and pData.DailyLog then
        local success, err = pcall(function()
            DailyLogStore:SetAsync(tostring(player.UserId), pData.DailyLog)
        end)
        if not success then
            warn("Failed to save daily log for player " .. player.Name .. ": " .. tostring(err))
        end
    end
end

function DailyLogSystem.AddDollars(player, amount)
    local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
    local pData = PlayerManager.ActivePlayers[player.UserId]

    if not pData or not pData.DailyLog then return false, "Economy data not loaded" end

    local data = pData.DailyLog

    local currentDay = os.date("!%Y-%j")
    if data.LastLogDay ~= currentDay then
        data.LastLogDay = currentDay
        data.DailyDollarsEarned = 0
    end

    if data.DailyDollarsEarned + amount > DAILY_LIMIT then
        local allowedAmount = DAILY_LIMIT - data.DailyDollarsEarned
        if allowedAmount > 0 then
            data.DailyDollarsEarned = DAILY_LIMIT
            pData.TotalDollars = pData.TotalDollars + allowedAmount
            return true, "Reached daily limit. Only added $" .. tostring(allowedAmount)
        else
            return false, "Daily limit of $" .. tostring(DAILY_LIMIT) .. " already reached."
        end
    end

    data.DailyDollarsEarned = data.DailyDollarsEarned + amount
    pData.TotalDollars = pData.TotalDollars + amount

    return true, "Added $" .. tostring(amount)
end

return DailyLogSystem
