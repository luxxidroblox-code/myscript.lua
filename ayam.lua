-- Eagle Nation Hub
-- Game : Bus Explorer Indonesia / CDID
-- UI   : DX-SR Hub (WindUI / Rayfield variant)
-- Clean : deobfuscated from JAWADEOBF Instance 723326

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser      = game:GetService("VirtualUser")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
-- ANTI-AFK
-- ============================================================
local idleConnection
local function setupAntiIdle()
    if idleConnection then return end
    for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
        pcall(conn.Disable, conn)
        pcall(conn.Disconnect, conn)
    end
    idleConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end
setupAntiIdle()

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    AutoFarm          = false, TweenSpeed       = 35, ActionDelay       = 0.5, NoclipFarm       = true,
    AutoCement        = false, CementTweenSpeed = 35, CementActionDelay = 0.5, CementNoclipFarm = true,
    AutoOilRig        = false, OilRigTweenSpeed = 35, OilRigActionDelay = 0.5, OilRigNoclipFarm = true,
    AutoMining        = false, MiningTweenSpeed = 35, MiningActionDelay = 0.5, MiningNoclipFarm = true,
    WalkSpeedEnabled  = false, WalkSpeed        = 16,
    JumpPowerEnabled  = false, JumpPower        = 50,
    InfiniteJump      = false, Noclip           = false,
}
_G.EagleNationConfig = Config

-- ============================================================
-- SESSION STATS
-- ============================================================
local Stats = {
    StartCash = 0, StartXP = 0, EarnedCash = 0, EarnedXP = 0,
    DeliveriesCompleted = 0, CurrentStatus = "Idle",

    CementStartCash = 0, CementStartXP = 0, CementEarnedCash = 0, CementEarnedXP = 0,
    CementDeliveriesCompleted = 0, CementCurrentStatus = "Idle",

    OilRigStartCash = 0, OilRigStartXP = 0, OilRigEarnedCash = 0, OilRigEarnedXP = 0,
    OilRigDeliveriesCompleted = 0, OilRigCurrentStatus = "Idle",

    MiningStartCash = 0, MiningStartXP = 0, MiningEarnedCash = 0, MiningEarnedXP = 0,
    MiningDeliveriesCompleted = 0, MiningCurrentStatus = "Idle",
}

local function getLeaderStats()
    local ls   = LocalPlayer:FindFirstChild("leaderstats")
    local cash = (ls and ls:FindFirstChild("$")  and ls["$"].Value)  or 0
    local xp   = (ls and ls:FindFirstChild("XP") and ls.XP.Value)    or 0
    return cash, xp
end

Stats.StartCash,    Stats.StartXP    = getLeaderStats()
Stats.CementStartCash,  Stats.CementStartXP  = Stats.StartCash, Stats.StartXP
Stats.OilRigStartCash,  Stats.OilRigStartXP  = Stats.StartCash, Stats.StartXP
Stats.MiningStartCash,  Stats.MiningStartXP  = Stats.StartCash, Stats.StartXP

-- ============================================================
-- WORLD LOCATIONS
-- ============================================================
local WorldLocations = {
    ["Ranch Main"]    = CFrame.new(13376.21,  149.36,   2990.05),
    ["Dealership"]    = CFrame.new(-489.74,    9.32,   -406.23),
    ["Mining Area"]   = CFrame.new(-5355.07,   5.87,   -946.03),
    ["Oil Rig"]       = CFrame.new(-3174.13, -132.51, -8470.26),
    ["Construction"]  = CFrame.new(29274,     196.16,  -2382),
    ["Race Track"]    = CFrame.new(-9231.64,  390.84,   3294.88),
    ["Custom Garage"] = CFrame.new(-765.64,    8.40,   -304.92),
}
local LocationNames = {
    "Ranch Main", "Dealership", "Mining Area", "Oil Rig",
    "Construction", "Race Track", "Custom Garage",
}

-- ============================================================
-- MOVEMENT HELPERS
-- ============================================================
local activeTween = nil

local function getRootPart(character)
    character = character or LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function setNoclip(enabled)
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and (
            part.Name == "HumanoidRootPart" or
            part.Name:find("Torso")         or
            part.Name == "Head"
        ) then
            part.CanCollide = not enabled
        end
    end
end

local function teleportTo(cf)
    local root = getRootPart()
    if root then root.CFrame = cf end
end

local function tweenTo(targetCF, speedOverride)
    local root = getRootPart()
    if not root then return end

    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end

    local speed = (Config.AutoMining  and Config.MiningTweenSpeed)  or
                  (Config.AutoOilRig  and Config.OilRigTweenSpeed)   or
                  (Config.AutoCement  and Config.CementTweenSpeed)   or
                  Config.TweenSpeed
    local clampedSpeed = math.clamp(speedOverride or speed or 35, 10, 50)

    if Config.NoclipFarm or
       (Config.AutoCement  and Config.CementNoclipFarm)  or
       (Config.AutoOilRig  and Config.OilRigNoclipFarm)  or
       (Config.AutoMining  and Config.MiningNoclipFarm)  then
        setNoclip(true)
    end

    -- Ranch gate bypass waypoint
    local gateWP     = Vector3.new(13360, 150.5, 2980)
    local inRanch    = root.Position.X > 12000 and root.Position.X < 14000
    local destInRanch = targetCF.Position.X > 12000 and targetCF.Position.X < 14000

    if inRanch and destInRanch then
        local fromRight  = root.Position.X > 13366
        local destLeft   = targetCF.Position.X < 13364
        local destRight  = targetCF.Position.X > 13366

        if (fromRight and destLeft) or ((not fromRight) and destRight) then
            local d = (gateWP - root.Position).Magnitude
            local t = TweenService:Create(root,
                TweenInfo.new(math.clamp(d / clampedSpeed, 0.1, 4), Enum.EasingStyle.Linear),
                { CFrame = CFrame.new(gateWP) })
            t:Play()
            t.Completed:Wait()
        end
    end

    local dist    = (targetCF.Position - root.Position).Magnitude
    local duration = math.clamp(dist / clampedSpeed, 0.1, 15)
    activeTween   = TweenService:Create(root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = targetCF })
    activeTween:Play()
    activeTween.Completed:Wait()
    activeTween = nil
end

local function firePrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    local hold = prompt.HoldDuration or 0
    if fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(hold + 0.15)
    else
        pcall(function() prompt:InputHoldBegin() end)
        task.wait(hold + 0.1)
        pcall(function() prompt:InputHoldEnd() end)
        task.wait(0.15)
    end
end

-- Approach CFrame facing the horse stall feed slot
local function getHayFeedCFrame(stall)
    local pos    = stall.Position
    local up     = stall.CFrame.UpVector
    local flatUp = Vector3.new(up.X, 0, up.Z).Unit
    local isD4   = false
    local rj     = Workspace:FindFirstChild("RancherJob")
    if rj and rj:FindFirstChild("RancherDestination4") then
        if (rj.RancherDestination4.Position - pos).Magnitude < 4 then isD4 = true end
    end
    local dir    = isD4 and flatUp or -flatUp
    local offset = pos + (dir * 3.2)
    local root   = getRootPart()
    local y      = (root and root.Position.Y) or (pos.Y + 0.5)
    return CFrame.lookAt(Vector3.new(offset.X, y, offset.Z), Vector3.new(pos.X, y, pos.Z))
