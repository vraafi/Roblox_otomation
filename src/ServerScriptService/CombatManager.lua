-- CombatManager.lua
-- Handles server-side validation for combat and magic usage.

local CombatManager = {}

-- Fallbacks for non-Roblox env testing
local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

function CombatManager.Initialize()
    -- Normally we'd hook up to RemoteEvents here
end

-- Simulates an attack. Player data would be fetched from PlayerManager in a real scenario
function CombatManager.ProcessAttack(playerData, targetData)
    local weaponId = playerData.Inventory.Equipped.Weapon

    if not weaponId then
        return false, "No weapon equipped"
    end

    local weaponInfo = ItemDatabase.GetItem(weaponId)

    if not weaponInfo then
        return false, "Invalid weapon"
    end

    -- Check if it's a magic wand
    if weaponInfo.SubType == "MagicWand" then
        -- You are what you wear: Check if player has enough mana (given by armor)
        if playerData.CurrentMana < weaponInfo.ManaCost then
            return false, "Not enough mana! Equip better armor with a higher core level."
        end

        -- Deduct mana
        playerData.CurrentMana = playerData.CurrentMana - weaponInfo.ManaCost

        -- Apply damage to target (simplified)
        targetData.CurrentHealth = targetData.CurrentHealth - weaponInfo.BaseDamage

        return true, "Cast magic successfully"
    end

    -- Modern firearms
    if weaponInfo.SubType == "ModernFirearm" then
        -- In a full game, check ammo here
        local damage = weaponInfo.Damage
        -- Mitigate by defense (you are what you wear: defense from armor)
        local mitigatedDamage = math.max(1, damage - (targetData.TotalStats.Defense * 0.5))

        targetData.CurrentHealth = targetData.CurrentHealth - mitigatedDamage

        return true, "Fired weapon successfully"
    end

    return false, "Unknown weapon type"
end

return CombatManager
