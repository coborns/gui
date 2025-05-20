-- RoImGUI: A simple ImGUI-inspired library for Roblox
-- Usage: local gui = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourusername/RoImGUI/main/roimgui.lua"))()

local RoImGUI = {}
RoImGUI.__index = RoImGUI

-- Configuration
local config = {
    font = Enum.Font.SourceSans,
    textSize = 14,
    padding = 5,
    margin = 2,
    windowBgColor = Color3.fromRGB(40, 40, 40),
    buttonColor = Color3.fromRGB(60, 60, 60),
    buttonHoverColor = Color3.fromRGB(80, 80, 80),
    textColor = Color3.fromRGB(255, 255, 255),
    sliderBgColor = Color3.fromRGB(30, 30, 30),
    sliderFillColor = Color3.fromRGB(0, 120, 215),
    transparency = 0.1,
}

-- Initialize
function RoImGUI.new(parent)
    local self = setmetatable({}, RoImGUI)
    
    -- Create ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "RoImGUI"
    self.gui.ResetOnSpawn = false
    self.gui.Parent = parent or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- State
    self.windows = {}
    self.activeWindow = nil
    self.lastPos = UDim2.new(0, 0, 0, 0)
    self.idCounter = 0
    self.hoveredElement = nil
    
    return self
end

-- Generate unique ID
function RoImGUI:genID(prefix)
    self.idCounter = self.idCounter + 1
    return (prefix or "elem") .. self.idCounter
end

-- Begin a window
function RoImGUI:begin(title, x, y, width, height)
    local id = title
    
    if not self.windows[id] then
        -- Create window frame
        local window = Instance.new("Frame")
        window.Name = id
        window.Size = UDim2.new(0, width or 200, 0, height or 300)
        window.Position = UDim2.new(0, x or 100, 0, y or 100)
        window.BackgroundColor3 = config.windowBgColor
        window.BackgroundTransparency = config.transparency
        window.BorderSizePixel = 1
        window.Parent = self.gui
        
        -- Create title bar
        local titleBar = Instance.new("TextLabel")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 25)
        titleBar.Position = UDim2.new(0, 0, 0, 0)
        titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        titleBar.BackgroundTransparency = 0
        titleBar.BorderSizePixel = 0
        titleBar.Text = title
        titleBar.TextColor3 = config.textColor
        titleBar.Font = config.font
        titleBar.TextSize = config.textSize
        titleBar.Parent = window
        
        -- Make window draggable
        local dragging = false
        local dragStart, startPos
        
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = window.Position
            end
        end)
        
        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
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
        
        -- Create content container
        local content = Instance.new("ScrollingFrame")
        content.Name = "Content"
        content.Size = UDim2.new(1, 0, 1, -25)
        content.Position = UDim2.new(0, 0, 0, 25)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 4
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.Parent = window
        
        -- Store window data
        self.windows[id] = {
            frame = window,
            content = content,
            lastPos = UDim2.new(0, config.padding, 0, config.padding),
            elements = {}
        }
    end
    
    self.activeWindow = id
    self.lastPos = self.windows[id].lastPos
    
    return true
end

-- End a window
function RoImGUI:end()
    if self.activeWindow then
        local window = self.windows[self.activeWindow]
        window.lastPos = self.lastPos
        window.content.CanvasSize = UDim2.new(0, 0, 0, self.lastPos.Y.Offset + config.padding)
        self.activeWindow = nil
    end
end

-- Button
function RoImGUI:button(label)
    if not self.activeWindow then return false end
    
    local window = self.windows[self.activeWindow]
    local id = self:genID("btn_" .. label)
    
    -- Create or get button
    local button
    if not window.elements[id] then
        button = Instance.new("TextButton")
        button.Name = id
        button.Size = UDim2.new(1, -config.padding * 2, 0, 25)
        button.Position = self.lastPos
        button.BackgroundColor3 = config.buttonColor
        button.BorderSizePixel = 1
        button.Text = label
        button.TextColor3 = config.textColor
        button.Font = config.font
        button.TextSize = config.textSize
        button.Parent = window.content
        
        window.elements[id] = button
    else
        button = window.elements[id]
        button.Position = self.lastPos
    end
    
    -- Update last position
    self.lastPos = UDim2.new(0, config.padding, 0, self.lastPos.Y.Offset + button.Size.Y.Offset + config.margin)
    
    -- Handle hover effect
    local clicked = false
    local hovered = false
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = config.buttonHoverColor
        hovered = true
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = config.buttonColor
        hovered = false
    end)
    
    button.MouseButton1Click:Connect(function()
        clicked = true
    end)
    
    return clicked
end