end

-- Approach CFrame facing the cement mixer front
local function getCementPourCFrame(mixer)
    local pos    = mixer.Position
    local look   = mixer.CFrame.LookVector
    local flat   = Vector3.new(look.X, 0, look.Z).Unit
    local offset = pos + (flat * 3.5)
    local root   = getRootPart()
    local y      = (root and root.Position.Y) or (pos.Y + 0.5)
    return CFrame.lookAt(Vector3.new(offset.X, y, offset.Z), Vector3.new(pos.X, y, pos.Z))
end

-- ============================================================
-- LOAD WINDUI
-- ============================================================
if _G.EagleNationHubLoaded then
    pcall(function() _G.EagleNationHubLoaded:Destroy() end)
    _G.EagleNationHubLoaded = nil
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title                      = "Eagle Nation",
    Icon                       = "motorbike",
    Author                     = "DX-SR Hub",
    Folder                     = "EagleNationHub",
    Size                       = UDim2.fromOffset(590, 470),
    MinSize                    = Vector2.new(560, 360),
    MaxSize                    = Vector2.new(850, 580),
    ToggleKey                  = Enum.KeyCode.V,
    Transparent                = true,
    Theme                      = "Dark",
    Resizable                  = true,
    SideBarWidth               = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar              = false,
    ScrollBarEnabled           = false,
})
_G.EagleNationHubLoaded = Window

Window:Tag({ Title = "v0.0.0.1",    Icon = "git-pull-request-draft", Color = Color3.fromHex("#30ff6a"), Radius = 13 })
Window:Tag({ Title = "DX-SR (paid)", Icon = "dollar-sign",            Color = Color3.fromHex("#34b1eb"), Radius = 13 })

-- Helper: update a WindUI Paragraph element
local function updateParagraph(label, desc, title)
    if not label then return end
    pcall(function()
        if label.SetDesc then
            label:SetDesc(desc)
            if title and label.SetTitle then label:SetTitle(title) end
        elseif label.Set then
            local t = { Desc = desc }
            if title then t.Title = title end
            label:Set(t)
        end
    end)
end

-- ============================================================
-- TABS
-- ============================================================
local mainSection = Window:Section({ Title = "Main", Icon = "house", Opened = true })
local feedingTab  = mainSection:Tab({ Title = "Feeding job",  Icon = "tractor" })
local cementTab   = mainSection:Tab({ Title = "Cement job",   Icon = "hammer"  })
local oilRigTab   = mainSection:Tab({ Title = "Oil rig",      Icon = "droplet" })
local miningTab   = mainSection:Tab({ Title = "Mining job",   Icon = "pickaxe" })
local teleportTab = Window:Tab({ Title = "Teleports",    Icon = "map-pin" })
local playerTab   = Window:Tab({ Title = "Player",       Icon = "user"    })
pcall(function() feedingTab:Select() end)

-- ============================================================
-- FEEDING JOB TAB
-- ============================================================
feedingTab:Section({ Title = "Horse Feeding Job (Hay Stack)", Opened = true })
pcall(function() feedingTab:Space() end)

local feedingStatsLabel = feedingTab:Paragraph({ Title = "Session Statistics", Desc = "Delivered: 0 | Cash: +$0 | XP: +0" })

local function updateFeedingStats()
    local cash, xp = getLeaderStats()
    Stats.EarnedCash = math.max(0, cash - Stats.StartCash)
    Stats.EarnedXP   = math.max(0, xp   - Stats.StartXP)
    updateParagraph(feedingStatsLabel,
        string.format("Delivered: %d | Cash: +$%s | XP: +%s",
            Stats.DeliveriesCompleted, tostring(Stats.EarnedCash), tostring(Stats.EarnedXP)),
        "Session Statistics")
end

_G.EagleNationFarmToggle = feedingTab:Toggle({
    Title = "Auto Feed Horse", Flag = "AutoFarmHorse", Default = false,
    Callback = function(enabled)
        Config.AutoFarm = enabled
        if enabled then
            if Config.AutoCement  then Config.AutoCement  = false pcall(function() _G.EagleNationCementToggle:SetValue(false)  end) end
            if Config.AutoOilRig  then Config.AutoOilRig  = false pcall(function() _G.EagleNationOilRigToggle:SetValue(false)  end) end
            if Config.AutoMining  then Config.AutoMining  = false pcall(function() _G.EagleNationMiningToggle:SetValue(false)  end) end
            Stats.CurrentStatus = "Starting farm cycle..."
            updateFeedingStats()
            WindUI:Notify({ Title = "Rancher Farm", Content = "Auto Feed Horse started!", Duration = 2.5 })
        else
            Stats.CurrentStatus = "Stopped"
            updateFeedingStats()
            if activeTween then pcall(function() activeTween:Cancel() end) activeTween = nil end
            setNoclip(false)
        end
    end,
})

feedingTab:Toggle({ Title = "Noclip During Farm", Flag = "NoclipFarmToggle", Default = true,
    Callback = function(v) Config.NoclipFarm = v end })
feedingTab:Slider({ Title = "Tween Speed", Step = 5, Flag = "TweenSpeedSlider",
    Value = { Min = 10, Max = 50, Default = 35 }, Callback = function(v) Config.TweenSpeed = v end })
feedingTab:Slider({ Title = "Action Delay", Step = 0.1, Flag = "ActionDelaySlider",
    Value = { Min = 0.1, Max = 4, Default = 0.5 }, Callback = function(v) Config.ActionDelay = v end })

-- ============================================================
-- CEMENT JOB TAB
-- ============================================================
cementTab:Section({ Title = "Cement Delivery Job (Construction Site)", Opened = true })
pcall(function() cementTab:Space() end)

local cementStatsLabel = cementTab:Paragraph({ Title = "Session Statistics", Desc = "Delivered: 0 | Cash: +$0 | XP: +0" })

local function updateCementStats()
    local cash, xp = getLeaderStats()
    Stats.CementEarnedCash = math.max(0, cash - Stats.CementStartCash)
    Stats.CementEarnedXP   = math.max(0, xp   - Stats.CementStartXP)
    updateParagraph(cementStatsLabel,
        string.format("Delivered: %d | Cash: +$%s | XP: +%s",
            Stats.CementDeliveriesCompleted, tostring(Stats.CementEarnedCash), tostring(Stats.CementEarnedXP)),
        "Session Statistics")
end

