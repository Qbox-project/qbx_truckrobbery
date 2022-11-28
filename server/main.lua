local QBCore = exports['qb-core']:GetCoreObject()
local ActiveMission = 0

RegisterNetEvent('AttackTransport:akceptujto', function()
    local copsOnDuty = 0
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local accountMoney = Player.PlayerData.money.bank

    if ActiveMission == 0 then
        if accountMoney < Config.ActivationCost then
            TriggerClientEvent('QBCore:Notify', src, "You need $" .. Config.ActivationCost .. " in the bank to accept the mission")
        else
            for _, v in pairs(QBCore.Functions.GetPlayers()) do
                local Player = QBCore.Functions.GetPlayer(v)

                if Player ~= nil then
                    if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
                        copsOnDuty = copsOnDuty + 1
                    end
                end
            end

            if copsOnDuty >= Config.ActivePolice then
                TriggerClientEvent("AttackTransport:Pozwolwykonac", src)

                Player.Functions.RemoveMoney('bank', Config.ActivationCost, "armored-truck")

                OdpalTimer()
            else
                TriggerClientEvent('QBCore:Notify', src, 'Need at least ' .. Config.ActivePolice ..' SASP to activate the mission.')
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Someone is already carrying out this mission')
    end
end)

RegisterNetEvent('qb-armoredtruckheist:server:callCops', function(streetLabel, coords)
    TriggerClientEvent("qb-armoredtruckheist:client:robberyCall", -1, streetLabel, coords)
end)

function OdpalTimer()
    ActiveMission = 1

    Wait(Config.ResetTimer)

    ActiveMission = 0

    TriggerClientEvent('AttackTransport:CleanUp', -1)
end

RegisterNetEvent('AttackTransport:zawiadompsy', function(x ,y, z)
    TriggerClientEvent('AttackTransport:InfoForLspd', -1, x, y, z)
end)

RegisterNetEvent('AttackTransport:graczZrobilnapad', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local bags = math.random(1, 3)

    Player.Functions.AddItem('markedbills', bags, false, {
    worth = math.random(Config.cashA, Config.cashB)
    })

    local chance = math.random(1, 100)

    TriggerClientEvent('QBCore:Notify', src, 'You took ' .. bags .. ' bags of cash from the van')

    if chance >= 95 then
    Player.Functions.AddItem('security_card_01', 1)
    end

    Wait(2500)
end)