-- Text
function RoImGUI:text(text)
    if not self.activeWindow then return end
    
    local window = self.windows[self.activeWindow]
    local id = self:genID("txt_" .. text:sub(1, 10))
    
    -- Create or get text label
    local label
    if not window.elements[id] then
        label = Instance.new("TextLabel")
        label.Name = id
        label.Size = UDim2.new(1, -config.padding * 2, 0, 20)
        label.Position = self.lastPos
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = config.textColor
        label.Font = config.font
        label.TextSize = config.textSize
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = window.content
        
        window.elements[id] = label
    else
        label = window.elements[id]
        label.Position = self.lastPos
        label.Text = text
    end
    
    -- Update last position
    self.lastPos = UDim2.new(0, config.padding, 0, self.lastPos.Y.Offset + label.Size.Y.Offset + config.margin)
end

-- Slider
function RoImGUI:slider(label, min, max, value)
    if not self.activeWindow then return value end
    
    local window = self.windows[self.activeWindow]
    local id = self:genID("slider_" .. label)
    
    -- Create container
    local container
    local sliderBg
    local sliderFill
    local sliderText
    
    if not window.elements[id] then
        container = Instance.new("Frame")
        container.Name = id
        container.Size = UDim2.new(1, -config.padding * 2, 0, 40)
        container.Position = self.lastPos
        container.BackgroundTransparency = 1
        container.Parent = window.content
        
        -- Label
        local labelText = Instance.new("TextLabel")
        labelText.Name = "Label"
        labelText.Size = UDim2.new(1, 0, 0, 20)
        labelText.Position = UDim2.new(0, 0, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label .. ": " .. value
        labelText.TextColor3 = config.textColor
        labelText.Font = config.font
        labelText.TextSize = config.textSize
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = container
        
        -- Slider background
        sliderBg = Instance.new("Frame")
        sliderBg.Name = "Background"
        sliderBg.Size = UDim2.new(1, 0, 0, 10)
        sliderBg.Position = UDim2.new(0, 0, 0, 25)
        sliderBg.BackgroundColor3 = config.sliderBgColor
        sliderBg.BorderSizePixel = 1
        sliderBg.Parent = container
        
        -- Slider fill
        sliderFill = Instance.new("Frame")
        sliderFill.Name = "Fill"
        sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        sliderFill.Position = UDim2.new(0, 0, 0, 0)
        sliderFill.BackgroundColor3 = config.sliderFillColor
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBg
        
        sliderText = labelText
        
        window.elements[id] = {
            container = container,
            bg = sliderBg,
            fill = sliderFill,
            text = sliderText,
            value = value
        }
    else
        local elem = window.elements[id]
        container = elem.container
        sliderBg = elem.bg
        sliderFill = elem.fill
        sliderText = elem.text
        
        container.Position = self.lastPos
        sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        sliderText.Text = label .. ": " .. value
        elem.value = value
    end
    
    -- Update last position
    self.lastPos = UDim2.new(0, config.padding, 0, self.lastPos.Y.Offset + container.Size.Y.Offset + config.margin)
    
    -- Handle slider interaction
    local newValue = value
    local dragging = false
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            
            -- Calculate new value based on mouse position
            local relX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            newValue = min + relX * (max - min)
            newValue = math.floor(newValue * 100) / 100 -- Round to 2 decimal places
            
            -- Update slider
            sliderFill.Size = UDim2.new(relX, 0, 1, 0)
            sliderText.Text = label .. ": " .. newValue
            window.elements[id].value = newValue
        end
    end)
    
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Calculate new value based on mouse position
            local relX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            newValue = min + relX * (max - min)
            newValue = math.floor(newValue * 100) / 100 -- Round to 2 decimal places
            
            -- Update slider
            sliderFill.Size = UDim2.new(relX, 0, 1, 0)
            sliderText.Text = label .. ": " .. newValue
            window.elements[id].value = newValue
        end
    end)
    
    return newValue
end

