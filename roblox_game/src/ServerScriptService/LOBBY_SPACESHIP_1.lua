-- LOBBY_SPACESHIP_1.lua  (AAA rewrite — v4)
-- ▸ Transparent glass walls & ceiling → space visible from ALL sides
-- ▸ Asteroids OUTSIDE hangar at window-height → move across the view
-- ▸ Black dragon pillars (Decal on each face)
-- ▸ Planets, nebulae, hourly rare events (supernova / black hole / comet / collision)
-- ▸ Proper R6 humanoid NPCs — ProximityPrompt on HRP (always shows)
-- ▸ NPC shop fires OpenNPCShop RemoteEvent to client
-- ▸ Portal to Kalimantan — actual character teleport

local SpaceshipLobby = {}

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")
local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")

-- ── Constants ────────────────────────────────────────────────
local LOBBY_Y   = 1000
local FLOOR_TOP = LOBBY_Y + 1   -- Y of floor surface (player feet here)
local HALL_W    = 580           -- X width of hangar
local HALL_D    = 380           -- Z depth of hangar
local WALL_H    = 68            -- height of walls
local WALL_T    = 4             -- thickness of glass walls

-- Shorthand center heights
local CEIL_Y  = FLOOR_TOP + WALL_H          -- ceiling Y
local WALL_CY = FLOOR_TOP + WALL_H * 0.5   -- wall centre Y

-- Half extents
local HW = HALL_W * 0.5
local HD = HALL_D * 0.5

-- ── Colors ───────────────────────────────────────────────────
local BLACK  = Color3.fromRGB(5,   6,   10)
local DARK   = Color3.fromRGB(14,  16,  22)
local CYAN   = Color3.fromRGB(0,   210, 255)
local GOLD   = Color3.fromRGB(220, 175, 50)
local GREEN  = Color3.fromRGB(50,  215, 100)
local PURPLE = Color3.fromRGB(130, 60,  255)
local RED    = Color3.fromRGB(220, 60,  50)
local SKIN   = Color3.fromRGB(255, 205, 168)
local WHITE  = Color3.fromRGB(230, 235, 255)

-- Dragon decal – applied to all 6 faces of each pillar
-- (Use rbxassetid://262656850 — classic Roblox Chinese dragon texture)
local DRAGON_DECAL = "rbxassetid://262656850"

-- ── Generic helpers ──────────────────────────────────────────
local function P(folder, name, sz, cf, col, mat, trans, noCol)
    local p = Instance.new("Part")
    p.Name         = name
    p.Size         = sz
    p.CFrame       = (type(cf) == "vector" or type(cf) == "Vector3") and CFrame.new(cf) or cf
    if type(cf) == "Vector3" then p.CFrame = CFrame.new(cf) end
    p.Anchored     = true
    p.CanCollide   = not noCol
    p.Color        = col or DARK
    p.Material     = mat or Enum.Material.SmoothPlastic
    p.Transparency = trans or 0
    p.CastShadow   = (trans or 0) < 0.5
    p.Parent       = folder
    return p
end

local function PV(folder, name, sz, pos, col, mat, trans, noCol)
    return P(folder, name, sz, CFrame.new(pos), col, mat, trans, noCol)
end

local function Light(parent, col, bright, range)
    local l = Instance.new("PointLight")
    l.Color      = col
    l.Brightness = bright
    l.Range      = range
    l.Parent     = parent
end

local function SGui(part, face, text, sz, col, canvasSz)
    local sg = Instance.new("SurfaceGui")
    sg.Face       = face
    sg.CanvasSize = canvasSz or Vector2.new(800, 200)
    sg.Parent     = part
    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = text
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = sz or 32
    lbl.TextColor3        = col or GOLD
    lbl.TextWrapped       = true
    lbl.TextXAlignment    = Enum.TextXAlignment.Center
    lbl.TextYAlignment    = Enum.TextYAlignment.Center
    lbl.Parent            = sg
    return lbl
end

-- ── Black dragon pillar ──────────────────────────────────────
local function DragonPillar(folder, x, z)
    local pillar = PV(folder, "Pillar", Vector3.new(9, WALL_H + 2, 9),
        Vector3.new(x, WALL_CY, z), BLACK, Enum.Material.SmoothPlastic)

    -- Dragon decal on all faces
    for _, face in ipairs({
        Enum.NormalId.Front, Enum.NormalId.Back,
        Enum.NormalId.Left,  Enum.NormalId.Right,
    }) do
        local d = Instance.new("Decal")
        d.Face    = face
        d.Texture = DRAGON_DECAL
        d.Color3  = Color3.fromRGB(180, 140, 80)   -- golden tint
        d.Parent  = pillar
    end

    -- Gold cap top + bottom
    local cap = PV(folder, "PillarCap", Vector3.new(11, 2, 11),
        Vector3.new(x, CEIL_Y + 1, z), GOLD, Enum.Material.Neon, 0, true)
    cap.CastShadow = false
    Light(cap, GOLD, 2.5, 30)
    PV(folder, "PillarBase", Vector3.new(11, 1.5, 11),
        Vector3.new(x, FLOOR_TOP + 0.75, z), DARK, Enum.Material.Metal)
end

-- ── R6 Humanoid NPC ─────────────────────────────────────────
local function BuildNPC(folder, npcName, pos, shirtCol, pantsCol, npcType, dialog)
    -- pos = Vector3 where feet stand (Y = FLOOR_TOP)
    local model = Instance.new("Model")
    model.Name  = npcName

    local FY = pos.Y

    local function Part(nm, sz, cy, cx, cz, col, mat)
        local part = Instance.new("Part")
        part.Name        = nm
        part.Size        = sz
        part.CFrame      = CFrame.new(pos.X + (cx or 0), FY + cy, pos.Z + (cz or 0))
        part.Anchored    = true
        part.CanCollide  = false
        part.Color       = col or SKIN
        part.Material    = mat or Enum.Material.SmoothPlastic
        part.Parent      = model
        return part
    end

    -- HumanoidRootPart (invisible, CanCollide ON — ProximityPrompt target)
    local hrp = Instance.new("Part")
    hrp.Name        = "HumanoidRootPart"
    hrp.Size        = Vector3.new(2, 2, 1)
    hrp.CFrame      = CFrame.new(pos.X, FY + 3, pos.Z)
    hrp.Anchored    = true
    hrp.CanCollide  = true    -- must be true for ProximityPrompt to reliably show
    hrp.Transparency = 1
    hrp.Parent      = model

    -- Body (R6 standard proportions)
    local torso  = Part("Torso",    Vector3.new(2, 2, 1),  3,    0,    0,  shirtCol)
    local head   = Part("Head",     Vector3.new(2, 1, 1),  4.5,  0,    0,  SKIN)
    local lArm   = Part("Left Arm", Vector3.new(1, 2, 1),  3,   -1.5,  0,  shirtCol)
    local rArm   = Part("Right Arm",Vector3.new(1, 2, 1),  3,    1.5,  0,  shirtCol)
    local lLeg   = Part("Left Leg", Vector3.new(1, 2, 1),  1,   -0.5,  0,  pantsCol)
    local rLeg   = Part("Right Leg",Vector3.new(1, 2, 1),  1,    0.5,  0,  pantsCol)

    -- Boots
    Part("LeftBoot",  Vector3.new(1.1, 0.5, 1.1), 0.25, -0.5, 0, Color3.fromRGB(30,25,20))
    Part("RightBoot", Vector3.new(1.1, 0.5, 1.1), 0.25,  0.5, 0, Color3.fromRGB(30,25,20))

    -- Face
    local face = Instance.new("Decal")
    face.Face    = Enum.NormalId.Front
    face.Texture = "rbxassetid://1281287"
    face.Parent  = head

    -- Humanoid
    local hum = Instance.new("Humanoid")
    hum.DisplayName = npcName
    hum.MaxHealth   = 100
    hum.Health      = 100
    hum.WalkSpeed   = 0
    hum.JumpPower   = 0
    hum.Parent      = model

    -- Overhead name billboard
    local bill  = Instance.new("BillboardGui")
    bill.Size          = UDim2.new(0, 260, 0, 46)
    bill.StudsOffset   = Vector3.new(0, 2.8, 0)
    bill.AlwaysOnTop   = false
    bill.Parent        = head

    local bFrame = Instance.new("Frame")
    bFrame.Size                   = UDim2.new(1,0,1,0)
    bFrame.BackgroundColor3       = Color3.fromRGB(8,10,18)
    bFrame.BackgroundTransparency = 0.15
    bFrame.Parent                 = bill
    Instance.new("UICorner", bFrame).CornerRadius = UDim.new(0,7)

    local nL = Instance.new("TextLabel")
    nL.Size      = UDim2.new(1,-6,1,0); nL.Position = UDim2.new(0,3,0,0)
    nL.BackgroundTransparency = 1
    nL.Text      = npcName
    nL.Font      = Enum.Font.GothamBold
    nL.TextSize  = 16; nL.TextColor3 = GOLD
    nL.TextXAlignment = Enum.TextXAlignment.Center
    nL.TextYAlignment = Enum.TextYAlignment.Center
    nL.Parent    = bFrame

    -- ProximityPrompt on HRP (invisible but always detectable)
    local pp = Instance.new("ProximityPrompt")
    if npcType then
        pp.ActionText  = "Buka Toko [E]"
        pp.ObjectText  = npcName
    else
        pp.ActionText  = "Bicara [E]"
        pp.ObjectText  = npcName
    end
    pp.MaxActivationDistance = 14
    pp.HoldDuration          = 0
    pp.RequiresLineOfSight   = false
    pp.Parent                = hrp

    pp.Triggered:Connect(function(plr)
        -- Fire shop event to client
        if npcType then
            local evFolder = RS:FindFirstChild("Events")
            if evFolder then
                local shopEv = evFolder:FindFirstChild("OpenNPCShop")
                if shopEv then shopEv:FireClient(plr, npcType) end
            end
        end

        -- Dialog bubble (5 s)
        local bbl = Instance.new("BillboardGui")
        bbl.Size        = UDim2.new(0, 310, 0, 85)
        bbl.StudsOffset = Vector3.new(0, 5.2, 0)
        bbl.Parent      = head
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1,0,1,0)
        bg.BackgroundColor3 = Color3.fromRGB(8,10,18)
        bg.BackgroundTransparency = 0.05
        bg.Parent = bbl
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0,9)
        local dL = Instance.new("TextLabel")
        dL.Size = UDim2.new(1,-12,1,0); dL.Position = UDim2.new(0,6,0,0)
        dL.BackgroundTransparency = 1
        dL.Text = dialog
        dL.Font = Enum.Font.Gotham; dL.TextSize = 13
        dL.TextColor3 = WHITE; dL.TextWrapped = true
        dL.TextXAlignment = Enum.TextXAlignment.Left
        dL.TextYAlignment = Enum.TextYAlignment.Center
        dL.Parent = bg
        Debris:AddItem(bbl, 5)
    end)

    model.PrimaryPart = hrp
    model.Parent      = folder
    return model
