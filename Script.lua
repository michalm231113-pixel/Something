local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ContextActionService = game:GetService("ContextActionService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local milion = 1000000
local CONFIG = {
    UI = {
        DisplayOrder = 2147483647,
        MainSize = Vector2.new(250, 590),
        LocalSize = Vector2.new(315, 555),
        PlayerTPSize = Vector2.new(235, 325),
        MainPosition = UDim2.fromOffset(20, 140),
        LocalPosition = UDim2.fromOffset(285, 120),
        PlayerTPPosition = UDim2.fromOffset(285, 150),
        CornerRadius = 10,
        ButtonCornerRadius = 8,
        Orange = Color3.fromRGB(217, 95, 2),
        OrangeHover = Color3.fromRGB(242, 119, 25),
        Dark = Color3.fromRGB(6, 6, 8),
        Darker = Color3.fromRGB(0, 0, 0),
        Panel = Color3.fromRGB(8, 8, 10),
        Panel2 = Color3.fromRGB(17, 17, 20),
        Button = Color3.fromRGB(92, 92, 92),
        ButtonHover = Color3.fromRGB(112, 112, 112),
        Stud = Color3.fromRGB(112, 116, 124),
        White = Color3.fromRGB(245, 245, 245),
        Gray = Color3.fromRGB(177, 177, 177),
        Green = Color3.fromRGB(60, 220, 110),
        Red = Color3.fromRGB(235, 70, 70),
        Yellow = Color3.fromRGB(255, 225, 60),
        BlueGray = Color3.fromRGB(95, 105, 115),
    },
    WalkSpeed = {
        DefaultCustom = 50,
        Min = 1,
        Max = milion,
    },
    JumpPower = {
        DefaultCustom = 50,
        Min = 0,
        Max = milion,
    },
    Fly = {
        DefaultSpeed = 100,
        MinSpeed = 10,
        MaxSpeed = milion,
    },
    Aimbot = {
        Smoothness = 0.35,
        TargetPart = "Head",
    },
    Highlight = {
        FillTransparency = 0.55,
        OutlineTransparency = 0,
        RefreshInterval = 0.25,
        InfoRefreshInterval = 0.10,
        BillboardSize = Vector2.new(250, 54),
        StudsOffset = Vector3.new(0, 3.45, 0),
    },
    FullBright = {
        RefreshInterval = 0.35,
    },
    Noclip = {
        RefreshInterval = 0.08,
    },
    Bhop = {
        Interval = 0.1,
    },
    AntiAFK = {
        ClickDelay = 0.15,
    },
    FeatureKeys = {
        ToggleGui = Enum.KeyCode.F1,
        Fly = Enum.KeyCode.F,
        InfiniteJump = Enum.KeyCode.Z,
        Noclip = Enum.KeyCode.T,
        Bhop = Enum.KeyCode.B,
        Aimbot = Enum.KeyCode.X,
        NextTarget = Enum.KeyCode.C,
        Highlight = Enum.KeyCode.H,
        AntiAFK = Enum.KeyCode.K,
        FullBright = Enum.KeyCode.J,
        ClickTP = Enum.KeyCode.L,
        PlayerTP = Enum.KeyCode.V,
        LocalPlayer = Enum.KeyCode.Y,
    },
}
local function safeCall(label, callback, ...)
    local ok, result = pcall(callback, ...)
    if not ok then
        warn("[MegaPanel V13] " .. tostring(label) .. " failed:", result)
        return nil
    end
    return result
end
local state = {
    InfiniteJump = false,
    Flying = false,
    Noclip = false,
    Bhop = false,
    Aimbot = false,
    Highlight = true,
    FullBright = false,
    ClickTP = false,
    AntiAFK = false,
    WalkSpeedEnabled = false,
    JumpPowerEnabled = false,
    WalkSpeed = CONFIG.WalkSpeed.DefaultCustom,
    JumpPower = CONFIG.JumpPower.DefaultCustom,
    FlySpeed = CONFIG.Fly.DefaultSpeed,
    TargetIndex = 1,
    CurrentTarget = nil,
}
local Character
local Humanoid
local HumanoidRootPart
local gameWalkSpeed = 16
local gameJumpPower = 50
local gameUseJumpPower = true
local humanoidDiedConnection
local walkSpeedChangedConnection
local jumpPowerChangedConnection
local Connections = {}
local PlayerConnections = {}
local InstanceConnections = {}
local ActionNames = {}
local destroyed = false
local function addConnection(connection)
    if connection then
        table.insert(Connections, connection)
    end
    return connection
end
local function disconnectConnection(connection)
    if not connection then
        return
    end

    if connection.Connected then
        connection:Disconnect()
    end

    for index = #Connections, 1, -1 do
        if Connections[index] == connection then
            table.remove(Connections, index)
        end
    end
end
local function addInstanceConnection(instance, connection)
    if not instance or not connection then
        return connection
    end

    local instanceList = InstanceConnections[instance]
    if not instanceList then
        instanceList = {}
        InstanceConnections[instance] = instanceList
    end

    table.insert(instanceList, connection)
    return addConnection(connection)
end
local function disconnectInstanceConnections(instance)
    local instanceList = InstanceConnections[instance]
    if not instanceList then
        return
    end

    for index = #instanceList, 1, -1 do
        disconnectConnection(instanceList[index])
    end

    InstanceConnections[instance] = nil
end
local function addPlayerConnection(player, connection)
    if not player or not connection then
        return connection
    end

    local playerList = PlayerConnections[player]
    if not playerList then
        playerList = {}
        PlayerConnections[player] = playerList
    end

    table.insert(playerList, connection)
    return addConnection(connection)
end
local function disconnectPlayerConnections(player)
    local playerList = PlayerConnections[player]
    if not playerList then
        return
    end

    for index = #playerList, 1, -1 do
        disconnectConnection(playerList[index])
    end

    PlayerConnections[player] = nil
end
local function cleanupConnections()
    while #Connections > 0 do
        local connection = table.remove(Connections)
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end

    table.clear(PlayerConnections)
    table.clear(InstanceConnections)
end
local existingGui = PlayerGui:FindFirstChild("MegaPanelV13")
if existingGui then
    safeCall("destroy old GUI", function()
        existingGui:Destroy()
    end)
end
local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or CONFIG.UI.CornerRadius)
    corner.Parent = instance
    return corner
end
local function addStroke(instance, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.new(1, 1, 1)
    stroke.Transparency = transparency or 0
    stroke.Thickness = thickness or 1
    stroke.Parent = instance
    return stroke
end
local function addPadding(instance, left, right, top, bottom)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or 0)
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or 0)
    padding.Parent = instance
    return padding
end
local function getKeyDisplay(keyCode)
    local display = safeCall("get key display", function()
        return UserInputService:GetStringForKeyCode(keyCode)
    end)
    if display and display ~= "" then
        return string.upper(display)
    end
    local raw = tostring(keyCode):gsub("Enum.KeyCode.", "")
    return string.upper(raw)
end
local function applySciFiSurface(frame)
    frame.BackgroundColor3 = CONFIG.UI.Dark
    frame.BackgroundTransparency = 0.04
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 32)),
        ColorSequenceKeypoint.new(0.42, Color3.fromRGB(5, 5, 7)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 21)),
    })
    gradient.Rotation = 38
    gradient.Parent = frame
    addStroke(frame, Color3.fromRGB(255, 255, 255), 0.12, 1.25)
    local width = math.max(frame.Size.X.Offset, 180)
    local height = math.max(frame.Size.Y.Offset, 100)
    local spacing = 36
    for y = 12, height - 12, spacing do
        for x = 12, width - 12, spacing do
            local stud = Instance.new("Frame")
            stud.Name = "ClassicStud"
            stud.Size = UDim2.fromOffset(6, 6)
            stud.Position = UDim2.fromOffset(x, y)
            stud.BackgroundColor3 = CONFIG.UI.Stud
            stud.BackgroundTransparency = 0.91
            stud.BorderSizePixel = 0
            stud.ZIndex = frame.ZIndex
            stud.Parent = frame
            addCorner(stud, 3)
            addStroke(stud, Color3.fromRGB(255, 255, 255), 0.92, 1)
        end
    end
