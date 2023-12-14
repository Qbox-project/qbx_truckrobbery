local config = require 'config.server'
local isMissionAvailable = true

lib.callback.register('qbx_truckrobbery:server:startMission', function(source)
	local player = exports.qbx_core:GetPlayer(source)
	if not isMissionAvailable then
		exports.qbx_core:Notify(source, Lang:t('error.already_active'), 'error')
		return
	end
	if player.PlayerData.money.bank < config.activationCost then
		exports.qbx_core:Notify(source, Lang:t('mission.activation_cost', {cost = config.activationCost}), 'inform')
		return
	end

	local numCops = exports.qbx_core:GetDutyCountType('leo')
	if numCops < config.numRequiredPolice then
		exports.qbx_core:Notify(source, Lang:t('error.active_police', {police = config.numRequiredPolice}), 'error')
		return
	end

	player.Functions.RemoveMoney('bank', config.activationCost, 'armored-truck')
	isMissionAvailable = false
	TriggerClientEvent('qbx_truckrobbery:client:missionStarted', source)
	Wait(config.missionCooldown)
	isMissionAvailable = true
	lib.callback('qbx_truckrobbery:client:resetMission', -1)
end)

lib.callback.register('qbx_truckrobbery:server:callCops', function(_, coords)
	local msg = Lang:t("info.alert_desc")
    local alertData = {
        title = Lang:t("info.alerttitle"),
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
		lib.callback('qbx_truckrobbery:client:notifyCop', copSrc, nil, msg, coords)
		TriggerClientEvent("qb-phone:client:addPoliceAlert", copSrc, alertData)
	end
end)

lib.callback.register('qbx_truckrobbery:server:giveReward', function(source)
	local player = exports.qbx_core:GetPlayer(source)
	local bags = math.random(1,3)
	local info = {
		worth = math.random(config.minReward, config.maxReward)
	}
	player.Functions.AddItem('markedbills', bags, false, info)
	exports.qbx_core:Notify(source, Lang:t('success.took_bags', {bags = bags}), 'success')
	if math.random() <= 0.05 then
		player.Functions.AddItem('security_card_01', 1)
	end
end)
