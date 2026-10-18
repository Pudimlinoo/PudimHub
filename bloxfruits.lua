-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Pudimlinoo/Pudimlinoo-script/main/script.lua"))()

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- Nome EXCLUSIVO do seu Hub (Para não confundir com o Tracker)
-- Nome EXCLUSIVO do seu Hub 
local NOME_DO_HUB = "PudimHub_Main_Interface"

-- 1. Remove APENAS o Hub se ele já estiver aberto
-- Remove APENAS o Hub se ele já estiver aberto
if player and player:FindFirstChild("PlayerGui") then
    if player.PlayerGui:FindFirstChild(NOME_DO_HUB) then
        player.PlayerGui[NOME_DO_HUB]:Destroy()
    end
end

if CoreGui:FindFirstChild(NOME_DO_HUB) then
    CoreGui[NOME_DO_HUB]:Destroy()
end

-- ================= SERVIÇOS =================
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
-- Servicos opcionais sao resolvidos somente quando utilizados.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local FILENAME = "BloxFruits_Tracker_Final.json"

-- ================= TEMA REDZ =================
local Theme = {

	Main = Color3.fromRGB(5,5,8),       -- fundo principal
	Second = Color3.fromRGB(13,8,11),     -- fundo interno
	Button = Color3.fromRGB(26,10,15),     -- botão neutro

	Red = Color3.fromRGB(240,30,55),       -- vermelho principal
	DarkRed = Color3.fromRGB(95,10,25),   -- vermelho escuro

	Text = Color3.fromRGB(240,240,240),
	Stroke = Color3.fromRGB(60,60,60)

}
-- Estado de interface e registro dos controles (sem ativar funções ao carregar).
local HUD = {toggles = {}, sliders = {}, jump = 60, scale = 100, status = true, alive = true, connections = {}, collisions = setmetatable({}, {__mode = "k"}), espLoops = {}}
-- Recursos locais: diagnostico, tarefas cancelaveis e preferencias.
HUD.favorites = {}
HUD.keys = {menu="G", players="F", npcs="H", cursor="B"}
HUD.light = true
HUD.watchEvents = false
HUD.errorText = "Nenhum erro registrado."
HUD.storageText = "Preparando preferencias..."
HUD.jobs = {}
function HUD.report(context, detail)
    local message=tostring(context)..": "..tostring(detail):sub(1,220)
    if message~=HUD.errorText or os.clock()-(HUD.errorAt or 0)>5 then
        warn("[PudimHub] "..message)
        HUD.errorAt=os.clock()
    end
    HUD.errorText=message
end
function HUD.setText(label, value)
    if label.Text ~= value then label.Text = value end
end
function HUD.startJob(callback)
    local job
    job = task.defer(function()
        if HUD.alive then
            local ok, err = pcall(callback)
            if not ok then HUD.report("Tarefa",err) end
        end
        HUD.jobs[job] = nil
    end)
    HUD.jobs[job] = true
    return job
end
function HUD.remote(...)
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    local remote = folder and folder:FindFirstChild("CommF_")
    if not remote or not remote:IsA("RemoteFunction") then
        HUD.report("Servico do jogo","CommF_ ainda indisponivel; tente novamente apos carregar.")
        error(HUD.errorText,0)
    end
    local args=table.pack(...)
    local result
    local job=HUD.startJob(function()
        result=table.pack(pcall(function() return remote:InvokeServer(table.unpack(args,1,args.n)) end))
    end)
    local deadline=os.clock()+10
    repeat task.wait(0.05) until result or not HUD.alive or os.clock()>=deadline
    if not result then
        pcall(task.cancel,job); HUD.jobs[job]=nil
        HUD.report("Servico do jogo","Tempo limite de resposta. Uma solicitacao enviada pode ainda ser processada.")
        error(HUD.errorText,0)
    end
    if not result[1] then HUD.report("Servico do jogo",result[2]); error(tostring(result[2]),0) end
    return table.unpack(result,2,result.n)
end
function HUD.activity()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return "PERSONAGEM", "Aguardando personagem vivo" end
    if HUD.seaBusy then return "SEA", "Trocando de mar" end
    if HUD.serverBusy then return "SERVIDOR", "Buscando / trocando servidor" end
    if HUD.travelActive then return "VIAGEM", "Viagem em andamento" end
    if HUD.flying then return "VOO", "Voo ativo" end
    if HUD.safeActive then return "SAFE", "Auto Safe ativo" end
    if os.clock() < HUD.manualHold then return "MANUAL", "Movimento manual" end
    if HUD.farmPaused then return "PAUSA", "Farm pausado; use Retomar farm" end
    return "LIVRE", "Pronto"
end

function HUD.connect(signal, callback)
    local connection = signal:Connect(function(...)
        if HUD.alive then
            local ok,err=pcall(callback,...)
            if not ok then HUD.report("Evento",err) end
        end
    end)
    table.insert(HUD.connections, connection)
    return connection
end
-- ================= GUI =================
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = NOME_DO_HUB -- <--- AQUI: Usa o nome único definido lá em cima
gui.ResetOnSpawn = false
HUD.travelActive = false
HUD.travelSpeed = 250
HUD.farmPaused = false
HUD.farmRadius = 800
HUD.farmFilter = ""
HUD.autoEquip = false
HUD.farmSearchAt = 0
HUD.farmAttackAt = 0
HUD.attackHz = 10
HUD.attackReach = 4
HUD.autoNear = false
HUD.manualFarmHeight = false
HUD.localHitbox = false
HUD.hitboxWidth = 8
HUD.hitboxPart = nil
HUD.hitboxOriginal = nil
function HUD.restoreHitbox()
    local part, saved = HUD.hitboxPart, HUD.hitboxOriginal
    HUD.hitboxPart, HUD.hitboxOriginal = nil, nil
    if part and part.Parent and saved then
        part.Size = saved.size
        part.CanCollide = saved.collide
    end
end
function HUD.applyHitbox(npc)
    local part = npc and npc:FindFirstChild("HumanoidRootPart")
    if not HUD.localHitbox or not part then HUD.restoreHitbox(); return end
    if HUD.hitboxPart ~= part then
        HUD.restoreHitbox()
        HUD.hitboxPart = part
        HUD.hitboxOriginal = {size=part.Size,collide=part.CanCollide}
    end
    local size = HUD.hitboxOriginal.size
    part.Size = Vector3.new(math.max(size.X,HUD.hitboxWidth),size.Y,math.max(size.Z,HUD.hitboxWidth))
    part.CanCollide = false
end
-- Distância à superfície das partes do corpo, sem usar acessórios como hitbox.
function HUD.bodyDistance(npc, position)
    local nearest = math.huge
    for _, part in ipairs(npc:GetChildren()) do
        if part:IsA("BasePart") then
            local size = (part == HUD.hitboxPart and HUD.hitboxOriginal) and HUD.hitboxOriginal.size or part.Size
            local half = size * 0.5
            local localPoint = part.CFrame:PointToObjectSpace(position)
            local outside = Vector3.new(math.max(0,math.abs(localPoint.X)-half.X),math.max(0,math.abs(localPoint.Y)-half.Y),math.max(0,math.abs(localPoint.Z)-half.Z))
            nearest = math.min(nearest,outside.Magnitude)
        end
    end
    return nearest
end
function HUD.isCombatTool(tool)
    return tool and tool:IsA("Tool") and (tool.ToolTip == "Melee" or tool.ToolTip == "Sword")
end
-- Compartilhado pelo farm e ataque proximo; sem inferir autoria do dano.
HUD.weaponName=""
HUD.aimFilter=""
HUD.aimPriority="Tela"
HUD.farmIgnored=setmetatable({}, {__mode="k"})
HUD.progress=nil
HUD.nearTarget=nil
HUD.nearSearchAt=0
HUD.moveAt=0
function HUD.pickWeapon(char,hum,now)
    local equipped=char:FindFirstChildOfClass("Tool")
    local function matches(tool)
        return HUD.isCombatTool(tool) and (HUD.weaponName=="" or tool.Name==HUD.weaponName)
    end
    if matches(equipped) then return equipped end
    if not HUD.autoEquip or now<(HUD.equipAt or 0) then return nil end
    HUD.equipAt=now+1
    local backpack=player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _,tool in ipairs(backpack:GetChildren()) do
            if matches(tool) then
                hum:EquipTool(tool)
                if tool.Parent==char then return tool end
                return nil
            end
        end
    end
    return nil
end
function HUD.observeProgress(npc,now)
    local hum=npc and npc:FindFirstChildOfClass("Humanoid")
    if not hum then HUD.progress=nil; return false end
    local state=HUD.progress
    if not state or state.target~=npc then
        HUD.progress={target=npc,health=hum.Health,at=now,retries=0,lastTry=0}
        return false
    end
    if hum.Health<state.health then state.at=now; state.retries=0 end
    state.health=hum.Health
    if now-state.lastTry>1.5 then state.at=now; return false end
    if now-state.at<8 then return false end
    state.at=now
    state.retries=state.retries+1
    if state.retries==1 then
        HUD.moveAt=0
        return "Reposicionando: vida do alvo sem reducao observada."
    end
    HUD.farmIgnored[npc]=now+15
    HUD.progress=nil
    return "Alvo sem progresso; ignorado por 15 segundos."
end
function HUD.resetCombatExtras()
    HUD.progress=nil; HUD.nearTarget=nil; HUD.moveAt=0; HUD.nearSearchAt=0
    table.clear(HUD.farmIgnored)
end
function HUD.validFarmTarget(npc,root,now,radius)
    local enemies=workspace:FindFirstChild("Enemies")
    if not npc or not enemies or npc.Parent~=enemies then return false end
    local hum=npc:FindFirstChildOfClass("Humanoid")
    local part=npc:FindFirstChild("HumanoidRootPart")
    return hum and part and part:IsA("BasePart") and hum.Health>0
        and (HUD.farmIgnored[npc] or 0)<=now
        and (part.Position-root.Position).Magnitude<=radius
        and (HUD.farmFilter=="" or npc.Name:lower():find(HUD.farmFilter,1,true)~=nil)
end

function HUD.tryAttack(npc, tool, root, now, fast)
    if not HUD.isCombatTool(tool) then return "Equipe uma ferramenta Melee ou Sword." end
    local targetHum = npc and npc:FindFirstChildOfClass("Humanoid")
    if not targetHum or targetHum.Health <= 0 then return "Alvo indisponível." end
    if UserInputService:GetFocusedTextBox() then return "Ataque pausado enquanto você digita." end
    local distance = HUD.bodyDistance(npc,root.Position)
    if distance > HUD.attackReach then return string.format("Fora da distância de ataque / %.1f studs",distance) end
    if not tool.Enabled then return "Aguardando a ferramenta ficar disponível." end
    if now < HUD.farmAttackAt then return "Alvo em alcance / aguardando próximo ataque." end
    HUD.farmAttackAt = now + (fast and 1 / HUD.attackHz or 0.3)
    local ok = pcall(function() tool:Activate() end)
    if not ok then return "A ferramenta não aceitou a ativação." end
    if HUD.progress and HUD.progress.target==npc then HUD.progress.lastTry=now end
    task.delay(0.025,function()
        if HUD.alive and tool.Parent == player.Character and tool.Enabled then
            pcall(function() tool:Deactivate() end)
        end
    end)
    return "Tentando atacar: "..npc.Name.." / "..tool.Name
end
HUD.manualHold = 0
HUD.seaBusy = false
HUD.seaToken = 0
gui.Destroying:Connect(function()
    HUD.alive = false
    for _, connection in ipairs(HUD.connections) do connection:Disconnect() end
    table.clear(HUD.connections)
end)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,460,0,520)
frame.Position = UDim2.new(0.03,0,0.35,0)
frame.BackgroundColor3 = Theme.Main
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke",frame)
stroke.Color = Theme.Red
stroke.Thickness = 1.5
-- ================= HUD V002 =================
local TweenService = game:GetService("TweenService")
local OPEN_SIZE = UDim2.fromOffset(600, 600)
local OPEN_TRANSP = 0.18
frame.Size = OPEN_SIZE
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.BackgroundColor3 = Theme.Main
frame.ClipsDescendants = false
stroke.Color = Theme.Red
stroke.Transparency = 0.25
stroke.Thickness = 1
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local hudScale = Instance.new("UIScale", frame)
local function fitHUD()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local view = cam.ViewportSize
    hudScale.Scale = math.max(0.1, math.min(HUD.scale / 100, (view.X - 24) / 600, (view.Y - 60) / 600))
end
fitHUD()
local viewportConnection
local function bindViewport()
    Camera = workspace.CurrentCamera
    if viewportConnection then viewportConnection:Disconnect() end
    local cam = workspace.CurrentCamera
    if cam then viewportConnection = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitHUD) end
    fitHUD()
end
bindViewport()
local cameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport)
gui.Destroying:Connect(function()
    if viewportConnection then viewportConnection:Disconnect() end
    cameraConnection:Disconnect()
end)

-- sombra
local shadow = Instance.new("ImageLabel", frame)
shadow.AnchorPoint = Vector2.new(0.5,0.5)
shadow.Position = UDim2.new(0.5,0,0.5,0)
shadow.Size = UDim2.new(1,40,1,40)
shadow.Image = "rbxassetid://1316045217"
shadow.ImageTransparency = 0.6
shadow.Visible = false
shadow.BackgroundTransparency = 1
shadow.ZIndex = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,38)
title.BackgroundColor3 = Theme.DarkRed
title.BackgroundTransparency = 0
title.Text = "🍮 PudimLinoo Hub"
title.TextColor3 = Theme.Text
title.Font = Enum.Font.GothamBold
title.TextSize = 20
Instance.new("UICorner", title).CornerRadius = UDim.new(0,16)

-- Cabeçalho e arraste com mouse/toque
title.Size = UDim2.new(1, 0, 0, 64)
title.BackgroundColor3 = Theme.Second
title.BackgroundTransparency = 0.15
title.Text = "  🍮 PUDIMHUB"
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 19
local subtitle = Instance.new("TextLabel", frame)
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(1, -150, 0, 20)
subtitle.Size = UDim2.fromOffset(130, 24)
subtitle.Text = "V033  /  BLOX FRUITS"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.fromRGB(156, 161, 177)
local dragging, dragStart, startPos, dragTouch
title.Active = true
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, frame.Position
        dragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
    end
end)
local dragChanged = HUD.connect(UserInputService.InputChanged, function(input)
    if dragging and (input == dragTouch or (not dragTouch and input.UserInputType == Enum.UserInputType.MouseMovement)) then
        local delta = input.Position - dragStart
        local cam = workspace.CurrentCamera
        if not cam then return end
        local view = cam.ViewportSize
        local half = Vector2.new(300, 300) * hudScale.Scale
        local x = startPos.X.Scale * view.X + startPos.X.Offset + delta.X
        local y = startPos.Y.Scale * view.Y + startPos.Y.Offset + delta.Y
        x = math.clamp(x, half.X, math.max(half.X, view.X - half.X))
        y = math.clamp(y, half.Y, math.max(half.Y, view.Y - half.Y - 36))
        frame.Position = UDim2.fromOffset(x, y)
    end
end)
local dragEnded = HUD.connect(UserInputService.InputEnded, function(input)
    if input == dragTouch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragTouch = false, nil
    end
end)
gui.Destroying:Connect(function() dragChanged:Disconnect(); dragEnded:Disconnect() end)

-- Navegação com rolagem independente
local sidebar = Instance.new("ScrollingFrame", frame)
sidebar.Size = UDim2.new(0, 132, 1, -124)
sidebar.Position = UDim2.fromOffset(12, 76)
sidebar.BackgroundTransparency = 1
sidebar.BorderSizePixel = 0
sidebar.CanvasSize = UDim2.new()
sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebar.ScrollBarThickness = 2
sidebar.ScrollBarImageColor3 = Theme.Red
sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0, 8)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
local container = Instance.new("Frame", frame)
container.Size = UDim2.new(1, -166, 1, -170)
container.Position = UDim2.fromOffset(154, 122)
container.BackgroundTransparency = 1
local tabs, tabButtons = {}, {}
local currentTab
local function createTab(name)
    task.wait()
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -6, 0, 42)
    btn.LayoutOrder = #tabs + 1
    btn.BackgroundColor3 = Theme.Second
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ({["INÍCIO"]="Início",PLAYER="Player",["Auto-Farm"]="Auto Farm",TELEPORT="Teleporte",AIMBOT="Aimbot",SISTEMA="Sistema",AJUSTES="Ajustes"})[name] or name
    btn.Font = Enum.Font.GothamMedium
    btn.TextColor3 = Color3.fromRGB(155, 161, 180)
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local page = Instance.new("ScrollingFrame", container)
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new()
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Theme.Red
    page.ScrollBarImageTransparency = 0.25
    page.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    page.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    page.Visible = false
    local padding = Instance.new("UIPadding", page)
    padding.PaddingTop = UDim.new(0, 2)
    padding.PaddingBottom = UDim.new(0, 16)
    padding.PaddingLeft = UDim.new(0, 2)
    padding.PaddingRight = UDim.new(0, 8)
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    local nextOrder = 0
    page.ChildAdded:Connect(function(child)
        if child:IsA("GuiObject") then
            nextOrder += 1
            child.LayoutOrder = nextOrder
        end
    end)
    table.insert(tabs, page)
    tabButtons[page] = btn
    local function selectTab()
        for _, other in ipairs(tabs) do
            other.Visible = other == page
            TweenService:Create(tabButtons[other], TweenInfo.new(0.15), {
                BackgroundColor3 = other == page and Theme.DarkRed or Theme.Second,
                TextColor3 = other == page and Theme.Text or Color3.fromRGB(155,161,180)
            }):Play()
        end
        currentTab = page
    end
    btn.Activated:Connect(selectTab)
    if not currentTab then selectTab() end
    return page
end

local tabOverview = createTab("INÍCIO")
local tabPlayer = createTab("PLAYER")
local tabFarm = createTab("Auto-Farm")
local tabESP = createTab("ESP")
local tabTeleport = createTab("TELEPORT")
local tabAimbot = createTab("AIMBOT")
local tabSistema = createTab("SISTEMA")
local tabSettings = createTab("AJUSTES")


-- ================= UI HELPERS =================
local function roundUI(object, radius)
    Instance.new("UICorner", object).CornerRadius = UDim.new(0, radius or 8)
end
local function criarSecao(txt, y, p)
    local label = Instance.new("TextLabel", p)
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = txt
    label.TextColor3 = Color3.fromRGB(237, 116, 127)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