_G.EagleNationCementToggle = cementTab:Toggle({
    Title = "Auto Cement Job", Flag = "AutoFarmCement", Default = false,
    Callback = function(enabled)
        Config.AutoCement = enabled
        if enabled then
            if Config.AutoFarm    then Config.AutoFarm    = false pcall(function() _G.EagleNationFarmToggle:SetValue(false)   end) end
            if Config.AutoOilRig  then Config.AutoOilRig  = false pcall(function() _G.EagleNationOilRigToggle:SetValue(false) end) end
            if Config.AutoMining  then Config.AutoMining  = false pcall(function() _G.EagleNationMiningToggle:SetValue(false) end) end
            Stats.CementCurrentStatus = "Starting cement cycle..."
            updateCementStats()
            WindUI:Notify({ Title = "Construction Farm", Content = "Auto Cement Job started!", Duration = 2.5 })
        else
            Stats.CementCurrentStatus = "Stopped"
            updateCementStats()
            if activeTween then pcall(function() activeTween:Cancel() end) activeTween = nil end
            setNoclip(false)
        end
    end,
})

cementTab:Toggle({ Title = "Noclip During Farm", Flag = "NoclipCementToggle", Default = true,
    Callback = function(v) Config.CementNoclipFarm = v end })
cementTab:Slider({ Title = "Tween Speed", Step = 5, Flag = "CementTweenSpeedSlider",
    Value = { Min = 10, Max = 50, Default = 35 }, Callback = function(v) Config.CementTweenSpeed = v end })
cementTab:Slider({ Title = "Action Delay", Step = 0.1, Flag = "CementActionDelaySlider",
    Value = { Min = 0.1, Max = 4, Default = 0.5 }, Callback = function(v) Config.CementActionDelay = v end })

-- ============================================================
-- OIL RIG TAB
-- ============================================================
oilRigTab:Section({ Title = "Oil Rig Job", Opened = true })
pcall(function() oilRigTab:Space() end)

local oilRigStatsLabel = oilRigTab:Paragraph({ Title = "Session Statistics", Desc = "Delivered: 0 | Cash: +$0 | XP: +0" })

local function updateOilRigStats()
    local cash, xp = getLeaderStats()
    Stats.OilRigEarnedCash = math.max(0, cash - Stats.OilRigStartCash)
    Stats.OilRigEarnedXP   = math.max(0, xp   - Stats.OilRigStartXP)
    updateParagraph(oilRigStatsLabel,
        string.format("Delivered: %d | Cash: +$%s | XP: +%s",
            Stats.OilRigDeliveriesCompleted, tostring(Stats.OilRigEarnedCash), tostring(Stats.OilRigEarnedXP)),
        "Session Statistics")
end

_G.EagleNationOilRigToggle = oilRigTab:Toggle({
    Title = "Auto Oil Rig", Flag = "AutoFarmOilRig", Default = false,
    Callback = function(enabled)
        Config.AutoOilRig = enabled
        if enabled then
            if Config.AutoFarm    then Config.AutoFarm    = false pcall(function() _G.EagleNationFarmToggle:SetValue(false)   end) end
            if Config.AutoCement  then Config.AutoCement  = false pcall(function() _G.EagleNationCementToggle:SetValue(false) end) end
            if Config.AutoMining  then Config.AutoMining  = false pcall(function() _G.EagleNationMiningToggle:SetValue(false) end) end
            Stats.OilRigCurrentStatus = "Starting oil rig cycle..."
            updateOilRigStats()
            WindUI:Notify({ Title = "Oil Rig Farm", Content = "Auto Oil Rig started!", Duration = 2.5 })
        else
            Stats.OilRigCurrentStatus = "Stopped"
            updateOilRigStats()
            if activeTween then pcall(function() activeTween:Cancel() end) activeTween = nil end
            setNoclip(false)
        end
    end,
})

oilRigTab:Toggle({ Title = "Noclip During Farm", Flag = "NoclipOilRigToggle", Default = true,
    Callback = function(v) Config.OilRigNoclipFarm = v end })
oilRigTab:Slider({ Title = "Tween Speed", Step = 5, Flag = "OilRigTweenSpeedSlider",
    Value = { Min = 10, Max = 50, Default = 35 }, Callback = function(v) Config.OilRigTweenSpeed = v end })
oilRigTab:Slider({ Title = "Action Delay", Step = 0.1, Flag = "OilRigActionDelaySlider",
    Value = { Min = 0.1, Max = 4, Default = 0.5 }, Callback = function(v) Config.OilRigActionDelay = v end })

-- ============================================================
-- MINING JOB TAB
-- ============================================================
miningTab:Section({ Title = "Mining Job (Ore Extraction & Sale)", Opened = true })
pcall(function() miningTab:Space() end)

local miningStatsLabel = miningTab:Paragraph({ Title = "Session Statistics", Desc = "Sales: 0 | Cash: +$0 | XP: +0" })

local function updateMiningStats()
    local cash, xp = getLeaderStats()
    Stats.MiningEarnedCash = math.max(0, cash - Stats.MiningStartCash)
    Stats.MiningEarnedXP   = math.max(0, xp   - Stats.MiningStartXP)
    updateParagraph(miningStatsLabel,
        string.format("Sales: %d | Cash: +$%s | XP: +%s",
            Stats.MiningDeliveriesCompleted, tostring(Stats.MiningEarnedCash), tostring(Stats.MiningEarnedXP)),
        "Session Statistics")
end

_G.EagleNationMiningToggle = miningTab:Toggle({
    Title = "Auto Mining Job", Flag = "AutoFarmMining", Default = false,
    Callback = function(enabled)
        Config.AutoMining = enabled
        if enabled then
            if Config.AutoFarm    then Config.AutoFarm    = false pcall(function() _G.EagleNationFarmToggle:SetValue(false)   end) end
            if Config.AutoCement  then Config.AutoCement  = false pcall(function() _G.EagleNationCementToggle:SetValue(false) end) end
            if Config.AutoOilRig  then Config.AutoOilRig  = false pcall(function() _G.EagleNationOilRigToggle:SetValue(false) end) end
            Stats.MiningCurrentStatus = "Starting mining cycle..."
            updateMiningStats()
            WindUI:Notify({ Title = "Mining Farm", Content = "Auto Mining Job started!", Duration = 2.5 })
        else
            Stats.MiningCurrentStatus = "Stopped"
            updateMiningStats()
            if activeTween then pcall(function() activeTween:Cancel() end) activeTween = nil end
            setNoclip(false)
        end
    end,
})

miningTab:Toggle({ Title = "Noclip During Farm", Flag = "NoclipMiningToggle", Default = true,
    Callback = function(v) Config.MiningNoclipFarm = v end })
miningTab:Slider({ Title = "Tween Speed", Step = 5, Flag = "MiningTweenSpeedSlider",
    Value = { Min = 10, Max = 50, Default = 35 }, Callback = function(v) Config.MiningTweenSpeed = v end })
miningTab:Slider({ Title = "Action Delay", Step = 0.1, Flag = "MiningActionDelaySlider",
    Value = { Min = 0.1, Max = 4, Default = 0.5 }, Callback = function(v) Config.MiningActionDelay = v end })

-- ============================================================
-- TELEPORTS TAB
-- ============================================================
teleportTab:Section({ Title = "World Locations", Opened = true })
pcall(function() teleportTab:Space() end)

local teleportReady    = false
local selectedLocation = LocationNames[1]

