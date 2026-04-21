local GatheringSystem = {}

GatheringSystem.Professions = {
    Lumberjack = { resource = "Wood" },
    Miner = { resource = "Metal" },
    Skinner = { resource = "Leather" },
    Farmer = { resource = "Food" },
    Fisher = { resource = "Fish" }
}

-- Simulates gathering using specialized tools
function GatheringSystem.Gather(player, professionName, toolTier)
    local profession = GatheringSystem.Professions[professionName]

    if not profession then
        warn("Invalid profession: " .. tostring(professionName))
        return false
    end

    -- Basic representation of using a specialized gathering tool
    local baseYield = 1
    local totalYield = baseYield * toolTier

    -- In a real scenario, this would check distance, node availability, tool validity, etc.
    print(player.Name .. " gathered " .. tostring(totalYield) .. " " .. profession.resource .. " using a tier " .. tostring(toolTier) .. " tool.")

    return {
        resourceType = profession.resource,
        amount = totalYield
    }
end

return GatheringSystem
