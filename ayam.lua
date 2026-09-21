local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- ============================================================
-- RUNTIME
-- ============================================================
local environment = (getgenv and getgenv()) or _G
local RUNTIME_KEY = "__ANTI_TP_BAT_DESYNC_RUNTIME"
local previousRuntime = environment[RUNTIME_KEY]
if type(previousRuntime) == "table" and type(previousRuntime.destroy) == "function" then
    pcall(previousRuntime.destroy)
end

local runtime = {
    alive = true,
    enabled = false,
    awaitingKey = false,
    boundKey = Enum.KeyCode.Delete,
    character = nil,
    rootPart = nil,
    fakeRoot = nil,
    repRootOwner = nil,
    stepConnection = nil,
    connections = {},
    captureGeneration = 0,
    mode = "ORIGINAL",
    loopActive = false,
    loopConnection = nil,
    originalCFrame = nil,
    config = {
        Radius = 25,
        VelocityThreshold = 60,
        DeltaThreshold = 15,
        AnchorTime = 0.2,
        PushPower = 800,
        PushEnabled = true,
        AnchorEnabled = true,
        Cooldown = 0.15,
        LastTrigger = 0,
        FlashEnabled = false,
    },
}
environment[RUNTIME_KEY] = runtime

-- ============================================================
-- HELPERS
-- ============================================================
local function disconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(runtime.connections, connection)
    return connection
end

local function createInstance(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    if parent then object.Parent = parent end
    return object
end

local function addCorner(parent, radius)
    return createInstance("UICorner", {
        CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius),
    }, parent)
end

local function addStroke(parent, color, transparency, thickness)
    return createInstance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    }, parent)
end

local function isBasePart(instance)
    if not instance then return false end
    local ok, result = pcall(function() return instance:IsA("BasePart") end)
    return ok and result == true
end

local function getCurrentRoot(character)
    character = character or LP.Character
    if not character then return nil end
    local ok, root = pcall(function() return character:FindFirstChild("HumanoidRootPart") end)
    if ok and isBasePart(root) then return root end
    return nil
end

local function findGlobalFunction(...)
    for index = 1, select("#", ...) do
        local name = select(index, ...)
        local value = rawget(environment, name)
        if type(value) == "function" then return value end
        value = rawget(_G, name)
        if type(value) == "function" then return value end
    end
    return nil
end

local function setHidden(instance, property, value)
    if not instance then return false end
    local setter = findGlobalFunction("sethiddenproperty", "set_hidden_property", "sethiddenprop", "set_hidden_prop")
    if setter then
        local ok = pcall(setter, instance, property, value)
        if ok then return true end
    end
    return pcall(function() instance[property] = value end)
end

local function getHidden(instance, property)
    if not instance then return false, nil end
    local getter = findGlobalFunction("gethiddenproperty", "get_hidden_property", "gethiddenprop", "get_hidden_prop")
    if getter then
        local ok, value = pcall(getter, instance, property)
        if ok then return true, value end
    end
    local ok, value = pcall(function() return instance[property] end)
    return ok, value
end

-- ============================================================
-- CONFIG FÃSICA
-- ============================================================
local function configurePhysics()
    pcall(function()
        setHidden(LP, "MaximumSimulationRadius", math.huge)
        setHidden(LP, "SimulationRadius", math.huge)
    end)
    pcall(function()
        local networkSettings = settings().Network
        networkSettings.InterpolationThrottling = Enum.InterpolationThrottlingMode.Disabled
    end)
    pcall(function()
        local physicsSettings = settings().Physics
        physicsSettings.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
        physicsSettings.AllowSleep = false
    end)
end
configurePhysics()

-- ============================================================
-- FAKE ROOT
-- ============================================================
local FAKE_ROOT_NAME = "AntiTPBat_DesyncRoot"
local FAKE_ROOT_Y = -2500
local FAKE_ROOT_VELOCITY = Vector3.new(0, -1000, 0)

local function fakeRootIsUsable()
    local fake = runtime.fakeRoot
    if not isBasePart(fake) then return false end
    local ok, parent = pcall(function() return fake.Parent end)
    return ok and parent ~= nil
