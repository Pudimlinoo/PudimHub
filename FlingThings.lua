-- PudimHub | Fling Things and People
-- Velocidade e pulo são acréscimos: 0 preserva o valor original do personagem.
if not game:IsLoaded() then game.Loaded:Wait() end
local env = (type(getgenv) == "function" and getgenv()) or _G
if env.PudimHubFTAP and type(env.PudimHubFTAP.Destroy) == "function" then
    env.PudimHubFTAP.Destroy()
end
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
assert(Player, "Execute no cliente Roblox.")
local Session = {Alive = true, Connections = {}}
env.PudimHubFTAP = Session
local function Connect(signal, callback)
    local connection = signal:Connect(function(...)
        if Session.Alive then callback(...) end
    end)
    table.insert(Session.Connections, connection)
    return connection
end
local Theme = {
    Text = Color3.fromRGB(240,240,240), Accent = Color3.fromRGB(240,30,55),
    Element = Color3.fromRGB(26,10,15),
}
local Configs = {SpeedExtra = 0, JumpExtra = 0, Fly = false, FlySpeed = 50, UIScale = 100}
local Refresh = {}
local function SetConfig(key, value)
    Configs[key] = value
    for _, refresh in pairs(Refresh) do refresh() end
end
local EndFly, RestoreMovement
local function StopAll()
    Configs.Fly = false
    Configs.SpeedExtra = 0
    Configs.JumpExtra = 0
    if EndFly then EndFly() end
    if RestoreMovement then RestoreMovement() end
    for _, refresh in pairs(Refresh) do refresh() end
end
local function New(class, parent, props)
    local object = Instance.new(class)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function Round(object, radius)
    New("UICorner", object, {CornerRadius = UDim.new(0, radius or 10)})
    return object
end
local function Text(parent, text, size, position, dimensions, color)
    return New("TextLabel", parent, {Text = text, TextSize = size or 13, Position = position or UDim2.new(),
        Size = dimensions or UDim2.fromScale(1,1), BackgroundTransparency = 1, TextColor3 = color or Theme.Text,
        Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
end
local ScreenGui = New("ScreenGui", Player:WaitForChild("PlayerGui"), {Name = "PudimHub_FTAP", ResetOnSpawn = false, DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
Session.Gui = ScreenGui
local MainFrame = Round(New("Frame", ScreenGui, {Size = UDim2.fromOffset(600, 600), AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.fromScale(0.5,0.5), BackgroundColor3 = Color3.fromRGB(5,5,8), BorderSizePixel = 0, ClipsDescendants = false, BackgroundTransparency = 0.05}), 14)
New("UIStroke", MainFrame, {Color = Color3.fromRGB(240,30,55), Thickness = 1, Transparency = 0.25})
local scale = New("UIScale", MainFrame)
local TopBar = New("Frame", MainFrame, {Size = UDim2.new(1,0,0,64), BackgroundColor3 = Color3.fromRGB(13,8,11), BorderSizePixel = 0})
Round(TopBar,12)
local brand=Text(TopBar,"🍮 PUDIMHUB",19,UDim2.fromOffset(18,18),UDim2.fromOffset(220,28))
brand.Font=Enum.Font.GothamBlack
Text(TopBar,"FLING THINGS AND PEOPLE",10,UDim2.new(1,-232,0,20),UDim2.fromOffset(184,24),Color3.fromRGB(156,161,177))
local accent=New("Frame",MainFrame,{Position=UDim2.fromOffset(18,62),Size=UDim2.new(1,-36,0,1),BackgroundColor3=Theme.Accent,BorderSizePixel=0})
New("UIGradient",accent,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.85)})})
local function Button(parent, label, position, size, callback, color)
    local b = Round(New("TextButton", parent, {Text = label, Position = position, Size = size, BackgroundColor3 = color or Theme.Element,
        TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, AutoButtonColor = true, BorderSizePixel = 0}), 7)
    local edge=New("UIStroke",b,{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Theme.Accent,Thickness=1,Transparency=0.82})
    Connect(b.MouseEnter,function() edge.Transparency=0.45 end)
    Connect(b.MouseLeave,function() edge.Transparency=0.82 end)
    Connect(b.Activated, callback)
    return b
