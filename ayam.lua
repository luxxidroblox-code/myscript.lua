local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/projectsionloader.lua'))()

-- ─── Services ────────────────────────────────────────────────────────────────
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local VirtualUser        = game:GetService("VirtualUser")
local lp                = Players.LocalPlayer

-- ─── Anti-idle ───────────────────────────────────────────────────────────────
for _, c in getconnections(lp.Idled) do pcall(c.Disable, c) pcall(c.Disconnect, c) end
lp.Idled:Connect(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.zero) end)

-- ─── Globals ─────────────────────────────────────────────────────────────────
_G.Autofarm           = false
_G.AutoWebhook        = false
_G.WebhookURL         = _G.WebhookURL         or ""
_G.StartTime          = _G.StartTime          or os.time()
_G.CycleCount         = _G.CycleCount         or 0
_G.TotalEarning       = _G.TotalEarning       or 0
_G.TotalTeleportCount = _G.TotalTeleportCount or 0

-- ─── DX-SR engine state ──────────────────────────────────────────────────────
local farmActive      = false
local sessionStart    = nil
local sessionMoneyStart = 0
local totalEarning    = 0
local totalJobs       = 0
local lastCycleEarned = 0
local earnLog         = {}          -- { earned, duration } rolling 6
local estIPH          = 0
local jobDelay        = 50          -- slider-controlled, seconds
local webhookMsgId    = nil
local webhookURL      = ""
local webhookEnabled  = false

-- DX-SR uses TruckArea require for destination index
-- *require may fail on some executors — pcall-wrapped*
local TruckArea
pcall(function() TruckArea = require(ReplicatedStorage.Shared.TruckArea) end)

local DataReplication
pcall(function() DataReplication = require(ReplicatedStorage.Services.DataReplication) end)

-- ─── Kill prop on load (kept from Projectsion) ───────────────────────────────
pcall(function()
    local p = Workspace.Map.Prop:GetChildren()[1627]
    if p then p:Destroy() end
end)

-- ─── Map destruction (DX-SR style: nuke whole Map model) ─────────────────────
local mapDeleted = false
local function deleteMap()
    if mapDeleted then return end
    mapDeleted = true
    local map = Workspace:FindFirstChild("Map")
    if map then pcall(function() map:Destroy() end) end
end

-- ─── Anti-join kick ──────────────────────────────────────────────────────────
local STAFF_GROUP_ID = 10884667
local function isStaff(player)
    local ok, r = pcall(function() return player:IsInGroup(STAFF_GROUP_ID) end)
    return ok and r
end
local function selfKick(player)
    local tag = isStaff(player) and "STAFF" or "PLAYER"
    lp:Kick(tag .. " DETECTED (" .. player.Name .. ") — kacung semua tu")
end
Players.PlayerAdded:Connect(function(p) if p ~= lp then task.wait(0.5) selfKick(p) end end)
task.spawn(function()
    while true do
        task.wait(3)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then selfKick(p) return end
        end
    end
end)

-- ─── Money readers ───────────────────────────────────────────────────────────
-- *DataReplication path preferred; GUI scrape as fallback*
local function getMoneyDR()
    local v = 0
    pcall(function()
        if DataReplication then
            if DataReplication.GetCash then v = DataReplication:GetCash()
            elseif DataReplication.GetData then v = DataReplication:GetData().Cash end
        end
    end)
    return v
end

local function getCleanMoney()
    local v = 0
    pcall(function()
        local tl = lp.PlayerGui.Main.Container.Hub.CashFrame.Frame.TextLabel
        v = tonumber(tl.Text:gsub("[^%d]", "")) or 0
    end)
    if v == 0 then v = getMoneyDR() end
    return v
end

-- ─── Format helpers ──────────────────────────────────────────────────────────
local function formatRP(n)
    local s = tostring(math.floor(n or 0))
    while true do
        local out, c = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
        s = out
        if c == 0 then break end
    end
    return "Rp " .. s
end

local function formatIPH(n)
    n = math.floor(n or 0)
    local b = n / 1e9
    if b >= 0.1 then return string.format("%s (~%.2fM/hr)", formatRP(n), b)
    else return string.format("%s (~%.1fJt/hr)", formatRP(n), n / 1e6) end
end

local function formatDuration(sec)
    sec = math.max(0, math.floor(sec))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%02d:%02d:%02d", h, m, s)
    else return string.format("%02d:%02d", m, s) end
