local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name             = "Projectsion | Bus Explorer Indonesia",
    LoadingTitle     = "Bus Explorer Indonesia",
    LoadingSubtitle  = "by .projectsion",
    Theme            = "Default",
    ConfigurationSaving = {
        Enabled  = true,
        FileName = "VoidlineConfig"
    },
    KeySystem = false,
})

local VirtualUser       = game:GetService("VirtualUser")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local LP                = Players.LocalPlayer
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local StatsFolder       = LP:WaitForChild("PlayerData")
local OwnedCarsFolder   = StatsFolder:WaitForChild("OwnedCars")
local CarData           = Remotes.GetClientCustomizationData:InvokeServer()
local StartUang         = StatsFolder.Uang.Value
local StartTime         = os.time()

_G.AutoFull        = false
_G.AntiAFK         = true
_G.AutoRejoin      = false
_G.blackscreen     = false
_G.HideChar        = false
_G.SelectedBus     = ""
_G.WebhookURL      = ""
_G.TotalEarning    = 0
_G.CycleCount      = 0
_G.StartTime       = os.time()
_G.AutoKickEnabled = false
_G.WebhookEnabled  = false

local TWEEN_SPEED      = 100
local ARRIVE_DELAY     = 60
local INCOME_THRESHOLD = 30_000_000
local STAFF_GROUP_ID   = 269201883

local isWaitingInZone      = false
local jobStarted           = false
local TargetUang           = 0
local lastMoney            = StatsFolder.Uang.Value
local SelectedBusToBuy     = ""
local CarListData          = {}
local pendingIncome        = 0
local SelectedAction       = "Dealership"
local SelectedTP           = "Dealership"
local isWebhookRunning     = false
local busOptions           = {}
local isCycleResetting     = false
local lockedRootPart       = nil

local lastCheckpointName   = ""
local lastCheckpointFolder = "Checkpoints"
local isRecovering         = false

local RouteData        = {}
local RouteSortedKeys  = {}
local SelectedRouteKey = ""
local LabelToKey       = {}

local StatusLabel, UangLabel, EarningLabel, TimeLabel, FPSLabel, PingLabel
local RouteRewardLabel

local BlackScreen        = Instance.new("ScreenGui")
BlackScreen.Name         = "ProjectsionBlackout"
BlackScreen.Parent       = game:GetService("CoreGui")
BlackScreen.DisplayOrder = -1
BlackScreen.Enabled      = false

local BSFrame            = Instance.new("Frame")
BSFrame.Parent           = BlackScreen
BSFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BSFrame.Size             = UDim2.new(1.5, 0, 1.5, 0)
BSFrame.Position         = UDim2.new(-0.25, 0, -0.25, 0)
BSFrame.BorderSizePixel  = 0

task.spawn(function()
    while task.wait(0.5) do
        BlackScreen.Enabled = _G.blackscreen
    end
end)

-- ── UnHeartBeat: disconnect Playfab detection RunService binds ────────────
-- Playfab's client-side cheat detection fires on Heartbeat and Stepped.
-- We scan getconnections on both signals, fingerprint by source chunk name,
-- and disconnect anything whose source resolves outside CoreScripts.
-- Called once at load; re-call after each teleport/respawn if needed.
local function UnHeartBeat()
    local signals = {
        RunService.Heartbeat,
        RunService.Stepped,
        RunService.RenderStepped,
    }
    local corePattern = "^CoreScript"
    for _, signal in ipairs(signals) do
        pcall(function()
            local conns = getconnections(signal)
            for _, conn in ipairs(conns) do
                pcall(function()
                    local info = debug.info(conn.Function, "s")
                    if info and not info:match(corePattern) then
                        local src = info:lower()
                        if src:find("playfab") or src:find("detect") or src:find("anticheat")
                           or src:find("cheat") or src:find("monitor") then
                            conn:Disable()
                        end
                    end
                end)
            end
        end)
    end
end

UnHeartBeat()

-- ── void-aware building collision stripper (from DDS rgStripModel) ────────
local function stripModel(model)
    if not model then return end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end

-- ── build raycast blacklist (from DDS rgBuildBlacklist) ──────────────────
local _rayParams      = RaycastParams.new()
_rayParams.FilterType = Enum.RaycastFilterType.Exclude
local _lastRayBuild   = 0

local function getCurrentBus()
    local spawnedFolder = Workspace:FindFirstChild("SpawnedVehicles")
    if not spawnedFolder then return nil end
    for _, veh in ipairs(spawnedFolder:GetChildren()) do
        local ownerAttr = veh:GetAttribute("Owner")
        local ownerVal  = veh:FindFirstChild("Owner")
        if (ownerAttr and tostring(ownerAttr) == LP.Name)
        or (ownerVal  and tostring(ownerVal.Value) == LP.Name)
        or veh.Name:find(LP.Name) then
            return veh
        end
    end
end

local function buildBlacklist()
    local bl = {}
    local char = LP.Character
    if char then table.insert(bl, char) end
    local bus = getCurrentBus()
    if bus then table.insert(bl, bus) end
    local am = Workspace:FindFirstChild("ActiveMissions")
    if am then table.insert(bl, am) end
    return bl
end

local function refreshRay(force)
    local now = os.clock()
    if not force and now - _lastRayBuild < 0.5 then return end
    _lastRayBuild = now
    _rayParams.FilterDescendantsInstances = buildBlacklist()
