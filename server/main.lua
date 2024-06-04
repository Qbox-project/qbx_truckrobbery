lib.locale()
local config = require 'config.server'
local sharedConfig = require 'config.shared'
local isMissionAvailable = true
local truck

RegisterNetEvent('qbx_truckrobbery:server:startMission', function()
    local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not isMissionAvailable then
		exports.qbx_core:Notify(src, locale('error.already_active'), 'error')
		return
	end
	if player.PlayerData.money.bank < config.activationCost then
		exports.qbx_core:Notify(src, locale('error.activation_cost', config.activationCost), 'error')
		return
	end

	local numCops = exports.qbx_core:GetDutyCountType('leo')
	if numCops < config.numRequiredPolice then
		exports.qbx_core:Notify(src, locale('error.active_police', config.numRequiredPolice), 'error')
		return
	end

	player.Functions.RemoveMoney('bank', config.activationCost, 'armored-truck')
	isMissionAvailable = false
    local coords = config.truckSpawns[math.random(1, #config.truckSpawns)]
	TriggerClientEvent('qbx_truckrobbery:client:missionStarted', src, coords)
	Wait(config.missionCooldown)
	isMissionAvailable = true
	truck = nil
    TriggerClientEvent('qbx_truckrobbery:client:missionEnded', -1)
end)

local function spawnGuardInSeat(seat, weapon)
	local coords = GetEntityCoords(truck)
	local guard = CreatePed(26, config.guardModel, coords.x, coords.y, coords.z, 0, true, false)
	lib.waitFor(function()
		if DoesEntityExist(guard) then
			return true
		end
	end, "guard does not exist")
	GiveWeaponToPed(guard, weapon, 250, false, true)
	for _ = 1, 50 do
		Wait(0)
		SetPedIntoVehicle(guard, truck, seat)

		if GetVehiclePedIsIn(guard, false) == truck then
			break
		end
	end
	Entity(guard).state:set('qbx_truckrobbery:initGuard', true, true)
	Wait(0)
end

lib.callback.register('qbx_truckrobbery:server:spawnVehicle', function(source, coords)
    local netId, veh = qbx.spawnVehicle({spawnSource = coords, model = config.truckModel})
	truck = veh
	SetVehicleDoorsLocked(truck, 2)
    local state = Entity(truck).state
    state:set('truckstate', TruckState.PLANTABLE, true)
    Wait(0)
	spawnGuardInSeat(-1, config.driverWeapon)
	spawnGuardInSeat(0, config.passengerWeapon)
	spawnGuardInSeat(1, config.backPassengerWeapon)
	spawnGuardInSeat(2, config.backPassengerWeapon)
	CreateThread(function()
		while NetworkGetEntityOwner(truck) ~= -1 do
			if isMissionAvailable or state.truckstate == TruckState.LOOTED then
				return
			end
			Wait(10000)
		end
		DeleteEntity(truck)
		exports.qbx_core:Notify(source, locale('error.truck_escaped'), 'error')
	end)
	CreateThread(function()
        local closestPlayer = nil
        while not closestPlayer do
            closestPlayer = lib.getClosestPlayer(GetEntityCoords(truck), 5)
			if isMissionAvailable or state.truckstate == TruckState.PLANTED then
				return
			end
			Wait(10000)
		end
		config.alertPolice(closestPlayer, coords)
	end)
	return netId
end)

RegisterNetEvent('qbx_truckrobbery:server:plantedBomb', function(source)
	if Entity(truck).state.truckstate ~= TruckState.PLANTABLE then return end
	if not exports.ox_inventory:RemoveItem(source, sharedConfig.bombItem, 1) then return end
    exports.qbx_core:Notify(source, locale('info.bomb_timer', config.timeToDetonation))
    Entity(truck).state:set('truckstate', TruckState.PLANTED, true)
	SetTimeout(config.timeToDetonation * 1000, function()
		SetVehicleDoorBroken(truck, 2, false)
		SetVehicleDoorBroken(truck, 3, false)
		ApplyForceToEntity(truck, 0, 20.0, 500.0, 0.0, 0.0, 0.0, 0.0, 1, false, true, true, false, true)
		Entity(truck).state:set('truckstate', TruckState.LOOTABLE, true)
	end)
end)

lib.callback.register('qbx_truckrobbery:server:giveReward', function(source)
	if Entity(truck).state.truckstate ~= TruckState.LOOTABLE then return end
	Entity(truck).state:set('truckstate', TruckState.LOOTED, true)
    local cantCarryRewards = {}
    local cantCarryRewardsSize = 0
    for i = 1, #config.rewards do
        local reward = config.rewards[i]
        if not reward.probability or math.random() <= reward.probability then
            local amount = math.random(reward.minAmount or 1, reward.maxAmount or 1)
            if exports.ox_inventory:CanCarryItem(source, reward.item, amount) then
                exports.ox_inventory:AddItem(source, reward.item, amount)
            else
                cantCarryRewardsSize += 1
                cantCarryRewards[cantCarryRewardsSize] = {reward.item, amount}
            end
        end
    end

    if cantCarryRewardsSize > 0 then
        exports.ox_inventory:CustomDrop('Loot', cantCarryRewards, GetEntityCoords(GetPlayerPed(source)))
    end
	exports.qbx_core:Notify(source, locale('success.looted'), 'success')
	return true
end)
