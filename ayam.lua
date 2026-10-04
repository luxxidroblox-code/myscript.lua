--[[
================================================================================
  🔥 REN X ATOMIC - MULTI JOB AUTO FARM (BRUTAL ANTI-AFK) 🔥
================================================================================
    [+] Brutal Anti-AFK (Multi-Layer Simulation: Keypress, Click, & Camera Jiggle)
    [+] Tab 1 : Job Delivery (Auto Pickup & Dropoff, Lock 2s, Stucked Item 6.5s Retry)
    [+] Tab 2 : Criminal / Side Job (Auto ATM Bust & Underground Safe Zone)
    [+] Tab 3 : Money Estimator (Per Hour, 24 Hours, Income & Total Money)
================================================================================
]]--

local Services = {
    Players           = game:GetService("Players"),
    RunService        = game:GetService("RunService"),
    UserInput         = game:GetService("UserInputService"),
    Workspace         = game:GetService("Workspace"),
    PhysicsService    = game:GetService("PhysicsService"),
    CollectionService = game:GetService("CollectionService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CoreGui           = game:GetService("CoreGui"),
    VirtualUser       = game:GetService("VirtualUser"),
    VirtualInput      = game:GetService("VirtualInputManager"),
    TweenService      = game:GetService("TweenService"),
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- Hanya instance script terbaru yang boleh mengirim webhook.
_G.REN_X_ATOMIC_WEBHOOK_SESSION = (_G.REN_X_ATOMIC_WEBHOOK_SESSION or 0) + 1
local ThisWebhookSession = _G.REN_X_ATOMIC_WEBHOOK_SESSION

-- ============================================================
-- // BOOT SCREEN / WINDUI FALLBACK
-- ============================================================
local BootGui = nil
local BootIcon = nil
local BootMessage = nil
local BootFailed = false

local function createBootScreen()
    local ok, guiResult, iconResult, messageResult = pcall(function()
        local old = Services.CoreGui:FindFirstChild("REN_X_ATOMIC_BOOT")
        if old then old:Destroy() end

        local gui = Instance.new("ScreenGui")
        gui.Name = "REN_X_ATOMIC_BOOT"
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 1000000
        gui.Parent = Services.CoreGui

        local backdrop = Instance.new("Frame")
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.BackgroundColor3 = Color3.fromRGB(5, 7, 14)
        backdrop.BackgroundTransparency = 0.04
        backdrop.BorderSizePixel = 0
        backdrop.Parent = gui

        local backdropGradient = Instance.new("UIGradient")
        backdropGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 13, 28)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(17, 10, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 21, 31)),
        })
        backdropGradient.Rotation = 28
        backdropGradient.Parent = backdrop

        -- Partikel mikro untuk efek depth / holographic dust.
        local particleLayer = Instance.new("Frame")
        particleLayer.Name = "HolographicParticles"
        particleLayer.Size = UDim2.fromScale(1, 1)
        particleLayer.BackgroundTransparency = 1
        particleLayer.ClipsDescendants = true
        particleLayer.Parent = backdrop

        local particles = {}
        for i = 1, 28 do
            local particle = Instance.new("Frame")
            local particleSize = math.random(1, 3)
            particle.Size = UDim2.fromOffset(particleSize, particleSize)
            particle.Position = UDim2.fromScale(math.random(), math.random())
            particle.BackgroundColor3 = i % 3 == 0
                and Color3.fromRGB(102, 227, 255)
                or Color3.fromRGB(144, 126, 255)
            particle.BackgroundTransparency = math.random(55, 88) / 100
            particle.BorderSizePixel = 0
            particle.Parent = particleLayer
            local particleCorner = Instance.new("UICorner")
            particleCorner.CornerRadius = UDim.new(1, 0)
            particleCorner.Parent = particle
            table.insert(particles, {
                object = particle,
                x = math.random(),
                y = math.random(),
                speed = math.random(4, 10) / 10000,
                phase = math.random() * math.pi * 2,
            })
        end

        task.spawn(function()
            local started = os.clock()
            while gui.Parent do
                local t = os.clock() - started
                for _, particleData in ipairs(particles) do
                    local particle = particleData.object
                    particleData.y = (particleData.y - particleData.speed) % 1
                    particle.Position = UDim2.fromScale(
                        particleData.x + math.sin(t * 0.7 + particleData.phase) * 0.008,
                        particleData.y
                    )
                    particle.BackgroundTransparency = 0.58 + (math.sin(t * 1.8 + particleData.phase) + 1) * 0.16
                end
                task.wait(0.05)
            end
        end)

        -- Scanline tipis yang menyapu card seperti console hologram.
        local scanline = Instance.new("Frame")
        scanline.AnchorPoint = Vector2.new(0.5, 0)
        scanline.Position = UDim2.fromScale(0.5, -0.08)
        scanline.Size = UDim2.new(0.7, 0, 0, 1)
        scanline.BackgroundColor3 = Color3.fromRGB(92, 220, 255)
        scanline.BackgroundTransparency = 0.82
        scanline.BorderSizePixel = 0
        scanline.Parent = backdrop
        task.spawn(function()
            while gui.Parent do
                scanline.Position = UDim2.fromScale(0.5, -0.08)
                local sweep = Services.TweenService:Create(
                    scanline,
                    TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    { Position = UDim2.fromScale(0.5, 1.08) }
                )
                sweep:Play()
                sweep.Completed:Wait()
                task.wait(0.35)
            end
        end)

        -- Ambient neon lights bergerak pelan di belakang card.
        local function addAmbientOrb(position, size, color, transparency)
            local orb = Instance.new("Frame")
            orb.AnchorPoint = Vector2.new(0.5, 0.5)
            orb.Position = position
            orb.Size = UDim2.fromOffset(size, size)
            orb.BackgroundColor3 = color
            orb.BackgroundTransparency = transparency
            orb.BorderSizePixel = 0
            orb.Parent = backdrop
            local orbCorner = Instance.new("UICorner")
            orbCorner.CornerRadius = UDim.new(1, 0)
            orbCorner.Parent = orb
            local orbGradient = Instance.new("UIGradient")
            orbGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.18),
                NumberSequenceKeypoint.new(0.65, 0.65),
                NumberSequenceKeypoint.new(1, 1),
            })
            orbGradient.Parent = orb
            return orb
        end

        local orbA = addAmbientOrb(UDim2.fromScale(0.18, 0.25), 190, Color3.fromRGB(72, 137, 255), 0.78)
        local orbB = addAmbientOrb(UDim2.fromScale(0.83, 0.72), 240, Color3.fromRGB(176, 70, 255), 0.83)
        local orbC = addAmbientOrb(UDim2.fromScale(0.75, 0.14), 120, Color3.fromRGB(40, 235, 194), 0.86)

        task.spawn(function()
            local started = os.clock()
            while gui.Parent do
                local t = os.clock() - started
                orbA.Position = UDim2.fromScale(0.18 + math.sin(t * 0.42) * 0.035, 0.25 + math.cos(t * 0.31) * 0.035)
                orbB.Position = UDim2.fromScale(0.83 + math.cos(t * 0.34) * 0.04, 0.72 + math.sin(t * 0.27) * 0.035)
                orbC.Position = UDim2.fromScale(0.75 + math.sin(t * 0.5) * 0.025, 0.14 + math.cos(t * 0.39) * 0.025)
                task.wait(0.05)
            end
        end)

        local card = Instance.new("Frame")
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.fromScale(0.5, 0.5)
        card.Size = UDim2.fromOffset(390, 300)
        card.BackgroundColor3 = Color3.fromRGB(13, 17, 29)
        card.BackgroundTransparency = 0.08
        card.BorderSizePixel = 0
        card.Parent = backdrop

        local cardGradient = Instance.new("UIGradient")
        cardGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 36, 61)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(14, 19, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 28, 39)),
        })
        cardGradient.Rotation = 135
        cardGradient.Parent = card

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 18)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Color3.fromRGB(100, 182, 255)
        cardStroke.Transparency = 0.52
        cardStroke.Thickness = 1.5
        cardStroke.Parent = card

        local topAccent = Instance.new("Frame")
        topAccent.AnchorPoint = Vector2.new(0.5, 0)
        topAccent.Position = UDim2.fromScale(0.5, 0)
        topAccent.Size = UDim2.new(0.62, 0, 0, 2)
        topAccent.BackgroundColor3 = Color3.fromRGB(100, 205, 255)
        topAccent.BorderSizePixel = 0
        topAccent.Parent = card
        local accentGradient = Instance.new("UIGradient")
        accentGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(113, 104, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(93, 225, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 255, 199)),
        })
        accentGradient.Parent = topAccent

        local icon = Instance.new("ImageLabel")
        icon.Name = "LoadingLogo"
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.255)
        icon.Size = UDim2.fromOffset(82, 82)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://113820398113201"
        icon.ImageColor3 = Color3.fromRGB(235, 248, 255)
        icon.Parent = card

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = icon

        local iconStroke = Instance.new("UIStroke")
        iconStroke.Color = Color3.fromRGB(92, 210, 255)
        iconStroke.Transparency = 0.12
        iconStroke.Thickness = 2
        iconStroke.Parent = icon

        local spinner = Instance.new("Frame")
        spinner.AnchorPoint = Vector2.new(0.5, 0.5)
        spinner.Position = UDim2.fromScale(0.5, 0.255)
        spinner.Size = UDim2.fromOffset(112, 112)
        spinner.BackgroundTransparency = 1
        spinner.Parent = card
        local spinnerStroke = Instance.new("UIStroke")
        spinnerStroke.Color = Color3.fromRGB(92, 210, 255)
        spinnerStroke.Transparency = 0.18
        spinnerStroke.Thickness = 2
        spinnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        spinnerStroke.Parent = spinner
        local spinnerCorner = Instance.new("UICorner")
        spinnerCorner.CornerRadius = UDim.new(1, 0)
        spinnerCorner.Parent = spinner

        local spinnerDot = Instance.new("Frame")
        spinnerDot.AnchorPoint = Vector2.new(0.5, 0.5)
        spinnerDot.Position = UDim2.fromScale(0.5, 0)
        spinnerDot.Size = UDim2.fromOffset(7, 7)
        spinnerDot.BackgroundColor3 = Color3.fromRGB(91, 241, 211)
        spinnerDot.BorderSizePixel = 0
        spinnerDot.Parent = spinner
        local spinnerDotCorner = Instance.new("UICorner")
        spinnerDotCorner.CornerRadius = UDim.new(1, 0)
        spinnerDotCorner.Parent = spinnerDot

        task.spawn(function()
            while gui.Parent do
                spinner.Rotation = (spinner.Rotation + 2.5) % 360
                icon.Rotation = math.sin(os.clock() * 2.2) * 4
                task.wait(0.03)
            end
        end)

        local title = Instance.new("TextLabel")
        title.AnchorPoint = Vector2.new(0.5, 0)
        title.Position = UDim2.fromScale(0.5, 0.47)
        title.Size = UDim2.fromOffset(350, 32)
        title.BackgroundTransparency = 1
        title.Text = "REN X  //  ATOMIC"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 24
        title.Font = Enum.Font.GothamBold
        title.Parent = card

        local titleGradient = Instance.new("UIGradient")
        titleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(151, 231, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 174, 255)),
        })
        titleGradient.Parent = title

        task.spawn(function()
            while gui.Parent do
                titleGradient.Offset = Vector2.new(-1, 0)
                local shimmer = Services.TweenService:Create(
                    titleGradient,
                    TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    { Offset = Vector2.new(1, 0) }
                )
                shimmer:Play()
                shimmer.Completed:Wait()
                task.wait(1.2)
            end
        end)

        local subtitle = Instance.new("TextLabel")
        subtitle.AnchorPoint = Vector2.new(0.5, 0)
        subtitle.Position = UDim2.fromScale(0.5, 0.585)
        subtitle.Size = UDim2.fromOffset(350, 20)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = "MULTI-JOB AUTOMATION  •  PREMIUM CORE"
        subtitle.TextColor3 = Color3.fromRGB(112, 201, 255)
        subtitle.TextSize = 10
        subtitle.Font = Enum.Font.GothamBold
        subtitle.TextTransparency = 0.05
        subtitle.Parent = card

        local message = Instance.new("TextLabel")
        message.AnchorPoint = Vector2.new(0.5, 0)
        message.Position = UDim2.fromScale(0.5, 0.665)
        message.Size = UDim2.fromOffset(340, 28)
        message.BackgroundTransparency = 1
        message.Text = "Membangunkan interface premium..."
        message.TextColor3 = Color3.fromRGB(204, 216, 235)
        message.TextSize = 14
        message.Font = Enum.Font.Gotham
        message.TextWrapped = true
        message.Parent = card

        task.spawn(function()
            local loadingMessages = {
                "Membangunkan interface premium...",
                "Menyiapkan automation core...",
                "Menyinkronkan secure session...",
                "Menyalakan atomic control layer...",
            }
            local index = 1
            while gui.Parent and not BootFailed do
                message.TextTransparency = 0.35
                local fadeIn = Services.TweenService:Create(
                    message,
                    TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    { TextTransparency = 0 }
                )
                fadeIn:Play()
                fadeIn.Completed:Wait()
                task.wait(0.72)
                index = index % #loadingMessages + 1
                message.Text = loadingMessages[index]
            end
        end)

        local statusDot = Instance.new("Frame")
        statusDot.AnchorPoint = Vector2.new(0.5, 0.5)
        statusDot.Position = UDim2.new(0.5, -63, 0.77, 0)
        statusDot.Size = UDim2.fromOffset(6, 6)
        statusDot.BackgroundColor3 = Color3.fromRGB(73, 232, 187)
        statusDot.BorderSizePixel = 0
        statusDot.Parent = card
        local statusDotCorner = Instance.new("UICorner")
        statusDotCorner.CornerRadius = UDim.new(1, 0)
        statusDotCorner.Parent = statusDot
        local statusText = Instance.new("TextLabel")
        statusText.AnchorPoint = Vector2.new(0, 0.5)
        statusText.Position = UDim2.new(0.5, -52, 0.77, 0)
        statusText.Size = UDim2.fromOffset(115, 16)
        statusText.BackgroundTransparency = 1
        statusText.Text = "SECURE SESSION"
        statusText.TextColor3 = Color3.fromRGB(112, 229, 194)
        statusText.TextSize = 9
        statusText.Font = Enum.Font.GothamBold
        statusText.TextXAlignment = Enum.TextXAlignment.Left
        statusText.Parent = card

        -- Capsule ini menjadi anchor tunggal agar status selalu benar-benar center.
        local statusGroup = Instance.new("Frame")
        statusGroup.AnchorPoint = Vector2.new(0.5, 0.5)
        statusGroup.Position = UDim2.fromScale(0.5, 0.77)
        statusGroup.Size = UDim2.fromOffset(154, 22)
        statusGroup.BackgroundColor3 = Color3.fromRGB(45, 172, 143)
        statusGroup.BackgroundTransparency = 0.88
        statusGroup.BorderSizePixel = 0
        statusGroup.Parent = card
        local statusGroupCorner = Instance.new("UICorner")
        statusGroupCorner.CornerRadius = UDim.new(1, 0)
        statusGroupCorner.Parent = statusGroup
        local statusGroupStroke = Instance.new("UIStroke")
        statusGroupStroke.Color = Color3.fromRGB(73, 232, 187)
        statusGroupStroke.Transparency = 0.78
        statusGroupStroke.Thickness = 1
        statusGroupStroke.Parent = statusGroup

        statusDot.Parent = statusGroup
        statusDot.Position = UDim2.new(0, 20, 0.5, 0)
        statusText.Parent = statusGroup
        statusText.Position = UDim2.new(0, 34, 0.5, 0)
        statusText.Size = UDim2.fromOffset(108, 16)

        local progressTrack = Instance.new("Frame")
        progressTrack.AnchorPoint = Vector2.new(0.5, 0)
        progressTrack.Position = UDim2.fromScale(0.5, 0.86)
        progressTrack.Size = UDim2.fromOffset(270, 4)
        progressTrack.BackgroundColor3 = Color3.fromRGB(40, 52, 76)
        progressTrack.BorderSizePixel = 0
        progressTrack.Parent = card

        local progressTrackCorner = Instance.new("UICorner")
        progressTrackCorner.CornerRadius = UDim.new(1, 0)
        progressTrackCorner.Parent = progressTrack

        local progressFill = Instance.new("Frame")
        progressFill.Size = UDim2.fromScale(0.18, 1)
        progressFill.BackgroundColor3 = Color3.fromRGB(94, 217, 255)
        progressFill.BorderSizePixel = 0
        progressFill.Parent = progressTrack

        local progressFillCorner = Instance.new("UICorner")
        progressFillCorner.CornerRadius = UDim.new(1, 0)
        progressFillCorner.Parent = progressFill

        local progressGradient = Instance.new("UIGradient")
        progressGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(112, 113, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(88, 224, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(71, 255, 191)),
        })
        progressGradient.Parent = progressFill

        local progressTween = Services.TweenService:Create(
            progressFill,
            TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Size = UDim2.fromScale(0.86, 1) }
        )
        progressTween:Play()

        local cardScale = Instance.new("UIScale")
        cardScale.Scale = 0.96
        cardScale.Parent = card
        Services.TweenService:Create(
            cardScale,
            TweenInfo.new(0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Scale = 1 }
        ):Play()

        return gui, icon, message
    end)
    if not ok then return nil, nil, nil end
    return guiResult, iconResult, messageResult
