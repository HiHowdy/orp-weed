ORP = nil

Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(10)
        if ORP == nil then
            TriggerEvent("ORP:GetObject", function(obj) ORP = obj end)    
            Citizen.Wait(200)
        end
    end
end)

local enhancedWeed = false

Keys = {
	['ESC'] = 322, ['F1'] = 288, ['F2'] = 289, ['F3'] = 170, ['F5'] = 166, ['F6'] = 167, ['F7'] = 168, ['F8'] = 169, ['F9'] = 56, ['F10'] = 57,
	['~'] = 243, ['1'] = 157, ['2'] = 158, ['3'] = 160, ['4'] = 164, ['5'] = 165, ['6'] = 159, ['7'] = 161, ['8'] = 162, ['9'] = 163, ['-'] = 84, ['='] = 83, ['BACKSPACE'] = 177,
	['TAB'] = 37, ['Q'] = 44, ['W'] = 32, ['E'] = 38, ['R'] = 45, ['T'] = 245, ['Y'] = 246, ['U'] = 303, ['P'] = 199, ['['] = 39, [']'] = 40, ['ENTER'] = 18,
	['CAPS'] = 137, ['A'] = 34, ['S'] = 8, ['D'] = 9, ['F'] = 23, ['G'] = 47, ['H'] = 74, ['K'] = 311, ['L'] = 182,
	['LEFTSHIFT'] = 21, ['Z'] = 20, ['X'] = 73, ['C'] = 26, ['V'] = 0, ['B'] = 29, ['N'] = 249, ['M'] = 244, [','] = 82, ['.'] = 81,
	['LEFTCTRL'] = 36, ['LEFTALT'] = 19, ['SPACE'] = 22, ['RIGHTCTRL'] = 70,
	['HOME'] = 213, ['PAGEUP'] = 10, ['PAGEDOWN'] = 11, ['DELETE'] = 178,
	['LEFT'] = 174, ['RIGHT'] = 175, ['TOP'] = 27, ['DOWN'] = 173,
}

local BlacklistedZones = {
    {x = 448.226, y = -996.318, z = 30.69, h = 256.32}, --mrpd
}

local Thread = CreateThread
local SpawnedPlants = {}
local DryingPlants = {}
local InteractedPlant = nil
local HarvestedPlants = {}
local canHarvest = true
local closestPlant = nil
local isDoingAction = false
local isLoggedIn = false
local isInApartment = false

local plyJob

RegisterNetEvent('weed:client:toggleWeedEffect')
AddEventHandler('weed:client:toggleWeedEffect', function(bool)
    enhancedWeed = bool
end)

RegisterNetEvent("ORP:Client:OnPlayerLoaded")
AddEventHandler("ORP:Client:OnPlayerLoaded", function()
    TriggerServerEvent('orp:weed:server:GetCurrentWeedData')
    isLoggedIn = true
end)

RegisterNetEvent('orp:client:weed:removeFromHarvested')
AddEventHandler('orp:client:weed:removeFromHarvested', function(plantId)
    for k,v in pairs(HarvestedPlants) do
        if v == plantId then
            table.remove(HarvestedPlants, k)
        end
    end
end)

RegisterNetEvent('weed:client:apartmentStatus')
AddEventHandler('weed:client:apartmentStatus', function(bool)
    isInApartment = bool
end)

RegisterNetEvent("ORP:Client:OnPlayerUnload")
AddEventHandler("ORP:Client:OnPlayerUnload", function()
    isLoggedIn = false
end)

