--[[
================================================================================
  ðŸ‘‘ KING AKBAR - ULTIMATE AUTO FARM SCRIPT ðŸ‘‘
================================================================================
    [+] Developer   : King Akbar
    [+] Game        : Drag Drive Simulator
    [+] Fitur       : + Auto RideGO Driver (Void Gate Ultra + Anti-Kick Stabil)
                      + Anti-Kick 3 Lapis (Hook + Random Keypress + Heartbeat F15)
                      + Auto-Recovery Respawn Karakter
                      + Dynamic Vehicle Selector (Scan Garasi)
                      + Dynamic Tracker Monitoring (Office / RideGO)
                      + Full Manual Activation (No Auto-Start)
    [+] Update      : Void TP dipercepat (VOID_STOP_TIME 0.08, HOP 600, jeda 0.05)
================================================================================
]]--

-- ============================================================================
-- // SILENT MODE (MATIKAN F9 CONSOLE)
-- ============================================================================
local print = function() end
local warn = function() end
local error = function() end

-- ============================================================================
-- // SAFE DESTROY (ANTI WARNING SPAM - F9 CLEAN)
-- ============================================================================
local function safeDestroy(obj)
    task.defer(function()
        pcall(function()
            if obj and obj.Parent then obj:Destroy() end
        end)
    end)
end

-- ============================================================================
-- // 0. ULTIMATE BYPASS "GACOR" â€” DDS TARGETED
-- ============================================================================
do
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local RS          = game:GetService("ReplicatedStorage")

    local function BLog(msg)  end
    local function BWarn(msg) end

    -- â”€â”€ [1] INDEXINSTANCE NEUTRALIZER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    pcall(function()
        if not getgc then return end
        for _, v in pairs(getgc(true)) do
            pcall(function()
                local idx = rawget(v, "indexInstance")
                if type(idx) == "table" and idx[1] == "kick" then
                    setreadonly(v, false)
                    v.tvk = { "kick", function() return game.Workspace:WaitForChild("") end }
                    BLog("IndexInstance kick dinetralkan")
                end
            end)
        end
    end)

    -- â”€â”€ [2] HTTP WEBHOOK BLOCKER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    pcall(function()
        local requestFunc =
            (syn and syn.request) or http_request or
            (fluxus and fluxus.request) or request or
            (http and http.request)
        if not requestFunc or not hookfunction then return end

        local oldReq = requestFunc
        hookfunction(requestFunc, function(opts)
            local url = string.lower(tostring(opts and (opts.Url or opts.url) or ""))
            local safe = url:find("roblox%.com") or url:find("rbxcdn%.com") or url == ""
            if not safe then
                BWarn("HTTP diblokir: " .. url)
                return { StatusCode = 200, Body = '{"success":true}', Success = true, Headers = {} }
            end
            return oldReq(opts)
        end)
        BLog("HTTP Blocker aktif")
    end)

    -- â”€â”€ [3] METATABLE HOOK â€” Anti-Kick + DDS Remote Blocker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    pcall(function()
        local mt = getrawmetatable(game)
        if not mt then return end
        local oldNamecall = rawget(mt, "__namecall")
        if not oldNamecall then return end
        if not pcall(setreadonly, mt, false) then return end

        local BLOCK_FIRE = {
            ["admin"]              = true,
            ["reportmessageevent"] = true,
            ["0bde16ec-a0df-43fe-ba4b-b1fca4f092ee"] = true,
        }
        local SPOOF_INVOKE = {
            ["requestadminstatus"] = false,
        }

        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""

            if (method:lower() == "kick" or method == "Disconnect")
                and tostring(self) == tostring(LocalPlayer)
            then
                if getgenv().allowSelfKick then
                    getgenv().allowSelfKick = false
                    return oldNamecall(self, ...)
                end
                BWarn("Kick diblokir!")
                return nil
            end

            if method == "FireServer" then
                local ok, name = pcall(function()
                    return string.lower(tostring(self.Name))
                end)
                if ok and BLOCK_FIRE[name] then
                    BWarn("FireServer diblokir: " .. name)
                    return nil
                end
            end

            if method == "InvokeServer" then
                local ok, name = pcall(function()
                    return string.lower(tostring(self.Name))
                end)
                if ok and SPOOF_INVOKE[name] ~= nil then
                    BWarn("InvokeServer dispoofed: " .. name)
                    return SPOOF_INVOKE[name]
                end
            end

            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        BLog("Metatable Hook aktif (Anti-Kick + Remote Blocker)")
    end)

    -- â”€â”€ [4] WRONGTEAMEVENT INTERCEPTOR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    task.spawn(function()
        local jobEv = RS:WaitForChild("JobEvents", 10)
        if not jobEv then return end
        local wte = jobEv:WaitForChild("WrongTeamEvent", 5)
        if not wte then return end
        wte.OnClientEvent:Connect(function()
            BWarn("WrongTeamEvent dari server â€” DIABAIKAN")
        end)
        BLog("WrongTeamEvent interceptor aktif")
    end)

    -- â”€â”€ [5] UUID AC REMOTE NEUTRALIZER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    task.spawn(function()
        local UUID = "0bde16ec-a0df-43fe-ba4b-b1fca4f092ee"
        local rem = RS:WaitForChild(UUID, 5)
        if not rem then BLog("UUID AC tidak aktif sesi ini") return end
        pcall(function()
            if rem:IsA("RemoteEvent") then
                rem.OnClientEvent:Connect(function()
                    BWarn("UUID AC fired â€” DIABAIKAN")
                end)
            end
        end)
        pcall(function()
            local fn = rem:FindFirstChildWhichIsA("RemoteFunction")
            if fn then fn.OnClientInvoke = function() return nil end end
        end)
        BLog("UUID AC dinetralkan: " .. UUID)
    end)

    -- â”€â”€ [6] SMART AC SCRIPT KILLER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local AC_KW = {
        "adonis","ae_","anticheat","anti_cheat","cheatdetect",
        "adminscript","bansystem","kicksystem","hackdetect",
        "exploitdetect","injectioncheck"
    }
    local killedSet = {}

    local function isAC(name)
        local low = string.lower(name)
        for _, kw in ipairs(AC_KW) do
            if low:find(kw, 1, true) then return true end
        end
        return false
    end

    local function killAC(parent)
        if not parent then return end
        pcall(function()
            for _, v in pairs(parent:GetChildren()) do
                local name = string.lower(v.Name)
                if isAC(name) then
                    pcall(function()
                        if v:IsA("LocalScript") or v:IsA("ModuleScript") or v:IsA("Script") then
                            if not v.Disabled then
                                v.Disabled = true
                                if not killedSet[v] then
                                    BWarn("AC Script dimatikan: " .. v.Name)
                                    killedSet[v] = true
                                end
                            end
                        end
                    end)
                    safeDestroy(v)
                end
            end
        end)
    end

    local gui_services = {
        LocalPlayer:WaitForChild("PlayerGui"),
        game:GetService("CoreGui"),
        gethui and gethui() or game:GetService("CoreGui"),
    }

    for _, svc in ipairs(gui_services) do pcall(killAC, svc) end

    task.spawn(function()
        while task.wait(3) do
            for _, svc in ipairs(gui_services) do pcall(killAC, svc) end
        end
    end)

    for _, svc in ipairs(gui_services) do
        pcall(function()
            svc.ChildAdded:Connect(function(child)
                if isAC(child.Name) then
                    pcall(function()
                        if child:IsA("LocalScript") or child:IsA("ModuleScript") or child:IsA("Script") then
                            child.Disabled = true
                            BWarn("AC Script baru dicegah: " .. child.Name)
                        end
                    end)
                    safeDestroy(child)
                end
            end)
        end)
    end

    BLog("Smart AC Killer aktif (scan 3s + ChildAdded monitor)")

    -- â”€â”€ [7] EXTERNAL BYPASS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    task.spawn(function()
        local ok1, e1 = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua", true))()
        end)
        BLog(ok1 and "AdonisCries loaded" or "AdonisCries gagal: " .. tostring(e1))

        task.wait(1)

        local ok2, e2 = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SUUUUUS00000/MEGGD-Anti-kick/refs/heads/main/MEGGD%20Best%20Anti-kick.lua"))()
        end)
        BLog(ok2 and "MEGGD Anti-Kick loaded" or "MEGGD gagal: " .. tostring(e2))
    end)
end

-- ============================================================================
-- // 1. LOAD WINDUI (SAFE)
-- ============================================================================
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
        ))()
    end)
    if ok and result then
        WindUI = result
    else
        WindUI = {
            CreateWindow = function() return {
                Tab            = function() return {
                    Paragraph  = function() return { Set = function() end } end,
                    Toggle     = function() end,
                    Button     = function() end,
                    Input      = function() end,
                    Slider     = function() end,
                    Section    = function() return {
                        Paragraph = function() return { Set = function() end } end,
                        Toggle    = function() end,
                        Button    = function() end,
                        Input     = function() end,
                        Slider    = function() end,
                    } end,
                    Select     = function() end,
                    Dropdown   = function() end,
                } end,
                Tag            = function() return { SetTitle = function() end } end,
                EditOpenButton = function() end,
                SetIconSize    = function() end,
            } end,
            Notify   = function() end,
            SetTheme = function() end,
            Gradient = function() return {} end,
        }
    end
end

-- ============================================================================
-- // 2. SERVICES & REFERENCES
-- ============================================================================
local Services = {
    Players             = game:GetService("Players"),
    RunService          = game:GetService("RunService"),
    TweenSvc            = game:GetService("TweenService"),
    UserInput           = game:GetService("UserInputService"),
    Stats               = game:GetService("Stats"),
    Workspace           = game:GetService("Workspace"),
    VirtualUser         = game:GetService("VirtualUser"),
    HttpService         = game:GetService("HttpService"),
    GuiService          = game:GetService("GuiService"),
    PathfindingService  = game:GetService("PathfindingService"),
    ReplicatedStorage   = game:GetService("ReplicatedStorage"),
    StarterGui          = game:GetService("StarterGui"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
}

local LocalPlayer = Services.Players.LocalPlayer

local IsMobile = Services.UserInput.TouchEnabled
    and not Services.UserInput.KeyboardEnabled
    and not Services.UserInput.MouseEnabled

local CharRef = {
    Character = nil,
    Humanoid  = nil,
    Root      = nil,
}

local function UpdateCharRef()
    CharRef.Character = LocalPlayer.Character
    if CharRef.Character then
        CharRef.Humanoid = CharRef.Character:WaitForChild("Humanoid", 5)
        CharRef.Root     = CharRef.Character:WaitForChild("HumanoidRootPart", 5)
    end
end
UpdateCharRef()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    UpdateCharRef()
end)

-- ============================================================================
-- // SAFE INPUT SYSTEM
-- ============================================================================
local function SafeClick(x, y, holdTime)
    holdTime = holdTime or 0.05
    pcall(function()
        if mousemover and mouse1press and mouse1release then
            mousemover(x, y)
            mouse1press(x, y)
            task.wait(holdTime)
            mouse1release(x, y)
        elseif mousemover and mouse1click then
            mousemover(x, y)
            task.wait(0.01)
            mouse1click()
        else
            Services.VirtualUser:Button1Down(Vector2.new(x, y))
            task.wait(holdTime)
            Services.VirtualUser:Button1Up(Vector2.new(x, y))
        end
    end)
end

-- ============================================================================
-- // 3. STATE MANAGER
-- ============================================================================
local State = {
    IsBaristaActive    = false,
    IsOfficeActive     = false,
    IsCourierActive    = false,
    IsRideGOActive     = false,
    AiThread           = nil,
    StatusText         = "Idling...",
    OrderCount         = 0,
    ActionDelay        = 5,
    AntiAFK            = true,
    AntiAdmin          = true,
    UangAwal           = 0,
    UangAwalSession    = 0,
    SessionStartTime   = 0,
    LastStopReason     = "",
    MachineFixCount    = 0,
    OfficeMathSolved   = 0,
    OfficePrints       = 0,
    CourierDelivered   = 0,
    FakeNameActive     = false,
    FakeName           = "King Akbar",
    TargetProfit       = 0,
    RideGOIsOnline     = false,
    RideGOPhase        = "idle",
    RideGOToken        = nil,
    RideGOTargetPos    = nil,
    RideGOTripCount    = 0,
    RideGOEarnings     = 0,
}

-- ============================================================================
-- // ANTI-KICK & KEEPALIVE 3 LAPIS (SUPER STABIL)
-- ============================================================================
pcall(function()
    if not hookmetamethod or not newcclosure or not getnamecallmethod then return end
    local _origNamecall
    _origNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
            if getgenv().allowSelfKick then
                getgenv().allowSelfKick = false
                return _origNamecall(self, ...)
            end
            return nil
        end
        return _origNamecall(self, ...)
    end))
end)

LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        pcall(function()
            Services.VirtualUser:CaptureController()
            Services.VirtualUser:ClickButton2(Vector2.new())
            Services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            Services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end)

task.spawn(function()
    local _keyPool = {
        Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
        Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.E,
    }
    while true do
        task.wait(math.random(50, 80))
        if State.AntiAFK then
            pcall(function()
                local k = _keyPool[math.random(1, #_keyPool)]
                Services.VirtualInputManager:SendKeyEvent(true, k, false, game)
                task.wait(0.04 + math.random() * 0.06)
                Services.VirtualInputManager:SendKeyEvent(false, k, false, game)
            end)
        end
    end
end)

do
    local _lastKA = tick()
    Services.RunService.Heartbeat:Connect(function()
        if tick() - _lastKA < 30 then return end
        _lastKA = tick()
        task.spawn(function()
            pcall(function()
                Services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
                task.wait(0.02)
                Services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
            end)
        end)
    end)
end

-- ============================================================================
-- // 3.5 FAKE NAME SYSTEM
-- ============================================================================
local OriginalDisplayName = LocalPlayer.DisplayName
local SpoofCache = {}

local function SpoofScan(char)
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            local t = obj.Text
            if t == LocalPlayer.Name or t == OriginalDisplayName or t == ("@" .. LocalPlayer.Name) then
                if SpoofCache[obj] == nil then SpoofCache[obj] = t end
                obj.Text = State.FakeName
            end
        end
    end
end

local function SpoofRestore()
    for obj, original in pairs(SpoofCache) do
        pcall(function()
            if obj.Parent then obj.Text = original end
        end)
    end
    SpoofCache = {}
end

local function SpoofApplyNow()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.DisplayName = State.FakeName end
        SpoofScan(char)
    end)
end

local function SpoofDisableNow()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayName = OriginalDisplayName end
        end
    end)
    SpoofRestore()
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if State.FakeNameActive then
        SpoofCache = {}
        pcall(function()
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then hum.DisplayName = State.FakeName end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not State.FakeNameActive then continue end
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.DisplayName ~= State.FakeName then
                hum.DisplayName = State.FakeName
            end
            SpoofScan(char)
        end)
    end
end)

