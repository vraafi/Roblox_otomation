-- LOBBY_SPACESHIP_1.lua
-- Full spaceship carrier lobby at Y=1000.
-- Physical hangar hull, NPC traders, sci-fi decorations,
-- quest board, market counter, control room, and safe SpawnLocation.

local SpaceshipLobby = {}

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local LOBBY_Y   = 1000
local FLOOR_TOP = LOBBY_Y + 1
local HALL_W    = 600
local HALL_D    = 400
local WALL_H    = 70
local WALL_T    = 8

-- ── helpers ──────────────────────────────────────────────────
local function Block(folder, name, size, pos, color, mat, trans)
    local p = Instance.new("Part")
    p.Name        = name
    p.Size        = size
    p.Position    = pos
    p.Anchored    = true
    p.CanCollide  = true
    p.Color       = color
    p.Material    = mat or Enum.Material.Metal
    p.Transparency = trans or 0
    p.CastShadow  = (trans or 0) < 0.5
    p.Parent      = folder
    return p
end

local function PL(parent, color, brightness, range)
    local l = Instance.new("PointLight")
    l.Color      = color
    l.Brightness = brightness
    l.Range      = range
    l.Parent     = parent
end

local function SurfaceSign(part, face, text, fontSize, textColor)
    local sg = Instance.new("SurfaceGui")
    sg.Face = face
    sg.CanvasSize = Vector2.new(800, 200)
    sg.Parent = part
    local lbl = Instance.new("TextLabel")
    lbl.Size                 = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                 = text
    lbl.Font                 = Enum.Font.GothamBold
    lbl.TextSize             = fontSize or 32
    lbl.TextColor3           = textColor or Color3.fromRGB(220, 175, 50)
    lbl.TextXAlignment       = Enum.TextXAlignment.Center
    lbl.TextYAlignment       = Enum.TextYAlignment.Center
    lbl.TextWrapped          = true
    lbl.Parent               = sg
    return sg
end

