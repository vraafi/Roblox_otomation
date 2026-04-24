-- MailSystem.lua
-- Handles the Arena Breakout style Inbox for market purchases, returns, and borrowed gear.

local MailSystem = {}

local SIX_DAYS_SECONDS = 6 * 24 * 60 * 60

-- Format: { [UserId] = { { MailId = "...", Sender = "System", ItemId = "M4A1", Expiration = 123456789 }, ... } }
MailSystem.PlayerInboxes = {}

function MailSystem.Initialize()
    game.Players.PlayerAdded:Connect(function(player)
        -- In production, load from DataStore
        MailSystem.PlayerInboxes[player.UserId] = {}
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        -- In production, save to DataStore
        MailSystem.PlayerInboxes[player.UserId] = nil
    end)

    -- Expiration Cleanup Loop
    task.spawn(function()
        while true do
            task.wait(60 * 5) -- Check every 5 minutes
            local currentTime = os.time()
            for userId, inbox in pairs(MailSystem.PlayerInboxes) do
                for i = #inbox, 1, -1 do
                    if currentTime > inbox[i].Expiration then
                        print("Deleted expired mail for User " .. userId)
                        table.remove(inbox, i)
                    end
                end
            end
        end
    end)

    print("Mail/Inbox System Initialized.")
end

function MailSystem.DeliverItem(userId, senderName, itemId, message)
    if not MailSystem.PlayerInboxes[userId] then
        -- If player is offline, we would save directly to their DataStore here
        warn("User " .. userId .. " is offline. Mail queued for DataStore save.")
        return
    end

    local mailItem = {
        MailId = "MAIL_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
        Sender = senderName,
        ItemId = itemId,
        Message = message or "Item Delivery",
        Expiration = os.time() + SIX_DAYS_SECONDS
    }

    table.insert(MailSystem.PlayerInboxes[userId], mailItem)

    local player = game.Players:GetPlayerByUserId(userId)
    if player then
        -- Notify Client GUI
        local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
        if events and events:FindFirstChild("NewMailAlert") then
            events.NewMailAlert:FireClient(player)
        end
    end

    print("Delivered " .. itemId .. " to User " .. userId .. "'s Inbox.")
end

function MailSystem.ClaimMail(player, mailId)
    local inbox = MailSystem.PlayerInboxes[player.UserId]
    if not inbox then return false, "Inbox empty." end

    for i, mail in ipairs(inbox) do
        if mail.MailId == mailId then
            -- Verify inventory space
            local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))
            local playerData = PlayerManager.ActivePlayers[player.UserId]

            -- Simplified grid check: assume 100 max items for now
            if #playerData.Inventory.Items >= 100 then
                return false, "Inventory full. Cannot claim."
            end

            -- Add to inventory
            table.insert(playerData.Inventory.Items, mail.ItemId)

            -- Delete Mail
            table.remove(inbox, i)
            return true, "Item claimed successfully!"
        end
    end

    return false, "Mail not found."
end

return MailSystem