end

local function destroyFakeRoot()
    local fake = runtime.fakeRoot
    runtime.fakeRoot = nil
    if fake then pcall(function() fake:Destroy() end) end
end

local function createFakeRoot(basePosition)
    destroyFakeRoot()
    local fake = createInstance("Part", {
        Name = FAKE_ROOT_NAME,
        Size = Vector3.new(2, 2, 1),
        Anchored = true,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        Transparency = 1,
        CFrame = CFrame.new(basePosition.X, FAKE_ROOT_Y, basePosition.Z),
        AssemblyLinearVelocity = FAKE_ROOT_VELOCITY,
    }, Workspace)
    runtime.fakeRoot = fake
    return fake
end

local function assignFakeReplicationRoot(rootPart, fake)
    if not isBasePart(rootPart) or not isBasePart(fake) then return false end
    runtime.repRootOwner = rootPart
    return setHidden(rootPart, "PhysicsRepRootPart", fake)
end

local function restoreReplicationRoot()
    local root = runtime.rootPart or getCurrentRoot()
    if isBasePart(root) then
        setHidden(root, "PhysicsRepRootPart", root)
    end
    if isBasePart(runtime.repRootOwner) and runtime.repRootOwner ~= root then
        setHidden(runtime.repRootOwner, "PhysicsRepRootPart", runtime.repRootOwner)
    end
    runtime.repRootOwner = nil
end

-- ============================================================
-- STEP DESYNC
-- ============================================================
local function stepDesync()
    if not runtime.alive or not runtime.enabled then return end
    local root = runtime.rootPart
    if not isBasePart(root) then
        root = getCurrentRoot(runtime.character)
        runtime.rootPart = root
    end
    if not root then return end
    if not fakeRootIsUsable() then
        local fake = createFakeRoot(root.Position)
        assignFakeReplicationRoot(root, fake)
        return
    end
    local fake = runtime.fakeRoot
    pcall(function()
        fake.Anchored = true
        fake.AssemblyLinearVelocity = FAKE_ROOT_VELOCITY
    end)
    local gotValue, current = getHidden(root, "PhysicsRepRootPart")
    if not gotValue or current ~= fake then
        setHidden(root, "PhysicsRepRootPart", fake)
    end
end

local function stopStepConnection()
    disconnect(runtime.stepConnection)
    runtime.stepConnection = nil
end

local function startStepConnection()
    stopStepConnection()
    runtime.stepConnection = RunService.Stepped:Connect(stepDesync)
end

-- ============================================================
-- APLICAR MODO NO FAKE ROOT
-- ============================================================
local function moveFakeTo(cf)
    local fake = runtime.fakeRoot
    if not isBasePart(fake) then return end
    pcall(function()
        fake.CFrame = cf
    end)
end

local function applyModeToFake()
    local fake = runtime.fakeRoot
    if not isBasePart(fake) then return end
    local base = runtime.originalCFrame
    if not base then return end

    local mode = runtime.mode
    local targetCFrame

    if mode == "ORIGINAL" then
        targetCFrame = base + Vector3.new(0, -9999, 0)
    elseif mode == "VOID" then
        targetCFrame = CFrame.new(base.Position.X, -999, base.Position.Z)
    elseif mode == "OCEAN" then
        targetCFrame = base + Vector3.new(200, 0, 0)
    elseif mode == "GROUND" then
        targetCFrame = base + Vector3.new(0, -10, 0)
    elseif mode == "SPACE" then
        targetCFrame = base + Vector3.new(0, 99, 0)
    elseif mode == "RANDOM BLINK" then
        local offset = Vector3.new(
            math.random(-100, 100),
            math.random(-50, 50),
            math.random(-100, 100)
        )
        targetCFrame = base + offset
    end

    if targetCFrame then
        moveFakeTo(targetCFrame)
    end
end

-- ============================================================
-- LOOP (ORIGINAL / Pisca Blink)
-- ============================================================
local function stopLoop()
    runtime.loopActive = false
    disconnect(runtime.loopConnection)
    runtime.loopConnection = nil
