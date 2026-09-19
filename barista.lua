-- JawaDeobf_Instace298_$?# Bypassed API EXECUTE
-- LOLER VM

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ── WindUI ────────────────────────────────────────────────────
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title        = "DX-SR Hub",
    Icon         = "coffee",
    Author       = "DX-SR",
    Folder       = "DX-SR",
    Size         = UDim2.fromOffset(580, 460),
    MinSize      = Vector2.new(560, 350),
    MaxSize      = Vector2.new(850, 560),
    ToggleKey    = Enum.KeyCode.V,
    Transparent  = true,
    Theme        = "Dark",
    Resizable    = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar    = false,
    ScrollBarEnabled = false,
})

Window:Tag({ Title = "v0.0.0.3",  Icon = "github",      Color = Color3.fromHex("#30ff6a"), Radius = 13 })
Window:Tag({ Title = "DX-SR Hub", Icon = "text-cursor", Color = Color3.fromHex("#1E3A8A"), Radius = 13 })

WindUI:Popup({
    Title   = "DX-SR Hub",
    Icon    = "coffee",
    Content = "Barista Autofarm v0.0.0.3",
    Buttons = {{ Title = "Continue", Icon = "arrow-right", Callback = function() end, Variant = "Primary" }},
})

-- ── Section → Tab ─────────────────────────────────────────────
local FarmingSection = Window:Section({ Title = "Farming", Icon = "coffee", Opened = true })
local mainTab        = FarmingSection:Tab({ Title = "Barista",     Icon = "coffee"   })
local settingsTab    = FarmingSection:Tab({ Title = "Settings",    Icon = "settings" })
local themeTab       = FarmingSection:Tab({ Title = "Theme",       Icon = "palette"  })
local infoTab        = FarmingSection:Tab({ Title = "Information", Icon = "info"     })

-- ── State ─────────────────────────────────────────────────────
local baristaEnabled  = false
local baristaWorking  = false
local baristaLastAct  = os.clock()
local baristaStuck    = 0
local baristaJobs     = 0

-- Tuning
local TWEEN_MAX   = 60
local START_POS   = Vector3.new(-4989.8, 5.5, -715)
local BREW_POS    = Vector3.new(-5000.2, 5.6, -792)
local REGISTER_POS= Vector3.new(-4997.1, 5.6, -755)
local SUPPLY_POS  = Vector3.new(-5116.8, 5.8, -670.9)
local DROP_CHECK  = Vector3.new(-5000,   5.5, -760)

-- ── Helpers ───────────────────────────────────────────────────
local function getChar()
    return LocalPlayer.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- Seat teleport (anti-kick bypass)
local function seatTeleport(targetCF)
    local hrp  = getHRP()
    local hum  = getHum()
    local char = getChar()
    local anim = char and char:FindFirstChild("Animate")
    if not hrp or not hum then return end

    if anim then anim.Disabled = true end

    local seat = Instance.new("Seat")
    seat.Size         = Vector3.new(2, 0.2, 2)
    seat.Transparency = 1
    seat.CanCollide   = false
    seat.Anchored     = true
    seat.CFrame       = hrp.CFrame
    seat.Parent       = workspace

    hum.Sit = true
    seat:Sit(hum)

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Parent   = hrp

    task.wait(0.5)
    seat.Anchored = false

    local tgt = targetCF * CFrame.new(0, 0.01, 0)
    local mid = hrp.CFrame:Lerp(tgt, 0.5)
    seat.CFrame = mid; hrp.CFrame = mid
    task.wait(0.1)
    seat.CFrame = tgt; hrp.CFrame = tgt
    seat.Anchored = true

    task.wait(1.6)
    bv:Destroy()
    hum.Sit = false
    if anim then anim.Disabled = false end
    task.wait(0.3)
    seat:Destroy()
    hrp.AssemblyLinearVelocity = Vector3.zero
    workspace.CurrentCamera.CameraSubject = hum
end

