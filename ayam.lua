-- ===== VERSION & RELOAD GUARD =====
local VERSION = "2.0.4"

if _G.NOMERCY_ViolenceDistrict_Loaded then
    warn("[King Vypers] Violence District already loaded..")
    if type(_G.NOMERCY_ShutdownHandler) == "function" then
        pcall(_G.NOMERCY_ShutdownHandler)
    end
    task.wait(0.5)
end
_G.NOMERCY_ViolenceDistrict_Loaded = true
_G.NOMERCY_Shutdown = false

-- ===== SERVICES =====
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ===== PLATFORM DETECTION =====
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local DrawingAvailable = (function()
    if isMobile then return false end
    local ok, result = pcall(function() return typeof(Drawing) == "table" and Drawing.new ~= nil end)
    return ok and result == true
end)()

-- ===== NMHUB GLOBAL TABLE =====
local NMHUB = {
    Flags = {},
    Toggles = {},
    Loops = {},
    Connections = {},
    GuiElements = {},
    HookedRemotes = {},
    OriginalState = {
        CanCollide = setmetatable({}, {__mode = "k"}),
        Lighting = {},
        Terrain = {},
        Textures = setmetatable({}, {__mode = "k"}),
        WalkSpeed = 16,
        JumpPower = 50,
    },
    Ready = false,
}

local autoSaveConfig = function() end

function NMHUB:StopLoop(name)
    if self.Loops[name] then
        pcall(task.cancel, self.Loops[name])
        self.Loops[name] = nil
    end
end

function NMHUB:Disconnect(name)
    if self.Connections[name] then
        pcall(function() self.Connections[name]:Disconnect() end)
        self.Connections[name] = nil
    end
end

-- ===== OPTIMIZED HOOKS & ANTI-KICK =====
pcall(function()
    if hookfunction then
        NMHUB.Connections.OldKick = hookfunction(LP.Kick, function() return nil end)
    end
end)

pcall(function()
    if hookfunction then
        NMHUB.Connections.OldTeleport = hookfunction(TeleportService.Teleport, function() return nil end)
        NMHUB.Connections.OldTeleportInstance = hookfunction(TeleportService.TeleportToPlaceInstance, function() return nil end)
    end
end)

function NMHUB:InstallRemoteHook(remotePath, callback)
    local ok, remote = pcall(function()
        local node = ReplicatedStorage
        for segment in remotePath:gmatch("[^.]+") do
            node = node:FindFirstChild(segment)
            if not node then return nil end
        end
        return node
    end)
    if not ok or not remote or not remote:IsA("RemoteEvent") then return false end
    local oldFireServer
    oldFireServer = hookfunction(remote.FireServer, newcclosure(function(...)
        if _G.NOMERCY_Shutdown then return oldFireServer(...) end
        return callback(oldFireServer, ...)
    end))
    table.insert(self.HookedRemotes, { remote = remote, old = oldFireServer })
    return true
end

local _TeleportFallGraceUntil = 0
NMHUB:InstallRemoteHook("Remotes.Mechanics.Fall", function(original, ...)
    if tick() < _TeleportFallGraceUntil then return nil end
    return original(...)
end)

local function performSafeTeleport(targetCFrame, offset)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    _TeleportFallGraceUntil = tick() + 0.6
    hrp.CFrame = targetCFrame + (offset or Vector3.zero)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Landed) end) end
    task.delay(0.05, function()
        if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Landed) end) end
    end)
    return true
end

-- ===== VYPERSLIB LOAD =====
local RAW_URL = "https://raw.githubusercontent.com/AwoakwoakSikat/uikings/refs/heads/main/VypersLib33.lua"
local Vypers  = loadstring(game:HttpGet(RAW_URL))()

if not Vypers then
    error("[King Vypers] CRITICAL: Could not load VypersLib Library.")
    return
end

pcall(function() if Vypers.SetFolder then Vypers:SetFolder("KingVypers") end end)
pcall(function() if Vypers.SetAccent then Vypers:SetAccent(Color3.fromRGB(120, 90, 240)) end end)

pcall(function()
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        NMHUB.OriginalState.WalkSpeed = LP.Character.Humanoid.WalkSpeed
        NMHUB.OriginalState.JumpPower = LP.Character.Humanoid.JumpPower
    end
end)

-- ===== WINDOW CREATION =====
local Window = nil
pcall(function()
    Window = Vypers:CreateWindow({
        Title           = "King Vypers",
        Icon            = "rbxassetid://139467646163013",
        FloatIconRadius = 14,
        SubTitle        = "v2.0",
        Author          = "by Yeremia",
        Background      = "rbxassetid://97514324988224",
        BackgroundTransparency = 0,
        Overlay         = 0.3,
        Size            = UDim2.new(0, 560, 0, 360),
        MinSize         = Vector2.new(480, 300),
        MaxSize         = Vector2.new(720, 480),
        SideBarWidth    = 150,
        Resizable       = true,
        Transparent     = false,
        SurfaceTransparency = 0.3,
        SectionTransparency = 0.3,
        TabTransparency     = 0.3,
        ItemColor    = Color3.fromRGB(40, 40, 60),
        SectionColor = Color3.fromRGB(28, 28, 44),
        TabColor     = Color3.fromRGB(34, 34, 52),
        WindowColor  = Color3.fromRGB(20, 20, 30),
        Accent       = Color3.fromRGB(120, 90, 240),
        ToggleKey   = Enum.KeyCode.RightShift,
        Folder      = "KingVypers",
    })
end)

if not Window then
    error("[King Vypers] Gagal membuat Window UI! VypersLib mungkin error.")
    return
end

-- Safe UI Wrappers to prevent "attempt to call a nil value"
local function SafeNotify(...)
    if Window and Window.Notify then pcall(Window.Notify, Window, ...) end
end

local function SafeDialog(...)
    if Window and Window.Dialog then pcall(Window.Dialog, Window, ...) end
end

if Window.Tag then
    pcall(function()
        Window:Tag({ Title = "BETA", Color = Color3.fromRGB(220, 180, 70) })
        Window:Tag({ Title = "Online", Icon = "bolt", Color = Color3.fromRGB(80, 190, 120) })
    end)
end

NMHUB.Window = Window
NMHUB.Ready = true
_G.NMHUB = NMHUB

-- ===== TABS =====
local TabInformation = Window:CreateTab({ Title = "Information", Icon = "info" })
local TabVisual      = Window:CreateTab({ Title = "Visual", Icon = "eye" })
local TabKiller      = Window:CreateTab({ Title = "Killer", Icon = "combat" })
local TabSurvivor    = Window:CreateTab({ Title = "Survivor", Icon = "shield" })
local TabTeleport    = Window:CreateTab({ Title = "Teleport", Icon = "map" })
local TabAimbot      = Window:CreateTab({ Title = "Aimbot", Icon = "crosshair" })
local TabMisc        = Window:CreateTab({ Title = "Misc", Icon = "cog" })
local TabConfig      = Window:CreateTab({ Title = "Config", Icon = "gear" })
local TabSettings    = Window:CreateTab({ Title = "Settings", Icon = "settings" })

-- ===== INFORMATION TAB =====
local InfoSec = TabInformation:CreateSection({ Title = "Information", Opened = true })
if InfoSec.CreateParagraph then
    InfoSec:CreateParagraph({
        Id = "IntroText",
        Title = "King Vypers",
        Text  = "King Vypers is a 100% free and keyless script.\nJoin our Discord to get the latest updates.",
        Buttons = {
            { Id = "BtnDiscord", Title = "Discord", Variant = "Primary", Icon = "copy", Callback = function()
                local invite = "https://discord.gg/gJJbCyzcMY"
                if setclipboard then
                    pcall(setclipboard, invite)
                    SafeNotify({ Title = "Discord", Content = "Link copied to clipboard!", Type = "success", Duration = 3 })
                else
                    SafeNotify({ Title = "Discord", Content = invite, Type = "info", Duration = 10 })
                end
            end },
        },
    })
end

-- ===== GAME STATE & REMOTES =====
local CollectionService = game:GetService("CollectionService")
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local RemAttacks, RemCarry, RemPallet, RemGen, RemItems, RemHeal, RemWindow

local function ensureRemotes()
    if not Remotes then return false end
    pcall(function()
        if not RemAttacks then RemAttacks = Remotes:WaitForChild("Attacks", 3) end
        if not RemCarry   then RemCarry   = Remotes:WaitForChild("Carry",   3) end
        if not RemPallet  then RemPallet  = Remotes:WaitForChild("Pallet",  3) end
        if not RemGen     then RemGen     = Remotes:WaitForChild("Generator", 3) end
        if not RemItems   then RemItems   = Remotes:WaitForChild("Items",   3) end
        if not RemHeal    then RemHeal    = Remotes:WaitForChild("Healing", 3) end
        if not RemWindow  then RemWindow  = Remotes:WaitForChild("Window", 3) end
    end)
    return RemAttacks ~= nil and RemItems ~= nil
end

local function getRole()
    local team = LP.Team
    return team and team.Name or "None"
end
local function isKiller()   return getRole() == "Killer"    end
local function isSurvivor() return getRole() == "Survivors" end
local function getChar() return LP.Character end

local function isKillerCarrying()
    local char = getChar(); if not char then return false end
    return char:GetAttribute("IsCarrying") == true
end

local function isKillerBusy()
    local char = getChar(); if not char then return true end
    local hum = char:FindFirstChild("Humanoid"); if not hum then return true end
    if char:GetAttribute("IsStunned") then return true end
    if char:GetAttribute("Immobile")  then return true end
    if hum:GetState() == Enum.HumanoidStateType.Physics then return true end
    return false
end

local function findClosestKnockedSurvivor(range)
    local char = getChar(); if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local best, bestDist = nil, range or 30
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and pl.Team and pl.Team.Name == "Survivors" then
            local tc = pl.Character
            if tc then
                local th = tc:FindFirstChild("HumanoidRootPart")
                local hu = tc:FindFirstChild("Humanoid")
                if th and hu and hu.Health > 0 then
                    local knocked  = CollectionService:HasTag(tc, "Knocked")
                    local carried  = tc:GetAttribute("IsCarried")  == true
                    local hooked   = tc:GetAttribute("IsHooked")   == true
                    if knocked and not carried and not hooked then
                        local d = (hrp.Position - th.Position).Magnitude
                        if d < bestDist then bestDist = d; best = tc end
                    end
                end
            end
        end
    end
    return best
end

local function findClosestAliveSurvivor(range)
    local char = getChar(); if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local best, bestDist = nil, range or 30
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and pl.Team and pl.Team.Name == "Survivors" then
            local tc = pl.Character
            if tc then
                local th = tc:FindFirstChild("HumanoidRootPart")
                local hu = tc:FindFirstChild("Humanoid")
                if th and hu and hu.Health > 20 then
                    local knocked = CollectionService:HasTag(tc, "Knocked")
                    local hooked  = tc:GetAttribute("IsHooked") == true
                    if not knocked and not hooked then
                        local d = (hrp.Position - th.Position).Magnitude
                        if d < bestDist then bestDist = d; best = tc end
                    end
                end
            end
        end
    end
    return best
end

local function findClosestHookPoint()
    local char = getChar(); if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local best, bestDist = nil, 80
    for _, hook in ipairs(CollectionService:GetTagged("HookPoint")) do
        local pos
        if hook:IsA("BasePart") then
            pos = hook.Position
        elseif hook:IsA("Model") then
            pos = hook:GetPivot().Position
        end
        if pos then
            local occupied = hook:GetAttribute("IsOccupied") or hook:GetAttribute("Occupied")
            if not occupied then
                local d = (hrp.Position - pos).Magnitude
                if d < bestDist then bestDist = d; best = hook end
            end
        end
    end
    return best
end

local _visualStopESP    = function() end
local _visualRestoreFog = function() end
local _visualRestoreFb  = function() end
local _visualRestoreFOV = function() end
local _mapCache = { Generators={}, Gates={}, Hooks={}, Pallets={}, Windows={} }

-- ===== VISUAL TAB =====
do
local _espHighlights  = {}
local _espBillboards  = {}
local _espConn        = nil
local _espLastUpdate  = 0
local _espUpdateRate  = 0.5
local _espMaxDist     = 500
local _espMaxObjects  = 100
local _espShowDist    = true

_mapCache    = { Generators={}, Gates={}, Hooks={}, Pallets={}, Windows={} }
local _mapLastScan = 0
local MAP_SCAN_IV  = 3.5

local _lighting = game:GetService("Lighting")
local _visState = { fogSaved=nil, fullbrightSaved=nil, origFOV=nil }

local function _vi(obj)
    if not obj then return false end
    local ok,r = pcall(function() return obj.Parent end)
    return ok and r ~= nil
end
local function _rootOf(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    end
end
local function _scanMap()
    local now = tick()
    if now - _mapLastScan < MAP_SCAN_IV then return end
    _mapLastScan = now
    local c = { Generators={}, Gates={}, Hooks={}, Pallets={}, Windows={} }
    for _, obj in ipairs(CollectionService:GetTagged("Generator")) do
        if obj:IsA("Model") and obj:IsDescendantOf(workspace) then
            local p2 = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if p2 then table.insert(c.Generators, {model=obj, part=p2, position=p2.Position}) end
        end
    end
    local useNameGeneratorFallback = #c.Generators == 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = obj.Name
            if n == "Generator" and useNameGeneratorFallback then
                local p2 = obj:FindFirstChildWhichIsA("BasePart")
                if p2 then table.insert(c.Generators, {model=obj, part=p2, position=p2.Position}) end
            elseif n == "Gate" then
                table.insert(c.Gates, obj)
            elseif n == "Hook" or obj:GetAttribute("IsHook") then
                if obj:FindFirstChildWhichIsA("BasePart") then table.insert(c.Hooks, obj) end
            elseif n == "Pallet" then
                table.insert(c.Pallets, obj)
            elseif n == "Window" then
                table.insert(c.Windows, obj)
            end
        end
    end
    _mapCache = c
end

local function _espDistance(obj)
    local rp = _vi(obj) and _rootOf(obj) or nil
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not rp or not myHRP then return 0 end
    return (myHRP.Position - rp.Position).Magnitude
end

local function _espObjectCount()
    local count = 0
    for _, h in pairs(_espHighlights) do
        if _vi(h) then count = count + 1 end
    end
    return count
end

local function _addHL(obj, col)
    if not _vi(obj) then return end
    if _espDistance(obj) > _espMaxDist then
        local old = _espHighlights[obj]
        if old then pcall(function() if _vi(old) then old:Destroy() end end) end
        _espHighlights[obj] = nil
        return
    end
    if _espHighlights[obj] and _vi(_espHighlights[obj]) then return end
    if _espObjectCount() >= _espMaxObjects then return end
    if _espHighlights[obj] then _espHighlights[obj] = nil end
    local ex = obj:FindFirstChild("_NMH")
    if ex then pcall(function() ex:Destroy() end) end
    pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "_NMH"; h.Adornee = obj
        h.FillColor = col; h.OutlineColor = col
        h.FillTransparency = 0.5; h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = obj; _espHighlights[obj] = h
    end)
end
local function _remHL(obj)
    if _espHighlights[obj] then
        pcall(function()
            if _vi(_espHighlights[obj]) then _espHighlights[obj]:Destroy() end
        end)
        _espHighlights[obj] = nil
    end
    local ex = obj:FindFirstChild("_NMH")
    if ex then pcall(function() ex:Destroy() end) end
end
local function _addLBL(obj, text, col)
    if not _vi(obj) then return end
    local rp = _rootOf(obj); if not rp then return end
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local dist = myHRP and (myHRP.Position - rp.Position).Magnitude or 0
    if dist > _espMaxDist then
        if _espBillboards[obj] and _vi(_espBillboards[obj]) then
            pcall(function() _espBillboards[obj]:Destroy() end)
            _espBillboards[obj] = nil
        end
        return
    end
    local lbl = _espShowDist and string.format("%s\n%.0fm", text, dist) or text
    if _espBillboards[obj] and _vi(_espBillboards[obj]) then
        local tl = _espBillboards[obj]:FindFirstChild("TL")
        if tl then tl.Text = lbl end
        return
    end
    _espBillboards[obj] = nil
    pcall(function()
        for _, c in ipairs(obj:GetChildren()) do
            if c:IsA("BillboardGui") and c.Name == "_NMBL" then c:Destroy() end
        end
        local bb = Instance.new("BillboardGui")
        bb.Name = "_NMBL"; bb.Size = UDim2.new(0,200,0,50)
        bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0,3,0)
        bb.Adornee = rp; bb.Parent = obj
        local tl = Instance.new("TextLabel")
        tl.Name = "TL"; tl.Size = UDim2.new(1,0,1,0)
        tl.BackgroundTransparency = 1
        tl.TextColor3 = col
        tl.TextStrokeColor3 = Color3.new(0,0,0); tl.TextStrokeTransparency = 0
        tl.Font = Enum.Font.SourceSansBold; tl.TextSize = 14
        tl.TextScaled = false; tl.TextWrapped = true; tl.Text = lbl
        tl.Parent = bb; _espBillboards[obj] = bb
    end)
end
local function _remLBL(obj)
    if _espBillboards[obj] then
        pcall(function()
            if _vi(_espBillboards[obj]) then _espBillboards[obj]:Destroy() end
        end)
        _espBillboards[obj] = nil
    end
end
local function _clearESP()
    for obj in pairs(_espHighlights) do _remHL(obj) end
    for obj in pairs(_espBillboards) do _remLBL(obj) end
    _espHighlights = {}; _espBillboards = {}
end

local function _distanceCull()
    for obj in pairs(_espHighlights) do
        if not _vi(obj) or _espDistance(obj) > _espMaxDist then _remHL(obj) end
    end
    for obj in pairs(_espBillboards) do
        if not _vi(obj) or _espDistance(obj) > _espMaxDist then _remLBL(obj) end
    end
end

local function _upPlayers()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and pl.Character and pl.Team then
            local tn = pl.Team.Name
            if tn == "Killer" and NMHUB.Flags.Visual_KillerESP then
                _addHL(pl.Character, Color3.fromRGB(255,50,50))
                _addLBL(pl.Character, pl.Name.."\n[KILLER]", Color3.fromRGB(255,50,50))
            elseif tn == "Survivors" and NMHUB.Flags.Visual_SurvivorESP then
                _addHL(pl.Character, Color3.fromRGB(50,255,50))
                _addLBL(pl.Character, pl.Name.."\n[SURVIVOR]", Color3.fromRGB(50,255,50))
            else
                _remHL(pl.Character); _remLBL(pl.Character)
            end
        end
    end
end
local function _upGens()
    _scanMap()
    for _, g in ipairs(_mapCache.Generators) do
        if NMHUB.Flags.Visual_GeneratorESP then
            local rp = g.model:GetAttribute("RepairProgress") or 0
            local pct = math.floor(rp)
            local lbl = pct >= 100
                and "Generator [DONE]"
                or string.format("Generator [%d%%]", pct)
            _addHL(g.model, Color3.fromRGB(203,132,66))
            _addLBL(g.model, lbl, Color3.fromRGB(203,132,66))
        else _remHL(g.model); _remLBL(g.model) end
    end
end
local function _upGates()
    _scanMap()
    for _, obj in ipairs(_mapCache.Gates) do
        if NMHUB.Flags.Visual_GateESP then
            _addHL(obj, Color3.fromRGB(255,255,255))
            _addLBL(obj, "Gate", Color3.fromRGB(255,255,255))
        else _remHL(obj); _remLBL(obj) end
    end
end
local function _upHooks()
    _scanMap()
    local hooks = _mapCache.Hooks
    if not NMHUB.Flags.Visual_HookESP then
        for _, obj in ipairs(hooks) do
            _remHL(obj); _remLBL(obj)
            if obj:FindFirstChild("Model") then
                for _, pt in ipairs(obj.Model:GetDescendants()) do
                    if pt:IsA("MeshPart") then _remHL(pt) end
                end
            end
        end
        return
    end
    if NMHUB.Flags.Visual_ClosestHookOnly then
        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local best, bd = nil, math.huge
        for _, obj in ipairs(hooks) do
            local bp = obj:FindFirstChildWhichIsA("BasePart")
            if bp and myHRP then
                local d = (bp.Position - myHRP.Position).Magnitude
                if d < bd then bd = d; best = obj end
            end
        end
        for _, obj in ipairs(hooks) do
            _remHL(obj); _remLBL(obj)
            if obj:FindFirstChild("Model") then
                for _, pt in ipairs(obj.Model:GetDescendants()) do
                    if pt:IsA("MeshPart") then _remHL(pt) end
                end
            end
        end
        if best then
            if best:FindFirstChild("Model") then
                for _, pt in ipairs(best.Model:GetDescendants()) do
                    if pt:IsA("MeshPart") then
                        _addHL(pt, Color3.fromRGB(255,255,0))
                    end
                end
            end
            _addLBL(best, "CLOSEST HOOK", Color3.fromRGB(255,255,0))
        end
    else
        for _, obj in ipairs(hooks) do
            if obj:FindFirstChild("Model") then
                for _, pt in ipairs(obj.Model:GetDescendants()) do
                    if pt:IsA("MeshPart") then _addHL(pt, Color3.fromRGB(255,0,0)) end
                end
            end
            _addLBL(obj, "Hook", Color3.fromRGB(255,0,0))
        end
    end
