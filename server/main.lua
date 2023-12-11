--- TODO: integrate with config and locales

local numRequiredCops = 2  		--<< needed policemen to activate the mission
local minReward = 250 				--<<how much minimum you can get from a robbery
local maxReward = 450				--<< how much maximum you can get from a robbery
local activationCost = 500		--<< how much is the activation of the mission (clean from the bank)
local missionCooldown = 2700 * 1000  --<< timer every how many missions you can do, default is 600 seconds
local isMissionAvailable = true

RegisterServerEvent('truckrobbery:AcceptMission', function()
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not isMissionAvailable then
		exports.qbx_core:Notify(src, 'Someone is already carrying out this mission')
		return
	end
	if player.PlayerData.money.bank < activationCost then
		exports.qbx_core:Notify( src, 'You need $'..activationCost..' in the bank to accept the mission')
		return
	end

	local numCops = exports.qbx_core:GetDutyCountType('leo')
	if numCops < numRequiredCops then
		exports.qbx_core:Notify(src, 'Need at least '..numRequiredCops.. ' SASP to activate the mission.')
		return
	end

	TriggerClientEvent("truckrobbery:StartMission", src)
	player.Functions.RemoveMoney('bank', activationCost, 'armored-truck')
	isMissionAvailable = false
	Wait(missionCooldown)
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
		worth = math.random(minReward, maxReward)
	}
	player.Functions.AddItem('markedbills', bags, false, info)
	exports.qbx_core:Notify(src, 'You took '..bags..' bags of cash from the van')
	if math.random() <= 0.05 then
		player.Functions.AddItem('security_card_01', 1)
	end
end)
