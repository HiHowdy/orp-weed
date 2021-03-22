ORP = nil

TriggerEvent('ORP:GetObject', function(obj) ORP = obj end)

local Thread = Citizen.CreateThread
local PlantsLoaded = false

Thread(function()
    TriggerEvent('orp:weed:server:getWeedPlants')
    print('PLANTS HAVE BEEN LOADED CUNT')
    PlantsLoaded = true
end)

RegisterServerEvent('orp:weed:server:getWeedPlants')
AddEventHandler('orp:weed:server:getWeedPlants', function()
    local data = {}
    ORP.Functions.ExecuteSql(true, "SELECT * FROM `weed_plants`", function(result)
        if result then
            for i = 1, #result do
                local plantData = json.decode(result[i].properties)
                plantData.beingHarvested = false
                table.insert(Config.Plants, plantData)
            end
        end

        ORP.Functions.ExecuteSql(true, "SELECT * FROM `weed_drying`", function(result)
            if result then
                for k = 1, #result do
                    local plantData = json.decode(result[k].properties)
                    plantData.beingHarvested = false
                    table.insert(Config.PlantsDrying, plantData)
                end
            end
        end)
    end)
end)

ORP.Functions.CreateUseableItem("bananakush", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:dryNewWeed', src, 'bananakush', 'good', 'bananakush')
end)

ORP.Functions.CreateUseableItem("bluedream", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:dryNewWeed', src, 'bluedream', 'good', 'bluedream')
end)

ORP.Functions.CreateUseableItem("purplehaze", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:dryNewWeed', src, 'purplehaze', 'good', 'purplehaze')
end)

ORP.Functions.CreateUseableItem("ogkush", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:dryNewWeed', src, 'ogkush', 'good', 'ogkush')
end)

ORP.Functions.CreateUseableItem("lowbananakush", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:dryNewWeed', src, 'bananakush', 'bad', 'lowbananakush')
end)

ORP.Functions.CreateUseableItem("lowbluedream", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:dryNewWeed', src, 'bluedream', 'bad', 'lowbluedream')
end)

ORP.Functions.CreateUseableItem("lowpurplehaze", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:dryNewWeed', src, 'purplehaze', 'bad', 'lowpurplehaze')
end)

ORP.Functions.CreateUseableItem("lowogkush", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:dryNewWeed', src, 'ogkush', 'bad', 'lowogkush')
end)

ORP.Functions.CreateUseableItem("weed_og-kush_seed", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:plantNewSeed', src, 'og_kush', 'weed_og-kush_seed')
end)

ORP.Functions.CreateUseableItem("weed_bananakush_seed", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:plantNewSeed', src, 'banana_kush', 'weed_bananakush_seed')
end)

ORP.Functions.CreateUseableItem("weed_bluedream_seed", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:plantNewSeed', src, 'blue_dream', 'weed_bluedream_seed')
end)

ORP.Functions.CreateUseableItem("weed_purple-haze_seed", function(source, item)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    TriggerClientEvent('orp:weed:client:plantNewSeed', src, 'purplehaze', 'weed_purple-haze_seed')
end)

RegisterServerEvent('orp:weed:server:saveWeedPlant')
AddEventHandler('orp:weed:server:saveWeedPlant', function(data, plantId)
    local data = json.encode(data)
    ORP.Functions.ExecuteSql(false, "INSERT INTO `weed_plants` (`properties`, `plantid`) VALUES ('" .. data .. "', '".. plantId .. "')")
end)

RegisterServerEvent('orp:weed:server:saveWeedDrying')
AddEventHandler('orp:weed:server:saveWeedDrying', function(data, plantId)
    local data = json.encode(data)
    ORP.Functions.ExecuteSql(false, "INSERT INTO `weed_drying` (`properties`, `plantid`) VALUES ('" .. data .. "', '".. plantId .. "')")
end)

RegisterServerEvent('orp:weed:server:giveShittySeed')
AddEventHandler('orp:weed:server:giveShittySeed', function()
    local src = source
    local Player = ORP.Functions.GetPlayer(source)
    Player.Functions.AddItem(Config.BadSeedReward, math.random(1, 2))
    TriggerClientEvent('inventory:client:ItemBox', source, ORP.Shared.Items[Config.BadSeedReward], "add")
end)

