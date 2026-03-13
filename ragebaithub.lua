-- ╔══════════════════════════════════════════════════════╗
-- ║            RAGEBAIT HUB  ·  by revix & kore          ║
-- ╚══════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playergui = player:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════
--  KILL AURA  (max config, no UI knobs)
-- ══════════════════════════════════════════════════════
local KA = {
    enabled        = false,
    range          = 9999,
    attacksPerSec  = 6000,
    hitboxSize     = 50,
    hitboxEnabled  = true,
    hitboxVisible  = false,

    HitRemote = nil, PunchDoRemote = nil,
    spiedHitArgs = nil, spyReady = false,
    selfFiring = false, hookInstalled = false, oldNamecall = nil,
    attacksFired = 0,
    upvalueCooldowns = {}, tableCooldowns = {},
    auraConn = nil, lastAttackTime = 0, inFlight = {},
    hrpCache = {},
}

local function matchesCombat(str)
    local s = str:lower()
    for _, p in ipairs({"combat","attack","punch","hit","damage","fight","pvp","melee","swing","weapon","fist","strike","brawl"}) do
        if s:find(p, 1, true) then return true end
    end
end

local function matchesCooldown(key)
    local k = key:lower()
    for _, p in ipairs({"cooldown","debounce","canattack","lastattack","attackcd","punchcd","combatcd",
        "isattacking","canpunch","attacktimer","nextattack","attackdelay","swingcd","hitcd",
        "attackready","canswing","canhit","lastpunch","lasthit","lastswing","cd","_cd",
        "_debounce","_cooldown","ispunching","isswinging","combo","punchcount","attackcount",
        "canfight","fighting","swinging","punching","attacking","hitcount","combostep",
        "combocount","combotimer","combodelay","combocooldown","attackstate","punchstate",
        "combatstate","state","busy","locked","active","ready","available","enabled","disabled",
        "blocked","canuse","lastuse","lasttime","timer","delay","wait","interval","rate","speed","time","stamp","last"}) do
        if k == p or k:find(p, 1, true) then return true end
    end
end

local function getRemotesKA()
    pcall(function() KA.HitRemote     = ReplicatedStorage.Packages.Knit.Services.CombatService.RF.Hit    end)
    pcall(function() KA.PunchDoRemote = ReplicatedStorage.Packages.Knit.Services.CombatService.RF.PunchDo end)
    if not KA.HitRemote or not KA.PunchDoRemote then
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteFunction") or v:IsA("RemoteEvent") then
                local n = v.Name:lower()
                if n == "hit"     and not KA.HitRemote     then KA.HitRemote     = v end
                if n == "punchdo" and not KA.PunchDoRemote then KA.PunchDoRemote = v end
            end
        end
    end
end

local function installSpy()
    if KA.hookInstalled then return end
    pcall(function()
        KA.oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not KA.selfFiring and method == "InvokeServer" and self == KA.HitRemote then
                KA.spiedHitArgs = {...}; KA.spyReady = true
            end
            return KA.oldNamecall(self, ...)
        end))
        KA.hookInstalled = true
    end)
    if not KA.hookInstalled then
        pcall(function()
            if KA.HitRemote then
                local oldInvoke = KA.HitRemote.InvokeServer
                hookfunction(oldInvoke, newcclosure(function(self, ...)
                    if not KA.selfFiring and self == KA.HitRemote then
                        KA.spiedHitArgs = {...}; KA.spyReady = true
                    end
                    return oldInvoke(self, ...)
                end))
                KA.hookInstalled = true
            end
        end)
    end
end

local scannedFuncs = {}
local function scanFunction(func, depth)
    if depth > 8 or scannedFuncs[func] then return end
    scannedFuncs[func] = true
    pcall(function()
        local upvalues  = debug.getupvalues(func)
        local constants = {}; pcall(function() constants = debug.getconstants(func) end)
        local hasCombat = false
        for _, c in pairs(constants) do
            if typeof(c) == "string" and matchesCombat(c) then hasCombat = true end
        end
        for idx, val in pairs(upvalues) do
            local vt = typeof(val)
            if vt == "boolean" then
                table.insert(KA.upvalueCooldowns, {func=func, idx=idx, valType="boolean", combat=hasCombat})
            elseif vt == "number" then
                table.insert(KA.upvalueCooldowns, {func=func, idx=idx, valType="number", combat=hasCombat})
            elseif vt == "table" then
                pcall(function()
                    for k, v in pairs(val) do
                        if typeof(k) == "string" and matchesCooldown(k) then
                            table.insert(KA.tableCooldowns, {tbl=val, key=k, valType=typeof(v)})
                        end
                    end
                end)
            elseif vt == "function" then
                scanFunction(val, depth+1)
            end
        end
        pcall(function()
            for _, proto in pairs(debug.getprotos(func)) do
                scanFunction(proto, depth+1)
            end
        end)
    end)
end

local function reverseEngineerModule()
    KA.upvalueCooldowns = {}; KA.tableCooldowns = {}; scannedFuncs = {}
    pcall(function()
        local mod = ReplicatedStorage:FindFirstChild("Controllers")
            and ReplicatedStorage.Controllers:FindFirstChild("CombatClient")
        if not mod then return end
        local data = require(mod)
        if typeof(data) == "table" then
            for _, v in pairs(data) do
                if typeof(v) == "function" then scanFunction(v, 0) end
            end
        end
    end)
    pcall(function()
        for _, obj in pairs(getgc(true)) do
            if typeof(obj) == "function" and not scannedFuncs[obj] then
                pcall(function()
                    local consts = debug.getconstants(obj)
                    local hasPD, hasHit = false, false
                    for _, c in pairs(consts) do
                        if typeof(c) == "string" then
                            local cl = c:lower()
                            if cl:find("punchdo", 1, true) then hasPD  = true end
                            if cl == "hit" and not cl:find("hitbox", 1, true) then hasHit = true end
                        end
                    end
                    if hasPD or hasHit then scanFunction(obj, 0) end
                end)
            end
        end
    end)
