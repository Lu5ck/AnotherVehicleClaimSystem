AVCSItemsListViewer = ISPanel:derive("AVCSItemsListViewer")
AVCSItemsListViewer.messages = {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

--************************************************************************--
--** AVCSItemsListViewer:initialise
--**
--************************************************************************--

function AVCSItemsListViewer:initialise()
    ISPanel.initialise(self);
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
    self.panel = ISTabPanel:new(10, top, self.width - 10 * 2, self.height - padBottom - btnHgt - padBottom - top);
    self.panel:initialise();
    self.panel.borderColor = { r = 0, g = 0, b = 0, a = 0}
    self.panel.target = self;
    self.panel.equalTabWidth = false
    self:addChild(self.panel);

    self.ok = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, getText("IGUI_CraftUI_Close"), self, AVCSItemsListViewer.onClick);
    self.ok.internal = "CLOSE";
    self.ok.anchorTop = false
    self.ok.anchorBottom = true
    self.ok:initialise();
    self.ok:instantiate();
    self.ok.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.ok);
    
    self:initList();
end

function AVCSItemsListViewer:initList()

    local playerClaimedCars = ModData.get("AVCSByPlayerID")
    local serverClaimedCars = ModData.get("AVCSByVehicleSQLID")


    local playerName = getPlayer():getUsername()
    local specificPlayerClaimedCars = playerClaimedCars[playerName]



    self.items = {}

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


    local listBox = AVCSItemsListTable:new(0, 0, self.panel.width, self.panel.height - self.panel.tabHeight, self);
    listBox:initialise()
    self.panel:addView(playerName, listBox);
--    listBox.parent = self;
    listBox:initList(self.items)
    self.panel:activateView(playerName)
end

function AVCSItemsListViewer:prerender()
    local z = 20;
    local splitPoint = 100;
    local x = 10;
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
    
    
    local title = "AVCS Menu"
    
    self:drawText(title, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, getText("IGUI_AdminPanel_ItemList")) / 2), z, 1,1,1,1, UIFont.Medium);
end

function AVCSItemsListViewer:onClick(button)
    if button.internal == "CLOSE" then
        self:close();
    end
end

function AVCSItemsListViewer:onSelectPlayer()
end

function AVCSItemsListViewer:setKeyboardFocus()
    local view = self.panel:getActiveView()
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
