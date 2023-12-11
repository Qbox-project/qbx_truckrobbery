return {
    useTarget = false,

    missionMarker = vec3(960.71197509766, -215.51979064941, 76.2552947998), -- Marker to start mission
    dealerCoords = vec3(960.78, -216.25, 76.25), -- place where the NPC stands

    truckSpawns = { -- Possible truck spawn locations
        [1] = vec4(-1215.97, -355.4, 36.9, 208.6),
        [2] = vec4(-2036.59, -259.78, 23.39, 136.92),
        [3] = vec4(-1292.28, -807.36, 17.19, 308.12),
        [4] = vec4(1072.27, -1950.67, 30.62, 144.03),
        [5] = vec4(1001.3, -55.03, 74.57, 117.98),
        [6] = vec4(-4.7, -669.71, 32.34, 176.32),
    },

    routeColor = 6, -- Color of the route

    driverWeapon = "WEAPON_COMBATPISTOL", -- Weapon of the driver
    passengerWeapon = "WEAPON_COMBATPISTOL", -- Weapon of the passenger
    truckModel = 'Stockade', -- Model of the truck
    dealerModel = "s_m_y_dealer_01", -- Model of the NPC that gives the mission
    guardModel = "s_m_m_security_01", -- Model of the guard

    timetoDetonation = 30 * 1000, -- Time to detonate the bomb, default 30 seconds

    -- Used for mission notification
    emailNotification = function()
        TriggerServerEvent('npwd_qbx_phone:server:sendNewMail', {
            sender = Lang:t('mission.sender'),
            subject = Lang:t('mission.subject'),
            message = Lang:t('mission.message'),
        })
    end,
}