Thread(function()
    while true do
    Citizen.Wait(150)

    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(ped)
    local inRange = false

        for i = 1, #Config.PlantsDrying do
            local dist = GetDistanceBetweenCoords(pos, Config.PlantsDrying[i].x, Config.PlantsDrying[i].y, Config.PlantsDrying[i].z, true)
    
            if dist < 50.0 then
                local hasSpawned = false
                inRange = true

                for z = 1, #DryingPlants do
                    local p = DryingPlants[z]
    
                    if p.id == Config.PlantsDrying[i].id then
                        hasSpawned = true
                    end
                end


                if not hasSpawned then
                    local hash = GetHashKey('bkr_prop_weed_drying_02a')
                    local data = {}

                    RequestModel(hash)

                    data.id = Config.PlantsDrying[i].id

                    while not HasModelLoaded(hash) do
                        Citizen.Wait(10)
                        RequestModel(hash)
                    end

                    data.obj = CreateObject(hash, Config.PlantsDrying[i].x, Config.PlantsDrying[i].y, Config.PlantsDrying[i].z, false, false, false) 
                    SetEntityAsMissionEntity(data.obj, true)
                    FreezeEntityPosition(data.obj, true)
                    table.insert(DryingPlants, data)
                    hasSpawned = false
                end
            end
        end

    for i = 1, #Config.Plants do
        local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.Plants[i].x, Config.Plants[i].y, Config.Plants[i].z, true)

        -- if Config.Plants[i].growth < 100 then
            if dist < 50.0 then
                inRange = true
                local hasSpawned = false
                local needsUpgrade = false
                local upgradeId = nil
                local tableRemove = nil
    
                for z = 1, #SpawnedPlants do
                    local p = SpawnedPlants[z]
    
                    if p.id == Config.Plants[i].id then
                        hasSpawned = true
                        if p.stage ~= Config.Plants[i].stage then
                            needsUpgrade = true
                            upgradeId = p.id
                            tableRemove = z
                        end
                    end
                end
    
                if not hasSpawned then
                    local hash = GetHashKey(Config.WeedStages[Config.Plants[i].stage])
                    RequestModel(hash)
                    local data = {}
                    data.id = Config.Plants[i].id
                    data.stage = Config.Plants[i].stage
    
                    while not HasModelLoaded(hash) do
                        Citizen.Wait(10)
                        RequestModel(hash)
                    end
    
                    data.obj = CreateObject(hash, Config.Plants[i].x, Config.Plants[i].y, Config.Plants[i].z + GetPlantZ(Config.Plants[i].stage), false, false, false) 
                    SetEntityAsMissionEntity(data.obj, true)
                    FreezeEntityPosition(data.obj, true)
                    table.insert(SpawnedPlants, data)
                    hasSpawned = false
                end
    
                if needsUpgrade then
                    for o = 1, #SpawnedPlants do
                        local u = SpawnedPlants[o]
    
                        if u.id == upgradeId then
                            SetEntityAsMissionEntity(u.obj, false)
                            FreezeEntityPosition(u.obj, false)
                            DeleteObject(u.obj)
    
                            local hash = GetHashKey(Config.WeedStages[Config.Plants[i].stage])
                            RequestModel(hash)
                            local data = {}
                            data.id = Config.Plants[i].id
                            data.stage = Config.Plants[i].stage
    
                            while not HasModelLoaded(hash) do
                                Citizen.Wait(10)
                                RequestModel(hash)
                            end
    
                            data.obj = CreateObject(hash, Config.Plants[i].x, Config.Plants[i].y, Config.Plants[i].z + GetPlantZ(Config.Plants[i].stage), false, false, false) 
                            SetEntityAsMissionEntity(data.obj, true)
                            FreezeEntityPosition(data.obj, true)
                            table.remove(SpawnedPlants, o)
                            table.insert(SpawnedPlants, data)
                            needsUpgrade = false
                        end
                    end
                end
            end
        -- end
    end
    end

end)

RegisterNetEvent('orp:weed:server:setAsNotDone')
AddEventHandler('orp:weed:server:setAsNotDone', function(id)
    for k,v in pairs(HarvestedPlants) do
        if v == id then
            table.remove(HarvestedPlants, k)
            return
        end
    end
    return
end)