end

local function nukeCooldowns()
    for _, e in ipairs(KA.upvalueCooldowns) do
        pcall(function()
            if e.valType == "boolean" then debug.setupvalue(e.func, e.idx, false)
            elseif e.valType == "number" then debug.setupvalue(e.func, e.idx, 0) end
        end)
    end
    for _, e in ipairs(KA.tableCooldowns) do
        pcall(function()
            if e.valType == "number" then rawset(e.tbl, e.key, 0)
            elseif e.valType == "boolean" then
                local k = e.key:lower()
                if k:find("debounce") or k:find("attacking") or k:find("punching")
                or k:find("swinging") or k:find("busy")      or k:find("locked")
                or k:find("blocked")  or k:find("disabled") then
                    rawset(e.tbl, e.key, false)
                else
                    rawset(e.tbl, e.key, true)
                end
            end
        end)
    end
end

local function buildHitArgs(targetChar)
    if KA.spiedHitArgs and #KA.spiedHitArgs > 0 then
        local out = {}
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        local hum = targetChar:FindFirstChildOfClass("Humanoid")
        local plr = Players:GetPlayerFromCharacter(targetChar)
        for i, arg in ipairs(KA.spiedHitArgs) do
            if typeof(arg) == "Instance" then
                if arg:IsA("Model") and arg:FindFirstChildOfClass("Humanoid") then out[i] = targetChar
                elseif arg:IsA("Humanoid") then out[i] = hum or arg
                elseif arg:IsA("Player")   then out[i] = plr or arg
                elseif arg:IsA("BasePart") then out[i] = targetChar:FindFirstChild(arg.Name) or hrp or arg
                else out[i] = arg end
            elseif typeof(arg) == "Vector3" then out[i] = hrp and hrp.Position or arg
            elseif typeof(arg) == "CFrame"  then out[i] = hrp and hrp.CFrame  or arg
            else out[i] = arg end
        end
        return out
    end
    return {targetChar:FindFirstChildOfClass("Humanoid") or targetChar}
end

local function performHit(targetChar)
    if not KA.HitRemote then return end
    pcall(function()
        local args = buildHitArgs(targetChar)
        if args and #args > 0 then KA.HitRemote:InvokeServer(unpack(args))
        else KA.HitRemote:InvokeServer() end
    end)
end

local function updateHitbox(p, hrp)
    if not hrp or not hrp.Parent then return end
    if not KA.hitboxEnabled then hrp.Size = Vector3.new(2,2,1); hrp.Transparency = 1; return end
    hrp.Size        = Vector3.new(KA.hitboxSize, KA.hitboxSize, KA.hitboxSize)
    hrp.Transparency = KA.hitboxVisible and 0.88 or 1
    hrp.Material     = KA.hitboxVisible and Enum.Material.Neon or Enum.Material.Plastic
    hrp.CanCollide   = false
end

local function updateAllHitboxes()
    for p, hrp in pairs(KA.hrpCache) do updateHitbox(p, hrp) end
end

local function cacheHRP(p)
    local function onChar(char)
        local hrp = char:WaitForChild("HumanoidRootPart", 8)
        if hrp then KA.hrpCache[p] = hrp; updateHitbox(p, hrp) end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Died:Connect(function() KA.hrpCache[p] = nil end) end
    end
    if p.Character then task.spawn(onChar, p.Character) end
    p.CharacterAdded:Connect(onChar)
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= player then cacheHRP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= player then cacheHRP(p) end end)
Players.PlayerRemoving:Connect(function(p) KA.hrpCache[p] = nil end)

local function getValidTargets()
    local myChar = player.Character; if not myChar then return {} end
    local myHRP  = myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return {} end
    local myPos  = myHRP.Position; local out = {}
    for p, hrp in pairs(KA.hrpCache) do
        if p ~= player and p.Character and hrp and hrp.Parent then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (hrp.Position - myPos).Magnitude
                if dist <= KA.range then table.insert(out, {char = p.Character, dist = dist}) end
            end
        end
    end
    table.sort(out, function(a,b) return a.dist < b.dist end)
    return out
end

local function startKillAura()
    KA.lastAttackTime = 0; KA.inFlight = {}
    KA.auraConn = RunService.Heartbeat:Connect(function()
        if not KA.enabled then return end
        local now = tick()
        local interval = 1 / math.clamp(KA.attacksPerSec / 150, 0.1, 3000)
        if now - KA.lastAttackTime < interval then return end
        KA.lastAttackTime = now
        local targets = getValidTargets()
        if #targets == 0 then return end
        local myChar = player.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        KA.selfFiring = true
        nukeCooldowns()
        for _, td in ipairs(targets) do
            local char = td.char
            if char and char:FindFirstChild("HumanoidRootPart") and not KA.inFlight[char] then
                KA.inFlight[char] = true
                task.spawn(function()
                    performHit(char)
                    KA.inFlight[char] = nil
                end)
            end
        end
        task.defer(function() KA.selfFiring = false end)
    end)
