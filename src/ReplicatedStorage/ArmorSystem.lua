-- ArmorSystem.lua
-- Handles limb-specific protection, armor classes, and bullet penetration math.

local ArmorSystem = {}

ArmorSystem.HitZones = {
    Helmet = { "Head" },
    Armor = { "Thorax", "Stomach", "LeftArm", "RightArm" }
}

function ArmorSystem.CalculateMitigation(ammoPenetration, armorClass, armorDurability, maxDurability)
    local armorResist = armorClass * 10
    local durabilityRatio = armorDurability / maxDurability
    armorResist = armorResist * durabilityRatio

    local penetrationChance = 0
    if ammoPenetration > armorResist + 10 then penetrationChance = 0.95
    elseif ammoPenetration < armorResist - 10 then penetrationChance = 0.10
    else penetrationChance = 0.5 + ((ammoPenetration - armorResist) / 20) end

    penetrationChance = math.max(0, math.min(1, penetrationChance))
    local didPenetrate = math.random() <= penetrationChance
    local damageMultiplier = didPenetrate and (math.random(70, 90) / 100) or (math.random(10, 20) / 100)

    return didPenetrate, damageMultiplier
end

function ArmorSystem.GetProtectingArmor(equippedGear, targetLimb, itemDatabase)
    for slot, itemId in pairs(equippedGear) do
        local itemData = itemDatabase.GetItem(itemId)
        if itemData and itemData.Type == "Armor" then
            local zones = itemData.ProtectedZones or ArmorSystem.HitZones[slot]
            if zones then
                for _, z in ipairs(zones) do if z == targetLimb then return itemData end end
            end
        end
    end
    return nil
end

return ArmorSystem
