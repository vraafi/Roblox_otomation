-- NPCShopClient.client.lua
-- Handles NPC shop UI on the client side.
-- Opens when server fires "OpenNPCShop" RemoteEvent.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player   = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Shop item databases ───────────────────────────────────────
local SHOP_DATA = {
    quartermaster = {
        title   = "Quartermaster Riggs — Senjata & Armor",
        color   = Color3.fromRGB(220, 175, 50),
        items   = {
            { name = "Pistol",                nameID = "Pistol",               price = 150,  desc = "Senjata ringan, 15 ammo" },
            { name = "Shotgun",               nameID = "Shotgun",              price = 320,  desc = "Hantaman jarak dekat" },
            { name = "Assault Rifle",         nameID = "Senapan Serbu",        price = 550,  desc = "Otomatis, 30 ammo" },
            { name = "Sniper Rifle",          nameID = "Senapan Runduk",       price = 900,  desc = "Jangkauan jauh, 5 ammo" },
            { name = "Combat Helmet",         nameID = "Helm Tempur",          price = 200,  desc = "+35 armor kepala" },
            { name = "Kevlar Vest",           nameID = "Rompi Anti-Peluru",    price = 380,  desc = "+85 armor torso" },
            { name = "Tactical Boots",        nameID = "Sepatu Taktis",        price = 180,  desc = "+25% kecepatan lari" },
            { name = "Fragmentation Grenade", nameID = "Granat Fragmentasi",   price = 120,  desc = "AoE damage tinggi" },
        }
    },
    apothecary = {
        title   = "Apothecary Vael — Obat & Sihir",
        color   = Color3.fromRGB(80, 220, 120),
        items   = {
            { name = "Healing Herb",   nameID = "Ramuan Sembuh",       price = 60,   desc = "Pulihkan 20 HP" },
            { name = "Health Potion",  nameID = "Ramuan HP",           price = 120,  desc = "Pulihkan 50 HP instan" },
            { name = "Mana Crystal",   nameID = "Kristal Mana",        price = 200,  desc = "Pulihkan 60 Mana" },
            { name = "Antidote",       nameID = "Penawar Racun",       price = 90,   desc = "Hapus efek racun" },
            { name = "Bandage Roll",   nameID = "Perban Gulung",       price = 50,   desc = "Hentikan pendarahan" },
            { name = "Bone Splint",    nameID = "Bidai Tulang",        price = 75,   desc = "Sembuhkan tulang patah" },
            { name = "Power Elixir",   nameID = "Eliksir Kekuatan",   price = 350,  desc = "+30% DMG selama 60 detik" },
            { name = "Mana Stone",     nameID = "Batu Mana",          price = 280,  desc = "Pasang ke inti senjata" },
        }
    },
}

-- ── Active credits (mock) ─────────────────────────────────────
local mockCredits = 1500

