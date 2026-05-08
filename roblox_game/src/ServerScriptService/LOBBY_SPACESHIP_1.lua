-- LOBBY_SPACESHIP_1.lua
-- AAA Spaceship Carrier Lobby
-- Features: enclosed hangar, proper R6 humanoid NPCs, animated space background
-- (asteroids, planets, nebula), rare hourly events, and NPC shop integration.

local SpaceshipLobby = {}

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")
local RS           = game:GetService("ReplicatedStorage")

local LOBBY_Y   = 1000
local FLOOR_TOP = LOBBY_Y + 1   -- Y where player stands (floor surface)
local HALL_W    = 600
local HALL_D    = 400
local WALL_H    = 72
local WALL_T    = 8

-- ============================================================
-- HELPERS
-- ============================================================
local function Block(folder, name, sz, pos, col, mat, trans, noCollide)
    local p = Instance.new("Part")
    p.Name         = name
    p.Size         = sz
    p.Position     = pos
    p.Anchored     = true
    p.CanCollide   = (not noCollide)
    p.Color        = col
    p.Material     = mat or Enum.Material.Metal
    p.Transparency = trans or 0
    p.CastShadow   = (trans or 0) < 0.5
    p.Parent       = folder
    return p
end

local function PL(parent, col, brightness, range)
    local l = Instance.new("PointLight")
    l.Color = col; l.Brightness = brightness; l.Range = range
    l.Parent = parent
end

local function SG(part, face, text, fontSize, textColor)
    local sg  = Instance.new("SurfaceGui")
    sg.Face   = face
    sg.CanvasSize = Vector2.new(800, 200)
    sg.Parent = part
    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = fontSize or 32
    lbl.TextColor3             = textColor or Color3.fromRGB(220,175,50)
    lbl.TextXAlignment         = Enum.TextXAlignment.Center
    lbl.TextYAlignment         = Enum.TextYAlignment.Center
    lbl.TextWrapped            = true
    lbl.Parent                 = sg
end

-- ============================================================
-- R6 HUMANOID NPC BUILDER
-- ============================================================
local function BuildR6NPC(folder, npcName, pos, skinCol, shirtCol, pantsCol,
                           actionText, dialogText, npcType)
    -- pos = floor position (feet at pos.Y)
    local FY = pos.Y  -- floor Y

    local model = Instance.new("Model")
    model.Name  = npcName

    -- Helper for anchored parts
    local function P(nm, sz, cframe, col, mat)
        local p = Instance.new("Part")
        p.Name     = nm
        p.Size     = sz
        p.CFrame   = cframe
        p.Anchored = true
        p.Color    = col
        p.Material = mat or Enum.Material.SmoothPlastic
        p.CanCollide = false
        p.Parent   = model
        return p
    end

    -- HumanoidRootPart (invisible, solid — needed for proximity prompts)
    local hrp = Instance.new("Part")
    hrp.Name         = "HumanoidRootPart"
    hrp.Size         = Vector3.new(2, 2, 1)
    hrp.CFrame       = CFrame.new(pos + Vector3.new(0, FY + 3, 0) - Vector3.new(0, FY, 0))
    hrp.Anchored     = true
    hrp.Transparency = 1
    hrp.CanCollide   = true
    hrp.Parent       = model

    -- Torso
    local torso = P("Torso", Vector3.new(2, 2, 1),
        CFrame.new(pos.X, FY + 3, pos.Z), shirtCol)

    -- Head (R6: 2×1×1, not a ball)
    local head = P("Head", Vector3.new(2, 1, 1),
        CFrame.new(pos.X, FY + 4.5, pos.Z), skinCol)

    -- Classic Roblox face decal
    local face = Instance.new("Decal")
    face.Face    = Enum.NormalId.Front
    face.Texture = "rbxassetid://1281287"
    face.Parent  = head

    -- Arms
    local lArm = P("Left Arm",  Vector3.new(1, 2, 1),
        CFrame.new(pos.X - 1.5, FY + 3, pos.Z), skinCol)
    local rArm = P("Right Arm", Vector3.new(1, 2, 1),
        CFrame.new(pos.X + 1.5, FY + 3, pos.Z), skinCol)

    -- Shirt sleeves color
    lArm.Color = shirtCol; rArm.Color = shirtCol

    -- Legs
    local lLeg = P("Left Leg",  Vector3.new(1, 2, 1),
        CFrame.new(pos.X - 0.5, FY + 1, pos.Z), pantsCol)
    local rLeg = P("Right Leg", Vector3.new(1, 2, 1),
        CFrame.new(pos.X + 0.5, FY + 1, pos.Z), pantsCol)

    -- Humanoid
    local hum = Instance.new("Humanoid")
    hum.DisplayName = npcName
    hum.MaxHealth   = 100
    hum.Health      = 100
    hum.WalkSpeed   = 0
    hum.JumpPower   = 0
    hum.Parent      = model

    -- Overhead name tag
    local bill = Instance.new("BillboardGui")
    bill.Size        = UDim2.new(0, 280, 0, 52)
    bill.StudsOffset = Vector3.new(0, 3.0, 0)
    bill.AlwaysOnTop = false
    bill.Parent      = head

    local bgF = Instance.new("Frame")
    bgF.Size                   = UDim2.new(1,0,1,0)
    bgF.BackgroundColor3       = Color3.fromRGB(10, 12, 20)
    bgF.BackgroundTransparency = 0.2
    bgF.Parent                 = bill
    Instance.new("UICorner", bgF).CornerRadius = UDim.new(0, 8)

    local nameL = Instance.new("TextLabel")
    nameL.Size                   = UDim2.new(1,-8,1,0)
    nameL.Position               = UDim2.new(0,4,0,0)
    nameL.BackgroundTransparency = 1
    nameL.Text                   = npcName
    nameL.Font                   = Enum.Font.GothamBold
    nameL.TextSize               = 17
    nameL.TextColor3             = Color3.fromRGB(220, 175, 50)
    nameL.TextXAlignment         = Enum.TextXAlignment.Center
    nameL.TextYAlignment         = Enum.TextYAlignment.Center
    nameL.Parent                 = bgF

    -- Proximity prompt on torso
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText            = actionText
    prompt.ObjectText            = npcName
    prompt.KeyboardKeyCode       = Enum.KeyCode.E
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration          = 0
    prompt.Parent                = torso

    prompt.Triggered:Connect(function(plr)
        -- Open NPC shop on client
        if npcType then
            local ev = RS:FindFirstChild("Events")
            if ev then
                local shopEv = ev:FindFirstChild("OpenNPCShop")
                if shopEv then shopEv:FireClient(plr, npcType) end
            end
        end

        -- Show dialog bubble (server-side, 5s)
        local bubble = Instance.new("BillboardGui")
        bubble.Size        = UDim2.new(0, 320, 0, 90)
        bubble.StudsOffset = Vector3.new(0, 5.5, 0)
        bubble.AlwaysOnTop = false
        bubble.Parent      = head

        local bg = Instance.new("Frame")
        bg.Size                   = UDim2.new(1,0,1,0)
        bg.BackgroundColor3       = Color3.fromRGB(8, 11, 18)
        bg.BackgroundTransparency = 0.08
        bg.Parent                 = bubble
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

        local dl = Instance.new("TextLabel")
        dl.Size                   = UDim2.new(1,-14,1,0)
        dl.Position               = UDim2.new(0,7,0,0)
        dl.BackgroundTransparency = 1
        dl.Text                   = dialogText
        dl.Font                   = Enum.Font.Gotham
        dl.TextSize               = 13
        dl.TextColor3             = Color3.fromRGB(230, 230, 230)
        dl.TextWrapped            = true
        dl.TextXAlignment         = Enum.TextXAlignment.Left
        dl.TextYAlignment         = Enum.TextYAlignment.Center
        dl.Parent                 = bg

        Debris:AddItem(bubble, 5)
    end)

    model.PrimaryPart = hrp
    model.Parent      = folder
    return model
