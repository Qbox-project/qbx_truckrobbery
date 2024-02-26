local config = require 'config.server'
local sharedConfig = require 'config.shared'
local isMissionAvailable = true

lib.callback.register('qbx_truckrobbery:server:startMission', function(source)
	local player = exports.qbx_core:GetPlayer(source)
	if not isMissionAvailable then
		exports.qbx_core:Notify(source, locale('error.already_active'), 'error')
		return
	end
	if player.PlayerData.money.bank < config.activationCost then
		exports.qbx_core:Notify(source, locale('error.activation_cost', config.activationCost), 'error')
		return
	end

	local numCops = exports.qbx_core:GetDutyCountType('leo')
	if numCops < config.numRequiredPolice then
		exports.qbx_core:Notify(source, locale('error.active_police', config.numRequiredPolice), 'error')
		return
	end

	player.Functions.RemoveMoney('bank', config.activationCost, 'armored-truck')
	isMissionAvailable = false
	TriggerClientEvent('qbx_truckrobbery:client:missionStarted', source)
	Wait(config.missionCooldown)
	isMissionAvailable = true
	lib.callback('qbx_truckrobbery:client:resetMission', -1)
end)

lib.callback.register('qbx_truckrobbery:server:spawnVehicle', function(_, model, coords)
    local netId = qbx.spawnVehicle({spawnSource = coords, model = model})
    local veh = NetworkGetEntityFromNetworkId(netId)
    Entity(veh).state:set('truckstate', TruckState.DEFAULT, true)
	return netId
end)

lib.callback.register('qbx_truckrobbery:server:callCops', function(_, coords)
	local msg = locale("info.alert_desc")
    local alertData = {
        title = locale('info.alert_title'),
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        description = msg
    }
	local numCops, copSrcs = exports.qbx_core:GetDutyCountType('leo')
	for i = 1, numCops do
		local copSrc = copSrcs[i]
		TriggerClientEvent('police:client:policeAlert', copSrc, coords, msg)
		TriggerClientEvent('qb-phone:client:addPoliceAlert', copSrc, alertData)
	end
end)

lib.callback.register('qbx_truckrobbery:server:plantedBomb', function(source)
	return exports.ox_inventory:RemoveItem(source, sharedConfig.bombItem, 1)
end)

lib.callback.register('qbx_truckrobbery:server:giveReward', function(source)
    for i = 1, #config.rewards do
        local reward = config.rewards[i]
        if not reward.probability or math.random() <= reward.probability then
            local amount = math.random(reward.minAmount or 1, reward.maxAmount or 1)
            exports.ox_inventory:AddItem(source, reward.item, amount)
        end
    end
	exports.qbx_core:Notify(source, locale('success.looted'), 'success')
end)
