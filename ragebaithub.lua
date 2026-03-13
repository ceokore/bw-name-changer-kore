-- ╔══════════════════════════════════════════════════════╗
-- ║ RAGEBAIT HUB · by revix & kore ║
-- ╚══════════════════════════════════════════════════════╝
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playergui = player:WaitForChild("PlayerGui")
-- ══════════════════════════════════════════════════════
-- KILL AURA BACKEND
-- ══════════════════════════════════════════════════════
local KA = {
    enabled=false, range=9999, attacksPerSec=6000,
    hitboxSize=50, hitboxEnabled=true, hitboxVisible=false,
    HitRemote=nil, PunchDoRemote=nil,
    spiedHitArgs=nil, spyReady=false,
    selfFiring=false, hookInstalled=false, oldNamecall=nil,
    upvalueCooldowns={}, tableCooldowns={},
    auraConn=nil, lastAttackTime=0, inFlight={}, hrpCache={},
}
local TargetNamesList = {}
local FriendsNamesList = {}
local function matchesCombat(s)
    s=s:lower()
    for _,p in ipairs({"combat","attack","punch","hit","damage","fight","pvp","melee","swing","weapon","fist","strike","brawl"}) do
        if s:find(p,1,true) then return true end
    end
end
local function matchesCooldown(k)
    k=k:lower()
    for _,p in ipairs({"cooldown","debounce","canattack","lastattack","attackcd","punchcd","combatcd",
        "isattacking","canpunch","attacktimer","nextattack","attackdelay","swingcd","hitcd","attackready",
        "canswing","canhit","lastpunch","lasthit","lastswing","cd","_cd","_debounce","_cooldown",
        "ispunching","isswinging","combo","punchcount","attackcount","canfight","fighting","swinging",
        "punching","attacking","hitcount","combostep","combocount","combotimer","combodelay",
        "combocooldown","attackstate","punchstate","combatstate","state","busy","locked","active",
        "ready","available","enabled","disabled","blocked","canuse","lastuse","lasttime","timer",
        "delay","wait","interval","rate","speed","time","stamp","last"}) do
        if k==p or k:find(p,1,true) then return true end
    end
end
local function isFriend(p)
    local name = p.Name:lower()
    local display = p.DisplayName:lower()
    for _, f in ipairs(FriendsNamesList) do
        if f ~= "" and (name:find(f,1,true) or display:find(f,1,true)) then return true end
    end
    return false
end
local function isTargeted(p)
    if #TargetNamesList == 0 then return true end
    local name = p.Name:lower()
    local display = p.DisplayName:lower()
    for _, t in ipairs(TargetNamesList) do
        if t ~= "" and (name:find(t,1,true) or display:find(t,1,true)) then return true end
    end
    return false
end
local function getRemotesKA()
    pcall(function() KA.HitRemote=ReplicatedStorage.Packages.Knit.Services.CombatService.RF.Hit end)
    pcall(function() KA.PunchDoRemote=ReplicatedStorage.Packages.Knit.Services.CombatService.RF.PunchDo end)
    if not KA.HitRemote or not KA.PunchDoRemote then
        for _,v in pairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteFunction") or v:IsA("RemoteEvent") then
                local n=v.Name:lower()
                if n=="hit" and not KA.HitRemote then KA.HitRemote=v end
                if n=="punchdo" and not KA.PunchDoRemote then KA.PunchDoRemote=v end
            end
        end
    end
end
local function installSpy()
    if KA.hookInstalled then return end
    pcall(function()
        KA.oldNamecall=hookmetamethod(game,"__namecall",newcclosure(function(self,...)
            local m=getnamecallmethod()
            if not KA.selfFiring and m=="InvokeServer" and self==KA.HitRemote then KA.spiedHitArgs={...}; KA.spyReady=true end
            return KA.oldNamecall(self,...)
        end)); KA.hookInstalled=true
    end)
    if not KA.hookInstalled then
        pcall(function()
            if KA.HitRemote then
                local oi=KA.HitRemote.InvokeServer
                hookfunction(oi,newcclosure(function(self,...)
                    if not KA.selfFiring and self==KA.HitRemote then KA.spiedHitArgs={...}; KA.spyReady=true end
                    return oi(self,...)
                end)); KA.hookInstalled=true
            end
        end)
    end
end
local scannedFuncs={}
local function scanFunction(func,depth)
    if depth>8 or scannedFuncs[func] then return end; scannedFuncs[func]=true
    pcall(function()
        local uv=debug.getupvalues(func); local con={}; pcall(function() con=debug.getconstants(func) end)
        local hc=false; for _,c in pairs(con) do if typeof(c)=="string" and matchesCombat(c) then hc=true end end
        for idx,val in pairs(uv) do
            local vt=typeof(val)
            if vt=="boolean" then table.insert(KA.upvalueCooldowns,{func=func,idx=idx,valType="boolean",combat=hc})
            elseif vt=="number" then table.insert(KA.upvalueCooldowns,{func=func,idx=idx,valType="number",combat=hc})
            elseif vt=="table" then
                pcall(function() for k,v in pairs(val) do
                    if typeof(k)=="string" and matchesCooldown(k) then table.insert(KA.tableCooldowns,{tbl=val,key=k,valType=typeof(v)}) end
                end end)
            elseif vt=="function" then scanFunction(val,depth+1) end
        end
        pcall(function() for _,p in pairs(debug.getprotos(func)) do scanFunction(p,depth+1) end end)
    end)
end
local function reverseEngineerModule()
    KA.upvalueCooldowns={}; KA.tableCooldowns={}; scannedFuncs={}
    pcall(function()
        local mod=ReplicatedStorage:FindFirstChild("Controllers") and ReplicatedStorage.Controllers:FindFirstChild("CombatClient")
        if not mod then return end; local data=require(mod)
        if typeof(data)=="table" then for _,v in pairs(data) do if typeof(v)=="function" then scanFunction(v,0) end end end
    end)
    pcall(function()
        for _,obj in pairs(getgc(true)) do
            if typeof(obj)=="function" and not scannedFuncs[obj] then
                pcall(function()
                    local con=debug.getconstants(obj); local hasPD,hasHit=false,false
                    for _,c in pairs(con) do if typeof(c)=="string" then
                        local cl=c:lower()
                        if cl:find("punchdo",1,true) then hasPD=true end
                        if cl=="hit" and not cl:find("hitbox",1,true) then hasHit=true end
                    end end
                    if hasPD or hasHit then scanFunction(obj,0) end
                end)
            end
        end
    end)
end
local function nukeCooldowns()
    for _,e in ipairs(KA.upvalueCooldowns) do
        pcall(function()
            if e.valType=="boolean" then debug.setupvalue(e.func,e.idx,false)
            elseif e.valType=="number" then debug.setupvalue(e.func,e.idx,0) end
        end)
    end
    for _,e in ipairs(KA.tableCooldowns) do
        pcall(function()
            if e.valType=="number" then rawset(e.tbl,e.key,0)
            elseif e.valType=="boolean" then
                local k=e.key:lower()
                if k:find("debounce") or k:find("attacking") or k:find("punching") or k:find("swinging")
                or k:find("busy") or k:find("locked") or k:find("blocked") or k:find("disabled") then
                    rawset(e.tbl,e.key,false)
                else rawset(e.tbl,e.key,true) end
            end
        end)
    end
end
local function buildHitArgs(targetChar)
    if KA.spiedHitArgs and #KA.spiedHitArgs>0 then
        local out={}; local hrp=targetChar:FindFirstChild("HumanoidRootPart")
        local hum=targetChar:FindFirstChildOfClass("Humanoid"); local plr=Players:GetPlayerFromCharacter(targetChar)
        for i,arg in ipairs(KA.spiedHitArgs) do
            if typeof(arg)=="Instance" then
                if arg:IsA("Model") and arg:FindFirstChildOfClass("Humanoid") then out[i]=targetChar
                elseif arg:IsA("Humanoid") then out[i]=hum or arg
                elseif arg:IsA("Player") then out[i]=plr or arg
                elseif arg:IsA("BasePart") then out[i]=targetChar:FindFirstChild(arg.Name) or hrp or arg
                else out[i]=arg end
            elseif typeof(arg)=="Vector3" then out[i]=hrp and hrp.Position or arg
            elseif typeof(arg)=="CFrame" then out[i]=hrp and hrp.CFrame or arg
            else out[i]=arg end
        end
        return out
    end
    return {targetChar:FindFirstChildOfClass("Humanoid") or targetChar}
