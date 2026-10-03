-- PROJECTSION HUB | CDID | Truck + Barista Autofarm
-- No Nexova auth, no Nexova hub, no Nexova assets

-- ================================================================
-- SERVICES
-- ================================================================
local Players             = game:GetService("Players")
local VirtualUser         = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local RunService          = game:GetService("RunService")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local HttpService         = game:GetService("HttpService")
local SoundService        = game:GetService("SoundService")

local LocalPlayer  = Players.LocalPlayer
local playerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- ================================================================
-- ANTI-IDLE
-- ================================================================
for _, conn in getconnections(LocalPlayer.Idled) do
    pcall(conn.Disable, conn)
    pcall(conn.Disconnect, conn)
end
local _idleConn = LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end)

-- ================================================================
-- TRUCK STATE
-- ================================================================
local truckRunning      = false
local truckDelay        = 50
local truckStartTick    = nil
local truckTotalEarned  = 0
local truckCycleCount   = 0
local truckLastEarned   = 0
local truckEarnPerHour  = 0
local truckEarnSamples  = {}

local webhookEnabled    = false
local webhookUrl        = ""

local networkContainer  = ReplicatedStorage:WaitForChild("NetworkContainer", 5)
local jobRemote         = networkContainer and networkContainer:FindFirstChild("RemoteEvents")
                          and networkContainer.RemoteEvents:FindFirstChild("Job")

local TruckArea         = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TruckArea"))

local DataReplication
pcall(function()
    DataReplication = require(ReplicatedStorage:WaitForChild("Services"):WaitForChild("DataReplication"))
end)

-- Countdown tween state (restored from original)
local _cdTweenObj    = nil
local _cdEndTime     = nil
local _cdTotalSecs   = 0
local _cdBarFill     = nil  -- UI element assigned later
local _cdBarLabel    = nil  -- UI element assigned later

-- ================================================================
-- BARISTA STATE
-- ================================================================
local baristaRunning        = false
local baristaOrders         = 0
local baristaStartTick      = nil
local baristaCurrentMenu    = "-"
local baristaCurrentFlavour = "-"
local baristaCurrentOrder   = nil

local BaristaMenu
pcall(function()
    BaristaMenu = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BaristaMenu"))
end)

-- ================================================================
-- SHARED HELPERS
-- ================================================================
local function fmtMoney(n)
    local s = tostring(math.floor(n or 0))
    repeat
        local out, hits = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
        s = out
        if hits == 0 then break end
    until false
    return "Rp " .. s
end

local function fmtEarnPerHour(total)
    local n = math.floor(total or 0)
    local b = n / 1000000000
    if b >= 0.1 then
        return string.format("%s (~%.2fM/hr)", fmtMoney(n), b)
    end
    return string.format("%s (~%.1fJt/hr)", fmtMoney(n), n / 1000000)
end

local function fmtTime(secs)
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = math.floor(secs % 60)
    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, s)
    end
    return string.format("%02d:%02d", m, s)
end

local function fmtTimeFull(secs)
    return string.format("%02d:%02d:%02d",
        math.floor(secs / 3600),
        math.floor((secs % 3600) / 60),
        math.floor(secs % 60))
end

local function getCash()
    local v = 0
    pcall(function()
        if DataReplication then
            if DataReplication.GetCash then
                v = DataReplication:GetCash()
            elseif DataReplication.GetData then
                v = DataReplication:GetData().Cash
            end
        end
    end)
    -- fallback: read from game UI label
    if v == 0 then
        pcall(function()
            local lbl = LocalPlayer.PlayerGui.Main.Container.Hub.CashFrame.Frame.TextLabel
            v = tonumber(lbl.Text:gsub("[^%d]", "")) or 0
        end)
    end
    return v
end

local function findTruckArea(pos)
    for i, area in ipairs(TruckArea) do
        if (pos - area.Location).Magnitude < 50 then
            return i, area.txt
        end
    end
    return nil, nil
end

local function getPlayerVehicle()
    local veh = workspace:FindFirstChild("Vehicles")
    if veh then
        return veh:FindFirstChild(LocalPlayer.Name .. "sCar")
    end
end

local function teleportCharacter(cf)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf end
end

local function firePrompt(prompt)
    if not (prompt and prompt:IsA("ProximityPrompt")) then return end
    prompt.Enabled = true
    if fireproximityprompt then
        pcall(fireproximityprompt, prompt)
    else
        prompt:InputHoldBegin()
        task.wait((prompt.HoldDuration or 0.5) + 0.1)
        prompt:InputHoldEnd()
    end
end

local function pressSpace(times, interval)
    for i = 1, times do
        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        task.wait(interval or 0.2)
    end
end

local function clickGuiButton(btn)
    if not btn then return end
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.MouseButton1Down)  end)
        pcall(function() firesignal(btn.Activated)         end)
        return
    end
    if getconnections then
        local fired = false
        for _, event in ipairs({ btn.MouseButton1Click, btn.MouseButton1Down, btn.Activated }) do
            for _, conn in pairs(getconnections(event)) do
                if conn.Fire     then pcall(function() conn:Fire()     end); fired = true
                elseif conn.Function then pcall(function() conn.Function() end); fired = true
                end
            end
        end
        if fired then return end
    end
    if btn:IsA("GuiButton") then
        pcall(function()
            local gs = game:GetService("GuiService")
            gs.SelectedObject = btn
            VirtualUser:Button1Down(Vector2.zero)
            VirtualUser:Button1Up(Vector2.zero)
        end)
    end
end

-- ================================================================
-- TRUCK MAP SUPPRESSION (original behaviour preserved)
-- ================================================================
local _mapDestroyed = false
local function suppressMap()
    if _mapDestroyed then return end
    _mapDestroyed = true
    pcall(function()
        local m = workspace:FindFirstChild("Map")
        if m then m:Destroy() end
    end)
end

local function placeBases()
    teleportCharacter(CFrame.new(34938, 135, -54576))
    task.wait(0.5)
    pcall(function()
        local bases = {
            { name = "Base_Malang",   pos = Vector3.new(-7851, 380, 46856) },
            { name = "Base_Surabaya", pos = Vector3.new(35076, 128, -54518) },
        }
        local sz = Vector3.new(1000, 5, 1000)
        for _, b in ipairs(bases) do
            local part = workspace:FindFirstChild(b.name) or Instance.new("Part")
            part.Name      = b.name
            part.Anchored  = true
            part.CanCollide = true
            part.Size      = sz
            part.CFrame    = CFrame.new(b.pos)
            part.Parent    = workspace
        end
    end)
