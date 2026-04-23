-- InputManager.client.lua
-- Handles universal cross-platform inputs (PC Keyboard/Mouse and Mobile Touch)

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Track if the player is currently opening a menu so we can disable combat
local isMenuOpen = false

local function handleJump(actionName, inputState, inputObject)
    if actionName == "JumpAction" and inputState == Enum.UserInputState.Begin then
        if not isMenuOpen and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function handleShoot(actionName, inputState, inputObject)
    if actionName == "ShootAction" and inputState == Enum.UserInputState.Begin then
        if not isMenuOpen and humanoid.Health > 0 then
            -- In a full game, this fires a RemoteEvent to CombatManager.lua
            print("Client requested FIRE weapon!")
            -- Determine aim direction from camera
            local cam = workspace.CurrentCamera
            local ray = cam:ScreenPointToRay(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
            -- FireServer(ray.Origin, ray.Direction)
        end
    end
end

local function handleInteract(actionName, inputState, inputObject)
    if actionName == "InteractAction" and inputState == Enum.UserInputState.Begin then
        if not isMenuOpen then
            print("Client requested INTERACT (ProximityPrompt override or general interact).")
        end
    end
end

-- Bind Actions with Mobile Button support
-- PC uses Spacebar for Jump, Mobile gets a screen button
ContextActionService:BindAction("JumpAction", handleJump, true, Enum.KeyCode.Space)
ContextActionService:SetTitle("JumpAction", "JUMP")
ContextActionService:SetPosition("JumpAction", UDim2.new(1, -100, 1, -100))

-- PC uses Left Click for Shoot, Mobile gets a screen button
ContextActionService:BindAction("ShootAction", handleShoot, true, Enum.UserInputType.MouseButton1)
ContextActionService:SetTitle("ShootAction", "FIRE")
ContextActionService:SetPosition("ShootAction", UDim2.new(1, -200, 1, -100))

-- PC uses F for Interact, Mobile gets a screen button
ContextActionService:BindAction("InteractAction", handleInteract, true, Enum.KeyCode.F)
ContextActionService:SetTitle("InteractAction", "USE")
ContextActionService:SetPosition("InteractAction", UDim2.new(1, -100, 1, -200))

-- Visually customize the mobile buttons if the player is on mobile
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
    local jumpButton = ContextActionService:GetButton("JumpAction")
    if jumpButton then jumpButton.Size = UDim2.new(0, 70, 0, 70) end

    local shootButton = ContextActionService:GetButton("ShootAction")
    if shootButton then
        shootButton.Size = UDim2.new(0, 90, 0, 90)
        shootButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end

-- Expose to global/other client scripts to freeze controls when UI is open
_G.SetMenuState = function(state)
    isMenuOpen = state
end

print("InputManager initialized for Mobile & PC.")