-- ── NPC builder ───────────────────────────────────────────────
local function BuildNPC(folder, npcName, pos, shirtColor, pantsColor, actionText, dialogText)
    local model = Instance.new("Model")
    model.Name  = npcName

    -- Root (invisible, anchored)
    local root = Instance.new("Part")
    root.Name         = "HumanoidRootPart"
    root.Size         = Vector3.new(2, 2, 1)
    root.Position     = pos + Vector3.new(0, 3, 0)
    root.Anchored     = true
    root.Transparency = 1
    root.CanCollide   = false
    root.Parent       = model

    -- Torso
    local torso = Instance.new("Part")
    torso.Name     = "Torso"
    torso.Size     = Vector3.new(2, 2, 1)
    torso.Position = pos + Vector3.new(0, 3, 0)
    torso.Anchored = true
    torso.Color    = shirtColor
    torso.Material = Enum.Material.SmoothPlastic
    torso.Parent   = model

    -- Head
    local head = Instance.new("Part")
    head.Name     = "Head"
    head.Shape    = Enum.PartType.Ball
    head.Size     = Vector3.new(2, 2, 2)
    head.Position = pos + Vector3.new(0, 5.2, 0)
    head.Anchored = true
    head.Color    = Color3.fromRGB(255, 210, 170)
    head.Material = Enum.Material.SmoothPlastic
    head.Parent   = model

    -- Legs
    for _, side in ipairs({{-0.6, "Left"}, {0.6, "Right"}}) do
        local leg = Instance.new("Part")
        leg.Name     = side[2] .. "Leg"
        leg.Size     = Vector3.new(0.9, 2, 1)
        leg.Position = pos + Vector3.new(side[1], 1, 0)
        leg.Anchored = true
        leg.Color    = pantsColor
        leg.Material = Enum.Material.SmoothPlastic
        leg.Parent   = model
    end

    -- Arms
    for _, side in ipairs({{-1.6, "Left"}, {1.6, "Right"}}) do
        local arm = Instance.new("Part")
        arm.Name     = side[2] .. "Arm"
        arm.Size     = Vector3.new(0.9, 2, 1)
        arm.Position = pos + Vector3.new(side[1], 3, 0)
        arm.Anchored = true
        arm.Color    = shirtColor
        arm.Material = Enum.Material.SmoothPlastic
        arm.Parent   = model
    end

    -- Humanoid (keeps name tag)
    local hum = Instance.new("Humanoid")
    hum.MaxHealth   = 999
    hum.Health      = 999
    hum.WalkSpeed   = 0
    hum.DisplayName = npcName
    hum.Parent      = model

    -- Overhead billboard name tag
    local bill = Instance.new("BillboardGui")
    bill.Size         = UDim2.new(0, 280, 0, 55)
    bill.StudsOffset  = Vector3.new(0, 4.2, 0)
    bill.AlwaysOnTop  = false
    bill.Parent       = head

    local bgF = Instance.new("Frame")
    bgF.Size                 = UDim2.new(1, 0, 1, 0)
    bgF.BackgroundColor3     = Color3.fromRGB(12, 15, 22)
    bgF.BackgroundTransparency = 0.25
    bgF.Parent               = bill
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = bgF

    local nameL = Instance.new("TextLabel")
    nameL.Size                 = UDim2.new(1, -8, 1, 0)
    nameL.Position             = UDim2.new(0, 4, 0, 0)
    nameL.BackgroundTransparency = 1
    nameL.Text                 = npcName
    nameL.Font                 = Enum.Font.GothamBold
    nameL.TextSize             = 18
    nameL.TextColor3           = Color3.fromRGB(220, 175, 50)
    nameL.TextXAlignment       = Enum.TextXAlignment.Center
    nameL.Parent               = bgF

    -- Proximity prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText            = actionText
    prompt.ObjectText            = npcName
    prompt.KeyboardKeyCode       = Enum.KeyCode.E
    prompt.MaxActivationDistance = 12
    prompt.Parent                = torso

    prompt.Triggered:Connect(function(player)
        -- Dialog bubble for 5 seconds
        local bubble = Instance.new("BillboardGui")
        bubble.Size        = UDim2.new(0, 320, 0, 90)
        bubble.StudsOffset = Vector3.new(0, 6.5, 0)
        bubble.Parent      = head

        local bgBubble = Instance.new("Frame")
        bgBubble.Size                 = UDim2.new(1, 0, 1, 0)
        bgBubble.BackgroundColor3     = Color3.fromRGB(10, 12, 20)
        bgBubble.BackgroundTransparency = 0.1
        bgBubble.Parent               = bubble
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 10)
        bc.Parent = bgBubble

        local dl = Instance.new("TextLabel")
        dl.Size                 = UDim2.new(1, -14, 1, 0)
        dl.Position             = UDim2.new(0, 7, 0, 0)
        dl.BackgroundTransparency = 1
        dl.Text                 = dialogText
        dl.Font                 = Enum.Font.Gotham
        dl.TextSize             = 14
        dl.TextColor3           = Color3.fromRGB(230, 230, 230)
        dl.TextWrapped          = true
        dl.TextXAlignment       = Enum.TextXAlignment.Left
        dl.TextYAlignment       = Enum.TextYAlignment.Center
        dl.Parent               = bgBubble

        Debris:AddItem(bubble, 5)
    end)

    model.PrimaryPart = root
    model.Parent      = folder
    return model
end

