
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ============================================================================
-- WIND UI — PROJECTSION DDS
-- ============================================================================

local LP = game:GetService("Players").LocalPlayer

local Window = WindUI:CreateWindow({
    Title      = "Projectsion DDS",
    SubTitle   = "by Projectsion",
    TabWidth   = 160,
    Size       = UDim2.fromOffset(580, 460),
    Acrylic    = false,
    Theme      = "Dark",
    Background = "rbxassetid://3293972833",
})

-- Background fallback injection
task.spawn(function()
    task.wait(0.5)
    local function tryInjectBG(gui)
        if not gui then return end
        local mainFrame = gui:FindFirstChildOfClass("Frame")
        if not mainFrame then return end
        if mainFrame:FindFirstChild("DDS_Background") then return end
        local bg = Instance.new("ImageLabel")
        bg.Name               = "DDS_Background"
        bg.Image              = "rbxassetid://3293972833"
        bg.Size               = UDim2.new(1, 0, 1, 0)
        bg.Position           = UDim2.new(0, 0, 0, 0)
        bg.ZIndex             = 0
        bg.BackgroundTransparency = 1
        bg.ImageTransparency  = 0.35
        bg.ScaleType          = Enum.ScaleType.Crop
        bg.Parent             = mainFrame
    end
    for _, gui in ipairs(LP.PlayerGui:GetChildren()) do
        if gui.Name:lower():find("wind") then tryInjectBG(gui) end
    end
    for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if gui.Name:lower():find("wind") then tryInjectBG(gui) end
    end
end)

-- ============================================================================
-- ADONIS BYPASS
-- ============================================================================

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

-- ============================================================================
-- TABS
-- ============================================================================

-- ── Courier tab ───────────────────────────────────────────────────────────────
local TabCourier = Window:CreateTab("Courier", "package")

TabCourier:CreateToggle({
    Name     = "Auto Courier",
    Default  = false,
    Callback = function(v)
        _G.AutofarmCourier = v
        updateBlackScreen()
    end,
})
TabCourier:CreateSlider({
    Name      = "Speed Min",
    Range     = {50, 500},
    Increment = 10,
    Default   = 150,
    Callback  = function(v) _G.CourierSpeedMin = v end,
})
TabCourier:CreateSlider({
    Name      = "Speed Max",
    Range     = {50, 600},
    Increment = 10,
    Default   = 330,
    Callback  = function(v) _G.CourierSpeedMax = v end,
})

-- ── Barista tab ───────────────────────────────────────────────────────────────
local TabBarista = Window:CreateTab("Barista", "coffee")

TabBarista:CreateToggle({
    Name     = "Auto Barista",
    Default  = false,
    Callback = function(v)
        _G.AutoFarmBarista = v
        updateBlackScreen()
        if v then LastActivity = 0 end
    end,
})
TabBarista:CreateSlider({
    Name      = "Speed Min",
    Range     = {50, 500},
    Increment = 10,
    Default   = 200,
    Callback  = function(v) _G.BaristaSpeedMin = v end,
})
TabBarista:CreateSlider({
    Name      = "Speed Max",
    Range     = {50, 600},
    Increment = 10,
    Default   = 380,
    Callback  = function(v) _G.BaristaSpeedMax = v end,
})

-- ── Police tab ────────────────────────────────────────────────────────────────
local TabPolice = Window:CreateTab("Police", "shield")

TabPolice:CreateToggle({
    Name     = "Auto Police",
    Default  = false,
    Callback = function(v)
        _G.AutoPoliceEnabled = v
        updateBlackScreen()
        if v and not (LP.Team and LP.Team.Name == "Police") then
            task.spawn(RequestPoliceJob)
        end
    end,
})
TabPolice:CreateSlider({
    Name      = "Teleport Speed Min",
    Range     = {100, 400},
    Increment = 10,
    Default   = 200,
    Callback  = function(v) AutoPoliceConfig.TeleportSpeed.min = v end,
})
TabPolice:CreateSlider({
    Name      = "Teleport Speed Max",
    Range     = {100, 500},
    Increment = 10,
    Default   = 300,
    Callback  = function(v) AutoPoliceConfig.TeleportSpeed.max = v end,
})

-- ── RideGO tab ────────────────────────────────────────────────────────────────
local TabRideGO = Window:CreateTab("RideGO", "car")

TabRideGO:CreateButton({
    Name     = "Start RideGO",
    Callback = function() StartRideGO() end,
})
TabRideGO:CreateButton({
    Name     = "Stop RideGO",
    Callback = function() StopRideGO() end,
})
TabRideGO:CreateSlider({
    Name      = "Speed Min",
    Range     = {30, 150},
    Increment = 5,
    Default   = 70,
    Callback  = function(v) rgState.MinSpeed = v end,
})
TabRideGO:CreateSlider({
    Name      = "Speed Max",
    Range     = {30, 200},
    Increment = 5,
    Default   = 95,
    Callback  = function(v) rgState.MaxSpeed = v end,
})

-- FIX: guard against empty vehicle list; run after rgState is populated
task.spawn(function()
    task.wait(3)
    local vehicles = rgState and rgState.OwnedVehicles
    if not vehicles or #vehicles == 0 then
        warn("[projectsion] RideGO: no owned vehicles found, skipping dropdown")
        return
    end
    TabRideGO:CreateDropdown({
        Name     = "Vehicle",
        Options  = vehicles,
        Default  = vehicles[1],
        Callback = function(v) rgState.SelectedCar = v end,
    })
end)

-- ── Settings tab ──────────────────────────────────────────────────────────────
local TabSettings = Window:CreateTab("Settings", "settings")

TabSettings:CreateInput({
    Name        = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback    = function(v) _G.WebhookURL = v end,
})
TabSettings:CreateToggle({
    Name     = "Auto Webhook",
    Default  = false,
    Callback = function(v) _G.AutoWebhook = v end,
})
TabSettings:CreateButton({
    Name     = "Rejoin Server",
    Callback = function() RejoinServer() end,
})

-- ── Stats tab ─────────────────────────────────────────────────────────────────
local TabStats = Window:CreateTab("Stats", "bar-chart-2")

local statDefs = {
    { key = "TotalEarning",  label = "Total Earned" },
    { key = "CourierEarned", label = "Courier"      },
    { key = "BaristaEarned", label = "Barista"      },
    { key = "PoliceEarned",  label = "Police"       },
    { key = "RideGOEarned",  label = "RideGO"       },
}

local statElements = {}
for _, def in ipairs(statDefs) do
    local el = TabStats:CreateLabel(def.label .. ": " .. formatRP(_G[def.key] or 0))
    statElements[def.key] = { el = el, label = def.label }
end

TabStats:CreateButton({
    Name     = "Refresh",
    Callback = function()
        for key, data in pairs(statElements) do
            -- FIX: surface Set errors instead of silently swallowing them
            local ok, err = pcall(function()
                data.el:Set(data.label .. ": " .. formatRP(_G[key] or 0)
                    .. "  |  " .. getRunningTimeWall())
            end)
            if not ok then
                warn("[projectsion] Stats refresh failed for " .. key .. ": " .. tostring(err))
            end
        end
    end,
})

task.spawn(function()
    while task.wait(5) do
        for key, data in pairs(statElements) do
            local ok, err = pcall(function()
                data.el:Set(data.label .. ": " .. formatRP(_G[key] or 0))
            end)
            if not ok then
                warn("[projectsion] Stats autoupdate failed for " .. key .. ": " .. tostring(err))
            end
        end
    end
end)

warn("[PROJECTSION DDS] Loaded.")