teleportTab:Dropdown({
    Title = "Select Location", Multi = false, Flag = "WorldTeleportDropdown",
    Value = selectedLocation, Values = LocationNames,
    Callback = function(loc)
        selectedLocation = loc
        if teleportReady and WorldLocations[loc] then
            teleportTo(WorldLocations[loc])
            WindUI:Notify({ Title = "Teleport", Content = "Teleported to " .. loc, Duration = 2 })
        end
    end,
})
teleportTab:Button({
    Title = "Teleport",
    Callback = function()
        local cf = WorldLocations[selectedLocation]
        if cf then
            teleportTo(cf)
            WindUI:Notify({ Title = "Teleport", Content = "Teleported to " .. selectedLocation, Duration = 2 })
        end
    end,
})
task.delay(0.5, function() teleportReady = true end)

-- ============================================================
-- PLAYER TAB â€” Overhead Customizer
-- ============================================================
playerTab:Section({ Title = "Overhead Customizer", Opened = true })
pcall(function() playerTab:Space() end)

local overheadData = { Rank = nil, Level = nil, Name = nil }

local function applyOverhead()
    local character  = LocalPlayer.Character
    local head       = character and character:FindFirstChild("Head")
    local overheadUI = head and head:FindFirstChild("OverheadUI")
    if not overheadUI then return end

    if overheadData.Rank and overheadData.Rank ~= "" then
        local lbl = overheadUI:FindFirstChild("GRank")
        if lbl and lbl:IsA("TextLabel") then lbl.Text = overheadData.Rank end
    end
    if overheadData.Level and overheadData.Level ~= "" then
        local lbl = overheadUI:FindFirstChild("LevelLabel")
        if lbl and lbl:IsA("TextLabel") then lbl.Text = overheadData.Level end
    end
    if overheadData.Name and overheadData.Name ~= "" then
        local lbl = overheadUI:FindFirstChild("PName")
        if lbl and lbl:IsA("TextLabel") then lbl.Text = overheadData.Name end
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    applyOverhead()
    local head = character:WaitForChild("Head", 10)
    local ui   = head and head:WaitForChild("OverheadUI", 10)
    if ui then applyOverhead() end
end)

task.spawn(function()
    while true do
        if overheadData.Rank or overheadData.Level or overheadData.Name then
            pcall(applyOverhead)
        end
        task.wait(1)
    end
end)

playerTab:Input({
    Title = "Rank", Desc = "Change overhead rank text",
    PlaceholderText = "Enter rank...", ClearTextOnFocus = false, Flag = "OverheadRankInput",
    Callback = function(v) overheadData.Rank = v applyOverhead() end,
})
playerTab:Input({
    Title = "Level", Desc = "e.g. [LVL -]",
    PlaceholderText = "[LVL -]", ClearTextOnFocus = false, Flag = "OverheadLevelInput",
    Callback = function(v)
        if v and v ~= "" then
            if v:find("%[LVL") then
                overheadData.Level = v
            elseif tonumber(v) then
                overheadData.Level = "[LVL " .. v .. "]"
            else
                overheadData.Level = v
            end
        else
            overheadData.Level = nil
        end
        applyOverhead()
    end,
})
playerTab:Input({
    Title = "Name", Desc = "Change overhead display name",
    PlaceholderText = "Enter name...", ClearTextOnFocus = false, Flag = "OverheadNameInput",
    Callback = function(v) overheadData.Name = v applyOverhead() end,
})

-- ============================================================
-- PLAYER TAB â€” Movement Modifiers
-- ============================================================
pcall(function() playerTab:Space() end)
playerTab:Section({ Title = "Movement Modifiers", Opened = true })
pcall(function() playerTab:Space() end)