end

local function stopKillAura()
    KA.selfFiring = false; KA.inFlight = {}
    if KA.auraConn then KA.auraConn:Disconnect(); KA.auraConn = nil end
end

-- init remotes
task.spawn(function()
    task.wait(0.5); getRemotesKA()
    task.wait(0.3); reverseEngineerModule()
    task.wait(0.3); installSpy()
end)
task.spawn(function()
    while task.wait(5) do if not KA.HitRemote then getRemotesKA() end end
end)

-- ══════════════════════════════════════════════════════
--  GUI
-- ══════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui", playergui)
gui.Name = "RagebaitHub"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ── palette ──
local CLR = {
    bg    = Color3.fromRGB(8,   8,   8),
    panel = Color3.fromRGB(14,  14,  14),
    btn   = Color3.fromRGB(18,  18,  18),
    btnOn = Color3.fromRGB(28,  28,  28),
    white = Color3.new(1,1,1),
    dim   = Color3.fromRGB(100,100,100),
    red   = Color3.fromRGB(220, 40,  40),
    accent= Color3.fromRGB(255,255,255),
}

-- ── main window ──
local Main = Instance.new("Frame", gui)
Main.Name = "Main"
Main.Size = UDim2.new(0, 740, 0, 320)
Main.Position = UDim2.new(0.5, -370, 0.5, -160)
Main.BackgroundColor3 = CLR.bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Thickness = 2; mainStroke.Color = CLR.white

-- animated border (sine white)
task.spawn(function()
    while Main and Main.Parent do
        local v = math.floor(((math.sin(tick() * 1.2) + 1) / 2) * 255)
        mainStroke.Color = Color3.fromRGB(v, v, v)
        task.wait(0.03)
    end
end)

-- ── background image ──
local BG = Instance.new("ImageLabel", Main)
BG.Size = UDim2.new(1,0,1,0)
BG.BackgroundTransparency = 1
BG.Image = "rbxassetid://116609435350470"
BG.ImageTransparency = 0.78
BG.ScaleType = Enum.ScaleType.Crop
BG.ZIndex = 1
Instance.new("UICorner", BG).CornerRadius = UDim.new(0, 10)

-- ── wavy dots ──
local DOT_COUNT = 20
local W_DOT, H_DOT = 740, 320
local dotConfigs, dotFrames = {}, {}
math.randomseed(os.clock() * 1000)
for i = 1, DOT_COUNT do
    local sz = math.random(3, 9)
    dotConfigs[i] = {
        baseX  = math.random(20, W_DOT - 20),
        baseY  = math.random(20, H_DOT - 20),
        ampX   = math.random(15, 50),
        ampY   = math.random(15, 50),
        freqX  = math.random(40, 90) / 100,
        freqY  = math.random(40, 90) / 100,
        phaseX = math.random(0, 628) / 100,
        phaseY = math.random(0, 628) / 100,
        speed  = math.random(55, 100) / 100,
        size   = sz,
        alpha  = math.random(50, 80) / 100,
    }
    local dot = Instance.new("Frame", Main)
    dot.Size = UDim2.new(0, sz, 0, sz)
    dot.BackgroundColor3 = CLR.white
    dot.BackgroundTransparency = dotConfigs[i].alpha
    dot.BorderSizePixel = 0
    dot.ZIndex = 2
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    dotFrames[i] = dot
end
task.spawn(function()
    while Main and Main.Parent do
        local t = tick()
        for i = 1, DOT_COUNT do
            local c = dotConfigs[i]
            local x = c.baseX + c.ampX * math.sin(t * c.speed * c.freqX + c.phaseX)
            local y = c.baseY + c.ampY * math.sin(t * c.speed * c.freqY + c.phaseY)
            local pulse = ((math.sin(t * c.speed * 0.5 + c.phaseX) + 1) / 2) * 0.2
            dotFrames[i].BackgroundTransparency = math.clamp(c.alpha + pulse, 0, 0.97)
            dotFrames[i].Position = UDim2.new(0, x - c.size/2, 0, y - c.size/2)
        end
        task.wait(0.03)
    end
end)

-- ── sidebar ──
local Sidebar = Instance.new("Frame", Main)
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 180, 1, -8)
Sidebar.Position = UDim2.new(0, 4, 0, 4)
Sidebar.BackgroundColor3 = CLR.panel
Sidebar.BackgroundTransparency = 0.15
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 3
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Sidebar).Color = Color3.fromRGB(35,35,35)

-- title block
local TitleBlock = Instance.new("Frame", Sidebar)
TitleBlock.Size = UDim2.new(1,0,0,72)
TitleBlock.BackgroundTransparency = 1
TitleBlock.ZIndex = 4

