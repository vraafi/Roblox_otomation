-- LendingSystem.lua
-- Manages temporary gear loans between teammates in the lobby.

local LendingSystem = {}
local ServerScriptService = game:GetService("ServerScriptService")

-- Format: { [BorrowerUserId] = { { OriginalOwnerId = ..., ItemId = "..." }, ... } }
LendingSystem.ActiveLoans = {}

function LendingSystem.Initialize()
    -- Intercept player disconnecting to return gear
    game.Players.PlayerRemoving:Connect(function(player)
        LendingSystem.ReturnBorrowedGear(player.UserId)
    end)
    print("Team Lending System Initialized.")
end

-- Call this when Player A gives Player B an item in the Lobby
function LendingSystem.LendItem(ownerPlayer, borrowerPlayer, itemId)
    local borrowerId = borrowerPlayer.UserId

    if not LendingSystem.ActiveLoans[borrowerId] then
        LendingSystem.ActiveLoans[borrowerId] = {}
    end

    table.insert(LendingSystem.ActiveLoans[borrowerId], {
        OriginalOwnerId = ownerPlayer.UserId,
        ItemId = itemId,
        OriginalCondition = 100 -- Simulated durability tracking
    })

    print(ownerPlayer.Name .. " lent " .. itemId .. " to " .. borrowerPlayer.Name)
end

-- Call this when Borrower Extracts or Disconnects
function LendingSystem.ReturnBorrowedGear(borrowerId)
    local loans = LendingSystem.ActiveLoans[borrowerId]
    if not loans or #loans == 0 then return end

    local MailSystem = require(ServerScriptService:WaitForChild("MailSystem"))
    local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))
    local borrowerData = PlayerManager.ActivePlayers[borrowerId]

    for _, loan in ipairs(loans) do
        -- Check if borrower still has it (they might have died and lost it in raid)
        local stillHasItem = false
        if borrowerData then
            for i, item in ipairs(borrowerData.Inventory.Items) do
                if item == loan.ItemId then
                    stillHasItem = true
                    table.remove(borrowerData.Inventory.Items, i)
                    break
                end
            end
        end

        if stillHasItem or not borrowerData then
            -- If borrower disconnected in lobby (not in raid), assume they still have it
            MailSystem.DeliverItem(
                loan.OriginalOwnerId,
                "System: Gear Return",
                loan.ItemId,
                "Your teammate returned your gear."
            )
            print("Returned borrowed " .. loan.ItemId .. " to Owner " .. loan.OriginalOwnerId)
        else
            print("Borrower " .. borrowerId .. " lost the borrowed " .. loan.ItemId .. " in raid.")
            -- Item is lost; do not mail it back.
        end
    end

    LendingSystem.ActiveLoans[borrowerId] = nil
end

return LendingSystem
