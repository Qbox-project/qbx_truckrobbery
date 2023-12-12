local config = require 'config.client'
local policeAlert = 0
local guardsDead = false
local truckBlip
local transport
local missionStarted = false
local vehicleCoords = nil
local dealer
local pilot = nil
local navigator = nil

AddEventHandler('onResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	lib.requestModel(config.dealerModel)
	dealer = CreatePed(26, config.dealerModel, config.dealerModelCoords.x, config.dealerModelCoords.y, config.dealerModelCoords.z, 268.9422, false, false)
	SetEntityHeading(dealer, 1.8)
	SetBlockingOfNonTemporaryEvents(dealer, true)
	TaskStartScenarioInPlace(dealer, 'WORLD_HUMAN_AA_SMOKE', 0, false)

	exports.ox_target:addLocalEntity(dealer, {
		name = 'dealer',
		label = Lang:t('mission.accept_mission_target'),
		icon = 'fas fa-circle-check',
		serverEvent = 'truckrobbery:AcceptMission',
		canInteract = function()
			return not missionStarted and QBX.PlayerData.job.type ~= 'leo'
		end,
		distance = 3.0,
	})
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	exports.ox_target:removeLocalEntity(dealer)
	DeletePed(dealer)
end)

local function callCops()
    if policeAlert == 0 then
        local transCoords = GetEntityCoords(transport)
        TriggerServerEvent('truckrobbery:server:callCops', transCoords)
        PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', false)
        policeAlert = 1
    end
end

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

local function createBombPlantingTarget()
	exports.ox_target:addLocalEntity(transport, {
		name = 'transportPlant',
		label = Lang:t('info.plant_bomb'),
		icon = 'fas fa-bomb',
		canInteract = function()
			return QBX.PlayerData.job.type ~= 'leo'
		end,
		onSelect = PlantBomb,
		distance = 3.0,
	})
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
	missionStarted = true
	createBombPlantingTarget()
end)

CreateThread(function()
	if IsPedDeadOrDying(pilot) and IsPedDeadOrDying(navigator) then
		guardsDead = true
		callCops()
	end
	Wait(1000)
end)

function PlantBomb()
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
	exports.ox_target:removeLocalEntity(transport, 'transportPlant')
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
		exports.ox_target:removeLocalEntity(transport, 'transportPlant')
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
		--- TODO: seems like these targets should be added for all players instead of just the bomb planter
		exports.ox_target:addLocalEntity(transport, {
			name = 'transportTake',
			label = Lang:t('info.take_money_target'),
			icon = 'fas fa-sack-dollar',
			canInteract = function()
				return QBX.PlayerData.job.type ~= 'leo'
			end,
			onSelect = GrabMoney,
			distance = 3.0,
		})
	end
end

RegisterNetEvent('truckrobbery:CleanUp', function()
    pickupMoney = 0
    policeAlert = 0
    guardsDead = false
    lootable = false
    missionStarted = false
    RemoveBlip(truckBlip)
	SetBlipRoute(truckBlip, false)
end)

function GrabMoney()
	exports.qbx_core:Notify(Lang:t('success.packing_cash'), 'success')

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
		exports.ox_target:removeLocalEntity(transport, 'transportTake')
		SetPedComponentVariation(cache.ped, 5, 45, 0, 2)
		TriggerServerEvent('truckrobbery:RobberySucess')
		TriggerEvent('truckrobbery:CleanUp')
	end
end