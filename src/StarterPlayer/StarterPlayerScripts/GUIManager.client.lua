-- GUIManager.client.lua
-- Procedurally constructs the client-side UI (Health, Mana, Inventory)
-- and ensures every screen has a functional 'X' close button.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ClientState = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ClientState"))
local GUIManager = {}

function GUIManager.Initialize()
    -- Create the main ScreenGui container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AbsoluteApexHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    GUIManager.CreateVitalsHUD(screenGui)
    GUIManager.CreateLimbHUD(screenGui)
    GUIManager.CreateTacticalHUD(screenGui)
    GUIManager.CreateInventoryScreen(screenGui)
    GUIManager.CreateFleaMarketScreen(screenGui)
    GUIManager.CreateMapScreen(screenGui)

    -- Create on-screen buttons for Mobile users
    local UserInputService = game:GetService("UserInputService")
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

        local marketBtn = Instance.new("TextButton")
        marketBtn.Name = "MobileMarketButton"
        marketBtn.Size = UDim2.new(0, 60, 0, 60)
        marketBtn.Position = UDim2.new(0, 20, 0, 220)
        marketBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        marketBtn.TextColor3 = Color3.new(1, 1, 1)
        marketBtn.Text = "MARKET"
        marketBtn.Font = Enum.Font.SourceSansBold
        marketBtn.Parent = screenGui

        local corner2 = Instance.new("UICorner")
        corner2.CornerRadius = UDim.new(0.5, 0)
        corner2.Parent = marketBtn

        marketBtn.MouseButton1Click:Connect(function()
            GUIManager.ToggleFleaMarket()
        end)

        local mapBtn = Instance.new("TextButton")
        mapBtn.Name = "MobileMapButton"
        mapBtn.Size = UDim2.new(0, 60, 0, 60)
        mapBtn.Position = UDim2.new(0, 20, 0, 290)
        mapBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
        mapBtn.TextColor3 = Color3.new(1, 1, 1)
        mapBtn.Text = "MAP"
        mapBtn.Font = Enum.Font.SourceSansBold
        mapBtn.Parent = screenGui

        local corner3 = Instance.new("UICorner")
        corner3.CornerRadius = UDim.new(0.5, 0)
        corner3.Parent = mapBtn

        mapBtn.MouseButton1Click:Connect(function()
            GUIManager.ToggleMap()
        end)
    end
end

local mapScreen = nil

function GUIManager.CreateMapScreen(parentGui)
    mapScreen = Instance.new("Frame")
    mapScreen.Name = "MapScreen"
    mapScreen.Size = UDim2.new(0.8, 0, 0.8, 0)
    mapScreen.Position = UDim2.new(0.1, 0, 0.1, 0)
    mapScreen.BackgroundColor3 = Color3.fromRGB(20, 25, 20)
    mapScreen.BackgroundTransparency = 0.1
    mapScreen.Visible = false
    mapScreen.Parent = parentGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.05, 0)
    corner.Parent = mapScreen

    local title = Instance.new("TextLabel")
    title.Name = "MapTitle"
    title.Size = UDim2.new(1, -50, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "TACTICAL MAP: Initializing..."
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = mapScreen

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 24
    closeBtn.Parent = mapScreen

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0.2, 0)
    btnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        GUIManager.ToggleMap(false)
    end)

    local mapDisplay = Instance.new("Frame")
    mapDisplay.Name = "MapDisplay"
    mapDisplay.Size = UDim2.new(0.95, 0, 0.85, 0)
    mapDisplay.Position = UDim2.new(0.025, 0, 0.1, 0)
    mapDisplay.BackgroundColor3 = Color3.fromRGB(10, 15, 10)
    mapDisplay.Parent = mapScreen

    -- A label to hold dynamic map data/icons
    local mapContent = Instance.new("TextLabel")
    mapContent.Name = "MapContent"
    mapContent.Size = UDim2.new(1, -20, 1, -20)
    mapContent.Position = UDim2.new(0, 10, 0, 10)
    mapContent.BackgroundTransparency = 1
    mapContent.Text = "Loading topographical data..."
    mapContent.TextColor3 = Color3.fromRGB(150, 255, 150)
    mapContent.Font = Enum.Font.Code
    mapContent.TextSize = 18
    mapContent.TextXAlignment = Enum.TextXAlignment.Left
    mapContent.TextYAlignment = Enum.TextYAlignment.Top
    mapContent.Parent = mapDisplay
end