-- Smooth tween teleport (dalam area barista)
local function baristaTeleport(targetCF)
    local hrp  = getHRP()
    local hum  = getHum()
    local char = getChar()
    if not hrp or not hum then return end

    local tgtPos  = targetCF.Position
    local curPos  = hrp.Position
    local dist3D  = (tgtPos - curPos).Magnitude
    local distFlat= (Vector3.new(tgtPos.X,0,tgtPos.Z) - Vector3.new(curPos.X,0,curPos.Z)).Magnitude

    if dist3D < 3.5 or distFlat < 2.5 then return end
    if hum.Sit then hum.Sit = false; task.wait(0.02) end

    hum.AutoRotate = false
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    local y        = tgtPos.Y
    local startPos = Vector3.new(hrp.Position.X, y, hrp.Position.Z)
    local endPos   = Vector3.new(tgtPos.X,       y, tgtPos.Z)

    local seat = Instance.new("Seat")
    seat.Name         = "barista_tp_seat"
    seat.Size         = Vector3.new(1,1,1)
    seat.Transparency = 1
    seat.CanCollide   = false
    seat.CFrame       = CFrame.new(startPos) * targetCF.Rotation
    seat.Parent       = workspace

    local weld   = Instance.new("WeldConstraint")
    weld.Part0   = seat
    weld.Part1   = hrp
    weld.Parent  = seat

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Velocity = Vector3.zero
    bv.Parent   = seat

    -- Keep seated & no collide
    local origCollide = {}
    local seatConn = RunService.Stepped:Connect(function()
        if hrp then
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        if seat and seat.Parent then
            seat.AssemblyLinearVelocity  = Vector3.zero
            seat.AssemblyAngularVelocity = Vector3.zero
        end
        if hum.SeatPart ~= seat then
            hum.Sit = true
            seat:Sit(hum)
        end
    end)
    local colConn = RunService.Stepped:Connect(function()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                    origCollide[p] = true
                end
            end
        end
    end)

    local duration = math.clamp(distFlat / TWEEN_MAX, 0.02, 1)
    local t0       = os.clock()

    while baristaEnabled and hrp and char and char.Parent
        and (os.clock() - t0) < duration do
        local alpha = math.min((os.clock() - t0) / duration, 1)
        local pos   = startPos:Lerp(endPos, alpha)
        local cf    = CFrame.new(pos) * targetCF.Rotation
        seat.CFrame = cf
        hrp.CFrame  = cf
        task.wait()
    end

    seatConn:Disconnect()
    colConn:Disconnect()

    for part in pairs(origCollide) do
        if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
            part.CanCollide = true
        end
    end

    bv:Destroy()
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hum.Sit = false
    seat:Destroy()

    hum.AutoRotate = true
    hum:ChangeState(Enum.HumanoidStateType.Running)
    hrp.CFrame = CFrame.new(endPos) * targetCF.Rotation
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

-- ProximityPrompt handler: handle End Shift → Start Shift sequence
local function promptHandler(parent)
    if not parent then return false end

    local prompt = parent:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt then return false end

    -- Tunggu prompt enabled
    if not prompt.Enabled then
        local t0 = os.clock()
        while baristaEnabled and not prompt.Enabled and (os.clock()-t0) < 2.5 do
            task.wait(0.2)
            if not prompt.Parent then
                prompt = parent:FindFirstChildWhichIsA("ProximityPrompt")
            end
            if not prompt then return false end
        end
    end

    if not prompt or not prompt.Enabled then return false end
    prompt.HoldDuration = 0

    -- Handle "End Shift" dulu kalau ada
    if prompt.ActionText == "End Shift" then
        local t0, lastClick = os.clock(), 0
        while baristaEnabled and (os.clock()-t0) < 6 do
            if not prompt.Parent then
                prompt = parent:FindFirstChildWhichIsA("ProximityPrompt")
            end
            if not prompt or prompt.ActionText == "Start Shift" then break end
            if (os.clock()-lastClick) > 1.2 then
                lastClick = os.clock()
                pcall(function()
                    prompt.HoldDuration = 0
                    fireproximityprompt(prompt)
                end)
            end
            task.wait(0.2)
        end
        task.wait(0.3)
    end

    if not prompt or not prompt.Parent then
        prompt = parent:FindFirstChildWhichIsA("ProximityPrompt")
    end

    -- Handle "Start Shift"
    if prompt and prompt.ActionText == "Start Shift" then
        local t0, lastClick = os.clock(), 0
        while baristaEnabled and (os.clock()-t0) < 6 do
            if not prompt.Parent then
                prompt = parent:FindFirstChildWhichIsA("ProximityPrompt")
            end
            if not prompt or prompt.ActionText == "End Shift" then break end
            if (os.clock()-lastClick) > 1.2 then
                lastClick = os.clock()
                pcall(function()
                    prompt.HoldDuration = 0
                    fireproximityprompt(prompt)
                end)
            end
            task.wait(0.2)
        end
        task.wait(0.3)
    end

    if not prompt or not prompt.Parent then
        prompt = parent:FindFirstChildWhichIsA("ProximityPrompt")
    end

    return prompt and prompt.ActionText == "End Shift"
