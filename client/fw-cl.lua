local C, s = Config.FrameworkSettings.CoreName, function(r) return GetResourceState(r) == 'started' end
local isESX, isQB, Core = C == "es_extended", C:find("qb"), (C == "es_extended" and exports[C]:getSharedObject() or exports[C]:GetCoreObject())
local hasOxTarget, hasQbTarget, hasInteract =  Config.FrameworkSettings.TargetSettings.resource == 'ox_target', Config.FrameworkSettings.TargetSettings.resource == 'qb-target', Config.FrameworkSettings.TargetSettings.resource == 'interact'
local Cache = {
    zones = {},
    peds = {},
    blips = {},
    targetZones = {},
}
FW = {}
FW.SendNuiMessage = function(action, data, bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = action,
        data = data
    })
end

FW.GetStreetName = function(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)
    
    if streetName and streetName ~= "" then
        if crossingName and crossingName ~= "" and crossingName ~= streetName then
            return streetName .. " / " .. crossingName
        end
        return streetName
    end
    return "Unknown Street"
end

FW.CreateBlip = function(coords, id, name, color, scale, shortRange)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, id)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    if shortRange then
        SetBlipAsShortRange(blip, true)
    end
    Cache.blips[id] = blip
    return blip
end

FW.RemoveBlip = function(blip)
    RemoveBlip(blip)
    Cache.blips[blip] = nil
end

FW.SendNotify = function(type, message)
   if isQB then
    Core.Functions.Notify(message, type, 5000)
   elseif isESX then
    Core.ShowNotification(message, type, 3000, "title here", "top-left")
   end
end

