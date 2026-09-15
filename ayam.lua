-- VoidlineHub | Bus Explorer Indonesia | Truck Autofarm
-- WindUI | DX-SR Hub | v0.0.0.2

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local VirtualInputMgr  = game:GetService("VirtualInputManager")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local VirtualUser      = game:GetService("VirtualUser")
local LocalPlayer      = Players.LocalPlayer

-- ── Anti-idle ──────────────────────────────────────────────────────────────
for _, conn in getconnections(LocalPlayer.Idled) do
    pcall(conn.Disable, conn)
    pcall(conn.Disconnect, conn)
end
local _idleConn = LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end)

-- ── uprightCF — strip pitch/roll, keep yaw + y-offset (ported from Projectsion) ──
local function uprightCF(cf, yOffset)
    yOffset   = yOffset or 0
    local pos  = cf.Position + Vector3.new(0, yOffset, 0)
    local look = cf.LookVector
    local yaw  = math.atan2(look.X, look.Z)
    return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
end

-- ── Teleport / proximity helpers ───────────────────────────────────────────
local function teleport(cf)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = uprightCF(cf)
    end
end

local function firePrompt(prompt)
    if not prompt then return end
    prompt.Enabled = true
    if fireproximityprompt then
        pcall(fireproximityprompt, prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.1)
        prompt:InputHoldEnd()
    end
end

local function getOwnedCar()
    local vehicles = Workspace:FindFirstChild("Vehicles")
    return vehicles and vehicles:FindFirstChild(LocalPlayer.Name .. "sCar")
end

-- ── Map-destroy helpers ────────────────────────────────────────────────────
local function createBaseParts()
    teleport(CFrame.new(34938, 135, -54576))
    task.wait(0.5)
    pcall(function()
        local bases = {
            { name = "Base_Malang",   pos = Vector3.new(-7851,  380,  46856) },
            { name = "Base_Surabaya", pos = Vector3.new(35076,  128, -54518) },
        }
        for _, b in ipairs(bases) do
            local part = Workspace:FindFirstChild(b.name)
            if not part then
                part            = Instance.new("Part")
                part.Name       = b.name
                part.Anchored   = true
                part.CanCollide = true
                part.Parent     = Workspace
            end
            part.Size   = Vector3.new(1000, 5, 1000)
            part.CFrame = CFrame.new(b.pos)
        end
    end)
end

local mapDestroyed = false
local function destroyMap()
    if mapDestroyed then return end
    mapDestroyed = true
    pcall(function()
        local map = Workspace:FindFirstChild("Map")
        if map then map:Destroy() end
    end)
end

