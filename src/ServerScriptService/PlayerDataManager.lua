local PlayerDataManager = {}
local players = {}
function PlayerDataManager.InitializePlayer(player)
    players[player.UserId] = { Silver = 0, Fame = 0, Health = 100, Mana = 100 }
end
function PlayerDataManager.GetPlayerData(player)
    return players[player.UserId]
end
return PlayerDataManager