end
local function criarBotaoToggle(txt, y, p, cb)
    local row = Instance.new("TextButton", p)
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = Theme.Second
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    roundUI(row)
    local label = Instance.new("TextLabel", row)
    label.Position = UDim2.fromOffset(12, 0)
    label.Size = UDim2.new(1, -76, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = txt
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    local toggle = Instance.new("Frame", row)
    toggle.Size = UDim2.fromOffset(40, 22)
    toggle.Position = UDim2.new(1, -52, 0.5, -11)
    toggle.BackgroundColor3 = Color3.fromRGB(55,18,25)
    roundUI(toggle, 11)
    local circle = Instance.new("Frame", toggle)
    circle.Size = UDim2.fromOffset(16, 16)
    circle.Position = UDim2.fromOffset(3, 3)
    circle.BackgroundColor3 = Theme.Text
    roundUI(circle, 8)
    local state = false
    local colorTween, positionTween
    local function setState(value, immediate)
        state = value == true
        if colorTween then colorTween:Cancel() end
        if positionTween then positionTween:Cancel() end
        local color = state and Theme.Red or Color3.fromRGB(55,18,25)
        local position = UDim2.fromOffset(state and 21 or 3, 3)
        if immediate then
            toggle.BackgroundColor3 = color
            circle.Position = position
        else
            colorTween = TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = color})
            positionTween = TweenService:Create(circle, TweenInfo.new(0.15), {Position = position})
            colorTween:Play()
            positionTween:Play()
        end
        cb(state)
        if HUD.preferencesChanged then HUD.preferencesChanged() end
    end
    table.insert(HUD.toggles, {key = p.Name.."/"..txt, set = setState, get = function() return state end, default = false})
    row.Activated:Connect(function() setState(not state, false) end)
end

