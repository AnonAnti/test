local Library = {}
Library.__index = Library

local PageLibrary = {}
PageLibrary.__index = PageLibrary

local SectionLibrary = {}
SectionLibrary.__index = SectionLibrary

local Action = {}
Action.__index = Action

local fontWeight = 8.4

local DefaultTheme = {
	WindowBackgroundColor = Color3.fromRGB(51, 51, 51),
	WindowOpacity = 1,

	TabButtonColor = Color3.fromRGB(70, 69, 69),
	TabButtonHovered = Color3.fromRGB(78, 77, 77),
	TabButtonActive = Color3.fromRGB(73, 72, 72),
	TabButtonSelected = Color3.fromRGB(160, 159, 159),
	TabButtonOpacity = 1,

	PageButtonColor = Color3.fromRGB(70, 69, 69),
	PageButtonHovered = Color3.fromRGB(78, 77, 77),
	PageButtonActive = Color3.fromRGB(73, 72, 72),
	PageButtonOpacity = 1,

	PageUIElementOpacity = 1,
	PageUIElementColor = Color3.fromRGB(31, 30, 30),

	ToggleTickColor = Color3.fromRGB(230, 229, 229),
	SliderGrabColor = Color3.fromRGB(31, 30, 30),
	SliderGrabActiveColor = Color3.fromRGB(97, 96, 96),

	DropdownItemHoverColor = Color3.fromRGB(78, 77, 77),

	TopbarBackgroundColor = Color3.fromRGB(60, 60, 60),
	TopbarOpacity = 1,

	PageBackgroundColor = Color3.fromRGB(60, 60, 60),
	PageOpacity = 1,
}

function Library.new(Title, Size)
	assert(Title, "missing argument #1")
	assert(type(Title) == "string", ("invalid argument #1 (expected string, got %s)"):format(type(Title)))

	if Size then
		assert(typeof(Size) == "Vector2", ("invalid argument #2 (expected Vector2, got %s)"):format(type(Title)))
	end

	local Size = Size or Vector2.new(700, 500)
	local Padding = Vector2.new(5, 5)
	
	local MainWindow = RenderWindow.new(Title)
	MainWindow.MinSize = Size
	MainWindow.DefaultSize = MainWindow.MinSize
	MainWindow.CanResize = false
	MainWindow.Visible = true

	MainWindow:SetColor(RenderColorOption.WindowBg, DefaultTheme.WindowBackgroundColor, 1)
	MainWindow:SetColor(RenderColorOption.HeaderHovered, DefaultTheme.DropdownItemHoverColor, 1)
	MainWindow:SetColor(RenderColorOption.SliderGrab, DefaultTheme.SliderGrabColor, 1)
	MainWindow:SetColor(RenderColorOption.SliderGrabActive, DefaultTheme.SliderGrabActiveColor, 1)
	MainWindow:SetColor(RenderColorOption.CheckMark, DefaultTheme.ToggleTickColor, 1)
	MainWindow:SetStyle(RenderStyleOption.WindowPadding, Padding)

	local TabsWindow = MainWindow:Child()
	TabsWindow.Size = Vector2.new(Size.X, 30)
	TabsWindow.Visible = true

	local TabsHolder = TabsWindow:SameLine()
	local RightTabsHolder = TabsWindow:SameLine()

	TabsWindow:SetColor(RenderColorOption.Button, DefaultTheme.TabButtonColor, 1)
	TabsWindow:SetColor(RenderColorOption.ButtonHovered, DefaultTheme.TabButtonHovered, 1)
	TabsWindow:SetColor(RenderColorOption.ButtonActive, DefaultTheme.TabButtonActive, 1)
	TabsWindow:SetStyle(RenderStyleOption.ItemSpacing, Vector2.new(10, 0))
	
	local UI = {
		MainWindow = MainWindow, 
		TabsWindow = TabsWindow,
		TabsHolder = TabsHolder,
		Padding = Padding,
		CurrentPage = "",
		Sections = {},
		SectionHolders = {},
		TabButtons = {},
		OnClose = function() end,
		Initialized = false,
	}
	setmetatable(UI, Library)

	return UI