end

-- ─── Destination lookup via TruckArea (DX-SR) ────────────────────────────────
-- *TruckArea[i].Location is Vector3; index 4 = Malang in known CDIDconfigs*
local TARGET_AREA_IDX = 4   -- Malang
local arrowCount  = 0
local arrowTarget = nil     -- Vector3

local networkContainer = ReplicatedStorage:WaitForChild("NetworkContainer", 5)
local jobRemote = networkContainer
    and networkContainer:FindFirstChild("RemoteEvents")
    and networkContainer.RemoteEvents:FindFirstChild("Job")

if jobRemote then
    jobRemote.OnClientEvent:Connect(function(cmd, val)
        if cmd == "SetArrow" and typeof(val) == "Vector3" then
            arrowCount  = arrowCount + 1
            arrowTarget = val
        elseif cmd == "Cleanup" then
            arrowCount  = 0
            arrowTarget = nil
        end
    end)
end

local function getAreaIndex(pos)
    if not TruckArea or not pos then return nil end
    for i, area in ipairs(TruckArea) do
        if (pos - area.Location).Magnitude < 50 then return i end
    end
    return nil
end

-- ─── Vehicle helpers (DX-SR style) ───────────────────────────────────────────
local function getMyTruck()
    local veh = Workspace:FindFirstChild("Vehicles")
    if not veh then return nil end
    for _, v in ipairs(veh:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("DriveSeat") then return v end
    end
end

local function firePrompt(p)
    if not p then return end
    p.Enabled = true
    if fireproximityprompt then pcall(fireproximityprompt, p)
    else p:InputHoldBegin() task.wait(p.HoldDuration + 0.1) p:InputHoldEnd() end
end

local function teleportHRP(cf)
    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cf
    end
end

-- ─── Spawner path ────────────────────────────────────────────────────────────
local SPAWNER_POS  = Vector3.new(35161.36, 139, -54683.41)
local MALANG_POS   = CFrame.new(-7845, 386, 46865)
local SURABAYA_CF  = CFrame.new(34938, 135, -54576)

local function getStarterPrompt()
    local etc = Workspace:FindFirstChild("Etc")
    local truck = etc and etc:FindFirstChild("Job") and etc.Job:FindFirstChild("Truck")
    local starter = truck and truck:FindFirstChild("Starter")
    if starter then
        return starter:FindFirstChild("Prompt", true)
            or starter:FindFirstChildWhichIsA("ProximityPrompt", true)
    end
end

-- ─── UI base piping ──────────────────────────────────────────────────────────
-- Hide Job ScreenGui and MapFrame the DX-SR way
pcall(function()
    local pg = lp:WaitForChild("PlayerGui", 5)
    if not pg then return end
    local function hideGui(g)
        if g and g:IsA("ScreenGui") then
            g.Enabled = false
            g:GetPropertyChangedSignal("Enabled"):Connect(function()
                if g.Enabled then g.Enabled = false end
            end)
        end
    end
    local function hideFrame(f)
        if f then
            f.Visible = false
            f:GetPropertyChangedSignal("Visible"):Connect(function()
                if f.Visible then f.Visible = false end
            end)
        end
    end
    local jobGui = pg:FindFirstChild("Job")
    if jobGui then hideGui(jobGui) end
    pg.ChildAdded:Connect(function(c) if c.Name == "Job" then hideGui(c) end end)
    task.spawn(function()
        local main = pg:WaitForChild("Main", 5)
        local hub  = main and main:WaitForChild("Container", 5)
        hub = hub and hub:WaitForChild("Hub", 5)
        local mf = hub and (hub:FindFirstChild("MapFrame") or hub:WaitForChild("MapFrame", 5))
        if mf then hideFrame(mf) end
    end)
end)

-- ─── Labels (wired after Window is built) ────────────────────────────────────
local LblStatus, LblElapsed, LblCurrentMoney
local LblTotalEarning, LblIPH, LblLastCycle
local LblTeleports, LblSessionTime, LblSessionEarned, LblSessionIPH

-- ─── Webhook ─────────────────────────────────────────────────────────────────
local webhookPinnedId = nil

local function httpReq(url, method, body)
    local fn = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not fn then return nil end
    local ok, res = pcall(fn, {
        Url     = url,
        Method  = method,
        Headers = { ["Content-Type"] = "application/json" },
        Body    = body,
    })
    return ok and res or nil
end

local function buildEmbed(title, color)
    local elapsed = sessionStart and (os.clock() - sessionStart) or 0
    return {
        title  = title,
        color  = color,
        fields = {
            { name = "Total Earning",  value = "```" .. formatRP(totalEarning)    .. "```", inline = true  },
            { name = "Jobs Done",      value = "```" .. tostring(totalJobs)       .. " Delivered```", inline = true },
            { name = "Earning / Hour", value = "```" .. formatIPH(estIPH)         .. "```", inline = false },
            { name = "Current Money",  value = "```" .. formatRP(getCleanMoney()) .. "```", inline = true  },
            { name = "Uptime",         value = "```" .. formatDuration(elapsed)   .. "```", inline = true  },
            { name = "Status",         value = "```" .. (farmActive and "Running" or "Idle") .. "```", inline = true },
        },
        thumbnail = { url = "https://tr.rbxcdn.com/180DAY-89e12785eed48e4b6cf7b03cd0cff336/150/150/Image/Webp/noFilter" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer    = { text = "Projectsion × DX-SR | CDIDTruck" },
    }
end

local function sendOrPatchWebhook()
    if not webhookEnabled or webhookURL == "" then return end
    local payload = HttpService:JSONEncode({
        username = "Projectsion Reports",
        embeds   = { buildEmbed("CDID Truck — Auto Farm Report", 0x1E3560) },
    })
    local base = webhookURL:gsub("%?.*$", "")
    if webhookPinnedId then
        local res = httpReq(base .. "/messages/" .. webhookPinnedId, "PATCH", payload)
        if res and res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300 then return end
        webhookPinnedId = nil
    end
    local res = httpReq(base .. "?wait=true", "POST", payload)
    if res and res.Body then
        local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if ok and data and data.id then webhookPinnedId = tostring(data.id) end
    end
end

-- Periodic webhook every 60 s
task.spawn(function()
    while true do
        task.wait(60)
        pcall(sendOrPatchWebhook)
    end
end)

-- ─── Core autofarm (DX-SR engine) ────────────────────────────────────────────
local function runFarm()
    sessionStart      = os.clock()
    sessionMoneyStart = getCleanMoney()

    -- initial teleport + base plates (DX-SR v25 equivalent)
    teleportHRP(SURABAYA_CF)
    task.wait(0.5)
    pcall(function()
        for _, def in ipairs({
            { name = "Base_Malang",   pos = Vector3.new(-7851, 380, 46856) },
            { name = "Base_Surabaya", pos = Vector3.new(35076, 128, -54518) },
        }) do
            local part = Workspace:FindFirstChild(def.name)
                or Instance.new("Part")
            part.Name      = def.name
            part.Anchored  = true
            part.CanCollide = true
            part.Size      = Vector3.new(1000, 5, 1000)
            part.CFrame    = CFrame.new(def.pos)
            part.Parent    = Workspace
        end
    end)

    deleteMap()

    if jobRemote then jobRemote:FireServer("Truck") end

    while farmActive do
        local cycleStart = os.clock()

        -- ── Roll until Malang (area index 4) ─────────────────────────────
        local gotMalang = false
        while farmActive and not gotMalang do
            arrowCount  = 0
            arrowTarget = nil

            if jobRemote then jobRemote:FireServer("Truck") end

            local sp = getStarterPrompt()
            if sp then firePrompt(sp) end

            -- wait for SetArrow × 2 or 0.5 s timeout (DX-SR pattern)
            local deadline = os.clock() + 0.5
            while farmActive and arrowCount < 2 and os.clock() < deadline do
                task.wait()
            end
            if not farmActive then break end
            if arrowCount < 2 or not arrowTarget then continue end

            local idx = getAreaIndex(arrowTarget)
            local isTarget = (idx == TARGET_AREA_IDX)

            if LblStatus then
                LblStatus:Set({ Title = "Status:", Content = string.format(
                    "Roll → Area %s %s",
                    tostring(idx or "?"),
                    isTarget and "✔ Malang" or "✘ rerolling..."
                )})
            end

            if isTarget then gotMalang = true end
        end
        if not farmActive then break end

        -- ── Spawn truck ───────────────────────────────────────────────────
        local spawnerFolder = Workspace:WaitForChild("Etc"):WaitForChild("Job")
            :WaitForChild("Truck"):WaitForChild("Spawner")
        local spawnerPart   = spawnerFolder:FindFirstChild("Part")
            or spawnerFolder:WaitForChild("Part", 3)

        local myTruck = getMyTruck()
        if not myTruck then
            if spawnerPart then
                teleportHRP(spawnerPart.CFrame + Vector3.new(0, 2, 0))
                local p = spawnerPart:FindFirstChild("Prompt")
                    or spawnerPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                if p then firePrompt(p) end
            end

            -- wait up to 6 s for truck
            local deadline = os.clock() + 6
            while farmActive and not myTruck and os.clock() < deadline do
                myTruck = getMyTruck()
                task.wait(0.05)
            end
        end
        if not farmActive or not myTruck then continue end

        -- remove trailer
        local trailerConn
        trailerConn = myTruck.ChildAdded:Connect(function(c)
            if c.Name:lower():find("trailer") then
                task.defer(function() pcall(c.Destroy, c) end)
            end
        end)
        for _, c in ipairs(myTruck:GetChildren()) do
            if c.Name:lower():find("trailer") then pcall(c.Destroy, c) end
        end

        task.wait(0.7)

        -- sit in DriveSeat
        local driveSeat = myTruck:WaitForChild("DriveSeat", 5)
        if driveSeat then
            local prompt = driveSeat:WaitForChild("PromptDriveSeat", 3)
            if prompt then
                teleportHRP(driveSeat.CFrame + Vector3.new(0, 3, 0))
                task.wait(0.2)
                firePrompt(prompt)
            end
        end

        -- wait seated
        local seated    = false
        local seatDeadline = os.clock() + 6
        while farmActive and os.clock() < seatDeadline do
            local char = lp.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.SeatPart then
                if driveSeat and hum.SeatPart ~= driveSeat then
                    hum.Sit = false
                    task.wait(0.1)
                    local p2 = driveSeat:FindFirstChild("PromptDriveSeat")
                    if p2 then
                        teleportHRP(driveSeat.CFrame + Vector3.new(0, 3, 0))
                        task.wait(0.1)
                        firePrompt(p2)
                    end
                else
                    seated = true
                    break
                end
            end
            task.wait(0.1)
        end

        if trailerConn then trailerConn:Disconnect() trailerConn = nil end
        for _, c in ipairs(myTruck:GetChildren()) do
            if c.Name:lower():find("trailer") then pcall(c.Destroy, c) end
        end

        if not farmActive or not seated then
            pcall(function()
                local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Sit = false end
            end)
            continue
        end

        -- ── Pivot truck to Malang (DX-SR style: direct PivotTo loop) ─────
        if LblStatus then LblStatus:Set({ Title = "Status:", Content = "Moving → Malang..." }) end

        local attempts = 0
        repeat
            myTruck:PivotTo(MALANG_POS)
            task.wait(0.25)
            attempts = attempts + 1
            if not myTruck or not myTruck.Parent then break end
        until (myTruck:GetPivot().Position - MALANG_POS.Position).Magnitude < 150
            or attempts >= 10

        if not myTruck or not myTruck.Parent then continue end
        if (myTruck:GetPivot().Position - MALANG_POS.Position).Magnitude >= 150 then
            continue
        end

        -- ── Job delay countdown ───────────────────────────────────────────
        local remaining = jobDelay - (os.clock() - cycleStart)
        if remaining > 0 then
            local deadline2 = os.clock() + remaining
            while farmActive and os.clock() < deadline2 do
                local left = math.ceil(deadline2 - os.clock())
                if LblStatus then
                    LblStatus:Set({ Title = "Status / Next TP:", Content = string.format("Drop In: %ds", left) })
                end
                task.wait(0.1)
            end
        end
        if not farmActive then break end

        -- ── Poll for payment (DX-SR heartbeat loop, 10 s max) ────────────
        if LblStatus then LblStatus:Set({ Title = "Status:", Content = "Waiting payment..." }) end
        local preSnap  = getMoneyDR()
        local earned   = 0
        if preSnap > 0 then
            local pollDeadline = os.clock() + 10
            while farmActive and os.clock() < pollDeadline do
                local now = getMoneyDR()
                if now > preSnap then
                    earned = now - preSnap
                    break
                end
                RunService.Heartbeat:Wait()
            end
        end

        -- ── Clear job, update stats ───────────────────────────────────────
        if jobRemote then jobRemote:FireServer("Unemployed") end

        local cycleDuration = os.clock() - cycleStart
        totalEarning  = totalEarning + earned
        totalJobs     = totalJobs    + 1
        lastCycleEarned = earned
        _G.TotalTeleportCount = _G.TotalTeleportCount + 1

        -- rolling IPH (last 6 cycles, DX-SR pattern)
        table.insert(earnLog, { earned = earned, duration = cycleDuration })
        while #earnLog > 6 do table.remove(earnLog, 1) end
        local sumE, sumD = 0, 0
        for _, e in ipairs(earnLog) do sumE = sumE + e.earned sumD = sumD + e.duration end
        if sumD > 0 then estIPH = (sumE / sumD) * 3600 end

        if LblLastCycle   then LblLastCycle:Set({ Title = "Last Cycle Earned:", Content = formatRP(lastCycleEarned) }) end
        if LblTotalEarning then LblTotalEarning:Set({ Title = "Total Earning:", Content = formatRP(totalEarning) }) end
        if LblIPH         then LblIPH:Set({ Title = "Earning / Hour:", Content = formatIPH(estIPH) }) end
        if LblTeleports   then LblTeleports:Set({ Title = "Total Teleport Done:", Content = totalJobs .. " Times" }) end
        if LblStatus      then LblStatus:Set({ Title = "Status:", Content = "Cycle done! ✔" }) end

        -- unseat + destroy truck
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = false end
        task.wait(0.5)
        if myTruck and myTruck.Parent then pcall(function() myTruck:Destroy() end) end
        task.wait(0.8)

        -- re-fire for next roll
        teleportHRP(SURABAYA_CF)
        if jobRemote then jobRemote:FireServer("Truck") end
    end
end

-- ─── Stats update loop ───────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1.5)
        local cur = getCleanMoney()
        if LblCurrentMoney then LblCurrentMoney:Set({ Title = "Current Money:", Content = formatRP(cur) }) end
        if sessionStart then
            local elapsed       = os.clock() - sessionStart
            local sessionEarned = math.max(0, cur - sessionMoneyStart)
            local sIPH          = elapsed > 20 and math.floor((sessionEarned / elapsed) * 3600) or 0
            if LblSessionTime    then LblSessionTime:Set({   Title = "Session Time:",    Content = formatDuration(elapsed) }) end
            if LblSessionEarned  then LblSessionEarned:Set({ Title = "Session Earned:", Content = formatRP(sessionEarned) }) end
            if LblSessionIPH     then LblSessionIPH:Set({    Title = "Session / Hour:", Content = formatIPH(sIPH) }) end
        end
        -- suppress Job GUI + MapFrame every tick
        pcall(function()
            local pg  = lp:FindFirstChild("PlayerGui")
            if not pg then return end
            local j   = pg:FindFirstChild("Job")
            if j and j.Enabled then j.Enabled = false end
            local hub = pg:FindFirstChild("Main") and pg.Main:FindFirstChild("Container")
                and pg.Main.Container:FindFirstChild("Hub")
            local mf  = hub and hub:FindFirstChild("MapFrame")
            if mf and mf.Visible then mf.Visible = false end
        end)
    end
end)

