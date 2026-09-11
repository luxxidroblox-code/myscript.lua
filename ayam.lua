--[[
    DX-SR Hub â€” Merged
    Base    : Doc2 (vehicleFly tween stable)
    Fix     : Vehicle spawn logic dari Doc1 (retry 6x, rdFindAndSit hardened)
    Tween/Drive: DOC2 TIDAK DIUBAH
]]

--=====================================================================
-- ANTI-CHEAT / ANTI-TAMPER DETECTION
--=====================================================================
local JAWADEOBF_hookedThreads = {}

local JAWADEOBF_detectAntiCheat = function()
    if not getreg or not getgc or not isfunctionhooked then
        return false
    end
    local JAWADEOBF_found = false
    for JAWADEOBF_idx, JAWADEOBF_thread in getreg() do
        if typeof(JAWADEOBF_thread) ~= "thread" then continue end
        local JAWADEOBF_info = debug.info(JAWADEOBF_thread, 1, "s")
        if JAWADEOBF_info
            and (JAWADEOBF_info:match(".Core.Anti")
                or JAWADEOBF_info:match(".Plugins.Anti_Cheat")) then
            JAWADEOBF_found = true
            table.insert(JAWADEOBF_hookedThreads, JAWADEOBF_thread)
        end
    end
    return JAWADEOBF_found
end

local JAWADEOBF_neutralizeAntiCheat = function()
    for JAWADEOBF_i, JAWADEOBF_thread in JAWADEOBF_hookedThreads do
        pcall(coroutine.close, JAWADEOBF_thread)
    end
    local JAWADEOBF_targets = {}
    if filtergc then
        local JAWADEOBF_tables = filtergc("table", { Keys = { "Detected", "RLocked" } }, false)
        for JAWADEOBF_i, JAWADEOBF_tbl in JAWADEOBF_tables do
            if typeof(rawget(JAWADEOBF_tbl, "Detected")) ~= "function" then continue end
            table.insert(JAWADEOBF_targets, JAWADEOBF_tbl)
        end
    else
        for JAWADEOBF_i, JAWADEOBF_tbl in getgc(true) do
            if typeof(JAWADEOBF_tbl) ~= "table" then continue end
            local JAWADEOBF_isTarget =
                typeof(rawget(JAWADEOBF_tbl, "Detected")) == "function"
                and rawget(JAWADEOBF_tbl, "RLocked")
            if not JAWADEOBF_isTarget then continue end
            table.insert(JAWADEOBF_targets, JAWADEOBF_tbl)
        end
    end
    for JAWADEOBF_i, JAWADEOBF_tbl in JAWADEOBF_targets do
        for JAWADEOBF_k, JAWADEOBF_fn in JAWADEOBF_tbl do
            if typeof(JAWADEOBF_fn) ~= "function" or isfunctionhooked(JAWADEOBF_fn) then continue end
            hookfunction(JAWADEOBF_fn, function(...)
                coroutine.yield(coroutine.running())
                return task.wait(9000000000)
            end)
        end
    end
    return true
end

if JAWADEOBF_detectAntiCheat() then JAWADEOBF_neutralizeAntiCheat() end

--=====================================================================
-- ADONIS REMOTE SECURITY
--=====================================================================
pcall(secureAdonisRemote)
task.spawn(function()
    while task.wait(2) do pcall(secureAdonisRemote) end
end)

--=====================================================================
-- ANTI-IDLE
--=====================================================================
local JAWADEOBF_enableAntiIdle = true
if JAWADEOBF_enableAntiIdle then
    local JAWADEOBF_Players = game:GetService("Players")
    local JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
    local JAWADEOBF_hooked = false
    if getconnections then
        pcall(function()
            for JAWADEOBF_i, JAWADEOBF_conn in pairs(getconnections(JAWADEOBF_LP.Idled)) do
                if JAWADEOBF_conn.Disable then
                    JAWADEOBF_conn:Disable(); JAWADEOBF_hooked = true
                elseif JAWADEOBF_conn.Disconnect then
                    JAWADEOBF_conn:Disconnect(); JAWADEOBF_hooked = true
                end
            end
        end)
    end
    if not JAWADEOBF_hooked then
        JAWADEOBF_LP.Idled:Connect(function()
            pcall(function()
                local JAWADEOBF_VU = game:FindService("VirtualUser") or game:GetService("VirtualUser")
                if JAWADEOBF_VU then
                    JAWADEOBF_VU:CaptureController()
                    JAWADEOBF_VU:ClickButton2(Vector2.new())
                end
            end)
        end)
    end
end

--=====================================================================
-- MAIN MENU BYPASS
--=====================================================================
local JAWADEOBF_bypassMainMenu = function()
    pcall(function()
        local JAWADEOBF_Lighting = game:GetService("Lighting")
        local JAWADEOBF_blur = JAWADEOBF_Lighting:FindFirstChild("menuBlur")
        if JAWADEOBF_blur then JAWADEOBF_blur.Enabled = false; JAWADEOBF_blur.Size = 0 end

        local JAWADEOBF_Players = game:GetService("Players")
        local JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
        local JAWADEOBF_PG = JAWADEOBF_LP and JAWADEOBF_LP:FindFirstChild("PlayerGui")
        if JAWADEOBF_PG then
            local JAWADEOBF_menu = JAWADEOBF_PG:FindFirstChild("mainMenuSystem")
            if JAWADEOBF_menu then
                JAWADEOBF_menu.Enabled = false
                local JAWADEOBF_base = JAWADEOBF_menu:FindFirstChild("baseFrame")
                if JAWADEOBF_base then
                    JAWADEOBF_base.Visible = false
                    local JAWADEOBF_snd = JAWADEOBF_base:FindFirstChild("SoundHome")
                    if JAWADEOBF_snd and JAWADEOBF_snd:IsA("Sound") then JAWADEOBF_snd:Stop() end
                end
                local JAWADEOBF_inter = JAWADEOBF_menu:FindFirstChild("intermissionFrame")
                if JAWADEOBF_inter then JAWADEOBF_inter.Visible = false end
            end
            local JAWADEOBF_mainUI = JAWADEOBF_PG:FindFirstChild("MainUI")
            if JAWADEOBF_mainUI then JAWADEOBF_mainUI.Enabled = true end
        end

        local JAWADEOBF_cam = workspace.CurrentCamera
        if JAWADEOBF_cam then JAWADEOBF_cam.CameraType = Enum.CameraType.Custom end

        pcall(function()
            game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)

        local JAWADEOBF_toggle = game:GetService("ReplicatedStorage"):FindFirstChild("menuToggleRequest")
        if JAWADEOBF_toggle and JAWADEOBF_toggle:IsA("RemoteEvent") then
            JAWADEOBF_toggle:FireServer()
        end
    end)
end

task.spawn(function()
    JAWADEOBF_bypassMainMenu()
    local JAWADEOBF_Players = game:GetService("Players")
    local JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
    local JAWADEOBF_PG = JAWADEOBF_LP and JAWADEOBF_LP:WaitForChild("PlayerGui", 10)
    if JAWADEOBF_PG then
        JAWADEOBF_PG.ChildAdded:Connect(function(JAWADEOBF_child)
            if JAWADEOBF_child.Name == "mainMenuSystem" then
                task.wait(0.1)
                JAWADEOBF_bypassMainMenu()
            end
        end)
    end
end)

--=====================================================================
-- WINDUI INIT
--=====================================================================
local JAWADEOBF_WindUI = loadstring(
    game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
)()

local JAWADEOBF_Window = JAWADEOBF_WindUI:CreateWindow({
    Title                       = "DDS",
    Icon                        = "van",
    Author                      = "DX-SR Hub",
    Folder                      = "DX-SR",
    Size                        = UDim2.fromOffset(580, 460),
    MinSize                     = Vector2.new(560, 350),
    MaxSize                     = Vector2.new(850, 560),
    ToggleKey                   = Enum.KeyCode.V,
    Transparent                 = true,
    Theme                       = "Dark",
    Resizable                   = true,
    SideBarWidth                = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar               = false,
    ScrollBarEnabled            = false,
})

JAWADEOBF_Window:Tag({ Title = "v0.0.0.15", Icon = "github",      Color = Color3.fromHex("#30ff6a"), Radius = 13 })
JAWADEOBF_Window:Tag({ Title = "DX-SR Hub", Icon = "text-cursor", Color = Color3.fromHex("#1E3A8A"), Radius = 13 })

JAWADEOBF_WindUI:Popup({
    Title   = "Update logs",
    Icon    = "info",
    Content = "Spawn hardened (retry 6x) + vehicleFly doc2 stable",
    Buttons = {{ Title = "Continue", Icon = "arrow-right", Callback = function() end, Variant = "Primary" }},
})

--=====================================================================
-- SECTION: FARMING
--=====================================================================
local JAWADEOBF_FarmingSection = JAWADEOBF_Window:Section({ Title = "Farming", Icon = "car", Opened = true })

--=====================================================================
-- TAB: RIDEGO
--=====================================================================
local JAWADEOBF_RidegoTab = JAWADEOBF_FarmingSection:Tab({ Title = "Ridego", Icon = "car" })
local JAWADEOBF_RidegoSection = JAWADEOBF_RidegoTab:Section({ Title = "Ridego Farming" })

-- â”€â”€ tunables (doc2) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local JAWADEOBF_tweenSpeed  = 200
local JAWADEOBF_tweenHeight = 20

JAWADEOBF_RidegoTab:Slider({
    Title = "Tween Speed", Desc = "Kecepatan terbang", Step = 10,
    Flag  = "RidegoTweenSpeed", Value = { Min = 0, Max = 500, Default = 200 },
    Callback = function(v) JAWADEOBF_tweenSpeed = v end,
})

JAWADEOBF_RidegoTab:Slider({
    Title = "Tween Height", Desc = "Ketinggian dari tanah", Step = 1,
    Flag  = "RidegoTweenHeight", Value = { Min = 0, Max = 100, Default = 50 },
    Callback = function(v) JAWADEOBF_tweenHeight = v end,
})

-- â”€â”€ vehicle list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local JAWADEOBF_vehicleList     = { "Sizuki-SatriaFU(Drag)" }
local JAWADEOBF_selectedVehicle = JAWADEOBF_vehicleList[1]

local JAWADEOBF_fetchVehicles = function()
    local JAWADEOBF_list = {}
    pcall(function()
        local JAWADEOBF_RS = game:GetService("ReplicatedStorage")
        local JAWADEOBF_DE = JAWADEOBF_RS:FindFirstChild("DealershipEvents")
        if JAWADEOBF_DE and JAWADEOBF_DE:FindFirstChild("InitializeCarData") then
            local JAWADEOBF_data = JAWADEOBF_DE.InitializeCarData:InvokeServer()
            if type(JAWADEOBF_data) == "table" then
                for _, JAWADEOBF_car in ipairs(JAWADEOBF_data) do
                    if JAWADEOBF_car.Name then table.insert(JAWADEOBF_list, JAWADEOBF_car.Name) end
                end
            end
        end
    end)
    if #JAWADEOBF_list == 0 then table.insert(JAWADEOBF_list, "Sizuki-SatriaFU(Drag)") end
    return JAWADEOBF_list
end

JAWADEOBF_vehicleList = JAWADEOBF_fetchVehicles()

local JAWADEOBF_vehicleDropdown = JAWADEOBF_RidegoTab:Dropdown({
    Title = "Select Vehicle", Desc = "Choose a vehicle to spawn",
    Multi = false, Flag = "RidegoSelectedVehicle",
    Value = JAWADEOBF_selectedVehicle, Values = JAWADEOBF_vehicleList,
    Callback = function(v) JAWADEOBF_selectedVehicle = v end,
})

JAWADEOBF_RidegoTab:Button({
    Title = "Refresh Vehicles", Desc = "Refresh your vehicle list",
    Callback = function()
        JAWADEOBF_vehicleList = JAWADEOBF_fetchVehicles()
        pcall(function() JAWADEOBF_vehicleDropdown:Refresh(JAWADEOBF_vehicleList) end)
        JAWADEOBF_WindUI:Notify({ Title = "Refresh", Content = "Vehicle list updated!", Duration = 3 })
    end,
})

-- â”€â”€ state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local JAWADEOBF_ridegoEnabled = false
local JAWADEOBF_ridegoBusy    = false

--=====================================================================
-- SEAT TELEPORT (doc2, unchanged)
--=====================================================================
local JAWADEOBF_seatTeleport = function(JAWADEOBF_cf)
    local JAWADEOBF_LP   = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character
    local JAWADEOBF_hrp  = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
    local JAWADEOBF_hum  = JAWADEOBF_char and JAWADEOBF_char:FindFirstChildOfClass("Humanoid")
    local JAWADEOBF_anim = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("Animate")
    if not JAWADEOBF_hrp or not JAWADEOBF_hum then return end

    if JAWADEOBF_hum.Sit then JAWADEOBF_hum.Sit = false; task.wait(0.1) end
    if JAWADEOBF_anim then JAWADEOBF_anim.Disabled = true end

    local JAWADEOBF_seat      = Instance.new("Seat")
    JAWADEOBF_seat.Size        = Vector3.new(2, 0.2, 2)
    JAWADEOBF_seat.Transparency = 1
    JAWADEOBF_seat.CanCollide  = false
    JAWADEOBF_seat.Anchored    = true
    JAWADEOBF_seat.CFrame      = JAWADEOBF_hrp.CFrame
    JAWADEOBF_seat.Parent      = workspace

    JAWADEOBF_hum.Sit = true
    JAWADEOBF_seat:Sit(JAWADEOBF_hum)

    local JAWADEOBF_bv     = Instance.new("BodyVelocity")
    JAWADEOBF_bv.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
    JAWADEOBF_bv.Velocity  = Vector3.new(0, 0, 0)
    JAWADEOBF_bv.Parent    = JAWADEOBF_hrp

    task.wait(0.5)
    JAWADEOBF_seat.Anchored = false

    local JAWADEOBF_target = JAWADEOBF_cf * CFrame.new(0, 0.01, 0)
    local JAWADEOBF_mid    = JAWADEOBF_hrp.CFrame:Lerp(JAWADEOBF_target, 0.5)
    JAWADEOBF_seat.CFrame  = JAWADEOBF_mid; JAWADEOBF_hrp.CFrame = JAWADEOBF_mid
    task.wait(0.1)
    JAWADEOBF_seat.CFrame  = JAWADEOBF_target; JAWADEOBF_hrp.CFrame = JAWADEOBF_target
    JAWADEOBF_seat.Anchored = true

    task.wait(1.6)
    if JAWADEOBF_bv then JAWADEOBF_bv:Destroy() end
    JAWADEOBF_hum.Sit = false
    if JAWADEOBF_anim then JAWADEOBF_anim.Disabled = false end
    task.wait(0.3)
    if JAWADEOBF_seat then JAWADEOBF_seat:Destroy() end
    JAWADEOBF_hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    workspace.CurrentCamera.CameraSubject = JAWADEOBF_hum
