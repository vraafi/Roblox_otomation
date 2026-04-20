local CombatSystem = {}

function CombatSystem.CalculateDamage(baseDamage, attackPower, armor)
    local damage = baseDamage * (1 + attackPower / 100)
    local reduction = armor / (armor + 100)
    return math.max(0, damage * (1 - reduction))
end

function CombatSystem.SplittingSlash(target)
    -- Applies a 1.25s root to the target
    local rootDuration = 1.25
    -- Logic to apply root to target...
    return { spell = "Splitting Slash", rooted = true, duration = rootDuration }
end

function CombatSystem.MightyBlow(target, isKillOrKnockdown)
    -- No longer consumes Heroic Charges.
    -- Cooldown resets on kill or knockdown.
    local baseDamage = 150
    local cooldown = 15 -- standard cooldown

    if isKillOrKnockdown then
        cooldown = 0 -- Reset cooldown
    end

    return { spell = "Mighty Blow", damage = baseDamage, newCooldown = cooldown }
end

return CombatSystem
