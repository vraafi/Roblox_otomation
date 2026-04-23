-- GUIManager.client.lua
-- Procedurally constructs the client-side UI (Health, Mana, Inventory)
-- and ensures every screen has a functional 'X' close button.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local GUIManager = {}

function GUIManager.Initialize()
    -- Create the main ScreenGui container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AbsoluteApexHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    GUIManager.CreateVitalsHUD(screenGui)
    GUIManager.CreateInventoryScreen(screenGui)

    -- Bind Inventory to Tab key
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, isProcessed)
        if isProcessed then return end
        if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.I then
            GUIManager.ToggleInventory()
        end
    end)

    -- Create an on-screen button for Mobile users to open inventory
    if UserInputService.TouchEnabled then
        local invBtn = Instance.new("TextButton")
        invBtn.Name = "MobileInvButton"
        invBtn.Size = UDim2.new(0, 60, 0, 60)
        invBtn.Position = UDim2.new(0, 20, 0, 150)
        invBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        invBtn.TextColor3 = Color3.new(1, 1, 1)
        invBtn.Text = "BAG"
        invBtn.Font = Enum.Font.SourceSansBold
        invBtn.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = invBtn

        invBtn.MouseButton1Click:Connect(function()
            GUIManager.ToggleInventory()
        end)
    end
end

function GUIManager.CreateVitalsHUD(parentGui)
    -- Frame for Health & Mana
    local vitalsFrame = Instance.new("Frame")
    vitalsFrame.Name = "VitalsHUD"
    vitalsFrame.Size = UDim2.new(0, 300, 0, 80)
    vitalsFrame.Position = UDim2.new(0, 20, 0, 20)
    vitalsFrame.BackgroundTransparency = 1
    vitalsFrame.Parent = parentGui

    -- Health Bar Background
    local hpBG = Instance.new("Frame")
    hpBG.Size = UDim2.new(1, 0, 0, 30)
    hpBG.Position = UDim2.new(0, 0, 0, 0)
    hpBG.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    hpBG.Parent = vitalsFrame

    -- Health Bar Fill
    local hpFill = Instance.new("Frame")
    hpFill.Name = "HealthFill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    hpFill.Parent = hpBG

    -- Mana Bar Background
    local mpBG = Instance.new("Frame")
    mpBG.Size = UDim2.new(1, 0, 0, 20)
    mpBG.Position = UDim2.new(0, 0, 0, 35)
    mpBG.BackgroundColor3 = Color3.fromRGB(0, 0, 50)
    mpBG.Parent = vitalsFrame

    -- Mana Bar Fill
    local mpFill = Instance.new("Frame")
    mpFill.Name = "ManaFill"
    mpFill.Size = UDim2.new(0.5, 0, 1, 0) -- Example 50%
    mpFill.BackgroundColor3 = Color3.fromRGB(50, 100, 255)
    mpFill.Parent = mpBG

    -- Add UI Corners for modern look
    for _, obj in pairs({hpBG, hpFill, mpBG, mpFill}) do
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.2, 0)
        corner.Parent = obj
    end

    -- Text Labels
    local hpText = Instance.new("TextLabel")
    hpText.Size = UDim2.new(1, 0, 1, 0)
    hpText.BackgroundTransparency = 1
    hpText.Text = "100 / 100"
    hpText.TextColor3 = Color3.new(1,1,1)
    hpText.Font = Enum.Font.SourceSansBold
    hpText.TextStrokeTransparency = 0
    hpText.Parent = hpBG

    local mpText = Instance.new("TextLabel")
    mpText.Size = UDim2.new(1, 0, 1, 0)
    mpText.BackgroundTransparency = 1
    mpText.Text = "50 / 100"
    mpText.TextColor3 = Color3.new(1,1,1)
    mpText.Font = Enum.Font.SourceSansBold
    mpText.TextStrokeTransparency = 0
    mpText.Parent = mpBG
end

local inventoryScreen = nil

function GUIManager.CreateInventoryScreen(parentGui)
    inventoryScreen = Instance.new("Frame")
    inventoryScreen.Name = "InventoryScreen"
    inventoryScreen.Size = UDim2.new(0.6, 0, 0.7, 0)
    inventoryScreen.Position = UDim2.new(0.2, 0, 0.15, 0)
    inventoryScreen.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    inventoryScreen.BackgroundTransparency = 0.1
    inventoryScreen.Visible = false -- Hidden by default
    inventoryScreen.Parent = parentGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.05, 0)
    corner.Parent = inventoryScreen

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "STORAGE & GEAR (Tetris Grid)"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = inventoryScreen

    -- ==============================================================
    -- CRITICAL REQUIREMENT: 'X' BUTTON TOP RIGHT TO CLOSE GUI
    -- ==============================================================
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 24
    closeBtn.Parent = inventoryScreen

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0.2, 0)
    btnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        GUIManager.ToggleInventory(false)
    end)

    -- Placeholder Grid Frame
    local gridFrame = Instance.new("Frame")
    gridFrame.Size = UDim2.new(0.95, 0, 0.8, 0)
    gridFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
    gridFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    gridFrame.Parent = inventoryScreen

    -- We can use UIGridLayout to simulate the Tetris inventory slots
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 50, 0, 50)
    gridLayout.CellPadding = UDim2.new(0, 2, 0, 2)
    gridLayout.Parent = gridFrame
end

function GUIManager.ToggleInventory(forceState)
    if not inventoryScreen then return end

    if forceState ~= nil then
        inventoryScreen.Visible = forceState
    else
        inventoryScreen.Visible = not inventoryScreen.Visible
    end

    -- Tell InputManager to freeze character jumping/shooting when menu is open
    if _G.SetMenuState then
        _G.SetMenuState(inventoryScreen.Visible)
    end

    -- Optional: Unlock mouse pointer when UI is open
    local UserInputService = game:GetService("UserInputService")
    if inventoryScreen.Visible then
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    else
        -- If player is in first-person/shift-lock
        -- UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end

-- Wait a second to ensure player is loaded, then initialize
task.spawn(function()
    task.wait(1)
    GUIManager.Initialize()
end)

return GUIManager
