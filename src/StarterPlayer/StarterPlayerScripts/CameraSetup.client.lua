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

local function updateViewmodel()
    if not viewmodel then return end
    -- Align viewmodel to camera
    viewmodel:SetPrimaryPartCFrame(camera.CFrame)
end

player.CharacterAdded:Connect(function(char)
    setupViewmodel()
end)

if player.Character then
    setupViewmodel()
end

RunService.RenderStepped:Connect(updateViewmodel)
