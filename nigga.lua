-- Ghost Driver | Gen2 port
repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local Lighting         = game:GetService("Lighting")

local localplayer = Players.LocalPlayer

-- ── anti-idle ──────────────────────────────────────────────────────────────
local idleConn
local function patchIdle(plr)
    if getconnections then
        for _, c in getconnections(plr.Idled) do
            pcall(function() c:Disable() end)
            pcall(function() c:Disconnect() end)
        end
    end
    pcall(function()
        if idleConn then idleConn:Disconnect() end
    end)
    idleConn = plr.Idled:Connect(function()
        local vim = Instance.new("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        vim:Destroy()
    end)
end
local function unpatchIdle()
    if idleConn then idleConn:Disconnect(); idleConn = nil end
end
patchIdle(localplayer)

-- ── service refs ───────────────────────────────────────────────────────────
local trafficFolder = Workspace:WaitForChild("TrafficFolder", 15)
local remotes       = ReplicatedStorage:WaitForChild("Remotes", 10)
local updateSpeedBridge = ReplicatedStorage:FindFirstChild("UpdateSpeedBridge")
local spawnCarEvent = remotes:FindFirstChild("SpawnCarEvent")

local maxCash = 70000
pcall(function()
    local m = require(ReplicatedStorage
        :WaitForChild("Controllers", 10)
        :WaitForChild("PoliceBustedController", 10)
        :WaitForChild("PoliceConfig", 10))
    if m and tonumber(m.MaxCashPerRun) then
        maxCash = tonumber(m.MaxCashPerRun)
    end
end)

-- ── traffic optimiser ──────────────────────────────────────────────────────
local strippedSet = {}
local function stripModel(model)
    if not model or strippedSet[model] then return end
    strippedSet[model] = true
    pcall(function()
        for _, v in ipairs(model:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false; v.CanTouch = false; v.CastShadow = false
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail")
                or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles")
                or v:IsA("Light") then
                v.Enabled = false
            end
        end
    end)
end
local function unregisterModel(model) strippedSet[model] = nil end

if trafficFolder then
    trafficFolder.ChildAdded:Connect(function(c)
        task.defer(function() stripModel(c) end)
    end)
    trafficFolder.ChildRemoved:Connect(unregisterModel)
    for _, v in ipairs(trafficFolder:GetChildren()) do stripModel(v) end
end

-- ── police AI tracking ─────────────────────────────────────────────────────
local policeSet = {}
local function trackPolice(model)
    if not (model and model:IsA("Model")) then return end
    if CollectionService:HasTag(model, "PoliceAI")
        or model:GetAttribute("IsPoliceAI")
        or model.Name:lower():find("police") then
        policeSet[model] = true
        stripModel(model)
    end
end
CollectionService:GetInstanceAddedSignal("PoliceAI"):Connect(trackPolice)
CollectionService:GetInstanceRemovedSignal("PoliceAI"):Connect(function(m)
    policeSet[m] = nil; unregisterModel(m)
end)
Workspace.ChildAdded:Connect(function(c)
    task.defer(function()
        trackPolice(c)
        if c.Name == "PoliceHelicopters" then
            c.ChildAdded:Connect(function(h) task.defer(function() stripModel(h) end) end)
            for _, h in ipairs(c:GetChildren()) do stripModel(h) end
        end
    end)
end)
Workspace.ChildRemoved:Connect(function(c)
    policeSet[c] = nil; unregisterModel(c)
end)
for _, v in ipairs(CollectionService:GetTagged("PoliceAI")) do trackPolice(v) end
for _, v in ipairs(Workspace:GetChildren()) do trackPolice(v) end
local policeHeli = Workspace:FindFirstChild("PoliceHelicopters")
if policeHeli then
    policeHeli.ChildAdded:Connect(function(h) task.defer(function() stripModel(h) end) end)
    for _, h in ipairs(policeHeli:GetChildren()) do stripModel(h) end
end

-- ── zero-lag graphics ──────────────────────────────────────────────────────
local function applyZeroLag()
    pcall(function()
        localplayer:SetAttribute("MobilePerfMode", false)
        localplayer:SetAttribute("LowGraphicsMode", true)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") then
                v.Enabled = false
            end
        end
        if settings and settings().Rendering then
            settings().Rendering.QualityLevel = 1
        end
        local ugs = UserSettings():GetService("UserGameSettings")
        if ugs then ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end
    end)
end

-- ── heartbeat spoof ────────────────────────────────────────────────────────
local inputHB, inputHB2, inputHBModule
pcall(function()
    local r = ReplicatedStorage:FindFirstChild("AC6Shared")
    r = r and r:FindFirstChild("Remotes")
    inputHB = r and r:FindFirstChild("InputHeartbeat")
end)
pcall(function()
    local m = require(ReplicatedStorage.Packages.Remotes)
    inputHB2 = m and m.InputHeartbeat
end)
pcall(function()
    inputHBModule = require(ReplicatedStorage.Controllers.InputHeartbeatController)
end)
local function fireHeartbeat()
    pcall(function()
        if inputHB  then inputHB:FireServer() end
        if inputHB2 then inputHB2:FireServer() end
        if inputHBModule then inputHBModule.pending = true end
    end)
end
pcall(function() localplayer.Idled:Connect(fireHeartbeat) end)
task.spawn(function()
    while true do task.wait(3.5); fireHeartbeat() end
end)

-- ── config ─────────────────────────────────────────────────────────────────
local cfg = {
    AutoFarm       = false,
    Speed          = 110,
    SelectedCar    = "Weinchen V20",
    SelectedMode   = "Normal",
    PoliceStars    = 3,
    ZeroLag        = true,
    TotalOvertakes = 0,
    StartCash      = 0,
    LaneWidth      = 13.5,
    LookAheadDist  = 220,
    WeaveLerpSpeed = 8.5,
}
pcall(function()
    local ls = localplayer:WaitForChild("leaderstats", 5)
    if ls and ls:FindFirstChild("Cash") then
        cfg.StartCash = ls.Cash.Value
    end
end)
pcall(function()
    local swerve = ReplicatedStorage:FindFirstChild("SwerveUIBridge")
    if swerve then
        swerve.Event:Connect(function()
            cfg.TotalOvertakes = cfg.TotalOvertakes + 1
        end)
    end
end)

-- ── helpers ────────────────────────────────────────────────────────────────
local function getVehicle()
    local char = localplayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart or not hum.SeatPart:IsA("VehicleSeat") then
        return nil, nil
    end
    local seat = hum.SeatPart
    local model = seat:FindFirstAncestorOfClass("Model")
    if model and model.Name == "Body" then model = model.Parent end
    return model, seat
end

local function getCarList()
    local list, fromServer = {}, false
    pcall(function()
        local rf = remotes:FindFirstChild("RequestGarageData")
        if rf and rf:IsA("RemoteFunction") then
            local data = rf:InvokeServer()
            if type(data) == "table" then
                for k in pairs(data) do table.insert(list, tostring(k)) end
                if #list > 0 then fromServer = true end
            end
        end
    end)
    if not fromServer then
        list = {"Weinchen V20","Wulfbrecht RZ7","Kitsuni LX","Sorg Varkis","StarterCar"}
    else
        table.sort(list)
    end
    return list, fromServer
end

local function formatCash(n)
    if not n or n ~= n then return "0" end
    local s = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if s:sub(1,1) == "," then s = s:sub(2) end
    return s
end

local function getWaypoints()
    local wp
    local getCacheFunc = ReplicatedStorage:FindFirstChild("GetMapCacheFunc", true)
    if getCacheFunc and getCacheFunc:IsA("RemoteFunction") then
        local data = getCacheFunc:InvokeServer()
        if data and type(data) == "table" then
            if data.Lane2 and data.Lane2.Waypoints then
                wp = data.Lane2.Waypoints
            else
                for _, v in pairs(data) do
                    if v.Waypoints and #v.Waypoints > 50 then
                        wp = v.Waypoints; break
                    end
                end
            end
        end
    end
    if not wp and getgc then
        local best = math.huge
        for _, v in ipairs(getgc(true)) do
            if type(v) == "table" and type(rawget(v,"Waypoints")) == "table" and rawget(v,"TotalLength") then
                local d = math.abs(v.TotalLength - 95465)
                if d < best then best = d; wp = v.Waypoints end
            end
        end
    end
    if not wp then return nil end
    local cap = #wp == 412 and 411 or #wp
    local out = {}
    for i = 1, cap do
        local a, b = wp[i], wp[i % cap + 1]
        table.insert(out, a)
        local mag = (b - a).Magnitude
        if mag > 350 then
            local steps = math.floor(mag / 220)
            for s = 1, steps do
                table.insert(out, a:Lerp(b, s / (steps + 1)))
            end
        end
    end
    return out
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local lastRayVehicle, lastRayChar
local function groundY(pos, vehicle)
    local char = localplayer.Character
    if vehicle ~= lastRayVehicle or char ~= lastRayChar then
        lastRayVehicle = vehicle; lastRayChar = char
        rayParams.FilterDescendantsInstances = {vehicle, char}
    end
    local hit = Workspace:Raycast(pos + Vector3.new(0,15,0), Vector3.new(0,-35,0), rayParams)
    if hit and not hit.Instance.Name:lower():find("fence")
           and not hit.Instance.Name:lower():find("wall")
           and not hit.Instance.Name:lower():find("shield") then
        return hit.Position.Y + 1.15
    end
    return pos.Y
end

local function closestOnSegment(pt, a, b)
    local ab = b - a
    local len2 = ab:Dot(ab)
    if len2 < 0.0001 then return a, 0 end
    local t = math.clamp((pt - a):Dot(ab) / len2, 0, 1)
    return a + ab * t, t
end

-- exit ramp down / up ─────────────────────────────────────────────────────
local exitDownPts = {
    Vector3.new(-3541.03,138,-150),
    Vector3.new(-3541.03,120,-500),
    Vector3.new(-3541.03,90,-1000),
    Vector3.new(-3541.03,63.5,-1490),
    Vector3.new(-3499.6,63.3,-1580),
}
local function teleportDown(vehicle, seat)
    local spd = 135
    local startPos = seat.Position
    if startPos.Y < 80 and (startPos.X < -3800 or startPos.Z < -850) then return true end
    local pts = {startPos, table.unpack(exitDownPts)}
    for i = 1, #pts - 1 do
        local a, b = pts[i], pts[i+1]
        local mag = (b-a).Magnitude
        local dur = mag / spd
        local t0  = os.clock()
        local dir = (b-a).Unit
        while os.clock()-t0 < dur do
            if not cfg.AutoFarm then return false end
            local frac = math.clamp((os.clock()-t0)/dur, 0, 1)
            local p = a:Lerp(b, frac)
            local y = groundY(p, vehicle)
            local wp = Vector3.new(p.X, y, p.Z)
            vehicle:PivotTo(CFrame.lookAt(wp, wp+dir))
            seat.AssemblyLinearVelocity = dir * spd
            task.wait(0.02)
        end
    end
    task.wait(0.2); return true
end

local exitUpPts = {
    Vector3.new(-3498,63.3,1600),
    Vector3.new(-3520,63.3,1500),
    Vector3.new(-3541,63.3,1350),
    Vector3.new(-3541,70,1150),
    Vector3.new(-3541,95,900),
    Vector3.new(-3541,120,650),
    Vector3.new(-3541,137.5,400),
    Vector3.new(-3541,138,100),
    Vector3.new(-3541,138,-150),
}
local function teleportUp(vehicle, seat)
    local spd = 135
    for i = 1, #exitUpPts - 1 do
        local a, b = exitUpPts[i], exitUpPts[i+1]
        local mag = (b-a).Magnitude
        local dur = mag / spd
        local t0  = os.clock()
        local dir = (b-a).Unit
        while os.clock()-t0 < dur do
            if not cfg.AutoFarm then return false end
            local frac = math.clamp((os.clock()-t0)/dur, 0, 1)
            local p = a:Lerp(b, frac)
            local y = groundY(p, vehicle)
            local wp = Vector3.new(p.X, y, p.Z)
            vehicle:PivotTo(CFrame.lookAt(wp, wp+dir))
            seat.AssemblyLinearVelocity = dir * spd
            task.wait(0.02)
        end
    end
    return true
end

local function isInCombo()
    local hud   = localplayer.PlayerGui:FindFirstChild("InGameHUD")
    local combo = hud and hud:FindFirstChild("ComboUI")
    local streak = combo and combo:FindFirstChild("Streak")
    if not streak or not streak.Visible then return false end
    local msg = streak:FindFirstChild("Message")
    if msg and (msg.Text:find("0X") or msg.Text:find("LOST") or msg.Text:find("CRASHED")) then
        return false
    end
    return true
end

local function doPolicePad(vehicle, seat)
    local wanted = tonumber(localplayer:GetAttribute("Wanted")) or 0
    if wanted > 0 then return true end
    local padPos = Vector3.new(-3639.55, 137.83, -188.56)
    local polPad = Workspace:FindFirstChild("PoliceSystem")
    polPad = polPad and polPad:FindFirstChild("PolicePad")
    local targetPos = polPad and polPad.Position or padPos
    local pts = {seat.Position, Vector3.new(-3639.55,138,-188.56)}
    local spd = 80
    for i = 1, #pts - 1 do
        local a, b = pts[i], pts[i+1]
        local mag = (b-a).Magnitude
        if mag < 5 then continue end
        local dur = mag / spd
        local t0  = os.clock()
        local dir = (b-a).Unit
        while os.clock()-t0 < dur do
            if not cfg.AutoFarm then return false end
            local frac = math.clamp((os.clock()-t0)/dur, 0, 1)
            local p = a:Lerp(b, frac)
            local y = groundY(p, vehicle)
            local wp = Vector3.new(p.X, y, p.Z)
            vehicle:PivotTo(CFrame.lookAt(wp, wp+dir))
            seat.AssemblyLinearVelocity = dir * spd
            task.wait(0.02)
        end
    end
    vehicle:PivotTo(CFrame.new(targetPos + Vector3.new(0,2,0)))
    seat.AssemblyLinearVelocity = Vector3.zero
    task.wait(1)

    local t0 = os.clock()
    while os.clock()-t0 < 8 do
        if not cfg.AutoFarm then return false end
        seat.AssemblyLinearVelocity = Vector3.zero
        vehicle:PivotTo(CFrame.new(targetPos + Vector3.new(0,2,0)))
        local diffVisible = false
        pcall(function()
            local gui = localplayer.PlayerGui:FindFirstChild("CopChaseDifficulty")
            if gui then
                for _, f in ipairs(gui:GetChildren()) do
                    if f:IsA("Frame") and f.Visible then diffVisible = true; break end
                end
                if not diffVisible and gui:IsA("ScreenGui") and gui.Enabled then
                    diffVisible = true
                end
            end
            if not diffVisible then
                local mm = localplayer.PlayerGui:FindFirstChild("MainGameMenu")
                local cd = mm and mm:FindFirstChild("CopChaseDifficulty")
                if cd and cd.Visible then diffVisible = true end
            end
        end)
        if diffVisible then break end
        task.wait(0.25)
    end
    task.wait(0.3)

    pcall(function()
        local ctrl = ReplicatedStorage:FindFirstChild("Controllers")
        ctrl = ctrl and ctrl:FindFirstChild("PoliceDifficultyController")
        if ctrl then
            local m = require(ctrl)
            if m then
                m.selected = tonumber(cfg.PoliceStars) or 5
                pcall(function() m:Paint() end)
            end
        end
    end)
    pcall(function()
        local gui = localplayer.PlayerGui:FindFirstChild("CopChaseDifficulty")
        local target = gui and (gui:FindFirstChild("CopChaseDifficulty") or gui)
        if target then
            local star = target:FindFirstChild("Star"..tostring(cfg.PoliceStars))
            if star and star:IsA("GuiButton") then firesignal(star.Activated) end
            local buy = target:FindFirstChild("Buy")
            if buy and buy:IsA("GuiButton") then firesignal(buy.Activated) end
        end
    end)
    pcall(function()
        local pr = ReplicatedStorage:FindFirstChild("Controllers")
        pr = pr and pr:FindFirstChild("PoliceRemotes")
        if pr then
            local m = require(pr)
            if m and m.PoliceDifficultyPick then
                m.PoliceDifficultyPick:FireServer(tonumber(cfg.PoliceStars) or 5)
            end
        end
    end)
    pcall(function()
        local ctrl = ReplicatedStorage:FindFirstChild("Controllers")
        ctrl = ctrl and ctrl:FindFirstChild("PoliceDifficultyController")
        if ctrl then
            local m = require(ctrl)
            if m and m.Hide then m:Hide() end
        end
    end)

    local t1 = os.clock()
    while os.clock()-t1 < 10 do
        if not cfg.AutoFarm then return false end
        if (tonumber(localplayer:GetAttribute("Wanted")) or 0) > 0 then
            task.wait(0.5); return true
        end
        task.wait(0.25)
    end
    return false
end

-- ── UI: Rayfield Gen2 ──────────────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name     = "Ghost Driver",
    subtitle = "Projectsion",
    sidebarLayout = true,
    theme    = "cobalt",
    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "GhostDriver",
        customFolder = "Projectsion",
    },
})

