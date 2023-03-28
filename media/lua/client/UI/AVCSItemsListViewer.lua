--***********************************************************
--**              	  ROBERT JOHNSON                       **
--***********************************************************

AVCS_ItemsListViewer = ISPanel:derive("AVCS_ItemsListViewer");
AVCS_ItemsListViewer.messages = {};

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

--************************************************************************--
--** AVCS_ItemsListViewer:initialise
--**
--************************************************************************--

function AVCS_ItemsListViewer:initialise()
    ISPanel.initialise(self);
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    local top = 100
    self.panel = ISTabPanel:new(0, top, self.width - 10 * 2, self.height - padBottom - btnHgt - padBottom - top);
    self.panel:initialise()
    self.panel.borderColor = { r = 0, g = 0, b = 0, a = 0};
    self.panel.target = self;
    self.panel.equalTabWidth = false
    self.panel:setTabsTransparency(0)       -- Hacky way to hide it
    self:addChild(self.panel)

    self.ok = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, getText("IGUI_CraftUI_Close"), self, AVCS_ItemsListViewer.onClick);
    self.ok.internal = "CLOSE";
    self.ok.anchorTop = false
    self.ok.anchorBottom = true
    self.ok:initialise();
    self.ok:instantiate();
    self.ok.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.ok);
    
    self:initList();
end

function AVCS_ItemsListViewer:initList()
    self.items = getAllItems();

    -- we gonna separate items by module
    self.module = {};
    local moduleNames = {}
    local allItems = {}
    for i=0,self.items:size()-1 do
        local item = self.items:get(i);
        --The following code is used to generate a list of all items in the game
        --in a format that allows for easier conversion into an excel / google sheets
        --compatible layout. IN THE OUTPUT, replace <<<>>> with a tab.

        --if (item:getDisplayCategory() ~= nil) then
        --    print("<<<>>>" .. item:getName() .. "<<<>>>" .. item:getDisplayCategory())
        --else
        --    print("<<<>>>" .. item:getName() .. "<<<>>>")
        --end

        --The above code activates as soon as the item list viewer is activated.
        if not item:getObsolete() and not item:isHidden() then
            if not self.module[item:getModuleName()] then
                self.module[item:getModuleName()] = {}
                table.insert(moduleNames, item:getModuleName())
            end
            table.insert(self.module[item:getModuleName()], item);
            table.insert(allItems, item)
        end
    end

    table.sort(moduleNames, function(a,b) return not string.sort(a, b) end)

    -- FIXME: something broke the X position, not sure what. So i fixed it by just putting a +10 to the X. 
    local listBox = AVCS_ItemsListTable:new(10, 0, self.panel.width, self.panel.height, self)
    
    listBox:initialise();
    self.panel:addView("", listBox)
    listBox:initList(allItems)

end

function AVCS_ItemsListViewer:prerender()
    local z = 20;
    local splitPoint = 100;
    local x = 10;
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)



    -- TODO: DON'T FORGET TO REMOVE THIS!!!
    local tempString = "Claim Vehicles"




    self:drawText(tempString, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, tempString) / 2), z, 1,1,1,1, UIFont.Medium);
end

function AVCS_ItemsListViewer:onClick(button)
    if button.internal == "CLOSE" then
        self:close();
    end
end

function AVCS_ItemsListViewer:onSelectPlayer()
end

function AVCS_ItemsListViewer:setKeyboardFocus()
    local view = self.panel:getActiveView()
    if not view then return end
    Core.UnfocusActiveTextEntryBox()
    --view.filterWidgetMap.Type:focus()
end

function AVCS_ItemsListViewer:close()
    self:setVisible(false);
    self:removeFromUIManager();
end

function AVCS_ItemsListViewer.OnOpenPanel()
    if AVCS_ItemsListViewer.instance then
        AVCS_ItemsListViewer.instance:setVisible(true)
        AVCS_ItemsListViewer.instance:addToUIManager()
        AVCS_ItemsListViewer.instance:setKeyboardFocus()
        return
    end
    local modal = AVCS_ItemsListViewer:new(50, 200, 850 * 2, 650 * 2)
    modal:initialise();
    modal:addToUIManager();
    modal.instance:setKeyboardFocus()
end

--************************************************************************--
--** AVCS_ItemsListViewer:new
--**
--************************************************************************--
function AVCS_ItemsListViewer:new(x, y, width, height)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2);
    y = getCore():getScreenHeight() / 2 - (height / 2);
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};
    o.width = width
    o.height = height
    o.moveWithMouse = true;
    AVCS_ItemsListViewer.instance = o;
    ISDebugMenu.RegisterClass(self);
    return o;
end