-- ============================================================
-- MAIN GENERATOR
-- ============================================================
function SpaceshipLobby.GenerateVisualSpaceship()
    -- Remove old lobby if it exists (hot-reload safe)
    local old = workspace:FindFirstChild("SpaceshipLobby")
    if old then old:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name   = "SpaceshipLobby"
    folder.Parent = workspace

    local DARK   = Color3.fromRGB(28,  30,  38)
    local MID    = Color3.fromRGB(45,  50,  62)
    local LIGHT  = Color3.fromRGB(75,  82, 100)
    local CYAN   = Color3.fromRGB(0,  200, 255)
    local GOLD   = Color3.fromRGB(220, 170,  50)
    local GREEN  = Color3.fromRGB(50,  210, 100)
    local PURPLE = Color3.fromRGB(120,  60, 255)

    local wallCY = FLOOR_TOP + WALL_H / 2

    -- ── FLOOR ────────────────────────────────────────────────
    Block(folder, "HangarFloor",
        Vector3.new(HALL_W + 20, 2, HALL_D + 20),
        Vector3.new(0, LOBBY_Y, 0),
        DARK, Enum.Material.Metal)

    -- Neon grid lines on floor
    for i = -8, 8 do
        local hStrip = Block(folder, "FH_"..i,
            Vector3.new(HALL_W - 10, 0.1, 1.5),
            Vector3.new(0, FLOOR_TOP, i * 22), CYAN, Enum.Material.Neon)
        hStrip.CastShadow = false

        local vStrip = Block(folder, "FV_"..i,
            Vector3.new(1.5, 0.1, HALL_D - 10),
            Vector3.new(i * 65, FLOOR_TOP, 0), CYAN, Enum.Material.Neon)
        vStrip.CastShadow = false
    end

    -- ── CEILING ──────────────────────────────────────────────
    Block(folder, "HangarCeiling",
        Vector3.new(HALL_W + 20, 3, HALL_D + 20),
        Vector3.new(0, FLOOR_TOP + WALL_H, 0),
        DARK, Enum.Material.Metal)

    -- Ceiling light panels
    for i = -4, 4 do
        local panel = Block(folder, "CLight_"..i,
            Vector3.new(90, 0.4, 10),
            Vector3.new(i * 62, FLOOR_TOP + WALL_H - 2.2, 0),
            Color3.fromRGB(200, 220, 255), Enum.Material.Neon)
        panel.CastShadow = false
        PL(panel, Color3.fromRGB(200, 220, 255), 3, 90)
    end

    -- ── WALLS ─────────────────────────────────────────────────
    Block(folder, "WallNorth", Vector3.new(HALL_W, WALL_H, WALL_T),
        Vector3.new(0, wallCY, -HALL_D/2), MID)
    Block(folder, "WallSouth", Vector3.new(HALL_W, WALL_H, WALL_T),
        Vector3.new(0, wallCY,  HALL_D/2), MID)
    Block(folder, "WallEast",  Vector3.new(WALL_T, WALL_H, HALL_D),
        Vector3.new(HALL_W/2,  wallCY, 0), MID)
    Block(folder, "WallWest",  Vector3.new(WALL_T, WALL_H, HALL_D),
        Vector3.new(-HALL_W/2, wallCY, 0), MID)

    -- Wall base glow strips
    local wallGlows = {
        {Vector3.new(HALL_W - 4, 1.5, 0.3), Vector3.new(0, FLOOR_TOP + 1, -HALL_D/2 + 1)},
        {Vector3.new(HALL_W - 4, 1.5, 0.3), Vector3.new(0, FLOOR_TOP + 1,  HALL_D/2 - 1)},
        {Vector3.new(0.3, 1.5, HALL_D - 4), Vector3.new(-HALL_W/2 + 1, FLOOR_TOP + 1, 0)},
        {Vector3.new(0.3, 1.5, HALL_D - 4), Vector3.new( HALL_W/2 - 1, FLOOR_TOP + 1, 0)},
    }
    for i, g in ipairs(wallGlows) do
        local glow = Block(folder, "WallGlow_"..i, g[1], g[2], CYAN, Enum.Material.Neon)
        glow.CastShadow = false
        PL(glow, CYAN, 1.2, 30)
    end

    -- ── STRUCTURAL PILLARS ────────────────────────────────────
    local pillarGrid = {
        {-220, -130}, {-220, 0}, {-220, 130},
        {   0, -130}, {  0, 130},
        { 220, -130}, { 220, 0}, { 220, 130},
    }
    for i, g in ipairs(pillarGrid) do
        -- Main pillar
        Block(folder, "Pillar_"..i, Vector3.new(10, WALL_H, 10),
            Vector3.new(g[1], wallCY, g[2]), LIGHT)
        -- Top accent
        local topAcc = Block(folder, "PillarTop_"..i, Vector3.new(14, 2, 14),
            Vector3.new(g[1], FLOOR_TOP + WALL_H - 2, g[2]), CYAN, Enum.Material.Neon)
        topAcc.CastShadow = false
        PL(topAcc, CYAN, 2, 30)
        -- Base ring
        local baseRing = Block(folder, "PillarBase_"..i, Vector3.new(13, 1.5, 13),
            Vector3.new(g[1], FLOOR_TOP + 1, g[2]), GOLD, Enum.Material.Neon)
        baseRing.CastShadow = false
    end

    -- ── SPACE WINDOWS (north wall) ────────────────────────────
    for i = -2, 2 do
        local win = Block(folder, "Window_"..i,
            Vector3.new(55, 25, 0.8),
            Vector3.new(i * 110, wallCY + 8, -HALL_D/2 + 1),
            Color3.fromRGB(10, 30, 80), Enum.Material.Glass, 0.25)
        -- Window frame (4 bars around it)
        for fi, fw in ipairs({
            {Vector3.new(57, 2, 1.5), Vector3.new(i*110, wallCY + 21, -HALL_D/2+1)},
            {Vector3.new(57, 2, 1.5), Vector3.new(i*110, wallCY - 4,  -HALL_D/2+1)},
            {Vector3.new(2, 27, 1.5), Vector3.new(i*110 - 29.5, wallCY+8, -HALL_D/2+1)},
            {Vector3.new(2, 27, 1.5), Vector3.new(i*110 + 29.5, wallCY+8, -HALL_D/2+1)},
        }) do
            local bar = Block(folder, "WinFrame_"..i.."_"..fi, fw[1], fw[2], LIGHT, Enum.Material.Metal)
        end
        -- Stars outside
        for s = 1, 8 do
            local star = Block(folder, "Star_"..i.."_"..s, Vector3.new(0.5, 0.5, 0.5),
                Vector3.new(i*110 + math.random(-25,25), wallCY + math.random(-10,12), -HALL_D/2 - math.random(8,50)),
                Color3.fromRGB(255,255,255), Enum.Material.Neon, 0)
            star.CastShadow = false
        end
    end

    -- ── SPAWN LOCATION (invisible, centered, safe) ────────────
    local spawn = Instance.new("SpawnLocation")
    spawn.Name        = "LobbySpawn"
    spawn.Size        = Vector3.new(40, 1, 40)
    spawn.Position    = Vector3.new(0, FLOOR_TOP, 0)
    spawn.Anchored    = true
    spawn.Transparency = 1
    spawn.CanCollide  = true
    spawn.TeamColor   = BrickColor.new("White")
    spawn.AllowTeamChangeOnTouch = false
    spawn.Duration    = 0
    spawn.Parent      = folder

    -- ── AMBIENT ENERGY CORE (center ceiling drop) ─────────────
    local core = Block(folder, "EnergyCoreGlow", Vector3.new(4, 4, 4),
        Vector3.new(0, FLOOR_TOP + WALL_H - 15, 0), CYAN, Enum.Material.Neon)
    core.CastShadow = false
    PL(core, CYAN, 8, 180)

    -- Rotating rings (static approximation)
    for i = 0, 5 do
        local a = math.rad(i * 60)
        local r = Block(folder, "CoreRing_"..i, Vector3.new(1, 1, 22),
            Vector3.new(math.sin(a)*11, FLOOR_TOP + WALL_H - 15, math.cos(a)*11),
            GOLD, Enum.Material.Neon)
        r.CastShadow = false
    end

    -- Vertical beam from core to floor
    local beam = Block(folder, "CoreBeam", Vector3.new(1.5, WALL_H - 20, 1.5),
        Vector3.new(0, FLOOR_TOP + 10, 0), CYAN, Enum.Material.Neon, 0.6)
    beam.CastShadow = false
    PL(beam, CYAN, 3, 60)

    -- ── NPC TRADERS ───────────────────────────────────────────
    SpaceshipLobby.BuildQMStation(folder, FLOOR_TOP, GOLD, CYAN)
    SpaceshipLobby.BuildApoStation(folder, FLOOR_TOP, GREEN, CYAN)
    SpaceshipLobby.BuildPortalArch(folder, FLOOR_TOP, PURPLE, CYAN)
    SpaceshipLobby.BuildMarketCounter(folder, FLOOR_TOP, CYAN)
    SpaceshipLobby.BuildQuestBoard(folder, FLOOR_TOP)
    SpaceshipLobby.BuildControlRoom(folder, FLOOR_TOP, CYAN, GREEN)
    SpaceshipLobby.BuildExtractionPad(folder, FLOOR_TOP, GREEN)

    print("[SpaceshipLobby] Full hangar generated — Y=" .. LOBBY_Y)
    return folder
