--[[
    YOKAI.WIN - MINHOHUB MOBILE
    - 조준선 / 중앙 이름 기본값: Rainbow (무지개 모드)
    - Rainbow 체크 해제 시 Color R, G, B 슬라이더 값 실시간 반영
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 기존 UI 정리
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

-- 글로벌 Config 설정
local Config = {
    HubName = "minhohub",            -- 기본 이름
    NameFont = Enum.Font.GothamBold, -- 기본 글꼴
    NameFontSize = 14,              -- 기본 글자 크기
    Crosshair = {
        Enabled = true,             -- 조준선 표시 여부
        ShowName = true,            -- 중앙 이름 표시 여부
        AlwaysCenter = true,
        Length = 20,
        Thickness = 2,
        Gap = 10,
        Speed = 35,
        Rainbow = true,             -- 무지개 색상 기본 활성화
        ColorR = 255,               -- 사용자 지정 Red (0~255)
        ColorG = 255,               -- 사용자 지정 Green (0~255)
        ColorB = 255                -- 사용자 지정 Blue (0~255)
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

-- 지원하는 글꼴 목록
local fontOptions = {
    "GothamBold",
    "SourceSansBold",
    "Code",
    "Arcade",
    "Fantasy",
    "Bodoni",
    "FredokaOne"
}

-- [ Config 및 Auto Load 파일 시스템 ]
local configFolder = "Yokai_Configs"
local autoLoadFile = configFolder .. "/AutoLoad.txt"

if writefile and readfile and isfolder and listfiles and isfile and makefolder then
    if not isfolder(configFolder) then
        makefolder(configFolder)
    end
end

local function GetConfigList()
    local list = {}
    if listfiles and isfolder and isfolder(configFolder) then
        pcall(function()
            for _, path in ipairs(listfiles(configFolder)) do
                if path:sub(-5) == ".json" then
                    local name = path:match("([^/^\\]+)%.json$") or path:sub(#configFolder + 2, -6)
                    table.insert(list, name)
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
                haloEmitter.LightInfluence = 0
                haloEmitter.Orientation = Enum.ParticleOrientation.FacingCameraWorld
                haloEmitter.Parent = att
            end)
        end

        if Config.Visuals.FloorAura or Config.Visuals.YokaiAura then
            pcall(function()
                local att = Instance.new("Attachment")
                att.Name = "YokaiCustomEffectAttachment"
                att.Position = Vector3.new(0, -3.2, 0)
                att.Parent = rootPart

                local ringEmitter = Instance.new("ParticleEmitter")
                ringEmitter.Name = "FloorRingEmitter"
                ringEmitter.Texture = "rbxassetid://1084991217"
                ringEmitter.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 40, 0))
                })
                ringEmitter.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 2),
                    NumberSequenceKeypoint.new(1, 7)
                })
                ringEmitter.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.2),
                    NumberSequenceKeypoint.new(1, 1)
                })
                ringEmitter.Lifetime = NumberRange.new(0.8, 1.2)
                ringEmitter.Rate = 25
                ringEmitter.Speed = NumberRange.new(0)
                ringEmitter.LightEmission = 0.9
                ringEmitter.Orientation = Enum.ParticleOrientation.FacingCamera
                ringEmitter.Parent = att

                local pillarEmitter = Instance.new("ParticleEmitter")
                pillarEmitter.Name = "AuraPillarEmitter"
                pillarEmitter.Texture = "rbxassetid://242202302"
                pillarEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 100, 20))
                pillarEmitter.Size = NumberSequence.new(3.5, 0.5)
                pillarEmitter.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.3),
                    NumberSequenceKeypoint.new(1, 1)
                })
                pillarEmitter.Lifetime = NumberRange.new(0.5, 0.8)
                pillarEmitter.Rate = 35
                pillarEmitter.Speed = NumberRange.new(4, 7)
                pillarEmitter.EmissionDirection = Enum.NormalId.Top
                pillarEmitter.LightEmission = 0.85
                pillarEmitter.Parent = att
            end)
        end
    end)
end

player.CharacterAdded:Connect(function(char)
    ApplyCharacterEffects(char)
end)

local function SaveConfig(fileName)
    if not writefile then return end
    if not fileName or fileName == "" then fileName = "default" end
    local filePath = configFolder .. "/" .. fileName .. ".json"
    
    local saveTable = HttpService:JSONDecode(HttpService:JSONEncode(Config))
    if typeof(Config.NameFont) == "EnumItem" then
        saveTable.NameFont = Config.NameFont.Name
    end
    
    local jsonData = HttpService:JSONEncode(saveTable)
    writefile(filePath, jsonData)
    if updateDropdownUI then updateDropdownUI(GetConfigList()) end
