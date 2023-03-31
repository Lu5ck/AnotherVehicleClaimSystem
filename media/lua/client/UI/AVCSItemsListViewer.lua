require "ISUI/ISCollapsableWindow"


AVCSItemsListViewer = ISCollapsableWindow:derive("AVCSItemsListViewer")
AVCSItemsListViewer.messages = {}



AVCSItemsListViewer.messages = {owner = "", location = ""}



local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

--************************************************************************--
--** AVCSItemsListViewer:initialise
--**
--************************************************************************--

function AVCSItemsListViewer:initialise()

	ISCollapsableWindow.initialise(self)


    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10
    local top = 50

    local correctHeight = self.height - padBottom - btnHgt - padBottom - top


    -- self.playerSelect = ISComboBox:new(self.width - 10 - btnWid, 10, btnWid, btnHgt, self, self.onSelectPlayer)
    -- self.playerSelect:initialise()
    -- self.playerSelect:addOption("Player 1")
    -- self.playerSelect:addOption("Player 2")
    -- self.playerSelect:addOption("Player 3")
    -- self.playerSelect:addOption("Player 4")
    -- self:addChild(self.playerSelect)

    self.leftPanel = ISTabPanel:new(20, top, self.width/3, correctHeight)
    self.leftPanel:initialise()
    self.leftPanel.borderColor = { r = 0, g = 0, b = 0, a = 0}
    self.leftPanel.target = self
    self.leftPanel.equalTabWidth = false
    self:addChild(self.leftPanel)



    local unclaimBtnX = self.leftPanel.width + 50
    local unclaimBtnY = top + 200
    local unclaimBtnImg = getTexture("media/ui/emotes/no.png")

    -- media/ui/emotes/no.png
        
    self.unclaimBtn = ISButton:new(unclaimBtnX, unclaimBtnY, 50, 50, "", self, AVCSItemsListViewer.onClick)
    self.unclaimBtn.internal = "UNCLAIM"
    self.unclaimBtn.anchorTop = false
    self.unclaimBtn.anchorBottom = true
    self.unclaimBtn.borderColor = {r=1, g=1, b=1, a=1}
    self.unclaimBtn.backgroundColor = {r=0, g=0, b=0, a=1}
    self.unclaimBtn.displayBackground = true
	self.unclaimBtn:setImage(unclaimBtnImg)
	self.unclaimBtn:setTextureRGBA(1, 0, 0, 1)
    self.unclaimBtn:initialise()
    self.unclaimBtn:instantiate()
    self:addChild(self.unclaimBtn)


    local updateBtnX = self.leftPanel.width + 50
    local updateBtnY = unclaimBtnY + 100
    local updateBtnImg = getTexture("media/ui/emotes/gears_green.png")

    self.updateBtn = ISButton:new(updateBtnX, updateBtnY, 50, 50, "", self, AVCSItemsListViewer.onClick)
    self.updateBtn.internal = "REFRESH"
    self.updateBtn.anchorTop = false
    self.updateBtn.anchorBottom = true
    self.updateBtn.borderColor = {r=1, g=1, b=1, a=1}
    self.updateBtn.backgroundColor = {r=0, g=0, b=0, a=1}
    self.updateBtn.displayBackground = true
	self.updateBtn:setImage(updateBtnImg)
	--self.updateBtn:setTextureRGBA(1, 1, 1, 1)
    self.updateBtn:initialise()
    self.updateBtn:instantiate()
    self:addChild(self.updateBtn)


    local previewPanelWidth = 400
    local previewPanelHeight = 400
    local infoPanelY = top


    self.infoPanel = ISPanel:new(self.width/2, infoPanelY, previewPanelWidth, 100)
    self.infoPanel:initialise()
    self.infoPanel.background = false
    self.infoPanel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.infoPanel.borderColor = { r = 1, g = 1, b = 1, a = 1}
    self.infoPanel.target = self
    self.infoPanel.equalTabWidth = false
    self:addChild(self.infoPanel)




    self.previewPanel = AVCSPreviewScene:new(self.width/2, top, previewPanelWidth, correctHeight)
    self.previewPanel:initialise()
    self.previewPanel:instantiate()
    self.previewPanel:setAnchorTop(false)
    self.previewPanel:setAnchorRight(false)
    self.previewPanel:setAnchorBottom(true)
    self.previewPanel:setView("Right")
    self.previewPanel.javaObject:fromLua1("setZoom", 4)
    self.previewPanel.javaObject:fromLua1("setDrawGrid", false)
    self.previewPanel.javaObject:fromLua1("createVehicle", "previewVeh")
    self.previewPanel.javaObject:fromLua2("setVehicleScript", "previewVeh", "")
    self:addChild(self.previewPanel)


    -- Setup list boxes, personal, safehouses, factions
    self:initListBoxes()


	self:addToUIManager()
	self:setVisible(true)
	self:update()
	self:bringToTop()
	ISLayoutManager.RegisterWindow('AVCSItemsListViewer', AVCSItemsListViewer, self)

