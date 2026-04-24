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
    local weaponId = playerData.Inventory.Equipped.Weapon

    if not weaponId then
        return false, "No weapon equipped"
    end

    local weaponInfo = ItemDatabase.GetItem(weaponId)

    if not weaponInfo then
        return false, "Invalid weapon"
    end

    -- Check if it's a magic wand
    if weaponInfo.SubType == "MagicWand" then
        -- You are what you wear: Check if player has enough mana (given by armor)
        if playerData.CurrentMana < weaponInfo.ManaCost then
            return false, "Not enough mana! Equip better armor with a higher core level."
        end

        -- Deduct mana
        playerData.CurrentMana = playerData.CurrentMana - weaponInfo.ManaCost

        -- Apply damage to target (simplified)
        targetData.CurrentHealth = targetData.CurrentHealth - weaponInfo.BaseDamage

        return true, "Cast magic successfully"
    end

    -- Modern firearms
    if weaponInfo.SubType == "ModernFirearm" then
        -- In a full game, check ammo here
        local damage = weaponInfo.Damage
        -- Mitigate by defense (you are what you wear: defense from armor)
        local mitigatedDamage = math.max(1, damage - (targetData.TotalStats.Defense * 0.5))

        targetData.CurrentHealth = targetData.CurrentHealth - mitigatedDamage

        return true, "Fired weapon successfully"
    end

    return false, "Unknown weapon type"
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
return CombatManager
