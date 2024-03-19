![image](https://github.com/Qbox-project/qbx_truckrobbery/assets/3579092/3cca1b05-e993-4b1f-bcf8-872c10096e84)
# qbx_truckrobbery

Heist to stop and rob a moving bank truck. After stopping the truck, player's must plant explosives on the back door and blow it off to access to the loot inside.

## Features
- **Networked Interactions**: Any player can interact with the truck to plant a bomb or loot it. This allows rival gangs to fight over the rewards inside.
- Truck drives erattically without stopping for traffic, objects, nor players
- 4 guards inside have different configurable weapons
- Police are alerted when player's are very close to the truck
- If the truck is more than 400 units away from any player, the mission fails
- Can configure a loot table of items that may be in the truck with different probabilities
- **Scalable/Performant**: Uses statebags & distance based checks so that only players within range of the mission execute code.