end

function Library:dispose()
	assert(self, "Expected ':' not '.' calling method 'dispose'")
	assert(self.MainWindow, "Expected ':' not '.' calling method 'dispose'")

	task.spawn(self.OnClose)

	self.MainWindow:Clear()
	self.MainWindow = nil
end

function Library:addPage(Title, Padding)
	assert(self, "Expected ':' not '.' calling method 'addPage'")
	assert(self.MainWindow, "Expected ':' not '.' calling method 'addPage'")
	assert(self.Sections[Title] == nil, ("Page '%s' already exists"):format(Title))

	if self.Initialized then
		return
	end

	local Padding = Padding or Vector2.new(5, 5)

	local SectionsHolderMain = self.MainWindow:Child()
	SectionsHolderMain.Size = self.MainWindow.MinSize - self.Padding - Vector2.new(self.Padding.X, self.TabsWindow.Size.Y * 2)
	SectionsHolderMain.Visible = false

	local SectionsHolder = SectionsHolderMain:SameLine()

	local TabButton = self.TabsHolder:Button()
	TabButton.Label = Title

	TabButton.OnUpdated:Connect(function()
		if self.CurrentPage ~= Title then
			if self.SectionHolders[self.CurrentPage] then
				self.SectionHolders[self.CurrentPage].Visible = false
			end

			self.SectionHolders[Title].Visible = true

			self.CurrentPage = Title
		end
	end)

	self.SectionHolders[Title] = SectionsHolderMain
	self.TabButtons[Title] = TabButton

	local Page = {
		Title = Title,
		Window = self,
		MainWindow = self.MainWindow,
		TabsWindow = self.TabsWindow,

		Sections = {}, 
		SectionsHolderMain = SectionsHolderMain,
		SectionsHolder = SectionsHolder,
		Padding = Padding
	}

	setmetatable(Page, PageLibrary)

	return Page
end

