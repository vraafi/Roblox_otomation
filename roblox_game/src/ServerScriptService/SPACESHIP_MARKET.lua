-- SPACESHIP_MARKET.lua
-- The central economy hub for the "Last Home of Humanity"
-- Allows players to spend extracted Dollars on gear before diving back into the portal.

local SpaceshipMarket = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local ServerScriptService = game:GetService("ServerScriptService")
local DailyLogSystem = require(ServerScriptService:WaitForChild("DAILY_LOG_SYSTEM_1"))
local InventorySystem = require(ReplicatedStorage:WaitForChild("InventorySystem"))

local MarketNPCs = {
    { Name = "Quartermaster_Riggs", Role = "Weapons & Armor", Position = Vector3.new(-50, 1002, 20) },
    { Name = "Apothecary_Vael", Role = "Magic & Consumables", Position = Vector3.new(-50, 1002, -20) }
}

function SpaceshipMarket.Initialize()
    print("Spaceship Market initializing...")
    -- NOTE: Physical NPC models are built entirely by LOBBY_SPACESHIP_1.lua (all 8 NPCs).
    -- This module only wires up server-side economy logic (buy/sell RemoteFunctions).

    -- Setup the NPC Sell Price Floor logic
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        local npcSellEvent = events:FindFirstChild("NPCSellRequest")
        if not npcSellEvent then
            npcSellEvent = Instance.new("RemoteFunction")
            npcSellEvent.Name = "NPCSellRequest"
            npcSellEvent.Parent = events
        end
        npcSellEvent.OnServerInvoke = SpaceshipMarket.HandleNPCSell
    end
end

-- Economic Price Floor: Players can instantly sell to NPCs for 40% of base value.
-- This ensures Flea Market prices never collapse below this hard floor.
function SpaceshipMarket.HandleNPCSell(player, itemId)
    local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
    local pData = PlayerManager.ActivePlayers[player.UserId]
    if not pData then return false, "Economy data missing" end

    local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))
    local playerData = PlayerManager.ActivePlayers[player.UserId]
    if not playerData then return false, "Player data missing" end

    local itemData = ItemDatabase.GetItem(itemId)
    if not itemData then return false, "Invalid item" end

    -- Verify ownership
    local hasItem = false
    for i, storedItemId in ipairs(playerData.Inventory.Items) do
        if storedItemId == itemId then
            hasItem = true
            table.remove(playerData.Inventory.Items, i)
            break
        end
    end

    if not hasItem then return false, "You do not own this item." end

    local floorPrice = math.floor(itemData.Value * 0.40)
    pData.TotalDollars = pData.TotalDollars + floorPrice

    print(player.Name .. " sold " .. itemData.Name .. " to NPC for $" .. floorPrice)
    return true, "Sold to NPC for $" .. floorPrice
end

-- Simulates server verification of a purchase
function SpaceshipMarket.AttemptPurchase(player, itemId)
    local itemData = ItemDatabase.GetItem(itemId)
    if not itemData then return false, "Item not found" end
    if not itemData.Value then return false, "Item is not for sale" end

    -- Check player's wallet
    local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
    local pData = PlayerManager.ActivePlayers[player.UserId]
    if not pData then return false, "Economy data missing" end

    if pData.TotalDollars >= itemData.Value then
        -- Deduct money
        pData.TotalDollars = pData.TotalDollars - itemData.Value

        -- Arena Breakout Mechanics: Purchased items go to Mail Inbox
        local MailSystem = require(ServerScriptService:WaitForChild("MailSystem"))
        MailSystem.DeliverItem(player.UserId, "Quartermaster Riggs", itemData.Id, "Thank you for your purchase.")

        print(player.Name .. " purchased " .. itemData.Name .. " for $" .. itemData.Value)
        return true, "Purchase sent to Inbox!"
    else
        return false, "Not enough Dollars. Need $" .. itemData.Value
    end
end

function SpaceshipMarket.OpenShopGUI(player, role)
    print("Opening Shop GUI for " .. player.Name .. " viewing " .. role)
    -- In a full game, fire a RemoteEvent to display the Shop UI to the player
end

return SpaceshipMarket
