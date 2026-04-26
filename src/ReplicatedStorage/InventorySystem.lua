-- InventorySystem.lua
-- Manages player inventory, equipping, and the Tetris-style grid concepts

local InventorySystem = {}

-- A player's inventory structure
function InventorySystem.NewInventory()
    return {
        -- Base pockets, no backpack equipped
        Rows = 2,
        Cols = 2,
        SafeCase = {
            Rows = 2,
            Cols = 2,
            Items = {} -- Items here survive death
        },
        Equipped = {
            Head = nil,
            Chest = nil,
            Legs = nil,
            Weapon = nil,
            Secondary = nil,
            Backpack = nil,
        },
        Items = {} -- General loot items
    }
end

-- Recalculates grid capacity based on equipped backpack
function InventorySystem.UpdateCapacity(inventory)
    local ItemDatabase = require(script.Parent.ItemDatabase)
    local bpId = inventory.Equipped.Backpack

    if bpId then
        local bpData = ItemDatabase.GetItem(bpId)
        if bpData and bpData.InventoryWidth and bpData.InventoryHeight then
            inventory.Cols = bpData.InventoryWidth
            inventory.Rows = bpData.InventoryHeight
            return
        end
    end

    -- Default naked pockets
    inventory.Cols = 2
    inventory.Rows = 2
end

-- Equips an item if it's the correct type
function InventorySystem.EquipItem(inventory, itemId)
    local ItemDatabase = require(script.Parent.ItemDatabase)
    local itemData = ItemDatabase.GetItem(itemId)

    if not itemData then return false, "Item not found" end

    if itemData.Type == "Armor" or itemData.Type == "Backpack" then
        local slot = itemData.Type == "Backpack" and "Backpack" or itemData.Slot
        if slot then
            local oldItem = inventory.Equipped[slot]
            inventory.Equipped[slot] = itemId
            InventorySystem.UpdateCapacity(inventory)
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
        InventorySystem.UpdateCapacity(inventory)
        return true, unequippedId
    end
    return false, "Slot is already empty"
end

return InventorySystem
