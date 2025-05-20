-- RoImGUI v2: A cleaner, more reliable ImGUI-style library for Roblox
-- Usage: local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourusername/RoImGUI/main/roimgui_v2.lua"))()

local ImGui = {}
ImGui.__index = ImGui

-- Theme configuration
local Theme = {
    Window = {
        Background = Color3.fromRGB(30, 30, 30),
        Border = Color3.fromRGB(60, 60, 60),
        Title = Color3.fromRGB(240, 240, 240),
        TitleBackground = Color3.fromRGB(40, 40, 40)
    },
    Element = {
        Background = Color3.fromRGB(50, 50, 50),
        BackgroundHover = Color3.fromRGB(60, 60, 60),
        Text = Color3.fromRGB(240, 240, 240),
        Border = Color3.fromRGB(70, 70, 70),
        Accent = Color3.fromRGB(0, 120, 215),
        Disabled = Color3.fromRGB(100, 100, 100)
    },
    Font = Enum.Font.SourceSansSemibold,
    TextSize = 14,
    Rounding = 4,
    Padding = 8,
    ElementHeight = 28,
    ElementSpacing = 4,
    WindowMinSize = Vector2.new(200, 150)
}

-- Utility functions
local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties or {}) do
        instance[k] = v
    end
    return instance
end

local function Round(num, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Initialize ImGui
function ImGui.new(parent)
    local self = setmetatable({}, ImGui)
    
    -- Create ScreenGui
    self.ScreenGui = CreateInstance("ScreenGui", {
        Name = "ImGui",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parent or (game:GetService("RunService"):IsStudio() and game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") or game.CoreGui)
    })
    
    -- State
    self.Windows = {}
    self.ActiveWindow = nil
    self.HoveredElement = nil
    self.DraggingElement = nil
    self.ElementCounter = 0
    self.WindowsZIndex = 0
    
    -- Input handling
    self.InputService = game:GetService("UserInputService")
    self.Mouse = game:GetService("Players").LocalPlayer:GetMouse()
    
    return self
end

-- Create a new window
function ImGui:Window(title, position, size)
    local windowId = title
    self.WindowsZIndex = self.WindowsZIndex + 1
    
    if not self.Windows[windowId] then
        local windowSize = size or Vector2.new(300, 400)
        local windowPos = position or Vector2.new(100, 100)
        
        -- Create window container
        local window = CreateInstance("Frame", {
            Name = title,
            Size = UDim2.new(0, windowSize.X, 0, windowSize.Y),
            Position = UDim2.new(0, windowPos.X, 0, windowPos.Y),
            BackgroundColor3 = Theme.Window.Background,
            BorderSizePixel = 1,
            BorderColor3 = Theme.Window.Border,
            ZIndex = self.WindowsZIndex,
            Parent = self.ScreenGui
        })
        
        -- Add corner rounding
        local corner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = window
        })
        
        -- Create title bar
        local titleBar = CreateInstance("Frame", {
            Name = "TitleBar",
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme.Window.TitleBackground,
            BorderSizePixel = 0,
            ZIndex = self.WindowsZIndex,
            Parent = window
        })
        
        -- Add corner rounding to title bar (top corners only)
        local titleCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = titleBar
        })
        
        -- Title text
        local titleText = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = Theme.Window.Title,
            TextSize = Theme.TextSize,
            Font = Theme.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = self.WindowsZIndex,
            Parent = titleBar
        })
        
        -- Content container
        local content = CreateInstance("ScrollingFrame", {
            Name = "Content",
            Size = UDim2.new(1, 0, 1, -30),
            Position = UDim2.new(0, 0, 0, 30),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Element.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = self.WindowsZIndex,
            Parent = window
        })
        
        -- Add padding to content
        local contentPadding = CreateInstance("UIPadding", {
            PaddingLeft = UDim.new(0, Theme.Padding),
            PaddingRight = UDim.new(0, Theme.Padding),
            PaddingTop = UDim.new(0, Theme.Padding),
            PaddingBottom = UDim.new(0, Theme.Padding),
            Parent = content
        })
        
        -- Auto layout for content
        local contentLayout = CreateInstance("UIListLayout", {
            Padding = UDim.new(0, Theme.ElementSpacing),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = content
        })
        
        -- Make window draggable
        local dragging = false
        local dragStart, startPos
        
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = window.Position
                
                -- Bring window to front
                self.WindowsZIndex = self.WindowsZIndex + 1
                window.ZIndex = self.WindowsZIndex
                titleBar.ZIndex = self.WindowsZIndex
                content.ZIndex = self.WindowsZIndex
                
                -- Update ZIndex for all children
                for _, child in pairs(window:GetDescendants()) do
                    if child:IsA("GuiObject") then
                        child.ZIndex = self.WindowsZIndex
                    end
                end
            end
        end)
        
        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        self.InputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                window.Position = UDim2.new(
                    startPos.X.Scale, 
                    startPos.X.Offset + delta.X, 
                    startPos.Y.Scale, 
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        -- Update content canvas size when children change
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + Theme.Padding * 2)
        end)
        
        -- Store window data
        self.Windows[windowId] = {
            Frame = window,
            Content = content,
            Elements = {},
            Visible = true,
            Layout = contentLayout
        }
    end
    
    -- Set as active window
    self.ActiveWindow = windowId
    
    -- Reset element counter for this frame
    self.ElementCounter = 0
    
    return self.Windows[windowId].Visible
