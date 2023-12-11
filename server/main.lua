local config = require 'config.server'
local isMissionAvailable = true

RegisterServerEvent('truckrobbery:AcceptMission', function()
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not isMissionAvailable then
		exports.qbx_core:Notify(src, Lang:t('error.already_active'), 'error')
		return
	end
	if player.PlayerData.money.bank < config.activationCost then
		exports.qbx_core:Notify(src, Lang:t('mission.activation_cost', {cost = config.activationCost}), 'inform')
		return
	end

	local numCops = exports.qbx_core:GetDutyCountType('leo')
	if numCops < config.numRequiredPolice then
		exports.qbx_core:Notify(src, Lang:t('error.active_police', {police = config.numRequiredPolice}), 'error')
		return
	end

	TriggerClientEvent("truckrobbery:StartMission", src)
	player.Functions.RemoveMoney('bank', config.activationCost, 'armored-truck')
	isMissionAvailable = false
	Wait(config.missionCooldown)
	isMissionAvailable = true
	TriggerClientEvent('truckrobbery:CleanUp', -1)
end)

RegisterNetEvent('truckrobbery:server:callCops', function(coords)
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
		TriggerClientEvent("truckrobbery:client:robberyCall", copSrc, msg, coords)
		TriggerClientEvent("qb-phone:client:addPoliceAlert", copSrc, alertData)
	end
end)

RegisterServerEvent('truckrobbery:RobberySucess', function()
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local bags = math.random(1,3)
	local info = {
		worth = math.random(config.minReward, config.maxReward)
	}
	player.Functions.AddItem('markedbills', bags, false, info)
	exports.qbx_core:Notify(src, Lang:t('success.took_bags', {bags = bags}), 'success')
	if math.random() <= 0.05 then
		player.Functions.AddItem('security_card_01', 1)
	end
end)
