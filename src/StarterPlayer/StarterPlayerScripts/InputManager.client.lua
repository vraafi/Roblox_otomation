-- InputManager.client.lua
-- Handles universal cross-platform inputs (PC Keyboard/Mouse and Mobile Touch)

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Track if the player is currently opening a menu so we can disable combat
local isMenuOpen = false

-- Use dynamic referencing so it always points to the alive character
local function handleJump(actionName, inputState, inputObject)
    if actionName == "JumpAction" and inputState == Enum.UserInputState.Begin then
        local character = player.Character
        if character and not isMenuOpen then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end

local function handleShoot(actionName, inputState, inputObject)
    if actionName == "ShootAction" and inputState == Enum.UserInputState.Begin then
        local character = player.Character
        if character and not isMenuOpen then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- In a full game, this fires a RemoteEvent to CombatManager.lua
                print("Client requested FIRE weapon!")
                local cam = workspace.CurrentCamera
                local ray = cam:ScreenPointToRay(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
                local events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
                events.FireWeapon:FireServer(123) -- Target ID placeholder
            end
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

-- (Patch Placeholder)

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

-- Tactical Weapon Actions
local function handlePing(actionName, inputState, inputObject)
    if actionName == "PingAction" and inputState == Enum.UserInputState.Begin then
        print("Tactical Ping Placed!")
    end
end



local function handleCrouch(actionName, inputState, inputObject)
    if actionName == "CrouchAction" and inputState == Enum.UserInputState.Begin then
        local character = player.Character
        if character and not isMenuOpen then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                if _G.TacticalStates.IsCrouching then
                    humanoid.WalkSpeed = 16 -- Stand up
                    _G.TacticalStates.IsCrouching = false
                    if _G.UpdateTacticalHUD then _G.UpdateTacticalHUD("Stance", "STANDING") end
                else
                    humanoid.WalkSpeed = 8 -- Crouch
                    _G.TacticalStates.IsCrouching = true
                    _G.TacticalStates.IsProning = false
                    if _G.UpdateTacticalHUD then _G.UpdateTacticalHUD("Stance", "CROUCHING") end
                end
            end
        end
    end
end

local function handleProne(actionName, inputState, inputObject)
    if actionName == "ProneAction" and inputState == Enum.UserInputState.Begin then
        local character = player.Character
        if character and not isMenuOpen then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                if _G.TacticalStates.IsProning then
                    humanoid.WalkSpeed = 16 -- Stand up
                    _G.TacticalStates.IsProning = false
                    if _G.UpdateTacticalHUD then _G.UpdateTacticalHUD("Stance", "STANDING") end
                else
                    humanoid.WalkSpeed = 4 -- Prone
                    _G.TacticalStates.IsProning = true
                    _G.TacticalStates.IsCrouching = false
                    if _G.UpdateTacticalHUD then _G.UpdateTacticalHUD("Stance", "PRONING") end
                end
            end
        end
    end
end

local function handlePeekLeft(actionName, inputState, inputObject)
    if actionName == "PeekLeftAction" then
        if inputState == Enum.UserInputState.Begin then
            _G.TacticalStates.PeekState = "Left"
        elseif inputState == Enum.UserInputState.End then
            if _G.TacticalStates.PeekState == "Left" then
                _G.TacticalStates.PeekState = "None"
            end
        end
    end
end

local function handlePeekRight(actionName, inputState, inputObject)
    if actionName == "PeekRightAction" then
        if inputState == Enum.UserInputState.Begin then
            _G.TacticalStates.PeekState = "Right"
        elseif inputState == Enum.UserInputState.End then
            if _G.TacticalStates.PeekState == "Right" then
                _G.TacticalStates.PeekState = "None"
            end
        end
    end
end

local function handleADS(actionName, inputState, inputObject)
    if actionName == "ADSAction" then
        if inputState == Enum.UserInputState.Begin then
            _G.TacticalStates.IsADS = true
            workspace.CurrentCamera.FieldOfView = 40
        elseif inputState == Enum.UserInputState.End then
            _G.TacticalStates.IsADS = false
            workspace.CurrentCamera.FieldOfView = 70
        end
    end
end

local function handleSprint(actionName, inputState, inputObject)
    local character = player.Character
    if character and not isMenuOpen then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            if inputState == Enum.UserInputState.Begin then
                humanoid.WalkSpeed = 24
                _G.TacticalStates.IsCrouching = false
                _G.TacticalStates.IsProning = false
            elseif inputState == Enum.UserInputState.End then
                humanoid.WalkSpeed = 16
            end
        end
    end
end

local function handleReload(actionName, inputState, inputObject)
    if actionName == "ReloadAction" and inputState == Enum.UserInputState.Begin then
        print("Requested Weapon Reload (Swap Magazine).")
        local events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
        local ok, msg = events.ReloadWeapon:InvokeServer("Mag_Instance_Id")
        print("Reload:", msg)
    end
end

local function handleFireMode(actionName, inputState, inputObject)
    if actionName == "FireModeAction" and inputState == Enum.UserInputState.Begin then
        print("Toggling Fire Mode (Auto/Single).")
    end
end

local function handleGrenade(actionName, inputState, inputObject)
    if actionName == "ThrowGrenadeAction" and inputState == Enum.UserInputState.Begin then
        local events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
        events.ThrowGrenade:FireServer("Frag_Grenade")
        print("Throwing Grenade...")
    end
end
ContextActionService:BindAction("ThrowGrenadeAction", handleGrenade, true, Enum.KeyCode.G)
ContextActionService:SetTitle("ThrowGrenadeAction", "NADE")
ContextActionService:SetPosition("ThrowGrenadeAction", UDim2.new(1, -200, 1, -400))

local function handleMedical(actionName, inputState, inputObject)
    if actionName == "UseMedicalAction" and inputState == Enum.UserInputState.Begin then
        local events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
        events.UseMedicalItem:InvokeServer("IFAK_Medkit", "Thorax")
        print("Using Medical Item...")
    end
end
ContextActionService:BindAction("UseMedicalAction", handleMedical, true, Enum.KeyCode.H)
ContextActionService:SetTitle("UseMedicalAction", "HEAL")
ContextActionService:SetPosition("UseMedicalAction", UDim2.new(1, -300, 1, -400))

local function handleCheckWeapon(actionName, inputState, inputObject)
    if actionName == "CheckWeaponAction" and inputState == Enum.UserInputState.Begin then
        print("Checking Weapon Chamber / Malfunctions.")
        if _G.UpdateTacticalHUD then _G.UpdateTacticalHUD("Ammo", "MAG: [ 30 ] | CHMBR: [ 1 ]") end
    end
end

-- Tactical Movement Actions
ContextActionService:BindAction("CrouchAction", handleCrouch, true, Enum.KeyCode.C)
ContextActionService:SetTitle("CrouchAction", "CRCH")
ContextActionService:SetPosition("CrouchAction", UDim2.new(1, -100, 1, -300))

ContextActionService:BindAction("ProneAction", handleProne, true, Enum.KeyCode.Z)
ContextActionService:SetTitle("ProneAction", "PRON")
ContextActionService:SetPosition("ProneAction", UDim2.new(1, -200, 1, -300))

ContextActionService:BindAction("SprintAction", handleSprint, true, Enum.KeyCode.LeftShift)
ContextActionService:SetTitle("SprintAction", "RUN")
ContextActionService:SetPosition("SprintAction", UDim2.new(0, 50, 1, -200))

ContextActionService:BindAction("PeekLeftAction", handlePeekLeft, true, Enum.KeyCode.Q)
ContextActionService:SetTitle("PeekLeftAction", "PK-L")
ContextActionService:SetPosition("PeekLeftAction", UDim2.new(1, -300, 1, -200))

ContextActionService:BindAction("PeekRightAction", handlePeekRight, true, Enum.KeyCode.E)
ContextActionService:SetTitle("PeekRightAction", "PK-R")
ContextActionService:SetPosition("PeekRightAction", UDim2.new(1, -100, 1, -400))

-- Tactical Weapon Actions
ContextActionService:BindAction("ADSAction", handleADS, true, Enum.UserInputType.MouseButton2)
ContextActionService:SetTitle("ADSAction", "AIM")
ContextActionService:SetPosition("ADSAction", UDim2.new(1, -300, 1, -100))

ContextActionService:BindAction("ReloadAction", handleReload, true, Enum.KeyCode.R)
ContextActionService:SetTitle("ReloadAction", "RLD")
ContextActionService:SetPosition("ReloadAction", UDim2.new(1, -200, 1, -200))

ContextActionService:BindAction("FireModeAction", handleFireMode, true, Enum.KeyCode.B)
ContextActionService:SetTitle("FireModeAction", "MODE")
ContextActionService:SetPosition("FireModeAction", UDim2.new(1, -100, 1, -500))

ContextActionService:BindAction("CheckWeaponAction", handleCheckWeapon, true, Enum.KeyCode.X)
ContextActionService:SetTitle("CheckWeaponAction", "CHK")
ContextActionService:SetPosition("CheckWeaponAction", UDim2.new(1, -200, 1, -500))

ContextActionService:BindAction("PingAction", handlePing, true, Enum.UserInputType.MouseButton3)
ContextActionService:SetTitle("PingAction", "PING")
ContextActionService:SetPosition("PingAction", UDim2.new(1, -300, 1, -500))
