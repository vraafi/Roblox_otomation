-- AUDIO_SYSTEM_1.lua
-- Rancang sistem audio untuk game.

local AudioSystem = {}

function AudioSystem.Initialize()
    -- Create SoundGroup for SFX
    local sfxGroup = Instance.new("SoundGroup")
    sfxGroup.Name = "SFXGroup"
    sfxGroup.Volume = 0.8
    sfxGroup.Parent = game:GetService("SoundService")

    -- Create SoundGroup for BGM
    local bgmGroup = Instance.new("SoundGroup")
    bgmGroup.Name = "BGMGroup"
    bgmGroup.Volume = 0.5
    bgmGroup.Parent = game:GetService("SoundService")

    -- Spaceship BGM
    local spaceshipBGM = Instance.new("Sound")
    spaceshipBGM.Name = "SpaceshipBGM"
    spaceshipBGM.SoundId = "rbxassetid://1843404009" -- Ambient sci-fi drone
    spaceshipBGM.Looped = true
    spaceshipBGM.SoundGroup = bgmGroup
    spaceshipBGM.Parent = workspace
    spaceshipBGM:Play()
end

function AudioSystem.PlaySpatialSound(assetId, position)
    local soundPart = Instance.new("Part")
    soundPart.Transparency = 1
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.Position = position
    soundPart.Parent = workspace

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(assetId)
    sound.SoundGroup = game:GetService("SoundService"):WaitForChild("SFXGroup")
    sound.Parent = soundPart

    sound:Play()

    sound.Ended:Connect(function()
        soundPart:Destroy()
    end)
end

function AudioSystem.ChangeBiomeMusic(biomeType)
    local bgm = workspace:FindFirstChild("SpaceshipBGM")
    if bgm then bgm:Stop() end

    local newBGM = Instance.new("Sound")
    newBGM.Name = "BiomeBGM"

    if biomeType == "Forest" then
        newBGM.SoundId = "rbxassetid://1843404009" -- Placeholder forest ambient
    elseif biomeType == "Desert" then
        newBGM.SoundId = "rbxassetid://1843404009" -- Placeholder desert wind
    end

    newBGM.Looped = true
    newBGM.Parent = workspace
    newBGM:Play()
end

return AudioSystem