end
local function _upPallets()
    _scanMap()
    for _, obj in ipairs(_mapCache.Pallets) do
        if NMHUB.Flags.Visual_PalletESP then
            _addHL(obj, Color3.fromRGB(255,215,0))
            _addLBL(obj, "Pallet", Color3.fromRGB(255,215,0))
        else _remHL(obj); _remLBL(obj) end
    end
end
local function _upWindows()
    _scanMap()
    for _, obj in ipairs(_mapCache.Windows) do
        if NMHUB.Flags.Visual_WindowESP then
            _addHL(obj, Color3.fromRGB(173,216,230))
            _addLBL(obj, "Window", Color3.fromRGB(173,216,230))
        else _remHL(obj); _remLBL(obj) end
    end
end
local function _upAllESP()
    if _G.NOMERCY_Shutdown then return end
    local now = tick()
    if now - _espLastUpdate < _espUpdateRate then return end
    _espLastUpdate = now
    for obj, h in pairs(_espHighlights) do
        if not _vi(obj) or not _vi(h) then _espHighlights[obj] = nil end
    end
    for obj, bb in pairs(_espBillboards) do
        if not _vi(obj) or not _vi(bb) then _espBillboards[obj] = nil end
    end
    _distanceCull()
    pcall(_upPlayers); pcall(_upGens); pcall(_upGates)
    pcall(_upHooks); pcall(_upPallets); pcall(_upWindows)
end
local function _startESP()
    if _espConn then return end
    _espConn = RunService.Heartbeat:Connect(_upAllESP)
    NMHUB.Connections.ESP = _espConn
end
local function _stopESP()
    if _espConn then
        pcall(function() _espConn:Disconnect() end)
        _espConn = nil; NMHUB.Connections.ESP = nil
    end
    _clearESP()
end
local function _anyESP()
    return NMHUB.Flags.Visual_KillerESP or NMHUB.Flags.Visual_SurvivorESP
        or NMHUB.Flags.Visual_GeneratorESP or NMHUB.Flags.Visual_GateESP
        or NMHUB.Flags.Visual_HookESP or NMHUB.Flags.Visual_PalletESP
        or NMHUB.Flags.Visual_WindowESP
end

local function _saveLightingBaseline()
    if _visState.fogSaved or _visState.fullbrightSaved then return end
    local at = _lighting:FindFirstChildOfClass("Atmosphere")
    _visState.lightingBaseline = {
        FogStart=_lighting.FogStart, FogEnd=_lighting.FogEnd,
        FogColor=_lighting.FogColor,
        Brightness=_lighting.Brightness, Ambient=_lighting.Ambient,
        OutdoorAmbient=_lighting.OutdoorAmbient, ClockTime=_lighting.ClockTime,
        GlobalShadows=_lighting.GlobalShadows,
        atmo=at, atmoDens=at and at.Density
    }
end

local function _applyLightingState()
    _saveLightingBaseline()
    local noFog = NMHUB.Flags.Visual_NoFog
    local fullbright = NMHUB.Flags.Visual_Fullbright
    if not noFog and not fullbright then
        local s = _visState.lightingBaseline
        if s then
            pcall(function() _lighting.FogStart = s.FogStart end)
            pcall(function() _lighting.FogEnd = s.FogEnd end)
            pcall(function() _lighting.FogColor = s.FogColor end)
            pcall(function() _lighting.Brightness = s.Brightness end)
            pcall(function() _lighting.Ambient = s.Ambient end)
            pcall(function() _lighting.OutdoorAmbient = s.OutdoorAmbient end)
            pcall(function() _lighting.ClockTime = s.ClockTime end)
            pcall(function() _lighting.GlobalShadows = s.GlobalShadows end)
            if s.atmo and _vi(s.atmo) then
                pcall(function() s.atmo.Density = s.atmoDens or s.atmo.Density end)
            end
        end
        _visState.fogSaved = nil
        _visState.fullbrightSaved = nil
        _visState.lightingBaseline = nil
        return
    end
    if fullbright then
        _lighting.Brightness=2; _lighting.Ambient=Color3.new(1,1,1)
        _lighting.OutdoorAmbient=Color3.new(1,1,1); _lighting.ClockTime=14
        _lighting.GlobalShadows=false
        _visState.fullbrightSaved = true
    end
    if noFog then
        _lighting.FogStart = 9e9; _lighting.FogEnd = 9e9
        local at = _lighting:FindFirstChildOfClass("Atmosphere")
        if at then at.Density = 0 end
        _visState.fogSaved = true
    end
    if fullbright then
        _lighting.FogStart=0; _lighting.FogEnd=9e9
    end
end

local function _noFogOn() _applyLightingState() end
local function _noFogOff() _applyLightingState() end
local function _fbOn() _applyLightingState() end
local function _fbOff() _applyLightingState() end
local function _fovOn()
    local cam = workspace.CurrentCamera; if not cam then return end
    if not _visState.origFOV then _visState.origFOV = cam.FieldOfView end
    cam.FieldOfView = NMHUB.Flags.Visual_FOVValue or 70
end
local function _fovOff()
    local cam = workspace.CurrentCamera; if not cam then return end
    if _visState.origFOV then
        cam.FieldOfView = _visState.origFOV; _visState.origFOV = nil
    end
end

_visualStopESP    = _stopESP
_visualRestoreFog = _noFogOff
_visualRestoreFb  = _fbOff
_visualRestoreFOV = _fovOff

-- ===== VISUAL TAB UI =====
local VisualPlayers = TabVisual:CreateSection({ Title = "Players", Opened = true })
VisualPlayers:CreateToggle({ Id = "Visual_KillerESP", Title = "Killer ESP", Desc = "Highlight killer in red with name label", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_KillerESP = v
    if v then _startESP() else
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Team and pl.Team.Name=="Killer" and pl.Character then
                _remHL(pl.Character); _remLBL(pl.Character)
            end
        end
        if not _anyESP() then _stopESP() end
    end
    autoSaveConfig()
end })
VisualPlayers:CreateToggle({ Id = "Visual_SurvivorESP", Title = "Survivor ESP", Desc = "Highlight survivors in green with name label", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_SurvivorESP = v
    if v then _startESP() else
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Team and pl.Team.Name=="Survivors" and pl.Character then
                _remHL(pl.Character); _remLBL(pl.Character)
            end
        end
        if not _anyESP() then _stopESP() end
    end
    autoSaveConfig()
end })

local VisualObjects = TabVisual:CreateSection({ Title = "World Objects" })
VisualObjects:CreateToggle({ Id = "Visual_GeneratorESP", Title = "Generator ESP", Desc = "Highlight generators in orange", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_GeneratorESP = v
    if v then _startESP() else
        for _, g in ipairs(_mapCache.Generators) do _remHL(g.model); _remLBL(g.model) end
        if not _anyESP() then _stopESP() end
    end
    autoSaveConfig()
end })
VisualObjects:CreateToggle({ Id = "Visual_GateESP", Title = "Gate ESP", Desc = "Highlight exit gates in white", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_GateESP = v
    if v then _startESP() else
        for _, obj in ipairs(_mapCache.Gates) do _remHL(obj); _remLBL(obj) end
        if not _anyESP() then _stopESP() end
    end
    autoSaveConfig()
end })
VisualObjects:CreateToggle({ Id = "Visual_HookESP", Title = "Hook ESP", Desc = "Highlight hooks in red (closest = yellow)", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_HookESP = v
    if v then _startESP()
    else pcall(_upHooks); if not _anyESP() then _stopESP() end end
    autoSaveConfig()
end })
VisualObjects:CreateToggle({ Id = "Visual_ClosestHookOnly", Title = "Closest Hook Only", Desc = "Show only nearest hook highlighted in yellow", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_ClosestHookOnly = v
    if NMHUB.Flags.Visual_HookESP then pcall(_upHooks) end
    autoSaveConfig()
end })
VisualObjects:CreateToggle({ Id = "Visual_PalletESP", Title = "Pallet ESP", Desc = "Highlight pallets in yellow", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_PalletESP = v
    if v then _startESP() else
        for _, obj in ipairs(_mapCache.Pallets) do _remHL(obj); _remLBL(obj) end
        if not _anyESP() then _stopESP() end
    end
    autoSaveConfig()
end })
VisualObjects:CreateToggle({ Id = "Visual_WindowESP", Title = "Window ESP", Desc = "Highlight vaultable windows in light blue", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_WindowESP = v
    if v then _startESP() else
        for _, obj in ipairs(_mapCache.Windows) do _remHL(obj); _remLBL(obj) end
        if not _anyESP() then _stopESP() end
    end
    autoSaveConfig()
end })

local VisualCamera = TabVisual:CreateSection({ Title = "Camera" })
VisualCamera:CreateToggle({ Id = "Visual_NoFog", Title = "Remove Fog", Desc = "Disable fog and atmosphere (saves original)", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_NoFog = v
    if v then pcall(_noFogOn) else pcall(_noFogOff) end
    autoSaveConfig()
end })
VisualCamera:CreateToggle({ Id = "Visual_Fullbright", Title = "Fullbright", Desc = "Maximum brightness, no shadows, no fog", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_Fullbright = v
    if v then pcall(_fbOn) else pcall(_fbOff) end
    autoSaveConfig()
end })
VisualCamera:CreateToggle({ Id = "Visual_CustomFOV", Title = "Custom FOV", Desc = "Override camera field of view", Default = false, Callback = function(v)
    NMHUB.Flags.Visual_CustomFOV = v
    if v then pcall(_fovOn) else pcall(_fovOff) end
    autoSaveConfig()
end })
VisualCamera:CreateSlider({ Id = "Visual_FOVValue", Title = "Field of View", Desc = "Camera FOV value (default 70)", Min = 30, Max = 120, Increment = 1, Suffix = "°", Default = 70, Callback = function(v)
    NMHUB.Flags.Visual_FOVValue = v
    if NMHUB.Flags.Visual_CustomFOV then pcall(_fovOn) end
    autoSaveConfig()
end })

local VisualSettings = TabVisual:CreateSection({ Title = "ESP Settings" })
VisualSettings:CreateToggle({ Id = "Visual_ShowDist", Title = "Show Distance", Desc = "Display meters on ESP labels", Default = true, Callback = function(v)
    NMHUB.Flags.Visual_ShowDist = v; _espShowDist = v
    autoSaveConfig()
end })
VisualSettings:CreateSlider({ Id = "Visual_MaxDist", Title = "Max Distance", Desc = "Hide ESP beyond this range (studs)", Min = 100, Max = 1000, Increment = 10, Suffix = " studs", Default = 500, Callback = function(v)
    NMHUB.Flags.Visual_MaxDist = v; _espMaxDist = v
    autoSaveConfig()
end })
VisualSettings:CreateSlider({ Id = "Visual_UpdateRate", Title = "Update Rate", Desc = "Seconds between ESP refresh", Min = 0.1, Max = 2.0, Increment = 0.1, Suffix = "s", Default = 0.5, Callback = function(v)
    NMHUB.Flags.Visual_UpdateRate = v; _espUpdateRate = v
    autoSaveConfig()
end })
VisualSettings:CreateSlider({ Id = "Visual_MaxObjects", Title = "Max ESP Objects", Desc = "Cap total highlighted objects", Min = 25, Max = 500, Increment = 5, Default = 100, Callback = function(v)
    NMHUB.Flags.Visual_MaxObjects = v; _espMaxObjects = v
    autoSaveConfig()
end })

end -- do (Visual Tab)

-- ===== KILLER TAB =====
local startKillerDispatcher = function() end
local stopKillerDispatcher  = function() end
local stepAutoAttack
local stepBurstAttack
local stepInfiniteLunge
local stepInstantKill
local stepDestroyPallets
local stepFullGenBreak
local stepAutoHook
local stepNoPalletStun
local stepNoSlowdown
local applyHitboxExpand
local removeHitboxExpand
local stopNoPalletStunWatchdog
local _hookState = "idle"

-- ===== KILLER TAB UI =====
do
local KillerCombat = TabKiller:CreateSection({ Title = "Combat", Opened = true })

KillerCombat:CreateToggle({ Id = "Killer_AutoAttack", Title = "Auto Attack", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_AutoAttack = v
    startKillerDispatcher()
    autoSaveConfig()
end })

KillerCombat:CreateSlider({ Id = "Killer_AutoAttackRange", Title = "Attack Range", Min = 5, Max = 30, Increment = 1, Suffix = " studs", Default = 15, Callback = function(v)
    NMHUB.Flags.Killer_AutoAttackRange = v
    autoSaveConfig()
end })

KillerCombat:CreateToggle({ Id = "Killer_BurstAttack", Title = "Burst Attack", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_BurstAttack = v
    startKillerDispatcher()
    autoSaveConfig()
end })

KillerCombat:CreateToggle({ Id = "Killer_HitboxExpand", Title = "Hitbox Expand", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_HitboxExpand = v
    if v then
        applyHitboxExpand()
        startKillerDispatcher()
    else
        removeHitboxExpand()
    end
    autoSaveConfig()
end })

KillerCombat:CreateSlider({ Id = "Killer_HitboxSize", Title = "Hitbox Size", Min = 5, Max = 50, Increment = 1, Suffix = " studs", Default = 15, Callback = function(v)
    NMHUB.Flags.Killer_HitboxSize = v
    if NMHUB.Flags.Killer_HitboxExpand then
        applyHitboxExpand()
    end
    autoSaveConfig()
end })

KillerCombat:CreateToggle({ Id = "Killer_InfiniteLunge", Title = "Infinite Lunge", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_InfiniteLunge = v
    startKillerDispatcher()
    autoSaveConfig()
end })

local KillerInstantKill = TabKiller:CreateSection({ Title = "Instant Kill" })

KillerInstantKill:CreateToggle({ Id = "Killer_InstantKill", Title = "Instant Kill", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_InstantKill = v
    startKillerDispatcher()
    autoSaveConfig()
end })

KillerInstantKill:CreateSlider({ Id = "Killer_InstantKillRange", Title = "Instant Kill Range", Min = 10, Max = 200, Increment = 5, Suffix = " studs", Default = 40, Callback = function(v)
    NMHUB.Flags.Killer_InstantKillRange = v
    autoSaveConfig()
end })

local KillerMapControl = TabKiller:CreateSection({ Title = "Map Control" })

KillerMapControl:CreateToggle({ Id = "Killer_DestroyPallets", Title = "Destroy Pallets", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_DestroyPallets = v
    startKillerDispatcher()
    autoSaveConfig()
end })

KillerMapControl:CreateToggle({ Id = "Killer_FullGenBreak", Title = "Full Gen Break", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_FullGenBreak = v
    startKillerDispatcher()
    autoSaveConfig()
end })

local KillerUtility = TabKiller:CreateSection({ Title = "Utility" })

KillerUtility:CreateToggle({ Id = "Killer_AutoHook", Title = "Auto Hook", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_AutoHook = v
    if not v then _hookState = "idle" end
    startKillerDispatcher()
    autoSaveConfig()
end })

KillerUtility:CreateToggle({ Id = "Killer_AntiBlind", Title = "Anti Blind", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_AntiBlind = v
    startKillerDispatcher()
    autoSaveConfig()
end })

KillerUtility:CreateToggle({ Id = "Killer_NoPalletStun", Title = "No Pallet Stun", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_NoPalletStun = v
    if v then startKillerDispatcher() else stopNoPalletStunWatchdog() end
    autoSaveConfig()
end })

KillerUtility:CreateToggle({ Id = "Killer_NoSlowdown", Title = "No Slowdown", Default = false, Callback = function(v)
    NMHUB.Flags.Killer_NoSlowdown = v
    startKillerDispatcher()
    autoSaveConfig()
end })

end -- ===== END KILLER TAB UI =====

-- ===== SURVIVOR TAB =====
local startAutoSkillCheck, stopAutoSkillCheck
local startFastRepair,     stopFastRepair
local startInstantGen,     stopInstantGen
local startAutoParry,      stopAutoParry
local startAutoWiggle,     stopAutoWiggle
local startInstantHeal,    stopInstantHeal
local startNoFallDmg,      stopNoFallDmg
local startFleeKiller,     stopFleeKiller
local startKillerAlert,    stopKillerAlert
local startAutoEscape,     stopAutoEscape
local startFastVault,      stopFastVault
local startSurvDispatcher, stopSurvDispatcher

local SurvivorObjectives = TabSurvivor:CreateSection({ Title = "Objectives", Opened = true })

SurvivorObjectives:CreateToggle({ Id = "Surv_AutoSkillCheck", Title = "Auto SkillCheck", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_AutoSkillCheck = v
    if v then startAutoSkillCheck() else stopAutoSkillCheck() end
    autoSaveConfig()
end })

SurvivorObjectives:CreateToggle({ Id = "Surv_FastRepair", Title = "Fast Repair", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_FastRepair = v
    if v then startFastRepair() else stopFastRepair() end
    autoSaveConfig()
end })

SurvivorObjectives:CreateToggle({ Id = "Surv_InstantGen", Title = "Instant Generator", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_InstantGen = v
    if v then startInstantGen() else stopInstantGen() end
    if v then
        SafeNotify({ Title = "⚠ Instant Generator", Content = "HIGH DETECTION RISK — use sparingly!", Type = "warning", Duration = 5 })
    end
    autoSaveConfig()
end })

local SurvivorDefense = TabSurvivor:CreateSection({ Title = "Defense" })

SurvivorDefense:CreateToggle({ Id = "Surv_AutoParry", Title = "Auto Parry", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_AutoParry = v
    if v then startAutoParry() else stopAutoParry() end
    autoSaveConfig()
end })

SurvivorDefense:CreateSlider({ Id = "Surv_ParryRange", Title = "Parry Range", Min = 5, Max = 40, Increment = 1, Suffix = " studs", Default = 20, Callback = function(v)
    NMHUB.Flags.Surv_ParryRange = v
    autoSaveConfig()
end })

SurvivorDefense:CreateToggle({ Id = "Surv_AutoWiggle", Title = "Auto Wiggle", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_AutoWiggle = v
    if v then startAutoWiggle() else stopAutoWiggle() end
    autoSaveConfig()
end })

SurvivorDefense:CreateToggle({ Id = "Surv_InstantHeal", Title = "Instant Heal", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_InstantHeal = v
    if v then startInstantHeal() else stopInstantHeal() end
    if v then
        SafeNotify({ Title = "⚠ Instant Heal", Content = "HIGH DETECTION RISK — use sparingly!", Type = "warning", Duration = 5 })
    end
    autoSaveConfig()
end })

SurvivorDefense:CreateToggle({ Id = "Surv_NoFallDmg", Title = "No Fall Damage", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_NoFallDmg = v
    if v then startNoFallDmg() else stopNoFallDmg() end
    autoSaveConfig()
end })

SurvivorDefense:CreateToggle({ Id = "Surv_NoSlowdown", Title = "No Slowdown", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_NoSlowdown = v
    startSurvDispatcher()
    autoSaveConfig()
end })

local SurvivorSafety = TabSurvivor:CreateSection({ Title = "Safety & Movement" })

SurvivorSafety:CreateToggle({ Id = "Surv_FastVault", Title = "Fast Vault", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_FastVault = v
    if v then startFastVault() else stopFastVault() end
    autoSaveConfig()
end })

SurvivorSafety:CreateToggle({ Id = "Surv_FleeKiller", Title = "Flee Killer", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_FleeKiller = v
    if v then startFleeKiller() else stopFleeKiller() end
    autoSaveConfig()
end })

SurvivorSafety:CreateSlider({ Id = "Surv_FleeDist", Title = "Flee Distance", Min = 10, Max = 60, Increment = 5, Suffix = " studs", Default = 30, Callback = function(v)
    NMHUB.Flags.Surv_FleeDist = v
    autoSaveConfig()
end })

SurvivorSafety:CreateToggle({ Id = "Surv_KillerAlert", Title = "Killer Alert", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_KillerAlert = v
    if v then startKillerAlert() else stopKillerAlert() end
    autoSaveConfig()
end })

SurvivorSafety:CreateSlider({ Id = "Surv_AlertRange", Title = "Alert Range", Min = 10, Max = 80, Increment = 5, Suffix = " studs", Default = 35, Callback = function(v)
    NMHUB.Flags.Surv_AlertRange = v
    autoSaveConfig()
end })

