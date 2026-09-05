--[[
    MinhoHub - Universal Executor Support
    Delta, RealModium, Bolt, Synapse, Fluxus compatible
]]

local suc = pcall(function()
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local CoreGui = game:GetService("CoreGui")
    local HttpService = game:GetService("HttpService")
    local Camera = workspace.CurrentCamera
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui", 5)
    
    local fileSystem = {
        writefile = writefile or (function() end),
        readfile = readfile or (function() end),
        isfile = isfile or (function() return false end),
        isfolder = isfolder or (function() return false end),
        listfiles = listfiles or (function() return {} end),
        makefolder = makefolder or (function() end),
        delfile = delfile or (function() end)
    }
    
    local function Cleanup()
        local names = {"YokaiGridUI", "YokaiESP_Overlay", "UltimateCrosshairGui", "YokaiMobileToggle"}
        for _, name in ipairs(names) do
            pcall(function()
                if playerGui:FindFirstChild(name) then playerGui[name]:Destroy() end
                if CoreGui:FindFirstChild(name) then CoreGui[name]:Destroy() end
            end)
        end
    end
    Cleanup()
    
    local Config = {
        HubName = "minhohub",
        NameFont = Enum.Font.GothamBold,
        NameFontSize = 14,
        Crosshair = {
            Enabled = true,
            ShowName = true,
            AlwaysCenter = true,
            Length = 20,
            Thickness = 2,
            Gap = 10,
            Speed = 35,
            Rainbow = true,
            ColorR = 255,
            ColorG = 255,
            ColorB = 255
        },
        Aimbot = { 
            Enabled = false, 
            RageMode = false, 
            Smoothness = 25, 
            DrKyoung = false,
            MinhoRage = false
        },
        RageKill = { Enabled = false, AutoShoot = false },
        Misc = { VoidSpam = false, VoidSpeed = 100 },
        ESP = { Boxes = false, Names = false, HealthBars = false },
        Visuals = {
            Wings = false,
            Halo = false,
            FloorAura = false,
            YokaiAura = false,
            ToxicWastelandHorns = false
        },
        World = { GlobalShadows = false, ClockTime = 14, FogEnd = 100000 }
    }
    
    local configFolder = "Yokai_Configs"
    local autoLoadFile = configFolder .. "/AutoLoad.txt"
    
    if fileSystem.makefolder and fileSystem.isfolder then
        pcall(function()
            if not fileSystem.isfolder(configFolder) then
                fileSystem.makefolder(configFolder)
            end
        end)
    end
    
    local function GetConfigList()
        local list = {}
        if fileSystem.listfiles and fileSystem.isfolder then
            pcall(function()
                if fileSystem.isfolder(configFolder) then
                    for _, path in ipairs(fileSystem.listfiles(configFolder)) do
                        if path:sub(-5) == ".json" then
                            local name = path:match("([^/^\\]+)%.json$") or path:sub(#configFolder + 2, -6)
                            table.insert(list, name)
                        end
                    end
                end
            end)
        end
        if #list == 0 then table.insert(list, "default") end
        return list
    end
    
    local updateDropdownUI
    
    local function ApplyCharacterEffects(character)
        if not character then return end
        
        task.spawn(function()
            local rootPart = character:WaitForChild("HumanoidRootPart", 5)
            local head = character:WaitForChild("Head", 5)
            local humanoid = character:WaitForChild("Humanoid", 5)
            local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or rootPart
            
            if not rootPart or not head or not humanoid then return end

            for _, v in pairs(character:GetDescendants()) do
                if v.Name == "YokaiCustomEffectAttachment" or v.Name == "ToxicWastelandHornsAccessory" then
                    pcall(function() v:Destroy() end)
                end
            end

            if Config.Visuals.ToxicWastelandHorns then
                pcall(function()
                    local accessory = Instance.new("Accessory")
                    accessory.Name = "ToxicWastelandHornsAccessory"

                    local handle = Instance.new("Part")
                    handle.Name = "Handle"
                    handle.Size = Vector3.new(1, 1, 1)
                    handle.CanCollide = false
                    handle.Massless = true

                    local mesh = Instance.new("SpecialMesh", handle)
                    mesh.MeshId = "rbxassetid://1744060292"
                    mesh.TextureId = "rbxassetid://1744060303"
                    mesh.Scale = Vector3.new(1, 1, 1)

                    local accAttachment = Instance.new("Attachment")
                    accAttachment.Name = "HatAttachment"
                    accAttachment.Position = Vector3.new(0, 0.6, 0)
                    accAttachment.Parent = handle

                    handle.Parent = accessory
                    accessory.Parent = character
                    humanoid:AddAccessory(accessory)
                end)
            end

            if Config.Visuals.Wings then
                pcall(function()
                    local leftAtt = Instance.new("Attachment")
                    leftAtt.Name = "YokaiCustomEffectAttachment"
                    leftAtt.Position = Vector3.new(-1.2, 0.8, 0.6)
                    leftAtt.Parent = torso

                    local rightAtt = Instance.new("Attachment")
                    rightAtt.Name = "YokaiCustomEffectAttachment"
                    rightAtt.Position = Vector3.new(1.2, 0.8, 0.6)
                    rightAtt.Parent = torso

                    local function setupWing(att)
                        local emitter = Instance.new("ParticleEmitter")
                        emitter.Name = "AngelWingEmitter"
                        emitter.Texture = "rbxassetid://258122325"
                        emitter.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 180)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 170, 40)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 0))
                        })
                        emitter.Size = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1.5),
                            NumberSequenceKeypoint.new(0.6, 4.5),
                            NumberSequenceKeypoint.new(1, 0)
                        })
                        emitter.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.1),
                            NumberSequenceKeypoint.new(0.8, 0.3),
                            NumberSequenceKeypoint.new(1, 1)
                        })
                        emitter.Lifetime = NumberRange.new(0.6, 1.0)
                        emitter.Rate = 60
                        emitter.Speed = NumberRange.new(2, 4)
                        emitter.SpreadAngle = Vector2.new(25, 25)
                        emitter.VelocityInheritance = 0.2
                        emitter.LightEmission = 0.95
                        emitter.LightInfluence = 0
                        emitter.Orientation = Enum.ParticleOrientation.FacingCamera
                        emitter.Parent = att
                    end

                    setupWing(leftAtt)
                    setupWing(rightAtt)
                end)
            end

            if Config.Visuals.Halo then
                pcall(function()
                    local att = Instance.new("Attachment")
                    att.Name = "YokaiCustomEffectAttachment"
                    att.Position = Vector3.new(0, 1.8, 0)
                    att.Parent = head

                    local haloEmitter = Instance.new("ParticleEmitter")
                    haloEmitter.Name = "AngelHaloEmitter"
                    haloEmitter.Texture = "rbxassetid://284205403"
                    haloEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100))
                    haloEmitter.Size = NumberSequence.new(2.8, 2.8)
                    haloEmitter.Transparency = NumberSequence.new(0.1)
                    haloEmitter.Lifetime = NumberRange.new(0.1, 0.15)
                    haloEmitter.Rate = 40
                    haloEmitter.Speed = NumberRange.new(0)
                    haloEmitter.LightEmission = 1
                    haloEmitter.Parent = att
                end)
            end

            if Config.Visuals.FloorAura then
                pcall(function()
                    local att = Instance.new("Attachment")
                    att.Name = "YokaiCustomEffectAttachment"
                    att.Position = Vector3.new(0, -2.8, 0)
                    att.Parent = rootPart

                    local auraEmitter = Instance.new("ParticleEmitter")
                    auraEmitter.Name = "FloorAuraEmitter"
                    auraEmitter.Texture = "rbxassetid://258122325"
                    auraEmitter.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
                    auraEmitter.Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.5),
                        NumberSequenceKeypoint.new(0.5, 2),
                        NumberSequenceKeypoint.new(1, 3)
                    })
                    auraEmitter.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.3),
                        NumberSequenceKeypoint.new(0.7, 0.6),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    auraEmitter.Lifetime = NumberRange.new(0.8, 1.2)
                    auraEmitter.Rate = 50
                    auraEmitter.Speed = NumberRange.new(3, 5)
                    auraEmitter.SpreadAngle = Vector2.new(45, 45)
                    auraEmitter.LightEmission = 0.5
                    auraEmitter.Parent = att
                end)
            end

            if Config.Visuals.YokaiAura then
                pcall(function()
                    local att = Instance.new("Attachment")
                    att.Name = "YokaiCustomEffectAttachment"
                    att.Position = Vector3.new(0, 0, 0)
                    att.Parent = rootPart

                    local yokaiEmitter = Instance.new("ParticleEmitter")
                    yokaiEmitter.Name = "YokaiAuraEmitter"
                    yokaiEmitter.Texture = "rbxassetid://258122325"
                    yokaiEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 100, 255))
                    yokaiEmitter.Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 3),
                        NumberSequenceKeypoint.new(1, 2)
                    })
                    yokaiEmitter.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.2),
                        NumberSequenceKeypoint.new(0.5, 0.4),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    yokaiEmitter.Lifetime = NumberRange.new(1, 1.5)
                    yokaiEmitter.Rate = 40
                    yokaiEmitter.Speed = NumberRange.new(2, 4)
                    yokaiEmitter.SpreadAngle = Vector2.new(30, 30)
                    yokaiEmitter.LightEmission = 0.7
                    yokaiEmitter.Parent = att
                end)
            end
        end)
    end

    local function SaveConfig(name)
        if not fileSystem.writefile then return end
        pcall(function()
            if not HttpService then return end
            local data = HttpService:JSONEncode(Config)
            fileSystem.writefile(configFolder .. "/" .. name .. ".json", data)
        end)
    end

    local function LoadConfig(name)
        if not fileSystem.readfile then return end
        pcall(function()
            if not HttpService then return end
            local data = fileSystem.readfile(configFolder .. "/" .. name .. ".json")
            local loaded = HttpService:JSONDecode(data)
            for key, value in pairs(loaded) do
                if type(value) == "table" and Config[key] then
                    for k, v in pairs(value) do
                        Config[key][k] = v
                    end
                else
                    Config[key] = value
                end
            end
            if updateDropdownUI then
                updateDropdownUI(GetConfigList())
            end
        end)
    end

    local function DeleteConfig(name)
        if not fileSystem.isfile or not fileSystem.delfile then return end
        pcall(function()
            if fileSystem.isfile(configFolder .. "/" .. name .. ".json") then
                fileSystem.delfile(configFolder .. "/" .. name .. ".json")
            end
        end)
        if updateDropdownUI then
            updateDropdownUI(GetConfigList())
        end
    end

    local function SetAutoLoad(name)
        if not fileSystem.writefile then return end
        pcall(function()
            fileSystem.writefile(autoLoadFile, name)
        end)
    end

    local function ClearAutoLoad()
        if not fileSystem.isfile or not fileSystem.delfile then return end
        pcall(function()
            if fileSystem.isfile(autoLoadFile) then
                fileSystem.delfile(autoLoadFile)
            end
        end)
    end

    local function LoadAutoConfig()
        if not fileSystem.readfile or not fileSystem.isfile then return end
        pcall(function()
            if fileSystem.isfile(autoLoadFile) then
                local name = fileSystem.readfile(autoLoadFile):match("^%s*(.-)%s*$")
                if name and name ~= "" then
                    LoadConfig(name)
                end
            end
        end)
    end

    LoadAutoConfig()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "YokaiGridUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 1000, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -500, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false

    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleBar.BorderSizePixel = 0

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Text = "MinhoHub"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Position = UDim2.new(0, 10, 0, 0)

    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -30, 0, 0)
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)

    local tabHolder = Instance.new("Frame", mainFrame)
    tabHolder.Name = "TabHolder"
    tabHolder.Size = UDim2.new(0, 120, 1, -30)
    tabHolder.Position = UDim2.new(0, 0, 0, 30)
    tabHolder.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    tabHolder.BorderSizePixel = 0

    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -120, 1, -30)
    contentFrame.Position = UDim2.new(0, 120, 0, 30)
    contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    contentFrame.BorderSizePixel = 0

    local tabs = {}
    local currentTab = nil

    local function createTab(name)
        local tabBtn = Instance.new("TextButton", tabHolder)
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabBtn.TextSize = 11
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        tabBtn.BorderSizePixel = 0
        tabBtn.Size = UDim2.new(1, 0, 0, 40)
        tabBtn.Position = UDim2.new(0, 0, 0, (#tabs * 40))

        local tabContent = Instance.new("ScrollingFrame", contentFrame)
        tabContent.Name = name
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 8
        tabContent.Visible = false
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)

        tabBtn.MouseButton1Click:Connect(function()
            if currentTab then
                currentTab.Visible = false
            end
            tabContent.Visible = true
            currentTab = tabContent
        end)

        table.insert(tabs, {button = tabBtn, content = tabContent})
        return tabContent
    end

    local function createSectionBox(parent, title, size, position)
        local section = Instance.new("Frame", parent)
        section.Size = size
        section.Position = position
        section.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        section.BorderSizePixel = 1
        section.BorderColor3 = Color3.fromRGB(60, 60, 60)

        local titleLabel = Instance.new("TextLabel", section)
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 12
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        titleLabel.BorderSizePixel = 0
        titleLabel.Size = UDim2.new(1, 0, 0, 20)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Position = UDim2.new(0, 5, 0, 0)

        local contentContainer = Instance.new("Frame", section)
        contentContainer.Size = UDim2.new(1, -10, 1, -25)
        contentContainer.Position = UDim2.new(0, 5, 0, 25)
        contentContainer.BackgroundTransparency = 1
        contentContainer.BorderSizePixel = 0

        return contentContainer
    end

    local function addCheckbox(parent, label, default, callback)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 25)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.Position = UDim2.new(0, 0, 0, (#parent:GetChildren() * 25))

        local checkbox = Instance.new("TextButton", container)
        checkbox.Text = ""
        checkbox.Size = UDim2.new(0, 20, 0, 20)
        checkbox.BackgroundColor3 = default and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 60)
        checkbox.BorderSizePixel = 1
        checkbox.BorderColor3 = Color3.fromRGB(100, 100, 100)

        local labelText = Instance.new("TextLabel", container)
        labelText.Text = label
        labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
        labelText.TextSize = 11
        labelText.Font = Enum.Font.GothamBold
        labelText.BackgroundTransparency = 1
        labelText.BorderSizePixel = 0
        labelText.Size = UDim2.new(1, -30, 1, 0)
        labelText.Position = UDim2.new(0, 30, 0, 0)
        labelText.TextXAlignment = Enum.TextXAlignment.Left

        local state = default
        checkbox.MouseButton1Click:Connect(function()
            state = not state
            checkbox.BackgroundColor3 = state and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 60)
            callback(state)
        end)
    end

    local function addSlider(parent, label, min, max, default, callback)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 40)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.Position = UDim2.new(0, 0, 0, (#parent:GetChildren() * 25))

        local labelText = Instance.new("TextLabel", container)
        labelText.Text = label
        labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
        labelText.TextSize = 11
        labelText.Font = Enum.Font.GothamBold
        labelText.BackgroundTransparency = 1
        labelText.BorderSizePixel = 0
        labelText.Size = UDim2.new(1, 0, 0, 15)
        labelText.TextXAlignment = Enum.TextXAlignment.Left

        local sliderBg = Instance.new("Frame", container)
        sliderBg.Size = UDim2.new(1, 0, 0, 6)
        sliderBg.Position = UDim2.new(0, 0, 0, 20)
        sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        sliderBg.BorderSizePixel = 0

        local sliderFill = Instance.new("Frame", sliderBg)
        sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        sliderFill.BorderSizePixel = 0

        local valueLabel = Instance.new("TextLabel", container)
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        valueLabel.TextSize = 10
        valueLabel.Font = Enum.Font.Code
        valueLabel.BackgroundTransparency = 1
        valueLabel.BorderSizePixel = 0
        valueLabel.Size = UDim2.new(0, 50, 0, 15)
        valueLabel.Position = UDim2.new(1, -50, 0, 0)

        sliderBg.MouseButton1Down:Connect(function()
            local dragging = true
            local mouse = game:GetService("Mouse")
            
            local function update()
                local relPos = math.clamp(mouse.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
                local percent = relPos / sliderBg.AbsoluteSize.X
                local value = math.floor(min + (max - min) * percent)
                sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                valueLabel.Text = tostring(value)
                callback(value)
            end

            while dragging do
                update()
                game:GetService("RunService").RenderStepped:Wait()
            end
        end)

        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    local function addButton(parent, label, callback)
        local button = Instance.new("TextButton", parent)
        button.Text = label
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 11
        button.Font = Enum.Font.GothamBold
        button.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
        button.BorderSizePixel = 1
        button.BorderColor3 = Color3.fromRGB(100, 150, 200)
        button.Size = UDim2.new(1, 0, 0, 25)
        button.Position = UDim2.new(0, 0, 0, (#parent:GetChildren() * 25))
        
        button.MouseButton1Click:Connect(callback)
    end

    local function addTextBox(parent, placeholder, callback)
        local textBox = Instance.new("TextBox", parent)
        textBox.PlaceholderText = placeholder
        textBox.Text = ""
        textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        textBox.TextSize = 11
        textBox.Font = Enum.Font.Code
        textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        textBox.BorderSizePixel = 1
        textBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
        textBox.Size = UDim2.new(1, 0, 0, 25)
        textBox.Position = UDim2.new(0, 0, 0, (#parent:GetChildren() * 25))
        
        textBox.FocusLost:Connect(function()
            callback(textBox.Text)
        end)
    end

    local function addDropdown(parent, label, options, callback)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 25)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.Position = UDim2.new(0, 0, 0, (#parent:GetChildren() * 25))

        local labelText = Instance.new("TextLabel", container)
        labelText.Text = label
        labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
        labelText.TextSize = 11
        labelText.Font = Enum.Font.GothamBold
        labelText.BackgroundTransparency = 1
        labelText.BorderSizePixel = 0
        labelText.Size = UDim2.new(0, 120, 0, 25)
        labelText.TextXAlignment = Enum.TextXAlignment.Left

        local dropdownBtn = Instance.new("TextButton", container)
        dropdownBtn.Text = options[1] or "Select"
        dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropdownBtn.TextSize = 10
        dropdownBtn.Font = Enum.Font.Code
        dropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        dropdownBtn.BorderSizePixel = 1
        dropdownBtn.BorderColor3 = Color3.fromRGB(100, 100, 100)
        dropdownBtn.Size = UDim2.new(1, -130, 0, 25)
        dropdownBtn.Position = UDim2.new(0, 125, 0, 0)

        local dropdownMenu = Instance.new("Frame", container)
        dropdownMenu.Size = UDim2.new(1, -130, 0, 0)
        dropdownMenu.Position = UDim2.new(0, 125, 0, 25)
        dropdownMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        dropdownMenu.BorderSizePixel = 1
        dropdownMenu.BorderColor3 = Color3.fromRGB(100, 100, 100)
        dropdownMenu.Visible = false
        dropdownMenu.ClipsDescendants = true

        local isOpen = false
        dropdownBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            dropdownMenu.Visible = isOpen
            if isOpen then
                dropdownMenu.Size = UDim2.new(1, -130, 0, #options * 20)
            else
                dropdownMenu.Size = UDim2.new(1, -130, 0, 0)
            end
        end)

        local function updateDropdown(newOptions)
            options = newOptions
            for _, child in pairs(dropdownMenu:GetChildren()) do
                child:Destroy()
            end
            for i, option in pairs(options) do
                local optionBtn = Instance.new("TextButton", dropdownMenu)
                optionBtn.Text = option
                optionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                optionBtn.TextSize = 10
                optionBtn.Font = Enum.Font.Code
                optionBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                optionBtn.BorderSizePixel = 0
                optionBtn.Size = UDim2.new(1, 0, 0, 20)
                optionBtn.Position = UDim2.new(0, 0, 0, (i-1) * 20)
                optionBtn.MouseButton1Click:Connect(function()
                    dropdownBtn.Text = option
                    callback(option)
                    isOpen = false
                    dropdownMenu.Visible = false
                    dropdownMenu.Size = UDim2.new(1, -130, 0, 0)
                end)
            end
        end

        updateDropdown(options)
        return updateDropdown
    end

    local aimPage = createTab("Aimbot")
    local aimSec1 = createSectionBox(aimPage, "Main Settings", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))
    addCheckbox(aimSec1, "Aimbot Enabled", Config.Aimbot.Enabled, function(v) Config.Aimbot.Enabled = v end)
    addCheckbox(aimSec1, "Rage Mode", Config.Aimbot.RageMode, function(v) Config.Aimbot.RageMode = v end)
    addSlider(aimSec1, "Smoothness", 1, 100, Config.Aimbot.Smoothness, function(v) Config.Aimbot.Smoothness = v end)

    local aimSec2 = createSectionBox(aimPage, "Special Modes", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0.52, 0, 0, 0))
    addCheckbox(aimSec2, "Dr. Kyoung Mode", Config.Aimbot.DrKyoung, function(v) Config.Aimbot.DrKyoung = v end)
    addCheckbox(aimSec2, "MinhoHub Rage", Config.Aimbot.MinhoRage, function(v) Config.Aimbot.MinhoRage = v end)

    local crosshairPage = createTab("Crosshair")
    local crossSec1 = createSectionBox(crosshairPage, "Display", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))
    addCheckbox(crossSec1, "Show Crosshair", Config.Crosshair.Enabled, function(v) Config.Crosshair.Enabled = v end)
    addCheckbox(crossSec1, "Show Center Name", Config.Crosshair.ShowName, function(v) Config.Crosshair.ShowName = v end)
    addSlider(crossSec1, "Length", 5, 50, Config.Crosshair.Length, function(v) Config.Crosshair.Length = v end)

    local crossSec2 = createSectionBox(crosshairPage, "Styling", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0.52, 0, 0, 0))
    addSlider(crossSec2, "Thickness", 1, 10, Config.Crosshair.Thickness, function(v) Config.Crosshair.Thickness = v end)
    addSlider(crossSec2, "Gap", 0, 30, Config.Crosshair.Gap, function(v) Config.Crosshair.Gap = v end)
    addCheckbox(crossSec2, "Rainbow Colors", Config.Crosshair.Rainbow, function(v) Config.Crosshair.Rainbow = v end)

    local crossSec3 = createSectionBox(crosshairPage, "Custom Colors", UDim2.new(0.98, 0, 0.4, 0), UDim2.new(0, 0, 0.55, 0))
    addSlider(crossSec3, "Red", 0, 255, Config.Crosshair.ColorR, function(v) Config.Crosshair.ColorR = v end)
    addSlider(crossSec3, "Green", 0, 255, Config.Crosshair.ColorG, function(v) Config.Crosshair.ColorG = v end)
    addSlider(crossSec3, "Blue", 0, 255, Config.Crosshair.ColorB, function(v) Config.Crosshair.ColorB = v end)

    local visualsPage = createTab("Visuals")
    local vizSec1 = createSectionBox(visualsPage, "Character Effects", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))
    addCheckbox(vizSec1, "Wings", Config.Visuals.Wings, function(v) Config.Visuals.Wings = v; ApplyCharacterEffects(player.Character) end)
    addCheckbox(vizSec1, "Halo", Config.Visuals.Halo, function(v) Config.Visuals.Halo = v; ApplyCharacterEffects(player.Character) end)
    addCheckbox(vizSec1, "Floor Aura", Config.Visuals.FloorAura, function(v) Config.Visuals.FloorAura = v; ApplyCharacterEffects(player.Character) end)

    local vizSec2 = createSectionBox(visualsPage, "Accessories", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0.52, 0, 0, 0))
    addCheckbox(vizSec2, "Yokai Aura", Config.Visuals.YokaiAura, function(v) Config.Visuals.YokaiAura = v; ApplyCharacterEffects(player.Character) end)
    addCheckbox(vizSec2, "Toxic Wastelands Horns", Config.Visuals.ToxicWastelandHorns, function(v) Config.Visuals.ToxicWastelandHorns = v; ApplyCharacterEffects(player.Character) end)

    local espPage = createTab("ESP")
    local espSec = createSectionBox(espPage, "Enemy Visualization", UDim2.new(0.98, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))
    addCheckbox(espSec, "ESP Boxes", Config.ESP.Boxes, function(v) Config.ESP.Boxes = v end)
    addCheckbox(espSec, "ESP Names", Config.ESP.Names, function(v) Config.ESP.Names = v end)
    addCheckbox(espSec, "Health Bars", Config.ESP.HealthBars, function(v) Config.ESP.HealthBars = v end)

    local miscPage = createTab("Misc")
    local miscSec1 = createSectionBox(miscPage, "Utility Options", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))
    addCheckbox(miscSec1, "Void Spam Exploit", Config.Misc.VoidSpam, function(v) Config.Misc.VoidSpam = v end)
    addSlider(miscSec1, "Void Speed", 10, 500, Config.Misc.VoidSpeed, function(v) Config.Misc.VoidSpeed = v end)

    local miscSec2 = createSectionBox(miscPage, "World Lighting", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0.52, 0, 0, 0))
    addCheckbox(miscSec2, "Global Shadows", Config.World.GlobalShadows, function(v) Lighting.GlobalShadows = v end)
    addSlider(miscSec2, "Time of Day", 0, 24, Config.World.ClockTime, function(v) Lighting.ClockTime = v end)

    local cfgPage = createTab("Config")
    local cfgSec = createSectionBox(cfgPage, "Configuration Manager", UDim2.new(0.98, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))

    local selectedConfig = "default"
    local configNameInput = "default"

    addTextBox(cfgSec, "Config Name (e.g. MyConfig)", function(txt)
        configNameInput = txt
    end)

    updateDropdownUI = addDropdown(cfgSec, "Select Config File", GetConfigList(), function(chosen)
        selectedConfig = chosen
    end)

    addButton(cfgSec, "Save Selected / Typed Config", function()
        local target = (configNameInput ~= "" and configNameInput) or selectedConfig
        SaveConfig(target)
    end)

    addButton(cfgSec, "Load Selected Config", function()
        LoadConfig(selectedConfig)
    end)

    addButton(cfgSec, "Delete Selected Config", function()
        DeleteConfig(selectedConfig)
    end)

    addButton(cfgSec, "Set Auto-Load for Selected", function()
        SetAutoLoad(selectedConfig)
    end)

    addButton(cfgSec, "Clear Auto-Load Setting", function()
        ClearAutoLoad()
    end)

    if tabs[1] then
        tabs[1].content.Visible = true
        currentTab = tabs[1].content
    end

    local espFolder = Instance.new("Folder", playerGui)
    espFolder.Name = "YokaiESP_Overlay"

    pcall(function()
        RunService.RenderStepped:Connect(function()
            espFolder:ClearAllChildren()
            if not (Config.ESP.Boxes or Config.ESP.Names or Config.ESP.HealthBars) then return end

            for _, target in ipairs(Players:GetPlayers()) do
                if target ~= player and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") then
                    local char = target.Character
                    local hrp = char.HumanoidRootPart
                    local hum = char.Humanoid

                    if hum.Health > 0 then
                        local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local head = char:FindFirstChild("Head")
                            local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or vector
                            local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                            local height = math.abs(headPos.Y - legPos.Y)
                            local width = height * 0.65

                            local boxFrame = Instance.new("Frame", espFolder)
                            boxFrame.Position = UDim2.new(0, vector.X - width / 2, 0, vector.Y - height / 2)
                            boxFrame.Size = UDim2.new(0, width, 0, height)
                            boxFrame.BackgroundTransparency = 1

                            if Config.ESP.Boxes then
                                local stroke = Instance.new("UIStroke", boxFrame)
                                stroke.Thickness = 1.5
                                stroke.Color = Color3.fromRGB(255, 140, 0)
                            end

                            if Config.ESP.Names then
                                local nameLbl = Instance.new("TextLabel", boxFrame)
                                nameLbl.Size = UDim2.new(1, 0, 0, 14)
                                nameLbl.Position = UDim2.new(0, 0, 0, -16)
                                nameLbl.BackgroundTransparency = 1
                                nameLbl.Text = target.DisplayName
                                nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                                nameLbl.TextSize = 10
                                nameLbl.Font = Enum.Font.Code
                            end

                            if Config.ESP.HealthBars then
                                local barBg = Instance.new("Frame", boxFrame)
                                barBg.Position = UDim2.new(0, -6, 0, 0)
                                barBg.Size = UDim2.new(0, 3, 1, 0)
                                barBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                                barBg.BorderSizePixel = 0

                                local barFill = Instance.new("Frame", barBg)
                                local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                barFill.Size = UDim2.new(1, 0, healthPercent, 0)
                                barFill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
                                barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
                                barFill.BorderSizePixel = 0
                            end
                        end
                    end
                end
            end
        end)
    end)

    pcall(function()
        task.spawn(function()
            while true do
                task.wait(0.1)
                if Config.Misc.VoidSpam and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        local hrp = player.Character.HumanoidRootPart
                        local originalPos = hrp.CFrame
                        hrp.CFrame = originalPos - Vector3.new(0, Config.Misc.VoidSpeed, 0)
                        task.wait(0.05)
                        hrp.CFrame = originalPos
                    end)
                end
            end
        end)
    end)

    local drKyoungCenter = Vector3.new(7000.00, 3954.00, 2070.45)
    local drKyoungRadius = 30
    local drKyoungSpeed = 8
    local drKyoungSwitchTime = 0.5
    local drKyoungStartTime = tick()

    pcall(function()
        RunService.Heartbeat:Connect(function()
            if not Config.Aimbot.DrKyoung then return end
            
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root or not root.Parent then return end

            local elapsed = tick() - drKyoungStartTime
            local cycle = math.floor(elapsed / drKyoungSwitchTime)
            local t = elapsed * drKyoungSpeed

            local x, z

            if cycle % 2 == 0 then
                x = math.sin(t) * drKyoungRadius
                z = math.sin(t * 2) * drKyoungRadius * 0.5
            else
                x = math.sin(t * 2) * drKyoungRadius
                z = math.sin(t * 4) * drKyoungRadius * 0.5
            end

            root.CFrame = CFrame.new(drKyoungCenter + Vector3.new(x, 0, z))
        end)
    end)

    local minhoTargetCFrame = CFrame.new(9000, 9000, 9000)
    local minhoProjectiles = {}

    pcall(function()
        workspace.ChildAdded:Connect(function(child)
            if not child:IsA("BasePart") then return end
            if child.Name == "CoreProjectile" then
                minhoProjectiles[child] = true
            elseif child.Name == "Part" then
                task.defer(function()
                    if child and child.Parent and child.AssemblyLinearVelocity.Magnitude > 50 then
                        minhoProjectiles[child] = true
                    end
                end)
            end
        end)
    end)

    pcall(function()
        workspace.ChildRemoved:Connect(function(child)
            minhoProjectiles[child] = nil
        end)
    end)

    pcall(function()
        RunService.Heartbeat:Connect(function()
            if not Config.Aimbot.MinhoRage then return end

            pcall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= player and p.Character then
                        local h = p.Character:FindFirstChild("HumanoidRootPart")
                        if h then
                            h.CFrame = minhoTargetCFrame
                            h.AssemblyLinearVelocity = Vector3.zero
                            h.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end

                for _, o in pairs(workspace:GetChildren()) do
                    if o.Name == "CoreProjectile" and o:IsA("BasePart") then
                        o.CFrame = minhoTargetCFrame
                        o.AssemblyLinearVelocity = Vector3.zero
                    end
                end

                for p in pairs(minhoProjectiles) do
                    if p and p.Parent then
                        p.CFrame = minhoTargetCFrame
                        p.AssemblyLinearVelocity = Vector3.zero
                    else
                        minhoProjectiles[p] = nil
                    end
                end
            end)
        end)
    end)

    local isMobile = false
    pcall(function()
        isMobile = UserInputService:GetLastInputType() == Enum.UserInputType.Touch
    end)

    pcall(function()
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.RightShift and not isMobile then
                mainFrame.Visible = not mainFrame.Visible
            end
        end)
    end)

    local toggleBtn = Instance.new("TextButton", playerGui)
    toggleBtn.Name = "YokaiMobileToggle"
    toggleBtn.Text = "M"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 16
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
    toggleBtn.BorderSizePixel = 1
    toggleBtn.BorderColor3 = Color3.fromRGB(100, 150, 200)
    toggleBtn.Size = UDim2.new(0, 40, 0, 40)
    toggleBtn.Position = UDim2.new(1, -50, 0, 10)
    toggleBtn.Visible = isMobile

    toggleBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)
end)

if not suc then
    warn("MinhoHub failed to load")
end
