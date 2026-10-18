-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Pudimlinoo/Pudimlinoo-script/main/buildaboat.Lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
assert(player, "Execute este script no cliente, como LocalScript.")
local playerGui = player:WaitForChild("PlayerGui")
local HUB_NAME = "PudimHub_BuildABoat_Interface"
local previous = playerGui:FindFirstChild(HUB_NAME)
if previous then previous:Destroy() end

local Theme = {
    Main = Color3.fromRGB(5, 5, 8),
    Second = Color3.fromRGB(13, 8, 11),
    Red = Color3.fromRGB(240, 30, 55),
    DarkRed = Color3.fromRGB(95, 10, 25),
    Text = Color3.fromRGB(240, 240, 240),
    Muted = Color3.fromRGB(155, 161, 180),
    Button = Color3.fromRGB(26, 10, 15),
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end

local function round(object, radius)
    create("UICorner", {CornerRadius = UDim.new(0, radius)}, object)
end
local function edge(object, transparency)
    return create("UIStroke", {Color = Theme.Red, Thickness = 1,
        Transparency = transparency or 0.82, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, object)
end
local function animate(object, properties)
    TweenService:Create(object, TweenInfo.new(0.15, Enum.EasingStyle.Quad), properties):Play()
end
local function feedback(button, outline)
    button.AutoButtonColor = false
    button.MouseEnter:Connect(function() animate(outline, {Transparency = 0.45}) end)
    button.MouseLeave:Connect(function() animate(outline, {Transparency = 0.82}) end)
end

local gui = create("ScreenGui", {
    Name = HUB_NAME,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

-- O quadro raiz acompanha a area util da tela, respeitando a barra do Roblox.
local root = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, gui)

local frame = create("Frame", {
    Size = UDim2.fromOffset(600, 600),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = Theme.Main,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
}, root)
round(frame, 12)
create("UIStroke", {Color = Theme.Red, Thickness = 1, Transparency = 0.25}, frame)
local scale = create("UIScale", {Scale = 1}, frame)

local title = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundColor3 = Theme.Second,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    Text = "  🍮 PUDIMHUB",
    Font = Enum.Font.GothamBlack,
    TextSize = 19,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Active = true,
}, frame)
round(title, 12)
create("TextLabel", {
    Position = UDim2.new(1, -252, 0, 20),
    Size = UDim2.fromOffset(190, 24),
    BackgroundTransparency = 1,
    Text = "ÍMÃ JOGADOR + BUILD v15 AUTO+  /  BUILD A BOAT",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = Theme.Muted,
    TextXAlignment = Enum.TextXAlignment.Right,
}, frame)

local accent = create("Frame", {Position = UDim2.fromOffset(18, 62),
    Size = UDim2.new(1, -36, 0, 1), BackgroundColor3 = Theme.Red, BorderSizePixel = 0}, frame)
create("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.85)})}, accent)
local minimize = create("TextButton", {Position = UDim2.new(1, -44, 0, 17),
    Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Theme.Button,
    BorderSizePixel = 0, Text = "−", TextColor3 = Theme.Text, TextSize = 20,
    Font = Enum.Font.GothamMedium}, frame)
round(minimize, 8)
feedback(minimize, edge(minimize))
minimize.Activated:Connect(function() frame.Visible = false end)

local sidebar = create("Frame", {
    Position = UDim2.fromOffset(12, 76),
    Size = UDim2.new(0, 132, 1, -120),
    BackgroundTransparency = 1,
}, frame)
create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)
local container = create("Frame", {
    Position = UDim2.fromOffset(154, 122),
    Size = UDim2.new(1, -166, 1, -166),
    BackgroundColor3 = Theme.Second,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, frame)
round(container, 8)
local search = create("TextBox", {Position = UDim2.fromOffset(154, 76),
    Size = UDim2.new(1, -166, 0, 34), BackgroundColor3 = Theme.Button,
    BorderSizePixel = 0, Text = "", PlaceholderText = "Buscar nesta aba…",
    PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.Text, TextSize = 12,
    Font = Enum.Font.Gotham, ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left}, frame)
round(search, 8); edge(search)
create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, search)

local tabs = {}
local currentTab
local categoryFilters = {}
local emptySearch = create("TextLabel", {Size = UDim2.new(1, -16, 0, 56),
    Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1,
    Text = "Nenhum controle encontrado nesta aba.", TextColor3 = Theme.Muted,
    TextSize = 12, Font = Enum.Font.GothamMedium, TextWrapped = true,
    Visible = false, ZIndex = 5}, container)
local function filterPage()
    if not currentTab then return end
    local query = string.lower(search.Text)
    if categoryFilters[currentTab.page] then
        emptySearch.Visible = not categoryFilters[currentTab.page](query)
        return
    end
    local found = false
    for _, item in ipairs(currentTab.page:GetChildren()) do
        if item:IsA("GuiObject") then
            local text = item:GetAttribute("SearchText") or ""
            if item:IsA("TextLabel") or item:IsA("TextButton") then text = text .. " " .. item.Text end
            for _, child in ipairs(item:GetDescendants()) do
                if child:IsA("TextLabel") then text = text .. " " .. child.Text end
            end
            item.Visible = query == "" or string.find(string.lower(text), query, 1, true) ~= nil
            found = found or item.Visible
        end
    end
    emptySearch.Visible = query ~= "" and not found
    currentTab.page.CanvasPosition = Vector2.zero
end
search:GetPropertyChangedSignal("Text"):Connect(filterPage)
local function selectTab(selected)
    currentTab = selected
    search.Text = ""
    search.PlaceholderText = "Buscar em " .. selected.page.Name .. "…"
    for _, tab in ipairs(tabs) do
        local active = tab == selected
        tab.page.Visible = active
        animate(tab.button, {BackgroundColor3 = active and Theme.DarkRed or Theme.Second,
            TextColor3 = active and Theme.Text or Theme.Muted})
        tab.indicator.Visible = active
    end
    filterPage()
end

local function createTab(name)
    local button = create("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(1, -6, 0, 38),
        LayoutOrder = #tabs + 1,
        BackgroundColor3 = Theme.Second,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextColor3 = Theme.Muted,
        TextSize = 12,
    }, sidebar)
    round(button, 8)
    feedback(button, edge(button))
    local indicator = create("Frame", {Size = UDim2.fromOffset(3, 18),
        Position = UDim2.new(0, 0, 0.5, -9), BackgroundColor3 = Theme.Red,
        BorderSizePixel = 0, Visible = false}, button)
    round(indicator, 2)
    local page = create("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Red,
        Visible = false,
    }, container)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8),
    }, page)
    create("UIListLayout", {
        Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    local tab = {button = button, page = page, indicator = indicator}
    table.insert(tabs, tab)
    button.Activated:Connect(function() selectTab(tab) end)
    return page
end

local tabHome = createTab("Início")
local tabPlayer = createTab("Player")
local tabAutoFarm = createTab("Auto Farm")
local tabStats = createTab("Estatísticas")
local tabMagnet = createTab("Ímã")
local tabMagnetPlayer = createTab("Ímã jogador")
local tabBuild = createTab("Build")
local tabVisual = createTab("Visual")
local tabSettings = createTab("Ajustes")
selectTab(tabs[1])
-- Adicione os futuros controles em tabPlayer ou tabAutoFarm.

local connections = {}
local function connect(signal, callback)
    table.insert(connections, signal:Connect(callback))
end
local function placeInside(x, y)
    local area = root.AbsoluteSize
    local half = 300 * scale.Scale
    frame.Position = UDim2.fromOffset(
        math.clamp(x, half, math.max(half, area.X - half)),
        math.clamp(y, half, math.max(half, area.Y - half))
    )
end
local function fitHUD()
    local area = root.AbsoluteSize
    if area.X <= 0 or area.Y <= 0 then return end
    scale.Scale = math.max(0.01, math.min(1, (area.X - 24) / 600, (area.Y - 24) / 600))
    placeInside(area.X / 2, area.Y / 2)
end
connect(root:GetPropertyChangedSignal("AbsoluteSize"), fitHUD)
fitHUD()

local dragging, dragTouch, dragStart, startPosition
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
        dragStart = input.Position
        startPosition = frame.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if dragging and (input == dragTouch or
        (not dragTouch and input.UserInputType == Enum.UserInputType.MouseMovement)) then
        local delta = input.Position - dragStart
        placeInside(startPosition.X.Offset + delta.X, startPosition.Y.Offset + delta.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input == dragTouch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragTouch = false, nil
    end
end)
connect(UserInputService.WindowFocusReleased, function()
    dragging, dragTouch = false, nil
end)

-- Inicio: perfil, vida, ouro e informacoes locais da sessao.
local order = 0
local function homeItem(className, properties)
    order = order + 1
    properties.LayoutOrder = order
    return create(className, properties, tabHome)
end
local function section(text)
    return homeItem("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
        Text = text, TextColor3 = Theme.Red, TextSize = 12,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    })
end
local function card(text, height)
    local label = homeItem("TextLabel", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Color3.fromRGB(26, 10, 15), BorderSizePixel = 0,
        Text = text, TextColor3 = Theme.Text, TextSize = 13,
        Font = Enum.Font.GothamMedium, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    round(label, 10)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
    }, label)
    return label
end

section("SEU PERSONAGEM")
local profileCard = homeItem("Frame", {
    Name = "PlayerProfile", Size = UDim2.new(1, 0, 0, 84),
    BackgroundColor3 = Color3.fromRGB(26, 10, 15), BorderSizePixel = 0,
})
round(profileCard, 10)
local avatar = create("ImageLabel", {
    Size = UDim2.fromOffset(56, 56), Position = UDim2.new(0, 12, 0.5, -28),
    BackgroundColor3 = Theme.Second, BorderSizePixel = 0,
    Image = "", ScaleType = Enum.ScaleType.Crop,
}, profileCard)
round(avatar, 28)
create("UIStroke", {Color = Theme.Red, Transparency = 0.35}, avatar)
local profile = create("TextLabel", {
    Position = UDim2.fromOffset(80, 8), Size = UDim2.new(1, -94, 1, -16),
    BackgroundTransparency = 1, Text = player.DisplayName,
    TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
}, profileCard)
task.spawn(function()
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId,
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)
    if ok and avatar.Parent then avatar.Image = content end
end)

local health = card("Vida: aguardando personagem", 62)
local track = create("Frame", {
    Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 4),
    BackgroundColor3 = Theme.Second, BorderSizePixel = 0,
}, health)
round(track, 2)
local healthFill = create("Frame", {
    Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Red, BorderSizePixel = 0,
}, track)
round(healthFill, 2)
local resources = card("Ouro: indisponível", 52)
section("BUILD A BOAT FOR TREASURE")
card("Construa seu barco e navegue em busca do tesouro!\nPlayer: movimento. Auto Farm: percurso até o baú.", 82)
section("ATALHOS")
card("G · Abrir / recolher menu\nArraste o cabeçalho para mover a janela.", 62)
local center = homeItem("TextButton", {
    Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Theme.DarkRed,
    BorderSizePixel = 0, Text = "Centralizar janela", TextColor3 = Theme.Text,
    Font = Enum.Font.GothamMedium, TextSize = 13,
})
round(center, 8)
center.Activated:Connect(fitHUD)

local footer = create("TextLabel", {
    Position = UDim2.new(0, 18, 1, -32), Size = UDim2.new(1, -36, 0, 22),
    BackgroundTransparency = 1, Text = "PUDIMHUB / BUILD A BOAT",
    TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium,
    TextSize = 11, TextColor3 = Theme.Muted,
}, frame)
connect(UserInputService.InputBegan, function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.G then
        frame.Visible = not frame.Visible
        dragging, dragTouch = false, nil
    end
end)

-- Leitura somente: usa Gold replicado, quando disponivel, sem alterar recursos.
local function goldText()
    local function read(parent)
        local value = parent and parent:FindFirstChild("Gold")
        if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then
            return tostring(value.Value)
        end
        return nil
    end
    return read(player:FindFirstChild("leaderstats"))
        or read(player:FindFirstChild("Data")) or read(player) or "indisponível"
