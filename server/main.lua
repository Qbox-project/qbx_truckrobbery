lib.locale()
local config = require 'config.server'
local clientConfig = require 'config.client'
local sharedConfig = require 'config.shared'
local isMissionAvailable = true
local truck
local missionOwner
local missionSource
local missionSpawn
local missionSequence = 0
local spawning = false
local truckState

local function isNear(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    return ped ~= 0 and #(GetEntityCoords(ped) - coords) <= maxDistance
end

local function isMissionOwner(source)
    if source ~= missionSource then return false end
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData.citizenid == missionOwner
end

local function endMission()
    isMissionAvailable = true
    if truck and DoesEntityExist(truck) then DeleteEntity(truck) end
    truck = nil
    truckState = nil
    spawning = false
    missionOwner = nil
    missionSource = nil
    missionSpawn = nil
    TriggerClientEvent('qbx_truckrobbery:client:missionEnded', -1)
end

RegisterNetEvent('qbx_truckrobbery:server:startMission', function()
    local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not player or player.PlayerData.job.type == 'leo' then return end
	if not isNear(src, clientConfig.dealerCoords.xyz, 5.0) then return end
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

	if not player.Functions.RemoveMoney('bank', config.activationCost, 'armored-truck') then return end
	isMissionAvailable = false
    local coords = config.truckSpawns[math.random(1, #config.truckSpawns)]
	missionSequence += 1
	local missionId = missionSequence
	missionOwner = player.PlayerData.citizenid
	missionSource = src
	missionSpawn = coords
	TriggerClientEvent('qbx_truckrobbery:client:missionStarted', src, coords)
	Wait(config.missionCooldown)
	if missionId == missionSequence then endMission() end
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

lib.callback.register('qbx_truckrobbery:server:spawnVehicle', function(source)
	if not isMissionOwner(source) or isMissionAvailable or truck or spawning or not missionSpawn then return end
	if not isNear(source, missionSpawn.xyz, 300.0) then return end

    spawning = true
    local missionId = missionSequence
    local success, netId, veh = pcall(qbx.spawnVehicle, {spawnSource = missionSpawn, model = config.truckModel})
    spawning = false
	if not success or not netId or not veh or veh == 0 then return end
    if missionId ~= missionSequence or isMissionAvailable then
        DeleteEntity(veh)
        return
    end
	truck = veh
	truckState = TruckState.PLANTABLE
	local spawnedTruck = veh
	SetVehicleDoorsLocked(truck, 2)
    local state = Entity(truck).state
    state:set('truckstate', TruckState.PLANTABLE, true)
    Wait(0)
	spawnGuardInSeat(-1, config.driverWeapon)
	spawnGuardInSeat(0, config.passengerWeapon)
	spawnGuardInSeat(1, config.backPassengerWeapon)
	spawnGuardInSeat(2, config.backPassengerWeapon)
	CreateThread(function()
		while DoesEntityExist(spawnedTruck) and NetworkGetEntityOwner(spawnedTruck) ~= -1 do
			if isMissionAvailable or state.truckstate == TruckState.LOOTED then
				return
			end
			Wait(10000)
		end
		DeleteEntity(spawnedTruck)
		exports.qbx_core:Notify(source, locale('error.truck_escaped'), 'error')
	end)
    CreateThread(function()
        local closestPlayer = nil
        while not closestPlayer do
			if not DoesEntityExist(spawnedTruck) or missionId ~= missionSequence then return end
            closestPlayer = lib.getClosestPlayer(GetEntityCoords(spawnedTruck), 5)
			if isMissionAvailable or state.truckstate == TruckState.PLANTED then
				return
			end
			Wait(10000)
		end
		config.alertPolice(closestPlayer, missionSpawn)
	end)
	return netId
end)

RegisterNetEvent('qbx_truckrobbery:server:plantedBomb', function()
	local source = source
	local player = exports.qbx_core:GetPlayer(source)
	if not player or player.PlayerData.job.type == 'leo' or not truck or not DoesEntityExist(truck) then return end
	if not isNear(source, GetEntityCoords(truck), 6.0) then return end
	if truckState ~= TruckState.PLANTABLE then return end
	if not exports.ox_inventory:RemoveItem(source, sharedConfig.bombItem, 1) then return end
    exports.qbx_core:Notify(source, locale('info.bomb_timer', config.timeToDetonation))
    Entity(truck).state:set('truckstate', TruckState.PLANTED, true)
	truckState = TruckState.PLANTED
	local missionTruck = truck
	local missionId = missionSequence
	SetTimeout(config.timeToDetonation * 1000, function()
		if missionId ~= missionSequence or not DoesEntityExist(missionTruck) or truckState ~= TruckState.PLANTED then return end
		SetVehicleDoorBroken(missionTruck, 2, false)
		SetVehicleDoorBroken(missionTruck, 3, false)
		ApplyForceToEntity(missionTruck, 0, 20.0, 500.0, 0.0, 0.0, 0.0, 0.0, 1, false, true, true, false, true)
		Entity(missionTruck).state:set('truckstate', TruckState.LOOTABLE, true)
		truckState = TruckState.LOOTABLE
	end)
end)

lib.callback.register('qbx_truckrobbery:server:giveReward', function(source)
	local player = exports.qbx_core:GetPlayer(source)
	if not player or player.PlayerData.job.type == 'leo' or not truck or not DoesEntityExist(truck) then return end
	if not isNear(source, GetEntityCoords(truck), 6.0) then return end
	if truckState ~= TruckState.LOOTABLE then return end
	truckState = TruckState.LOOTED
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

AddEventHandler('playerDropped', function()
    if source ~= missionSource then return end
    if truck and DoesEntityExist(truck) then return end
    missionSequence += 1
    endMission()
end)
