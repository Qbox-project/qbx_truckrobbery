local config = require 'config.client'
local sharedConfig = require 'config.shared'
local truckBlip
local truck
local area
local missionStarted = false
local dealer, pilot, navigator
local c4Prop

AddEventHandler('onResourceStop', function(resource)
	if resource ~= cache.resource then return end
	exports.ox_target:removeLocalEntity(dealer)
	DeletePed(dealer)
end)

local function alertPolice()
	lib.callback('qbx_truckrobbery:server:callCops', false, nil, GetEntityCoords(truck))
	PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', false)
end

local function resetMission()
    missionStarted = false
    RemoveBlip(truckBlip)
    RemoveBlip(area)
end

lib.callback.register('qbx_truckrobbery:resetMission', resetMission)

local function lootTruck()
	if lib.progressBar({
		duration = 5000,
		label = locale('info.looting_truck'),
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
			pos = vec3(0.0, 0.0, -0.16),
			rot = vec3(250.0, -30.0, 0.0),
		}
	}) then
		local success = lib.callback.await('qbx_truckrobbery:server:giveReward')
		if not success then return end
		SetPedComponentVariation(cache.ped, 5, 45, 0, 2)
		resetMission()
	end
end

local function plantBomb()
	if not IsVehicleStopped(truck) then
		exports.qbx_core:Notify(locale('error.truck_moving'), 'error')
		return
	end
	if IsEntityInWater(cache.ped) then
		exports.qbx_core:Notify(locale('error.get_out_water'), 'error')
		return
	end
	local hasBomb = exports.ox_inventory:Search('count', sharedConfig.bombItem) > 0
	if not hasBomb then
		exports.qbx_core:Notify(locale('error.missing_bomb'), 'error')
		return
	end
	SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
	Wait(500)

	if lib.progressBar({
		duration = 5000,
		label = locale('info.planting_bomb'),
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
			pos = vec3(0.06, 0.0, 0.06),
			rot = vec3(90.0, 0.0, 0.0),
		}
	}) then
		if Entity(truck).state.truckstate ~= TruckState.PLANTABLE then return end
		lib.callback('qbx_truckrobbery:server:plantedBomb')
	end
end

