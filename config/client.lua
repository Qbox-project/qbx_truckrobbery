return {
    dealerCoords = vec4(960.78, -216.25, 75.25, 1.8), -- place where the NPC stands

    truckSpawns = { -- Possible truck spawn locations
        vec4(-1201.8, -370.18, 37.29, 27.79),
        vec4(-2036.59, -259.78, 23.39, 136.92),
        vec4(-1292.28, -807.36, 17.19, 308.12),
        vec4(1072.27, -1950.67, 30.62, 144.03),
        vec4(1001.3, -55.03, 74.57, 117.98),
        vec4(-4.7, -669.71, 32.34, 176.32),
    },

    routeColor = 6, -- Color of the route

    driverWeapon = `WEAPON_COMBATPISTOL`, -- Weapon of the driver
    passengerWeapon = `WEAPON_COMBATPISTOL`, -- Weapon of the passenger
    truckModel = `Stockade`, -- Model of the truck
    dealerModel = `s_m_y_dealer_01`, -- Model of the NPC that gives the mission
    guardModel = `s_m_m_security_01`, -- Model of the guard

    timeToDetonation = 30, -- Time in seconds till bomb detonation after placement

    -- Used for mission notification
    emailNotification = function()
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = locale('mission.sender'),
            subject = locale('mission.subject'),
            message = locale('mission.message'),
        })
    end,
}