end

-- ============================================================
-- SPACE BACKGROUND (planets, stars, nebula — outside hangar)
-- ============================================================
local function BuildSpaceBackground(folder)
    local spaceFolder = Instance.new("Folder")
    spaceFolder.Name   = "SpaceBackground"
    spaceFolder.Parent = folder

    -- ── PLANETS ──────────────────────────────────────────────
    local planets = {
        -- {pos relative to lobby, radius, color, material}
        { Vector3.new(-800, LOBBY_Y + 200, -900), 120, Color3.fromRGB(180, 120, 60),  Enum.Material.SmoothPlastic }, -- Gas giant (Jupiter-like)
        { Vector3.new( 700, LOBBY_Y - 100, -800), 70,  Color3.fromRGB(60,  90,  180), Enum.Material.SmoothPlastic }, -- Ice giant (blue)
        { Vector3.new(-300, LOBBY_Y + 400, -1200),50,  Color3.fromRGB(180, 60,  50),  Enum.Material.SmoothPlastic }, -- Red planet (Mars-like)
        { Vector3.new( 400, LOBBY_Y - 200, -1000),30,  Color3.fromRGB(160, 150, 140), Enum.Material.SmoothPlastic }, -- Rocky moon
        { Vector3.new(-600, LOBBY_Y + 600, -700), 90,  Color3.fromRGB(100, 160, 80),  Enum.Material.SmoothPlastic }, -- Emerald planet
    }
    for i, pd in ipairs(planets) do
        local planet = Instance.new("Part")
        planet.Name     = "Planet_" .. i
        planet.Shape    = Enum.PartType.Ball
        planet.Size     = Vector3.new(pd[2]*2, pd[2]*2, pd[2]*2)
        planet.Position = pd[1]
        planet.Anchored = true
        planet.CanCollide = false
        planet.Color    = pd[3]
        planet.Material = pd[4]
        planet.CastShadow = false
        planet.Parent   = spaceFolder

        -- Glow atmosphere on planet
        PL(planet, pd[3], 1.5, pd[2] * 2.5)

        -- Rings on gas giant
        if i == 1 then
            local ring = Instance.new("Part")
            ring.Shape    = Enum.PartType.Cylinder
            ring.Size     = Vector3.new(3, pd[2]*3.2, pd[2]*3.2)
            ring.CFrame   = CFrame.new(pd[1]) * CFrame.Angles(math.rad(20), 0, math.rad(5))
            ring.Anchored = true
            ring.CanCollide = false
            ring.Color    = Color3.fromRGB(200, 160, 90)
            ring.Material = Enum.Material.SmoothPlastic
            ring.Transparency = 0.55
            ring.CastShadow = false
            ring.Parent   = spaceFolder
        end
    end

    -- ── NEBULA CLOUDS ────────────────────────────────────────
    local nebulae = {
        { Vector3.new(0,   LOBBY_Y + 500, -1400), 400, Color3.fromRGB(80,  30, 120), 0.88 }, -- Purple nebula
        { Vector3.new(-900, LOBBY_Y + 300, -600),  300, Color3.fromRGB(30,  80, 140), 0.88 }, -- Blue nebula
        { Vector3.new( 900, LOBBY_Y - 100, -800),  350, Color3.fromRGB(140, 50,  30), 0.90 }, -- Red/orange nebula
    }
    for i, nd in ipairs(nebulae) do
        local neb = Instance.new("Part")
        neb.Name      = "Nebula_" .. i
        neb.Shape     = Enum.PartType.Ball
        neb.Size      = Vector3.new(nd[2]*2, nd[2]*1.3, nd[2]*1.6)
        neb.Position  = nd[1]
        neb.Anchored  = true
        neb.CanCollide = false
        neb.Color     = nd[3]
        neb.Material  = Enum.Material.Neon
        neb.Transparency = nd[4]
        neb.CastShadow = false
        neb.Parent    = spaceFolder
        PL(neb, nd[3], 0.8, nd[2] * 1.5)
    end

    -- ── ASTEROID BELT (static background pieces) ─────────────
    for i = 1, 25 do
        local asz = math.random(4, 18)
        local aPos = Vector3.new(
            math.random(-900, 900),
            LOBBY_Y + math.random(-150, 300),
            math.random(-1300, -500)
        )
        local ast = Instance.new("Part")
        ast.Name      = "StaticAsteroid_" .. i
        ast.Shape     = Enum.PartType.Ball
        ast.Size      = Vector3.new(asz, asz * 0.65, asz * 0.55)
        ast.Position  = aPos
        ast.Anchored  = true
        ast.CanCollide = false
        ast.Color     = Color3.fromRGB(math.random(80,130), math.random(75,115), math.random(60,100))
        ast.Material  = Enum.Material.Rock
        ast.CastShadow = false
        ast.Parent    = spaceFolder
    end

    return spaceFolder
