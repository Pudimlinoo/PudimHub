-- Carregador universal do PudimHub. Publique este arquivo como script.lua.
-- Antes, salve o script completo do Blox Fruits como bloxfruits.lua.
if not game:IsLoaded() then game.Loaded:Wait() end

local base = "https://raw.githubusercontent.com/Pudimlinoo/Pudimlinoo-script/main/"
local scripts = {
    [994732206] = "bloxfruits.lua",
    [210851291] = "buildaboat.Lua",
}

local file = scripts[game.GameId]
if not file then
    warn("[PudimHub] Jogo sem script configurado. GameId: " .. tostring(game.GameId))
    return
end

local ok, message = pcall(function()
    local source = game:HttpGet(base .. file)
    local run, compileError = loadstring(source, "PudimHub/" .. file)
    if not run then error("Erro em " .. file .. ": " .. tostring(compileError), 0) end
    run()
end)
if not ok then
    warn("[PudimHub] Falha ao carregar " .. file .. ": " .. tostring(message))
end