end

-- ============================================================
-- QUARTERMASTER STATION — East wing (+X)
-- ============================================================
function SpaceshipLobby.BuildQMStation(folder, yFloor, GOLD, CYAN)
    local bx, bz = 180, -100

    -- Back wall alcove
    Block(folder, "QM_BackWall", Vector3.new(60, 30, 4),
        Vector3.new(bx, yFloor + 15, bz - 25), Color3.fromRGB(30,35,45))

    -- Counter
    local ctr = Block(folder, "QM_Counter", Vector3.new(50, 3, 12),
        Vector3.new(bx, yFloor + 1.5, bz - 10), Color3.fromRGB(35,40,52))
    Block(folder, "QM_CounterTop", Vector3.new(50.4, 0.4, 12.4),
        Vector3.new(bx, yFloor + 3.2, bz - 10), CYAN, Enum.Material.Neon).CastShadow = false
    PL(ctr, CYAN, 1.5, 25)

    -- Weapon display racks on counter
    for i = -3, 3 do
        Block(folder, "QM_GunRack_"..i, Vector3.new(0.35, 0.5, 6),
            Vector3.new(bx + i * 6, yFloor + 3.5, bz - 10),
            Color3.fromRGB(20,20,20), Enum.Material.Metal)
    end

    -- Overhead sign
    local sign = Block(folder, "QM_Sign", Vector3.new(50, 6, 1),
        Vector3.new(bx, yFloor + 18, bz - 25.5), Color3.fromRGB(15,18,28))
    SurfaceSign(sign, Enum.NormalId.Front,
        "QUARTERMASTER RIGGS\nSenjata & Armor Terbaik", 28, GOLD)

    -- Spotlight over desk
    local spot = Block(folder, "QM_Spotlight", Vector3.new(2, 0.5, 2),
        Vector3.new(bx, yFloor + 20, bz - 10), GOLD, Enum.Material.Neon)
    spot.CastShadow = false
    local sl = Instance.new("SpotLight")
    sl.Face = Enum.NormalId.Bottom
    sl.Brightness = 5; sl.Range = 35; sl.Angle = 45
    sl.Color = GOLD; sl.Parent = spot

    BuildNPC(folder, "Quartermaster Riggs",
        Vector3.new(bx, yFloor, bz - 18),
        Color3.fromRGB(35, 50, 80), Color3.fromRGB(25, 30, 50),
        "Beli Senjata / Armor",
        "Siap tempur, prajurit? Senjata terbaik ada di sini. Cek inventorimu dulu."
    )
