-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Pudimlinoo/PudimHub/main/script.lua"))()

-- PudimHub Dragon Adventures v018 | revisão do script enviado
-- Interações dependem dos objetos carregados e das funções do executor.
if not game:IsLoaded() then game.Loaded:Wait() end
local env = (type(getgenv) == "function" and getgenv()) or _G
if env.PudimHubDA and type(env.PudimHubDA.Destroy) == "function" then
    pcall(env.PudimHubDA.Destroy)
end
local Session = {Alive = true, Connections = {}, Revision = 0}
env.PudimHubDA = Session
local function Connect(signal, callback)
    local connection = signal:Connect(function(...)
        if Session.Alive then callback(...) end
    end)
    table.insert(Session.Connections, connection)
    return connection
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer


-- // CONFIGURAÇÕES VISUAIS
local Theme = {
    Background = Color3.fromRGB(5, 5, 8),
    Sidebar = Color3.fromRGB(13, 8, 11),
    Element = Color3.fromRGB(26, 10, 15),
    Text = Color3.fromRGB(240, 240, 240),
    Accent = Color3.fromRGB(240, 30, 55), -- Vermelho clássico da referência
    ToggleOff = Color3.fromRGB(50, 50, 60),
    Outline = Color3.fromRGB(40, 40, 50)
}

-- // VARIÁVEIS DE CONTROLE
local Configs = {
    -- Gerais
    AutoFarm = false,
    PlayerMods = false,
    AntiAFK = true,
    AutoEgg = false,
    AutoChest = false, -- [NOVO] Auto Baú
    AutoCollect = false,
    EspMobs = false,
    EspEggs = false,
    EspChests = false, -- [NOVO] ESP Baú
    EspResources = false,
    WalkSpeed = 16,
    JumpPower = 50,
    Fly = false,
    FlySpeed = 50,
    FarmDistance = 15,
    
    -- Riding
    AutoRiding = false,
    AutoStartRace = false,
    TweenSpeed = 190,
    SearchRadius = 1000,
    IgnoreTime = 5,
    
    -- Filtros Riding
    MinSize = 130,
    MaxTransparency = 0.9
}

local State = {
    TargetMob = nil,
    CurrentEggIndex = 1,
    Flying = false,
    WasFlying = false,
    Blacklist = {},
    LastPos = Vector3.new(0,0,0),
    StuckCount = 0
}

local Cache = { Mobs = {}, Eggs = {}, Resources = {}, Chests = {} }
local ESP_Storage = {} 




Configs.MobPriority="Mais próximo"
Configs.MobFilter=""
Configs.ToolName=""
Configs.FarmPosition="Acima"
Configs.AttackMode="Ferramenta"
Configs.AutoEquip=false
Configs.FarmRadius=1500
Configs.AttackInterval=250
Configs.StallTimeout=15
Configs.CollectRetries=3
Configs.CollectWait=4
Configs.RetryCooldown=20
Configs.TravelSpeed=100
Configs.EspDistance=1500
Configs.EspLimit=25
Configs.EspThroughWalls=true
Configs.EspHighlight=true

local Refresh = {}
local movementKeys = {"AutoRiding", "AutoFarm", "AutoEgg", "AutoChest", "AutoCollect", "Fly"}
local function CancelMove()
    Session.Revision += 1
    if Session.Tween then Session.Tween:Cancel(); Session.Tween = nil end
end
local function SetConfig(key, value)
    if table.find(movementKeys, key) then
        CancelMove()
        if value then
            for _, other in ipairs(movementKeys) do
                if other ~= key then Configs[other] = false end
            end
        end
    end
    Configs[key] = value
    for _, refresh in pairs(Refresh) do refresh() end
end
local function GetRoot() return Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") end
local function GetHumanoid() return Player.Character and Player.Character:FindFirstChildWhichIsA("Humanoid") end
local function Part(object)
    if not object or not object.Parent then return nil end
    if object:IsA("BasePart") then return object end
    if object:IsA("Attachment") then return object:FindFirstAncestorWhichIsA("BasePart") end
    if object:IsA("Model") and object.PrimaryPart then return object.PrimaryPart end
    return object:FindFirstChild("HumanoidRootPart") or object:FindFirstChildWhichIsA("BasePart", true)
end
local function GetMoverPart()
    local h = GetHumanoid()
    if h and h.SeatPart then
        return h.SeatPart.AssemblyRootPart or h.SeatPart
    end
    return GetRoot()
end
local function StopAll()
    CancelMove()
    for _, key in ipairs(movementKeys) do Configs[key] = false end
    for _, refresh in pairs(Refresh) do refresh() end
end

