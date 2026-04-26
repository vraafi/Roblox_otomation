-- StatSystem.lua
-- Enforces "You Are What You Wear" logical element.
-- Characters cannot increase statistics by leveling up; everything depends on tools/gear.

local StatSystem = {}

local ItemDatabase = require(script.Parent.ItemDatabase)

-- Base stats for a naked character. These NEVER change based on level.
StatSystem.BaseStats = {
    MaxHealth = 100,
    MaxMana = 0, -- Cannot use magic without gear that provides mana
    Defense = 0,
    MoveSpeed = 16,
}

-- Recalculates all stats based on currently equipped gear
function StatSystem.CalculateTotalStats(equippedGear)
    local totalStats = {
        MaxHealth = StatSystem.BaseStats.MaxHealth,
        MaxMana = StatSystem.BaseStats.MaxMana,
        Defense = StatSystem.BaseStats.Defense,
        MoveSpeed = StatSystem.BaseStats.MoveSpeed,
    }

    local totalWeight = 0

    -- equippedGear should be a dictionary like { "Chest" = "Mage_Robe_T1", "Weapon" = "Novice_Wand" }
    for slot, itemId in pairs(equippedGear) do
        local itemData = ItemDatabase.GetItem(itemId)

        if itemData then
            if itemData.Type == "Armor" then
                totalStats.MaxHealth = totalStats.MaxHealth + (itemData.HealthBonus or 0)
                totalStats.MaxMana = totalStats.MaxMana + (itemData.ManaBonus or 0)
                totalStats.Defense = totalStats.Defense + (itemData.DefenseBonus or 0)
            end

            totalWeight = totalWeight + (itemData.Weight or 0)
        end
    end

    -- Encumbrance Logic (Arena Breakout Style)
    totalStats.TotalWeight = totalWeight

    if totalWeight >= 70 then
        -- Over-encumbered: Cannot run, only walk slowly
        totalStats.MoveSpeed = 6
        totalStats.CanSprint = false
    elseif totalWeight > 30 then
        -- Partially encumbered: Scaling slowdown
        totalStats.MoveSpeed = math.max(10, totalStats.MoveSpeed - (totalWeight - 30) * 0.15)
        totalStats.CanSprint = true
    else
        totalStats.CanSprint = true
    end

    return totalStats
end

-- Fall damage calculation based on studs (1 meter ~ 3.5 studs in Roblox)
function StatSystem.CalculateFallDamage(fallDistanceMeters)
    if fallDistanceMeters < 1 then
        return { LegDamage = 0, BrokenLeg = false }
    elseif fallDistanceMeters >= 1 and fallDistanceMeters < 3 then
        -- 1 to 3 meters: Leg damage but no break
        return { LegDamage = math.floor(fallDistanceMeters * 15), BrokenLeg = false }
    else
        -- 3+ meters: Severe damage and broken leg
        return { LegDamage = math.floor(fallDistanceMeters * 25), BrokenLeg = true }
    end
end

return StatSystem