end
local sessionStart = os.clock()
local elapsed, frames = 0, 0
local function refresh(fps)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local team = player.Team and player.Team.Name or "Sem time"
    profile.Text = player.DisplayName .. "  (@" .. player.Name .. ")\nTime: " .. team
    local ratio = humanoid and math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1) or 0
    health.Text = humanoid and ("Vida  " .. math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth))
        or "Aguardando personagem…"
    healthFill.Size = UDim2.fromScale(ratio, 1)
    healthFill.BackgroundColor3 = ratio < 0.3 and Theme.Red or Color3.fromRGB(86, 205, 159)
    resources.Text = "Ouro: " .. goldText()
    local seconds = math.floor(os.clock() - sessionStart)
    footer.Text = string.format("%s FPS  /  %d jogadores  /  %02d:%02d no HUD  /  G: menu",
        tostring(fps), #Players:GetPlayers(), math.floor(seconds / 60), seconds % 60)
end
refresh("—")
connect(RunService.RenderStepped, function(dt)
    elapsed = elapsed + dt
    frames = frames + 1
    if elapsed < 1 then return end
    refresh(math.floor(frames / elapsed + 0.5))
    elapsed, frames = 0, 0
end)
-- Controles compartilhados das abas.
-- Persistencia opcional do ambiente. LocalScripts comuns nao possuem readfile/writefile.
local preferences = {controls = {}, loading = true, closed = false, revision = 0}
local settingsFile = "PudimHub_BuildABoat_" .. tostring(player.UserId) .. "_settings_v1.json"
local storageStatus
local hasStorage = type(readfile) == "function" and type(writefile) == "function"
local function storageMessage(message)
    if storageStatus and storageStatus.Parent then storageStatus.Text = message end
end
local function saveSettings()
    if preferences.loading or preferences.closed then return end
    if not hasStorage then
        storageMessage("Salvamento indisponível: este ambiente não oferece readfile/writefile.")
        return
    end
    local values = {}
    for key, entry in pairs(preferences.controls) do values[key] = entry.get() end
    local ok, message = pcall(function()
        local encoded = HttpService:JSONEncode({version = 1, userId = player.UserId, values = values})
        writefile(settingsFile, encoded)
    end)
    storageMessage(ok and "Preferências salvas automaticamente por conta."
        or ("Falha ao salvar: " .. tostring(message):sub(1, 140)))
end
local function preferencesChanged()
    if preferences.loading or preferences.closed then return end
    preferences.revision = preferences.revision + 1
    local revision = preferences.revision
    task.delay(0.7, function()
        if not preferences.closed and preferences.revision == revision then saveSettings() end
    end)
end
local controlOrder = {}
local function control(page, className, text, height)
    controlOrder[page] = (controlOrder[page] or 0) + 1
    local object = create(className, {
        Size = UDim2.new(1, 0, 0, height or ((page == tabBuild or page == tabMagnet or page == tabMagnetPlayer) and 38 or 44)), LayoutOrder = controlOrder[page],
        BackgroundColor3 = Theme.Button, BorderSizePixel = 0,
        Text = text, TextColor3 = Theme.Text, TextSize = 13,
        TextWrapped = true, Font = Enum.Font.GothamMedium,
    }, page)
    round(object, 8)
    local outline = edge(object)
    object:SetAttribute("SearchText", text)
    if object:IsA("TextButton") then feedback(object, outline) end
    if className == "TextLabel" then
        object.TextXAlignment = Enum.TextXAlignment.Left
        create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, object)
        if (height or 44) <= 28 then
            object.TextColor3 = Color3.fromRGB(237, 116, 127)
            object.Font = Enum.Font.GothamBold
            object.TextSize = 12
            outline.Enabled = false
        end
    end
    return object
end
local function toggle(page, name, callback)
    local enabled = false
    local button = control(page, "TextButton", "", (page == tabBuild or page == tabMagnet or page == tabMagnetPlayer) and 40 or 46)
    button:SetAttribute("SearchText", name)
    create("TextLabel", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -78, 1, 0),
        BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium,
        TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, button)
    local track = create("Frame", {Size = UDim2.fromOffset(40, 22),
        Position = UDim2.new(1, -52, 0.5, -11), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(55, 18, 25)}, button)
    round(track, 11)
    local dot = create("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3),
        BorderSizePixel = 0, BackgroundColor3 = Theme.Text}, track)
    round(dot, 8)
    local function set(value)
        if enabled == value then return end
        enabled = value
        animate(track, {BackgroundColor3 = value and Theme.Red or Color3.fromRGB(55, 18, 25)})
        animate(dot, {Position = UDim2.fromOffset(value and 21 or 3, 3)})
        callback(value)
        preferencesChanged()
    end
    preferences.controls[page.Name .. "/" .. name] = {
        kind = "boolean", get = function() return enabled end, set = set,
    }
    button.Activated:Connect(function() set(not enabled) end)
    return set
end
local function numberField(page, name, initial, minimum, maximum, callback)
    local compact = page == tabBuild or page == tabMagnet or page == tabMagnetPlayer
    controlOrder[page] = (controlOrder[page] or 0) + 1
    local row = create("Frame", {Size = UDim2.new(1, 0, 0, compact and 68 or 82), LayoutOrder = controlOrder[page],
        BackgroundColor3 = Theme.Second, BorderSizePixel = 0}, page)
    row:SetAttribute("SearchText", name)
    round(row, 8); edge(row)
    create("TextLabel", {Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -94, 0, 28),
        BackgroundTransparency = 1, Text = name, TextWrapped = true,
        TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left}, row)
    local box = create("TextBox", {Size = UDim2.fromOffset(62, 26), Position = UDim2.new(1, -74, 0, 9),
        Text = tostring(initial), BackgroundColor3 = Theme.Button, TextColor3 = Theme.Text,
        TextSize = 12, Font = Enum.Font.GothamBold, BorderSizePixel = 0}, row)
    round(box, 6)
    box.ClearTextOnFocus = false
    local current = initial
    local hit = create("TextButton", {Size = UDim2.new(1, -24, 0, compact and 30 or 36),
        Position = UDim2.fromOffset(12, compact and 32 or 38), Text = "", BorderSizePixel = 0}, row)
    hit.BackgroundTransparency = 1
    hit.AutoButtonColor = false
    local bar = create("Frame", {Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 0.5, -3), BackgroundColor3 = Theme.DarkRed,
        BorderSizePixel = 0}, hit)
    round(bar, 3)
    local fill = create("Frame", {Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Theme.Red, BorderSizePixel = 0}, bar)
    round(fill, 3)
    local knob = create("Frame", {Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0}, bar)
    round(knob, 8)
    local function show(value, notify)
        current = math.clamp(value, minimum, maximum)
        local ratio = (current - minimum) / (maximum - minimum)
        fill.Size = UDim2.fromScale(ratio, 1)
        knob.Position = UDim2.fromScale(ratio, 0.5)
        box.Text = string.format("%.2f", current):gsub("%.?0+$", "")
        if notify then callback(current) end
        preferencesChanged()
    end
    local sliding, touch
    local previousScrolling
    local function release()
        if sliding then page.ScrollingEnabled = previousScrolling end
        sliding, touch = false, nil
    end
    local function move(x)
        if bar.AbsoluteSize.X <= 0 then return end
        local ratio = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = minimum + ratio * (maximum - minimum)
        local step = maximum <= 30 and 0.1 or 1
        show(math.floor(value / step + 0.5) * step, true)
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if sliding then return end
            previousScrolling = page.ScrollingEnabled
            page.ScrollingEnabled = false
            sliding = true
            touch = input.UserInputType == Enum.UserInputType.Touch and input or nil
            move(input.Position.X)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if sliding and (input == touch or (not touch and input.UserInputType == Enum.UserInputType.MouseMovement)) then move(input.Position.X) end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input == touch or input.UserInputType == Enum.UserInputType.MouseButton1 then release() end
    end)
    connect(UserInputService.WindowFocusReleased, release)
    connect(frame:GetPropertyChangedSignal("Visible"), release)
    connect(page:GetPropertyChangedSignal("Visible"), release)
    connect(row:GetPropertyChangedSignal("Visible"), release)
    box.FocusLost:Connect(function()
        local value = tonumber((box.Text:gsub(",", ".")))
        if value and value == value and math.abs(value) < math.huge then
            show(value, true)
        end
        box.Text = string.format("%.2f", current):gsub("%.?0+$", "")
    end)
    show(initial, false)
    preferences.controls[page.Name .. "/" .. name] = {
        kind = "number", get = function() return current end,
        set = function(value) show(value, true) end,
    }
    return function(value) show(value, false) end
end

