-- GUIManager.client.lua
-- AAA-quality HUD: bilingual, animated, responsive, ZIndex-layered.
-- Layout: Bottom-left = vitals | Bottom-right = limb status
--         Top-right = minimap compass | Center-bottom = hotbar
--         Fullscreen panels: Inventory, Market, Map, Settings

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local LocalizationSystem = require(ReplicatedStorage:WaitForChild("LocalizationSystem"))
LocalizationSystem.Init()

-- ClientState optional (graceful fallback if module missing)
local ClientState = {}
local _csOk, _csMod = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Shared", 3):WaitForChild("ClientState", 3))
end)
if _csOk and _csMod then ClientState = _csMod end

local GUIManager = {}

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    BG_DARK       = Color3.fromRGB(12, 14, 18),
    BG_MID        = Color3.fromRGB(20, 23, 30),
    BG_PANEL      = Color3.fromRGB(16, 18, 24),
    BORDER        = Color3.fromRGB(55, 65, 85),
    ACCENT_GOLD   = Color3.fromRGB(220, 175, 50),
    ACCENT_CYAN   = Color3.fromRGB(0, 210, 255),
    ACCENT_RED    = Color3.fromRGB(220, 50, 50),
    ACCENT_GREEN  = Color3.fromRGB(50, 210, 100),
    ACCENT_BLUE   = Color3.fromRGB(60, 120, 240),
    TEXT_PRIMARY  = Color3.fromRGB(240, 240, 240),
    TEXT_DIM      = Color3.fromRGB(140, 150, 165),
    HP_FILL       = Color3.fromRGB(220, 55, 55),
    HP_BG         = Color3.fromRGB(45, 10, 10),
    MANA_FILL     = Color3.fromRGB(60, 120, 240),
    MANA_BG       = Color3.fromRGB(8, 15, 45),
    DANGER        = Color3.fromRGB(255, 60, 60),
    WARNING       = Color3.fromRGB(255, 180, 30),
}

-- ============================================================
-- HELPERS
-- ============================================================
local function AddCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent       = parent
    return c
end

local function AddStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or Theme.BORDER
    s.Thickness = thickness or 1
    s.Parent    = parent
    return s
end

local function AddPadding(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.PaddingLeft   = UDim.new(0, px)
    p.PaddingRight  = UDim.new(0, px)
    p.Parent        = parent
    return p
end

local function Label(parent, text, font, size, color, xAlign)
    local l = Instance.new("TextLabel")
    l.Size                  = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text                  = text or ""
    l.Font                  = font or Enum.Font.GothamBold
    l.TextSize              = size or 14
    l.TextColor3            = color or Theme.TEXT_PRIMARY
    l.TextXAlignment        = xAlign or Enum.TextXAlignment.Left
    l.TextYAlignment        = Enum.TextYAlignment.Center
    l.TextStrokeTransparency = 0.6
    l.TextStrokeColor3      = Color3.new(0, 0, 0)
    l.Parent                = parent
    return l
end

local function MakeCloseBtn(parent, callback)
    local btn = Instance.new("TextButton")
    btn.Name               = "CloseBtn"
    btn.Size               = UDim2.new(0, 32, 0, 32)
    btn.Position           = UDim2.new(1, -40, 0, 8)
    btn.BackgroundColor3   = Theme.ACCENT_RED
    btn.Text               = "✕"
    btn.TextColor3         = Theme.TEXT_PRIMARY
    btn.Font               = Enum.Font.GothamBold
    btn.TextSize           = 16
    btn.ZIndex             = 10
    btn.Parent             = parent
    AddCorner(btn, 8)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(255, 80, 80) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.ACCENT_RED }):Play()
    end)
    btn.MouseButton1Click:Connect(callback)

    return btn
end

local function SlideIn(frame, dir)
    -- dir: "up" | "down" | "left" | "right"
    local origPos = frame.Position
    local offsets = {
        up    = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale + 0.04, origPos.Y.Offset),
        down  = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale - 0.04, origPos.Y.Offset),
        left  = UDim2.new(origPos.X.Scale - 0.04, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset),
        right = UDim2.new(origPos.X.Scale + 0.04, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset),
    }
    frame.Position  = offsets[dir] or offsets["up"]
    frame.Visible   = true
    TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position    = origPos,
        BackgroundTransparency = frame:GetAttribute("TargetTransparency") or 0
    }):Play()
end

local function SlideOut(frame, dir, callback)
    local origPos = frame.Position
    local offsets = {
        up    = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale - 0.04, origPos.Y.Offset),
        down  = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale + 0.04, origPos.Y.Offset),
        left  = UDim2.new(origPos.X.Scale + 0.04, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset),
        right = UDim2.new(origPos.X.Scale - 0.04, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset),
    }
    local t = TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position            = offsets[dir] or offsets["down"],
        BackgroundTransparency = 1
    })
    t:Play()
    t.Completed:Connect(function()
        frame.Visible = false
        frame.Position = origPos
        frame.BackgroundTransparency = frame:GetAttribute("TargetTransparency") or 0
        if callback then callback() end
    end)
end

-- Animated bar fill with tween
local function TweenBarFill(fillFrame, targetScale)
    targetScale = math.clamp(targetScale, 0, 1)
    TweenService:Create(fillFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(targetScale, 0, 1, 0)
    }):Play()
end

-- ============================================================
-- PANEL REFERENCES
-- ============================================================
local screenGui       = nil
local inventoryPanel  = nil
local marketPanel     = nil
local mapPanel        = nil
local settingsPanel   = nil
local notifHolder     = nil
local vitalsFrame     = nil
local hpFill, mpFill  = nil, nil
local hpText, mpText  = nil, nil
local limbFrames      = {}

GUIManager.CachedMana    = 0
GUIManager.CachedMaxMana = 0

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local function SpawnNotif(text, color, duration)
    if not notifHolder then return end
    color    = color    or Theme.TEXT_PRIMARY
    duration = duration or 4

    local notif = Instance.new("Frame")
    notif.Size               = UDim2.new(1, 0, 0, 40)
    notif.BackgroundColor3   = Theme.BG_MID
    notif.BackgroundTransparency = 1
    notif.Parent             = notifHolder
    AddCorner(notif, 6)
    AddStroke(notif, color, 1)
    AddPadding(notif, 8)

    local lbl = Label(notif, text, Enum.Font.Gotham, 14, color, Enum.TextXAlignment.Center)
    lbl.TextWrapped = true

    TweenService:Create(notif, TweenInfo.new(0.2), { BackgroundTransparency = 0.15 }):Play()

    task.delay(duration, function()
        if notif and notif.Parent then
            TweenService:Create(notif, TweenInfo.new(0.3), { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }):Play()
            task.wait(0.35)
            if notif and notif.Parent then notif:Destroy() end
        end
    end)
end

GUIManager.Notify = SpawnNotif

-- ============================================================
-- INITIALIZE MAIN SCREEN GUI
-- ============================================================
function GUIManager.Initialize()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name           = "AbsoluteApexHUD"
    screenGui.ResetOnSpawn   = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent         = player:WaitForChild("PlayerGui")

    -- Build layers bottom → top
    GUIManager.BuildHotbar(screenGui)
    GUIManager.BuildVitalsHUD(screenGui)
    GUIManager.BuildLimbStatusHUD(screenGui)
    GUIManager.BuildCompassHUD(screenGui)
    GUIManager.BuildNotificationHolder(screenGui)
    GUIManager.BuildMobileToolbar(screenGui)

    -- Hidden panels (created but invisible)
    GUIManager.BuildInventoryPanel(screenGui)
    GUIManager.BuildMarketPanel(screenGui)
    GUIManager.BuildMapPanel(screenGui)
    GUIManager.BuildSettingsPanel(screenGui)

    -- Server event listeners
    GUIManager.SetupNetworkListeners()

    -- Keyboard shortcuts (desktop)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.I then
            GUIManager.ToggleInventory()
        elseif input.KeyCode == Enum.KeyCode.M then
            GUIManager.ToggleMap()
        elseif input.KeyCode == Enum.KeyCode.F then
            GUIManager.ToggleMarket()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            GUIManager.CloseAllPanels()
        end
    end)