end

-- ================================================================
-- JOB GUI SUPPRESSOR (original behaviour preserved)
-- ================================================================
pcall(function()
    local gui = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end

    local function disableScreenGui(sg)
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

    local jobGui = gui:FindFirstChild("Job")
    if jobGui then disableScreenGui(jobGui) end
    gui.ChildAdded:Connect(function(child)
        if child.Name == "Job" then disableScreenGui(child) end
    end)

    task.spawn(function()
        local main = gui:WaitForChild("Main", 5)
        local hub  = main and main:WaitForChild("Container", 5)
        hub = hub and hub:WaitForChild("Hub", 5)
        local mf = hub and (hub:FindFirstChild("MapFrame") or hub:WaitForChild("MapFrame", 5))
        if mf then hideFrame(mf) end
    end)
end)

-- ================================================================
-- TRUCK COUNTDOWN UI HELPERS
-- ================================================================
-- These are wired to Rayfield paragraph labels defined below.
-- We store refs here and write to them after UI creation.
local _rfParagraphRefs = {}

local function setCountdownBar(secs)
    if _cdTweenObj then
        pcall(function() _cdTweenObj:Cancel() end)
        _cdTweenObj = nil
    end
    if secs and secs > 0 then
        _cdTotalSecs = secs
        _cdEndTime   = os.clock() + secs
        if _cdBarFill then
            _cdBarFill.Size = UDim2.new(1, 0, 1, 0)
            local ti = TweenInfo.new(secs, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            _cdTweenObj = TweenService:Create(_cdBarFill, ti, { Size = UDim2.new(0, 0, 1, 0) })
            _cdTweenObj:Play()
        end
    else
        _cdTotalSecs = 0
        _cdEndTime   = nil
        if _cdBarFill then _cdBarFill.Size = UDim2.new(0, 0, 1, 0) end
    end
end

local function resetCountdown()
    _cdEndTime   = nil
    _cdTotalSecs = 0
    if _cdTweenObj then
        pcall(function() _cdTweenObj:Cancel() end)
        _cdTweenObj = nil
    end
    if _cdBarFill  then _cdBarFill.Size = UDim2.new(0, 0, 1, 0) end
    if _cdBarLabel then _cdBarLabel.Text = "0s" end
end

-- ================================================================
-- WEBHOOK
-- ================================================================
local function sendWebhook(income)
    if webhookUrl == "" or not webhookUrl:find("discord.com") then return end
    local http_fn = request or http_request
                    or (syn and syn.request)
                    or (fluxus and fluxus.request)
    if not http_fn then return end
    local embed = {
        author = { name = "Projectsion Webhook" },
        title  = "Truck Cycle Completed",
        color  = 0xFFFFFF,
        fields = {
            { name = "Username",      value = LocalPlayer.Name,          inline = false },
            { name = "Cycle Income",  value = fmtMoney(income),          inline = false },
            { name = "Current Money", value = fmtMoney(getCash()),        inline = false },
            { name = "Total Earning", value = fmtMoney(truckTotalEarned), inline = false },
            { name = "Cycle Count",   value = tostring(truckCycleCount),  inline = false },
            { name = "Running Time",  value = truckStartTick and fmtTime(os.clock() - truckStartTick) or "—", inline = false },
            { name = "Est /Hour",     value = fmtEarnPerHour(truckEarnPerHour), inline = false },
        },
        footer = { text = "Projectsion | " .. os.date("%m/%d/%Y %I:%M %p") },
    }
    pcall(function()
        http_fn({
            Url     = webhookUrl,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode({ username = "Projectsion Reports", embeds = { embed } }),
        })
    end)
end

-- ================================================================
-- TRUCK AUTOFARM LOOP
-- ================================================================
local function truckLoop()
    task.spawn(function()
        local SURABAYA_SPAWN  = CFrame.new(34938, 135, -54576)
        local TRUCK_SEAT_POS  = Vector3.new(35161.36, 139, -54683.41)
        local MALANG_BASE_CF  = CFrame.new(-7848, 386, 46763)
        local MALANG_DELIVER  = CFrame.new(-7845, 386, 46865)

        local function findTruckStarter()
            local etc = workspace:FindFirstChild("Etc")
            local job = etc and etc:FindFirstChild("Job")
            local trk = job and job:FindFirstChild("Truck")
            local sta = trk and trk:FindFirstChild("Starter")
            if sta then
                return sta:FindFirstChild("Prompt", true) or sta:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
        end

        if jobRemote then jobRemote:FireServer("Truck") end
        placeBases()
        suppressMap()

        while truckRunning do
            local cycleStart = os.clock()
            local arrivedAtDrop = false

            -- Step 1: request job until arrow reaches drop zone (index 4)
            while truckRunning and not arrivedAtDrop do
                local _arrowCount = 0
                local _arrowPos   = nil

                if jobRemote then jobRemote:FireServer("Truck") end

                local starter = findTruckStarter()
                if starter then firePrompt(starter) end

                -- listen for SetArrow events temporarily
                local arrowConn
                arrowConn = jobRemote and jobRemote.OnClientEvent:Connect(function(evt, pos)
                    if evt == "SetArrow" and typeof(pos) == "Vector3" then
                        _arrowCount += 1
                        _arrowPos    = pos
                    elseif evt == "Cleanup" then
                        _arrowCount = 0
                        _arrowPos   = nil
                    end
                end)

                local t0 = os.clock()
                repeat task.wait(0.05) until _arrowCount >= 2 or (os.clock() - t0) > 0.5

                if arrowConn then arrowConn:Disconnect() end

                if _arrowCount >= 2 and _arrowPos then
                    local idx = findTruckArea(_arrowPos)
                    if idx == 4 then arrivedAtDrop = true end
                end
            end
            if not truckRunning then break end

            -- Step 2: get or spawn truck
            local truck = getPlayerVehicle()
            if not truck then
                teleportCharacter(CFrame.new(TRUCK_SEAT_POS) + Vector3.new(0, 3, 0))

                local spawner = workspace.Etc.Job.Truck.Spawner
                local spawnPart = spawner:FindFirstChild("Part") or spawner:WaitForChild("Part", 3)
                if spawnPart then
                    teleportCharacter(spawnPart.CFrame + Vector3.new(0, 2, 0))
                end

                local deadline = os.clock() + 6
                while truckRunning and not truck do
                    spawnPart = spawner:FindFirstChild("Part")
                    local prom = spawnPart and (spawnPart:FindFirstChild("Prompt") or spawnPart:FindFirstChildWhichIsA("ProximityPrompt", true))
                    if prom then firePrompt(prom) end

                    local t1 = os.clock()
                    repeat
                        truck = getPlayerVehicle()
                        task.wait(0.05)
                    until truck or (os.clock() - t1) > 0.4

                    if (os.clock() - deadline) > 0 and spawnPart then
                        teleportCharacter(spawnPart.CFrame + Vector3.new(0, 2, 0))
                        deadline = os.clock() + 6
                    end
                end
            end
            if not truckRunning or not truck then continue end

            task.wait(0.7)

            -- Remove trailers
            local trailerConn
            trailerConn = truck.ChildAdded:Connect(function(child)
                if child.Name:lower():find("trailer") then
                    task.defer(function() pcall(child.Destroy, child) end)
                end
            end)
            for _, c in ipairs(truck:GetChildren()) do
                if c.Name:lower():find("trailer") then pcall(c.Destroy, c) end
            end

            -- Sit in truck
            local driveSeat = truck:WaitForChild("DriveSeat", 5)
            if driveSeat then
                local sitPrompt = driveSeat:WaitForChild("PromptDriveSeat", 3)
                if sitPrompt then
                    teleportCharacter(driveSeat.CFrame + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                    firePrompt(sitPrompt)
                end
            end

            -- Wait until seated
            local t2 = os.clock()
            while truckRunning do
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.SeatPart then
                    if driveSeat and hum.SeatPart ~= driveSeat then
                        hum.Sit = false
                        task.wait(0.1)
                        local rp = driveSeat:FindFirstChild("PromptDriveSeat")
                        if rp then
                            teleportCharacter(driveSeat.CFrame + Vector3.new(0, 3, 0))
                            task.wait(0.1)
                            firePrompt(rp)
                        end
                    else
                        break
                    end
                end
                if (os.clock() - t2) > 1.5 and driveSeat then
                    local rp = driveSeat:FindFirstChild("PromptDriveSeat")
                    if rp then
                        teleportCharacter(driveSeat.CFrame + Vector3.new(0, 3, 0))
                        task.wait(0.1)
                        firePrompt(rp)
                    end
                end
                task.wait(0.1)
                if (os.clock() - t2) > 6 then break end
            end

            if trailerConn then trailerConn:Disconnect(); trailerConn = nil end
            for _, c in ipairs(truck:GetChildren()) do
                if c.Name:lower():find("trailer") then pcall(c.Destroy, c) end
            end

            if not truckRunning then break end

            -- Step 3: teleport truck to Malang (retry up to 10x)
            for attempt = 1, 10 do
                truck:PivotTo(MALANG_BASE_CF)
                task.wait(0.25)
                if not (truck and truck.Parent) then break end

                local tpos = truck:GetPivot().Position
                if (tpos - MALANG_BASE_CF.Position).Magnitude < 150 then break end

                -- Detach
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Sit = false end

                local t3 = os.clock()
                while truckRunning and hum and hum.SeatPart do
                    hum.Sit = false
                    task.wait(0.05)
                    if (os.clock() - t3) > 1.2 then break end
                end
                task.wait(0.15)

                driveSeat = truck:FindFirstChild("DriveSeat") or truck:WaitForChild("DriveSeat", 2)
                local rp2 = driveSeat and (driveSeat:FindFirstChild("PromptDriveSeat") or driveSeat:FindFirstChildWhichIsA("ProximityPrompt", true))
                if driveSeat and rp2 then
                    teleportCharacter(driveSeat.CFrame + Vector3.new(0, 3, 0))
                    task.wait(0.1)
                    firePrompt(rp2)
                end

                local t4 = os.clock()
                while truckRunning do
                    local char2 = LocalPlayer.Character
                    local hum2  = char2 and char2:FindFirstChildOfClass("Humanoid")
                    if hum2 and hum2.SeatPart and (not driveSeat or hum2.SeatPart == driveSeat) then break end
                    if (os.clock() - t4) > 1.2 and driveSeat and rp2 then
                        teleportCharacter(driveSeat.CFrame + Vector3.new(0, 3, 0))
                        task.wait(0.1)
                        firePrompt(rp2)
                    end
                    task.wait(0.1)
                    if (os.clock() - t4) > 5 then break end
                end

                for _, c in ipairs(truck:GetChildren()) do
                    if c.Name:lower():find("trailer") then pcall(c.Destroy, c) end
                end
                task.wait(0.2)
            end

            if not (truck and truck.Parent) then continue end
            if (truck:GetPivot().Position - MALANG_BASE_CF.Position).Magnitude >= 150 then continue end

            -- Step 4: wait for delay countdown
            local remaining = truckDelay - (os.clock() - cycleStart)
            if remaining > 0 then
                setCountdownBar(remaining)
                if _cdBarLabel then _cdBarLabel.Text = string.format("%ds", math.ceil(remaining)) end

                local prev = nil
                while truckRunning do
                    local elapsed = os.clock() - cycleStart
                    local left    = truckDelay - elapsed
                    if left <= 0 then break end
                    local ceiled = math.ceil(left)
                    if ceiled ~= prev then
                        if _cdBarLabel then _cdBarLabel.Text = string.format("%ds", ceiled) end
                        if _rfParagraphRefs.truckDelayCountdown then
                            _rfParagraphRefs.truckDelayCountdown:SetDesc(string.format("%ds", ceiled))
                        end
                        prev = ceiled
                    end
                    task.wait(0.1)
                end
            end

            if _cdBarLabel then _cdBarLabel.Text = "0s" end
            if _rfParagraphRefs.truckDelayCountdown then
                _rfParagraphRefs.truckDelayCountdown:SetDesc("0s")
            end
            resetCountdown()

            if not truckRunning then break end

            -- Step 5: deliver — read cash before/after
            local cashBefore = getCash()
            truck:PivotTo(CFrame.new(MALANG_DELIVER.Position))

            if cashBefore > 0 then
                local t5 = os.clock()
                while truckRunning do
                    local cashNow = getCash()
                    if cashNow > cashBefore then
                        local income = cashNow - cashBefore

                        truckCycleCount   += 1
                        truckTotalEarned  += income
                        truckLastEarned    = income

                        table.insert(truckEarnSamples, { earned = income, duration = os.clock() - cycleStart })
                        while #truckEarnSamples > 6 do table.remove(truckEarnSamples, 1) end

                        local sumE, sumD = 0, 0
                        for _, s in ipairs(truckEarnSamples) do sumE += s.earned; sumD += s.duration end
                        if sumD > 0 then truckEarnPerHour = (sumE / sumD) * 3600 end

                        if webhookEnabled then
                            task.spawn(function() sendWebhook(income) end)
                        end
                        break
                    end
                    if (os.clock() - t5) > 10 then break end
                    task.wait()
                end
            end

            -- Detach and return
            local char3 = LocalPlayer.Character
            local hum3  = char3 and char3:FindFirstChildOfClass("Humanoid")
            if hum3 then hum3.Sit = false end

            teleportCharacter(SURABAYA_SPAWN)
            if jobRemote then jobRemote:FireServer("Truck") end

            local starter2 = findTruckStarter()
            if starter2 then firePrompt(starter2) end
        end
    end)
end

-- ================================================================
-- BARISTA HELPERS
-- ================================================================
local function baristaSmartTeleport(destination)
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    local targetCF
    if typeof(destination) == "CFrame" then
        targetCF = destination
    elseif type(destination) == "string" then
        local obj = workspace:FindFirstChild(destination, true)
        if obj then
            if obj:IsA("BasePart") then
                targetCF = obj.CFrame * CFrame.new(0, 0, -3)
            elseif obj:IsA("Model") then
                targetCF = obj:GetPivot() * CFrame.new(0, 0, -3)
            end
        end
    end

    if not targetCF then return end

    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local seat    = hum.SeatPart
        local vehicle = seat.Parent
        if vehicle and vehicle:IsA("Model") then
            seat.AssemblyLinearVelocity  = Vector3.zero
            seat.AssemblyAngularVelocity = Vector3.zero
            vehicle:PivotTo(targetCF)
            task.wait(0.05)
            seat.AssemblyLinearVelocity  = Vector3.zero
            seat.AssemblyAngularVelocity = Vector3.zero
        end
    elseif hrp then
        hrp.CFrame = targetCF
    end
end

local function baristaGetMenuId(menuName)
    if not BaristaMenu or not menuName or menuName == "" then return nil end
    for id, data in pairs(BaristaMenu.Items) do
        if data.name then
            if data.name.id == menuName or data.name.en == menuName then
                return id
            end
        end
    end
end

local function baristaScanOrder()
    local dialog = playerGui:FindFirstChild("NpcDialog")
    if not dialog then return nil end

    local textObj
    if dialog:IsA("TextLabel") or dialog:IsA("TextButton") or dialog:IsA("TextBox") then
        textObj = dialog
    else
        textObj = dialog:FindFirstChildWhichIsA("TextLabel", true)
    end
    if not textObj or textObj.Text == "" then return nil end

    local text = textObj.Text
    local menuName, flavour

    menuName, flavour = text:match("[Pp]esan%s+(.+),%s*[Rr]asa%s+(.+)%s+[Yy]a")
    if not menuName then menuName = text:match("[Pp]esan%s+(.+)%s+[Yy]a") end
    if not menuName then return nil end

    menuName = menuName:gsub("^%s+", ""):gsub("%s+$", "")
    if flavour then flavour = flavour:gsub("^%s+", ""):gsub("%s+$", "") end

    local menuId = baristaGetMenuId(menuName)
    if not menuId then return nil end

    baristaCurrentOrder = {
        Menu    = menuName,
        MenuId  = menuId,
        Flavour = flavour,
        Steps   = BaristaMenu and BaristaMenu.Items[menuId] and BaristaMenu.Items[menuId].steps,
    }

    baristaCurrentMenu    = menuName
    baristaCurrentFlavour = flavour or "-"

    return baristaCurrentOrder
end

local function baristaWaitOrder(timeout)
    local deadline = os.clock() + (timeout or 10)
    while os.clock() < deadline do
        local order = baristaScanOrder()
        if order then return order end
        task.wait(0.2)
    end
end

local function baristaSelectFlavour()
    local flavour = baristaCurrentOrder and baristaCurrentOrder.Flavour
    if not flavour or flavour == "" then return false end

    local picker = playerGui:FindFirstChild("Job") and playerGui.Job:FindFirstChild("ChoicePicker")
    local grid   = picker and picker:FindFirstChild("Grid")
    if not grid then return false end

    local btn = grid:FindFirstChild(flavour)
    if not btn then
        for _, child in ipairs(grid:GetChildren()) do
            if child.Name:lower() == flavour:lower() or child.Name:find(flavour) then
                btn = child; break
            end
        end
    end
    if not btn then return false end

    clickGuiButton(btn)
    task.wait(1)
    return true
end

-- Brew minigame controller (predictive PID)
local function runAutoBrew()
    local brewGui = playerGui:WaitForChild("Job"):WaitForChild("BrewMinigame")
    local track   = brewGui:WaitForChild("Track")
    local zone    = track:WaitForChild("Zone")
    local needle  = track:WaitForChild("Needle")

    local deadline = os.clock() + 10
    while not brewGui.Visible and os.clock() < deadline do task.wait(0.05) end
    if not brewGui.Visible then return false end

    local holding  = false
    local lastX    = needle.Position.X.Scale
    local lastTime = os.clock()

    local function setHold(state)
        if holding == state then return end
        holding = state
        VirtualInputManager:SendKeyEvent(state, Enum.KeyCode.Space, false, game)
    end

    while brewGui.Parent and brewGui.Visible do
        local now = os.clock()
        local dt  = now - lastTime
        if dt > 0 then
            local needleX  = needle.Position.X.Scale
            local zoneX    = zone.Position.X.Scale
            local zoneW    = zone.Size.X.Scale
            local targetX  = zoneX + zoneW / 2
            local velocity = (needleX - lastX) / dt

            local predTime = velocity > 0 and 0.30 or 0.08
            local predX    = needleX + velocity * predTime
            local error    = targetX - predX
            local tol      = 0.012

            if error > tol then
                setHold(true)
            elseif error < -tol then
                setHold(false)
            else
                if velocity > 0.025 then setHold(false)
                elseif velocity < -0.025 then setHold(false)
                else setHold(false)
                end
            end

            lastX    = needleX
            lastTime = now
        end
        task.wait(0.01)
    end

    setHold(false)
    return true
end

-- ================================================================
-- BARISTA DRINK RECIPES
-- Each returns true on success
-- ================================================================
local Stations = {
    BeanHopper     = function() return workspace.Barista.Stations.BeanHopper.BaristaStationPrompt     end,
    Brewer         = function() return workspace.Barista.Stations.Brewer.BaristaStationPrompt         end,
    Milk           = function() return workspace.Barista.Stations.Milk.BaristaStationPrompt           end,
    FlavourBottle  = function() return workspace.Barista.Stations.FlavourBottle.BaristaStationPrompt  end,
    Steamer        = function() return workspace.Barista.Stations.Steamer.BaristaStationPrompt        end,
    IceMaker       = function() return workspace.Barista.Stations.IceMaker.BaristaStationPrompt       end,
    WaterTap       = function() return workspace.Barista.Stations.WaterTap.BaristaStationPrompt       end,
    ChocolateJar   = function() return workspace.Barista.Stations.ChocolateJar.BaristaStationPrompt   end,
    CreamDispenser = function() return workspace.Barista.Stations.CreamDispenser.BaristaStationPrompt end,
    TeaBox         = function() return workspace.Barista.Stations.TeaBox.BaristaStationPrompt         end,
    MatchaJar      = function() return workspace.Barista.Stations.MatchaJar.BaristaStationPrompt      end,
    BobaPot        = function() return workspace.Barista.Stations.BobaPot.BaristaStationPrompt        end,
    LemonBoard     = function() return workspace.Barista.Stations.LemonBoard.BaristaStationPrompt     end,
    Carbonator     = function() return workspace.Barista.Stations.Carbonator.BaristaStationPrompt     end,
}

local CF = {
    BeanHopper     = CFrame.new(-27.46, 24.61,  8416.72),
    Brewer         = nil, -- fire at BeanHopper position, prompt is on Brewer object
    Milk           = CFrame.new(-13.96, 24.01,  8427.20),
    FlavourBottle  = CFrame.new(-25.90, 24.57,  8441.20),
    Steamer        = CFrame.new(-23.85, 24.61,  8413.78),
    IceMaker       = CFrame.new( -5.73, 24.63,  8415.39),
    WaterTap       = CFrame.new(-41.09, 23.02,  8436.42),
    ChocolateJar   = CFrame.new(-20.89, 24.57,  8436.18),
    CreamDispenser = CFrame.new(-34.14, 24.57,  8443.18),
    TeaBox         = CFrame.new(-16.11, 24.57,  8431.05),
    MatchaJar      = CFrame.new(-18.60, 24.57,  8433.67),
    BobaPot        = CFrame.new(-23.34, 24.57,  8438.54),
    LemonBoard     = CFrame.new(-28.25, 24.57,  8443.58),
    Carbonator     = CFrame.new(-36.30, 24.57,  8441.02),
    CupRack        = CFrame.new(-11.64, 24.61,  8409.11),
    Cashier        = CFrame.new(-32.88, 23.81,  8422.71),
}

local function step(cfKey, stationKey)
    baristaSmartTeleport(CF[cfKey])
    task.wait(1)
    local ok, prompt = pcall(Stations[stationKey])
    if ok and prompt then firePrompt(prompt) end
    task.wait(1)
end

local function stepBeans()
    baristaSmartTeleport(CF.BeanHopper)
    task.wait(1)
    local _, p = pcall(Stations.BeanHopper)
    if p then firePrompt(p) end
    task.wait(1)

    local _, p2 = pcall(Stations.Brewer)
    if p2 then firePrompt(p2) end
    task.wait(0.2)

    local brewOk = runAutoBrew()
    if not brewOk then return false end
    task.wait(1)
    return true
end

local function doKopiHitam()
    return stepBeans()
end

local function doCappuccino()
    if not stepBeans() then return false end
    step("Milk",          "Milk")
    step("FlavourBottle", "FlavourBottle")
    if not baristaSelectFlavour() then return false end
    step("Steamer",       "Steamer")
    return true
end

local function doEsKopiSusu()
    if not stepBeans() then return false end
    step("Milk",          "Milk")
    step("FlavourBottle", "FlavourBottle")
    if not baristaSelectFlavour() then return false end
    step("IceMaker",      "IceMaker")
    return true
end

local function doAmericano()
    if not stepBeans() then return false end
    step("WaterTap", "WaterTap")
    return true
end

local function doLatte()
    if not stepBeans() then return false end
    step("Milk", "Milk")
    return true
end

local function doHotChocolate()
    step("Milk",         "Milk")
    step("ChocolateJar", "ChocolateJar")
    return true
end

local function doMocha()
    if not stepBeans() then return false end
    step("Milk",         "Milk")
    step("ChocolateJar", "ChocolateJar")
    return true
end

local function doMacchiato()
    if not stepBeans() then return false end
    step("Steamer", "Steamer")
    return true
end

local function doFrappuccino()
    if not stepBeans() then return false end
    step("Milk",          "Milk")
    step("CreamDispenser","CreamDispenser")
    step("IceMaker",      "IceMaker")
    return true
end

local function doTea()
    step("WaterTap", "WaterTap")
    step("TeaBox",   "TeaBox")
    return true
end

local function doThaiTea()
    step("WaterTap", "WaterTap")
    step("TeaBox",   "TeaBox")
    step("Milk",     "Milk")
    step("IceMaker", "IceMaker")
    return true
end

local function doMatcha()
    step("WaterTap", "WaterTap")
    step("MatchaJar","MatchaJar")
    step("Milk",     "Milk")
    return true
end

local function doBubbleTea()
    step("WaterTap", "WaterTap")
    step("TeaBox",   "TeaBox")
    step("Milk",     "Milk")
    step("BobaPot",  "BobaPot")
    step("IceMaker", "IceMaker")
    return true
end

local function doSoda()
    step("WaterTap",  "WaterTap")
    step("Carbonator","Carbonator")
    step("IceMaker",  "IceMaker")
    return true
end

local function doLemonade()
    step("WaterTap",  "WaterTap")
    step("Carbonator","Carbonator")
    step("LemonBoard","LemonBoard")
    step("IceMaker",  "IceMaker")
    return true
end

local DRINK_MAP = {
    KopiHitam    = doKopiHitam,
    Cappuccino   = doCappuccino,
    EsKopiSusu   = doEsKopiSusu,
    Americano    = doAmericano,
    Latte        = doLatte,
    HotChocolate = doHotChocolate,
    Mocha        = doMocha,
    Macchiato    = doMacchiato,
    Frappuccino  = doFrappuccino,
    Tea          = doTea,
    ThaiTea      = doThaiTea,
    Matcha       = doMatcha,
    BubbleTea    = doBubbleTea,
    Soda         = doSoda,
    Lemonade     = doLemonade,
}

-- ================================================================
-- BARISTA SINGLE CYCLE
-- ================================================================
local function runBaristaOnce()
    -- 1. Teleport to cashier
    baristaSmartTeleport(CF.Cashier)
    task.wait(1)

    -- 2. Find nearest customer with serve prompt
    local customers      = workspace:FindFirstChild("BaristaCustomers")
    local servePrompt    = nil
    local currentCustomer = nil
    local deadline       = os.clock() + 30

    while not servePrompt and os.clock() < deadline do
        if customers then
            local best = 6
            for _, customer in ipairs(customers:GetChildren()) do
                local hrp = customer:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local prom = hrp:FindFirstChild("BaristaServePrompt")
                    if prom and prom:IsA("ProximityPrompt") and prom.Enabled then
                        local dist = (hrp.Position - CF.Cashier.Position).Magnitude
                        if dist <= best then
                            best            = dist
                            servePrompt     = prom
                            currentCustomer = customer
                        end
                    end
                end
            end
        end
        if not servePrompt then task.wait(0.2) end
    end

    if not servePrompt then return end
    firePrompt(servePrompt)
    task.wait(1)

    -- 3. Scan order
    baristaCurrentOrder = nil
    local order = baristaWaitOrder(10)
    if not order then return end

    task.wait(1)
    pressSpace(1, 0.5)
    task.wait(1)

    -- 4. Get cup from CupRack
    baristaSmartTeleport(CF.CupRack)
    task.wait(1)

    ReplicatedStorage
        :WaitForChild("NetworkContainer")
        :WaitForChild("RemoteEvents")
        :WaitForChild("Barista")
        :FireServer("Station", "CupRack")

    local picker = playerGui:WaitForChild("Job", 5):WaitForChild("ChoicePicker", 5)
    task.wait(1)

    local menuId  = baristaCurrentOrder.MenuId
    local cupGrid = picker and picker:WaitForChild("Grid", 5)
    local cupBtn  = cupGrid and cupGrid:FindFirstChild(menuId)

    if not cupBtn and cupGrid then
        for _, child in ipairs(cupGrid:GetChildren()) do
            if child.Name:lower() == menuId:lower() or child.Name:find(menuId) then
                cupBtn = child; break
            end
        end
    end

    if not cupBtn then return end
    clickGuiButton(cupBtn)
    task.wait(1)

    -- 5. Make drink
    local drinkFn = DRINK_MAP[menuId]
    if not drinkFn then return end
    if not drinkFn() then return end

    -- 6. Return to cashier and serve
    baristaSmartTeleport(CF.Cashier)
    task.wait(1)

    if not (currentCustomer and currentCustomer.Parent) then return end

    local servePrompt2 = nil
    local deadline2    = os.clock() + 30

    while not servePrompt2 and os.clock() < deadline2 do
        if not (currentCustomer and currentCustomer.Parent) then break end
        local hrp2 = currentCustomer:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            local dist2 = (hrp2.Position - CF.Cashier.Position).Magnitude
            if dist2 <= 6 then
                local prom2 = hrp2:FindFirstChild("BaristaServePrompt")
                if prom2 and prom2:IsA("ProximityPrompt") and prom2.Enabled then
                    servePrompt2 = prom2
                end
            end
        end
        if not servePrompt2 then task.wait(0.2) end
    end

    if not servePrompt2 then return end
    firePrompt(servePrompt2)
    task.wait(0.5)

    baristaOrders       += 1
    baristaCurrentMenu    = "-"
    baristaCurrentFlavour = "-"
    task.wait(1)
end

-- ================================================================
-- BARISTA LOOP
-- ================================================================
local function baristaLoop()
    task.spawn(function()
        -- Start Barista job via NPC
        for _ = 1, 5 do
            baristaSmartTeleport("NPC_BARISTA_MANAGER")
            task.wait(0.2)
        end
        task.wait(1)

        local t0 = os.clock()
        while os.clock() - t0 < 1 do
            local npc = workspace.Barista.NPC_BARISTA_MANAGER.Head:FindFirstChild("DialogPrompt")
            if npc then firePrompt(npc) end
            task.wait(0.5)
        end
        pressSpace(5, 0.2)
        task.wait(1)

        while baristaRunning do
            runBaristaOnce()
            task.wait(0.1)
        end
    end)
end

-- ================================================================
-- CONFIG SYSTEM
-- ================================================================
local HttpSvc   = game:GetService("HttpService")
local CFG_FOLDER = "Projectsion/config"

local function cfgEnsure()
    pcall(function()
        if isfolder and not isfolder("Projectsion")  then makefolder("Projectsion") end
        if isfolder and not isfolder(CFG_FOLDER)     then makefolder(CFG_FOLDER)    end
    end)
end

local function cfgPath(name) return CFG_FOLDER .. "/" .. name .. ".json" end

local function cfgList()
    local out = {}
    pcall(function()
        if not listfiles then return end
        cfgEnsure()
        for _, f in ipairs(listfiles(CFG_FOLDER)) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end)
    return out
end

local _rfToggleAutoFarm  = nil
local _rfSliderDelay     = nil
local _rfToggleWebhook   = nil
local _rfInputWebhook    = nil
local _rfToggleBarista   = nil

local function cfgCurrentData()
    return {
        AutoFarmTruck  = truckRunning,
        TeleportDelay  = truckDelay,
        WebhookEnabled = webhookEnabled,
        WebhookUrl     = webhookUrl,
        AutoBarista    = baristaRunning,
    }
end

local function cfgApply(data)
    pcall(function() if data.AutoFarmTruck  ~= nil and _rfToggleAutoFarm then _rfToggleAutoFarm:Set(data.AutoFarmTruck)   end end)
    pcall(function() if data.TeleportDelay  ~= nil and _rfSliderDelay    then _rfSliderDelay:Set(data.TeleportDelay)      end end)
    pcall(function() if data.WebhookEnabled ~= nil and _rfToggleWebhook  then _rfToggleWebhook:Set(data.WebhookEnabled)   end end)
    pcall(function() if data.WebhookUrl     ~= nil and _rfInputWebhook   then _rfInputWebhook:Set(data.WebhookUrl)        end end)
    pcall(function() if data.AutoBarista    ~= nil and _rfToggleBarista  then _rfToggleBarista:Set(data.AutoBarista)      end end)
end

local function cfgSave(name)
    pcall(function()
        if not writefile then return end
        cfgEnsure()
        writefile(cfgPath(name), HttpSvc:JSONEncode({
            __version  = 1.3,
            __elements = cfgCurrentData(),
            __autoload = false,
            __custom   = {},
        }))
    end)
end

local function cfgLoad(name)
    local ok, data = false, nil
    pcall(function()
        if not (readfile and isfile) then return end
        local p = cfgPath(name)
        if isfile(p) then
            ok, data = pcall(function() return HttpSvc:JSONDecode(readfile(p)) end)
        end
    end)
    if ok and data and data.__elements then cfgApply(data.__elements) end
    return ok, data
end

local function cfgDelete(name)
    pcall(function()
        if delfile and isfile then
            local p = cfgPath(name)
            if isfile(p) then delfile(p) end
        end
    end)
end

-- ================================================================
-- RAYFIELD UI
-- ================================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name             = "Projectsion | CDID",
    LoadingTitle     = "Projectsion Hub",
    LoadingSubtitle  = "Car Driving Indonesia",
    ConfigurationSaving = { Enabled = false },
    KeySystem        = false,
})

