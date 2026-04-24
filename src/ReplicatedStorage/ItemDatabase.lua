-- ItemDatabase.lua
-- Defines all items in the game.

local ItemDatabase = {}

-- You are what you wear: Core concept from Albion Online.
-- Modern weapons, fantasy weapons (wands with cores), modern medical, fantasy medical, armor with cores.

ItemDatabase.Items = {
    -- Modern Weapons
    ["M4A1_Assault_Rifle"] = {
        Id = "M4A1_Assault_Rifle",
        Type = "Weapon",
        SubType = "ModernFirearm",
        Damage = 35,
        FireRate = 0.1,
        MagazineSize = 30,
        Weight = 3.5,
    },
    ["Glock_19"] = {
        Id = "Glock_19",
        Type = "Weapon",
        SubType = "ModernFirearm",
        Damage = 20,
        FireRate = 0.2,
        MagazineSize = 15,
        Weight = 1.2,
    },

    -- Fantasy Weapons (Magic Wands require monster cores)
    ["Novice_Wand"] = {
        Id = "Novice_Wand",
        Type = "Weapon",
        SubType = "MagicWand",
        BaseDamage = 15,
        CoreLevelRequired = 1,
        ManaCost = 5,
        Weight = 1.0,
    },
    ["Elder_Wand"] = {
        Id = "Elder_Wand",
        Type = "Weapon",
        SubType = "MagicWand",
        BaseDamage = 80,
        CoreLevelRequired = 9,
        ManaCost = 30,
        Weight = 2.0,
    },

    -- Armor (You are what you wear - stats come strictly from here)
    ["Tactical_Vest_Basic"] = {
        Id = "Tactical_Vest_Basic",
        Type = "Armor",
        Slot = "Chest",
        HealthBonus = 100,
        DefenseBonus = 20,
        ManaBonus = 0,
        CoreLevel = 0, -- Modern armor doesn't have cores
        Weight = 5.0,
    },
    ["Mage_Robe_T1"] = {
        Id = "Mage_Robe_T1",
        Type = "Armor",
        Slot = "Chest",
        HealthBonus = 30,
        DefenseBonus = 5,
        ManaBonus = 50,
        CoreLevel = 1, -- Level 1 core embedded
        Weight = 1.5,
    },
    ["Archmage_Robe_T9"] = {
        Id = "Archmage_Robe_T9",
        Type = "Armor",
        Slot = "Chest",
        HealthBonus = 150,
        DefenseBonus = 30,
        ManaBonus = 500,
        CoreLevel = 9, -- Level 9 core embedded
        Weight = 2.5,
    },

    -- Medical (Modern)
    ["IFAK_Medkit"] = {
        Id = "IFAK_Medkit",
        Type = "Consumable",
        SubType = "ModernMedical",
        HealAmount = 100,
        UseTime = 3.0,
        Weight = 0.5,
    },

    -- Medical (Fantasy)
    ["Minor_Healing_Potion"] = {
        Id = "Minor_Healing_Potion",
        Type = "Consumable",
        SubType = "FantasyMedical",
        HealAmount = 50,
        UseTime = 1.0, -- Faster to drink than wrap a bandage
        Weight = 0.2,
    },
    ["Major_Mana_Potion"] = {
        Id = "Major_Mana_Potion",
        Type = "Consumable",
        SubType = "FantasyMedical",
        ManaRestoreAmount = 150,
        UseTime = 1.0,
        Weight = 0.2,
    },

    -- Monster Cores (Used to craft/upgrade or power things)
    ["Monster_Core_T1"] = {
        Id = "Monster_Core_T1",
        Type = "Material",
        SubType = "Core",
        Level = 1,
        Weight = 0.1,
    },
    ["Monster_Core_T9"] = {
        Id = "Monster_Core_T9",
        Type = "Material",
        SubType = "Core",
        Level = 9,
        Weight = 0.1,
    }
}

function ItemDatabase.GetItem(itemId)
    return ItemDatabase.Items[itemId]
end


-- Expand ItemDatabase with Advanced Medical Items
ItemDatabase.Items["Surgical_Kit"] = {
    Id = "Surgical_Kit",
    Type = "Consumable",
    SubType = "ModernMedical",
    HealAmount = 0,
    FixesLimb = true,
    UseTime = 12.0,
    Weight = 1.0,
}
ItemDatabase.Items["Military_Bandage"] = {
    Id = "Military_Bandage",
    Type = "Consumable",
    SubType = "ModernMedical",
    HealAmount = 10,
    StopsBleeding = true,
    UseTime = 2.0,
    Weight = 0.1,
}
ItemDatabase.Items["Tourniquet"] = {
    Id = "Tourniquet",
    Type = "Consumable",
    SubType = "ModernMedical",
    HealAmount = 0,
    StopsBleeding = true,
    StopsPain = true,
    UseTime = 3.5,
    Weight = 0.2,
}


-- Expand ItemDatabase with hit zones
ItemDatabase.Items["Tactical_Helmet"] = {
    Id = "Tactical_Helmet",
    Type = "Armor",
    Slot = "Helmet",
    HealthBonus = 20,
    DefenseBonus = 30,
    ManaBonus = 0,
    CoreLevel = 0,
    Weight = 2.0,
    Protects = {"Head"}
}

ItemDatabase.Items["Tactical_Vest_Basic"].Protects = {"Thorax", "Stomach"}
ItemDatabase.Items["Mage_Robe_T1"].Protects = {"Thorax", "Stomach", "LeftArm", "RightArm"}
ItemDatabase.Items["Archmage_Robe_T9"].Protects = {"Thorax", "Stomach", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}


-- Expand ItemDatabase with active skills (Albion Online style)
ItemDatabase.Items["Archmage_Robe_T9"].ActiveSkill = {
    Name = "Mana Shield",
    ManaCost = 100,
    Cooldown = 30,
    Duration = 5,
    Effect = "Invulnerability"
}

ItemDatabase.Items["Elder_Wand"].ActiveSkill = {
    Name = "Meteor Strike",
    ManaCost = 150,
    Cooldown = 45,
    Damage = 300,
    AoERadius = 15
}

return ItemDatabase