local function criarSlider(txt, min, max, init, y, p, cb)
    task.wait()
    -- Um único cartão por slider: título, valor e barra rolam juntos.
    local row = Instance.new("Frame", p)
    row.Size = UDim2.new(1, 0, 0, 82)
    row.BackgroundColor3 = Theme.Second
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel = 0
    roundUI(row)
    local label = Instance.new("TextLabel", row)
    label.Position = UDim2.fromOffset(12, 10)
    label.Size = UDim2.new(1, -88, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = txt
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextColor3 = Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    local valueBox = Instance.new("TextBox", row)
    valueBox.Size = UDim2.fromOffset(58, 26)
    valueBox.Position = UDim2.new(1, -70, 0, 8)
    valueBox.BackgroundColor3 = Color3.fromRGB(30, 9, 15)
    valueBox.TextColor3 = Theme.Text
    valueBox.Font = Enum.Font.GothamBold
    valueBox.TextSize = 12
    valueBox.ClearTextOnFocus = false
    roundUI(valueBox, 6)
    local hit = Instance.new("TextButton", row)
    hit.Position = UDim2.fromOffset(16, 38)
    hit.Size = UDim2.new(1, -32, 0, 36)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    local bar = Instance.new("Frame", hit)
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0.5, -3)
    bar.BackgroundColor3 = Color3.fromRGB(59, 14, 24)
    roundUI(bar, 3)
    local fill = Instance.new("Frame", bar)
    fill.BackgroundColor3 = Theme.Red
    fill.BorderSizePixel = 0
    roundUI(fill, 3)
    local knob = Instance.new("Frame", bar)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(16, 16)
    knob.BackgroundColor3 = Theme.Text
    roundUI(knob, 8)
    local value, activeInput, scrollWasEnabled
    local function setValue(newValue)
        if newValue ~= newValue then return end
        newValue = math.clamp(math.floor(newValue + 0.5), min, max)
        local ratio = (newValue - min) / (max - min)
        fill.Size = UDim2.fromScale(ratio, 1)
        knob.Position = UDim2.fromScale(ratio, 0.5)
        valueBox.Text = tostring(newValue)
        if value ~= newValue then value = newValue; cb(value); if HUD.preferencesChanged then HUD.preferencesChanged() end end
    end
    local function fromPosition(position)
        if bar.AbsoluteSize.X <= 0 then return end
        setValue(min + math.clamp((position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1) * (max - min))
    end
    local function stopDrag()
        if not activeInput then return end
        activeInput = nil
        p.ScrollingEnabled = scrollWasEnabled
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if activeInput then return end
            activeInput = input
            scrollWasEnabled = p.ScrollingEnabled
            p.ScrollingEnabled = false
            fromPosition(input.Position)
        end
    end)
    local moveConnection = HUD.connect(UserInputService.InputChanged, function(input)
        if activeInput and (input == activeInput or (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
            fromPosition(input.Position)
        end
    end)
    local endConnection = HUD.connect(UserInputService.InputEnded, function(input)
        if input == activeInput or (activeInput and activeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then stopDrag() end
    end)
    local focusConnection = HUD.connect(UserInputService.WindowFocusReleased, stopDrag)
    p:GetPropertyChangedSignal("Visible"):Connect(function() if not p.Visible then stopDrag() end end)
    valueBox.FocusLost:Connect(function() setValue(tonumber(valueBox.Text) or value) end)
    row.Destroying:Connect(function()
        stopDrag()
        moveConnection:Disconnect()
        endConnection:Disconnect()
        focusConnection:Disconnect()
    end)
    local key = p.Name .. "/" .. txt
    HUD.sliders[key] = {set = setValue, get = function() return value end, default = init, min = min, max = max}
    setValue(init)
end
-- ================= VARIÁVEIS =================
local noclip = false
local floorEnabled = false
local floor
local tpSpeed = 0
local altPressed = false
-- ESP
local espOnlyEnemies = false
local espObjects = {}
local boatTransparencyEnabled = false
local BOAT_TRANSPARENCY = 0.6
local ESPAtivo = false
-- ESP FRUTAS
local fruitESPEnabled = false
local fruitEspObjects = {}
-- auto safe
local autoSafeEnabled = false
local autoSafePercent = 30 -- 30% da sua vida máxima
local autoSafeHeight = 10000
local emFuga = false
-- ================= AUTO FARM VARIÁVEIS =================

local autoFarmEnabled = false
local farmHeight = 15
local farmDistance = 4
local farmTarget = nil
local attacking = false
local fastAttackSpeed = 0.02

local fastAttackEnabled = false

-- ================= AUTO FARM MENU =================
criarSecao("AUTO FARM NPC",0,tabFarm)

criarBotaoToggle("Auto Farm",30,tabFarm,function(v)
	autoFarmEnabled = v
	farmTarget = nil
    HUD.farmPaused = false
    HUD.resetCombatExtras()
    HUD.farmSearchAt = 0
end)

criarBotaoToggle("Fast Attack",70,tabFarm,function(v)
	fastAttackEnabled = v
end)



criarSlider("ALTURA FARM",5,30,farmHeight,150,tabFarm,function(v)
	farmHeight = v
end)

criarSlider("DISTÂNCIA NPC",2,10,farmDistance,190,tabFarm,function(v)
	farmDistance = v
end)

criarSlider("RAIO DE BUSCA NPC",100,3000,800,0,tabFarm,function(v) HUD.farmRadius = v end)
criarBotaoToggle("Equipar Melee / Espada",0,tabFarm,function(v) HUD.autoEquip = v end)
do
    local filter = Instance.new("TextBox", tabFarm)
    HUD.farmFilterInput = filter
    filter.Size = UDim2.new(1,0,0,40)
    filter.BackgroundColor3 = Theme.Second
    filter.TextColor3 = Theme.Text
    filter.PlaceholderText = "Nome do NPC (vazio = qualquer um)"
    filter.PlaceholderColor3 = Color3.fromRGB(180,140,145)
    filter.Text = ""
    filter.TextSize = 12
    filter.Font = Enum.Font.GothamMedium
    filter.ClearTextOnFocus = false
    roundUI(filter,8)
    filter.FocusLost:Connect(function()
        HUD.farmFilter = string.lower(filter.Text):match("^%s*(.-)%s*$")
        if HUD.preferencesChanged then HUD.preferencesChanged() end
        farmTarget = nil
        HUD.farmSearchAt = 0
    end)
    HUD.farmStatus = Instance.new("TextLabel", tabFarm)
    HUD.farmStatus.Size = UDim2.new(1,0,0,54)
    HUD.farmStatus.BackgroundTransparency = 1
    HUD.farmStatus.TextColor3 = Theme.Text
    HUD.farmStatus.Font = Enum.Font.GothamMedium
    HUD.farmStatus.TextSize = 12
    HUD.farmStatus.TextWrapped = true
    HUD.setText(HUD.farmStatus,"Auto farm desligado.")
    local resume = Instance.new("TextButton", tabFarm)
    resume.Size = UDim2.new(1,0,0,38)
    resume.BackgroundColor3 = Theme.DarkRed
    resume.TextColor3 = Theme.Text
    resume.Font = Enum.Font.GothamMedium
    resume.TextSize = 12
    resume.Text = "Retomar farm após viagem"
    roundUI(resume,8)
    resume.Activated:Connect(function()
        if not HUD.travelActive and not HUD.seaBusy then HUD.farmPaused = false; HUD.farmSearchAt = 0 end
    end)
end

criarSecao("CONTROLE DE ATAQUE",0,tabFarm)
criarSlider("Tentativas por segundo",2,15,10,0,tabFarm,function(v) HUD.attackHz = v end)
criarSlider("Distância de ativação",1,8,4,0,tabFarm,function(v) HUD.attackReach = v end)
criarBotaoToggle("Ataque perto de NPC (sem farm)",0,tabFarm,function(v) HUD.autoNear = v; if not v then HUD.restoreHitbox() end end)
criarBotaoToggle("Manter altura manual",0,tabFarm,function(v) HUD.manualFarmHeight = v end)
criarBotaoToggle("Hitbox local do NPC",0,tabFarm,function(v)
    HUD.localHitbox = v
    if not v then HUD.restoreHitbox() end
end)
criarSlider("Largura da hitbox local",4,16,8,0,tabFarm,function(v) HUD.hitboxWidth = v end)
do
    local note = Instance.new("TextLabel",tabFarm)
    note.Size = UDim2.new(1,0,0,94)
    note.BackgroundTransparency = 1
    note.Font = Enum.Font.GothamMedium
    note.TextSize = 12
    note.TextColor3 = Theme.Text
    note.TextWrapped = true
    note.Text = "Sem altura manual, o farm se aproxima para atacar. A frequência controla tentativas; dano e velocidade real dependem da arma. A hitbox é local e não garante alcance extra no servidor."
end
-- ================= ESP FRUTAS =================

-- Catalogo local de nomes e raridades. ESP somente texto.
HUD.fruitCatalog = {
    ["Rocket"] = {rarity="Common"},
    ["Spin"] = {rarity="Common"},
    ["Chop"] = {rarity="Common"},
    ["Spring"] = {rarity="Common"},
    ["Bomb"] = {rarity="Common"},
    ["Smoke"] = {rarity="Common"},
    ["Spike"] = {rarity="Common"},
    ["Flame"] = {rarity="Uncommon"},
    ["Falcon"] = {rarity="Uncommon"},
    ["Ice"] = {rarity="Uncommon"},
    ["Sand"] = {rarity="Uncommon"},
    ["Dark"] = {rarity="Uncommon"},
    ["Diamond"] = {rarity="Uncommon"},
    ["Light"] = {rarity="Rare"},
    ["Rubber"] = {rarity="Rare"},
    ["Barrier"] = {rarity="Rare"},
    ["Ghost"] = {rarity="Rare"},
    ["Magma"] = {rarity="Rare"},
    ["Quake"] = {rarity="Legendary"},
    ["Buddha"] = {rarity="Legendary"},
    ["Love"] = {rarity="Legendary"},
    ["Spider"] = {rarity="Legendary"},
    ["Sound"] = {rarity="Legendary"},
    ["Phoenix"] = {rarity="Legendary"},
    ["Portal"] = {rarity="Legendary"},
    ["Rumble"] = {rarity="Legendary"},
    ["Pain"] = {rarity="Legendary"},
    ["Blizzard"] = {rarity="Legendary"},
    ["Gravity"] = {rarity="Mythical"},
    ["Dough"] = {rarity="Mythical"},
    ["Shadow"] = {rarity="Mythical"},
    ["Venom"] = {rarity="Mythical"},
    ["Control"] = {rarity="Mythical"},
    ["Spirit"] = {rarity="Mythical"},
    ["Dragon"] = {rarity="Mythical"},
    ["Leopard"] = {rarity="Mythical"},
    ["Kitsune"] = {rarity="Mythical"},
    ["Mammoth"] = {rarity="Mythical"},
    ["T-Rex"] = {rarity="Mythical"},
}
HUD.fruitColors = {
    Common=Color3.fromRGB(180,180,180), Uncommon=Color3.fromRGB(80,255,80),
    Rare=Color3.fromRGB(80,150,255), Legendary=Color3.fromRGB(255,170,0),
    Mythical=Color3.fromRGB(255,70,70), Unknown=Color3.fromRGB(210,210,220)
}
HUD.equippedFruitESP = true
-- Preserva os nomes adicionais reconhecidos na v025.
for _,name in ipairs({"Blade","Creation","Dragon East","Dragon West","Eagle","Gas","Lightning","Tiger","Yeti"}) do
    HUD.fruitCatalog[name]=HUD.fruitCatalog[name] or {rarity="Unknown"}
end
HUD.fruitNames = {}
for name in pairs(HUD.fruitCatalog) do HUD.fruitNames[name:lower()] = name end
function HUD.fruitInfo(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local raw = tool.Name:match("^%s*(.-)%s*$")
    local clean = raw:gsub("%s+[Ff][Rr][Uu][Ii][Tt]$", "")
    -- Alguns objetos usam nomes duplicados, como Rocket-Rocket.
    for canonical in pairs(HUD.fruitCatalog) do
        if clean:lower() == (canonical.."-"..canonical):lower() then clean=canonical; break end
    end
    local name = HUD.fruitNames[clean:lower()]
    if not name and clean == raw and tool.ToolTip ~= "Blox Fruit" then return nil end
    name = name or clean
    local entry = HUD.fruitCatalog[name]
    return {name=name, rarity=entry and entry.rarity or "Unknown"}
end
function HUD.isWorldFruit(tool)
    if not HUD.fruitInfo(tool) or not tool:IsDescendantOf(workspace) then return false end
    local parent=tool.Parent
    while parent and parent~=workspace do
        if parent:IsA("Backpack") or (parent:IsA("Model") and Players:GetPlayerFromCharacter(parent)) then return false end
        parent=parent.Parent
    end
    return true
end
function HUD.equippedFruit(character)
    if not HUD.equippedFruitESP or not character then return nil end
    for _,tool in ipairs(character:GetChildren()) do
        local info=HUD.fruitInfo(tool)
        if info then return info end
    end
end
local function createFruitESP(tool)

	if not HUD.alive or not fruitESPEnabled or not HUD.isWorldFruit(tool) or fruitEspObjects[tool] then return end

	local part = tool:FindFirstChildWhichIsA("BasePart")
	if not part then return end

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.new(0,200,0,60)
	bill.AlwaysOnTop = true
	bill.Adornee = part
	bill.Parent = part

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1,0,1,0)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamBold
	txt.TextScaled = false
	txt.TextSize = 14
	txt.TextStrokeTransparency = 0
	txt.Parent = bill
	txt.TextStrokeTransparency = 0
	txt.TextStrokeColor3 = Color3.new(0,0,0)
	bill.Size = UDim2.fromOffset(230,48)

	fruitEspObjects[tool] = {
		gui = bill,
		label = txt,
		part = part
	}

end
-- ================= PLAYER =================
criarSecao("PLAYER",0,tabPlayer)

criarBotaoToggle("Noclip",30,tabPlayer,function(v)
	noclip = v
end)

criarBotaoToggle("Water Walk",70,tabPlayer,function(v)
	floorEnabled = v
	if not v and floor then
		floor:Destroy()
		floor = nil
	end
end)

-- ================= MOVIMENTO =================
criarSecao("MOVIMENTO",120,tabPlayer)

HUD.jumpOriginals = setmetatable({}, {__mode = "k"})
function HUD.applyJump(humanoid)
    if not HUD.alive or not humanoid or humanoid.Health <= 0 then return end
    if not HUD.jumpOriginals[humanoid] then
        HUD.jumpOriginals[humanoid] = {power = humanoid.JumpPower, usePower = humanoid.UseJumpPower}
    end
    if not humanoid.UseJumpPower then humanoid.UseJumpPower = true end
    if humanoid.JumpPower ~= HUD.jump then humanoid.JumpPower = HUD.jump end
end
function HUD.waterLift(top, rootY, footOffset, thickness)
    local desired = top + footOffset + 0.2
    if rootY >= top - thickness - 12 and rootY < desired then return desired - rootY end
    return 0
end
do
    local top, thickness = -3.5, 36
    local surface
    HUD.connect(RunService.PreSimulation, function()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        HUD.applyJump(humanoid)
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not floorEnabled or not root or not humanoid or humanoid.Health <= 0 then
            if floor then floor:Destroy(); floor = nil; surface = nil end
            return
        end
        if not floor or not floor.Parent then
            floor = Instance.new("Part")
            floor.Name = "PudimHub_WaterSupport"
            floor.Anchored = true
            floor.Size = Vector3.new(500, thickness, 500)
            floor.Transparency = 1
            floor.CanTouch = false
            floor.CanQuery = false
            floor.TopSurface = Enum.SurfaceType.Smooth
            floor.BottomSurface = Enum.SurfaceType.Smooth
            floor.Parent = Workspace
            surface = Instance.new("Part")
            surface.Name = "WaterSurface"
            surface.Anchored = true
            surface.Size = Vector3.new(500, 0.12, 500)
            surface.CanCollide = false
            surface.CanTouch = false
            surface.CanQuery = false
            surface.CastShadow = false
            surface.Material = Enum.Material.Glass
            surface.Color = Theme.DarkRed
            surface.Transparency = 0.82
            surface.Parent = floor
            local outline = Instance.new("SelectionBox")
            outline.Adornee = surface
            outline.Color3 = Theme.Red
            outline.LineThickness = 0.04
            outline.SurfaceTransparency = 1
            outline.Transparency = 0.3
            outline.Parent = surface
        end
        local paused = humanoid.Sit or HUD.flying or HUD.travelActive or HUD.seaBusy
        floor.CanCollide = not paused
        floor.Position = Vector3.new(root.Position.X, top - thickness / 2, root.Position.Z)
        if surface and surface.Parent then
            surface.Position = Vector3.new(root.Position.X, top + 0.06, root.Position.Z)
            surface.Transparency = paused and 1 or 0.82
        end
        if not paused then
            local footOffset = humanoid.HipHeight + root.Size.Y / 2
            if humanoid.RigType == Enum.HumanoidRigType.R6 then
                local leg = character:FindFirstChild("Left Leg")
                footOffset = footOffset + (leg and leg:IsA("BasePart") and leg.Size.Y or 2)
            end
            local lift = HUD.waterLift(top, root.Position.Y, footOffset, thickness)
            if lift > 0 then
                root.CFrame = root.CFrame + Vector3.new(0, lift, 0)
                local velocity = root.AssemblyLinearVelocity
                if velocity.Y < 0 then
                    root.AssemblyLinearVelocity = Vector3.new(velocity.X, 0, velocity.Z)
                end
            end
        end
    end)
    gui.Destroying:Connect(function()
        for humanoid, original in pairs(HUD.jumpOriginals) do
            if humanoid.Parent then
                humanoid.JumpPower = original.power
                humanoid.UseJumpPower = original.usePower
            end
        end
    end)
end
criarSlider("Pulo",60,500,60,150,tabPlayer,function(v)
	HUD.jump = v
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    HUD.applyJump(humanoid)
end)

criarSlider("Velocidade TP",0,10,0,220,tabPlayer,function(v)
	tpSpeed = v
end)

criarSecao("Auto Safe", 270, tabPlayer)
criarBotaoToggle("Auto Safe", 300, tabPlayer, function(v) autoSafeEnabled = v; if not v then emFuga = false end end)
criarSlider("Limite % Vida", 5, 95, autoSafePercent, 340, tabPlayer, function(v) autoSafePercent = v end)
criarSlider("Altura Safe", 200, 20000, autoSafeHeight, 410, tabPlayer, function(v) autoSafeHeight = v end)
-- ================= ESP =================
criarSecao("ESP",0,tabESP)
criarBotaoToggle("ESP jogadores",30,tabESP,function(v)
	ESPAtivo = v
end)

criarBotaoToggle("Só inimigos",70,tabESP,function(v)
	espOnlyEnemies = v
end)

criarBotaoToggle("ESP frutas",110,tabESP,function(v)
	fruitESPEnabled = v
    if HUD.setFruitESP then HUD.setFruitESP(v) end
end)

criarBotaoToggle("Ocultar fruta equipada no ESP",0,tabESP,function(v) HUD.equippedFruitESP=not v end)
do
    local note=Instance.new("TextLabel",tabESP)
    note.Size=UDim2.new(1,0,0,70); note.BackgroundTransparency=1
    note.TextColor3=Theme.Text; note.Font=Enum.Font.Gotham; note.TextSize=12; note.TextWrapped=true
    note.Text="Fruta equipada: somente ferramentas visiveis no personagem. Nao mostra inventario guardado."
end
-- ================= SISTEMA =================
criarSecao("SISTEMA",0,tabSistema)

local rejoin = Instance.new("TextButton",tabSistema)
rejoin.Position = UDim2.new(0,10,0,30)
rejoin.Size = UDim2.new(1,0,0,38)
rejoin.BackgroundColor3 = Theme.Button
rejoin.Text="Rejoin"
rejoin.TextColor3=Color3.new(1,1,1)
rejoin.Font=Enum.Font.GothamMedium
rejoin.TextSize=12
Instance.new("UICorner",rejoin)

rejoin.MouseButton1Click:Connect(function()
    if HUD.serverBusy or HUD.seaBusy then return end
	local TeleportService = game:GetService("TeleportService")
	local Players = game:GetService("Players")

	TeleportService:TeleportToPlaceInstance(
		game.PlaceId,
		game.JobId,
		Players.LocalPlayer
	)
end)

-- ================= TIME =================
criarSecao("TIME (BLOX FRUITS)",80,tabSistema)

local function setTeam(team)
	pcall(function()
		HUD.remote("SetTeam",team)
	end)
end

local marine = Instance.new("TextButton",tabSistema)
marine.Position = UDim2.new(0,10,0,110)
marine.Size = UDim2.new(1,0,0,38)
marine.BackgroundColor3 = Color3.fromRGB(0,90,160)
marine.Text="Entrar Marine"
marine.TextColor3=Color3.new(1,1,1)
marine.Font=Enum.Font.GothamMedium
marine.TextSize=12
Instance.new("UICorner",marine)
marine.MouseButton1Click:Connect(function()
	setTeam("Marines")
end)

local pirate = Instance.new("TextButton",tabSistema)
pirate.Position = UDim2.new(0,10,0,150)
pirate.Size = UDim2.new(1,0,0,38)
pirate.BackgroundColor3 = Color3.fromRGB(160,40,40)
pirate.Text="Entrar Pirata"
pirate.TextColor3=Color3.new(1,1,1)
pirate.Font=Enum.Font.GothamMedium
pirate.TextSize=12
Instance.new("UICorner",pirate)
pirate.MouseButton1Click:Connect(function()
	setTeam("Pirates")
end)
-- ================= TELEPORT =================
-- Nenhum Sea selecionado ao abrir; a lista depende do clique do usuario.
HUD.currentSea = nil
-- Coordenadas herdadas da v030; eventos dependem dos objetos carregados no cliente.
HUD.islandsBySea = {
    [1] = {
        {nome="Pirate Starter", cf=CFrame.new(1071.2832,16.3085976,1426.86792), aliases={"Pirate Starter"}},
        {nome="Marine Starter", cf=CFrame.new(-2573.3374,6.88881969,2046.99817), aliases={"Marine Starter"}},
        {nome="Middle Town", cf=CFrame.new(-655.824158,7.88708115,1436.67908), aliases={"Middle Town"}},
        {nome="Jungle", cf=CFrame.new(-1249.77222,11.8870859,341.356476), aliases={"Jungle"}},
        {nome="Pirate Village", cf=CFrame.new(-1122.34998,4.78708982,3855.91992), aliases={"Pirate Village"}},
        {nome="Desert", cf=CFrame.new(1094.14587,6.47350502,4192.88721), aliases={"Desert"}},
        {nome="Frozen Village", cf=CFrame.new(1198.00928,27.0074959,-1211.73376), aliases={"Frozen Village"}},
        {nome="Marine Fortress", cf=CFrame.new(-4505.375,20.687294,4260.55908), aliases={"Marine Fortress"}},
        {nome="Colosseum", cf=CFrame.new(-1428.35474,7.38933945,-3014.37305), aliases={"Colosseum"}},
        {nome="Lower Skylands", cf=CFrame.new(-4970.21875,717.707275,-2622.35449), aliases={"Lower Skylands"}},
        {nome="Prison", cf=CFrame.new(4854.16455,5.68742752,740.194641), aliases={"Prison"}},
        {nome="Magma Village", cf=CFrame.new(-5231.75879,8.61593437,8467.87695), aliases={"Magma Village"}},
        {nome="Fountain City", cf=CFrame.new(5132.7124,4.53632832,4037.8562), aliases={"Fountain City"}},
        {nome="Upper Skylands", cf=CFrame.new(-7894.62,5547.14,-380.29), portal=Vector3.new(-7894.62,5547.14,-380.29), aliases={"Upper Skylands"}},
        {nome="Underwater City", cf=CFrame.new(61163.85,11.68,1819.78), portal=Vector3.new(61163.85,11.68,1819.78), aliases={"Underwater City"}},
        {nome="Jean-Luc Island / Mob Island", cf=CFrame.new(-2850.2,7.39,5354.99), aliases={"Jean-Luc Island","Mob Island"}},
        {nome="Skylands / Gods Guard", cf=CFrame.new(-4813.02,903.71,-1912.69), portal=Vector3.new(-4607.82,872.54,-1667.56), aliases={"Skylands / Gods Guard"}},
        {nome="North Pole", event=true, aliases={"North Pole","Christmas Island"}},
    },
    [2] = {
        {nome="Café", cf=CFrame.new(-380,80,300), aliases={"Café"}},
        {nome="Mansão", cf=CFrame.new(-390,332,715), aliases={"Mansão"}},
        {nome="Green Zone", cf=CFrame.new(-2221,80,-2704), aliases={"Green Zone"}},
        {nome="Graveyard", cf=CFrame.new(-5429,55,-745), aliases={"Graveyard"}},
        {nome="Cursed Ship / exterior", cf=CFrame.new(-6528,90,-162), aliases={"Cursed Ship / exterior"}},
        {nome="Snow Mountain", cf=CFrame.new(950,440,-5181), aliases={"Snow Mountain"}},
        {nome="Hot and Cold", cf=CFrame.new(-5701,15,-5003), aliases={"Hot and Cold"}},
        {nome="Ice Castle", cf=CFrame.new(5589,35,-6354), aliases={"Ice Castle"}},
        {nome="Forgotten Island", cf=CFrame.new(-3050,255,-10170), aliases={"Forgotten Island"}},
        {nome="Cursed Ship / interior", cf=CFrame.new(923.21,126.98,32852.83), portal=Vector3.new(923.21,126.98,32852.83), hint="Entrada depende do acesso liberado pelo jogo.", aliases={"Cursed Ship"}},
        {nome="Kingdom of Rose", cf=CFrame.new(-394.98,118.5,1245.84), aliases={"Kingdom of Rose"}},
        {nome="Kingdom of Rose / porto", cf=CFrame.new(82.95,18.07,2834.99), aliases={"Kingdom of Rose / porto"}},
        {nome="Factory", cf=CFrame.new(430.43,210.02,-432.5), aliases={"Factory"}},
        {nome="Colosseum", cf=CFrame.new(-1836.58,44.59,1360.31), aliases={"Colosseum"}},
        {nome="Dark Arena", cf=CFrame.new(3780.03,22.65,-3498.59), aliases={"Dark Arena"}},
        {nome="Remote Island / Usoap", cf=CFrame.new(4748.79,8.35,2849.58), aliases={"Remote Island","Remote","Usoap Island","Ussop Island"}},
        {nome="Cave Island", hint="Sem coordenada fixa confirmada. Aproxime-se da ilha a leste do porto e tente localizar novamente.", aliases={"Cave Island","CaveIsland"}},
        {nome="Indra Island", cf=CFrame.new(-26880.93,22.85,473.19), hint="Area da missao de acesso ao Sea 3; chegar nao inicia a missao.", aliases={"Indra Island"}},
        {nome="North Pole", event=true, aliases={"North Pole","Christmas Island"}},
    },
    [3] = {
        {nome="Port Town", cf=CFrame.new(-610.309692,57.8323097,6436.33594), aliases={"Port Town"}},
        {nome="Hydra Island", cf=CFrame.new(5229.99561,603.916565,345.154022), aliases={"Hydra Island"}},
        {nome="Great Tree", cf=CFrame.new(2174.94873,28.7312393,-6728.83154), aliases={"Great Tree"}},
        {nome="Castle on the Sea", cf=CFrame.new(-5477.62842,313.794739,-2808.4585), aliases={"Castle on the Sea"}},
        {nome="Floating Turtle", cf=CFrame.new(-10919.2998,331.788452,-8637.57227), aliases={"Floating Turtle"}},
        {nome="Mansão", cf=CFrame.new(-12553.8125,332.403961,-7621.91748), aliases={"Mansão"}},
        {nome="Peanut Land", cf=CFrame.new(-2142,48,-10031), aliases={"Peanut Land"}},
        {nome="Ice Cream Land", cf=CFrame.new(-949,59,-10907), aliases={"Ice Cream Land"}},
        {nome="Haunted Castle", cf=CFrame.new(-9515.37,164.01,5786.06), aliases={"Haunted Castle"}},
        {nome="Cake Land", cf=CFrame.new(-2021.32,37.8,-12028.73), aliases={"Cake Land","Cake Island","CakeLoaf"}},
        {nome="Chocolate Land", cf=CFrame.new(233.23,29.88,-12201.23), aliases={"Chocolate Land","Chocolate Island","Cocoa Island"}},
        {nome="Candy Cane Land", cf=CFrame.new(-1150.04,20.38,-14446.33), aliases={"Candy Cane Land","Candy Island","Candy Cane Island"}},
        {nome="Tiki Outpost", cf=CFrame.new(-16547.75,61.14,-173.41), aliases={"Tiki Outpost"}},
        {nome="Submerged Island / acesso", fallback=CFrame.new(-16547.75,61.14,-173.41), npc="Submarine Worker", hint="Em Tiki, fale com Submarine Worker no Sub Port 01. O jogo exige derrotar Tyrant of the Skies.", aliases={"Submerged Island / acesso"}},
        {nome="Temple of Time", cf=CFrame.new(28286.36,14895.3,102.62), portal=Vector3.new(28286.36,14895.3,102.62), hint="O servidor valida os requisitos do templo.", aliases={"Temple of Time"}},
        {nome="Hydra / Friendly Arena", cf=CFrame.new(5220.29,72.82,-1450.86), aliases={"Hydra / Friendly Arena"}},
        {nome="Hydra / Secret Temple", cf=CFrame.new(5217.36,6.57,1100.88), aliases={"Hydra / Secret Temple"}},
        {nome="Dimensional Shift", hint="Depende do evento de Cake Prince/Dough King e do portal do jogo.", event=true, aliases={"Dimensional Shift"}},
        {nome="Mirage Island", event=true, aliases={"Mirage Island","MysticIsland"}},
        {nome="Kitsune Island", event=true, aliases={"Kitsune Island","KitsuneIsland"}},
        {nome="Prehistoric Island", event=true, aliases={"Prehistoric Island","PrehistoricIsland"}},
        {nome="Frozen Dimension", event=true, aliases={"Frozen Dimension","FrozenDimension"}},
        {nome="Treasure Island", event=true, aliases={"Treasure Island","TreasureIsland"}},
        {nome="Haunted Shipwreck", event=true, aliases={"Haunted Shipwreck","HauntedShipwreck"}},
        {nome="North Pole", event=true, aliases={"North Pole","Christmas Island"}},
    },
}

criarSecao("TELEPORT / ESCOLHA SEU SEA",190,tabTeleport)
local currentTween = nil
local travelConnection
local travelJob
local travelRoot
local travelHumanoid
local travelStatus = Instance.new("TextLabel", container)
travelStatus.Name="TeleportStatus"
travelStatus.Size = UDim2.new(1,0,0,58)
travelStatus.Position=UDim2.fromOffset(0,0)
travelStatus.BackgroundColor3=Theme.Second
travelStatus.BackgroundTransparency = 0.1
travelStatus.BorderSizePixel=0
roundUI(travelStatus,8)
tabTeleport.Position=UDim2.fromOffset(0,66)
tabTeleport.Size=UDim2.new(1,0,1,-66)
travelStatus.Visible=tabTeleport.Visible
HUD.connect(tabTeleport:GetPropertyChangedSignal("Visible"),function()
    travelStatus.Visible=tabTeleport.Visible
end)
travelStatus.TextColor3 = Theme.Text
travelStatus.TextSize = 12
travelStatus.Font = Enum.Font.GothamMedium
travelStatus.TextWrapped = true
travelStatus.Text = "Escolha manualmente Sea 1, 2 ou 3 para carregar as ilhas."
HUD.travelToken = 0
local function CancelTeleport(message)
    HUD.travelToken = HUD.travelToken + 1
    local oldJob=travelJob
    travelJob=nil
    if oldJob and oldJob~=coroutine.running() then
        pcall(task.cancel,oldJob); HUD.jobs[oldJob]=nil
    end
    if travelConnection then travelConnection:Disconnect(); travelConnection = nil end
    local oldTween = currentTween
    currentTween = nil
    HUD.travelActive = false
    travelRoot, travelHumanoid = nil, nil
    if oldTween then oldTween:Cancel() end
    if message then travelStatus.Text = message end
end
-- Cancelamento sempre acessivel, mesmo com a lista de ilhas rolada.
do
    travelStatus.Size=UDim2.new(1,-76,0,58)
    local stop=Instance.new("TextButton",container)
    stop.Name="StopTravel"; stop.Size=UDim2.fromOffset(70,58)
    stop.Position=UDim2.new(1,-70,0,0)
    stop.BackgroundColor3=Theme.DarkRed; stop.TextColor3=Theme.Text
    stop.Font=Enum.Font.GothamMedium; stop.TextSize=12; stop.Text="Parar TP"
    stop.TextWrapped=true; roundUI(stop,8)
    stop.Visible=tabTeleport.Visible
    HUD.connect(tabTeleport:GetPropertyChangedSignal("Visible"),function() stop.Visible=tabTeleport.Visible end)
    HUD.connect(stop.Activated,function() CancelTeleport("Viagem cancelada.") end)
end
local function TweenTeleport(destination)
    if HUD.seaBusy or HUD.serverBusy then travelStatus.Text = "Aguarde a troca de servidor/Sea."; return end
    if not HUD.currentSea then travelStatus.Text = "Escolha primeiro o Sea em que esta."; return end
    -- O Sea escolhido manualmente determina o catalogo, sem bloqueio por PlaceId.
    CancelTeleport("Preparando viagem: "..destination.nome)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then travelStatus.Text = "Aguarde o personagem renascer."; return end
    if HUD.stopFly then HUD.stopFly() end
    if root.Anchored then travelStatus.Text = "Personagem preso. Aguarde antes de viajar."; return end
    hum.Sit=false
    HUD.farmPaused, HUD.travelActive = true, true
    travelRoot, travelHumanoid = root, hum
    local token = HUD.travelToken
    local function valid()
        return HUD.alive and HUD.travelActive and token == HUD.travelToken and player.Character == character
            and root.Parent == character and hum.Health > 0
    end
    local function normalize(name) return string.lower(name):gsub("[^%w]", "") end
    local function findNamed(folder, names)
        if not folder then return nil end
        local namesSet = {}
        for _, name in ipairs(names) do namesSet[normalize(name)] = true end
        for _, item in ipairs(folder:GetChildren()) do
            if namesSet[normalize(item.Name)] then return item end
        end
    end
    local function objectPosition(object)
        if not object then return nil end
        if object:IsA("BasePart") then return object.Position end
        if object:IsA("Model") then return object:GetPivot().Position end
    end
    local function groundAt(position, high)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = {character}
        if floor then table.insert(ignore,floor) end
        for _, name in ipairs({"Characters", "Enemies", "NPCs", "_WorldOrigin", "PudimHub_FlightOrigin"}) do
            local object = workspace:FindFirstChild(name)
            if object then table.insert(ignore, object) end
        end
        params.FilterDescendantsInstances = ignore
        params.IgnoreWater = false
        params.RespectCanCollide = true
        local height = high and 600 or 40
        for _, offset in ipairs({Vector3.zero,Vector3.new(30,0,0),Vector3.new(-30,0,0),Vector3.new(0,0,30),Vector3.new(0,0,-30)}) do
            local hit = workspace:Raycast(position + offset + Vector3.new(0,height,0),Vector3.new(0,-height-250,0),params)
            if hit and hit.Material ~= Enum.Material.Water and hit.Normal.Y > 0.6 then
                return CFrame.new(hit.Position + Vector3.new(0,hum.HipHeight + root.Size.Y/2 + 1,0))
            end
        end
    end
    local function entrance(position)
        if (root.Position-position).Magnitude < 1000 then return true end
        travelStatus.Text = "Solicitando entrada de " .. destination.nome .. "..."
        -- Uma solicitacao por etapa; sem repeticao ilimitada ou reset do personagem.
        local finished, success = false, false
        HUD.startJob(function()
            if not valid() then return end
            success = pcall(function() HUD.remote("requestEntrance", position) end)
            finished = true
        end)
        local deadline = os.clock() + 8
        repeat task.wait(0.1)
        until not valid() or (root.Position-position).Magnitude < 1000 or os.clock() >= deadline
        if not valid() then return false end
        if (root.Position-position).Magnitude >= 1000 then
            CancelTeleport(finished and not success and "Falha na entrada especial." or "Entrada nao confirmada. Use o portal/NPC do jogo e confira os requisitos.")
            return false
        end
        return true
    end
    travelJob=HUD.startJob(function()
        local ok, err = pcall(function()
            local point, observed, livePosition = destination.cf, nil, nil
            local needsGround = not destination.cf and not destination.npc
            if destination.npc then
                local npc = findNamed(workspace:FindFirstChild("NPCs"), {destination.npc})
                if npc then
                    local npcRoot = npc:FindFirstChild("HumanoidRootPart") or (npc:IsA("Model") and npc.PrimaryPart)
                    if npcRoot and (not destination.fallback or (npcRoot.Position-destination.fallback.Position).Magnitude < 4000) then
                        point = npcRoot.CFrame * CFrame.new(0,0,5)
                    end
                end
                point = point or destination.fallback
            elseif not destination.portal then
                local origin = workspace:FindFirstChild("_WorldOrigin")
                observed = findNamed(origin and origin:FindFirstChild("Locations"), destination.aliases)
                    or findNamed(workspace:FindFirstChild("Map"), destination.aliases)
                livePosition = objectPosition(observed)
                if livePosition then
                    -- Marcadores sao centros de regioes, nao pisos.
                    if not point then
                        point = CFrame.new(livePosition)
                        needsGround = true
                    end
                end
            end
            if not point then
                CancelTeleport(destination.hint or (destination.nome .. ": nao localizado no mapa carregado. O evento pode estar ausente ou longe demais."))
                return
            end
            if HUD.currentSea == 1 and root.Position.X > 50000 and point.Position.X < 50000 then
                if not entrance(Vector3.new(3865,5,-1926)) then return end
            elseif HUD.currentSea == 2 and root.Position.Z > 20000 and point.Position.Z < 20000 then
                if not entrance(Vector3.new(-6508.56,89.03,-132.84)) then return end
            end
            if destination.portal and not entrance(destination.portal) then return end
            if not valid() then return end
            travelStatus.Text="Carregando destino: "..destination.nome
            pcall(function() player:RequestStreamAroundAsync(point.Position, 3) end)
            if not valid() then return end
            local grounded = groundAt(point.Position, needsGround)
            if not grounded and needsGround then
                -- O streaming pode terminar antes de o piso aparecer no cliente.
                local deadline=os.clock()+3
                repeat
                    task.wait(0.25)
                    if not valid() then return end
                    grounded=groundAt(point.Position,true)
                until grounded or os.clock()>=deadline
            end
            if grounded then point = grounded
            elseif needsGround then
                CancelTeleport("Local encontrado, mas sem piso carregado para pousar. Aproxime-se e tente novamente.")
                return
            end
            local duration = math.max(0.1,(root.Position-point.Position).Magnitude/HUD.travelSpeed)
            if duration > 600 then
                CancelTeleport("Viagem acima de 10 minutos nessa velocidade. Aumente Velocidade da viagem ou aproxime-se."); return
            end
            travelStatus.Text = string.format("%s / %.0f s / farm pausado",destination.nome,duration)
            local tween = TweenService:Create(root,TweenInfo.new(duration,Enum.EasingStyle.Linear),{CFrame=point})
            currentTween = tween
            local completed,ended = false,false
            travelConnection = tween.Completed:Connect(function(state)
                ended=true; completed=state==Enum.PlaybackState.Completed
            end)
            tween:Play()
            local limit = os.clock()+duration+4
            local progressPosition,progressAt=root.Position,os.clock()
            repeat
                task.wait(0.15)
                if not valid() then return end
                if (root.Position-progressPosition).Magnitude>=1 then
                    progressPosition,progressAt=root.Position,os.clock()
                elseif not ended and os.clock()-progressAt>4 then
                    CancelTeleport("Sem deslocamento por 4 segundos. Personagem preso ou movimento recusado."); return
                end
                travelStatus.Text=string.format("Indo: %s / %.0f studs restantes",destination.nome,(root.Position-point.Position).Magnitude)
                if root.Anchored then CancelTeleport("Viagem interrompida: personagem ancorado."); return end
                if destination.event and observed and not observed:IsDescendantOf(workspace) then
                    CancelTeleport("Evento deixou de estar carregado durante a viagem."); return
                end
            until not valid() or ended or os.clock() >= limit
            if not valid() then return end
            if not completed then CancelTeleport("Percurso interrompido ou tempo limite."); return end
            travelStatus.Text = "Conferindo chegada: " .. destination.nome
            task.wait(1)
            if not valid() then return end
            local arrived = (root.Position-point.Position).Magnitude < 40
            CancelTeleport(arrived and (destination.hint or ("Chegada local conferida: " .. destination.nome .. ". Retome o farm quando quiser."))
                or "Posicao corrigida pelo jogo ou pouso nao confirmado. Confira o destino antes de tentar novamente.")
            HUD.manualHold = os.clock()+0.5
        end)
        if not ok and valid() then HUD.report("Teleporte",err); CancelTeleport("Viagem interrompida: " .. tostring(err):sub(1,160)) end
    end)
end

criarSlider("Velocidade da viagem",50,350,250,0,tabTeleport,function(v) HUD.travelSpeed = v end)
HUD.connect(RunService.Heartbeat,function()
    if HUD.travelActive and (not travelRoot or not travelRoot.Parent or not travelHumanoid or travelHumanoid.Health <= 0 or player.Character ~= travelRoot.Parent) then
        CancelTeleport("Viagem cancelada: personagem indisponível.")
    end
end)
HUD.connect(player.CharacterAdded,function()
    CancelTeleport("Personagem renasceu. Escolha o destino novamente.")
    farmTarget = nil
    emFuga = false
    HUD.farmSearchAt = 0
end)

-- ================= SELETOR MANUAL DE SEA =================
do
    local selectedLabel = Instance.new("TextLabel",tabTeleport)
    selectedLabel.Size = UDim2.new(1,0,0,54)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.TextColor3 = Theme.Text
    selectedLabel.Font = Enum.Font.GothamMedium
    selectedLabel.TextSize = 12
    selectedLabel.TextWrapped = true
    selectedLabel.Text = "Escolha seu Sea abaixo. Eventos dependem do mapa carregado."
    local selector = Instance.new("Frame",tabTeleport)
    selector.Size = UDim2.new(1,0,0,40)
    selector.BackgroundTransparency = 1
    local buttons = {}
    local search = Instance.new("TextBox",tabTeleport)
    search.Size = UDim2.new(1,0,0,36)
    search.BackgroundColor3 = Theme.Second
    search.TextColor3 = Theme.Text
    search.PlaceholderText = "Buscar ilha nesta lista..."
    search.PlaceholderColor3 = Color3.fromRGB(170,150,160)
    search.Font = Enum.Font.Gotham
    search.TextSize = 13
    search.Text = ""
    search.ClearTextOnFocus = false
    roundUI(search)
    local list = Instance.new("Frame",tabTeleport)
    list.Size = UDim2.new(1,0,0,0)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    -- Uma unica rolagem na aba: evita disputa de toque entre dois ScrollingFrames.
    local function rebuild()
        for _, child in ipairs(list:GetChildren()) do child:Destroy() end
        local entries = table.clone(HUD.islandsBySea[HUD.currentSea] or {})
        table.sort(entries,function(a,b)
            local fa=HUD.favorites[tostring(HUD.currentSea)..":"..a.nome]==true
            local fb=HUD.favorites[tostring(HUD.currentSea)..":"..b.nome]==true
            if fa~=fb then return fa end
            return a.nome<b.nome
        end)
        local query = string.lower(search.Text):match("^%s*(.-)%s*$")
        local count = 0
        for _, island in ipairs(entries) do
            local keywords = island.nome .. " " .. table.concat(island.aliases or {}, " ")
            if query == "" or string.find(string.lower(keywords),query,1,true) then
                local destination = island
                local button = Instance.new("TextButton",list)
                button.Size = UDim2.new(1,-49,0,34)
                button.Position = UDim2.fromOffset(0,count*38)
                button.BackgroundColor3 = Theme.Button
                button.BackgroundTransparency = 0.15
                button.TextColor3 = Theme.Text
                button.Font = Enum.Font.GothamMedium
                button.TextSize = 12
                button.TextWrapped = true
                local tag = island.event and " [EVENTO]" or island.npc and " [ACESSO]" or island.portal and " [ENTRADA]" or not island.cf and " [LOCALIZAR]" or ""
                button.Text = island.nome .. tag
                roundUI(button,7)
                button.Active=true
                button.Activated:Connect(function()
                    if not HUD.alive then return end
                    travelStatus.Text="Selecionado: "..destination.nome
                    local ok,err=pcall(TweenTeleport,destination)
                    if not ok then
                        HUD.report("Clique teleporte",err)
                        CancelTeleport("Falha ao iniciar: "..tostring(err):sub(1,160))
                    end
                end)
                local favorite=Instance.new("TextButton",list)
                favorite.Size=UDim2.fromOffset(34,34)
                favorite.Position=UDim2.new(1,-43,0,count*38)
                favorite.BackgroundColor3=Theme.Second
                favorite.TextColor3=Theme.Red
                favorite.TextSize=22
                local key=tostring(HUD.currentSea)..":"..island.nome
                favorite.Text=HUD.favorites[key] and "★" or "☆"
                roundUI(favorite,7)
                favorite.Activated:Connect(function()
                    HUD.favorites[key]=not HUD.favorites[key] or nil
                    if HUD.preferencesChanged then HUD.preferencesChanged() end
                    rebuild()
                end)
                count = count + 1
            end
        end
        list.Size = UDim2.new(1,0,0,HUD.currentSea and math.max(38,count*38) or 0)
        if HUD.currentSea then selectedLabel.Text = "SEA "..HUD.currentSea.." / "..count.." de "..#entries.." destinos. [EVENTO] depende de estar carregado." end
    end
    for sea = 1,3 do
        local selectedSea = sea
        local button = Instance.new("TextButton",selector)
        button.Size = UDim2.new(1/3,-6,1,0)
        button.Position = UDim2.new((sea-1)/3,0,0,0)
        button.BackgroundColor3 = Theme.Button
        button.TextColor3 = Theme.Text
        button.Text = "SEA "..sea
        button.TextSize = 13
        button.Font = Enum.Font.GothamBold
        roundUI(button,8)
        buttons[sea] = button
        button.Activated:Connect(function()
            CancelTeleport("SEA "..selectedSea.." selecionado. Escolha uma ilha.")
            HUD.currentSea = selectedSea
            search.Text = ""
            for index, item in ipairs(buttons) do
                item.BackgroundColor3 = index == selectedSea and Theme.DarkRed or Theme.Button
                item.Text = "SEA "..index..(index == selectedSea and " [x]" or "")
            end
            rebuild()
        end)
    end
    HUD.refreshIslands = rebuild
    for sea,button in ipairs(buttons) do
        button.BackgroundColor3=sea==HUD.currentSea and Theme.DarkRed or Theme.Button
        button.Text="SEA "..sea..(sea==HUD.currentSea and " [x]" or "")
    end
    rebuild()
    search:GetPropertyChangedSignal("Text"):Connect(rebuild)
    HUD.resetSeaSelection = function()
        HUD.currentSea = nil
        search.Text = ""
        for sea, button in ipairs(buttons) do
            button.Text = "SEA "..sea..(sea==HUD.currentSea and " [x]" or "")
            button.BackgroundColor3 = sea==HUD.currentSea and Theme.DarkRed or Theme.Button
        end
        selectedLabel.Text = "Escolha manualmente Sea 1, 2 ou 3."
        travelStatus.Text = "Escolha seu Sea para carregar as ilhas."
        rebuild()
    end
end


do
    criarSecao("VIAJAR ENTRE SEAS",0,tabTeleport)
    local note = Instance.new("TextLabel",tabTeleport)
    note.Size = UDim2.new(1,0,0,62)
    note.BackgroundTransparency = 1
    note.TextColor3 = Theme.Text
    note.Font = Enum.Font.GothamMedium
    note.TextSize = 12
    note.TextWrapped = true
    note.Text = "O servidor verifica seu acesso ao destino. A viagem não desbloqueia mares."
    local destinations = {
        {name="SEA 1", id=2753915549, command="TravelMain"},
        {name="SEA 2", id=4442272183, command="TravelDressrosa"},
        {name="SEA 3", id=7449423635, command="TravelZou"}
    }
    for _, destination in ipairs(destinations) do
        local button = Instance.new("TextButton",tabTeleport)
        button.Size = UDim2.new(1,0,0,40)
        button.BackgroundColor3 = Theme.DarkRed
        button.BackgroundTransparency = 0.15
        button.TextColor3 = Theme.Text
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 13
        button.Text = destination.name .. (game.PlaceId == destination.id and " / Atual" or " / Viajar")
        roundUI(button,8)
        button.Activated:Connect(function()
            if game.PlaceId == destination.id then note.Text = "Você já está no "..destination.name.."."; return end
            if HUD.seaBusy or HUD.serverBusy then return end
            CancelTeleport("Solicitando troca de Sea…")
            if HUD.stopFly then HUD.stopFly() end
            HUD.farmPaused, HUD.seaBusy = true, true
            HUD.seaToken += 1
            local token = HUD.seaToken
            note.Text = "Solicitando "..destination.name.." ao servidor…"
            task.delay(15,function()
                if HUD.alive and token == HUD.seaToken and HUD.seaBusy then
                    HUD.seaBusy = false
                    HUD.seaToken += 1
                    note.Text = "Viagem não confirmada. Verifique o acesso ao Sea e tente pelo NPC de viagem."
                end
            end)
            HUD.startJob(function()
                local ok = pcall(function()
                    if HUD.savePreferences then HUD.savePreferences() end
                    HUD.remote(destination.command)
                end)
                if not HUD.alive or token ~= HUD.seaToken then return end
                if not ok then
                    HUD.seaBusy = false
                    HUD.seaToken += 1
                    note.Text = "Não foi possível solicitar a viagem. Tente novamente depois."
                end
            end)
        end)
    end
    HUD.connect(TeleportService.TeleportInitFailed,function(who)
        if who == player and HUD.seaBusy then
            HUD.seaBusy = false
            HUD.seaToken += 1
            note.Text = "O servidor não iniciou a viagem. Confira seu acesso e tente novamente."
        end
    end)
end

-- ================= AIMBOT v011: JOGADORES / NPCs =================
do
    local aim = {mode = nil, part = nil, model = nil, humanoid = nil, owner = nil,
        playerFov = 200, npcFov = 200, distance = 500, smooth = 0,
        enemiesOnly = false, showFov = true, highlight = true, elapsed = 0, keepBehindWalls = false}
    local green = Color3.fromRGB(55, 235, 130)
    local function clearTarget(reason)
        aim.reason=reason
        aim.part, aim.model, aim.humanoid, aim.owner = nil, nil, nil, nil
    end
    HUD.clearAimTarget=clearTarget
    local circle = Instance.new("Frame", gui)
    circle.Name = "AimFOV"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.BackgroundTransparency = 1
    circle.Visible = false
    roundUI(circle, 9999)
    local stroke = Instance.new("UIStroke", circle)
    stroke.Thickness = 1.5
    local marker = Instance.new("Highlight", gui)
    marker.Name = "AimTarget"
    marker.DepthMode = Enum.HighlightDepthMode.Occluded
    marker.FillTransparency = 0.88
    marker.OutlineTransparency = 0.1
    marker.Enabled = false

    criarSecao("MIRA • F JOGADORES / H NPCs E BOSSES",0,tabAimbot)
    local controls = {}
    local status = Instance.new("TextLabel")
    local function updateUI()
        for mode, button in pairs(controls) do
            local active = aim.mode == mode
            local name = mode == "NPC" and "["..HUD.keys.npcs.."] NPCs / Bosses" or "["..HUD.keys.players.."] Jogadores"
            button.Text = name .. (active and "  •  Ligado" or "  •  Desligado")
            button.TextColor3 = active and (mode == "NPC" and green or Theme.Red) or Theme.Text
        end
        local color = aim.mode == "NPC" and green or Theme.Red
        stroke.Color = color
        marker.FillColor, marker.OutlineColor = color, color
        marker.Adornee = aim.model
        marker.Enabled = aim.highlight and aim.model ~= nil and aim.mode ~= nil
        if not aim.mode then
            status.Text = "Mira desligada • "..HUD.keys.players..": jogadores | "..HUD.keys.npcs..": NPCs/bosses"
        elseif aim.model and aim.humanoid then
            status.Text = "ALVO: " .. aim.model.Name .. " • HP " .. math.ceil(aim.humanoid.Health)
        else
            status.Text = (aim.reason and aim.reason.." • " or "").."Buscando " .. (aim.mode == "NPC" and "NPC/boss" or "jogador") .. " visivel no circulo..."
        end
        status.TextColor3 = aim.mode and color or Theme.Text
    end
    HUD.savedAimMode = false
    local function setMode(mode, temporary)
        if not temporary then
            HUD.savedAimMode = mode or false
            if HUD.preferencesChanged then HUD.preferencesChanged() end
        end
        aim.mode = mode
        aim.elapsed = 1
        clearTarget()
        circle.Visible = false
        updateUI()
    end
    HUD.restoreAimMode = function(mode)
        if mode=="PLAYER" or mode=="NPC" then setMode(mode) else setMode(nil) end
    end
    HUD.resetAim = function() setMode(nil) end
    for _, mode in ipairs({"PLAYER", "NPC"}) do
        local selectedMode = mode
        local button = Instance.new("TextButton", tabAimbot)
        button.Size = UDim2.new(1, 0, 0, 46)
        button.BackgroundColor3 = Theme.Second
        button.BackgroundTransparency = 0.2
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.TextSize = 12
        roundUI(button)
        controls[mode] = button
        button.Activated:Connect(function()
            if aim.mode == selectedMode then setMode(nil) else setMode(selectedMode) end
        end)
    end
    status.Size = UDim2.new(1, 0, 0, 48)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 12
    status.TextWrapped = true
    status.Parent = tabAimbot
    criarBotaoToggle("Jogadores: só inimigos",0,tabAimbot,function(v)
        aim.enemiesOnly = v; clearTarget()
    end)
    criarBotaoToggle("Manter alvo atrás de paredes (NPC/Player)",0,tabAimbot,function(v)
        aim.keepBehindWalls = v
    end)
    criarBotaoToggle("Ocultar círculo FOV",0,tabAimbot,function(v) aim.showFov = not v end)
    criarBotaoToggle("Ocultar destaque do alvo",0,tabAimbot,function(v)
        aim.highlight = not v; updateUI()
    end)
    criarSlider("FOV JOGADORES",50,500,200,0,tabAimbot,function(v) aim.playerFov = v end)
    criarSlider("FOV NPCs / BOSSES",50,500,200,0,tabAimbot,function(v) aim.npcFov = v end)
    criarSlider("DISTANCIA DA MIRA",50,1500,500,0,tabAimbot,function(v) aim.distance = v end)
    criarSlider("SUAVIDADE (0 = INSTANTANEO)",0,100,0,0,tabAimbot,function(v) aim.smooth = v end)

    local function sameTeam(other)
        if player.Team and other.Team then return player.Team == other.Team end
        if player.TeamColor and other.TeamColor then return player.TeamColor == other.TeamColor end
        return false
    end
    local sightParams=RaycastParams.new()
    sightParams.FilterType=Enum.RaycastFilterType.Exclude
    sightParams.IgnoreWater=true
    local sightCharacter,sightCamera,sightFloor,sightMarker
    local function eligible(model, owner)
        if not model or not model:IsA("Model") or not model:IsDescendantOf(workspace) then return false end
        if aim.mode == "PLAYER" then
            return owner and owner ~= player and owner.Parent == Players and owner.Character == model
                and (not aim.enemiesOnly or not sameTeam(owner))
        end
        local folder = workspace:FindFirstChild("Enemies")
        return aim.mode == "NPC" and folder and model.Parent == folder
            and model ~= player.Character and not Players:GetPlayerFromCharacter(model)
            and (HUD.aimFilter=="" or model.Name:lower():find(HUD.aimFilter,1,true)~=nil)
    end
    local function visiblePart(camera, model, part, holding)
        if not part or not part:IsA("BasePart") or not part:IsDescendantOf(model) then return nil end
        local distance = (part.Position - camera.CFrame.Position).Magnitude
        local offset = 0
        -- FOV e distancia limitam apenas a captura de um NOVO alvo.
        if not holding then
            if distance > aim.distance or distance < 0.01 then return nil end
            local screen, onScreen = camera:WorldToViewportPoint(part.Position)
            if not onScreen or screen.Z <= 0 then return nil end
            local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            offset = (Vector2.new(screen.X, screen.Y) - center).Magnitude
            local radius = aim.mode == "NPC" and aim.npcFov or aim.playerFov
            if offset > radius then return nil end
        end
        if sightCharacter~=player.Character or sightCamera~=camera or sightFloor~=floor or sightMarker~=HUD.flightMarker then
            sightCharacter,sightCamera,sightFloor,sightMarker=player.Character,camera,floor,HUD.flightMarker
            local ignore={camera}
            if sightCharacter then table.insert(ignore,sightCharacter) end
            if floor then table.insert(ignore,floor) end
            if HUD.flightMarker then table.insert(ignore,HUD.flightMarker) end
            sightParams.FilterDescendantsInstances=ignore
        end
        local hit = workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, sightParams)
        if hit and not hit.Instance:IsDescendantOf(model) then return nil end
        return offset
    end
    local function acquire(camera)
        local best = math.huge
        local function consider(model, owner)
            if not eligible(model, owner) then return end
            local hum = model:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end
            local head = model:FindFirstChild("Head")
            local torso = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
            local parts = {}
            if head then table.insert(parts, head) end
            if torso then table.insert(parts, torso) end
            for _, part in ipairs(parts) do
                local score = visiblePart(camera, model, part)
                if score and HUD.aimPriority=="Distancia" then score=(part.Position-camera.CFrame.Position).Magnitude end
                if score and score < best then
                    best = score
                    aim.part, aim.model, aim.humanoid, aim.owner = part, model, hum, owner
                    aim.reason=nil
                end
            end
        end
        if aim.mode == "PLAYER" then
            for _, other in ipairs(Players:GetPlayers()) do consider(other.Character, other) end
        elseif aim.mode == "NPC" then
            local folder = workspace:FindFirstChild("Enemies")
            if folder then
                for _, npc in ipairs(folder:GetChildren()) do consider(npc, nil) end
            end
        end
    end
    HUD.connect(UserInputService.InputBegan, function(input, processed)
        if processed or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode[HUD.keys.players] then
            if aim.mode == "PLAYER" then setMode(nil) else setMode("PLAYER") end
        elseif input.KeyCode == Enum.KeyCode[HUD.keys.npcs] then
            if aim.mode == "NPC" then setMode(nil) else setMode("NPC") end
        end
    end)
    HUD.connect(player.CharacterRemoving, function() setMode(nil, true) end)
    HUD.connect(player.CharacterAdded, function()
        setMode(HUD.savedAimMode or nil, true)
    end)
    local renderName="PudimHubAim_"..tostring(player.UserId)
    local function renderAim(dt)
        local camera = workspace.CurrentCamera
        local ownChar = player.Character
        local ownHum = ownChar and ownChar:FindFirstChildOfClass("Humanoid")
        if not aim.mode or not camera or not ownHum or ownHum.Health <= 0 then
            circle.Visible = false
            if aim.model then clearTarget(); updateUI() end
            return
        end
        local radius = aim.mode == "NPC" and aim.npcFov or aim.playerFov
        local inset = gui.IgnoreGuiInset and Vector2.new() or game:GetService("GuiService"):GetGuiInset()
        circle.Visible = aim.showFov
        circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
        circle.Position = UDim2.fromOffset(camera.ViewportSize.X / 2 - inset.X, camera.ViewportSize.Y / 2 - inset.Y)
        aim.elapsed = aim.elapsed + dt
        -- A opcao de paredes afeta a retencao de NPCs e jogadores; novos alvos exigem visibilidade.
        if aim.part then
            local reason
            if not eligible(aim.model,aim.owner) or not aim.part:IsDescendantOf(aim.model) then reason="Alvo removido ou filtro alterado"
            elseif not aim.humanoid or aim.humanoid.Health<=0 then reason="Alvo sem vida"
            elseif not aim.keepBehindWalls
                and visiblePart(camera,aim.model,aim.part,true)==nil then reason="Alvo obstruido" end
            if reason then clearTarget(reason); updateUI() end
        end
        -- Digitar pausa a camera, mas nao troca nem descarta um alvo ainda valido.
        if UserInputService:GetFocusedTextBox() then return end
        -- So busca outro alvo quando o anterior deixa de ser valido.
        if aim.elapsed >= 0.1 then
            aim.elapsed = 0
            if not aim.part then acquire(camera) end
            updateUI()
        end
        if aim.part and aim.part:IsDescendantOf(workspace) and aim.humanoid and aim.humanoid.Health > 0 then
            local origin = camera.CFrame.Position
            if (aim.part.Position - origin).Magnitude > 0.01 then
                local desired = CFrame.lookAt(origin, aim.part.Position)
                local alpha = aim.smooth == 0 and 1 or 1 - math.exp(-dt / (0.025 + aim.smooth * 0.003))
                camera.CFrame = camera.CFrame:Lerp(desired, alpha)
            end
        end
    end
    RunService:BindToRenderStep(renderName,Enum.RenderPriority.Camera.Value+1,function(dt)
        if not HUD.alive then return end
        local ok,err=pcall(renderAim,dt)
        if not ok then clearTarget("Falha na mira"); HUD.report("Mira",err) end
    end)
    gui.Destroying:Connect(function() RunService:UnbindFromRenderStep(renderName) end)
    updateUI()
end

-- ================= LOOP =================
HUD.connect(RunService.RenderStepped, function(dt)
    if not (autoSafeEnabled or autoFarmEnabled or tpSpeed > 0 or noclip or floorEnabled or next(HUD.collisions) or HUD.hitboxPart) then return end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then HUD.restoreHitbox(); return end

    if autoSafeEnabled then
        if hum and hum.Health > 0 then
            -- CALCULA O LIMITE BASEADO NA SUA VIDA MÁXIMA
            local limite = hum.MaxHealth * (autoSafePercent / 100)

            if hum.Health >= math.min(hum.MaxHealth,limite+hum.MaxHealth*0.1) and emFuga == true then
                emFuga = false
            end
            if hum.Health <= limite and emFuga == false then
                emFuga = true
                CancelTeleport("Viagem interrompida pelo Auto Safe.")
                if HUD.stopFly then HUD.stopFly() end
                if root then
                    root.CFrame = root.CFrame + Vector3.new(0, autoSafeHeight, 0)
                end
            end
        else
            emFuga = false
        end
    end
-- ================= AUTO FARM =================
local now=os.clock()
HUD.safeActive=emFuga
local farmCanMove=autoFarmEnabled and HUD.activity()=="LIVRE"
if farmCanMove then
    if not HUD.validFarmTarget(farmTarget,root,now,HUD.farmRadius) then
        farmTarget=nil; HUD.progress=nil
        if now>=HUD.farmSearchAt then
            HUD.farmSearchAt=now+0.4
            local enemies=workspace:FindFirstChild("Enemies")
            local nearest=HUD.farmRadius
            if enemies then
                for _,npc in ipairs(enemies:GetChildren()) do
                    if HUD.validFarmTarget(npc,root,now,HUD.farmRadius) then
                        local distance=(npc.HumanoidRootPart.Position-root.Position).Magnitude
                        if distance<nearest then nearest=distance; farmTarget=npc end
                    end
                end
            end
        end
    end
    if farmTarget then
        local recovery=HUD.observeProgress(farmTarget,now)
        if (HUD.farmIgnored[farmTarget] or 0)>now then
            HUD.restoreHitbox(); farmTarget=nil
            HUD.setText(HUD.farmStatus,recovery)
        else
            local targetRoot=farmTarget.HumanoidRootPart
            if now>=HUD.moveAt then
                HUD.moveAt=now+0.1
                local offset=Vector3.new(0,farmHeight,farmDistance)
                if not HUD.manualFarmHeight then
                    local size=targetRoot==HUD.hitboxPart and HUD.hitboxOriginal.size or targetRoot.Size
                    local limit=math.max(1,math.min(size.X,size.Y,size.Z)*0.5+HUD.attackReach*0.7)
                    if offset.Magnitude>limit then offset=offset.Unit*limit end
                end
                if HUD.progress and HUD.progress.retries>0 then offset=Vector3.new(offset.Z,offset.Y,0) end
                local point=targetRoot.Position+offset
                local params=RaycastParams.new()
                params.FilterType=Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances={char,farmTarget}
                params.RespectCanCollide=true
                local obstruction=workspace:Raycast(targetRoot.Position,point-targetRoot.Position,params)
                if not obstruction then
                    local far=HUD.bodyDistance(farmTarget,root.Position)>math.max(0.5,HUD.attackReach-0.5)
                    if recovery or far or (HUD.manualFarmHeight and (point-root.Position).Magnitude>2) then
                        root.CFrame=CFrame.lookAt(point,targetRoot.Position)
                    elseif (targetRoot.Position-root.Position).Magnitude>0.01 then
                        local direction=(targetRoot.Position-root.Position).Unit
                        if root.CFrame.LookVector:Dot(direction)<0.95 then root.CFrame=CFrame.lookAt(root.Position,targetRoot.Position) end
                    end
                end
            end
            HUD.applyHitbox(farmTarget)
            local tool=HUD.pickWeapon(char,hum,now)
            HUD.setText(HUD.farmStatus,recovery or HUD.tryAttack(farmTarget,tool,root,now,fastAttackEnabled))
        end
    else HUD.restoreHitbox(); HUD.setText(HUD.farmStatus,"Procurando NPC valido no raio e filtro...") end
else
    HUD.progress=nil
    if autoFarmEnabled or not HUD.autoNear then HUD.restoreHitbox() end
    if autoFarmEnabled then
        local _,reason=HUD.activity()
        HUD.setText(HUD.farmStatus,"Farm pausado: "..reason)
    elseif not HUD.autoNear then HUD.setText(HUD.farmStatus,"Auto farm desligado.") end
end

    if tpSpeed > 0 and hum.MoveDirection.Magnitude > 0 and not HUD.travelActive and not HUD.seaBusy and not HUD.flying and not farmCanMove and not emFuga and now >= HUD.manualHold then
        root.CFrame += hum.MoveDirection * tpSpeed * math.min(dt, 0.05) * 60
    end


	if noclip then
		for _,v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				if HUD.collisions[v] == nil then HUD.collisions[v] = v.CanCollide end
                v.CanCollide = false
			end
		end
	end

	if not noclip then
        for part, collision in pairs(HUD.collisions) do
            if part.Parent then part.CanCollide = collision end
            HUD.collisions[part] = nil
        end
    end
end)

-- ================= ESP SOB DEMANDA =================
do
    local scanToken = 0
    local watched = {}
    local function watchTool(tool)
        if not tool:IsA("Tool") then return end
        if not watched[tool] then
            local connections={}
            watched[tool]=connections
            connections[1]=tool.AncestryChanged:Connect(function()
                if HUD.alive and fruitESPEnabled and HUD.isWorldFruit(tool) then createFruitESP(tool) end
            end)
            connections[2]=tool.Destroying:Connect(function()
                for _,connection in ipairs(connections) do connection:Disconnect() end
                watched[tool]=nil
            end)
        end
        if HUD.isWorldFruit(tool) then createFruitESP(tool) end
    end
    gui.Destroying:Connect(function()
        for _,connections in pairs(watched) do
            for _,connection in ipairs(connections) do connection:Disconnect() end
        end
        table.clear(watched)
    end)
    local function clearFruitESP()
        for _,connections in pairs(watched) do
            for _,connection in ipairs(connections) do connection:Disconnect() end
        end
        table.clear(watched)
        for tool, entry in pairs(fruitEspObjects) do
            entry.gui:Destroy()
            fruitEspObjects[tool] = nil
        end
    end
    HUD.setFruitESP = function(enabled)
        scanToken += 1
        local token = scanToken
        if not enabled then clearFruitESP(); return end
        -- Uma busca cancelável por ativação, distribuída entre quadros.
        HUD.startJob(function()
            local pending = {workspace}
            local processed = 0
            while #pending > 0 and HUD.alive and fruitESPEnabled and token == scanToken do
                local item = table.remove(pending)
                if item == workspace or item:IsDescendantOf(workspace) then
                    if item:IsA("Tool") then watchTool(item) end
                    for _, child in ipairs(item:GetChildren()) do
                        table.insert(pending,child)
                    end
                end
                processed += 1
                if processed >= 50 then processed = 0; task.wait() end
            end
        end)
    end
    HUD.connect(workspace.DescendantAdded,function(item)
        if not fruitESPEnabled then return end
        local tool = item:IsA("Tool") and item or (item:IsA("BasePart") and item.Parent)
        if tool and tool:IsA("Tool") then watchTool(tool) end
    end)
    local elapsed = 0
    HUD.connect(RunService.Heartbeat,function(dt)
        if not fruitESPEnabled and not ESPAtivo and next(espObjects) == nil then return end
        elapsed += dt
        if elapsed < 0.2 then return end
        elapsed = 0
        local character = player.Character
        local ownRoot = character and character:FindFirstChild("HumanoidRootPart")
        if fruitESPEnabled then
            for tool, entry in pairs(fruitEspObjects) do
                if not HUD.isWorldFruit(tool) or not entry.part:IsDescendantOf(tool) then
                    entry.gui:Destroy()
                    fruitEspObjects[tool] = nil
                else
                    entry.gui.Enabled = ownRoot ~= nil
                    if ownRoot then
                        local info = HUD.fruitInfo(tool)
                        entry.label.TextColor3=HUD.fruitColors[info.rarity]
                        local rarity=info.rarity=="Unknown" and "Desconhecida" or info.rarity
                        HUD.setText(entry.label,info.name.."\n"..math.floor((ownRoot.Position-entry.part.Position).Magnitude).." studs / "..rarity)
                    end
                end
            end
        end
        for plr, bill in pairs(espObjects) do
            local char = plr.Character
            if not ESPAtivo or not plr.Parent or not char or not bill.Parent or bill.Parent ~= char:FindFirstChild("Head") then
                bill:Destroy()
                espObjects[plr] = nil
            end
        end
        if not ESPAtivo then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                local char = plr.Character
                local head = char and char:FindFirstChild("Head")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local sameTeam = player.Team ~= nil and plr.Team == player.Team
                local visible = ownRoot and head and root and hum and hum.Health > 0 and (not espOnlyEnemies or not sameTeam)
                local bill = espObjects[plr]
                if visible then
                    if not bill then
                        bill = Instance.new("BillboardGui")
                        bill.Size = UDim2.fromOffset(240,112)
                        bill.AlwaysOnTop = true
                        bill.Adornee = head
                        bill.Parent = head
                        local text = Instance.new("TextLabel",bill)
                        text.Name = "Info"
                        text.Size = UDim2.new(1,0,0,76)
                        text.BackgroundTransparency = 1
                        text.TextStrokeTransparency = 0
                        text.Font = Enum.Font.GothamMedium
                        text.TextSize = 14
                        local fruitText=Instance.new("TextLabel",bill)
                        fruitText.Name="EquippedFruit"; fruitText.Position=UDim2.fromOffset(0,76)
                        fruitText.Size=UDim2.new(1,0,0,34); fruitText.BackgroundTransparency=1
                        fruitText.TextStrokeTransparency=0; fruitText.Font=Enum.Font.GothamMedium
                        fruitText.TextSize=12; fruitText.TextWrapped=true
                        espObjects[plr] = bill
                    end
                    local fruit=HUD.equippedFruit(char)
                    bill.EquippedFruit.Visible=fruit~=nil
                    if fruit then
                        bill.EquippedFruit.TextColor3=HUD.fruitColors[fruit.rarity]
                        HUD.setText(bill.EquippedFruit,"Equipada: "..fruit.name)
                    end
                    local data = plr:FindFirstChild("Data")
                    local level = data and data:FindFirstChild("Level")
                    bill.Info.TextColor3 = sameTeam and Color3.fromRGB(0,170,255) or Theme.Red
                    bill.Info.Text = plr.Name.."\nHP: "..math.floor(hum.Health).." / LVL: "..(level and tostring(level.Value) or "?").."\n"..math.floor((ownRoot.Position-root.Position).Magnitude).." studs"
                end
                if bill then bill.Enabled = not not visible end
            end
        end
    end)
    if fruitESPEnabled then HUD.setFruitESP(true) end
end

-- ================= TOGGLE MENU ANIMADO NO G & BOTÃO MOBILE =================

local menuOpen = true
local busy = false

-- OPEN_SIZE definido antes da animação
local CLOSED_SIZE = UDim2.new(0,0,0,0)

-- OPEN_TRANSP definido antes da animação
local CLOSED_TRANSP = 1

-- estado inicial (já abre com animação)
frame.Visible = true
frame.Size = CLOSED_SIZE
frame.BackgroundTransparency = 1

local tweenOpen = TweenService:Create(
	frame,
	TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{Size = OPEN_SIZE, BackgroundTransparency = OPEN_TRANSP}
)

local tweenClose = TweenService:Create(
	frame,
	TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	{Size = CLOSED_SIZE, BackgroundTransparency = CLOSED_TRANSP}
)

-- animação inicial
tweenOpen:Play()

-- TECLADO (Botão G)
HUD.connect(UserInputService.InputBegan, function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode[HUD.keys.menu] then
		if busy then return end
		busy = true

		if menuOpen then
			tweenClose:Play()
			tweenClose.Completed:Wait()
			frame.Visible = false
			menuOpen = false
		else
			frame.Visible = true
			tweenOpen:Cancel()
            tweenOpen=TweenService:Create(frame,TweenInfo.new(0),{Size=OPEN_SIZE,BackgroundTransparency=OPEN_TRANSP})
			tweenOpen:Play()
			menuOpen = true
		end

		task.wait(0.05)
		busy = false
	end
end)

-- Botão mobile removido. Abrir/recolher pela tecla G.
-- Iluminação original preservada. Sem destruição de Atmosphere ou ativação de sombras na abertura.
-- ================= ZOOM =================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================= FLY TELEPORT =================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local flying = false
HUD.flying = false
HUD.stopFly = function()
    local wasFlying = flying
    flying, HUD.flying = false, false
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if wasFlying and root then root.Anchored = false end
    if HUD.clearFlightMarker then HUD.clearFlightMarker() end
end
local speed = 180
criarSecao("VOO ALT + M1", 0, tabPlayer)
criarSlider("Velocidade do voo Alt + M1 (studs/s)", 10, 1500, 180, 0, tabPlayer, function(value)
    speed = value
end)

local keys = {
	W=false, A=false, S=false, D=false,
	Space=false, Ctrl=false
}

-- Silhueta local da pose inicial: uma marca por vez, sem colisoes ou scripts.
do
    function HUD.clearFlightMarker()
        if HUD.flightMarker then HUD.flightMarker:Destroy(); HUD.flightMarker = nil end
    end
    function HUD.markFlightStart(character, root)
        HUD.clearFlightMarker()
        local ghost = Instance.new("Model")
        HUD.flightMarker = ghost
        ghost.Name = "PudimHub_FlightOrigin"
        local origin = root.CFrame
        for _, bodyPart in ipairs(character:GetChildren()) do
            if bodyPart:IsA("BasePart") and bodyPart ~= root and bodyPart.Transparency < 1 then
                local pose = bodyPart.CFrame
                local ok, copy = pcall(function() return bodyPart:Clone() end)
                if not ok or not copy then
                    copy = Instance.new("Part")
                    copy.Size = bodyPart.Size
                end
                -- Nao carregar juntas, scripts, texturas ou emissores para o Workspace.
                for _, child in ipairs(copy:GetChildren()) do
                    if child:IsA("DataModelMesh") then
                        for _, nested in ipairs(child:GetChildren()) do nested:Destroy() end
                        if child:IsA("SpecialMesh") then child.TextureId = "" end
                    else child:Destroy() end
                end
                if copy:IsA("MeshPart") then copy.TextureID = "" end
                copy.Name = bodyPart.Name
                copy.Anchored = true
                copy.CanCollide, copy.CanTouch, copy.CanQuery = false, false, false
                copy.CastShadow = false
                copy.Material = Enum.Material.Neon
                copy.Color = Theme.Red
                copy.Transparency = 0.25
                copy.LocalTransparencyModifier = 0
                copy.CFrame = pose
                copy.Parent = ghost
            end
        end
        local anchor = Instance.new("Part")
        anchor.Name = "StartPosition"
        anchor.Size = Vector3.new(0.2, 0.2, 0.2)
        anchor.CFrame = origin
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = false, false, false
        anchor.Parent = ghost
        ghost.PrimaryPart = anchor
        local billboard = Instance.new("BillboardGui", anchor)
        billboard.Name = "FlightOriginLabel"
        billboard.Adornee = anchor
        billboard.Size = UDim2.fromOffset(180, 32)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 3000
        local text = Instance.new("TextLabel", billboard)
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.Text = "INICIO DO VOO"
        text.TextColor3 = Theme.Red
        text.TextStrokeTransparency = 0.25
        text.Font = Enum.Font.GothamBold
        text.TextSize = 13
        local outline = Instance.new("Highlight", ghost)
        outline.Adornee = ghost
        outline.FillColor = Theme.Red
        outline.FillTransparency = 0.65
        outline.OutlineColor = Color3.fromRGB(255, 160, 175)
        outline.OutlineTransparency = 0
        outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        ghost.Parent = workspace
    end
    local clear = Instance.new("TextButton", tabPlayer)
    clear.Size = UDim2.new(1, 0, 0, 42)
    clear.BackgroundColor3 = Theme.Second
    clear.BackgroundTransparency = 0.2
    clear.BorderSizePixel = 0
    clear.Text = "Limpar silhueta do início do voo"
    clear.TextColor3 = Theme.Text
    clear.Font = Enum.Font.GothamMedium
    clear.TextSize = 12
    roundUI(clear)
    clear.Activated:Connect(HUD.clearFlightMarker)
    HUD.connect(player.CharacterRemoving, HUD.clearFlightMarker)
    gui.Destroying:Connect(HUD.clearFlightMarker)
end

local function getFlyRoot()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- ================= INPUT =================
HUD.connect(UserInputService.InputBegan, function(i, gp)
	if gp then return end

	-- ALT pressionado
	if i.KeyCode == Enum.KeyCode.LeftAlt or i.KeyCode == Enum.KeyCode.RightAlt then
		altPressed = true
	end

	-- ALT + CLICK ESQUERDO
	if altPressed and i.UserInputType == Enum.UserInputType.MouseButton1 and not HUD.seaBusy then
        local root = getFlyRoot()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return end
        CancelTeleport("Viagem cancelada pelo comando de voo.")
        if not flying then
            -- Capturar a pose e posicao antes de ancorar ou mover o personagem.
            local ok, err = pcall(HUD.markFlightStart, char, root)
            if not ok then HUD.clearFlightMarker(); warn("PudimHub: falha na silhueta: " .. tostring(err)) end
        end
        flying = not flying
        HUD.flying = flying
        root.Anchored = flying
        if not flying then HUD.clearFlightMarker() end
	end

	if i.KeyCode == Enum.KeyCode.W then keys.W = true end
	if i.KeyCode == Enum.KeyCode.A then keys.A = true end
	if i.KeyCode == Enum.KeyCode.S then keys.S = true end
	if i.KeyCode == Enum.KeyCode.D then keys.D = true end
	if i.KeyCode == Enum.KeyCode.Space then keys.Space = true end
	if i.KeyCode == Enum.KeyCode.LeftControl then keys.Ctrl = true end
end)

HUD.connect(UserInputService.InputEnded, function(i)
	if i.KeyCode == Enum.KeyCode.LeftAlt or i.KeyCode == Enum.KeyCode.RightAlt then
		altPressed = false
	end

	if i.KeyCode == Enum.KeyCode.W then keys.W = false end
	if i.KeyCode == Enum.KeyCode.A then keys.A = false end
	if i.KeyCode == Enum.KeyCode.S then keys.S = false end
	if i.KeyCode == Enum.KeyCode.D then keys.D = false end
	if i.KeyCode == Enum.KeyCode.Space then keys.Space = false end
	if i.KeyCode == Enum.KeyCode.LeftControl then keys.Ctrl = false end
end)


-- ================= LOOP DO FLY =================
HUD.connect(RunService.RenderStepped, function(dt)
	if not flying or HUD.travelActive or HUD.seaBusy then return end

	local root = getFlyRoot()
	if not root then return end

	local cam = workspace.CurrentCamera
    if not cam then return end
	local move = Vector3.zero

	if keys.W then move += cam.CFrame.LookVector end
	if keys.S then move -= cam.CFrame.LookVector end
	if keys.A then move -= cam.CFrame.RightVector end
	if keys.D then move += cam.CFrame.RightVector end
	if keys.Space then move += Vector3.new(0,1,0) end
	if keys.Ctrl then move -= Vector3.new(0,1,0) end

	if move.Magnitude > 0 then
		local dir = move.Unit

		local newPos = root.Position + (dir * speed * math.min(dt, 0.1))

		root.CFrame = CFrame.new(
			newPos,
			newPos + cam.CFrame.LookVector
		)
	else

		root.CFrame = CFrame.new(
			root.Position,
			root.Position + cam.CFrame.LookVector
		)
	end
end)

HUD.connect(player.CharacterAdded, function(char)
	task.wait(1)
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = false
	end
	flying = false
    HUD.flying = false
end)
-- ================= TELEPORTE PRECISO NO CURSOR =================
do
    local cooldownUntil = 0
    local maxDistance = 10000
    local playerAimRadius = 18
    local function boatFor(part)
        local boats = Workspace:FindFirstChild("Boats")
        local current = part
        while current and current ~= Workspace do
            if boats and current.Parent == boats then return current end
            if current:IsA("Model") then
                local name = current.Name:lower()
                if (name:find("boat", 1, true) or name:find("ship", 1, true))
                    and current:FindFirstChildWhichIsA("BasePart", true) then return current end
            end
            current = current.Parent
        end
    end
    local function waterTarget(ray, support, maximum)
        if not support or not support.Parent or math.abs(ray.Direction.Y) < 0.0001 then return end
        local top = support.Position.Y + support.Size.Y / 2
        local distance = (top - ray.Origin.Y) / ray.Direction.Y
        if distance <= 0 or distance > maximum then return end
        local position = ray.Origin + ray.Direction * distance
        local localPoint = support.CFrame:PointToObjectSpace(position)
        if math.abs(localPoint.X) > support.Size.X / 2 or math.abs(localPoint.Z) > support.Size.Z / 2 then return end
        return {Position = position, Normal = Vector3.yAxis, Instance = support,
            Material = Enum.Material.SmoothPlastic, Distance = distance}
    end
    local function landingBlocked(center, size, excluded)
        local probe = Instance.new("Part")
        probe.Name = "PudimHub_TPLandingCheck"
        probe.Anchored = true
        probe.CanCollide, probe.CanTouch, probe.CanQuery = false, false, false
        probe.Transparency = 1
        probe.Size, probe.CFrame = size, center
        local ignore = table.clone(excluded)
        table.insert(ignore, probe)
        local overlap = OverlapParams.new()
        overlap.FilterType = Enum.RaycastFilterType.Exclude
        overlap.FilterDescendantsInstances = ignore
        overlap.RespectCanCollide = true
        overlap.MaxParts = 1
        probe.Parent = Workspace
        local ok, parts = pcall(function() return Workspace:GetPartsInPart(probe, overlap) end)
        probe:Destroy()
        return not ok or #parts > 0
    end
    local function reject(reason)
        HUD.report("TP no cursor", reason)
    end
    HUD.connect(UserInputService.InputBegan, function(input, processed)
        if processed or UserInputService:GetFocusedTextBox()
            or input.KeyCode ~= Enum.KeyCode[HUD.keys.cursor] or os.clock() < cooldownUntil then return end
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then return end
        local cursor = UserInputService:GetMouseLocation()
        for _, object in ipairs(player.PlayerGui:GetGuiObjectsAtPosition(cursor.X, cursor.Y)) do
            if object:IsDescendantOf(frame) and frame.Visible then return end
        end
        cooldownUntil = os.clock() + 0.2
        local excluded = {character}
        local camera = Workspace.CurrentCamera
        if camera then table.insert(excluded, camera) end
        if floor then table.insert(excluded, floor) end
        if HUD.flightMarker then table.insert(excluded, HUD.flightMarker) end
        for _, other in ipairs(Players:GetPlayers()) do
            if other.Character and other.Character ~= character then table.insert(excluded, other.Character) end
        end
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then table.insert(excluded, enemies) end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = excluded
        params.IgnoreWater = false
        params.RespectCanCollide = true
        local function teleportTo(destination)
            CancelTeleport("Viagem cancelada pelo teleporte no cursor.")
            if HUD.stopFly then HUD.stopFly() end
            HUD.manualHold = os.clock() + 1
            if autoFarmEnabled then HUD.farmPaused = true end
            humanoid.Sit = false
            root.CFrame = CFrame.new(destination) * root.CFrame.Rotation
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        -- Uma pequena tolerancia na tela prioriza o jogador, inclusive sem chao sob ele.
        local targetRoot, targetPoint
        local bestPixels, bestDepth = playerAimRadius * playerAimRadius, math.huge
        if camera then
            for _, other in ipairs(Players:GetPlayers()) do
                local model = other.Character
                local targetHum = model and model:FindFirstChildOfClass("Humanoid")
                local candidateRoot = model and model:FindFirstChild("HumanoidRootPart")
                if model ~= character and targetHum and targetHum.Health > 0 and candidateRoot then
                    for _, part in ipairs(model:GetChildren()) do
                        if part:IsA("BasePart") then
                            local point, visible = camera:WorldToScreenPoint(part.Position)
                            if visible and point.Z > 0 then
                                local dx, dy = point.X - cursor.X, point.Y - cursor.Y
                                local pixels = dx * dx + dy * dy
                                if pixels < bestPixels or (pixels == bestPixels and point.Z < bestDepth) then
                                    targetRoot, targetPoint = candidateRoot, part.Position
                                    bestPixels, bestDepth = pixels, point.Z
                                end
                            end
                        end
                    end
                end
            end
        end
        if targetRoot then
            if (targetRoot.Position - root.Position).Magnitude > maxDistance then
                reject("Jogador além do alcance de 10.000 studs."); return
            end
            local direction = targetPoint - camera.CFrame.Position
            local obstruction = Workspace:Raycast(camera.CFrame.Position, direction, params)
            if obstruction and obstruction.Distance < direction.Magnitude - 1 then
                reject("Jogador encoberto por um obstáculo."); return
            end
            local space = OverlapParams.new()
            space.FilterType = Enum.RaycastFilterType.Exclude
            space.FilterDescendantsInstances = excluded
            space.RespectCanCollide = true
            space.MaxParts = 1
            if #Workspace:GetPartBoundsInBox(CFrame.new(targetRoot.Position), root.Size + Vector3.new(1, 0.2, 1), space) > 0 then
                reject("Sem espaço no ponto do jogador."); return
            end
            teleportTo(targetRoot.Position)
            return
        end
        local ray = player:GetMouse().UnitRay
        local rayLength = math.min(15000, (ray.Origin - root.Position).Magnitude + maxDistance)
        local hit = Workspace:Raycast(ray.Origin, ray.Direction * rayLength, params)
        -- A mira visual reconhece pecas decorativas do barco; o pouso exige apoio fisico.
        local visualParams = RaycastParams.new()
        visualParams.FilterType = Enum.RaycastFilterType.Exclude
        visualParams.FilterDescendantsInstances = excluded
        visualParams.IgnoreWater = false
        visualParams.RespectCanCollide = false
        local visual = Workspace:Raycast(ray.Origin, ray.Direction * rayLength, visualParams)
        if visual and boatFor(visual.Instance) and (not hit or visual.Distance <= hit.Distance + 0.1) then hit = visual end
        local platformHit = floorEnabled and waterTarget(ray, floor, rayLength)
        if platformHit and (not hit or platformHit.Distance < hit.Distance) then hit = platformHit end
        if not hit then reject("Nenhuma superfície sob o cursor. Aponte para o chão."); return end
        local boat = hit.Instance ~= floor and boatFor(hit.Instance)
        if boat then
            local bounds, size
            if boat:IsA("Model") then bounds, size = boat:GetBoundingBox()
            elseif boat:IsA("BasePart") then bounds, size = boat.CFrame, boat.Size end
            if bounds then
                local boatParams = RaycastParams.new()
                boatParams.FilterType = Enum.RaycastFilterType.Include
                boatParams.FilterDescendantsInstances = {boat}
                boatParams.RespectCanCollide = true
                local top = bounds.Position.Y + size.Magnitude / 2 + 4
                local deck = Workspace:Raycast(Vector3.new(hit.Position.X, top, hit.Position.Z),
                    Vector3.new(0, -(size.Magnitude + 8), 0), boatParams)
                if not deck then reject("Sem apoio sólido nesse ponto do barco."); return end
                hit = deck
            end
        end
        if (hit.Position - root.Position).Magnitude > maxDistance then
            reject("Ponto além do alcance de 10.000 studs."); return
        end
        if hit.Material == Enum.Material.Water or hit.Normal.Y < 0.6 then
            reject("Aponte para um chão sólido, não água ou parede."); return
        end
        if not boat and hit.Instance ~= floor and hit.Instance:IsA("BasePart") and hit.Instance.Transparency >= 0.95 then
            reject("Superfície invisível; escolha um ponto visível."); return
        end
        local footOffset = humanoid.HipHeight + root.Size.Y / 2
        if humanoid.RigType == Enum.HumanoidRigType.R6 then
            local leg = character:FindFirstChild("Left Leg")
            footOffset = footOffset + (leg and leg:IsA("BasePart") and leg.Size.Y or 2)
        end
        local head = character:FindFirstChild("Head")
        local aboveRoot = root.Size.Y / 2 + (head and head:IsA("BasePart") and head.Size.Y or 2)
        local height = footOffset + aboveRoot
        local destination = hit.Position + Vector3.new(0, footOffset + 0.4, 0)
        local overhead = Workspace:Raycast(hit.Position + Vector3.new(0, 0.1, 0),
            Vector3.new(0, height + 0.3, 0), params)
        if overhead then reject("Sem espaço acima desse ponto."); return end
        local blocked = landingBlocked(
            CFrame.new(hit.Position + Vector3.new(0, height / 2 + 0.4, 0)),
            Vector3.new(math.max(3, root.Size.X), height, math.max(3, root.Size.Z)), excluded)
        if blocked then reject("Espaço apertado ou ocupado; escolha outro ponto."); return end
        teleportTo(destination)
        if boat and hit.Instance:IsA("BasePart") then
            root.AssemblyLinearVelocity = hit.Instance:GetVelocityAtPosition(destination)
        end
    end)
end
-- ================= PAINEL / BUSCA / PREFERÊNCIAS V010 =================
do
    local function textCard(parent, text, height)
        local card = Instance.new("TextLabel", parent)
        card.Size = UDim2.new(1, 0, 0, height or 68)
        card.BackgroundColor3 = Theme.Second
        card.BackgroundTransparency = 0.2
        card.BorderSizePixel = 0
        card.Text = text
        card.TextColor3 = Theme.Text
        card.TextSize = 13
        card.Font = Enum.Font.GothamMedium
        card.TextWrapped = true
        card.TextXAlignment = Enum.TextXAlignment.Left
        roundUI(card, 10)
        local pad = Instance.new("UIPadding", card)
        pad.PaddingLeft = UDim.new(0, 14)
        pad.PaddingRight = UDim.new(0, 14)
        return card
    end
    local function action(parent, text, callback)
        local button = Instance.new("TextButton", parent)
        button.Size = UDim2.new(1, 0, 0, 42)
        button.BackgroundColor3 = Theme.Button
        button.BorderSizePixel = 0
        button.TextColor3 = Theme.Text
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 13
        button.Text = text
        roundUI(button, 8)
        button.Activated:Connect(callback)
        return button
    end

    criarSecao("SEU PERSONAGEM", 0, tabOverview)
    local profileCard=Instance.new("Frame",tabOverview)
    profileCard.Name="PlayerProfile"
    profileCard.Size=UDim2.new(1,0,0,84)
    profileCard.BackgroundColor3=Theme.Second
    profileCard.BackgroundTransparency=0.2
    profileCard.BorderSizePixel=0
    roundUI(profileCard,10)
    local avatar=Instance.new("ImageLabel",profileCard)
    avatar.Name="PlayerAvatar"
    avatar.Size=UDim2.fromOffset(56,56)
    avatar.Position=UDim2.new(0,12,0.5,-28)
    avatar.BackgroundColor3=Theme.Button
    avatar.BorderSizePixel=0
    avatar.ScaleType=Enum.ScaleType.Crop
    avatar.Image=""
    roundUI(avatar,28)
    local avatarEdge=Instance.new("UIStroke",avatar)
    avatarEdge.Color=Theme.Red; avatarEdge.Thickness=1; avatarEdge.Transparency=0.35
    -- Sem texto sobre a foto; o fundo permanece visivel enquanto ela carrega.
    local profile=Instance.new("TextLabel",profileCard)
    profile.Name="PlayerDetails"
    profile.Position=UDim2.fromOffset(80,8)
    profile.Size=UDim2.new(1,-94,1,-16)
    profile.BackgroundTransparency=1
    profile.Text=player.DisplayName.."  (@"..player.Name..")"
    profile.TextColor3=Theme.Text; profile.Font=Enum.Font.GothamMedium; profile.TextSize=13
    profile.TextWrapped=true; profile.TextXAlignment=Enum.TextXAlignment.Left
    -- Consulta assincrona: nao bloqueia a montagem do HUD.
    HUD.startJob(function()
        for attempt=1,3 do
            if not HUD.alive or not avatar.Parent then return end
            local ok,content,ready=pcall(function()
                return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150)
            end)
            if not HUD.alive or not avatar.Parent then return end
            if ok and type(content)=="string" and content~="" then
                avatar.Image=content
                if ready then return end
            end
            if attempt<3 then task.wait(2) end
        end
    end)
    local health = textCard(tabOverview, "Vida: aguardando personagem", 62)
    local track = Instance.new("Frame", health)
    track.Position = UDim2.new(0, 0, 1, -10)
    track.Size = UDim2.new(1, 0, 0, 4)
    track.BackgroundColor3 = Theme.Button
    roundUI(track, 2)
    local healthFill = Instance.new("Frame", track)
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(86, 205, 159)
    healthFill.BorderSizePixel = 0
    roundUI(healthFill, 2)
    local resources = textCard(tabOverview, "Beli: —   |   Fragmentos: —", 62)
    criarSecao("ATALHOS", 0, tabOverview)
    local shortcutCard = textCard(tabOverview, "G  ·  Abrir / recolher menu\nF  ·  Mira jogadores / H  ·  Mira NPCs\nB  ·  Teleporte no cursor\nAlt + clique  ·  Alternar voo", 110)
    textCard(tabOverview, "Movimento: clique ou arraste as barras. Você também pode digitar um valor. O pulo começa em 60.", 78)
    action(tabOverview, "Centralizar janela", function() frame.Position = UDim2.fromScale(0.5, 0.5) end)

    local footer = Instance.new("TextLabel", frame)
    footer.Position = UDim2.new(0, 18, 1, -34)
    footer.Size = UDim2.new(1, -36, 0, 22)
    footer.BackgroundTransparency = 1
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.TextSize = 11
    footer.Font = Enum.Font.GothamMedium
    footer.TextColor3 = Color3.fromRGB(156, 161, 177)
    HUD.setText(footer,"PUDIM HUB  /  V033")
    local sessionStart = os.clock()
    local elapsed, frames = 0, 0
    HUD.connect(RunService.Heartbeat, function(dt)
        elapsed += dt
        frames += 1
        if elapsed < 1.5 then return end
        HUD.setText(shortcutCard,HUD.keys.menu..": menu / "..HUD.keys.players..": mira jogadores / "..HUD.keys.npcs..": mira NPCs\n"..HUD.keys.cursor..": TP cursor / Alt + clique: voo")
        local fps = math.floor(frames / elapsed + 0.5)
        elapsed, frames = 0, 0
        footer.Visible = HUD.status
        local data = player:FindFirstChild("Data")
        local function stat(name)
            local entry = data and data:FindFirstChild(name)
            return entry and tostring(entry.Value) or "—"
        end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local team = player.Team and player.Team.Name or "Sem time"
        HUD.setText(profile,player.DisplayName .. "  (@" .. player.Name .. ")\nNível " .. stat("Level") .. "  /  " .. team)
        HUD.setText(resources,"Beli: " .. stat("Beli") .. "\nFragmentos: " .. stat("Fragments"))
        local ratio = humanoid and math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1) or 0
        HUD.setText(health,humanoid and ("Vida  " .. math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)) or "Aguardando respawn…")
        healthFill.Size = UDim2.fromScale(ratio, 1)
        healthFill.BackgroundColor3 = ratio < 0.3 and Theme.Red or Color3.fromRGB(86,205,159)
        local seconds = math.floor(os.clock() - sessionStart)
        HUD.setText(footer,string.format("%d FPS  /  %d jogadores  /  %02d:%02d nesta sessão  /  %s: menu", fps, #Players:GetPlayers(), math.floor(seconds / 60), seconds % 60,HUD.keys.menu))
    end)

    -- Busca somente na aba atual, sem modificar os valores dos controles.
    local search = Instance.new("TextBox", frame)
    search.Position = UDim2.fromOffset(154, 76)
    search.Size = UDim2.new(1, -166, 0, 34)
    search.BackgroundColor3 = Theme.Second
    search.BorderSizePixel = 0
    search.PlaceholderText = "Buscar nesta aba…"
    search.PlaceholderColor3 = Color3.fromRGB(143,149,169)
    search.Text = ""
    search.TextSize = 13
    search.TextColor3 = Theme.Text
    search.Font = Enum.Font.GothamMedium
    search.ClearTextOnFocus = false
    search.TextXAlignment = Enum.TextXAlignment.Left
    roundUI(search, 8)
    local searchPadding = Instance.new("UIPadding", search)
    searchPadding.PaddingLeft = UDim.new(0, 12)
    local empty = Instance.new("TextLabel", container)
    empty.Size = UDim2.new(1, 0, 0, 56)
    empty.BackgroundTransparency = 1
    empty.Text = "Nenhuma opção encontrada nesta aba."
    empty.TextColor3 = Theme.Text
    empty.Font = Enum.Font.GothamMedium
    empty.TextSize = 12
    empty.Visible = false
    local function normalize(text)
        text = string.lower(text)
        for from, to in pairs({["á"]="a", ["à"]="a", ["ã"]="a", ["â"]="a", ["é"]="e", ["ê"]="e", ["í"]="i", ["ó"]="o", ["ô"]="o", ["õ"]="o", ["ú"]="u", ["ç"]="c", ["Á"]="a", ["Ã"]="a", ["Â"]="a", ["É"]="e", ["Ê"]="e", ["Í"]="i", ["Ó"]="o", ["Ô"]="o", ["Õ"]="o", ["Ú"]="u", ["Ç"]="c"}) do
            text = text:gsub(from, to)
        end
        return text
    end
    local function filter()
        local query = normalize(search.Text):match("^%s*(.-)%s*$")
        local count = 0
        for _, page in ipairs(tabs) do
            for _, row in ipairs(page:GetChildren()) do
                if row:IsA("GuiObject") then
                    local labels = {}
                    if row:IsA("TextLabel") or row:IsA("TextButton") then table.insert(labels, row.Text) end
                    for _, part in ipairs(row:GetDescendants()) do
                        if part:IsA("TextLabel") or part:IsA("TextButton") then table.insert(labels, part.Text) end
                    end
                    local visible = query == "" or string.find(normalize(table.concat(labels, " ")), query, 1, true) ~= nil
                    row.Visible = visible
                    if page == currentTab and visible then count += 1 end
                end
            end
        end
        empty.Position=UDim2.fromOffset(0,currentTab==tabTeleport and 66 or 0)
        empty.Visible = count == 0 and query ~= ""
    end
    search:GetPropertyChangedSignal("Text"):Connect(function()
        filter()
        if currentTab then currentTab.CanvasPosition = Vector2.zero end
    end)
    for _, page in ipairs(tabs) do
        page:GetPropertyChangedSignal("Visible"):Connect(function()
            if page.Visible then
                search.Text = ""
                task.defer(filter)
            end
        end)
    end

    criarSecao("INTERFACE", 0, tabSettings)
    criarSlider("Escala do HUD %", 65, 115, 100, 0, tabSettings, function(value)
        HUD.scale = value
        fitHUD()
    end)
    action(tabSettings, "Mostrar / ocultar informações de sessão", function()
        HUD.status = not HUD.status
        if HUD.preferencesChanged then HUD.preferencesChanged() end
        footer.Visible = HUD.status
    end)
    action(tabSettings, "Centralizar janela", function() frame.Position = UDim2.fromScale(0.5, 0.5) end)
    criarSecao("PREFERÊNCIAS", 0, tabSettings)
    local feedback = textCard(tabSettings, "V033 salva preferencias automaticamente por conta. Abaixo: importar/exportar o arquivo antigo. Valores, botoes ligados/desligados e modo da mira sao restaurados ao abrir.", 88)
    local settingsFile = "PudimHub_UI_v005.json"
    action(tabSettings, "Exportar preferencias antigas", function()
        if type(writefile) ~= "function" then feedback.Text = "Este ambiente não oferece salvamento em arquivo."; return end
        local values = {}
        for key, control in pairs(HUD.sliders) do values[key] = control.get() end
        local ok = pcall(function()
            writefile(settingsFile, HttpService:JSONEncode({version = 1, values = values, status = HUD.status}))
        end)
        feedback.Text = ok and "Preferências salvas. Use Carregar para aplicá-las." or "Não foi possível salvar as preferências."
    end)
    action(tabSettings, "Importar preferencias antigas", function()
        if type(readfile) ~= "function" then feedback.Text = "Este ambiente não oferece leitura de arquivo."; return end
        local ok, saved = pcall(function() return HttpService:JSONDecode(readfile(settingsFile)) end)
        if not ok or type(saved) ~= "table" or saved.version ~= 1 or type(saved.values) ~= "table" then
            feedback.Text = "Nenhuma preferência válida encontrada. Salve primeiro."
            return
        end
        for key, value in pairs(saved.values) do
            local control = HUD.sliders[key]
            if control and type(value) == "number" and value == value and math.abs(value) < math.huge then control.set(value) end
        end
        if type(saved.status) == "boolean" then HUD.status = saved.status end
        if HUD.preferencesChanged then HUD.preferencesChanged() end
        feedback.Text = "Preferências antigas importadas para o autosave."
    end)
    action(tabSettings, "Restaurar TODOS os controles", function()
        -- Executar callbacks reais e atualizar tambem a aparencia dos botoes.
        if HUD.cancelServerSearch then HUD.cancelServerSearch() end
        if HUD.resetExtras then HUD.resetExtras() end
        if HUD.resetCombatSettings then HUD.resetCombatSettings() end
        for _, control in ipairs(HUD.toggles) do control.set(control.default, true) end
        if HUD.resetAim then HUD.resetAim() end
        if HUD.stopFly then HUD.stopFly() end
        CancelTeleport("Controles restaurados. Viagem local cancelada.")
        HUD.restoreHitbox()
        for part, collision in pairs(HUD.collisions) do
            if part.Parent then part.CanCollide = collision end
            HUD.collisions[part] = nil
        end
        for _, control in pairs(HUD.sliders) do control.set(control.default) end
        HUD.farmFilter, HUD.farmPaused = "", false
        if HUD.farmFilterInput then HUD.farmFilterInput.Text = "" end
        farmTarget = nil
        HUD.farmSearchAt, HUD.farmAttackAt, HUD.manualHold = 0, 0, 0
        HUD.setText(HUD.farmStatus,"Auto farm desligado.")
        if HUD.resetSeaSelection then HUD.resetSeaSelection() end
        HUD.status = true
        footer.Visible = true
        search.Text = ""
        frame.Position = UDim2.fromScale(0.5, 0.5)
        for _, page in ipairs(tabs) do page.CanvasPosition = Vector2.zero end
        feedback.Text = "Controles restaurados: ESP, mira, farm e voo desligados. Pulo: 60."
    end)
    HUD.connect(player.CharacterAdded, function(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        HUD.applyJump(humanoid)
    end)
    gui.Destroying:Connect(function()
        HUD.alive = false
        for _, connection in ipairs(HUD.connections) do connection:Disconnect() end
    end)
    -- Botão discreto para recolher, além do G.
    local minimize = Instance.new("TextButton", title)
    minimize.Size = UDim2.fromOffset(30, 30)
    minimize.Position = UDim2.new(1, -38, 0, 17)
    minimize.BackgroundColor3 = Theme.Button
    minimize.Text = "−"
    minimize.TextColor3 = Theme.Text
    minimize.TextSize = 20
    roundUI(minimize, 8)
    subtitle.Position = UDim2.new(1, -192, 0, 20)
    minimize.Activated:Connect(function()
        if busy then return end
        busy = true
        tweenClose:Play()
        tweenClose.Completed:Wait()
        frame.Visible, menuOpen = false, false
        busy = false
    end)
end
-- Remove os objetos criados por esta execução ao substituir a interface.
gui.Destroying:Connect(function()
    HUD.restoreHitbox()
    local wasFlying = flying
    autoFarmEnabled, fastAttackEnabled, flying = false, false, false
    CancelTeleport()
    if floor then floor:Destroy() end
    for _, bill in pairs(espObjects) do bill:Destroy() end
    for _, entry in pairs(fruitEspObjects) do entry.gui:Destroy() end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root and wasFlying then root.Anchored = false end
    for part, collision in pairs(HUD.collisions) do
        if part.Parent then part.CanCollide = collision end
    end
end)
do
    local accent = Instance.new("Frame",frame)
    accent.Position = UDim2.fromOffset(18,62)
    accent.Size = UDim2.new(1,-36,0,1)
    accent.BorderSizePixel = 0
    accent.BackgroundColor3 = Theme.Red
    local gradient = Instance.new("UIGradient",accent)
    gradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.85)})
    for _, page in ipairs(tabs) do
        for _, row in ipairs(page:GetChildren()) do
            if (row:IsA("Frame") or row:IsA("TextButton") or row:IsA("TextBox")) and row.BackgroundTransparency < 1 then
                local edge = Instance.new("UIStroke",row)
                edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                edge.Color = Theme.Red
                edge.Thickness = 1
                edge.Transparency = 0.8
            end
        end
    end