Rayfield:Notify({
    Title    = "Projectsion",
    Content  = "Truck + Barista autofarm loaded.",
    Duration = 4,
    Image    = 4483362458,
})

-- Paragraph wrapper: SetDesc(text)
local function rfParagraph(tab, label, defaultVal)
    local lbl = tab:CreateLabel(label .. ":  " .. defaultVal)
    local ref = {
        SetDesc = function(self, val)
            pcall(function() lbl:Set(label .. ":  " .. val) end)
        end
    }
    return ref
end

-- ================================================================
-- TAB: MAIN  (Truck + Barista)
-- ================================================================
local tabMain = Window:CreateTab("Main", 4483362458)

-- ── TRUCK ──────────────────────────────────────────────────────
tabMain:CreateSection("Auto Truck")

_rfToggleAutoFarm = tabMain:CreateToggle({
    Name         = "Auto Farm Truck",
    CurrentValue = false,
    Flag         = "AutoFarmTruck",
    Callback     = function(val)
        truckRunning = val
        if val then
            if not truckStartTick then truckStartTick = os.clock() end
            truckLoop()
        else
            pcall(function() RunService:Set3dRenderingEnabled(true) end)
        end
    end,
})

_rfSliderDelay = tabMain:CreateSlider({
    Name         = "Job Delay (seconds)",
    Range        = { 0, 50 },
    Increment    = 1,
    CurrentValue = truckDelay,
    Flag         = "TeleportDelay",
    Callback     = function(val)
        truckDelay = val
    end,
})