end
local gui = Instance.new("ScreenGui")
gui.Name = "MegaPanelV13"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = CONFIG.UI.DisplayOrder
gui.Enabled = true
gui.Parent = PlayerGui
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel"
mainFrame.Size = UDim2.fromOffset(CONFIG.UI.MainSize.X, CONFIG.UI.MainSize.Y)
mainFrame.Position = CONFIG.UI.MainPosition
mainFrame.BackgroundColor3 = CONFIG.UI.Panel
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 1000
mainFrame.Parent = gui
addCorner(mainFrame, CONFIG.UI.CornerRadius)
applySciFiSurface(mainFrame)
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -54, 0, 38)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.Text = "MEGA PANEL V14"
title.TextColor3 = Color3.fromRGB(217, 95, 2)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 1001
title.Parent = mainFrame
local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "VersionLabel"
versionLabel.Size = UDim2.new(1, -24, 0, 20)
versionLabel.Position = UDim2.fromOffset(12, 43)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "COSMIC • V14 • LOCAL"
versionLabel.TextColor3 = CONFIG.UI.Gray
versionLabel.TextSize = 11
versionLabel.Font = Enum.Font.Gotham
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.ZIndex = 1001
versionLabel.Parent = mainFrame
local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.Position = UDim2.new(1, -42, 0, 8)
closeButton.BackgroundColor3 = CONFIG.UI.Button
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBold
closeButton.AutoButtonColor = false
closeButton.ZIndex = 1005
closeButton.Parent = mainFrame
addCorner(closeButton, 7)
addStroke(closeButton, Color3.fromRGB(255, 255, 255), 0.42, 1)
local targetStatus = Instance.new("TextLabel")
targetStatus.Name = "TargetStatus"
targetStatus.Size = UDim2.new(1, -24, 0, 28)
targetStatus.Position = UDim2.fromOffset(12, 72)
targetStatus.BackgroundColor3 = CONFIG.UI.Darker
targetStatus.Text = "TARGET: NONE"
targetStatus.TextColor3 = CONFIG.UI.Gray
targetStatus.TextSize = 12
targetStatus.Font = Enum.Font.GothamBold
targetStatus.TextXAlignment = Enum.TextXAlignment.Left
targetStatus.ZIndex = 1001
targetStatus.Parent = mainFrame
addCorner(targetStatus, 7)
addStroke(targetStatus, Color3.fromRGB(255, 255, 255), 0.78, 1)
addPadding(targetStatus, 10, 8, 0, 0)
local buttonIndex = 0
local function createButton(parent, text, keyCode)
    buttonIndex += 1
    local button = Instance.new("TextButton")
    button.Name = "Button_" .. buttonIndex
    button.Size = UDim2.new(1, -24, 0, 40)
    button.BackgroundColor3 = CONFIG.UI.Button
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = ""
    button.ZIndex = 1001
    button.Parent = parent
    addCorner(button, CONFIG.UI.ButtonCornerRadius)
    addStroke(button, Color3.fromRGB(255, 255, 255), 0.56, 1)
    local edgeAccent = Instance.new("Frame")
    edgeAccent.Name = "OrangeAccent"
    edgeAccent.Size = UDim2.new(0, 3, 1, -12)
    edgeAccent.Position = UDim2.fromOffset(4, 6)
    edgeAccent.BackgroundColor3 = CONFIG.UI.Orange
    edgeAccent.BorderSizePixel = 0
    edgeAccent.ZIndex = 1002
    edgeAccent.Parent = button
    addCorner(edgeAccent, 2)
    local buttonText = Instance.new("TextLabel")
    buttonText.Name = "Text"
    buttonText.Size = UDim2.new(1, keyCode and -68 or -20, 1, 0)
    buttonText.Position = UDim2.fromOffset(10, 0)
    buttonText.BackgroundTransparency = 1
    buttonText.Text = text
    buttonText.TextColor3 = CONFIG.UI.White
    buttonText.TextStrokeColor3 = CONFIG.UI.Orange
    buttonText.TextStrokeTransparency = 0.82
    buttonText.TextSize = 13
    buttonText.Font = Enum.Font.GothamBold
    buttonText.TextXAlignment = Enum.TextXAlignment.Left
    buttonText.TextTruncate = Enum.TextTruncate.AtEnd
    buttonText.ZIndex = 1002
    buttonText.Parent = button
    if keyCode then
        local keySlot = Instance.new("TextLabel")
        keySlot.Name = "Hotkey"
        keySlot.Size = UDim2.fromOffset(42, 26)
        keySlot.AnchorPoint = Vector2.new(1, 0.5)
        keySlot.Position = UDim2.new(1, -7, 0.5, 0)
        keySlot.BackgroundColor3 = CONFIG.UI.Darker
        keySlot.BackgroundTransparency = 0.12
        keySlot.Text = getKeyDisplay(keyCode)
        keySlot.TextColor3 = CONFIG.UI.White
        keySlot.TextSize = 10
        keySlot.Font = Enum.Font.GothamBold
        keySlot.TextXAlignment = Enum.TextXAlignment.Center
        keySlot.TextYAlignment = Enum.TextYAlignment.Center
        keySlot.ZIndex = 1003
        keySlot.Parent = button
        addCorner(keySlot, 6)
        addStroke(keySlot, Color3.fromRGB(255, 255, 255), 0.55, 1)
    end
    addConnection(button.MouseEnter:Connect(function()
        if not button.Parent then
            return
        end
        TweenService:Create(
            button,
            TweenInfo.new(0.12),
            {BackgroundColor3 = button:GetAttribute("Active") and CONFIG.UI.OrangeHover or CONFIG.UI.ButtonHover}
        ):Play()
    end))
    addConnection(button.MouseLeave:Connect(function()
        if not button.Parent then
            return
        end
        TweenService:Create(
            button,
            TweenInfo.new(0.12),
            {BackgroundColor3 = button:GetAttribute("Active") and CONFIG.UI.Orange or CONFIG.UI.Button}
        ):Play()
    end))
    return button, buttonText
end
local function setButtonState(button, enabled, customLabel)
    if not button or not button.Parent then
        return
    end
    button:SetAttribute("Active", enabled)
    local label = button:FindFirstChild("Text")
    if label then
        label.Text = customLabel
    end
    TweenService:Create(
        button,
        TweenInfo.new(0.12),
        {BackgroundColor3 = enabled and CONFIG.UI.Orange or CONFIG.UI.Button}
    ):Play()
end
local function createMainButton(text, keyCode)
    local button = createButton(mainFrame, text, keyCode)
    button.Position = UDim2.fromOffset(12, 108 + ((buttonIndex - 1) * 46))
    return button
end
local infiniteJumpButton = createMainButton("Inf. Jump: OFF", CONFIG.FeatureKeys.InfiniteJump)
local flyButton = createMainButton("Flying: OFF", CONFIG.FeatureKeys.Fly)
local aimbotButton = createMainButton("Aimbot: OFF", CONFIG.FeatureKeys.Aimbot)
local noclipButton = createMainButton("Noclip: OFF", CONFIG.FeatureKeys.Noclip)
local bhopButton = createMainButton("Bhop: OFF", CONFIG.FeatureKeys.Bhop)
local highlightButton = createMainButton("Highlight: ON", CONFIG.FeatureKeys.Highlight)
local playerTPButton = createMainButton("Player TP", CONFIG.FeatureKeys.PlayerTP)
local localPlayerButton = createMainButton("LocalPlayer", CONFIG.FeatureKeys.LocalPlayer)
local noteLabel = Instance.new("TextLabel")
noteLabel.Name = "Note"
noteLabel.Size = UDim2.new(1, -24, 0, 50)
noteLabel.Position = UDim2.new(0, 12, 1, -58)
noteLabel.BackgroundTransparency = 1
noteLabel.Text = "C = next target\nF1 = show / hide panel"
noteLabel.TextColor3 = CONFIG.UI.Gray
noteLabel.TextSize = 11
noteLabel.Font = Enum.Font.Gotham
noteLabel.TextXAlignment = Enum.TextXAlignment.Left
noteLabel.TextYAlignment = Enum.TextYAlignment.Bottom
noteLabel.ZIndex = 1001
noteLabel.Parent = mainFrame
local localFrame = Instance.new("Frame")
localFrame.Name = "LocalPlayerPanel"
localFrame.Size = UDim2.fromOffset(CONFIG.UI.LocalSize.X, CONFIG.UI.LocalSize.Y)
localFrame.Position = CONFIG.UI.LocalPosition
localFrame.BackgroundColor3 = CONFIG.UI.Panel
localFrame.BorderSizePixel = 0
localFrame.Visible = false
localFrame.ZIndex = 900
localFrame.Parent = gui
addCorner(localFrame, CONFIG.UI.CornerRadius)
applySciFiSurface(localFrame)
local localTitle = Instance.new("TextLabel")
localTitle.Name = "LocalTitle"
localTitle.Size = UDim2.new(1, -20, 0, 34)
localTitle.Position = UDim2.fromOffset(10, 8)
localTitle.BackgroundTransparency = 1
localTitle.Text = "LOCAL PLAYER"
localTitle.TextColor3 = Color3.fromRGB(217, 95, 2)
localTitle.TextSize = 18
localTitle.Font = Enum.Font.GothamBold
localTitle.TextXAlignment = Enum.TextXAlignment.Left
localTitle.ZIndex = 901
localTitle.Parent = localFrame
local localScroll = Instance.new("ScrollingFrame")
localScroll.Name = "Scroll"
localScroll.Size = UDim2.new(1, -16, 1, -52)
localScroll.Position = UDim2.fromOffset(8, 44)
localScroll.BackgroundTransparency = 1
localScroll.BorderSizePixel = 0
localScroll.ScrollBarThickness = 5
localScroll.CanvasSize = UDim2.fromOffset(0, 0)
localScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
localScroll.ZIndex = 901
localScroll.Parent = localFrame
local localLayout = Instance.new("UIListLayout")
localLayout.Padding = UDim.new(0, 8)
localLayout.SortOrder = Enum.SortOrder.LayoutOrder
localLayout.Parent = localScroll
addPadding(localScroll, 4, 4, 4, 8)
local localButtonCount = 0
local function createLocalButton(text, keyCode)
    localButtonCount += 1
    local button = createButton(localScroll, text, keyCode)
    button.Size = UDim2.new(1, -8, 0, 40)
    button.LayoutOrder = localButtonCount
    button.ZIndex = 902
    return button