end

local function startLoop()
    stopLoop()
    runtime.loopActive = true
    runtime.loopConnection = RunService.Heartbeat:Connect(function()
        if not runtime.alive or not runtime.enabled or not runtime.loopActive then return end
        local fake = runtime.fakeRoot
        if not isBasePart(fake) then return end
        local base = runtime.originalCFrame
        if not base then return end

        -- Vai pra posiÃ§Ã£o do modo
        applyModeToFake()

        -- Espera 0.2s e volta pra base
        task.delay(0.2, function()
            if not runtime.alive or not runtime.enabled then return end
            local f = runtime.fakeRoot
            if not isBasePart(f) then return end
            pcall(function()
                f.CFrame = base
            end)
        end)
    end)
end

-- ============================================================
-- DETECÃ‡ÃƒO
-- ============================================================
local trackers = {}

local function GetChar(plr) return plr and plr.Character or nil end
local function GetRoot(plr)
    local c = GetChar(plr)
    return c and c:FindFirstChild("HumanoidRootPart") or nil
end
local function GetHum(plr)
    local c = GetChar(plr)
    return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function CheckTeleport(plr, root)
    local now = tick()
    local prev = trackers[plr]
    if not prev then
        trackers[plr] = { lastPos = root.Position, lastTime = now }
        return false
    end
    local dt = now - prev.lastTime
    if dt < 0.005 then return false end
    local delta = (root.Position - prev.lastPos).Magnitude
    local speed = delta / dt
    prev.lastPos = root.Position
    prev.lastTime = now
    if speed > runtime.config.VelocityThreshold or delta > runtime.config.DeltaThreshold then
        return true, speed, delta
    end
    return false
end

local function HasTool(plr)
    local c = GetChar(plr)
    if not c then return false end
    return c:FindFirstChildOfClass("Tool") ~= nil
end

-- ============================================================
-- ANCHOR SELF
-- ============================================================
local isAnchored = false
local lastAnchorParts = {}

local function AnchorSelf()
    if not runtime.config.AnchorEnabled then return end
    if isAnchored then return end
    isAnchored = true

    local char = LP.Character
    if not char then isAnchored = false return end

    lastAnchorParts = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(lastAnchorParts, { part = part, anchored = part.Anchored })
            part.Anchored = true
        end
    end
    task.delay(runtime.config.AnchorTime, function()
        for _, entry in ipairs(lastAnchorParts) do
            if entry.part and entry.part.Parent then
                entry.part.Anchored = entry.anchored
            end
        end
        lastAnchorParts = {}
        isAnchored = false
    end)
end

-- ============================================================
-- PUSH
-- ============================================================
local function PushAttacker(attacker, myRoot)
    if not runtime.config.PushEnabled then return end
    local atkRoot = GetRoot(attacker)
    if not atkRoot then return end

    local dir = atkRoot.Position - myRoot.Position
    if dir.Magnitude < 0.1 then
        dir = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
    end
    dir = dir.Unit
    if dir.Y ~= dir.Y then dir = Vector3.new(1, 0, 0) end

    pcall(function() atkRoot:SetNetworkOwner(LP) end)

    local force = dir * runtime.config.PushPower + Vector3.new(0, 100, 0)
    pcall(function() atkRoot.AssemblyLinearVelocity = force end)

    pcall(function()
        local old = atkRoot:FindFirstChild("AntiTPBat_Push")
        if old then old:Destroy() end
        local oldAtt = atkRoot:FindFirstChild("AntiTPBat_Att")
        if oldAtt then oldAtt:Destroy() end

        local att = Instance.new("Attachment")
        att.Name = "AntiTPBat_Att"
        att.Parent = atkRoot

        local lv = Instance.new("LinearVelocity")
        lv.Name = "AntiTPBat_Push"
        lv.Attachment0 = att
        lv.MaxForce = math.huge
        lv.VectorVelocity = force
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.Parent = atkRoot

        task.delay(0.25, function()
            if lv and lv.Parent then lv:Destroy() end
            if att and att.Parent then att:Destroy() end
        end)
    end)
end