_rfToggleWebhook = tabMain:CreateToggle({
    Name         = "Enable Webhook",
    CurrentValue = false,
    Flag         = "WebhookEnabled",
    Callback     = function(val)
        webhookEnabled = val
    end,
})

_rfInputWebhook = tabMain:CreateInput({
    Name                     = "Webhook URL",
    PlaceholderText          = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Flag                     = "WebhookUrl",
    Callback                 = function(val)
        webhookUrl = val
    end,
})

-- ── BARISTA ────────────────────────────────────────────────────
tabMain:CreateSection("Auto Barista")

_rfToggleBarista = tabMain:CreateToggle({
    Name         = "Auto Farm Barista",
    CurrentValue = false,
    Flag         = "AutoBarista",
    Callback     = function(val)
        baristaRunning = val
        if val then
            if not baristaStartTick then baristaStartTick = os.clock() end
            -- Private server guard (CDI Jakarta place)
            if #Players:GetChildren() > 1 then
                Rayfield:Notify({ Title = "Barista", Content = "Private Server required!", Duration = 4 })
                _rfToggleBarista:Set(false)
                baristaRunning = false
                return
            end
            if game.PlaceId ~= 14005966837 then
                Rayfield:Notify({ Title = "Barista", Content = "Must be in Jakarta!", Duration = 4 })
                _rfToggleBarista:Set(false)
                baristaRunning = false
                return
            end
            baristaLoop()
        end
    end,
})

