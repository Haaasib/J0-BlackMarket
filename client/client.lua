RegisterNetEvent('J0-BlackMarket:client:openBurnerPhone', function()
    FW.SendNuiMessage('openBurnerPhone', {
        data = Config.BlackMarketSettings,
        locale = L
    }, true)
end)

RegisterNuiCallback('closeUi', function()
    SetNuiFocus(false, false)
end)

RegisterNuiCallback('getTime', function(_, cb)
    cb(FW.GetGtaTime())
end)