end
local function performHit(targetChar)
    if not KA.HitRemote then return end
    pcall(function()
        local args=buildHitArgs(targetChar)
        if args and #args>0 then KA.HitRemote:InvokeServer(unpack(args)) else KA.HitRemote:InvokeServer() end
    end)
end
local function updateHitbox(p,hrp)
    if not hrp or not hrp.Parent then return end
    if isFriend(p) or not KA.hitboxEnabled or not isTargeted(p) then hrp.Size=Vector3.new(2,2,1); hrp.Transparency=1; return end
    hrp.Size=Vector3.new(KA.hitboxSize,KA.hitboxSize,KA.hitboxSize)
    hrp.Transparency=KA.hitboxVisible and 0.88 or 1
    hrp.Material=KA.hitboxVisible and Enum.Material.Neon or Enum.Material.Plastic
    hrp.CanCollide=false
end
local function updateAllHitboxes() for p,hrp in pairs(KA.hrpCache) do updateHitbox(p,hrp) end end
local function cacheHRP(p)
    local function onChar(char)
        local hrp=char:WaitForChild("HumanoidRootPart",8)
        if hrp then KA.hrpCache[p]=hrp; updateHitbox(p,hrp) end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Died:Connect(function() KA.hrpCache[p]=nil end) end
    end
    if p.Character then task.spawn(onChar,p.Character) end
    p.CharacterAdded:Connect(onChar)
end
for _,p in ipairs(Players:GetPlayers()) do if p~=player then cacheHRP(p) end end
Players.PlayerAdded:Connect(function(p) if p~=player then cacheHRP(p) end end)
Players.PlayerRemoving:Connect(function(p) KA.hrpCache[p]=nil end)
local function getValidTargets()
    local myChar=player.Character; if not myChar then return {} end
    local myHRP=myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return {} end
    local myPos=myHRP.Position; local out={}
    for p,hrp in pairs(KA.hrpCache) do
        if p~=player and p.Character and hrp and hrp.Parent then
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health>0 then
                if not isFriend(p) and isTargeted(p) then
                    local dist=(hrp.Position-myPos).Magnitude
                    if dist<=KA.range then table.insert(out,{char=p.Character,dist=dist}) end
                end
            end
        end
    end
    table.sort(out,function(a,b) return a.dist<b.dist end); return out
end
local function startKillAura()
    KA.lastAttackTime=0; KA.inFlight={}
    KA.auraConn=RunService.Heartbeat:Connect(function()
        if not KA.enabled then return end
        local now=tick(); local interval=1/math.clamp(KA.attacksPerSec/150,0.1,3000)
        if now-KA.lastAttackTime<interval then return end; KA.lastAttackTime=now
        local targets=getValidTargets(); if #targets==0 then return end
        local myChar=player.Character; if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        KA.selfFiring=true; nukeCooldowns()
        for _,td in ipairs(targets) do
            local char=td.char
            if char and char:FindFirstChild("HumanoidRootPart") and not KA.inFlight[char] then
                KA.inFlight[char]=true
                task.spawn(function() performHit(char); KA.inFlight[char]=nil end)
            end
        end
        task.defer(function() KA.selfFiring=false end)
    end)
end
local function stopKillAura()
    KA.selfFiring=false; KA.inFlight={}
    if KA.auraConn then KA.auraConn:Disconnect(); KA.auraConn=nil end
end
task.spawn(function()
    task.wait(0.5); getRemotesKA(); task.wait(0.3); reverseEngineerModule(); task.wait(0.3); installSpy()
end)
task.spawn(function() while task.wait(5) do if not KA.HitRemote then getRemotesKA() end end end)
-- ══════════════════════════════════════════════════════
-- GLITCH FOLLOW BACKEND
-- ══════════════════════════════════════════════════════
local GF={enabled=false,target=nil,hum=nil,root=nil,conn=nil}
local function gfSetupChar(char)
    GF.hum=char:WaitForChild("Humanoid"); GF.root=char:WaitForChild("HumanoidRootPart")
    if GF.hum then
        GF.hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
        GF.hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
    end
end
pcall(function() gfSetupChar(player.Character or player.CharacterAdded:Wait()) end)
player.CharacterAdded:Connect(function(char) gfSetupChar(char); if GF.enabled then GF.enabled=false end end)
local function startGlitchFollow()
    GF.enabled=true
    GF.conn=RunService.RenderStepped:Connect(function()
        if not GF.enabled or not GF.target then return end
        local myChar=player.Character; local tChar=GF.target.Character
        if not myChar or not tChar then return end
        local myRoot=myChar:FindFirstChild("HumanoidRootPart"); local tRoot=tChar:FindFirstChild("HumanoidRootPart")
        if not myRoot or not tRoot then return end
        myRoot.AssemblyLinearVelocity=Vector3.zero; myRoot.AssemblyAngularVelocity=Vector3.zero
        if GF.hum then GF.hum:ChangeState(Enum.HumanoidStateType.Running) end
        for _=1,8 do
            local r=math.random(2,10)
            myRoot.CFrame=tRoot.CFrame*CFrame.new(math.random(-r,r),math.random(-2,2),math.random(-r,r))
                *CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360)))
        end
    end)
end
local function stopGlitchFollow()
    GF.enabled=false; if GF.conn then GF.conn:Disconnect(); GF.conn=nil end
end
-- ══════════════════════════════════════════════════════
-- REMOTES
-- ══════════════════════════════════════════════════════
local ColorRemote,NameRemote,BioColorRemote,isBioFunction
pcall(function()
    local R=ReplicatedStorage:WaitForChild("Remotes",3)
    if R then
        ColorRemote=R:FindFirstChild("UpdateRPColor"); NameRemote=R:FindFirstChild("UpdateRPName")
        BioColorRemote=R:FindFirstChild("UpdateBioColor")
        if BioColorRemote then isBioFunction=BioColorRemote:IsA("RemoteFunction") end
    end
end)
local function fireColorRemote(c) if ColorRemote then pcall(function() ColorRemote:FireServer(c) end) end end
local function fireBioRemote(c)
    if BioColorRemote then pcall(function()
        if isBioFunction then BioColorRemote:InvokeServer(c) else BioColorRemote:FireServer(c) end
    end) end