SurvivorSafety:CreateToggle({ Id = "Surv_AutoEscape", Title = "Auto Escape", Default = false, Callback = function(v)
    NMHUB.Flags.Surv_AutoEscape = v
    if v then startAutoEscape() else stopAutoEscape() end
    if v then
        SafeNotify({ Title = "⚠ Auto Escape", Content = "EXTREME DETECTION RISK — expect bans!", Type = "error", Duration = 6 })
    end
    autoSaveConfig()
end })


-- ===== KILLER STEP FUNCTIONS =====
local _lastAutoAttack   = 0
local _lastInstantKill  = 0
local _lastLunge        = 0
local _lastHookAction   = 0
local _lastPalletBreak  = 0
local _lastGenBreak     = 0
_hookState              = "idle"

local _killerDispFrame = 0
local _killerDispConn  = nil

local function anyKillerFeatureOn()
    return NMHUB.Flags.Killer_AutoAttack
        or NMHUB.Flags.Killer_InfiniteLunge
        or NMHUB.Flags.Killer_InstantKill
        or NMHUB.Flags.Killer_DestroyPallets
        or NMHUB.Flags.Killer_FullGenBreak
        or NMHUB.Flags.Killer_AutoHook
        or NMHUB.Flags.Killer_NoPalletStun
        or NMHUB.Flags.Killer_NoSlowdown
        or NMHUB.Flags.Killer_AntiBlind
        or NMHUB.Flags.Killer_HitboxExpand
end

stepAutoAttack = function()
    if not NMHUB.Flags.Killer_AutoAttack or not isKiller() then return end
    if isKillerBusy() or isKillerCarrying() then return end
    if (tick() - _lastAutoAttack) < 0.3 then return end
    if not ensureRemotes() then return end
    local range = NMHUB.Flags.Killer_AutoAttackRange or 15
    local target = findClosestAliveSurvivor(range)
    if not target then return end
    local ba = RemAttacks and RemAttacks:FindFirstChild("BasicAttack")
    if ba then
        pcall(function() ba:FireServer() end)
        _lastAutoAttack = tick()
    end
end

stepInfiniteLunge = function()
    if not NMHUB.Flags.Killer_InfiniteLunge or not isKiller() then return end
    if isKillerBusy() then return end
    if (tick() - _lastLunge) < 0.4 then return end
    if not ensureRemotes() then return end
    local lu = RemAttacks and RemAttacks:FindFirstChild("Lunge")
    if lu then
        pcall(function() lu:FireServer() end)
        _lastLunge = tick()
    end
end

stepInstantKill = function()
    if not NMHUB.Flags.Killer_InstantKill or not isKiller() then return end
    if isKillerBusy() or isKillerCarrying() then return end
    if (tick() - _lastInstantKill) < 0.5 then return end
    if not ensureRemotes() then return end
    local char = getChar(); if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local range = NMHUB.Flags.Killer_InstantKillRange or 40
    local target = findClosestAliveSurvivor(range)
    if not target then return end
    local tHRP = target:FindFirstChild("HumanoidRootPart"); if not tHRP then return end
    
    local lookVector = tHRP.CFrame.LookVector
    local behindPos = tHRP.Position - (lookVector * 2.5)
    
    hrp.CFrame = CFrame.new(behindPos, tHRP.Position)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    
    local ba = RemAttacks:FindFirstChild("BasicAttack")
    local lu = RemAttacks:FindFirstChild("Lunge")
    
    local function fireAttack()
        if ba then pcall(function() ba:FireServer() end) end
        if lu then pcall(function() lu:FireServer() end) end
    end
    
    fireAttack()
    
    task.defer(function()
        if _G.NOMERCY_Shutdown or not NMHUB.Flags.Killer_InstantKill then return end
        if target and target.Parent then fireAttack() end
    end)
    
    task.delay(0.06, function()
        if _G.NOMERCY_Shutdown or not NMHUB.Flags.Killer_InstantKill then return end
        if target and target.Parent then fireAttack() end
    end)
    
    _lastInstantKill = tick()
end

stepDestroyPallets = function()
    if not NMHUB.Flags.Killer_DestroyPallets or not isKiller() then return end
    if (tick() - _lastPalletBreak) < 1.5 then return end
    if not ensureRemotes() then return end
    local jason = RemPallet and RemPallet:FindFirstChild("Jason")
    if not jason then return end
    local dg = jason:FindFirstChild("Destroy-Global")
    if dg then
        pcall(function() dg:FireServer() end)
        _lastPalletBreak = tick()
    end
end

stepFullGenBreak = function()
    if not NMHUB.Flags.Killer_FullGenBreak or not isKiller() then return end
    if (tick() - _lastGenBreak) < 2.0 then return end
    if not ensureRemotes() then return end
    local bge = RemGen and RemGen:FindFirstChild("BreakGenEvent")
    if not bge then return end
    local gens = CollectionService:GetTagged("GeneratorPoint")
    if #gens == 0 then return end
    for _, gp in ipairs(gens) do
        local prog = gp.Parent and gp.Parent:GetAttribute("RepairProgress") or 0
        if prog > 0 then
            pcall(function() bge:FireServer(gp) end)
        end
    end
    _lastGenBreak = tick()
end

NMHUB._hook = {
    step             = 0,
    stepTime         = 0,
    stateTime        = 0,
    retries          = 0,
    pickupRetryTime  = 0,
    pickupRetries    = 0,
    lockedHook       = nil,
    lockedSurv       = nil,
    delays = {
        Tick        = 0.15,
        Pickup      = 0.8,
        Travel      = 0.4,
        Phase       = 0.3,
        Event       = 0.4,
        Commit      = 0.5,
        PickupRetry = 0.3,
        Cooldown    = 1.0,
    },
}
NMHUB._hook.resolveHookPoint = function(hook)
    if not hook then return nil end
    if hook:IsA("BasePart") and CollectionService:HasTag(hook, "HookPoint") then
        return hook
    end
    for _, d in ipairs(hook:GetDescendants()) do
        if d:IsA("BasePart") and CollectionService:HasTag(d, "HookPoint") then
            return d
        end
    end
    return hook
end
NMHUB._hook.resolvePartAndPos = function(hook)
    if not hook or not hook.Parent then return nil, nil end
    local hookPart = hook
    if hook:IsA("Model") then
        hookPart = hook.PrimaryPart
            or hook:FindFirstChild("Hook")
            or hook:FindFirstChild("Main")
            or hook:FindFirstChildWhichIsA("BasePart")
            or hook
    end
    local hookPos = hookPart and hookPart:IsA("BasePart") and hookPart.Position or nil
    return hookPart, hookPos
end
NMHUB._hook.teleportTo = function(hrp, hook)
    local hookPart, hookPos = NMHUB._hook.resolvePartAndPos(hook)
    if not hookPos or not hrp then return false end
    local hookCF = hookPart:IsA("BasePart") and hookPart.CFrame or CFrame.new(hookPos)
    local standPos = hookPos + (hookCF.LookVector * -2.5) + Vector3.new(0, 0.5, 0)
    return performSafeTeleport(CFrame.new(standPos, hookPos))
end
NMHUB._hook.findDowned = function()
    local char = getChar()
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, 200
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == LP then continue end
        if not (pl.Team and pl.Team.Name == "Survivors") then continue end
        local tChar = pl.Character
        if not tChar then continue end
        local tHum = tChar:FindFirstChildOfClass("Humanoid")
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHum or not tHRP then continue end
        local isDowned = CollectionService:HasTag(tChar, "Knocked")
            or (tHum.Health > 0 and tHum.Health <= 1)
            or tChar:GetAttribute("DownedMarker") == true
            or tChar:GetAttribute("IsDowned") == true
        local onHook    = CollectionService:HasTag(tChar, "Hooked")
            or tChar:GetAttribute("IsHooked") == true
        local isCarried = tChar:GetAttribute("IsCarried") or pl:GetAttribute("IsCarried")
        if not isDowned or onHook or isCarried then continue end
        local dist = (tHRP.Position - hrp.Position).Magnitude
        if dist < bestDist then bestDist = dist; best = pl end
    end
    return best
end
NMHUB._hook.findEmptyHook = function()
    local char = getChar()
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(CollectionService:GetTagged("HookPoint")) do
        if not obj:IsDescendantOf(workspace) then continue end
        if obj:GetAttribute("IsOccupied") == true then continue end
        if CollectionService:HasTag(obj, "Occupied") then continue end
        local hookPos = obj:IsA("BasePart") and obj.Position
            or (obj:IsA("Model") and obj:GetPivot().Position)
        if not hookPos then continue end
        local occupied = false
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl == LP then continue end
            local tChar = pl.Character
            if tChar and CollectionService:HasTag(tChar, "Hooked") then
                local tHRP = tChar:FindFirstChild("HumanoidRootPart")
                if tHRP and (tHRP.Position - hookPos).Magnitude < 5 then
                    occupied = true; break
                end
            end
        end
        if occupied then continue end
        local dist = (hrp.Position - hookPos).Magnitude
        if dist < bestDist then bestDist = dist; best = obj end
    end
    return best
end
NMHUB._hook.setState = function(state)
    _hookState = state
    NMHUB._hook.stateTime = tick()
    if state == "hooking" then
        NMHUB._hook.step           = 0
        NMHUB._hook.stepTime       = tick()
        NMHUB._hook.retries        = 0
    elseif state == "pickup" then
        NMHUB._hook.pickupRetryTime = tick()
        NMHUB._hook.pickupRetries   = 0
    end
end
NMHUB._hook.reset = function()
    NMHUB._hook.lockedHook      = nil
    NMHUB._hook.lockedSurv      = nil
    NMHUB._hook.step            = 0
    NMHUB._hook.stepTime        = 0
    NMHUB._hook.stateTime       = tick()
    NMHUB._hook.retries         = 0
    NMHUB._hook.pickupRetryTime = 0
    NMHUB._hook.pickupRetries   = 0
    _hookState      = "idle"
    _lastHookAction = tick()
end

stepAutoHook = function()
    if not NMHUB.Flags.Killer_AutoHook or not isKiller() then return end
    if (tick() - _lastHookAction) < NMHUB._hook.delays.Tick then return end
    if not ensureRemotes() then return end

    local now  = tick()
    local char = getChar()
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local carry = RemCarry
    if not carry then return end
    local D = NMHUB._hook.delays
    local H = NMHUB._hook
    _lastHookAction = now

    local stateElapsed = now - H.stateTime

    if _hookState == "idle" then
        if isKillerCarrying() then
            local hook = H.findEmptyHook()
            if hook then
                H.lockedHook = hook
                H.teleportTo(hrp, hook)
                H.setState("travel")
            end
            return
        end
        local target = H.findDowned()
        if not target then return end
        H.lockedSurv = target
        local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if tHRP then
            performSafeTeleport(CFrame.new(tHRP.Position + Vector3.new(0, 0.5, 2), tHRP.Position))
        end
        local cse = carry:FindFirstChild("CarrySurvivorEvent")
        if cse and target.Character then
            pcall(function() cse:FireServer(target.Character) end)
            task.delay(0.08, function()
                if target.Character then
                    pcall(function() cse:FireServer(target.Character) end)
                end
            end)
        end
        H.setState("pickup")

    elseif _hookState == "pickup" then
        if isKillerCarrying() then
            if stateElapsed < D.Pickup then return end
            local hook = H.findEmptyHook()
            if not hook then return end
            H.lockedHook = hook
            H.teleportTo(hrp, hook)
            H.setState("travel")
        else
            if H.lockedSurv and H.lockedSurv.Character then
                local retryHum = H.lockedSurv.Character:FindFirstChildOfClass("Humanoid")
                local retryHRP = H.lockedSurv.Character:FindFirstChild("HumanoidRootPart")
                local stillDowned = retryHum and retryHRP
                    and (CollectionService:HasTag(H.lockedSurv.Character, "Knocked")
                        or (retryHum.Health > 0 and retryHum.Health <= 1)
                        or H.lockedSurv.Character:GetAttribute("IsDowned") == true)
                if stillDowned
                    and (now - H.pickupRetryTime) >= D.PickupRetry
                    and H.pickupRetries < 6 then
                    if retryHRP then
                        performSafeTeleport(CFrame.new(retryHRP.Position + Vector3.new(0, 0.5, 2), retryHRP.Position))
                    end
                    local cse = carry:FindFirstChild("CarrySurvivorEvent")
                    if cse and H.lockedSurv.Character then
                        pcall(function() cse:FireServer(H.lockedSurv.Character) end)
                    end
                    H.pickupRetryTime = now
                    H.pickupRetries   = H.pickupRetries + 1
                end
            end
            if stateElapsed >= 6 then H.reset() end
        end

    elseif _hookState == "travel" then
        if not isKillerCarrying() then
            H.setState("cooldown")
            return
        end
        if stateElapsed < D.Travel then return end
        if H.lockedHook and H.lockedHook.Parent then
            H.teleportTo(hrp, H.lockedHook)
        end
        H.setState("hooking")

    elseif _hookState == "hooking" then
        if not isKillerCarrying() then
            H.lockedHook = nil
            H.lockedSurv = nil
            H.setState("cooldown")
            return
        end
        if not H.lockedHook or not H.lockedHook.Parent then
            H.reset()
            return
        end
        local hookPoint   = H.resolveHookPoint(H.lockedHook)
        local stepElapsed = now - H.stepTime
        local he = carry:FindFirstChild("HookEvent")
        local hc = carry:FindFirstChild("HookCommit")

        if H.step == 0 then
            H.step = 1; H.stepTime = now
        elseif H.step == 1 and stepElapsed >= D.Phase then
            if he then pcall(function() he:FireServer(hookPoint) end) end
            H.step = 2; H.stepTime = now
        elseif H.step == 2 and stepElapsed >= D.Event then
            if hc then pcall(function() hc:FireServer(hookPoint) end) end
            H.step = 3; H.stepTime = now
        elseif H.step == 3 and stepElapsed >= D.Commit then
            if isKillerCarrying() then
                if he then pcall(function() he:FireServer(hookPoint) end) end
                if hc then pcall(function() hc:FireServer(hookPoint) end) end
                H.retries = H.retries + 1
                if H.retries >= 3 then
                    H.teleportTo(hrp, H.lockedHook)
                    H.setState("travel")
                else
                    H.step = 0; H.stepTime = now
                end
            else
                H.lockedHook = nil
                H.lockedSurv = nil
                H.setState("cooldown")
            end
        end

    elseif _hookState == "cooldown" then
        if stateElapsed >= D.Cooldown then
            H.reset()
        end
    end
end

local _stunWatchConn     = nil
local _stunWatchCharConn = nil

stopNoPalletStunWatchdog = function()
    if _stunWatchConn then
        pcall(function() _stunWatchConn:Disconnect() end)
        _stunWatchConn = nil
        NMHUB.Connections.StunWatchdog = nil
    end
    if _stunWatchCharConn then
        pcall(function() _stunWatchCharConn:Disconnect() end)
        _stunWatchCharConn = nil
        NMHUB.Connections.StunWatchCharacter = nil
    end
end

local function startNoPalletStunWatchdog()
    if _stunWatchConn then return end
    local char = getChar(); if not char then return end
    _stunWatchConn = char:GetAttributeChangedSignal("IsStunned"):Connect(function()
        if not NMHUB.Flags.Killer_NoPalletStun then return end
        if char:GetAttribute("IsStunned") ~= true then return end
        local jason = RemPallet and RemPallet:FindFirstChild("Jason")
        local so = jason and jason:FindFirstChild("Stunover")
        if so then pcall(function() so:FireServer() end) end
        pcall(function() char:SetAttribute("IsStunned", false) end)
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            local base = (char:GetAttribute("Speed") or 16)
                * (char:GetAttribute("speedboost") or 1)
            hum.WalkSpeed = base
        end
    end)
    NMHUB.Connections.StunWatchdog = _stunWatchConn
    if not _stunWatchCharConn then
        _stunWatchCharConn = LP.CharacterAdded:Connect(function()
            if not NMHUB.Flags.Killer_NoPalletStun then return end
            if _stunWatchConn then
                pcall(function() _stunWatchConn:Disconnect() end)
                _stunWatchConn = nil
                NMHUB.Connections.StunWatchdog = nil
            end
            task.wait(0.1)
            startNoPalletStunWatchdog()
        end)
        NMHUB.Connections.StunWatchCharacter = _stunWatchCharConn
    end
end

stepNoPalletStun = function()
    if not NMHUB.Flags.Killer_NoPalletStun or not isKiller() then
        stopNoPalletStunWatchdog()
        return
    end
    if not _stunWatchConn then
        ensureRemotes()
        startNoPalletStunWatchdog()
    end
end

stepAntiBlind = function()
    if not NMHUB.Flags.Killer_AntiBlind or not isKiller() then return end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    local darkness = pg:FindFirstChild("Darkness")
    if darkness and darkness.Enabled then
        darkness.Enabled = false
    end
end

stepNoSlowdown = function()
    if not NMHUB.Flags.Killer_NoSlowdown or not isKiller() then return end
    if isKillerCarrying() then return end
    local char = getChar(); if not char then return end
    local hum = char:FindFirstChild("Humanoid"); if not hum then return end
    if char:GetAttribute("IsStunned") or char:GetAttribute("Immobile") then return end
    local base = (char:GetAttribute("Speed") or LP:GetAttribute("Speed") or 16)
        * (char:GetAttribute("speedboost") or LP:GetAttribute("speedboost") or 1)
    if hum.WalkSpeed < base then hum.WalkSpeed = base end
end

local _originalHitboxSizes = {}

applyHitboxExpand = function()
    if not ensureRemotes() then return end
    local size = NMHUB.Flags.Killer_HitboxSize or 15
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and pl.Team and pl.Team.Name == "Survivors" then
            local tc = pl.Character
            if tc then
                local hrp = tc:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not _originalHitboxSizes[hrp] then
                        _originalHitboxSizes[hrp] = hrp.Size
                    end
                    hrp.Size = Vector3.new(size, size, size)
                end
            end
        end
    end
end

removeHitboxExpand = function()
    for part, origSize in pairs(_originalHitboxSizes) do
        pcall(function()
            if part and part.Parent then part.Size = origSize end
        end)
    end
    table.clear(_originalHitboxSizes)
end

local _lastBurst = 0
NMHUB:Disconnect("KillerBurstInput")
NMHUB.Connections.KillerBurstInput = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not NMHUB.Flags.Killer_BurstAttack or not isKiller() then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if (tick() - _lastBurst) < 0.5 then return end
    if isKillerBusy() then return end
    if not ensureRemotes() then return end
    local ba = RemAttacks and RemAttacks:FindFirstChild("BasicAttack")
    if ba then
        pcall(function() ba:FireServer() end)
        task.delay(0.1, function()
            if not _G.NOMERCY_Shutdown then
                pcall(function() ba:FireServer() end)
            end
        end)
        _lastBurst = tick()
    end
end)

stopKillerDispatcher = function()
    if _killerDispConn then
        pcall(function() _killerDispConn:Disconnect() end)
        _killerDispConn = nil
    end
end

startKillerDispatcher = function()
    if _killerDispConn then return end
    _killerDispFrame = 0
    _killerDispConn = RunService.Heartbeat:Connect(function()
        if _G.NOMERCY_Shutdown then
            stopKillerDispatcher()
            return
        end
        if not anyKillerFeatureOn() then
            stopKillerDispatcher()
            return
        end
        _killerDispFrame = _killerDispFrame + 1

        if _killerDispFrame % 3 == 0 then
            pcall(stepAutoAttack)
            pcall(stepInfiniteLunge)
            pcall(stepInstantKill)
            pcall(stepNoSlowdown)
        end
        if _killerDispFrame % 6 == 0 then
            pcall(stepNoPalletStun)
            pcall(stepAntiBlind)
        end
        if _killerDispFrame % 3 == 0 then
            pcall(stepAutoHook)
        end
        if _killerDispFrame % 30 == 0 then
            pcall(stepDestroyPallets)
            pcall(stepFullGenBreak)
            if NMHUB.Flags.Killer_HitboxExpand then
                pcall(applyHitboxExpand)
            end
        end
    end)
end

-- ===== SURVIVOR STEP FUNCTIONS =====
local function ensureSurvRemotes()
    return ensureRemotes()
end