end

-- ============================================================
-- VITALS HUD — bottom-left
-- ============================================================
function GUIManager.BuildVitalsHUD(parent)
    vitalsFrame = Instance.new("Frame")
    vitalsFrame.Name               = "VitalsHUD"
    vitalsFrame.Size               = UDim2.new(0, 280, 0, 80)
    vitalsFrame.Position           = UDim2.new(0, 16, 1, -110)
    vitalsFrame.BackgroundColor3   = Theme.BG_DARK
    vitalsFrame.BackgroundTransparency = 0.35
    vitalsFrame.ZIndex             = 2
    vitalsFrame.Parent             = parent
    AddCorner(vitalsFrame, 8)
    AddStroke(vitalsFrame, Theme.BORDER)
    AddPadding(vitalsFrame, 10)

    -- HP label
    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size                 = UDim2.new(0, 32, 0, 14)
    hpLabel.Position             = UDim2.new(0, 0, 0, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text                 = "HP"
    hpLabel.Font                 = Enum.Font.GothamBold
    hpLabel.TextSize             = 11
    hpLabel.TextColor3           = Theme.HP_FILL
    hpLabel.TextXAlignment       = Enum.TextXAlignment.Left
    hpLabel.Parent               = vitalsFrame

    -- HP bar background
    local hpBG = Instance.new("Frame")
    hpBG.Size             = UDim2.new(1, 0, 0, 22)
    hpBG.Position         = UDim2.new(0, 0, 0, 14)
    hpBG.BackgroundColor3 = Theme.HP_BG
    hpBG.Parent           = vitalsFrame
    AddCorner(hpBG, 4)

    hpFill = Instance.new("Frame")
    hpFill.Name           = "HPFill"
    hpFill.Size           = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Theme.HP_FILL
    hpFill.Parent         = hpBG
    AddCorner(hpFill, 4)

    hpText = Instance.new("TextLabel")
    hpText.Size               = UDim2.new(1, 0, 1, 0)
    hpText.BackgroundTransparency = 1
    hpText.Text               = "100 / 100"
    hpText.Font               = Enum.Font.GothamBold
    hpText.TextSize           = 12
    hpText.TextColor3         = Theme.TEXT_PRIMARY
    hpText.TextStrokeTransparency = 0.5
    hpText.ZIndex             = 3
    hpText.Parent             = hpBG

    -- MP label
    local mpLabel = Instance.new("TextLabel")
    mpLabel.Size                 = UDim2.new(0, 50, 0, 12)
    mpLabel.Position             = UDim2.new(0, 0, 0, 40)
    mpLabel.BackgroundTransparency = 1
    mpLabel.Text                 = "MANA"
    mpLabel.Font                 = Enum.Font.GothamBold
    mpLabel.TextSize             = 10
    mpLabel.TextColor3           = Theme.MANA_FILL
    mpLabel.TextXAlignment       = Enum.TextXAlignment.Left
    mpLabel.Parent               = vitalsFrame

    -- MP bar background
    local mpBG = Instance.new("Frame")
    mpBG.Size             = UDim2.new(1, 0, 0, 14)
    mpBG.Position         = UDim2.new(0, 0, 0, 53)
    mpBG.BackgroundColor3 = Theme.MANA_BG
    mpBG.Parent           = vitalsFrame
    AddCorner(mpBG, 3)

    mpFill = Instance.new("Frame")
    mpFill.Name           = "MPFill"
    mpFill.Size           = UDim2.new(0, 0, 1, 0)
    mpFill.BackgroundColor3 = Theme.MANA_FILL
    mpFill.Parent         = mpBG
    AddCorner(mpFill, 3)

    mpText = Instance.new("TextLabel")
    mpText.Size               = UDim2.new(1, 0, 1, 0)
    mpText.BackgroundTransparency = 1
    mpText.Text               = LocalizationSystem.Get("HUD_NO_MANA")
    mpText.Font               = Enum.Font.Gotham
    mpText.TextSize           = 9
    mpText.TextColor3         = Theme.TEXT_DIM
    mpText.TextStrokeTransparency = 0.6
    mpText.ZIndex             = 3
    mpText.Parent             = mpBG

    -- Wire up to humanoid
    local function hookHumanoid()
        local char = player.Character or player.CharacterAdded:Wait()
        local hum  = char:WaitForChild("Humanoid")
        local function update()
            local hp    = hum.Health
            local maxHp = math.max(hum.MaxHealth, 1)
            hpText.Text = math.floor(hp) .. " / " .. math.floor(maxHp)
            TweenBarFill(hpFill, hp / maxHp)

            -- Color shift: green→yellow→red
            local ratio = hp / maxHp
            if ratio > 0.5 then
                hpFill.BackgroundColor3 = Theme.HP_FILL
            elseif ratio > 0.25 then
                hpFill.BackgroundColor3 = Theme.WARNING
            else
                hpFill.BackgroundColor3 = Theme.DANGER
            end
        end
        hum.HealthChanged:Connect(update)
        update()
    end

    task.spawn(hookHumanoid)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        hookHumanoid()
    end)
end