end
local function createSectionHeader(text)
    localButtonCount += 1
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -8, 0, 22)
    header.BackgroundTransparency = 1
    header.Text = text
    header.TextColor3 = Color3.fromRGB(217, 95, 2)
    header.TextSize = 12
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = localButtonCount
    header.ZIndex = 902
    header.Parent = localScroll
    return header
end
local function createNumberBox(placeholder, initialValue)
    localButtonCount += 1
    local container = Instance.new("Frame")
    container.Name = string.gsub(placeholder, "%s+", "") .. "Control"
    container.Size = UDim2.new(1, -8, 0, 56)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.LayoutOrder = localButtonCount
    container.ZIndex = 902
    container.Parent = localScroll
    local fieldLabel = Instance.new("TextLabel")
    fieldLabel.Name = "FieldLabel"
    fieldLabel.Size = UDim2.new(1, -8, 0, 14)
    fieldLabel.Position = UDim2.fromOffset(2, 0)
    fieldLabel.BackgroundTransparency = 1
    fieldLabel.Text = string.upper(placeholder)
    fieldLabel.TextColor3 = CONFIG.UI.Orange
    fieldLabel.TextSize = 10
    fieldLabel.Font = Enum.Font.GothamBold
    fieldLabel.TextXAlignment = Enum.TextXAlignment.Left
    fieldLabel.ZIndex = 903
    fieldLabel.Parent = container
    local box = Instance.new("TextBox")
    box.Name = string.gsub(placeholder, "%s+", "") .. "Input"
    box.Size = UDim2.new(1, -8, 0, 36)
    box.Position = UDim2.fromOffset(0, 16)
    box.BackgroundColor3 = CONFIG.UI.Darker
    box.TextColor3 = CONFIG.UI.White
    box.PlaceholderText = "Enter number"
    box.PlaceholderColor3 = CONFIG.UI.Gray
    box.Text = tostring(initialValue)
    box.TextSize = 13
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ZIndex = 903
    box.Parent = container
    addCorner(box, 7)
    addStroke(box, Color3.fromRGB(255, 255, 255), 0.58, 1)
    addPadding(box, 10, 10, 0, 0)
    return box
end
local walkSpeedToggle = createLocalButton("WalkSpeed: OFF", nil)
local walkSpeedInput = createNumberBox("WalkSpeed", state.WalkSpeed)
local jumpPowerToggle = createLocalButton("JumpPower: OFF", nil)
local jumpPowerInput = createNumberBox("JumpPower", state.JumpPower)
local separatorSlot = Instance.new("Frame")
separatorSlot.Name = "Separator"
separatorSlot.Size = UDim2.new(1, -8, 0, 14)
separatorSlot.BackgroundTransparency = 1
separatorSlot.LayoutOrder = localButtonCount + 1
separatorSlot.ZIndex = 902
separatorSlot.Parent = localScroll
local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.AnchorPoint = Vector2.new(0, 0.5)
separator.Position = UDim2.fromScale(0, 0.5)
separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
separator.BackgroundTransparency = 0.68
separator.BorderSizePixel = 0
separator.ZIndex = 903
separator.Parent = separatorSlot
localButtonCount += 1
local flySpeedInput = createNumberBox("FlySpeed", state.FlySpeed)
local antiAFKButton = createLocalButton("AFK Alert: OFF", CONFIG.FeatureKeys.AntiAFK)
local clickTPButton = createLocalButton("Click TP: OFF", CONFIG.FeatureKeys.ClickTP)
local fullBrightButton = createLocalButton("FullBright: OFF", CONFIG.FeatureKeys.FullBright)
local performanceHeader = Instance.new("TextLabel")
performanceHeader.Name = "PerformanceHeader"
performanceHeader.Size = UDim2.new(1, -8, 0, 22)
performanceHeader.BackgroundTransparency = 1
performanceHeader.Text = "PERFORMANCE"
performanceHeader.TextColor3 = CONFIG.UI.White
performanceHeader.TextSize = 12
performanceHeader.Font = Enum.Font.GothamBold
performanceHeader.TextXAlignment = Enum.TextXAlignment.Left
localButtonCount += 1
performanceHeader.LayoutOrder = localButtonCount
performanceHeader.ZIndex = 902
performanceHeader.Parent = localScroll
local performanceFrame = Instance.new("Frame")
performanceFrame.Name = "Performance"
performanceFrame.Size = UDim2.new(1, -8, 0, 42)
performanceFrame.BackgroundColor3 = CONFIG.UI.Darker
performanceFrame.BorderSizePixel = 0
localButtonCount += 1
performanceFrame.LayoutOrder = localButtonCount
performanceFrame.ZIndex = 902
performanceFrame.Parent = localScroll
addCorner(performanceFrame, 7)
addStroke(performanceFrame, Color3.fromRGB(255, 255, 255), 0.68, 1)
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPS"
fpsLabel.Size = UDim2.new(0.5, -4, 1, 0)
fpsLabel.Position = UDim2.fromOffset(8, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: --"
fpsLabel.TextColor3 = CONFIG.UI.Green
fpsLabel.TextSize = 12
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.ZIndex = 903
fpsLabel.Parent = performanceFrame
local pingLabel = Instance.new("TextLabel")
pingLabel.Name = "Ping"
pingLabel.Size = UDim2.new(0.5, -8, 1, 0)
pingLabel.Position = UDim2.new(0.5, 0, 0, 0)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "PING: --"
pingLabel.TextColor3 = CONFIG.UI.Yellow
pingLabel.TextSize = 12
pingLabel.Font = Enum.Font.GothamBold
pingLabel.TextXAlignment = Enum.TextXAlignment.Right
pingLabel.ZIndex = 903
pingLabel.Parent = performanceFrame
local PANEL_EMOTES = {
    {Key = "Panel_TakeTheL", Label = "Elka / Take The L", Id = 105367539610328},
    {Key = "Panel_ChillFloat", Label = "Siedzenie w powietrzu", Id = 134795656394655},
    {Key = "Panel_MM2FakeDead", Label = "MM2 Fake Dead", Id = 83548980186247},
}
local activeEmoteTrack = nil
local activeEmoteAnimation = nil
local registerPanelEmotes
local playPanelEmote
local emoteHeader = createSectionHeader("ANIMATIONS / EMOTES")
emoteHeader.LayoutOrder = localButtonCount
for _, emote in ipairs(PANEL_EMOTES) do
    local selectedEmote = emote
    local button = createLocalButton(selectedEmote.Label, nil)
    addConnection(button.MouseButton1Click:Connect(function()
        safeCall("emote button " .. selectedEmote.Label, playPanelEmote, selectedEmote)
    end))
end
local function updateLocalCanvas()
    local contentHeight = localLayout.AbsoluteContentSize.Y + 16
    localScroll.CanvasSize = UDim2.fromOffset(0, contentHeight)
end
addConnection(localLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateLocalCanvas))
updateLocalCanvas()
local TELEPORT_COOLDOWN = 0.1
local lastTeleportAt = -math.huge
local function consumeTeleportCooldown()
    local now = os.clock()
    if now - lastTeleportAt < TELEPORT_COOLDOWN then
        return false
    end
    lastTeleportAt = now
    return true
