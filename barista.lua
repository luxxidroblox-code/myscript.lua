-- =========================================================
-- SERVICE
-- =========================================================
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:FindFirstChild("PlayerGui")

local Connections = {}
local CleanupObjects = {}

local originalMaterials = {}
local originalShadows = {}
local originalQualityLevel = settings().Rendering.QualityLevel

-- =========================================================
-- ASSETS
-- =========================================================
local Assets = {
    LOGO_FULL         = "rbxthumb://type=Asset&id=86703178512316&w=150&h=150",
    LOGO_TEXT         = "rbxthumb://type=Asset&id=136303933903606&w=150&h=150",
    LOGO_WITHOUT_TEXT = "rbxthumb://type=Asset&id=133854239689854&w=150&h=150",
}

-- =========================================================
-- CONFIG
-- =========================================================
local Config = {
    API_URL            = (getgenv and getgenv().Nexova_api_url) or "https://www.nexova.my.id/",
    GAME_NAME          = "Car Driving Indonesia",
    PRODUCT_CODE       = "NEX-CDID-BARISTA",
    LICENSE_KEY        = (getgenv and getgenv().Nexova_key) or Nexova_key or "",
    REQUEST_FUNC       = request or http_request or (syn and syn.request) or (fluxus and fluxus.request),
    HEADERS            = { ["Content-Type"] = "application/json" },
    PUBLISH_MODE       = true,
    DEBUG_MODE         = false,
    SESSION_TOKEN      = nil,
    HEARTBEAT_INTERVAL = 60,
    IS_RUNNING         = false,
}

local AuthState = {
    status_license = "unknown",
    key            = "",
    plan_license   = "N/A",
    max_devices    = 1,
    expired_at     = "N/A"
}

-- =========================================================
-- AUDIO SYSTEM
-- =========================================================
local AudioRegistry = {
    WelcomeHub  = "rbxassetid://6112625298",
    MinimizeHub = "rbxassetid://74947743572579",
    AutoFarmBGM = "rbxassetid://86316862829978",
    ToastSFX    = "rbxassetid://129485210015224"
}

local currentBGMTrack = nil

local function playEffect(actionType, isLooping)
    if isLooping and currentBGMTrack then
        pcall(function() currentBGMTrack:Destroy() end)
        currentBGMTrack = nil
    end

    task.spawn(function()
        pcall(function()
            local audioTrack = Instance.new("Sound")
            audioTrack.SoundId = AudioRegistry[actionType] or AudioRegistry.Tap
            audioTrack.Volume  = 0.8
            audioTrack.Looped  = isLooping or false

            local targetHolder = nil
            pcall(function() targetHolder = gethui() end)
            if not targetHolder then pcall(function() targetHolder = game:GetService("CoreGui") end) end
            if not targetHolder then targetHolder = SoundService end

            audioTrack.Parent = targetHolder
            if not audioTrack.IsLoaded then audioTrack.Loaded:Wait() end
            audioTrack:Play()

            if isLooping then
                currentBGMTrack = audioTrack
            else
                task.delay(audioTrack.TimeLength + 0.8, function()
                    pcall(function() audioTrack:Destroy() end)
                end)
            end
        end)
    end)
end

-- =========================================================
-- HELPER FUNCTIONS
-- =========================================================
local function debugPrint(msg)
    if Config.DEBUG_MODE then print("[NEX-PRINT] " .. tostring(msg)) end
end

local function debugWarn(msg)
    if Config.DEBUG_MODE then warn("[NEX-WARN] " .. tostring(msg)) end
end

local function getHWID()
    local hwid = nil
    pcall(function()
        if gethwid then
            local res = gethwid()
            if res and res ~= "" then hwid = res end
        end
    end)
    if not hwid then
        pcall(function()
            local clientId = RbxAnalyticsService:GetClientId()
            if clientId and clientId ~= "" then hwid = clientId end
        end)
    end
    return hwid and tostring(hwid) or nil
end

local function sendApiRequest(action, payload)
    local reqSuccess, response = pcall(function()
        return Config.REQUEST_FUNC({
            Url     = Config.API_URL .. "/API/route_license.php?act=" .. tostring(action),
            Method  = "POST",
            Headers = Config.HEADERS,
            Body    = HttpService:JSONEncode(payload)
        })
    end)

    if not reqSuccess or not response or not response.Body then
        return false, { message = "Connection error / No response from server." }
    end

    local parseSuccess, parsed = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if parseSuccess and parsed then
        return parsed.success, parsed
    else
        return false, { message = "Invalid JSON response from server." }
    end
end

-- =========================================================
-- CORE LIFECYCLE (SESSION & CLEANUP)
-- =========================================================
local function endSession()
    if not Config.SESSION_TOKEN then return end
    local hwid = getHWID()
    if not hwid then return end

    local success, response = sendApiRequest("session_end", {
        session_token = Config.SESSION_TOKEN,
        hwid_hash     = hwid
    })

    if success then
        debugPrint("Session terminated cleanly.")
    else
        debugWarn("Failed to end session: " .. tostring(response.message))
    end

    Config.SESSION_TOKEN = nil
end

local function destroyHub(reason)
    if not Config.IS_RUNNING and #Connections == 0 and #CleanupObjects == 0 then return end

    debugPrint("Cleaning up... Reason: " .. tostring(reason or "Manual"))
    Config.IS_RUNNING = false

    endSession()

    for name, conn in pairs(Connections) do
        if conn then
            pcall(function() conn:Disconnect() end)
            debugPrint("Disconnected: " .. name)
        end
    end
    table.clear(Connections)

    for name, obj in pairs(CleanupObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
            debugPrint("Destroyed: " .. name)
        end
    end
    table.clear(CleanupObjects)
end

local function startHeartbeatLoop()
    task.spawn(function()
        while Config.IS_RUNNING and Config.SESSION_TOKEN do
            task.wait(Config.HEARTBEAT_INTERVAL)
            if not Config.IS_RUNNING then break end

            local hbSuccess, hbData = sendApiRequest("heartbeat", {
                session_token = Config.SESSION_TOKEN,
                hwid_hash     = getHWID()
            })

            if not hbSuccess then
                local rawMessage = (type(hbData) == "table" and hbData.message) or "Session expired."
                debugWarn("Heartbeat Failed: " .. tostring(rawMessage))
                destroyHub("Heartbeat Failed: " .. tostring(rawMessage))
                LocalPlayer:Kick("[NEX-KICK] Session Ended: " .. tostring(rawMessage))
                break
            else
                debugPrint("Heartbeat OK: " .. tostring((type(hbData) == "table" and hbData.message) or "OK"))
            end
        end
    end)
end

-- =========================================================
-- TOAST SYSTEM
-- =========================================================
local ToastSystem = {
    ActiveToast = nil,
    PRESETS = {
        ["info"]    = { Icon = "ℹ️",  Color = Color3.fromRGB(0, 180, 255),   Title = "INFORMATION" },
        ["success"] = { Icon = "✅",  Color = Color3.fromRGB(0, 235, 145),   Title = "SUCCESS" },
        ["warning"] = { Icon = "⚠️",  Color = Color3.fromRGB(255, 180, 0),   Title = "WARNING" },
        ["error"]   = { Icon = "🔒",  Color = Color3.fromRGB(255, 60, 80),   Title = "ACCESS DENIED" }
    }
}

function ToastSystem.Show(toastType, message, customTitle, displayDuration)
    if type(customTitle) == "number" then
        displayDuration = customTitle
        customTitle = nil
    end
    displayDuration = type(displayDuration) == "number" and displayDuration or 2.5

    local preset    = ToastSystem.PRESETS[string.lower(tostring(toastType))] or ToastSystem.PRESETS["info"]
    local titleText = preset.Title
    if customTitle and type(customTitle) == "string" and customTitle ~= "" then
        titleText = customTitle
    end

    local mainColor = preset.Color
    local iconText  = preset.Icon

    if ToastSystem.ActiveToast then
        pcall(function() ToastSystem.ActiveToast:Destroy() end)
        ToastSystem.ActiveToast = nil
    end

    local mainHub = CoreGui:FindFirstChild("NexovaHub") or playerGui:FindFirstChild("NexovaHub")
    if not mainHub then return end

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Name              = "NexovaToast"
    ToastFrame.AnchorPoint       = Vector2.new(0.5, 0)
    ToastFrame.Position          = UDim2.new(0.5, 0, 0, -65)
    ToastFrame.Size              = UDim2.fromOffset(320, 52)
    ToastFrame.BackgroundColor3  = Color3.fromRGB(8, 15, 30)
    ToastFrame.BorderSizePixel   = 0
    ToastFrame.ClipsDescendants  = true
    ToastFrame.ZIndex            = 999
    ToastFrame.Parent            = mainHub
    ToastSystem.ActiveToast      = ToastFrame

    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 8)

    local ToastStroke       = Instance.new("UIStroke", ToastFrame)
    ToastStroke.Thickness   = 1.5
    ToastStroke.Color       = mainColor

    local IconLabel              = Instance.new("TextLabel", ToastFrame)
    IconLabel.Position           = UDim2.new(0, 12, 0.5, -13)
    IconLabel.Size               = UDim2.fromOffset(24, 24)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text               = iconText
    IconLabel.TextSize           = 16
    IconLabel.Font               = Enum.Font.GothamBold

    local TitleLabel             = Instance.new("TextLabel", ToastFrame)
    TitleLabel.Position          = UDim2.new(0, 42, 0, 8)
    TitleLabel.Size              = UDim2.new(1, -50, 0, 16)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text              = string.upper(tostring(titleText))
    TitleLabel.TextColor3        = mainColor
    TitleLabel.TextSize          = 11
    TitleLabel.Font              = Enum.Font.GothamBold
    TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left

    local MsgLabel               = Instance.new("TextLabel", ToastFrame)
    MsgLabel.Position            = UDim2.new(0, 42, 0, 24)
    MsgLabel.Size                = UDim2.new(1, -50, 0, 18)
    MsgLabel.BackgroundTransparency = 1
    MsgLabel.Text                = tostring(message or "")
    MsgLabel.TextColor3          = Color3.fromRGB(210, 215, 230)
    MsgLabel.TextSize            = 10
    MsgLabel.Font                = Enum.Font.GothamMedium
    MsgLabel.TextXAlignment      = Enum.TextXAlignment.Left
    MsgLabel.TextTruncate        = Enum.TextTruncate.AtEnd

    local ProgressTrack          = Instance.new("Frame", ToastFrame)
    ProgressTrack.Position       = UDim2.new(0, 8, 1, -6)
    ProgressTrack.Size           = UDim2.new(1, -16, 0, 3)
    ProgressTrack.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
    ProgressTrack.BorderSizePixel = 0
    ProgressTrack.ClipsDescendants = true
    Instance.new("UICorner", ProgressTrack).CornerRadius = UDim.new(1, 0)

    local ProgressBar            = Instance.new("Frame", ProgressTrack)
    ProgressBar.Position         = UDim2.new(0, 0, 0, 0)
    ProgressBar.Size             = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = mainColor
    ProgressBar.BorderSizePixel  = 0
    Instance.new("UICorner", ProgressBar).CornerRadius = UDim.new(1, 0)

    playEffect("ToastSFX")

    local tweenIn = TweenService:Create(ToastFrame,
        TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, 0, 0, 20) })
    tweenIn:Play()

    local tweenProgress = TweenService:Create(ProgressBar,
        TweenInfo.new(displayDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { Size = UDim2.new(1, 0, 1, 0) })

    tweenIn.Completed:Connect(function() tweenProgress:Play() end)

    tweenProgress.Completed:Connect(function()
        if ToastSystem.ActiveToast == ToastFrame then
            local tweenOut = TweenService:Create(ToastFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                { Position = UDim2.new(0.5, 0, 0, -65) })
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                if ToastFrame and ToastFrame.Parent then ToastFrame:Destroy() end
                if ToastSystem.ActiveToast == ToastFrame then ToastSystem.ActiveToast = nil end
            end)
        end
    end)