local Title = Instance.new("TextLabel", TitleBlock)
Title.Size = UDim2.new(1,-12,0,36)
Title.Position = UDim2.new(0, 10, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "RAGEBAIT HUB"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextColor3 = CLR.white
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 5

local TitleStroke = Instance.new("UIStroke", Title)
TitleStroke.Thickness = 1; TitleStroke.Color = Color3.fromRGB(0,0,0)

local Subtitle = Instance.new("TextLabel", TitleBlock)
Subtitle.Size = UDim2.new(1,-12,0,20)
Subtitle.Position = UDim2.new(0, 10, 0, 46)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "made with love by revix and kore"
Subtitle.Font = Enum.Font.GothamSemibold
Subtitle.TextSize = 9
Subtitle.TextColor3 = CLR.white
Subtitle.TextTransparency = 0.55
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 5

-- sidebar divider
local Div = Instance.new("Frame", Sidebar)
Div.Size = UDim2.new(1,-20,0,1)
Div.Position = UDim2.new(0,10,0,76)
Div.BackgroundColor3 = Color3.fromRGB(35,35,35)
Div.BorderSizePixel = 0
Div.ZIndex = 4

-- feature buttons list
local BtnList = Instance.new("Frame", Sidebar)
BtnList.Size = UDim2.new(1,0,1,-84)
BtnList.Position = UDim2.new(0,0,0,84)
BtnList.BackgroundTransparency = 1
BtnList.ZIndex = 4

local BtnLayout = Instance.new("UIListLayout", BtnList)
BtnLayout.Padding = UDim.new(0, 4)
BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder

local UIPadding = Instance.new("UIPadding", BtnList)
UIPadding.PaddingLeft = UDim.new(0, 8)
UIPadding.PaddingRight = UDim.new(0, 8)
UIPadding.PaddingTop = UDim.new(0, 4)

-- ── content area ──
local ContentArea = Instance.new("Frame", Main)
ContentArea.Size = UDim2.new(1,-196,1,-8)
ContentArea.Position = UDim2.new(0,192,0,4)
ContentArea.BackgroundColor3 = CLR.panel
ContentArea.BackgroundTransparency = 0.2
ContentArea.BorderSizePixel = 0
ContentArea.ZIndex = 3
Instance.new("UICorner", ContentArea).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", ContentArea).Color = Color3.fromRGB(35,35,35)

-- content inner scroll
local ContentScroll = Instance.new("ScrollingFrame", ContentArea)
ContentScroll.Size = UDim2.new(1,0,1,0)
ContentScroll.BackgroundTransparency = 1
ContentScroll.ScrollBarThickness = 3
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
ContentScroll.CanvasSize = UDim2.new(0,0,0,0)
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroll.ZIndex = 4

local ContentLayout = Instance.new("UIListLayout", ContentScroll)
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ContentPad = Instance.new("UIPadding", ContentScroll)
ContentPad.PaddingLeft  = UDim.new(0,10)
ContentPad.PaddingRight = UDim.new(0,10)
ContentPad.PaddingTop   = UDim.new(0,10)

-- ── drag ──
local dragging, dragStart, startPos = false, nil, nil
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                  startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ── minimize / open ──
local MiniBtn = Instance.new("TextButton", Main)
MiniBtn.Size = UDim2.new(0,26,0,18)
MiniBtn.Position = UDim2.new(1,-30,0,6)
MiniBtn.BackgroundColor3 = CLR.btn
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.Text = "—"
MiniBtn.TextSize = 12
MiniBtn.TextColor3 = CLR.white
MiniBtn.ZIndex = 10
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(0,4)

local OpenBtn = Instance.new("TextButton", gui)
OpenBtn.Size = UDim2.new(0, 130, 0, 32)
OpenBtn.Position = UDim2.new(0, 0, 1, -38)
OpenBtn.BackgroundColor3 = CLR.bg
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.Text = "RAGEBAIT HUB"
OpenBtn.TextSize = 11
OpenBtn.TextColor3 = CLR.white
OpenBtn.Visible = false
OpenBtn.ZIndex = 10
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", OpenBtn).Color = CLR.white

MiniBtn.MouseButton1Click:Connect(function() Main.Visible = false; OpenBtn.Visible = true end)
OpenBtn.MouseButton1Click:Connect(function() Main.Visible = true;  OpenBtn.Visible = false end)

-- ══════════════════════════════════════════════════════
--  WIDGET HELPERS
-- ══════════════════════════════════════════════════════
local function makeLabel(text, parent, size, xalign)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = size or UDim2.new(1,0,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = CLR.dim
    lbl.TextXAlignment = xalign or Enum.TextXAlignment.Left
    lbl.ZIndex = 5
    return lbl
end

local function makeStatusLabel(text, parent)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1,0,0,16)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = CLR.dim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5
    return lbl
end

-- sidebar feature button
local currentFeatureBtn = nil
local function makeSideBtn(text, order)
    local btn = Instance.new("TextButton", BtnList)
    btn.Size = UDim2.new(1,0,0,30)
    btn.BackgroundColor3 = CLR.btn
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextSize = 13
    btn.TextColor3 = CLR.dim
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.ZIndex = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0,10)
    return btn
end

-- content section header
local function makeSectionHeader(text, parent, order)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,0,0,24)
    f.BackgroundTransparency = 1
    f.LayoutOrder = order
    f.ZIndex = 5

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = CLR.dim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 6
    return f
end

-- content toggle row
local function makeToggleRow(text, parent, order, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,34)
    row.BackgroundColor3 = CLR.btn
    row.BackgroundTransparency = 0.15
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 5
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-54,1,0)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = CLR.white
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 6

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(0,36,0,18)
    track.Position = UDim2.new(1,-46,0.5,-9)
    track.BackgroundColor3 = Color3.fromRGB(35,35,35)
    track.BorderSizePixel = 0
    track.ZIndex = 6
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0,14,0,14)
    thumb.Position = UDim2.new(0,2,0.5,-7)
    thumb.BackgroundColor3 = CLR.dim
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 7
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1,0)

    local on = false
    local function set(state)
        on = state
        track.BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(35,35,35)
        thumb.BackgroundColor3 = on and Color3.fromRGB(0,0,0) or CLR.dim
        local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
        TweenService:Create(thumb, tweenInfo, {
            Position = on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
        }):Play()
        if callback then callback(on) end
    end

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 8
    btn.MouseButton1Click:Connect(function() set(not on) end)
    return set