-- ============================================================
-- FLASH
-- ============================================================
local flashGui
local function Flash()
    if not runtime.config.FlashEnabled then return end
    if not flashGui or not flashGui.Parent then
        flashGui = Instance.new("ScreenGui")
        flashGui.Name = "AntiTPBatFlash"
        flashGui.IgnoreGuiInset = true
        flashGui.ResetOnSpawn = false
        flashGui.DisplayOrder = 9999
        pcall(function() flashGui.Parent = CoreGui end)
    end
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
    f.BackgroundTransparency = 0.6
    f.BorderSizePixel = 0
    f.Parent = flashGui
    task.spawn(function()
        for i = 1, 6 do
            f.BackgroundTransparency = f.BackgroundTransparency + 0.066
            task.wait(0.02)
        end
        f:Destroy()
    end)
end

-- ============================================================
-- ACTIVATE
-- ============================================================
local function Activate(attacker)
    local now = tick()
    if now - runtime.config.LastTrigger < runtime.config.Cooldown then return end
    runtime.config.LastTrigger = now

    local myRoot = GetRoot(LP)
    if not myRoot then return end

    Flash()

    if attacker then PushAttacker(attacker, myRoot) end
    AnchorSelf()
end

-- ============================================================
-- DETECTION LOOP
-- ============================================================
local detectionConn

local function StartDetection()
    if detectionConn then detectionConn:Disconnect() end
    detectionConn = RunService.Heartbeat:Connect(function()
        if not runtime.enabled then return end
        if isAnchored then return end
        local myRoot = GetRoot(LP)
        if not myRoot then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local root = GetRoot(plr)
                if root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist <= runtime.config.Radius then
                        if CheckTeleport(plr, root) then
                            Activate(plr)
                            return
                        end
                        if dist < 6 and HasTool(plr) then
                            Activate(plr)
                            return
                        end
                    else
                        CheckTeleport(plr, root)
                    end
                end
            end
        end
    end)
end

local function StopDetection()
    if detectionConn then detectionConn:Disconnect() detectionConn = nil end
end

-- ============================================================
-- BIND CHARACTER
-- ============================================================
local function bindCharacter(character)
    local oldRoot = runtime.rootPart
    runtime.character = character
    runtime.rootPart = getCurrentRoot(character)
    if runtime.enabled then
        if isBasePart(oldRoot) and oldRoot ~= runtime.rootPart then
            setHidden(oldRoot, "PhysicsRepRootPart", oldRoot)
        end
        destroyFakeRoot()
        local root = runtime.rootPart
        if not root and character then
            local ok, waitedRoot = pcall(function()
                return character:WaitForChild("HumanoidRootPart", 8)
            end)
            if ok and isBasePart(waitedRoot) then
                root = waitedRoot
                runtime.rootPart = root
            end
        end
        if root then
            runtime.originalCFrame = root.CFrame
            local fake = createFakeRoot(root.Position)
            assignFakeReplicationRoot(root, fake)
            startStepConnection()
            applyModeToFake()
        end
    end
end

bindCharacter(LP.Character)
connect(LP.CharacterAdded, function(character)
    task.defer(bindCharacter, character)
end)

-- ============================================================
-- ENABLE / DISABLE
-- ============================================================
local function setEnabled(value)
    if not runtime.alive then return false end
    value = value == true
    if runtime.enabled == value then return value end

    if value then
        local root = getCurrentRoot(runtime.character or LP.Character)
        if not root then return false end
        runtime.rootPart = root
        runtime.character = LP.Character
        runtime.originalCFrame = root.CFrame
        runtime.enabled = true

        local fake = createFakeRoot(root.Position)
        assignFakeReplicationRoot(root, fake)
        startStepConnection()
        StartDetection()

        if runtime.mode == "ORIGINAL" or runtime.config.FlashEnabled then
            startLoop()
        else
            applyModeToFake()
        end
    else
        runtime.enabled = false

        stopLoop()
        StopDetection()
        stopStepConnection()
        -- RESTAURA o PhysicsRepRootPart (senÃ£o vocÃª nÃ£o anda)
        restoreReplicationRoot()
        destroyFakeRoot()

        -- Garante que o root real volta a ser dono de si mesmo
        local root = runtime.rootPart or getCurrentRoot(runtime.character)
        if isBasePart(root) then
            pcall(function()
                root:SetNetworkOwner(LP)
            end)
        end

        runtime.originalCFrame = nil
    end
    return runtime.enabled
