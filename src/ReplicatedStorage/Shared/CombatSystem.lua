local CombatSystem = {}
function CombatSystem.CalculateDamage(baseDamage, attackPower, armor)
    local damage = baseDamage * (1 + attackPower / 100)
    local reduction = armor / (armor + 100)
    return math.max(0, damage * (1 - reduction))
end
function CombatSystem.CastSpell(spellId, target)
    -- Spell casting logic
    return true
end
return CombatSystem
