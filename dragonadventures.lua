-- PudimHub Dragon Adventures v016 | revisão do script enviado
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
    Background = Color3.fromRGB(15, 15, 20),
    Sidebar = Color3.fromRGB(20, 20, 30),
    Element = Color3.fromRGB(30, 30, 45),
    Text = Color3.fromRGB(240, 240, 240),
    Accent = Color3.fromRGB(0, 255, 128), -- Verde Neon
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

-- // UI LIBRARY
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PudimHub_DA_v016"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 50
Session.Gui = ScreenGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 550, 0, 350)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Top Bar
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Theme.Sidebar
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", TopBar)
Title.Text = "PudimHub • Dragon Adventures v016"
Title.RichText = true
Title.Size = UDim2.new(1, -190, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.Accent
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13

-- Arrastar UI
local dragging, dragInput, dragStart, startPos
Connect(TopBar.InputBegan, function(input) if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then dragging = true; dragInput = input; dragStart = input.Position; startPos = MainFrame.Position end end)
Connect(TopBar.InputEnded, function(input) if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then dragging = false end end)
Connect(UserInputService.InputChanged, function(input) if (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput) then dragInput = input end end)
Connect(RunService.RenderStepped, function() if dragging and dragInput then local delta = dragInput.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0, 5); CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Theme.Accent; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 18
Connect(CloseBtn.MouseButton1Click, function() MainFrame.Visible = false end)

-- Tabs
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(0, 130, 1, -40); TabContainer.Position = UDim2.new(0, 0, 0, 40); TabContainer.BackgroundColor3 = Theme.Sidebar
Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 10)
local TabList = Instance.new("UIListLayout", TabContainer); TabList.Padding = UDim.new(0, 5); TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center; TabList.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", TabContainer).PaddingTop = UDim.new(0, 10)

local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.Size = UDim2.new(1, -140, 1, -50); ContentContainer.Position = UDim2.new(0, 135, 0, 45); ContentContainer.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(name)
    local TabButton = Instance.new("TextButton", TabContainer)
    TabButton.Size = UDim2.new(0.9, 0, 0, 35); TabButton.BackgroundColor3 = Theme.Background; TabButton.Text = name; TabButton.TextColor3 = Theme.Text; TabButton.Font = Enum.Font.GothamSemibold; TabButton.TextSize = 14
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)
    local Page = Instance.new("ScrollingFrame", ContentContainer)
    Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 2; Page.ScrollBarImageColor3 = Theme.Accent; Page.AutomaticCanvasSize = Enum.AutomaticSize.Y; Page.CanvasSize = UDim2.new()
    local PageLayout = Instance.new("UIListLayout", Page); PageLayout.Padding = UDim.new(0, 8); PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    Connect(TabButton.MouseButton1Click, function() for _, t in pairs(Tabs) do t.Page.Visible = false; t.Btn.BackgroundColor3 = Theme.Background; t.Btn.TextColor3 = Theme.Text end; Page.Visible = true; TabButton.BackgroundColor3 = Theme.Accent; TabButton.TextColor3 = Color3.new(0,0,0) end)
    table.insert(Tabs, {Btn = TabButton, Page = Page})
    return Page
end

local function CreateToggle(parent, text, configKey, callback)
    local button = Instance.new("TextButton", parent)
    button.Size = UDim2.new(1, -10, 0, 40)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 13
    button.TextColor3 = Theme.Text
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    Refresh[configKey] = function()
        button.Text = text .. (Configs[configKey] and "  [ON]" or "  [OFF]")
        button.BackgroundColor3 = Configs[configKey] and Color3.fromRGB(20, 90, 65) or Theme.Element
    end
    Refresh[configKey]()
    Connect(button.Activated, function()
        SetConfig(configKey, not Configs[configKey])
        if callback then callback(Configs[configKey]) end
    end)
end