end
local function fireNameRemote(t) if NameRemote then pcall(function() NameRemote:FireServer(t) end) end end
-- ══════════════════════════════════════════════════════
-- PALETTE & CONSTANTS
-- ══════════════════════════════════════════════════════
local CLR = {
    bg = Color3.fromRGB(8, 8, 8),
    panel = Color3.fromRGB(14, 14, 14),
    btn = Color3.fromRGB(18, 18, 18),
    btnSel = Color3.fromRGB(26, 26, 26),
    white = Color3.new(1,1,1),
    dim = Color3.fromRGB(90, 90, 90),
    subdim = Color3.fromRGB(48, 48, 48),
    border = Color3.fromRGB(28, 28, 28),
    red = Color3.fromRGB(220,40, 40),
}
local MAIN_W, MAIN_H = 740, 330
local PL_X, PL_W = 194, 160
local INNER_H = MAIN_H - 8 -- 322
-- ContentArea positions based on whether PL is visible
local CA_X_NOPL = 194
local CA_X_WITHPL= PL_X + PL_W + 4 -- 358
local CA_W_NOPL = MAIN_W - CA_X_NOPL - 8 -- 538
local CA_W_WITHPL= MAIN_W - CA_X_WITHPL - 8 -- 374
-- ══════════════════════════════════════════════════════
-- SCREEN GUI
-- ══════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui", playergui)
gui.Name="RagebaitHub"; gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.DisplayOrder=99
-- ── Main window ──────────────────────────────────────
-- AnchorPoint=0.5,0.5 + Position center so UIScale animates from center
local Main=Instance.new("Frame",gui)
Main.Name="Main"; Main.AnchorPoint=Vector2.new(0.5,0.5)
Main.Size=UDim2.new(0,MAIN_W,0,MAIN_H); Main.Position=UDim2.new(0.5,0,0.5,0)
Main.BackgroundColor3=CLR.bg; Main.BorderSizePixel=0; Main.ClipsDescendants=false
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,10)
local MainScale=Instance.new("UIScale",Main); MainScale.Scale=0
local mainStroke=Instance.new("UIStroke",Main); mainStroke.Thickness=2
task.spawn(function()
    while Main and Main.Parent do
        mainStroke.Color=Color3.fromRGB(math.floor(((math.sin(tick()*1.2)+1)/2)*255),
                                        math.floor(((math.sin(tick()*1.2)+1)/2)*255),
                                        math.floor(((math.sin(tick()*1.2)+1)/2)*255))
        task.wait(0.03)
    end
end)
-- background image
local BG=Instance.new("ImageLabel",Main)
BG.Size=UDim2.new(1,0,1,0); BG.BackgroundTransparency=1
BG.Image="rbxassetid://116609435350470"; BG.ImageTransparency=0.82
BG.ScaleType=Enum.ScaleType.Crop; BG.ZIndex=1
Instance.new("UICorner",BG).CornerRadius=UDim.new(0,10)
-- wavy dots
do
    local N=22; local cfg,fr={},{}
    math.randomseed(os.clock()*10000)
    for i=1,N do
        local sz=math.random(3,9)
        cfg[i]={bx=math.random(20,MAIN_W-20),by=math.random(20,MAIN_H-20),
                ax=math.random(14,52),ay=math.random(14,52),
                fx=math.random(40,90)/100,fy=math.random(40,90)/100,
                px=math.random(0,628)/100,py=math.random(0,628)/100,
                sp=math.random(55,100)/100,sz=sz,al=math.random(50,80)/100}
        local d=Instance.new("Frame",Main); d.Size=UDim2.new(0,sz,0,sz)
        d.BackgroundColor3=CLR.white; d.BackgroundTransparency=cfg[i].al
        d.BorderSizePixel=0; d.ZIndex=2
        Instance.new("UICorner",d).CornerRadius=UDim.new(1,0); fr[i]=d
    end
    task.spawn(function()
        while Main and Main.Parent do
            local t=tick()
            for i=1,N do
                local c=cfg[i]
                local x=c.bx+c.ax*math.sin(t*c.sp*c.fx+c.px); local y=c.by+c.ay*math.sin(t*c.sp*c.fy+c.py)
                local pulse=((math.sin(t*c.sp*0.5+c.px)+1)/2)*0.2
                fr[i].BackgroundTransparency=math.clamp(c.al+pulse,0,0.97)
                fr[i].Position=UDim2.new(0,x-c.sz/2,0,y-c.sz/2)
            end
            task.wait(0.03)
        end
    end)
end
-- ── Sidebar ──────────────────────────────────────────
local Sidebar=Instance.new("Frame",Main)
Sidebar.Size=UDim2.new(0,186,0,INNER_H); Sidebar.Position=UDim2.new(0,4,0,4)
Sidebar.BackgroundColor3=CLR.panel; Sidebar.BackgroundTransparency=0.1
Sidebar.BorderSizePixel=0; Sidebar.ZIndex=3
Instance.new("UICorner",Sidebar).CornerRadius=UDim.new(0,8)
local sStroke=Instance.new("UIStroke",Sidebar); sStroke.Color=CLR.border; sStroke.Thickness=1
local TitleLbl=Instance.new("TextLabel",Sidebar)
TitleLbl.Size=UDim2.new(1,-14,0,26); TitleLbl.Position=UDim2.new(0,10,0,10)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="RAGEBAIT HUB"
TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=14; TitleLbl.TextColor3=CLR.white
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left; TitleLbl.ZIndex=5
local ts=Instance.new("UIStroke",TitleLbl); ts.Thickness=1; ts.Color=Color3.new(0,0,0)
local SubLbl=Instance.new("TextLabel",Sidebar)
SubLbl.Size=UDim2.new(1,-14,0,13); SubLbl.Position=UDim2.new(0,10,0,36)
SubLbl.BackgroundTransparency=1; SubLbl.Text="made with love by revix and kore"
SubLbl.Font=Enum.Font.GothamSemibold; SubLbl.TextSize=9
SubLbl.TextColor3=CLR.white; SubLbl.TextTransparency=0.55
SubLbl.TextXAlignment=Enum.TextXAlignment.Left; SubLbl.ZIndex=5
local SideDiv=Instance.new("Frame",Sidebar)
SideDiv.Size=UDim2.new(1,-20,0,1); SideDiv.Position=UDim2.new(0,10,0,56)
SideDiv.BackgroundColor3=CLR.border; SideDiv.BorderSizePixel=0; SideDiv.ZIndex=5
-- scrollable tab list
local SideScroll=Instance.new("ScrollingFrame",Sidebar)
SideScroll.Size=UDim2.new(1,0,1,-62); SideScroll.Position=UDim2.new(0,0,0,62)
SideScroll.BackgroundTransparency=1; SideScroll.ScrollBarThickness=3
SideScroll.ScrollBarImageColor3=CLR.subdim; SideScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
SideScroll.CanvasSize=UDim2.new(0,0,0,0); SideScroll.ZIndex=4; SideScroll.BorderSizePixel=0
local SideLayout=Instance.new("UIListLayout",SideScroll)
SideLayout.Padding=UDim.new(0,4); SideLayout.SortOrder=Enum.SortOrder.LayoutOrder
local SidePad=Instance.new("UIPadding",SideScroll)
SidePad.PaddingLeft=UDim.new(0,8); SidePad.PaddingRight=UDim.new(0,8)
SidePad.PaddingTop=UDim.new(0,4); SidePad.PaddingBottom=UDim.new(0,8)
-- ── Player List panel (inside Main) ──────────────────
local PLPanel=Instance.new("Frame",Main)
PLPanel.Name="PlayerList"; PLPanel.Size=UDim2.new(0,PL_W,0,INNER_H)
PLPanel.Position=UDim2.new(0,PL_X,0,4)
PLPanel.BackgroundColor3=CLR.panel; PLPanel.BackgroundTransparency=0.06
PLPanel.BorderSizePixel=0; PLPanel.ZIndex=3; PLPanel.Visible=false
Instance.new("UICorner",PLPanel).CornerRadius=UDim.new(0,8)
local plStroke=Instance.new("UIStroke",PLPanel); plStroke.Color=CLR.border; plStroke.Thickness=1
local PLHeader=Instance.new("TextLabel",PLPanel)
PLHeader.Size=UDim2.new(1,-14,0,20); PLHeader.Position=UDim2.new(0,8,0,8)
PLHeader.BackgroundTransparency=1; PLHeader.Text="PLAYERS"
PLHeader.Font=Enum.Font.GothamBold; PLHeader.TextSize=10; PLHeader.TextColor3=CLR.dim
PLHeader.TextXAlignment=Enum.TextXAlignment.Left; PLHeader.ZIndex=4
local PLDivLine=Instance.new("Frame",PLPanel)
PLDivLine.Size=UDim2.new(1,-16,0,1); PLDivLine.Position=UDim2.new(0,8,0,30)
PLDivLine.BackgroundColor3=CLR.border; PLDivLine.BorderSizePixel=0; PLDivLine.ZIndex=4
local PLScroll=Instance.new("ScrollingFrame",PLPanel)
PLScroll.Size=UDim2.new(1,0,1,-35); PLScroll.Position=UDim2.new(0,0,0,35)
PLScroll.BackgroundTransparency=1; PLScroll.ScrollBarThickness=3
PLScroll.ScrollBarImageColor3=CLR.subdim; PLScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
PLScroll.CanvasSize=UDim2.new(0,0,0,0); PLScroll.ZIndex=4; PLScroll.BorderSizePixel=0
local PLLayout=Instance.new("UIListLayout",PLScroll)
PLLayout.Padding=UDim.new(0,3); PLLayout.SortOrder=Enum.SortOrder.LayoutOrder
local PLPad=Instance.new("UIPadding",PLScroll)
PLPad.PaddingLeft=UDim.new(0,6); PLPad.PaddingRight=UDim.new(0,6)
PLPad.PaddingTop=UDim.new(0,4); PLPad.PaddingBottom=UDim.new(0,4)
-- ── Content area ─────────────────────────────────────
local ContentArea=Instance.new("Frame",Main)
ContentArea.Size=UDim2.new(0,CA_W_NOPL,0,INNER_H); ContentArea.Position=UDim2.new(0,CA_X_NOPL,0,4)
ContentArea.BackgroundColor3=CLR.panel; ContentArea.BackgroundTransparency=0.15
ContentArea.BorderSizePixel=0; ContentArea.ZIndex=3
Instance.new("UICorner",ContentArea).CornerRadius=UDim.new(0,8)
local caStroke=Instance.new("UIStroke",ContentArea); caStroke.Color=CLR.border; caStroke.Thickness=1
local ContentScroll=Instance.new("ScrollingFrame",ContentArea)
ContentScroll.Size=UDim2.new(1,0,1,0); ContentScroll.BackgroundTransparency=1
ContentScroll.ScrollBarThickness=3; ContentScroll.ScrollBarImageColor3=CLR.subdim
ContentScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; ContentScroll.CanvasSize=UDim2.new(0,0,0,0)
ContentScroll.ZIndex=4; ContentScroll.BorderSizePixel=0
local ContentLayout=Instance.new("UIListLayout",ContentScroll)
ContentLayout.Padding=UDim.new(0,6); ContentLayout.SortOrder=Enum.SortOrder.LayoutOrder
local ContentPad=Instance.new("UIPadding",ContentScroll)
ContentPad.PaddingLeft=UDim.new(0,10); ContentPad.PaddingRight=UDim.new(0,10)
ContentPad.PaddingTop=UDim.new(0,10); ContentPad.PaddingBottom=UDim.new(0,10)
-- update ContentArea layout based on PL visibility
local function updateContentLayout()
    local show=PLPanel.Visible
    TweenService:Create(ContentArea,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{
        Position=UDim2.new(0,show and CA_X_WITHPL or CA_X_NOPL,0,4),
        Size=UDim2.new(0,show and CA_W_WITHPL or CA_W_NOPL,0,INNER_H),
    }):Play()
