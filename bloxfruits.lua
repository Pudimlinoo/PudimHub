-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Pudimlinoo/PudimHub/main/script.lua"))()

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
    if HUD.chestBusy then return "BAU", "Bau Farm ativo" end
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

-- Cabeçalho e arraste com mouse
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
local dragging, dragStart, startPos
title.Active = true
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos = true, input.Position, frame.Position
    end
end)
local dragChanged = HUD.connect(UserInputService.InputChanged, function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
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
HUD.tabBau = createTab("Bau Farm")
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    if HUD.chestBusy then
        HUD.stopChest("Parado para viagem. Clique novamente no destino.")
        travelStatus.Text = "Parando Bau Farm; aguarde e clique no destino novamente."
        return
    end
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
                if HUD.stopChest then HUD.stopChest("Interrompido pelo Auto Safe.") end
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

    if not HUD.chestBusy and tpSpeed > 0 and hum.MoveDirection.Magnitude > 0 and not HUD.travelActive and not HUD.seaBusy and not HUD.flying and not farmCanMove and not emFuga and now >= HUD.manualHold then
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

-- ================= TOGGLE MENU ANIMADO NO G =================

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

-- Abrir/recolher pela tecla G.
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
        if HUD.chestBusy then HUD.stopChest("Parado para voo. Use Alt + clique novamente."); return end
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
            if HUD.chestBusy then HUD.stopChest("Parado para teleporte. Repita o comando."); return end
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


-- ================= BAU FARM / MOTOR INTEGRADO =================
do
    local page = HUD.tabBau
    local settings = {speed = 255, visuals = false, discovery = true}
    local session
    local function runEngine(bridge)
-- Dynamic CanTouch farmer with a discovery pass and persistent streaming memory.
local SPEED = 190 -- Fallback horizontal speed on foot in studs per second.
local SPEED_MIN = 250 -- Minimum sinusoidal speed in studs per second.
local SPEED_MAX = 259.9 -- Maximum sinusoidal speed in studs per second.
local SPEED_PERIOD = 0.2 -- Complete sinusoidal cycle period in seconds (5 Hz).
local EFFECTIVE_AVG_SPEED = (SPEED_MAX + SPEED_MIN) * 0.5 -- 254.95 studs/s nominal average

local BOAT_PURCHASE_RANGE = 450
local BOAT_APPROACH_RANGE = 420 -- Margin for dealer position offsets.
local MIN_ROOT_Y = 2.0 -- Strict altitude floor (keeps boat above waterline at all times).
local MAX_TRAVEL_SECONDS = 180
local LOAD_UI = false
local SHOW_ROUTE_TRACERS = true
local SHOW_HITBOX_VISUALIZER = true -- Gold outlines for chest targets, including the discovery pass.
local REWARD_SEA = bridge.sea -- Set to 1, 2, or 3 for your current Sea.
local ESTIMATED_PICKUP_SECONDS = 0.03
local LOOKAHEAD_STOPS = 4
local MAP_OUTLIER_DISTANCE = 10000 -- Ignore very distant spawns when fitting the chest map.
local DISCOVERY_RUN = bridge.discovery -- Discover through known chest locations once; dealers are only for getting a boat.
local DISCOVERY_RADIUS = 200 -- Nearby discovery seeds share one streaming stop.
local STREAM_TIMEOUT = 2 -- Bound each streaming request; no parallel request flood.

-- Chest trigger geometry
local HITBOX_SIZE = Vector3.new(100, 100, 100)
local HITBOX_HALF_EXTENT = 50 -- Start at the face of the 100x100x100 trigger, with no 5-stud inset.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
while not player do
    task.wait()
    player = Players.LocalPlayer
end
print("[Chest Farmer] Script started")

-- Sinusoidal 3D Speed Generator (250 - 259.9 studs/s) Synchronized with Server Clock
local function getSinusoidalSpeed(serverTime)
    local mid = (SPEED_MAX + SPEED_MIN) * 0.5 -- 254.95
    local amp = (SPEED_MAX - SPEED_MIN) * 0.5 -- 4.95
    local omega = (2 * math.pi) / SPEED_PERIOD
    local serverTimeCycle = serverTime % SPEED_PERIOD
    return mid + amp * math.sin(serverTimeCycle * omega)
end

local C = {
    Speed = SPEED,
    BoatSpeed = EFFECTIVE_AVG_SPEED,
    MinRootY = MIN_ROOT_Y,
    PollSeconds = 0.05,
    SweepMargin = 5, -- Continue a short distance past the hitbox face for touch registration.
    MinimumTouchDepth = 4,
    ArrivalDistance = 4,
    PendingConfirmSeconds = 3,
    CharacterTimeout = 15,
    ChestFailureCooldown = 10,
    MaxChestCooldown = 120,
    MatchRadius = 1,
    ObserveSeconds = 0.5, -- Fallback polling; CanTouch changes also update state immediately.
    ReplanSeconds = 1,
    SwitchGain = 1.25,
    MinimumCommitSeconds = 1.5,
    FinishDistance = 30,
    BeamWidth = 8,
    BranchWidth = 8,
    PlanBudgetSeconds = 0.0015,
    MapRefreshSeconds = 0.5,
    Debug = true,
}

-- Loaded CanTouch is authoritative. Timers predict only known, unloaded chests.
local gradeBySpawnName = {Chest1 = "Silver", Chest2 = "Gold", Chest3 = "Diamond"}
local chestEconomy = {
    Silver = {respawn = 180, rewards = {{250, 420}, {500, 1000}, {1000, 1695}}},
    Gold = {respawn = 360, rewards = {{600, 1100}, {2300, 3120}, {3875, 5200}}},
    Diamond = {respawn = 720, rewards = {{1500, 3000}, {5000, 7250}, {8000, 12250}}},
}
local function gradeOf(record) return gradeBySpawnName[record.name] or "Gold" end
local function economyOf(record) return chestEconomy[gradeOf(record)] end
local function respawnOf(record) return record.respawnEstimate or (gradeBySpawnName[record.name] and economyOf(record).respawn) end
local function enforceAltitudeFloor(position)
    if position.Y >= C.MinRootY then return position end
    return Vector3.new(position.X, C.MinRootY, position.Z)
end

-- CALCULATED LEG SPEED TRACKER
local legHistory = {}
local maxLegHistory = 15
local avgLegSpeed = 0
local legHistoryMode = nil
local measuredMotion = {}

local function recordLegPerformance(distance, timeTaken, mode)
    if timeTaken <= 0.02 or distance <= 4.0 then return end
    if legHistoryMode ~= mode then
        table.clear(legHistory)
        legHistoryMode = mode
    end
    table.insert(legHistory, {distance = distance, time = timeTaken})
    if #legHistory > maxLegHistory then
        table.remove(legHistory, 1)
    end
    local totalDistance, totalTime = 0, 0
    for _, leg in ipairs(legHistory) do
        totalDistance += leg.distance
        totalTime += leg.time
    end
    avgLegSpeed = totalDistance / totalTime
    measuredMotion[mode] = {speed = avgLegSpeed, samples = #legHistory}
end

-- ROUTE PLANNER (Direct 3D Euclidean Distance)
local Planner = {}
function Planner.travelSeconds(a, b, speed3D)
    local dist3D = (b - a).Magnitude
    local mode = speed3D == C.Speed and "foot" or "boat"
    local observed = measuredMotion[mode]
    local calibrated = speed3D
    if observed and observed.samples >= 3 then
        calibrated = math.clamp(observed.speed, speed3D * 0.7, speed3D * 1.1)
    end
    return dist3D / calibrated
end

function Planner.sweepPath(node, fromPosition, margin)
    local center = enforceAltitudeFloor(node.position)
    local half = node.halfSize or Vector3.new(HITBOX_HALF_EXTENT, HITBOX_HALF_EXTENT, HITBOX_HALF_EXTENT)
    -- Coordinate clamping gives the nearest point on the shared trigger box,
    -- rather than intersecting a longer ray aimed at the chest's center.
    local entryPoint = Vector3.new(
        math.clamp(fromPosition.X, center.X - half.X, center.X + half.X),
        math.clamp(fromPosition.Y, center.Y - half.Y, center.Y + half.Y),
        math.clamp(fromPosition.Z, center.Z - half.Z, center.Z + half.Z))
    local inward = center - entryPoint
    local direction = inward.Magnitude > 0.001 and inward.Unit or Vector3.new(0, 0, -1)
    local exitPoint = entryPoint + direction * (margin + 6)
    -- Include the arrival tolerance so stopping short still leaves four studs inside.
    -- Thin shared regions use their center, the deepest point common to all members.
    local depth = C.MinimumTouchDepth + C.ArrivalDistance
    local inset = Vector3.new(math.min(depth, half.X), math.min(depth, half.Y), math.min(depth, half.Z))
    exitPoint = Vector3.new(
        math.clamp(exitPoint.X, center.X - half.X + inset.X, center.X + half.X - inset.X),
        math.clamp(exitPoint.Y, center.Y - half.Y + inset.Y, center.Y + half.Y - inset.Y),
        math.clamp(exitPoint.Z, center.Z - half.Z + inset.Z, center.Z + half.Z - inset.Z))

    return enforceAltitudeFloor(entryPoint), center, enforceAltitudeFloor(exitPoint)
end

function Planner.leg(position, node, startAt, now, options)
    local entry, _, exit = Planner.sweepPath(node, position, options.sweepMargin)
    local travel = options.travelEstimator and options.travelEstimator(position, entry)
        or Planner.travelSeconds(position, entry, options.speed)
    if travel > options.maxTravel then return nil end
    if node.readyAt and node.readyAt > startAt + travel then return nil end
    local sweepSeconds = options.travelEstimator(entry, exit)
    return {seconds = math.max(0.01, travel + sweepSeconds + options.service),
        probability = node.reliability, exitPosition = exit}
end

local function better(a, b)
    if math.abs(a.score - b.score) > 1e-9 then return a.score > b.score end
    if math.abs(a.elapsed - b.elapsed) > 1e-9 then return a.elapsed < b.elapsed end
    return a.first.id < b.first.id
end

local function keepBest(list, entry, limit)
    local index = #list + 1
    for i, old in ipairs(list) do if better(entry, old) then index = i; break end end
    if index <= limit then
        table.insert(list, index, entry)
        if #list > limit then table.remove(list) end
    end
end

function Planner.plan(position, nodes, now, options, forcedFirstId)
    local beam = {{position = position, elapsed = 0, reward = 0, visited = {}, route = {}}}
    local best
    local deadline = options.budget and (os.clock() + options.budget)
    -- Examine every first stop once, then bound deeper expansion by the CPU budget.
    local roots = {}
    for _, node in ipairs(nodes) do
        if not forcedFirstId or node.id == forcedFirstId then
            local leg = Planner.leg(position, node, now, now, options)
            if leg then
                local reward = node.value * leg.probability
                keepBest(roots, {position = leg.exitPosition, first = node, elapsed = leg.seconds,
                    reward = reward, score = reward / (leg.seconds + options.smoothing),
                    visited = {[node.id] = true}, route = {node}}, options.width)
            end
        end
    end
    if #roots == 0 then return nil end
    beam, best = roots, roots[1]
    for depth = 2, options.depth do
        local expanded = {}
        for _, state in ipairs(beam) do
            if depth > 1 and deadline and os.clock() >= deadline then return best end
            local branches = {}
            local exhausted = false
            for nodeIndex, node in ipairs(nodes) do
                if not state.visited[node.id] and (depth > 1 or not forcedFirstId or node.id == forcedFirstId) then
                    local leg = Planner.leg(state.position, node, now + state.elapsed, now, options)
                    if leg then
                        local elapsed = state.elapsed + leg.seconds
                        local reward = state.reward + node.value * leg.probability
                        local entry = {
                            position = leg.exitPosition, first = state.first or node,
                            elapsed = elapsed, reward = reward,
                            score = reward / (elapsed + options.smoothing),
                            parent = state, node = node,
                        }
                        keepBest(branches, entry, options.branch)
                    end
                end
                if nodeIndex % 16 == 0 and deadline and os.clock() >= deadline then
                    exhausted = true
                    break
                end
            end
            for _, entry in ipairs(branches) do
                entry.visited = table.clone(entry.parent.visited)
                entry.visited[entry.node.id] = true
                entry.route = table.clone(entry.parent.route)
                table.insert(entry.route, entry.node)
                entry.parent, entry.node = nil, nil
                keepBest(expanded, entry, options.width)
                if not best or better(entry, best) then best = entry end
            end
            if exhausted then return best end
        end
        if #expanded == 0 then break end
        beam = expanded
    end
    return best
end

-- DEALER & BOAT CORE
local dealerList, lastDealerScan = {}, -math.huge
local ownedBoat = nil

local function rememberDealer(npc)
    if not (npc:IsA("Model") or npc:IsA("BasePart"))
        or not npc.Name:lower():gsub("%s+", ""):find("boatdealer", 1, true) then return end
    local folder = workspace:FindFirstChild("NPCs")
    if not folder or not npc:IsDescendantOf(folder) then return end
    local position = npc:IsA("Model") and npc:GetPivot().Position or npc.Position
    for _, dealer in ipairs(dealerList) do
        if (dealer.position - position).Magnitude <= 5 then
            dealer.instance, dealer.position, dealer.name = npc, position, npc.Name
            return
        end
    end
    table.insert(dealerList, {instance = npc, position = position, name = npc.Name})
end

local function scanDealers(force)
    local now = workspace:GetServerTimeNow()
    if not force and now - lastDealerScan < 3 then return end
    lastDealerScan = now
    for i = #dealerList, 1, -1 do
        local dealer = dealerList[i]
        if dealer.instance and not dealer.instance:IsDescendantOf(workspace) then
            dealer.instance = nil
        end
    end
end

local function boatSeat(boat)
    if not boat or not boat.Parent then return nil end
    local seat = boat:FindFirstChild("VehicleSeat", true)
    return seat and seat:IsA("VehicleSeat") and seat or nil
end

local function boatBelongsToPlayer(boat)
    local seat = boatSeat(boat)
    if seat and seat.Occupant and seat.Occupant.Parent == player.Character then return true end
    local owner = boat:FindFirstChild("Owner", true)
    if not owner or not owner:IsA("ValueBase") then return false end
    local value = owner.Value
    return value == player or value == player.Name or value == player.UserId
        or tostring(value) == tostring(player.UserId)
end

-- CHARACTER & VELOCITY HELPERS
local function parts()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if char and char:IsDescendantOf(workspace) and root and hum and hum.Health > 0 then
        return char, root, hum
    end
end

local function getLiveVelocity()
    local char, root, hum = parts()
    if not char or not root then return 0 end
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local motionPart = hum.SeatPart.AssemblyRootPart or hum.SeatPart
        local vel = motionPart.AssemblyLinearVelocity or motionPart.Velocity
        return vel.Magnitude
    else
        local vel = root.AssemblyLinearVelocity or root.Velocity
        return vel.Magnitude
    end
end

-- UI CREATION
local playerGui = player:FindFirstChildOfClass("PlayerGui")
local GUI_NAME = "PudimHub_BauEngine"
local globalEnvironment = {} -- lifecycle owned by this hub
if globalEnvironment.ChestFarmerBoatStop then pcall(globalEnvironment.ChestFarmerBoatStop) end
local oldGui = playerGui and playerGui:FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = GUI_NAME, false
gui.Enabled = false
gui.Parent = bridge.host
bridge.engineGui = gui
if LOAD_UI then
    if playerGui then
        gui.Parent = playerGui
    else
        task.spawn(function()
            local latePlayerGui = player:WaitForChild("PlayerGui")
            if not gui.Parent then gui.Parent = latePlayerGui end
        end)
    end
end

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(300, 224)
panel.Position = UDim2.fromOffset(15, 100)
panel.BackgroundColor3 = Color3.fromRGB(25, 28, 34)
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

local function label(text, x, y, width, height, size, color)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Position = UDim2.fromOffset(x, y)
    item.Size = UDim2.fromOffset(width, height)
    item.Font = Enum.Font.Gotham
    item.TextSize = size
    item.TextColor3 = color
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextTruncate = Enum.TextTruncate.AtEnd
    item.Text = text
    item.Parent = panel
    return item
end

local light = Color3.fromRGB(240, 242, 245)
local muted = Color3.fromRGB(160, 167, 178)
local titleLabel = label("Chest Farm Â· Initializing", 14, 10, 150, 26, 16, light)
label("Money gained", 14, 46, 130, 18, 11, muted)
label("Money / min", 157, 46, 130, 18, 11, muted)
local gainedLabel = label("â€”", 14, 65, 130, 24, 18, Color3.fromRGB(125, 225, 163))
local rateLabel = label("â€”", 157, 65, 130, 24, 18, light)

label("Live velocity", 14, 95, 130, 18, 11, muted)
label("Avg leg speed", 157, 95, 130, 18, 11, muted)
local speedLabel = label("0.0 studs/s", 14, 114, 130, 22, 14, Color3.fromRGB(80, 200, 255))
local avgSpeedLabel = label("â€”", 157, 114, 130, 22, 14, Color3.fromRGB(125, 225, 163))

local nextPassLabel = label("Watching for active chestsâ€¦", 14, 142, 272, 17, 11, light)
local availabilityLabel = label("Finding chestsâ€¦", 14, 160, 272, 17, 11, muted)
local plannerLabel = label("Live planner startingâ€¦", 14, 178, 272, 17, 10, muted)
local statusLabel = label("Startingâ€¦", 14, 198, 272, 17, 11, muted)
local updateSmallDetails

local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.fromOffset(60, 26)
stopButton.Position = UDim2.fromOffset(226, 10)
stopButton.Text = "Stop"
stopButton.Font = Enum.Font.Gotham
stopButton.TextSize = 12
stopButton.TextColor3 = light
stopButton.BackgroundColor3 = Color3.fromRGB(55, 60, 70)
stopButton.BorderSizePixel = 0
stopButton.Parent = panel

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = stopButton

local mapButton = Instance.new("TextButton")
mapButton.Size = UDim2.fromOffset(54, 26)
mapButton.Position = UDim2.fromOffset(166, 10)
mapButton.Text = "Map"
mapButton.Font = Enum.Font.Gotham
mapButton.TextSize = 12
mapButton.TextColor3 = light
mapButton.BackgroundColor3 = Color3.fromRGB(55, 60, 70)
mapButton.BorderSizePixel = 0
mapButton.Parent = panel
local mapButtonCorner = Instance.new("UICorner")
mapButtonCorner.CornerRadius = UDim.new(0, 6)
mapButtonCorner.Parent = mapButton

local stopped = false
local connections = {}
bridge.connections = connections

local uiInput = game:GetService("UserInputService")
local uiLastViewport = Vector2.zero
local uiLastTouch = nil
local uiPanelPosition
local function positionStats(position)
    local camera = workspace.CurrentCamera
    if not camera then return end
    local topLeft, bottomRight = game:GetService("GuiService"):GetGuiInset()
    local usable = camera.ViewportSize - topLeft - bottomRight
    local size = Vector2.new(panel.Size.X.Offset, panel.Size.Y.Offset) * panelScale.Scale
    uiPanelPosition = Vector2.new(
        math.clamp(position.X, 0, math.max(0, usable.X - size.X)),
        math.clamp(position.Y, 0, math.max(0, usable.Y - size.Y)))
    panel.Position = UDim2.fromOffset(uiPanelPosition.X, uiPanelPosition.Y)
end
local function layoutStats()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local touch = uiInput.TouchEnabled
    if viewport == uiLastViewport and touch == uiLastTouch then return end
    uiLastViewport, uiLastTouch = viewport, touch
    local topLeft, bottomRight = game:GetService("GuiService"):GetGuiInset()
    local usable = viewport - topLeft - bottomRight
    panelScale.Scale = math.min(1, math.max(0.5, (usable.X - 16) / 300))
    panel.Size = UDim2.fromOffset(300, touch and 240 or 224)
    positionStats(uiPanelPosition or Vector2.new(touch and 8 or 15, touch and 8 or math.min(100, math.max(8, usable.Y - 232))))
    stopButton.Size = UDim2.fromOffset(60, touch and 42 or 26)
    mapButton.Size = UDim2.fromOffset(54, touch and 42 or 26)
    stopButton.Position = UDim2.fromOffset(226, touch and 4 or 10)
    mapButton.Position = UDim2.fromOffset(166, touch and 4 or 10)
    for _, child in ipairs(panel:GetChildren()) do
        if child:IsA("TextLabel") then
            local originalY = child:GetAttribute("LayoutY")
            if not originalY then originalY = child.Position.Y.Offset; child:SetAttribute("LayoutY", originalY) end
            child.Position = UDim2.fromOffset(child.Position.X.Offset, originalY + (touch and originalY >= 46 and 16 or 0))
        end
    end
end
layoutStats()

-- Drag from the title area; Map and Stop remain independent tap targets.
local dragHandle = Instance.new("Frame")
dragHandle.Name = "DragHandle"
dragHandle.BackgroundTransparency = 1
dragHandle.Size = UDim2.fromOffset(158, 44)
dragHandle.Active = true
dragHandle.ZIndex = 5
dragHandle.Parent = panel
local statsDragInput, statsDragStart, statsDragPosition
table.insert(connections, dragHandle.InputBegan:Connect(function(input)
    if stopped or statsDragInput then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    statsDragInput = input
    statsDragStart = Vector2.new(input.Position.X, input.Position.Y)
    statsDragPosition = Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset)
end))
table.insert(connections, uiInput.InputChanged:Connect(function(input)
    if not statsDragInput or stopped or not panel.Visible then return end
    if input == statsDragInput or (statsDragInput.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseMovement) then
        local position = Vector2.new(input.Position.X, input.Position.Y)
        positionStats(statsDragPosition + position - statsDragStart)
    end
end))
table.insert(connections, uiInput.InputEnded:Connect(function(input)
    if input == statsDragInput then statsDragInput = nil end
end))

local virtualUser = game:GetService("VirtualUser")
local antiAfkConnection = player.Idled:Connect(function()
    virtualUser:CaptureController()
    virtualUser:ClickButton2(Vector2.new())
end)
table.insert(connections, antiAfkConnection)

local candidates, records = {}, {}
local chestOriginals = setmetatable({}, {__mode = "k"})
local currentRouteDestination
local currentTargetBoxCenter = nil
local currentTargetRecords = nil
local currentNextRoutePosition = nil
local choose, eligible, observeRecord
local liveNavigation = {plan = nil, nodeCount = 0, planMilliseconds = 0, speed = C.BoatSpeed}
local discovery = {active = DISCOVERY_RUN, regions = {}, completed = 0, skipped = 0,
    seededRecords = {}, lastSeedScan = -math.huge}
local streamingJob
local function requestStream(position)
    if not workspace.StreamingEnabled or stopped then return nil end
    if streamingJob and not streamingJob.done then
        return (streamingJob.position - position).Magnitude <= DISCOVERY_RADIUS and streamingJob or nil
    end
    local job = {position = position, done = false}
    streamingJob = job
    task.spawn(function()
        job.ok = pcall(function() player:RequestStreamAroundAsync(position, STREAM_TIMEOUT) end)
        job.done = true
    end)
    return job
end
local lastObserved = -math.huge

local function log(message)
    if C.Debug then print("[Chest Farmer] " .. message) end
end
local function display(message)
    if gui.Parent then statusLabel.Text = message end
end

local startingBeli, moneyStarted
local function formatMoney(value)
    local rounded = math.floor(math.abs(value) + 0.5)
    local digits = string.format("%.0f", rounded)
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return (value < 0 and rounded > 0 and "-$" or "$") .. grouped
end

local function readBeli()
    local data = player:FindFirstChild("Data")
    local value = data and data:FindFirstChild("Beli")
    if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then return value.Value end
end

local function updateMoney()
    if not gui.Parent then return end
    local balance = readBeli()
    if not balance then return end
    local now = workspace:GetServerTimeNow()
    if startingBeli == nil then startingBeli, moneyStarted = balance, now end
    local gained = balance - startingBeli
    local elapsed = now - moneyStarted
    gainedLabel.Text = formatMoney(gained)
    rateLabel.Text = formatMoney(elapsed > 0 and gained * 60 / elapsed or 0)
end

local moneyRefreshAt = 0
table.insert(connections, RunService.Heartbeat:Connect(function()
    if not gui.Parent then return end
    layoutStats()
    local velocityText = string.format("%.1f studs/s", getLiveVelocity())
    if speedLabel.Text ~= velocityText then speedLabel.Text = velocityText end

    local now = os.clock()
    if now < moneyRefreshAt then return end
    moneyRefreshAt = now + 0.25
    updateMoney()
    bridge.stats = {money = gainedLabel.Text, rate = rateLabel.Text,
        speed = speedLabel.Text, detail = statusLabel.Text, route = plannerLabel.Text}
    if updateSmallDetails then updateSmallDetails() end
    if avgLegSpeed > 0 then
        avgSpeedLabel.Text = string.format("%.1f studs/s", avgLegSpeed)
    else
        avgSpeedLabel.Text = "â€”"
    end
end))

local function stop()
    if stopped then return end
    stopped = true
    display("Parando...")
    if bridge.halt then bridge.halt() end
    if bridge.approachDrive and bridge.approachDrive.Parent then
        bridge.approachDrive.VectorVelocity = Vector3.zero
        bridge.approachDrive.Enabled = false
    end
    local _, root, hum = parts()
    if root then root.AssemblyLinearVelocity = Vector3.zero end
    if hum and hum.SeatPart then hum.SeatPart.AssemblyLinearVelocity = Vector3.zero end
end
globalEnvironment.ChestFarmerBoatStop = stop
bridge.stop = stop
if bridge.cancelled then stop() end
table.insert(connections, stopButton.Activated:Connect(stop))
table.insert(connections, gui.Destroying:Connect(stop))

local function waitCharacter(timeout)
    local deadline = workspace:GetServerTimeNow() + timeout
    repeat
        local char, root, hum = parts()
        if char then return char, root, hum end
        task.wait(C.PollSeconds)
    until stopped or workspace:GetServerTimeNow() >= deadline
end

local function available(part)
    return part and part:IsDescendantOf(workspace) and part.CanTouch == true
end
local function loadedTrigger(record)
    local trigger = record.spawnPart or record.part
    return trigger and trigger:IsDescendantOf(workspace) and trigger or nil
end
local function rememberedReadyAt(record, now)
    local trigger = loadedTrigger(record)
    if trigger then return trigger.CanTouch and now or math.huge end
    if not record.geometry or record.lastCanTouch == nil then return math.huge end
    if record.lastCanTouch then return now end
    return record.readyAt or math.huge
end
local function chestStatus(record, now)
    local trigger = loadedTrigger(record)
    if trigger and trigger.CanTouch then return "ready" end
    if not trigger and rememberedReadyAt(record, now) <= now then return "remembered" end
    if record.readyAt and record.readyAt < math.huge and record.readyAt > now then return "predicted" end
    return record.lastCanTouch == nil and "unknown" or "empty"
end

local function enforceChestHitbox(part)
    if stopped or not part:IsDescendantOf(workspace) then return end
    pcall(function()
        if part.Size ~= HITBOX_SIZE then part.Size = HITBOX_SIZE end
        if part.CanCollide then part.CanCollide = false end
    end)
end

local function track(obj)
    rememberDealer(obj)
    if not obj:IsA("BasePart") or not obj.Name:lower():find("chest", 1, true) then return end
    local visualFolder = workspace:FindFirstChild("ChestModels")
    if visualFolder and obj:IsDescendantOf(visualFolder) then return end

    if not chestOriginals[obj] then
        chestOriginals[obj] = {size = obj.Size, canCollide = obj.CanCollide}
        for _, property in ipairs({"Size", "CanCollide"}) do
            table.insert(connections, obj:GetPropertyChangedSignal(property):Connect(function()
                enforceChestHitbox(obj)
            end))
        end
        table.insert(connections, obj:GetPropertyChangedSignal("CanTouch"):Connect(function()
            if stopped or not obj:IsDescendantOf(workspace) then return end
            local record = candidates[obj]
            if type(record) ~= "table" then return end
            local attempt = record.pendingAttempt
            if not obj.CanTouch and attempt and not attempt.done and attempt.activeBefore and attempt.crossed
                and attempt.touchPart == obj then
                attempt.deactivatedAt = workspace:GetServerTimeNow()
            end
            if observeRecord then observeRecord(record, obj, workspace:GetServerTimeNow()) end
        end))
    end
    enforceChestHitbox(obj)

    if candidates[obj] == nil then candidates[obj] = true end
end
table.insert(connections, workspace.DescendantAdded:Connect(track))
local initialScanComplete = false
task.spawn(function()
    local pending = {workspace}
    while not stopped and #pending > 0 do
        for _ = 1, 200 do
            local item = table.remove(pending)
            if not item then break end
            track(item)
            for _, child in ipairs(item:GetChildren()) do table.insert(pending, child) end
        end
        task.wait()
    end
    initialScanComplete = not stopped
end)

-- REWARDS & COOLDOWNS (Server-Synchronized)
local function markEmpty(record, now, ours)
    if record.state == "empty" and record.emptyAt and now - record.emptyAt < 5 then
        if ours and record.lastLossCounted then
            record.otherLosses = math.max(0, (record.otherLosses or 0) - 1)
            record.lastLossCounted = false
        end
        return
    end
    record.emptyAt = now
    record.readyAt = now + (respawnOf(record) or economyOf(record).respawn)
    record.observationGap = false
    record.state = "empty"
    record.lastLossCounted = not ours
    if not ours then record.otherLosses = (record.otherLosses or 0) + 1 end
end

observeRecord = function(record, trigger, now)
    if not trigger or not trigger:IsDescendantOf(workspace) then
        record.loaded, record.observationGap = false, true
        return
    end
    local priorTouch = record.lastCanTouch
    local gap = record.observationGap
    record.spawnPart = trigger
    record.loaded = true
    if not record.geometry or record.geometry.cframe ~= trigger.CFrame or record.geometry.size ~= trigger.Size then
        record.geometry = {cframe = trigger.CFrame, size = trigger.Size}
    end
    record.position, record.lastObservedAt = trigger.Position, now
    if trigger.CanTouch then
        if priorTouch == false and record.emptyAt and not gap then
            local measured = now - record.emptyAt
            local nominal = economyOf(record).respawn
            if measured > nominal * 0.5 and measured < nominal * 1.5 then
                record.respawnEstimate = (record.respawnEstimate or nominal) * 0.8 + measured * 0.2
            end
        end
        record.part, record.state, record.collected = trigger, "ready", false
        record.emptyAt, record.readyAt = nil, now
        record.initiallyEmptyAt = nil
    else
        record.part = nil
        if priorTouch == true then
            local attempt = record.pendingAttempt
            markEmpty(record, now, attempt and attempt.deactivatedAt ~= nil)
        end
        record.state = "empty"
        if not record.emptyAt and not record.initiallyEmptyAt then
            -- Unknown startup collection time: a full respawn interval is a conservative bound.
            record.initiallyEmptyAt = now
            record.readyAt = now + (respawnOf(record) or economyOf(record).respawn)
        end
    end
    record.lastCanTouch, record.observationGap = trigger.CanTouch, false
end

local pendingAttempts = {}
local startupMissReports = 0
local lastPickupBalance = readBeli()
local function beginPending(record, sweepSeconds)
    if record.pendingAttempt then return record.pendingAttempt end
    local now = workspace:GetServerTimeNow()
    local trigger = record.spawnPart or record.part
    if not available(trigger) then return nil end
    local attempt = {record = record, touchPart = trigger, activeBefore = available(trigger) == true,
        expires = now + sweepSeconds + C.PendingConfirmSeconds + 1, crossed = false}
    record.pendingAttempt = attempt
    record.pendingUntil = attempt.expires
    table.insert(pendingAttempts, attempt)
    return attempt
end

local function confirmPickup(attempt, now)
    if attempt.done then return end
    attempt.done = true
    local record = attempt.record
    markEmpty(record, now, true)
    record.collected = true
    record.successes = (record.successes or 0) + 1
    record.failures = 0
    record.cooldown = now + 1
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    local now, balance = workspace:GetServerTimeNow(), readBeli()
    if balance and lastPickupBalance and balance > lastPickupBalance then
        local gain = balance - lastPickupBalance
        -- Beli can combine several pickups or come from another source.
        -- Retain it as supporting evidence; it cannot identify a chest by itself.
        for _, attempt in ipairs(pendingAttempts) do
            if not attempt.done and attempt.crossed and now <= attempt.expires then
                attempt.beliEvidence = (attempt.beliEvidence or 0) + gain
            end
        end
    end
    if balance then lastPickupBalance = balance end
    for i = #pendingAttempts, 1, -1 do
        local attempt = pendingAttempts[i]
        -- A pass alone is not a pickup: require contact, deactivation and reward evidence.
        local observedPart = attempt.touchPart
        if not attempt.done and attempt.crossed and attempt.activeBefore and now <= attempt.expires
            and (attempt.beliEvidence or 0) > 0
            and (attempt.deactivatedAt or (observedPart and observedPart:IsDescendantOf(workspace) and observedPart.CanTouch == false)) then
            confirmPickup(attempt, attempt.deactivatedAt or now)
        end
        if attempt.done or now >= attempt.expires then
            local record = attempt.record
            if record.pendingAttempt == attempt then
                record.pendingAttempt, record.pendingUntil = nil, nil
                if not attempt.done and attempt.crossed and attempt.activeBefore
                    and observedPart and observedPart:IsDescendantOf(workspace) and observedPart.CanTouch then
                    if startupMissReports < 5 then
                        startupMissReports += 1
                        local char, root, hum = parts()
                        local touchParts, anchoredParts = 0, 0
                        if char then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    if part.CanTouch then touchParts += 1 end
                                    if part.Anchored then anchoredParts += 1 end
                                end
                            end
                        end
                        local trigger = record.part or record.spawnPart
                        log(string.format("Miss %d: %s | active trigger=%s | trigger CanTouch=%s | character touch parts=%d | anchored parts=%d | seated=%s | scan complete=%s",
                            startupMissReports, record.name, tostring(available(trigger) == true),
                            tostring(trigger and trigger.CanTouch), touchParts, anchoredParts,
                            tostring(hum and hum.SeatPart ~= nil), tostring(initialScanComplete)))
                    end
                    record.misses = (record.misses or 0) + 1
                    record.failures = (record.failures or 0) + 1
                    record.cooldown = now + math.min(C.MaxChestCooldown, C.ChestFailureCooldown * 2 ^ math.min(record.failures - 1, 4))
                end
            end
            table.remove(pendingAttempts, i)
        end
    end
end))