-- ================================================================
-- TAB: STATS
-- ================================================================
local tabStats = Window:CreateTab("Stats", 4483362458)

-- ── TRUCK STATS ────────────────────────────────────────────────
tabStats:CreateSection("Truck")

local rfTruckTime     = rfParagraph(tabStats, "Time Elapsed",    "00:00")
local rfTruckMoney    = rfParagraph(tabStats, "Current Money",   "Rp 0")
local rfTruckTotal    = rfParagraph(tabStats, "Total Earning",   "Rp 0")
local rfTruckPerHour  = rfParagraph(tabStats, "Earning / Hour",  "Rp 0")
local rfTruckLast     = rfParagraph(tabStats, "You Got",         "Rp 0")
local rfTruckCycles   = rfParagraph(tabStats, "Cycles Done",     "0")
local rfTruckCountdown = rfParagraph(tabStats, "Delay Countdown", "0s")

_rfParagraphRefs.truckDelayCountdown = rfTruckCountdown

-- ── BARISTA STATS ──────────────────────────────────────────────
tabStats:CreateSection("Barista")

local rfBaristaStatus  = rfParagraph(tabStats, "Status",          "Stopped")
local rfBaristaOrders  = rfParagraph(tabStats, "Orders Done",     "0")
local rfBaristaElapsed = rfParagraph(tabStats, "Time Elapsed",    "00:00:00")
local rfBaristaMenu    = rfParagraph(tabStats, "Current Menu",    "-")
local rfBaristaTaro    = rfParagraph(tabStats, "Current Flavour", "-")