end

-- ── Main Barista Loop ─────────────────────────────────────────
task.spawn(function()
    while task.wait(0.1) do
        if not baristaEnabled then continue end

        local char = getChar()
        local hrp  = getHRP()
        local hum  = getHum()

        if not char or not hrp or not hum or hum.Health <= 0 then
            task.wait(0.5); continue
        end

        -- Pastikan team Barista
        if not LocalPlayer.Team or LocalPlayer.Team.Name ~= "Barista" then
            WindUI:Notify({ Title = "Barista", Content = "Masuk job Barista...", Duration = 3, Icon = "coffee" })
            local oldChar = LocalPlayer.Character
            game:GetService("ReplicatedStorage")
                :WaitForChild("JobEvents")
                :WaitForChild("TeamChangeRequest")
                :FireServer("Barista", 11378976, 1, 0, "Detector")

            local t0 = os.clock()
            while (not LocalPlayer.Character
                or LocalPlayer.Character == oldChar
                or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
                and (os.clock()-t0) < 5 do
                task.wait(0.2)
            end
            task.wait(1.5)

            local newHRP = getHRP()
            if newHRP then
                seatTeleport(CFrame.new(START_POS))
                task.wait(0.5)
            end
            continue
        end

        -- Referensi part
        local job          = workspace:FindFirstChild("BaristaJob")
        local interactions = job and job:FindFirstChild("Interactions")
        if not interactions then task.wait(0.5); continue end

        local startParent    = interactions:FindFirstChild("StartPart")
        local startPart      = startParent and startParent:FindFirstChild("StartPart")
        local machineParent  = interactions:FindFirstChild("MachinePart")
        local machinePart    = machineParent and machineParent:FindFirstChild("MachinePart")
        local registerParent = interactions:FindFirstChild("RegisterPart")
        local registerPart   = registerParent and registerParent:FindFirstChild("RegisterPart")
        local supplyParent   = interactions:FindFirstChild("SupplyPart")
        local supplyPart     = supplyParent and supplyParent:FindFirstChild("SupplyPart")

        local startPrompt    = startPart    and startPart:FindFirstChildWhichIsA("ProximityPrompt")
        local machinePrompt  = machinePart  and machinePart:FindFirstChildWhichIsA("ProximityPrompt")
        local registerPrompt = registerPart and registerPart:FindFirstChildWhichIsA("ProximityPrompt")
        local supplyPrompt   = supplyPart   and supplyPart:FindFirstChildWhichIsA("ProximityPrompt")

        local distToDrop  = (Vector3.new(DROP_CHECK.X,0,DROP_CHECK.Z)
            - Vector3.new(hrp.Position.X,0,hrp.Position.Z)).Magnitude
        local distToStart = (Vector3.new(START_POS.X,0,START_POS.Z)
            - Vector3.new(hrp.Position.X,0,hrp.Position.Z)).Magnitude
        local canStart    = startPrompt and startPrompt.Enabled
            and startPrompt.ActionText == "Start Shift"

        -- Belum kerja / terlalu jauh / bisa start shift
        if not baristaWorking or distToDrop > 80 or canStart then
            if distToDrop > 80 then
                seatTeleport(CFrame.new(START_POS))
                task.wait(0.5)
            elseif distToStart > 6 then
                baristaTeleport(CFrame.new(START_POS))
                task.wait(0.3)
            end

            local ok = promptHandler(startPart)
            if not ok then task.wait(0.5); continue end

            baristaWorking = true
            baristaLastAct = os.clock()
            baristaTeleport(CFrame.new(BREW_POS))
            task.wait(0.08)
            continue
        end

        -- Supply
        if supplyPrompt and supplyPrompt.Enabled then
            baristaLastAct = os.clock()
            seatTeleport(CFrame.new(SUPPLY_POS))
            task.wait(0.4)
            if supplyPrompt and supplyPrompt.Enabled then
                pcall(function()
                    supplyPrompt.HoldDuration = 0
                    fireproximityprompt(supplyPrompt)
                end)
            end
            task.wait(0.6)
            seatTeleport(CFrame.new(BREW_POS))
            task.wait(0.4)
            continue
        end

        -- Register / serve
        if registerPrompt and registerPrompt.Enabled then
            baristaLastAct = os.clock()
            baristaTeleport(CFrame.new(REGISTER_POS))
            task.wait(0.08)
            if registerPrompt and registerPrompt.Enabled then
                pcall(function()
                    registerPrompt.HoldDuration = 0
                    fireproximityprompt(registerPrompt)
                end)
            end
            task.wait(0.1)

            baristaJobs += 1
            WindUI:Notify({
                Title   = "Barista",
                Content = "Order #" .. baristaJobs .. " selesai!",
                Duration = 2,
                Icon    = "coffee",
            })

            baristaTeleport(CFrame.new(BREW_POS))
            task.wait(0.08)
            continue
        end

        -- Machine / brew
        if machinePrompt and machinePrompt.Enabled then
            baristaLastAct = os.clock()
            local distBrew = (BREW_POS - hrp.Position).Magnitude
            if distBrew > 3 then
                baristaTeleport(CFrame.new(BREW_POS))
                task.wait(0.08)
            end
            if machinePrompt and machinePrompt.Enabled then
                pcall(function()
                    machinePrompt.HoldDuration = 0
                    fireproximityprompt(machinePrompt)
                end)
            end

            -- Tunggu register prompt / minigame
            local t0 = os.clock()
            while baristaEnabled and (os.clock()-t0) < 6 do
                baristaLastAct = os.clock()
                if registerPrompt and registerPrompt.Enabled then break end
                local bGui  = PlayerGui:FindFirstChild("BaristaGUI")
                local bMini = bGui and bGui:FindFirstChild("MinigameFrame")
                if not (bMini and bMini.Visible) and (os.clock()-t0) > 1 then break end
                task.wait(0.08)
            end
            continue
        end

        -- Idle — drift ke brew pos
        local distIdle = (Vector3.new(BREW_POS.X,0,BREW_POS.Z)
            - Vector3.new(hrp.Position.X,0,hrp.Position.Z)).Magnitude
        if distIdle > 3.5 then
            baristaTeleport(CFrame.new(BREW_POS))
        end

        -- Stuck detection 18 detik
        if (os.clock() - baristaLastAct) > 18 then
            baristaLastAct = os.clock()
            baristaStuck  += 1
            WindUI:Notify({
                Title   = "Barista",
                Content = "Stuck #" .. baristaStuck .. " — refresh shift...",
                Duration = 3,
                Icon    = "coffee",
            })

            baristaTeleport(CFrame.new(START_POS))
            task.wait(0.3)
            baristaWorking = false

            local ok = promptHandler(startPart)
            if not ok then task.wait(0.5); continue end

            baristaWorking = true
            baristaLastAct = os.clock()
            baristaTeleport(CFrame.new(BREW_POS))
            task.wait(0.08)
        end
    end
end)

-- ── Main Tab UI ───────────────────────────────────────────────
local farmSection = mainTab:Section({ Title = "Autofarm Barista", Opened = true })

local statusLabel = farmSection:Paragraph({ Title = "Status",       Desc = "Idle" })
local stepLabel   = farmSection:Paragraph({ Title = "Jobs Done",    Desc = "0"    })
local stuckLabel  = farmSection:Paragraph({ Title = "Stuck Count",  Desc = "0"    })

farmSection:Toggle({
    Title    = "Barista Autofarm",
    Desc     = "Auto barista CDID — brew & serve",
    Default  = false,
    Flag     = "AutofarmBarista",
    Callback = function(state)
        baristaEnabled = state
        baristaWorking = false
        baristaLastAct = os.clock()
        if state then
            WindUI:Notify({
                Title   = "Barista Autofarm",
                Content = "CDID BARISTA AUTOFARM AKTIF!",
                Duration = 3,
                Icon    = "coffee",
            })
        else
            WindUI:Notify({ Title = "Barista Autofarm", Content = "Stopped.", Duration = 2 })
        end
    end,
})

-- Status loop
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            statusLabel:SetDesc(baristaEnabled and "Running" or "Idle")
            stepLabel:SetDesc(tostring(baristaJobs))
            stuckLabel:SetDesc(tostring(baristaStuck))
        end)
    end