end

-- content text box
local function makeTextBox(placeholder, parent, order, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1,0,0,34)
    frame.BackgroundColor3 = CLR.btn
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.ZIndex = 5
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)

    local tb = Instance.new("TextBox", frame)
    tb.Size = UDim2.new(1,-16,1,-8)
    tb.Position = UDim2.new(0,8,0,4)
    tb.BackgroundTransparency = 1
    tb.TextColor3 = CLR.white
    tb.PlaceholderColor3 = CLR.dim
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 13
    tb.Text = ""
    tb.PlaceholderText = placeholder
    tb.ClearTextOnFocus = false
    tb.ZIndex = 6
    tb:GetPropertyChangedSignal("Text"):Connect(function()
        if callback then callback(tb.Text) end
    end)
    return tb
end

-- content amount box (generic)
local function makeAmountBox(placeholder, parent, order)
    return makeTextBox(placeholder, parent, order, nil)
end

-- ══════════════════════════════════════════════════════
--  PLAYER LIST
-- ══════════════════════════════════════════════════════
local PlayerListFrame = Instance.new("Frame", Main)
PlayerListFrame.Name = "PlayerList"
PlayerListFrame.Size = UDim2.new(0, 160, 1, -8)
PlayerListFrame.Position = UDim2.new(0, -168, 0, 4)
PlayerListFrame.BackgroundColor3 = CLR.panel
PlayerListFrame.BackgroundTransparency = 0.1
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.ZIndex = 3
PlayerListFrame.Visible = false
Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", PlayerListFrame).Color = Color3.fromRGB(35,35,35)

local PLHeader = Instance.new("TextLabel", PlayerListFrame)
PLHeader.Size = UDim2.new(1,-16,0,28)
PLHeader.Position = UDim2.new(0,8,0,6)
PLHeader.BackgroundTransparency = 1
PLHeader.Text = "PLAYERS"
PLHeader.Font = Enum.Font.GothamBold
PLHeader.TextSize = 11
PLHeader.TextColor3 = CLR.dim
PLHeader.TextXAlignment = Enum.TextXAlignment.Left
PLHeader.ZIndex = 4

local PLDiv = Instance.new("Frame", PlayerListFrame)
PLDiv.Size = UDim2.new(1,-16,0,1); PLDiv.Position = UDim2.new(0,8,0,36)
PLDiv.BackgroundColor3 = Color3.fromRGB(35,35,35); PLDiv.BorderSizePixel = 0; PLDiv.ZIndex = 4

local PLScroll = Instance.new("ScrollingFrame", PlayerListFrame)
PLScroll.Size = UDim2.new(1,0,1,-42); PLScroll.Position = UDim2.new(0,0,0,42)
PLScroll.BackgroundTransparency = 1; PLScroll.ScrollBarThickness = 3
PLScroll.ScrollBarImageColor3 = Color3.fromRGB(60,60,60)
PLScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PLScroll.CanvasSize = UDim2.new(0,0,0,0); PLScroll.ZIndex = 4

local PLLayout = Instance.new("UIListLayout", PLScroll)
PLLayout.Padding = UDim.new(0, 3); PLLayout.SortOrder = Enum.SortOrder.LayoutOrder
local PLPad = Instance.new("UIPadding", PLScroll)
PLPad.PaddingLeft = UDim.new(0,6); PLPad.PaddingRight = UDim.new(0,6); PLPad.PaddingTop = UDim.new(0,4)

local function makePLBtn(targetPlayer)
    local btn = Instance.new("TextButton", PLScroll)
    btn.Size = UDim2.new(1,0,0,28)
    btn.BackgroundColor3 = CLR.btn
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = targetPlayer.Name
    btn.TextSize = 12
    btn.TextColor3 = CLR.white
    btn.AutoButtonColor = false
    btn.ZIndex = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    return btn
end

-- ══════════════════════════════════════════════════════
--  FEATURE STATE
-- ══════════════════════════════════════════════════════
local currentFeature     = nil
local selectedPlayer     = nil
local flying             = false
local tpwalking          = false
local aimLocking         = false
local aimlockTarget      = nil
local aimlockConnection  = nil
local aimlockHighlight   = nil
local mouseUnlocked      = false
local mouseUnlockConn    = nil
local flyBV, flyBG, flyConn = nil, nil, nil
local colorRunning       = false

-- Color system
local pickedH, pickedS, pickedV = 0, 1, 1
local colorCycleSpeed = 4
local colorTime, colorCharCount = 0, 1
local colorWord = player.DisplayName or player.Name
local lastNameUpdate, lastBioUpdate = 0, 0
local nameUpdateFreq, bioUpdateFreq = 0.08, 0.08
local colorConnection = nil

local ColorRemote, NameRemote, BioColorRemote, isBioFunction
pcall(function()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes", 3)
    if Remotes then
        ColorRemote    = Remotes:FindFirstChild("UpdateRPColor")
        NameRemote     = Remotes:FindFirstChild("UpdateRPName")
        BioColorRemote = Remotes:FindFirstChild("UpdateBioColor")
        if BioColorRemote then isBioFunction = BioColorRemote:IsA("RemoteFunction") end
    end
end)