end

--=====================================================================
-- SPAWN VEHICLE â€” DOC1 HARDENED (retry 6x, tunggu model LP di workspace)
--=====================================================================
local JAWADEOBF_rdSpawnVehicle = function()
    local JAWADEOBF_RS = game:GetService("ReplicatedStorage")
    local JAWADEOBF_SE = JAWADEOBF_RS:FindFirstChild("SpawnCarEvents")
    if not JAWADEOBF_SE then return false end

    local JAWADEOBF_despawn = JAWADEOBF_SE:FindFirstChild("DespawnCar")
    local JAWADEOBF_spawn   = JAWADEOBF_SE:FindFirstChild("SpawnCar")
    if not JAWADEOBF_spawn then return false end

    -- bersih dulu
    if JAWADEOBF_despawn then pcall(function() JAWADEOBF_despawn:FireServer() end) end
    task.wait(1.5)

    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer

    for attempt = 1, 6 do
        pcall(function() JAWADEOBF_spawn:FireServer(JAWADEOBF_selectedVehicle) end)

        local deadline = os.clock() + 8
        while os.clock() < deadline do
            task.wait(0.4)
            for _, obj in ipairs(workspace:GetChildren()) do
                if string.match(obj.Name, "^" .. JAWADEOBF_LP.Name .. "Montors_") then
                    local seat = obj:FindFirstChildWhichIsA("VehicleSeat", true)
                    if seat then return true end
                end
            end
        end

        JAWADEOBF_WindUI:Notify({
            Title   = "RideGO Spawn",
            Content = "Retry " .. attempt .. "/6 â€” belum muncul...",
            Duration = 2,
        })

        if JAWADEOBF_despawn then pcall(function() JAWADEOBF_despawn:FireServer() end) end
        task.wait(2)
    end
    return false
end

--=====================================================================
-- FIND AND SIT â€” DOC1 HARDENED
-- Hapus FrontSection/RearSection, proximity prompt + fallback Sit
--=====================================================================
local JAWADEOBF_rdFindAndSit = function()
    local JAWADEOBF_LP   = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character
    local JAWADEOBF_root = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
    local JAWADEOBF_hum  = JAWADEOBF_char and JAWADEOBF_char:FindFirstChildOfClass("Humanoid")
    if not JAWADEOBF_root or not JAWADEOBF_hum then return false end

    local JAWADEOBF_myCar = nil
    for _, obj in ipairs(workspace:GetChildren()) do
        if string.match(obj.Name, "^" .. JAWADEOBF_LP.Name .. "Montors_") then
            JAWADEOBF_myCar = obj; break
        end
    end
    if not JAWADEOBF_myCar then return false end

    -- hapus barrier
    pcall(function()
        local fs = JAWADEOBF_myCar:FindFirstChild("FrontSection")
        local rs = JAWADEOBF_myCar:FindFirstChild("RearSection")
        if fs then fs:Destroy() end
        if rs then rs:Destroy() end
    end)

    local JAWADEOBF_driveSeat = JAWADEOBF_myCar:FindFirstChild("DriveSeat")
                             or JAWADEOBF_myCar:FindFirstChildWhichIsA("VehicleSeat", true)
    if not JAWADEOBF_driveSeat then return false end

    -- snap karakter ke atas seat
    JAWADEOBF_root.CFrame = JAWADEOBF_driveSeat.CFrame * CFrame.new(0, 1.5, 0)
    task.wait(0.35)

    -- coba proximity prompt
    local JAWADEOBF_prompt = JAWADEOBF_driveSeat:FindFirstChildWhichIsA("ProximityPrompt")
    if JAWADEOBF_prompt and JAWADEOBF_prompt.Enabled then
        pcall(function() fireproximityprompt(JAWADEOBF_prompt) end)
        task.wait(0.8)
    end

    -- fallback: Sit langsung
    if not JAWADEOBF_hum.Sit then
        JAWADEOBF_driveSeat:Sit(JAWADEOBF_hum)
        task.wait(0.5)
    end

    return JAWADEOBF_hum.Sit
end

--=====================================================================
-- VEHICLE FLY â€” DOC2 UNCHANGED (stable tween, hard stop on arrival)
--=====================================================================
local JAWADEOBF_vehicleFly = function(JAWADEOBF_targetCF)
    local JAWADEOBF_LP   = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character

    if not (JAWADEOBF_char
        and JAWADEOBF_char:FindFirstChild("Humanoid")
        and JAWADEOBF_char.Humanoid.Sit) then
        return
    end

    local JAWADEOBF_seatPart = JAWADEOBF_char.Humanoid.SeatPart
    if not JAWADEOBF_seatPart then return end

    local JAWADEOBF_primary = JAWADEOBF_seatPart
    local JAWADEOBF_model   = JAWADEOBF_seatPart:FindFirstAncestorOfClass("Model")
    if JAWADEOBF_model and JAWADEOBF_model.PrimaryPart then
        JAWADEOBF_primary = JAWADEOBF_model.PrimaryPart
    end

    local JAWADEOBF_targetPos = JAWADEOBF_targetCF.Position
    local JAWADEOBF_RunService = game:GetService("RunService")

    local JAWADEOBF_conn = JAWADEOBF_RunService.Stepped:Connect(function()
        if JAWADEOBF_model then
            for _, JAWADEOBF_p in ipairs(JAWADEOBF_model:GetDescendants()) do
                if JAWADEOBF_p:IsA("BasePart") then JAWADEOBF_p.CanCollide = false end
            end
        end
        if JAWADEOBF_char then
            for _, JAWADEOBF_p in ipairs(JAWADEOBF_char:GetDescendants()) do
                if JAWADEOBF_p:IsA("BasePart") then JAWADEOBF_p.CanCollide = false end
            end
        end
        pcall(function()
            local JAWADEOBF_missions = workspace:FindFirstChild("ActiveMissions")
            if JAWADEOBF_missions then
                local JAWADEOBF_pass = JAWADEOBF_missions:FindFirstChild("RideGO_Passenger")
                if JAWADEOBF_pass then
                    for _, JAWADEOBF_p in ipairs(JAWADEOBF_pass:GetDescendants()) do
                        if JAWADEOBF_p:IsA("BasePart") then JAWADEOBF_p.CanCollide = false end
                    end
                end
            end
        end)
    end)

    local JAWADEOBF_gyro     = Instance.new("BodyGyro")
    JAWADEOBF_gyro.P         = 90000
    JAWADEOBF_gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    JAWADEOBF_gyro.D         = 50
    JAWADEOBF_gyro.Parent    = JAWADEOBF_primary

    local JAWADEOBF_bv       = Instance.new("BodyVelocity")
    JAWADEOBF_bv.MaxForce    = Vector3.new(9e9, 9e9, 9e9)
    JAWADEOBF_bv.Velocity    = Vector3.zero
    JAWADEOBF_bv.Parent      = JAWADEOBF_primary

    if JAWADEOBF_model then
        for _, JAWADEOBF_p in ipairs(JAWADEOBF_model:GetDescendants()) do
            if JAWADEOBF_p:IsA("BasePart") then JAWADEOBF_p.Anchored = false end
        end
    end

    local JAWADEOBF_speed     = 230
    local JAWADEOBF_startTime = os.clock()

    while JAWADEOBF_ridegoEnabled do
        if not JAWADEOBF_primary or not JAWADEOBF_primary.Parent then break end

        local JAWADEOBF_cur   = JAWADEOBF_primary.Position
        local JAWADEOBF_delta = JAWADEOBF_targetPos - JAWADEOBF_cur
        local JAWADEOBF_dist  = JAWADEOBF_delta.Magnitude

        if JAWADEOBF_dist < 15 then
            JAWADEOBF_bv.Velocity = Vector3.zero; break
        end
        if (os.clock() - JAWADEOBF_startTime) > 120 then
            JAWADEOBF_bv.Velocity = Vector3.zero; break
        end

        JAWADEOBF_gyro.CFrame = JAWADEOBF_targetCF
        JAWADEOBF_bv.Velocity = JAWADEOBF_delta.Unit * JAWADEOBF_speed
        task.wait()
    end

    if JAWADEOBF_conn then JAWADEOBF_conn:Disconnect() end

    if JAWADEOBF_primary and JAWADEOBF_primary.Parent then
        pcall(function() JAWADEOBF_bv.Velocity = Vector3.zero end)
        pcall(function() JAWADEOBF_primary.AssemblyLinearVelocity = Vector3.zero end)
        pcall(function() JAWADEOBF_primary.AssemblyAngularVelocity = Vector3.zero end)
        pcall(function() JAWADEOBF_gyro:Destroy() end)
        pcall(function() JAWADEOBF_bv:Destroy() end)

        if JAWADEOBF_model then
            for _, JAWADEOBF_p in ipairs(JAWADEOBF_model:GetDescendants()) do
                if JAWADEOBF_p:IsA("BasePart") then
                    JAWADEOBF_p.CanCollide = true
                    JAWADEOBF_p.Anchored   = false
                end
            end
            local JAWADEOBF_driveSeat = JAWADEOBF_model:FindFirstChild("DriveSeat")
            if JAWADEOBF_driveSeat then JAWADEOBF_driveSeat.CanCollide = false end
        end
    end

    if JAWADEOBF_char then
        for _, JAWADEOBF_p in ipairs(JAWADEOBF_char:GetDescendants()) do
            if JAWADEOBF_p:IsA("BasePart") then JAWADEOBF_p.CanCollide = true end
        end
    end
end

--=====================================================================
-- TAXIEVENT LISTENER
--=====================================================================
task.spawn(function()
    pcall(function()
        local JAWADEOBF_RS       = game:GetService("ReplicatedStorage")
        local JAWADEOBF_taxiEvent = JAWADEOBF_RS:WaitForChild("TaxiAssets")
            :WaitForChild("Events")
            :WaitForChild("TaxiEvent")

        JAWADEOBF_taxiEvent.OnClientEvent:Connect(function(JAWADEOBF_action, JAWADEOBF_data)
            if not JAWADEOBF_ridegoEnabled then return end

            -- â”€â”€ OrderOffer: auto accept â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if JAWADEOBF_action == "OrderOffer"
                and type(JAWADEOBF_data) == "table"
                and JAWADEOBF_data.Token then
                task.wait(1)
                JAWADEOBF_taxiEvent:FireServer("AcceptOrder", JAWADEOBF_data.Token)
                pcall(function()
                    JAWADEOBF_WindUI:Notify({ Title = "RideGO", Content = "Auto-accepted order!", Duration = 3 })
                end)

            -- â”€â”€ OrderAccepted: teleport â†’ spawn (retry 6x) â†’ sit â”€
            elseif JAWADEOBF_action == "OrderAccepted"
                and type(JAWADEOBF_data) == "table" then

                pcall(function()
                    JAWADEOBF_WindUI:Notify({
                        Title   = "Order Accepted",
                        Content = "Pickup: " .. (JAWADEOBF_data.PickupAddr or "?")
                            .. "\nDropoff: " .. (JAWADEOBF_data.DropAddr or "?"),
                        Duration = 5,
                    })
                end)

                if JAWADEOBF_data.PickupPos then
                    task.spawn(function()
                        JAWADEOBF_ridegoBusy = true

                        -- teleport ke pickup
                        local JAWADEOBF_pickupCF = CFrame.new(JAWADEOBF_data.PickupPos)
                        if JAWADEOBF_data.PickupLook then
                            JAWADEOBF_pickupCF = CFrame.lookAt(
                                JAWADEOBF_data.PickupPos,
                                JAWADEOBF_data.PickupPos + JAWADEOBF_data.PickupLook
                            )
                        end
                        JAWADEOBF_seatTeleport(JAWADEOBF_pickupCF)
                        task.wait(0.5)

                        -- spawn kendaraan â€” retry 6x (DOC1)
                        local JAWADEOBF_spawned = JAWADEOBF_rdSpawnVehicle()
                        if not JAWADEOBF_spawned then
                            JAWADEOBF_WindUI:Notify({
                                Title   = "RideGO",
                                Content = "Gagal spawn kendaraan setelah 6 retry!",
                                Duration = 5,
                            })
                            JAWADEOBF_ridegoBusy = false
                            return
                        end

                        -- tunggu server settle
                        task.wait(1.2)

                        -- sit ke kendaraan (DOC1 hardened)
                        local JAWADEOBF_seated = JAWADEOBF_rdFindAndSit()
                        if not JAWADEOBF_seated then
                            JAWADEOBF_WindUI:Notify({
                                Title   = "RideGO",
                                Content = "Tidak bisa duduk di kendaraan!",
                                Duration = 4,
                            })
                            JAWADEOBF_ridegoBusy = false
                            return
                        end

                        -- GoOnline setelah duduk
                        task.spawn(function()
                            task.wait(0.5)
                            local JAWADEOBF_rs   = game:GetService("ReplicatedStorage")
                            local JAWADEOBF_taxi = JAWADEOBF_rs:FindFirstChild("TaxiAssets")
                            if JAWADEOBF_taxi
                                and JAWADEOBF_taxi:FindFirstChild("Events")
                                and JAWADEOBF_taxi.Events:FindFirstChild("TaxiEvent") then
                                JAWADEOBF_taxi.Events.TaxiEvent:FireServer("GoOnline")
                            end
                        end)

                        JAWADEOBF_ridegoBusy = false
                    end)
                end

            -- â”€â”€ TripStarted: vehicleFly doc2 ke dropoff â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            elseif JAWADEOBF_action == "TripStarted"
                and type(JAWADEOBF_data) == "table" then

                pcall(function()
                    JAWADEOBF_WindUI:Notify({
                        Title   = "Trip Started",
                        Content = "Heading to Dropoff: " .. (JAWADEOBF_data.DropAddr or "?"),
                        Duration = 5,
                    })
                end)

                if JAWADEOBF_data.DropPos then
                    task.spawn(function()
                        JAWADEOBF_vehicleFly(CFrame.new(JAWADEOBF_data.DropPos))
                    end)
                end
            end
        end)
    end)
end)