playerTab:Toggle({ Title = "Modify WalkSpeed", Desc = "Bypasses game speed limits (default is 6)",
    Flag = "WalkSpeedToggle", Default = false,
    Callback = function(v)
        Config.WalkSpeedEnabled = v
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum and not v then hum.WalkSpeed = 6 end
    end,
})
playerTab:Toggle({ Title = "Modify JumpPower", Desc = "Enable custom jump power",
    Flag = "JumpPowerToggle", Default = false,
    Callback = function(v)
        Config.JumpPowerEnabled = v
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum and not v then hum.JumpPower = 50 end
    end,
})
playerTab:Toggle({ Title = "Infinite Jump", Desc = "Jump continuously in the air",
    Flag = "InfiniteJumpToggle", Default = false,
    Callback = function(v) Config.InfiniteJump = v end,
})
playerTab:Toggle({ Title = "Noclip", Desc = "Walk through walls and obstacles",
    Flag = "NoclipToggle", Default = false,
    Callback = function(v)
        Config.Noclip = v
        if not v then setNoclip(false) end
    end,
})
playerTab:Slider({ Title = "WalkSpeed Value", Desc = "Set custom walkspeed",
    Step = 1, Flag = "WalkSpeedValue",
    Value = { Min = 6, Max = 80, Default = 24 },
    Callback = function(v) Config.WalkSpeed = v end,
})
playerTab:Slider({ Title = "JumpPower Value", Desc = "Set custom jump power",
    Step = 5, Flag = "JumpPowerValue",
    Value = { Min = 50, Max = 200, Default = 70 },
    Callback = function(v) Config.JumpPower = v end,
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local character = LocalPlayer.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    if not character then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        if Config.WalkSpeedEnabled then hum.WalkSpeed = Config.WalkSpeed end
        if Config.JumpPowerEnabled then hum.JumpPower = Config.JumpPower end
    end
    if Config.Noclip or (Config.AutoFarm and Config.NoclipFarm) then
        setNoclip(true)
    end
end)

-- ============================================================
-- CONFIGURATION TAB
-- ============================================================
local configTab = Window:Tab({ Title = "Configuration", Icon = "settings" })
configTab:Section({ Title = "Theme" })
pcall(function() configTab:Space() end)

local themes = {}
pcall(function()
    local list = WindUI:GetThemes()
    if list then
        for k, v in pairs(list) do
            if type(v) == "string" then table.insert(themes, v)
            elseif type(k) == "string" then table.insert(themes, k) end
        end
    end
end)
if #themes == 0 then
    themes = { "Dark", "Light", "Rose", "Plant", "Red", "Indigo", "Sky", "Violet",
               "Amber", "Emerald", "Midnight", "Crimson", "Monokai Pro", "Cotton Candy",
               "Mellowsi", "Rainbow" }
end

configTab:Dropdown({
    Title = "Select Theme", Desc = "Choose UI Theme", Multi = false, Flag = "SelectedTheme",
    Value = WindUI:GetCurrentTheme() or "Dark", Values = themes,
    Callback = function(theme) pcall(function() WindUI:SetTheme(theme) end) end,
})

configTab:Section({ Title = "Config" })
pcall(function() configTab:Space() end)

local selectedConfig = ""
local configNameInput = ""

local function getAllConfigs()
    local list = {}
    pcall(function()
        local configs = Window.ConfigManager:AllConfigs()
        if configs then for _, name in ipairs(configs) do table.insert(list, name) end end
    end)
    return list
end

local configDropdown = configTab:Dropdown({
    Title = "Select Config", Desc = "Choose saved config", Multi = false,
    Flag = "SelectedConfigDropdown", Value = "", Values = getAllConfigs(),
    Callback = function(v) selectedConfig = v end,
})

configTab:Input({
    Title = "Config Name", Desc = "New config name",
    PlaceholderText = "Enter config name...", Flag = "ConfigNameInput",
    Callback = function(v) configNameInput = v end,
})
configTab:Button({ Title = "Save Config", Desc = "Save current settings to new config",
    Callback = function()
        if configNameInput == "" then
            WindUI:Notify({ Title = "Config", Content = "Enter config name first!", Duration = 3 }) return
        end
        pcall(function()
            selectedConfig = configNameInput
            pcall(function() configDropdown:Select(configNameInput) end)
            Window.ConfigManager:CreateConfig(configNameInput):Save()
        end)
        WindUI:Notify({ Title = "Config", Content = "Config '" .. configNameInput .. "' saved successfully!", Duration = 3 })
        pcall(function() configDropdown:Refresh(getAllConfigs()) configDropdown:Select(configNameInput) end)
    end,
})
configTab:Button({ Title = "Load Config", Desc = "Load selected config",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 }) return
        end
        pcall(function()
            Window.ConfigManager:CreateConfig(selectedConfig):Load()
            pcall(function() configDropdown:Select(selectedConfig) end)
        end)
        WindUI:Notify({ Title = "Config", Content = "Config '" .. selectedConfig .. "' loaded successfully!", Duration = 3 })
    end,
})
configTab:Button({ Title = "Rewrite Config", Desc = "Rewrite selected config",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 }) return
        end
        local path       = "WindUI/" .. (Window.Folder or "EagleNationHub") .. "/config/" .. selectedConfig .. ".json"
        local autoLoad   = false
        local customData = {}
        if isfile and isfile(path) and readfile then
            pcall(function()
                local decoded = HttpService:JSONDecode(readfile(path))
                if type(decoded) == "table" then
                    autoLoad   = decoded.__autoload or false
                    customData = decoded.__custom or {}
                end
            end)
        end
        local ok, err = pcall(function()
            pcall(function() configDropdown:Select(selectedConfig) end)
            local elements = {}
            local parser   = Window.ConfigManager.Parser
            local flags    = Window.PendingFlags or Window.Flags or {}
            for flagName, flag in pairs(flags) do
                if flag and flag.__type and parser and parser[flag.__type] then
                    pcall(function() elements[tostring(flagName)] = parser[flag.__type].Save(flag) end)
                end
            end
            local data = { __version = 1.2, __elements = elements, __autoload = autoLoad, __custom = customData }
            if writefile then writefile(path, HttpService:JSONEncode(data)) end
            local cfgs = Window.ConfigManager and Window.ConfigManager.Configs
            if cfgs and cfgs[selectedConfig] then
                local cfg      = cfgs[selectedConfig]
                cfg.AutoLoad   = autoLoad
                cfg.CustomData = customData
                for flagName, flag in pairs(flags) do cfg:Register(flagName, flag) end
            end
        end)
        if ok then
            WindUI:Notify({ Title = "Config", Content = "Config '" .. selectedConfig .. "' rewritten! (Not loaded)", Duration = 3 })
        else
            WindUI:Notify({ Title = "Config", Content = "Failed: " .. tostring(err), Duration = 3 })
        end
    end,
})
configTab:Button({ Title = "Delete Config", Desc = "Delete selected config",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 }) return
        end
        pcall(function() Window.ConfigManager:CreateConfig(selectedConfig):Delete() end)
        WindUI:Notify({ Title = "Config", Content = "Config '" .. selectedConfig .. "' deleted!", Duration = 3 })
        selectedConfig = ""
        pcall(function() configDropdown:Refresh(getAllConfigs()) configDropdown:Select("") end)
    end,
})
configTab:Button({ Title = "Set Auto Load", Desc = "Automatically load selected config on start",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 }) return
        end
        pcall(function()
            local allCfgs = Window.ConfigManager:AllConfigs()
            if allCfgs and isfile and readfile and writefile then
                for _, name in ipairs(allCfgs) do
                    local p = "WindUI/" .. (Window.Folder or "EagleNationHub") .. "/config/" .. name .. ".json"
                    if isfile(p) then
                        pcall(function()
                            local d = HttpService:JSONDecode(readfile(p))
                            if type(d) == "table" then
                                d.__autoload = (name == selectedConfig)
                                writefile(p, HttpService:JSONEncode(d))
                            end
                        end)
                    end
                end
            end
            pcall(function() configDropdown:Select(selectedConfig) end)
            local cfgs = Window.ConfigManager and Window.ConfigManager.Configs
            if cfgs then
                for name, cfg in pairs(cfgs) do
                    if cfg and cfg.SetAutoLoad then cfg:SetAutoLoad(name == selectedConfig) end
                end
            end
        end)
        WindUI:Notify({ Title = "Config", Content = "Auto load set to '" .. selectedConfig .. "'!", Duration = 3 })
    end,
})

-- Auto-load on start
pcall(function()
    local allCfgs = Window.ConfigManager:AllConfigs()
    if allCfgs and readfile and isfile then
        for _, name in pairs(allCfgs) do
            local path = "WindUI/" .. (Window.Folder or "EagleNationHub") .. "/config/" .. name .. ".json"
            if isfile(path) then
                local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
                if ok and type(decoded) == "table" and decoded.__autoload then
                    Window.ConfigManager:CreateConfig(name):Load()
                    selectedConfig = name
                    task.defer(function() pcall(function() configDropdown:Select(name) end) end)
                    break
                end
            end
        end
    end
end)

Window:EditOpenButton({
    Title = "Eagle Hub", Icon = "wheat",
    CornerRadius = UDim.new(0, 16), StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("F89B29"), Color3.fromHex("FF0F7B")),
    OnlyMobile = false, Enabled = true, Draggable = true,
})

-- ============================================================
-- FARM LOOPS
-- ============================================================

