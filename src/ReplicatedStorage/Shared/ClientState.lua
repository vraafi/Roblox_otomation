-- ClientState.lua
local ClientState = {
    TacticalStates = {
        IsCrouching = false,
        IsProning = false,
        PeekState = "None",
        IsADS = false
    },
    MenuOpen = false,
    UpdateTacticalHUD = nil
}
return ClientState
