local InventorySystem = {}
function InventorySystem.new()
    local self = { items = {}, equipped = {} }
    setmetatable(self, { __index = InventorySystem })
    return self
end
function InventorySystem:AddItem(item)
    table.insert(self.items, item)
end
function InventorySystem:EquipItem(slot, item)
    self.equipped[slot] = item
end
return InventorySystem
