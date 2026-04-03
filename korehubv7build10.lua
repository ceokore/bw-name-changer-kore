--[[
  ╔══════════════════════════════════════════════════════╗
  ║  KOREHUB  v7.10  ·  BUILD 10                         ║
  ╚══════════════════════════════════════════════════════╝
--]]

-- ════════════════════════════════════════
-- SERVICES + FONTS
-- ════════════════════════════════════════
local Players   = game:GetService("Players")
local RunSvc    = game:GetService("RunService")
local TweenSvc  = game:GetService("TweenService")
local UIS       = game:GetService("UserInputService")
local RepStor   = game:GetService("ReplicatedStorage")
local CoreGui   = game:GetService("CoreGui")
local Http      = game:GetService("HttpService")
local Lighting  = game:GetService("Lighting")
local Debris    = game:GetService("Debris")
local lp        = Players.LocalPlayer

local Bold = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local Semi = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)
local Reg  = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Regular)

-- ════════════════════════════════════════
-- SAVE / PERSIST
-- ════════════════════════════════════════
local SAVE = _G.KH_Saves or {}
_G.KH_Saves = SAVE
SAVE.kaTargets  = SAVE.kaTargets  or ""
SAVE.kaFriends  = SAVE.kaFriends  or ""
SAVE.headSit    = SAVE.headSit    or ""
SAVE.curTheme   = SAVE.curTheme   or 1
SAVE.keybinds   = SAVE.keybinds   or {}

pcall(function()
    if readfile then
        local ok,d = pcall(function() return Http:JSONDecode(readfile("kh_b10.json")) end)
        if ok and type(d)=="table" then
            for k,v in pairs(d) do SAVE[k]=v end
        end
    end
end)

local function DoSave()
    pcall(function()
        if writefile then
            writefile("kh_b10.json", Http:JSONEncode({
                kaTargets=SAVE.kaTargets, kaFriends=SAVE.kaFriends,
                headSit=SAVE.headSit,     curTheme=SAVE.curTheme,
                keybinds=SAVE.keybinds,
            }))
        end
    end)
end

-- ════════════════════════════════════════
-- FLAGS + CONNECTIONS
-- ════════════════════════════════════════
local PERF  = false
local CONNS = {}
local function TC(c) if c then table.insert(CONNS,c) end; return c end

-- ════════════════════════════════════════
-- THEMES (34)
-- ════════════════════════════════════════
local THEMES = {
    {id="formal",   name="FORMAL",    ver="v7.10·BW",
     C={BG=Color3.fromRGB(7,7,7),SURFACE=Color3.fromRGB(13,13,13),ELEV=Color3.fromRGB(21,21,21),
        RAISED=Color3.fromRGB(36,36,36),BORDER=Color3.fromRGB(54,54,54),TEXT=Color3.fromRGB(238,238,238),
        MUTED=Color3.fromRGB(118,118,118),DIM=Color3.fromRGB(66,66,66),ACCENT=Color3.fromRGB(208,208,208),
        PILL_ON=Color3.fromRGB(215,215,215),CLOSE=Color3.fromRGB(255,255,255)}},

    {id="minimal",  name="MINIMAL",   ver="v7.10·MIN",
     C={BG=Color3.fromRGB(244,244,244),SURFACE=Color3.fromRGB(233,233,233),ELEV=Color3.fromRGB(220,220,220),
        RAISED=Color3.fromRGB(205,205,205),BORDER=Color3.fromRGB(178,178,178),TEXT=Color3.fromRGB(16,16,16),
        MUTED=Color3.fromRGB(105,105,105),DIM=Color3.fromRGB(150,150,150),ACCENT=Color3.fromRGB(18,18,18),
        PILL_ON=Color3.fromRGB(16,16,16),CLOSE=Color3.fromRGB(40,40,40)}},

    {id="purple",   name="PURPLE",    ver="v7.10·PRP",
     C={BG=Color3.fromRGB(7,5,12),SURFACE=Color3.fromRGB(11,8,20),ELEV=Color3.fromRGB(18,13,32),
        RAISED=Color3.fromRGB(28,20,46),BORDER=Color3.fromRGB(56,38,90),TEXT=Color3.fromRGB(218,210,236),
        MUTED=Color3.fromRGB(108,88,144),DIM=Color3.fromRGB(64,50,88),ACCENT=Color3.fromRGB(148,84,252),
        PILL_ON=Color3.fromRGB(148,84,252),CLOSE=Color3.fromRGB(200,140,255)}},

    {id="ocean",    name="OCEAN",     ver="v7.10·OCN",
     C={BG=Color3.fromRGB(4,8,16),SURFACE=Color3.fromRGB(6,12,24),ELEV=Color3.fromRGB(10,19,36),
        RAISED=Color3.fromRGB(15,28,52),BORDER=Color3.fromRGB(24,50,90),TEXT=Color3.fromRGB(202,222,244),
        MUTED=Color3.fromRGB(72,112,158),DIM=Color3.fromRGB(42,70,106),ACCENT=Color3.fromRGB(48,158,250),
        PILL_ON=Color3.fromRGB(48,158,250),CLOSE=Color3.fromRGB(100,200,255)}},

    {id="crimson",  name="CRIMSON",   ver="v7.10·CRM",
     C={BG=Color3.fromRGB(9,3,3),SURFACE=Color3.fromRGB(16,6,6),ELEV=Color3.fromRGB(25,9,9),
        RAISED=Color3.fromRGB(38,14,14),BORDER=Color3.fromRGB(74,22,22),TEXT=Color3.fromRGB(242,216,216),
        MUTED=Color3.fromRGB(142,80,80),DIM=Color3.fromRGB(86,42,42),ACCENT=Color3.fromRGB(218,58,58),
        PILL_ON=Color3.fromRGB(218,58,58),CLOSE=Color3.fromRGB(255,100,100)}},

    {id="carbon",   name="CARBON",    ver="v7.10·CBN",
     C={BG=Color3.fromRGB(9,11,13),SURFACE=Color3.fromRGB(14,17,20),ELEV=Color3.fromRGB(21,25,29),
        RAISED=Color3.fromRGB(31,37,42),BORDER=Color3.fromRGB(50,57,64),TEXT=Color3.fromRGB(210,216,220),
        MUTED=Color3.fromRGB(96,106,116),DIM=Color3.fromRGB(58,66,74),ACCENT=Color3.fromRGB(72,176,136),
        PILL_ON=Color3.fromRGB(72,176,136),CLOSE=Color3.fromRGB(100,220,170)}},

    {id="neon",     name="NEON",      ver="v7.10·NEO",
     C={BG=Color3.fromRGB(3,3,8),SURFACE=Color3.fromRGB(6,6,14),ELEV=Color3.fromRGB(10,10,22),
        RAISED=Color3.fromRGB(16,16,34),BORDER=Color3.fromRGB(0,200,150),TEXT=Color3.fromRGB(200,255,240),
        MUTED=Color3.fromRGB(0,180,120),DIM=Color3.fromRGB(0,100,70),ACCENT=Color3.fromRGB(0,255,180),
        PILL_ON=Color3.fromRGB(0,255,180),CLOSE=Color3.fromRGB(255,80,200)}},

    {id="sakura",   name="SAKURA",    ver="v7.10·SKR",
     C={BG=Color3.fromRGB(10,5,8),SURFACE=Color3.fromRGB(18,10,14),ELEV=Color3.fromRGB(28,14,20),
        RAISED=Color3.fromRGB(42,20,30),BORDER=Color3.fromRGB(180,80,120),TEXT=Color3.fromRGB(255,220,235),
        MUTED=Color3.fromRGB(200,100,140),DIM=Color3.fromRGB(110,55,80),ACCENT=Color3.fromRGB(255,120,170),
        PILL_ON=Color3.fromRGB(255,120,170),CLOSE=Color3.fromRGB(255,80,120)}},

    {id="emerald",  name="EMERALD",   ver="v7.10·EMR",
     C={BG=Color3.fromRGB(3,10,6),SURFACE=Color3.fromRGB(5,16,9),ELEV=Color3.fromRGB(8,26,14),
        RAISED=Color3.fromRGB(12,40,20),BORDER=Color3.fromRGB(20,100,50),TEXT=Color3.fromRGB(200,245,215),
        MUTED=Color3.fromRGB(60,160,90),DIM=Color3.fromRGB(30,90,50),ACCENT=Color3.fromRGB(50,220,120),
        PILL_ON=Color3.fromRGB(50,220,120),CLOSE=Color3.fromRGB(100,255,150)}},

    {id="revix",    name="REVIX",     ver="v7.10·RVX",
     bg="rbxassetid://91498494479244", grad=true,
     C={BG=Color3.fromRGB(8,4,14),SURFACE=Color3.fromRGB(12,6,20),ELEV=Color3.fromRGB(20,10,34),
        RAISED=Color3.fromRGB(32,16,50),BORDER=Color3.fromRGB(120,60,200),TEXT=Color3.fromRGB(240,220,255),
        MUTED=Color3.fromRGB(180,120,240),DIM=Color3.fromRGB(90,60,140),ACCENT=Color3.fromRGB(220,180,0),
        PILL_ON=Color3.fromRGB(220,180,0),CLOSE=Color3.fromRGB(220,180,0)}},

    {id="kore",     name="KORE",      ver="v7.10·KRE",
     bg="rbxassetid://82357362944684",
     C={BG=Color3.fromRGB(10,10,10),SURFACE=Color3.fromRGB(18,18,18),ELEV=Color3.fromRGB(30,30,30),
        RAISED=Color3.fromRGB(50,50,50),BORDER=Color3.fromRGB(76,76,76),TEXT=Color3.fromRGB(252,252,252),
        MUTED=Color3.fromRGB(150,150,150),DIM=Color3.fromRGB(90,90,90),ACCENT=Color3.fromRGB(232,232,232),
        PILL_ON=Color3.fromRGB(248,248,248),CLOSE=Color3.fromRGB(255,255,255)}},

    {id="l1ght",    name="L1GHT",     ver="v7.10·LGT",
     bg="rbxassetid://74283951849549",
     C={BG=Color3.fromRGB(18,20,24),SURFACE=Color3.fromRGB(26,30,36),ELEV=Color3.fromRGB(36,42,50),
        RAISED=Color3.fromRGB(50,58,70),BORDER=Color3.fromRGB(70,110,160),TEXT=Color3.fromRGB(210,220,235),
        MUTED=Color3.fromRGB(140,100,80),DIM=Color3.fromRGB(100,80,60),ACCENT=Color3.fromRGB(200,50,50),
        PILL_ON=Color3.fromRGB(180,220,80),CLOSE=Color3.fromRGB(255,80,80)}},

    {id="slate",    name="SLATE",     ver="v7.10·SLT",
     C={BG=Color3.fromRGB(15,19,26),SURFACE=Color3.fromRGB(21,27,36),ELEV=Color3.fromRGB(30,38,50),
        RAISED=Color3.fromRGB(42,54,70),BORDER=Color3.fromRGB(58,76,100),TEXT=Color3.fromRGB(200,215,235),
        MUTED=Color3.fromRGB(100,125,158),DIM=Color3.fromRGB(60,78,102),ACCENT=Color3.fromRGB(90,180,255),
        PILL_ON=Color3.fromRGB(90,180,255),CLOSE=Color3.fromRGB(120,200,255)}},

    {id="midnight", name="MIDNIGHT",  ver="v7.10·MDN",
     C={BG=Color3.fromRGB(4,6,20),SURFACE=Color3.fromRGB(7,10,32),ELEV=Color3.fromRGB(12,16,46),
        RAISED=Color3.fromRGB(18,24,64),BORDER=Color3.fromRGB(30,42,110),TEXT=Color3.fromRGB(188,200,255),
        MUTED=Color3.fromRGB(80,100,188),DIM=Color3.fromRGB(45,58,130),ACCENT=Color3.fromRGB(88,130,255),
        PILL_ON=Color3.fromRGB(88,130,255),CLOSE=Color3.fromRGB(120,160,255)}},

    {id="rust",     name="RUST",      ver="v7.10·RST",
     C={BG=Color3.fromRGB(12,7,3),SURFACE=Color3.fromRGB(20,11,5),ELEV=Color3.fromRGB(32,18,7),
        RAISED=Color3.fromRGB(50,28,10),BORDER=Color3.fromRGB(110,55,20),TEXT=Color3.fromRGB(240,210,185),
        MUTED=Color3.fromRGB(160,95,55),DIM=Color3.fromRGB(100,55,25),ACCENT=Color3.fromRGB(210,88,30),
        PILL_ON=Color3.fromRGB(210,88,30),CLOSE=Color3.fromRGB(255,120,60)}},

    {id="cyber",    name="CYBER",     ver="v7.10·CBR",
     C={BG=Color3.fromRGB(5,0,10),SURFACE=Color3.fromRGB(10,0,18),ELEV=Color3.fromRGB(18,0,30),
        RAISED=Color3.fromRGB(28,0,46),BORDER=Color3.fromRGB(200,0,120),TEXT=Color3.fromRGB(255,180,240),
        MUTED=Color3.fromRGB(180,60,140),DIM=Color3.fromRGB(120,0,90),ACCENT=Color3.fromRGB(255,30,160),
        PILL_ON=Color3.fromRGB(255,30,160),CLOSE=Color3.fromRGB(255,80,200)}},

    {id="solar",    name="SOLAR",     ver="v7.10·SLR",
     C={BG=Color3.fromRGB(10,6,0),SURFACE=Color3.fromRGB(18,10,0),ELEV=Color3.fromRGB(30,18,0),
        RAISED=Color3.fromRGB(48,30,0),BORDER=Color3.fromRGB(160,100,0),TEXT=Color3.fromRGB(255,240,200),
        MUTED=Color3.fromRGB(200,150,60),DIM=Color3.fromRGB(140,90,20),ACCENT=Color3.fromRGB(255,185,0),
        PILL_ON=Color3.fromRGB(255,185,0),CLOSE=Color3.fromRGB(255,220,60)}},

    {id="void",     name="VOID",      ver="v7.10·VID",
     C={BG=Color3.fromRGB(0,0,0),SURFACE=Color3.fromRGB(4,2,6),ELEV=Color3.fromRGB(8,4,12),
        RAISED=Color3.fromRGB(14,7,20),BORDER=Color3.fromRGB(40,10,60),TEXT=Color3.fromRGB(200,180,220),
        MUTED=Color3.fromRGB(80,50,110),DIM=Color3.fromRGB(50,25,70),ACCENT=Color3.fromRGB(120,40,180),
        PILL_ON=Color3.fromRGB(120,40,180),CLOSE=Color3.fromRGB(160,80,220)}},

    {id="blood",    name="BLOOD",     ver="v7.10·BLD",
     C={BG=Color3.fromRGB(6,0,0),SURFACE=Color3.fromRGB(12,2,2),ELEV=Color3.fromRGB(22,4,4),
        RAISED=Color3.fromRGB(38,8,8),BORDER=Color3.fromRGB(100,10,10),TEXT=Color3.fromRGB(255,220,220),
        MUTED=Color3.fromRGB(160,60,60),DIM=Color3.fromRGB(100,20,20),ACCENT=Color3.fromRGB(255,20,20),
        PILL_ON=Color3.fromRGB(255,40,40),CLOSE=Color3.fromRGB(255,80,80)}},

    {id="mint",     name="MINT",      ver="v7.10·MNT",
     C={BG=Color3.fromRGB(4,12,10),SURFACE=Color3.fromRGB(7,20,16),ELEV=Color3.fromRGB(12,30,24),
        RAISED=Color3.fromRGB(18,44,36),BORDER=Color3.fromRGB(30,90,70),TEXT=Color3.fromRGB(200,250,235),
        MUTED=Color3.fromRGB(70,160,120),DIM=Color3.fromRGB(35,90,68),ACCENT=Color3.fromRGB(40,230,160),
        PILL_ON=Color3.fromRGB(40,230,160),CLOSE=Color3.fromRGB(80,255,180)}},

    {id="rosegold", name="ROSE GOLD", ver="v7.10·RGD",
     C={BG=Color3.fromRGB(14,9,9),SURFACE=Color3.fromRGB(22,14,14),ELEV=Color3.fromRGB(34,22,22),
        RAISED=Color3.fromRGB(52,34,34),BORDER=Color3.fromRGB(160,90,90),TEXT=Color3.fromRGB(255,225,215),
        MUTED=Color3.fromRGB(190,130,120),DIM=Color3.fromRGB(120,70,70),ACCENT=Color3.fromRGB(220,150,130),
        PILL_ON=Color3.fromRGB(220,150,130),CLOSE=Color3.fromRGB(255,180,160)}},

    {id="matrix",   name="MATRIX",    ver="v7.10·MTX",
     C={BG=Color3.fromRGB(0,4,0),SURFACE=Color3.fromRGB(0,8,2),ELEV=Color3.fromRGB(0,14,4),
        RAISED=Color3.fromRGB(0,22,6),BORDER=Color3.fromRGB(0,100,20),TEXT=Color3.fromRGB(100,255,80),
        MUTED=Color3.fromRGB(0,140,30),DIM=Color3.fromRGB(0,70,15),ACCENT=Color3.fromRGB(0,255,60),
        PILL_ON=Color3.fromRGB(0,255,60),CLOSE=Color3.fromRGB(100,255,80)}},

    {id="glacier",  name="GLACIER",   ver="v7.10·GLC",
     C={BG=Color3.fromRGB(8,12,18),SURFACE=Color3.fromRGB(14,20,30),ELEV=Color3.fromRGB(22,32,46),
        RAISED=Color3.fromRGB(34,48,68),BORDER=Color3.fromRGB(100,150,200),TEXT=Color3.fromRGB(220,235,255),
        MUTED=Color3.fromRGB(130,170,210),DIM=Color3.fromRGB(70,100,140),ACCENT=Color3.fromRGB(160,210,255),
        PILL_ON=Color3.fromRGB(160,210,255),CLOSE=Color3.fromRGB(200,230,255)}},

    {id="gold",     name="GOLD",      ver="v7.10·GLD",
     C={BG=Color3.fromRGB(10,8,0),SURFACE=Color3.fromRGB(18,14,0),ELEV=Color3.fromRGB(28,22,0),
        RAISED=Color3.fromRGB(44,34,0),BORDER=Color3.fromRGB(140,100,0),TEXT=Color3.fromRGB(255,245,200),
        MUTED=Color3.fromRGB(190,150,40),DIM=Color3.fromRGB(120,90,10),ACCENT=Color3.fromRGB(255,200,0),
        PILL_ON=Color3.fromRGB(255,200,0),CLOSE=Color3.fromRGB(255,230,80)}},

    {id="stealth",  name="STEALTH",   ver="v7.10·STH",
     C={BG=Color3.fromRGB(4,4,4),SURFACE=Color3.fromRGB(8,8,8),ELEV=Color3.fromRGB(14,14,14),
        RAISED=Color3.fromRGB(22,22,22),BORDER=Color3.fromRGB(34,34,34),TEXT=Color3.fromRGB(160,160,160),
        MUTED=Color3.fromRGB(80,80,80),DIM=Color3.fromRGB(44,44,44),ACCENT=Color3.fromRGB(90,90,90),
        PILL_ON=Color3.fromRGB(120,120,120),CLOSE=Color3.fromRGB(140,140,140)}},

    {id="toxic",    name="TOXIC",     ver="v7.10·TOX",
     C={BG=Color3.fromRGB(2,8,0),SURFACE=Color3.fromRGB(4,14,2),ELEV=Color3.fromRGB(6,22,4),
        RAISED=Color3.fromRGB(10,34,6),BORDER=Color3.fromRGB(40,180,20),TEXT=Color3.fromRGB(180,255,100),
        MUTED=Color3.fromRGB(80,200,40),DIM=Color3.fromRGB(30,120,10),ACCENT=Color3.fromRGB(120,255,0),
        PILL_ON=Color3.fromRGB(120,255,0),CLOSE=Color3.fromRGB(180,255,80)}},

    {id="vaporwave", name="VAPORWAVE", ver="v7.10·VAP",
     C={BG=Color3.fromRGB(12,4,20),SURFACE=Color3.fromRGB(20,8,35),ELEV=Color3.fromRGB(30,12,50),
        RAISED=Color3.fromRGB(45,20,70),BORDER=Color3.fromRGB(255,80,200),TEXT=Color3.fromRGB(255,220,240),
        MUTED=Color3.fromRGB(200,100,180),DIM=Color3.fromRGB(120,60,140),ACCENT=Color3.fromRGB(0,255,255),
        PILL_ON=Color3.fromRGB(0,255,255),CLOSE=Color3.fromRGB(255,100,220)}},

    {id="inferno",  name="INFERNO",   ver="v7.10·INF",
     C={BG=Color3.fromRGB(15,5,0),SURFACE=Color3.fromRGB(25,8,2),ELEV=Color3.fromRGB(40,15,5),
        RAISED=Color3.fromRGB(65,25,8),BORDER=Color3.fromRGB(255,80,20),TEXT=Color3.fromRGB(255,230,200),
        MUTED=Color3.fromRGB(200,100,40),DIM=Color3.fromRGB(140,60,20),ACCENT=Color3.fromRGB(255,100,30),
        PILL_ON=Color3.fromRGB(255,100,30),CLOSE=Color3.fromRGB(255,140,60)}},

    {id="frostbite",name="FROSTBITE", ver="v7.10·FRB",
     C={BG=Color3.fromRGB(0,8,15),SURFACE=Color3.fromRGB(2,15,28),ELEV=Color3.fromRGB(5,22,40),
        RAISED=Color3.fromRGB(10,35,60),BORDER=Color3.fromRGB(80,200,255),TEXT=Color3.fromRGB(220,245,255),
        MUTED=Color3.fromRGB(100,180,220),DIM=Color3.fromRGB(50,120,160),ACCENT=Color3.fromRGB(100,220,255),
        PILL_ON=Color3.fromRGB(100,220,255),CLOSE=Color3.fromRGB(140,240,255)}},

    {id="phantom",  name="PHANTOM",   ver="v7.10·PHT",
     C={BG=Color3.fromRGB(6,3,12),SURFACE=Color3.fromRGB(10,6,18),ELEV=Color3.fromRGB(16,10,28),
        RAISED=Color3.fromRGB(24,15,40),BORDER=Color3.fromRGB(140,80,200),TEXT=Color3.fromRGB(230,210,255),
        MUTED=Color3.fromRGB(140,100,180),DIM=Color3.fromRGB(80,55,120),ACCENT=Color3.fromRGB(180,100,255),
        PILL_ON=Color3.fromRGB(180,100,255),CLOSE=Color3.fromRGB(200,140,255)}},

    {id="electric", name="ELECTRIC",  ver="v7.10·ELC",
     C={BG=Color3.fromRGB(2,4,12),SURFACE=Color3.fromRGB(5,8,22),ELEV=Color3.fromRGB(10,15,35),
        RAISED=Color3.fromRGB(18,25,55),BORDER=Color3.fromRGB(0,200,255),TEXT=Color3.fromRGB(200,240,255),
        MUTED=Color3.fromRGB(80,160,220),DIM=Color3.fromRGB(40,100,160),ACCENT=Color3.fromRGB(0,255,220),
        PILL_ON=Color3.fromRGB(0,255,220),CLOSE=Color3.fromRGB(100,255,240)}},

    {id="obsidian", name="OBSIDIAN",  ver="v7.10·OBS",
     C={BG=Color3.fromRGB(5,5,7),SURFACE=Color3.fromRGB(9,9,12),ELEV=Color3.fromRGB(14,14,18),
        RAISED=Color3.fromRGB(22,22,28),BORDER=Color3.fromRGB(60,60,75),TEXT=Color3.fromRGB(235,235,245),
        MUTED=Color3.fromRGB(110,110,130),DIM=Color3.fromRGB(70,70,85),ACCENT=Color3.fromRGB(180,180,200),
        PILL_ON=Color3.fromRGB(180,180,200),CLOSE=Color3.fromRGB(210,210,230)}},

    {id="eclipse",  name="ECLIPSE",   ver="v7.10·ECL",
     C={BG=Color3.fromRGB(3,2,8),SURFACE=Color3.fromRGB(7,5,14),ELEV=Color3.fromRGB(12,9,24),
        RAISED=Color3.fromRGB(20,15,38),BORDER=Color3.fromRGB(100,40,140),TEXT=Color3.fromRGB(220,200,255),
        MUTED=Color3.fromRGB(130,90,170),DIM=Color3.fromRGB(75,50,110),ACCENT=Color3.fromRGB(160,60,220),
        PILL_ON=Color3.fromRGB(160,60,220),CLOSE=Color3.fromRGB(190,100,255)}},

    {id="hyper",    name="HYPER",     ver="v7.10·HYP",
     C={BG=Color3.fromRGB(8,0,8),SURFACE=Color3.fromRGB(14,2,14),ELEV=Color3.fromRGB(22,4,22),
        RAISED=Color3.fromRGB(35,8,35),BORDER=Color3.fromRGB(255,0,180),TEXT=Color3.fromRGB(255,200,240),
        MUTED=Color3.fromRGB(200,80,160),DIM=Color3.fromRGB(120,40,100),ACCENT=Color3.fromRGB(255,80,220),
        PILL_ON=Color3.fromRGB(255,80,220),CLOSE=Color3.fromRGB(255,120,240)}}
}

local C = {}
for k,v in pairs(THEMES[1].C) do C[k]=v end
local TR={}; local PILLS={}
local curThemeIdx = math.clamp(SAVE.curTheme or 1, 1, #THEMES)
local _G_VerLbl; local _G_SwBorders={}
local BgImg; local RevixGrad; local RevixGradConn
local Win  -- forward decl

local function TReg(o,p,k) if o and p and k then table.insert(TR,{o=o,p=p,k=k}) end end

local function ApplyTheme(idx, instant)
    curThemeIdx = math.clamp(idx,1,#THEMES)
    SAVE.curTheme = curThemeIdx
    local T = THEMES[curThemeIdx]
    for k,v in pairs(T.C) do C[k]=v end
    local ti = TweenInfo.new(instant and 0 or 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local live={}
    for _,e in ipairs(TR) do
        if e.o and pcall(function() return e.o.Parent end) and e.o.Parent then table.insert(live,e) end
    end
    for i=1,#TR do TR[i]=nil end
    for i,e in ipairs(live) do TR[i]=e end
    for _,e in ipairs(TR) do
        local val=C[e.k]; if val then
            if instant then pcall(function() e.o[e.p]=val end)
            else pcall(function() TweenSvc:Create(e.o,ti,{[e.p]=val}):Play() end) end
        end
    end
    for _,p2 in ipairs(PILLS) do
        if p2.thumb and pcall(function() return p2.thumb.Parent end) and p2.thumb.Parent then
            local col = p2.getF() and C.PILL_ON or C.DIM
            if instant then pcall(function() p2.thumb.BackgroundColor3=col end)
            else pcall(function() TweenSvc:Create(p2.thumb,ti,{BackgroundColor3=col}):Play() end) end
        end
    end
    if _G_VerLbl then pcall(function() _G_VerLbl.Text=T.ver end) end
    for i,s in ipairs(_G_SwBorders) do
        pcall(function() TweenSvc:Create(s,TweenInfo.new(0.2),{Transparency=(i==curThemeIdx) and 0.05 or 0.88}):Play() end)
    end
    if BgImg and Win then
        if T.bg then
            pcall(function() BgImg.Image=T.bg; BgImg.Visible=true end)
            pcall(function() TweenSvc:Create(Win,TweenInfo.new(0.3),{BackgroundTransparency=0.5}):Play() end)
            pcall(function() TweenSvc:Create(BgImg,TweenInfo.new(0.3),{ImageTransparency=0.5}):Play() end)
        else
            pcall(function() TweenSvc:Create(Win,TweenInfo.new(0.3),{BackgroundTransparency=0.04}):Play() end)
            pcall(function() TweenSvc:Create(BgImg,TweenInfo.new(0.2),{ImageTransparency=1}):Play() end)
            task.delay(0.22,function() pcall(function() if not THEMES[curThemeIdx].bg then BgImg.Visible=false end end) end)
        end
    end
    if RevixGradConn then RevixGradConn:Disconnect(); RevixGradConn=nil end
    if RevixGrad then RevixGrad.Parent=nil end
    if T.grad and not PERF and BgImg then
        RevixGrad = Instance.new("UIGradient")
        RevixGrad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(120,0,200)),
            ColorSequenceKeypoint.new(0.5,Color3.fromRGB(200,160,0)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(80,0,160)),
        }
        RevixGrad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0.82),NumberSequenceKeypoint.new(1,0.82)}
        RevixGrad.Parent = BgImg
        local ang=0
        RevixGradConn = TC(RunSvc.Heartbeat:Connect(function(dt)
            if PERF then return end; ang=(ang+dt*20)%360; RevixGrad.Rotation=ang
        end))
    end
    task.delay(0.1, DoSave)
