if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

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
        warn("[projectsion] filtergc miss")
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
            warn("[projectsion] Adonis bypass " .. (retry and "active (retry)." or "failed."))
        end)
    else
        warn("[projectsion] Adonis bypass active.")
    end
end)

pcall(function()
    local networkPause = game:GetService('CoreGui').RobloxGui:FindFirstChild('CoreScripts/NetworkPause')
    if networkPause then networkPause:Destroy() end
end)

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

_G.RideGOEnabled    = false
_G.blackscreen      = false
_G.PermanentBlackscreen = false
_G.RejoinTriggered  = false

_G.AutoWebhook  = false
_G.WebhookURL   = ""
_G.TotalEarning = 0
_G.CycleCount   = 0

_G.RideGOEarned = 0

local ActiveConnections = {}
local lastMoney       = PlayerData.RPValue.Value
local pendingIncome   = 0
local isRunning       = false

local _activeSeconds = 0
local _farmTickStart = nil

local function _syncFarmTimer()
    local anyActive = _G.RideGOEnabled
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

local function formatTime(secs)
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = math.floor(secs % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function formatRP(v)
    local s         = string.format("%.0f", v)
    local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "RP. " .. formatted
end

local function computeRPH()
    local secs = getActiveSeconds()
    if secs < 60 then return "—" end
    return formatRP((_G.TotalEarning / secs) * 3600) .. "/h"
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
    local isAnyFarmActive = _G.RideGOEnabled
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

local statTimer   = nil
local statRPH     = nil
local statTotal   = nil
local statBalance = nil
local statBreak   = nil

local function pushEarningStats()
    pcall(function() statTotal:SetDesc(formatRP(_G.TotalEarning)) end)
    pcall(function() statRPH:SetDesc(computeRPH()) end)
    pcall(function()
        statBreak:SetDesc(string.format("RideGO: %s", formatRP(_G.RideGOEarned)))
    end)
end

local _lastNotifText = ""

task.spawn(function()
    local ok, NOTIF = pcall(function()
        return LP:WaitForChild("PlayerGui", 30)
            :WaitForChild("MainUI", 30)
            :WaitForChild("Frame4", 30)
            :WaitForChild("NOTIF", 30)
    end)
    if not ok or not NOTIF then return end

    NOTIF:GetPropertyChangedSignal("Text"):Connect(function()
        local text = NOTIF.Text
        if text == "" or text == _lastNotifText then return end
        _lastNotifText = text

        local digits = text:gsub("[^%d]", "")
        if digits ~= "" then
            local amount = tonumber(digits) or 0
            if amount > 0 then
                _G.TotalEarning = _G.TotalEarning + amount
                if _G.RideGOEnabled then _G.RideGOEarned = _G.RideGOEarned + amount end
                pushEarningStats()
            end
        end
    end)
end)

PlayerData.RPValue.Changed:Connect(function(newMoney)
    if newMoney > lastMoney then
        local gained = newMoney - lastMoney
        pendingIncome = pendingIncome + gained
        if not isRunning then
            isRunning = true
            task.spawn(function()
                while isRunning do
                    task.wait(60)
                    if pendingIncome > 0 and _G.WebhookURL ~= "" then
                        sendWebhook(pendingIncome, 0)
                        pendingIncome = 0
                    end
                    if not _G.RideGOEnabled then isRunning = false end
                end
            end)
        end
    end
    lastMoney = newMoney
end)

local function RejoinServer()
    local queue_teleport = queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
    _G.RideGOEnabled = false
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

-- ─── RideGO ───────────────────────────────────────────────────────────────────

local rgState = {
    IsActive          = false,
    IsOnline          = false,
    Phase             = "idle",
    Token             = nil,
    TargetPos         = nil,
    TripCount         = 0,
    Earnings          = 0,
    CurrentCycleTrips = 0,
    NextBikeCycle     = math.random(3, 7),
    LastSeat          = nil,
    SelectedCar       = nil,
    OwnedVehicles     = {},
    MinSpeed          = 70,
    MaxSpeed          = 95,
}

local rgChar = {
    Character = LP.Character,
    Humanoid  = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"),
    Root      = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"),
}
LP.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    rgChar.Character = char
    rgChar.Humanoid  = char:WaitForChild("Humanoid", 5)
    rgChar.Root      = char:WaitForChild("HumanoidRootPart", 5)
    if rgState.IsActive then
        for _, st in ipairs({
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.GettingUp,
        }) do pcall(function() rgChar.Humanoid:SetStateEnabled(st, false) end) end
    end
end)