end

local RG_DOWN    = Vector3.new(0, -1000, 0)
local RG_OFFSETS = {
    Vector3.new(0, 0, 0),
    Vector3.new(0, 0,  10), Vector3.new(0, 0, -10),
    Vector3.new(10, 0, 0),  Vector3.new(-10, 0, 0),
}

local function findGroundY(origin)
    refreshRay(false)
    local highest = nil
    for i = 1, #RG_OFFSETS do
        local r = Workspace:Raycast(origin + RG_OFFSETS[i], RG_DOWN, _rayParams)
        if r then if not highest or r.Position.Y > highest then highest = r.Position.Y end end
    end
    return highest
end

local function hasGroundAt(origin)
    refreshRay(false)
    for i = 1, #RG_OFFSETS do
        if Workspace:Raycast(origin + RG_OFFSETS[i], RG_DOWN, _rayParams) then return true end
    end
    return false
end

-- ── BCA-style vehicleFlyTo with void awareness ───────────────────────────
-- Replaces BXI's Lerp/PivotTo tween with BodyVelocity + BodyGyro fly.
-- Void scanner from DDS rgFlyToTarget grafted in-loop.
local RG_SCAN_STEP   = 50
local RG_SCAN_IVTL   = 0.12
local RG_HOVER       = 12
local RG_VOID_STEP   = 300
local RG_VOID_STEPS  = 40
local RG_VOID_WAIT   = 0.1
local RG_VOID_MARGIN = 150
local RG_BRAKE_D     = 60
local RG_BRAKE_J     = 80
local RG_BRAKE_P     = 0.75
local RG_BRAKE_S     = 1.12
local RG_ACCEL       = 90
local RG_ARRIVE      = 5
local RG_CRAWL       = 6
local RG_SNAP        = 3
local RG_TURN        = 0.12
local RG_MAX_SPEED   = 230
local RG_RAY_ABOVE   = 1000
local RG_RAY_LEN     = 5000

local function findLandingY(origin)
    refreshRay(false)
    local start = Vector3.new(origin.X, origin.Y + RG_RAY_ABOVE, origin.Z)
    local r = Workspace:Raycast(start, Vector3.new(0, -RG_RAY_LEN, 0), _rayParams)
    return r and r.Position.Y or nil
end

local function brakeCap(distToStop)
    if distToStop <= 0 then return 0 end
    local a  = RG_BRAKE_D * RG_BRAKE_P
    local r  = RG_BRAKE_D / RG_BRAKE_J
    local ar = a * r
    local v  = (-ar + math.sqrt(ar * ar + 8 * a * distToStop)) / 2
    return math.max(v, 0)
end

local function pivotKeepYaw(model, position)
    local _, yaw, _ = model:GetPivot():ToOrientation()
    model:PivotTo(CFrame.new(position) * CFrame.Angles(0, yaw, 0))
end

