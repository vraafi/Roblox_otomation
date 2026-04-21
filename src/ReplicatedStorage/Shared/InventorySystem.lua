local InventorySystem = {}

function InventorySystem.new(maxWeightCapacity)
    local self = {
        inventorySlots = {}, -- Max 48 slots
        equipmentSlots = {}, -- Max 10 slots
        maxWeightCapacity = maxWeightCapacity or 100,
        currentWeight = 0
    }

    -- Initialize 48 inventory slots
    for i = 1, 48 do
        self.inventorySlots[i] = nil
    end

    -- Initialize 10 equipment slots
    for i = 1, 10 do
        self.equipmentSlots[i] = nil
    end

    setmetatable(self, { __index = InventorySystem })
    return self
end

function InventorySystem:CalculateWeight()
    local totalWeight = 0
    for _, item in pairs(self.inventorySlots) do
        if item and item.weight then
            totalWeight = totalWeight + item.weight
        end
    end
    self.currentWeight = totalWeight
    return totalWeight
end

function InventorySystem:GetMovementPenalty()
    self:CalculateWeight()
    if self.currentWeight > self.maxWeightCapacity then
        -- Basic movement penalty for exceeding 100% capacity
        return 0.5 -- 50% speed reduction as a placeholder basic penalty
    end
    return 0 -- No penalty
end

function InventorySystem:AddItem(slot, item)
    if slot > 0 and slot <= 48 and not self.inventorySlots[slot] then
        self.inventorySlots[slot] = item
        self:CalculateWeight()
        return true
    end
    return false
end

function InventorySystem:EquipItem(slot, item)
    if slot > 0 and slot <= 10 and not self.equipmentSlots[slot] then
        self.equipmentSlots[slot] = item
        -- Equipped items don't count towards weight
        self:CalculateWeight()
        return true
    end
    return false
end

return InventorySystem
