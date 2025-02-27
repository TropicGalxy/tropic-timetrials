local activeTrials = {}
local spawnedVehicles = {}

local function getPlayerIdentifier(playerId)
    for i = 0, GetNumPlayerIdentifiers(playerId) - 1 do
        local identifier = GetPlayerIdentifier(playerId, i)
        if identifier and string.find(identifier, "license:") then
            return identifier
        end
    end
    return nil
end

local function saveTime(playerId, trialName, time)
    local playerName = GetPlayerName(playerId)
    local playerIdentifier = getPlayerIdentifier(playerId) 
    if not playerIdentifier then return end

    local result = MySQL.query.await(
        "SELECT time FROM time_trials WHERE player_identifier = ? AND trial_name = ?",
        {playerIdentifier, trialName}
    )

    local bestTime = result[1] and result[1].time or nil

    if not bestTime or time < bestTime then
        MySQL.query.await(
            "INSERT INTO time_trials (player_identifier, player_name, trial_name, time) VALUES (?, ?, ?, ?) "
            .. "ON DUPLICATE KEY UPDATE player_name = VALUES(player_name), time = VALUES(time)",
            {playerIdentifier, playerName, trialName, time}
        )
    end
end

local function getLeaderboard(trialName)
    local result = MySQL.query.await(
        "SELECT player_name, time FROM time_trials WHERE trial_name = ? ORDER BY time ASC LIMIT 10",
        {trialName}
    )
    return result or {}
end

RegisterNetEvent("tropic-timeTrial:start", function(trialName)
    local src = source
    activeTrials[src] = { trial = trialName, startTime = GetGameTimer() }
end)

RegisterNetEvent("tropic-timeTrial:finish", function(trialName, clientTime)
    local src = source
    if not activeTrials[src] or activeTrials[src].trial ~= trialName then return end

    local elapsedTime = (GetGameTimer() - activeTrials[src].startTime) / 1000
    activeTrials[src] = nil

    saveTime(src, trialName, elapsedTime)
    TriggerClientEvent("tropic-timeTrial:receiveLeaderboard", src, trialName, getLeaderboard(trialName))
end)

RegisterNetEvent("tropic-timeTrial:getLeaderboard", function(trialName)
    local src = source
    local result = getLeaderboard(trialName)
    TriggerClientEvent("tropic-timeTrial:receiveLeaderboard", src, trialName, result)
end)