function PageLibrary:addSection(Name)
	assert(self, "Expected ':' not '.' calling method 'addSection'")
	assert(self.Sections, "Expected ':' not '.' calling method 'addSection'")

	assert(Name, "missing argument #1")
	assert(type(Name) == "string", ("invalid argument #1 (expected string, got %s)"):format(type(Name)))

	local Offset = Vector2.new(1 - (1 / (#self.Sections + 1)), 0)

	if #self.Sections == 0 then
		Offset = Vector2.new(0, 0)
	end

	local Size = self.MainWindow.MinSize - self.Padding - Vector2.new(self.Padding.X, self.TabsWindow.Size.Y * 2)

	local SectionWindow = self.SectionsHolder:Child()
	SectionWindow.Size = self.MainWindow.MinSize - self.Padding - Vector2.new(self.Padding.X, self.TabsWindow.Size.Y * 2)
	SectionWindow.Visible = true

	SectionWindow:SetColor(RenderColorOption.FrameBg, DefaultTheme.PageUIElementColor, DefaultTheme.PageUIElementOpacity)
	SectionWindow:SetColor(RenderColorOption.Separator, Color3.fromRGB(60, 60, 60), 0)
	SectionWindow:SetColor(RenderColorOption.Button, DefaultTheme.PageButtonColor, DefaultTheme.PageButtonOpacity)
	SectionWindow:SetColor(RenderColorOption.ButtonHovered, DefaultTheme.PageButtonHovered, DefaultTheme.PageButtonOpacity)
	SectionWindow:SetColor(RenderColorOption.ButtonActive, DefaultTheme.PageButtonActive, DefaultTheme.PageButtonOpacity)
	SectionWindow:SetColor(RenderColorOption.ChildBg, DefaultTheme.PageBackgroundColor, DefaultTheme.PageOpacity)
	SectionWindow:SetStyle(RenderStyleOption.ScrollbarSize, 5)

	SectionWindow:Indent(2):Label(Name)

	local SectionTitleSeparator = SectionWindow:Child()
	SectionTitleSeparator.Size = Vector2.new(Size.X, 1)
	SectionTitleSeparator:SetColor(RenderColorOption.ChildBg, Color3.fromRGB(255, 255, 255), 1)
	SectionTitleSeparator:SetStyle(RenderStyleOption.WindowBorderSize, 0)

	SectionWindow:Separator()

	self.Window.Sections[Name] = {SectionWindow, SectionTitleSeparator}

	table.insert(self.Sections, {SectionWindow, SectionTitleSeparator})

	for Index, Section in pairs(self.Sections) do
		local size = self.MainWindow.MinSize - self.Padding - Vector2.new(self.Padding.X, self.TabsWindow.Size.Y * 2) - ((self.MainWindow.MinSize) * Offset)

		if Index == #self.Sections then
			size = size + Vector2.new(self.MainWindow.MinSize.X - self.Padding.X - size.X, 0)
		end

		Section[1].Size = size
		Section[2].Size = Vector2.new(size.X, 1)
	end

	local Section = {
		SectionWindow = SectionWindow,
		Padding = self.Padding,
		Size = Size,
	}
	
	setmetatable(Section, SectionLibrary)

	return Section
end

function Library:init()
	assert(self, "Expected ':' not '.' calling method 'init'")
	assert(self.MainWindow, "Expected ':' not '.' calling method 'init'")

	if self.Initialized then
		return
	end

	self.Initialized = true

	local position = self.MainWindow.MinSize.X - (5 * fontWeight) - self.Padding.X * 2

	local CloseButton = self.TabsHolder:Indent(position):Button()
	CloseButton.Label = "Close"

	CloseButton.OnUpdated:Connect(function()
		if self.MainWindow then
			self:dispose()
		end
	end)
end

function Library:applyTheme(NewTheme)
	assert(self, "Expected ':' not '.' calling method 'applyTheme'")
	assert(self.MainWindow, "Expected ':' not '.' calling method 'applyTheme'")

	assert(NewTheme, "missing argument #1")
	assert(type(NewTheme) == "table", ("invalid argument #1 (expected table, got %s)"):format(type(NewTheme)))

	local function GetThemeColor(Name)
		if not NewTheme[Name] then
			return DefaultTheme[Name]
		end

		return NewTheme[Name]
	end

	self.MainWindow:SetColor(RenderColorOption.WindowBg, GetThemeColor("WindowBackgroundColor"), GetThemeColor("WindowOpacity"))
	self.MainWindow:SetColor(RenderColorOption.TitleBgCollapsed, GetThemeColor("TopbarBackgroundColor"), GetThemeColor("TopbarOpacity"))
	self.MainWindow:SetColor(RenderColorOption.TitleBg, GetThemeColor("TopbarBackgroundColor"), GetThemeColor("TopbarOpacity"))
	self.MainWindow:SetColor(RenderColorOption.TitleBgActive, GetThemeColor("TopbarBackgroundColor"), GetThemeColor("TopbarOpacity"))
	self.MainWindow:SetColor(RenderColorOption.HeaderHovered, GetThemeColor("DropdownItemHoverColor"), GetThemeColor("PageUIElementOpacity"))
	self.MainWindow:SetColor(RenderColorOption.SliderGrab, GetThemeColor("SliderGrabColor"), GetThemeColor("PageUIElementOpacity"))
	self.MainWindow:SetColor(RenderColorOption.SliderGrabActive, GetThemeColor("SliderGrabActiveColor"), GetThemeColor("PageUIElementOpacity"))
	self.MainWindow:SetColor(RenderColorOption.CheckMark, GetThemeColor("ToggleTickColor"), GetThemeColor("PageUIElementOpacity"))

	self.TabsWindow:SetColor(RenderColorOption.Button, GetThemeColor("TabButtonColor"), GetThemeColor("TabButtonOpacity"))
	self.TabsWindow:SetColor(RenderColorOption.ButtonHovered, GetThemeColor("TabButtonHovered"), GetThemeColor("TabButtonOpacity"))
	self.TabsWindow:SetColor(RenderColorOption.ButtonActive, GetThemeColor("TabButtonActive"), GetThemeColor("TabButtonOpacity"))

	for Title, SectionWindow in pairs(self.Sections) do
		SectionWindow[1]:SetColor(RenderColorOption.FrameBg, GetThemeColor("PageUIElementColor"), GetThemeColor("PageUIElementOpacity"))
		SectionWindow[1]:SetColor(RenderColorOption.Button, GetThemeColor("PageButtonColor"), GetThemeColor("PageButtonOpacity"))
		SectionWindow[1]:SetColor(RenderColorOption.ButtonHovered, GetThemeColor("PageButtonHovered"), GetThemeColor("PageButtonOpacity"))
		SectionWindow[1]:SetColor(RenderColorOption.ButtonActive, GetThemeColor("PageButtonActive"), GetThemeColor("PageButtonOpacity"))
		SectionWindow[1]:SetColor(RenderColorOption.ChildBg, GetThemeColor("PageBackgroundColor"), GetThemeColor("PageOpacity"))
	end
end

function Library:notification(Text, Type)
	assert(self, "Expected ':' not '.' calling method 'notification'")
	assert(self.MainWindow, "Expected ':' not '.' calling method 'notification'")

	local Colors = {
		[ToastType.Warning] = Color3.fromRGB(238, 185, 9),
		[ToastType.Info] = Color3.fromRGB(255, 255, 255),
		[ToastType.Error] = Color3.fromRGB(255, 0, 0),
		[ToastType.Success] = Color3.fromRGB(0, 255, 0),
	}

	syn.toast_notification({
		Type = Type or ToastType.Warning,
		Duration = 5,
		Title = self.MainWindow.WindowName .. " - Notfication",
		Content = Text,
		IconColor = Colors[Type or ToastType.Warning]
	})	
end

function Action.new(UIElement, Callback, Type)
	local NewAction = {
		UIElement = UIElement,
		Type = Type,
		Callback = Callback,
	}

	setmetatable(NewAction, Action)

	return NewAction
end

function Action:interact(...)
	assert(self, "Expected ':' not '.' calling method 'interact'")
	assert(self.UIElement, "Expected ':' not '.' calling method 'interact'")

	self.Callback(...)

	if self.Type == "Slider" then
		local newValue = ...
		assert(type(newValue) == "number", ("invalid argument #1 (expected number, got %s)"):format(type(newValue)))

		self.UIElement.Value = newValue

	elseif self.Type == "Toggle" then
		local newState = ...
		assert(type(newState) == "boolean", ("invalid argument #1 (expected boolean, got %s)"):format(type(newState)))

		self.UIElement.Value = newState

	elseif self.Type == "Dropdown" then
		local newItem = ...
		assert(type(newItem) == "string", ("invalid argument #1 (expected string, got %s)"):format(type(newItem)))
		assert(table.find(self.UIElement.Items, newItem) ~= nil, ("Dropdown doesn't contain the item '%s'"):format(newItem))

		self.UIElement.SelectedItem = table.find(self.UIElement.Items, newItem)

	elseif self.Type == "TextBox" then
		local newInput = ...
		assert(type(newInput) == "string", ("invalid argument #1 (expected string, got %s)"):format(type(newInput)))

		self.UIElement.Value = newInput

	elseif self.Type == "ColorPicker" then
		local r, g, b, a = ...
		
		assert(type(r) == "number", ("invalid argument #1 (expected number, got %s)"):format(type(r)))
		assert(type(g) == "number", ("invalid argument #2 (expected number, got %s)"):format(type(g)))
		assert(type(b) == "number", ("invalid argument #3 (expected number, got %s)"):format(type(b)))
		assert(type(a) == "number", ("invalid argument #4 (expected number, got %s)"):format(type(a)))

		self.UIElement.Color = Color3.fromRGB(r, g, b)
		self.UIElement.Alpha = a
	end
end

function Action:addItem(Item)
	assert(self, "Expected ':' not '.' calling method 'addItem'")
	assert(self.UIElement, "Expected ':' not '.' calling method 'addItem'")
	assert(self.Type == "Dropdown", "method 'addItem' can only be called on dropdowns")

	assert(table.find(self.UIElement.Items, Item) == nil, ("dropdown already contains item '%s'"):format(Item))
	
	local NewItems = table.clone(self.UIElement.Items)
	table.insert(NewItems, Item)
	self.UIElement.Items = NewItems
end

function Action:removeItem(Item)
	assert(self, "Expected ':' not '.' calling method 'removeItem'")
	assert(self.UIElement, "Expected ':' not '.' calling method 'removeItem'")
	assert(self.Type == "Dropdown", "method 'removeItem' can only be called on dropdowns")

	assert(table.find(self.UIElement.Items, Item) ~= nil, ("dropdown doesn't contain item '%s'"):format(Item))

	local NewItems = table.clone(self.UIElement.Items)
	table.remove(NewItems, table.find(NewItems, Item))
	self.UIElement.Items = NewItems
end

function Action:containsItem(Item)
	assert(self, "Expected ':' not '.' calling method 'containsItem'")
	assert(self.UIElement, "Expected ':' not '.' calling method 'containsItem'")
	assert(self.Type == "Dropdown", "method 'containsItem' can only be called on dropdowns")

	return table.find(self.UIElement.Items, Item) ~= nil
end

function SectionLibrary:addToggle(Text, Callback)
	assert(self, "Expected ':' not '.' calling method 'addToggle'")
	assert(self.SectionWindow, "Expected ':' not '.' calling method 'addToggle'")

	local Callback = Callback or function() end

	local CheckBox = self.SectionWindow:CheckBox()
	CheckBox.Label = Text
	CheckBox.Value = DefaultState ~= nil and DefaultState or false
	CheckBox.OnUpdated:Connect(function()
		Callback(CheckBox.Value)
	end)

	return Action.new(CheckBox, Callback, "Toggle")
end

function SectionLibrary:newLine(Amount)
	assert(self, "Expected ':' not '.' calling method 'newLine'")
	assert(self.SectionWindow, "Expected ':' not '.' calling method 'newLine'")

	if Amount ~= nil then
		assert(type(Amount) == "number", ("invalid argument #1 (expected number or nil, got %s)"):format(type(Amount)))
	end

	for i = 1, Amount or 1 do
		self.SectionWindow:Separator()
	end
end

function SectionLibrary:addSeparator()
	local Separator = self.SectionWindow:Child()
	Separator.Size = Vector2.new(self.Size.X, 1)
	Separator:SetColor(RenderColorOption.ChildBg, Color3.fromRGB(255, 255, 255), 1)
	Separator:SetStyle(RenderStyleOption.WindowBorderSize, 0)

	self.SectionWindow:Separator()
end

function SectionLibrary:addLabel(Text)
	assert(self, "Expected ':' not '.' calling method 'addLabel'")
	assert(self.SectionWindow, "Expected ':' not '.' calling method 'addLabel'")

	assert(Text, "missing argument #1")
	assert(type(Text) == "string", ("invalid argument #1 (expected string, got %s)"):format(type(Text)))

	self.SectionWindow:Label(Text)
end

function SectionLibrary:addButton(Text, Callback)
	assert(self, "Expected ':' not '.' calling method 'addButton'")
	assert(self.SectionWindow, "Expected ':' not '.' calling method 'addButton'")

	local Callback = Callback or function() end

	local Button = self.SectionWindow:Button()
	Button.Label = Text
	Button.OnUpdated:Connect(function()
		Callback()
	end)

	return Action.new(Button, Callback, "Button")
end

function SectionLibrary:addTextBox(Text, Callback, MaxTextLength, UILength)
	assert(self, "Expected ':' not '.' calling method 'addTextBox'")
	assert(self.SectionWindow, "Expected ':' not '.' calling method 'addTextBox'")

	local Callback = Callback or function() end

	local TextBoxHolder = self.SectionWindow:Child()
	TextBoxHolder.Size = Vector2.new(UILength or 120, 25)
	TextBoxHolder.Visible = true

	local Box = TextBoxHolder:SameLine():TextBox()
	Box.Label = Text
	Box.MaxTextLength = MaxTextLength or 16384
	Box.OnUpdated:Connect(function(...)
		Callback(...)
	end)

	return Action.new(Box, Callback, "TextBox")
end


function SectionLibrary:addSlider(Text, Callback, Min, Max, IntegerOnly, Clamped, Default, UILength)
	assert(self, "Expected ':' not '.' calling method 'addSlider'")
	assert(self.SectionWindow, "Expected ':' not '.' calling method 'addSlider'")

	assert(Min, "missing argument #3")
	assert(type(Min) == "number", ("invalid argument #3 (expected number, got %s)"):format(type(Min)))

	assert(Max, "missing argument #4")
	assert(type(Max) == "number", ("invalid argument #4 (expected number, got %s)"):format(type(Max)))

	assert(IntegerOnly ~= nil, "missing argument #5")
	assert(type(IntegerOnly) == "boolean", ("invalid argument #5 (expected boolean, got %s)"):format(type(IntegerOnly)))

	assert(Clamped ~= nil, "missing argument #6")
	assert(type(Clamped) == "boolean", ("invalid argument #6 (expected boolean, got %s)"):format(type(Clamped)))

	local Callback = Callback or function() end

	local SliderHolder = self.SectionWindow:Child()
	SliderHolder.Size = Vector2.new(UILength or 120, 25)
	SliderHolder.Visible = true

	local Slider = IntegerOnly and SliderHolder:SameLine():IntSlider() or SliderHolder:SameLine():Slider()
	Slider.Label = Text
	Slider.Min = Min
	Slider.Max = Max
	Slider.Clamped = Clamped
	Slider.Value = Default or Min
	Slider.OnUpdated:Connect(function(...)
		Callback(...)
	end)

	return Action.new(Slider, Callback, "Slider")
end

function SectionLibrary:addDropdown(Text, Callback, Items, DefaultItem, UILength)
	assert(self, "Expected ':' not '.' calling method 'addDropdown'")
	assert(self.SectionWindow, "Expected ':' not '.' calling method 'addDropdown'")

	assert(Items, "missing argument #3")
	assert(type(Items) == "table", ("invalid argument #3 (expected table, got %s)"):format(type(Items)))

	assert(DefaultItem, "missing argument #4")
	assert(type(DefaultItem) == "string", ("invalid argument #4 (expected string, got %s)"):format(type(DefaultItem)))

	if not table.find(Items, DefaultItem) then
		error(("List doesn't contain default item '%s'"):format(DefaultItem))
	end

	local Callback = Callback or function() end

	local DropdownHolder = self.SectionWindow:Child()
	DropdownHolder.Size = Vector2.new((UILength or 160) + math.floor(#Text * fontWeight), 25)
	DropdownHolder.Visible = true

	local Dropdown = DropdownHolder:SameLine():Combo()
	Dropdown.Label = Text
	Dropdown.Items = Items
	Dropdown.SelectedItem = table.find(Items, DefaultItem)
	Dropdown.OnUpdated:Connect(function(int)
		Callback(Dropdown.Items[int])
	end)

	return Action.new(Dropdown, Callback, "Dropdown")
end

function SectionLibrary:addColorPicker(Text, Callback, DefaultColor, UseAlpha, ReturnInt, UILengthX, UILengthY)
	assert(self, "Expected ':' not '.' calling method 'addColorPicker'")
	assert(self.SectionWindow, "Expected ':' not '.' calling method 'addColorPicker'")

	local Callback = Callback or function() end

	local ColorPickerHolder = self.SectionWindow:Child()

	if UILengthX and UILengthY then
		ColorPickerHolder.Size = Vector2.new(UILengthX or 120, UILengthY or 120)
	end
	ColorPickerHolder.Visible = true

	local ColorPicker = ColorPickerHolder:SameLine():ColorPicker()
	ColorPicker.Label = Text
	ColorPicker.UseAlpha = UseAlpha ~= nil and UseAlpha or false
	ColorPicker.ReturnInt = ReturnInt ~= nil and ReturnInt or true
	ColorPicker.Color = DefaultColor or Color3.fromRGB(255, 255, 255)

	ColorPicker.OnUpdated:Connect(function(r, g, b, a)
		Callback(r, g, b, a)
	end)

	return Action.new(ColorPicker, Callback, "ColorPicker")
end


getgenv().Library = Library