RegisterServerEvent('orp:weed:server:plantNewSeed')
AddEventHandler('orp:weed:server:plantNewSeed', function(type, location, seed)
    local src = source
    local plantId = math.random(111111, 999999)
    local Player = ORP.Functions.GetPlayer(src)
    local SeedData = {id = plantId, type = type, x = location.x, y = location.y, z = location.z, hunger = Config.StartingHunger, thirst = Config.StartingThirst, growth = 0.0, quality = 100.0, stage = 1, grace = true, beingHarvested = false, planter = Player.PlayerData.ssn}

    local PlantCount = 0

    for k, v in pairs(Config.Plants) do
        if v.planter == Player.PlayerData.ssn then
            PlantCount = PlantCount + 1
        end
    end

    if PlantCount >= Config.MaxPlantCount then
        TriggerClientEvent('orp:weed:client:notify', src, 'You already have ' .. Config.MaxPlantCount .. ' plants down')
    else
        Player.Functions.RemoveItem(seed, 1)
        table.insert(Config.Plants, SeedData)
        TriggerClientEvent('orp:weed:client:plantSeedConfirm', src)
        TriggerEvent('orp:weed:server:saveWeedPlant', SeedData, plantId)
        TriggerEvent('orp:weed:server:updatePlants')
    end
end)

RegisterServerEvent('orp:weed:server:dryNewWeed')
AddEventHandler('orp:weed:server:dryNewWeed', function(type, location, grade, item)
    local src = source
    local plantId = math.random(111111, 999999)
    local Player = ORP.Functions.GetPlayer(src)
    local SeedData = {id = plantId, type = type, x = location.x, y = location.y, z = location.z, growth = 0.0, beingHarvested = false, planter = Player.PlayerData.ssn, grade = grade}

    local PlantCount = 0

    for k, v in pairs(Config.PlantsDrying) do
        if v.planter == Player.PlayerData.ssn then
            PlantCount = PlantCount + 1
        end
    end

    if PlantCount >= Config.MaxPlantCount then
        TriggerClientEvent('orp:weed:client:notify', src, 'You are already drying ' .. Config.MaxPlantCount .. ' plants')
    else
        Player.Functions.RemoveItem(item, 1, function(result)
            if result then
                table.insert(Config.PlantsDrying, SeedData)
                TriggerClientEvent('orp:weed:client:plantSeedConfirm', src)
                TriggerEvent('orp:weed:server:saveWeedDrying', SeedData, plantId)
                TriggerEvent('orp:weed:server:updatePlants')
            end
        end)
    end
end)

RegisterServerEvent('orp:weed:plantHasBeenHarvested')
AddEventHandler('orp:weed:plantHasBeenHarvested', function(type, plantId)

    if type == 'drying' then
        for k, v in pairs(Config.PlantsDrying) do
            if v.id == plantId then
                v.beingHarvested = true
            end
        end
    else
        for k, v in pairs(Config.Plants) do
            if v.id == plantId then
                v.beingHarvested = true
            end
        end
    end

    TriggerEvent('orp:weed:server:updatePlants')
end)

RegisterServerEvent('orp:weed:plantHasNotBeenHarvested')
AddEventHandler('orp:weed:plantHasNotBeenHarvested', function(type, plantId)
    if type == "drying" then
        for k, v in pairs(Config.PlantsDrying) do
            if v.id == plantId then
                v.beingHarvested = false
            end
        end
    else
        for k, v in pairs(Config.Plants) do
            if v.id == plantId then
                v.beingHarvested = false
            end
        end
    end

    TriggerClientEvent('orp:weed:server:setAsNotDone', -1, plantId)
    TriggerEvent('orp:weed:server:updatePlants')
end)

