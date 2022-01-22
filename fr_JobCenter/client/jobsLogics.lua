local open = falses
local working = false
local WorkBlips = {}
local ESX = nil
Citizen.CreateThread(function()
	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end)

function LoadJobsBlips()

    local blip = AddBlipForCoord(jobCenter)

    SetBlipSprite(blip, 109)
    SetBlipScale(blip, 0.85)
    SetBlipColour(blip, 57)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName("Job Center - Job civil")
    EndTextCommandSetBlipName(blip)  

    for k,v in pairs(jobs) do
        if not v.fullTimeJob then
		    local blip = AddBlipForCoord(v.job.vestiaire)

		    SetBlipSprite(blip, v.blipsSetting.sprite)
		    SetBlipScale(blip, v.blipsSetting.scale)
		    SetBlipColour(blip, v.blipsSetting.color)
		    SetBlipAsShortRange(blip, true)

		    BeginTextCommandSetBlipName('STRING')
		    AddTextComponentSubstringPlayerName(v.blipsSetting.name)
            EndTextCommandSetBlipName(blip)  
        end
    end
end

function LoadWorkBlips(zones, veh)
    for k,v in pairs(zones) do
		local blip = AddBlipForCoord(v.pos)

		SetBlipSprite(blip, 171)
		SetBlipScale(blip, 0.60)
		SetBlipColour(blip, 47)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(v.label)
        EndTextCommandSetBlipName(blip)  
        table.insert(WorkBlips, blip)   
    end

		local blip = AddBlipForCoord(veh.pos)

		SetBlipSprite(blip, 171)
		SetBlipScale(blip, 0.60)
		SetBlipColour(blip, 47)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName("Sortie de véhicule")
        EndTextCommandSetBlipName(blip)  
        table.insert(WorkBlips, blip)   
end

function UnloadWorkBlips()
    for k,v in pairs(WorkBlips) do
        RemoveBlip(v)
    end
    WorkBlips = {}
end


Citizen.CreateThread(function()
    LoadJobsBlips()
    while true do
        local pPed = GetPlayerPed(-1)
        local pCoords = GetEntityCoords(pPed)
        local pNear = false

        for k,v in pairs(jobs) do
            if not v.fullTimeJob then
                if #(v.job.vestiaire - pCoords) < 3.0 then
                    Visual.FloatingHelpText("Appuyer sur ~INPUT_PICKUP~ pour ouvrir le véstiaire de travail (~o~"..v.label.."~s~)", false, false)
                    pNear = true
                    if IsControlJustReleased(1, 38) then
                        OpenJobVestiaireMenu(v)
                    end
                end
            end
        end

        if pNear then
            Wait(1)
        else
            Wait(500)
        end
    end
end)

local main = RageUI.CreateMenu("Véstiaire", "~bVéstiaire de travaille")
main.Closed = function()
    open = false
end


function OpenJobVestiaireMenu(self)
    if open then
        open = false
        return
    else
        open = true
        RageUI.Visible(main, true)


        Citizen.CreateThread(function()
            while open do
                RageUI.IsVisible(main, function()
                    RageUI.Separator("> "..self.label.." <")
                    if not working then
                        RageUI.Button('Commencer le travail', self.description, {}, true, {
                            onSelected = function()
                                working = true
                                StartJobLogics(self)
                                LoadWorkBlips(self.job.farm, self.job.veh)
                                LoadWorkCloth(self.job.workCloth)
                                -- Need to to start job logics here
                                TriggerEvent("FeedM:showNotification", "Vous commencez à travailler!", 5000, "warning")
                            end,
                        })
                    else
                        RageUI.Button('Stopper le travail', nil, {}, true, {
                            onSelected = function()
                                working = false
                                TriggerEvent("FeedM:showNotification", "Vous avez terminé de travailler. Revenez quand vous voulez!", 5000, "warning")
                                UnloadWorkBlips()
                                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                                    TriggerEvent('skinchanger:loadSkin', skin)
                                end)
                            end,
                        })
                    end
        
                end)
                Wait(1)
            end
        end)
    end
end