end

-- ============================================================
-- ANIMATED ASTEROIDS (move left-to-right, loop forever)
-- ============================================================
local function BuildAnimatedAsteroids(folder)
    local astFolder = Instance.new("Folder")
    astFolder.Name   = "AnimatedAsteroids"
    astFolder.Parent = folder

    -- Corridor: runs in front of north wall windows at varying Z depths
    local asteroidDefs = {
        -- {startX, endX, Z depth, Y, size, speed (seconds)}
        { -900,  900, -600, LOBBY_Y + 80,  8, 28 },
        {  900, -900, -720, LOBBY_Y - 40,  5, 22 },
        { -900,  900, -850, LOBBY_Y + 180, 12, 38 },
        {  900, -900, -500, LOBBY_Y + 30,  7, 18 },
        { -900,  900, -950, LOBBY_Y + 250, 15, 50 },
        {  900, -900, -670, LOBBY_Y - 80,  6, 26 },
    }

    for i, def in ipairs(asteroidDefs) do
        local sz   = def[5]
        local ast  = Instance.new("Part")
        ast.Name   = "Asteroid_" .. i
        ast.Shape  = Enum.PartType.Ball
        ast.Size   = Vector3.new(sz, sz * 0.7, sz * 0.55)
        ast.Position = Vector3.new(def[1], def[4], def[3])
        ast.Anchored  = true
        ast.CanCollide = false
        ast.Color  = Color3.fromRGB(math.random(85,130), math.random(80,120), math.random(65,100))
        ast.Material = Enum.Material.Rock
        ast.CastShadow = false
        ast.Parent = astFolder

        -- Slow spin via orientation offset (alternating per asteroid)
        local startCF = CFrame.new(def[1], def[4], def[3])
            * CFrame.Angles(math.random(0,360)/57.3, math.random(0,360)/57.3, 0)
        local endCF   = CFrame.new(def[2], def[4], def[3])
            * CFrame.Angles(math.random(0,360)/57.3, math.random(0,360)/57.3, 0)

        ast.CFrame = startCF

        -- Loop tween
        task.spawn(function()
            while ast.Parent do
                local tw = TweenService:Create(ast,
                    TweenInfo.new(def[6], Enum.EasingStyle.Linear),
                    { CFrame = endCF })
                tw:Play()
                tw.Completed:Wait()
                if not ast.Parent then break end
                ast.CFrame = startCF
            end
        end)
    end

    return astFolder
end

-- ============================================================
-- SPACE EVENTS (rare — every 3600 s = 1 hour, random type)
-- ============================================================
local function TriggerSupernova()
    print("[SpaceEvents] SUPERNOVA triggered")
    local nova = Instance.new("Part")
    nova.Name      = "SupernovaFlash"
    nova.Shape     = Enum.PartType.Ball
    nova.Size      = Vector3.new(50, 50, 50)
    nova.Position  = Vector3.new(-800, LOBBY_Y + 250, -900)
    nova.Anchored  = true
    nova.CanCollide = false
    nova.Color     = Color3.fromRGB(255, 240, 180)
    nova.Material  = Enum.Material.Neon
    nova.CastShadow = false
    nova.Parent    = workspace

    PL(nova, Color3.fromRGB(255, 240, 180), 10, 600)

    -- Grow and fade
    local grow = TweenService:Create(nova,
        TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(600, 600, 600), Transparency = 0.0 })
    grow:Play()
    grow.Completed:Wait()

    local fade = TweenService:Create(nova,
        TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = Vector3.new(800, 800, 800), Transparency = 1.0 })
    fade:Play()
    fade.Completed:Wait()
    nova:Destroy()
end

