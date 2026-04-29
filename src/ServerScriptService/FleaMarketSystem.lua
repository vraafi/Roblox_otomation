-- FleaMarketSystem.lua
-- Backend logic for the Player-to-Player (P2P) Arena Breakout style market.

local FleaMarketSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- Active listings in the global market
-- Format: { ListingId = { SellerId, ItemId, Price, ExpirationTime } }
FleaMarketSystem.ActiveListings = {}

-- Fee percentages based on listing duration (Arena Breakout style)
local FEE_12_HOUR = 0.05 -- 5% listing fee
local FEE_24_HOUR = 0.12 -- 12% listing fee

function FleaMarketSystem.Initialize()
    -- Ensure RemoteEvents exist for client communication
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then
        events = Instance.new("Folder")
        events.Name = "Events"
        events.Parent = ReplicatedStorage
    end

    local marketRequest = events:FindFirstChild("MarketRequest")
    if not marketRequest then
        marketRequest = Instance.new("RemoteFunction")
        marketRequest.Name = "MarketRequest"
        marketRequest.Parent = events
    end

    marketRequest.OnServerInvoke = FleaMarketSystem.HandleClientRequest

    -- Cleanup loop for expired listings
    task.spawn(function()
        while true do
            task.wait(60)
            local currentTime = os.time()
            for id, listing in pairs(FleaMarketSystem.ActiveListings) do
                if currentTime > listing.ExpirationTime then
                    -- Expired: Mail the item back to the seller.
                    local MailSystem = require(game:GetService("ServerScriptService"):WaitForChild("MailSystem"))
                    MailSystem.DeliverItem(listing.SellerId, "Flea Market Return", listing.ItemId, "Your listing expired.")
                    FleaMarketSystem.ActiveListings[id] = nil
                end
            end
        end
    end)

    print("Player-to-Player Flea Market Initialized.")
end

-- Generates a grouped/categorized list of active items for the client GUI
function FleaMarketSystem.GetMarketData(categoryFilter, searchQuery)
    local results = {}

    for id, listing in pairs(FleaMarketSystem.ActiveListings) do
        local itemData = ItemDatabase.GetItem(listing.ItemId)
        if itemData then
            local matchCategory = (categoryFilter == "All" or itemData.Type == categoryFilter)
            local matchSearch = true

            if searchQuery and searchQuery ~= "" then
                matchSearch = string.find(string.lower(itemData.Name), string.lower(searchQuery)) ~= nil
            end

            if matchCategory and matchSearch then
                table.insert(results, {
                    ListingId = id,
                    ItemId = itemData.Id,
                    Name = itemData.Name,
                    Price = listing.Price,
                    SellerId = listing.SellerId
                })
            end
        end
    end

    return results
end

function FleaMarketSystem.CreateListing(player, itemId, price, durationHours)
    -- SECURITY PATCH: Prevent negative price exploits
    if type(price) ~= "number" or price <= 0 then
        return false, "Invalid price."
    end

    local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
    local pData = PlayerManager.ActivePlayers[player.UserId]
    if not pData then return false, "Economy data missing" end

    local itemData = ItemDatabase.GetItem(itemId)
    if not itemData then return false, "Invalid item" end

    -- Calculate Listing Fee
    local feePercent = (durationHours == 24) and FEE_24_HOUR or FEE_12_HOUR
    local feeCost = math.ceil(price * feePercent)

    if pData.TotalDollars < feeCost then
        return false, "Not enough money to pay the listing fee of $" .. feeCost
    end

    -- Verify the player actually has this item in their inventory
    local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
    local playerData = PlayerManager.ActivePlayers[player.UserId]
    if not playerData then return false, "Player data missing" end

    local hasItem = false
    for i, storedItemId in ipairs(playerData.Inventory.Items) do
        if storedItemId == itemId then
            hasItem = true
            table.remove(playerData.Inventory.Items, i) -- Physically remove from inventory
            break
        end
    end

    if not hasItem then
        return false, "You do not own this item."
    end

    -- Deduct Fee
    pData.TotalDollars = pData.TotalDollars - feeCost

    -- Add to market
    local listingId = "LST_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    FleaMarketSystem.ActiveListings[listingId] = {
        SellerId = player.UserId,
        ItemId = itemId,
        Price = price,
        ExpirationTime = os.time() + (durationHours * 3600)
    }

    print(player.Name .. " listed " .. itemData.Name .. " for $" .. price .. " (Fee: $" .. feeCost .. ")")
    return true, "Listed successfully!"
end

function FleaMarketSystem.PurchaseListing(player, listingId)
    local listing = FleaMarketSystem.ActiveListings[listingId]
    if not listing then return false, "Listing no longer available" end

    if listing.SellerId == player.UserId then
        return false, "You cannot buy your own listing."
    end

    local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
    local pData = PlayerManager.ActivePlayers[player.UserId]
    if not pData then return false, "Economy data missing" end

    if pData.TotalDollars < listing.Price then
        return false, "Not enough money."
    end

    -- Verify buyer has room in inventory
    local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
    local buyerData = PlayerManager.ActivePlayers[player.UserId]
    if not buyerData then return false, "Player data missing" end

    -- Simplified grid check: assume 100 max items for now
    if #buyerData.Inventory.Items >= 100 then
        return false, "Inventory full."
    end

    -- Deduct buyer money
    pData.TotalDollars = pData.TotalDollars - listing.Price

    -- Give seller money (In a full game, this would be sent via an Inbox/Mail system)
    local sellerData = PlayerManager.ActivePlayers[listing.SellerId]
    if sellerData then
        sellerData.TotalDollars = sellerData.TotalDollars + listing.Price
    end

    -- Mail buyer the item (Arena Breakout mechanics)
    local MailSystem = require(game:GetService("ServerScriptService"):WaitForChild("MailSystem"))
    MailSystem.DeliverItem(player.UserId, "Flea Market Purchase", listing.ItemId, "You purchased an item.")

    -- Remove listing
    FleaMarketSystem.ActiveListings[listingId] = nil

    return true, "Purchase successful!"
end

-- Central router for client requests
function FleaMarketSystem.HandleClientRequest(player, action, ...)
    local args = {...}

    if action == "GetMarket" then
        local category = args[1] or "All"
        local search = args[2] or ""
        return true, FleaMarketSystem.GetMarketData(category, search)

    elseif action == "CreateListing" then
        local itemId = args[1]
        local price = args[2]
        local duration = args[3] -- 12 or 24
        return FleaMarketSystem.CreateListing(player, itemId, price, duration)

    elseif action == "PurchaseListing" then
        local listingId = args[1]
        return FleaMarketSystem.PurchaseListing(player, listingId)
    end

    return false, "Unknown Action"
end

return FleaMarketSystem
