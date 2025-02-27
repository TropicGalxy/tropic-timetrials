local trialsFile = "savedTrials.lua"

local AllowedTimeTrialCreators = { -- you can use rockstar license, fivem license, steam id, or discord id
    ["license:a8cebabd3f4952af82bb078aa14f156cfa84b8c7"] = true,  
}

local function isPlayerAuthorized(playerId)
    for i = 0, GetNumPlayerIdentifiers(playerId) - 1 do
        local identifier = GetPlayerIdentifier(playerId, i)
        if AllowedTimeTrialCreators[identifier] then
            return true
        end
    end
    return false
end

RegisterNetEvent("tropic-timeTrial:checkAdmin")
AddEventHandler("tropic-timeTrial:checkAdmin", function()
    local src = source
    if isPlayerAuthorized(src) then
        TriggerClientEvent("tropic-timeTrial:beginCreation", src) 
    else
        TriggerClientEvent("tropic-timeTrial:showAccessDenied", src) 
    end
end)

RegisterNetEvent("tropic-timeTrial:checkSavePermission")
AddEventHandler("tropic-timeTrial:checkSavePermission", function(trialData)
    local src = source
    if isPlayerAuthorized(src) then
        saveTrial(trialData) 
        TriggerClientEvent("tropic-timeTrial:trialSaved", src)  
    else
        TriggerClientEvent("tropic-timeTrial:showAccessDenied", src) 
    end
end)

function saveTrial(trialData)
    local trialName = trialData.name:gsub("[^%w%s]", "")
    if not trialName or trialName == "" then return end

    Config.TimeTrials[trialName] = {
        start = trialData.start,
        spawn = trialData.spawn,
        vehicle = trialData.vehicle,
        checkpoints = trialData.checkpoints
    }

    saveTrials()
end


function saveTrials()
    local fileContent = "Config.TimeTrials = {\n"

    for trialName, trialData in pairs(Config.TimeTrials) do
        fileContent = fileContent .. string.format("    [\"%s\"] = {\n", trialName)
        fileContent = fileContent .. string.format("        spawn = vector4(%.4f, %.4f, %.4f, %.4f),\n", 
            trialData.spawn.x, trialData.spawn.y, trialData.spawn.z, trialData.spawn.w)
        fileContent = fileContent .. string.format("        start = vector3(%.4f, %.4f, %.4f),\n", 
            trialData.start.x, trialData.start.y, trialData.start.z)
        fileContent = fileContent .. string.format("        vehicle = \"%s\",\n", trialData.vehicle)
        fileContent = fileContent .. "        checkpoints = {\n"

        for _, checkpoint in ipairs(trialData.checkpoints) do
            fileContent = fileContent .. string.format("            vector3(%.4f, %.4f, %.4f),\n", 
                checkpoint.x, checkpoint.y, checkpoint.z)
        end

        fileContent = fileContent .. "        }\n    },\n"
    end

    fileContent = fileContent .. "}\n"

    SaveResourceFile(GetCurrentResourceName(), trialsFile, fileContent, -1)
end