local function TriggerCometFlyby()
    print("[SpaceEvents] COMET FLYBY triggered")
    local comet = Instance.new("Part")
    comet.Name      = "Comet"
    comet.Shape     = Enum.PartType.Ball
    comet.Size      = Vector3.new(20, 12, 12)
    comet.Position  = Vector3.new(-1200, LOBBY_Y + 300, -400)
    comet.Anchored  = true
    comet.CanCollide = false
    comet.Color     = Color3.fromRGB(200, 230, 255)
    comet.Material  = Enum.Material.Neon
    comet.CastShadow = false
    comet.Parent    = workspace

    PL(comet, Color3.fromRGB(200, 230, 255), 6, 120)

    -- Tail
    local tail = Instance.new("Part")
    tail.Size   = Vector3.new(3, 3, 180)
    tail.Anchored = true
    tail.CanCollide = false
    tail.Color  = Color3.fromRGB(180, 210, 255)
    tail.Material = Enum.Material.Neon
    tail.Transparency = 0.7
    tail.CastShadow = false
    tail.Parent = workspace

    local move = TweenService:Create(comet,
        TweenInfo.new(10, Enum.EasingStyle.Linear),
        { Position = Vector3.new(1200, LOBBY_Y + 200, -600) })
    move:Play()

    task.spawn(function()
        while comet.Parent and move.PlaybackState ~= Enum.PlaybackState.Completed do
            tail.CFrame = CFrame.new(comet.Position + Vector3.new(-90, 0, 0))
            task.wait()
        end
    end)

    move.Completed:Wait()
    comet:Destroy()
    tail:Destroy()
end

local function TriggerPlanetCollision()
    print("[SpaceEvents] PLANET COLLISION triggered")
    -- Two smaller spheres rush toward each other then explode
    local p1 = Instance.new("Part")
    p1.Shape     = Enum.PartType.Ball
    p1.Size      = Vector3.new(80,80,80)
    p1.Position  = Vector3.new(-700, LOBBY_Y + 350, -1100)
    p1.Anchored  = true
    p1.CanCollide = false
    p1.Color     = Color3.fromRGB(160, 100, 50)
    p1.Material  = Enum.Material.SmoothPlastic
    p1.Parent    = workspace

    local p2 = p1:Clone()
    p2.Position = Vector3.new(-400, LOBBY_Y + 350, -1100)
    p2.Color    = Color3.fromRGB(80, 110, 180)
    p2.Parent   = workspace

    local t1 = TweenService:Create(p1, TweenInfo.new(3, Enum.EasingStyle.Quad), { Position = Vector3.new(-550, LOBBY_Y+350, -1100) })
    local t2 = TweenService:Create(p2, TweenInfo.new(3, Enum.EasingStyle.Quad), { Position = Vector3.new(-550, LOBBY_Y+350, -1100) })
    t1:Play(); t2:Play()
    t1.Completed:Wait()

    -- Explosion flash
    p1:Destroy(); p2:Destroy()
    local blast = Instance.new("Part")
    blast.Shape    = Enum.PartType.Ball
    blast.Size     = Vector3.new(20,20,20)
    blast.Position = Vector3.new(-550, LOBBY_Y+350, -1100)
    blast.Anchored = true
    blast.CanCollide = false
    blast.Color    = Color3.fromRGB(255, 200, 80)
    blast.Material = Enum.Material.Neon
    blast.Parent   = workspace
    PL(blast, Color3.fromRGB(255, 200, 80), 12, 800)

    TweenService:Create(blast, TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(500,500,500), Transparency = 1 }):Play()
    Debris:AddItem(blast, 7)
end

local function TriggerMeteorShower()
    print("[SpaceEvents] METEOR SHOWER triggered")
    for i = 1, 12 do
        task.delay(i * 0.4, function()
            local met = Instance.new("Part")
            met.Shape    = Enum.PartType.Ball
            met.Size     = Vector3.new(8,8,8)
            met.Position = Vector3.new(math.random(-500,500), LOBBY_Y+600, math.random(-800,-400))
            met.Anchored = true
            met.CanCollide = false
            met.Color    = Color3.fromRGB(255, 160, 60)
            met.Material = Enum.Material.Neon
            met.Parent   = workspace
            PL(met, Color3.fromRGB(255,160,60), 4, 50)

            TweenService:Create(met, TweenInfo.new(2, Enum.EasingStyle.Quad),
                { Position = met.Position + Vector3.new(math.random(-200,200), -700, -100),
                  Size     = Vector3.new(2,2,2),
                  Transparency = 0.9 }):Play()
            Debris:AddItem(met, 2.5)
        end)
    end
end

local spaceEvents = { TriggerSupernova, TriggerCometFlyby, TriggerPlanetCollision, TriggerMeteorShower }

