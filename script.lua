-- Carregador universal do PudimHub.
if not game:IsLoaded() then game.Loaded:Wait() end

local base = "https://raw.githubusercontent.com/Pudimlinoo/PudimHub/main/"
local scripts = {
    [994732206] = "bloxfruits.lua",
    [210851291] = "buildaboat.Lua",
}

-- Resolve o universo pelo PlaceId oficial: funciona também nos outros mundos.
-- O resultado é mantido no ambiente durante esta sessão.
local file = scripts[game.GameId]
if not file then
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local dragonUniverse = env.PudimHubDragonUniverse
    if not dragonUniverse then
        local ok, result = pcall(function()
            return game:GetService("HttpService"):JSONDecode(game:HttpGet(
                "https://apis.roblox.com/universes/v1/places/3475397644/universe"
            )).universeId
        end)
        if ok and type(result) == "number" then
            dragonUniverse = result
            env.PudimHubDragonUniverse = result
        end
    end
    if game.GameId == dragonUniverse or game.PlaceId == 3475397644 then
        file = "dragonadventures.lua"
    elseif not dragonUniverse then
        warn("[PudimHub] Não foi possível consultar o universo de Dragon Adventures. Tente novamente ou execute dragonadventures.lua diretamente.")
    end
end
if not file then
    warn("[PudimHub] Jogo sem script configurado. GameId: " .. tostring(game.GameId))
    return
end
local ok, message = pcall(function()
    if type(loadstring) ~= "function" then error("Executor sem suporte a loadstring", 0) end
    local source = game:HttpGet(base .. file)
    if type(source) ~= "string" or source:match("^%s*$") then error("Arquivo vazio: " .. file, 0) end
    local run, compileError = loadstring(source, "PudimHub/" .. file)
    if not run then error("Erro em " .. file .. ": " .. tostring(compileError), 0) end
    run()
end)
if not ok then
    warn("[PudimHub] Falha ao carregar " .. file .. ": " .. tostring(message))
end
