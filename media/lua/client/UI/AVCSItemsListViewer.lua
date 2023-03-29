AVCSItemsListViewer = ISPanel:derive("AVCSItemsListViewer")
AVCSItemsListViewer.messages = {}



AVCSItemsListViewer.messages = {owner = "", location = ""}



local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

--************************************************************************--
--** AVCSItemsListViewer:initialise
--**
--************************************************************************--

function AVCSItemsListViewer:initialise()
    ISPanel.initialise(self)
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    -- self.playerSelect = ISComboBox:new(self.width - 10 - btnWid, 10, btnWid, btnHgt, self, self.onSelectPlayer)
    -- self.playerSelect:initialise()
    -- self.playerSelect:addOption("Player 1")
    -- self.playerSelect:addOption("Player 2")
    -- self.playerSelect:addOption("Player 3")
    -- self.playerSelect:addOption("Player 4")
    -- self:addChild(self.playerSelect)

    local top = 50
    self.leftPanel = ISTabPanel:new(10, top, self.width/3, self.height - padBottom - btnHgt - padBottom - top)
    self.leftPanel:initialise()
    self.leftPanel.borderColor = { r = 0, g = 0, b = 0, a = 0}
    self.leftPanel.target = self
    self.leftPanel.equalTabWidth = false
    self:addChild(self.leftPanel)

    self.previewPanel = AVCSPreviewScene:new(self.width/2, top + 50, 380, 380)
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


    self.infoPanel = ISPanel:new(self.width/3 + 150, top + 450, self.width/3 + 90, 100)
    self.infoPanel:initialise()
    self.infoPanel.background = false
    self.infoPanel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.infoPanel.borderColor = { r = 1, g = 1, b = 1, a = 1}
    self.infoPanel.target = self
    self.infoPanel.equalTabWidth = false
    self:addChild(self.infoPanel)




    self.ok = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, getText("IGUI_CraftUI_Close"), self, AVCSItemsListViewer.onClick)
    self.ok.internal = "CLOSE"
    self.ok.anchorTop = false
    self.ok.anchorBottom = true
    self.ok:initialise()
    self.ok:instantiate()
    self.ok.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.ok)
    
    self:initList()
end

function AVCSItemsListViewer:initList()

    local DEBUG = true

    if DEBUG then
        self.items = {
        }

        self.items[1] = {carModel = "Base.CarTaxi", location = {1000, 2000}}
        self.items[2] = {carModel = "Base.ModernCar", location = {2000, 512}}
    else


        local playerClaimedCars = ModData.get("AVCSByPlayerID")
        local serverClaimedCars = ModData.get("AVCSByVehicleSQLID")
    
        local playerName = getPlayer():getUsername()
        self.items = {}
    
    
        if playerClaimedCars then
            
            local specificPlayerClaimedCars = playerClaimedCars[playerName]
    
        
            print("Loading vehicles list")
        
            local index = 1
            for x in pairs(specificPlayerClaimedCars) do
                local singleCar = serverClaimedCars[x]
        
                self.items[index] = {
                    carModel = singleCar.CarModel,
                    location = {singleCar.LastLocationX, singleCar.LastLocationY}
                }
        
                print(self.items[index].carModel)
                index = index + 1
        
            end
    
        end


    end





    local listBox = AVCSItemsListTable:new(0, 0, self.leftPanel.width, self.leftPanel.height - self.leftPanel.tabHeight, self.previewPanel, self.infoPanel)
    listBox:initialise()

    self.leftPanel:addView("Personal", listBox)
    listBox:initList(self.items)

    self.leftPanel:addView("Faction", listBox)
    self.leftPanel:addView("Safehouses", listBox)


    self.leftPanel:activateView("Personal")
end

function AVCSItemsListViewer:render()


    -- TODO We must allign this to the left
    self.infoPanel:drawText(AVCSItemsListViewer.messages.owner, 10, 10, 1,1,1,1, UIFont.Medium)
    self.infoPanel:drawText(AVCSItemsListViewer.messages.location, 10, 40, 1,1,1,1, UIFont.Medium)


end


function AVCSItemsListViewer:prerender()


    -- TITLE SETUP --

    local z = 20
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local title = "AVCS Menu"
    self:drawText(title, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, getText("IGUI_AdminPanel_ItemList")) / 2), z, 1,1,1,1, UIFont.Medium)


    -- OTHER STUFF --

    local infoX = self.width/3 + 150
    local infoY = 500

    local infoWidth = self.width/3 + 90
    local infoHeight = 100

    self:drawRect(infoX, infoY, infoWidth, infoHeight, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    self:drawRectBorder(infoX, infoY, infoWidth, infoHeight, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);




end

function AVCSItemsListViewer:onClick(button)
    if button.internal == "CLOSE" then
        self:close();
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
    self:setVisible(false);
    self:removeFromUIManager();
end

function AVCSItemsListViewer.OnOpenPanel()
    if AVCSItemsListViewer.instance then
        AVCSItemsListViewer.instance:setVisible(true)
        AVCSItemsListViewer.instance:addToUIManager()
        AVCSItemsListViewer.instance:setKeyboardFocus()
        return
    end
    local modal = AVCSItemsListViewer:new(50, 200, 850, 650)
    modal:initialise();
    modal:addToUIManager();
    modal.instance:setKeyboardFocus()
end

--************************************************************************--
--** AVCSItemsListViewer:new
--**
--************************************************************************--
function AVCSItemsListViewer:new(x, y, width, height)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2);
    y = getCore():getScreenHeight() / 2 - (height / 2);
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};
    o.width = width;
    o.height = height;
    o.moveWithMouse = true;
    AVCSItemsListViewer.instance = o;
    ISDebugMenu.RegisterClass(self);
    return o;
end