end

-- Ataque proximo: captura limitada, retencao do alvo e sem movimento.
do
    local elapsed=0
    HUD.connect(RunService.Heartbeat,function(dt)
        elapsed=elapsed+dt
        if elapsed<0.05 then return end
        elapsed=0
        if autoFarmEnabled or not HUD.autoNear then HUD.nearTarget=nil; return end
        HUD.safeActive=emFuga
        if HUD.activity()~="LIVRE" then HUD.progress=nil; HUD.restoreHitbox(); return end
        local char=player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health<=0 then HUD.nearTarget=nil; HUD.progress=nil; return end
        local now=os.clock()
        local target=HUD.nearTarget
        if not HUD.validFarmTarget(target,root,now,100) or HUD.bodyDistance(target,root.Position)>HUD.attackReach then
            target=nil; HUD.progress=nil
        end
        if not target and now>=HUD.nearSearchAt then
            HUD.nearSearchAt=now+0.25
            local enemies=workspace:FindFirstChild("Enemies")
            local closest=HUD.attackReach
            if enemies then
                for _,npc in ipairs(enemies:GetChildren()) do
                    if HUD.validFarmTarget(npc,root,now,100) then
                        local distance=HUD.bodyDistance(npc,root.Position)
                        if distance<=closest then target=npc; closest=distance end
                    end
                end
            end
        end
        HUD.nearTarget=target
        HUD.applyHitbox(target)
        if target then
            local result=HUD.observeProgress(target,now)
            if (HUD.farmIgnored[target] or 0)>now then HUD.nearTarget=nil; HUD.restoreHitbox()
            else
                if result then result="Vida do alvo sem reducao; verificando novamente sem mover." end
                result=result or HUD.tryAttack(target,HUD.pickWeapon(char,hum,now),root,now,true)
            end
            HUD.setText(HUD.farmStatus,result)
        else HUD.setText(HUD.farmStatus,"Ataque proximo: aguardando NPC em alcance.") end
    end)
