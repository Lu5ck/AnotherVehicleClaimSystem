require "ISUI/ISPanel"

-- TODO Add on select to change the preview

--local previewBtnTexture = getTexture("media/textures/ShopUI_Preview.png")


local panelContainers = {}



AVCSItemsListTable = ISPanel:derive("AVCSItemsListTable")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

function AVCSItemsListTable:initialise()
    ISPanel.initialise(self)
end


function AVCSItemsListTable:render()
    ISPanel.render(self)
end



function AVCSItemsListTable:getCurrentItemId()
    print("Selected: " .. self.datas.selected)
    
    for k, v in ipairs(self.datas.items) do
        print("Cycling: " .. k)
        if k == self.datas.selected then
            return v.item.id
            
        end
    end

end



function AVCSItemsListTable:createChildren()
    ISPanel.createChildren(self)

    self.datas = ISScrollingListBox:new(0, HEADER_HGT, self.width, self.height - HEADER_HGT)

    self.datas.itemheight = FONT_HGT_SMALL + 4 * 2
    self.datas.selected = 0
    self.datas.joypadParent = self
    self.datas.font = UIFont.NewSmall
    self.datas.doDrawItem = self.drawDatas
    self.datas.drawBorder = true
    self.datas.items = {}       -- init

    self.datas:addColumn("Car", 0)

    self.datas:initialise()
    self.datas:instantiate()

    self:addChild(self.datas)

end




function AVCSItemsListTable:initList(module)
    for _, v in ipairs(module) do
        self.datas:addItem(v.carModel, v)
    end

    table.sort(self.datas.items, function(a,b) return not string.sort(a.item.carModel, b.item.carModel) end)
    self.datas.selected = 1     -- Auto select the first item

end

local function doDrawItemOverride(self, y, item, alt)
    if AVCSMenu.isRefreshing then
        AVCSBaseUI.GetPersonalVehicles()
        self:clear()
        for _, v in ipairs(AVCSBaseUI.items) do
            self:addItem(v.carModel, v)
        end
        --table.sort(self.items, function(a,b) return not string.sort(a.item.carModel, b.item.carModel) end)
        --self.selected = 1     -- Auto select the first item

        AVCSMenu.isRefreshing = false
     end



    
    
    
    
    --print(#self.items)


    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end

    local a = 0.9

    if self.selected == item.index then
        -- FIXME workaroundy, but it should work
        AVCSItemsListViewer.messages.sqlId = item.item.id

        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15)
        --print(item.item.carModel)

        panelContainers.previewPanel.javaObject:fromLua2("setVehicleScript", "previewVeh", item.item.carModel)
        AVCSItemsListViewer.messages.owner = "Owner: " .. getPlayer():getUsername()
        AVCSItemsListViewer.messages.location = "Location: " .. tostring(item.item.location[1]) .. ", " .. tostring(item.item.location[2])

    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5)
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    local iconX = 4
    local iconSize = FONT_HGT_SMALL
    local xoffset = 10

    local clipX = self.columns[1].size
    local clipX2 = self.columns[1].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)

    --self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)

    local carName = item.item.carModel:gsub("Base.", "")        -- TODO Won't work with custom cars necessarily.



    self:drawText(getText("IGUI_VehicleName" .. carName), xoffset, y + 4, 1, 1, 1, a, self.font)
    self:repaintStencilRect(0, clipY, self.width, clipY2 - clipY)

    -- local icon = item.item:getIcon()
    -- if item.item:getIconsForTexture() and not item.item:getIconsForTexture():isEmpty() then
    --     icon = item.item:getIconsForTexture():get(0)
    -- end
    -- if icon then
    --     local texture = getTexture("Item_" .. icon)
    --     if texture then
    --         self:drawTextureScaledAspect2(texture, self.columns[2].size + iconX, y + (self.itemheight - iconSize) / 2, iconSize, iconSize,  1, 1, 1, 1);
    --     end
    -- end
    
    return y + self.itemheight;

end

function AVCSItemsListTable:update()
    self.datas.doDrawItem = doDrawItemOverride
end

--------------------------------

function AVCSItemsListTable:new(x, y, width, height, previewPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self);
    o.listHeaderColor = {r=0.4, g=0.4, b=0.4, a=0.3}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0}
    o.backgroundColor = {r=0, g=0, b=0, a=1}
    o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5}
    panelContainers.previewPanel = previewPanel
    AVCSItemsListTable.instance = o
    return o
end