-- ================================================================
-- STATS UPDATE LOOP
-- ================================================================
task.spawn(function()
    while true do
        task.wait(1)

        -- Truck
        if truckRunning and truckStartTick then
            rfTruckTime:SetDesc(fmtTime(os.clock() - truckStartTick))
        end
        rfTruckMoney:SetDesc(fmtMoney(getCash()))
        rfTruckTotal:SetDesc(fmtMoney(truckTotalEarned))
        rfTruckLast:SetDesc(fmtMoney(truckLastEarned))
        rfTruckCycles:SetDesc(tostring(truckCycleCount))
        if truckEarnPerHour > 0 then
            rfTruckPerHour:SetDesc(fmtEarnPerHour(truckEarnPerHour))
        elseif truckRunning then
            rfTruckPerHour:SetDesc("Calculating...")
        end

        -- Countdown bar label sync
        if _cdEndTime then
            local left = _cdEndTime - os.clock()
            if left > 0 then
                rfTruckCountdown:SetDesc(string.format("%ds", math.ceil(left)))
            else
                rfTruckCountdown:SetDesc("0s")
            end
        end

        -- Barista
        if baristaRunning and baristaStartTick then
            local elapsed = os.time() - baristaStartTick
            rfBaristaElapsed:SetDesc(fmtTimeFull(elapsed))
            rfBaristaStatus:SetDesc("Running")
        else
            rfBaristaStatus:SetDesc("Stopped")
        end

        rfBaristaOrders:SetDesc(tostring(baristaOrders))
        rfBaristaMenu:SetDesc(baristaCurrentMenu or "-")
        rfBaristaTaro:SetDesc(baristaCurrentFlavour or "-")

        -- Suppress Job GUI
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if not pg then return end
            local job = pg:FindFirstChild("Job")
            if job and job.Enabled then job.Enabled = false end
            local mapFrame = pg:FindFirstChild("Main")
                and pg.Main:FindFirstChild("Container")
                and pg.Main.Container:FindFirstChild("Hub")
                and pg.Main.Container.Hub:FindFirstChild("MapFrame")
            if mapFrame and mapFrame.Visible then mapFrame.Visible = false end
        end)
    end
