-- Language: Luau (Roblox Client / Executor)
-- Module: projectsion_windui.lua (Full script)
-- Runtime: Roblox Luau VM (WindUI dist/main.lua)
-- *WindUI Slider reads bounds and initial position from `Value = { Min = ..., Max = ..., Default = ... }` and normalizes callbacks across numeric or table values.*
-- *WindUI Dropdown reads initial selection from `Value` alongside `Values` and updates options via `:Refresh(values)`.*

-- ============================================================================
-- PROJECTSION × WINDUI
-- WindUI library: https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua
-- Autofarm core merged — Rayfield removed, Adonis replaced with hiadonis()
-- RideGO upgraded to v15f-clean (A* Road Graph, Hover-Step, Gap-Fly)
-- ============================================================================

-- ── Game-load guard ──────────────────────────────────────────────────────────
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

-- ── Adonis bypass ────────────────────────────────────────────────────────────
local function unfreezeTable(t)
    if type(t) == "table" then
        pcall(function()
            if setreadonly    then setreadonly(t, false)  end
            if table.unfreeze then table.unfreeze(t)      end
            if make_writeable then make_writeable(t)      end
        end)
        for _, v in pairs(t) do
            if type(v) == "table" then unfreezeTable(v) end
        end
    end
end

local function falsifyIndexInstance()
    if not getgc then return end
    for _, v in pairs(getgc(true)) do
        pcall(function()
            local idx = rawget(v, "indexInstance")
            if type(idx) == "table" and idx[1] == "kick" then
                setreadonly(v, false)
                v.tvk = { "kick", function()
                    return game.Workspace:WaitForChild("")
                end }
                setreadonly(v, true)
            end
        end)
    end
end

local function hiadonis()
    local Detected = filtergc("function", {
        Constants      = { " - On Xbox", " - On mobile", "_" },
        IgnoreExecutor = true,
    }, true)
    if not Detected then
        warn("[projectsion] filtergc miss — Adonis not loaded or constants changed")
        return false
    end

    local s, l, a, n, f = debug.info(Detected, "slanf")
    warn("[projectsion] Detected located.")

    local targetDebug = (typeof(REnv) == "table" and REnv.debug) or debug
    local origDebugInfo
    if targetDebug and targetDebug.info then
        origDebugInfo = hookfunction(targetDebug.info, newcclosure(function(fn, fmt, ...)
            if fn == Detected and fmt == "slanf" then return s, l, a, n, f end
            return origDebugInfo(fn, fmt, ...)
        end))
    end

    hookfunction(Detected, newcclosure(function(...)
        return coroutine.yield(coroutine.running())
    end))

    local Kill = filtergc("function", {
        Constants = { "Kill", "Variables", "Process" }, IgnoreExecutor = true,
    }, true)
    if Kill then
        warn("[projectsion] Kill located.")
        hookfunction(Kill, newcclosure(function(...) end))
    end

    local Log = filtergc("function", {
        Constants = { "Log", "Logs", "LogMessage" }, IgnoreExecutor = true,
    }, true)
    if Log then
        warn("[projectsion] Log located.")
        hookfunction(Log, newcclosure(function(...) end))
    end

    setthreadidentity(2)
    for _, v in getgc(true) do
        if typeof(v) == "table" then
            unfreezeTable(v)
            local dk = rawget(v, "Detected")
            local kk = rawget(v, "Kill")
            local lk = rawget(v, "Log")
            if dk ~= nil then
                pcall(rawset, v, "Detected", function() return false end)
            end
            if typeof(dk) == "function" and dk ~= Detected then
                pcall(hookfunction, dk, function(...) return true end)
            end
            if typeof(kk) == "function" and kk ~= Kill then
                pcall(hookfunction, kk, function(...) end)
            end
            if typeof(lk) == "function" and lk ~= Log then
                pcall(hookfunction, lk, function(...) end)
            end
        end
    end
    setthreadidentity(7)

    pcall(falsifyIndexInstance)
    return true
end

task.delay(1.5, function()
    local ok = hiadonis()
    if not ok then
        task.delay(3, function()
            local retry = hiadonis()
            warn("[projectsion] Adonis bypass " .. (retry and "active (retry)." or "failed — check constants."))
        end)
    else
        warn("[projectsion] Adonis bypass active.")
    end
end)

pcall(function()
    local networkPause = game:GetService('CoreGui').RobloxGui:FindFirstChild('CoreScripts/NetworkPause')
    if networkPause then networkPause:Destroy() end
end)

-- ── Services ─────────────────────────────────────────────────────────────────
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local LP                = Players.LocalPlayer
local RunService        = game:GetService("RunService")
local PlayerData        = LP:WaitForChild("PlayerData")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local TeleportService   = game:GetService("TeleportService")
local VIM               = game:GetService("VirtualInputManager")

-- ── Game refs ─────────────────────────────────────────────────────────────────
local CourierSettings = require(ReplicatedStorage:WaitForChild("Delivery System"):WaitForChild("Settings"))
local MachinePrompt   = workspace.BaristaJob.Interactions.MachinePart.MachinePart.MachinePrompt
local RegisterPrompt  = workspace.BaristaJob.Interactions.RegisterPart.RegisterPart.RegisterPrompt
local SupplyPrompt    = workspace.BaristaJob.Interactions.SupplyPart.SupplyPart.SupplyPrompt
local JobPrompt       = workspace.BaristaJob.Interactions.StartPart.StartPart.JobPrompt

local SupplyCF        = CFrame.new(-5116.78418, 5.78931046, -670.858887)
local MachineCF       = CFrame.new(-4997.1665, 1.58353043, -795.047607)
local RegisterCF      = CFrame.new(-4994.06934, 1.30402756, -760.247437)
local StartJobCF      = CFrame.new(-4989.80078, 5.30382967, -715.013062)
local TAKE_BOX_CFRAME = CFrame.new(-5105.61182, 4.48948574, -3758.98267)
local TAKE_PROMPT     = workspace:WaitForChild("Livrason"):WaitForChild("Take1"):WaitForChild("Take"):WaitForChild("ProximityPrompt")

-- ── _G flags ──────────────────────────────────────────────────────────────────
_G.AutofarmCourier      = false
_G.CourierSpeedMin      = 150
_G.CourierSpeedMax      = 330
_G.AutoFarmBarista      = false
_G.BaristaSpeedMin      = 200
_G.BaristaSpeedMax      = 380
_G.AutoPoliceEnabled    = false
_G.RideGOEnabled        = false
_G.blackscreen          = false
_G.PermanentBlackscreen = false
_G.RejoinTriggered      = false

_G.AutoWebhook  = false
_G.WebhookURL   = ""
_G.TotalEarning = 0
_G.CycleCount   = 0

_G.CourierEarned    = 0
_G.BaristaEarned    = 0
_G.PoliceEarned     = 0
_G.AutoDriveEarned  = 0
_G.RideGOEarned     = 0

-- ── Locals ───────────────────────────────────────────────────────────────────
local LastActivity    = tick()
local lastMoney       = PlayerData.RPValue.Value
local pendingIncome   = 0
local isRunning       = false
local WaktuKosong     = nil

local AutoPoliceConfig = {
    TeleportSpeed    = {min = 200, max = 300},
    PostTeleportWait = {min = 2,   max = 4},
    WalkTimeout      = 10,
    TargetOffset     = 15,
    LoopDelay        = 1
}

local ActiveConnections = {}
local NeedJobRefresh, RequestingJob = false, false
local TeleportActive    = false
local missionsCompleted = 0
local AnchoredPartsList = {}
local ActiveMissions    = Workspace:WaitForChild("ActiveMissions", 10)

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function rngSpeed(minSpd, maxSpd)
    local a = minSpd + math.random() * (maxSpd - minSpd)
    local b = minSpd + math.random() * (maxSpd - minSpd)
    return (a + b) / 2
end

local function extractSliderValue(raw, fallback)
    if type(raw) == "number" then
        return raw
    elseif type(raw) == "table" then
        local candidate = raw.Value or raw.Default or raw.Current or raw[1]
        if type(candidate) == "number" then
            return candidate
        end
    end
    local parsed = tonumber(raw)
    return parsed or fallback
end

local _activeSeconds = 0
local _farmTickStart = nil

local function _syncFarmTimer()
    local anyActive = _G.AutofarmCourier or _G.AutoFarmBarista
        or _G.AutoPoliceEnabled or _G.AutoDriveActive or _G.RideGOEnabled
    if anyActive and not _farmTickStart then
        _farmTickStart = tick()
    elseif not anyActive and _farmTickStart then
        _activeSeconds = _activeSeconds + (tick() - _farmTickStart)
        _farmTickStart = nil
    end
end

local function getActiveSeconds()
    if _farmTickStart then return _activeSeconds + (tick() - _farmTickStart) end
    return _activeSeconds
end

local function formatRP(v)
    local s         = string.format("%.0f", v)
    local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "RP. " .. formatted
end

local function generateRandomName()
    local chars  = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local length = math.random(12, 24)
    local result = ""
    for i = 1, length do
        result = result .. string.sub(chars, math.random(1, #chars), math.random(1, #chars))
    end
    return result
end

local function getRunningTimeWall()
    if not _G._wallStart then return "00:00:00" end
    local diff = os.time() - _G._wallStart
    return string.format("%02d:%02d:%02d",
        math.floor(diff / 3600), math.floor((diff % 3600) / 60), diff % 60)
end

local function sendWebhook(income, target)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount = _G.CycleCount + 1
    local currentMoney = PlayerData.RPValue.Value
    local http_request  = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    local embed = {
        ["author"] = {["name"] = "Projectsion Webhook"},
        ["title"]  = "Cycle Completed",
        ["color"]  = 0xFFFFFF,
        ["fields"] = {
            {["name"] = "Username",      ["value"] = LP.Name,                               ["inline"] = false},
            {["name"] = "Cycle Income",  ["value"] = formatRP(income),                      ["inline"] = false},
            {["name"] = "Target",        ["value"] = formatRP(target),                      ["inline"] = false},
            {["name"] = "Current Money", ["value"] = formatRP(currentMoney) .. " (Est)",    ["inline"] = false},
            {["name"] = "Total Earning", ["value"] = formatRP(_G.TotalEarning) .. " (Est)", ["inline"] = false},
            {["name"] = "Running Time",  ["value"] = getRunningTimeWall(),                  ["inline"] = false},
        },
        ["footer"] = {["text"] = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p")}
    }
    local payload = HttpService:JSONEncode({["username"] = "Projectsion Reports", ["embeds"] = {embed}})
    if http_request then
        pcall(function()
            http_request({
                Url     = _G.WebhookURL,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = payload
            })
        end)
    end
end

-- ── Black screen ──────────────────────────────────────────────────────────────
local BlackScreen = Instance.new("ScreenGui")
local Frame       = Instance.new("Frame")
if gethui then
    BlackScreen.Parent = gethui()
else
    BlackScreen.Parent = game:GetService("CoreGui") or LP.PlayerGui
end
BlackScreen.Name         = generateRandomName()
Frame.Name               = generateRandomName()
BlackScreen.DisplayOrder = -1
BlackScreen.Enabled      = false
Frame.Parent             = BlackScreen
Frame.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
Frame.Size               = UDim2.new(1.5, 0, 1.5, 0)
Frame.Position           = UDim2.new(-0.25, 0, -0.25, 0)
Frame.BorderSizePixel    = 0

Frame:GetPropertyChangedSignal("Size"):Connect(function()
    if Frame.Size ~= UDim2.new(1.5, 0, 1.5, 0) then Frame.Size = UDim2.new(1.5, 0, 1.5, 0) end
end)
Frame:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
    if Frame.BackgroundTransparency ~= 0 then Frame.BackgroundTransparency = 0 end
end)
Frame:GetPropertyChangedSignal("Visible"):Connect(function()
    if Frame.Visible == false and _G.PermanentBlackscreen then Frame.Visible = true end
end)

local function updateBlackScreen()
    local isAnyFarmActive = (_G.AutofarmCourier or _G.AutoFarmBarista or _G.AutoPoliceEnabled or _G.AutoDriveActive or _G.RideGOEnabled)
    _syncFarmTimer()
    if isAnyFarmActive then
        _G.blackscreen          = true
        _G.PermanentBlackscreen = true
    else
        _G.blackscreen = false
        if _G.PermanentBlackscreen then BlackScreen.Enabled = true end
        return
    end
    BlackScreen.Enabled = _G.blackscreen
end

-- ── Money tracker ─────────────────────────────────────────────────────────────
PlayerData.RPValue.Changed:Connect(function(newMoney)
    if newMoney > lastMoney then
        local gained = newMoney - lastMoney
        pendingIncome   = pendingIncome + gained
        _G.TotalEarning = _G.TotalEarning + gained
        if _G.AutofarmCourier      then _G.CourierEarned    = _G.CourierEarned    + gained
        elseif _G.AutoFarmBarista  then _G.BaristaEarned    = _G.BaristaEarned    + gained
        elseif _G.AutoPoliceEnabled then _G.PoliceEarned    = _G.PoliceEarned     + gained
        elseif _G.AutoDriveActive  then _G.AutoDriveEarned  = _G.AutoDriveEarned  + gained
        elseif _G.RideGOEnabled    then _G.RideGOEarned     = _G.RideGOEarned     + gained
        end
        if not isRunning then
            isRunning = true
            task.spawn(function()
                while isRunning do
                    task.wait(60)
                    if pendingIncome > 0 and _G.WebhookURL ~= "" then
                        sendWebhook(pendingIncome, 0)
                        pendingIncome = 0
                    end
                    if not _G.AutofarmCourier and not _G.AutoFarmBarista
                    and not _G.AutoPoliceEnabled and not _G.AutoDriveActive
                    and not _G.RideGOEnabled then isRunning = false end
                end
            end)
        end
    end
    lastMoney = newMoney
end)

-- ── Rejoin ────────────────────────────────────────────────────────────────────
local function RejoinServer()
    local queue_teleport = queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
    _G.AutofarmCourier   = false
    _G.AutoFarmBarista   = false
    _G.AutoPoliceEnabled = false
    _G.AutoDriveActive   = false
    if _G.RIDEGO_STOP then pcall(_G.RIDEGO_STOP) end
    _G.RideGOEnabled     = false
    _syncFarmTimer()
    task.wait(5)
    if queue_teleport then
        queue_teleport([[
            if not game:IsLoaded() then game.Loaded:Wait() end
            task.wait(4)
            pcall(function()
                loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/adonis.lua"
                ))()
            end)
            task.wait(2)
            pcall(function()
                loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/doc.lua"
                ))()
            end)
        ]])
    end
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LP)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end
    end)
end

task.spawn(function()
    task.wait(10)
    while task.wait(2) do
        if not _G.RejoinTriggered and _G.CourierEarned >= 79000000 then
            _G.RejoinTriggered = true
            task.wait(1)
            RejoinServer()
            break
        end
    end
end)

-- ── Anti-idle ─────────────────────────────────────────────────────────────────
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

pcall(function()
    local getconnections = getconnections or get_signal_cons
    if getconnections then
        for _, conn in ipairs(getconnections(LP.Idled)) do
            if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
        end
    end
end)

local idledConn = LP.Idled:Connect(function()
    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.2)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)
table.insert(ActiveConnections, idledConn)

-- ── Anti-cheat hooks ──────────────────────────────────────────────────────────
local d = false
local h = {}
local x, y
setthreadidentity(2)
for i, v in getgc(true) do
    if typeof(v) == "table" then
        local a = rawget(v, "Detected")
        local b = rawget(v, "Kill")
        if typeof(a) == "function" and not x then
            x = a
            local o; o = hookfunction(x, function(c, f, n) return true end)
            table.insert(h, x)
        end
        if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
            y = b
            local o; o = hookfunction(y, function(f) end)
            table.insert(h, y)
        end
    end
end
local o; o = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local a, f = ...
    if x and a == x then return coroutine.yield(coroutine.running()) end
    return o(...)
end))
setthreadidentity(7)

-- ============================================================================
-- COURIER AUTOFARM
-- ============================================================================

local function SwitchToCourier()
    local TeamRemote = ReplicatedStorage:FindFirstChild("TeamChangeRequest", true)
    if TeamRemote then
        if not LP.Team or LP.Team.Name ~= "Courier" then
            TeamRemote:FireServer("Courier", 11378976, 0, 0, "Detector")
            task.wait(1.5)
        end
    end
end

local function Tween(targetCFrame, keepSit)
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum  = Char and Char:FindFirstChild("Humanoid")
    if not Root or not Hum then return end
    Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Hum.Sit = true
    task.wait(0.25)
    local gyro        = Instance.new("BodyGyro")
    gyro.MaxTorque    = Vector3.new(1e6, 1e6, 1e6)
    gyro.P            = 1e5
    gyro.D            = 500
    gyro.CFrame       = targetCFrame
    gyro.Parent       = Root
    local distance    = (Root.Position - targetCFrame.Position).Magnitude
    local tripSpeed   = rngSpeed(_G.CourierSpeedMin, _G.CourierSpeedMax)
    local duration    = distance / tripSpeed
    Root.Velocity     = Vector3.new(0, 0, 0)
    Root.RotVelocity  = Vector3.new(0, 0, 0)
    local info  = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Root, info, {CFrame = targetCFrame})
    tween:Play()
    local conn = RunService.Stepped:Connect(function()
        if tween.PlaybackState == Enum.PlaybackState.Playing then
            Root.Velocity = Vector3.new(0, 0, 0)
            gyro.CFrame   = targetCFrame
        else conn:Disconnect() end
    end)
    tween.Completed:Wait()
    conn:Disconnect()
    Root.Velocity = Vector3.new(0, 0, 0)
    gyro:Destroy()
    if not keepSit then
        Hum.Sit = false
        Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        task.wait(0.15)
        Hum.Jump = true
        task.wait(0.1)
    end
end

