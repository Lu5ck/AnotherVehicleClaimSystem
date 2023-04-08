# Another Vehicle Claim System (AVCS)
## Goal
As this is made for MP, I am very conscious about efficiency thus I try my best to minimize meaningless loops which can and will become a performance nightmare for any server. Also, minimize inefficient use of network bandwidth and upstream as this is also a important consideration for server. All in all, I want to make vehicle claim system optimized for server usage.
## Technical - How it works
- Tracking Vehicle Ownership
Tracking vehicle is unusually difficult in PZ. PZ does not provide a good source of unique identifier for vehicles. Upon looking through the PZ methods document, the only arguably unique identifier is via "getSQLID()". Yet, it is only arguably unique identifier because client-side and server-side hold different set of "getSQLID()" which I assume is because client-side does not have the full vehicle database. The workaround solution is to simply tag the servver-side "getSQLID()" as object mod data onto the vehicle so everybody will have the same identifier. Strangely enough, vehicle object doesn't hold mod data thus we procee to unremovable objects (Thanks K15).

- Global Database
This mod started out with the goal of having a centralized database thus in this case, we use the global mod data. Global mod data is basically a fancy key/value table and so we structured two such tables
  - AVCSByVehicleSQLID
    - [Vehicle SQL ID]
      - OwnerPlayerID = Username
      - ClaimDateTime = getTimestamp()
      - CarModel = Base.Car
      - LastLocationX = 1239
      - LastLocationY = 1459
      - LastLocationUpdateDateTime = getTimestamp()
  - AVCSByPlayerID
    - [Username]
      - [VehicleSQLID1] = true
      - [VehicleSQLID2] = true
      - [VehicleSQLID.etc] = true
      - LastKnownLogonTime = getTimestamp()
    
These tables are structured similarily to a database with vehicle SQL ID acting as either primary or foreign key, player username acting as either primary or foreign key. As this is a key/value table, as long we have vehicle SQL ID or player username, we can obtain the related data easily with minimum overhead.

In PZ, global mod data is fully controlled by the modder such that the modders have to keep it sync-ed between the client-side and server-side. The lazy way is to simply transmit the entire mod data when there's any changes but this can become a bandwidth and upstream nightmare. Obviously, that is not done here. The only time the entire global mod data is sent is during when player first joined the server and when there is a unknown cause of desync occurred. Otherwie, only bare minimum data is sent.

- Overriding "IS" actions
In animated actions, it go through several stages. We override the very first stage to do our permission checking, it is the only stage that make sense.

- Logging
"isAVCSVehicleClaimAction" and "isAVCSVehicleUnclaimAction" can be manually added to log in "servertest.ini". Otherwise, if you enabled server-side permission validation for claiming and unclaiming, any abnormality will logged to the vanilla log folder under AVCS tag.

## Future
I don't know what future will hold for this mod. This mod can be expanded into a more comphrensive claiming system involving a seperate claim for factions and safehouses, likewise customized permissions just by expanding the database via global mod data and add related code to it. Unforutnately, time is not something I have a lot thus likely not add these features which is why I made this open source so in hope that others will expand it if they ever feel the passion to.