function HarvestDryingPlant()
    local plant = GetClosestDryingPlant()
    local hasDone = false

    for k,v in pairs(HarvestedPlants) do
        if v == plant.id then
            hasDone = true
        end
    end

    if not hasDone then
        table.insert(HarvestedPlants, plant.id)
        local ped = GetPlayerPed(-1)
        isDoingAction = true
        TriggerServerEvent('orp:weed:plantHasBeenHarvested', 'drying', plant.id)

        RequestAnimDict('amb@prop_human_bum_bin@base')
        while not HasAnimDictLoaded('amb@prop_human_bum_bin@base') do
            Citizen.Wait(0)
        end

        TaskPlayAnim(ped, 'amb@prop_human_bum_bin@base', 'base', 8.0, 8.0, -1, 1, 1, 0, 0, 0)
        
        ORP.Functions.Progressbar("harvest_plant", "Harvesting Plant...", math.random(5000, 6000), false, false, {}, {}, {}, {}, function() -- Done
            TriggerServerEvent('orp:weed:harvestWeed', plant.id)
            canHarvest = true
            isDoingAction = false
        end, function() -- Cancel

        
            
        end)
    end
end

-- function SetPlantTimeout(id)
--     Citizen.SetTimeout(10000, function()
--         TriggerEvent()
--     end)
-- end

function HarvestWeedPlant()
    local plant = GetClosestPlant()
    local hasDone = false

    for k, v in pairs(HarvestedPlants) do
        if v == plant.id then
            hasDone = true
        end
    end

    if not hasDone then
        table.insert(HarvestedPlants, plant.id)
        local ped = GetPlayerPed(-1)
        isDoingAction = true
        TriggerServerEvent('orp:weed:plantHasBeenHarvested', 'plant', plant.id)

        RequestAnimDict('amb@prop_human_bum_bin@base')
        while not HasAnimDictLoaded('amb@prop_human_bum_bin@base') do
            Citizen.Wait(0)
        end

        TaskPlayAnim(ped, 'amb@prop_human_bum_bin@base', 'base', 8.0, 8.0, -1, 1, 1, 0, 0, 0)
        
        ORP.Functions.Progressbar("harvest_plant", "Harvesting Plant...", math.random(5000, 6000), false, false, {}, {}, {}, {}, function() -- Done
            canHarvest = true
            TriggerServerEvent('orp:weed:harvestPlant', plant.id, enhancedWeed)
            isDoingAction = false
        end, function() -- Cancel
            ORP.Functions.Notify("Cancelled", "error")
        end)
        canHarvest = true
    else
        ORP.Functions.Notify("Error", "error")
    end
end

function DestroyWeedPlant()
    local plant = GetClosestPlant()
    local hasDone = false

    for k, v in pairs(HarvestedPlants) do
        if v == plant.id then
            hasDone = true
        end
    end

    if not hasDone then
        table.insert(HarvestedPlants, plant.id)
        local ped = GetPlayerPed(-1)
        isDoingAction = true
        TriggerServerEvent('orp:weed:plantHasBeenHarvested', plant.id)

        RequestAnimDict('amb@prop_human_bum_bin@base')
        while not HasAnimDictLoaded('amb@prop_human_bum_bin@base') do
            Citizen.Wait(0)
        end

        TaskPlayAnim(ped, 'amb@prop_human_bum_bin@base', 'base', 8.0, 8.0, -1, 1, 1, 0, 0, 0)
        ORP.Functions.Progressbar("harvest_plant", "Destroying Plant...", math.random(1000, 2000), false, false, {}, {}, {}, {}, function() -- Done
            TriggerServerEvent('orp:weed:destroyWeed', plant.id)
            canHarvest = true
            isDoingAction = false
        end, function() -- Cancel
            ORP.Functions.Notify("Cancelled", "error")
        end)
    else
        ORP.Functions.Notify("Error", "error")
    end
end

function RemovePlantFromTable(plantId)
    for k, v in pairs(Config.Plants) do
        if v.id == plantId then
            table.remove(Config.Plants, k)
        end
    end
end

