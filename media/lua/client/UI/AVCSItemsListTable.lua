require "ISUI/ISPanel"

AVCS_ItemsListTable = ISPanel:derive("AVCS_ItemsListTable")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

function AVCS_ItemsListTable:initialise()
    ISPanel.initialise(self);
end


function AVCS_ItemsListTable:render()
    ISPanel.render(self);
    

end

function AVCS_ItemsListTable:new (x, y, width, height, viewer)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    o.listHeaderColor = {r=0.4, g=0.4, b=0.4, a=0.3};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0};
    o.backgroundColor = {r=0, g=0, b=0, a=1};
    o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5};
    o.filterWidgets = {};
    o.filterWidgetMap = {}
    o.viewer = viewer
    AVCS_ItemsListTable.instance = o;
    return o;
end

function AVCS_ItemsListTable:createChildren()
    ISPanel.createChildren(self);
    
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local entryHgt = FONT_HGT_MEDIUM + 2 * 4
    local bottomHgt = 5 + FONT_HGT_SMALL * 2 + 5 + btnHgt + 20 + FONT_HGT_LARGE + HEADER_HGT + entryHgt

    self.datas = ISScrollingListBox:new(0, HEADER_HGT, self.width, self.height - bottomHgt - HEADER_HGT);
    self.datas:initialise();
    self.datas:instantiate();
    self.datas.itemheight = FONT_HGT_MEDIUM + 4 * 4
    self.datas.selected = 0;
    self.datas.joypadParent = self;
    self.datas.font = UIFont.Medium;
    self.datas.doDrawItem = self.drawDatas
    self.datas.drawBorder = true

    self.datas:addColumn("Name", 0)
    self.datas:addColumn("Price", 900)

    self.datas:setOnMouseDoubleClick(self, AVCS_ItemsListTable.addItem);
    self:addChild(self.datas);

    local x = 0;
    --local entryY = self.filters:getBottom() + self.datas.itemheight
    for i, _ in ipairs(self.datas.columns) do
        local size;
        if i == #self.datas.columns then -- last column take all the remaining width
            size = self.datas:getWidth() - x;
        else
            size = self.datas.columns[i+1].size - self.datas.columns[i].size
        end
        x = x + size;
    end
end

function AVCS_ItemsListTable:addItem(item)
    
    print("popup confirmation menu")
end

function AVCS_ItemsListTable:onOptionMouseDown(button, x, y)
    if button.internal == "ADDITEM1" then
        local item = button.parent.datas.items[button.parent.datas.selected].item
        self:addItem(item)
    end
    if button.internal == "ADDITEM2" then
        local item = button.parent.datas.items[button.parent.datas.selected].item
        for i=1,2 do self:addItem(item) end
    end
    if button.internal == "ADDITEM5" then
        local item = button.parent.datas.items[button.parent.datas.selected].item
        for i=1,5 do self:addItem(item) end
    end
    if button.internal == "ADDITEM" then
        local item = button.parent.datas.items[button.parent.datas.selected].item;
--        self:addItem(button.parent.datas.items[button.parent.datas.selected].item);
        local modal = ISTextBox:new(0, 0, 280, 180, "Add x item(s): " .. item:getDisplayName(), "1", self, AVCS_ItemsListTable.onAddItem, nil, item);
        modal:initialise();
        modal:addToUIManager();
        modal:setOnlyNumbers(true);
    end
end

function AVCS_ItemsListTable:onAddItem(button, item)
    if button.internal == "OK" then
        for i=0,tonumber(button.parent.entry:getText()) - 1 do
            self:addItem(item);
        end
    end
end