window:CreateTag({ text = "v0.0.0.5", color = Color3.fromHex("#30ff6a") })
window:CreateTag({ text = "Projectsion", color = Color3.fromHex("#1E3A8A") })

-- ── Farming tab ───────────────────────────────────────────────────────────
local farmTab = window:CreateTab({ name = "Farming", icon = 93364949241311 })

farmTab:CreateSection({ name = "Auto Farming" })

local farmToggle = farmTab:CreateToggle({
    name     = "Start Farming",
    flag     = "AutoFarm",
    value    = false,
    callback = function(val)
        cfg.AutoFarm = val
        if val and cfg.ZeroLag then applyZeroLag() end
    end,
})

farmTab:CreateToggle({
    name     = "Zero Lag Mode",
    flag     = "ZeroLag",
    value    = true,
    callback = function(val)
        cfg.ZeroLag = val
        if val then applyZeroLag() end
    end,
})
task.defer(function() if cfg.ZeroLag then applyZeroLag() end end)

farmTab:CreateSlider({
    name      = "Speed (MPH)",
    flag      = "Speed",
    range     = {60, 250},
    increment = 5,
    value     = 110,
    suffix    = " MPH",
    callback  = function(val) cfg.Speed = val end,
})

local carList, _ = getCarList()
local carDropdown = farmTab:CreateDropdown({
    name     = "Select Car",
    flag     = "SelectedCar",
    options  = carList,
    value    = cfg.SelectedCar,
    callback = function(sel)
        cfg.SelectedCar = sel[1] or sel
    end,
})