local function refreshChests(force)
    local now = workspace:GetServerTimeNow()
    if not force and now - lastObserved < C.ObserveSeconds then return end
    local observedSeconds = math.min(2, math.max(0, now - lastObserved))
    lastObserved = now
    for _, r in ipairs(records) do r.spawnPart = nil; r.part = nil end
    for part in pairs(candidates) do
        if not part:IsDescendantOf(workspace) then
            candidates[part] = nil
        else
            enforceChestHitbox(part)

            local r = candidates[part]
            if r == true then
                r = nil
                for _, existing in ipairs(records) do
                    if existing.name == part.Name and (existing.position - part.Position).Magnitude <= C.MatchRadius then
                        r = existing
                        break
                    end
                end
                if not r then
                    r = {id = #records + 1, name = part.Name, position = part.Position,
                        cooldown = 0, failures = 0, successes = 0, misses = 0,
                        exposure = 0, otherLosses = 0, state = "unknown",
                        readyAt = math.huge}
                    table.insert(records, r)
                end
                candidates[part] = r
            end
            r.spawnPart = part
            if available(part) then r.part = part end
            r.position = part.Position
        end
    end
    for _, r in ipairs(records) do
        if r.state == "ready" then r.exposure = (r.exposure or 0) + observedSeconds end
        observeRecord(r, r.spawnPart, now)
    end