end
-- ── Minimize button ───────────────────────────────────
local MiniBtn=Instance.new("TextButton",Main)
MiniBtn.Size=UDim2.new(0,24,0,15); MiniBtn.Position=UDim2.new(1,-28,0,8)
MiniBtn.BackgroundColor3=CLR.btn; MiniBtn.Font=Enum.Font.GothamBold
MiniBtn.Text="—"; MiniBtn.TextSize=11; MiniBtn.TextColor3=CLR.dim
MiniBtn.ZIndex=12; MiniBtn.AutoButtonColor=false
Instance.new("UICorner",MiniBtn).CornerRadius=UDim.new(0,4)
MiniBtn.MouseEnter:Connect(function() MiniBtn.TextColor3=CLR.white end)
MiniBtn.MouseLeave:Connect(function() MiniBtn.TextColor3=CLR.dim end)
-- ── Open / restore button ─────────────────────────────
local OpenFrame=Instance.new("Frame",gui)
OpenFrame.Size=UDim2.new(0,200,0,52); OpenFrame.Position=UDim2.new(0,10,1,-64)
OpenFrame.BackgroundColor3=Color3.fromRGB(8,8,8); OpenFrame.BorderSizePixel=0
OpenFrame.Visible=false; OpenFrame.ZIndex=20
Instance.new("UICorner",OpenFrame).CornerRadius=UDim.new(0,8)
local openStroke=Instance.new("UIStroke",OpenFrame); openStroke.Color=CLR.subdim; openStroke.Thickness=1
task.spawn(function()
    while OpenFrame and OpenFrame.Parent do
        if OpenFrame.Visible then
            local v=math.floor(((math.sin(tick()*1.2)+1)/2)*150)
            openStroke.Color=Color3.fromRGB(v,v,v)
        end
        task.wait(0.04)
    end
end)
local OpenTitle=Instance.new("TextLabel",OpenFrame)
OpenTitle.Size=UDim2.new(1,-12,0,18); OpenTitle.Position=UDim2.new(0,10,0,8)
OpenTitle.BackgroundTransparency=1; OpenTitle.Text="RAGEBAIT HUB"
OpenTitle.Font=Enum.Font.GothamBold; OpenTitle.TextSize=13
OpenTitle.TextColor3=CLR.white; OpenTitle.TextXAlignment=Enum.TextXAlignment.Left; OpenTitle.ZIndex=21
local OpenSub=Instance.new("TextLabel",OpenFrame)
OpenSub.Size=UDim2.new(1,-12,0,12); OpenSub.Position=UDim2.new(0,10,0,28)
OpenSub.BackgroundTransparency=1; OpenSub.Text="click to restore"
OpenSub.Font=Enum.Font.Gotham; OpenSub.TextSize=10
OpenSub.TextColor3=CLR.dim; OpenSub.TextXAlignment=Enum.TextXAlignment.Left; OpenSub.ZIndex=21
local OpenHit=Instance.new("TextButton",OpenFrame)
OpenHit.Size=UDim2.new(1,0,1,0); OpenHit.BackgroundTransparency=1; OpenHit.Text=""; OpenHit.ZIndex=22
-- ══════════════════════════════════════════════════════
-- OPEN / CLOSE ANIMATIONS
-- ══════════════════════════════════════════════════════
local function openMainAnim()
    Main.Visible=true; MainScale.Scale=0
    TweenService:Create(MainScale,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
end
local function closeMainAnim(cb)
    TweenService:Create(MainScale,TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=0}):Play()
    task.delay(0.17,function()
        Main.Visible=false; if cb then cb() end
    end)
end
MiniBtn.MouseButton1Click:Connect(function()
    closeMainAnim(function()
        PLPanel.Visible=false; updateContentLayout(); OpenFrame.Visible=true
    end)
end)
OpenHit.MouseButton1Click:Connect(function()
    OpenFrame.Visible=false; openMainAnim()
end)
-- Insert key
UIS.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.Insert then
        if Main.Visible then
            closeMainAnim(function() PLPanel.Visible=false; updateContentLayout() end)
        else
            openMainAnim()
        end
    end