end

local function LoadConfig(fileName)
    if not readfile or not isfile then return end
    if not fileName or fileName == "" then fileName = "default" end
    local filePath = configFolder .. "/" .. fileName .. ".json"
    if isfile(filePath) then
        local content = readfile(filePath)
        local decoded = HttpService:JSONDecode(content)
        for k, v in pairs(decoded) do
            if type(v) == "table" and Config[k] then
                for subK, subV in pairs(v) do
                    Config[k][subK] = subV
                end
            else
                Config[k] = v
            end
        end

        if typeof(Config.NameFont) == "string" then
            pcall(function()
                Config.NameFont = Enum.Font[Config.NameFont]
            end)
        end

        if player.Character then ApplyCharacterEffects(player.Character) end
    end
end

local function DeleteConfig(fileName)
    if not delfile or not isfile then return end
    if not fileName or fileName == "" then fileName = "default" end
    local filePath = configFolder .. "/" .. fileName .. ".json"
    if isfile(filePath) then
        delfile(filePath)
    end
    if updateDropdownUI then updateDropdownUI(GetConfigList()) end
end

local function SetAutoLoad(fileName)
    if not writefile then return end
    if not fileName or fileName == "" then fileName = "default" end
    writefile(autoLoadFile, fileName)
end

local function ClearAutoLoad()
    if delfile and isfile and isfile(autoLoadFile) then
        delfile(autoLoadFile)
    end
end

if readfile and isfile and isfile(autoLoadFile) then
    pcall(function()
        local autoConfig = readfile(autoLoadFile)
        if autoConfig and autoConfig ~= "" then
            LoadConfig(autoConfig)
        end
    end)
end

-- [ 조준선 GUI & 중앙 텍스트 ]
local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name = "UltimateCrosshairGui"
crosshairGui.ResetOnSpawn = false
crosshairGui.DisplayOrder = 2147483647
crosshairGui.IgnoreGuiInset = true
crosshairGui.Parent = playerGui

local mainMouseHolder = Instance.new("Frame", crosshairGui)
mainMouseHolder.AnchorPoint = Vector2.new(0.5, 0.5)
mainMouseHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
mainMouseHolder.Size = UDim2.new(0, 0, 0, 0)
mainMouseHolder.BackgroundTransparency = 1

local crosshairHolder = Instance.new("Frame", mainMouseHolder)
crosshairHolder.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairHolder.BackgroundTransparency = 1

local function createThinBar()
    local bar = Instance.new("Frame", crosshairHolder)
    bar.BorderSizePixel = 0
    bar.ZIndex = 100
    local stroke = Instance.new("UIStroke", bar)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(0, 0, 0)
    return bar
end

local barTop, barBottom, barLeft, barRight = createThinBar(), createThinBar(), createThinBar(), createThinBar()

local centerTextLabel = Instance.new("TextLabel", mainMouseHolder)
centerTextLabel.Size = UDim2.new(0, 200, 0, 40)
centerTextLabel.AnchorPoint = Vector2.new(0.5, 0)
centerTextLabel.Position = UDim2.new(0, 0, 0, 32)
centerTextLabel.BackgroundTransparency = 1
centerTextLabel.Font = Config.NameFont
centerTextLabel.TextSize = Config.NameFontSize
centerTextLabel.TextStrokeTransparency = 0.2
centerTextLabel.Text = Config.HubName
centerTextLabel.ZIndex = 100

local hue, rotAngle, cycleTime = 0, 0, 0