--=====================================================================
-- TOGGLE AUTO FARM RIDEGO
--=====================================================================
local JAWADEOBF_ridegoToggle = JAWADEOBF_RidegoTab:Toggle({
    Title    = "Auto Farm Ridego",
    Flag     = "RidegoAutoFarm",
    Default  = false,
    Callback = function(JAWADEOBF_state)
        JAWADEOBF_ridegoEnabled = JAWADEOBF_state
        if not JAWADEOBF_state then return end

        -- join job
        pcall(function()
            local JAWADEOBF_RS      = game:GetService("ReplicatedStorage")
            local JAWADEOBF_teamReq = JAWADEOBF_RS.JobEvents.TeamChangeRequest
            JAWADEOBF_teamReq:FireServer("RideGO Driver", 11378976, 1, 0, "Detector")
        end)

        -- idle loop: pastikan kendaraan ada + karakter duduk (DOC1 hardened)
        task.spawn(function()
            while JAWADEOBF_ridegoEnabled do
                if not JAWADEOBF_ridegoBusy then
                    local JAWADEOBF_LP   = game:GetService("Players").LocalPlayer
                    local JAWADEOBF_char = JAWADEOBF_LP.Character
                    local JAWADEOBF_hum  = JAWADEOBF_char and JAWADEOBF_char:FindFirstChildOfClass("Humanoid")
                    local JAWADEOBF_hrp  = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")

                    if JAWADEOBF_hrp and JAWADEOBF_hum then
                        -- cek apakah kendaraan sudah ada
                        local JAWADEOBF_myCar = nil
                        for _, obj in ipairs(workspace:GetChildren()) do
                            if string.match(obj.Name, "^" .. JAWADEOBF_LP.Name .. "Montors_") then
                                JAWADEOBF_myCar = obj; break
                            end
                        end

                        if not JAWADEOBF_myCar then
                            -- spawn (retry 6x)
                            JAWADEOBF_rdSpawnVehicle()
                            task.wait(1.5)
                        elseif not JAWADEOBF_hum.Sit then
                            -- kendaraan ada tapi belum duduk
                            JAWADEOBF_rdFindAndSit()

                            task.spawn(function()
                                task.wait(0.5)
                                local JAWADEOBF_char2 = JAWADEOBF_LP.Character
                                local JAWADEOBF_hum2  = JAWADEOBF_char2 and JAWADEOBF_char2:FindFirstChildOfClass("Humanoid")
                                if JAWADEOBF_hum2 and JAWADEOBF_hum2.Sit then
                                    local JAWADEOBF_rs   = game:GetService("ReplicatedStorage")
                                    local JAWADEOBF_taxi = JAWADEOBF_rs:FindFirstChild("TaxiAssets")
                                    if JAWADEOBF_taxi
                                        and JAWADEOBF_taxi:FindFirstChild("Events")
                                        and JAWADEOBF_taxi.Events:FindFirstChild("TaxiEvent") then
                                        JAWADEOBF_taxi.Events.TaxiEvent:FireServer("GoOnline")
                                    end
                                end
                            end)
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end,
})
JAWADEOBF_ridegoToggle:Unlock()

--=====================================================================
-- WEBHOOK HELPER
--=====================================================================
local JAWADEOBF_request    = request or http_request
    or (syn and syn.request)
    or (http and http.request)

getgenv().WEBHOOK_MSG_IDS  = getgenv().WEBHOOK_MSG_IDS or {}
local JAWADEOBF_webhookIds = getgenv().WEBHOOK_MSG_IDS

local JAWADEOBF_sendWebhook = function(JAWADEOBF_url, JAWADEOBF_payload, JAWADEOBF_forceNew)
    if not JAWADEOBF_url or JAWADEOBF_url == "" or not JAWADEOBF_request then return end
    task.spawn(function()
        pcall(function()
            local JAWADEOBF_http     = game:GetService("HttpService")
            local JAWADEOBF_base     = string.gsub(JAWADEOBF_url, "%?.*$", "")
            local JAWADEOBF_existing = JAWADEOBF_webhookIds[JAWADEOBF_base]
            local JAWADEOBF_edited   = false

            if not JAWADEOBF_forceNew and JAWADEOBF_existing and JAWADEOBF_existing ~= "" then
                local JAWADEOBF_editUrl = JAWADEOBF_base .. "/messages/" .. tostring(JAWADEOBF_existing)
                local JAWADEOBF_res = JAWADEOBF_request({
                    Url     = JAWADEOBF_editUrl,
                    Method  = "PATCH",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body    = JAWADEOBF_http:JSONEncode(JAWADEOBF_payload),
                })
                if JAWADEOBF_res
                    and (JAWADEOBF_res.StatusCode == 200
                        or JAWADEOBF_res.StatusCode == 204
                        or (JAWADEOBF_res.Status and string.match(tostring(JAWADEOBF_res.Status), "^2"))) then
                    JAWADEOBF_edited = true
                end
            end

            if not JAWADEOBF_edited then
                local JAWADEOBF_postUrl = JAWADEOBF_base .. "?wait=true"
                local JAWADEOBF_res = JAWADEOBF_request({
                    Url     = JAWADEOBF_postUrl,
                    Method  = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body    = JAWADEOBF_http:JSONEncode(JAWADEOBF_payload),
                })
                if not JAWADEOBF_forceNew and JAWADEOBF_res and JAWADEOBF_res.Body then
                    local JAWADEOBF_ok, JAWADEOBF_parsed = pcall(function()
                        return JAWADEOBF_http:JSONDecode(JAWADEOBF_res.Body)
                    end)
                    if JAWADEOBF_ok and type(JAWADEOBF_parsed) == "table" and JAWADEOBF_parsed.id then
                        JAWADEOBF_webhookIds[JAWADEOBF_base] = tostring(JAWADEOBF_parsed.id)
                    end
                end
            end
        end)
    end)
end

local JAWADEOBF_formatTime = function(JAWADEOBF_sec)
    local h = math.floor(JAWADEOBF_sec / 3600)
    local m = math.floor((JAWADEOBF_sec % 3600) / 60)
    local s = math.floor(JAWADEOBF_sec % 60)
    return string.format("%02dh %02dm %02ds", h, m, s)
end

--=====================================================================
-- TELEPORT DATA PERSISTENCE
--=====================================================================
local JAWADEOBF_rejoinPayload = [[
task.spawn(function()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        local blur = Lighting:FindFirstChild("menuBlur")
        if blur then blur.Enabled = false; blur.Size = 0 end
        local player = game:GetService("Players").LocalPlayer
        if player and player:FindFirstChild("PlayerGui") then
            local mainUI = player.PlayerGui:FindFirstChild("MainUI")
            if mainUI and mainUI:FindFirstChild("Holder") then mainUI.Holder.Visible = false end
        end
        pcall(function()
            local menuEvent = game:GetService("ReplicatedStorage"):WaitForChild("menuToggleRequest", 5)
            if menuEvent and menuEvent:IsA("RemoteEvent") then menuEvent:FireServer() end
        end)
        pcall(function()
            game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)
        local cam = workspace.CurrentCamera
        if cam then cam.CameraType = Enum.CameraType.Custom end
    end)
end)
local ok, data = pcall(function()
    return game:GetService("TeleportService"):GetLocalPlayerTeleportData()
end)
if ok and typeof(data) == "CFrame" then
    local Players = game:GetService("Players")
    local ME = Players.LocalPlayer
    while not ME do Players:GetPropertyChangedSignal("LocalPlayer"):Wait(); ME = Players.LocalPlayer end
    local Character = ME.Character or ME.CharacterAdded:Wait()
    Character:WaitForChild("HumanoidRootPart")
    local t = tick()
    while (tick() - t) <= 0.3 do Character:PivotTo(data); task.wait() end
end
]]

local JAWADEOBF_rejoinServer = function(JAWADEOBF_reason)
    local JAWADEOBF_TP      = game:GetService("TeleportService")
    local JAWADEOBF_Players = game:GetService("Players")
    local JAWADEOBF_LP      = JAWADEOBF_Players.LocalPlayer
    local JAWADEOBF_placeId = game.PlaceId
    local JAWADEOBF_jobId   = game.JobId
    local JAWADEOBF_pivot   = nil
    local JAWADEOBF_queue   = (syn and syn.queue_on_teleport)
        or queue_on_teleport
        or (fluxus and fluxus.queue_on_teleport)

    if JAWADEOBF_queue and JAWADEOBF_LP and JAWADEOBF_LP.Character then
        pcall(function()
            JAWADEOBF_pivot = JAWADEOBF_LP.Character:GetPivot()
            local JAWADEOBF_payload = ""
            if getgenv().WEBHOOK_MSG_IDS then
                for k, v in pairs(getgenv().WEBHOOK_MSG_IDS) do
                    JAWADEOBF_payload = JAWADEOBF_payload .. string.format(
                        "getgenv().WEBHOOK_MSG_IDS = getgenv().WEBHOOK_MSG_IDS or {}; getgenv().WEBHOOK_MSG_IDS[%q] = %q\n",
                        k, v
                    )
                end
            end
            if isBaristaFarming or baristaRejoining then
                JAWADEOBF_payload = JAWADEOBF_payload .. "getgenv().AUTO_RESUME_BARISTA = true\n"
            end
            if isCourierFarming or courierRejoining then
                JAWADEOBF_payload = JAWADEOBF_payload .. "getgenv().AUTO_RESUME_COURIER = true\n"
            end
            JAWADEOBF_queue(JAWADEOBF_payload .. JAWADEOBF_rejoinPayload)
        end)
    end

    if #JAWADEOBF_Players:GetPlayers() <= 1 then
        pcall(function() JAWADEOBF_LP:Kick(JAWADEOBF_reason or "\n[DX-SR] Rejoining Server...") end)
        task.wait(0.3)
        JAWADEOBF_TP:Teleport(JAWADEOBF_placeId, JAWADEOBF_LP, JAWADEOBF_pivot)
    else
        JAWADEOBF_TP:TeleportToPlaceInstance(JAWADEOBF_placeId, JAWADEOBF_jobId, JAWADEOBF_LP, nil, JAWADEOBF_pivot)
    end
end

--=====================================================================
-- TAB: COURIER
--=====================================================================
local JAWADEOBF_CourierTab     = JAWADEOBF_FarmingSection:Tab({ Title = "Courir", Icon = "box" })
local JAWADEOBF_CourierSection = JAWADEOBF_CourierTab:Section({ Title = "Courier Farming", Opened = true })

local JAWADEOBF_courierEnabled      = false
local JAWADEOBF_courierSpeed        = 230
local JAWADEOBF_courierDropDelay    = 5
local JAWADEOBF_courierJobId        = nil
local JAWADEOBF_courierStartTime    = nil
local JAWADEOBF_courierDistance     = 0
local JAWADEOBF_courierResetFlag    = false
local JAWADEOBF_courierLastJobTime  = os.clock()
local JAWADEOBF_courierRestarting   = false
local JAWADEOBF_courierTotalEarn    = 0
local JAWADEOBF_courierJobCount     = 0
local JAWADEOBF_courierLastNotif    = ""
local JAWADEOBF_courierShiftLimit   = false
local JAWADEOBF_courierRejoinWarned = false
local JAWADEOBF_courierRejoinDone   = false
local JAWADEOBF_courierLimitSeconds = 3 * 3600

local JAWADEOBF_courierToggle = JAWADEOBF_CourierSection:Toggle({
    Title    = "Autofarm Courier",
    Desc     = "Auto delivery courier",
    Flag     = "CourierAutoFarm",
    Default  = false,
    Callback = function(JAWADEOBF_state)
        JAWADEOBF_courierEnabled = JAWADEOBF_state
        if JAWADEOBF_state then
            JAWADEOBF_courierResetFlag    = true
            JAWADEOBF_courierStartTime    = os.clock()
            JAWADEOBF_courierRejoinWarned = false
            JAWADEOBF_courierRejoinDone   = false
            game:GetService("ReplicatedStorage").JobEvents.TeamChangeRequest
                :FireServer("Courier", 11378976, 0, 0, "Detector")
        else
            JAWADEOBF_courierStartTime    = nil
            JAWADEOBF_courierRejoinWarned = false
            JAWADEOBF_courierRejoinDone   = false
        end
    end,
})

JAWADEOBF_CourierSection:Slider({
    Title = "Courier Speed", Desc = "Kecepatan courier", Step = 10,
    Flag  = "CourierSpeed", Value = { Min = 0, Max = 500, Default = 230 },
    Callback = function(v) JAWADEOBF_courierSpeed = v end,
})

JAWADEOBF_CourierSection:Slider({
    Title = "Dropoff Delay", Desc = "Wait time (s) di lokasi delivery", Step = 1,
    Flag  = "CourierDropoffDelay", Value = { Min = 0, Max = 10, Default = 5 },
    Callback = function(v) JAWADEOBF_courierDropDelay = v end,
})

local JAWADEOBF_courierWebhook   = ""
local JAWADEOBF_courierWebhookOn = false

JAWADEOBF_CourierSection:Input({
    Title = "Webhook URL", Desc = "Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...", Flag = "CourierWebhookUrl",
    Callback = function(v) JAWADEOBF_courierWebhook = v end,
})

JAWADEOBF_CourierSection:Toggle({
    Title = "Enable Webhook", Desc = "Kirim notifikasi ke Discord",
    Flag = "CourierWebhookEnabled", Default = false,
    Callback = function(v) JAWADEOBF_courierWebhookOn = v end,
})

local JAWADEOBF_CourierInfo = JAWADEOBF_CourierTab:Section({ Title = "Information", Opened = true })
local JAWADEOBF_infoTime    = JAWADEOBF_CourierInfo:Paragraph({ Title = "Time Elapsed",     Desc = "00h 00m 00s" })
local JAWADEOBF_infoRejoin  = JAWADEOBF_CourierInfo:Paragraph({ Title = "Rejoin in",        Desc = "03h 00m 00s" })
local JAWADEOBF_infoDest    = JAWADEOBF_CourierInfo:Paragraph({ Title = "Next Destination", Desc = "-" })
local JAWADEOBF_infoDist    = JAWADEOBF_CourierInfo:Paragraph({ Title = "Distance",         Desc = "0 studs" })
local JAWADEOBF_infoEarn    = JAWADEOBF_CourierInfo:Paragraph({ Title = "Total Earning",    Desc = "Rp. 0" })
local JAWADEOBF_infoJobs    = JAWADEOBF_CourierInfo:Paragraph({ Title = "Total Job Done",   Desc = "0" })