end

-- =========================================================
-- UI & AUTHENTICATION
-- =========================================================
local function loadingScreen()
    local UILoading = {}

    UILoading.Screen = Instance.new("ScreenGui")
    UILoading.Screen.Name           = "NexovaLoadingScreen"
    UILoading.Screen.IgnoreGuiInset = true
    UILoading.Screen.ResetOnSpawn   = false
    UILoading.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    pcall(function() UILoading.Screen.Parent = CoreGui end)
    if not UILoading.Screen.Parent then
        UILoading.Screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    CleanupObjects["LoadingScreen"] = UILoading.Screen

    UILoading.Overlay = Instance.new("Frame", UILoading.Screen)
    UILoading.Overlay.Size               = UDim2.fromScale(1, 1)
    UILoading.Overlay.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
    UILoading.Overlay.BackgroundTransparency = 0.05
    UILoading.Overlay.BorderSizePixel    = 0

    UILoading.Container = Instance.new("Frame", UILoading.Overlay)
    UILoading.Container.Name             = "MainContainer"
    UILoading.Container.AnchorPoint      = Vector2.new(0.5, 0.5)
    UILoading.Container.Position         = UDim2.fromScale(0.5, 0.5)
    UILoading.Container.Size             = UDim2.fromOffset(500, 200)
    UILoading.Container.BackgroundTransparency = 1

    UILoading.Scale = Instance.new("UIScale", UILoading.Container)

    local function updateScale()
        local cam = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
        if not cam then return end
        local screenSize = cam.ViewportSize
        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
            local minDimension = math.min(screenSize.X, screenSize.Y)
            UILoading.Scale.Scale = math.clamp((minDimension * 0.85) / 500, 0.60, 0.90)
        else
            UILoading.Scale.Scale = 1.0
        end
    end

    pcall(function()
        updateScale()
        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            local cam = workspace.CurrentCamera
            if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end
        end)
        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
        end
    end)

    UILoading.Logo = Instance.new("ImageLabel", UILoading.Container)
    UILoading.Logo.AnchorPoint        = Vector2.new(0.5, 0.5)
    UILoading.Logo.Position           = UDim2.new(0, 100, 0, 100)
    UILoading.Logo.Size               = UDim2.fromOffset(140, 140)
    UILoading.Logo.BackgroundTransparency = 1
    UILoading.Logo.Image              = Assets.LOGO_WITHOUT_TEXT
    UILoading.Logo.ImageTransparency  = 1
    UILoading.Logo.ScaleType          = Enum.ScaleType.Fit

    UILoading.Divider = Instance.new("Frame", UILoading.Container)
    UILoading.Divider.AnchorPoint     = Vector2.new(0.5, 0.5)
    UILoading.Divider.Position        = UDim2.new(0, 185, 0, 100)
    UILoading.Divider.Size            = UDim2.fromOffset(2, 150)
    UILoading.Divider.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
    UILoading.Divider.BackgroundTransparency = 1
    UILoading.Divider.BorderSizePixel = 0

    UILoading.Title = Instance.new("ImageLabel", UILoading.Container)
    UILoading.Title.AnchorPoint       = Vector2.new(0, 0.5)
    UILoading.Title.Position          = UDim2.new(0, 205, 0, 45)
    UILoading.Title.Size              = UDim2.fromOffset(220, 55)
    UILoading.Title.BackgroundTransparency = 1
    UILoading.Title.Image             = Assets.LOGO_TEXT
    UILoading.Title.ImageTransparency = 1
    UILoading.Title.ScaleType         = Enum.ScaleType.Fit

    UILoading.TitleScale = Instance.new("UIScale", UILoading.Title)
    UILoading.TitleScale.Scale = 0.80

    UILoading.Status = Instance.new("TextLabel", UILoading.Container)
    UILoading.Status.AnchorPoint      = Vector2.new(0, 0.5)
    UILoading.Status.Position         = UDim2.new(0, 205, 0, 85)
    UILoading.Status.Size             = UDim2.fromOffset(280, 25)
    UILoading.Status.BackgroundTransparency = 1
    UILoading.Status.Text             = "Initializing..."
    UILoading.Status.TextColor3       = Color3.fromRGB(190, 190, 196)
    UILoading.Status.TextTransparency = 1
    UILoading.Status.Font             = Enum.Font.Gotham
    UILoading.Status.TextSize         = 13
    UILoading.Status.TextXAlignment   = Enum.TextXAlignment.Left

    UILoading.StatusScale = Instance.new("UIScale", UILoading.Status)
    UILoading.StatusScale.Scale = 0.80

    UILoading.ProgressBackground = Instance.new("Frame", UILoading.Container)
    UILoading.ProgressBackground.AnchorPoint     = Vector2.new(0, 0.5)
    UILoading.ProgressBackground.Position        = UDim2.new(0, 205, 0, 115)
    UILoading.ProgressBackground.Size            = UDim2.fromOffset(260, 5)
    UILoading.ProgressBackground.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    UILoading.ProgressBackground.BackgroundTransparency = 1
    UILoading.ProgressBackground.BorderSizePixel = 0
    Instance.new("UICorner", UILoading.ProgressBackground).CornerRadius = UDim.new(1, 0)

    UILoading.ProgressScale = Instance.new("UIScale", UILoading.ProgressBackground)
    UILoading.ProgressScale.Scale = 0.80

    UILoading.ProgressBar = Instance.new("Frame", UILoading.ProgressBackground)
    UILoading.ProgressBar.Size              = UDim2.fromScale(0, 1)
    UILoading.ProgressBar.BackgroundColor3  = Color3.fromRGB(0, 120, 220)
    UILoading.ProgressBar.BorderSizePixel   = 0
    Instance.new("UICorner", UILoading.ProgressBar).CornerRadius = UDim.new(1, 0)

    UILoading.ProgressGradient = Instance.new("UIGradient", UILoading.ProgressBar)
    UILoading.ProgressGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 200, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 120, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 60, 180))
    })

    UILoading.Percentage = Instance.new("TextLabel", UILoading.Container)
    UILoading.Percentage.AnchorPoint      = Vector2.new(0, 0.5)
    UILoading.Percentage.Position         = UDim2.new(0, 205, 0, 140)
    UILoading.Percentage.Size             = UDim2.fromOffset(260, 20)
    UILoading.Percentage.BackgroundTransparency = 1
    UILoading.Percentage.Text             = "0%"
    UILoading.Percentage.TextColor3       = Color3.fromRGB(120, 120, 125)
    UILoading.Percentage.TextTransparency = 1
    UILoading.Percentage.Font             = Enum.Font.Gotham
    UILoading.Percentage.TextSize         = 11
    UILoading.Percentage.TextXAlignment   = Enum.TextXAlignment.Left

    UILoading.PercentageScale = Instance.new("UIScale", UILoading.Percentage)
    UILoading.PercentageScale.Scale = 0.80

    local function tween(instance, duration, properties)
        local anim = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
        anim:Play()
        return anim
    end

    tween(UILoading.Logo, 0.5, { ImageTransparency = 0 })
    task.wait(0.6)
    tween(UILoading.Logo, 0.6, { Position = UDim2.new(0, 65, 0, 100) })
    task.wait(0.15)
    tween(UILoading.Divider, 0.25, { BackgroundTransparency = 0 })
    task.wait(0.12)
    tween(UILoading.Title,              0.45, { ImageTransparency = 0 })
    tween(UILoading.TitleScale,         0.45, { Scale = 1 })
    tween(UILoading.Status,             0.45, { TextTransparency = 0 })
    tween(UILoading.StatusScale,        0.45, { Scale = 1 })
    tween(UILoading.ProgressBackground, 0.45, { BackgroundTransparency = 0 })
    tween(UILoading.ProgressScale,      0.45, { Scale = 1 })
    tween(UILoading.Percentage,         0.45, { TextTransparency = 0 })
    tween(UILoading.PercentageScale,    0.45, { Scale = 1 })
    task.wait(0.45)

    return {
        update = function(percent, text)
            UILoading.Status.Text     = text
            UILoading.Percentage.Text = tostring(percent) .. "%"
            tween(UILoading.ProgressBar, 0.4, { Size = UDim2.fromScale(percent / 100, 1) })
        end,
        fail = function(message)
            UILoading.Status.Text     = message
            UILoading.Percentage.Text = "FAILED"
            UILoading.ProgressBar.BackgroundColor3 = Color3.fromRGB(210, 45, 55)
            UILoading.ProgressGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 90, 90)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 45, 55)),
                ColorSequenceKeypoint.new(1,   Color3.fromRGB(150, 20, 30))
            })
        end,
        close = function()
            tween(UILoading.Logo,               0.4, { ImageTransparency = 1 })
            tween(UILoading.Divider,            0.2, { BackgroundTransparency = 1 })
            tween(UILoading.Title,              0.4, { ImageTransparency = 1 })
            tween(UILoading.Status,             0.2, { TextTransparency = 1 })
            tween(UILoading.ProgressBar,        0.1, { BackgroundTransparency = 1 })
            tween(UILoading.ProgressBackground, 0.1, { BackgroundTransparency = 1 })
            tween(UILoading.Percentage,         0.2, { TextTransparency = 1 })
            tween(UILoading.Overlay,            0.4, { BackgroundTransparency = 1 })
            task.wait(0.45)
            CleanupObjects["LoadingScreen"] = nil
            UILoading.Screen:Destroy()
        end
    }
end