RunService:BindToRenderStep("YokaiCrosshairLock", Enum.RenderPriority.Camera.Value + 1, function(dt)
    crosshairHolder.Visible = Config.Crosshair.Enabled
    centerTextLabel.Visible = Config.Crosshair.ShowName

    if not Config.Crosshair.Enabled and not Config.Crosshair.ShowName then
        return
    end

    if Config.Crosshair.AlwaysCenter then
        mainMouseHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    else
        local mousePos = UserInputService:GetMouseLocation()
        mainMouseHolder.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
    end

    centerTextLabel.Font = Config.NameFont
    centerTextLabel.TextSize = Config.NameFontSize
    centerTextLabel.Text = Config.HubName

    -- [핵심] Rainbow 모드 토글 여부에 따라 색상 지정
    local activeColor
    if Config.Crosshair.Rainbow then
        hue = (hue + dt * 0.4) % 1
        activeColor = Color3.fromHSV(hue, 0.85, 1)
    else
        -- 사용자 지정 단색 (RGB)
        activeColor = Color3.fromRGB(
            math.clamp(Config.Crosshair.ColorR, 0, 255),
            math.clamp(Config.Crosshair.ColorG, 0, 255),
            math.clamp(Config.Crosshair.ColorB, 0, 255)
        )
    end

    barTop.BackgroundColor3 = activeColor
    barBottom.BackgroundColor3 = activeColor
    barLeft.BackgroundColor3 = activeColor
    barRight.BackgroundColor3 = activeColor
    centerTextLabel.TextColor3 = activeColor

    local speedMultiplier = Config.Crosshair.Speed / 10
    cycleTime = (cycleTime + dt * speedMultiplier) % (math.pi * 2)
    rotAngle = (cycleTime - math.sin(cycleTime)) * (180 / math.pi)
    crosshairHolder.Rotation = rotAngle

    local pulseTime = tick() * 4
    local baseLen = Config.Crosshair.Length
    local dynamicLen = math.floor(baseLen + math.sin(pulseTime) * (baseLen * 0.25))
    local offset = Config.Crosshair.Gap + math.sin(pulseTime) * 2
    local totalThick = Config.Crosshair.Thickness

    barTop.Size = UDim2.new(0, totalThick, 0, dynamicLen)
    barBottom.Size = UDim2.new(0, totalThick, 0, dynamicLen)
    barLeft.Size = UDim2.new(0, dynamicLen, 0, totalThick)
    barRight.Size = UDim2.new(0, dynamicLen, 0, totalThick)

    barTop.Position = UDim2.new(0, -totalThick/2, 0, -offset - dynamicLen)
    barBottom.Position = UDim2.new(0, -totalThick/2, 0, offset)
    barLeft.Position = UDim2.new(0, -offset - dynamicLen, 0, -totalThick/2)
    barRight.Position = UDim2.new(0, offset, 0, -totalThick/2)
end)

-- [ UI 및 자유 드래그 모바일 버튼 ]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YokaiGridUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = playerGui

local MobileToggleGui = Instance.new("ScreenGui")
MobileToggleGui.Name = "YokaiMobileToggle"
MobileToggleGui.ResetOnSpawn = false
MobileToggleGui.DisplayOrder = 999999998
MobileToggleGui.Parent = playerGui

local ToggleBtn = Instance.new("TextButton", MobileToggleGui)
ToggleBtn.Size = UDim2.new(0, 100, 0, 40)
ToggleBtn.Position = UDim2.new(0, 20, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ToggleBtn.Text = "minhohub"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.Code
ToggleBtn.Active = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Thickness = 1
ToggleStroke.Color = Color3.fromRGB(45, 45, 55)

local dragging = false
local dragInput, dragStart, startPos
local dragMoved = false

local function update(input)
    local delta = input.Position - dragStart
    ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragMoved = false
        dragStart = input.Position
        startPos = ToggleBtn.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        if (input.Position - dragStart).Magnitude > 5 then
            dragMoved = true
        end
        update(input)
    end
end)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 520, 0, 320)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)

ToggleBtn.MouseButton1Click:Connect(function()
    if not dragMoved then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 1
MainStroke.Color = Color3.fromRGB(35, 35, 45)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 50, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)

local SidebarList = Instance.new("UIListLayout", Sidebar)
SidebarList.Padding = UDim.new(0, 10)
SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarList.VerticalAlignment = Enum.VerticalAlignment.Top

local SidebarPadding = Instance.new("UIPadding", Sidebar)
SidebarPadding.PaddingTop = UDim.new(0, 15)

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size = UDim2.new(1, -60, 1, -10)
ContentArea.Position = UDim2.new(0, 55, 0, 5)
ContentArea.BackgroundTransparency = 1

local pages = {}

local function createPage(name)
    local page = Instance.new("Frame", ContentArea)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    pages[name] = page
    return page
end

local combatPage = createPage("Combat")
local visualPage = createPage("Visuals")
local miscPage = createPage("Misc")
local configPage = createPage("Config")

