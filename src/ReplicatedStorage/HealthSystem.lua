-- HealthSystem.lua
-- Handles the Arena Breakout style limb-based health system and status effects.

local HealthSystem = {}

HealthSystem.Limbs = {
    Head = { Max = 35, Lethal = true },
    Thorax = { Max = 85, Lethal = true },
    Stomach = { Max = 70, Lethal = false },
    LeftArm = { Max = 60, Lethal = false },
    RightArm = { Max = 60, Lethal = false },
    LeftLeg = { Max = 65, Lethal = false },
    RightLeg = { Max = 65, Lethal = false },
}

function HealthSystem.CreateHealthProfile()
    local profile = {
        Limbs = {},
        StatusEffects = {
            Bleeding = {},
            Broken = {},
            Pain = false,
        },
        IsDead = false
    }
    for limbName, data in pairs(HealthSystem.Limbs) do
        profile.Limbs[limbName] = { Current = data.Max, IsBlackedOut = false }
    end
    return profile
end

function HealthSystem.ApplyDamage(profile, targetLimb, amount)
    if profile.IsDead or not profile.Limbs[targetLimb] then return end
    local limb = profile.Limbs[targetLimb]

    if limb.IsBlackedOut then
        HealthSystem.SpreadDamage(profile, targetLimb, amount)
    else
        limb.Current = limb.Current - amount
        if limb.Current <= 0 then
            limb.Current = 0
            limb.IsBlackedOut = true
            if HealthSystem.Limbs[targetLimb].Lethal then
                profile.IsDead = true
            else
                profile.StatusEffects.Pain = true
                profile.StatusEffects.Broken[targetLimb] = true
            end
        end
    end
end

function HealthSystem.SpreadDamage(profile, originLimb, amount)
    local multipliers = { Stomach = 1.5, LeftArm = 0.7, RightArm = 0.7, LeftLeg = 1.0, RightLeg = 1.0 }
    local mult = multipliers[originLimb] or 1.0
    local totalDamage = amount * mult
    local healthy = 0
    for l, d in pairs(profile.Limbs) do if not d.IsBlackedOut and l ~= originLimb then healthy = healthy + 1 end end

    if healthy == 0 then profile.IsDead = true return end
    local dmgPerLimb = totalDamage / healthy
    for l, d in pairs(profile.Limbs) do
        if not d.IsBlackedOut and l ~= originLimb then
            d.Current = d.Current - dmgPerLimb
            if d.Current <= 0 then
                d.Current = 0
                d.IsBlackedOut = true
                if HealthSystem.Limbs[l].Lethal then profile.IsDead = true end
            end
        end
    end
end

function HealthSystem.ApplyStatus(profile, effectType, limbName)
    if profile.IsDead then return end
    if effectType == "Bleeding" then profile.StatusEffects.Bleeding[limbName] = true
    elseif effectType == "Broken" then profile.StatusEffects.Broken[limbName] = true; profile.StatusEffects.Pain = true
    elseif effectType == "Pain" then profile.StatusEffects.Pain = true end
end

function HealthSystem.UseMedicalItem(profile, itemData, targetLimb)
    if profile.IsDead then return false, "Player is dead" end
    local healed = false; local msg = "No effect"
    if itemData.FixesLimb and targetLimb and profile.StatusEffects.Broken[targetLimb] then
        if HealthSystem.Limbs[targetLimb].Lethal then return false, "Cannot perform surgery on Head/Thorax" end
        profile.StatusEffects.Broken[targetLimb] = nil; profile.Limbs[targetLimb].IsBlackedOut = false; profile.Limbs[targetLimb].Current = 1
        healed = true; msg = "Surgery successful on " .. targetLimb
        local stillBroken = false; for _, _ in pairs(profile.StatusEffects.Broken) do stillBroken = true break end
        if not stillBroken then profile.StatusEffects.Pain = false end
    end
    if itemData.StopsBleeding then
        if targetLimb and profile.StatusEffects.Bleeding[targetLimb] then profile.StatusEffects.Bleeding[targetLimb] = nil; healed = true; msg = "Stopped bleeding"
        else for l, isB in pairs(profile.StatusEffects.Bleeding) do if isB then profile.StatusEffects.Bleeding[l] = nil; healed = true; msg = "Stopped bleeding"; break end end end
    end
    if itemData.StopsPain and profile.StatusEffects.Pain then profile.StatusEffects.Pain = false; healed = true; msg = "Pain relieved" end
    if itemData.HealAmount and itemData.HealAmount > 0 then
        if targetLimb then
            if not profile.Limbs[targetLimb].IsBlackedOut then profile.Limbs[targetLimb].Current = math.min(HealthSystem.Limbs[targetLimb].Max, profile.Limbs[targetLimb].Current + itemData.HealAmount); healed = true; msg = "Healed " .. targetLimb
            else msg = targetLimb .. " is blacked out." end
        else
            local pool = itemData.HealAmount
            for l, d in pairs(profile.Limbs) do
                if not d.IsBlackedOut and pool > 0 then
                    local missing = HealthSystem.Limbs[l].Max - d.Current
                    if missing > 0 then local app = math.min(missing, pool); d.Current = d.Current + app; pool = pool - app; healed = true end
                end
            end
            if healed then msg = "Healed overall health" end
        end
    end
    return healed, msg
end

return HealthSystem