-- ── GUI suppression (job screen / map frame only) ──────────────────────────
pcall(function()
    local gui = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end

    local function hideGui(sg)
        if sg and sg:IsA("ScreenGui") then
            sg.Enabled = false
            sg:GetPropertyChangedSignal("Enabled"):Connect(function()
                if sg.Enabled then sg.Enabled = false end
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

    local job = gui:FindFirstChild("Job")
    if job then hideGui(job) end
    gui.ChildAdded:Connect(function(child)
        if child.Name == "Job" then hideGui(child) end
    end)

    task.spawn(function()
        local main  = gui:WaitForChild("Main", 5)
        local cont  = main and main:WaitForChild("Container", 5)
        local hub   = cont and cont:WaitForChild("Hub", 5)
        local mapF  = hub  and (hub:FindFirstChild("MapFrame") or hub:WaitForChild("MapFrame", 5))
        if mapF then hideFrame(mapF) end
    end)
end)

-- ── State ──────────────────────────────────────────────────────────────────
local farmActive      = false
local jobDelay        = 50
local webhookUrl      = ""
local webhookOn       = false
local webhookMsgId    = nil
local webhookInterval = 60

local totalEarned  = 0
local tripCount    = 0
local lastEarned   = 0
local perHourRate  = 0
local farmStart    = nil
local sessionStart = os.clock()
local recentTrips  = {}
local arrowCount   = 0
local arrowTarget  = nil

-- ── TruckArea module ───────────────────────────────────────────────────────
local TruckArea = require(ReplicatedStorage.Shared.TruckArea)

-- ── DataReplication (cash reader) ─────────────────────────────────────────
local DataRep
pcall(function()
    DataRep = require(ReplicatedStorage.Services.DataReplication)
end)

local function getCash()
    local cash = 0
    pcall(function()
        if DataRep then
            if DataRep.GetCash then
                cash = DataRep:GetCash()
            elseif DataRep.GetData then
                cash = DataRep:GetData().Cash
            end
        end
    end)
    return cash
end

local function readDisplayCash()
    local cash = 0
    pcall(function()
        local lbl = LocalPlayer.PlayerGui.Main.Container.Hub.CashFrame.Frame.TextLabel
        cash = tonumber(lbl.Text:gsub("[^%d]", "")) or 0
    end)
    return cash > 0 and cash or getCash()
end

-- ── Formatters ─────────────────────────────────────────────────────────────
local function fmtTime(s)
    local h   = math.floor(s / 3600)
    local m   = math.floor((s % 3600) / 60)
    local sec = math.floor(s % 60)
    return h > 0 and string.format("%02d:%02d:%02d", h, m, sec)
               or  string.format("%02d:%02d", m, sec)
end

local function fmtRp(n)
    local s = tostring(math.floor(n or 0))
    repeat s = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2") until not s:find("^(-?%d+)(%d%d%d)")
    return "Rp " .. s
end

local function fmtRate(rph)
    local v = math.floor(rph or 0)
    if (v / 1e9) >= 0.1 then
        return string.format("%s (~%.2fM/hr)", fmtRp(v), v / 1e9)
    end
    return string.format("%s (~%.1fJt/hr)", fmtRp(v), v / 1e6)
end

-- ── Nearest TruckArea lookup ───────────────────────────────────────────────
local function nearestArea(pos)
    for i, area in ipairs(TruckArea) do
        if (pos - area.Location).Magnitude < 50 then
            return i, area.txt
        end
    end
    return nil, nil
end

-- ── Remote event wiring ────────────────────────────────────────────────────
local NetContainer = ReplicatedStorage:WaitForChild("NetworkContainer", 5)
local JobRemote    = NetContainer and NetContainer:FindFirstChild("RemoteEvents")
                     and NetContainer.RemoteEvents:FindFirstChild("Job")

if JobRemote then
    JobRemote.OnClientEvent:Connect(function(action, data)
        if action == "SetArrow" and typeof(data) == "Vector3" then
            arrowCount  = arrowCount + 1
            arrowTarget = data
        elseif action == "Cleanup" then
            arrowCount  = 0
            arrowTarget = nil
        end
    end)
end

-- ── Countdown tween state ──────────────────────────────────────────────────
local cdTween    = nil
local cdEndTime  = nil
local cdDuration = 0
local barFill    = nil
local cdLabel    = nil

local function startCountdown(secs)
    if cdTween then pcall(function() cdTween:Cancel() end); cdTween = nil end
    if secs and secs > 0 then
        cdDuration = secs
        cdEndTime  = os.clock() + secs
        if barFill then
            barFill.Size = UDim2.new(1, 0, 1, 0)
            cdTween = TweenService:Create(
                barFill,
                TweenInfo.new(secs, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                { Size = UDim2.new(0, 0, 1, 0) }
            )
            cdTween:Play()
        end
    else
        cdDuration = 0
        cdEndTime  = nil
        if barFill then barFill.Size = UDim2.new(0, 0, 1, 0) end
    end
end

local function resetCountdown()
    cdEndTime  = nil
    cdDuration = 0
    if cdTween then pcall(function() cdTween:Cancel() end); cdTween = nil end
    if barFill  then barFill.Size = UDim2.new(0, 0, 1, 0) end
    if cdLabel  then cdLabel.Text = "0s" end
end

local function setCountdownText(txt)
    if cdLabel then cdLabel.Text = txt end
end

-- ── Main farm loop ─────────────────────────────────────────────────────────
local SPAWN_CF  = CFrame.new(34938, 135, -54576)
local SPAWNER_V = Vector3.new(35161.36, 139, -54683.41)
local BASE_CF   = CFrame.new(-7848, 386, 46763)
local BASE_DEST = CFrame.new(-7845, 386, 46865)
local BASE_POS  = Vector3.new(-7845.344, 389.014, 46865.543)

local function getTruckStarter()
    local truck   = Workspace:FindFirstChild("Etc")
        and Workspace.Etc:FindFirstChild("Job")
        and Workspace.Etc.Job:FindFirstChild("Truck")
    local starter = truck and truck:FindFirstChild("Starter")
    if starter then
        return starter:FindFirstChild("Prompt", true)
            or starter:FindFirstChildWhichIsA("ProximityPrompt", true)
    end
end

local function startFarm()
    task.spawn(function()
        if JobRemote then JobRemote:FireServer("Truck") end
        createBaseParts()
        destroyMap()

        while farmActive do
            local tripStart = os.clock()
            local gotRoute  = false

            -- ── Phase 1: Get Cirebon_Baranangsiang4 route ─────────────────
            while farmActive and not gotRoute do
                arrowCount  = 0
                arrowTarget = nil
                if JobRemote then JobRemote:FireServer("Truck") end

                -- uprightCF applied via teleport() — no trip on starter approach
                local starter = getTruckStarter()
                if starter then
                    teleport(uprightCF(starter:GetPivot(), 3))
                    firePrompt(starter)
                end

                local t0 = os.clock()
                while farmActive and arrowCount < 2 do
                    if os.clock() - t0 > 0.5 then break end
                    task.wait()
                end
                if not farmActive then break end
                if arrowCount < 2 or not arrowTarget then continue end

                local areaIdx = nearestArea(arrowTarget)
                if areaIdx == 4 then gotRoute = true end
            end
            if not farmActive or not gotRoute then break end

            -- ── Phase 2: Spawn truck ───────────────────────────────────────
            local spawnerRoot = Workspace.Etc.Job.Truck.Spawner
            local car         = getOwnedCar()
            if not car then
                -- uprightCF on spawner approach — character lands upright
                teleport(uprightCF(CFrame.new(SPAWNER_V), 3))
                local spawnPart = spawnerRoot:FindFirstChild("Part")
                              or  spawnerRoot:WaitForChild("Part", 3)
                if spawnPart then
                    teleport(uprightCF(spawnPart.CFrame, 2))
                end

                local deadline = os.clock()
                while farmActive and not car do
                    local prompt = spawnPart and (
                        spawnPart:FindFirstChild("Prompt")
                        or spawnPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                    )
                    if prompt then
                        firePrompt(prompt)
                    elseif not spawnPart then
                        spawnPart = spawnerRoot:FindFirstChild("Part")
                        if spawnPart then
                            teleport(uprightCF(spawnPart.CFrame, 2))
                        end
                    end
                    local t1 = os.clock()
                    while farmActive and os.clock() - t1 < 0.4 do
                        car = getOwnedCar()
                        if car then break end
                        task.wait(0.05)
                    end
                    if os.clock() - deadline > 6 then
                        if spawnPart then teleport(uprightCF(spawnPart.CFrame, 2)) end
                        deadline = os.clock()
                    end
                end
            end
            if not farmActive or not car then continue end

            task.wait(0.7)

            local trailerConn = car.ChildAdded:Connect(function(child)
                if child.Name:lower():find("trailer") then
                    task.defer(function() pcall(child.Destroy, child) end)
                end
            end)
            for _, child in ipairs(car:GetChildren()) do
                if child.Name:lower():find("trailer") then pcall(child.Destroy, child) end
            end

            -- ── Phase 3: Sit in DriveSeat ─────────────────────────────────
            local driveSeat = car:WaitForChild("DriveSeat", 5)
            if driveSeat then
                local seatPrompt = driveSeat:WaitForChild("PromptDriveSeat", 3)
                if seatPrompt then
                    teleport(uprightCF(driveSeat.CFrame, 3))
                    task.wait(0.2)
                    firePrompt(seatPrompt)
                end
            end

            local t2 = os.clock()
            while farmActive do
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                if hum and hum.SeatPart then
                    if driveSeat and hum.SeatPart ~= driveSeat then
                        hum.Sit = false
                        task.wait(0.1)
                        local p = driveSeat:FindFirstChild("PromptDriveSeat")
                        if p then
                            teleport(uprightCF(driveSeat.CFrame, 3))
                            task.wait(0.1)
                            firePrompt(p)
                        end
                    else
                        break
                    end
                end
                if os.clock() - t2 > 1.5 and driveSeat then
                    local p = driveSeat:FindFirstChild("PromptDriveSeat")
                    if p then
                        teleport(uprightCF(driveSeat.CFrame, 3))
                        task.wait(0.1)
                        firePrompt(p)
                    end
                end
                task.wait(0.1)
                if os.clock() - t2 > 6 then break end
            end

            trailerConn:Disconnect()
            for _, child in ipairs(car:GetChildren()) do
                if child.Name:lower():find("trailer") then pcall(child.Destroy, child) end
            end
            if not farmActive then break end

            -- ── Phase 4: PivotTo base ──────────────────────────────────────
            local pivotAttempts = 0
            while farmActive and pivotAttempts < 10 do
                car:PivotTo(BASE_CF)
                task.wait(0.25)
                if not car or not car.Parent then break end
                if (car:GetPivot().Position - BASE_CF.Position).Magnitude < 150 then break end
                pivotAttempts += 1
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                if hum then
                    hum.Sit = false
                    local t3 = os.clock()
                    while farmActive and hum and hum.SeatPart do
                        hum.Sit = false
                        task.wait(0.05)
                        if os.clock() - t3 > 1.2 then break end
                    end
                end
                task.wait(0.15)
                local ds2 = car:FindFirstChild("DriveSeat") or car:WaitForChild("DriveSeat", 2)
                local sp2 = ds2 and (ds2:FindFirstChild("PromptDriveSeat")
                                   or ds2:FindFirstChildWhichIsA("ProximityPrompt", true))
                if ds2 and sp2 then
                    teleport(uprightCF(ds2.CFrame, 3))
                    task.wait(0.1)
                    firePrompt(sp2)
                end
                local t4 = os.clock()
                while farmActive do
                    local char = LocalPlayer.Character
                    local hum  = char and char:FindFirstChild("Humanoid")
                    if hum and hum.SeatPart and (not ds2 or hum.SeatPart == ds2) then break end
                    if os.clock() - t4 > 1.2 and ds2 and sp2 then
                        teleport(uprightCF(ds2.CFrame, 3))
                        task.wait(0.1)
                        firePrompt(sp2)
                    end
                    task.wait(0.1)
                    if os.clock() - t4 > 5 then break end
                end
                for _, child in ipairs(car:GetChildren()) do
                    if child.Name:lower():find("trailer") then pcall(child.Destroy, child) end
                end
                task.wait(0.2)
            end

            if not farmActive or not car or not car.Parent then continue end
            if (car:GetPivot().Position - BASE_CF.Position).Magnitude >= 150 then continue end

            -- ── Phase 5: Job delay countdown ──────────────────────────────
            local elapsed   = os.clock() - tripStart
            local remaining = jobDelay - elapsed
            local lastSec   = nil
            if remaining > 0 then
                startCountdown(remaining)
                setCountdownText(string.format("%ds", math.ceil(remaining)))
            end
            while farmActive do
                local rem = jobDelay - (os.clock() - tripStart)
                if rem <= 0 then break end
                local s = math.ceil(rem)
                if s ~= lastSec then
                    if UI_paragraphs and UI_paragraphs.countdown then
                        UI_paragraphs.countdown:SetDesc(string.format("%ds", s))
                    end
                    setCountdownText(string.format("%ds", s))
                    lastSec = s
                end
                task.wait(0.1)
            end
            if UI_paragraphs and UI_paragraphs.countdown then
                UI_paragraphs.countdown:SetDesc("0s")
            end
            resetCountdown()
            if not farmActive then break end

            -- ── Phase 6: Collect reward ────────────────────────────────────
            local cashBefore = getCash()
            car:PivotTo(BASE_DEST)
            if cashBefore > 0 then
                local t5 = os.clock()
                while farmActive do
                    local cashAfter = getCash()
                    if cashAfter > cashBefore then
                        local gained = cashAfter - cashBefore
                        local dur    = os.clock() - tripStart
                        totalEarned += gained
                        lastEarned   = gained
                        tripCount   += 1
                        table.insert(recentTrips, { earned = gained, duration = dur })
                        while #recentTrips > 6 do table.remove(recentTrips, 1) end
                        local sumE, sumD = 0, 0
                        for _, t in ipairs(recentTrips) do
                            sumE += t.earned; sumD += t.duration
                        end
                        if sumD > 0 then perHourRate = (sumE / sumD) * 3600 end
                        break
                    end
                    if os.clock() - t5 > 10 then break end
                    task.wait()
                end
            end

            -- ── Phase 7: Dismount and reset ───────────────────────────────
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            if hum then hum.Sit = false end
            teleport(SPAWN_CF)
            if JobRemote then JobRemote:FireServer("Truck") end
            local starter = getTruckStarter()
            if starter then firePrompt(starter) end
        end
    end)
end

-- ── Paragraph reference table (filled after UI build) ─────────────────────
UI_paragraphs = {}

-- ── Background stats ticker ────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1)
        local now = os.clock()

        if UI_paragraphs.elapsed then
            if farmActive and farmStart then
                UI_paragraphs.elapsed:SetDesc(fmtTime(now - farmStart))
            elseif tripCount == 0 then
                UI_paragraphs.elapsed:SetDesc("00:00")
            end
        end

        if UI_paragraphs.currentMoney then
            UI_paragraphs.currentMoney:SetDesc(fmtRp(readDisplayCash()))
        end
        if UI_paragraphs.totalEarned then
            UI_paragraphs.totalEarned:SetDesc(fmtRp(totalEarned))
        end
        if UI_paragraphs.perHour then
            if perHourRate > 0 then
                UI_paragraphs.perHour:SetDesc(fmtRate(perHourRate))
            elseif farmActive then
                UI_paragraphs.perHour:SetDesc("Calculating...")
            else
                UI_paragraphs.perHour:SetDesc("Rp 0")
            end
        end
        if UI_paragraphs.youGot and lastEarned > 0 then
            UI_paragraphs.youGot:SetDesc(fmtRp(lastEarned))
        end

        pcall(function()
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            if not gui then return end
            local job = gui:FindFirstChild("Job")
            if job and job.Enabled then job.Enabled = false end
            local hub = gui:FindFirstChild("Main")
                and gui.Main:FindFirstChild("Container")
                and gui.Main.Container:FindFirstChild("Hub")
            local mf  = hub and hub:FindFirstChild("MapFrame")
            if mf and mf.Visible then mf.Visible = false end
        end)
    end
end)