end)
-- ══════════════════════════════════════════════════════
-- DRAG (sidebar header; sliderActive blocks it)
-- ══════════════════════════════════════════════════════
local sliderActive=false
local dragging,dragStart,dragBasePos=false,nil,nil
Sidebar.InputBegan:Connect(function(input)
    if sliderActive then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=input.Position; dragBasePos=Main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and not sliderActive and input.UserInputType==Enum.UserInputType.MouseMovement then
        local d=input.Position-dragStart
        Main.Position=UDim2.new(dragBasePos.X.Scale,dragBasePos.X.Offset+d.X,
                                 dragBasePos.Y.Scale,dragBasePos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
-- ══════════════════════════════════════════════════════
-- WIDGET HELPERS
-- ══════════════════════════════════════════════════════
local function makeStatusLabel(text,parent)
    local l=Instance.new("TextLabel",parent); l.Size=UDim2.new(1,0,0,15); l.BackgroundTransparency=1
    l.Text=text; l.Font=Enum.Font.Gotham; l.TextSize=11; l.TextColor3=CLR.dim
    l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=5; return l
end
local function makeSectionHeader(text,parent,order)
    local f=Instance.new("Frame",parent); f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1
    f.LayoutOrder=order; f.ZIndex=5
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=text:upper(); l.Font=Enum.Font.GothamBold; l.TextSize=11; l.TextColor3=CLR.dim
    l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=6; return f
end
local function makeToggleRow(text,parent,order,callback)
    local row=Instance.new("Frame",parent); row.Size=UDim2.new(1,0,0,34)
    row.BackgroundColor3=CLR.btn; row.BackgroundTransparency=0.1; row.BorderSizePixel=0
    row.LayoutOrder=order; row.ZIndex=5
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-50,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=13
    lbl.TextColor3=CLR.white; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local track=Instance.new("Frame",row); track.Size=UDim2.new(0,36,0,18); track.Position=UDim2.new(1,-46,0.5,-9)
    track.BackgroundColor3=Color3.fromRGB(32,32,32); track.BorderSizePixel=0; track.ZIndex=6
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local thumb=Instance.new("Frame",track); thumb.Size=UDim2.new(0,14,0,14); thumb.Position=UDim2.new(0,2,0.5,-7)
    thumb.BackgroundColor3=CLR.dim; thumb.BorderSizePixel=0; thumb.ZIndex=7
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local on=false
    local function set(state)
        on=state
        track.BackgroundColor3=on and CLR.white or Color3.fromRGB(32,32,32)
        thumb.BackgroundColor3=on and Color3.fromRGB(0,0,0) or CLR.dim
        TweenService:Create(thumb,TweenInfo.new(0.12,Enum.EasingStyle.Quad),{
            Position=on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
        }):Play()
        if callback then callback(on) end
    end
    local hit=Instance.new("TextButton",row); hit.Size=UDim2.new(1,0,1,0)
    hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=8
    hit.MouseButton1Click:Connect(function() set(not on) end)
    return set
end
local function makeTextBox(placeholder,parent,order)
    local f=Instance.new("Frame",parent); f.Size=UDim2.new(1,0,0,34)
    f.BackgroundColor3=CLR.btn; f.BackgroundTransparency=0.05; f.BorderSizePixel=0
    f.LayoutOrder=order; f.ZIndex=5
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local tb=Instance.new("TextBox",f); tb.Size=UDim2.new(1,-16,1,-8); tb.Position=UDim2.new(0,8,0,4)
    tb.BackgroundTransparency=1; tb.TextColor3=CLR.white; tb.PlaceholderColor3=CLR.dim
    tb.Font=Enum.Font.Gotham; tb.TextSize=13; tb.Text=""; tb.PlaceholderText=placeholder
    tb.ClearTextOnFocus=false; tb.ZIndex=6; return tb
end
local function makeSliderDrag(bar,cursor,onChanged)
    local held=false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            held=true; sliderActive=true
            local rel=math.clamp((UIS:GetMouseLocation().X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            cursor.Position=UDim2.new(rel,-2,0,0); onChanged(rel)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then held=false; sliderActive=false end
    end)
    UIS.InputChanged:Connect(function(input)
        if held and input.UserInputType==Enum.UserInputType.MouseMovement then
            local rel=math.clamp((UIS:GetMouseLocation().X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            cursor.Position=UDim2.new(rel,-2,0,0); onChanged(rel)
        end
    end)
end
-- ══════════════════════════════════════════════════════
-- SIDEBAR TAB FACTORY
-- ══════════════════════════════════════════════════════
local currentTabBtn=nil
local function makeSideBtn(label,order)
    local btn=Instance.new("TextButton",SideScroll); btn.Size=UDim2.new(1,0,0,30)
    btn.BackgroundColor3=CLR.btn; btn.Font=Enum.Font.GothamSemibold; btn.Text=label; btn.TextSize=12
    btn.TextColor3=CLR.dim; btn.TextXAlignment=Enum.TextXAlignment.Left
    btn.AutoButtonColor=false; btn.LayoutOrder=order; btn.ZIndex=5
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    local pad=Instance.new("UIPadding",btn); pad.PaddingLeft=UDim.new(0,10)
    return btn
end
local function setSideActive(btn)
    if currentTabBtn then currentTabBtn.TextColor3=CLR.dim; currentTabBtn.BackgroundColor3=CLR.btn end
    currentTabBtn=btn
    if btn then btn.TextColor3=CLR.white; btn.BackgroundColor3=CLR.btnSel end
end
-- ══════════════════════════════════════════════════════
-- PAGE SYSTEM
-- ══════════════════════════════════════════════════════
local pages={}
local function showPage(name) for k,v in pairs(pages) do v.Visible=(k==name) end end
local function makePage()
    local f=Instance.new("Frame",ContentScroll); f.Size=UDim2.new(1,0,0,0)
    f.AutomaticSize=Enum.AutomaticSize.Y; f.BackgroundTransparency=1
    f.LayoutOrder=1; f.ZIndex=5; f.Visible=false
    local l=Instance.new("UIListLayout",f); l.Padding=UDim.new(0,6); l.SortOrder=Enum.SortOrder.LayoutOrder
    return f
end
-- ══════════════════════════════════════════════════════
-- FEATURE STATE
-- ══════════════════════════════════════════════════════
local currentFeature=nil
local flying=false; local flyBV,flyBG,flyConn=nil,nil,nil
local tpwalking=false
local aimLocking=false; local aimlockTarget,aimlockConn,aimlockHL=nil,nil,nil
local mouseUnlocked=false; local muConn=nil
local colorRunning=false; local colorConn=nil
-- color state
local pickedH,pickedS,pickedV=0,1,1
local colorCycleSpeed=4; local colorTime=0; local colorCharCount=1
local colorWord=player.DisplayName or player.Name
local storedRPName=colorWord
local lastNameUpd,lastBioUpd=0,0; local nameFreq,bioFreq=0.08,0.08
local colorPreset="custom" -- "custom","bw","pink","galaxy","gold","purpleyellow"
local colorPresetTime=0; local galaxyGradRot=0
local bounceForward=true
-- super spin state
local spinning=false; local spinConn=nil
-- refs
local flyAmountRef,tpwAmountRef,rpNameRef,spinSpeedRef=nil,nil,nil,nil
local gfToggleFn=nil
-- ── feature stop/start ───────────────────────────────
local function stopAimlock()
    aimLocking=false
    if aimlockConn then aimlockConn:Disconnect(); aimlockConn=nil end
    if aimlockHL then aimlockHL:Destroy(); aimlockHL=nil end
    aimlockTarget=nil
end
local function startAimlock(tp)
    if aimLocking and aimlockTarget==tp then stopAimlock(); return end; stopAimlock()
    local char=tp.Character; if not char then return end
    aimLocking=true; aimlockTarget=tp
    aimlockHL=Instance.new("Highlight"); aimlockHL.FillColor=CLR.red
    aimlockHL.OutlineColor=CLR.white; aimlockHL.FillTransparency=0.5; aimlockHL.Parent=char
    aimlockConn=RunService.RenderStepped:Connect(function()
        local tc=aimlockTarget and aimlockTarget.Character
        if not tc or not tc:FindFirstChild("HumanoidRootPart") then stopAimlock(); return end
        workspace.CurrentCamera.CFrame=CFrame.new(workspace.CurrentCamera.CFrame.Position,tc.HumanoidRootPart.Position)
    end)
end
Players.PlayerRemoving:Connect(function(p) if aimlockTarget==p then stopAimlock() end end)
local function stopFly()
    flying=false
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
    if flyConn then flyConn:Disconnect(); flyConn=nil end
end
local function startFly()
    local speed=(flyAmountRef and tonumber(flyAmountRef.Text)) or 70
    local char=player.Character or player.CharacterAdded:Wait()
    local root=char:WaitForChild("HumanoidRootPart"); flying=true
    flyBV=Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1,1,1)*1e5; flyBV.Parent=root
    flyBG=Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(1,1,1)*1e5; flyBG.CFrame=root.CFrame; flyBG.Parent=root
    flyConn=RunService.RenderStepped:Connect(function()
        if flying and root and root.Parent then
            flyBV.Velocity=workspace.CurrentCamera.CFrame.LookVector*((flyAmountRef and tonumber(flyAmountRef.Text)) or speed)
            flyBG.CFrame=workspace.CurrentCamera.CFrame
        end
    end)
end
player.CharacterAdded:Connect(function() if flying then stopFly() end end)
local function stopTpWalk() tpwalking=false end
local function startTpWalk()
    tpwalking=true; local char=player.Character
    local hum=char and char:FindFirstChildWhichIsA("Humanoid"); if not hum then tpwalking=false; return end
    task.spawn(function()
        while tpwalking and char and hum and hum.Parent do
            local dt=RunService.Heartbeat:Wait()
            if hum.MoveDirection.Magnitude>0 then
                pcall(function() char:TranslateBy(hum.MoveDirection*((tpwAmountRef and tonumber(tpwAmountRef.Text)) or 4)*dt*10) end)
            end
            if not player.Character or player.Character~=char then tpwalking=false end
        end
    end)
end
player.CharacterAdded:Connect(function() if tpwalking then stopTpWalk() end end)
local function stopMouseUnlock()
    mouseUnlocked=false; if muConn then muConn:Disconnect(); muConn=nil end
end
local function startMouseUnlock()
    mouseUnlocked=true
    muConn=RunService.RenderStepped:Connect(function() UIS.MouseBehavior=Enum.MouseBehavior.Default end)
end
local function stopColor()
    colorRunning=false; if colorConn then colorConn:Disconnect(); colorConn=nil end
end
local function startColor()
    colorRunning=true; colorTime=0; colorPresetTime=0; galaxyGradRot=0
    colorCharCount=1; bounceForward=true; lastNameUpd=0; lastBioUpd=0
    colorWord = storedRPName
    colorConn=RunService.Heartbeat:Connect(function(dt)
        colorPresetTime+=dt
        local col
        if colorPreset=="bw" then
            col=Color3.new(0,0,0):Lerp(Color3.new(1,1,1),(math.sin(colorPresetTime*4)+1)/2)
        elseif colorPreset=="pink" then
            col=Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(255,60,160),(math.sin(colorPresetTime*1.2)+1)/2)
        elseif colorPreset=="galaxy" then
            local GC={Color3.fromRGB(120,0,180),Color3.fromRGB(0,0,120),Color3.fromRGB(255,130,200)}
            local a=(math.sin(colorPresetTime*2)+1)/2
            if a<0.33 then col=GC[1]:Lerp(GC[2],a/0.33)
            elseif a<0.66 then col=GC[2]:Lerp(GC[3],(a-0.33)/0.33)
            else col=GC[3]:Lerp(GC[1],(a-0.66)/0.34) end
        elseif colorPreset=="gold" then
            col=Color3.fromRGB(212,175,55):Lerp(Color3.fromRGB(255,255,255),(math.sin(colorPresetTime*3)+1)/2)
        elseif colorPreset=="purpleyellow" then
            galaxyGradRot+=45*dt
            col=Color3.fromRGB(60,0,90):Lerp(Color3.fromRGB(170,140,0),(math.sin(math.rad(galaxyGradRot))+1)/2)
        else -- custom
            colorTime+=dt*colorCycleSpeed
            col=Color3.fromHSV((pickedH+colorTime*0.1)%1,pickedS,pickedV)
        end
        fireColorRemote(col)
        lastBioUpd+=dt; if lastBioUpd>=bioFreq then lastBioUpd=0; fireBioRemote(col) end
        lastNameUpd+=dt
        if lastNameUpd>=nameFreq then
            lastNameUpd=0
            -- galaxy uses bounce typing; others use standard cycle
            local text
            if colorPreset=="galaxy" then
                text=string.sub(colorWord,1,colorCharCount)
                if bounceForward then colorCharCount+=1; if colorCharCount>#colorWord then bounceForward=false; colorCharCount=#colorWord end
                else colorCharCount-=1; if colorCharCount<1 then bounceForward=true; colorCharCount=1 end end
            else
                text=string.sub(colorWord,1,colorCharCount)
                colorCharCount = colorCharCount + 1
                    if colorCharCount > #colorWord then
                    colorCharCount = 1
                end
            end
            fireNameRemote(text)
        end
    end)
end
local function stopSpin()
    spinning=false; if spinConn then spinConn:Disconnect(); spinConn=nil end
end
local function startSpin()
    spinning=true
    spinConn=RunService.Heartbeat:Connect(function(dt)
        if not spinning then return end
        local char=player.Character; if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local s=(spinSpeedRef and tonumber(spinSpeedRef.Text)) or 360
        hrp.CFrame=hrp.CFrame*CFrame.Angles(0,math.rad(s*dt),0)
    end)
end
player.CharacterAdded:Connect(function() if spinning then stopSpin() end end)
local function stopAllFeatures()
    stopAimlock(); stopFly(); stopTpWalk(); stopMouseUnlock(); stopColor(); stopGlitchFollow(); stopSpin()
end
-- ══════════════════════════════════════════════════════
-- BUILD PAGES
-- ══════════════════════════════════════════════════════
---- TP ------------------------------------------------
local tpPage=makePage(); pages["TP"]=tpPage
makeSectionHeader("TELEPORT TO PLAYER",tpPage,0)
makeStatusLabel("select a player from the list",tpPage).LayoutOrder=1
---- AIMLOCK -------------------------------------------
local alPage=makePage(); pages["Aimlock"]=alPage
makeSectionHeader("AIMLOCK",alPage,0)
makeStatusLabel("select a player from the list",alPage).LayoutOrder=1
---- FLY -----------------------------------------------
local flyPage=makePage(); pages["Fly"]=flyPage
makeSectionHeader("FLY",flyPage,0)
makeStatusLabel("speed (default 70) · E key toggles",flyPage).LayoutOrder=1
flyAmountRef=makeTextBox("fly speed...",flyPage,2)
local flyToggleFn; flyToggleFn=makeToggleRow("fly enabled",flyPage,3,function(s)
    if s then startFly() else stopFly() end
end)
UIS.InputBegan:Connect(function(input,gpe)
    if gpe or currentFeature~="Fly" then return end
    if input.KeyCode==Enum.KeyCode.E then
        if flying then stopFly(); flyToggleFn(false) else startFly(); flyToggleFn(true) end
    end
end)
---- TPWALK --------------------------------------------
local tpwPage=makePage(); pages["TpWalk"]=tpwPage
makeSectionHeader("TELEPORT WALK",tpwPage,0)
makeStatusLabel("speed multiplier (default 4)",tpwPage).LayoutOrder=1
tpwAmountRef=makeTextBox("speed...",tpwPage,2)
makeToggleRow("tpwalk enabled",tpwPage,3,function(s)
    if s then startTpWalk() else stopTpWalk() end
end)
---- MOUSE UNLOCK --------------------------------------
local muPage=makePage(); pages["MouseUnlock"]=muPage
makeSectionHeader("MOUSE UNLOCK",muPage,0)
makeStatusLabel("frees cursor during gameplay",muPage).LayoutOrder=1
makeToggleRow("mouse unlock enabled",muPage,2,function(s)
    if s then startMouseUnlock() else stopMouseUnlock() end
end)
---- COLOR ---------------------------------------------
local colPage=makePage(); pages["Color"]=colPage
makeSectionHeader("RP COLOR CYCLER",colPage,0)
-- Preset row builder
local function makeColorBar(labelText,parent,order)
    local wrap=Instance.new("Frame",parent); wrap.Size=UDim2.new(1,0,0,44)
    wrap.BackgroundTransparency=1; wrap.LayoutOrder=order; wrap.ZIndex=5
    local lbl=Instance.new("TextLabel",wrap); lbl.Size=UDim2.new(1,0,0,16); lbl.BackgroundTransparency=1
    lbl.Text=labelText; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=CLR.dim
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local bar=Instance.new("Frame",wrap); bar.Size=UDim2.new(1,0,0,18); bar.Position=UDim2.new(0,0,0,22)
    bar.BackgroundColor3=Color3.fromRGB(28,28,28); bar.BorderSizePixel=0; bar.ZIndex=6; bar.ClipsDescendants=true
    Instance.new("UICorner",bar).CornerRadius=UDim.new(0,4)
    local cur=Instance.new("Frame",bar); cur.Size=UDim2.new(0,4,1,0)
    cur.BackgroundColor3=CLR.white; cur.BorderSizePixel=0; cur.ZIndex=7
    return bar,cur
end
-- COLOR PRESETS section
do
    local presetSection=Instance.new("Frame",colPage)
    presetSection.Size=UDim2.new(1,0,0,70); presetSection.BackgroundTransparency=1
    presetSection.LayoutOrder=1; presetSection.ZIndex=5
    local presetLbl=Instance.new("TextLabel",presetSection)
    presetLbl.Size=UDim2.new(1,0,0,16); presetLbl.BackgroundTransparency=1
    presetLbl.Text="COLOR PRESET"; presetLbl.Font=Enum.Font.GothamBold; presetLbl.TextSize=11
    presetLbl.TextColor3=CLR.dim; presetLbl.TextXAlignment=Enum.TextXAlignment.Left; presetLbl.ZIndex=6
    local presetGrid=Instance.new("Frame",presetSection)
    presetGrid.Size=UDim2.new(1,0,0,50); presetGrid.Position=UDim2.new(0,0,0,18)
    presetGrid.BackgroundTransparency=1; presetGrid.ZIndex=5
    local gridLayout=Instance.new("UIGridLayout",presetGrid)
    gridLayout.CellSize=UDim2.new(0,80,0,22); gridLayout.CellPadding=UDim2.new(0,4,0,4)
    gridLayout.SortOrder=Enum.SortOrder.LayoutOrder
    local PRESETS={
        {key="custom", label="CUSTOM", accent=Color3.fromRGB(90,90,90)},
        {key="bw", label="B · W", accent=Color3.fromRGB(180,180,180)},
        {key="pink", label="PINK", accent=Color3.fromRGB(255,60,160)},
        {key="galaxy", label="GALAXY", accent=Color3.fromRGB(120,0,180)},
        {key="gold", label="GOLD", accent=Color3.fromRGB(212,175,55)},
        {key="purpleyellow",label="P·Y",accent=Color3.fromRGB(140,100,20)},
    }
    local presetBtns={}
    local function setPresetActive(key)
        colorPreset=key
        for k,b in pairs(presetBtns) do
            b.BackgroundColor3 = (k==key) and Color3.fromRGB(30,30,30) or CLR.btn
            b.TextColor3 = (k==key) and CLR.white or CLR.dim
            if k==key then
                local stroke=b:FindFirstChildOfClass("UIStroke")
                local pr=nil; for _,p in ipairs(PRESETS) do if p.key==k then pr=p; break end end
                if stroke and pr then stroke.Color=pr.accent end
            else
                local stroke=b:FindFirstChildOfClass("UIStroke"); if stroke then stroke.Color=CLR.border end
            end
        end
    end
    for i,pr in ipairs(PRESETS) do
        local btn=Instance.new("TextButton",presetGrid)
        btn.Size=UDim2.new(0,80,0,22); btn.BackgroundColor3=CLR.btn
        btn.Font=Enum.Font.GothamBold; btn.Text=pr.label; btn.TextSize=10
        btn.TextColor3=CLR.dim; btn.AutoButtonColor=false; btn.LayoutOrder=i; btn.ZIndex=6
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
        local st=Instance.new("UIStroke",btn); st.Color=CLR.border; st.Thickness=1
        presetBtns[pr.key]=btn
        btn.MouseButton1Click:Connect(function()
            setPresetActive(pr.key)
        end)
    end
    setPresetActive("custom") -- default
end
-- CUSTOM sliders
local sliderDivLbl=makeStatusLabel("─── custom sliders (active when CUSTOM preset) ───",colPage); sliderDivLbl.LayoutOrder=2
local hueBar,hueCur=makeColorBar("HUE",colPage,3)
Instance.new("UIGradient",hueBar).Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1,1)),
    ColorSequenceKeypoint.new(0.17,Color3.fromHSV(0.17,1,1)),
    ColorSequenceKeypoint.new(0.33,Color3.fromHSV(0.33,1,1)),
    ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1,1)),
    ColorSequenceKeypoint.new(0.67,Color3.fromHSV(0.67,1,1)),
    ColorSequenceKeypoint.new(0.83,Color3.fromHSV(0.83,1,1)),
    ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1,1)),
})
local satBar,satCur=makeColorBar("SATURATION",colPage,4); local SatGrad=Instance.new("UIGradient",satBar)
local briBar,briCur=makeColorBar("BRIGHTNESS", colPage,5); local BriGrad=Instance.new("UIGradient",briBar)
local spdBar,spdCur=makeColorBar("CYCLE SPEED",colPage,6)
spdBar.BackgroundColor3=Color3.fromRGB(28,28,28)
local spdFill=Instance.new("Frame",spdBar); spdFill.Size=UDim2.new(0.2,0,1,0)
spdFill.BackgroundColor3=CLR.white; spdFill.BorderSizePixel=0; spdFill.ZIndex=6
local spdValLbl=makeStatusLabel("speed: 4",colPage); spdValLbl.LayoutOrder=7
local function updateGradients()
    SatGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(pickedH,0,pickedV)),ColorSequenceKeypoint.new(1,Color3.fromHSV(pickedH,1,pickedV))})
    BriGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0,0,0)),ColorSequenceKeypoint.new(1,Color3.fromHSV(pickedH,pickedS,1))})
