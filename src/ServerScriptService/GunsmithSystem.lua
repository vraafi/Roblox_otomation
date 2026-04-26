-- GunsmithSystem.lua
-- Handles weapon modifications, calculating total stats (Ergonomics, Stability, etc.) based on attachments.

local GunsmithSystem = {}

-- A database of specific attachments that can be applied to weapons
local AttachmentsData = {
    ["Heavy_Suppressor"] = {
        Id = "Heavy_Suppressor",
        Name = "Heavy Suppressor",
        SlotType = "Muzzle",
        Stats = { Firepower = 0, Accuracy = 5, Range = -10, Stability = 15, Ergonomics = -10, RateOfFire = 0 }
    },
    ["Compensator"] = {
        Id = "Compensator",
        Name = "Recoil Compensator",
        SlotType = "Muzzle",
        Stats = { Firepower = 0, Accuracy = -2, Range = 0, Stability = 20, Ergonomics = -5, RateOfFire = 0 }
    },
    ["Red_Dot_Sight"] = {
        Id = "Red_Dot_Sight",
        Name = "Red Dot Sight",
        SlotType = "Optic",
        Stats = { Firepower = 0, Accuracy = 15, Range = 0, Stability = 0, Ergonomics = -2, RateOfFire = 0 }
    },
    ["Sniper_Scope_8x"] = {
        Id = "Sniper_Scope_8x",
        Name = "8x Sniper Scope",
        SlotType = "Optic",
        Stats = { Firepower = 0, Accuracy = 40, Range = 150, Stability = 0, Ergonomics = -25, RateOfFire = 0 }
    },
    ["Vertical_Foregrip"] = {
        Id = "Vertical_Foregrip",
        Name = "Vertical Foregrip",
        SlotType = "Foregrip",
        Stats = { Firepower = 0, Accuracy = 0, Range = 0, Stability = 10, Ergonomics = 5, RateOfFire = 0 }
    },
    ["Extended_Mag"] = {
        Id = "Extended_Mag",
        Name = "Extended Magazine (+10)",
        SlotType = "Magazine",
        Stats = { Firepower = 0, Accuracy = 0, Range = 0, Stability = 0, Ergonomics = -10, RateOfFire = 0 },
        CapacityModifier = 10
    }
}

-- Formats a fresh, unmodded weapon instance to support attachments
function GunsmithSystem.CreateWeaponInstance(baseWeaponData)
    local instance = {
        Id = "INST_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000,9999)),
        BaseItemId = baseWeaponData.Id,
        Name = baseWeaponData.Name,
        Attachments = {}, -- e.g., { Muzzle = "Heavy_Suppressor" }
        TotalStats = {}
    }

    -- Initialize structure based on available slots
    if baseWeaponData.ModSlots then
        for _, slotName in ipairs(baseWeaponData.ModSlots) do
            instance.Attachments[slotName] = nil
        end
    end

    GunsmithSystem.CalculateTotalStats(instance, baseWeaponData)
    return instance
end

-- Modifies an attachment slot. Removes an old attachment if one exists.
function GunsmithSystem.AttachPart(weaponInstance, baseWeaponData, attachmentId)
    local attachData = AttachmentsData[attachmentId]
    if not attachData then return false, "Attachment does not exist." end

    local targetSlot = attachData.SlotType
    if weaponInstance.Attachments[targetSlot] == nil and not baseWeaponData.ModSlots then
        return false, "This weapon does not support " .. targetSlot .. " attachments."
    end

    -- Verify the weapon actually has this slot
    local hasSlot = false
    for _, s in ipairs(baseWeaponData.ModSlots) do
        if s == targetSlot then hasSlot = true break end
    end
    if not hasSlot then return false, "This weapon cannot equip " .. targetSlot .. " parts." end

    local oldPart = weaponInstance.Attachments[targetSlot]
    weaponInstance.Attachments[targetSlot] = attachmentId

    GunsmithSystem.CalculateTotalStats(weaponInstance, baseWeaponData)

    return true, oldPart
end

-- Deduces the final functional stats of a weapon by summing the base weapon and its active attachments
function GunsmithSystem.CalculateTotalStats(weaponInstance, baseWeaponData)
    local stats = {
        Firepower = baseWeaponData.Firepower or 0,
        Accuracy = baseWeaponData.Accuracy or 0,
        Range = baseWeaponData.Range or 0,
        Stability = baseWeaponData.Stability or 0,
        Ergonomics = baseWeaponData.Ergonomics or 0,
        RateOfFire = baseWeaponData.RateOfFire or 0,
        MagazineSize = baseWeaponData.MagazineSize or 0
    }

    -- Loop through active attachments and sum the modifiers
    for slot, attachId in pairs(weaponInstance.Attachments) do
        if attachId then
            local modData = AttachmentsData[attachId]
            if modData and modData.Stats then
                stats.Firepower = stats.Firepower + modData.Stats.Firepower
                stats.Accuracy = stats.Accuracy + modData.Stats.Accuracy
                stats.Range = stats.Range + modData.Stats.Range
                stats.Stability = stats.Stability + modData.Stats.Stability
                stats.Ergonomics = stats.Ergonomics + modData.Stats.Ergonomics
                stats.RateOfFire = stats.RateOfFire + modData.Stats.RateOfFire

                if modData.CapacityModifier then
                    stats.MagazineSize = stats.MagazineSize + modData.CapacityModifier
                end
            end
        end
    end

    -- Clamp values to logical Arena Breakout constraints (e.g., 0 to 100 scales)
    stats.Accuracy = math.clamp(stats.Accuracy, 0, 100)
    stats.Stability = math.clamp(stats.Stability, 0, 100)
    stats.Ergonomics = math.clamp(stats.Ergonomics, 0, 100)

    weaponInstance.TotalStats = stats
    return stats
end

return GunsmithSystem
