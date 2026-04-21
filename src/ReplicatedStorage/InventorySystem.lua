-- InventorySystem.lua
-- Manages player inventory, equipping, and the Tetris-style grid concepts

local InventorySystem = {}

-- A player's inventory structure
function InventorySystem.NewInventory(rows, cols)
    return {
        Grid = {}, -- Could be a 2D array for Tetris inventory
        Rows = rows or 10,
        Cols = cols or 10,
        Equipped = {
            Head = nil,
            Chest = nil,
            Legs = nil,
            Weapon = nil,
            Secondary = nil,
            Backpack = nil,
        },
        Items = {} -- List of items stored
    }
end

-- Equips an item if it's the correct type
function InventorySystem.EquipItem(inventory, itemId)
    local ItemDatabase = require(script.Parent.ItemDatabase)
    local itemData = ItemDatabase.GetItem(itemId)

    if not itemData then return false, "Item not found" end

    if itemData.Type == "Armor" then
        if itemData.Slot then
            local oldItem = inventory.Equipped[itemData.Slot]
            inventory.Equipped[itemData.Slot] = itemId
            return true, oldItem
        end
    elseif itemData.Type == "Weapon" then
        local oldItem = inventory.Equipped.Weapon
        inventory.Equipped.Weapon = itemId
        return true, oldItem
    end

    return false, "Cannot equip this item"
end

function InventorySystem.UnequipItem(inventory, slot)
    if inventory.Equipped[slot] then
        local unequippedId = inventory.Equipped[slot]
        inventory.Equipped[slot] = nil
        return true, unequippedId
    end
    return false, "Slot is already empty"
end

return InventorySystem