-- Hay Feeding
local function runHayFarm()
    local character = LocalPlayer.Character
    local root      = getRootPart(character)
    if not character or not root then task.wait(1) return end

    local packageSites = Workspace:FindFirstChild("PackageSites")
    local hayStack     = packageSites and packageSites:FindFirstChild("GatherPackageHay")
    if not hayStack then
        Stats.CurrentStatus = "Waiting for Hay Stack to exist..."
        updateFeedingStats() task.wait(1) return
    end

    local hayPrompt       = hayStack:FindFirstChildWhichIsA("ProximityPrompt")
    local deliveryKey     = LocalPlayer.Name .. "_Delivery"
    local activeDeliveries = Workspace:FindFirstChild("ActiveDeliveries")
    local delivery        = activeDeliveries and activeDeliveries:FindFirstChild(deliveryKey)

    if not delivery then
        local grabCF = CFrame.lookAt(
            Vector3.new(hayStack.Position.X - 3.5, root.Position.Y, hayStack.Position.Z),
            Vector3.new(hayStack.Position.X,        root.Position.Y, hayStack.Position.Z))
        if (root.Position - grabCF.Position).Magnitude > 2 then
            Stats.CurrentStatus = "Moving to Hay Supply..."
            updateFeedingStats() tweenTo(grabCF)
        end
        if not Config.AutoFarm then return end

        local hold = (hayPrompt and hayPrompt.HoldDuration) or 1.5
        Stats.CurrentStatus = string.format("Grabbing Hay (Hold %.1fs)...", hold)
        updateFeedingStats()
        if hayPrompt then firePrompt(hayPrompt) end

        if Config.ActionDelay and Config.ActionDelay > 0 then
            Stats.CurrentStatus = string.format("Action Delay: Waiting %.1fs...", Config.ActionDelay)
            updateFeedingStats() task.wait(Config.ActionDelay)
        end

        Stats.CurrentStatus = "Waiting for server to assign horse..."
        updateFeedingStats()
        local t0 = tick()
        repeat
            delivery = activeDeliveries and activeDeliveries:FindFirstChild(deliveryKey)
            task.wait(0.05)
        until delivery or (tick() - t0 > 8) or not Config.AutoFarm
    end

    if not Config.AutoFarm then return end

    if delivery then
        local stallName  = "Horse Stall"
        local rancherJob = Workspace:FindFirstChild("RancherJob")
        if rancherJob then
            local stallMap = {
                RancherDestination1 = "Stall 1 (Horse 1)", RancherDestination2 = "Stall 2 (Horse 2)",
                RancherDestination3 = "Stall 3 (Horse 3)", RancherDestination4 = "Stall 4 (Horse 4)",
            }
            for _, part in ipairs(rancherJob:GetChildren()) do
                if part:IsA("BasePart") and (part.Position - delivery.Position).Magnitude < 6 then
                    stallName = stallMap[part.Name] or part.Name break
                end
            end
        end

        Stats.CurrentStatus = "Assigned: " .. stallName .. " - Moving..."
        updateFeedingStats()
        local feedCF = getHayFeedCFrame(delivery)
        tweenTo(feedCF)
        if not Config.AutoFarm then return end
        if (delivery.Position - root.Position).Magnitude > 6 then tweenTo(feedCF) end

        local feedPrompt = delivery:WaitForChild("ProximityPrompt", 4)
        if feedPrompt then
            Stats.CurrentStatus = string.format("Feeding %s (Hold %.1fs)...", stallName, feedPrompt.HoldDuration or 1.2)
            updateFeedingStats() firePrompt(feedPrompt)
        end

        Stats.CurrentStatus = "Waiting for server validation..."
        updateFeedingStats()
        local t0 = tick()
        while activeDeliveries:FindFirstChild(deliveryKey) and (tick() - t0 < 4) do
            task.wait(0.05) if not Config.AutoFarm then break end
        end
        if not activeDeliveries:FindFirstChild(deliveryKey) then
            Stats.CurrentStatus = "Fed " .. stallName .. " Successfully!"
            updateFeedingStats()
        end
    end
    task.wait(0.1)
end

task.spawn(function()
    while true do
        if Config.AutoFarm then
            local ok, err = pcall(runHayFarm)
            if not ok and Config.AutoFarm then
                warn("[Eagle Nation Hub Farm Error]:", err)
                Stats.CurrentStatus = "Error: " .. tostring(err)
                updateFeedingStats() task.wait(1)
            end
        else task.wait(0.5) end
    end
end)

-- Cement Farm
local function runCementFarm()
    local character = LocalPlayer.Character
    local root      = getRootPart(character)
    if not character or not root then task.wait(1) return end

    local packageSites  = Workspace:FindFirstChild("PackageSites")
    local cementSupply  = packageSites and packageSites:FindFirstChild("GatherPackageCement")
    if not cementSupply then
        Stats.CementCurrentStatus = "Waiting for Cement Supply..."
        updateCementStats() task.wait(1) return
    end

    local cementPrompt    = cementSupply:FindFirstChildWhichIsA("ProximityPrompt")
    local deliveryKey     = LocalPlayer.Name .. "_Delivery"
    local activeDeliveries = Workspace:FindFirstChild("ActiveDeliveries")
    local delivery        = activeDeliveries and activeDeliveries:FindFirstChild(deliveryKey)

    if not delivery then
        local grabCF = CFrame.lookAt(
            Vector3.new(cementSupply.Position.X + 3.5, root.Position.Y, cementSupply.Position.Z),
            Vector3.new(cementSupply.Position.X,        root.Position.Y, cementSupply.Position.Z))
        if (root.Position - grabCF.Position).Magnitude > 2 then
            Stats.CementCurrentStatus = "Moving to Cement Supply..."
            updateCementStats() tweenTo(grabCF)
        end
        if not Config.AutoCement then return end

        local hold = (cementPrompt and cementPrompt.HoldDuration) or 1.5
        Stats.CementCurrentStatus = string.format("Grabbing Cement (Hold %.1fs)...", hold)
        updateCementStats()
        if cementPrompt then firePrompt(cementPrompt) end

        if Config.CementActionDelay and Config.CementActionDelay > 0 then
            Stats.CementCurrentStatus = string.format("Action Delay: Waiting %.1fs...", Config.CementActionDelay)
            updateCementStats() task.wait(Config.CementActionDelay)
        end

        Stats.CementCurrentStatus = "Waiting for server to assign mixer..."
        updateCementStats()
        local t0 = tick()
        repeat
            delivery = activeDeliveries and activeDeliveries:FindFirstChild(deliveryKey)
            task.wait(0.05)
        until delivery or (tick() - t0 > 8) or not Config.AutoCement
    end

    if not Config.AutoCement then return end

    if delivery then
        local mixerName     = "Concrete Mixer"
        local constructionJob = Workspace:FindFirstChild("ConstructionJob")
        if constructionJob then
            for _, part in ipairs(constructionJob:GetChildren()) do
                if part:IsA("BasePart") and (part.Position - delivery.Position).Magnitude < 6 then
                    local num = part.Name:match("%d+")
                    mixerName = (num and "Mixer " .. num) or part.Name break
                end
            end
        end

        Stats.CementCurrentStatus = "Assigned: " .. mixerName .. " - Moving..."
        updateCementStats()
        local pourCF = getCementPourCFrame(delivery)
        tweenTo(pourCF)
        if not Config.AutoCement then return end
        if (delivery.Position - root.Position).Magnitude > 6 then tweenTo(pourCF) end

        local pourPrompt = delivery:WaitForChild("ProximityPrompt", 4)
        if pourPrompt then
            Stats.CementCurrentStatus = string.format("Pouring %s (Hold %.1fs)...", mixerName, pourPrompt.HoldDuration or 2)
            updateCementStats() firePrompt(pourPrompt)
        end

        Stats.CementCurrentStatus = "Waiting for server validation..."
        updateCementStats()
        local t0 = tick()
        while activeDeliveries:FindFirstChild(deliveryKey) and (tick() - t0 < 4) do
            task.wait(0.05) if not Config.AutoCement then break end
        end
        if not activeDeliveries:FindFirstChild(deliveryKey) then
            Stats.CementCurrentStatus = "Poured " .. mixerName .. " Successfully!"
            updateCementStats()
        end
    end
    task.wait(0.1)