end

-- FALLBACK WALKING MOVEMENT (Only used when acquiring initial boat)
local function approachPosition(target, stopRadius)
    if stopped then return false end
    local char, root, hum = parts()
    if not char then return false end
    target = enforceAltitudeFloor(target)
    local previousFlight = root:FindFirstChild("ContinuousFlightVelocity")
    local flightWasEnabled = previousFlight and previousFlight.Enabled
    if previousFlight then previousFlight.Enabled = false end
    local attachment = Instance.new("Attachment", root)
    local drive = Instance.new("LinearVelocity", root)
    bridge.approachDrive = drive
    drive.Attachment0 = attachment
    drive.RelativeTo = Enum.ActuatorRelativeTo.World
    drive.ForceLimitsEnabled = false

    local originals = {}
    local function disableCollision(part)
        if not part:IsA("BasePart") then return end
        if originals[part] == nil then originals[part] = part.CanCollide end
        part.CanCollide = false
    end
    for _, part in ipairs(char:GetDescendants()) do disableCollision(part) end
    local added = char.DescendantAdded:Connect(disableCollision)
    local noclipConn = RunService.PreSimulation:Connect(function()
        for part in pairs(originals) do
            if part.Parent and part.CanCollide then part.CanCollide = false end
        end
    end)

    bridge.cleanupApproach = function()
        noclipConn:Disconnect()
        added:Disconnect()
        for part, canCollide in pairs(originals) do
            if part.Parent then part.CanCollide = canCollide end
        end
        drive:Destroy()
        attachment:Destroy()
        bridge.approachDrive = nil
        if previousFlight and previousFlight.Parent then previousFlight.Enabled = flightWasEnabled end
        bridge.cleanupApproach = nil
    end
    local estimate = Planner.travelSeconds(root.Position, target, C.Speed)
    local began = workspace:GetServerTimeNow()
    local arrived = false
    while not stopped and player.Character == char and hum.Health > 0 and workspace:GetServerTimeNow() - began <= estimate * 2 + 3 do
        RunService.Heartbeat:Wait()
        local delta = target - root.Position
        if delta.Magnitude <= stopRadius then arrived = true; break end
        if stopped then break end
        drive.VectorVelocity = delta.Unit * C.Speed
    end
    bridge.cleanupApproach = nil
    noclipConn:Disconnect()
    added:Disconnect()
    for part, canCollide in pairs(originals) do
        if part.Parent then part.CanCollide = canCollide end
    end
    bridge.approachDrive = nil
    drive:Destroy()
    attachment:Destroy()
    if previousFlight and previousFlight.Parent then
        previousFlight.Enabled = flightWasEnabled
    end
    return arrived
end

local preparedBoat, boatSeatCleanupConnection
local function prepareDinghySeats(boat)
    if not boat or not boat.Parent or preparedBoat == boat then return end
    if boatSeatCleanupConnection then boatSeatCleanupConnection:Disconnect() end
    preparedBoat = boat
    -- Preserve all seats; collision changes are restored by restoreFlightCollision().
end