-- Checkbox
function RoImGUI:checkbox(label, checked)
    if not self.activeWindow then return checked end
    
    local window = self.windows[self.activeWindow]
    local id = self:genID("chk_" .. label)
    
    -- Create container
    local container
    local box
    local text
    
    if not window.elements[id] then
        container = Instance.new("Frame")
        container.Name = id
        container.Size = UDim2.new(1, -config.padding * 2, 0, 25)
        container.Position = self.lastPos
        container.BackgroundTransparency = 1
        container.Parent = window.content
        
        -- Checkbox
        box = Instance.new("TextButton")
        box.Name = "Box"
        box.Size = UDim2.new(0, 20, 0, 20)
        box.Position = UDim2.new(0, 0, 0, 0)
        box.BackgroundColor3 = checked and config.sliderFillColor or config.buttonColor
        box.BorderSizePixel = 1
        box.Text = checked and "✓" or ""
        box.TextColor3 = config.textColor
        box.Font = config.font
        box.TextSize = config.textSize
        box.Parent = container
        
        -- Label
        text = Instance.new("TextLabel")
        text.Name = "Label"
        text.Size = UDim2.new(1, -25, 1, 0)
        text.Position = UDim2.new(0, 25, 0, 0)
        text.BackgroundTransparency = 1
        text.Text = label
        text.TextColor3 = config.textColor
        text.Font = config.font
        text.TextSize = config.textSize
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.Parent = container
        
        window.elements[id] = {
            container = container,
            box = box,
            text = text,
            checked = checked
        }
    else
        local elem = window.elements[id]
        container = elem.container
        box = elem.box
        text = elem.text
        
        container.Position = self.lastPos
        box.BackgroundColor3 = checked and config.sliderFillColor or config.buttonColor
        box.Text = checked and "✓" or ""
        elem.checked = checked
    end
    
    -- Update last position
    self.lastPos = UDim2.new(0, config.padding, 0, self.lastPos.Y.Offset + container.Size.Y.Offset + config.margin)
    
    -- Handle checkbox interaction
    local newChecked = checked
    
    box.MouseButton1Click:Connect(function()
        newChecked = not newChecked
        box.BackgroundColor3 = newChecked and config.sliderFillColor or config.buttonColor
        box.Text = newChecked and "✓" or ""
        window.elements[id].checked = newChecked
    end)
    
    return newChecked
end

-- Separator
function RoImGUI:separator()
    if not self.activeWindow then return end
    
    local window = self.windows[self.activeWindow]
    local id = self:genID("sep")
    
    -- Create separator
    local separator
    if not window.elements[id] then
        separator = Instance.new("Frame")
        separator.Name = id
        separator.Size = UDim2.new(1, -config.padding * 2, 0, 1)
        separator.Position = self.lastPos
        separator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        separator.BorderSizePixel = 0
        separator.Parent = window.content
        
        window.elements[id] = separator
    else
        separator = window.elements[id]
        separator.Position = self.lastPos
    end
    
    -- Update last position
    self.lastPos = UDim2.new(0, config.padding, 0, self.lastPos.Y.Offset + separator.Size.Y.Offset + config.margin)
end

-- Input field
function RoImGUI:input(label, text)
    if not self.activeWindow then return text end
    
    local window = self.windows[self.activeWindow]
    local id = self:genID("input_" .. label)
    
    -- Create container
    local container
    local textBox
    local labelText
    
    if not window.elements[id] then
        container = Instance.new("Frame")
        container.Name = id
        container.Size = UDim2.new(1, -config.padding * 2, 0, 45)
        container.Position = self.lastPos
        container.BackgroundTransparency = 1
        container.Parent = window.content
        
        -- Label
        labelText = Instance.new("TextLabel")
        labelText.Name = "Label"
        labelText.Size = UDim2.new(1, 0, 0, 20)
        labelText.Position = UDim2.new(0, 0, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextColor3 = config.textColor
        labelText.Font = config.font
        labelText.TextSize = config.textSize
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = container
        
        -- TextBox
        textBox = Instance.new("TextBox")
        textBox.Name = "TextBox"
        textBox.Size = UDim2.new(1, 0, 0, 25)
        textBox.Position = UDim2.new(0, 0, 0, 20)
        textBox.BackgroundColor3 = config.buttonColor
        textBox.BorderSizePixel = 1
        textBox.Text = text or ""
        textBox.TextColor3 = config.textColor
        textBox.Font = config.font
        textBox.TextSize = config.textSize
        textBox.ClearTextOnFocus = false
        textBox.Parent = container
        
        window.elements[id] = {
            container = container,
            textBox = textBox,
            label = labelText,
            text = text or ""
        }
    else
        local elem = window.elements[id]
        container = elem.container
        textBox = elem.textBox
        labelText = elem.label
        
        container.Position = self.lastPos
        textBox.Text = text or elem.text
        elem.text = text or elem.text
    end
    
    -- Update last position
    self.lastPos = UDim2.new(0, config.padding, 0, self.lastPos.Y.Offset + container.Size.Y.Offset + config.margin)
    
    -- Handle text input
    local newText = text or ""
    
    textBox.FocusLost:Connect(function()
        newText = textBox.Text
        window.elements[id].text = newText
    end)
    
    return newText
end

-- Clean up
function RoImGUI:destroy()
    self.gui:Destroy()
end

return RoImGUI