end

-- ════════════════════════════════════════════════════════════
-- SPACE BACKGROUND  (outside the glass hangar)
-- ════════════════════════════════════════════════════════════
local function BuildSpaceBackground(folder)
    local spaceF = Instance.new("Folder")
    spaceF.Name   = "Space"
    spaceF.Parent = folder

    -- ── Giant black void sphere — blocks default sky color ──
    -- Roblox renders inside of a SmoothPlastic sphere as its inner surface
    -- Use Neon material + black = absorbs all light → appears black from inside
    local void = Instance.new("Part")
    void.Name         = "VoidSphere"
    void.Shape        = Enum.PartType.Ball
    void.Size         = Vector3.new(8000, 8000, 8000)
    void.Position     = Vector3.new(0, LOBBY_Y, 0)
    void.Anchored     = true
    void.CanCollide   = false
    void.Color        = Color3.fromRGB(0, 0, 0)
    void.Material     = Enum.Material.SmoothPlastic
    void.Transparency = 0
    void.CastShadow   = false
    void.Parent       = spaceF

    -- ── Stars (neon white dots spread inside the void) ───────
    for i = 1, 300 do
        local ang   = math.random() * math.pi * 2
        local elev  = (math.random() - 0.5) * math.pi
        local dist  = math.random(600, 3800)
        local sx    = math.cos(elev) * math.cos(ang) * dist
        local sy    = math.sin(elev) * dist + LOBBY_Y
        local sz    = math.cos(elev) * math.sin(ang) * dist
        local ssz   = math.random(2, 7) * 0.3
        local star  = Instance.new("Part")
        star.Name   = "Star_"..i
        star.Shape  = Enum.PartType.Ball
        star.Size   = Vector3.new(ssz, ssz, ssz)
        star.Position = Vector3.new(sx, sy, sz)
        star.Anchored = true; star.CanCollide = false
        star.Color  = Color3.fromRGB(220, 225, 255)
        star.Material = Enum.Material.Neon
        star.CastShadow = false; star.Transparency = 0
        star.Parent = spaceF
    end

    -- ── Planets ──────────────────────────────────────────────
    local planetDefs = {
        -- pos,                                  radius, color,                       haRing
        {Vector3.new(-950, LOBBY_Y+220, -1100),  140,   Color3.fromRGB(190,130,65),  true },  -- Jupiter-like (with rings)
        {Vector3.new( 850, LOBBY_Y- 80, -1200),   90,   Color3.fromRGB(65, 95,195),  false},  -- Ice giant
        {Vector3.new(-350, LOBBY_Y+480, -1500),   65,   Color3.fromRGB(190, 65, 55), false},  -- Mars-like
        {Vector3.new( 500, LOBBY_Y-200, -1300),   38,   Color3.fromRGB(155,150,140), false},  -- Rocky moon
        {Vector3.new(-700, LOBBY_Y+700,  1100),  110,   Color3.fromRGB(95, 170, 85), false},  -- Emerald planet (south side)
        {Vector3.new( 900, LOBBY_Y+500,  1200),   75,   Color3.fromRGB(180, 60,170), false},  -- Purple gas (south)
    }
    for i, pd in ipairs(planetDefs) do
        local planet = Instance.new("Part")
        planet.Name  = "Planet_"..i
        planet.Shape = Enum.PartType.Ball
        local d      = pd[2] * 2
        planet.Size  = Vector3.new(d, d, d)
        planet.Position  = pd[1]
        planet.Anchored  = true; planet.CanCollide = false
        planet.Color     = pd[3]; planet.Material = Enum.Material.SmoothPlastic
        planet.CastShadow = false
        planet.Parent    = spaceF
        Light(planet, pd[3], 1.5, pd[2] * 2.8)

        if pd[4] then   -- ring system
            local ring = Instance.new("Part")
            ring.Shape   = Enum.PartType.Cylinder
            local rw     = pd[2] * 3.4
            ring.Size    = Vector3.new(4, rw, rw)
            ring.CFrame  = CFrame.new(pd[1]) * CFrame.Angles(math.rad(22), 0, math.rad(6))
            ring.Anchored = true; ring.CanCollide = false
            ring.Color   = Color3.fromRGB(210, 170, 100)
            ring.Material = Enum.Material.SmoothPlastic
            ring.Transparency = 0.50; ring.CastShadow = false
            ring.Parent  = spaceF
        end
    end

    -- ── Nebula clouds ─────────────────────────────────────────
    local nebulae = {
        {Vector3.new(  0, LOBBY_Y+650, -1800), 500, Color3.fromRGB(80,  30, 130), 0.88},
        {Vector3.new(-1100,LOBBY_Y+400, -900), 380, Color3.fromRGB(30,  80, 155), 0.88},
        {Vector3.new( 1100,LOBBY_Y-100,-1000), 420, Color3.fromRGB(150, 55,  30), 0.90},
        {Vector3.new(   0, LOBBY_Y+500,  1600),450, Color3.fromRGB(40, 130,  80), 0.88},
    }
    for i, nd in ipairs(nebulae) do
        local neb = Instance.new("Part")
        neb.Name   = "Nebula_"..i
        neb.Shape  = Enum.PartType.Ball
        neb.Size   = Vector3.new(nd[2]*2, nd[2]*1.3, nd[2]*1.7)
        neb.Position = nd[1]; neb.Anchored = true; neb.CanCollide = false
        neb.Color  = nd[3]; neb.Material = Enum.Material.Neon
        neb.Transparency = nd[4]; neb.CastShadow = false
        neb.Parent = spaceF
        Light(neb, nd[3], 0.7, nd[2] * 1.6)
    end

    return spaceF
