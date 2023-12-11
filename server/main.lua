local numRequiredCops = 2  		--<< needed policemen to activate the mission
local minReward = 250 				--<<how much minimum you can get from a robbery
local maxReward = 450				--<< how much maximum you can get from a robbery
local activationCost = 500		--<< how much is the activation of the mission (clean from the bank)
local missionCooldown = 2700 * 1000  --<< timer every how many missions you can do, default is 600 seconds
local isMissionAvailable = true

RegisterServerEvent('AttackTransport:akceptujto', function()
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

	TriggerClientEvent('AttackTransport:Pozwolwykonac', src)
	player.Functions.RemoveMoney('bank', activationCost, 'armored-truck')
	isMissionAvailable = false
	Wait(missionCooldown)
	isMissionAvailable = true
	TriggerClientEvent('AttackTransport:CleanUp', -1)
end)

RegisterServerEvent('qb-armoredtruckheist:server:callCops', function(streetLabel, coords)
    TriggerClientEvent('qb-armoredtruckheist:client:robberyCall', -1, streetLabel, coords)
end)

RegisterServerEvent('AttackTransport:zawiadompsy', function(x ,y, z)
    TriggerClientEvent('AttackTransport:InfoForLspd', -1, x, y, z)
end)

RegisterServerEvent('AttackTransport:graczZrobilnapad', function()
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