-- HUD v018: páginas, telemetria e controles de mouse/toque.
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
local ScreenGui = New("ScreenGui", Player:WaitForChild("PlayerGui"), {Name = "PudimHub_DA_v018", ResetOnSpawn = false, DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
Session.Gui = ScreenGui
local MainFrame = Round(New("Frame", ScreenGui, {Size = UDim2.fromOffset(600, 600), AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.fromScale(0.5,0.5), BackgroundColor3 = Color3.fromRGB(5,5,8), BorderSizePixel = 0, ClipsDescendants = false, BackgroundTransparency = 0.05}), 14)
New("UIStroke", MainFrame, {Color = Color3.fromRGB(240,30,55), Thickness = 1, Transparency = 0.25})
local scale = New("UIScale", MainFrame)
local TopBar = New("Frame", MainFrame, {Size = UDim2.new(1,0,0,64), BackgroundColor3 = Color3.fromRGB(13,8,11), BorderSizePixel = 0})
Round(TopBar,12)
local brand=Text(TopBar,"🍮 PUDIMHUB",19,UDim2.fromOffset(18,18),UDim2.fromOffset(220,28))
brand.Font=Enum.Font.GothamBlack
Text(TopBar,"V018 / DRAGON ADVENTURES",10,UDim2.new(1,-232,0,20),UDim2.fromOffset(184,24),Color3.fromRGB(156,161,177))
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
Button(MainFrame, "PARAR TUDO", UDim2.fromOffset(154,76), UDim2.fromOffset(120,32), function() StopAll() end, Color3.fromRGB(109,42,51))
Button(TopBar, "—", UDim2.new(1,-38,0,17), UDim2.fromOffset(30,30), function() MainFrame.Visible = false end)
Button(MainFrame, "ENCERRAR", UDim2.fromOffset(282,76), UDim2.fromOffset(100,32), function() Session.Destroy() end)
local sidebar=New("ScrollingFrame",MainFrame,{Position=UDim2.fromOffset(12,76),Size=UDim2.new(0,132,1,-124),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=Theme.Accent})
New("UIListLayout",sidebar,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local ContentContainer = New("Frame", MainFrame, {Position = UDim2.fromOffset(154,122), Size = UDim2.new(1,-166,1,-180), BackgroundTransparency = 1})
local footer = New("Frame", MainFrame, {Position = UDim2.new(0,12,1,-48), Size = UDim2.new(1,-24,0,40), BackgroundColor3 = Color3.fromRGB(13,8,11), BorderSizePixel = 0})
local status = Text(footer, "Pronto para iniciar", 12, UDim2.fromOffset(10,2), UDim2.new(1,-30,0,19), Theme.Accent)
local substatus = Text(footer, "Escolha um farm na barra lateral", 10, UDim2.fromOffset(10,23), UDim2.new(1,-30,0,16), Color3.fromRGB(156,161,177))
local Pages, SelectedPage = {}, nil
local function Page(label, subtitle)
    local index = #Pages + 1
    local b
    local page = New("ScrollingFrame", ContentContainer, {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent})
    New("UIListLayout", page, {Padding = UDim.new(0,9), SortOrder = Enum.SortOrder.LayoutOrder})
    local header = New("Frame", page, {Size = UDim2.new(1,-8,0,52), BackgroundTransparency = 1})
    Text(header, label, 21, UDim2.new(), UDim2.new(1,0,0,28))
    Text(header, subtitle, 11, UDim2.fromOffset(0,31), UDim2.new(1,0,0,18), Color3.fromRGB(156,161,177))
    b = Button(sidebar, label, UDim2.new(), UDim2.new(1,-6,0,42), function()
        for _, entry in ipairs(Pages) do entry.Page.Visible = false; entry.Button.BackgroundColor3 = Theme.Element; entry.Button.TextColor3 = Theme.Text end
        page.Visible = true; b.BackgroundColor3 = Color3.fromRGB(95,10,25); b.TextColor3 = Theme.Accent; SelectedPage = page
    end, Theme.Element)
    b.LayoutOrder=index
    table.insert(Pages, {Page = page, Button = b})
    return page
end
local function Card(parent, height)
    local card=Round(New("Frame", parent, {Size = UDim2.new(1,-8,0,height), BackgroundColor3 = Color3.fromRGB(13,8,11), BackgroundTransparency=0.2, BorderSizePixel = 0}), 8)
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
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=input; scrollWasEnabled=parent.ScrollingEnabled; parent.ScrollingEnabled=false; Update(input) end
    end)
    Connect(UserInputService.InputChanged,function(input)
        if dragging and (input==dragging or input.UserInputType==Enum.UserInputType.MouseMovement) then Update(input) end
    end)
    Connect(UserInputService.InputEnded,function(input) if input==dragging then dragging=nil; parent.ScrollingEnabled=scrollWasEnabled end end)
    Refresh[key]()
end
local function Choice(parent,title,key,options)
    local card=Card(parent,48)
    Text(card,title,12,UDim2.fromOffset(13,13),UDim2.new(0.45,0,0,22))
    local b=Button(card,"",UDim2.new(0.45,0,0,9),UDim2.new(0.55,-13,0,30),function()
        local index=table.find(options,Configs[key]) or 0
        SetConfig(key,options[index % #options + 1])
    end)
    Refresh[key]=function() b.Text=tostring(Configs[key]) .. "  ›" end
    Refresh[key]()
end
local function Input(parent,title,key,placeholder)
    local card=Card(parent,62)
    Text(card,title,11,UDim2.fromOffset(13,6),UDim2.new(1,-26,0,18))
    local box=Round(New("TextBox",card,{Position=UDim2.fromOffset(13,29),Size=UDim2.new(1,-26,0,25),
        Text=Configs[key],PlaceholderText=placeholder,ClearTextOnFocus=false,TextSize=11,Font=Enum.Font.Gotham,
        BackgroundColor3=Color3.fromRGB(30,9,15),TextColor3=Theme.Text,PlaceholderColor3=Color3.fromRGB(155,161,180),BorderSizePixel=0}),5)
    Connect(box.FocusLost,function() Configs[key]=box.Text:match("^%s*(.-)%s*$") end)
end
local Overview=Page("Início","Alvos carregados, atividade e resultado das interações.")
local FarmTab=Page("Farm normal","Escolha o alvo, a arma e a posição de ataque.")
local ChestTab=Page("Coletas","Baús, ovos e recursos com tentativas limitadas.")
local RidingTab=Page("Riding","Corrida com cancelamento e controle de velocidade.")
local EspTab=Page("ESP","Marcadores por categoria, vida e distância.")
local PlayerTab=Page("Jogador","Movimento, voo e ajustes do personagem.")
local summary=Card(Overview,86)
Text(summary,"ALVOS CARREGADOS",10,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,18),Theme.Accent)
local counts=Text(summary,"Mobs 0   •   Baús 0   •   Ovos 0   •   Recursos 0",11,UDim2.fromOffset(14,36),UDim2.new(1,-28,0,25))
local targetCard=Card(Overview,99)
Text(targetCard,"ALVO ATUAL",10,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,18),Theme.Accent)
local targetLabel=Text(targetCard,"Nenhum",16,UDim2.fromOffset(14,33),UDim2.new(1,-28,0,25))
local targetDetail=Text(targetCard,"Aguardando um modo de farm",11,UDim2.fromOffset(14,65),UDim2.new(1,-28,0,20),Color3.fromRGB(156,161,177))
local logCard=Card(Overview,124)
Text(logCard,"ATIVIDADE RECENTE",10,UDim2.fromOffset(14,8),UDim2.new(1,-28,0,20),Theme.Accent)
local logLabel=Text(logCard,"",11,UDim2.fromOffset(14,32),UDim2.new(1,-28,0,85),Color3.fromRGB(156,161,177))
logLabel.TextYAlignment=Enum.TextYAlignment.Top; logLabel.TextWrapped=true
local LogLines, lastMessage={},nil
local function Status(message)
    status.Text=message
    if message~=lastMessage then
        lastMessage=message; table.insert(LogLines,1,message)
        while #LogLines>4 do table.remove(LogLines) end
        logLabel.Text=table.concat(LogLines,"\n")
    end
end
local function SetTarget(object,detail)
    Session.Target=object
    targetLabel.Text=object and object.Name or "Nenhum"
    targetDetail.Text=detail or "Aguardando um modo de farm"
end
Toggle(FarmTab,"Farm de mobs","Mantém o alvo até morrer ou ficar sem progresso.","AutoFarm")
Input(FarmTab,"Filtrar nome do mob","MobFilter","Vazio = todos os mobs reconhecidos")
Choice(FarmTab,"Prioridade","MobPriority",{"Mais próximo","Menor vida"})
Choice(FarmTab,"Posição de ataque","FarmPosition",{"Acima","Atrás"})
Choice(FarmTab,"Tipo de ataque","AttackMode",{"Ferramenta","Clique"})
Toggle(FarmTab,"Equipar automaticamente","Usa a primeira ferramenta disponível na mochila.","AutoEquip")
Input(FarmTab,"Ferramenta preferida","ToolName","Nome exato; vazio = equipada / primeira disponível")
Slider(FarmTab,"Distância do alvo","FarmDistance",3,35)
Slider(FarmTab,"Raio de busca","FarmRadius",100,3000)
Slider(FarmTab,"Intervalo do ataque (ms)","AttackInterval",100,1500)
Slider(FarmTab,"Trocar se não causar dano (s)","StallTimeout",5,40)
Toggle(ChestTab,"Farm de baús","Vai ao mais próximo; espera resposta e tenta novamente.","AutoChest")
Toggle(ChestTab,"Coletar ovos","Interage e aguarda o minigame de coleta.","AutoEgg")
Toggle(ChestTab,"Coletar recursos","Procura pontos de coleta identificados no mapa.","AutoCollect")
Slider(ChestTab,"Tentativas por alvo","CollectRetries",1,5)
Slider(ChestTab,"Espera por resposta (s)","CollectWait",2,10)
Slider(ChestTab,"Intervalo após falha (s)","RetryCooldown",5,90)
Slider(ChestTab,"Velocidade de deslocamento","TravelSpeed",30,250)
Toggle(RidingTab,"Auto Riding","Monte no dragão e inicie a corrida.","AutoRiding")
Toggle(RidingTab,"Iniciar corrida perto","Aciona prompts de corrida dentro do alcance.","AutoStartRace")
Slider(RidingTab,"Velocidade do dragão","TweenSpeed",50,400)
Slider(RidingTab,"Raio dos anéis","SearchRadius",100,3000)
Toggle(EspTab,"Mobs","Nome, distância e barra de vida.","EspMobs")
Toggle(EspTab,"Baús","Contorno azul e estado da interação.","EspChests")
Toggle(EspTab,"Ovos","Marcadores dourados, mesmo sem prompt ativo.","EspEggs")
Toggle(EspTab,"Recursos","Identificação dos pontos de coleta.","EspResources")
Toggle(EspTab,"Ver através das paredes","Desligue para respeitar a oclusão.","EspThroughWalls")
Toggle(EspTab,"Contorno dos objetos","Desligue para mostrar somente as etiquetas.","EspHighlight")
Slider(EspTab,"Distância máxima","EspDistance",100,4000)
Slider(EspTab,"Máximo de marcadores","EspLimit",5,60)
Toggle(PlayerTab,"Voo (G)","WASD · Espaço sobe · Ctrl desce.","Fly")
Toggle(PlayerTab,"Aplicar velocidade e pulo","Restaura os valores ao desligar.","PlayerMods")
Toggle(PlayerTab,"Anti AFK","Mantém a rotina anti-inatividade ativa.","AntiAFK")
Slider(PlayerTab,"Velocidade do voo","FlySpeed",20,200)
Slider(PlayerTab,"Velocidade ao andar","WalkSpeed",16,150)
Slider(PlayerTab,"Força do pulo","JumpPower",50,200)
Pages[1].Page.Visible=true; Pages[1].Button.BackgroundColor3=Color3.fromRGB(95,10,25)
local reopen=Button(ScreenGui,"PUDIM",UDim2.new(0,12,0.5,-20),UDim2.fromOffset(72,40),function() MainFrame.Visible=not MainFrame.Visible end)
local drag, dragStart, panelStart
Connect(TopBar.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag=input; dragStart=input.Position; panelStart=MainFrame.Position end
end)
Connect(UserInputService.InputEnded,function(input) if input==drag then drag=nil end end)
Connect(UserInputService.InputChanged,function(input)
    if drag and (input==drag or input.UserInputType==Enum.UserInputType.MouseMovement) then
        local delta=input.Position-dragStart
        local camera=Workspace.CurrentCamera
        if camera then
            local view=camera.ViewportSize; local half=300*scale.Scale
            local x=panelStart.X.Scale*view.X+panelStart.X.Offset+delta.X
            local y=panelStart.Y.Scale*view.Y+panelStart.Y.Offset+delta.Y
            MainFrame.Position=UDim2.fromOffset(math.clamp(x,half,math.max(half,view.X-half)),math.clamp(y,half,math.max(half,view.Y-half-36)))
        end
    end
end)
local function Resize()
    local camera=Workspace.CurrentCamera
    if camera then scale.Scale=math.clamp(math.min((camera.ViewportSize.X-24)/600,(camera.ViewportSize.Y-60)/600),0.25,1) end
end

local cooldown = setmetatable({}, {__mode = "k"})
local failures = setmetatable({}, {__mode = "k"})
local candidates, VisualTargets = {}, {}
local Attempts, ObservedChanges = 0, 0
local function Index(object)
    local n=object.Name:lower()
    local named=n:find("egg",1,true) or n:find("chest",1,true) or n:find("treasure",1,true) or n:find("resource",1,true) or n:find("fruit",1,true) or n:find("food",1,true)
    if object:IsA("Model") or object:IsA("ProximityPrompt") or (object:IsA("BasePart") and named) then candidates[object] = true end
end
for _, object in ipairs(Workspace:GetDescendants()) do Index(object) end
Connect(Workspace.DescendantAdded, Index)
Connect(Workspace.DescendantRemoving, function(object) candidates[object] = nil end)
local function Excluded(object)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and (object == player.Character or object:IsDescendantOf(player.Character)) then return true end
    end
    local node=object
    while node and node~=Workspace do
        local n=node.Name:lower()
        if n=="dragons" or n=="playerdragons" or n=="pets" or n=="npcs" then return true end
        if node:GetAttribute("Owner") or node:GetAttribute("OwnerId") or node:GetAttribute("OwnerUserId") then return true end
        node=node.Parent
    end
    return false
end
local function NameTag(name)
    name=name:lower()
    if name:find("egg",1,true) then return "Egg" end
    if name:find("chest",1,true) or name:find("treasure",1,true) then return "Chest" end
    if name:find("resource",1,true) or name:find("harvest",1,true) or name:find("food",1,true) or name:find("fruit",1,true) then return "Res" end
end
local function Classify(object)
    local node=object
    for _=1,5 do
        if not node or node==Workspace then break end
        local tag=NameTag(node.Name)
        if tag then return tag end
        node=node.Parent
    end
    if object:IsA("ProximityPrompt") then return NameTag(object.ObjectText .. " " .. object.ActionText) end
end
local function Canonical(object)
    local node=object:IsA("ProximityPrompt") and object.Parent or object
    local model=node:IsA("Model") and node or node:FindFirstAncestorWhichIsA("Model")
    if model and Part(model) then return model end
    return Part(node)
end
local function IsMob(object)
    if not object:IsA("Model") or Excluded(object) then return false end
    local h=object:FindFirstChildWhichIsA("Humanoid")
    if not h or h.Health<=0 or not Part(object) then return false end
    local node=object
    while node and node~=Workspace do
        local n=node.Name:lower()
        if n:find("mob",1,true) or n:find("enem",1,true) or n:find("monster",1,true) then return true end
        node=node.Parent
    end
    return object:GetAttribute("Hostile")==true or object:GetAttribute("IsEnemy")==true
end
local colors={Mob=Color3.fromRGB(255,102,116),Egg=Color3.fromRGB(255,209,95),Chest=Color3.fromRGB(91,184,255),Res=Color3.fromRGB(0,255,128)}
local flags={Mob="EspMobs",Egg="EspEggs",Chest="EspChests",Res="EspResources"}
local names={Mob="MOB",Egg="OVO",Chest="BAÚ",Res="RECURSO"}
local function RemoveESP(object)
    local d=ESP_Storage[object]
    if d then d.Billboard:Destroy(); d.Highlight:Destroy(); ESP_Storage[object]=nil end
end
local function Scan()
    Cache={Mobs={},Eggs={},Resources={},Chests={},Races={}}
    VisualTargets={}
    local promptSeen={}
    for object in pairs(candidates) do
        if object.Parent and not Excluded(object) then
            if object:IsA("Model") and IsMob(object) then
                table.insert(Cache.Mobs,object); VisualTargets[object]={Tag="Mob"}
            elseif object:IsA("ProximityPrompt") then
                local tag=Classify(object)
                local owner=Canonical(object)
                if tag and owner then
                    local visual=VisualTargets[owner]
                    if not visual or not visual.Prompt or object.Enabled then VisualTargets[owner]={Tag=tag,Prompt=object} end
                    local list=tag=="Egg" and Cache.Eggs or tag=="Chest" and Cache.Chests or Cache.Resources
                    if object.Enabled and not promptSeen[owner] then table.insert(list,object); promptSeen[owner]=true end
                end
                local description=(object.ObjectText .. " " .. object.ActionText):lower()
                if object.Enabled and (description:find("race",1,true) or description:find("corrida",1,true)) then table.insert(Cache.Races,object) end
            elseif NameTag(object.Name) then
                local owner=Canonical(object)
                if owner and not VisualTargets[owner] then VisualTargets[owner]={Tag=Classify(object)} end
            end
        end
    end
    counts.Text=string.format("Mobs %d   •   Baús %d   •   Ovos %d   •   Recursos %d",#Cache.Mobs,#Cache.Chests,#Cache.Eggs,#Cache.Resources)
    substatus.Text=string.format("Interações enviadas: %d   •   Alvos que mudaram após interação: %d",Attempts,ObservedChanges)
end
local function UpdateVisuals()
    local root=GetRoot()
    if not root then for object in pairs(ESP_Storage) do RemoveESP(object) end; return end
    local sorted={}
    for object,info in pairs(VisualTargets) do
        local part=Part(object)
        if part and Configs[flags[info.Tag]] then
            local distance=(root.Position-part.Position).Magnitude
            if distance<=Configs.EspDistance then table.insert(sorted,{Object=object,Info=info,Part=part,Distance=distance}) end
        end
    end
    table.sort(sorted,function(a,b) return a.Distance<b.Distance end)
    local visible={}
    for index=1,math.min(#sorted,Configs.EspLimit) do
        local item=sorted[index]; local object,info=item.Object,item.Info
        visible[object]=true
        local d=ESP_Storage[object]
        if not d then
            local hl=New("Highlight",ScreenGui,{Adornee=object,FillTransparency=0.82,OutlineTransparency=0.15})
            local bill=New("BillboardGui",ScreenGui,{Adornee=item.Part,Size=UDim2.fromOffset(185,54),StudsOffsetWorldSpace=Vector3.new(0,3,0),MaxDistance=Configs.EspDistance})
            local bg=Round(New("Frame",bill,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(12,20,28),BackgroundTransparency=0.15,BorderSizePixel=0}),7)
            local label=Text(bg,"",11,UDim2.fromOffset(7,4),UDim2.new(1,-14,0,19))
            local detail=Text(bg,"",10,UDim2.fromOffset(7,24),UDim2.new(1,-14,0,17))
            local track=New("Frame",bg,{Position=UDim2.new(0,7,1,-6),Size=UDim2.new(1,-14,0,3),BackgroundTransparency=1})
            local health=New("Frame",track,{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.Mob,BorderSizePixel=0})
            d={Highlight=hl,Billboard=bill,Text=label,Detail=detail,Health=health}; ESP_Storage[object]=d
        end
        local selected=Session.Target==object or (Session.Target and Canonical(Session.Target)==object)
        d.Highlight.Enabled=Configs.EspHighlight and index<=30
        d.Highlight.FillColor=colors[info.Tag]; d.Highlight.OutlineColor=selected and Color3.new(1,1,1) or colors[info.Tag]
        d.Highlight.DepthMode=Configs.EspThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        d.Billboard.AlwaysOnTop=Configs.EspThroughWalls; d.Billboard.MaxDistance=Configs.EspDistance
        d.Text.Text=(selected and "> " or "") .. names[info.Tag] .. " · " .. object.Name; d.Text.TextColor3=colors[info.Tag]
        local h=object:FindFirstChildWhichIsA("Humanoid")
        local state=""
        if h then state=string.format(" · %d/%d HP",math.ceil(h.Health),math.ceil(h.MaxHealth))
        elseif info.Prompt then state=info.Prompt.Enabled and " · interativo" or " · indisponível"
        else state=" · sem prompt" end
        d.Detail.Text=string.format("%d studs%s",item.Distance,state)
        d.Health.Visible=h~=nil
        if h then d.Health.Size=UDim2.fromScale(math.clamp(h.Health/math.max(h.MaxHealth,1),0,1),1) end
    end
    for object in pairs(ESP_Storage) do if not visible[object] then RemoveESP(object) end end
end

local function Nearest(objects, origin, maxDistance)
    local best, distance = nil, maxDistance or math.huge
    for _, object in ipairs(objects) do
        if object.Parent and (cooldown[object] or 0) <= os.clock() then
            local part = object:IsA("ProximityPrompt") and Part(object.Parent) or Part(object)
            if part then
                local d = (origin - part.Position).Magnitude
                if d < distance then best, distance = object, d end
            end
        end
    end
    return best, distance
end
local function Move(part, target, speed, key, valid, tolerance)
    CancelMove()
    local revision = Session.Revision
    local duration = math.max(0.1, (part.Position - target.Position).Magnitude / speed)
    local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = target})
    Session.Tween = tween; tween:Play()
    local deadline = os.clock() + math.min(duration + 2, 20)
    local arrived = false
    repeat
        task.wait(0.05)
        if not Session.Alive or revision ~= Session.Revision or not Configs[key] or not part.Parent or (valid and not valid()) then break end
        if (part.Position - target.Position).Magnitude < (tolerance or 4) then arrived = true; break end
    until os.clock() >= deadline or tween.PlaybackState == Enum.PlaybackState.Completed or tween.PlaybackState == Enum.PlaybackState.Cancelled
    tween:Cancel()
    if Session.Tween == tween then Session.Tween = nil end
    return arrived and Session.Alive and revision == Session.Revision and Configs[key]
end
local function Prompt(prompt)
    local root, part = GetMoverPart(), Part(prompt.Parent)
    if not prompt.Enabled or not root or not part or (root.Position - part.Position).Magnitude > prompt.MaxActivationDistance + 2 then return false end
    if type(fireproximityprompt) ~= "function" then Status("Executor sem fireproximityprompt; interaja manualmente"); return false end
    local ok, err = pcall(fireproximityprompt, prompt, prompt.HoldDuration)
    if not ok then Status("Falha na interação: " .. tostring(err)) end
    return ok
end
-- Só botões específicos de uma interface de coleta/minigame reconhecida.
-- Nunca dispara confirm/yes nem todos os botões da tela.
local function CollectionUI()
    if type(getconnections) ~= "function" then return end
    local gui = Player:FindFirstChild("PlayerGui")
    if not gui then return end
    for _, button in ipairs(gui:GetDescendants()) do
        if button:IsA("GuiButton") and not button:IsDescendantOf(ScreenGui) and button.Visible and button.Active then
            local name = button.Name:lower()
            if name == "target" or name == "claim" or name == "collect" then
                local node, visible, scope = button.Parent, true, false
                while node and node ~= gui do
                    if node:IsA("GuiObject") and not node.Visible then visible = false end
                    if node:IsA("ScreenGui") and not node.Enabled then visible = false end
                    local n = node.Name:lower()
                    if n == "eggminigame" or n == "eggcollection" or n == "chestreward" then scope = true end
                    node = node.Parent
                end
                if visible and scope then
                    local ok, connections = pcall(getconnections, button.Activated)
                    if ok and #connections == 0 then ok, connections = pcall(getconnections, button.MouseButton1Click) end
                    if ok then for _, connection in ipairs(connections) do pcall(function() connection:Fire() end) end end
                    return
                end
            end
        end
    end
end
local function Collect(key,list)
    local root=GetRoot()
    if not root then Status("Aguardando personagem"); return end
    local prompt=Nearest(list,root.Position,Configs.FarmRadius)
    if not prompt then SetTarget(nil); Status("Sem coleta disponível no raio; aguardando"); return end
    local part=Part(prompt.Parent)
    if not part then return end
    local owner=Canonical(prompt)
    SetTarget(owner,"Indo até o ponto de interação")
    Status("Deslocando até " .. (owner and owner.Name or prompt.Parent.Name))
    local reach=math.max(0.5,math.min(2,prompt.MaxActivationDistance*0.4))
    local arrived=Move(GetMoverPart() or root,part.CFrame*CFrame.new(0,reach,0),Configs.TravelSpeed,key,function()
        return prompt:IsDescendantOf(Workspace) and prompt.Enabled
    end, math.max(0.25,math.min(1,prompt.MaxActivationDistance*0.2)))
    if not arrived then cooldown[prompt]=os.clock()+Configs.RetryCooldown; return end
    local revision=Session.Revision
    for attempt=1,Configs.CollectRetries do
        if not Session.Alive or Session.Revision~=revision or not Configs[key] then return end
        if not prompt:IsDescendantOf(Workspace) or not prompt.Enabled then break end
        Status(string.format("Interagindo: tentativa %d/%d",attempt,Configs.CollectRetries))
        if not Prompt(prompt) then break end
        Attempts+=1
        local deadline=os.clock()+Configs.CollectWait
        repeat
            task.wait(0.15)
            if not Session.Alive or Session.Revision~=revision or not Configs[key] then return end
            if not prompt:IsDescendantOf(Workspace) or not prompt.Enabled then
                ObservedChanges+=1; failures[prompt]=nil; cooldown[prompt]=os.clock()+15
                Status("Alvo mudou após interação; seguindo para o próximo")
                SetTarget(nil); return
            end
            CollectionUI()
        until os.clock()>=deadline
    end
    failures[prompt]=(failures[prompt] or 0)+1
    cooldown[prompt]=os.clock()+math.min(Configs.RetryCooldown*failures[prompt],180)
    Status("Sem confirmação da coleta; alvo em espera")
    SetTarget(nil)
end

local function Riding()
    local h, mover = GetHumanoid(), GetMoverPart()
    if not h or not h.SeatPart or not mover then Status("Monte no dragão para usar Riding"); return end
    if Configs.AutoStartRace then
        local prompt = Nearest(Cache.Races or {}, mover.Position, 15)
        if prompt then cooldown[prompt] = os.clock() + 10; Prompt(prompt) end
    end
    local interactions = Workspace:FindFirstChild("Interactions")
    local rings = interactions and interactions:FindFirstChild("RidingRings")
    rings = rings and rings:FindFirstChild("CreatedRings")
    if not rings then Status("Aguardando anéis da corrida"); return end
    local active = {}
    for _, ring in ipairs(rings:GetChildren()) do
        if ring:IsA("BasePart") and tonumber(ring.Name) and ring.Size.Magnitude > Configs.MinSize and ring.Transparency < Configs.MaxTransparency then table.insert(active, ring) end
    end
    local ring = Nearest(active, mover.Position, Configs.SearchRadius)
    if not ring then Status("Nenhum anel ativo no alcance"); return end
    SetTarget(ring,"Atravessando anel da corrida")
    Status("Riding: anel " .. ring.Name)
    Move(mover, ring.CFrame, Configs.TweenSpeed, "AutoRiding", function()
        return ring:IsDescendantOf(Workspace) and ring.Transparency < Configs.MaxTransparency and GetMoverPart() == mover and h.SeatPart ~= nil
    end)
    cooldown[ring] = os.clock() + Configs.IgnoreTime
end
local farmTarget, lastHealth, lastDamage, lastAttack, approachFailures
local function PickMob(root)
    local best,bestScore
    for _,mob in ipairs(Cache.Mobs) do
        if IsMob(mob) and (cooldown[mob] or 0)<=os.clock() and (Configs.MobFilter=="" or mob.Name:lower():find(Configs.MobFilter:lower(),1,true)) then
            local distance=(root.Position-Part(mob).Position).Magnitude
            local h=mob:FindFirstChildWhichIsA("Humanoid")
            if distance<=Configs.FarmRadius then
                local score=Configs.MobPriority=="Menor vida" and h.Health or distance
                if not bestScore or score<bestScore then best,bestScore=mob,score end
            end
        end
    end
    return best
end
local function Farm()
    local root,h=GetRoot(),GetHumanoid()
    if not root or not h or h.Health<=0 then farmTarget=nil; Status("Aguardando respawn"); return end
    if farmTarget and (not IsMob(farmTarget) or (root.Position-Part(farmTarget).Position).Magnitude>Configs.FarmRadius or (Configs.MobFilter~="" and not farmTarget.Name:lower():find(Configs.MobFilter:lower(),1,true))) then farmTarget=nil end
    if not farmTarget then
        farmTarget=PickMob(root)
        if not farmTarget then SetTarget(nil); Status("Nenhum mob reconhecido no raio"); return end
        lastHealth=farmTarget:FindFirstChildWhichIsA("Humanoid").Health
        lastDamage=os.clock(); approachFailures=0
    end
    local mob=farmTarget
    local enemy=mob:FindFirstChildWhichIsA("Humanoid")
    local part=Part(mob)
    SetTarget(mob,string.format("Vida: %d/%d · %s",math.ceil(enemy.Health),math.ceil(enemy.MaxHealth),Configs.FarmPosition))
    if enemy.Health<lastHealth then lastDamage=os.clock() end
    lastHealth=enemy.Health
    local position=Configs.FarmPosition=="Atrás" and (part.CFrame*CFrame.new(0,1,Configs.FarmDistance)).Position or part.Position+Vector3.new(0,Configs.FarmDistance,0)
    local destination=CFrame.new(position,part.Position)
    local mover=GetMoverPart() or root
    if (mover.Position-position).Magnitude>12 then
        Status("Aproximando de " .. mob.Name)
        local arrived=Move(mover,destination,Configs.TravelSpeed,"AutoFarm",function() return IsMob(mob) end)
        lastDamage=os.clock()
        if not arrived then
            approachFailures+=1
            if approachFailures>=2 then cooldown[mob]=os.clock()+Configs.RetryCooldown; farmTarget=nil; Status("Alvo inacessível; buscando outro") end
        end
        return
    end
    if os.clock()-lastDamage>=Configs.StallTimeout then
        cooldown[mob]=os.clock()+Configs.RetryCooldown; farmTarget=nil; SetTarget(nil)
        Status("Vida não diminuiu; trocando alvo")
        return
    end
    mover.CFrame=destination; mover.AssemblyLinearVelocity=Vector3.zero
    if os.clock()-(lastAttack or 0)<Configs.AttackInterval/1000 then return end
    lastAttack=os.clock()
    if Configs.AttackMode=="Ferramenta" then
        local tool=Player.Character:FindFirstChildWhichIsA("Tool")
        if Configs.AutoEquip and (not tool or (Configs.ToolName~="" and tool.Name~=Configs.ToolName)) then
            local backpack=Player:FindFirstChildWhichIsA("Backpack")
            local desired=backpack and (Configs.ToolName~="" and backpack:FindFirstChild(Configs.ToolName) or backpack:FindFirstChildWhichIsA("Tool"))
            if desired and desired:IsA("Tool") then h:EquipTool(desired); tool=desired end
        end
        if Configs.ToolName~="" and (not tool or tool.Name~=Configs.ToolName) then Status("Ferramenta escolhida não está equipada / disponível"); return end
        if tool then tool:Activate(); Status("Atacando: " .. mob.Name)
        else Status("Equipe uma ferramenta ou escolha ataque por clique") end
    else
        local camera=Workspace.CurrentCamera
        if camera then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(camera.ViewportSize/2,camera.CFrame)
            Status("Clique de ataque: " .. mob.Name)
        end
    end
end

local flight, originalHumanoid
local function EndFly()
    if not flight then return end
    flight.Velocity:Destroy(); flight.Attachment:Destroy()
    if flight.Humanoid.Parent then flight.Humanoid.PlatformStand = flight.PlatformStand end
    if flight.Root.Parent then flight.Root.AssemblyLinearVelocity = Vector3.zero end
    flight = nil
end
local function RestoreHumanoid()
    if originalHumanoid and originalHumanoid.H.Parent then
        originalHumanoid.H.WalkSpeed = originalHumanoid.Speed
        originalHumanoid.H.JumpPower = originalHumanoid.Power
        originalHumanoid.H.JumpHeight = originalHumanoid.Height
    end
    originalHumanoid = nil
end
local function PlayerUpdate()
    local h, root = GetHumanoid(), GetRoot()
    if originalHumanoid and (not Configs.PlayerMods or originalHumanoid.H ~= h) then RestoreHumanoid() end
    if Configs.PlayerMods and h then
        if not originalHumanoid then originalHumanoid = {H = h, Speed = h.WalkSpeed, Power = h.JumpPower, Height = h.JumpHeight} end
        h.WalkSpeed = Configs.WalkSpeed
        if h.UseJumpPower then h.JumpPower = Configs.JumpPower else h.JumpHeight = Configs.JumpPower ^ 2 / (2 * math.max(Workspace.Gravity, 1)) end
    end
    if flight and (not Configs.Fly or root ~= flight.Root or not h or h.Health <= 0 or h.SeatPart) then EndFly() end
    if not Configs.Fly or not h or h.Health <= 0 or not root or h.SeatPart then return end
    if not flight then
        local attachment = Instance.new("Attachment", root)
        local velocity = Instance.new("LinearVelocity", root)
        velocity.Attachment0 = attachment; velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.MaxForce = math.huge; velocity.VectorVelocity = Vector3.zero
        flight = {Attachment = attachment, Velocity = velocity, Root = root, Humanoid = h, PlatformStand = h.PlatformStand}
        h.PlatformStand = true
    end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local move = h.MoveDirection
    if not UserInputService:GetFocusedTextBox() then
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
    end
    flight.Velocity.VectorVelocity = (move.Magnitude > 1 and move.Unit or move) * Configs.FlySpeed
end
Session.Destroy = function()
    if not Session.Alive then return end
    Session.Alive = false; StopAll(); EndFly(); RestoreHumanoid()
    for _, connection in ipairs(Session.Connections) do connection:Disconnect() end
    table.clear(Session.Connections)
    ScreenGui:Destroy()
    if env.PudimHubDA == Session then env.PudimHubDA = nil end
end
Connect(Player.CharacterRemoving, function() CancelMove(); EndFly(); RestoreHumanoid() end)
Connect(Player.Idled, function()
    if Configs.AntiAFK then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero) end) end
