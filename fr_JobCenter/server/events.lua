ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterNetEvent("fr_job:GetJobItem")
AddEventHandler("fr_job:GetJobItem", function(item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local itemInfo = xPlayer.getInventoryItem(item)
    if itemInfo.limit ~= -1 and (itemInfo.count + 1) < itemInfo.limit then
        xPlayer.addInventoryItem(item, 1)
    else
        TriggerClientEvent("FeedM:showNotification", source, "Attention! Tu n'a pas assez de place!", 3000, "danger")
    end
end)


RegisterNetEvent("fr_job:ExchangeItem")
AddEventHandler("fr_job:ExchangeItem", function(item, item2)
    local xPlayer = ESX.GetPlayerFromId(source)
    local itemInfo = xPlayer.getInventoryItem(item)
    local itemInfo2 = xPlayer.getInventoryItem(item2)

    if itemInfo.count <= 0 then
        TriggerClientEvent("FeedM:showNotification", source, "Attention! Tu n'a pas assez d'objets!", 3000, "danger")
        return
    end

    if itemInfo2.limit ~= -1 and (itemInfo2.count + 1) < itemInfo2.limit then
        xPlayer.removeInventoryItem(item, 1)
        xPlayer.addInventoryItem(item2, 1)
    else
        TriggerClientEvent("FeedM:showNotification", source, "Attention! Tu n'a pas assez de place!", 3000, "danger")
        return
    end
end)


RegisterNetEvent("fr_job:SellItem")
AddEventHandler("fr_job:SellItem", function(item, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    local itemInfo = xPlayer.getInventoryItem(item)

    if itemInfo.count > 0 then
        xPlayer.removeInventoryItem(item, 1)
        xPlayer.addMoney(price)
    else
        TriggerClientEvent("FeedM:showNotification", source, "Attention! Tu n'a pas assez d'objets!", 3000, "danger")
        return
    end
end)


RegisterNetEvent("fr_jobs:SetJob")
AddEventHandler("fr_jobs:SetJob", function(job)
    local xPlayer = ESX.GetPlayerFromId(source)
    for k,v in pairs(jobs) do
        if v.fullTimeJob then
            if v.jobname == job then
                xPlayer.setJob(job, 0)
                return
            end
        end
    end

    -- If job not found, they add AC detection
end)