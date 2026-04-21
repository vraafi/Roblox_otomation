-- LOBBY_SPACESHIP_1.lua
-- Rancang lobby di pesawat luar angkasa besar dengan domain investor per player.
-- Visual Assets included via Instance generation.

local SpaceshipLobby = {}

-- Arena Breakout realistic medical tracking per limb
local PlayerHealthData = {}

function SpaceshipLobby.Initialize()
    SpaceshipLobby.GenerateVisualSpaceship()
    game.Players.PlayerAdded:Connect(SpaceshipLobby.InitializePlayerLobby)
end

function SpaceshipLobby.GenerateVisualSpaceship()
    -- Create the physical lobby in workspace
    local lobbyFolder = Instance.new("Folder")
    lobbyFolder.Name = "SpaceshipLobby"
    lobbyFolder.Parent = workspace

    -- Main Hangar Floor
    local floor = Instance.new("Part")
    floor.Name = "HangarFloor"
    floor.Size = Vector3.new(200, 2, 200)
    floor.Position = Vector3.new(0, 1000, 0) -- High in the sky
    floor.Anchored = true
    floor.Material = Enum.Material.Metal
    floor.Color = Color3.fromRGB(40, 40, 45)
    floor.Parent = lobbyFolder

    -- Add a visual sci-fi crate (Asset ID example)
    local crate = Instance.new("Part")
    crate.Size = Vector3.new(4, 4, 4)
    crate.Position = Vector3.new(0, 1002, 0)
    crate.Anchored = true
    crate.Parent = lobbyFolder

    local crateMesh = Instance.new("SpecialMesh")
    crateMesh.MeshType = Enum.MeshType.FileMesh
    crateMesh.MeshId = "rbxassetid://12345678" -- Placeholder SciFi Crate
    crateMesh.TextureId = "rbxassetid://87654321"
    crateMesh.Parent = crate

    -- Set spawn point to the ship
    local spawnPoint = Instance.new("SpawnLocation")
    spawnPoint.Size = Vector3.new(10, 1, 10)
    spawnPoint.Position = Vector3.new(0, 1001, 0)
    spawnPoint.Anchored = true
    spawnPoint.TeamColor = BrickColor.new("White")
    spawnPoint.Parent = lobbyFolder
end

function SpaceshipLobby.InitializePlayerLobby(player)
    -- Initialize Arena Breakout realistic health system
    PlayerHealthData[player.UserId] = {
        Head = { Status = "Healthy", MaxHP = 35, CurrentHP = 35 },
        Thorax = { Status = "Healthy", MaxHP = 85, CurrentHP = 85 },
        Stomach = { Status = "Healthy", MaxHP = 70, CurrentHP = 70 },
        LeftArm = { Status = "Healthy", MaxHP = 60, CurrentHP = 60 },
        RightArm = { Status = "Healthy", MaxHP = 60, CurrentHP = 60 },
        LeftLeg = { Status = "Healthy", MaxHP = 65, CurrentHP = 65 },
        RightLeg = { Status = "Healthy", MaxHP = 65, CurrentHP = 65 },
        Ailments = {} -- "Bleeding", "BrokenBone", "Pain"
    }

    -- Assign a personal investor domain (Storage Area)
    SpaceshipLobby.GenerateInvestorDomain(player)
end

function SpaceshipLobby.GenerateInvestorDomain(player)
    -- Calculate unique offset for this player's domain
    local offset = #game.Players:GetPlayers() * 50

    local domain = Instance.new("Part")
    domain.Name = player.Name .. "_StorageDomain"
    domain.Size = Vector3.new(30, 1, 30)
    domain.Position = Vector3.new(100 + offset, 1001, 0)
    domain.Anchored = true
    domain.Material = Enum.Material.Neon
    domain.Color = Color3.fromRGB(0, 100, 255)
    domain.Parent = workspace:FindFirstChild("SpaceshipLobby") or workspace
end

function SpaceshipLobby.ApplyDamage(player, limb, amount)
    local data = PlayerHealthData[player.UserId]
    if not data or not data[limb] then return end

    data[limb].CurrentHP = data[limb].CurrentHP - amount

    if data[limb].CurrentHP <= 0 then
        data[limb].Status = "Destroyed"
        -- If head or thorax is destroyed, player dies (Arena Breakout logic)
        if limb == "Head" or limb == "Thorax" then
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.Health = 0
            end
        else
            -- Broken limb penalties (e.g., walk speed reduction if leg)
            table.insert(data.Ailments, "Broken" .. limb)
        end
    elseif amount > 10 and math.random() > 0.5 then
        table.insert(data.Ailments, "Bleeding")
    end
end

return SpaceshipLobby