local function AutoEquipBox()
    local Char = LP.Character
    if not Char or not Char:FindFirstChild("Humanoid") then return false end
    local held = Char:FindFirstChildOfClass("Tool")
    if held and held.Name:lower() == "box" then return true end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, item in pairs(bp:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower() == "box" then
                Char.Humanoid:EquipTool(item)
                return true
            end
        end
    end
    return false
end

local function GetActivePoint()
    for _, folder in ipairs(CourierSettings.Folder.Location:GetChildren()) do
        local block  = folder:FindFirstChild("Block")
        local prompt = block and block:FindFirstChildOfClass("ProximityPrompt")
        if prompt and (prompt.Enabled or folder:FindFirstChild("POINT").billboardgui.Enabled) then
            return block, prompt
        end
    end
    return nil, nil
end

task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutofarmCourier then
            SwitchToCourier()
            local Char = LP.Character or LP.CharacterAdded:Wait()
            local Hum  = Char:WaitForChild("Humanoid")
            local Root = Char:WaitForChild("HumanoidRootPart")
            if not (Hum and Root and Hum.Health > 0) then continue end
            local BoxTempatAmbil = workspace:FindFirstChild("Livrason")
                                   and workspace.Livrason:FindFirstChild("Take1")
            local TargetBlock, TargetPrompt = GetActivePoint()
            if not BoxTempatAmbil or (AutoEquipBox() and not TargetBlock) then
                task.wait(2) continue
            end
            if not AutoEquipBox() then
                if not WaktuKosong then WaktuKosong = os.clock() end
                if (os.clock() - WaktuKosong) >= 240 then
                    game:GetService("ReplicatedStorage")
                        :WaitForChild("JobEvents")
                        :WaitForChild("TeamChangeRequest")
                        :FireServer("Civilian", 0, 0, 0, "Detector")
                    WaktuKosong = nil
                    repeat task.wait(1)
                    until (LP.Team and LP.Team.Name == "Civilian") or not _G.AutofarmCourier
                    task.wait(15)
                    continue
                end
                Tween(TAKE_BOX_CFRAME, false)
                task.wait(0.4)
                if _G.AutofarmCourier and TAKE_PROMPT.Enabled then
                    fireproximityprompt(TAKE_PROMPT)
                    task.wait(1.5)
                end
            else
                WaktuKosong = nil
                if TargetBlock and TargetPrompt then
                    task.wait(math.random(0, 1))
                    Tween(TargetBlock.CFrame * CFrame.new(0, 2, 0), false)
                    task.wait(0.3)
                    AutoEquipBox()
                    if _G.AutofarmCourier and TargetPrompt.Enabled then
                        fireproximityprompt(TargetPrompt)
                        task.wait(0.5)
                        if Hum and _G.AutofarmCourier then
                            Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                            Hum.Sit = true
                        end
                        task.wait(3)
                    end
                end
            end
        else
            WaktuKosong = nil
        end
    end
end)

-- ============================================================================
-- BARISTA AUTOFARM
-- ============================================================================

local function GetBaristaElements()
    local Gui = LP.PlayerGui:FindFirstChild("BaristaGUI")
    if Gui then
        local OrderText = Gui:FindFirstChild("StatusFrame") and Gui.StatusFrame:FindFirstChild("OrderText")
        local Minigame  = Gui:FindFirstChild("MinigameFrame")
        return Gui, OrderText, Minigame
    end
    return nil, nil, nil
end

local function GetRemote(name)
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    return nil
end

local function BypassTP(targetCF)
    local Char = LP.Character or LP.CharacterAdded:Wait()
    local Hum  = Char:WaitForChild("Humanoid")
    local Root = Char:WaitForChild("HumanoidRootPart")
    if Hum and Root then
        local distance  = (Root.Position - targetCF.Position).Magnitude
        local tripSpeed = rngSpeed(_G.BaristaSpeedMin, _G.BaristaSpeedMax)
        local duration  = distance / tripSpeed
        Hum.Sit = true
        task.wait(0.5)
        local info  = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(Root, info, {CFrame = targetCF})
        tween:Play()
        tween.Completed:Wait()
        task.wait(0.3)
        Hum.Sit = false
    end
end

local function ExecuteStartSequence()
    local tr = GetRemote("TeamChangeRequest")
    if LP.Team and LP.Team.Name ~= "Barista" and tr then
        tr:FireServer("Barista", 11378976, 0, 0, "Detector")
        task.wait(2.5)
    end
    BypassTP(StartJobCF)
    task.wait(0.8)
    if JobPrompt and JobPrompt.Enabled then
        fireproximityprompt(JobPrompt)
    end
    LastActivity = tick()
end

task.spawn(function()
    while task.wait(0.6) do
        if _G.AutoFarmBarista then
            local _, OrderTextLabel, MinigameFrame = GetBaristaElements()
            if tick() - LastActivity >= 240 then ExecuteStartSequence() end
            if OrderTextLabel then
                local txt      = OrderTextLabel.Text:lower()
                local isBroken = (OrderTextLabel.TextColor3.R > 0.8 and (txt:find("break") or txt:find("down")))
                if isBroken then
                    BypassTP(SupplyCF)
                    task.wait(0.5)
                    fireproximityprompt(SupplyPrompt)
                    LastActivity = tick()
                    task.wait(0.5)
                    BypassTP(MachineCF)
                    fireproximityprompt(MachinePrompt)
                elseif MachinePrompt.Enabled and not (MinigameFrame and MinigameFrame.Visible) then
                    BypassTP(MachineCF)
                    fireproximityprompt(MachinePrompt)
                    LastActivity = tick()
                    repeat task.wait(0.5) LastActivity = tick()
                    until not (MinigameFrame and MinigameFrame.Visible) or not _G.AutoFarmBarista
                elseif RegisterPrompt.Enabled and not (MinigameFrame and MinigameFrame.Visible) then
                    task.wait(0.5)
                    BypassTP(RegisterCF)
                    task.wait(0.5)
                    fireproximityprompt(RegisterPrompt)
                    LastActivity = tick()
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local _, _, MinigameFrame = GetBaristaElements()
    if _G.AutoFarmBarista and MinigameFrame and MinigameFrame.Visible then
        local tz = MinigameFrame:FindFirstChild("TargetZone", true)
        if tz then tz.Size = UDim2.new(1, 0, 1, 0); tz.Position = UDim2.new(0, 0, 0, 0) end
    end
end)

-- ============================================================================
-- POLICE AUTOFARM
-- ============================================================================

local function getPoliceUI()
    local pGui = LP:FindFirstChild("PlayerGui")
    return pGui and pGui:FindFirstChild("PoliceUI")
end

local function GetLocationLabelText()
    local ui    = getPoliceUI()
    local label = ui and ui:FindFirstChild("LocationLabel", true)
    return label and label.Text
end

local function WaitUntilAssigned()
    while _G.AutoPoliceEnabled and GetLocationLabelText() == "Awaiting assignment..." do task.wait(0.5) end
end

local function GetObjectiveProgress()
    local ui    = getPoliceUI()
    local label = ui and ui:FindFirstChild("ObjectiveLabel", true)
    if label and label.Text then
        local text = label.Text:gsub("%s+", "")
        if text == "" then return "empty", nil end
        local current, target = label.Text:match("(%d+)/(%d+)")
        if current and target then return tonumber(current), tonumber(target) end
    end
    return nil, nil
end

local function GetObjectiveDetailedProgress()
    local ui    = getPoliceUI()
    local label = ui and ui:FindFirstChild("ObjectiveLabel", true)
    if label and label.Text then
        local text = label.Text:lower()
        if text:gsub("%s+", "") == "" then return nil, nil, nil, nil end
        local currentLines, targetLines = text:match("(%d+)/(%d+)%s+police%s+line")
        local currentCones, targetCones = text:match("(%d+)/(%d+)%s+cone")
        if not currentLines and not currentCones then
            local cur, tar = text:match("(%d+)/(%d+)")
            if cur and tar then
                if text:find("cone") then currentCones, targetCones = cur, tar else currentLines, targetLines = cur, tar end
            end
        end
        return tonumber(currentLines), tonumber(targetLines), tonumber(currentCones), tonumber(targetCones)
    end
    return nil, nil, nil, nil
end

local function UnanchorAll()
    for _, part in ipairs(AnchoredPartsList) do
        if part and part.Parent then pcall(function() part.Anchored = false end) end
    end
    table.clear(AnchoredPartsList)
    local Character = LP.Character
    if Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.Anchored = false end) end
        end
    end
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        pcall(function()
            local seat = Humanoid.SeatPart
            if seat then local weld = seat:FindFirstChild("SeatWeld") if weld then weld:Destroy() end end
            Humanoid.Sit = false
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            task.wait(0.15)
            Humanoid.Jump = true
            local HRP = Character:FindFirstChild("HumanoidRootPart")
            if HRP then HRP.CFrame = HRP.CFrame + Vector3.new(0, 0.5, 0) end
        end)
    end
end

local function SafePoliceTeleport(targetCFrame, bypassChecks, preventUnsit, skipSit)
    if not bypassChecks and not _G.AutoPoliceEnabled then return end
    local Character = LP.Character
    local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
    local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end
    TeleportActive = true
    pcall(function()
        local isDriving  = (Humanoid.SeatPart ~= nil and Humanoid.SeatPart:IsA("VehicleSeat"))
        local destCFrame = targetCFrame + (isDriving and Vector3.new(0, 10, 0) or Vector3.new(0, 1.5, 0))
        local mainPart, vehicle = HRP, nil
        if isDriving then
            local seat = Humanoid.SeatPart
            vehicle    = seat:FindFirstAncestorOfClass("Model")
            mainPart   = (vehicle and vehicle.PrimaryPart) or seat
        else
            local distance = (destCFrame.Position - HRP.Position).Magnitude
            if distance > 80 then skipSit = false end
            if Humanoid.SeatPart then
                pcall(function()
                    local seat = Humanoid.SeatPart
                    local weld = seat:FindFirstChild("SeatWeld")
                    if weld then weld:Destroy() end
                    Humanoid.Sit = false
                    task.wait(0.1)
                end)
            end
            if not skipSit then
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                if not Humanoid.Sit then
                    local attempts = 0
                    while not Humanoid.Sit and _G.AutoPoliceEnabled and attempts < 3 do
                        Humanoid.Sit = true
                        task.wait(0.2)
                        attempts = attempts + 1
                    end
                    task.wait(0.2)
                end
            end
        end
        if Character then
            for _, part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then pcall(function() part.Anchored = false end) end
            end
        end
        local currentPos = mainPart.Position
        local targetPos  = destCFrame.Position
        local distance   = (targetPos - currentPos).Magnitude
        local speedConf  = AutoPoliceConfig.TeleportSpeed
        local speed      = speedConf.min + math.random() * (speedConf.max - speedConf.min)
        local duration   = distance / speed
        if duration > 0 then
            if isDriving then
                if vehicle then
                    for _, p in ipairs(vehicle:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = false end end
                end
                mainPart.Velocity, mainPart.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
                local tween = TweenService:Create(mainPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = destCFrame})
                local connection; connection = RunService.Stepped:Connect(function()
                    if tween.PlaybackState == Enum.PlaybackState.Playing then
                        pcall(function()
                            mainPart.Velocity, mainPart.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
                            if vehicle and vehicle.PrimaryPart then
                                vehicle.PrimaryPart.Velocity = Vector3.new(0,0,0)
                                vehicle.PrimaryPart.RotVelocity = Vector3.new(0,0,0)
                            end
                        end)
                    else if connection then connection:Disconnect() end end
                end)
                tween:Play()
                tween.Completed:Wait()
                if connection then connection:Disconnect() end
            else
                local gyro        = Instance.new("BodyGyro")
                gyro.MaxTorque    = Vector3.new(1e6, 1e6, 1e6)
                gyro.P            = 1e5
                gyro.D            = 500
                gyro.CFrame       = destCFrame
                gyro.Parent       = HRP
                HRP.Anchored = false
                local startTime = os.clock()
                while os.clock() - startTime < duration do
                    if not _G.AutoPoliceEnabled then break end
                    local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
                    pcall(function()
                        HRP.Velocity, HRP.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
                        HRP.CFrame  = CFrame.new(currentPos:Lerp(targetPos, alpha)) * destCFrame.Rotation
                        gyro.CFrame = destCFrame
                    end)
                    RunService.Heartbeat:Wait()
                end
                pcall(function() HRP.CFrame = destCFrame end)
                gyro:Destroy()
            end
            mainPart.Velocity, mainPart.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
        else
            if isDriving then
                if vehicle then vehicle:PivotTo(destCFrame) else mainPart.CFrame = destCFrame end
            else
                Character:PivotTo(destCFrame)
            end
        end
        if not preventUnsit then
            if not isDriving and Humanoid then
                Humanoid.Sit = false
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            end
            UnanchorAll()
        end
        local postWait = AutoPoliceConfig.PostTeleportWait
        if postWait and not skipSit then task.wait(math.random(postWait.min, postWait.max)) end
    end)
    TeleportActive = false
end

local function FindMissionPart(missionModel)
    local part = missionModel:FindFirstChild("Part")
    if not part then
        for _, desc in ipairs(missionModel:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name ~= "Batas" then part = desc break end
        end
    end
    return part
end

local function GetPrompt(missionModel, targetPart)
    local prompt = targetPart and (targetPart:FindFirstChildOfClass("ProximityPrompt") or targetPart:FindFirstChild("ProximityPrompt", true))
    return prompt or missionModel:FindFirstChildOfClass("ProximityPrompt") or missionModel:FindFirstChild("ProximityPrompt", true)
end

local function DisableToolScripts(tool)
    if not tool then return end
    pcall(function()
        local handler = tool:FindFirstChild("PlacementHandler")
        if handler then handler.Disabled = true; handler:Destroy() end
    end)
end

local function EquipToolByName(toolName)
    local Character = LP.Character
    local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return false end
    if Humanoid.Sit or Humanoid.SeatPart then
        pcall(function()
            local seat = Humanoid.SeatPart
            if seat then local weld = seat:FindFirstChild("SeatWeld") if weld then weld:Destroy() end end
            Humanoid.Sit = false
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            task.wait(0.15)
            Humanoid.Jump = true
        end)
        task.wait(0.8)
    end
    local equippedTool = Character:FindFirstChild(toolName)
    if equippedTool then DisableToolScripts(equippedTool) return true end
    local tool = LP.Backpack:FindFirstChild(toolName)
    if tool then
        DisableToolScripts(tool)
        pcall(function() tool.Parent = Character end)
        task.wait(0.5)
        return true
    end
    return false
end

local function FirePrompt(prompt, targetPart)
    if not prompt or not prompt.Enabled then return false end
    pcall(function()
        prompt.RequiresLineOfSight = false
        if prompt.MaxActivationDistance < 100 then prompt.MaxActivationDistance = 100 end
    end)
    local Character = LP.Character
    local HRP    = Character and Character:FindFirstChild("HumanoidRootPart")
    local target = targetPart or prompt.Parent
    for attempt = 1, 3 do
        if not _G.AutoPoliceEnabled then break end
        if not prompt or not prompt.Parent or not prompt.Enabled then return true end
        if HRP and target and target:IsA("BasePart") then
            pcall(function()
                HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(target.Position.X, HRP.Position.Y, target.Position.Z))
                local cam  = Workspace.CurrentCamera
                if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position) end
            end)
            task.wait(0.2)
        end
        local triggered = false
        if fireproximityprompt then
            local success = pcall(function() fireproximityprompt(prompt) end)
            if success then
                task.wait(0.5)
                if not prompt or not prompt.Parent or not prompt.Enabled then triggered = true; break end
            end
        end
        if not triggered and prompt and prompt.Parent and prompt.Enabled then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.3)
                prompt:InputHoldEnd()
            end)
            task.wait(0.5)
            if not prompt or not prompt.Parent or not prompt.Enabled then triggered = true; break end
        end
    end
    return not (prompt and prompt.Parent and prompt.Enabled)
end

local function RequestPoliceJob()
    local ui        = getPoliceUI()
    local container = ui and ui:FindFirstChild("Container")
    if container and container.Visible then return end
    RequestingJob = true
    pcall(function()
        local isAlreadyPolice = (LP.Team and LP.Team.Name == "Police")
        if not isAlreadyPolice then
            local JobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
            local Event     = JobEvents and JobEvents:WaitForChild("TeamChangeRequest", 10)
            if Event then Event:FireServer("Police", 0, 0, 1428858969, "Detector") task.wait(2) end
        end
        local Character = LP.Character
        while not Character or not Character.Parent or not Character:FindFirstChildOfClass("Humanoid")
            or Character:FindFirstChildOfClass("Humanoid").Health <= 0 do
            if not _G.AutoPoliceEnabled then break end
            task.wait(0.25)
            Character = LP.Character
        end
        NeedJobRefresh = false
        if Character then
            local HRP = Character:WaitForChild("HumanoidRootPart", 10)
            if HRP then
                SafePoliceTeleport(CFrame.new(2839.58398, 3.48455882, -838.377747, 0.999973476, -2.63135558e-08, 0.00728388596, 2.71063172e-08, 1, -1.08738945e-07, -0.00728388596, 1.08933499e-07, 0.999973476))
                UnanchorAll()
                task.wait(1.5)
                local PoliceJob = Workspace:WaitForChild("PoliceJob", 10)
                local Start     = PoliceJob and PoliceJob:WaitForChild("Start", 10)
                local TOMBOL    = Start and Start:WaitForChild("ProximityPrompt", 10)
                if TOMBOL then
                    task.wait(1)
                    if fireproximityprompt then
                        pcall(function() fireproximityprompt(TOMBOL) end)
                    else
                        pcall(function()
                            TOMBOL:InputHoldBegin()
                            task.wait(TOMBOL.HoldDuration + 0.1)
                            TOMBOL:InputHoldEnd()
                        end)
                    end
                    task.wait(1)
                end
            end
        end
    end)
    RequestingJob = false
end