RunService.Heartbeat:Connect(function()
    local hum = rgChar.Humanoid
    if hum and hum.SeatPart then rgState.LastSeat = hum.SeatPart end
end)

local function rgSetRagdollStates(enabled)
    local hum = rgChar.Humanoid
    if not hum then return end
    for _, st in ipairs({
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.GettingUp,
    }) do pcall(function() hum:SetStateEnabled(st, enabled) end) end
end

local function rgZeroVelocity(part)
    if not part then return end
    pcall(function()
        part.AssemblyLinearVelocity  = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function rgPivotKeepYaw(bike, position)
    local _, yaw, _ = bike:GetPivot():ToOrientation()
    bike:PivotTo(CFrame.new(position) * CFrame.Angles(0, yaw, 0))
end

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
        rgState.OwnedVehicles = unique
        local found = false
        for _, n in ipairs(unique) do if n == rgState.SelectedCar then found = true; break end end
        if not found then rgState.SelectedCar = unique[1] end
    else
        rgState.OwnedVehicles = {}
        rgState.SelectedCar   = nil
    end
    return rgState.OwnedVehicles
end

local function rgIsVehicleMine(v)
    if not (v and v:IsA("Model")) then return false end
    local myName = LP.Name
    local vName  = v.Name
    local ownerAttr = v:GetAttribute("Owner") or v:GetAttribute("Player") or v:GetAttribute("Creator")
    if ownerAttr and (tostring(ownerAttr) == myName or tostring(ownerAttr) == tostring(LP.UserId)) then return true end
    local ownerVal = v:FindFirstChild("Owner") or v:FindFirstChild("Player")
    if ownerVal and (ownerVal:IsA("StringValue") or ownerVal:IsA("ObjectValue")) then
        if tostring(ownerVal.Value) == myName or ownerVal.Value == LP then return true end
    end
    local seat = v:FindFirstChildOfClass("VehicleSeat") or v:FindFirstChild("DriveSeat", true)
    if seat and seat.Occupant and rgChar.Humanoid and seat.Occupant == rgChar.Humanoid then return true end
    if vName:find(myName, 1, true) then return true end
    if rgState.SelectedCar and vName:find(rgState.SelectedCar, 1, true) then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and vName:find(plr.Name, 1, true) then return false end
        end
        return true
    end
    return false
end

local function rgGetBikeModel()
    local hum = rgChar.Humanoid
    if hum and hum.SeatPart then return hum.SeatPart:FindFirstAncestorOfClass("Model") end
    if rgState.IsActive and rgState.LastSeat and rgState.LastSeat.Parent then
        return rgState.LastSeat:FindFirstAncestorOfClass("Model")
    end
    return nil
end

local function rgGetPrimary(bike)
    if not bike then return nil end
    return bike.PrimaryPart
        or bike:FindFirstChild("VehicleSeat")
        or bike:FindFirstChildOfClass("BasePart")
end

local function rgGetMovers(primary)
    if not primary then return nil, nil end
    local bv = primary:FindFirstChild("RG_BV")
    if not bv then
        bv          = Instance.new("BodyVelocity")
        bv.Name     = "RG_BV"
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.zero
        bv.Parent   = primary
    end
    local bg = primary:FindFirstChild("RG_BG")
    if not bg then
        bg           = Instance.new("BodyGyro")
        bg.Name      = "RG_BG"
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.P         = 3000
        bg.D         = 500
        bg.CFrame    = primary.CFrame
        bg.Parent    = primary
    end
    return bv, bg
end

local function rgFindMyMotor()
    for _, v in pairs(Workspace:GetChildren()) do
        if rgIsVehicleMine(v) and (v:FindFirstChildOfClass("VehicleSeat") or v:FindFirstChild("DriveSeat", true)) then
            return v
        end
    end
    local vFolder = Workspace:FindFirstChild("Cars") or Workspace:FindFirstChild("Vehicles")
    if vFolder then
        for _, v in pairs(vFolder:GetChildren()) do if rgIsVehicleMine(v) then return v end end
    end
    return nil
end

local rgDealerEvents = ReplicatedStorage:WaitForChild("DealershipEvents", 10)
local rgSpawnEvents  = ReplicatedStorage:WaitForChild("SpawnCarEvents", 10)

local function rgSpawnAndMountBike()
    if not rgState.SelectedCar then rgFetchOwnedVehicles() end
    if not rgState.SelectedCar or not rgSpawnEvents then return rgGetBikeModel() end
    pcall(function()
        if rgSpawnEvents:FindFirstChild("DespawnCar") then
            rgSpawnEvents.DespawnCar:FireServer()
        elseif rgSpawnEvents:FindFirstChild("RemoveCar") then
            rgSpawnEvents.RemoveCar:FireServer()
        end
    end)
    task.wait(0.8)
    pcall(function()
        if rgDealerEvents then
            if rgDealerEvents:FindFirstChild("InitializeCarData") then rgDealerEvents.InitializeCarData:InvokeServer() end
            if rgDealerEvents:FindFirstChild("GetInfoCarSlot") then rgDealerEvents.GetInfoCarSlot:InvokeServer() end
        end
        if rgSpawnEvents:FindFirstChild("SpawnCar") then rgSpawnEvents.SpawnCar:FireServer(rgState.SelectedCar) end
    end)
    local seatFound = nil
    local timeout   = tick() + 8
    while tick() < timeout and not seatFound do
        task.wait(0.2)
        if rgChar.Root then
            for _, model in ipairs(Workspace:GetChildren()) do
                if model:IsA("Model") and rgIsVehicleMine(model) then
                    local seat = model:FindFirstChildOfClass("VehicleSeat") or model:FindFirstChild("DriveSeat", true)
                    if seat and (not seat.Occupant or seat.Occupant == rgChar.Humanoid) then
                        if (seat.Position - rgChar.Root.Position).Magnitude < 100 then
                            seatFound = seat; break
                        end
                    end
                end
            end
        end
    end
    if seatFound and rgChar.Humanoid and rgChar.Root then
        rgZeroVelocity(rgChar.Root)
        rgChar.Root.CFrame = seatFound.CFrame
        task.wait(0.1)
        seatFound:Sit(rgChar.Humanoid)
        task.wait(0.5)
        if rgChar.Humanoid.SeatPart ~= seatFound then
            rgChar.Root.CFrame = seatFound.CFrame
            task.wait(0.1)
            seatFound:Sit(rgChar.Humanoid)
            task.wait(0.5)
        end
        local primary = seatFound.Parent.PrimaryPart or seatFound
        rgGetMovers(primary)
        return seatFound.Parent
    end
    return rgGetBikeModel()
end

local function rgEnsureBike()
    if not rgState.SelectedCar then
        rgFetchOwnedVehicles()
        if not rgState.SelectedCar then return nil end
    end
    local bike = rgGetBikeModel()
    if bike and rgIsVehicleMine(bike) and rgChar.Humanoid and rgChar.Humanoid.SeatPart then
        local primary = rgGetPrimary(bike)
        if primary then rgGetMovers(primary) end
        return bike
    end
    local existing = rgFindMyMotor()
    if existing and rgChar.Root and rgChar.Humanoid then
        local seat = existing:FindFirstChildOfClass("VehicleSeat") or existing:FindFirstChild("DriveSeat", true)
        if seat and (not seat.Occupant or seat.Occupant == rgChar.Humanoid) then
            if (seat.Position - rgChar.Root.Position).Magnitude < 100 then
                rgZeroVelocity(rgChar.Root)
                rgChar.Root.CFrame = seat.CFrame
                task.wait(0.1)
                seat:Sit(rgChar.Humanoid)
                task.wait(0.5)
                local primary = existing.PrimaryPart or seat
                rgGetMovers(primary)
                return existing
            end
        end
    end
    return rgSpawnAndMountBike()
end

local function rgSafeDismount()
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local bike = rgGetBikeModel()
    if bike then
        local primary = rgGetPrimary(bike)
        if primary then
            rgZeroVelocity(primary)
            local bv = primary:FindFirstChild("RG_BV")
            if bv then bv.Velocity = Vector3.zero end
        end
    end
    if root then rgZeroVelocity(root) end
    if hum then
        hum.Sit  = false
        hum.Jump = true
        task.wait(0.1)
        if hum.SeatPart then
            char:PivotTo(char:GetPivot() * CFrame.new(0, 2.5, 0))
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    task.wait(0.2)
    if root then rgZeroVelocity(root) end
end

local function rgStripModel(model)
    if not model then return end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end

RunService.Heartbeat:Connect(function()
    if not rgState.IsActive then return end
    pcall(function()
        rgStripModel(rgChar.Character)
        local bike = rgGetBikeModel() or rgFindMyMotor()
        if bike then
            for _, p in ipairs(bike:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
            for _, seat in ipairs(bike:GetDescendants()) do
                if seat:IsA("VehicleSeat") and seat.Occupant then
                    rgStripModel(seat.Occupant.Parent)
                end
            end
        end
        local am = Workspace:FindFirstChild("ActiveMissions")
        if am then
            local pax = am:FindFirstChild("RideGO_Passenger")
            if pax then rgStripModel(pax) end
            for _, inst in ipairs(am:GetDescendants()) do
                if inst:IsA("BasePart") and inst.Name == "Batas" then
                    inst.CanCollide = false; inst.CanQuery = false
                end
            end
        end
        if bike then
            local primary = rgGetPrimary(bike)
            if primary then
                local playerChars = {}
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character then playerChars[plr.Character] = true end
                end
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("Model") and not playerChars[obj]
                       and obj:FindFirstChildOfClass("Humanoid") then
                        local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                        if root and (root.Position - primary.Position).Magnitude <= 25 then
                            rgStripModel(obj)
                        end
                    end
                end
            end
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if not rgState.IsActive then continue end
        local onDuty = rgState.Phase ~= "idle" and rgState.Phase ~= "cycling"
        if not onDuty then continue end
        local hum  = rgChar.Humanoid
        local root = rgChar.Root
        local seat = rgState.LastSeat
        if hum and hum.Health > 0 and not hum.SeatPart
           and seat and seat.Parent and root then
            rgZeroVelocity(root)
            root.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
            local ok = pcall(function() seat:Sit(hum) end)
            if not ok then pcall(function() hum.Sit = true end) end
            task.wait(1)
        end
    end
end)

local RG_MAX_SPEED  = 230
local RG_HOVER      = 12
local RG_LAND       = 3
local RG_VOID_STEP  = 300
local RG_VOID_STEPS = 40
local RG_VOID_WAIT  = 0.1
local RG_VOID_MARGIN= 150
local RG_SCAN_STEP  = 50
local RG_SCAN_IVTL  = 0.12
local RG_RAY_ABOVE  = 1000
local RG_RAY_LEN    = 5000
local RG_ACCEL      = 90
local RG_BRAKE_D    = 60
local RG_BRAKE_P    = 0.75
local RG_BRAKE_J    = 80
local RG_BRAKE_S    = 1.12
local RG_CRAWL      = 6
local RG_ARRIVE     = 5
local RG_SNAP       = 3
local RG_PASS_DIST  = 25
local RG_PASS_MARGIN= 3
local RG_TURN       = 0.12

local RG_DOWN    = Vector3.new(0, -1000, 0)
local RG_OFFSETS = {
    Vector3.new(0, 0, 0),
    Vector3.new(0, 0,  10), Vector3.new(0, 0, -10),
    Vector3.new(10, 0, 0),  Vector3.new(-10, 0, 0),
}

local rgRayParams      = RaycastParams.new()
rgRayParams.FilterType = Enum.RaycastFilterType.Exclude
local rgLastRayBuild   = 0

local function rgBuildBlacklist()
    local bl = {}
    if LP.Character then table.insert(bl, LP.Character) end
    local bike = rgGetBikeModel()
    if bike then
        table.insert(bl, bike)
        for _, seat in ipairs(bike:GetDescendants()) do
            if seat:IsA("VehicleSeat") and seat.Occupant then
                table.insert(bl, seat.Occupant.Parent)
            end
        end
    end
    local am = Workspace:FindFirstChild("ActiveMissions")
    if am then table.insert(bl, am) end
    return bl
end

local function rgRefreshRay(force)
    local now = os.clock()
    if not force and now - rgLastRayBuild < 0.5 then return end
    rgLastRayBuild = now
    rgRayParams.FilterDescendantsInstances = rgBuildBlacklist()
end

local function rgFindGroundY(origin)
    rgRefreshRay(false)
    local highest = nil
    for i = 1, #RG_OFFSETS do
        local r = Workspace:Raycast(origin + RG_OFFSETS[i], RG_DOWN, rgRayParams)
        if r then if not highest or r.Position.Y > highest then highest = r.Position.Y end end
    end
    return highest
end

local function rgFindLandingY(origin)
    rgRefreshRay(false)
    local start = Vector3.new(origin.X, origin.Y + RG_RAY_ABOVE, origin.Z)
    local r     = Workspace:Raycast(start, Vector3.new(0, -RG_RAY_LEN, 0), rgRayParams)
    return r and r.Position.Y or nil
end

local function rgHasGroundAt(origin)
    rgRefreshRay(false)
    for i = 1, #RG_OFFSETS do
        if Workspace:Raycast(origin + RG_OFFSETS[i], RG_DOWN, rgRayParams) then return true end
    end
    return false
end

local function rgBrakeSpeedCap(distToStop)
    if distToStop <= 0 then return 0 end
    local a  = RG_BRAKE_D * RG_BRAKE_P
    local r  = RG_BRAKE_D / RG_BRAKE_J
    local ar = a * r
    local v  = (-ar + math.sqrt(ar * ar + 8 * a * distToStop)) / 2
    return math.max(v, 0)
end

local function rgFlyToTarget(targetPos)
    local bike = rgEnsureBike() or rgGetBikeModel()
    if not bike then return false end
    local primary = rgGetPrimary(bike)
    if not primary then return false end
    pcall(function() bike:SetNetworkOwner(LP) end)
    rgSetRagdollStates(false)
    rgRefreshRay(true)
    local bv, bg = rgGetMovers(primary)
    bv.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity  = Vector3.zero
    rgZeroVelocity(primary)
    bg.CFrame    = bike:GetPivot()

    local reached    = false
    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
    local minSpd     = tonumber(rgState.MinSpeed) or 70
    local maxSpd     = tonumber(rgState.MaxSpeed) or 95
    if minSpd > maxSpd then minSpd, maxSpd = maxSpd, minSpd end

    local baseSpeed      = math.random(math.floor(minSpd), math.floor(maxSpd))
    local curSpeed       = 0
    local moveDir        = Vector3.zero
    local smoothedLook   = bike:GetPivot()
    local curDecel       = 0
    local jitterMul      = 1
    local nextJitterAt   = 0
    local nextVoidScanAt = 0
    local minDist        = math.huge

    local function crossVoid(startPos, dir, voidStartDist)
        local guard  = 0
        local vDecel = curDecel
        while curSpeed > 1 and guard < 400 do
            guard += 1
            if not bv.Parent then break end
            local stepDt = math.clamp(RunService.Heartbeat:Wait(), 0.005, 0.1)
            vDecel   = math.min(vDecel + RG_BRAKE_J * stepDt, RG_BRAKE_D)
            curSpeed = math.max(curSpeed - vDecel * stepDt, 0)
            bv.Velocity = Vector3.new(dir.X * curSpeed, 0, dir.Z * curSpeed)
        end
        curSpeed = 0; curDecel = 0
        if bv.Parent then bv.Velocity = Vector3.zero end
        rgZeroVelocity(primary)
        task.wait(0.3)
        if not rgState.IsActive then return false end
        local safePos = startPos + dir * math.max(0, voidStartDist - 20)
        local safeY   = rgFindGroundY(safePos) or startPos.Y
        rgPivotKeepYaw(bike, Vector3.new(safePos.X, safeY + RG_HOVER, safePos.Z))
        rgZeroVelocity(primary)
        if rgChar.Root then rgZeroVelocity(rgChar.Root) end
        smoothedLook = bike:GetPivot(); bg.CFrame = smoothedLook
        task.wait(0.2)
        local stepPos = Vector3.new(safePos.X, safeY + RG_HOVER, safePos.Z)
        local landed  = false
        local dFlat   = (Vector3.new(stepPos.X, 0, stepPos.Z) - flatTarget).Magnitude
        for step = 1, RG_VOID_STEPS do
            if not rgState.IsActive then return false end
            local stepDist = math.min(RG_VOID_STEP, dFlat)
            if stepDist < 5 then break end
            local nextPos  = stepPos + dir * stepDist
            local groundYN = rgFindLandingY(nextPos)
            local landPos
            if groundYN then
                landPos = Vector3.new(nextPos.X, groundYN + RG_HOVER, nextPos.Z)
                landed  = true
            else
                landPos = Vector3.new(nextPos.X, stepPos.Y, nextPos.Z)
            end
            rgPivotKeepYaw(bike, landPos)
            rgZeroVelocity(primary)
            if rgChar.Root then rgZeroVelocity(rgChar.Root) end
            smoothedLook = bike:GetPivot(); bg.CFrame = smoothedLook
            task.wait(RG_VOID_WAIT)
            stepPos = landPos
            dFlat   = (Vector3.new(stepPos.X, 0, stepPos.Z) - flatTarget).Magnitude
            if landed then break end
        end
        if not landed then
            local safeY2 = (rgFindLandingY(targetPos) or targetPos.Y) + RG_HOVER
            rgPivotKeepYaw(bike, Vector3.new(targetPos.X, safeY2, targetPos.Z))
            rgZeroVelocity(primary)
            if rgChar.Root then rgZeroVelocity(rgChar.Root) end
            smoothedLook = bike:GetPivot(); bg.CFrame = smoothedLook
            task.wait(RG_VOID_WAIT)
        end
        task.wait(0.2)
        return true
    end

    while rgState.IsActive do
        local dt       = math.clamp(RunService.Heartbeat:Wait(), 0.005, 0.1)
        local nowClock = os.clock()
        if not bv.Parent or not bg.Parent or rgGetPrimary(rgGetBikeModel()) ~= primary then break end
        if rgChar.Humanoid and not rgChar.Humanoid.SeatPart then
            local b2 = rgEnsureBike()
            if b2 then
                primary = rgGetPrimary(b2)
                if primary then bv, bg = rgGetMovers(primary) end
            end
        end
        local pos      = primary.Position
        local flatPos  = Vector3.new(pos.X, 0, pos.Z)
        local toTarget = flatTarget - flatPos
        local flatDist = toTarget.Magnitude
        if flatDist < minDist then minDist = flatDist end
        local passed = (minDist < RG_PASS_DIST) and (flatDist > minDist + RG_PASS_MARGIN)
        if flatDist <= RG_ARRIVE or passed then reached = true; break end
        local dirTo = toTarget / flatDist
        if nowClock >= nextVoidScanAt then
            nextVoidScanAt = nowClock + RG_SCAN_IVTL
            local ramp      = RG_BRAKE_D / RG_BRAKE_J
            local stopDist  = (curSpeed * curSpeed) / (2 * RG_BRAKE_D) + curSpeed * ramp * 0.5
            local lookAhead = math.min(math.max(150, stopDist + RG_VOID_MARGIN), 1000, flatDist)
            local voidAt    = nil
            for dv = RG_SCAN_STEP, lookAhead, RG_SCAN_STEP do
                if not rgHasGroundAt(pos + dirTo * dv) then voidAt = dv; break end
            end
            if voidAt then
                if not crossVoid(pos, dirTo, voidAt) then return false end
                curSpeed = 0; curDecel = 0; minDist = math.huge
                nextVoidScanAt = os.clock() + 0.3
                continue
            end
        end
        if nowClock >= nextJitterAt then
            jitterMul    = 1 + (math.random(-5, 5) / 100)
            nextJitterAt = nowClock + 1.5
        end
        local cruise  = math.min(baseSpeed * jitterMul, RG_MAX_SPEED)
        local cap     = math.max(rgBrakeSpeedCap(flatDist - 1), RG_CRAWL)
        local desired = math.min(cruise, cap)
        if desired >= curSpeed then
            curDecel = 0
            curSpeed = math.min(curSpeed + RG_ACCEL * dt, desired)
        else
            curDecel = math.min(curDecel + RG_BRAKE_J * dt, RG_BRAKE_D)
            curSpeed = math.max(curSpeed - curDecel * dt, desired)
            local hardCap = cap * RG_BRAKE_S
            if curSpeed > hardCap then curSpeed = hardCap end
        end
        moveDir = dirTo
        local velH   = moveDir * curSpeed
        local gY     = rgFindGroundY(pos)
        local hoverY = gY and (gY + RG_HOVER) or pos.Y
        local yVel   = math.clamp((hoverY - pos.Y) * 4, -25, 25)
        bv.Velocity = Vector3.new(velH.X, yVel, velH.Z)
        if curSpeed > 1 then
            local wantLook = CFrame.lookAt(pos, pos + Vector3.new(velH.X, 0, velH.Z))
            smoothedLook   = smoothedLook:Lerp(wantLook, RG_TURN)
            bg.CFrame      = smoothedLook
        end
    end

    if not reached then
        if bv.Parent then bv.Velocity = Vector3.zero end
        return false
    end
    local lastVel = moveDir * curSpeed
    for i = 1, 20 do
        if not bv.Parent then break end
        local k = 1 - i / 20
        bv.Velocity = Vector3.new(lastVel.X * k, 0, lastVel.Z * k)
        task.wait(0.025)
    end
    if bv.Parent then bv.Velocity = Vector3.zero end
    rgZeroVelocity(primary)
    local pNow    = primary.Position
    local distNow = (Vector3.new(pNow.X, 0, pNow.Z) - flatTarget).Magnitude
    if distNow > RG_SNAP then
        rgPivotKeepYaw(bike, Vector3.new(targetPos.X, pNow.Y, targetPos.Z))
        rgZeroVelocity(primary)
        if rgChar.Root then rgZeroVelocity(rgChar.Root) end
        smoothedLook = bike:GetPivot(); bg.CFrame = smoothedLook
        task.wait(0.1)
    end
    local gY = rgFindGroundY(primary.Position)
    if gY then
        local targetLandY = gY + RG_LAND
        local dGuard = 0
        while bv.Parent and primary.Position.Y > targetLandY + 0.5 and dGuard < 100 do
            if not rgState.IsActive then break end
            dGuard += 1
            bv.Velocity = Vector3.new(0, -8, 0)
            task.wait(0.1)
        end
    end
    if bv.Parent then bv.Velocity = Vector3.zero end
    rgZeroVelocity(primary)
    task.wait(1)
    return true
end

local TaxiEventRG = nil
task.spawn(function()
    local assets = ReplicatedStorage:WaitForChild("TaxiAssets", 15)
    local evts   = assets and assets:WaitForChild("Events", 15)
    local tevt   = evts and evts:WaitForChild("TaxiEvent", 15)
    TaxiEventRG  = tevt
    if not TaxiEventRG then return end

    TaxiEventRG.OnClientEvent:Connect(function(action, data)
        if not rgState.IsActive then return end
        local d = data or {}
        if action == "DutyStarted" then
            rgState.IsOnline = true; rgState.Phase = "idle"
            rgEnsureBike()
        elseif action == "DutyEnded" then
            rgState.IsOnline = false; rgState.Phase = "idle"; rgState.TargetPos = nil
        elseif action == "OrderOffer" and rgState.Phase == "idle" then
            rgState.Token = d.Token; rgState.Phase = "offered"
            rgEnsureBike()
            TaxiEventRG:FireServer("AcceptOrder", rgState.Token)
        elseif action == "OrderAccepted" and rgState.Token == d.Token then
            rgState.TargetPos = d.PickupPos; rgState.Phase = "goingPickup"
        elseif action == "PassengerBoarding"
            and (rgState.Phase == "goingPickup" or rgState.Phase == "atPickup") then
            rgState.Phase = "waitingBoard"; task.wait(3)
        elseif action == "TripStarted" and rgState.Phase == "waitingBoard" then
            rgState.TargetPos = d.DropPos; rgState.Phase = "goingDrop"
        elseif action == "OrderCompleted" then
            rgState.TripCount = (rgState.TripCount or 0) + 1
            local earned      = tonumber(d.Earned or d.FareEarned) or 0
            rgState.Earnings  = (rgState.Earnings or 0) + earned
            task.delay(1, function() TaxiEventRG:FireServer("AckTripComplete") end)
            rgState.Token = nil; rgState.TargetPos = nil
            rgState.CurrentCycleTrips = (rgState.CurrentCycleTrips or 0) + 1
            if rgState.CurrentCycleTrips >= (rgState.NextBikeCycle or 5) then
                rgState.Phase = "cycling"
                task.spawn(function()
                    pcall(function() TaxiEventRG:FireServer("GoOffline") end)
                    task.wait(0.5)
                    rgSafeDismount()
                    task.wait(math.random(40, 80) / 10)
                    rgSpawnAndMountBike()
                    task.wait(math.random(15, 25) / 10)
                    pcall(function() TaxiEventRG:FireServer("GoOnline") end)
                    rgState.CurrentCycleTrips = 0
                    rgState.NextBikeCycle     = math.random(3, 7)
                    rgState.Phase             = "idle"
                end)
            else
                rgState.Phase = "idle"
            end
        elseif action == "OrderExpired" or action == "OrderDeclined" or action == "OrderCancelled" then
            rgState.Token = nil; rgState.TargetPos = nil
            if rgState.Phase ~= "cycling" then rgState.Phase = "idle" end
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.4)
        if not rgState.IsActive or not rgState.TargetPos then continue end
        if rgState.Phase == "goingPickup" then
            local ok = rgFlyToTarget(rgState.TargetPos)
            if ok and rgState.Phase == "goingPickup" then rgState.Phase = "atPickup" end
        elseif rgState.Phase == "goingDrop" then
            local ok = rgFlyToTarget(rgState.TargetPos)
            if ok and rgState.Phase == "goingDrop" then
                rgState.Phase = "waitingDropOff"
                local arrivedAt = tick()
                while rgState.IsActive and rgState.Phase == "waitingDropOff"
                    and (tick() - arrivedAt < 8) do
                    task.wait(0.5)
                end
                if rgState.Phase == "waitingDropOff" then
                    pcall(function()
                        if TaxiEventRG then
                            TaxiEventRG:FireServer("CancelOrder")
                            if rgState.Token then TaxiEventRG:FireServer("DeclineOrder", rgState.Token) end
                        end
                    end)
                    rgSafeDismount()
                    task.wait(0.5)
                    rgSpawnAndMountBike()
                    rgState.Token = nil; rgState.TargetPos = nil; rgState.Phase = "idle"
                end
            end
        end
    end
end)

LP:GetPropertyChangedSignal("Team"):Connect(function()
    if rgState.IsActive and LP.Team and LP.Team.Name ~= "RideGO Driver" then
        rgState.IsActive = false
        _G.RideGOEnabled = false
        _syncFarmTimer()
        if TaxiEventRG then pcall(function() TaxiEventRG:FireServer("GoOffline") end) end
    end
end)

function StartRideGO()
    if rgState.IsActive then return end
    if not TaxiEventRG then return end
    if not rgState.SelectedCar then rgFetchOwnedVehicles() end
    if not rgState.SelectedCar then return end
    rgState.IsActive          = true
    rgState.TripCount         = 0
    rgState.Earnings          = 0
    rgState.CurrentCycleTrips = 0
    rgState.NextBikeCycle     = math.random(3, 7)
    _G.RideGOEnabled          = true
    _syncFarmTimer()
    rgSetRagdollStates(false)
    rgEnsureBike()
    if not rgState.IsOnline then
        pcall(function() TaxiEventRG:FireServer("GoOnline") end)
    end
end

function StopRideGO()
    if not rgState.IsActive then return end
    rgState.IsActive  = false
    _G.RideGOEnabled  = false
    rgState.TargetPos = nil
    _syncFarmTimer()
    if rgState.IsOnline and TaxiEventRG then
        pcall(function() TaxiEventRG:FireServer("GoOffline") end)
    end
    local bike = rgGetBikeModel() or rgFindMyMotor()
    if bike then
        local primary = rgGetPrimary(bike)
        if primary then
            local bv = primary:FindFirstChild("RG_BV")
            local bg = primary:FindFirstChild("RG_BG")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
            rgZeroVelocity(primary)
        end
    end
    rgSetRagdollStates(true)
end

task.spawn(function()
    task.wait(2)
    rgFetchOwnedVehicles()
end)

-- ─── UI ───────────────────────────────────────────────────────────────────────

local Wind = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

_G._wallStart = os.time()

local Window = Wind:CreateWindow({
    Title    = "Projectsion",
    SubTitle = "Autofarm",
    TabWidth = 160,
    Size     = UDim2.fromOffset(580, 460),
    Theme    = "Dark",
    OpenButton = {
        Enabled   = true,
        Title     = "Projectsion",
        Draggable = true,
    },
})

local RideTab = Window:Tab({ Title = "RideGO", Icon = "car" })

RideTab:Toggle({
    Title   = "RideGO",
    Default = false,
    Callback = function(state)
        if state then StartRideGO() else StopRideGO() end
        updateBlackScreen()
    end,
})

RideTab:Slider({
    Title     = "Min Speed",
    Value     = { Min = 30, Max = 230, Default = 70 },
    Increment = 1,
    Callback  = function(v) rgState.MinSpeed = v end,
})

RideTab:Slider({
    Title     = "Max Speed",
    Value     = { Min = 30, Max = 230, Default = 95 },
    Increment = 1,
    Callback  = function(v) rgState.MaxSpeed = v end,
})

local vehicleDropdown = RideTab:Dropdown({
    Title    = "Vehicle",
    Values   = { "Fetching..." },
    Default  = "Fetching...",
    Callback = function(v)
        if v ~= "Fetching..." then rgState.SelectedCar = v end
    end,
})

task.spawn(function()
    task.wait(2.5)
    local vehicles = rgState.OwnedVehicles
    if #vehicles > 0 and vehicleDropdown then
        pcall(function()
            vehicleDropdown:Refresh(vehicles, vehicles[1])
            rgState.SelectedCar = vehicles[1]
        end)
    end
end)

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

local StatsTab = Window:Tab({ Title = "Stats", Icon = "bar-chart-2" })

statTimer   = StatsTab:Paragraph({ Title = "Session Timer",  Desc = "00:00:00" })
statRPH     = StatsTab:Paragraph({ Title = "Earning / Hour", Desc = "—" })
statTotal   = StatsTab:Paragraph({ Title = "Total Earned",   Desc = "RP. 0" })
statBalance = StatsTab:Paragraph({ Title = "Money Balance",  Desc = formatRP(PlayerData.RPValue.Value) })
statBreak   = StatsTab:Paragraph({ Title = "By Job",         Desc = "RideGO: RP. 0" })

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function() statTimer:SetDesc(formatTime(getActiveSeconds())) end)
        pcall(function() statBalance:SetDesc(formatRP(PlayerData.RPValue.Value)) end)
    end
end)

warn("[PROJECTSION] Loaded.")