end

local function toggleEnabled()
    return setEnabled(not runtime.enabled)
end

-- ============================================================
-- UI
-- ============================================================
local parentGui = (gethui and gethui()) or CoreGui
local oldGui = parentGui:FindFirstChild("AntiAntiBatHub")
if oldGui then oldGui:Destroy() end

local ScreenGui = createInstance("ScreenGui", {
    Name = "AntiAntiBatHub",
    DisplayOrder = 15,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
}, parentGui)
runtime.gui = ScreenGui

local Frame = createInstance("Frame", {
    Size = UDim2.new(0, 200, 0, 86),
    Position = UDim2.new(0.5, -100, 0.5, -43),
    BackgroundColor3 = Color3.fromRGB(10, 10, 10),
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Active = true,
}, ScreenGui)
addCorner(Frame, 8)
addStroke(Frame, Color3.fromRGB(60, 60, 60), 0.3)

-- Escala ligeiramente menor em telas touch e permite arraste por toque.
createInstance("UIScale", {
    Scale = UserInputService.TouchEnabled and 0.9 or 1,
}, Frame)

local Header = createInstance("Frame", {
    Size = UDim2.new(1, -8, 0, 30),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
}, Frame)
addCorner(Header, 6)

createInstance("TextLabel", {
    Size = UDim2.new(1, -100, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "ez mm2 anti hit/invisible",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local StatusFrame = createInstance("Frame", {
    Size = UDim2.new(0, 42, 0, 18),
    Position = UDim2.new(1, -42, 0.5, -9),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
}, Header)
addCorner(StatusFrame, 4)

local StatusText = createInstance("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "OFF",
    TextColor3 = Color3.fromRGB(255, 80, 100),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
}, StatusFrame)

local LockBtn = createInstance("TextButton", {
    Size = UDim2.new(0, 22, 0, 22),
    Position = UDim2.new(1, -68, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Text = "ðŸ”“",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    AutoButtonColor = false,
    Active = true,
}, Header)
addCorner(LockBtn, 4)

local ActivateBtn = createInstance("TextButton", {
    Size = UDim2.new(1, -16, 0, 32),
    Position = UDim2.new(0, 8, 0, 44),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Text = "ACTIVATE",
    TextColor3 = Color3.fromRGB(220, 220, 220),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    AutoButtonColor = false,
}, Frame)
addCorner(ActivateBtn, 6)
addStroke(ActivateBtn, Color3.fromRGB(80, 80, 80), 0)

local Settings = createInstance("Frame", {
    Size = UDim2.new(0, 220, 0, 360),
    Position = UDim2.new(0.5, -110, 0.5, -43),
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 0,
    Visible = false,
    Active = true,
}, ScreenGui)
addCorner(Settings, 8)
addStroke(Settings, Color3.fromRGB(60, 60, 60), 0)

local SetHeader = createInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
}, Settings)
addCorner(SetHeader, 8)

createInstance("TextLabel", {
    Size = UDim2.new(1, -40, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "SETTINGS",
    TextColor3 = Color3.fromRGB(220, 220, 220),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, SetHeader)

local SetClose = createInstance("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -28, 0.5, -12),
    BackgroundTransparency = 1,
    Text = "âœ•",
    TextColor3 = Color3.fromRGB(150, 150, 150),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
}, SetHeader)

local SetContent = createInstance("Frame", {
    Size = UDim2.new(1, -16, 1, -44),
    Position = UDim2.new(0, 8, 0, 38),
    BackgroundTransparency = 1,
}, Settings)
createInstance("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
}, SetContent)

createInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    Text = "MODE OPTIONS",
    TextColor3 = Color3.fromRGB(150, 150, 150),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 1,
}, SetContent)