end

-- ── Animated asteroids (OUTSIDE hangar, at window height) ───
-- Move in ONE direction across the view, then loop.
local function BuildAnimatedAsteroids(folder)
    local astF = Instance.new("Folder")
    astF.Name   = "MovingAsteroids"
    astF.Parent = folder

    -- Window-height midpoint: visible through glass walls
    local midY  = FLOOR_TOP + WALL_H * 0.45   -- ≈ FLOOR_TOP + 30

    local defs = {
        -- startX/Z, endX/Z, fixedZ/X, fixedY,        size, duration, axis
        -- NORTH side (Z=-HD-200 to -HD-600) moving West→East
        { sx=-1100, ex=1100, fz=-HD-280, fy=midY+10,  sz=9,  dur=22, axis="Z" },
        { sx= 1100, ex=-1100,fz=-HD-420, fy=midY-15,  sz=6,  dur=17, axis="Z" },
        { sx=-1100, ex=1100, fz=-HD-560, fy=midY+35,  sz=13, dur=30, axis="Z" },
        -- SOUTH side (Z=+HD+200 to +HD+500) moving East→West
        { sx= 1100, ex=-1100,fz= HD+250, fy=midY+5,   sz=8,  dur=25, axis="Z" },
        { sx=-1100, ex=1100, fz= HD+400, fy=midY-20,  sz=11, dur=32, axis="Z" },
        -- EAST side (X=HW+200 to HW+500) moving South→North
        { sx=-HD-200,ex=HD+200, fz=HW+280, fy=midY+20, sz=7, dur=20, axis="X" },
        -- WEST side (X=-HW-200 to -HW-500) moving North→South
        { sx=HD+200, ex=-HD-200,fz=-HW-300,fy=midY+8,  sz=10, dur=28, axis="X" },
        -- ABOVE ceiling (Y=CEIL_Y+80 to +200) moving any direction
        { sx=-1100, ex=1100, fz=-500, fy=CEIL_Y+100, sz=18, dur=40, axis="Z" },
        { sx= 1100, ex=-1100,fz= 400, fy=CEIL_Y+160, sz=12, dur=35, axis="Z" },
    }

    for i, d in ipairs(defs) do
        local asz = d.sz
        local ast = Instance.new("Part")
        ast.Name     = "Asteroid_"..i
        ast.Shape    = Enum.PartType.Ball
        ast.Size     = Vector3.new(asz, asz*0.72, asz*0.58)
        ast.Anchored = true; ast.CanCollide = false
        ast.Color    = Color3.fromRGB(
            math.random(80,130), math.random(75,115), math.random(60,100))
        ast.Material = Enum.Material.Rock
        ast.CastShadow = false

        local startCF, endCF
        if d.axis == "Z" then
            -- moves along X axis, fixed Z and Y
            startCF = CFrame.new(d.sx, d.fy, d.fz)
                * CFrame.Angles(math.random()*6, math.random()*6, math.random()*6)
            endCF   = CFrame.new(d.ex, d.fy, d.fz)
                * CFrame.Angles(math.random()*6, math.random()*6, math.random()*6)
        else
            -- moves along Z axis, fixed X and Y
            startCF = CFrame.new(d.fz, d.fy, d.sx)
                * CFrame.Angles(math.random()*6, math.random()*6, math.random()*6)
            endCF   = CFrame.new(d.fz, d.fy, d.ex)
                * CFrame.Angles(math.random()*6, math.random()*6, math.random()*6)
        end

        ast.CFrame = startCF
        ast.Parent = astF

        -- Staggered start so they don't all begin at the same position
        local offset = math.random() * d.dur

        task.spawn(function()
            task.wait(offset)
            while ast.Parent do
                local tw = TweenService:Create(ast,
                    TweenInfo.new(d.dur, Enum.EasingStyle.Linear),
                    { CFrame = endCF })
                tw:Play()
                tw.Completed:Wait()
                if not ast.Parent then break end
                ast.CFrame = startCF
            end
        end)
    end

    return astF
end