end
local playerTPFrame = Instance.new("Frame")
playerTPFrame.Name = "PlayerTPPanel"
playerTPFrame.Size = UDim2.fromOffset(CONFIG.UI.PlayerTPSize.X, CONFIG.UI.PlayerTPSize.Y)
playerTPFrame.Position = CONFIG.UI.PlayerTPPosition
playerTPFrame.BackgroundColor3 = CONFIG.UI.Panel
playerTPFrame.BorderSizePixel = 0
playerTPFrame.Visible = false
playerTPFrame.ZIndex = 850
playerTPFrame.Parent = gui
addCorner(playerTPFrame, CONFIG.UI.CornerRadius)
applySciFiSurface(playerTPFrame)
local playerTPTitle = Instance.new("TextLabel")
playerTPTitle.Name = "Title"
playerTPTitle.Size = UDim2.new(1, -20, 0, 34)
playerTPTitle.Position = UDim2.fromOffset(10, 8)
playerTPTitle.BackgroundTransparency = 1
playerTPTitle.Text = "PLAYER TP"
playerTPTitle.TextColor3 = Color3.fromRGB(217, 95, 2)
playerTPTitle.TextSize = 18
playerTPTitle.Font = Enum.Font.GothamBold
playerTPTitle.TextXAlignment = Enum.TextXAlignment.Left
playerTPTitle.ZIndex = 851
playerTPTitle.Parent = playerTPFrame
local playerTPScroll = Instance.new("ScrollingFrame")
playerTPScroll.Name = "Scroll"
playerTPScroll.Size = UDim2.new(1, -16, 1, -50)
playerTPScroll.Position = UDim2.fromOffset(8, 44)
playerTPScroll.BackgroundTransparency = 1
playerTPScroll.BorderSizePixel = 0
playerTPScroll.ScrollBarThickness = 5
playerTPScroll.CanvasSize = UDim2.fromOffset(0, 0)
playerTPScroll.ZIndex = 851
playerTPScroll.Parent = playerTPFrame
local playerTPLayout = Instance.new("UIListLayout")
playerTPLayout.Padding = UDim.new(0, 6)
playerTPLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerTPLayout.Parent = playerTPScroll
addPadding(playerTPScroll, 4, 4, 4, 8)
local PANEL_OPEN_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local PANEL_CLOSE_INFO = TweenInfo.new(0.40, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local panelAppearance = {}
local panelTweens = {}
local panelTargetVisibility = {}
local panelGeneration = {}
local function capturePanelAppearance(panel)
    panelAppearance[panel] = panelAppearance[panel] or {Size = panel.Size, Properties = {}}
    local cache = panelAppearance[panel].Properties
    local function capture(instance)
        if cache[instance] then
            return
        end
        local values = {}
        if instance:IsA("GuiObject") then
            values.BackgroundTransparency = instance.BackgroundTransparency
            if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
                values.TextTransparency = instance.TextTransparency
                values.TextStrokeTransparency = instance.TextStrokeTransparency
            end
            if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
                values.ImageTransparency = instance.ImageTransparency
            end
        elseif instance:IsA("UIStroke") then
            values.Transparency = instance.Transparency
        end
        if next(values) then
            cache[instance] = values
        end
    end
    capture(panel)
    for _, descendant in ipairs(panel:GetDescendants()) do
        capture(descendant)
    end
end
local function cancelPanelTweens(panel)
    local active = panelTweens[panel]
    if active then
        for _, tween in ipairs(active) do
            pcall(function()
                tween:Cancel()
            end)
        end
    end
    panelTweens[panel] = {}
end
local function setPanelTransparency(panel, transparency)
    capturePanelAppearance(panel)
    for instance, originals in pairs(panelAppearance[panel].Properties) do
        if instance and instance.Parent then
            for property, originalValue in pairs(originals) do
                if property == "BackgroundTransparency" or property == "TextTransparency"
                    or property == "TextStrokeTransparency" or property == "ImageTransparency"
                    or property == "Transparency" then
                    pcall(function()
                        instance[property] = transparency == 1 and 1 or originalValue
                    end)
                end
            end
        end
    end
end
local function animatePanel(panel, shouldShow)
    if not panel or not panel.Parent then
        return
    end
    capturePanelAppearance(panel)
    panelTargetVisibility[panel] = shouldShow
    panelGeneration[panel] = (panelGeneration[panel] or 0) + 1
    local generation = panelGeneration[panel]
    cancelPanelTweens(panel)
    local info = panelAppearance[panel]
    local sizeTweenInfo = shouldShow and PANEL_OPEN_INFO or PANEL_CLOSE_INFO
    if shouldShow then
        if not panel.Visible then
            panel.Size = UDim2.fromOffset(0, 0)
            panel.Visible = true
            setPanelTransparency(panel, 1)
        end
    end
    local tweens = panelTweens[panel]
    local panelGoal = {Size = shouldShow and info.Size or UDim2.fromOffset(0, 0)}
    local sizeTween = TweenService:Create(panel, sizeTweenInfo, panelGoal)
    table.insert(tweens, sizeTween)
    for instance, originalValues in pairs(info.Properties) do
        if instance and instance.Parent then
            local goal = {}
            for property, originalValue in pairs(originalValues) do
                if property == "BackgroundTransparency" or property == "TextTransparency"
                    or property == "TextStrokeTransparency" or property == "ImageTransparency"
                    or property == "Transparency" then
                    goal[property] = shouldShow and originalValue or 1
                end
            end
            if next(goal) then
                local tween = TweenService:Create(instance, sizeTweenInfo, goal)
                table.insert(tweens, tween)
                tween:Play()
            end
        end
    end
    sizeTween:Play()
    task.spawn(function()
        sizeTween.Completed:Wait()
        if panelGeneration[panel] ~= generation then
            return
        end
        if not shouldShow then
            panel.Visible = false
        end
    end)
end
local function togglePanel(panel)
    local showing = panelTargetVisibility[panel]
    if showing == nil then
        showing = panel.Visible
    end
    animatePanel(panel, not showing)
end
local guiVisible = true
local localWasVisibleBeforeGuiHide = false
local playerTPWasVisibleBeforeGuiHide = false
local function toggleGuiVisibility()
    if guiVisible then
        guiVisible = false
        localWasVisibleBeforeGuiHide = panelTargetVisibility[localFrame] == true or localFrame.Visible
        playerTPWasVisibleBeforeGuiHide = panelTargetVisibility[playerTPFrame] == true or playerTPFrame.Visible
        animatePanel(mainFrame, false)
        if localWasVisibleBeforeGuiHide then
            animatePanel(localFrame, false)
        end
        if playerTPWasVisibleBeforeGuiHide then
            animatePanel(playerTPFrame, false)
        end
        task.delay(0.42, function()
            if not guiVisible and gui and gui.Parent then
                gui.Enabled = false
            end
        end)
    else
        guiVisible = true
        gui.Enabled = true
        animatePanel(mainFrame, true)
        if localWasVisibleBeforeGuiHide then
            animatePanel(localFrame, true)
        end
        if playerTPWasVisibleBeforeGuiHide then
            animatePanel(playerTPFrame, true)
        end
    end
end
local function getCharacterParts()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
end
local function isCharacterReady()
    return Character
        and Character.Parent
        and Humanoid
        and Humanoid.Parent
        and HumanoidRootPart
        and HumanoidRootPart.Parent
end
registerPanelEmotes = function(emote)
    if not Humanoid or not Humanoid.Parent then
        return nil
    end

    local description = Humanoid.HumanoidDescription
    if not description then
        warn("[MegaPanel V14] HumanoidDescription is unavailable; cannot register catalog emotes.")
        return nil
    end

    local emoteMap = safeCall("read HumanoidDescription emotes", function()
        return description:GetEmotes()
    end)
    if type(emoteMap) ~= "table" then
        warn("[MegaPanel V14] Could not read the current emote list.")
        return nil
    end

    for name, ids in pairs(emoteMap) do
        if type(ids) == "table" then
            for _, assetId in ipairs(ids) do
                if tonumber(assetId) == emote.Id then
                    return name
                end
            end
        end
    end

    emoteMap[emote.Key] = {emote.Id}
    local registered = safeCall("register catalog emote " .. emote.Label, function()
        description:SetEmotes(emoteMap)
        return true
    end)

    if registered ~= true then
        warn(("[MegaPanel V14] Could not register '%s' (ID %s) in the HumanoidDescription.")
            :format(emote.Label, tostring(emote.Id)))
        return nil
    end

    return emote.Key
end
playPanelEmote = function(emote)
    if not isCharacterReady() then
        warn("[MegaPanel V14] Cannot play emote; character is not ready.")
        return
    end

    local requestHumanoid = Humanoid

    if activeEmoteTrack then
        pcall(function()
            activeEmoteTrack:Stop(0.12)
            activeEmoteTrack:Destroy()
        end)
        activeEmoteTrack = nil
    end

    if activeEmoteAnimation then
        activeEmoteAnimation:Destroy()
        activeEmoteAnimation = nil
    end

    local emoteName = registerPanelEmotes(emote)
    if not emoteName then
        return
    end

    local played = safeCall("play catalog emote " .. emote.Label, function()
        return requestHumanoid:PlayEmoteAsync(emoteName)
    end)

    if played ~= true then
        warn(("[MegaPanel V14] Roblox could not play '%s' (ID %s). Check the emote asset permissions and whether this experience allows user emotes.")
            :format(emote.Label, tostring(emote.Id)))
    end
end
local function snapshotGameMovementValues()
    if not isCharacterReady() then
        return
    end
    gameWalkSpeed = Humanoid.WalkSpeed
    gameJumpPower = Humanoid.JumpPower
    gameUseJumpPower = Humanoid.UseJumpPower
end
local function applyWalkSpeed()
    if not isCharacterReady() then
        return
    end
    if state.WalkSpeedEnabled then
        Humanoid.WalkSpeed = state.WalkSpeed
    else
        Humanoid.WalkSpeed = gameWalkSpeed
    end
end
local function setWalkSpeed(value)
    value = tonumber(value)
    if not value then
        walkSpeedInput.Text = tostring(state.WalkSpeed)
        return
    end
    value = math.clamp(value, CONFIG.WalkSpeed.Min, CONFIG.WalkSpeed.Max)
    state.WalkSpeed = value
    walkSpeedInput.Text = tostring(value)
    applyWalkSpeed()
end
local function applyJumpPower()
    if not isCharacterReady() then
        return
    end
    if state.JumpPowerEnabled then
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = state.JumpPower
    else
        Humanoid.UseJumpPower = gameUseJumpPower
        Humanoid.JumpPower = gameJumpPower
    end
end
local function setJumpPower(value)
    value = tonumber(value)
    if not value then
        jumpPowerInput.Text = tostring(state.JumpPower)
        return
    end
    value = math.clamp(value, CONFIG.JumpPower.Min, CONFIG.JumpPower.Max)
    state.JumpPower = value
    jumpPowerInput.Text = tostring(value)
    applyJumpPower()
end
local function setFlySpeed(value)
    value = tonumber(value)
    if not value then
        flySpeedInput.Text = tostring(state.FlySpeed)
        return
    end
    value = math.clamp(value, CONFIG.Fly.MinSpeed, CONFIG.Fly.MaxSpeed)
    state.FlySpeed = value
    flySpeedInput.Text = tostring(value)
end
addConnection(walkSpeedInput.FocusLost:Connect(function()
    safeCall("WalkSpeed input", setWalkSpeed, walkSpeedInput.Text)
end))
addConnection(jumpPowerInput.FocusLost:Connect(function()
    safeCall("JumpPower input", setJumpPower, jumpPowerInput.Text)
end))
addConnection(flySpeedInput.FocusLost:Connect(function()
    safeCall("FlySpeed input", setFlySpeed, flySpeedInput.Text)
end))
addConnection(walkSpeedToggle.MouseButton1Click:Connect(function()
    safeCall("toggle WalkSpeed", function()
        state.WalkSpeedEnabled = not state.WalkSpeedEnabled
        setButtonState(walkSpeedToggle, state.WalkSpeedEnabled, "WalkSpeed: " .. (state.WalkSpeedEnabled and "ON" or "OFF"))
        applyWalkSpeed()
    end)
end))
addConnection(jumpPowerToggle.MouseButton1Click:Connect(function()
    safeCall("toggle JumpPower", function()
        state.JumpPowerEnabled = not state.JumpPowerEnabled
        setButtonState(jumpPowerToggle, state.JumpPowerEnabled, "JumpPower: " .. (state.JumpPowerEnabled and "ON" or "OFF"))
        applyJumpPower()
    end)
end))
local function setInfiniteJump(enabled)
    state.InfiniteJump = enabled
    setButtonState(infiniteJumpButton, enabled, "Inf. Jump: " .. (enabled and "ON" or "OFF"))
end
addConnection(UserInputService.JumpRequest:Connect(function()
    if not state.InfiniteJump or not isCharacterReady() then
        return
    end
    safeCall("Infinite Jump", function()
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
end))
addConnection(infiniteJumpButton.MouseButton1Click:Connect(function()
    setInfiniteJump(not state.InfiniteJump)
end))
local lastBhopTime = 0
local function setBhop(enabled)
    state.Bhop = enabled
    setButtonState(bhopButton, enabled, "Bhop: " .. (enabled and "ON" or "OFF"))
end
addConnection(bhopButton.MouseButton1Click:Connect(function()
    safeCall("toggle Bhop", function()
        setBhop(not state.Bhop)
    end)
end))
local noclipOriginal = {}
local function applyNoclipToCharacter()
    if not isCharacterReady() then
        return
    end
    for _, instance in ipairs(Character:GetDescendants()) do
        if instance:IsA("BasePart") then
            if noclipOriginal[instance] == nil then
                noclipOriginal[instance] = instance.CanCollide
            end
            instance.CanCollide = false
        end
    end
end
local function stopNoclip()
    for instance, originalValue in pairs(noclipOriginal) do
        if instance and instance.Parent then
            instance.CanCollide = originalValue
        end
    end
    table.clear(noclipOriginal)
end
local function setNoclip(enabled)
    state.Noclip = enabled
    if enabled then
        applyNoclipToCharacter()
    else
        stopNoclip()
    end
    setButtonState(noclipButton, enabled, "Noclip: " .. (enabled and "ON" or "OFF"))
end
addConnection(noclipButton.MouseButton1Click:Connect(function()
    safeCall("toggle Noclip", function()
        setNoclip(not state.Noclip)
    end)
end))
local flyAttachment
local flyVelocity
local flyOrientation
local flyOldAutoRotate
local flyOldPlatformStand
local flyControllerRoot
local flyVehicleMode = false
local function getVehicleControllerRoot()
    if not Humanoid or not Humanoid.Parent then
        return nil
    end
    local seatPart = Humanoid.SeatPart
    if not seatPart or not seatPart:IsA("BasePart") then
        return nil
    end
    local root = seatPart.AssemblyRootPart
    if not root or not root.Parent then
        return nil
    end
    if root == HumanoidRootPart then
        return nil
    end
    if root.Anchored then
        return nil
    end
    return root
end
local function destroyFlyControllers()
    if flyVelocity then
        safeCall("destroy fly velocity", function()
            flyVelocity:Destroy()
        end)
        flyVelocity = nil
    end
    if flyOrientation then
        safeCall("destroy fly orientation", function()
            flyOrientation:Destroy()
        end)
        flyOrientation = nil
    end
    if flyAttachment then
        safeCall("destroy fly attachment", function()
            flyAttachment:Destroy()
        end)
        flyAttachment = nil
    end
    flyControllerRoot = nil
    flyVehicleMode = false
end
local function createFlyControllers(root, vehicleMode)
    if not root or not root.Parent then
        return false
    end
    if root.Anchored then
        return false
    end
    destroyFlyControllers()
    flyControllerRoot = root
    flyVehicleMode = vehicleMode
    flyAttachment = Instance.new("Attachment")
    flyAttachment.Name = "MegaPanelV13_FlyAttachment"
    flyAttachment.Parent = root
    flyVelocity = Instance.new("LinearVelocity")
    flyVelocity.Name = "MegaPanelV13_LinearVelocity"
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    flyVelocity.ForceLimitsEnabled = false
    flyVelocity.VectorVelocity = Vector3.zero
    flyVelocity.Parent = root
    flyOrientation = Instance.new("AlignOrientation")
    flyOrientation.Name = "MegaPanelV13_AlignOrientation"
    flyOrientation.Attachment0 = flyAttachment
    flyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyOrientation.RigidityEnabled = true
    flyOrientation.Responsiveness = 200
    flyOrientation.MaxTorque = math.huge
    flyOrientation.Parent = root
    return true
end
local function stopFlying()
    state.Flying = false
    destroyFlyControllers()
    if Humanoid and Humanoid.Parent then
        if flyOldAutoRotate ~= nil then
            Humanoid.AutoRotate = flyOldAutoRotate
        else
            Humanoid.AutoRotate = true
        end
        if flyOldPlatformStand ~= nil then
            Humanoid.PlatformStand = flyOldPlatformStand
        else
            Humanoid.PlatformStand = false
        end
        applyWalkSpeed()
    end
    flyOldAutoRotate = nil
    flyOldPlatformStand = nil
    setButtonState(flyButton, false, "Flying: OFF")
end
local function startFlying()
    if not isCharacterReady() then
        return
    end
    if state.Flying then
        local vehicleRoot = getVehicleControllerRoot()
        if flyVehicleMode and vehicleRoot and vehicleRoot ~= flyControllerRoot then
            if not createFlyControllers(vehicleRoot, true) then
                stopFlying()
            end
        elseif not flyVehicleMode and not vehicleRoot and flyControllerRoot ~= HumanoidRootPart then
            if not createFlyControllers(HumanoidRootPart, false) then
                stopFlying()
            end
        end
        return
    end
    state.Flying = true
    flyOldAutoRotate = Humanoid.AutoRotate
    flyOldPlatformStand = Humanoid.PlatformStand
    local vehicleRoot = getVehicleControllerRoot()
    if vehicleRoot then
        Humanoid.AutoRotate = false
        if not createFlyControllers(vehicleRoot, true) then
            state.Flying = false
            Humanoid.AutoRotate = flyOldAutoRotate
            flyOldAutoRotate = nil
            flyOldPlatformStand = nil
            return
        end
    else
        Humanoid.AutoRotate = false
        Humanoid.PlatformStand = true
        if not createFlyControllers(HumanoidRootPart, false) then
            state.Flying = false
            Humanoid.AutoRotate = flyOldAutoRotate
            Humanoid.PlatformStand = flyOldPlatformStand
            flyOldAutoRotate = nil
            flyOldPlatformStand = nil
            return
        end
    end
    setButtonState(flyButton, true, "Flying: ON")
end
local function updateFlyControllerMode()
    if not state.Flying or not isCharacterReady() then
        return
    end
    local vehicleRoot = getVehicleControllerRoot()
    if vehicleRoot then
        if not flyVehicleMode or flyControllerRoot ~= vehicleRoot then
            if Humanoid then
                Humanoid.PlatformStand = false
                Humanoid.AutoRotate = false
            end
            createFlyControllers(vehicleRoot, true)
        end
    else
        if flyVehicleMode then
            destroyFlyControllers()
            if Humanoid then
                Humanoid.AutoRotate = false
                Humanoid.PlatformStand = true
            end
            createFlyControllers(HumanoidRootPart, false)
        end
    end
end
local function updateFly()
    if not state.Flying then
        return
    end
    if not isCharacterReady() then
        return
    end
    if UserInputService:GetFocusedTextBox() then
        if flyVelocity then
            flyVelocity.VectorVelocity = Vector3.zero
        end
        return
    end
    updateFlyControllerMode()
    if not flyVelocity or not flyOrientation or not flyControllerRoot then
        return
    end
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local movement = Vector3.zero
    local forward = camera.CFrame.LookVector
    local right = camera.CFrame.RightVector
    local up = Vector3.yAxis
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        movement += forward
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        movement -= forward
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        movement += right
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        movement -= right
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        movement += up
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        movement -= up
    end
    if movement.Magnitude > 0 then
        movement = movement.Unit * state.FlySpeed
    end
    safeCall("update fly velocity", function()
        if flyVelocity and flyVelocity.Parent then
            flyVelocity.VectorVelocity = movement
        end
    end)
    local look = camera.CFrame.LookVector
    if look.Magnitude > 0 then
        safeCall("update fly orientation", function()
            if flyOrientation and flyOrientation.Parent then
                flyOrientation.CFrame = CFrame.lookAt(Vector3.zero, look)
            end
        end)
    end
end
addConnection(flyButton.MouseButton1Click:Connect(function()
    safeCall("toggle Fly", function()
        if state.Flying then
            stopFlying()
        else
            startFlying()
        end
    end)
end))
local originalLighting
local lastFullBrightUpdate = 0
local function startFullBright()
    if originalLighting then
        return
    end
    originalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    }
    setButtonState(fullBrightButton, true, "FullBright: ON")
end
local function stopFullBright()
    if not originalLighting then
        return
    end
    safeCall("restore lighting", function()
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end)
    originalLighting = nil
    setButtonState(fullBrightButton, false, "FullBright: OFF")
end
local function updateFullBright()
    if not state.FullBright then
        return
    end
    if os.clock() - lastFullBrightUpdate < CONFIG.FullBright.RefreshInterval then
        return
    end
    lastFullBrightUpdate = os.clock()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
end
local function setFullBright(enabled)
    state.FullBright = enabled
    if enabled then
        startFullBright()
    else
        stopFullBright()
    end
end
addConnection(fullBrightButton.MouseButton1Click:Connect(function()
    safeCall("toggle FullBright", function()
        setFullBright(not state.FullBright)
    end)
end))
local highlightFolder = Instance.new("Folder")
highlightFolder.Name = "MegaPanelV13_Highlights"
highlightFolder.Parent = workspace
local highlights = {}
local lastHighlightRefresh = 0
local lastHighlightInfoRefresh = 0
local function getTargetPart(player)
    local character = player.Character
    if not character then
        return nil
    end
    return character:FindFirstChild(CONFIG.Aimbot.TargetPart)
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end
local function getTargetHumanoid(player)
    local character = player.Character
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end
local function isAlive(player)
    local targetPart = getTargetPart(player)
    local humanoid = getTargetHumanoid(player)
    return humanoid ~= nil and humanoid.Health > 0 and targetPart ~= nil
end
local function isTeammate(player)
    if LocalPlayer.Team == nil then
        return false
    end
    return player.Team == LocalPlayer.Team
end
local function getHighlightColor(player)
    if player == state.CurrentTarget then
        return CONFIG.UI.Yellow
    end
    if isTeammate(player) then
        return CONFIG.UI.Green
    end
    return CONFIG.UI.Red
end
local function getOrCreateInfoGui(player, character)
    local info = highlights[player]
    if not info then
        info = {}
        highlights[player] = info
    end
    local head = character:FindFirstChild("Head")
    if not head then
        if info.billboard then
            info.billboard.Enabled = false
        end
        return info
    end
    if not info.billboard or not info.billboard.Parent then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "MegaPanelV13_PlayerInfo_" .. tostring(player.UserId)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.Size = UDim2.fromOffset(CONFIG.Highlight.BillboardSize.X, CONFIG.Highlight.BillboardSize.Y)
        billboard.StudsOffset = CONFIG.Highlight.StudsOffset
        billboard.MaxDistance = 100000
        billboard.Enabled = state.Highlight
        billboard.Adornee = head
        billboard.Parent = PlayerGui
        local label = Instance.new("TextLabel")
        label.Name = "Info"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = CONFIG.UI.White
        label.TextStrokeTransparency = 0.15
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.RichText = false
        label.Parent = billboard
        info.billboard = billboard
        info.label = label
    end
    info.billboard.Adornee = head
    info.billboard.Enabled = state.Highlight
    return info
end
local function updatePlayerInfo(player)
    if player == LocalPlayer then
        return
    end
    local info = highlights[player]
    if not info then
        return
    end
    local character = player.Character
    local humanoid = getTargetHumanoid(player)
    local head = character and character:FindFirstChild("Head")
    if not character or not humanoid or humanoid.Health <= 0 or not head then
        if info.highlight then
            info.highlight.Enabled = false
        end
        if info.billboard then
            info.billboard.Enabled = false
        end
        return
    end
    if info.label then
        local nickname = player.DisplayName
        if not nickname or nickname == "" then
            nickname = player.Name
        end
        info.label.Text = string.format("%s\nHP: %.0f / %.0f", nickname, math.max(0, humanoid.Health), math.max(0, humanoid.MaxHealth))
        info.label.TextColor3 = getHighlightColor(player)
    end
    if info.billboard then
        info.billboard.Adornee = head
        info.billboard.Enabled = state.Highlight
    end
end
local function createOrUpdateHighlight(player)
    if player == LocalPlayer then
        return
    end
    local character = player.Character
    local humanoid = getTargetHumanoid(player)
    local head = character and character:FindFirstChild("Head")
    local info = highlights[player]
    if not info then
        info = {}
        highlights[player] = info
    end
    if not state.Highlight then
        return
    end
    if not character or not humanoid or humanoid.Health <= 0 or not head then
        if info.highlight then
            safeCall("release invalid highlight", function()
                info.highlight:Destroy()
            end)
            info.highlight = nil
        end
        if info.billboard then
            info.billboard.Enabled = false
        end
        return
    end
    local highlight = info.highlight
    if not highlight or not highlight.Parent then
        highlight = Instance.new("Highlight")
        highlight.Name = "MegaPanelV13_Player_" .. tostring(player.UserId)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = CONFIG.Highlight.FillTransparency
        highlight.OutlineTransparency = CONFIG.Highlight.OutlineTransparency
        highlight.Parent = highlightFolder
        info.highlight = highlight
    end
    local color = getHighlightColor(player)
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Enabled = true
    getOrCreateInfoGui(player, character)
    updatePlayerInfo(player)
end
local function removeHighlight(player)
    local info = highlights[player]
    if not info then
        return
    end
    if info.highlight then
        safeCall("remove highlight", function()
            info.highlight:Destroy()
        end)
    end
    if info.billboard then
        safeCall("remove highlight info", function()
            info.billboard:Destroy()
        end)
    end
    highlights[player] = nil
end
local function refreshHighlights(force)
    if not state.Highlight then
        return
    end
    local now = os.clock()
    if not force and now - lastHighlightRefresh < CONFIG.Highlight.RefreshInterval then
        return
    end
    lastHighlightRefresh = now
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            safeCall("refresh highlight for " .. player.Name, createOrUpdateHighlight, player)
        end
    end
    for player, info in pairs(highlights) do
        if not player.Parent then
            removeHighlight(player)
        elseif not player.Character then
            if info.highlight then
                info.highlight.Enabled = false
            end
            if info.billboard then
                info.billboard.Enabled = false
            end
        end
    end
end
local function updateHighlightInfo(force)
    if not state.Highlight then
        return
    end
    local now = os.clock()
    if not force and now - lastHighlightInfoRefresh < CONFIG.Highlight.InfoRefreshInterval then
        return
    end
    lastHighlightInfoRefresh = now
    for player in pairs(highlights) do
        safeCall("update highlight info for " .. player.Name, updatePlayerInfo, player)
    end
end
local function setHighlight(enabled)
    state.Highlight = enabled
    if enabled then
        refreshHighlights(true)
        updateHighlightInfo(true)
    else
        for _, info in pairs(highlights) do
            if info.highlight then
                safeCall("release highlight slot", function()
                    info.highlight:Destroy()
                end)
                info.highlight = nil
            end
            if info.billboard then
                info.billboard.Enabled = false
            end
        end
    end
    setButtonState(highlightButton, enabled, "Highlight: " .. (enabled and "ON" or "OFF"))
end
addConnection(highlightButton.MouseButton1Click:Connect(function()
    safeCall("toggle Highlight", function()
        setHighlight(not state.Highlight)
    end)
end))
local function hookPlayerHighlightEvents(player)
    if player == LocalPlayer then
        return
    end
    addPlayerConnection(player, player.CharacterAdded:Connect(function()
        task.defer(function()
            if state.Highlight then
                safeCall("character highlight rebuild", refreshHighlights, true)
            end
        end)
    end))
    addPlayerConnection(player, player:GetPropertyChangedSignal("Team"):Connect(function()
        if state.Highlight then
            safeCall("team highlight refresh", refreshHighlights, true)
        end
    end))
end
addConnection(Players.PlayerAdded:Connect(function(player)
    hookPlayerHighlightEvents(player)
    task.defer(updateLocalCanvas)
end))
addConnection(Players.PlayerRemoving:Connect(function(player)
    disconnectPlayerConnections(player)
    removeHighlight(player)
    task.defer(updateLocalCanvas)
end))
for _, player in ipairs(Players:GetPlayers()) do
    hookPlayerHighlightEvents(player)
end
local function isValidAimbotTarget(player)
    if player == nil or player == LocalPlayer then
        return false
    end
    if not player.Parent then
        return false
    end
    if not isAlive(player) then
        return false
    end
    if LocalPlayer.Team == nil then
        return true
    end
    if player.Team == LocalPlayer.Team then
        return false
    end
    return true
end
local function getValidTargets()
    local targets = {}
    if not isCharacterReady() then
        return targets
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidAimbotTarget(player) then
            table.insert(targets, player)
        end
    end
    table.sort(targets, function(a, b)
        local aPart = getTargetPart(a)
        local bPart = getTargetPart(b)
        if not aPart or not bPart or not HumanoidRootPart then
            return false
        end
        local aDistance = (aPart.Position - HumanoidRootPart.Position).Magnitude
        local bDistance = (bPart.Position - HumanoidRootPart.Position).Magnitude
        return aDistance < bDistance
    end)
    return targets
end
local function setCurrentTarget(player)
    if player and not isValidAimbotTarget(player) then
        player = nil
    end
    state.CurrentTarget = player
    if player then
        targetStatus.Text = "TARGET: " .. player.Name
        targetStatus.TextColor3 = CONFIG.UI.Yellow
    else
        targetStatus.Text = "TARGET: NONE"
        targetStatus.TextColor3 = CONFIG.UI.Gray
    end
    if state.Highlight then
        refreshHighlights(true)
    end
end
local function chooseTarget()
    local targets = getValidTargets()
    if #targets == 0 then
        state.TargetIndex = 1
        setCurrentTarget(nil)
        return
    end
    if state.TargetIndex < 1 or state.TargetIndex > #targets then
        state.TargetIndex = 1
    end
    setCurrentTarget(targets[state.TargetIndex])
end
local function nextTarget()
    local targets = getValidTargets()
    if #targets == 0 then
        state.TargetIndex = 1
        setCurrentTarget(nil)
        return
    end
    local currentPosition = 0
    for index, player in ipairs(targets) do
        if player == state.CurrentTarget then
            currentPosition = index
            break
        end
    end
    if currentPosition == 0 then
        currentPosition = 1
    else
        currentPosition += 1
    end
    if currentPosition > #targets then
        currentPosition = 1
    end
    state.TargetIndex = currentPosition
    setCurrentTarget(targets[currentPosition])
end
local function setAimbot(enabled)
    state.Aimbot = enabled
    if enabled then
        state.TargetIndex = 1
        chooseTarget()
    else
        setCurrentTarget(nil)
    end
    setButtonState(
        aimbotButton,
        enabled,
        "Aimbot: " .. (enabled and "ON" or "OFF")
    )
end
local function updateAimbot(deltaTime)
    if not state.Aimbot or not isCharacterReady() then
        return
    end
    if UserInputService:GetFocusedTextBox() then
        return
    end
    local target = state.CurrentTarget
    if not isValidAimbotTarget(target) then
        chooseTarget()
        target = state.CurrentTarget
    end
    if not target then
        return
    end
    local targetCharacter = target.Character
    local targetHead = targetCharacter and targetCharacter:FindFirstChild("Head")
    local camera = workspace.CurrentCamera
    if not targetHead or not camera then
        return
    end
    local origin = camera.CFrame.Position
    local direction = targetHead.Position - origin
    if direction.Magnitude < 0.001 then
        return
    end
    local desired = CFrame.lookAt(origin, origin + direction.Unit)
    local dt = math.max(deltaTime or (1 / 60), 0)
    local baseAlpha = math.clamp(CONFIG.Aimbot.Smoothness, 0.01, 1)
    local alpha = 1 - math.pow(1 - baseAlpha, dt * 60)
    camera.CFrame = camera.CFrame:Lerp(desired, alpha)
end
addConnection(aimbotButton.MouseButton1Click:Connect(function()
    safeCall("toggle Aimbot", function()
        setAimbot(not state.Aimbot)
    end)
end))
local function createPlayerTPButton(player)
    if player == LocalPlayer then
        return
    end
    local button = Instance.new("TextButton")
    button.Name = "TP_" .. tostring(player.UserId)
    button.LayoutOrder = player.UserId
    button.Size = UDim2.new(1, -8, 0, 36)
    button.BackgroundColor3 = CONFIG.UI.Button
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = player.Name
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.ZIndex = 852
    button.Parent = playerTPScroll
    addCorner(button, 7)
    addStroke(button, Color3.fromRGB(255, 255, 255), 0.72, 1)
    addInstanceConnection(button, button.MouseEnter:Connect(function()
        button.BackgroundColor3 = CONFIG.UI.ButtonHover
    end))
    addInstanceConnection(button, button.MouseLeave:Connect(function()
        button.BackgroundColor3 = CONFIG.UI.Button
    end))
    addInstanceConnection(button, button.MouseButton1Click:Connect(function()
        safeCall("teleport to " .. player.Name, function()
            if not isCharacterReady() then
                return
            end
            local targetCharacter = player.Character
            if not targetCharacter then
                return
            end
            local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
            if not targetRoot then
                return
            end
            if not consumeTeleportCooldown() then
                return
            end
            HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        end)
    end))
end
local function updatePlayerTPList()
    for _, child in ipairs(playerTPScroll:GetChildren()) do
        if child:IsA("TextButton") then
            disconnectInstanceConnections(child)
            child:Destroy()
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        createPlayerTPButton(player)
    end
    playerTPScroll.CanvasSize = UDim2.fromOffset(0, playerTPLayout.AbsoluteContentSize.Y + 16)
end
addConnection(playerTPLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerTPScroll.CanvasSize = UDim2.fromOffset(0, playerTPLayout.AbsoluteContentSize.Y + 16)
end))
addConnection(Players.PlayerAdded:Connect(function()
    task.defer(updatePlayerTPList)
end))
addConnection(Players.PlayerRemoving:Connect(function()
    task.defer(updatePlayerTPList)
end))
updatePlayerTPList()
addConnection(playerTPButton.MouseButton1Click:Connect(function()
    togglePanel(playerTPFrame)
end))
addConnection(localPlayerButton.MouseButton1Click:Connect(function()
    togglePanel(localFrame)
end))
local mouse = LocalPlayer:GetMouse()
local function mouseIsOverOurGui()
    local guiObjects = PlayerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
    for _, object in ipairs(guiObjects) do
        if object:IsDescendantOf(gui) then
            return true
        end
    end
    return false