Thread(function()
    while true do
        Citizen.Wait(0)
        if ORP ~= nil then
            local InRange = false
            local ped = GetPlayerPed(-1)
            local pos = GetEntityCoords(ped)

            for k, v in pairs(Config.Plants) do
                -- if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, v.x, v.y, v.z, true) < 1.3 and not isDoingAction and not v.beingHarvested and not IsPedInAnyVehicle(GetPlayerPed(-1), false) and isLoggedIn then
                    if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, v.x, v.y, v.z, true) < 1.3 and not isDoingAction and not v.beingHarvested and not IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                    ORP.Functions.GetPlayerData(function(PlayerData)
                        if PlayerData.job.name == 'police' then
                            local plant = GetClosestPlant()
                            ORP.Functions.DrawText3D(v.x, v.y, v.z, '~r~E~w~ - Destroy Plant')
                            if IsControlJustReleased(0, Keys["E"]) then
                                if v.id == plant.id then
                                    DestroyWeedPlant()
                                end
                            end
                        else
                            if v.growth < 100 then
                                local plant = GetClosestPlant()
                                ORP.Functions.DrawText3D(v.x, v.y, v.z, 'Thirst: ' .. v.thirst .. '% - Hunger: ' .. v.hunger .. '% - Growth: ' ..  v.growth .. '% -  Quality: ' .. v.quality)
                                ORP.Functions.DrawText3D(v.x, v.y, v.z - 0.18, '~b~G~w~ - Water      ~y~H~w~ - Feed')
                                if IsControlJustReleased(0, Keys["G"]) then
                                    if v.id == plant.id then
                                        if v.thirst < 100 then
                                            TriggerEvent('orp:weed:client:waterPlant')
                                        else
                                            ORP.Functions.Notify('This plant does not need water', 'error', 4500)
                                        end
                                    end
                                elseif IsControlJustReleased(0, Keys["H"]) then
                                    if v.id == plant.id then
                                        if v.hunger < 100 then
                                            TriggerEvent('orp:weed:client:feedPlant')
                                        else
                                            ORP.Functions.Notify('This plant does not need fertilizer', 'error', 4500)
                                        end
                                    end
                                end
                            else
                                ORP.Functions.DrawText3D(v.x, v.y, v.z, '[Quality: ' .. v.quality .. ']')
                                ORP.Functions.DrawText3D(v.x, v.y, v.z - 0.18, '~g~E~w~ - Harvest')
                                if IsControlJustReleased(0, Keys["E"]) and canHarvest then
                                    local plant = GetClosestPlant()
                                    if v.id == plant.id then
                                        HarvestWeedPlant()
                                    end
                                end
                            end
                        end
                    end)
                end
            end

            for k,v in pairs(Config.PlantsDrying) do
                if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, v.x, v.y, v.z, true) < 1.3 and not isDoingAction and not v.beingHarvested and not IsPedInAnyVehicle(ped, false) then
                    ORP.Functions.GetPlayerData(function(PlayerData)
                        if PlayerData.job.name == 'police' then
                            local plant = GetClosestDryingPlant()
                            ORP.Functions.DrawText3D(v.x, v.y, v.z, '~r~E~w~ - Destroy Plant')
                            if IsControlJustReleased(0, Keys["E"]) then
                                --TODO
                            end
                        else
                            if v.growth < 100 then
                                local plant = GetClosestDryingPlant()
                                ORP.Functions.DrawText3D(v.x, v.y, v.z + 0.7, 'Drying - ' .. v.growth .. '%')
                            else
                                ORP.Functions.DrawText3D(v.x, v.y, v.z + 0.7, '~g~E~w~ - Harvest')
                                if IsControlJustReleased(0, Keys["E"]) and canHarvest then
                                    local plant = GetClosestDryingPlant()
                                    if v.id == plant.id then
                                        HarvestDryingPlant()
                                    end
                                end
                            end
                        end
                    end)
                end
            end

            
        end
    end
end)

local IsSearching = false

