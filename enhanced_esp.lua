-- Enhanced Roblox Drawing ESP (no team check)
-- Requested updates:
--  * White, thicker, wider boxes
--  * Hover info (tool detection fixed)
--  * Optional tracer lines
--  * Dealer spawn tracker (1/2/3)
--  * Clean menu with tabs + animated open/close

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local SETTINGS = {
    ESP_ENABLED = true,
    HOVER_INFO_ENABLED = true,
    DISTANCE_LIMIT_ENABLED = true,
    TRACERS_ENABLED = true,
    DEALER_TRACKER_ENABLED = true,
    MAX_DISTANCE = 1500,
    BOX_FILLED = false,
    BOX_FILL_TRANSPARENCY = 0.9,
    BOX_WIDTH_SCALE = 1.35,
    BOX_THICKNESS = 2.2,
    MENU_VISIBLE = true,
}

local HEAD_OFFSET = Vector3.new(0, 0.5, 0)
local LEG_OFFSET = Vector3.new(0, 3, 0)

local dealerLabels = {
    [1] = "next to church side fast travel",
    [2] = "inside gold cave",
    [3] = "below fast travel on mountain",
}

local espByPlayer = {}

local function getCurrentDealerInfo()
    local gameFolder = workspace:FindFirstChild("Game")
    local illegalFolder = gameFolder and gameFolder:FindFirstChild("Illegal")
    if not illegalFolder then
        return "Dealer: not found"
    end

    for i = 1, 3 do
        local slot = illegalFolder:FindFirstChild(tostring(i))
        local supplies = slot and slot:FindFirstChild("Illegal Supplies")
        if supplies then
            return string.format("Dealer #%d: %s", i, dealerLabels[i] or "unknown")
        end
    end

    return "Dealer: inactive"
end

local function safeDistance(fromPos, toPos)
    if not fromPos or not toPos then
        return math.huge
    end
    return (fromPos - toPos).Magnitude
end

local function getCurrentToolName(player)
    local character = player.Character
    if character then
        local equipped = character:FindFirstChildOfClass("Tool")
        if equipped then
            return equipped.Name
        end
    end

    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        local anyTool = backpack:FindFirstChildOfClass("Tool")
        if anyTool then
            return anyTool.Name .. " (backpack)"
        end
    end

    return "None"
end

local function hideDrawings(data)
    data.Outline.Visible = false
    data.Box.Visible = false
    data.Info.Visible = false
    data.Line.Visible = false
    data.State.Hovered = false
end

local function removePlayerEsp(player)
    local data = espByPlayer[player]
    if not data then return end

    if data.Outline then data.Outline:Remove() end
    if data.Box then data.Box:Remove() end
    if data.Info then data.Info:Remove() end
    if data.Line then data.Line:Remove() end

    espByPlayer[player] = nil
end

local function addPlayerEsp(player)
    if player == LocalPlayer then return end
    if espByPlayer[player] then return end

    local outline = Drawing.new("Square")
    outline.Visible = false
    outline.Color = Color3.new(0, 0, 0)
    outline.Thickness = SETTINGS.BOX_THICKNESS + 1.5
    outline.Transparency = 1
    outline.Filled = false

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.new(1, 1, 1)
    box.Thickness = SETTINGS.BOX_THICKNESS
    box.Transparency = SETTINGS.BOX_FILLED and SETTINGS.BOX_FILL_TRANSPARENCY or 1
    box.Filled = SETTINGS.BOX_FILLED

    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(255, 255, 255)
    line.Thickness = 1.8
    line.Transparency = 0.95

    local info = Drawing.new("Text")
    info.Visible = false
    info.Color = Color3.fromRGB(255, 255, 255)
    info.Size = 14
    info.Center = false
    info.Outline = true
    info.Font = 2
    info.Text = ""

    espByPlayer[player] = {
        Outline = outline,
        Box = box,
        Info = info,
        Line = line,
        State = {
            Hovered = false,
        },
    }
end

for _, p in ipairs(Players:GetPlayers()) do
    addPlayerEsp(p)
end

Players.PlayerAdded:Connect(addPlayerEsp)
Players.PlayerRemoving:Connect(removePlayerEsp)

-- ===== Menu UI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EnhancedEspMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local okCG = pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)
if not okCG then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(370, 285)
frame.Position = UDim2.fromScale(0.04, 0.2)
frame.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(68, 87, 132)
stroke.Thickness = 1
stroke.Transparency = 0.2
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -18, 0, 34)
title.Position = UDim2.fromOffset(12, 6)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.Text = "Enhanced ESP"
title.Parent = frame

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -18, 0, 18)
hint.Position = UDim2.fromOffset(12, 28)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextColor3 = Color3.fromRGB(151, 168, 210)
hint.Text = "F1 ESP • F2 Hover • F3 Distance • F4 Tracers • RightShift Menu"
hint.Parent = frame

local tabs = Instance.new("Frame")
tabs.BackgroundTransparency = 1
tabs.Size = UDim2.new(1, -16, 0, 30)
tabs.Position = UDim2.fromOffset(8, 50)
tabs.Parent = frame

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.Padding = UDim.new(0, 8)
tabList.Parent = tabs

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Size = UDim2.new(1, -16, 1, -88)
content.Position = UDim2.fromOffset(8, 82)
content.Parent = frame