end
local function doClickTP()
    if not state.ClickTP or not isCharacterReady() then
        return
    end
    if mouseIsOverOurGui() then
        return
    end
    if not mouse.Hit or not consumeTeleportCooldown() then
        return
    end
    safeCall("Click TP", function()
        HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
    end)
end
addConnection(mouse.Button1Down:Connect(function()
    doClickTP()
end))
local function setClickTP(enabled)
    state.ClickTP = enabled
    setButtonState(clickTPButton, enabled, "Click TP: " .. (enabled and "ON" or "OFF"))
end
addConnection(clickTPButton.MouseButton1Click:Connect(function()
    safeCall("toggle Click TP", function()
        setClickTP(not state.ClickTP)
    end)
end))
local antiAFKConnection
local function stopAntiAFK()
    state.AntiAFK = false
    if antiAFKConnection then
        disconnectConnection(antiAFKConnection)
        antiAFKConnection = nil
    end
    setButtonState(antiAFKButton, false, "AFK Alert: OFF")
end
local function startAntiAFK()
    if antiAFKConnection then
        disconnectConnection(antiAFKConnection)
        antiAFKConnection = nil
    end
    state.AntiAFK = true
    antiAFKConnection = LocalPlayer.Idled:Connect(function(idleTime)
        if not state.AntiAFK or destroyed then
            return
        end
        warn(("[MegaPanel V14] AFK detected after %.0f seconds. Roblox may disconnect idle players automatically.")
            :format(idleTime or 0))
        stopAntiAFK()
    end)
    addConnection(antiAFKConnection)
    setButtonState(antiAFKButton, true, "AFK Alert: ON")
