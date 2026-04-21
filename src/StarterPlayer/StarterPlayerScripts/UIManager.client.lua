local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventorySystem = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InventorySystem"))

local UI = Instance.new("ScreenGui")
UI.Name = "AlbionUI"
UI.ResetOnSpawn = false
UI.Parent = player:WaitForChild("PlayerGui")

-- Basic Status UI
local healthBar = Instance.new("Frame")
healthBar.Size = UDim2.new(0, 200, 0, 20)
healthBar.Position = UDim2.new(0.5, -100, 0.9, 0)
healthBar.BackgroundColor3 = Color3.new(1, 0, 0)
healthBar.Parent = UI

local manaBar = Instance.new("Frame")
manaBar.Size = UDim2.new(0, 200, 0, 20)
manaBar.Position = UDim2.new(0.5, -100, 0.9, 25)
manaBar.BackgroundColor3 = Color3.new(0, 0, 1)
manaBar.Parent = UI

-- Inventory UI (48 slots container)
local inventoryFrame = Instance.new("ScrollingFrame")
inventoryFrame.Size = UDim2.new(0, 400, 0, 300)
inventoryFrame.Position = UDim2.new(0.8, -400, 0.2, 0)
inventoryFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
inventoryFrame.Parent = UI

local uigrid_inv = Instance.new("UIGridLayout")
uigrid_inv.CellSize = UDim2.new(0, 40, 0, 40)
uigrid_inv.Parent = inventoryFrame

for i = 1, 48 do
    local slot = Instance.new("TextButton")
    slot.Text = tostring(i)
    slot.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
    slot.Parent = inventoryFrame

    slot.MouseButton1Click:Connect(function()
        print("Clicked Inventory Slot: " .. i)
    end)
end

-- Equipment UI (10 slots container)
local equipmentFrame = Instance.new("Frame")
equipmentFrame.Size = UDim2.new(0, 200, 0, 300)
equipmentFrame.Position = UDim2.new(0.8, -610, 0.2, 0)
equipmentFrame.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
equipmentFrame.Parent = UI

local uigrid_eq = Instance.new("UIGridLayout")
uigrid_eq.CellSize = UDim2.new(0, 45, 0, 45)
uigrid_eq.Parent = equipmentFrame

for i = 1, 10 do
    local eqSlot = Instance.new("TextButton")
    eqSlot.Text = "EQ"..i
    eqSlot.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    eqSlot.Parent = equipmentFrame

    eqSlot.MouseButton1Click:Connect(function()
        print("Clicked Equipment Slot: " .. i)
    end)
end

-- Weight Text Label
local weightLabel = Instance.new("TextLabel")
weightLabel.Size = UDim2.new(0, 200, 0, 30)
weightLabel.Position = UDim2.new(0.8, -400, 0.2, -35)
weightLabel.BackgroundColor3 = Color3.new(0, 0, 0)
weightLabel.TextColor3 = Color3.new(1, 1, 1)
weightLabel.Text = "Weight: 0% / 100%"
weightLabel.Parent = UI
