local sqsContainers = {}
local sqsVehicles = {}

function ISInventoryPage:refreshBackpacks()
	self.buttonPool = self.buttonPool or {}
	for i,v in ipairs(self.backpacks) do
		self:removeChild(v)
		table.insert(self.buttonPool, i, v)
	end

	local floorContainer = ISInventoryPage.GetFloorContainer(self.player)

	self.inventoryPane.lastinventory = self.inventoryPane.inventory

	self.inventoryPane:hideButtons()

	local oldNumBackpacks = #self.backpacks
	table.wipe(self.backpacks)

	local containerButton = nil

	local playerObj = getSpecificPlayer(self.player)

	triggerEvent("OnRefreshInventoryWindowContainers", self, "begin")

	if self.onCharacter then
		local name = getText("IGUI_InventoryName", playerObj:getDescriptor():getForename(), playerObj:getDescriptor():getSurname())
		containerButton = self:addContainerButton(playerObj:getInventory(), self.invbasic, name, nil)
		containerButton.capacity = self.inventory:getMaxWeight()
		if not self.capacity then
			self.capacity = containerButton.capacity
		end
		local it = playerObj:getInventory():getItems()
		for i = 0, it:size()-1 do
			local item = it:get(i)
			if item:getCategory() == "Container" and playerObj:isEquipped(item) or item:getType() == "KeyRing" then
				-- found a container, so create a button for it...
				containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
				if(item:getVisual() and item:getClothingItem()) then
					local tint = item:getVisual():getTint(item:getClothingItem());
					containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0);
				end
			end
		end
	elseif playerObj:getVehicle() then
		local vehicle = playerObj:getVehicle()
		for partIndex=1,vehicle:getPartCount() do
			local vehiclePart = vehicle:getPartByIndex(partIndex-1)
			if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, playerObj) then
				-- Insert AVCS Permission Checking
				local checkResult = AVCS.getPublicPermission(vehicle, "AllowContainersAccess")

				-- If public allowed, we don't have to check other permissions
				if not checkResult then
					checkResult = AVCS.checkPermission(playerObj, vehicle)
					checkResult = AVCS.getSimpleBooleanPermission(checkResult)
				end

                if checkResult then
                    local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
                    containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, nil)
                    self:checkExplored(containerButton.inventory, playerObj)
                end
			end
		end
	else
		local cx = playerObj:getX()
		local cy = playerObj:getY()
		local cz = playerObj:getZ()

		-- Do floor
		local container = floorContainer
		container:removeItemsFromProcessItems()
		container:clear()

		local sqs = sqsContainers
		table.wipe(sqs)

		local dir = playerObj:getDir()
		local lookSquare = nil
		if self.lookDir ~= dir then
			self.lookDir = dir
			local dx,dy = 0,0
			if dir == IsoDirections.NW or dir == IsoDirections.W or dir == IsoDirections.SW then
				dx = -1
			end
			if dir == IsoDirections.NE or dir == IsoDirections.E or dir == IsoDirections.SE then
				dx = 1
			end
			if dir == IsoDirections.NW or dir == IsoDirections.N or dir == IsoDirections.NE then
				dy = -1
			end
			if dir == IsoDirections.SW or dir == IsoDirections.S or dir == IsoDirections.SE then
				dy = 1
			end
			lookSquare = getCell():getGridSquare(cx + dx, cy + dy, cz)
		end

		local vehicleContainers = sqsVehicles
		table.wipe(vehicleContainers)

		for dy=-1,1 do
			for dx=-1,1 do
				local square = getCell():getGridSquare(cx + dx, cy + dy, cz)
				if square then
					table.insert(sqs, square)
				end
			end
		end

		for _,gs in ipairs(sqs) do
			-- stop grabbing thru walls...
			local currentSq = playerObj:getCurrentSquare()
			if gs ~= currentSq and currentSq and currentSq:isBlockedTo(gs) then
				gs = nil
			end

			-- don't show containers in safehouse if you're not allowed
			if gs and isClient() and SafeHouse.isSafeHouse(gs, playerObj:getUsername(), true) and not getServerOptions():getBoolean("SafehouseAllowLoot") then
				gs = nil
			end

			if gs ~= nil then
				local numButtons = #self.backpacks

				local wobs = gs:getWorldObjects()
				for i = 0, wobs:size()-1 do
					local o = wobs:get(i)
					-- FIXME: An item can be in only one container in coop the item won't be displayed for every player.
					floorContainer:AddItem(o:getItem())
					if o:getItem() and o:getItem():getCategory() == "Container" then
						local item = o:getItem()
						containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), nil)
						if item:getVisual() and item:getClothingItem() then
							local tint = item:getVisual():getTint(item:getClothingItem());
							containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0);
						end
					end
				end

				local sobs = gs:getStaticMovingObjects()
				for i = 0, sobs:size()-1 do
					local so = sobs:get(i)
					if so:getContainer() ~= nil then
						local title = getTextOrNull("IGUI_ContainerTitle_" .. so:getContainer():getType()) or ""
						containerButton = self:addContainerButton(so:getContainer(), nil, title, nil)
						self:checkExplored(containerButton.inventory, playerObj)
					end
				end

				local obs = gs:getObjects()
				for i = 0, obs:size()-1 do
					local o = obs:get(i)
					for containerIndex = 1,o:getContainerCount() do
						local container = o:getContainerByIndex(containerIndex-1)
						local title = getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) or ""
						containerButton = self:addContainerButton(container, nil, title, nil)
						if instanceof(o, "IsoThumpable") and o:isLockedToCharacter(playerObj) then
							containerButton.onclick = nil
							containerButton.onmousedown = nil
							containerButton:setOnMouseOverFunction(nil)
							containerButton:setOnMouseOutFunction(nil)
							containerButton.textureOverride = getTexture("media/ui/lock.png")
						end

						if instanceof(o, "IsoThumpable") and o:isLockedByPadlock() and playerObj:getInventory():haveThisKeyId(o:getKeyId()) then
							containerButton.textureOverride = getTexture("media/ui/lockOpen.png")
						end

						self:checkExplored(containerButton.inventory, playerObj)
					end
				end

				local vehicle = gs:getVehicleContainer()
				if vehicle and not vehicleContainers[vehicle] then
					vehicleContainers[vehicle] = true
					for partIndex=1,vehicle:getPartCount() do
						local vehiclePart = vehicle:getPartByIndex(partIndex-1)
						if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, playerObj) then
							-- Insert AVCS Permission Checking
							local checkResult = AVCS.getPublicPermission(vehicle, "AllowContainersAccess")

							-- If public allowed, we don't have to check other permissions
							if not checkResult then
								checkResult = AVCS.checkPermission(playerObj, vehicle)
								checkResult = AVCS.getSimpleBooleanPermission(checkResult)
							end
							
                            if checkResult then
                                local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
                                containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, nil)
                                self:checkExplored(containerButton.inventory, playerObj)
                            end
						end
					end
				end

				if (numButtons < #self.backpacks) and (gs == lookSquare) then
					self.inventoryPane.inventory = self.backpacks[numButtons + 1].inventory
				end
			end
		end

		triggerEvent("OnRefreshInventoryWindowContainers", self, "beforeFloor")

		local title = getTextOrNull("IGUI_ContainerTitle_floor") or ""
		containerButton = self:addContainerButton(floorContainer, ContainerButtonIcons.floor, title, nil)
		containerButton.capacity = floorContainer:getMaxWeight()
	end

	triggerEvent("OnRefreshInventoryWindowContainers", self, "buttonsAdded")

	local found = false
	local foundIndex = -1
	for index,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == self.inventoryPane.inventory then
			foundIndex = index
			found = true
			break
		end
	end

	self.inventoryPane.inventory = self.inventoryPane.lastinventory
	self.inventory = self.inventoryPane.inventory
	if self.backpackChoice ~= nil and playerObj:getJoypadBind() ~= -1 then
		if not self.onCharacter and oldNumBackpacks == 1 and #self.backpacks > 1 then
			self.backpackChoice = 1
		end
		if self.backpackChoice > #self.backpacks then
			self.backpackChoice = 1
		end
		if self.backpacks[self.backpackChoice] ~= nil then
			self.inventoryPane.inventory = self.backpacks[self.backpackChoice].inventory
			self.capacity = self.backpacks[self.backpackChoice].capacity
		end
	else
		if not self.onCharacter and oldNumBackpacks == 1 and #self.backpacks > 1 then
			self.inventoryPane.inventory = self.backpacks[1].inventory
			self.capacity = self.backpacks[1].capacity
		elseif found then
			self.inventoryPane.inventory = self.backpacks[foundIndex].inventory
			self.capacity = self.backpacks[foundIndex].capacity
		elseif not found and #self.backpacks > 0 then
			if self.backpacks[1] and self.backpacks[1].inventory then
				self.inventoryPane.inventory = self.backpacks[1].inventory
				self.capacity = self.backpacks[1].capacity
			end
		elseif self.inventoryPane.lastinventory ~= nil then
			self.inventoryPane.inventory = self.inventoryPane.lastinventory
		end
	end

	-- ISInventoryTransferAction sometimes turns the player to face a container.
	-- Which container is selected changes as the player changes direction.
	-- Although ISInventoryTransferAction forces a container to be selected,
	-- sometimes the action completes before the player finishes turning.
	if self.forceSelectedContainer then
		if self.forceSelectedContainerTime > getTimestampMs() then
			for _,containerButton in ipairs(self.backpacks) do
				if containerButton.inventory == self.forceSelectedContainer then
					self.inventoryPane.inventory = containerButton.inventory
					self.capacity = containerButton.capacity
					break
				end
			end
		else
			self.forceSelectedContainer = nil
		end
	end

	if isClient() and (not self.isCollapsed) and (self.inventoryPane.inventory ~= self.inventoryPane.lastinventory) then
		self.inventoryPane.inventory:requestSync()
	end

	self.inventoryPane:bringToTop()
	self.resizeWidget2:bringToTop()
	self.resizeWidget:bringToTop()

	self.inventory = self.inventoryPane.inventory

	self.title = nil
	for k,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == self.inventory then
            self.selectedButton = containerButton;
			containerButton:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0)
			self.title = containerButton.name
		else
			containerButton:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0)
		end
	end

	if self.inventoryPane ~= nil then
		self.inventoryPane:refreshContainer()
	end

	self:refreshWeight()

	self:syncToggleStove()

	triggerEvent("OnRefreshInventoryWindowContainers", self, "end")
end