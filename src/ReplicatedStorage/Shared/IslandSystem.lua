local IslandSystem = {}

local activeIslands = {}

function IslandSystem.PurchasePlayerIsland(player, hasPurchasedSevenDaysPremium)
    -- As confirmed by trace: A player must have purchased at least 7 days' Premium time
    if not hasPurchasedSevenDaysPremium then
        return false, "You must have purchased at least 7 days' Premium time to buy an island."
    end

    activeIslands[player.UserId] = {
        owner = player.UserId,
        isPvPEnabled = false -- PvP is not enabled on a Player Island
    }

    print(player.Name .. " successfully purchased a Player Island.")
    return true
end

function IslandSystem.EnterIsland(player)
    local islandData = activeIslands[player.UserId]
    if not islandData then
        return false, "You do not own an island."
    end

    -- Explicitly enforce the PvP rule confirmed by the trace
    local isPvPEnabled = islandData.isPvPEnabled

    print(player.Name .. " entered their Player Island. PvP Enabled: " .. tostring(isPvPEnabled))
    return true, { pvpZone = isPvPEnabled }
end

return IslandSystem