local function fireColorRemote(color)
    if ColorRemote then pcall(function() ColorRemote:FireServer(color) end) end
end
local function fireBioRemote(color)
    if BioColorRemote then
        pcall(function()
            if isBioFunction then BioColorRemote:InvokeServer(color) else BioColorRemote:FireServer(color) end
        end)
    end
end
local function fireNameRemote(text)
    if NameRemote then pcall(function() NameRemote:FireServer(text) end) end
end

-- ── stop helpers ──
local function stopMouseUnlock()
    mouseUnlocked = false
    if mouseUnlockConn then mouseUnlockConn:Disconnect(); mouseUnlockConn = nil end
end
local function startMouseUnlock()
    mouseUnlocked = true
    mouseUnlockConn = RunService.RenderStepped:Connect(function()
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end)
end

local function stopAimlock()
    aimLocking = false
    if aimlockConnection then aimlockConnection:Disconnect(); aimlockConnection = nil end
    if aimlockHighlight then aimlockHighlight:Destroy(); aimlockHighlight = nil end
    aimlockTarget = nil
end
local function startAimlock(targetPlayer)
    if aimLocking and aimlockTarget == targetPlayer then stopAimlock() return end
    stopAimlock()
    local char = targetPlayer.Character; if not char then return end
    aimLocking = true; aimlockTarget = targetPlayer
    aimlockHighlight = Instance.new("Highlight")
    aimlockHighlight.FillColor = CLR.red
    aimlockHighlight.OutlineColor = CLR.white
    aimlockHighlight.FillTransparency = 0.5
    aimlockHighlight.Parent = char
    aimlockConnection = RunService.RenderStepped:Connect(function()
        local tChar = aimlockTarget and aimlockTarget.Character
        if not tChar or not tChar:FindFirstChild("HumanoidRootPart") then stopAimlock() return end
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, tChar.HumanoidRootPart.Position)
    end)
end
Players.PlayerRemoving:Connect(function(p) if aimlockTarget == p then stopAimlock() end end)

local function stopFly()
    flying = false
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    if flyConn then flyConn:Disconnect(); flyConn = nil end
end

local flyAmountRef = nil
local function startFly()
    local speed = (flyAmountRef and tonumber(flyAmountRef.Text)) or 70
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    flying = true
    flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(1,1,1)*100000; flyBV.Parent = root
    flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(1,1,1)*100000; flyBG.CFrame = root.CFrame; flyBG.Parent = root
    flyConn = RunService.RenderStepped:Connect(function()
        if flying and root and root.Parent then
            local s = (flyAmountRef and tonumber(flyAmountRef.Text)) or speed
            flyBV.Velocity = workspace.CurrentCamera.CFrame.LookVector * s
            flyBG.CFrame   = workspace.CurrentCamera.CFrame
        end
    end)
end
player.CharacterAdded:Connect(function() if flying then stopFly() end end)

local tpAmountRef = nil
local function stopTpWalk()
    tpwalking = false
end
local function startTpWalk()
    local speed = (tpAmountRef and tonumber(tpAmountRef.Text)) or 4
    tpwalking = true
    local char = player.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hum then stopTpWalk() return end
    task.spawn(function()
        while tpwalking and char and hum and hum.Parent do
            local delta = RunService.Heartbeat:Wait()
            if hum.MoveDirection.Magnitude > 0 then
                local s = (tpAmountRef and tonumber(tpAmountRef.Text)) or speed
                pcall(function() char:TranslateBy(hum.MoveDirection * s * delta * 10) end)
            end
            if not player.Character or player.Character ~= char then stopTpWalk() end
        end
    end)
end
player.CharacterAdded:Connect(function() if tpwalking then stopTpWalk() end end)

local function stopColor()
    colorRunning = false
    if colorConnection then colorConnection:Disconnect(); colorConnection = nil end
end