local JAWADEOBF_formatRupiah = function(n)
    return "Rp. " .. tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local JAWADEOBF_courierWebhookSend = function(JAWADEOBF_isStuck, JAWADEOBF_isRejoin)
    if not JAWADEOBF_courierWebhookOn or JAWADEOBF_courierWebhook == "" then return end
    local elapsed  = JAWADEOBF_courierStartTime and JAWADEOBF_formatTime(os.clock() - JAWADEOBF_courierStartTime) or "00h 00m 00s"
    local remain   = JAWADEOBF_courierStartTime and JAWADEOBF_formatTime(math.max(0, JAWADEOBF_courierLimitSeconds - (os.clock() - JAWADEOBF_courierStartTime))) or "03h 00m 00s"
    local destName = "-"
    pcall(function()
        local liv = workspace:FindFirstChild("Livrason") and workspace.Livrason:FindFirstChild("Location")
        if JAWADEOBF_courierJobId and liv and liv:FindFirstChild(JAWADEOBF_courierJobId) then
            destName = liv[JAWADEOBF_courierJobId].POINT.billboardgui:GetChildren()[2].Text
        elseif JAWADEOBF_courierJobId then
            destName = "Location " .. JAWADEOBF_courierJobId
        end
    end)
    local money = JAWADEOBF_formatRupiah(JAWADEOBF_courierTotalEarn)
    local msg   = { username = "DX-SR Courier" }
    if JAWADEOBF_isRejoin then
        msg.embeds = {{ title = "ðŸ” Courier Auto Rejoin (3h Limit)", color = 16711680,
            fields = {
                { name = "â³ Time Elapse",   value = "`" .. elapsed .. "`",                              inline = true },
                { name = "ðŸ’° Total Earning", value = "`" .. money .. "`",                                inline = true },
                { name = "ðŸ“¦ Job Done",      value = "`" .. tostring(JAWADEOBF_courierJobCount) .. "`",  inline = true },
            },
            footer = { text = "DX-SR Hub â€¢ Courier System" }, timestamp = DateTime.now():ToIsoDate(),
        }}
    elseif JAWADEOBF_isStuck then
        msg.embeds = {{ title = "ðŸš¨ Stuck (job restarted)", color = 16731469,
            fields = {
                { name = "â³ Time Elapse",   value = "`" .. elapsed .. "`",                              inline = true },
                { name = "ðŸ” Rejoin in",     value = "`" .. remain .. "`",                               inline = true },
                { name = "ðŸ“ Next Dest",     value = "`" .. destName .. "`",                             inline = true },
                { name = "ðŸ’° Total Earning", value = "`" .. money .. "`",                                inline = true },
                { name = "ðŸ“¦ Job Done",      value = "`" .. tostring(JAWADEOBF_courierJobCount) .. "`",  inline = true },
            },
            footer = { text = "DX-SR Hub â€¢ Courier System" }, timestamp = DateTime.now():ToIsoDate(),
        }}
    else
        msg.embeds = {{ title = "ðŸ“¦ Courier Delivery Completed", color = 54478,
            fields = {
                { name = "â³ Time Elapse",   value = "`" .. elapsed .. "`",                              inline = true },
                { name = "ðŸ” Rejoin in",     value = "`" .. remain .. "`",                               inline = true },
                { name = "ðŸ“ Next Dest",     value = "`" .. destName .. "`",                             inline = true },
                { name = "ðŸ’° Total Earning", value = "`" .. money .. "`",                                inline = true },
                { name = "ðŸ“¦ Job Done",      value = "`" .. tostring(JAWADEOBF_courierJobCount) .. "`",  inline = true },
            },
            footer = { text = "DX-SR Hub â€¢ Courier System" }, timestamp = DateTime.now():ToIsoDate(),
        }}
    end
    JAWADEOBF_sendWebhook(JAWADEOBF_courierWebhook, msg)
end

local JAWADEOBF_courierRejoinWarning = function()
    if not JAWADEOBF_courierWebhookOn or JAWADEOBF_courierWebhook == "" then return end
    local elapsed = JAWADEOBF_courierStartTime and JAWADEOBF_formatTime(os.clock() - JAWADEOBF_courierStartTime) or "02h 59m 50s"
    local money   = JAWADEOBF_formatRupiah(JAWADEOBF_courierTotalEarn)
    JAWADEOBF_sendWebhook(JAWADEOBF_courierWebhook, {
        content = "@everyone", username = "DX-SR Courier",
        embeds  = {{ title = "ðŸš¨ Courier Auto Rejoin Warning (10 Detik)", color = 16711680,
            fields = {
                { name = "â³ Time Elapse", value = "`" .. elapsed .. "`",                              inline = true },
                { name = "ðŸ” Rejoin in",  value = "`10 Detik`",                                       inline = true },
                { name = "ðŸ’° Earning",    value = "`" .. money .. "`",                                 inline = true },
                { name = "ðŸ“¦ Job Done",   value = "`" .. tostring(JAWADEOBF_courierJobCount) .. "`",  inline = true },
            },
            footer = { text = "DX-SR Hub â€¢ Courier Rejoin Alert" }, timestamp = DateTime.now():ToIsoDate(),
        }},
    }, true)
end

task.spawn(function()
    while task.wait(1) do
        if JAWADEOBF_courierEnabled and JAWADEOBF_courierStartTime then
            local elapsed = os.clock() - JAWADEOBF_courierStartTime
            local remain  = math.max(0, JAWADEOBF_courierLimitSeconds - elapsed)
            pcall(function() JAWADEOBF_infoTime:SetDesc(JAWADEOBF_formatTime(elapsed)) end)
            pcall(function() JAWADEOBF_infoRejoin:SetDesc(JAWADEOBF_formatTime(remain)) end)
            if remain <= 10 and not JAWADEOBF_courierRejoinDone then
                JAWADEOBF_courierRejoinDone = true
                pcall(JAWADEOBF_courierRejoinWarning)
            end
            if elapsed >= JAWADEOBF_courierLimitSeconds and not JAWADEOBF_courierRejoinWarned then
                JAWADEOBF_courierRejoinWarned = true
                pcall(function() JAWADEOBF_courierWebhookSend(false, true) end)
                task.wait(0.5)
                JAWADEOBF_rejoinServer("\n[DX-SR] Courier 3h Limit - Auto Rejoining...")
            end
        else
            pcall(function() JAWADEOBF_infoTime:SetDesc("00h 00m 00s") end)
            pcall(function() JAWADEOBF_infoRejoin:SetDesc("03h 00m 00s") end)
        end
    end
end)

local JAWADEOBF_courierHandleShiftLimit = function()
    if JAWADEOBF_courierShiftLimit then return end
    JAWADEOBF_courierShiftLimit = true
    JAWADEOBF_courierLastNotif  = os.date("%H:%M:%S")
    JAWADEOBF_courierWebhookSend(true)
    pcall(function()
        JAWADEOBF_WindUI:Notify({ Title = "Courier Shift Limit", Content = "Limit shift! Berpindah ke Civilian...", Duration = 3 })
    end)
    JAWADEOBF_courierJobId     = nil
    JAWADEOBF_courierResetFlag = false
    pcall(function() JAWADEOBF_infoDest:SetDesc("-") end)
    pcall(function()
        local tr = game:GetService("ReplicatedStorage"):WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
        tr:FireServer("Civilian", 0, 0, 0, "MainMenu")
    end)
    task.wait(3)
    pcall(function()
        JAWADEOBF_WindUI:Notify({ Title = "Courier Shift Limit", Content = "Masuk kembali ke Courier...", Duration = 3 })
        local tr = game:GetService("ReplicatedStorage"):WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
        tr:FireServer("Courier", 11378976, 1, 0, "Detector")
    end)
    local LP   = game:GetService("Players").LocalPlayer
    local char = LP.Character
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
        LP.CharacterAdded:Wait()
    end
    task.wait(2)
    JAWADEOBF_courierResetFlag   = true
    JAWADEOBF_courierRestarting  = false
    JAWADEOBF_courierJobId       = nil
    JAWADEOBF_courierLastJobTime = os.clock()
    JAWADEOBF_courierShiftLimit  = false
end

task.spawn(function()
    pcall(function()
        local notif = game:GetService("ReplicatedStorage")
            :WaitForChild("Notification", 9e9)
            :WaitForChild("NotifEvent", 9e9)
        notif.OnClientEvent:Connect(function(k, v)
            if not JAWADEOBF_courierEnabled then return end
            local isLimit = false
            if typeof(v) == "string" then
                if v:find("NC_SHIFT_LIMIT") or v:find("shift kurir tercapai") or v:lower():find("courier shift limit") then isLimit = true end
            elseif typeof(v) == "table" then
                if v.k == "NC_SHIFT_LIMIT" or (v.a and tostring(v.a):find("NC_SHIFT_LIMIT")) then isLimit = true end
            end
            if typeof(k) == "string" and (k:find("NC_SHIFT_LIMIT") or k:lower():find("courier shift")) then isLimit = true end
            if isLimit then task.spawn(JAWADEOBF_courierHandleShiftLimit) end
        end)
    end)
end)

task.spawn(function()
    local LP     = game:GetService("Players").LocalPlayer
    local PG     = LP:WaitForChild("PlayerGui", 9e9):WaitForChild("MainUI", 9e9)
    local Frame4 = PG:WaitForChild("Frame4", 9e9)
    local NOTIF  = Frame4:WaitForChild("NOTIF", 9e9)
    NOTIF:GetPropertyChangedSignal("Text"):Connect(function()
        if not JAWADEOBF_courierEnabled then return end
        local text = NOTIF.Text
        if text == "" or text == JAWADEOBF_courierLastNotif then return end
        JAWADEOBF_courierLastNotif = text
        if text:find("NC_SHIFT_LIMIT") or text:find("shift kurir tercapai") or text:lower():find("courier shift limit") then
            task.spawn(JAWADEOBF_courierHandleShiftLimit); return
        end
        local digits = text:gsub("[^%d]", "")
        if digits ~= "" then
            local amount = tonumber(digits) or 0
            JAWADEOBF_courierTotalEarn = JAWADEOBF_courierTotalEarn + amount
            JAWADEOBF_courierJobCount  = JAWADEOBF_courierJobCount  + 1
            pcall(function() JAWADEOBF_infoEarn:SetDesc(JAWADEOBF_formatRupiah(JAWADEOBF_courierTotalEarn)) end)
            pcall(function() JAWADEOBF_infoJobs:SetDesc(tostring(JAWADEOBF_courierJobCount)) end)
            JAWADEOBF_courierWebhookSend(false)
        end
    end)
end)

game:GetService("ReplicatedStorage")
    :WaitForChild("Delivery System")
    .Settings.ServiceEvent.OnClientEvent:Connect(function(evt, act, id)
        if evt == "ServiceEvent" and act == "Create" and id then
            JAWADEOBF_courierJobId       = tostring(id)
            JAWADEOBF_courierLastJobTime = os.clock()
            JAWADEOBF_courierResetFlag   = false
            pcall(function()
                local liv = workspace:FindFirstChild("Livrason") and workspace.Livrason:FindFirstChild("Location")
                if liv and liv:FindFirstChild(JAWADEOBF_courierJobId) then
                    JAWADEOBF_infoDest:SetDesc(liv[JAWADEOBF_courierJobId].POINT.billboardgui:GetChildren()[2].Text)
                else
                    JAWADEOBF_infoDest:SetDesc("Location " .. JAWADEOBF_courierJobId)
                end
            end)
        end
    end)

local JAWADEOBF_courierFlyTo = function(JAWADEOBF_targetCF)
    local LP   = game:GetService("Players").LocalPlayer
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.AutoRotate = false

    local seat = Instance.new("Seat")
    seat.Name         = "courier_seat"
    seat.Size         = Vector3.new(1, 1, 1)
    seat.Transparency = 1
    seat.CanCollide   = false
    seat.CFrame       = hrp.CFrame
    seat.Parent       = workspace

    local weld     = Instance.new("WeldConstraint")
    weld.Part0     = seat; weld.Part1 = hrp; weld.Parent = seat

    local bv       = Instance.new("BodyVelocity")
    bv.MaxForce    = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity    = Vector3.new(0, 0, 0)
    bv.Parent      = seat

    local gyro     = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    gyro.CFrame    = hrp.CFrame
    gyro.Parent    = seat

    local seatConn = game:GetService("RunService").Stepped:Connect(function()
        if hum.SeatPart ~= seat then hum.Sit = true; seat:Sit(hum) end
    end)

    local origCollide = {}
    local collideConn = game:GetService("RunService").Stepped:Connect(function()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false; origCollide[p] = true
                end
            end
        end
    end)

    local animator = hum:FindFirstChildOfClass("Animator")
    local animTrack
    if animator then
        pcall(function()
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://507766388"
            animTrack = animator:LoadAnimation(anim)
            animTrack.Priority = Enum.AnimationPriority.Action
            animTrack:Play()
        end)
    end

    local targetPos = JAWADEOBF_targetCF.Position
    local startTime = os.clock()

    while JAWADEOBF_courierEnabled and hrp do
        local cur   = hrp.Position
        local delta = targetPos - cur
        local dist  = delta.Magnitude
        JAWADEOBF_courierDistance = math.floor(dist)
        pcall(function() JAWADEOBF_infoDist:SetDesc(tostring(JAWADEOBF_courierDistance) .. " studs") end)
        if dist < 8 then break end
        if (os.clock() - startTime) > 180 then break end
        bv.Velocity = delta.Unit * JAWADEOBF_courierSpeed
        gyro.CFrame = CFrame.lookAt(cur, targetPos)
        task.wait()
    end

    seatConn:Disconnect(); collideConn:Disconnect()
    for part, _ in pairs(origCollide) do
        if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
            part.CanCollide = true
        end
    end
    if bv then bv.Velocity = Vector3.new(0, 0, 0) end
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    task.wait(0.1)
    hum.Sit = false
    if seat then seat:Destroy() end
    if animTrack then pcall(function() animTrack:Stop() end) end
    hum.AutoRotate = true
    hum:ChangeState(Enum.HumanoidStateType.Running)
    pcall(function() JAWADEOBF_infoDist:SetDesc("0 studs") end)
end

task.spawn(function()
    JAWADEOBF_courierRestarting = false
    while task.wait(1) do
        if not JAWADEOBF_courierEnabled then continue end
        if JAWADEOBF_courierResetFlag then
            task.wait(2)
            JAWADEOBF_courierResetFlag  = false
            JAWADEOBF_courierRestarting = false
            JAWADEOBF_courierJobId      = nil
        end
        local LP   = game:GetService("Players").LocalPlayer
        local char = LP.Character
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 or JAWADEOBF_courierShiftLimit then continue end
        if not JAWADEOBF_courierJobId then
            if not JAWADEOBF_courierRestarting then
                JAWADEOBF_courierFlyTo(CFrame.new(-5108, 5, -3759))
                if not JAWADEOBF_courierEnabled or JAWADEOBF_courierShiftLimit then continue end
                task.wait(0.5)
                pcall(function()
                    local prompt = workspace.Livrason.Take1.Take.ProximityPrompt
                    if prompt then prompt.HoldDuration = 0; fireproximityprompt(prompt) end
                end)
                JAWADEOBF_courierRestarting = true
            end
            local waited = 0
            while JAWADEOBF_courierEnabled and not JAWADEOBF_courierJobId and not JAWADEOBF_courierShiftLimit and waited < 6 do
                task.wait(0.5); waited = waited + 0.5
            end
            if JAWADEOBF_courierEnabled and not JAWADEOBF_courierJobId and not JAWADEOBF_courierShiftLimit then
                JAWADEOBF_courierRestarting = false
            end
            if JAWADEOBF_courierEnabled and not JAWADEOBF_courierJobId then
                local idle = os.clock() - JAWADEOBF_courierLastJobTime
                if idle > 15 and not JAWADEOBF_courierResetFlag then JAWADEOBF_courierResetFlag = true end
                if idle > 30 then
                    pcall(function()
                        game:GetService("ReplicatedStorage"):WaitForChild("Delivery System")
                            .Settings.ServiceEvent:FireServer("RequestJobUpdate")
                    end)
                    JAWADEOBF_courierLastJobTime = os.clock()
                end
            end
        else
            local pickupCF = nil
            pcall(function()
                local block = workspace.Livrason.Location[JAWADEOBF_courierJobId].Block
                local crate = block:FindFirstChild("Dust Food Crates 56")
                    or block:FindFirstChild("Meshes/Rac1ks_Cylinder.023")
                if crate then pickupCF = crate.CFrame end
            end)
            if pickupCF then
                JAWADEOBF_courierFlyTo(pickupCF)
                if not JAWADEOBF_courierEnabled then continue end
                task.wait(JAWADEOBF_courierDropDelay)
                pcall(function()
                    local hum2 = char:FindFirstChildOfClass("Humanoid")
                    if hum2 then
                        local box = LP.Backpack:FindFirstChild("Box")
                        if box and box:IsA("Tool") then hum2:EquipTool(box) end
                    end
                end)
                task.wait(0.5)
                pcall(function()
                    local prompt = workspace.Livrason.Location[JAWADEOBF_courierJobId].Block.ProximityPrompt
                    if prompt then prompt.HoldDuration = 0; fireproximityprompt(prompt) end
                end)
                task.wait(1)
                JAWADEOBF_courierJobId = nil
                pcall(function() JAWADEOBF_infoDest:SetDesc("-") end)
            else
                JAWADEOBF_courierJobId = nil
            end
        end
    end
end)

