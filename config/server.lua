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
        vec4(-281.05, -617.55, 33.35, 276.51), -- Daily Globe International
        vec4(2.55, -671.9, 32.34, 181.81), -- Union Depository (1)
        vec4(-19.54, -672.65, 32.34, 183.36), -- Union Depository (2)
        vec4(-34.64, -674.35, 32.34, 177.9), -- Union Depository (3)
        vec4(147.24, -1081.15, 29.19, 1.6), -- Legion Square Bank
        vec4(-1187.67, -321.86, 37.61, 22.79), -- Rockford Hills Bank
        vec4(276.2, -172.81, 60.54, 70.45), -- Parking garage near Hawick Bank
        vec4(255.49, 278.25, 105.59, 67.0), -- Behind Pacific Bank
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