-- ════════════════════════════════════════════════════════════
-- RARE SPACE EVENTS  (one per hour, random)
-- ════════════════════════════════════════════════════════════
local function DoSupernova()
    local pos = Vector3.new(-950, LOBBY_Y+250, -1100)
    local nova = Instance.new("Part")
    nova.Shape   = Enum.PartType.Ball; nova.Size = Vector3.new(60,60,60)
    nova.Position = pos; nova.Anchored = true; nova.CanCollide = false
    nova.Color   = Color3.fromRGB(255,245,190); nova.Material = Enum.Material.Neon
    nova.CastShadow = false; nova.Parent = workspace
    Light(nova, Color3.fromRGB(255,240,180), 15, 700)
    TweenService:Create(nova, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(700,700,700) }):Play()
    task.wait(5)
    TweenService:Create(nova, TweenInfo.new(9, Enum.EasingStyle.Quad),
        { Transparency = 1, Size = Vector3.new(900,900,900) }):Play()
    Debris:AddItem(nova, 10)
end

local function DoBlackHole()
    local pos = Vector3.new(800, LOBBY_Y+300, -1200)
    -- Dark vortex disc
    local bh = Instance.new("Part")
    bh.Shape  = Enum.PartType.Cylinder; bh.Size = Vector3.new(6, 200, 200)
    bh.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
    bh.Anchored = true; bh.CanCollide = false
    bh.Color  = Color3.fromRGB(0,0,0); bh.Material = Enum.Material.SmoothPlastic
    bh.CastShadow = false; bh.Parent = workspace

    -- Accretion ring (orange glow around black hole)
    local ring = Instance.new("Part")
    ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(4, 320, 320)
    ring.CFrame = CFrame.new(pos) * CFrame.Angles(0,0, math.rad(90))
    ring.Anchored = true; ring.CanCollide = false
    ring.Color = Color3.fromRGB(255,150,30); ring.Material = Enum.Material.Neon
    ring.Transparency = 0.35; ring.CastShadow = false; ring.Parent = workspace
    Light(ring, Color3.fromRGB(255,140,20), 8, 500)

    -- Grow then vanish
    TweenService:Create(bh,   TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(6, 400, 400) }):Play()
    TweenService:Create(ring, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(4, 600, 600) }):Play()
    task.wait(12)
    TweenService:Create(bh,   TweenInfo.new(4), { Transparency = 1 }):Play()
    TweenService:Create(ring, TweenInfo.new(4), { Transparency = 1 }):Play()
    Debris:AddItem(bh,   5)
    Debris:AddItem(ring, 5)
end

local function DoComet()
    local comet = Instance.new("Part")
    comet.Shape = Enum.PartType.Ball; comet.Size = Vector3.new(22, 14, 14)
    comet.Position = Vector3.new(-1300, LOBBY_Y+310, -350)
    comet.Anchored = true; comet.CanCollide = false
    comet.Color = Color3.fromRGB(200,235,255); comet.Material = Enum.Material.Neon
    comet.CastShadow = false; comet.Parent = workspace
    Light(comet, Color3.fromRGB(200,235,255), 7, 130)

    local tail = Instance.new("Part")
    tail.Size = Vector3.new(4, 4, 200); tail.Anchored = true; tail.CanCollide = false
    tail.Color = Color3.fromRGB(180,215,255); tail.Material = Enum.Material.Neon
    tail.Transparency = 0.65; tail.CastShadow = false; tail.Parent = workspace

    local mv = TweenService:Create(comet, TweenInfo.new(12, Enum.EasingStyle.Linear),
        { Position = Vector3.new(1300, LOBBY_Y+250, -600) })
    mv:Play()
    local running = true
    task.spawn(function()
        while running do
            tail.CFrame = CFrame.new(comet.Position + Vector3.new(-100,0,0))
            task.wait()
        end
    end)
    mv.Completed:Wait(); running = false
    comet:Destroy(); tail:Destroy()
end

local function DoPlanetCollision()
    local midPos = Vector3.new(-550, LOBBY_Y+380, -1000)
    local col1   = Color3.fromRGB(160,100,50)
    local col2   = Color3.fromRGB(80,110,190)
    local p1 = Instance.new("Part")
    p1.Shape = Enum.PartType.Ball; p1.Size = Vector3.new(100,100,100)
    p1.Position = midPos + Vector3.new(-300,0,0)
    p1.Anchored = true; p1.CanCollide = false; p1.Color = col1
    p1.Material = Enum.Material.SmoothPlastic; p1.CastShadow = false; p1.Parent = workspace

    local p2 = p1:Clone(); p2.Position = midPos + Vector3.new(300,0,0)
    p2.Color = col2; p2.Parent = workspace

    local t1 = TweenService:Create(p1, TweenInfo.new(4, Enum.EasingStyle.Quad),
        { Position = midPos })
    local t2 = TweenService:Create(p2, TweenInfo.new(4, Enum.EasingStyle.Quad),
        { Position = midPos })
    t1:Play(); t2:Play(); t1.Completed:Wait()
    p1:Destroy(); p2:Destroy()

    local blast = Instance.new("Part")
    blast.Shape = Enum.PartType.Ball; blast.Size = Vector3.new(30,30,30)
    blast.Position = midPos; blast.Anchored = true; blast.CanCollide = false
    blast.Color = Color3.fromRGB(255,200,80); blast.Material = Enum.Material.Neon
    blast.CastShadow = false; blast.Parent = workspace
    Light(blast, Color3.fromRGB(255,200,80), 14, 900)
    TweenService:Create(blast, TweenInfo.new(7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(600,600,600), Transparency = 1 }):Play()
    Debris:AddItem(blast, 8)
end

local EVENTS = { DoSupernova, DoBlackHole, DoComet, DoPlanetCollision }

-- ════════════════════════════════════════════════════════════
-- 3D DISPLAY MODELS  (item props on counter surfaces)
-- ════════════════════════════════════════════════════════════
local function DisplayRifle(folder, pos)
    -- Barrel
    PV(folder,"GunBarrel",Vector3.new(0.35,0.35,5), pos+Vector3.new(0,0.5,0),
        Color3.fromRGB(35,35,40), Enum.Material.Metal)
    -- Body
    PV(folder,"GunBody",Vector3.new(0.55,0.55,2.2), pos+Vector3.new(0,0.3,-0.5),
        Color3.fromRGB(20,20,25), Enum.Material.Metal)
    -- Grip
    PV(folder,"GunGrip",Vector3.new(0.4,0.8,0.4), pos+Vector3.new(0,-0.2,0.8),
        Color3.fromRGB(30,25,20), Enum.Material.SmoothPlastic)
    -- Scope
    PV(folder,"GunScope",Vector3.new(0.3,0.4,1), pos+Vector3.new(0,0.8,-0.3),
        Color3.fromRGB(10,10,12), Enum.Material.SmoothPlastic)
end