-- ============================================================
-- HANGAR STRUCTURE
-- ============================================================
function SpaceshipLobby.GenerateVisualSpaceship()
    local old = workspace:FindFirstChild("SpaceshipLobby")
    if old then old:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name   = "SpaceshipLobby"
    folder.Parent = workspace

    local DARK   = Color3.fromRGB(22,  25,  32)
    local MID    = Color3.fromRGB(38,  43,  55)
    local LIGHT  = Color3.fromRGB(65,  72,  90)
    local CYAN   = Color3.fromRGB(0,   200, 255)
    local GOLD   = Color3.fromRGB(220, 175, 50)
    local GREEN  = Color3.fromRGB(50,  210, 100)
    local PURPLE = Color3.fromRGB(120, 60,  255)
    local SKIN   = Color3.fromRGB(255, 205, 168)

    local wallCY = FLOOR_TOP + WALL_H / 2

    -- ── FLOOR ──────────────────────────────────────────────────
    Block(folder, "HangarFloor",
        Vector3.new(HALL_W + 30, 2, HALL_D + 30),
        Vector3.new(0, LOBBY_Y, 0), DARK)

    -- Neon grid (cyan lines)
    for i = -7, 7 do
        local hL = Block(folder, "FH_"..i, Vector3.new(HALL_W-8, 0.12, 1.4),
            Vector3.new(0, FLOOR_TOP, i*25), CYAN, Enum.Material.Neon, 0, true)
        hL.CastShadow = false
        local vL = Block(folder, "FV_"..i, Vector3.new(1.4, 0.12, HALL_D-8),
            Vector3.new(i*38, FLOOR_TOP, 0), CYAN, Enum.Material.Neon, 0, true)
        vL.CastShadow = false
    end

    -- ── CEILING ────────────────────────────────────────────────
    Block(folder, "HangarCeiling",
        Vector3.new(HALL_W + 30, 3, HALL_D + 30),
        Vector3.new(0, FLOOR_TOP + WALL_H, 0), DARK)

    -- Ceiling light panels (8 rows — bright for dark ambient)
    for i = -4, 4 do
        local panel = Block(folder, "CLight_"..i,
            Vector3.new(88, 0.5, 12),
            Vector3.new(i*58, FLOOR_TOP + WALL_H - 2.5, 0),
            Color3.fromRGB(210, 225, 255), Enum.Material.Neon, 0, true)
        panel.CastShadow = false
        PL(panel, Color3.fromRGB(210, 225, 255), 5, 100)
    end

    -- ── WALLS ──────────────────────────────────────────────────
    Block(folder, "WallNorth", Vector3.new(HALL_W, WALL_H, WALL_T),
        Vector3.new(0, wallCY, -HALL_D/2), MID)
    Block(folder, "WallSouth", Vector3.new(HALL_W, WALL_H, WALL_T),
        Vector3.new(0, wallCY,  HALL_D/2), MID)
    Block(folder, "WallEast",  Vector3.new(WALL_T, WALL_H, HALL_D),
        Vector3.new( HALL_W/2, wallCY, 0), MID)
    Block(folder, "WallWest",  Vector3.new(WALL_T, WALL_H, HALL_D),
        Vector3.new(-HALL_W/2, wallCY, 0), MID)

    -- Wall base glow strips (4 walls)
    local wallGlows = {
        { Vector3.new(HALL_W-4, 2, 0.4),   Vector3.new(0, FLOOR_TOP+1, -HALL_D/2+1) },
        { Vector3.new(HALL_W-4, 2, 0.4),   Vector3.new(0, FLOOR_TOP+1,  HALL_D/2-1) },
        { Vector3.new(0.4, 2, HALL_D-4),   Vector3.new(-HALL_W/2+1, FLOOR_TOP+1, 0) },
        { Vector3.new(0.4, 2, HALL_D-4),   Vector3.new( HALL_W/2-1, FLOOR_TOP+1, 0) },
    }
    for i, g in ipairs(wallGlows) do
        local gw = Block(folder, "WallGlow_"..i, g[1], g[2], CYAN, Enum.Material.Neon, 0, true)
        gw.CastShadow = false
        PL(gw, CYAN, 2, 50)
    end

    -- ── PILLARS ────────────────────────────────────────────────
    for i, g in ipairs({
        {-210,-120},{-210,0},{-210,120},
        {   0,-120},{   0,120},
        { 210,-120},{ 210,0},{ 210,120},
    }) do
        Block(folder, "Pillar_"..i, Vector3.new(10, WALL_H, 10),
            Vector3.new(g[1], wallCY, g[2]), LIGHT)
        local pt = Block(folder, "PTop_"..i, Vector3.new(14, 2, 14),
            Vector3.new(g[1], FLOOR_TOP + WALL_H - 2, g[2]), GOLD, Enum.Material.Neon, 0, true)
        pt.CastShadow = false
        PL(pt, GOLD, 3, 35)
        local pb = Block(folder, "PBase_"..i, Vector3.new(13, 1.5, 13),
            Vector3.new(g[1], FLOOR_TOP+1, g[2]), CYAN, Enum.Material.Neon, 0, true)
        pb.CastShadow = false
    end

    -- ── NORTH WALL: Space Windows ──────────────────────────────
    for i = -2, 2 do
        -- Glass pane
        Block(folder, "SpaceWindow_"..i, Vector3.new(58, 28, 0.8),
            Vector3.new(i*110, wallCY+8, -HALL_D/2+1),
            Color3.fromRGB(8, 20, 60), Enum.Material.Glass, 0.18)

        -- Window frame bars
        for fi, fw in ipairs({
            { Vector3.new(60,2.5,1.5), Vector3.new(i*110, wallCY+23,   -HALL_D/2+1) },
            { Vector3.new(60,2.5,1.5), Vector3.new(i*110, wallCY-6,    -HALL_D/2+1) },
            { Vector3.new(2.5,30,1.5), Vector3.new(i*110-31, wallCY+8, -HALL_D/2+1) },
            { Vector3.new(2.5,30,1.5), Vector3.new(i*110+31, wallCY+8, -HALL_D/2+1) },
        }) do
            Block(folder, "WF_"..i.."_"..fi, fw[1], fw[2], LIGHT)
        end
    end

    -- ── SPAWN LOCATION (invisible, centered, safe) ─────────────
    local spawn = Instance.new("SpawnLocation")
    spawn.Name         = "LobbySpawn"
    spawn.Size         = Vector3.new(50, 1, 50)
    spawn.Position     = Vector3.new(0, FLOOR_TOP, 0)
    spawn.Anchored     = true
    spawn.Transparency = 1
    spawn.CanCollide   = true
    spawn.TeamColor    = BrickColor.new("White")
    spawn.AllowTeamChangeOnTouch = false
    spawn.Duration     = 0
    spawn.Parent       = folder

    -- ── ENERGY CORE (ceiling drop) ─────────────────────────────
    local core = Block(folder, "Core", Vector3.new(5,5,5),
        Vector3.new(0, FLOOR_TOP + WALL_H - 12, 0), CYAN, Enum.Material.Neon, 0, true)
    core.CastShadow = false
    PL(core, CYAN, 10, 200)

    local beam = Block(folder, "CoreBeam", Vector3.new(2, WALL_H - 18, 2),
        Vector3.new(0, FLOOR_TOP + 10, 0), CYAN, Enum.Material.Neon, 0.65, true)
    beam.CastShadow = false
    PL(beam, CYAN, 4, 80)

    for i = 0, 5 do
        local a = math.rad(i*60)
        local ring = Block(folder, "CoreRing_"..i, Vector3.new(1.2, 1.2, 22),
            Vector3.new(math.sin(a)*11, FLOOR_TOP + WALL_H - 12, math.cos(a)*11),
            GOLD, Enum.Material.Neon, 0, true)
        ring.CastShadow = false
    end

    -- ── NPC TRADERS ────────────────────────────────────────────
    SpaceshipLobby.BuildQMStation(folder, SKIN, GOLD, CYAN)
    SpaceshipLobby.BuildApoStation(folder, SKIN, GREEN, CYAN)
    SpaceshipLobby.BuildPortalStation(folder, SKIN, PURPLE)
    SpaceshipLobby.BuildMarketCounter(folder, CYAN)
    SpaceshipLobby.BuildQuestBoard(folder)
    SpaceshipLobby.BuildControlRoom(folder, CYAN, GREEN)
    SpaceshipLobby.BuildExtractionPad(folder, GREEN)

    -- ── SPACE BACKGROUND ───────────────────────────────────────
    BuildSpaceBackground(folder)
    BuildAnimatedAsteroids(folder)

    -- ── HOURLY RARE EVENTS ─────────────────────────────────────
    task.spawn(function()
        while folder.Parent do
            task.wait(3600)  -- 1 hour
            local idx = math.random(1, #spaceEvents)
            task.spawn(spaceEvents[idx])
        end
    end)

    print("[SpaceshipLobby] Hangar generated at Y=" .. LOBBY_Y)
    return folder
end

-- ============================================================
-- QUARTERMASTER STATION
-- ============================================================
function SpaceshipLobby.BuildQMStation(folder, SKIN, GOLD, CYAN)
    local bx, bz = 170, -100

    Block(folder, "QM_BackWall", Vector3.new(65, 32, 4),
        Vector3.new(bx, FLOOR_TOP+16, bz-26), Color3.fromRGB(28,33,45))

    local ctr = Block(folder, "QM_Counter", Vector3.new(52, 3, 13),
        Vector3.new(bx, FLOOR_TOP+1.5, bz-10), Color3.fromRGB(32,38,52))
    Block(folder, "QM_CTop", Vector3.new(52.5,0.4,13.5),
        Vector3.new(bx, FLOOR_TOP+3.2, bz-10), CYAN, Enum.Material.Neon, 0, true).CastShadow = false
    PL(ctr, CYAN, 2, 30)

    -- Weapon racks on counter (simple rods)
    for i = -3, 3 do
        Block(folder, "QM_Gun_"..i, Vector3.new(0.4, 0.5, 6),
            Vector3.new(bx + i*6, FLOOR_TOP+3.6, bz-10), Color3.fromRGB(18,18,18))
    end

    local sign = Block(folder, "QM_Sign", Vector3.new(52,7,0.8),
        Vector3.new(bx, FLOOR_TOP+19, bz-28), Color3.fromRGB(12,15,24))
    SG(sign, Enum.NormalId.Front,
        "QUARTERMASTER RIGGS\nSenjata & Armor", 28, GOLD)

    local spot = Block(folder, "QM_Spot", Vector3.new(2,0.5,2),
        Vector3.new(bx, FLOOR_TOP+20, bz-10), GOLD, Enum.Material.Neon, 0, true)
    spot.CastShadow = false
    local sl = Instance.new("SpotLight")
    sl.Face = Enum.NormalId.Bottom; sl.Brightness = 6
    sl.Range = 40; sl.Angle = 45; sl.Color = GOLD; sl.Parent = spot

    BuildR6NPC(folder, "Quartermaster Riggs",
        Vector3.new(bx, FLOOR_TOP, bz - 20),
        SKIN,
        Color3.fromRGB(35, 50, 85),   -- shirt (military blue)
        Color3.fromRGB(28, 32, 50),   -- pants (dark)
        "Buka Toko Senjata [E]",
        "Prajurit! Koleksi senjata terbaik ada di sini. Siap tempur?",
        "quartermaster"
    )
end

-- ============================================================
-- APOTHECARY STATION
-- ============================================================
function SpaceshipLobby.BuildApoStation(folder, SKIN, GREEN, CYAN)
    local bx, bz = -170, -100

    Block(folder, "APO_BackWall", Vector3.new(65, 32, 4),
        Vector3.new(bx, FLOOR_TOP+16, bz-26), Color3.fromRGB(18,30,22))

    local ctr = Block(folder, "APO_Counter", Vector3.new(52, 3, 13),
        Vector3.new(bx, FLOOR_TOP+1.5, bz-10), Color3.fromRGB(20,35,27))
    Block(folder, "APO_CTop", Vector3.new(52.5,0.4,13.5),
        Vector3.new(bx, FLOOR_TOP+3.2, bz-10), GREEN, Enum.Material.Neon, 0, true).CastShadow = false
    PL(ctr, GREEN, 2, 30)

    -- Glowing potions
    local potCols = {
        Color3.fromRGB(255,50,50), Color3.fromRGB(50,220,100),
        Color3.fromRGB(80,130,255), Color3.fromRGB(255,200,0), Color3.fromRGB(255,100,200),
    }
    for i, col in ipairs(potCols) do
        local bot = Block(folder, "APO_Potion_"..i, Vector3.new(1.6,2.4,1.6),
            Vector3.new(bx - 9 + i*4.2, FLOOR_TOP+4.6, bz-10), col, Enum.Material.Neon, 0, true)
        bot.CastShadow = false
        PL(bot, col, 2, 12)
    end

    local sign = Block(folder, "APO_Sign", Vector3.new(52,7,0.8),
        Vector3.new(bx, FLOOR_TOP+19, bz-28), Color3.fromRGB(10,22,15))
    SG(sign, Enum.NormalId.Front,
        "APOTHECARY VAEL\nObat & Sihir", 28, GREEN)

    local spot = Block(folder, "APO_Spot", Vector3.new(2,0.5,2),
        Vector3.new(bx, FLOOR_TOP+20, bz-10), GREEN, Enum.Material.Neon, 0, true)
    spot.CastShadow = false
    local sl = Instance.new("SpotLight")
    sl.Face = Enum.NormalId.Bottom; sl.Brightness = 6
    sl.Range = 40; sl.Angle = 45; sl.Color = GREEN; sl.Parent = spot

    BuildR6NPC(folder, "Apothecary Vael",
        Vector3.new(bx, FLOOR_TOP, bz - 20),
        SKIN,
        Color3.fromRGB(55, 30, 80),  -- shirt (purple robe)
        Color3.fromRGB(35, 18, 55),
        "Buka Toko Obat [E]",
        "Tubuhmu adalah senjatamu. Rawat dia baik-baik, petualang.",
        "apothecary"
    )
end

-- ============================================================
-- PORTAL STATION
-- ============================================================
function SpaceshipLobby.BuildPortalStation(folder, SKIN, PURPLE)
    local px, pz = 0, -160

    -- Arch pillars
    for _, sx in ipairs({-20, 20}) do
        local pillar = Block(folder, "PortalPillar_"..sx, Vector3.new(6, 36, 6),
            Vector3.new(px+sx, FLOOR_TOP+18, pz), PURPLE, Enum.Material.Neon, 0, true)
        pillar.CastShadow = false
        PL(pillar, PURPLE, 3, 40)
    end
    local topBar = Block(folder, "PortalTop", Vector3.new(46, 6, 6),
        Vector3.new(px, FLOOR_TOP+39, pz), PURPLE, Enum.Material.Neon, 0, true)
    topBar.CastShadow = false

    -- Void surface
    local void = Block(folder, "PortalVoid", Vector3.new(32, 30, 0.6),
        Vector3.new(px, FLOOR_TOP+16, pz), Color3.fromRGB(35,8,100), Enum.Material.Neon, 0.3, true)
    void.CastShadow = false
    PL(void, PURPLE, 8, 80)

    -- Void particles (dots)
    for i = 1, 14 do
        local dot = Block(folder, "VoidDot_"..i, Vector3.new(0.7,0.7,0.7),
            Vector3.new(px+math.random(-14,14), FLOOR_TOP+math.random(3,30), pz-0.9),
            Color3.fromRGB(200,150,255), Enum.Material.Neon, 0, true)
        dot.CastShadow = false
    end

    local sign = Block(folder, "PortalSign", Vector3.new(55,8,0.8),
        Vector3.new(px, FLOOR_TOP+50, pz), Color3.fromRGB(10,6,22))
    SG(sign, Enum.NormalId.Front,
        "PORTAL DOMAIN FANTASI\nMasuk ke Kalimantan", 28, Color3.fromRGB(200,150,255))

    -- ProximityPrompt on void
    local pp = Instance.new("ProximityPrompt")
    pp.ActionText = "Masuk Kalimantan"
    pp.ObjectText = "Portal Fantasi"
    pp.MaxActivationDistance = 16
    pp.Parent = void

    BuildR6NPC(folder, "Portal Keeper",
        Vector3.new(px, FLOOR_TOP, pz + 16),
        SKIN,
        Color3.fromRGB(42, 16, 80),
        Color3.fromRGB(28, 10, 55),
        "Bicara dengan Penjaga [E]",
        "Kalimantan menunggumu. Pastikan inventorimu penuh sebelum masuk.",
        nil  -- no shop
    )
end

-- ============================================================
-- FLEA MARKET COUNTER
-- ============================================================
function SpaceshipLobby.BuildMarketCounter(folder, CYAN)
    local mz = 130
    Block(folder, "Market_Counter", Vector3.new(200, 3, 14),
        Vector3.new(0, FLOOR_TOP+1.5, mz), Color3.fromRGB(25,30,42))
    local top = Block(folder, "Market_CTop", Vector3.new(200.5,0.5,14.5),
        Vector3.new(0, FLOOR_TOP+3.3, mz), CYAN, Enum.Material.Neon, 0, true)
    top.CastShadow = false
    PL(top, CYAN, 3, 50)

    local sign = Block(folder, "Market_Sign", Vector3.new(160,8,0.8),
        Vector3.new(0, FLOOR_TOP+14, mz-7.5), Color3.fromRGB(10,12,22))
    SG(sign, Enum.NormalId.Front,
        "FLEA MARKET — Jual & Beli antar Pemain [F untuk buka]", 24, CYAN)

    -- Stalls with display items
    for i = -3, 3 do
        Block(folder, "Stall_"..i, Vector3.new(26, 0.3, 8),
            Vector3.new(i*32, FLOOR_TOP+3.5, mz), Color3.fromRGB(35,42,56))
        for j = 1, 3 do
            Block(folder, "StallItem_"..i.."_"..j, Vector3.new(2.5, 2.5, 2.5),
                Vector3.new(i*32 - 4 + j*4, FLOOR_TOP+4.7, mz),
                Color3.fromHSV(math.random()/1, 0.7, 0.9), Enum.Material.SmoothPlastic)
        end
    end
end

-- ============================================================
-- QUEST BOARD
-- ============================================================
function SpaceshipLobby.BuildQuestBoard(folder)
    local qx, qz = -260, 50
    Block(folder, "QB_Back", Vector3.new(6, 36, 65),
        Vector3.new(qx-3, FLOOR_TOP+18, qz), Color3.fromRGB(30,24,16))

    local board = Block(folder, "QB_Face", Vector3.new(0.4, 31, 60),
        Vector3.new(qx, FLOOR_TOP+16, qz), Color3.fromRGB(18,14,8))
    PL(board, Color3.fromRGB(255,200,100), 2, 25)

    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Right
    sg.CanvasSize = Vector2.new(480, 620)
    sg.Parent = board

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(16,12,6)
    bg.Parent = sg

    local titleQ = Instance.new("TextLabel")
    titleQ.Size = UDim2.new(1,0,0,72); titleQ.BackgroundColor3 = Color3.fromRGB(100,65,12)
    titleQ.Text = "PAPAN MISI HARIAN"; titleQ.Font = Enum.Font.GothamBold
    titleQ.TextSize = 36; titleQ.TextColor3 = Color3.fromRGB(255,220,120)
    titleQ.TextXAlignment = Enum.TextXAlignment.Center
    titleQ.TextYAlignment = Enum.TextYAlignment.Center
    titleQ.Parent = bg

    for i, q in ipairs({
        "Ekstrak hidup dari Kalimantan (1x)",
        "Bunuh 5 monster zona hutan dalam",
        "Temukan 1 Gold Bar — bawa keluar",
        "Selamat dari serangan meteor",
        "Kumpulkan 10 Healing Herb",
        "Jual 3 item di Flea Market",
    }) do
        local ql = Instance.new("TextLabel")
        ql.Size = UDim2.new(1,0,0,86)
        ql.Position = UDim2.new(0,0,0, 72+(i-1)*90)
        ql.BackgroundColor3 = i%2==0 and Color3.fromRGB(22,18,10) or Color3.fromRGB(16,12,6)
        ql.Text = i .. ". " .. q
        ql.Font = Enum.Font.Gotham; ql.TextSize = 22
        ql.TextColor3 = Color3.fromRGB(215,205,175)
        ql.TextWrapped = true; ql.TextXAlignment = Enum.TextXAlignment.Left
        ql.Parent = bg
        local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0,10); pad.Parent = ql
    end