end

BootGui, BootIcon, BootMessage = createBootScreen()

local function showBootFailure(reason)
    BootFailed = true
    if BootMessage then
        BootMessage.Text = "WindUI tidak muncul.\n" .. reason .. "\nRefresh Roblox lalu execute ulang."
        BootMessage.TextColor3 = Color3.fromRGB(255, 150, 150)
    end
    if BootIcon then BootIcon.Rotation = 0 end
end

-- ============================================================
-- // BRUTAL ANTI-AFK ENGINE (ULTIMATE BYPASS)
-- ============================================================
task.spawn(function()
    pcall(function()
        -- Matikan connection bawaan game agar tidak mengirim sinyal idle
        if getconnections then
            for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
                connection:Disable()
            end
        end
        
        -- Event listener tambahan saat game mencoba memaksa idle
        LocalPlayer.Idled:Connect(function()
            Services.VirtualUser:CaptureController()
            Services.VirtualUser:ClickButton2(Vector2.new(math.random(100, 500), math.random(100, 500)))
        end)

        -- Loop brutal setiap 15 detik untuk simulasi aktivitas penuh
        task.spawn(function()
            while true do
                pcall(function()
                    -- 1. Simulasi klik mouse di layar
                    Services.VirtualUser:CaptureController()
                    Services.VirtualUser:Button1Down(Vector2.new(200, 200))
                    task.wait(0.1)
                    Services.VirtualUser:Button1Up(Vector2.new(200, 200))

                    -- 2. Simulasi pencet tombol keyboard secara acak (Spasi atau Tombol W)
                    local randomKey = math.random(1, 2) == 1 and Enum.KeyCode.Space or Enum.KeyCode.W
                    Services.VirtualInput:SendKeyEvent(true, randomKey, false, game)
                    task.wait(0.2)
                    Services.VirtualInput:SendKeyEvent(false, randomKey, false, game)

                    -- 3. Goyang dikit kamera (Camera Jiggle) supaya server mengira player menengok
                    if Camera then
                        local currentCamCF = Camera.CFrame
                        Camera.CFrame = currentCamCF * CFrame.Angles(0, math.rad(math.random(-2, 2)), 0)
                        task.wait(0.1)
                        Camera.CFrame = currentCamCF
                    end
                end)
                task.wait(15) -- Dijalankan setiap 15 detik secara konstan
            end
        end)
    end)
end)