end

-- ============================================================
-- APOTHECARY STATION — West wing (−X)
-- ============================================================
function SpaceshipLobby.BuildApoStation(folder, yFloor, GREEN, CYAN)
    local bx, bz = -180, -100

    Block(folder, "APO_BackWall", Vector3.new(60, 30, 4),
        Vector3.new(bx, yFloor + 15, bz - 25), Color3.fromRGB(20,35,28))

    local ctr = Block(folder, "APO_Counter", Vector3.new(50, 3, 12),
        Vector3.new(bx, yFloor + 1.5, bz - 10), Color3.fromRGB(22,38,30))
    Block(folder, "APO_CounterTop", Vector3.new(50.4, 0.4, 12.4),
        Vector3.new(bx, yFloor + 3.2, bz - 10), GREEN, Enum.Material.Neon).CastShadow = false
    PL(ctr, GREEN, 1.5, 25)

    -- Glowing potion bottles
    local potColors = {
        Color3.fromRGB(255,50,50), Color3.fromRGB(50,220,100),
        Color3.fromRGB(80,130,255), Color3.fromRGB(255,200,0),
        Color3.fromRGB(255,100,200),
    }
    for i, col in ipairs(potColors) do
        local b = Block(folder, "APO_Potion_"..i,
            Vector3.new(1.5, 2.2, 1.5),
            Vector3.new(bx - 10 + i * 4.5, yFloor + 4.6, bz - 10),
            col, Enum.Material.Neon)
        b.CastShadow = false
        PL(b, col, 2, 10)
    end

    local sign = Block(folder, "APO_Sign", Vector3.new(50, 6, 1),
        Vector3.new(bx, yFloor + 18, bz - 25.5), Color3.fromRGB(12,25,18))
    SurfaceSign(sign, Enum.NormalId.Front,
        "APOTHECARY VAEL\nObat-obatan & Sihir", 28, GREEN)

    local spot = Block(folder, "APO_Spotlight", Vector3.new(2, 0.5, 2),
        Vector3.new(bx, yFloor + 20, bz - 10), GREEN, Enum.Material.Neon)
    spot.CastShadow = false
    local sl = Instance.new("SpotLight")
    sl.Face = Enum.NormalId.Bottom
    sl.Brightness = 5; sl.Range = 35; sl.Angle = 45
    sl.Color = GREEN; sl.Parent = spot

    BuildNPC(folder, "Apothecary Vael",
        Vector3.new(bx, yFloor, bz - 18),
        Color3.fromRGB(55, 30, 80), Color3.fromRGB(35, 18, 55),
        "Beli Obat / Sihir",
        "Lukamu bisa disembuhkan. Tubuhmu adalah senjata terkuat — jaga baik-baik."
    )