-- ============================================================
-- LIMB STATUS HUD — bottom-right
-- ============================================================
function GUIManager.BuildLimbStatusHUD(parent)
    local panel = Instance.new("Frame")
    panel.Name               = "LimbHUD"
    panel.Size               = UDim2.new(0, 155, 0, 180)
    panel.Position           = UDim2.new(1, -172, 1, -200)
    panel.BackgroundColor3   = Theme.BG_DARK
    panel.BackgroundTransparency = 0.4
    panel.ZIndex             = 2
    panel.Parent             = parent
    AddCorner(panel, 8)
    AddStroke(panel, Theme.BORDER)

    local title = Instance.new("TextLabel")
    title.Size                 = UDim2.new(1, -8, 0, 22)
    title.Position             = UDim2.new(0, 8, 0, 6)
    title.BackgroundTransparency = 1
    title.Text                 = "LIMB STATUS"
    title.Font                 = Enum.Font.GothamBold
    title.TextSize             = 11
    title.TextColor3           = Theme.ACCENT_GOLD
    title.TextXAlignment       = Enum.TextXAlignment.Left
    title.Parent               = panel

    local limbNames = {"Head", "Chest", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
    local limbColors = {
        Healthy   = Theme.ACCENT_GREEN,
        Injured   = Theme.WARNING,
        Destroyed = Theme.DANGER,
    }

    for i, limb in ipairs(limbNames) do
        local row = Instance.new("Frame")
        row.Size               = UDim2.new(1, -12, 0, 22)
        row.Position           = UDim2.new(0, 6, 0, 24 + (i - 1) * 25)
        row.BackgroundColor3   = Theme.BG_MID
        row.BackgroundTransparency = 0.5
        row.Parent             = panel
        AddCorner(row, 4)

        local limbLabel = Instance.new("TextLabel")
        limbLabel.Size                 = UDim2.new(0.6, 0, 1, 0)
        limbLabel.BackgroundTransparency = 1
        limbLabel.Text                 = limb:upper()
        limbLabel.Font                 = Enum.Font.Gotham
        limbLabel.TextSize             = 10
        limbLabel.TextColor3           = Theme.TEXT_DIM
        limbLabel.TextXAlignment       = Enum.TextXAlignment.Left
        limbLabel.Position             = UDim2.new(0, 6, 0, 0)
        limbLabel.Parent               = row

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name               = "Status_" .. limb
        statusLabel.Size               = UDim2.new(0.4, -4, 1, 0)
        statusLabel.Position           = UDim2.new(0.6, 0, 0, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text               = "OK"
        statusLabel.Font               = Enum.Font.GothamBold
        statusLabel.TextSize           = 10
        statusLabel.TextColor3         = Theme.ACCENT_GREEN
        statusLabel.TextXAlignment     = Enum.TextXAlignment.Right
        statusLabel.Parent             = row

        limbFrames[limb] = statusLabel
    end
end

-- ============================================================
-- COMPASS / BIOME INDICATOR — top-right
-- ============================================================
function GUIManager.BuildCompassHUD(parent)
    local compass = Instance.new("Frame")
    compass.Name               = "CompassHUD"
    compass.Size               = UDim2.new(0, 200, 0, 42)
    compass.Position           = UDim2.new(1, -216, 0, 16)
    compass.BackgroundColor3   = Theme.BG_DARK
    compass.BackgroundTransparency = 0.4
    compass.ZIndex             = 2
    compass.Parent             = parent
    AddCorner(compass, 8)
    AddStroke(compass, Theme.BORDER)

    local dirLabel = Instance.new("TextLabel")
    dirLabel.Name              = "DirectionLabel"
    dirLabel.Size              = UDim2.new(0, 50, 1, 0)
    dirLabel.BackgroundTransparency = 1
    dirLabel.Text              = "N"
    dirLabel.Font              = Enum.Font.GothamBold
    dirLabel.TextSize          = 22
    dirLabel.TextColor3        = Theme.ACCENT_GOLD
    dirLabel.TextXAlignment    = Enum.TextXAlignment.Center
    dirLabel.Parent            = compass

    local biomeLabel = Instance.new("TextLabel")
    biomeLabel.Name            = "BiomeLabel"
    biomeLabel.Size            = UDim2.new(1, -55, 1, 0)
    biomeLabel.Position        = UDim2.new(0, 55, 0, 0)
    biomeLabel.BackgroundTransparency = 1
    biomeLabel.Text            = "Kalimantan"
    biomeLabel.Font            = Enum.Font.Gotham
    biomeLabel.TextSize        = 12
    biomeLabel.TextColor3      = Theme.TEXT_DIM
    biomeLabel.TextXAlignment  = Enum.TextXAlignment.Left
    biomeLabel.TextYAlignment  = Enum.TextYAlignment.Center
    biomeLabel.Parent          = compass

    -- Update compass direction each heartbeat
    RunService.Heartbeat:Connect(function()
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local lookDir = root.CFrame.LookVector
        local angle   = math.atan2(lookDir.X, lookDir.Z)
        local deg     = math.deg(angle)
        if deg < 0 then deg = deg + 360 end

        local dirs = {"N","NE","E","SE","S","SW","W","NW","N"}
        local idx  = math.floor((deg + 22.5) / 45) + 1
        dirLabel.Text = dirs[idx]

        -- Biome detection by Y position
        local y = root.Position.Y
        if y > 800 then
            biomeLabel.Text = LocalizationSystem.Get("BIOME_LOBBY")
        else
            biomeLabel.Text = LocalizationSystem.Get("BIOME_TROPICAL")
        end
    end)
end

-- ============================================================
-- HOTBAR — bottom-center
-- ============================================================
function GUIManager.BuildHotbar(parent)
    local SLOTS = 6
    local holder = Instance.new("Frame")
    holder.Name               = "Hotbar"
    holder.Size               = UDim2.new(0, SLOTS * 64 + (SLOTS - 1) * 4, 0, 64)
    holder.Position           = UDim2.new(0.5, -(SLOTS * 64 + (SLOTS - 1) * 4) / 2, 1, -80)
    holder.BackgroundTransparency = 1
    holder.ZIndex             = 2
    holder.Parent             = parent

    for i = 1, SLOTS do
        local slot = Instance.new("Frame")
        slot.Name             = "HotbarSlot_" .. i
        slot.Size             = UDim2.new(0, 62, 0, 62)
        slot.Position         = UDim2.new(0, (i - 1) * 66, 0, 0)
        slot.BackgroundColor3 = Theme.BG_DARK
        slot.BackgroundTransparency = 0.3
        slot.Parent           = holder
        AddCorner(slot, 8)
        AddStroke(slot, Theme.BORDER)

        local numLabel = Instance.new("TextLabel")
        numLabel.Size                 = UDim2.new(0, 16, 0, 16)
        numLabel.Position             = UDim2.new(0, 4, 0, 2)
        numLabel.BackgroundTransparency = 1
        numLabel.Text                 = tostring(i)
        numLabel.Font                 = Enum.Font.GothamBold
        numLabel.TextSize             = 11
        numLabel.TextColor3           = Theme.TEXT_DIM
        numLabel.Parent               = slot
    end
end

-- ============================================================
-- NOTIFICATION HOLDER — top-center
-- ============================================================
function GUIManager.BuildNotificationHolder(parent)
    notifHolder = Instance.new("Frame")
    notifHolder.Name               = "NotifHolder"
    notifHolder.Size               = UDim2.new(0, 360, 1, -20)
    notifHolder.Position           = UDim2.new(0.5, -180, 0, 10)
    notifHolder.BackgroundTransparency = 1
    notifHolder.ZIndex             = 20
    notifHolder.Parent             = parent

    local layout = Instance.new("UIListLayout")
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding           = UDim.new(0, 6)
    layout.SortOrder         = Enum.SortOrder.LayoutOrder
    layout.Parent            = notifHolder
end

-- ============================================================
-- MOBILE TOOLBAR — right side, scale-relative
-- ============================================================
function GUIManager.BuildMobileToolbar(parent)
    if not UserInputService.TouchEnabled then return end

    local toolbar = Instance.new("Frame")
    toolbar.Name               = "MobileToolbar"
    toolbar.Size               = UDim2.new(0, 72, 0, 320)
    toolbar.Position           = UDim2.new(0, 12, 0.5, -160)
    toolbar.BackgroundTransparency = 1
    toolbar.ZIndex             = 5
    toolbar.Parent             = parent

    local layout = Instance.new("UIListLayout")
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding           = UDim.new(0, 8)
    layout.Parent            = toolbar

    local btns = {
        { text = LocalizationSystem.Get("MOBILE_BAG"),    color = Theme.ACCENT_CYAN,  action = function() GUIManager.ToggleInventory() end },
        { text = LocalizationSystem.Get("MOBILE_MARKET"), color = Theme.ACCENT_GOLD,  action = function() GUIManager.ToggleMarket()    end },
        { text = LocalizationSystem.Get("MOBILE_MAP"),    color = Theme.ACCENT_BLUE,  action = function() GUIManager.ToggleMap()       end },
        { text = LocalizationSystem.Get("MOBILE_SET"),    color = Theme.TEXT_DIM,     action = function() GUIManager.ToggleSettings()  end },
    }

    for _, def in ipairs(btns) do
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0, 68, 0, 68)
        btn.BackgroundColor3 = Theme.BG_MID
        btn.TextColor3       = def.color
        btn.Text             = def.text
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 12
        btn.AutoButtonColor  = false
        btn.Parent           = toolbar
        AddCorner(btn, 12)
        AddStroke(btn, def.color, 2)

        btn.MouseButton1Click:Connect(def.action)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = def.color }):Play()
            TweenService:Create(btn, TweenInfo.new(0.1), { TextColor3 = Theme.BG_DARK }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.BG_MID }):Play()
            TweenService:Create(btn, TweenInfo.new(0.1), { TextColor3 = def.color }):Play()
        end)
    end