local function GetRandomPointInPart(part)
    local size = part.Size
    return part.Position + Vector3.new(
        (math.random() - 0.5) * (size.X * 0.8),
        size.Y / 2,
        (math.random() - 0.5) * (size.Z * 0.8)
    )
end

local function GetConePlacementZones(missionModel)
    local zones = {}
    for _, desc in ipairs(missionModel:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name:find("ConePlacementZone") then table.insert(zones, desc) end
    end
    return zones
end

local function PlaceConeAtZone(zonePart)
    local Character = LP.Character
    local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return false end
    local targetPos = GetRandomPointInPart(zonePart)
    SafePoliceTeleport(CFrame.new(targetPos + Vector3.new(0, 1.5, 0)), nil, false, true)
    if not _G.AutoPoliceEnabled then return false end
    local tool = LP.Backpack:FindFirstChild("TrafficCone") or Character:FindFirstChild("TrafficCone")
    if tool then
        DisableToolScripts(tool)
        local initialCount = GetObjectiveProgress() or 0
        EquipToolByName("TrafficCone")
        pcall(function()
            HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(zonePart.Position.X, zonePart.Position.Y, zonePart.Position.Z))
            local cam  = Workspace.CurrentCamera
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, zonePart.Position) end
        end)
        task.wait(0.2)
        local remote = tool:FindFirstChild("PlaceConeEvent") or tool:FindFirstChildOfClass("RemoteEvent")
        if remote then pcall(function() remote:FireServer(targetPos, HRP.CFrame) end) end
        task.wait(0.3)
        local startPlaceTime, success = os.clock(), false
        while os.clock() - startPlaceTime < 3 do
            local currentCount, targetCount = GetObjectiveProgress()
            if currentCount == "empty" or (tonumber(currentCount) or 0) > initialCount then success = true break end
            task.wait(0.15)
        end
        if not success then
            pcall(function() tool:Activate() end)
            task.wait(1)
            if (GetObjectiveProgress() or 0) > initialCount then success = true end
        end
        return success or (GetObjectiveProgress() and true or false)
    end
    return false
end

local function GetLinePlacementZones(missionModel)
    local zones = {}
    for _, desc in ipairs(missionModel:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name:find("LinePlacementZone") then table.insert(zones, desc) end
    end
    return zones
end

local function PlaceLineAtZone(zonePart)
    local Character = LP.Character
    local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return false end
    local targetPos = GetRandomPointInPart(zonePart)
    SafePoliceTeleport(CFrame.new(targetPos + Vector3.new(0, 1.5, 0)), nil, false, true)
    if not _G.AutoPoliceEnabled then return false end
    local tool = LP.Backpack:FindFirstChild("PoliceLine") or Character:FindFirstChild("PoliceLine")
    if tool then
        DisableToolScripts(tool)
        local initialLines = GetObjectiveDetailedProgress()
        local initialCount = initialLines or 0
        EquipToolByName("PoliceLine")
        pcall(function()
            HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(zonePart.Position.X, zonePart.Position.Y, zonePart.Position.Z))
            local cam  = Workspace.CurrentCamera
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, zonePart.Position) end
        end)
        task.wait(0.2)
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then pcall(function() remote:FireServer(targetPos, HRP.CFrame) end) end
        task.wait(0.3)
        local startPlaceTime, success = os.clock(), false
        while os.clock() - startPlaceTime < 3 do
            local currentLines = GetObjectiveDetailedProgress()
            if not currentLines or currentLines > initialCount then success = true break end
            task.wait(0.15)
        end
        if not success then
            pcall(function() tool:Activate() end)
            task.wait(1)
            local finalLines = GetObjectiveDetailedProgress()
            if finalLines and finalLines > initialCount then success = true end
        end
        return success
    end
    return false
end

local function GetSuspectHP()
    local ui    = getPoliceUI()
    local label = ui and ui:FindFirstChild("ObjectiveLabel", true)
    if label and label.Text then
        local text = label.Text:lower()
        local currentHP, maxHP = text:match("suspect%s*%(%s*(%d+)%s*/%s*(%d+)%s*hp%)")
        if currentHP and maxHP then return tonumber(currentHP), tonumber(maxHP) end
    end
    return nil, nil
end

local function NeutralizeSuspect(missionModel, suspect)
    local Character = LP.Character
    local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local suspectHRP = suspect:FindFirstChild("HumanoidRootPart") or suspect.PrimaryPart or suspect:FindFirstChild("Head") or suspect:FindFirstChildOfClass("Part")
    EquipToolByName("Baton")
    local lastHitTime   = 0
    local lastEquipTime = 0
    while _G.AutoPoliceEnabled and missionModel.Parent and suspect.Parent do
        local curHP, maxHP = GetSuspectHP()
        Character = LP.Character
        HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
        if not HRP then task.wait(0.5) continue end
        local tool = Character:FindFirstChild("Baton")
        if not tool then
            if os.clock() - lastEquipTime > 2 then EquipToolByName("Baton") lastEquipTime = os.clock() end
            tool = Character:FindFirstChild("Baton") or LP.Backpack:FindFirstChild("Baton")
        end
        local suspectPos  = suspectHRP.Position
        local suspectLook = suspectHRP.CFrame.LookVector
        local targetPos   = suspectPos + suspectLook * 2.5
        pcall(function()
            HRP.Velocity = Vector3.new(0, 0, 0)
            HRP.CFrame   = CFrame.new(targetPos, suspectPos)
        end)
        if tool and tool.Parent == Character then
            if os.clock() - lastHitTime > 0.2 then
                pcall(function() tool:Activate() end)
                lastHitTime = os.clock()
            end
        end
        task.wait(0.05)
    end
    pcall(function()
        local Character = LP.Character
        local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then Humanoid:UnequipTools() end
    end)
end

local function setupCharacterDied(char)
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
    if humanoid then
        local diedConn; diedConn = humanoid.Died:Connect(function()
            NeedJobRefresh = true
            if diedConn then diedConn:Disconnect() end
        end)
        table.insert(ActiveConnections, diedConn)
    end
end

if LP.Character then setupCharacterDied(LP.Character) end
table.insert(ActiveConnections, LP.CharacterAdded:Connect(function(char)
    setupCharacterDied(char)
    if _G.AutoPoliceEnabled and NeedJobRefresh and not RequestingJob then
        NeedJobRefresh = false
        task.wait(3)
        RequestPoliceJob()
    end
end))