end

-- End the current window
function ImGui:EndWindow()
    self.ActiveWindow = nil
end

-- Generate a unique ID for elements
function ImGui:GetID(name)
    self.ElementCounter = self.ElementCounter + 1
    return name .. "_" .. self.ElementCounter
end

-- Button element
function ImGui:Button(label, size)
    if not self.ActiveWindow then return false end
    
    local window = self.Windows[self.ActiveWindow]
    local id = self:GetID("Button_" .. label)
    
    -- Default width is full width minus padding
    local buttonWidth = (size and size.X) or (window.Content.AbsoluteSize.X - Theme.Padding * 2)
    
    -- Create or update button
    local button
    if not window.Elements[id] then
        button = CreateInstance("TextButton", {
            Name = id,
            Size = UDim2.new(0, buttonWidth, 0, Theme.ElementHeight),
            BackgroundColor3 = Theme.Element.Background,
            BorderSizePixel = 0,
            Text = label,
            TextColor3 = Theme.Element.Text,
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            AutoButtonColor = false,
            ZIndex = self.WindowsZIndex,
            Parent = window.Content
        })
        
        -- Add corner rounding
        local corner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = button
        })
        
        -- Store element
        window.Elements[id] = {
            Instance = button,
            Type = "Button",
            Clicked = false
        }
        
        -- Handle hover and click effects
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Theme.Element.BackgroundHover
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Theme.Element.Background
        end)
        
        button.MouseButton1Down:Connect(function()
            button.BackgroundColor3 = Theme.Element.Accent
        end)
        
        button.MouseButton1Up:Connect(function()
            button.BackgroundColor3 = Theme.Element.BackgroundHover
        end)
    else
        button = window.Elements[id].Instance
        button.Text = label
        button.Size = UDim2.new(0, buttonWidth, 0, Theme.ElementHeight)
    end
    
    -- Reset clicked state
    window.Elements[id].Clicked = false
    
    -- Check if button was clicked
    button.MouseButton1Click:Connect(function()
        window.Elements[id].Clicked = true
    end)
    
    return window.Elements[id].Clicked
end