end

task.spawn(function()
    while true do
        if Config.AutoCement then
            local ok, err = pcall(runCementFarm)
            if not ok and Config.AutoCement then
                warn("[Eagle Nation Hub Cement Farm Error]:", err)
                Stats.CementCurrentStatus = "Error: " .. tostring(err)
                updateCementStats() task.wait(1)
            end
        else task.wait(0.5) end
    end
end)

-- Oil Rig Farm
local hasOilCarried = false

local function runOilRigFarm()
    local character = LocalPlayer.Character
    local root      = getRootPart(character)
    if not character or not root then task.wait(1) return end

    local oilRigJob      = Workspace:FindFirstChild("OilRigJob")
    local collectionTank = oilRigJob and oilRigJob:FindFirstChild("CollectionTank")
    local wells          = oilRigJob and oilRigJob:FindFirstChild("Wells")
    if not oilRigJob or not collectionTank or not wells then
        Stats.OilRigCurrentStatus = "Waiting for Oil Rig Job..."
        updateOilRigStats() task.wait(1) return
    end

    local carryingOil = hasOilCarried or (collectionTank:FindFirstChild("OilCarryBeam") ~= nil)

    if not carryingOil then
        local readyWells   = {}
        local shortestWait = math.huge

        for _, well in ipairs(wells:GetChildren()) do
            if well:IsA("BasePart") then
                local refillAt = well:GetAttribute("RefillAt") or 0
                local wait     = refillAt - os.time()
                if wait <= 0 then
                    table.insert(readyWells, well)
                elseif wait < shortestWait then
                    shortestWait = wait
                end
            end
        end

        if #readyWells == 0 then
            Stats.OilRigCurrentStatus = string.format("All wells refilling (wait %ds)...", math.max(1, shortestWait))
            updateOilRigStats() task.wait(math.clamp(shortestWait, 0.5, 3)) return
        end

        table.sort(readyWells, function(a, b)
            return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
        end)
        local targetWell = readyWells[1]

        local approachCF = CFrame.lookAt(
            Vector3.new(targetWell.Position.X, root.Position.Y, targetWell.Position.Z + 3.5),
            Vector3.new(targetWell.Position.X, root.Position.Y, targetWell.Position.Z))
        if (root.Position - approachCF.Position).Magnitude > 2 then
            Stats.OilRigCurrentStatus = "Moving to " .. targetWell.Name .. "..."
            updateOilRigStats() tweenTo(approachCF)
        end
        if not Config.AutoOilRig then return end

        local wellPrompt = targetWell:FindFirstChildWhichIsA("ProximityPrompt")
        Stats.OilRigCurrentStatus = string.format("Collecting Oil (Hold %.1fs)...", (wellPrompt and wellPrompt.HoldDuration) or 1)
        updateOilRigStats()
        if wellPrompt then firePrompt(wellPrompt) end

        if Config.OilRigActionDelay and Config.OilRigActionDelay > 0 then
            Stats.OilRigCurrentStatus = string.format("Action Delay: Waiting %.1fs...", Config.OilRigActionDelay)
            updateOilRigStats() task.wait(Config.OilRigActionDelay)
        end

        local t0 = tick()
        repeat task.wait(0.05)
        until hasOilCarried or collectionTank:FindFirstChild("OilCarryBeam")
            or (tick() - t0 > 3) or not Config.AutoOilRig
    end

    if not Config.AutoOilRig then return end

    carryingOil = hasOilCarried or (collectionTank:FindFirstChild("OilCarryBeam") ~= nil)
    if carryingOil then
        local tankPrompt = collectionTank:FindFirstChildWhichIsA("ProximityPrompt")
        local deliverCF  = CFrame.lookAt(
            Vector3.new(collectionTank.Position.X + 3.5, root.Position.Y, collectionTank.Position.Z),
            Vector3.new(collectionTank.Position.X,        root.Position.Y, collectionTank.Position.Z))
        Stats.OilRigCurrentStatus = "Moving to Collection Tank..."
        updateOilRigStats() tweenTo(deliverCF)
        if not Config.AutoOilRig then return end
        if (collectionTank.Position - root.Position).Magnitude > 6 then tweenTo(deliverCF) end

        if tankPrompt then
            Stats.OilRigCurrentStatus = string.format("Delivering Oil (Hold %.1fs)...", tankPrompt.HoldDuration or 1.2)
            updateOilRigStats() firePrompt(tankPrompt)
        end

        Stats.OilRigCurrentStatus = "Waiting for server validation..."
        updateOilRigStats()
        local t0 = tick()
        while (hasOilCarried or collectionTank:FindFirstChild("OilCarryBeam")) and (tick() - t0 < 4) do
            task.wait(0.05) if not Config.AutoOilRig then break end
        end
        if not hasOilCarried and not collectionTank:FindFirstChild("OilCarryBeam") then
            Stats.OilRigCurrentStatus = "Delivered Oil Successfully!"
            updateOilRigStats()
        end
    end
    task.wait(0.1)
end

task.spawn(function()
    while true do
        if Config.AutoOilRig then
            local ok, err = pcall(runOilRigFarm)
            if not ok and Config.AutoOilRig then
                warn("[Eagle Nation Hub Oil Rig Farm Error]:", err)
                Stats.OilRigCurrentStatus = "Error: " .. tostring(err)
                updateOilRigStats() task.wait(1)
            end
        else task.wait(0.5) end
    end
end)

