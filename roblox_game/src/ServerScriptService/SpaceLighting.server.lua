-- SpaceLighting.server.lua
-- Runs at game start, forces pure deep-space lighting.
-- This overrides any defaults from project.json at runtime.

local Lighting = game:GetService("Lighting")

-- Remove default Atmosphere and Sky (source of white sky)
for _, child in ipairs(Lighting:GetChildren()) do
    if child:IsA("Sky") or child:IsA("Atmosphere") then
        child:Destroy()
    end
end

-- Deep space: midnight, near-zero ambient, no sun
Lighting.TimeOfDay        = "00:00:00"
Lighting.GeographicLatitude = 0
Lighting.Ambient          = Color3.fromRGB(4,  4,  10)
Lighting.OutdoorAmbient   = Color3.fromRGB(2,  2,   6)
Lighting.Brightness       = 0.0
Lighting.GlobalShadows    = true
Lighting.FogColor         = Color3.fromRGB(0,  0,   8)
Lighting.FogStart         = 8000
Lighting.FogEnd           = 9000
Lighting.Technology       = Enum.Technology.Future

-- Star-filled sky, no sun/moon
local sky             = Instance.new("Sky")
sky.StarCount         = 5000
sky.CelestialBodiesShown = false
sky.Parent            = Lighting

-- Bloom: strong so neon parts glow
local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
bloom.Intensity = 0.9
bloom.Size      = 24
bloom.Threshold = 0.72
bloom.Enabled   = true
bloom.Parent    = Lighting

-- Slight blue color correction (space feel)
local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
cc.Brightness  = 0.0
cc.Contrast    = 0.12
cc.Saturation  = 0.15
cc.TintColor   = Color3.fromRGB(200, 210, 255)
cc.Enabled     = true
cc.Parent      = Lighting

print("[SpaceLighting] Dark space environment applied.")