-- Text element
function ImGui:Text(text, color)
    if not self.ActiveWindow then return end
    
    local window = self.Windows[self.ActiveWindow]
    local id = self:GetID("Text_" .. text:sub(1, math.min(10, #text)))
    
    -- Create or update text label
    local label
    if not window.Elements[id] then
        label = CreateInstance("TextLabel", {
            Name = id,
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = color or Theme.Element.Text,
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = self.WindowsZIndex,
            Parent = window.Content
        })
        
        -- Store element
        window.Elements[id] = {
            Instance = label,
            Type = "Text"
        }
    else
        label = window.Elements[id].Instance
        label.Text = text
        if color then
            label.TextColor3 = color
        end
    end
    
    -- Adjust height based on text content
    local textSize = game:GetService("TextService"):GetTextSize(
        text,
        Theme.TextSize,
        Theme.Font,
        Vector2.new(label.AbsoluteSize.X, 10000)
    )
    
    label.Size = UDim2.new(1, 0, 0, math.max(Theme.ElementHeight, textSize.Y))
end

-- Slider element
function ImGui:Slider(label, value, min, max, format)
    if not self.ActiveWindow then return value end
    
    local window = self.Windows[self.ActiveWindow]
    local id = self:GetID("Slider_" .. label)
    
    -- Format value display
    format = format or "%.1f"
    local displayValue = string.format(format, value)
    
    -- Create container
    local container
    local slider
    local fill
    local valueLabel
    
    if not window.Elements[id] then
        -- Container for the whole element
        container = CreateInstance("Frame", {
            Name = id,
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight * 2),
            BackgroundTransparency = 1,
            ZIndex = self.WindowsZIndex,
            Parent = window.Content
        })
        
        -- Label
        local textLabel = CreateInstance("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -70, 0, Theme.ElementHeight),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Theme.Element.Text,
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Value display
        valueLabel = CreateInstance("TextLabel", {
            Name = "Value",
            Size = UDim2.new(0, 70, 0, Theme.ElementHeight),
            Position = UDim2.new(1, -70, 0, 0),
            BackgroundTransparency = 1,
            Text = displayValue,
            TextColor3 = Theme.Element.Accent,
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Slider background
        slider = CreateInstance("Frame", {
            Name = "Slider",
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
            Position = UDim2.new(0, 0, 0, Theme.ElementHeight),
            BackgroundColor3 = Theme.Element.Background,
            BorderSizePixel = 0,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Add corner rounding
        local sliderCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = slider
        })
        
        -- Slider fill
        fill = CreateInstance("Frame", {
            Name = "Fill",
            Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = Theme.Element.Accent,
            BorderSizePixel = 0,
            ZIndex = self.WindowsZIndex,
            Parent = slider
        })
        
        -- Add corner rounding to fill
        local fillCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = fill
        })
        
        -- Store element
        window.Elements[id] = {
            Instance = container,
            Slider = slider,
            Fill = fill,
            ValueLabel = valueLabel,
            Type = "Slider",
            Value = value
        }
        
        -- Handle slider interaction
        local isDragging = false
        
        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                
                -- Calculate value from mouse position
                local relativeX = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                local newValue = min + relativeX * (max - min)
                newValue = Round(newValue, 1) -- Round to 1 decimal place
                
                -- Update value
                window.Elements[id].Value = newValue
                valueLabel.Text = string.format(format, newValue)
                fill.Size = UDim2.new(relativeX, 0, 1, 0)
            end
        end)
        
        slider.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end)
        
        self.InputService.InputChanged:Connect(function(input)
            if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                -- Calculate value from mouse position
                local relativeX = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                local newValue = min + relativeX * (max - min)
                newValue = Round(newValue, 1) -- Round to 1 decimal place
                
                -- Update value
                window.Elements[id].Value = newValue
                valueLabel.Text = string.format(format, newValue)
                fill.Size = UDim2.new(relativeX, 0, 1, 0)
            end
        end)
    else
        container = window.Elements[id].Instance
        slider = window.Elements[id].Slider
        fill = window.Elements[id].Fill
        valueLabel = window.Elements[id].ValueLabel
        
        -- Update value display
        valueLabel.Text = displayValue
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        window.Elements[id].Value = value
    end
    
    return window.Elements[id].Value
end

-- Checkbox element
function ImGui:Checkbox(label, checked)
    if not self.ActiveWindow then return checked end
    
    local window = self.Windows[self.ActiveWindow]
    local id = self:GetID("Checkbox_" .. label)
    
    -- Create container
    local container
    local box
    local checkmark
    
    if not window.Elements[id] then
        -- Container for the whole element
        container = CreateInstance("Frame", {
            Name = id,
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
            BackgroundTransparency = 1,
            ZIndex = self.WindowsZIndex,
            Parent = window.Content
        })
        
        -- Checkbox
        box = CreateInstance("Frame", {
            Name = "Box",
            Size = UDim2.new(0, Theme.ElementHeight - 8, 0, Theme.ElementHeight - 8),
            Position = UDim2.new(0, 0, 0, 4),
            BackgroundColor3 = checked and Theme.Element.Accent or Theme.Element.Background,
            BorderSizePixel = 0,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Add corner rounding
        local boxCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = box
        })
        
        -- Checkmark (visible when checked)
        checkmark = CreateInstance("ImageLabel", {
            Name = "Checkmark",
            Size = UDim2.new(0.7, 0, 0.7, 0),
            Position = UDim2.new(0.15, 0, 0.15, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6031094667", -- Checkmark icon
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            Visible = checked,
            ZIndex = self.WindowsZIndex,
            Parent = box
        })
        
        -- Label
        local textLabel = CreateInstance("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -(Theme.ElementHeight), 0, Theme.ElementHeight),
            Position = UDim2.new(0, Theme.ElementHeight, 0, 0),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Theme.Element.Text,
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Make clickable
        local button = CreateInstance("TextButton", {
            Name = "Button",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Store element
        window.Elements[id] = {
            Instance = container,
            Box = box,
            Checkmark = checkmark,
            Type = "Checkbox",
            Checked = checked
        }
        
        -- Handle checkbox interaction
        button.MouseButton1Click:Connect(function()
            window.Elements[id].Checked = not window.Elements[id].Checked
            box.BackgroundColor3 = window.Elements[id].Checked and Theme.Element.Accent or Theme.Element.Background
            checkmark.Visible = window.Elements[id].Checked
        end)
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            if not window.Elements[id].Checked then
                box.BackgroundColor3 = Theme.Element.BackgroundHover
            end
        end)
        
        button.MouseLeave:Connect(function()
            if not window.Elements[id].Checked then
                box.BackgroundColor3 = Theme.Element.Background
            end
        end)
    else
        container = window.Elements[id].Instance
        box = window.Elements[id].Box
        checkmark = window.Elements[id].Checkmark
        
        -- Update checked state
        if checked ~= window.Elements[id].Checked then
            window.Elements[id].Checked = checked
            box.BackgroundColor3 = checked and Theme.Element.Accent or Theme.Element.Background
            checkmark.Visible = checked
        end
    end
    
    return window.Elements[id].Checked
end

-- Input field element
function ImGui:InputText(label, text)
    if not self.ActiveWindow then return text end
    
    local window = self.Windows[self.ActiveWindow]
    local id = self:GetID("Input_" .. label)
    
    -- Create container
    local container
    local textBox
    
    if not window.Elements[id] then
        -- Container for the whole element
        container = CreateInstance("Frame", {
            Name = id,
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight * 2),
            BackgroundTransparency = 1,
            ZIndex = self.WindowsZIndex,
            Parent = window.Content
        })
        
        -- Label
        local textLabel = CreateInstance("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Theme.Element.Text,
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- TextBox
        textBox = CreateInstance("TextBox", {
            Name = "TextBox",
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
            Position = UDim2.new(0, 0, 0, Theme.ElementHeight),
            BackgroundColor3 = Theme.Element.Background,
            BorderSizePixel = 0,
            Text = text or "",
            PlaceholderText = "Enter text...",
            TextColor3 = Theme.Element.Text,
            PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            ClearTextOnFocus = false,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Add corner rounding
        local boxCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = textBox
        })
        
        -- Add padding
        local padding = CreateInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = textBox
        })
        
        -- Store element
        window.Elements[id] = {
            Instance = container,
            TextBox = textBox,
            Type = "InputText",
            Text = text or ""
        }
        
        -- Handle text input
        textBox.FocusLost:Connect(function()
            window.Elements[id].Text = textBox.Text
        end)
        
        -- Hover effect
        textBox.MouseEnter:Connect(function()
            textBox.BackgroundColor3 = Theme.Element.BackgroundHover
        end)
        
        textBox.MouseLeave:Connect(function()
            textBox.BackgroundColor3 = Theme.Element.Background
        end)
    else
        container = window.Elements[id].Instance
        textBox = window.Elements[id].TextBox
        
        -- Update text
        if text ~= window.Elements[id].Text then
            window.Elements[id].Text = text
            textBox.Text = text
        end
    end
    
    return window.Elements[id].Text
end

-- Separator element
function ImGui:Separator()
    if not self.ActiveWindow then return end
    
    local window = self.Windows[self.ActiveWindow]
    local id = self:GetID("Separator")
    
    -- Create separator
    local separator
    if not window.Elements[id] then
        separator = CreateInstance("Frame", {
            Name = id,
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme.Element.Border,
            BorderSizePixel = 0,
            ZIndex = self.WindowsZIndex,
            Parent = window.Content
        })
        
        -- Store element
        window.Elements[id] = {
            Instance = separator,
            Type = "Separator"
        }
    else
        separator = window.Elements[id].Instance
    end
end

-- ColorPicker element
function ImGui:ColorPicker(label, color)
    if not self.ActiveWindow then return color end
    
    local window = self.Windows[self.ActiveWindow]
    local id = self:GetID("ColorPicker_" .. label)
    
    -- Create container
    local container
    local preview
    
    if not window.Elements[id] then
        -- Container for the whole element
        container = CreateInstance("Frame", {
            Name = id,
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
            BackgroundTransparency = 1,
            ZIndex = self.WindowsZIndex,
            Parent = window.Content
        })
        
        -- Label
        local textLabel = CreateInstance("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -Theme.ElementHeight - 4, 0, Theme.ElementHeight),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Theme.Element.Text,
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Color preview
        preview = CreateInstance("Frame", {
            Name = "Preview",
            Size = UDim2.new(0, Theme.ElementHeight - 8, 0, Theme.ElementHeight - 8),
            Position = UDim2.new(1, -Theme.ElementHeight + 4, 0, 4),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Add corner rounding
        local previewCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = preview
        })
        
        -- Make clickable
        local button = CreateInstance("TextButton", {
            Name = "Button",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Store element
        window.Elements[id] = {
            Instance = container,
            Preview = preview,
            Type = "ColorPicker",
            Color = color
        }
        
        -- TODO: Implement color picker popup
        -- For now, just cycle through some preset colors on click
        local colors = {
            Color3.fromRGB(255, 0, 0),   -- Red
            Color3.fromRGB(0, 255, 0),   -- Green
            Color3.fromRGB(0, 0, 255),   -- Blue
            Color3.fromRGB(255, 255, 0), -- Yellow
            Color3.fromRGB(0, 255, 255), -- Cyan
            Color3.fromRGB(255, 0, 255), -- Magenta
            Color3.fromRGB(255, 255, 255) -- White
        }
        
        local colorIndex = 1
        
        button.MouseButton1Click:Connect(function()
            colorIndex = (colorIndex % #colors) + 1
            window.Elements[id].Color = colors[colorIndex]
            preview.BackgroundColor3 = colors[colorIndex]
        end)
    else
        container = window.Elements[id].Instance
        preview = window.Elements[id].Preview
        
        -- Update color
        if color ~= window.Elements[id].Color then
            window.Elements[id].Color = color
            preview.BackgroundColor3 = color
        end
    end
    
    return window.Elements[id].Color
end

-- Dropdown element
function ImGui:Dropdown(label, options, selectedIndex)
    if not self.ActiveWindow then return selectedIndex end
    
    local window = self.Windows[self.ActiveWindow]
    local id = self:GetID("Dropdown_" .. label)
    
    -- Create container
    local container
    local dropdown
    local selectedText
    local dropdownList
    
    if not window.Elements[id] then
        -- Container for the whole element
        container = CreateInstance("Frame", {
            Name = id,
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight * 2),
            BackgroundTransparency = 1,
            ZIndex = self.WindowsZIndex,
            Parent = window.Content
        })
        
        -- Label
        local textLabel = CreateInstance("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Theme.Element.Text,
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Dropdown button
        dropdown = CreateInstance("Frame", {
            Name = "Dropdown",
            Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
            Position = UDim2.new(0, 0, 0, Theme.ElementHeight),
            BackgroundColor3 = Theme.Element.Background,
            BorderSizePixel = 0,
            ZIndex = self.WindowsZIndex,
            Parent = container
        })
        
        -- Add corner rounding
        local dropdownCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = dropdown
        })
        
        -- Selected text
        selectedText = CreateInstance("TextLabel", {
            Name = "SelectedText",
            Size = UDim2.new(1, -Theme.ElementHeight, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = options[selectedIndex] or "Select...",
            TextColor3 = Theme.Element.Text,
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = self.WindowsZIndex,
            Parent = dropdown
        })
        
        -- Arrow icon
        local arrow = CreateInstance("ImageLabel", {
            Name = "Arrow",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -24, 0.5, -8),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6031091004", -- Down arrow icon
            ImageColor3 = Theme.Element.Text,
            ZIndex = self.WindowsZIndex,
            Parent = dropdown
        })
        
        -- Dropdown list (hidden by default)
        dropdownList = CreateInstance("Frame", {
            Name = "DropdownList",
            Size = UDim2.new(1, 0, 0, #options * Theme.ElementHeight),
            Position = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = Theme.Element.Background,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = self.WindowsZIndex + 1,
            Parent = dropdown
        })
        
        -- Add corner rounding
        local listCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, Theme.Rounding),
            Parent = dropdownList
        })
        
        -- Create option buttons
        for i, option in ipairs(options) do
            local optionButton = CreateInstance("TextButton", {
                Name = "Option_" .. i,
                Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
                Position = UDim2.new(0, 0, 0, (i-1) * Theme.ElementHeight),
                BackgroundTransparency = 1,
                Text = option,
                TextColor3 = Theme.Element.Text,
                Font = Theme.Font,
                TextSize = Theme.TextSize,
                ZIndex = self.WindowsZIndex + 1,
                Parent = dropdownList
            })
            
            -- Highlight selected option
            if i == selectedIndex then
                optionButton.TextColor3 = Theme.Element.Accent
            end
            
            -- Hover effect
            optionButton.MouseEnter:Connect(function()
                optionButton.BackgroundTransparency = 0.8
            end)
            
            optionButton.MouseLeave:Connect(function()
                optionButton.BackgroundTransparency = 1
            end)
            
            -- Select option
            optionButton.MouseButton1Click:Connect(function()
                window.Elements[id].SelectedIndex = i
                selectedText.Text = options[i]
                dropdownList.Visible = false
                
                -- Update highlighting
                for j, child in ipairs(dropdownList:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.TextColor3 = (j == i) and Theme.Element.Accent or Theme.Element.Text
                    end
                end
            end)
        end
        
        -- Make dropdown clickable
        local button = CreateInstance("TextButton", {
            Name = "Button",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = self.WindowsZIndex,
            Parent = dropdown
        })
        
        -- Store element
        window.Elements[id] = {
            Instance = container,
            Dropdown = dropdown,
            DropdownList = dropdownList,
            SelectedText = selectedText,
            Type = "Dropdown",
            SelectedIndex = selectedIndex,
            Options = options,
            IsOpen = false
        }
        
        -- Toggle dropdown list
        button.MouseButton1Click:Connect(function()
            window.Elements[id].IsOpen = not window.Elements[id].IsOpen
            dropdownList.Visible = window.Elements[id].IsOpen
            arrow.Rotation = window.Elements[id].IsOpen and 180 or 0
        end)
        
        -- Close dropdown when clicking elsewhere
        self.InputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = Vector2.new(input.Position.X, input.Position.Y)
                local dropdownPos = dropdown.AbsolutePosition
                local dropdownSize = dropdown.AbsoluteSize
                local listPos = dropdownList.AbsolutePosition
                local listSize = dropdownList.AbsoluteSize
                
                -- Check if click is outside dropdown and list
                if window.Elements[id] and window.Elements[id].IsOpen then
                    if not (mousePos.X >= dropdownPos.X and mousePos.X <= dropdownPos.X + dropdownSize.X and
                           mousePos.Y >= dropdownPos.Y and mousePos.Y <= dropdownPos.Y + dropdownSize.Y) and
                       not (mousePos.X >= listPos.X and mousePos.X <= listPos.X + listSize.X and
                           mousePos.Y >= listPos.Y and mousePos.Y <= listPos.Y + listSize.Y) then
                        window.Elements[id].IsOpen = false
                        dropdownList.Visible = false
                        arrow.Rotation = 0
                    end
                end
            end
        end)
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            dropdown.BackgroundColor3 = Theme.Element.BackgroundHover
        end)
        
        button.MouseLeave:Connect(function()
            dropdown.BackgroundColor3 = Theme.Element.Background
        end)
    else
        container = window.Elements[id].Instance
        dropdown = window.Elements[id].Dropdown
        dropdownList = window.Elements[id].DropdownList
        selectedText = window.Elements[id].SelectedText
        
        -- Update selected index
        if selectedIndex ~= window.Elements[id].SelectedIndex then
            window.Elements[id].SelectedIndex = selectedIndex
            selectedText.Text = options[selectedIndex] or "Select..."
            
            -- Update highlighting
            for i, child in ipairs(dropdownList:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = (i == selectedIndex) and Theme.Element.Accent or Theme.Element.Text
                end
            end
        end
        
        -- Update options if they've changed
        if #options ~= #window.Elements[id].Options then
            -- Clear existing options
            for _, child in ipairs(dropdownList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            -- Create new options
            for i, option in ipairs(options) do
                local optionButton = CreateInstance("TextButton", {
                    Name = "Option_" .. i,
                    Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
                    Position = UDim2.new(0, 0, 0, (i-1) * Theme.ElementHeight),
                    BackgroundTransparency = 1,
                    Text = option,
                    TextColor3 = (i == selectedIndex) and Theme.Element.Accent or Theme.Element.Text,
                    Font = Theme.Font,
                    TextSize = Theme.TextSize,
                    ZIndex = self.WindowsZIndex + 1,
                    Parent = dropdownList
                })
                
                -- Hover effect
                optionButton.MouseEnter:Connect(function()
                    optionButton.BackgroundTransparency = 0.8
                end)
                
                optionButton.MouseLeave:Connect(function()
                    optionButton.BackgroundTransparency = 1
                end)
                
                -- Select option
                optionButton.MouseButton1Click:Connect(function()
                    window.Elements[id].SelectedIndex = i
                    selectedText.Text = options[i]
                    dropdownList.Visible = false
                    
                    -- Update highlighting
                    for j, child in ipairs(dropdownList:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.TextColor3 = (j == i) and Theme.Element.Accent or Theme.Element.Text
                        end
                    end
                end)
            end
            
            -- Update dropdown list size
            dropdownList.Size = UDim2.new(1, 0, 0, #options * Theme.ElementHeight)
            
            -- Update stored options
            window.Elements[id].Options = options
        end
    end
    
    return window.Elements[id].SelectedIndex
end

-- Clean up
function ImGui:Destroy()
    self.ScreenGui:Destroy()
end

-- Set theme
function ImGui:SetTheme(newTheme)
    for k, v in pairs(newTheme) do
        if type(v) == "table" then
            for k2, v2 in pairs(v) do
                Theme[k][k2] = v2
            end
        else
            Theme[k] = v
        end
    end
end

return ImGui
