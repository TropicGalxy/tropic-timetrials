local activeTrial = nil
local currentCheckpoint = 1
local startTime = nil
local running = false
local blips = {}
local checkpoints = {}

CreateThread(function()
    while true do
        if running and startTime then
            local elapsedTime = GetGameTimer() - startTime
            SendNUIMessage({ action = "update", time = elapsedTime })
        end
        Wait(10)
    end
end)

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())

        for trialName, trialData in pairs(Config.TimeTrials) do
            if trialData and trialData.start then
                local dist = #(playerCoords - trialData.start)

                if dist < 15.0 then
                    DrawText3D(trialData.start, Config.TimeTrialText.text, Config.TimeTrialText.color)

                    DrawMarker(
                        Config.TimeTrialMarker.type,
                        trialData.start.x, trialData.start.y, trialData.start.z - 1.0,
                        0, 0, 0, 0, 0, 0,
                        Config.TimeTrialMarker.scale.x, Config.TimeTrialMarker.scale.y, Config.TimeTrialMarker.scale.z,
                        Config.TimeTrialMarker.color.r, Config.TimeTrialMarker.color.g, Config.TimeTrialMarker.color.b, Config.TimeTrialMarker.color.a,
                        false, true, 2, false, nil, nil, false
                    )

                    if dist < 2.0 and IsControlJustPressed(0, 38) then
                        openTimeTrialMenu(trialName)
                    end
                end
            end
        end
        Wait(0)
    end
end)

function openTimeTrialMenu(trialName)
    lib.registerContext({
        id = "timeTrialMenu",
        title = "Time Trial - " .. trialName,
        options = {
            {title = "Start Trial", event = "tropic-timeTrial:start", icon = "fa-solid fa-car", args = trialName},
            {title = "View Leaderboard", event = "showLeaderboard", icon = "fa-solid fa-trophy", args = trialName}
        }
    })
    lib.showContext("timeTrialMenu")
end

function spawnTrialVehicle(vehicleModel, spawnCoords)
    if DoesEntityExist(spawnedVehicle) then
        DeleteEntity(spawnedVehicle)
    end

    local model = GetHashKey(vehicleModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    spawnedVehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    TaskWarpPedIntoVehicle(PlayerPedId(), spawnedVehicle, -1)

    if Config.UseQB then
        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(veh))
    end
end


RegisterNetEvent("tropic-timeTrial:start", function(trialName)
    local trialData = Config.TimeTrials[trialName]
    if not trialData then return end

    activeTrial = trialName
    currentCheckpoint = 1

    spawnTrialVehicle(trialData.vehicle, trialData.spawn)

    setupCheckpoints(trialData)

    startTime = GetGameTimer()
    running = true
    SendNUIMessage({ action = "start" })
    lib.notify({title = "Time Trial", description = "Race started! Reach all checkpoints.", type = "info"})
    TriggerServerEvent("tropic-timeTrial:start", trialName)
end)

function createCheckpoint(index, coords, nextCoords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 1.0)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Checkpoint " .. index)
    EndTextCommandSetBlipName(blip)
    table.insert(blips, blip)

    if not nextCoords then
        nextCoords = coords
    end

    local checkpoint = CreateCheckpoint(46, coords.x, coords.y, coords.z, nextCoords.x, nextCoords.y, nextCoords.z, 5.0, 255, 255, 0, 150, index)
    SetCheckpointCylinderHeight(checkpoint, 6.0, 6.0, 6.0)

    checkpoints[index] = checkpoint
end

function setupCheckpoints(trialData)
    clearCheckpoints()
    for i, coords in ipairs(trialData.checkpoints) do
        local nextCoords = trialData.checkpoints[i + 1] or nil
        createCheckpoint(i, coords, nextCoords)
    end
end

function clearCheckpoints()
    for _, blip in ipairs(blips) do
        RemoveBlip(blip)
    end
    for _, checkpoint in pairs(checkpoints) do
        DeleteCheckpoint(checkpoint)
    end
    blips = {}
    checkpoints = {}
end

function finishTrial()
    if not startTime then return end

    local elapsedTime = (GetGameTimer() - startTime) / 1000
    local trialData = Config.TimeTrials[activeTrial]
    startTime = nil
    running = false
    SendNUIMessage({ action = "stop" })

    lib.notify({
        title = "Time Trial",
        description = "Finished! Time: " .. elapsedTime .. "s\nYou have been teleported back to the start.",
        type = "success"
    })

    TriggerServerEvent("tropic-timeTrial:finish", activeTrial, elapsedTime)

    Wait(3000)

    if DoesEntityExist(spawnedVehicle) then
        DeleteEntity(spawnedVehicle)
    end

    SetEntityCoords(PlayerPedId(), trialData.start.x, trialData.start.y, trialData.start.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), trialData.start.w)

    activeTrial = nil
    clearCheckpoints()
end

function stopTimeTrial()
    if not activeTrial then return end

    local trialData = Config.TimeTrials[activeTrial]
    startTime = nil
    running = false
    SendNUIMessage({ action = "stop" })

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle and DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end

    SetEntityCoords(PlayerPedId(), trialData.start.x, trialData.start.y, trialData.start.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), trialData.start.w)

    lib.notify({
        title = "Time Trial",
        description = "Trial stopped. You have been teleported back to the start.",
        type = "error"
    })

    activeTrial = nil
    clearCheckpoints()
end

RegisterCommand("stoptimetrial", function()
    stopTimeTrial()
end, false)

CreateThread(function()
    while true do
        if activeTrial then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local trialData = Config.TimeTrials[activeTrial]

            if currentCheckpoint <= #trialData.checkpoints then
                local checkpoint = trialData.checkpoints[currentCheckpoint]
                local dist = #(playerCoords - checkpoint)

                if dist < 5.0 then
                    lib.notify({title = "Time Trial", description = "Checkpoint reached!", type = "info"})
                    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", true)

                    RemoveBlip(blips[currentCheckpoint])
                    DeleteCheckpoint(checkpoints[currentCheckpoint])
                    currentCheckpoint = currentCheckpoint + 1

                    if currentCheckpoint > #trialData.checkpoints then
                        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
                        finishTrial()
                    end
                end
            end
        end
        Wait(100)
    end
end)

RegisterNetEvent("showLeaderboard", function(trialName)
    TriggerServerEvent("tropic-timeTrial:getLeaderboard", trialName)
end)

RegisterNetEvent("tropic-timeTrial:receiveLeaderboard", function(trialName, leaderboard)
    if not leaderboard or #leaderboard == 0 then
        lib.notify({title = "Leaderboard", description = "No times recorded yet for " .. trialName, type = "error"})
        return
    end

    local options = {}

    for i, entry in ipairs(leaderboard) do
        table.insert(options, {
            title = i .. ". " .. entry.player_name, 
            description = "Time: " .. entry.time .. "s"
        })
    end

    lib.registerContext({
        id = "leaderboard_menu",
        title = "Leaderboard - " .. trialName,
        options = options
    })

    lib.showContext("leaderboard_menu")
end)

function DrawText3D(coords, text, color)
    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(Config.TimeTrialText.scale, Config.TimeTrialText.scale)
        SetTextFont(Config.TimeTrialText.font)
        SetTextProportional(1)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextCentre(1)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(x, y)
    end
end