local function vehicleFlyTo(car, targetCFrame, speed)
    if not car then return end
    local root = car.PrimaryPart or car:FindFirstChild("DriveSeat")
    if not root then return end

    refreshRay(true)

    local targetPos  = targetCFrame.Position
    local flySpeed   = speed or TWEEN_SPEED
    local arriveD    = TWEEN_SPEED > 0 and 15 or 33

    local noclipConn = RunService.Stepped:Connect(function()
        for _, v in ipairs(car:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        local char = LP.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
        stripModel(car)
    end)

    local BG = Instance.new("BodyGyro")
    BG.P         = 9e4
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.D         = 50
    BG.Parent    = root

    local BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Velocity  = Vector3.zero
    BV.Parent    = root

    local flatTarget     = Vector3.new(targetPos.X, 0, targetPos.Z)
    local curSpeed       = 0
    local moveDir        = Vector3.zero
    local smoothedLook   = car:GetPivot()
    local curDecel       = 0
    local jitterMul      = 1
    local nextJitterAt   = 0
    local nextVoidScanAt = 0
    local minDist        = math.huge
    local reached        = false

    local function crossVoid(startPos, dir, voidStartDist)
        curSpeed = 0; curDecel = 0
        BV.Velocity = Vector3.zero
        for _, v in ipairs(car:GetDescendants()) do
            if v:IsA("BasePart") then
                v.AssemblyLinearVelocity  = Vector3.zero
                v.AssemblyAngularVelocity = Vector3.zero
            end
        end
        task.wait(0.3)
        if not _G.AutoFull then return false end
        local safePos = startPos + dir * math.max(0, voidStartDist - 20)
        local safeY   = findGroundY(safePos) or startPos.Y
        pivotKeepYaw(car, Vector3.new(safePos.X, safeY + RG_HOVER, safePos.Z))
        smoothedLook = car:GetPivot(); BG.CFrame = smoothedLook
        task.wait(0.2)
        local stepPos = Vector3.new(safePos.X, safeY + RG_HOVER, safePos.Z)
        local landed  = false
        local dFlat   = (Vector3.new(stepPos.X, 0, stepPos.Z) - flatTarget).Magnitude
        for _ = 1, RG_VOID_STEPS do
            if not _G.AutoFull then return false end
            local stepDist = math.min(RG_VOID_STEP, dFlat)
            if stepDist < 5 then break end
            local nextPos   = stepPos + dir * stepDist
            local groundYN  = findLandingY(nextPos)
            local landPos
            if groundYN then
                landPos = Vector3.new(nextPos.X, groundYN + RG_HOVER, nextPos.Z)
                landed  = true
            else
                landPos = Vector3.new(nextPos.X, stepPos.Y, nextPos.Z)
            end
            pivotKeepYaw(car, landPos)
            smoothedLook = car:GetPivot(); BG.CFrame = smoothedLook
            task.wait(RG_VOID_WAIT)
            stepPos = landPos
            dFlat   = (Vector3.new(stepPos.X, 0, stepPos.Z) - flatTarget).Magnitude
            if landed then break end
        end
        if not landed then
            local safeY2 = (findLandingY(targetPos) or targetPos.Y) + RG_HOVER
            pivotKeepYaw(car, Vector3.new(targetPos.X, safeY2, targetPos.Z))
            smoothedLook = car:GetPivot(); BG.CFrame = smoothedLook
            task.wait(RG_VOID_WAIT)
        end
        task.wait(0.2)
        return true
    end

    while _G.AutoFull do
        local dt       = math.clamp(RunService.Heartbeat:Wait(), 0.005, 0.1)
        local nowClock = os.clock()
        if not BV.Parent or not BG.Parent then break end
        local pos      = root.Position
        local flatPos  = Vector3.new(pos.X, 0, pos.Z)
        local toTarget = flatTarget - flatPos
        local flatDist = toTarget.Magnitude
        if flatDist < minDist then minDist = flatDist end
        local passed = (minDist < 20) and (flatDist > minDist + 3)
        if flatDist <= RG_ARRIVE or passed then reached = true; break end
        local dirTo = toTarget / flatDist

        if nowClock >= nextVoidScanAt then
            nextVoidScanAt = nowClock + RG_SCAN_IVTL
            local ramp      = RG_BRAKE_D / RG_BRAKE_J
            local stopDist  = (curSpeed * curSpeed) / (2 * RG_BRAKE_D) + curSpeed * ramp * 0.5
            local lookAhead = math.min(math.max(150, stopDist + RG_VOID_MARGIN), 1000, flatDist)
            local voidAt    = nil
            for dv = RG_SCAN_STEP, lookAhead, RG_SCAN_STEP do
                if not hasGroundAt(pos + dirTo * dv) then voidAt = dv; break end
            end
            if voidAt then
                if not crossVoid(pos, dirTo, voidAt) then break end
                curSpeed = 0; curDecel = 0; minDist = math.huge
                nextVoidScanAt = os.clock() + 0.3
                continue
            end
        end

        if nowClock >= nextJitterAt then
            jitterMul    = 1 + (math.random(-5, 5) / 100)
            nextJitterAt = nowClock + 1.5
        end

        local cruise  = math.min(flySpeed * jitterMul, RG_MAX_SPEED)
        local cap     = math.max(brakeCap(flatDist - 1), RG_CRAWL)
        local desired = math.min(cruise, cap)
        if desired >= curSpeed then
            curDecel = 0
            curSpeed = math.min(curSpeed + RG_ACCEL * dt, desired)
        else
            curDecel = math.min(curDecel + RG_BRAKE_J * dt, RG_BRAKE_D)
            curSpeed = math.max(curSpeed - curDecel * dt, desired)
            if curSpeed > cap * RG_BRAKE_S then curSpeed = cap * RG_BRAKE_S end
        end

        moveDir = dirTo
        local velH   = moveDir * curSpeed
        local gY     = findGroundY(pos)
        local hoverY = gY and (gY + RG_HOVER) or pos.Y
        local yVel   = math.clamp((hoverY - pos.Y) * 4, -25, 25)
        BV.Velocity  = Vector3.new(velH.X, yVel, velH.Z)
        if curSpeed > 1 then
            local wantLook = CFrame.lookAt(pos, pos + Vector3.new(velH.X, 0, velH.Z))
            smoothedLook   = smoothedLook:Lerp(wantLook, RG_TURN)
            BG.CFrame      = smoothedLook
        end
    end

    BV.Velocity = Vector3.zero
    for _, v in ipairs(car:GetDescendants()) do
        if v:IsA("BasePart") then
            v.AssemblyLinearVelocity  = Vector3.zero
            v.AssemblyAngularVelocity = Vector3.zero
        end
    end

    BG:Destroy()
    BV:Destroy()
    noclipConn:Disconnect()

    for _, v in ipairs(car:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = true end
    end
    local char = LP.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

-- ── anti-afk ─────────────────────────────────────────────────────────────
for _, c in getconnections(LP.Idled) do
    pcall(c.Disable, c)
    pcall(c.Disconnect, c)
end

LP.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

-- ── staff kick ───────────────────────────────────────────────────────────
local kickedSelf     = true
local checkedPlayers = {}

local function isStaffMember(player)
    if checkedPlayers[player.UserId] ~= nil then
        return checkedPlayers[player.UserId]
    end
    local ok, result = pcall(function()
        return player:IsInGroup(STAFF_GROUP_ID)
    end)
    local inGroup = ok and result == true
    checkedPlayers[player.UserId] = inGroup
    return inGroup
end

local function kickSelfIfStaffPresent()
    if kickedSelf or not _G.AutoKickEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if isStaffMember(p) then
            kickedSelf = true
            task.wait(0.2)
            LP:Kick(
                "\n[Projectsion]\nStaff member detected in server:\n"
                .. p.Name .. " (Group " .. STAFF_GROUP_ID .. ")\nExiting safely."
            )
            return
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    task.delay(2, function()
        if not _G.AutoKickEnabled or kickedSelf then return end
        if isStaffMember(p) then
            kickedSelf = true
            task.wait(0.2)
            LP:Kick(
                "\n[Projectsion]\nStaff member detected: "
                .. p.Name .. "\nExiting safely."
            )
        end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    checkedPlayers[p.UserId] = nil
end)

task.spawn(function()
    while task.wait(8) do
        if kickedSelf then break end
        kickSelfIfStaffPresent()
    end
end)

-- ── format helpers ────────────────────────────────────────────────────────
local function formatRS(amount)
    local f = tostring(math.floor(amount))
    local k
    while true do
        f, k = string.gsub(f, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return f
end

local function formatRP(v) return "Rp " .. formatRS(v) end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d",
        math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
end

local function SetStatus(text)
    if StatusLabel then StatusLabel:Set("Status: " .. text) end
end

-- ── unlock helper ─────────────────────────────────────────────────────────
local function unlockVehicle()
    if lockedRootPart and lockedRootPart.Parent then
        lockedRootPart.Anchored                = false
        lockedRootPart.AssemblyLinearVelocity  = Vector3.zero
        lockedRootPart.AssemblyAngularVelocity = Vector3.zero
    end
    lockedRootPart = nil
end

-- ── bus list ──────────────────────────────────────────────────────────────
for _, car in pairs(OwnedCarsFolder:GetChildren()) do
    local carID   = car.Name
    local carInfo = CarData and CarData.CarData_Cars and CarData.CarData_Cars[carID]
    if carInfo then table.insert(busOptions, carID) end
end
if #busOptions == 0 then table.insert(busOptions, "Jetbus_3_RM _SHD") end
_G.SelectedBus = busOptions[1]

local ClientData = Remotes.GetClientCustomizationData:InvokeServer()
if ClientData and ClientData.CarData_Cars then
    for carID in pairs(ClientData.CarData_Cars) do
        table.insert(CarListData, carID)
    end
    table.sort(CarListData)
end

-- ── TP locations ──────────────────────────────────────────────────────────
local TP_Locations = {
    ["Dealership"]    = CFrame.new(19830.625,  266.913116,  -27910.4844,  0.999847949, 0,  0.017436387, 0, 1, 0, -0.017436387, 0,  0.999847949),
    ["Modifikasi"]    = CFrame.new(12035.499,  -21.3362789,  12740.0605, -0.573599219, 0,  0.81913656,  0, 1, 0, -0.81913656,  0, -0.573599219),
    ["Teleport City"] = CFrame.new(21795.2461, 292.439026,  -40055.918,   0.707134247, 0, -0.707079291, 0, 1, 0,  0.707079291, 0,  0.707134247),
}

-- ── route fetch ───────────────────────────────────────────────────────────
local function buildLabelForKey(key)
    local info = RouteData[key]
    if not info then return key end
    return (info.DisplayName or key)
        .. "  |  " .. formatRP(info.Reward or 0)
        .. "  (" .. tostring(info.TotalCheckpoints or "?") .. " CP)"
end

local function fetchRoutes()
    RouteData       = {}
    RouteSortedKeys = {}
    LabelToKey      = {}
    local ok, result = pcall(function()
        return Remotes:WaitForChild("GetAvailableBusRoutes"):InvokeServer("Baranangsiang")
    end)
    if not ok or type(result) ~= "table" then return false end
    for key, info in pairs(result) do
        RouteData[key] = info
        table.insert(RouteSortedKeys, key)
    end
    table.sort(RouteSortedKeys, function(a, b)
        return (RouteData[a].Reward or 0) > (RouteData[b].Reward or 0)
    end)
    if SelectedRouteKey == "" and #RouteSortedKeys > 0 then
        SelectedRouteKey = RouteSortedKeys[1]
    end
    for _, key in ipairs(RouteSortedKeys) do
        LabelToKey[buildLabelForKey(key)] = key
    end
    return true
end

local function buildRouteOptions()
    local opts = {}
    for _, key in ipairs(RouteSortedKeys) do
        table.insert(opts, buildLabelForKey(key))
    end
    return opts
end

fetchRoutes()

-- ── prepare vehicle ───────────────────────────────────────────────────────
local function prepareVehicle()
    Remotes.SpawnCar:FireServer(_G.SelectedBus)
    task.wait(2)
    local spawnedFolder = Workspace:FindFirstChild("SpawnedVehicles")
    if not spawnedFolder then return end
    local bus = nil
    for _, veh in ipairs(spawnedFolder:GetChildren()) do
        local ownerAttr = veh:GetAttribute("Owner")
        local ownerVal  = veh:FindFirstChild("Owner")
        if (ownerAttr and tostring(ownerAttr) == LP.Name)
        or (ownerVal  and tostring(ownerVal.Value) == LP.Name)
        or veh.Name:find(LP.Name) then
            bus = veh; break
        end
    end
    if not bus then
        local vehicles = spawnedFolder:GetChildren()
        bus = vehicles[#vehicles]
    end
    if not bus then return end
    local seat = bus:FindFirstChild("DriveSeat", true)
    if seat then
        local char = LP.Character or LP.CharacterAdded:Wait()
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = seat.CFrame + Vector3.new(0, 2, 0) end
        task.wait(0.3)
        local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt", true)
                    or bus:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then fireproximityprompt(prompt) end
    end
end

-- ── moveTo (BCA vehicleFlyTo replaces Lerp tween) ────────────────────────
local function getPart(name, folderName)
    local folder = Workspace:WaitForChild(folderName, 5)
    if not folder then return nil end
    local part = folder:FindFirstChild(name, true)
    if not part then
        task.wait(0.3)
        part = folder:FindFirstChild(name, true)
    end
    return part
end

local function moveTo(targetPart)
    if not targetPart then return end
    unlockVehicle()

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")

    local bus = getCurrentBus()

    if bus and hum and hum.SeatPart then
        vehicleFlyTo(bus, targetPart.CFrame + Vector3.new(0, 3, 0), TWEEN_SPEED)
    else
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local startCF  = rootPart.CFrame
        local targetCF = targetPart.CFrame + Vector3.new(0, 3, 0)

        rootPart.Anchored = true

        local noclipConn = RunService.Stepped:Connect(function()
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide              = false
                    p.AssemblyLinearVelocity  = Vector3.zero
                    p.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end)

        local distance = (targetCF.Position - startCF.Position).Magnitude
        local duration = math.max(distance / TWEEN_SPEED, 0.1)
        local elapsed  = 0

        while elapsed < duration do
            if not _G.AutoFull then break end
            local dt = RunService.Heartbeat:Wait()
            elapsed  = elapsed + dt
            rootPart.CFrame = startCF:Lerp(targetCF, math.min(elapsed / duration, 1))
        end

        rootPart.CFrame = targetCF
        noclipConn:Disconnect()

        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.CanCollide = true
            end
        end

        task.wait(0.8)
        rootPart.Anchored                = false
        rootPart.AssemblyLinearVelocity  = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.25)
        rootPart.Anchored                = true
        rootPart.AssemblyLinearVelocity  = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        lockedRootPart = rootPart
    end
end

-- ── start job ─────────────────────────────────────────────────────────────
local function startJob()
    if jobStarted then return end
    if SelectedRouteKey == "" then SetStatus("No route selected."); return end
    SetStatus("Preparing vehicle...")
    prepareVehicle()
    task.wait(2)
    if not _G.AutoFull then return end
    UnHeartBeat()
    SetStatus("Invoke job: " .. SelectedRouteKey)
    local res = Remotes:WaitForChild("StartBusJob"):InvokeServer(SelectedRouteKey, nil)
    if type(res) == "table" and res.success and res.nextCheckpointPartName then
        jobStarted           = true
        lastCheckpointName   = res.nextCheckpointPartName
        lastCheckpointFolder = "Checkpoints"
        SetStatus("Job started — moving to first checkpoint...")
        local part = getPart(res.nextCheckpointPartName, "Checkpoints")
        if part then moveTo(part) end
    else
        SetStatus("Job invoke failed, retrying...")
        task.wait(2)
        if _G.AutoFull then startJob() end
    end
end

-- ── cycle reset ───────────────────────────────────────────────────────────
local function doCycleReset()
    if isCycleResetting then return end
    isCycleResetting   = true
    isWaitingInZone    = false
    jobStarted         = false
    lastCheckpointName = ""
    unlockVehicle()
    SetStatus("Income detected — waiting 3s...")
    task.wait(3)
    if not _G.AutoFull then isCycleResetting = false; return end
    SetStatus("Destroying bus...")
    local bus = getCurrentBus()
    if bus then bus:Destroy() end
    task.wait(0.5)
    if not _G.AutoFull then isCycleResetting = false; return end
    SetStatus("Resetting character...")
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
    LP.CharacterAdded:Wait()
    task.wait(1.5)
    if not _G.AutoFull then isCycleResetting = false; return end
    SetStatus("Starting next cycle...")
    isCycleResetting = false
    startJob()
end

StatsFolder.Uang:GetPropertyChangedSignal("Value"):Connect(function()
    local newMoney = StatsFolder.Uang.Value
    if newMoney > lastMoney then
        local income = newMoney - lastMoney
        pendingIncome = pendingIncome + income
        if _G.AutoFull and not isCycleResetting and income >= INCOME_THRESHOLD then
            task.spawn(doCycleReset)
        end
    end
    lastMoney = newMoney
end)

-- ── checkpoint recovery ───────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.5) do
        if not _G.AutoFull or isRecovering or isCycleResetting then continue end
        if lastCheckpointName == "" then continue end
        local detected = false
        pcall(function()
            for _, sg in ipairs(LP.PlayerGui:GetChildren()) do
                for _, label in ipairs(sg:GetDescendants()) do
                    if label:IsA("TextLabel") or label:IsA("TextButton") then
                        if string.find(string.upper(label.Text), "RETURN TO THE CHECKPOINT") then
                            detected = true; break
                        end
                    end
                end
                if detected then break end
            end
        end)
        if detected then
            isRecovering = true
            SetStatus("Off-track — recovering to checkpoint...")
            local part = getPart(lastCheckpointName, lastCheckpointFolder)
            if part then moveTo(part) end
            task.wait(1)
            isRecovering = false
            SetStatus("Recovered — continuing...")
        end
    end
end)

-- ── BusJobUpdate handler ──────────────────────────────────────────────────
Remotes:WaitForChild("BusJobUpdate").OnClientEvent:Connect(function(action, data)
    if not _G.AutoFull then return end
    if action == "StartCheckpointWait" then
        isWaitingInZone = true; SetStatus("Waiting in zone..."); return
    end
    if action == "JobSuccess" or action == "JobCancelled" then
        isWaitingInZone    = false
        jobStarted         = false
        lastCheckpointName = ""
        SetStatus(action == "JobSuccess" and "Job success! Restarting..." or "Cancelled. Restarting...")
        task.wait(1)
        if _G.AutoFull then startJob() end
        return
    end
    if type(data) ~= "table" then return end
    local isFinal    = (action == "FinalDestination" or data.isFinalDestination)
    local targetName = isFinal and data.endTriggerPartName
                    or (data.nextCheckpointPartName or data.checkpointPartName)
    local folder     = isFinal and "BusJobEndTriggers" or "Checkpoints"
    if targetName then
        lastCheckpointName   = targetName
        lastCheckpointFolder = folder
        task.spawn(function()
            isWaitingInZone = false
            if isFinal then
                local waitStart = os.clock()
                while _G.AutoFull do
                    local remaining = ARRIVE_DELAY - (os.clock() - waitStart)
                    if remaining <= 0 then break end
                    local secs = math.floor(remaining)
                    local ms   = math.floor((remaining - secs) * 1000)
                    SetStatus(string.format("Arrive in: %02d:%03d", secs, ms))
                    task.wait(0.05)
                end
                if not _G.AutoFull then return end
                SetStatus("Moving to final stop...")
                local part = getPart(targetName, folder)
                if part then moveTo(part) end
                task.wait(1.5)
                if _G.AutoFull and not isCycleResetting and not jobStarted then
                    isWaitingInZone    = false
                    jobStarted         = false
                    lastCheckpointName = ""
                    SetStatus("Cycle done — restarting...")
                    startJob()
                end
            else
                SetStatus("Moving to: " .. targetName)
                local part = getPart(targetName, folder)
                if part then moveTo(part) end
            end
        end)
    end
end)

-- ── collision stripper heartbeat (from DDS) ───────────────────────────────
RunService.Heartbeat:Connect(function()
    if not _G.AutoFull then return end
    pcall(function()
        local char = LP.Character
        if char then stripModel(char) end
        local bus = getCurrentBus()
        if bus then
            for _, p in ipairs(bus:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end)

-- ── stats loop ────────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(1) do
        if UangLabel then
            pcall(function()
                local cur = StatsFolder.Uang.Value
                UangLabel:Set("Uang: Rp " .. formatRS(cur))
                EarningLabel:Set("Earning: Rp " .. formatRS(cur - StartUang))
                local diff = os.time() - StartTime
                TimeLabel:Set(string.format("Time: %02d:%02d:%02d",
                    math.floor(diff/3600), math.floor((diff%3600)/60), diff%60))
                local ping = tonumber(
                    game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
                        :GetValueString():split(" ")[1]) or 0
                PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
                FPSLabel:Set("FPS: " .. math.floor(1 / task.wait()))
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════════════════════════════
local MainTab = Window:CreateTab("Main Farm", "play")
MainTab:CreateSection("Autofarm Bus")

MainTab:CreateParagraph({
    Title   = "WARNING",
    Content = "USE JB5 ONLY. Auto-Kick detects group " .. STAFF_GROUP_ID .. " members.",
})

MainTab:CreateToggle({
    Name         = "On Autofarm",
    CurrentValue = false,
    Callback     = function(Value)
        _G.AutoFull = Value
        if Value then
            isWaitingInZone  = false
            jobStarted       = false
            isCycleResetting = false
            UnHeartBeat()
            task.spawn(startJob)
        else
            unlockVehicle()
            isWaitingInZone    = false
            jobStarted         = false
            isCycleResetting   = false
            lastCheckpointName = ""
            SetStatus("Idle")
        end
    end,
})

MainTab:CreateSlider({
    Name         = "Move Speed (studs/s)",
    Range        = { 50, 500 },
    Increment    = 10,
    CurrentValue = TWEEN_SPEED,
    Flag         = "TweenSpeed",
    Callback     = function(Value) TWEEN_SPEED = Value end,
})

MainTab:CreateSlider({
    Name         = "Arrive Delay (seconds)",
    Range        = { 5, 120 },
    Increment    = 5,
    CurrentValue = ARRIVE_DELAY,
    Flag         = "ArriveDelay",
    Callback     = function(Value) ARRIVE_DELAY = Value end,
})

MainTab:CreateToggle({
    Name         = "Black Screen",
    CurrentValue = false,
    Flag         = "BlackScreen",
    Callback     = function(Value) _G.blackscreen = Value end,
})

MainTab:CreateSection("Auto Stop Settings")

MainTab:CreateInput({
    Name                     = "Set Target Money",
    PlaceholderText          = "input your target",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local cleanNumber = Text:gsub("%.", "")
        TargetUang = tonumber(cleanNumber) or 0
        Rayfield:Notify({ Title = "Target Set", Content = "Target: Rp " .. formatRS(TargetUang), Duration = 3 })
    end,
})

MainTab:CreateToggle({
    Name         = "Enable Auto-Kick on Target",
    CurrentValue = false,
    Flag         = "AutoKick",
    Callback     = function(Value)
        _G.AutoKickEnabled = Value
        if Value then
            task.spawn(function()
                while _G.AutoKickEnabled do
                    if TargetUang > 0 and StatsFolder.Uang.Value >= TargetUang then
                        LP:Kick("\n[Projectsion]\nTarget reached!\nTotal: Rp " .. formatRS(StatsFolder.Uang.Value))
                        break
                    end
                    task.wait(2)
                end
            end)
        end
    end,
})

local RouteTab = Window:CreateTab("Routes", "map-pin")
RouteTab:CreateSection("Select Bus Route")

RouteTab:CreateParagraph({
    Title   = "Route Info",
    Content = "Routes sorted by reward (highest first). Refresh to reload.",
})

local routeOpts    = buildRouteOptions()
local defaultLabel = routeOpts[1] or "No routes loaded"

local RouteDropdown = RouteTab:CreateDropdown({
    Name            = "Available Routes",
    Options         = routeOpts,
    CurrentOption   = { defaultLabel },
    MultipleOptions = false,
    Callback        = function(Option)
        local label = Option[1]
        local key   = LabelToKey[label]
        if key then
            SelectedRouteKey = key
            local info = RouteData[key]
            if RouteRewardLabel then
                RouteRewardLabel:Set(
                    "Selected: " .. (info.DisplayName or key)
                    .. "  |  Reward: " .. formatRP(info.Reward or 0)
                    .. "  |  " .. tostring(info.TotalCheckpoints or "?") .. " checkpoints"
                )
            end
            SetStatus("Route: " .. (info.DisplayName or key))
        end
    end,
})

RouteRewardLabel = RouteTab:CreateLabel(
    #RouteSortedKeys > 0
        and ("Selected: "
            .. (RouteData[SelectedRouteKey] and RouteData[SelectedRouteKey].DisplayName or SelectedRouteKey)
            .. "  |  Reward: " .. formatRP(RouteData[SelectedRouteKey] and RouteData[SelectedRouteKey].Reward or 0)
            .. "  |  " .. tostring(RouteData[SelectedRouteKey] and RouteData[SelectedRouteKey].TotalCheckpoints or "?") .. " checkpoints")
        or "No route loaded.",
    "coins"
)

RouteTab:CreateButton({
    Name     = "Refresh Route List",
    Callback = function()
        if fetchRoutes() then
            local newOpts = buildRouteOptions()
            RouteDropdown:Set(newOpts)
            Rayfield:Notify({ Title = "Routes Refreshed", Content = tostring(#RouteSortedKeys) .. " routes loaded.", Duration = 3, Image = "refresh-cw" })
        else
            Rayfield:Notify({ Title = "Fetch Failed", Content = "Could not reach GetAvailableBusRoutes.", Duration = 4, Image = "alert-triangle" })
        end
    end,
})

local ConfigTab = Window:CreateTab("Configuration", "settings")
ConfigTab:CreateSection("Select Vehicle")

local BusDropdown = ConfigTab:CreateDropdown({
    Name            = "Select Owned Bus",
    Options         = busOptions,
    CurrentOption   = { busOptions[1] },
    MultipleOptions = false,
    Callback        = function(Option)
        _G.SelectedBus = Option[1]
        SetStatus("Selected: " .. _G.SelectedBus)
    end,
})

ConfigTab:CreateButton({
    Name     = "Refresh Garage List",
    Callback = function()
        local newOptions = {}
        for _, car in pairs(OwnedCarsFolder:GetChildren()) do
            table.insert(newOptions, car.Name)
        end
        BusDropdown:Set(newOptions)
    end,
})

ConfigTab:CreateSection("Webhook")

ConfigTab:CreateInput({
    Name                     = "Discord Webhook URL",
    PlaceholderText          = "Paste URL Here",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        _G.WebhookURL = Text
        Rayfield:Notify({ Title = "Webhook Updated", Content = "URL saved.", Duration = 3, Image = "link" })
    end,
})

ConfigTab:CreateToggle({
    Name         = "Enable Webhook Report",
    CurrentValue = false,
    Callback     = function(Value)
        _G.WebhookEnabled = Value
        if Value and (_G.WebhookURL == "" or not _G.WebhookURL:find("discord.com")) then
            Rayfield:Notify({ Title = "Webhook Error", Content = "Enter a valid Discord Webhook URL first!", Duration = 5, Image = "alert-triangle" })
        end
    end,
})

local SafetyTab = Window:CreateTab("Safety", "shield")
SafetyTab:CreateSection("Staff Detection")

SafetyTab:CreateParagraph({
    Title   = "How It Works",
    Content = "Monitors all players for membership in group "
        .. STAFF_GROUP_ID
        .. ". When detected, kicks YOU out of the server safely.",
})

SafetyTab:CreateToggle({
    Name         = "Auto-Kick on Staff Detection",
    CurrentValue = true,
    Flag         = "StaffKick",
    Callback     = function(Value)
        _G.AutoKickEnabled = Value
        kickedSelf = false
        if Value then
            SetStatus("Staff detection: ACTIVE")
            task.spawn(kickSelfIfStaffPresent)
        else
            SetStatus("Staff detection: OFF")
        end
    end,
})

SafetyTab:CreateButton({
    Name     = "Scan Now",
    Callback = function()
        if not _G.AutoKickEnabled then
            Rayfield:Notify({ Title = "Detection Off", Content = "Enable the toggle first.", Duration = 3, Image = "alert-triangle" })
            return
        end
        kickSelfIfStaffPresent()
        Rayfield:Notify({ Title = "Scan Complete", Content = "No staff members found.", Duration = 3, Image = "shield" })
    end,
})

SafetyTab:CreateSection("Playfab Bypass")

SafetyTab:CreateButton({
    Name     = "Re-run UnHeartBeat",
    Callback = function()
        UnHeartBeat()
        Rayfield:Notify({ Title = "UnHeartBeat", Content = "Playfab detection heartbeats disconnected.", Duration = 3, Image = "shield" })
    end,
})

local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Info Farm")
StatusLabel  = StatsTab:CreateLabel("Status: Waiting",                    "clock")
UangLabel    = StatsTab:CreateLabel("Uang: Rp " .. formatRS(StartUang),   "banknote")
EarningLabel = StatsTab:CreateLabel("Earning: Rp 0",                       "coins")
TimeLabel    = StatsTab:CreateLabel("Time: 00:00:00",                       "timer")

StatsTab:CreateSection("System Info")
FPSLabel  = StatsTab:CreateLabel("FPS: Scanning...",  "monitor")
PingLabel = StatsTab:CreateLabel("Ping: Scanning...", "wifi")

local MoreTab = Window:CreateTab("More Features", "plus-circle")
MoreTab:CreateSection("Important Features")

MoreTab:CreateToggle({
    Name         = "Anti-AFK System",
    CurrentValue = true,
    Flag         = "AntiAFK",
    Callback     = function(Value)
        _G.AntiAFK = Value
        SetStatus(_G.AntiAFK and "Anti-AFK Enabled" or "Anti-AFK Disabled")
    end,
})

MoreTab:CreateToggle({
    Name         = "Auto Rejoin",
    CurrentValue = false,
    Flag         = "AutoRejoin",
    Callback     = function(Value) _G.AutoRejoin = Value end,
})

MoreTab:CreateSection("Visual & Performance")

MoreTab:CreateButton({
    Name     = "Hide All Names",
    Callback = function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BillboardGui") then v:Destroy() end
        end
        SetStatus("Names Hidden")
    end,
})

MoreTab:CreateToggle({
    Name         = "Hide Character",
    CurrentValue = false,
    Flag         = "HideChar",
    Callback     = function(Value)
        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = Value and 1 or 0
                end
            end
        end
    end,
})

MoreTab:CreateButton({
    Name     = "FPS Boost",
    Callback = function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            end
        end
        SetStatus("FPS Boosted")
    end,
})

MoreTab:CreateSection("Auto Buy Bus")

MoreTab:CreateDropdown({
    Name            = "Select Bus to Purchase",
    Options         = CarListData,
    CurrentOption   = { CarListData[1] or "None" },
    MultipleOptions = false,
    Callback        = function(Option) SelectedBusToBuy = Option[1] end,
})

MoreTab:CreateButton({
    Name     = "Purchase Selected Bus",
    Callback = function()
        if SelectedBusToBuy == "" or SelectedBusToBuy == "None" then
            Rayfield:Notify({ Title = "Error", Content = "Select a bus first!", Duration = 3 })
            return
        end
        local success, err = pcall(function()
            Remotes:WaitForChild("BuyCar"):FireServer(SelectedBusToBuy)
        end)
        SetStatus(success and ("Bought: " .. SelectedBusToBuy) or "Purchase Failed!")
        if not success then warn("Purchase error: " .. tostring(err)) end
    end,
})

MoreTab:CreateSection("World Teleport")

MoreTab:CreateDropdown({
    Name            = "Select TP Destination",
    Options         = { "Dealership", "Modifikasi", "Teleport City" },
    CurrentOption   = { "Dealership" },
    MultipleOptions = false,
    Callback        = function(Option) SelectedTP = Option[1] end,
})

MoreTab:CreateButton({
    Name     = "Teleport Now",
    Callback = function()
        local targetCF = TP_Locations[SelectedTP]
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character:PivotTo(targetCF)
            SetStatus("Teleported to " .. SelectedTP)
        end
    end,
})

MoreTab:CreateSection("Open UI / Actions")

MoreTab:CreateDropdown({
    Name            = "Select Menu to Open",
    Options         = { "Dealership", "Modifikasi", "Teleport City" },
    CurrentOption   = { "Dealership" },
    MultipleOptions = false,
    Callback        = function(Option) SelectedAction = Option[1] end,
})

MoreTab:CreateButton({
    Name     = "Open Selected Menu",
    Callback = function()
        if SelectedAction == "Dealership" then
            local p = Workspace:FindFirstChild("BigBus_DealershipPart")
                   and Workspace.BigBus_DealershipPart:FindFirstChild("ProximityPrompt")
            if p then fireproximityprompt(p) end
        elseif SelectedAction == "Modifikasi" then
            local p = Workspace.Modif.ModificationTriggerPart:FindFirstChild("ProximityPrompt")
            if p then fireproximityprompt(p) end
        elseif SelectedAction == "Teleport City" then
            local p = Workspace:FindFirstChild("Telportpart")
                   and Workspace.Telportpart:FindFirstChild("ProximityPrompt")
            if p then fireproximityprompt(p) end
        end
        SetStatus("Opening " .. SelectedAction)
    end,
})