-- ============================================================
-- // LOAD WINDUI
-- ============================================================
local WindUI
local success, err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not WindUI then
    showBootFailure("Library gagal dimuat")
    return
end

local Window = nil
local windowSuccess, windowError = pcall(function()
    Window = WindUI:CreateWindow({
        Title = "REN X  //  ATOMIC",
        Icon = "zap",
        Author = "NEXUS AUTOMATION SUITE",
        Folder = "RenXAtomicConfig",
        Size = UDim2.fromOffset(640, 500),
        MinSize = Vector2.new(560, 380),
        ToggleKey = Enum.KeyCode.RightShift,
        Theme = "Dark",
        Resizable = true,
        SideBarWidth = 214,
    })
end)

if not windowSuccess or not Window then
    showBootFailure("Window WindUI gagal dibuat")
    return
end

if BootGui then
    BootGui:Destroy()
    BootGui = nil
end

-- Recovery UI: panel tetap bisa dibuka kembali walau state window berubah.
-- Semua opsi recovery dibungkus pcall agar perbedaan versi WindUI tidak
-- menghentikan script sebelum Window:Open() dipanggil.
pcall(function()
    Window:EditOpenButton({
        Title = "Open Atomic Nexus",
        Icon = "sparkles",
        Enabled = true,
        Draggable = true,
    })
end)

-- Tombol reopen mandiri di CoreGui. Tidak ikut hilang saat WindUI diminimize.
local RecoveryGuiName = "REN_X_ATOMIC_RECOVERY"
local RecoveryButton = nil
pcall(function()
    local oldRecoveryGui = Services.CoreGui:FindFirstChild(RecoveryGuiName)
    if oldRecoveryGui then oldRecoveryGui:Destroy() end

    local recoveryGui = Instance.new("ScreenGui")
    recoveryGui.Name = RecoveryGuiName
    recoveryGui.ResetOnSpawn = false
    recoveryGui.DisplayOrder = 999999
    recoveryGui.IgnoreGuiInset = true
    recoveryGui.Parent = Services.CoreGui

    local reopenButton = Instance.new("ImageButton")
    RecoveryButton = reopenButton
    reopenButton.Name = "ReopenButton"
    reopenButton.Size = UDim2.fromOffset(52, 52)
    reopenButton.Position = UDim2.new(1, -68, 0, 14)
    reopenButton.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    reopenButton.BackgroundTransparency = 0.02
    reopenButton.BorderSizePixel = 0
    reopenButton.Image = "rbxassetid://113820398113201"
    reopenButton.ImageColor3 = Color3.fromRGB(226, 247, 255)
    reopenButton.AutoButtonColor = true
    reopenButton.Parent = recoveryGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = reopenButton

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 170, 255)
    stroke.Thickness = 2
    stroke.Parent = reopenButton

    local reopenGradient = Instance.new("UIGradient")
    reopenGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(64, 105, 178)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(31, 52, 88)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 128, 130)),
    })
    reopenGradient.Rotation = 35
    reopenGradient.Parent = reopenButton

    -- Drag support untuk mouse dan touch.
    local dragging = false
    local dragStart = nil
    local startPosition = nil
    local dragInput = nil

    reopenButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = reopenButton.Position
            dragInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragInput = nil
                end
            end)
        end
    end)

    reopenButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    Services.UserInput.InputChanged:Connect(function(input)
        if dragging and input == dragInput and dragStart and startPosition then
            local delta = input.Position - dragStart
            reopenButton.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    reopenButton.Activated:Connect(function()
        pcall(function() Window:Open() end)
    end)
end)

pcall(function()
    -- Minimize tidak menyentuh recovery button; X/destroy baru menyembunyikannya.
    Window:OnDestroy(function()
        if RecoveryButton then RecoveryButton.Visible = false end
    end)
    Window:OnOpen(function()
        if RecoveryButton then RecoveryButton.Visible = true end
    end)
end)

-- Minimize tetap aktif; floating OpenButton dan RightShift menjadi jalur reopen.
pcall(function()
    Window:SetToggleKey(Enum.KeyCode.RightShift)
end)

-- Fallback untuk tombol '-' pada keyboard.
Services.UserInput.InputBegan:Connect(function(input, processed)
    if not processed and tostring(input.KeyCode):find("Minus") then
        pcall(function() Window:Open() end)
    end
end)

-- Buka lebih awal agar error pada elemen tab tidak membuat seluruh UI menghilang.
pcall(function() Window:Open() end)

-- State webhook dideklarasikan lebih awal agar loop farm dapat mengirim event.
local WebhookEnabled = false
local WebhookAutoEvents = false
local WebhookBotName = "REN X ATOMIC"
local WebhookCooldown = 5
local WebhookLastSentAt = 0
local sendDiscordWebhook

-- Adapter status agar logika lama tidak perlu diubah.
local function makeStatusParagraph(section, title, value)
    local paragraph = section:Paragraph({
        Title = title,
        Desc = value,
    })
    return {
        Set = function(_, _, newValue)
            paragraph:SetDesc(newValue)
        end,
    }
end

-- ============================================================
-- // SHARED UTILITIES & NOCLIP / FLY
-- ============================================================
local NoclipConnections = {}
local IsNoclipActive = false
local BodyVel = nil
local BodyGyro = nil