-- ─── Elapsed timer ───────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1)
        if farmActive and sessionStart then
            if LblElapsed then
                LblElapsed:Set({ Title = "Time Elapsed:", Content = formatDuration(os.clock() - sessionStart) })
            end
        end
    end
end)

-- ─── Rayfield UI ─────────────────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name            = "Car Driving Indonesia | By .projectsion",
    LoadingTitle    = "Projectsion Loading...",
    LoadingSubtitle = "CDID Script",
    ConfigurationSaving = { Enabled = false },
    Discord             = { Enabled = false },
    KeySystem           = false,
})

-- Farm Tab
local FarmTab = Window:CreateTab("Autofarm", "truck")
FarmTab:CreateSection("Autofarm Truck")
FarmTab:CreateToggle({
    Name         = "On Autofarm Truck",
    Info         = "Engine: DX-SR | Filter: Malang only",
    CurrentValue = false,
    Callback     = function(v)
        _G.Autofarm = v
        farmActive  = v
        if v then task.spawn(runFarm) end
    end,
})
FarmTab:CreateSlider({
    Name         = "Job Delay (seconds)",
    Range        = { 0, 90 },
    Increment    = 1,
    CurrentValue = jobDelay,
    Callback     = function(v) jobDelay = v end,
})

-- Stats Tab
local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Live")
LblStatus       = StatsTab:CreateParagraph({ Title = "Status:",            Content = "Idle" })
LblElapsed      = StatsTab:CreateParagraph({ Title = "Time Elapsed:",      Content = "00:00" })
LblCurrentMoney = StatsTab:CreateParagraph({ Title = "Current Money:",     Content = "Rp 0" })