function GUIManager.ToggleMap(forceState)
    if not mapScreen then return end

    if forceState ~= nil then
        mapScreen.Visible = forceState
    else
        mapScreen.Visible = not mapScreen.Visible
    end

    if ClientState.SetMenuState then ClientState.SetMenuState(mapScreen.Visible) end

    if mapScreen.Visible then
        local player = game.Players.LocalPlayer
        local char = player.Character
        local mapContent = mapScreen.MapDisplay.MapContent
        local mapTitle = mapScreen.MapTitle

        if char and char:FindFirstChild("HumanoidRootPart") then
            local yPos = char.HumanoidRootPart.Position.Y
            -- Use elevation (Y axis) to deduce location since Lobby is Y=1000+
            if yPos > 800 then
                mapTitle.Text = "TACTICAL MAP: O'Neill Spaceship Lobby"
                mapContent.Text = "LOCATION: Safe Zone - Century-Class Orbital Habitat\n\n" ..
                                  "POINTS OF INTEREST:\n" ..
                                  "[ ] Quartermaster Riggs (Weapons/Armor) : East Wing\n" ..
                                  "[ ] Apothecary Vael (Magic/Consumables) : West Wing\n" ..
                                  "[ ] Fantasy Portal Domain : North Hangar\n" ..
                                  "[ ] Player Stash / Extraction Deposit : South Hangar\n\n" ..
                                  "WARNING: Ensure gear loadout does not exceed 70kg before entering portal."
            else
                mapTitle.Text = "TACTICAL MAP: Kalimantan Macro-Biome"
                mapContent.Text = "LOCATION: Combat Zone - Kalimantan Grid (1330km x 960km)\n\n" ..
                                  "TOPOGRAPHY: Proceed with extreme caution. Hostile ecosystem detected.\n" ..
                                  "[ ! ] Alpha Extraction Zone: Central Grid (0, 0)\n\n" ..
                                  "WEATHER ADVISORY: Monitoring for Seasonal Shifts and Meteor Strikes.\n" ..
                                  "STATUS: " .. tostring(math.floor(char.Humanoid.Health)) .. " / " .. tostring(char.Humanoid.MaxHealth) .. " HP"
            end
        end
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
    mpText.Text = "0 / 0"
    mpText.TextColor3 = Color3.new(1,1,1)
    mpText.Font = Enum.Font.SourceSansBold
    mpText.TextStrokeTransparency = 0
    mpText.Parent = mpBG

    -- Dynamically update Health and Mana bars
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")

    local function updateBars()
        local maxHp = humanoid.MaxHealth
        local currentHp = humanoid.Health
        hpText.Text = math.floor(currentHp) .. " / " .. math.floor(maxHp)
        hpFill.Size = UDim2.new(currentHp / maxHp, 0, 1, 0)

        -- In a real game, Mana is stored in an IntValue or PlayerManager
        -- Here we simulate reading it from a hypothetical ManaValue object or default to 0
        -- Since the server tracks mana internally without ValueObjects in this architecture,
        -- we would rely on the UpdateVitals RemoteEvent we created earlier.
        -- But for the continuous loop fallback, we'll read humanoid health for HP, and assume mana is pushed via events.
        local currentMana = GUIManager.CachedMana or 0
        local maxMana = GUIManager.CachedMaxMana or 0

        if maxMana > 0 then
            mpText.Text = math.floor(currentMana) .. " / " .. math.floor(maxMana)
            mpFill.Size = UDim2.new(currentMana / maxMana, 0, 1, 0)
        else
            mpText.Text = "NO MANA CORE EQUIPPED"
            mpFill.Size = UDim2.new(0, 0, 1, 0)
        end
    end

    humanoid.HealthChanged:Connect(updateBars)
    updateBars()
end

local inventoryScreen = nil
local marketScreen = nil

function GUIManager.CreateFleaMarketScreen(parentGui)
    marketScreen = Instance.new("Frame")
    marketScreen.Name = "FleaMarketScreen"
    marketScreen.Size = UDim2.new(0.7, 0, 0.8, 0)
    marketScreen.Position = UDim2.new(0.15, 0, 0.1, 0)
    marketScreen.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    marketScreen.BackgroundTransparency = 0.05
    marketScreen.Visible = false
    marketScreen.Parent = parentGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.05, 0)
    corner.Parent = marketScreen

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "FLEA MARKET (Player-to-Player)"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = marketScreen

    -- 'X' Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 24
    closeBtn.Parent = marketScreen

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0.2, 0)
    btnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        GUIManager.ToggleFleaMarket(false)
    end)

    -- Search Bar
    local searchBar = Instance.new("TextBox")
    searchBar.Name = "SearchBar"
    searchBar.Size = UDim2.new(0.4, 0, 0, 30)
    searchBar.Position = UDim2.new(0, 10, 0, 50)
    searchBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    searchBar.TextColor3 = Color3.new(1,1,1)
    searchBar.PlaceholderText = "Search items..."
    searchBar.Font = Enum.Font.SourceSans
    searchBar.TextSize = 18
    searchBar.Parent = marketScreen

    -- Categories
    local categories = {"All", "Weapon", "Armor", "ValuableLoot", "Consumable"}
    for i, cat in ipairs(categories) do
        local catBtn = Instance.new("TextButton")
        catBtn.Size = UDim2.new(0, 100, 0, 30)
        catBtn.Position = UDim2.new(0.42 + ((i-1)*0.11), 0, 0, 50)
        catBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        catBtn.Text = cat
        catBtn.TextColor3 = Color3.new(1,1,1)
        catBtn.Parent = marketScreen
    end

    -- Listing Area
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "Listings"
    listFrame.Size = UDim2.new(0.95, 0, 0.7, 0)
    listFrame.Position = UDim2.new(0.025, 0, 0.2, 0)
    listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    listFrame.Parent = marketScreen

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = listFrame
end

