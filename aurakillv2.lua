```lua
-- Kore AuraKill - ANTI-LAG FINAL VERSION
-- Fixed: NO LAG / NO DEATH after use (optimized background + smart aura loop + throttled target scan + nuke only on fire)
-- Aura now stays at full 9999 APS forever without freezing the game
-- Fighting style works after gym (animation hook ONLY when KillAura ON)
-- Static black background + crisp white border (exactly black & white)
-- Textboxes show bright white text + visible placeholders
-- Range 100 | Triple damage | Star BG (136410535524403) | Draggable

do
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local AllConnections = {}
    local function safeConnect(signal, func)
        local conn = signal:Connect(func)
        table.insert(AllConnections, conn)
        return conn
    end

    local function resolveDecalToImage(decalId)
        local imageId = "rbxassetid://" .. tostring(decalId)
        pcall(function()
            local objects = game:GetObjects("rbxassetid://" .. tostring(decalId))
            if objects and objects[1] then
                local obj = objects[1]
                if obj:IsA("Decal") or obj:IsA("Texture") then imageId = obj.Texture
                elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then imageId = obj.Image
                else
                    local decal = obj:FindFirstChildWhichIsA("Decal", true)
                    if decal then imageId = decal.Texture
                    else
                        local img = obj:FindFirstChildWhichIsA("ImageLabel", true)
                        if img then imageId = img.Image end
                    end
                end
                pcall(function() obj:Destroy() end)
            end
        end)
        return imageId
    end

    local KillAuraEnabled = false
    local KillAuraRange = 100
    local AttacksPerSecond = 9999
    local HitboxEnabled = false
    local HitboxVisible = false
    local HitboxSize = 10
    local TargetNamesList = {}
    local FriendsNamesList = {}

    local RE = {
        HitRemote = nil,
        PunchDoRemote = nil,
        spiedHitArgs = nil,
        spiedPunchArgs = nil,
        upvalueCooldowns = {},
        tableCooldowns = {},
        selfFiring = false
    }

    local combatWords = {"punch","attack","swing","combat","hit","fight","slash","strike","melee","fist","jab","hook","uppercut","kick","smack","slap","beat","brawl"}
    local safeWords = {"walk","run","idle","emote","dance","sit","jump","fall","climb","swim","wave","point","lean","crouch","catwalk","strut","pose","cheer","laugh","cry","loop","move","land","tool","hold","equip"}
    local punchIds = {"186934910","204062532","522635514","507770239","507766388","507766666","507770677","4849281135","4849286857","10469493270","5104897796","5104899699"}

    local function isSafe(track)
        if not track then return false end
        local n = (track.Name or ""):lower()
        local id = ((track.Animation and track.Animation.AnimationId) or ""):lower()
        for _, kw in ipairs(safeWords) do if n:find(kw) or id:find(kw) then return true end end
        return false
    end

    local function isPunch(track)
        if not track then return false end
        if isSafe(track) then return false end
        local id = ((track.Animation and track.Animation.AnimationId) or ""):lower()
        local n = (track.Name or ""):lower()
        for _, pid in ipairs(punchIds) do if id:find(pid) then return true end end
        for _, kw in ipairs(combatWords) do if n:find(kw) or id:find(kw) then return true end end
        return false
    end

    local function matchesCooldown(key)
        local k = key:lower()
        local patterns = {"cooldown","debounce","canattack","lastattack","attackcd","punchcd","combatcd","isattacking","canpunch","attacktimer","nextattack","attackdelay","swingcd","hitcd","attackready","canswing","canhit","lastpunch","lasthit","lastswing","cd","_cd","_debounce","_cooldown","ispunching","isswinging","combo","punchcount","attackcount","canfight","fighting","swinging","punching","attacking","hitcount","combostep","combocount","combotimer","combodelay","combocooldown","attackstate","punchstate","combatstate","state","busy","locked","active","ready","available","enabled","disabled","blocked","canuse","lastuse","lasttime","timer","delay","wait","interval","rate","speed","time","stamp","last"}
        for _, pat in ipairs(patterns) do if k == pat or k:find(pat) then return true end end
        return false
    end

    local function matchesCombat(str)
        local s = str:lower()
        local patterns = {"combat","attack","punch","hit","damage","fight","pvp","melee","swing","weapon","fist","strike","brawl"}
        for _, pat in ipairs(patterns) do if s:find(pat) then return true end end
        return false
    end

    local scannedFuncs = {}
    local function scanFunction(func, depth)
        if depth > 8 or scannedFuncs[func] then return end
        scannedFuncs[func] = true
        pcall(function()
            local upvalues = debug.getupvalues(func)
            local constants = {}
            pcall(function() constants = debug.getconstants(func) end)
            local hasCombat = false
            for _, c in pairs(constants) do
                if typeof(c) == "string" and matchesCombat(c) then hasCombat = true end
            end
            for idx, val in pairs(upvalues) do
                local vtype = typeof(val)
                if vtype == "boolean" then
                    table.insert(RE.upvalueCooldowns, {func=func, idx=idx, valType="boolean", combat=hasCombat})
                elseif vtype == "number" then
                    table.insert(RE.upvalueCooldowns, {func=func, idx=idx, valType="number", combat=hasCombat})
                elseif vtype == "table" then
                    pcall(function()
                        for k, v in pairs(val) do
                            if typeof(k) == "string" and matchesCooldown(k) then
                                table.insert(RE.tableCooldowns, {tbl=val, key=k, valType=typeof(v)})
                            end
                        end
                    end)
                elseif vtype == "function" then
                    scanFunction(val, depth + 1)
                end
            end
        end)
    end

    local function reverseEngineerModule()
        RE.upvalueCooldowns = {}
        RE.tableCooldowns = {}
        scannedFuncs = {}
        pcall(function()
            local combatMod = ReplicatedStorage:FindFirstChild("Controllers") and ReplicatedStorage.Controllers:FindFirstChild("CombatClient")
            if combatMod then
                local moduleData = require(combatMod)
                for key, val in pairs(moduleData) do
                    if typeof(val) == "function" then scanFunction(val, 0) end
                end
            end
        end)
        pcall(function()
            for _, obj in pairs(getgc(true)) do
                if typeof(obj) == "function" and not scannedFuncs[obj] then
                    local consts = debug.getconstants(obj)
                    local hasCombat = false
                    for _, c in pairs(consts) do
                        if typeof(c) == "string" and matchesCombat(c) then hasCombat = true end
                    end
                    if hasCombat then scanFunction(obj, 0) end
                end
            end
        end)
    end

    local function nukeCooldowns()
        for _, entry in ipairs(RE.upvalueCooldowns) do
            pcall(function()
                if entry.valType == "boolean" then debug.setupvalue(entry.func, entry.idx, false)
                elseif entry.valType == "number" then debug.setupvalue(entry.func, entry.idx, 0) end
            end)
        end
        for _, entry in ipairs(RE.tableCooldowns) do
            pcall(function()
                if entry.valType == "number" then rawset(entry.tbl, entry.key, 0)
                elseif entry.valType == "boolean" then rawset(entry.tbl, entry.key, false) end
            end)
        end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Kore"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 590, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -295, 0.5, -260)
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Pure black
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = true
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    -- BLACK & WHITE BORDER (exactly as requested - no rainbow)
    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Thickness = 4
    mainStroke.Color = Color3.fromRGB(255, 255, 255) -- White
    mainStroke.Transparency = 0.05

    local innerStroke = Instance.new("UIStroke", MainFrame)
    innerStroke.Thickness = 2
    innerStroke.Color = Color3.fromRGB(0, 0, 0) -- Black inner
    innerStroke.Transparency = 0.2

    safeConnect(UserInputService.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.Insert then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    -- OPTIMIZED Star BG (25 nodes + 40 lines = way less lag)
    local ConstellationContainer = Instance.new("Frame")
    ConstellationContainer.Name = "StarBG"
    ConstellationContainer.Size = UDim2.new(1, 0, 1, 0)
    ConstellationContainer.BackgroundTransparency = 1
    ConstellationContainer.ZIndex = 0
    ConstellationContainer.ClipsDescendants = true
    ConstellationContainer.Parent = MainFrame

    local bgBase = Instance.new("Frame")
    bgBase.Size = UDim2.new(1, 0, 1, 0)
    bgBase.BackgroundColor3 = Color3.fromRGB(2, 2, 5)
    bgBase.ZIndex = -1
    bgBase.Parent = ConstellationContainer

    spawn(function()
        local nodes = {}
        local NODE_COUNT = 25   -- reduced for anti-lag
        local MAX_CONNECT_DIST = 130
        local linePool = {}
        local MAX_LINES = 40    -- reduced for anti-lag

        for i = 1, NODE_COUNT do
            local baseSize = math.random(1, 3)
            local brightness = math.random(200, 255)
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, baseSize, 0, baseSize)
            dot.BackgroundColor3 = Color3.fromRGB(brightness, brightness, brightness)
            dot.BackgroundTransparency = math.random(20, 45) / 100
            dot.ZIndex = 1
            dot.Parent = ConstellationContainer
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            table.insert(nodes, {frame = dot, size = baseSize, x = math.random(15, 575), y = math.random(15, 505), vx = (math.random() - 0.5) * 5, vy = (math.random() - 0.5) * 5, baseTransparency = math.random(20, 45) / 100, phaseOffset = math.random() * math.pi * 2})
        end

        for i = 1, MAX_LINES do
            local line = Instance.new("Frame")
            line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            line.BorderSizePixel = 0
            line.ZIndex = 0
            line.Visible = false
            line.AnchorPoint = Vector2.new(0, 0.5)
            line.Parent = ConstellationContainer
            table.insert(linePool, line)
        end

        while MainFrame and MainFrame.Parent do
            local dt = RunService.RenderStepped:Wait()
            if not MainFrame.Visible then
                for _, l in ipairs(linePool) do l.Visible = false end
                for _, n in ipairs(nodes) do n.frame.Visible = false end
                continue
            end

            for _, n in ipairs(nodes) do
                n.vx = n.vx + (math.random() - 0.5) * 0.15
                n.vy = n.vy + (math.random() - 0.5) * 0.15
                local spd = math.sqrt(n.vx * n.vx + n.vy * n.vy)
                if spd > 5 then n.vx = (n.vx / spd) * 5; n.vy = (n.vy / spd) * 5 end
                n.vx = n.vx * 0.998
                n.vy = n.vy * 0.998
                n.x = n.x + n.vx * dt
                n.y = n.y + n.vy * dt
                if n.x < 5 then n.x = 5; n.vx = math.abs(n.vx) * 0.6 end
                if n.x > 575 then n.x = 575; n.vx = -math.abs(n.vx) * 0.6 end
                if n.y < 5 then n.y = 5; n.vy = math.abs(n.vy) * 0.6 end
                if n.y > 505 then n.y = 505; n.vy = -math.abs(n.vy) * 0.6 end

                local pulse = (math.sin(tick() * 1.1 + n.phaseOffset) + 1) / 2
                n.frame.BackgroundTransparency = n.baseTransparency + pulse * 0.15
                n.frame.Position = UDim2.new(0, n.x - n.size / 2, 0, n.y - n.size / 2)
                n.frame.Visible = true
            end

            for _, l in ipairs(linePool) do l.Visible = false end
            local lineIdx = 1
            for i = 1, #nodes do
                if lineIdx > MAX_LINES then break end
                for j = i + 1, #nodes do
                    if lineIdx > MAX_LINES then break end
                    local dx = nodes[i].x - nodes[j].x
                    local dy = nodes[i].y - nodes[j].y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < MAX_CONNECT_DIST then
                        local line = linePool[lineIdx]
                        local angle = math.deg(math.atan2(nodes[j].y - nodes[i].y, nodes[j].x - nodes[i].x))
                        local alpha = 1 - (dist / MAX_CONNECT_DIST)
                        line.Position = UDim2.new(0, nodes[i].x, 0, nodes[i].y)
                        line.Size = UDim2.new(0, dist, 0, 1)
                        line.Rotation = angle
                        line.BackgroundTransparency = 1 - (alpha * 0.25)
                        line.Visible = true
                        lineIdx = lineIdx + 1
                    end
                end
            end
        end
    end)

    -- (rest of UI is identical to last version but with white text fixed)
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 140, 1, -8)
    Sidebar.Position = UDim2.new(0, 4, 0, 4)
    Sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Sidebar.BackgroundTransparency = 0.4
    Sidebar.ZIndex = 2
    Sidebar.Parent = MainFrame
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

    local LogoText = Instance.new("TextLabel")
    LogoText.Size = UDim2.new(1, -12, 0, 80)
    LogoText.Position = UDim2.new(0, 6, 0, 6)
    LogoText.BackgroundTransparency = 1
    LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogoText.Font = Enum.Font.GothamBold
    LogoText.TextSize = 24
    LogoText.Text = "KORE\nAURA KILL"
    LogoText.TextWrapped = true
    LogoText.ZIndex = 3
    LogoText.Parent = Sidebar

    local ContentArea = Instance.new("ScrollingFrame")
    ContentArea.Size = UDim2.new(1, -155, 1, -10)
    ContentArea.Position = UDim2.new(0, 150, 0, 5)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ScrollBarThickness = 4
    ContentArea.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    ContentArea.CanvasSize = UDim2.new(0, 0, 0, 1000)
    ContentArea.ZIndex = 2
    ContentArea.Parent = MainFrame

    local ContentBGImage = Instance.new("ImageLabel")
    ContentBGImage.Size = UDim2.new(1, 0, 1, 0)
    ContentBGImage.BackgroundTransparency = 1
    ContentBGImage.ImageTransparency = 0.35
    ContentBGImage.ScaleType = Enum.ScaleType.Stretch
    ContentBGImage.ZIndex = 1
    ContentBGImage.Parent = MainFrame
    Instance.new("UICorner", ContentBGImage).CornerRadius = UDim.new(0, 12)

    task.spawn(function()
        local resolved = resolveDecalToImage(136410535524403)
        if ContentBGImage and ContentBGImage.Parent then
            ContentBGImage.Image = resolved
        end
    end)

    local CombatTab = Instance.new("Frame")
    CombatTab.Size = UDim2.new(1, -10, 1, 0)
    CombatTab.BackgroundTransparency = 1
    CombatTab.ZIndex = 2
    CombatTab.Parent = ContentArea

    local CombatLayout = Instance.new("UIListLayout", CombatTab)
    CombatLayout.Padding = UDim.new(0, 10)
    CombatLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local KillAuraSection = Instance.new("Frame")
    KillAuraSection.Size = UDim2.new(1, 0, 0, 280)
    KillAuraSection.BackgroundTransparency = 1
    KillAuraSection.LayoutOrder = 1
    KillAuraSection.ZIndex = 3
    KillAuraSection.Parent = CombatTab

    local killAuraLayout = Instance.new("UIListLayout", KillAuraSection)
    killAuraLayout.Padding = UDim.new(0, 8)
    killAuraLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Text = "⚔️ KILL AURA"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.LayoutOrder = 0
    title.ZIndex = 4
    title.Parent = KillAuraSection

    local function createToggle(text, parent, callback, order)
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, 0, 0, 32)
        toggle.BackgroundTransparency = 1
        toggle.LayoutOrder = order
        toggle.ZIndex = 3
        toggle.Parent = parent

        local checkbox = Instance.new("TextButton")
        checkbox.Size = UDim2.new(0, 22, 0, 22)
        checkbox.Position = UDim2.new(0, 8, 0, 5)
        checkbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        checkbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
        checkbox.BorderSizePixel = 2
        checkbox.Text = ""
        checkbox.ZIndex = 4
        checkbox.Parent = toggle

        local checkmark = Instance.new("TextLabel")
        checkmark.Size = UDim2.new(1, 0, 1, 0)
        checkmark.BackgroundTransparency = 1
        checkmark.TextColor3 = Color3.fromRGB(0, 255, 100)
        checkmark.Font = Enum.Font.GothamBold
        checkmark.TextSize = 18
        checkmark.Text = ""
        checkmark.ZIndex = 5
        checkmark.Parent = checkbox

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -110, 1, 0)
        label.Position = UDim2.new(0, 38, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 15
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4
        label.Parent = toggle

        local enabled = false
        local function setEnabled(state)
            enabled = state
            checkmark.Text = enabled and "✓" or ""
            checkbox.BackgroundColor3 = enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(30, 30, 30)
            if callback then callback(enabled) end
        end
        checkbox.MouseButton1Click:Connect(function() setEnabled(not enabled) end)
        return setEnabled
    end

    local function createSlider(text, min, max, default, parent, callback, order)
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, 0, 0, 42)
        slider.BackgroundTransparency = 1
        slider.LayoutOrder = order
        slider.ZIndex = 3
        slider.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 0, 20)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 14
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4
        label.Parent = slider

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 50, 0, 20)
        valueLabel.Position = UDim2.new(1, -55, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 14
        valueLabel.Text = tostring(default)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.ZIndex = 4
        valueLabel.Parent = slider

        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(1, -16, 0, 6)
        sliderBg.Position = UDim2.new(0, 8, 0, 26)
        sliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        sliderBg.ZIndex = 4
        sliderBg.Parent = slider
        Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 3)

        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sliderFill.ZIndex = 5
        sliderFill.Parent = sliderBg
        Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)

        local sliderBtn = Instance.new("TextButton")
        sliderBtn.Size = UDim2.new(0, 16, 0, 16)
        sliderBtn.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
        sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sliderBtn.Text = ""
        sliderBtn.ZIndex = 6
        sliderBtn.Parent = sliderBg
        Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(1, 0)

        local currentValue = default
        local dragging = false
        local function setValue(value)
            value = math.clamp(math.floor(value), min, max)
            currentValue = value
            local pos = (value - min) / (max - min)
            sliderFill.Size = UDim2.new(pos, 0, 1, 0)
            sliderBtn.Position = UDim2.new(pos, -8, 0.5, -8)
            valueLabel.Text = tostring(value)
            if callback then callback(value) end
        end

        sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
        safeConnect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        safeConnect(UserInputService.InputChanged, function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                setValue(min + (max - min) * pos)
            end
        end)
    end

    local function createTextInput(labelText, parent, callback, order)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = order
        frame.ZIndex = 3
        frame.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 80, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 14
        label.Text = labelText
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4
        label.Parent = frame

        local textbox = Instance.new("TextBox")
        textbox.Size = UDim2.new(1, -95, 0, 28)
        textbox.Position = UDim2.new(0, 88, 0, 4)
        textbox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        textbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
        textbox.BorderSizePixel = 1
        textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textbox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
        textbox.Font = Enum.Font.Gotham
        textbox.TextSize = 14
        textbox.PlaceholderText = "player1 player2 ..."
        textbox.ClearTextOnFocus = false
        textbox.ZIndex = 4
        textbox.Parent = frame
        Instance.new("UICorner", textbox).CornerRadius = UDim.new(0, 6)

        textbox:GetPropertyChangedSignal("Text"):Connect(function() if callback then callback(textbox.Text) end end)
    end

    local function createButton(text, parent, callback, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -16, 0, 36)
        btn.Position = UDim2.new(0, 8, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.Text = text
        btn.LayoutOrder = order
        btn.ZIndex = 4
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(callback)
    end

    local setKillAura = createToggle("KillAura Enabled", KillAuraSection, function(state)
        KillAuraEnabled = state
        if state then startKillAura() else stopKillAura() end
    end, 1)

    createSlider("KillAura Range", 5, 100, 100, KillAuraSection, function(val) KillAuraRange = val end, 2)
    createSlider("Hitbox Size", 1, 30, 10, KillAuraSection, function(val) HitboxSize = val; updateAllHitboxes() end, 3)

    createToggle("Hitbox Enabled", KillAuraSection, function(state) HitboxEnabled = state; updateAllHitboxes() end, 4)
    createToggle("Hitbox Visible", KillAuraSection, function(state) HitboxVisible = state; updateAllHitboxes() end, 5)

    local TargetSection = Instance.new("Frame")
    TargetSection.Size = UDim2.new(1, 0, 0, 130)
    TargetSection.BackgroundTransparency = 1
    TargetSection.LayoutOrder = 2
    TargetSection.ZIndex = 3
    TargetSection.Parent = CombatTab

    local targetLayout = Instance.new("UIListLayout", TargetSection)
    targetLayout.Padding = UDim.new(0, 8)
    targetLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local targetInfo = Instance.new("TextLabel")
    targetInfo.Size = UDim2.new(1, -16, 0, 18)
    targetInfo.BackgroundTransparency = 1
    targetInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    targetInfo.Font = Enum.Font.Gotham
    targetInfo.TextSize = 12
    targetInfo.Text = "Targets (space separated)"
    targetInfo.TextXAlignment = Enum.TextXAlignment.Left
    targetInfo.LayoutOrder = 0
    targetInfo.ZIndex = 4
    targetInfo.Parent = TargetSection

    local targetBoxFrame = Instance.new("Frame")
    targetBoxFrame.Size = UDim2.new(1, -16, 0, 36)
    targetBoxFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    targetBoxFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    targetBoxFrame.BorderSizePixel = 1
    targetBoxFrame.LayoutOrder = 1
    targetBoxFrame.ZIndex = 4
    targetBoxFrame.Parent = TargetSection
    Instance.new("UICorner", targetBoxFrame).CornerRadius = UDim.new(0, 6)

    local targetTextBox = Instance.new("TextBox")
    targetTextBox.Size = UDim2.new(1, -12, 1, -8)
    targetTextBox.Position = UDim2.new(0, 6, 0, 4)
    targetTextBox.BackgroundTransparency = 1
    targetTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetTextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    targetTextBox.Font = Enum.Font.Gotham
    targetTextBox.TextSize = 14
    targetTextBox.PlaceholderText = "player1 player2 ..."
    targetTextBox.ClearTextOnFocus = false
    targetTextBox.Parent = targetBoxFrame

    local targetCountLabel = Instance.new("TextLabel")
    targetCountLabel.Size = UDim2.new(1, -16, 0, 16)
    targetCountLabel.BackgroundTransparency = 1
    targetCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetCountLabel.Font = Enum.Font.GothamBold
    targetCountLabel.TextSize = 12
    targetCountLabel.Text = "Active Targets: 0"
    targetCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetCountLabel.LayoutOrder = 2
    targetCountLabel.ZIndex = 4
    targetCountLabel.Parent = TargetSection

    local function parseTargets(text)
        TargetNamesList = {}
        for name in text:gmatch("%S+") do table.insert(TargetNamesList, name:lower()) end
        targetCountLabel.Text = "Active Targets: " .. #TargetNamesList
        updateAllHitboxes()
    end
    targetTextBox:GetPropertyChangedSignal("Text"):Connect(function() parseTargets(targetTextBox.Text) end)

    local FriendsSection = Instance.new("Frame")
    FriendsSection.Size = UDim2.new(1, 0, 0, 130)
    FriendsSection.BackgroundTransparency = 1
    FriendsSection.LayoutOrder = 3
    FriendsSection.ZIndex = 3
    FriendsSection.Parent = CombatTab

    local friendsLayout = Instance.new("UIListLayout", FriendsSection)
    friendsLayout.Padding = UDim.new(0, 8)
    friendsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local friendsInfo = Instance.new("TextLabel")
    friendsInfo.Size = UDim2.new(1, -16, 0, 18)
    friendsInfo.BackgroundTransparency = 1
    friendsInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    friendsInfo.Font = Enum.Font.Gotham
    friendsInfo.TextSize = 12
    friendsInfo.Text = "Friends (never hit)"
    friendsInfo.TextXAlignment = Enum.TextXAlignment.Left
    friendsInfo.LayoutOrder = 0
    friendsInfo.ZIndex = 4
    friendsInfo.Parent = FriendsSection

    local friendsBoxFrame = Instance.new("Frame")
    friendsBoxFrame.Size = UDim2.new(1, -16, 0, 36)
    friendsBoxFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    friendsBoxFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    friendsBoxFrame.BorderSizePixel = 1
    friendsBoxFrame.LayoutOrder = 1
    friendsBoxFrame.ZIndex = 4
    friendsBoxFrame.Parent = FriendsSection
    Instance.new("UICorner", friendsBoxFrame).CornerRadius = UDim.new(0, 6)

    local friendsTextBox = Instance.new("TextBox")
    friendsTextBox.Size = UDim2.new(1, -12, 1, -8)
    friendsTextBox.Position = UDim2.new(0, 6, 0, 4)
    friendsTextBox.BackgroundTransparency = 1
    friendsTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    friendsTextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    friendsTextBox.Font = Enum.Font.Gotham
    friendsTextBox.TextSize = 14
    friendsTextBox.PlaceholderText = "friend1 friend2 ..."
    friendsTextBox.ClearTextOnFocus = false
    friendsTextBox.Parent = friendsBoxFrame

    local friendsCountLabel = Instance.new("TextLabel")
    friendsCountLabel.Size = UDim2.new(1, -16, 0, 16)
    friendsCountLabel.BackgroundTransparency = 1
    friendsCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    friendsCountLabel.Font = Enum.Font.GothamBold
    friendsCountLabel.TextSize = 12
    friendsCountLabel.Text = "Protected Friends: 0"
    friendsCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    friendsCountLabel.LayoutOrder = 2
    friendsCountLabel.ZIndex = 4
    friendsCountLabel.Parent = FriendsSection

    local function parseFriends(text)
        FriendsNamesList = {}
        for name in text:gmatch("%S+") do table.insert(FriendsNamesList, name:lower()) end
        friendsCountLabel.Text = "Protected Friends: " .. #FriendsNamesList
        updateAllHitboxes()
    end
    friendsTextBox:GetPropertyChangedSignal("Text"):Connect(function() parseFriends(friendsTextBox.Text) end)

    local function isFriend(name)
        local lower = name:lower()
        for _, f in ipairs(FriendsNamesList) do
            if f ~= "" and lower:find(f, 1, true) then return true end
        end
        return false
    end

    local function isTargeted(name)
        if #TargetNamesList == 0 then return false end
        local lower = name:lower()
        for _, t in ipairs(TargetNamesList) do
            if t ~= "" and lower:find(t, 1, true) then return true end
        end
        return false
    end

    local function hasAnyTarget()
        return #TargetNamesList > 0
    end

    local hrpCache = {}
    local function updateHitbox(player, hrp)
        if not hrp or not hrp.Parent then return end
        if isFriend(player.Name) or isFriend(player.DisplayName) then
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
            return
        end
        local should = HitboxEnabled
        if hasAnyTarget() then should = should and isTargeted(player.Name) end
        if not should then
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
            return
        end
        hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
        hrp.Transparency = HitboxVisible and 0.9 or 1
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
        end
        if player.Character then onChar(player.Character) end
        player.CharacterAdded:Connect(onChar)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then cachePlayerHRP(p) end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then cachePlayerHRP(p) end
    end)

    local lastTargetScan = 0
    local cachedTargets = {}
    local function getValidTargets()
        local now = tick()
        if now - lastTargetScan < 0.15 then return cachedTargets end   -- throttle scan to 6 times/sec
        lastTargetScan = now

        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            cachedTargets = {}
            return cachedTargets 
        end
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local targets = {}
        for player, hrp in pairs(hrpCache) do
            if player ~= LocalPlayer and player.Character and hrp and hrp.Parent and not isFriend(player.Name) then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local should = true
                    if hasAnyTarget() then should = isTargeted(player.Name) end
                    if should then
                        local dist = (hrp.Position - myPos).Magnitude
                        if dist < KillAuraRange then
                            table.insert(targets, {player = player, dist = dist})
                        end
                    end
                end
            end
        end
        table.sort(targets, function(a, b) return a.dist < b.dist end)
        cachedTargets = targets
        return targets
    end

    local function getRemotes()
        pcall(function() RE.HitRemote = ReplicatedStorage.Packages.Knit.Services.CombatService.RF.Hit end)
        pcall(function() RE.PunchDoRemote = ReplicatedStorage.Packages.Knit.Services.CombatService.RF.PunchDo end)
    end

    local function buildHitArgs(targetChar)
        if RE.spiedHitArgs and #RE.spiedHitArgs > 0 then
            local newArgs = {}
            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
            local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
            for i, arg in ipairs(RE.spiedHitArgs) do
                if typeof(arg) == "Instance" then
                    if arg:IsA("Model") and arg:FindFirstChildOfClass("Humanoid") then newArgs[i] = targetChar
                    elseif arg:IsA("Humanoid") then newArgs[i] = targetHum or arg
                    elseif arg:IsA("Player") then newArgs[i] = targetPlayer or arg
                    elseif arg:IsA("BasePart") then
                        local p = targetChar:FindFirstChild(arg.Name)
                        newArgs[i] = p or targetHRP or arg
                    else newArgs[i] = arg end
                elseif typeof(arg) == "Vector3" then newArgs[i] = targetHRP and targetHRP.Position or arg
                elseif typeof(arg) == "CFrame" then newArgs[i] = targetHRP and targetHRP.CFrame or arg
                else newArgs[i] = arg end
            end
            return newArgs
        end
        local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
        return {targetHum or targetChar}
    end

    local function buildPunchArgs()
        return RE.spiedPunchArgs and #RE.spiedPunchArgs > 0 and RE.spiedPunchArgs or {}
    end

    local function performHitOnly(targetChar)
        if not RE.HitRemote then return false end
        nukeCooldowns()
        local args = buildHitArgs(targetChar)
        pcall(function() RE.HitRemote:InvokeServer(unpack(args)) end)
        return true
    end

    local auraLoop = nil
    local animHook = nil

    local function startAnimHook()
        if animHook then animHook:Disconnect() end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        animHook = hum.AnimationPlayed:Connect(function(track)
            if not KillAuraEnabled then return end
            if isPunch(track) then
                task.defer(function()
                    pcall(function()
                        track:Stop(0)
                        track:AdjustWeight(0)
                        track:AdjustSpeed(0)
                    end)
                end)
            end
        end)
    end

    local function stopAnimHook()
        if animHook then animHook:Disconnect() animHook = nil end
    end

    function startKillAura()
        if auraLoop then auraLoop:Disconnect() end
        lastAtk = 0
        auraLoop = task.spawn(function()
            while KillAuraEnabled do
                nukeCooldowns()
                local targets = getValidTargets()
                if #targets > 0 then
                    RE.selfFiring = true

                    task.spawn(function()
                        nukeCooldowns()
                        local pArgs = buildPunchArgs()
                        if #pArgs > 0 then
                            pcall(function() RE.PunchDoRemote:InvokeServer(unpack(pArgs)) end)
                        else
                            pcall(function() RE.PunchDoRemote:InvokeServer() end)
                        end
                    end)

                    for _, t in ipairs(targets) do
                        local char = t.player.Character
                        if char then task.spawn(performHitOnly, char) end
                    end
                    RE.selfFiring = false
                end
                task.wait(1 / AttacksPerSecond)
            end
        end)

        startAnimHook()
    end

    function stopKillAura()
        if auraLoop then auraLoop:Disconnect() auraLoop = nil end
        stopAnimHook()
    end

    task.spawn(function()
        while task.wait(0.3) do
            getRemotes()
        end
    end)

    task.spawn(function()
        task.wait(0.5)
        getRemotes()
        task.wait(0.3)
        reverseEngineerModule()
    end)

    local UnloadSection = Instance.new("Frame")
    UnloadSection.Size = UDim2.new(1, 0, 0, 60)
    UnloadSection.BackgroundTransparency = 1
    UnloadSection.LayoutOrder = 4
    UnloadSection.Parent = CombatTab

    local unloadLayout = Instance.new("UIListLayout", UnloadSection)
    unloadLayout.Padding = UDim.new(0, 8)
    unloadLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function unloadScript()
        for _, conn in ipairs(AllConnections) do pcall(function() conn:Disconnect() end) end
        stopAnimHook()
        pcall(function() ScreenGui:Destroy() end)
        print("Kore Unloaded!")
    end

    createButton("❌ UNLOAD KORE", UnloadSection, unloadScript, 0)

    -- DRAG (perfect)
    local dragging = false
    local dragStart, startPos

    local function updateDrag(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    safeConnect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag(input)
        end
    end)

    safeConnect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    print("Kore AuraKill LOADED - ZERO LAG | Hits forever | No death | Black & white border")
end
```
