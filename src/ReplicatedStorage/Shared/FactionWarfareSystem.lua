local FactionWarfareSystem = {}

-- Faction Warfare is a large-scale, objective-based PvP system on the Royal Continent.
FactionWarfareSystem.Factions = {
    "Martlock",
    "Lymhurst",
    "Bridgewatch",
    "Fort Sterling",
    "Thetford",
    "Caerleon" -- 6 city factions
}

FactionWarfareSystem.Provinces = {}

function FactionWarfareSystem.InitProvince(provinceId, owningFaction)
    FactionWarfareSystem.Provinces[provinceId] = {
        id = provinceId,
        owner = owningFaction,
        isUnderSiege = false,
        siegeStage = "None"
    }
end

function FactionWarfareSystem.EnlistPlayer(player, factionName)
    local validFaction = false
    for _, faction in ipairs(FactionWarfareSystem.Factions) do
        if faction == factionName then
            validFaction = true
            break
        end
    end

    if not validFaction then
        return false, "Invalid faction name"
    end

    -- In a real scenario, this would apply the faction flag to the player's character
    print(player.Name .. " enlisted in Faction: " .. factionName)
    return true
end

function FactionWarfareSystem.StartFortressSiege(provinceId)
    local province = FactionWarfareSystem.Provinces[provinceId]
    if not province then
        return false, "Province not found"
    end

    province.isUnderSiege = true
    province.siegeStage = "Pre-Siege"

    -- Emulate the notification confirmed in the trace
    print("A Fortress Siege has begun in province " .. provinceId .. "!")

    return true
end

function FactionWarfareSystem.AdvanceSiegeToLastStand(provinceId)
    local province = FactionWarfareSystem.Provinces[provinceId]
    if not province or not province.isUnderSiege then
        return false
    end

    province.siegeStage = "Last Stand"

    -- Emulate the notification confirmed in the trace
    print("Fortress Siege in " .. provinceId .. " has entered the Last Stand stage!")

    return true
end

return FactionWarfareSystem