Thread(function()
    while true do
        Citizen.Wait(0)
        if ORP ~= nil then
            local ped = GetPlayerPed(-1)
            local pos = GetEntityCoords(ped)
            local InRange = false

            for k, v in pairs(Config.SeedLocations) do
                if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, v.x, v.y, v.z) < 1.5 then
                    InRange = true
                end
            end

            if InRange and not IsSearching and not IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                ORP.Functions.DrawText3D(pos.x, pos.y, pos.z, '~y~G~w~ - Search')
                if IsControlJustReleased(0, Keys["G"]) then
                    IsSearching = true
                    RequestAnimDict('amb@prop_human_bum_bin@base')
                    while not HasAnimDictLoaded('amb@prop_human_bum_bin@base') do
                        Citizen.Wait(0)
                    end

                    TaskPlayAnim(ped, 'amb@prop_human_bum_bin@base', 'base', 8.0, 8.0, -1, 1, 1, 0, 0, 0)
                    ORP.Functions.Progressbar("searching_seeds", "Searching...", math.random(9000, 14000), false, true, {}, {}, {}, {}, function() -- Done
                        local chance = math.random(1, 10)

                        if chance > 7 then
                            TriggerServerEvent('orp:weed:server:giveShittySeed')
                        end
                        Citizen.Wait(3000)
                        IsSearching = false
                    end, function() -- Cancel
                        Citizen.Wait(3000)
                        IsSearching = false
                    end)
                end
            else
                Citizen.Wait(3000)
            end
        end
    end
end)

function GetClosestPlant()
    local dist = 1000
    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(ped)
    local plant = {}

    for i = 1, #Config.Plants do
        local xd = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.Plants[i].x, Config.Plants[i].y, Config.Plants[i].z, true)
        if xd < dist then
            dist = xd
            plant = Config.Plants[i]
        end
    end

    return plant
end

function GetClosestDryingPlant()
    local dist = 1000
    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(ped)
    local plant = {}

    for i = 1, #Config.PlantsDrying do
        local xd = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.PlantsDrying[i].x, Config.PlantsDrying[i].y, Config.PlantsDrying[i].z, true)
        if xd < dist then
            dist = xd
            plant = Config.PlantsDrying[i]
        end
    end

    return plant
end

RegisterNetEvent('orp:weed:client:removeWeedObject')
AddEventHandler('orp:weed:client:removeWeedObject', function(plant)
    for i = 1, #SpawnedPlants do
        local o = SpawnedPlants[i]
        if o.id == plant then
            SetEntityAsMissionEntity(o.obj, false)
            FreezeEntityPosition(o.obj, false)
            DeleteObject(o.obj)
        end
    end
end)

RegisterNetEvent('orp:weed:client:removeWeedObjectDrying')
AddEventHandler('orp:weed:client:removeWeedObjectDrying', function(plant)
    for i = 1, #DryingPlants do
        local o = DryingPlants[i]
        if o.id == plant then
            SetEntityAsMissionEntity(o.obj, false)
            FreezeEntityPosition(o.obj, false)
            DeleteObject(o.obj)
        end
    end
end)

RegisterNetEvent('orp:weed:client:notify')
AddEventHandler('orp:weed:client:notify', function(msg, type)
    if type ~= nil then
        ORP.Functions.Notify(msg, type)
    else
        ORP.Functions.Notify(msg)
    end
end)

RegisterNetEvent('orp:weed:client:waterPlant')
AddEventHandler('orp:weed:client:waterPlant', function()
    local entity = nil
    local plant = GetClosestPlant()
    isDoingAction = true

    for k, v in pairs(SpawnedPlants) do
        if v.id == plant.id then
            entity = v.obj
        end
    end

    TaskTurnPedToFaceEntity(GetPlayerPed(-1), entity, -1)

    RequestAnimDict('amb@prop_human_bum_bin@base')
    while not HasAnimDictLoaded('amb@prop_human_bum_bin@base') do
        Citizen.Wait(0)
    end
    
    ORP.Functions.TriggerCallback('ORP:HasItem', function(resulto)
        print('hi')
        if resulto then
            print('cunt')
            TaskPlayAnim(ped, 'amb@prop_human_bum_bin@base', 'base', 8.0, 8.0, -1, 1, 1, 0, 0, 0)
            ORP.Functions.Progressbar("watering_plant", "Watering...", math.random(1000, 2000), false, false, {}, {}, {}, {}, function() -- Done
                TriggerServerEvent('orp:weed:server:waterPlant', plant.id)
                ClearPedTasksImmediately(GetPlayerPed(-1))
                isDoingAction = false
            end, function() -- Cancel
                ORP.Functions.Notify("Cancelled", "error")
            end)
        else
            return
        end
    end, 'fertilizer')
end)