local function DisplayHelmet(folder, pos)
    -- Dome
    local dome = Instance.new("Part")
    dome.Shape = Enum.PartType.Ball
    dome.Size = Vector3.new(2.4,2.4,2.4)
    dome.Position = pos + Vector3.new(0,1.2,0)
    dome.Anchored = true; dome.CanCollide = false
    dome.Color = Color3.fromRGB(30,38,55); dome.Material = Enum.Material.Metal
    dome.CastShadow = false; dome.Parent = folder
    -- Visor
    PV(folder,"Visor",Vector3.new(1.8,0.7,0.3), pos+Vector3.new(0,1.1,1.1),
        Color3.fromRGB(0,180,230), Enum.Material.Neon, 0.25)
end

local function DisplayPotion(folder, pos, col)
    local bottle = Instance.new("Part")
    bottle.Shape = Enum.PartType.Ball
    bottle.Size = Vector3.new(1.1,1.4,1.1)
    bottle.Position = pos + Vector3.new(0,0.7,0)
    bottle.Anchored = true; bottle.CanCollide = false
    bottle.Color = col; bottle.Material = Enum.Material.Neon
    bottle.Transparency = 0.25; bottle.CastShadow = false; bottle.Parent = folder
    PV(folder,"PotionCork",Vector3.new(0.4,0.5,0.4), pos+Vector3.new(0,1.5,0),
        Color3.fromRGB(130,90,50), Enum.Material.SmoothPlastic)
    Light(bottle, col, 2, 8)
end

local function DisplayGoldBar(folder, pos)
    PV(folder,"GoldBar",Vector3.new(1.8,0.7,0.9), pos+Vector3.new(0,0.35,0),
        Color3.fromRGB(240,200,50), Enum.Material.SmoothPlastic)
    Light(PV(folder,"GoldGlow",Vector3.new(1.8,0.1,0.9), pos+Vector3.new(0,0.72,0),
        Color3.fromRGB(255,215,60), Enum.Material.Neon, 0, true), Color3.fromRGB(255,210,60), 1.5, 6)
end

local function DisplayMedKit(folder, pos)
    PV(folder,"MedBox",Vector3.new(1.6,1,1.4), pos+Vector3.new(0,0.5,0),
        Color3.fromRGB(240,240,240), Enum.Material.SmoothPlastic)
    -- Red cross face decal
    local box = PV(folder,"MedCross",Vector3.new(0.7,0.7,0.05), pos+Vector3.new(0,0.5,0.73),
        Color3.fromRGB(220,40,40), Enum.Material.SmoothPlastic)
    PV(folder,"MedCrossH",Vector3.new(0.2,0.7,0.05), pos+Vector3.new(0,0.5,0.74),
        Color3.fromRGB(255,255,255), Enum.Material.SmoothPlastic)
    PV(folder,"MedCrossV",Vector3.new(0.7,0.2,0.05), pos+Vector3.new(0,0.5,0.75),
        Color3.fromRGB(255,255,255), Enum.Material.SmoothPlastic)
end

local function DisplayBulletBox(folder, pos)
    PV(folder,"AmmoBox",Vector3.new(1.4,0.9,0.9), pos+Vector3.new(0,0.45,0),
        Color3.fromRGB(60,50,30), Enum.Material.Metal)
    for i = 1, 5 do
        PV(folder,"Bullet_"..i,Vector3.new(0.18,0.6,0.18),
            pos+Vector3.new(-0.4+(i-1)*0.2, 1.15, 0),
            Color3.fromRGB(210,175,50), Enum.Material.SmoothPlastic)
    end
end