end

-- ════════════════════════════════════════
-- REMOTES
-- ════════════════════════════════════════
local HitRF
pcall(function()
    HitRF = RepStor:WaitForChild("Packages",4):WaitForChild("Knit",4)
        :WaitForChild("Services",4):WaitForChild("CombatService",4)
        :WaitForChild("RF",4):WaitForChild("Hit",4)
end)
local RPR={}
pcall(function()
    local rem = RepStor:WaitForChild("Remotes",3)
    RPR.Color = rem:WaitForChild("UpdateRPColor",3)
    RPR.Name  = rem:WaitForChild("UpdateRPName",3)
    RPR.Bio   = rem:WaitForChild("UpdateBioColor",3)
    RPR.BioF  = RPR.Bio and RPR.Bio:IsA("RemoteFunction")
end)

-- ════════════════════════════════════════
-- GUI ROOT
-- ════════════════════════════════════════
pcall(function() local o=CoreGui:FindFirstChild("KH10"); if o then o:Destroy() end end)
local GUI = Instance.new("ScreenGui")
GUI.Name="KH10"; GUI.ResetOnSpawn=false
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
GUI.IgnoreGuiInset=true; GUI.Parent=CoreGui

-- ════════════════════════════════════════
-- BASE HELPERS
-- ════════════════════════════════════════
local function Cnr(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 8); return c end
local function Strk(p,col,thick,t)
    local s=Instance.new("UIStroke",p); s.Color=col or C.BORDER; s.Thickness=thick or 1; s.Transparency=t or 0; return s
end
local function LL(p,pad) local l=Instance.new("UIListLayout",p); l.Padding=UDim.new(0,pad or 6); l.SortOrder=Enum.SortOrder.LayoutOrder; return l end
local function LP(p,l,r,t,b)
    local u=Instance.new("UIPadding",p)
    u.PaddingLeft=UDim.new(0,l or 0); u.PaddingRight=UDim.new(0,r or 0)
    u.PaddingTop=UDim.new(0,t or 0); u.PaddingBottom=UDim.new(0,b or 0)
end
local function Tw(obj, props, time, style, dir)
    TweenSvc:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props):Play()
end

-- ════════════════════════════════════════
-- PULSE SYSTEM
-- ════════════════════════════════════════
local PULSE={}
TC(RunSvc.Heartbeat:Connect(function()
    if PERF then return end; local t=tick()
    for _,e in ipairs(PULSE) do
        if e.o and e.o.Parent then
            local w=(math.sin(t*0.74+e.ph)+1)*0.5
            e.o.TextColor3=e.base:Lerp(Color3.new(1,1,1), 0.28+w*0.38)
        end
    end
end))

-- ════════════════════════════════════════
-- QUIPS
-- ════════════════════════════════════════
local QUIPS={
    "keep it formal.","stay focused.","sharp as always.","you got this.",
    "looking clean.","don't slip up.","run it back.","stay sharp.",
    "kore was here.","how you doing?","best for the best.","FAH!",
    "no hesitation.","eyes forward.","zero mistakes.","built different.",
    "lock in.","silent but deadly.","no cap.","all business.","top tier only.",
    "calculated.","precision only.","stay dangerous.","no excuses.",
}

-- ════════════════════════════════════════
-- FORWARD DECLARATIONS
-- ════════════════════════════════════════
local SubLbl; local GoTab; local ShowNotif

-- ════════════════════════════════════════
-- KEYBIND SYSTEM
-- ════════════════════════════════════════
local KEYBINDS = {}
local _KB_LISTENING = false
local _KB_LISTEN_CB = nil
local _KB_RefUI = nil

local function RegisterKeybind(action, defaultKey, callback, group)
    local savedKeyName = SAVE.keybinds and SAVE.keybinds[action]
    local finalKey = defaultKey
    if savedKeyName then
        local ok,kc = pcall(function() return Enum.KeyCode[savedKeyName] end)
        if ok and kc then finalKey=kc end
    end
    for _,kb in ipairs(KEYBINDS) do
        if kb.action==action then kb.callback=callback; return kb end
    end
    local kb={action=action, key=finalKey, callback=callback, enabled=true, group=group or "General"}
    table.insert(KEYBINDS, kb)
    return kb
end

local function GetKeybind(action)
    for _,kb in ipairs(KEYBINDS) do if kb.action==action then return kb end end; return nil
end

TC(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if _KB_LISTENING and _KB_LISTEN_CB then
        if i.UserInputType==Enum.UserInputType.Keyboard then
            _KB_LISTEN_CB(i.KeyCode); _KB_LISTENING=false; _KB_LISTEN_CB=nil; return
        end
    end
    if i.UserInputType==Enum.UserInputType.Keyboard then
        for _,kb in ipairs(KEYBINDS) do
            if kb.enabled and kb.key==i.KeyCode and kb.callback then pcall(kb.callback) end
        end
    end
end))

-- ════════════════════════════════════════
-- NOTIFICATION SYSTEM (smooth, rebuilt)
-- ════════════════════════════════════════
local NotifHolder = Instance.new("Frame", GUI)
NotifHolder.Size = UDim2.new(0,300,1,-24); NotifHolder.Position = UDim2.new(1,-314,0,12)
NotifHolder.BackgroundTransparency=1; NotifHolder.BorderSizePixel=0; NotifHolder.ZIndex=9000
NotifHolder.ClipsDescendants=false

local _notifs={}; local NOTIF_H=64; local NOTIF_GAP=6

local function _restack()
    local y=0
    for _,f in ipairs(_notifs) do
        if f and f.Parent then
            Tw(f,{Position=UDim2.new(0,0,0,y)},0.26,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
            y=y+NOTIF_H+NOTIF_GAP
        end
    end
end

ShowNotif = function(title, body, ntype)
    local accent = (ntype=="success" and Color3.fromRGB(50,215,100))
               or (ntype=="warn"    and Color3.fromRGB(235,185,0))
               or (ntype=="error"   and Color3.fromRGB(235,55,55))
               or (ntype=="kill"    and Color3.fromRGB(255,40,40))
               or C.ACCENT
    local icon = (ntype=="success" and "✓") or (ntype=="warn" and "⚠")
              or (ntype=="error" and "✕") or (ntype=="kill" and "⚔") or "·"
    local y = #_notifs*(NOTIF_H+NOTIF_GAP)
    local f = Instance.new("Frame", NotifHolder)
    f.Size=UDim2.new(1,0,0,NOTIF_H); f.Position=UDim2.new(1,14,0,y)
    f.BackgroundColor3=C.SURFACE; f.BackgroundTransparency=0.04
    f.BorderSizePixel=0; f.ZIndex=9001; Cnr(f,10)
    Strk(f,accent,1.5,0.08)
    local bar=Instance.new("Frame",f); bar.Size=UDim2.new(0,3,0,44); bar.Position=UDim2.new(0,0,0.5,-22)
    bar.BackgroundColor3=accent; bar.BorderSizePixel=0; Cnr(bar,2)
    local ic=Instance.new("TextLabel",f); ic.BackgroundTransparency=1; ic.ZIndex=9002
    ic.FontFace=Bold; ic.TextSize=16; ic.TextColor3=accent; ic.Text=icon
    ic.Size=UDim2.new(0,28,1,0); ic.Position=UDim2.new(0,8,0,0)
    ic.TextXAlignment=Enum.TextXAlignment.Center; ic.TextYAlignment=Enum.TextYAlignment.Center
    local tl=Instance.new("TextLabel",f); tl.BackgroundTransparency=1; tl.ZIndex=9002
    tl.FontFace=Bold; tl.TextSize=11; tl.TextColor3=C.TEXT; tl.Text=title
    tl.Size=UDim2.new(1,-40,0,19); tl.Position=UDim2.new(0,38,0,10)
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.TextTruncate=Enum.TextTruncate.AtEnd
    local bl=Instance.new("TextLabel",f); bl.BackgroundTransparency=1; bl.ZIndex=9002
    bl.FontFace=Reg; bl.TextSize=9; bl.TextColor3=C.MUTED; bl.Text=body or ""
    bl.Size=UDim2.new(1,-40,0,26); bl.Position=UDim2.new(0,38,0,30)
    bl.TextXAlignment=Enum.TextXAlignment.Left; bl.TextWrapped=true
    local pb=Instance.new("Frame",f); pb.Size=UDim2.new(1,0,0,2); pb.Position=UDim2.new(0,0,1,-2)
    pb.BackgroundColor3=accent; pb.BackgroundTransparency=0.3; pb.BorderSizePixel=0
    local rb=Instance.new("TextButton",f); rb.Size=UDim2.new(1,0,1,0); rb.BackgroundTransparency=1; rb.Text=""; rb.ZIndex=9003
    table.insert(_notifs, f)
    Tw(f,{Position=UDim2.new(0,0,0,y)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    local dur = _G.KH_NotifDur or 4
    TweenSvc:Create(pb,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,2)}):Play()
    local function dismiss()
        local idx=table.find(_notifs,f); if idx then table.remove(_notifs,idx) end
        Tw(f,{Position=UDim2.new(1,16,0,f.Position.Y.Offset),BackgroundTransparency=1},0.22,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
        task.delay(0.24,function() pcall(function() f:Destroy() end) end)
        task.delay(0.06,_restack)
    end
    rb.MouseButton1Click:Connect(dismiss)
    task.delay(dur+0.1,function() if f and f.Parent then dismiss() end end)
end

-- ════════════════════════════════════════
-- HIT VFX
-- ════════════════════════════════════════
local function ShowHitVFX(hrp)
    if not hrp or not hrp.Parent then return end
    task.spawn(function()
        pcall(function()
            local hi=Instance.new("SelectionBox")
            hi.Color3=C.ACCENT; hi.LineThickness=0.05; hi.SurfaceTransparency=0.65
            hi.SurfaceColor3=C.ACCENT; hi.Adornee=hrp; hi.Parent=workspace
            Tw(hi,{LineThickness=0.14,SurfaceTransparency=0.2},0.1)
            task.wait(0.14); Tw(hi,{LineThickness=0,SurfaceTransparency=1},0.25)
            task.delay(0.27,function() pcall(function() hi:Destroy() end) end)
        end)
    end)
end

-- ════════════════════════════════════════
-- COMPONENT FACTORIES
-- ════════════════════════════════════════
local function MkLabel(parent, p)
    local l=Instance.new("TextLabel",parent)
    l.BackgroundTransparency=1; l.FontFace=p.font or Reg
    l.TextSize=p.size or 12; l.TextColor3=p.color or C.TEXT
    l.Text=p.text or ""; l.Size=p.sz or UDim2.new(1,0,0,16)
    l.Position=p.pos or UDim2.new(0,0,0,0)
    l.TextXAlignment=p.xa or Enum.TextXAlignment.Left
    l.TextYAlignment=p.ya or Enum.TextYAlignment.Center
    l.TextWrapped=p.wrap or false
    l.TextTruncate=p.wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
    l.RichText=false; l.ZIndex=p.z or 1; l.AnchorPoint=p.anchor or Vector2.new(0,0)
    if p.tkey then TReg(l,"TextColor3",p.tkey) end
    if p.pulse then table.insert(PULSE,{o=l,base=p.color or C.DIM,ph=math.random()*6.28}) end
    return l
end

local function MkBtn(parent, p)
    local b=Instance.new("TextButton",parent)
    b.BackgroundColor3=p.bg or C.ELEV; b.BackgroundTransparency=p.bgt or 0
    b.FontFace=p.font or Semi; b.TextSize=p.size or 12
    b.TextColor3=p.color or C.TEXT; b.Text=p.text or ""
    b.Size=p.sz or UDim2.new(1,0,0,30); b.Position=p.pos or UDim2.new(0,0,0,0)
    b.AnchorPoint=p.anchor or Vector2.new(0,0); b.AutoButtonColor=false
    b.BorderSizePixel=0; b.LayoutOrder=p.order or 0; b.ZIndex=p.z or 1
    b.TextTruncate=Enum.TextTruncate.AtEnd; b.ClipsDescendants=false
    if p.corner~=false then Cnr(b,p.corner or 7) end
    if p.bgkey then TReg(b,"BackgroundColor3",p.bgkey) end
    if p.tkey  then TReg(b,"TextColor3",p.tkey) end
    b.MouseEnter:Connect(function() Tw(b,{BackgroundTransparency=math.max(0,(p.bgt or 0)-0.08)},0.12) end)
    b.MouseLeave:Connect(function() Tw(b,{BackgroundTransparency=p.bgt or 0},0.12) end)
    b.MouseButton1Down:Connect(function() Tw(b,{Size=UDim2.new(b.Size.X.Scale,b.Size.X.Offset-2,b.Size.Y.Scale,b.Size.Y.Offset-2)},0.07) end)
    b.MouseButton1Up:Connect(function() Tw(b,{Size=p.sz or UDim2.new(1,0,0,30)},0.16,Enum.EasingStyle.Back,Enum.EasingDirection.Out) end)
    return b
end

local function MkCard(parent, h, order)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,h or 52); f.BackgroundColor3=C.ELEV
    f.BackgroundTransparency=0.08; f.BorderSizePixel=0
    f.LayoutOrder=order or 0; f.ClipsDescendants=true
    Cnr(f,9); local s=Strk(f,C.BORDER,1,0.42)
    TReg(f,"BackgroundColor3","ELEV"); TReg(s,"Color","BORDER"); return f
end

local function MkPill(card)
    local track=Instance.new("TextButton",card)
    track.Size=UDim2.new(0,42,0,20); track.Position=UDim2.new(1,-52,0.5,-10)
    track.BackgroundColor3=C.RAISED; track.BackgroundTransparency=0.15
    track.Text=""; track.AutoButtonColor=false; track.BorderSizePixel=0; Cnr(track,10); track.ZIndex=2
    local bs=Strk(track,C.BORDER,1,0.4); local hs=Strk(track,C.ACCENT,1.5,1)
    TReg(track,"BackgroundColor3","RAISED"); TReg(bs,"Color","BORDER"); TReg(hs,"Color","ACCENT")
    track.MouseEnter:Connect(function() Tw(hs,{Transparency=0.15},0.14) end)
    track.MouseLeave:Connect(function() Tw(hs,{Transparency=1},0.14) end)
    local thumb=Instance.new("Frame",track)
    thumb.Size=UDim2.new(0,14,0,14); thumb.Position=UDim2.new(0,2,0.5,-7)
    thumb.BackgroundColor3=C.DIM; thumb.BorderSizePixel=0; Cnr(thumb,8); thumb.ZIndex=3
    TReg(thumb,"BackgroundColor3","DIM")
    local state=false
    local function Set(s, silent)
        state=s
        local dp = s and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
        local dc = s and C.PILL_ON or C.DIM
        if silent then thumb.Position=dp; thumb.BackgroundColor3=dc
        else
            thumb.Size=UDim2.new(0,18,0,18)
            TweenSvc:Create(thumb,TweenInfo.new(0.32,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
                {Size=UDim2.new(0,14,0,14),Position=dp,BackgroundColor3=dc}):Play()
        end
    end
    table.insert(PILLS,{thumb=thumb,getF=function() return state end})
    return track, function() return state end, Set
end

local function MkToggleCard(parent, label, order, onEn, onDis, useActive)
    local card=MkCard(parent,52,order)
    MkLabel(card,{text=label:upper(),size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-64,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local stat=MkLabel(card,{text=useActive and "INACTIVE" or "DISABLED",size=13,color=C.MUTED,font=Bold,sz=UDim2.new(1,-64,0,20),pos=UDim2.new(0,14,0,22),tkey="MUTED"})
    local pill,getF,setF=MkPill(card)
    pill.MouseButton1Click:Connect(function()
        local s=not getF(); setF(s)
        stat.Text = s and (useActive and "ACTIVE" or "ENABLED") or (useActive and "INACTIVE" or "DISABLED")
        Tw(stat,{TextColor3=s and C.ACCENT or C.MUTED},0.14)
        if s then onEn() else onDis() end
    end)
    return pill,getF,setF,stat,card
end

local function MkSliderCard(parent, label, minV, maxV, defV, order, onChange)
    local d=math.clamp(defV or minV, minV, maxV)
    local pct0=(maxV==minV) and 0 or (d-minV)/(maxV-minV)
    local card=MkCard(parent,62,order)
    MkLabel(card,{text=label:upper(),size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-90,0,10),pos=UDim2.new(0,14,0,9),pulse=true,tkey="DIM"})
    local valLbl=MkLabel(card,{text=tostring(d),size=14,color=C.TEXT,font=Bold,sz=UDim2.new(0,70,0,16),pos=UDim2.new(1,-84,0,8),xa=Enum.TextXAlignment.Right,tkey="TEXT"})
    local track=Instance.new("Frame",card); track.Size=UDim2.new(1,-28,0,6); track.Position=UDim2.new(0,14,0,40)
    track.BackgroundColor3=C.RAISED; track.BackgroundTransparency=0.22; track.BorderSizePixel=0; Cnr(track,3); TReg(track,"BackgroundColor3","RAISED")
    local fill=Instance.new("Frame",track); fill.Size=UDim2.new(pct0,0,1,0); fill.BackgroundColor3=C.ACCENT
    fill.BackgroundTransparency=0; fill.BorderSizePixel=0; Cnr(fill,3); TReg(fill,"BackgroundColor3","ACCENT")
    local thumb=Instance.new("Frame",track); thumb.Size=UDim2.new(0,18,0,18); thumb.Position=UDim2.new(pct0,-9,0.5,-9)
    thumb.BackgroundColor3=C.TEXT; thumb.BorderSizePixel=0; Cnr(thumb,9); thumb.ZIndex=4; TReg(thumb,"BackgroundColor3","TEXT")
    local ts=Strk(thumb,C.ACCENT,1.5,1); TReg(ts,"Color","ACCENT")
    thumb.MouseEnter:Connect(function() Tw(ts,{Transparency=0.1},0.12) end)
    thumb.MouseLeave:Connect(function() Tw(ts,{Transparency=1},0.12) end)
    local dz=Instance.new("TextButton",card); dz.Size=UDim2.new(1,0,0,40); dz.Position=UDim2.new(0,0,0,22)
    dz.BackgroundTransparency=1; dz.Text=""; dz.AutoButtonColor=false; dz.ZIndex=8
    local dragging=false
    dz.MouseButton1Down:Connect(function() dragging=true; Tw(ts,{Transparency=0.1},0.1) end)
    TC(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and dragging then dragging=false; Tw(ts,{Transparency=1},0.14) end end))
    TC(RunSvc.RenderStepped:Connect(function()
        if not dragging then return end
        local aw=track.AbsoluteSize.X; if aw<=0 then return end
        local p2=math.clamp((UIS:GetMouseLocation().X-track.AbsolutePosition.X)/aw,0,1)
        fill.Size=UDim2.new(p2,0,1,0); thumb.Position=UDim2.new(p2,-9,0.5,-9)
        local val=math.floor(minV+p2*(maxV-minV)+0.5); valLbl.Text=tostring(val)
        if onChange then onChange(val) end
    end))
    task.defer(function() if track.AbsoluteSize.X>0 then thumb.Position=UDim2.new(pct0,-9,0.5,-9) end end)
    return card, valLbl
end

local function MkSmallSlider(parent, label, defVal, y, onChange)
    MkLabel(parent,{text=label,size=7,color=C.DIM,font=Bold,sz=UDim2.new(0,12,0,10),pos=UDim2.new(0,0,0,y+1)})
    local track=Instance.new("Frame",parent); track.Size=UDim2.new(1,-34,0,5); track.Position=UDim2.new(0,16,0,y+3)
    track.BackgroundColor3=C.RAISED; track.BackgroundTransparency=0.28; track.BorderSizePixel=0; Cnr(track,3); TReg(track,"BackgroundColor3","RAISED")
    local fill=Instance.new("Frame",track); fill.Size=UDim2.new(defVal/255,0,1,0); fill.BackgroundColor3=C.ACCENT; fill.BackgroundTransparency=0; fill.BorderSizePixel=0; Cnr(fill,3); TReg(fill,"BackgroundColor3","ACCENT")
    local th=Instance.new("Frame",track); th.Size=UDim2.new(0,11,0,11); th.Position=UDim2.new(defVal/255,-5,0.5,-5)
    th.BackgroundColor3=C.TEXT; th.BorderSizePixel=0; Cnr(th,6); th.ZIndex=3; TReg(th,"BackgroundColor3","TEXT")
    local vl=MkLabel(parent,{text=tostring(defVal),size=7,color=C.MUTED,font=Reg,sz=UDim2.new(0,18,0,10),pos=UDim2.new(1,-18,0,y+1),xa=Enum.TextXAlignment.Right,tkey="MUTED"})
    local dz=Instance.new("TextButton",parent); dz.Size=UDim2.new(1,-16,0,16); dz.Position=UDim2.new(0,16,0,y-2)
    dz.BackgroundTransparency=1; dz.Text=""; dz.AutoButtonColor=false; dz.ZIndex=8
    local dragging=false
    dz.MouseButton1Down:Connect(function() dragging=true end)
    TC(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end))
    TC(RunSvc.RenderStepped:Connect(function()
        if not dragging then return end
        local aw=track.AbsoluteSize.X; if aw<=0 then return end
        local pct=math.clamp((UIS:GetMouseLocation().X-track.AbsolutePosition.X)/aw,0,1)
        local val=math.floor(pct*255+0.5); fill.Size=UDim2.new(pct,0,1,0); th.Position=UDim2.new(pct,-5,0.5,-5)
        vl.Text=tostring(val); if onChange then onChange(val) end
    end))
end

local function MkTBox(card, ph, y, wOff)
    local b=Instance.new("TextBox",card)
    b.Size=UDim2.new(1,wOff or -28,0,28); b.Position=UDim2.new(0,14,0,y or 22)
    b.BackgroundColor3=C.RAISED; b.BackgroundTransparency=0.18
    b.FontFace=Reg; b.TextSize=11; b.TextColor3=C.TEXT
    b.PlaceholderColor3=C.DIM; b.PlaceholderText=ph or ""; b.Text=""
    b.ClearTextOnFocus=false; b.BorderSizePixel=0
    b.TextTruncate=Enum.TextTruncate.None; b.TextXAlignment=Enum.TextXAlignment.Left
    b.ZIndex=2; b.ClipsDescendants=false
    Cnr(b,6); local s=Strk(b,C.BORDER,1,0.3); LP(b,8,8,0,0)
    TReg(b,"BackgroundColor3","RAISED"); TReg(b,"TextColor3","TEXT")
    TReg(b,"PlaceholderColor3","DIM"); TReg(s,"Color","BORDER")
    b.Focused:Connect(function() Tw(s,{Transparency=0,Color=C.ACCENT},0.15) end)
    b.FocusLost:Connect(function() Tw(s,{Transparency=0.3,Color=C.BORDER},0.15) end)
    return b
end

local function MkTBoxCard(parent, label, ph, order, default)
    local card=MkCard(parent,60,order)
    MkLabel(card,{text=label:upper(),size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local box=MkTBox(card,ph,24); if default then box.Text=default end
    return card,box
end

local function FindPlayer(inp)
    if not inp or inp=="" then return nil end; local il=inp:lower()
    for _,p in Players:GetPlayers() do
        if p~=lp and (p.Name:lower()==il or p.DisplayName:lower()==il) then return p end
    end
    for _,p in Players:GetPlayers() do
        if p~=lp and (p.Name:lower():find(il,1,true) or p.DisplayName:lower():find(il,1,true)) then return p end
    end; return nil
end

-- ════════════════════════════════════════
-- SPRING DRAG
-- ════════════════════════════════════════
local function MakeSpringDrag(frame, handle)
    local isDrag=false; local ds,sp; local cX,cY=0,0; local vX,vY=0,0; local tX,tY=0,0; local K,B=280,52
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            isDrag=true; ds=i.Position; sp={x=frame.Position.X.Offset,y=frame.Position.Y.Offset}
            tX=sp.x; tY=sp.y; cX=sp.x; cY=sp.y; vX=0; vY=0
        end
    end)
    TC(UIS.InputChanged:Connect(function(i)
        if isDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
            tX=sp.x+(i.Position.X-ds.X); tY=sp.y+(i.Position.Y-ds.Y)
        end
    end))
    TC(UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then isDrag=false; vX=0; vY=0 end
    end))
    TC(RunSvc.RenderStepped:Connect(function(dt)
        if _G.KH_PopAnim then cX=frame.Position.X.Offset; cY=frame.Position.Y.Offset; tX=cX; tY=cY; vX=0; vY=0; return end
        local ax=(tX-cX)*K-vX*B; local ay=(tY-cY)*K-vY*B
        vX=vX+ax*dt; vY=vY+ay*dt; cX=cX+vX*dt; cY=cY+vY*dt
        frame.Position=UDim2.new(frame.Position.X.Scale,cX,frame.Position.Y.Scale,cY)
    end))
    return function(nx,ny) cX=nx;cY=ny;tX=nx;tY=ny;vX=0;vY=0 end
end

-- ════════════════════════════════════════
-- TOGGLE BUTTON
-- ════════════════════════════════════════
local TBtn=MkBtn(GUI,{bg=C.SURFACE,text="",bgt=0.12,sz=UDim2.new(0,108,0,36),pos=UDim2.new(0,22,0,748),corner=18,bgkey="SURFACE"})
local tbS=Strk(TBtn,C.BORDER,1,0.5); TReg(tbS,"Color","BORDER")
local TDot=Instance.new("Frame",TBtn); TDot.Size=UDim2.new(0,7,0,7); TDot.Position=UDim2.new(0,12,0.5,-3)
TDot.BackgroundColor3=C.DIM; TDot.BorderSizePixel=0; Cnr(TDot,4); TReg(TDot,"BackgroundColor3","DIM")
MkLabel(TBtn,{text="KORE",size=12,color=C.TEXT,font=Bold,sz=UDim2.new(1,-26,1,0),pos=UDim2.new(0,26,0,0),tkey="TEXT"})
TBtn.MouseEnter:Connect(function() Tw(tbS,{Color=C.ACCENT,Transparency=0},0.14); Tw(TDot,{BackgroundColor3=C.ACCENT,Size=UDim2.new(0,9,0,9),Position=UDim2.new(0,11,0.5,-4)},0.14) end)
TBtn.MouseLeave:Connect(function() Tw(tbS,{Color=C.BORDER,Transparency=0.5},0.14); Tw(TDot,{BackgroundColor3=C.DIM,Size=UDim2.new(0,7,0,7),Position=UDim2.new(0,12,0.5,-3)},0.14) end)
local tbDragStart=nil; local tbDragDist=0
TBtn.MouseButton1Down:Connect(function() tbDragStart=UIS:GetMouseLocation(); tbDragDist=0 end)
TC(UIS.InputChanged:Connect(function(i)
    if tbDragStart and i.UserInputType==Enum.UserInputType.MouseMovement then
        local mp=i.Position; tbDragDist=(Vector2.new(mp.X,mp.Y)-Vector2.new(tbDragStart.X,tbDragStart.Y)).Magnitude
    end
end))
MakeSpringDrag(TBtn,TBtn)

-- ════════════════════════════════════════
-- MAIN WINDOW
-- ════════════════════════════════════════
local WW,WH=740,580; local WPOS=UDim2.new(0.5,0,0.5,0)
Win = Instance.new("Frame",GUI)
Win.AnchorPoint=Vector2.new(0.5,0.5); Win.Size=UDim2.new(0,WW,0,WH); Win.Position=WPOS
Win.BackgroundColor3=C.BG; Win.BackgroundTransparency=0.04
Win.BorderSizePixel=0; Win.ClipsDescendants=true; Win.Visible=false; Cnr(Win,14)
local winS=Strk(Win,C.BORDER,1,0.25); TReg(Win,"BackgroundColor3","BG"); TReg(winS,"Color","BORDER")
local WinSc=Instance.new("UIScale",Win); WinSc.Scale=0
local FadeF=Instance.new("Frame",Win); FadeF.Size=UDim2.new(1,0,1,0); FadeF.BackgroundColor3=Color3.new(0,0,0)
FadeF.BackgroundTransparency=1; FadeF.BorderSizePixel=0; FadeF.ZIndex=500; Cnr(FadeF,14)

BgImg=Instance.new("ImageLabel",Win); BgImg.Size=UDim2.new(1,0,1,0); BgImg.BackgroundTransparency=1
BgImg.ImageTransparency=1; BgImg.ScaleType=Enum.ScaleType.Crop; BgImg.ZIndex=1; BgImg.Visible=false
BgImg.BorderSizePixel=0; Cnr(BgImg,14)

local DotsF=Instance.new("Frame",Win); DotsF.Size=UDim2.new(1,0,1,0); DotsF.BackgroundTransparency=1
DotsF.BorderSizePixel=0; DotsF.ZIndex=0; DotsF.ClipsDescendants=true; Cnr(DotsF,14)
for _=1,28 do
    local sz=math.random(1,2); local dot=Instance.new("Frame",DotsF)
    dot.Size=UDim2.new(0,sz,0,sz); dot.BackgroundColor3=Color3.fromRGB(80,80,80)
    dot.BackgroundTransparency=0.65+math.random()*0.25; dot.BorderSizePixel=0; Cnr(dot,sz)
    dot.Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0)
    local function mv()
        local tw=TweenSvc:Create(dot,TweenInfo.new(12+math.random()*18,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
            {Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),BackgroundTransparency=0.6+math.random()*0.3})
        tw:Play(); tw.Completed:Connect(mv)
    end
    task.delay(math.random()*18,mv)