local visualTab = Instance.new("Frame")
visualTab.Size = UDim2.fromScale(1, 1)
visualTab.BackgroundTransparency = 1
visualTab.Parent = content

local infoTab = Instance.new("Frame")
infoTab.Size = UDim2.fromScale(1, 1)
infoTab.BackgroundTransparency = 1
infoTab.Visible = false
infoTab.Parent = content

local function makeTabButton(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(95, 28)
    btn.BackgroundColor3 = Color3.fromRGB(30, 38, 58)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(220, 230, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    return btn
end

local visualBtn = makeTabButton("Visuals")
visualBtn.Parent = tabs
local infoBtn = makeTabButton("Info")
infoBtn.Parent = tabs

local function activateTab(which)
    local visual = which == "visual"
    visualTab.Visible = visual
    infoTab.Visible = not visual

    TweenService:Create(visualBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = visual and Color3.fromRGB(62, 96, 181) or Color3.fromRGB(30, 38, 58)
    }):Play()

    TweenService:Create(infoBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = (not visual) and Color3.fromRGB(62, 96, 181) or Color3.fromRGB(30, 38, 58)
    }):Play()
end

visualBtn.MouseButton1Click:Connect(function() activateTab("visual") end)
infoBtn.MouseButton1Click:Connect(function() activateTab("info") end)
activateTab("visual")

local function makeToggle(parent, y, label, getter, setter)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 30)
    row.Position = UDim2.fromOffset(4, y)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -92, 1, 0)
    text.Font = Enum.Font.Gotham
    text.TextSize = 14
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextColor3 = Color3.fromRGB(226, 233, 252)
    text.Text = label
    text.Parent = row

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(78, 24)
    button.Position = UDim2.new(1, -80, 0.5, -12)
    button.BorderSizePixel = 0
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 7)
    bc.Parent = button
    button.Parent = row

    local function redraw()
        if getter() then
            button.BackgroundColor3 = Color3.fromRGB(62, 153, 94)
            button.TextColor3 = Color3.fromRGB(240, 255, 243)
            button.Text = "ON"
        else
            button.BackgroundColor3 = Color3.fromRGB(99, 55, 55)
            button.TextColor3 = Color3.fromRGB(255, 236, 236)
            button.Text = "OFF"
        end
    end

    button.MouseButton1Click:Connect(function()
        setter(not getter())
        redraw()
    end)

    redraw()
end

makeToggle(visualTab, 8, "ESP", function() return SETTINGS.ESP_ENABLED end, function(v) SETTINGS.ESP_ENABLED = v end)
makeToggle(visualTab, 44, "Hover info", function() return SETTINGS.HOVER_INFO_ENABLED end, function(v) SETTINGS.HOVER_INFO_ENABLED = v end)
makeToggle(visualTab, 80, "Distance limit", function() return SETTINGS.DISTANCE_LIMIT_ENABLED end, function(v) SETTINGS.DISTANCE_LIMIT_ENABLED = v end)
makeToggle(visualTab, 116, "Tracers", function() return SETTINGS.TRACERS_ENABLED end, function(v) SETTINGS.TRACERS_ENABLED = v end)
makeToggle(visualTab, 152, "Dealer tracker", function() return SETTINGS.DEALER_TRACKER_ENABLED end, function(v) SETTINGS.DEALER_TRACKER_ENABLED = v end)

local distanceLabel = Instance.new("TextLabel")
distanceLabel.BackgroundTransparency = 1
distanceLabel.Size = UDim2.new(1, -8, 0, 26)
distanceLabel.Position = UDim2.fromOffset(4, 188)
distanceLabel.Font = Enum.Font.Gotham
distanceLabel.TextSize = 13
distanceLabel.TextColor3 = Color3.fromRGB(180, 198, 235)
distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
distanceLabel.Text = "Max Distance: " .. tostring(SETTINGS.MAX_DISTANCE) .. " (Shift + MouseWheel)"
distanceLabel.Parent = visualTab

local dealerStatus = Instance.new("TextLabel")
dealerStatus.BackgroundTransparency = 1
dealerStatus.Size = UDim2.new(1, -8, 0, 70)
dealerStatus.Position = UDim2.fromOffset(4, 12)
dealerStatus.Font = Enum.Font.Gotham
dealerStatus.TextSize = 14
dealerStatus.TextWrapped = true
dealerStatus.TextXAlignment = Enum.TextXAlignment.Left
dealerStatus.TextYAlignment = Enum.TextYAlignment.Top
dealerStatus.TextColor3 = Color3.fromRGB(228, 236, 255)
dealerStatus.Text = "Dealer: checking..."
dealerStatus.Parent = infoTab