StatsTab:CreateSection("Cycle")
LblLastCycle   = StatsTab:CreateParagraph({ Title = "Last Cycle Earned:", Content = "Rp 0" })
LblTotalEarning = StatsTab:CreateParagraph({ Title = "Total Earning:",    Content = "Rp 0" })
LblIPH          = StatsTab:CreateParagraph({ Title = "Earning / Hour:",   Content = "Rp 0" })
LblTeleports    = StatsTab:CreateParagraph({ Title = "Total Teleport Done:", Content = "0 Times" })

StatsTab:CreateSection("Session")
LblSessionTime   = StatsTab:CreateParagraph({ Title = "Session Time:",    Content = "—" })
LblSessionEarned = StatsTab:CreateParagraph({ Title = "Session Earned:",  Content = "Rp 0" })
LblSessionIPH    = StatsTab:CreateParagraph({ Title = "Session / Hour:", Content = "Rp 0" })

-- Misc Tab (NPC/teleport, kept)
local NPC_Paths = {
    ["Npc job select"]       = workspace.Etc.Job.Selection.Model.Prompt,
    ["Npc upgrade slot Npc"] = workspace.Etc.Upgrade.Upgrade.Prompt,
    ["Npc Box Shop"]         = workspace.Etc.NPC.BOXSHOP.ProximityPrompt,
    ["Daily quest npc"]      = workspace.Asset.DailyQuest.NPC.ProximityPrompt,
}
local SelectedNPC = ""
local ProxTab = Window:CreateTab("Misc", "bot")
ProxTab:CreateSection("Open NPC")
ProxTab:CreateDropdown({
    Name          = "Select NPC",
    Options       = { "Npc job select", "Npc upgrade slot Npc", "Npc Box Shop", "Daily quest npc" },
    CurrentOption = { "Npc job select" },
    MultipleOptions = false,
    Callback = function(v) SelectedNPC = v[1] end,
})
ProxTab:CreateButton({
    Name     = "Open NPC UI",
    Callback = function()
        local t = NPC_Paths[SelectedNPC]
        if t then fireproximityprompt(t) end
    end,
})