end

-- ============================================================
-- PORTAL ARCH — North center
-- ============================================================
function SpaceshipLobby.BuildPortalArch(folder, yFloor, PURPLE, CYAN)
    local px, pz = 0, -160

    -- Side pillars
    for _, sx in ipairs({-18, 18}) do
        local pillar = Block(folder, "Portal_Pillar_"..sx,
            Vector3.new(5, 35, 5),
            Vector3.new(px + sx, yFloor + 17.5, pz),
            PURPLE, Enum.Material.Neon)
        pillar.CastShadow = false
        PL(pillar, PURPLE, 3, 35)
    end
    -- Top bar
    Block(folder, "Portal_TopBar", Vector3.new(41, 5, 5),
        Vector3.new(px, yFloor + 37.5, pz), PURPLE, Enum.Material.Neon).CastShadow = false

    -- Void surface
    local void = Block(folder, "Portal_Void",
        Vector3.new(29, 28, 0.5),
        Vector3.new(px, yFloor + 15, pz),
        Color3.fromRGB(40, 10, 100), Enum.Material.Neon, 0.3)
    void.CastShadow = false
    PL(void, PURPLE, 6, 70)

    -- Particle-like dots in void
    for i = 1, 12 do
        local dot = Block(folder, "VoidDot_"..i, Vector3.new(0.6,0.6,0.6),
            Vector3.new(px + math.random(-13,13), yFloor + math.random(3,28), pz - 0.8),
            Color3.fromRGB(200, 150, 255), Enum.Material.Neon)
        dot.CastShadow = false
    end

    -- Portal sign
    local sign = Block(folder, "Portal_Sign", Vector3.new(50, 7, 1),
        Vector3.new(px, yFloor + 47, pz), Color3.fromRGB(12, 8, 25))
    SurfaceSign(sign, Enum.NormalId.Front,
        "PORTAL DOMAIN FANTASI\nMasuk ke Kalimantan", 28, Color3.fromRGB(200,150,255))

    -- ProximityPrompt on void
    local pp = Instance.new("ProximityPrompt")
    pp.ActionText = "Masuk Kalimantan"
    pp.ObjectText = "Portal Fantasi"
    pp.MaxActivationDistance = 14
    pp.Parent = void

    BuildNPC(folder, "Portal Keeper",
        Vector3.new(px, yFloor, pz + 14),
        Color3.fromRGB(45, 18, 85), Color3.fromRGB(28, 10, 55),
        "Bicara dengan Penjaga",
        "Kalimantan menantimu. Pastikan tasmu terisi sebelum masuk — tidak ada jalan kembali yang mudah."
    )