-- ── Build shop GUI ────────────────────────────────────────────
local function OpenShop(npcType)
    -- Remove existing
    local old = playerGui:FindFirstChild("NPCShopGui")
    if old then old:Destroy() end

    local data = SHOP_DATA[npcType]
    if not data then return end

    local sg = Instance.new("ScreenGui")
    sg.Name            = "NPCShopGui"
    sg.ResetOnSpawn    = false
    sg.IgnoreGuiInset  = false
    sg.DisplayOrder    = 20
    sg.Parent          = playerGui

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Size                 = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.55
    backdrop.Parent               = sg

    -- Main panel
    local panel = Instance.new("Frame")
    panel.Name                   = "ShopPanel"
    panel.Size                   = UDim2.new(0, 680, 0, 540)
    panel.Position               = UDim2.new(0.5, -340, 0.5, -270)
    panel.BackgroundColor3       = Color3.fromRGB(10, 12, 18)
    panel.BorderSizePixel        = 0
    panel.Parent                 = sg

    local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 12); pc.Parent = panel
    local ps = Instance.new("UIStroke"); ps.Color = data.color; ps.Thickness = 2; ps.Parent = panel

    -- Header
    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 54)
    header.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    header.BorderSizePixel  = 0
    header.Parent           = panel
    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 12); hc.Parent = header

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size                 = UDim2.new(1, -110, 1, 0)
    titleLbl.Position             = UDim2.new(0, 14, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text                 = data.title
    titleLbl.Font                 = Enum.Font.GothamBold
    titleLbl.TextSize             = 17
    titleLbl.TextColor3           = data.color
    titleLbl.TextXAlignment       = Enum.TextXAlignment.Left
    titleLbl.TextYAlignment       = Enum.TextYAlignment.Center
    titleLbl.TextWrapped          = true
    titleLbl.Parent               = header

    -- Credits display
    local creditLbl = Instance.new("TextLabel")
    creditLbl.Name                  = "CreditLabel"
    creditLbl.Size                  = UDim2.new(0, 140, 0, 30)
    creditLbl.Position              = UDim2.new(0, 14, 0, 58)
    creditLbl.BackgroundColor3      = Color3.fromRGB(20, 26, 18)
    creditLbl.Text                  = "Kredit: " .. mockCredits
    creditLbl.Font                  = Enum.Font.GothamBold
    creditLbl.TextSize              = 14
    creditLbl.TextColor3            = Color3.fromRGB(120, 255, 100)
    creditLbl.TextXAlignment        = Enum.TextXAlignment.Center
    creditLbl.TextYAlignment        = Enum.TextYAlignment.Center
    creditLbl.Parent                = panel
    local clc = Instance.new("UICorner"); clc.CornerRadius = UDim.new(0, 6); clc.Parent = creditLbl

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 38, 0, 38)
    closeBtn.Position         = UDim2.new(1, -46, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.Text             = "X"
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 18
    closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    closeBtn.Parent           = header
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(panel, TweenInfo.new(0.18), { Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0) }):Play()
        task.wait(0.2)
        sg:Destroy()
    end)

    -- Scroll frame for items
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                    = UDim2.new(1, -20, 1, -110)
    scroll.Position                = UDim2.new(0, 10, 0, 96)
    scroll.BackgroundTransparency  = 1
    scroll.ScrollBarThickness      = 4
    scroll.ScrollBarImageColor3    = data.color
    scroll.CanvasSize              = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
    scroll.Parent                  = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding         = UDim.new(0, 6)
    listLayout.SortOrder       = Enum.SortOrder.LayoutOrder
    listLayout.Parent          = scroll

    -- Item rows
    for i, item in ipairs(data.items) do
        local row = Instance.new("Frame")
        row.Name             = "Item_" .. i
        row.Size             = UDim2.new(1, -10, 0, 66)
        row.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(14, 17, 24) or Color3.fromRGB(18, 22, 32)
        row.LayoutOrder      = i
        row.Parent           = scroll
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 7); rc.Parent = row

        -- Item name
        local nameL = Instance.new("TextLabel")
        nameL.Size                 = UDim2.new(0.42, 0, 0.48, 0)
        nameL.Position             = UDim2.new(0, 10, 0, 4)
        nameL.BackgroundTransparency = 1
        nameL.Text                 = item.name
        nameL.Font                 = Enum.Font.GothamBold
        nameL.TextSize             = 15
        nameL.TextColor3           = Color3.fromRGB(235, 230, 210)
        nameL.TextXAlignment       = Enum.TextXAlignment.Left
        nameL.Parent               = row

        -- Indonesian name
        local nameID = Instance.new("TextLabel")
        nameID.Size                 = UDim2.new(0.42, 0, 0.4, 0)
        nameID.Position             = UDim2.new(0, 10, 0.5, 0)
        nameID.BackgroundTransparency = 1
        nameID.Text                 = item.nameID
        nameID.Font                 = Enum.Font.Gotham
        nameID.TextSize             = 12
        nameID.TextColor3           = Color3.fromRGB(150, 155, 165)
        nameID.TextXAlignment       = Enum.TextXAlignment.Left
        nameID.Parent               = row

        -- Description
        local descL = Instance.new("TextLabel")
        descL.Size                 = UDim2.new(0.36, 0, 1, -8)
        descL.Position             = UDim2.new(0.42, 0, 0, 4)
        descL.BackgroundTransparency = 1
        descL.Text                 = item.desc
        descL.Font                 = Enum.Font.Gotham
        descL.TextSize             = 12
        descL.TextColor3           = Color3.fromRGB(130, 140, 155)
        descL.TextWrapped          = true
        descL.TextXAlignment       = Enum.TextXAlignment.Left
        descL.TextYAlignment       = Enum.TextYAlignment.Center
        descL.Parent               = row

        -- Price label
        local priceL = Instance.new("TextLabel")
        priceL.Size                 = UDim2.new(0, 75, 0, 26)
        priceL.Position             = UDim2.new(1, -160, 0.5, -13)
        priceL.BackgroundColor3     = Color3.fromRGB(20, 30, 20)
        priceL.Text                 = tostring(item.price) .. " kr"
        priceL.Font                 = Enum.Font.GothamBold
        priceL.TextSize             = 14
        priceL.TextColor3           = Color3.fromRGB(100, 240, 100)
        priceL.TextXAlignment       = Enum.TextXAlignment.Center
        priceL.TextYAlignment       = Enum.TextYAlignment.Center
        priceL.Parent               = row
        local plc = Instance.new("UICorner"); plc.CornerRadius = UDim.new(0, 5); plc.Parent = priceL

        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Size             = UDim2.new(0, 72, 0, 34)
        buyBtn.Position         = UDim2.new(1, -82, 0.5, -17)
        buyBtn.BackgroundColor3 = data.color
        buyBtn.Text             = "BELI"
        buyBtn.Font             = Enum.Font.GothamBold
        buyBtn.TextSize         = 14
        buyBtn.TextColor3       = Color3.fromRGB(10, 8, 4)
        buyBtn.Parent           = row
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 7); bc.Parent = buyBtn

        buyBtn.MouseButton1Click:Connect(function()
            if mockCredits >= item.price then
                mockCredits = mockCredits - item.price
                creditLbl.Text = "Kredit: " .. mockCredits
                -- Flash green
                TweenService:Create(buyBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(50, 220, 80) }):Play()
                task.wait(0.15)
                TweenService:Create(buyBtn, TweenInfo.new(0.15), { BackgroundColor3 = data.color }):Play()
                -- Confirmation toast
                local toast = Instance.new("TextLabel")
                toast.Size                 = UDim2.new(0, 320, 0, 44)
                toast.Position             = UDim2.new(0.5, -160, 0, -10)
                toast.BackgroundColor3     = Color3.fromRGB(20, 80, 30)
                toast.Text                 = "Dibeli: " .. item.name .. " (-" .. item.price .. " kr)"
                toast.Font                 = Enum.Font.GothamBold
                toast.TextSize             = 15
                toast.TextColor3           = Color3.fromRGB(150, 255, 150)
                toast.TextXAlignment       = Enum.TextXAlignment.Center
                toast.TextYAlignment       = Enum.TextYAlignment.Center
                toast.ZIndex               = 50
                toast.Parent               = sg
                local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 8); tc.Parent = toast
                TweenService:Create(toast, TweenInfo.new(0.4), { Position = UDim2.new(0.5,-160,0,12) }):Play()
                task.wait(1.6)
                TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
                task.wait(0.35)
                toast:Destroy()
            else
                -- Not enough credits — flash red
                TweenService:Create(buyBtn, TweenInfo.new(0.08), { BackgroundColor3 = Color3.fromRGB(220, 50, 50) }):Play()
                task.wait(0.2)
                TweenService:Create(buyBtn, TweenInfo.new(0.15), { BackgroundColor3 = data.color }):Play()
            end
        end)
    end

    -- Entrance animation
    panel.Size     = UDim2.new(0, 0, 0, 0)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size     = UDim2.new(0, 680, 0, 540),
        Position = UDim2.new(0.5, -340, 0.5, -270)
    }):Play()
end

-- ── Listen for server event ───────────────────────────────────
local events = ReplicatedStorage:WaitForChild("Events", 10)
if events then
    local shopEvent = events:WaitForChild("OpenNPCShop", 10)
    if shopEvent then
        shopEvent.OnClientEvent:Connect(function(npcType)
            OpenShop(npcType)
        end)
    end
end