local SelectedPlayer = ""
local TpTab = Window:CreateTab("Teleport", "map-pin")
TpTab:CreateSection("Teleport Player")
local PlayerDropdown = TpTab:CreateDropdown({
    Name          = "Select Player",
    Options       = {},
    CurrentOption = { "" },
    MultipleOptions = false,
    Callback = function(v) SelectedPlayer = v[1] end,
})
local function refreshPlayers()
    local list = {}
    for _, v in pairs(workspace.Lives:GetChildren()) do
        if v:IsA("Model") and v.Name ~= lp.Name then
            table.insert(list, v.Name)
        end
    end
    PlayerDropdown:Refresh(list, { "" })
end
TpTab:CreateButton({ Name = "Refresh Player List", Callback = refreshPlayers })
TpTab:CreateButton({
    Name     = "Teleport to Player",
    Callback = function()
        local t = workspace.Lives:FindFirstChild(SelectedPlayer)
        if t then lp.Character:PivotTo(t:GetPivot()) end
    end,
})
task.spawn(refreshPlayers)

-- Webhook Tab
local WebhookTab = Window:CreateTab("Webhook", "webhook")
WebhookTab:CreateSection("Webhook Farm")
WebhookTab:CreateInput({
    Name                     = "Webhook Link",
    PlaceholderText          = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(t) webhookURL = t _G.WebhookURL = t end,
})
WebhookTab:CreateToggle({
    Name         = "Enable Webhook",
    Info         = "PATCH tiap 60s, POST saat ID hilang",
    CurrentValue = false,
    Callback     = function(v) webhookEnabled = v _G.AutoWebhook = v end,
})