end
updateGradients()
makeSliderDrag(hueBar,hueCur,function(r) pickedH=r; updateGradients() end)
makeSliderDrag(satBar,satCur,function(r) pickedS=r; updateGradients() end)
makeSliderDrag(briBar,briCur,function(r) pickedV=r; updateGradients() end)
makeSliderDrag(spdBar,spdCur,function(r)
    colorCycleSpeed=math.max(0.1,r*20); spdFill.Size=UDim2.new(r,0,1,0)
    spdValLbl.Text="speed: "..math.floor(colorCycleSpeed*10)/10
end)
makeStatusLabel("rp name",colPage).LayoutOrder=8
rpNameRef=makeTextBox("enter rp name...",colPage,9)
pcall(function() rpNameRef.Text=player.DisplayName or player.Name end)
rpNameRef.FocusLost:Connect(function()
    if rpNameRef.Text ~= "" then
        storedRPName = rpNameRef.Text
    else
        storedRPName = player.DisplayName or player.Name
    end
end)
makeToggleRow("color cycle enabled",colPage,10,function(s)
    if s then startColor() else stopColor() end
end)
---- KILL AURA -----------------------------------------
local kaPage=makePage(); pages["KillAura"]=kaPage
makeSectionHeader("KILL AURA",kaPage,0)
makeStatusLabel("range: max · aps: 6000 · hitbox: 50 · fully automatic",kaPage).LayoutOrder=1
local kaLbl=makeStatusLabel("status: off",kaPage); kaLbl.LayoutOrder=2
makeToggleRow("kill aura enabled",kaPage,3,function(s)
    KA.enabled=s; kaLbl.Text=s and "status: \u{1F7E2} active — destroying all in range" or "status: off"
    if s then KA.hitboxEnabled=true; KA.hitboxSize=50; updateAllHitboxes(); startKillAura()
    else stopKillAura(); KA.hitboxEnabled=false; KA.hitboxSize=10; updateAllHitboxes() end
end)
makeToggleRow("force rescan remotes + module",kaPage,4,function(s)
    if not s then return end
    task.spawn(function()
        KA.HitRemote=nil; KA.hookInstalled=false; KA.spyReady=false
        getRemotesKA(); installSpy(); reverseEngineerModule()
    end)
end)
makeStatusLabel("cooldown nuke + hitbox expansion always at maximum",kaPage).LayoutOrder=5
makeSectionHeader("TARGETS (BLANK = ALL)",kaPage,6)
local tLbl=makeStatusLabel("active targets: all",kaPage)
tLbl.LayoutOrder=7
local targetTB=makeTextBox("player1 player2 ...",kaPage,8)
targetTB.FocusLost:Connect(function()
    TargetNamesList={}
    for n in targetTB.Text:gmatch("%S+") do table.insert(TargetNamesList,n:lower()) end
    tLbl.Text=#TargetNamesList==0 and "active targets: all" or "active targets: "..#TargetNamesList
    updateAllHitboxes()
end)
makeSectionHeader("FRIENDS (NEVER HIT)",kaPage,9)
local fLbl=makeStatusLabel("protected: 0",kaPage)
fLbl.LayoutOrder=10
local friendTB=makeTextBox("friend1 friend2 ...",kaPage,11)
friendTB.FocusLost:Connect(function()
    FriendsNamesList={}
    for n in friendTB.Text:gmatch("%S+") do table.insert(FriendsNamesList,n:lower()) end
    fLbl.Text="protected: "..#FriendsNamesList
    updateAllHitboxes()
end)
---- GLITCH FOLLOW -------------------------------------
local gfPage=makePage(); pages["GlitchFollow"]=gfPage
makeSectionHeader("GLITCH FOLLOW",gfPage,0)
makeStatusLabel("select target from player list · J key = emergency stop",gfPage).LayoutOrder=1
makeStatusLabel("teleports 8× per frame with random spin offsets",gfPage).LayoutOrder=2
local gfLbl=makeStatusLabel("status: off · target: none",gfPage); gfLbl.LayoutOrder=3
local function updateGFStatus()
    gfLbl.Text=GF.enabled and ("\u{1F7E2} active · target: "..(GF.target and GF.target.Name or "none"))
                           or ("status: off · target: "..(GF.target and GF.target.Name or "none"))
