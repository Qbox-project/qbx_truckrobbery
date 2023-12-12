local config = require 'config.client'
local bowBackdoor = 0
local policeAlert = 0
local lootTime = 1
local guardsDead = false
local blownUp = 0
local truckBlip
local transport
local missionStart = 0
local warning = 0
local vehicleCoords = nil
local dealer
local pilot = nil
local navigator = nil

CreateThread(function()
    while true do
        Wait(2)
		local plyCoords = GetEntityCoords(cache.ped, false)
		local dist = #(plyCoords - vec3(config.missionMarker.x, config.missionMarker.y, config.missionMarker.z))

		if dist <= 50.0 and QBX.PlayerData.job.type == 'leo' then
		if not DoesEntityExist(dealer) then
				lib.requestModel(config.dealerModel)
				dealer = CreatePed(26, config.dealerModel, config.dealerModelCoords.x, config.dealerModelCoords.y, config.dealerModelCoords.z, 268.9422, false, false)
				SetEntityHeading(dealer, 1.8)
				SetBlockingOfNonTemporaryEvents(dealer, true)
				TaskStartScenarioInPlace(dealer, 'WORLD_HUMAN_AA_SMOKE', 0, false)
			end
			if missionStart == 0 and dist <= 2 then
				if config.useTarget then
					exports.ox_target:addLocalEntity(dealer, {
						name = 'dealer',
						label = Lang:t('mission.accept_mission_target'),
						icon = 'fas fa-circle-check',
						serverEvent = 'truckrobbery:AcceptMission',
						canInteract = function()
							if QBX.PlayerData.job.type == 'leo' then return false end
							return true
						end,
						distance = 3.0,
					})
				else
					DrawMarker(25, config.dealerModelCoords.x, config.dealerModelCoords.y, config.dealerModelCoords.z - 0.90, 0, 0, 0, 0, 0, 0, 1.301, 1.3001, 1.3001, 0, 205, 250, 200, 0, 0, 0, 0)
					if dist <= 1.5 then
						DrawText3D(Lang:t('mission.accept_mission'), config.dealerModelCoords)
						if IsControlJustPressed(0, 38) and dist <= 4.0 then
							TriggerServerEvent('truckrobbery:AcceptMission')
							Wait(500)
						end
					end
				end
			else
				exports.ox_target:removeLocalEntity(dealer, 'dealer')
			end
		elseif DoesEntityExist(dealer) then
			DeleteEntity(dealer)
		else
			Wait(1500)
		end
	end
end)

function CheckGuards()
	if IsPedDeadOrDying(pilot) and IsPedDeadOrDying(navigator) then
		guardsDead = true
	end
	Wait(500)
end

RegisterNetEvent('truckrobbery:client:911alert', function()
    if policeAlert == 0 then
        local transCoords = GetEntityCoords(transport)
        TriggerServerEvent('truckrobbery:server:callCops', transCoords)
        PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', false)
        policeAlert = 1
    end
end)

RegisterNetEvent('truckrobbery:client:robberyCall', function(msg, coords)
    PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
    exports.qbx_core:Notify(msg, 'police', 10000)

    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 487)
    SetBlipColour(blip, 4)
    SetBlipDisplay(blip, 4)
    SetBlipAlpha(blip, transG)
    SetBlipScale(blip, 1.2)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Lang:t('info.cop_blip'))
    EndTextCommandSetBlipName(blip)
    while transG ~= 0 do
        Wait(180 * 4)
        transG = transG - 1
        SetBlipAlpha(blip, transG)
        if transG == 0 then
            SetBlipSprite(blip, 2)
            RemoveBlip(blip)
            return
        end
    end
end)

function MissionNotification()
	Wait(2000)
	config.emailNotification()
	Wait(3000)
end