local function refreshCarList()
    local newList, fromServer = getCarList()
    if fromServer then
        carDropdown:Refresh(newList)
        if table.find(newList, cfg.SelectedCar) then
            carDropdown:Set({cfg.SelectedCar}, true)
        else
            cfg.SelectedCar = newList[1]
            carDropdown:Set({cfg.SelectedCar}, true)
        end
    end
end
task.defer(refreshCarList)
pcall(function()
    local addCar = remotes:FindFirstChild("AddCar")
    if addCar and addCar:IsA("RemoteEvent") then
        addCar.OnClientEvent:Connect(function() task.wait(0.5); refreshCarList() end)
    end
    local remCar = remotes:FindFirstChild("RemoveCar")
    if remCar and remCar:IsA("RemoteEvent") then
        remCar.OnClientEvent:Connect(function() task.wait(0.5); refreshCarList() end)
    end
end)
task.spawn(function()
    while true do task.wait(4); pcall(refreshCarList) end
end)

farmTab:CreateDropdown({
    name     = "Select Mode",
    flag     = "SelectedMode",
    options  = {"Normal", "Police Chase"},
    value    = cfg.SelectedMode,
    callback = function(sel)
        cfg.SelectedMode = sel[1] or sel
    end,
})

farmTab:CreateDropdown({
    name     = "Police Stars",
    flag     = "PoliceStars",
    options  = {"1","2","3","4","5"},
    value    = tostring(cfg.PoliceStars),
    callback = function(sel)
        cfg.PoliceStars = tonumber(sel[1] or sel) or 3
    end,
})