end
gfToggleFn=makeToggleRow("glitch follow enabled",gfPage,4,function(s)
    if s then
        if not GF.target then task.defer(function() gfToggleFn(false) end); gfLbl.Text="⚠ select a player first"; return end
        startGlitchFollow()
    else stopGlitchFollow() end; updateGFStatus()
end)
makeStatusLabel("ragdoll + fall detection bypassed automatically",gfPage).LayoutOrder=5
---- SUPER SPIN ----------------------------------------
local ssPage=makePage(); pages["SuperSpin"]=ssPage
makeSectionHeader("SUPER SPIN",ssPage,0)
makeStatusLabel("spins your character at the specified speed",ssPage).LayoutOrder=1
makeStatusLabel("degrees per second · default: 360",ssPage).LayoutOrder=2
spinSpeedRef=makeTextBox("spin speed (default 360)...",ssPage,3)
makeToggleRow("super spin enabled",ssPage,4,function(s)
    if s then startSpin() else stopSpin() end
end)
makeStatusLabel("works best at 720+ for max chaos",ssPage).LayoutOrder=5
-- ══════════════════════════════════════════════════════
-- SIDEBAR WIRING
-- ══════════════════════════════════════════════════════
local FEATURES={
    {label="TP", key="TP", needsPL=true, order=1},
    {label="AIMLOCK", key="Aimlock", needsPL=true, order=2},
    {label="FLY", key="Fly", needsPL=false, order=3},
    {label="TPWALK", key="TpWalk", needsPL=false, order=4},
    {label="MOUSE UNLOCK", key="MouseUnlock", needsPL=false, order=5},
    {label="COLOR", key="Color", needsPL=false, order=6},
    {label="KILL AURA", key="KillAura", needsPL=false, order=7},
    {label="GLITCH FOLLOW",key="GlitchFollow", needsPL=true, order=8},
    {label="SUPER SPIN", key="SuperSpin", needsPL=false, order=9},
}
local sideBtns={}
local function needsPLFor(key)
    for _,d in ipairs(FEATURES) do if d.key==key then return d.needsPL end end; return false
