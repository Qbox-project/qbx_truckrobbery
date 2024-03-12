return {
    numRequiredPolice = 2, -- Minimum required police to activate mission
    activationCost = 500, -- How much is the activation of the mission (clean from the bank)
    missionCooldown = 2700 * 1000, -- Timer every how many missions you can do, default is 600 seconds

    ---@class Reward
    ---@field item string
    ---@field minAmount? integer default 1
    ---@field maxAmount? integer default 1
    ---@field probability? number 0.0 to 1.0, the independent probability of the reward being present. Defaults to 1.0

    ---@type Reward[]
    rewards = {
        {
            item = 'black_money',
            minAmount = 250,
            maxAmount = 450,
        },
        {
            item = 'security_card_01',
            probability = 0.05
        }
    },
    timeToDetonation = 30, -- Time in seconds till bomb detonation after placement
    driverWeapon = `WEAPON_COMBATPISTOL`, -- Weapon of the driver
    passengerWeapon = `WEAPON_COMBATSHOTGUN`, -- Weapon of the passenger
    backPassengerWeapon = `WEAPON_TACTICALRIFLE`,
    truckModel = `Stockade`, -- Model of the truck
    guardModel = `s_m_m_security_01`, -- Model of the guard

    truckSpawns = { -- Possible truck spawn locations
        vec4(-1201.8, -370.18, 37.29, 27.79),
        vec4(-2036.59, -259.78, 23.39, 136.92),
        vec4(-1292.28, -807.36, 17.19, 308.12),
        vec4(1072.27, -1950.67, 30.62, 144.03),
        vec4(1001.3, -55.03, 74.57, 117.98),
        vec4(-4.7, -669.71, 32.34, 176.32),
    },

    alertPolice = function(src, coords)
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
    end
}