task.spawn(function()
    while true do
        if _G.AutoPoliceEnabled then
            if RequestingJob or NeedJobRefresh then task.wait(0.5) continue end
            local Character = LP.Character
            local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
            local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
            if not Character or not Humanoid or not HRP or Humanoid.Health <= 0 then
                task.wait(0.5) continue
            end
            local missionModel = nil
            for _, child in ipairs(ActiveMissions:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") then missionModel = child break end
            end
            if missionModel then
                task.wait(2.5)
                if _G.AutoPoliceEnabled and missionModel.Parent then
                    pcall(function()
                        for _, desc in ipairs(missionModel:GetDescendants()) do
                            if desc:IsA("MeshPart") then desc.CanCollide = false end
                        end
                    end)
                    local targetPart = FindMissionPart(missionModel)
                    local prompt     = GetPrompt(missionModel, targetPart)
                    if prompt then
                        if targetPart then
                            SafePoliceTeleport(CFrame.new(targetPart.Position + Vector3.new(0, 1.5, 0)), nil, false)
                            if not _G.AutoPoliceEnabled then break end
                            task.wait(0.5)
                            EquipToolByName("BukuTilang")
                            FirePrompt(prompt, targetPart)
                            local startWait = os.clock()
                            while prompt and prompt.Parent and prompt.Enabled
                                and missionModel.Parent == ActiveMissions
                                and _G.AutoPoliceEnabled do
                                if os.clock() - startWait > 10 then break end
                                task.wait(0.25)
                            end
                        end
                    else
                        local lineZones = GetLinePlacementZones(missionModel)
                        local coneZones = GetConePlacementZones(missionModel)
                        if #lineZones > 0 or #coneZones > 0 then
                            local emptyStreak = 0
                            while _G.AutoPoliceEnabled do
                                if not missionModel or not missionModel.Parent then break end
                                local currentLines, targetLines, currentCones, targetCones = GetObjectiveDetailedProgress()
                                local linesNeeded = targetLines and (currentLines < targetLines)
                                local conesNeeded = targetCones and (currentCones < targetCones)
                                local label = getPoliceUI() and getPoliceUI():FindFirstChild("ObjectiveLabel", true)
                                if not label or (label.Text or ""):gsub("%s+", "") == "" then break end
                                if not targetLines and not targetCones then
                                    local cur, tar = GetObjectiveProgress()
                                    if cur == "empty" then break
                                    elseif cur and tar then
                                        if cur >= tar then break end
                                        if #coneZones > 0 then conesNeeded = true else linesNeeded = true end
                                    else
                                        emptyStreak = emptyStreak + 1
                                        if emptyStreak > 5 then
                                            if #coneZones > 0 then conesNeeded = true else linesNeeded = true end
                                        else task.wait(1) continue end
                                    end
                                end
                                emptyStreak = 0
                                if not linesNeeded and not conesNeeded then break end
                                local success = false
                                if linesNeeded and #lineZones > 0 then
                                    local zonePart = lineZones[math.random(1, #lineZones)]
                                    if zonePart and zonePart.Parent and zonePart:IsDescendantOf(Workspace) then
                                        success = PlaceLineAtZone(zonePart)
                                    end
                                elseif conesNeeded and #coneZones > 0 then
                                    local zonePart = coneZones[math.random(1, #coneZones)]
                                    if zonePart and zonePart.Parent and zonePart:IsDescendantOf(Workspace) then
                                        success = PlaceConeAtZone(zonePart)
                                    end
                                else
                                    task.wait(1) success = true
                                end
                                if not success then task.wait(1) end
                            end
                            pcall(function()
                                local Character = LP.Character
                                local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
                                if Humanoid then Humanoid:UnequipTools() end
                            end)
                        end
                        local suspect = missionModel:FindFirstChild("Penjahat") or missionModel:WaitForChild("Penjahat", 2)
                        if suspect and _G.AutoPoliceEnabled then NeutralizeSuspect(missionModel, suspect) end
                        task.wait(math.random(3.5, 6))
                    end
                    while missionModel and missionModel.Parent == ActiveMissions and _G.AutoPoliceEnabled do task.wait(0.25) end
                    if _G.AutoPoliceEnabled then missionsCompleted = missionsCompleted + 1 task.wait(2) end
                    WaitUntilAssigned()
                end
            end
        end
        task.wait(AutoPoliceConfig.LoopDelay)
    end
end)

-- ============================================================================
-- RIDEGO AUTOFARM (v15f-clean · Road Graph, Hover-Step & Gap-Fly)
-- ============================================================================

local ATUR = {
    JEMPUT_JARAK          = 500,
    ANTAR_JARAK           = 200,
    JEMPUT_JEDA           = 0.25,
    ANTAR_JEDA            = 0.68,
    TERBANG_KECEPATAN     = 150,
    TERBANG_CELAH_MAKS    = 4500,
    TERBANG_MAKS_PER_JALAN = 1,
    TERBANG_JAUH_MIN      = 600,
    TERBANG_KETINGGIAN    = 350,
    BATAS_DIAM            = 50,
    SELECTED_BIKE         = "Yamahax-MioSporty",
}

do
    local function num(v, def)
        local n = tonumber(v)
        return n or def
    end
    ATUR.JEMPUT_JARAK           = math.clamp(num(ATUR.JEMPUT_JARAK, 150), 10, 500)
    ATUR.ANTAR_JARAK            = math.clamp(num(ATUR.ANTAR_JARAK, 90), 10, 250)
    ATUR.JEMPUT_JEDA            = math.clamp(num(ATUR.JEMPUT_JEDA, 0.25), 0.05, 5)
    ATUR.ANTAR_JEDA             = math.clamp(num(ATUR.ANTAR_JEDA, 0.68), 0.05, 5)
    ATUR.TERBANG_KECEPATAN      = math.clamp(num(ATUR.TERBANG_KECEPATAN, 150), 30, 400)
    ATUR.TERBANG_CELAH_MAKS     = math.clamp(num(ATUR.TERBANG_CELAH_MAKS, 4500), 60, 5000)
    ATUR.TERBANG_MAKS_PER_JALAN = math.floor(math.clamp(num(ATUR.TERBANG_MAKS_PER_JALAN, 1), 1, 5))
    ATUR.TERBANG_JAUH_MIN       = math.clamp(num(ATUR.TERBANG_JAUH_MIN, 600), 100, 3000)
    ATUR.TERBANG_KETINGGIAN     = math.clamp(num(ATUR.TERBANG_KETINGGIAN, 350), 50, 800)
    ATUR.BATAS_DIAM             = math.clamp(num(ATUR.BATAS_DIAM, 50), 15, 300)
end

local BUILD = "v15f-clean 2026-11-23"

local CFG = {
    AUTO_JOB       = true,
    AUTO_SPAWN     = true,
    AUTO_ACK       = true,
    MIN_FARE       = 0,
    ORDERS         = 0,
    HOP_FAIL_MAX   = 8,
    STALL_STEPS    = 14,
    FLY_SPEED      = ATUR.TERBANG_KECEPATAN,
    FLY_ARRIVE     = 4,
    FLY_MAX_TIME   = 40,
    FLY_MAX_GAP    = ATUR.TERBANG_CELAH_MAKS,
    FLY_MAX_CROSS  = ATUR.TERBANG_MAKS_PER_JALAN,
    FLY_LONG_MIN   = ATUR.TERBANG_JAUH_MIN,
    FLY_RISE       = ATUR.TERBANG_KETINGGIAN,
    ARRIVE_PICKUP  = 16,
    ARRIVE_DROP    = 16,
    GROUND_OFFSET  = 1.8,
    WALL_CLEAR     = 3.6,
    EDGE_MARGIN    = 30,
    OFFER_TIMEOUT  = 45,
    ACCEPT_TIMEOUT = 15,
    BOARD_WAIT     = 8,
    BOARD_ROUNDS   = 3,
    BOARD_BACKOFF  = 22,
    DROP_WAIT      = 30,
    DROP_ROUNDS    = 3,
    DROP_HOLD      = 40,
    TP_FAR         = 350,
    TRAIL_FILE     = "RideGO/trail_v1.json",
}

local rgS = {
    running = false,
    phase   = "standby",
    note    = "menunggu toggle",
    orders  = 0,
    lastTp  = 0,
    hops    = 0,
    hover   = false,
}

local nowT
do
    local ok, v = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(v) == "number" then
        nowT = function() return workspace:GetServerTimeNow() end
    else
        nowT = function() return os.clock() end
    end
end

local ATUR_LIMIT = {
    JEMPUT_JARAK      = { 10, 500 },
    ANTAR_JARAK       = { 10, 250 },
    JEMPUT_JEDA       = { 0.05, 5 },
    ANTAR_JEDA        = { 0.05, 5 },
    TERBANG_KECEPATAN = { 30, 400 },
    BATAS_DIAM        = { 15, 300 },
}

local function setAtur(key, value)
    local lim = ATUR_LIMIT[key]
    local n = tonumber(value)
    if not (lim and n) then return ATUR[key] end
    ATUR[key] = math.clamp(n, lim[1], lim[2])
    if key == "TERBANG_KECEPATAN" then
        CFG.FLY_SPEED = ATUR.TERBANG_KECEPATAN
    end
    return ATUR[key]
end

local function setRideGOAuto(on)
    rgS.running      = on and true or false
    _G.RideGOEnabled = rgS.running
    if rgS.running then
        rgS.phase = "mulai"
        rgS.note  = "auto dinyalakan"
    else
        rgS.phase = "standby"
        rgS.note  = "auto dimatikan"
        if _G.RIDEGO_UNLOCK then pcall(_G.RIDEGO_UNLOCK) end
    end
    updateBlackScreen()
end

_G.RIDEGO_INFO = function()
    return {
        build     = BUILD,
        running   = rgS.running,
        phase     = rgS.phase,
        note      = rgS.note,
        orders    = rgS.orders,
        hops      = rgS.hops,
        tripStuds = rgS.tripStuds,
        tripMoney = rgS.tripMoney,
        ping      = rgS.ping,
    }
end

_G.RIDEGO_STOP = function()
    setRideGOAuto(false)
    rgS.note = "dihentikan manual"
end

_G.RIDEGO_START = function()
    setRideGOAuto(true)
end

-- ── Owned vehicles fetcher (binds to WindUI Vehicle dropdown) ─────────────────
local rgOwnedVehicles = { "Yamahax-MioSporty" }

local function rgParseVehicleCandidate(item, outMap)
    if not item then return end
    if type(item) == "string" and #item > 1 then
        local low = item:lower()
        if not low:find("slot") and not low:find("frame")
           and not low:find("button") and not low:find("package") then
            outMap[item] = true
        end
    elseif type(item) == "table" then
        local n = item.Name or item.Car or item.CarName or item.Vehicle or item.Model
        if n and type(n) == "string" and #n > 1 then
            local low = n:lower()
            if not low:find("slot") and not low:find("frame") then outMap[n] = true end
        end
    end
end

local function rgFetchOwnedVehicles()
    local foundMap          = {}
    local DealershipEventsF = ReplicatedStorage:FindFirstChild("DealershipEvents")
    if DealershipEventsF then
        if DealershipEventsF:FindFirstChild("InitializeCarData") then
            pcall(function()
                local res = DealershipEventsF.InitializeCarData:InvokeServer()
                if type(res) == "table" then
                    for _, e in pairs(res) do rgParseVehicleCandidate(e, foundMap) end
                end
            end)
        end
        if DealershipEventsF:FindFirstChild("GetInfoCarSlot") then
            pcall(function()
                local r = DealershipEventsF.GetInfoCarSlot:InvokeServer()
                if type(r) == "table" then
                    for _, e in pairs(r) do rgParseVehicleCandidate(e, foundMap) end
                end
            end)
            for i = 1, 30 do
                pcall(function()
                    local r = DealershipEventsF.GetInfoCarSlot:InvokeServer(i)
                    if type(r) == "table" then rgParseVehicleCandidate(r, foundMap) end
                end)
            end
        end
    end
    pcall(function()
        if not getgc then return end
        for _, tbl in pairs(getgc(true)) do
            if type(tbl) == "table" and rawget(tbl, 1) and type(rawget(tbl, 1)) == "table" then
                local first = rawget(tbl, 1)
                if rawget(first, "Horsepower") and rawget(first, "Name") and rawget(first, "FinalDrive") then
                    for _, cd in ipairs(tbl) do
                        if type(cd) == "table" and cd.Name then foundMap[cd.Name] = true end
                    end
                end
            end
        end
    end)
    pcall(function()
        for _, fName in ipairs({"Data", "Cars", "Garage", "Vehicles", "OwnedCars"}) do
            local folder = LP:FindFirstChild(fName)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("StringValue") and #child.Value > 1 then
                        foundMap[child.Value] = true
                    elseif not child:IsA("Folder") then
                        foundMap[child.Name] = true
                    end
                end
            end
        end
    end)
    local unique = {}
    for carName, _ in pairs(foundMap) do
        if type(carName) == "string" and #carName > 1
           and carName ~= "None" and carName ~= "Empty" then
            table.insert(unique, carName)
        end
    end
    table.sort(unique)
    if #unique > 0 then
        rgOwnedVehicles = unique
        local found = false
        for _, n in ipairs(unique) do
            if n == ATUR.SELECTED_BIKE then found = true; break end
        end
        if not found then ATUR.SELECTED_BIKE = unique[1] end
    end
    return rgOwnedVehicles
end

-- ── Spatial & Physics helpers ─────────────────────────────────────────────────
local rgRayParams = RaycastParams.new()
rgRayParams.FilterType = Enum.RaycastFilterType.Exclude
rgRayParams.IgnoreWater = true

local rgWaterParams = RaycastParams.new()
rgWaterParams.FilterType = Enum.RaycastFilterType.Exclude
rgWaterParams.IgnoreWater = false

local function rayHit(origin, dir, len, ignore)
    rgRayParams.FilterDescendantsInstances = ignore or {}
    return Workspace:Raycast(origin, dir * len, rgRayParams)
end

local BAD_GROUND = {
    [Enum.Material.Water] = true,
}

local function rayGroundBelow(p, depth, bike)
    local ignore = { LP.Character }
    if bike then table.insert(ignore, bike) end
    return rayHit(Vector3.new(p.X, p.Y + 10, p.Z), Vector3.new(0, -1, 0), depth or 40, ignore)
end

local rgOverlapParams = OverlapParams.new()
rgOverlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function probeSize(bike)
    local _, size = bike:GetBoundingBox()
    return Vector3.new(math.max(size.X * 0.9, 3), math.max(size.Y * 0.75, 3), math.max(size.Z * 0.9, 3))
end

local function smallClearAt(pos, rot, bike)
    local size = probeSize(bike)
    local cf = CFrame.new(pos + Vector3.new(0, size.Y * 0.5 + 0.3, 0)) * rot
    rgOverlapParams.FilterDescendantsInstances = { bike, LP.Character }
    local parts = Workspace:GetPartBoundsInBox(cf, size, rgOverlapParams)
    for _, p in ipairs(parts) do
        if p:IsA("BasePart") and p.CanCollide and p.Size.Y >= 3 then
            local m = math.max(p.Size.X, p.Size.Y, p.Size.Z)
            if m < 40 then return false, p end
        end
    end
    return true
end

local function wallClearAt(pos, bike)
    local ignore = { bike, LP.Character }
    for _, h in ipairs({ 1.0, 2.2, 3.4 }) do
        local o = pos + Vector3.new(0, h, 0)
        for a = 0, 340, 20 do
            local rad = math.rad(a)
            local hit = rayHit(o, Vector3.new(math.cos(rad), 0, math.sin(rad)), CFG.WALL_CLEAR, ignore)
            if hit then return false, hit.Instance end
        end
    end
    return true
end

local function areaClearAt(pos, rot, bike)
    local ok, blk = smallClearAt(pos, rot, bike)
    if not ok then return false, blk end
    return wallClearAt(pos, bike)
end

local function uprightRot(pivot)
    local l = pivot.LookVector
    local flat = Vector3.new(l.X, 0, l.Z)
    if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
    return CFrame.lookAt(Vector3.zero, flat)
end

local function bikeSnapshot(bike)
    local snap = {}
    for _, d in ipairs(bike:GetDescendants()) do
        if d:IsA("BasePart") then snap[#snap + 1] = { p = d, a = d.Anchored, c = d.CanCollide } end
    end
    return snap
end

local function bikeRestore(snap)
    for _, s in ipairs(snap) do
        if s.p and s.p.Parent then
            pcall(function()
                s.p.CanCollide = s.c
                s.p.Anchored   = s.a
            end)
        end
    end
end

local function findSafeNear(p, maxR, bike, loose)
    maxR = maxR or 90
    local rot = uprightRot(bike:GetPivot())
    local ignore = { bike, LP.Character }
    for r = 6, maxR, 6 do
        for a = 0, 330, 30 do
            local rad = math.rad(a)
            local q = Vector3.new(p.X + math.cos(rad) * r, p.Y, p.Z + math.sin(rad) * r)
            local hit = rayGroundBelow(q, 40, bike)
            if not hit then
                local sky = rayHit(Vector3.new(q.X, p.Y + 500, q.Z), Vector3.new(0, -1, 0), 1000, ignore)
                if sky and math.abs(sky.Position.Y - p.Y) <= 15 then hit = sky end
            end
            if hit and not BAD_GROUND[hit.Material] and math.abs(hit.Position.Y - p.Y) <= (loose and 30 or 15) then
                local cand = Vector3.new(q.X, hit.Position.Y + 1.5, q.Z)
                local okUp = true
                if not loose then
                    okUp = not rayHit(hit.Position + Vector3.new(0, 2, 0), Vector3.new(0, 1, 0), 10, ignore)
                end
                if okUp and areaClearAt(cand, rot, bike) then return cand end
            end
        end
    end
    return nil
end

local function bikeSettle(bike, rot)
    local p0 = bike:GetPivot().Position
    if areaClearAt(p0, rot, bike) then return true end
    for r = 3, 18, 3 do
        for i = 0, 7 do
            local a = math.rad(i * 45)
            local q = p0 + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
            if areaClearAt(q, rot, bike) then
                pcall(function() bike:PivotTo(CFrame.new(q) * rot) end)
                return true
            end
        end
    end
    for _, lift in ipairs({ 4, 8, 12, 18, 26 }) do
        local q = p0 + Vector3.new(0, lift, 0)
        if areaClearAt(q, rot, bike) then
            pcall(function() bike:PivotTo(CFrame.new(q) * rot) end)
            return true
        end
    end
    return false
end

local ensurePassenger
local rgSafePos

local function bikeDriveSeat(bike) return bike and bike:FindFirstChild("DriveSeat", true) end

local function charFollowBike(bike)
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local seat = bikeDriveSeat(bike)
    if not (char and hum and seat) then return false end
    if seat.Occupant ~= hum then return false end
    return pcall(function() char:PivotTo(seat.CFrame) end)
end

local function bikeReseat(bike, tries)
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local seat = bikeDriveSeat(bike)
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hum and seat and hrp) then return false end

    local near = (hrp.Position - seat.Position).Magnitude < 10
    if seat.Occupant == hum and hum.SeatPart == seat and near then return true end

    if hum.SeatPart then
        pcall(function() hum.Sit = false end)
        task.wait(0.05)
    end
    pcall(function() char:PivotTo(seat.CFrame) end)
    task.wait(0.1)

    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true) end)
    if hum:GetState() == Enum.HumanoidStateType.Ragdoll then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    pcall(function() seat:Sit(hum) end)
    for _ = 1, (tries or 12) do
        task.wait(0.12)
        local r2 = char:FindFirstChild("HumanoidRootPart")
        if seat.Occupant == hum and r2 and (r2.Position - seat.Position).Magnitude < 10 then return true end
    end
    return false
end

local function bikeSnapGround(bike, rot)
    local p = bike:GetPivot().Position
    for _, h in ipairs({ 3, 40, 150, 400 }) do
        local hit = rayHit(p + Vector3.new(0, h, 0), Vector3.new(0, -1, 0), h + 250, { bike, LP.Character })
        if hit then
            local s = hit.Instance.Size
            if math.max(s.X, s.Y, s.Z) < 20000 and not BAD_GROUND[hit.Material] then
                local y = hit.Position.Y + CFG.GROUND_OFFSET
                pcall(function() bike:PivotTo(CFrame.new(Vector3.new(p.X, y, p.Z)) * rot) end)
                return true
            end
        end
    end
    return false
end

local noFallBike
local function fallScriptRemove()
    local pg    = LP:FindFirstChildOfClass("PlayerGui")
    local iface = pg and pg:FindFirstChild("Interface")
    local fs    = iface and iface:FindFirstChild("FallingScript")
    if fs and fs:IsA("LocalScript") and fs.Enabled then pcall(function() fs.Enabled = false end) end
end

local function fallGuardOn(bike)
    fallScriptRemove()
    if not (bike and bike.Parent) then return end
    if noFallBike == bike then return end
    noFallBike = bike
    local fs = bike:FindFirstChild("FallingScript", true)
    if fs and fs:IsA("LocalScript") then pcall(function() fs.Enabled = false end) end

    pcall(function()
        bike.DescendantAdded:Connect(function(d)
            if d.Name == "FallingScript" and d:IsA("LocalScript") then
                task.wait(0.1)
                pcall(function() d.Enabled = false end)
            end
        end)
    end)
end

local function bikeTeleport(bike, dest, label, blind, quick)
    if not (bike and bike.Parent and dest) then return false end
    local pivot = bike:GetPivot()
    if (dest - pivot.Position).Magnitude > CFG.TP_FAR then
        pcall(function() Workspace:RequestStreamAroundAsync(dest, 8) end)
    end
    local rot  = uprightRot(pivot)
    local snap = bikeSnapshot(bike)
    getgenv().RIDEGO_PENDING = { bike = bike, snap = snap, at = nowT() }

    for _, s in ipairs(snap) do
        s.p.CanCollide = false
    end

    local function pivotApply(cf)
        pcall(function() bike:PivotTo(cf) end)
        charFollowBike(bike)
    end
    pivotApply(CFrame.new(dest + Vector3.new(0, 4, 0)) * rot)
    task.wait(0.05)
    if blind then
        local landed = false
        local ignore = { bike, LP.Character }
        for _ = 1, (quick and 12 or 60) do
            local hit = rayHit(Vector3.new(dest.X, dest.Y + 4, dest.Z), Vector3.new(0, -1, 0), 700, ignore)
            if not hit then
                hit = rayHit(Vector3.new(dest.X, dest.Y + 90, dest.Z), Vector3.new(0, -1, 0), 400, ignore)
            end
            if hit and not BAD_GROUND[hit.Material] and hit.Position.Y <= dest.Y + 60 then
                local y = hit.Position.Y + CFG.GROUND_OFFSET
                pcall(function() bike:PivotTo(CFrame.new(Vector3.new(dest.X, y, dest.Z)) * rot) end)
                charFollowBike(bike)
                landed = true
                break
            end
            pcall(function() Workspace:RequestStreamAroundAsync(dest, 10) end)
            task.wait(0.25)
        end
        if not landed then
            pcall(function() bike:PivotTo(pivot) end)
            charFollowBike(bike)
            bikeRestore(snap)
            getgenv().RIDEGO_PENDING = nil
            bikeReseat(bike)
            return false
        end
    end
    bikeSettle(bike, rot)
    if not bikeSnapGround(bike, rot) then
        pcall(function() bike:PivotTo(pivot) end)
        charFollowBike(bike)
        bikeRestore(snap)
        getgenv().RIDEGO_PENDING = nil
        bikeReseat(bike)
        return false
    end
    charFollowBike(bike)

    task.wait(0.1)
    fallGuardOn(bike)
    bikeRestore(snap)
    getgenv().RIDEGO_PENDING = nil

    bikeReseat(bike)
    rgSafePos  = bike:GetPivot().Position
    rgS.hops   = rgS.hops + 1
    rgS.lastTp = nowT()
    return true
end

local function padFlat(pos, bike, rad)
    rad = rad or 6
    local ignore = { bike, LP.Character }
    local ok = 0
    local pts = { { 0, 0 }, { rad, 0 }, { -rad, 0 }, { 0, rad }, { 0, -rad } }
    for _, o in ipairs(pts) do
        local h = rayHit(Vector3.new(pos.X + o[1], pos.Y + 25, pos.Z + o[2]), Vector3.new(0, -1, 0), 60, ignore)
        if h and not BAD_GROUND[h.Material] and h.Normal.Y > 0.6 then ok = ok + 1 end
    end
    return ok >= 4
end

local function padExists(pos, bike) return padFlat(pos, bike, 6) or padFlat(pos, bike, 3) end

local function padFind(center, bike, maxR)
    maxR = maxR or 64
    local ignore = { bike, LP.Character }
    for r = 0, maxR, 8 do
        local n = (r == 0) and 1 or 8
        for i = 0, n - 1 do
            local a = (i / n) * math.pi * 2
            local q = center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
            local h = rayHit(Vector3.new(q.X, center.Y + 60, q.Z), Vector3.new(0, -1, 0), 260, ignore)
            if
                h
                and not BAD_GROUND[h.Material]
                and h.Normal.Y > 0.6
                and h.Position.Y > -80
                and padExists(Vector3.new(q.X, h.Position.Y, q.Z), bike)
            then
                return Vector3.new(q.X, h.Position.Y, q.Z)
            end
        end
    end
    return nil
end

local function hoverHold(cf)
    if rgS.holdPos and rgS.holdPos.Parent then rgS.holdPos.Position = cf.Position end
    if rgS.holdRot and rgS.holdRot.Parent then rgS.holdRot.CFrame   = cf end
end

local function hoverLock(bike)
    if rgS.hoverAnchored then return end
    local root = bike.PrimaryPart or bike:FindFirstChildWhichIsA("BasePart", true)
    if not root then return end
    local cf  = bike:GetPivot()
    local att = Instance.new("Attachment")
    att.Name   = "RideGO_Hold"
    att.Parent = root
    local ap = Instance.new("AlignPosition")
    ap.Name            = "RideGO_HoldPos"
    ap.Mode            = Enum.PositionAlignmentMode.OneAttachment
    ap.Attachment0     = att
    ap.Position        = cf.Position
    ap.RigidityEnabled = true
    ap.MaxForce        = 1e7
    ap.Responsiveness  = 200
    ap.Parent          = root
    local ao = Instance.new("AlignOrientation")
    ao.Name            = "RideGO_HoldRot"
    ao.Mode            = Enum.OrientationAlignmentMode.OneAttachment
    ao.Attachment0     = att
    ao.CFrame          = cf
    ao.RigidityEnabled = true
    ao.MaxTorque       = 1e7
    ao.Responsiveness  = 200
    ao.Parent          = root
    rgS.hoverBike     = bike
    rgS.hoverAtt      = att
    rgS.holdPos       = ap
    rgS.holdRot       = ao
    rgS.hoverAnchored = true
    pcall(function()
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function hoverUnlock(bike)
    if not rgS.hoverAnchored then return end
    rgS.hoverAnchored = false
    for _, k in ipairs({ "holdPos", "holdRot" }) do
        local c = rgS[k]
        if c then
            pcall(function() c:Destroy() end)
            rgS[k] = nil
        end
    end
    if rgS.hoverAtt then
        pcall(function() rgS.hoverAtt:Destroy() end)
        rgS.hoverAtt = nil
    end
    rgS.hoverBike = nil
end

_G.RIDEGO_UNLOCK = function()
    local b = rgS.hoverBike
    if b then hoverUnlock(b) end
end

local function bikeFlyTo(bike, destPos, speed, arriveDist, maxTime, gap)
    if not (bike and bike.Parent and destPos) then return false end
    local root = bike.PrimaryPart or bikeDriveSeat(bike) or bike:FindFirstChildWhichIsA("BasePart", true)
    if not root then return false end

    speed      = speed or CFG.FLY_SPEED
    arriveDist = arriveDist or CFG.FLY_ARRIVE
    maxTime    = maxTime or CFG.FLY_MAX_TIME

    pcall(function() Workspace:RequestStreamAroundAsync(destPos, 20) end)

    local startPos = bike:GetPivot().Position
    local destY    = destPos.Y or startPos.Y
    local long     = (gap or 0) >= CFG.FLY_LONG_MIN

    local cruiseY = math.max(startPos.Y, destY + 2)
    if long then cruiseY = cruiseY + CFG.FLY_RISE end
    local target = Vector3.new(destPos.X, cruiseY, destPos.Z)

    local char     = LP.Character
    local snap     = bikeSnapshot(bike)
    local charSnap = {}
    if char and char.Parent then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then charSnap[#charSnap + 1] = { p = d, c = d.CanCollide } end
        end
    end

    local bg = Instance.new("BodyGyro")
    bg.P         = 9e4
    bg.D         = 50
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.Parent    = root
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity  = Vector3.zero
    bv.Parent    = root

    getgenv().RIDEGO_FLY = true
    local function noclipOn()
        for _, s in ipairs(snap) do
            if s.p and s.p.Parent then s.p.CanCollide = false end
        end
        for _, s in ipairs(charSnap) do
            if s.p and s.p.Parent then s.p.CanCollide = false end
        end
    end

    local ok = pcall(function()
        local t0 = nowT()
        local function faceDir(px, pz)
            bg.CFrame = CFrame.lookAt(root.Position, Vector3.new(px, root.Position.Y, pz))
        end

        if long then
            local tRise = nowT()
            while rgS.running do
                if not (bike.Parent and root.Parent) then error("motor hilang saat naik") end
                noclipOn()
                local cur  = root.Position
                local need = cruiseY - cur.Y
                if need <= 6 or nowT() - tRise > 15 then break end
                bv.Velocity = Vector3.new(0, math.clamp(need * 2, 25, 140), 0)
                faceDir(target.X, target.Z)
                task.wait()
            end
        end

        while rgS.running do
            if not (bike.Parent and root.Parent) then error("motor hilang saat terbang") end
            noclipOn()
            local cur      = root.Position
            local flat     = Vector3.new(target.X - cur.X, 0, target.Z - cur.Z)
            local distance = flat.Magnitude
            if distance <= arriveDist then break end
            if nowT() - t0 > maxTime then error(string.format("terlalu lama (%.0f stud lagi)", distance)) end
            local dir     = flat.Unit
            local vy, spd = 0, speed
            if long and distance < 260 then
                vy  = math.clamp((destY + 2 - cur.Y) * 1.5, -150, 150)
                spd = math.min(speed, math.max(40, distance * 1.2))
            else
                vy = math.clamp((cruiseY - cur.Y) * 2, -60, 140)
            end
            bv.Velocity = Vector3.new(dir.X * spd, vy, dir.Z * spd)
            faceDir(target.X, target.Z)
            task.wait()
        end

        if long then
            local tDown = nowT()
            while rgS.running do
                if not (bike.Parent and root.Parent) then error("motor hilang saat turun") end
                noclipOn()
                local cur  = root.Position
                local need = cur.Y - (destY + 2)
                if need <= 6 or nowT() - tDown > 20 then break end
                bv.Velocity = Vector3.new(0, math.clamp(-need * 2, -150, -20), 0)
                task.wait()
            end
        end
    end)

    pcall(function() bv.Velocity = Vector3.zero end)
    pcall(function() bg:Destroy() end)
    pcall(function() bv:Destroy() end)
    for _, s in ipairs(snap) do
        if s.p and s.p.Parent then
            pcall(function()
                s.p.AssemblyLinearVelocity  = Vector3.zero
                s.p.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end
    bikeRestore(snap)
    for _, s in ipairs(charSnap) do
        if s.p and s.p.Parent then pcall(function() s.p.CanCollide = s.c end) end
    end
    getgenv().RIDEGO_FLY = nil

    if ok and not rgS.running then ok = false end

    local rot = uprightRot(bike:GetPivot())
    if ok then
        pcall(function() bike:PivotTo(CFrame.new(Vector3.new(destPos.X, destY, destPos.Z)) * rot) end)
        charFollowBike(bike)
    end
    if not ok then
        pcall(function() bike:PivotTo(CFrame.new(startPos) * rot) end)
        charFollowBike(bike)
        bikeSnapGround(bike, rot)
        bikeReseat(bike)
        return false
    end
    if not bikeSnapGround(bike, rot) then
        pcall(function() bike:PivotTo(CFrame.new(startPos) * rot) end)
        charFollowBike(bike)
        bikeSnapGround(bike, rot)
        bikeReseat(bike)
        return false
    end
    charFollowBike(bike)
    bikeReseat(bike)
    rgSafePos  = bike:GetPivot().Position
    rgS.hops   = rgS.hops + 1
    rgS.lastTp = nowT()
    return true
end

local function bikeStep(bike, dest, label, allowDrop)
    if not (bike and bike.Parent and dest) then return false end
    local pivot  = bike:GetPivot()
    local rot    = uprightRot(pivot)
    local ignore = { bike, LP.Character }
    local curY   = pivot.Position.Y

    if rgS.hover and rgS.hoverY then
        local hy   = rgS.hoverY
        local g    = rayHit(Vector3.new(dest.X, hy + 45, dest.Z), Vector3.new(0, -1, 0), 185, ignore)
        local land = nil
        if g and not BAD_GROUND[g.Material] and g.Position.Y > -80 then
            local dy = g.Position.Y - hy
            if (dy >= -18 and dy <= 25) or allowDrop then land = g.Position.Y end
        end

        if land and not padExists(Vector3.new(dest.X, land, dest.Z), bike) then
            local ps = padFind(Vector3.new(dest.X, land, dest.Z), bike, 24)
            if ps then
                land = ps.Y
                dest = Vector3.new(ps.X, land, ps.Z)
            elseif nowT() - (rgS.hoverAt or 0) < 10 then
                land = nil
            end
        end
        if not land then
            if nowT() - (rgS.hoverAt or 0) > 10 then
                local ps = padFind(Vector3.new(dest.X, hy, dest.Z), bike, 64)
                if ps then
                    land = ps.Y
                    dest = Vector3.new(ps.X, hy, ps.Z)
                end
            end
        end
        if not land then
            hoverLock(bike)
            local cf = CFrame.new(Vector3.new(dest.X, hy, dest.Z)) * rot
            hoverHold(cf)
            local okH = pcall(function() bike:PivotTo(cf) end)
            if not okH then return false end
            charFollowBike(bike)
            hoverHold(cf)
            rgS.hops   = rgS.hops + 1
            rgS.lastTp = nowT()
            return true
        end

        rgS.hover, rgS.hoverY = false, nil
        hoverUnlock(bike)
        dest = Vector3.new(dest.X, land, dest.Z)
    else
        local top = math.max(dest.Y, curY) + 200
        local hit = rayHit(Vector3.new(dest.X, top, dest.Z), Vector3.new(0, -1, 0), 1200, ignore)
        if hit and BAD_GROUND[hit.Material] then hit = nil end
        if hit and hit.Normal.Y < 0.6 then hit = nil end
        if not hit then
            local deep = rayHit(Vector3.new(dest.X, curY + 4, dest.Z), Vector3.new(0, -1, 0), 2500, ignore)
            if deep and not BAD_GROUND[deep.Material] and deep.Position.Y > -80 and deep.Normal.Y > 0.6 then
                hit = deep
            end
        end

        local landPos = hit and Vector3.new(dest.X, hit.Position.Y, dest.Z) or nil
        if landPos and not padExists(landPos, bike) then landPos = padFind(landPos, bike, 32) end
        if not landPos then
            rgS.hover   = true
            rgS.hoverY  = curY
            rgS.hoverAt = nowT()
            hoverLock(bike)
            local cf = CFrame.new(Vector3.new(dest.X, curY, dest.Z)) * rot
            hoverHold(cf)
            local okH = pcall(function() bike:PivotTo(cf) end)
            if not okH then
                rgS.hover, rgS.hoverY = false, nil
                hoverUnlock(bike)
                return false
            end
            charFollowBike(bike)
            hoverHold(cf)
            rgS.hops   = rgS.hops + 1
            rgS.lastTp = nowT()
            return true
        end
        dest = landPos
    end

    local ok = pcall(
        function() bike:PivotTo(CFrame.new(dest + Vector3.new(0, CFG.GROUND_OFFSET, 0)) * rot) end
    )
    if not ok then return false end
    local at    = bike:GetPivot().Position
    local under = rayHit(at + Vector3.new(0, 1, 0), Vector3.new(0, -1, 0), 14, { bike, LP.Character })
    local solid = under
        and not BAD_GROUND[under.Material]
        and under.Normal.Y > 0.6
        and padExists(Vector3.new(at.X, under.Position.Y, at.Z), bike)
    if not solid then
        pcall(function() bike:PivotTo(pivot) end)
        charFollowBike(bike)
        local back =
            rayHit(pivot.Position + Vector3.new(0, 1, 0), Vector3.new(0, -1, 0), 14, { bike, LP.Character })
        if back then
            rgS.note = "tepi tanah, batal melangkah"
        else
            if not rgS.hover then
                rgS.hover, rgS.hoverY = true, pivot.Position.Y
                rgS.hoverAt = nowT()
                hoverLock(bike)
            end
            rgS.note = "tidak ada pijakan -> lanjut melayang"
        end
        return false
    end
    charFollowBike(bike)
    rgS.hops   = rgS.hops + 1
    rgS.lastTp = nowT()
    rgSafePos  = bike:GetPivot().Position
    return true
end

local function pendingHeal()
    local pend = getgenv().RIDEGO_PENDING
    if type(pend) ~= "table" then return false end
    getgenv().RIDEGO_PENDING = nil
    if pend.bike and pend.bike.Parent and type(pend.snap) == "table" then
        bikeRestore(pend.snap)
        return true
    end
    return false
end

-- ── Road Graph & A* Pathfinder ────────────────────────────────────────────────
local NODES, BANNED = {}, {}
do
    if readfile and isfile and isfile(CFG.TRAIL_FILE) then
        local ok, data = pcall(
            function() return HttpService:JSONDecode(readfile(CFG.TRAIL_FILE)) end
        )
        if ok and type(data) == "table" then
            for _, n in ipairs(data.nodes or data.n or {}) do
                local v
                if type(n) == "table" then
                    if n[1] then
                        v = Vector3.new(n[1], n[2], n[3])
                    elseif n.x then
                        v = Vector3.new(n.x, n.y, n.z)
                    end
                end
                if v then NODES[#NODES + 1] = v end
            end
        end
    end
end

local function distXZ(a, b) return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude end

local NODE_SET = {}

local function mapAddNode(v)
    local key = string.format("%d_%d", math.floor(v.X / 22), math.floor(v.Z / 22))
    if NODE_SET[key] then return false end
    NODE_SET[key] = true
    NODES[#NODES + 1] = v
    return true
end

local lastScan = 0

local function mapScanRoads(force)
    if not force and (nowT() - lastScan) < 6 then return 0 end
    lastScan = nowT()
    local added = 0
    local seen  = 0

    for _, d in ipairs(Workspace:GetDescendants()) do
        seen = seen + 1
        if seen % 300 == 0 then task.wait() end
        if
            d:IsA("BasePart")
            and d.CanCollide
            and d.Material == Enum.Material.Asphalt
            and d.Size.Y <= 10
            and math.max(d.Size.X, d.Size.Z) >= 12
        then
            local cf, size = d.CFrame, d.Size
            local nx = math.clamp(math.floor(size.X / 40), 1, 24)
            local nz = math.clamp(math.floor(size.Z / 40), 1, 24)
            for ix = 0, nx do
                for iz = 0, nz do
                    local px = ((nx > 0) and (ix / nx - 0.5) or 0) * size.X
                    local pz = ((nz > 0) and (iz / nz - 0.5) or 0) * size.Z
                    local p  = cf * Vector3.new(px, size.Y * 0.5, pz)
                    if mapAddNode(p) then added = added + 1 end
                    if added > 20000 then return added end
                end
            end
        end
    end
    return added
end

local function guideTarget()
    local am = Workspace:FindFirstChild("ActiveMissions")
    local g  = am and am:FindFirstChild("RideGO_GuideTarget")
    if g and g:IsA("BasePart") then return g.Position end
    return nil
end

local function guideIsDrop()
    local am = Workspace:FindFirstChild("ActiveMissions")
    local g  = am and am:FindFirstChild("RideGO_GuideTarget")
    if not g or not g:IsA("BasePart") then return false end
    local c
    local b = g:FindFirstChild("RideGO_Beam")
    if b and b:IsA("Beam") then
        local k = b.Color.Keypoints
        if k and k[1] then c = k[1].Value end
    end
    c = c or g.Color
    return c.G > 0.55 and c.R < 0.45
end

local function eventPos(d, key)
    if type(d) ~= "table" then return nil end
    local v = d[key]
    if typeof(v) == "Vector3" then return v end
    if type(v) == "table" and type(v.X) == "number" and type(v.Z) == "number" then
        return Vector3.new(v.X, v.Y or 0, v.Z)
    end
    return nil
end

local rgEV = {
    online   = false,
    offer    = nil,
    accepted = nil,
    boarded  = false,
    trip     = nil,
    done     = nil,
    acked    = false,
}
_G.RIDEGO_EV = rgEV

local function eventDrop()
    return eventPos(rgEV.trip, "DropPos") or eventPos(rgEV.accepted, "DropPos")
end

local function mapNearest(p)
    local best, bd = nil, math.huge
    for _, n in ipairs(NODES) do
        local d = distXZ(n, p)
        if d < bd then
            best, bd = n, d
        end
    end
    return best, bd
end

local GCELL = 130
local GRID, GRID_N = {}, -1

local function mapEnsureGrid()
    if GRID_N == #NODES then return end
    GRID = {}
    for i = 1, #NODES do
        local n = NODES[i]
        local k = math.floor(n.X / GCELL) .. "_" .. math.floor(n.Z / GCELL)
        local b = GRID[k]
        if not b then
            b = {}
            GRID[k] = b
        end
        b[#b + 1] = i
    end
    GRID_N = #NODES
end

local function mapNeighbors(i, out)
    mapEnsureGrid()
    local n  = NODES[i]
    local cx = math.floor(n.X / GCELL)
    local cz = math.floor(n.Z / GCELL)
    for dx = -1, 1 do
        for dz = -1, 1 do
            local b = GRID[(cx + dx) .. "_" .. (cz + dz)]
            if b then
                for _, j in ipairs(b) do
                    if j ~= i then
                        local m = NODES[j]
                        local ax, az = m.X - n.X, m.Z - n.Z
                        if ax * ax + az * az <= GCELL * GCELL and math.abs(m.Y - n.Y) <= 45 then
                            out[#out + 1] = j
                        end
                    end
                end
            end
        end
    end
    return out
end

local function mapNearIndex(p, maxR)
    mapEnsureGrid()
    maxR = maxR or 400
    local best, bd = nil, maxR
    local r  = math.ceil(maxR / GCELL)
    local cx = math.floor(p.X / GCELL)
    local cz = math.floor(p.Z / GCELL)
    for dx = -r, r do
        for dz = -r, r do
            local b = GRID[(cx + dx) .. "_" .. (cz + dz)]
            if b then
                for _, i in ipairs(b) do
                    local n = NODES[i]
                    local ax, az = n.X - p.X, n.Z - p.Z
                    local d = math.sqrt(ax * ax + az * az)
                    if d < bd then
                        best, bd = i, d
                    end
                end
            end
        end
    end
    return best, bd
end

local function mapPlan(from, to)
    if #NODES < 4 then return nil end
    local s = mapNearIndex(from, 600)
    if not s then return nil end
    local g = mapNearIndex(to, 1500)
    if not g then return nil end
    if s == g then return nil end

    local open     = { s }
    local inOpen   = { [s] = true }
    local gScore   = { [s] = 0 }
    local gn       = NODES[g]
    local sx, sz   = NODES[s].X - from.X, NODES[s].Z - from.Z
    local h0x, h0z = gn.X - from.X, gn.Z - from.Z
    local fScore   = { [s] = math.sqrt(sx * sx + sz * sz) + math.sqrt(h0x * h0x + h0z * h0z) }
    local came     = {}
    local closed   = {}
    local budget   = 6000
    local iter     = 0

    while #open > 0 and budget > 0 do
        budget = budget - 1
        iter   = iter + 1

        if iter % 400 == 0 then task.wait() end
        local bi, bf = 1, math.huge
        for k = 1, #open do
            local f = fScore[open[k]] or math.huge
            if f < bf then
                bi, bf = k, f
            end
        end
        local cur = table.remove(open, bi)
        inOpen[cur] = nil
        if cur == g then break end
        closed[cur] = true
        local n  = NODES[cur]
        local ns = {}
        mapNeighbors(cur, ns)
        for _, j in ipairs(ns) do
            local ban = BANNED[j]
            if not closed[j] and not (ban and ban > nowT()) then
                local m      = NODES[j]
                local dx, dz = m.X - n.X, m.Z - n.Z
                local ng     = (gScore[cur] or 0) + math.sqrt(dx * dx + dz * dz)
                if ng < (gScore[j] or math.huge) then
                    came[j]   = cur
                    gScore[j] = ng
                    local hx, hz = gn.X - m.X, gn.Z - m.Z
                    fScore[j] = ng + math.sqrt(hx * hx + hz * hz)
                    if not inOpen[j] then
                        open[#open + 1] = j
                        inOpen[j] = true
                    end
                end
            end
        end
    end

    if not gScore[g] then return nil end
    local path  = {}
    local c     = g
    local guard = 0
    while c and c ~= s and guard < 5000 do
        guard = guard + 1
        table.insert(path, 1, NODES[c] + Vector3.new(0, 1.5, 0))
        c = came[c]
    end
    if #path == 0 then return nil end
    return path
end

-- ── Bike Spawn, Seat & Void Recovery ──────────────────────────────────────────
local function bikeFind()
    local char = LP.Character
    if not char then return nil end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart

    if seat then
        local m = seat.Parent
        while m and m.Parent ~= Workspace do
            m = m.Parent
        end
        if m and m:FindFirstChild("DriveSeat", true) then return m, seat end
    end

    for _, m in ipairs(Workspace:GetChildren()) do
        if m:IsA("Model") and m.Name:find(LP.Name, 1, true) then
            local ds = m:FindFirstChild("DriveSeat", true)
            if ds then return m, ds end
        end
    end
    return nil
end

local function bikeSit(bike, seat)
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (hum and seat) then return false end
    if seat.Occupant == hum then return true end
    pcall(function() char:PivotTo(seat.CFrame * CFrame.new(0, 2.5, 0)) end)
    task.wait(0.25)
    pcall(function() seat:Sit(hum) end)
    for _ = 1, 20 do
        task.wait(0.2)
        if seat.Occupant == hum then return true end
    end
    return seat.Occupant == hum
end

local function jobEnsure()
    local JobEvents = ReplicatedStorage:FindFirstChild("JobEvents")
    local req       = JobEvents and JobEvents:FindFirstChild("TeamChangeRequest")
    if not req then return false end
    if LP.Team and LP.Team.Name == "RideGO Driver" then return true end
    rgS.phase = "join job"
    local ok = pcall(function() req:FireServer("RideGO Driver", 11378976, 1, 0, "MainMenu") end)
    if not ok then return false end
    for _ = 1, 40 do
        task.wait(0.25)
        if LP.Team and LP.Team.Name == "RideGO Driver" then return true end
    end
    return LP.Team ~= nil and LP.Team.Name == "RideGO Driver"
end

local function bikeEnsure()
    pendingHeal()
    local bike, seat = bikeFind()
    if bike then
        fallGuardOn(bike)
        bikeSit(bike, seat)
        return bike, seat
    end
    local sp = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
    local sc = sp and sp:FindFirstChild("SpawnCar")
    if not sc then return nil end
    rgS.phase = "spawn motor"
    pcall(function() sc:FireServer(ATUR.SELECTED_BIKE or "Yamahax-MioSporty") end)
    for _ = 1, 50 do
        task.wait(0.3)
        bike, seat = bikeFind()
        if bike then
            bikeSit(bike, seat)
            return bike, seat
        end
    end
    return nil
end

local function guardChar(bike)
    bike = bike or bikeFind()
    local char = LP.Character
    if not (bike and bike.Parent and char and char.Parent) then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local seat = bikeDriveSeat(bike)
    if not (hum and root and seat) then return end
    if hum.Health <= 0 then return end
    local bp      = bike:GetPivot().Position
    local off     = (root.Position - bp).Magnitude
    local falling = root.Position.Y < bp.Y - 20
    if off <= 20 and not falling and seat.Occupant == hum then return end
    pcall(function()
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    pcall(function() char:PivotTo(seat.CFrame) end)
    if nowT() - (rgS.charLogAt or 0) > 2 then rgS.charLogAt = nowT() end
    bikeReseat(bike, 4)
end

local function guardVoid()
    local bike = bikeFind()
    if not bike or not bike.Parent then return end

    pcall(guardChar, bike)
    local p = bike:GetPivot().Position

    if not rgS.hover and not rgS.hoverAnchored then
        local any = false
        for _, d in ipairs(bike:GetDescendants()) do
            if d:IsA("BasePart") and d.Anchored then
                any = true
                break
            end
        end
        if any then
            rgS.lockSeenAt = rgS.lockSeenAt or nowT()
            if nowT() - rgS.lockSeenAt > 1.5 then
                for _, d in ipairs(bike:GetDescendants()) do
                    if d:IsA("BasePart") then pcall(function() d.Anchored = false end) end
                end
                rgS.lockSeenAt = nil
            end
        else
            rgS.lockSeenAt = nil
        end
    end

    if rgS.hover then
        if p.Y < -80 and rgSafePos then
            rgS.hover  = false
            rgS.hoverY = nil
            hoverUnlock(bike)
            bikeTeleport(bike, rgSafePos + Vector3.new(0, 2, 0), "tarik dari melayang")
        end
        return
    end
    if rgSafePos then
        local underNow =
            rayHit(Vector3.new(p.X, p.Y + 1, p.Z), Vector3.new(0, -1, 0), 10, { bike, LP.Character })
        if not underNow then
            local back = rayHit(
                Vector3.new(rgSafePos.X, rgSafePos.Y + 30, rgSafePos.Z),
                Vector3.new(0, -1, 0),
                60,
                { bike, LP.Character }
            )
            if back then
                bikeTeleport(bike, rgSafePos + Vector3.new(0, 2, 0), "tarik dari tepi")
            else
                rgSafePos = nil
                bikeEnsure()
            end
            return
        end
    end

    if rgSafePos and p.Y < rgSafePos.Y - 15 and not rgS.hover then
        local g = rayHit(p + Vector3.new(0, 1, 0), Vector3.new(0, -1, 0), 25, { bike, LP.Character })
        if not g then
            bikeTeleport(bike, rgSafePos + Vector3.new(0, 2, 0), "tarik dari jatuh")
            return
        end
    end
    local n      = mapNearest(p)
    local floorY = n and (n.Y - 80) or -40
    if p.Y < math.min(floorY, -40) then
        if rgSafePos and rgSafePos.Y > -100 then
            bikeTeleport(bike, rgSafePos + Vector3.new(0, 2, 0), "tarik dari void")
        else
            bikeEnsure()
        end
    elseif p.Y > -60 then
        local under = rayHit(Vector3.new(p.X, p.Y + 4, p.Z), Vector3.new(0, -1, 0), 40, { bike, LP.Character })
        if not under then
            local far = rayHit(Vector3.new(p.X, p.Y, p.Z), Vector3.new(0, -1, 0), 2000, { bike, LP.Character })
            if far then bikeTeleport(bike, far.Position + Vector3.new(0, 2, 0), "turun ke tanah") end
        else
            rgSafePos = p
        end
    end
end

-- ── Taxi Remotes & Order State Machine ────────────────────────────────────────
local TaxiEventRG = nil
local ackEarly

task.spawn(function()
    local TaxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets", 30)
    local TaxiEvents = TaxiAssets and TaxiAssets:WaitForChild("Events", 15)
    local tevt       = TaxiEvents and TaxiEvents:WaitForChild("TaxiEvent", 15)
    TaxiEventRG      = tevt
    if not TaxiEventRG then return end

    TaxiEventRG.OnClientEvent:Connect(function(action, data)
        pcall(function()
            rgEV.last = action
            if action == "DutyStarted" then
                rgEV.online = true
            elseif action == "OrderOffer" then
                rgEV.offer = data or {}
            elseif action == "OrderAccepted" then
                rgEV.accepted = data or {}
                rgEV.acked    = false
                rgEV.online   = true
            elseif action == "OrderDeclined" or action == "OrderExpired" then
                rgEV.offer = nil
            elseif action == "PassengerBoarding" then
                rgEV.boarded = true
            elseif action == "TripStarted" then
                rgEV.boarded = true
                rgEV.trip    = data
            elseif action == "OrderCompleted" then
                rgEV.done   = data or true
                rgEV.online = true
                if ackEarly then ackEarly() end
            end
        end)
    end)
end)

local hookedRemote = {}
local lastHook = 0
local function taxiHook()
    if nowT() - lastHook < 5 then return end
    lastHook = nowT()
    local seen = 0
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        seen = seen + 1
        if seen % 200 == 0 then task.wait() end
        if d:IsA("RemoteEvent") and d ~= TaxiEventRG and not hookedRemote[d] then
            hookedRemote[d] = true
            local nm = d.Name
            pcall(function()
                d.OnClientEvent:Connect(function(...)
                    if nm ~= "ChangeTitles" then return end
                    local a = { ... }
                    for _, v in ipairs(a) do
                        if type(v) == "table" and v.name == "KM" then
                            local idx   = table.find(a, v)
                            local studs = a[idx + 1]
                            local money = a[idx + 2]
                            if type(studs) == "number" then
                                rgS.tripStuds = math.floor(studs)
                                rgS.tripMoney = type(money) == "number" and math.floor(money) or rgS.tripMoney
                            end
                        end
                    end
                end)
            end)
        end
    end
end

local function taxiFire(action, ...)
    if not TaxiEventRG then return false end
    local args = table.pack(...)
    return pcall(function() TaxiEventRG:FireServer(action, table.unpack(args, 1, args.n)) end)
end

local function tripAck()
    if rgEV.acked then return end
    rgEV.acked = true
    if CFG.AUTO_ACK then taxiFire("AckTripComplete") end
end
ackEarly = tripAck

local function waitUntil(fn, timeout, step)
    local t0 = nowT()
    step = step or 0.25
    while rgS.running do
        local v = fn()
        if v then return v end
        if nowT() - t0 > timeout then return nil end
        task.wait(step)
    end
    return nil
end

local function stepFindGround(from, to, maxStep, ignore)
    local dir = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
    if dir.Magnitude < 0.5 then return nil end
    local dirUnit = dir.Unit
    local fromD   = dir.Magnitude
    local topY    = math.max(from.Y, to.Y) + 140

    local angles = { 0, 15, -15, 28, -28, 42, -42, 55, -55, 65, -65 }
    local fracs  = { 1.0, 0.85, 0.7 }
    for _, a in ipairs(angles) do
        local rad = math.rad(a)
        local c, s = math.cos(rad), math.sin(rad)
        local d = Vector3.new(dirUnit.X * c - dirUnit.Z * s, 0, dirUnit.X * s + dirUnit.Z * c)
        for _, f in ipairs(fracs) do
            local st     = maxStep * f
            local px, pz = from.X + d.X * st, from.Z + d.Z * st
            if fromD - st * 0.6 > 0 then
                local hit = rayHit(Vector3.new(px, topY, pz), Vector3.new(0, -1, 0), 1400, ignore)
                if hit and not BAD_GROUND[hit.Material] then return Vector3.new(px, hit.Position.Y, pz), a, st end
            end
        end
    end
    return nil
end

local function stepFindClear(pos, target, step, bike, ignore, rot)
    local base = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
    if base.Magnitude < 0.5 then return nil end
    base = base.Unit
    local dirs = { 0, 25, -25, 50, -50, 75, -75, 100, -100 }
    for _, a in ipairs(dirs) do
        local rad = math.rad(a)
        local c, s = math.cos(rad), math.sin(rad)
        local d = Vector3.new(base.X * c - base.Z * s, 0, base.X * s + base.Z * c)
        for _, f in ipairs({ 1.0, 0.65 }) do
            local st  = step * f
            local q   = Vector3.new(pos.X + d.X * st, pos.Y, pos.Z + d.Z * st)
            local hit = rayHit(Vector3.new(q.X, q.Y + 200, q.Z), Vector3.new(0, -1, 0), 1600, ignore)
            if hit and not BAD_GROUND[hit.Material] then
                local cand = Vector3.new(q.X, hit.Position.Y, q.Z)
                if areaClearAt(cand + Vector3.new(0, CFG.GROUND_OFFSET, 0), rot, bike) then return cand, a end
            end
        end
    end
    return nil
end

local function groundAtPoint(p, ignore, lift)
    local hit = rayHit(Vector3.new(p.X, p.Y + 400, p.Z), Vector3.new(0, -1, 0), 1400, ignore)
    if hit and not BAD_GROUND[hit.Material] then return Vector3.new(p.X, hit.Position.Y + (lift or 0), p.Z) end
    return nil
end

local function groundAtXZ(x, z, baseY, ignore)
    local hit = rayHit(Vector3.new(x, (baseY or 0) + 150, z), Vector3.new(0, -1, 0), 450, ignore)
    if hit and not BAD_GROUND[hit.Material] then return hit.Position.Y end
    return nil
end

local function gapAhead(pos, target, ignore, maxGap)
    local dx, dz = target.X - pos.X, target.Z - pos.Z
    local d0     = math.sqrt(dx * dx + dz * dz)
    if d0 < 1 then return nil end
    local dir   = Vector3.new(dx / d0, 0, dz / d0)
    maxGap      = maxGap or CFG.FLY_MAX_GAP
    local baseY = pos.Y

    local function wet(x, z, groundY, refY)
        rgWaterParams.FilterDescendantsInstances = ignore or {}
        local wh = Workspace:Raycast(Vector3.new(x, (refY or baseY) + 150, z), Vector3.new(0, -1, 0) * 460, rgWaterParams)
        return wh ~= nil
            and wh.Material == Enum.Material.Water
            and (groundY == nil or wh.Position.Y > groundY - 1)
    end
    local gapStart = nil
    local step     = math.clamp(maxGap / 80, 15, 60)
    local d        = 10
    while d <= maxGap do
        local x = pos.X + dir.X * d
        local z = pos.Z + dir.Z * d
        local y = groundAtXZ(x, z, baseY, ignore)
        if y and wet(x, z, y, baseY) then y = nil end
        if y then
            if gapStart then
                local dLand, landY = nil, nil
                local scan = math.max(gapStart + 5, d - step)
                while scan <= d do
                    local sx = pos.X + dir.X * scan
                    local sz = pos.Z + dir.Z * scan
                    local sy = groundAtXZ(sx, sz, baseY, ignore)
                    if sy and wet(sx, sz, sy, baseY) then sy = nil end
                    if sy then
                        dLand, landY = scan, sy
                        break
                    end
                    scan = scan + 5
                end
                if dLand then
                    local ax = pos.X + dir.X * (dLand + CFG.EDGE_MARGIN)
                    local az = pos.Z + dir.Z * (dLand + CFG.EDGE_MARGIN)
                    local ay = groundAtXZ(ax, az, landY, ignore)
                    if ay and not wet(ax, az, ay, landY) and (dLand - gapStart) >= 12 then
                        return dLand - gapStart, Vector3.new(pos.X + dir.X * dLand, landY, pos.Z + dir.Z * dLand)
                    end
                end
            end
            baseY = y
        elseif not gapStart then
            gapStart = d
        end
        d = d + step
    end
    if gapStart then return nil, nil, maxGap - gapStart end
    return nil
end

local function stepIsSafe(pos, dirUnit, step, ignore, margin)
    if step < 1 then return nil end
    local midX = pos.X + dirUnit.X * step * 0.5
    local midZ = pos.Z + dirUnit.Z * step * 0.5
    local midY = groundAtXZ(midX, midZ, pos.Y, ignore)
    if not midY then return nil end
    local endX = pos.X + dirUnit.X * step
    local endZ = pos.Z + dirUnit.Z * step
    local endY = groundAtXZ(endX, endZ, midY, ignore)
    if not endY then return nil end
    local aheadX = endX + dirUnit.X * (margin or CFG.EDGE_MARGIN)
    local aheadZ = endZ + dirUnit.Z * (margin or CFG.EDGE_MARGIN)
    if not groundAtXZ(aheadX, aheadZ, endY, ignore) then return nil end
    return Vector3.new(endX, endY, endZ)
end

local function stepAroundVoid(pos, target, maxStep, ignore, margin)
    local dx, dz = target.X - pos.X, target.Z - pos.Z
    local d0     = math.sqrt(dx * dx + dz * dz)
    if d0 < 1 then return nil end
    local want   = Vector3.new(dx / d0, 0, dz / d0)
    local cap    = math.min(maxStep, math.max(4, d0))
    local angles = { 0, 20, -20, 40, -40, 60, -60, 80, -80, 100, -100, 120, -120, 140, -140, 158, -158 }
    local best, bestAng, bestStep, bestScore
    for _, a in ipairs(angles) do
        local rad = math.rad(a)
        local c, s = math.cos(rad), math.sin(rad)
        local d = Vector3.new(want.X * c - want.Z * s, 0, want.X * s + want.Z * c)
        for _, f in ipairs({ 1.0, 0.8, 0.6 }) do
            local st = cap * f
            local p  = stepIsSafe(pos, d, st, ignore, margin)
            if p then
                local gain  = d0 - distXZ(p, target)
                local score = gain - math.abs(a) * 0.02
                if not bestScore or score > bestScore then
                    best, bestAng, bestStep, bestScore = p, a, st, score
                end
                if a == 0 and gain > 0 then return p, a, st end
            end
        end
    end
    return best, bestAng, bestStep
end

local UNREACH = {}
local function unreachKey(p) return string.format("%d_%d", math.floor(p.X / 200), math.floor(p.Z / 200)) end
local function unreachMark(p, reason)
    UNREACH[unreachKey(p)] = {
        expire = nowT() + 300,
        at     = nowT() - 31,
        reason = reason,
    }
end
local function unreachHit(p)
    local e = UNREACH[unreachKey(p)]
    if not (e and e.expire > nowT()) then return false end
    if nowT() - e.at > 30 then e.at = nowT() end
    return true
end

local function travelTo(target, arriveR, tag)
    if unreachHit(target) then return false, "tidak terjangkau" end
    local fails      = 0
    local tightTries = 0
    local bestDist   = math.huge
    local stall      = 0
    local stage      = 0
    local stallPos   = nil
    local gainMark   = nil
    local progressAt = nowT()
    rgS.spd, rgS.spdT, rgS.spdD = 0, nil, nil

    local voidTry    = 0
    local fast       = (tag == "jemput")
    local path, planAt = nil, 0
    local flyUsed    = 0
    local flyFails   = 0
    local gapBlocked = 0

    local function tryFly(pos, dist)
        if flyFails >= 2 then return false end
        if flyUsed >= CFG.FLY_MAX_CROSS then return false end
        local bike = bikeFind()
        if not (bike and bike.Parent) then return false end

        if nowT() - (rgS.streamAt or 0) > 5 then
            rgS.streamAt = nowT()
            pcall(function() Workspace:RequestStreamAroundAsync(target, 20) end)
            gainMark   = nil
            progressAt = nowT()
        end
        local gap, landPos, remain = gapAhead(pos, target, { bike, LP.Character }, CFG.FLY_MAX_GAP)
        if not (gap and landPos) then
            if remain then
                gapBlocked = gapBlocked + 1
                local dx, dz = target.X - pos.X, target.Z - pos.Z
                local dl     = math.sqrt(dx * dx + dz * dz)
                if dl > 1 then
                    local mid = pos + Vector3.new(dx / dl, 0, dz / dl) * 150
                    pcall(function() Workspace:RequestStreamAroundAsync(mid, 40) end)
                end
                if gapBlocked >= 3 then return false, true end
            end
            return false
        end

        if dist and distXZ(landPos, target) >= dist - 10 then return false end
        flyUsed = flyUsed + 1
        if rgS.hover or rgS.hoverAnchored then
            rgS.hover, rgS.hoverY = false, nil
            hoverUnlock(bike)
        end
        local longHop = gap >= CFG.FLY_LONG_MIN
        local flyTime = math.max(CFG.FLY_MAX_TIME, (gap / math.max(30, CFG.FLY_SPEED)) * 2 + 30)
        local label   = longHop and "terbang JAUH" or "terbang menyeberang"
        rgS.phase     = label
        rgS.note      = string.format("terbang %.0f stud", gap)
        local okFly   = bikeFlyTo(bike, landPos, CFG.FLY_SPEED, CFG.FLY_ARRIVE, flyTime, gap)

        gainMark   = nil
        progressAt = nowT()
        if not okFly then
            flyFails = flyFails + 1
            flyUsed  = math.max(0, flyUsed - 1)
            return false
        end
        voidTry  = 0
        fails    = 0
        stall    = 0
        stallPos = nil
        stage    = 0
        path     = nil
        bestDist = distXZ(bike:GetPivot().Position, target)
        return true
    end

    while rgS.running do
        guardVoid()

        if tag ~= "jemput" then
            local g = guideTarget()
            if g and distXZ(g, target) > 60 then
                target     = g
                gainMark   = nil
                progressAt = nowT()
            end
        end
        local bike = bikeFind()
        if not bike then
            bike = bikeEnsure()
            if not bike then return false, "motor hilang" end
        end
        fallGuardOn(bike)

        do
            local char = LP.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local seat = bikeDriveSeat(bike)
            if seat and hum and seat.Occupant ~= hum then bikeReseat(bike) end
        end
        local pos  = bike:GetPivot().Position
        local dist = distXZ(pos, target)
        if dist <= arriveR then
            bikeReseat(bike)
            rgS.note = string.format("sampai %s (%.0f stud)", tag, dist)
            return true
        end

        if fails >= 2 and dist <= math.max(arriveR * 4, 60) then
            local closer
            if tightTries < 3 and dist > arriveR * 1.6 then closer = findSafeNear(target, 45, bike, true) end
            if closer and distXZ(closer, target) < dist - 4 then
                tightTries = tightTries + 1
                bikeTeleport(bike, closer, "merapat ke " .. tag)
                fails = 0
            else
                bikeReseat(bike)
                rgS.note = string.format("cukup dekat %s (%.0f stud)", tag, dist)
                return true
            end
        end

        local now = nowT()
        if not rgS.spdT then
            rgS.spdT, rgS.spdD = now, dist
        elseif now - rgS.spdT > 2 then
            rgS.spd = (rgS.spdD - dist) / (now - rgS.spdT)
            rgS.spdT, rgS.spdD = now, dist
        end

        if not gainMark then
            gainMark   = dist
            progressAt = now
        elseif dist <= gainMark - 100 then
            gainMark   = dist
            progressAt = now
        end
        if now - progressAt > ATUR.BATAS_DIAM then
            rgS.note = "tidak ada kemajuan"
            unreachMark(target, "tidak ada kemajuan")
            return false, "tidak ada kemajuan"
        end

        rgS.phase = "teleport " .. tag
        local spd = math.max(0, rgS.spd or 0)
        if spd > 1 then
            rgS.note = string.format(
                "%.0f stud lagi  (%.0f stud/s, ~%ds)",
                dist,
                spd,
                math.ceil(dist / spd)
            )
        else
            rgS.note = string.format("%.0f stud lagi", dist)
        end

        local gap = fast and math.max(0.05, ATUR.JEMPUT_JEDA) or math.max(0.05, ATUR.ANTAR_JEDA)
        if nowT() - rgS.lastTp < gap then task.wait(gap - (nowT() - rgS.lastTp)) end

        local dest, how
        local margin = math.min(CFG.EDGE_MARGIN, math.max(10, dist * 0.5))
        if fast then
            local st = ATUR.JEMPUT_JARAK
            if fails >= 6 then
                local gs = groundAtPoint(target, { bike, LP.Character }, 0)
                pcall(function() Workspace:RequestStreamAroundAsync(target, 20) end)
                if gs then
                    dest, how = gs, "titik jemput"
                end
            else
                local sg, sang = stepAroundVoid(pos, target, st, { bike, LP.Character }, margin)
                if not sg then
                    local g, ang = stepFindGround(pos, target, st, { bike, LP.Character })
                    if g then
                        sg, sang = g, ang
                    end
                end
                if sg then
                    voidTry   = 0
                    dest, how = sg, "jemput cepat"
                    if sang and sang ~= 0 then how = string.format("jemput putar pinggir %d", sang) end
                else
                    local flew, unflyable = tryFly(pos, dist)
                    if flew then
                        voidTry = 0
                        how     = "terbang menyeberang"
                    elseif unflyable then
                        rgS.note = "celah terlalu lebar"
                        return false, "celah terlalu lebar"
                    else
                        voidTry = voidTry + 1
                        pcall(function() Workspace:RequestStreamAroundAsync(target, 20) end)
                        rgS.note = string.format("menunggu peta (putar pinggir %d)", voidTry)
                    end
                end
            end
        else
            local step = ATUR.ANTAR_JARAK

            if not path or #path == 0 or nowT() - planAt > 10 then
                path = mapPlan(pos, target)
                if (not path or #path == 0) and dist > 300 and nowT() - (rgS.mapScanAt or 0) > 20 then
                    rgS.mapScanAt = nowT()
                    pcall(function() Workspace:RequestStreamAroundAsync(target, 20) end)
                    mapScanRoads()
                    gainMark   = nil
                    progressAt = nowT()
                    path       = mapPlan(pos, target)
                end
                planAt = nowT()
            end
            if path and #path > 0 then
                while #path > 0 do
                    local n0    = path[1]
                    local dNode = distXZ(pos, n0)
                    if dNode < 20 or (dNode <= step * 2 and distXZ(n0, target) > dist - 5) then
                        table.remove(path, 1)
                    else
                        break
                    end
                end
            end
            local ignore = { bike, LP.Character }
            if path and #path > 0 then
                local nxt   = path[1]
                local first = distXZ(pos, nxt)
                if first > step then
                    local dir = Vector3.new(nxt.X - pos.X, 0, nxt.Z - pos.Z)
                    if dir.Magnitude > 0.01 then
                        dir = dir.Unit
                        nxt = Vector3.new(pos.X + dir.X * step, nxt.Y, pos.Z + dir.Z * step)
                    end
                else
                    local walked = first
                    local from   = nxt
                    local prev   = Vector3.new(nxt.X - pos.X, 0, nxt.Z - pos.Z)
                    if prev.Magnitude > 0.01 then prev = prev.Unit else prev = nil end
                    local i = 2
                    while prev and i <= #path and walked < step do
                        local nn  = path[i]
                        local seg = Vector3.new(nn.X - from.X, 0, nn.Z - from.Z)
                        if seg.Magnitude > 0.01 then
                            local dir = seg.Unit
                            if prev:Dot(dir) < 0.75 then break end
                            if walked + seg.Magnitude > step then
                                nxt = Vector3.new(
                                    from.X + dir.X * (step - walked),
                                    nn.Y,
                                    from.Z + dir.Z * (step - walked)
                                )
                                walked = step
                                break
                            end
                            walked = walked + seg.Magnitude
                            nxt    = nn
                            from   = nn
                            prev   = dir
                        end
                        i = i + 1
                    end
                end

                local stp = math.min(step, math.max(1, distXZ(pos, nxt)))
                local g = stepAroundVoid(pos, nxt, stp, ignore, margin)
                    or stepFindGround(pos, nxt, stp, ignore)
                    or groundAtPoint(nxt, ignore)
                if g then
                    voidTry   = 0
                    dest, how = g, "jalan raya"
                end
            end

            if not dest then
                local sg, sang = stepAroundVoid(pos, target, step, ignore, margin)
                if sg then
                    voidTry  = 0
                    local hd = math.floor(distXZ(pos, sg))
                    dest, how = sg, string.format("langkah %d stud", hd)
                    if sang and sang ~= 0 then how = string.format("putar pinggir %d (%d stud)", sang, hd) end
                elseif dist <= 120 then
                    local g, ang = stepFindGround(pos, target, step, ignore)
                    if g then
                        voidTry  = 0
                        local hd = math.floor(distXZ(pos, g))
                        dest, how = g, string.format("langkah %d stud", hd)
                        if ang ~= 0 then how = string.format("langkah %d stud (belok %d)", hd, ang) end
                    end
                end
                if not dest then
                    local flew, unflyable = tryFly(pos, dist)
                    if flew then
                        voidTry = 0
                        how     = "terbang menyeberang"
                    elseif unflyable then
                        rgS.note = "celah terlalu lebar"
                        return false, "celah terlalu lebar"
                    else
                        voidTry = voidTry + 1
                        pcall(function() Workspace:RequestStreamAroundAsync(target, 20) end)
                        rgS.note = string.format("menunggu peta (putar pinggir %d)", voidTry)
                    end
                end
            end

            if
                dest
                and how ~= "jembatan"
                and not string.find(how or "", "melayang")
                and not rgS.hover
                and (fails > 0 or rgS.hops % 4 == 0)
            then
                local rot2 = uprightRot(bike:GetPivot())
                if not areaClearAt(dest + Vector3.new(0, CFG.GROUND_OFFSET, 0), rot2, bike) then
                    local cs, ang = stepFindClear(pos, target, step, bike, ignore, rot2)
                    if cs then
                        dest, how = cs, string.format("belok %d", ang or 0)
                    else
                        dest     = nil
                        rgS.note = "mentok tembok, cari jalan"
                        task.wait(0.25)
                    end
                end
            end
        end

        if dest then
            local hadPax = rgEV.boarded or rgEV.trip
            bikeStep(bike, dest, how, dist <= math.max(CFG.ARRIVE_DROP * 4, 60))

            if hadPax and ensurePassenger then
                local paxGap = (rgS.paxMiss or 0) >= 2 and 12 or 4
                if nowT() - (rgS.paxAt or 0) > paxGap then
                    rgS.paxAt = nowT()
                    if ensurePassenger(bike) then
                        rgS.paxMiss = 0
                    else
                        rgS.paxMiss = (rgS.paxMiss or 0) + 1
                    end
                end
            end
            if how == "lompat buta ke tujuan" then mapScanRoads() end
            local after = distXZ(bike:GetPivot().Position, target)
            if after > dist - 3 then
                if path and #path > 0 then table.remove(path, 1) end
                fails = fails + 1
            else
                fails = 0
            end

            if after < bestDist - 5 then
                local prevBest = bestDist
                bestDist = after
                stall    = 0
                stallPos = nil
                if stage > 0 and after <= prevBest - 40 then stage = 0 end
            else
                stall    = stall + 1
                stallPos = stallPos or pos
                if distXZ(pos, stallPos) > 120 then
                    stall    = 0
                    stallPos = pos
                end
            end
            if stall >= CFG.STALL_STEPS and dist > math.max(arriveR * 2, 40) then
                stall    = 0
                stallPos = nil

                local flew, unflyable = tryFly(pos, dist)
                if flew then
                    path  = nil
                    stage = 0
                elseif unflyable then
                    rgS.note = "celah terlalu lebar"
                    unreachMark(target, "celah terlalu lebar")
                    return false, "celah terlalu lebar"
                elseif stage == 0 then
                    stage = 1
                    path  = nil
                    local bi = mapNearIndex(pos, 250)
                    if bi then BANNED[bi] = nowT() + 120 end
                elseif stage == 1 then
                    stage = 2
                    local moved = false
                    local bp    = rgSafePos
                    if bp and distXZ(bp, pos) > 40 and distXZ(bp, target) <= dist + 60 then
                        moved = bikeTeleport(bike, bp + Vector3.new(0, 2, 0), "tarik dari macet")
                    end
                    if not moved then
                        local alt = findSafeNear(pos, 120, bike, true)
                        if alt and distXZ(alt, pos) > 25 then moved = bikeTeleport(bike, alt, "geser dari macet") end
                    end
                    path     = nil
                    bestDist = distXZ(bike:GetPivot().Position, target)
                else
                    rgS.note = "macet, ulangi rute"
                    return false, "macet"
                end
            end
        else
            if how == "terbang menyeberang" then
                task.wait(0.2)
            elseif voidTry > 0 then
                task.wait(0.5)
            else
                fails = fails + 1
                task.wait(0.8)
            end
        end

        if fails >= CFG.HOP_FAIL_MAX then
            rgS.note = "tidak bisa mendekat"
            return false, how or "mentok"
        end
    end
    return false, "dihentikan"
end

-- ── Passenger Boarding & Drop-off ─────────────────────────────────────────────
local function paxOnboard(bike)
    local drive = bikeDriveSeat(bike)
    for _, d in ipairs(bike:GetDescendants()) do
        if d:IsA("VehicleSeat") and d ~= drive and d.Occupant then
            if d.Occupant.Parent ~= LP.Character then return true end
        end
    end
    return false
end

local function bikePaxSeat(bike)
    local drive = bikeDriveSeat(bike)
    for _, d in ipairs(bike:GetDescendants()) do
        if d:IsA("VehicleSeat") and d ~= drive then return d end
    end
    return nil
end

ensurePassenger = function(bike)
    if not bike then return false end
    if paxOnboard(bike) then return true end
    local seat = bikePaxSeat(bike)
    if not seat then return false end
    local am  = Workspace:FindFirstChild("ActiveMissions")
    local pax = am and am:FindFirstChild("RideGO_Passenger")
    local ph  = pax and pax:FindFirstChildOfClass("Humanoid")
    if not (pax and ph) then return false end
    pcall(function() pax:PivotTo(seat.CFrame * CFrame.new(0, 3, 0)) end)
    task.wait(0.12)
    pcall(function() seat:Sit(ph) end)
    for _ = 1, 8 do
        task.wait(0.12)
        if seat.Occupant == ph then return true end
    end
    return false
end

local function paxWaitBoarding(pickup)
    for round = 1, CFG.BOARD_ROUNDS do
        if not rgS.running then return false end
        rgS.phase = "tunggu penumpang"
        rgS.note  = string.format("ronde %d/%d", round, CFG.BOARD_ROUNDS)
        local b = bikeFind()
        if b and paxOnboard(b) then
            rgEV.boarded = true
            return true
        end
        local boarded = waitUntil(function()
            if rgEV.boarded or rgEV.trip then return true end
            local bb = bikeFind()
            return bb and paxOnboard(bb) or nil
        end, CFG.BOARD_WAIT)
        if boarded then
            rgEV.boarded = true
            return true
        end

        local bike = bikeFind()
        if not bike then return false end

        if ensurePassenger and ensurePassenger(bike) then
            rgEV.boarded = true
            return true
        end
        local cur = bike:GetPivot().Position
        local dir = Vector3.new(cur.X - pickup.X, 0, cur.Z - pickup.Z)
        if dir.Magnitude < 1 then dir = Vector3.new(1, 0, 0) end
        dir = dir.Unit

        local back = Vector3.new(cur.X, pickup.Y, cur.Z) + dir * CFG.BOARD_BACKOFF
        local spot = findSafeNear(back, 80, bike)
        if spot then
            bikeTeleport(bike, spot, "mundur dari penumpang")
            task.wait(1.2)
            local again = waitUntil(function() return rgEV.boarded and true or nil end, 3)
            if again then return true end
        end

        local ahead = findSafeNear(pickup, 110, bike) or findSafeNear(pickup, 60, bike, true)
        if ahead then
            bikeTeleport(bike, ahead, "maju ke penumpang")
            task.wait(0.8)
        end
    end
    return false
end

local function findExactSpot(p, bike, ignoreWalls)
    local ignore = { bike, LP.Character }
    local hit = rayGroundBelow(Vector3.new(p.X, p.Y, p.Z), 60, bike)
        or rayHit(Vector3.new(p.X, p.Y + 500, p.Z), Vector3.new(0, -1, 0), 1000, ignore)
    if not hit then return nil end
    local cand = Vector3.new(p.X, hit.Position.Y + CFG.GROUND_OFFSET, p.Z)
    if ignoreWalls then return cand end
    local rot = uprightRot(bike:GetPivot())
    if areaClearAt(cand, rot, bike) then return cand end
    return nil
end

local function waitDrop(drop)
    local holdStart = nowT()
    while rgS.running and (nowT() - holdStart) < CFG.DROP_HOLD do
        if rgEV.done then return true end
        guardVoid()
        local bike = bikeFind()
        local g    = guideTarget()
        if bike and g then
            local dg = distXZ(bike:GetPivot().Position, g)
            if dg > 80 and distXZ(g, drop) > 80 then
                drop = g
                if not travelTo(drop, CFG.ARRIVE_DROP, "antar") then return false end
                holdStart = nowT()
                bike      = bikeFind()
            end
        end
        if bike then
            local cur = bike:GetPivot().Position
            if distXZ(cur, drop) > 8 then
                local tight = findExactSpot(drop, bike, true) or findSafeNear(drop, 40, bike, true)
                if tight then bikeTeleport(bike, tight, "tahan di titik antar") end
            end
        end
        rgS.phase = "tunggu selesai"
        rgS.note  = string.format(
            "verifikasi %ds/%ds | %s",
            math.floor(nowT() - holdStart),
            CFG.DROP_HOLD,
            tostring(rgS.tripMoney or "-")
        )
        task.wait(1.0)
    end
    if rgEV.done then return true end

    for round = 1, CFG.DROP_ROUNDS do
        if not rgS.running then return false end
        rgS.phase = "tunggu selesai"
        rgS.note  = string.format("diam di titik antar %d/%d", round, CFG.DROP_ROUNDS)

        local t0 = nowT()
        while rgS.running and (nowT() - t0) < CFG.DROP_WAIT do
            if rgEV.done then return true end
            guardVoid()
            local bike = bikeFind()
            local g    = guideTarget()

            if bike and g then
                local dg = distXZ(bike:GetPivot().Position, g)
                if dg > 80 and distXZ(g, drop) > 80 then
                    drop = g
                    if not travelTo(drop, CFG.ARRIVE_DROP, "antar") then return false end
                    break
                end
            end

            if bike and distXZ(bike:GetPivot().Position, drop) > 5 then
                local tight = findExactSpot(drop, bike) or findSafeNear(drop, 40, bike, true)
                if tight then bikeTeleport(bike, tight, "rapat ke titik antar") end
            end
            rgS.note = string.format("diam di titik antar %d/%d | %s", round, CFG.DROP_ROUNDS, tostring(rgS.tripMoney or "-"))
            task.wait(1.0)
        end
        if rgEV.done then return true end
    end

    tripAck()
    local am = Workspace:FindFirstChild("ActiveMissions")
    local g  = am and am:FindFirstChild("RideGO_GuideTarget")
    if g then pcall(function() g:Destroy() end) end
    return false
end

local function offerRequest()
    for attempt = 1, 4 do
        if not rgS.running then return nil end
        rgS.phase = "cari order"
        rgS.note  = string.format("percobaan %d/4", attempt)

        if attempt == 1 then
            if not rgEV.online then
                taxiFire("GoOnline")
                rgEV.online = true
            end
        else
            taxiFire("GoOffline")
            rgEV.online = false
            task.wait(1.6)
            taxiFire("GoOnline")
            rgEV.online = true
        end
        local offer = waitUntil(function() return rgEV.offer end, CFG.OFFER_TIMEOUT)
        if offer then return offer end
    end
    return nil
end

local function runOrder()
    rgEV.offer, rgEV.accepted, rgEV.boarded, rgEV.trip, rgEV.done = nil, nil, false, nil, nil
    rgEV.acked = false

    local bike = bikeEnsure()
    if not bike then
        rgS.note = "tidak dapat motor"
        return false
    end
    bikeReseat(bike)

    local offer = offerRequest()
    if not offer then return false end
    if (tonumber(offer.Fare) or 0) < CFG.MIN_FARE then
        if offer.Token then taxiFire("DeclineOrder", offer.Token) end
        rgEV.offer = nil
        return false
    end
    if offer.Token == nil then return false end

    rgS.phase = "accept order"
    taxiFire("AcceptOrder", offer.Token)

    local acc = waitUntil(function() return rgEV.accepted end, CFG.ACCEPT_TIMEOUT)
    if not acc then return false end
    local pickup = acc.PickupPos
    if not pickup then pickup = guideTarget() end
    if not pickup then return false end

    local okTravel = travelTo(pickup, CFG.ARRIVE_PICKUP, "jemput")
    if not okTravel then return false end

    local boarded = paxWaitBoarding(pickup)
    if not boarded then return false end

    local drop
    do
        drop = waitUntil(function()
            if guideIsDrop() then return guideTarget() end
            if rgEV.trip then
                local d = eventDrop()
                if d then return d end
                return guideTarget()
            end
            return nil
        end, 25)
        if not drop then drop = eventDrop() or guideTarget() end
    end
    if not drop then return false end

    local okDrop = travelTo(drop, CFG.ARRIVE_DROP, "antar")
    if not okDrop then return false end

    local done = waitDrop(drop)
    if not done then return false end
    tripAck()
    rgEV.accepted, rgEV.trip, rgEV.boarded, rgEV.done = nil, nil, false, nil
    rgS.orders = rgS.orders + 1
    return true
end

local function tripResumeGuide()
    local g = guideTarget()
    if not g then return false end
    local isDrop = guideIsDrop()
    rgS.phase = "lanjut trip"
    if not travelTo(g, CFG.ARRIVE_DROP, isDrop and "antar" or "tujuan") then return false end

    if rgEV.done then
        tripAck()
        rgEV.done, rgEV.boarded, rgEV.trip, rgEV.accepted = nil, false, nil, nil
        rgS.orders = rgS.orders + 1
        return true
    end

    if isDrop or rgEV.trip or rgEV.boarded then
        rgEV.boarded = true
        if waitDrop(g) then
            tripAck()
            rgEV.done, rgEV.boarded, rgEV.trip, rgEV.accepted = nil, false, nil, nil
            rgS.orders = rgS.orders + 1
            return true
        end
        return false
    end

    if paxWaitBoarding(g) then
        local dest = guideTarget() or g
        if travelTo(dest, CFG.ARRIVE_DROP, "antar") then
            if waitDrop(dest) then
                tripAck()
                rgEV.done, rgEV.boarded, rgEV.trip, rgEV.accepted = nil, false, nil, nil
                rgS.orders = rgS.orders + 1
                return true
            end
        end
    end
    return false
end

local function tripResume()
    if not rgEV.trip then return false end
    local drop = (type(rgEV.trip) == "table") and rgEV.trip.DropPos or nil
    if not drop then return false end
    local ok = travelTo(drop, CFG.ARRIVE_DROP, "antar")
    if not ok then return false end
    local done = waitDrop(drop)
    if done then
        tripAck()
        rgEV.trip, rgEV.done = nil, nil
        rgEV.boarded, rgEV.accepted = false, nil
        rgS.orders = rgS.orders + 1
        return true
    end
    return false
end

-- ── Main Menu Bypass & RideGO Core Loop ───────────────────────────────────────
local MENU_BTN = {
    "applySelect",
    "deploySelect",
    "playButton",
    "PlayButton",
    "Play",
    "play",
    "startButton",
    "StartButton",
    "deployButton",
}

local function getPlayerGui() return LP:FindFirstChildOfClass("PlayerGui") end

local function getMenuRoot()
    local pg = getPlayerGui()
    return pg, pg and pg:FindFirstChild("mainMenuSystem")
end

local function menuHitAtCenter()
    local pg  = getPlayerGui()
    local cam = Workspace.CurrentCamera
    if not (pg and cam) then return nil end
    local vp = cam.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then return nil end
    local ok, list = pcall(function() return pg:GetGuiObjectsAtPosition(vp.X * 0.5, vp.Y * 0.5) end)
    if not ok or type(list) ~= "table" then return nil end
    return list[1]
end

local function menuTopScreen(o)
    local p = o
    while p do
        if p:IsA("ScreenGui") then return p end
        p = p.Parent
    end
    return nil
end

local function guiUnderName(o, wanted)
    local p = o
    while p do
        if p.Name == wanted then return true end
        p = p.Parent
    end
    return false
end

local function menuOpen()
    local hit = menuHitAtCenter()
    if not hit then return false end
    return guiUnderName(hit, "mainMenuSystem")
end

local function loadingOpen()
    local hit = menuHitAtCenter()
    if not hit then return false end
    local sg = menuTopScreen(hit)
    if not sg then return false end
    local n = string.lower(sg.Name)
    return (string.find(n, "loading") ~= nil)
end

local function guiClick(button)
    if not (button and button.Parent) then return false end
    local t0 = nowT()
    pcall(function()
        local last = button.AbsolutePosition
        while nowT() - t0 < 2 do
            task.wait(0.05)
            if button.AbsolutePosition == last then break end
            last = button.AbsolutePosition
        end
    end)
    task.wait(0.1)
    local done = false
    pcall(function()
        local gs  = game:GetService("GuiService")
        local old = gs.SelectedObject
        gs.SelectedObject = button
        task.wait(0.08)
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.08)
        gs.SelectedObject = old
        done = true
    end)
    if not done then
        pcall(function()
            if firesignal then
                firesignal(button.MouseButton1Down)
                task.wait(0.05)
                firesignal(button.MouseButton1Up)
                firesignal(button.MouseButton1Click)
                firesignal(button.Activated)
            end
        end)
    else
        task.wait(0.5)
        if (menuOpen() or loadingOpen()) and firesignal then
            pcall(function()
                firesignal(button.MouseButton1Down)
                task.wait(0.05)
                firesignal(button.MouseButton1Up)
                firesignal(button.MouseButton1Click)
                firesignal(button.Activated)
            end)
        end
    end
    return true
end

local function waitCharacter()
    local t0 = nowT()
    while rgS.running and (nowT() - t0) < 45 do
        local ch = LP.Character
        if ch and ch:FindFirstChild("HumanoidRootPart") then
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then return true end
        end
        task.wait(0.5)
    end
    return false
end

local menuIgnore = false
local function menuClearScreens()
    if menuIgnore then return true end
    if not menuOpen() and not loadingOpen() then return true end
    local t0      = nowT()
    local presses = 0
    rgS.phase     = "main menu"
    rgS.note      = "menembus menu"
    while rgS.running and (nowT() - t0) < 150 do
        if not menuOpen() and not loadingOpen() then
            waitCharacter()
            return true
        end
        local _, mm = getMenuRoot()
        local cand  = {}
        for _, nm in ipairs(MENU_BTN) do
            local b = mm and mm:FindFirstChild(nm, true)
            if b and (b:IsA("TextButton") or b:IsA("ImageButton")) then cand[#cand + 1] = b end
        end

        local target = nil
        if #cand > 0 then target = cand[(presses % #cand) + 1] end
        if target then
            pcall(guiClick, target)
            presses  = presses + 1
            rgS.note = string.format("tekan %s (%d)", target.Name, presses)
            task.wait(0.5)
        else
            rgS.note = "menunggu tombol Play"
            task.wait(0.5)
        end
    end

    local ch0 = LP.Character
    if ch0 and ch0:FindFirstChild("HumanoidRootPart") then
        menuIgnore = true
        return true
    end
    return false
end

task.spawn(function()
    pendingHeal()

    local prepped = false
    while true do
        if not rgS.running then
            if rgS.phase ~= "standby" then
                rgS.phase = "standby"
                rgS.note  = "menunggu toggle"
            end
            task.wait(0.35)
        elseif CFG.ORDERS > 0 and rgS.orders >= CFG.ORDERS then
            break
        else
            if not prepped then
                menuClearScreens()
                if CFG.AUTO_JOB then jobEnsure() end
                if CFG.AUTO_SPAWN then bikeEnsure() end
                mapScanRoads(true)
                taxiHook()
                prepped = rgS.running
            end
            if rgS.running then
                if not menuIgnore and (menuOpen() or loadingOpen()) then
                    menuClearScreens()
                    taxiHook()
                end
                taxiHook()

                local bikeNow = bikeFind()
                local busy    = rgEV.trip or rgEV.accepted or guideTarget() or (bikeNow and paxOnboard(bikeNow))

                local ok, runErr = pcall(function()
                    if busy then return tripResume() or tripResumeGuide() end
                    return runOrder()
                end)
                if not ok then
                    rgEV.done, rgEV.trip, rgEV.accepted, rgEV.boarded = nil, nil, nil, false
                    rgS.phase = "error, ulangi"
                    task.wait(2)
                elseif not runErr then
                    rgS.phase = busy and "lanjut trip" or "istirahat"
                    rgS.note  = busy and "belum sampai tujuan, ulangi" or "cari order lagi"
                    task.wait(2)
                end
            end
        end
    end
    rgS.phase = "selesai"
end)

task.spawn(function()
    local ps = nil
    pcall(function() ps = game:GetService("Stats").Network.ServerStatsItem["Data Ping"] end)
    while ps do
        task.wait(1)
        local ok, v = pcall(function() return ps:GetValue() end)
        if ok then rgS.ping = v end
    end
end)

task.spawn(function()
    task.wait(2)
    rgFetchOwnedVehicles()
end)

-- ============================================================================
-- WIND UI
-- ============================================================================

local Wind = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

_G._wallStart = os.time()

local function createWindSlider(tab, title, minVal, maxVal, defaultVal, stepVal, onChanged)
    local sliderSpec = {
        Title = title,
        Value = {
            Min     = minVal,
            Max     = maxVal,
            Default = defaultVal,
        },
        Callback = function(raw)
            onChanged(extractSliderValue(raw, defaultVal))
        end,
    }
    if stepVal then
        sliderSpec.Step = stepVal
    end
    return tab:Slider(sliderSpec)
end

-- ── Window ────────────────────────────────────────────────────────────────────
local Window = Wind:CreateWindow({
    Title    = "Projectsion",
    SubTitle = "Autofarm",
    TabWidth = 160,
    Size     = UDim2.fromOffset(580, 460),
    Acrylic  = true,
    Theme    = "Dark",
})

-- ============================================================================
-- TAB: COURIER
-- ============================================================================
local CourierTab = Window:Tab({ Title = "Courier", Icon = "package" })

CourierTab:Toggle({
    Title   = "Auto Courier",
    Default = false,
    Callback = function(state)
        _G.AutofarmCourier = state
        updateBlackScreen()
    end,
})

createWindSlider(CourierTab, "Min Speed", 50, 500, _G.CourierSpeedMin, 1, function(v)
    _G.CourierSpeedMin = v
end)

createWindSlider(CourierTab, "Max Speed", 50, 500, _G.CourierSpeedMax, 1, function(v)
    _G.CourierSpeedMax = v
end)

-- ============================================================================
-- TAB: BARISTA
-- ============================================================================
local BaristaTab = Window:Tab({ Title = "Barista", Icon = "coffee" })

BaristaTab:Toggle({
    Title   = "Auto Barista",
    Default = false,
    Callback = function(state)
        _G.AutoFarmBarista = state
        updateBlackScreen()
    end,
})

createWindSlider(BaristaTab, "Min Speed", 50, 500, _G.BaristaSpeedMin, 1, function(v)
    _G.BaristaSpeedMin = v
end)

createWindSlider(BaristaTab, "Max Speed", 50, 500, _G.BaristaSpeedMax, 1, function(v)
    _G.BaristaSpeedMax = v
end)

-- ============================================================================
-- TAB: POLICE
-- ============================================================================
local PoliceTab = Window:Tab({ Title = "Police", Icon = "shield" })

PoliceTab:Toggle({
    Title   = "Auto Police",
    Default = false,
    Callback = function(state)
        _G.AutoPoliceEnabled = state
        updateBlackScreen()
        if state and not RequestingJob then
            task.spawn(RequestPoliceJob)
        end
    end,
})

createWindSlider(PoliceTab, "Teleport Speed Min", 50, 600, AutoPoliceConfig.TeleportSpeed.min, 1, function(v)
    AutoPoliceConfig.TeleportSpeed.min = v
end)

createWindSlider(PoliceTab, "Teleport Speed Max", 50, 600, AutoPoliceConfig.TeleportSpeed.max, 1, function(v)
    AutoPoliceConfig.TeleportSpeed.max = v
end)

-- ============================================================================
-- TAB: RIDEGO
-- ============================================================================
local RideTab = Window:Tab({ Title = "RideGO", Icon = "car" })

RideTab:Toggle({
    Title   = "RideGO",
    Default = false,
    Callback = function(state)
        setRideGOAuto(state)
    end,
})

createWindSlider(RideTab, "Pickup Distance", 10, 500, ATUR.JEMPUT_JARAK, 10, function(v)
    setAtur("JEMPUT_JARAK", v)
end)

createWindSlider(RideTab, "Drop Distance", 10, 250, ATUR.ANTAR_JARAK, 10, function(v)
    setAtur("ANTAR_JARAK", v)
end)

createWindSlider(RideTab, "Pickup Delay", 0.05, 5, ATUR.JEMPUT_JEDA, 0.05, function(v)
    setAtur("JEMPUT_JEDA", v)
end)

createWindSlider(RideTab, "Drop Delay", 0.05, 5, ATUR.ANTAR_JEDA, 0.05, function(v)
    setAtur("ANTAR_JEDA", v)
end)

createWindSlider(RideTab, "Fly Speed", 30, 400, ATUR.TERBANG_KECEPATAN, 5, function(v)
    setAtur("TERBANG_KECEPATAN", v)
end)

createWindSlider(RideTab, "Stall Limit", 15, 300, ATUR.BATAS_DIAM, 5, function(v)
    setAtur("BATAS_DIAM", v)
end)

local initialVehicles = (#rgOwnedVehicles > 0) and rgOwnedVehicles or { "Yamahax-MioSporty" }
local initialSelected = ATUR.SELECTED_BIKE or initialVehicles[1]

local VehicleDropdown = RideTab:Dropdown({
    Title  = "Vehicle",
    Values = initialVehicles,
    Value  = initialSelected,
    Callback = function(v)
        if type(v) == "string" and v ~= "" then
            ATUR.SELECTED_BIKE = v
        end
    end,
})

local function syncVehicleDropdown()
    local owned = rgFetchOwnedVehicles()
    if #owned > 0 then
        pcall(function()
            VehicleDropdown:Refresh(owned)
        end)
        pcall(function()
            if VehicleDropdown.Select then
                VehicleDropdown:Select(ATUR.SELECTED_BIKE)
            end
        end)
    end
end

task.spawn(function()
    task.wait(2.5)
    syncVehicleDropdown()
    local retryDeadline = os.clock() + 12
    while #rgOwnedVehicles <= 1 and os.clock() < retryDeadline do
        task.wait(2)
        syncVehicleDropdown()
    end
end)

-- ============================================================================
-- TAB: WEBHOOK
-- ============================================================================
local WebhookTab = Window:Tab({ Title = "Webhook", Icon = "link" })

WebhookTab:Toggle({
    Title   = "Auto Webhook",
    Default = false,
    Callback = function(state) _G.AutoWebhook = state end,
})

WebhookTab:Input({
    Title       = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback    = function(v) _G.WebhookURL = v end,
})

-- ============================================================================
-- TAB: MISC
-- ============================================================================
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })

MiscTab:Button({
    Title    = "Rejoin Server",
    Callback = function() RejoinServer() end,
})

MiscTab:Button({
    Title    = "Toggle Blackscreen",
    Callback = function()
        BlackScreen.Enabled = not BlackScreen.Enabled
        _G.PermanentBlackscreen = BlackScreen.Enabled
    end,
})

local StatsSection = MiscTab:Section({ Title = "Stats" })

task.spawn(function()
    while true do
        task.wait(5)
        local secs = getActiveSeconds()
        local hh   = math.floor(secs / 3600)
        local mm   = math.floor((secs % 3600) / 60)
        local ss   = math.floor(secs % 60)
        local farmTime = string.format("%02d:%02d:%02d", hh, mm, ss)
        pcall(function()
            StatsSection:Paragraph({
                Title   = "Earnings",
                Content = string.format(
                    "Total: %s\nCourier: %s\nBarista: %s\nPolice: %s\nRideGO: %s\nOrders: %d | Phase: %s\nFarm time: %s",
                    formatRP(_G.TotalEarning),
                    formatRP(_G.CourierEarned),
                    formatRP(_G.BaristaEarned),
                    formatRP(_G.PoliceEarned),
                    formatRP(_G.RideGOEarned),
                    rgS.orders or 0,
                    rgS.phase or "standby",
                    farmTime
                ),
            })
        end)
    end
end)

warn("[PROJECTSION × WINDUI] Loaded. Adonis bypass queued.")