local rpNameRef = nil
local function startColor()
    colorRunning = true; colorTime = 0; colorCharCount = 1
    lastNameUpdate = 0; lastBioUpdate = 0
    colorWord = (rpNameRef and rpNameRef.Text ~= "" and rpNameRef.Text) or (player.DisplayName or player.Name)
    colorConnection = RunService.Heartbeat:Connect(function(dt)
        colorTime += dt * colorCycleSpeed
        local cycledH = (pickedH + colorTime * 0.1) % 1
        local color = Color3.fromHSV(cycledH, pickedS, pickedV)
        fireColorRemote(color)
        lastBioUpdate += dt
        if lastBioUpdate >= bioUpdateFreq then lastBioUpdate = 0; fireBioRemote(color) end
        lastNameUpdate += dt
        if lastNameUpdate >= nameUpdateFreq then
            lastNameUpdate = 0
            fireNameRemote(string.sub(colorWord, 1, colorCharCount))
            colorCharCount = (colorCharCount >= #colorWord) and 1 or (colorCharCount + 1)
        end
    end)
end

-- ══════════════════════════════════════════════════════
--  BUILD PAGES
-- ══════════════════════════════════════════════════════
-- pages = frames parented to ContentScroll, shown/hidden
local pages = {}

local function showPage(name)
    for k, v in pairs(pages) do v.Visible = (k == name) end
end

local function makePageFrame()
    local f = Instance.new("Frame", ContentScroll)
    f.Size = UDim2.new(1,0,0,0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1
    f.LayoutOrder = 1
    f.ZIndex = 5
    local layout = Instance.new("UIListLayout", f)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    return f, layout
end

-- ── TP page ──
local tpPage = makePageFrame()
pages["TP"] = tpPage

makeSectionHeader("TELEPORT TO PLAYER", tpPage, 0)
local tpStatus = makeStatusLabel("select a player from the list →", tpPage)
tpStatus.LayoutOrder = 1

-- ── Aimlock page ──
local alPage = makePageFrame()
alPage.Visible = false
pages["Aimlock"] = alPage

makeSectionHeader("AIMLOCK", alPage, 0)
local alStatus = makeStatusLabel("select a player from the list →", alPage)
alStatus.LayoutOrder = 1

-- ── Fly page ──
local flyPage = makePageFrame()
flyPage.Visible = false
pages["Fly"] = flyPage

makeSectionHeader("FLY", flyPage, 0)
local flySpeedLbl = makeStatusLabel("speed (default 70)", flyPage); flySpeedLbl.LayoutOrder = 1
local flyTB = makeTextBox("fly speed...", flyPage, 2); flyAmountRef = flyTB
local flyToggle; flyToggle = makeToggleRow("fly enabled", flyPage, 3, function(state)
    if state then startFly() else stopFly() end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.E and currentFeature == "Fly" then
        if flying then stopFly(); flyToggle(false) else startFly(); flyToggle(true) end
    end
end)

-- ── TpWalk page ──
local tpwPage = makePageFrame()
tpwPage.Visible = false
pages["TpWalk"] = tpwPage

makeSectionHeader("TELEPORT WALK", tpwPage, 0)
local tpwLbl = makeStatusLabel("speed multiplier (default 4)", tpwPage); tpwLbl.LayoutOrder = 1
local tpwTB = makeTextBox("speed...", tpwPage, 2); tpAmountRef = tpwTB
local tpwToggle; tpwToggle = makeToggleRow("tpwalk enabled", tpwPage, 3, function(state)
    if state then startTpWalk() else stopTpWalk() end
end)

-- ── MouseUnlock page ──
local muPage = makePageFrame()
muPage.Visible = false
pages["MouseUnlock"] = muPage

makeSectionHeader("MOUSE UNLOCK", muPage, 0)
makeStatusLabel("unlocks cursor during gameplay", muPage).LayoutOrder = 1
makeToggleRow("mouse unlock enabled", muPage, 2, function(state)
    if state then startMouseUnlock() else stopMouseUnlock() end
end)

-- ── Color page ──
local colPage = makePageFrame()
colPage.Visible = false
pages["Color"] = colPage

makeSectionHeader("RP COLOR CYCLER", colPage, 0)

local function makeSliderDrag(bar, cursor, onChanged)
    local draggingSlider = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            local rel = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            cursor.Position = UDim2.new(rel, -2, 0, 0); onChanged(rel)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            cursor.Position = UDim2.new(rel, -2, 0, 0); onChanged(rel)
        end
    end)
end

local function makeColorBar(labelText, parent, order)
    local wrapper = Instance.new("Frame", parent)
    wrapper.Size = UDim2.new(1,0,0,44)
    wrapper.BackgroundTransparency = 1
    wrapper.LayoutOrder = order
    wrapper.ZIndex = 5

    local lbl = Instance.new("TextLabel", wrapper)
    lbl.Size = UDim2.new(1,0,0,16); lbl.BackgroundTransparency = 1
    lbl.Text = labelText; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = CLR.dim; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 6

    local bar = Instance.new("Frame", wrapper)
    bar.Size = UDim2.new(1,0,0,18); bar.Position = UDim2.new(0,0,0,22)
    bar.BackgroundColor3 = Color3.fromRGB(30,30,30); bar.BorderSizePixel = 0; bar.ZIndex = 6
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,4)
    bar.ClipsDescendants = true

    local cursor = Instance.new("Frame", bar)
    cursor.Size = UDim2.new(0,4,1,0); cursor.BackgroundColor3 = CLR.white
    cursor.BorderSizePixel = 0; cursor.ZIndex = 7
    return bar, cursor
end

local hueBar, hueCursor = makeColorBar("HUE", colPage, 1)
local HueGradient = Instance.new("UIGradient", hueBar)
HueGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,    1, 1)),
    ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5,  1, 1)),
    ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
    ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,    1, 1)),
})

local satBar, satCursor = makeColorBar("SATURATION", colPage, 2)
local SatGradient = Instance.new("UIGradient", satBar)

local briBar, briCursor = makeColorBar("BRIGHTNESS", colPage, 3)
local BriGradient = Instance.new("UIGradient", briBar)

local function updateGradients()
    SatGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(pickedH, 0, pickedV)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(pickedH, 1, pickedV)),
    })
    BriGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(pickedH, pickedS, 1)),
    })
end

makeSliderDrag(hueBar, hueCursor, function(r) pickedH = r; updateGradients() end)
makeSliderDrag(satBar, satCursor, function(r) pickedS = r; updateGradients() end)
makeSliderDrag(briBar, briCursor, function(r) pickedV = r; updateGradients() end)

local speedBar, speedCursor = makeColorBar("CYCLE SPEED", colPage, 4)
speedBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
local speedFill = Instance.new("Frame", speedBar)
speedFill.Size = UDim2.new(0.2,0,1,0); speedFill.BackgroundColor3 = CLR.white
speedFill.BorderSizePixel = 0; speedFill.ZIndex = 6

