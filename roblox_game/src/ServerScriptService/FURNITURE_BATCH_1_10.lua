-- FURNITURE_BATCH_1_10.lua
-- Furnitur untuk lobby pesawat luar angkasa & pulau Kalimantan.
-- Menggunakan VisualAssetOverhaul.BuildFurniture() untuk aset 3D AAA.

local FurnitureBatch26 = {}

local FurnitureData = {
    [1]  = { Name = "Stash_Box_T1",      GridWidth = 3, GridHeight = 2, StorageCapacity = 20,  Color = Color3.fromRGB(100, 100, 80)  },
    [2]  = { Name = "Gun_Rack",           GridWidth = 4, GridHeight = 1, StorageCapacity = 15,  Color = Color3.fromRGB(40,  40,  40)  },
    [3]  = { Name = "Medical_Fridge",     GridWidth = 2, GridHeight = 3, StorageCapacity = 25,  Color = Color3.fromRGB(220, 220, 220) },
    [4]  = { Name = "Armor_Mannequin",    GridWidth = 2, GridHeight = 2, StorageCapacity = 5,   Color = Color3.fromRGB(150, 150, 150) },
    [5]  = { Name = "Workbench_T1",       GridWidth = 4, GridHeight = 2, StorageCapacity = 10,  Color = Color3.fromRGB(130, 80,  40)  },
    [6]  = { Name = "Safe_Vault",         GridWidth = 2, GridHeight = 2, StorageCapacity = 40,  Color = Color3.fromRGB(20,  20,  20)  },
    [7]  = { Name = "Ammo_Crate",         GridWidth = 2, GridHeight = 1, StorageCapacity = 30,  Color = Color3.fromRGB(60,  80,  50)  },
    [8]  = { Name = "Alchemy_Table",      GridWidth = 3, GridHeight = 2, StorageCapacity = 15,  Color = Color3.fromRGB(80,  40,  120) },
    [9]  = { Name = "Display_Case",       GridWidth = 3, GridHeight = 1, StorageCapacity = 8,   Color = Color3.fromRGB(200, 200, 255) },
    [10] = { Name = "Apex_Storage_Core",  GridWidth = 4, GridHeight = 4, StorageCapacity = 100, Color = Color3.fromRGB(0,   255, 255) },
}

-- ── Helper: lazy-require VisualAssetOverhaul ─────────────────
local _VisualAssets = nil
local function getVisualAssets()
    if not _VisualAssets then
        local ok, mod = pcall(function()
            return require(game:GetService("ServerScriptService"):WaitForChild("VisualAssetOverhaul", 5))
        end)
        if ok and mod then _VisualAssets = mod end
    end
    return _VisualAssets
end

-- ── Main spawn function ──────────────────────────────────────
function FurnitureBatch26.SpawnFurniture(id, position, rotationY)
    local data = FurnitureData[id]
    if not data then return end

    local VA = getVisualAssets()
    local model

    if VA then
        -- AAA multi-part furniture via VisualAssetOverhaul
        model = VA.BuildFurniture(data, position, rotationY or 0)
    else
        -- Fallback: single coloured box with prompt
        model = Instance.new("Model")
        model.Name = data.Name

        local part = Instance.new("Part")
        part.Name     = "MainBody"
        part.Size     = Vector3.new(data.GridWidth * 2, 4, data.GridHeight * 2)
        part.Position = position + Vector3.new(0, part.Size.Y / 2, 0)
        part.Orientation = Vector3.new(0, rotationY or 0, 0)
        part.Color    = data.Color
        part.Material = Enum.Material.Metal
        part.Anchored = true
        part.Parent   = model

        model.PrimaryPart = part

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Open Storage"
        prompt.ObjectText = data.Name .. " (Capacity: " .. data.StorageCapacity .. ")"
        prompt.Parent     = part

        prompt.Triggered:Connect(function(player)
            print(player.Name .. " opened " .. data.Name)
            local evFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
            if evFolder then
                local openEv = evFolder:FindFirstChild("OpenStorage")
                if openEv then
                    openEv:FireClient(player, data.Name, data.StorageCapacity)
                end
            end
        end)
    end

    if model then
        -- Wire up interaction callback on the primary part's existing prompt
        if model.PrimaryPart then
            local existingPrompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
            if existingPrompt then
                existingPrompt.Triggered:Connect(function(player)
                    print(player.Name .. " opened " .. data.Name .. " (Capacity: " .. data.StorageCapacity .. ")")
                    local evFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
                    if evFolder then
                        local openEv = evFolder:FindFirstChild("OpenStorage")
                        if openEv then
                            openEv:FireClient(player, data.Name, data.StorageCapacity)
                        end
                    end
                end)
            end
        end

        model.Parent = workspace
    end

    return model
end

return FurnitureBatch26