end

-- ============================================================
-- PANEL BUILDER HELPER
-- ============================================================
local function MakePanel(name, size, pos, targetAlpha)
    local panel = Instance.new("Frame")
    panel.Name               = name
    panel.Size               = size
    panel.Position           = pos
    panel.BackgroundColor3   = Theme.BG_PANEL
    panel.BackgroundTransparency = targetAlpha or 0.06
    panel.Visible            = false
    panel.ZIndex             = 8
    panel:SetAttribute("TargetTransparency", targetAlpha or 0.06)
    return panel
end

local function MakePanelHeader(panel, titleText, iconText)
    -- Header bar
    local header = Instance.new("Frame")
    header.Name             = "Header"
    header.Size             = UDim2.new(1, 0, 0, 52)
    header.BackgroundColor3 = Theme.BG_DARK
    header.BackgroundTransparency = 0.0
    header.ZIndex           = 9
    header.Parent           = panel
    AddCorner(header, 0)

    local topBar = Instance.new("Frame")
    topBar.Size             = UDim2.new(1, 0, 0, 3)
    topBar.BackgroundColor3 = Theme.ACCENT_GOLD
    topBar.ZIndex           = 10
    topBar.Parent           = header

    local icon = Instance.new("TextLabel")
    icon.Size                 = UDim2.new(0, 40, 1, 0)
    icon.Position             = UDim2.new(0, 16, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text                 = iconText or "◈"
    icon.Font                 = Enum.Font.GothamBold
    icon.TextSize             = 22
    icon.TextColor3           = Theme.ACCENT_GOLD
    icon.ZIndex               = 10
    icon.Parent               = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name              = "TitleLabel"
    titleLabel.Size              = UDim2.new(1, -110, 1, 0)
    titleLabel.Position          = UDim2.new(0, 60, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text              = titleText or ""
    titleLabel.Font              = Enum.Font.GothamBold
    titleLabel.TextSize          = 18
    titleLabel.TextColor3        = Theme.TEXT_PRIMARY
    titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    titleLabel.ZIndex            = 10
    titleLabel.Parent            = header

    return header
end

-- ============================================================
-- INVENTORY PANEL
-- ============================================================
function GUIManager.BuildInventoryPanel(parent)
    inventoryPanel = MakePanel("InventoryPanel",
        UDim2.new(0.62, 0, 0.78, 0),
        UDim2.new(0.5, 0, 0.5, 0)
    )
    inventoryPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    inventoryPanel.Parent = parent
    AddCorner(inventoryPanel, 10)
    AddStroke(inventoryPanel, Theme.BORDER, 1)

    local header = MakePanelHeader(inventoryPanel, LocalizationSystem.Get("INV_TITLE"), "[BAG]")
    MakeCloseBtn(header, function() GUIManager.ToggleInventory(false) end)

    -- Two-column layout
    local leftCol = Instance.new("Frame")
    leftCol.Name             = "GridArea"
    leftCol.Size             = UDim2.new(0.58, -6, 1, -58)
    leftCol.Position         = UDim2.new(0, 8, 0, 56)
    leftCol.BackgroundColor3 = Theme.BG_DARK
    leftCol.BackgroundTransparency = 0.2
    leftCol.Parent           = inventoryPanel
    AddCorner(leftCol, 6)

    -- Tetris-style grid (10 × 7 = 70 slots)
    local gridFrame = Instance.new("Frame")
    gridFrame.Name   = "Grid"
    gridFrame.Size   = UDim2.new(1, -12, 1, -12)
    gridFrame.Position = UDim2.new(0, 6, 0, 6)
    gridFrame.BackgroundTransparency = 1
    gridFrame.Parent = leftCol

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize    = UDim2.new(0, 52, 0, 52)
    gridLayout.CellPadding = UDim2.new(0, 3, 0, 3)
    gridLayout.Parent      = gridFrame

    for i = 1, 70 do
        local slot = Instance.new("Frame")
        slot.Name             = "GSlot_" .. i
        slot.BackgroundColor3 = Theme.BG_MID
        slot.BackgroundTransparency = 0.3
        slot.Parent           = gridFrame
        AddCorner(slot, 4)
        AddStroke(slot, Color3.fromRGB(35, 40, 55), 1)
    end

    -- Right column: gear slots + weight
    local rightCol = Instance.new("Frame")
    rightCol.Name             = "GearArea"
    rightCol.Size             = UDim2.new(0.42, -14, 1, -58)
    rightCol.Position         = UDim2.new(0.58, 6, 0, 56)
    rightCol.BackgroundColor3 = Theme.BG_DARK
    rightCol.BackgroundTransparency = 0.2
    rightCol.Parent           = inventoryPanel
    AddCorner(rightCol, 6)
    AddPadding(rightCol, 10)

    local gearTitle = Instance.new("TextLabel")
    gearTitle.Size               = UDim2.new(1, 0, 0, 22)
    gearTitle.BackgroundTransparency = 1
    gearTitle.Text               = "EQUIPPED GEAR"
    gearTitle.Font               = Enum.Font.GothamBold
    gearTitle.TextSize           = 13
    gearTitle.TextColor3         = Theme.ACCENT_GOLD
    gearTitle.TextXAlignment     = Enum.TextXAlignment.Left
    gearTitle.Parent             = rightCol

    local gearSlotDefs = {
        {"Head",     "HEAD",  UDim2.new(0.5, -34, 0, 32)},
        {"Chest",    "CHEST", UDim2.new(0.5, -34, 0, 100)},
        {"Backpack", "BAG",   UDim2.new(0.5, -34, 0, 168)},
        {"PrimWeap", "PRI",   UDim2.new(0, 8,    0, 240)},
        {"SecWeap",  "SEC",   UDim2.new(1, -76, 0, 240)},
    }

    for _, def in ipairs(gearSlotDefs) do
        local gs = Instance.new("Frame")
        gs.Name             = "GearSlot_" .. def[1]
        gs.Size             = UDim2.new(0, 64, 0, 64)
        gs.Position         = def[3]
        gs.BackgroundColor3 = Theme.BG_MID
        gs.BackgroundTransparency = 0.3
        gs.Parent           = rightCol
        AddCorner(gs, 8)
        AddStroke(gs, Theme.BORDER, 1)

        local slotIcon = Instance.new("TextLabel")
        slotIcon.Size               = UDim2.new(1, 0, 0.5, 0)
        slotIcon.BackgroundTransparency = 1
        slotIcon.Text               = def[2]
        slotIcon.Font               = Enum.Font.GothamBold
        slotIcon.TextSize           = 22
        slotIcon.TextXAlignment     = Enum.TextXAlignment.Center
        slotIcon.Parent             = gs

        local slotName = Instance.new("TextLabel")
        slotName.Size               = UDim2.new(1, 0, 0.4, 0)
        slotName.Position           = UDim2.new(0, 0, 0.58, 0)
        slotName.BackgroundTransparency = 1
        slotName.Text               = def[1]:upper()
        slotName.Font               = Enum.Font.Gotham
        slotName.TextSize           = 10
        slotName.TextColor3         = Theme.TEXT_DIM
        slotName.TextXAlignment     = Enum.TextXAlignment.Center
        slotName.Parent             = gs
    end

    -- Weight bar
    local weightLabel = Instance.new("TextLabel")
    weightLabel.Name               = "WeightLabel"
    weightLabel.Size               = UDim2.new(1, 0, 0, 18)
    weightLabel.Position           = UDim2.new(0, 0, 1, -46)
    weightLabel.BackgroundTransparency = 1
    weightLabel.Text               = "Weight: 0 / 70 kg"
    weightLabel.Font               = Enum.Font.Gotham
    weightLabel.TextSize           = 12
    weightLabel.TextColor3         = Theme.TEXT_DIM
    weightLabel.TextXAlignment     = Enum.TextXAlignment.Left
    weightLabel.Parent             = rightCol

    local wBG = Instance.new("Frame")
    wBG.Name             = "WeightBG"
    wBG.Size             = UDim2.new(1, 0, 0, 10)
    wBG.Position         = UDim2.new(0, 0, 1, -28)
    wBG.BackgroundColor3 = Theme.BG_MID
    wBG.Parent           = rightCol
    AddCorner(wBG, 4)

    local wFill = Instance.new("Frame")
    wFill.Name           = "WeightFill"
    wFill.Size           = UDim2.new(0, 0, 1, 0)
    wFill.BackgroundColor3 = Theme.ACCENT_GOLD
    wFill.Parent         = wBG
    AddCorner(wFill, 4)
end

-- ============================================================
-- MARKET PANEL
-- ============================================================
function GUIManager.BuildMarketPanel(parent)
    marketPanel = MakePanel("MarketPanel",
        UDim2.new(0.78, 0, 0.85, 0),
        UDim2.new(0.5, 0, 0.5, 0)
    )
    marketPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    marketPanel.Parent = parent
    AddCorner(marketPanel, 10)
    AddStroke(marketPanel, Theme.BORDER)

    local header = MakePanelHeader(marketPanel, LocalizationSystem.Get("MARKET_TITLE"), "[MKT]")
    MakeCloseBtn(header, function() GUIManager.ToggleMarket(false) end)

    -- Category tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name             = "TabBar"
    tabBar.Size             = UDim2.new(1, -16, 0, 36)
    tabBar.Position         = UDim2.new(0, 8, 0, 58)
    tabBar.BackgroundColor3 = Theme.BG_DARK
    tabBar.BackgroundTransparency = 0.2
    tabBar.Parent           = marketPanel
    AddCorner(tabBar, 6)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection      = Enum.FillDirection.Horizontal
    tabLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
    tabLayout.Padding            = UDim.new(0, 4)
    tabLayout.SortOrder          = Enum.SortOrder.LayoutOrder
    tabLayout.Parent             = tabBar
    AddPadding(tabBar, 4)

    local categories = LocalizationSystem.Get("MARKET_CATEGORIES")
    for i, cat in ipairs(categories) do
        local tab = Instance.new("TextButton")
        tab.Name             = "Tab_" .. i
        tab.Size             = UDim2.new(0, 100, 1, 0)
        tab.BackgroundColor3 = i == 1 and Theme.ACCENT_GOLD or Theme.BG_MID
        tab.TextColor3       = i == 1 and Theme.BG_DARK     or Theme.TEXT_DIM
        tab.Text             = cat
        tab.Font             = Enum.Font.GothamBold
        tab.TextSize         = 12
        tab.AutoButtonColor  = false
        tab.Parent           = tabBar
        AddCorner(tab, 5)
    end

    -- Search row
    local searchRow = Instance.new("Frame")
    searchRow.Size             = UDim2.new(1, -16, 0, 34)
    searchRow.Position         = UDim2.new(0, 8, 0, 100)
    searchRow.BackgroundColor3 = Theme.BG_DARK
    searchRow.BackgroundTransparency = 0.2
    searchRow.Parent           = marketPanel
    AddCorner(searchRow, 6)
    AddPadding(searchRow, 5)

    local searchBox = Instance.new("TextBox")
    searchBox.Name           = "SearchBox"
    searchBox.Size           = UDim2.new(1, 0, 1, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = LocalizationSystem.Get("MARKET_SEARCH")
    searchBox.Text           = ""
    searchBox.Font           = Enum.Font.Gotham
    searchBox.TextSize       = 14
    searchBox.TextColor3     = Theme.TEXT_PRIMARY
    searchBox.PlaceholderColor3 = Theme.TEXT_DIM
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent         = searchRow

    -- Listings area
    local listings = Instance.new("ScrollingFrame")
    listings.Name             = "Listings"
    listings.Size             = UDim2.new(1, -16, 1, -146)
    listings.Position         = UDim2.new(0, 8, 0, 140)
    listings.BackgroundColor3 = Theme.BG_DARK
    listings.BackgroundTransparency = 0.3
    listings.ScrollBarThickness = 5
    listings.ScrollBarImageColor3 = Theme.ACCENT_GOLD
    listings.BorderSizePixel  = 0
    listings.Parent           = marketPanel
    AddCorner(listings, 6)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding   = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent    = listings
    AddPadding(listings, 6)
end

-- ============================================================
-- MAP PANEL
-- ============================================================
function GUIManager.BuildMapPanel(parent)
    mapPanel = MakePanel("MapPanel",
        UDim2.new(0.75, 0, 0.84, 0),
        UDim2.new(0.5, 0, 0.5, 0)
    )
    mapPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    mapPanel.Parent = parent
    AddCorner(mapPanel, 10)
    AddStroke(mapPanel, Theme.BORDER)

    local header = MakePanelHeader(mapPanel, LocalizationSystem.Get("MAP_TITLE_KALIMANTAN"), "[MAP]")
    header:FindFirstChild("TitleLabel").Name = "MapTitleLabel"
    MakeCloseBtn(header, function() GUIManager.ToggleMap(false) end)

    -- Map visual area
    local mapArea = Instance.new("Frame")
    mapArea.Name             = "MapArea"
    mapArea.Size             = UDim2.new(0.7, -8, 1, -62)
    mapArea.Position         = UDim2.new(0, 8, 0, 58)
    mapArea.BackgroundColor3 = Color3.fromRGB(8, 14, 10)
    mapArea.Parent           = mapPanel
    AddCorner(mapArea, 8)
    AddStroke(mapArea, Color3.fromRGB(30, 60, 30))

    -- Grid lines overlay
    for i = 1, 9 do
        local hLine = Instance.new("Frame")
        hLine.Size             = UDim2.new(1, 0, 0, 1)
        hLine.Position         = UDim2.new(0, 0, i / 10, 0)
        hLine.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
        hLine.BorderSizePixel  = 0
        hLine.Parent           = mapArea

        local vLine = Instance.new("Frame")
        vLine.Size             = UDim2.new(0, 1, 1, 0)
        vLine.Position         = UDim2.new(i / 10, 0, 0, 0)
        vLine.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
        vLine.BorderSizePixel  = 0
        vLine.Parent           = mapArea
    end

    -- Extraction zone marker
    local extractMarker = Instance.new("Frame")
    extractMarker.Name           = "ExtractMarker"
    extractMarker.Size           = UDim2.new(0, 18, 0, 18)
    extractMarker.Position       = UDim2.new(0.5, -9, 0.5, -9)
    extractMarker.BackgroundColor3 = Theme.ACCENT_GREEN
    extractMarker.Parent         = mapArea
    AddCorner(extractMarker, 9)

    local extractPulse = Instance.new("UIStroke")
    extractPulse.Color     = Theme.ACCENT_GREEN
    extractPulse.Thickness = 2
    extractPulse.Parent    = extractMarker

    -- Animate the pulse
    task.spawn(function()
        while extractMarker.Parent do
            TweenService:Create(extractPulse, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Thickness = 6}):Play()
            task.wait(2)
        end
    end)

    local extractLabel = Instance.new("TextLabel")
    extractLabel.Size               = UDim2.new(0, 90, 0, 18)
    extractLabel.Position           = UDim2.new(0, 22, 0, 0)
    extractLabel.BackgroundTransparency = 1
    extractLabel.Text               = "EXTRACT"
    extractLabel.Font               = Enum.Font.GothamBold
    extractLabel.TextSize           = 10
    extractLabel.TextColor3         = Theme.ACCENT_GREEN
    extractLabel.Parent             = extractMarker

    -- Player position dot
    local playerDot = Instance.new("Frame")
    playerDot.Name           = "PlayerDot"
    playerDot.Size           = UDim2.new(0, 12, 0, 12)
    playerDot.AnchorPoint    = Vector2.new(0.5, 0.5)
    playerDot.Position       = UDim2.new(0.5, 0, 0.5, 0)
    playerDot.BackgroundColor3 = Theme.ACCENT_CYAN
    playerDot.Parent         = mapArea
    AddCorner(playerDot, 6)

    -- Right sidebar: POI list + status
    local sidebar = Instance.new("Frame")
    sidebar.Name             = "Sidebar"
    sidebar.Size             = UDim2.new(0.3, -8, 1, -62)
    sidebar.Position         = UDim2.new(0.7, 0, 0, 58)
    sidebar.BackgroundColor3 = Theme.BG_DARK
    sidebar.BackgroundTransparency = 0.15
    sidebar.Parent           = mapPanel
    AddCorner(sidebar, 8)
    AddPadding(sidebar, 10)

    local sideTitle = Instance.new("TextLabel")
    sideTitle.Size               = UDim2.new(1, 0, 0, 22)
    sideTitle.BackgroundTransparency = 1
    sideTitle.Text               = "POINTS OF INTEREST"
    sideTitle.Font               = Enum.Font.GothamBold
    sideTitle.TextSize           = 11
    sideTitle.TextColor3         = Theme.ACCENT_GOLD
    sideTitle.TextXAlignment     = Enum.TextXAlignment.Left
    sideTitle.Parent             = sidebar

    local pois = {
        {"⚔", LocalizationSystem.Get("MAP_POI_QM")},
        {"✨", LocalizationSystem.Get("MAP_POI_APATH")},
        {"🌀", LocalizationSystem.Get("MAP_POI_PORTAL")},
        {"📦", LocalizationSystem.Get("MAP_POI_STASH")},
    }

    for i, poi in ipairs(pois) do
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 42)
        row.Position         = UDim2.new(0, 0, 0, 28 + (i-1) * 46)
        row.BackgroundColor3 = Theme.BG_MID
        row.BackgroundTransparency = 0.5
        row.Parent           = sidebar
        AddCorner(row, 5)
        AddPadding(row, 5)

        local iconL = Instance.new("TextLabel")
        iconL.Size               = UDim2.new(0, 22, 1, 0)
        iconL.BackgroundTransparency = 1
        iconL.Text               = poi[1]
        iconL.Font               = Enum.Font.GothamBold
        iconL.TextSize           = 16
        iconL.TextXAlignment     = Enum.TextXAlignment.Center
        iconL.Parent             = row

        local textL = Instance.new("TextLabel")
        textL.Size               = UDim2.new(1, -28, 1, 0)
        textL.Position           = UDim2.new(0, 26, 0, 0)
        textL.BackgroundTransparency = 1
        textL.Text               = poi[2]
        textL.Font               = Enum.Font.Gotham
        textL.TextSize           = 10
        textL.TextColor3         = Theme.TEXT_DIM
        textL.TextWrapped        = true
        textL.TextXAlignment     = Enum.TextXAlignment.Left
        textL.TextYAlignment     = Enum.TextYAlignment.Center
        textL.Parent             = row
    end

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name              = "StatusLabel"
    statusLabel.Size              = UDim2.new(1, 0, 0, 40)
    statusLabel.Position          = UDim2.new(0, 0, 1, -45)
    statusLabel.BackgroundColor3  = Theme.BG_MID
    statusLabel.BackgroundTransparency = 0.4
    statusLabel.Text              = "HP: — | ZONE: —"
    statusLabel.Font              = Enum.Font.Gotham
    statusLabel.TextSize          = 11
    statusLabel.TextColor3        = Theme.TEXT_DIM
    statusLabel.TextWrapped       = true
    statusLabel.TextXAlignment    = Enum.TextXAlignment.Center
    statusLabel.TextYAlignment    = Enum.TextYAlignment.Center
    statusLabel.Parent            = sidebar
    AddCorner(statusLabel, 5)
end

-- ============================================================
-- SETTINGS PANEL
-- ============================================================
function GUIManager.BuildSettingsPanel(parent)
    settingsPanel = MakePanel("SettingsPanel",
        UDim2.new(0, 400, 0, 480),
        UDim2.new(0.5, 0, 0.5, 0)
    )
    settingsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    settingsPanel.Parent = parent
    AddCorner(settingsPanel, 10)
    AddStroke(settingsPanel, Theme.BORDER)

    local header = MakePanelHeader(settingsPanel, LocalizationSystem.Get("MENU_SETTINGS"), "[SET]")
    MakeCloseBtn(header, function() GUIManager.ToggleSettings(false) end)
    AddPadding(settingsPanel, 14)

    local settingDefs = {
        { label = "Master Volume",   default = 100, min = 0, max = 100 },
        { label = "Music Volume",    default = 45,  min = 0, max = 100 },
        { label = "SFX Volume",      default = 80,  min = 0, max = 100 },
        { label = "Voice Volume",    default = 90,  min = 0, max = 100 },
    }

    for i, def in ipairs(settingDefs) do
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, -28, 0, 52)
        row.Position         = UDim2.new(0, 14, 0, 56 + (i-1) * 60)
        row.BackgroundColor3 = Theme.BG_MID
        row.BackgroundTransparency = 0.5
        row.Parent           = settingsPanel
        AddCorner(row, 6)
        AddPadding(row, 8)

        local rowLabel = Instance.new("TextLabel")
        rowLabel.Size               = UDim2.new(0.55, 0, 1, 0)
        rowLabel.BackgroundTransparency = 1
        rowLabel.Text               = def.label
        rowLabel.Font               = Enum.Font.Gotham
        rowLabel.TextSize           = 13
        rowLabel.TextColor3         = Theme.TEXT_PRIMARY
        rowLabel.TextXAlignment     = Enum.TextXAlignment.Left
        rowLabel.Parent             = row

        local valLabel = Instance.new("TextLabel")
        valLabel.Size               = UDim2.new(0, 36, 1, 0)
        valLabel.Position           = UDim2.new(1, -40, 0, 0)
        valLabel.BackgroundTransparency = 1
        valLabel.Text               = tostring(def.default)
        valLabel.Font               = Enum.Font.GothamBold
        valLabel.TextSize           = 13
        valLabel.TextColor3         = Theme.ACCENT_GOLD
        valLabel.TextXAlignment     = Enum.TextXAlignment.Right
        valLabel.Parent             = row
    end

    -- Language switcher
    local langRow = Instance.new("Frame")
    langRow.Size             = UDim2.new(1, -28, 0, 52)
    langRow.Position         = UDim2.new(0, 14, 0, 300)
    langRow.BackgroundColor3 = Theme.BG_MID
    langRow.BackgroundTransparency = 0.5
    langRow.Parent           = settingsPanel
    AddCorner(langRow, 6)
    AddPadding(langRow, 8)

    local langLabel = Instance.new("TextLabel")
    langLabel.Size               = UDim2.new(0.5, 0, 1, 0)
    langLabel.BackgroundTransparency = 1
    langLabel.Text               = "Language"
    langLabel.Font               = Enum.Font.Gotham
    langLabel.TextSize           = 13
    langLabel.TextColor3         = Theme.TEXT_PRIMARY
    langLabel.TextXAlignment     = Enum.TextXAlignment.Left
    langLabel.Parent             = langRow

    local enBtn = Instance.new("TextButton")
    enBtn.Size             = UDim2.new(0, 70, 0, 32)
    enBtn.Position         = UDim2.new(0.52, 0, 0.5, -16)
    enBtn.BackgroundColor3 = LocalizationSystem.GetLanguage() == "EN" and Theme.ACCENT_GOLD or Theme.BG_DARK
    enBtn.TextColor3       = LocalizationSystem.GetLanguage() == "EN" and Theme.BG_DARK     or Theme.TEXT_DIM
    enBtn.Text             = "🇬🇧 EN"
    enBtn.Font             = Enum.Font.GothamBold
    enBtn.TextSize         = 13
    enBtn.Parent           = langRow
    AddCorner(enBtn, 6)

    local idBtn = Instance.new("TextButton")
    idBtn.Size             = UDim2.new(0, 70, 0, 32)
    idBtn.Position         = UDim2.new(0.52, 78, 0.5, -16)
    idBtn.BackgroundColor3 = LocalizationSystem.GetLanguage() == "ID" and Theme.ACCENT_GOLD or Theme.BG_DARK
    idBtn.TextColor3       = LocalizationSystem.GetLanguage() == "ID" and Theme.BG_DARK     or Theme.TEXT_DIM
    idBtn.Text             = "🇮🇩 ID"
    idBtn.Font             = Enum.Font.GothamBold
    idBtn.TextSize         = 13
    idBtn.Parent           = langRow
    AddCorner(idBtn, 6)

    enBtn.MouseButton1Click:Connect(function()
        LocalizationSystem.SetLanguage("EN")
        enBtn.BackgroundColor3 = Theme.ACCENT_GOLD; enBtn.TextColor3 = Theme.BG_DARK
        idBtn.BackgroundColor3 = Theme.BG_DARK;     idBtn.TextColor3 = Theme.TEXT_DIM
        GUIManager.RefreshLanguage()
    end)
    idBtn.MouseButton1Click:Connect(function()
        LocalizationSystem.SetLanguage("ID")
        idBtn.BackgroundColor3 = Theme.ACCENT_GOLD; idBtn.TextColor3 = Theme.BG_DARK
        enBtn.BackgroundColor3 = Theme.BG_DARK;     enBtn.TextColor3 = Theme.TEXT_DIM
        GUIManager.RefreshLanguage()
    end)
