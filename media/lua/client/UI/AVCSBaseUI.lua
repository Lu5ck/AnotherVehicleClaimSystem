AVCSBaseUI = {}

AVCSBaseUI.items = {}

AVCSBaseUI.GetPersonalVehicles = function()
    local DEBUG = false
    local items = {}

    if DEBUG then
        items[1] = {carModel = "Base.CarTaxi", location = {1000, 2000}, id = "idid"}
        items[2] = {carModel = "Base.ModernCar", location = {2000, 512}, id = "idid1"}


    else
        local playerClaimedCars = ModData.get("AVCSByPlayerID")
        local serverClaimedCars = ModData.get("AVCSByVehicleSQLID")

        local playerName = getPlayer():getUsername()
        local specificPlayerClaimedCars = playerClaimedCars[playerName]

        if specificPlayerClaimedCars then
            print("Loading vehicles list")

            local index = 1
            for vehicleId, _ in pairs(specificPlayerClaimedCars) do
                local singleCar = serverClaimedCars[vehicleId]

                items[index] = {
                    carModel = singleCar.CarModel,
                    location = {singleCar.LastLocationX, singleCar.LastLocationY},
                    id = vehicleId
                }

                print(items[index].carModel)
                index = index + 1

            end
        end
    end

    
    AVCSMenu.isItemsEmpty = #items == 0
    AVCSBaseUI.items = items

    return items

end