end
local function setAntiAFK(enabled)
    if enabled then
        startAntiAFK()
    else
        stopAntiAFK()
    end
end
addConnection(antiAFKButton.MouseButton1Click:Connect(function()
    safeCall("toggle AFK Alert", function()
        setAntiAFK(not state.AntiAFK)
    end)
end))
local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition
    local activeInput
    addConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        dragStart = input.Position
        startPosition = target.Position
        activeInput = input
        local changedConnection
        changedConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                activeInput = nil
                disconnectConnection(changedConnection)
                changedConnection = nil
            end
        end)
        addConnection(changedConnection)
    end))
    addConnection(handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            activeInput = input
        end
    end))
    addConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= activeInput then
            return
        end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end))
end
makeDraggable(title, mainFrame)
makeDraggable(localTitle, localFrame)
makeDraggable(playerTPTitle, playerTPFrame)
local function setupMovementWatchers()
    if not Humanoid then
        return
    end
    if walkSpeedChangedConnection then
        disconnectConnection(walkSpeedChangedConnection)
    end
    if jumpPowerChangedConnection then
        disconnectConnection(jumpPowerChangedConnection)
    end
    walkSpeedChangedConnection = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if not state.WalkSpeedEnabled and Humanoid and Humanoid.Parent then
            gameWalkSpeed = Humanoid.WalkSpeed
        end
    end)
    jumpPowerChangedConnection = Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if not state.JumpPowerEnabled and Humanoid and Humanoid.Parent then
            gameJumpPower = Humanoid.JumpPower
        end
    end)
    addConnection(walkSpeedChangedConnection)
    addConnection(jumpPowerChangedConnection)