--=====================================================================
-- TAB: BARISTA
--=====================================================================
local JAWADEOBF_BaristaTab     = JAWADEOBF_FarmingSection:Tab({ Title = "Barista", Icon = "coffee" })
local JAWADEOBF_BaristaSection = JAWADEOBF_BaristaTab:Section({ Title = "Barista Farming", Opened = true })

local JAWADEOBF_baristaEnabled      = false
local JAWADEOBF_baristaWorking      = false
local JAWADEOBF_baristaStartTime    = nil
local JAWADEOBF_baristaJobCount     = 0
local JAWADEOBF_baristaLastAction   = os.clock()
local JAWADEOBF_baristaRejoinWarned = false
local JAWADEOBF_baristaRejoinDone   = false
local JAWADEOBF_baristaLimitSeconds = 3 * 3600
local JAWADEOBF_baristaWebhook      = ""
local JAWADEOBF_baristaWebhookOn    = false
local JAWADEOBF_baristaStuckCount   = 0

local JAWADEOBF_baristaToggle = JAWADEOBF_BaristaSection:Toggle({
    Title    = "Autofarm Barista",
    Desc     = "Auto barista job (Brew & Serve)",
    Flag     = "BaristaAutoFarm",
    Default  = false,
    Callback = function(JAWADEOBF_state)
        JAWADEOBF_baristaEnabled = JAWADEOBF_state
        JAWADEOBF_baristaWorking = false
        if JAWADEOBF_state then
            JAWADEOBF_baristaStartTime    = os.clock()
            JAWADEOBF_baristaLastAction   = os.clock()
            JAWADEOBF_baristaRejoinWarned = false
            JAWADEOBF_baristaRejoinDone   = false
        else
            JAWADEOBF_baristaStartTime    = nil
            JAWADEOBF_baristaRejoinWarned = false
            JAWADEOBF_baristaRejoinDone   = false
        end
    end,
})

JAWADEOBF_BaristaSection:Input({
    Title = "Webhook URL", Desc = "Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...", Flag = "BaristaWebhookUrl",
    Callback = function(v) JAWADEOBF_baristaWebhook = v end,
})

JAWADEOBF_BaristaSection:Toggle({
    Title = "Enable Webhook", Desc = "Kirim notifikasi ke Discord",
    Flag = "BaristaWebhookEnabled", Default = false,
    Callback = function(v) JAWADEOBF_baristaWebhookOn = v end,
})

local JAWADEOBF_BaristaInfo   = JAWADEOBF_BaristaTab:Section({ Title = "Information", Opened = true })
local JAWADEOBF_baristaTime   = JAWADEOBF_BaristaInfo:Paragraph({ Title = "Timestamp",      Desc = "00h 00m 00s" })
local JAWADEOBF_baristaRejoin = JAWADEOBF_BaristaInfo:Paragraph({ Title = "Auto Rejoin In", Desc = "03h 00m 00s" })
local JAWADEOBF_baristaJobs   = JAWADEOBF_BaristaInfo:Paragraph({ Title = "Job Done",       Desc = "0" })
local JAWADEOBF_baristaStuck  = JAWADEOBF_BaristaInfo:Paragraph({ Title = "Stuck Count",    Desc = "0" })

local JAWADEOBF_baristaWebhookSend = function(JAWADEOBF_isStuck, JAWADEOBF_isRejoin)
    if not JAWADEOBF_baristaWebhookOn or JAWADEOBF_baristaWebhook == "" then return end
    local elapsed = JAWADEOBF_baristaStartTime and JAWADEOBF_formatTime(os.clock() - JAWADEOBF_baristaStartTime) or "00h 00m 00s"
    local msg     = { username = "DX-SR Barista" }
    local fields  = {
        { name = "â³ Time Elapse",  value = "`" .. elapsed .. "`",                               inline = true },
        { name = "â˜• Job Done",     value = "`" .. tostring(JAWADEOBF_baristaJobCount) .. "`",   inline = true },
        { name = "âš ï¸ Stuck Count", value = "`" .. tostring(JAWADEOBF_baristaStuckCount) .. "`", inline = true },
    }
    if JAWADEOBF_isRejoin then
        msg.embeds = {{ title = "ðŸ” Barista Auto Rejoin (3h Limit)", color = 16711680, fields = fields,
            footer = { text = "DX-SR Hub â€¢ Barista System" }, timestamp = DateTime.now():ToIsoDate() }}
    elseif JAWADEOBF_isStuck then
        msg.embeds = {{ title = "ðŸ”„ Barista Shift Refreshed", color = 16753920, fields = fields,
            footer = { text = "DX-SR Hub â€¢ Barista System" }, timestamp = DateTime.now():ToIsoDate() }}
    else
        msg.embeds = {{ title = "â˜• Barista Order Served", color = 54478, fields = fields,
            footer = { text = "DX-SR Hub â€¢ Barista System" }, timestamp = DateTime.now():ToIsoDate() }}
    end
    JAWADEOBF_sendWebhook(JAWADEOBF_baristaWebhook, msg)
end

local JAWADEOBF_baristaRejoinWarning = function()
    if not JAWADEOBF_baristaWebhookOn or JAWADEOBF_baristaWebhook == "" then return end
    local elapsed = JAWADEOBF_baristaStartTime and JAWADEOBF_formatTime(os.clock() - JAWADEOBF_baristaStartTime) or "02h 59m 50s"
    JAWADEOBF_sendWebhook(JAWADEOBF_baristaWebhook, {
        content = "@everyone", username = "DX-SR Barista",
        embeds  = {{ title = "ðŸš¨ Barista Auto Rejoin Warning (10 Detik)", color = 16711680,
            fields = {
                { name = "â³ Time Elapse",  value = "`" .. elapsed .. "`",                               inline = true },
                { name = "ðŸ” Rejoin in",    value = "`10 Detik`",                                        inline = true },
                { name = "â˜• Job Done",     value = "`" .. tostring(JAWADEOBF_baristaJobCount) .. "`",   inline = true },
                { name = "âš ï¸ Stuck Count", value = "`" .. tostring(JAWADEOBF_baristaStuckCount) .. "`", inline = true },
            },
            footer = { text = "DX-SR Hub â€¢ Barista Rejoin Alert" }, timestamp = DateTime.now():ToIsoDate(),
        }},
    }, true)
end

task.spawn(function()
    while task.wait(1) do
        if JAWADEOBF_baristaEnabled and JAWADEOBF_baristaStartTime then
            local elapsed = os.clock() - JAWADEOBF_baristaStartTime
            local remain  = math.max(0, JAWADEOBF_baristaLimitSeconds - elapsed)
            pcall(function() JAWADEOBF_baristaTime:SetDesc(JAWADEOBF_formatTime(elapsed)) end)
            pcall(function() JAWADEOBF_baristaRejoin:SetDesc(JAWADEOBF_formatTime(remain)) end)
            if remain <= 10 and not JAWADEOBF_baristaRejoinDone then
                JAWADEOBF_baristaRejoinDone = true
                pcall(JAWADEOBF_baristaRejoinWarning)
            end
            if elapsed >= JAWADEOBF_baristaLimitSeconds and not JAWADEOBF_baristaRejoinWarned then
                JAWADEOBF_baristaRejoinWarned = true
                pcall(function() JAWADEOBF_baristaWebhookSend(false, true) end)
                task.wait(0.5)
                JAWADEOBF_rejoinServer("\n[DX-SR] Barista 3h Limit - Auto Rejoining...")
            end
        else
            pcall(function() JAWADEOBF_baristaTime:SetDesc("00h 00m 00s") end)
            pcall(function() JAWADEOBF_baristaRejoin:SetDesc("03h 00m 00s") end)
        end
    end
end)

local JAWADEOBF_baristaTweenMax   = 60
local JAWADEOBF_baristaTweenShort = 0.08
local JAWADEOBF_baristaTweenMed   = 0.1
local JAWADEOBF_baristaTweenLong  = 0.1

local JAWADEOBF_baristaTeleport = function(JAWADEOBF_targetCF)
    local LP   = game:GetService("Players").LocalPlayer
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local curPos   = hrp.Position
    local tgtPos   = JAWADEOBF_targetCF.Position
    local dist3D   = (tgtPos - curPos).Magnitude
    local distFlat = (Vector3.new(tgtPos.X, 0, tgtPos.Z) - Vector3.new(curPos.X, 0, curPos.Z)).Magnitude
    if dist3D < 3.5 or distFlat < 2.5 then return end
    if hum.Sit then hum.Sit = false; task.wait(0.02) end

    hum.AutoRotate = false
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    local y        = tgtPos.Y
    local startPos = Vector3.new(hrp.Position.X, y, hrp.Position.Z)
    local endPos   = Vector3.new(tgtPos.X, y, tgtPos.Z)

    local seat      = Instance.new("Seat")
    seat.Name        = "pria_solo_part"
    seat.Size        = Vector3.new(1, 1, 1)
    seat.Transparency = 1
    seat.CanCollide  = false
    seat.CFrame      = CFrame.new(startPos) * JAWADEOBF_targetCF.Rotation
    seat.Parent      = workspace

    local weld   = Instance.new("WeldConstraint")
    weld.Part0   = seat; weld.Part1 = hrp; weld.Parent = seat

    local bv     = Instance.new("BodyVelocity")
    bv.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity  = Vector3.zero
    bv.Parent    = seat

    local seatConn = game:GetService("RunService").Stepped:Connect(function()
        if hrp then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end
        if seat and seat.Parent then seat.AssemblyLinearVelocity = Vector3.zero; seat.AssemblyAngularVelocity = Vector3.zero end
        if hum.SeatPart ~= seat then hum.Sit = true; seat:Sit(hum) end
    end)

    local origCollide = {}
    local collideConn = game:GetService("RunService").Stepped:Connect(function()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false; origCollide[p] = true end
            end
        end
    end)

    local duration = math.clamp(distFlat / JAWADEOBF_baristaTweenMax, 0.02, 1)
    local t0       = os.clock()

    while JAWADEOBF_baristaEnabled and hrp and char.Parent and (os.clock() - t0) < duration do
        local alpha = math.min((os.clock() - t0) / duration, 1)
        local pos   = startPos:Lerp(endPos, alpha)
        local cf    = CFrame.new(pos) * JAWADEOBF_targetCF.Rotation
        seat.CFrame = cf; hrp.CFrame = cf
        task.wait()
    end

    seatConn:Disconnect(); collideConn:Disconnect()
    for part, _ in pairs(origCollide) do
        if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then part.CanCollide = true end
    end
    if bv then bv:Destroy() end
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hum.Sit = false
    if seat then seat:Destroy() end
    hum.AutoRotate = true
    hum:ChangeState(Enum.HumanoidStateType.Running)
    hrp.CFrame = CFrame.new(endPos) * JAWADEOBF_targetCF.Rotation
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local LP  = game:GetService("Players").LocalPlayer
            local PG  = LP:FindFirstChild("PlayerGui")
            local gui = PG and PG:FindFirstChild("BaristaGUI")
            if gui and gui.Enabled then
                local mini = gui:FindFirstChild("MinigameFrame")
                if mini and mini.Visible then
                    local stroke = mini:FindFirstChildWhichIsA("UIStroke")
                    if stroke then stroke.Color = Color3.fromRGB(0, 212, 206) end
                    local bar = mini:FindFirstChild("ProgressBar")
                    if bar and bar:IsA("GuiObject") and bar.Visible then bar.Visible = false end
                    local tap = mini:FindFirstChild("TapZone")
                    if tap then
                        local kids = tap:GetChildren()
                        if kids[4] and kids[4]:IsA("GuiObject") and kids[4].Visible then kids[4].Visible = false end
                        if kids[5] and kids[5]:IsA("GuiObject") and kids[5].Visible then kids[5].Visible = false end
                        for _, k in ipairs(kids) do if k:IsA("TextLabel") and k.Visible then k.Visible = false end end
                    end
                    local bg = mini:FindFirstChild("BackgroundBar")
                    if bg then
                        if bg.BackgroundTransparency ~= 1 then bg.BackgroundTransparency = 1 end
                        local cursor = bg:FindFirstChild("PlayerCursor")
                        if cursor and cursor:IsA("GuiObject") and cursor.Visible then cursor.Visible = false end
                        local target = bg:FindFirstChild("TargetZone")
                        if target then
                            if target.BackgroundTransparency ~= 1 then target.BackgroundTransparency = 1 end
                            if JAWADEOBF_baristaEnabled and target.Size.Y.Scale < 1.5 then
                                target.Size = UDim2.new(1, 0, 1, 0)
                            end
                            for _, k in ipairs(target:GetChildren()) do if k:IsA("UIGradient") then k:Destroy() end end
                            local label = target:FindFirstChild("DXSRLabel") or target:FindFirstChildWhichIsA("TextLabel")
                            if not label then label = Instance.new("TextLabel"); label.Name = "DXSRLabel"; label.Parent = target end
                            label.Name = "DXSRLabel"; label.Text = "DX-SR"; label.Font = Enum.Font.GothamBold
                            label.Position = UDim2.new(0.5, 0, 0.1, 170); label.AnchorPoint = Vector2.new(0.5, 0.5)
                            label.Size = UDim2.new(0, 200, 0, 50); label.TextSize = 40
                            label.TextColor3 = Color3.fromRGB(0, 235, 255)
                            label.TextXAlignment = Enum.TextXAlignment.Center
                            label.TextYAlignment = Enum.TextYAlignment.Bottom
                            label.BackgroundTransparency = 1; label.Visible = true
                        end
                    end
                end
                local mission = PG and PG:FindFirstChild("BaristaMissionUI")
                if mission then
                    local container = mission:FindFirstChild("Container")
                    if container then
                        local btnFrame = container:FindFirstChild("ButtonFrame")
                        local btn = btnFrame and btnFrame:FindFirstChild("TextButton")
                        if btn then
                            for _, k in ipairs(btn:GetChildren()) do if k:IsA("UIGradient") then k:Destroy() end end
                            btn.BackgroundColor3 = Color3.fromRGB(0, 212, 206)
                            local title = btn:FindFirstChild("TitleLabel")
                            if title and title.Text ~= "DX-SR COMPANY" then title.Text = "DX-SR COMPANY" end
                        end
                        local main = container:FindFirstChild("MainFrame")
                        if main then
                            local grad = main:FindFirstChild("UIGradient") or main:FindFirstChildWhichIsA("UIGradient")
                            if not grad then grad = Instance.new("UIGradient"); grad.Name = "UIGradient"; grad.Parent = main end
                            if main.BackgroundColor3 ~= Color3.fromRGB(255, 255, 255) then main.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end
                            grad.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 22, 40)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 42, 70)),
                            })
                            grad.Rotation = 45
                        end
                    end
                end
            end
        end)
    end