end

-- ============================================================
-- FLEA MARKET COUNTER — South
-- ============================================================
function SpaceshipLobby.BuildMarketCounter(folder, yFloor, CYAN)
    local mz = 130
    Block(folder, "Market_Counter", Vector3.new(180, 3, 14),
        Vector3.new(0, yFloor + 1.5, mz), Color3.fromRGB(28, 32, 45))
    local top = Block(folder, "Market_CounterTop", Vector3.new(180.4, 0.45, 14.4),
        Vector3.new(0, yFloor + 3.25, mz), CYAN, Enum.Material.Neon)
    top.CastShadow = false
    PL(top, CYAN, 2, 40)

    local sign = Block(folder, "Market_Sign", Vector3.new(150, 8, 1),
        Vector3.new(0, yFloor + 15, mz - 7.5), Color3.fromRGB(12, 15, 25))
    SurfaceSign(sign, Enum.NormalId.Front,
        "FLEA MARKET  —  Jual & Beli Antar Pemain  [F untuk buka]",
        26, CYAN)

    -- Stalls
    for i = -2, 2 do
        local stall = Block(folder, "Market_Stall_"..i,
            Vector3.new(28, 0.3, 8),
            Vector3.new(i * 34, yFloor + 3.5, mz),
            Color3.fromRGB(40, 48, 60))
        -- Items on stall (visual only)
        for j = 1, 3 do
            local item = Block(folder, "StallItem_"..i.."_"..j,
                Vector3.new(2, 2, 2),
                Vector3.new(i*34 - 5 + j*4, yFloor + 4.8, mz),
                Color3.fromHSV(math.random(), 0.7, 0.9), Enum.Material.SmoothPlastic)
        end
    end
end

-- ============================================================
-- QUEST BOARD — West
-- ============================================================
function SpaceshipLobby.BuildQuestBoard(folder, yFloor)
    local qx, qz = -240, 50
    -- Board backing
    local back = Block(folder, "QuestBoard_Back", Vector3.new(6, 35, 60),
        Vector3.new(qx - 3, yFloor + 17.5, qz), Color3.fromRGB(35, 28, 18))
    local board = Block(folder, "QuestBoard_Face", Vector3.new(0.4, 30, 55),
        Vector3.new(qx, yFloor + 15, qz), Color3.fromRGB(22, 18, 12))

    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Right
    sg.CanvasSize = Vector2.new(440, 600)
    sg.Parent = board

    local bgQ = Instance.new("Frame")
    bgQ.Size = UDim2.new(1,0,1,0)
    bgQ.BackgroundColor3 = Color3.fromRGB(18,14,8)
    bgQ.Parent = sg

    local titleQ = Instance.new("TextLabel")
    titleQ.Size = UDim2.new(1,0,0,70); titleQ.Position = UDim2.new(0,0,0,0)
    titleQ.BackgroundColor3 = Color3.fromRGB(120, 75, 15)
    titleQ.Text = "PAPAN MISI HARIAN"
    titleQ.Font = Enum.Font.GothamBold; titleQ.TextSize = 34
    titleQ.TextColor3 = Color3.fromRGB(255, 225, 130)
    titleQ.TextXAlignment = Enum.TextXAlignment.Center
    titleQ.TextYAlignment = Enum.TextYAlignment.Center
    titleQ.Parent = bgQ

    local quests = {
        "Bertahan hidup dan ekstrak dari Kalimantan",
        "Bunuh 5 monster di zona hutan dalam",
        "Temukan 1 Gold Bar dan bawa keluar",
        "Selamat dari serangan meteor",
        "Kumpulkan 10 Healing Herb",
        "Jual 3 item ke Flea Market",
    }
    for i, q in ipairs(quests) do
        local ql = Instance.new("TextLabel")
        ql.Size = UDim2.new(1,0,0,80)
        ql.Position = UDim2.new(0,0,0,70 + (i-1)*88)
        ql.BackgroundColor3 = i%2==0 and Color3.fromRGB(25,20,12) or Color3.fromRGB(20,16,10)
        ql.Text = i .. ".  " .. q
        ql.Font = Enum.Font.Gotham; ql.TextSize = 22
        ql.TextColor3 = Color3.fromRGB(215, 205, 175)
        ql.TextWrapped = true; ql.TextXAlignment = Enum.TextXAlignment.Left
        ql.Parent = bgQ
        local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0,10); pad.Parent = ql
    end

    PL(board, Color3.fromRGB(255, 200, 100), 1.5, 20)
