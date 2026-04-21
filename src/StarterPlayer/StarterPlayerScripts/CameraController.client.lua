local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CAMERA_OFFSET = Vector3.new(0, 40, 30) -- Elevated follow perspective
local CAMERA_LOOK_DOWN_ANGLE = CFrame.Angles(math.rad(-50), 0, 0)

-- Wait for the character to load before trying to follow it
local function onCharacterAdded(character)
    camera.CameraType = Enum.CameraType.Scriptable

    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    RunService:BindToRenderStep("FollowCamera", Enum.RenderPriority.Camera.Value, function()
        if humanoidRootPart then
            local targetPosition = humanoidRootPart.Position + CAMERA_OFFSET
            camera.CFrame = CFrame.new(targetPosition) * CAMERA_LOOK_DOWN_ANGLE
        end
    end)
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