local function buyDinghy()
    if stopped then return nil end
    local boats = workspace:FindFirstChild("Boats") or workspace:WaitForChild("Boats", 3)
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
    local event = remoteFolder and remoteFolder:FindFirstChild("CommF_")
    if not boats or not event then return nil end
    local _, root = parts()
    for _, existing in ipairs(boats:GetChildren()) do
        local seat = boatSeat(existing)
        if seat and root and boatBelongsToPlayer(existing) and (root.Position - seat.Position).Magnitude <= 500 then
            prepareDinghySeats(existing)
            return existing
        end
    end
    local seen = {}
    for _, child in ipairs(boats:GetChildren()) do seen[child] = true end
    local arrivals = {}
    local added = boats.ChildAdded:Connect(function(child) table.insert(arrivals, child) end)
    task.spawn(function() pcall(function() event:InvokeServer("BuyBoat", "Dinghy") end) end)
    local deadline = workspace:GetServerTimeNow() + 8
    local found
    repeat
        for _, boat in ipairs(arrivals) do
            if boat.Parent == boats and not seen[boat] and boatBelongsToPlayer(boat) and boatSeat(boat) then
                found = boat
                break
            end
        end
        if found then break end
        task.wait(0.1)
    until stopped or workspace:GetServerTimeNow() >= deadline
    added:Disconnect()
    if found then prepareDinghySeats(found) end
    return found
end

local function boardBoat(boat)
    prepareDinghySeats(boat)
    local char, root, hum = parts()
    local seat = boatSeat(boat)
    if not char or not seat then return false end
    seat:Sit(hum)
    local deadline = workspace:GetServerTimeNow() + 2
    while not stopped and workspace:GetServerTimeNow() < deadline and seat.Occupant ~= hum do task.wait(0.05) end
    return seat.Occupant == hum
end

-- SMART VEHICLE/FALLBACK RESOLVER
local function getActiveVehicleOrCharacter()
    local char, root, hum = parts()
    if not char then return nil, nil end

    if hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local boat = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if boat then
            ownedBoat = boat
            prepareDinghySeats(boat)
            local seat = boatSeat(boat)
            if seat and seat.Occupant == hum then
                titleLabel.Text = "Chest Farm Â· 100% Boat"
                return boat, seat
            end
        end
    end

    if ownedBoat and ownedBoat.Parent then
        prepareDinghySeats(ownedBoat)
        local seat = boatSeat(ownedBoat)
        if seat and (root.Position - seat.Position).Magnitude <= 350 then
            display("Boarding owned Dinghyâ€¦")
            approachPosition(seat.Position + Vector3.new(0, 3, 0), 10)
            if boardBoat(ownedBoat) then
                titleLabel.Text = "Chest Farm Â· 100% Boat"
                return ownedBoat, seat
            end
        end
    end

    scanDealers(true)
    local nearestDealer, nearestDist = nil, math.huge
    for _, dealer in ipairs(dealerList) do
        local dist = (root.Position - dealer.position).Magnitude
        if dist < nearestDist then
            nearestDealer, nearestDist = dealer, dist
        end
    end

    if nearestDealer and nearestDist <= 1200 then
        display("Boat Dealer found! Getting Dinghyâ€¦")
        if (root.Position - nearestDealer.position).Magnitude > BOAT_APPROACH_RANGE then
            approachPosition(nearestDealer.position, BOAT_APPROACH_RANGE)
        end
        local boat = buyDinghy()
        if boat then
            ownedBoat = boat
            local seat = boatSeat(boat)
            if seat then
                approachPosition(seat.Position + Vector3.new(0, 3, 0), 8)
                if boardBoat(boat) then
                    titleLabel.Text = "Chest Farm Â· 100% Boat"
                    return boat, seat
                end
            end
        end
    end

    titleLabel.Text = "Chest Farm Â· On Foot (Scanning)"
    return nil, nil
end

-- 3D CONTINUOUS FLIGHT CONTROLLER
local persistentLinearVelocity = nil
local persistentAttachment = nil
local persistentNoclipConn = nil
local noclipChar, noclipBoat = nil, nil
local noclipOriginals = {}
local noclipAdded = {}

local function restoreFlightCollision()
    for _, connection in ipairs(noclipAdded) do connection:Disconnect() end
    table.clear(noclipAdded)
    for part, canCollide in pairs(noclipOriginals) do
        if part.Parent then part.CanCollide = canCollide end
    end
    table.clear(noclipOriginals)
    noclipChar, noclipBoat = nil, nil
end

