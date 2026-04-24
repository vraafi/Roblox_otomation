-- CombatManager.lua
-- Handles server-side validation for combat and magic usage.

local CombatManager = {}

-- Fallbacks for non-Roblox env testing
local ItemDatabase = require(script.Parent.Parent.ReplicatedStorage.ItemDatabase)

function CombatManager.Initialize()
    -- Normally we'd hook up to RemoteEvents here
end

-- Simulates an attack. Player data would be fetched from PlayerManager in a real scenario
function CombatManager.ProcessAttack(playerData, targetData)
    local weaponInstance = playerData.Inventory.Equipped.WeaponInstance

    -- Fallback for basic non-instanced weapons (wands, legacy gear)
    if not weaponInstance then
        local weaponId = playerData.Inventory.Equipped.Weapon
        if not weaponId then return false, "No weapon equipped" end
        local weaponInfo = ItemDatabase.GetItem(weaponId)
        if not weaponInfo then return false, "Invalid weapon" end

        if weaponInfo.SubType == "MagicWand" then
            if playerData.CurrentMana < weaponInfo.ManaCost then
                return false, "Not enough mana! Equip better armor with a higher core level."
            end
            playerData.CurrentMana = playerData.CurrentMana - weaponInfo.ManaCost
            targetData.CurrentHealth = targetData.CurrentHealth - weaponInfo.BaseDamage
            return true, "Cast magic successfully"
        end
        return false, "Unknown weapon type"
    end

    -- Modern Hardcore Firearms Logic
    local weaponInfo = ItemDatabase.GetItem(weaponInstance.BaseItemId)
    if weaponInfo.RequiresMagazine then
        if not weaponInstance.ChamberedRound then
            return false, "Click! Weapon empty or not cocked."
        end

        local ammoInfo = ItemDatabase.GetItem(weaponInstance.ChamberedRound)
        weaponInstance.ChamberedRound = nil -- Consume round

        -- Cycle next round from mag into chamber
        if weaponInstance.LoadedMagazine and #weaponInstance.LoadedMagazine.CurrentAmmo > 0 then
            weaponInstance.ChamberedRound = table.remove(weaponInstance.LoadedMagazine.CurrentAmmo, 1)
        end

        local damage = ammoInfo.Damage or 10
        local mitigatedDamage = math.max(1, damage - (targetData.TotalStats.Defense * 0.5))
        targetData.CurrentHealth = targetData.CurrentHealth - mitigatedDamage

        return true, "Fired " .. ammoInfo.Id
    end

    return false, "Unknown instance"
end

function CombatManager.ProcessLimbAttack(attackerId, targetId, hitLimb)
    local PlayerManager = require(script.Parent.PlayerManager)
    local attackerData = PlayerManager.ActivePlayers[attackerId]
    local targetData = PlayerManager.ActivePlayers[targetId]

    if not attackerData or not targetData then return false, "Invalid players" end

    local weaponId = attackerData.Inventory.Equipped.Weapon
    if not weaponId then return false, "No weapon equipped" end

    local weaponInfo = ItemDatabase.GetItem(weaponId)
    if not weaponInfo then return false, "Invalid weapon" end

    local damage = weaponInfo.Damage or weaponInfo.BaseDamage or 10

    -- Check for magic
    if weaponInfo.SubType == "MagicWand" then
        if attackerData.CurrentMana < weaponInfo.ManaCost then
            return false, "Not enough mana!"
        end
        attackerData.CurrentMana = attackerData.CurrentMana - weaponInfo.ManaCost
    end

    -- Check armor penetration
    local defense = 0
    for slot, itemId in pairs(targetData.Inventory.Equipped) do
        local armorInfo = ItemDatabase.GetItem(itemId)
        if armorInfo and armorInfo.Protects then
            for _, protectedLimb in ipairs(armorInfo.Protects) do
                if protectedLimb == hitLimb then
                    defense = defense + (armorInfo.DefenseBonus or 0)
                end
            end
        end
    end

    local mitigatedDamage = math.max(1, damage - (defense * 0.5))

    local ServerScriptService = game:GetService("ServerScriptService")
    local SpaceshipLobby = require(ServerScriptService:WaitForChild("LOBBY_SPACESHIP_1"))

    local targetPlayer = game.Players:GetPlayerByUserId(targetId)
    if targetPlayer and SpaceshipLobby.ApplyDamage then
        SpaceshipLobby.ApplyDamage(targetPlayer, hitLimb, mitigatedDamage)
        return true, "Hit " .. hitLimb .. " for " .. mitigatedDamage .. " damage"
    end

    return false, "Failed to apply damage"
