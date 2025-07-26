-- Carregar GUI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tlredz/Library/refs/heads/main/V5/Source.lua"))()

-- Interface personalizada
local Window = Library:MakeWindow({ "Vox Seas", "by PATOLINO", "voxseas-config.json" })
local MainTab = Window:MakeTab({ "Farm", "Teleport", "Config" })

-- Serviços necessários
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

-- Variáveis e configurações
local OnFarm = false
local Settings = {
    TweenSpeed = 125,
    SelectedTool = "CombatType",
}
local EquippedTool, QuestDataCache = nil, {quests = {}, currentLevel = -1}

-- Funções auxiliares
local function IsAlive(chr)
    local humanoid = chr and chr:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function TweenTo(cframe)
    if not (Character and Character.PrimaryPart and IsAlive(Character)) then return end
    local dist = (Character.PrimaryPart.Position - cframe.Position).Magnitude
    local t = math.max(dist / Settings.TweenSpeed, 0.1)
    TweenService:Create(Character.PrimaryPart, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = cframe}):Play()
end

-- Aqui você deve ajustar para estrutura de quests/inimigos de Vox Seas
local function UpdateQuestList()
    QuestDataCache.quests = {}
    for _, q in pairs(require(ReplicatedStorage.MainModules.Essentials.QuestDescriptions)) do
        if q.Goal and q.Goal > 0 and q.MinLevel then
            table.insert(QuestDataCache.quests, {
                Level = q.MinLevel,
                Target = q.Target,
                NpcName = q.Npc,
                Id = q.Id
            })
        end
    end
    table.sort(QuestDataCache.quests, function(a,b) return a.Level > b.Level end)
end

local function GetCurrentQuest()
    local lvlFrame = Player.PlayerGui.MainUI.MainFrame.StastisticsFrame
    local lvlText = lvlFrame and lvlFrame.LevelBackground.Level.Text
    local lvl = tonumber(lvlText)
    if lvl and lvl == QuestDataCache.currentLevel then return QuestDataCache.currentQuest end
    if lvl then
        for _, q in ipairs(QuestDataCache.quests) do
            if lvl >= q.Level then
                QuestDataCache.currentLevel = lvl
                QuestDataCache.currentQuest = q
                return q
            end
        end
    end
    return nil
end

-- Segurança: equipar arma ou ferramenta de combate
local function EquipCombat()
    if not IsAlive(Character) then return end
    if EquippedTool and EquippedTool:GetAttribute(Settings.SelectedTool) then
        EquippedTool:Activate()
        return
    end
    for _, tool in ipairs(Player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute(Settings.SelectedTool) then
            EquippedTool = tool
            tool.Parent = Character
            return
        end
    end
end

-- Função principal de farm automático
local function AutoFarmLoop()
    while OnFarm and task.wait(1) do
        local cur = GetCurrentQuest()
        if not cur then
            task.wait(2)
        else
            -- Exemplo de lógica: teleportar para NPC, aceitar quest, matar mobs, repetir
            local npc = workspace:FindFirstChild(cur.NpcName, true)
            if npc and npc.PrimaryPart then
                TweenTo(npc.PrimaryPart.CFrame)
                task.wait(1)
                -- Endereço para comando de diálogo/quest (ajuste conforme evento real)
                game.ReplicatedStorage.BetweenSides.Remotes.Events.DialogueEvent:FireServer("Quests", {NpcName=cur.NpcName, QuestName=cur.Id})
                task.wait(2)
            end
            -- Aqui você colocaria lógica para achar inimigo e atacar
            EquipCombat()
        end
    end
end

-- GUI: Aba Farm
MainTab:AddSection("Farm Settings")
MainTab:AddToggle({"Auto Farm", false, function(val)
    OnFarm = val
    if val then task.spawn(AutoFarmLoop) end
end})

-- GUI: Aba Teleport
MainTab:AddButton("Teleport to NPC", function()
    local quest = GetCurrentQuest()
    if quest then
        local npc = workspace:FindFirstChild(quest.NpcName, true)
        if npc and npc.PrimaryPart then
            TweenTo(npc.PrimaryPart.CFrame)
        end
    end
end)

-- GUI: Aba Config
local ConfigTab = Window.Tabs.Config
ConfigTab:AddSlider({"Tween Speed", 50, 300, 1, Settings.TweenSpeed, {Settings, "TweenSpeed"}})
ConfigTab:AddDropdown({"Tool Type", {"CombatType", "ToolA", "ToolB"}, Settings.SelectedTool, {Settings, "SelectedTool"}})

-- Inicialização
UpdateQuestList()