local activeTab = nil
local function createTabButton(iconText, pageName)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(0, 36, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    btn.Text = iconText
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
    btn.TextSize = 18
    btn.Font = Enum.Font.Code
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(40, 40, 50)

    btn.MouseButton1Click:Connect(function()
        for name, pg in pairs(pages) do
            pg.Visible = (name == pageName)
        end
        if activeTab then
            activeTab.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            activeTab.TextColor3 = Color3.fromRGB(180, 180, 200)
        end
        activeTab = btn
        btn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    if not activeTab then
        activeTab = btn
        btn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        pages[pageName].Visible = true
    end
end

createTabButton("🎯", "Combat")
createTabButton("👁️", "Visuals")
createTabButton("⚙️", "Misc")
createTabButton("💾", "Config")

local function createSectionBox(parent, titleText, size, pos)
    local box = Instance.new("Frame", parent)
    box.Size = size
    box.Position = pos
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    local stroke = Instance.new("UIStroke", box)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(35, 35, 45)

    local title = Instance.new("TextLabel", box)
    title.Size = UDim2.new(1, -10, 0, 22)
    title.Position = UDim2.new(0, 8, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(220, 220, 230)
    title.TextSize = 11
    title.Font = Enum.Font.Code
    title.TextXAlignment = Enum.TextXAlignment.Left

    local container = Instance.new("ScrollingFrame", box)
    container.Size = UDim2.new(1, -10, 1, -30)
    container.Position = UDim2.new(0, 5, 0, 26)
    container.BackgroundTransparency = 1
    container.ScrollBarThickness = 2
    container.CanvasSize = UDim2.new(0, 0, 0, 0)

    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 6)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    return container
end

local function addCheckbox(container, text, state, callback)
    local f = Instance.new("Frame", container)
    f.Size = UDim2.new(1, 0, 0, 20)
    f.BackgroundTransparency = 1

    local box = Instance.new("TextButton", f)
    box.Size = UDim2.new(0, 12, 0, 12)
    box.Position = UDim2.new(0, 2, 0.5, -6)
    box.BackgroundColor3 = state and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(35, 35, 45)
    box.Text = ""
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 2)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -22, 1, 0)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    f.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            state = not state
            box.BackgroundColor3 = state and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(35, 35, 45)
            callback(state)
        end
    end)
end

local function addSlider(container, text, min, max, val, callback)
    local f = Instance.new("Frame", container)
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, 0, 0, 14)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.format("%s %d", text, val)
    lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local bg = Instance.new("Frame", f)
    bg.Size = UDim2.new(1, -4, 0, 8)
    bg.Position = UDim2.new(0, 2, 0, 18)
    bg.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 2)

    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)

    local isSliderDragging = false
    bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then isSliderDragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then isSliderDragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if isSliderDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((i.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
            val = math.floor(min + (max - min) * pos)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            lbl.Text = string.format("%s %d", text, val)
            callback(val)
        end
    end)
end

local function addTextBox(container, placeholder, callback)
    local f = Instance.new("Frame", container)
    f.Size = UDim2.new(1, 0, 0, 26)
    f.BackgroundTransparency = 1

    local box = Instance.new("TextBox", f)
    box.Size = UDim2.new(1, -4, 1, 0)
    box.Position = UDim2.new(0, 2, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    box.Text = ""
    box.PlaceholderText = placeholder
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    box.TextSize = 10
    box.Font = Enum.Font.Code
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

    local stroke = Instance.new("UIStroke", box)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(45, 45, 55)

    box.FocusLost:Connect(function(enterPressed)
        if box.Text ~= "" then
            callback(box.Text)
        end
    end)
    return box
end

local function addButton(container, text, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, -4, 0, 24)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.TextSize = 10
    btn.Font = Enum.Font.Code
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(45, 45, 55)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function addDropdown(container, titleText, options, onSelect)
    local f = Instance.new("Frame", container)
    f.Size = UDim2.new(1, -4, 0, 44)
    f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, 0, 0, 14)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText
    lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local mainBtn = Instance.new("TextButton", f)
    mainBtn.Size = UDim2.new(1, 0, 0, 24)
    mainBtn.Position = UDim2.new(0, 0, 0, 16)
    mainBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    mainBtn.Text = " " .. (options[1] or "None")
    mainBtn.TextColor3 = Color3.fromRGB(255, 140, 0)
    mainBtn.TextSize = 10
    mainBtn.Font = Enum.Font.Code
    mainBtn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 3)

    local listFrame = Instance.new("ScrollingFrame", f)
    listFrame.Size = UDim2.new(1, 0, 0, 80)
    listFrame.Position = UDim2.new(0, 0, 0, 42)
    listFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    listFrame.Visible = false
    listFrame.ZIndex = 50
    listFrame.ScrollBarThickness = 2
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 3)

    local layout = Instance.new("UIListLayout", listFrame)
    layout.Padding = UDim.new(0, 2)

    local function refreshOptions(newOptions)
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, opt in ipairs(newOptions) do
            local itemBtn = Instance.new("TextButton", listFrame)
            itemBtn.Size = UDim2.new(1, 0, 0, 20)
            itemBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
            itemBtn.Text = " " .. opt
            itemBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
            itemBtn.TextSize = 10
            itemBtn.Font = Enum.Font.Code
            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
            itemBtn.ZIndex = 51

            itemBtn.MouseButton1Click:Connect(function()
                mainBtn.Text = " " .. opt
                listFrame.Visible = false
                f.Size = UDim2.new(1, -4, 0, 44)
                onSelect(opt)
            end)
        end
        listFrame.CanvasSize = UDim2.new(0, 0, 0, #newOptions * 22)
    end

    refreshOptions(options)

    mainBtn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
        if listFrame.Visible then
            f.Size = UDim2.new(1, -4, 0, 128)
        else
            f.Size = UDim2.new(1, -4, 0, 44)
        end
    end)

    return function(updatedList)
        refreshOptions(updatedList)
        if #updatedList > 0 then
            mainBtn.Text = " " .. updatedList[1]
            onSelect(updatedList[1])
        end
    end
