
local spawnedPeds, netIdTable = {}, {}
local startedLicenseTrialPerPlayer = {}

SCRIPTSTORM_DMV = {
    PlacePeds = function() 
        for i = 1, #Config.DMV do
            local dmv = Config.DMV[i]
            local ped = dmv.Ped
            local model = ped.Model
            local coords = ped.Pos
            spawnedPeds[i] = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, true, true)
            netIdTable[i] = NetworkGetNetworkIdFromEntity(spawnedPeds[i])
            while not DoesEntityExist(spawnedPeds[i]) do Wait(50) end
            Wait(100)
            TriggerClientEvent('scst_dmv:pedHandler', -1, netIdTable)
        end
    end,
    DeletePeds = function() 
        for i = 1, #spawnedPeds do
            DeleteEntity(spawnedPeds[i])
            spawnedPeds[i] = nil
        end
    end,
    PlaceDMVS = function() 
        for i = 1, #Config.DMV do
            local dmv = Config.DMV[i]
            local ped = dmv.Ped

            this.PlacePeds(i, ped)
        end
    end,
    Pay = function() 

    end
}

ESX.RegisterServerCallback('scst_dmv:canYouPay', function(source, cb, type)
    local playerId = source
	local xPlayer = ESX.GetPlayerFromId(source)

    if startedLicenseTrialPerPlayer[playerId] ~= nil and startedLicenseTrialPerPlayer[playerId][type] ~= nil then 
        if startedLicenseTrialPerPlayer[playerId][type].Payed == true then 
            if startedLicenseTrialPerPlayer[playerId][type].Exam.Tries < Config.MaxRetries.Exam and
            startedLicenseTrialPerPlayer[playerId][type].Practical.Tries < Config.MaxRetries.Practical then 
                cb(true)
                return
            end
        end
    end

    local currentLicense = nil
    for k,v in pairs(Config.Licenses) do
        if k:lower() == type:lower() then
            currentLicense = Config.Licenses[k]
        end
    end 

	if currentLicense and xPlayer.getMoney() >= currentLicense.Price then
		xPlayer.removeMoney(currentLicense.Price, "DMV Purchase")
		TriggerClientEvent('esx:showNotification', source, TranslateCap('you_paid', currentLicense.Price))
        if startedLicenseTrialPerPlayer[playerId] == nil then 
            startedLicenseTrialPerPlayer[playerId] = {}
        end
        startedLicenseTrialPerPlayer[playerId][type] = {
            Payed = true,
            Exam = {
                Passed = false,
                Tries = 0
            },
            Practical = {
                Passed = false,
                Tries = 0
            }
        }
		cb(true)
	else
        TriggerClientEvent('esx:showNotification', source, TranslateCap('not_enough_money'))
		cb(false)
	end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    SCRIPTSTORM_DMV.PlacePeds()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    SCRIPTSTORM_DMV.DeletePeds()
end)

-- register callbacks
ESX.RegisterServerCallback("scst_dmv:getPlayerData", function(source, cb)
    local startedTrials = {}

    if startedLicenseTrialPerPlayer ~= nil and startedLicenseTrialPerPlayer[source] ~= nil then
        startedTrials = startedLicenseTrialPerPlayer[source]
    end
    TriggerEvent('esx_license:getLicenses', source, function(licenses)
        local playerData = {
            Licenses = licenses,
            StartedTrials = startedTrials
        }
        cb(playerData)
    end)
end)

RegisterNetEvent('scst_dmv:failExam')
AddEventHandler('scst_dmv:failExam', function(vehicleType)
    local playerId = source
    print('in failExam')
    if startedLicenseTrialPerPlayer ~= nil then
        if startedLicenseTrialPerPlayer[playerId] == nil then 
            startedLicenseTrialPerPlayer[playerId] = {}
        end


        if startedLicenseTrialPerPlayer[playerId][vehicleType] ~= nil then
            print('setting failExam not nil')
            startedLicenseTrialPerPlayer[playerId][vehicleType].Exam.Passed = false
            startedLicenseTrialPerPlayer[playerId][vehicleType].Exam.Tries = startedLicenseTrialPerPlayer[playerId][vehicleType].Exam.Tries + 1
        else 
            print('setting failExam')
            startedLicenseTrialPerPlayer[playerId][vehicleType] = {
                Payed = true,
                Exam = {
                    Passed = false,
                    Tries = 1
                },
                Practical = {
                    Passed = false,
                    Tries = 0
                }
            }
        end
    end
end)

RegisterNetEvent('scst_dmv:passExam')
AddEventHandler('scst_dmv:passExam', function(vehicleType)
    local playerId = source
    if startedLicenseTrialPerPlayer ~= nil then
        if startedLicenseTrialPerPlayer[playerId] == nil then 
            startedLicenseTrialPerPlayer[playerId] = {}
        end


        if startedLicenseTrialPerPlayer[playerId][vehicleType] ~= nil then
            startedLicenseTrialPerPlayer[playerId][vehicleType].Exam.Passed = true
            startedLicenseTrialPerPlayer[playerId][vehicleType].Exam.Tries = startedLicenseTrialPerPlayer[playerId][vehicleType].Exam.Tries + 1
        else 
            startedLicenseTrialPerPlayer[playerId][vehicleType] = {
                Payed = true,
                Exam = {
                    Passed = true,
                    Tries = 1
                },
                Practical = {
                    Passed = false,
                    Tries = 0
                }
            }
        end

    end
end)