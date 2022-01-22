local open = false
local main = RageUI.CreateMenu("JobCenter", "~b~Pole emploie")
main.Closed = function()
    open = false
end

Citizen.CreateThread(function()
    while true do
        local pPed = GetPlayerPed(-1)
        local pCoords = GetEntityCoords(pPed)
        local pNear = false

        if GetDistanceBetweenCoords(pCoords, jobCenter, true) < 3.0 then
            pNear = true
            Visual.FloatingHelpText("Appuyer sur ~INPUT_PICKUP~ pour ouvrir le job center", false, false)
            if IsControlJustReleased(1, 38) then
                OpenJobCenterMenu()
            end
        end

        if pNear then
            Wait(1)
        else
            Wait(500)
        end
    end
end)



function OpenJobCenterMenu()
    if open then
        open = false
        return
    else
        open = true
        RageUI.Visible(main, true)


        Citizen.CreateThread(function()
            while open do
                RageUI.IsVisible(main, function()
                    RageUI.Separator("> Choisir un job <")
                    for k,v in pairs(jobs) do
                        RageUI.Button(v.label, v.description, {}, true, {
                            onSelected = function()
                                -- Set waypoint + notif
                                if not v.fullTimeJob then
                                    SetNewWaypoint(v.job.vestiaire.x, v.job.vestiaire.y)
                                    TriggerEvent("FeedM:showNotification", "Votre GPS a été mis à jours vers le véstiaire ~o~"..v.label.."~s~!\nRendez-vous sur le point!", 5000, "success")
                                else
                                    TriggerServerEvent("fr_jobs:SetJob", v.jobname)
                                    TriggerEvent("FeedM:showNotification", "Votre job à été mis à jours!", 5000, "success")
                                end
                            end,
                        });
                    end
                end)
                Wait(1)
            end
        end)
    end
end