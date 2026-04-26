local RefiningSystem = {}

-- Refining is the process by which players can turn resources gained from Gathering into usable materials for Crafting.
function RefiningSystem.Refine(gatheredResourceAmount)
    if not gatheredResourceAmount or gatheredResourceAmount <= 0 then
        return 0
    end

    -- Basic 2:1 refining ratio representation
    local refineRatio = 2
    local refinedMaterialAmount = math.floor(gatheredResourceAmount / refineRatio)

    return refinedMaterialAmount
end

return RefiningSystem
