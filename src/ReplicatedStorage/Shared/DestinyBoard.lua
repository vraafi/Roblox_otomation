local DestinyBoard = {}

function DestinyBoard.new()
    local self = {
        nodes = {
            ["Beginner Fighter"] = { unlocked = true, fame = 0, maxFame = 1000 },
            ["Trainee Fighter"] = { unlocked = false, fame = 0, maxFame = 5000, req = "Beginner Fighter" },
            ["Journeyman Warrior"] = { unlocked = false, fame = 0, maxFame = 15000, req = "Trainee Fighter" },
            ["Sword Fighter"] = { unlocked = false, fame = 0, maxFame = 50000, req = "Journeyman Warrior" }
        }
    }
    setmetatable(self, { __index = DestinyBoard })
    return self
end

function DestinyBoard:AddFame(nodeName, amount)
    local node = self.nodes[nodeName]
    if node and node.unlocked then
        node.fame = math.min(node.fame + amount, node.maxFame)
        if node.fame >= node.maxFame then
            self:UnlockNextNodes(nodeName)
        end
        return true
    end
    return false
end

function DestinyBoard:UnlockNextNodes(completedNodeName)
    for name, node in pairs(self.nodes) do
        if node.req == completedNodeName then
            node.unlocked = true
        end
    end
end

return DestinyBoard