end
local function setupCharacter(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    if state.Flying then
        destroyFlyControllers()
    end
    gameWalkSpeed = Humanoid.WalkSpeed
    gameJumpPower = Humanoid.JumpPower
    gameUseJumpPower = Humanoid.UseJumpPower
    if state.WalkSpeedEnabled then
        Humanoid.WalkSpeed = state.WalkSpeed
    end
    if state.JumpPowerEnabled then
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = state.JumpPower
    end
    if state.Noclip then
        table.clear(noclipOriginal)
        applyNoclipToCharacter()
    end
    if humanoidDiedConnection then
        disconnectConnection(humanoidDiedConnection)
    end
    humanoidDiedConnection = Humanoid.Died:Connect(function()
        if state.Flying then
            stopFlying()
        end
    end)
    addConnection(humanoidDiedConnection)
    task.defer(function()
        if state.Highlight then
            safeCall("post-respawn highlight refresh", refreshHighlights)
        end
    end)
end
addConnection(LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    safeCall("CharacterAdded setup", function()
        local shouldFlyAgain = state.Flying
        local shouldNoclipAgain = state.Noclip
        if state.Flying then
            stopFlying()
        end
        table.clear(noclipOriginal)
        setupCharacter(newCharacter)
        setupMovementWatchers()
        if shouldNoclipAgain then
            state.Noclip = true
            setButtonState(noclipButton, true, "Noclip: ON")
            applyNoclipToCharacter()
        end
        if shouldFlyAgain then
            task.defer(function()
                if isCharacterReady() then
                    startFlying()
                end
            end)
        end
    end)
end))
local lastNoclipUpdate = 0
local fpsFrames = 0
local fpsTimer = 0
local pingTimer = 0
RunService:BindToRenderStep(
    "MegaPanelV13_Render",
    Enum.RenderPriority.Camera.Value + 1,
    function(deltaTime)
        if not gui.Parent then
            return
        end
        fpsFrames += 1
        fpsTimer += deltaTime
        pingTimer += deltaTime
        if fpsTimer >= 0.5 then
            local fpsValue = math.floor((fpsFrames / fpsTimer) + 0.5)
            fpsFrames = 0
            fpsTimer = 0
            fpsLabel.Text = "FPS: " .. fpsValue
        end
        if pingTimer >= 0.5 then
            pingTimer = 0
            safeCall("update Ping", function()
                local ping = LocalPlayer:GetNetworkPing()
                if typeof(ping) == "number" then
                    local pingMS = math.floor(ping * 1000 + 0.5)
                    pingLabel.Text = "PING: " .. pingMS .. " ms"
                end
            end)
        end
        updateFly()
        updateAimbot(deltaTime)
        if state.Highlight then
            refreshHighlights(false)
            updateHighlightInfo(false)
        end
        updateFullBright()
        if state.Noclip and os.clock() - lastNoclipUpdate >= CONFIG.Noclip.RefreshInterval then
            lastNoclipUpdate = os.clock()
            applyNoclipToCharacter()
        end
        if state.Bhop
            and isCharacterReady()
            and os.clock() - lastBhopTime >= CONFIG.Bhop.Interval
            and Humanoid.FloorMaterial ~= Enum.Material.Air then
            lastBhopTime = os.clock()
            Humanoid.Jump = true
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if isCharacterReady() then
            if state.WalkSpeedEnabled and not state.Flying then
                Humanoid.WalkSpeed = state.WalkSpeed
            end
            if state.JumpPowerEnabled and not state.Flying then
                Humanoid.UseJumpPower = true
                Humanoid.JumpPower = state.JumpPower
            end
        end
    end
)
local function bindKey(actionName, keyCode, callback)
    if not keyCode then
        return
    end
    table.insert(ActionNames, actionName)
    ContextActionService:BindAction(
        actionName,
        function(_, inputState)
            if destroyed then
                return Enum.ContextActionResult.Pass
            end
            if inputState ~= Enum.UserInputState.Begin then
                return Enum.ContextActionResult.Pass
            end
            if keyCode ~= CONFIG.FeatureKeys.ToggleGui
                and UserInputService:GetFocusedTextBox() then
                return Enum.ContextActionResult.Pass
            end
            safeCall("hotkey " .. actionName, callback)
            return Enum.ContextActionResult.Sink
        end,
        false,
        keyCode
    )