-- Listas abertas no proprio painel, sem cobrir os outros controles.
local function dropdown(page, button, provider, choose, selected)
    controlOrder[page] = (controlOrder[page] or 0) + 1
    local popup = create("Frame", {Size = UDim2.new(1, 0, 0, 190),
        LayoutOrder = controlOrder[page], BackgroundColor3 = Theme.Second,
        BorderSizePixel = 0, Visible = false}, page)
    round(popup, 8); edge(popup)
    popup:SetAttribute("SearchText", button:GetAttribute("SearchText") or button.Text)
    popup:SetAttribute("Dropdown", true)
    popup:SetAttribute("Expanded", false)
    local filter = create("TextBox", {Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 0, 30), Text = "", PlaceholderText = "Buscar opção…",
        ClearTextOnFocus = false, TextSize = 12, Font = Enum.Font.Gotham,
        TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted,
        BackgroundColor3 = Theme.Button, BorderSizePixel = 0}, popup)
    round(filter, 6)
    local list = create("ScrollingFrame", {Position = UDim2.fromOffset(8, 44),
        Size = UDim2.new(1, -16, 1, -52), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Red}, popup)
    create("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
    local rows = {}
    local empty = create("TextLabel", {Size = UDim2.new(1, -6, 0, 34), Text = "Nenhuma opção disponível",
        TextColor3 = Theme.Muted, TextSize = 12, Font = Enum.Font.Gotham,
        BackgroundTransparency = 1, Visible = false}, list)
    local function filterOptions()
        local count, query = 0, string.lower(filter.Text)
        for _, row in ipairs(rows) do
            row.Visible = query == "" or string.find(string.lower(row.Text), query, 1, true) ~= nil
            if row.Visible then count = count + 1 end
        end
        empty.Visible = count == 0
        popup.Size = UDim2.new(1, 0, 0, 52 + math.min(math.max(count, 1), 4) * 36)
        list.CanvasPosition = Vector2.zero
    end
    filter:GetPropertyChangedSignal("Text"):Connect(filterOptions)
    button.Activated:Connect(function()
        local expanded = not popup:GetAttribute("Expanded")
        for _, child in ipairs(page:GetChildren()) do
            if child:GetAttribute("Dropdown") then child:SetAttribute("Expanded", false); child.Visible = false end
        end
        popup:SetAttribute("Expanded", expanded)
        if expanded then
            for _, row in ipairs(rows) do row:Destroy() end
            table.clear(rows)
            filter.Text = ""
            local options = provider()
            local value = selected()
            for index, option in ipairs(options) do
                local row = create("TextButton", {Size = UDim2.new(1, -6, 0, 32), LayoutOrder = index,
                    Text = (option.value == value and "✓  " or "") .. option.label,
                    BackgroundColor3 = option.value == value and Theme.DarkRed or Theme.Button,
                    TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamMedium,
                    BorderSizePixel = 0, AutoButtonColor = false, TextWrapped = true}, list)
                round(row, 6)
                table.insert(rows, row)
                row.Activated:Connect(function()
                    choose(option.value)
                    popup:SetAttribute("Expanded", false)
                    popup.Visible = false
                    filterPage()
                end)
            end
            filterOptions()
        end
        popup.Visible = expanded
        filterPage()
    end)
end
local function indexedOptions(names)
    local options = {}
    for index, name in ipairs(names) do table.insert(options, {value = index, label = name}) end
    return options
end
local function categories(page, definitions)
    local rows, assigned = {}, {}
    for _, row in ipairs(page:GetChildren()) do if row:IsA("GuiObject") then table.insert(rows, row) end end
    table.sort(rows, function(a,b) return a.LayoutOrder < b.LayoutOrder end)
    local groups = {}
    for _, definition in ipairs(definitions) do
        local group = {name = definition[1], expanded = definition[3] == true, rows = {}}
        for _, row in ipairs(rows) do
            if table.find(definition[2], row:GetAttribute("SearchText")) then
                table.insert(group.rows, row); assigned[row] = true
            end
        end
        table.insert(groups, group)
    end
    local order, pinned = 0, {}
    for _, row in ipairs(rows) do
        if not assigned[row] then order = order + 1; row.LayoutOrder = order; table.insert(pinned, row) end
    end
    local function matches(row, query)
        local text = row:GetAttribute("SearchText") or ""
        if row:IsA("TextLabel") or row:IsA("TextButton") then text = text .. " " .. row.Text end
        return query == "" or string.find(string.lower(text), query, 1, true) ~= nil
    end
    local function render(query)
        local found = false
        for _, row in ipairs(pinned) do row.Visible = matches(row, query); found = found or row.Visible end
        for _, group in ipairs(groups) do
            local groupMatch = query ~= "" and string.find(string.lower(group.name), query, 1, true) ~= nil
            local any = query == ""
            for _, row in ipairs(group.rows) do
                local matched = groupMatch or matches(row, query)
                any = any or matched
                row.Visible = matched and (group.expanded or query ~= "")
                    and (not row:GetAttribute("Dropdown") or row:GetAttribute("Expanded") == true)
            end
            group.header.Text = (group.expanded and "▾  " or "▸  ") .. group.name
            group.header.Visible = any
            found = found or any
        end
        return found
    end
    for _, group in ipairs(groups) do
        group.header = control(page, "TextButton", group.name, 32)
        group.header.BackgroundColor3 = Theme.DarkRed
        order = order + 1; group.header.LayoutOrder = order
        for _, row in ipairs(group.rows) do order = order + 1; row.LayoutOrder = order end
        group.header.Activated:Connect(function()
            group.expanded = not group.expanded
            render(string.lower(search.Text))
        end)
    end
    local layout = page:FindFirstChildOfClass("UIListLayout")
    if layout then layout.Padding = UDim.new(0, 6) end
    categoryFilters[page] = render
    render("")
end

local alive = true
local movement = {speed = nil, jump = nil, noclip = false, water = false}
local originals = setmetatable({}, {__mode = "k"})
local collisions = {}
local function characterParts()
    local character = player.Character
    return character, character and character:FindFirstChildOfClass("Humanoid"),
        character and character:FindFirstChild("HumanoidRootPart")
end
local function applyMovement()
    local _, humanoid = characterParts()
    if not humanoid then return end
    if not originals[humanoid] then
        originals[humanoid] = {speed = humanoid.WalkSpeed, power = humanoid.JumpPower,
            height = humanoid.JumpHeight}
    end
    if movement.speed then humanoid.WalkSpeed = movement.speed end
    if movement.jump then
        if humanoid.UseJumpPower then humanoid.JumpPower = movement.jump
        else humanoid.JumpHeight = movement.jump ^ 2 / (2 * math.max(workspace.Gravity, 1)) end
    end
end
local function restoreMovement()
    movement.speed, movement.jump = nil, nil
    for humanoid, saved in pairs(originals) do
        if humanoid.Parent then
            humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight = saved.speed, saved.power, saved.height
        end
    end
end
local function restoreCollisions()
    for part, value in pairs(collisions) do
        if part.Parent then part.CanCollide = value end
        collisions[part] = nil
    end
end
control(tabPlayer, "TextLabel", "MOVIMENTO", 28).BackgroundTransparency = 1
local _, initialHumanoid = characterParts()
local initialSpeed = initialHumanoid and initialHumanoid.WalkSpeed or 16
local initialJump = initialHumanoid and (initialHumanoid.UseJumpPower and initialHumanoid.JumpPower
    or math.sqrt(2 * workspace.Gravity * initialHumanoid.JumpHeight)) or 50
local showSpeed = numberField(tabPlayer, "Velocidade normal (WalkSpeed)", initialSpeed, 0, 150, function(value)
    movement.speed = value; applyMovement()
end)
local showJump = numberField(tabPlayer, "Força do pulo", math.floor(initialJump), 0, 200, function(value)
    movement.jump = value; applyMovement()
end)
local stopFlight, setFly, setInfiniteJump
do
    local enabled, infiniteJump, speed = false, false, 60
    local attachment, velocity, activeHumanoid, savedPlatform, savedRotate
    local focused = true
    stopFlight = function()
        movement.flyActive = false
        if velocity then velocity:Destroy(); velocity = nil end
        if attachment then attachment:Destroy(); attachment = nil end
        if activeHumanoid and activeHumanoid.Parent then
            activeHumanoid.PlatformStand = savedPlatform
            activeHumanoid.AutoRotate = savedRotate
        end
        activeHumanoid = nil
    end
    setFly = toggle(tabPlayer, "Fly", function(value)
        enabled = value
        if not value then stopFlight() end
    end)
    numberField(tabPlayer, "Velocidade do Fly", 60, 5, 300, function(value) speed = value end)
    control(tabPlayer, "TextLabel", "Fly: WASD para mover • Espaço sobe • Ctrl desce", 38)
    setInfiniteJump = toggle(tabPlayer, "Pulo infinito", function(value) infiniteJump = value end)
    local lastJump = 0
    connect(UserInputService.JumpRequest, function()
        if not infiniteJump or enabled or movement.farming or UserInputService:GetFocusedTextBox() then return end
        local _, humanoid = characterParts()
        if humanoid and humanoid.Health > 0 and not humanoid.SeatPart and os.clock() - lastJump >= 0.12 then
            lastJump = os.clock()
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    connect(UserInputService.WindowFocusReleased, function() focused = false; stopFlight() end)
    connect(UserInputService.WindowFocused, function() focused = true end)
    connect(player.CharacterRemoving, stopFlight)
    connect(RunService.PreSimulation, function()
        local _, humanoid, rootPart = characterParts()
        if not enabled or not focused or movement.farming or not rootPart or not humanoid
            or humanoid.Health <= 0 or humanoid.SeatPart or rootPart.Anchored then stopFlight(); return end
        if activeHumanoid ~= humanoid or not attachment or attachment.Parent ~= rootPart
            or not velocity or velocity.Parent ~= rootPart then
            stopFlight()
            activeHumanoid = humanoid
            savedPlatform, savedRotate = humanoid.PlatformStand, humanoid.AutoRotate
            attachment = create("Attachment", {Name = "PudimHub_FlyAttachment"}, rootPart)
            velocity = create("LinearVelocity", {Name = "PudimHub_FlyVelocity", Attachment0 = attachment,
                RelativeTo = Enum.ActuatorRelativeTo.World, VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
                ForceLimitsEnabled = false, VectorVelocity = Vector3.zero}, rootPart)
        end
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
        movement.flyActive = true
        local direction = Vector3.zero
        local camera = workspace.CurrentCamera
        if camera and not UserInputService:GetFocusedTextBox() then
            local function key(code) return UserInputService:IsKeyDown(code) and 1 or 0 end
            direction = camera.CFrame.LookVector * (key(Enum.KeyCode.W) - key(Enum.KeyCode.S))
                + camera.CFrame.RightVector * (key(Enum.KeyCode.D) - key(Enum.KeyCode.A))
                + Vector3.yAxis * (key(Enum.KeyCode.Space) - math.max(key(Enum.KeyCode.LeftControl), key(Enum.KeyCode.RightControl)))
        end
        velocity.VectorVelocity = direction.Magnitude > 0 and direction.Unit * speed or Vector3.zero
    end)
end
local setWater
local setNoclip = toggle(tabPlayer, "Noclip", function(value)
    movement.noclip = value
    if not value then restoreCollisions() end
end)
local waterFloor
local function removeFloor()
    if waterFloor then waterFloor:Destroy(); waterFloor = nil end
end
setWater = toggle(tabPlayer, "Water Walk", function(value)
    movement.water = value
    if not value then removeFloor() end
end)
local waterClearance = 3
numberField(tabPlayer, "Water Walk: distância da água", 3, 2, 8, function(value)
    waterClearance = value
end)
local function waterSurface(hit)
    if not hit then return false end
    if hit.Material == Enum.Material.Water then return true end
    -- Alguns mapas representam a agua com Parts em vez de Terrain.
    local item = hit.Instance
    for _ = 1, 3 do
        if not item or item == workspace then break end
        local name = string.lower(item.Name)
        if name == "water" or name == "waterpart" or name == "river"
            or name == "waterparts" then return true end
        item = item.Parent
    end
    return false
end
control(tabPlayer, "TextButton", "Restaurar movimento original").Activated:Connect(function()
    restoreMovement(); setNoclip(false); setWater(false); setFly(false); setInfiniteJump(false)
    local _, humanoid = characterParts()
    if humanoid then
        showSpeed(humanoid.WalkSpeed)
        showJump(math.floor(humanoid.UseJumpPower and humanoid.JumpPower
            or math.sqrt(2 * workspace.Gravity * humanoid.JumpHeight)))
    end
end)
connect(RunService.Stepped, function()
    local character, humanoid, rootPart = characterParts()
    if movement.noclip and character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if collisions[part] == nil then collisions[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end
    if not movement.water or movement.farming or movement.flyActive or not rootPart
        or not humanoid or humanoid.Health <= 0 or humanoid.SeatPart then
        removeFloor(); return
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = waterFloor and {character, waterFloor} or {character}
    params.IgnoreWater = false
    -- Comeca acima dos pes para detectar a superficie mesmo apos uma queda curta.
    local origin = rootPart.Position + Vector3.new(0, 16, 0)
    local hit = workspace:Raycast(origin, Vector3.new(0, -64, 0), params)
    if waterSurface(hit) then
        local velocity = rootPart.AssemblyLinearVelocity
        local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        local width = math.clamp(20 + horizontalSpeed * 0.3, 20, 64)
        local surfaceY = hit.Position.Y + waterClearance
        if not waterFloor then
            waterFloor = create("Part", {Name = "PudimHub_WaterFloor", Anchored = true,
                Size = Vector3.new(width, 1, width), Transparency = 1, CanCollide = true,
                CanTouch = false, CanQuery = false}, workspace)
        end
        waterFloor.Size = Vector3.new(width, 1, width)
        -- Com Noclip, a correcao vertical abaixo sustenta o personagem sem colisao.
        waterFloor.CanCollide = not movement.noclip
        waterFloor.Position = Vector3.new(rootPart.Position.X, surfaceY - 0.5, rootPart.Position.Z)
        local feetOffset = humanoid.HipHeight + rootPart.Size.Y / 2
        if humanoid.RigType == Enum.HumanoidRigType.R6 then feetOffset = feetOffset + 2 end
        local safeRootY = surfaceY + feetOffset + 0.1
        if rootPart.Position.Y < safeRootY then
            -- Correcao apenas vertical: nao altera o WalkSpeed nem o movimento horizontal.
            rootPart.CFrame = rootPart.CFrame + Vector3.new(0, safeRootY - rootPart.Position.Y, 0)
            rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(0, velocity.Y), velocity.Z)
            if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    else removeFloor() end
end)
connect(player.CharacterAdded, function(character)
    restoreCollisions(); removeFloor()
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if alive and humanoid and player.Character == character then applyMovement() end
    end)
end)

-- Estrutura de mapa conhecida: BoatStages/NormalStages/CaveStageN e TheEnd/GoldenChest/Trigger.
-- Referencia de estrutura: github.com/Stefanuk12/ROBLOX (Build A Boat For Treasure/Autofarm.lua).
local farm = {enabled = false, token = 0, stageDelay = 2, respawnDelay = 5,
    trips = 0, speed = 250, seconds = 0, gold = 0, lastGold = nil, goldObserved = false}
local farmPlatforms = {}
local function clearFarmPlatforms()
    for part in pairs(farmPlatforms) do part:Destroy(); farmPlatforms[part] = nil end
end
local setFarm
control(tabAutoFarm, "TextLabel", "PERCURSO ATÉ O TESOURO", 28).BackgroundTransparency = 1
local status = control(tabAutoFarm, "TextLabel", "Parado", 68)
local function farmStatus(text)
    if alive then status.Text = text .. "\nPercursos até o baú: " .. farm.trips end
end
local function valid(token)
    return alive and farm.enabled and farm.token == token
end
local function pause(seconds, token)
    local deadline = os.clock() + seconds
    repeat
        if not valid(token) then return false end
        task.wait(0.05)
    until os.clock() >= deadline
    return valid(token)
end
local function travel(rootPart, target, token, sameCharacter)
    local start = rootPart.CFrame
    local distance = (start.Position - target.Position).Magnitude
    local covered = 0
    while covered < distance do
        local dt = RunService.Heartbeat:Wait()
        if not valid(token) or not sameCharacter() then return false end
        covered = math.min(distance, covered + farm.speed * math.min(dt, 0.1))
        rootPart.CFrame = start:Lerp(target, covered / distance)
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end
    return valid(token) and sameCharacter()
end
local function route()
    local stages = workspace:FindFirstChild("BoatStages")
    stages = stages and stages:FindFirstChild("NormalStages")
    if not stages then return nil, nil, "Mapa não encontrado: BoatStages/NormalStages." end
    local points = {}
    for _, stage in ipairs(stages:GetChildren()) do
        local index = tonumber(stage.Name:match("^CaveStage(%d+)$"))
        if index then
            local marker = stage:FindFirstChild("DarknessPart", true)
            if not marker or not marker:IsA("BasePart") then
                return nil, nil, "Etapa sem marcador: " .. stage.Name
            end
            table.insert(points, {index = index, marker = marker})
        end
    end
    table.sort(points, function(a, b) return a.index < b.index end)
    local ending = stages:FindFirstChild("TheEnd")
    local chest = ending and ending:FindFirstChild("GoldenChest")
    local trigger = chest and chest:FindFirstChild("Trigger")
    if #points == 0 or not trigger or not trigger:IsA("BasePart") then
        return nil, nil, "Etapas ou gatilho do baú indisponíveis. Aguarde o mapa carregar."
    end
    return points, trigger
end
local function runFarm(token)
    while valid(token) do
        farmStatus("Aguardando personagem vivo…")
        local character, humanoid, rootPart
        local deadline = os.clock() + 60
        repeat
            if not pause(0.1, token) then return end
            character, humanoid, rootPart = characterParts()
        until (humanoid and humanoid.Health > 0 and rootPart) or os.clock() > deadline
        if not humanoid or humanoid.Health <= 0 or not rootPart then error("Personagem indisponível por 60 segundos.", 0) end
        local points, trigger, reason = route()
        local mapDeadline = os.clock() + 30
        while not points and valid(token) and os.clock() < mapDeadline do
            farmStatus("Aguardando o mapa carregar…")
            if not pause(0.5, token) then return end
            points, trigger, reason = route()
        end
        if not points then error(reason, 0) end
        local function sameCharacter()
            return player.Character == character and rootPart.Parent and humanoid.Health > 0
        end
        local interrupted = false
        for _, point in ipairs(points) do
            if not valid(token) then return end
            if not sameCharacter() then interrupted = true; break end
            if not point.marker.Parent then error("O mapa mudou. Reinicie o farm.", 0) end
            farmStatus("Passando pela etapa " .. point.index .. "…")
            if not travel(rootPart, point.marker.CFrame, token, sameCharacter) then interrupted = true; break end
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            local footOffset = humanoid.HipHeight + rootPart.Size.Y / 2
            if humanoid.RigType == Enum.HumanoidRigType.R6 then footOffset = footOffset + 2 end
            local support = create("Part", {
                Name = "PudimHub_FarmSupport", Anchored = true, Transparency = 1,
                Size = Vector3.new(12, 0.5, 12), CanCollide = true, CanTouch = false,
                Position = rootPart.Position - Vector3.new(0, footOffset + 0.25, 0),
            }, workspace)
            farmPlatforms[support] = true
            local continuing = pause(farm.stageDelay, token)
            support:Destroy(); farmPlatforms[support] = nil
            if not continuing then return end
        end
        if not interrupted and sameCharacter() then
            farmStatus("Chegando ao baú…")
            if not trigger.Parent then error("O baú não está mais disponível.", 0) end
            if not travel(rootPart, trigger.CFrame, token, sameCharacter) then
                if not valid(token) then return end
                interrupted = true
            end
            if not interrupted then
            rootPart.AssemblyLinearVelocity = Vector3.zero
            farm.trips = farm.trips + 1
            farmStatus("Aguardando recompensa e renascimento…")
            deadline = os.clock() + 60
            while valid(token) and sameCharacter() and os.clock() < deadline do
                if not pause(0.2, token) then return end
            end
            if valid(token) and sameCharacter() then
                error("Sem renascimento após 60 s. A coleta do baú não foi confirmada.", 0)
            end
            end
        end
        if not pause(farm.respawnDelay, token) then return end
    end
end
setFarm = toggle(tabAutoFarm, "Auto Farm", function(enabled)
    farm.token = farm.token + 1
    farm.enabled = enabled
    movement.farming = enabled
    if enabled then removeFloor() end
    if not enabled then clearFarmPlatforms(); farmStatus("Parado"); return end
    farm.lastGold = tonumber(goldText())
    local token = farm.token
    task.spawn(function()
        local ok, message = pcall(runFarm, token)
        if not ok and valid(token) then
            setFarm(false)
            farmStatus("Farm interrompido: " .. tostring(message))
        end
    end)
end)
numberField(tabAutoFarm, "Velocidade do percurso (studs/s)", 250, 50, 600, function(value) farm.speed = value end)
numberField(tabAutoFarm, "Segundos em cada etapa", 2, 0.5, 10, function(value) farm.stageDelay = value end)
numberField(tabAutoFarm, "Pausa entre percursos (segundos)", 5, 1, 30, function(value) farm.respawnDelay = value end)

local stats = control(tabStats, "TextLabel", "Preparando estatísticas…", 164)
local compactStats = control(tabAutoFarm, "TextLabel", "", 88)
local function renderStats()
    local total = math.floor(farm.seconds)
    local clockText = string.format("%02d:%02d:%02d", math.floor(total / 3600), math.floor(total / 60) % 60, total % 60)
    local money = farm.goldObserved and tostring(farm.gold) or "indisponível"
    compactStats.Text = string.format("Chegadas ao final: %d\nOuro ganho: %s  |  Tempo: %s", farm.trips, money, clockText)
    stats.Text = compactStats.Text .. "\nSaldo atual: " .. goldText()
        .. "\nEstado: " .. (farm.enabled and "Farm ligado" or "Farm parado")
end
local statsElapsed = 0
connect(RunService.Heartbeat, function(dt)
    if farm.enabled then
        farm.seconds = farm.seconds + dt
        local balance = tonumber(goldText())
        if balance then
            farm.goldObserved = true
            if farm.lastGold then farm.gold = farm.gold + math.max(0, balance - farm.lastGold) end
        end
        farm.lastGold = balance
    end
    statsElapsed = statsElapsed + dt
    if statsElapsed >= 0.5 then statsElapsed = 0; renderStats() end
end)
control(tabStats, "TextButton", "Zerar contadores da sessão").Activated:Connect(function()
    farm.trips, farm.seconds, farm.gold = 0, 0, 0
    farm.lastGold = tonumber(goldText())
    farm.goldObserved = farm.lastGold ~= nil
    renderStats()
end)
renderStats()

local Lighting = game:GetService("Lighting")
local savedLighting
local setLight = toggle(tabVisual, "Iluminação clara", function(enabled)
    if enabled then
        savedLighting = {Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows}
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        Lighting.GlobalShadows = false
    elseif savedLighting then
        for property, value in pairs(savedLighting) do Lighting[property] = value end
        savedLighting = nil
    end
end)
local cameras = setmetatable({}, {__mode = "k"})
local selectedFov
local function applyFov()
    local camera = workspace.CurrentCamera
    if camera and selectedFov then
        if not cameras[camera] then cameras[camera] = camera.FieldOfView end
        camera.FieldOfView = selectedFov
    end
end
local showFov = numberField(tabVisual, "Campo de visão (FOV)", workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70, 40, 110, function(value)
    selectedFov = value; applyFov()
end)
connect(workspace:GetPropertyChangedSignal("CurrentCamera"), applyFov)
local function restoreVisual()
    setLight(false)
    selectedFov = nil
    for camera, value in pairs(cameras) do
        if camera.Parent then camera.FieldOfView = value end
        cameras[camera] = nil
    end
    if workspace.CurrentCamera then showFov(workspace.CurrentCamera.FieldOfView) end
end
control(tabVisual, "TextButton", "Restaurar visual original").Activated:Connect(restoreVisual)
control(tabSettings, "TextButton", "Centralizar janela").Activated:Connect(fitHUD)
local antiAfkEnabled = false
local antiAfkStatus = control(tabSettings, "TextLabel", "Anti-AFK: desligado", 52)
local setAntiAfk = toggle(tabSettings, "Anti-AFK", function(enabled)
    antiAfkEnabled = enabled
    antiAfkStatus.Text = enabled and "Anti-AFK: aguardando inatividade" or "Anti-AFK: desligado"
end)
connect(player.Idled, function()
    if not antiAfkEnabled then return end
    local ok = pcall(function()
        local virtualUser = game:GetService("VirtualUser")
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new(0, 0))
    end)
    antiAfkStatus.Text = ok and "Anti-AFK: entrada enviada após inatividade"
        or "Anti-AFK indisponível: este ambiente bloqueou a entrada virtual."
end)
setAntiAfk(true)
numberField(tabSettings, "Transparência do HUD (%)", 5, 0, 80, function(value) frame.BackgroundTransparency = value / 100 end)
control(tabSettings, "TextButton", "Parar farm e restaurar personagem").Activated:Connect(function()
    setFarm(false); restoreMovement(); setNoclip(false); setWater(false)
    local _, humanoid = characterParts()
    if humanoid then
        showSpeed(humanoid.WalkSpeed)
        showJump(humanoid.UseJumpPower and humanoid.JumpPower or math.sqrt(2 * workspace.Gravity * humanoid.JumpHeight))
    end
end)
control(tabSettings, "TextButton", "Fechar e remover HUD").Activated:Connect(function() gui:Destroy() end)