end

-- ================= SERVIDORES PUBLICOS =================
-- https://create.roblox.com/docs/cloud/reference/domains/games
do
    local token, busy, pending, cooldown = 0, false, nil, 0
    local attempted = {[game.JobId] = true}
    local buttons = {}
    local status = Instance.new("TextLabel", tabSistema)
    status.Size = UDim2.new(1, 0, 0, 80)
    status.BackgroundTransparency = 1
    status.TextColor3 = Theme.Text
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 12
    status.TextWrapped = true
    status.Text = "Busca no Sea atual. Menos cheio nao garante vazio. Filtro Brasil indisponivel: pais nao confirmado pela lista publica."
    local function finish(message)
        busy, HUD.serverBusy, pending = false, false, nil
        status.Text = message
        for _, button in ipairs(buttons) do
            button.AutoButtonColor = true
            button.TextTransparency = 0
        end
    end
    HUD.cancelServerSearch = function()
        token = token + 1
        finish("Busca encerrada. Um teleporte ja enviado ao Roblox nao pode ser desfeito por este botao.")
    end
    local function active(id) return HUD.alive and busy and token == id end
    local function getPage(url)
        local requestFn = request or http_request or (syn and syn.request)
        local body
        if type(requestFn) == "function" then
            local response = requestFn({Url = url, Method = "GET"})
            if type(response) ~= "table" then error("Resposta HTTP invalida.") end
            local code = tonumber(response.StatusCode)
            if code == 429 then error("Limite de consultas do Roblox. Aguarde antes de tentar novamente.") end
            if not code or code < 200 or code >= 300 then error("Consulta HTTP recusada: " .. tostring(code)) end
            body = response.Body
        else
            local ok, result = pcall(function() return game:HttpGet(url) end)
            if not ok then error("A lista nao pode ser consultada neste ambiente. Tente novamente mais tarde.") end
            body = result
        end
        local data = HttpService:JSONDecode(body)
        if type(data) ~= "table" or type(data.data) ~= "table" then error("Lista de servidores invalida.") end
        return data
    end
    local function start(mode)
        if busy then return end
        if HUD.seaBusy then status.Text = "Aguarde a viagem entre Seas terminar."; return end
        if os.clock() < cooldown then status.Text = "Aguarde alguns segundos antes de buscar novamente."; return end
        cooldown = os.clock() + 8
        busy, HUD.serverBusy = true, true
        token = token + 1
        local id = token
        for _, button in ipairs(buttons) do button.AutoButtonColor = false; button.TextTransparency = 0.45 end
        status.Text = "Procurando servidores publicos no Sea atual..."
        task.delay(35, function()
            if active(id) then
                token = token + 1
                finish("Tempo limite. A entrada nao foi confirmada; aguarde antes de tentar outra vez.")
            end
        end)
        HUD.startJob(function()
            local ok, err = pcall(function()
                local cursor, candidates, seen = nil, {}, {}
                for page = 1, 3 do
                    if not active(id) then return end
                    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"
                    if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
                    local data = getPage(url)
                    if not active(id) then return end
                    for _, server in ipairs(data.data) do
                        if type(server) == "table" and type(server.id) == "string" and server.id ~= ""
                            and type(server.playing) == "number" and type(server.maxPlayers) == "number"
                            and server.playing >= 0 and server.playing < server.maxPlayers
                            and server.id ~= game.JobId and not attempted[server.id] and not seen[server.id] then
                            seen[server.id] = true
                            table.insert(candidates, server)
                        end
                    end
                    cursor = data.nextPageCursor
                    if type(cursor) ~= "string" or cursor == "" then break end
                    task.wait(0.8)
                end
                if not active(id) then return end
                if #candidates == 0 then finish("Nenhum outro servidor com vaga nas paginas consultadas. Tente mais tarde."); return end
                table.sort(candidates, function(a, b) return a.playing < b.playing end)
                local chosen = mode == "EMPTY" and candidates[1] or candidates[math.random(1, #candidates)]
                attempted[chosen.id] = true
                pending = chosen.id
                CancelTeleport("Viagem local interrompida para trocar de servidor.")
                if HUD.stopFly then HUD.stopFly() end
                HUD.farmPaused = true
                status.Text = "Solicitando entrada: " .. chosen.playing .. "/" .. chosen.maxPlayers .. " jogadores. Regiao desconhecida."
                if HUD.savePreferences then HUD.savePreferences() end
                TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, player)
            end)
            if not ok and active(id) then finish("Falha: " .. tostring(err)) end
        end)
    end
    local function addButton(text, mode)
        local button = Instance.new("TextButton", tabSistema)
        button.Size = UDim2.new(1, 0, 0, 44)
        button.BackgroundColor3 = Theme.DarkRed
        button.BorderSizePixel = 0
        button.TextColor3 = Theme.Text
        button.Font = Enum.Font.GothamBold
        button.TextSize = 12
        button.Text = text
        roundUI(button)
        button.Activated:Connect(function() start(mode) end)
        table.insert(buttons, button)
    end
    addButton("Servidor vazio / menos cheio", "EMPTY")
    addButton("Trocar de servidor", "OTHER")
    HUD.connect(TeleportService.TeleportInitFailed, function(who, result, message, placeId, options)
        if who ~= player or not busy or not pending or placeId ~= game.PlaceId then return end
        if options and options.ServerInstanceId ~= "" and options.ServerInstanceId ~= pending then return end
        token = token + 1
        finish("Entrada recusada: " .. tostring(message) .. ". Clique novamente para tentar outro servidor.")
    end)
    gui.Destroying:Connect(function() token = token + 1; busy = false; HUD.serverBusy = false end)
end

-- Interface e armazenamento: implementacao propria, sem bibliotecas remotas.
do
    local function label(parent, value, height)
        local item=Instance.new("TextLabel",parent)
        item.Size=UDim2.new(1,0,0,height or 52)
        item.BackgroundColor3=Theme.Second
        item.BackgroundTransparency=0.2
        item.TextColor3=Theme.Text
        item.Font=Enum.Font.Gotham
        item.TextSize=12
        item.TextWrapped=true
        item.Text=value
        roundUI(item,8)
        return item
    end
    local function button(parent,value,callback)
        local item=Instance.new("TextButton",parent)
        item.Size=UDim2.new(1,0,0,38)
        item.BackgroundColor3=Theme.Button
        item.TextColor3=Theme.Text
        item.Font=Enum.Font.GothamMedium
        item.TextSize=12
        item.Text=value
        roundUI(item,8)
        HUD.connect(item.Activated,callback)
        return item
    end
    criarSecao("PUDIMHUB / V033",0,tabSistema)
    local activity=label(tabSistema,"Pronto",40)
    local diagnostics=label(tabSistema,HUD.errorText,70)
    local storage=label(tabSettings,HUD.storageText,55)
    HUD.accent=1
    local function accent(index)
        local oldRed,oldDark=Theme.Red,Theme.DarkRed
        HUD.accent=index==2 and 2 or 1
        Theme.Red=HUD.accent==2 and Color3.fromRGB(210,22,65) or Color3.fromRGB(240,30,55)
        Theme.DarkRed=HUD.accent==2 and Color3.fromRGB(75,8,30) or Color3.fromRGB(95,10,25)
        for _,item in ipairs(frame:GetDescendants()) do
            if item:IsA("GuiObject") then
                if item.BackgroundColor3==oldRed then item.BackgroundColor3=Theme.Red
                elseif item.BackgroundColor3==oldDark then item.BackgroundColor3=Theme.DarkRed end
                if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
                    if item.TextColor3==oldRed then item.TextColor3=Theme.Red end
                end
            elseif item:IsA("UIStroke") and item.Color==oldRed then item.Color=Theme.Red end
        end
    end
    local accentButton=button(tabSettings,"",function()
        accent(HUD.accent==1 and 2 or 1)
        if HUD.preferencesChanged then HUD.preferencesChanged() end
    end)
    local watchButton
    watchButton=button(tabTeleport,"",function()
        HUD.watchEvents=not HUD.watchEvents
        if HUD.preferencesChanged then HUD.preferencesChanged() end
    end)
    local eventLabel=label(tabTeleport,"Observador desligado. Somente objetos carregados neste cliente.",66)
    local keyInputs={}
    criarSecao("ATALHOS PERSONALIZADOS",0,tabSettings)
    for _,entry in ipairs({{"menu","Menu"},{"players","Mira jogadores"},{"npcs","Mira NPCs"},{"cursor","TP cursor"}}) do
        local id,caption=entry[1],entry[2]
        local box=Instance.new("TextBox",tabSettings)
        box.Size=UDim2.new(1,0,0,36)
        box.BackgroundColor3=Theme.Second
        box.TextColor3=Theme.Text
        box.Font=Enum.Font.Gotham
        box.TextSize=12
        box.ClearTextOnFocus=true
        box.Text=caption..": "..HUD.keys[id]
        box.PlaceholderText=caption..": digite uma letra"
        roundUI(box,8)
        keyInputs[id]={box=box,caption=caption}
        HUD.connect(box.FocusLost,function()
            local key=box.Text:upper():match("^%s*([A-Z])%s*$")
            local allowed=key and not string.find("WASD",key,1,true)
            for other,value in pairs(HUD.keys) do if other~=id and value==key then allowed=false end end
            if allowed then HUD.keys[id]=key; if HUD.preferencesChanged then HUD.preferencesChanged() end
            else HUD.report("Atalho","Use uma letra livre; W/A/S/D ficam reservados para movimento.") end
            box.Text=caption..": "..HUD.keys[id]
        end)
    end
    criarSlider("Transparencia do painel %",0,65,18,0,tabSettings,function(value)
        OPEN_TRANSP=value/100
        frame.BackgroundTransparency=OPEN_TRANSP
    end)
    local file="PudimHub_"..tostring(player.UserId).."_v019.json"
    local enabled=type(readfile)=="function" and type(writefile)=="function"
    local ready,dirty,due,revision=false,false,0,0
    local writing=false
    local function finite(n) return type(n)=="number" and n==n and math.abs(n)<1e8 end
    function HUD.preferencesChanged()
        if not ready then return end
        revision=revision+1; dirty=true; due=os.clock()+0.8
    end
    local function snapshot()
        local values,toggles={},{}
        for key,control in pairs(HUD.sliders) do values[key]=control.get() end
        for _,control in ipairs(HUD.toggles) do toggles[control.key]=control.get() end
        local p=frame.Position
        return {version=1,values=values,toggles=toggles,aimMode=HUD.savedAimMode,keys=HUD.keys,favorites=HUD.favorites,
            watchEvents=HUD.watchEvents,status=HUD.status,filter=HUD.farmFilter,accent=HUD.accent,
            weapon=HUD.weaponName,aimFilter=HUD.aimFilter,aimPriority=HUD.aimPriority,
            position={p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset}}
    end
    local function save()
        if not enabled or not dirty or writing then return end
        writing=true
        local current=revision
        local ok,err=pcall(function() writefile(file,HttpService:JSONEncode(snapshot())) end)
        writing=false
        if ok then dirty=revision~=current; HUD.storageText="Preferencias salvas automaticamente • "..os.date("%H:%M:%S")
        else due=os.clock()+5; HUD.storageText="Falha ao salvar; nova tentativa em 5s."; HUD.report("Arquivo",err) end
    end
    HUD.savePreferences=save
    local function apply(saved)
        if type(saved)~="table" or saved.version~=1 or type(saved.values)~="table" then return false end
        for key,value in pairs(saved.values) do
            local control=HUD.sliders[key]
            if control and finite(value) then control.set(value) end
        end
        if type(saved.keys)=="table" then
            local candidate,seen={},{}
            for id,default in pairs(HUD.keys) do
                local key=saved.keys[id]
                if type(key)~="string" or not key:match("^[A-Z]$") or key:find("[WASD]") or seen[key] then candidate=nil; break end
                candidate[id]=key; seen[key]=true
            end
            if candidate then HUD.keys=candidate end
        end
        if type(saved.favorites)=="table" then
            for sea,entries in pairs(HUD.islandsBySea) do
                for _,entry in ipairs(entries) do
                    local key=tostring(sea)..":"..entry.nome
                    if saved.favorites[key]==true then HUD.favorites[key]=true end
                end
            end
        end
        HUD.light=true; HUD.watchEvents=saved.watchEvents==true
        accent(saved.accent)
        HUD.status=saved.status~=false
        if type(saved.filter)=="string" and #saved.filter<=100 then
            HUD.farmFilter=saved.filter
            if HUD.farmFilterInput then HUD.farmFilterInput.Text=saved.filter end
        end
        if type(saved.weapon)=="string" and #saved.weapon<=100 then HUD.weaponName=saved.weapon end
        if type(saved.aimFilter)=="string" and #saved.aimFilter<=100 then HUD.aimFilter=saved.aimFilter:lower() end
        HUD.aimPriority=saved.aimPriority=="Distancia" and "Distancia" or "Tela"
        local p=saved.position
        if type(p)=="table" and finite(p[1]) and finite(p[2]) and finite(p[3]) and finite(p[4]) then
            frame.Position=UDim2.new(math.clamp(p[1],0,1),math.clamp(p[2],-2000,2000),math.clamp(p[3],0,1),math.clamp(p[4],-2000,2000))
        end
        -- Ativa os controles depois de restaurar valores, filtros e arma.
        if type(saved.toggles)=="table" then
            for _,control in ipairs(HUD.toggles) do
                local value=saved.toggles[control.key]
                if type(value)=="boolean" then control.set(value,true) end
            end
        end
        if saved.aimMode==false or saved.aimMode=="NPC" or saved.aimMode=="PLAYER" then
            HUD.restoreAimMode(saved.aimMode)
        end
        return true
    end
    if enabled then
        local exists=true
        if type(isfile)=="function" then local ok,value=pcall(isfile,file); if ok then exists=value end end
        if exists then
            local ok,raw=pcall(readfile,file)
            if ok then
                local decoded,saved=pcall(function() return HttpService:JSONDecode(raw) end)
                local applied,valid=false,false
                if decoded then applied,valid=pcall(apply,saved) end
                if not applied or not valid then enabled=false; HUD.storageText="Arquivo invalido preservado; autosave desativado."
                else HUD.storageText="Preferencias da conta carregadas." end
            else HUD.storageText="Autosave pronto; sera criado ao alterar preferencias." end
        else HUD.storageText="Autosave pronto; sera criado ao alterar preferencias." end
    else HUD.storageText="Sem readfile/writefile: preferencias so nesta execucao." end
    for id,item in pairs(keyInputs) do item.box.Text=item.caption..": "..HUD.keys[id] end
    tweenOpen:Cancel()
    frame.Size=OPEN_SIZE
    frame.BackgroundTransparency=OPEN_TRANSP
    ready=true
    local function clampWindow()
        local cam=workspace.CurrentCamera
        if not cam then return end
        local size=cam.ViewportSize
        local half=Vector2.new(300*hudScale.Scale,300*hudScale.Scale)
        local p=frame.Position
        frame.Position=UDim2.fromOffset(math.clamp(p.X.Scale*size.X+p.X.Offset,half.X,math.max(half.X,size.X-half.X)),
            math.clamp(p.Y.Scale*size.Y+p.Y.Offset,half.Y,math.max(half.Y,size.Y-half.Y-40)))
    end
    clampWindow()
    HUD.connect(frame:GetPropertyChangedSignal("Position"),HUD.preferencesChanged)
    HUD.connect(UserInputService.InputEnded,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then clampWindow() end
    end)
    HUD.resetExtras=function()
        HUD.keys={menu="G",players="F",npcs="H",cursor="B"}
        HUD.favorites={}; HUD.light=true; HUD.watchEvents=false
        accent(1)
        for id,item in pairs(keyInputs) do item.box.Text=item.caption..": "..HUD.keys[id] end
        if HUD.refreshIslands then HUD.refreshIslands() end
        HUD.preferencesChanged()
    end
    local elapsed,eventElapsed=0,0
    HUD.connect(RunService.Heartbeat,function(dt)
        elapsed=elapsed+dt; eventElapsed=eventElapsed+dt
        if elapsed<0.5 then return end
        elapsed=0
        if dirty and os.clock()>=due then save() end
        local _,description=HUD.activity()
        HUD.setText(activity,description)
        HUD.setText(diagnostics,HUD.errorText)
        HUD.setText(storage,HUD.storageText)
        HUD.setText(accentButton,"Cor do HUD: "..(HUD.accent==1 and "Vermelho clássico" or "Rubi"))
        HUD.setText(watchButton,"Observar eventos carregados: "..(HUD.watchEvents and "Sim" or "Não"))
        shadow.Visible=false
        if not HUD.watchEvents then HUD.setText(eventLabel,"Observador desligado. Somente objetos carregados neste cliente.")
        elseif eventElapsed>=3 then
            eventElapsed=0
            local origin=workspace:FindFirstChild("_WorldOrigin")
            local locations=origin and origin:FindFirstChild("Locations")
            local map=workspace:FindFirstChild("Map")
            local found={}
            for _,entry in ipairs(HUD.islandsBySea[HUD.currentSea] or {}) do
                if entry.event then
                    for _,alias in ipairs(entry.aliases or {entry.nome}) do
                        if (locations and locations:FindFirstChild(alias)) or (map and map:FindFirstChild(alias)) then
                            table.insert(found,entry.nome); break
                        end
                    end
                end
            end
            HUD.setText(eventLabel,not HUD.currentSea and "Escolha o Sea para observar eventos." or #found>0 and "Carregados: "..table.concat(found,", ") or "Nenhum evento observado localmente. Isso nao confirma ausencia no servidor.")
        end
    end)
    gui.Destroying:Connect(function()
        save()
        for job in pairs(HUD.jobs) do pcall(task.cancel,job) end
        table.clear(HUD.jobs)
    end)
end

-- Estilo compartilhado. Atua apenas nos controles deste HUD.
do
    local styled=setmetatable({}, {__mode="k"})
    local function style(button)
        if not HUD.alive or not button:IsDescendantOf(frame) or not button:IsA("TextButton") or styled[button] then return end
        -- Area invisivel para arrastar sliders: conservar a geometria e transparencia.
        if button.BackgroundTransparency>=1 and button.Text=="" then return end
        styled[button]=true
        button.BorderSizePixel=0
        button.AutoButtonColor=false
        button.Font=Enum.Font.GothamMedium
        if button.Size.X.Scale>0 and button.Size.Y.Scale==0 and button.Size.Y.Offset>=38 then
            button.Size=UDim2.new(button.Size.X.Scale,button.Size.X.Offset,0,38)
            button.TextSize=12
            button.TextWrapped=true
        end
        local teamButton=button==marine or button==pirate
        button.BackgroundTransparency=teamButton and 0.72 or 0.12
        -- As cores de selecao, alerta e mira continuam sob controle das funcoes.
        local selected=tabButtons[currentTab]==button or button.Text:find("[x]",1,true)
            or (button.Text:find("Ligado",1,true) and not button.Text:find("Desligado",1,true))
        if not selected and (button.BackgroundColor3==Theme.Second or button.BackgroundColor3==Theme.DarkRed) then
            button.BackgroundColor3=Theme.Button
        end
        local corner=button:FindFirstChildOfClass("UICorner")
        if not corner then corner=Instance.new("UICorner",button) end
        corner.CornerRadius=UDim.new(0,8)
        local edge=button:FindFirstChildOfClass("UIStroke")
        if not edge then edge=Instance.new("UIStroke",button) end
        edge.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        edge.Thickness=1
        edge.Color=teamButton and button.BackgroundColor3 or Theme.Red
        edge.Transparency=0.82
        local hovering,pressed=false,false
        local function feedback()
            edge.Color=teamButton and button.BackgroundColor3 or Theme.Red
            edge.Transparency=pressed and 0.2 or hovering and 0.45 or 0.82
        end
        button.MouseEnter:Connect(function() hovering=true; feedback() end)
        button.MouseLeave:Connect(function() hovering=false; pressed=false; feedback() end)
        button.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then pressed=true; feedback() end
        end)
        button.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then pressed=false; feedback() end
        end)
    end
    for _,item in ipairs(frame:GetDescendants()) do style(item) end
    HUD.connect(frame.DescendantAdded,function(item)
        if item:IsA("TextButton") then task.defer(function() style(item) end) end
    end)
