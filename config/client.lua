return {
    dealerCoords = vec4(960.78, -216.25, 75.25, 1.8), -- place where the NPC stands
    routeColor = 6, -- Color of the route
    dealerModel = `s_m_y_dealer_01`, -- Model of the NPC that gives the mission

    -- Used for mission notification
    emailNotification = function()
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = locale('mission.sender'),
            subject = locale('mission.subject'),
            message = locale('mission.message'),
        })
    end,
    guardAccuracy = 50,
    lootDuration = 5000 -- how many milliseconds it takes to loot the truck
}