RegisterNetEvent('truckrobbery:StartMission', function()
	MissionNotification()
	ClearPedTasks(dealer)
	TaskWanderStandard(dealer, 10.0, 10)
	local drawCoord = math.random(1, #config.truckSpawns)
	vehicleCoords = config.truckSpawns[drawCoord]

	lib.requestModel(joaat(config.truckModel))

	ClearAreaOfVehicles(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 15.0, false, false, false, false, false)
	transport = CreateVehicle(joaat(config.truckModel), vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleCoords.w, true, true)
	SetEntityAsMissionEntity(transport)
	truckBlip = AddBlipForEntity(transport)
	SetBlipSprite(truckBlip, 67)
	SetBlipColour(truckBlip, 1)
	SetBlipFlashes(truckBlip, true)
	SetBlipRoute(truckBlip,  true)
	SetBlipRouteColour(truckBlip, config.routeColor)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(Lang:t('mission.stockade'))
	EndTextCommandSetBlipName(truckBlip)

	lib.requestModel(config.guardModel)

	pilot = CreatePed(26, config.guardModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 268.9422, true, false)
	navigator = CreatePed(26, config.guardModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 268.9422, true, false)
	SetPedIntoVehicle(pilot, transport, -1)
	SetPedIntoVehicle(navigator, transport, 0)
	SetPedFleeAttributes(pilot, 0, false)
	SetPedCombatAttributes(pilot, 46, true)
	SetPedCombatAbility(pilot, 100)
	SetPedCombatMovement(pilot, 2)
	SetPedCombatRange(pilot, 2)
	SetPedKeepTask(pilot, true)
	GiveWeaponToPed(pilot, config.driverWeapon,250,false,true)
	SetPedAsCop(pilot, true)

	SetPedFleeAttributes(navigator, 0, false)
	SetPedCombatAttributes(navigator, 46, true)
	SetPedCombatAbility(navigator, 100)
	SetPedCombatMovement(navigator, 2)
	SetPedCombatRange(navigator, 2)
	SetPedKeepTask(navigator, true)
	TaskEnterVehicle(navigator,transport, -1, 0, 1.0, 1)
	GiveWeaponToPed(navigator, config.passengerWeapon, 250, false, true)
	SetPedAsCop(navigator, true)

	TaskVehicleDriveWander(pilot, transport, 80.0, 536871867)
	TaskVehicleDriveWander(navigator, transport, 80.0, 536871867)
	missionStart = 1
end)

CreateThread(function()
    while true do
        Wait(5)
		if missionStart == 1 then
			local plyCoords = GetEntityCoords(cache.ped, false)
			local transCoords = GetEntityCoords(transport)
			local dist = #(plyCoords - transCoords)

			if dist <= 75.0 and QBX.PlayerData.job.type == 'leo' then
				DrawMarker(0, transCoords.x, transCoords.y, transCoords.z+4.5, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 135, 31, 35, 100, 1, 0, 0, 0)
				if warning == 0 then
					warning = 1
					exports.qbx_core:Notify(Lang:t('info.before_bomb'), 'error')
				end

				if not guardsDead then
					CheckGuards()
				elseif guardsDead and blownUp == 0 then
					TriggerEvent('truckrobbery:client:911alert')
				end
			else
				Wait(500)
			end

			if dist <= 7 and blownUp == 0  then
				if QBX.PlayerData.job.type == 'leo' then

					if guardsDead and blownUp == 0 then
						if config.useTarget then
							if bowBackdoor == 0 and guardsDead then
								exports.qbx_core:Notify(Lang:t('info.detonate_bomb_target'), 'inform')
								bowBackdoor = 1
							end
							exports.ox_target:addLocalEntity(transport, {
								name = 'transportPlant',
								label = Lang:t('info.plant_bomb'),
								icon = 'fas fa-bomb',
								canInteract = function()
									if QBX.PlayerData.job.type == 'leo' then return false end
									return true
								end,
								onSelect = function()
									if QBX.PlayerData.job.type == 'leo' then return false end
									CheckVehicleInformation()
									return true
								end,
								distance = 3.0,
							})
							Wait(500)
						else
							if bowBackdoor == 0 then
								exports.qbx_core:Notify(Lang:t('info.detonate_bomb'), 'inform')
								bowBackdoor = 1
							end
							if IsControlPressed(0, 47) and guardsDead then
								CheckVehicleInformation()
								Wait(500)
							end
						end
					end
				end
			end
		else
			Wait(1500)
		end
	end
end)

function CheckVehicleInformation()
	if not IsVehicleStopped(transport) then
		exports.qbx_core:Notify(Lang:t('error.truck_ismoving'), 'error')
		return
	end
	if not guardsDead then
		exports.qbx_core:Notify(Lang:t('error.guards_dead'), 'error')
		return
	end
	if IsEntityInWater(cache.ped) then
		exports.qbx_core:Notify(Lang:t('info.get_out_water'), 'error')
		return
	end
	if config.useTarget then
		exports.ox_target:removeLocalEntity(transport, 'transportPlant')
	end
	blownUp = 1
	SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`,true)
	Wait(500)

	if lib.progressBar({
		duration = 5000,
		label = Lang:t('info.planting_bomb'),
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = true,
			car = true,
			combat = true,
			mouse = false,
		},
		anim = {
			dict = 'anim@heists@ornate_bank@thermal_charge_heels',
			clip = 'thermal_charge',
			flag = 16,
		},
		prop = {
			model = `prop_c4_final_green`,
			pos = {
				x = 0.06,
				y = 0.0,
				z = 0.06,
			},
			rot = {
				x = 90.0,
				y = 0.0,
				z = 0.0,
			},
		}
	}) then
		local coords = GetEntityCoords(cache.ped)
		local prop = CreateObject(`prop_c4_final_green`, coords.x, coords.y, coords.z + 0.2,  true,  true, true)
		AttachEntityToEntity(prop, transport, GetEntityBoneIndexByName(transport, 'door_pside_r'), -0.7, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
		exports.qbx_core:Notify(Lang:t('info.bomb_timer', {TimeToBlow = config.timetoDetonation / 1000}), 'error')
		Wait(config.timetoDetonation)
		local transCoords = GetEntityCoords(transport)
		SetVehicleDoorBroken(transport, 2, false)
		SetVehicleDoorBroken(transport, 3, false)
		AddExplosion(transCoords.x,transCoords.y,transCoords.z, 'EXPLOSION_TANKER', 2.0, true, false, 2.0)
		ApplyForceToEntity(transport, 0, 20.0, 500.0, 0.0, 0.0, 0.0, 0.0, 1, false, true, true, false, true)

		exports.qbx_core:Notify(Lang:t('info.collect'), 'success')
		local plyCoords = GetEntityCoords(cache.ped, false)
		local transCoords = GetEntityCoords(transport)
		local dist = #(plyCoords - transCoords)

		if dist > 45.0 then
			Wait(500)
		end

		if config.useTarget then
			exports.ox_target:addLocalEntity(transport, {
				name = 'transportTake',
				label = Lang:t('info.take_money_target'),
				icon = 'fas fa-sack-dollar',
				canInteract = function()
					return QBX.PlayerData.job.type ~= 'leo'
				end,
				onSelect = TakingMoney,
				distance = 3.0,
			})
		else
			local point = lib.points.new({
				coords = GetEntityCoords(cache.ped),
				distance = 3.0,
			})

			function point:onEnter()
				if QBX.PlayerData.job.type ~= 'leo' then
					lib.showTextUI(Lang:t('info.take_money_target'))
				end
			end

			function point:onExit()
				lib.hideTextUI()
			end

			function point:nearby()
				if IsControlJustPressed(0, 38) and QBX.PlayerData.job.type ~= 'leo' then
					TakingMoney()
				end
			end
		end
	else
		blownUp = 0
	end
end

RegisterNetEvent('truckrobbery:CleanUp', function()
    pickupMoney = 0
    bowBackdoor = 0
    policeAlert = 0
    lootTime = 1
    guardsDead = false
    lootable = false
    blownUp = 0
    missionStart = 0
    warning = 0
    RemoveBlip(truckBlip)
	SetBlipRoute(truckBlip, false)
end)

function TakingMoney()
	if config.useTarget then
		exports.ox_target:removeLocalEntity(transport, 'transportTake')
	end
	exports.qbx_core:Notify(Lang:t('success.packing_cash'), 'success')
	local _time = GetGameTimer()

	if lib.progressBar({
		duration = 5000,
		label = Lang:t('info.grabing_money'),
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = true,
			car = true,
			combat = true,
			mouse = false,
		},
		anim = {
			dict = 'anim@heists@ornate_bank@grab_cash_heels',
			clip = 'grab',
			flag = 1,
		},
		prop = {
			model = `prop_cs_heist_bag_02`,
			bone = 57005,
			pos = {
				x = 0.0,
				y = 0.0,
				z = -0.16,
			},
			rot = {
				x = 250.0,
				y = -30.0,
				z = 0.0,
			},
		}
	}) then
		lootTime = GetGameTimer() - _time
		SetPedComponentVariation(cache.ped, 5, 45, 0, 2)
		TriggerServerEvent('truckrobbery:RobberySucess', lootTime)
		TriggerEvent('truckrobbery:CleanUp')
	end
end