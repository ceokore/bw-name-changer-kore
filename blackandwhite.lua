local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

-- REMOTES
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ColorRemote = Remotes:WaitForChild("UpdateRPColor")
local NameRemote = Remotes:WaitForChild("UpdateRPName")
local BioColorRemote = Remotes:WaitForChild("UpdateBioColor")

local isBioFunction = BioColorRemote:IsA("RemoteFunction")

-- SETTINGS
local NameSpeed = 0.08
local BioUpdateFrequency = 0.08
local FadeSpeed = 4 -- higher = faster

-- VARIABLES
local Word = Player.DisplayName or Player.Name
local charCount = 1
local lastNameUpdate = 0
local lastBioUpdate = 0
local Connection

-- ===== GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0,280,0,130)
Frame.Position = UDim2.new(.5,-140,.5,-65)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.Parent = ScreenGui

local NameBox = Instance.new("TextBox")
NameBox.Size = UDim2.new(0,240,0,35)
NameBox.Position = UDim2.new(0,20,0,15)
NameBox.PlaceholderText = "Enter RP Name"
NameBox.Text = Word
NameBox.BackgroundColor3 = Color3.fromRGB(220,220,220)
NameBox.TextColor3 = Color3.new(0,0,0)
NameBox.Parent = Frame

local Start = Instance.new("TextButton")
Start.Size = UDim2.new(0,240,0,35)
Start.Position = UDim2.new(0,20,0,70)
Start.Text = "Start"
Start.BackgroundColor3 = Color3.fromRGB(60,60,60)
Start.TextColor3 = Color3.new(1,1,1)
Start.Parent = Frame

-- ===== COLOR LOOP =====
local time = 0

local function GetBWColor(dt)
    time += dt * FadeSpeed

    -- Smooth oscillation between 0 and 1
    local alpha = (math.sin(time) + 1) / 2

    return Color3.new(0,0,0):Lerp(Color3.new(1,1,1), alpha)
end

-- ===== START FUNCTION =====
local function StartSystem()

    Word = NameBox.Text ~= "" and NameBox.Text or Word
    charCount = 1

    -- close gui
    ScreenGui:Destroy()

    Connection = RunService.Heartbeat:Connect(function(dt)

        local NewColor = GetBWColor(dt)

        -- RP COLOR
        pcall(function()
            ColorRemote:FireServer(NewColor)
        end)

        -- BIO COLOR
        lastBioUpdate += dt
        if lastBioUpdate >= BioUpdateFrequency then
            lastBioUpdate = 0

            pcall(function()
                if isBioFunction then
                    BioColorRemote:InvokeServer(NewColor)
                else
                    BioColorRemote:FireServer(NewColor)
                end
            end)
        end

        -- NAME TYPING
        lastNameUpdate += dt
        if lastNameUpdate >= NameSpeed then

            lastNameUpdate = 0

            local text = string.sub(Word,1,charCount)

            pcall(function()
                NameRemote:FireServer(text)
            end)

            charCount = (charCount >= #Word) and 1 or (charCount + 1)

        end

    end)

end

Start.MouseButton1Click:Connect(StartSystem)