function GUIManager.ToggleFleaMarket(forceState)
    if not marketScreen then return end

    if forceState ~= nil then
        marketScreen.Visible = forceState
    else
        marketScreen.Visible = not marketScreen.Visible
    end

    if ClientState.SetMenuState then ClientState.SetMenuState(marketScreen.Visible) end

    local UserInputService = game:GetService("UserInputService")
    if marketScreen.Visible then
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default

        -- Pull active listings from the server
        local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
        if events then
            local marketReq = events:FindFirstChild("MarketRequest")
            if marketReq then
                task.spawn(function()
                    local success, listings = marketReq:InvokeServer("GetMarket", "All", "")
                    if success and listings then
                        local listFrame = marketScreen:FindFirstChild("Listings")
                        if listFrame then
                            -- Clear old UI
                            for _, child in ipairs(listFrame:GetChildren()) do
                                if child:IsA("Frame") then child:Destroy() end
                            end

                            -- Populate new UI
                            for _, listing in ipairs(listings) do
                                local frame = Instance.new("Frame")
                                frame.Size = UDim2.new(1, 0, 0, 40)
                                frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)

                                local text = Instance.new("TextLabel")
                                text.Size = UDim2.new(0.7, 0, 1, 0)
                                text.BackgroundTransparency = 1
                                text.Text = listing.Name .. " - $" .. tostring(listing.Price)
                                text.TextColor3 = Color3.new(1,1,1)
                                text.TextXAlignment = Enum.TextXAlignment.Left
                                text.Parent = frame

                                local buyBtn = Instance.new("TextButton")
                                buyBtn.Size = UDim2.new(0.25, 0, 0.8, 0)
                                buyBtn.Position = UDim2.new(0.75, 0, 0.1, 0)
                                buyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                                buyBtn.Text = "BUY"
                                buyBtn.TextColor3 = Color3.new(1,1,1)
                                buyBtn.Parent = frame

                                buyBtn.MouseButton1Click:Connect(function()
                                    local ok, msg = marketReq:InvokeServer("PurchaseListing", listing.ListingId)
                                    print("Market Purchase: " .. tostring(msg))
                                    if ok then frame:Destroy() end
                                end)

                                frame.Parent = listFrame
                            end
                        end
                    end
                end)
            end
        end
    end
end

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

    -- Populate empty grid slots
    for i = 1, 40 do
        local slot = Instance.new("Frame")
        slot.Name = "Slot_" .. i
        slot.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        slot.BorderSizePixel = 1
        slot.BorderColor3 = Color3.fromRGB(50, 50, 50)
        slot.Parent = gridFrame
    end
end

-- Simulated function to add an item visually to the Tetris grid
-- A real game would use complex math to find intersecting free grid spaces based on GridWidth/GridHeight
function GUIManager.AddItemToGrid(itemName, gridWidth, gridHeight, color)
    if not inventoryScreen then return end
    local gridFrame = inventoryScreen:FindFirstChild("Frame")
    if not gridFrame then return end

    -- Find an empty slot
    for _, slot in ipairs(gridFrame:GetChildren()) do
        if slot:IsA("Frame") and #slot:GetChildren() == 0 then
            local itemGui = Instance.new("Frame")
            itemGui.Name = "Item_" .. itemName
            -- Size spans across multiple grid cells based on Tetris dimensions
            itemGui.Size = UDim2.new(gridWidth, (gridWidth-1)*2, gridHeight, (gridHeight-1)*2)
            itemGui.BackgroundColor3 = color or Color3.fromRGB(100, 150, 200)
            itemGui.ZIndex = 2

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = itemName
            label.TextScaled = true
            label.TextColor3 = Color3.new(1,1,1)
            label.ZIndex = 3
            label.Parent = itemGui

            itemGui.Parent = slot
            return true
        end
    end
    return false
end

function GUIManager.ToggleInventory(forceState)
    if not inventoryScreen then return end

    if forceState ~= nil then
        inventoryScreen.Visible = forceState
    else
        inventoryScreen.Visible = not inventoryScreen.Visible
    end

    -- Tell InputManager to freeze character jumping/shooting when menu is open
    if ClientState.SetMenuState then
        ClientState.SetMenuState(inventoryScreen.Visible)
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

-- Listen for Server Events
local function SetupNetworkListeners()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local events = replicatedStorage:WaitForChild("Events", 5)

    if events then
        local pickupEvent = events:WaitForChild("ItemPickedUp", 5)
        if pickupEvent then
            pickupEvent.OnClientEvent:Connect(function(itemData)
                local success = GUIManager.AddItemToGrid(itemData.Name, itemData.GridWidth, itemData.GridHeight, itemData.Color)
                if not success then
                    warn("Inventory Full! Could not fit " .. itemData.Name)
                end
            end)
        end

        local updateLimb = events:WaitForChild("UpdateLimbHUD", 5)
        if updateLimb then
            updateLimb.OnClientEvent:Connect(function(limbData)
                GUIManager.UpdateLimbHUD(limbData)
            end)
        end
    end
end