local speedLbl = makeStatusLabel("speed: 4", colPage); speedLbl.LayoutOrder = 5
makeSliderDrag(speedBar, speedCursor, function(r)
    colorCycleSpeed = math.max(0.1, r * 20)
    speedFill.Size = UDim2.new(r, 0, 1, 0)
    speedLbl.Text = "speed: " .. math.floor(colorCycleSpeed * 10) / 10
end)

local rpNameLbl = makeStatusLabel("rp name", colPage); rpNameLbl.LayoutOrder = 6
local rpNameTB = makeTextBox("enter rp name...", colPage, 7)
rpNameTB.Text = player.DisplayName or player.Name
rpNameRef = rpNameTB

makeToggleRow("color cycle enabled", colPage, 8, function(state)
    if state then startColor() else stopColor() end
end)

-- ── Kill Aura page ──
local kaPage = makePageFrame()
kaPage.Visible = false
pages["KillAura"] = kaPage

makeSectionHeader("KILL AURA", kaPage, 0)
makeStatusLabel("max range · max speed · max hitbox  ·  no config needed", kaPage).LayoutOrder = 1

local kaStatusLbl = makeStatusLabel("status: off", kaPage); kaStatusLbl.LayoutOrder = 2
makeToggleRow("kill aura enabled", kaPage, 3, function(state)
    KA.enabled = state
    kaStatusLbl.Text = state and "status: \u{1F7E2} active — destroying all targets" or "status: off"
    if state then
        KA.hitboxEnabled = true
        KA.hitboxSize = 50
        updateAllHitboxes()
        startKillAura()
    else
        stopKillAura()
        KA.hitboxEnabled = false
        KA.hitboxSize = 10
        updateAllHitboxes()
    end
end)

makeToggleRow("rescan remotes", kaPage, 4, function(state)
    if state then
        task.spawn(function()
            KA.HitRemote = nil; KA.hookInstalled = false; KA.spyReady = false
            getRemotesKA(); installSpy(); reverseEngineerModule()
        end)
    end
end)

makeStatusLabel("hitbox + nuke cooldowns always at maximum", kaPage).LayoutOrder = 5
makeStatusLabel("press insert to toggle gui visibility", kaPage).LayoutOrder = 6

-- ══════════════════════════════════════════════════════
--  SIDEBAR BUTTONS
-- ══════════════════════════════════════════════════════
local function setSideActive(btn)
    if currentFeatureBtn then
        currentFeatureBtn.TextColor3 = CLR.dim
        currentFeatureBtn.BackgroundColor3 = CLR.btn
    end
    currentFeatureBtn = btn
    if btn then
        btn.TextColor3 = CLR.white
        btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
    end
end

local function switchFeature(name, showPL, btn)
    -- stop current
    if currentFeature == "Aimlock" then stopAimlock() end
    if currentFeature == "Fly"     then stopFly() end
    if currentFeature == "TpWalk"  then stopTpWalk() end
    if currentFeature == "Color"   then stopColor() end
    if currentFeature == "MouseUnlock" then stopMouseUnlock() end

    currentFeature = name
    PlayerListFrame.Visible = showPL or false
    showPage(name)
    setSideActive(btn)
    selectedPlayer = nil
end

local btns = {}
local features = {
    {"TP",          "TP",          true,  1},
    {"AIMLOCK",     "Aimlock",     true,  2},
    {"FLY",         "Fly",         false, 3},
    {"TPWALK",      "TpWalk",      false, 4},
    {"MOUSE UNLOCK","MouseUnlock", false, 5},
    {"COLOR",       "Color",       false, 6},
    {"KILL AURA",   "KillAura",    false, 7},
}

for _, def in ipairs(features) do
    local label, key, showPL, order = def[1], def[2], def[3], def[4]
    local btn = makeSideBtn(label, order)
    btns[key] = btn
    btn.MouseButton1Click:Connect(function()
        if currentFeature == key then
            -- deselect
            if currentFeature == "Aimlock" then stopAimlock() end
            if currentFeature == "Fly"     then stopFly() end
            if currentFeature == "TpWalk"  then stopTpWalk() end
            if currentFeature == "Color"   then stopColor() end
            if currentFeature == "MouseUnlock" then stopMouseUnlock() end
            currentFeature = nil; PlayerListFrame.Visible = false
            setSideActive(nil)
            -- hide all pages
            for _, v in pairs(pages) do v.Visible = false end
        else
            switchFeature(key, showPL, btn)
        end
    end)
end

-- ── player list wiring ──
local playerBtns = {}
local function addPlayerBtn(targetPlayer)
    if targetPlayer == player then return end
    local btn = makePLBtn(targetPlayer)
    playerBtns[targetPlayer] = btn
    btn.MouseButton1Click:Connect(function()
        if currentFeature == "TP" then
            local char = player.Character
            local targetChar = targetPlayer.Character
            if char and targetChar then
                local root = char:FindFirstChild("HumanoidRootPart")
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if root and targetRoot then
                    root.CFrame = targetRoot.CFrame + Vector3.new(2, 0, 0)
                end
            end
        elseif currentFeature == "Aimlock" then
            startAimlock(targetPlayer)
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do addPlayerBtn(p) end
Players.PlayerAdded:Connect(addPlayerBtn)
Players.PlayerRemoving:Connect(function(p)
    if playerBtns[p] then playerBtns[p]:Destroy(); playerBtns[p] = nil end
end)

-- ── insert key toggle visibility ──
UIS.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.Insert then
        Main.Visible = not Main.Visible
    end
end)

-- ── default page ──
showPage("TP")
setSideActive(btns["TP"])
currentFeature = "TP"

updateGradients()
