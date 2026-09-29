-- ============================================================
--  ALIEN HUB | Rayfield UI (v3.9.5 — quick actions, mobile-first)
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local cloneref = cloneref or function(obj) return obj end
local camera = workspace.CurrentCamera

-- [0] FFLAGS
pcall(function()
    setfflag("RemoteEventSingleInvocationSizeLimit", "2900")
    setfflag("TouchSenderMaxBandwidthBpsScaling", "-2147000000")
end)

-- ============================================================
--  CONFIG (toggle flags — permanent loops read these)
-- ============================================================
local Config = {
    Fly = true,
    AutoHaki = true,
    AutoV4 = true,
    FlaggedM1 = true,
    FruitM1 = true,
    TweenToPlayer = false,
    TweenToNearest = false,
    ESP = true,
    NoClip = true,
    AntiStun = true,
    IceWater = false,
}

-- ============================================================
--  HUB — shared mutable settings + feature functions
-- ============================================================
local Hub = {
    TweenSpeedVal = 180,
    TeamCheckEnabled = false,
    MinTargetLevel = 2300,
    InstaSnapDistance = 25,
    TweenRecalcThreshold = 25,
    TweenMaxRange = 20000,
    TweenXOffset = 0,
    TweenYOffset = 5,
    TweenZOffset = 5,
    FlaggedRange = 10000,
    FruitM1Range = 100,
    DragonGunEnabled = false,
    DragonGunRange = 2500,
    MobBringRange = 300,
    MobBringHold = 5,
    OrbitRadius = 67,
    OrbitSpeed = 5,
    InfJumpEnabled = false,
    DashLengthEnabled = false,
    DashLengthValue = 50,
    RemoveAnimsEnabled = false,
    PanicFleeEnabled = false,
    PanicFleeThreshold = 5500,
    PanicFleeResetHealth = 7000,
    HitboxEnabled = false,
    HitboxSize = 20,
    HitboxTransparency = 0.5,
    AntiLavaActive = false,
    DeleteShipActive = false,
    WalkOnWaterEnabled = false,
    SelectedPlayerName = nil,
    SelectedPlayerObj = nil,
    ActiveTween = nil,
    BountyMinSingle = 100000000,
    BountyMinTotal = 30000000,
    BountyMaxPages = 10,
    BountyScanTimeout = 15,
    BountyTeleportRetryWait = 12,
    BountyPostTeleportWait = 3,
    BountyMaxJoinAttempts = 10,
    ListMode = "Off",
    PlayerList = {},
}

Hub.Net, Hub.RegisterAttack, Hub.RegisterHit, Hub.NetModule = nil, nil, nil, nil
Hub.CommF, Hub.commE, Hub.MouseModule, Hub.Validator = nil, nil, nil, nil

do -- NETWORK CACHE
    local ModulesFolder = ReplicatedStorage:WaitForChild("Modules", 30)
    local Net = ModulesFolder and ModulesFolder:WaitForChild("Net", 30)
    Hub.Net = Net
    Hub.RegisterAttack = Net and Net:WaitForChild("RE/RegisterAttack", 15)
    Hub.RegisterHit = Net and Net:WaitForChild("RE/RegisterHit", 15)
    if Net then
        pcall(function() Hub.NetModule = require(Net) end)
    end
    local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
    Hub.CommF = RemotesFolder and RemotesFolder:WaitForChild("CommF_", 30)
    Hub.commE = RemotesFolder and RemotesFolder:WaitForChild("CommE", 15)
    Hub.MouseModule = ReplicatedStorage:FindFirstChild("Mouse")
    Hub.Validator = RemotesFolder and RemotesFolder:FindFirstChild("Validator")
end

-- ============================================================
--  WINDOW (config saving enabled)
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Alien Hub",
    LoadingTitle = "Alien Hub",
    LoadingSubtitle = "v3.9.5 | initializing modules...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AlienHub",
        FileName = "Config"
    },
    KeySystem = false
})

local MainTab = Window:CreateTab("Main", "home")
local CombatTab = Window:CreateTab("Combat", "swords")
local SilentAimTab = Window:CreateTab("Silent Aim", "crosshair")
local MovementTab = Window:CreateTab("Movement", "wind")
local VisualTab = Window:CreateTab("Visuals", "eye")
local PlayerTab = Window:CreateTab("Players", "users")
local TeleportsTab = Window:CreateTab("Teleports", "map")
local RacesTab = Window:CreateTab("Races", "dna")
local ServerTab = Window:CreateTab("Server", "globe")

local function Notify(title, text, duration)
    Rayfield:Notify({
        Title = title,
        Content = text,
        Duration = duration or 2,
        Image = "bell"
    })
end

-- ============================================================
--  BOUNTY HELPERS
-- ============================================================
local function FormatBounty(n)
    n = tonumber(n) or 0
    if n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    end
    return tostring(math.floor(n))
end

local function GetPlayerBounty(p)
    local data = p:FindFirstChild("Data")
    if data then
        local b = data:FindFirstChild("Bounty")
        if b and (b:IsA("NumberValue") or b:IsA("IntValue")) then
            return b.Value
        end
    end
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        local b = ls:FindFirstChild("Bounty") or ls:FindFirstChild("Honor")
        if b then
            local raw = tostring(b.Value):gsub(",", "")
            return tonumber(raw) or 0
        end
    end
    return 0
end

local function GetCurrentServerBounty()
    local total, topName, topVal = 0, "None", 0
    for _, p in ipairs(Players:GetPlayers()) do
        local b = GetPlayerBounty(p)
        total = total + b
        if b > topVal then
            topVal = b
            topName = p.Name
        end
    end
    return total, topName, topVal
end

local function httpGetJson(url)
    local body = nil
    pcall(function() body = game:HttpGet(url) end)
    if not body then
        local req = (http_request or request or (http and http.request))
        if req then
            pcall(function()
                local resp = req({Url = url, Method = "GET"})
                body = (type(resp) == "table") and (resp.Body or resp.body) or resp
            end)
        end
    end
    if not body then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if ok then return data end
    return nil
end

local function GetServerCandidates(minPlayers)
    local candidates = {}
    local data = httpGetJson("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    if data and data.data then
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                if not minPlayers or s.playing <= minPlayers then
                    table.insert(candidates, {id = s.id, playing = s.playing})
                end
            end
        end
    end
    return candidates
end

local function HopToServer(jobId)
    Notify("Server", "Teleporting...", 2)
    task.wait(0.5)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
    end)
end

-- ============================================================
--  ALLY CHECK
-- ============================================================
local function IsAlly(targetPlayer)
    if not targetPlayer then return false end
    if targetPlayer == player then return true end

    local myData = player:FindFirstChild("Data")
    local tData = targetPlayer:FindFirstChild("Data")
    if myData and tData then
        local myCrew = myData:FindFirstChild("CrewID")
        local tCrew = tData:FindFirstChild("CrewID")
        if myCrew and tCrew and myCrew.Value ~= "" and myCrew.Value == tCrew.Value then
            return true
        end
    end

    local pGui = player:FindFirstChild("PlayerGui")
    if pGui then
        local mainGui = pGui:FindFirstChild("Main")
        if mainGui then
            local alliesMenu = mainGui:FindFirstChild("Allies")
            if alliesMenu then
                local container = alliesMenu:FindFirstChild("Container")
                if container then
                    local alliesList = container:FindFirstChild("Allies")
                    if alliesList then
                        local scroll = alliesList:FindFirstChild("ScrollingFrame")
                        if scroll then
                            local frameList = scroll:FindFirstChild("Frame")
                            if frameList and frameList:FindFirstChild(targetPlayer.Name) then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ============================================================
--  PLAYER LIST SYSTEM
-- ============================================================
Hub.IsListed = function(name)
    return Hub.PlayerList[name] == true
end

-- ============================================================
--  SAFEZONE GEOMETRY + PVP STATE + TARGET FILTERS
-- ============================================================
Hub.GetPVPState, Hub.IsInCombat, Hub.ShouldSkipPlayerTarget = nil, nil, nil

do
    local SafezoneZones = {}
    local WorldOriginRef = nil

    local function GetWorldOrigin()
        if not WorldOriginRef or not WorldOriginRef.Parent then
            WorldOriginRef = workspace:FindFirstChild("_WorldOrigin")
        end
        return WorldOriginRef
    end

    local function ScanSafezones()
        SafezoneZones = {}
        local wo = GetWorldOrigin()
        if not wo then return end
        local safeZones = wo:FindFirstChild("SafeZones")
        if not safeZones then return end
        for _, child in ipairs(safeZones:GetChildren()) do
            local mesh = child:FindFirstChild("Mesh")
            if mesh and mesh:IsA("SpecialMesh") then
                SafezoneZones[#SafezoneZones + 1] = {
                    zone = child,
                    radius = child.Size.X * mesh.Scale.X / 2
                }
            end
        end
    end

    task.spawn(function()
        while true do
            local wo = GetWorldOrigin()
            local sz = wo and wo:FindFirstChild("SafeZones")
            if sz then
                ScanSafezones()
                sz.ChildAdded:Connect(ScanSafezones)
                sz.ChildRemoved:Connect(ScanSafezones)
                break
            end
            task.wait(2)
        end
    end)

    local function IsInSafezoneGeometry(p)
        local char = p.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local pos = hrp.Position
        for i = 1, #SafezoneZones do
            local z = SafezoneZones[i]
            if (z.zone.Position - pos).Magnitude <= z.radius then
                return true
            end
        end
        return false
    end

    local function GetPVPState(p, char)
        if not char then return false end
        if IsInSafezoneGeometry(p) then
            return false
        end
        local distFromIslands = p:GetAttribute("DistanceFromIslands")
        if distFromIslands ~= nil and distFromIslands < 0 then
            return false
        end
        local pvpDisabled = p:GetAttribute("PvpDisabled")
        if pvpDisabled ~= nil then
            return not pvpDisabled
        end
        if char:FindFirstChildOfClass("ForceField") then return false end
        local pvpAttr = char:GetAttribute("PvP")
        if pvpAttr ~= nil then return pvpAttr end
        local pvpVal = char:FindFirstChild("PvP")
        if pvpVal and pvpVal:IsA("BoolValue") then return pvpVal.Value end
        return true
    end

    local LevelCache = {}
    Players.PlayerRemoving:Connect(function(p) LevelCache[p] = nil end)

    local function GetPlayerLevel(p)
        local c = LevelCache[p]
        if c and c.data.Parent == p and c.level.Parent == c.data then
            return tonumber(c.level.Value) or 0
        end
        local data = p:FindFirstChild("Data")
        local level = data and data:FindFirstChild("Level")
        if data and level then
            LevelCache[p] = {data = data, level = level}
            return tonumber(level.Value) or 0
        end
        LevelCache[p] = nil
        return 0
    end

    local function ShouldSkipPlayerTarget(p)
        if p == player then return true end

        if Hub.ListMode == "Blacklist" and Hub.IsListed(p.Name) then
            return true
        elseif Hub.ListMode == "Whitelist" and not Hub.IsListed(p.Name) then
            return true
        end

        if Hub.TeamCheckEnabled and p.Team and player.Team and p.Team == player.Team then return true end
        if p:GetAttribute("IslandRaiding") == true then return true end
        if p:GetAttribute("PvpDisabled") == true then return true end
        if Hub.MinTargetLevel > 0 and GetPlayerLevel(p) < Hub.MinTargetLevel then return true end
        return false
    end

    Hub.GetPVPState = GetPVPState
    Hub.IsInCombat = function(p, char) return GetPVPState(p, char) == true end
    Hub.ShouldSkipPlayerTarget = ShouldSkipPlayerTarget
end

-- ============================================================
--  PASSIVE BUFFS
-- ============================================================
do
    local function SetupCharacter(char)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then
            hrp.ChildAdded:Connect(function(v)
                if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyPosition") or v:IsA("BodyAngularVelocity") then
                    local name = v.Name:lower()
                    if (name:match("stun") or name:match("freeze") or name:match("ragdoll") or name:match("knockback") or name:match("root"))
                    and v.Name ~= "FlyVelocity" and v.Name ~= "FlyGyro" and v.Name ~= "FarmVelocity" then
                        pcall(function() v:Destroy() end)
                    end
                end
            end)
        end
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Stunned, false) end)
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
        end
    end

    if player.Character then SetupCharacter(player.Character) end
    player.CharacterAdded:Connect(SetupCharacter)

    RunService.Heartbeat:Connect(function()
        local char = player.Character
        if not char then return end

        if Config.AntiStun then
            char:SetAttribute("UnbreakableAll", true)
            char:SetAttribute("Stun", 0)
            char:SetAttribute("Stunned", false)
            char:SetAttribute("CantMove", false)
            char:SetAttribute("Busy", false)

            local hum = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                hum.PlatformStand = false
                hum.Sit = false
                if hrp.Anchored then hrp.Anchored = false end
                local seatWeld = hrp:FindFirstChild("SeatWeld")
                if seatWeld then pcall(function() seatWeld:Destroy() end) end
                for _, child in ipairs(hrp:GetChildren()) do
                    if (child:IsA("BodyVelocity") or child:IsA("BodyGyro") or child:IsA("BodyPosition"))
                    and child.Name ~= "FlyVelocity" and child.Name ~= "FlyGyro" and child.Name ~= "FarmVelocity" then
                        pcall(function() child:Destroy() end)
                    end
                end
            end
        end

        if Config.IceWater then
            char:SetAttribute("WaterWalking", true)
        end

        local hum2 = char:FindFirstChild("Humanoid")
        if hum2 and not Config.Fly then
            pcall(function() hum2:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false) end)
            if hum2.PlatformStand then
                hum2.PlatformStand = false
            end
        end
    end)

    RunService.Stepped:Connect(function()
        if not Config.NoClip then return end
        local char = player.Character
        if not char then return end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end)
end