end
function CombatManager.UseGearSkill(playerId, gearSlot)
    local PlayerManager = require(script.Parent.PlayerManager)
    local playerData = PlayerManager.ActivePlayers[playerId]

    if not playerData then return false, "Player not found" end

    local itemId = playerData.Inventory.Equipped[gearSlot]
    if not itemId then return false, "No gear in that slot" end

    local itemInfo = ItemDatabase.GetItem(itemId)
    if not itemInfo or not itemInfo.ActiveSkill then return false, "Gear has no active skill" end

    local skill = itemInfo.ActiveSkill

    if playerData.CurrentMana < skill.ManaCost then
        return false, "Not enough mana to cast " .. skill.Name
    end

    playerData.CurrentMana = playerData.CurrentMana - skill.ManaCost

    -- Process Skill Effects (Simulated)
    if skill.Effect == "Invulnerability" then
        playerData.Status = "Invulnerable"
        -- Schedule removal of status after Duration
        task.delay(skill.Duration, function()
            if PlayerManager.ActivePlayers[playerId] then
                PlayerManager.ActivePlayers[playerId].Status = "Alive"
            end
        end)
        return true, "Cast " .. skill.Name .. " (Invulnerable for " .. skill.Duration .. "s)"
    end

    if skill.Name == "Meteor Strike" then
        -- In a real game, this would invoke the ExplosivesManager and cast a visual AoE
        return true, "Cast " .. skill.Name .. " dealing " .. skill.Damage .. " AoE damage!"
    end

    return true, "Cast " .. skill.Name
end

function CombatManager.LoadMagazine(weaponInstance, magazineInstance)
    local weaponInfo = ItemDatabase.GetItem(weaponInstance.BaseItemId)
    local magInfo = ItemDatabase.GetItem(magazineInstance.BaseItemId)

    if not weaponInfo or not magInfo then return false, "Invalid items" end
    if weaponInfo.Caliber ~= magInfo.Caliber then return false, "Caliber mismatch" end
    if not weaponInfo.RequiresMagazine then return false, "Weapon does not use magazines" end

    weaponInstance.LoadedMagazine = magazineInstance

    -- Chamber a round immediately if weapon is cocked/empty
    if not weaponInstance.ChamberedRound and #magazineInstance.CurrentAmmo > 0 then
        weaponInstance.ChamberedRound = table.remove(magazineInstance.CurrentAmmo, 1)
        return true, "Magazine loaded and weapon cocked"
    end

    return true, "Magazine loaded"
end

function CombatManager.PackAmmo(magazineInstance, ammoItemId)
    local magInfo = ItemDatabase.GetItem(magazineInstance.BaseItemId)
    local ammoInfo = ItemDatabase.GetItem(ammoItemId)

    if not magInfo or not ammoInfo then return false, "Invalid items" end
    if magInfo.Caliber ~= ammoInfo.Caliber then return false, "Caliber mismatch" end
    if #magazineInstance.CurrentAmmo >= magInfo.Capacity then return false, "Magazine is full" end

    table.insert(magazineInstance.CurrentAmmo, ammoItemId)
    return true, "Ammo loaded into magazine"
end

-- Override ProcessAttack to strictly use ChamberedRounds
local function hookEvents()
    local events = game:GetService("ReplicatedStorage"):WaitForChild("Events")

    local fireEvent = events:WaitForChild("FireWeapon")
    fireEvent.OnServerEvent:Connect(function(player, targetPlayerId)
        -- In a fully physical game, this uses raycasts. For this prototype, we simulate target data.
        local PlayerManager = require(script.Parent.PlayerManager)
        local attackerData = PlayerManager.ActivePlayers[player.UserId]
        local targetData = PlayerManager.ActivePlayers[targetPlayerId]

        if attackerData and targetData then
            CombatManager.ProcessAttack(attackerData, targetData)
        end
    end)

    local reloadFunc = events:WaitForChild("ReloadWeapon")
    reloadFunc.OnServerInvoke = function(player, magInstanceId)
        local PlayerManager = require(script.Parent.PlayerManager)
        local playerData = PlayerManager.ActivePlayers[player.UserId]
        if not playerData then return false, "Player not found" end

        local weaponInstance = playerData.Inventory.Equipped.WeaponInstance
        if not weaponInstance then return false, "No weapon equipped" end

        -- Simplified search for mag in inventory
        -- In full game, would find magInstanceId in backpack
        local magInstance = { BaseItemId = "Mag_STANAG_30", CurrentAmmo = {} }
        return CombatManager.LoadMagazine(weaponInstance, magInstance)
    end
end

-- Override Initialize
local oldInit = CombatManager.Initialize
function CombatManager.Initialize()
    oldInit()
    task.spawn(hookEvents)
end
return CombatManager