RegisterNetEvent('qbx_truckrobbery:client:missionStarted', function()
	exports.qbx_core:Notify('Go to the designated location to find the bank truck')
	Wait(2000)
	config.emailNotification()
	Wait(3000)
	local vehicleSpawnCoords = config.truckSpawns[math.random(1, #config.truckSpawns)]

	lib.requestModel(config.truckModel)

	area = AddBlipForRadius(vehicleSpawnCoords.x, vehicleSpawnCoords.y, vehicleSpawnCoords.z, 450.0)
	SetBlipHighDetail(area, true)
	SetBlipAlpha(area, 90)
	SetBlipRoute(area, true)
	SetBlipRouteColour(area, config.routeColor)
	SetBlipColour(area, 1)

	ClearAreaOfVehicles(vehicleSpawnCoords.x, vehicleSpawnCoords.y, vehicleSpawnCoords.z, 15.0, false, false, false, false, false)
	local netId = lib.callback.await('qbx_truckrobbery:server:spawnVehicle', false, config.truckModel, vehicleSpawnCoords)
	lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
			truck = NetToVeh(netId)
            return truck
        end
    end, locale('no_truck_spawned'))

	exports.qbx_core:Notify(locale('info.truck_spotted'), 'inform')

	RemoveBlip(area)

	truckBlip = AddBlipForEntity(truck)
	SetBlipSprite(truckBlip, 67)
	SetBlipColour(truckBlip, 1)
	SetBlipFlashes(truckBlip, true)
	SetBlipRoute(truckBlip, true)
	SetBlipRouteColour(truckBlip, config.routeColor)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString('Armored Truck')
	EndTextCommandSetBlipName(truckBlip)
	lib.requestModel(config.guardModel, 5000)

	pilot = CreatePed(26, config.guardModel, vehicleSpawnCoords.x, vehicleSpawnCoords.y, vehicleSpawnCoords.z, 268.9422, true, false)
	navigator = CreatePed(26, config.guardModel, vehicleSpawnCoords.x, vehicleSpawnCoords.y, vehicleSpawnCoords.z, 268.9422, true, false)

	CreateThread(function()
		while true do
			if IsPedDeadOrDying(pilot) or IsPedDeadOrDying(navigator) then
				TriggerServerEvent('qbx_truckrobbery:server:guardKilled')
				alertPolice()
				return
			end
			Wait(1000)
		end
	end)

	SetPedIntoVehicle(pilot, truck, -1)
	SetPedIntoVehicle(navigator, truck, 0)
	SetPedFleeAttributes(pilot, 0, false)
	SetPedCombatAttributes(pilot, 46, true)
	SetPedCombatAbility(pilot, 100)
	SetPedCombatMovement(pilot, 2)
	SetPedCombatRange(pilot, 2)
	SetPedKeepTask(pilot, true)
	GiveWeaponToPed(pilot, config.driverWeapon, 250, false, true)
	SetPedAsCop(pilot, true)

	SetPedFleeAttributes(navigator, 0, false)
	SetPedCombatAttributes(navigator, 46, true)
	SetPedCombatAbility(navigator, 100)
	SetPedCombatMovement(navigator, 2)
	SetPedCombatRange(navigator, 2)
	SetPedKeepTask(navigator, true)
	TaskEnterVehicle(navigator,truck, -1, 0, 1.0, 1)
	GiveWeaponToPed(navigator, config.passengerWeapon, 250, false, true)
	SetPedAsCop(navigator, true)

	TaskVehicleDriveWander(pilot, truck, 80.0, 536871867)
	TaskVehicleDriveWander(navigator, truck, 80.0, 536871867)
	missionStarted = true
end)

qbx.entityStateHandler('truckstate', function(entity, _, value)
	lib.print.info("truckstate changed", value)
	if entity == 0 then return end
    truck = entity
    if value == TruckState.PLANTABLE then
        exports.ox_target:addLocalEntity(truck, {
            name = 'transportPlant',
            label = locale('info.plant_bomb'),
            icon = 'fas fa-bomb',
            canInteract = function()
                return QBX.PlayerData.job.type ~= 'leo'
            end,
            onSelect = plantBomb,
            distance = 3.0,
        })
    elseif value == TruckState.PLANTED then
        exports.ox_target:removeLocalEntity(truck, 'transportPlant')
		local coords = GetEntityCoords(cache.ped)
		c4Prop = CreateObject(`prop_c4_final_green`, coords.x, coords.y, coords.z + 0.2,  false, false, true)
		AttachEntityToEntity(c4Prop, truck, GetEntityBoneIndexByName(truck, 'door_pside_r'), -0.7, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
		while DoesEntityExist(c4Prop) do
			if not DoesEntityExist(truck) then
				DeleteObject(c4Prop)
				return
			end

			qbx.playAudio({
				audioName = 'IDLE_BEEP',
				audioRef = 'EPSILONISM_04_SOUNDSET',
				audioSource = c4Prop
			})
			Wait(1000)
		end
    elseif value == TruckState.LOOTABLE then
		if c4Prop and DoesEntityExist(c4Prop) then
			DeleteObject(c4Prop)
		end
		if Entity(truck).state.truckstate == TruckState.PLANTED then
			local transCoords = GetEntityCoords(truck)
			AddExplosion(transCoords.x,transCoords.y,transCoords.z, 'EXPLOSION_TANKER', 2.0, true, false, 2.0)
		end
        exports.ox_target:addLocalEntity(truck, {
			name = 'transportTake',
			label = locale('info.loot_truck'),
			icon = 'fas fa-sack-dollar',
			canInteract = function()
				return QBX.PlayerData.job.type ~= 'leo'
			end,
			onSelect = lootTruck,
			distance = 3.0,
		})
    elseif value == TruckState.LOOTED then
		exports.ox_target:removeLocalEntity(truck, 'transportTake')
    end
end)

lib.requestModel(config.dealerModel, 5000)
dealer = CreatePed(26, config.dealerModel, config.dealerCoords.x, config.dealerCoords.y, config.dealerCoords.z, config.dealerCoords.w, false, false)
TaskStartScenarioInPlace(dealer, 'WORLD_HUMAN_AA_SMOKE', 0, false)
SetEntityInvincible(dealer, true)
SetBlockingOfNonTemporaryEvents(dealer, true)
Wait(1000)
FreezeEntityPosition(dealer, true)

exports.ox_target:addLocalEntity(dealer, {
    name = 'dealer',
    label = locale('mission.ask_for_mission'),
    icon = 'fas fa-circle-check',
    canInteract = function()
        return not missionStarted and QBX.PlayerData.job.type ~= 'leo'
    end,
    onSelect = function()
        lib.callback('qbx_truckrobbery:server:startMission')
    end,
    distance = 3.0,
})