local function CreateSlider(parent, text, min, max, configKey)
    local Frame = Instance.new("Frame", parent); Frame.Size = UDim2.new(1, -10, 0, 55); Frame.BackgroundColor3 = Theme.Element; Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame); Label.Text = text .. ": " .. Configs[configKey]; Label.Size = UDim2.new(1, -20, 0, 20); Label.Position = UDim2.new(0, 10, 0, 5); Label.BackgroundTransparency = 1; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.TextSize = 14
    local SliderBg = Instance.new("TextButton", Frame); SliderBg.Text = ""; SliderBg.Size = UDim2.new(1, -20, 0, 6); SliderBg.Position = UDim2.new(0, 10, 0, 35); SliderBg.BackgroundColor3 = Theme.Background; SliderBg.AutoButtonColor = false; Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
    local SliderFill = Instance.new("Frame", SliderBg); SliderFill.Size = UDim2.new((Configs[configKey] - min)/(max - min), 0, 1, 0); SliderFill.BackgroundColor3 = Theme.Accent; Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
    local function Update(input) local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1); local val = math.floor(min + (max - min) * pos); Configs[configKey] = val; Label.Text = text .. ": " .. val; SliderFill.Size = UDim2.new(pos, 0, 1, 0) end
    local sliding = false; Connect(SliderBg.InputBegan, function(input) if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then sliding = input; Update(input) end end); Connect(UserInputService.InputEnded, function(input) if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then if input == sliding or input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end end); Connect(UserInputService.InputChanged, function(input) if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input == sliding) then Update(input) end end)
end

-- CRIAÇÃO DAS ABAS
local FarmTab = CreateTab("Auto Farm")
local EspTab = CreateTab("Visuals / ESP")
local PlayerTab = CreateTab("Player")

-- SEÇÃO RIDING
local RidingLabel = Instance.new("TextLabel", FarmTab)
RidingLabel.Text = "--- RIDING FARM ---"
RidingLabel.Size = UDim2.new(1, 0, 0, 25); RidingLabel.BackgroundTransparency = 1; RidingLabel.TextColor3 = Theme.Accent; RidingLabel.Font = Enum.Font.GothamBold; RidingLabel.TextSize = 14

CreateToggle(FarmTab, "Auto Riding", "AutoRiding", function(state) if state then State.Blacklist = {} end end)
CreateToggle(FarmTab, "Iniciar corrida perto", "AutoStartRace")
CreateSlider(FarmTab, "Velocidade do Dragão", 100, 400, "TweenSpeed")

local FarmLabel = Instance.new("TextLabel", FarmTab)
FarmLabel.Text = "--- FARM NORMAL ---"
FarmLabel.Size = UDim2.new(1, 0, 0, 25); FarmLabel.BackgroundTransparency = 1; FarmLabel.TextColor3 = Theme.Accent; FarmLabel.Font = Enum.Font.GothamBold; FarmLabel.TextSize = 14

CreateToggle(FarmTab, "Auto Farm Mobs", "AutoFarm")
CreateToggle(FarmTab, "Auto Coletar Ovos (Mira)", "AutoEgg")
CreateToggle(FarmTab, "Auto Coletar Baús", "AutoChest") -- [NOVO]
CreateToggle(FarmTab, "Auto Coletar Recursos", "AutoCollect")
CreateSlider(FarmTab, "Distância Farm", 5, 50, "FarmDistance")

-- Configurações Visuals
CreateToggle(EspTab, "ESP Mobs (Vermelho)", "EspMobs")
CreateToggle(EspTab, "ESP Ovos (Dourado)", "EspEggs")
CreateToggle(EspTab, "ESP Baús (Azul)", "EspChests") -- [NOVO]
CreateToggle(EspTab, "ESP Recursos (Verde)", "EspResources")

-- Configurações Player
CreateToggle(PlayerTab, "Fly (G)", "Fly")
CreateToggle(PlayerTab, "Aplicar velocidade / pulo", "PlayerMods")
CreateToggle(PlayerTab, "Anti AFK", "AntiAFK")
CreateSlider(PlayerTab, "Fly Speed", 20, 200, "FlySpeed")
CreateSlider(PlayerTab, "Walk Speed", 16, 200, "WalkSpeed")
CreateSlider(PlayerTab, "Jump Power", 50, 300, "JumpPower")

Tabs[1].Btn.BackgroundColor3 = Theme.Accent; Tabs[1].Btn.TextColor3 = Color3.new(0,0,0); Tabs[1].Page.Visible = true


local status = Instance.new("TextLabel", MainFrame)
status.Position = UDim2.new(0, 140, 1, -22)
status.Size = UDim2.new(1, -150, 0, 20)
status.BackgroundTransparency = 1
status.TextColor3 = Theme.Accent
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Pronto • escolha um modo de movimento"
ContentContainer.Size = UDim2.new(1, -140, 1, -75)
local function Status(message) status.Text = message end
local function TopButton(text, width, offset, callback)
    local button = Instance.new("TextButton", TopBar)
    button.Size = UDim2.new(0, width, 0, 28)
    button.Position = UDim2.new(1, offset, 0, 6)
    button.Text = text; button.TextSize = 11; button.Font = Enum.Font.GothamBold
    button.TextColor3 = Theme.Text; button.BackgroundColor3 = Theme.Element
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    Connect(button.Activated, callback)
    return button