local function authenticateUser()
    if not Config.REQUEST_FUNC then
        LocalPlayer:Kick("[NEX-KICK] Executor HTTP not supported!")
        return false
    end

    local loader = loadingScreen()
    loader.update(10, "Checking Device...")

    local hwid = getHWID()
    if not hwid then
        loader.fail("HWID Error")
        task.wait(1.5)
        LocalPlayer:Kick("[NEX-KICK] Failed to detect HWID.")
        return false
    end

    if Config.LICENSE_KEY == "" then
        loader.fail("No License")
        task.wait(1.5)
        LocalPlayer:Kick("[NEX-KICK] License key is empty!")
        return false
    end

    local authPayload = {
        license_key     = Config.LICENSE_KEY,
        product_code    = Config.PRODUCT_CODE,
        place_id        = game.PlaceId,
        roblox_id       = LocalPlayer.UserId,
        roblox_username = LocalPlayer.Name,
        hwid_hash       = hwid
    }

    loader.update(40, "Verifying License...")
    local vSuccess, vData = sendApiRequest("verify", authPayload)
    if not vSuccess then
        loader.fail("Invalid License")
        task.wait(1.5)
        if type(vData) == "table" and vData.code == "max_devices_reached" then
            LocalPlayer:Kick("[NEX-KICK] Device Limit! Reset HWID via Discord Bot.")
        else
            local errMessage = (type(vData) == "table" and vData.message) or "Invalid/expired key."
            LocalPlayer:Kick("[NEX-KICK] Verify Failed: " .. tostring(errMessage))
        end
        return false
    end

    pcall(function()
        local licInfo = type(vData) == "table" and vData.data and (vData.data.license or vData.data)
        if licInfo then
            AuthState.status_license = tostring(licInfo.status or licInfo.status_license or "active")
            AuthState.key            = tostring(licInfo.license_key or Config.LICENSE_KEY)
            AuthState.plan_license   = tostring(licInfo.plan_code or licInfo.plan or "N/A")
            AuthState.max_devices    = licInfo.max_devices or 1
            local exp = licInfo.expired_at or licInfo.expires
            if not exp or exp == "" or tostring(exp) == "nil" then
                AuthState.expired_at = "Lifetime"
            else
                AuthState.expired_at = tostring(exp)
            end
        end
    end)

    loader.update(80, "Creating Session...")
    local sessSuccess, sessData = sendApiRequest("session_start", authPayload)
    if not sessSuccess or type(sessData) ~= "table" or not sessData.data or not sessData.data.session_token then
        loader.fail("Session Failed")
        task.wait(1.5)
        local errMessage = (type(sessData) == "table" and sessData.message) or "Active on another device."
        LocalPlayer:Kick("[NEX-KICK] Session Failed: " .. tostring(errMessage))
        return false
    end

    Config.SESSION_TOKEN = sessData.data.session_token
    Config.IS_RUNNING    = true

    loader.update(100, "Authentication Successful!")
    task.wait(0.5)
    loader.close()

    startHeartbeatLoop()
    return true
end

-- =========================================================
-- AUTO END SESSION ON CLIENT LEAVE
-- =========================================================
Connections["PlayerLeave"] = LocalPlayer.AncestryChanged:Connect(function(_, parent)
    destroyHub("Player Close The Game")
end)