end

-- [ Combat 탭 ]
local aimSec = createSectionBox(combatPage, "Aimbot Module", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))
addCheckbox(aimSec, "Enable Aimbot", Config.Aimbot.Enabled, function(v) Config.Aimbot.Enabled = v end)
addCheckbox(aimSec, "Rage Mode", Config.Aimbot.RageMode, function(v) Config.Aimbot.RageMode = v end)
addSlider(aimSec, "Smoothness", 1, 100, Config.Aimbot.Smoothness, function(v) Config.Aimbot.Smoothness = v end)
addCheckbox(aimSec, "경박사 (Movement)", Config.Aimbot.DrKyoung, function(v) Config.Aimbot.DrKyoung = v end)
addCheckbox(aimSec, "민호허브전용레이지", Config.Aimbot.MinhoRage, function(v) Config.Aimbot.MinhoRage = v end)

-- 오른쪽 섹션: Rage & Crosshair
local rageSec = createSectionBox(combatPage, "Rage & Crosshair", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0.52, 0, 0, 0))
addCheckbox(rageSec, "Auto-TP Rage Kill", Config.RageKill.Enabled, function(v) Config.RageKill.Enabled = v end)
addCheckbox(rageSec, "Auto Shoot", Config.RageKill.AutoShoot, function(v) Config.RageKill.AutoShoot = v end)

-- 조준선 & 이름 기본 설정
addCheckbox(rageSec, "Show Crosshair", Config.Crosshair.Enabled, function(v) Config.Crosshair.Enabled = v end)
addCheckbox(rageSec, "Show Name Label", Config.Crosshair.ShowName, function(v) Config.Crosshair.ShowName = v end)
addCheckbox(rageSec, "Always Center Lock", Config.Crosshair.AlwaysCenter, function(v) Config.Crosshair.AlwaysCenter = v end)

-- [ 무지개 vs 단색 변경 ]
addCheckbox(rageSec, "Rainbow Mode (Checked=Rainbow)", Config.Crosshair.Rainbow, function(v) 
    Config.Crosshair.Rainbow = v 
end)

-- 단색 조절 RGB 슬라이더 (Rainbow 체크 해제 시 아래 값 적용)
addSlider(rageSec, "Custom Color Red", 0, 255, Config.Crosshair.ColorR, function(v) 
    Config.Crosshair.ColorR = v 
end)
addSlider(rageSec, "Custom Color Green", 0, 255, Config.Crosshair.ColorG, function(v) 
    Config.Crosshair.ColorG = v 
end)
addSlider(rageSec, "Custom Color Blue", 0, 255, Config.Crosshair.ColorB, function(v) 
    Config.Crosshair.ColorB = v 
end)

-- 이름 / 글꼴 / 크기
addTextBox(rageSec, "Change Name (e.g. minhohub)", function(txt)
    Config.HubName = txt
end)