end

-- ============================================================
-- PANEL TOGGLE FUNCTIONS
-- ============================================================
local function unlockMouse()
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    if ClientState.SetMenuState then ClientState.SetMenuState(true) end
end

local function lockMouse()
    if ClientState.SetMenuState then ClientState.SetMenuState(false) end
end

function GUIManager.ToggleInventory(forceState)
    if not inventoryPanel then return end
    local open = forceState ~= nil and forceState or not inventoryPanel.Visible
    if open then
        GUIManager.CloseAllPanels()
        inventoryPanel.Visible = true
        SlideIn(inventoryPanel, "up")
        unlockMouse()
    else
        SlideOut(inventoryPanel, "down", lockMouse)
    end
end

function GUIManager.ToggleMarket(forceState)
    if not marketPanel then return end
    local open = forceState ~= nil and forceState or not marketPanel.Visible
    if open then
        GUIManager.CloseAllPanels()
        marketPanel.Visible = true
        SlideIn(marketPanel, "up")
        unlockMouse()
        GUIManager.RefreshMarketListings()
    else
        SlideOut(marketPanel, "down", lockMouse)
    end
end

function GUIManager.ToggleMap(forceState)
    if not mapPanel then return end
    local open = forceState ~= nil and forceState or not mapPanel.Visible
    if open then
        GUIManager.CloseAllPanels()
        mapPanel.Visible = true
        SlideIn(mapPanel, "up")
        unlockMouse()
        GUIManager.RefreshMapData()
    else
        SlideOut(mapPanel, "down", lockMouse)
    end