end
bindKey("MegaPanelV13_ToggleGui", CONFIG.FeatureKeys.ToggleGui, function()
    toggleGuiVisibility()
end)
bindKey("MegaPanelV13_Fly", CONFIG.FeatureKeys.Fly, function()
    if state.Flying then
        stopFlying()
    else
        startFlying()
    end
end)
bindKey("MegaPanelV13_InfiniteJump", CONFIG.FeatureKeys.InfiniteJump, function()
    setInfiniteJump(not state.InfiniteJump)
end)
bindKey("MegaPanelV13_Noclip", CONFIG.FeatureKeys.Noclip, function()
    setNoclip(not state.Noclip)
end)
bindKey("MegaPanelV13_Bhop", CONFIG.FeatureKeys.Bhop, function()
    setBhop(not state.Bhop)
end)
bindKey("MegaPanelV13_Aimbot", CONFIG.FeatureKeys.Aimbot, function()
    setAimbot(not state.Aimbot)
end)
bindKey("MegaPanelV13_NextTarget", CONFIG.FeatureKeys.NextTarget, function()
    if state.Aimbot then
        nextTarget()
    end
end)
bindKey("MegaPanelV13_Highlight", CONFIG.FeatureKeys.Highlight, function()
    setHighlight(not state.Highlight)
end)
bindKey("MegaPanelV13_AFKAlert", CONFIG.FeatureKeys.AntiAFK, function()
    setAntiAFK(not state.AntiAFK)
end)
bindKey("MegaPanelV13_FullBright", CONFIG.FeatureKeys.FullBright, function()
    setFullBright(not state.FullBright)
end)
bindKey("MegaPanelV13_ClickTP", CONFIG.FeatureKeys.ClickTP, function()
    setClickTP(not state.ClickTP)
end)
bindKey("MegaPanelV13_PlayerTP", CONFIG.FeatureKeys.PlayerTP, function()
    togglePanel(playerTPFrame)
end)
bindKey("MegaPanelV13_LocalPlayer", CONFIG.FeatureKeys.LocalPlayer, function()
    togglePanel(localFrame)
end)
getCharacterParts()
snapshotGameMovementValues()
setupCharacter(Character)
setupMovementWatchers()
safeCall("initial highlight refresh", refreshHighlights)
setButtonState(infiniteJumpButton, state.InfiniteJump, "Inf. Jump: " .. (state.InfiniteJump and "ON" or "OFF"))
setButtonState(flyButton, state.Flying, "Flying: " .. (state.Flying and "ON" or "OFF"))
setButtonState(aimbotButton, state.Aimbot, "Aimbot: " .. (state.Aimbot and "ON" or "OFF"))
setButtonState(noclipButton, state.Noclip, "Noclip: " .. (state.Noclip and "ON" or "OFF"))
setButtonState(bhopButton, state.Bhop, "Bhop: " .. (state.Bhop and "ON" or "OFF"))
setButtonState(highlightButton, state.Highlight, "Highlight: " .. (state.Highlight and "ON" or "OFF"))
setButtonState(walkSpeedToggle, state.WalkSpeedEnabled, "WalkSpeed: " .. (state.WalkSpeedEnabled and "ON" or "OFF"))
setButtonState(jumpPowerToggle, state.JumpPowerEnabled, "JumpPower: " .. (state.JumpPowerEnabled and "ON" or "OFF"))
setButtonState(antiAFKButton, state.AntiAFK, "AFK Alert: " .. (state.AntiAFK and "ON" or "OFF"))
setButtonState(clickTPButton, state.ClickTP, "Click TP: " .. (state.ClickTP and "ON" or "OFF"))
setButtonState(fullBrightButton, state.FullBright, "FullBright: " .. (state.FullBright and "ON" or "OFF"))
local function cleanup()
    if destroyed then
        return
    end
    destroyed = true
    state.InfiniteJump = false
    state.Bhop = false
    state.Aimbot = false
    state.Noclip = false
    state.ClickTP = false
    state.Highlight = false
    state.WalkSpeedEnabled = false
    state.JumpPowerEnabled = false
    applyWalkSpeed()
    applyJumpPower()
    if activeEmoteTrack then
        pcall(function()
            activeEmoteTrack:Stop(0.1)
            activeEmoteTrack:Destroy()
        end)
        activeEmoteTrack = nil
    end
    if activeEmoteAnimation then
        activeEmoteAnimation:Destroy()
        activeEmoteAnimation = nil
    end
    if state.Flying then
        stopFlying()
    end
    if state.AntiAFK then
        stopAntiAFK()
    end
    if originalLighting then
        state.FullBright = false
        stopFullBright()
    end
    stopNoclip()
    RunService:UnbindFromRenderStep("MegaPanelV13_Render")
    for _, actionName in ipairs(ActionNames) do
        ContextActionService:UnbindAction(actionName)
    end
    table.clear(ActionNames)
    for player, info in pairs(highlights) do
        if info and info.highlight then
            safeCall("cleanup highlight", function()
                info.highlight:Destroy()
            end)
        end
        if info and info.billboard then
            safeCall("cleanup highlight info", function()
                info.billboard:Destroy()
            end)
        end
        highlights[player] = nil
    end
    if highlightFolder then
        safeCall("cleanup highlight folder", function()
            highlightFolder:Destroy()
    end)
    end
    cleanupConnections()
    if gui then
        safeCall("cleanup GUI", function()
            gui:Destroy()
        end)
    end
end
addConnection(closeButton.MouseButton1Click:Connect(function()
    guiVisible = false
    animatePanel(mainFrame, false)
    if localFrame.Visible then
        animatePanel(localFrame, false)
    end
    if playerTPFrame.Visible then
        animatePanel(playerTPFrame, false)
    end
    task.delay(0.42, cleanup)
end))
print("[MegaPanel V14 Cosmic] loaded successfully.")
print("[MegaPanel V14 Cosmic] F1 = GUI")
print("[MegaPanel V14 Cosmic] X = Aimbot")
print("[MegaPanel V14 Cosmic] C = Next Target")
print("[MegaPanel V14 Cosmic] H = Highlight")
print("[MegaPanel V14 Cosmic] K = AFK Alert")