end)

-- ================================================================
-- TAB: CONFIGURATION
-- ================================================================
local tabCfg = Window:CreateTab("Configuration", 4483362458)

tabCfg:CreateSection("Theme")
local themes = { "Dark","Light","Rose","Plant","Red","Indigo","Sky","Violet","Amber","Emerald","Midnight","Crimson","Monokai Pro","Cotton Candy","Mellowsi","Rainbow" }
tabCfg:CreateDropdown({
    Name            = "Select Theme",
    Options         = themes,
    CurrentOption   = { "Dark" },
    MultipleOptions = false,
    Flag            = "SelectedTheme",
    Callback        = function(val)
        pcall(function() Rayfield:SetTheme(val) end)
    end,
})

tabCfg:CreateSection("Config Manager")

local selectedCfg = ""
local cfgNameInput = ""

local cfgDropdown = tabCfg:CreateDropdown({
    Name            = "Select Config",
    Options         = cfgList(),
    CurrentOption   = {},
    MultipleOptions = false,
    Flag            = "SelectedConfigDropdown",
    Callback        = function(val)
        selectedCfg = val
    end,
})

tabCfg:CreateInput({
    Name                     = "Config Name",
    PlaceholderText          = "Enter config name...",
    RemoveTextAfterFocusLost = false,
    Flag                     = "ConfigNameInput",
    Callback                 = function(val)
        cfgNameInput = val
    end,
})