end
TopButton("Parar tudo", 80, -180, function() StopAll(); Status("Parado") end)
TopButton("Sair", 50, -95, function() Session.Destroy() end)
local reopen = Instance.new("TextButton", ScreenGui)
reopen.Size = UDim2.new(0, 85, 0, 34); reopen.Position = UDim2.new(0, 12, 0.5, -17)
reopen.Text = "PudimHub"; reopen.TextColor3 = Theme.Accent
reopen.BackgroundColor3 = Theme.Sidebar; reopen.Font = Enum.Font.GothamBold; reopen.TextSize = 12
Instance.new("UICorner", reopen).CornerRadius = UDim.new(0, 8)
Connect(reopen.Activated, function() MainFrame.Visible = not MainFrame.Visible end)
local scale = Instance.new("UIScale", MainFrame)
local function Resize()
    local camera = Workspace.CurrentCamera
    if camera then scale.Scale = math.clamp(math.min((camera.ViewportSize.X - 24) / 550, (camera.ViewportSize.Y - 30) / 350), 0.35, 1) end
end

local cooldown = setmetatable({}, {__mode = "k"})
local candidates = {}
local function Index(object)
    if object:IsA("Model") or object:IsA("ProximityPrompt") then candidates[object] = true end
end
for _, object in ipairs(Workspace:GetDescendants()) do Index(object) end
Connect(Workspace.DescendantAdded, Index)
Connect(Workspace.DescendantRemoving, function(object) candidates[object] = nil end)
local function Excluded(object)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and (object == player.Character or object:IsDescendantOf(player.Character)) then return true end
    end
    local h = GetHumanoid()
    local vehicle = h and h.SeatPart and h.SeatPart:FindFirstAncestorWhichIsA("Model")
    return vehicle and (object == vehicle or object:IsDescendantOf(vehicle)) or false
end
local function Classify(object)
    local node = object
    for _ = 1, 5 do
        if not node or node == Workspace then break end
        local name = node.Name:lower()
        if name:find("egg", 1, true) then return "Egg" end
        if name:find("chest", 1, true) or name:find("treasure", 1, true) then return "Chest" end
        if name:find("resource", 1, true) or name:find("harvest", 1, true) or name:find("food", 1, true) then return "Res" end
        node = node.Parent
    end
end
local function IsMob(object)
    if not object:IsA("Model") or Excluded(object) then return false end
    local h = object:FindFirstChildWhichIsA("Humanoid")
    if not h or h.Health <= 0 or not Part(object) then return false end
    local node = object
    while node and node ~= Workspace do
        local name = node.Name:lower()
        if name:find("mob", 1, true) or name:find("enemies", 1, true) or name:find("monster", 1, true) then return true end
        node = node.Parent
    end
    return false
end
local colors = {Mob = Color3.fromRGB(255,70,70), Egg = Color3.fromRGB(255,215,0), Chest = Color3.fromRGB(0,170,255), Res = Theme.Accent}
local flags = {Mob = "EspMobs", Egg = "EspEggs", Chest = "EspChests", Res = "EspResources"}
local names = {Mob = "MOB", Egg = "OVO", Chest = "BAÚ", Res = "RECURSO"}
local function RemoveESP(object)
    local data = ESP_Storage[object]
    if data then data.Billboard:Destroy(); data.Highlight:Destroy(); ESP_Storage[object] = nil end
end
local function UpdateESP(object, tag)
    if not Configs[flags[tag]] then return end
    local part = object:IsA("ProximityPrompt") and Part(object.Parent) or Part(object)
    if not part then return end
    local data = ESP_Storage[object]
    if not data then
        local hl = Instance.new("Highlight", ScreenGui)
        hl.Adornee = object:IsA("Model") and object or part
        hl.FillColor = colors[tag]; hl.FillTransparency = 0.65
        local bill = Instance.new("BillboardGui", ScreenGui)
        bill.Adornee = part; bill.AlwaysOnTop = true; bill.Size = UDim2.new(0, 145, 0, 24)
        local label = Instance.new("TextLabel", bill)
        label.Size = UDim2.fromScale(1,1); label.BackgroundTransparency = 1
        label.TextColor3 = colors[tag]; label.Font = Enum.Font.GothamBold; label.TextSize = 12
        data = {Highlight = hl, Billboard = bill, Text = label, Tag = tag}
        ESP_Storage[object] = data
    end
    local root = GetRoot()
    data.Text.Text = names[tag] .. (root and string.format(" [%d studs]", (root.Position - part.Position).Magnitude) or "")