local function _setupPersistentHooks()
    if not hookfunction then return end
    ensureRemotes()
    ensureSurvRemotes()

    pcall(function()
        local mech = Remotes and Remotes:FindFirstChild("Mechanics")
        local fallRem = mech and mech:FindFirstChild("Fall")
        if fallRem and fallRem:IsA("RemoteEvent") then
            local oldFS
            oldFS = hookfunction(fallRem.FireServer, newcclosure(function(self, ...)
                if not checkcaller() and NMHUB.Flags.Surv_NoFallDmg then
                    return nil
                end
                return oldFS(self, ...)
            end))
            table.insert(NMHUB.HookedRemotes, { remote = fallRem, old = oldFS })
        end
    end)

    pcall(function()
        local jason = RemPallet and RemPallet:FindFirstChild("Jason")
        if not jason then return end
        for _, rname in ipairs({ "Stun", "StunDrop" }) do
            local rem = jason:FindFirstChild(rname)
            if rem and rem:IsA("RemoteEvent") then
                local oldFS
                oldFS = hookfunction(rem.FireServer, newcclosure(function(self, ...)
                    if not checkcaller() and NMHUB.Flags.Killer_NoPalletStun then
                        return nil
                    end
                    return oldFS(self, ...)
                end))
                table.insert(NMHUB.HookedRemotes, { remote = rem, old = oldFS })
            end
        end
    end)

    pcall(function()
        local items = Remotes and Remotes:FindFirstChild("Items")
        local fl    = items and items:FindFirstChild("Flashlight")
        local gb    = fl and fl:FindFirstChild("GotBlinded")
        if gb and gb:IsA("RemoteEvent") then
            local oldFS
            oldFS = hookfunction(gb.FireServer, newcclosure(function(self, ...)
                if not checkcaller() and NMHUB.Flags.Killer_AntiBlind and isKiller() then
                    return nil
                end
                return oldFS(self, ...)
            end))
            table.insert(NMHUB.HookedRemotes, { remote = gb, old = oldFS })
        end
    end)
end

local function _setupNoSlowdownHook()
    pcall(function()
        local ok, mt = pcall(function() return getrawmetatable(game) end)
        if not (ok and mt and setreadonly) then return end
        setreadonly(mt, false)
        local oldNI = mt.__newindex
        mt.__newindex = newcclosure(function(t, k, v)
            if not checkcaller()
            and NMHUB.Flags.Killer_NoSlowdown
            and isKiller() then
                if k == "WalkSpeed" and type(v) == "number" and v < 16
                and typeof(t) == "Instance" and t:IsA("Humanoid") then
                    local ch = getChar()
                    local base = (ch and ch:GetAttribute("Speed") or 16)
                        * (ch and ch:GetAttribute("speedboost") or 1)
                    return oldNI(t, k, math.max(v, base))
                end
                if k == "Anchored" and v == true
                and typeof(t) == "Instance" and t:IsA("BasePart")
                and t.Name == "HumanoidRootPart" then
                    return oldNI(t, k, false)
                end
            end
            return oldNI(t, k, v)
        end)
        setreadonly(mt, true)
    end)
end

task.spawn(function()
    task.wait(3)
    if _G.NOMERCY_Shutdown then return end
    pcall(_setupPersistentHooks)
    pcall(_setupNoSlowdownHook)
end)

local function findKillerCharacter()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Team and pl.Team.Name == "Killer" then
            return pl.Character
        end
    end
end

local function isBeingCarried()
    local char = getChar(); if not char then return false end
    return char:GetAttribute("IsCarried") == true
end

local function isHooked()
    local char = getChar(); if not char then return false end
    return char:GetAttribute("IsHooked") == true
        or CollectionService:HasTag(char, "Hooked")
end

local function findNearestGen()
    local char = getChar(); if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local best, bestDist = nil, 999
    for _, gp in ipairs(CollectionService:GetTagged("GeneratorPoint")) do
        local pos = gp:IsA("BasePart") and gp.Position
            or (gp:IsA("Model") and gp:GetPivot().Position)
        if pos then
            local d = (hrp.Position - pos).Magnitude
            if d < bestDist then bestDist = d; best = { part = gp, dist = d } end
        end
    end
    return best
end

local function findFarthestGen()
    local char = getChar(); if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local best, bestDist = nil, 0
    for _, gp in ipairs(CollectionService:GetTagged("GeneratorPoint")) do
        local pos = gp:IsA("BasePart") and gp.Position
            or (gp:IsA("Model") and gp:GetPivot().Position)
        if pos then
            local d = (hrp.Position - pos).Magnitude
            if d > bestDist then bestDist = d; best = gp end
        end
    end
    return best
end

local function findNearestWindow()
    local char = getChar(); if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local best, bestDist = nil, 12
    for _, win in ipairs(CollectionService:GetTagged("VaultPoint")) do
        local pos = win:IsA("BasePart") and win.Position
            or (win:IsA("Model") and win.PrimaryPart and win.PrimaryPart.Position)
            or (win:IsA("Model") and win:GetPivot().Position)
        if pos then
            local d = (hrp.Position - pos).Magnitude
            if d < bestDist then bestDist = d; best = win end
        end
    end
    return best
end

local _scHookConn    = nil
local _scActiveGen   = nil
local _scActivePoint = nil

local function _setupSkillCheckHook()
    if _scHookConn then return end
    task.spawn(function()
        if not ensureSurvRemotes() then return end
        local scEvent = RemGen and RemGen:WaitForChild("SkillCheckEvent", 5)
        if not scEvent then return end
        if _scHookConn then return end
        _scHookConn = scEvent.OnClientEvent:Connect(function(gen, point)
            _scActiveGen   = gen
            _scActivePoint = point
            local isAuto = NMHUB.Flags.Surv_AutoSkillCheck
            local isFast = NMHUB.Flags.Surv_FastRepair
            local isInst = NMHUB.Flags.Surv_InstantGen
            if not (isAuto or isFast or isInst) then return end
            if not isSurvivor() then return end
            local scResult = RemGen:FindFirstChild("SkillCheckResultEvent")
            if not scResult then return end
            if isInst then
                task.spawn(function()
                    for i = 1, 200 do
                        if _G.NOMERCY_Shutdown or not NMHUB.Flags.Surv_InstantGen then break end
                        if _scActiveGen ~= gen then break end
                        pcall(function() scResult:FireServer("success", 1, gen, point) end)
                        if i % 10 == 0 then task.wait(0) end
                    end
                    _scActiveGen = nil; _scActivePoint = nil
                end)
            else
                task.delay(0.15, function()
                    if _G.NOMERCY_Shutdown then return end
                    if not (NMHUB.Flags.Surv_AutoSkillCheck or NMHUB.Flags.Surv_FastRepair) then return end
                    if _scActiveGen ~= gen then return end
                    pcall(function() scResult:FireServer("success", 1, gen, point) end)
                    pcall(function()
                        local pg = LP:FindFirstChild("PlayerGui")
                        local prompt = pg and pg:FindFirstChild("SkillCheckPromptGui")
                        if prompt and prompt:FindFirstChild("Check") then
                            prompt.Check.Visible = false
                        end
                    end)
                    _scActiveGen = nil; _scActivePoint = nil
                end)
            end
        end)
        NMHUB.Connections.SC_HookConn = _scHookConn
    end)
end

local function _teardownSkillCheckHook()
    if NMHUB.Flags.Surv_AutoSkillCheck
    or NMHUB.Flags.Surv_FastRepair
    or NMHUB.Flags.Surv_InstantGen then return end
    if _scHookConn then
        pcall(function() _scHookConn:Disconnect() end)
        _scHookConn = nil
        NMHUB.Connections.SC_HookConn = nil
    end
    _scActiveGen = nil; _scActivePoint = nil
end

local _apHeartbeat   = nil
local _apCharConn    = nil
local _apCheckGui    = nil
local _apArmed       = true
local _apVIM         = game:GetService("VirtualInputManager")

local function AP_pressSpace()
    pcall(function()
        _apVIM:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
        task.wait(0.01)
        _apVIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

local function AP_lineInGoal(Line, Goal)
    local lr = Line.Rotation % 360
    local gr = Goal.Rotation % 360
    local gs = (gr + 104) % 360
    local ge = (gr + 114) % 360
    if gs > ge then return lr >= gs or lr <= ge end
    return lr >= gs and lr <= ge
end

local function AP_resolveCheck()
    local gui = _apCheckGui
    if not (gui and gui.Parent) then
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end
        gui = pg:FindFirstChild("SkillCheckPromptGui")
        _apCheckGui = gui
    end
    if not gui then return nil end
    return gui:FindFirstChild("Check")
end

local _autoCancelConn  = nil
local _genCancelActive = false

local function forceLeaveGenerator()
    if _genCancelActive then return end
    _genCancelActive = true
    
    task.spawn(function()
        local re = RemGen and RemGen:FindFirstChild("RepairEvent")
        if re then
            local g = findNearestGen()
            if g and g.part then
                pcall(function() re:FireServer(g.part, false) end)
            end
        end
        local char = getChar()
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
            pcall(function() hum:Move(Vector3.new(0, 0, -1), true) end)
            task.delay(0.2, function() pcall(function() hum:Move(Vector3.new(0,0,0), true) end) end)
        end
    end)
    
    task.delay(1.5, function() _genCancelActive = false end)
end

local function startAutoCancelMonitor()
    if _autoCancelConn then return end
    _autoCancelConn = UserInputService.InputChanged:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Thumbstick1 and input.Position.Magnitude > 0.1 then
            local g = findNearestGen()
            if g and g.dist <= 12 then forceLeaveGenerator() end
        end
    end)
    local _autoCancelConn2 = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local movKeys = {
            Enum.KeyCode.W, Enum.KeyCode.A,
            Enum.KeyCode.S, Enum.KeyCode.D,
            Enum.KeyCode.Space, Enum.KeyCode.Thumbstick1
        }
        for _, k in ipairs(movKeys) do
            if input.KeyCode == k then
                local g = findNearestGen()
                if g and g.dist <= 12 then
                    forceLeaveGenerator()
                end
                break
            end
        end
    end)
    NMHUB.Connections.AutoCancelGen = {
        Disconnect = function()
            pcall(function() _autoCancelConn:Disconnect() end)
            pcall(function() _autoCancelConn2:Disconnect() end)
        end
    }
end

local function stopAutoCancelMonitor()
    if NMHUB.Flags.Surv_AutoSkillCheck or NMHUB.Flags.Surv_FastRepair then return end
    if _autoCancelConn then
        pcall(function() _autoCancelConn:Disconnect() end)
        _autoCancelConn = nil
        NMHUB.Connections.AutoCancelGen = nil
    end
end

startAutoSkillCheck = function()
    if _apHeartbeat then return end
    _apArmed    = true
    _apCheckGui = nil
    if _apCharConn then _apCharConn:Disconnect() end
    _apCharConn = LP.CharacterAdded:Connect(function()
        _apCheckGui = nil
        _apArmed    = true
    end)
    NMHUB.Connections.AP_CharConn = _apCharConn
    _apHeartbeat = RunService.Heartbeat:Connect(function()
        if not NMHUB.Flags.Surv_AutoSkillCheck or not isSurvivor() then return end
        local Check = AP_resolveCheck()
        if not Check or not Check.Visible then
            _apArmed = true
            return
        end
        local Line = Check:FindFirstChild("Line")
        local Goal = Check:FindFirstChild("Goal")
        if not (Line and Goal) then return end
        if AP_lineInGoal(Line, Goal) then
            if _apArmed then
                AP_pressSpace()
                _apArmed = false
            end
        else
            _apArmed = true
        end
    end)
    NMHUB.Connections.AP_Heartbeat = _apHeartbeat
end

stopAutoSkillCheck = function()
    if _apHeartbeat then
        pcall(function() _apHeartbeat:Disconnect() end)
        _apHeartbeat = nil
        NMHUB.Connections.AP_Heartbeat = nil
    end
    if _apCharConn then
        pcall(function() _apCharConn:Disconnect() end)
        _apCharConn = nil
        NMHUB.Connections.AP_CharConn = nil
    end
    _apCheckGui = nil
    stopAutoCancelMonitor()
end

local _fastRepairConn = nil
local _lastFastRepair = 0

startFastRepair = function()
    if _fastRepairConn then return end
    _setupSkillCheckHook()
    _fastRepairConn = RunService.Heartbeat:Connect(function()
        if not NMHUB.Flags.Surv_FastRepair or not isSurvivor() then return end
        if _genCancelActive then return end
        if (tick() - _lastFastRepair) < 0.12 then return end
        if not ensureSurvRemotes() then return end
        local g = findNearestGen()
        if not g or g.dist > 12 then return end
        local re = RemGen:FindFirstChild("RepairEvent")
        if re then pcall(function() re:FireServer() end) end
        _lastFastRepair = tick()
    end)
    NMHUB.Connections.FastRepair = _fastRepairConn
    startAutoCancelMonitor()
end

stopFastRepair = function()
    if _fastRepairConn then
        pcall(function() _fastRepairConn:Disconnect() end)
        _fastRepairConn = nil
        NMHUB.Connections.FastRepair = nil
    end
    _teardownSkillCheckHook()
    stopAutoCancelMonitor()
end

local _instantGenConn = nil
local _lastInstantGen = 0

startInstantGen = function()
    if _instantGenConn then return end
    _setupSkillCheckHook()
    _instantGenConn = RunService.Heartbeat:Connect(function()
        if not NMHUB.Flags.Surv_InstantGen or not isSurvivor() then return end
        if (tick() - _lastInstantGen) < 0.5 then return end
        if not ensureSurvRemotes() then return end
        local g = findNearestGen()
        if not g or g.dist > 12 then return end
        local re = RemGen:FindFirstChild("RepairEvent")
        if re then pcall(function() re:FireServer() end) end
        _lastInstantGen = tick()
    end)
    NMHUB.Connections.InstantGen = _instantGenConn
end

stopInstantGen = function()
    if _instantGenConn then
        pcall(function() _instantGenConn:Disconnect() end)
        _instantGenConn = nil
        NMHUB.Connections.InstantGen = nil
    end
    _teardownSkillCheckHook()
end

-- ==========================================
-- AUTO PARRY SYSTEM (PERBAIKAN TOTAL)
-- ==========================================
local _parryAnimWatchers = {}
local _parryCooldown = false

local function ExecuteParry_KV()
    if _parryCooldown or not isSurvivor() then return end
    _parryCooldown = true

    task.spawn(function()
        local char = getChar()
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local dagger = char:FindFirstChild("Parrying Dagger") or LP.Backpack:FindFirstChild("Parrying Dagger")
        
        -- 1. INSTANT EQUIP & ACTIVATE
        if dagger then
            if dagger.Parent == LP.Backpack and hum then 
                hum:EquipTool(dagger) 
                task.wait(0.02)
            end
            pcall(function() dagger:Activate() end)
        end

        -- 2. INSTANT FIRE REMOTE
        if ensureRemotes() and RemItems then
            local parryRemote = RemItems:FindFirstChild("Parrying Dagger")
            parryRemote = parryRemote and parryRemote:FindFirstChild("parry")
            if parryRemote then
                pcall(function() parryRemote:FireServer() end)
            end
        end

        -- 3. DETEKSI PLATFORM UNTUK VIRTUAL INPUT
        if isMobile then
            local VIM = game:GetService("VirtualInputManager")
            local clickedUI = false
            pcall(function()
                local pg = LP:FindFirstChild("PlayerGui")
                for _, gui in ipairs(pg:GetDescendants()) do
                    if (gui:IsA("ImageButton") or gui:IsA("TextButton")) and gui.Visible and gui.AbsolutePosition.X > 0 then
                        local n = gui.Name:lower()
                        if n:find("attack") or n:find("parry") or n:find("sword") or n:find("combat") or n:find("action") or n:find("contextaction") then
                            local cx = gui.AbsolutePosition.X + (gui.AbsoluteSize.X / 2)
                            local cy = gui.AbsolutePosition.Y + (gui.AbsoluteSize.Y / 2)
                            task.spawn(function()
                                pcall(function()
                                    VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                                    task.wait(0.02)
                                    VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                                end)
                            end)
                            clickedUI = true
                        end
                    end
                end
            end)

            if not clickedUI then
                local cam = workspace.CurrentCamera
                if cam then
                    local cx, cy = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2
                    task.spawn(function()
                        pcall(function()
                            VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                            task.wait(0.02)
                            VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                        end)
                    end)
                end
            end
        else
            if mouse2click then
                pcall(function() mouse2click() end)
            else
                task.spawn(function()
                    local VU = game:GetService("VirtualUser")
                    pcall(function()
                        VU:Button2Down(Vector2.new(0,0))
                        task.wait(0.02)
                        VU:Button2Up(Vector2.new(0,0))
                    end)
                end)
            end
        end
    end)

    print("[King Vypers] 🛡️ Auto Parry Berhasil Dijalankan!")
    task.delay(0.4, function() _parryCooldown = false end)
end

local function WatchKillerAnimations(char, plr)
    if _parryAnimWatchers[char] then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local anim = hum and hum:FindFirstChild("Animator")
    if not anim or not anim.AnimationPlayed then return end

    local conn = anim.AnimationPlayed:Connect(function(track)
        if not NMHUB.Flags.Surv_AutoParry or not isSurvivor() then return end
        
        local animObj = track.Animation
        local animId = (animObj and animObj.AnimationId) and tostring(animObj.AnimationId):lower() or ""
        local prio = track.Priority
        local isAttack = false

        if prio == Enum.AnimationPriority.Action or prio == Enum.AnimationPriority.Action2 or prio == Enum.AnimationPriority.Action3 or prio == Enum.AnimationPriority.Action4 then
            isAttack = true
        elseif animId:find("attack") or animId:find("swing") or animId:find("slash") or animId:find("hit") or animId:find("stab") or animId:find("punch") or animId:find("strike") then
            isAttack = true
        end

        if isAttack then
            local myChar = getChar()
            if not myChar then return end
            local hrp = myChar:FindFirstChild("HumanoidRootPart")
            local khrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp or not khrp then return end

            if (hrp.Position - khrp.Position).Magnitude <= (NMHUB.Flags.Surv_ParryRange or 20) then
                ExecuteParry_KV()
            end
        end
    end)
    
    _parryAnimWatchers[char] = conn
    
    char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if _parryAnimWatchers[char] then
                pcall(function() _parryAnimWatchers[char]:Disconnect() end)
                _parryAnimWatchers[char] = nil
            end
        end
    end)
end

local function SetupKillerWatcher(plr)
    if plr == LP then return end
    local function checkAndWatch(c)
        task.wait(0.5)
        if plr.Team and plr.Team.Name:lower():find("killer") then 
            WatchKillerAnimations(c, plr) 
        end
    end
    
    if plr.CharacterAdded then
        plr.CharacterAdded:Connect(checkAndWatch)
    end
    if plr.Character then
        task.spawn(function() checkAndWatch(plr.Character) end)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    SetupKillerWatcher(p)
end
Players.PlayerAdded:Connect(SetupKillerWatcher)

startAutoParry = function()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Team and pl.Team.Name:lower():find("killer") and pl.Character then
            WatchKillerAnimations(pl.Character, pl)
        end
    end
end

stopAutoParry = function()
    -- Tidak perlu disconnect watcher karena flag `NMHUB.Flags.Surv_AutoParry`
    -- sudah menangani penonaktifan eksekusi di dalam `WatchKillerAnimations`.
end

local _autoWiggleConn = nil
local _lastWiggle     = 0

startAutoWiggle = function()
    if _autoWiggleConn then return end
    _autoWiggleConn = RunService.Heartbeat:Connect(function()
        if not NMHUB.Flags.Surv_AutoWiggle or not isSurvivor() then return end
        if not isBeingCarried() then return end
        if (tick() - _lastWiggle) < 0.15 then return end
        if not ensureRemotes() then return end
        local selfUnhook = RemCarry and RemCarry:FindFirstChild("SelfUnHookEvent")
        if selfUnhook then
            pcall(function() selfUnhook:FireServer() end)
        else
            local vim = game:GetService("VirtualInputManager")
            for _, key in ipairs({ Enum.KeyCode.A, Enum.KeyCode.D }) do
                task.spawn(function()
                    pcall(function()
                        vim:SendKeyEvent(true,  key, false, game)
                        task.wait(0.08)
                        vim:SendKeyEvent(false, key, false, game)
                    end)
                end)
            end
        end
        _lastWiggle = tick()
    end)
    NMHUB.Connections.AutoWiggle = _autoWiggleConn
end

stopAutoWiggle = function()
    if _autoWiggleConn then
        pcall(function() _autoWiggleConn:Disconnect() end)
        _autoWiggleConn = nil
        NMHUB.Connections.AutoWiggle = nil
    end
end

local _instantHealConn    = nil
local _lastInstantHeal    = 0
local _healScHookConn     = nil

local function _setupHealSkillCheckHook()
    if _healScHookConn then return end
    task.spawn(function()
        if not ensureSurvRemotes() then return end
        local healScEvent = RemHeal and RemHeal:WaitForChild("SkillCheckEvent", 5)
        if not healScEvent then return end
        if _healScHookConn then return end
        _healScHookConn = healScEvent.OnClientEvent:Connect(function(healTarget, healPoint)
            if _G.NOMERCY_Shutdown then return end
            if not NMHUB.Flags.Surv_InstantHeal then return end
            if not isSurvivor() then return end
            local healScResult = RemHeal:FindFirstChild("SkillCheckResultEvent")
            if not healScResult then return end
            task.delay(0.1, function()
                if _G.NOMERCY_Shutdown or not NMHUB.Flags.Surv_InstantHeal then return end
                pcall(function() healScResult:FireServer("success", 1, healTarget, healPoint) end)
            end)
        end)
        NMHUB.Connections.Heal_SC_HookConn = _healScHookConn
    end)
