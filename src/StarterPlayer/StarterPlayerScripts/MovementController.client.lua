local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local isMouse1Down = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Using MouseButton1 as discovered in the trace for movement
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouse1Down = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouse1Down = false
    end
end)

RunService.RenderStepped:Connect(function()
    if isMouse1Down then
        local character = player.Character
        if not character then return end

        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        local mouseLocation = UserInputService:GetMouseLocation()
        local ray = camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)

        -- Raycast to find the ground position
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

        if result then
            humanoid:MoveTo(result.Position)
        end
    end
end)