end

function GUIManager.ToggleSettings(forceState)
    if not settingsPanel then return end
    local open = forceState ~= nil and forceState or not settingsPanel.Visible
    if open then
        GUIManager.CloseAllPanels()
        settingsPanel.Visible = true
        SlideIn(settingsPanel, "up")
        unlockMouse()
    else
        SlideOut(settingsPanel, "down", lockMouse)
    end
end

function GUIManager.CloseAllPanels()
    local panels = {inventoryPanel, marketPanel, mapPanel, settingsPanel}
    for _, p in ipairs(panels) do
        if p and p.Visible then
            SlideOut(p, "down")
        end
    end
    lockMouse()
end

-- ============================================================
-- INVENTORY GRID ITEM PLACEMENT
-- ============================================================
function GUIManager.AddItemToGrid(itemName, gridW, gridH, color)
    if not inventoryPanel then return false end
    local grid = inventoryPanel:FindFirstChild("GridArea", true)
    if not grid then return false end
    local g    = grid:FindFirstChild("Grid")
    if not g   then return false end

    for _, slot in ipairs(g:GetChildren()) do
        if slot:IsA("Frame") and slot.Name:sub(1, 5) == "GSlot" and #slot:GetChildren() == 0 then
            local item = Instance.new("Frame")
            item.Name             = "Item_" .. itemName
            item.Size             = UDim2.new(1, 0, 1, 0)
            item.BackgroundColor3 = color or Theme.ACCENT_CYAN
            item.ZIndex           = 4
            item.Parent           = slot
            AddCorner(item, 4)

            local lbl = Instance.new("TextLabel")
            lbl.Size               = UDim2.new(1, -4, 1, -4)
            lbl.Position           = UDim2.new(0, 2, 0, 2)
            lbl.BackgroundTransparency = 1
            lbl.Text               = itemName
            lbl.Font               = Enum.Font.Gotham
            lbl.TextScaled         = true
            lbl.TextColor3         = Theme.TEXT_PRIMARY
            lbl.TextStrokeTransparency = 0.6
            lbl.ZIndex             = 5
            lbl.Parent             = item

            return true
        end
    end
    SpawnNotif(LocalizationSystem.Get("INV_FULL"), Theme.DANGER)
    return false
