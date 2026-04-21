local ZoneSystem = {}

ZoneSystem.ZoneTypes = {
    BLUE = "Blue",
    YELLOW = "Yellow",
    RED = "Red",
    BLACK = "Black"
}

local playerFlags = {}

function ZoneSystem.FlagForCombat(player)
    playerFlags[player.UserId] = {
        isFlagged = true,
        isFactionFlagged = false -- Basic implementation, would hook into FactionWarfareSystem
    }
    print(player.Name .. " is now flagged for combat.")
end

function ZoneSystem.GetPlayerFlagState(player)
    return playerFlags[player.UserId] or { isFlagged = false, isFactionFlagged = false }
end

function ZoneSystem.CanAttack(attacker, target, zoneType)
    local attackerFlags = ZoneSystem.GetPlayerFlagState(attacker)
    local targetFlags = ZoneSystem.GetPlayerFlagState(target)

    if zoneType == ZoneSystem.ZoneTypes.RED or zoneType == ZoneSystem.ZoneTypes.YELLOW then
        -- Flagging allows a player to attack unflagged players
        if attackerFlags.isFlagged and not targetFlags.isFlagged then
            return true
        end

        -- A flagged player can always be attacked by anyone in red zones
        if zoneType == ZoneSystem.ZoneTypes.RED and targetFlags.isFlagged then
            return true
        end

        -- A flagged player can be attacked by anyone BUT faction-flagged players in yellow zones
        if zoneType == ZoneSystem.ZoneTypes.YELLOW and targetFlags.isFlagged then
            if not attackerFlags.isFactionFlagged then
                return true
            end
        end
    end

    return false
end

return ZoneSystem
