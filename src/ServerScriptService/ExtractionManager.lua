-- ExtractionManager.lua
-- Handles the Arena Breakout extraction logic

local ExtractionManager = {}

-- Stores active extraction zones on the map
ExtractionManager.ActiveZones = {}

-- Time required to stand in the zone to extract
local EXTRACTION_TIME_REQUIRED = 10 -- seconds

function ExtractionManager.RegisterExtractionZone(zoneId, position, radius)
    ExtractionManager.ActiveZones[zoneId] = {
        Id = zoneId,
        Position = position,
        Radius = radius,
        PlayersExtracting = {} -- Maps PlayerId to TimeSpent
    }
end

-- Call this in a server heartbeat/loop
function ExtractionManager.UpdateExtractions(dt, activePlayers)
    for zoneId, zone in pairs(ExtractionManager.ActiveZones) do
        -- Iterate over all alive players (activePlayers is passed from PlayerManager)
        for playerId, playerData in pairs(activePlayers) do
            local isInZone = false
            local player = game.Players:GetPlayerByUserId(playerId)
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (player.Character.HumanoidRootPart.Position - zone.Position).Magnitude
                isInZone = dist <= zone.Radius
            end

            if isInZone then
                if not zone.PlayersExtracting[playerId] then
                    zone.PlayersExtracting[playerId] = 0
                end

                zone.PlayersExtracting[playerId] = zone.PlayersExtracting[playerId] + dt

                if zone.PlayersExtracting[playerId] >= EXTRACTION_TIME_REQUIRED then
                    ExtractionManager.ExtractPlayer(playerId, playerData)
                    zone.PlayersExtracting[playerId] = nil -- remove from tracking
                end
            else
                -- Reset if they leave the zone
                zone.PlayersExtracting[playerId] = nil
            end
        end
    end
end

function ExtractionManager.ExtractPlayer(playerId, playerData)
    -- Arena Breakout logic: Player successfully extracts with all their loot
    print("Player " .. playerId .. " has extracted successfully!")

    local ServerScriptService = game:GetService("ServerScriptService")

    -- Return any borrowed gear to teammates via Mail
    local LendingSystem = require(ServerScriptService:WaitForChild("LendingSystem"))
    LendingSystem.ReturnBorrowedGear(playerId)

    -- Deposit remaining un-secured loot into the Lobby Stash
    local LobbyStashSystem = require(ServerScriptService:WaitForChild("LobbyStashSystem"))
    local player = game.Players:GetPlayerByUserId(playerId)

    if player then
        LobbyStashSystem.DepositExtractedLoot(player, playerData.Inventory)
    end


    local player = game.Players:GetPlayerByUserId(playerId)
    if player and player.Character then
        local ServerScriptService = game:GetService("ServerScriptService")
        local SpaceshipLobby = require(ServerScriptService:WaitForChild("LOBBY_SPACESHIP_1"))

        -- Teleport them to the spaceship
        player.Character:PivotTo(CFrame.new(0, 1005, 0))
    end

    playerData.Status = "Extracted"
end

return ExtractionManager