local Modes = { "ORIGINAL", "VOID", "OCEAN", "GROUND", "SPACE", "RANDOM BLINK" }
local modeButtons = {}

local function SelectMode(name)
    runtime.mode = name
    for _, btn in pairs(modeButtons) do
        local lbl = btn:FindFirstChildOfClass("TextLabel")
        if lbl and lbl.Text == name then
            lbl.TextColor3 = Color3.fromRGB(220, 20, 20)
            btn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
        elseif lbl then
            lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
        end
    end

    if runtime.enabled then
        stopLoop()
        if runtime.mode == "ORIGINAL" or runtime.config.FlashEnabled then
            startLoop()
        else
            applyModeToFake()
        end
    end
end

for i, mode in ipairs(Modes) do
    local btn = createInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Color3.fromRGB(26, 26, 26),
        BorderSizePixel = 0,
        Text = "",
        LayoutOrder = i + 1,
        AutoButtonColor = false,
    }, SetContent)
    addCorner(btn, 4)

    createInstance("TextLabel", {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = mode,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, btn)

    local dot = createInstance("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(1, -16, 0.5, -4),
        BackgroundColor3 = Color3.fromRGB(80, 80, 80),
        BorderSizePixel = 0,
    }, btn)
    addCorner(dot, UDim.new(1, 0))

    connect(btn.MouseButton1Click, function()
        SelectMode(mode)
    end)

    table.insert(modeButtons, btn)
end

SelectMode("ORIGINAL")

-- Pisca Blink
createInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "FLASH MODE (Pisca Blink)",
    TextColor3 = Color3.fromRGB(150, 150, 150),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 100,
}, SetContent)

local FlashBtn = createInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = Color3.fromRGB(26, 26, 26),
    BorderSizePixel = 0,
    Text = "",
    LayoutOrder = 101,
    AutoButtonColor = false,
}, SetContent)
addCorner(FlashBtn, 4)

createInstance("TextLabel", {
    Size = UDim2.new(0.7, 0, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Pisca (Blink)",
    TextColor3 = Color3.fromRGB(200, 200, 200),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, FlashBtn)

local FlashToggle = createInstance("TextButton", {
    Size = UDim2.new(0, 50, 0, 18),
    Position = UDim2.new(1, -58, 0.5, -9),
    BackgroundColor3 = Color3.fromRGB(50, 30, 30),
    BorderSizePixel = 0,
    Text = "OFF",
    TextColor3 = Color3.fromRGB(200, 200, 200),
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    AutoButtonColor = false,
}, FlashBtn)
addCorner(FlashToggle, 4)

local flashState = false
connect(FlashToggle.MouseButton1Click, function()
    flashState = not flashState
    FlashToggle.Text = flashState and "ON" or "OFF"
    FlashToggle.BackgroundColor3 = flashState and Color3.fromRGB(60, 20, 20) or Color3.fromRGB(50, 30, 30)
    runtime.config.FlashEnabled = flashState

    if runtime.enabled then
        stopLoop()
        if runtime.mode == "ORIGINAL" or flashState then
            startLoop()
        else
            applyModeToFake()
        end
    end
end)

-- Keybind
createInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "KEYBIND",
    TextColor3 = Color3.fromRGB(150, 150, 150),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 200,
}, SetContent)

local KeyBtn = createInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundColor3 = Color3.fromRGB(26, 26, 26),
    BorderSizePixel = 0,
    Text = "",
    LayoutOrder = 201,
    AutoButtonColor = false,
}, SetContent)
addCorner(KeyBtn, 4)