-- ── Webhook ────────────────────────────────────────────────────────────────
local function sendWebhook(title, color, extraFields)
    if not webhookOn or webhookUrl == "" then return end
    local cash    = readDisplayCash()
    local elapsed = farmStart and (os.clock() - farmStart) or (os.clock() - sessionStart)
    local fields  = {
        { name = "Total earning",    value = "```" .. fmtRp(totalEarned)  .. "```", inline = true  },
        { name = "Total job done",   value = "```" .. tripCount            .. " Delivered```", inline = true },
        { name = "Earning per/hour", value = "```" .. fmtRate(perHourRate) .. "```", inline = false },
        { name = "Current money",    value = "```" .. fmtRp(cash)          .. "```", inline = true  },
        { name = "Uptime",           value = "```" .. fmtTime(elapsed)     .. "```", inline = true  },
    }
    if extraFields then
        for _, f in ipairs(extraFields) do table.insert(fields, f) end
    end
    local body = HttpService:JSONEncode({
        username = "anonymous",
        embeds   = { {
            title     = title,
            color     = color,
            fields    = fields,
            thumbnail = { url = "https://tr.rbxcdn.com/180DAY-89e12785eed48e4b6cf7b03cd0cff336/150/150/Image/Webp/noFilter" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer    = { text = "DX-SR Hub | CDIDTruck" },
        } },
    })
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if not req then return end
        local cleanUrl = webhookUrl:gsub("%?.*$", "")
        if webhookMsgId then
            local res = req({ Url = cleanUrl .. "/messages/" .. webhookMsgId,
                              Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
            if res and res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300 then return end
            webhookMsgId = nil
        end
        local res = req({ Url = cleanUrl .. "?wait=true",
                          Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
        if res and res.Body then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
            if ok and data and data.id then webhookMsgId = tostring(data.id) end
        end
    end)
end

local webhookAlerted = false
local function alertWebhook(reason)
    if webhookAlerted or not webhookOn or webhookUrl == "" then return end
    webhookAlerted = true
    sendWebhook("CDID Truck – Alert", 15548997, {
        { name = "Reason", value = "```" .. tostring(reason) .. "```", inline = false },
        { name = "Status", value  = "```Disconnected```",              inline = true  },
    })
end

pcall(function()
    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        local msg = game:GetService("GuiService"):GetErrorMessage()
        if msg and msg ~= "" then alertWebhook(msg) end
    end)
end)
pcall(function()
    local overlay = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui", 5)
                    and game:GetService("CoreGui").RobloxPromptGui:WaitForChild("promptOverlay", 5)
    if overlay then
        local function checkPrompt(child)
            if child.Name == "ErrorPrompt" then
                local area = child:FindFirstChild("MessageArea")
                local lbl  = area and area:FindFirstChild("ErrorFrame")
                             and area.ErrorFrame:FindFirstChild("ErrorMessage")
                alertWebhook(lbl and lbl.Text or "Roblox Prompt Disconnected")
            end
        end
        overlay.ChildAdded:Connect(checkPrompt)
        local existing = overlay:FindFirstChild("ErrorPrompt")
        if existing then checkPrompt(existing) end
    end
end)
pcall(function()
    game:GetService("TeleportService").TeleportInitFailed:Connect(function(_, _, msg)
        alertWebhook("Teleport Failed: " .. tostring(msg))
    end)
end)
pcall(function()
    game:BindToClose(function() alertWebhook("Game Closed") end)
end)

task.spawn(function()
    while true do
        task.wait(webhookInterval)
        if webhookOn and webhookUrl ~= "" then
            sendWebhook("CDID Truck – Auto Farm Report", 1981066, {
                { name = "Status", value = "```" .. (farmActive and "Running" or "Idle") .. "```", inline = true },
            })
        end
    end
end)

-- ── WindUI ─────────────────────────────────────────────────────────────────
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title       = "CDID x Truck",
    Icon        = "truck",
    Author      = "DX-SR Hub",
    Folder      = "DX-SR",
    Size        = UDim2.fromOffset(580, 460),
    MinSize     = Vector2.new(560, 350),
    MaxSize     = Vector2.new(850, 560),
    ToggleKey   = Enum.KeyCode.V,
    Transparent = true,
    Theme       = "Dark",
    Resizable   = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar    = false,
    ScrollBarEnabled = false,
})
Window:Tag({ Title = "v0.0.0.2",  Icon = "github",      Color = Color3.fromHex("#30ff6a"), Radius = 13 })
Window:Tag({ Title = "DX-SR Hub", Icon = "text-cursor", Color = Color3.fromHex("#1E3A8A"), Radius = 13 })
WindUI:Popup({
    Title   = "Update log",
    Icon    = "info",
    Content = "Made by DX-SR, Initiate success",
    Buttons = { { Title = "Continue", Icon = "arrow-right", Callback = function() end, Variant = "Primary" } },
})

local mainSection = Window:Section({ Title = "Main", Icon = "home", Opened = true })
local truckTab    = mainSection:Tab({ Title = "Truck", Icon = "truck" })

truckTab:Section({ Title = "Auto Truck", Opened = true })
pcall(function() truckTab:Space() end)

truckTab:Toggle({
    Title    = "Auto farm Truck",
    Flag     = "AutoFarmTruck",
    Default  = false,
    Callback = function(val)
        farmActive = val
        if val then
            if not farmStart then farmStart = os.clock() end
            startFarm()
        end
    end,
})

truckTab:Slider({
    Title    = "Job delay",
    Step     = 1,
    Flag     = "TeleportDelay",
    Value    = { Min = 0, Max = 50, Default = jobDelay },
    Callback = function(val) jobDelay = val end,
})

truckTab:Toggle({
    Title    = "Enable Webhook",
    Flag     = "WebhookEnabled",
    Default  = false,
    Callback = function(val) webhookOn = val end,
})

truckTab:Input({
    Title            = "Webhook URL",
    PlaceholderText  = "https://discord.com/api/webhooks/...",
    ClearTextOnFocus = false,
    Flag             = "WebhookUrl",
    Value            = webhookUrl,
    Callback         = function(val) webhookUrl = val end,
})

truckTab:Section({ Title = "Information", Opened = true })
pcall(function() truckTab:Space() end)

do
    local pGui = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local sg = Instance.new("ScreenGui")
        sg.Name           = "CDCountdown"
        sg.DisplayOrder   = 10
        sg.IgnoreGuiInset = true
        sg.ResetOnSpawn   = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local bg = Instance.new("Frame")
        bg.Size                   = UDim2.new(1, 0, 0, 36)
        bg.Position               = UDim2.new(0, 0, 1, -50)
        bg.BackgroundColor3       = Color3.fromRGB(10, 10, 15)
        bg.BackgroundTransparency = 0.25
        bg.BorderSizePixel        = 0
        bg.Parent                 = sg

        local bar = Instance.new("Frame")
        bar.Name             = "BarBg"
        bar.Size             = UDim2.new(1, 0, 0, 5)
        bar.Position         = UDim2.new(0, 0, 0, 0)
        bar.BackgroundColor3 = Color3.fromRGB(24, 30, 46)
        bar.BorderSizePixel  = 0
        bar.ClipsDescendants = true
        bar.Parent           = bg
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Name             = "Fill"
        fill.Size             = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(34, 211, 238)
        fill.BorderSizePixel  = 0
        fill.Parent           = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        barFill = fill

        local lbl = Instance.new("TextLabel")
        lbl.Size                   = UDim2.new(1, 0, 0, 18)
        lbl.Position               = UDim2.new(0, 8, 0, 10)
        lbl.BackgroundTransparency = 1
        lbl.Font                   = Enum.Font.GothamBold
        lbl.Text                   = "0s"
        lbl.TextColor3             = Color3.fromRGB(224, 242, 254)
        lbl.TextSize               = 13
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = bg
        cdLabel = lbl

        sg.Parent = pGui
    end
end

UI_paragraphs.countdown    = truckTab:Paragraph({ Title = "Delay Countdown", Desc = "0s" })
UI_paragraphs.elapsed      = truckTab:Paragraph({ Title = "Time Elapsed",    Desc = "00:00" })
UI_paragraphs.currentMoney = truckTab:Paragraph({ Title = "Current Money",   Desc = "Rp 0" })
UI_paragraphs.totalEarned  = truckTab:Paragraph({ Title = "Total Earning",   Desc = "Rp 0" })
UI_paragraphs.perHour      = truckTab:Paragraph({ Title = "Earning / Hour",  Desc = "Rp 0" })
UI_paragraphs.youGot       = truckTab:Paragraph({ Title = "You Got",         Desc = "Rp 0" })

-- ── Config tab ─────────────────────────────────────────────────────────────
local cfgTab = mainSection:Tab({ Title = "Configuration", Icon = "settings" })
cfgTab:Section({ Title = "Theme", Opened = true })
pcall(function() cfgTab:Space() end)

local themes = { "Dark","Light","Rose","Plant","Red","Indigo","Sky","Violet",
                 "Amber","Emerald","Midnight","Crimson","Monokai Pro","Cotton Candy",
                 "Mellowsi","Rainbow" }
cfgTab:Dropdown({
    Title    = "Select Theme",
    Desc     = "Choose UI Theme",
    Multi    = false,
    Flag     = "SelectedTheme",
    Value    = WindUI:GetCurrentTheme() or "Dark",
    Values   = themes,
    Callback = function(v) pcall(function() WindUI:SetTheme(v) end) end,
})

cfgTab:Section({ Title = "Config Manager", Opened = true })
pcall(function() cfgTab:Space() end)

local selectedCfg  = ""
local cfgNameInput = ""
local function listConfigs()
    local out = {}
    pcall(function()
        local all = Window.ConfigManager:AllConfigs()
        if all then for _, n in ipairs(all) do table.insert(out, n) end end
    end)
    return out
end

local cfgDropdown = cfgTab:Dropdown({
    Title    = "Select Config",
    Desc     = "Choose saved config",
    Multi    = false,
    Flag     = "SelectedConfigDropdown",
    Value    = "",
    Values   = listConfigs(),
    Callback = function(v) selectedCfg = v end,
})

cfgTab:Input({
    Title            = "Config Name",
    Desc             = "New config name",
    PlaceholderText  = "Enter config name...",
    ClearTextOnFocus = false,
    Flag             = "ConfigNameInput",
    Callback         = function(v) cfgNameInput = v end,
})

cfgTab:Button({
    Title    = "Save Config",
    Desc     = "Save current settings",
    Callback = function()
        if cfgNameInput == "" then
            WindUI:Notify({ Title = "Config", Content = "Enter config name first!", Duration = 3 })
            return
        end
        pcall(function()
            selectedCfg = cfgNameInput
            pcall(function() cfgDropdown:Select(cfgNameInput) end)
            Window.ConfigManager:CreateConfig(cfgNameInput):Save()
        end)
        WindUI:Notify({ Title = "Config", Content = "Config '" .. cfgNameInput .. "' saved!", Duration = 3 })
        pcall(function() cfgDropdown:Refresh(listConfigs()); cfgDropdown:Select(cfgNameInput) end)
    end,
})

cfgTab:Button({
    Title    = "Load Config",
    Desc     = "Load selected config",
    Callback = function()
        if selectedCfg == "" or selectedCfg == "--" then
            WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 })
            return
        end
        pcall(function()
            Window.ConfigManager:CreateConfig(selectedCfg):Load()
            pcall(function() cfgDropdown:Select(selectedCfg) end)
        end)
        WindUI:Notify({ Title = "Config", Content = "Config '" .. selectedCfg .. "' loaded!", Duration = 3 })
    end,
})