end

-- ============================================================
-- CONTROL ROOM — East side
-- ============================================================
function SpaceshipLobby.BuildControlRoom(folder, yFloor, CYAN, GREEN)
    local cx = 240
    for i = -2, 2 do
        local terminal = Block(folder, "Terminal_"..i,
            Vector3.new(10, 15, 5),
            Vector3.new(cx, yFloor + 7.5, i * 25),
            Color3.fromRGB(18, 22, 32))

        local screen = Block(folder, "Screen_"..i,
            Vector3.new(7.5, 9, 0.4),
            Vector3.new(cx - 4.8, yFloor + 9, i * 25),
            Color3.fromRGB(0, 140, 210), Enum.Material.Neon, 0.15)
        screen.CastShadow = false
        PL(screen, CYAN, 2, 22)

        local sg = Instance.new("SurfaceGui")
        sg.Face = Enum.NormalId.Right; sg.CanvasSize = Vector2.new(300, 360)
        sg.Parent = screen
        local scl = Instance.new("TextLabel")
        scl.Size = UDim2.new(1,0,1,0)
        scl.BackgroundTransparency = 1
        scl.Text = "APEX v9.1\nSTATUS: ONLINE\nZONE: AKTIF\nWEATHER: --\nPLAYERS: --"
        scl.Font = Enum.Font.Code; scl.TextSize = 22
        scl.TextColor3 = Color3.fromRGB(100, 255, 180)
        scl.TextXAlignment = Enum.TextXAlignment.Left
        scl.TextYAlignment = Enum.TextYAlignment.Top
        scl.Parent = sg
    end
end

-- ============================================================
-- EXTRACTION DEPOSIT PAD — South-east
-- ============================================================
function SpaceshipLobby.BuildExtractionPad(folder, yFloor, GREEN)
    local ex, ez = 180, 100
    -- Pad
    local pad = Block(folder, "ExtractPad",
        Vector3.new(40, 0.8, 40),
        Vector3.new(ex, yFloor + 0.4, ez),
        GREEN, Enum.Material.Neon, 0.4)
    pad.CastShadow = false
    PL(pad, GREEN, 3, 50)

    -- Corner pillars
    for _, corner in ipairs({{-18,-18},{18,-18},{-18,18},{18,18}}) do
        local cp = Block(folder, "ExtractCorner",
            Vector3.new(2, 8, 2),
            Vector3.new(ex + corner[1], yFloor + 4, ez + corner[2]),
            GREEN, Enum.Material.Neon)
        cp.CastShadow = false
        PL(cp, GREEN, 2, 15)
    end

    local sign = Block(folder, "ExtractSign", Vector3.new(36, 7, 1),
        Vector3.new(ex, yFloor + 14, ez - 20.5), Color3.fromRGB(10, 20, 12))
    SurfaceSign(sign, Enum.NormalId.Front,
        "ZONA DEPOSIT EKSTRAKSI\nLoot & Rampasan Misi", 26, GREEN)

    -- ProximityPrompt on pad
    local pp = Instance.new("ProximityPrompt")
    pp.ActionText = "Deposit Loot"
    pp.ObjectText = "Extraction Deposit Pad"
    pp.MaxActivationDistance = 18
    pp.Parent = pad
end

-- ============================================================
-- PLAYER SAFETY: teleport if spawned below lobby
-- ============================================================
function SpaceshipLobby.InitializePlayerLobby(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.6)
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and root.Position.Y < 900 then
            root.CFrame = CFrame.new(0, FLOOR_TOP + 6, 0)
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
