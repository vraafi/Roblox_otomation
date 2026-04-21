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
            -- In Roblox, check distance from character to zone.Position
            -- For this logic template, we assume we calculate distance somehow:
            local dist = 0 -- placeholder for (playerData.Position - zone.Position).Magnitude

            -- Simplified distance check
            local isInZone = dist <= zone.Radius

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

    -- Save their inventory to the database
    -- Move player back to the lobby
    playerData.Status = "Extracted"
end

return ExtractionManager
