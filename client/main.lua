local SCRIPTSTORM_DMV = {
    Data = {}
}

local CurrentDMV = nil
local CurrentVehicle = nil
local LastVehicleHealth = 100
local FailedDriverTest = false
local DriveErrors = 0

local activeBlips, markerPoints, dmvPoints, licenses = {}, {}, {}, {}
local playerLoaded, uiActive, inMenu, drivingTestActive, displayWarning = false, false, false
local warningCountdown, numWarnings = 0
local countDown = 5
local countDownActive = false

        function SCRIPTSTORM_DMV:Thread() 
            self:CreateBlips()
            local data = self.Data
            data.ped = PlayerPedId()
            data.coord = GetEntityCoords(data.Ped)
            playerLoaded = true

            CreateThread(function ()
                while playerLoaded do
                    data.coord = GetEntityCoords(data.ped)
                    data.ped = PlayerPedId()

                    if (IsPedOnFoot(data.ped) and not ESX.PlayerData.dead) and not inMenu then
                        for i = 1, #Config.DMV do
                            local dmvDistance = #(data.coord - Config.DMV[i].Pos)
                            if dmvDistance <= 3 then
                                dmvPoints[#dmvPoints+1] = Config.DMV[i].Pos
                                CurrentDMV = Config.DMV[i]
                                self:LoadLicenses(CurrentDMV)
                                break
                            else 
                                CurrentDMV = nil
                                dmvPoints = {}
                            end
                            if Config.ShowMarker and dmvDistance <= (Config.DrawMarker or 10) then
                                markerPoints[#markerPoints+1] = Config.DMV[i].Pos
                            end
                        end
                    end

                    if next(dmvPoints) and not uiActive then
                        self:TextUi(true)
                    end

                    if not next(dmvPoints) and uiActive then
                        self:TextUi(false)
                    end    

                    Wait(1000)
                end
            end)

            if not Config.ShowMarker then return end

            CreateThread(function()
                local wait = 1000
                while playerLoaded do
                    if next(markerPoints) then
                        for i = 1, #markerPoints do
                            DrawMarker(1, markerPoints[i].x, markerPoints[i].y, markerPoints[i].z,
                             0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 187, 255, 0, 255, false, true, 2, false, nil, nil, false)
                        end
                        wait = 0
                    end
                    Wait(wait)
                end
            end)

            CreateThread(function() 
                SCRIPTSTORM_DMV:CheckForDrivingErrors() 
            end)

            CreateThread(function() 
                while countDownActive and drivingTestActive do 
                    SendNUIMessage({
                        showMenu = true,
                        action = "showCountdown",
                        data = {
                            countdown = countdown
                        },
                    })
                end 
            end)
        end

        function SCRIPTSTORM_DMV:LoadQuestions(vehicleType, language)
            if language ~= nil then 
                local fileData = LoadResourceFile(GetCurrentResourceName(), ('questions/%s/%s.json'):format(language, vehicleType))
                local saveData = {}
                if fileData then
                    saveData = json.decode(fileData)
                    return saveData
                end
            end 

            local fd = LoadResourceFile(GetCurrentResourceName(), ('questions/en/%s.json'):format(vehicleType))

            if fd then
                Citizen.Trace('No language set for scriptstorm_dmv, fetching default en' ..saveData)
                saveData = json.decode(fd)
                return saveData
            end
        end

        function SCRIPTSTORM_DMV:LoadLicenses(dmv)
            if CurrentDMV and CurrentDMV.Licenses then 
                for vechicleType in string.gmatch(CurrentDMV.Licenses, '([^,]+)') do
                    for k,v in pairs(Config.Licenses) do
                        if k:lower() == vechicleType:lower() then
                            if not CurrentDMV.AvailableLicenses then 
                                CurrentDMV["AvailableLicenses"] = {}
                            end
                            CurrentDMV["AvailableLicenses"][k:lower()] = {
                                type = k:lower(),
                                prerequiredLicense = v.PrerequiredLicense,
                                price = v.Price,
                                model = v.Model,
                                minimumCorrectExam = v.MinimumCorrectExam,
                                questions = SCRIPTSTORM_DMV:LoadQuestions(k:lower(), Config.Language),
                                questionnaireAmount = v.QuestionnaireAmount
                            }
                        end
                    end 
                end
            end
        end

        -- Handle text ui / Keypress
        function SCRIPTSTORM_DMV:TextUi(state)
            uiActive = state
            if not state then
                return ESX.HideUI()
            end
            if inMenu == false then
                ESX.TextUI(TranslateCap('press_e_dmv'))
            end

            CreateThread(function()
                while uiActive do
                    if IsControlJustReleased(0, 38) then
                        self:HandleUi(true)
                        self:TextUi(false)
                    end
                    Wait(0)
                end
            end)
        end

        -- Open / Close ui
        function SCRIPTSTORM_DMV:HandleUi(state)
            SetNuiFocus(state, state)
            inMenu = state
            ClearPedTasks(PlayerPedId())
            if not state then
                SendNUIMessage({
                    showMenu = false,
                })
                return
            end
            ESX.TriggerServerCallback('scst_dmv:getPlayerData', function(data)
                SendNUIMessage({
                    showMenu = true,
                    action = "openStartMenu",
                    data = {
                        player = {
                            id = PlayerPedId(),
                            licenses = data.Licenses,
                            startedTrials = data.StartedTrials,
                        },
                        availableLicenses = CurrentDMV.AvailableLicenses,
                        maxRetries = {
                            exam = Config.MaxRetries.Exam,
                            practical = Config.MaxRetries.Practical
                        }
                    },
                    translations = {
                        prerequiredLicense = TranslateCap('prerequired_license_dmv', '$$'),
                        license = TranslateCap('license_dmv'),
                        errors = TranslateCap('errors_dmv'),
                        practical = TranslateCap('practical_dmv'),
                        exam = TranslateCap('exam_dmv'),
                        questions = TranslateCap('questions_dmv'),
                        car = TranslateCap('car_dmv'),
                        bike = TranslateCap('bike_dmv'),
                        truck = TranslateCap('truck_dmv'),
                        selectLicense = TranslateCap('select_license_dmv'),
  			            getReady = TranslateCap('get_ready_dmv'),
                        youFailed =  TranslateCap('you_failed_dmv'),
                        youPassed =  TranslateCap('you_passed_dmv'),
                        getReadyText = TranslateCap('get_ready_text_dmv'),
                        results = TranslateCap('results_dmv')
                    }
                })
            end)
        end

        -- Create Blips
        function SCRIPTSTORM_DMV:CreateBlips()
            local tmpActiveBlips = {}
            for i = 1, #Config.DMV do
                if type(Config.DMV[i].Blip) == 'table' and Config.DMV[i].Blip.Enabled then
                    local position = Config.DMV[i].Pos
                    local bInfo = Config.DMV[i].Blip
                    local blip = AddBlipForCoord(position.x, position.y, position.z)
                    SetBlipSprite(blip, bInfo.Sprite)
                    SetBlipScale(blip, bInfo.Scale)
                    SetBlipColour(blip, bInfo.Color)
                    SetBlipDisplay(blip, 4)
                    SetBlipAsShortRange(blip, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentSubstringPlayerName(bInfo.Label)
                    EndTextCommandSetBlipName(blip)
                    tmpActiveBlips[#tmpActiveBlips + 1] = blip
                end
            end

            activeBlips = tmpActiveBlips
        end

        -- Remove blips
        function SCRIPTSTORM_DMV:RemoveBlips()
            for i = 1, #activeBlips do
                if DoesBlipExist(activeBlips[i]) then
                    RemoveBlip(activeBlips[i])
                end
            end
            activeBlips = {}
        end

        function SCRIPTSTORM_DMV:LoadNpc(index, netID, scenario)
            CreateThread(function()
                while not NetworkDoesEntityExistWithNetworkId(netID) do
                    Wait(200)
                end
                local npc = NetworkGetEntityFromNetworkId(netID)
                TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_CLIPBOARD', 0, true)
                SetEntityProofs(npc, true, true, true, true, true, true, true, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                FreezeEntityPosition(npc, true)
                SetPedCanRagdollFromPlayerImpact(npc, false)
                SetPedCanRagdoll(npc, false)
                SetEntityAsMissionEntity(npc, true, true)
                SetEntityDynamic(npc, false)
            end)
        end

        function SCRIPTSTORM_DMV:StartDrivingTest(state, vehicleType) 
            local playerHeading = GetEntityHeading(playerPed)
            countDown = 5
            countDownActive = false

            if CurrentDMV and CurrentDMV["AvailableLicenses"] ~= nil and 
            CurrentDMV["AvailableLicenses"][vehicleType:lower()] ~= nil and CurrentDMV.VehicleSpawnPoint then 
                local vehicle = CurrentDMV["AvailableLicenses"][vehicleType:lower()]
                Citizen.Trace(vehicle.model:upper())
                Citizen.Trace(CurrentDMV.VehicleSpawnPoint.x)
                ESX.Game.SpawnVehicle(vehicle.model:upper(), CurrentDMV.VehicleSpawnPoint,playerHeading, function(vehicle)

                    CurrentVehicle    = vehicle
                    LastVehicleHealth = GetEntityHealth(vehicle)
                    FailedDriverTest = false
                    drivingTestActive = true
            
                    local playerPed   = PlayerPedId()
                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                    SetVehicleFuelLevel(vehicle, 100.0)
                    DecorSetFloat(vehicle, "_FUEL_LEVEL", GetVehicleFuelLevel(vehicle))
                end)
            end
        end

        function translateVector3(pos, angle, distance)
            local angleRad = angle * 2.0 * math.pi / 360.0
            return vector3(pos.x - distance*math.sin(angleRad), pos.y + distance*math.cos(angleRad), pos.z)
        end

        function GetPlayerLookingVector(playerped, radius)
            local pedyaw = GetEntityHeading(playerped)
            local camyaw = GetGameplayCamRelativeHeading()
            local pitch = 90.0-GetGameplayCamRelativePitch()
            local yaw = pedyaw + camyaw
        
            if yaw > 180 then
                yaw = yaw - 360
            elseif yaw < -180 then
                yaw = yaw + 360
            end
            local pitch = pitch * math.pi / 180
            local yaw = yaw * math.pi / 180
            local x = radius * math.sin(pitch) * math.sin(yaw)
            local y = radius * math.sin(pitch) * math.cos(yaw)
            local z = radius * math.cos(pitch)
            local playerpedcoords = GetGameplayCamCoord()
            local xcorr = -x+ playerpedcoords.x
            local ycorr = y+ playerpedcoords.y
            local zcorr = z+ playerpedcoords.z
            local Vector = vector3(tonumber(xcorr), tonumber(ycorr), tonumber(zcorr))
            return Vector
        end

        function SCRIPTSTORM_DMV:GetClosestTrafficLight() 

            local player = PlayerPedId()
            local playerPosition = GetEntityCoords(player)
            local playerHeading = GetEntityHeading(player)
            local camcoords = GetGameplayCamCoord()
            local lookingvector = GetPlayerLookingVector(playerped, 30)

            local SEARCH_STEP_SIZE = 10.0    
            local SEARCH_MIN_DISTANCE = 20.0 
            local SEARCH_MAX_DISTANCE = 100.0
            local HEADING_THRESHOLD = 300.0  
            local SEARCH_RADIUS = 50.0 

            local trafficLightObjects = {
                [0] = 'prop_traffic_01a',  
                [1] = 'prop_traffic_01b', 
                [2] = 'prop_traffic_01d', 
                [3] = 'prop_traffic_02a', 
                [4] = 'prop_traffic_02b',  
                [5] = 'prop_traffic_03a',  
                [6] = 'prop_traffic_03b'  
            }

            local trafficLight = 0

                for _, trafficLightObject in pairs(trafficLightObjects) do
                    local modelHash = GetHashKey(trafficLightObject)
                    -- Check if there is a traffic light in front of player
                    trafficLight = GetClosestObjectOfType(lookingvector, SEARCH_RADIUS, modelHash, false, false, false)
                    if trafficLight ~= 0 then
                        -- Check traffic light heading relative to player heading (to prevent setting the wrong lights)
                        local lightHeading = GetEntityHeading(trafficLight)
                        local headingDiff = math.abs(playerHeading - lightHeading)
                        local state = Entity(trafficLight).state
                        Citizen.Trace('state' ..trafficLight ..'\n')
                        SetEntityDrawOutline(trafficLight, true)
                        if state ~= nil then 
                            Citizen.Trace('state' ..table.concat(state) ..'\n')
                        end

                        if ((headingDiff < HEADING_THRESHOLD) or (headingDiff > (360.0 - HEADING_THRESHOLD))) then
                            Citizen.Trace('found trafficLight' ..trafficLight ..'\n')
                            -- Within threshold, stop searching
                            break
                        else
                            -- Outside threshold, skip and keep searching
                            trafficLight = 0
                        end
                    end

                -- If traffic light found stop searching
                if trafficLight ~= 0 then
                    break
                end
            end

            return trafficLight
        end

        function SCRIPTSTORM_DMV:CheckForDrivingErrors()
            while true do 
                local sleep = 1500
                local maxSpeed = Config.SpeedLimits.City

                if drivingTestActive then 
                    local playerPed = PlayerPedId()
                    if IsPedInAnyVehicle(playerPed, false) then

                        if countDownActive then 
                            SendNUIMessage({
                                showMenu = false,
                            })
                            countDownActive = false
                            countDown = 5
                        end 
                        local vehicle = GetVehiclePedIsIn(playerPed, false)
                        local coords = GetEntityCoords(PlayerPedId())
                        local speed = GetEntitySpeed(vehicle)
                        local health = GetEntityHealth(vehicle)
                        local vehicleNodeId = GetNthClosestVehicleNodeId(coords.x, coords.y, coords.z)
        
                        if health < LastVehicleHealth then
                            DriveErrors += 1
                            ESX.ShowNotification(TranslateCap('you_damaged_veh'))
                            LastVehicleHealth = health
                            sleep = 1500
                        end

                        if IsPlayerDrivingDangerously(playerPed, 0) then
                            Citizen.Trace('IsPlayerDrivingDangerously 0' ..tostring(IsPlayerDrivingDangerously(playerPed, 0))..'\n')
                            ESX.ShowNotification(TranslateCap('you_not_on_road'))
                        end
                        if IsPlayerDrivingDangerously(playerPed, 1) then
                            Citizen.Trace('IsPlayerDrivingDangerously 1' ..tostring(IsPlayerDrivingDangerously(playerPed, 1))..'\n')
                            ESX.ShowNotification(TranslateCap('you_ran_a_red_light'))
                        end
        
                        if IsPlayerDrivingDangerously(playerPed, 2) then
                            Citizen.Trace('IsPlayerDrivingDangerously 2' ..tostring(IsPlayerDrivingDangerously(playerPed, 2)) ..'\n')
                            ESX.ShowNotification(TranslateCap('you_driving_against_traffic'))
                        end

                        local _, density, flags = GetVehicleNodeProperties(coords.x, coords.y, coords.z)

                        if density == 6 then
                            maxSpeed = Config.SpeedLimits.Highway
                        else 
                            maxSpeed = Config.SpeedLimits.City
                        end

                        if density == 8 then 
                         /* TODO Loop through the mission traffic lights  */
                        end

                        if speed > maxSpeed then 
                            ESX.ShowNotification(TranslateCap('driving_too_fast'))
                        end
                    end

                    if not IsPedInAnyVehicle(playerPed, false) or IsPlayerDead(playerPed) then
                        sleep = 1000
                        countDownActive = true 
                        if countDown == 0 then 
                            DeleteVehicle(CurrentVehicle)
                            CurrentVehicle = nil
                            SendNUIMessage({
                                showMenu = false,
                            })
                            drivingTestActive = false
                        else
                            countDown -= 1
                            SendNUIMessage({
                                showMenu = true,
                                action = "showCountdown",
                                data = {
                                    countdown = countDown,
                                    text = TranslateCap('get_back_in_vehicle'),
                                },
                            })
                        end
                    end
                end
    
                Wait(sleep)
            end
        end

-- Events
RegisterNetEvent('scst_dmv:pedHandler', function(netIdTable)
    for i = 1, #netIdTable do
        SCRIPTSTORM_DMV:LoadNpc(i, netIdTable[i])
    end
end)

-- Handlers

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SCRIPTSTORM_DMV:Thread()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SCRIPTSTORM_DMV:RemoveBlips()
    if uiActive then SCRIPTSTORM_DMV:TextUi(false) end
end)

RegisterNetEvent('esx:playerLoaded', function()
    SCRIPTSTORM_DMV:Thread()
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    playerLoaded = false
end)

-- Nui Callbacks
RegisterNUICallback('close', function(data, cb)
    SCRIPTSTORM_DMV:HandleUi(false)
    cb('ok')
end)

RegisterNUICallback('initDriving', function(data, cb)
    SCRIPTSTORM_DMV:HandleUi(false)
    SCRIPTSTORM_DMV:StartDrivingTest(true, data.type)
    cb('ok')
end)

RegisterNUICallback('handlePay', function(data, cb)
    ESX.TriggerServerCallback('scst_dmv:canYouPay', function(hasPayed)
        if hasPayed then
            cb(true)
        else 
            cb(false)
        end 
    end, data.type)
end)

RegisterNUICallback('failExam', function(data, cb)
    TriggerServerEvent('scst_dmv:failExam', data.type)
    cb('ok')
end)


RegisterNUICallback('passExam', function(data, cb)
    TriggerServerEvent('scst_dmv:passExam', data.type)
    cb('ok')
end)