end)

local JAWADEOBF_baristaPromptHandler = function(JAWADEOBF_parent)
    if not JAWADEOBF_parent then return false end
    local prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt then return false end
    if not prompt.Enabled then
        local t0 = os.clock()
        while JAWADEOBF_baristaEnabled and not prompt.Enabled and (os.clock() - t0) < 2.5 do
            task.wait(0.2)
            if not prompt.Parent then prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt") end
        end
    end
    if not prompt or not prompt.Enabled then return false end
    prompt.HoldDuration = 0
    if prompt.ActionText == "End Shift" then
        local t0 = os.clock(); local lastClick = 0
        while JAWADEOBF_baristaEnabled and (os.clock() - t0) < 6 do
            if not prompt.Parent then prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt") end
            if not prompt then break end
            if prompt.ActionText == "Start Shift" then break end
            if (os.clock() - lastClick) > 1.2 then lastClick = os.clock(); pcall(function() prompt.HoldDuration = 0; fireproximityprompt(prompt) end) end
            task.wait(0.2)
        end
        task.wait(0.3)
    end
    if not prompt or not prompt.Parent then prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt") end
    if prompt and prompt.ActionText == "Start Shift" then
        local t0 = os.clock(); local lastClick = 0
        while JAWADEOBF_baristaEnabled and (os.clock() - t0) < 6 do
            if not prompt.Parent then prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt") end
            if not prompt then break end
            if prompt.ActionText == "End Shift" then break end
            if (os.clock() - lastClick) > 1.2 then lastClick = os.clock(); pcall(function() prompt.HoldDuration = 0; fireproximityprompt(prompt) end) end
            task.wait(0.2)
        end
        task.wait(0.3)
    end
    if not prompt or not prompt.Parent then prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt") end
    return prompt and prompt.ActionText == "End Shift"
end

