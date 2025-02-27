local creatingTrial = false
local placingStart = false
local placingSpawn = false
local placingCheckpoints = false
local newTrial = {name = "", start = nil, spawn = nil, vehicle = "", checkpoints = {}}

RegisterCommand("createtimetrial", function()
    TriggerServerEvent("tropic-timeTrial:checkAdmin")
end, false)

RegisterNetEvent("tropic-timeTrial:beginCreation")
AddEventHandler("tropic-timeTrial:beginCreation", function()
    if creatingTrial then
        lib.notify({title = "Time Trial", description = "You are already creating a trial!", type = "error"})
        return
    end

    creatingTrial = true
    newTrial = {name = "", start = nil, spawn = nil, vehicle = "", checkpoints = {}}

    local input = lib.inputDialog("Create Time Trial", {
        {type = "input", label = "Trial Name", required = true},
        {type = "input", label = "Vehicle Model", required = true}
    })

    if not input or #input < 2 then
        creatingTrial = false
        lib.notify({title = "Time Trial", description = "Cancelled trial creation.", type = "error"})
        return
    end

    newTrial.name = input[1]:gsub("[^%w%s]", "") 
    newTrial.vehicle = input[2]:gsub("[^%w%s]", "")

    lib.notify({title = "Time Trial", description = "Now go to the start location and press [E] to set it.", type = "info"})
    placingStart = true
end)

RegisterNetEvent("tropic-timeTrial:showAccessDenied")
AddEventHandler("tropic-timeTrial:showAccessDenied", function()
    lib.notify({
        title = "Access Denied", 
        description = "You do not have permission to create a time trial.", 
        type = "error"
    })
end)

CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if placingStart then
            sleep = 0
            DrawText3D(playerCoords, "[E] Set Start Position")
            if IsControlJustPressed(0, 38) then
                newTrial.start = playerCoords
                lib.notify({title = "Time Trial", description = "Start position set! Now go to the spawn location and press [E].", type = "success"})
                placingStart = false
                placingSpawn = true
            end
        elseif placingSpawn then
            sleep = 0
            DrawText3D(playerCoords, "[E] Set Spawn Position")
            if IsControlJustPressed(0, 38) then
                newTrial.spawn = vector4(playerCoords.x, playerCoords.y, playerCoords.z, GetEntityHeading(playerPed))
                lib.notify({title = "Time Trial", description = "Spawn position set! Now start adding checkpoints. Press [E] at each checkpoint.", type = "success"})
                placingSpawn = false
                placingCheckpoints = true
            end
        elseif placingCheckpoints then
            sleep = 0
            DrawText3D(playerCoords, "[E] Add Checkpoint | /savetrial to finish")
            if IsControlJustPressed(0, 38) then
                table.insert(newTrial.checkpoints, playerCoords)
                lib.notify({title = "Time Trial", description = "Checkpoint added! Total: " .. #newTrial.checkpoints, type = "success"})
            end
        end

        Wait(sleep)
    end
end)

RegisterCommand("savetrial", function()
    TriggerServerEvent("tropic-timeTrial:checkSavePermission", newTrial)
end, false)

RegisterNetEvent("tropic-timeTrial:trialSaved")
AddEventHandler("tropic-timeTrial:trialSaved", function()
    lib.notify({title = "Time Trial", description = "Trial saved successfully!", type = "success"})

    creatingTrial = false
    placingCheckpoints = false
    newTrial = {name = "", start = nil, spawn = nil, vehicle = "", checkpoints = {}}
end)

RegisterNetEvent("tropic-timeTrial:showAccessDenied")
AddEventHandler("tropic-timeTrial:showAccessDenied", function()
    lib.notify({
        title = "Access Denied", 
        description = "You do not have permission to save a trial.", 
        type = "error"
    })
end)

function DrawText3D(coords, text)
    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(0, 255, 0, 255)
        SetTextCentre(1)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(x, y)
    end
end