FW.CreatePed = function(model, coords, heading)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z-1.0, heading, false, false)
    SetModelAsNoLongerNeeded(model)
    SetPedFleeAttributes(ped, 0, false)
    SetPedKeepTask(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedCanBeTargetted(ped, false)
    SetPedCanBeShotInVehicle(ped, false)
    SetEntityInvincible(ped, true)
    Cache.peds[ped] = ped
    return ped
end

FW.DeletePed = function(ped)
    if DoesEntityExist(ped) then
        DeletePed(ped)
    end
    Cache.peds[ped] = nil
end

FW.GetGtaTime = function()
    local hour = GetClockHours()
    local minute = GetClockMinutes()

    local suffix = hour >= 12 and "PM" or "AM"
    local displayHour = hour % 12
    displayHour = displayHour == 0 and 12 or displayHour

    return {
        hour = displayHour,
        minute = minute,
        suffix = suffix,
        hour24 = hour,
        formatted = ("%02d:%02d %s"):format(displayHour, minute, suffix)
    }
end


FW.FixOptions = function(options)
    local fixedOptions = {}
    for k, v in pairs(options) do
        local action = v.onSelect or v.action
        local wrappedAction = action and function(data)
            local ent = type(data) == 'table' and data.entity or data
            local coords = type(data) == 'table' and data.coords or GetEntityCoords(ent)
            local args = v.args or {}
            local serverId = type(data) == 'table' and data.serverId or nil
            return action(ent, coords, args, serverId)
        end

        local option = {
            label = v.label,
            icon = v.icon,
            groups = v.groups or v.job,
            canInteract = v.canInteract,
            args = v.args
        }

        if hasOxTarget then
            option.onSelect = wrappedAction
            option.name = v.name or v.label
            option.serverEvent = v.serverEvent
            option.event = v.event
        elseif hasQbTarget then
            option.action = wrappedAction
            option.job = v.groups or v.job
            option.type = v.serverEvent and "server" or "client"
            option.event = v.serverEvent or v.event
        elseif hasInteract then
            option.action = wrappedAction
            option.name = v.name or v.label
        end
        fixedOptions[k] = option
    end
    return fixedOptions
end

local getDist = function(options)
    local d = 2.5
    for _, v in pairs(options) do
        if v.distance and v.distance > d then d = v.distance end
    end
    return d
end

FW.AddBoxZone = function(name, coords, size, heading, options)
    options = FW.FixOptions(options)
    local id = name
    if hasOxTarget then
        id = exports.ox_target:addBoxZone({
            coords = coords, size = size, rotation = heading,
            debug = Config.FrameworkSettings.TargetSettings.debug, options = options
        })
    elseif hasQbTarget then
        exports['qb-target']:AddBoxZone(name, coords, size.x, size.y, {
            name = name, heading = heading, debugPoly = Config.FrameworkSettings.TargetSettings.debug,
            minZ = coords.z - (size.z/2), maxZ = coords.z + (size.z/2)
        }, { options = options, distance = getDist(options) })
    elseif hasInteract then
        exports.interact:AddInteraction({
            id = name, coords = coords, options = options,
            distance = 8.0, interactDst = size.x
        })
    end
    table.insert(Cache.targetZones, { id = id, type = 'zone', creator = GetInvokingResource() })
    return id
end

FW.AddTargetModel = function(models, options)
    options = FW.FixOptions(options)
    local id = "model_" .. tostring(#Cache.targetZones)
    if hasOxTarget then
        exports.ox_target:addModel(models, options)
    elseif hasQbTarget then
        exports['qb-target']:AddTargetModel(models, { options = options, distance = getDist(options) })
    elseif hasInteract then
        exports.interact:AddModelInteraction({ model = models, id = id, options = options })
    end
    table.insert(Cache.targetZones, { id = id, type = 'model', target = models, creator = GetInvokingResource() })
end

FW.AddGlobalVehicle = function(options)
    options = FW.FixOptions(options)
    local id = "glob_veh_" .. tostring(#Cache.targetZones)
    if hasOxTarget then
        exports.ox_target:addGlobalVehicle(options)
    elseif hasQbTarget then
        exports['qb-target']:AddGlobalVehicle({ options = options, distance = getDist(options) })
    elseif hasInteract then
        exports.interact:AddGlobalVehicleInteraction({ id = id, options = options })
    end
    table.insert(Cache.targetZones, { id = id, type = 'vehicle', creator = GetInvokingResource() })
end

FW.AddGlobalPlayer = function(options)
    options = FW.FixOptions(options)
    local id = "glob_ply_" .. tostring(#Cache.targetZones)
    if hasOxTarget then
        exports.ox_target:addGlobalPlayer(options)
    elseif hasQbTarget then
        exports['qb-target']:AddGlobalPlayer({ options = options, distance = getDist(options) })
    elseif hasInteract then
        exports.interact:addGlobalPlayerInteraction({ id = id, options = options })
    end
    table.insert(Cache.targetZones, { id = id, type = 'player', creator = GetInvokingResource() })
end

FW.RemoveTarget = function(id, type)
    if hasOxTarget then
        if type == 'zone' then exports.ox_target:removeZone(id) end
    elseif hasQbTarget then
        if type == 'zone' then exports['qb-target']:RemoveZone(id)
        elseif type == 'model' then exports['qb-target']:RemoveTargetModel(id) end
    elseif hasInteract then
        if type == 'zone' then exports.interact:RemoveInteraction(id)
        elseif type == 'model' then exports.interact:RemoveModelInteraction(nil, id)
        elseif type == 'vehicle' then exports.interact:RemoveGlobalVehicleInteraction(id)
        elseif type == 'player' then exports.interact:RemoveGlobalPlayerInteraction(id) end
    end
end

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    for k, v in pairs(Cache.zones) do
        if v and v.destroy then v:destroy() end
    end
    for k, v in pairs(Cache.peds) do
        if v then FW.DeletePed(v) end
    end
    for k, v in pairs(Cache.blips) do
        if v then FW.RemoveBlip(v) end
    end
    Cache.zones = {}
    Cache.peds = {}
    Cache.blips = {}
    for _, v in pairs(Cache.targetZones) do
        FW.RemoveTarget(v.id, v.type)
    end
end)

return FW

