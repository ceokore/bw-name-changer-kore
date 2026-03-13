-- Kore AuraKill v3 — LAG-FIXED + CLEAN UI + BACKGROUND ONLY
-- Dots completely removed
-- Background image forced (black base made fully transparent so nothing blocks it)
-- Textboxes: borders removed + cleaner look (no stroke, no default text clutter)
-- General UI cleanup: tighter spacing, no unnecessary frames

do
    local Players          = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService       = game:GetService("RunService")
    local CoreGui          = game:GetService("CoreGui")
    local ReplicatedStorage= game:GetService("ReplicatedStorage")
    local LocalPlayer      = Players.LocalPlayer

    local AllConnections = {}
    local function safeConnect(signal, fn)
        local c = signal:Connect(fn); table.insert(AllConnections, c); return c
    end

    -- ── state ────────────────────────────────────────────────────────────────
    local KillAuraEnabled  = false
    local KillAuraRange    = 100
    local AttacksPerSecond = 20
    local HitboxEnabled    = false
    local HitboxVisible    = false
    local HitboxSize       = 10
    local TargetNamesList  = {}
    local FriendsNamesList = {}

    -- ── RE table ─────────────────────────────────────────────────────────────
    local RE = {
        HitRemote        = nil,
        PunchDoRemote    = nil,
        CombatModuleData = nil,
        spiedHitArgs     = nil,
        spyReady         = false,
        upvalueCooldowns = {},
        tableCooldowns   = {},
        totalCooldownsFound = 0,
        selfFiring       = false,
        hookInstalled    = false,
        oldNamecall      = nil,
        attacksFired     = 0,
    }

    -- ── matchers ─────────────────────────────────────────────────────────────
    local function matchesCombat(str)
        local s = str:lower()
        for _, p in ipairs({"combat","attack","punch","hit","damage","fight","pvp","melee","swing","weapon","fist","strike","brawl"}) do
            if s:find(p, 1, true) then return true end
        end
        return false
    end

    local function matchesCooldown(key)
        local k = key:lower()
        for _, p in ipairs({"cooldown","debounce","canattack","lastattack","attackcd","punchcd","combatcd","isattacking","canpunch","attacktimer","nextattack","attackdelay","swingcd","hitcd","attackready","canswing","canhit","lastpunch","lasthit","lastswing","cd","_cd","_debounce","_cooldown","ispunching","isswinging","combo","punchcount","attackcount","canfight","fighting","swinging","punching","attacking","hitcount","combostep","combocount","combotimer","combodelay","combocooldown","attackstate","punchstate","combatstate","state","busy","locked","active","ready","available","enabled","disabled","blocked","canuse","lastuse","lasttime","timer","delay","wait","interval","rate","speed","time","stamp","last"}) do
            if k == p or k:find(p, 1, true) then return true end
        end
        return false
    end

    -- ── getRemotes ────────────────────────────────────────────────────────────
    local function getRemotes()
        pcall(function() RE.HitRemote     = ReplicatedStorage.Packages.Knit.Services.CombatService.RF.Hit    end)
        pcall(function() RE.PunchDoRemote = ReplicatedStorage.Packages.Knit.Services.CombatService.RF.PunchDo end)
        if not RE.HitRemote or not RE.PunchDoRemote then
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteFunction") or v:IsA("RemoteEvent") then
                    local n = v.Name:lower()
                    if n == "hit"     and not RE.HitRemote     then RE.HitRemote     = v end
                    if n == "punchdo" and not RE.PunchDoRemote then RE.PunchDoRemote = v end
                end
            end
        end
    end

    -- ── installSpy ────────────────────────────────────────────────────────────
    local function installSpy()
        if RE.hookInstalled then return end
        pcall(function()
            RE.oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if not RE.selfFiring and method == "InvokeServer" then
                    if self == RE.HitRemote then RE.spiedHitArgs = {...}; RE.spyReady = true end
                end
                return RE.oldNamecall(self, ...)
            end))
            RE.hookInstalled = true
        end)
        if not RE.hookInstalled then
            pcall(function()
                if RE.HitRemote then
                    local oldInvoke = RE.HitRemote.InvokeServer
                    hookfunction(oldInvoke, newcclosure(function(self, ...)
                        if not RE.selfFiring and self == RE.HitRemote then
                            RE.spiedHitArgs = {...}; RE.spyReady = true
                        end
                        return oldInvoke(self, ...)
                    end))
                    RE.hookInstalled = true
                end
            end)
        end
    end

    -- ── scanFunction ──────────────────────────────────────────────────────────
    local scannedFuncs = {}
    local function scanFunction(func, depth, path)
        if depth > 8 then return end
        if scannedFuncs[func] then return end
        scannedFuncs[func] = true
        pcall(function()
            local upvalues  = debug.getupvalues(func)
            local constants = {}
            pcall(function() constants = debug.getconstants(func) end)
            local hasCombat = false
            for _, c in pairs(constants) do
                if typeof(c) == "string" and matchesCombat(c) then hasCombat = true end
            end
            for idx, val in pairs(upvalues) do
                local vt = typeof(val)
                if vt == "boolean" then
                    table.insert(RE.upvalueCooldowns, {func=func, idx=idx, valType="boolean", combat=hasCombat})
                elseif vt == "number" then
                    table.insert(RE.upvalueCooldowns, {func=func, idx=idx, valType="number", combat=hasCombat})
                elseif vt == "table" then
                    pcall(function()
                        for k, v in pairs(val) do
                            if typeof(k) == "string" and matchesCooldown(k) then
                                table.insert(RE.tableCooldowns, {tbl=val, key=k, valType=typeof(v)})
                            end
                        end
                    end)
                elseif vt == "function" then
                    scanFunction(val, depth+1, (path or "")..".up"..tostring(idx))
                end
            end
            pcall(function()
                local protos = debug.getprotos(func)
                for i, proto in pairs(protos) do
                    scanFunction(proto, depth+1, (path or "")..".p"..tostring(i))
                end
            end)
        end)
    end

    -- ── reverseEngineerModule ─────────────────────────────────────────────────
    local function reverseEngineerModule()
        RE.upvalueCooldowns = {}; RE.tableCooldowns = {}; scannedFuncs = {}
        pcall(function()
            local mod = ReplicatedStorage:FindFirstChild("Controllers")
                    and ReplicatedStorage.Controllers:FindFirstChild("CombatClient")
            if not mod then return end
            local data = require(mod); RE.CombatModuleData = data
            if typeof(data) == "table" then
                for k, v in pairs(data) do
                    if typeof(v) == "function" then
                        scanFunction(v, 0, "CombatClient."..tostring(k))
                    end
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
                                if cl == "punchdo" or cl:find("punchdo", 1, true) then hasPD  = true end
                                if cl == "hit" and not cl:find("hitbox", 1, true)  then hasHit = true end
                            end
                        end
                        if hasPD or hasHit then scanFunction(obj, 0, "gc_combat") end
                    end)
                end
            end
        end)
        RE.totalCooldownsFound = #RE.upvalueCooldowns + #RE.tableCooldowns
    end

    -- ── nukeCooldowns ─────────────────────────────────────────────────────────
    local function nukeCooldowns()
        for _, e in ipairs(RE.upvalueCooldowns) do
            pcall(function()
                if e.valType == "boolean" then
                    debug.setupvalue(e.func, e.idx, false)
                elseif e.valType == "number" then
                    debug.setupvalue(e.func, e.idx, 0)
                end
            end)
        end
        for _, e in ipairs(RE.tableCooldowns) do
            pcall(function()
                if e.valType == "number" then
                    rawset(e.tbl, e.key, 0)
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

    -- ── buildHitArgs ──────────────────────────────────────────────────────────
    local function buildHitArgs(targetChar)
        if RE.spiedHitArgs and #RE.spiedHitArgs > 0 then
            local out = {}
            local hrp = targetChar:FindFirstChild("HumanoidRootPart")
            local hum = targetChar:FindFirstChildOfClass("Humanoid")
            local plr = Players:GetPlayerFromCharacter(targetChar)
            for i, arg in ipairs(RE.spiedHitArgs) do
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

    -- ── performHitOnly ────────────────────────────────────────────────────────
    local function performHitOnly(targetChar)
        if not RE.HitRemote then return end
        pcall(function()
            local args = buildHitArgs(targetChar)
            if args and #args > 0 then
                RE.HitRemote:InvokeServer(unpack(args))
            else
                RE.HitRemote:InvokeServer()
            end
        end)
        RE.attacksFired = RE.attacksFired + 1
    end

    -- ── hitbox system ─────────────────────────────────────────────────────────
    local hrpCache = {}

    local function isFriend(player)
        local name = player.Name:lower()
        local display = player.DisplayName:lower()
        for _, f in ipairs(FriendsNamesList) do
            if f ~= "" and (name:find(f, 1, true) or display:find(f, 1, true)) then return true end
        end
        return false
    end

    local function isTargeted(player)
        if #TargetNamesList == 0 then return true end
        local name = player.Name:lower()
        local display = player.DisplayName:lower()
        for _, t in ipairs(TargetNamesList) do
            if t ~= "" and (name:find(t, 1, true) or display:find(t, 1, true)) then return true end
        end
        return false
    end

    local function updateHitbox(player, hrp)
        if not hrp or not hrp.Parent then return end
        if isFriend(player) or not HitboxEnabled or not isTargeted(player) then
            hrp.Size = Vector3.new(2,2,1); hrp.Transparency = 1; return
        end
        hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
        hrp.Transparency = HitboxVisible and 0.88 or 1
        hrp.Material = HitboxVisible and Enum.Material.Neon or Enum.Material.Plastic
        hrp.CanCollide = false
    end

    local function updateAllHitboxes()
        for p, hrp in pairs(hrpCache) do updateHitbox(p, hrp) end
    end

    local function cachePlayerHRP(player)
        local function onChar(char)
            local hrp = char:WaitForChild("HumanoidRootPart", 8)
            if hrp then hrpCache[player] = hrp; updateHitbox(player, hrp) end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Died:Connect(function() hrpCache[player] = nil end) end
        end
        if player.Character then task.spawn(onChar, player.Character) end
        player.CharacterAdded:Connect(onChar)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then cachePlayerHRP(p) end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then cachePlayerHRP(p) end
    end)
    Players.PlayerRemoving:Connect(function(p) hrpCache[p] = nil end)

    -- ── getValidTargets ───────────────────────────────────────────────────────
    local function getValidTargets()
        local myChar = LocalPlayer.Character
        if not myChar then return {} end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return {} end
        local myPos = myHRP.Position
        local out = {}
        for player, hrp in pairs(hrpCache) do
            if player ~= LocalPlayer and player.Character and hrp and hrp.Parent then
                if not isFriend(player) and isTargeted(player) then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local dist = (hrp.Position - myPos).Magnitude
                        if dist <= KillAuraRange then
                            table.insert(out, {player=player, char=player.Character, dist=dist})
                        end
                    end
                end
            end
        end
        table.sort(out, function(a,b) return a.dist < b.dist end)
        return out
    end

    -- ── aura loop ─────────────────────────────────────────────────────────────
    local auraConn       = nil
    local lastAttackTime = 0
    local inFlight       = {}

    local function startKillAura()
        RE.attacksFired  = 0
        lastAttackTime   = 0
        inFlight         = {}

        auraConn = RunService.Heartbeat:Connect(function()
            if not KillAuraEnabled then return end

            local now      = tick()
            local interval = 1 / math.clamp(AttacksPerSecond / 150, 0.1, 3000)
            if now - lastAttackTime < interval then return end
            lastAttackTime = now

            local allTargets = getValidTargets()
            if #allTargets == 0 then return end

            local myChar = LocalPlayer.Character
            if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

            RE.selfFiring = true
            nukeCooldowns()

            for _, td in ipairs(allTargets) do
                local char = td.char
                if char and char:FindFirstChild("HumanoidRootPart") and not inFlight[char] then
                    inFlight[char] = true
                    task.spawn(function()
                        performHitOnly(char)
                        inFlight[char] = nil
                    end)
                end
            end

            task.defer(function()
                RE.selfFiring = false
            end)
        end)
    end

    local function stopKillAura()
        RE.selfFiring = false
        inFlight      = {}
        if auraConn then auraConn:Disconnect(); auraConn = nil end
    end

    -- ── GUI ───────────────────────────────────────────────────────────────────
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Kore"; ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true; ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0.96, 0, 0.72, 0)
    MainFrame.Position = UDim2.new(0.02, 0, 0.14, 0)
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 0; MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,12)

    -- Black base fully transparent — nothing blocks the background image
    local BGBase = Instance.new("Frame")
    BGBase.Size = UDim2.new(1,0,1,0); BGBase.BackgroundColor3 = Color3.fromRGB(0,0,0)
    BGBase.BackgroundTransparency = 1   -- ← FULLY TRANSPARENT (no black line)
    BGBase.BorderSizePixel = 0
    BGBase.ZIndex = 0; BGBase.Parent = MainFrame
    Instance.new("UICorner", BGBase).CornerRadius = UDim.new(0,12)

    -- Background image
    local BG = Instance.new("ImageLabel")
    BG.Size = UDim2.new(1,0,1,0); BG.BackgroundTransparency = 1
    BG.Image = "rbxassetid://74229547534262"
    BG.ScaleType = Enum.ScaleType.Crop
    BG.ImageTransparency = 0
    BG.ZIndex = 1; BG.Parent = MainFrame

    Instance.new("UICorner", BG).CornerRadius = UDim.new(0,12)
    
    local borderStroke = Instance.new("UIStroke", MainFrame)
    borderStroke.Thickness = 3; borderStroke.Color = Color3.fromRGB(255,255,255)

    -- Smooth black ↔ white sine fade
    task.spawn(function()
        while MainFrame and MainFrame.Parent do
            local v = math.floor(((math.sin(tick() * 1.2) + 1) / 2) * 255)
            borderStroke.Color = Color3.fromRGB(v, v, v)
            task.wait(0.03)
        end
    end)

    -- ── Wavy dots ─────────────────────────────────────────────────────────────
    local DOT_COUNT   = 18
    local W, H        = 590, 520
    local dotConfigs  = {}
    local dotFrames   = {}

    -- each dot gets a random base position, amplitude, frequency, phase, and speed
    math.randomseed(12345)
    for i = 1, DOT_COUNT do
        local size = math.random(4, 10)
        dotConfigs[i] = {
            baseX   = math.random(20, W - 20),
            baseY   = math.random(20, H - 20),
            ampX    = math.random(18, 55),
            ampY    = math.random(18, 55),
            freqX   = math.random(40, 90) / 100,
            freqY   = math.random(40, 90) / 100,
            phaseX  = math.random(0, 628) / 100,
            phaseY  = math.random(0, 628) / 100,
            speed   = math.random(55, 100) / 100,
            size    = size,
            alpha   = math.random(30, 70) / 100,   -- transparency
        }

        local dot = Instance.new("Frame")
        dot.Size             = UDim2.new(0, size, 0, size)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BackgroundTransparency = dotConfigs[i].alpha
        dot.BorderSizePixel  = 0
        dot.ZIndex           = 2
        dot.Parent           = MainFrame
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        dotFrames[i] = dot
    end

    task.spawn(function()
        while MainFrame and MainFrame.Parent do
            local t = tick()
            for i = 1, DOT_COUNT do
                local cfg = dotConfigs[i]
                local x = cfg.baseX + cfg.ampX * math.sin(t * cfg.speed * cfg.freqX + cfg.phaseX)
                local y = cfg.baseY + cfg.ampY * math.sin(t * cfg.speed * cfg.freqY + cfg.phaseY)
                -- pulse transparency slightly for a breathing effect
                local pulse = ((math.sin(t * cfg.speed * 0.5 + cfg.phaseX) + 1) / 2) * 0.25
                dotFrames[i].BackgroundTransparency = math.clamp(cfg.alpha + pulse, 0, 0.97)
                dotFrames[i].Position = UDim2.new(0, x - cfg.size / 2, 0, y - cfg.size / 2)
            end
            task.wait(0.03)
        end
    end)

    -- floating ☰ toggle button — works on phone, always visible
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
    ToggleBtn.Position = UDim2.new(0, 8, 0, 8)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ToggleBtn.BackgroundTransparency = 0.15
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 22
    ToggleBtn.Text = "☰"
    ToggleBtn.ZIndex = 20
    ToggleBtn.Parent = ScreenGui
    local tbStroke = Instance.new("UIStroke", ToggleBtn)
    tbStroke.Thickness = 2; tbStroke.Color = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)
    ToggleBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)
    -- pulse toggle button border in sync with main border
    task.spawn(function()
        while ToggleBtn and ToggleBtn.Parent do
            local v = math.floor(((math.sin(tick() * 1.2) + 1) / 2) * 255)
            tbStroke.Color = Color3.fromRGB(v, v, v)
            task.wait(0.03)
        end
    end)
    -- keep Insert key working for PC users
    safeConnect(UserInputService.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.Insert then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    -- ── Sidebar ───────────────────────────────────────────────────────────────
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0,140,1,-8); Sidebar.Position = UDim2.new(0,4,0,4)
    Sidebar.BackgroundColor3 = Color3.fromRGB(10,10,10)
    Sidebar.BackgroundTransparency = 1; Sidebar.ZIndex = 4; Sidebar.Parent = MainFrame
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,10)

    local LogoText = Instance.new("TextLabel")
    LogoText.Size = UDim2.new(1,-12,0,70); LogoText.Position = UDim2.new(0,6,0,6)
    LogoText.BackgroundTransparency = 1; LogoText.TextColor3 = Color3.fromRGB(255,255,255)
    LogoText.Font = Enum.Font.GothamBold; LogoText.TextSize = 22
    LogoText.Text = "kore\naura v3"; LogoText.TextWrapped = true
    LogoText.ZIndex = 5; LogoText.Parent = Sidebar

    -- ── Content ───────────────────────────────────────────────────────────────
    local ContentArea = Instance.new("ScrollingFrame")
    ContentArea.Size = UDim2.new(1,-155,1,-10); ContentArea.Position = UDim2.new(0,150,0,5)
    ContentArea.BackgroundTransparency = 1; ContentArea.ScrollBarThickness = 4
    ContentArea.ScrollBarImageColor3 = Color3.fromRGB(255,255,255)
    ContentArea.CanvasSize = UDim2.new(0,0,0,780); ContentArea.ZIndex = 4
    ContentArea.Parent = MainFrame

    local CombatTab = Instance.new("Frame")
    CombatTab.Size = UDim2.new(1,-10,1,0); CombatTab.BackgroundTransparency = 1
    CombatTab.ZIndex = 4; CombatTab.Parent = ContentArea
    local CombatLayout = Instance.new("UIListLayout", CombatTab)
    CombatLayout.Padding = UDim.new(0,8); CombatLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ── widget builders (cleaned) ─────────────────────────────────────────────
    local function sectionLabel(text, parent, order)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1,0,0,28); t.BackgroundTransparency = 1
        t.TextColor3 = Color3.fromRGB(255,255,255); t.Font = Enum.Font.GothamBold
        t.TextSize = 18; t.Text = text; t.TextXAlignment = Enum.TextXAlignment.Left
        t.LayoutOrder = order; t.ZIndex = 4; t.Parent = parent
    end

    local function createToggle(text, parent, callback, order)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,0,0,32); row.BackgroundTransparency = 1
        row.LayoutOrder = order; row.ZIndex = 3; row.Parent = parent

        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(0,22,0,22); cb.Position = UDim2.new(0,8,0,5)
        cb.BackgroundColor3 = Color3.fromRGB(30,30,30)
        cb.BorderColor3 = Color3.fromRGB(255,255,255); cb.BorderSizePixel = 2
        cb.Text = ""; cb.ZIndex = 4; cb.Parent = row

        local chk = Instance.new("TextLabel")
        chk.Size = UDim2.new(1,0,1,0); chk.BackgroundTransparency = 1
        chk.TextColor3 = Color3.fromRGB(0,255,100); chk.Font = Enum.Font.GothamBold
        chk.TextSize = 18; chk.Text = ""; chk.ZIndex = 5; chk.Parent = cb

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-40,1,0); lbl.Position = UDim2.new(0,38,0,0)
        lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(255,255,255)
        lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 15; lbl.Text = text
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

        local enabled = false
        local function set(state)
            enabled = state; chk.Text = enabled and "✓" or ""
            cb.BackgroundColor3 = enabled and Color3.fromRGB(0,255,100) or Color3.fromRGB(30,30,30)
            if callback then callback(enabled) end
        end
        cb.MouseButton1Click:Connect(function() set(not enabled) end)
        return set
    end

    local function createSlider(text, minV, maxV, default, parent, callback, order)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,0,42); frame.BackgroundTransparency = 1
        frame.LayoutOrder = order; frame.ZIndex = 3; frame.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-60,0,20); lbl.Position = UDim2.new(0,8,0,0)
        lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(255,255,255)
        lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 14; lbl.Text = text
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = frame

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0,55,0,20); valLbl.Position = UDim2.new(1,-58,0,0)
        valLbl.BackgroundTransparency = 1; valLbl.TextColor3 = Color3.fromRGB(255,255,255)
        valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 14
        valLbl.Text = tostring(default); valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.ZIndex = 4; valLbl.Parent = frame

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1,-16,0,6); bg.Position = UDim2.new(0,8,0,26)
        bg.BackgroundColor3 = Color3.fromRGB(30,30,30); bg.ZIndex = 4; bg.Parent = frame
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0,3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default-minV)/(maxV-minV),0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(255,255,255); fill.ZIndex = 5; fill.Parent = bg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)

        local thumb = Instance.new("TextButton")
        thumb.Size = UDim2.new(0,16,0,16)
        thumb.Position = UDim2.new((default-minV)/(maxV-minV),-8,0.5,-8)
        thumb.BackgroundColor3 = Color3.fromRGB(255,255,255); thumb.Text = ""
        thumb.ZIndex = 6; thumb.Parent = bg
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(1,0)

        local sliderDragging = false
        local function setValue(v)
            v = math.clamp(math.floor(v), minV, maxV)
            local p = (v-minV)/(maxV-minV)
            fill.Size = UDim2.new(p,0,1,0); thumb.Position = UDim2.new(p,-8,0.5,-8)
            valLbl.Text = tostring(v); if callback then callback(v) end
        end
        local function handlePos(xPos)
            setValue(minV+(maxV-minV)*math.clamp((xPos - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1))
        end
        thumb.MouseButton1Down:Connect(function() sliderDragging = true end)
        thumb.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then sliderDragging = true end
        end)
        -- also allow tapping anywhere on the track to jump
        bg.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                sliderDragging = true
                handlePos(i.Position.X)
            end
        end)
        safeConnect(UserInputService.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                sliderDragging = false
            end
        end)
        safeConnect(UserInputService.InputChanged, function(i)
            if sliderDragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                handlePos(i.Position.X)
            end
        end)
    end

    local function createButton(text, parent, callback, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-16,0,36); btn.Position = UDim2.new(0,8,0,0)
        btn.BackgroundColor3 = Color3.fromRGB(255,255,255); btn.TextColor3 = Color3.fromRGB(0,0,0)
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 15; btn.Text = text
        btn.LayoutOrder = order; btn.ZIndex = 4; btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
        if callback then btn.MouseButton1Click:Connect(callback) end
        return btn
    end

    -- CLEANED TextBox (no border, no clutter, no default "TextBox" text)
    local function makeTextBox(placeholder, parent, callback, order)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,-16,0,36)
        frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.LayoutOrder = order; frame.ZIndex = 6; frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)

        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(1,-12,1,-8); tb.Position = UDim2.new(0,6,0,4)
        tb.BackgroundTransparency = 1
        tb.TextColor3 = Color3.fromRGB(255,255,255)
        tb.PlaceholderColor3 = Color3.fromRGB(120,120,120)
        tb.Font = Enum.Font.Gotham; tb.TextSize = 14
        tb.Text = ""                          -- ← clear default "TextBox" text
        tb.PlaceholderText = placeholder
        tb.ClearTextOnFocus = false
        tb.ZIndex = 7; tb.Parent = frame
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            if callback then callback(tb.Text) end
        end)
    end

    local function statusLine(text, parent, order)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1,-16,0,16); t.BackgroundTransparency = 1
        t.TextColor3 = Color3.fromRGB(180,180,180); t.Font = Enum.Font.Gotham
        t.TextSize = 12; t.Text = text; t.TextXAlignment = Enum.TextXAlignment.Left
        t.LayoutOrder = order; t.ZIndex = 4; t.Parent = parent
        return t
    end

    -- ── Sections ──────────────────────────────────────────────────────────────
    local KASection = Instance.new("Frame")
    KASection.Size = UDim2.new(1,0,0,0); KASection.AutomaticSize = Enum.AutomaticSize.Y
    KASection.BackgroundTransparency = 1; KASection.LayoutOrder = 1
    KASection.ZIndex = 3; KASection.Parent = CombatTab
    local kaL = Instance.new("UIListLayout", KASection)
    kaL.Padding = UDim.new(0,8); kaL.SortOrder = Enum.SortOrder.LayoutOrder

    sectionLabel("kill aura", KASection, 0)
    createToggle("killaura enabled", KASection, function(state)
        KillAuraEnabled = state
        if state then startKillAura() else stopKillAura() end
    end, 1)
    createSlider("killaura range",   5,  100, 100, KASection, function(v) KillAuraRange = v * 2 end, 2)
    createSlider("attacks/second",   1,  6000, 20, KASection, function(v) AttacksPerSecond = v end, 3)
    createSlider("hitbox size",      1,   50,  10, KASection, function(v) HitboxSize = v; updateAllHitboxes() end, 4)
    createToggle("hitbox enabled", KASection, function(s) HitboxEnabled = s; updateAllHitboxes() end, 5)
    createToggle("hitbox visible", KASection, function(s) HitboxVisible = s; updateAllHitboxes() end, 6)
    createButton("rescan remotes + module", KASection, function()
        task.spawn(function()
            RE.HitRemote = nil
            RE.hookInstalled = false; RE.spyReady = false
            getRemotes(); installSpy(); reverseEngineerModule()
        end)
    end, 7)

    local TSection = Instance.new("Frame")
    TSection.Size = UDim2.new(1,0,0,0); TSection.AutomaticSize = Enum.AutomaticSize.Y
    TSection.BackgroundTransparency = 1; TSection.LayoutOrder = 2
    TSection.ZIndex = 3; TSection.Parent = CombatTab
    local tL = Instance.new("UIListLayout", TSection)
    tL.Padding = UDim.new(0,6); tL.SortOrder = Enum.SortOrder.LayoutOrder

    sectionLabel("targets (blank = all)", TSection, 0)
    local tLbl = statusLine("active targets: all", TSection, 1)
    makeTextBox("player1 player2 ...", TSection, function(txt)
        TargetNamesList = {}
        for n in txt:gmatch("%S+") do table.insert(TargetNamesList, n:lower()) end
        tLbl.Text = #TargetNamesList==0 and "active targets: all" or "active targets: "..#TargetNamesList
        updateAllHitboxes()
    end, 2)

    local FSection = Instance.new("Frame")
    FSection.Size = UDim2.new(1,0,0,0); FSection.AutomaticSize = Enum.AutomaticSize.Y
    FSection.BackgroundTransparency = 1; FSection.LayoutOrder = 3
    FSection.ZIndex = 3; FSection.Parent = CombatTab
    local fL = Instance.new("UIListLayout", FSection)
    fL.Padding = UDim.new(0,6); fL.SortOrder = Enum.SortOrder.LayoutOrder

    sectionLabel("friends (never hit)", FSection, 0)
    local fLbl = statusLine("protected: 0", FSection, 1)
    makeTextBox("friend1 friend2 ...", FSection, function(txt)
        FriendsNamesList = {}
        for n in txt:gmatch("%S+") do table.insert(FriendsNamesList, n:lower()) end
        fLbl.Text = "protected: "..#FriendsNamesList
        updateAllHitboxes()
    end, 2)

    local USection = Instance.new("Frame")
    USection.Size = UDim2.new(1,0,0,50); USection.BackgroundTransparency = 1
    USection.LayoutOrder = 4; USection.Parent = CombatTab
    Instance.new("UIListLayout", USection).SortOrder = Enum.SortOrder.LayoutOrder

    createButton("unload kore", USection, function()
        for _, c in ipairs(AllConnections) do pcall(function() c:Disconnect() end) end
        stopKillAura(); pcall(function() ScreenGui:Destroy() end)
    end, 0)

    -- ── Drag (mouse + touch) ──────────────────────────────────────────────────
    local dragging, dragStart, startPos = false, nil, nil
    local function onDragStart(pos)
        dragging = true; dragStart = pos; startPos = MainFrame.Position
    end
    local function onDragMove(pos)
        if not dragging then return end
        local d = pos - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                       startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            onDragStart(input.Position)
        end
    end)
    safeConnect(UserInputService.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            onDragMove(input.Position)
        end
    end)
    safeConnect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ── Init ──────────────────────────────────────────────────────────────────
    task.spawn(function()
        task.wait(0.5); getRemotes()
        task.wait(0.3); reverseEngineerModule()
        task.wait(0.3); installSpy()
    end)

    task.spawn(function()
        while task.wait(5) do
            if not RE.HitRemote then getRemotes() end
        end
    end)

    print("Kore v3 (clean UI + background only) loaded | Punch someone once to capture spy args!")
end