end)
Connect(UserInputService.InputBegan, function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.G then SetConfig("Fly", not Configs.Fly)
    elseif input.KeyCode == Enum.KeyCode.H then MainFrame.Visible = not MainFrame.Visible end
end)
local function Worker(interval, callback)
    task.spawn(function()
        while Session.Alive do
            local ok, err = pcall(callback)
            if not ok and Session.Alive then
                CancelMove(); Status("Erro: " .. tostring(err)); warn("[PudimHub DA] " .. tostring(err))
            end
            task.wait(interval)
        end
    end)
end
Worker(1, function() Scan(); Resize() end)
Worker(0.2, UpdateVisuals)
Worker(0.1, function()
    if Configs.AutoRiding then Riding()
    elseif Configs.AutoEgg then Collect("AutoEgg", Cache.Eggs)
    elseif Configs.AutoChest then Collect("AutoChest", Cache.Chests)
    elseif Configs.AutoCollect then Collect("AutoCollect", Cache.Resources)
    elseif Configs.AutoFarm then Farm()
    else farmTarget=nil; SetTarget(nil); Status(Configs.Fly and "Voo ativo" or "Pronto para iniciar") end
end)
Connect(RunService.Heartbeat, PlayerUpdate)
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "PudimHub DA v018", Text = "H: painel • G: voo • Parar tudo no topo", Duration = 5,
}) end)