local function setFlightCollisionTargets(char, boat, motionPart)
    if char == noclipChar and boat == noclipBoat then return end
    restoreFlightCollision()
    noclipChar, noclipBoat = char, boat
    local function disable(part)
        if not part:IsA("BasePart") then return end
        if noclipOriginals[part] == nil then noclipOriginals[part] = part.CanCollide end
        part.CanCollide = false
    end
    local function watch(container)
        if not container then return end
        for _, part in ipairs(container:GetDescendants()) do disable(part) end
        table.insert(noclipAdded, container.DescendantAdded:Connect(disable))
    end
    watch(char)
    watch(boat)
    if motionPart then
        disable(motionPart)
        local ok, connected = pcall(function() return motionPart:GetConnectedParts(true) end)
        if ok then for _, part in ipairs(connected) do disable(part) end end
    end
    if not persistentNoclipConn then
        persistentNoclipConn = RunService.PreSimulation:Connect(function()
            for part in pairs(noclipOriginals) do
                if not part.Parent then
                    noclipOriginals[part] = nil
                elseif part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end
end

local activeFlightCommand
local function applyFlightCommand(command, now)
    local motionPart, lv, dir = command.part, command.constraint, command.direction
    if stopped or not motionPart.Parent or not lv.Parent then return end
    local speed = command.isBoat and math.clamp(getSinusoidalSpeed(now), SPEED_MIN, SPEED_MAX) or C.Speed
    local velocity = dir * speed
    if command.seat and command.seat.Parent then
        -- Native propulsion must not compete with the world-space flight velocity.
        command.seat.ThrottleFloat = 0
        command.seat.SteerFloat = 0
    end
    local up = math.abs(dir.Y) > 0.999 and Vector3.new(0, 0, -1) or Vector3.yAxis
    motionPart.CFrame = CFrame.lookAt(motionPart.Position, motionPart.Position + dir, up)
    motionPart.AssemblyAngularVelocity = Vector3.zero
    lv.VectorVelocity = velocity
    motionPart.AssemblyLinearVelocity = velocity
end
-- Persistent across adjacent legs; update before physics without stopping at boundaries.
table.insert(connections, RunService.PreSimulation:Connect(function()
    local speed = bridge.speed
    if C.Speed ~= speed then
        C.Speed, C.BoatSpeed = speed, speed
        SPEED_MIN, SPEED_MAX = math.max(10, speed - 4.95), speed + 4.95
        table.clear(measuredMotion)
        table.clear(legHistory)
        avgLegSpeed = 0
    end
    SHOW_ROUTE_TRACERS, SHOW_HITBOX_VISUALIZER = bridge.visuals, bridge.visuals
    local command = activeFlightCommand
    if command then
        if command.character ~= player.Character or not command.part.Parent or not command.constraint.Parent then
            activeFlightCommand = nil
            return
        end
        applyFlightCommand(command, workspace:GetServerTimeNow())
    end
end))

local function getFlightConstraint(boat, seat)
    local char, root = parts()
    local motionPart = seat and (seat.AssemblyRootPart or seat) or root
    if not motionPart then return nil, nil end

    if not persistentLinearVelocity or persistentLinearVelocity.Parent ~= motionPart then
        if persistentLinearVelocity then persistentLinearVelocity:Destroy() end
        if persistentAttachment then persistentAttachment:Destroy() end

        persistentAttachment = Instance.new("Attachment")
        persistentAttachment.Name = "ContinuousFlightAttachment"
        persistentAttachment.Parent = motionPart

        persistentLinearVelocity = Instance.new("LinearVelocity")
        persistentLinearVelocity.Name = "ContinuousFlightVelocity"
        persistentLinearVelocity.Attachment0 = persistentAttachment
        persistentLinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
        persistentLinearVelocity.ForceLimitsEnabled = false
        persistentLinearVelocity.MaxForce = math.huge
        persistentLinearVelocity.VectorVelocity = Vector3.zero
        persistentLinearVelocity.Parent = motionPart
    end

    setFlightCollisionTargets(char, boat, motionPart)

    return persistentLinearVelocity, motionPart
end

local function pauseFlight()
    activeFlightCommand = nil
    if persistentLinearVelocity and persistentLinearVelocity.Parent then
        persistentLinearVelocity.VectorVelocity = Vector3.zero
        local motionPart = persistentLinearVelocity.Parent
        if motionPart:IsA("BasePart") then
            motionPart.AssemblyLinearVelocity = Vector3.zero
            motionPart.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

bridge.halt = pauseFlight

-- Moves in a single straight 3D vector directly to the destination with INSTANT acceleration and FULL 3D PITCH
local function move3D(boat, seat, destination, recordsToArm, guard)
    local char, root, hum = parts()
    if not char then return "interrupted" end

    local lv, motionPart = getFlightConstraint(boat, seat)
    if not lv or not motionPart then return "interrupted" end

    local began = workspace:GetServerTimeNow()
    local startPos = root.Position
    local delta = destination - startPos
    local totalDist = delta.Magnitude
    local function armNearby(position)
        if not recordsToArm then return end
        for _, rec in ipairs(recordsToArm) do
            local trigger = rec.spawnPart or rec.part
            local offset = trigger and trigger.CFrame:PointToObjectSpace(position)
            local half = trigger and trigger.Size * 0.5
            if available(trigger) and math.abs(offset.X) <= half.X + 12
                and math.abs(offset.Y) <= half.Y + 12 and math.abs(offset.Z) <= half.Z + 12 then
                local attempt = beginPending(rec, 0.05)
                if attempt and math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y
                    and math.abs(offset.Z) <= half.Z then attempt.crossed = true end
            end
        end
    end

    armNearby(startPos)
    if totalDist <= C.ArrivalDistance then return "arrived" end

    local initialDir = delta.Unit
    local isBoat = (boat ~= nil and seat ~= nil)
    local minSpeed = isBoat and SPEED_MIN or C.Speed
    local timeout = (totalDist / minSpeed) + 3.0
    local outcome = "arrived"
    local movingDistance, movingTime = 0, 0
    local previousPosition, previousTime = motionPart.Position, os.clock()

    local command = {part = motionPart, constraint = lv, direction = initialDir,
        seat = seat, isBoat = isBoat, character = char}
    local function drive(dir, now)
        command.direction = dir
        activeFlightCommand = command
        applyFlightCommand(command, now)
    end

    drive(initialDir, began)

    while not stopped and player.Character == char and hum.Health > 0 do
        RunService.Heartbeat:Wait()
        local frameTime = os.clock()
        local framePosition = motionPart.Position
        movingDistance += (framePosition - previousPosition).Magnitude
        movingTime += frameTime - previousTime
        previousPosition, previousTime = framePosition, frameTime
        if isBoat and seat.Occupant ~= hum then
            seat:Sit(hum)
            if seat.Occupant ~= hum then outcome = "interrupted"; break end
        end

        local now = workspace:GetServerTimeNow()
        if now - began > timeout then outcome = "timeout"; break end

        local currentPos = root.Position
        local currentDelta = destination - currentPos
        local currentDist = currentDelta.Magnitude

        armNearby(currentPos)
        if guard then
            local decision = guard(now, currentPos, currentDist)
            if decision then outcome = decision; break end
        end

        -- Cutoff check
        local passed = (currentPos - startPos):Dot(initialDir) >= totalDist
        if currentDist <= C.ArrivalDistance or passed then
            outcome = "arrived"
            break
        end

        -- Each leg is a straight velocity vector; do not chase an overshot endpoint.
        drive(initialDir, now)
    end

    if stopped or player.Character ~= char or hum.Health <= 0 then
        outcome = "interrupted"
    end
    if outcome == "arrived" then
        recordLegPerformance(movingDistance, movingTime, isBoat and "boat" or "foot")
    elseif outcome == "timeout" or outcome == "interrupted" then
        pauseFlight()
    end

    return outcome
end

-- One short pass collects every chest in an overlapping trigger cluster.
local function flyThroughTarget(boat, seat, node)
    local char, root = parts()
    if not char then return "interrupted" end
    local recordsList = node.records
    local entryPoint, centerPoint, exitPoint = Planner.sweepPath(node, root.Position, C.SweepMargin)
    currentTargetBoxCenter, currentTargetRecords = centerPoint, recordsList
    local function finish(outcome)
        currentRouteDestination, currentTargetBoxCenter = nil, nil
        currentTargetRecords, currentNextRoutePosition = nil, nil
        return outcome
    end
    local function hasActive()
        for _, record in ipairs(recordsList) do
            if available(record.spawnPart or record.part) then return true end
        end
        return false
    end
    local function hasMissing()
        for _, record in ipairs(recordsList) do if not loadedTrigger(record) then return true end end
        return false
    end
    local function hasPotential(now, seconds)
        for _, record in ipairs(recordsList) do
            if rememberedReadyAt(record, now) <= now + seconds then return true end
        end
        return false
    end
    local approachSeconds = Planner.travelSeconds(root.Position, entryPoint, liveNavigation.speed)
    if not hasPotential(workspace:GetServerTimeNow(), approachSeconds) then return finish("unavailable") end
    local verificationJob
    local began, lastReplan = workspace:GetServerTimeNow(), workspace:GetServerTimeNow()
    local targetName = node.isCluster and ("Pass Â· " .. #recordsList .. " chests") or node.record.name
    local function guard(now, position, remaining)
        if not hasPotential(now, Planner.travelSeconds(position, entryPoint, liveNavigation.speed)) then return "unavailable" end
        if hasMissing() and not verificationJob and remaining <= liveNavigation.speed * STREAM_TIMEOUT + DISCOVERY_RADIUS then
            verificationJob = requestStream(centerPoint)
        end
        if remaining <= C.FinishDistance or now - began < C.MinimumCommitSeconds
            or now - lastReplan < C.ReplanSeconds then return end
        -- Finish the short pass once contact is possible; never reroute during confirmation.
        for _, record in ipairs(recordsList) do
            if record.pendingAttempt then return end
        end
        lastReplan = now
        refreshChests()
        local _, currentRoot = parts()
        if not currentRoot then return "interrupted" end
        local best = choose(currentRoot, nil, liveNavigation.speed)
        if not best then return "unavailable" end
        local sameTarget = best.first.id == node.id
        local retained = sameTarget and best or choose(currentRoot, node.record, liveNavigation.speed)
        if not sameTarget and (not retained or best.score > retained.score * C.SwitchGain) then
            return "reroute"
        end
        -- Preserve the displayed committed route when a marginal alternative is rejected.
        if retained then
            liveNavigation.plan = retained
            currentNextRoutePosition = retained.route[2] and retained.route[2].position or nil
        end
    end
    display("Approach Â· " .. targetName)
    currentRouteDestination = entryPoint
    local approach = move3D(boat, seat, entryPoint, recordsList, guard)
    if approach ~= "arrived" then return finish(approach) end
    refreshChests(true)
    if not hasActive() and hasMissing() then
        if workspace.StreamingEnabled then
            verificationJob = verificationJob or requestStream(centerPoint)
            pauseFlight()
            local deadline = workspace:GetServerTimeNow() + STREAM_TIMEOUT
            while not stopped and not hasActive() and workspace:GetServerTimeNow() < deadline do
                RunService.Heartbeat:Wait()
                refreshChests()
                local allLoaded = true
                for _, record in ipairs(recordsList) do if not loadedTrigger(record) then allLoaded = false; break end end
                if allLoaded then break end
                if not verificationJob then verificationJob = requestStream(centerPoint) end
            end
            refreshChests(true)
        end
    end
    if stopped then return finish("interrupted") end
    if not hasActive() then
        for _, record in ipairs(recordsList) do
            if not loadedTrigger(record) then record.cooldown = workspace:GetServerTimeNow() + C.ChestFailureCooldown end
        end
        return finish("unavailable")
    end
    display("Passing through Â· " .. targetName)
    currentRouteDestination = exitPoint
    -- No timer wait and no artificial confirmation pause: continue through the hitboxes.
    return finish(move3D(boat, seat, exitPoint, recordsList))
end
-- Loaded inactivity wins. Remembered data is usable only when its hitbox is unloaded.
eligible = function(record, now)
    local pending = record.pendingAttempt
    return rememberedReadyAt(record, now) < math.huge
        and not (pending and not pending.done)
        and now >= (record.cooldown or 0)
end

-- Conservatively inscribe an axis-aligned cube in a rotated hitbox.
local function triggerBounds(record)
    local geometry = record.geometry
    if geometry.low then return geometry.low, geometry.high end
    local half = geometry.size * 0.5
    local rotation = geometry.cframe
    local right, up, look = rotation.RightVector, rotation.UpVector, rotation.LookVector
    local radius = math.min(
        half.X / (math.abs(right.X) + math.abs(right.Y) + math.abs(right.Z)),
        half.Y / (math.abs(up.X) + math.abs(up.Y) + math.abs(up.Z)),
        half.Z / (math.abs(look.X) + math.abs(look.Y) + math.abs(look.Z)))
    local extent = Vector3.new(radius, radius, radius)
    local low, high = rotation.Position - extent, rotation.Position + extent
    low = Vector3.new(low.X, math.max(low.Y, C.MinRootY), low.Z)
    geometry.low, geometry.high = low, high
    return low, high
end
local function overlapBounds(aLow, aHigh, bLow, bHigh)
    local low = Vector3.new(math.max(aLow.X, bLow.X), math.max(aLow.Y, bLow.Y), math.max(aLow.Z, bLow.Z))
    local high = Vector3.new(math.min(aHigh.X, bHigh.X), math.min(aHigh.Y, bHigh.Y), math.min(aHigh.Z, bHigh.Z))
    return low, high
end
local function buildFusedClusters(rawNodes)
    local nodes, used = {}, {}
    for index, anchor in ipairs(rawNodes) do
        if used[index] then continue end
        local group, low, high = {anchor.record}, anchor.low, anchor.high
        local value, expected, readyAt = anchor.value, anchor.value * anchor.reliability, anchor.readyAt
        used[index] = true
        for other = index + 1, #rawNodes do
            if used[other] then continue end
            local candidate = rawNodes[other]
            if anchor.inferred ~= candidate.inferred or math.abs(readyAt - candidate.readyAt) > 3 then continue end
            if candidate.low.X > high.X - 4 or candidate.high.X < low.X + 4
                or candidate.low.Y > high.Y - 4 or candidate.high.Y < low.Y + 4
                or candidate.low.Z > high.Z - 4 or candidate.high.Z < low.Z + 4 then continue end
            local nextLow, nextHigh = overlapBounds(low, high, candidate.low, candidate.high)
            local span = nextHigh - nextLow
            -- Every member shares a real touch region; one short pass can collect all.
            if math.min(span.X, span.Y, span.Z) >= 4 then
                low, high = nextLow, nextHigh
                value += candidate.value
                expected += candidate.value * candidate.reliability
                readyAt = math.max(readyAt, candidate.readyAt)
                table.insert(group, candidate.record)
                used[other] = true
            end
        end
        table.insert(nodes, {id = anchor.record.id, record = anchor.record, records = group,
            position = (low + high) * 0.5, halfSize = (high - low) * 0.5,
            value = value, reliability = expected / value,
            readyAt = readyAt, inferred = anchor.inferred,
            isCluster = #group > 1, clusterCount = #group})
    end
    return nodes
end
local function snapshotNodes(now)
    local raw = {}
    for _, record in ipairs(records) do
        if not eligible(record, now) then continue end
        local low, high = triggerBounds(record)
        if high.Y <= low.Y then continue end
        local reward = economyOf(record).rewards[REWARD_SEA]
        local inferred = loadedTrigger(record) == nil
        table.insert(raw, {record = record, low = low, high = high, value = (reward[1] + reward[2]) * 0.5,
            readyAt = rememberedReadyAt(record, now), inferred = inferred,
            reliability = math.clamp((record.successes + 8) / (record.successes + record.misses + 8), 0.3, 1)
                * (inferred and 0.85 or 1)})
    end
    return buildFusedClusters(raw)
end
local function plannerOptions(speed)
    return {speed = speed, maxTravel = MAX_TRAVEL_SECONDS,
        travelEstimator = function(from, dest) return Planner.travelSeconds(from, dest, speed) end,
        service = ESTIMATED_PICKUP_SECONDS, sweepMargin = C.SweepMargin,
        depth = LOOKAHEAD_STOPS, width = C.BeamWidth, branch = C.BranchWidth,
        smoothing = 5, budget = C.PlanBudgetSeconds}
end
choose = function(root, forcedRecord, currentSpeed)
    local now, began = workspace:GetServerTimeNow(), os.clock()
    local nodes = snapshotNodes(now)
    local plan = Planner.plan(root.Position, nodes, now, plannerOptions(currentSpeed or C.BoatSpeed),
        forcedRecord and forcedRecord.id)
    if plan then plan.node, plan.record = plan.first, plan.first.record end
    if not forcedRecord then
        liveNavigation.plan = plan
        liveNavigation.nodeCount, liveNavigation.planMilliseconds = #nodes, (os.clock() - began) * 1000
    end
    return plan
end

-- Discovery visits chest locations only and expands as more chest parts stream in.
-- It is separate from dynamic farming and never treats a visit as collection evidence.
local function addDiscoveryRegion(record)
    local position = enforceAltitudeFloor(record.position)
    for _, region in ipairs(discovery.regions) do
        if (region.position - position).Magnitude <= DISCOVERY_RADIUS then return end
    end
    table.insert(discovery.regions, {position = position, name = record.name, record = record, visits = 0})
end
local function collectDiscoverySeeds(force)
    if not discovery.active then return end
    local now = os.clock()
    if not force and now - discovery.lastSeedScan < 1 then return end
    discovery.lastSeedScan = now
    for _, record in ipairs(records) do
        if not discovery.seededRecords[record.id] then
            discovery.seededRecords[record.id] = true
            addDiscoveryRegion(record)
        end
    end
end
local function discoveryNode(region)
    if region.record.geometry then
        local low, high = triggerBounds(region.record)
        return {position = (low + high) * 0.5, halfSize = (high - low) * 0.5}
    end
    return {position = region.position}
end
local function chooseDiscovery(root, speed)
    collectDiscoverySeeds(true)
    local nearest, distance
    for _, region in ipairs(discovery.regions) do
        local trigger = loadedTrigger(region.record)
        if not region.visited and trigger and not trigger.CanTouch then
            -- Its state is already observed; discovery does not need a trip to an empty chest.
            region.visited = true
            discovery.completed += 1
        end
        if not region.visited then
            local entry = Planner.sweepPath(discoveryNode(region), root.Position, C.SweepMargin)
            local candidate = Planner.travelSeconds(root.Position, entry, speed)
            if candidate <= MAX_TRAVEL_SECONDS and (not distance or candidate < distance) then
                nearest, distance = region, candidate
            end
        end
    end
    if not nearest then
        for _, region in ipairs(discovery.regions) do
            if not region.visited then region.visited = true; discovery.skipped += 1 end
        end
        discovery.active = false
        log(string.format("Discovery complete: %d areas sampled, %d chest locations remembered, %d far areas skipped",
            discovery.completed, #records, discovery.skipped))
    end
    return nearest
end
local function discoverArea(boat, seat, region)
    local _, root = parts()
    if not root then return "interrupted" end
    local entryPoint, centerPoint, exitPoint = Planner.sweepPath(discoveryNode(region), root.Position, C.SweepMargin)
    local nearRecords = {}
    for _, record in ipairs(records) do
        if (record.position - region.position).Magnitude <= DISCOVERY_RADIUS then table.insert(nearRecords, record) end
    end
    liveNavigation.plan = nil
    currentRouteDestination, currentTargetRecords = entryPoint, nearRecords
    currentTargetBoxCenter, currentNextRoutePosition = centerPoint, nil
    display(string.format("Discovering %d/%d Â· %s", discovery.completed + 1, #discovery.regions, region.name))
    local job
    local knownRecordCount = #records
    local function streamGuard(_, _, remaining)
        refreshChests()
        local trigger = loadedTrigger(region.record)
        if trigger and not trigger.CanTouch then return "unavailable" end
        for index = knownRecordCount + 1, #records do
            local record = records[index]
            if (record.position - region.position).Magnitude <= DISCOVERY_RADIUS then
                table.insert(nearRecords, record)
            end
        end
        knownRecordCount = #records
        if not job and remaining <= liveNavigation.speed * STREAM_TIMEOUT + DISCOVERY_RADIUS then
            job = requestStream(region.position)
        end
    end
    local outcome = move3D(boat, seat, entryPoint, nearRecords, streamGuard)
    if outcome == "arrived" then
        if workspace.StreamingEnabled and not loadedTrigger(region.record) and (not job or not job.done) then
            job = job or requestStream(region.position)
            pauseFlight()
            local deadline = workspace:GetServerTimeNow() + STREAM_TIMEOUT
            repeat
                RunService.Heartbeat:Wait()
                refreshChests()
                if not job then job = requestStream(region.position) end
            until stopped or loadedTrigger(region.record) or (job and job.done) or workspace:GetServerTimeNow() >= deadline
        end
        refreshChests(true)
        collectDiscoverySeeds(true)
        if available(loadedTrigger(region.record)) then
            currentRouteDestination = exitPoint
            outcome = move3D(boat, seat, exitPoint, nearRecords)
        end
        if outcome == "arrived" then
            region.visited = true
            discovery.completed += 1
        elseif outcome == "timeout" then
            region.visits += 1
            if region.visits >= 2 then region.visited = true; discovery.skipped += 1 end
        end
    elseif outcome == "timeout" then
        region.visits += 1
        if region.visits >= 2 then region.visited = true; discovery.skipped += 1 end
    end
    currentRouteDestination, currentTargetBoxCenter = nil, nil
    currentTargetRecords, currentNextRoutePosition = nil, nil
    return outcome
end

updateSmallDetails = function()
    local ready, expected, waiting, confirmed, loaded = 0, 0, 0, 0, 0
    local now = workspace:GetServerTimeNow()
    for _, record in ipairs(records) do
        confirmed += record.successes or 0
        if loadedTrigger(record) then loaded += 1 end
        local state = chestStatus(record, now)
        if state == "ready" then ready += 1
        elseif state == "remembered" then expected += 1
        else waiting += 1 end
    end
    availabilityLabel.Text = string.format("%d live Â· %d expected Â· %d cooling/empty", ready, expected, waiting)
    if discovery.active then
        nextPassLabel.Text = string.format("Discovery %d/%d areas Â· %d known chests",
            discovery.completed + discovery.skipped, #discovery.regions, #records)
        plannerLabel.Text = string.format("%d loaded Â· %d confirmed Â· learning locations", loaded, confirmed)
        return
    end
    local plan = liveNavigation.plan
    if plan then
        local _, root = parts()
        local seconds = root and Planner.travelSeconds(root.Position,
            Planner.sweepPath(plan.first, root.Position, C.SweepMargin), liveNavigation.speed or C.BoatSpeed) or 0
        nextPassLabel.Text = string.format("Next pass ~%s Â· ETA %.1fs", formatMoney(plan.first.value), seconds)
    else
        nextPassLabel.Text = "Watching known chest respawnsâ€¦"
    end
    plannerLabel.Text = string.format("%d confirmed Â· %d candidate stops Â· %d ahead",
        confirmed, liveNavigation.nodeCount, plan and #plan.route or 0)
end

local function installChestMap()
    if not LOAD_UI then return end
    local inputService = game:GetService("UserInputService")
    local guiService = game:GetService("GuiService")
    local colors = {
        ready = Color3.fromRGB(99, 225, 160), predicted = Color3.fromRGB(255, 204, 111),
        remembered = Color3.fromRGB(125, 190, 255),
        unknown = Color3.fromRGB(126, 166, 231), empty = Color3.fromRGB(113, 125, 143),
        target = Color3.fromRGB(255, 113, 132), dealer = Color3.fromRGB(186, 147, 247),
    }
    local function rounded(object, radius)
        Instance.new("UICorner", object).CornerRadius = UDim.new(0, radius)
    end
    local function text(parent, value, size, color)
        local item = Instance.new("TextLabel")
        item.BackgroundTransparency = 1
        item.Font = Enum.Font.Gotham
        item.TextSize = size
        item.TextColor3 = color or light
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.TextTruncate = Enum.TextTruncate.AtEnd
        item.Text = value
        item.Parent = parent
        return item
    end
    local frame = Instance.new("Frame")
    frame.Name = "ChestMap"
    frame.Visible = false
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(19, 24, 33)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    rounded(frame, 12)
    local border = Instance.new("UIStroke", frame)
    border.Color = Color3.fromRGB(57, 69, 87)
    local heading = text(frame, "CHEST MAP Â· LIVE ROUTE", 16)
    heading.Font = Enum.Font.GothamBold
    heading.Position, heading.Size = UDim2.fromOffset(14, 10), UDim2.new(1, -64, 0, 24)
    local subtitle = text(frame, "Finding nearby spawnsâ€¦", 11, muted)
    subtitle.Position, subtitle.Size = UDim2.fromOffset(14, 36), UDim2.new(1, -28, 0, 18)
    local function button(value, x, width, y)
        local item = Instance.new("TextButton")
        item.Text, item.Font, item.TextSize = value, Enum.Font.GothamMedium, 12
        item.TextColor3 = light
        item.BackgroundColor3 = Color3.fromRGB(38, 47, 62)
        item.BorderSizePixel = 0
        item.Position, item.Size = UDim2.fromOffset(x, y or 62), UDim2.fromOffset(width, 32)
        item.Parent = frame
        rounded(item, 6)
        return item
    end
    local fitButton = button("Fit", 12, 42)
    local followButton = button("Follow", 60, 62)
    local timersButton = button("Timers Off", 128, 88)
    local minusButton = button("âˆ’", 222, 32)
    local plusButton = button("+", 260, 32)
    local closeButton = button("Ã—", 0, 30, 8)
    closeButton.Position = UDim2.new(1, -42, 0, 8)
    local canvas = Instance.new("Frame")
    canvas.Position, canvas.Size = UDim2.fromOffset(12, 104), UDim2.new(1, -24, 1, -234)
    canvas.BackgroundColor3 = Color3.fromRGB(25, 33, 45)
    canvas.BorderSizePixel = 0
    canvas.ClipsDescendants = true
    canvas.Parent = frame
    local function footer(value, y, height, size)
        local item = text(frame, value, size or 11, muted)
        item.Position, item.Size = UDim2.new(0, 14, 1, y), UDim2.new(1, -28, 0, height)
        return item
    end
    local legend = footer('', -120, 18, 11)
    legend.RichText = true
    legend.Text = '<font color="#63E1A0">â—</font> Live   <font color="#7DBEFF">â—</font> Expected   <font color="#FFCC6F">â—</font> Cooling'
    local legend2 = footer('', -102, 18, 11)
    legend2.RichText = true
    legend2.Text = '<font color="#717D8F">â—</font> Empty   <font color="#FF7184">â—</font> Target   <font color="#BA93F7">â—†</font> Dealer   <font color="#FFFFFF">â–²</font> You'
    local help = footer("Drag to pan Â· Tap a group to zoom Â· S / G / D = grade", -81, 18, 10)
    local details = footer("Tap a chest for its value, distance and respawn time.", -60, 50, 12)
    details.TextWrapped, details.TextTruncate = true, Enum.TextTruncate.None
    details.TextYAlignment = Enum.TextYAlignment.Top
    details.TextColor3 = light

    local center, pixelsPerStud = Vector2.zero, 0.1
    local initialized, follow, timers = false, false, false
    local autoFitUntil, fittedRecordCount = os.clock() + 2, 0
    local selected, selectedGroup = nil, nil
    local dirty, lastRefresh, suppressClickUntil = true, 0, 0
    local markerPool, dealerPool, gridPool = {}, {}, {}
    local lastViewport = Vector2.zero
    local function flat(position) return Vector2.new(position.X, position.Z) end
    local function project(position)
        local delta = flat(position) - center
        return canvas.AbsoluteSize * 0.5 + Vector2.new(delta.X, -delta.Y) * pixelsPerStud
    end
    local function unproject(point)
        local delta = (point - canvas.AbsoluteSize * 0.5) / pixelsPerStud
        return center + Vector2.new(delta.X, -delta.Y)
    end
    local function isInRange(position, root)
        return not root or (flat(position) - flat(root.Position)).Magnitude <= MAP_OUTLIER_DISTANCE
    end
    local function countdown(seconds)
        local value = math.max(0, math.ceil(seconds))
        return string.format("%d:%02d", math.floor(value / 60), value % 60)
    end
    local function status(record, now)
        return chestStatus(record, now)
    end
    local function setFollow(value)
        follow = value
        followButton.Text = value and "Following" or "Follow"
        followButton.BackgroundColor3 = value and Color3.fromRGB(39, 87, 100) or Color3.fromRGB(38, 47, 62)
    end
    local function fit()
        local _, root = parts()
        if not root then return end
        local low, high = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
        local count = 0
        local function include(position)
            local p = flat(position)
            low = Vector2.new(math.min(low.X, p.X), math.min(low.Y, p.Y))
            high = Vector2.new(math.max(high.X, p.X), math.max(high.Y, p.Y))
        end
        for _, record in ipairs(records) do
            if isInRange(record.position, root) then include(record.position); count += 1 end
        end
        if root then include(root.Position) end
        if low.X == math.huge then return end
        center = (low + high) * 0.5
        local size, span = canvas.AbsoluteSize, high - low
        pixelsPerStud = math.clamp(math.min(math.max(40, size.X - 64) / math.max(200, span.X),
            math.max(40, size.Y - 64) / math.max(200, span.Y)), 0.002, 4)
        initialized = count > 0
        setFollow(false)
        dirty = true
    end
    local function zoom(factor, point)
        autoFitUntil = 0
        point = point or canvas.AbsoluteSize * 0.5
        local before = unproject(point)
        pixelsPerStud = math.clamp(pixelsPerStud * factor, 0.002, 4)
        center += before - unproject(point)
        setFollow(false)
        dirty = true
    end
    local function line(color, thickness)
        local item = Instance.new("Frame")
        item.BorderSizePixel, item.BackgroundColor3 = 0, color
        item.AnchorPoint = Vector2.new(0.5, 0.5)
        item.ZIndex = 2
        item.Size = UDim2.fromOffset(0, thickness or 2)
        item.Parent = canvas
        return item
    end
    local routeLine, nextLine = line(Color3.fromRGB(88, 205, 237)), line(colors.predicted)
    routeLine.ZIndex, nextLine.ZIndex = 3, 3
    local lookaheadLines = {}
    local function drawLine(item, a, b)
        item.Visible = a ~= nil and b ~= nil
        if not item.Visible then return end
        -- Clip before rotating so a long route cannot spill across the surrounding UI.
        local travel, enter, leave = b - a, 0, 1
        local function clip(p, q)
            if math.abs(p) < 1e-9 then return q >= 0 end
            local ratio = q / p
            if p < 0 then enter = math.max(enter, ratio) else leave = math.min(leave, ratio) end
            return enter <= leave
        end
        local bounds = canvas.AbsoluteSize
        if not (clip(-travel.X, a.X) and clip(travel.X, bounds.X - a.X)
            and clip(-travel.Y, a.Y) and clip(travel.Y, bounds.Y - a.Y)) then
            item.Visible = false
            return
        end
        b, a = a + travel * leave, a + travel * enter
        local delta, midpoint = b - a, (a + b) * 0.5
        item.Position, item.Size = UDim2.fromOffset(midpoint.X, midpoint.Y),
            UDim2.fromOffset(delta.Magnitude, item.Size.Y.Offset)
        item.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    end
    local playerDot = text(canvas, "â–²", 23, Color3.new(1, 1, 1))
    playerDot.AnchorPoint, playerDot.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(26, 26)
    playerDot.TextXAlignment, playerDot.ZIndex = Enum.TextXAlignment.Center, 7
    playerDot.TextStrokeTransparency = 0.3
    local scaleLabel = text(canvas, "", 10, muted)
    scaleLabel.Position, scaleLabel.Size, scaleLabel.ZIndex = UDim2.fromOffset(8, 6), UDim2.new(1, -16, 0, 16), 8

    local function newMarker()
        local item = {}
        item.button = Instance.new("TextButton")
        local b = item.button
        b.AnchorPoint, b.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(inputService.TouchEnabled and 34 or 24, inputService.TouchEnabled and 34 or 24)
        b.Font, b.TextSize, b.TextColor3 = Enum.Font.GothamBold, 11, Color3.fromRGB(17, 24, 33)
        b.BorderSizePixel, b.ZIndex, b.Parent = 0, 4, canvas
        rounded(b, 12)
        item.stroke = Instance.new("UIStroke", b)
        item.stroke.ApplyStrokeMode, item.stroke.Thickness = Enum.ApplyStrokeMode.Border, 2
        item.timer = text(canvas, "", 10, colors.predicted)
        item.timer.BackgroundColor3, item.timer.BackgroundTransparency = Color3.fromRGB(15, 21, 30), 0.05
        item.timer.TextXAlignment, item.timer.Size, item.timer.ZIndex = Enum.TextXAlignment.Center, UDim2.fromOffset(52, 18), 6
        rounded(item.timer, 4)
        table.insert(connections, b.Activated:Connect(function()
            if os.clock() < suppressClickUntil or not item.group then return end
            local group = item.group
            selectedGroup, selected = group.records, group.records[1]
            if #group.records > 1 then
                if pixelsPerStud >= 4 then
                    item.inspectIndex = (item.inspectIndex or 0) % #group.records + 1
                    selected, selectedGroup = group.records[item.inspectIndex], nil
                else
                    center = group.world / #group.records
                    pixelsPerStud = math.min(4, pixelsPerStud * 2.2)
                end
                autoFitUntil = 0
                setFollow(false)
            end
            dirty = true
        end))
        return item
    end
    local function layout()
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000, 700)
        if not gui.IgnoreGuiInset then
            local topLeft, bottomRight = guiService:GetGuiInset()
            viewport -= topLeft + bottomRight
        end
        if viewport == lastViewport then return end
        lastViewport = viewport
        local touch = inputService.TouchEnabled
        local width = math.max(260, math.min(520, viewport.X - 16))
        local height = math.max(240, math.min(600, viewport.Y - 16))
        frame.Size = UDim2.fromOffset(width, height)
        frame.Position = UDim2.new(1, -8, 0, touch and 8 or math.min(76, math.max(8, (viewport.Y - height) * 0.5)))
        local controls = {fitButton, followButton, timersButton, minusButton, plusButton}
        local controlWidth = (width - 40) / #controls
        for index, control in ipairs(controls) do
            control.Size = UDim2.fromOffset(controlWidth, touch and 42 or 32)
            control.Position = UDim2.fromOffset(12 + (index - 1) * (controlWidth + 4), 60)
            control.TextSize = controlWidth < 65 and 10 or 12
        end
        closeButton.Size = UDim2.fromOffset(touch and 42 or 30, touch and 42 or 32)
        closeButton.Position = UDim2.new(1, touch and -50 or -42, 0, 6)
        local compact = height < 430
        local canvasTop = touch and 110 or 104
        local footerHeight = compact and 108 or 130
        canvas.Position = UDim2.fromOffset(12, canvasTop)
        canvas.Size = UDim2.new(1, -24, 1, -canvasTop - footerHeight)
        legend.Visible = not compact
        legend2.Position = UDim2.new(0, 14, 1, compact and -98 or -102)
        help.Position = UDim2.new(0, 14, 1, compact and -78 or -81)
        details.Position = UDim2.new(0, 14, 1, -58)
        details.TextSize = compact and 11 or 12
        panel.Visible = not (touch and frame.Visible)
        dirty = true
    end
    local function render()
        local _, root = parts()
        local now, size = workspace:GetServerTimeNow(), canvas.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then return end
        if not initialized or (#records ~= fittedRecordCount and os.clock() < autoFitUntil) then
            fit()
            fittedRecordCount = #records
        end
        if follow and root then center = flat(root.Position) end
        local targets = {}
        for _, record in ipairs(currentTargetRecords or {}) do targets[record] = true end
        local groups, bins = {}, {}
        local ready, expected, respawning, omitted, visible = 0, 0, 0, 0, 0
        for _, record in ipairs(records) do
            if not isInRange(record.position, root) then omitted += 1; continue end
            local state, p = status(record, now), project(record.position)
            if state == "ready" then ready += 1 elseif state == "remembered" then expected += 1
            elseif state == "predicted" then respawning += 1 end
            local markerInset = inputService.TouchEnabled and 19 or 14
            if p.X < markerInset or p.Y < 26 or p.X > size.X - markerInset or p.Y > size.Y - markerInset then continue end
            visible += 1
            local spacing = inputService.TouchEnabled and 42 or 30
            local bx, by = math.floor(p.X / spacing), math.floor(p.Y / spacing)
            local group
            for x = bx - 1, bx + 1 do
                for y = by - 1, by + 1 do
                    for _, candidate in ipairs(bins[x .. ":" .. y] or {}) do
                        if (candidate.point - p).Magnitude < spacing then group = candidate; break end
                    end
                    if group then break end
                end
                if group then break end
            end
            if not group then
                group = {point = p, world = Vector2.zero, records = {}, ready = 0, target = false, state = state}
                table.insert(groups, group)
                local key = bx .. ":" .. by
                bins[key] = bins[key] or {}
                table.insert(bins[key], group)
            end
            table.insert(group.records, record)
            group.world += flat(record.position)
            group.target = group.target or targets[record] == true
            if state == "ready" then group.ready += 1; group.state = "ready" end
            if state == "remembered" and group.ready == 0 then group.state = "remembered" end
            if state == "predicted" then
                group.remaining = math.min(group.remaining or math.huge, record.readyAt - now)
                if group.ready == 0 and group.state ~= "remembered" then group.state = "predicted" end
            end
        end
        -- A world-aligned grid and distance key give scale without inventing terrain.
        local rawStep = 70 / pixelsPerStud
        local power = 10 ^ math.floor(math.log10(rawStep))
        local step = math.ceil(rawStep / power) * power
        local topLeft = unproject(Vector2.zero)
        local gridCount = 0
        local function gridLine(position, dimensions)
            gridCount += 1
            local item = gridPool[gridCount]
            if not item then
                item = Instance.new("Frame")
                item.BackgroundColor3, item.BorderSizePixel, item.ZIndex, item.Parent = Color3.fromRGB(36, 46, 61), 0, 1, canvas
                gridPool[gridCount] = item
            end
            item.Position, item.Size, item.Visible = position, dimensions, true
        end
        local firstX = (math.ceil(topLeft.X / step) * step - topLeft.X) * pixelsPerStud
        local firstY = (topLeft.Y - math.floor(topLeft.Y / step) * step) * pixelsPerStud
        for x = firstX, size.X, step * pixelsPerStud do gridLine(UDim2.fromOffset(x, 0), UDim2.fromOffset(1, size.Y)) end
        for y = firstY, size.Y, step * pixelsPerStud do gridLine(UDim2.fromOffset(0, y), UDim2.fromOffset(size.X, 1)) end
        for i = gridCount + 1, #gridPool do gridPool[i].Visible = false end
        local route = liveNavigation.plan and liveNavigation.plan.route or {}
        scaleLabel.Text = string.format("+Z â†‘ Â· grid %s Â· purple: lookahead Â· cyan: current Â· gold: next", tostring(step))
        local segmentCount = math.max(0, #route - 1)
        local createdSegments = 0
        for index = 1, segmentCount do
            local segment = lookaheadLines[index]
            if not segment then
                if createdSegments >= 24 then dirty = true; break end
                segment = line(Color3.fromRGB(180, 115, 255), 2)
                segment.BackgroundTransparency = 0.25
                local direction = text(segment, "â–¶", 12, Color3.fromRGB(216, 174, 255))
                direction.Name = "Direction"
                direction.AnchorPoint = Vector2.new(0.5, 0.5)
                direction.Position = UDim2.new(0.62, 0, 0.5, 0)
                direction.Size = UDim2.fromOffset(14, 14)
                direction.TextXAlignment = Enum.TextXAlignment.Center
                direction.TextStrokeTransparency = 0.35
                direction.ZIndex = 2
                lookaheadLines[index] = segment
                createdSegments += 1
            end
            local fromStop, toStop = route[index], route[index + 1]
            if isInRange(fromStop.position, root) and isInRange(toStop.position, root) then
                drawLine(segment, project(fromStop.position), project(toStop.position))
            else
                segment.Visible = false
            end
            local direction = segment:FindFirstChild("Direction")
            if direction then direction.Visible = segment.Visible and segment.Size.X.Offset >= 26 end
        end
        for index = segmentCount + 1, #lookaheadLines do lookaheadLines[index].Visible = false end
        -- Place timer labels only in free space; the selected chest always has a detailed countdown below.
        local occupied = {}
        for _, group in ipairs(groups) do
            table.insert(occupied, {group.point.X - 14, group.point.Y - 14, group.point.X + 14, group.point.Y + 14})
        end
        for i, group in ipairs(groups) do
            local item = markerPool[i]
            if not item then item = newMarker(); markerPool[i] = item end
            item.group = group
            local b, p = item.button, group.point
            b.Visible, b.Position = true, UDim2.fromOffset(p.X, p.Y)
            b.BackgroundColor3 = colors[group.state]
            b.Text = #group.records > 1 and tostring(#group.records) or gradeOf(group.records[1]):sub(1, 1)
            item.stroke.Color = group.target and colors.target or (selected and table.find(group.records, selected) and light or Color3.fromRGB(15, 22, 32))
            item.stroke.Thickness = group.target and 3 or 2
            item.timer.Visible = false
            if timers and group.remaining then
                for _, offset in ipairs({Vector2.new(-26, -34), Vector2.new(-26, 16), Vector2.new(16, -9), Vector2.new(-68, -9)}) do
                    local origin = p + offset
                    local rect = {origin.X, origin.Y, origin.X + 52, origin.Y + 18}
                    local free = rect[1] >= 0 and rect[2] >= 24 and rect[3] <= size.X and rect[4] <= size.Y
                    if free then
                        for _, other in ipairs(occupied) do
                            if rect[1] < other[3] and rect[3] > other[1] and rect[2] < other[4] and rect[4] > other[2] then free = false; break end
                        end
                    end
                    if free then
                        item.timer.Position = UDim2.fromOffset(origin.X, origin.Y)
                        item.timer.Text = "~" .. countdown(group.remaining)
                        item.timer.Visible = true
                        table.insert(occupied, rect)
                        break
                    end
                end
            end
        end
        for i = #groups + 1, #markerPool do markerPool[i].button.Visible = false; markerPool[i].timer.Visible = false end
        local dealerCount = 0
        for _, dealer in ipairs(dealerList) do
            if dealer.instance and isInRange(dealer.position, root) then
                local p = project(dealer.position)
                if p.X >= 12 and p.Y >= 24 and p.X <= size.X - 12 and p.Y <= size.Y - 12 then
                    dealerCount += 1
                    local item = dealerPool[dealerCount]
                    if not item then
                        item = text(canvas, "â—†", 19, colors.dealer)
                        item.AnchorPoint, item.Size, item.ZIndex = Vector2.new(0.5, 0.5), UDim2.fromOffset(20, 20), 3
                        item.TextXAlignment = Enum.TextXAlignment.Center
                        dealerPool[dealerCount] = item
                    end
                    item.Position, item.Visible = UDim2.fromOffset(p.X, p.Y), true
                end
            end
        end
        for i = dealerCount + 1, #dealerPool do dealerPool[i].Visible = false end
        playerDot.Visible = root ~= nil
        if root then
            local p, look = project(root.Position), root.CFrame.LookVector
            playerDot.Position = UDim2.fromOffset(p.X, p.Y)
            playerDot.Rotation = math.deg(math.atan2(look.X, look.Z))
        end
        drawLine(routeLine, root and project(root.Position), currentRouteDestination and project(currentRouteDestination))
        drawLine(nextLine, currentTargetBoxCenter and project(currentTargetBoxCenter), currentNextRoutePosition and project(currentNextRoutePosition))
        subtitle.Text = string.format("%d live Â· %d expected Â· %d cooling Â· %d far hidden", ready, expected, respawning, omitted)
        help.Text = string.format("%d in view Â· Drag to pan Â· Tap groups to zoom Â· S/G/D = grade", visible)
        if selected then
            local state = status(selected, now)
            local reward = economyOf(selected).rewards[REWARD_SEA]
            local distance = root and (selected.position - root.Position).Magnitude or 0
            if selectedGroup and #selectedGroup > 1 then
                local groupReady, value = 0, 0
                for _, record in ipairs(selectedGroup) do
                    if status(record, now) == "ready" then groupReady += 1 end
                    local range = economyOf(record).rewards[REWARD_SEA]
                    value += (range[1] + range[2]) * 0.5
                end
                local hint = pixelsPerStud >= 4 and "Tap the group again to inspect each overlapping chest."
                    or "Zoom in, then tap a letter to inspect a single chest."
                details.Text = string.format("%d chests Â· %d ready Â· ~%s total value\n%s", #selectedGroup, groupReady, formatMoney(value), hint)
            else
                local stateText = state == "predicted" and ((selected.initiallyEmptyAt and "Ready by ~" or "Respawn ~") .. countdown(selected.readyAt - now))
                    or state == "remembered" and "Expected ready Â· unloaded"
                    or state == "unknown" and "Unverified / streamed out"
                    or state == "ready" and "Ready to collect" or "Empty"
                details.Text = string.format("%s Â· %s Â· %.0f studs\n%s Â· %sâ€“%s Â· %d confirmed pickups",
                    gradeOf(selected), selected.name, distance,
                    stateText, formatMoney(reward[1]), formatMoney(reward[2]), selected.successes or 0)
            end
        else
            local plan = liveNavigation.plan
            if plan then
                details.Text = string.format("Next pass: %d chests Â· ~%s value\n%d stops ahead Â· blue = expected while unloaded",
                    #plan.first.records, formatMoney(plan.first.value), #plan.route)
            else
                details.Text = "Locations and states stay in memory when unloaded.\nTap a chest for value, distance and respawn time."
            end
        end
    end

    table.insert(connections, fitButton.Activated:Connect(fit))
    table.insert(connections, followButton.Activated:Connect(function() setFollow(not follow); dirty = true end))
    table.insert(connections, plusButton.Activated:Connect(function() zoom(1.6) end))
    table.insert(connections, minusButton.Activated:Connect(function() zoom(1 / 1.6) end))
    table.insert(connections, timersButton.Activated:Connect(function()
        timers = not timers
        timersButton.Text = timers and "Timers On" or "Timers Off"
        timersButton.BackgroundColor3 = timers and Color3.fromRGB(87, 71, 38) or Color3.fromRGB(38, 47, 62)
        dirty = true
    end))
    local function toggle()
        frame.Visible = not frame.Visible
        panel.Visible = not (inputService.TouchEnabled and frame.Visible)
        mapButton.BackgroundColor3 = frame.Visible and Color3.fromRGB(45, 75, 95) or Color3.fromRGB(55, 60, 70)
        dirty = true
    end
    table.insert(connections, closeButton.Activated:Connect(toggle))
    table.insert(connections, mapButton.Activated:Connect(toggle))
    local dragInput, dragStart, dragCenter, dragged
    local function inside(position)
        local inset = not gui.IgnoreGuiInset and guiService:GetGuiInset() or Vector2.zero
        local p = Vector2.new(position.X, position.Y) - inset - canvas.AbsolutePosition
        return p.X >= 0 and p.Y >= 0 and p.X <= canvas.AbsoluteSize.X and p.Y <= canvas.AbsoluteSize.Y, p
    end
    table.insert(connections, inputService.InputBegan:Connect(function(input)
        if not frame.Visible or not gui.Parent or dragInput then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if not inside(input.Position) then return end
        dragInput, dragStart, dragCenter, dragged = input, Vector2.new(input.Position.X, input.Position.Y), center, false
    end))
    table.insert(connections, inputService.InputChanged:Connect(function(input)
        if not frame.Visible then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local hit, p = inside(inputService:GetMouseLocation())
            if hit then zoom(input.Position.Z > 0 and 1.3 or 1 / 1.3, p) end
        elseif dragInput and (input == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            if delta.Magnitude > 4 then dragged = true end
            if dragged then
                autoFitUntil = 0
                center = dragCenter + Vector2.new(-delta.X, delta.Y) / pixelsPerStud
                suppressClickUntil = os.clock() + 0.25
                setFollow(false)
                dirty = true
            end
        end
    end))
    table.insert(connections, inputService.InputEnded:Connect(function(input)
        if input == dragInput then
            if dragged then suppressClickUntil = os.clock() + 0.25 end
            dragInput = nil
        end
    end))
    layout()
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if stopped or not gui.Parent or not frame.Visible then return end
        layout()
        local now = os.clock()
        if now - lastRefresh < (dirty and 1 / 30 or C.MapRefreshSeconds) then return end
        lastRefresh, dirty = now, false
        render()
    end))
end
installChestMap()


-- TRACERS & GOLD 100x100x100 HITBOX VISUALIZER
local traceParts = {}
if SHOW_ROUTE_TRACERS or SHOW_HITBOX_VISUALIZER then
    local hitboxes = {}
    local function getHitbox(index)
        if hitboxes[index] then return hitboxes[index] end
        local part = Instance.new("Part")
        part.Name = "Hitbox100VisualizerPart"
        part.Size, part.Transparency = HITBOX_SIZE, 1
        part.Anchored = true -- Visual marker only; never anchors the character or boat.
        part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
        part.Parent = workspace.Terrain
        local outline = Instance.new("SelectionBox")
        outline.Name = "Hitbox100GoldOutline"
        outline.Color3 = Theme.Red
        outline.LineThickness, outline.SurfaceTransparency = 0.25, 1
        outline.Adornee, outline.Visible = part, false
        outline.Parent = workspace.Terrain
        local item = {part = part, outline = outline}
        hitboxes[index] = item
        table.insert(traceParts, outline)
        table.insert(traceParts, part)
        return item
    end
    local function makeTracer(name, color)
        local from = Instance.new("Attachment", workspace.Terrain)
        local dest = Instance.new("Attachment", workspace.Terrain)
        local beam = Instance.new("Beam", workspace.Terrain)
        beam.Name = name
        beam.Attachment0, beam.Attachment1 = from, dest
        beam.FaceCamera, beam.Segments = true, 1
        beam.Width0, beam.Width1 = 0.35, 0.35
        beam.Color, beam.Transparency = ColorSequence.new(color), NumberSequence.new(0.2)
        beam.Enabled = false
        table.insert(traceParts, beam)
        table.insert(traceParts, from)
        table.insert(traceParts, dest)
        return {from = from, dest = dest, beam = beam}
    end
    local currentTrace = SHOW_ROUTE_TRACERS and makeTracer("FarmRouteCurrent", Theme.Red)
    local nextTrace = SHOW_ROUTE_TRACERS and makeTracer("FarmRouteNext", Theme.Red:Lerp(Theme.Text, 0.3))
    local function updateTracer(tracer, from, dest)
        if not tracer then return end
        tracer.beam.Enabled = from ~= nil and dest ~= nil
        if tracer.beam.Enabled then
            tracer.from.WorldPosition, tracer.dest.WorldPosition = from, dest
        end
    end
    table.insert(connections, RunService.RenderStepped:Connect(function()
        local _, root = parts()
        -- Follow the hub's accent, including live changes in Ajustes.
        local currentColor = Theme.Red
        local nextColor = Theme.Red:Lerp(Theme.Text, 0.3)
        if currentTrace and currentTrace.beam.Color.Keypoints[1].Value ~= currentColor then
            currentTrace.beam.Color = ColorSequence.new(currentColor)
        end
        if nextTrace and nextTrace.beam.Color.Keypoints[1].Value ~= nextColor then
            nextTrace.beam.Color = ColorSequence.new(nextColor)
        end
        local count = 0
        local function showHitbox(frame)
            count += 1
            local item = getHitbox(count)
            if item.part.CFrame ~= frame then item.part.CFrame = frame end
            item.outline.Color3 = Theme.Red
            item.outline.Visible = true
        end
        if not stopped and root and SHOW_HITBOX_VISUALIZER then
            -- Draw each real chest in the pass, including cached geometry when unloaded.
            for _, record in ipairs(currentTargetRecords or {}) do
                local trigger = loadedTrigger(record)
                local frame = trigger and trigger.CFrame or (record.geometry and record.geometry.cframe)
                if frame then showHitbox(frame) end
            end
            if count == 0 and currentTargetBoxCenter then showHitbox(CFrame.new(currentTargetBoxCenter)) end
        end
        for index = count + 1, #hitboxes do hitboxes[index].outline.Visible = false end
        local enabled = not stopped and root ~= nil and SHOW_ROUTE_TRACERS
        updateTracer(currentTrace, enabled and root.Position or nil, enabled and currentRouteDestination or nil)
        updateTracer(nextTrace, enabled and currentTargetBoxCenter or nil, enabled and currentNextRoutePosition or nil)
    end))
end

-- MAIN FARM LOOP
-- An immediately completed/rejected leg must not restart planning indefinitely in one frame.
local farmFrame = 0
table.insert(connections, RunService.Heartbeat:Connect(function() farmFrame += 1 end))
;(function()
    local ok, err = xpcall(function()
        display("Preparing chest locationsâ€¦")
        local startupDeadline = os.clock() + C.CharacterTimeout
        while not stopped and (not initialScanComplete or not game:IsLoaded()) and os.clock() < startupDeadline do
            RunService.Heartbeat:Wait()
        end
        if stopped then return end
        refreshChests(true)
        local startupBalance = readBeli()
        if startupBalance then
            lastPickupBalance = startupBalance
            if startingBeli == nil then
                startingBeli, moneyStarted = startupBalance, workspace:GetServerTimeNow()
            end
        end
        if not initialScanComplete then log("Initial discovery still running; continuing with known spawns") end
        local lastPlanningFrame = -1
        while not stopped do
            if farmFrame == lastPlanningFrame then RunService.Heartbeat:Wait() end
            if stopped then break end
            lastPlanningFrame = farmFrame
            scanDealers()
            refreshChests()
            local _, root = waitCharacter(C.CharacterTimeout)
            if stopped then break end
            if not root then task.wait(0.5); continue end

            -- Resolve Boat or seamless Foot mode
            local boat, seat = getActiveVehicleOrCharacter()
            local currentSpeed = boat and C.BoatSpeed or C.Speed

            liveNavigation.speed = currentSpeed
            if discovery.active then
                local region = chooseDiscovery(root, currentSpeed)
                if region then
                    discoverArea(boat, seat, region)
                    continue
                end
            end
            local plan = choose(root, nil, currentSpeed)
            if not plan then
                liveNavigation.plan = nil
                currentRouteDestination, currentTargetBoxCenter = nil, nil
                currentTargetRecords, currentNextRoutePosition = nil, nil
                display("Watching known chest respawnsâ€¦")
                pauseFlight()
                task.wait(C.PollSeconds)
                continue
            end
            local node = plan.node
            currentNextRoutePosition = plan.route and plan.route[2] and plan.route[2].position or nil
            display(string.format("%s Â· %s", boat and "Boat" or "Foot",
                node.isCluster and ("Cluster (" .. node.clusterCount .. " chests)") or node.record.name))

            -- Execute direct 3D flight (auto-adjusts speed and physics based on boat or foot)
            local outcome = flyThroughTarget(boat, seat, node)

            if outcome ~= "arrived" and outcome ~= "unavailable" and outcome ~= "interrupted" and outcome ~= "reroute" then
                for _, record in ipairs(node.records or {node.record}) do
                    record.failures = (record.failures or 0) + 1
                    record.cooldown = workspace:GetServerTimeNow() + 10
                end
            end
        end
    end, debug.traceback)

    stopped = true
    if bridge.cleanupApproach then bridge.cleanupApproach() end
    pauseFlight()
    if boatSeatCleanupConnection then boatSeatCleanupConnection:Disconnect() end
    preparedBoat = nil
    if persistentNoclipConn then persistentNoclipConn:Disconnect() end
    restoreFlightCollision()
    if persistentLinearVelocity then persistentLinearVelocity:Destroy() end
    if persistentAttachment then persistentAttachment:Destroy() end
    for _, conn in ipairs(connections) do conn:Disconnect() end
    for _, part in ipairs(traceParts) do part:Destroy() end
    for part, original in pairs(chestOriginals) do
        if part.Parent then
            pcall(function()
                part.Size = original.size
                part.CanCollide = original.canCollide
            end)
        end
    end
    if ok then
        gui:Destroy()
    else
        titleLabel.Text = "Chest Farm Â· Error"
        statusLabel.Text = "Stopped: check developer console"
        statusLabel.TextColor3 = Color3.fromRGB(255, 130, 130)
    end
    if globalEnvironment.ChestFarmerBoatStop == stop then globalEnvironment.ChestFarmerBoatStop = nil end
    bridge.error = not ok and tostring(err) or nil
    if not ok then warn("[Chest Farmer] " .. tostring(err)); gui:Destroy() end
end)()

    end
    local function text(value, height)
        local label = Instance.new("TextLabel", page)
        label.Size = UDim2.new(1, 0, 0, height or 48)
        label.BackgroundColor3 = Theme.Second
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextWrapped = true
        label.Text = value
        roundUI(label, 8)
        return label
    end
    local function button(value, callback)
        local item = Instance.new("TextButton", page)
        item.Size = UDim2.new(1, 0, 0, 38)
        item.BackgroundColor3 = Theme.Button
        item.TextColor3 = Theme.Text
        item.Font = Enum.Font.GothamMedium
        item.TextSize = 12
        item.Text = value
        roundUI(item, 8)
        HUD.connect(item.Activated, callback)
        return item
    end
    criarSecao("BAU FARM", 0, page)
    text("Rotas automaticas com barco ou a pe. Inicie perto de um Boat Dealer para usar o Dinghy. O motor pode comprar esse barco com Beli.", 64)
    local status = text("Parado. Clique em Iniciar Bau Farm.")
    local metrics = text("Saldo da sessao: -- | Beli/min: --", 54)
    local startButton, stopButton
    function HUD.stopChest(reason)
        local active = session
        if not active then return end
        active.cancelled = true
        active.reason = reason or "Farm parado."
        if active.stop then active.stop() end
        if HUD.alive then status.Text = "Parando e restaurando movimento..." end
    end
    startButton = button("Iniciar Bau Farm", function()
        if session or not HUD.alive then return end
        if HUD.travelActive or HUD.flying or HUD.safeActive or HUD.seaBusy or HUD.serverBusy then
            status.Text = "Finalize o voo, viagem ou Auto Safe antes de iniciar."
            return
        end
        local active = {host = gui, speed = settings.speed, visuals = settings.visuals,
            discovery = settings.discovery, sea = HUD.currentSea or 1}
        session = active
        HUD.chestBusy = true
        HUD.restoreHitbox()
        startButton.Text = "Bau Farm em execucao"
        status.Text = "Preparando locais de baus..."
        -- Independent worker: destroying the hub requests cooperative cleanup.
        task.defer(function()
            local ok, err = xpcall(function()
                if not active.cancelled then runEngine(active) end
            end, debug.traceback)
            if active.stop then pcall(active.stop) end
            if active.cleanupApproach then pcall(active.cleanupApproach) end
            for _, connection in ipairs(active.connections or {}) do connection:Disconnect() end
            if active.engineGui then active.engineGui:Destroy() end
            if session == active then
                session = nil
                HUD.chestBusy = false
                if HUD.alive then
                    startButton.Text = "Iniciar Bau Farm"
                    local failure = not ok and tostring(err) or active.error
                    status.Text = failure and "Erro no farm; veja a aba Sistema." or active.reason or "Farm finalizado."
                    if failure then HUD.report("Bau Farm", failure) end
                end
            end
        end)
    end)
    stopButton = button("Parar Bau Farm", function() HUD.stopChest() end)
    criarSlider("Velocidade Bau (studs/s)", 50, 350, 255, 0, page, function(value)
        settings.speed = value
        if session then session.speed = value end
    end)
    criarBotaoToggle("Mostrar rota e baus", 0, page, function(value)
        settings.visuals = value
        if session then session.visuals = value end
    end)
    button("Restaurar velocidade: 255", function()
        local slider = HUD.sliders[page.Name.."/Velocidade Bau (studs/s)"]
        if slider then slider.set(255) end
    end)
    text("Velocidade aplicada a pe e no barco (barco varia cerca de 5 studs/s). O saldo inclui gastos e outros ganhos. Auto Farm NPC pausa durante esta sessao.", 70)
    local elapsed = 0
    HUD.connect(RunService.Heartbeat, function(dt)
        if not session then return end
        if HUD.travelActive or HUD.flying or HUD.safeActive or HUD.seaBusy or HUD.serverBusy then
            if not session.cancelled then HUD.stopChest("Interrompido por outra atividade do hub.") end
        end
        elapsed += dt
        if elapsed < 0.25 then return end
        elapsed = 0
        local stats = session.stats
        if stats then
            if not session.cancelled then HUD.setText(status, stats.detail.."\n"..stats.route) end
            HUD.setText(metrics, "Saldo: "..stats.money.." | Beli/min: "..stats.rate.."\nVelocidade real: "..stats.speed)
        end
    end)
    gui.Destroying:Connect(function() HUD.stopChest("Hub fechado.") end)
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
        if input.UserInputType==Enum.UserInputType.MouseButton1 then clampWindow() end
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
            if input.UserInputType==Enum.UserInputType.MouseButton1 then pressed=true; feedback() end
        end)
        button.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then pressed=false; feedback() end
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