farmTab:CreateSection({ name = "Information" })

local earningText  = farmTab:CreateText({ name = "Total Earning",  text = "$0" })
local pointText    = farmTab:CreateText({ name = "Total Points",   text = "0 PTS" })
local rankText     = farmTab:CreateText({ name = "Current Rank",   text = "-" })
local levelText    = farmTab:CreateText({ name = "Current Level",  text = "0" })
local xpText       = farmTab:CreateText({ name = "Current XP",     text = "0 / 0" })
local overtakeText = farmTab:CreateText({ name = "Total Overtake", text = "0" })

-- ── Configuration tab ─────────────────────────────────────────────────────
local cfgTab = window:CreateTab({ name = "Configuration", icon = 93364949241311 })

cfgTab:CreateSection({ name = "Theme" })

cfgTab:CreateDropdown({
    name     = "Select Theme",
    options  = {"default","cobalt","ember","amethyst","frost","rose"},
    value    = "cobalt",
    forgetState = true,
    callback = function(sel)
        pcall(function() window:ChangeTheme(sel[1] or sel) end)
    end,
})

cfgTab:CreateSection({ name = "Config" })

local configName = ""
local configInput = cfgTab:CreateInput({
    name        = "Config Name",
    placeholder = "Enter config name...",
    forgetState = true,
    callback    = function(text) configName = text end,
})