cfgTab:Button({
    Title    = "Delete Config",
    Desc     = "Delete selected config",
    Callback = function()
        if selectedCfg == "" or selectedCfg == "--" then
            WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 })
            return
        end
        pcall(function() Window.ConfigManager:CreateConfig(selectedCfg):Delete() end)
        WindUI:Notify({ Title = "Config", Content = "Config '" .. selectedCfg .. "' deleted!", Duration = 3 })
        selectedCfg = ""
        pcall(function() cfgDropdown:Refresh(listConfigs()); cfgDropdown:Select("") end)
    end,
})

cfgTab:Button({
    Title    = "Set Auto Load",
    Desc     = "Auto-load this config on start",
    Callback = function()
        if selectedCfg == "" or selectedCfg == "--" then
            WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 })
            return
        end
        pcall(function()
            local all = Window.ConfigManager:AllConfigs()
            if all and isfile and readfile and writefile then
                for _, name in ipairs(all) do
                    local path = "WindUI/" .. (Window.Folder or "DX-SR") .. "/config/" .. name .. ".json"
                    if isfile(path) then
                        pcall(function()
                            local data = HttpService:JSONDecode(readfile(path))
                            if type(data) == "table" then
                                data.__autoload = (name == selectedCfg)
                                writefile(path, HttpService:JSONEncode(data))
                            end
                        end)
                    end
                end
            end
            pcall(function() cfgDropdown:Select(selectedCfg) end)
            if Window.ConfigManager and Window.ConfigManager.Configs then
                for name, cfg in pairs(Window.ConfigManager.Configs) do
                    if cfg and cfg.SetAutoLoad then cfg:SetAutoLoad(name == selectedCfg) end
                end
            end
        end)
        WindUI:Notify({ Title = "Config", Content = "Auto load set to '" .. selectedCfg .. "'!", Duration = 3 })
    end,
})

pcall(function()
    local all = Window.ConfigManager:AllConfigs()
    if all and readfile and isfile then
        for _, name in ipairs(all) do
            local path = "WindUI/" .. (Window.Folder or "DX-SR") .. "/config/" .. name .. ".json"
            if isfile(path) then
                local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
                if ok and type(data) == "table" and data.__autoload then
                    Window.ConfigManager:CreateConfig(name):Load()
                    selectedCfg = name
                    task.defer(function() pcall(function() cfgDropdown:Select(name) end) end)
                    break
                end
            end
        end
    end
end)

Window:EditOpenButton({
    Title           = "Open UI",
    Icon            = "monitor",
    CornerRadius    = UDim.new(0, 16),
    StrokeThickness = 2,
    Color           = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile      = false,
    Enabled         = true,
})