-- ============================================================
--  VALIDATOR WARMUP
-- ============================================================
if Hub.Validator then
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            pcall(function()
                Hub.Validator:FireServer(math.floor(os.clock() * 1000))
            end)
        end
    end)
end

-- ============================================================
--  FLY (mobile: joystick + hold ▲▼ buttons | PC: WASD/Space/Ctrl)
-- ============================================================
do
    local FlyConnection = nil
    local bv, bg = nil, nil
    local flyVertical = 0
    local FlyVertGui = nil

    local function CreateFlyButtons()
        if FlyVertGui then return end
        pcall(function()
            FlyVertGui = Instance.new("ScreenGui")
            FlyVertGui.Name = "AlienFlyVert"
            FlyVertGui.ResetOnSpawn = false
            FlyVertGui.DisplayOrder = 999
            local okRoot = pcall(function()
                FlyVertGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
            end)
            if not FlyVertGui.Parent then
                FlyVertGui.Parent = player:WaitForChild("PlayerGui")
            end

            local holder = Instance.new("Frame")
            holder.Name = "Holder"
            holder.Size = UDim2.new(0, 128, 0, 58)
            holder.Position = UDim2.new(1, -148, 1, -250)
            holder.BackgroundTransparency = 1
            holder.Active = true
            holder.Parent = FlyVertGui

            local function makeBtn(xOffset, label)
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 58, 0, 58)
                b.Position = UDim2.new(0, xOffset, 0, 0)
                b.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
                b.BackgroundTransparency = 0.25
                b.Text = label
                b.TextColor3 = Color3.fromRGB(0, 255, 255)
                b.TextSize = 22
                b.Font = Enum.Font.GothamBold
                b.AutoButtonColor = false
                b.BorderSizePixel = 0
                b.Parent = holder
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 12)
                c.Parent = b
                local s = Instance.new("UIStroke")
                s.Color = Color3.fromRGB(0, 200, 255)
                s.Thickness = 1.5
                s.Transparency = 0.3
                s.Parent = b
                return b
            end

            local upBtn = makeBtn(0, "▲")
            local downBtn = makeBtn(70, "▼")

            local function bindHold(btn, dir)
                btn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        flyVertical = dir
                    end
                end)
                btn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if flyVertical == dir then flyVertical = 0 end
                    end
                end)
            end
            bindHold(upBtn, 1)
            bindHold(downBtn, -1)

            local dragging, dragStart, startPos
            holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragStart = input.Position
                    startPos = holder.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseMovement) then
                    local delta = input.Position - dragStart
                    holder.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end)
        end)
    end

    local function SetFlyButtons(vis)
        if not UserInputService.TouchEnabled then return end
        if vis then
            CreateFlyButtons()
            if FlyVertGui then FlyVertGui.Enabled = true end
        else
            flyVertical = 0
            if FlyVertGui then FlyVertGui.Enabled = false end
        end
    end

    local function StopFly()
        if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
        local char = player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local oldBv = hrp:FindFirstChild("FlyVelocity")
                local oldBg = hrp:FindFirstChild("FlyGyro")
                if oldBv then oldBv:Destroy() end
                if oldBg then oldBg:Destroy() end
            end
        end
        bv, bg = nil, nil
        SetFlyButtons(false)
    end

    local function StartFly()
        StopFly()
        SetFlyButtons(true)
        FlyConnection = RunService.RenderStepped:Connect(function(dt)
            if not Config.Fly then StopFly() return end
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not hrp or not hum then return end

            if not bv or not bv.Parent then
                bv = Instance.new("BodyVelocity")
                bv.Name = "FlyVelocity"
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.Parent = hrp

                bg = Instance.new("BodyGyro")
                bg.Name = "FlyGyro"
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.P = 9e4
                bg.CFrame = hrp.CFrame
                bg.Parent = hrp

                hum.PlatformStand = true
            end

            local cam = workspace.CurrentCamera
            local move = Vector3.zero

            local stickDir = hum.MoveDirection
            if stickDir.Magnitude > 0 then
                local camLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
                local camRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
                if camLook.Magnitude > 0 then camLook = camLook.Unit end
                if camRight.Magnitude > 0 then camRight = camRight.Unit end

                local stickForward = stickDir:Dot(camLook)
                local stickRight = stickDir:Dot(camRight)

                move += camLook * stickForward
                move += camRight * stickRight
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end

            if flyVertical ~= 0 then
                move += Vector3.new(0, flyVertical, 0)
            end

            if move.Magnitude > 0 then
                move = move.Unit
            end

            bv.Velocity = move * Hub.TweenSpeedVal
            bg.CFrame = cam.CFrame
        end)
    end

    Hub.StartFly = StartFly
    Hub.StopFly = StopFly

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Config.Fly then StartFly() end
    end)
end

-- ============================================================
--  AUTO HAKI & V4 (permanent loops)
-- ============================================================
do
    task.spawn(function()
        while true do
            task.wait(0.2)
            if Config.AutoHaki then
                local char = player.Character
                if char and Hub.CommF and not char:FindFirstChild("HasBuso") then
                    pcall(function() Hub.CommF:InvokeServer("Buso") end)
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.4)
            if Config.AutoV4 then
                local char = player.Character
                if char then
                    local raceEnergy = char:GetAttribute("RaceEnergy")
                    local energyOK = (raceEnergy == nil) or (raceEnergy >= 100)
                    if energyOK then
                        local tool = char:FindFirstChild("Awakening") or player.Backpack:FindFirstChild("Awakening")
                        if tool then
                            local remote = tool:FindFirstChildWhichIsA("RemoteFunction")
                            if remote then
                                pcall(function() remote:InvokeServer(true) end)
                            end
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.2)
            if Config.AutoV4 then
                local char = player.Character
                if char and not char:GetAttribute("DeathHandled") then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum and (hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead) then
                        char:SetAttribute("DeathHandled", true)
                        hum:ChangeState(Enum.HumanoidStateType.Dead)
                        char:BreakJoints()
                    end
                end
            end
        end
    end)
end