storageStatus = control(tabSettings, "TextLabel", "Carregando preferências…", 76)
control(tabSettings, "TextButton", "Salvar preferências agora").Activated:Connect(saveSettings)

local releaseMagnet
do
    local magnet = {enabled = false, holding = false, toggleMode = false, autoCapture = false, radius = 20, reach = 150,
        response = 100, speed = 80, limit = 1000, unlimited = true, depth = 35, mode = 1, formation = 12,
        angle = 0, orbitHeight = 5, orbitRate = 70, tornadoHeight = 40, ghost = false,
        capture = 0, capturing = false, autoLimit = 200, spacing = 6, sphereRadius = 15, playerRadius = 12, items = {}}
    local autoFolderIndex, autoModelIndex = 1, 1
    local autoModels = {}
    local autoIgnored = setmetatable({}, {__mode = "k"})
    local modeNames = {"Normal", "Centralizar no cursor", "Círculo", "Órbita",
        "Órbita no jogador", "Círculo no jogador", "Tornado", "Tornado no cursor", "Linha reta", "Parede", "Esfera",
        "Caixa no jogador", "Esfera no jogador"}
    local function followsPlayer(mode) return (mode >= 5 and mode <= 7) or mode == 12 or mode == 13 end
    local mouse = player:GetMouse()
    local tornadoCenter
    local groupCenter
    local wallRight
    local layoutCount = 0
    local recoveryLoad = 0
    local splitScan = 0
    local lastCursorTarget
    local aimParams = RaycastParams.new()
    aimParams.FilterType = Enum.RaycastFilterType.Exclude
    local aimFilterDirty = true
    local function rebuildAimFilter()
        local excluded = {}
        for _, other in ipairs(Players:GetPlayers()) do
            if other.Character then table.insert(excluded, other.Character) end
        end
        for _, item in ipairs(magnet.items) do
            for part in pairs(item.collisions) do
                if part.Parent then table.insert(excluded, part) end
            end
        end
        aimParams.FilterDescendantsInstances = excluded
        aimFilterDirty = false
    end
    control(tabMagnet, "TextLabel", "ÍMÃ DE BLOCOS", 28).BackgroundTransparency = 1
    local magnetStatus = control(tabMagnet, "TextLabel", "Desligado", 52)
    control(tabMagnetPlayer, "TextLabel", "ÍMÃ AO REDOR DO JOGADOR", 28).BackgroundTransparency = 1
    local playerStatus = control(tabMagnetPlayer, "TextLabel", "Desligado", 64)
    connect(magnetStatus:GetPropertyChangedSignal("Text"), function() playerStatus.Text = magnetStatus.Text end)
    local function updateCollisions(item, ghost)
        for part, saved in pairs(item.collisions) do
            if part.Parent then
                -- As pecas originais sao restauradas, inclusive as que ja nao colidiam.
                local collide = not ghost and saved.collide or false
                local touch = not ghost and saved.touch or false
                if part.CanCollide ~= collide then part.CanCollide = collide end
                if part.CanTouch ~= touch then part.CanTouch = touch end
            end
        end
    end
    local function removeActuators(item)
        if item.align then item.align:Destroy() end
        if item.lift then item.lift:Destroy() end
        if item.attachment then item.attachment:Destroy() end
    end
    local function discard(item, preserveCollisions)
        removeActuators(item)
        if item.highlight then item.highlight:Destroy() end
        if not preserveCollisions then updateCollisions(item, false) end
    end
    releaseMagnet = function()
        magnet.holding = false
        magnet.capture = magnet.capture + 1
        magnet.capturing = false
        for _, item in ipairs(magnet.items) do discard(item) end
        table.clear(magnet.items)
        tornadoCenter = nil
        groupCenter = nil
        wallRight = nil
        layoutCount = 0
        recoveryLoad = 0
        lastCursorTarget = nil
        aimFilterDirty = true
        magnetStatus.Text = not magnet.enabled and "Desligado" or magnet.autoCapture and "Coleta automática: aguardando blocos ao redor do jogador" or (magnet.toggleMode
            and "Clique para capturar • clique novamente para soltar"
            or followsPlayer(magnet.mode)
            and "Clique nos blocos para prender o grupo ao jogador"
            or "Segure o clique sobre os blocos soltos")
    end
    local setEnabled = toggle(tabMagnet, "Ativar ímã", function(value)
        magnet.enabled = value
        releaseMagnet()
    end)
    local setAutomatic = toggle(tabMagnet, "Coleta automática ao redor do jogador", function(value)
        magnet.autoCapture = value
        if value then table.clear(autoIgnored) end
        releaseMagnet()
    end)
    numberField(tabMagnet, "Limite da coleta automática", 200, 1, 1000, function(value)
        magnet.autoLimit = math.floor(value)
    end)
    toggle(tabMagnet, "Modo toggle (clique para prender/soltar)", function(value)
        magnet.toggleMode = value
        releaseMagnet()
    end)
    local modeButton = control(tabMagnet, "TextButton", "Modo: Normal  ▾")
    modeButton:SetAttribute("SearchText", "Modo do ímã")
    local playerMode = 5
    local playerModeButton = control(tabMagnetPlayer, "TextButton", "Modo: Órbita no jogador  ▾")
    playerModeButton:SetAttribute("SearchText", "Modo ao redor do jogador")
    local function setMode(value)
        if value == 14 then value = 2 end -- Compatibilidade com o antigo modo automatico.
        magnet.mode = math.clamp(math.floor(value), 1, #modeNames)

        for _, item in ipairs(magnet.items) do updateCollisions(item, magnet.ghost or magnet.mode == 11 or magnet.mode == 13) end
        magnet.angle = 0
        tornadoCenter = nil
        modeButton.Text = "Modo: " .. modeNames[magnet.mode] .. "  ▾"
        wallRight = nil
        if followsPlayer(magnet.mode) then
            playerMode = magnet.mode
            playerModeButton.Text = "Modo: " .. modeNames[playerMode] .. "  ▾"
        end
        if not magnet.capturing and not magnet.autoCapture and (not magnet.holding or (not magnet.toggleMode and not followsPlayer(magnet.mode)
            and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1))) then releaseMagnet() end
        preferencesChanged()
    end
    dropdown(tabMagnet, modeButton, function()
        local options = {}
        for index, name in ipairs(modeNames) do
            if not followsPlayer(index) then table.insert(options, {value = index, label = name}) end
        end
        return options
    end,
        setMode, function() return magnet.mode end)
    dropdown(tabMagnetPlayer, playerModeButton, function()
        local options = {}
        for _, index in ipairs({5, 6, 7, 12, 13}) do
            table.insert(options, {value = index, label = modeNames[index]})
        end
        return options
    end, setMode, function() return playerMode end)
    control(tabMagnetPlayer, "TextButton", "Ativar no jogador").Activated:Connect(function()
        setMode(playerMode)
        if not magnet.enabled then setEnabled(true) end
    end)
    control(tabMagnetPlayer, "TextButton", "Soltar todos os blocos").Activated:Connect(function()
        if magnet.autoCapture then setAutomatic(false) else releaseMagnet() end
    end)
    control(tabMagnetPlayer, "TextButton", "Desligar ímã").Activated:Connect(function() setEnabled(false) end)
    preferences.controls["Ímã/Modo"] = {kind = "number", get = function() return magnet.mode end, set = setMode}
    numberField(tabMagnet, "Raio de captura (studs)", 20, 5, 1000, function(value) magnet.radius = value end)
    numberField(tabMagnet, "Alcance máximo (studs)", 150, 20, 2000, function(value) magnet.reach = value end)
    numberField(tabMagnet, "Resposta do movimento (%)", 100, 5, 500, function(value) magnet.response = value end)
    numberField(tabMagnet, "Velocidade dos blocos (studs/s)", 80, 5, 1000, function(value) magnet.speed = value end)
    numberField(tabMagnetPlayer, "Raio do círculo / órbita", 12, 5, 500, function(value) magnet.formation = value end)
    preferences.controls["Ímã/Raio do círculo / órbita"] = preferences.controls["Ímã jogador/Raio do círculo / órbita"]
    preferences.controls["Ímã jogador/Raio do círculo / órbita"] = nil
    local setUnlimited = toggle(tabMagnet, "Sem limite de distância do jogador", function(value) magnet.unlimited = value end)
    setUnlimited(true)
    local showDepth = numberField(tabMagnet, "Distância do cursor (studs)", 35, 5, 2500, function(value) magnet.depth = value end)
    numberField(tabMagnetPlayer, "Altura da formação no jogador", 5, 0, 100, function(value) magnet.orbitHeight = value end)
    preferences.controls["Ímã/Altura da formação no jogador"] = preferences.controls["Ímã jogador/Altura da formação no jogador"]
    preferences.controls["Ímã jogador/Altura da formação no jogador"] = nil
    numberField(tabMagnetPlayer, "Tamanho da caixa / esfera", 12, 5, 100, function(value) magnet.playerRadius = value end)
    numberField(tabMagnetPlayer, "Altura do tornado", 40, 5, 500, function(value) magnet.tornadoHeight = value end)
    preferences.controls["Ímã/Altura do tornado"] = preferences.controls["Ímã jogador/Altura do tornado"]
    preferences.controls["Ímã jogador/Altura do tornado"] = nil
    numberField(tabMagnet, "Espaçamento da linha / parede", 6, 2, 100, function(value) magnet.spacing = value end)
    numberField(tabMagnet, "Raio da esfera", 15, 3, 500, function(value) magnet.sphereRadius = value end)
    numberField(tabMagnetPlayer, "Velocidade da órbita (graus/s)", 70, 0, 14400, function(value) magnet.orbitRate = value end)
    preferences.controls["Ímã/Velocidade da órbita (graus/s)"] = preferences.controls["Ímã jogador/Velocidade da órbita (graus/s)"]
    preferences.controls["Ímã jogador/Velocidade da órbita (graus/s)"] = nil
    numberField(tabMagnet, "Limite de conjuntos de blocos", 1000, 1, 3000, function(value) magnet.limit = math.floor(value) end)
    local setGhost = toggle(tabMagnet, "Atravessar obstáculos", function(value)
        magnet.ghost = value
        for _, item in ipairs(magnet.items) do updateCollisions(item, value or magnet.mode == 11 or magnet.mode == 13) end
    end)
    setGhost(true)
    control(tabMagnet, "TextButton", "Soltar todos os blocos").Activated:Connect(function()
        if magnet.autoCapture then setAutomatic(false) else releaseMagnet() end
    end)
    control(tabMagnet, "TextButton", "Resetar opções do ímã").Activated:Connect(function()
        releaseMagnet()
        setEnabled(false)
        magnet.angle = 0
        local defaults = { ["Modo"] = 1, ["Raio de captura (studs)"] = 20,
            ["Modo toggle (clique para prender/soltar)"] = false, ["Coleta automática ao redor do jogador"] = false, ["Limite da coleta automática"] = 200,
            ["Alcance máximo (studs)"] = 150, ["Resposta do movimento (%)"] = 100,
            ["Velocidade dos blocos (studs/s)"] = 80,
            ["Distância do cursor (studs)"] = 35,
            ["Altura da formação no jogador"] = 5, ["Velocidade da órbita (graus/s)"] = 70,
            ["Altura do tornado"] = 40,
            ["Espaçamento da linha / parede"] = 6,
            ["Raio da esfera"] = 15,
            ["Atravessar obstáculos"] = true,
            ["Raio do círculo / órbita"] = 12, ["Limite de conjuntos de blocos"] = 1000, ["Sem limite de distância do jogador"] = true }
        for name, value in pairs(defaults) do preferences.controls["Ímã/" .. name].set(value) end
        preferences.controls["Ímã jogador/Tamanho da caixa / esfera"].set(12)
        magnetStatus.Text = "Ímã desligado • opções restauradas"
        saveSettings()
    end)

    local function formationOffset(mode, index, count, radius, angle, original, tornadoHeight)
        if mode == 1 then return original end
        if mode == 2 then return Vector3.new(0, 0, 0) end
        if mode == 12 or mode == 13 then
            local y = 1 - 2 * (index - 0.5) / math.max(1, count)
            local ring = math.sqrt(math.max(0, 1 - y * y))
            local theta = (index - 1) * math.pi * (3 - math.sqrt(5))
            local point = Vector3.new(math.cos(theta) * ring, y, math.sin(theta) * ring)
            if mode == 12 then
                point = point / math.max(math.abs(point.X), math.abs(point.Y), math.abs(point.Z), 0.001)
            end
            return point * (mode == 13 and (magnet.effectivePlayerRadius or magnet.playerRadius) or magnet.playerRadius)
        end
        if mode == 11 then
            if count <= 1 then return Vector3.zero end
            -- Espiral de Fibonacci distribui os blocos pela superficie sem acumular nos polos.
            local y = 1 - 2 * (index - 0.5) / count
            local ring = math.sqrt(math.max(0, 1 - y * y))
            local theta = (index - 1) * math.pi * (3 - math.sqrt(5))
            return Vector3.new(math.cos(theta) * ring, y, math.sin(theta) * ring) * (magnet.effectiveSphereRadius or magnet.sphereRadius)
        end
        if mode == 9 then
            return Vector3.new((index - 1 - (count - 1) / 2) * magnet.spacing, 0, 0)
        end
        if mode == 10 then
            local columns = math.max(1, math.ceil(math.sqrt(count)))
            local row = math.floor((index - 1) / columns)
            return Vector3.new(((index - 1) % columns - (columns - 1) / 2) * magnet.spacing,
                row * magnet.spacing, 0)
        end
        if mode == 7 or mode == 8 then
            local level = count > 1 and (index - 1) / (count - 1) or 0
            local ringRadius = radius * (0.2 + 0.8 * level)
            -- Distribuicao angular uniforme, base estreita e topo largo.
            local theta = angle + (index - 1) * math.pi * (3 - math.sqrt(5))
            return Vector3.new(math.cos(theta) * ringRadius, level * (tornadoHeight or 40),
                math.sin(theta) * ringRadius)
        end
        local theta = 2 * math.pi * (index - 1) / math.max(1, count) + ((mode == 4 or mode == 5) and angle or 0)
        return Vector3.new(math.cos(theta) * radius, 0, math.sin(theta) * radius)
    end
    local function forceFor(part)
        -- Forca ajustada a massa; dispensa um slider de unidades fisicas.
        return math.clamp(part.AssemblyMass * (workspace.Gravity + 1000), 30000, 50000000)
    end
    local function orbitAngularRate(rate, radius, dt, pace)
        -- Limita o salto angular por quadro para evitar inverter visualmente o giro.
        return math.min(math.rad(rate), 6000 / math.max(1, radius),
            math.rad(120) / math.max(dt, 0.001)) * pace
    end
    local function permitted(part, allowAnchored)
        if not part:IsA("BasePart") or (part.Anchored and not allowAnchored) then return false end
        local item = part
        while item and item ~= workspace do
            if item:IsA("Tool") or item:IsA("Accessory")
                or (item:IsA("Model") and item:FindFirstChildOfClass("Humanoid")) then return false end
            if string.sub(item.Name, 1, 9) == "PudimHub_" then return false end
            item = item.Parent
        end
        if (part:IsA("Seat") or part:IsA("VehicleSeat")) and part.Occupant then return false end
        return true
    end
    local function ensureActuators(item)
        if not item.attachment or item.attachment.Parent ~= item.part
            or not item.align or item.align.Parent ~= item.part
            or not item.lift or item.lift.Parent ~= item.part then
            removeActuators(item)
            item.attachment = create("Attachment", {Name = "PudimHub_MagnetAttachment",
                Position = item.part.CFrame:PointToObjectSpace(item.part.AssemblyCenterOfMass)}, item.part)
            item.align = create("AlignPosition", {Name = "PudimHub_MagnetForce",
                Mode = Enum.PositionAlignmentMode.OneAttachment, Attachment0 = item.attachment,
                ApplyAtCenterOfMass = true, RigidityEnabled = false,
                ForceLimitMode = Enum.ForceLimitMode.Magnitude, MaxForce = forceFor(item.part),
                MaxVelocity = magnet.speed, Responsiveness = math.clamp(magnet.response * 0.65, 5, 200),
                Position = item.command}, item.part)
            item.lift = create("VectorForce", {Name = "PudimHub_MagnetSupport",
                Attachment0 = item.attachment, RelativeTo = Enum.ActuatorRelativeTo.World,
                ApplyAtCenterOfMass = true, Force = Vector3.zero}, item.part)
        end
        item.align.Enabled = true
        item.lift.Enabled = true
        item.align.Attachment0 = item.attachment
        item.lift.Attachment0 = item.attachment
        item.lift.Force = Vector3.new(0, item.part.AssemblyMass * workspace.Gravity, 0)
    end
    local function beginCapture(automatic)
        if not automatic then releaseMagnet() end
        local initialCount = #magnet.items
        local captureLimit = automatic and math.min(magnet.limit, magnet.autoLimit, initialCount + 20) or magnet.limit
        local capture = magnet.capture
        local character, humanoid, rootPart = characterParts()
        if not rootPart or not humanoid or humanoid.Health <= 0 or farm.enabled then
            magnetStatus.Text = "Aguarde o personagem e desligue o farm para usar o ímã"
            return
        end
        magnet.capturing = true
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}
        local ray = mouse.UnitRay
        local hit = automatic and {Position = rootPart.Position}
            or workspace:Raycast(ray.Origin, ray.Direction * (magnet.unlimited and 15000 or (magnet.reach + 500)), params)
        if not hit or (not magnet.unlimited and (hit.Position - rootPart.Position).Magnitude > magnet.reach) then
            magnet.capturing = false
            magnetStatus.Text = "Aponte para uma área dentro do alcance"
            return
        end
        local overlap = OverlapParams.new()
        overlap.FilterType = Enum.RaycastFilterType.Exclude
        local excluded = {}
        for _, other in ipairs(Players:GetPlayers()) do
            if other.Character then table.insert(excluded, other.Character) end
        end
        if automatic then
            for member in pairs(autoIgnored) do
                if member.Parent then table.insert(excluded, member) end
            end
            for _, selected in ipairs(magnet.items) do
                for member in pairs(selected.collisions) do table.insert(excluded, member) end
            end
        end
        overlap.FilterDescendantsInstances = excluded
        overlap.MaxParts = automatic and 128 or math.min(10000, math.max(1000, magnet.limit * 20))
        local parts = workspace:GetPartBoundsInRadius(hit.Position, magnet.radius, overlap)
        -- Inclui PPart de blocos do jogo que a consulta espacial pode omitir (CanQuery=false).
        local candidates = {}
        for _, part in ipairs(parts) do candidates[part] = true end
        local blocks = workspace:FindFirstChild("Blocks")
        local scanned = 0
        if blocks and automatic then
            local folders = blocks:GetChildren()
            local inspected, advances = 0, 0
            while #folders > 0 and inspected < 128 and advances <= #folders do
                if autoFolderIndex > #folders then autoFolderIndex = 1 end
                if autoModelIndex == 1 then autoModels = folders[autoFolderIndex]:GetChildren() end
                local model = autoModels[autoModelIndex]
                if not model then
                    autoFolderIndex = autoFolderIndex + 1
                    autoModelIndex = 1
                    autoModels = {}
                    advances = advances + 1
                else
                    autoModelIndex = autoModelIndex + 1
                    inspected = inspected + 1
                    local part = model:IsA("BasePart") and model or model:FindFirstChild("PPart")
                    if part and part:IsA("BasePart") and part:IsDescendantOf(workspace) and not candidates[part]
                        and (part.Position - hit.Position).Magnitude <= magnet.radius + part.Size.Magnitude / 2 then
                        candidates[part] = true
                        table.insert(parts, part)
                    end
                end
            end
        elseif blocks then
            for _, folder in ipairs(blocks:GetChildren()) do
                for _, model in ipairs(folder:GetChildren()) do
                    scanned = scanned + 1
                    if scanned % 100 == 0 then
                        task.wait()
                        if not alive or capture ~= magnet.capture then return end
                    end
                    local part = model:IsA("BasePart") and model or model:FindFirstChild("PPart")
                    if part and part:IsA("BasePart") and not candidates[part]
                        and (part.Position - hit.Position).Magnitude <= magnet.radius + part.Size.Magnitude / 2 then
                        candidates[part] = true
                        table.insert(parts, part)
                    end
                end
            end
        end
        table.sort(parts, function(a, b)
            return (a.Position - hit.Position).Magnitude < (b.Position - hit.Position).Magnitude
        end)
        local seen = {}
        if automatic then
            for _, selected in ipairs(magnet.items) do
                seen[selected.part] = true
                seen[selected.part.AssemblyRootPart or selected.part] = true
                for member in pairs(selected.collisions) do seen[member] = true end
            end
        end
        magnet.capturing = true
        for partIndex, part in ipairs(parts) do
            if partIndex % 25 == 0 then task.wait() end
            if not alive or capture ~= magnet.capture or not magnet.enabled then return end
            if farm.enabled then releaseMagnet(); return end
            if #magnet.items >= captureLimit then break end
            local assembly = part.AssemblyRootPart or part
            if not seen[assembly] and not seen[part]
                and (not automatic or (not autoIgnored[assembly] and not autoIgnored[part])) then
                seen[assembly] = true
                local accepted = assembly:IsDescendantOf(workspace) and permitted(assembly) and permitted(part)
                    and (magnet.unlimited or (assembly.Position - rootPart.Position).Magnitude <= magnet.reach)
                local joined = {}
                if accepted then
                    joined = assembly:GetConnectedParts(true)
                    if #joined > (automatic and 100 or 1000) then accepted = false end
                    if accepted then
                        for _, connected in ipairs(joined) do
                            if not permitted(connected) or (automatic and autoIgnored[connected]) then accepted = false; break end
                        end
                    end
                end
                if accepted then
                    local collisions = {}
                    for _, connected in ipairs(joined) do
                        seen[connected] = true
                        collisions[connected] = {collide = connected.CanCollide, touch = connected.CanTouch}
                    end
                    collisions[assembly] = {collide = assembly.CanCollide, touch = assembly.CanTouch}
                    local massCenter = assembly.AssemblyCenterOfMass
                    local highlight = #magnet.items < 24 and create("Highlight", {Name = "PudimHub_MagnetHighlight",
                        Adornee = assembly, FillColor = Theme.Red, FillTransparency = 0.85,
                        OutlineColor = Theme.Red, OutlineTransparency = 0.15,
                        DepthMode = Enum.HighlightDepthMode.Occluded}, assembly)
                    local item = {part = assembly, collisions = collisions,
                        highlight = highlight, offset = massCenter - hit.Position,
                        command = massCenter, stalled = 0, lastPosition = massCenter}
                    local envelope = 0
                    for member in pairs(collisions) do
                        envelope = math.max(envelope, (member.Position - massCenter).Magnitude * 2 + member.Size.Magnitude)
                    end
                    item.spacingDiameter = envelope
                    table.insert(magnet.items, item)
                    ensureActuators(item)
                    updateCollisions(item, magnet.ghost or magnet.mode == 11 or magnet.mode == 13)
                end
            end
        end
        magnet.capturing = false
        if not automatic then
            magnet.depth = math.clamp((hit.Position - ray.Origin).Magnitude, 5, 2500)
            lastCursorTarget = hit.Position
            showDepth(magnet.depth)
            magnet.angle = 0
        end
        aimFilterDirty = true
        for index, item in ipairs(magnet.items) do
            item.slot, item.slotCount = index, #magnet.items
        end
        magnet.holding = #magnet.items > 0
        magnetStatus.Text = magnet.holding and (modeNames[magnet.mode] .. " • selecionados: " .. #magnet.items)
            or (automatic and "Coleta automática: aguardando blocos ao redor do jogador" or "Nenhum bloco solto encontrado nesta área")
    end
    task.spawn(function()
        while alive do
            task.wait(0.5)
            if alive and magnet.enabled and magnet.autoCapture and not magnet.capturing
                and not farm.enabled and #magnet.items < math.min(magnet.limit, magnet.autoLimit) then
                local ok, message = pcall(beginCapture, true)
                if not ok then
                    setEnabled(false)
                    magnetStatus.Text = "Coleta automática interrompida; veja o console"
                    warn("[PudimHub Ímã automático] " .. tostring(message))
                end
            end
        end
    end)
    local function releaseNearestPile(position)
        local camera = workspace.CurrentCamera
        if not camera then return end
        local seed, best = nil, math.huge
        for _, item in ipairs(magnet.items) do
            if item.part:IsDescendantOf(workspace) then
                local point, visible = camera:WorldToScreenPoint(item.part.AssemblyCenterOfMass)
                if visible and point.Z > 0 then
                    local distance = (Vector2.new(point.X, point.Y) - position).Magnitude
                    if distance < best then seed, best = item, distance end
                end
            end
        end
        if not seed then return end
        local center = seed.part.AssemblyCenterOfMass
        local radius = math.max(12, seed.part.Size.Magnitude)
        local released = 0
        for index = #magnet.items, 1, -1 do
            local item = magnet.items[index]
            if item == seed or (item.part:IsDescendantOf(workspace)
                and (item.part.AssemblyCenterOfMass - center).Magnitude <= radius) then
                autoIgnored[item.part] = true
                autoIgnored[item.part.AssemblyRootPart or item.part] = true
                for member in pairs(item.collisions) do autoIgnored[member] = true end
                discard(item)
                table.remove(magnet.items, index)
                released = released + 1
            end
        end
        for index, item in ipairs(magnet.items) do item.slot, item.slotCount = index, #magnet.items end
        layoutCount = #magnet.items
        magnet.holding = #magnet.items > 0
        aimFilterDirty = true
        magnetStatus.Text = "Pilha solta: " .. released .. " • coleta automática continua ligada"
    end
    connect(UserInputService.InputBegan, function(input, processed)
        if not magnet.enabled or processed or UserInputService:GetFocusedTextBox()
            or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local position = UserInputService:GetMouseLocation()
        for _, object in ipairs(playerGui:GetGuiObjectsAtPosition(position.X, position.Y)) do
            if object:IsDescendantOf(frame) and frame.Visible then return end
        end
        if magnet.autoCapture then releaseNearestPile(position); return end
        if magnet.toggleMode and (magnet.holding or magnet.capturing) then
            releaseMagnet()
            return
        end
        local ok, message = pcall(beginCapture)
        if not ok then
            releaseMagnet()
            magnetStatus.Text = "Falha ao capturar blocos; veja o console"
            warn("[PudimHub Ímã] " .. tostring(message))
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not magnet.autoCapture and not magnet.toggleMode and not followsPlayer(magnet.mode)
            and (magnet.holding or magnet.capturing) then releaseMagnet() end
    end)
    connect(UserInputService.WindowFocusReleased, function()
        if not magnet.autoCapture and not magnet.toggleMode and not followsPlayer(magnet.mode) then releaseMagnet() end
    end)
    connect(player.CharacterRemoving, releaseMagnet)
    connect(RunService.PreSimulation, function()
        if not magnet.enabled or (not magnet.ghost and magnet.mode ~= 11 and magnet.mode ~= 13) or not (magnet.holding or magnet.capturing) then return end
        for _, item in ipairs(magnet.items) do updateCollisions(item, true) end
    end)
    connect(RunService.Heartbeat, function(dt)
        if not magnet.holding then return end
        local _, humanoid, rootPart = characterParts()
        if not rootPart or not humanoid or humanoid.Health <= 0 or farm.enabled then releaseMagnet(); return end
        local ray = mouse.UnitRay
        local target
        if aimFilterDirty then rebuildAimFilter() end
        if aimFilterDirty then rebuildAimFilter() end
        local diameter = 1
        local clearance = 4
        for _, item in ipairs(magnet.items) do
            if item.part:IsDescendantOf(workspace) then
                diameter = math.max(diameter, item.spacingDiameter or item.part.Size.Magnitude)
                clearance = math.max(clearance, item.part.Size.Magnitude * 0.5 + 2
                    + (magnet.mode == 1 and math.max(0, -item.offset.Y) or 0))
            end
        end
        local minimumRadius = (diameter + 0.5) * math.sqrt(math.max(1, #magnet.items)) / 2.8
        magnet.effectiveSphereRadius = math.max(magnet.sphereRadius, minimumRadius)
        magnet.effectivePlayerRadius = math.max(magnet.playerRadius, minimumRadius)
        if followsPlayer(magnet.mode) then
            target = rootPart.Position + Vector3.new(0,
                (magnet.mode == 12 or magnet.mode == 13) and (magnet.orbitHeight - 5) or magnet.orbitHeight, 0)
        else
            if aimFilterDirty then rebuildAimFilter() end
            -- O alcance e medido a partir do personagem, nao a partir da camera.
            local cameraOffset = ray.Origin - rootPart.Position
            local projection = cameraOffset:Dot(ray.Direction)
            local discriminant = projection * projection - (cameraOffset:Dot(cameraOffset) - magnet.reach ^ 2)
            local rayLength = magnet.unlimited and 15000 or (discriminant >= 0 and (-projection + math.sqrt(discriminant)) or 0)
            if rayLength > 0 then
                local hit = workspace:Raycast(ray.Origin, ray.Direction * rayLength, aimParams)
                if hit then
                    -- Mantem espaco entre a formacao e a superficie apontada.
                    target = hit.Position + hit.Normal * clearance
                    magnet.depth = math.clamp(hit.Distance, 5, 2500)
                else
                    target = ray.Origin + ray.Direction * math.min(magnet.depth, rayLength)
                end
            else
                -- Conserva o centro, mas continua a animacao e a recuperacao do grupo.
                target = lastCursorTarget or (rootPart.Position + ray.Direction * math.min(magnet.depth, magnet.reach))
            end
            lastCursorTarget = target
        end
        local tornado = magnet.mode == 7 or magnet.mode == 8
        if magnet.mode == 11 then target = target + Vector3.new(0, magnet.effectiveSphereRadius, 0) end
        local pace = 1 - math.min(0.65, recoveryLoad * 0.65)
        if tornado then
            if magnet.mode == 8 then target = target + Vector3.new(0, clearance, 0) end
            tornadoCenter = tornadoCenter or target
            local delta = target - tornadoCenter
            -- Reserva velocidade para o giro e para os blocos atrasados recuperarem a formacao.
            local step = magnet.speed * 0.35 * pace * math.min(dt, 0.1)
            tornadoCenter = delta.Magnitude > step and (tornadoCenter + delta.Unit * step) or target
            target = tornadoCenter
            groupCenter = target
        else
            tornadoCenter = nil
            groupCenter = groupCenter or target
            local delta = target - groupCenter
            local step = magnet.speed * 0.55 * math.min(dt, 0.1)
            groupCenter = delta.Magnitude > step and (groupCenter + delta.Unit * step) or target
            target = groupCenter
        end
        local rotating = magnet.mode == 4 or magnet.mode == 5 or tornado
        -- O giro tem sua propria reserva de velocidade, independente do deslocamento do cursor.
        local angularRate = orbitAngularRate(magnet.orbitRate, magnet.formation, dt, pace)
        local rigidShape = magnet.mode == 10 or magnet.mode == 11 or magnet.mode == 12 or magnet.mode == 13
        if magnet.mode == 10 or magnet.mode == 11 then
            -- Eleva a forma inteira: corrigir cada bloco separadamente achatava a esfera e a parede.
            local bottom = target - Vector3.new(0, magnet.mode == 11 and magnet.effectiveSphereRadius or 0, 0)
            local hit = workspace:Raycast(bottom + Vector3.new(0, clearance + 8, 0),
                Vector3.new(0, -(clearance + 72), 0), aimParams)
            if hit and hit.Normal.Y > 0.5 then
                target = target + Vector3.new(0, math.max(0, hit.Position.Y + clearance - bottom.Y), 0)
            end
        end
        if magnet.mode == 10 and not wallRight then
            local camera = workspace.CurrentCamera
            local right = camera and camera.CFrame.RightVector or Vector3.xAxis
            right = Vector3.new(right.X, 0, right.Z)
            wallRight = right.Magnitude > 0.001 and right.Unit or Vector3.xAxis
        end
        if layoutCount ~= #magnet.items then
            layoutCount = #magnet.items
            for index, item in ipairs(magnet.items) do item.slot, item.slotCount = index, layoutCount end
        end
        magnet.angle = (magnet.angle + math.min(dt, 0.1) * angularRate) % (2 * math.pi)
        local unresponsive = 0
        local paused = 0
        local waiting = 0
        local recovering = 0
        local occupiedAssemblies = {}
        local floorBudget = 64
        -- Recupera partes da selecao que se separaram de um conjunto soldado.
        splitScan = splitScan + dt
        if splitScan >= 0.4 then
            splitScan = 0
            local tracked, additions = {}, {}
            for _, item in ipairs(magnet.items) do
                tracked[item.part.AssemblyRootPart or item.part] = true
            end
            for _, item in ipairs(magnet.items) do
                for part in pairs(item.collisions) do
                    if part:IsDescendantOf(workspace) then
                        local root = part.AssemblyRootPart or part
                        if not tracked[root] and permitted(root) and permitted(part)
                            and #magnet.items + #additions < magnet.limit then
                            tracked[root] = true
                            local savedParts = {}
                            for member, saved in pairs(item.collisions) do
                                if (member.AssemblyRootPart or member) == root then savedParts[member] = saved end
                            end
                            table.insert(additions, {part = root, collisions = savedParts,
                                offset = item.offset, command = root.AssemblyCenterOfMass,
                                lastPosition = root.AssemblyCenterOfMass, stalled = 0,
                                slot = item.slot, slotCount = item.slotCount, spacingDiameter = item.spacingDiameter})
                        end
                    end
                end
            end
            for _, item in ipairs(additions) do table.insert(magnet.items, item) end
            if #additions > 0 then
                aimFilterDirty = true
                for index, item in ipairs(magnet.items) do
                    item.slot, item.slotCount = index, #magnet.items
                end
            end
        end
        for index = #magnet.items, 1, -1 do
            local item = magnet.items[index]
            if not item.part:IsDescendantOf(workspace) then
                for part in pairs(item.collisions) do
                    if part:IsDescendantOf(workspace) and permitted(part, true) then
                        item.part = part
                        if item.highlight and item.highlight.Parent then item.highlight.Adornee = part end
                        break
                    end
                end
            end
            local assembly = item.part.AssemblyRootPart or item.part
            if not item.part:IsDescendantOf(workspace) then
                -- Streaming pode retirar o bloco temporariamente; conserva a selecao ate voltar.
                if item.align and item.align.Parent then item.align.Enabled = false end
                if item.lift and item.lift.Parent then item.lift.Enabled = false end
                waiting = waiting + 1
            elseif not permitted(item.part, true) or not permitted(assembly, true) then
                -- Uma cadeira ocupada pode ligar temporariamente o bloco ao personagem.
                -- Suspende a forca sem esquecer a selecao; retoma quando estiver livre.
                if item.align then item.align.Enabled = false end
                if item.lift then item.lift.Enabled = false end
                paused = paused + 1
            elseif occupiedAssemblies[assembly] then
                -- Conjuntos unidos durante o arraste usam apenas um motor.
                local keeper = occupiedAssemblies[assembly]
                for part, saved in pairs(item.collisions) do
                    if not keeper.collisions[part] then keeper.collisions[part] = saved end
                end
                discard(item, true); table.remove(magnet.items, index)
            elseif assembly.Anchored or item.part.Anchored then
                occupiedAssemblies[assembly] = item
                if item.align then item.align.Enabled = false end
                if item.lift then item.lift.Enabled = false end
                paused = paused + 1
            else
                occupiedAssemblies[assembly] = item
                if item.part ~= assembly then
                    removeActuators(item)
                    item.part = assembly
                    item.lastPosition = assembly.AssemblyCenterOfMass
                    item.stalled = 0
                end
                ensureActuators(item)
                local offset = formationOffset(magnet.mode, item.slot or index, item.slotCount or #magnet.items,
                    magnet.formation, magnet.angle, item.offset, magnet.tornadoHeight)
                if magnet.mode == 9 or magnet.mode == 10 then
                    local camera = workspace.CurrentCamera
                    local right = magnet.mode == 10 and wallRight or (camera and camera.CFrame.RightVector or Vector3.xAxis)
                    right = Vector3.new(right.X, 0, right.Z)
                    right = right.Magnitude > 0.001 and right.Unit or Vector3.xAxis
                    offset = right * offset.X + Vector3.yAxis * offset.Y
                end
                local destination = target + offset
                -- Verificacao escalonada evita centenas de raycasts no mesmo quadro.
                item.floorTimer = (item.floorTimer or ((index % 12) * 0.015)) - dt
                local moved = not item.floorProbe or (destination - item.floorProbe).Magnitude > 12
                if not rigidShape and (item.floorTimer <= 0 or moved) and floorBudget > 0 then
                    floorBudget = floorBudget - 1
                    item.floorTimer = 0.18
                    item.floorProbe = destination
                    local sizeClearance = item.part.Size.Magnitude * 0.5 + 2
                    local floorHit = workspace:Raycast(destination + Vector3.new(0, sizeClearance + 8, 0),
                        Vector3.new(0, -(sizeClearance + 72), 0), aimParams)
                    item.floorY = floorHit and floorHit.Normal.Y > 0.5
                        and (floorHit.Position.Y + sizeClearance) or nil
                end
                if item.floorY and not rigidShape then
                    destination = Vector3.new(destination.X, math.max(destination.Y, item.floorY), destination.Z)
                end
                item.command = destination
                item.attachment.Position = item.part.CFrame:PointToObjectSpace(item.part.AssemblyCenterOfMass)
                item.align.Position = item.command
                local current = item.part.AssemblyCenterOfMass
                local distance = (item.command - current).Magnitude
                local catchingUp = distance > math.max(8, magnet.speed * 0.15)
                    or current.Y < item.command.Y - 4
                local force = forceFor(item.part)
                local orbitSpeed = rotating and angularRate * magnet.formation or 0
                local motionSpeed = math.max(magnet.speed, orbitSpeed * 1.25 + magnet.speed * 0.55)
                if rotating then
                    force = math.min(100000000, force + item.part.AssemblyMass * angularRate * angularRate * magnet.formation * 1.5)
                end
                if catchingUp then
                    force = math.min(100000000, force + item.part.AssemblyMass * math.min(2000, distance * 30))
                    recovering = recovering + 1
                end
                item.align.MaxForce = force
                item.align.Responsiveness = math.clamp(math.max(magnet.response * 0.65,
                    rotating and 200 or (catchingUp and 160 or 5)), 5, 200)
                item.align.MaxVelocity = math.min(rotating and 9000 or 3500,
                    catchingUp and (motionSpeed + math.min(motionSpeed, distance * 2)) or motionSpeed)
                if (item.command - current).Magnitude > 8 and (current - item.lastPosition).Magnitude < 0.05 then
                    item.stalled = item.stalled + dt
                else item.stalled = 0 end
                if item.stalled > 2 then unresponsive = unresponsive + 1 end
                item.lastPosition = current
            end
        end
        recoveryLoad = recovering / math.max(1, #magnet.items)
        if #magnet.items == 0 then releaseMagnet()
        else
            magnetStatus.Text = modeNames[magnet.mode] .. " • selecionados: " .. #magnet.items
                .. ((magnet.mode == 11 or magnet.mode == 13) and string.format(" • raio: %.1f",
                    magnet.mode == 11 and magnet.effectiveSphereRadius or magnet.effectivePlayerRadius) or "")
                .. (recovering > 0 and (" • recuperando: " .. recovering) or "")
                .. (waiting > 0 and (" • aguardando retorno: " .. waiting) or "")
                .. (unresponsive > 0 and (" • sem acompanhar: " .. unresponsive) or "")
                .. (paused > 0 and (" • ancorados/ocupados: " .. paused) or "")
                .. (followsPlayer(magnet.mode) and " • use Soltar para liberar" or "")
        end
    end)
end

local stopBuild
do
    local build = {block = "WoodBlock", pattern = 1, location = 1, count = 20, height = 20, spacing = 6, rate = 5000, turbo = true,
        busy = false, token = 0, pending = false, created = {}}
    local models = {"Blocos no ar para ímã", "Grade", "Torre", "Parede", "Linha reta", "Círculo", "Esfera", "Pirâmide", "Escada"}
    local choices = {}
    local function isDynamiteName(name)
        local key = string.lower(name):gsub("[%s_%-]", ""):gsub("block$", "")
        return key == "dynamite" or key == "dinamite" or key == "bundlesofdynamite"
            or key == "bundleofdynamite" or key == "thingsofdynamite"
            or key == "dynamitebundle" or key == "dynamitebundles"
    end
    local function buildCategory(name)
        local lower = string.lower(name):gsub("block$", "")
        if lower == "balloon" or lower == "balloons" then return "Balões" end
        if lower == "tnt" then return "TNT" end
        if isDynamiteName(name) then return "Dinamite" end
        if lower:match("chair$") or lower:match("seat$") or lower:match("throne$") then return "Cadeiras" end
        if lower:match("scaffold$") or lower:match("scaffolding$") then return "Andaimes" end
        if name:match("Block$") then return "Blocos" end
        return nil
    end
    local function buildLabel(name)
        local lower = string.lower(name):gsub("block$", "")
        if lower == "balloon" or lower == "balloons" then return "Balão (" .. name .. ")" end
        if isDynamiteName(name) then return "Dinamite (" .. name .. ")" end
        if lower == "woodseat" or lower == "woodenseat" or lower == "woodchair" or lower == "woodenchair" then
            return "Cadeira de madeira (" .. name .. ")"
        end
        return name
    end
    control(tabBuild, "TextLabel", "CONSTRUÇÃO AUTOMÁTICA", 28).BackgroundTransparency = 1
    local buildStatus = control(tabBuild, "TextLabel", "Escolha o bloco e o modelo", 64)
    local blockButton = control(tabBuild, "TextButton", "Bloco: WoodBlock")
    blockButton:SetAttribute("SearchText", "Bloco")
    local function updateBlockButton()
        local data = player:FindFirstChild("Data")
        local entry = data and data:FindFirstChild(build.block)
        local amount = entry and (entry:IsA("IntValue") or entry:IsA("NumberValue")) and entry.Value or nil
        blockButton.Text = "Bloco: " .. buildLabel(build.block) .. (amount and ("  •  " .. tostring(amount)) or "") .. "  ▾"
    end
    local function inventory()
        table.clear(choices)
        local data = player:FindFirstChild("Data")
        if data then
            for _, entry in ipairs(data:GetChildren()) do
                if (entry:IsA("IntValue") or entry:IsA("NumberValue"))
                    and (entry.Value > 0 or isDynamiteName(entry.Name)) and buildCategory(entry.Name) then
                    table.insert(choices, entry.Name)
                end
            end
        end
        table.sort(choices, function(a, b)
            local ca, cb = buildCategory(a), buildCategory(b)
            if ca == cb then return a < b end
            return ca < cb
        end)
        updateBlockButton()
        return #choices
    end
    dropdown(tabBuild, blockButton, function()
        inventory()
        local options = {}
        local data = player:FindFirstChild("Data")
        for _, name in ipairs(choices) do
            local entry = data and data:FindFirstChild(name)
            table.insert(options, {value = name, label = buildCategory(name) .. " • " .. buildLabel(name) .. "  •  " .. tostring(entry and entry.Value or 0)})
        end
        return options
    end, function(value)
        build.block = value
        updateBlockButton(); preferencesChanged()
    end, function() return build.block end)
    control(tabBuild, "TextButton", "Atualizar lista de blocos").Activated:Connect(function()
        local count = inventory()
        local found = false
        for _, name in ipairs(choices) do if isDynamiteName(name) then found = true; break end end
        buildStatus.Text = "Tipos listados: " .. count .. (found and " • procure Dinamite na lista"
            or " • dinamite não identificada no inventário carregado")
    end)
    preferences.controls["Build/Bloco"] = {kind = "string", get = function() return build.block end,
        set = function(value)
            if #value <= 80 and not value:find("%c") and buildCategory(value) then
                build.block = value; updateBlockButton()
            end
        end}
    local patternButton = control(tabBuild, "TextButton", "Modelo: " .. models[1] .. "  ▾")
    patternButton:SetAttribute("SearchText", "Modelo")
    local function setPattern(value)
        build.pattern = math.clamp(math.floor(value), 1, #models)
        patternButton.Text = "Modelo: " .. models[build.pattern] .. "  ▾"
        preferencesChanged()
    end
    dropdown(tabBuild, patternButton, function() return indexedOptions(models) end,
        setPattern, function() return build.pattern end)
    preferences.controls["Build/Modelo"] = {kind = "number", get = function() return build.pattern end, set = setPattern}
    local locationNames = {"Ponto fixo da base", "Acima do personagem"}
    local locationButton = control(tabBuild, "TextButton", "Local: " .. locationNames[1] .. "  ▾")
    locationButton:SetAttribute("SearchText", "Local")
    local function setLocation(value)
        build.location = math.clamp(math.floor(value), 1, 2)
        locationButton.Text = "Local: " .. locationNames[build.location] .. "  ▾"
        preferencesChanged()
    end
    dropdown(tabBuild, locationButton, function() return indexedOptions(locationNames) end,
        setLocation, function() return build.location end)
    preferences.controls["Build/Local"] = {kind = "number", get = function() return build.location end, set = setLocation}
    numberField(tabBuild, "Quantidade de blocos", 20, 1, 10000, function(value) build.count = math.floor(value) end)
    numberField(tabBuild, "Altura sobre o terreno", 20, 5, 60, function(value) build.height = value end)
    numberField(tabBuild, "Espaçamento dos blocos", 6, 3, 12, function(value) build.spacing = value end)
    numberField(tabBuild, "Velocidade de construção (blocos/s)", 5000, 1, 5000, function(value) build.rate = value end)
    local setTurbo = toggle(tabBuild, "Turbo (sem pausa entre blocos)", function(value) build.turbo = value end)
    setTurbo(true)

    local function zoneForPlayer()
        for _, part in ipairs(workspace:GetChildren()) do
            local color = part:FindFirstChild("TeamColor")
            if part:IsA("BasePart") and color and color:IsA("BrickColorValue")
                and color.Value == player.TeamColor then return part end
        end
        return nil
    end
    local function blocksFolder()
        local folder = workspace:FindFirstChild("Blocks")
        return folder and folder:FindFirstChild(player.Name)
    end
    local function blockPart(model)
        if model:IsA("BasePart") then return model end
        return model:FindFirstChild("PPart") or model:FindFirstChildWhichIsA("BasePart", true)
    end
    local function getTool(name, remoteName)
        local character, humanoid = characterParts()
        if not character or not humanoid or humanoid.Health <= 0 then error("Personagem indisponível", 0) end
        local backpack = player:FindFirstChildOfClass("Backpack")
        local tool = character:FindFirstChild(name) or (backpack and backpack:FindFirstChild(name))
        if not tool or not tool:IsA("Tool") then error("Ferramenta não encontrada: " .. name, 0) end
        if tool.Parent ~= character then humanoid:EquipTool(tool); task.wait(0.1) end
        local remote = tool:FindFirstChild(remoteName)
        if tool.Parent ~= character or not remote or not remote:IsA("RemoteFunction") then
            error("Ferramenta incompatível: " .. name .. "/" .. remoteName, 0)
        end
        return remote
    end
    local function active(token)
        return alive and token == build.token and not farm.enabled
    end
    local function invoke(remote, args)
        if build.pending then error("Aguardando resposta da solicitação anterior", 0) end
        build.pending = true
        local response
        local signal = Instance.new("BindableEvent")
        local closed, timedOut = false, false
        local timeout = task.delay(8, function()
            timedOut = true
            if not closed then signal:Fire() end
        end)
        task.spawn(function()
            response = table.pack(pcall(function() return remote:InvokeServer(table.unpack(args, 1, args.n)) end))
            build.pending = false
            if not closed then signal:Fire() end
        end)
        if not response and not timedOut then signal.Event:Wait() end
        closed = true
        if not timedOut then task.cancel(timeout) end
        signal:Destroy()
        if not response then error("Sem resposta do servidor; a última solicitação ainda pode ser processada", 0) end
        if not response[1] then error(tostring(response[2]), 0) end
        if response[2] == false then error("O servidor recusou a solicitação", 0) end
    end
    local function positions(pattern, count, spacing, height)
        local result = {}
        local width = pattern == 1 and math.ceil(count ^ (1 / 3)) or math.ceil(math.sqrt(count))
        local pyramidWidth, pyramidCapacity = 0, 0
        if pattern == 8 then
            while pyramidCapacity < count do
                pyramidWidth = pyramidWidth + 1
                pyramidCapacity = pyramidCapacity + pyramidWidth * pyramidWidth
            end
        end
        for index = 0, count - 1 do
            local x, y, z = 0, height, 0
            if pattern == 3 then
                y = height + index * spacing
            elseif pattern == 4 then
                x = (index % width - (width - 1) / 2) * spacing
                y = height + math.floor(index / width) * spacing
            elseif pattern == 5 then
                x = (index - (count - 1) / 2) * spacing
            elseif pattern == 6 then
                local radius = count > 1 and spacing / (2 * math.sin(math.pi / count)) or 0
                local angle = 2 * math.pi * index / count
                x, z = math.cos(angle) * radius, math.sin(angle) * radius
            elseif pattern == 7 and count > 1 then
                local radius = spacing * math.sqrt(count) * 0.35
                local level = 1 - 2 * (index + 0.5) / count
                local ring = math.sqrt(math.max(0, 1 - level * level))
                local angle = index * math.pi * (3 - math.sqrt(5))
                x, z = math.cos(angle) * ring * radius, math.sin(angle) * ring * radius
                y = height + radius * (1 + level)
            elseif pattern == 7 then
                x, z = 0, 0
            elseif pattern == 8 then
                local remaining, side, layer = index, pyramidWidth, 0
                while remaining >= side * side and side > 1 do
                    remaining = remaining - side * side
                    side, layer = side - 1, layer + 1
                end
                x = (remaining % side - (side - 1) / 2) * spacing
                z = (math.floor(remaining / side) - (side - 1) / 2) * spacing
                y = height + layer * spacing
            elseif pattern == 9 then
                x = (index - (count - 1) / 2) * spacing
                y = height + index * spacing * 0.5
            else
                x = (index % width - (width - 1) / 2) * spacing
                z = (math.floor(index / width) % width - (width - 1) / 2) * spacing
                if pattern == 1 then y = y + math.floor(index / (width * width)) * spacing end
            end
            table.insert(result, Vector3.new(x, y, z))
        end
        return result
    end
    local function startJob(callback)
        if build.busy or build.pending then buildStatus.Text = "Aguarde a operação anterior terminar"; return end
        if farm.enabled then buildStatus.Text = "Desligue o Auto Farm antes de construir"; return end
        releaseMagnet()
        build.busy = true
        build.token = build.token + 1
        local token = build.token
        task.spawn(function()
            local ok, message = pcall(callback, token)
            build.busy = false
            if alive and not ok then buildStatus.Text = "Build: " .. tostring(message):sub(1, 180) end
        end)
    end
    stopBuild = function()
        build.token = build.token + 1
        if buildStatus.Parent then buildStatus.Text = "Cancelado. Blocos já criados permanecem no terreno." end
    end
    control(tabBuild, "TextButton", "Construir modelo").Activated:Connect(function()
        -- Congela as escolhas para impedir mudancas no meio de uma construcao.
        local name, count, pattern, spacing, height = build.block, build.count, build.pattern, build.spacing, build.height
        local location = build.location
        startJob(function(token)
            local zone = zoneForPlayer()
            if not zone then error("Terreno do seu time não encontrado", 0) end
            local origin = Vector3.new(0, zone.Size.Y / 2, 0)
            if location == 2 then
                local _, humanoid, rootPart = characterParts()
                if not rootPart or not humanoid or humanoid.Health <= 0 then error("Personagem indisponível", 0) end
                origin = zone.CFrame:PointToObjectSpace(rootPart.Position)
            end
            local zoneFrame = zone.CFrame
            local data = player:FindFirstChild("Data")
            local entry = data and data:FindFirstChild(name)
            if not entry or not (entry:IsA("IntValue") or entry:IsA("NumberValue")) then error("Bloco não encontrado no inventário", 0) end
            if entry.Value < count then error("Quantidade insuficiente desse bloco", 0) end
            local plan = positions(pattern, count, spacing, height)
            for _, offset in ipairs(plan) do
                local position = origin + offset
                if math.abs(position.X) > zone.Size.X / 2 - 3 or math.abs(position.Z) > zone.Size.Z / 2 - 3
                    or position.Y - zone.Size.Y / 2 > 120 or position.Y < zone.Size.Y / 2 then
                    error(location == 2 and "Modelo fora do terreno: aproxime-se do centro da sua base ou reduza o tamanho"
                        or "Modelo grande demais: reduza quantidade, altura ou espaçamento", 0)
                end
            end
            local remote = getTool("BuildingTool", "RF")
            local completed, sent = 0, 0
            local started = os.clock()
            local before, requests = {}, {}
            local folder = blocksFolder()
            if folder then for _, item in ipairs(folder:GetChildren()) do before[item] = true end end
            local capacity = build.turbo and 4 or 1
            local failure
            while completed < count do
                local running = active(token) and not failure
                if not zone.Parent then failure = "O terreno mudou"; running = false end
                local outstanding = 0
                for _, request in ipairs(requests) do
                    if not request.finished then outstanding = outstanding + 1 end
                end
                -- Apenas quatro solicitacoes em voo; uma resposta libera a proxima vaga.
                while running and outstanding < capacity and sent < #plan
                    and (build.turbo or os.clock() - started >= sent / build.rate) do
                    sent = sent + 1
                    local world = zoneFrame * CFrame.new(origin + plan[sent])
                    local request = {world = world, sentAt = os.clock()}
                    table.insert(requests, request)
                    outstanding = outstanding + 1
                    build.inFlight = (build.inFlight or 0) + 1
                    build.pending = true
                    local args = table.pack(name, entry.Value, zone, zone.CFrame:ToObjectSpace(world), true, world, false)
                    task.spawn(function()
                        request.response = table.pack(pcall(function()
                            return remote:InvokeServer(table.unpack(args, 1, args.n))
                        end))
                        request.repliedAt = os.clock()
                        build.inFlight = build.inFlight - 1
                        build.pending = build.inFlight > 0
                    end)
                end
                -- Uma consulta por quadro confirma todas as posicoes pendentes.
                folder = blocksFolder()
                if folder then
                    for _, item in ipairs(folder:GetChildren()) do
                        if not before[item] and item.Name == name then
                            local part = blockPart(item)
                            if part and part:IsA("BasePart") then
                                local nearest, best = nil, 3
                                for _, request in ipairs(requests) do
                                    if not request.created and not request.finished then
                                        local distance = (part.Position - request.world.Position).Magnitude
                                        if distance < best then nearest, best = request, distance end
                                    end
                                end
                                if nearest then
                                    nearest.created = item
                                    before[item] = true
                                    table.insert(build.created, item)
                                end
                            end
                        end
                    end
                end
                outstanding = 0
                for _, request in ipairs(requests) do
                    if not request.finished then
                        local response = request.response
                        if response and (not response[1] or response[2] == false) then
                            failure = failure or (response[1] and "Servidor recusou um bloco; fila interrompida"
                                or tostring(response[2]))
                            request.finished = true
                        elseif response and request.created then
                            request.finished = true
                            completed = completed + 1
                        elseif os.clock() - request.sentAt >= 8
                            or (request.repliedAt and os.clock() - request.repliedAt >= 3) then
                            failure = failure or "Bloco sem confirmação; fila interrompida, sem reenviar duplicatas"
                            request.finished = true
                        else
                            outstanding = outstanding + 1
                        end
                    end
                end
                if active(token) then
                    buildStatus.Text = string.format("Confirmados: %d/%d • fila: %d • %.1f blocos/s reais",
                        completed, count, outstanding, completed / math.max(0.001, os.clock() - started))
                end
                if (failure or not active(token)) and outstanding == 0 then break end
                if completed < count then task.wait() end
            end
            if failure then error(failure, 0) end
            if not active(token) then return end
            updateBlockButton()
            buildStatus.Text = string.format("Pronto: %d blocos em %.1fs • %.1f blocos/s. Use Soltar para o ímã.",
                completed, os.clock() - started, completed / math.max(0.001, os.clock() - started))
        end)
    end)
    control(tabBuild, "TextButton", "Soltar blocos criados para o ímã").Activated:Connect(function()
        startJob(function(token)
            local folder = blocksFolder()
            if not folder then error("Seus blocos não foram encontrados", 0) end
            local remote = getTool("PropertiesTool", "SetPropertieRF")
            local released = 0
            for _, item in ipairs(build.created) do
                if not active(token) then return end
                local part = item.Parent and blockPart(item)
                if item:IsDescendantOf(folder) and part and part:IsA("BasePart") and part.Anchored then
                    invoke(remote, table.pack("Anchored", {item}))
                    local deadline = os.clock() + 3
                    repeat task.wait(0.05) until not part.Parent or not part.Anchored or os.clock() >= deadline
                    if part.Parent and part.Anchored then error("Servidor não confirmou que o bloco foi solto", 0) end
                    released = released + 1
                end
            end
            if active(token) then buildStatus.Text = "Blocos liberados: " .. released end
        end)
    end)
    control(tabBuild, "TextButton", "Cancelar construção").Activated:Connect(stopBuild)
    inventory()
end

categories(tabMagnet, {
    {"Geral", {"Ativar ímã", "Coleta automática ao redor do jogador", "Limite da coleta automática", "Modo toggle (clique para prender/soltar)", "Modo do ímã", "Soltar todos os blocos"}, true},
    {"Captura", {"Raio de captura (studs)", "Alcance máximo (studs)", "Sem limite de distância do jogador", "Limite de conjuntos de blocos"}, false},
    {"Movimento", {"Resposta do movimento (%)", "Velocidade dos blocos (studs/s)",
        "Distância do cursor (studs)", "Atravessar obstáculos"}, false},
    {"Formação e tornado", {"Raio do círculo / órbita", "Altura da formação no jogador",
        "Altura do tornado", "Espaçamento da linha / parede", "Raio da esfera", "Velocidade da órbita (graus/s)"}, false},
    {"Restaurar", {"Resetar opções do ímã"}, false},
})
categories(tabMagnetPlayer, {
    {"Controle", {"Modo ao redor do jogador", "Ativar no jogador", "Soltar todos os blocos", "Desligar ímã"}, true},
    {"Formação", {"Raio do círculo / órbita", "Altura da formação no jogador", "Tamanho da caixa / esfera",
        "Altura do tornado", "Velocidade da órbita (graus/s)"}, true},
})
categories(tabBuild, {
    {"Blocos e modelo", {"Bloco", "Modelo", "Local", "Atualizar lista de blocos"}, true},
    {"Dimensões", {"Quantidade de blocos", "Altura sobre o terreno", "Espaçamento dos blocos"}, false},
    {"Construção", {"Velocidade de construção (blocos/s)", "Turbo (sem pausa entre blocos)", "Construir modelo",
        "Soltar blocos criados para o ímã", "Cancelar construção"}, true},
})

local function loadSettings()
    if not hasStorage then
        storageMessage("Sem salvamento em disco: readfile/writefile não estão disponíveis. Ajustes valem apenas nesta execução.")
        return
    end
    if type(isfile) == "function" then
        local checked, exists = pcall(isfile, settingsFile)
        if checked and not exists then
            storageMessage("Primeiro uso: suas alterações serão salvas automaticamente.")
            return
        end
    end
    local readOk, contents = pcall(readfile, settingsFile)
    if not readOk then
        storageMessage("Sem arquivo legível. Altere uma opção para tentar salvar suas preferências.")
        return
    end
    local ok, saved = pcall(function()
        assert(type(contents) == "string" and #contents <= 65536, "Arquivo inválido ou grande demais")
        local data = HttpService:JSONDecode(contents)
        assert(type(data) == "table" and data.version == 1 and data.userId == player.UserId
            and type(data.values) == "table", "Formato ou conta incompatível")
        return data
    end)
    if not ok then
        storageMessage("Preferências inválidas; usando padrões. O próximo salvamento substituirá o arquivo.")
        return
    end
    -- Sliders primeiro; alternadores depois. Auto Farm e aplicado por ultimo.
    local failed = false
    for _, kind in ipairs({"number", "string", "boolean"}) do
        for key, entry in pairs(preferences.controls) do
            local value = saved.values[key]
            if key ~= "Auto Farm/Auto Farm" and entry.kind == kind and type(value) == kind then
                if kind ~= "number" or (value == value and math.abs(value) < math.huge) then
                    local applied = pcall(entry.set, value)
                    if not applied then failed = true end
                end
            end
        end
    end
    local savedFarm = saved.values["Auto Farm/Auto Farm"]
    if type(savedFarm) == "boolean" then
        local applied = pcall(setFarm, savedFarm)
        if not applied then failed = true end
    end
    storageMessage(failed and "Preferências carregadas parcialmente; alguns controles falharam."
        or "Preferências restauradas. Salvamento automático ativo.")
end
loadSettings()
preferences.loading = false

-- Acabamento consistente dos cartoes da pagina inicial.
for _, item in ipairs(tabHome:GetChildren()) do
    if item:IsA("GuiObject") and item.BackgroundTransparency < 1 then
        edge(item)
        if item:IsA("TextButton") then feedback(item, item:FindFirstChildOfClass("UIStroke")) end
    end
end

gui.Destroying:Connect(function()
    -- Salva antes de restaurar o personagem: a limpeza nao apaga as preferencias.
    saveSettings()
    preferences.closed = true
    stopBuild()
    releaseMagnet()
    stopFlight()
    alive = false
    farm.enabled = false
    farm.token = farm.token + 1
    clearFarmPlatforms()
    restoreVisual()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    restoreMovement()
    restoreCollisions()
    removeFloor()
end)