function AVCS_ItemsListTable:initList(module)



    
    local categoryNames = {}
    local displayCategoryNames = {}
    local categoryMap = {}
    local displayCategoryMap = {}
    for x,v in ipairs(module) do
        self.datas:addItem(v:getDisplayName(), v);
        if not categoryMap[v:getTypeString()] then
            categoryMap[v:getTypeString()] = true
            table.insert(categoryNames, v:getTypeString())
        end
        if not displayCategoryMap[v:getDisplayCategory()] then
            displayCategoryMap[v:getDisplayCategory()] = true
            table.insert(displayCategoryNames, v:getDisplayCategory())
        end
    end
    table.sort(self.datas.items, function(a,b) return not string.sort(a.item:getDisplayName(), b.item:getDisplayName()); end);

    --local combo = self.filterWidgetMap.Type
    table.sort(categoryNames, function(a,b) return not string.sort(a, b) end)
    --combo:addOption("<Any>")
    for _,categoryName in ipairs(categoryNames) do
        --combo:addOption(categoryName)
    end

    --local combo = self.filterWidgetMap.Name
    table.sort(displayCategoryNames, function(a,b) return not string.sort(a, b) end)
    --combo:addOption("<Any>")
    --combo:addOption("<No category set>")
    for _,displayCategoryName in ipairs(displayCategoryNames) do
        --combo:addOption(displayCategoryName)
    end
end

function AVCS_ItemsListTable:update()
    self.datas.doDrawItem = self.drawDatas
end

function AVCS_ItemsListTable:filterDisplayCategory(widget, scriptItem)
    if widget.selected == 1 then return true end -- Any category
    if widget.selected == 2 then return scriptItem:getDisplayCategory() == nil end
    return scriptItem:getDisplayCategory() == widget:getOptionText(widget.selected)
end

function AVCS_ItemsListTable:filterCategory(widget, scriptItem)
    if widget.selected == 1 then return true end -- Any category
    return scriptItem:getTypeString() == widget:getOptionText(widget.selected)
end

function AVCS_ItemsListTable:filterName(widget, scriptItem)
    local txtToCheck = string.lower(scriptItem:getDisplayName())
    local filterTxt = string.lower(widget:getInternalText())
    return checkStringPattern(filterTxt) and string.match(txtToCheck, filterTxt)
end

function AVCS_ItemsListTable:filterType(widget, scriptItem)
    local txtToCheck = string.lower(scriptItem:getName())
    local filterTxt = string.lower(widget:getInternalText())
    return checkStringPattern(filterTxt) and string.match(txtToCheck, filterTxt)
end

function AVCS_ItemsListTable.onFilterChange(widget)
    local datas = widget.parent.datas;
    if not datas.fullList then datas.fullList = datas.items; end
    datas:clear()
--print(entry.parent, combo)
--    local filterTxt = entry:getInternalText();
--    if filterTxt == "" then datas.items = datas.fullList; return; end
    for i,v in ipairs(datas.fullList) do -- check every items
        local add = true;
        for j,widget in ipairs(widget.parent.filterWidgets) do -- check every filters
            if not widget.itemsListFilter(self, widget, v.item) then
                add = false
                break
            end
        end
        if add then
            datas:addItem(i, v.item);
        end
    end
end

function AVCS_ItemsListTable:onOtherKey(key)
    if key == Keyboard.KEY_TAB then
        Core.UnfocusActiveTextEntryBox()
        if self.columnName == "Type" then
            self.parent.filterWidgetMap.Name:focus()
        else
            self.parent.filterWidgetMap.Type:focus()
        end
    end
end

function AVCS_ItemsListTable:drawDatas(y, item, alt)
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end
    
    local a = 0.9;

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5);
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local iconX = 12
    local iconSize = FONT_HGT_LARGE;
    local xoffset = 10;

    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)
    
    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item:getDisplayName(), iconX + iconSize + 40, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self:drawText("Test price", self.columns[2].size + xoffset, y + 4, 1, 1, 1, a, self.font)


    self:repaintStencilRect(0, clipY, self.width, clipY2 - clipY)

    local icon = item.item:getIcon()
    if item.item:getIconsForTexture() and not item.item:getIconsForTexture():isEmpty() then
        icon = item.item:getIconsForTexture():get(0)
    end
    if icon then
        local texture = getTexture("Item_" .. icon)
        if texture then
            self:drawTextureScaledAspect2(texture, self.columns[1].size + iconX, y + (self.itemheight - iconSize) / 2, iconSize, iconSize,  1, 1, 1, 1);
        end
    end
    
    return y + self.itemheight;
end