end)

-- ── Settings Tab ──────────────────────────────────────────────
local cfgSection  = settingsTab:Section({ Title = "Configuration",       Opened = true })
local loadSection = settingsTab:Section({ Title = "Load / Delete Config", Opened = true })

local CONFIG_DIR = "/config/"
local CONFIG_EXT = ".json"
local ConfigManager = { Flags = {}, AllConfigs = {} }

function ConfigManager:Refresh()
    self.AllConfigs = {}
    if not isfolder(CONFIG_DIR) then return end
    for _, entry in ipairs(listfiles(CONFIG_DIR)) do
        local f = entry:match("([^/\\]+)$")
        if f then
            local stem = f:match("^(.+)" .. CONFIG_EXT .. "$")
            if stem then table.insert(self.AllConfigs, stem) end
        end
    end
end

function ConfigManager:Save(name)
    if not name or name == "" then
        WindUI:Notify({ Title = "Config", Content = "Masukkan nama config!", Duration = 3 })
        return
    end
    if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
    writefile(CONFIG_DIR .. name .. CONFIG_EXT, HttpService:JSONEncode(self.Flags))
    WindUI:Notify({ Title = "Config", Content = "'" .. name .. "' disimpan!", Duration = 3 })
    self:Refresh()
end

function ConfigManager:Load(name)
    if not name or name == "" then
        WindUI:Notify({ Title = "Config", Content = "Pilih config dulu!", Duration = 3 })
        return
    end
    local path = CONFIG_DIR .. name .. CONFIG_EXT
    if not isfile(path) then
        WindUI:Notify({ Title = "Config", Content = "Config tidak ditemukan!", Duration = 3 })
        return
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
    if ok then
        for k, v in pairs(data) do self.Flags[k] = v end
        WindUI:Notify({ Title = "Config", Content = "'" .. name .. "' dimuat!", Duration = 3 })
    end
