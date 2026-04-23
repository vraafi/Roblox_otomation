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

return ItemManager