-- ============================================================================
-- // 4. HUMANIZATION (RNG WAIT)
-- ============================================================================
local function rWait(minSec, maxSec)
    task.wait(math.random((minSec or 0.5) * 1000, (maxSec or 1.5) * 1000) / 1000)
end

-- ============================================================================
-- // 5. GetPlayerMoney
-- ============================================================================
local function GetPlayerMoney()
    local money = 0
    pcall(function()
        if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Money") then
            money = LocalPlayer.leaderstats.Money.Value
        elseif LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Money") then
            money = LocalPlayer.Data.Money.Value
        else
            for _, v in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible and string.find(v.Text, "Rp%.") then
                    local m = tonumber(string.gsub(v.Text, "[^%d]", ""))
                    if m and m > money then money = m end
                end
            end
        end
    end)
    return money
end

-- ============================================================================
-- // 6. ADMIN SENSOR
-- ============================================================================
local GAME_GROUP_ID  = 11378976
local MIN_STAFF_RANK = 2

local BlacklistedNames = {
    "slametriyadi",
    "admin",
    "moderator",
    "developer"
}

local function CheckForAdmin(player)
    if not State.AntiAdmin or player == LocalPlayer then return end
    local isStaff = false
    local pName = string.lower(player.Name)
    local dName = string.lower(player.DisplayName)
    for _, badName in ipairs(BlacklistedNames) do
        if pName:find(badName) or dName:find(badName) then
            isStaff = true; break
        end
    end
    if not isStaff then
        pcall(function()
            local rank = player:GetRankInGroup(GAME_GROUP_ID)
            if rank >= MIN_STAFF_RANK then isStaff = true end
        end)
    end
    if not isStaff then
        pcall(function()
            local chatTag = player:GetAttributeInHierarchy("ChatTags") or player:GetAttribute("IsAdmin")
            if chatTag then isStaff = true end
        end)
    end
    if isStaff then
        State.LastStopReason = "Admin detected: " .. player.Name
        rWait(0.2, 0.5)
        getgenv().allowSelfKick = true
        LocalPlayer:Kick("ðŸš¨ " .. player.Name .. " (Admin) joined! Leaving for safety.")
    end
end

for _, p in ipairs(Services.Players:GetPlayers()) do CheckForAdmin(p) end
Services.Players.PlayerAdded:Connect(CheckForAdmin)

local TextChatService = game:GetService("TextChatService")
pcall(function()
    TextChatService.MessageReceived:Connect(function(message)
        if not State.AntiAdmin then return end
        local text = string.lower(message.Text or "")
        local sender = message.TextSource
        if sender then
            local player = Services.Players:GetPlayerByUserId(sender.UserId)
            if player and player ~= LocalPlayer then
                if text:find("%[admin%]") or text:find("%[mod%]") or text:find("%[owner%]") or text:find("%[staff%]") then
                    State.LastStopReason = "Admin chat detected: " .. player.Name
                    rWait(0.2, 0.5)
                    getgenv().allowSelfKick = true
                    LocalPlayer:Kick("ðŸš¨ Admin chatting detected! Leaving server!")
                end
            end
        end
    end)
end)

-- ============================================================================
-- // 7. SPLASH SCREEN
-- ============================================================================
do
    local sg = Instance.new("ScreenGui")
    sg.Name = "BaristaSplash"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 999
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame", sg)
    bg.Size = UDim2.fromScale(1,1); bg.BackgroundColor3 = Color3.fromHex("#0a0a0a")
    bg.BorderSizePixel = 0; bg.ZIndex = 1

    local grad = Instance.new("UIGradient", bg)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#0a0a0a")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#1e1e1e")),
    }); grad.Rotation = 135

    local ct = Instance.new("Frame", bg)
    ct.Size = UDim2.fromOffset(500, 300); ct.Position = UDim2.fromScale(0.5, 0.5)
    ct.AnchorPoint = Vector2.new(0.5, 0.5); ct.BackgroundTransparency = 1; ct.ZIndex = 2

    local function mkLabel(txt, yOff, sz)
        local l = Instance.new("TextLabel", ct)
        l.Size = UDim2.fromOffset(500, 70); l.Position = UDim2.fromOffset(0, yOff)
        l.BackgroundTransparency = 1; l.Text = txt; l.TextSize = sz
        l.Font = Enum.Font.GothamBold; l.TextColor3 = Color3.fromHex("#ffffff")
        l.TextTransparency = 1; l.ZIndex = 3; return l
    end

    local icon = Instance.new("ImageLabel", ct)
    icon.Size = UDim2.fromOffset(120, 120); icon.Position = UDim2.fromOffset(190, -40)
    icon.BackgroundTransparency = 1; icon.Image = "rbxassetid://91115084979317"
    icon.ImageTransparency = 1; icon.ZIndex = 3

    local title = mkLabel("King Akbar", 70, IsMobile and 38 or 50)
    local tg = Instance.new("UIGradient", title)
    tg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHex("#ffffff")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("#aaaaaa")),
        ColorSequenceKeypoint.new(1,   Color3.fromHex("#555555")),
    }); tg.Rotation = 45

    local stat = mkLabel("Preparing combat engine...", 200, 12)
    stat.Font = Enum.Font.Gotham; stat.TextColor3 = Color3.fromHex("#555555")
    stat.TextXAlignment = Enum.TextXAlignment.Left; stat.Position = UDim2.fromOffset(50, 200)

    local line = Instance.new("Frame", ct)
    line.Size = UDim2.fromOffset(0, 2); line.Position = UDim2.fromOffset(250, 152)
    line.AnchorPoint = Vector2.new(0.5, 0); line.BackgroundColor3 = Color3.fromHex("#444444")
    line.BorderSizePixel = 0; line.ZIndex = 3

    local barBg = Instance.new("Frame", ct)
    barBg.Size = UDim2.fromOffset(400, 5); barBg.Position = UDim2.fromOffset(50, 190)
    barBg.BackgroundColor3 = Color3.fromHex("#222222"); barBg.BackgroundTransparency = 1
    barBg.BorderSizePixel = 0; barBg.ZIndex = 3
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame", barBg)
    bar.Size = UDim2.fromOffset(0, 5); bar.BackgroundColor3 = Color3.fromHex("#ffffff")
    bar.BorderSizePixel = 0; bar.ZIndex = 4
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local function tw(obj, props, t)
        Services.TweenSvc:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
    end

    task.spawn(function()
        tw(icon,  { ImageTransparency = 0 }, 0.5); task.wait(0.15)
        tw(title, { TextTransparency  = 0 }, 0.6); task.wait(0.35)
        tw(line,  { Size = UDim2.fromOffset(400, 2) }, 0.7); task.wait(0.4)
        tw(barBg, { BackgroundTransparency = 0 }, 0.3)
        tw(stat,  { TextTransparency = 0 }, 0.3)

        for _, s in ipairs({
            { "Preparing RNG Bot...", 0.30 },
            { "Activating Emergency Alarm...", 0.60 },
            { "Welcome, King Akbar!", 1.00 },
        }) do
            stat.Text = s[1]
            tw(bar, { Size = UDim2.fromOffset(400 * s[2], 5) }, 0.5)
            task.wait(0.55)
        end

        task.wait(0.3)
        for _, p in ipairs({ bg, icon, title, line, barBg, bar, stat }) do
            local prop = p == stat and "TextTransparency"
                or (p == icon  and "ImageTransparency" or "BackgroundTransparency")
            if p == title then prop = "TextTransparency" end
            tw(p, { [prop] = 1 }, 0.4)
        end
        task.wait(0.8); sg:Destroy()
    end)
    task.wait(3)
end

-- ============================================================================
-- // 8. CONSTANTS & PATHS (BARISTA)
-- ============================================================================
local Constants = {
    START_SHIFT  = Vector3.new(-4991.23, 4.29, -715.26),
    COLOR_ORANGE = Color3.fromRGB(230, 150, 30),
    COLOR_GREEN  = Color3.fromRGB(30,  180, 60),
}

local Paths = {
    START_TO_MACHINE = {
        Vector3.new(-4991.23, 4.29, -715.26), Vector3.new(-5004.86, 4.29, -718.90),
        Vector3.new(-5006.28, 4.29, -802.11), Vector3.new(-4994.18, 4.29, -801.66),
        Vector3.new(-4994.62, 4.29, -794.89), Vector3.new(-4997.13, 4.29, -794.57),
        Vector3.new(-4998.16, 4.29, -794.80),
    },
    MACHINE_TO_CASHIER = {
        Vector3.new(-4997.13, 4.29, -794.57), Vector3.new(-4994.62, 4.29, -794.89),
        Vector3.new(-4995.56, 4.29, -759.78),
    },
    CASHIER_TO_MACHINE = {
        Vector3.new(-4994.62, 4.29, -794.89), Vector3.new(-4997.13, 4.29, -794.57),
        Vector3.new(-4998.16, 4.29, -794.80),
    },
    MACHINE_TO_START = {
        Vector3.new(-4998.16, 4.29, -794.80), Vector3.new(-4997.13, 4.29, -794.57),
        Vector3.new(-4994.62, 4.29, -794.89), Vector3.new(-4994.18, 4.29, -801.66),
        Vector3.new(-5006.28, 4.29, -802.11), Vector3.new(-5004.86, 4.29, -718.90),
        Vector3.new(-4991.23, 4.29, -715.26),
    },
    CASHIER_TO_START = {
        Vector3.new(-4995.56, 4.29, -759.78), Vector3.new(-4994.62, 4.29, -794.89),
        Vector3.new(-4994.18, 4.29, -801.66), Vector3.new(-5006.28, 4.29, -802.11),
        Vector3.new(-5004.86, 4.29, -718.90), Vector3.new(-4991.23, 4.29, -715.26),
    },
    MACHINE_TO_FIX = {
        Vector3.new(-4998.14, 4.29, -795.38), Vector3.new(-4997.02, 4.29, -802.18),
        Vector3.new(-5006.31, 4.29, -802.30), Vector3.new(-5003.75, 4.29, -711.60),
        Vector3.new(-5004.43, 3.19, -670.40), Vector3.new(-5114.86, 3.19, -670.41),
    },
    FIX_TO_MACHINE = {
        Vector3.new(-5114.86, 3.19, -670.41), Vector3.new(-5004.43, 3.19, -670.40),
        Vector3.new(-5003.75, 4.29, -711.60), Vector3.new(-5006.31, 4.29, -802.30),
        Vector3.new(-4997.02, 4.29, -802.18), Vector3.new(-4998.14, 4.29, -795.38),
    },
}

-- ============================================================================
-- // 9. PERFORMANCE SYSTEMS
-- ============================================================================
local BlackGui
local function ToggleBlackScreen(on)
    pcall(function() Services.RunService:Set3dRenderingEnabled(not on) end)
    if on then
        if not BlackGui then
            BlackGui = Instance.new("ScreenGui")
            BlackGui.Name = "BlackScreenSaver"; BlackGui.IgnoreGuiInset = true
            BlackGui.DisplayOrder = 9999; BlackGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            local f = Instance.new("Frame", BlackGui)
            f.Size = UDim2.fromScale(1,1); f.BackgroundColor3 = Color3.new(0,0,0)
            local t = Instance.new("TextLabel", f)
            t.Text = "ðŸŒ‘ POWER SAVING MODE ACTIVE ðŸŒ‘\nKing Akbar is farming..."
            t.Size = UDim2.fromScale(1,1); t.TextColor3 = Color3.new(1,1,1)
            t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = 20
        end
        BlackGui.Enabled = true
    else
        if BlackGui then BlackGui.Enabled = false end
    end
end

local AntiLagActive = false
local AntiLagConn = nil
local PotatoActive = false
local PotatoConns = {}

local LAG_CLASSES = {
    "ParticleEmitter", "Smoke", "Fire", "Explosion", "Beam", "Trail", "Sparkles"
}

local function isLaggy(inst)
    for _, c in ipairs(LAG_CLASSES) do
        if inst:IsA(c) then return true end
    end
    return false
end

local function ToggleAntiLag(on)
    if on and PotatoActive then PotatoActive = false end
    AntiLagActive = on
    if on then
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function() game:GetService("Lighting").GlobalShadows = false end)
        task.spawn(function()
            for _, v in pairs(Services.Workspace:GetDescendants()) do
                if isLaggy(v) then safeDestroy(v) end
            end
        end)
        if not AntiLagConn then
            AntiLagConn = Services.Workspace.DescendantAdded:Connect(function(v)
                if AntiLagActive and isLaggy(v) then safeDestroy(v) end
            end)
        end
    else
        if AntiLagConn then AntiLagConn:Disconnect(); AntiLagConn = nil end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        pcall(function() game:GetService("Lighting").GlobalShadows = true end)
    end
end

