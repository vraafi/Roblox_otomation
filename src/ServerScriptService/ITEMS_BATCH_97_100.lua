-- ITEMS_BATCH_97_100.lua (Handling Tasks ITEM_97 to ITEM_100)
-- Final 4 items to complete the 100 item requirement!

local LootItemSystemBatch22 = {}

local LootItemsData = {
    [97] = {
        Id = "Satellite_Dish",
        Name = "Satellite Dish",
        GridWidth = 2,
        GridHeight = 3,
        Weight = math.random(1, 10),
        Value = 1100,
        Color = Color3.fromRGB(150, 150, 150),
        Material = Enum.Material.Metal,
        MeshId = "rbxassetid://372630511" -- Placeholder
    },
    [98] = {
        Id = "Blood_Diamond",
        Name = "Blood Diamond",
        GridWidth = 1,
        GridHeight = 1,
        Weight = math.random(1, 10),
        Value = 6000,
        Color = Color3.fromRGB(120, 0, 0),
        Material = Enum.Material.Neon,
        MeshId = "rbxassetid://114425114"
    },
    [99] = {
        Id = "Quantum_Processor",
        Name = "Quantum Processor Unit",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 8500,
        Color = Color3.fromRGB(200, 255, 255),
        Material = Enum.Material.Glass,
        MeshId = "rbxassetid://114425114"
    },
    [100] = {
        Id = "Apex_Relic",
        Name = "The Apex Relic",
        GridWidth = 2,
        GridHeight = 2,
        Weight = math.random(1, 10),
        Value = 50000, -- The most valuable single slot item
        Color = Color3.fromRGB(0, 0, 0),
        Material = Enum.Material.ForceField,
        MeshId = "rbxassetid://645065406"
    }
}

function LootItemSystemBatch22.RegisterItems()
    local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

    for i = 97, 100 do
        local data = LootItemsData[i]
        if data then
            ItemDatabase.Items[data.Id] = {
                Id = data.Id,
                Name = data.Name,
                Type = "ValuableLoot",
                GridWidth = data.GridWidth,
                GridHeight = data.GridHeight,
                Value = data.Value
            }
        end
    end
    print("Registered Final Loot Items 97-100 into ItemDatabase.")
end

function LootItemSystemBatch22.SpawnPhysicalItem(id, position)
    local data = nil
    for _, v in pairs(LootItemsData) do
        if v.Id == id then
            data = v
            break
        end
    end

    if not data then return end

    local part = Instance.new("Part")
    part.Name = data.Name
    part.Size = Vector3.new(data.GridWidth, 0.5, data.GridHeight)
    part.Position = position
    part.Color = data.Color
    part.Material = data.Material
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
    prompt.ObjectText = data.Name
    prompt.Parent = part

    prompt.Triggered:Connect(function(player)
        print(player.Name .. " picked up " .. data.Name .. " (Worth $" .. data.Value .. ", Size: " .. data.GridWidth .. "x" .. data.GridHeight .. ")")
        part:Destroy()
    end)

    return part
end

return LootItemSystemBatch22