end
local function Scan()
    Cache = {Mobs = {}, Eggs = {}, Resources = {}, Chests = {}, Races = {}}
    local seen = {}
    for object in pairs(candidates) do
        if object.Parent and not Excluded(object) then
            if IsMob(object) then table.insert(Cache.Mobs, object); seen[object] = true; UpdateESP(object, "Mob") end
            if object:IsA("ProximityPrompt") and object.Enabled then
                local tag = Classify(object)
                local collection = tag == "Egg" and Cache.Eggs or tag == "Chest" and Cache.Chests or tag == "Res" and Cache.Resources
                if collection then table.insert(collection, object); seen[object] = true; UpdateESP(object, tag) end
                local description = (object.ObjectText .. " " .. object.ActionText):lower()
                if description:find("race", 1, true) or description:find("corrida", 1, true) then table.insert(Cache.Races, object) end
            end
        end
    end
    for object, data in pairs(ESP_Storage) do
        if not seen[object] or not Configs[flags[data.Tag]] then RemoveESP(object) end
    end
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
local function Move(part, target, speed, key, valid)
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
        if (part.Position - target.Position).Magnitude < 5 then arrived = true; break end
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
local function Collect(key, list)
    local root = GetRoot()
    if not root then Status("Aguardando personagem"); return end
    local prompt = Nearest(list, root.Position)
    if not prompt then Status("Nenhum alvo de coleta disponível / carregado"); return end
    local part = Part(prompt.Parent)
    if not part then return end
    cooldown[prompt] = os.clock() + 12
    Status("Coletando: " .. prompt.Parent.Name)
    local arrived = Move(GetMoverPart() or root, part.CFrame * CFrame.new(0, 2, 0), Configs.TweenSpeed, key, function() return prompt:IsDescendantOf(Workspace) and prompt.Enabled end)
    if not arrived then return end
    local revision = Session.Revision
    if Prompt(prompt) then
        local deadline = os.clock() + 3
        repeat
            task.wait(0.2)
            if not Session.Alive or Session.Revision ~= revision or not Configs[key] then break end
            CollectionUI()
        until os.clock() >= deadline
        if Session.Alive then Status("Interação enviada; coleta depende do jogo / minigame") end
    end
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
    Status("Riding: anel " .. ring.Name)
    Move(mover, ring.CFrame, Configs.TweenSpeed, "AutoRiding", function()
        return ring:IsDescendantOf(Workspace) and ring.Transparency < Configs.MaxTransparency and GetMoverPart() == mover and h.SeatPart ~= nil
    end)
    cooldown[ring] = os.clock() + Configs.IgnoreTime
end
local function Farm()
    local root = GetRoot()
    if not root then Status("Aguardando personagem"); return end
    local mob = Nearest(Cache.Mobs, root.Position)
    if not mob or not IsMob(mob) then Status("Nenhum mob reconhecido / carregado"); return end
    local part = Part(mob)
    if not part then return end
    local mover = GetMoverPart() or root
    mover.CFrame = CFrame.new(part.Position + Vector3.new(0, Configs.FarmDistance, 0), part.Position)
    mover.AssemblyLinearVelocity = Vector3.zero
    local tool = Player.Character and Player.Character:FindFirstChildWhichIsA("Tool")
    if tool then tool:Activate(); Status("Atacando: " .. mob.Name)
    else Status("Posicionado; equipe uma ferramenta para atacar") end
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
Worker(0.75, function() Scan(); Resize() end)
Worker(0.1, function()
    if Configs.AutoRiding then Riding()
    elseif Configs.AutoEgg then Collect("AutoEgg", Cache.Eggs)
    elseif Configs.AutoChest then Collect("AutoChest", Cache.Chests)
    elseif Configs.AutoCollect then Collect("AutoCollect", Cache.Resources)
    elseif Configs.AutoFarm then Farm() end
end)
Connect(RunService.Heartbeat, PlayerUpdate)
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "PudimHub DA v016", Text = "H: painel • G: voo • Parar tudo no topo", Duration = 5,
}) end)