RegisterNetEvent('orp:weed:client:feedPlant')
AddEventHandler('orp:weed:client:feedPlant', function()
    local entity = nil
    local plant = GetClosestPlant()
    isDoingAction = true

    for k, v in pairs(SpawnedPlants) do
        if v.id == plant.id then
            entity = v.obj
        end
    end

    TaskTurnPedToFaceEntity(GetPlayerPed(-1), entity, -1)

    RequestAnimDict('amb@prop_human_bum_bin@base')
    while not HasAnimDictLoaded('amb@prop_human_bum_bin@base') do
        Citizen.Wait(0)
    end

    ORP.Functions.TriggerCallback('ORP:HasItem', function(result)
        if result then
            TaskPlayAnim(ped, 'amb@prop_human_bum_bin@base', 'base', 8.0, 8.0, -1, 1, 1, 0, 0, 0)
            ORP.Functions.Progressbar("fertilizing_plant", "Fertilizing...", math.random(1000, 2000), false, false, {}, {}, {}, {}, function() -- Done
                TriggerServerEvent('orp:weed:server:feedPlant', plant.id)
                ClearPedTasksImmediately(GetPlayerPed(-1))
                isDoingAction = false
            end, function() -- Cancel
                ORP.Functions.Notify("Cancelled", "error")
            end)
        end
    end, 'fertilizer')
end)

RegisterNetEvent('orp:weed:client:updateWeedData')
AddEventHandler('orp:weed:client:updateWeedData', function(plantData, dryingData)
    Config.Plants = plantData
    Config.PlantsDrying = dryingData
end)

RegisterNetEvent('orp:weed:client:plantNewSeed')
AddEventHandler('orp:weed:client:plantNewSeed', function(type, seed)
    local pos = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 1.0, 0.0)
    local coords = GetEntityCoords(GetPlayerPed(-1))

    if isInApartment then
        ORP.Functions.Notify('Cannot plant weed in hotel rooms', 'error')
    else
        local canPlantHere = true

        for k,v in pairs(BlacklistedZones) do
            if GetDistanceBetweenCoords(coords, v.x, v.y, v.z, false) < 50.0 then
                canPlantHere = false
            end
        end

        if canPlantHere then
            if CanPlantSeedHere(pos) and not IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                TriggerServerEvent('orp:weed:server:plantNewSeed', type, pos, seed)
            end
        else
            ORP.Functions.Notify('Cannot dry in this location', 'error')
        end
    end
end)

RegisterNetEvent('orp:weed:client:dryNewWeed')
AddEventHandler('orp:weed:client:dryNewWeed', function(type, grade, item)
    local pos = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 1.0, 0.0)
    local coords = GetEntityCoords(GetPlayerPed(-1))
    
    if isInApartment then
        ORP.Functions.Notify('Cannot dry weed in hotel rooms', 'error')
    else
        local canPlantHere = true

        for k,v in pairs(BlacklistedZones) do
            if GetDistanceBetweenCoords(coords, v.x, v.y, v.z, false) < 75.0 then
                canPlantHere = false
            end
        end

        if canPlantHere then
            if not IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                TriggerServerEvent('orp:weed:server:dryNewWeed', type, pos, grade, item)
            end
        else
            ORP.Functions.Notify('Cannot dry in this location', 'error')
        end
    end
end)

RegisterNetEvent('orp:weed:client:plantSeedConfirm')
AddEventHandler('orp:weed:client:plantSeedConfirm', function()
    RequestAnimDict("pickup_object")

    while not HasAnimDictLoaded("pickup_object") do
        Citizen.Wait(7)
    end
    TaskPlayAnim(GetPlayerPed(-1), "pickup_object" ,"pickup_low" ,8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(1800)
    ClearPedTasks(GetPlayerPed(-1))
end)

function CanPlantSeedHere(pos)
    local canPlant = true

    for i = 1, #Config.Plants do
        if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.Plants[i].x, Config.Plants[i].y, Config.Plants[i].z, true) < 1.3 then
            canPlant = false
        end
    end

    return canPlant
end

function GetPlantZ(stage)
    if stage == 1 then return -1.0
    else return -3.5
    end
end