addDropdown(rageSec, "Name Font", fontOptions, function(chosenFont)
    pcall(function()
        Config.NameFont = Enum.Font[chosenFont]
    end)
end)
addSlider(rageSec, "Name Font Size", 8, 40, Config.NameFontSize, function(v)
    Config.NameFontSize = v
end)

addSlider(rageSec, "Crosshair Length", 5, 50, Config.Crosshair.Length, function(v) Config.Crosshair.Length = v end)
addSlider(rageSec, "Crosshair Thick", 1, 10, Config.Crosshair.Thickness, function(v) Config.Crosshair.Thickness = v end)
addSlider(rageSec, "Crosshair Gap", 0, 30, Config.Crosshair.Gap, function(v) Config.Crosshair.Gap = v end)
addSlider(rageSec, "Spin Speed", 0, 100, Config.Crosshair.Speed, function(v) Config.Crosshair.Speed = v end)

-- [ Visuals 탭 ]
local espSec = createSectionBox(visualPage, "ESP Settings", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))
addCheckbox(espSec, "Boxes ESP", Config.ESP.Boxes, function(v) Config.ESP.Boxes = v end)
addCheckbox(espSec, "Names ESP", Config.ESP.Names, function(v) Config.ESP.Names = v end)
addCheckbox(espSec, "Health Bars", Config.ESP.HealthBars, function(v) Config.ESP.HealthBars = v end)

local auraSec = createSectionBox(visualPage, "Character Aura & Effects", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0.52, 0, 0, 0))
addCheckbox(auraSec, "Angel Wings Effect", Config.Visuals.Wings, function(v)
    Config.Visuals.Wings = v
    if player.Character then ApplyCharacterEffects(player.Character) end
end)
addCheckbox(auraSec, "Angel Halo Effect", Config.Visuals.Halo, function(v)
    Config.Visuals.Halo = v
    if player.Character then ApplyCharacterEffects(player.Character) end
end)
addCheckbox(auraSec, "Floor Ring Aura", Config.Visuals.FloorAura, function(v)
    Config.Visuals.FloorAura = v
    if player.Character then ApplyCharacterEffects(player.Character) end
end)
addCheckbox(auraSec, "Yokai Power Aura", Config.Visuals.YokaiAura, function(v)
    Config.Visuals.YokaiAura = v
    if player.Character then ApplyCharacterEffects(player.Character) end
end)
addCheckbox(auraSec, "Toxic Wasteland Horns", Config.Visuals.ToxicWastelandHorns, function(v)
    Config.Visuals.ToxicWastelandHorns = v
    if player.Character then ApplyCharacterEffects(player.Character) end
end)

-- [ Misc 탭 ]
local miscSec1 = createSectionBox(miscPage, "Utility Options", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))
addCheckbox(miscSec1, "Void Spam Exploit", Config.Misc.VoidSpam, function(v) Config.Misc.VoidSpam = v end)
addSlider(miscSec1, "Void Speed", 10, 500, Config.Misc.VoidSpeed, function(v) Config.Misc.VoidSpeed = v end)

local miscSec2 = createSectionBox(miscPage, "World Lighting", UDim2.new(0.48, 0, 0.95, 0), UDim2.new(0.52, 0, 0, 0))
addCheckbox(miscSec2, "Global Shadows", Config.World.GlobalShadows, function(v) Lighting.GlobalShadows = v end)
addSlider(miscSec2, "Time of Day", 0, 24, Config.World.ClockTime, function(v) Lighting.ClockTime = v end)

-- [ Config 탭 ]
local cfgSec = createSectionBox(configPage, "Configuration Manager", UDim2.new(0.98, 0, 0.95, 0), UDim2.new(0, 0, 0, 0))

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

-- [ ESP 루프 ]
local espFolder = Instance.new("Folder", playerGui)
espFolder.Name = "YokaiESP_Overlay"

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

-- [ Void Spam 로직 ]
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

-- [ 경박사 로직 ]
local drKyoungCenter = Vector3.new(7000.00, 3954.00, 2070.45)
local drKyoungRadius = 30
local drKyoungSpeed = 8
local drKyoungSwitchTime = 0.5
local drKyoungStartTime = tick()

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

-- [ 민호허브전용레이지 로직 ]
local minhoTargetCFrame = CFrame.new(9000, 9000, 9000)
local minhoProjectiles = {}

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

workspace.ChildRemoved:Connect(function(child)
    minhoProjectiles[child] = nil
end)

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