local MountSystem = {}

MountSystem.Mounts = {
    ["RidingHorse"] = {
        tier = 3,
        maxLoad = 100,
        speed = 50,
        resistances = 10,
        hitPoints = 500
    },
    ["ArmoredHorse"] = {
        tier = 4,
        maxLoad = 120,
        speed = 60,
        resistances = 40,
        hitPoints = 800
    }
}

function MountSystem.Mount(player, mountId, adventurerLevel)
    local mountData = MountSystem.Mounts[mountId]
    if not mountData then
        return false, "Invalid Mount"
    end

    if adventurerLevel < mountData.tier then
        return false, "Adventurer node level too low"
    end

    -- Simulates mounting as a channeled spell
    local mountTime = 3 -- 3 seconds base mount channel
    print(player.Name .. " is mounting " .. mountId .. "...")

    -- In a real scenario, this would yield for mountTime and check for interruptions.
    -- Once successfully channeled, apply stats.
    local activeMountStats = {
        maxLoad = mountData.maxLoad,
        speed = mountData.speed,
        resistances = mountData.resistances,
        hitPoints = mountData.hitPoints
    }

    return true, activeMountStats
end

function MountSystem.Dismount(player)
    print(player.Name .. " has dismounted.")
    -- Removes the mount stats and active status
    return true
end

return MountSystem
