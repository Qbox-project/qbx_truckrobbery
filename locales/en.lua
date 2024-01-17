local Translations = {
    error = {
     get_out_water = 'Get out of the water',
     guards_dead = 'The guards must be dead to place the bomb',
     truck_ismoving = 'You can\'t rob a vehicle that is moving.',
     missing_bomb = 'It appears you don\'t have a bomb...',
     active_police = 'Need at least %{police} police to activate the mission.',
     already_active = 'Someone is already carrying out this mission',
    },
    success = {
      packing_cash = 'You are packing the cash into a bag',
      took_bags = 'You took $%{bags} from the Truck',
    },
    mission = {
      activation_cost = "You need $ %{cost} in the bank to accept the mission",
      accept_mission_target = 'Accept missions',
      accept_mission = '~g~[E]~b~ To accept mission',
      stockade = 'Stockade',
      sender = "The Boss",
      subject ="New Target",
      message = "So you are intrested in making some money? Good. Go get yourself a Gun and make it happen. Sending you the location now.",
    },
    info = {
      before_bomb = 'Get rid of the guards before you place the bomb.',
      detonate_bomb_target = 'Plant the Bomb',
      plant_bomb = 'Plant the Bomb',
      planting_bomb = 'Planting the Bomb..',
      bomb_timer = 'The load will be detonated in %{TimeToBlow} Seconds',
      collect = 'You can start collecting cash.',
      take_money_target = 'Take the money',
      take_money = 'Press [E] to take the money',
      cop_blip = "10-90: Armored Truck Robbery",
      alerttitle = "Armored Truck Robbery Attempt",
      alert_desc = "An Armored Truck is being robbed!",
      grabbing_money = 'You\'re taking the money..'
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})