end

local function _teardownHealSkillCheckHook()
    if _healScHookConn then
        pcall(function() _healScHookConn:Disconnect() end)
        _healScHookConn = nil
        NMHUB.Connections.Heal_SC_HookConn = nil
    end
end

startInstantHeal = function()
    if _instantHealConn then return end
    _setupHealSkillCheckHook()
    _instantHealConn = RunService.Heartbeat:Connect(function()
        if not NMHUB.Flags.Surv_InstantHeal or not isSurvivor() then return end
        if (tick() - _lastInstantHeal) < 1.5 then return end
        if not ensureSurvRemotes() then return end
        local char = getChar(); if not char then return end
        local hum = char:FindFirstChild("Humanoid"); if not hum then return end
        if hum.Health >= hum.MaxHealth then return end
        if isBeingCarried() or isHooked() then return end
        local he = RemHeal and RemHeal:FindFirstChild("HealEvent")
        if he then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() he:FireServer(hrp, true) end)
                _lastInstantHeal = tick()
            end
        end
    end)
    NMHUB.Connections.InstantHeal = _instantHealConn
end

stopInstantHeal = function()
    if _instantHealConn then
        pcall(function() _instantHealConn:Disconnect() end)
        _instantHealConn = nil
        NMHUB.Connections.InstantHeal = nil
    end
    _teardownHealSkillCheckHook()
end

local _noFallConn     = nil
local _noFallCharConn = nil

startNoFallDmg = function()
    if _noFallConn then return end
    local char = getChar()
    if not char then return end
    local hum = char:FindFirstChild("Humanoid"); if not hum then return end
    local maxHp = hum.MaxHealth
    _noFallConn = hum.StateChanged:Connect(function(_, new)
        if not NMHUB.Flags.Surv_NoFallDmg then return end
        if new == Enum.HumanoidStateType.Landed then
            task.delay(0.05, function()
                if hum and hum.Parent then
                    hum.Health = math.max(hum.Health, maxHp * 0.5)
                end
            end)
        end
    end)
    NMHUB.Connections.NoFallDmg = _noFallConn
    if not _noFallCharConn then
        _noFallCharConn = LP.CharacterAdded:Connect(function()
            if not NMHUB.Flags.Surv_NoFallDmg then return end
            if _noFallConn then
                pcall(function() _noFallConn:Disconnect() end)
                _noFallConn = nil
                NMHUB.Connections.NoFallDmg = nil
            end
            task.wait(0.1)
            startNoFallDmg()
        end)
    end
end

stopNoFallDmg = function()
    if _noFallConn then
        pcall(function() _noFallConn:Disconnect() end)
        _noFallConn = nil
        NMHUB.Connections.NoFallDmg = nil
    end
    if _noFallCharConn then
        pcall(function() _noFallCharConn:Disconnect() end)
        _noFallCharConn = nil
    end
end

local function stepSurvNoSlowdown()
    if not NMHUB.Flags.Surv_NoSlowdown or not isSurvivor() then return end
    if isBeingCarried() or isHooked() then return end
    local char = getChar(); if not char then return end
    local hum = char:FindFirstChild("Humanoid"); if not hum then return end
    if hum.WalkSpeed > 0 and hum.WalkSpeed < 16 then
        hum.WalkSpeed = 16
    end
end

local _fastVaultConn = nil
local _lastFastVault = 0

startFastVault = function()
    if _fastVaultConn then return end
    _fastVaultConn = RunService.Heartbeat:Connect(function()
        if not NMHUB.Flags.Surv_FastVault or not isSurvivor() then return end
        if (tick() - _lastFastVault) < 0.3 then return end
        if not ensureSurvRemotes() then return end
        local win = findNearestWindow(); if not win then return end
        local fv = RemWindow and RemWindow:FindFirstChild("fastvault")
        if fv then
            pcall(function() fv:FireServer(LP) end)
            _lastFastVault = tick()
        end
    end)
    NMHUB.Connections.FastVault = _fastVaultConn
end

stopFastVault = function()
    if _fastVaultConn then
        pcall(function() _fastVaultConn:Disconnect() end)
        _fastVaultConn = nil
        NMHUB.Connections.FastVault = nil
    end
end

local _fleeConn  = nil
local _lastFlee  = 0

startFleeKiller = function()
    if _fleeConn then return end
    _fleeConn = RunService.Heartbeat:Connect(function()
        if not NMHUB.Flags.Surv_FleeKiller or not isSurvivor() then return end
        if isBeingCarried() or isHooked() then return end
        if (tick() - _lastFlee) < 5.0 then return end
        local char = getChar(); if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local fleeDist = NMHUB.Flags.Surv_FleeDist or 30
        local killerChar = findKillerCharacter()
        if not killerChar then return end
        local khrp = killerChar:FindFirstChild("HumanoidRootPart"); if not khrp then return end
        if (hrp.Position - khrp.Position).Magnitude > fleeDist then return end
        local target = findFarthestGen()
        if not target then return end
        local pos = target:IsA("BasePart") and target.Position
            or (target:IsA("Model") and target:GetPivot().Position)
        if not pos then return end
        performSafeTeleport(CFrame.new(pos + Vector3.new(0, 3, 4)))
        _lastFlee = tick()
        SafeNotify({ Title = "Flee Killer", Content = "Teleported to farthest generator!", Type = "info", Duration = 2 })
    end)
    NMHUB.Connections.FleeKiller = _fleeConn
end

stopFleeKiller = function()
    if _fleeConn then
        pcall(function() _fleeConn:Disconnect() end)
        _fleeConn = nil
        NMHUB.Connections.FleeKiller = nil
    end
end

local _alertConn    = nil
local _lastAlert    = 0
local _wasInRange   = false

startKillerAlert = function()
    if _alertConn then return end
    _alertConn = RunService.Heartbeat:Connect(function()
        if not NMHUB.Flags.Surv_KillerAlert or not isSurvivor() then return end
        local char = getChar(); if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local alertRange = NMHUB.Flags.Surv_AlertRange or 35
        local killerChar = findKillerCharacter()
        if not killerChar then _wasInRange = false; return end
        local khrp = killerChar:FindFirstChild("HumanoidRootPart"); if not khrp then return end
        local dist = (hrp.Position - khrp.Position).Magnitude
        local inRange = dist <= alertRange
        if inRange and not _wasInRange then
            if (tick() - _lastAlert) > 3.0 then
                SafeNotify({
                    Title = "⚠ Killer Nearby!",
                    Content = string.format("Killer is %.0f studs away!", dist),
                    Type   = "warning",
                    Duration = 3,
                })
                _lastAlert = tick()
            end
        end
        _wasInRange = inRange
    end)
    NMHUB.Connections.KillerAlert = _alertConn
end

stopKillerAlert = function()
    if _alertConn then
        pcall(function() _alertConn:Disconnect() end)
        _alertConn = nil
        NMHUB.Connections.KillerAlert = nil
        _wasInRange = false
    end
end

do
local _escapeConn     = nil
local _lastEscape     = 0
local _escapeRunToken = 0
local _escapeBusy     = false
local _lastEscapeWarn = 0

local function _getLeverEvent()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local exit = rem and rem:FindFirstChild("Exit")
    return exit and exit:FindFirstChild("LeverEvent")
end

local function _resolveNearestExitPoint()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, exitPoint in ipairs(CollectionService:GetTagged("ExitPoint")) do
        if exitPoint:IsA("BasePart") and exitPoint:IsDescendantOf(workspace) then
            local dist = (exitPoint.Position - hrp.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = exitPoint
            end
        end
    end
    return best
end

local function _escapeStillActive(token)
    return token == _escapeRunToken
        and not _G.NOMERCY_Shutdown
        and NMHUB.Flags.Surv_AutoEscape == true
        and isSurvivor()
end

local function _resolveInstanceCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.CFrame end
    if obj:IsA("Model") then
        local ok, cf = pcall(function() return obj:GetPivot() end)
        if ok then return cf end
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        return part and part.CFrame or nil
    end
    return nil
end

local function _resolveEscapeCFrame()
    local map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("map") or workspace
    if map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop") then
        return CFrame.new(3098.16, 454.04, -4918.74)
    end
    if map:FindFirstChild("HooksMeat") then
        return CFrame.new(1546.12, 152.21, -796.72)
    end
    if map:FindFirstChild("churchbell") then
        return CFrame.new(760.98, -20.14, -78.48)
    end
    local finish = map:FindFirstChild("Finishline") or map:FindFirstChild("FinishLine")
    local cf = _resolveInstanceCFrame(finish)
    if cf then return cf end
    local exitGate = map:FindFirstChild("ExitGate") or map:FindFirstChild("exitgate")
    cf = _resolveInstanceCFrame(exitGate)
    if cf then return cf end
    local best, bestDist = nil, math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Gate" then
            local target = obj:FindFirstChild("Escape") or obj
            local gateCF = _resolveInstanceCFrame(target)
            if gateCF then
                local dist = hrp and (gateCF.Position - hrp.Position).Magnitude or 0
                if dist < bestDist then bestDist = dist; best = gateCF end
            end
        end
    end
    return best
end

local function _resolveInsideGateCFrame()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local rootPos = root and root.Position
    local bestCF, bestDist = nil, math.huge
    local map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("map") or workspace
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Gate" then
            local gatePart = obj:FindFirstChild("Escape")
                or obj:FindFirstChild("Gate")
                or obj:FindFirstChildWhichIsA("BasePart")
            if gatePart and gatePart:IsA("BasePart") then
                local insideCF = gatePart.CFrame + (gatePart.CFrame.LookVector * 8)
                local dist = rootPos and (insideCF.Position - rootPos).Magnitude or 0
                if dist < bestDist then bestDist = dist; bestCF = insideCF end
            end
        end
    end
    if bestCF then return bestCF end
    local fallback = _resolveEscapeCFrame()
    return fallback and (fallback + fallback.LookVector * 6) or nil
end

local function safeTeleport(targetCFrame, offset, token)
    if not targetCFrame or not _escapeStillActive(token) then return false end
    return performSafeTeleport(targetCFrame, offset)
end

local function _runAutoEscape(token)
    if not _escapeStillActive(token) then return end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local generator = remotes and remotes:FindFirstChild("Generator")
    local escapeTime = generator and generator:FindFirstChild("Escapetime")
    if escapeTime then 
        pcall(function() escapeTime:FireServer() end) 
    end

    local escapeCF = _resolveInsideGateCFrame()
    if not escapeCF then return end

    if not safeTeleport(escapeCF, Vector3.new(0, 2, 0), token) then
        return
    end

    task.wait(0.05)
    for _ = 1, 5 do
        if not _escapeStillActive(token) then break end
        local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not h then break end
        h.CFrame = h.CFrame + (h.CFrame.LookVector * 10)
        task.wait(0.03)
    end
end

startAutoEscape = function()
    if _escapeConn then return end
    _escapeConn = RunService.Heartbeat:Connect(function()
        if not NMHUB.Flags.Surv_AutoEscape or not isSurvivor() or _escapeBusy then return end
        if (tick() - _lastEscape) < 1.0 then return end
        _lastEscape = tick()
        _escapeBusy = true
        _escapeRunToken = _escapeRunToken + 1
        local token = _escapeRunToken
        task.spawn(function()
            local ok, err = pcall(_runAutoEscape, token)
            if not ok and tick() - _lastEscapeWarn > 2 then
                _lastEscapeWarn = tick()
                warn("[King Vypers][AutoEscape] " .. tostring(err))
            end
            if token == _escapeRunToken then _escapeBusy = false end
        end)
    end)
    NMHUB.Connections.AutoEscape = _escapeConn
end

stopAutoEscape = function()
    _escapeRunToken = _escapeRunToken + 1
    _escapeBusy = false
    if _escapeConn then
        pcall(function() _escapeConn:Disconnect() end)
        _escapeConn = nil
        NMHUB.Connections.AutoEscape = nil
    end
end
end

local _survDispConn = nil

local function anySurvFeatureNeedingDispatch()
    return NMHUB.Flags.Surv_NoSlowdown
end

stopSurvDispatcher = function()
    if _survDispConn then
        pcall(function() _survDispConn:Disconnect() end)
        _survDispConn = nil
    end
end

startSurvDispatcher = function()
    if _survDispConn then return end
    _survDispConn = RunService.Heartbeat:Connect(function()
        if _G.NOMERCY_Shutdown then stopSurvDispatcher(); return end
        if not anySurvFeatureNeedingDispatch() then stopSurvDispatcher(); return end
        pcall(stepSurvNoSlowdown)
    end)
end

if NMHUB.Flags.Surv_NoSlowdown then startSurvDispatcher() end

-- ===== AIMBOT TAB =====
do
local _aimbotHolding   = false

local function _getAimbotTarget()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local cam = workspace.CurrentCamera
    if not cam then return nil end

    local fovRadius = NMHUB.Flags.Aimbot_FOV or 120
    local bestDist  = fovRadius
    local bestPart  = nil

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == LP then continue end
        local tChar = pl.Character
        if not tChar then continue end
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then continue end
        local tHum = tChar:FindFirstChildOfClass("Humanoid")
        if not tHum or tHum.Health <= 0 then continue end

        if isKiller() then
            if not (pl.Team and pl.Team.Name == "Survivors") then continue end
        else
            if not (pl.Team and pl.Team.Name == "Killer") then continue end
        end

        local screenPos, onScreen = cam:WorldToViewportPoint(tHRP.Position)
        if not onScreen then continue end
        local viewSize = cam.ViewportSize
        local cx, cy   = viewSize.X / 2, viewSize.Y / 2
        local dx, dy   = screenPos.X - cx, screenPos.Y - cy
        local screenDist = math.sqrt(dx*dx + dy*dy)

        if NMHUB.Flags.Aimbot_VisCheck then
            local ray = Ray.new(cam.CFrame.Position,
                (tHRP.Position - cam.CFrame.Position).Unit * 1000)
            local hitPart = workspace:FindPartOnRayWithIgnoreList(
                ray, { LP.Character, cam })
            if hitPart and hitPart:IsDescendantOf(tChar) == false then continue end
        end

        if screenDist < bestDist then
            bestDist = screenDist
            bestPart = tHRP
        end
    end
    return bestPart
end

local function _startAimbot()
    if NMHUB.Connections.AimbotConn then return end

    if DrawingAvailable then
        pcall(function()
            local circle = Drawing.new("Circle")
            circle.Visible      = true
            circle.Radius       = NMHUB.Flags.Aimbot_FOV or 120
            circle.Color        = Color3.fromRGB(255, 50, 50)
            circle.Thickness    = 1
            circle.Filled       = false
            circle.Transparency = 0.6
            NMHUB.GuiElements.AimbotFovCircle = circle
        end)
    elseif isMobile then
        pcall(function()
            local pg = LP:FindFirstChild("PlayerGui") or CoreGui
            local sg = Instance.new("ScreenGui")
            sg.Name = "MobileFOV"; sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true; sg.DisplayOrder = 90; sg.Parent = pg
            local fovF = Instance.new("Frame")
            fovF.Name = "FOVCircle"; fovF.BackgroundTransparency = 1
            fovF.AnchorPoint = Vector2.new(0.5, 0.5)
            fovF.Position = UDim2.new(0.5, 0, 0.5, 0)
            local r = NMHUB.Flags.Aimbot_FOV or 120
            fovF.Size = UDim2.new(0, r*2, 0, r*2)
            fovF.Visible = false; fovF.Parent = sg
            Instance.new("UICorner", fovF).CornerRadius = UDim.new(1, 0)
            local fovStk = Instance.new("UIStroke")
            fovStk.Color = Color3.fromRGB(255, 50, 50)
            fovStk.Thickness = 1.5; fovStk.Transparency = 0.3
            fovStk.Parent = fovF
            NMHUB.GuiElements.MobileFOVGui = sg
            NMHUB.GuiElements.MobileFOVFrame = fovF
            NMHUB.GuiElements.MobileFOVStroke = fovStk
        end)
    end

    NMHUB.Connections.AimbotConn = RunService.Heartbeat:Connect(function()
        if _G.NOMERCY_Shutdown or not NMHUB.Flags.Aimbot_Enabled then return end

        pcall(function()
            local fc = NMHUB.GuiElements.AimbotFovCircle
            if fc then
                local cam = workspace.CurrentCamera
                local vs  = cam and cam.ViewportSize
                if vs then
                    fc.Position = Vector2.new(vs.X/2, vs.Y/2)
                    fc.Radius   = NMHUB.Flags.Aimbot_FOV or 120
                    fc.Visible  = NMHUB.Flags.Aimbot_ShowFOV
                end
            end
        end)
        pcall(function()
            local mf = NMHUB.GuiElements.MobileFOVFrame
            if mf then
                local r = NMHUB.Flags.Aimbot_FOV or 120
                mf.Size = UDim2.new(0, r*2, 0, r*2)
                mf.Visible = NMHUB.Flags.Aimbot_ShowFOV or false
                local ms = NMHUB.GuiElements.MobileFOVStroke
                if ms then
                    ms.Color = _aimbotHolding and Color3.fromRGB(90,220,120) or Color3.fromRGB(255,50,50)
                end
            end
        end)

        if NMHUB.Flags.Aimbot_HoldRMB then
            if not isMobile then
                _aimbotHolding = UserInputService:IsMouseButtonPressed(
                    Enum.UserInputType.MouseButton2)
            end
            if not _aimbotHolding then return end
        end

        local target = _getAimbotTarget()
        if not target then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local smooth   = NMHUB.Flags.Aimbot_Smooth or 0.15
        local targetCF = CFrame.lookAt(cam.CFrame.Position, target.Position)
        cam.CFrame = cam.CFrame:Lerp(targetCF, smooth)
    end)
end

local function _stopAimbot()
    if NMHUB.Connections.AimbotConn then
        pcall(function() NMHUB.Connections.AimbotConn:Disconnect() end)
        NMHUB.Connections.AimbotConn = nil
    end
    pcall(function()
        local fc = NMHUB.GuiElements.AimbotFovCircle
        if fc then fc:Remove() end
        NMHUB.GuiElements.AimbotFovCircle = nil
    end)
    pcall(function()
        if NMHUB.GuiElements.MobileFOVGui then
            NMHUB.GuiElements.MobileFOVGui:Destroy()
            NMHUB.GuiElements.MobileFOVGui = nil
            NMHUB.GuiElements.MobileFOVFrame = nil
            NMHUB.GuiElements.MobileFOVStroke = nil
        end
    end)
    _aimbotHolding = false
end

local AimbotGeneral = TabAimbot:CreateSection({ Title = "Aimbot", Opened = true })

AimbotGeneral:CreateToggle({ Id = "Aimbot_Enabled", Title = "Enable Aimbot", Default = false, Callback = function(v)
    NMHUB.Flags.Aimbot_Enabled = v
    if v then _startAimbot() else _stopAimbot() end
    autoSaveConfig()
end })

AimbotGeneral:CreateToggle({ Id = "Aimbot_HoldRMB", Title = "Hold RMB to Aim", Default = true, Callback = function(v)
    NMHUB.Flags.Aimbot_HoldRMB = v
    autoSaveConfig()
end })

AimbotGeneral:CreateToggle({ Id = "Aimbot_VisCheck", Title = "Visibility Check", Default = false, Callback = function(v)
    NMHUB.Flags.Aimbot_VisCheck = v
    autoSaveConfig()
end })

AimbotGeneral:CreateToggle({ Id = "Aimbot_ShowFOV", Title = "Show FOV Circle", Default = true, Callback = function(v)
    NMHUB.Flags.Aimbot_ShowFOV = v
    autoSaveConfig()
end })

local AimbotSettings = TabAimbot:CreateSection({ Title = "Settings" })

AimbotSettings:CreateSlider({ Id = "Aimbot_FOV", Title = "FOV Radius", Min = 20, Max = 500, Increment = 5, Suffix = " px", Default = 120, Callback = function(v)
    NMHUB.Flags.Aimbot_FOV = v
    autoSaveConfig()
end })

AimbotSettings:CreateSlider({ Id = "Aimbot_Smooth", Title = "Smooth", Min = 1, Max = 100, Increment = 1, Suffix = "%", Default = 15, Callback = function(v)
    NMHUB.Flags.Aimbot_Smooth = v / 100
    autoSaveConfig()
end })

end -- ===== END AIMBOT TAB =====

-- ===== TELEPORT TAB =====
local function getTeleportPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local tp = obj:FindFirstChild("Tp", true)
        if tp and tp:IsA("BasePart") then return tp.Position end
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        local ok, piv = pcall(function() return obj:GetPivot().Position end)
        if ok then return piv end
        local bp = obj:FindFirstChildWhichIsA("BasePart")
        if bp then return bp.Position end
    end
    return nil
end

local function doTeleport(obj)
    local pos  = getTeleportPos(obj)
    if not pos then return false end
    return performSafeTeleport(CFrame.new(pos), Vector3.new(0, 4, 0))
end

local _tpGenObjs,  _tpGenList   = {}, {}
local _tpHookObjs, _tpHookList  = {}, {}
local _tpPalObjs,  _tpPalList   = {}, {}
local _tpWinObjs,  _tpWinList   = {}, {}
local _tpGateObjs, _tpGateList  = {}, {}
local _tpPlrObjs,  _tpPlrList   = {}, {}

local function rebuildTagList(tag, prefix, listOut, objsOut)
    for k in pairs(objsOut) do objsOut[k] = nil end
    while #listOut > 0 do table.remove(listOut) end
    local i = 0
    for _, obj in ipairs(CollectionService:GetTagged(tag)) do
        i = i + 1
        local label = prefix .. " " .. i
        table.insert(listOut, label)
        objsOut[label] = obj
    end
    if #listOut == 0 then table.insert(listOut, "— none found —") end
end

local function rebuildGateList()
    for k in pairs(_tpGateObjs) do _tpGateObjs[k] = nil end
    while #_tpGateList > 0 do table.remove(_tpGateList) end
    local gates = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Gate"
        and obj:IsDescendantOf(workspace) then
            table.insert(gates, obj)
        end
    end
    if _mapCache then _mapCache.Gates = gates end
    local i = 0
    for _, gateObj in ipairs(gates) do
        i = i + 1
        local label = "Gate " .. i
        table.insert(_tpGateList, label)
        _tpGateObjs[label] = gateObj
    end
    if #_tpGateList == 0 then table.insert(_tpGateList, "— none found —") end
end

local function rebuildPlayerList()
    for k in pairs(_tpPlrObjs) do _tpPlrObjs[k] = nil end
    while #_tpPlrList > 0 do table.remove(_tpPlrList) end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP then
            table.insert(_tpPlrList, pl.Name)
            _tpPlrObjs[pl.Name] = pl
        end
    end
    if #_tpPlrList == 0 then table.insert(_tpPlrList, "— no other players —") end
end

rebuildTagList("GeneratorPoint", "Generator", _tpGenList,  _tpGenObjs)
rebuildTagList("HookPoint",      "Hook",      _tpHookList, _tpHookObjs)
rebuildTagList("PalletPoint",    "Pallet",    _tpPalList,  _tpPalObjs)
rebuildTagList("VaultPoint",     "Window",    _tpWinList,  _tpWinObjs)
rebuildGateList()
rebuildPlayerList()

local _selGen, _selHook, _selPal, _selWin, _selGate, _selPlr = nil,nil,nil,nil,nil,nil

local TeleportMapObjects = TabTeleport:CreateSection({ Title = "Map Objects", Opened = true })

local TpGenDropdown = TeleportMapObjects:CreateDropdown({ 
    Id = "TpGenerator", Title = "Generator", Values = _tpGenList, Default = "", Sidebar = true, 
    Refresh = function() rebuildTagList("GeneratorPoint", "Generator", _tpGenList, _tpGenObjs); return _tpGenList end, 
    RefreshInterval = 5, Callback = function(v) _selGen = _tpGenObjs[v] end 
})
TeleportMapObjects:CreateButton({ Id = "BtnTpGen", Title = "Teleport to Generator", Callback = function() 
    if _selGen and doTeleport(_selGen) then return end 
    SafeNotify({ Title = "Teleport", Content = "No generator selected or map not loaded yet.", Type = "warning", Duration = 3 }) 
end })

local TpHookDropdown = TeleportMapObjects:CreateDropdown({ 
    Id = "TpHook", Title = "Hook", Values = _tpHookList, Default = "", Sidebar = true, 
    Refresh = function() rebuildTagList("HookPoint", "Hook", _tpHookList, _tpHookObjs); return _tpHookList end, 
    RefreshInterval = 5, Callback = function(v) _selHook = _tpHookObjs[v] end 
})
TeleportMapObjects:CreateButton({ Id = "BtnTpHook", Title = "Teleport to Hook", Callback = function() 
    if _selHook and doTeleport(_selHook) then return end 
    SafeNotify({ Title = "Teleport", Content = "No hook selected or map not loaded yet.", Type = "warning", Duration = 3 }) 
end })

local TpPalDropdown = TeleportMapObjects:CreateDropdown({ 
    Id = "TpPallet", Title = "Pallet", Values = _tpPalList, Default = "", Sidebar = true, 
    Refresh = function() rebuildTagList("PalletPoint", "Pallet", _tpPalList, _tpPalObjs); return _tpPalList end, 
    RefreshInterval = 5, Callback = function(v) _selPal = _tpPalObjs[v] end 
})
TeleportMapObjects:CreateButton({ Id = "BtnTpPal", Title = "Teleport to Pallet", Callback = function() 
    if _selPal and doTeleport(_selPal) then return end 
    SafeNotify({ Title = "Teleport", Content = "No pallet selected or map not loaded yet.", Type = "warning", Duration = 3 }) 
end })

local TpWinDropdown = TeleportMapObjects:CreateDropdown({ 
    Id = "TpWindow", Title = "Window", Values = _tpWinList, Default = "", Sidebar = true, 
    Refresh = function() rebuildTagList("VaultPoint", "Window", _tpWinList, _tpWinObjs); return _tpWinList end, 
    RefreshInterval = 5, Callback = function(v) _selWin = _tpWinObjs[v] end 
})
TeleportMapObjects:CreateButton({ Id = "BtnTpWin", Title = "Teleport to Window", Callback = function() 
    if _selWin and doTeleport(_selWin) then return end 
    SafeNotify({ Title = "Teleport", Content = "No window selected or map not loaded yet.", Type = "warning", Duration = 3 }) 
end })

local TpGateDropdown = TeleportMapObjects:CreateDropdown({ 
    Id = "TpGate", Title = "Gate", Values = _tpGateList, Default = "", Sidebar = true, 
    Refresh = function() rebuildGateList(); return _tpGateList end, 
    RefreshInterval = 5, Callback = function(v) _selGate = _tpGateObjs[v] end 
})
TeleportMapObjects:CreateButton({ Id = "BtnTpGate", Title = "Teleport to Gate", Callback = function() 
    if _selGate and doTeleport(_selGate) then return end 
    SafeNotify({ Title = "Teleport", Content = "No gate selected or gate not found in map.", Type = "warning", Duration = 3 }) 
end })

TeleportMapObjects:CreateButton({ Id = "BtnRefreshMap", Title = "Refresh Map Objects", Callback = function()
    rebuildTagList("GeneratorPoint", "Generator", _tpGenList,  _tpGenObjs)
    rebuildTagList("HookPoint",      "Hook",      _tpHookList, _tpHookObjs)
    rebuildTagList("PalletPoint",    "Pallet",    _tpPalList,  _tpPalObjs)
    rebuildTagList("VaultPoint",     "Window",    _tpWinList,  _tpWinObjs)
    rebuildGateList()
    _selGen = nil; _selHook = nil; _selPal = nil; _selWin = nil; _selGate = nil
    if TpGenDropdown and TpGenDropdown.Refresh then pcall(TpGenDropdown.Refresh, _tpGenList) end
    if TpHookDropdown and TpHookDropdown.Refresh then pcall(TpHookDropdown.Refresh, _tpHookList) end
    if TpPalDropdown and TpPalDropdown.Refresh then pcall(TpPalDropdown.Refresh, _tpPalList) end
    if TpWinDropdown and TpWinDropdown.Refresh then pcall(TpWinDropdown.Refresh, _tpWinList) end
    if TpGateDropdown and TpGateDropdown.Refresh then pcall(TpGateDropdown.Refresh, _tpGateList) end
    SafeNotify({ Title = "Teleport", Content = "Map objects refreshed.", Type = "success", Duration = 2 })
end })

local TeleportPlayers = TabTeleport:CreateSection({ Title = "Players" })

local TpPlrDropdown = TeleportPlayers:CreateDropdown({ 
    Id = "TpPlayer", Title = "Player", Values = _tpPlrList, Default = "", Sidebar = true, 
    Refresh = function() rebuildPlayerList(); return _tpPlrList end, 
    RefreshInterval = 5, Callback = function(v) _selPlr = _tpPlrObjs[v] end 
})
TeleportPlayers:CreateButton({ Id = "BtnTpPlr", Title = "Teleport to Player", Callback = function()
    if not _selPlr then
        SafeNotify({ Title = "Teleport", Content = "No player selected.", Type = "warning", Duration = 3 })
        return
    end
    local tChar = _selPlr.Character
    local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then
        SafeNotify({ Title = "Teleport", Content = "Player has no active character.", Type = "warning", Duration = 3 })
        return
    end
    local char = getChar(); if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    hrp.CFrame = tHRP.CFrame * CFrame.new(3, 0, 0)
end })

-- ===== MISC TAB =====
do
local PlayerMovementSection = TabMisc:CreateSection({ Title = "Player Movement", Opened = true })

PlayerMovementSection:CreateSlider({ Id = "WalkSpeed", Title = "WalkSpeed", Min = 16, Max = 500, Increment = 1, Suffix = " spd", Default = 16, Callback = function(Value)
    NMHUB.Flags.WalkSpeed = Value
    local char = LP.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Value
    end
    autoSaveConfig()
end })

PlayerMovementSection:CreateSlider({ Id = "JumpPower", Title = "JumpPower", Min = 50, Max = 500, Increment = 1, Suffix = " jp", Default = 50, Callback = function(Value)
    NMHUB.Flags.JumpPower = Value
    local char = LP.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = Value
    end
    autoSaveConfig()
end })

PlayerMovementSection:CreateToggle({ Id = "Fly", Title = "Fly", Default = false, Callback = function(Value)
    NMHUB.Flags.Fly = Value
    if Value then
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        hum.PlatformStand = true

        local bv = Instance.new("BodyVelocity")
        bv.Name     = "FlyVelocity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent   = hrp
        NMHUB.GuiElements.FlyVelocity = bv

        local bg = Instance.new("BodyGyro")
        bg.Name      = "FlyGyro"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P         = 9e4
        bg.CFrame    = hrp.CFrame
        bg.Parent    = hrp
        NMHUB.GuiElements.FlyGyro = bg

        NMHUB:Disconnect("FlyHeartbeat")
        NMHUB.Connections.FlyHeartbeat = RunService.Heartbeat:Connect(function()
            if _G.NOMERCY_Shutdown or not NMHUB.Flags.Fly then
                if bv and bv.Parent then bv:Destroy() end
                if bg and bg.Parent then bg:Destroy() end
                if hum and hum.Parent then hum.PlatformStand = false end
                return
            end
            if not hrp or not hrp.Parent then return end

            local cam = workspace.CurrentCamera
            if not cam then return end

            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                dir = dir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.X)
            or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                dir = dir - Vector3.new(0, 1, 0)
            end

            local speed = NMHUB.Flags.WalkSpeed or 50
            bv.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
            bg.CFrame = cam.CFrame
        end)

        SafeNotify({ Title = "Fly Enabled", Content = "Space=up  X/LCtrl/LShift=down  WASD=move", Type = "success", Duration = 3 })
    else
        NMHUB:Disconnect("FlyHeartbeat")

        if NMHUB.GuiElements.FlyVelocity then
            pcall(function() NMHUB.GuiElements.FlyVelocity:Destroy() end)
            NMHUB.GuiElements.FlyVelocity = nil
        end
        if NMHUB.GuiElements.FlyGyro then
            pcall(function() NMHUB.GuiElements.FlyGyro:Destroy() end)
            NMHUB.GuiElements.FlyGyro = nil
        end

        pcall(function()
            local ch  = LP.Character
            local hm  = ch and ch:FindFirstChildOfClass("Humanoid")
            if hm then hm.PlatformStand = false end
        end)

        SafeNotify({ Title = "Fly Disabled", Content = "Flight mode stopped.", Type = "info", Duration = 2 })
    end
    autoSaveConfig()
end })

