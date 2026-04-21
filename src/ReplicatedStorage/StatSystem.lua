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

    -- Heavy gear might reduce speed slightly, simulating realism
    if totalWeight > 20 then
        totalStats.MoveSpeed = math.max(10, totalStats.MoveSpeed - (totalWeight - 20) * 0.2)
    end

    return totalStats
end

return StatSystem