-- ════════════════════════════════════════════════════════════
-- MAIN BUILD FUNCTION
-- ════════════════════════════════════════════════════════════
function SpaceshipLobby.GenerateVisualSpaceship()
    local old = workspace:FindFirstChild("SpaceshipLobby")
    if old then old:Destroy() end

    local root = Instance.new("Folder")
    root.Name   = "SpaceshipLobby"
    root.Parent = workspace

    -- ── FLOOR ────────────────────────────────────────────────
    PV(root,"Floor", Vector3.new(HALL_W+20, 2, HALL_D+20),
        Vector3.new(0, LOBBY_Y, 0), Color3.fromRGB(12,14,20), Enum.Material.Metal)

    -- Grid (cyan neon lines)
    for i = -7, 7 do
        local hL = PV(root,"FH_"..i, Vector3.new(HALL_W-10,0.1,1.2),
            Vector3.new(0, FLOOR_TOP, i*25), CYAN, Enum.Material.Neon, 0, true)
        hL.CastShadow = false
        local vL = PV(root,"FV_"..i, Vector3.new(1.2,0.1,HALL_D-10),
            Vector3.new(i*38, FLOOR_TOP, 0), CYAN, Enum.Material.Neon, 0, true)
        vL.CastShadow = false
    end

    -- ── TRANSPARENT GLASS WALLS (space visible through) ──────
    local glassTrans = 0.82  -- nearly see-through

    -- North wall (glass — asteroids move past this)
    PV(root,"WallNorthGlass", Vector3.new(HALL_W, WALL_H, WALL_T),
        Vector3.new(0, WALL_CY, -HD),
        Color3.fromRGB(5, 20, 55), Enum.Material.Glass, glassTrans)

    -- South wall (glass)
    PV(root,"WallSouthGlass", Vector3.new(HALL_W, WALL_H, WALL_T),
        Vector3.new(0, WALL_CY,  HD),
        Color3.fromRGB(5, 20, 55), Enum.Material.Glass, glassTrans)

    -- East wall (glass)
    PV(root,"WallEastGlass", Vector3.new(WALL_T, WALL_H, HALL_D),
        Vector3.new(HW, WALL_CY, 0),
        Color3.fromRGB(5, 20, 55), Enum.Material.Glass, glassTrans)

    -- West wall (glass)
    PV(root,"WallWestGlass", Vector3.new(WALL_T, WALL_H, HALL_D),
        Vector3.new(-HW, WALL_CY, 0),
        Color3.fromRGB(5, 20, 55), Enum.Material.Glass, glassTrans)

    -- ── TRANSPARENT GLASS CEILING (stars visible above) ──────
    PV(root,"Ceiling", Vector3.new(HALL_W+20, WALL_T, HALL_D+20),
        Vector3.new(0, CEIL_Y, 0),
        Color3.fromRGB(5, 20, 55), Enum.Material.Glass, 0.85)

    -- Ceiling support beams (dark metal X-pattern)
    for i = -3, 3 do
        PV(root,"BeamX_"..i, Vector3.new(HALL_W+10, 2.5, 3),
            Vector3.new(0, CEIL_Y-1.5, i*(HALL_D/7)),
            BLACK, Enum.Material.Metal)
        PV(root,"BeamZ_"..i, Vector3.new(3, 2.5, HALL_D+10),
            Vector3.new(i*(HALL_W/7), CEIL_Y-1.5, 0),
            BLACK, Enum.Material.Metal)
    end

    -- Wall top/bottom frame bands (thin solid border — helps frame the glass)
    for _, z in ipairs({-HD, HD}) do
        PV(root,"WallTopBand_"..z, Vector3.new(HALL_W+10, 3, 8),
            Vector3.new(0, CEIL_Y+1, z), BLACK, Enum.Material.Metal)
        PV(root,"WallBotBand_"..z, Vector3.new(HALL_W+10, 3, 8),
            Vector3.new(0, FLOOR_TOP+1.5, z), BLACK, Enum.Material.Metal)
    end
    for _, x in ipairs({-HW, HW}) do
        PV(root,"WallTopBandX_"..x, Vector3.new(8, 3, HALL_D+10),
            Vector3.new(x, CEIL_Y+1, 0), BLACK, Enum.Material.Metal)
        PV(root,"WallBotBandX_"..x, Vector3.new(8, 3, HALL_D+10),
            Vector3.new(x, FLOOR_TOP+1.5, 0), BLACK, Enum.Material.Metal)
    end

    -- Neon base strip around walls (cyan glow border)
    PV(root,"GlowN", Vector3.new(HALL_W,1.5,0.4), Vector3.new(0,FLOOR_TOP+1.5,-HD+2),
        CYAN, Enum.Material.Neon, 0, true).CastShadow = false
    PV(root,"GlowS", Vector3.new(HALL_W,1.5,0.4), Vector3.new(0,FLOOR_TOP+1.5, HD-2),
        CYAN, Enum.Material.Neon, 0, true).CastShadow = false
    PV(root,"GlowE", Vector3.new(0.4,1.5,HALL_D), Vector3.new( HW-2,FLOOR_TOP+1.5,0),
        CYAN, Enum.Material.Neon, 0, true).CastShadow = false
    PV(root,"GlowW", Vector3.new(0.4,1.5,HALL_D), Vector3.new(-HW+2,FLOOR_TOP+1.5,0),
        CYAN, Enum.Material.Neon, 0, true).CastShadow = false

    -- ── BLACK DRAGON PILLARS ──────────────────────────────────
    local pillarPositions = {
        {-HW+10, -HD+10}, {-HW+10, HD-10},
        { HW-10, -HD+10}, { HW-10, HD-10},
        {-180,  -HD+10}, {-180,  HD-10},
        {   0,  -HD+10}, {   0,  HD-10},
        { 180,  -HD+10}, { 180,  HD-10},
    }
    for _, pp in ipairs(pillarPositions) do
        DragonPillar(root, pp[1], pp[2])
    end

    -- Interior corner pillars (inset)
    for _, pp in ipairs({
        {-HW+10, 0}, {HW-10, 0},
        {0, -HD+10}, {0, HD-10},
    }) do
        DragonPillar(root, pp[1], pp[2])
    end

    -- ── CEILING LIGHTS (bright interior despite dark ambient) ─
    local ceilLightPositions = {
        {-180, -100}, {-180, 0}, {-180, 100},
        {   0, -100}, {   0, 0}, {   0, 100},
        { 180, -100}, { 180, 0}, { 180, 100},
    }
    for i, cp in ipairs(ceilLightPositions) do
        local panel = PV(root,"CLight_"..i, Vector3.new(80,0.4,10),
            Vector3.new(cp[1], CEIL_Y-2.5, cp[2]),
            Color3.fromRGB(215,225,255), Enum.Material.Neon, 0, true)
        panel.CastShadow = false
        Light(panel, Color3.fromRGB(215,225,255), 6, 90)
    end

    -- Extra ambient fill lights spread around floor level
    for i = -2, 2 do
        for j = -1, 1 do
            local fLight = PV(root,"FillLight_"..i.."_"..j, Vector3.new(0.5,0.5,0.5),
                Vector3.new(i*100, FLOOR_TOP + 25, j*80),
                CYAN, Enum.Material.Neon, 1, true)
            fLight.CastShadow = false
            Light(fLight, Color3.fromRGB(150,200,255), 3, 80)
        end
    end

    -- ── ENERGY CORE (central) ─────────────────────────────────
    local core = PV(root,"Core", Vector3.new(5,5,5),
        Vector3.new(0, CEIL_Y-10, 0), CYAN, Enum.Material.Neon, 0, true)
    core.CastShadow = false
    Light(core, CYAN, 12, 220)

    PV(root,"CoreBeam", Vector3.new(2, WALL_H-18, 2),
        Vector3.new(0, FLOOR_TOP+10, 0), CYAN, Enum.Material.Neon, 0.68, true).CastShadow = false

    for i = 0, 5 do
        local a = math.rad(i*60)
        PV(root,"CoreRing_"..i, Vector3.new(1.2,1.2,22),
            Vector3.new(math.sin(a)*12, CEIL_Y-10, math.cos(a)*12),
            GOLD, Enum.Material.Neon, 0, true).CastShadow = false
    end

    -- ── SPAWN LOCATION ────────────────────────────────────────
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "LobbySpawn"; spawn.Size = Vector3.new(50,1,50)
    spawn.Position = Vector3.new(0, FLOOR_TOP, 0)
    spawn.Anchored = true; spawn.Transparency = 1
    spawn.TeamColor = BrickColor.new("White")
    spawn.AllowTeamChangeOnTouch = false; spawn.Duration = 0
    spawn.Parent = root

    -- ════════════════════════════════════════════════════════
    -- NPC STATIONS
    -- ════════════════════════════════════════════════════════

    -- ── QUARTERMASTER RIGGS ───────────────────────────────────
    do
        local bx, bz = 155, -90

        -- Back wall panel
        PV(root,"QM_Back", Vector3.new(70,34,3),
            Vector3.new(bx, FLOOR_TOP+17, bz-25), Color3.fromRGB(18,22,35))

        -- Counter
        local ctr = PV(root,"QM_Counter", Vector3.new(54,3,14),
            Vector3.new(bx, FLOOR_TOP+1.5, bz-9), Color3.fromRGB(22,28,42))
        local cTop = PV(root,"QM_CTop", Vector3.new(54.5,0.35,14.5),
            Vector3.new(bx, FLOOR_TOP+3.2, bz-9), CYAN, Enum.Material.Neon, 0, true)
        cTop.CastShadow = false; Light(cTop, CYAN, 2, 32)

        -- Sign
        local sign = PV(root,"QM_Sign", Vector3.new(55,7,0.6),
            Vector3.new(bx, FLOOR_TOP+19, bz-27), DARK)
        SGui(sign, Enum.NormalId.Front,
            "QUARTERMASTER RIGGS\nSENJATA & ARMOR", 28, GOLD)

        -- Spotlight
        local spot = PV(root,"QM_Spot", Vector3.new(1.5,0.5,1.5),
            Vector3.new(bx, CEIL_Y-3, bz-9), GOLD, Enum.Material.Neon, 0, true)
        spot.CastShadow = false
        local sl = Instance.new("SpotLight"); sl.Face = Enum.NormalId.Bottom
        sl.Brightness = 7; sl.Range = 44; sl.Angle = 48; sl.Color = GOLD; sl.Parent = spot

        -- 3D Item displays on counter
        DisplayRifle(root, Vector3.new(bx-18, FLOOR_TOP+3.5, bz-9))
        DisplayHelmet(root, Vector3.new(bx-5,  FLOOR_TOP+3.5, bz-12))
        DisplayBulletBox(root, Vector3.new(bx+8,  FLOOR_TOP+3.5, bz-9))
        DisplayGoldBar(root, Vector3.new(bx+18, FLOOR_TOP+3.5, bz-9))

        -- NPC
        BuildNPC(root, "Quartermaster Riggs",
            Vector3.new(bx, FLOOR_TOP, bz-19),
            Color3.fromRGB(35,52,90), Color3.fromRGB(28,32,52),
            "quartermaster",
            "Prajurit! Koleksi senjata terbaik ada di sini. Pilih dengan bijak — nyawamu taruhannya.")
    end

    -- ── APOTHECARY VAEL ───────────────────────────────────────
    do
        local bx, bz = -155, -90

        PV(root,"APO_Back", Vector3.new(70,34,3),
            Vector3.new(bx, FLOOR_TOP+17, bz-25), Color3.fromRGB(12,22,16))

        local ctr = PV(root,"APO_Counter", Vector3.new(54,3,14),
            Vector3.new(bx, FLOOR_TOP+1.5, bz-9), Color3.fromRGB(14,26,18))
        local cTop = PV(root,"APO_CTop", Vector3.new(54.5,0.35,14.5),
            Vector3.new(bx, FLOOR_TOP+3.2, bz-9), GREEN, Enum.Material.Neon, 0, true)
        cTop.CastShadow = false; Light(cTop, GREEN, 2, 32)

        local sign = PV(root,"APO_Sign", Vector3.new(55,7,0.6),
            Vector3.new(bx, FLOOR_TOP+19, bz-27), DARK)
        SGui(sign, Enum.NormalId.Front,
            "APOTHECARY VAEL\nOBAT & SIHIR", 28, GREEN)

        local spot = PV(root,"APO_Spot", Vector3.new(1.5,0.5,1.5),
            Vector3.new(bx, CEIL_Y-3, bz-9), GREEN, Enum.Material.Neon, 0, true)
        spot.CastShadow = false
        local sl = Instance.new("SpotLight"); sl.Face = Enum.NormalId.Bottom
        sl.Brightness = 7; sl.Range = 44; sl.Angle = 48; sl.Color = GREEN; sl.Parent = spot

        -- 3D Item displays
        DisplayPotion(root, Vector3.new(bx-18, FLOOR_TOP+3.5, bz-9),  Color3.fromRGB(255,50,50))
        DisplayPotion(root, Vector3.new(bx-12, FLOOR_TOP+3.5, bz-9),  Color3.fromRGB(50,220,100))
        DisplayPotion(root, Vector3.new(bx-6,  FLOOR_TOP+3.5, bz-9),  Color3.fromRGB(80,130,255))
        DisplayPotion(root, Vector3.new(bx,    FLOOR_TOP+3.5, bz-9),  Color3.fromRGB(255,200,0))
        DisplayMedKit(root, Vector3.new(bx+12, FLOOR_TOP+3.5, bz-9))

        BuildNPC(root, "Apothecary Vael",
            Vector3.new(bx, FLOOR_TOP, bz-19),
            Color3.fromRGB(55,30,82), Color3.fromRGB(35,18,58),
            "apothecary",
            "Tubuhmu adalah senjatamu, petualang. Rawatlah baik-baik sebelum masuk ke hutan.")
    end

    -- ── PORTAL KALIMANTAN ─────────────────────────────────────
    do
        local px, pz = 0, -155

        -- Arch pillars
        for _, sx in ipairs({-22, 22}) do
            local pillar = PV(root,"PortalPillar"..sx, Vector3.new(7,38,7),
                Vector3.new(px+sx, FLOOR_TOP+19, pz), PURPLE, Enum.Material.Neon, 0, true)
            pillar.CastShadow = false; Light(pillar, PURPLE, 3, 45)
        end
        local topBar = PV(root,"PortalTop", Vector3.new(50,7,7),
            Vector3.new(px, FLOOR_TOP+41, pz), PURPLE, Enum.Material.Neon, 0, true)
        topBar.CastShadow = false

        -- Portal void
        local voidPart = PV(root,"PortalVoid", Vector3.new(34,32,0.5),
            Vector3.new(px, FLOOR_TOP+17, pz), Color3.fromRGB(30,6,95),
            Enum.Material.Neon, 0.22, true)
        voidPart.CastShadow = false
        Light(voidPart, PURPLE, 9, 90)

        -- Swirling void dots
        for i = 1, 18 do
            local a   = math.rad(i*(360/18))
            local r   = math.random(3,14)
            PV(root,"VDot_"..i, Vector3.new(0.8,0.8,0.8),
                Vector3.new(px + math.cos(a)*r, FLOOR_TOP+math.random(4,30), pz-0.6),
                Color3.fromRGB(200,150,255), Enum.Material.Neon, 0, true).CastShadow = false
        end

        local portSign = PV(root,"PortalSign", Vector3.new(58,8,0.6),
            Vector3.new(px, FLOOR_TOP+53, pz), DARK)
        SGui(portSign, Enum.NormalId.Front,
            "PORTAL — KALIMANTAN ISLAND\nTekan E untuk masuk ke zona", 26,
            Color3.fromRGB(200,150,255))

        -- ProximityPrompt on void (teleport to Kalimantan)
        local pp = Instance.new("ProximityPrompt")
        pp.ActionText            = "Masuk Kalimantan [E]"
        pp.ObjectText            = "Portal Fantasi"
        pp.MaxActivationDistance = 18
        pp.HoldDuration          = 0
        pp.RequiresLineOfSight   = false
        pp.Parent                = voidPart

        pp.Triggered:Connect(function(plr)
            local char = plr.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            -- Teleport to Kalimantan spawn (game world at Y≈5)
            hrp.CFrame = CFrame.new(50, 8, 50)
        end)

        -- Portal Keeper NPC (no shop)
        BuildNPC(root, "Portal Keeper",
            Vector3.new(px + 28, FLOOR_TOP, pz + 14),
            Color3.fromRGB(40,14,78), Color3.fromRGB(26,8,52),
            nil,
            "Kalimantan menunggumu. Pastikan inventorimu penuh dan nyawamu tangguh.")
    end

    -- ── FLEA MARKET COUNTER ───────────────────────────────────
    do
        local mz = 125
        local ctr = PV(root,"Mkt_Counter", Vector3.new(200,3,14),
            Vector3.new(0, FLOOR_TOP+1.5, mz), Color3.fromRGB(20,25,38))
        local cTop = PV(root,"Mkt_CTop", Vector3.new(200.5,0.35,14.5),
            Vector3.new(0, FLOOR_TOP+3.2, mz), CYAN, Enum.Material.Neon, 0, true)
        cTop.CastShadow = false; Light(cTop, CYAN, 3, 55)

        local sign = PV(root,"Mkt_Sign", Vector3.new(160,8,0.6),
            Vector3.new(0, FLOOR_TOP+13, mz-7.5), DARK)
        SGui(sign, Enum.NormalId.Front,
            "FLEA MARKET — Jual & Beli antar Pemain [F]", 26, CYAN)

        -- Stall items
        for i = -3, 3 do
            PV(root,"Stall_"..i, Vector3.new(27,0.3,9),
                Vector3.new(i*32, FLOOR_TOP+3.5, mz), Color3.fromRGB(28,35,50))
            DisplayGoldBar(root, Vector3.new(i*32-8, FLOOR_TOP+3.5, mz))
            DisplayPotion(root, Vector3.new(i*32,    FLOOR_TOP+3.5, mz),
                Color3.fromHSV(i/6, 0.8, 0.9))
            DisplayBulletBox(root, Vector3.new(i*32+8, FLOOR_TOP+3.5, mz))
        end
    end

    -- ── QUEST BOARD ───────────────────────────────────────────
    do
        local qx, qz = -HW+28, 40
        PV(root,"QB_Frame", Vector3.new(7,38,68),
            Vector3.new(qx-4, FLOOR_TOP+19, qz), Color3.fromRGB(25,18,10))
        local board = PV(root,"QB_Face", Vector3.new(0.5,33,63),
            Vector3.new(qx, FLOOR_TOP+18, qz), Color3.fromRGB(14,10,5))
        Light(board, GOLD, 2, 28)

        local sg = Instance.new("SurfaceGui")
        sg.Face = Enum.NormalId.Right; sg.CanvasSize = Vector2.new(480,620)
        sg.Parent = board

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(14,10,4)
        bg.Parent = sg

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1,0,0,72)
        titleLbl.BackgroundColor3 = Color3.fromRGB(90,60,10)
        titleLbl.Text = "PAPAN MISI HARIAN"
        titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 34
        titleLbl.TextColor3 = Color3.fromRGB(255,220,120)
        titleLbl.TextXAlignment = Enum.TextXAlignment.Center
        titleLbl.TextYAlignment = Enum.TextYAlignment.Center
        titleLbl.Parent = bg

        local quests = {
            "Ekstrak hidup dari Kalimantan (1×)",
            "Bunuh 5 monster di zona hutan dalam",
            "Temukan Gold Bar — bawa keluar aman",
            "Selamat dari serangan Meteor Shower",
            "Kumpulkan 10 Healing Herb",
            "Jual 3 item di Flea Market",
        }
        for i, q in ipairs(quests) do
            local row = Instance.new("TextLabel")
            row.Size = UDim2.new(1,0,0,88)
            row.Position = UDim2.new(0,0,0, 72+(i-1)*90)
            row.BackgroundColor3 = i%2==0
                and Color3.fromRGB(20,15,7)
                or Color3.fromRGB(14,10,4)
            row.Text = i..". "..q
            row.Font = Enum.Font.Gotham; row.TextSize = 21
            row.TextColor3 = Color3.fromRGB(215,205,175)
            row.TextWrapped = true; row.TextXAlignment = Enum.TextXAlignment.Left
            row.Parent = bg
            local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0,10); pad.Parent = row
        end
    end

    -- ── CONTROL ROOM ─────────────────────────────────────────
    do
        for i = -2, 2 do
            local cx = HW - 28
            local terminal = PV(root,"Term_"..i, Vector3.new(12,17,7),
                Vector3.new(cx, FLOOR_TOP+8.5, i*28), Color3.fromRGB(12,16,26))
            Light(terminal, CYAN, 1, 22)

            local screen = PV(root,"Screen_"..i, Vector3.new(9,11,0.35),
                Vector3.new(cx-5.9, FLOOR_TOP+9.5, i*28),
                Color3.fromRGB(0,140,220), Enum.Material.Neon, 0.12, true)
            screen.CastShadow = false; Light(screen, CYAN, 3, 28)

            local sg = Instance.new("SurfaceGui")
            sg.Face = Enum.NormalId.Right; sg.CanvasSize = Vector2.new(360,480)
            sg.Parent = screen
            local scl = Instance.new("TextLabel")
            scl.Size = UDim2.new(1,0,1,0); scl.BackgroundTransparency = 1
            scl.Text = "APEX v9.1\nSTATUS: ONLINE\n\nZONE: KALIMANTAN AKTIF\nPLAYERS: ONLINE\nNEXT EVENT: --"
            scl.Font = Enum.Font.Code; scl.TextSize = 22
            scl.TextColor3 = Color3.fromRGB(100,255,180)
            scl.TextXAlignment = Enum.TextXAlignment.Left
            scl.TextYAlignment = Enum.TextYAlignment.Top
            scl.Parent = sg
        end
    end

    -- ── EXTRACTION DEPOSIT PAD ────────────────────────────────
    do
        local ex, ez = 165, 95
        local pad = PV(root,"ExtPad", Vector3.new(44,0.8,44),
            Vector3.new(ex, FLOOR_TOP+0.4, ez), GREEN, Enum.Material.Neon, 0.40, true)
        pad.CastShadow = false; Light(pad, GREEN, 5, 65)

        for _, corner in ipairs({{-20,-20},{20,-20},{-20,20},{20,20}}) do
            local cp = PV(root,"ExtCorner", Vector3.new(2.5,10,2.5),
                Vector3.new(ex+corner[1], FLOOR_TOP+5, ez+corner[2]),
                GREEN, Enum.Material.Neon, 0, true)
            cp.CastShadow = false; Light(cp, GREEN, 3, 20)
        end

        local eSign = PV(root,"ExtSign", Vector3.new(42,8,0.6),
            Vector3.new(ex, FLOOR_TOP+14, ez-22), DARK)
        SGui(eSign, Enum.NormalId.Front,
            "ZONA DEPOSIT EKSTRAKSI\nLoot & Rampasan Misi", 26, GREEN)

        local ePP = Instance.new("ProximityPrompt")
        ePP.ActionText = "Deposit Loot"; ePP.ObjectText = "Extraction Deposit"
        ePP.MaxActivationDistance = 20; ePP.Parent = pad
    end

    -- ── SPACE BACKGROUND + ANIMATED ASTEROIDS ────────────────
    BuildSpaceBackground(root)
    BuildAnimatedAsteroids(root)

    -- ── HOURLY RARE EVENTS ────────────────────────────────────
    task.spawn(function()
        while root.Parent do
            task.wait(3600)
            local idx = math.random(1, #EVENTS)
            task.spawn(EVENTS[idx])
        end
    end)

    print("[SpaceshipLobby] v4 — transparent walls + space background + dragon pillars.")
    return root
end

-- ── Player safety (teleport up if fell below lobby) ─────────
function SpaceshipLobby.InitializePlayerLobby(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.8)
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and root.Position.Y < 900 then
            root.CFrame = CFrame.new(0, FLOOR_TOP + 7, 0)
        end
    end)
end

function SpaceshipLobby.Initialize()
    SpaceshipLobby.GenerateVisualSpaceship()
    Players.PlayerAdded:Connect(SpaceshipLobby.InitializePlayerLobby)
    print("[SpaceshipLobby] Initialized.")
end

return SpaceshipLobby
