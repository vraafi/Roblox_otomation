local EquipmentSystem = {}

-- Memory Context: "Character abilities and stats do not increase with player level; they depend entirely on equipped gear, adhering to Albion Online's 'you are what you wear' classless system."
EquipmentSystem.ItemDatabase = {
    ["Broadsword"] = {
        type = "Weapon",
        slot = "MainHand",
        providedSkills = {
            Q = "Heroic Strike",
            W = "Splitting Slash",
            E = "Mighty Blow"
        },
        stats = { attackPower = 50 }
    },
    ["PlateArmor"] = {
        type = "Armor",
        slot = "Chest",
        providedSkills = {
            R = "Mend Wounds"
        },
        stats = { defense = 100, healthBonus = 200 }
    }
}

-- Simulates equipping an item and granting the player its skills
function EquipmentSystem.EquipItem(player, itemId)
    local itemData = EquipmentSystem.ItemDatabase[itemId]

    if not itemData then
        return false, "Item does not exist"
    end

    -- In a full Roblox integration, this would update a player's assigned abilities
    -- and potentially replicate a Tool or model to their character.
    print(player.Name .. " equipped " .. itemId .. " into the " .. itemData.slot .. " slot.")
    print(player.Name .. " gained the following skills from this item:")

    local grantedSkills = {}
    if itemData.providedSkills then
        for keybind, skillName in pairs(itemData.providedSkills) do
            print(" - [" .. keybind .. "] " .. skillName)
            grantedSkills[keybind] = skillName
        end
    end

    return true, grantedSkills, itemData.stats
end

return EquipmentSystem