cfgTab:CreateButton({
    name     = "Save Config",
    callback = function()
        if configName == "" then
            window:Notify({ title = "Config", content = "Enter config name first!", duration = 3 })
            return
        end
        local ok, err = pcall(function() window:Save(configName) end)
        if ok then
            window:Notify({ title = "Config", content = "Config '"..configName.."' saved!", duration = 3 })
        else
            window:Notify({ title = "Config", content = "Save failed: "..tostring(err), duration = 4 })
        end
    end,
})

cfgTab:CreateButton({
    name     = "Load Config",
    callback = function()
        if configName == "" then
            window:Notify({ title = "Config", content = "Enter config name first!", duration = 3 })
            return
        end
        local ok, err = pcall(function() window:Load(configName) end)
        if ok then
            window:Notify({ title = "Config", content = "Config '"..configName.."' loaded!", duration = 3 })
        else
            window:Notify({ title = "Config", content = "Load failed: "..tostring(err), duration = 4 })
        end
    end,
})

cfgTab:CreateButton({
    name     = "Delete Config",
    callback = function()
        if configName == "" then
            window:Notify({ title = "Config", content = "Enter config name first!", duration = 3 })
            return
        end
        local ok, err = pcall(function() window:DeleteConfig(configName) end)
        if ok then
            window:Notify({ title = "Config", content = "Config '"..configName.."' deleted!", duration = 3 })
            configName = ""
            configInput:Set("", true)
        else
            window:Notify({ title = "Config", content = "Delete failed: "..tostring(err), duration = 4 })
        end
    end,
})

-- ── stats loop ────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            local ls   = localplayer:FindFirstChild("leaderstats")
            local cash  = ls and ls:FindFirstChild("Cash")  and ls.Cash.Value  or 0
            local rank  = ls and ls:FindFirstChild("Rank")  and ls.Rank.Value  or "-"
            local level = ls and ls:FindFirstChild("Level") and ls.Level.Value or 0
            local xp    = localplayer:FindFirstChild("XP")    and localplayer.XP.Value    or 0
            local maxXP = localplayer:FindFirstChild("MaxXP") and localplayer.MaxXP.Value or 0
            local pts   = localplayer:GetAttribute("TrafficRunPoints") or 0
            local combo = localplayer:GetAttribute("DrivingCombo")     or 0
            local chase = localplayer:GetAttribute("PoliceChaseCash")  or 0
            local earned = math.max(0, cash - cfg.StartCash)

            if cfg.SelectedMode == "Police Chase" and chase > 0 then
                earningText:Set("+$"..formatCash(earned).." (Chase: $"..formatCash(chase)..")")
            else
                earningText:Set("+$"..formatCash(earned).." (Total: $"..formatCash(cash)..")")
            end
            pointText:Set(formatCash(pts).." PTS ("..tostring(combo).."X Combo)")
            rankText:Set(tostring(rank))
            levelText:Set("Level "..tostring(level))
            xpText:Set(formatCash(xp).." / "..formatCash(maxXP))
            overtakeText:Set(tostring(cfg.TotalOvertakes))
        end)
    end