-- Mining Farm
local function runMiningFarm()
    local character = LocalPlayer.Character
    local root      = getRootPart(character)
    local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not root or not humanoid then task.wait(1) return end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local pickaxe  = character:FindFirstChild("Pickaxe") or (backpack and backpack:FindFirstChild("Pickaxe"))

    if not pickaxe then
        local miningRemotes = ReplicatedStorage:FindFirstChild("MiningRemotes")
        local buyPickaxe    = miningRemotes and miningRemotes:FindFirstChild("BuyPickaxe")
        if buyPickaxe then
            pcall(function() buyPickaxe:InvokeServer() end)
            task.wait(0.5)
            pickaxe = character:FindFirstChild("Pickaxe") or (backpack and backpack:FindFirstChild("Pickaxe"))
        end
    end

    if pickaxe and pickaxe.Parent == backpack then
        humanoid:EquipTool(pickaxe) task.wait(0.2)
    end

    local bagCount = LocalPlayer:GetAttribute("EN_MiningBag") or 0
    local bagMax   = 10

    if bagCount >= bagMax then
        local traderPos = Vector3.new(-5337.1, 5.59, -899.32)
        local traderCF  = CFrame.lookAt(traderPos + Vector3.new(0, 0, 3.5), traderPos)
        Stats.MiningCurrentStatus = string.format("Bag Full (%d/%d) - Moving to Ore Trader...", bagCount, bagMax)
        updateMiningStats() tweenTo(traderCF)
        if not Config.AutoMining then return end

        if (root.Position - traderPos).Magnitude <= 16 then
            Stats.MiningCurrentStatus = "Selling Ore..."
            updateMiningStats()
            local miningRemotes = ReplicatedStorage:FindFirstChild("MiningRemotes")
            local sellRemote    = miningRemotes and miningRemotes:FindFirstChild("Sell")
            if sellRemote then
                local result = sellRemote:InvokeServer("all")
                if result and type(result) == "table" and result.total and result.total > 0 then
                    Stats.MiningEarnedCash         = Stats.MiningEarnedCash + result.total
                    Stats.MiningEarnedXP           = Stats.MiningEarnedXP + (result.xp or 0)
                    Stats.MiningDeliveriesCompleted = Stats.MiningDeliveriesCompleted + 1
                    Stats.MiningCurrentStatus       = string.format("Sold for +$%s & +%s XP", tostring(result.total), tostring(result.xp or 0))
                    updateMiningStats()
                end
            end
            if Config.MiningActionDelay and Config.MiningActionDelay > 0 then
                task.wait(Config.MiningActionDelay)
            end
        end
        return
    end

    local miningJob    = Workspace:FindFirstChild("MiningJob")
    local activeDeposits = miningJob and miningJob:FindFirstChild("ActiveDeposits")
    if not activeDeposits then
        Stats.MiningCurrentStatus = "Waiting for ActiveDeposits..."
        updateMiningStats() task.wait(1) return
    end

    local deposits = {}
    for _, deposit in ipairs(activeDeposits:GetChildren()) do
        if (deposit:GetAttribute("SwingsLeft") or 1) > 0 then
            table.insert(deposits, deposit)
        end
    end

    if #deposits == 0 then
        Stats.MiningCurrentStatus = "Waiting for deposits to spawn..."
        updateMiningStats() task.wait(1.5) return
    end

    table.sort(deposits, function(a, b)
        return (a:GetPivot().Position - root.Position).Magnitude < (b:GetPivot().Position - root.Position).Magnitude
    end)

    local targetDeposit = deposits[1]
    local depositPos    = targetDeposit:GetPivot().Position
    local approachCF    = CFrame.lookAt(
        Vector3.new(depositPos.X, root.Position.Y, depositPos.Z + 3.8),
        Vector3.new(depositPos.X, root.Position.Y, depositPos.Z))
    if (root.Position - approachCF.Position).Magnitude > 2 then
        Stats.MiningCurrentStatus = "Moving to " .. targetDeposit.Name .. "..."
        updateMiningStats() tweenTo(approachCF)
    end
    if not Config.AutoMining then return end

    local equippedPickaxe = character:FindFirstChild("Pickaxe")
    if not equippedPickaxe and pickaxe and pickaxe.Parent == backpack then
        humanoid:EquipTool(pickaxe) task.wait(0.2)
        equippedPickaxe = character:FindFirstChild("Pickaxe")
    end

    local miningRemotes = ReplicatedStorage:FindFirstChild("MiningRemotes")
    local swingRemote   = miningRemotes and miningRemotes:FindFirstChild("Swing")
    local maxSwings     = 20
    local swingsDone    = 0

    while targetDeposit.Parent
        and (targetDeposit:GetAttribute("SwingsLeft") or 0) > 0
        and swingsDone < maxSwings do
        if not Config.AutoMining then break end
        if (LocalPlayer:GetAttribute("EN_MiningBag") or 0) >= bagMax then break end

        Stats.MiningCurrentStatus = string.format("Mining %s (%d left)...",
            targetDeposit.Name, targetDeposit:GetAttribute("SwingsLeft") or 0)
        updateMiningStats()

        if swingRemote then
            swingRemote:FireServer(targetDeposit)
        elseif equippedPickaxe then
            equippedPickaxe:Activate()
        end

        swingsDone = swingsDone + 1
        task.wait(1)
    end

    if Config.MiningActionDelay and Config.MiningActionDelay > 0 then
        task.wait(Config.MiningActionDelay)
    end
    task.wait(0.1)
end

task.spawn(function()
    while true do
        if Config.AutoMining then
            local ok, err = pcall(runMiningFarm)
            if not ok and Config.AutoMining then
                warn("[Eagle Nation Hub Mining Farm Error]:", err)
                Stats.MiningCurrentStatus = "Error: " .. tostring(err)
                updateMiningStats() task.wait(1)
            end
        else task.wait(0.5) end
    end
end)

-- ============================================================
-- REMOTE EVENT LISTENERS
-- ============================================================

local deliveryEvent = ReplicatedStorage:FindFirstChild("deliveryEvent")
if deliveryEvent then
    deliveryEvent.OnClientEvent:Connect(function(eventType, cash, xp)
        if eventType ~= "STOP" then return end
        if Config.AutoCement then
            if cash and type(cash) == "number" then Stats.CementEarnedCash = Stats.CementEarnedCash + cash end
            if xp   and type(xp)   == "number" then Stats.CementEarnedXP   = Stats.CementEarnedXP   + xp   end
            Stats.CementDeliveriesCompleted = Stats.CementDeliveriesCompleted + 1
            Stats.CementCurrentStatus = string.format("Reward: +$%s & +%s XP", tostring(cash or 650), tostring(xp or 100))
            pcall(updateCementStats)
        else
            if cash and type(cash) == "number" then Stats.EarnedCash = Stats.EarnedCash + cash end
            if xp   and type(xp)   == "number" then Stats.EarnedXP   = Stats.EarnedXP   + xp   end
            Stats.DeliveriesCompleted = Stats.DeliveriesCompleted + 1
            Stats.CurrentStatus = string.format("Reward: +$%s & +%s XP", tostring(cash or 650), tostring(xp or 100))
            pcall(updateFeedingStats)
        end
    end)
end

local oilRigResult = ReplicatedStorage:FindFirstChild("OilRigResult")
if oilRigResult then
    oilRigResult.OnClientEvent:Connect(function(eventType, cash, xp)
        if eventType == "collected" or eventType == "handsfull" then
            hasOilCarried = true
        elseif eventType == "paid" or eventType == "void" or eventType == "empty" then
            hasOilCarried = false
        end
        if eventType == "paid" then
            if cash and type(cash) == "number" then Stats.OilRigEarnedCash = Stats.OilRigEarnedCash + cash end
            if xp   and type(xp)   == "number" then Stats.OilRigEarnedXP   = Stats.OilRigEarnedXP   + xp   end
            Stats.OilRigDeliveriesCompleted = Stats.OilRigDeliveriesCompleted + 1
            Stats.OilRigCurrentStatus = string.format("Reward: +$%s & +%s XP", tostring(cash or 0), tostring(xp or 0))
            pcall(updateOilRigStats)
        end
    end)
end

-- Stats refresh tick
task.spawn(function()
    while true do
        if      Config.AutoFarm    then pcall(updateFeedingStats)
        elseif  Config.AutoCement  then pcall(updateCementStats)
        elseif  Config.AutoOilRig  then pcall(updateOilRigStats)
        elseif  Config.AutoMining  then pcall(updateMiningStats)
        end
        task.wait(1.5)
    end
end)

WindUI:Notify({
    Title   = "Eagle Nation Hub",
    Content = "Eagle Nation Hub loaded successfully! Press [V] to toggle.",
    Duration = 4,
})