end
Button(MainFrame, "PARAR TUDO", UDim2.new(0,12,1,-140), UDim2.fromOffset(126,32), function() StopAll() end, Color3.fromRGB(109,42,51))
local minimize = Button(TopBar, "—", UDim2.new(1,-38,0,17), UDim2.fromOffset(30,30), function() MainFrame.Visible = false end)
Button(MainFrame, "ENCERRAR", UDim2.new(0,12,1,-100), UDim2.fromOffset(126,32), function() Session.Destroy() end)
local sidebar=New("ScrollingFrame",MainFrame,{Position=UDim2.fromOffset(12,76),Size=UDim2.new(0,132,1,-228),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=Theme.Accent})
New("UIListLayout",sidebar,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local ContentContainer = New("Frame", MainFrame, {Position = UDim2.fromOffset(154,122), Size = UDim2.new(1,-166,1,-180), BackgroundTransparency = 1})
local footer = New("Frame", MainFrame, {Position = UDim2.new(0,12,1,-48), Size = UDim2.new(1,-24,0,40), BackgroundColor3 = Color3.fromRGB(13,8,11), BorderSizePixel = 0})
local status = Text(footer, "Pronto para iniciar", 12, UDim2.fromOffset(10,2), UDim2.new(1,-30,0,19), Theme.Accent)
local substatus = Text(footer, "0 = movimento original do personagem", 10, UDim2.fromOffset(10,23), UDim2.new(1,-30,0,16), Color3.fromRGB(156,161,177))
local Pages, SelectedPage = {}, nil
local search = Round(New("TextBox", MainFrame, {Position=UDim2.fromOffset(154,76), Size=UDim2.new(1,-166,0,34),
    BackgroundColor3=Color3.fromRGB(13,8,11), BorderSizePixel=0, Text="", PlaceholderText="Buscar nesta aba…",
    TextColor3=Theme.Text, PlaceholderColor3=Color3.fromRGB(156,161,177), Font=Enum.Font.GothamMedium,
    TextSize=12, ClearTextOnFocus=false, TextXAlignment=Enum.TextXAlignment.Left}), 8)
New("UIPadding", search, {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)})
local function FilterPage()
    if not SelectedPage then return end
    local query = search.Text:lower():match("^%s*(.-)%s*$")
    for _, item in ipairs(SelectedPage:GetChildren()) do
        if item:IsA("Frame") and item.Name ~= "PageHeader" then
            local found = query == ""
            for _, label in ipairs(item:GetDescendants()) do
                if (label:IsA("TextLabel") or label:IsA("TextButton")) and label.Text:lower():find(query,1,true) then found = true end
            end
            item.Visible = found
        end
    end
    SelectedPage.CanvasPosition = Vector2.zero
end
Connect(search:GetPropertyChangedSignal("Text"), FilterPage)
local function Page(label, subtitle)
    local index = #Pages + 1
    local b
    local page = New("ScrollingFrame", ContentContainer, {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent})
    New("UIListLayout", page, {Padding = UDim.new(0,9), SortOrder = Enum.SortOrder.LayoutOrder})
    local header = New("Frame", page, {Name="PageHeader", LayoutOrder=0, Size = UDim2.new(1,-8,0,52), BackgroundTransparency = 1})
    Text(header, label, 21, UDim2.new(), UDim2.new(1,0,0,28))
    Text(header, subtitle, 11, UDim2.fromOffset(0,31), UDim2.new(1,0,0,18), Color3.fromRGB(156,161,177))
    b = Button(sidebar, label, UDim2.new(), UDim2.new(1,-6,0,42), function()
        for _, entry in ipairs(Pages) do entry.Page.Visible = false; entry.Button.BackgroundColor3 = Theme.Element; entry.Button.TextColor3 = Theme.Text end
        page.Visible = true; b.BackgroundColor3 = Color3.fromRGB(95,10,25); b.TextColor3 = Theme.Accent; SelectedPage = page
        search.Text = ""; FilterPage()
    end, Theme.Element)
    b.LayoutOrder=index
    table.insert(Pages, {Page = page, Button = b})
    return page