-- ============================================================
--  FLAGGED M1 (cached seed, unified filters)
-- ============================================================
do
    local u4_flagged = nil
    local u5_flagged = nil
    local CachedSeed = 0

    local function getServerTime()
        if workspace.GetServerTimeNow then return workspace:GetServerTimeNow() else return tick() end
    end

    do
        local _v2 = {
            ReplicatedStorage:FindFirstChild("Util"), ReplicatedStorage:FindFirstChild("Common"),
            ReplicatedStorage:FindFirstChild("Remotes"), ReplicatedStorage:FindFirstChild("Assets"),
            ReplicatedStorage:FindFirstChild("FX"),
        }
        for _, folder in ipairs(_v2) do
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
                        u5_flagged = child:GetAttribute("Id")
                        u4_flagged = child
                    end
                end
            end
        end
    end

    task.spawn(function()
        local seedRemote = Hub.Net and Hub.Net:FindFirstChild("seed")
        if seedRemote then
            while true do
                pcall(function()
                    local r = seedRemote:InvokeServer()
                    if type(r) == "number" then CachedSeed = r end
                end)
                task.wait(1)
            end
        end
    end)

    local function DoFlaggedFastAttack()
        if not Hub.RegisterHit then return end
        local _Character = player.Character
        if not _Character then return end
        local _HRP = _Character:FindFirstChild("HumanoidRootPart")
        if not _HRP then return end
        local _Tool = _Character:FindFirstChildOfClass("Tool")
        if not _Tool then return end

        local wt = _Tool:GetAttribute("WeaponType")
        if wt ~= "Melee" and wt ~= "Sword" then return end

        local _targets = {}
        local enemies = workspace:FindFirstChild("Enemies")
        local chars = workspace:FindFirstChild("Characters")

        local function checkFolder(folder, isPlayers)
            if not folder then return end
            for _, v in ipairs(folder:GetChildren()) do
                if v ~= _Character then
                    local skip = false
                    if isPlayers then
                        local vp = Players:GetPlayerFromCharacter(v)
                        if vp and Hub.ShouldSkipPlayerTarget(vp) then skip = true end
                    end
                    if not skip then
                        local vHRP = v:FindFirstChild("HumanoidRootPart")
                        local vHum = v:FindFirstChild("Humanoid")
                        if vHRP and vHum and vHum.Health > 0 and (vHRP.Position - _HRP.Position).Magnitude <= Hub.FlaggedRange then
                            _targets[#_targets + 1] = {v, vHRP}
                        end
                    end
                end
            end
        end

        checkFolder(enemies, false)
        checkFolder(chars, true)

        if #_targets > 0 then
            pcall(function()
                if Hub.NetModule then Hub.NetModule:RemoteEvent("RegisterHit", true) end
                if Hub.RegisterAttack then Hub.RegisterAttack:FireServer() end
                local _Head = _targets[1][1]:FindFirstChild("Head")
                if _Head then
                    local threadId = tostring(player.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
                    Hub.RegisterHit:FireServer(_Head, _targets, {}, threadId)

                    if u4_flagged then
                        local seedVal = CachedSeed
                        local fireRemote = cloneref(u4_flagged) or ReplicatedStorage:FindFirstChild(u4_flagged.Name) or u4_flagged

                        local gsubResult = string.gsub("RE/RegisterHit", ".", function(c)
                            local byteVal = string.byte(c)
                            local timeVal = math.floor(getServerTime() / 10 % 10)
                            return string.char(bit32.bxor(byteVal, timeVal + 1))
                        end)

                        fireRemote:FireServer(gsubResult, bit32.bxor(u5_flagged + 909090, seedVal * 2), _Head, _targets)
                    end
                end
            end)
        end
    end

    RunService.Heartbeat:Connect(function()
        if Config.FlaggedM1 then
            pcall(DoFlaggedFastAttack)
        end
    end)
end

-- ============================================================
--  FRUIT AURA
-- ============================================================
do
    local function getFruit()
        local bp = player.Backpack
        if bp then
            for _, v in ipairs(bp:GetChildren()) do
                if v:GetAttribute("WeaponType") == "Demon Fruit" then return v end
            end
        end
        if player.Character then
            for _, v in ipairs(player.Character:GetChildren()) do
                if v:GetAttribute("WeaponType") == "Demon Fruit" then return v end
            end
        end
        return nil
    end

    local function getNearestTarget(myHRP)
        local nearest = nil
        local nearestDist = Hub.FruitM1Range

        for _, p in ipairs(Players:GetPlayers()) do
            if not Hub.ShouldSkipPlayerTarget(p) and p.Character then
                local hum = p.Character:FindFirstChild("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist < nearestDist then nearestDist = dist; nearest = hrp end
                end
            end
        end

        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, npc in ipairs(enemies:GetChildren()) do
                local hum = npc:FindFirstChild("Humanoid")
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist < nearestDist then nearestDist = dist; nearest = hrp end
                end
            end
        end
        return nearest
    end

    RunService.Heartbeat:Connect(function()
        if Config.FruitM1 then
            pcall(function()
                local fruit = getFruit()
                if fruit then
                    local rem = fruit:FindFirstChild("LeftClickRemote")
                    if rem then
                        local myChar = player.Character
                        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if myHRP then
                            local targetHRP = getNearestTarget(myHRP)
                            if targetHRP then
                                local direction = (targetHRP.Position - myHRP.Position).Unit
                                rem:FireServer(direction, 1, true)
                            else
                                rem:FireServer(Vector3.new(0.12, -0.5, -0.1), 1, true)
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- ============================================================
--  DRAGON GUN M1 (v3.7 proven core)
-- ============================================================
do
    local ShootGunEvent, Validator2, ShootFunction = nil, nil, nil
    local V_Idx = { v26 = 12, v22 = 13, v25 = 14, v21 = 15, v23 = 16, v24 = 17, v27 = 18 }

    local getupval = debug.getupvalue or getupvalue
    local setupval = debug.setupvalue or setupvalue
    local getupvals = debug.getupvalues or getupvalues

    task.spawn(function()
        pcall(function()
            local mods = ReplicatedStorage:WaitForChild("Modules", 10)
            if mods then
                local dn = mods:WaitForChild("Net", 10)
                if dn then
                    ShootGunEvent = dn:WaitForChild("RE/ShootGunEvent", 10)
                end
            end
            local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
            if remotes then
                Validator2 = remotes:WaitForChild("Validator2", 10)
            end
        end)
    end)

    local function InitDragonGun()
        local ok, result = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CombatController"))
        end)
        if ok and type(result) == "table" and result.Attack then
            ShootFunction = getupval(result.Attack, 9)
        end
    end

    local function GetNextValidator()
        if not ShootFunction then InitDragonGun() end
        if not ShootFunction then return 0, 0 end
        local okUV, upvals = pcall(getupvals, ShootFunction)
        if not okUV or not upvals then return 0, 0 end

        if upvals[V_Idx.v21] ~= 727595 then
            for i, v in pairs(upvals) do
                if v == 727595 then
                    local offset = i - 15
                    V_Idx.v21 = i; V_Idx.v22 = 13 + offset; V_Idx.v23 = 16 + offset
                    V_Idx.v24 = 17 + offset; V_Idx.v26 = 12 + offset; V_Idx.v25 = 14 + offset
                    V_Idx.v27 = 18 + offset
                    break
                end
            end
        end

        local okR, v1, v2, v3, v4, v5, v6, v7 = pcall(function()
            return getupval(ShootFunction, V_Idx.v21),
                   getupval(ShootFunction, V_Idx.v22),
                   getupval(ShootFunction, V_Idx.v23),
                   getupval(ShootFunction, V_Idx.v24),
                   getupval(ShootFunction, V_Idx.v25),
                   getupval(ShootFunction, V_Idx.v26),
                   getupval(ShootFunction, V_Idx.v27)
        end)
        if not okR then return 0, 0 end
        if not (v1 and v2 and v3 and v4 and v5 and v6 and v7) then return 0, 0 end

        local v8 = v6 * v2
        local v9 = (v5 * v2 + v6 * v1) % v3
        v9 = (v9 * v3 + v8) % v4
        v5 = math.floor(v9 / v3)
        v6 = v9 - v5 * v3
        v7 = v7 + 1

        pcall(function()
            setupval(ShootFunction, V_Idx.v25, v5)
            setupval(ShootFunction, V_Idx.v26, v6)
            setupval(ShootFunction, V_Idx.v27, v7)
        end)

        return math.floor(v9 / v4 * 16777215), v7
    end

    local function GetClosestDragonTarget(myHRP)
        local closest, dist = nil, Hub.DragonGunRange
        local myPos = myHRP.Position

        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, enemy in pairs(enemies:GetChildren()) do
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                local r = enemy:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and r then
                    local d = (r.Position - myPos).Magnitude
                    if d < dist then dist = d; closest = r end
                end
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if not Hub.ShouldSkipPlayerTarget(p) and p.Character then
                local hum = p.Character:FindFirstChild("Humanoid")
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and r then
                    local d = (r.Position - myPos).Magnitude
                    if d < dist then dist = d; closest = r end
                end
            end
        end
        return closest
    end

    task.spawn(function()
        while true do
            task.wait(0.085)
            if Hub.DragonGunEnabled then
                pcall(function()
                    local char = player.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if not tool or tool.ToolTip ~= "Gun" then return end
                    local myHRP = char:FindFirstChild("HumanoidRootPart")
                    if not myHRP then return end

                    local target = GetClosestDragonTarget(myHRP)
                    if not target then return end

                    local code, count = GetNextValidator()
                    if code ~= 0 and Validator2 then
                        Validator2:FireServer(code, count)
                    end

                    tool:SetAttribute("LocalOverheat", 0)
                    tool:SetAttribute("LocalTotalShots", (tool:GetAttribute("LocalTotalShots") or 0) + 1)

                    if ShootGunEvent then
                        ShootGunEvent:FireServer(target.Position, { target })
                    end
                end)
            end
        end
    end)
end

-- ============================================================
--  MOB BRING v2 (cycle system, hold & restore)
-- ============================================================
do
    local Bring = {
        Enabled = false,
        Generation = 0,
        Restores = {},
        Cycles = {},
        Returned = {},
        LastPrune = 0
    }
    local BringThread = nil

    local function MobRemember(part, prop)
        if not part then return end
        local r = Bring.Restores[part]
        if not r then
            r = {}
            Bring.Restores[part] = r
        end
        if r[prop] == nil then
            local ok, v = pcall(function() return part[prop] end)
            if ok then r[prop] = v end
        end
    end

    local function MobRestoreInstance(part)
        if not part then return end
        local r = Bring.Restores[part]
        if not r then return end
        if part.Parent then
            for k, v in pairs(r) do
                pcall(function() part[k] = v end)
            end
        end
        Bring.Restores[part] = nil
    end

    local function MobRestoreAll()
        for part, cycle in pairs(Bring.Cycles) do
            local hum = cycle.Mob and cycle.Mob:FindFirstChildOfClass("Humanoid")
            if part and part.Parent and hum and hum.Health > 0 then
                pcall(function() part.CFrame = cycle.Origin end)
            end
        end
        for part, restore in pairs(Bring.Restores) do
            if part and part.Parent then
                for k, v in pairs(restore) do
                    pcall(function() part[k] = v end)
                end
            end
        end
        table.clear(Bring.Restores)
        table.clear(Bring.Cycles)
        table.clear(Bring.Returned)
    end

    local function MobPrune(now)
        if now - Bring.LastPrune < 1 then return end
        Bring.LastPrune = now
        for part, cycle in pairs(Bring.Cycles) do
            if not part or not part.Parent or not cycle.Mob or not cycle.Mob.Parent then
                Bring.Cycles[part] = nil
            end
        end
        for part in pairs(Bring.Returned) do
            if not part or not part.Parent then Bring.Returned[part] = nil end
        end
        for part in pairs(Bring.Restores) do
            if not part or not part.Parent then Bring.Restores[part] = nil end
        end
    end

    local function MobBeginCycle(part, mob, hum, now)
        Bring.Cycles[part] = { Mob = mob, Origin = part.CFrame, StartedAt = now }
        MobRemember(part, "CanCollide")
        MobRemember(part, "AssemblyLinearVelocity")
        MobRemember(part, "AssemblyAngularVelocity")
        MobRemember(hum, "WalkSpeed")
        MobRemember(hum, "JumpPower")
    end

    local function MobReturnCycle(part, cycle)
        local hum = cycle.Mob and cycle.Mob:FindFirstChildOfClass("Humanoid")
        if part and part.Parent and hum and hum.Health > 0 then
            pcall(function() part.CFrame = cycle.Origin end)
        end
        MobRestoreInstance(part)
        if hum then MobRestoreInstance(hum) end
        Bring.Cycles[part] = nil
        Bring.Returned[part] = true
    end

    local function MobApply()
        local now = os.clock()
        MobPrune(now)

        for part, cycle in pairs(Bring.Cycles) do
            if now - cycle.StartedAt >= Hub.MobBringHold then
                MobReturnCycle(part, cycle)
            end
        end

        local character = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local enemies = workspace:FindFirstChild("Enemies")
        if not character or not enemies then return end

        local grabCFrame = character.CFrame * CFrame.new(0, -15, 0)

        for _, Enemy in ipairs(enemies:GetChildren()) do
            local hum = Enemy:FindFirstChildOfClass("Humanoid")
            local hrp = Enemy:FindFirstChild("HumanoidRootPart") or Enemy.PrimaryPart

            if not (hum and hrp and hum.Health > 0 and (hrp.Position - character.Position).Magnitude <= Hub.MobBringRange) then
                if hrp then Bring.Returned[hrp] = nil end
            elseif not Bring.Returned[hrp] then
                local owned
                if isnetworkowner then
                    owned = isnetworkowner(hrp)
                else
                    owned = hrp.ReceiveAge == 0 and not hrp.Anchored
                end

                if owned then
                    if not Bring.Cycles[hrp] then
                        MobBeginCycle(hrp, Enemy, hum, now)
                    end
                    hrp.CanCollide = false
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    hrp.CFrame = grabCFrame
                end
            end
        end
    end

    function Hub.StopMobBring()
        Bring.Enabled = false
        Bring.Generation = Bring.Generation + 1
        if BringThread then task.cancel(BringThread); BringThread = nil end
        MobRestoreAll()
    end

    function Hub.StartMobBring()
        Hub.StopMobBring()
        Bring.Enabled = true
        Bring.Generation = Bring.Generation + 1
        local gen = Bring.Generation
        pcall(function()
            sethiddenproperty(player, "SimulationRadius", math.huge)
        end)
        BringThread = task.spawn(function()
            while Bring.Enabled and Bring.Generation == gen do
                MobApply()
                task.wait()
            end
        end)
    end

    function Hub.IsMobBringEnabled()
        return Bring.Enabled
    end
end

-- ============================================================
--  ANTI LAVA + GHOST SHIP + WALK ON WATER
-- ============================================================
do
    RunService.Stepped:Connect(function(_, dt)
        if not Hub.AntiLavaActive then return end
        pcall(function()
            local char = player.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart")
                and part.Name ~= "HumanoidRootPart"
                and part.Name ~= "Torso" and part.Name ~= "UpperTorso"
                and part.Name ~= "LowerTorso" and part.Name ~= "Head" then
                    part.CanTouch = false
                end
            end
        end)
    end)

    task.spawn(function()
        local cleaned = false
        while true do
            if Hub.AntiLavaActive and not cleaned then
                for _, d in ipairs(workspace:GetDescendants()) do
                    if d.Name == "Lava" then pcall(function() d:Destroy() end) end
                end
                cleaned = true
                workspace.DescendantAdded:Connect(function(d)
                    if Hub.AntiLavaActive and d.Name == "Lava" then
                        pcall(function() d:Destroy() end)
                    end
                end)
            end
            task.wait(1)
        end
    end)
end

do
    task.spawn(function()
        while true do
            if Hub.DeleteShipActive then
                pcall(function()
                    local shipNames = {"CursedShip", "Cursed Ship", "Ship"}
                    local exteriorNames = {"Wall", "Floor", "Ceiling", "Base", "Hull", "Window", "DoorFrame"}
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        for _, sName in ipairs(shipNames) do
                            if obj.Name:find(sName) and (obj:IsA("Model") or obj:IsA("Folder")) then
                                for _, child in ipairs(obj:GetDescendants()) do
                                    if child:IsA("BasePart") and child.Parent and not child.Parent:FindFirstChild("Humanoid") then
                                        local isExterior = false
                                        for _, ext in ipairs(exteriorNames) do
                                            if child.Name:find(ext) then isExterior = true; break end
                                        end
                                        if not isExterior then
                                            child:Destroy()
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(3)
            else
                task.wait(1)
            end
        end
    end)
end

do
    local WaterPart = nil

    local function GetWaterPart()
        if not WaterPart or not WaterPart.Parent then
            WaterPart = Instance.new("Part")
            WaterPart.Size = Vector3.new(200, 1, 200)
            WaterPart.Transparency = 1
            WaterPart.Anchored = true
            WaterPart.CanCollide = false
            WaterPart.Name = "AlienWaterPlatform"
            WaterPart.Parent = workspace
        end
        return WaterPart
    end

    RunService.Heartbeat:Connect(function()
        if not Hub.WalkOnWaterEnabled then
            if WaterPart and WaterPart.Parent then WaterPart.CanCollide = false end
            return
        end
        pcall(function()
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local wp = GetWaterPart()
            if hrp and hrp.Position.Y >= 9.5 then
                wp.Position = Vector3.new(hrp.Position.X, 9.2, hrp.Position.Z)
                wp.CanCollide = true
            else
                wp.CanCollide = false
            end
        end)
    end)
end

-- ============================================================
--  HITBOX EXPANDER
-- ============================================================
do
    local OriginalSizes = {}

    local function ApplyHitboxTo(hrp)
        if not hrp or not hrp.Parent then return end
        if not OriginalSizes[hrp] then
            OriginalSizes[hrp] = {size = hrp.Size, transparency = hrp.Transparency}
        end
        hrp.Size = Vector3.new(Hub.HitboxSize, Hub.HitboxSize, Hub.HitboxSize)
        hrp.Transparency = Hub.HitboxTransparency
        hrp.CanCollide = false
    end

    function Hub.RestoreHitboxes()
        for hrp, data in pairs(OriginalSizes) do
            if hrp and hrp.Parent then
                hrp.Size = data.size
                hrp.Transparency = data.transparency
            end
        end
        OriginalSizes = {}
    end

    task.spawn(function()
        while true do
            task.wait(1)
            if Hub.HitboxEnabled then
                pcall(function()
                    local enemies = workspace:FindFirstChild("Enemies")
                    if enemies then
                        for _, npc in ipairs(enemies:GetChildren()) do
                            local hrp = npc:FindFirstChild("HumanoidRootPart")
                            if hrp then ApplyHitboxTo(hrp) end
                        end
                    end
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player and p.Character then
                            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then ApplyHitboxTo(hrp) end
                        end
                    end
                end)
            end
        end
    end)
end

-- ============================================================
--  PANIC FLEE
-- ============================================================
do
    local Armed = true
    local LastRun = 0
    local Count = 0

    task.spawn(function()
        while true do
            task.wait(0.2)
            if Hub.PanicFleeEnabled then
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    if not Armed and hum.Health >= Hub.PanicFleeResetHealth then
                        Armed = true
                    end

                    if Armed and hum.Health <= Hub.PanicFleeThreshold
                    and (os.clock() - LastRun) >= 10 then
                        Count = Count + 1
                        Armed = false
                        LastRun = os.clock()

                        local nearestHRP, nearestDist = nil, math.huge
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= player and p.Character then
                                local th = p.Character:FindFirstChild("HumanoidRootPart")
                                if th and p.Character:FindFirstChildOfClass("Humanoid")
                                and p.Character.Humanoid.Health > 0 then
                                    local d = (th.Position - hrp.Position).Magnitude
                                    if d < nearestDist then nearestDist = d; nearestHRP = th end
                                end
                            end
                        end

                        local fleeDir = Vector3.new(0, 1, 0)
                        if nearestHRP then
                            local away = hrp.Position - nearestHRP.Position
                            away = Vector3.new(away.X, 0, away.Z)
                            if away.Magnitude > 0 then away = away.Unit end
                            fleeDir = (away * 0.7 + Vector3.new(0, 1, 0)).Unit
                        end

                        local dest = hrp.Position + fleeDir * 2500
                        Notify("Panic Flee", "Low health — escaping! (" .. Count .. "/5)", 2)

                        if Hub.ActiveTween then Hub.ActiveTween:Cancel(); Hub.ActiveTween = nil end
                        TweenService:Create(
                            hrp,
                            TweenInfo.new(math.max(0.5, 2500 / Hub.TweenSpeedVal), Enum.EasingStyle.Linear),
                            {CFrame = CFrame.new(dest)}
                        ):Play()

                        if Count >= 5 then
                            Hub.PanicFleeEnabled = false
                            Notify("Panic Flee", "Attempts exhausted — disabled", 3)
                        end
                    end
                end
            else
                Count = 0
                Armed = true
            end
        end
    end)
end

-- ============================================================
--  MOVEMENT | SMOOTH PURSUIT
-- ============================================================
do
    local TweenConnection = nil
    local SnapArmed = true

    local function StopTween()
        if TweenConnection then TweenConnection:Disconnect(); TweenConnection = nil end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end

    local function GetNearestPlayerHRP(myHRP)
        local nearest = nil
        local nearestDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if not Hub.ShouldSkipPlayerTarget(p) and not IsAlly(p) and p.Character then
                if Hub.IsInCombat(p, p.Character) then
                    local hum = p.Character:FindFirstChild("Humanoid")
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        local dist = (hrp.Position - myHRP.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = hrp
                        end
                    end
                end
            end
        end
        return nearest
    end

    local function StartTween()
        StopTween()
        SnapArmed = true
        TweenConnection = RunService.Heartbeat:Connect(function(dt)
            if not (Config.TweenToPlayer or Config.TweenToNearest) then StopTween() return end
            dt = math.min(dt, 0.1)

            local myChar = player.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end

            local tHRP = nil
            if Config.TweenToPlayer then
                local target = Hub.SelectedPlayerName and Players:FindFirstChild(Hub.SelectedPlayerName)
                if target and target.Character then
                    tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                end
            elseif Config.TweenToNearest then
                tHRP = GetNearestPlayerHRP(myHRP)
            end

            if not tHRP then
                myHRP.AssemblyLinearVelocity = Vector3.zero
                return
            end

            local rawDist = (myHRP.Position - tHRP.Position).Magnitude
            if rawDist > Hub.TweenMaxRange then return end

            local targetPos = (tHRP.CFrame * CFrame.new(Hub.TweenXOffset, Hub.TweenYOffset, Hub.TweenZOffset)).Position

            local speed = Hub.TweenSpeedVal
            local lookahead = math.min(0.3, rawDist / math.max(speed, 1))
            local aimPos = targetPos + (tHRP.AssemblyLinearVelocity * lookahead)

            local toTarget = aimPos - myHRP.Position
            local dist = toTarget.Magnitude

            if rawDist > Hub.InstaSnapDistance * 1.5 then
                SnapArmed = true
            end
            if SnapArmed and dist <= Hub.InstaSnapDistance then
                myHRP.CFrame = CFrame.new(aimPos)
                myHRP.AssemblyLinearVelocity = Vector3.zero
                SnapArmed = false
                return
            end

            if dist < 30 then
                speed = math.max(speed * (dist / 30), 10)
            end

            local step = speed * dt
            if step >= dist then
                myHRP.CFrame = CFrame.new(aimPos)
                myHRP.AssemblyLinearVelocity = Vector3.zero
            else
                myHRP.AssemblyLinearVelocity = (toTarget / dist) * speed
            end
        end)
    end

    Hub.StartTween = StartTween
    Hub.StopTween = StopTween
end

-- ============================================================
--  ORBIT + INF JUMP + DASH + ANIM REMOVAL
-- ============================================================
do
    local OrbitEnabled = false
    local OrbitAngle = 0
    local OrbitConn = nil

    function Hub.StopOrbit()
        OrbitEnabled = false
        if OrbitConn then OrbitConn:Disconnect(); OrbitConn = nil end
    end

    function Hub.StartOrbit()
        Hub.StopOrbit()
        OrbitEnabled = true
        OrbitConn = RunService.Heartbeat:Connect(function(dt)
            if not OrbitEnabled then Hub.StopOrbit() return end
            local target = Hub.SelectedPlayerObj or (Hub.SelectedPlayerName and Players:FindFirstChild(Hub.SelectedPlayerName))
            local tHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not tHRP or not myHRP then return end

            OrbitAngle = OrbitAngle + Hub.OrbitSpeed * dt
            local offset = Vector3.new(math.cos(OrbitAngle) * Hub.OrbitRadius, 10, math.sin(OrbitAngle) * Hub.OrbitRadius)
            myHRP.CFrame = CFrame.lookAt(tHRP.Position + offset, tHRP.Position)
        end)
    end
end

do
    UserInputService.JumpRequest:Connect(function()
        if Hub.InfJumpEnabled then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X,
                    hum.JumpPower * 1.5,
                    hrp.AssemblyLinearVelocity.Z
                )
            end
        end
    end)
end

do
    task.spawn(function()
        while true do
            task.wait(0.1)
            if Hub.DashLengthEnabled then
                pcall(function()
                    local char = player.Character
                    if char then
                        if char:GetAttribute("DashLength") ~= Hub.DashLengthValue then
                            char:SetAttribute("DashLength", Hub.DashLengthValue)
                        end
                        if char:GetAttribute("DashLengthAir") ~= Hub.DashLengthValue then
                            char:SetAttribute("DashLengthAir", Hub.DashLengthValue)
                        end
                    end
                end)
            end
        end
    end)
end

do
    local ATTACK_KEYWORDS = {"attack","slash","punch","m1","combo","hit","tool","ability","skill","bullet","gun","sword","melee","fruit"}

    local function isAttackAnim(track)
        local n = string.lower(track.Name)
        for _, kw in ipairs(ATTACK_KEYWORDS) do
            if string.find(n, kw) then return true end
        end
        return track.Priority == Enum.AnimationPriority.Action
    end

    task.spawn(function()
        while true do
            task.wait(0.1)
            if Hub.RemoveAnimsEnabled then
                pcall(function()
                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local animator = hum and hum:FindFirstChild("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            if not isAttackAnim(track) then
                                track:Stop(0)
                            end
                        end
                    end
                end)
            end
        end
    end)
end

-- ============================================================
--  ESP (name/dist/level/bounty/pvp)
-- ============================================================
do
    local ESPObjects = {}

    local function ClearESP()
        for _, obj in pairs(ESPObjects) do
            if obj and obj.billboard then pcall(function() obj.billboard:Destroy() end) end
        end
        ESPObjects = {}
    end

    local function CreateESP(target)
        if not target:FindFirstChild("Head") then return end
        local head = target:FindFirstChild("Head")
        if head:FindFirstChild("NeonESP") then return end

        local bountyVal = nil
        local levelVal = nil
        local pl = Players:GetPlayerFromCharacter(target)
        if pl then
            local data = pl:FindFirstChild("Data")
            if data then
                bountyVal = data:FindFirstChild("Bounty")
                levelVal = data:FindFirstChild("Level")
            end
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NeonESP"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 90)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Text = target.Name
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(0, 255, 255)
        lbl.TextStrokeTransparency = 0.4
        lbl.Parent = billboard

        local espStroke = Instance.new("UIStroke")
        espStroke.Color = Color3.new(0,0,0)
        espStroke.Thickness = 2
        espStroke.Transparency = 0.5
        espStroke.Parent = lbl

        table.insert(ESPObjects, {
            billboard = billboard,
            label = lbl,
            hrp = target:FindFirstChild("HumanoidRootPart"),
            target = target,
            name = target.Name,
            bountyVal = bountyVal,
            levelVal = levelVal,
            playerObj = pl
        })
    end

    local function SyncESP()
        if not Config.ESP then return end

        for i = #ESPObjects, 1, -1 do
            local data = ESPObjects[i]
            if not data.target or not data.target.Parent or not data.target:FindFirstChild("Head") or not data.hrp or not data.hrp.Parent then
                if data.billboard then data.billboard:Destroy() end
                table.remove(ESPObjects, i)
            end
        end

        local function checkAndAdd(char)
            if not char or not char:FindFirstChild("Head") then return end
            local hasESP = false
            for _, data in ipairs(ESPObjects) do
                if data.target == char then hasESP = true break end
            end
            if not hasESP then CreateESP(char) end
        end

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then checkAndAdd(p.Character) end
        end
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, npc in pairs(enemies:GetChildren()) do checkAndAdd(npc) end
        end
    end

    task.spawn(function()
        while true do
            task.wait(0.1)
            if Config.ESP then
                local myChar = player.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    for _, data in ipairs(ESPObjects) do
                        if data.billboard and data.billboard.Parent and data.hrp and data.hrp.Parent then
                            local dist = math.floor((myHRP.Position - data.hrp.Position).Magnitude)
                            local lines = data.name .. " [" .. dist .. "m]"

                            if data.levelVal and data.levelVal.Value then
                                lines = lines .. "\nLvl " .. tostring(data.levelVal.Value)
                            end
                            if data.bountyVal and data.bountyVal.Value > 0 then
                                lines = lines .. " | " .. FormatBounty(data.bountyVal.Value)
                            end
                            if data.playerObj then
                                lines = lines .. (Hub.GetPVPState(data.playerObj, data.target) and "\nPvP: ON" or "\nPvP: Off/Safe")
                            end

                            data.label.Text = lines
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            if Config.ESP then SyncESP() end
        end
    end)

    Hub.SyncESP = SyncESP
    Hub.ClearESP = ClearESP
end

-- ============================================================
--  SILENT AIM + PREDICTION
-- ============================================================
local SilentAimModule = {}

do
    local SilentAimPlayersEnabled = false
    local SilentAimNPCsEnabled = false
    local UserWantsplayerAim = false
    local UserWantsNPCAim = false
    local PredictionEnabled = false
    local HighlightEnabled = false
    local AutoKen = false
    local ZSkillorM1 = false
    local autoKenRunning = false

    local currentTool = nil
    local playersaimbot = nil
    local PlayersPosition = nil
    local NPCaimbot = nil
    local NPCPosition = nil
    local currentHighlight = nil
    local currentTargetType = nil
    local Selectedplayer = nil

    local characterConnections = {}
    local Skills = {"X"}
    local Booms = {"TAP"}

    local PredictionAmount = 0.1
    local maxRange = 1000
    local PredictionSampleInterval = 0.03
    local PredictionSamples = 5

    local PredictionBuffers = setmetatable({}, {__mode = "k"})

    local function GetPredictionBuffer(hrp)
        local buf = PredictionBuffers[hrp]
        if not buf then
            buf = { positions = {}, timestamps = {}, head = 0, count = 0, capacity = PredictionSamples }
            PredictionBuffers[hrp] = buf
        end
        return buf
    end

    task.spawn(function()
        while true do
            task.wait(PredictionSampleInterval)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local buf = GetPredictionBuffer(hrp)
                        buf.head = (buf.head % buf.capacity) + 1
                        buf.positions[buf.head] = hrp.Position
                        buf.timestamps[buf.head] = os.clock()
                        buf.count = math.min(buf.count + 1, buf.capacity)
                    end
                end
            end
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, npc in ipairs(enemies:GetChildren()) do
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local buf = GetPredictionBuffer(hrp)
                        buf.head = (buf.head % buf.capacity) + 1
                        buf.positions[buf.head] = hrp.Position
                        buf.timestamps[buf.head] = os.clock()
                        buf.count = math.min(buf.count + 1, buf.capacity)
                    end
                end
            end
        end
    end)

    local function PredictFromBuffer(hrp)
        local buf = PredictionBuffers[hrp]
        if not buf or buf.count < 2 then
            return hrp.Position
        end

        local capacity = buf.capacity
        local head = buf.head

        local function idx(offset)
            return (head + offset - 2) % capacity + 1
        end

        local prev = idx(1)
        local totalDisp = Vector3.zero
        local totalTime = 0

        for i = 2, buf.count do
            local cur = idx(i)
            local dt = buf.timestamps[cur] - buf.timestamps[prev]
            if dt > 0 then
                totalDisp += (buf.positions[cur] - buf.positions[prev])
                totalTime += dt
            end
            prev = cur
        end

        if totalTime > 0 then
            return hrp.Position + (totalDisp / totalTime) * PredictionAmount
        end
        return hrp.Position
    end

    local function getPredictedPosition(hrp)
        if not hrp then return nil end
        if not PredictionEnabled then
            return hrp.Position
        end
        return PredictFromBuffer(hrp)
    end

    local function getHRP(model)
        if not model or not model:FindFirstChild("HumanoidRootPart") then return nil end
        return model.HumanoidRootPart
    end

    local function clearConnections()
        for _, conn in ipairs(characterConnections) do
            pcall(function() conn:Disconnect() end)
        end
        characterConnections = {}
    end

    local function isAllyWithMe(targetplayer)
        local myGui = player:FindFirstChild("PlayerGui")
        if not myGui then return false end

        local scrolling = myGui:FindFirstChild("Main")
            and myGui.Main:FindFirstChild("Allies")
            and myGui.Main.Allies:FindFirstChild("Container")
            and myGui.Main.Allies.Container:FindFirstChild("Allies")
            and myGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")

        if scrolling then
            for _, frame in pairs(scrolling:GetDescendants()) do
                if frame:IsA("ImageButton") and frame.Name == targetplayer.Name then
                    return true
                end
            end
        end

        return false
    end

    local function isEnemy(targetplayer)
        if not targetplayer or targetplayer == player then
            return false
        end

        -- PLAYER LIST SYSTEM — silent aim hook
        if Hub.ListMode == "Blacklist" and Hub.IsListed(targetplayer.Name) then
            return false
        elseif Hub.ListMode == "Whitelist" and not Hub.IsListed(targetplayer.Name) then
            return false
        end

        local myTeam = player.Team
        local targetTeam = targetplayer.Team

        if myTeam and targetTeam then
            if myTeam.Name == "Pirates" and targetTeam.Name == "Marines" then
                return true
            elseif myTeam.Name == "Marines" and targetTeam.Name == "Pirates" then
                return true
            end

            if myTeam.Name == "Pirates" and targetTeam.Name == "Pirates" then
                if isAllyWithMe(targetplayer) then
                    return false
                end
                return true
            end

            if myTeam.Name == "Marines" and targetTeam.Name == "Marines" then
                return false
            end
        end

        return true
    end

    local function getClosestplayer(lpHRP)
        if not lpHRP then return nil end

        local closest = nil
        local closestDist = math.huge
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and isEnemy(pl) and pl.Character and pl.Character.Parent ~= nil then
                local hum = pl.Character:FindFirstChildWhichIsA("Humanoid")
                local hrp = getHRP(pl.Character)
                if hum and hum.Health > 0 and hrp then
                    local dist = (hrp.Position - lpHRP.Position).Magnitude
                    if dist <= maxRange and dist < closestDist then
                        closestDist = dist
                        closest = pl
                    end
                end
            end
        end
        return closest
    end

    local function getClosestNPC(lpHRP)
        if not lpHRP then return nil end

        local enemiesFolder = workspace:FindFirstChild("Enemies")
        if not enemiesFolder then return nil end

        local closest = nil
        local closestDist = math.huge
        for _, npc in ipairs(enemiesFolder:GetChildren()) do
            if npc:IsA("Model") then
                local hum = npc:FindFirstChildWhichIsA("Humanoid")
                local hrp = getHRP(npc)
                if hum and hum.Health > 0 and hrp then
                    local dist = (hrp.Position - lpHRP.Position).Magnitude
                    if dist <= maxRange and dist < closestDist then
                        closestDist = dist
                        closest = npc
                    end
                end
            end
        end
        return closest
    end

    local function applyHighlight(targetModel, targetType)
        if not HighlightEnabled then return end
        if not targetModel then return end
        if currentHighlight and currentHighlight.Adornee == targetModel then return end

        if currentHighlight then
            currentHighlight:Destroy()
            currentHighlight = nil
            currentTargetType = nil
        end

        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(255, 255, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 0)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Adornee = targetModel
        hl.Parent = targetModel
        currentHighlight = hl
        currentTargetType = targetType
    end

    local function clearHighlight()
        if currentHighlight then
            currentHighlight:Destroy()
            currentHighlight = nil
            currentTargetType = nil
        end
    end

    local function isSkillReadyForTool(toolName)
        if not toolName then return false end
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return false end
        local skillsFolder = playerGui:FindFirstChild("Main") and playerGui.Main:FindFirstChild("Skills")
        if not skillsFolder then return false end
        local toolFrame = skillsFolder:FindFirstChild(toolName)
        if not toolFrame then return false end

        for _, skillKey in ipairs({"Z","X","C","V"}) do
            local skill = toolFrame:FindFirstChild(skillKey)
            if skill and skill:FindFirstChild("Cooldown") and skill.Cooldown:IsA("Frame") then
                local cooldownSize = skill.Cooldown.Size.X.Scale
                if cooldownSize == 1.0 then
                    return true
                end
            end
        end
        return false
    end

    local function isNotDoughValidCondition()
        return (currentTool and currentTool.Name == "Dough-Dough")
    end

    local function isNotValidCondition()
        return (currentTool and currentTool.Name == "Lightning-Lightning")
        or (currentTool and currentTool.Name == "Portal-Portal")
    end

    RunService.RenderStepped:Connect(function()
        local lpChar = player.Character
        if not lpChar then return end
        local lpHRP = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpHRP then return end

        if not SilentAimPlayersEnabled and not SilentAimNPCsEnabled then
            return
        end

        local targetModel = nil
        local lookTargetPos = nil

        if SilentAimPlayersEnabled then
            local targetplayer = Selectedplayer or getClosestplayer(lpHRP)
            if targetplayer and targetplayer ~= player and targetplayer.Character then
                playersaimbot = targetplayer.Name
                local hrp = getHRP(targetplayer.Character)
                PlayersPosition = getPredictedPosition(hrp)
                lookTargetPos = PlayersPosition
                targetModel = targetplayer.Character
                applyHighlight(targetModel, "player")
            else
                playersaimbot, PlayersPosition = nil, nil
            end
        elseif currentTargetType == "player" then
            playersaimbot, PlayersPosition = nil, nil
            clearHighlight()
        end

        if SilentAimNPCsEnabled then
            local closestNPC = getClosestNPC(lpHRP)
            if closestNPC then
                NPCaimbot = closestNPC.Name
                local hrp = getHRP(closestNPC)
                NPCPosition = getPredictedPosition(hrp)
                lookTargetPos = NPCPosition
                if not targetModel then
                    targetModel = closestNPC
                    applyHighlight(targetModel, "NPC")
                end
            else
                NPCaimbot, NPCPosition = nil, nil
            end
        elseif currentTargetType == "NPC" then
            NPCaimbot, NPCPosition = nil, nil
            clearHighlight()
        end

        if currentTool and lookTargetPos and isSkillReadyForTool(currentTool.Name) and not isNotDoughValidCondition() then
            local lookVector = (Vector3.new(lookTargetPos.X, lpHRP.Position.Y, lookTargetPos.Z) - lpHRP.Position).Unit
            lpHRP.CFrame = CFrame.new(lpHRP.Position, lpHRP.Position + lookVector)
        end
    end)

    local function hookTool(tool)
        currentTool = tool
        table.insert(characterConnections, tool.AncestryChanged:Connect(function(_, parent)
            if not parent then
                currentTool = nil
            end
        end))
    end

    local function isValidCondition()
        return (currentTool and currentTool.Name == "Buddy Sword")
    end

    spawn(function()
        local ok, hookMeta = pcall(getrawmetatable, game)
        if ok and hookMeta then
            setreadonly(hookMeta, false)
            local OldHook
            OldHook = hookmetamethod(game, "__namecall", function(self, V1, V2, ...)
                local Method = (getnamecallmethod and getnamecallmethod():lower()) or ""

                if tostring(self) == "RemoteEvent" and Method == "fireserver" then
                    if typeof(V1) == "Vector3" then
                        if SilentAimPlayersEnabled and PlayersPosition then
                            return OldHook(self, PlayersPosition, V2, ...)
                        elseif SilentAimNPCsEnabled and NPCPosition then
                            return OldHook(self, NPCPosition, V2, ...)
                        end
                    end
                    if type(V1) == "string" and table.find(Booms, V1) then
                        if ZSkillorM1 then
                            if SilentAimPlayersEnabled and PlayersPosition then
                                return OldHook(self, V1, PlayersPosition, nil, ...)
                            elseif SilentAimNPCsEnabled and NPCPosition then
                                return OldHook(self, V1, NPCPosition, nil, ...)
                            end
                        end
                    end
                elseif Method == "invokeserver" then
                    if isValidCondition() then
                        if type(V1) == "string" and table.find(Skills, V1) then
                            if SilentAimPlayersEnabled and PlayersPosition then
                                return OldHook(self, V1, PlayersPosition, nil, ...)
                            elseif SilentAimNPCsEnabled and NPCPosition then
                                return OldHook(self, V1, NPCPosition, nil, ...)
                            end
                        end
                    end
                end

                return OldHook(self, V1, V2, ...)
            end)
            setreadonly(hookMeta, true)
        end
    end)

    if not isNotValidCondition() then
        if Hub.MouseModule and typeof(Hub.MouseModule) == "Instance" then
            local ok2, okResult = pcall(function()
                return require(Hub.MouseModule)
            end)

            if ok2 and okResult then
                if type(okResult) == "table" then
                    Mouse = okResult
                else
                    Mouse = nil
                end
            else
                Mouse = nil
            end

            if Mouse then
                local Character = player.Character or player.CharacterAdded:Wait()
                local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

                if RootPart then
                    pcall(function()
                        if type(Mouse) == "table" then
                            Mouse.Hit = CFrame.new(RootPart.Position)
                            Mouse.Target = RootPart
                        end
                    end)
                else
                    task.spawn(function()
                        local Character = player.Character or player.CharacterAdded:Wait()
                        local RootPart = Character:WaitForChild("HumanoidRootPart")
                        pcall(function()
                            if type(Mouse) == "table" then
                                Mouse.Hit = CFrame.new(RootPart.Position)
                                Mouse.Target = RootPart
                            end
                        end)
                    end)
                end

                RunService.Heartbeat:Connect(function()
                    if not ZSkillorM1 or (not SilentAimPlayersEnabled and not SilentAimNPCsEnabled) then
                        return
                    end

                    if Mouse and ZSkillorM1 and (SilentAimPlayersEnabled or SilentAimNPCsEnabled) then
                        local targetCFrame = nil

                        if PlayersPosition then
                            targetCFrame = CFrame.new(PlayersPosition)
                        elseif NPCPosition then
                            targetCFrame = CFrame.new(NPCPosition)
                        end

                        if targetCFrame then
                            pcall(function()
                                if type(Mouse) == "table" then
                                    Mouse.Hit = targetCFrame
                                    Mouse.Target = nil
                                end
                            end)

                            if Hub.MouseModule then
                                local ok, MouseData = pcall(require, Hub.MouseModule)
                                if ok and type(MouseData) == "table" then
                                    MouseData.Hit = targetCFrame
                                    MouseData.Target = nil
                                end
                            end
                        end
                    end
                end)
            end
        end
    end

    local Services = setmetatable({}, {
        __index = function(self, serviceName)
            local good, service = pcall(game.GetService, game, serviceName);
            if (good) then
                self[serviceName] = service
                return service;
            end
        end
    });

    local HasTag = function(tagName)
        local char = player.Character
        if (not char) then return false; end
        return Services.CollectionService:HasTag(char, tagName);
    end

    local function startAutoKenLoop()
        if autoKenRunning then return end
        autoKenRunning = true

        task.spawn(function()
            while AutoKen do
                task.wait(0.1)

                if HasTag("Ken") then
                    local playerGui = player:FindFirstChild("PlayerGui")
                    if playerGui then
                        local kenButton = playerGui:FindFirstChild("MobileContextButtons")
                        and playerGui.MobileContextButtons.ContextButtonFrame:FindFirstChild("BoundActionKen")

                        if kenButton and kenButton:GetAttribute("Selected") ~= true then
                            kenButton:SetAttribute("Selected", true)
                        end
                    end

                    local observationManager = getrenv()._G.OM
                    if observationManager and not observationManager.active then
                        observationManager.radius = 0
                        observationManager:setActive(true)
                        if Hub.commE then
                            Hub.commE:FireServer("Ken", true)
                        end
                    end
                end
            end
            autoKenRunning = false
        end)
    end

    local function onCharacterAdded(char)
        clearConnections()

        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                hookTool(child)
            end
        end

        table.insert(characterConnections, char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then hookTool(child) end
        end))

        table.insert(characterConnections, char.ChildRemoved:Connect(function(child)
            if child == currentTool then
                currentTool = nil
            end
        end))
    end

    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then onCharacterAdded(player.Character) end

    function SilentAimModule:SetPlayers(v)
        UserWantsplayerAim = v
        SilentAimPlayersEnabled = v
    end

    function SilentAimModule:GetPlayers()
        return SilentAimPlayersEnabled
    end

    function SilentAimModule:SetNPCs(v)
        UserWantsNPCAim = v
        SilentAimNPCsEnabled = v
    end

    function SilentAimModule:SetZSkill(v)
        ZSkillorM1 = v
    end

    function SilentAimModule:SetPrediction(v)
        PredictionEnabled = v
    end

    function SilentAimModule:SetPredictionAmount(v)
        PredictionAmount = v
    end

    function SilentAimModule:SetHighlight(v)
        HighlightEnabled = v
        if not v then clearHighlight() end
    end

    function SilentAimModule:SetKen(v)
        AutoKen = v
        if v then
            startAutoKenLoop()
        end
    end

    function SilentAimModule:SetRange(v)
        maxRange = v
    end

    function SilentAimModule:SetSelectedPlayer(plr)
        Selectedplayer = plr
    end
end

-- ============================================================
--  MOBILE | FLOATING HUB TOGGLE (tap to hide/show UI)
-- ============================================================
do
    local ToggleGui = Instance.new("ScreenGui")
    ToggleGui.Name = "AlienUIToggle"
    ToggleGui.ResetOnSpawn = false
    ToggleGui.DisplayOrder = 1000
    local okRoot = pcall(function()
        ToggleGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not ToggleGui.Parent then
        ToggleGui.Parent = player:WaitForChild("PlayerGui")
    end

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleBtn"
    btn.Size = UDim2.new(0, 46, 0, 46)
    btn.Position = UDim2.new(0, 12, 0.4, 0)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    btn.BackgroundTransparency = 0.2
    btn.Text = "AH"
    btn.TextColor3 = Color3.fromRGB(0, 255, 255)
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamBlack
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = ToggleGui

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = btn
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(0, 255, 255)
    s.Thickness = 2
    s.Transparency = 0.3
    s.Parent = btn

    local function GetRayfieldGui()
        local roots = {}
        pcall(function() roots[#roots + 1] = gethui and gethui() end)
        pcall(function() roots[#roots + 1] = game:GetService("CoreGui") end)
        pcall(function() roots[#roots + 1] = player:FindFirstChild("PlayerGui") end)
        for _, root in ipairs(roots) do
            if root then
                local g = root:FindFirstChild("Rayfield")
                if g and g:IsA("ScreenGui") then
                    return g
                end
            end
        end
        return nil
    end

    local dragging, dragStart, startPos, moved
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then moved = true end
            btn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not moved then
                local gui = GetRayfieldGui()
                if gui then
                    gui.Enabled = not gui.Enabled
                else
                    Notify("Alien Hub", "UI not found — re-execute the loader", 3)
                end
            end
        end
    end)
end

-- ============================================================
--  MOBILE | QUICK ACTION PANEL (floating keybind-style toggles)
-- ============================================================
do
    if UserInputService.TouchEnabled then
        local PanelGui = Instance.new("ScreenGui")
        PanelGui.Name = "AlienQuickActions"
        PanelGui.ResetOnSpawn = false
        PanelGui.DisplayOrder = 998
        local okRoot = pcall(function()
            PanelGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        end)
        if not PanelGui.Parent then
            PanelGui.Parent = player:WaitForChild("PlayerGui")
        end

        local panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.Size = UDim2.new(0, 96, 0, 260)
        panel.Position = UDim2.new(1, -110, 0.25, 0)
        panel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
        panel.BackgroundTransparency = 0.35
        panel.BorderSizePixel = 0
        panel.Active = true
        panel.Parent = PanelGui

        local pc = Instance.new("UICorner")
        pc.CornerRadius = UDim.new(0, 10)
        pc.Parent = panel
        local ps = Instance.new("UIStroke")
        ps.Color = Color3.fromRGB(0, 200, 255)
        ps.Thickness = 1.5
        ps.Transparency = 0.4
        ps.Parent = panel

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = panel

        local collapsed = false

        local function SetRayfieldFlag(flag, value)
            pcall(function()
                local el = Rayfield.Flags and Rayfield.Flags[flag]
                if el and el.Set then
                    el:Set(value)
                end
            end)
        end

        local function makeToggle(order, label, getter, setter, flag)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 88, 0, 26)
            b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
            b.Text = label .. ": ?"
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.TextSize = 11
            b.Font = Enum.Font.GothamBold
            b.AutoButtonColor = false
            b.BorderSizePixel = 0
            b.LayoutOrder = order
            b.Parent = panel
            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 6)
            bc.Parent = b

            local function refresh()
                local on = getter()
                b.Text = label .. ": " .. (on and "ON" or "OFF")
                b.BackgroundColor3 = on and Color3.fromRGB(20, 110, 60) or Color3.fromRGB(90, 30, 30)
            end

            b.MouseButton1Click:Connect(function()
                setter(not getter())
                refresh()
            end)
            b.TouchTap:Connect(function()
                setter(not getter())
                refresh()
            end)

            refresh()
            return b
        end

        local grip = Instance.new("TextButton")
        grip.Size = UDim2.new(0, 88, 0, 22)
        grip.BackgroundColor3 = Color3.fromRGB(0, 90, 120)
        grip.Text = "⚡ ACTIONS  ▾"
        grip.TextColor3 = Color3.fromRGB(220, 250, 255)
        grip.TextSize = 11
        grip.Font = Enum.Font.GothamBold
        grip.AutoButtonColor = false
        grip.BorderSizePixel = 0
        grip.LayoutOrder = 0
        grip.Parent = panel
        local gc = Instance.new("UICorner")
        gc.CornerRadius = UDim.new(0, 6)
        gc.Parent = grip

        -- ============ COMBAT TOGGLES ============
        makeToggle(1, "Pursue", function()
            return Config.TweenToNearest
        end, function(v)
            Config.TweenToNearest = v
            if v then
                Config.TweenToPlayer = false
                SetRayfieldFlag("TweenPlayer", false)
                Hub.StartTween()
            else
                Hub.StopTween()
            end
            SetRayfieldFlag("TweenNearest", v)
        end, "TweenNearest")

        makeToggle(2, "M1", function()
            return Config.FlaggedM1
        end, function(v)
            Config.FlaggedM1 = v
            SetRayfieldFlag("FlaggedM1", v)
        end, "FlaggedM1")

        makeToggle(3, "Aim", function()
            return SilentAimModule.GetPlayers and SilentAimModule.GetPlayers() or false
        end, function(v)
            SilentAimModule:SetPlayers(v)
        end, "SAPlayers")

        makeToggle(4, "Flee", function()
            return Hub.PanicFleeEnabled
        end, function(v)
            Hub.PanicFleeEnabled = v
            SetRayfieldFlag("PanicFlee", v)
        end, "PanicFlee")

        makeToggle(5, "Aura", function()
            return Config.FruitM1
        end, function(v)
            Config.FruitM1 = v
            SetRayfieldFlag("FruitM1", v)
        end, "FruitM1")

        makeToggle(6, "Gun", function()
            return Hub.DragonGunEnabled
        end, function(v)
            Hub.DragonGunEnabled = v
            SetRayfieldFlag("DragonGunM1", v)
        end, "DragonGunM1")

        makeToggle(7, "Bring", function()
            return Hub.IsMobBringEnabled and Hub.IsMobBringEnabled() or false
        end, function(v)
            if v then Hub.StartMobBring() else Hub.StopMobBring() end
        end, "BringNPC")

        -- collapse behavior
        grip.MouseButton1Click:Connect(function()
            collapsed = not collapsed
            for _, b in ipairs(panel:GetChildren()) do
                if b:IsA("TextButton") and b ~= grip then
                    b.Visible = not collapsed
                end
            end
            grip.Text = collapsed and "⚡" or "⚡ ACTIONS  ▾"
            panel.Size = collapsed and UDim2.new(0, 88, 0, 26) or UDim2.new(0, 96, 0, 260)
        end)
        grip.TouchTap:Connect(function()
            collapsed = not collapsed
            for _, b in ipairs(panel:GetChildren()) do
                if b:IsA("TextButton") and b ~= grip then
                    b.Visible = not collapsed
                end
            end
            grip.Text = collapsed and "⚡" or "⚡ ACTIONS  ▾"
            panel.Size = collapsed and UDim2.new(0, 88, 0, 26) or UDim2.new(0, 96, 0, 260)
        end)

        -- drag panel
        local dragging, dragStart, startPos
        panel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = panel.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStart
                panel.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end
end

-- ============================================================
--  FPS BOOST
-- ============================================================
function Hub.ApplyFPSBoost()
    pcall(function()
        local atmos = Lighting:FindFirstChild("BaseAtmosphere")
        if atmos then atmos:Destroy() end
    end)
    pcall(function() settings().Rendering.QualityLevel = "Level01" end)

    task.spawn(function()
        pcall(function()
            local map = workspace:FindFirstChild("Map")
            if map then
                local now = os.clock()
                for _, d in ipairs(map:GetDescendants()) do
                    if d:IsA("BasePart") then
                        d.Material = Enum.Material.SmoothPlastic
                    elseif d:IsA("Texture") then
                        d:Destroy()
                    end
                    if os.clock() - now > 0.0083 then task.wait(); now = os.clock() end
                end
            end
        end)

        local now = os.clock()
        for _, d in ipairs(game:GetDescendants()) do
            pcall(function()
                if d:IsA("ParticleEmitter") or d:IsA("Trail") then
                    d.Lifetime = NumberRange.new(0)
                elseif d:IsA("Decal") then
                    d.Transparency = 1
                elseif d:IsA("Fire") or d:IsA("SpotLight") or d:IsA("Smoke") then
                    d.Enabled = false
                elseif d:IsA("Explosion") then
                    d.BlastPressure = 1
                    d.BlastRadius = 1
                elseif d:IsA("BasePart") or d:IsA("UnionOperation") then
                    d.Reflectance = 0
                end
            end)
            if os.clock() - now >= 0.0042 then task.wait(); now = os.clock() end
        end
    end)

    pcall(function()
        local CameraShake = require(ReplicatedStorage.Util.CameraShake)
        if CameraShake.SetEnabled then CameraShake:SetEnabled(false) end
        local CameraShaker = require(ReplicatedStorage.Util.CameraShaker)
        if CameraShaker.SetEnabled then CameraShaker:SetEnabled(false) end
        ReplicatedStorage.Remotes.ChangeSetting:FireServer("CameraShake", false)
    end)
    pcall(function()
        player:SetAttribute("DisableAllyEffects", true)
    end)
end

-- ============================================================
--  UI | MAIN TAB
-- ============================================================
MainTab:CreateToggle({
    Name = "Auto Haki",
    CurrentValue = true,
    Flag = "AutoHaki",
    Callback = function(Value)
        Config.AutoHaki = Value
        Notify("Auto Haki", Value and "Enabled" or "Disabled", 2)
    end
})

MainTab:CreateToggle({
    Name = "Auto V4 (RaceEnergy gated)",
    CurrentValue = true,
    Flag = "AutoV4",
    Callback = function(Value)
        Config.AutoV4 = Value
        Notify("Auto V4", Value and "Enabled" or "Disabled", 2)
    end
})

MainTab:CreateToggle({
    Name = "Panic Flee (auto-escape low HP)",
    CurrentValue = false,
    Flag = "PanicFlee",
    Callback = function(Value)
        Hub.PanicFleeEnabled = Value
        Notify("Panic Flee", Value and ("Armed — flees below " .. Hub.PanicFleeThreshold .. " HP") or "Disabled", 2)
    end
})

-- ============================================================
--  UI | COMBAT TAB
-- ============================================================
CombatTab:CreateToggle({
    Name = "Flagged M1s",
    CurrentValue = true,
    Flag = "FlaggedM1",
    Callback = function(Value)
        Config.FlaggedM1 = Value
        Notify("Flagged M1s", Value and "Enabled" or "Disabled", 2)
    end
})

CombatTab:CreateSlider({
    Name = "Flagged Range",
    Range = {100, 10000},
    Increment = 100,
    Suffix = "studs",
    CurrentValue = 10000,
    Flag = "FlaggedRange",
    Callback = function(Value)
        Hub.FlaggedRange = Value
    end
})

CombatTab:CreateToggle({
    Name = "Fruit Aura",
    CurrentValue = true,
    Flag = "FruitM1",
    Callback = function(Value)
        Config.FruitM1 = Value
        Notify("Fruit Aura", Value and "Enabled" or "Disabled", 2)
    end
})

CombatTab:CreateSlider({
    Name = "Fruit Aura Range",
    Range = {10, 500},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 100,
    Flag = "FruitRange",
    Callback = function(Value)
        Hub.FruitM1Range = Value
    end
})

CombatTab:CreateToggle({
    Name = "Dragon Gun M1",
    CurrentValue = false,
    Flag = "DragonGunM1",
    Callback = function(Value)
        Hub.DragonGunEnabled = Value
        Notify("Dragon Gun M1", Value and "Enabled — equip any Gun" or "Disabled", 2)
    end
})

CombatTab:CreateSlider({
    Name = "Dragon Gun Range",
    Range = {100, 10000},
    Increment = 100,
    Suffix = "studs",
    CurrentValue = 2500,
    Flag = "DragonGunRange",
    Callback = function(Value)
        Hub.DragonGunRange = Value
    end
})

CombatTab:CreateToggle({
    Name = "Mob Bring (hold 5s, auto-returns)",
    CurrentValue = false,
    Flag = "BringNPC",
    Callback = function(Value)
        if Value then
            Hub.StartMobBring()
            Notify("Mob Bring", "Enabled — mobs held below you, returned after " .. Hub.MobBringHold .. "s", 3)
        else
            Hub.StopMobBring()
            Notify("Mob Bring", "Disabled — all mobs restored", 2)
        end
    end
})

CombatTab:CreateSlider({
    Name = "Mob Bring Range",
    Range = {50, 1000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 300,
    Flag = "BringRange",
    Callback = function(Value)
        Hub.MobBringRange = Value
    end
})

CombatTab:CreateSlider({
    Name = "Mob Bring Hold Time",
    Range = {1, 15},
    Increment = 1,
    Suffix = "s",
    CurrentValue = 5,
    Flag = "BringHold",
    Callback = function(Value)
        Hub.MobBringHold = Value
    end
})

CombatTab:CreateButton({
    Name = "Collect All Fruits",
    Callback = function()
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local count = 0
        for _, R in pairs(workspace:GetChildren()) do
            if string.find(R.Name, "Fruit") and R:FindFirstChild("Handle") then
                R.Handle.CFrame = char.HumanoidRootPart.CFrame
                count = count + 1
            end
        end
        Notify("Fruits", count > 0 and ("Pulled " .. count .. " fruits") or "No fruits on ground", 2)
    end
})

CombatTab:CreateSection("Hitbox Expander")

CombatTab:CreateToggle({
    Name = "Extend Hitboxes",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        Hub.HitboxEnabled = Value
        if not Value then
            Hub.RestoreHitboxes()
            Notify("Hitbox", "Restored", 2)
        else
            Notify("Hitbox", "Extended to " .. Hub.HitboxSize .. " studs", 2)
        end
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {5, 200},
    Increment = 5,
    Suffix = "studs",
    CurrentValue = 20,
    Flag = "HitboxSize",
    Callback = function(Value)
        Hub.HitboxSize = Value
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Flag = "HitboxTransparency",
    Callback = function(Value)
        Hub.HitboxTransparency = Value
    end
})

CombatTab:CreateSection("Targeting Filters")

CombatTab:CreateToggle({
    Name = "Team Check (skip same-team players)",
    CurrentValue = false,
    Flag = "TeamCheck",
    Callback = function(Value)
        Hub.TeamCheckEnabled = Value
        Notify("Team Check", Value and "ON — attacks/tweens skip your team" or "OFF", 2)
    end
})

CombatTab:CreateSlider({
    Name = "Min Target Level (skip low levels)",
    Range = {0, 2550},
    Increment = 50,
    Suffix = "",
    CurrentValue = 2300,
    Flag = "MinTargetLevel",
    Callback = function(Value)
        Hub.MinTargetLevel = Value
    end
})

-- ============================================================
--  UI | SILENT AIM TAB
-- ============================================================
SilentAimTab:CreateToggle({
    Name = "Silent Aim — Players",
    CurrentValue = false,
    Flag = "SAPlayers",
    Callback = function(Value)
        SilentAimModule:SetPlayers(Value)
        Notify("Silent Aim", Value and "Players: ON" or "Players: OFF", 2)
    end
})

SilentAimTab:CreateToggle({
    Name = "Silent Aim — NPCs",
    CurrentValue = false,
    Flag = "SANPCs",
    Callback = function(Value)
        SilentAimModule:SetNPCs(Value)
        Notify("Silent Aim", Value and "NPCs: ON" or "NPCs: OFF", 2)
    end
})

SilentAimTab:CreateToggle({
    Name = "Z Skill / M1 Redirection",
    CurrentValue = false,
    Flag = "ZSkillM1",
    Callback = function(Value)
        SilentAimModule:SetZSkill(Value)
        Notify("Z Skill/M1", Value and "Enabled" or "Disabled", 2)
    end
})

SilentAimTab:CreateToggle({
    Name = "Prediction (velocity buffer)",
    CurrentValue = false,
    Flag = "SAPrediction",
    Callback = function(Value)
        SilentAimModule:SetPrediction(Value)
        Notify("Prediction", Value and "Enabled" or "Disabled", 2)
    end
})

SilentAimTab:CreateSlider({
    Name = "Prediction Lead Time",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "SAPredictionAmount",
    Callback = function(Value)
        SilentAimModule:SetPredictionAmount(Value)
    end
})

SilentAimTab:CreateToggle({
    Name = "Target Highlight",
    CurrentValue = false,
    Flag = "SAHighlight",
    Callback = function(Value)
        SilentAimModule:SetHighlight(Value)
        Notify("Highlight", Value and "Enabled" or "Disabled", 2)
    end
})

SilentAimTab:CreateToggle({
    Name = "Auto Ken (Observation)",
    CurrentValue = false,
    Flag = "AutoKen",
    Callback = function(Value)
        SilentAimModule:SetKen(Value)
        Notify("Auto Ken", Value and "Enabled" or "Disabled", 2)
    end
})

SilentAimTab:CreateSlider({
    Name = "Silent Aim Range",
    Range = {50, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 1000,
    Flag = "SAMaxRange",
    Callback = function(Value)
        SilentAimModule:SetRange(Value)
    end
})

-- ============================================================
--  UI | MOVEMENT TAB
-- ============================================================
MovementTab:CreateToggle({
    Name = "Fly (Mobile: joystick + ▲▼ buttons)",
    CurrentValue = true,
    Flag = "Fly",
    Callback = function(Value)
        Config.Fly = Value
        if Value then
            Hub.StartFly()
            Notify("Fly", "Enabled — ▲▼ buttons on screen", 2)
        else
            Hub.StopFly()
            Notify("Fly", "Disabled", 2)
        end
    end
})

MovementTab:CreateSlider({
    Name = "Fly / Tween Speed",
    Range = {50, 180},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = 180,
    Flag = "TweenSpeed",
    Callback = function(Value)
        Hub.TweenSpeedVal = Value
    end
})

MovementTab:CreateToggle({
    Name = "Tween to Selected Player (Smooth Pursuit)",
    CurrentValue = false,
    Flag = "TweenPlayer",
    Callback = function(Value)
        Config.TweenToPlayer = Value
        if Value then
            Config.TweenToNearest = false
            Hub.StartTween()
            Notify("Tween", "Pursuing selected player", 2)
        else
            Hub.StopTween()
            Notify("Tween Player", "Disabled", 2)
        end
    end
})

MovementTab:CreateToggle({
    Name = "Tween to Nearest (PVP Only, Smooth Pursuit)",
    CurrentValue = false,
    Flag = "TweenNearest",
    Callback = function(Value)
        Config.TweenToNearest = Value
        if Value then
            Config.TweenToPlayer = false
            Hub.StartTween()
            Notify("Tween", "Pursuing nearest combatant", 2)
        else
            Hub.StopTween()
            Notify("Tween Nearest", "Disabled", 2)
        end
    end
})

MovementTab:CreateSlider({
    Name = "Snap Distance (final approach)",
    Range = {0, 100},
    Increment = 5,
    Suffix = "studs",
    CurrentValue = 25,
    Flag = "InstaSnap",
    Callback = function(Value)
        Hub.InstaSnapDistance = Value
    end
})

MovementTab:CreateSlider({
    Name = "Tween X Offset (their left/right)",
    Range = {-50, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 0,
    Flag = "TweenXOff",
    Callback = function(Value)
        Hub.TweenXOffset = Value
    end
})

MovementTab:CreateSlider({
    Name = "Tween Y Offset (up/down)",
    Range = {-50, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 5,
    Flag = "TweenYOff",
    Callback = function(Value)
        Hub.TweenYOffset = Value
    end
})

MovementTab:CreateSlider({
    Name = "Tween Z Offset (front/behind)",
    Range = {-50, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 5,
    Flag = "TweenZOff",
    Callback = function(Value)
        Hub.TweenZOffset = Value
    end
})

MovementTab:CreateSection("Orbit")

MovementTab:CreateToggle({
    Name = "Orbit Selected Target",
    CurrentValue = false,
    Flag = "OrbitTarget",
    Callback = function(Value)
        if Value then
            Hub.StartOrbit()
            Notify("Orbit", "Circling target", 2)
        else
            Hub.StopOrbit()
            Notify("Orbit", "Stopped", 2)
        end
    end
})

MovementTab:CreateSlider({
    Name = "Orbit Radius",
    Range = {10, 200},
    Increment = 5,
    Suffix = "studs",
    CurrentValue = 67,
    Flag = "OrbitRadius",
    Callback = function(Value)
        Hub.OrbitRadius = Value
    end
})

MovementTab:CreateSlider({
    Name = "Orbit Speed",
    Range = {1, 20},
    Increment = 1,
    Suffix = "",
    CurrentValue = 5,
    Flag = "OrbitSpeed",
    Callback = function(Value)
        Hub.OrbitSpeed = Value
    end
})

MovementTab:CreateSection("Character")

MovementTab:CreateToggle({
    Name = "NoClip",
    CurrentValue = true,
    Flag = "NoClipToggle",
    Callback = function(Value)
        Config.NoClip = Value
        Notify("NoClip", Value and "Enabled" or "Disabled", 2)
    end
})

MovementTab:CreateToggle({
    Name = "Anti Stun (full AntiMover)",
    CurrentValue = true,
    Flag = "AntiStunToggle",
    Callback = function(Value)
        Config.AntiStun = Value
        Notify("Anti Stun", Value and "Enabled" or "Disabled", 2)
    end
})

MovementTab:CreateToggle({
    Name = "Ice Water (WaterWalking attribute)",
    CurrentValue = false,
    Flag = "IceWaterToggle",
    Callback = function(Value)
        Config.IceWater = Value
        Notify("Ice Water", Value and "Enabled" or "Disabled", 2)
    end
})

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(Value)
        Hub.InfJumpEnabled = Value
        Notify("Infinite Jump", Value and "Enabled" or "Disabled", 2)
    end
})

MovementTab:CreateToggle({
    Name = "Extended Dash Length",
    CurrentValue = false,
    Flag = "DashLength",
    Callback = function(Value)
        Hub.DashLengthEnabled = Value
        if not Value then
            pcall(function()
                local char = player.Character
                if char then
                    char:SetAttribute("DashLength", 1)
                    char:SetAttribute("DashLengthAir", 1)
                end
            end)
        end
        Notify("Dash Length", Value and "Enabled" or "Disabled", 2)
    end
})

MovementTab:CreateSlider({
    Name = "Dash Length Value",
    Range = {1, 500},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Flag = "DashLengthVal",
    Callback = function(Value)
        Hub.DashLengthValue = Value
    end
})

MovementTab:CreateToggle({
    Name = "Remove Idle Animations (keeps attacks)",
    CurrentValue = false,
    Flag = "NoAnims",
    Callback = function(Value)
        Hub.RemoveAnimsEnabled = Value
        Notify("Remove Animations", Value and "Enabled" or "Disabled", 2)
    end
})

MovementTab:CreateSection("World")

MovementTab:CreateToggle({
    Name = "Anti Lava (CanTouch + delete lava)",
    CurrentValue = false,
    Flag = "AntiLava",
    Callback = function(Value)
        Hub.AntiLavaActive = Value
        Notify("Anti Lava", Value and "Enabled — lava deleted + no touch" or "Disabled", 2)
    end
})

MovementTab:CreateToggle({
    Name = "Delete Ghost Ship Structures",
    CurrentValue = false,
    Flag = "DeleteShip",
    Callback = function(Value)
        Hub.DeleteShipActive = Value
        Notify("Ghost Ship", Value and "Deleting ship clutter every 3s" or "Stopped", 2)
    end
})

MovementTab:CreateToggle({
    Name = "Walk on Water",
    CurrentValue = false,
    Flag = "WalkWater",
    Callback = function(Value)
        Hub.WalkOnWaterEnabled = Value
        Notify("Walk on Water", Value and "Enabled" or "Disabled", 2)
    end
})

-- ============================================================
--  UI | VISUALS TAB
-- ============================================================
VisualTab:CreateToggle({
    Name = "Player & NPC ESP (Lvl/Bounty/PvP)",
    CurrentValue = true,
    Flag = "ESP",
    Callback = function(Value)
        Config.ESP = Value
        if Value then
            Notify("ESP", "Enabled", 2)
        else
            Hub.ClearESP()
            Notify("ESP", "Disabled", 2)
        end
    end
})

VisualTab:CreateButton({
    Name = "FPS Boost (one-shot optimizer)",
    Callback = function()
        Hub.ApplyFPSBoost()
        Notify("FPS Boost", "Applied — materials flattened, effects killed", 3)
    end
})

-- ============================================================
--  UI | PLAYERS TAB (target select + player lists)
-- ============================================================
do
    local playerNames = {}
    local function RefreshPlayerDropdown()
        playerNames = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                table.insert(playerNames, p.Name)
            end
        end
    end
    RefreshPlayerDropdown()

    local PlayerDropdown = PlayerTab:CreateDropdown({
        Name = "Select Target Player",
        Options = playerNames,
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "TargetPlayer",
        Callback = function(Option)
            Hub.SelectedPlayerName = Option[1]
            if Hub.SelectedPlayerName then
                Hub.SelectedPlayerObj = Players:FindFirstChild(Hub.SelectedPlayerName)
                SilentAimModule:SetSelectedPlayer(Hub.SelectedPlayerObj)
                Notify("Target Selected", Hub.SelectedPlayerName, 2)
            else
                Hub.SelectedPlayerObj = nil
                SilentAimModule:SetSelectedPlayer(nil)
            end
        end
    })

    PlayerTab:CreateButton({
        Name = "Clear Selected Target",
        Callback = function()
            Hub.SelectedPlayerName = nil
            Hub.SelectedPlayerObj = nil
            SilentAimModule:SetSelectedPlayer(nil)
            PlayerDropdown:Set({})
            Notify("Target", "Cleared — silent aim back to closest", 2)
        end
    })

    local function getListEntries()
        local entries = {}
        for name, _ in pairs(Hub.PlayerList) do
            table.insert(entries, name)
        end
        return entries
    end

    PlayerTab:CreateSection("Player Lists (protect / hunt)")

    PlayerTab:CreateDropdown({
        Name = "List Mode",
        Options = {"Off", "Blacklist (never target listed)", "Whitelist (only target listed)"},
        CurrentOption = {"Off"},
        MultipleOptions = false,
        Flag = "ListMode",
        Callback = function(Option)
            local mode = Option[1] or "Off"
            if mode:find("Blacklist") then
                Hub.ListMode = "Blacklist"
            elseif mode:find("Whitelist") then
                Hub.ListMode = "Whitelist"
            else
                Hub.ListMode = "Off"
            end
            Notify("List Mode",
                Hub.ListMode == "Blacklist" and "Listed players are PROTECTED" or
                Hub.ListMode == "Whitelist" and "ONLY listed players are targetable" or
                "List system off", 3)
        end
    })

    local ListAddDropdown = PlayerTab:CreateDropdown({
        Name = "Add Player to List",
        Options = playerNames,
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "ListAdd",
        Callback = function(Option)
        end
    })

    local ListRemoveDropdown = PlayerTab:CreateDropdown({
        Name = "Listed Players",
        Options = getListEntries(),
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "ListRemove",
        Callback = function(Option)
        end
    })

    PlayerTab:CreateButton({
        Name = "+ Add Listed Player",
        Callback = function()
            local sel = ListAddDropdown:Get()
            local name = sel and sel[1]
            if name and name ~= "" then
                Hub.PlayerList[name] = true
                Notify("Player List", name .. " added (" .. Hub.ListMode .. " mode)", 2)
                ListRemoveDropdown:Refresh(getListEntries())
            else
                Notify("Player List", "Select a player in the dropdown above first", 2)
            end
        end
    })

    PlayerTab:CreateButton({
        Name = "- Remove Listed Player",
        Callback = function()
            local sel = ListRemoveDropdown:Get()
            local name = sel and sel[1]
            if name then
                Hub.PlayerList[name] = nil
                Notify("Player List", name .. " removed", 2)
                ListRemoveDropdown:Refresh(getListEntries())
            else
                Notify("Player List", "Select a listed player first", 2)
            end
        end
    })

    PlayerTab:CreateButton({
        Name = "Clear Player List",
        Callback = function()
            Hub.PlayerList = {}
            ListRemoveDropdown:Refresh({})
            Notify("Player List", "Cleared", 2)
        end
    })

    PlayerTab:CreateButton({
        Name = "Refresh Player List",
        Callback = function()
            RefreshPlayerDropdown()
            PlayerDropdown:Refresh(playerNames)
            ListAddDropdown:Refresh(playerNames)
            ListRemoveDropdown:Refresh(getListEntries())
            Notify("Player List", "Refreshed", 2)
        end
    })

    Players.PlayerAdded:Connect(function()
        task.wait(1)
        RefreshPlayerDropdown()
        PlayerDropdown:Refresh(playerNames)
        ListAddDropdown:Refresh(playerNames)
    end)
    Players.PlayerRemoving:Connect(function()
        task.wait(1)
        RefreshPlayerDropdown()
        PlayerDropdown:Refresh(playerNames)
        ListAddDropdown:Refresh(playerNames)
    end)
end

-- ============================================================
--  UI | TELEPORTS TAB
-- ============================================================
do
    local islandNames = {}
    local function RefreshIslands()
        islandNames = {}
        local locations = workspace:FindFirstChild("_WorldOrigin")
            and workspace._WorldOrigin:FindFirstChild("Locations")
        if locations then
            for _, v in ipairs(locations:GetChildren()) do
                table.insert(islandNames, v.Name)
            end
        end
    end
    RefreshIslands()

    local SelectedIsland = nil
    local IslandDropdown = TeleportsTab:CreateDropdown({
        Name = "Select Island",
        Options = islandNames,
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "SelIsland",
        Callback = function(Option)
            SelectedIsland = Option[1]
        end
    })

    TeleportsTab:CreateButton({
        Name = "Teleport to Island",
        Callback = function()
            if not SelectedIsland then
                Notify("Teleport", "Select an island first", 2)
                return
            end
            local locations = workspace:FindFirstChild("_WorldOrigin")
                and workspace._WorldOrigin:FindFirstChild("Locations")
            local part = locations and locations:FindFirstChild(SelectedIsland)
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not part or not hrp then
                Notify("Teleport", "Island not found in this sea", 2)
                return
            end

            local targetPos = (part.CFrame + Vector3.new(0, 10, 0)).Position
            local dist = (hrp.Position - targetPos).Magnitude

            local usedRemote = pcall(function()
                Hub.CommF:InvokeServer("requestEntrance", targetPos)
            end)

            if not usedRemote or dist > 15000 then
                if dist < Hub.InstaSnapDistance then
                    hrp.CFrame = CFrame.new(targetPos)
                    Notify("Teleport", "Snapped to " .. SelectedIsland, 2)
                else
                    Notify("Teleport", "Tweening to " .. SelectedIsland .. "...", 2)
                    local timeToArrive = math.max(0.1, dist / 180)
                    TweenService:Create(
                        hrp,
                        TweenInfo.new(timeToArrive, Enum.EasingStyle.Linear),
                        {CFrame = CFrame.new(targetPos)}
                    ):Play()
                end
            else
                Notify("Teleport", "Warped to " .. SelectedIsland, 2)
            end
        end
    })

    TeleportsTab:CreateButton({
        Name = "Refresh Island List",
        Callback = function()
            RefreshIslands()
            IslandDropdown:Refresh(islandNames)
            Notify("Teleport", "Island list refreshed", 2)
        end
    })

    local npcNames = {}
    local function RefreshNPCs()
        npcNames = {}
        local npcs = workspace:FindFirstChild("NPCs")
        if npcs then
            for _, v in ipairs(npcs:GetChildren()) do
                if v:IsA("Model") then
                    table.insert(npcNames, v.Name)
                end
            end
        end
    end
    RefreshNPCs()

    local SelectedNPC = nil
    local NPCDropdown = TeleportsTab:CreateDropdown({
        Name = "Select NPC",
        Options = npcNames,
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "SelNPC",
        Callback = function(Option)
            SelectedNPC = Option[1]
        end
    })

    TeleportsTab:CreateButton({
        Name = "Teleport to NPC",
        Callback = function()
            if not SelectedNPC then
                Notify("Teleport", "Select an NPC first", 2)
                return
            end
            local npcs = workspace:FindFirstChild("NPCs")
            local npc = npcs and npcs:FindFirstChild(SelectedNPC)
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local target = npc and (npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart"))

            if target and hrp then
                local destCFrame = target.CFrame + Vector3.new(0, 5, 0)
                local dist = (hrp.Position - target.Position).Magnitude

                if dist < 500 then
                    hrp.CFrame = destCFrame
                    Notify("Teleport", "Warped to " .. SelectedNPC, 2)
                else
                    local timeToArrive = math.max(0.1, dist / 180)
                    TweenService:Create(
                        hrp,
                        TweenInfo.new(timeToArrive, Enum.EasingStyle.Linear),
                        {CFrame = destCFrame}
                    ):Play()
                    Notify("Teleport", "Tweening to " .. SelectedNPC .. "...", 2)
                end
            else
                Notify("Teleport", "NPC not found", 2)
            end
        end
    })

    TeleportsTab:CreateButton({
        Name = "Refresh NPC List",
        Callback = function()
            RefreshNPCs()
            NPCDropdown:Refresh(npcNames)
            Notify("Teleport", "NPC list refreshed", 2)
        end
    })
end

-- ============================================================
--  UI | RACES TAB
-- ============================================================
do
    local raceOptions = {"Human", "Skypiea", "FishMan", "Mink"}
    local SelectedRace = nil

    RacesTab:CreateDropdown({
        Name = "Select Race",
        Options = raceOptions,
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "SelRace",
        Callback = function(Option)
            SelectedRace = Option[1]
        end
    })

    RacesTab:CreateButton({
        Name = "Upgrade Race",
        Callback = function()
            if not SelectedRace then
                Notify("Races", "Select a race first", 2)
                return
            end
            local ok = pcall(function()
                Hub.CommF:InvokeServer("UpgradeRace", SelectedRace)
            end)
            Notify("Races", ok and ("Upgrade request sent: " .. SelectedRace) or "Upgrade failed", ok and 2 or 3)
        end
    })

    RacesTab:CreateButton({
        Name = "Buy Race Reroll (3000F)",
        Callback = function()
            local ok = pcall(function()
                Hub.CommF:InvokeServer("BlackbeardReward", "Reroll", "1")
            end)
            Notify("Races", ok and "Reroll purchased" or "Reroll failed", 2)
        end
    })

    RacesTab:CreateButton({
        Name = "Switch Ghoul / Draco",
        Callback = function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local data = player:FindFirstChild("Data")
            if not hrp or not data or not data:FindFirstChild("Race") then
                Notify("Races", "Character not ready", 2)
                return
            end

            local currentRace = data.Race.Value

            if currentRace == "Ghoul" then
                Notify("Races", "Switching to Draco...", 2)
                local savedCFrame = hrp.CFrame

                hrp.CFrame = CFrame.new(5814.42724609375, 1208.3267822265625, 884.5785522460938)
                task.wait(0.1)

                local ok = pcall(function()
                    local netFolder = ReplicatedStorage:FindFirstChild("Modules")
                        and ReplicatedStorage.Modules:FindFirstChild("Net")
                    if netFolder and netFolder:FindFirstChild("RF/InteractDragonQuest") then
                        netFolder["RF/InteractDragonQuest"]:InvokeServer({
                            NPC = "Dragon Wizard",
                            Command = "DragonRace",
                        })
                    end
                end)

                task.wait(0.1)
                hrp.CFrame = savedCFrame

                Notify("Races", ok and "Draco switch fired" or "Draco remote failed", 2)
            else
                Notify("Races", "Switching to Ghoul...", 2)
                local ok = pcall(function()
                    Hub.CommF:InvokeServer("Ectoplasm", "Change", 4)
                end)
                Notify("Races", ok and "Ghoul switch fired" or "Ghoul switch failed", 2)
            end

            task.wait(1)
            Notify("Races", "Current race: " .. tostring(player.Data.Race.Value), 3)
        end
    })
end

-- ============================================================
--  UI | SERVER TAB (queued bounty hopper)
-- ============================================================
do
    local StoredJobID = ""
    local BountyHopRunning = false
    local HopQueue = {}
    local JoinAttempts = {}

    ServerTab:CreateButton({
        Name = "Copy Current Job ID",
        Callback = function()
            local jobId = game.JobId
            if setclipboard then
                setclipboard(jobId)
                Notify("Server", "Job ID copied: " .. jobId, 3)
            elseif toclipboard then
                toclipboard(jobId)
                Notify("Server", "Job ID copied: " .. jobId, 3)
            else
                Notify("Server", "No clipboard function available", 3)
            end
        end
    })

    ServerTab:CreateInput({
        Name = "Job ID",
        PlaceholderText = "paste job id here",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            StoredJobID = Text
        end
    })

    ServerTab:CreateButton({
        Name = "Join Job ID",
        Callback = function()
            if not StoredJobID or StoredJobID == "" then
                Notify("Server", "Enter a Job ID first", 3)
                return
            end
            HopToServer(StoredJobID)
        end
    })

    ServerTab:CreateButton({
        Name = "Rejoin Server",
        Callback = function()
            Notify("Server", "Rejoining...", 2)
            pcall(function()
                TeleportService:Teleport(game.PlaceId)
            end)
        end
    })

    ServerTab:CreateButton({
        Name = "Hop to Random Server",
        Callback = function()
            Notify("Server", "Fetching server list...", 2)
            task.spawn(function()
                local candidates = GetServerCandidates()
                if #candidates > 0 then
                    local pick = candidates[math.random(1, #candidates)]
                    Notify("Server", "Hopping to server with " .. pick.playing .. " players", 2)
                    HopToServer(pick.id)
                else
                    Notify("Server", "No servers found — check executor HTTP support", 4)
                end
            end)
        end
    })

    ServerTab:CreateButton({
        Name = "Hop to Least Players Server",
        Callback = function()
            Notify("Server", "Scanning for emptiest server...", 2)
            task.spawn(function()
                local candidates = GetServerCandidates()
                if #candidates > 0 then
                    table.sort(candidates, function(a, b) return a.playing < b.playing end)
                    local best = candidates[1]
                    Notify("Server", "Joining server with " .. best.playing .. " players", 2)
                    HopToServer(best.id)
                else
                    Notify("Server", "No servers found", 4)
                end
            end)
        end
    })

    ServerTab:CreateSection("Bounty System")

    ServerTab:CreateButton({
        Name = "Show Current Server Bounty",
        Callback = function()
            local total, topName, topVal = GetCurrentServerBounty()
            local count = #Players:GetPlayers()
            Notify("Server Bounty",
                string.format("Total: %s | %d players\nTop: %s (%s)",
                    FormatBounty(total), count, topName, FormatBounty(topVal)),
                6)
        end
    })

    ServerTab:CreateSlider({
        Name = "Min Single-Player Bounty",
        Range = {1000000, 500000000},
        Increment = 1000000,
        Suffix = "",
        CurrentValue = 100000000,
        Flag = "BountyMinSingle",
        Callback = function(Value)
            Hub.BountyMinSingle = Value
        end
    })

    ServerTab:CreateSlider({
        Name = "Min Server Total Bounty",
        Range = {1000000, 500000000},
        Increment = 1000000,
        Suffix = "",
        CurrentValue = 30000000,
        Flag = "BountyMinTotal",
        Callback = function(Value)
            Hub.BountyMinTotal = Value
        end
    })

    ServerTab:CreateSlider({
        Name = "Queue Pages (100 servers each)",
        Range = {1, 100},
        Increment = 1,
        Suffix = "",
        CurrentValue = 10,
        Flag = "BountyPages",
        Callback = function(Value)
            Hub.BountyMaxPages = Value
        end
    })

    ServerTab:CreateToggle({
        Name = "Auto Bounty Hop (queued)",
        CurrentValue = false,
        Flag = "BountyHop",
        Callback = function(Value)
            BountyHopRunning = Value
            if Value then
                HopQueue = {}
                JoinAttempts = {}
                Notify("Bounty Hop", "Started — hunting " .. FormatBounty(Hub.BountyMinSingle) .. "+ players", 4)
                task.spawn(function()
                    local function LoadHopQueue()
                        HopQueue = {}
                        local cursor = ""
                        for page = 1, Hub.BountyMaxPages do
                            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                            local data = httpGetJson(url)
                            if not data or not data.data then break end
                            for _, s in ipairs(data.data) do
                                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                                    table.insert(HopQueue, {id = s.id, playing = s.playing})
                                end
                            end
                            cursor = data.nextPageCursor or ""
                            if cursor == "" then break end
                            task.wait(0.3)
                        end
                        for i = #HopQueue, 2, -1 do
                            local j = math.random(i)
                            HopQueue[i], HopQueue[j] = HopQueue[j], HopQueue[i]
                        end
                    end

                    while BountyHopRunning do
                        local waited = 0
                        while BountyHopRunning and waited < 10 do
                            local char = player.Character
                            local data = player:FindFirstChild("Data")
                            if char and char:FindFirstChild("HumanoidRootPart") and data then break end
                            task.wait(1)
                            waited = waited + 1
                        end
                        if not BountyHopRunning then break end

                        task.wait(Hub.BountyPostTeleportWait)

                        local scanDeadline = os.clock() + Hub.BountyScanTimeout
                        local total, topName, topVal = 0, "None", 0
                        while os.clock() < scanDeadline do
                            total, topName, topVal = GetCurrentServerBounty()
                            if total > 0 then break end
                            task.wait(1)
                        end

                        Notify("Bounty Hop",
                            string.format("Server: %s | Top: %s (%s)",
                                FormatBounty(total), topName, FormatBounty(topVal)),
                            4)

                        if topVal >= Hub.BountyMinSingle or total >= Hub.BountyMinTotal then
                            Notify("Bounty Hop", "TARGET FOUND — staying in this server!", 6)
                            BountyHopRunning = false
                            break
                        end

                        local picked = nil
                        while #HopQueue > 0 do
                            local c = table.remove(HopQueue)
                            if (JoinAttempts[c.id] or 0) < Hub.BountyMaxJoinAttempts then
                                picked = c
                                break
                            end
                        end

                        if not picked then
                            Notify("Bounty Hop", "Queue empty — reloading pages...", 2)
                            LoadHopQueue()
                            while #HopQueue > 0 do
                                local c = table.remove(HopQueue)
                                if (JoinAttempts[c.id] or 0) < Hub.BountyMaxJoinAttempts then
                                    picked = c
                                    break
                                end
                            end
                        end

                        if not picked then
                            Notify("Bounty Hop", "All attempts exhausted — rejoining", 3)
                            pcall(function()
                                TeleportService:Teleport(game.PlaceId)
                            end)
                            break
                        end

                        JoinAttempts[picked.id] = (JoinAttempts[picked.id] or 0) + 1
                        local prevJob = game.JobId
                        Notify("Bounty Hop", "Hopping to server (" .. picked.playing .. " players) — attempt " .. JoinAttempts[picked.id], 2)
                        task.wait(0.5)
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, picked.id, player)
                        end)

                        local failWait = 0
                        while BountyHopRunning and failWait < 6 do
                            task.wait(1)
                            failWait = failWait + 1
                        end
                        if BountyHopRunning and game.JobId == prevJob then
                            Notify("Bounty Hop", "Join failed — retrying after cooldown", 2)
                            task.wait(Hub.BountyTeleportRetryWait)
                        end

                        task.wait(1)
                    end
                end)
            else
                Notify("Bounty Hop", "Stopped", 2)
            end
        end
    })
end

-- ============================================================
--  INITIALIZE DEFAULTS
-- ============================================================
task.spawn(function()
    task.wait(0.5)
    Hub.StartFly()
    pcall(function() player.CameraMaxZoomDistance = 128 end)
    Notify("Alien Hub", "v3.9.5 loaded — quick actions active", 3)
end)