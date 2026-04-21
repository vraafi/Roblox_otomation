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
            -- First time playing or no data
            data = {
                LastLogDay = os.date("!%Y-%j"),
                DailyDollarsEarned = 0,
                TotalDollars = 0
            }
        else
            -- Check if it's a new day (using day of the year)
            local currentDay = os.date("!%Y-%j")
            if data.LastLogDay ~= currentDay then
                data.LastLogDay = currentDay
                data.DailyDollarsEarned = 0 -- Reset daily limit
            end
        end

        -- Store temporary data on server
        _G.PlayerEconomies = _G.PlayerEconomies or {}
        _G.PlayerEconomies[player.UserId] = data
    else
        warn("Failed to load daily log for player " .. player.Name)
    end
end

function DailyLogSystem.OnPlayerRemoving(player)
    if _G.PlayerEconomies and _G.PlayerEconomies[player.UserId] then
        local success, err = pcall(function()
            DailyLogStore:SetAsync(tostring(player.UserId), _G.PlayerEconomies[player.UserId])
        end)
        if not success then
            warn("Failed to save daily log for player " .. player.Name .. ": " .. tostring(err))
        end
        _G.PlayerEconomies[player.UserId] = nil
    end
end

-- Function to add money, respecting the $1,000 daily limit
function DailyLogSystem.AddDollars(player, amount)
    if not _G.PlayerEconomies or not _G.PlayerEconomies[player.UserId] then return false, "Economy data not loaded" end

    local data = _G.PlayerEconomies[player.UserId]

    -- Check if it's a new day before adding
    local currentDay = os.date("!%Y-%j")
    if data.LastLogDay ~= currentDay then
        data.LastLogDay = currentDay
        data.DailyDollarsEarned = 0
    end

    if data.DailyDollarsEarned + amount > DAILY_LIMIT then
        local allowedAmount = DAILY_LIMIT - data.DailyDollarsEarned
        if allowedAmount > 0 then
            data.DailyDollarsEarned = DAILY_LIMIT
            data.TotalDollars = data.TotalDollars + allowedAmount
            return true, "Reached daily limit. Only added $" .. tostring(allowedAmount)
        else
            return false, "Daily limit of $" .. tostring(DAILY_LIMIT) .. " already reached."
        end
    end

    data.DailyDollarsEarned = data.DailyDollarsEarned + amount
    data.TotalDollars = data.TotalDollars + amount

    return true, "Added $" .. tostring(amount)
end

return DailyLogSystem