RegisterServerEvent('orp:weed:destroyWeed')
AddEventHandler('orp:weed:destroyWeed', function(plantId)
    TriggerClientEvent('orp:weed:client:removeWeedObject', -1, plantId)
    TriggerEvent('orp:weed:server:weedPlantRemoved', 'plant', plantId)
    TriggerEvent('orp:weed:server:updatePlants')
end)

RegisterServerEvent('orp:weed:harvestPlant')
AddEventHandler('orp:weed:harvestPlant', function(plantId, bool)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    local amount, label, item
    local goodQuality = false
    local hasFound = false
    local returnGoodSeed = false
    local seedReturnType = nil
    local plantTable = 0

    for k,v in pairs(Config.Plants) do
        if v.id == plantId then
            for y = 1, #Config.PlantRewards do
                if v.type == Config.PlantRewards[y].type then
                    label = Config.PlantRewards[y].label
                    tempItem = Config.PlantRewards[y].item

                    local quality = math.ceil(v.quality)

                    hasFound = true

                    if v.type ~= "og_kush" then
                        returnGoodSeed = true
                        seedReturnType = Config.ReturnSeeds[v.type]
                    end

                    plantTable = k

                    if quality > 89 then
                        goodQuality = true
                        item = tempItem
                    else
                        item = 'low'..tempItem
                    end

                end
            end
        end
    end

    if hasFound then
        if Player.Functions.AddItem(item, 1) then
            if label ~= nil then
                TriggerClientEvent('orp:weed:client:notify', src, 'You harvest the ' .. label .. ' Plant')
            end
            TriggerClientEvent('orp:weed:client:removeWeedObject', -1, plantId)
            TriggerEvent('orp:weed:server:weedPlantRemoved', 'plant', plantId)
            TriggerEvent('orp:weed:server:updatePlants')
            TriggerClientEvent('inventory:client:ItemBox', source, ORP.Shared.Items[item], "add")
            table.remove(Config.Plants, plantTable)

            if goodQuality then
                if returnGoodSeed then
                    if math.random(1, 10) >= 8 then
                        local seedamount = math.random(1, 2)
                        if bool then seedamount = seedamount * 2 end
                        Player.Functions.AddItem(seedReturnType, seedamount)
                        TriggerClientEvent('inventory:client:ItemBox', source, ORP.Shared.Items[seedReturnType], "add")
                    else
                        local seedamount = 1
                        if bool then seedamount = seedamount * 2 end
                        Player.Functions.AddItem(seedReturnType, seedamount)
                        TriggerClientEvent('inventory:client:ItemBox', source, ORP.Shared.Items[seedReturnType], "add")
                    end
                else
                    if math.random(1, 2) == 2 then
                        local seedamount = math.random(1, 2)
                        if bool then seedamount = seedamount * 2 end
                        local seed = math.random(1, #Config.GoodSeedRewards)
                        Player.Functions.AddItem(Config.GoodSeedRewards[seed], seedamount)
                        TriggerClientEvent('inventory:client:ItemBox', source, ORP.Shared.Items[Config.GoodSeedRewards[seed]], "add")
                    end
                end

                if bool then
                    if math.random(1, 10) == 6 then
                        local seed = 'weed_blueberrykush_seed'
                        Player.Functions.AddItem(seed, 1)
                        TriggerClientEvent('inventory:client:ItemBox', source, ORP.Shared.Items[seed], "add")
                    end
                end
            else
                if math.random(1, 3) == 3 then
                    local seedamount = math.random(1, 2)
                    if bool then seedamount = seedamount * 2 end
                    Player.Functions.AddItem(Config.BadSeedReward, seedamount)
                    TriggerClientEvent('inventory:client:ItemBox', source, ORP.Shared.Items[Config.BadSeedReward], "add")
                end
            end
        else
            TriggerClientEvent('orp:weed:client:notify', src, 'You cannot carry anymore plants', 'error')
            TriggerClientEvent('orp:client:weed:removeFromHarvested', -1, plantId)
            TriggerEvent('orp:weed:plantHasNotBeenHarvested', 'plant', plantId)
        end
    end
end)

RegisterServerEvent('orp:weed:harvestWeed')
AddEventHandler('orp:weed:harvestWeed', function(plantId)
    local src = source
    local Player = ORP.Functions.GetPlayer(src)
    local amount
    local label
    local item
    local goodQuality = false
    local hasFound = false
    local returnGoodSeed = false
    local seedReturnType = nil
    local plantTable = 0

    for k, v in pairs(Config.PlantsDrying) do
        if v.id == plantId then
            YieldData = Config.YieldRewards[v.type]
            label = YieldData.label
            item = YieldData.item
            amount = math.random(YieldData.rewardMin, YieldData.rewardMax)

            plantTable = k

            if v.grade == "good" then
                goodQuality = true
                amount = math.ceil(amount)
            else
                amount = math.ceil(amount / 2)
            end

            amount = (amount * YieldData.multiplier)
        end
    end

    -- if hasFound then
        if Player.Functions.AddItem(item, amount) then
            if label ~= nil then
                TriggerClientEvent('orp:weed:client:notify', src, 'You harvest x' .. amount .. ' ' .. label)
            end
            TriggerClientEvent('orp:weed:client:removeWeedObjectDrying', -1, plantId)
            TriggerEvent('orp:weed:server:weedPlantRemoved', 'drying', plantId)
            TriggerEvent('orp:weed:server:updatePlants')
            TriggerClientEvent('inventory:client:ItemBox', source, ORP.Shared.Items[item], "add")
            table.remove(Config.PlantsDrying, plantTable)
        else
            -- Player.Functions.AddItem('empty_weed_bag', 1)
            TriggerClientEvent('orp:weed:client:notify', src, 'You cannot carry anymore weed', 'error')
            TriggerClientEvent('orp:client:weed:removeFromHarvested', -1, plantId)
            TriggerEvent('orp:weed:plantHasNotBeenHarvested', 'drying', plantId)
        end
    -- end
end)

RegisterServerEvent('orp:weed:server:updatePlants')
AddEventHandler('orp:weed:server:updatePlants', function()
    TriggerClientEvent('orp:weed:client:updateWeedData', -1, Config.Plants, Config.PlantsDrying)
end)

RegisterServerEvent('orp:weed:server:GetCurrentWeedData')
AddEventHandler('orp:weed:server:GetCurrentWeedData', function()
    TriggerClientEvent('orp:weed:client:updateWeedData', -1, Config.Plants, Config.PlantsDrying)
end)

RegisterServerEvent('orp:weed:server:waterPlant')
AddEventHandler('orp:weed:server:waterPlant', function(plantId)
    local src = source
    local Player = ORP.Functions.GetPlayer(source)

    for k, v in pairs(Config.Plants) do
        if v.id == plantId then
            Config.Plants[k].thirst = Config.Plants[k].thirst + Config.ThirstIncrease
            if Config.Plants[k].thirst > 100.0 then
                Config.Plants[k].thirst = 100.0
            end
        end
    end

    Player.Functions.RemoveItem('water', 1)
    Player.Functions.AddItem('emptybottle', 1)
    TriggerEvent('orp:weed:server:updatePlants')
end)

RegisterServerEvent('orp:weed:server:feedPlant')
AddEventHandler('orp:weed:server:feedPlant', function(plantId)
    local src = source
    local Player = ORP.Functions.GetPlayer(source)

    for k, v in pairs(Config.Plants) do
        if v.id == plantId then
            Config.Plants[k].hunger = Config.Plants[k].hunger + Config.HungerIncrease
            if Config.Plants[k].hunger > 100.0 then
                Config.Plants[k].hunger = 100.0
            end
        end
    end

    Player.Functions.RemoveItem('fertilizer', 1)
    TriggerEvent('orp:weed:server:updatePlants')
end)

RegisterServerEvent('orp:weed:server:updateWeedPlant')
AddEventHandler('orp:weed:server:updateWeedPlant', function(id, data)
    ORP.Functions.ExecuteSql(true, "SELECT * FROM `weed_plants` WHERE `plantid`= '" .. id .. "'", function(result)
        if result then
            local newData = json.encode(data)
            ORP.Functions.ExecuteSql(false, "UPDATE `weed_plants` SET `properties` = '" .. newData .. "' WHERE `plantid` = '" .. id .. "'")
        end
    end)
end)

RegisterServerEvent('orp:weed:server:updateWeedDryingPlant')
AddEventHandler('orp:weed:server:updateWeedDryingPlant', function(id, data)
    ORP.Functions.ExecuteSql(true, "SELECT * FROM `weed_drying` WHERE `plantid`= '" .. id .. "'", function(result)
        if result then
            local newData = json.encode(data)
            ORP.Functions.ExecuteSql(false, "UPDATE `weed_drying` SET `properties` = '" .. newData .. "' WHERE `plantid` = '" .. id .. "'")
        end
    end)
end)

RegisterServerEvent('orp:weed:server:weedPlantRemoved')
AddEventHandler('orp:weed:server:weedPlantRemoved', function(type, plantId)
    if type == "drying" then
        ORP.Functions.ExecuteSql(true, "SELECT * FROM `weed_drying`", function(result)
            if result then
                for i = 1, #result do
                    local plantData = json.decode(result[i].properties)
                    if plantData.id == plantId then
                        ORP.Functions.ExecuteSql(false, "DELETE FROM `weed_drying` WHERE `id` = '" .. result[i].id .. "'")
                        for k, v in pairs(Config.PlantsDrying) do
                            if v.id == plantId then
                                table.remove(Config.PlantsDrying, k)
                            end
                        end
                    end
                end
            end
        end)
    elseif type == "plant" then
        ORP.Functions.ExecuteSql(true, "SELECT * FROM `weed_plants`", function(result)
            if result then
                for i = 1, #result do
                    local plantData = json.decode(result[i].properties)
                    if plantData.id == plantId then
                        ORP.Functions.ExecuteSql(false, "DELETE FROM `weed_plants` WHERE `id` = '" .. result[i].id .. "'")
                        for k, v in pairs(Config.Plants) do
                            if v.id == plantId then
                                table.remove(Config.Plants, k)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

Thread(function()
    while true do
        Citizen.Wait(6 * (60 * 1000))
        -- Citizen.Wait(10000) -- testing
        for k,v in pairs(Config.Plants) do
            -- Citizen.Wait(50)
            if v.growth < 100 then
                if v.grace then
                    Config.Plants[k].grace = false
                else
                    Config.Plants[k].thirst = v.thirst - math.random(Config.Degrade.min, Config.Degrade.max) / 10
                    Config.Plants[k].hunger = v.hunger - math.random(Config.Degrade.min, Config.Degrade.max) / 10
                    Config.Plants[k].growth = v.growth + math.random(Config.GrowthIncrease.min, Config.GrowthIncrease.max) / 10

                    if v.growth > 100 then
                        Config.Plants[k].growth = 100
                    end

                    if v.hunger < 0 then
                        Config.Plants[k].hunger = 0
                    end

                    if v.thirst < 0 then
                        Config.Plants[k].thirst = 0
                    end

                    if v.quality < 25 then
                        Config.Plants[k].quality = 25
                    end

                    if v.thirst < 75 or v.hunger < 75 then
                        Config.Plants[k].quality = Config.Plants[k].quality - math.random(Config.QualityDegrade.min, Config.QualityDegrade.max) / 10
                    end

                    if v.stage == 1 and v.growth >= 55 then
                        Config.Plants[k].stage = 2
                    elseif v.stage == 2 and v.growth >= 90 then
                        Config.Plants[k].stage = 3
                    end
                end
            end
            TriggerEvent('orp:weed:server:updateWeedPlant', Config.Plants[k].id, Config.Plants[k])
        end

        for k,v in pairs(Config.PlantsDrying) do
            if v.growth < 100 then
                Config.PlantsDrying[k].growth = v.growth + math.random(30, 40) / 10

                if v.growth > 100 then
                    Config.PlantsDrying[k].growth = 100
                end
            end
            TriggerEvent('orp:weed:server:updateWeedDryingPlant', Config.PlantsDrying[k].id, Config.PlantsDrying[k])
        end
        TriggerEvent('orp:weed:server:updatePlants')
    end
end)