-- =========================================================
-- MAIN HUB
-- =========================================================
local function mainScreen()
    if CoreGui:FindFirstChild("NexovaHub") then CoreGui.NexovaHub:Destroy() end
    if playerGui and playerGui:FindFirstChild("NexovaHub") then playerGui.NexovaHub:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "NexovaHub"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local success = pcall(function() ScreenGui.Parent = CoreGui end)
    if not success or not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    CleanupObjects["MainHub"] = ScreenGui

    local BlackFrame = Instance.new("Frame")
    BlackFrame.Name             = "BlackFrame"
    BlackFrame.Size             = UDim2.fromScale(1, 1)
    BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BlackFrame.BorderSizePixel  = 0
    BlackFrame.ZIndex           = 1
    BlackFrame.Visible          = false
    BlackFrame.Parent           = ScreenGui

    local BlackText = Instance.new("TextLabel")
    BlackText.AnchorPoint        = Vector2.new(0.5, 0.5)
    BlackText.Position           = UDim2.fromScale(0.5, 0.15)
    BlackText.Size               = UDim2.fromOffset(400, 30)
    BlackText.BackgroundTransparency = 1
    BlackText.Text               = "NEXOVA HUB // ANTI-RENDER MODE ACTIVE"
    BlackText.TextColor3         = Color3.fromRGB(0, 180, 255)
    BlackText.TextSize           = 12
    BlackText.Font               = Enum.Font.GothamMedium
    BlackText.Parent             = BlackFrame

    local MainFrame = Instance.new("Frame")
    MainFrame.Name             = "MainFrame"
    MainFrame.AnchorPoint      = Vector2.new(0.5, 0.5)
    MainFrame.Position         = UDim2.fromScale(0.5, 0.5)
    MainFrame.Size             = UDim2.fromOffset(700, 500)
    MainFrame.BackgroundColor3 = Color3.fromRGB(5, 9, 20)
    MainFrame.BorderSizePixel  = 0
    MainFrame.Visible          = false
    MainFrame.ZIndex           = 10
    MainFrame.Parent           = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    local MainFrameStroke     = Instance.new("UIStroke", MainFrame)
    MainFrameStroke.Color       = Color3.fromRGB(0, 180, 255)
    MainFrameStroke.Transparency = 0.25
    MainFrameStroke.Thickness   = 1

    local MainFrameGradient   = Instance.new("UIGradient", MainFrameStroke)
    MainFrameGradient.Color     = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 180, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 110, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(235, 40, 255))
    })

    local MainFrameScale = Instance.new("UIScale")

    local function updateScale()
        local cam = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
        if not cam then return end
        local screenSize = cam.ViewportSize
        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
            local minDimension = math.min(screenSize.X, screenSize.Y)
            MainFrameScale.Scale = math.clamp((minDimension * 0.85) / 700, 0.60, 0.80)
        else
            MainFrameScale.Scale = 1.0
        end
    end

    pcall(function()
        updateScale()
        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            local cam = workspace.CurrentCamera
            if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end
        end)
        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
        end
    end)

    MainFrameScale.Parent = MainFrame

    local Window      = MainFrame
    local WindowScale = MainFrameScale

    local MinimizedIcon = Instance.new("ImageButton")
    MinimizedIcon.Name             = "MinimizedIcon"
    MinimizedIcon.AnchorPoint      = Vector2.new(0.5, 0.5)
    MinimizedIcon.Position         = UDim2.new(0.5, 0, 0, 60)
    MinimizedIcon.Size             = UDim2.fromOffset(50, 50)
    MinimizedIcon.BackgroundColor3 = Color3.fromRGB(8, 15, 30)
    MinimizedIcon.BorderSizePixel  = 0
    MinimizedIcon.AutoButtonColor  = false
    MinimizedIcon.Image            = Assets.LOGO_WITHOUT_TEXT
    MinimizedIcon.ScaleType        = Enum.ScaleType.Fit
    MinimizedIcon.Visible          = false
    MinimizedIcon.Draggable        = true
    MinimizedIcon.Parent           = ScreenGui

    Instance.new("UICorner", MinimizedIcon).CornerRadius = UDim.new(0, 14)

    local MinimizedStroke       = Instance.new("UIStroke", MinimizedIcon)
    MinimizedStroke.Color         = Color3.fromRGB(0, 180, 255)
    MinimizedStroke.Transparency  = 0.15
    MinimizedStroke.Thickness     = 1

    local Sidebar = Instance.new("Frame")
    Sidebar.Name             = "Sidebar"
    Sidebar.Size             = UDim2.new(0, 190, 1, 0)
    Sidebar.BackgroundColor3 = Color3.fromRGB(7, 13, 27)
    Sidebar.BorderSizePixel  = 0
    Sidebar.Parent           = MainFrame

    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

    local SidebarCover = Instance.new("Frame")
    SidebarCover.Size             = UDim2.new(0, 20, 1, 0)
    SidebarCover.Position         = UDim2.new(1, -20, 0, 0)
    SidebarCover.BackgroundColor3 = Color3.fromRGB(7, 13, 27)
    SidebarCover.BorderSizePixel  = 0
    SidebarCover.Parent           = Sidebar

    local Logo = Instance.new("ImageLabel")
    Logo.AnchorPoint        = Vector2.new(0.5, 0)
    Logo.Position           = UDim2.new(0.5, 0, 0, 25)
    Logo.Size               = UDim2.fromOffset(190, 85)
    Logo.BackgroundTransparency = 1
    Logo.Image              = Assets.LOGO_FULL
    Logo.ScaleType          = Enum.ScaleType.Fit
    Logo.Parent             = Sidebar

    local Navigation = Instance.new("Frame")
    Navigation.Name             = "Navigation"
    Navigation.Position         = UDim2.new(0, 18, 0, 125)
    Navigation.Size             = UDim2.new(1, -36, 0, 320)
    Navigation.BackgroundTransparency = 1
    Navigation.Parent           = Sidebar

    local NavigationLayout = Instance.new("UIListLayout", Navigation)
    NavigationLayout.Padding    = UDim.new(0, 5)
    NavigationLayout.SortOrder  = Enum.SortOrder.LayoutOrder

    local navButtons = {}

    local function createNavButton(name, text, icon)
        local Button = Instance.new("TextButton")
        Button.Name               = name
        Button.Size               = UDim2.new(1, 0, 0, 35)
        Button.BackgroundColor3   = Color3.fromRGB(7, 13, 27)
        Button.BackgroundTransparency = 1
        Button.BorderSizePixel    = 0
        Button.AutoButtonColor    = false
        Button.Text               = ""
        Button.Parent             = Navigation

        Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

        local Icon = Instance.new("TextLabel", Button)
        Icon.Position          = UDim2.new(0, 14, 0, 0)
        Icon.Size              = UDim2.fromOffset(30, 35)
        Icon.BackgroundTransparency = 1
        Icon.Text              = icon
        Icon.TextColor3        = Color3.fromRGB(125, 135, 160)
        Icon.TextSize          = 15
        Icon.Font              = Enum.Font.GothamBold
        Icon.TextXAlignment    = Enum.TextXAlignment.Center
        Icon.TextYAlignment    = Enum.TextYAlignment.Center

        local Label = Instance.new("TextLabel", Button)
        Label.Position         = UDim2.new(0, 58, 0, 0)
        Label.Size             = UDim2.new(1, -65, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text             = text
        Label.TextColor3       = Color3.fromRGB(195, 202, 220)
        Label.TextSize         = 12
        Label.Font             = Enum.Font.GothamMedium
        Label.TextXAlignment   = Enum.TextXAlignment.Left

        navButtons[name] = { button = Button, icon = Icon, label = Label }
        return Button
    end

    createNavButton("Home",    "HOME",    "🏠")
    createNavButton("Barista", "BARISTA", "🔥")

    local DiscordButton = Instance.new("TextButton")
    DiscordButton.Name              = "Discord"
    DiscordButton.AnchorPoint       = Vector2.new(0.5, 1)
    DiscordButton.Position          = UDim2.new(0.5, 0, 1, -18)
    DiscordButton.Size              = UDim2.new(1, -36, 0, 30)
    DiscordButton.BackgroundColor3  = Color3.fromRGB(10, 28, 65)
    DiscordButton.BackgroundTransparency = 0.15
    DiscordButton.BorderSizePixel   = 0
    DiscordButton.AutoButtonColor   = false
    DiscordButton.Text              = "💾   DISCORD"
    DiscordButton.TextColor3        = Color3.fromRGB(235, 240, 250)
    DiscordButton.TextSize          = 11
    DiscordButton.Font              = Enum.Font.GothamBold
    DiscordButton.Parent            = Sidebar

    Instance.new("UICorner", DiscordButton).CornerRadius = UDim.new(0, 8)

    local DiscordStroke       = Instance.new("UIStroke", DiscordButton)
    DiscordStroke.Color         = Color3.fromRGB(175, 50, 255)
    DiscordStroke.Transparency  = 0.25

    local Content = Instance.new("Frame")
    Content.Name             = "Content"
    Content.Position         = UDim2.new(0, 190, 0, 0)
    Content.Size             = UDim2.new(1, -190, 1, 0)
    Content.BackgroundTransparency = 1
    Content.Parent           = MainFrame

    local function createCard(parent, name, position, size)
        local Card = Instance.new("Frame")
        Card.Name             = name
        Card.Position         = position
        Card.Size             = size
        Card.BackgroundColor3 = Color3.fromRGB(8, 15, 30)
        Card.BorderSizePixel  = 0
        Card.Parent           = parent

        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 10)

        local Stroke       = Instance.new("UIStroke", Card)
        Stroke.Color         = Color3.fromRGB(25, 42, 68)
        Stroke.Transparency  = 0.15
        Stroke.Thickness     = 1

        return Card
    end

    local function createCardTitle(parent, icon, text, color)
        local Icon = Instance.new("TextLabel", parent)
        Icon.Position          = UDim2.new(0, 16, 0, 16)
        Icon.Size              = UDim2.fromOffset(22, 22)
        Icon.BackgroundTransparency = 1
        Icon.Text              = icon
        Icon.TextColor3        = color
        Icon.TextSize          = 18
        Icon.Font              = Enum.Font.GothamBold
        Icon.TextYAlignment    = Enum.TextYAlignment.Center

        local Title = Instance.new("TextLabel", parent)
        Title.Position         = UDim2.new(0, 45, 0, 10)
        Title.Size             = UDim2.new(1, -58, 0, 35)
        Title.BackgroundTransparency = 1
        Title.Text             = text
        Title.TextColor3       = Color3.fromRGB(235, 240, 250)
        Title.TextSize         = 14
        Title.Font             = Enum.Font.GothamMedium
        Title.TextXAlignment   = Enum.TextXAlignment.Left
        Title.TextYAlignment   = Enum.TextYAlignment.Center
    end

    -- TOPBAR
    local TopBar = Instance.new("Frame")
    TopBar.Name             = "TopBar"
    TopBar.Size             = UDim2.new(1, 0, 0, 60)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent           = Content

    local PlanBadge = Instance.new("Frame", TopBar)
    PlanBadge.Position         = UDim2.new(0, 25, 0.5, -12)
    PlanBadge.Size             = UDim2.fromOffset(110, 24)
    PlanBadge.BackgroundColor3 = Color3.fromRGB(12, 22, 45)
    PlanBadge.BorderSizePixel  = 0
    Instance.new("UICorner", PlanBadge).CornerRadius = UDim.new(0, 6)

    local PlanBadgeText = Instance.new("TextLabel", PlanBadge)
    PlanBadgeText.Size               = UDim2.fromScale(1, 1)
    PlanBadgeText.BackgroundTransparency = 1
    PlanBadgeText.Text               = "👑 " .. tostring(AuthState.plan_license or "N/A")
    PlanBadgeText.TextColor3         = Color3.fromRGB(180, 220, 255)
    PlanBadgeText.TextSize           = 10
    PlanBadgeText.Font               = Enum.Font.GothamBold

    local MarqueeContainer = Instance.new("Frame", TopBar)
    MarqueeContainer.Position         = UDim2.new(0, 145, 0.5, -15)
    MarqueeContainer.Size             = UDim2.new(1, -240, 0, 30)
    MarqueeContainer.BackgroundTransparency = 1
    MarqueeContainer.ClipsDescendants = true

    local MarqueeLabel = Instance.new("TextLabel", MarqueeContainer)
    MarqueeLabel.Position         = UDim2.new(1, 0, 0, 0)
    MarqueeLabel.Size             = UDim2.new(0, 0, 1, 0)
    MarqueeLabel.AutomaticSize    = Enum.AutomaticSize.X
    MarqueeLabel.BackgroundTransparency = 1
    MarqueeLabel.Text             = "✨ Welcome to NEXOVA HUB! Thank you for purchasing and using products from Nexova! Unleash Your Power! ✨"
    MarqueeLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
    MarqueeLabel.TextSize         = 12.5
    MarqueeLabel.Font             = Enum.Font.GothamBold
    MarqueeLabel.TextXAlignment   = Enum.TextXAlignment.Left
    MarqueeLabel.TextYAlignment   = Enum.TextYAlignment.Center

    local TextGradient = Instance.new("UIGradient", MarqueeLabel)
    TextGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(0, 235, 145)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 180, 255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(235, 40, 255)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(0, 235, 145))
    })
    TextGradient.Offset = Vector2.new(-1, 0)

    task.spawn(function()
        task.wait(0.1)
        local textWidth = MarqueeLabel.TextBounds.X
        while MarqueeLabel and MarqueeLabel.Parent do
            MarqueeLabel.Position = UDim2.new(1, 0, 0, 0)
            local tween = TweenService:Create(MarqueeLabel,
                TweenInfo.new(14, Enum.EasingStyle.Linear),
                { Position = UDim2.new(0, -textWidth, 0, 0) })
            tween:Play()
            tween.Completed:Wait()
        end
    end)

    task.spawn(function()
        TweenService:Create(TextGradient,
            TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            { Offset = Vector2.new(1, 0) }):Play()
    end)

    local function createWindowButton(name, text, position)
        local Button = Instance.new("TextButton")
        Button.Name              = name
        Button.Position          = position
        Button.Size              = UDim2.fromOffset(30, 30)
        Button.BackgroundColor3  = Color3.fromRGB(8, 15, 30)
        Button.BackgroundTransparency = 0.2
        Button.BorderSizePixel   = 0
        Button.AutoButtonColor   = false
        Button.Text              = text
        Button.TextColor3        = Color3.fromRGB(235, 240, 250)
        Button.TextSize          = 20
        Button.Font              = Enum.Font.Gotham
        Button.Parent            = TopBar
        Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)
        local Stroke = Instance.new("UIStroke", Button)
        Stroke.Color       = Color3.fromRGB(30, 45, 70)
        Stroke.Transparency = 0.3
        return Button
    end

    local MinimizeButton = createWindowButton("Minimize", "-",  UDim2.new(1, -86, 0.5, -15))
    local CloseButton    = createWindowButton("Close",    "×", UDim2.new(1, -50, 0.5, -15))
    CloseButton.TextColor3 = Color3.fromRGB(235, 40, 255)

    local TopBarDivider = Instance.new("Frame", TopBar)
    TopBarDivider.Position         = UDim2.new(0, 25, 1, -5)
    TopBarDivider.Size             = UDim2.new(1, -50, 0, 1)
    TopBarDivider.BackgroundColor3 = Color3.fromRGB(30, 45, 75)
    TopBarDivider.BorderSizePixel  = 0

    local DividerGradient = Instance.new("UIGradient", TopBarDivider)
    DividerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.8),
        NumberSequenceKeypoint.new(0.2, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1,   0.8)
    })

    local Body = Instance.new("Frame")
    Body.Name             = "Body"
    Body.Position         = UDim2.new(0, 25, 0, 70)
    Body.Size             = UDim2.new(1, -50, 1, -85)
    Body.BackgroundTransparency = 1
    Body.Parent           = Content

    -- HOME PAGE
    local HomePage = Instance.new("Frame")
    HomePage.Name             = "HomePage"
    HomePage.Size             = UDim2.fromScale(1, 1)
    HomePage.BackgroundTransparency = 1
    HomePage.Visible          = true
    HomePage.Parent           = Body

    local ProfileCard = createCard(HomePage, "Profile", UDim2.new(0, 0, 0, 0), UDim2.new(0, 223, 0, 190))
    createCardTitle(ProfileCard, "👤", "PROFILE", Color3.fromRGB(0, 180, 255))

    local Avatar = Instance.new("ImageLabel")
    Avatar.Position          = UDim2.new(0, 14, 0, 50)
    Avatar.Size              = UDim2.fromOffset(100, 100)
    Avatar.BackgroundColor3  = Color3.fromRGB(15, 22, 38)
    Avatar.BorderSizePixel   = 0
    Avatar.Parent            = ProfileCard
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)

    local AvatarStroke      = Instance.new("UIStroke", Avatar)
    AvatarStroke.Color        = Color3.fromRGB(0, 180, 255)
    AvatarStroke.Transparency = 0.25

    pcall(function()
        local image = Players:GetUserThumbnailAsync(LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
        Avatar.Image = image
    end)

    local function profileRow(parent, y, label, value)
        local Label = Instance.new("TextLabel", parent)
        Label.Position         = UDim2.new(0, 130, 0, y)
        Label.Size             = UDim2.new(1, -130, 0, 15)
        Label.BackgroundTransparency = 1
        Label.Text             = label
        Label.TextColor3       = Color3.fromRGB(125, 135, 160)
        Label.TextSize         = 10
        Label.Font             = Enum.Font.Gotham
        Label.TextXAlignment   = Enum.TextXAlignment.Left
        Label.TextYAlignment   = Enum.TextYAlignment.Center

        local Value = Instance.new("TextLabel", parent)
        Value.Position         = UDim2.new(0, 130, 0, y + 13)
        Value.Size             = UDim2.new(1, -130, 0, 17)
        Value.BackgroundTransparency = 1
        Value.Text             = value
        Value.TextColor3       = Color3.fromRGB(235, 240, 250)
        Value.TextSize         = 11.5
        Value.Font             = Enum.Font.GothamMedium
        Value.TextXAlignment   = Enum.TextXAlignment.Left
        Value.TextYAlignment   = Enum.TextYAlignment.Center
        Value.TextTruncate     = Enum.TextTruncate.AtEnd
        return Value
    end

    profileRow(ProfileCard, 50,  "Username",     LocalPlayer.Name)
    profileRow(ProfileCard, 90,  "Display Name", LocalPlayer.DisplayName)
    profileRow(ProfileCard, 130, "User ID",      tostring(LocalPlayer.UserId))

    local AvatarOnline = Instance.new("Frame")
    AvatarOnline.AnchorPoint      = Vector2.new(1, 1)
    AvatarOnline.Position         = UDim2.new(0, 114, 0, 150)
    AvatarOnline.Size             = UDim2.fromOffset(13, 13)
    AvatarOnline.BackgroundColor3 = Color3.fromRGB(0, 235, 145)
    AvatarOnline.BorderSizePixel  = 0
    AvatarOnline.Parent           = ProfileCard
    Instance.new("UICorner", AvatarOnline).CornerRadius = UDim.new(1, 0)

    local LicenseCard = createCard(HomePage, "License", UDim2.new(0, 237, 0, 0), UDim2.new(0, 223, 0, 190))
    createCardTitle(LicenseCard, "🔒", "LICENSE", Color3.fromRGB(175, 50, 255))

    local function maskLicense(key)
        if not key or key == "" then return "N/A" end
        if #key <= 8 then return key end
        return string.sub(key, 1, 4) .. "-XXXX-XXXX-" .. string.sub(key, -4)
    end

    local function licenseRow(y, label, value, valueColor)
        local Label = Instance.new("TextLabel", LicenseCard)
        Label.Position         = UDim2.new(0, 14, 0, y)
        Label.Size             = UDim2.fromOffset(70, 22)
        Label.BackgroundTransparency = 1
        Label.Text             = label
        Label.TextColor3       = Color3.fromRGB(125, 135, 160)
        Label.TextSize         = 11
        Label.Font             = Enum.Font.Gotham
        Label.TextXAlignment   = Enum.TextXAlignment.Left
        Label.TextYAlignment   = Enum.TextYAlignment.Center

        local Value = Instance.new("TextLabel", LicenseCard)
        Value.Position         = UDim2.new(0, 80, 0, y)
        Value.Size             = UDim2.new(1, -94, 0, 22)
        Value.BackgroundTransparency = 1
        Value.Text             = value
        Value.TextColor3       = valueColor or Color3.fromRGB(235, 240, 250)
        Value.TextSize         = 11.5
        Value.Font             = Enum.Font.GothamMedium
        Value.TextXAlignment   = Enum.TextXAlignment.Right
        Value.TextYAlignment   = Enum.TextYAlignment.Center
        Value.TextTruncate     = Enum.TextTruncate.AtEnd
        return Value
    end

    local LicenseStatus = tostring(AuthState.status_license or "unknown")
    local LicenseStatusText = LicenseStatus
    if LicenseStatus == "active"  then LicenseStatusText = "✓ Active"
    elseif LicenseStatus == "expired" then LicenseStatusText = "✕ Expired"
    elseif LicenseStatus == "revoked" then LicenseStatusText = "✕ Revoked" end

    local LicenseStatusColor = (LicenseStatus == "active")
        and Color3.fromRGB(0, 235, 145) or Color3.fromRGB(255, 80, 90)

    local expiresText = (AuthState.expired_at == "Lifetime") and "Lifetime" or tostring(AuthState.expired_at or "N/A")

    licenseRow(42,  "Status",      LicenseStatusText, LicenseStatusColor)
    licenseRow(68,  "Product",     tostring(Config.PRODUCT_CODE), Color3.fromRGB(180, 210, 255))
    licenseRow(94,  "License Key", maskLicense(AuthState.key))
    licenseRow(120, "Plan",        tostring(AuthState.plan_license or "N/A"))
    licenseRow(146, "Expires",     expiresText)

    local function createHomeMetricCard(name, position, size, icon, title, initialVal, accentColor, hasGradient)
        local Card = createCard(HomePage, name, position, size)
        createCardTitle(Card, icon, title, accentColor)

        local ValueLabel = Instance.new("TextLabel", Card)
        ValueLabel.Position         = UDim2.new(0, 14, 0, 48)
        ValueLabel.Size             = UDim2.new(1, -28, 0, 25)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text             = initialVal
        ValueLabel.TextColor3       = Color3.fromRGB(235, 240, 250)
        ValueLabel.TextSize         = 14
        ValueLabel.Font             = Enum.Font.GothamMedium
        ValueLabel.TextXAlignment   = Enum.TextXAlignment.Left

        local Line = Instance.new("Frame", Card)
        Line.Position         = UDim2.new(0, 14, 1, -16)
        Line.Size             = UDim2.new(1, -28, 0, 3)
        Line.BackgroundColor3 = Color3.fromRGB(30, 40, 65)
        Line.BorderSizePixel  = 0
        Line.ClipsDescendants = true
        Instance.new("UICorner", Line).CornerRadius = UDim.new(1, 0)

        local FillBar = nil
        if not hasGradient then
            FillBar = Instance.new("Frame", Line)
            FillBar.Position         = UDim2.new(0, 0, 0, 0)
            FillBar.Size             = UDim2.new(0, 0, 1, 0)
            FillBar.BackgroundColor3 = accentColor
            FillBar.BorderSizePixel  = 0
            Instance.new("UICorner", FillBar).CornerRadius = UDim.new(1, 0)
        else
            local Gradient = Instance.new("UIGradient", Line)
            Gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(175, 50, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 40, 255))
            })
        end

        return ValueLabel, FillBar
    end

    local SessionTime           = createHomeMetricCard("Session", UDim2.new(0, 0,   0, 204), UDim2.new(0, 144, 0, 100), "⏳", "SESSION", "00:00:00", Color3.fromRGB(175, 50, 255), true)
    local FPSValue,   FPSFill  = createHomeMetricCard("FPS",     UDim2.new(0, 158, 0, 204), UDim2.new(0, 144, 0, 100), "💻", "FPS",     "0 FPS",    Color3.fromRGB(0, 180, 255),  false)
    local PingValue,  PingFill = createHomeMetricCard("Ping",    UDim2.new(0, 316, 0, 204), UDim2.new(0, 144, 0, 100), "📶", "PING",    "0 MS",     Color3.fromRGB(0, 235, 145),  false)
    if PingFill then PingFill.Size = UDim2.fromScale(0.85, 1) end

    local sessionStartTick = tick()
    local countedFrames    = 0
    local timerTick        = tick()

    Connections["FPS_RenderStepped"] = RunService.RenderStepped:Connect(function()
        countedFrames = (tonumber(countedFrames) or 0) + 1
    end)

    task.spawn(function()
        while task.wait(0.5) do
            local nowTick  = tick()
            local diffTime = nowTick - timerTick

            local elapsedSec = math.floor(nowTick - sessionStartTick)
            if SessionTime then
                SessionTime.Text = string.format("%02d:%02d:%02d",
                    math.floor(elapsedSec / 3600),
                    math.floor((elapsedSec % 3600) / 60),
                    elapsedSec % 60)
            end

            if diffTime > 0 then
                local currentFps  = math.floor(((tonumber(countedFrames) or 0) / diffTime) + 0.5)
                timerTick         = nowTick
                countedFrames     = 0
                local maxBarWidth = 116

                pcall(function()
                    if FPSValue then FPSValue.Text = currentFps .. " FPS" end
                    if FPSFill  then
                        FPSFill.Size = UDim2.new(0, math.floor(maxBarWidth * math.clamp(currentFps / 240, 0.05, 1)), 0, 3)
                    end
                end)

                pcall(function()
                    local stats      = game:GetService("Stats")
                    local pingItem   = stats and stats.Network
                        and stats.Network.ServerStatsItem
                        and stats.Network.ServerStatsItem:FindFirstChild("Data Ping")

                    if pingItem then
                        local pVal = math.floor(pingItem:GetValue())
                        if PingValue then PingValue.Text = pVal .. " MS" end
                        if PingFill  then
                            PingFill.Size = UDim2.new(0, math.floor(maxBarWidth * math.clamp(1 - (pVal / 500), 0.05, 1)), 0, 3)
                        end
                    else
                        if PingValue then PingValue.Text = "65 MS" end
                        if PingFill  then PingFill.Size = UDim2.new(0, math.floor(maxBarWidth * 0.8), 0, 3) end
                    end
                end)
            end
        end
    end)

    -- BARISTA PAGE
    local BaristaPage = Instance.new("Frame")
    BaristaPage.Name             = "BaristaPage"
    BaristaPage.Size             = UDim2.fromScale(1, 1)
    BaristaPage.BackgroundTransparency = 1
    BaristaPage.Visible          = false
    BaristaPage.Parent           = Body

    local function createAutoBaristaMetricCard(name, position, size, icon, title, initialText, accentColor, isGradient)
        local Card = createCard(BaristaPage, name, position, size)
        createCardTitle(Card, icon, title, accentColor)

        local ValueLabel = Instance.new("TextLabel", Card)
        ValueLabel.Name             = "ValueLabel"
        ValueLabel.Position         = UDim2.new(0, 14, 0, 48)
        ValueLabel.Size             = UDim2.new(1, -28, 0, 25)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text             = initialText
        ValueLabel.TextColor3       = Color3.fromRGB(235, 240, 250)
        ValueLabel.TextSize         = 14
        ValueLabel.Font             = Enum.Font.GothamMedium
        ValueLabel.TextXAlignment   = Enum.TextXAlignment.Left
        ValueLabel.TextTruncate     = Enum.TextTruncate.AtEnd

        local Line = Instance.new("Frame", Card)
        Line.Position         = UDim2.new(0, 14, 1, -16)
        Line.Size             = UDim2.new(1, -28, 0, 3)
        Line.BackgroundColor3 = accentColor
        Line.BorderSizePixel  = 0
        Instance.new("UICorner", Line).CornerRadius = UDim.new(1, 0)

        if isGradient then
            Line.BackgroundColor3 = Color3.fromRGB(30, 20, 55)
            local Gradient = Instance.new("UIGradient", Line)
            Gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(175, 50, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 40, 255))
            })
        end

        return ValueLabel
    end

    local BaristaStatusValue  = createAutoBaristaMetricCard("BaristaStatusCard",  UDim2.new(0, 0,   0, 0), UDim2.new(0, 144, 0, 110), "⚙️", "STATUS",  "● STOPPED",  Color3.fromRGB(255, 80, 90),  false)
    local BaristaOrdersValue  = createAutoBaristaMetricCard("BaristaOrdersCard",  UDim2.new(0, 158, 0, 0), UDim2.new(0, 144, 0, 110), "☕", "ORDERS",  "0",           Color3.fromRGB(175, 50, 255), true)
    local BaristaElapsedValue = createAutoBaristaMetricCard("BaristaElapsedCard", UDim2.new(0, 316, 0, 0), UDim2.new(0, 144, 0, 110), "⏳", "ELAPSED", "00:00:00",   Color3.fromRGB(175, 50, 255), true)

    local AutoBaristaProgressCard = createCard(BaristaPage, "AutoBaristaProgressCard", UDim2.new(0, 0, 0, 126), UDim2.new(0, 144, 0, 104))
    createCardTitle(AutoBaristaProgressCard, "📊", "STATUS INFO", Color3.fromRGB(175, 50, 255))

    local AutoBaristaStatusProgress = Instance.new("TextLabel", AutoBaristaProgressCard)
    AutoBaristaStatusProgress.Position         = UDim2.new(0, 8, 0, 48)
    AutoBaristaStatusProgress.Size             = UDim2.new(1, -16, 0, 42)
    AutoBaristaStatusProgress.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
    AutoBaristaStatusProgress.BackgroundTransparency = 0.5
    AutoBaristaStatusProgress.BorderSizePixel  = 0
    AutoBaristaStatusProgress.Text             = "Status: Idle / Waiting to start..."
    AutoBaristaStatusProgress.TextColor3       = Color3.fromRGB(200, 210, 230)
    AutoBaristaStatusProgress.TextSize         = 11
    AutoBaristaStatusProgress.Font             = Enum.Font.Gotham
    AutoBaristaStatusProgress.TextWrapped      = true
    Instance.new("UICorner", AutoBaristaStatusProgress).CornerRadius = UDim.new(0, 6)
    local ProgressStroke      = Instance.new("UIStroke", AutoBaristaStatusProgress)
    ProgressStroke.Color        = Color3.fromRGB(175, 50, 255)
    ProgressStroke.Transparency = 0.5

    local BaristaMenuValue    = createAutoBaristaMetricCard("BaristaMenuCard",    UDim2.new(0, 158, 0, 126), UDim2.new(0, 144, 0, 104), "📋", "MENU",    "-", Color3.fromRGB(0, 200, 255), false)
    local BaristaFlavourValue = createAutoBaristaMetricCard("BaristaFlavourCard", UDim2.new(0, 316, 0, 126), UDim2.new(0, 144, 0, 104), "🧪", "FLAVOUR", "-", Color3.fromRGB(0, 200, 255), false)

    local BaristaControlCard = createCard(BaristaPage, "BaristaControlCard", UDim2.new(0, 0, 0, 248), UDim2.new(0, 460, 0, 104))
    createCardTitle(BaristaControlCard, "☕", "AUTO BARISTA CONTROL", Color3.fromRGB(175, 50, 255))

    local BaristaStartButton = Instance.new("TextButton")
    BaristaStartButton.Position          = UDim2.new(0, 14, 0, 50)
    BaristaStartButton.Size              = UDim2.new(1, -28, 0, 36)
    BaristaStartButton.BackgroundColor3  = Color3.fromRGB(10, 28, 65)
    BaristaStartButton.BorderSizePixel   = 0
    BaristaStartButton.Text              = "START AUTO BARISTA"
    BaristaStartButton.TextColor3        = Color3.fromRGB(235, 240, 250)
    BaristaStartButton.TextSize          = 12
    BaristaStartButton.Font              = Enum.Font.GothamMedium
    BaristaStartButton.AutoButtonColor   = false
    BaristaStartButton.Parent            = BaristaControlCard
    Instance.new("UICorner", BaristaStartButton).CornerRadius = UDim.new(0, 6)
    local StartStroke       = Instance.new("UIStroke", BaristaStartButton)
    StartStroke.Color         = Color3.fromRGB(0, 180, 255)
    StartStroke.Transparency  = 0.35

    -- AUTO BARISTA LOGIC
    local autoBarista           = false
    local startTime             = 0
    local ordersCompletedCount  = 0
    local BaristaMenu           = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BaristaMenu"))
    local currentOrder          = nil

    local function firePrompt(prompt)
        if not (prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled) then return end
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration or 0.5)
                prompt:InputHoldEnd()
            end
        end)
    end

    local function smartTeleportTo(destination)
        local Character = LocalPlayer.Character
        local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart  = Character and Character:FindFirstChild("HumanoidRootPart")
        local targetCFrame = nil

        if typeof(destination) == "CFrame" then
            targetCFrame = destination
        elseif type(destination) == "string" then
            local targetObj = workspace:FindFirstChild(destination, true)
            if targetObj then
                if targetObj:IsA("BasePart") then
                    targetCFrame = targetObj.CFrame * CFrame.new(0, 0, -3)
                elseif targetObj:IsA("Model") then
                    targetCFrame = targetObj:GetPivot() * CFrame.new(0, 0, -3)
                end
            end
        end

        if targetCFrame then
            if Humanoid and Humanoid.SeatPart and Humanoid.SeatPart:IsA("VehicleSeat") then
                local DriveSeat = Humanoid.SeatPart
                local Vehicle   = DriveSeat.Parent
                if Vehicle and Vehicle:IsA("Model") then
                    DriveSeat.AssemblyLinearVelocity  = Vector3.zero
                    DriveSeat.AssemblyAngularVelocity = Vector3.zero
                    Vehicle:PivotTo(targetCFrame)
                    task.wait(0.05)
                    DriveSeat.AssemblyLinearVelocity  = Vector3.zero
                    DriveSeat.AssemblyAngularVelocity = Vector3.zero
                end
            else
                if RootPart then RootPart.CFrame = targetCFrame end
            end
        end
    end

    local function pressSpaceKey(times, interval)
        for i = 1, times do
            VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            task.wait(interval)
        end
    end

    local function clickGuiButton(btn)
        if not btn then return end
        if firesignal then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            pcall(function() firesignal(btn.MouseButton1Down) end)
            pcall(function() firesignal(btn.Activated) end)
            return
        end
        if getconnections then
            local events = { btn.MouseButton1Click, btn.MouseButton1Down, btn.Activated }
            local fired  = false
            for _, event in ipairs(events) do
                for _, conn in pairs(getconnections(event)) do
                    if conn.Fire then pcall(function() conn:Fire() end) fired = true
                    elseif conn.Function then pcall(function() conn:Function() end) fired = true end
                end
            end
            if fired then return end
        end
        if btn:IsA("GuiButton") then
            pcall(function()
                local guiService  = game:GetService("GuiService")
                guiService.SelectedObject = btn
                local virtualUser = game:GetService("VirtualUser")
                virtualUser:Button1Down(Vector2.new(0, 0))
                virtualUser:Button1Up(Vector2.new(0, 0))
            end)
        end
    end

    local function runAutoBrew()
        local BrewGui = playerGui:WaitForChild("Job"):WaitForChild("BrewMinigame")
        local Track   = BrewGui:WaitForChild("Track")
        local Zone    = Track:WaitForChild("Zone")
        local Needle  = Track:WaitForChild("Needle")

        local timeout = os.clock() + 10
        while not BrewGui.Visible and os.clock() < timeout do task.wait(0.05) end
        if not BrewGui.Visible then return false end

        local holding  = false
        local lastX    = Needle.Position.X.Scale
        local lastTime = os.clock()

        local function setHold(state)
            if holding == state then return end
            holding = state
            VirtualInputManager:SendKeyEvent(state, Enum.KeyCode.Space, false, game)
        end

        while BrewGui.Parent and BrewGui.Visible do
            local now  = os.clock()
            local dt   = now - lastTime
            if dt > 0 then
                local needleX     = Needle.Position.X.Scale
                local zoneX       = Zone.Position.X.Scale
                local zoneWidth   = Zone.Size.X.Scale
                local targetX     = zoneX + (zoneWidth / 2)
                local velocity    = (needleX - lastX) / dt
                local predTime    = velocity > 0 and 0.30 or 0.08
                local predictedX  = needleX + (velocity * predTime)
                local predictedErr = targetX - predictedX
                local tolerance   = 0.012

                if predictedErr > tolerance then
                    setHold(true)
                elseif predictedErr < -tolerance then
                    setHold(false)
                else
                    setHold(false)
                end

                lastX    = needleX
                lastTime = now
            end
            task.wait(0.01)
        end

        setHold(false)
        return true
    end

    local function getMenuIdFromName(menuName)
        if not menuName or menuName == "" then return nil end
        for menuId, data in pairs(BaristaMenu.Items) do
            if data.name then
                if data.name.id == menuName or data.name.en == menuName then return menuId end
            end
        end
        return nil
    end

    local function scanCurrentOrder()
        local npcDialog = playerGui:FindFirstChild("NpcDialog")
        if not npcDialog then return nil end

        local textObject
        if npcDialog:IsA("TextLabel") or npcDialog:IsA("TextButton") or npcDialog:IsA("TextBox") then
            textObject = npcDialog
        else
            textObject = npcDialog:FindFirstChildWhichIsA("TextLabel", true)
        end

        if not textObject then return nil end
        local text = textObject.Text
        if not text or text == "" then return nil end

        local menuName, flavour
        menuName, flavour = text:match("[Pp]esan%s+(.+),%s*[Rr]asa%s+(.+)%s+[Yy]a")
        if not menuName then menuName = text:match("[Pp]esan%s+(.+)%s+[Yy]a") end
        if not menuName then return nil end

        menuName = menuName:gsub("^%s+", ""):gsub("%s+$", "")
        if flavour then flavour = flavour:gsub("^%s+", ""):gsub("%s+$", "") end

        local menuId = getMenuIdFromName(menuName)
        if not menuId then return nil end

        local steps = BaristaMenu.Items[menuId] and BaristaMenu.Items[menuId].steps

        currentOrder = { Menu = menuName, MenuId = menuId, Flavour = flavour, RawText = text, Steps = steps }

        pcall(function()
            if BaristaMenuValue    then BaristaMenuValue.Text    = currentOrder.Menu    or "-" end
            if BaristaFlavourValue then BaristaFlavourValue.Text = currentOrder.Flavour or "-" end
        end)

        return currentOrder
    end

    local function waitForCurrentOrder(timeout)
        timeout = timeout or 10
        local deadline = os.clock() + timeout
        while os.clock() < deadline do
            local order = scanCurrentOrder()
            if order then return order end
            task.wait(0.2)
        end
        return nil
    end

    local function updateStatus(message)
        pcall(function()
            if AutoBaristaStatusProgress then
                AutoBaristaStatusProgress.Text = "Status: " .. message
            end
        end)
    end

    local function formatBaristaElapsedTime(seconds)
        return string.format("%02d:%02d:%02d",
            math.floor(seconds / 3600),
            math.floor((seconds % 3600) / 60),
            seconds % 60)
    end

    local function selectCurrentFlavour()
        local flavourName  = currentOrder and currentOrder.Flavour
        if not flavourName or flavourName == "" then return false end

        local choicePicker = playerGui and playerGui:FindFirstChild("Job") and playerGui.Job:FindFirstChild("ChoicePicker")
        local flavourGrid  = choicePicker and choicePicker:FindFirstChild("Grid")
        local flavourButton = nil

        if flavourGrid then
            flavourButton = flavourGrid:FindFirstChild(flavourName)
            if not flavourButton then
                for _, btn in ipairs(flavourGrid:GetChildren()) do
                    if btn.Name:lower() == flavourName:lower() or btn.Name:find(flavourName) then
                        flavourButton = btn
                        break
                    end
                end
            end
        end

        if flavourButton then
            clickGuiButton(flavourButton)
            task.wait(1)
            return true
        end
        return false
    end

    -- Drink recipe functions
    local function doKopiHitam()
        updateStatus("Getting Coffee Beans...")
        smartTeleportTo(CFrame.new(-27.46021270751953, 24.607194900512695, 8416.7197265625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.BeanHopper.BaristaStationPrompt) task.wait(1)
        updateStatus("Loading Beans into Brewer...")
        firePrompt(workspace.Barista.Stations.Brewer.BaristaStationPrompt) task.wait(0.2)
        updateStatus("Brewing Coffee...")
        if not runAutoBrew() then updateStatus("Brewing Failed!") return false end task.wait(1)
        return true
    end

    local function doCappuccino()
        updateStatus("Getting Coffee Beans...")
        smartTeleportTo(CFrame.new(-27.46021270751953, 24.607194900512695, 8416.7197265625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.BeanHopper.BaristaStationPrompt) task.wait(1)
        updateStatus("Loading Beans into Brewer...")
        firePrompt(workspace.Barista.Stations.Brewer.BaristaStationPrompt) task.wait(0.2)
        updateStatus("Brewing Coffee...")
        if not runAutoBrew() then updateStatus("Brewing Failed!") return false end task.wait(1)
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Flavour...")
        smartTeleportTo(CFrame.new(-25.904417037963867, 24.565404891967773, 8441.203125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.FlavourBottle.BaristaStationPrompt) task.wait(1)
        updateStatus("Selecting Flavour...")
        if not selectCurrentFlavour() then updateStatus("Failed to Select Flavour!") return false end task.wait(1)
        updateStatus("Steaming Milk...")
        smartTeleportTo(CFrame.new(-23.854318618774414, 24.607194900512695, 8413.7763671875)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Steamer.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doEsKopiSusu()
        updateStatus("Getting Coffee Beans...")
        smartTeleportTo(CFrame.new(-27.46021270751953, 24.607194900512695, 8416.7197265625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.BeanHopper.BaristaStationPrompt) task.wait(1)
        updateStatus("Loading Beans into Brewer...")
        firePrompt(workspace.Barista.Stations.Brewer.BaristaStationPrompt) task.wait(0.2)
        updateStatus("Brewing Coffee...")
        if not runAutoBrew() then updateStatus("Brewing Failed!") return false end task.wait(1)
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Flavour...")
        smartTeleportTo(CFrame.new(-25.904417037963867, 24.565404891967773, 8441.203125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.FlavourBottle.BaristaStationPrompt) task.wait(1)
        updateStatus("Selecting Flavour...")
        if not selectCurrentFlavour() then updateStatus("Failed to Select Flavour!") return false end task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doAmericano()
        updateStatus("Getting Coffee Beans...")
        smartTeleportTo(CFrame.new(-27.46021270751953, 24.607194900512695, 8416.7197265625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.BeanHopper.BaristaStationPrompt) task.wait(1)
        updateStatus("Loading Beans into Brewer...")
        firePrompt(workspace.Barista.Stations.Brewer.BaristaStationPrompt) task.wait(0.2)
        updateStatus("Brewing Coffee...")
        if not runAutoBrew() then updateStatus("Brewing Failed!") return false end task.wait(1)
        updateStatus("Filling Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.WaterTap.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doLatte()
        updateStatus("Getting Coffee Beans...")
        smartTeleportTo(CFrame.new(-27.46021270751953, 24.607194900512695, 8416.7197265625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.BeanHopper.BaristaStationPrompt) task.wait(1)
        updateStatus("Loading Beans into Brewer...")
        firePrompt(workspace.Barista.Stations.Brewer.BaristaStationPrompt) task.wait(0.2)
        updateStatus("Brewing Coffee...")
        if not runAutoBrew() then updateStatus("Brewing Failed!") return false end task.wait(1)
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Milk.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doHotChocolate()
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Chocolate...")
        smartTeleportTo(CFrame.new(-20.886396408081055, 24.565404891967773, 8436.17578125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.ChocolateJar.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doMocha()
        updateStatus("Getting Coffee Beans...")
        smartTeleportTo(CFrame.new(-27.46021270751953, 24.607194900512695, 8416.7197265625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.BeanHopper.BaristaStationPrompt) task.wait(1)
        updateStatus("Loading Beans into Brewer...")
        firePrompt(workspace.Barista.Stations.Brewer.BaristaStationPrompt) task.wait(0.2)
        updateStatus("Brewing Coffee...")
        if not runAutoBrew() then updateStatus("Brewing Failed!") return false end task.wait(1)
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Chocolate...")
        smartTeleportTo(CFrame.new(-20.886396408081055, 24.565404891967773, 8436.17578125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.ChocolateJar.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doMacchiato()
        updateStatus("Getting Coffee Beans...")
        smartTeleportTo(CFrame.new(-27.46021270751953, 24.607194900512695, 8416.7197265625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.BeanHopper.BaristaStationPrompt) task.wait(1)
        updateStatus("Loading Beans into Brewer...")
        firePrompt(workspace.Barista.Stations.Brewer.BaristaStationPrompt) task.wait(0.2)
        updateStatus("Brewing Coffee...")
        if not runAutoBrew() then updateStatus("Brewing Failed!") return false end task.wait(1)
        updateStatus("Steaming Milk...")
        smartTeleportTo(CFrame.new(-23.854318618774414, 24.607194900512695, 8413.7763671875)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Steamer.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doFrappuccino()
        updateStatus("Getting Coffee Beans...")
        smartTeleportTo(CFrame.new(-27.46021270751953, 24.607194900512695, 8416.7197265625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.BeanHopper.BaristaStationPrompt) task.wait(1)
        updateStatus("Loading Beans into Brewer...")
        firePrompt(workspace.Barista.Stations.Brewer.BaristaStationPrompt) task.wait(0.2)
        updateStatus("Brewing Coffee...")
        if not runAutoBrew() then updateStatus("Brewing Failed!") return false end task.wait(1)
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Adding Whipped Cream...")
        smartTeleportTo(CFrame.new(-34.13874053955078, 24.565404891967773, 8443.1826171875)) task.wait(1)
        firePrompt(workspace.Barista.Stations.CreamDispenser.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doTea()
        updateStatus("Filling Hot Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.WaterTap.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Tea Bag...")
        smartTeleportTo(CFrame.new(-16.10846519470215, 24.565404891967773, 8431.048828125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.TeaBox.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doThaiTea()
        updateStatus("Filling Hot Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.WaterTap.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Tea Bag...")
        smartTeleportTo(CFrame.new(-16.10846519470215, 24.565404891967773, 8431.048828125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.TeaBox.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doMatcha()
        updateStatus("Filling Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.WaterTap.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Matcha Powder...")
        smartTeleportTo(CFrame.new(-18.60329246520996, 24.565404891967773, 8433.6748046875)) task.wait(1)
        firePrompt(workspace.Barista.Stations.MatchaJar.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Milk.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doBubbleTea()
        updateStatus("Filling Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.WaterTap.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Tea Bag...")
        smartTeleportTo(CFrame.new(-16.10846519470215, 24.565404891967773, 8431.048828125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.TeaBox.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Adding Boba...")
        smartTeleportTo(CFrame.new(-23.343908309936523, 24.565404891967773, 8438.5400390625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.BobaPot.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doSoda()
        updateStatus("Filling Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.WaterTap.BaristaStationPrompt) task.wait(1)
        updateStatus("Adding Carbonated Water...")
        smartTeleportTo(CFrame.new(-36.2972526550293, 24.565404891967773, 8441.0244140625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Carbonator.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doLemonade()
        updateStatus("Filling Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.WaterTap.BaristaStationPrompt) task.wait(1)
        updateStatus("Adding Carbonated Water...")
        smartTeleportTo(CFrame.new(-36.2972526550293, 24.565404891967773, 8441.0244140625)) task.wait(1)
        firePrompt(workspace.Barista.Stations.Carbonator.BaristaStationPrompt) task.wait(1)
        updateStatus("Cutting Lemon...")
        smartTeleportTo(CFrame.new(-28.2451171875, 24.565404891967773, 8443.5751953125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.LemonBoard.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(workspace.Barista.Stations.IceMaker.BaristaStationPrompt) task.wait(1)
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

    local function runAutoBarista()
        local cashierCFrame = CFrame.new(-32.88235092163086, 23.811004638671875, 8422.7119140625)

        updateStatus("Moving to Cashier...")
        smartTeleportTo(cashierCFrame)
        task.wait(1)

        updateStatus("Waiting for Customer...")
        local customers      = workspace:FindFirstChild("BaristaCustomers")
        local scanStart      = os.clock()
        local servePrompt    = nil
        local currentCustomer = nil

        while not servePrompt and os.clock() - scanStart < 30 do
            if customers then
                local closestDist = 6
                for _, customer in ipairs(customers:GetChildren()) do
                    local hrp = customer:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local prompt = hrp:FindFirstChild("BaristaServePrompt")
                        if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            local dist = (hrp.Position - cashierCFrame.Position).Magnitude
                            if dist <= closestDist then
                                closestDist    = dist
                                servePrompt    = prompt
                                currentCustomer = customer
                            end
                        end
                    end
                end
            end
            if not servePrompt then task.wait(0.2) end
        end

        if servePrompt then
            updateStatus("Talking to Customer...")
            firePrompt(servePrompt)
        else
            updateStatus("Customer Not Found!")
            return
        end
        task.wait(1)

        updateStatus("Receiving Order...")
        currentOrder = nil
        local order = waitForCurrentOrder(10)
        if not order then updateStatus("Order Not Found!") return end

        task.wait(1)
        pressSpaceKey(1, 0.5)
        task.wait(1)

        updateStatus("Getting Cup...")
        smartTeleportTo(CFrame.new(-11.643688201904297, 24.607194900512695, 8409.1103515625))
        task.wait(1)

        game:GetService("ReplicatedStorage")
            :WaitForChild("NetworkContainer")
            :WaitForChild("RemoteEvents")
            :WaitForChild("Barista")
            :FireServer("Station", "CupRack")

        local choicePicker = playerGui:WaitForChild("Job", 5):WaitForChild("ChoicePicker", 5)
        task.wait(1)

        local menuName  = currentOrder and currentOrder.MenuId
        if not menuName or menuName == "" then updateStatus("Invalid Menu!") return end

        local cupGrid   = choicePicker and choicePicker:WaitForChild("Grid", 5)
        local cupButton = nil

        if cupGrid then
            cupButton = cupGrid:FindFirstChild(menuName)
            if not cupButton then
                for _, btn in ipairs(cupGrid:GetChildren()) do
                    if btn.Name:lower() == menuName:lower() or btn.Name:find(menuName) then
                        cupButton = btn break
                    end
                end
            end
        end

        if cupButton then
            clickGuiButton(cupButton)
        else
            updateStatus("Cup Not Found: " .. tostring(menuName))
            task.wait(2)
            return
        end
        task.wait(1)

        updateStatus("Making: " .. currentOrder.MenuId)
        local drinkFn = DRINK_MAP[currentOrder.MenuId]
        if not drinkFn then updateStatus("Menu Not Supported: " .. currentOrder.MenuId) return end
        if not drinkFn() then updateStatus("Drink Preparation Failed!") return end

        updateStatus("Returning to Cashier...")
        smartTeleportTo(cashierCFrame)
        task.wait(1)

        if not (currentCustomer and currentCustomer.Parent) then
            updateStatus("Customer Disappeared!")
            return
        end

        local serveStart  = os.clock()
        local servePrompt2 = nil

        updateStatus("Waiting Customer at Cashier...")
        while not servePrompt2 and os.clock() - serveStart < 30 do
            if not (currentCustomer and currentCustomer.Parent) then break end
            local hrp = currentCustomer:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - cashierCFrame.Position).Magnitude
                if dist <= 6 then
                    local prompt = hrp:FindFirstChild("BaristaServePrompt")
                    if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        servePrompt2 = prompt
                    end
                end
            end
            if not servePrompt2 then task.wait(0.2) end
        end

        if servePrompt2 then
            updateStatus("Serving Order...")
            firePrompt(servePrompt2)
            task.wait(0.5)

            ordersCompletedCount = ordersCompletedCount + 1
            if BaristaOrdersValue then BaristaOrdersValue.Text = tostring(ordersCompletedCount) end

            pcall(function()
                if BaristaMenuValue    then BaristaMenuValue.Text    = "-" end
                if BaristaFlavourValue then BaristaFlavourValue.Text = "-" end
            end)

            updateStatus("Order Completed!")
        else
            updateStatus("Customer Timeout / Lost!")
        end
        task.wait(1)
    end

    Connections["BaristaStartButton"] = BaristaStartButton.MouseButton1Click:Connect(function()
        autoBarista = not autoBarista

        if autoBarista then
            BaristaStartButton.Text            = "STOP AUTO BARISTA"
            BaristaStartButton.BackgroundColor3 = Color3.fromRGB(180, 30, 60)
            BaristaStatusValue.Text            = "● RUNNING"
            BaristaStatusValue.TextColor3      = Color3.fromRGB(0, 235, 145)
            startTime = os.time()

            ToastSystem.Show("success", "Auto Barista Started!")
            updateStatus("Starting Auto Barista...")

            if #Players:GetChildren() > 1 then
                LocalPlayer:Kick("[NEX-KICK] Used on a Private Server!")
                return
            end

            if game.PlaceId ~= 14005966837 then
                LocalPlayer:Kick("[NEX-KICK] Used in Jakarta!")
                return
            end

            task.spawn(function()
                while autoBarista do
                    BaristaElapsedValue.Text = formatBaristaElapsedTime(os.time() - startTime)
                    task.wait(1)
                end
            end)

            pcall(function()
                originalQualityLevel = settings().Rendering.QualityLevel
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        if not originalMaterials[obj] then
                            originalMaterials[obj] = obj.Material
                            originalShadows[obj]   = obj.CastShadow
                        end
                        obj.Material   = Enum.Material.SmoothPlastic
                        obj.CastShadow = false
                    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
                        obj.Enabled = false
                    elseif obj:IsA("PostEffect") then
                        obj.Enabled = false
                    end
                end
            end)

            updateStatus("Going to Barista Manager...")
            for i = 1, 5 do
                smartTeleportTo("NPC_BARISTA_MANAGER")
                task.wait(0.2)
            end
            task.wait(1)

            updateStatus("Starting Job Process...")
            local initStart = os.clock()
            while os.clock() - initStart < 1 do
                firePrompt(workspace.Barista.NPC_BARISTA_MANAGER.Head.DialogPrompt)
                task.wait(0.5)
            end
            pressSpaceKey(5, 0.2)
            task.wait(1)

            task.spawn(function()
                while autoBarista do
                    runAutoBarista()
                    task.wait(0.1)
                end
            end)

        else
            BaristaStartButton.Text            = "START AUTO BARISTA"
            BaristaStartButton.BackgroundColor3 = Color3.fromRGB(10, 28, 65)
            BaristaStatusValue.Text            = "● STOPPED"
            BaristaStatusValue.TextColor3      = Color3.fromRGB(255, 80, 90)
            updateStatus("Stopped")

            pcall(function()
                if BaristaMenuValue    then BaristaMenuValue.Text    = "-" end
                if BaristaFlavourValue then BaristaFlavourValue.Text = "-" end
            end)

            pcall(function()
                settings().Rendering.QualityLevel = originalQualityLevel
                for obj, mat in pairs(originalMaterials) do
                    if obj and obj.Parent then
                        obj.Material   = mat
                        if originalShadows[obj] ~= nil then obj.CastShadow = originalShadows[obj] end
                    end
                end
                table.clear(originalMaterials)
                table.clear(originalShadows)
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
                        obj.Enabled = true
                    elseif obj:IsA("PostEffect") then
                        obj.Enabled = true
                    end
                end
            end)

            pcall(function()
                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then humanoid.Health = 0 end
                    character:BreakJoints()
                end
            end)
        end
    end)

    -- FOOTER
    local Footer = Instance.new("TextLabel")
    Footer.AnchorPoint        = Vector2.new(0.5, 1)
    Footer.Position           = UDim2.new(0.5, 0, 1, 0)
    Footer.Size               = UDim2.new(1, -40, 0, 20)
    Footer.BackgroundTransparency = 1
    Footer.Text               = "N E X O V A   H U B   //   U N L E A S H   Y O U R   P O W E R"
    Footer.TextColor3         = Color3.fromRGB(125, 135, 160)
    Footer.TextSize           = 9
    Footer.Font               = Enum.Font.Gotham
    Footer.Parent             = Body

    -- DISCORD
    Connections["DiscordButton"] = DiscordButton.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard("https://discord.gg/KeNubYZzeB")
            DiscordButton.Text = "✓ COPIED!"
            ToastSystem.Show("success", "Discord link copied!")
            task.wait(2)
            DiscordButton.Text = "💾   DISCORD"
        end
    end)

    -- NAVIGATION
    local PAGES = { Home = HomePage, Barista = BaristaPage }
    local activeTweens   = {}
    local activePageName = nil

    local function setActiveNavigation(targetName)
        if activePageName == targetName then return end
        activePageName = targetName

        for navName, data in pairs(navButtons) do
            if navName == targetName then
                data.button.BackgroundTransparency = 0
                data.button.BackgroundColor3       = Color3.fromRGB(10, 28, 65)
                data.icon.TextColor3               = Color3.fromRGB(0, 180, 255)
                data.label.TextColor3              = Color3.fromRGB(235, 240, 250)
                local stroke = data.button:FindFirstChildOfClass("UIStroke")
                if not stroke then stroke = Instance.new("UIStroke", data.button) end
                stroke.Color       = Color3.fromRGB(175, 50, 255)
                stroke.Transparency = 0.15
            else
                data.button.BackgroundTransparency = 1
                data.icon.TextColor3               = Color3.fromRGB(125, 135, 160)
                data.label.TextColor3              = Color3.fromRGB(195, 202, 220)
                local stroke = data.button:FindFirstChildOfClass("UIStroke")
                if stroke then stroke:Destroy() end
            end
        end

        for _, pageFrame in pairs(PAGES) do pageFrame.Visible = false end

        local newPage = PAGES[targetName]
        if newPage then
            if activeTweens[newPage] then activeTweens[newPage]:Cancel() end
            newPage.Position = UDim2.new(0, 0, 0, 35)
            newPage.Visible  = true
            local tweenIn = TweenService:Create(newPage,
                TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
                { Position = UDim2.new(0, 0, 0, 0) })
            activeTweens[newPage] = tweenIn
            tweenIn:Play()
        end
    end

    for name, data in pairs(navButtons) do
        Connections["Nav_" .. name] = data.button.MouseButton1Click:Connect(function()
            setActiveNavigation(name)
        end)
    end

    setActiveNavigation("Home")

    -- MINIMIZE & CLOSE
    local minimized = false

    local function toggleHub()
        minimized = not minimized
        local tweenInfoOpen   = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tweenInfoClose  = TweenInfo.new(0.2,  Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tweenInfoButton = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        MinimizedIcon.Visible = true
        MinimizedIcon.Size    = UDim2.fromOffset(40, 40)
        TweenService:Create(MinimizedIcon, tweenInfoButton, { Size = UDim2.fromOffset(50, 50) }):Play()

        if minimized then
            playEffect("MinimizeHub")
            local closeTween = TweenService:Create(WindowScale, tweenInfoClose, { Scale = 0 })
            closeTween:Play()
            closeTween.Completed:Connect(function()
                if minimized then Window.Visible = false end
            end)
        else
            playEffect("MinimizeHub")
            local targetFinalScale = 1.0
            if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
                local minDim = math.min(workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y)
                targetFinalScale = math.clamp((minDim * 0.85) / 700, 0.60, 0.80)
            end
            WindowScale.Scale = targetFinalScale * 0.5
            Window.Visible    = true
            TweenService:Create(WindowScale, tweenInfoOpen, { Scale = targetFinalScale }):Play()
        end
    end

    Connections["MinimizeButton"] = MinimizeButton.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not minimized then
            toggleHub()
        end
    end)

    Connections["MinimizedIcon"] = MinimizedIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggleHub()
        end
    end)

    Connections["CloseButton"] = CloseButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            destroyHub("user_closed_hub")
        end
    end)

    -- DRAG
    local dragging, dragInput, dragStart, startPosition = false, nil, nil, nil

    Connections["TopBarDragStart"] = TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging      = true
            dragStart     = input.Position
            startPosition = Window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    Connections["WindowDragMove"] = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)

    -- OPEN ANIMATION
    task.spawn(function()
        task.wait(0.5)
        playEffect("WelcomeHub")

        local finalScale = 1.0
        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
            local minDim = math.min(workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y)
            finalScale = math.clamp((minDim * 0.85) / 700, 0.60, 0.80)
        end

        WindowScale.Scale    = finalScale * 0.4
        Window.Visible       = true
        MinimizedIcon.Size   = UDim2.fromOffset(0, 0)
        MinimizedIcon.Visible = true

        TweenService:Create(WindowScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = finalScale }):Play()
        task.wait(0.1)
        TweenService:Create(MinimizedIcon, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(50, 50) }):Play()
    end)

    return ScreenGui
end