local CraftingSystem = {}

local VALID_QUALITY_ITEMS = {
    ["Armor"] = true,
    ["Weapons"] = true,
    ["Accessories"] = true,
    ["Mounts"] = true
}

-- Characters individually with Premium Status active passively earn 10,000 Focus points.
function CraftingSystem.PassiveFocusEarn(hasPremium)
    if hasPremium then
        return 10000
    end
    return 0
end

function CraftingSystem.CraftItem(itemType, refinedMaterials, useFocus)
    if not refinedMaterials or refinedMaterials <= 0 then
        return nil, 0 -- Item, returned materials
    end

    local returnedMaterials = 0
    local quality = 1 -- Base generic quality numeric value

    -- Crafting Focus improves resource return rate and quality
    if useFocus then
        returnedMaterials = math.floor(refinedMaterials * 0.15) -- Simulate a 15% return rate when focused
        quality = quality + 1 -- Boost quality tier
    end

    -- Items that have quality (Armor, Weapons, Accessories, and Mounts)
    local craftedQuality = nil
    if VALID_QUALITY_ITEMS[itemType] then
        -- Generate a generic random quality value representing the mechanic
        local randomBoost = math.random(1, 100)
        if randomBoost > 80 then
            quality = quality + 1
        end
        craftedQuality = quality
    end

    local craftedItem = {
        itemType = itemType,
        quality = craftedQuality
    }

    return craftedItem, returnedMaterials
end

return CraftingSystem
