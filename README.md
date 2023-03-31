# Another Vehicle Claim System (AVCS)
Work in Process (WIP)
## Main differences between Valhalla Community claiming.
- Valhalla track car ownership via object ModData and a serverside list if I am not mistaken. AVCS track ownership via only Global ModData.
- AVCS requires claim ticket to claim vehicle, as part of money sink economy and prevent claiming abuse.
- AVCS is designed in hope to be able to remotely unclaim vehicles since ownership is recorded in Global ModData. Removing ownership from object ModData is tedious and can create a lot of backlogs as objects only appear at runtime, when someone is in that map cell. This can be further complicated with issue like losing vehicles to "void".
- Make use of vanilla logging system to track "isAVCSVehicleClaimAction" and "isAVCSVehicleUnclaimAction" actions
- Allow public users to hitch ride as this mod only block access to driver seat instead of all the seats
- Allow public users to repair vehicles, who doesn't love free repairs? We block uninstalling and dismantling parts
## To do list
1. ~~Copy & override the remaining vanilla functions to block unauthorized vehicle utilization actions, such as siphoning fuel, dismantling vehicles, opening truck etc.~~
2. ~~Figure out a least expensive last known location tracking. The game doesn't provide access to their DB containing the vehicle locations. Need a way to track location without much overhead on server~~
3. UI to display users' claimed vehicles, showing last known locations, preview car models and allow unclaiming remotely from there
4. Expand UI to also include safehouse and factions tabs, also allow members to unclaim each others' vehicles from there
5. ~~Add in toggable (sandbox setting) server side permission checking and log unauthorized unclaim and claiming~~
6. Mesh and texture for the claim ticket
7. ~~Finish up tooltips for claim & unclaim menu~~
8. ~~Claimed timeout aka vehicles will be unclaimed if player not logon for XX time~~