end

function AVCSItemsListViewer:initListBoxes()

    self:initList()



    self.listBox = AVCSItemsListTable:new(0, 0, self.leftPanel.width, self.leftPanel.height - self.leftPanel.tabHeight, self.previewPanel)
    self.listBox:initialise()

    -- TODO Add icons
    self.leftPanel:addView("P", self.listBox)
    self.listBox:initList(self.items)

    self.leftPanel:addView("F", self.listBox)       -- TODO Make different listbox
    self.leftPanel:addView("S", self.listBox)       -- TODO Make different listbox


    self.leftPanel:activateView("P")
end

function AVCSItemsListViewer:initList()

    local DEBUG = false

    if DEBUG then
        self.items = {}

        self.items[1] = {carModel = "Base.CarTaxi", location = {1000, 2000}, id = "idid"}
        self.items[2] = {carModel = "Base.ModernCar", location = {2000, 512}, id = "idid1"}
    else
        local playerClaimedCars = ModData.get("AVCSByPlayerID")
        local serverClaimedCars = ModData.get("AVCSByVehicleSQLID")

        local playerName = getPlayer():getUsername()
        self.items = {}
        local specificPlayerClaimedCars = playerClaimedCars[playerName]

        if specificPlayerClaimedCars then
            print("Loading vehicles list")

            local index = 1
            for vehicleId, _ in pairs(specificPlayerClaimedCars) do
                local singleCar = serverClaimedCars[vehicleId]

                self.items[index] = {
                    carModel = singleCar.CarModel,
                    location = {singleCar.LastLocationX, singleCar.LastLocationY},
                    id = vehicleId
                }

                print(self.items[index].carModel)
                index = index + 1

            end
        end
    end


    
end

function AVCSItemsListViewer:render()
	ISCollapsableWindow.render(self)


    -- Render the info
    
    -- TODO We must allign this to the left
    self.infoPanel:drawText(AVCSItemsListViewer.messages.owner, 10, 10, 1,1,1,1, UIFont.Medium)
    self.infoPanel:drawText(AVCSItemsListViewer.messages.location, 10, 40, 1,1,1,1, UIFont.Medium)
    
    


end

function AVCSItemsListViewer:update()

end


function AVCSItemsListViewer:prerender()
	ISCollapsableWindow.prerender(self)



    local infoX = self.infoPanel.x
    local infoY = self.infoPanel.y

    local infoWidth = self.infoPanel.width
    local infoHeight = self.infoPanel.height


    self:drawRect(infoX, infoY, infoWidth, infoHeight, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    self:drawRectBorder(infoX, infoY, infoWidth, infoHeight, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

end

function AVCSItemsListViewer:onToggleVisible()
	if self:getIsVisible() then
		self:addToUIManager()
	else
		self:removeFromUIManager()
	end
end

function AVCSItemsListViewer:refreshVehiclesList()

    self.listBox:initList(self.items)

end

function AVCSItemsListViewer:onClick(button)

    if button.internal == "UNCLAIM" then


        sendClientCommand(getPlayer(), "AVCS", "unclaimVehicle", {sqlId = AVCSItemsListViewer.messages.sqlId} )


        print("Unclaim car")
    elseif button.internal == "REFRESH" then
        self:initList()
        self.listBox:initList(self.items)       -- TODO WE SHOULD REFRESH THE OTHER LIST BOXES!
    end
end

function AVCSItemsListViewer:onSelectPlayer()
end

function AVCSItemsListViewer:setKeyboardFocus()
    local view = self.leftPanel:getActiveView()
    if not view then return end
    Core.UnfocusActiveTextEntryBox()
    --view.filterWidgetMap.Type:focus()
end

function AVCSItemsListViewer:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function AVCSItemsListViewer.OnOpenPanel()
    if AVCSItemsListViewer.instance then
        AVCSItemsListViewer.instance:setVisible(true)
        AVCSItemsListViewer.instance:addToUIManager()
        AVCSItemsListViewer.instance:setKeyboardFocus()
        

        -- TODO force update
        return
    end

    local width = 850
    local height = 650

    local x = getCore():getScreenWidth() / 2 - (width / 2)
    local y = getCore():getScreenHeight() / 2 - (height / 2)

    local modal = AVCSItemsListViewer:new(x, y, width, height)
    modal:initialise()
    modal:addToUIManager()
    modal.instance:setKeyboardFocus()
end

--************************************************************************--
--** AVCSItemsListViewer:new
--**
--************************************************************************--
function AVCSItemsListViewer:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.showBackground    	= true
	o.showBorder        	= true
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}


    o.title = "AVCS Menu"
    o.width = width
    o.height = height

	o.visibleTarget			= o;
	--o.visibleFunction		= ISSearchWindow.onToggleVisible;

    o.moveWithMouse = true
    o:setResizable(false)
	o:setDrawFrame(true)
    o:setVisible(true)
    o:initialise()

    AVCSItemsListViewer.instance = o

    return o
end