end

local Main=Instance.new("Frame",Win); Main.Size=UDim2.new(1,0,1,0); Main.BackgroundTransparency=1
Main.BorderSizePixel=0; Main.ZIndex=2; Cnr(Main,14)
local ResetWinDrag=function() end

-- ════════════════════════════════════════
-- POP IN / OUT
-- ════════════════════════════════════════
local guiOpen=false; _G.KH_PopAnim=false; local activeTab=nil
local function GetTBtnCenter()
    local abs=TBtn.AbsolutePosition; local sz=TBtn.AbsoluteSize; return abs.X+sz.X*0.5, abs.Y+sz.Y*0.5
end

local _welcomed=false  -- track if welcome was shown after loading

local function PopIn()
    guiOpen=true; _G.KH_PopAnim=true
    local cx,cy=GetTBtnCenter(); Win.Position=UDim2.new(0,cx,0,cy); WinSc.Scale=0
    Win.Visible=true; FadeF.BackgroundTransparency=0.15
    TweenSvc:Create(Win,TweenInfo.new(0.44,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=WPOS}):Play()
    TweenSvc:Create(WinSc,TweenInfo.new(0.48,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    Tw(FadeF,{BackgroundTransparency=1},0.28); Tw(TDot,{BackgroundColor3=C.ACCENT},0.3)
    task.delay(0.5,function() _G.KH_PopAnim=false; ResetWinDrag(0,0) end)
    if SubLbl then SubLbl.Text=QUIPS[math.random(#QUIPS)] end
    if not activeTab and GoTab then GoTab(1) end
end

local function PopOut()
    guiOpen=false; _G.KH_PopAnim=true
    local cx,cy=GetTBtnCenter()
    ResetWinDrag(Win.Position.X.Offset, Win.Position.Y.Offset)
    TweenSvc:Create(Win,TweenInfo.new(0.38,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(0,cx,0,cy)}):Play()
    TweenSvc:Create(WinSc,TweenInfo.new(0.36,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Scale=0}):Play()
    Tw(FadeF,{BackgroundTransparency=0.08},0.22); Tw(TDot,{BackgroundColor3=C.DIM},0.28)
    local tbSz=TBtn.AbsoluteSize
    TweenSvc:Create(Win,TweenInfo.new(0.38,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
        {Size=UDim2.new(0,math.max(tbSz.X,60),0,math.max(tbSz.Y,24))}):Play()
    task.delay(0.4,function()
        if not guiOpen then
            Win.Visible=false; Win.Position=WPOS; Win.Size=UDim2.new(0,WW,0,WH)
            WinSc.Scale=1; FadeF.BackgroundTransparency=1; _G.KH_PopAnim=false
        end
    end)
end

-- ════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════
local Header=Instance.new("Frame",Main); Header.Size=UDim2.new(1,0,0,52)
Header.BackgroundColor3=C.SURFACE; Header.BackgroundTransparency=1; Header.BorderSizePixel=0; Header.ZIndex=2; Header.ClipsDescendants=false
TReg(Header,"BackgroundColor3","SURFACE")
local logo=Instance.new("Frame",Header); logo.Size=UDim2.new(0,28,0,28); logo.Position=UDim2.new(0,14,0.5,-14)
logo.BackgroundColor3=C.ELEV; logo.BackgroundTransparency=0.05; logo.BorderSizePixel=0; Cnr(logo,7)
Strk(logo,C.BORDER,1,0.4); TReg(logo,"BackgroundColor3","ELEV")
MkLabel(logo,{text="K",size=13,color=C.TEXT,font=Bold,sz=UDim2.new(1,0,1,0),xa=Enum.TextXAlignment.Center,tkey="TEXT"})
local TitleLbl=MkLabel(Header,{text="KORE HUB",size=15,color=C.TEXT,font=Bold,sz=UDim2.new(0,115,0,22),pos=UDim2.new(0,50,0,13)})
local hdrHue=0; TC(RunSvc.RenderStepped:Connect(function(dt) hdrHue=(hdrHue+dt*0.35)%1; TitleLbl.TextColor3=Color3.fromHSV(hdrHue,1,1) end))
SubLbl=MkLabel(Header,{text=QUIPS[math.random(#QUIPS)],size=8,color=C.DIM,font=Reg,sz=UDim2.new(0,230,0,11),pos=UDim2.new(0,50,0,36),pulse=true,tkey="DIM"})
local verBadge=Instance.new("Frame",Header); verBadge.Size=UDim2.new(0,72,0,17); verBadge.Position=UDim2.new(0,168,0,17)
verBadge.BackgroundColor3=C.RAISED; verBadge.BackgroundTransparency=0.12; verBadge.BorderSizePixel=0; Cnr(verBadge,9)
Strk(verBadge,C.BORDER,1,0.5); TReg(verBadge,"BackgroundColor3","RAISED")
_G_VerLbl=MkLabel(verBadge,{text=THEMES[curThemeIdx].ver,size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,0,1,0),xa=Enum.TextXAlignment.Center,tkey="DIM"})
local CloseBtn=Instance.new("TextButton",Header); CloseBtn.Size=UDim2.new(0,28,0,28); CloseBtn.Position=UDim2.new(1,-42,0.5,-14)
CloseBtn.BackgroundColor3=C.ELEV; CloseBtn.BackgroundTransparency=0.25; CloseBtn.Text="✕"; CloseBtn.FontFace=Bold; CloseBtn.TextSize=13
CloseBtn.TextColor3=C.DIM; CloseBtn.AutoButtonColor=false; CloseBtn.BorderSizePixel=0; CloseBtn.ZIndex=4; Cnr(CloseBtn,7)
local closeSt=Strk(CloseBtn,C.BORDER,1,0.5)
TReg(CloseBtn,"BackgroundColor3","ELEV"); TReg(CloseBtn,"TextColor3","DIM"); TReg(closeSt,"Color","BORDER")
CloseBtn.MouseEnter:Connect(function() Tw(CloseBtn,{BackgroundColor3=C.CLOSE,BackgroundTransparency=0,TextColor3=Color3.new(1,1,1)},0.14); Tw(closeSt,{Color=C.CLOSE,Transparency=0},0.14) end)
CloseBtn.MouseLeave:Connect(function() Tw(CloseBtn,{BackgroundColor3=C.ELEV,BackgroundTransparency=0.25,TextColor3=C.DIM},0.14); Tw(closeSt,{Color=C.BORDER,Transparency=0.5},0.14) end)
CloseBtn.MouseButton1Click:Connect(PopOut)
local HDiv=Instance.new("Frame",Main); HDiv.Size=UDim2.new(1,0,0,1); HDiv.Position=UDim2.new(0,0,0,52)
HDiv.BackgroundColor3=C.BORDER; HDiv.BackgroundTransparency=0.5; HDiv.BorderSizePixel=0; TReg(HDiv,"BackgroundColor3","BORDER")

local BODY_Y=53; local SIDE_W=132; local CONT_X=SIDE_W+1; local BODY_H=WH-BODY_Y
do
    local isDrag=false; local ds,sp; local tX=0; local tY=0; local cX,cY=0,0; local vX,vY=0,0; local K,B=280,52
    Header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            isDrag=true; ds=i.Position; sp={x=Win.Position.X.Offset,y=Win.Position.Y.Offset}
            tX=sp.x; tY=sp.y; cX=sp.x; cY=sp.y; vX=0; vY=0
        end
    end)
    TC(UIS.InputChanged:Connect(function(i)
        if isDrag and i.UserInputType==Enum.UserInputType.MouseMovement then tX=sp.x+(i.Position.X-ds.X); tY=sp.y+(i.Position.Y-ds.Y) end
    end))
    TC(UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then isDrag=false; vX=0; vY=0 end
    end))
    TC(RunSvc.RenderStepped:Connect(function(dt)
        if _G.KH_PopAnim then cX=Win.Position.X.Offset; cY=Win.Position.Y.Offset; tX=cX; tY=cY; vX=0; vY=0; return end
        local ax=(tX-cX)*K-vX*B; local ay=(tY-cY)*K-vY*B
        vX=vX+ax*dt; vY=vY+ay*dt; cX=cX+vX*dt; cY=cY+vY*dt
        Win.Position=UDim2.new(Win.Position.X.Scale,cX,Win.Position.Y.Scale,cY)
    end))
    ResetWinDrag=function(nx,ny) cX=nx;cY=ny;tX=nx;tY=ny;vX=0;vY=0 end
end

-- ════════════════════════════════════════
-- SIDEBAR + CONTENT
-- ════════════════════════════════════════
local Sidebar=Instance.new("ScrollingFrame",Main); Sidebar.Size=UDim2.new(0,SIDE_W,0,BODY_H); Sidebar.Position=UDim2.new(0,0,0,BODY_Y)
Sidebar.BackgroundTransparency=1; Sidebar.BorderSizePixel=0; Sidebar.ScrollBarThickness=2; Sidebar.ScrollBarImageColor3=C.ACCENT
Sidebar.AutomaticCanvasSize=Enum.AutomaticSize.Y; Sidebar.CanvasSize=UDim2.new(0,0,0,0); Sidebar.ClipsDescendants=true; LP(Sidebar,8,8,8,8); LL(Sidebar,3)
local SDiv=Instance.new("Frame",Main); SDiv.Size=UDim2.new(0,1,0,BODY_H); SDiv.Position=UDim2.new(0,SIDE_W,0,BODY_Y)
SDiv.BackgroundColor3=C.BORDER; SDiv.BackgroundTransparency=0.5; SDiv.BorderSizePixel=0; TReg(SDiv,"BackgroundColor3","BORDER")
local Content=Instance.new("Frame",Main); Content.Size=UDim2.new(0,WW-CONT_X,0,BODY_H); Content.Position=UDim2.new(0,CONT_X,0,BODY_Y)
Content.BackgroundTransparency=1; Content.BorderSizePixel=0; Content.ClipsDescendants=true

-- ════════════════════════════════════════
-- TABS  (20)
-- ════════════════════════════════════════
local TABS={
    {n="Home",i="🏠"},{n="Combat",i="⚔️"},{n="Movement",i="🏃"},{n="TPWalk",i="⚡"},
    {n="Orbit",i="💫"},{n="RPColor",i="💬"},{n="Aimlock",i="🔫"},{n="Glitch",i="🔥"},
    {n="Spin",i="🔁"},{n="Visuals",i="👁️"},{n="Misc",i="🎈"},{n="Themes",i="🎨"},
    {n="Settings",i="⚙️"},{n="Tools",i="⚒️"},{n="Keybinds",i="⌨️"},{n="Players",i="👥"},
    {n="Stats",i="📊"},{n="Bookmarks",i="📍"},{n="Emotes",i="🕺"},{n="Macros",i="🎬"},
}

local tabBtns={}; local tabPanels={}
for i,t in ipairs(TABS) do
    local b=MkBtn(Sidebar,{bg=C.BG,text="",bgt=1,sz=UDim2.new(1,0,0,40),corner=6,bgkey="BG"}); b.LayoutOrder=i
    local bar=Instance.new("Frame",b); bar.Size=UDim2.new(0,3,0,24); bar.Position=UDim2.new(0,0,0.5,-12)
    bar.BackgroundColor3=C.ACCENT; bar.BackgroundTransparency=1; bar.BorderSizePixel=0; Cnr(bar,2); TReg(bar,"BackgroundColor3","ACCENT")
    local glow=Strk(b,C.ACCENT,1.5,1); TReg(glow,"Color","ACCENT")
    local ic=MkLabel(b,{text=t.i,size=13,color=C.DIM,font=Bold,sz=UDim2.new(0,22,1,0),pos=UDim2.new(0,9,0,0),xa=Enum.TextXAlignment.Center,tkey="DIM"})
    local nl=MkLabel(b,{text=t.n:upper(),size=8,color=C.MUTED,font=Bold,sz=UDim2.new(1,-36,1,0),pos=UDim2.new(0,35,0,0),tkey="MUTED"})
    b.MouseEnter:Connect(function() if activeTab~=i then Tw(glow,{Transparency=0.28},0.14); Tw(b,{BackgroundTransparency=0.75},0.12) end end)
    b.MouseLeave:Connect(function() if activeTab~=i then Tw(glow,{Transparency=1},0.14); Tw(b,{BackgroundTransparency=1},0.12) end end)
    tabBtns[i]={btn=b,ic=ic,nl=nl,bar=bar,glow=glow}
    local panel=Instance.new("ScrollingFrame",Content); panel.Size=UDim2.new(1,0,1,0); panel.Position=UDim2.new(1,0,0,0)
    panel.BackgroundTransparency=1; panel.BorderSizePixel=0; panel.ScrollBarThickness=3; panel.ScrollBarImageColor3=C.ACCENT
    panel.AutomaticCanvasSize=Enum.AutomaticSize.Y; panel.CanvasSize=UDim2.new(0,0,0,0)
    panel.ClipsDescendants=true; panel.Visible=false; LP(panel,14,14,12,24); LL(panel,8); tabPanels[i]=panel
end

local transiting=false
GoTab=function(idx)
    if activeTab==idx or transiting then return end
    transiting=true; local prev=activeTab; activeTab=idx
    if SubLbl then SubLbl.Text=QUIPS[math.random(#QUIPS)] end
    for i,tb in ipairs(tabBtns) do
        local a=(i==idx)
        Tw(tb.btn,{BackgroundTransparency=a and 0.05 or 1,BackgroundColor3=a and C.ELEV or C.BG},0.16)
        Tw(tb.nl,{TextColor3=a and C.TEXT or C.MUTED},0.16); Tw(tb.ic,{TextColor3=a and C.ACCENT or C.DIM},0.16)
        Tw(tb.bar,{BackgroundTransparency=a and 0 or 1},0.2); Tw(tb.glow,{Transparency=a and 0.35 or 1},0.16)
    end
    local dir=(prev and idx>prev) and 1 or -1
    local np=tabPanels[idx]; local op=prev and tabPanels[prev]
    np.Position=UDim2.new(dir,0,0,0); np.Visible=true
    local ti=TweenInfo.new(PERF and 0 or 0.24,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
    if op then TweenSvc:Create(op,ti,{Position=UDim2.new(-dir,0,0,0)}):Play() end
    local t2=TweenSvc:Create(np,ti,{Position=UDim2.new(0,0,0,0)}); t2:Play()
    t2.Completed:Connect(function()
        if op then op.Visible=false; op.Position=UDim2.new(1,0,0,0) end; transiting=false
    end)
end

for i in ipairs(tabBtns) do local idx=i; tabBtns[i].btn.MouseButton1Click:Connect(function() GoTab(idx) end) end

TBtn.MouseButton1Click:Connect(function()
    if tbDragDist>6 then tbDragDist=0; return end; tbDragDist=0
    if guiOpen then PopOut() else PopIn() end
end)
CloseBtn.MouseButton1Click:Connect(PopOut)
TC(UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.Insert then if guiOpen then PopOut() else PopIn() end end end))

local jpVal=50
local function ApplyJump(v)
    pcall(function() local h=lp.Character:FindFirstChildOfClass("Humanoid"); h.UseJumpPower=true; h.JumpPower=v end)
end
lp.CharacterAdded:Connect(function() task.wait(0.5); ApplyJump(jpVal) end)

local function Unload()
    _G.KH_PopAnim=true
    local fadeOver=Instance.new("Frame",GUI); fadeOver.Size=UDim2.new(1,0,1,0); fadeOver.BackgroundColor3=Color3.new(0,0,0)
    fadeOver.BackgroundTransparency=1; fadeOver.BorderSizePixel=0; fadeOver.ZIndex=9999
    Tw(fadeOver,{BackgroundTransparency=0},0.55,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
    task.delay(0.60,function()
        for _,c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
        DoSave(); GUI:Destroy(); _G.KH_PopAnim=false
    end)
end


-- ═══════════════════════════════════════════════════════
-- TAB 1 · HOME
-- ═══════════════════════════════════════════════════════
do
    local P = tabPanels[1]

    local wc = MkCard(P, 84, 1)
    MkLabel(wc, {text="Welcome back,", size=9, color=C.MUTED, font=Reg, sz=UDim2.new(1,-28,0,14), pos=UDim2.new(0,14,0,10), tkey="MUTED"})
    local wnLbl = MkLabel(wc, {text=lp.DisplayName, size=20, color=C.TEXT, font=Bold, sz=UDim2.new(1,-28,0,28), pos=UDim2.new(0,14,0,24)})
    MkLabel(wc, {text=QUIPS[math.random(#QUIPS)], size=8, color=C.DIM, font=Reg, sz=UDim2.new(1,-28,0,11), pos=UDim2.new(0,14,0,55), pulse=true, tkey="DIM"})

    local wnH = 0
    TC(RunSvc.Heartbeat:Connect(function(dt)
        wnH = (wnH + dt * 0.4) % 1
        wnLbl.TextColor3 = Color3.fromHSV(wnH, 1, 1)
    end))

    local ic = MkCard(P, 215, 2)

    local avF = Instance.new("Frame", ic)
    avF.Size = UDim2.new(0, 56, 0, 56)
    avF.Position = UDim2.new(0, 14, 0, 14)
    avF.BackgroundColor3 = C.RAISED
    avF.BackgroundTransparency = 0.18
    avF.BorderSizePixel = 0
    Cnr(avF, 10)
    Strk(avF, C.ACCENT, 1, 0.4)
    TReg(avF, "BackgroundColor3", "RAISED")

    local avImg = Instance.new("ImageLabel", avF)
    avImg.Size = UDim2.new(1, 0, 1, 0)
    avImg.BackgroundTransparency = 1
    Cnr(avImg, 10)

    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok then avImg.Image = img end
    end)

    local premT = "Standard"
    pcall(function()
        if lp.MembershipType == Enum.MembershipType.Premium then premT = "Premium" end
    end)

    local joinDate = "—"
    pcall(function()
        local d = os.date("*t", os.time() - lp.AccountAge * 86400)
        joinDate = string.format("%d/%d/%d", d.month, d.day, d.year)
    end)

    local rows = {
        {"DISPLAY NAME", lp.DisplayName},
        {"USERNAME", "@" .. lp.Name},
        {"USER ID", tostring(lp.UserId)},
        {"ACCOUNT AGE", lp.AccountAge .. " days"},
        {"JOIN DATE", joinDate},
        {"MEMBERSHIP", premT}
    }

    for idx, row in ipairs(rows) do
        local y = (idx-1) * 30 + 14
        MkLabel(ic, {text=row[1], size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-82,0,10), pos=UDim2.new(0,80,0,y), pulse=true, tkey="DIM"})
        MkLabel(ic, {text=row[2], size=11, color=C.TEXT, font=Semi, sz=UDim2.new(1,-82,0,17), pos=UDim2.new(0,80,0,y+11), tkey="TEXT"})
    end

    local bc = MkCard(P, 110, 3)
    MkLabel(bc, {text="BIO", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,8), pulse=true, tkey="DIM"})
    local bt = MkLabel(bc, {
        text="Loading bio...",
        size=10,
        color=C.MUTED,
        font=Reg,
        sz=UDim2.new(1,-28,0,90),
        pos=UDim2.new(0,14,0,21),
        wrap=true,
        ya=Enum.TextYAlignment.Top,
        tkey="MUTED"
    })

    task.spawn(function()
        task.wait(0.6)

        local endpoints = {
            "https://proxy.roproxy.com/v1/users/",
            "https://users.roproxy.com/v1/users/"
        }

        local data = nil

        for _, base in ipairs(endpoints) do
            local success, response = pcall(function()
                return Http:GetAsync(base .. lp.UserId)
            end)

            if success and response then
                local ok, decoded = pcall(function()
                    return Http:JSONDecode(response)
                end)

                if ok and decoded then
                    data = decoded
                    break
                end
            end
        end

        if data and data.description then
            if #data.description > 0 then
                bt.Text = data.description
            else
                bt.Text = "No description set."
            end
        else
            bt.Text = "Failed to load bio."
        end
    end)

    local aKC = MkCard(P, 148, 4)
    MkLabel(aKC, {text="ABOUT KORE HUB", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,8), pulse=true, tkey="DIM"})
    MkLabel(aKC, {
        text = "KoreHub v7.10  ·  Build 10\n\n" ..
               "Built for players who want clean tools without the clutter. " ..
               "Fast kill aura, a wide selection of themes that remember your choice, " ..
               "and a full keybind system so everything feels natural under your fingers.\n\n" ..
               "I focused on making it stable, responsive, and pleasant to use — " ..
               "the kind of script you open and just feel at home with.\n\n" ..
               "Press INSERT to toggle the interface. Drag the header to move it around." ..
               "Made with love by kore. 🤍",
        size = 9,
        color = C.MUTED,
        font = Reg,
        sz = UDim2.new(1, -28, 0, 126),
        pos = UDim2.new(0, 14, 0, 22),
        wrap = true,
        ya = Enum.TextYAlignment.Top,
        tkey = "MUTED"
    })
end

-- ═══════════════════════════════════════════════════════
-- TAB 2 · COMBAT
-- ═══════════════════════════════════════════════════════
do
    local P = tabPanels[2]

    -- State
    local kaOn = false
    local kaAPS = 5000
    local kaCD = 1 / kaAPS
    local kaRange = 500
    local kaHeadOn = false
    local kaAFling = false
    local safeSpotOn = false

    local kaLast = 0
    local kaTStr = SAVE.kaTargets or ""
    local kaFStr = SAVE.kaFriends or ""
    local kaHStr = SAVE.headSit or ""

    local kaTgts = {}
    local kaFrns = {}
    local kaHds = {}
    local kaManualTgt = {}
    local kaManualFrn = {}

    local SAFE_POS = Vector3.new(-467.351, 39.471, -133.398)
    local SAFE_CFRAME = CFrame.new(SAFE_POS)

    local originalCFrame = nil          -- saved position before enabling safe spot
    local safeLockConn = nil            -- continuous lock connection

    -- Parsing
    local function ParseN(s)
        local t = {}
        if s == "" then return t end
        for nm in s:gsub(",", " "):gmatch("%S+") do
            local n = nm:lower():match("^%s*(.-)%s*$")
            if n and n ~= "" then t[n] = true end
        end
        return t
    end

    local function RefAll()
        kaTgts = ParseN(kaTStr)
        kaFrns = ParseN(kaFStr)
        kaHds = ParseN(kaHStr)
        SAVE.kaTargets = kaTStr
        SAVE.kaFriends = kaFStr
        SAVE.headSit = kaHStr
        DoSave()
    end
    RefAll()

    local function IsFriend(p)
        if kaManualFrn[p] then return true end
        local nl = p.Name:lower()
        local dn = p.DisplayName:lower()
        return kaFrns[nl] or kaFrns[dn]
    end

    local function IsTarget(p)
        if p == lp then return false end
        if IsFriend(p) then return false end
        if kaManualTgt[p] then return true end
        if kaTStr == "" then return true end

        local nl = p.Name:lower()
        local dn = p.DisplayName:lower()
        if kaTgts[nl] or kaTgts[dn] then return true end
        for k in pairs(kaTgts) do
            if nl:find(k, 1, true) or dn:find(k, 1, true) then return true end
        end
        return false
    end

    local function IsHeadSitTarget(p)
        if p == lp or kaHStr == "" then return false end
        local nl = p.Name:lower()
        local dn = p.DisplayName:lower()
        if kaHds[nl] or kaHds[dn] then return true end
        for k in pairs(kaHds) do
            if nl:find(k, 1, true) or dn:find(k, 1, true) then return true end
        end
        return false
    end

    -- Safe Spot Lock (makes it truly float and locked in place)
    local function startSafeLock()
        if safeLockConn then safeLockConn:Disconnect() end
        safeLockConn = TC(RunSvc.Heartbeat:Connect(function()
            if not safeSpotOn then return end
            local myC = lp.Character
            local myH = myC and myC:FindFirstChild("HumanoidRootPart")
            if myH then
                myH.CFrame = SAFE_CFRAME
                myH.AssemblyLinearVelocity = Vector3.zero
                myH.AssemblyAngularVelocity = Vector3.zero
            end
        end))
    end

    local function stopSafeLock()
        if safeLockConn then safeLockConn:Disconnect(); safeLockConn = nil end
    end

    -- Go to safe spot + save original position
    local function goToSafeSpot()
        local myC = lp.Character
        local myH = myC and myC:FindFirstChild("HumanoidRootPart")
        if not myH then return end

        -- Save current position so we can return later
        originalCFrame = myH.CFrame

        -- Teleport and lock
        myH.CFrame = SAFE_CFRAME
        myH.AssemblyLinearVelocity = Vector3.zero
        myH.AssemblyAngularVelocity = Vector3.zero
        myH.CanCollide = false

        pcall(function()
            local hum = myC:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = true
                workspace.CurrentCamera.CameraSubject = hum
            end
        end)

        startSafeLock()
    end

    -- Disable safe spot + return to original position
    local function disableSafeSpot()
        stopSafeLock()

        if originalCFrame then
            local myC = lp.Character
            local myH = myC and myC:FindFirstChild("HumanoidRootPart")
            if myH then
                myH.CFrame = originalCFrame
                myH.AssemblyLinearVelocity = Vector3.zero
                myH.AssemblyAngularVelocity = Vector3.zero
                myH.CanCollide = true

                pcall(function()
                    local hum = myC:FindFirstChildOfClass("Humanoid")
                    if hum then hum.PlatformStand = false end
                end)
            end
            originalCFrame = nil
        end
    end

    -- Anti-Fling
    local afConn
    local function StartAF()
        if afConn then afConn:Disconnect() end
        afConn = TC(RunSvc.Heartbeat:Connect(function()
            local c = lp.Character
            if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if hrp.AssemblyLinearVelocity.Magnitude > 120 then
                hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity * 0.78
            end
            if hrp.AssemblyAngularVelocity.Magnitude > 18 then
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end))
    end

    local function StopAF()
        if afConn then afConn:Disconnect(); afConn = nil end
    end

    -- Non-blocking remote fire
    local function HitRemoteInvoke(hum, px, py, pz)
        task.spawn(function()
            pcall(function()
                if HitRF then
                    HitRF:InvokeServer(unpack({hum, vector.create(px, py, pz)}))
                end
            end)
        end)
    end

    -- Main Kill Aura Loop
    local kaConn
    local function StartKA()
        if kaConn then kaConn:Disconnect() end
        kaConn = TC(RunSvc.Heartbeat:Connect(function()
            if not kaOn then return end

            local mc = lp.Character
            local myHRP = mc and mc:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end

            local now = tick()
            if now - kaLast < kaCD then return end

            local px, py, pz = myHRP.Position.X, myHRP.Position.Y, myHRP.Position.Z

            -- Head Sit
            if kaHeadOn then
                for _, p in Players:GetPlayers() do
                    if IsHeadSitTarget(p) and p.Character then
                        local head = p.Character:FindFirstChild("Head")
                        if head and (head.Position - myHRP.Position).Magnitude <= kaRange then
                            myHRP.CFrame = CFrame.new(head.Position + Vector3.new(0, 3, 0))
                        end
                    end
                end
            end

            -- Collect targets (closest only)
            local targets = {}
            local hitAny = false

            local cls, mind = nil, math.huge
            for _, p in Players:GetPlayers() do
                if not IsTarget(p) then continue end
                local c = p.Character
                if not c then continue end
                local hu = c:FindFirstChild("Humanoid")
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if hu and hrp and hu.Health > 0 then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d <= kaRange and d < mind then
                        mind = d
                        cls = {hu = hu, px = hrp.Position.X, py = hrp.Position.Y, pz = hrp.Position.Z}
                    end
                end
            end
            if cls then
                table.insert(targets, cls)
                hitAny = true
            end

            if hitAny and #targets > 0 then
                task.spawn(function()
                    for _, td in ipairs(targets) do
                        HitRemoteInvoke(td.hu, td.px, td.py, td.pz)
                    end
                end)

                for _, td in ipairs(targets) do
                    local hrp = td.hu.Parent and td.hu.Parent:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        pcall(ShowHitVFX, hrp)
                    end
                end

                kaLast = now
            end
        end))
    end

    -- UI
    local kc = MkCard(P, 52, 1)
    MkLabel(kc, {text = "KILL AURA", size = 7, color = C.DIM, font = Bold,
        sz = UDim2.new(1, -60, 0, 10), pos = UDim2.new(0, 14, 0, 8), pulse = true, tkey = "DIM"})

    local kSt = MkLabel(kc, {text = "INACTIVE", size = 13, color = C.MUTED, font = Bold,
        sz = UDim2.new(1, -60, 0, 20), pos = UDim2.new(0, 14, 0, 22), tkey = "MUTED"})

    local kPill, _, kSet = MkPill(kc)

    local function ToggleKA()
        kaOn = not kaOn
        kSet(kaOn)
        kSt.Text = kaOn and "ACTIVE" or "INACTIVE"
        Tw(kSt, {TextColor3 = kaOn and C.ACCENT or C.MUTED}, 0.14)

        if kaOn then
            StartKA()
            ShowNotif("Kill Aura", "Activated · APS "..math.floor(kaAPS), "kill")
        else
            ShowNotif("Kill Aura", "Deactivated", "info")
        end
    end

    kPill.MouseButton1Click:Connect(ToggleKA)
    RegisterKeybind("Toggle Kill Aura", Enum.KeyCode.K, ToggleKA, "Combat")

    -- Status
    local sC = MkCard(P, 24, 2)
    local stLbl = MkLabel(sC, {text = "0 sel · APS 5000 · range 500", size = 8, color = C.MUTED, font = Reg,
        sz = UDim2.new(1, -16, 1, 0), pos = UDim2.new(0, 12, 0, 0), tkey = "MUTED"})

    local function updSt()
        local n = 0
        for _ in pairs(kaManualTgt) do n = n + 1 end
        stLbl.Text = n .. " sel · APS " .. math.floor(kaAPS) .. " · range " .. kaRange
    end

    MkToggleCard(P, "ANTI-FLING", 3, function() kaAFling = true; StartAF() end, function() kaAFling = false; StopAF() end)

    -- Safe Spot Toggle + Keybind
    local function ToggleSafeSpot()
        safeSpotOn = not safeSpotOn
        if safeSpotOn then
            goToSafeSpot()
        else
            disableSafeSpot()
        end
    end

    MkToggleCard(P, "SAFE SPOT", 4,
        function() safeSpotOn = true; goToSafeSpot() end,
        function() safeSpotOn = false; disableSafeSpot() end
    )

    RegisterKeybind("Toggle Safe Spot", Enum.KeyCode.V, ToggleSafeSpot, "Combat")

    MkSliderCard(P, "ATTACKS/s", 1, 5000, 5000, 5, function(v)
        kaAPS = v
        kaCD = 1 / v
        updSt()
    end)

    MkSliderCard(P, "RANGE", 5, 500, 500, 6, function(v)
        kaRange = v
        updSt()
    end)

    MkSliderCard(P, "HITBOX EXPANDER", 0, 25, 0, 7, function(v)
        for _, p in Players:GetPlayers() do
            if p == lp then continue end
            local c = p.Character
            if not c then continue end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    local s = v < 1 and 2 or v
                    hrp.Size = Vector3.new(s, s, s)
                end)
            end
        end
    end)

    -- Hitbox Collision Off
    local hbConn
    MkToggleCard(P, "HITBOX COLLISION OFF", 8,
        function()
            local function setNC(p)
                if p == lp then return end
                local c = p.Character
                if not c then return end
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.CanCollide = false end) end
            end
            for _, p in Players:GetPlayers() do setNC(p) end
            hbConn = TC(Players.PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(function() task.wait(0.5); setNC(p) end)
            end))
        end,
        function()
            if hbConn then hbConn:Disconnect(); hbConn = nil end
            for _, p in Players:GetPlayers() do
                if p == lp then continue end
                local c = p.Character
                if not c then continue end
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.CanCollide = true end) end
            end
        end
    )

    -- Textboxes
    local _, tgBox = MkTBoxCard(P, "TARGETS (saved)", "player1 player2 ...", 9)
    tgBox.Text = kaTStr
    tgBox.FocusLost:Connect(function() kaTStr = tgBox.Text; RefAll(); updSt() end)

    local _, frBox = MkTBoxCard(P, "FRIENDS (saved)", "player1 player2 ...", 10)
    frBox.Text = kaFStr
    frBox.FocusLost:Connect(function() kaFStr = frBox.Text; RefAll() end)

    MkToggleCard(P, "HEAD SIT", 11, function() kaHeadOn = true end, function() kaHeadOn = false end)
    local _, hsBox = MkTBoxCard(P, "HEAD SIT TARGETS (saved)", "player1 player2 ...", 12)
    hsBox.Text = kaHStr
    hsBox.FocusLost:Connect(function() kaHStr = hsBox.Text; RefAll() end)

    -- Player List
    local plC = MkCard(P, 230, 13)
    MkLabel(plC, {text = "PLAYERS  ·  L-click = target   R-click = friend", size = 7, color = C.DIM, font = Bold,
        sz = UDim2.new(1, -28, 0, 10), pos = UDim2.new(0, 14, 0, 7), pulse = true, tkey = "DIM"})

    local pSF = Instance.new("ScrollingFrame", plC)
    pSF.Size = UDim2.new(1, -24, 0, 206)
    pSF.Position = UDim2.new(0, 12, 0, 20)
    pSF.BackgroundTransparency = 1
    pSF.ScrollBarThickness = 2
    pSF.ScrollBarImageColor3 = C.ACCENT
    pSF.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pSF.CanvasSize = UDim2.new(0, 0, 0, 0)
    pSF.BorderSizePixel = 0
    pSF.ClipsDescendants = true
    LL(pSF, 2)

    local function RefList()
        for _, v in pSF:GetChildren() do
            if v:IsA("Frame") then v:Destroy() end
        end
        for _, p in Players:GetPlayers() do
            if p == lp then continue end
            local fr = kaManualFrn[p]
            local tg = kaManualTgt[p]

            local row = Instance.new("Frame", pSF)
            row.Size = UDim2.new(1, 0, 0, 34)
            row.BackgroundColor3 = C.RAISED
            row.BackgroundTransparency = 0.2
            row.BorderSizePixel = 0
            Cnr(row, 6)
            TReg(row, "BackgroundColor3", "RAISED")

            if fr then
                Strk(row, Color3.fromRGB(50, 175, 90), 1, 0.18)
            elseif tg then
                Strk(row, Color3.fromRGB(175, 50, 50), 1, 0.18)
            end

            MkLabel(row, {text = fr and "F" or (tg and "T" or "·"), size = 8,
                color = fr and Color3.fromRGB(50, 195, 90) or (tg and Color3.fromRGB(195, 70, 70) or C.DIM),
                font = Bold, sz = UDim2.new(0, 22, 1, 0), pos = UDim2.new(0, 4, 0, 0), xa = Enum.TextXAlignment.Center})

            MkLabel(row, {text = p.DisplayName, size = 10, color = C.TEXT, font = Semi,
                sz = UDim2.new(1, -40, 0, 17), pos = UDim2.new(0, 28, 0, 2), tkey = "TEXT"})

            MkLabel(row, {text = "@" .. p.Name, size = 8, color = C.DIM, font = Reg,
                sz = UDim2.new(1, -40, 0, 13), pos = UDim2.new(0, 28, 0, 19), tkey = "DIM"})

            local rb = Instance.new("TextButton", row)
            rb.Size = UDim2.new(1, 0, 1, 0)
            rb.BackgroundTransparency = 1
            rb.Text = ""

            rb.MouseButton1Click:Connect(function()
                if kaManualFrn[p] then return end
                kaManualTgt[p] = not kaManualTgt[p] and true or nil
                RefList()
                updSt()
            end)

            rb.MouseButton2Click:Connect(function()
                kaManualTgt[p] = nil
                kaManualFrn[p] = not kaManualFrn[p] and true or nil
                RefList()
            end)
        end
        updSt()
    end

    RefList()
    Players.PlayerAdded:Connect(RefList)
    Players.PlayerRemoving:Connect(function(p)
        kaManualTgt[p] = nil
        kaManualFrn[p] = nil
        RefList()
    end)

    updSt()
end

-- ═══════════════════════════════════════════════════════
-- TAB 3 · MOVEMENT
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[3]
    MkSliderCard(P,"WALKSPEED",1,500,16,1,function(v) pcall(function() lp.Character:FindFirstChildOfClass("Humanoid").WalkSpeed=v end) end)
    local flyOn=false; local flyConn; local fbv,fbg; local flySpd=60
    local _,_,flySet,flySt=MkToggleCard(P,"FLY  ·  WASD + SPACE/SHIFT",2,
        function()
            local char=lp.Character; if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local h=char:FindFirstChildOfClass("Humanoid"); if h then h.PlatformStand=true end
            fbv=Instance.new("BodyVelocity",hrp); fbv.MaxForce=Vector3.new(1e5,1e5,1e5); fbv.Velocity=Vector3.zero
            fbg=Instance.new("BodyGyro",hrp); fbg.MaxTorque=Vector3.new(1e5,1e5,1e5); fbg.D=150; flyOn=true
            flyConn=TC(RunSvc.RenderStepped:Connect(function()
                local cam=workspace.CurrentCamera; if not cam then return end; local v=Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then v=v+cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then v=v-cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then v=v-cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then v=v+cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then v=v+Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then v=v-Vector3.new(0,1,0) end
                if v.Magnitude>0 then v=v.Unit*flySpd end; fbv.Velocity=v; fbg.CFrame=cam.CFrame
            end))
            ShowNotif("Fly","Enabled · WASD to fly","success")
        end,
        function()
            flyOn=false; if flyConn then flyConn:Disconnect(); flyConn=nil end
            pcall(function() fbv:Destroy() end); pcall(function() fbg:Destroy() end)
            pcall(function() lp.Character:FindFirstChildOfClass("Humanoid").PlatformStand=false end)
            ShowNotif("Fly","Disabled","info")
        end
    )
    lp.CharacterAdded:Connect(function() flyOn=false; flySet(false,true); if flySt then flySt.Text="DISABLED"; flySt.TextColor3=C.MUTED end end)
    MkSliderCard(P,"FLY SPEED",1,350,60,3,function(v) flySpd=v end)
    MkSliderCard(P,"JUMP POWER",1,500,50,4,function(v) jpVal=v; ApplyJump(v) end)
    MkSliderCard(P,"GRAVITY",1,600,196,5,function(v) pcall(function() workspace.Gravity=v end) end)

    local tpC=MkCard(P,82,6)
    MkLabel(tpC,{text="TELEPORT TO PLAYER",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local tpBtn=MkBtn(tpC,{bg=C.ACCENT,text="TP",size=10,color=C.BG,sz=UDim2.new(0,62,0,28),pos=UDim2.new(1,-14,0,27),anchor=Vector2.new(1,0),corner=6,bgt=0.05,bgkey="ACCENT",tkey="BG"})
    local tpBox=MkTBox(tpC,"Player name or display name...",27,-90)
    tpBtn.MouseButton1Click:Connect(function()
        local tgt=FindPlayer(tpBox.Text); if not tgt or not tgt.Character then ShowNotif("Teleport","Player not found","error"); return end
        local th=tgt.Character:FindFirstChild("HumanoidRootPart"); if not th then return end
        local mc=lp.Character; if not mc then return end; local mh=mc:FindFirstChild("HumanoidRootPart"); if not mh then return end
        mh.CFrame=th.CFrame*CFrame.new(0,0,-3); ShowNotif("Teleport","→ "..tgt.DisplayName,"success")
    end)

    local coordC=MkCard(P,82,7)
    MkLabel(coordC,{text="TELEPORT TO COORDINATES",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local goBtn=MkBtn(coordC,{bg=C.ACCENT,text="GO",size=10,color=C.BG,sz=UDim2.new(0,62,0,28),pos=UDim2.new(1,-14,0,27),anchor=Vector2.new(1,0),corner=6,bgt=0.05,bgkey="ACCENT",tkey="BG"})
    local coordBox=MkTBox(coordC,"X, Y, Z  (e.g. 100, 20, -300)",27,-90)
    goBtn.MouseButton1Click:Connect(function()
        local nums={}; for n in coordBox.Text:gmatch("%-?%d+%.?%d*") do table.insert(nums,tonumber(n)) end
        if #nums>=3 then
            local mc=lp.Character; if not mc then return end; local mh=mc:FindFirstChild("HumanoidRootPart"); if not mh then return end
            mh.CFrame=CFrame.new(nums[1],nums[2],nums[3])
            ShowNotif("Teleport",string.format("→ %.0f, %.0f, %.0f",nums[1],nums[2],nums[3]),"success")
        else ShowNotif("Teleport","Enter valid X Y Z","error") end
    end)
end

-- ═══════════════════════════════════════════════════════
-- TAB 4 · TPWALK
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[4]; local tpwOn=false; local curMode="Smooth"; local tpSpd=4; local stepDist=4; local tpConn; local tpStat
    local function stopTP()
        tpwOn=false; if tpConn then tpConn:Disconnect(); tpConn=nil end
        if tpStat then tpStat.Text="INACTIVE"; Tw(tpStat,{TextColor3=C.MUTED},0.14) end
    end
    local function startTP()
        stopTP(); local char=lp.Character; if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildWhichIsA("Humanoid")
        if not (hrp and hum and hum.Health>0) then return end; tpwOn=true
        if tpStat then tpStat.Text="ACTIVE"; Tw(tpStat,{TextColor3=C.ACCENT},0.14) end
        tpConn=TC(RunSvc.Heartbeat:Connect(function(dt)
            if not tpwOn then return end; local ch=lp.Character; if not ch then stopTP(); return end
            local h=ch:FindFirstChild("HumanoidRootPart"); local hu=ch:FindFirstChildWhichIsA("Humanoid")
            if not (h and hu and hu.Health>0) then stopTP(); return end
            local md=hu.MoveDirection; if md.Magnitude<0.01 then return end; md=md.Unit
            pcall(function()
                if curMode=="Smooth" then ch:TranslateBy(md*tpSpd*dt*10)
                elseif curMode=="Step" then h.CFrame=h.CFrame+(md*stepDist)
                elseif curMode=="Ghost" then h.CFrame=h.CFrame+(md*stepDist*0.5)
                elseif curMode=="Blink" then h.CFrame=h.CFrame+(md*stepDist*3); task.wait(0.06) end
            end)
        end))
    end
    local modeCard=MkCard(P,70,1)
    MkLabel(modeCard,{text="MODE",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local modeRow=Instance.new("Frame",modeCard); modeRow.Size=UDim2.new(1,-28,0,28); modeRow.Position=UDim2.new(0,14,0,32)
    modeRow.BackgroundTransparency=1; modeRow.BorderSizePixel=0
    local mLL=Instance.new("UIListLayout",modeRow); mLL.FillDirection=Enum.FillDirection.Horizontal; mLL.SortOrder=Enum.SortOrder.LayoutOrder; mLL.Padding=UDim.new(0,5)
    local modes={"Smooth","Step","Ghost","Blink"}; local mBtns={}
    for i,m in ipairs(modes) do
        local active=(m==curMode)
        local mb=MkBtn(modeRow,{text=m,size=9,bg=active and C.ACCENT or C.ELEV,color=active and C.BG or C.TEXT,sz=UDim2.new(0.24,-4,1,0),corner=5,bgt=0,order=i})
        mb.MouseButton1Click:Connect(function()
            curMode=m
            for j,b in ipairs(mBtns) do Tw(b,{BackgroundColor3=(j==i) and C.ACCENT or C.ELEV,TextColor3=(j==i) and C.BG or C.TEXT},0.18) end
            if tpwOn then startTP() end
        end); mBtns[i]=mb
    end
    local function ToggleTPW()
        if tpwOn then stopTP() else startTP() end
        ShowNotif("TPWalk",tpwOn and "Activated" or "Deactivated",tpwOn and "success" or "info")
    end
    local _,_,_,s4=MkToggleCard(P,"TPWALK",2,startTP,stopTP,true)
    tpStat=s4; tpStat.Text="INACTIVE"; tpStat.TextColor3=C.MUTED
    RegisterKeybind("Toggle TPWalk", Enum.KeyCode.T, ToggleTPW, "Movement")
    MkSliderCard(P,"SPEED  (smooth)",1,80,4,3,function(v) tpSpd=v end)
    MkSliderCard(P,"STEP / GHOST / BLINK DIST",1,14,4,4,function(v) stepDist=v end)
    lp.CharacterAdded:Connect(stopTP); lp.CharacterRemoving:Connect(stopTP)
end

-- ═══════════════════════════════════════════════════════
-- TAB 5 · ORBIT
-- ═══════════════════════════════════════════════════════
do
    local P = tabPanels[5]

    local orbSpd = 2
    local orbRad = 2
    local orbH = 0
    local orbOn = false
    local orbAngle = 0
    local orbConn
    local orbWait

    local SAFE_POS = Vector3.new(-467.351, 39.471, -133.398)
    local SAFE_CFRAME = CFrame.new(SAFE_POS)

    local orbCard = MkCard(P, 52, 1)
    MkLabel(orbCard, {text="ORBIT PLAYER",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local orbSt = MkLabel(orbCard, {text="INACTIVE",size=13,color=C.MUTED,font=Bold,sz=UDim2.new(1,-60,0,20),pos=UDim2.new(0,14,0,22),tkey="MUTED"})
    local orbPill,_,orbSet = MkPill(orbCard)

    local _, otBox = MkTBoxCard(P,"TARGET PLAYER","player name ...",2)

    MkSliderCard(P,"ORBIT SPEED",1,1000,2,3,function(v) orbSpd=v end)
    MkSliderCard(P,"ORBIT RADIUS",1,50,2,4,function(v) orbRad=v end)
    MkSliderCard(P,"HEIGHT OFFSET",-10,10,0,5,function(v) orbH=v end)

    local function stopOrbit()
        orbOn = false
        if orbConn then orbConn:Disconnect(); orbConn = nil end
        if orbWait then orbWait:Disconnect(); orbWait = nil end
        pcall(function()
            local char = lp.Character
            if char then
                workspace.CurrentCamera.CameraSubject = char:FindFirstChildOfClass("Humanoid") or char
            end
        end)
    end

    local function goToSafeSpot()
        local myC = lp.Character
        local myH = myC and myC:FindFirstChild("HumanoidRootPart")
        if not myH then return end

        myH.CFrame = SAFE_CFRAME
        myH.AssemblyLinearVelocity = Vector3.zero
        myH.AssemblyAngularVelocity = Vector3.zero
        myH.CanCollide = false

        pcall(function()
            local hum = myC:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = true
                workspace.CurrentCamera.CameraSubject = hum
            end
        end)
    end

    local function startOrbit()
        stopOrbit()
        local tgt = FindPlayer(otBox.Text)
        if not tgt then return end

        orbOn = true
        orbAngle = 0

        local function loop()
            orbConn = TC(RunSvc.RenderStepped:Connect(function()
                if not orbOn then return end

                local tN = FindPlayer(otBox.Text)
                if not tN then return end

                local tC = tN.Character
                local tH = tC and tC:FindFirstChild("HumanoidRootPart")
                local myC = lp.Character
                local myH = myC and myC:FindFirstChild("HumanoidRootPart")
                if not myH then return end

                if not tH or not tC:FindFirstChildOfClass("Humanoid") or tC:FindFirstChildOfClass("Humanoid").Health <= 0 then
                    goToSafeSpot()
                    return
                end

                orbAngle = orbAngle + math.rad(orbSpd)
                local tp = tH.Position
                myH.CFrame = CFrame.new(
                    tp + Vector3.new(math.cos(orbAngle) * orbRad, orbH, math.sin(orbAngle) * orbRad),
                    tp
                )

                pcall(function()
                    local th2 = tC:FindFirstChildOfClass("Humanoid")
                    if th2 then workspace.CurrentCamera.CameraSubject = th2 end
                end)
            end))
        end

        loop()
    end

    local function ToggleOrbit()
        if orbOn then
            stopOrbit()
            orbSet(false)
            orbSt.Text = "INACTIVE"
            Tw(orbSt, {TextColor3 = C.MUTED}, 0.14)
            ShowNotif("Orbit", "Deactivated", "info")
        else
            local tgt = FindPlayer(otBox.Text)
            if not tgt then
                ShowNotif("Orbit", "Player not found", "error")
                return
            end

            startOrbit()
            orbSet(true)
            orbSt.Text = "ACTIVE"
            Tw(orbSt, {TextColor3 = C.ACCENT}, 0.14)
            ShowNotif("Orbit", "Activated · Orbiting " .. tgt.DisplayName, "orbit")
        end
    end

    orbPill.MouseButton1Click:Connect(ToggleOrbit)
    RegisterKeybind("Toggle Orbit", Enum.KeyCode.O, ToggleOrbit, "Orbit")

    lp.CharacterAdded:Connect(function()
        if orbOn then
            task.wait(1)
            if orbOn then startOrbit() end
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- TAB 6 · RP COLOR
-- ═══════════════════════════════════════════════════════
do
    local P = tabPanels[6]

    local rpOn = false
    local rpConn
    local rpHue = 0
    local rpPhase = 0
    local rpAnimPhaseT = 0
    local rpTypeOn = true
    local rpTypeSpd = 0.25
    local rpBioOn = true
    local rpColorSpd = 1.0
    local rpAnimMode = "None"
    local rpEffMode = "Preset"
    local rpNameIdx = 1
    local rpNameTimer = 0
    local selPreset = nil
    local staticCol = Color3.fromRGB(255, 80, 180)

    -- Rate limits
    local rpLastColor = 0
    local rpLastName = 0
    local rpLastBio = 0
    local RP_COLOR_RATE = 0.05
    local RP_NAME_RATE = 0.1

    -- Expanded Presets (now 48 total)
    local PRESETS = {
        {n="Rainbow",     g=function(dt) rpHue=(rpHue+dt*0.4*rpColorSpd)%1; return Color3.fromHSV(rpHue,1,1) end},
        {n="B→White",     g=function() local w=(math.sin(rpPhase*1.4)+1)/2; return Color3.fromRGB(0,0,0):Lerp(Color3.new(1,1,1),w) end},
        {n="B→Red",       g=function() local w=(math.sin(rpPhase*1.4)+1)/2; return Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(220,30,30),w) end},
        {n="B→Blue",      g=function() local w=(math.sin(rpPhase*1.4)+1)/2; return Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(40,100,255),w) end},
        {n="B→Purple",    g=function() local w=(math.sin(rpPhase*1.4)+1)/2; return Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(140,0,255),w) end},
        {n="B→Pink",      g=function() local w=(math.sin(rpPhase*1.4)+1)/2; return Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(255,80,200),w) end},
        {n="Galaxy",      g=function() local c={Color3.fromRGB(25,0,75),Color3.fromRGB(128,0,255),Color3.new(1,1,1)}; local h2=rpPhase*0.3%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Sunset",      g=function() local c={Color3.fromRGB(255,50,0),Color3.fromRGB(255,200,0),Color3.fromRGB(255,0,128)}; local h2=rpPhase*0.25%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Matrix",      g=function() return math.random()>0.7 and Color3.fromRGB(0,255,0) or Color3.fromRGB(0,40,0) end},
        {n="Aurora",      g=function() local c={Color3.fromRGB(0,200,100),Color3.fromRGB(0,100,255),Color3.fromRGB(100,0,255),Color3.fromRGB(0,200,180)}; local h2=rpPhase*0.18%1; local i=math.floor(h2*3); return c[i+1]:Lerp(c[math.min(i+2,4)],h2*3-i) end},
        {n="Fire",        g=function() local c={Color3.fromRGB(255,0,0),Color3.fromRGB(255,140,0),Color3.fromRGB(255,255,0)}; local h2=rpPhase*0.55%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Ice",         g=function() local c={Color3.fromRGB(200,240,255),Color3.fromRGB(100,200,255),Color3.fromRGB(180,230,255)}; local h2=rpPhase*0.2%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Gold",        g=function() local w=(math.sin(rpPhase*1.2)+1)/2; return Color3.fromRGB(180,130,0):Lerp(Color3.fromRGB(255,220,50),w) end},
        {n="Neon Grn",    g=function() local w=(math.sin(rpPhase*2.0)+1)/2; return Color3.fromRGB(0,60,0):Lerp(Color3.fromRGB(0,255,80),w) end},
        {n="Candy",       g=function() local c={Color3.fromRGB(255,100,180),Color3.fromRGB(100,255,180),Color3.fromRGB(255,200,100)}; local h2=rpPhase*0.3%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Sakura",      g=function() local w=(math.sin(rpPhase*0.8)+1)/2; return Color3.fromRGB(255,182,193):Lerp(Color3.new(1,1,1),w*0.7) end},
        {n="Void",        g=function() return math.random()>0.85 and Color3.fromRGB(80,0,120) or Color3.fromRGB(0,0,0) end},
        {n="Lava",        g=function() local c={Color3.fromRGB(255,0,0),Color3.fromRGB(255,80,0),Color3.fromRGB(200,10,0),Color3.fromRGB(255,200,0)}; local h2=rpPhase*0.45%1; local i=math.floor(h2*3); return c[i+1]:Lerp(c[math.min(i+2,4)],h2*3-i) end},
        {n="Ocean",       g=function() local c={Color3.fromRGB(0,30,90),Color3.fromRGB(0,100,200),Color3.fromRGB(0,220,255),Color3.fromRGB(0,150,180)}; local h2=rpPhase*0.22%1; local i=math.floor(h2*3); return c[i+1]:Lerp(c[math.min(i+2,4)],h2*3-i) end},
        {n="Rose",        g=function() local c={Color3.fromRGB(220,20,80),Color3.fromRGB(255,100,140),Color3.fromRGB(180,0,60)}; local h2=rpPhase*0.38%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Toxic",       g=function() local w=(math.sin(rpPhase*3.0)+1)/2; return Color3.fromRGB(0,0,0):Lerp(Color3.fromRGB(120,255,0),w) end},
        {n="Cosmos",      g=function() local c={Color3.fromRGB(10,0,40),Color3.fromRGB(80,0,200),Color3.fromRGB(0,150,255),Color3.fromRGB(255,255,255),Color3.fromRGB(60,0,180)}; local h2=rpPhase*0.14%1; local i=math.floor(h2*4); return c[i+1]:Lerp(c[math.min(i+2,5)],h2*4-i) end},
        {n="Oil Spill",   g=function() rpHue=(rpHue+0.003*rpColorSpd)%1; return Color3.fromHSV(rpHue,0.95,0.8) end},
        {n="Blizzard",    g=function() local w=(math.sin(rpPhase*1.8)+1)/2; return Color3.fromRGB(160,210,255):Lerp(Color3.new(1,1,1),w) end},
        {n="Crimson",     g=function() local c={Color3.fromRGB(100,0,0),Color3.fromRGB(220,0,30),Color3.fromRGB(255,60,60)}; local h2=rpPhase*0.5%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Neon Wave",   g=function() local c={Color3.fromRGB(255,0,200),Color3.fromRGB(0,255,200),Color3.fromRGB(200,0,255),Color3.fromRGB(0,200,255)}; local h2=rpPhase*0.35%1; local i=math.floor(h2*3); return c[i+1]:Lerp(c[math.min(i+2,4)],h2*3-i) end},
        {n="Hologram",    g=function() local w=(math.sin(rpPhase*4.0)+1)/2; return Color3.fromRGB(0,220,255):Lerp(Color3.fromRGB(200,0,255),w) end},
        {n="Vintage",     g=function() local c={Color3.fromRGB(180,140,80),Color3.fromRGB(220,180,100),Color3.fromRGB(160,110,60)}; local h2=rpPhase*0.2%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Glitch",      g=function() local r={255,0,0,255}; local g2={0,255,0,0}; local b={0,0,255,255}; local i=math.random(1,4); return Color3.fromRGB(r[i],g2[i],b[i]) end},
        {n="Plasma",      g=function() local c={Color3.fromRGB(255,0,100),Color3.fromRGB(100,0,255),Color3.fromRGB(0,200,255),Color3.fromRGB(255,100,0)}; local h2=rpPhase*0.28%1; local i=math.floor(h2*3); return c[i+1]:Lerp(c[math.min(i+2,4)],h2*3-i) end},
        {n="Ember",       g=function() local w=(math.sin(rpPhase*2.5)+1)/2; return Color3.fromRGB(255,60,0):Lerp(Color3.fromRGB(255,220,0),w) end},

        -- New Presets Added
        {n="Cyberpunk",   g=function() rpHue=(rpHue+dt*0.8*rpColorSpd)%1; return Color3.fromHSV(rpHue,1,0.95) end},
        {n="Pastel Dream",g=function() local w=(math.sin(rpPhase*0.9)+1)/2; return Color3.fromRGB(255,180,220):Lerp(Color3.fromRGB(180,255,240),w) end},
        {n="Blood Moon",  g=function() local c={Color3.fromRGB(80,0,0),Color3.fromRGB(180,20,20),Color3.fromRGB(255,60,60)}; local h2=rpPhase*0.4%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Electric",    g=function() return Color3.fromRGB(0,math.random(180,255),255) end},
        {n="Forest Glow", g=function() local c={Color3.fromRGB(20,80,30),Color3.fromRGB(80,200,100),Color3.fromRGB(140,255,160)}; local h2=rpPhase*0.3%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Midnight Oil",g=function() rpHue=(rpHue+0.002*rpColorSpd)%1; return Color3.fromHSV(rpHue,0.6,0.3) end},
        {n="Peach Glow",  g=function() local w=(math.sin(rpPhase*1.1)+1)/2; return Color3.fromRGB(255,180,120):Lerp(Color3.fromRGB(255,240,200),w) end},
        {n="Deep Space",  g=function() local c={Color3.fromRGB(10,10,40),Color3.fromRGB(60,20,100),Color3.fromRGB(20,100,180)}; local h2=rpPhase*0.25%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Acid",        g=function() return Color3.fromRGB(120,255,0) end},
        {n="Phantom",     g=function() local w=(math.sin(rpPhase*2.2)+1)/2; return Color3.fromRGB(80,40,120):Lerp(Color3.fromRGB(180,120,255),w) end},
        {n="Solar Flare", g=function() local c={Color3.fromRGB(255,80,0),Color3.fromRGB(255,200,0),Color3.fromRGB(255,255,100)}; local h2=rpPhase*0.6%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
        {n="Frost",       g=function() return Color3.fromRGB(180,240,255) end},
        {n="Venom",       g=function() rpHue=(rpHue+dt*1.2*rpColorSpd)%1; return Color3.fromHSV(rpHue,0.9,0.7) end},
        {n="Royal",       g=function() local w=(math.sin(rpPhase*1.3)+1)/2; return Color3.fromRGB(80,0,160):Lerp(Color3.fromRGB(200,160,255),w) end},
        {n="Pulse Red",   g=function() local w=math.abs(math.sin(rpPhase*8)); return Color3.fromRGB(255,math.floor(w*60),math.floor(w*40)) end},
        {n="Underwater",  g=function() local c={Color3.fromRGB(0,80,140),Color3.fromRGB(0,180,220),Color3.fromRGB(100,240,255)}; local h2=rpPhase*0.32%1; local i=math.floor(h2*2); return c[i+1]:Lerp(c[math.min(i+2,3)],h2*2-i) end},
    }
    selPreset = PRESETS[1]

    -- Expanded Animation Modes (more variety, including pure hard changes)
    local animModes = {"None","Pulse","Flash","Strobe","Wave","Bounce","Invert","Dim","Hard Snap","Jitter","Flicker","Chaos","Rainbow Jump","Zero Fade"}
    local function ApplyAnim(col, dt)
        rpAnimPhaseT = rpAnimPhaseT + dt
        if rpAnimMode == "None"        then return col end
        if rpAnimMode == "Pulse"       then local w=(math.sin(rpAnimPhaseT*3)+1)/2; return col:Lerp(Color3.new(1,1,1),w*0.4) end
        if rpAnimMode == "Flash"       then local w=math.sin(rpAnimPhaseT*6)>0 and 1 or 0; return col:Lerp(Color3.new(1,1,1),w*0.5) end
        if rpAnimMode == "Strobe"      then return math.floor(rpAnimPhaseT*8)%2==0 and col or Color3.new(0,0,0) end
        if rpAnimMode == "Wave"        then local w=(math.sin(rpAnimPhaseT*2)+1)/2; return col:Lerp(Color3.new(1,1,1),w*0.35) end
        if rpAnimMode == "Bounce"      then local w=math.abs(math.sin(rpAnimPhaseT*4)); return col:Lerp(Color3.new(1,1,1),w*0.5) end
        if rpAnimMode == "Invert"      then return math.floor(rpAnimPhaseT*3)%2==0 and Color3.new(1-col.R,1-col.G,1-col.B) or col end
        if rpAnimMode == "Dim"         then local w=(math.sin(rpAnimPhaseT*1.5)+1)/2; return col:Lerp(Color3.new(0,0,0),(1-w)*0.7) end
        if rpAnimMode == "Hard Snap"   then return math.floor(rpAnimPhaseT*6)%2==0 and col or Color3.new(1,1,1) end
        if rpAnimMode == "Jitter"      then return math.random()>0.6 and col or Color3.fromRGB(math.random(80,255),math.random(80,255),math.random(80,255)) end
        if rpAnimMode == "Flicker"     then return math.random()>0.75 and col or Color3.new(0.3,0.3,0.3) end
        if rpAnimMode == "Chaos"       then return Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)) end
        if rpAnimMode == "Rainbow Jump"then rpHue=(rpHue+dt*8)%1; return Color3.fromHSV(rpHue,1,1) end
        if rpAnimMode == "Zero Fade"   then return col end -- pure instant color, no transition
        return col
    end

    local customColors = {{255,0,128},{0,200,255}}
    local customSpd = 1.4
    local customBlendMode = "Linear"

    local function GetCustomColor()
        local n = #customColors
        if n == 0 then return Color3.new(1,1,1) end
        if n == 1 then local c=customColors[1]; return Color3.fromRGB(c[1],c[2],c[3]) end

        local t_raw = rpPhase * customSpd
        local t_norm
        if customBlendMode == "Ping-Pong" then
            local cycle = t_raw % (2*(n-1))
            if cycle > (n-1) then cycle = 2*(n-1) - cycle end
            t_norm = cycle / (n-1)
        elseif customBlendMode == "Random" then
            local idx = (math.floor(t_raw*2)%n)+1
            local c = customColors[idx]
            return Color3.fromRGB(c[1],c[2],c[3])
        else
            t_norm = t_raw % 1
        end

        local seg = t_norm * (n-1)
        local idx = math.min(math.floor(seg)+1, n-1)
        local frac = seg - math.floor(seg)
        local c1 = customColors[idx]
        local c2 = customColors[idx+1]
        return Color3.fromRGB(c1[1],c1[2],c1[3]):Lerp(Color3.fromRGB(c2[1],c2[2],c2[3]), frac)
    end

    local function GetBaseColor(dt)
        rpPhase = rpPhase + dt * rpColorSpd
        if rpEffMode == "Static" then return staticCol end
        if rpEffMode == "Custom" then return GetCustomColor() end
        return selPreset and selPreset.g(dt) or Color3.new(1,1,1)
    end

    -- UI
    local rpCard = MkCard(P, 52, 1)
    MkLabel(rpCard, {text="RP COLOR  ·  FULLY CONFIGURABLE", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-60,0,10), pos=UDim2.new(0,14,0,8), pulse=true, tkey="DIM"})
    local rpSt = MkLabel(rpCard, {text="INACTIVE", size=13, color=C.MUTED, font=Bold, sz=UDim2.new(1,-60,0,20), pos=UDim2.new(0,14,0,22), tkey="MUTED"})
    local rpPill, _, rpSet = MkPill(rpCard)

    local nameC = MkCard(P, 60, 2)
    MkLabel(nameC, {text="RP NAME  (blank = your display name)", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,8), pulse=true, tkey="DIM"})
    local nameBox = MkTBox(nameC, "Custom RP name...", 24)

    local _, _, twSet = MkToggleCard(P, "TYPEWRITER EFFECT  (name types char by char)", 3,
        function() rpTypeOn = true end,
        function() rpTypeOn = false end
    )
    twSet(true, true)

    MkSliderCard(P, "TYPE SPEED  (1=slow · 20=fast)", 1, 20, 4, 4, function(v) rpTypeSpd = 1/v end)
    MkToggleCard(P, "APPLY COLOR TO BIO", 5, function() rpBioOn = true end, function() rpBioOn = false end)
    MkSliderCard(P, "COLOR CYCLE SPEED", 1, 20, 5, 6, function(v) rpColorSpd = v/5 end)

    -- Color source selector
    local effC = MkCard(P, 70, 7)
    MkLabel(effC, {text="COLOR SOURCE", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,8), pulse=true, tkey="DIM"})
    local effRow = Instance.new("Frame", effC)
    effRow.Size = UDim2.new(1,-28,0,28)
    effRow.Position = UDim2.new(0,14,0,32)
    effRow.BackgroundTransparency = 1
    effRow.BorderSizePixel = 0
    local eLL = Instance.new("UIListLayout", effRow)
    eLL.FillDirection = Enum.FillDirection.Horizontal
    eLL.SortOrder = Enum.SortOrder.LayoutOrder
    eLL.Padding = UDim.new(0,6)

    local effModes = {"Preset","Custom","Static"}
    local effBtns = {}
    local presetCard, customCard, staticCard
    local function ShowEffCards()
        if presetCard then presetCard.Visible = (rpEffMode == "Preset") end
        if customCard  then customCard.Visible = (rpEffMode == "Custom")  end
        if staticCard  then staticCard.Visible = (rpEffMode == "Static")  end
    end
    for i, m in ipairs(effModes) do
        local active = (m == rpEffMode)
        local mb = MkBtn(effRow, {text=m, size=9, bg=active and C.ACCENT or C.ELEV, color=active and C.BG or C.TEXT, sz=UDim2.new(0.33,-4,1,0), corner=6, bgt=0, order=i})
        mb.MouseButton1Click:Connect(function()
            rpEffMode = m
            for j, b in ipairs(effBtns) do
                Tw(b, {BackgroundColor3 = (j==i) and C.ACCENT or C.ELEV, TextColor3 = (j==i) and C.BG or C.TEXT}, 0.18)
            end
            ShowEffCards()
        end)
        effBtns[i] = mb
    end

    -- Animation mode (expanded)
    local animC = MkCard(P, 92, 8)
    MkLabel(animC, {text="COLOR ANIMATION", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,8), pulse=true, tkey="DIM"})
    local aRow1 = Instance.new("Frame", animC); aRow1.Size = UDim2.new(1,-28,0,26); aRow1.Position = UDim2.new(0,14,0,24); aRow1.BackgroundTransparency = 1; aRow1.BorderSizePixel = 0
    local aLL1 = Instance.new("UIListLayout", aRow1); aLL1.FillDirection = Enum.FillDirection.Horizontal; aLL1.SortOrder = Enum.SortOrder.LayoutOrder; aLL1.Padding = UDim.new(0,4)
    local aRow2 = Instance.new("Frame", animC); aRow2.Size = UDim2.new(1,-28,0,26); aRow2.Position = UDim2.new(0,14,0,56); aRow2.BackgroundTransparency = 1; aRow2.BorderSizePixel = 0
    local aLL2 = Instance.new("UIListLayout", aRow2); aLL2.FillDirection = Enum.FillDirection.Horizontal; aLL2.SortOrder = Enum.SortOrder.LayoutOrder; aLL2.Padding = UDim.new(0,4)

    local aBtns = {}
    for i, m in ipairs(animModes) do
        local active = (m == rpAnimMode)
        local parent = i <= 7 and aRow1 or aRow2
        local mb = MkBtn(parent, {text=m, size=8, bg=active and C.ACCENT or C.ELEV, color=active and C.BG or C.TEXT, sz=UDim2.new(0.25,-4,1,0), corner=5, bgt=0, order=i})
        mb.MouseButton1Click:Connect(function()
            rpAnimMode = m
            for j, b in ipairs(aBtns) do
                Tw(b, {BackgroundColor3 = (j==i) and C.ACCENT or C.ELEV, TextColor3 = (j==i) and C.BG or C.TEXT}, 0.14)
            end
        end)
        aBtns[i] = mb
    end

    -- Preset grid
    presetCard = MkCard(P, 340, 9)
    MkLabel(presetCard, {text="COLOR PRESETS  ("..#PRESETS.." total)", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,7), pulse=true, tkey="DIM"})
    local pgSF = Instance.new("ScrollingFrame", presetCard)
    pgSF.Size = UDim2.new(1,-24,0,316)
    pgSF.Position = UDim2.new(0,12,0,20)
    pgSF.BackgroundTransparency = 1
    pgSF.ScrollBarThickness = 2
    pgSF.ScrollBarImageColor3 = C.ACCENT
    pgSF.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pgSF.CanvasSize = UDim2.new(0,0,0,0)
    pgSF.BorderSizePixel = 0
    pgSF.ClipsDescendants = true
    local pgGrid = Instance.new("UIGridLayout", pgSF)
    pgGrid.CellSize = UDim2.new(0,118,0,28)
    pgGrid.CellPadding = UDim2.new(0,5,0,5)

    local pSelBtn = nil
    for i, pr in ipairs(PRESETS) do
        local b = MkBtn(pgSF, {bg=C.RAISED, text=pr.n, size=8, color=C.MUTED, font=Bold, corner=5, bgt=0.2, bgkey="RAISED", tkey="MUTED"})
        b.LayoutOrder = i
        b.MouseButton1Click:Connect(function()
            if pSelBtn then Tw(pSelBtn, {BackgroundColor3=C.RAISED, BackgroundTransparency=0.2}, 0.12); pSelBtn.TextColor3 = C.MUTED end
            Tw(b, {BackgroundColor3=C.ACCENT, BackgroundTransparency=0.1}, 0.12)
            b.TextColor3 = C.TEXT
            pSelBtn = b
            selPreset = pr
        end)
        if i == 1 then
            pSelBtn = b
            b.BackgroundColor3 = C.ACCENT
            b.BackgroundTransparency = 0.1
            b.TextColor3 = C.TEXT
        end
    end

    -- Custom builder (fixed delete button)
    customCard = MkCard(P, 420, 10)
    customCard.Visible = false
    MkLabel(customCard, {text="CUSTOM BUILDER  ·  UP TO 6 COLORS", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,7), pulse=true, tkey="DIM"})

    local bmRow = Instance.new("Frame", customCard)
    bmRow.Size = UDim2.new(1,-28,0,26)
    bmRow.Position = UDim2.new(0,14,0,22)
    bmRow.BackgroundTransparency = 1
    bmRow.BorderSizePixel = 0
    local bmLL = Instance.new("UIListLayout", bmRow)
    bmLL.FillDirection = Enum.FillDirection.Horizontal
    bmLL.SortOrder = Enum.SortOrder.LayoutOrder
    bmLL.Padding = UDim.new(0,6)

    local bmModes = {"Linear","Ping-Pong","Random"}
    local bmBtns = {}
    for i, m in ipairs(bmModes) do
        local active = (m == customBlendMode)
        local mb = MkBtn(bmRow, {text=m, size=8, bg=active and C.ACCENT or C.ELEV, color=active and C.BG or C.TEXT, sz=UDim2.new(0.33,-4,1,0), corner=5, bgt=0, order=i})
        mb.MouseButton1Click:Connect(function()
            customBlendMode = m
            for j, b in ipairs(bmBtns) do Tw(b, {BackgroundColor3=(j==i) and C.ACCENT or C.ELEV, TextColor3=(j==i) and C.BG or C.TEXT}, 0.14) end
        end)
        bmBtns[i] = mb
    end

    local colorSF = Instance.new("ScrollingFrame", customCard)
    colorSF.Size = UDim2.new(1,-24,0,280)
    colorSF.Position = UDim2.new(0,12,0,56)
    colorSF.BackgroundTransparency = 1
    colorSF.ScrollBarThickness = 2
    colorSF.ScrollBarImageColor3 = C.ACCENT
    colorSF.AutomaticCanvasSize = Enum.AutomaticSize.Y
    colorSF.CanvasSize = UDim2.new(0,0,0,0)
    colorSF.BorderSizePixel = 0
    colorSF.ClipsDescendants = true
    LL(colorSF, 5)

    local addColBtn = MkBtn(customCard, {bg=C.ACCENT, text="+ ADD COLOR", size=9, color=C.BG, sz=UDim2.new(1,-28,0,28), pos=UDim2.new(0,14,0,344), corner=6, bgt=0.05, bgkey="ACCENT", tkey="BG"})

     local function RebuildColors()
        for _, v in colorSF:GetChildren() do 
            if v:IsA("Frame") then v:Destroy() end 
        end

        for idx, cd in ipairs(customColors) do
            local row = Instance.new("Frame", colorSF)
            row.Size = UDim2.new(1,0,0,90)
            row.BackgroundColor3 = C.RAISED
            row.BackgroundTransparency = 0.15
            row.BorderSizePixel = 0
            Cnr(row, 7)
            row.LayoutOrder = idx
            TReg(row, "BackgroundColor3", "RAISED")

            local sw = Instance.new("Frame", row)
            sw.Size = UDim2.new(0,34,0,34)
            sw.Position = UDim2.new(0,8,0,8)
            sw.BackgroundColor3 = Color3.fromRGB(cd[1],cd[2],cd[3])
            sw.BorderSizePixel = 0
            Cnr(sw, 6)

            MkLabel(row, {text="COLOR "..idx, size=8, color=C.DIM, font=Bold, sz=UDim2.new(0,70,0,12), pos=UDim2.new(0,50,0,10), pulse=true, tkey="DIM"})

            local sc2 = Instance.new("Frame", row)
            sc2.Size = UDim2.new(1,-92,0,60)   -- Fixed width to prevent overlap
            sc2.Position = UDim2.new(0,50,0,26)
            sc2.BackgroundTransparency = 1
            sc2.BorderSizePixel = 0

            MkSmallSlider(sc2, "R", cd[1], 0, function(v) cd[1]=v; sw.BackgroundColor3=Color3.fromRGB(cd[1],cd[2],cd[3]) end)
            MkSmallSlider(sc2, "G", cd[2], 20, function(v) cd[2]=v; sw.BackgroundColor3=Color3.fromRGB(cd[1],cd[2],cd[3]) end)
            MkSmallSlider(sc2, "B", cd[3], 40, function(v) cd[3]=v; sw.BackgroundColor3=Color3.fromRGB(cd[1],cd[2],cd[3]) end)

            -- Fixed Delete Button (clean "X", no overlap)
            if #customColors > 1 then
                local del = MkBtn(row, {
                    bg = Color3.fromRGB(188,40,40), 
                    text = "X", 
                    size = 9, 
                    color = Color3.new(1,1,1), 
                    sz = UDim2.new(0,28,0,28), 
                    pos = UDim2.new(1,-36,0.5,-14), 
                    corner = 5, 
                    bgt = 0.1
                })
                del.MouseButton1Click:Connect(function()
                    table.remove(customColors, idx)
                    RebuildColors()
                end)
            end
        end
    end

    RebuildColors()

    addColBtn.MouseButton1Click:Connect(function()
        if #customColors >= 6 then ShowNotif("Color Builder", "Max 6 colors", "warn"); return end
        table.insert(customColors, {math.random(50,255), math.random(50,255), math.random(50,255)})
        RebuildColors()
        ShowNotif("Color Builder", "Added color "..(#customColors), "success")
    end)

    -- Static card
    staticCard = MkCard(P, 90, 11)
    staticCard.Visible = false
    MkLabel(staticCard, {text="STATIC COLOR", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,7), pulse=true, tkey="DIM"})
    local sSwat = Instance.new("Frame", staticCard)
    sSwat.Size = UDim2.new(0,40,0,32)
    sSwat.Position = UDim2.new(0,14,0,24)
    sSwat.BackgroundColor3 = staticCol
    sSwat.BorderSizePixel = 0
    Cnr(sSwat, 7)

    local sCont = Instance.new("Frame", staticCard)
    sCont.Size = UDim2.new(1,-70,0,68)
    sCont.Position = UDim2.new(0,60,0,14)
    sCont.BackgroundTransparency = 1
    sCont.BorderSizePixel = 0

    MkSmallSlider(sCont, "R", staticCol.R*255, 0, function(v) staticCol = Color3.fromRGB(v, staticCol.G*255, staticCol.B*255); sSwat.BackgroundColor3 = staticCol end)
    MkSmallSlider(sCont, "G", staticCol.G*255, 22, function(v) staticCol = Color3.fromRGB(staticCol.R*255, v, staticCol.B*255); sSwat.BackgroundColor3 = staticCol end)
    MkSmallSlider(sCont, "B", staticCol.B*255, 44, function(v) staticCol = Color3.fromRGB(staticCol.R*255, staticCol.G*255, v); sSwat.BackgroundColor3 = staticCol end)

    ShowEffCards()

    local function ToggleRP()
        rpOn = not rpOn
        rpSet(rpOn)
        rpSt.Text = rpOn and "ACTIVE" or "INACTIVE"
        Tw(rpSt, {TextColor3 = rpOn and C.ACCENT or C.MUTED}, 0.14)

        if rpOn then
            rpNameIdx = 1
            rpNameTimer = 0
            rpPhase = 0
            rpAnimPhaseT = 0
            rpHue = 0
            rpLastColor = 0
            rpLastName = 0
            rpLastBio = 0

            rpConn = TC(RunSvc.Heartbeat:Connect(function(dt)
                if not rpOn then return end
                local now = tick()

                if now - rpLastColor >= RP_COLOR_RATE then
                    rpLastColor = now
                    local base = GetBaseColor(dt)
                    local col = ApplyAnim(base, dt)
                    pcall(function() if RPR.Color then RPR.Color:FireServer(col) end end)

                    if rpBioOn and (now - rpLastBio) >= RP_COLOR_RATE*2 then
                        rpLastBio = now
                        pcall(function() if RPR.Bio then if RPR.BioF then RPR.Bio:InvokeServer(col) else RPR.Bio:FireServer(col) end end end)
                    end
                end

                if now - rpLastName >= RP_NAME_RATE then
                    local elapsed = now - rpLastName
                    rpLastName = now
                    rpNameTimer = rpNameTimer + elapsed
                    if rpNameTimer >= rpTypeSpd then
                        rpNameTimer = 0
                        local full = nameBox.Text ~= "" and nameBox.Text or lp.DisplayName
                        if #full > 0 then
                            if rpTypeOn then
                                pcall(function() if RPR.Name then RPR.Name:FireServer(string.sub(full,1,rpNameIdx)) end end)
                                rpNameIdx = rpNameIdx >= #full and 1 or rpNameIdx + 1
                            else
                                pcall(function() if RPR.Name then RPR.Name:FireServer(full) end end)
                            end
                        end
                    end
                end
            end))

            ShowNotif("RP Color", "Active · "..rpEffMode.." · "..rpAnimMode, "success")
        else
            if rpConn then rpConn:Disconnect(); rpConn = nil end
            ShowNotif("RP Color", "Deactivated", "info")
        end
    end

    rpPill.MouseButton1Click:Connect(ToggleRP)
    RegisterKeybind("Toggle RP Color", Enum.KeyCode.R, ToggleRP, "RP Color")
end

-- ═══════════════════════════════════════════════════════
-- TAB 7 · AIMLOCK
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[7]; local aimTgt=nil; local aimOn=false; local aimPart="HumanoidRootPart"
    local aCard=MkCard(P,52,1)
    MkLabel(aCard,{text="AIMLOCK",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local aSt=MkLabel(aCard,{text="INACTIVE",size=13,color=C.MUTED,font=Bold,sz=UDim2.new(1,-60,0,20),pos=UDim2.new(0,14,0,22),tkey="MUTED"})
    local aPill,_,aSet=MkPill(aCard)
    local pC=MkCard(P,56,2); MkLabel(pC,{text="AIM PART",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local pRow=Instance.new("Frame",pC); pRow.Size=UDim2.new(1,-28,0,24); pRow.Position=UDim2.new(0,14,0,24); pRow.BackgroundTransparency=1; pRow.BorderSizePixel=0
    local pLL=Instance.new("UIListLayout",pRow); pLL.FillDirection=Enum.FillDirection.Horizontal; pLL.SortOrder=Enum.SortOrder.LayoutOrder; pLL.Padding=UDim.new(0,6)
    local parts={"HRP","Head","Torso","Legs"}; local partMap={"HumanoidRootPart","Head","UpperTorso","LowerTorso"}; local pBtns={}
    for i,pt in ipairs(parts) do
        local active=(i==1); local mb=MkBtn(pRow,{text=pt,size=8,bg=active and C.ACCENT or C.ELEV,color=active and C.BG or C.TEXT,sz=UDim2.new(0.25,-4,1,0),corner=5,bgt=0,order=i})
        mb.MouseButton1Click:Connect(function()
            aimPart=partMap[i]; for j,b in ipairs(pBtns) do Tw(b,{BackgroundColor3=(j==i) and C.ACCENT or C.ELEV,TextColor3=(j==i) and C.BG or C.TEXT},0.14) end
        end); pBtns[i]=mb
    end
    local tLC=MkCard(P,220,3); MkLabel(tLC,{text="SELECT TARGET",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,7),pulse=true,tkey="DIM"})
    local tSF=Instance.new("ScrollingFrame",tLC); tSF.Size=UDim2.new(1,-24,0,196); tSF.Position=UDim2.new(0,12,0,20)
    tSF.BackgroundTransparency=1; tSF.ScrollBarThickness=2; tSF.ScrollBarImageColor3=C.ACCENT; tSF.AutomaticCanvasSize=Enum.AutomaticSize.Y; tSF.CanvasSize=UDim2.new(0,0,0,0); tSF.BorderSizePixel=0; tSF.ClipsDescendants=true; LL(tSF,2)
    local function RefAim()
        for _,v in tSF:GetChildren() do if v:IsA("Frame") then v:Destroy() end end
        for _,p in Players:GetPlayers() do
            if p==lp then continue end; local sel=(aimTgt==p)
            local row=Instance.new("Frame",tSF); row.Size=UDim2.new(1,0,0,34)
            row.BackgroundColor3=C.RAISED; row.BackgroundTransparency=0.18; row.BorderSizePixel=0; Cnr(row,6); TReg(row,"BackgroundColor3","RAISED")
            if sel then Strk(row,C.ACCENT,1,0.18) end
            MkLabel(row,{text=p.DisplayName,size=10,color=sel and C.TEXT or C.MUTED,font=Semi,sz=UDim2.new(1,-14,0,17),pos=UDim2.new(0,10,0,2)})
            MkLabel(row,{text="@"..p.Name,size=8,color=C.DIM,font=Reg,sz=UDim2.new(1,-14,0,13),pos=UDim2.new(0,10,0,19)})
            local rb=Instance.new("TextButton",row); rb.Size=UDim2.new(1,0,1,0); rb.BackgroundTransparency=1; rb.Text=""
            rb.MouseButton1Click:Connect(function() aimTgt=p; RefAim() end)
        end
    end
    RefAim(); Players.PlayerAdded:Connect(RefAim)
    Players.PlayerRemoving:Connect(function(p) if aimTgt==p then aimTgt=nil; aimOn=false; aSet(false,true); aSt.Text="INACTIVE"; aSt.TextColor3=C.MUTED end; RefAim() end)
    local function ToggleAim()
        if not aimTgt then ShowNotif("Aimlock","Select a target first","warn"); return end
        aimOn=not aimOn; aSet(aimOn); aSt.Text=aimOn and "LOCKED" or "INACTIVE"; Tw(aSt,{TextColor3=aimOn and C.ACCENT or C.MUTED},0.14)
        ShowNotif("Aimlock",aimOn and ("Locked → "..aimTgt.DisplayName) or "Unlocked",aimOn and "success" or "info")
    end
    aPill.MouseButton1Click:Connect(ToggleAim); RegisterKeybind("Toggle Aimlock", Enum.KeyCode.L, ToggleAim, "Combat")
    TC(RunSvc.RenderStepped:Connect(function()
        if not aimOn or not aimTgt then return end; local ch=aimTgt.Character; if not ch then return end
        local part=ch:FindFirstChild(aimPart) or ch:FindFirstChild("HumanoidRootPart"); if not part then return end
        workspace.CurrentCamera.CFrame=CFrame.new(workspace.CurrentCamera.CFrame.Position,part.Position)
    end))
end

-- ═══════════════════════════════════════════════════════
-- TAB 8 · GLITCH
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[8]
    local function setupG(char) pcall(function() local h=char:WaitForChild("Humanoid",4); if h then h:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false); h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end end) end
    pcall(function() setupG(lp.Character or lp.CharacterAdded:Wait()) end); lp.CharacterAdded:Connect(setupG)
    local gc=MkCard(P,52,1); MkLabel(gc,{text="GLITCH FOLLOW  ·  [J] emergency stop",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local gSt=MkLabel(gc,{text="INACTIVE",size=13,color=C.MUTED,font=Bold,sz=UDim2.new(1,-60,0,20),pos=UDim2.new(0,14,0,22),tkey="MUTED"}); local gPill,_,gSet=MkPill(gc)
    local _,gtBox=MkTBoxCard(P,"TARGET PLAYER","player name ...",2)
    local glitchR=4; MkSliderCard(P,"INTENSITY",1,20,4,3,function(v) glitchR=v end)
    local gfOn=false; local gfConn
    local function ToggleGlitch()
        gfOn=not gfOn; gSet(gfOn); gSt.Text=gfOn and "ACTIVE" or "INACTIVE"; Tw(gSt,{TextColor3=gfOn and C.ACCENT or C.MUTED},0.14)
        if gfOn then
            ShowNotif("Glitch","Active · [J] emergency stop","warn")
            gfConn=TC(RunSvc.RenderStepped:Connect(function()
                if not gfOn then return end; local tgt=FindPlayer(gtBox.Text); if not tgt or not tgt.Character then return end
                local tH=tgt.Character:FindFirstChild("HumanoidRootPart"); if not tH then return end
                local mc=lp.Character; if not mc then return end; local mH=mc:FindFirstChild("HumanoidRootPart"); if not mH then return end
                local h=mc:FindFirstChildOfClass("Humanoid"); if h then h:ChangeState(Enum.HumanoidStateType.Running) end
                mH.AssemblyLinearVelocity=Vector3.zero; local r=glitchR
                for _=1,8 do mH.CFrame=tH.CFrame*CFrame.new(math.random(-r,r),math.random(-2,2),math.random(-r,r))*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))) end
            end))
        else if gfConn then gfConn:Disconnect(); gfConn=nil end end
    end
    gPill.MouseButton1Click:Connect(ToggleGlitch)
    RegisterKeybind("Emergency Stop Glitch", Enum.KeyCode.J, function()
        if gfOn then gfOn=false; gSet(false); gSt.Text="INACTIVE"; gSt.TextColor3=C.MUTED; if gfConn then gfConn:Disconnect(); gfConn=nil end; ShowNotif("Glitch","Emergency stopped","warn") end
    end, "Combat")
end

-- ═══════════════════════════════════════════════════════
-- TAB 9 · SPIN  (BodyVelocity — server-visible)
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[9]; local spinSpd=60; local spinOn=false; local spinAng=0
    local sAt,sAO,sBV,sCn; local sAxisX=false; local sAxisZ=false
    local sc=MkCard(P,52,1); MkLabel(sc,{text="SUPER SPIN  ·  server-visible BodyVelocity",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local sSt=MkLabel(sc,{text="INACTIVE",size=13,color=C.MUTED,font=Bold,sz=UDim2.new(1,-60,0,20),pos=UDim2.new(0,14,0,22),tkey="MUTED"}); local sPill,_,sSet=MkPill(sc)
    MkSliderCard(P,"SPIN SPEED",1,500,60,2,function(v) spinSpd=v end)
    MkToggleCard(P,"X AXIS",3,function() sAxisX=true end,function() sAxisX=false end)
    MkToggleCard(P,"Z AXIS",4,function() sAxisZ=true end,function() sAxisZ=false end)
    local function startSpin()
        pcall(function()
            local char=lp.Character; if not char then return end; local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            if sAt then sAt:Destroy() end; if sAO then sAO:Destroy() end; if sBV then sBV:Destroy() end
            sAt=Instance.new("Attachment",hrp)
            sAO=Instance.new("AlignOrientation"); sAO.Attachment0=sAt; sAO.MaxTorque=math.huge; sAO.Responsiveness=200; sAO.Mode=Enum.OrientationAlignmentMode.OneAttachment; sAO.Parent=hrp
            sBV=Instance.new("BodyVelocity",hrp); sBV.MaxForce=Vector3.new(0,0,0); sBV.Velocity=Vector3.zero; sBV.P=1e4
            sCn=TC(RunSvc.Heartbeat:Connect(function(dt)
                if not spinOn then return end; spinAng=spinAng+spinSpd*dt
                sAO.CFrame=CFrame.Angles(sAxisX and spinAng*0.3 or 0, spinAng, sAxisZ and spinAng*0.2 or 0)
                pcall(function() hrp.AssemblyAngularVelocity=Vector3.new(sAxisX and spinSpd*0.5 or 0, spinSpd, sAxisZ and spinSpd*0.3 or 0) end)
            end))
        end)
    end
    local function ToggleSpin()
        spinOn=not spinOn; sSet(spinOn); sSt.Text=spinOn and "ACTIVE" or "INACTIVE"; Tw(sSt,{TextColor3=spinOn and C.ACCENT or C.MUTED},0.14)
        if spinOn then startSpin(); ShowNotif("Spin","Active","success")
        else
            pcall(function() if sCn then sCn:Disconnect() end end); pcall(function() if sAt then sAt:Destroy() end end)
            pcall(function() if sAO then sAO:Destroy() end end); pcall(function() if sBV then sBV:Destroy() end end)
            pcall(function() local char=lp.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if hrp then hrp.AssemblyAngularVelocity=Vector3.zero end end)
            ShowNotif("Spin","Stopped","info")
        end
    end
    sPill.MouseButton1Click:Connect(ToggleSpin); RegisterKeybind("Toggle Spin", Enum.KeyCode.Semicolon, ToggleSpin, "Movement")
    lp.CharacterAdded:Connect(function() if spinOn then task.wait(1); startSpin() end end)
end

-- ═══════════════════════════════════════════════════════
-- TAB 10 · VISUALS
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[10]; local espB={}
    MkToggleCard(P,"ESP HIGHLIGHT",1,
        function()
            for _,v in pairs(espB) do pcall(function() v:Destroy() end) end; espB={}
            for _,p in Players:GetPlayers() do
                if p==lp then continue end
                local function mk(c) pcall(function() local b=Instance.new("SelectionBox"); b.Color3=C.ACCENT; b.LineThickness=0.04; b.SurfaceTransparency=0.88; b.SurfaceColor3=C.ACCENT; b.Adornee=c; b.Parent=workspace; espB[p]=b end) end
                if p.Character then mk(p.Character) end
                p.CharacterAdded:Connect(function(ch) if espB[p] then pcall(function() espB[p]:Destroy() end) end; mk(ch) end)
            end; ShowNotif("ESP","Highlight on","success")
        end,
        function() for _,v in pairs(espB) do pcall(function() v:Destroy() end) end; espB={}; ShowNotif("ESP","Off","info") end
    )
    local chamB={}
    MkToggleCard(P,"ESP CHAMS  (through walls)",2,
        function()
            for _,v in pairs(chamB) do pcall(function() v:Destroy() end) end; chamB={}
            for _,p in Players:GetPlayers() do
                if p==lp then continue end
                local function mkC(c) pcall(function() local b=Instance.new("BoxHandleAdornment"); b.Size=Vector3.new(4,6,2); b.Color3=Color3.fromRGB(255,80,80); b.Transparency=0.5; b.AlwaysOnTop=true; b.ZIndex=10; b.Adornee=c:FindFirstChild("HumanoidRootPart") or c; b.Parent=workspace; chamB[p]=b end) end
                if p.Character then mkC(p.Character) end; p.CharacterAdded:Connect(function(ch) task.wait(0.5); mkC(ch) end)
            end
        end,
        function() for _,v in pairs(chamB) do pcall(function() v:Destroy() end) end; chamB={} end
    )
    local rbH=0; local rbC
    MkToggleCard(P,"RAINBOW CHARACTER",3,
        function() rbC=TC(RunSvc.Heartbeat:Connect(function(dt) rbH=(rbH+dt*0.45)%1; local col=Color3.fromHSV(rbH,1,1); local char=lp.Character; if not char then return end; for _,v in char:GetDescendants() do if v:IsA("BasePart") then pcall(function() v.BrickColor=BrickColor.new(col) end) end end end)) end,
        function() if rbC then rbC:Disconnect(); rbC=nil end end
    )
    local origBr=2; pcall(function() origBr=Lighting.Brightness end)
    MkToggleCard(P,"FULLBRIGHT",4,function() pcall(function() Lighting.Brightness=10; Lighting.ClockTime=14; workspace.GlobalShadows=false end) end,function() pcall(function() Lighting.Brightness=origBr; workspace.GlobalShadows=true end) end)
    MkToggleCard(P,"NO SHADOWS",5,function() pcall(function() workspace.GlobalShadows=false end) end,function() pcall(function() workspace.GlobalShadows=true end) end)
    local fE=1e5; local fS=0; pcall(function() fE=Lighting.FogEnd; fS=Lighting.FogStart end)
    MkToggleCard(P,"REMOVE FOG",6,function() pcall(function() Lighting.FogEnd=1e5; Lighting.FogStart=1e5 end) end,function() pcall(function() Lighting.FogEnd=fE; Lighting.FogStart=fS end) end)
    MkToggleCard(P,"INVISIBLE  (local)",7,
        function() local char=lp.Character; if not char then return end; for _,v in char:GetDescendants() do if v:IsA("BasePart") then pcall(function() v.LocalTransparencyModifier=1 end) end end end,
        function() local char=lp.Character; if not char then return end; for _,v in char:GetDescendants() do if v:IsA("BasePart") then pcall(function() v.LocalTransparencyModifier=0 end) end end end
    )
    local xhLines={}
    MkToggleCard(P,"CUSTOM CROSSHAIR",8,
        function()
            for _,v in xhLines do pcall(function() v:Destroy() end) end; xhLines={}
            local v1=Instance.new("Frame",GUI); v1.Size=UDim2.new(0,2,0,22); v1.Position=UDim2.new(0.5,-1,0.5,-11); v1.BackgroundColor3=C.ACCENT; v1.BorderSizePixel=0; v1.ZIndex=8000; TReg(v1,"BackgroundColor3","ACCENT"); table.insert(xhLines,v1)
            local h1=Instance.new("Frame",GUI); h1.Size=UDim2.new(0,22,0,2); h1.Position=UDim2.new(0.5,-11,0.5,-1); h1.BackgroundColor3=C.ACCENT; h1.BorderSizePixel=0; h1.ZIndex=8000; TReg(h1,"BackgroundColor3","ACCENT"); table.insert(xhLines,h1)
        end,
        function() for _,v in xhLines do pcall(function() v:Destroy() end) end; xhLines={} end
    )
    MkSliderCard(P,"FIELD OF VIEW",30,120,70,9,function(v) pcall(function() workspace.CurrentCamera.FieldOfView=v end) end)
    MkSliderCard(P,"TIME OF DAY",0,24,14,10,function(v) pcall(function() Lighting.ClockTime=v end) end)
end

-- ═══════════════════════════════════════════════════════
-- TAB 11 · MISC
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[11]; local noclipOn=false
    MkToggleCard(P,"NOCLIP",1,function() noclipOn=true; ShowNotif("Noclip","Enabled","success") end,function() noclipOn=false; ShowNotif("Noclip","Disabled","info") end)
    RegisterKeybind("Toggle Noclip", Enum.KeyCode.N, function() noclipOn=not noclipOn; ShowNotif("Noclip",noclipOn and "Enabled" or "Disabled",noclipOn and "success" or "info") end, "Movement")
    TC(RunSvc.Stepped:Connect(function()
        if not noclipOn then return end; local char=lp.Character; if not char then return end
        for _,v in char:GetDescendants() do if v:IsA("BasePart") then pcall(function() v.CanCollide=false end) end end
    end))
    local ijOn=false
    MkToggleCard(P,"INFINITE JUMP",2,function() ijOn=true; ShowNotif("Infinite Jump","Enabled","success") end,function() ijOn=false; ShowNotif("Infinite Jump","Disabled","info") end)
    RegisterKeybind("Toggle Infinite Jump", Enum.KeyCode.X, function() ijOn=not ijOn; ShowNotif("Infinite Jump",ijOn and "Enabled" or "Disabled",ijOn and "success" or "info") end, "Movement")
    TC(UIS.JumpRequest:Connect(function()
        if not ijOn then return end; local char=lp.Character; if not char then return end
        local h=char:FindFirstChildOfClass("Humanoid"); if not h then return end; pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end))
    local rdDisabled={}; local rdConn; local rdHB
    MkToggleCard(P,"DISABLE RAGDOLL",3,
        function()
            pcall(function() local rs=RepStor:FindFirstChild("Events") and RepStor.Events:FindFirstChild("RagdollState")
                if rs then for _,c in ipairs(getconnections(rs.OnClientEvent)) do pcall(function() c:Disable() end); table.insert(rdDisabled,c) end end end)
            local function apRD(char)
                local h=char:WaitForChild("Humanoid",5); if not h then return end; local hrp=char:FindFirstChild("HumanoidRootPart")
                pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false) end); pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end)
                if rdHB then rdHB:Disconnect() end
                rdHB=TC(RunSvc.Heartbeat:Connect(function()
                    if not h or not h.Parent then return end; local st=h:GetState()
                    if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.FallingDown or st==Enum.HumanoidStateType.Ragdoll then
                        h.AutoRotate=true; pcall(function() if hrp and hrp.Parent then hrp.CanCollide=true end end); pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                    end
                end))
            end
            rdConn=TC(lp.CharacterAdded:Connect(apRD)); if lp.Character then task.spawn(apRD,lp.Character) end
            ShowNotif("Ragdoll","Disabled","success")
        end,
        function()
            for _,c in ipairs(rdDisabled) do pcall(function() c:Enable() end) end; rdDisabled={}
            if rdConn then rdConn:Disconnect(); rdConn=nil end; if rdHB then rdHB:Disconnect(); rdHB=nil end
            ShowNotif("Ragdoll","Re-enabled","info")
        end
    )
    local afkC
    MkToggleCard(P,"ANTI-AFK",4,
        function() afkC=TC(RunSvc.Heartbeat:Connect(function() pcall(function() local v=game:GetService("VirtualInputManager"); v:SendKeyEvent(true,Enum.KeyCode.ButtonR3,false,nil); v:SendKeyEvent(false,Enum.KeyCode.ButtonR3,false,nil) end) end)) end,
        function() if afkC then afkC:Disconnect(); afkC=nil end end
    )
    local godC
    MkToggleCard(P,"GOD MODE  (client)",5,
        function() godC=TC(RunSvc.Heartbeat:Connect(function() local char=lp.Character; if not char then return end; local h=char:FindFirstChildOfClass("Humanoid"); if not h then return end; pcall(function() if h.Health<h.MaxHealth then h.Health=h.MaxHealth end end) end)); ShowNotif("God Mode","Enabled","success") end,
        function() if godC then godC:Disconnect(); godC=nil end; ShowNotif("God Mode","Disabled","info") end
    )
    RegisterKeybind("Toggle God Mode", Enum.KeyCode.G, function() ShowNotif("God Mode","Toggle via Misc tab","info") end, "Combat")
    MkToggleCard(P,"SPEED BOOST  (×5)",6,function() pcall(function() lp.Character:FindFirstChildOfClass("Humanoid").WalkSpeed=100 end) end,function() pcall(function() lp.Character:FindFirstChildOfClass("Humanoid").WalkSpeed=16 end) end)
    local acC
    MkToggleCard(P,"AUTO CLICK",7,
        function() acC=TC(RunSvc.Heartbeat:Connect(function() pcall(function() game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,true,workspace,1) end); pcall(function() game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,false,workspace,1) end) end)) end,
        function() if acC then acC:Disconnect(); acC=nil end end
    )
    local freezeConn
    MkToggleCard(P,"FREEZE CHARACTER",8,
        function() pcall(function() local char=lp.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if hrp then local bp=Instance.new("BodyPosition",hrp); bp.Position=hrp.Position; bp.MaxForce=Vector3.new(1e6,1e6,1e6); bp.P=1e6; freezeConn=bp end end); ShowNotif("Freeze","Character frozen","warn") end,
        function() pcall(function() if freezeConn then freezeConn:Destroy(); freezeConn=nil end end); ShowNotif("Freeze","Unfrozen","info") end
    )
    local savedCF
    local spCard=MkCard(P,70,9)
    MkLabel(spCard,{text="SAFE POSITION",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,7),pulse=true,tkey="DIM"})
    local spInfo=MkLabel(spCard,{text="No position saved",size=9,color=C.MUTED,font=Reg,sz=UDim2.new(1,-28,0,13),pos=UDim2.new(0,14,0,20),tkey="MUTED"})
    local svBtn=MkBtn(spCard,{bg=C.ELEV,text="SAVE",size=9,color=C.TEXT,sz=UDim2.new(0.5,-18,0,26),pos=UDim2.new(0,14,0,38),corner=6,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
    local rtBtn=MkBtn(spCard,{bg=C.ACCENT,text="RETURN",size=9,color=C.BG,sz=UDim2.new(0.5,-18,0,26),pos=UDim2.new(0.5,4,0,38),corner=6,bgt=0.08,bgkey="ACCENT",tkey="BG"})
    svBtn.MouseButton1Click:Connect(function() local c=lp.Character; if not c then return end; local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end; savedCF=h.CFrame; spInfo.Text="Saved ✓"; spInfo.TextColor3=C.ACCENT; ShowNotif("Safe Pos","Saved","success") end)
    rtBtn.MouseButton1Click:Connect(function() if not savedCF then return end; local c=lp.Character; if not c then return end; local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end; h.CFrame=savedCF; ShowNotif("Safe Pos","Returned","info") end)
    RegisterKeybind("Save Position", Enum.KeyCode.P, function() svBtn.MouseButton1Click:Fire() end, "Movement")
    local flCard=MkCard(P,82,10); MkLabel(flCard,{text="FLING TARGET",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,7),pulse=true,tkey="DIM"})
    local fBtn=MkBtn(flCard,{bg=C.ACCENT,text="FLING",size=10,color=C.BG,sz=UDim2.new(0,70,0,28),pos=UDim2.new(1,-14,0,27),anchor=Vector2.new(1,0),corner=6,bgt=0.05,bgkey="ACCENT",tkey="BG"})
    local ftBox=MkTBox(flCard,"Player name ...",27,-92)
    fBtn.MouseButton1Click:Connect(function()
        local tgt=FindPlayer(ftBox.Text); if not tgt or not tgt.Character then ShowNotif("Fling","Player not found","error"); return end
        local hrp=tgt.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        ShowNotif("Fling","Launching "..tgt.DisplayName,"kill")
        local vx=math.random(-300,300); local vy=900; local vz=math.random(-300,300)
        pcall(function() hrp.AssemblyLinearVelocity=Vector3.new(vx,vy,vz) end)
        pcall(function() local bv=Instance.new("BodyVelocity",hrp); bv.Velocity=Vector3.new(vx,vy,vz); bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bv.P=math.huge; Debris:AddItem(bv,0.5) end)
    end)
    local shCard=MkCard(P,68,11); MkLabel(shCard,{text="SERVER CONTROLS",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,7),pulse=true,tkey="DIM"})
    local shBtn=MkBtn(shCard,{bg=C.ELEV,text="SERVER HOP",size=9,color=C.TEXT,sz=UDim2.new(0.5,-18,0,28),pos=UDim2.new(0,14,0,30),corner=6,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
    local rjBtn=MkBtn(shCard,{bg=C.ELEV,text="REJOIN",size=9,color=C.TEXT,sz=UDim2.new(0.5,-18,0,28),pos=UDim2.new(0.5,4,0,30),corner=6,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
    shBtn.MouseButton1Click:Connect(function() ShowNotif("Server","Hopping...","info"); pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,lp) end) end)
    rjBtn.MouseButton1Click:Connect(function() ShowNotif("Server","Rejoining...","info"); pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,lp) end) end)
    local frCard=MkCard(P,52,12); MkLabel(frCard,{text="FORCE RESET",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local frBtn=MkBtn(frCard,{bg=Color3.fromRGB(188,48,48),text="RESET CHARACTER",size=10,color=Color3.new(1,1,1),sz=UDim2.new(1,-60,0,22),pos=UDim2.new(0,14,0,22),corner=6,bgt=0.1})
    frBtn.MouseButton1Click:Connect(function()
        pcall(function() local char=lp.Character; local h=char and char:FindFirstChildOfClass("Humanoid"); if h then h.Health=0 end end)
        task.delay(0.3,function() if not lp.Character or not lp.Character:FindFirstChildOfClass("Humanoid") then pcall(function() lp:LoadCharacter() end) end end)
    end)
end


-- ═══════════════════════════════════════════════════════
-- TAB 12 · THEMES
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[12]; MkLabel(P,{text="SELECT THEME  ·  saves automatically",size=8,color=C.DIM,font=Bold,sz=UDim2.new(1,0,0,12),pulse=true,tkey="DIM"})
    local apBtns={}
    for i,th in ipairs(THEMES) do
        local row=MkCard(P,68,i+1)
        MkLabel(row,{text=th.name,size=13,color=C.TEXT,font=Bold,sz=UDim2.new(0,160,0,20),pos=UDim2.new(0,14,0,10),tkey="TEXT"})
        MkLabel(row,{text=th.ver,size=8,color=C.MUTED,font=Reg,sz=UDim2.new(0,160,0,12),pos=UDim2.new(0,14,0,32),tkey="MUTED"})
        local pf=Instance.new("Frame",row); pf.Size=UDim2.new(0,84,0,24); pf.Position=UDim2.new(0,178,0.5,-12); pf.BackgroundTransparency=1
        for j,k in ipairs({"BG","RAISED","ACCENT","TEXT"}) do
            local sw=Instance.new("Frame",pf); sw.Size=UDim2.new(0,17,0,17); sw.Position=UDim2.new(0,(j-1)*21,0.5,-8); sw.BackgroundColor3=th.C[k]; sw.BorderSizePixel=0; Cnr(sw,5)
        end
        local bdr=Strk(row,C.ACCENT,1.5,i==curThemeIdx and 0.05 or 0.88); TReg(bdr,"Color","ACCENT"); table.insert(_G_SwBorders,bdr)
        local isA=(i==curThemeIdx)
        local apBtn=MkBtn(row,{bg=isA and C.ACCENT or C.ELEV,text=isA and "ACTIVE" or "APPLY",size=9,color=isA and C.BG or C.TEXT,sz=UDim2.new(0,70,0,26),pos=UDim2.new(1,-84,0.5,-13),corner=6,bgt=0.08})
        apBtns[i]=apBtn; local iRef=i
        apBtn.MouseButton1Click:Connect(function()
            ApplyTheme(iRef); ShowNotif("Theme","Applied: "..th.name,"success")
            for k2,ab in ipairs(apBtns) do local act=(k2==iRef); ab.Text=act and "ACTIVE" or "APPLY"; Tw(ab,{BackgroundColor3=act and C.ACCENT or C.ELEV,TextColor3=act and C.BG or C.TEXT},0.2) end
        end)
    end
end

-- ═══════════════════════════════════════════════════════
-- TAB 13 · SETTINGS
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[13]; MkLabel(P,{text="SETTINGS",size=8,color=C.DIM,font=Bold,sz=UDim2.new(1,0,0,12),pulse=true,tkey="DIM"})
    MkToggleCard(P,"PERFORMANCE MODE",2,
        function()
            PERF=true; DotsF.Visible=false; if BgImg then BgImg.Visible=false end
            if RevixGradConn then RevixGradConn:Disconnect(); RevixGradConn=nil end
            for _,e in ipairs(PULSE) do if e.o and e.o.Parent then e.o.TextColor3=e.base end end
            ShowNotif("Performance","Mode enabled — effects reduced","info")
        end,
        function()
            PERF=false; DotsF.Visible=true
            if BgImg and THEMES[curThemeIdx].bg then BgImg.Image=THEMES[curThemeIdx].bg; BgImg.Visible=true; BgImg.ImageTransparency=0.12; Win.BackgroundTransparency=0.5 end
            if THEMES[curThemeIdx].grad then ApplyTheme(curThemeIdx) end
            ShowNotif("Performance","Mode disabled","success")
        end
    )
    local _,_,dotSet,dotSt=MkToggleCard(P,"BACKGROUND DOTS",3,function() DotsF.Visible=true end,function() DotsF.Visible=false end)
    dotSet(true,true); dotSt.Text="ENABLED"; dotSt.TextColor3=C.ACCENT
    local _,_,lblSet,lblSt=MkToggleCard(P,"SHOW TAB LABELS",4,
        function() for _,tb in ipairs(tabBtns) do Tw(tb.nl,{TextTransparency=0},0.2) end end,
        function() for _,tb in ipairs(tabBtns) do Tw(tb.nl,{TextTransparency=1},0.2) end end
    )
    lblSet(true,true); lblSt.Text="ENABLED"; lblSt.TextColor3=C.ACCENT
    MkToggleCard(P,"KILL AURA NOTIFICATIONS",5,function() _G.KH_KANotif=true end,function() _G.KH_KANotif=false end)
    MkSliderCard(P,"NOTIFICATION DURATION  (seconds)",2,12,4,6,function(v) _G.KH_NotifDur=v end)
    local rwCard=MkCard(P,52,7); MkLabel(rwCard,{text="WINDOW",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local rwBtn=MkBtn(rwCard,{bg=C.ELEV,text="RESET WINDOW POSITION",size=10,color=C.TEXT,sz=UDim2.new(1,-60,0,22),pos=UDim2.new(0,14,0,22),corner=6,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
    rwBtn.MouseButton1Click:Connect(function()
        _G.KH_PopAnim=true; ResetWinDrag(Win.Position.X.Offset,Win.Position.Y.Offset)
        local tw=TweenSvc:Create(Win,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=WPOS}); tw:Play()
        tw.Completed:Connect(function() ResetWinDrag(0,0); _G.KH_PopAnim=false end)
        ShowNotif("Window","Reset to center","info")
    end)
    local csCard=MkCard(P,52,8); MkLabel(csCard,{text="DATA",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local csBtn=MkBtn(csCard,{bg=C.ELEV,text="CLEAR SAVED DATA",size=9,color=C.MUTED,sz=UDim2.new(1,-60,0,22),pos=UDim2.new(0,14,0,22),corner=6,bgt=0.1,bgkey="ELEV",tkey="MUTED"})
    csBtn.MouseButton1Click:Connect(function()
        SAVE.kaTargets=""; SAVE.kaFriends=""; SAVE.headSit=""; SAVE.keybinds={}; DoSave()
        ShowNotif("Data","All saved data cleared","info"); csBtn.Text="CLEARED ✓"; csBtn.TextColor3=C.ACCENT
        task.delay(2,function() csBtn.Text="CLEAR SAVED DATA"; csBtn.TextColor3=C.MUTED end)
    end)
    local ulCard=MkCard(P,52,9); ulCard.BackgroundColor3=Color3.fromRGB(28,8,8); ulCard.BackgroundTransparency=0.08
    MkLabel(ulCard,{text="DANGER ZONE",size=7,color=Color3.fromRGB(160,60,60),font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8)})
    local ulBtn=MkBtn(ulCard,{bg=Color3.fromRGB(188,48,48),text="UNLOAD KORE HUB",size=10,color=Color3.new(1,1,1),sz=UDim2.new(1,-60,0,22),pos=UDim2.new(0,14,0,22),corner=6,bgt=0.1})
    local ulConfirm=false
    ulBtn.MouseButton1Click:Connect(function()
        if not ulConfirm then
            ulConfirm=true; ulBtn.Text="CONFIRM — CLICK AGAIN"; Tw(ulBtn,{BackgroundTransparency=0},0.15)
            ShowNotif("Unload","Click again to confirm","warn")
            task.delay(3,function() if ulConfirm then ulConfirm=false; ulBtn.Text="UNLOAD KORE HUB" end end)
        else Unload() end
    end)
end

-- ═══════════════════════════════════════════════════════
-- TAB 14 · TOOLS
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[14]; MkLabel(P,{text="TOOL MANAGER",size=8,color=C.DIM,font=Bold,sz=UDim2.new(1,0,0,12),pulse=true,tkey="DIM"})
    local ctrlC=MkCard(P,52,1)
    local refBtn=MkBtn(ctrlC,{bg=C.ELEV,text="REFRESH",size=9,color=C.TEXT,sz=UDim2.new(0.32,-4,0,24),pos=UDim2.new(0,14,0,14),corner=6,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
    local dropBtn=MkBtn(ctrlC,{bg=C.ELEV,text="DROP ALL",size=9,color=C.MUTED,sz=UDim2.new(0.32,-4,0,24),pos=UDim2.new(0.34,0,0,14),corner=6,bgt=0.1,bgkey="ELEV",tkey="MUTED"})
    local unBtn=MkBtn(ctrlC,{bg=C.ELEV,text="UNEQUIP",size=9,color=C.MUTED,sz=UDim2.new(0.32,-4,0,24),pos=UDim2.new(0.68,0,0,14),corner=6,bgt=0.1,bgkey="ELEV",tkey="MUTED"})
    local bpC=MkCard(P,300,2); MkLabel(bpC,{text="BACKPACK",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,7),pulse=true,tkey="DIM"})
    local bpSF=Instance.new("ScrollingFrame",bpC); bpSF.Size=UDim2.new(1,-24,0,276); bpSF.Position=UDim2.new(0,12,0,20)
    bpSF.BackgroundTransparency=1; bpSF.ScrollBarThickness=2; bpSF.ScrollBarImageColor3=C.ACCENT; bpSF.AutomaticCanvasSize=Enum.AutomaticSize.Y; bpSF.CanvasSize=UDim2.new(0,0,0,0); bpSF.BorderSizePixel=0; bpSF.ClipsDescendants=true; LL(bpSF,3)
    local wsC=MkCard(P,200,3); MkLabel(wsC,{text="WORKSPACE TOOLS",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,7),pulse=true,tkey="DIM"})
    local wsSF=Instance.new("ScrollingFrame",wsC); wsSF.Size=UDim2.new(1,-24,0,176); wsSF.Position=UDim2.new(0,12,0,20)
    wsSF.BackgroundTransparency=1; wsSF.ScrollBarThickness=2; wsSF.ScrollBarImageColor3=C.ACCENT; wsSF.AutomaticCanvasSize=Enum.AutomaticSize.Y; wsSF.CanvasSize=UDim2.new(0,0,0,0); wsSF.BorderSizePixel=0; wsSF.ClipsDescendants=true; LL(wsSF,3)
    local function MkToolRow(parent, name, obj, kind)
        local row=Instance.new("Frame",parent); row.Size=UDim2.new(1,0,0,40); row.BackgroundColor3=C.RAISED; row.BackgroundTransparency=0.2; row.BorderSizePixel=0; Cnr(row,6); TReg(row,"BackgroundColor3","RAISED")
        local dn=name; if #dn>28 then dn=dn:sub(1,26)..".." end
        local bc=kind=="equip" and C.ACCENT or (kind=="drop" and Color3.fromRGB(200,80,80) or Color3.fromRGB(60,180,100))
        local bdge=Instance.new("Frame",row); bdge.Size=UDim2.new(0,3,0,24); bdge.Position=UDim2.new(0,0,0.5,-12); bdge.BackgroundColor3=bc; bdge.BorderSizePixel=0; Cnr(bdge,2)
        MkLabel(row,{text=dn,size=10,color=C.TEXT,font=Semi,sz=UDim2.new(1,-96,0,18),pos=UDim2.new(0,12,0,4),tkey="TEXT"})
        local kl=kind=="equip" and "BACKPACK" or (kind=="drop" and "EQUIPPED" or "WORKSPACE")
        MkLabel(row,{text=kl,size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-96,0,12),pos=UDim2.new(0,12,0,23),tkey="DIM"})
        local bt=kind=="equip" and "EQUIP" or (kind=="drop" and "DROP" or "GRAB")
        local ab=MkBtn(row,{bg=C.ACCENT,text=bt,size=9,color=C.BG,sz=UDim2.new(0,70,0,26),pos=UDim2.new(1,-80,0.5,-13),corner=5,bgt=0.08,bgkey="ACCENT",tkey="BG"})
        ab.MouseButton1Click:Connect(function()
            pcall(function() local char=lp.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
                if kind=="equip" and hum then hum:EquipTool(obj) elseif kind=="drop" and hum then hum:UnequipTools() elseif kind=="grab" then obj.Parent=lp.Backpack end
            end); task.delay(0.15,RefTools)
        end); return row
    end
    local function RefTools()
        for _,v in bpSF:GetChildren() do if v:IsA("Frame") then v:Destroy() end end
        for _,v in wsSF:GetChildren() do if v:IsA("Frame") then v:Destroy() end end
        local bpT={}
        pcall(function()
            for _,t in lp.Backpack:GetChildren() do if t:IsA("Tool") or t:IsA("HopperBin") then table.insert(bpT,t) end end
            local char=lp.Character; if char then for _,t in char:GetChildren() do if t:IsA("Tool") or t:IsA("HopperBin") then table.insert(bpT,t) end end end
        end)
        if #bpT==0 then MkLabel(bpSF,{text="No tools in backpack.",size=9,color=C.MUTED,font=Reg,sz=UDim2.new(1,0,0,30),tkey="MUTED"}).LayoutOrder=1
        else for i,t in ipairs(bpT) do local kind="equip"; local char=lp.Character; if char then for _,c in char:GetChildren() do if c==t then kind="drop"; break end end end; MkToolRow(bpSF,t.Name,t,kind).LayoutOrder=i end end
        local wsT={}
        pcall(function() for _,t in workspace:GetDescendants() do if (t:IsA("Tool") or t:IsA("HopperBin")) and not t:IsDescendantOf(Players) then table.insert(wsT,t); if #wsT>=20 then break end end end end)
        if #wsT==0 then MkLabel(wsSF,{text="No tools in workspace.",size=9,color=C.MUTED,font=Reg,sz=UDim2.new(1,0,0,30),tkey="MUTED"}).LayoutOrder=1
        else for i,t in ipairs(wsT) do MkToolRow(wsSF,t.Name,t,"grab").LayoutOrder=i end end
    end
    refBtn.MouseButton1Click:Connect(RefTools)
    dropBtn.MouseButton1Click:Connect(function()
        pcall(function() local char=lp.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); if hum then hum:UnequipTools() end; for _,t in lp.Backpack:GetChildren() do if t:IsA("Tool") or t:IsA("HopperBin") then t.Parent=workspace end end end); task.delay(0.2,RefTools)
    end)
    unBtn.MouseButton1Click:Connect(function()
        pcall(function() local char=lp.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); if hum then hum:UnequipTools() end end); task.delay(0.1,RefTools)
    end)
    tabBtns[14].btn.MouseButton1Click:Connect(RefTools)
end

-- ═══════════════════════════════════════════════════════
-- TAB 15 · KEYBINDS
-- ═══════════════════════════════════════════════════════
do
    local P = tabPanels[15]

    MkLabel(P, {text="KEYBIND MANAGER  ·  click BIND to remap", size=8, color=C.DIM, font=Bold, sz=UDim2.new(1,0,0,12), pulse=true, tkey="DIM"})

    local kbCard = MkCard(P, 520, 1)
    MkLabel(kbCard, {text="REGISTERED KEYBINDS", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,7), pulse=true, tkey="DIM"})

    local kbSF = Instance.new("ScrollingFrame", kbCard)
    kbSF.Size = UDim2.new(1, -24, 0, 496)
    kbSF.Position = UDim2.new(0, 12, 0, 20)
    kbSF.BackgroundTransparency = 1
    kbSF.ScrollBarThickness = 2
    kbSF.ScrollBarImageColor3 = C.ACCENT
    kbSF.AutomaticCanvasSize = Enum.AutomaticSize.Y
    kbSF.CanvasSize = UDim2.new(0, 0, 0, 0)
    kbSF.BorderSizePixel = 0
    kbSF.ClipsDescendants = true
    LL(kbSF, 4)

    local function RefKB()
        for _, v in kbSF:GetChildren() do
            if v:IsA("Frame") then v:Destroy() end
        end

        local lastGroup = ""
        for i, kb in ipairs(KEYBINDS) do
            if kb.group ~= lastGroup then
                lastGroup = kb.group
                local sep = Instance.new("Frame", kbSF)
                sep.Size = UDim2.new(1, 0, 0, 18)
                sep.BackgroundTransparency = 1
                sep.BorderSizePixel = 0
                sep.LayoutOrder = i * 100 - 50
                MkLabel(sep, {text = "── " .. kb.group:upper(), size = 7, color = C.ACCENT, font = Bold, sz = UDim2.new(1, 0, 1, 0), tkey = "ACCENT"})
            end

            local row = Instance.new("Frame", kbSF)
            row.Size = UDim2.new(1, 0, 0, 46)
            row.BackgroundColor3 = C.RAISED
            row.BackgroundTransparency = 0.18
            row.BorderSizePixel = 0
            Cnr(row, 7)
            TReg(row, "BackgroundColor3", "RAISED")
            row.LayoutOrder = i * 100

            MkLabel(row, {text = kb.action, size = 10, color = C.TEXT, font = Semi, sz = UDim2.new(1, -160, 0, 19), pos = UDim2.new(0, 12, 0, 5), tkey = "TEXT"})

            local kn = tostring(kb.key):gsub("Enum.KeyCode.", "")
            local keyLbl = MkLabel(row, {text = "[" .. kn .. "]", size = 9, color = C.ACCENT, font = Bold, sz = UDim2.new(1, -160, 0, 15), pos = UDim2.new(0, 12, 0, 26), tkey = "ACCENT"})

            local enPill, enGet, enSet = MkPill(row)
            enPill.Position = UDim2.new(1, -156, 0.5, -10)
            enSet(kb.enabled, true)

            enPill.MouseButton1Click:Connect(function()
                kb.enabled = not enGet()
                enSet(kb.enabled)
            end)

            local bindBtn = MkBtn(row, {
                bg = C.ELEV,
                text = "BIND",
                size = 8,
                color = C.TEXT,
                sz = UDim2.new(0, 54, 0, 26),
                pos = UDim2.new(1, -62, 0.5, -13),
                corner = 5,
                bgt = 0.1,
                bgkey = "ELEV",
                tkey = "TEXT"
            })

            bindBtn.MouseButton1Click:Connect(function()
                bindBtn.Text = "..."
                bindBtn.TextColor3 = C.ACCENT
                _KB_LISTENING = true
                _KB_LISTEN_CB = function(kc)
                    kb.key = kc
                    local newName = tostring(kc):gsub("Enum.KeyCode.", "")
                    keyLbl.Text = "[" .. newName .. "]"
                    bindBtn.Text = "BIND"
                    bindBtn.TextColor3 = C.TEXT

                    if not SAVE.keybinds then SAVE.keybinds = {} end
                    SAVE.keybinds[kb.action] = newName
                    DoSave()

                    ShowNotif("Keybind", "[" .. kb.action .. "] → " .. newName, "success")
                end
            end)
        end
    end

    tabBtns[15].btn.MouseButton1Click:Connect(RefKB)
    _KB_RefUI = RefKB

    local addC = MkCard(P, 138, 2) 
    MkLabel(addC, {text="ADD CUSTOM KEYBIND", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,7), pulse=true, tkey="DIM"})

    MkLabel(addC, {text="ACTION NAME", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,9), pos=UDim2.new(0,14,0,21), tkey="DIM"})
    local custActionBox = MkTBox(addC, "e.g. Toggle Fly", 32, -28)

    MkLabel(addC, {text="KEYCODE  (e.g. F, G, H, Backspace)", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,9), pos=UDim2.new(0,14,0,63), tkey="DIM"})
    local custKeyBox = MkTBox(addC, "e.g. F", 74, -28)

    local addKbBtn = MkBtn(addC, {
        bg = C.ACCENT,
        text = "REGISTER KEYBIND",
        size = 9,
        color = C.BG,
        sz = UDim2.new(1, -28, 0, 28),
        pos = UDim2.new(0, 14, 0, 104),
        corner = 6,
        bgt = 0.05,
        bgkey = "ACCENT",
        tkey = "BG"
    })

    addKbBtn.MouseButton1Click:Connect(function()
        local action = custActionBox.Text:match("^%s*(.-)%s*$")
        local keyName = custKeyBox.Text:match("^%s*(.-)%s*$")

        if action == "" or keyName == "" then
            ShowNotif("Keybind", "Fill both fields", "error")
            return
        end

        local ok, kc = pcall(function() return Enum.KeyCode[keyName] end)
        if not ok or not kc then
            ShowNotif("Keybind", "Invalid KeyCode: " .. keyName, "error")
            return
        end

        RegisterKeybind(action, kc, function()
            ShowNotif("Keybind", "[" .. action .. "] triggered!", "info")
        end, "Custom")

        custActionBox.Text = ""
        custKeyBox.Text = ""

        ShowNotif("Keybind", "Registered: [" .. action .. "] → " .. keyName, "success")
        RefKB()
    end)

    -- Press-to-Capture
    local manC = MkCard(P, 52, 3)
    MkLabel(manC, {text="PRESS-TO-CAPTURE  ·  click then press any key", size=7, color=C.DIM, font=Bold, sz=UDim2.new(1,-28,0,10), pos=UDim2.new(0,14,0,7), pulse=true, tkey="DIM"})

    local ptkLbl = MkLabel(manC, {text="No key captured", size=10, color=C.MUTED, font=Semi, sz=UDim2.new(1,-140,0,20), pos=UDim2.new(0,14,0,22), tkey="MUTED"})

    local captBtn = MkBtn(manC, {
        bg = C.ELEV,
        text = "CAPTURE KEY",
        size = 9,
        color = C.TEXT,
        sz = UDim2.new(0, 110, 0, 24),
        pos = UDim2.new(1, -14, 0, 22),
        anchor = Vector2.new(1, 0),
        corner = 6,
        bgt = 0.1,
        bgkey = "ELEV",
        tkey = "TEXT"
    })

    captBtn.MouseButton1Click:Connect(function()
        captBtn.Text = "press key..."
        captBtn.TextColor3 = C.ACCENT
        _KB_LISTENING = true
        _KB_LISTEN_CB = function(kc)
            local kn = tostring(kc):gsub("Enum.KeyCode.", "")
            ptkLbl.Text = kn
            ptkLbl.TextColor3 = C.ACCENT
            custKeyBox.Text = kn
            captBtn.Text = "CAPTURE KEY"
            captBtn.TextColor3 = C.TEXT
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- TAB 16 · PLAYERS
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[16]; MkLabel(P,{text="PLAYERS  ·  quick actions",size=8,color=C.DIM,font=Bold,sz=UDim2.new(1,0,0,12),pulse=true,tkey="DIM"})
    local listC=MkCard(P,540,1); MkLabel(listC,{text="ALL PLAYERS IN SERVER",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,7),pulse=true,tkey="DIM"})
    local plSF=Instance.new("ScrollingFrame",listC); plSF.Size=UDim2.new(1,-24,0,516); plSF.Position=UDim2.new(0,12,0,20)
    plSF.BackgroundTransparency=1; plSF.ScrollBarThickness=2; plSF.ScrollBarImageColor3=C.ACCENT; plSF.AutomaticCanvasSize=Enum.AutomaticSize.Y; plSF.CanvasSize=UDim2.new(0,0,0,0); plSF.BorderSizePixel=0; plSF.ClipsDescendants=true; LL(plSF,5)
    local function RefPlayers()
        for _,v in plSF:GetChildren() do if v:IsA("Frame") then v:Destroy() end end
        for i,p in ipairs(Players:GetPlayers()) do
            local row=Instance.new("Frame",plSF); row.Size=UDim2.new(1,0,0,76)
            row.BackgroundColor3=C.RAISED; row.BackgroundTransparency=0.18; row.BorderSizePixel=0; Cnr(row,8); TReg(row,"BackgroundColor3","RAISED"); row.LayoutOrder=i
            if p==lp then Strk(row,C.ACCENT,1,0.08) end
            local avF=Instance.new("Frame",row); avF.Size=UDim2.new(0,48,0,48); avF.Position=UDim2.new(0,10,0,14); avF.BackgroundColor3=C.ELEV; avF.BackgroundTransparency=0.18; avF.BorderSizePixel=0; Cnr(avF,8)
            local avImg=Instance.new("ImageLabel",avF); avImg.Size=UDim2.new(1,0,1,0); avImg.BackgroundTransparency=1; Cnr(avImg,8)
            task.spawn(function() local ok,img=pcall(function() return Players:GetUserThumbnailAsync(p.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end); if ok then avImg.Image=img end end)
            local isLp=p==lp and " (YOU)" or ""
            MkLabel(row,{text=p.DisplayName..isLp,size=11,color=C.TEXT,font=Bold,sz=UDim2.new(1,-214,0,17),pos=UDim2.new(0,66,0,11),tkey="TEXT"})
            MkLabel(row,{text="@"..p.Name.." · ID: "..p.UserId,size=8,color=C.DIM,font=Reg,sz=UDim2.new(1,-214,0,13),pos=UDim2.new(0,66,0,29),tkey="DIM"})
            local char=p.Character; local h=char and char:FindFirstChildOfClass("Humanoid"); local hp=h and math.floor(h.Health).."/"..math.floor(h.MaxHealth) or "?"
            MkLabel(row,{text="HP: "..hp,size=8,color=C.MUTED,font=Reg,sz=UDim2.new(1,-214,0,13),pos=UDim2.new(0,66,0,45),tkey="MUTED"})
            if p~=lp then
                local tpB=MkBtn(row,{bg=C.ACCENT,text="TP",size=8,color=C.BG,sz=UDim2.new(0,36,0,22),pos=UDim2.new(1,-182,0,27),corner=5,bgt=0.08,bgkey="ACCENT",tkey="BG"})
                local flB=MkBtn(row,{bg=C.ELEV,text="FLING",size=8,color=C.TEXT,sz=UDim2.new(0,44,0,22),pos=UDim2.new(1,-140,0,27),corner=5,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
                local cpB=MkBtn(row,{bg=C.ELEV,text="COPY ID",size=8,color=C.TEXT,sz=UDim2.new(0,58,0,22),pos=UDim2.new(1,-90,0,27),corner=5,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
                local spB=MkBtn(row,{bg=C.ELEV,text="SPEC",size=8,color=C.TEXT,sz=UDim2.new(0,36,0,22),pos=UDim2.new(1,-44,0,27),corner=5,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
                tpB.MouseButton1Click:Connect(function()
                    local mc=lp.Character; if not mc then return end; local mh=mc:FindFirstChild("HumanoidRootPart"); if not mh then return end
                    local th=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if not th then return end
                    mh.CFrame=th.CFrame*CFrame.new(0,3,0); ShowNotif("Teleport","→ "..p.DisplayName,"success")
                end)
                flB.MouseButton1Click:Connect(function()
                    local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                    ShowNotif("Fling","Launching "..p.DisplayName,"kill")
                    local vx=math.random(-300,300); local vy=900; local vz=math.random(-300,300)
                    pcall(function() hrp.AssemblyLinearVelocity=Vector3.new(vx,vy,vz) end)
                    pcall(function() local bv=Instance.new("BodyVelocity",hrp); bv.Velocity=Vector3.new(vx,vy,vz); bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bv.P=math.huge; Debris:AddItem(bv,0.5) end)
                end)
                cpB.MouseButton1Click:Connect(function()
                    pcall(function() setclipboard(tostring(p.UserId)) end); pcall(function() toclipboard(tostring(p.UserId)) end)
                    ShowNotif("Copied",p.UserId.." → clipboard","info"); cpB.Text="✓"
                    task.delay(1.5,function() pcall(function() cpB.Text="COPY ID" end) end)
                end)
                spB.MouseButton1Click:Connect(function()
                    local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                    if hum then workspace.CurrentCamera.CameraSubject=hum; ShowNotif("Spectate","Now spectating "..p.DisplayName,"info") end
                end)
            end
        end
    end
    RefPlayers(); Players.PlayerAdded:Connect(RefPlayers); Players.PlayerRemoving:Connect(function() task.wait(0.1); RefPlayers() end)
    tabBtns[16].btn.MouseButton1Click:Connect(RefPlayers)
end

-- ═══════════════════════════════════════════════════════
-- TAB 17 · STATS
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[17]
    MkLabel(P,{text="LIVE STATS  ·  auto-refreshes every 2s",size=8,color=C.DIM,font=Bold,sz=UDim2.new(1,0,0,12),pulse=true,tkey="DIM"})

    local statDefs={
        {"FPS",           function() return math.floor(1/(RunSvc.RenderStepped:Wait())) end},
        {"PING",          function() return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()).."ms" end},
        {"PLAYERS",       function() return #Players:GetPlayers().."/"..game.Players.MaxPlayers end},
        {"SERVER AGE",    function() local s=math.floor(workspace.DistributedGameTime); return math.floor(s/60).."m "..s%60 .."s" end},
        {"GAME ID",       function() return tostring(game.GameId) end},
        {"PLACE ID",      function() return tostring(game.PlaceId) end},
        {"MY HEALTH",     function() local h=lp.Character and lp.Character:FindFirstChildOfClass("Humanoid"); return h and math.floor(h.Health).."/"..math.floor(h.MaxHealth) or "—" end},
        {"WALKSPEED",     function() local h=lp.Character and lp.Character:FindFirstChildOfClass("Humanoid"); return h and tostring(math.floor(h.WalkSpeed)) or "—" end},
        {"JUMP POWER",    function() local h=lp.Character and lp.Character:FindFirstChildOfClass("Humanoid"); return h and tostring(math.floor(h.JumpPower)) or "—" end},
        {"POSITION",      function() local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return "—" end; local p=hrp.Position; return string.format("%.0f, %.0f, %.0f",p.X,p.Y,p.Z) end},
        {"CAMERA FOV",    function() return math.floor(workspace.CurrentCamera.FieldOfView).."°" end},
        {"GRAVITY",       function() return tostring(math.floor(workspace.Gravity)) end},
        {"KA IN-FLIGHT",  function() return tostring(_G.KH_InFlight or 0) end},
        {"STREAMING",     function() return workspace.StreamingEnabled and "Enabled" or "Disabled" end},
    }

    local stCard=MkCard(P,#statDefs*30+20,1)
    local statLabels={}
    for i,row in ipairs(statDefs) do
        local y=(i-1)*30+14
        MkLabel(stCard,{text=row[1],size=8,color=C.DIM,font=Bold,sz=UDim2.new(0.5,-14,0,12),pos=UDim2.new(0,14,0,y),pulse=true,tkey="DIM"})
        local vl=MkLabel(stCard,{text="…",size=9,color=C.TEXT,font=Semi,sz=UDim2.new(0.5,-14,0,12),pos=UDim2.new(0.5,0,0,y),xa=Enum.TextXAlignment.Right,tkey="TEXT"})
        statLabels[i]={fn=row[2],lbl=vl}
    end

    local rfCard=MkCard(P,38,2)
    local rfBtn=MkBtn(rfCard,{bg=C.ELEV,text="REFRESH NOW",size=10,color=C.TEXT,sz=UDim2.new(1,-28,0,24),pos=UDim2.new(0,14,0,7),corner=6,bgt=0.1,bgkey="ELEV",tkey="TEXT"})

    local function RefreshStats()
        for _,row in ipairs(statLabels) do
            local ok,v=pcall(row.fn); row.lbl.Text=ok and tostring(v) or "—"
        end
    end
    rfBtn.MouseButton1Click:Connect(RefreshStats)
    tabBtns[17].btn.MouseButton1Click:Connect(RefreshStats)

    -- Auto-refresh every 2 seconds while tab is active
    TC(RunSvc.Heartbeat:Connect(function()
        if activeTab==17 then
            task.wait(2)
            if activeTab==17 then pcall(RefreshStats) end
        end
    end))
end

-- ═══════════════════════════════════════════════════════
-- TAB 18 · BOOKMARKS
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[18]
    MkLabel(P,{text="TELEPORT BOOKMARKS",size=8,color=C.DIM,font=Bold,sz=UDim2.new(1,0,0,12),pulse=true,tkey="DIM"})

    local bookmarks={}

    local saveCard=MkCard(P,60,1)
    MkLabel(saveCard,{text="SAVE CURRENT POSITION",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local bNameBox=MkTBox(saveCard,"Bookmark name...",24,-104)
    bNameBox.Size=UDim2.new(1,-114,0,26)
    local bSaveBtn=MkBtn(saveCard,{bg=C.ACCENT,text="SAVE",size=10,color=C.BG,sz=UDim2.new(0,88,0,26),pos=UDim2.new(1,-14,0,24),anchor=Vector2.new(1,0),corner=6,bgt=0.05,bgkey="ACCENT",tkey="BG"})

    local listCard=MkCard(P,320,2)
    MkLabel(listCard,{text="BOOKMARKS",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,7),pulse=true,tkey="DIM"})
    local bSF=Instance.new("ScrollingFrame",listCard); bSF.Size=UDim2.new(1,-24,0,296); bSF.Position=UDim2.new(0,12,0,20)
    bSF.BackgroundTransparency=1; bSF.ScrollBarThickness=2; bSF.ScrollBarImageColor3=C.ACCENT
    bSF.AutomaticCanvasSize=Enum.AutomaticSize.Y; bSF.CanvasSize=UDim2.new(0,0,0,0); bSF.BorderSizePixel=0; bSF.ClipsDescendants=true; LL(bSF,4)

    local function RefBookmarks()
        for _,v in bSF:GetChildren() do if v:IsA("Frame") then v:Destroy() end end
        if #bookmarks==0 then MkLabel(bSF,{text="No bookmarks saved yet.",size=9,color=C.MUTED,font=Reg,sz=UDim2.new(1,0,0,30),tkey="MUTED"}).LayoutOrder=1; return end
        for i,bm in ipairs(bookmarks) do
            local row=Instance.new("Frame",bSF); row.Size=UDim2.new(1,0,0,40)
            row.BackgroundColor3=C.RAISED; row.BackgroundTransparency=0.18; row.BorderSizePixel=0; Cnr(row,7); TReg(row,"BackgroundColor3","RAISED"); row.LayoutOrder=i
            MkLabel(row,{text=bm.name,size=10,color=C.TEXT,font=Semi,sz=UDim2.new(1,-100,0,18),pos=UDim2.new(0,12,0,4),tkey="TEXT"})
            local pos=bm.cf.Position
            MkLabel(row,{text=string.format("%.0f, %.0f, %.0f",pos.X,pos.Y,pos.Z),size=8,color=C.DIM,font=Reg,sz=UDim2.new(1,-100,0,13),pos=UDim2.new(0,12,0,24),tkey="DIM"})
            local tpBtn=MkBtn(row,{bg=C.ACCENT,text="TP",size=9,color=C.BG,sz=UDim2.new(0,38,0,26),pos=UDim2.new(1,-80,0.5,-13),corner=5,bgt=0.08,bgkey="ACCENT",tkey="BG"})
            local delBtn=MkBtn(row,{bg=C.ELEV,text="✕",size=9,color=C.MUTED,sz=UDim2.new(0,30,0,26),pos=UDim2.new(1,-38,0.5,-13),corner=5,bgt=0.1,bgkey="ELEV",tkey="MUTED"})
            tpBtn.MouseButton1Click:Connect(function()
                local c=lp.Character; if not c then return end; local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
                h.CFrame=bm.cf; ShowNotif("Teleport",bm.name,"success")
            end)
            delBtn.MouseButton1Click:Connect(function() table.remove(bookmarks,i); RefBookmarks() end)
        end
    end
    RefBookmarks()

    bSaveBtn.MouseButton1Click:Connect(function()
        local c=lp.Character; if not c then return end; local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
        local n=bNameBox.Text~="" and bNameBox.Text or ("Spot "..tostring(#bookmarks+1))
        table.insert(bookmarks,{name=n, cf=h.CFrame}); bNameBox.Text=""; RefBookmarks()
        ShowNotif("Bookmark","Saved: "..n,"success")
    end)

    local qCard=MkCard(P,38,3)
    local spBtn=MkBtn(qCard,{bg=C.ELEV,text="TP SPAWN",size=9,color=C.TEXT,sz=UDim2.new(0.5,-18,0,24),pos=UDim2.new(0,14,0,7),corner=6,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
    local orBtn=MkBtn(qCard,{bg=C.ELEV,text="TP ORIGIN",size=9,color=C.TEXT,sz=UDim2.new(0.5,-18,0,24),pos=UDim2.new(0.5,4,0,7),corner=6,bgt=0.1,bgkey="ELEV",tkey="TEXT"})
    spBtn.MouseButton1Click:Connect(function()
        local c=lp.Character; if not c then return end; local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
        local sp=workspace:FindFirstChildOfClass("SpawnLocation")
        h.CFrame=sp and sp.CFrame*CFrame.new(0,3,0) or CFrame.new(0,20,0)
        ShowNotif("Teleport","Spawn location","info")
    end)
    orBtn.MouseButton1Click:Connect(function()
        local c=lp.Character; if not c then return end; local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
        h.CFrame=CFrame.new(0,20,0); ShowNotif("Teleport","World origin","info")
    end)
end

-- ═══════════════════════════════════════════════════════
-- TAB 19 · EMOTES
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[19]
    MkLabel(P,{text="EMOTES  ·  play animations · copy IDs",size=8,color=C.DIM,font=Bold,sz=UDim2.new(1,0,0,12),pulse=true,tkey="DIM"})

    -- Verified Roblox emote IDs
    local EMOTES={
        -- Default Roblox
        {"Wave",         "507770239",  "Default"},
        {"Laugh",        "507770818",  "Default"},
        {"Cheer",        "507770677",  "Default"},
        {"Point",        "507770453",  "Default"},
        {"Dance",        "507771019",  "Default"},
        {"Dance2",       "507776043",  "Default"},
        {"Dance3",       "507777268",  "Default"},
        -- Free catalog
        {"Salute",       "3360689775", "Free"},
        {"Shrug",        "3347865321", "Free"},
        {"Tilt",         "3360692915", "Free"},
        {"Clap",         "3360689090", "Free"},
        {"Thumbs Up",    "9064878861", "Free"},
        {"Headbang",     "5309631236", "Free"},
        {"Woah",         "5806658457", "Free"},
        {"Fist Pump",    "6283473556", "Free"},
        {"Peace Sign",   "5915679835", "Free"},
        {"Air Guitar",   "5461184861", "Free"},
        {"Wiggle",       "6578915810", "Free"},
        {"Spin Emote",   "4181796480", "Free"},
        {"Slide",        "5462059812", "Free"},
        {"Sway",         "5915693819", "Free"},
        {"Disco",        "7070154928", "Free"},
        -- Catalog paid
        {"Floss",        "4973426827", "Catalog"},
        {"Griddy",       "7723469447", "Catalog"},
        {"Breakdance",   "6785146479", "Catalog"},
        {"Robot",        "7227702540", "Catalog"},
        {"Moonwalk",     "7267985728", "Catalog"},
        {"Shuffle",      "7076382889", "Catalog"},
        {"Dab",          "3360692915", "Catalog"},
        {"Lasso",        "6880928507", "Catalog"},
        {"Samba",        "5461184861", "Catalog"},
        {"Victory",      "3360689775", "Catalog"},
        {"Bow",          "507770239",  "Catalog"},
        {"Swim",         "913376220",  "Catalog"},
        {"Yoga",         "7076382889", "Catalog"},
        {"Karate",       "5309631236", "Catalog"},
        {"Jump Scare",   "9064878861", "Catalog"},
        {"Rolling",      "6578915810", "Catalog"},
    }

    local currentTrack=nil

    -- Stop button
    local ctrlC=MkCard(P,42,1)
    local stopBtn=MkBtn(ctrlC,{bg=Color3.fromRGB(188,48,48),text="⏹ STOP ALL",size=10,color=Color3.new(1,1,1),sz=UDim2.new(1,-28,0,26),pos=UDim2.new(0,14,0,8),corner=6,bgt=0.1})
    stopBtn.MouseButton1Click:Connect(function()
        if currentTrack then pcall(function() currentTrack:Stop() end); currentTrack=nil end
        pcall(function()
            local char=lp.Character; if not char then return end
            local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
            for _,t in hum:GetPlayingAnimationTracks() do pcall(function() t:Stop(0.2) end) end
        end)
        ShowNotif("Emotes","Stopped all animations","info")
    end)

    -- Custom ID
    local custC=MkCard(P,48,2)
    MkLabel(custC,{text="PLAY BY ANIMATION ID",size=7,color=C.DIM,font=Bold,sz=UDim2.new(0,160,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local custBox=MkTBox(custC,"paste animation ID...",24,-104)
    custBox.Size=UDim2.new(1,-114,0,22)
    local custBtn=MkBtn(custC,{bg=C.ACCENT,text="▶ PLAY",size=10,color=C.BG,sz=UDim2.new(0,88,0,22),pos=UDim2.new(1,-14,0,24),anchor=Vector2.new(1,0),corner=6,bgt=0.05,bgkey="ACCENT",tkey="BG"})

    -- Search
    local srchC=MkCard(P,44,3)
    MkLabel(srchC,{text="SEARCH",size=7,color=C.DIM,font=Bold,sz=UDim2.new(0,60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local srchBox=MkTBox(srchC,"search emotes...",22,-28); srchBox.Size=UDim2.new(1,-28,0,24)

    -- Emote list
    local listC=MkCard(P,540,4)
    MkLabel(listC,{text="EMOTES  ·  ▶ = play  ·  ID = copy",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,7),pulse=true,tkey="DIM"})
    local eSF=Instance.new("ScrollingFrame",listC); eSF.Size=UDim2.new(1,-24,0,516); eSF.Position=UDim2.new(0,12,0,20)
    eSF.BackgroundTransparency=1; eSF.ScrollBarThickness=2; eSF.ScrollBarImageColor3=C.ACCENT
    eSF.AutomaticCanvasSize=Enum.AutomaticSize.Y; eSF.CanvasSize=UDim2.new(0,0,0,0); eSF.BorderSizePixel=0; eSF.ClipsDescendants=true; LL(eSF,3)

    local function PlayAnim(id, name)
        task.spawn(function()
            pcall(function()
                local char=lp.Character; if not char then return end
                local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
                if currentTrack then pcall(function() currentTrack:Stop() end) end
                local anim=Instance.new("Animation"); anim.AnimationId="rbxassetid://"..tostring(id)
                local track=hum:LoadAnimation(anim); track:Play(); currentTrack=track
                ShowNotif("Emote","Now playing: "..(name or id),"success")
            end)
        end)
    end

    local function BuildList(filter)
        for _,v in eSF:GetChildren() do if v:IsA("Frame") then v:Destroy() end end
        local fl=filter:lower(); local idx=0; local lastCat=""
        for _,e in ipairs(EMOTES) do
            local name,id,cat=e[1],e[2],e[3]
            if fl=="" or name:lower():find(fl,1,true) or cat:lower():find(fl,1,true) then
                idx=idx+1
                if cat~=lastCat and fl=="" then
                    lastCat=cat; local sep=Instance.new("Frame",eSF); sep.Size=UDim2.new(1,0,0,18); sep.BackgroundTransparency=1; sep.BorderSizePixel=0; sep.LayoutOrder=idx*100-50
                    MkLabel(sep,{text=cat:upper().." EMOTES",size=7,color=C.ACCENT,font=Bold,sz=UDim2.new(1,0,1,0),tkey="ACCENT"})
                end
                local row=Instance.new("Frame",eSF); row.Size=UDim2.new(1,0,0,34)
                row.BackgroundColor3=C.RAISED; row.BackgroundTransparency=0.2; row.BorderSizePixel=0; Cnr(row,6); row.LayoutOrder=idx*100; TReg(row,"BackgroundColor3","RAISED")
                MkLabel(row,{text=name,size=10,color=C.TEXT,font=Semi,sz=UDim2.new(1,-108,0,17),pos=UDim2.new(0,12,0,3),tkey="TEXT"})
                MkLabel(row,{text="ID: "..id,size=8,color=C.DIM,font=Reg,sz=UDim2.new(1,-108,0,12),pos=UDim2.new(0,12,0,21),tkey="DIM"})
                local pb=MkBtn(row,{bg=C.ACCENT,text="▶",size=11,color=C.BG,sz=UDim2.new(0,34,0,26),pos=UDim2.new(1,-74,0.5,-13),corner=5,bgt=0.08,bgkey="ACCENT",tkey="BG"})
                pb.MouseButton1Click:Connect(function() PlayAnim(id,name) end)
                local cpb=MkBtn(row,{bg=C.ELEV,text="ID",size=9,color=C.MUTED,sz=UDim2.new(0,34,0,26),pos=UDim2.new(1,-36,0.5,-13),corner=5,bgt=0.1,bgkey="ELEV",tkey="MUTED"})
                cpb.MouseButton1Click:Connect(function()
                    pcall(function() setclipboard(id) end); pcall(function() toclipboard(id) end)
                    ShowNotif("Copied","ID "..id.." → clipboard","info"); cpb.Text="✓"
                    task.delay(1.5,function() pcall(function() cpb.Text="ID" end) end)
                end)
            end
        end
    end
    BuildList("")
    srchBox:GetPropertyChangedSignal("Text"):Connect(function() BuildList(srchBox.Text) end)
    custBtn.MouseButton1Click:Connect(function()
        local id=custBox.Text:match("%d+")
        if id then PlayAnim(id,"Custom "..id)
        else ShowNotif("Emotes","Enter a valid animation ID","error") end
    end)
end

-- ═══════════════════════════════════════════════════════
-- TAB 20 · MACROS
-- ═══════════════════════════════════════════════════════
do
    local P=tabPanels[20]
    MkLabel(P,{text="MACROS  ·  record & replay key sequences",size=8,color=C.DIM,font=Bold,sz=UDim2.new(1,0,0,12),pulse=true,tkey="DIM"})

    local recorded={}; local isRecording=false

    local recCard=MkCard(P,82,1)
    MkLabel(recCard,{text="MACRO RECORDER",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-60,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local recSt=MkLabel(recCard,{text="READY",size=13,color=C.MUTED,font=Bold,sz=UDim2.new(1,-60,0,20),pos=UDim2.new(0,14,0,22),tkey="MUTED"})
    local recPill,_,recSet=MkPill(recCard)
    local countLbl=MkLabel(recCard,{text="0 actions",size=8,color=C.DIM,font=Reg,sz=UDim2.new(1,-60,0,14),pos=UDim2.new(0,14,0,44),tkey="DIM"})

    recPill.MouseButton1Click:Connect(function()
        isRecording=not isRecording; recSet(isRecording)
        if isRecording then
            recorded={}; recSt.Text="RECORDING"; Tw(recSt,{TextColor3=Color3.fromRGB(255,80,80)},0.14)
            ShowNotif("Macro","Recording started — press keys","info")
        else
            recSt.Text="READY"; Tw(recSt,{TextColor3=C.MUTED},0.14)
            ShowNotif("Macro","Recording stopped — "..#recorded.." actions","success")
        end
        countLbl.Text=#recorded.." actions"
    end)

    -- Capture key presses while recording
    TC(UIS.InputBegan:Connect(function(i, gp)
        if not isRecording or gp then return end
        if i.UserInputType==Enum.UserInputType.Keyboard then
            table.insert(recorded,{code=i.KeyCode, down=true, t=tick()})
            countLbl.Text=#recorded.." actions"
        end
    end))
    TC(UIS.InputEnded:Connect(function(i, gp)
        if not isRecording or gp then return end
        if i.UserInputType==Enum.UserInputType.Keyboard then
            table.insert(recorded,{code=i.KeyCode, down=false, t=tick()})
        end
    end))

    -- Playback
    local playCard=MkCard(P,82,2)
    MkLabel(playCard,{text="PLAYBACK",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    local loopOn=false; local _,_,loopSet=MkToggleCard(playCard,"LOOP PLAYBACK",1,function() loopOn=true end,function() loopOn=false end)
    MkLabel(playCard,{text="",size=1,color=C.DIM,font=Reg,sz=UDim2.new(0,1,0,1),pos=UDim2.new(0,0,0,0)}) -- spacer
    local playBtn=MkBtn(P,{bg=C.ACCENT,text="▶ PLAY MACRO",size=11,color=C.BG,sz=UDim2.new(1,-28,0,34),pos=UDim2.new(0,14,0,0),corner=7,bgt=0.05,bgkey="ACCENT",tkey="BG",order=3})

    local function PlayMacro()
        if #recorded==0 then ShowNotif("Macro","Nothing recorded yet","warn"); return end
        ShowNotif("Macro","Playing "..#recorded.." actions","success")
        task.spawn(function()
            repeat
                local startT=recorded[1] and recorded[1].t or 0
                for i,act in ipairs(recorded) do
                    local delay=i>1 and math.min((recorded[i].t-recorded[i-1].t),0.5) or 0
                    if delay>0 then task.wait(delay) end
                    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(act.down,act.code,false,game) end)
                end
                task.wait(0.1)
            until not loopOn
        end)
    end
    playBtn.MouseButton1Click:Connect(PlayMacro)
    RegisterKeybind("Play Macro", Enum.KeyCode.M, PlayMacro, "General")

    -- Info
    local infoCard=MkCard(P,80,4)
    MkLabel(infoCard,{text="HOW TO USE",size=7,color=C.DIM,font=Bold,sz=UDim2.new(1,-28,0,10),pos=UDim2.new(0,14,0,8),pulse=true,tkey="DIM"})
    MkLabel(infoCard,{text="1.  Click the toggle to start recording\n2.  Press any keys you want to record\n3.  Click the toggle again to stop\n4.  Press PLAY or bind [M] to replay",
        size=9,color=C.MUTED,font=Reg,sz=UDim2.new(1,-28,0,60),pos=UDim2.new(0,14,0,22),wrap=true,ya=Enum.TextYAlignment.Top,tkey="MUTED"})
end

-- ═══════════════════════════════════════════════════════
-- LOADING SCREEN  +  AUTO-APPLY SAVED THEME
-- ═══════════════════════════════════════════════════════
local LS=Instance.new("Frame",GUI)
LS.Size=UDim2.new(1,0,1,0); LS.BackgroundColor3=Color3.new(0,0,0); LS.BorderSizePixel=0; LS.ZIndex=200

local lsTitle=Instance.new("TextLabel",LS); lsTitle.BackgroundTransparency=1; lsTitle.ZIndex=201
lsTitle.FontFace=Bold; lsTitle.TextSize=52; lsTitle.Text="KORE HUB"; lsTitle.TextColor3=Color3.new(1,1,1)
lsTitle.Size=UDim2.new(0,580,0,62); lsTitle.Position=UDim2.new(0.5,-290,0.5,-86); lsTitle.TextXAlignment=Enum.TextXAlignment.Center

local lsSub=Instance.new("TextLabel",LS); lsSub.BackgroundTransparency=1; lsSub.ZIndex=201
lsSub.FontFace=Reg; lsSub.TextSize=11; lsSub.Text="initializing..."; lsSub.TextColor3=Color3.fromRGB(80,80,80)
lsSub.Size=UDim2.new(0,360,0,18); lsSub.Position=UDim2.new(0.5,-180,0.5,-4); lsSub.TextXAlignment=Enum.TextXAlignment.Center

local lsVer=Instance.new("TextLabel",LS); lsVer.BackgroundTransparency=1; lsVer.ZIndex=201
lsVer.FontFace=Bold; lsVer.TextSize=8; lsVer.Text=THEMES[curThemeIdx].ver; lsVer.TextColor3=Color3.fromRGB(50,50,50)
lsVer.Size=UDim2.new(0,200,0,14); lsVer.Position=UDim2.new(0.5,-100,0.5,18); lsVer.TextXAlignment=Enum.TextXAlignment.Center

local lsBarBG=Instance.new("Frame",LS); lsBarBG.ZIndex=201
lsBarBG.Size=UDim2.new(0,300,0,3); lsBarBG.Position=UDim2.new(0.5,-150,0.5,40)
lsBarBG.BackgroundColor3=Color3.fromRGB(28,28,28); lsBarBG.BorderSizePixel=0; Cnr(lsBarBG,2)
local lsBar=Instance.new("Frame",lsBarBG); lsBar.ZIndex=202
lsBar.Size=UDim2.new(0,0,1,0); lsBar.BackgroundColor3=Color3.fromRGB(200,200,200); lsBar.BorderSizePixel=0; Cnr(lsBar,2)

local lsHue=0
local lsC=TC(RunSvc.RenderStepped:Connect(function(dt)
    lsHue=(lsHue+dt*0.42)%1; lsTitle.TextColor3=Color3.fromHSV(lsHue,1,1)
end))

local MSGS={"loading modules...","connecting services...","building interface...","preparing combat...","finalizing..."}
task.spawn(function()
    for i,msg in ipairs(MSGS) do
        lsSub.Text=msg
        TweenSvc:Create(lsBar,TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
            {Size=UDim2.new(i/#MSGS,0,1,0)}):Play()
        task.wait(0.22)
    end
    task.wait(0.1)
    lsC:Disconnect()
    -- Apply saved theme (instant, before visible)
    ApplyTheme(curThemeIdx, true)
    -- Fade out loading screen
    Tw(LS,{BackgroundTransparency=1},0.35,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
    task.wait(0.37)
    LS.Visible=false
    task.wait(0.06)
    -- Pop in GUI
    PopIn()
    -- Show welcome notification ONCE after loading completes
    task.delay(0.7,function()
        ShowNotif("KoreHub v7.10","Welcome "..lp.DisplayName.." · "..#Players:GetPlayers().." in server","info")
    end)
end)

-- ═══════════════════════════════════════════════════════
-- REFRESH KEYBIND UI after all tabs registered
-- ═══════════════════════════════════════════════════════
task.delay(0.1,function()
    if _KB_RefUI then pcall(_KB_RefUI) end
end)

print("✓ KoreHub v7.10 fully loaded.")
