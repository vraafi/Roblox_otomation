-- CameraSetup.client.lua
-- Enforces First-Person Perspective and handles the Viewmodel (Arms + Default Knife)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Lock to first-person
player.CameraMode = Enum.CameraMode.LockFirstPerson

local viewmodel = nil

local function setupViewmodel()
    if viewmodel then viewmodel:Destroy() end

    viewmodel = Instance.new("Model")
    viewmodel.Name = "Viewmodel"

    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(1, 1, 1)
    rootPart.Transparency = 1
    rootPart.CanCollide = false
    rootPart.Parent = viewmodel
    viewmodel.PrimaryPart = rootPart

    -- Create Right Arm
    local rightArm = Instance.new("Part")
    rightArm.Name = "RightArm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Color = Color3.fromRGB(255, 204, 153)
    rightArm.CanCollide = false
    rightArm.Parent = viewmodel

    -- Create Default Knife
    local knife = Instance.new("Part")
    knife.Name = "DefaultKnife"
    knife.Size = Vector3.new(0.2, 1.5, 0.2)
    knife.Color = Color3.fromRGB(100, 100, 100)
    knife.CanCollide = false
    knife.Parent = viewmodel

    -- Weld Arm to Root
    local weldArm = Instance.new("Weld")
    weldArm.Part0 = rootPart
    weldArm.Part1 = rightArm
    weldArm.C0 = CFrame.new(1.5, -1, -2)
    weldArm.Parent = rootPart

    -- Weld Knife to Arm
    local weldKnife = Instance.new("Weld")
    weldKnife.Part0 = rightArm
    weldKnife.Part1 = knife
    weldKnife.C0 = CFrame.new(0, -1, -0.5) * CFrame.Angles(math.rad(90), 0, 0)
    weldKnife.Parent = rightArm

    viewmodel.Parent = camera
end

-- Add TweenService and variables for Camera & Viewmodel manipulation
local TweenService = game:GetService("TweenService")

-- Expose states globally so InputManager can tell CameraSetup what to do
_G.TacticalStates = {
    IsCrouching = false,
    IsProning = false,
    PeekState = "None", -- "Left", "Right", "None"
    IsADS = false
}

local currentCameraOffset = Vector3.new(0, 0, 0)
local currentCameraRoll = 0
local targetAdsOffset = CFrame.new(0, 0, 0)

-- Update function now interpolates properties
local function updateViewmodel(dt)
    if not viewmodel then return end

    local char = player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")

    -- 1. Handle Camera Height (Stance)
    local targetHeightOffset = 0
    if _G.TacticalStates.IsProning then
        targetHeightOffset = -3.5
    elseif _G.TacticalStates.IsCrouching then
        targetHeightOffset = -1.5
    end

    -- 2. Handle Camera Peek (Leaning)
    local targetPeekOffset = 0
    local targetRoll = 0

    if _G.TacticalStates.PeekState == "Left" then
        targetPeekOffset = -1.5
        targetRoll = math.rad(15)
    elseif _G.TacticalStates.PeekState == "Right" then
        targetPeekOffset = 1.5
        targetRoll = math.rad(-15)
    end

    -- Smoothly interpolate camera offset
    local targetOffsetVector = Vector3.new(targetPeekOffset, targetHeightOffset, 0)
    currentCameraOffset = currentCameraOffset:Lerp(targetOffsetVector, dt * 10)

    if humanoid then
        humanoid.CameraOffset = currentCameraOffset
    end

    -- Smoothly interpolate camera roll (Z-axis rotation)
    currentCameraRoll = currentCameraRoll + (targetRoll - currentCameraRoll) * dt * 10
    camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, currentCameraRoll)

    -- 3. Handle Viewmodel ADS
    local targetAdsCFrame = CFrame.new(0, 0, 0)
    if _G.TacticalStates.IsADS then
        -- Bring the gun to the center of the screen
        targetAdsCFrame = CFrame.new(-1.0, 0.5, 1) -- Estimated offset to center the right arm
    end

    targetAdsOffset = targetAdsOffset:Lerp(targetAdsCFrame, dt * 15)

    -- Align viewmodel to camera, applying ADS offset
    viewmodel:SetPrimaryPartCFrame(camera.CFrame * targetAdsOffset)
end

player.CharacterAdded:Connect(setupViewmodel)
if player.Character then setupViewmodel() end
RunService.RenderStepped:Connect(updateViewmodel)