PlayerMovementSection:CreateToggle({ Id = "Noclip", Title = "Noclip", Default = false, Callback = function(Value)
    NMHUB.Flags.Noclip = Value
    if Value then
        NMHUB:Disconnect("NoclipStepped")
        NMHUB.Connections.NoclipStepped = RunService.Stepped:Connect(function()
            if _G.NOMERCY_Shutdown or not NMHUB.Flags.Noclip then return end
            local char = LP.Character
            if not char then return end
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if NMHUB.OriginalState.CanCollide[part] == nil then
                        NMHUB.OriginalState.CanCollide[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end)
        SafeNotify({ Title = "Noclip Enabled", Content = "You can now walk through walls!", Type = "info", Duration = 2 })
    else
        NMHUB:Disconnect("NoclipStepped")
        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    if NMHUB.OriginalState.CanCollide[part] ~= nil then
                        part.CanCollide = NMHUB.OriginalState.CanCollide[part]
                        NMHUB.OriginalState.CanCollide[part] = nil
                    else
                        part.CanCollide = true
                    end
                end
            end
        end
        SafeNotify({ Title = "Noclip Disabled", Content = "Collision restored.", Type = "info", Duration = 2 })
    end
    autoSaveConfig()
end })

PlayerMovementSection:CreateToggle({ Id = "InfiniteJump", Title = "Infinite Jump", Default = false, Callback = function(Value)
    NMHUB.Flags.InfiniteJump = Value
    if Value then
        local UIS = game:GetService("UserInputService")
        NMHUB:Disconnect("InfiniteJump")
        NMHUB.Connections.InfiniteJump = UIS.JumpRequest:Connect(function()
            if not NMHUB.Flags.InfiniteJump then return end
            local char = LP.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        SafeNotify({ Title = "Infinite Jump Enabled", Content = "You can jump infinitely!", Type = "info", Duration = 2 })
    else
        if NMHUB.Connections.InfiniteJump then
            NMHUB.Connections.InfiniteJump:Disconnect()
            NMHUB.Connections.InfiniteJump = nil
        end
        SafeNotify({ Title = "Infinite Jump Disabled", Content = "Jump returned to normal.", Type = "info", Duration = 2 })
    end
    autoSaveConfig()
end })

local UtilitiesSection = TabMisc:CreateSection({ Title = "Utilities" })

UtilitiesSection:CreateToggle({ Id = "AntiAFK", Title = "Anti-AFK", Default = false, Callback = function(Value)
    NMHUB.Flags.AntiAFK = Value
    if Value then
        local VirtualUser = game:GetService("VirtualUser")
        NMHUB:Disconnect("AntiAFK")
        NMHUB.Connections.AntiAFK = LP.Idled:Connect(function()
            if not NMHUB.Flags.AntiAFK then return end
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        SafeNotify({ Title = "Anti-AFK Enabled", Content = "You won't be kicked for inactivity!", Type = "success", Duration = 2 })
    else
        if NMHUB.Connections.AntiAFK then
            NMHUB.Connections.AntiAFK:Disconnect()
            NMHUB.Connections.AntiAFK = nil
        end
        SafeNotify({ Title = "Anti-AFK Disabled", Content = "AFK detection re-enabled.", Type = "info", Duration = 2 })
    end
    autoSaveConfig()
end })

UtilitiesSection:CreateToggle({ Id = "AutoReconnect", Title = "Auto-Reconnect", Default = false, Callback = function(Value)
    NMHUB.Flags.AutoReconnect = Value
    if Value then
        local TeleportService = game:GetService("TeleportService")
        NMHUB:Disconnect("AutoReconnect")
        NMHUB.Connections.AutoReconnect = game:GetService("CoreGui").DescendantAdded:Connect(function(descendant)
            if not NMHUB.Flags.AutoReconnect then return end
            if descendant.Name == "ErrorPrompt" or descendant.Name == "ErrorFrame" then
                task.wait(0.5)
                pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
            end
        end)
        SafeNotify({ Title = "Auto-Reconnect Enabled", Content = "Will auto-rejoin on disconnect!", Type = "success", Duration = 2 })
    else
        if NMHUB.Connections.AutoReconnect then
            NMHUB.Connections.AutoReconnect:Disconnect()
            NMHUB.Connections.AutoReconnect = nil
        end
        SafeNotify({ Title = "Auto-Reconnect Disabled", Content = "Auto-rejoin disabled.", Type = "info", Duration = 2 })
    end
    autoSaveConfig()
end })

end -- ===== END MISC TAB =====

-- ===== SETTINGS TAB =====
do
local PerformanceSection = TabSettings:CreateSection({ Title = "Performance", Opened = true })

PerformanceSection:CreateToggle({ Id = "FPSBoost", Title = "FPS Boost", Default = false, Callback = function(Value)
    NMHUB.Flags.FPSBoost = Value
    if Value then
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace.Terrain
        if not NMHUB.OriginalState.Lighting.Stored then
            NMHUB.OriginalState.Lighting.GlobalShadows = Lighting.GlobalShadows
            NMHUB.OriginalState.Lighting.FogEnd = Lighting.FogEnd
            NMHUB.OriginalState.Terrain.WaterWaveSize = Terrain.WaterWaveSize
            NMHUB.OriginalState.Terrain.WaterWaveSpeed = Terrain.WaterWaveSpeed
            NMHUB.OriginalState.Terrain.WaterReflectance = Terrain.WaterReflectance
            NMHUB.OriginalState.Terrain.WaterTransparency = Terrain.WaterTransparency
            NMHUB.OriginalState.Lighting.Stored = true
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
        SafeNotify({ Title = "FPS Boost Enabled", Content = "Graphics optimized for better performance!", Type = "success", Duration = 3 })
    else
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace.Terrain
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        if NMHUB.OriginalState.Lighting.Stored then
            Lighting.GlobalShadows = NMHUB.OriginalState.Lighting.GlobalShadows
            Lighting.FogEnd = NMHUB.OriginalState.Lighting.FogEnd
            Terrain.WaterWaveSize = NMHUB.OriginalState.Terrain.WaterWaveSize
            Terrain.WaterWaveSpeed = NMHUB.OriginalState.Terrain.WaterWaveSpeed
            Terrain.WaterReflectance = NMHUB.OriginalState.Terrain.WaterReflectance
            Terrain.WaterTransparency = NMHUB.OriginalState.Terrain.WaterTransparency
        else
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 100000
            Terrain.WaterWaveSize = 0.15
            Terrain.WaterWaveSpeed = 10
            Terrain.WaterReflectance = 1
            Terrain.WaterTransparency = 1
        end
        SafeNotify({ Title = "FPS Boost Disabled", Content = "Graphics restored to default.", Type = "info", Duration = 2 })
    end
    autoSaveConfig()
end })

PerformanceSection:CreateToggle({ Id = "RemoveTextures", Title = "Remove Textures", Default = false, Callback = function(Value)
    NMHUB.Flags.RemoveTextures = Value
    if Value then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                if NMHUB.OriginalState.Textures[obj] == nil then
                    NMHUB.OriginalState.Textures[obj] = obj.Transparency
                end
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                if NMHUB.OriginalState.Textures[obj] == nil then
                    NMHUB.OriginalState.Textures[obj] = obj.Enabled
                end
                obj.Enabled = false
            end
        end
        SafeNotify({ Title = "Textures Removed", Content = "All textures and particles disabled!", Type = "success", Duration = 2 })
    else
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                if NMHUB.OriginalState.Textures[obj] ~= nil then
                    obj.Transparency = NMHUB.OriginalState.Textures[obj]
                    NMHUB.OriginalState.Textures[obj] = nil
                else
                    obj.Transparency = 0
                end
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                if NMHUB.OriginalState.Textures[obj] ~= nil then
                    obj.Enabled = NMHUB.OriginalState.Textures[obj]
                    NMHUB.OriginalState.Textures[obj] = nil
                else
                    obj.Enabled = true
                end
            end
        end
        SafeNotify({ Title = "Textures Restored", Content = "Visual effects re-enabled.", Type = "info", Duration = 2 })
    end
    autoSaveConfig()
end })

PerformanceSection:CreateToggle({ Id = "PerformanceMonitor", Title = "Performance Monitor", Default = false, Callback = function(Value)
    NMHUB.Flags.PerformanceMonitor = Value
    if Value then
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "FPSCounter"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local Label = Instance.new("TextLabel")
        Label.Name = "FPSLabel"
        Label.Size = UDim2.fromOffset(100, 30)
        Label.Position = UDim2.new(1, -110, 0, 10)
        Label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Label.BackgroundTransparency = 0.5
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 14
        Label.Font = Enum.Font.GothamBold
        Label.Text = "FPS: --"
        Label.Parent = ScreenGui
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 6)
        Corner.Parent = Label
        
        pcall(function() ScreenGui.Parent = CoreGui end)
        if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end
        NMHUB.GuiElements.FPSCounter = ScreenGui
        
        NMHUB:Disconnect("FPSHeartbeat")
        local lastTime = tick()
        local frameCount = 0
        NMHUB.Connections.FPSHeartbeat = RunService.Heartbeat:Connect(function()
            if _G.NOMERCY_Shutdown or not NMHUB.Flags.PerformanceMonitor then return end
            frameCount = frameCount + 1
            local currentTime = tick()
            if currentTime - lastTime >= 1 then
                local fps = math.floor(frameCount / (currentTime - lastTime))
                if Label and Label.Parent then
                    Label.Text = "FPS: " .. fps
                    if fps >= 60 then
                        Label.TextColor3 = Color3.fromRGB(0, 255, 0)
                    elseif fps >= 30 then
                        Label.TextColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        Label.TextColor3 = Color3.fromRGB(255, 0, 0)
                    end
                end
                frameCount = 0
                lastTime = currentTime
            end
        end)
        SafeNotify({ Title = "FPS Monitor Enabled", Content = "FPS counter displayed on screen!", Type = "success", Duration = 2 })
    else
        if NMHUB.GuiElements.FPSCounter then
            NMHUB.GuiElements.FPSCounter:Destroy()
            NMHUB.GuiElements.FPSCounter = nil
        end
        NMHUB:Disconnect("FPSHeartbeat")
        SafeNotify({ Title = "FPS Monitor Disabled", Content = "FPS counter removed.", Type = "info", Duration = 2 })
    end
    autoSaveConfig()
end })

local SettingsSection = TabSettings:CreateSection({ Title = "Script Management" })

SettingsSection:CreateButton({ Id = "BtnDestroy", Title = "Destroy Script", Callback = function()
    SafeDialog({
        Title = "Konfirmasi Destroy",
        Content = "Yakin ingin destroy script?\nSemua fitur akan berhenti.",
        Buttons = {
            { Id = "BtnDestroyYes", Title = "Ya, Destroy", Callback = function()
                _G.NOMERCY_Shutdown = true
                if type(_G.NOMERCY_ShutdownHandler) == "function" then
                    _G.NOMERCY_ShutdownHandler()
                end
            end },
            { Id = "BtnDestroyNo", Title = "Batal", Callback = function()
                SafeNotify({ Title = "Dibatalkan", Content = "Script tetap berjalan.", Type = "info", Duration = 2 })
            end }
        }
    })
end })

end -- ===== END SETTINGS TAB =====

-- ===== CONFIG TAB =====
do
local function syncFeatureBackends()
    if NMHUB.Flags.Killer_HitboxExpand then applyHitboxExpand() else removeHitboxExpand() end
    if NMHUB.Flags.Killer_NoPalletStun then startKillerDispatcher() else stopNoPalletStunWatchdog() end
    if anyKillerFeatureOn() then startKillerDispatcher() else stopKillerDispatcher() end

    if NMHUB.Flags.Surv_AutoSkillCheck then startAutoSkillCheck() else stopAutoSkillCheck() end
    if NMHUB.Flags.Surv_FastRepair then startFastRepair() else stopFastRepair() end
    if NMHUB.Flags.Surv_InstantGen then startInstantGen() else stopInstantGen() end
    if NMHUB.Flags.Surv_AutoParry then startAutoParry() else stopAutoParry() end
    if NMHUB.Flags.Surv_AutoWiggle then startAutoWiggle() else stopAutoWiggle() end
    if NMHUB.Flags.Surv_InstantHeal then startInstantHeal() else stopInstantHeal() end
    if NMHUB.Flags.Surv_NoFallDmg then startNoFallDmg() else stopNoFallDmg() end
    if NMHUB.Flags.Surv_FastVault then startFastVault() else stopFastVault() end
    if NMHUB.Flags.Surv_FleeKiller then startFleeKiller() else stopFleeKiller() end
    if NMHUB.Flags.Surv_KillerAlert then startKillerAlert() else stopKillerAlert() end
    if NMHUB.Flags.Surv_AutoEscape then startAutoEscape() else stopAutoEscape() end
    if NMHUB.Flags.Surv_NoSlowdown then startSurvDispatcher() else stopSurvDispatcher() end

    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = NMHUB.Flags.WalkSpeed or hum.WalkSpeed
        hum.JumpPower = NMHUB.Flags.JumpPower or hum.JumpPower
    end
end

local HttpService = game:GetService("HttpService")
local ConfigFolder = "KingVypers/violence_district"

if not isfolder or not makefolder then
    warn("[King Vypers] Config system unavailable - executor missing folder functions")
else
    if not isfolder("KingVypers") then pcall(makefolder, "KingVypers") end
    if not isfolder(ConfigFolder) then pcall(makefolder, ConfigFolder) end
end

local function getConfigList()
    if not isfolder or not listfiles then return {} end
    local configs = {}
    local files = listfiles(ConfigFolder)
    for _, file in ipairs(files) do
        local name = file:match("([^/\\]+)%.json$")
        if name and name ~= "autoload" then
            table.insert(configs, name)
        end
    end
    return configs
end

local function saveConfig(configName)
    if not writefile or not HttpService then
        SafeNotify({ Title = "Config Error", Content = "Executor missing writefile function!", Type = "error", Duration = 3 })
        return false
    end
    local config = {
        Killer_AutoAttack       = NMHUB.Flags.Killer_AutoAttack       or false,
        Killer_AutoAttackRange  = NMHUB.Flags.Killer_AutoAttackRange  or 15,
        Killer_BurstAttack      = NMHUB.Flags.Killer_BurstAttack      or false,
        Killer_HitboxExpand     = NMHUB.Flags.Killer_HitboxExpand     or false,
        Killer_HitboxSize       = NMHUB.Flags.Killer_HitboxSize       or 15,
        Killer_InfiniteLunge    = NMHUB.Flags.Killer_InfiniteLunge    or false,
        Killer_InstantKill      = NMHUB.Flags.Killer_InstantKill      or false,
        Killer_InstantKillRange = NMHUB.Flags.Killer_InstantKillRange or 40,
        Killer_DestroyPallets   = NMHUB.Flags.Killer_DestroyPallets   or false,
        Killer_FullGenBreak     = NMHUB.Flags.Killer_FullGenBreak     or false,
        Killer_AutoHook         = NMHUB.Flags.Killer_AutoHook         or false,
        Killer_AntiBlind        = NMHUB.Flags.Killer_AntiBlind        or false,
        Killer_NoPalletStun     = NMHUB.Flags.Killer_NoPalletStun     or false,
        Killer_NoSlowdown       = NMHUB.Flags.Killer_NoSlowdown       or false,
        Surv_AutoSkillCheck = NMHUB.Flags.Surv_AutoSkillCheck or false,
        Surv_FastRepair     = NMHUB.Flags.Surv_FastRepair     or false,
        Surv_InstantGen     = NMHUB.Flags.Surv_InstantGen     or false,
        Surv_AutoParry      = NMHUB.Flags.Surv_AutoParry      or false,
        Surv_ParryRange     = NMHUB.Flags.Surv_ParryRange     or 20,
        Surv_AutoWiggle     = NMHUB.Flags.Surv_AutoWiggle     or false,
        Surv_InstantHeal    = NMHUB.Flags.Surv_InstantHeal    or false,
        Surv_NoFallDmg      = NMHUB.Flags.Surv_NoFallDmg      or false,
        Surv_NoSlowdown     = NMHUB.Flags.Surv_NoSlowdown     or false,
        Surv_FastVault      = NMHUB.Flags.Surv_FastVault      or false,
        Surv_FleeKiller     = NMHUB.Flags.Surv_FleeKiller     or false,
        Surv_FleeDist       = NMHUB.Flags.Surv_FleeDist       or 30,
        Surv_KillerAlert    = NMHUB.Flags.Surv_KillerAlert    or false,
        Surv_AlertRange     = NMHUB.Flags.Surv_AlertRange     or 35,
        Surv_AutoEscape     = NMHUB.Flags.Surv_AutoEscape     or false,
        Visual_KillerESP       = NMHUB.Flags.Visual_KillerESP or false,
        Visual_SurvivorESP     = NMHUB.Flags.Visual_SurvivorESP or false,
        Visual_GeneratorESP    = NMHUB.Flags.Visual_GeneratorESP or false,
        Visual_GateESP         = NMHUB.Flags.Visual_GateESP or false,
        Visual_HookESP         = NMHUB.Flags.Visual_HookESP or false,
        Visual_ClosestHookOnly = NMHUB.Flags.Visual_ClosestHookOnly or false,
        Visual_PalletESP       = NMHUB.Flags.Visual_PalletESP or false,
        Visual_WindowESP       = NMHUB.Flags.Visual_WindowESP or false,
        Visual_NoFog           = NMHUB.Flags.Visual_NoFog or false,
        Visual_Fullbright      = NMHUB.Flags.Visual_Fullbright or false,
        Visual_CustomFOV       = NMHUB.Flags.Visual_CustomFOV or false,
        Visual_FOVValue        = NMHUB.Flags.Visual_FOVValue or 70,
        Visual_ShowDist        = NMHUB.Flags.Visual_ShowDist ~= false,
        Visual_MaxDist         = NMHUB.Flags.Visual_MaxDist or 500,
        Visual_UpdateRate      = NMHUB.Flags.Visual_UpdateRate or 0.5,
        Visual_MaxObjects      = NMHUB.Flags.Visual_MaxObjects or 100,
        WalkSpeed         = NMHUB.Flags.WalkSpeed or 16,
        JumpPower         = NMHUB.Flags.JumpPower or 50,
        Fly               = NMHUB.Flags.Fly or false,
        Noclip            = NMHUB.Flags.Noclip or false,
        InfiniteJump      = NMHUB.Flags.InfiniteJump or false,
        AntiAFK           = NMHUB.Flags.AntiAFK or false,
        AutoReconnect     = NMHUB.Flags.AutoReconnect or false,
        FPSBoost          = NMHUB.Flags.FPSBoost or false,
        RemoveTextures    = NMHUB.Flags.RemoveTextures or false,
        PerformanceMonitor= NMHUB.Flags.PerformanceMonitor or false,
    }
    local success, err = pcall(function()
        writefile(ConfigFolder .. "/" .. configName .. ".json", HttpService:JSONEncode(config))
    end)
    if success then
        SafeNotify({ Title = "Config Saved", Content = "Config '" .. configName .. "' saved successfully!", Type = "success", Duration = 3 })
        return true
    else
        SafeNotify({ Title = "Save Failed", Content = tostring(err), Type = "error", Duration = 3 })
        return false
    end
end

local function loadConfig(configName)
    if not readfile or not isfile or not HttpService then
        SafeNotify({ Title = "Config Error", Content = "Executor missing readfile function!", Type = "error", Duration = 3 })
        return false
    end
    local filePath = ConfigFolder .. "/" .. configName .. ".json"
    if not isfile(filePath) then
        SafeNotify({ Title = "Load Failed", Content = "Config '" .. configName .. "' not found!", Type = "error", Duration = 3 })
        return false
    end
    local success, result = pcall(function() return HttpService:JSONDecode(readfile(filePath)) end)
    if success and result then
        NMHUB.Flags.Killer_AutoAttack       = result.Killer_AutoAttack       or false
        NMHUB.Flags.Killer_AutoAttackRange  = result.Killer_AutoAttackRange  or 15
        NMHUB.Flags.Killer_BurstAttack      = result.Killer_BurstAttack      or false
        NMHUB.Flags.Killer_HitboxExpand     = result.Killer_HitboxExpand     or false
        NMHUB.Flags.Killer_HitboxSize       = result.Killer_HitboxSize       or 15
        NMHUB.Flags.Killer_InfiniteLunge    = result.Killer_InfiniteLunge    or false
        NMHUB.Flags.Killer_InstantKill      = result.Killer_InstantKill      or false
        NMHUB.Flags.Killer_InstantKillRange = result.Killer_InstantKillRange or 40
        NMHUB.Flags.Killer_DestroyPallets   = result.Killer_DestroyPallets   or false
        NMHUB.Flags.Killer_FullGenBreak     = result.Killer_FullGenBreak     or false
        NMHUB.Flags.Killer_AutoHook         = result.Killer_AutoHook         or false
        NMHUB.Flags.Killer_AntiBlind        = result.Killer_AntiBlind        or false
        NMHUB.Flags.Killer_NoPalletStun     = result.Killer_NoPalletStun     or false
        NMHUB.Flags.Killer_NoSlowdown       = result.Killer_NoSlowdown       or false
        NMHUB.Flags.Surv_AutoSkillCheck = result.Surv_AutoSkillCheck or false
        NMHUB.Flags.Surv_FastRepair     = result.Surv_FastRepair     or false
        NMHUB.Flags.Surv_InstantGen     = result.Surv_InstantGen     or false
        NMHUB.Flags.Surv_AutoParry      = result.Surv_AutoParry      or false
        NMHUB.Flags.Surv_ParryRange     = result.Surv_ParryRange     or 20
        NMHUB.Flags.Surv_AutoWiggle     = result.Surv_AutoWiggle     or false
        NMHUB.Flags.Surv_InstantHeal    = result.Surv_InstantHeal    or false
        NMHUB.Flags.Surv_NoFallDmg      = result.Surv_NoFallDmg      or false
        NMHUB.Flags.Surv_NoSlowdown     = result.Surv_NoSlowdown     or false
        NMHUB.Flags.Surv_FastVault      = result.Surv_FastVault      or false
        NMHUB.Flags.Surv_FleeKiller     = result.Surv_FleeKiller     or false
        NMHUB.Flags.Surv_FleeDist       = result.Surv_FleeDist       or 30
        NMHUB.Flags.Surv_KillerAlert    = result.Surv_KillerAlert    or false
        NMHUB.Flags.Surv_AlertRange     = result.Surv_AlertRange     or 35
        NMHUB.Flags.Surv_AutoEscape     = result.Surv_AutoEscape     or false
        NMHUB.Flags.Visual_KillerESP       = result.Visual_KillerESP or false
        NMHUB.Flags.Visual_SurvivorESP     = result.Visual_SurvivorESP or false
        NMHUB.Flags.Visual_GeneratorESP    = result.Visual_GeneratorESP or false
        NMHUB.Flags.Visual_GateESP         = result.Visual_GateESP or false
        NMHUB.Flags.Visual_HookESP         = result.Visual_HookESP or false
        NMHUB.Flags.Visual_ClosestHookOnly = result.Visual_ClosestHookOnly or false
        NMHUB.Flags.Visual_PalletESP       = result.Visual_PalletESP or false
        NMHUB.Flags.Visual_WindowESP       = result.Visual_WindowESP or false
        NMHUB.Flags.Visual_NoFog           = result.Visual_NoFog or false
        NMHUB.Flags.Visual_Fullbright      = result.Visual_Fullbright or false
        NMHUB.Flags.Visual_CustomFOV       = result.Visual_CustomFOV or false
        NMHUB.Flags.Visual_FOVValue        = result.Visual_FOVValue or 70
        NMHUB.Flags.Visual_ShowDist        = result.Visual_ShowDist ~= false
        NMHUB.Flags.Visual_MaxDist         = result.Visual_MaxDist or 500
        NMHUB.Flags.Visual_UpdateRate      = result.Visual_UpdateRate or 0.5
        NMHUB.Flags.Visual_MaxObjects      = result.Visual_MaxObjects or 100
        NMHUB.Flags.WalkSpeed              = result.WalkSpeed or 16
        NMHUB.Flags.JumpPower              = result.JumpPower or 50
        NMHUB.Flags.Fly                    = result.Fly or false
        NMHUB.Flags.Noclip                 = result.Noclip or false
        NMHUB.Flags.InfiniteJump           = result.InfiniteJump or false
        NMHUB.Flags.AntiAFK                = result.AntiAFK or false
        NMHUB.Flags.AutoReconnect          = result.AutoReconnect or false
        NMHUB.Flags.FPSBoost               = result.FPSBoost or false
        NMHUB.Flags.RemoveTextures         = result.RemoveTextures or false
        NMHUB.Flags.PerformanceMonitor     = result.PerformanceMonitor or false
        syncFeatureBackends()
        SafeNotify({ Title = "Config Loaded", Content = "Config '" .. configName .. "' loaded successfully!", Type = "success", Duration = 3 })
        return true
    else
        SafeNotify({ Title = "Load Failed", Content = "Failed to parse config file!", Type = "error", Duration = 3 })
        return false
    end
end

local function saveAutoLoad(configName)
    if not writefile or not HttpService then return end
    local autoLoadFile = ConfigFolder .. "/autoload.json"
    local data = { autoLoadConfig = configName }
    pcall(function() writefile(autoLoadFile, HttpService:JSONEncode(data)) end)
end

local function getAutoLoad()
    if not readfile or not isfile or not HttpService then return nil end
    local autoLoadFile = ConfigFolder .. "/autoload.json"
    if not isfile(autoLoadFile) then return nil end
    local success, result = pcall(function() return HttpService:JSONDecode(readfile(autoLoadFile)) end)
    if success and result then return result.autoLoadConfig end
    return nil
end

local function clearAutoLoad()
    if not delfile then return end
    local autoLoadFile = ConfigFolder .. "/autoload.json"
    pcall(delfile, autoLoadFile)
end

local ConfigSection = TabConfig:CreateSection({ Title = "Configuration", Opened = true })

ConfigSection:CreateInput({ Id = "CfgNameInput", Title = "Config Name", Placeholder = "Enter config name...", Default = "", Callback = function(Value)
    NMHUB.Flags.ConfigName = Value
end })

local ConfigDropdown = ConfigSection:CreateDropdown({ 
    Id = "CfgSelect", Title = "Select Config", Values = getConfigList(), Default = "", Sidebar = true, 
    Refresh = getConfigList, RefreshInterval = 5, Callback = function(Value)
        NMHUB.Flags.SelectedConfig = Value
    end 
})

ConfigSection:CreateButton({ Id = "BtnCreateCfg", Title = "Create Config", Callback = function()
    local name = NMHUB.Flags.ConfigName
    if not name or name == "" then
        SafeNotify({ Title = "Error", Content = "Please enter a config name!", Type = "error", Duration = 2 })
        return
    end
    if saveConfig(name) then
        if ConfigDropdown and ConfigDropdown.Refresh then ConfigDropdown:Refresh(getConfigList()) end
    end
end })

ConfigSection:CreateButton({ Id = "BtnLoadCfg", Title = "Load Config", Callback = function()
    local name = NMHUB.Flags.SelectedConfig
    if not name or name == "" then
        SafeNotify({ Title = "Error", Content = "Please select a config!", Type = "error", Duration = 2 })
        return
    end
    loadConfig(name)
end })

ConfigSection:CreateButton({ Id = "BtnDeleteCfg", Title = "Delete Config", Callback = function()
    local name = NMHUB.Flags.SelectedConfig
    if not name or name == "" then
        SafeNotify({ Title = "Error", Content = "Please select a config!", Type = "error", Duration = 2 })
        return
    end
    SafeDialog({
        Title = "Confirm Delete",
        Content = "Delete config '" .. name .. "'?",
        Buttons = {
            { Id = "BtnDeleteYes", Title = "Yes, Delete", Callback = function()
                if delfile then
                    pcall(delfile, ConfigFolder .. "/" .. name .. ".json")
                    if ConfigDropdown and ConfigDropdown.Refresh then ConfigDropdown:Refresh(getConfigList()) end
                    SafeNotify({ Title = "Deleted", Content = "Config deleted!", Type = "success", Duration = 2 })
                end
            end },
            { Id = "BtnDeleteNo", Title = "Cancel" },
        }
    })
end })

local AutoLoadSection = TabConfig:CreateSection({ Title = "Auto Load & Auto Save" })

AutoLoadSection:CreateToggle({ Id = "AutoLoadEnabled", Title = "Enable Auto Load", Default = getAutoLoad() ~= nil, Callback = function(Value)
    NMHUB.Flags.AutoLoadEnabled = Value
    if not Value then clearAutoLoad() end
end })

AutoLoadSection:CreateToggle({ Id = "AutoSaveEnabled", Title = "Enable Auto Save", Default = false, Callback = function(Value)
    NMHUB.Flags.AutoSaveEnabled = Value
    if Value then
        SafeNotify({ Title = "Auto Save Enabled", Content = "Settings will be saved automatically!", Type = "success", Duration = 2 })
    end
end })

autoSaveConfig = function()
    if not NMHUB.Flags.AutoSaveEnabled then return end
    local configName = NMHUB.Flags.SelectedConfig or getAutoLoad()
    if not configName or configName == "" then
        configName = "autosave"
    end
    if writefile and HttpService then
        local config = {
            Killer_AutoAttack       = NMHUB.Flags.Killer_AutoAttack       or false,
            Killer_AutoAttackRange  = NMHUB.Flags.Killer_AutoAttackRange  or 15,
            Killer_BurstAttack      = NMHUB.Flags.Killer_BurstAttack      or false,
            Killer_HitboxExpand     = NMHUB.Flags.Killer_HitboxExpand     or false,
            Killer_HitboxSize       = NMHUB.Flags.Killer_HitboxSize       or 15,
            Killer_InfiniteLunge    = NMHUB.Flags.Killer_InfiniteLunge    or false,
            Killer_InstantKill      = NMHUB.Flags.Killer_InstantKill      or false,
            Killer_InstantKillRange = NMHUB.Flags.Killer_InstantKillRange or 40,
            Killer_DestroyPallets   = NMHUB.Flags.Killer_DestroyPallets   or false,
            Killer_FullGenBreak     = NMHUB.Flags.Killer_FullGenBreak     or false,
            Killer_AutoHook         = NMHUB.Flags.Killer_AutoHook         or false,
            Killer_AntiBlind        = NMHUB.Flags.Killer_AntiBlind        or false,
            Killer_NoPalletStun     = NMHUB.Flags.Killer_NoPalletStun     or false,
            Killer_NoSlowdown       = NMHUB.Flags.Killer_NoSlowdown       or false,
            Surv_AutoSkillCheck = NMHUB.Flags.Surv_AutoSkillCheck or false,
            Surv_FastRepair     = NMHUB.Flags.Surv_FastRepair     or false,
            Surv_InstantGen     = NMHUB.Flags.Surv_InstantGen     or false,
            Surv_AutoParry      = NMHUB.Flags.Surv_AutoParry      or false,
            Surv_ParryRange     = NMHUB.Flags.Surv_ParryRange     or 20,
            Surv_AutoWiggle     = NMHUB.Flags.Surv_AutoWiggle     or false,
            Surv_InstantHeal    = NMHUB.Flags.Surv_InstantHeal    or false,
            Surv_NoFallDmg      = NMHUB.Flags.Surv_NoFallDmg      or false,
            Surv_NoSlowdown     = NMHUB.Flags.Surv_NoSlowdown     or false,
            Surv_FastVault      = NMHUB.Flags.Surv_FastVault      or false,
            Surv_FleeKiller     = NMHUB.Flags.Surv_FleeKiller     or false,
            Surv_FleeDist       = NMHUB.Flags.Surv_FleeDist       or 30,
            Surv_KillerAlert    = NMHUB.Flags.Surv_KillerAlert    or false,
            Surv_AlertRange     = NMHUB.Flags.Surv_AlertRange     or 35,
            Surv_AutoEscape     = NMHUB.Flags.Surv_AutoEscape     or false,
            Visual_KillerESP       = NMHUB.Flags.Visual_KillerESP or false,
            Visual_SurvivorESP     = NMHUB.Flags.Visual_SurvivorESP or false,
            Visual_GeneratorESP    = NMHUB.Flags.Visual_GeneratorESP or false,
            Visual_GateESP         = NMHUB.Flags.Visual_GateESP or false,
            Visual_HookESP         = NMHUB.Flags.Visual_HookESP or false,
            Visual_ClosestHookOnly = NMHUB.Flags.Visual_ClosestHookOnly or false,
            Visual_PalletESP       = NMHUB.Flags.Visual_PalletESP or false,
            Visual_WindowESP       = NMHUB.Flags.Visual_WindowESP or false,
            Visual_NoFog           = NMHUB.Flags.Visual_NoFog or false,
            Visual_Fullbright      = NMHUB.Flags.Visual_Fullbright or false,
            Visual_CustomFOV       = NMHUB.Flags.Visual_CustomFOV or false,
            Visual_FOVValue        = NMHUB.Flags.Visual_FOVValue or 70,
            Visual_ShowDist        = NMHUB.Flags.Visual_ShowDist ~= false,
            Visual_MaxDist         = NMHUB.Flags.Visual_MaxDist or 500,
            Visual_UpdateRate      = NMHUB.Flags.Visual_UpdateRate or 0.5,
            Visual_MaxObjects      = NMHUB.Flags.Visual_MaxObjects or 100,
            WalkSpeed         = NMHUB.Flags.WalkSpeed or 16,
            JumpPower         = NMHUB.Flags.JumpPower or 50,
            Fly               = NMHUB.Flags.Fly or false,
            Noclip            = NMHUB.Flags.Noclip or false,
            InfiniteJump      = NMHUB.Flags.InfiniteJump or false,
            AntiAFK           = NMHUB.Flags.AntiAFK or false,
            AutoReconnect     = NMHUB.Flags.AutoReconnect or false,
            FPSBoost          = NMHUB.Flags.FPSBoost or false,
            RemoveTextures    = NMHUB.Flags.RemoveTextures or false,
            PerformanceMonitor= NMHUB.Flags.PerformanceMonitor or false,
        }
        pcall(function() writefile(ConfigFolder .. "/" .. configName .. ".json", HttpService:JSONEncode(config)) end)
    end
end

AutoLoadSection:CreateButton({ Id = "BtnSetAuto", Title = "Set as Auto Load", Callback = function()
    local name = NMHUB.Flags.SelectedConfig
    if not name or name == "" then
        SafeNotify({ Title = "Error", Content = "Please select a config first!", Type = "error", Duration = 2 })
        return
    end
    saveAutoLoad(name)
    SafeNotify({ Title = "Auto Load Set", Content = "Config '" .. name .. "' will load on startup!", Type = "success", Duration = 3 })
end })

AutoLoadSection:CreateButton({ Id = "BtnClearAuto", Title = "Clear Auto Load", Callback = function()
    clearAutoLoad()
    SafeNotify({ Title = "Auto Load Cleared", Content = "No config will auto-load on startup.", Type = "info", Duration = 2 })
end })

NMHUB.Loops.AutoLoadTask = task.spawn(function()
    task.wait(0.5)
    if _G.NOMERCY_Shutdown then return end
    local autoLoadConfigName = getAutoLoad()
    if autoLoadConfigName and NMHUB.Flags.AutoLoadEnabled ~= false then
        print("[King Vypers] Auto-loading config: " .. autoLoadConfigName)
        loadConfig(autoLoadConfigName)
    end
    NMHUB.Loops.AutoLoadTask = nil
end)

end -- ===== END CONFIG TAB =====

-- ===== SHUTDOWN HANDLER =====
_G.NOMERCY_ShutdownHandler = function()
    if NMHUB._ShuttingDown then return end
    NMHUB._ShuttingDown = true
    print("[King Vypers] Shutdown initiated...")
    _G.NOMERCY_Shutdown = true
    
    pcall(function()
        if LP.Character and LP.Character:FindFirstChild("Humanoid") then
            LP.Character.Humanoid.WalkSpeed = NMHUB.OriginalState.WalkSpeed or 16
            LP.Character.Humanoid.JumpPower = NMHUB.OriginalState.JumpPower or 50
        end
        if NMHUB.Flags.Noclip then
            local char = LP.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and NMHUB.OriginalState.CanCollide[part] ~= nil then
                        part.CanCollide = NMHUB.OriginalState.CanCollide[part]
                    end
                end
            end
        end
        if NMHUB.Flags.FPSBoost then
            local Lighting = game:GetService("Lighting")
            local Terrain = workspace.Terrain
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            if NMHUB.OriginalState.Lighting.Stored then
                Lighting.GlobalShadows = NMHUB.OriginalState.Lighting.GlobalShadows
                Lighting.FogEnd = NMHUB.OriginalState.Lighting.FogEnd
                Terrain.WaterWaveSize = NMHUB.OriginalState.Terrain.WaterWaveSize
                Terrain.WaterWaveSpeed = NMHUB.OriginalState.Terrain.WaterWaveSpeed
                Terrain.WaterReflectance = NMHUB.OriginalState.Terrain.WaterReflectance
                Terrain.WaterTransparency = NMHUB.OriginalState.Terrain.WaterTransparency
            end
        end
        if NMHUB.Flags.RemoveTextures then
            for _, obj in pairs(workspace:GetDescendants()) do
                if (obj:IsA("Decal") or obj:IsA("Texture")) and NMHUB.OriginalState.Textures[obj] ~= nil then
                    obj.Transparency = NMHUB.OriginalState.Textures[obj]
                elseif (obj:IsA("ParticleEmitter") or obj:IsA("Trail")) and NMHUB.OriginalState.Textures[obj] ~= nil then
                    obj.Enabled = NMHUB.OriginalState.Textures[obj]
                end
            end
        end
    end)

    pcall(function()
        for _, entry in ipairs(NMHUB.HookedRemotes) do
            if entry.remote and entry.old then
                pcall(hookfunction, entry.remote.FireServer, entry.old)
            end
        end
        table.clear(NMHUB.HookedRemotes)
        if NMHUB.Connections.OldKick then
            pcall(hookfunction, LP.Kick, NMHUB.Connections.OldKick)
            NMHUB.Connections.OldKick = nil
        end
        if NMHUB.Connections.OldTeleport then
            pcall(hookfunction, TeleportService.Teleport, NMHUB.Connections.OldTeleport)
            NMHUB.Connections.OldTeleport = nil
        end
        if NMHUB.Connections.OldTeleportInstance then
            pcall(hookfunction, TeleportService.TeleportToPlaceInstance, NMHUB.Connections.OldTeleportInstance)
            NMHUB.Connections.OldTeleportInstance = nil
        end
    end)

    pcall(function() stopKillerDispatcher() end)
    pcall(function() removeHitboxExpand() end)
    pcall(function() stopNoPalletStunWatchdog() end)
    pcall(function() stopAutoSkillCheck() end)
    pcall(function() stopFastRepair()     end)
    pcall(function() stopInstantGen()     end)
    pcall(function() stopAutoParry()      end)
    pcall(function() stopAutoWiggle()     end)
    pcall(function() stopInstantHeal()    end)
    pcall(function() stopNoFallDmg()      end)
    pcall(function() stopFastVault()      end)
    pcall(function() stopFleeKiller()     end)
    pcall(function() stopKillerAlert()    end)
    pcall(function() stopAutoEscape()     end)
    pcall(function() stopSurvDispatcher() end)
    pcall(function()
        if _scHookConn then
            _scHookConn:Disconnect()
            _scHookConn = nil
            NMHUB.Connections.SC_HookConn = nil
        end
        _scActiveGen = nil; _scActivePoint = nil
    end)
    pcall(function()
        if _healScHookConn then
            _healScHookConn:Disconnect()
            _healScHookConn = nil
            NMHUB.Connections.Heal_SC_HookConn = nil
        end
    end)
    pcall(function()
        if NMHUB.Connections.AimbotConn then
            NMHUB.Connections.AimbotConn:Disconnect()
            NMHUB.Connections.AimbotConn = nil
        end
        local fc = NMHUB.GuiElements.AimbotFovCircle
        if fc then fc:Remove() end
        NMHUB.GuiElements.AimbotFovCircle = nil
    end)
    pcall(function()
        if _autoCancelConn then
            _autoCancelConn:Disconnect()
            _autoCancelConn = nil
            NMHUB.Connections.AutoCancelGen = nil
        end
    end)

    pcall(function() _visualStopESP() end)
    pcall(function() _visualRestoreFog() end)
    pcall(function() _visualRestoreFb() end)
    pcall(function() _visualRestoreFOV() end)

    for name, _ in pairs(NMHUB.Loops) do NMHUB:StopLoop(name) end
    for name, _ in pairs(NMHUB.Connections) do NMHUB:Disconnect(name) end
    
    pcall(function()
        if NMHUB.GuiElements.FlyVelocity then NMHUB.GuiElements.FlyVelocity:Destroy(); NMHUB.GuiElements.FlyVelocity = nil end
        if NMHUB.GuiElements.FlyGyro then NMHUB.GuiElements.FlyGyro:Destroy(); NMHUB.GuiElements.FlyGyro = nil end
        local ch = LP.Character
        local hm = ch and ch:FindFirstChildOfClass("Humanoid")
        if hm then hm.PlatformStand = false end
    end)
    pcall(function()
        if NMHUB.GuiElements.ToggleGui then NMHUB.GuiElements.ToggleGui:Destroy() end
    end)
    pcall(function()
        if NMHUB.GuiElements.MobileUI then NMHUB.GuiElements.MobileUI:Destroy() end
        if NMHUB.GuiElements.MobileAimGui then NMHUB.GuiElements.MobileAimGui:Destroy() end
        if NMHUB.GuiElements.MobileFOVGui then NMHUB.GuiElements.MobileFOVGui:Destroy() end
        NMHUB.GuiElements.MobileUI = nil
        NMHUB.GuiElements.MobileAimGui = nil
        NMHUB.GuiElements.MobileFOVGui = nil
        NMHUB.GuiElements.MobileFOVFrame = nil
        NMHUB.GuiElements.MobileFOVStroke = nil
    end)
    
    pcall(function()
        if Window and Window.Destroy then Window:Destroy() end
    end)
    pcall(function()
        if Vypers and Vypers.Destroy then Vypers:Destroy() end
    end)
    
    if _G.NMHUB == NMHUB then _G.NMHUB = nil end
    _G.NOMERCY_ViolenceDistrict_Loaded = nil
    _G.NOMERCY_ShutdownHandler = nil
    print("[King Vypers] Shutdown complete")
end

-- ===== MOBILE UI SYSTEM =====
local _MobileGui = { RadarFrame = nil, RadarDots = {}, RadarObjDots = {}, AimBtn = nil }

local function _CreateMobileUI()
    if not isMobile then return end
    local pg = LP:FindFirstChild("PlayerGui") or CoreGui
    if not pg then return end

    local sg = Instance.new("ScreenGui")
    sg.Name = "MobileUI"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 100; sg.Parent = pg
    NMHUB.GuiElements.MobileUI = sg

    local RS = 130
    local radarF = Instance.new("Frame")
    radarF.Name = "Radar"
    radarF.Size = UDim2.new(0, RS, 0, RS)
    radarF.Position = UDim2.new(0, 20, 0, 120)
    radarF.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    radarF.BackgroundTransparency = 0.3
    radarF.BorderSizePixel = 0; radarF.Visible = false; radarF.Parent = sg
    Instance.new("UICorner", radarF).CornerRadius = UDim.new(0, 8)
    local rStroke = Instance.new("UIStroke")
    rStroke.Color = Color3.fromRGB(120, 90, 240); rStroke.Thickness = 2; rStroke.Parent = radarF
    local ch = Instance.new("Frame")
    ch.Size = UDim2.new(1, -20, 0, 1); ch.Position = UDim2.new(0, 10, 0.5, 0)
    ch.BackgroundColor3 = Color3.fromRGB(45, 45, 45); ch.BorderSizePixel = 0; ch.Parent = radarF
    local cv = Instance.new("Frame")
    cv.Size = UDim2.new(0, 1, 1, -20); cv.Position = UDim2.new(0.5, 0, 0, 10)
    cv.BackgroundColor3 = Color3.fromRGB(45, 45, 45); cv.BorderSizePixel = 0; cv.Parent = radarF
    local cdot = Instance.new("Frame")
    cdot.Size = UDim2.new(0, 10, 0, 10); cdot.Position = UDim2.new(0.5, -5, 0.5, -5)
    cdot.BackgroundColor3 = Color3.fromRGB(120, 90, 240); cdot.BorderSizePixel = 0
    cdot.ZIndex = 5; cdot.Parent = radarF
    Instance.new("UICorner", cdot).CornerRadius = UDim.new(1, 0)
    _MobileGui.RadarFrame = radarF

    for i = 1, 20 do
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0, 8, 0, 8)
        d.BackgroundColor3 = Color3.fromRGB(255, 65, 65)
        d.BorderSizePixel = 0; d.ZIndex = 4; d.Visible = false; d.Parent = radarF
        Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
        _MobileGui.RadarDots[i] = d
    end
    for i = 1, 30 do
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0, 6, 0, 6)
        d.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
        d.BorderSizePixel = 0; d.ZIndex = 3; d.Visible = false; d.Parent = radarF
        Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
        _MobileGui.RadarObjDots[i] = d
    end

    local aimSG = Instance.new("ScreenGui")
    aimSG.Name = "AimBtn"; aimSG.ResetOnSpawn = false
    aimSG.IgnoreGuiInset = true
    aimSG.ZIndexBehavior = Enum.ZIndexBehavior.AlwaysOnTop
    aimSG.Parent = pg
    NMHUB.GuiElements.MobileAimGui = aimSG

    local btn = Instance.new("TextButton")
    btn.Name = "AimHold"
    btn.Size = UDim2.new(0, 75, 0, 75)
    btn.Position = UDim2.new(1, -95, 1, -170)
    btn.BackgroundColor3 = Color3.fromRGB(200, 55, 55)
    btn.BackgroundTransparency = 0.2
    btn.Text = "🎯\nAIM"; btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 14; btn.Font = Enum.Font.GothamBold
    btn.Visible = false; btn.ZIndex = 20; btn.Parent = aimSG
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local aStk = Instance.new("UIStroke")
    aStk.Color = Color3.fromRGB(255, 100, 100); aStk.Thickness = 2; aStk.Parent = btn

    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            _aimbotHolding = true
            btn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
            aStk.Color = Color3.fromRGB(50, 230, 80)
        end
    end)
    btn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            _aimbotHolding = false
            btn.BackgroundColor3 = Color3.fromRGB(200, 55, 55)
            aStk.Color = Color3.fromRGB(255, 100, 100)
        end
    end)
    _MobileGui.AimBtn = btn