end

do
    local function button(parent,text,callback)
        local b=Instance.new("TextButton",parent)
        b.Size=UDim2.new(1,0,0,38); b.BackgroundColor3=Theme.Button
        b.TextColor3=Theme.Text; b.TextSize=12; b.Font=Enum.Font.GothamMedium
        b.Text=text; roundUI(b,8); HUD.connect(b.Activated,callback)
        return b
    end
    local weapon
    local function updateWeapon()
        weapon.Text="Arma do farm: "..(HUD.weaponName=="" and "Automatica" or HUD.weaponName)
    end
    weapon=button(tabFarm,"",function()
        local names,seen={""},{}
        local containers={}
        if player.Character then table.insert(containers,player.Character) end
        local backpack=player:FindFirstChildOfClass("Backpack")
        if backpack then table.insert(containers,backpack) end
        for _,container in ipairs(containers) do
            for _,tool in ipairs(container:GetChildren()) do
                if HUD.isCombatTool(tool) and not seen[tool.Name] then
                    seen[tool.Name]=true; table.insert(names,tool.Name)
                end
            end
        end
        table.sort(names)
        local index=table.find(names,HUD.weaponName) or 1
        HUD.weaponName=names[index%#names+1]
        HUD.progress=nil; HUD.equipAt=0
        updateWeapon(); HUD.preferencesChanged()
    end)
    updateWeapon()
    local filter=Instance.new("TextBox",tabAimbot)
    filter.Size=UDim2.new(1,0,0,38); filter.BackgroundColor3=Theme.Second
    filter.TextColor3=Theme.Text; filter.Font=Enum.Font.Gotham; filter.TextSize=12
    filter.PlaceholderText="Filtrar NPC/boss por nome (vazio = todos)"
    filter.Text=HUD.aimFilter; filter.ClearTextOnFocus=false; roundUI(filter,8)
    HUD.connect(filter.FocusLost,function()
        HUD.aimFilter=filter.Text:lower():match("^%s*(.-)%s*$"):sub(1,100)
        filter.Text=HUD.aimFilter
        if HUD.clearAimTarget then HUD.clearAimTarget("Filtro alterado") end
        HUD.preferencesChanged()
    end)
    local priority
    local function updatePriority() priority.Text="Novo alvo: "..(HUD.aimPriority=="Tela" and "Centro da tela" or "Mais perto") end
    priority=button(tabAimbot,"",function()
        HUD.aimPriority=HUD.aimPriority=="Tela" and "Distancia" or "Tela"
        updatePriority(); HUD.preferencesChanged()
    end)
    updatePriority()
    HUD.resetCombatSettings=function()
        HUD.weaponName=""; HUD.aimFilter=""; HUD.aimPriority="Tela"
        filter.Text=""; updateWeapon(); updatePriority(); HUD.resetCombatExtras()
    end
    HUD.connect(player.CharacterRemoving,function() HUD.resetCombatExtras() end)
end