task.spawn(function()
    while task.wait(JAWADEOBF_baristaTweenLong) do
        if not JAWADEOBF_baristaEnabled then continue end
        local LP   = game:GetService("Players").LocalPlayer
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hrp or not hum or hum.Health <= 0 then task.wait(0.5); continue end

        if not LP.Team or LP.Team.Name ~= "Barista" then
            pcall(function() JAWADEOBF_WindUI:Notify({ Title = "Barista Job", Content = "Masuk ke job Barista...", Duration = 3 }) end)
            local oldChar = LP.Character
            local tr = game:GetService("ReplicatedStorage"):WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
            tr:FireServer("Barista", 11378976, 1, 0, "Detector")
            local t0 = os.clock()
            while (not LP.Character or LP.Character == oldChar or not LP.Character:FindFirstChild("HumanoidRootPart"))
                and (os.clock() - t0) < 5 do task.wait(0.2) end
            task.wait(1.5)
            local newChar = LP.Character
            local newHrp  = newChar and newChar:FindFirstChild("HumanoidRootPart")
            if newHrp then hrp = newHrp; JAWADEOBF_seatTeleport(CFrame.new(-4989.8, 5.5, -715)); task.wait(0.5) end
            continue
        end

        local job          = workspace:FindFirstChild("BaristaJob")
        local interactions = job and job:FindFirstChild("Interactions")
        if not interactions then continue end

        local startPart    = interactions:FindFirstChild("StartPart")    and interactions.StartPart:FindFirstChild("StartPart")
        local machinePart  = interactions:FindFirstChild("MachinePart")  and interactions.MachinePart:FindFirstChild("MachinePart")
        local registerPart = interactions:FindFirstChild("RegisterPart") and interactions.RegisterPart:FindFirstChild("RegisterPart")
        local supplyPart   = interactions:FindFirstChild("SupplyPart")   and interactions.SupplyPart:FindFirstChild("SupplyPart")

        local startPrompt    = startPart    and startPart:FindFirstChildWhichIsA("ProximityPrompt")
        local machinePrompt  = machinePart  and machinePart:FindFirstChildWhichIsA("ProximityPrompt")
        local registerPrompt = registerPart and registerPart:FindFirstChildWhichIsA("ProximityPrompt")
        local supplyPrompt   = supplyPart   and supplyPart:FindFirstChildWhichIsA("ProximityPrompt")

        local dropPos     = Vector3.new(-5000, 5.5, -760)
        local distToDrop  = (Vector3.new(dropPos.X, 0, dropPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
        local startPos    = Vector3.new(-4989.8, 5.5, -715)
        local distToStart = (Vector3.new(startPos.X, 0, startPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
        local canStart    = startPrompt and startPrompt.Enabled and startPrompt.ActionText == "Start Shift"

        if not JAWADEOBF_baristaWorking or distToDrop > 80 or canStart then
            if distToDrop > 80 then JAWADEOBF_seatTeleport(CFrame.new(startPos)); task.wait(0.5)
            elseif distToStart > 6 then JAWADEOBF_baristaTeleport(CFrame.new(startPos)); task.wait(0.3) end
            if startPart then startPrompt = startPart:FindFirstChildWhichIsA("ProximityPrompt") end
            local ok = JAWADEOBF_baristaPromptHandler(startPart)
            if not ok then task.wait(0.5); continue end
            JAWADEOBF_baristaWorking  = true
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_baristaTeleport(CFrame.new(-5000.2, 5.6, -792))
            task.wait(JAWADEOBF_baristaTweenShort); continue
        end

        if supplyPrompt and supplyPrompt.Enabled then
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_seatTeleport(CFrame.new(-5116.8, 5.8, -670.9)); task.wait(0.4)
            if supplyPrompt and supplyPrompt.Enabled then pcall(function() supplyPrompt.HoldDuration = 0; fireproximityprompt(supplyPrompt) end) end
            task.wait(0.6); JAWADEOBF_seatTeleport(CFrame.new(-5000.2, 5.6, -792)); task.wait(0.4); continue
        end

        if registerPrompt and registerPrompt.Enabled then
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_baristaTeleport(CFrame.new(-4997.1, 5.6, -755)); task.wait(JAWADEOBF_baristaTweenShort)
            if registerPrompt and registerPrompt.Enabled then pcall(function() registerPrompt.HoldDuration = 0; fireproximityprompt(registerPrompt) end) end
            task.wait(JAWADEOBF_baristaTweenMed)
            JAWADEOBF_baristaJobCount = JAWADEOBF_baristaJobCount + 1
            pcall(function() JAWADEOBF_baristaJobs:SetDesc(tostring(JAWADEOBF_baristaJobCount)) end)
            JAWADEOBF_baristaWebhookSend(false)
            JAWADEOBF_baristaTeleport(CFrame.new(-5000.2, 5.6, -792)); task.wait(JAWADEOBF_baristaTweenShort); continue
        end

        if machinePrompt and machinePrompt.Enabled then
            JAWADEOBF_baristaLastAction = os.clock()
            local brewPos = Vector3.new(-5000.2, 5.6, -792)
            local dist    = (brewPos - hrp.Position).Magnitude
            if dist > 3 then JAWADEOBF_baristaTeleport(CFrame.new(brewPos)); task.wait(JAWADEOBF_baristaTweenShort) end
            if machinePrompt and machinePrompt.Enabled then pcall(function() machinePrompt.HoldDuration = 0; fireproximityprompt(machinePrompt) end) end
            local t0 = os.clock()
            while JAWADEOBF_baristaEnabled and (os.clock() - t0) < 6 do
                JAWADEOBF_baristaLastAction = os.clock()
                if registerPrompt and registerPrompt.Enabled then break end
                local bariGui  = LP.PlayerGui:FindFirstChild("BaristaGUI")
                local bariMini = bariGui and bariGui:FindFirstChild("MinigameFrame")
                if not (bariMini and bariMini.Visible) and (os.clock() - t0) > 1 then break end
                task.wait(0.08)
            end
            continue
        end

        local brewPosCF  = CFrame.new(-5000.2, 5.6, -792)
        local distIdle   = (Vector3.new(brewPosCF.Position.X, 0, brewPosCF.Position.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
        if distIdle > 3.5 then JAWADEOBF_baristaTeleport(brewPosCF) end

        local idleTime = os.clock() - JAWADEOBF_baristaLastAction
        if idleTime > 18 then
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_baristaStuckCount = JAWADEOBF_baristaStuckCount + 1
            pcall(function() JAWADEOBF_baristaStuck:SetDesc(tostring(JAWADEOBF_baristaStuckCount)) end)
            JAWADEOBF_baristaWebhookSend(true)
            pcall(function() JAWADEOBF_WindUI:Notify({ Title = "Barista Limit Recovery", Content = "Me-refresh shift barista...", Duration = 3 }) end)
            JAWADEOBF_baristaTeleport(CFrame.new(-4989.8, 5.5, -715)); task.wait(0.3)
            JAWADEOBF_baristaWorking = false
            if startPart then startPrompt = startPart:FindFirstChildWhichIsA("ProximityPrompt") end
            local ok = JAWADEOBF_baristaPromptHandler(startPart)
            if not ok then task.wait(0.5); continue end
            JAWADEOBF_baristaWorking  = true
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_baristaTeleport(CFrame.new(-5000.2, 5.6, -792)); task.wait(JAWADEOBF_baristaTweenShort); continue
        end
    end
end)

if getgenv().AUTO_RESUME_BARISTA then
    task.spawn(function()
        JAWADEOBF_bypassMainMenu()
        local LP = game:GetService("Players").LocalPlayer
        while not LP do game:GetService("Players"):GetPropertyChangedSignal("LocalPlayer"):Wait(); LP = game:GetService("Players").LocalPlayer end
        local char = LP.Character or LP.CharacterAdded:Wait()
        char:WaitForChild("HumanoidRootPart", 15); task.wait(3)
        local tr = game:GetService("ReplicatedStorage"):WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
        tr:FireServer("Barista", 11378976, 1, 0, "Detector"); task.wait(1)
        local c2 = LP.Character or LP.CharacterAdded:Wait()
        c2:WaitForChild("HumanoidRootPart", 10); task.wait(0.2)
        JAWADEOBF_seatTeleport(CFrame.new(-4989.8, 5.5, -715)); task.wait(0.5)
        local job   = workspace:FindFirstChild("BaristaJob")
        local inter = job and job:FindFirstChild("Interactions")
        local sp    = inter and inter:FindFirstChild("StartPart") and inter.StartPart:FindFirstChild("StartPart")
        if sp then JAWADEOBF_baristaPromptHandler(sp) end
        if JAWADEOBF_baristaToggle then
            pcall(function() JAWADEOBF_baristaToggle:SetValue(true) end)
            pcall(function() JAWADEOBF_baristaToggle:Set(true) end)
        else
            JAWADEOBF_baristaEnabled    = true
            JAWADEOBF_baristaStartTime  = os.clock()
            JAWADEOBF_baristaLastAction = os.clock()
        end
        getgenv().AUTO_RESUME_BARISTA = false
    end)
end

if getgenv().AUTO_RESUME_COURIER then
    task.spawn(function()
        JAWADEOBF_bypassMainMenu()
        local LP = game:GetService("Players").LocalPlayer
        while not LP do game:GetService("Players"):GetPropertyChangedSignal("LocalPlayer"):Wait(); LP = game:GetService("Players").LocalPlayer end
        local char = LP.Character or LP.CharacterAdded:Wait()
        char:WaitForChild("HumanoidRootPart", 15); task.wait(3)
        local tr = game:GetService("ReplicatedStorage"):WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
        tr:FireServer("Courier", 11378976, 0, 0, "Detector"); task.wait(1)
        local c2 = LP.Character or LP.CharacterAdded:Wait()
        c2:WaitForChild("HumanoidRootPart", 10); task.wait(0.2)
        JAWADEOBF_seatTeleport(CFrame.new(-5108, 5, -3759)); task.wait(0.5)
        if JAWADEOBF_courierToggle then
            pcall(function() JAWADEOBF_courierToggle:SetValue(true) end)
            pcall(function() JAWADEOBF_courierToggle:Set(true) end)
        else
            JAWADEOBF_courierEnabled   = true
            JAWADEOBF_courierResetFlag = true
            JAWADEOBF_courierStartTime = os.clock()
        end
        getgenv().AUTO_RESUME_COURIER = false
    end)
end

--=====================================================================
-- TAB: TELEPORT
--=====================================================================
local JAWADEOBF_TeleportTab = JAWADEOBF_Window:Tab({ Title = "Teleport", Icon = "map-pin" })

local JAWADEOBF_genericTeleport = function(JAWADEOBF_cf)
    local LP   = game:GetService("Players").LocalPlayer
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local anim = char and char:FindFirstChild("Animate")
    if not hrp or not hum then return end
    if anim then anim.Disabled = true end

    local seat      = Instance.new("Seat")
    seat.Size        = Vector3.new(2, 0.2, 2)
    seat.Transparency = 1; seat.CanCollide = false; seat.Anchored = true
    seat.CFrame      = hrp.CFrame; seat.Parent = workspace

    hum.Sit = true; seat:Sit(hum)
    local bv    = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.new(0,0,0); bv.Parent = hrp

    task.wait(0.5); seat.Anchored = false
    local target = JAWADEOBF_cf * CFrame.new(0, 0.01, 0)
    local mid    = hrp.CFrame:Lerp(target, 0.5)
    seat.CFrame  = mid; hrp.CFrame = mid; task.wait(0.1)
    seat.CFrame  = target; hrp.CFrame = target; seat.Anchored = true
    task.wait(1.6)
    if bv then bv:Destroy() end
    hum.Sit = false
    if anim then anim.Disabled = false end
    task.wait(0.3); if seat then seat:Destroy() end
    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
    workspace.CurrentCamera.CameraSubject = hum
end

local JAWADEOBF_DealershipSection = JAWADEOBF_TeleportTab:Section({ Title = "Dealership" })
local JAWADEOBF_dealerPositions   = {
    ["Drag dealer"]    = Vector3.new(-5018, 3, -5358),
    ["Yahamax dealer"] = Vector3.new(717, 3, -738),
    ["Premium dealer"] = Vector3.new(-4817, 4, -764),
    ["Kawzaki dealer"] = Vector3.new(-9500, 16, 956),
    ["Piazzo dealer"]  = Vector3.new(-5752, 6, -3902),
    ["Hando dealer"]   = Vector3.new(-5944, 5, -3903),
    ["Truck dealer"]   = Vector3.new(-10252, 5, 1309),
    ["Bus dealer"]     = Vector3.new(-16443, 105, 4632),
    ["Car dealer"]     = Vector3.new(-6606, 4, -4206),
}
local JAWADEOBF_dealerList = {}
for k, _ in pairs(JAWADEOBF_dealerPositions) do table.insert(JAWADEOBF_dealerList, k) end
local JAWADEOBF_selectedDealer = JAWADEOBF_dealerList[1]

JAWADEOBF_DealershipSection:Dropdown({
    Title = "Select dealership", Desc = "Choose a dealership", Multi = false,
    Flag  = "TeleportDealership", Value = JAWADEOBF_selectedDealer, Values = JAWADEOBF_dealerList,
    Callback = function(v) JAWADEOBF_selectedDealer = v end,
})
JAWADEOBF_DealershipSection:Button({
    Title = "Teleport now", Desc = "Bypass teleport ke dealership",
    Callback = function()
        if JAWADEOBF_dealerPositions[JAWADEOBF_selectedDealer] then
            JAWADEOBF_genericTeleport(CFrame.new(JAWADEOBF_dealerPositions[JAWADEOBF_selectedDealer]))
        end
    end,
})

local JAWADEOBF_OtherTpSection = JAWADEOBF_TeleportTab:Section({ Title = "Other teleport" })
local JAWADEOBF_otherPositions = {
    ["Drag race"]      = Vector3.new(-8903, 2, 742),
    ["Modification"]   = Vector3.new(-8652, 6, 148),
    ["helmet shop"]    = Vector3.new(-718, 5, -487),
    ["Town square"]    = Vector3.new(-267, 6, -4244),
    ["Feva hotel"]     = Vector3.new(-2721, 7, -4174),
    ["Clothing shop"]  = Vector3.new(-4778, 5, -3895),
    ["Ngopi cafe"]     = Vector3.new(-8294, 2, -3687),
    ["Starbook coffe"] = Vector3.new(-10262, 4, -4153),
}
local JAWADEOBF_otherList = {}
for k, _ in pairs(JAWADEOBF_otherPositions) do table.insert(JAWADEOBF_otherList, k) end
local JAWADEOBF_selectedOther = JAWADEOBF_otherList[1]

JAWADEOBF_OtherTpSection:Dropdown({
    Title = "Select place", Desc = "Choose a place", Multi = false,
    Flag  = "TeleportOtherLocation", Value = JAWADEOBF_selectedOther, Values = JAWADEOBF_otherList,
    Callback = function(v) JAWADEOBF_selectedOther = v end,
})
JAWADEOBF_OtherTpSection:Button({
    Title = "Teleport now", Desc = "Teleport ke lokasi",
    Callback = function()
        if JAWADEOBF_otherPositions[JAWADEOBF_selectedOther] then
            JAWADEOBF_genericTeleport(CFrame.new(JAWADEOBF_otherPositions[JAWADEOBF_selectedOther]))
        end
    end,
})
JAWADEOBF_OtherTpSection:Button({
    Title = "Teleport to anomaly", Desc = "Teleport + interact dengan anomaly",
    Callback = function()
        task.spawn(function()
            JAWADEOBF_genericTeleport(CFrame.new(7828, 3, -470)); task.wait(2)
            pcall(function()
                local prompt = workspace["CHBZ3125E96vFxITe"]["CHBZ3125E96vFxITe_"]["Prompt"]["ProximityPrompt"]
                if prompt then prompt.HoldDuration = 0; fireproximityprompt(prompt) end
            end)
        end)
    end,
})

--=====================================================================
-- TAB: MISC
--=====================================================================
local JAWADEOBF_MiscTab       = JAWADEOBF_Window:Tab({ Title = "Misc", Icon = "box" })
local JAWADEOBF_AvatarSection = JAWADEOBF_MiscTab:Section({ Title = "Avatar & Name Spoofer" })

local JAWADEOBF_avatarBackup    = nil
local JAWADEOBF_spoofName       = ""
local JAWADEOBF_spoofNameOn     = false
local JAWADEOBF_spoofRank       = ""
local JAWADEOBF_spoofRankOn     = false
local JAWADEOBF_rankGradient    = nil
local JAWADEOBF_prefixText      = ""
local JAWADEOBF_prefixColor     = Color3.fromRGB(24, 24, 24)
local JAWADEOBF_nameShadowColor = Color3.fromRGB(0, 0, 0)

local JAWADEOBF_parseColorSequence = function(str)
    local nums = {}
    for tok in string.gmatch(str, "%S+") do table.insert(nums, tonumber(tok)) end
    local keypoints = {}
    for i = 1, #nums, 5 do
        local t, r, g, b = nums[i], nums[i+1], nums[i+2], nums[i+3]
        if t and r and g and b then
            table.insert(keypoints, ColorSequenceKeypoint.new(t, Color3.new(r, g, b)))
        end
    end
    if #keypoints > 0 then
        if keypoints[1].Time > 0 then table.insert(keypoints, 1, ColorSequenceKeypoint.new(0, keypoints[1].Value)) end
        if keypoints[#keypoints].Time < 1 then table.insert(keypoints, ColorSequenceKeypoint.new(1, keypoints[#keypoints].Value)) end
        return ColorSequence.new(keypoints)
    end
    return nil
end

local JAWADEOBF_r15Parts = {
    UpperTorso = Enum.BodyPartR15.UpperTorso, LowerTorso = Enum.BodyPartR15.LowerTorso,
    LeftUpperArm = Enum.BodyPartR15.LeftUpperArm, LeftLowerArm = Enum.BodyPartR15.LeftLowerArm,
    LeftHand = Enum.BodyPartR15.LeftHand, RightUpperArm = Enum.BodyPartR15.RightUpperArm,
    RightLowerArm = Enum.BodyPartR15.RightLowerArm, RightHand = Enum.BodyPartR15.RightHand,
    LeftUpperLeg = Enum.BodyPartR15.LeftUpperLeg, LeftLowerLeg = Enum.BodyPartR15.LeftLowerLeg,
    LeftFoot = Enum.BodyPartR15.LeftFoot, RightUpperLeg = Enum.BodyPartR15.RightUpperLeg,
    RightLowerLeg = Enum.BodyPartR15.RightLowerLeg, RightFoot = Enum.BodyPartR15.RightFoot,
}

local JAWADEOBF_applyAvatarSpoof = function(JAWADEOBF_userId)
    local LP   = game:GetService("Players").LocalPlayer
    local char = LP.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if not JAWADEOBF_avatarBackup then
        JAWADEOBF_avatarBackup = { body_parts = {}, accessories = {}, clothing = {}, face = nil, head_mesh = nil, body_colors = nil, scales = {} }
        for name, _ in pairs(JAWADEOBF_r15Parts) do
            local part = char:FindFirstChild(name)
            if part and part:IsA("BasePart") then JAWADEOBF_avatarBackup.body_parts[name] = part:Clone() end
        end
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then JAWADEOBF_avatarBackup.body_parts["Head"] = head:Clone() end
        for _, ch in ipairs(char:GetChildren()) do
            if ch:IsA("Accessory") then table.insert(JAWADEOBF_avatarBackup.accessories, ch:Clone())
            elseif ch:IsA("Shirt") or ch:IsA("Pants") or ch:IsA("ShirtGraphic") then table.insert(JAWADEOBF_avatarBackup.clothing, ch:Clone())
            elseif ch:IsA("BodyColors") then JAWADEOBF_avatarBackup.body_colors = ch:Clone() end
        end
        if head then
            for _, k in ipairs(head:GetChildren()) do
                if k:IsA("Decal") and (k.Name == "face" or k.Name == "Face") then JAWADEOBF_avatarBackup.face = k:Clone(); break end
            end
            local mesh = head:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                JAWADEOBF_avatarBackup.head_mesh = { MeshId = mesh.MeshId, TextureId = mesh.TextureId, Scale = mesh.Scale, Offset = mesh.Offset }
            end
            JAWADEOBF_avatarBackup.head_size  = head.Size
            JAWADEOBF_avatarBackup.head_color = head.Color
        end
        for name, _ in pairs({ HeadScale=true, BodyDepthScale=true, BodyWidthScale=true, BodyHeightScale=true, BodyTypeScale=true, BodyProportionScale=true }) do
            local scale = hum:FindFirstChild(name)
            if scale and scale:IsA("NumberValue") then JAWADEOBF_avatarBackup.scales[name] = scale.Value end
        end
    end

    local ok, model = pcall(function() return game:GetService("Players"):CreateHumanoidModelFromUserIdAsync(JAWADEOBF_userId) end)
    if not ok or not model then JAWADEOBF_WindUI:Notify({ Title = "Avatar Changer", Content = "Failed to load avatar", Duration = 3 }); return end
    local targetHum = model:FindFirstChildOfClass("Humanoid")
    if not targetHum then model:Destroy(); return end

    for name, enum in pairs(JAWADEOBF_r15Parts) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then pcall(function() hum:ReplaceBodyPartR15(enum, part:Clone()) end) end
    end
    for _, ch in ipairs(char:GetChildren()) do
        if ch:IsA("Accessory") or ch:IsA("Shirt") or ch:IsA("Pants") or ch:IsA("ShirtGraphic") or ch:IsA("CharacterMesh") then ch:Destroy() end
    end
    local head       = char:FindFirstChild("Head")
    local targetHead = model:FindFirstChild("Head")
    if head then
        for _, k in ipairs(head:GetChildren()) do if k:IsA("Decal") and (k.Name == "face" or k.Name == "Face") then k:Destroy() end end
    end
    if head and targetHead then
        for _, k in ipairs(targetHead:GetChildren()) do
            if k:IsA("Decal") and (k.Name == "face" or k.Name == "Face") then k:Clone().Parent = head end
        end
        local tMesh = targetHead:FindFirstChildOfClass("SpecialMesh")
        local cMesh = head:FindFirstChildOfClass("SpecialMesh")
        if tMesh and cMesh then cMesh.MeshId = tMesh.MeshId; cMesh.TextureId = tMesh.TextureId; cMesh.Scale = tMesh.Scale; cMesh.Offset = tMesh.Offset
        elseif tMesh and not cMesh then tMesh:Clone().Parent = head end
        head.Size = targetHead.Size; head.Color = targetHead.Color
    end
    for _, k in ipairs(model:GetChildren()) do
        if k:IsA("Shirt") or k:IsA("Pants") or k:IsA("ShirtGraphic") then k:Clone().Parent = char
        elseif k:IsA("BodyColors") then
            local bc = char:FindFirstChildOfClass("BodyColors")
            if bc then bc.HeadColor3 = k.HeadColor3; bc.TorsoColor3 = k.TorsoColor3; bc.LeftArmColor3 = k.LeftArmColor3; bc.RightArmColor3 = k.RightArmColor3; bc.LeftLegColor3 = k.LeftLegColor3; bc.RightLegColor3 = k.RightLegColor3 end
        end
    end
    for _, acc in ipairs(model:GetChildren()) do
        if acc:IsA("Accessory") then
            local clone  = acc:Clone()
            local handle = clone:FindFirstChild("Handle")
            if not handle then continue end
            local attach = handle:FindFirstChildOfClass("Attachment")
            for _, k in ipairs(handle:GetChildren()) do if k:IsA("Weld") or k:IsA("Motor6D") or k:IsA("WeldConstraint") then k:Destroy() end end
            local targetPart, targetAttach = nil, nil
            if attach then
                for _, p in ipairs(char:GetChildren()) do
                    if p:IsA("BasePart") then
                        for _, a in ipairs(p:GetChildren()) do
                            if a:IsA("Attachment") and a.Name == attach.Name then targetPart = p; targetAttach = a; break end
                        end
                    end
                    if targetPart then break end
                end
            end
            if not targetPart then
                targetPart = char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
                if not targetPart then continue end
            end
            clone.Parent = char
            local weld = Instance.new("Weld"); weld.Part0 = targetPart; weld.Part1 = handle
            if targetAttach and attach then weld.C0 = targetAttach.CFrame; weld.C1 = attach.CFrame
            else weld.C0 = CFrame.new(0, targetPart.Size.Y / 2, 0); weld.C1 = attach and attach.CFrame or CFrame.new() end
            weld.Parent = handle
        end
    end
    model:Destroy()
    JAWADEOBF_WindUI:Notify({ Title = "Avatar Changer", Content = "Avatar spoofed!", Duration = 3 })
end

local JAWADEOBF_resetAvatar = function()
    local LP   = game:GetService("Players").LocalPlayer
    local char = LP.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local bk   = JAWADEOBF_avatarBackup
    if not bk  then return end

    for name, enum in pairs(JAWADEOBF_r15Parts) do
        local part = bk.body_parts[name]
        if part then pcall(function() hum:ReplaceBodyPartR15(enum, part:Clone()) end) end
    end
    local head = char:FindFirstChild("Head")
    if head and bk.head_mesh then
        local mesh = head:FindFirstChildOfClass("SpecialMesh")
        if mesh then mesh.MeshId = bk.head_mesh.MeshId; mesh.TextureId = bk.head_mesh.TextureId; mesh.Scale = bk.head_mesh.Scale; mesh.Offset = bk.head_mesh.Offset end
    end
    if head and bk.head_size  then head.Size  = bk.head_size  end
    if head and bk.head_color then head.Color = bk.head_color end
    for _, ch in ipairs(char:GetChildren()) do
        if ch:IsA("Accessory") or ch:IsA("Shirt") or ch:IsA("Pants") or ch:IsA("ShirtGraphic") or ch:IsA("CharacterMesh") then ch:Destroy() end
    end
    if head then
        for _, k in ipairs(head:GetChildren()) do if k:IsA("Decal") and (k.Name == "face" or k.Name == "Face") then k:Destroy() end end
        if bk.face then bk.face:Clone().Parent = head end
    end
    for _, cl in ipairs(bk.clothing) do cl:Clone().Parent = char end
    if bk.body_colors then
        local bc = char:FindFirstChildOfClass("BodyColors")
        if bc then bc.HeadColor3 = bk.body_colors.HeadColor3; bc.TorsoColor3 = bk.body_colors.TorsoColor3; bc.LeftArmColor3 = bk.body_colors.LeftArmColor3; bc.RightArmColor3 = bk.body_colors.RightArmColor3; bc.LeftLegColor3 = bk.body_colors.LeftLegColor3; bc.RightLegColor3 = bk.body_colors.RightLegColor3 end
    end
    for _, acc in ipairs(bk.accessories) do
        local clone  = acc:Clone()
        local handle = clone:FindFirstChild("Handle")
        if not handle then continue end
        local attach = handle:FindFirstChildOfClass("Attachment")
        for _, k in ipairs(handle:GetChildren()) do if k:IsA("Weld") or k:IsA("Motor6D") or k:IsA("WeldConstraint") then k:Destroy() end end
        local targetPart, targetAttach = nil, nil
        if attach then
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then
                    for _, a in ipairs(p:GetChildren()) do if a:IsA("Attachment") and a.Name == attach.Name then targetPart = p; targetAttach = a; break end end
                end
                if targetPart then break end
            end
        end
        if not targetPart then targetPart = char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart"); if not targetPart then continue end end
        clone.Parent = char
        local weld = Instance.new("Weld"); weld.Part0 = targetPart; weld.Part1 = handle
        if targetAttach and attach then weld.C0 = targetAttach.CFrame; weld.C1 = attach.CFrame
        else weld.C0 = CFrame.new(0, targetPart.Size.Y / 2, 0); weld.C1 = handle.CFrame end
        weld.Parent = handle
    end
    for name, val in pairs(bk.scales) do
        local scale = hum:FindFirstChild(name)
        if scale and scale:IsA("NumberValue") then scale.Value = val end
    end
    JAWADEOBF_avatarBackup = nil
    JAWADEOBF_WindUI:Notify({ Title = "Avatar Changer", Content = "Avatar reset!", Duration = 3 })
end

JAWADEOBF_AvatarSection:Input({
    Title = "Spoof Avatar (Username)", PlaceholderText = "Target Username...",
    ClearTextOnFocus = false, Flag = "AvatarTargetUsername",
    Callback = function(v)
        if v and v ~= "" then
            task.spawn(function()
                local ok, uid = pcall(function() return game:GetService("Players"):GetUserIdFromNameAsync(v) end)
                if ok and uid then JAWADEOBF_applyAvatarSpoof(uid)
                else JAWADEOBF_WindUI:Notify({ Title = "Avatar Changer", Content = "Player not found!", Duration = 3 }) end
            end)
        end
    end,
})
JAWADEOBF_AvatarSection:Button({ Title = "Reset Avatar", Desc = "Revert ke avatar asli", Callback = JAWADEOBF_resetAvatar })
JAWADEOBF_AvatarSection:Input({
    Title = "Spoof Name (Local)", PlaceholderText = "Fake Name...", ClearTextOnFocus = false, Flag = "AvatarSpoofName",
    Callback = function(v)
        JAWADEOBF_spoofName = v; JAWADEOBF_spoofNameOn = (v ~= "")
        JAWADEOBF_WindUI:Notify({ Title = "Name Spoofer", Content = (v ~= "") and ("Spoofing: " .. v) or "Disabled.", Duration = 3 })
    end,
})
JAWADEOBF_AvatarSection:Input({
    Title = "Spoof Rank (Local)", PlaceholderText = "Fake Rank...", ClearTextOnFocus = false, Flag = "AvatarSpoofRank",
    Callback = function(v)
        JAWADEOBF_spoofRank = v; JAWADEOBF_spoofRankOn = (v ~= "")
        JAWADEOBF_WindUI:Notify({ Title = "Rank Spoofer", Content = (v ~= "") and ("Spoofing: " .. v) or "Disabled.", Duration = 3 })
    end,
})
JAWADEOBF_AvatarSection:Input({
    Title = "Custom Prefix (Name)", PlaceholderText = "e.g. 505", ClearTextOnFocus = false, Flag = "AvatarCustomPrefix",
    Callback = function(v) JAWADEOBF_prefixText = v end,
})
JAWADEOBF_AvatarSection:Colorpicker({
    Title = "Prefix Color", Desc = "Warna prefix", Default = Color3.fromRGB(24, 24, 24),
    Transparency = 0, Locked = false, Flag = "AvatarPrefixColor",
    Callback = function(v) JAWADEOBF_prefixColor = v end,
})
JAWADEOBF_AvatarSection:Colorpicker({
    Title = "Name Shadow Color", Desc = "Warna shadow nama", Default = Color3.fromRGB(0, 0, 0),
    Transparency = 0, Locked = false, Flag = "AvatarNameShadowColor",
    Callback = function(v) JAWADEOBF_nameShadowColor = v end,
})
JAWADEOBF_AvatarSection:Input({
    Title = "Rank Gradient Sequence", PlaceholderText = "Studio ColorSequence string...", ClearTextOnFocus = false, Flag = "AvatarRankGradient",
    Callback = function(v)
        if v ~= "" then
            local seq = JAWADEOBF_parseColorSequence(v)
            if seq then JAWADEOBF_rankGradient = seq; JAWADEOBF_WindUI:Notify({ Title = "Rank Spoofer", Content = "Gradient parsed!", Duration = 3 })
            else JAWADEOBF_WindUI:Notify({ Title = "Rank Spoofer", Content = "Invalid format!", Duration = 3 }) end
        else JAWADEOBF_rankGradient = nil end
    end,
})

task.spawn(function()
    while task.wait(1) do
        local LP = game:GetService("Players").LocalPlayer
        if not LP then continue end
        if JAWADEOBF_spoofNameOn and JAWADEOBF_spoofName ~= "" then
            pcall(function()
                local realName    = LP.Name
                local displayName = LP.DisplayName
                local function replaceAll(root)
                    if not root then return end
                    for _, k in ipairs(root:GetDescendants()) do
                        if k:IsA("TextLabel") or k:IsA("TextButton") or k:IsA("TextBox") then
                            if k.Text:find(realName) or k.Text:find(displayName) then
                                k.Text = k.Text:gsub(realName, JAWADEOBF_spoofName):gsub(displayName, JAWADEOBF_spoofName)
                            end
                        end
                    end
                end
                replaceAll(LP:FindFirstChild("PlayerGui"))
                if LP.Character then replaceAll(LP.Character) end
            end)
        end
        pcall(function()
            local wsChar = workspace:FindFirstChild(LP.Name) or LP.Character
            if wsChar then
                local head = wsChar:FindFirstChild("Head")
                if head then
                    local tags    = head:FindFirstChild("RankTags")
                    if tags then
                        local nameLbl = tags:FindFirstChild("Player_Username")
                        local rankLbl = tags:FindFirstChild("Player_Rank")
                        if JAWADEOBF_spoofNameOn and JAWADEOBF_spoofName ~= "" and nameLbl and nameLbl:IsA("TextLabel") then
                            local tag = nameLbl.Text:match("^(<font.->%[.-%]%</font>)")
                            if JAWADEOBF_prefixText ~= "" then
                                nameLbl.Text = string.format(
                                    "<font color=\"rgb(%d,%d,%d)\">[%s]</font> %s",
                                    math.floor(JAWADEOBF_prefixColor.R * 255),
                                    math.floor(JAWADEOBF_prefixColor.G * 255),
                                    math.floor(JAWADEOBF_prefixColor.B * 255),
                                    JAWADEOBF_prefixText, JAWADEOBF_spoofName
                                )
                            elseif tag then nameLbl.Text = tag .. " " .. JAWADEOBF_spoofName
                            else nameLbl.Text = JAWADEOBF_spoofName end
                            local shadow = nameLbl:FindFirstChild("Shadow")
                            if shadow and shadow:IsA("TextLabel") then shadow.Text = nameLbl.Text; shadow.TextColor3 = JAWADEOBF_nameShadowColor end
                        end
                        if JAWADEOBF_spoofRankOn and JAWADEOBF_spoofRank ~= "" and rankLbl and rankLbl:IsA("TextLabel") then
                            rankLbl.Text = JAWADEOBF_spoofRank
                            local grad = rankLbl:FindFirstChildOfClass("UIGradient")
                            if grad and JAWADEOBF_rankGradient then grad.Color = JAWADEOBF_rankGradient end
                        end
                    end
                end
            end
        end)
    end
end)

--=====================================================================
-- TAB: CONFIGURATION
--=====================================================================
local JAWADEOBF_ConfigTab    = JAWADEOBF_Window:Tab({ Title = "Configuration", Icon = "settings" })
local JAWADEOBF_ThemeSection = JAWADEOBF_ConfigTab:Section({ Title = "Theme" })

local JAWADEOBF_themeList = {}
pcall(function()
    local themes = JAWADEOBF_WindUI:GetThemes()
    if themes then
        for k, v in pairs(themes) do
            if type(v) == "string" then table.insert(JAWADEOBF_themeList, v)
            elseif type(k) == "string" then table.insert(JAWADEOBF_themeList, k) end
        end
    end
end)
if #JAWADEOBF_themeList == 0 then
    JAWADEOBF_themeList = { "Dark","Light","Rose","Plant","Red","Indigo","Sky","Violet","Amber","Emerald","Midnight","Crimson","Monokai Pro","Cotton Candy","Mellowsi","Rainbow" }
end

JAWADEOBF_ConfigTab:Dropdown({
    Title = "Select Theme", Desc = "Choose UI Theme", Multi = false,
    Flag  = "SelectedTheme", Value = JAWADEOBF_WindUI:GetCurrentTheme() or "Dark", Values = JAWADEOBF_themeList,
    Callback = function(v) pcall(function() JAWADEOBF_WindUI:SetTheme(v) end) end,
})

local JAWADEOBF_ConfigSection  = JAWADEOBF_ConfigTab:Section({ Title = "Config Manager" })
local JAWADEOBF_selectedConfig = ""
local JAWADEOBF_configName     = ""

local JAWADEOBF_getConfigs = function()
    local list = {}
    pcall(function()
        local all = JAWADEOBF_Window.ConfigManager:AllConfigs()
        if all then for _, c in ipairs(all) do table.insert(list, c) end end
    end)
    return list
end

local JAWADEOBF_configDropdown = JAWADEOBF_ConfigTab:Dropdown({
    Title = "Select Config", Desc = "Choose saved config", Multi = false,
    Flag  = "SelectedConfigDropdown", Value = "", Values = JAWADEOBF_getConfigs(),
    Callback = function(v) JAWADEOBF_selectedConfig = v end,
})

JAWADEOBF_ConfigTab:Input({
    Title = "Config Name", Desc = "New config name", PlaceholderText = "Enter config name...",
    Flag  = "ConfigNameInput", Callback = function(v) JAWADEOBF_configName = v end,
})

JAWADEOBF_ConfigTab:Button({
    Title = "Save Config", Desc = "Save current settings",
    Callback = function()
        if JAWADEOBF_configName == "" then JAWADEOBF_WindUI:Notify({ Title = "Config", Content = "Enter config name first!", Duration = 3 }); return end
        pcall(function()
            JAWADEOBF_selectedConfig = JAWADEOBF_configName
            pcall(function() JAWADEOBF_configDropdown:Select(JAWADEOBF_configName) end)
            local cfg = JAWADEOBF_Window.ConfigManager:CreateConfig(JAWADEOBF_configName); cfg:Save()
        end)
        JAWADEOBF_WindUI:Notify({ Title = "Config", Content = "'" .. JAWADEOBF_configName .. "' saved!", Duration = 3 })
        pcall(function() JAWADEOBF_configDropdown:Refresh(JAWADEOBF_getConfigs()); JAWADEOBF_configDropdown:Select(JAWADEOBF_configName) end)
    end,
})

JAWADEOBF_ConfigTab:Button({
    Title = "Load Config", Desc = "Load selected config",
    Callback = function()
        if JAWADEOBF_selectedConfig == "" then JAWADEOBF_WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 }); return end
        pcall(function()
            local cfg = JAWADEOBF_Window.ConfigManager:CreateConfig(JAWADEOBF_selectedConfig); cfg:Load()
            pcall(function() JAWADEOBF_configDropdown:Select(JAWADEOBF_selectedConfig) end)
        end)
        JAWADEOBF_WindUI:Notify({ Title = "Config", Content = "'" .. JAWADEOBF_selectedConfig .. "' loaded!", Duration = 3 })
    end,
})

JAWADEOBF_ConfigTab:Button({
    Title = "Delete Config", Desc = "Delete selected config",
    Callback = function()
        if JAWADEOBF_selectedConfig == "" then JAWADEOBF_WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 }); return end
        pcall(function()
            local cfg = JAWADEOBF_Window.ConfigManager:CreateConfig(JAWADEOBF_selectedConfig); cfg:Delete()
        end)
        JAWADEOBF_WindUI:Notify({ Title = "Config", Content = "'" .. JAWADEOBF_selectedConfig .. "' deleted!", Duration = 3 })
        JAWADEOBF_selectedConfig = ""
        pcall(function() JAWADEOBF_configDropdown:Refresh(JAWADEOBF_getConfigs()); JAWADEOBF_configDropdown:Select("") end)
    end,
})

JAWADEOBF_ConfigTab:Button({
    Title = "Set Auto Load", Desc = "Auto load config ini saat start",
    Callback = function()
        if JAWADEOBF_selectedConfig == "" then JAWADEOBF_WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 }); return end
        pcall(function()
            local http = game:GetService("HttpService")
            local all  = JAWADEOBF_Window.ConfigManager:AllConfigs()
            if all and isfile and readfile and writefile then
                for _, c in ipairs(all) do
                    local p = "WindUI/DX-SR/config/" .. c .. ".json"
                    if isfile(p) then
                        pcall(function()
                            local d = http:JSONDecode(readfile(p))
                            if type(d) == "table" then d.__autoload = (c == JAWADEOBF_selectedConfig); writefile(p, http:JSONEncode(d)) end
                        end)
                    end
                end
            end
            pcall(function() JAWADEOBF_configDropdown:Select(JAWADEOBF_selectedConfig) end)
            if JAWADEOBF_Window.ConfigManager and JAWADEOBF_Window.ConfigManager.Configs then
                for name, cfg in pairs(JAWADEOBF_Window.ConfigManager.Configs) do
                    if cfg and cfg.SetAutoLoad then cfg:SetAutoLoad(name == JAWADEOBF_selectedConfig) end
                end
            end
        end)
        JAWADEOBF_WindUI:Notify({ Title = "Config", Content = "Auto load set to '" .. JAWADEOBF_selectedConfig .. "'!", Duration = 3 })
    end,
})

pcall(function()
    local http = game:GetService("HttpService")
    local all  = JAWADEOBF_Window.ConfigManager:AllConfigs()
    if all and readfile and isfile then
        for _, c in pairs(all) do
            local p = "WindUI/DX-SR/config/" .. c .. ".json"
            if isfile(p) then
                local ok, data = pcall(function() return http:JSONDecode(readfile(p)) end)
                if ok and type(data) == "table" and data.__autoload then
                    local cfg = JAWADEOBF_Window.ConfigManager:CreateConfig(c); cfg:Load()
                    JAWADEOBF_selectedConfig = c
                    task.defer(function() pcall(function() JAWADEOBF_configDropdown:Select(c) end) end)
                    break
                end
            end
        end
    end
end)

--=====================================================================
-- EDIT OPEN BUTTON
--=====================================================================
JAWADEOBF_Window:EditOpenButton({
    Title           = "Open UI",
    Icon            = "monitor",
    CornerRadius    = UDim.new(0, 16),
    StrokeThickness = 2,
    Color           = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile      = false,
    Enabled         = true,
})