local function TogglePotatoMode(on)
    if on and AntiLagActive then ToggleAntiLag(false) end
    PotatoActive = on
    if on then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function()
            local Lighting = game:GetService("Lighting")
            Lighting.GlobalShadows = false; Lighting.FogEnd = 10
            Lighting.Brightness = 0; Lighting.TimeOfDay = "12:00:00"
            for _, v in pairs(Lighting:GetDescendants()) do
                if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("Clouds") then
                    pcall(function() v.Enabled = false end)
                end
            end
        end)
        task.spawn(function()
            for _, v in pairs(Services.Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or
                   v:IsA("Explosion") or v:IsA("Beam") or v:IsA("Trail") or
                   v:IsA("Sparkles") or v:IsA("Sound") or v:IsA("Decal") or
                   v:IsA("Texture") or v:IsA("PointLight") or v:IsA("SpotLight") or
                   v:IsA("SurfaceLight") then
                    safeDestroy(v)
                elseif v:IsA("MeshPart") then
                    pcall(function() v.TextureID = ""; v.MeshId = "" end)
                elseif v:IsA("BasePart") then
                    pcall(function() v.Material = Enum.Material.SmoothPlastic end)
                end
            end
        end)
        pcall(function()
            Services.Workspace.Terrain:Clear()
            Services.Workspace.Terrain.WaterWaveSize = 0
        end)
        local c1 = Services.Workspace.DescendantAdded:Connect(function(v)
            if not PotatoActive then return end
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or
               v:IsA("Explosion") or v:IsA("Beam") or v:IsA("Trail") or
               v:IsA("Sparkles") or v:IsA("Sound") or v:IsA("Decal") or
               v:IsA("Texture") or v:IsA("PointLight") or v:IsA("SpotLight") or
               v:IsA("SurfaceLight") then
                safeDestroy(v)
            elseif v:IsA("MeshPart") then
                pcall(function() v.TextureID = ""; v.MeshId = "" end)
            elseif v:IsA("BasePart") then
                pcall(function() v.Material = Enum.Material.SmoothPlastic end)
            end
        end)
        table.insert(PotatoConns, c1)
    else
        for _, conn in ipairs(PotatoConns) do pcall(function() conn:Disconnect() end) end
        PotatoConns = {}
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        pcall(function()
            game:GetService("Lighting").GlobalShadows = true
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").Brightness = 2
        end)
    end
end

-- ============================================================================
-- // 10. UTILITY (BARISTA)
-- ============================================================================
local function WalkToPoint(pos)
    if not CharRef.Humanoid or not CharRef.Root then return end
    if CharRef.Humanoid.Sit then
        CharRef.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.wait(0.2)
    end
    local hp = pos + Vector3.new(math.random(-15,15)/10, 0, math.random(-15,15)/10)
    CharRef.Humanoid:MoveTo(hp)
    local t = 10
    while t > 0 and State.IsBaristaActive do
        local d = Vector3.new(CharRef.Root.Position.X, 0, CharRef.Root.Position.Z)
               - Vector3.new(hp.X, 0, hp.Z)
        if d.Magnitude < 3 then break end
        task.wait(0.1); t -= 0.1
    end
end

local function FollowPath(arr)
    for _, p in ipairs(arr) do
        if not State.IsBaristaActive then break end
        WalkToPoint(p)
    end
end

local function FindPrompt(kw, maxD, origin)
    if not CharRef.Root then return nil end
    origin = origin or CharRef.Root.Position; maxD = maxD or 20
    local found, closest = nil, maxD
    for _, v in pairs(Services.Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled
            and string.find(string.lower(v.ActionText), string.lower(kw))
        then
            local part = v.Parent
            if part and part:IsA("BasePart") then
                local d = (part.Position - origin).Magnitude
                if d < closest then closest = d; found = v end
            end
        end
    end
    return found
end

local function DoHold(prompt)
    if not prompt then return false end
    pcall(function()
        prompt:InputHoldBegin()
        rWait((prompt.HoldDuration or 1) + 0.2, (prompt.HoldDuration or 1) + 0.6)
        prompt:InputHoldEnd()
    end)
    rWait(0.1, 0.3); return true
end

local function DoTap(prompt)
    if not prompt then return false end
    pcall(function()
        prompt:InputHoldBegin(); rWait(0.08, 0.18); prompt:InputHoldEnd()
    end)
    rWait(0.2, 0.4); return true
end

local function IsMachineBroken()
    for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible then
                local t = string.lower(v.Text)
                if t:find("machine broke") or t:find("needs maintenance") or t:find("fix machine") then
                    return true
                end
            end
        end
    end
    return false
end

local function HasJob()
    local hasJob = true
    for _, v in pairs(Services.Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled and v.ActionText:lower():find("shift") then
            local part = v.Parent
            if part and part:IsA("BasePart") and (part.Position - Constants.START_SHIFT).Magnitude < 40 then
                hasJob = v.ActionText:lower():find("end") and true or false
                break
            end
        end
    end
    return hasJob
end

local function FindByColor(parent, col, tol)
    local best, bestD = nil, math.huge
    for _, v in pairs(parent:GetDescendants()) do
        if (v:IsA("Frame") or v:IsA("ImageLabel")) and v.Visible and v.BackgroundTransparency < 0.8 then
            local c = v:IsA("ImageLabel") and v.ImageColor3 or v.BackgroundColor3
            local d = math.abs(c.R-col.R) + math.abs(c.G-col.G) + math.abs(c.B-col.B)
            if d < bestD then bestD = d; best = v end
        end
    end
    return bestD < (tol or 0.6) and best or nil
end

-- ============================================================================
-- // 11. AI MINIGAME (BARISTA)
-- ============================================================================
local function StartMinigameAI()
    if State.AiThread then task.cancel(State.AiThread) end
    State.AiThread = task.spawn(function()
        local cam = Services.Workspace.CurrentCamera
        while State.IsBaristaActive do
            task.wait(0.016)
            local gui = LocalPlayer.PlayerGui:FindFirstChild("BaristaGUI")
            if not gui then task.wait(0.1); continue end
            local mf = gui:FindFirstChild("MinigameFrame", true)
            if not (mf and mf.Visible) then task.wait(0.1); continue end

            local cx = (cam.ViewportSize.X/2) + math.random(-15,15)
            local cy = (cam.ViewportSize.Y/2) + math.random(-15,15)
            local pill, bar = nil, nil

            for _, v in pairs(mf:GetDescendants()) do
                if v:IsA("Frame") or v:IsA("ImageLabel") then
                    local nm = v.Name:lower()
                    if nm:find("pill") or nm:find("indicator") or nm:find("player") or nm:find("handle") then pill = v end
                    if nm:find("target") or nm:find("zone") or nm:find("goal") or nm:find("safe") then bar = v end
                end
            end

            if not pill then pill = FindByColor(mf, Constants.COLOR_ORANGE, 0.6) end
            if not bar  then bar  = FindByColor(mf, Constants.COLOR_GREEN,  0.6) end

            if not pill or not bar then
                local els = {}
                for _, v in pairs(mf:GetDescendants()) do
                    if (v:IsA("Frame") or v:IsA("ImageLabel")) and v.Visible
                        and v.BackgroundTransparency < 0.9 and v.AbsoluteSize.Y > 10
                    then table.insert(els, v) end
                end
                table.sort(els, function(a,b) return a.AbsolutePosition.X < b.AbsolutePosition.X end)
                if #els >= 2 then pill = els[1]; bar = els[#els] end
            end

            if pill and bar then
                local diff = (pill.AbsolutePosition.Y + pill.AbsoluteSize.Y/2)
                           - (bar.AbsolutePosition.Y  + bar.AbsoluteSize.Y/2)
                if diff > 6 then
                    SafeClick(cx, cy, math.random(55,90)/1000)
                    task.wait(math.random(30,60)/1000)
                elseif diff < -6 then
                    task.wait(0.016)
                else
                    SafeClick(cx, cy, math.random(50,80)/1000)
                    task.wait(math.random(80,130)/1000)
                end
            else
                SafeClick(cx, cy, math.random(55,90)/1000)
                task.wait(math.random(60,100)/1000)
            end
        end
    end)
end

-- ============================================================================
-- // 12. BARISTA FARMING LOOP
-- ============================================================================
local function TakeJob()
    State.StatusText = "ðŸƒ Walking to start shift..."
    WalkToPoint(Constants.START_SHIFT); rWait(0.4, 0.8)
    local sp = FindPrompt("start shift", 30) or FindPrompt("shift", 30)
    if sp and sp.ActionText:lower():find("start") then
        State.StatusText = "ðŸ’¼ Shift started!"
        DoTap(sp); rWait(0.8, 1.5)
    end
end

local function HasPendingOrder()
    local mp = Paths.START_TO_MACHINE[#Paths.START_TO_MACHINE]
    return FindPrompt("brewing", 40, mp) or FindPrompt("brew", 40, mp) or FindPrompt("make", 40, mp) ~= nil
end

local function BaristaFarmLoop()
    local isAtCashier = false
    while State.IsBaristaActive do
        if not CharRef.Character or not CharRef.Character.Parent then
            UpdateCharRef()
        end

        if not HasJob() then
            State.StatusText = "âš ï¸ Shift ended, restarting..."
            local dm = (CharRef.Root.Position - Paths.START_TO_MACHINE[#Paths.START_TO_MACHINE]).Magnitude
            local dc = (CharRef.Root.Position - Paths.MACHINE_TO_CASHIER[#Paths.MACHINE_TO_CASHIER]).Magnitude
            FollowPath(dm < dc and Paths.MACHINE_TO_START or Paths.CASHIER_TO_START)
            TakeJob()
            State.StatusText = "ðŸš¶ Returning to workstation..."
            FollowPath(Paths.START_TO_MACHINE); isAtCashier = false; continue
        end

        while not HasPendingOrder() and not IsMachineBroken() and State.IsBaristaActive do
            State.StatusText = "Waiting for customers..."; task.wait(1)
        end
        if not State.IsBaristaActive then continue end
        if not HasJob() then continue end

        if IsMachineBroken() then
            State.StatusText = "Machine broken, fixing..."
            if isAtCashier then FollowPath(Paths.CASHIER_TO_MACHINE); isAtCashier = false end
            FollowPath(Paths.MACHINE_TO_FIX); rWait(0.4, 0.8)
            local fix = FindPrompt("fix",20) or FindPrompt("repair",20) or FindPrompt("clean",20) or FindPrompt("maintain",20)
            if fix then DoHold(fix)
            else
                for _, v in pairs(Services.Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and v.Enabled then
                        local p = v.Parent
                        if p and p:IsA("BasePart") and (p.Position - CharRef.Root.Position).Magnitude < 15 then DoHold(v) end
                    end
                end
            end
            rWait(0.4, 0.8)
            State.MachineFixCount = (State.MachineFixCount or 0) + 1
            FollowPath(Paths.FIX_TO_MACHINE); continue
        end

        if HasPendingOrder() then
            if isAtCashier then
                FollowPath(Paths.CASHIER_TO_MACHINE); isAtCashier = false
            else
                WalkToPoint(Paths.START_TO_MACHINE[#Paths.START_TO_MACHINE])
            end

            local mp = Paths.START_TO_MACHINE[#Paths.START_TO_MACHINE]
            local bp = FindPrompt("brewing",30,mp) or FindPrompt("brew",30,mp) or FindPrompt("make",30,mp)
            if bp then
                State.StatusText = "Brewing coffee..."; DoTap(bp); rWait(0.8, 1.2)
                while State.IsBaristaActive do
                    local g = LocalPlayer.PlayerGui:FindFirstChild("BaristaGUI")
                    local m = g and g:FindFirstChild("MinigameFrame", true)
                    if not m or not m.Visible then break end; task.wait(0.5)
                end
            end
            rWait(0.8, 1.5)

            local dp = FindPrompt("take",25,mp) or FindPrompt("grab",25,mp)
            if dp then DoTap(dp) end; rWait(0.3, 0.7)

            local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool") or CharRef.Character:FindFirstChildOfClass("Tool")
            if tool then CharRef.Humanoid:EquipTool(tool) end

            State.StatusText = "ðŸš¶ Delivering coffee..."
            FollowPath(Paths.MACHINE_TO_CASHIER); isAtCashier = true

            local attempt = 0
            while CharRef.Character:FindFirstChildOfClass("Tool") and State.IsBaristaActive and attempt < 5 do
                local sp2 = FindPrompt("serve",25) or FindPrompt("deliver",25)
                if sp2 then DoHold(sp2) else break end
                attempt += 1; rWait(0.4, 0.7)
            end

            if not CharRef.Character:FindFirstChildOfClass("Tool") then
                State.OrderCount += 1
                State.StatusText = "âœ… Coffee sold! Total: " .. State.OrderCount
            end

            local delay = State.ActionDelay + math.random(-5, 10) / 10
            rWait(delay, delay + 0.5)
        end
    end
end

local function StartBaristaScript()
    if State.IsBaristaActive then return end
    State.IsBaristaActive = true
    State.UangAwal = GetPlayerMoney()
    State.UangAwalSession = State.UangAwal
    State.SessionStartTime = os.time()
    State.LastStopReason = ""
    State.MachineFixCount = 0
    task.spawn(function() TakeJob(); StartMinigameAI(); BaristaFarmLoop() end)
end

local function StopBaristaScript(reason)
    State.IsBaristaActive = false
    State.StatusText = "Idling..."
    State.LastStopReason = reason or "User manually stopped Barista"
    if CharRef.Humanoid and CharRef.Root then
        CharRef.Humanoid:MoveTo(CharRef.Root.Position)
    end
end

-- ============================================================================
-- // 13. OFFICE JOB SYSTEM & MONITORING
-- ============================================================================
local playerGui       = LocalPlayer:WaitForChild("PlayerGui")
local ComputersFolder = workspace:WaitForChild("Computers")

local function hasText(str, keyword)
    return str and string.find(string.lower(str), string.lower(keyword)) ~= nil
end

local function eksekusiPromptTahan(pp)
    if not pp then return end
    if (pp.HoldDuration or 0) > 0 then DoHold(pp) else DoTap(pp) end
end

local myChair = nil

local function jalanKe(pos)
    local root = CharRef.Root
    local hum = CharRef.Humanoid
    if not root or not hum then return false end
    local targetPos = pos + Vector3.new(math.random(-12,12)/10, 0, math.random(-12,12)/10)
    local path = Services.PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true
    })
    local success, _ = pcall(function()
        path:ComputeAsync(root.Position, targetPos)
    end)
    if success and path.Status == Enum.PathStatus.Success then
        for _, waypoint in ipairs(path:GetWaypoints()) do
            if not State.IsOfficeActive then break end
            if waypoint.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
            hum:MoveTo(waypoint.Position)
            local t = 0
            while (root.Position - waypoint.Position).Magnitude > 3.5 do
                task.wait(0.02); t += 0.02
                if t > 1.5 or not State.IsOfficeActive then break end
            end
        end
        return true
    else
        hum:MoveTo(targetPos)
        hum.MoveToFinished:Wait(3)
        return true
    end
end

local function keluarKursi()
    local hum = CharRef.Humanoid
    if not hum then return end
    if hum.SeatPart then
        myChair = hum.SeatPart
        task.wait(math.random(10, 20)/10)
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.3)
    end
end

local function getSeatFromChair(chair)
    if not chair then return nil end
    if chair:IsA("Seat") or chair:IsA("VehicleSeat") then return chair end
    return chair:FindFirstChildWhichIsA("Seat") or chair:FindFirstChildWhichIsA("VehicleSeat")
end

local function findOfficeSeat(excludeSeat)
    local origin = CharRef.Root and CharRef.Root.Position
    if not origin then return nil end
    local best, bestD = nil, math.huge
    for _, v in pairs(ComputersFolder:GetDescendants()) do
        if v:IsA("Model") and v.Name == "Setup" then
            local seat = v:FindFirstChild("Seat", true)
            if seat and seat:IsA("Seat") and seat ~= excludeSeat then
                if not seat.Occupant or seat.Occupant == CharRef.Humanoid then
                    local d = (seat.Position - origin).Magnitude
                    if d < bestD then bestD = d; best = seat end
                end
            end
        end
    end
    return best
end

local function joinOfficeTeam()
    pcall(function()
        Services.ReplicatedStorage:WaitForChild("JobEvents")
            :WaitForChild("TeamChangeRequest")
            :FireServer("Office Worker", 0, 1, 0, "")
    end)
end

local function dudukKeKursi(instantTP)
    local hum = CharRef.Humanoid
    if not hum then return false end
    if hum.SeatPart then return true end

    if State.IsOfficeActive then
        if not myChair or (myChair.Occupant and myChair.Occupant ~= hum) then
            myChair = findOfficeSeat()
        end
    end

    if not myChair then return false end
    if not instantTP then keluarKursi() end

    local seat = getSeatFromChair(myChair)
    local handle = myChair:FindFirstChild("Handle")
    local targetCFrame = seat and seat.CFrame
        or (handle and handle.CFrame)
        or (myChair:IsA("BasePart") and myChair.CFrame)
        or (myChair.PrimaryPart and myChair.PrimaryPart.CFrame)

    if not targetCFrame then return false end

    if instantTP then
        if CharRef.Root then CharRef.Root.CFrame = targetCFrame; task.wait(0.1) end
        if seat then seat:Sit(hum); task.wait(1.5); return true
        else
            for _, child in pairs(myChair:GetChildren()) do
                if child:IsA("ProximityPrompt") and child.Enabled then
                    eksekusiPromptTahan(child); task.wait(1.5); return true
                end
            end
        end
    else
        jalanKe(targetCFrame.Position + Vector3.new(0, 2, 0))
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        if seat then seat:Sit(hum); task.wait(1.5); return true
        else
            for _, child in pairs(myChair:GetChildren()) do
                if child:IsA("ProximityPrompt") and child.Enabled then
                    eksekusiPromptTahan(child); task.wait(1.5); return true
                end
            end
        end
    end
    return false
end

-- ============================================================================
-- // AUTO JAWAB SOAL MATEMATIKA (OFFICE)
-- ============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local JobEvents = ReplicatedStorage:WaitForChild("JobEvents")
local GenerateQuestion = JobEvents:WaitForChild("GenerateQuestion")
local CorrectAnswer = JobEvents:WaitForChild("CorrectAnswer")

local function evaluateMath(text)
    local cleanText = string.gsub(text, "<[^>]+>", "")
    cleanText = string.gsub(cleanText, "%s+", "")
    local a, op, b = string.match(cleanText, "(%-?%d+%.?%d*)([%+%-])(%-?%d+%.?%d*)")
    if not a or not op or not b then return nil end
    a, b = tonumber(a), tonumber(b)
    if op == "+" then return a + b
    elseif op == "-" then return a - b end
    return nil
end

local function getAnswerButtons()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("WorkGui")
    local frame = gui and gui:FindFirstChild("Frame")
    if not frame then return {} end
    local list = {}
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("GuiButton") then table.insert(list, child) end
    end
    return list
end

local function findCorrectButton(jawaban, timeoutSec)
    local deadline = tick() + (timeoutSec or 2.5)
    while tick() < deadline do
        for _, btn in ipairs(getAnswerButtons()) do
            local numText = string.match(tostring(btn.Text or ""), "%-?%d+%.?%d*")
            if tonumber(numText) == jawaban and btn:IsDescendantOf(game) then
                return btn
            end
        end
        task.wait(0.1)
    end
    return nil
end

local function clearHighlights()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("WorkGui")
    if not gui then return end
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj.Name == "AutoMathHighlight" then safeDestroy(obj) end
    end
end

local function highlightButton(btn)
    clearHighlights()
    local stroke = Instance.new("UIStroke")
    stroke.Name = "AutoMathHighlight"
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Parent = btn
    TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Thickness = 7}):Play()
end

local function unhighlightLater(btn, delaySec)
    task.delay(delaySec, function()
        local s = btn:FindFirstChild("AutoMathHighlight")
        if s then
            TweenService:Create(s, TweenInfo.new(0.2), {Thickness = 0}):Play()
            task.delay(0.25, function() safeDestroy(s) end)
        end
    end)
end

local function pressButton(btn)
    if getconnections then
        for _, signal in ipairs({btn.MouseButton1Click, btn.Activated}) do
            for _, conn in ipairs(getconnections(signal)) do
                if conn.Function then
                    if pcall(conn.Function) then return "handler-asli" end
                end
            end
        end
    end
    local ok = pcall(function()
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        SafeClick(pos.X + size.X / 2, pos.Y + size.Y / 2, 0.06)
    end)
    if ok then return "safe-click" end
    return nil
end

local lastActivityTime = tick()

GenerateQuestion.OnClientEvent:Connect(function(questionText, answerData, sessionID)
    if State and State.IsOfficeActive == false then return end
    lastActivityTime = tick()

    local jawaban = evaluateMath(questionText)
    if not jawaban then return end

    local correctAnswerID = nil
    if type(answerData) == "table" then
        for _, data in ipairs(answerData) do
            local numText = string.match(tostring(data.Text or ""), "%-?%d+%.?%d*")
            if tonumber(numText) == jawaban then
                correctAnswerID = data.ID; break
            end
        end
    end

    local correctButton = findCorrectButton(jawaban, 2.5)
    if correctButton then highlightButton(correctButton) end
    task.wait(math.random(15, 30) / 10)

    if correctButton then
        local reText = string.match(tostring(correctButton.Text or ""), "%-?%d+%.?%d*")
        if not correctButton:IsDescendantOf(game) or tonumber(reText) ~= jawaban then
            correctButton = findCorrectButton(jawaban, 0.5)
        end
    end

    if correctButton then
        pressButton(correctButton)
        unhighlightLater(correctButton, 0.4)
    else
        clearHighlights()
    end

    if State then State.OfficeMathSolved = (State.OfficeMathSolved or 0) + 1 end
end)

-- ============================================================================
-- // OFFICE STABILITY ENGINE
-- ============================================================================
task.spawn(function()
    while true do
        task.wait(2)
        if not State.IsOfficeActive then continue end
        if getgenv().isGoingToPrinter or isSwitching then continue end

        local hum = CharRef.Humanoid
        if not hum then continue end

        if not hum.SeatPart then
            pcall(function()
                local seat = findOfficeSeat(nil)
                if seat then
                    myChair = seat
                    jalanKe(seat.CFrame.Position + Vector3.new(0, 2, 0))
                    task.wait(0.3)
                    if CharRef.Humanoid then seat:Sit(CharRef.Humanoid) end
                end
            end)
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if not State.IsOfficeActive then return end
    task.wait(3)
    if not State.IsOfficeActive then return end

    local seat = findOfficeSeat(nil)
    if seat then
        myChair = seat
        pcall(function()
            jalanKe(seat.CFrame.Position + Vector3.new(0, 2, 0))
            task.wait(0.3)
            seat:Sit(CharRef.Humanoid)
        end)
    end
    lastActivityTime = tick()
end)

local isSwitching = false
local IDLE_SWITCH_TIME = 60

getgenv().forceStopMath = false
getgenv().isGoingToPrinter = false

task.spawn(function()
    while true do
        task.wait(1)
        if not State.IsOfficeActive then continue end
        if getgenv().isGoingToPrinter or getgenv().forceStopMath or isSwitching then continue end
        if tick() - lastActivityTime > IDLE_SWITCH_TIME then
            isSwitching = true
            getgenv().forceStopMath = true
            keluarKursi()
            local newSeat = findOfficeSeat(myChair)
            if newSeat then myChair = newSeat end
            dudukKeKursi(false)
            getgenv().forceStopMath = false
            isSwitching = false
            lastActivityTime = tick()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        if not State.IsOfficeActive then continue end
        if getgenv().isGoingToPrinter then
            getgenv().printWatchdog = getgenv().printWatchdog or tick()
            if tick() - getgenv().printWatchdog > 45 then
                getgenv().isGoingToPrinter = false
                getgenv().forceStopMath = false
                getgenv().printWatchdog = nil
                activePrinterName = nil
                lastActivityTime = tick()
            end
        else
            getgenv().printWatchdog = nil
        end
    end
end)

-- ============================================================================
-- // PRINTER LOOP
-- ============================================================================
local AssignPrintJob = JobEvents:WaitForChild("AssignPrintJob")
local ClearPrintJob  = JobEvents:WaitForChild("ClearPrintJob")
local activePrinterName = nil
local printerRetryCount = 0
local MAX_PRINTER_RETRY = 3
local printerCooldownUntil = 0

AssignPrintJob.OnClientEvent:Connect(function(printerName)
    if tick() < printerCooldownUntil then return end
    activePrinterName = printerName
    printerRetryCount = 0
end)

ClearPrintJob.OnClientEvent:Connect(function()
    activePrinterName = nil
    printerRetryCount = 0
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if not State.IsOfficeActive then continue end

        if activePrinterName and not getgenv().isGoingToPrinter then
            if printerRetryCount >= MAX_PRINTER_RETRY then
                activePrinterName = nil
                printerRetryCount = 0
                getgenv().isGoingToPrinter = false
                getgenv().forceStopMath = false
                lastActivityTime = tick()
                continue
            end

            getgenv().isGoingToPrinter = true
            getgenv().forceStopMath = true
            getgenv().printWatchdog = tick()
            printerRetryCount = printerRetryCount + 1

            pcall(function()
                task.wait(math.random(3,7)/10)

                local hum = CharRef.Humanoid
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                    if hum.SeatPart then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.4)
                    end
                end

                local printerPart = nil
                local targetPrompt = nil
                local currentPrinterName = activePrinterName

                for i = 1, 10 do
                    if not activePrinterName or activePrinterName ~= currentPrinterName then break end
                    local printerModel = ComputersFolder:FindFirstChild(activePrinterName)
                    if printerModel then
                        printerPart = printerModel:FindFirstChild("Part")
                        if printerPart then
                            targetPrompt = printerPart:FindFirstChildOfClass("ProximityPrompt")
                            if targetPrompt then break end
                        end
                    end
                    task.wait(0.5)
                end

                if printerPart and targetPrompt and activePrinterName then
                    targetPrompt.Enabled = true

                    jalanKe(printerPart.Position + Vector3.new(0, 0, 2.5))

                    if CharRef.Root then
                        local look = Vector3.new(printerPart.Position.X, CharRef.Root.Position.Y, printerPart.Position.Z)
                        CharRef.Root.CFrame = CFrame.lookAt(CharRef.Root.Position, look)
                    end

                    local cam = workspace.CurrentCamera
                    local prevType = cam.CameraType
                    pcall(function()
                        cam.CameraType = Enum.CameraType.Scriptable
                        cam.CFrame = CFrame.lookAt(
                            CharRef.Root.Position + Vector3.new(0, 1.5, 0),
                            printerPart.Position
                        )
                    end)

                    task.wait(0.3)
                    eksekusiPromptTahan(targetPrompt)
                    State.OfficePrints = (State.OfficePrints or 0) + 1

                    pcall(function() cam.CameraType = prevType end)

                    local t = 0
                    while activePrinterName == currentPrinterName and t < 12 do
                        task.wait(0.5); t = t + 0.5
                    end

                    printerRetryCount = 0
                end
            end)

            pcall(function()
                local hum = CharRef.Humanoid
                if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end

                local seat = findOfficeSeat(nil)
                if seat then
                    myChair = seat
                    jalanKe(seat.CFrame.Position + Vector3.new(0, 2, 0))
                    task.wait(0.3)
                    if CharRef.Humanoid then seat:Sit(CharRef.Humanoid) end
                end
            end)

            getgenv().isGoingToPrinter = false
            getgenv().forceStopMath = false
            getgenv().printWatchdog = nil
            lastActivityTime = tick()

            printerCooldownUntil = tick() + 8
        end
    end
end)

-- ============================================================================
-- // MONITORING GUI (DYNAMIC OFFICE / RIDEGO TRACKER)
-- ============================================================================
local CoreGui2 = (gethui and gethui()) or game:GetService("CoreGui")
local TrackerGui = nil
local CachedMoneyLabel = nil
local DisplayedValues = {}

local function parseNumber(val)
    if not val then return 0 end
    local cleanString = string.gsub(tostring(val), "[^%d%-]", "")
    return tonumber(cleanString) or 0
end

local function formatTime(seconds)
    seconds = tonumber(seconds) or 0
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function CariLabelUang()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return nil end
    for _, guiObject in ipairs(pGui:GetDescendants()) do
        if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
            local text = guiObject.Text
            if text and string.find(text, "Rp%.") and string.match(text, "%d+") then
                return guiObject
            end
        end
    end
    return nil
end

local function DapatkanUangPemain()
    if CachedMoneyLabel and CachedMoneyLabel.Parent then
        return parseNumber(CachedMoneyLabel.Text)
    end
    CachedMoneyLabel = CariLabelUang()
    if CachedMoneyLabel then return parseNumber(CachedMoneyLabel.Text) end
    return GetPlayerMoney()
end

local function fmtRupiah(num)
    num = tonumber(num) or 0
    if num >= 1e9 then return "Rp" .. string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then return "Rp" .. string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then return "Rp" .. string.format("%.1fK", num / 1e3)
    else return "Rp" .. tostring(math.floor(num)) end
end

local function fmtProfit(num)
    num = tonumber(num) or 0
    local sign = num >= 0 and "+" or "-"
    local absNum = math.abs(num)
    if absNum >= 1e9 then return sign .. string.format("%.1fB", absNum / 1e9)
    elseif absNum >= 1e6 then return sign .. string.format("%.1fM", absNum / 1e6)
    elseif absNum >= 1e3 then return sign .. string.format("%.1fK", absNum / 1e3)
    else return sign .. tostring(math.floor(absNum)) end
end

local function fmtShort(num)
    num = tonumber(num) or 0
    if num >= 1e9 then return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then return string.format("%.1fK", num / 1e3)
    else return tostring(math.floor(num)) end
end

local function animateValue(label, targetNum, formatter, colorPos, colorNeg, colorNeutral)
    local key = label
    if DisplayedValues[key] == nil then DisplayedValues[key] = targetNum end
    local cur = DisplayedValues[key]
    if math.abs(cur - targetNum) < 0.5 then
        DisplayedValues[key] = targetNum
        if formatter then label.Text = formatter(targetNum) end
        if colorNeutral then label.TextColor3 = colorNeutral end
        return
    end
    local next = cur + (targetNum - cur) * 0.18
    DisplayedValues[key] = next
    if formatter then label.Text = formatter(next) end
    if colorPos and colorNeg then
        label.TextColor3 = (next >= 0) and colorPos or colorNeg
    elseif colorNeutral then
        label.TextColor3 = colorNeutral
    end
end

local function buatMonitoringGUI()
    local uangSekarang = DapatkanUangPemain()
    if not getgenv().UangAwalDikunci or getgenv().UangAwalDikunci == 0 then
        getgenv().UangAwalDikunci = uangSekarang
    end
    getgenv().WaktuMulai = getgenv().WaktuMulai or tick()
    local uangAwal = getgenv().UangAwalDikunci
    DisplayedValues = {}

    if TrackerGui and TrackerGui.Parent then TrackerGui:Destroy() end
    TrackerGui = Instance.new("ScreenGui")
    TrackerGui.Name = "KingAkbarTracker"
    TrackerGui.Parent = CoreGui2

    local Frame = Instance.new("Frame")
    Frame.Size        = UDim2.new(0, 228, 0, 0)
    Frame.Position    = UDim2.new(1, -16, 0.5, 0)
    Frame.AnchorPoint = Vector2.new(1, 0.5)
    Frame.BackgroundColor3       = Color3.fromRGB(18, 18, 22)
    Frame.BackgroundTransparency = 0.18
    Frame.BorderSizePixel = 0
    Frame.Active   = true
    Frame.Draggable = true
    Frame.AutomaticSize = Enum.AutomaticSize.Y
    Frame.Parent   = TrackerGui
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke", Frame)
    Stroke.Color = Color3.fromRGB(60, 60, 68); Stroke.Thickness = 1
    local Padding = Instance.new("UIPadding", Frame)
    Padding.PaddingTop    = UDim.new(0,10); Padding.PaddingBottom = UDim.new(0,10)
    Padding.PaddingLeft   = UDim.new(0,12); Padding.PaddingRight  = UDim.new(0,12)
    local List = Instance.new("UIListLayout", Frame)
    List.Padding = UDim.new(0, 7); List.SortOrder = Enum.SortOrder.LayoutOrder

    local H = Instance.new("Frame", Frame)
    H.Size = UDim2.new(1,0,0,36); H.BackgroundTransparency = 1; H.LayoutOrder = 1
    local Img = Instance.new("ImageLabel", H)
    Img.Size = UDim2.new(0,32,0,32); Img.Position = UDim2.new(0,0,0.5,-16)
    Img.BackgroundTransparency = 1; Img.Image = "rbxassetid://84070081307966"
    Img.ScaleType = Enum.ScaleType.Fit; Img.ZIndex = 2
    Instance.new("UICorner", Img).CornerRadius = UDim.new(0,7)
    local TitleLbl = Instance.new("TextLabel", H)
    TitleLbl.Size = UDim2.new(1,-40,0,14); TitleLbl.Position = UDim2.new(0,40,0,4)
    TitleLbl.BackgroundTransparency = 1; TitleLbl.Text = "KING AKBAR"
    TitleLbl.TextColor3 = Color3.fromRGB(210,210,215); TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 13; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    local SubLbl = Instance.new("TextLabel", H)
    SubLbl.Size = UDim2.new(1,-40,0,11); SubLbl.Position = UDim2.new(0,40,0,20)
    SubLbl.BackgroundTransparency = 1
    SubLbl.Text = State.IsRideGOActive and "RideGO Driver" or (State.IsOfficeActive and "Office Worker" or "Bypass GACOR")
    SubLbl.TextColor3 = Color3.fromRGB(90,90,100); SubLbl.Font = Enum.Font.Gotham
    SubLbl.TextSize = 9; SubLbl.TextXAlignment = Enum.TextXAlignment.Left

    local Div = Instance.new("Frame", Frame)
    Div.Size = UDim2.new(1,0,0,1); Div.BackgroundColor3 = Color3.fromRGB(55,55,62)
    Div.BorderSizePixel = 0; Div.LayoutOrder = 2

    local function baris(iconL, labelL, iconR, labelR, order)
        local R = Instance.new("Frame", Frame)
        R.Size = UDim2.new(1,0,0,34); R.BackgroundTransparency = 1; R.LayoutOrder = order
        local function kolom(parent, xOffset, icon, caption)
            local bg = Instance.new("Frame", parent)
            bg.Size = UDim2.new(0.5,-4,1,0); bg.Position = UDim2.new(xOffset,0,0,0)
            bg.BackgroundColor3 = Color3.fromRGB(30,30,36); bg.BackgroundTransparency = 0.4
            bg.BorderSizePixel = 0
            Instance.new("UICorner", bg).CornerRadius = UDim.new(0,6)
            local capLbl = Instance.new("TextLabel", bg)
            capLbl.Size = UDim2.new(1,-6,0,11); capLbl.Position = UDim2.new(0,6,0,4)
            capLbl.BackgroundTransparency = 1; capLbl.Text = icon .. " " .. caption
            capLbl.TextColor3 = Color3.fromRGB(110,110,120); capLbl.Font = Enum.Font.GothamMedium
            capLbl.TextSize = 9; capLbl.TextXAlignment = Enum.TextXAlignment.Left
            local valLbl = Instance.new("TextLabel", bg)
            valLbl.Size = UDim2.new(1,-6,0,14); valLbl.Position = UDim2.new(0,6,1,-18)
            valLbl.BackgroundTransparency = 1; valLbl.Text = "â€”"
            valLbl.TextColor3 = Color3.fromRGB(225,225,230); valLbl.Font = Enum.Font.GothamBold
            valLbl.TextSize = 12; valLbl.TextXAlignment = Enum.TextXAlignment.Left
            return valLbl, capLbl
        end
        local lv, lc = kolom(R, 0,   iconL, labelL)
        local rv, rc = kolom(R, 0.5, iconR, labelR)
        return lv, rv, lc, rc
    end

    local v_initial, v_profit = baris("ðŸ’µ","Initial", "ðŸ’°","Profit", 3)
    local v_stat1, v_stat2, c_stat1, c_stat2 = baris(
        State.IsRideGOActive and "ðŸš•" or "ðŸ“",
        State.IsRideGOActive and "Trips" or "Solved",
        State.IsRideGOActive and "ðŸ’µ" or "ðŸ–¨ï¸",
        State.IsRideGOActive and "Fares" or "Prints",
        4
    )
    local v_profitH, v_ping   = baris("âš¡","Profit/H", "ðŸ“¶","Ping", 5)
    local v_fps,     v_uptime = baris("ðŸŽ®","FPS",      "â±ï¸","Uptime", 6)

    local CLR_WHITE  = Color3.fromRGB(225,225,230)
    local CLR_GREEN  = Color3.fromRGB(80, 210, 120)
    local CLR_RED    = Color3.fromRGB(230, 80,  80)
    local CLR_YELLOW = Color3.fromRGB(230,190, 60)

    v_initial.Text = fmtRupiah(uangAwal)

    task.spawn(function()
        local prevStat1 = 0
        local prevStat2 = 0
        while TrackerGui and TrackerGui.Parent do
            pcall(function()
                local currentMoney = DapatkanUangPemain()
                if uangAwal == 0 and currentMoney > 0 then
                    getgenv().UangAwalDikunci = currentMoney
                    uangAwal = currentMoney
                    v_initial.Text = fmtRupiah(uangAwal)
                end
                local profit      = currentMoney - uangAwal
                local uptimeDetik = tick() - getgenv().WaktuMulai
                local uptimeJam   = math.max(uptimeDetik / 3600, 1/3600)
                local profitH     = profit / uptimeJam

                local pingVal, fpsVal = 0, 0
                pcall(function() pingVal = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                pcall(function() fpsVal  = math.floor(workspace:GetRealPhysicsFPS()) end)

                animateValue(v_profit, profit, fmtProfit, CLR_GREEN, CLR_RED, nil)

                if State.IsRideGOActive then
                    SubLbl.Text = "RideGO Driver"
                    c_stat1.Text = "ðŸš• Trips"
                    c_stat2.Text = "ðŸ’µ Fares"

                    local trips = State.RideGOTripCount or 0
                    local fares = State.RideGOEarnings or 0

                    if trips ~= prevStat1 then
                        prevStat1 = trips
                        v_stat1.TextColor3 = CLR_YELLOW
                        Services.TweenSvc:Create(v_stat1, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { TextColor3 = CLR_WHITE }):Play()
                    end
                    animateValue(v_stat1, trips, function(n) return tostring(math.floor(n)) end, nil, nil, CLR_WHITE)

                    if fares ~= prevStat2 then
                        prevStat2 = fares
                        v_stat2.TextColor3 = CLR_GREEN
                        Services.TweenSvc:Create(v_stat2, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { TextColor3 = CLR_WHITE }):Play()
                    end
                    animateValue(v_stat2, fares, fmtShort, nil, nil, CLR_WHITE)
                else
                    SubLbl.Text = State.IsOfficeActive and "Office Worker" or "Bypass GACOR"
                    c_stat1.Text = "ðŸ“ Solved"
                    c_stat2.Text = "ðŸ–¨ï¸ Prints"

                    local solved = State.OfficeMathSolved or 0
                    local prints = State.OfficePrints or 0

                    if solved ~= prevStat1 then
                        prevStat1 = solved
                        v_stat1.TextColor3 = CLR_YELLOW
                        Services.TweenSvc:Create(v_stat1, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { TextColor3 = CLR_WHITE }):Play()
                    end
                    animateValue(v_stat1, solved, function(n) return tostring(math.floor(n)) end, nil, nil, CLR_WHITE)

                    if prints ~= prevStat2 then
                        prevStat2 = prints
                        v_stat2.TextColor3 = CLR_GREEN
                        Services.TweenSvc:Create(v_stat2, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { TextColor3 = CLR_WHITE }):Play()
                    end
                    animateValue(v_stat2, prints, function(n) return tostring(math.floor(n)) end, nil, nil, CLR_WHITE)
                end

                animateValue(v_profitH, profitH, fmtShort, CLR_GREEN, CLR_RED, nil)
                animateValue(v_ping, pingVal, function(n) return tostring(math.floor(n)) .. " ms" end, nil, nil, pingVal > 200 and CLR_RED or CLR_WHITE)

                local fpsColor = fpsVal >= 30 and CLR_GREEN or (fpsVal >= 15 and CLR_YELLOW or CLR_RED)
                animateValue(v_fps, fpsVal, function(n) return tostring(math.floor(n)) end, nil, nil, fpsColor)

                v_uptime.Text = formatTime(uptimeDetik)
                v_uptime.TextColor3 = CLR_WHITE

                if State.TargetProfit > 0 and profit >= State.TargetProfit then
                    State.IsOfficeActive   = false
                    State.IsBaristaActive  = false
                    State.IsCourierActive  = false
                    State.IsRideGOActive   = false
                    getgenv().fullAuto     = false

                    WindUI:Notify({
                        Title    = "Target Tercapai",
                        Content  = "Profit " .. fmtProfit(profit) .. " dari target " .. fmtRupiah(State.TargetProfit) .. ", keluar sekarang.",
                        Duration = 4,
                    })

                    task.wait(3)

                    local exited = false
                    pcall(function()
                        game:GetService("Players"):FindFirstChildOfClass("Player").Parent = nil
                        exited = true
                    end)

                    if not exited then
                        pcall(function()
                            local np = Instance.new("NetworkReplicator")
                            np.Parent = game
                            exited = true
                        end)
                    end

                    if not exited then
                        local function crash() return crash() end
                        pcall(crash)
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
end

local function matikanMonitoring()
    if TrackerGui and TrackerGui.Parent then TrackerGui:Destroy(); TrackerGui = nil end
end

local function StartOfficeScript()
    if State.IsOfficeActive then return end
    State.IsOfficeActive = true
    State.OfficeMathSolved = 0
    State.OfficePrints = 0
    getgenv().fullAuto = true
    CachedMoneyLabel = nil
    getgenv().UangAwalDikunci = nil
    getgenv().WaktuMulai = tick()

    joinOfficeTeam()
    task.wait(0.8)

    if not CharRef.Humanoid or not CharRef.Humanoid.SeatPart then
        WindUI:Notify({ Title = "ðŸ” Office", Content = "Finding seat...", Duration = 3 })
        local targetSeat = findOfficeSeat(nil)
        if targetSeat then
            myChair = targetSeat
            dudukKeKursi(true)
        else
            WindUI:Notify({ Title = "âš ï¸ Office", Content = "No empty seat found! Sit manually.", Duration = 5 })
        end
    else
        myChair = CharRef.Humanoid.SeatPart
    end

    lastActivityTime = tick()
    buatMonitoringGUI()
    WindUI:Notify({ Title = "âœ… Office", Content = "Auto Office started!", Duration = 4 })
end

local function StopOfficeScript()
    State.IsOfficeActive = false
    getgenv().fullAuto = false
    getgenv().forceStopMath = false
    getgenv().isGoingToPrinter = false

    pcall(function()
        Services.ReplicatedStorage:WaitForChild("JobEvents")
            :WaitForChild("PlayerChangedJob"):FireServer()
    end)

    if CharRef.Humanoid then
        CharRef.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    end

    CachedMoneyLabel = nil
    getgenv().UangAwalDikunci = nil
    matikanMonitoring()
    WindUI:Notify({ Title = "ðŸ›‘ Office", Content = "Auto Office stopped.", Duration = 3 })
end

-- ============================================================================
-- // 14. AUTO COURIER
-- ============================================================================
local CourierJob = {
    Name = "Courier", TeamId = 11378976,
    X = -5158.57, Y = 4.41, Z = -3757.87
}

SELECTED_CAR = "Yamahax-MioSporty"
OwnedVehiclesList = { "Yamahax-MioSporty" }

VehicleDropdownCourier = nil
VehicleDropdownRideGO  = nil

function FetchOwnedVehicles()
    local list = {}
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local DealershipEvents = RS:WaitForChild("DealershipEvents", 5)

        if DealershipEvents then
            if DealershipEvents:FindFirstChild("InitializeCarData") then
                DealershipEvents.InitializeCarData:InvokeServer()
            end
            if DealershipEvents:FindFirstChild("GetInfoCarSlot") then
                local slotData = DealershipEvents.GetInfoCarSlot:InvokeServer()
                if type(slotData) == "table" then
                    for _, item in pairs(slotData) do
                        if type(item) == "string" and item ~= "" then
                            table.insert(list, item)
                        elseif type(item) == "table" then
                            local carName = item.Car or item.Name or item.CarName or item.Vehicle or item[1]
                            if carName and type(carName) == "string" and carName ~= "" then
                                table.insert(list, carName)
                            end
                        end
                    end
                end
            end
        end
    end)

    local unique, hash = {}, {}
    for _, car in ipairs(list) do
        if not hash[car] then
            table.insert(unique, car)
            hash[car] = true
        end
    end

    if #unique > 0 then
        OwnedVehiclesList = unique
        if not hash[SELECTED_CAR] then
            SELECTED_CAR = OwnedVehiclesList[1]
        end
    else
        OwnedVehiclesList = { "Yamahax-MioSporty" }
    end

    return OwnedVehiclesList
end

function RefreshAllVehicleDropdowns()
    local cars = FetchOwnedVehicles()
    pcall(function()
        if VehicleDropdownCourier and VehicleDropdownCourier.Refresh then
            VehicleDropdownCourier:Refresh(cars)
        end
        if VehicleDropdownRideGO and VehicleDropdownRideGO.Refresh then
            VehicleDropdownRideGO:Refresh(cars)
        end
    end)
    return cars
end

local function spawnCar()
    Services.ReplicatedStorage:WaitForChild("SpawnCarEvents"):WaitForChild("SpawnCar"):FireServer(SELECTED_CAR)
end

local function findMyMotor()
    local myName = LocalPlayer.Name
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name:match(myName) and v.Name:match("Montors") then return v end
    end
    return nil
end

local function walkToCourier(point, timeout)
    timeout = timeout or 10
    local hum = CharRef.Humanoid
    if not hum then return end
    local t = tick()
    while tick() - t < timeout and State.IsCourierActive do
        local hrp = CharRef.Root
        if hrp and (hrp.Position - point).Magnitude < 5 then break end
        hum:MoveTo(point); task.wait(0.5)
    end
end

local function setJob(job)
    pcall(function()
        Services.ReplicatedStorage:WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
            :FireServer(job.Name, job.TeamId, 1, 0, "Detector")
    end)
end

local function exitMotor()
    local motor = findMyMotor()
    if not motor then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local anims = motor:FindFirstChild("Anims")
    if anims then
        pcall(function() anims:FireServer("RemovePlayer", char, nil) end)
        task.wait(0.3)
    end
    local driveSeat = motor:FindFirstChild("DriveSeat", true)
    if driveSeat then pcall(function() driveSeat:Sit(nil) end); task.wait(0.3) end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then pcall(function() humanoid.Jump = true end) end
    return true
end

local function rideMotor()
    local motor = findMyMotor()
    if not motor then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local anims = motor:FindFirstChild("Anims")
    if anims then
        pcall(function() anims:FireServer("CreatePlayer", char) end); task.wait(0.2)
        pcall(function() anims:FireServer("RegisterPlayer", char) end); task.wait(0.2)
    end
    local kickstand = motor:FindFirstChild("Kickstand")
    if kickstand then pcall(function() kickstand:FireServer("StandUp", 0, 0, 0, 0, false) end); task.wait(0.2) end
    local driveSeat = motor:FindFirstChild("DriveSeat", true)
    if driveSeat then
        pcall(function()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = driveSeat.CFrame end
            driveSeat:Sit(char:FindFirstChildOfClass("Humanoid"))
        end)
    end
    return true
end

local function forceDismount()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return end
    hum.Jump = true; task.wait(0.1)
    if hum.SeatPart then
        char:PivotTo(char:GetPivot() * CFrame.new(0, 2, 0))
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    task.wait(0.2)
end

local function ghostGlideMotor(targetPos)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
    if not (vehicle and vehicle.PrimaryPart) then return end
    local pp = vehicle.PrimaryPart
    local speed = 150
    local glideHeight = targetPos.Y + 3
    local posTujuan = Vector3.new(targetPos.X, glideHeight, targetPos.Z)
    local virtualAnchor = Instance.new("BodyVelocity")
    virtualAnchor.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    virtualAnchor.Velocity = Vector3.new(0, 0, 0)
    virtualAnchor.Parent = pp
    local virtualGyro = Instance.new("BodyGyro")
    virtualGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    virtualGyro.P = 100000
    virtualGyro.Parent = pp
    local noclip = Services.RunService.Stepped:Connect(function()
        if not State.IsCourierActive then return end
        for _, v in pairs(vehicle:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end)
    local _, currentYRot, _ = pp.CFrame:ToEulerAnglesYXZ()
    local function glideTo(targetVector, faceForward)
        if not State.IsCourierActive then return end
        local dist = (pp.Position - targetVector).Magnitude
        local timeToMove = dist / speed
        if timeToMove > 0 then
            local startTime = tick()
            while tick() - startTime < timeToMove and State.IsCourierActive do
                if not hum.SeatPart then break end
                local alpha = (tick() - startTime) / timeToMove
                local currentPos = pp.Position:Lerp(targetVector, alpha)
                if faceForward then
                    local dir = (targetVector - pp.Position).Unit
                    local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
                    if flatDir.Magnitude > 0.001 then
                        local newCF = CFrame.lookAt(currentPos, currentPos + flatDir)
                        virtualGyro.CFrame = newCF; vehicle:PivotTo(newCF)
                    end
                else
                    local newCF = CFrame.new(currentPos) * CFrame.Angles(0, currentYRot, 0)
                    virtualGyro.CFrame = newCF; vehicle:PivotTo(newCF)
                end
                Services.RunService.Heartbeat:Wait()
            end
        end
    end
    glideTo(posTujuan, true)
    local finalSafeY = targetPos.Y + 3
    local timeout = tick() + 8
    while tick() < timeout and State.IsCourierActive do
        local rayResult = workspace:Raycast(
            Vector3.new(targetPos.X, glideHeight + 5, targetPos.Z),
            Vector3.new(0, -100, 0)
        )
        if rayResult and rayResult.Instance then
            finalSafeY = rayResult.Position.Y + 1.5; break
        else task.wait(1) end
    end
    glideTo(Vector3.new(targetPos.X, finalSafeY, targetPos.Z), false)
    virtualAnchor:Destroy(); virtualGyro:Destroy(); noclip:Disconnect()
    pp.AssemblyLinearVelocity = Vector3.new(0,0,0)
    pp.AssemblyAngularVelocity = Vector3.new(0,0,0)
    forceDismount()
end

local ServiceEventConn = nil

local function startCourierLoop()
    local activePackageLoc = nil
    local activePackageNum = nil

    local serviceEvent = Services.ReplicatedStorage:FindFirstChild("ServiceEvent", true)
    if serviceEvent then
        ServiceEventConn = serviceEvent.OnClientEvent:Connect(function(eventName, action, paketNum)
            if not State.IsCourierActive then return end
            if action == "Create" then
                local Location = workspace:FindFirstChild("Livrason") and workspace.Livrason:FindFirstChild("Location")
                if Location then
                    local paket = Location:FindFirstChild(tostring(paketNum))
                    if paket then
                        local block = paket:FindFirstChild("Block")
                        if block then activePackageLoc = block.Position; activePackageNum = paketNum end
                    end
                end
            elseif action == "Remove" then
                if activePackageNum == paketNum then activePackageLoc = nil; activePackageNum = nil end
            end
        end)
    end

    setJob(CourierJob); task.wait(1.5)
    spawnCar(); task.wait(6)
    rideMotor(); task.wait(3.5)

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local motor = findMyMotor()
    if not (motor and hrp and State.IsCourierActive) then return end

    local target = CFrame.new(CourierJob.X, CourierJob.Y, CourierJob.Z)
    pcall(function()
        motor:SetPrimaryPartCFrame(target); task.wait(0.3)
        hrp.CFrame = target * CFrame.new(0, 2, 0)
    end)

    task.wait(3.5); exitMotor(); task.wait(1.5)
    walkToCourier(Vector3.new(-5109.06, 5.18, -3758.69), 10); task.wait(1.5)

    pcall(function()
        local prompt = workspace.Livrason.Take1.Take.ProximityPrompt
        if prompt then
            prompt:InputHoldBegin(); task.wait(prompt.HoldDuration + 0.2); prompt:InputHoldEnd()
        end
    end)
    task.wait(1.5)

    while State.IsCourierActive do
        local t = tick()
        while State.IsCourierActive and not activePackageLoc and tick() - t < 20 do task.wait(0.4) end
        if not State.IsCourierActive then break end
        if not activePackageLoc then break end

        spawnCar(); task.wait(4); rideMotor(); task.wait(3.5)
        ghostGlideMotor(activePackageLoc); task.wait(1)
        walkToCourier(activePackageLoc, 20); task.wait(2.0)

        local targetNum = activePackageNum
        pcall(function()
            local LocationFolder = workspace.Livrason.Location
            local paketModel = LocationFolder:FindFirstChild(tostring(targetNum))
            if paketModel then
                local block = paketModel:FindFirstChild("Block")
                local prompt = block and block:FindFirstChild("ProximityPrompt")
                if prompt and prompt.Enabled then
                    local box = LocalPlayer.Backpack:FindFirstChild("Box")
                        or LocalPlayer.Character:FindFirstChild("Box")
                        or LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                    if box and CharRef.Humanoid then
                        CharRef.Humanoid:EquipTool(box); task.wait(1.0)
                    end
                    prompt:InputHoldBegin(); task.wait(prompt.HoldDuration + 0.2); prompt:InputHoldEnd()
                    State.CourierDelivered = (State.CourierDelivered or 0) + 1
                    task.wait(2.5)
                end
            end
        end)
        task.wait(2.0)
    end

    if ServiceEventConn then ServiceEventConn:Disconnect(); ServiceEventConn = nil end
end

local function StartCourierScript()
    if State.IsCourierActive then return end
    State.IsCourierActive = true
    State.CourierDelivered = 0
    task.spawn(startCourierLoop)
end

local function StopCourierScript()
    State.IsCourierActive = false
    if ServiceEventConn then ServiceEventConn:Disconnect(); ServiceEventConn = nil end
end

-- ============================================================================
-- // 15. INJECT A-CHASSIS
-- ============================================================================
local function InjectMesin(HP_Mult, RPM_Add, Ratio_Mult, FD_Mult, NamaMode)
    local char = game:GetService("Players").LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
        local vehicle = char.Humanoid.SeatPart.Parent
        while vehicle and not vehicle:IsA("Model") do vehicle = vehicle.Parent end
        if vehicle then
            local foundTune = false
            for _, s in pairs(vehicle:GetDescendants()) do
                if s:IsA("LocalScript") then
                    local name = string.lower(s.Name)
                    if string.find(name, "limit") or string.find(name, "speed") or string.find(name, "cap") then
                        if name ~= "a-chassis interface" and name ~= "drive" then
                            pcall(function() s.Disabled = true end); safeDestroy(s)
                        end
                    end
                end
            end
            for _, v in pairs(vehicle:GetDescendants()) do
                if v:IsA("ModuleScript") and (v.Name == "Tune" or string.find(string.lower(v.Name), "tune")) then
                    pcall(function()
                        local tune = require(v)
                        if tune.Horsepower then tune.Horsepower = tune.Horsepower * HP_Mult end
                        if tune.Redline    then tune.Redline    = tune.Redline + RPM_Add end
                        if tune.Ratios then
                            for i, ratio in pairs(tune.Ratios) do
                                if type(ratio) == "number" and ratio > 0 then tune.Ratios[i] = ratio * Ratio_Mult end
                            end
                        end
                        if tune.FinalDrive   then tune.FinalDrive   = tune.FinalDrive * FD_Mult end
                        if tune.Limiter  ~= nil then tune.Limiter  = false end
                        if tune.RevLimit     then tune.RevLimit     = 999999 end
                        if tune.SpeedLimit   then tune.SpeedLimit   = false end
                        if tune.TopSpeed     then tune.TopSpeed     = 999999 end
                        if tune.MaxSpeed     then tune.MaxSpeed     = 999999 end
                        if tune.DragMult     then tune.DragMult     = tune.DragMult * 0.05 end
                        if tune.Weight       then tune.Weight       = tune.Weight * 0.7 end
                        foundTune = true
                    end)
                end
            end
            if foundTune then
                WindUI:Notify({ Title = "âœ… " .. NamaMode, Content = "Safe! Respawn vehicle to apply.", Duration = 5 })
            else
                WindUI:Notify({ Title = "âŒ Injection Failed", Content = "Not a standard A-Chassis.", Duration = 4 })
            end
        end
    else
        WindUI:Notify({ Title = "âš ï¸ Warning!", Content = "Please enter a vehicle first!", Duration = 3 })
    end
end

-- ============================================================================
-- // 16. AUTO RIDEGO DRIVER (VOID GATE ULTRA + AUTO RECOVERY)
-- ============================================================================
local TaxiEvent = Services.ReplicatedStorage
    :WaitForChild("TaxiAssets", 10)
    :WaitForChild("Events", 10)
    :WaitForChild("TaxiEvent", 10)

local DealershipEvents = Services.ReplicatedStorage:WaitForChild("DealershipEvents", 10)
local SpawnCarEvents   = Services.ReplicatedStorage:WaitForChild("SpawnCarEvents", 10)

local MAX_SPEED_LIMIT = 200
local MIN_SPEED_LIMIT = 190
local HOVER_HEIGHT    = 12
-- â˜… VOID DIPERCEPAT: stop sebelum scan hanya 0.08 detik (sebelumnya 0.6)
local VOID_STOP_TIME  = 0.08
local VOID_SCAN_MAX   = 6000
local VOID_SCAN_STEP  = 50
-- â˜… Tiap lompatan void lebih jauh 600 stud (sebelumnya 250)
local HOP_DISTANCE    = 600
local HOP_MAX         = 25
local STREAM_WAIT_MAX = 8

local function getBikeModel()
    local hum = CharRef.Humanoid
    if not hum or not hum.SeatPart then return nil end
    return hum.SeatPart.Parent
end

local function getMovers(primary)
    if not primary then return nil, nil end

    local bv = primary:FindFirstChild("RideGO_BV")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "RideGO_BV"
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.zero
        bv.Parent = primary
    end

    local bg = primary:FindFirstChild("RideGO_BG")
    if not bg then
        bg = Instance.new("BodyGyro")
        bg.Name = "RideGO_BG"
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.CFrame = primary.CFrame
        bg.Parent = primary
    end

    return bv, bg
end

local function newRayParams()
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local blacklist = { LocalPlayer.Character }
    local bike = getBikeModel()
    if bike then
        table.insert(blacklist, bike)
        for _, seat in ipairs(bike:GetDescendants()) do
            if seat:IsA("VehicleSeat") and seat.Occupant then
                table.insert(blacklist, seat.Occupant.Parent)
            end
        end
    end
    rayParams.FilterDescendantsInstances = blacklist
    return rayParams
end

local function findGroundY(origin)
    local ray = Services.Workspace:Raycast(origin, Vector3.new(0, -600, 0), newRayParams())
    return ray and ray.Position.Y or nil
end

local function findGroundYFar(x, z, fromY)
    local origin = Vector3.new(x, (fromY or 0) + 300, z)
    local ray = Services.Workspace:Raycast(origin, Vector3.new(0, -3000, 0), newRayParams())
    return ray and ray.Position.Y or nil
end

local function requestStream(pos)
    pcall(function()
        Services.Workspace:RequestStreamAround(pos, 0.5)
    end)
end

local function hoverLock(primary, bv, bg, flatLook)
    bv.Velocity = Vector3.zero
    primary.AssemblyLinearVelocity  = Vector3.zero
    primary.AssemblyAngularVelocity = Vector3.zero
    if flatLook then
        bg.CFrame = CFrame.lookAt(primary.Position, primary.Position + flatLook)
    end
end

local function hoverWaitForGround(primary, bv, bg, flatLook, targetPos, timeout)
    local t0 = tick()
    while tick() - t0 < (timeout or STREAM_WAIT_MAX) do
        if not State.IsRideGOActive or State.RideGOTargetPos ~= targetPos then return nil, true end
        if not primary.Parent then return nil, true end

        hoverLock(primary, bv, bg, flatLook)

        local gY = findGroundY(primary.Position)
        if gY then return gY, false end
        task.wait(0.25)
    end
    return nil, false
end

local function ensureBike()
    local bike = getBikeModel()
    if bike then
        local primary = bike.PrimaryPart or bike:FindFirstChild("VehicleSeat") or bike:FindFirstChildOfClass("BasePart")
        if primary then getMovers(primary) end
        return bike
    end

    pcall(function()
        if DealershipEvents:FindFirstChild("InitializeCarData") then
            DealershipEvents.InitializeCarData:InvokeServer()
        end
        if DealershipEvents:FindFirstChild("GetInfoCarSlot") then
            DealershipEvents.GetInfoCarSlot:InvokeServer()
        end
        if SpawnCarEvents:FindFirstChild("SpawnCar") then
            SpawnCarEvents.SpawnCar:FireServer(SELECTED_CAR or "Yamahax-MioSporty")
        end
    end)

    local seatFound = nil
    local timeout = tick() + 5

    while tick() < timeout and not seatFound do
        task.wait(0.3)
        if CharRef.Root then
            for _, model in ipairs(Services.Workspace:GetChildren()) do
                if model:IsA("Model") and (model.Name:find("Mio") or model:FindFirstChildOfClass("VehicleSeat")) then
                    local seat = model:FindFirstChildOfClass("VehicleSeat")
                    if seat and not seat.Occupant then
                        local dist = (seat.Position - CharRef.Root.Position).Magnitude
                        if dist < 45 then
                            seatFound = seat
                            break
                        end
                    end
                end
            end
        end
    end

    if seatFound and CharRef.Humanoid and CharRef.Root then
        CharRef.Root.CFrame = seatFound.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.1)
        seatFound:Sit(CharRef.Humanoid)
        task.wait(0.5)

        local primary = seatFound.Parent.PrimaryPart or seatFound
        getMovers(primary)
        return seatFound.Parent
    end

    return getBikeModel()
end

-- [AUTO-RECOVERY RESPAWN HANDLER]
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if not State.IsRideGOActive then return end

    task.wait(1.5)
    pcall(ensureBike)

    if not State.RideGOTargetPos and State.RideGOPhase ~= "idle" then
        State.RideGOPhase = "idle"
    end
end)

Services.RunService.Stepped:Connect(function()
    if not State.IsRideGOActive then return end

    if CharRef.Humanoid and not CharRef.Humanoid.Sit and getBikeModel() then
        CharRef.Humanoid.Sit = true
    end

    local bike = getBikeModel()
    if bike then
        for _, part in ipairs(bike:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
        for _, seat in ipairs(bike:GetDescendants()) do
            if seat:IsA("VehicleSeat") and seat.Occupant then
                local pax = seat.Occupant.Parent
                if pax then
                    for _, part in ipairs(pax:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end

    if CharRef.Character then
        for _, part in ipairs(CharRef.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    local activeMissions = Services.Workspace:FindFirstChild("ActiveMissions")
    if activeMissions then
        for _, mission in ipairs(activeMissions:GetChildren()) do
            if mission.Name:find("RideGO_Passenger") then
                for _, part in ipairs(mission:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

local function flyToTarget(targetPos)
    local bike = ensureBike()
    if not bike then return false end

    local primary = bike.PrimaryPart
        or bike:FindFirstChild("VehicleSeat")
        or bike:FindFirstChildOfClass("BasePart")
    if not primary then return false end

    pcall(function() bike:SetNetworkOwner(LocalPlayer) end)

    local bv, bg = getMovers(primary)
    bv.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)

    local reached     = false
    local flatTarget  = Vector3.new(targetPos.X, 0, targetPos.Z)
    local baseSpeed   = math.random(MIN_SPEED_LIMIT, MAX_SPEED_LIMIT)
    local voidHandled = 0

    local function voidStopAndTP()
        -- â˜… Stop singkat 0.08 detik sebelum scan void (lebih cepat dari 0.6)
        local stopStart = tick()
        while tick() - stopStart < VOID_STOP_TIME do
            if not State.IsRideGOActive or State.RideGOTargetPos ~= targetPos then return end
            bv.Velocity = Vector3.zero
            primary.AssemblyAngularVelocity = Vector3.zero
            task.wait(0.03)
        end
        hoverLock(primary, bv, bg, nil)
        task.wait(0.05) -- â˜… Jeda setelah hover lock (sebelumnya 0.15)

        local posNow   = primary.Position
        local flatNow  = Vector3.new(posNow.X, 0, posNow.Z)
        local distNow  = (flatNow - flatTarget).Magnitude
        local dirToTgt = distNow > 1 and ((flatTarget - flatNow).Unit) or Vector3.new(0, 0, -1)
        local hoverY   = posNow.Y

        voidHandled += 1

        local safeLandPos = nil

        local streak, firstD, firstGY = 0, nil, nil
        for d = VOID_SCAN_STEP, VOID_SCAN_MAX, VOID_SCAN_STEP do
            if not State.IsRideGOActive or State.RideGOTargetPos ~= targetPos then return end

            local px = posNow.X + dirToTgt.X * d
            local pz = posNow.Z + dirToTgt.Z * d
            local gY = findGroundYFar(px, pz, posNow.Y)

            if gY then
                if streak == 0 then
                    firstD  = d
                    firstGY = gY
                end
                streak += 1

                if streak >= 3 then
                    local landD = firstD + 25
                    if landD >= distNow - 10 then
                        break
                    end
                    local lx = posNow.X + dirToTgt.X * landD
                    local lz = posNow.Z + dirToTgt.Z * landD
                    local newDist = (Vector3.new(lx, 0, lz) - flatTarget).Magnitude
                    if newDist < distNow then
                        safeLandPos = Vector3.new(lx, firstGY + HOVER_HEIGHT, lz)
                    end
                    break
                end
            else
                streak, firstD, firstGY = 0, nil, nil
            end
        end

        if safeLandPos then
            local tpCFrame = CFrame.lookAt(safeLandPos, safeLandPos + dirToTgt)
            bike:PivotTo(tpCFrame)
            bg.CFrame = tpCFrame
            requestStream(safeLandPos)

            -- â˜… Jeda lebih singkat setelah safe land TP (0.05 + 0.05 vs 0.1 + 0.2)
            task.wait(0.05)
            hoverLock(primary, bv, bg, dirToTgt)
            task.wait(0.05)
            return
        end

        local curFlat = flatNow
        for hop = 1, HOP_MAX do
            if not State.IsRideGOActive or State.RideGOTargetPos ~= targetPos then return end
            if not primary.Parent then return end

            local remaining = (flatTarget - curFlat).Magnitude
            if remaining < 20 then break end

            -- â˜… Hop lebih jauh 600 stud per lompatan (sebelumnya 250)
            local stepD  = math.min(HOP_DISTANCE, remaining)
            local hopPos = Vector3.new(curFlat.X + dirToTgt.X * stepD, hoverY, curFlat.Z + dirToTgt.Z * stepD)
            local tpCF   = CFrame.lookAt(hopPos, hopPos + dirToTgt)

            bike:PivotTo(tpCF)
            bg.CFrame = tpCF
            hoverLock(primary, bv, bg, dirToTgt)
            requestStream(hopPos)
            -- â˜… Jeda antar hop jauh lebih singkat (0.05 vs 0.35)
            task.wait(0.05)

            local gY = findGroundY(primary.Position)
            if gY then
                local landPos = Vector3.new(primary.Position.X, gY + HOVER_HEIGHT, primary.Position.Z)
                bike:PivotTo(CFrame.lookAt(landPos, landPos + dirToTgt))
                hoverLock(primary, bv, bg, dirToTgt)
                return
            end

            curFlat = Vector3.new(primary.Position.X, 0, primary.Position.Z)
        end

        local missionPos = Vector3.new(targetPos.X, math.max(hoverY, targetPos.Y + HOVER_HEIGHT), targetPos.Z)
        local tpCF = CFrame.lookAt(missionPos, missionPos + dirToTgt)
        bike:PivotTo(tpCF)
        bg.CFrame = tpCF
        hoverLock(primary, bv, bg, dirToTgt)
        requestStream(missionPos)

        local gY, aborted = hoverWaitForGround(primary, bv, bg, dirToTgt, targetPos, STREAM_WAIT_MAX)
        if aborted then return end

        if gY then
            local landPos = Vector3.new(primary.Position.X, gY + HOVER_HEIGHT, primary.Position.Z)
            bike:PivotTo(CFrame.lookAt(landPos, landPos + dirToTgt))
            hoverLock(primary, bv, bg, dirToTgt)
        end
    end

    local ok, err = pcall(function()
        while State.IsRideGOActive and State.RideGOTargetPos == targetPos do
            if not primary.Parent or not CharRef.Humanoid or not CharRef.Humanoid.SeatPart then
                break
            end

            local pos      = primary.Position
            local flatPos  = Vector3.new(pos.X, 0, pos.Z)
            local flatDist = (flatPos - flatTarget).Magnitude

            if flatDist < 15 then
                reached = true
                break
            end

            local dirToTarget    = (flatTarget - flatPos).Unit
            local currentGroundY = findGroundY(pos)
            local lookAheadPos   = pos + dirToTarget * 45
            local groundAheadY   = findGroundY(lookAheadPos)

            if (not currentGroundY) or (not groundAheadY) then
                voidStopAndTP()
                continue
            end

            local targetHoverY = currentGroundY + HOVER_HEIGHT

            local currentSpeed = baseSpeed
            if flatDist < 90 then
                currentSpeed = math.clamp(flatDist * 2.2, 25, baseSpeed)
            end
            currentSpeed = currentSpeed * (1 + (math.random(-3, 3) / 100))

            local moveDir = dirToTarget
            if moveDir.X ~= moveDir.X then moveDir = Vector3.zero end
            local moveVel = moveDir * currentSpeed
            local yVel    = math.clamp((targetHoverY - pos.Y) * 5, -30, 30)

            bv.Velocity = Vector3.new(moveVel.X, yVel, moveVel.Z)
            if moveVel.Magnitude > 0 then
                bg.CFrame = CFrame.lookAt(pos, pos + moveVel)
            end
            task.wait(0.03)
        end
    end)

    if err then end
    if not reached then
        bv.Velocity = Vector3.zero
        return false
    end

    local currentLook = bike:GetPivot().LookVector
    local flatLook = Vector3.new(currentLook.X, 0, currentLook.Z).Unit
    if flatLook.Magnitude == 0 then flatLook = Vector3.new(0, 0, -1) end

    bg.CFrame = CFrame.lookAt(primary.Position, primary.Position + flatLook)

    local lastVel = bv.Velocity
    for i = 1, 8 do
        bv.Velocity = lastVel * (1 - i / 8)
        task.wait(0.03)
    end
    bv.Velocity = Vector3.zero

    local groundY = findGroundY(primary.Position)
    if not groundY then
        groundY = hoverWaitForGround(primary, bv, bg, flatLook, targetPos, STREAM_WAIT_MAX)
    end

    if groundY then
        local targetLandY = groundY + 2.5
        local landTimeout = tick() + 2.5

        while primary.Parent and primary.Position.Y > targetLandY and tick() < landTimeout do
            if not State.IsRideGOActive then break end

            local remainingDist = primary.Position.Y - targetLandY
            local downSpeed = math.clamp(remainingDist * 3, 1, 6)

            bv.Velocity = Vector3.new(0, -downSpeed, 0)
            bg.CFrame   = CFrame.lookAt(primary.Position, primary.Position + flatLook)
            task.wait(0.04)
        end
    end

    hoverLock(primary, bv, bg, flatLook)
    task.wait(3)
    return true
end

TaxiEvent.OnClientEvent:Connect(function(action, data)
    if not State.IsRideGOActive then return end
    local d = data or {}

    if action == "DutyStarted" then
        State.RideGOIsOnline = true
        State.RideGOPhase    = "idle"
        ensureBike()

    elseif action == "DutyEnded" then
        State.RideGOIsOnline  = false
        State.RideGOPhase     = "idle"
        State.RideGOTargetPos = nil

    elseif action == "OrderOffer" and State.RideGOPhase == "idle" then
        State.RideGOToken = d.Token
        State.RideGOPhase = "offered"
        ensureBike()
        TaxiEvent:FireServer("AcceptOrder", State.RideGOToken)

    elseif action == "OrderAccepted" and State.RideGOToken == d.Token then
        State.RideGOTargetPos = d.PickupPos
        State.RideGOPhase     = "goingPickup"

    elseif action == "PassengerBoarding"
        and (State.RideGOPhase == "goingPickup" or State.RideGOPhase == "atPickup") then
        State.RideGOPhase = "waitingBoard"

    elseif action == "TripStarted" and State.RideGOPhase == "waitingBoard" then
        State.RideGOTargetPos = d.DropPos
        State.RideGOPhase     = "goingDrop"

    elseif action == "OrderCompleted" then
        State.RideGOTripCount = (State.RideGOTripCount or 0) + 1
        local earned = tonumber(d.Earned or d.FareEarned) or 0
        State.RideGOEarnings = (State.RideGOEarnings or 0) + earned

        task.delay(1, function() TaxiEvent:FireServer("AckTripComplete") end)
        State.RideGOToken     = nil
        State.RideGOTargetPos = nil
        State.RideGOPhase     = "idle"

    elseif action == "OrderExpired"
        or action == "OrderDeclined"
        or action == "OrderCancelled" then
        State.RideGOToken     = nil
        State.RideGOTargetPos = nil
        State.RideGOPhase     = "idle"
    end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        if not State.IsRideGOActive or not State.RideGOTargetPos then continue end

        if State.RideGOPhase == "goingPickup" then
            local ok = flyToTarget(State.RideGOTargetPos)
            if ok and State.RideGOPhase == "goingPickup" then
                State.RideGOPhase = "atPickup"
            end

        elseif State.RideGOPhase == "goingDrop" then
            flyToTarget(State.RideGOTargetPos)
        end
    end
end)

local function StartRideGOScript()
    if State.IsRideGOActive then return end
    State.IsRideGOActive = true
    State.RideGOTripCount = 0
    State.RideGOEarnings = 0
    CachedMoneyLabel = nil
    getgenv().UangAwalDikunci = nil
    getgenv().WaktuMulai = tick()

    buatMonitoringGUI()

    ensureBike()
    if not State.RideGOIsOnline then
        TaxiEvent:FireServer("GoOnline")
    end

    WindUI:Notify({
        Title = "ðŸš• RideGO Driver",
        Content = "Auto RideGO & Monitoring Aktif!",
        Duration = 4
    })
end

local function StopRideGOScript()
    State.IsRideGOActive = false
    State.RideGOTargetPos = nil
    if State.RideGOIsOnline then
        TaxiEvent:FireServer("GoOffline")
    end
    local bike = getBikeModel()
    if bike then
        local primary = bike.PrimaryPart or bike:FindFirstChild("VehicleSeat") or bike:FindFirstChildOfClass("BasePart")
        if primary then
            local bv = primary:FindFirstChild("RideGO_BV")
            local bg = primary:FindFirstChild("RideGO_BG")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
    end

    CachedMoneyLabel = nil
    getgenv().UangAwalDikunci = nil
    matikanMonitoring()

    WindUI:Notify({
        Title = "ðŸ›‘ RideGO Driver",
        Content = "Auto RideGO dihentikan.",
        Duration = 3
    })
end

-- ==================== TEAM DETECTOR (SAFETY ONLY) ====================
local function OnRideGOTeamChanged()
    if State.IsRideGOActive and LocalPlayer.Team and LocalPlayer.Team.Name ~= "RideGO Driver" then
        StopRideGOScript()
        WindUI:Notify({
            Title    = "âš ï¸ RideGO Driver",
            Content  = "Keluar dari tim driver, bot dimatikan otomatis.",
            Duration = 3
        })
    end
end
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(OnRideGOTeamChanged)

-- ============================================================================
-- // 17. UI â€” 7 TAB
-- ============================================================================
local wSz  = IsMobile and UDim2.fromOffset(420, 320) or UDim2.fromOffset(580, 460)
local mnSz = IsMobile and Vector2.new(600, 300) or Vector2.new(600, 350)
local mxSz = IsMobile and Vector2.new(650, 400) or Vector2.new(850, 560)

local Window = WindUI:CreateWindow({
    Title                       = "King Akbar - Drag Drive Simulator",
    Icon                        = "crown",
    Author                      = "King Akbar",
    Folder                      = "MySuperHub",
    Size                        = wSz,
    MinSize                     = mnSz,
    MaxSize                     = mxSz,
    Transparent                 = false,
    Background                  = "rbxassetid://127295801178451",
    BackgroundImageTransparency = 0.5,
    Theme                       = "Dark",
    Resizable                   = true,
    SideBarWidth                = 210,
    HideSearchBar               = false,
    ScrollBarEnabled            = true,
})

local TabInfo = Window:Tab({ Title = "Info", Icon = "info", Border = true })

local memberCount = "N/A"
local onlineCount = "N/A"

local function fetchDiscordInfo()
    local req = request or http_request or (syn and syn.request)
    if not req then return end
    local ok, res = pcall(function()
        return req({
            Url     = "https://discord.com/api/v9/invites/XmWf3YQPpZ?with_counts=true",
            Method  = "GET",
            Headers = { ["User-Agent"] = "Mozilla/5.0" }
        })
    end)
    if ok and res and res.StatusCode == 200 then
        local ok2, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res.Body) end)
        if ok2 and data then
            memberCount = tostring(data.approximate_member_count   or "N/A")
            onlineCount = tostring(data.approximate_presence_count or "N/A")
        end
    end
end
fetchDiscordInfo()

local ServerInfo = TabInfo:Paragraph({
    Title         = "King Vypers | Official",
    Desc          = "â€¢ Member Count: " .. memberCount .. "\nâ€¢ Online Count: " .. onlineCount,
    Image         = "rbxassetid://107726435417936",
    Thumbnail     = "rbxassetid://83197533072664",
    ThumbnailSize = 80,
    Buttons = {
        {
            Title    = "Copy Discord Invite",
            Color    = Color3.fromHex("#5707AB"),
            Icon     = "link",
            Callback = function()
                if setclipboard then setclipboard("https://discord.gg/XmWf3YQPpZ") end
            end
        },
        {
            Title    = "Update Info",
            Icon     = "refresh-cw",
            Callback = function()
                fetchDiscordInfo()
                ServerInfo:SetDesc("â€¢ Member Count: " .. memberCount .. "\nâ€¢ Online Count: " .. onlineCount)
            end
        }
    }
})

local TabFarm = Window:Tab({ Title = "Auto Farm", Icon = "coffee", Border = true })

local SectionBarista = TabFarm:Section({ Title = "Auto Barista", Box = true, BoxBorder = true, Opened = false })
SectionBarista:Toggle({ Title = "Enable Auto Barista", Icon = "play", Value = false, Callback = function(on) if on then StartBaristaScript() else StopBaristaScript() end end })

local SectionOffice = TabFarm:Section({ Title = "Auto Office", Box = true, BoxBorder = true, Opened = false })
SectionOffice:Toggle({ Title = "Enable Auto Office", Icon = "briefcase", Value = false, Callback = function(on) if on then StartOfficeScript() else StopOfficeScript() end end })

SectionOffice:Input({
    Title       = "Stop otomatis di profit (Rp)",
    Desc        = "Kalau sudah nyampe, langsung keluar server. Kosongin = gak ada batas.",
    Placeholder = "contoh: 50000000",
    Callback    = function(Text)
        local bersih = string.gsub(Text or "", "[^%d]", "")
        local val = tonumber(bersih) or 0
        State.TargetProfit = val
        if val > 0 then
            WindUI:Notify({
                Title   = "Target dipasang",
                Content = "Bakal keluar pas profit udah " .. fmtRupiah(val),
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title   = "Target dicopot",
                Content = "Gak ada batas profit, jalan terus.",
                Duration = 3,
            })
        end
    end
})

SectionOffice:Toggle({
    Title = "Auto keluar saat target tercapai",
    Desc  = "Nyalain ini biar langsung keluar server kalau udah nyampe target profit.",
    Icon  = "log-out",
    Value = false,
    Callback = function(on)
        if on and State.TargetProfit == 0 then
            WindUI:Notify({
                Title   = "Isi target dulu",
                Content = "Masukin angka target profit dulu sebelum nyalain ini.",
                Duration = 3,
            })
        end
    end
})

local SectionCourier = TabFarm:Section({ Title = "Auto Courier", Box = true, BoxBorder = true, Opened = false })
SectionCourier:Toggle({ Title = "Enable Auto Courier", Icon = "package", Value = false, Callback = function(on) if on then StartCourierScript() else StopCourierScript() end end })

VehicleDropdownCourier = SectionCourier:Dropdown({
    Title    = "Pilih Motor Kurir",
    Multi    = false,
    Options  = OwnedVehiclesList,
    Callback = function(chosen)
        if chosen and chosen ~= "" then
            SELECTED_CAR = chosen
            WindUI:Notify({
                Title    = "ðŸš— Kendaraan Dipilih",
                Content  = "Menggunakan: " .. SELECTED_CAR,
                Duration = 2
            })
        end
    end
})

SectionCourier:Button({
    Title    = "ðŸ”„ Refresh Garasi",
    Icon     = "refresh-cw",
    Callback = function()
        local cars = RefreshAllVehicleDropdowns()
        WindUI:Notify({
            Title    = "âœ… Garasi Terdeteksi",
            Content  = "Ditemukan " .. #cars .. " kendaraan!",
            Duration = 3
        })
    end
})

local SectionRideGO = TabFarm:Section({ Title = "Auto RideGO Driver", Box = true, BoxBorder = true, Opened = false })
SectionRideGO:Paragraph({
    Title = "Status: Stabil + Void Cepat",
    Desc = "Void TP dipercepat: stop 0.08s, hop 600 stud.",
})
SectionRideGO:Toggle({
    Title = "Enable Auto RideGO",
    Icon = "car",
    Value = false,
    Callback = function(on)
        if on then
            StartRideGOScript()
        else
            StopRideGOScript()
        end
    end
})

VehicleDropdownRideGO = SectionRideGO:Dropdown({
    Title    = "Pilih Kendaraan RideGO",
    Multi    = false,
    Options  = OwnedVehiclesList,
    Callback = function(chosen)
        if chosen and chosen ~= "" then
            SELECTED_CAR = chosen
            WindUI:Notify({
                Title    = "ðŸš• Kendaraan Dipilih",
                Content  = "Menggunakan: " .. SELECTED_CAR,
                Duration = 2
            })
        end
    end
})

SectionRideGO:Button({
    Title    = "ðŸ”„ Refresh Garasi",
    Icon     = "refresh-cw",
    Callback = function()
        local cars = RefreshAllVehicleDropdowns()
        WindUI:Notify({
            Title    = "âœ… Garasi Terdeteksi",
            Content  = "Ditemukan " .. #cars .. " kendaraan!",
            Duration = 3
        })
    end
})

local TabSec = Window:Tab({ Title = "Security", Icon = "shield", Border = true })
local Perlindungan = TabSec:Section({ Title = "Protection", Box = true, BoxBorder = true, Opened = false })
Perlindungan:Toggle({ Title = "Anti-Admin (Auto Leave)", Desc = "Automatically leaves if a staff member joins", Icon = "user-minus", Value = true, Callback = function(on) State.AntiAdmin = on end })
Perlindungan:Toggle({ Title = "Anti-AFK", Desc = "Keeps connection active while botting", Icon = "clock", Value = true, Callback = function(on) State.AntiAFK = on end })

local TabPerf = Window:Tab({ Title = "Performance", Icon = "zap", Border = true })
local HematDaya = TabPerf:Section({ Title = "Power Saving", Box = true, BoxBorder = true, Opened = false })
HematDaya:Toggle({ Title = "Disable Rendering (AFK Mode)", Desc = "Black screen, saves battery, bot keeps running", Value = false, Callback = function(on) ToggleBlackScreen(on) end })

local SectionAntiLag = TabPerf:Section({ Title = "Anti Lag", Box = true, BoxBorder = true, Opened = false })
SectionAntiLag:Toggle({ Title = "Enable Anti Lag", Desc = "Purges particles & locks graphics to minimum", Value = false, Callback = function(on) ToggleAntiLag(on) end })

local SectionPotato = TabPerf:Section({ Title = "Ultra Potato Mode", Box = true, BoxBorder = true, Opened = false })
SectionPotato:Toggle({ Title = "Enable Potato Mode (EXTREME)", Desc = "Destroys terrain, meshes, lighting, sounds for MAX FPS. Mutually exclusive with Anti-Lag.", Value = false, Callback = function(on) TogglePotatoMode(on) end })

local TabCfg = Window:Tab({ Title = "Settings", Icon = "settings", Border = true })
local Konfigurasi = TabCfg:Section({ Title = "Configuration", Box = true, BoxBorder = true, Opened = false })
Konfigurasi:Slider({ Title = "Action Delay (Seconds)", Desc = "Lower is faster, but riskier", Step = 1, Value = { Min = 1, Max = 10, Default = 5 }, Callback = function(v) State.ActionDelay = v end })

local SectionFakeName = TabCfg:Section({ Title = "Spoof Name", Box = true, BoxBorder = true, Opened = false })
SectionFakeName:Input({
    Title = "Spoof Name (Empty = King Akbar)", Placeholder = "King Akbar",
    Callback = function(Text)
        local cleanText = string.gsub(Text or "", "^%s+", "")
        cleanText = string.gsub(cleanText, "%s+$", "")
        State.FakeName = (cleanText == "") and "King Akbar" or cleanText
        if State.FakeNameActive then SpoofApplyNow() end
    end
})
SectionFakeName:Toggle({
    Title = "Enable Spoof Name", Desc = "Changes your display name (Client-sided)", Value = false,
    Callback = function(on)
        State.FakeNameActive = on
        if on then
            SpoofApplyNow()
            WindUI:Notify({ Title = "ðŸŽ­ Spoof Name", Content = "Name changed to: " .. State.FakeName, Duration = 3 })
        else
            SpoofDisableNow()
            WindUI:Notify({ Title = "ðŸŽ­ Spoof Name", Content = "Original name restored.", Duration = 3 })
        end
    end
})

local SectionRedeem = TabCfg:Section({ Title = "Auto Redeem", Box = true, BoxBorder = true, Opened = false })
local redeemCodes = {
    "DRAGDRIVESIMULATORAUGUST26",
    "DDSSPECIALMERDEKA2026",
    "NEWLIGHTSMODIFICATION",
    "DELAYDIKITBARULOMBA",
    "DDSTHX175KROADTO200KLIKES"
}
local function FireRedeemRemote(code)
    pcall(function()
        local remote = Services.ReplicatedStorage:WaitForChild("RedeemCodeEvents"):WaitForChild("Redeem")
        if remote then remote:InvokeServer(code) end
    end)
end
SectionRedeem:Button({
    Title = "ðŸŽ Redeem All Codes", Desc = "Automatically redeems all available codes",
    Callback = function()
        task.spawn(function()
            WindUI:Notify({ Title = "ðŸ”„ Auto Redeem", Content = "Redeeming codes...", Duration = 3 })
            for _, code in ipairs(redeemCodes) do FireRedeemRemote(code); task.wait(2) end
            WindUI:Notify({ Title = "âœ… Auto Redeem", Content = "All codes redeemed!", Duration = 5 })
        end)
    end
})

local TabPreset = Window:Tab({ Title = "Instant Modes", Icon = "car", Border = true })
local ModeCepat = TabPreset:Section({ Title = "Presets", Box = true, BoxBorder = true, Opened = false })
ModeCepat:Button({ Title = "ðŸ›µ SUNDAY RIDE (Safe)",         Callback = function() InjectMesin(1.5,  2000, 0.9,  0.9,  "Sunday Ride Active") end })
ModeCepat:Button({ Title = "ðŸŽï¸ RACING MODE (Aggressive)",  Callback = function() InjectMesin(3.5,  5000, 0.75, 0.75, "Racing Mode Active") end })
ModeCepat:Button({ Title = "ðŸš€ GOD MODE (Max Speed)",       Callback = function() InjectMesin(8,   15000, 0.45, 0.45, "God Mode Active") end })
ModeCepat:Button({ Title = "ðŸ”„ RESET TO DEFAULT",           Callback = function() WindUI:Notify({ Title = "â„¹ï¸ Info", Content = "Respawn vehicle from game menu to reset.", Duration = 5 }) end })

local TabCustom = Window:Tab({ Title = "Custom Tune", Icon = "sliders", Border = true })
local TuneSendiri = TabCustom:Section({ Title = "Manual Tuning", Box = true, BoxBorder = true, Opened = false })
local customHP, customRPM, customRatio, customFD = 2, 5000, 0.8, 0.8
TuneSendiri:Input({ Title = "ðŸ’ª Horsepower Multiplier", Placeholder = "Example: 3",    Callback = function(Text) local val = tonumber(Text) if val then customHP    = val end end })
TuneSendiri:Input({ Title = "ðŸ”¥ RPM Adder",             Placeholder = "Example: 8000", Callback = function(Text) local val = tonumber(Text) if val then customRPM   = val end end })
TuneSendiri:Input({ Title = "âš™ï¸ Gear Ratio Multiplier", Placeholder = "Example: 0.6",  Callback = function(Text) local val = tonumber(Text) if val then customRatio = val end end })
TuneSendiri:Input({ Title = "â›“ï¸ Final Drive Multiplier", Placeholder = "Example: 0.6", Callback = function(Text) local val = tonumber(Text) if val then customFD    = val end end })
TuneSendiri:Button({ Title = "âš¡ INJECT CUSTOM TUNE", Callback = function() InjectMesin(customHP, customRPM, customRatio, customFD, "Custom Tune Active") end })

Window:EditOpenButton({
    Title = "Open King Akbar", Icon = "crown",
    CornerRadius = UDim.new(0, 12), StrokeThickness = 2,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHex("#ffffff")),
        ColorSequenceKeypoint.new(1,   Color3.fromHex("#0a0a0a")),
    }),
    Enabled = true, Draggable = true,
})

local FpsTag = Window:Tag({
    Title = "Fps: ...",
    Color = WindUI:Gradient({
        [0]   = { Color = Color3.fromHex("#0a0a0a"), Transparency = 0 },
        [100] = { Color = Color3.fromHex("#888888"), Transparency = 0 },
    }, { Rotation = 45 }),
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local fps  = math.floor(1 / Services.RunService.RenderStepped:Wait())
            local ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            if FpsTag and FpsTag.SetTitle then
                FpsTag:SetTitle(("Fps: %d | Ping: %d"):format(fps, ping))
            end
        end)
    end
end)

Window:SetIconSize(47)
WindUI:SetTheme("dark")
TabInfo:Select()

WindUI:Notify({
    Title    = "ðŸ‘‘ King Akbar Siap",
    Content  = "Auto Farm Drag Drive Simulator telah dimuat!",
    Duration = 5,
})

task.spawn(function()
    task.wait(2)
    RefreshAllVehicleDropdowns()
end)