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

    for _, npcData in ipairs(MarketNPCs) do
        local npc = Instance.new("Model")
        npc.Name = npcData.Name

        local rootPart = Instance.new("Part")
        rootPart.Size = Vector3.new(4, 5, 4)
        rootPart.Position = npcData.Position
        rootPart.Anchored = true
        rootPart.Color = Color3.fromRGB(200, 150, 100)
        rootPart.Parent = npc

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Trade"
        prompt.ObjectText = npcData.Name .. " (" .. npcData.Role .. ")"
        prompt.Parent = rootPart

        prompt.Triggered:Connect(function(player)
            SpaceshipMarket.OpenShopGUI(player, npcData.Role)
        end)

        npc.PrimaryPart = rootPart
        npc.Parent = workspace
    end

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
    local pData = _G.PlayerEconomies and _G.PlayerEconomies[player.UserId]
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
    local pData = _G.PlayerEconomies and _G.PlayerEconomies[player.UserId]
    if not pData then return false, "Economy data missing" end

    if pData.TotalDollars >= itemData.Value then
        -- Deduct money
        pData.TotalDollars = pData.TotalDollars - itemData.Value

        -- In a real scenario, this would add the item to their InventorySystem
        -- For the simulation, we notify the client to update their UI
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events and events:FindFirstChild("ItemPickedUp") then
            events.ItemPickedUp:FireClient(player, {
                Name = itemData.Name,
                GridWidth = itemData.GridWidth,
                GridHeight = itemData.GridHeight,
                Color = itemData.Color
            })
        end

        print(player.Name .. " purchased " .. itemData.Name .. " for $" .. itemData.Value)
        return true, "Purchase successful!"
    else
        return false, "Not enough Dollars. Need $" .. itemData.Value
    end
end

function SpaceshipMarket.OpenShopGUI(player, role)
    print("Opening Shop GUI for " .. player.Name .. " viewing " .. role)
    -- In a full game, fire a RemoteEvent to display the Shop UI to the player
end

return SpaceshipMarket
