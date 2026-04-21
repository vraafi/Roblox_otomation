local FarmingSystem = {}

local activePlots = {}

-- Represents the new skill unique to islands confirmed by the trace
function FarmingSystem.PlantSeed(player, plotId, seedType)
    if activePlots[plotId] then
        return false, "Plot is already in use."
    end

    activePlots[plotId] = {
        owner = player.UserId,
        seed = seedType,
        isFullyGrown = false
    }

    print(player.Name .. " planted " .. seedType .. " in plot " .. plotId)
    return true
end

function FarmingSystem.HarvestCrop(player, plotId)
    local plot = activePlots[plotId]

    if not plot then
        return false, "Plot is empty."
    end

    if plot.owner ~= player.UserId then
        return false, "You do not own this plot."
    end

    -- In a real scenario, we would check if it is fully grown based on time
    local cropYield = 1
    activePlots[plotId] = nil -- Clear the plot

    print(player.Name .. " harvested their crops from plot " .. plotId)
    return true, cropYield
end

return FarmingSystem