createInstance("TextLabel", {
    Size = UDim2.new(0.7, 0, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "ANTI TP BAT",
    TextColor3 = Color3.fromRGB(200, 200, 200),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, KeyBtn)

local KBValue = createInstance("TextButton", {
    Size = UDim2.new(0, 60, 0, 18),
    Position = UDim2.new(1, -68, 0.5, -9),
    BackgroundColor3 = Color3.fromRGB(26, 26, 26),
    BorderSizePixel = 0,
    Text = "Delete",
    TextColor3 = Color3.fromRGB(220, 220, 220),
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    AutoButtonColor = false,
}, KeyBtn)
addCorner(KBValue, 4)
addStroke(KBValue, Color3.fromRGB(80, 80, 80), 0.5)

local listening = false
connect(KBValue.MouseButton1Click, function()
    listening = true
    KBValue.Text = "..."
end)

-- ============================================================
-- UI LOCK
-- ============================================================
local uiLocked = false

local function setUILocked(value)
    uiLocked = value == true
    LockBtn.Text = uiLocked and "ðŸ”’" or "ðŸ”“"
    LockBtn.BackgroundColor3 = uiLocked and Color3.fromRGB(70, 25, 25) or Color3.fromRGB(30, 30, 30)
    ActivateBtn.Active = not uiLocked
    ActivateBtn.AutoButtonColor = not uiLocked
    ActivateBtn.TextColor3 = uiLocked and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(220, 220, 220)
end

connect(LockBtn.MouseButton1Click, function()
    setUILocked(not uiLocked)
end)

-- ============================================================
-- INPUT
-- ============================================================
connect(UserInputService.InputBegan, function(input, gp)
    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
        listening = false
        KBValue.Text = input.KeyCode.Name
        runtime.boundKey = input.KeyCode
        return
    end
    if gp then return end
    if input.KeyCode == runtime.boundKey then
        local on = toggleEnabled()
        StatusText.Text = on and "ON" or "OFF"
        StatusText.TextColor3 = on and Color3.fromRGB(80, 255, 100) or Color3.fromRGB(255, 80, 100)
        ActivateBtn.Text = on and "DEACTIVATE" or "ACTIVATE"
    end
end)

connect(ActivateBtn.MouseButton1Click, function()
    if uiLocked then return end
    local on = toggleEnabled()
    StatusText.Text = on and "ON" or "OFF"
    StatusText.TextColor3 = on and Color3.fromRGB(80, 255, 100) or Color3.fromRGB(255, 80, 100)
    ActivateBtn.Text = on and "DEACTIVATE" or "ACTIVATE"
end)

connect(ActivateBtn.MouseEnter, function()
    if uiLocked then return end
    TweenService:Create(ActivateBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
end)
connect(ActivateBtn.MouseLeave, function()
    if uiLocked then return end
    TweenService:Create(ActivateBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
end)

connect(SetClose.MouseButton1Click, function()
    Settings.Visible = false
end)

-- Drag
local dragging, dragStart, startPos
connect(Header.InputBegan, function(input)
    if not uiLocked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
connect(Header.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
connect(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local drag2, start2, pos2
connect(SetHeader.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag2 = true
        start2 = input.Position
        pos2 = Settings.Position
    end
end)
connect(SetHeader.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag2 = false
    end
end)
connect(UserInputService.InputChanged, function(input)
    if drag2 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - start2
        Settings.Position = UDim2.new(
            pos2.X.Scale, pos2.X.Offset + delta.X,
            pos2.Y.Scale, pos2.Y.Offset + delta.Y
        )
    end
end)

-- ============================================================
-- DESTROY
-- ============================================================
function runtime.destroy()
    runtime.alive = false
    runtime.enabled = false
    stopLoop()
    StopDetection()
    stopStepConnection()
    restoreReplicationRoot()
    destroyFakeRoot()
    for _, c in ipairs(runtime.connections) do
        disconnect(c)
    end
    table.clear(runtime.connections)
    if runtime.gui then
        pcall(function() runtime.gui:Destroy() end)
        runtime.gui = nil
    end
    if environment[RUNTIME_KEY] == runtime then
        environment[RUNTIME_KEY] = nil
    end
end

-- ============================================================
-- API
-- ============================================================
_G.AntiTPBat = {
    Toggle = toggleEnabled,
    SetMode = function(m) SelectMode(m) end,
    SetEnabled = setEnabled,
    IsEnabled = function() return runtime.enabled end,
    GetConfig = function() return runtime.config end,
    Destroy = runtime.destroy,
}

print("[Anti TP Bat] Carregado. Modo:", runtime.mode, "| Keybind:", runtime.boundKey.Name)