-- Collision bangunan dibuat terpisah dari terrain/default. Dengan cara ini
-- karakter selalu menembus bangunan, tetapi tetap bisa berdiri di tanah.
local BuildingCollisionGroup = "REN_X_Building"
local CharacterCollisionGroup = "REN_X_Player"
local BuildingNameTokens = {
    "building", "house", "home", "apartment", "shop", "store", "bank",
    "hospital", "school", "garage", "office", "mall", "tower", "warehouse",
    "restaurant", "hotel", "station", "police", "firestation", "gasstation",
    "structure", "interior", "buildingpart",
}
local BuildingContainerNames = {
    buildings = true, building = true, structures = true, structure = true,
    houses = true, house = true, interiors = true, interior = true,
}

local function setupBuildingCollisionGroups()
    pcall(function()
        Services.PhysicsService:RegisterCollisionGroup(BuildingCollisionGroup)
    end)
    pcall(function()
        Services.PhysicsService:RegisterCollisionGroup(CharacterCollisionGroup)
    end)
    pcall(function()
        Services.PhysicsService:CollisionGroupSetCollidable(
            CharacterCollisionGroup,
            BuildingCollisionGroup,
            false
        )
        -- Tetap collidable terhadap Default, termasuk terrain.
        Services.PhysicsService:CollisionGroupSetCollidable(
            CharacterCollisionGroup,
            "Default",
            true
        )
    end)
end

local function hasBuildingMarker(instance)
    if not instance then return false end
    if Services.CollectionService:HasTag(instance, "Building")
        or Services.CollectionService:HasTag(instance, "Buildings") then
        return true
    end

    local normalized = string.lower(instance.Name):gsub("[^%w]", "")
    if BuildingContainerNames[normalized] then return true end
    for _, token in ipairs(BuildingNameTokens) do
        if normalized:find(token, 1, true) then return true end
    end
    return false
end

local function isBuildingPart(part)
    if not part or not part:IsA("BasePart") then return false end
    if part:IsDescendantOf(Services.Workspace.Terrain) then return false end
    local character = LocalPlayer.Character
    if character and part:IsDescendantOf(character) then return false end

    local current = part
    while current and current ~= Services.Workspace do
        if hasBuildingMarker(current) then return true end
        current = current.Parent
    end
    return false
end

local function applyBuildingCollision(part)
    if isBuildingPart(part) then
        pcall(function() part.CollisionGroup = BuildingCollisionGroup end)
    end
end

local function applyCharacterCollision(character)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CollisionGroup = CharacterCollisionGroup end)
        end
    end
end

setupBuildingCollisionGroups()
for _, object in ipairs(Services.Workspace:GetDescendants()) do
    applyBuildingCollision(object)
end
Services.Workspace.DescendantAdded:Connect(applyBuildingCollision)
if LocalPlayer.Character then applyCharacterCollision(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(character)
    task.defer(applyCharacterCollision, character)
    character.DescendantAdded:Connect(function(object)
        if object:IsA("BasePart") then
            pcall(function() object.CollisionGroup = CharacterCollisionGroup end)
        end
    end)
end)

local function enableFlyNoclip(state)
    IsNoclipActive = state
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")

    if state then
        if root then
            root.Velocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)

            if not BodyVel or not BodyVel.Parent then
                BodyVel = Instance.new("BodyVelocity")
                BodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                BodyVel.Velocity = Vector3.new(0, 0, 0)
                BodyVel.Parent = root
            end
            if not BodyGyro or not BodyGyro.Parent then
                BodyGyro = Instance.new("BodyGyro")
                BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                BodyGyro.CFrame = root.CFrame
                BodyGyro.Parent = root
            end
        end
    else
        if BodyVel then BodyVel:Destroy() BodyVel = nil end
        if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
        
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

local function stopNoclipHandler()
    for _, conn in ipairs(NoclipConnections) do conn:Disconnect() end
    table.clear(NoclipConnections)
    enableFlyNoclip(false)
end

-- ============================================================
local DeliveryState = {
    AutoFarm = false,
    CompletedCount = 0,
    HasRequestedJob = false,
}
local DeliveryLandingPlatform = nil

local Remotes = Services.ReplicatedStorage:WaitForChild("Remotes")
local RequestStartJobSession = Remotes:WaitForChild("RequestStartJobSession")
local AttemptDeliveryPickup = Remotes:WaitForChild("AttemptDeliveryPickup")
local AttemptDeliveryComplete = Remotes:WaitForChild("AttemptDeliveryComplete")
local DeliveryLocationInteracted = Remotes:WaitForChild("DeliveryLocationInteracted")
local DeliveryLocationLeft = Remotes:WaitForChild("DeliveryLocationLeft")

local function safePreparePickup(object)
    if not object then return end
    pcall(function()
        for _, part in ipairs(object:GetDescendants()) do
            if part:IsA("BasePart") then part.CanTouch = true end
        end
    end)
end

local function startDeliveryNoclip()
    if #NoclipConnections > 0 then return end
    table.insert(NoclipConnections, Services.RunService.Stepped:Connect(function()
        if not DeliveryState.AutoFarm then return end
        local character = LocalPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end))
end

local function getPickupFolder()
    return Services.Workspace:FindFirstChild("DeliveryPickupItems_DeliveryLocation")
end

local function getPickupItems()
    local folder = getPickupFolder()
    return folder and folder:GetChildren() or {}
end

local function getCenterCFrame(container)
    if not container then return nil end
    if container:IsA("Model") then return container:GetPivot()
    elseif container:IsA("BasePart") then return container.CFrame
    elseif container:IsA("Folder") then
        local children = container:GetChildren()
        if #children > 0 then
            local totalPos = Vector3.new(0, 0, 0)
            local count = 0
            for _, child in ipairs(children) do
                if child:IsA("BasePart") then totalPos = totalPos + child.Position; count = count + 1
                elseif child:IsA("Model") then totalPos = totalPos + child:GetPivot().Position; count = count + 1 end
            end
            if count > 0 then return CFrame.new(totalPos / count) end
        end
    end
    return nil
end

local function getDropoffTarget()
    return Services.Workspace:FindFirstChild("DeliveryTargetAnchor")
end

local function getDeliveryLocationInstance()
    local ok, res = pcall(function()
        return Services.Workspace.Game.Jobs.Delivery.DeliveryLocations.DeliveryLocation
    end)
    return ok and res or nil
end

local function createDeliveryLandingPlatform(targetCFrame)
    if not targetCFrame then return end

    if not DeliveryLandingPlatform or not DeliveryLandingPlatform.Parent then
        DeliveryLandingPlatform = Instance.new("Part")
        DeliveryLandingPlatform.Name = "REN_X_DeliveryLandingPlatform"
        DeliveryLandingPlatform.Size = Vector3.new(24, 1, 24)
        DeliveryLandingPlatform.Anchored = true
        DeliveryLandingPlatform.CanCollide = true
        DeliveryLandingPlatform.CanTouch = false
        DeliveryLandingPlatform.CanQuery = false
        DeliveryLandingPlatform.Transparency = 0.45
        DeliveryLandingPlatform.Material = Enum.Material.SmoothPlastic
        DeliveryLandingPlatform.Color = Color3.fromRGB(70, 180, 255)
        DeliveryLandingPlatform.CastShadow = false
        DeliveryLandingPlatform.Parent = Services.Workspace

        local logoSurface = Instance.new("SurfaceGui")
        logoSurface.Name = "REN_X_DeliveryLogo"
        logoSurface.Face = Enum.NormalId.Top
        logoSurface.AlwaysOnTop = true
        logoSurface.LightInfluence = 0
        logoSurface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        logoSurface.PixelsPerStud = 32
        logoSurface.Parent = DeliveryLandingPlatform

        local logoImage = Instance.new("ImageLabel")
        logoImage.Name = "AtomicLogo"
        logoImage.AnchorPoint = Vector2.new(0.5, 0.5)
        logoImage.Position = UDim2.fromScale(0.5, 0.5)
        logoImage.Size = UDim2.fromScale(0.42, 0.42)
        logoImage.BackgroundTransparency = 1
        logoImage.Image = "rbxassetid://113820398113201"
        logoImage.ImageTransparency = 0.12
        logoImage.ScaleType = Enum.ScaleType.Fit
        logoImage.Parent = logoSurface

        local logoAspect = Instance.new("UIAspectRatioConstraint")
        logoAspect.AspectRatio = 1
        logoAspect.AspectType = Enum.AspectType.FitWithinMaxSize
        logoAspect.Parent = logoImage
    end

    DeliveryLandingPlatform.CFrame = CFrame.new(targetCFrame.Position + Vector3.new(0, 0.5, 0))
end