end

function ConfigManager:Delete(name)
    if not name or name == "" then
        WindUI:Notify({ Title = "Config", Content = "Pilih config dulu!", Duration = 3 })
        return
    end
    local path = CONFIG_DIR .. name .. CONFIG_EXT
    if isfile(path) then
        delfile(path)
        WindUI:Notify({ Title = "Config", Content = "'" .. name .. "' dihapus!", Duration = 3 })
        self:Refresh()
    end
end

cfgSection:Input({
    Title       = "Config Name",
    Desc        = "Nama config baru",
    Placeholder = "Masukkan nama...",
    Flag        = "ConfigNameInput",
    Callback    = function(v) ConfigManager.Flags.ConfigNameInput = v end,
})

cfgSection:Button({
    Title    = "Save Config",
    Desc     = "Simpan settings ke config baru",
    Icon     = "save",
    Callback = function() ConfigManager:Save(ConfigManager.Flags.ConfigNameInput) end,
})

ConfigManager:Refresh()

local configDropdown = loadSection:Dropdown({
    Title    = "Select Config",
    Desc     = "Pilih config yang tersimpan",
    Values   = ConfigManager.AllConfigs,
    Multi    = false,
    Flag     = "SelectedConfigDropdown",
    Callback = function(v) ConfigManager.Flags.SelectedConfigDropdown = v end,
})

loadSection:Button({
    Title    = "Load Config",
    Icon     = "arrow-right",
    Callback = function() ConfigManager:Load(ConfigManager.Flags.SelectedConfigDropdown) end,
})

loadSection:Button({
    Title    = "Delete Config",
    Callback = function()
        ConfigManager:Delete(ConfigManager.Flags.SelectedConfigDropdown)
        configDropdown:Refresh(ConfigManager.AllConfigs)
    end,
})

-- ── Theme Tab ─────────────────────────────────────────────────
local themeSection = themeTab:Section({ Title = "Select Theme", Opened = true })

themeSection:Dropdown({
    Title    = "Choose UI Theme",
    Values   = { "Dark","Light","Midnight","Emerald","Crimson","Indigo","Amber","Violet","Rose","Sky","Rainbow","Monokai Pro" },
    Default  = "Dark",
    Flag     = "SelectedTheme",
    Callback = function(val) Window:SetTheme(val) end,
})

-- ── Info Tab ──────────────────────────────────────────────────
local infoSection = infoTab:Section({ Title = "Script Hub", Opened = true })
infoSection:Paragraph({ Title = "Hub",     Desc = "DX-SR Hub"           })
infoSection:Paragraph({ Title = "Script",  Desc = "Autofarm Barista"    })
infoSection:Paragraph({ Title = "Version", Desc = "v0.0.0.3"            })
infoSection:Paragraph({ Title = "Author",  Desc = "DX-SR"               })
infoSection:Paragraph({ Title = "Game",    Desc = "Car Driving Indonesia"})

-- ── Open Button ───────────────────────────────────────────────
Window:EditOpenButton({
    Title           = "DX-SR Hub",
    Icon            = "coffee",
    CornerRadius    = UDim.new(0, 16),
    StrokeThickness = 2,
    Color           = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile      = false,
    Enabled         = true,
})

WindUI:Notify({
    Title    = "DX-SR Hub",
    Content  = "Barista Autofarm v0.0.0.3 loaded! Press V to toggle UI.",
    Duration = 5,
    Icon     = "coffee",
})