end

-- ============================================================
-- CONTROL ROOM
-- ============================================================
function SpaceshipLobby.BuildControlRoom(folder, CYAN, GREEN)
    for i = -2, 2 do
        local cx = 255
        local terminal = Block(folder, "Terminal_"..i, Vector3.new(11,16,6),
            Vector3.new(cx, FLOOR_TOP+8, i*26), Color3.fromRGB(16,20,30))
        PL(terminal, CYAN, 1, 20)

        local screen = Block(folder, "Screen_"..i, Vector3.new(8,10,0.4),
            Vector3.new(cx-4.9, FLOOR_TOP+9, i*26), Color3.fromRGB(0,140,210),
            Enum.Material.Neon, 0.15, true)
        screen.CastShadow = false
        PL(screen, CYAN, 3, 25)

        local sg2 = Instance.new("SurfaceGui")
        sg2.Face = Enum.NormalId.Right; sg2.CanvasSize = Vector2.new(320,400)
        sg2.Parent = screen
        local scl = Instance.new("TextLabel")
        scl.Size = UDim2.new(1,0,1,0); scl.BackgroundTransparency = 1
        scl.Text = "APEX v9.1\nSTATUS: ONLINE\nZONE: KALIMANTAN AKTIF\nWEATHER: --\nPLAYERS: --\nNEXT EVENT: --"
        scl.Font = Enum.Font.Code; scl.TextSize = 22
        scl.TextColor3 = Color3.fromRGB(100,255,180)
        scl.TextXAlignment = Enum.TextXAlignment.Left
        scl.TextYAlignment = Enum.TextYAlignment.Top
        scl.Parent = sg2
    end