function StartJobLogics(self)
    local pPed = GetPlayerPed(-1)
    local pCoords = GetEntityCoords(pPed)

    local function SpawnJobVehicle(model, pos, heading, inVeh)
        if inVeh then
            DeleteEntity(GetVehiclePedIsIn(GetPlayerPed(-1), false))
            return
        end
        RequestModel(GetHashKey(model))
        while not HasModelLoaded(GetHashKey(model)) do Wait(1) end

        if ESX.Game.IsSpawnPointClear(pos, 5.0) then
            -- Will need to check if no vehicle are here befor spawning veh, will do that later
            local veh = CreateVehicle(GetHashKey(model), pos, heading, true, false)
            SetEntityAsMissionEntity(veh, 1, 1)
            TaskWarpPedIntoVehicle(pPed, veh, -1)
        else
            TriggerEvent("FeedM:showNotification", "Il n'y a pas la place!", 5000, "warning")
        end
    end

    local inAction = false
    local function StartJobAction(action)
        inAction = true
        Citizen.CreateThread(function()
            local count = 0
            while inAction do
                if action.type == 1 then -- récolte
                    count = count + 1
                    if count == 200 then
                        count = 0
                        TriggerServerEvent("fr_job:GetJobItem", action.item)
                    end
                elseif action.type == 2 then
                    count = count + 1
                    if count == 100 then
                        count = 0
                        TriggerServerEvent("fr_job:ExchangeItem", action.itemToExange, action.item)
                    end
                elseif action.type == 3 then
                    count = count + 1
                    if count == 100 then
                        count = 0
                        TriggerServerEvent("fr_job:SellItem", action.item, action.price)
                    end
                end

                Wait(0)
            end
        end)

        Citizen.CreateThread(function()
            while inAction do
                if GetDistanceBetweenCoords(pCoords, action.pos, true) > 3.0 then
                    inAction = false
                    TriggerEvent("FeedM:showNotification", "Vous avez quitté la zone de travail", 5000, "warning")
                end
                Wait(100)
            end
        end)
    end


    Citizen.CreateThread(function()
        while working do
            pPed = GetPlayerPed(-1)
            pCoords = GetEntityCoords(pPed)
            Wait(300)
        end
    end)


    Citizen.CreateThread(function()
        while working do
            local pNear = false

            local dst = GetDistanceBetweenCoords(pCoords, self.job.veh.pos, true)
            if dst < 50.0 then
                pNear = true
                -- marker
                DrawMarker(36, self.job.veh.pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 208, 0, 200, 0, 1, 2, 0, nil, nil, 0)
                if dst < 3.0 then
                    -- Help text
                    if not IsPedInAnyVehicle(pPed, false) then
                        Visual.FloatingHelpText("Appuyer sur ~INPUT_PICKUP~ pour sortir le véhicule de travail (~o~"..self.job.veh.type.."~s~)", false, false)
                        if IsControlJustReleased(1, 38) then
                            SpawnJobVehicle(self.job.veh.type, self.job.veh.pos, self.job.veh.heading, false)
                        end
                    else
                        Visual.FloatingHelpText("Appuyer sur ~INPUT_PICKUP~ pour ranger le véhicule de travail", false, false)
                        if IsControlJustReleased(1, 38) then
                            SpawnJobVehicle(self.job.veh.type, self.job.veh.pos, self.job.veh.heading, true)
                        end
                    end
                end
            end


            if pNear then 
                Wait(1)
            else
                Wait(500)
            end
        end
    end)

    Citizen.CreateThread(function()
        while working do
            local pNear = false

            for k,v in pairs(self.job.farm) do
                local dst = GetDistanceBetweenCoords(pCoords, v.pos, true)
                if dst < 50.0 then
                    pNear = true
                    -- marker
                    DrawMarker(25, v.pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 3.0, 255, 208, 0, 200, 0, 1, 2, 0, nil, nil, 0)
                    if dst < 3.0 then
                        -- Info text
                        if not inAction then
                            Visual.FloatingHelpText("Appuyer sur ~INPUT_PICKUP~ pour utiliser le/la ~o~"..v.label, false, false)
                        else
                            Visual.FloatingHelpText("Appuyer sur ~INPUT_PICKUP~ pour stopper le travail")
                        end

                        if IsControlJustReleased(1, 38) then
                            if not inAction then
                                StartJobAction(v)
                            else
                                inAction = false
                            end
                        end
                    end

                    break
                end
            end


            if pNear then 
                Wait(1)
            else
                Wait(500)
            end
        end
    end)
end


function LoadWorkCloth(cloths)
    TriggerEvent('skinchanger:getSkin', function(skin)
		local uniformObject

		if skin.sex == 0 then
			uniformObject = cloths.male
		else
			uniformObject = cloths.female
		end

		if uniformObject then
			TriggerEvent('skinchanger:loadClothes', skin, uniformObject)
		end
	end)
end