tabCfg:CreateButton({
    Name     = "Save Config",
    Callback = function()
        if cfgNameInput == "" then
            Rayfield:Notify({ Title = "Config", Content = "Enter a name first!", Duration = 3 })
            return
        end
        cfgSave(cfgNameInput)
        selectedCfg = cfgNameInput
        Rayfield:Notify({ Title = "Config", Content = "Saved: " .. cfgNameInput, Duration = 3 })
        pcall(function() cfgDropdown:Refresh(cfgList(), cfgNameInput) end)
    end,
})

tabCfg:CreateButton({
    Name     = "Load Config",
    Callback = function()
        if selectedCfg == "" then
            Rayfield:Notify({ Title = "Config", Content = "Select a config first!", Duration = 3 })
            return
        end
        cfgLoad(selectedCfg)
        Rayfield:Notify({ Title = "Config", Content = "Loaded: " .. selectedCfg, Duration = 3 })
    end,
})

tabCfg:CreateButton({
    Name     = "Rewrite Config",
    Callback = function()
        if selectedCfg == "" then
            Rayfield:Notify({ Title = "Config", Content = "Select a config first!", Duration = 3 })
            return
        end
        local p = cfgPath(selectedCfg)
        local autoload, custom = false, {}
        if isfile and isfile(p) and readfile then
            pcall(function()
                local d = HttpSvc:JSONDecode(readfile(p))
                autoload = d.__autoload or false
                custom   = d.__custom   or {}
            end)
        end
        if writefile then
            writefile(p, HttpSvc:JSONEncode({
                __version  = 1.3,
                __elements = cfgCurrentData(),
                __autoload = autoload,
                __custom   = custom,
            }))
        end
        Rayfield:Notify({ Title = "Config", Content = "Rewritten: " .. selectedCfg, Duration = 3 })
    end,
})

tabCfg:CreateButton({
    Name     = "Delete Config",
    Callback = function()
        if selectedCfg == "" then
            Rayfield:Notify({ Title = "Config", Content = "Select a config first!", Duration = 3 })
            return
        end
        cfgDelete(selectedCfg)
        Rayfield:Notify({ Title = "Config", Content = "Deleted: " .. selectedCfg, Duration = 3 })
        selectedCfg = ""
        pcall(function() cfgDropdown:Refresh(cfgList(), nil) end)
    end,
})

tabCfg:CreateButton({
    Name     = "Set Auto Load",
    Callback = function()
        if selectedCfg == "" then
            Rayfield:Notify({ Title = "Config", Content = "Select a config first!", Duration = 3 })
            return
        end
        local all = cfgList()
        if isfile and readfile and writefile then
            for _, name in ipairs(all) do
                local p = cfgPath(name)
                if isfile(p) then
                    pcall(function()
                        local d = HttpSvc:JSONDecode(readfile(p))
                        if type(d) == "table" then
                            d.__autoload = (name == selectedCfg)
                            writefile(p, HttpSvc:JSONEncode(d))
                        end
                    end)
                end
            end
        end
        Rayfield:Notify({ Title = "Config", Content = "Auto load set to: " .. selectedCfg, Duration = 3 })
    end,
})

-- Auto-load on startup
pcall(function()
    local all = cfgList()
    if readfile and isfile then
        for _, name in ipairs(all) do
            local p = cfgPath(name)
            if isfile(p) then
                local ok, d = pcall(function() return HttpSvc:JSONDecode(readfile(p)) end)
                if ok and type(d) == "table" and d.__autoload then
                    cfgLoad(name)
                    selectedCfg = name
                    task.defer(function()
                        pcall(function() cfgDropdown:Set(name) end)
                    end)
                    break
                end
            end
        end
    end
end)