end

-- ============================================================
-- EXTRACTION PAD
-- ============================================================
function SpaceshipLobby.BuildExtractionPad(folder, GREEN)
    local ex, ez = 180, 100
    local pad = Block(folder, "ExtractPad", Vector3.new(44,0.8,44),
        Vector3.new(ex, FLOOR_TOP+0.4, ez), GREEN, Enum.Material.Neon, 0.38, true)
    pad.CastShadow = false
    PL(pad, GREEN, 4, 60)

    for _, corner in ipairs({{-20,-20},{20,-20},{-20,20},{20,20}}) do
        local cp = Block(folder, "ExtCorner", Vector3.new(2.2,9,2.2),
            Vector3.new(ex+corner[1], FLOOR_TOP+4.5, ez+corner[2]),
            GREEN, Enum.Material.Neon, 0, true)
        cp.CastShadow = false
        PL(cp, GREEN, 3, 18)
    end

    local sign = Block(folder, "ExtractSign", Vector3.new(40,8,0.8),
        Vector3.new(ex, FLOOR_TOP+15, ez-22), Color3.fromRGB(8,18,10))
    SG(sign, Enum.NormalId.Front,
        "ZONA DEPOSIT EKSTRAKSI\nLoot & Rampasan Misi", 26, GREEN)

    local pp = Instance.new("ProximityPrompt")
    pp.ActionText = "Deposit Loot"
    pp.ObjectText = "Extraction Deposit"
    pp.MaxActivationDistance = 20
    pp.Parent = pad
end

-- ============================================================
-- PLAYER SAFETY: teleport if spawned below lobby
-- ============================================================
function SpaceshipLobby.InitializePlayerLobby(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.7)
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and root.Position.Y < 900 then
            root.CFrame = CFrame.new(0, FLOOR_TOP + 7, 0)
        end
    end)
end

-- ============================================================
-- INIT
-- ============================================================
function SpaceshipLobby.Initialize()
    SpaceshipLobby.GenerateVisualSpaceship()
    Players.PlayerAdded:Connect(SpaceshipLobby.InitializePlayerLobby)
    print("[SpaceshipLobby] Initialized.")
end

return SpaceshipLobby
