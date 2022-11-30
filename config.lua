Config = Config or {}

Config.MissionMarker = vec3(960.71197509766, -215.51979064941, 76.2552947998) -- place where is the marker with the mission
Config.DealerCoords = vec3(960.78, -216.25, 76.25) -- place where the NPC dealer stands

Config.VehicleModel = 'stockade'
Config.VehicleSpawns = {  -- below the coordinates for random vehicle responses
    vec3(-1327.479736328, -86.045326232910, 49.31),
    vec3(-2075.888183593, -233.73908996580, 21.10),
    vec3(-972.1781616210, -1530.9045410150, 4.890),
    vec3(798.18426513672, -1799.8173828125, 29.33),
    vec3(1247.0718994141, -344.65634155273, 69.08)
}

Config.DriverWep = 'WEAPON_MICROSMG' -- the weapon the driver is to be equipped with
Config.NavWep = 'WEAPON_MICROSMG' -- the weapon the guard should be equipped with
Config.TimeToBlow = 30000 -- bomb detonation time after planting, default 20 seconds

Config.ActivePolice = 0 -- needed policemen to activate the mission
Config.Cash = math.random(250, 450) -- how much you can get from a robbery
Config.ActivationCost = 500 -- how much is the activation of the mission (clean from the bank)
Config.ResetTimer = 2700 * 1000 -- timer every how many missions you can do, default is 600 seconds