end)

-- ── autofarm loop ─────────────────────────────────────────────────────────
task.spawn(function()
    local waypoints
    local retries = 0
    while not waypoints and retries < 25 do
        task.wait(0.5); waypoints = getWaypoints(); retries += 1
    end
    if not waypoints then return end

    local function nearestWpIdx(pos)
        local best, idx = math.huge, 1
        for i = 1, #waypoints do
            local a = waypoints[i]
            local b = waypoints[i % #waypoints + 1]
            local closest = closestOnSegment(pos, a, b)
            local d = (pos - closest).Magnitude
            if d < best then best = d; idx = i end
        end
        return idx
    end

    local function nearestPolice(pos)
        local best, closest = math.huge, nil
        for k in pairs(policeSet) do
            if k.Parent then
                local pp = k.PrimaryPart or k:FindFirstChild("CollisionShell") or k:FindFirstChild("DriveSeat")
                if pp then
                    local d = (pp.Position - pos).Magnitude
                    if d < best then best = d; closest = k end
                end
            else
                policeSet[k] = nil; unregisterModel(k)
            end
        end
        return closest, best
    end

    local function getAChassisTune(vehicle)
        local at = vehicle and vehicle:FindFirstChild("A-Chassis Tune")
        at = at and at:FindFirstChild("A-Chassis Interface")
        return at and at:FindFirstChild("Values")
    end

    local function dismissBusted()
        pcall(function()
            local gui = localplayer.PlayerGui:FindFirstChild("PoliceBustedUI")
            if gui and gui.Enabled then
                local skip = gui:FindFirstChild("Skip", true)
                if skip and skip:IsA("GuiButton") and skip.Visible then
                    firesignal(skip.Activated)
                end
                local close = gui:FindFirstChild("Close", true)
                if close and close:IsA("GuiButton") and close.Visible then
                    firesignal(close.Activated)
                end
            end
        end)
    end

    local wpIdx    = 1
    local laneOff  = 0
    local laneTarget = 0
    local laneDir  = 1
    local velSmooth = 0
    local idle = "IDLE"
    local chaseCashPeak = 0
    local chaseCashTime = 0
    local policeTime    = 0

    while true do
        if not cfg.AutoFarm then task.wait(0.4); continue end

        local vehicle, seat = getVehicle()
        if not vehicle or not seat then
            if spawnCarEvent then
                spawnCarEvent:FireServer(cfg.SelectedCar)
                task.wait(2)
                vehicle, seat = getVehicle()
            end
            if not vehicle or not seat then task.wait(0.5); continue end
        end

        if seat.Position.Y > 80 and seat.Position.X > -3800 then
            while isInCombo() do
                if not cfg.AutoFarm then break end
                seat.AssemblyLinearVelocity = Vector3.zero
                velSmooth = 0
                task.wait(0.5)
            end
            if cfg.SelectedMode == "Police Chase" then
                if not doPolicePad(vehicle, seat) then task.wait(0.5); continue end
                task.wait(1)
                vehicle, seat = getVehicle()
                if not vehicle or not seat then task.wait(0.5); continue end
                idle = "WAITING_POLICE"
                policeTime  = os.clock()
                chaseCashPeak = 0
                chaseCashTime = os.clock()
                velSmooth = 0
            end
            if not teleportDown(vehicle, seat) then task.wait(0.5); continue end
            wpIdx = nearestWpIdx(seat.Position)
        end

        if cfg.SelectedMode == "Police Chase" then
            local status = localplayer:GetAttribute("PoliceStatus")
            local wanted = tonumber(localplayer:GetAttribute("Wanted")) or 0
            if status ~= "CHASE" and wanted == 0 and seat.Position.Y < 80 then
                idle = "IDLE"; velSmooth = 0
                seat.AssemblyLinearVelocity = Vector3.zero
                dismissBusted()
                local bustedActive = localplayer:GetAttribute("PoliceBustedScreenActive")
                if bustedActive then
                    local bt = os.clock()
                    while localplayer:GetAttribute("PoliceBustedScreenActive") and os.clock()-bt < 6 do
                        if not cfg.AutoFarm then break end
                        dismissBusted(); task.wait(0.5)
                    end
                    task.wait(1.5)
                end
                while isInCombo() do
                    if not cfg.AutoFarm then break end
                    seat.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.5)
                end
                teleportUp(vehicle, seat)
                task.wait(1); continue
            end
        end

        local pos = seat.Position
        local atLap = (cfg.SelectedMode ~= "Police Chase"
            and wpIdx > 500
            and pos.Z <= 1650 and pos.Z >= 1350
            and pos.X > -3530 and pos.X < -3470)

        if not atLap then
            local targetSpd = cfg.Speed
            local closestPolice, policeDist = nil, math.huge

            if cfg.SelectedMode == "Police Chase" then
                if cfg.ZeroLag then applyZeroLag() end
                closestPolice, policeDist = nearestPolice(seat.Position)
                if idle == "WAITING_POLICE" then
                    targetSpd = 18
                    local busted = tonumber(localplayer:GetAttribute("Busted")) or 0
                    if busted > 0.01 or policeDist < 85 or os.clock()-policeTime > 8 then
                        idle = "CHASING"
                    end
                elseif idle == "CHASING" or idle == "ESCAPING" then
                    local cc = tonumber(localplayer:GetAttribute("PoliceChaseCash")) or 0
                    if cc > chaseCashPeak then chaseCashPeak = cc; chaseCashTime = os.clock() end
                    local cashDone = cc >= maxCash or cc >= 70000
                        or (cc >= 4000 and os.clock()-chaseCashTime > 6)
                    if idle == "ESCAPING" or cashDone then
                        idle = "ESCAPING"; targetSpd = 250
                    else
                        local busted = tonumber(localplayer:GetAttribute("Busted")) or 0
                        local evade  = tonumber(localplayer:GetAttribute("PoliceEvadeProgress")) or 0
                        local clamp  = math.clamp(cfg.Speed, 75, 105)
                        if evade > 0.03 then
                            targetSpd = evade>0.4 and 35 or evade>0.2 and 50 or evade>0.08 and 65 or 75
                        elseif busted > 0.03 then
                            targetSpd = busted>0.4 and 160 or busted>0.2 and 135 or busted>0.08 and 115 or 100
                        else
                            targetSpd = clamp
                            if policeDist < 45 then targetSpd = clamp+12
                            elseif policeDist > 160 and policeDist < math.huge then targetSpd = clamp-12 end
                        end
                    end
                end
            end

            local wA = waypoints[wpIdx]
            local wB = waypoints[wpIdx % #waypoints + 1]
            local proj, t = closestOnSegment(pos, wA, wB)
            if (pos - proj).Magnitude > 45 then
                wpIdx = nearestWpIdx(pos)
                wA = waypoints[wpIdx]; wB = waypoints[wpIdx % #waypoints + 1]
                proj, t = closestOnSegment(pos, wA, wB)
            end

            local seg = wB - wA
            local segMag = seg.Magnitude
            local dir  = seg.Unit
            local right = Vector3.new(-dir.Z, 0, dir.X).Unit
            local dt = 0.02
            local accelRate = 50; local brakeRate = 80

            if velSmooth < targetSpd then
                velSmooth = math.min(targetSpd, velSmooth + accelRate*dt)
                pcall(function()
                    seat.Throttle=1; seat.ThrottleFloat=1
                    local av = getAChassisTune(vehicle)
                    if av then
                        if av:FindFirstChild("Throttle") then av.Throttle.Value=1 end
                        if av:FindFirstChild("Brake")    then av.Brake.Value=0    end
                    end
                end)
            elseif velSmooth > targetSpd then
                velSmooth = math.max(targetSpd, velSmooth - brakeRate*dt)
                pcall(function()
                    seat.Throttle=0; seat.ThrottleFloat=0
                    local av = getAChassisTune(vehicle)
                    if av then
                        if av:FindFirstChild("Throttle") then av.Throttle.Value=0   end
                        if av:FindFirstChild("Brake")    then av.Brake.Value=0.4    end
                    end
                end)
            else
                pcall(function()
                    seat.Throttle=0.7; seat.ThrottleFloat=0.7
                    local av = getAChassisTune(vehicle)
                    if av and av:FindFirstChild("Throttle") then av.Throttle.Value=0.7 end
                end)
            end

            local mph2studs = 1.76
            local ahead = (t * segMag) + velSmooth * mph2studs * dt
            local remainSeg = segMag
            local curA, curB = wA, wB
            local curDir = dir

            while ahead >= remainSeg and remainSeg > 0.01 do
                wpIdx = wpIdx % #waypoints + 1
                curA = waypoints[wpIdx]
                curB = waypoints[wpIdx % #waypoints + 1]
                local s = curB - curA
                curDir = s.Unit
                ahead = ahead - remainSeg
                remainSeg = s.Magnitude
            end
            local targetPt = curA + curDir * math.clamp(ahead, 0, remainSeg)

            -- police chase special logic
            if cfg.SelectedMode == "Police Chase" then
                local cc = tonumber(localplayer:GetAttribute("PoliceChaseCash")) or 0
                local cashDone = cc >= maxCash or cc >= 70000
                    or (cc >= 4000 and os.clock()-chaseCashTime > 6)
                if idle == "ESCAPING" or cashDone then
                    pcall(function()
                        for _, pai in ipairs(CollectionService:GetTagged("PoliceAI")) do
                            if pai:IsA("Model") then
                                pai:PivotTo(CFrame.new(seat.Position - dir*3500))
                                local pp = pai.PrimaryPart or pai:FindFirstChild("CollisionShell") or pai:FindFirstChild("DriveSeat")
                                if pp then pp.AssemblyLinearVelocity = Vector3.zero end
                            end
                        end
                        for k in pairs(policeSet) do
                            if k.Parent and k:IsA("Model") then
                                k:PivotTo(CFrame.new(seat.Position - dir*3500))
                                local pp = k.PrimaryPart or k:FindFirstChild("CollisionShell") or k:FindFirstChild("DriveSeat")
                                if pp then pp.AssemblyLinearVelocity = Vector3.zero end
                            end
                        end
                    end)
                elseif idle == "CHASING" and closestPolice then
                    if not strippedSet[closestPolice] then stripModel(closestPolice) end
                    pcall(function()
                        local behindPt = seat.Position - dir*45
                        local bp = Vector3.new(behindPt.X, seat.Position.Y, behindPt.Z)
                        closestPolice:PivotTo(CFrame.lookAt(bp, bp+dir))
                        local pp = closestPolice.PrimaryPart
                            or closestPolice:FindFirstChild("CollisionShell")
                            or closestPolice:FindFirstChild("DriveSeat")
                        if pp and pp:IsA("BasePart") then
                            pp.AssemblyLinearVelocity = seat.AssemblyLinearVelocity
                        end
                    end)
                end
            end

            -- lane weave
            local near_L, near_C, near_R = math.huge, math.huge, math.huge
            local block_L, block_C, block_R = false, false, false
            if trafficFolder then
                for _, car in ipairs(trafficFolder:GetChildren()) do
                    if not strippedSet[car] then stripModel(car) end
                    local hb = car:FindFirstChild("CoreHitbox") or car.PrimaryPart
                    if not hb then continue end
                    local rel = hb.Position - pos
                    local fwd = rel:Dot(dir)
                    if fwd < -30 or fwd > cfg.LookAheadDist then continue end
                    local side = (hb.Position - targetPt):Dot(right)
                    if side < -6.5 then
                        if fwd > 0 then near_L = math.min(near_L, fwd) end
                        if fwd >= -28 and fwd <= 30 then block_L = true end
                    elseif side > 6.5 then
                        if fwd > 0 then near_R = math.min(near_R, fwd) end
                        if fwd >= -28 and fwd <= 30 then block_R = true end
                    else
                        if fwd > 0 then near_C = math.min(near_C, fwd) end
                        if fwd >= -28 and fwd <= 30 then block_C = true end
                    end
                end
            end

            local free_L = not block_L and near_L > 30
            local free_C = not block_C and near_C > 30
            local free_R = not block_R and near_R > 30
            local lw = cfg.LaneWidth
            local minClear = math.clamp(velSmooth*0.45, 52, 75)
            local mergeClear = minClear + 18

            if laneTarget > 6.5 then
                if near_R < minClear then
                    if free_C then laneTarget = 0
                    elseif free_L and near_L > near_C then laneTarget = -lw; laneDir = -1 end
                elseif free_C and near_C > mergeClear and near_R > mergeClear then
                    laneTarget = 0
                end
            elseif laneTarget < -6.5 then
                if near_L < minClear then
                    if free_C then laneTarget = 0
                    elseif free_R and near_R > near_C then laneTarget = lw; laneDir = 1 end
                elseif free_C and near_C > mergeClear and near_L > mergeClear then
                    laneTarget = 0
                end
            elseif near_C < minClear then
                if free_L and free_R then
                    if near_L > minClear and near_R > minClear then
                        laneDir = -laneDir; laneTarget = laneDir * lw
                    elseif near_L > near_R then laneTarget = -lw; laneDir = -1
                    elseif near_R > near_L then laneTarget = lw;  laneDir = 1
                    else laneDir = -laneDir; laneTarget = laneDir * lw end
                elseif free_L then laneTarget = -lw; laneDir = -1
                elseif free_R then laneTarget = lw;  laneDir = 1 end
            else
                laneTarget = 0
            end

            laneOff = laneOff + (laneTarget - laneOff)
                * math.clamp(dt * cfg.WeaveLerpSpeed, 0, 1)

            local finalPt = targetPt + right * laneOff
            local gy = groundY(finalPt, vehicle)
            local gp = Vector3.new(finalPt.X, gy, finalPt.Z)
            vehicle:PivotTo(CFrame.lookAt(gp, gp + curDir))
            seat.AssemblyLinearVelocity = curDir * (velSmooth * mph2studs)

            if updateSpeedBridge then
                updateSpeedBridge:Fire(math.floor(velSmooth))
            end
            task.wait(dt)
        else
            teleportUp(vehicle, seat)
            if teleportDown(vehicle, seat) then
                wpIdx = nearestWpIdx(seat.Position)
            else
                task.wait(0.5)
            end
        end
    end
end)