end
local function Card(parent, height)
    local card=Round(New("Frame", parent, {LayoutOrder=#parent:GetChildren(), Size = UDim2.new(1,-8,0,height), BackgroundColor3 = Color3.fromRGB(13,8,11), BackgroundTransparency=0.2, BorderSizePixel = 0}), 10)
    New("UIStroke",card,{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Theme.Accent,Thickness=1,Transparency=0.8})
    return card
end
local function Toggle(parent, title, detail, key)
    local card=Card(parent,62)
    Text(card,title,12,UDim2.fromOffset(12,9),UDim2.new(1,-78,0,20))
    Text(card,detail,10,UDim2.fromOffset(12,32),UDim2.new(1,-78,0,20),Color3.fromRGB(156,161,177))
    local hit=New("TextButton",card,{Text="",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,AutoButtonColor=false})
    local toggle=Round(New("Frame",hit,{Size=UDim2.fromOffset(40,22),Position=UDim2.new(1,-52,0.5,-11),BackgroundColor3=Color3.fromRGB(55,18,25),BorderSizePixel=0}),11)
    local knob=Round(New("Frame",toggle,{Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(3,3),BackgroundColor3=Theme.Text,BorderSizePixel=0}),8)
    local colorTween,positionTween
    Refresh[key]=function()
        if colorTween then colorTween:Cancel() end
        if positionTween then positionTween:Cancel() end
        colorTween=TweenService:Create(toggle,TweenInfo.new(0.15),{BackgroundColor3=Configs[key] and Theme.Accent or Color3.fromRGB(55,18,25)})
        positionTween=TweenService:Create(knob,TweenInfo.new(0.15),{Position=UDim2.fromOffset(Configs[key] and 21 or 3,3)})
        colorTween:Play(); positionTween:Play()
    end
    Connect(hit.Activated,function() SetConfig(key,not Configs[key]) end)
    Refresh[key]()
end
local function Slider(parent, title, key, minimum, maximum)
    local card = Card(parent,82)
    local label = Text(card,title,12,UDim2.fromOffset(13,8),UDim2.new(1,-88,0,20))
    local rail = New("TextButton",card,{Text="",Position=UDim2.fromOffset(16,38),Size=UDim2.new(1,-32,0,36),BackgroundTransparency=1})
    local track = Round(New("Frame",rail,{Position=UDim2.fromOffset(0,10),Size=UDim2.new(1,0,0,5),BackgroundColor3=Color3.fromRGB(59,14,24),BorderSizePixel=0}),3)
    local fill = Round(New("Frame",track,{Size=UDim2.fromScale(0,1),BackgroundColor3=Theme.Accent,BorderSizePixel=0}),3)
    local knob=Round(New("Frame",track,{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(16,16),BackgroundColor3=Theme.Text,BorderSizePixel=0}),8)
    local valueBox=Round(New("TextBox",card,{Position=UDim2.new(1,-70,0,8),Size=UDim2.fromOffset(58,26),BackgroundColor3=Color3.fromRGB(30,9,15),TextColor3=Theme.Text,Font=Enum.Font.GothamBold,TextSize=12,ClearTextOnFocus=false,BorderSizePixel=0}),6)
    local dragging,scrollWasEnabled
    Refresh[key] = function()
        label.Text = title
        valueBox.Text=tostring(Configs[key])
        knob.Position=UDim2.fromScale((Configs[key]-minimum)/(maximum-minimum),0.5)
        fill.Size = UDim2.fromScale((Configs[key]-minimum)/(maximum-minimum),1)
    end
    Connect(valueBox.FocusLost,function()
        local value=tonumber(valueBox.Text)
        if value and value==value and math.abs(value)<math.huge then Configs[key]=math.clamp(math.floor(value+0.5),minimum,maximum) end
        Refresh[key]()
    end)
    local function Update(input)
        local amount=math.clamp((input.Position.X-rail.AbsolutePosition.X)/math.max(rail.AbsoluteSize.X,1),0,1)
        Configs[key]=math.floor(minimum+(maximum-minimum)*amount+0.5); Refresh[key]()
    end
    Connect(rail.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=input; scrollWasEnabled=parent.ScrollingEnabled; parent.ScrollingEnabled=false; Update(input) end
    end)
    Connect(UserInputService.InputChanged,function(input)
        if dragging and (input==dragging or (dragging.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then Update(input) end
    end)
    Connect(UserInputService.InputEnded,function(input) if input==dragging then dragging=nil; parent.ScrollingEnabled=scrollWasEnabled end end)
    Refresh[key]()
end

local Home = Page("Início", "Fling Things and People • PudimHub")
local PlayerTab = Page("Player", "Movimento e voo do seu personagem.")
local Settings = Page("Ajustes", "Interface, atalhos e restauração.")
local function Info(parent, title, description)
    local card = Card(parent, 100)
    Text(card, title, 13, UDim2.fromOffset(12,8), UDim2.new(1,-24,0,22), Theme.Accent)
    local body = Text(card, description, 12, UDim2.fromOffset(12,35), UDim2.new(1,-24,0,56))
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextTruncate = Enum.TextTruncate.None
    return body
end
local profileCard = Card(Home, 84)
profileCard.Name = "PlayerProfile"
local avatar = Round(New("ImageLabel", profileCard, {Name="PlayerAvatar", Size=UDim2.fromOffset(56,56),
    Position=UDim2.new(0,12,0.5,-28), BackgroundColor3=Theme.Element, BorderSizePixel=0, Image="",
    ScaleType=Enum.ScaleType.Crop}), 28)
New("UIStroke", avatar, {Color=Theme.Accent, Thickness=1, Transparency=0.35})
local profile = Text(profileCard, Player.DisplayName .. "  (@" .. Player.Name .. ")", 13,
    UDim2.fromOffset(80,8), UDim2.new(1,-94,1,-16))
profile.TextWrapped = true
profile.TextTruncate = Enum.TextTruncate.None
local function LoadAvatar()
    Session.AvatarRevision = (Session.AvatarRevision or 0) + 1
    local revision = Session.AvatarRevision
    task.spawn(function()
        for attempt=1,3 do
            if not Session.Alive or revision ~= Session.AvatarRevision then return end
            local ok, content, ready = pcall(function()
                return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            end)
            if not Session.Alive or revision ~= Session.AvatarRevision or not avatar.Parent then return end
            if ok and type(content)=="string" and content~="" then avatar.Image=content; if ready then return end end
            if attempt<3 then task.wait(2) end
        end
    end)
end
LoadAvatar()
Connect(Player.CharacterAppearanceLoaded, LoadAvatar)
local healthCard = Card(Home, 62)
local healthLabel = Text(healthCard, "Vida: aguardando personagem", 13, UDim2.fromOffset(12,8), UDim2.new(1,-24,0,30))
local healthTrack = Round(New("Frame", healthCard, {Position=UDim2.new(0,12,1,-14), Size=UDim2.new(1,-24,0,4),
    BackgroundColor3=Theme.Element, BorderSizePixel=0}), 2)
local healthFill = Round(New("Frame", healthTrack, {Size=UDim2.fromScale(0,1), BorderSizePixel=0,
    BackgroundColor3=Color3.fromRGB(86,205,159)}), 2)
local movementCard = Card(Home, 60)
local movementInfo = Text(movementCard, "Aguardando personagem...", 12, UDim2.fromOffset(12,8), UDim2.new(1,-24,1,-16))
movementInfo.TextWrapped = true
Info(Home, "ATALHOS", "H: abrir/fechar painel • G: voo\nWASD: direção • Espaço: subir • Ctrl: descer")
Info(Home, "MOVIMENTO", "Arraste as barras ou digite um valor. Velocidade e pulo em 0 mantêm o padrão do personagem. O mouse fica livre enquanto o painel está aberto.")
local centerCard = Card(Home, 48)
Button(centerCard, "Centralizar janela", UDim2.fromOffset(10,7), UDim2.new(1,-20,0,34), function()
    MainFrame.Position = UDim2.fromScale(0.5,0.5)
end)
Info(PlayerTab, "ZERO = PADRÃO", "Os valores são extras acima do movimento original. Ex.: velocidade original 16 + extra 10 = 26. Pulo usa força ou altura, conforme o jogo.")
Slider(PlayerTab, "Velocidade extra", "SpeedExtra", 0, 150)
Slider(PlayerTab, "Pulo extra (força / altura)", "JumpExtra", 0, 150)
Toggle(PlayerTab, "Voo (G)", "WASD • Espaço / Ctrl para altura.", "Fly")
Slider(PlayerTab, "Velocidade do voo", "FlySpeed", 1, 200)
Slider(Settings, "Escala do painel (%)", "UIScale", 60, 120)
Info(Settings, "ATALHOS", "H abre ou fecha o painel. O botão PUDIM também reabre. G liga ou desliga o voo. Atalhos não atuam enquanto você digita.")
local resetCard = Card(Settings, 52)
Button(resetCard, "RESTAURAR PADRÕES", UDim2.fromOffset(10,9), UDim2.new(1,-20,0,34), function()
    StopAll()
    SetConfig("FlySpeed", 50)
    SetConfig("UIScale", 100)
end)
Pages[1].Page.Visible = true
SelectedPage = Home
Pages[1].Button.BackgroundColor3 = Color3.fromRGB(95,10,25)
Pages[1].Button.TextColor3 = Theme.Accent
Button(ScreenGui, "PUDIM", UDim2.new(0,12,0.5,-20), UDim2.fromOffset(72,40), function()
    MainFrame.Visible = not MainFrame.Visible
end)
-- Painel adaptado à área útil; arraste pelo cabeçalho com mouse.
TopBar.Active = true
local drag, dragStart, panelStart
Connect(TopBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag, dragStart, panelStart = input, input.Position, MainFrame.AbsolutePosition + MainFrame.AbsoluteSize / 2
    end
end)
Connect(UserInputService.InputEnded, function(input) if input == drag then drag = nil end end)
local function PlacePanel(point)
    local view = ScreenGui.AbsoluteSize
    local half = MainFrame.AbsoluteSize / 2
    MainFrame.Position = UDim2.fromOffset(
        math.clamp(point.X, half.X, math.max(half.X, view.X-half.X)),
        math.clamp(point.Y, half.Y, math.max(half.Y, view.Y-half.Y)))
end
Connect(UserInputService.InputChanged, function(input)
    if drag and (input == drag or (drag.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
        local delta = input.Position - dragStart
        PlacePanel(panelStart + Vector2.new(delta.X,delta.Y))
    end
end)
local function Resize()
    local view = ScreenGui.AbsoluteSize
    scale.Scale = math.max(0.1, math.min(Configs.UIScale/100, (view.X-24)/600, (view.Y-24)/600))
    PlacePanel(MainFrame.AbsolutePosition + MainFrame.AbsoluteSize/2)
end
Connect(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), Resize)

-- Guarde/restaure apenas propriedades alteradas por esta sessão.
-- Novos Humanoids recebem novas bases após cada respawn.
local originals
local function Humanoid()
    return Player.Character and Player.Character:FindFirstChildWhichIsA("Humanoid")
end
RestoreMovement = function()
    if not originals then return end
    if originals.H.Parent then
        for property, value in pairs(originals.Values) do originals.H[property] = value end
    end
    originals = nil
end
local function ApplyExtra(h, property, extra)
    if extra == 0 then
        if originals.Values[property] ~= nil then
            h[property] = originals.Values[property]
            originals.Values[property] = nil
        end
        return
    end
    if originals.Values[property] == nil then originals.Values[property] = h[property] end
    h[property] = originals.Values[property] + extra
end
local flight
EndFly = function()
    if not flight then return end
    flight.Velocity:Destroy()
    flight.Orientation:Destroy()
    flight.Attachment:Destroy()
    if flight.H.Parent then
        flight.H.PlatformStand = flight.PlatformStand
        flight.H.AutoRotate = flight.AutoRotate
    end
    if flight.Root.Parent then flight.Root.AssemblyLinearVelocity = Vector3.zero end
    flight = nil
end
local function UpdatePlayer()
    local h = Humanoid()
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if originals and originals.H ~= h then RestoreMovement() end
    if h and h.Health > 0 then
        originals = originals or {H = h, Values = {}}
        ApplyExtra(h, "WalkSpeed", Configs.SpeedExtra)
        ApplyExtra(h, "JumpPower", h.UseJumpPower and Configs.JumpExtra or 0)
        ApplyExtra(h, "JumpHeight", not h.UseJumpPower and Configs.JumpExtra or 0)
    end
    local canFly = Configs.Fly and h and h.Health > 0 and root and not h.SeatPart and not root.Anchored
    if flight and (not canFly or flight.Root ~= root or flight.H ~= h) then EndFly() end
    if not canFly then return end
    local camera = Workspace.CurrentCamera
    if not camera then
        if flight then flight.Velocity.VectorVelocity = Vector3.zero end
        return
    end
    if not flight then
        local attachment = New("Attachment", root, {Name = "PudimFlyAttachment"})
        local velocity = New("LinearVelocity", root, {Name = "PudimFlyVelocity", Attachment0 = attachment,
            RelativeTo = Enum.ActuatorRelativeTo.World, MaxForce = math.huge, VectorVelocity = Vector3.zero})
        local orientation = New("AlignOrientation", root, {Name = "PudimFlyOrientation", Attachment0 = attachment,
            Mode = Enum.OrientationAlignmentMode.OneAttachment, MaxTorque = math.huge, Responsiveness = 25})
        flight = {H = h, Root = root, Attachment = attachment, Velocity = velocity, Orientation = orientation,
            PlatformStand = h.PlatformStand, AutoRotate = h.AutoRotate}
        h.PlatformStand = true
        h.AutoRotate = false
    end
    local move = Vector3.zero
    if not UserInputService:GetFocusedTextBox() then
        local x = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
        local z = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
        if x ~= 0 or z ~= 0 then
            move = camera.CFrame.RightVector * x + camera.CFrame.LookVector * z
        end
        local y = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0)
            - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0)
        move = move + Vector3.yAxis * y
    end
    if move.Magnitude > 1 then move = move.Unit end
    flight.Velocity.VectorVelocity = move * Configs.FlySpeed
    flight.Orientation.CFrame = camera.CFrame.Rotation
end
Session.Destroy = function()
    if not Session.Alive then return end
    Session.Alive = false
    RunService:UnbindFromRenderStep("PudimHubFTAPCursor")
    if Session.RestoreMouse then Session.RestoreMouse() end
    EndFly()
    RestoreMovement()
    for _, connection in ipairs(Session.Connections) do connection:Disconnect() end
    table.clear(Session.Connections)
    ScreenGui:Destroy()
    if env.PudimHubFTAP == Session then env.PudimHubFTAP = nil end
end
Connect(ScreenGui.Destroying, Session.Destroy)
Connect(Player.CharacterRemoving, function()
    SetConfig("Fly", false)
    EndFly()
    RestoreMovement()
end)
Connect(UserInputService.InputBegan, function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.G then SetConfig("Fly", not Configs.Fly)
    elseif input.KeyCode == Enum.KeyCode.H then MainFrame.Visible = not MainFrame.Visible end
end)
-- Modal libera o cursor em primeira pessoa; a atualização após a câmera
-- mantém o mouse livre caso o controle do jogo reaplique o bloqueio.
local savedMouse
Session.RestoreMouse = function()
    minimize.Modal = false
    if savedMouse then
        UserInputService.MouseBehavior = savedMouse.Behavior
        UserInputService.MouseIconEnabled = savedMouse.Icon
        savedMouse = nil
    end
end
local function SyncMouse()
    if not Session.Alive or not MainFrame.Visible or not ScreenGui.Enabled then
        Session.RestoreMouse()
        return
    end
    if not savedMouse then
        savedMouse = {Behavior=UserInputService.MouseBehavior, Icon=UserInputService.MouseIconEnabled}
    end
    minimize.Modal = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end
Connect(MainFrame:GetPropertyChangedSignal("Visible"), SyncMouse)
Connect(ScreenGui:GetPropertyChangedSignal("Enabled"), SyncMouse)
RunService:BindToRenderStep("PudimHubFTAPCursor", Enum.RenderPriority.Last.Value + 1, SyncMouse)
SyncMouse()
local elapsed, frames = 0, 0
local sessionStart = os.clock()
Connect(RunService.Heartbeat, function(dt)
    UpdatePlayer()
    elapsed = elapsed + dt
    frames = frames + 1
    if elapsed < 0.2 then return end
    local fps = math.floor(frames / elapsed + 0.5)
    elapsed, frames = 0, 0
    Resize()
    local h = Humanoid()
    local ratio = h and math.clamp(h.Health/math.max(h.MaxHealth,1),0,1) or 0
    healthLabel.Text = h and string.format("Vida  %.0f / %.0f", h.Health, h.MaxHealth) or "Aguardando respawn…"
    healthFill.Size = UDim2.fromScale(ratio,1)
    healthFill.BackgroundColor3 = ratio < 0.3 and Theme.Accent or Color3.fromRGB(86,205,159)
    profile.Text = Player.DisplayName .. "  (@" .. Player.Name .. ")\n" .. (Player.Team and Player.Team.Name or "Sem time")
    local seconds = math.floor(os.clock()-sessionStart)
    substatus.Text = string.format("%d FPS / %d jogadores / %02d:%02d nesta sessão / H: menu", fps, #Players:GetPlayers(), math.floor(seconds/60), seconds%60)
    status.Text = flight and "Voo ativo" or (Configs.Fly and "Voo aguardando personagem livre" or "Pronto")
    if h then
        movementInfo.Text = string.format("Velocidade: %.1f • %s: %.1f\nFling Things and People", h.WalkSpeed,
            h.UseJumpPower and "Força do pulo" or "Altura do pulo", h.UseJumpPower and h.JumpPower or h.JumpHeight)
    else movementInfo.Text = "Aguardando personagem..." end
end)
Resize()
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Pudimlinoo/PudimHub/main/script.lua"))()