local tips = Instance.new("TextLabel")
tips.BackgroundTransparency = 1
tips.Size = UDim2.new(1, -8, 0, 90)
tips.Position = UDim2.fromOffset(4, 90)
tips.Font = Enum.Font.Gotham
tips.TextSize = 13
tips.TextWrapped = true
tips.TextXAlignment = Enum.TextXAlignment.Left
tips.TextYAlignment = Enum.TextYAlignment.Top
tips.TextColor3 = Color3.fromRGB(165, 184, 230)
tips.Text = "Hover a box to see player info.\nTracers draw from the bottom-center of your screen to target boxes.\nMenu can be hidden with RightShift."
tips.Parent = infoTab

-- Menu animation + hotkeys
local expandedSize = UDim2.fromOffset(370, 285)
local collapsedSize = UDim2.fromOffset(370, 0)

local function setMenuVisible(visible)
    SETTINGS.MENU_VISIBLE = visible
    frame.ClipsDescendants = true
    TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = visible and expandedSize or collapsedSize
    }):Play()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F1 then
        SETTINGS.ESP_ENABLED = not SETTINGS.ESP_ENABLED
    elseif input.KeyCode == Enum.KeyCode.F2 then
        SETTINGS.HOVER_INFO_ENABLED = not SETTINGS.HOVER_INFO_ENABLED
    elseif input.KeyCode == Enum.KeyCode.F3 then
        SETTINGS.DISTANCE_LIMIT_ENABLED = not SETTINGS.DISTANCE_LIMIT_ENABLED
    elseif input.KeyCode == Enum.KeyCode.F4 then
        SETTINGS.TRACERS_ENABLED = not SETTINGS.TRACERS_ENABLED
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        setMenuVisible(not SETTINGS.MENU_VISIBLE)
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        if input.Position.Z > 0 then
            SETTINGS.MAX_DISTANCE = math.clamp(SETTINGS.MAX_DISTANCE + 50, 100, 5000)
        else
            SETTINGS.MAX_DISTANCE = math.clamp(SETTINGS.MAX_DISTANCE - 50, 100, 5000)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    distanceLabel.Text = "Max Distance: " .. tostring(SETTINGS.MAX_DISTANCE) .. " (Shift + MouseWheel)"
    dealerStatus.Text = SETTINGS.DEALER_TRACKER_ENABLED and getCurrentDealerInfo() or "Dealer tracker disabled"

    if not SETTINGS.ESP_ENABLED then
        for _, data in pairs(espByPlayer) do
            hideDrawings(data)
        end
        return
    end

    local mousePos = UserInputService:GetMouseLocation()

    for player, data in pairs(espByPlayer) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local head = character and character:FindFirstChild("Head")

        if not (character and humanoid and rootPart and head and humanoid.Health > 0) then
            hideDrawings(data)
            continue
        end

        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local dist = safeDistance(localRoot and localRoot.Position, rootPart.Position)
        if SETTINGS.DISTANCE_LIMIT_ENABLED and dist > SETTINGS.MAX_DISTANCE then
            hideDrawings(data)
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen or rootPos.Z <= 0 then
            hideDrawings(data)
            continue
        end

        local headPos = Camera:WorldToViewportPoint(head.Position + HEAD_OFFSET)
        local legPos = Camera:WorldToViewportPoint(rootPart.Position - LEG_OFFSET)

        local width = math.clamp((1000 / rootPos.Z) * SETTINGS.BOX_WIDTH_SCALE, 4, 420)
        local height = math.abs(legPos.Y - headPos.Y)
        local topLeft = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)

        data.Outline.Thickness = SETTINGS.BOX_THICKNESS + 1.5
        data.Box.Thickness = SETTINGS.BOX_THICKNESS

        data.Outline.Size = Vector2.new(width, height)
        data.Outline.Position = topLeft
        data.Outline.Visible = true

        data.Box.Size = Vector2.new(width, height)
        data.Box.Position = topLeft
        data.Box.Color = Color3.fromRGB(255, 255, 255) -- requested white boxes
        data.Box.Visible = true

        if SETTINGS.TRACERS_ENABLED then
            local vp = Camera.ViewportSize
            data.Line.From = Vector2.new(vp.X / 2, vp.Y - 8)
            data.Line.To = Vector2.new(rootPos.X, rootPos.Y)
            data.Line.Visible = true
        else
            data.Line.Visible = false
        end

        local insideX = mousePos.X >= topLeft.X and mousePos.X <= (topLeft.X + width)
        local insideY = mousePos.Y >= topLeft.Y and mousePos.Y <= (topLeft.Y + height)
        local hovered = insideX and insideY
        data.State.Hovered = hovered

        if SETTINGS.HOVER_INFO_ENABLED and hovered then
            local speed = rootPart.AssemblyLinearVelocity.Magnitude
            data.Info.Text = string.format(
                "%s (@%s)\nHP: %d/%d\nDistance: %.0f\nTool: %s\nSpeed: %.1f",
                player.DisplayName,
                player.Name,
                math.floor(humanoid.Health),
                math.floor(humanoid.MaxHealth),
                dist,
                getCurrentToolName(player),
                speed
            )
            data.Info.Position = Vector2.new(topLeft.X + width + 8, topLeft.Y)
            data.Info.Visible = true
        else
            data.Info.Visible = false
        end
    end
end)