end
for _,def in ipairs(FEATURES) do
    local btn=makeSideBtn(def.label,def.order); sideBtns[def.key]=btn
    btn.MouseButton1Click:Connect(function()
        if currentFeature==def.key then
            currentFeature=nil
            PLPanel.Visible=false; updateContentLayout()
            setSideActive(nil); for _,v in pairs(pages) do v.Visible=false end
        else
            currentFeature=def.key; showPage(def.key)
            PLPanel.Visible=def.needsPL; updateContentLayout()
            setSideActive(btn)
        end
    end)
end
-- ══════════════════════════════════════════════════════
-- PLAYER LIST
-- ══════════════════════════════════════════════════════
local playerBtns={}; local selPLBtn=nil
local function setPLSelected(btn)
    if selPLBtn then selPLBtn.BackgroundColor3=CLR.btn; selPLBtn.TextColor3=CLR.white end
    selPLBtn=btn; if btn then btn.BackgroundColor3=Color3.fromRGB(30,30,30) end
end
local function makePLBtn(targetPlayer)
    local btn=Instance.new("TextButton",PLScroll); btn.Size=UDim2.new(1,0,0,28)
    btn.BackgroundColor3=CLR.btn; btn.Font=Enum.Font.GothamSemibold; btn.Text=targetPlayer.Name; btn.TextSize=12
    btn.TextColor3=CLR.white; btn.AutoButtonColor=false; btn.ZIndex=5
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    btn.MouseButton1Click:Connect(function()
        setPLSelected(btn)
        if currentFeature=="TP" then
            local myChar=player.Character; local tChar=targetPlayer.Character
            if myChar and tChar then
                local myR=myChar:FindFirstChild("HumanoidRootPart"); local tR=tChar:FindFirstChild("HumanoidRootPart")
                if myR and tR then myR.CFrame=tR.CFrame+Vector3.new(2,0,0) end
            end
        elseif currentFeature=="Aimlock" then
            startAimlock(targetPlayer)
        elseif currentFeature=="GlitchFollow" then
            GF.target=targetPlayer; updateGFStatus()
            if GF.enabled then stopGlitchFollow(); startGlitchFollow() end
        end
    end)
    return btn
end
local function rebuildPlayerList()
    for _,b in pairs(playerBtns) do if b and b.Parent then b:Destroy() end end
    playerBtns={}; selPLBtn=nil
    for _,p in pairs(Players:GetPlayers()) do
        if p~=player then playerBtns[p]=makePLBtn(p) end
    end
end
rebuildPlayerList()
Players.PlayerAdded:Connect(function(p) if p~=player then playerBtns[p]=makePLBtn(p) end end)
Players.PlayerRemoving:Connect(function(p)
    if playerBtns[p] then playerBtns[p]:Destroy(); playerBtns[p]=nil end
    if GF.target==p then
        stopGlitchFollow(); GF.target=nil; updateGFStatus()
        task.defer(function() if gfToggleFn then gfToggleFn(false) end end)
    end
end)
-- J key emergency stop
UIS.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.J and GF.enabled then
        stopGlitchFollow()
        task.defer(function() if gfToggleFn then gfToggleFn(false) end end)
        updateGFStatus()
    end
end)
-- ══════════════════════════════════════════════════════
-- INITIAL STATE + SPAWN ANIMATION
-- ══════════════════════════════════════════════════════
showPage("TP"); setSideActive(sideBtns["TP"]); currentFeature="TP"
PLPanel.Visible=true; updateContentLayout()
-- play opening animation on load
openMainAnim()
