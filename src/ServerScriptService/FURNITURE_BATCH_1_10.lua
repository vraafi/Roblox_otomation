-- FURNITURE_BATCH_1_10.lua (Handling Tasks FURNITURE_1 to FURNITURE_10)
-- Rancang furnitur unik untuk lobby pesawat luar angkasa. WAJIB tentukan dimensi Tetris.

local FurnitureBatch26 = {}

local FurnitureData = {
    [1] = { Name = "Stash_Box_T1", GridWidth = 3, GridHeight = 2, StorageCapacity = 20, Color = Color3.fromRGB(100, 100, 80) },
    [2] = { Name = "Gun_Rack", GridWidth = 4, GridHeight = 1, StorageCapacity = 15, Color = Color3.fromRGB(40, 40, 40) },
    [3] = { Name = "Medical_Fridge", GridWidth = 2, GridHeight = 3, StorageCapacity = 25, Color = Color3.fromRGB(220, 220, 220) },
    [4] = { Name = "Armor_Mannequin", GridWidth = 2, GridHeight = 2, StorageCapacity = 5, Color = Color3.fromRGB(150, 150, 150) },
    [5] = { Name = "Workbench_T1", GridWidth = 4, GridHeight = 2, StorageCapacity = 10, Color = Color3.fromRGB(130, 80, 40) },
    [6] = { Name = "Safe_Vault", GridWidth = 2, GridHeight = 2, StorageCapacity = 40, Color = Color3.fromRGB(20, 20, 20) },
    [7] = { Name = "Ammo_Crate", GridWidth = 2, GridHeight = 1, StorageCapacity = 30, Color = Color3.fromRGB(60, 80, 50) },
    [8] = { Name = "Alchemy_Table", GridWidth = 3, GridHeight = 2, StorageCapacity = 15, Color = Color3.fromRGB(80, 40, 120) },
    [9] = { Name = "Display_Case", GridWidth = 3, GridHeight = 1, StorageCapacity = 8, Color = Color3.fromRGB(200, 200, 255) },
    [10] = { Name = "Apex_Storage_Core", GridWidth = 4, GridHeight = 4, StorageCapacity = 100, Color = Color3.fromRGB(0, 255, 255) }
}

function FurnitureBatch26.SpawnFurniture(id, position, rotationY)
    local data = FurnitureData[id]
    if not data then return end

    local model = Instance.new("Model")
    model.Name = data.Name

    local part = Instance.new("Part")
    part.Name = "MainBody"
    part.Size = Vector3.new(data.GridWidth * 2, 4, data.GridHeight * 2) -- Scaled up for physical space
    part.Position = position + Vector3.new(0, part.Size.Y/2, 0)
    part.Orientation = Vector3.new(0, rotationY or 0, 0)
    part.Color = data.Color
    part.Material = Enum.Material.Metal
    part.Anchored = true
    part.Parent = model

    model.PrimaryPart = part
    model.Parent = workspace

    -- Interaction prompt for storage UI
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Open Storage"
    prompt.ObjectText = data.Name .. " (Capacity: " .. data.StorageCapacity .. ")"
    prompt.Parent = part

    prompt.Triggered:Connect(function(player)
        print(player.Name .. " opened " .. data.Name)
        -- In a real game, this fires a RemoteEvent to open the client's Tetris GUI
    end)

    return model
end

return FurnitureBatch26
