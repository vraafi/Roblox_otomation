-- ItemManager.lua
-- Centralized manager for spawning physical loot items, armors, and weapons.
-- Replaces the duplicated spawning logic across 14 separate batch files.

local ItemManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

function ItemManager.SpawnPhysicalItem(itemId, position)
    local data = ItemDatabase.GetItem(itemId)
    if not data then
        warn("ItemManager: Could not find item ID " .. tostring(itemId) .. " in Database.")
        return nil
    end

    local height = data.GridHeight or 1
    local width = data.GridWidth or 1

    local part = Instance.new("Part")
    part.Name = data.Name
    part.Size = Vector3.new(width * 0.8, 0.5, height * 0.8)
    part.Position = position
    part.Color = data.Color or Color3.new(1, 1, 1)
    part.Material = data.Material or Enum.Material.Plastic
    part.Parent = workspace

    if data.MeshId then
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = data.MeshId
        mesh.Scale = part.Size
        mesh.Parent = part
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pick Up"

    -- Format dynamic prompt text based on item type
    local promptTxt = data.Name
    if data.Type == "Weapon" then
        promptTxt = promptTxt .. " (Dmg: " .. tostring(data.BaseDamage or data.Damage or 0) .. ")"
        if data.ManaCost and data.ManaCost > 0 then
            promptTxt = promptTxt .. " [Mana: " .. data.ManaCost .. "]"
        end
    elseif data.Type == "Armor" then
        promptTxt = promptTxt .. " (Def: " .. tostring(data.DefenseBonus or 0) .. " | Mana: " .. tostring(data.ManaBonus or 0) .. ")"
    else
        promptTxt = promptTxt .. " ($" .. tostring(data.Value or 0) .. ")"
    end

    prompt.ObjectText = promptTxt
    prompt.Parent = part

    prompt.Triggered:Connect(function(player)
        print(player.Name .. " looted " .. data.Name)

        -- Fire RemoteEvent to update client UI
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local events = replicatedStorage:FindFirstChild("Events")
        if not events then
            events = Instance.new("Folder")
            events.Name = "Events"
            events.Parent = replicatedStorage
        end

        local pickupEvent = events:FindFirstChild("ItemPickedUp")
        if not pickupEvent then
            pickupEvent = Instance.new("RemoteEvent")
            pickupEvent.Name = "ItemPickedUp"
            pickupEvent.Parent = events
        end

        -- Add to Server Inventory Data
        local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
        local playerData = PlayerManager.ActivePlayers[player.UserId]
        if playerData then
            table.insert(playerData.Inventory.Items, data.Id)
        end

        -- Send data to the client so it renders on the Tetris Grid
        pickupEvent:FireClient(player, {
            Name = data.Name,
            GridWidth = width,
            GridHeight = height,
            Color = data.Color
        })

        part:Destroy()
    end)

    return part
end

-- Calculates a random item ID weighted strictly by its Value.
-- Cheap items have a massively higher drop chance. Rare/Expensive items drop very rarely.
-- This regulates supply on the Flea Market, creating an organic price ceiling.
function ItemManager.GetRandomWeightedItem()
    local totalWeight = 0
    local weightTable = {}

    for id, data in pairs(ItemDatabase.Items) do
        if data.Type == "ValuableLoot" or data.Type == "Weapon" or data.Type == "Armor" then
            local baseValue = data.Value or 100

            -- The weight formula: Inversely proportional to value.
            -- A $10 item has a weight of 1,000,000. A $50,000 item has a weight of 200.
            local dropWeight = math.floor(10000000 / baseValue)

            table.insert(weightTable, {Id = id, Weight = dropWeight})
            totalWeight = totalWeight + dropWeight
        end
    end

    if totalWeight == 0 then return nil end

    local randomTarget = math.random(1, totalWeight)
    local currentSum = 0

    for _, entry in ipairs(weightTable) do
        currentSum = currentSum + entry.Weight
        if randomTarget <= currentSum then
            return entry.Id
        end
    end

    return nil
end

return ItemManager