local function destroyDeliveryLandingPlatform()
    if DeliveryLandingPlatform then
        DeliveryLandingPlatform:Destroy()
        DeliveryLandingPlatform = nil
    end
end

local function teleportAndDropToCFrame(targetCFrame)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and targetCFrame then
        enableFlyNoclip(true)
        root.Velocity = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
        root.CFrame = targetCFrame + Vector3.new(0, 40, 0)
        
        task.wait(2.0)
        
        if BodyVel then BodyVel:Destroy() BodyVel = nil end
        if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
        task.wait(0.4)
    end
end

local TabDelivery = Window:Tab({ Title = "Job Delivery", Icon = "package-check" })
local SecDelivery = TabDelivery:Section({ Title = "Automated Delivery System", Opened = true })

local StatusLabel = makeStatusParagraph(SecDelivery, "Status Sistem", "Standby (Off)")
local CounterLabel = makeStatusParagraph(SecDelivery, "Total Paket Selesai", "0 Paket")

local function runDeliveryLoop()
    startDeliveryNoclip()
    task.spawn(function()
        if not DeliveryState.HasRequestedJob then
            pcall(function() RequestStartJobSession:FireServer("Delivery", "jobPad", "HighRisk") end)
            DeliveryState.HasRequestedJob = true
            task.wait(1)
        end

        while DeliveryState.AutoFarm do
            StatusLabel:Set("Status Sistem", "Mencari Pickup Zone...")
            local pickupFolder = nil
            local attempts = 0
            
            repeat
                if not DeliveryState.AutoFarm then break end
                pickupFolder = getPickupFolder()
                if not pickupFolder or #getPickupItems() == 0 then
                    task.wait(0.15)
                    attempts = attempts + 1
                    if attempts >= 30 then
                        local checkTarget = getDropoffTarget()
                        if checkTarget then
                            StatusLabel:Set("Status Sistem", "Pickup hilang, Teleport ke Target...")
                            local targetCF = checkTarget:IsA("Model") and checkTarget:GetPivot() or checkTarget.CFrame
                            teleportAndDropToCFrame(targetCF)
                            break
                        else
                            StatusLabel:Set("Status Sistem", "Refreshing Lokasi Nyangkut...")
                            pcall(function()
                                local loc = getDeliveryLocationInstance()
                                if loc then DeliveryLocationLeft:FireServer(loc) end
                            end)
                            task.wait(1)
                            attempts = 0
                        end
                    end
                end
            until (pickupFolder and #getPickupItems() > 0) or not DeliveryState.AutoFarm

            if not DeliveryState.AutoFarm then break end

            pickupFolder = getPickupFolder()
            if pickupFolder and #getPickupItems() > 0 then
                local centerCF = getCenterCFrame(pickupFolder)
                if centerCF then
                    StatusLabel:Set("Status Sistem", "Teleport ke Pickup Zone...")
                    createDeliveryLandingPlatform(centerCF)
                    teleportAndDropToCFrame(centerCF)
                    safePreparePickup(pickupFolder)
                end

                local lastItemCount = #getPickupItems()
                local stuckTimeCounter = 0

                while DeliveryState.AutoFarm do
                    local items = getPickupItems()
                    if #items == 0 then break end

                    if #items == lastItemCount then
                        -- Retry per item jika jumlah pickup tidak berkurang sama sekali.
                        stuckTimeCounter = stuckTimeCounter + 0.3
                        if stuckTimeCounter >= 6.5 then
                            StatusLabel:Set("Status Sistem", "Item Macet 6,5s! Teleport Pickup Ulang...")
                            if centerCF then
                                createDeliveryLandingPlatform(centerCF)
                                teleportAndDropToCFrame(centerCF)
                                safePreparePickup(pickupFolder)
                            end
                            stuckTimeCounter = 0
                        end
                    else
                        lastItemCount = #items
                        stuckTimeCounter = 0
                    end

                    StatusLabel:Set("Status Sistem", "Mengangkut Paket (Sisa: " .. #items .. ")...")
                    pcall(function() DeliveryLocationInteracted:FireServer(items[1]) end)
                    pcall(function() AttemptDeliveryPickup:FireServer(items[1]) end)
                    task.wait(0.3)
                end

                pcall(function()
                    local loc = getDeliveryLocationInstance()
                    if loc then DeliveryLocationLeft:FireServer(loc) end
                end)
                task.wait(0.2)
            end

            if not DeliveryState.AutoFarm then break end

            StatusLabel:Set("Status Sistem", "Menunggu Dropoff Target...")
            local dropTarget = nil
            local dropAttempts = 0
            repeat
                if not DeliveryState.AutoFarm then break end
                dropTarget = getDropoffTarget()
                if not dropTarget then
                    task.wait(0.15)
                    dropAttempts = dropAttempts + 1
                    if dropAttempts > 50 then break end
                end
            until dropTarget or not DeliveryState.AutoFarm

            if not DeliveryState.AutoFarm then break end

            if dropTarget then
                StatusLabel:Set("Status Sistem", "Teleport ke Dropoff & Standby...")
                safePreparePickup(dropTarget)
                local dropCF = dropTarget:IsA("Model") and dropTarget:GetPivot() or dropTarget.CFrame
                
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    enableFlyNoclip(true)
                    root.Velocity = Vector3.zero
                    root.RotVelocity = Vector3.zero
                    root.CFrame = dropCF + Vector3.new(0, 40, 0)
                end

                StatusLabel:Set("Status Sistem", "Standby Server (3 Detik)...")
                task.wait(3)

                if not DeliveryState.AutoFarm then break end

                if BodyVel then BodyVel:Destroy() BodyVel = nil end
                if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = true end
                    end
                end
                task.wait(0.3)

                pcall(function() DeliveryLocationInteracted:FireServer(dropTarget) end)
                task.wait(0.2)
                pcall(function() AttemptDeliveryComplete:FireServer(dropTarget) end)

                DeliveryState.CompletedCount = DeliveryState.CompletedCount + 1
                CounterLabel:Set("Total Paket Selesai", tostring(DeliveryState.CompletedCount) .. " Paket")

                -- Auto-event delivery: kirim setelah paket benar-benar selesai.
                if WebhookAutoEvents then
                    sendDiscordWebhook(
                        "Delivery Paket Selesai",
                        "Paket #" .. tostring(DeliveryState.CompletedCount) .. " berhasil diselesaikan.",
                        0x57F287,
                        true
                    )
                end

                pcall(function()
                    local locDrop = getDeliveryLocationInstance()
                    if locDrop then DeliveryLocationLeft:FireServer(locDrop) end
                end)
                task.wait(0.3)
            end
        end
    end)
end

SecDelivery:Toggle({
    Title = "Aktifkan Auto Farm Delivery",
    Value = false,
    Callback = function(state)
        DeliveryState.AutoFarm = state
        if state then
            StatusLabel:Set("Status Sistem", "Running (Aktif)")
            runDeliveryLoop()
        else
            StatusLabel:Set("Status Sistem", "Standby (Off)")
            stopNoclipHandler()
            destroyDeliveryLandingPlatform()
            DeliveryState.HasRequestedJob = false
        end
    end,
})
-- // TAB 2: CRIMINAL / SIDE JOB
-- ============================================================
local CriminalAutoFarm = false
local TargetBustLimit = 10
local BustedATMs = {}
local UNDERGROUND_OFFSET = -35
local SafePlatform = nil

local AttemptATMBustStart = Remotes:WaitForChild("AttemptATMBustStart")
local AttemptATMBustComplete = Remotes:WaitForChild("AttemptATMBustComplete")
local AttemptCriminalJobComplete = Remotes:WaitForChild("AttemptCriminalJobComplete")

local function getLootBagCount()
    local count = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character

    local function checkContainer(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("bag") or name:find("loot") or name:find("money") or name:find("tas") or name:find("stolen") then
                    count = count + 1
                end
            end
        end
    end

    checkContainer(backpack)
    checkContainer(character)
    
    if count == 0 then
        if character and character:FindFirstChild("LootValue") then
            count = character.LootValue.Value
        elseif LocalPlayer:FindFirstChild("Leaderstats") and LocalPlayer.Leaderstats:FindFirstChild("Bags") then
            count = LocalPlayer.Leaderstats.Bags.Value
        end
    end
    return count
end

local CriminalCounterLabel = nil
local CriminalStatusText = nil

local function updateBagUI()
    if CriminalCounterLabel then
        local currentBags = getLootBagCount()
        CriminalCounterLabel:Set("Status Tas", "Tas: " .. tostring(currentBags) .. " / " .. tostring(TargetBustLimit))
    end
end

local function forceDisableCollision(object)
    if not object then return end
    for _, part in ipairs(object:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
        end
    end
    if object:IsA("BasePart") then
        object.CanCollide = false
        object.CanTouch = false
    end
end

local function createSafePlatform(targetPos)
    if not SafePlatform or not SafePlatform.Parent then
        SafePlatform = Instance.new("Part")
        SafePlatform.Name = "UndergroundSafeZone"
        SafePlatform.Size = Vector3.new(30, 2, 30)
        SafePlatform.Position = targetPos - Vector3.new(0, 3, 0)
        SafePlatform.Anchored = true
        SafePlatform.Transparency = 0.5
        SafePlatform.Material = Enum.Material.SmoothPlastic
        SafePlatform.Color = Color3.fromRGB(0, 255, 150)
        SafePlatform.Parent = Services.Workspace
    else
        SafePlatform.Position = targetPos - Vector3.new(0, 3, 0)
    end
end

local function teleportToSafeZone()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        enableFlyNoclip(true)
        local currentPos = root.Position
        local safePos = Vector3.new(currentPos.X, currentPos.Y + UNDERGROUND_OFFSET, currentPos.Z)
        createSafePlatform(safePos)
        root.Velocity = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
        root.CFrame = CFrame.new(safePos)
        task.wait(0.2)
    end
end

local function startCriminalNoclip()
    if #NoclipConnections > 0 then return end
    local function applyBrutalNoclip()
        if not CriminalAutoFarm or not IsNoclipActive then return end
        local character = LocalPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.CanTouch = false
            end
        end
    end
    table.insert(NoclipConnections, Services.RunService.Stepped:Connect(applyBrutalNoclip))
    table.insert(NoclipConnections, Services.RunService.RenderStepped:Connect(applyBrutalNoclip))
    table.insert(NoclipConnections, Services.RunService.Heartbeat:Connect(applyBrutalNoclip))
end

local function hasIcon(atm)
    if not atm or not atm.Parent then return false end
    local distantAttachment = atm:FindFirstChild("DistantIconAttachment")
    if not distantAttachment then return false end
    local billboard = distantAttachment:FindFirstChild("ATMIconBillboard")
    if not billboard then return false end
    local icon = billboard:FindFirstChild("Icon")
    return icon and icon.Parent ~= nil
end

local function isValidATM(atm)
    if not atm or not atm.Parent then return false end
    if BustedATMs[atm] then return false end
    return hasIcon(atm)
end

local function getActiveATM()
    local jobsFolder = Services.Workspace:FindFirstChild("Game") and Services.Workspace.Game:FindFirstChild("Jobs")
    if jobsFolder then
        for _, child in ipairs(jobsFolder:GetChildren()) do
            if child.Name:find("ATM") then
                for _, spawner in ipairs(child:GetChildren()) do
                    local atm = spawner:FindFirstChild("CriminalATM") or spawner:FindFirstChild("CriminalATMWater")
                    if isValidATM(atm) then return atm end
                end
            end
        end
    end
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if (obj.Name == "CriminalATM" or obj.Name == "CriminalATMWater") and isValidATM(obj) then
            return obj
        end
    end
    return nil
end

local function teleportToATM(atm)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and atm then
        forceDisableCollision(atm)
        local targetCFrame = atm:IsA("Model") and atm:GetPivot() or atm.CFrame
        enableFlyNoclip(true)
        root.Velocity = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
        root.CFrame = targetCFrame * CFrame.new(0, 0.8, 0.8)
        task.wait(0.1)
    end
end

local function findDropOffPoint()
    local path = Services.Workspace:FindFirstChild("Game") 
        and Services.Workspace.Game:FindFirstChild("Jobs") 
        and Services.Workspace.Game.Jobs:FindFirstChild("CriminalDropOffSpawners") 
        and Services.Workspace.Game.Jobs.CriminalDropOffSpawners:FindFirstChild("CriminalDropOffSpawnerPermanent") 
        and Services.Workspace.Game.Jobs.CriminalDropOffSpawners.CriminalDropOffSpawnerPermanent:FindFirstChild("CriminalDropOffPoint")
    if path then return path end

    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj.Name == "CriminalDropOffPoint" then return obj end
    end
    return nil
end

local function completeCriminalJob()
    local dropOffPoint = findDropOffPoint()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:FindFirstChild("HumanoidRootPart")
    if dropOffPoint and root then
        forceDisableCollision(dropOffPoint)
        local targetCFrame = dropOffPoint:IsA("Model") and dropOffPoint:GetPivot() or dropOffPoint.CFrame
        if targetCFrame then
            enableFlyNoclip(true)
            root.Velocity = Vector3.new(0, 0, 0)
            root.CFrame = targetCFrame * CFrame.new(0, 1.2, 0)
            task.wait(0.3)
            for i = 1, 3 do
                pcall(function() AttemptCriminalJobComplete:InvokeServer(dropOffPoint) end)
                task.wait(0.3)
            end
            task.wait(0.5)
            return true
        end
    end
    return false
end

local TabCriminal = Window:Tab({ Title = "Criminal / Side Job", Icon = "briefcase-business" })
local SecCriminal = TabCriminal:Section({ Title = "Criminal Operations (ATM Bust)", Opened = true })

CriminalCounterLabel = makeStatusParagraph(SecCriminal, "Status Tas", "Tas: 0 / 10")
CriminalStatusText = makeStatusParagraph(SecCriminal, "Status Sistem", "Status: Off")

SecCriminal:Input({
    Title = "Batas Tas (Bust Target)",
    Value = "10",
    Placeholder = "Masukkan batas tas",
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            TargetBustLimit = math.floor(num)
            updateBagUI()
        end
    end
})

local function startCriminalFarmLoop()
    startCriminalNoclip()
    task.spawn(function()
        CriminalStatusText:Set("Status Sistem", "Status: Ambil Job...")
        pcall(function() RequestStartJobSession:FireServer("Criminal", "jobPad") end)
        task.wait(1)
        table.clear(BustedATMs)

        while CriminalAutoFarm do
            local currentBags = getLootBagCount()
            updateBagUI()

            if currentBags >= TargetBustLimit then
                CriminalStatusText:Set("Status Sistem", "Status: Tas Penuh! Setor...")
                local depositCompleted = completeCriminalJob()
                if depositCompleted and WebhookAutoEvents then
                    sendDiscordWebhook(
                        "Criminal Setor Selesai",
                        "Setor criminal berhasil diselesaikan.",
                        0x57F287,
                        true
                    )
                end
                updateBagUI()
                teleportToSafeZone()
                task.wait(1)
            end

            CriminalStatusText:Set("Status Sistem", "Status: Scanning Icon ATM...")
            local targetATM = getActiveATM()
            
            if targetATM and targetATM.Parent then
                teleportToATM(targetATM)
                local isBustSuccessful = false
                local retryCount = 0
                local maxRetries = 3

                while CriminalAutoFarm and retryCount < maxRetries and not isBustSuccessful do
                    if hasIcon(targetATM) then
                        local bagBefore = getLootBagCount()
                        CriminalStatusText:Set("Status Sistem", string.format("Status: Busting... [%d/%d]", retryCount + 1, maxRetries))
                        pcall(function() AttemptATMBustStart:InvokeServer(targetATM) end)
                        task.wait(3.1) 

                        if not CriminalAutoFarm then break end

                        pcall(function() AttemptATMBustComplete:InvokeServer(targetATM) end)
                        task.wait(0.2)
                        updateBagUI()
                        local bagAfter = getLootBagCount()

                        if bagAfter > bagBefore then
                            isBustSuccessful = true
                            CriminalStatusText:Set("Status Sistem", "Status: Bust Berhasil!")
                            if WebhookAutoEvents then
                                sendDiscordWebhook(
                                    "Criminal Bust Berhasil",
                                    "Bust ATM berhasil. Tas bertambah dari " .. tostring(bagBefore) .. " menjadi " .. tostring(bagAfter) .. ".",
                                    0x57F287,
                                    true
                                )
                            end
                        else
                            retryCount = retryCount + 1
                            CriminalStatusText:Set("Status Sistem", "Status: Tas Gak Nambah, Ulangi...")
                            task.wait(0.3)
                        end
                    else
                        break
                    end
                end

            BustedATMs[targetATM] = true

                if isBustSuccessful then
                    CriminalStatusText:Set("Status Sistem", "Status: Safe Zone (Bawah Tanah)...")
                    teleportToSafeZone()
                    task.wait(0.8)
                else
                    CriminalStatusText:Set("Status Sistem", "Status: Gagal Bust, Cari ATM Lain...")
                    task.wait(0.2)
                end
            else
                CriminalStatusText:Set("Status Sistem", "Status: Waiting Respawn...")
                teleportToSafeZone()
                task.wait(2)
                table.clear(BustedATMs)
            end
        end
    end)
end

SecCriminal:Toggle({
    Title = "Aktifkan Criminal Automation",
    Value = false,
    Callback = function(v)
        CriminalAutoFarm = v
        if v then
            CriminalStatusText:Set("Status Sistem", "Status: Running")
            startCriminalFarmLoop()
        else
            CriminalStatusText:Set("Status Sistem", "Status: Off")
            stopNoclipHandler()
            if SafePlatform then SafePlatform:Destroy() end
        end
    end
})

-- ============================================================
-- // TAB 3: MONEY ESTIMATOR
-- // Sumber data:
-- // 1) PlayerGui > HUD > MainHUD > SideHUD > BL-Row3 > Money...
-- // 2) PlayerGui > HUD > MainHUD > Topbar > Row-topbar > RightSide
-- //    > BL-Row3 > money_MOBILE > Holder > Money...
-- ============================================================
local function findMoneyTextObject()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local hud = playerGui:FindFirstChild("HUD")

    -- Patch game dapat memiliki dua MainHUD:
    -- 1) PlayerGui > HUD > HUD > MainHUD
    -- 2) PlayerGui > MainHUD (yang bawah pada hasil scan terbaru).
    -- Keduanya dipindai agar object yang aktif selalu ketemu.
    local mainHUDs = {}
    local function addMainHUD(obj)
        if obj and obj.Name == "MainHUD" then
            for _, existing in ipairs(mainHUDs) do
                if existing == obj then return end
            end
            table.insert(mainHUDs, obj)
        end
    end

    for _, obj in ipairs(playerGui:GetDescendants()) do
        addMainHUD(obj)
    end
    local candidateRows = {}
    local function addCandidateRow(row)
        if not row then return end
        for _, existing in ipairs(candidateRows) do
            if existing == row then return end
        end
        table.insert(candidateRows, row)
    end

    for _, mainHUD in ipairs(mainHUDs) do
        -- Ambil semua BL-Row3 di tiap MainHUD, termasuk yang berada di Topbar
        -- dan struktur mobile money yang berubah antar patch.
        if mainHUD.Name == "BL-Row3" then addCandidateRow(mainHUD) end
        for _, obj in ipairs(mainHUD:GetDescendants()) do
            if obj.Name == "BL-Row3" then
                addCandidateRow(obj)
            end
        end
    end

    -- Pada patch tertentu Topbar menjadi sibling dari MainHUD di dalam HUD.
    -- Scan langsung seluruh HUD agar jalur HUD > Topbar > BL-Row3 ikut terbaca.
    if hud then
        for _, obj in ipairs(hud:GetDescendants()) do
            if obj.Name == "BL-Row3" then
                addCandidateRow(obj)
            end
        end
    end

    -- Prioritaskan TextLabel bernama Money, lalu fallback ke object yang namanya
    -- mengandung "Money" karena nama key parent dapat berbeda antar patch game.
    local fallback = nil
    for _, row in ipairs(candidateRows) do
        local objects = { row }
        for _, obj in ipairs(row:GetDescendants()) do
            table.insert(objects, obj)
        end
        for _, obj in ipairs(objects) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                if obj.Name == "Money" then return obj end
                if not fallback and obj.Name:lower():find("money") then
                    fallback = obj
                end
            end
        end
    end
    return fallback
end

local function parseMoneyValue(rawText)
    if type(rawText) ~= "string" then return nil end
    local cleaned = rawText:gsub("%s", ""):gsub("$", ""):gsub(",", "")
    local numberPart, suffix = cleaned:match("([%d%.]+)([kKmMbB]?)")
    local number = tonumber(numberPart)
    if not number then
        number = tonumber(cleaned:match("[%d%.]+"))
        suffix = ""
    end
    if not number then return nil end

    local multipliers = { k = 1000, m = 1000000, b = 1000000000 }
    return number * (multipliers[(suffix or ""):lower()] or 1)
end

local function readCurrentMoney()
    local moneyObject = findMoneyTextObject()
    if not moneyObject then return nil end
    return parseMoneyValue(moneyObject.Text)
end

local function formatMoney(value)
    value = tonumber(value) or 0
    local sign = value < 0 and "-" or ""
    value = math.abs(math.floor(value + 0.5))
    local formatted = tostring(value)
    while true do
        local replaced, count = formatted:gsub("^(%d+)(%d%d%d)", "%1,%2")
        formatted = replaced
        if count == 0 then break end
    end
    return sign .. "$" .. formatted
end

local TabMoney = Window:Tab({ Title = "Money Estimator", Icon = "chart-no-axes-combined" })
local SecMoney = TabMoney:Section({ Title = "Money Tracking & Estimation", Opened = true })

local MoneyCurrentLabel = makeStatusParagraph(SecMoney, "Total Money Keseluruhan", "Membaca HUD...")
local MoneyHourlyLabel = makeStatusParagraph(SecMoney, "Estimasi Per Jam", "Menunggu data...")
local Money24HourLabel = makeStatusParagraph(SecMoney, "Estimasi 24 Jam", "Menunggu data...")
local MoneyIncomeLabel = makeStatusParagraph(SecMoney, "Total Money Penghasilan", "Menunggu data...")
local MoneyRuntimeLabel = makeStatusParagraph(SecMoney, "Durasi Tracking", "00:00:00")

local moneyTrackingStartedAt = os.clock()
local moneyBaseline = nil

local function formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function updateMoneyEstimator()
    local currentMoney = readCurrentMoney()
    if not currentMoney then
        MoneyCurrentLabel:Set("Total Money Keseluruhan", "HUD Money tidak ditemukan")
        return
    end

    if not moneyBaseline then moneyBaseline = currentMoney end

    local elapsed = math.max(os.clock() - moneyTrackingStartedAt, 1)
    local income = currentMoney - moneyBaseline
    local hourly = income / elapsed * 3600

    MoneyCurrentLabel:Set("Total Money Keseluruhan", formatMoney(currentMoney))
    MoneyHourlyLabel:Set("Estimasi Per Jam", formatMoney(hourly))
    Money24HourLabel:Set("Estimasi 24 Jam", formatMoney(hourly * 24))
    MoneyIncomeLabel:Set("Total Money Penghasilan", formatMoney(income))
    MoneyRuntimeLabel:Set("Durasi Tracking", formatDuration(elapsed))
end

SecMoney:Button({
    Title = "Reset Baseline Tracking",
    Icon = "rotate-ccw",
    Callback = function()
        local currentMoney = readCurrentMoney()
        if currentMoney then
            moneyBaseline = currentMoney
            moneyTrackingStartedAt = os.clock()
            updateMoneyEstimator()
        end
    end,
})

task.spawn(function()
    while true do
        pcall(updateMoneyEstimator)
        task.wait(1)
    end
end)

-- ============================================================
-- // TAB 4: DISCORD WEBHOOK
-- // Payload menggunakan Discord Execute Webhook + Embed JSON.
-- ============================================================
local TabWebhook = Window:Tab({ Title = "Discord Webhook", Icon = "webhook" })
local SecWebhook = TabWebhook:Section({ Title = "Webhook Configuration", Opened = true })

local WebhookURL = ""
local WebhookConfigFile = "REN_X_ATOMIC_WEBHOOK_CONFIG.json"

local function saveWebhookConfig()
    if not writefile then return false end
    local ok = pcall(function()
        local payload = {
            url = WebhookURL,
            botName = WebhookBotName,
            enabled = WebhookEnabled,
            autoEvents = WebhookAutoEvents,
            cooldown = WebhookCooldown,
        }
        writefile(WebhookConfigFile, game:GetService("HttpService"):JSONEncode(payload))
    end)
    return ok
end

if isfile and readfile then
    pcall(function()
        local saved = game:GetService("HttpService"):JSONDecode(readfile(WebhookConfigFile))
        if type(saved) == "table" then
            WebhookURL = tostring(saved.url or "")
            if tostring(saved.botName or "") ~= "" then WebhookBotName = tostring(saved.botName):sub(1, 80) end
            WebhookEnabled = saved.enabled == true
            WebhookAutoEvents = saved.autoEvents == true
            if tonumber(saved.cooldown) and tonumber(saved.cooldown) >= 0 then
                WebhookCooldown = math.floor(tonumber(saved.cooldown))
            end
        end
    end)
end

local WebhookStatus = makeStatusParagraph(SecWebhook, "Webhook Status", "Belum dikonfigurasi")

local function getFarmMode()
    if DeliveryState and DeliveryState.AutoFarm then
        return "Job Delivery • RUNNING"
    end
    if CriminalAutoFarm then
        return "Criminal / ATM • RUNNING"
    end
    return "Idle / OFF"
end

local function getWebhookStats()
    local currentMoney = readCurrentMoney()
    local elapsed = math.max(os.clock() - moneyTrackingStartedAt, 1)
    local income = (currentMoney and moneyBaseline) and (currentMoney - moneyBaseline) or 0
    local hourly = income / elapsed * 3600
    return currentMoney, income, hourly, elapsed
end

local function getHttpRequest()
    local env = nil
    pcall(function()
        if getgenv then env = getgenv() end
    end)

    return (env and (env.request or env.http_request))
        or request
        or http_request
        or (syn and syn.request)
        or (http and http.request)
        or (fluxus and fluxus.request)
        or (Electron and Electron.request)
end

local function getResponseStatusCode(response)
    if type(response) ~= "table" then return 0 end
    return tonumber(response.StatusCode or response.status_code or response.Status or response.status) or 0
end

local function getResponseBody(response)
    if type(response) ~= "table" then return tostring(response or "") end
    return tostring(response.Body or response.body or response.ResponseBody or response.response_body or "")
end

local function isDiscordWebhookURL(url)
    return type(url) == "string"
        and (url:match("^https://discord%.com/api/webhooks/")
            or url:match("^https://discordapp%.com/api/webhooks/")) ~= nil
end

local function buildWebhookPayload(title, description, color)
    local currentMoney, income, hourly, elapsed = getWebhookStats()
    local farmMode = getFarmMode()
    local fields = {
        { name = "Player", value = "protect", inline = true },
        { name = "Farm Mode", value = farmMode, inline = true },
        { name = "Money Sekarang", value = currentMoney and formatMoney(currentMoney) or "Tidak terbaca", inline = true },
        { name = "Penghasilan", value = formatMoney(income), inline = true },
        { name = "Estimasi / Jam", value = formatMoney(hourly), inline = true },
        { name = "Estimasi 24 Jam", value = formatMoney(hourly * 24), inline = true },
        { name = "Runtime", value = formatDuration(elapsed), inline = true },
    }

    if farmMode:find("Delivery", 1, true) then
        table.insert(fields, 4, {
            name = "Paket Selesai",
            value = tostring(DeliveryState.CompletedCount),
            inline = true,
        })
    elseif farmMode:find("Criminal", 1, true) then
        table.insert(fields, 4, {
            name = "Tas Criminal",
            value = tostring(getLootBagCount()) .. " / " .. tostring(TargetBustLimit),
            inline = true,
        })
    end

    return {
        username = WebhookBotName,
        embeds = {{
            title = title,
            description = description,
            color = color or 0x4C9AFF,
            fields = fields,
            footer = { text = "REN X ATOMIC • Live Farm Stats" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
        allowed_mentions = { parse = {} },
    }
end

sendDiscordWebhook = function(title, description, color, force)
    if _G.REN_X_ATOMIC_WEBHOOK_SESSION ~= ThisWebhookSession then
        return false
    end
    if not WebhookEnabled then
        WebhookStatus:Set("Webhook Status", "Aktifkan toggle webhook dulu")
        return false
    end
    if not isDiscordWebhookURL(WebhookURL) then
        WebhookStatus:Set("Webhook Status", "URL webhook tidak valid")
        return false
    end

    if not force and os.clock() - (WebhookLastSentAt or 0) < WebhookCooldown then
        return false
    end

    local httpRequest = getHttpRequest()
    if not httpRequest then
        WebhookStatus:Set("Webhook Status", "Executor tidak menyediakan request()")
        return false
    end

    local ok, response = pcall(function()
        local body = game:GetService("HttpService"):JSONEncode(
            buildWebhookPayload(title, description, color)
        )
        local cleanURL = WebhookURL:gsub("%s+", "")
        local separator = cleanURL:find("?", 1, true) and "&" or "?"
        return httpRequest({
            Url = cleanURL .. separator .. "wait=true",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)

    if not ok then
        WebhookStatus:Set("Webhook Status", "Request error: " .. tostring(response):sub(1, 90))
        return false
    end

    local statusCode = getResponseStatusCode(response)
    if statusCode >= 200 and statusCode < 300 then
        WebhookLastSentAt = os.clock()
        WebhookStatus:Set("Webhook Status", "Embed berhasil terkirim ke Discord")
        return true
    end
    local responseBody = getResponseBody(response):gsub("%s+", " "):sub(1, 140)
    if responseBody == "" then responseBody = "Tidak ada detail response" end
    WebhookStatus:Set(
        "Webhook Status",
        "Discord menolak request (HTTP " .. tostring(statusCode) .. "): " .. responseBody
    )
    return false
end

SecWebhook:Paragraph({
    Title = "Live Farm Stats • JSON Embed",
    Desc = "Embed berisi player, mode auto-farm, money, penghasilan, estimasi per jam/24 jam, delivery selesai, tas criminal, runtime, dan timestamp.",
})

SecWebhook:Input({
    Title = "Discord Webhook URL",
    Desc = "URL disimpan hanya selama runtime script.",
    Placeholder = "https://discord.com/api/webhooks/...",
    Value = WebhookURL,
    Callback = function(value)
        WebhookURL = tostring(value or ""):gsub("%s+", "")
        WebhookStatus:Set("Webhook Status", isDiscordWebhookURL(WebhookURL) and "URL valid" or "Menunggu URL valid")
        saveWebhookConfig()
    end,
})

SecWebhook:Input({
    Title = "Nama Bot Webhook",
    Value = WebhookBotName,
    Placeholder = "Nama yang tampil di Discord",
    Callback = function(value)
        local name = tostring(value or ""):sub(1, 80)
        if name ~= "" then WebhookBotName = name end
        saveWebhookConfig()
    end,
})

SecWebhook:Toggle({
    Title = "Aktifkan Discord Webhook",
    Desc = "Mengizinkan pengiriman webhook.",
    Value = WebhookEnabled,
    Callback = function(value)
        WebhookEnabled = value
        WebhookStatus:Set("Webhook Status", value and "Aktif" or "Nonaktif")
        saveWebhookConfig()
    end,
})

SecWebhook:Toggle({
    Title = "Auto Notify Farm Event",
    Desc = "Kirim hanya saat event job: delivery setiap paket selesai; criminal setiap bust berhasil dan setiap setor selesai. Tidak dipicu oleh perubahan money.",
    Value = WebhookAutoEvents,
    Callback = function(value)
        WebhookAutoEvents = value
        WebhookStatus:Set("Webhook Status", value and "Auto event aktif" or "Auto event nonaktif")
        saveWebhookConfig()
    end,
})

SecWebhook:Input({
    Title = "Cooldown Notifikasi (detik)",
    Value = tostring(WebhookCooldown),
    Placeholder = "Contoh: 5",
    Callback = function(value)
        local seconds = tonumber(value)
        if seconds and seconds >= 0 then
            WebhookCooldown = math.floor(seconds)
            saveWebhookConfig()
        end
    end,
})

SecWebhook:Button({
    Title = "Save Webhook Config",
    Icon = "save",
    Callback = function()
        WebhookStatus:Set("Webhook Status", saveWebhookConfig() and "Config berhasil disimpan" or "Executor tidak support writefile")
    end,
})

SecWebhook:Button({
    Title = "Reset Webhook Config",
    Icon = "rotate-ccw",
    Callback = function()
        WebhookURL = ""
        WebhookBotName = "REN X ATOMIC"
        WebhookEnabled = false
        WebhookAutoEvents = false
        WebhookCooldown = 5
        if writefile then pcall(writefile, WebhookConfigFile, "{}") end
        WebhookStatus:Set("Webhook Status", "Config direset; execute ulang untuk menerapkan field UI")
    end,
})

SecWebhook:Button({
    Title = "Test Kirim Embed JSON",
    Icon = "send",
    Callback = function()
        sendDiscordWebhook(
            "Webhook Connected",
            "REN X ATOMIC berhasil terhubung ke Discord.",
            0x57F287,
            true
        )
    end,
})

pcall(function() Window:Open() end)