end

local function _UpdateMobileRadar()
    if not _MobileGui.RadarFrame then return end
    local showRadar = NMHUB.Flags.Visual_PlayerESP
        or NMHUB.Flags.Visual_GeneratorESP
        or NMHUB.Flags.Visual_GateESP
    if not showRadar then _MobileGui.RadarFrame.Visible = false; return end
    _MobileGui.RadarFrame.Visible = true

    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local cam = workspace.CurrentCamera
    if not cam then return end

    local myAngle = -math.atan2(cam.CFrame.LookVector.X, cam.CFrame.LookVector.Z)
    local cosA, sinA = math.cos(myAngle), math.sin(myAngle)
    local RS = 130
    local half = RS / 2
    local scale = (half - 10) / 150
    local maxD = half - 8

    local function worldToRadar(px, pz)
        local dx = (px - myRoot.Position.X) * scale
        local dz = (pz - myRoot.Position.Z) * scale
        local rx = dx * cosA - dz * sinA
        local ry = dx * sinA + dz * cosA
        local dist = math.sqrt(rx*rx + ry*ry)
        if dist > maxD then
            local s = maxD / dist
            rx, ry = rx * s, ry * s
        end
        return Vector2.new(half + rx, half + ry)
    end

    local idx = 1
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and idx <= #_MobileGui.RadarDots then
            local pr = player.Character:FindFirstChild("HumanoidRootPart")
            if pr then
                local isK = player.Team and player.Team.Name == "Killer"
                local isS = player.Team and player.Team.Name == "Survivors"
                if isK or isS then
                    local p = worldToRadar(pr.Position.X, pr.Position.Z)
                    local d = _MobileGui.RadarDots[idx]
                    d.BackgroundColor3 = isK and Color3.fromRGB(255, 65, 65) or Color3.fromRGB(65, 220, 130)
                    d.Position = UDim2.new(0, p.X - 4, 0, p.Y - 4)
                    d.Visible = true; idx = idx + 1
                end
            end
        end
    end
    for i = idx, #_MobileGui.RadarDots do _MobileGui.RadarDots[i].Visible = false end

    local objIdx = 1
    if NMHUB.Flags.Visual_GeneratorESP then
        for _, gp in ipairs(CollectionService:GetTagged("GeneratorPoint")) do
            if gp:IsA("BasePart") and objIdx <= #_MobileGui.RadarObjDots then
                local p = worldToRadar(gp.Position.X, gp.Position.Z)
                local d = _MobileGui.RadarObjDots[objIdx]
                d.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
                d.Position = UDim2.new(0, p.X - 3, 0, p.Y - 3)
                d.Visible = true; objIdx = objIdx + 1
            end
        end
    end
    for i = objIdx, #_MobileGui.RadarObjDots do _MobileGui.RadarObjDots[i].Visible = false end
end

task.spawn(function()
    task.wait(2)
    if _G.NOMERCY_Shutdown then return end
    pcall(_CreateMobileUI)
    if isMobile then
        NMHUB.Connections.MobileUIHeartbeat = RunService.Heartbeat:Connect(function()
            if _G.NOMERCY_Shutdown then return end
            pcall(_UpdateMobileRadar)
            if _MobileGui.AimBtn then
                _MobileGui.AimBtn.Visible = NMHUB.Flags.Aimbot_Enabled or false
            end
        end)
    end
end)

-- ===== ENABLE CONFIG & FINAL NOTIFICATION =====
pcall(function() if Vypers.EnableConfig then Vypers:EnableConfig("default") end end)

NMHUB.Loops.FinalNotificationTask = task.spawn(function()
    task.wait(1)
    if _G.NOMERCY_Shutdown then return end
    SafeNotify({
        Title = "King Vypers",
        Content = "Violence District v" .. VERSION .. " loaded successfully!",
        Type = "success",
        Duration = 5
    })
    NMHUB.Loops.FinalNotificationTask = nil
    print("[King Vypers] Violence District v" .. VERSION .. " Loaded!")
end)