end

-- ============================================================
-- REFRESH MAP DATA
-- ============================================================
function GUIManager.RefreshMapData()
    if not mapPanel then return end
    local sidebar    = mapPanel:FindFirstChild("Sidebar", true)
    local titleLabel = mapPanel:FindFirstChild("MapTitleLabel", true)
    local statusLbl  = sidebar and sidebar:FindFirstChild("StatusLabel")

    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local y   = root.Position.Y
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hp  = hum and math.floor(hum.Health) or 0
    local maxHp = hum and math.floor(hum.MaxHealth) or 0

    if y > 800 then
        if titleLabel then titleLabel.Text = LocalizationSystem.Get("MAP_TITLE_LOBBY") end
        if statusLbl  then statusLbl.Text  = LocalizationSystem.Get("BIOME_LOBBY") .. "\nHP: " .. hp .. " / " .. maxHp end
    else
        if titleLabel then titleLabel.Text = LocalizationSystem.Get("MAP_TITLE_KALIMANTAN") end
        if statusLbl  then statusLbl.Text  = LocalizationSystem.Get("BIOME_TROPICAL") .. "\nHP: " .. hp .. " / " .. maxHp end
    end
end

-- ============================================================
-- REFRESH MARKET LISTINGS
-- ============================================================
function GUIManager.RefreshMarketListings()
    if not marketPanel then return end
    local listFrame = marketPanel:FindFirstChild("Listings", true)
    if not listFrame then return end

    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return end
    local marketReq = events:FindFirstChild("MarketRequest")
    if not marketReq then return end

    task.spawn(function()
        local ok, listings = pcall(function()
            return marketReq:InvokeServer("GetMarket", "All", "")
        end)
        if not ok or not listings then return end

        -- Clear old rows (keep layout)
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        for _, listing in ipairs(listings) do
            local row = Instance.new("Frame")
            row.Size             = UDim2.new(1, -12, 0, 52)
            row.BackgroundColor3 = Theme.BG_MID
            row.BackgroundTransparency = 0.35
            row.Parent           = listFrame
            AddCorner(row, 6)
            AddPadding(row, 8)

            local nameL = Instance.new("TextLabel")
            nameL.Size               = UDim2.new(0.55, 0, 0.5, 0)
            nameL.BackgroundTransparency = 1
            nameL.Text               = listing.Name or "Unknown"
            nameL.Font               = Enum.Font.GothamBold
            nameL.TextSize           = 14
            nameL.TextColor3         = Theme.TEXT_PRIMARY
            nameL.TextXAlignment     = Enum.TextXAlignment.Left
            nameL.Parent             = row

            local priceL = Instance.new("TextLabel")
            priceL.Size               = UDim2.new(0.55, 0, 0.5, 0)
            priceL.Position           = UDim2.new(0, 0, 0.5, 0)
            priceL.BackgroundTransparency = 1
            priceL.Text               = "$ " .. tostring(listing.Price)
            priceL.Font               = Enum.Font.Gotham
            priceL.TextSize           = 12
            priceL.TextColor3         = Theme.ACCENT_GOLD
            priceL.TextXAlignment     = Enum.TextXAlignment.Left
            priceL.Parent             = row

            local buyBtn = Instance.new("TextButton")
            buyBtn.Size             = UDim2.new(0, 80, 0.8, 0)
            buyBtn.Position         = UDim2.new(1, -84, 0.1, 0)
            buyBtn.BackgroundColor3 = Theme.ACCENT_GREEN
            buyBtn.TextColor3       = Theme.BG_DARK
            buyBtn.Text             = LocalizationSystem.Get("MARKET_BUY")
            buyBtn.Font             = Enum.Font.GothamBold
            buyBtn.TextSize         = 13
            buyBtn.AutoButtonColor  = false
            buyBtn.Parent           = row
            AddCorner(buyBtn, 6)

            buyBtn.MouseButton1Click:Connect(function()
                local success, msg = pcall(function()
                    return marketReq:InvokeServer("PurchaseListing", listing.ListingId)
                end)
                if success then
                    SpawnNotif(LocalizationSystem.Get("MARKET_PURCHASE_SUCCESS"), Theme.ACCENT_GREEN)
                    row:Destroy()
                else
                    SpawnNotif(LocalizationSystem.Get("MARKET_PURCHASE_FAIL"), Theme.DANGER)
                end
            end)
        end
    end)
