local player = game.Players.LocalPlayer
local UI = Instance.new("ScreenGui")
UI.Name = "AlbionUI"
UI.Parent = player:WaitForChild("PlayerGui")

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