end

-- ============================================================
-- LIMB HUD UPDATE
-- ============================================================
function GUIManager.UpdateLimbHUD(limbData)
    for limbName, data in pairs(limbData) do
        local label = limbFrames[limbName]
        if label then
            local status = data.Status or "Healthy"
            label.Text = status == "Healthy" and "OK"
                     or  status == "Injured"  and "INJ"
                     or  "X"
            label.TextColor3 = status == "Healthy" and Theme.ACCENT_GREEN
                           or  status == "Injured"  and Theme.WARNING
                           or  Theme.DANGER
        end
    end
end

-- ============================================================
-- LANGUAGE REFRESH
-- ============================================================
function GUIManager.RefreshLanguage()
    -- Update dynamic text labels that depend on localization
    if mpText then
        mpText.Text = LocalizationSystem.Get("HUD_NO_MANA")
    end
    SpawnNotif("Language changed / Bahasa diubah", Theme.ACCENT_CYAN, 3)
end

-- ============================================================
-- SERVER EVENT LISTENERS
-- ============================================================
function GUIManager.SetupNetworkListeners()
    local events = ReplicatedStorage:WaitForChild("Events", 10)
    if not events then
        warn("[GUIManager] Events folder not found within timeout.")
        return
    end

    -- Item pickup
    local pickupEv = events:WaitForChild("ItemPickedUp", 5)
    if pickupEv then
        pickupEv.OnClientEvent:Connect(function(itemData)
            GUIManager.AddItemToGrid(itemData.Name, itemData.GridWidth, itemData.GridHeight, itemData.Color)
        end)
    end

    -- Limb status
    local limbEv = events:WaitForChild("UpdateLimbHUD", 5)
    if limbEv then
        limbEv.OnClientEvent:Connect(function(limbData)
            GUIManager.UpdateLimbHUD(limbData)
        end)
    end

    -- Vitals (mana)
    local vitalsEv = events:WaitForChild("UpdateVitals", 5)
    if vitalsEv then
        vitalsEv.OnClientEvent:Connect(function(curHP, maxHP, curMana, maxMana)
            GUIManager.CachedMana    = curMana
            GUIManager.CachedMaxMana = maxMana

            if mpFill and mpText then
                if maxMana > 0 then
                    TweenBarFill(mpFill, curMana / maxMana)
                    mpText.Text = math.floor(curMana) .. " / " .. math.floor(maxMana)
                    mpText.TextColor3 = Theme.TEXT_PRIMARY
                else
                    TweenBarFill(mpFill, 0)
                    mpText.Text = LocalizationSystem.Get("HUD_NO_MANA")
                    mpText.TextColor3 = Theme.TEXT_DIM
                end
            end
        end)
    end

    -- Season change notification
    local seasonEv = events:WaitForChild("SeasonChanged", 5)
    if seasonEv then
        seasonEv.OnClientEvent:Connect(function(season)
            local seasonKey = "SEASON_" .. season:upper()
            local name = LocalizationSystem.Get(seasonKey)
            SpawnNotif(LocalizationSystem.Get("SEASON_CHANGED") .. " " .. name, Theme.ACCENT_CYAN, 6)
        end)
    end

    -- Meteor warning
    local meteorEv = events:WaitForChild("MeteorWarning", 5)
    if meteorEv then
        meteorEv.OnClientEvent:Connect(function(strikePos)
            SpawnNotif("⚠ " .. LocalizationSystem.Get("METEOR_WARNING") .. "\n" .. LocalizationSystem.Get("METEOR_DANGER"), Theme.DANGER, 8)
        end)
    end

    -- Mail alert
    local mailEv = events:WaitForChild("NewMailAlert", 5)
    if mailEv then
        mailEv.OnClientEvent:Connect(function(subject)
            SpawnNotif("📬 New mail: " .. tostring(subject), Theme.ACCENT_GOLD, 6)
        end)
    end
end

-- ============================================================
-- BOOT
-- ============================================================
GUIManager.Initialize()

return GUIManager
