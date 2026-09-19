-- JawaDeobf_Instace298_$?# Bypassed API EXECUTE
-- LOLER VM

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local TweenService      = game:GetService("TweenService")

local LocalPlayer   = Players.LocalPlayer
local PlayerGui     = LocalPlayer:WaitForChild("PlayerGui")

-- ── WindUI ────────────────────────────────────────────────────
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-- ── Window — ikut pola DDS persis ─────────────────────────────
local Window = WindUI:CreateWindow({
    Title       = "DX-SR Hub",
    Icon        = "coffee",
    Author      = "DX-SR",
    Folder      = "DX-SR",
    Size        = UDim2.fromOffset(580, 460),
    MinSize     = Vector2.new(560, 350),
    MaxSize     = Vector2.new(850, 560),
    ToggleKey   = Enum.KeyCode.V,
    Transparent = true,
    Theme       = "Dark",
    Resizable   = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar    = false,
    ScrollBarEnabled = false,
})

Window:Tag({
    Title  = "v0.0.0.3",
    Icon   = "github",
    Color  = Color3.fromHex("#30ff6a"),
    Radius = 13,
})

Window:Tag({
    Title  = "DX-SR Hub",
    Icon   = "text-cursor",
    Color  = Color3.fromHex("#1E3A8A"),
    Radius = 13,
})

WindUI:Popup({
    Title   = "DX-SR Hub",
    Icon    = "coffee",
    Content = "Barista Autofarm v0.0.0.3",
    Buttons = {
        {
            Title    = "Continue",
            Icon     = "arrow-right",
            Callback = function() end,
            Variant  = "Primary",
        },
    },
})

-- ── Section → Tab (pola DDS) ──────────────────────────────────
local FarmingSection = Window:Section({
    Title  = "Farming",
    Icon   = "coffee",
    Opened = true,
})

local mainTab = FarmingSection:Tab({
    Title = "Barista",
    Icon  = "coffee",
})

-- ── Config Manager ────────────────────────────────────────────
local CONFIG_DIR = "/config/"
local CONFIG_EXT = ".json"

local ConfigManager = {
    Flags         = {},
    AllConfigs    = {},
    AutoLoad      = false,
    SelectedTheme = "Dark",
}

local defaultConfig = {
    OnlyMobile    = false,
    AutoLoad      = false,
    SelectedTheme = "Dark",
    ToggleKey     = "V",
}

function ConfigManager:CreateConfig(name)
    if not name or name == "" then
        WindUI:Notify({ Title = "Config", Content = "Enter config name first!", Duration = 3 })
        return
    end
    if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
    writefile(CONFIG_DIR .. name .. CONFIG_EXT, HttpService:JSONEncode(defaultConfig))
    WindUI:Notify({ Title = "Config", Content = "'" .. name .. "' saved!", Duration = 3 })
    self:Refresh()
end

function ConfigManager:Load(name)
    if not name or name == "" then
        WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 })
        return
    end
    local path = CONFIG_DIR .. name .. CONFIG_EXT
    if not isfile(path) then
        WindUI:Notify({ Title = "Config", Content = "Config '" .. name .. "' not found!", Duration = 3 })
        return
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
    if not ok then
        WindUI:Notify({ Title = "Config", Content = "Failed to load: " .. name, Duration = 3 })
        return
    end
    for k, v in pairs(data) do self.Flags[k] = v end
    WindUI:Notify({ Title = "Config", Content = "'" .. name .. "' loaded!", Duration = 3 })
end

function ConfigManager:Save(name)
    if not name or name == "" then
        WindUI:Notify({ Title = "Config", Content = "Enter config name first!", Duration = 3 })
        return
    end
    if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
    local ok, err = pcall(writefile, CONFIG_DIR .. name .. CONFIG_EXT, HttpService:JSONEncode(self.Flags))
    if not ok then
        WindUI:Notify({ Title = "Config", Content = "Failed to rewrite: " .. tostring(err), Duration = 3 })
        return
    end
    WindUI:Notify({ Title = "Config", Content = "'" .. name .. "' rewritten!", Duration = 3 })
end

function ConfigManager:Delete(name)
    if not name or name == "" then
        WindUI:Notify({ Title = "Config", Content = "Select config first!", Duration = 3 })
        return
    end
    local path = CONFIG_DIR .. name .. CONFIG_EXT
    if isfile(path) then
        delfile(path)
        WindUI:Notify({ Title = "Config", Content = "'" .. name .. "' deleted!", Duration = 3 })
        self:Refresh()
    end
end

function ConfigManager:SetAutoLoad(name, state)
    self.AutoLoad = state
    self.Flags.AutoLoad = state
    WindUI:Notify({
        Title    = "Config",
        Content  = "Auto load set to '" .. tostring(state) .. "'",
        Duration = 3,
    })
end

function ConfigManager:Refresh()
    self.AllConfigs = {}
    if not isfolder(CONFIG_DIR) then return end
    for _, entry in ipairs(listfiles(CONFIG_DIR)) do
        local fileName = entry:match("([^/\\]+)$")
        if fileName then
            local stem = fileName:match("^(.+)" .. CONFIG_EXT .. "$")
            if stem then table.insert(self.AllConfigs, stem) end
        end
    end
end

-- ── Session Stats ─────────────────────────────────────────────
local Stats = {
    Orders    = 0,
    Salary    = 0,
    XP        = 0,
    StartTime = os.clock(),
}

local function fmtSalary(n)
    return "Rp " .. tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function fmtStats()
    return "Orders: " .. Stats.Orders .. " | Salary: " .. fmtSalary(Stats.Salary)
end

-- ── Autofarm Core ─────────────────────────────────────────────
local AutofarmBarista = {
    Running     = false,
    Thread      = nil,
    Status      = "Idle",
    CurrentStep = "Idle",
}

local BaristaRemote   = nil
local NpcDialogRemote = nil
local JobRemote       = nil

local function getWorkspaceRefs()
    local ws = {
        Barista          = workspace:FindFirstChild("Barista"),
        BaristaCustomers = workspace:WaitForChild("BaristaCustomers", 30),
        NEW_JOB          = workspace:FindFirstChild("NEW_JOB"),
    }
    ws.Stations    = ws.Barista and ws.Barista:FindFirstChild("Stations")
    ws.RecipeBoard = ws.Barista and ws.Barista:FindFirstChild("RecipeBoard")
    ws.NpcManager  = ws.Barista and ws.Barista:FindFirstChild("NPC_BARISTA_MANAGER")
    ws.Telephone   = ws.NEW_JOB
        and ws.NEW_JOB:FindFirstChild("Cafe")
        and ws.NEW_JOB.Cafe:FindFirstChild("Cafe_Kanji_Jawa")
        and ws.NEW_JOB.Cafe.Cafe_Kanji_Jawa:FindFirstChild("Telphone")
        and ws.NEW_JOB.Cafe.Cafe_Kanji_Jawa.Telphone:FindFirstChild("Telephone")
    return ws
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function tweenTo(target, duration)
    local hrp = getHRP()
    if not hrp then return end
    duration = duration or 0.8
    local pos
    if typeof(target) == "Vector3" then
        pos = target
    elseif target:IsA("BasePart") then
        pos = target.Position
    else
        local bp = target:FindFirstChildWhichIsA("BasePart", true)
        pos = bp and bp.Position
    end
    if not pos then return end
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) }
    )
    tween:Play()
    tween.Completed:Wait()
    task.wait(0.3)
end

local function fireProximityPrompt(prompt)
    if not prompt then return end
    fireproximityprompt(prompt, prompt.HoldDuration or 0)
    task.wait((prompt.HoldDuration or 0) + 0.3)
end

local STATION_POSITIONS = {
    BeanHopper     = Vector3.new(8415.3,     23.5, 53.8085098),
    Brewer         = Vector3.new(8416.7,     23.5, 53.8085098),
    Steamer        = Vector3.new(8419,       23.5, 53.8085098),
    Milk           = Vector3.new(8426.7,     23.5, 53.8085098),
    IceMaker       = Vector3.new(8431,       23.5, 53.8085098),
    CreamDispenser = Vector3.new(8433.7,     23.5, 53.8085098),
    Carbonator     = Vector3.new(8436.2,     23.5, 53.8085098),
    BobaPot        = Vector3.new(8436.4,     23.5, 53.8085098),
    WaterTap       = Vector3.new(8436.50586, 23.5, 18.9660721),
    TeaBox         = Vector3.new(8438.5,     23.5, 53.8085098),
    LemonBoard     = Vector3.new(8441,       23.5, 53.8085098),
    MatchaJar      = Vector3.new(8441.2,     23.5, 53.8085098),
    ChocolateJar   = Vector3.new(8443.2,     23.5, 53.8085098),
    CreamJar       = Vector3.new(8443.6,     23.5, 53.8085098),
    FlavourBottle  = Vector3.new(8449,       23.5, 53.8085098),
    CupRack        = Vector3.new(8413.8,     23.5, 53.8085098),
    Trash          = Vector3.new(8409.1,     23.5, 53.8085098),
    BrewHoldArea   = Vector3.new(8415.4,     23.5, 53.8085098),
}

local lastCupState  = nil
local lastOrderData = nil
local baristaConn   = nil

local function attachListener()
    if baristaConn then baristaConn:Disconnect() end
    lastCupState  = nil
    lastOrderData = nil
    if not BaristaRemote then return end

    baristaConn = BaristaRemote.OnClientEvent:Connect(function(action, data, extra)
        if action == "CupState" and type(data) == "table" then
            lastCupState = data
            AutofarmBarista.CurrentStep = tostring(data.nextStep or data.nextStation or "?")

        elseif action == "OrderTaken" and not lastOrderData then
            lastOrderData = { menuId = data, flavour = extra }

        elseif action == "OrderDone" then
            Stats.Orders += 1

        elseif action == "JobProgress" and type(data) == "table" then
            Stats.Salary = tonumber(data.salary or 0) or 0
            Stats.XP     = tonumber(data.xp    or 0) or 0

        elseif action == "LevelUpBanner" then
            WindUI:Notify({ Title = "Level Up!", Content = tostring(data) .. " XP", Duration = 3, Icon = "sparkles" })

        elseif action == "HasClaimable" then
            BaristaRemote:FireServer("Claim")
        end
    end)
end

-- ── Brew Minigame ─────────────────────────────────────────────
local function autoBrewMinigame()
    local jobGui = PlayerGui:FindFirstChild("Job")
    if not jobGui then return false end
    local brewGui = jobGui:FindFirstChild("BrewMinigame")
    if not brewGui or not brewGui.Visible then return false end

    local track  = brewGui:FindFirstChild("Track")
    local zone   = track and track:FindFirstChild("Zone")
    local needle = track and track:FindFirstChild("Needle")
    local result = brewGui:FindFirstChild("ResultLabel")
    if not (zone and needle and result) then return false end

    local t = 0
    while zone.AbsoluteSize.X == 0 and t < 30 do
        task.wait(0.05); t += 1
    end

    BaristaRemote:FireServer("BrewStart")
    task.wait(0.3)

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not brewGui.Visible or not AutofarmBarista.Running then
            conn:Disconnect(); return
        end
        local needleMid = needle.AbsolutePosition.X + needle.AbsoluteSize.X / 2
        local zoneLeft  = zone.AbsolutePosition.X
        local zoneRight = zoneLeft + zone.AbsoluteSize.X
        if needleMid > zoneLeft and needleMid < zoneRight then
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end)

    t = 0
    while result.Text ~= "100%" and t < 300 and AutofarmBarista.Running do
        task.wait(0.1); t += 1
    end
    conn:Disconnect()

    local success = result.Text == "100%"
    BaristaRemote:FireServer("BrewResult", success and 1 or 0)
    task.wait(0.3)
    return success
end

-- ── Serve flow ────────────────────────────────────────────────
local function waitForCupState(timeout)
    lastCupState = nil
    local t = 0
    timeout = (timeout or 5) * 10
    while not lastCupState and t < timeout and AutofarmBarista.Running do
        task.wait(0.1); t += 1
    end
    local d = lastCupState
    lastCupState = nil
    return d
end

local function runStationLoop(ws)
    for step = 1, 30 do
        if not AutofarmBarista.Running then break end

        local data = waitForCupState(8)
        if not data then
            warn("[Barista] CupState timeout step " .. step)
            break
        end

        if data.ruined then
            AutofarmBarista.CurrentStep = "Cup ruined, discarding..."
            WindUI:Notify({ Title = "Barista", Content = "Cup ruined, discarding...", Duration = 2 })
            return "ruined"
        end

        if data.doneCount and data.stepCount and data.doneCount >= data.stepCount then
            AutofarmBarista.CurrentStep = "Ready to Serve!"
            return "done"
        end

        local stationName = data.nextStation
        if not stationName then break end

        AutofarmBarista.CurrentStep = "Step " .. step .. ": " .. tostring(data.nextStep or stationName)
        print("[Barista] Step " .. step .. " → " .. stationName)

        local hrp = getHRP()
        if hrp then
            local stationPos = STATION_POSITIONS[stationName]
            if stationPos then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(stationPos)
            else
                local stationObj = ws.Stations and ws.Stations:FindFirstChild(stationName)
                if stationObj then tweenTo(stationObj) end
            end
        end
        task.wait(0.4)

        local stationObj = ws.Stations and ws.Stations:FindFirstChild(stationName)
        local prompt = stationObj and stationObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            fireProximityPrompt(prompt)
        else
            BaristaRemote:FireServer("Station", stationName)
        end
        task.wait(0.3)

        task.wait(0.2)
        autoBrewMinigame()
    end
    return "timeout"
end

local function takeOrderFromCustomer(customer, ws, orderIndex)
    local hrp = customer:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    AutofarmBarista.CurrentStep = "Taking order #" .. orderIndex
    tweenTo(hrp)

    BaristaRemote:FireServer("TakeOrder", orderIndex)
    task.wait(0.5)

    local servePrompt = hrp:FindFirstChild("BaristaServePrompt")
    if servePrompt then fireProximityPrompt(servePrompt) end
    task.wait(0.5)

    lastOrderData = nil
    local t = 0
    while not lastOrderData and t < 150 and AutofarmBarista.Running do
        task.wait(0.1); t += 1
    end

    return lastOrderData
end

local function makeDrink(orderData, ws)
    local menuId  = orderData.menuId  or "?"
    local flavour = orderData.flavour or "?"

    print("[Barista] Preparing " .. menuId .. " (Flavour: " .. tostring(flavour) .. ")")
    AutofarmBarista.CurrentStep = "Taking cup for " .. menuId

    WindUI:Notify({
        Title    = "Barista",
        Content  = "Preparing " .. menuId .. " (Flavour: " .. tostring(flavour) .. ")",
        Duration = 3,
        Icon     = "coffee",
    })

    BaristaRemote:FireServer("Pick", "Menu", menuId)
    task.wait(0.5)

    local hrp = getHRP()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(STATION_POSITIONS.CupRack)
    end
    task.wait(0.4)

    local cupRack   = ws.Stations and ws.Stations:FindFirstChild("CupRack")
    local cupPrompt = cupRack and cupRack:FindFirstChildWhichIsA("ProximityPrompt", true)
    if cupPrompt then
        fireProximityPrompt(cupPrompt)
    else
        BaristaRemote:FireServer("Station", "CupRack")
    end
    task.wait(0.5)

    local result = runStationLoop(ws)

    if result == "ruined" then
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(STATION_POSITIONS.Trash)
        end
        task.wait(0.3)
        local trashObj    = ws.Stations and ws.Stations:FindFirstChild("Trash")
        local trashPrompt = trashObj and trashObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if trashPrompt then
            fireProximityPrompt(trashPrompt)
        else
            BaristaRemote:FireServer("Station", "Trash")
        end
        task.wait(0.5)

        BaristaRemote:FireServer("Pick", "Menu", menuId)
        task.wait(0.5)
        if cupPrompt then
            fireProximityPrompt(cupPrompt)
        else
            BaristaRemote:FireServer("Station", "CupRack")
        end
        task.wait(0.5)
        result = runStationLoop(ws)
    end

    return result
end

local function serveCustomer(customer, ws)
    local hrp = customer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    AutofarmBarista.CurrentStep = "Serving drink to customer..."
    tweenTo(hrp)

    local servePrompt = hrp:FindFirstChild("BaristaServePrompt")
    if servePrompt then
        fireProximityPrompt(servePrompt)
    else
        BaristaRemote:FireServer("Serve", customer.Name)
    end
    task.wait(0.5)

    WindUI:Notify({
        Title    = "Barista",
        Content  = "Order #" .. Stats.Orders .. " done! " .. fmtStats(),
        Duration = 3,
        Icon     = "coffee",
    })
end

-- ── Main job loop ─────────────────────────────────────────────
local function startJob()
    print("[Barista] CDID BARISTA AUTOFARM LOADED!")

    local remotes = ReplicatedStorage
        :WaitForChild("NetworkContainer", 30)
        :WaitForChild("RemoteEvents", 30)

    JobRemote = remotes:WaitForChild("Job", 30)
    if JobRemote then
        JobRemote:FireServer("Unemployee")
        task.wait(1)
    end

    NpcDialogRemote = remotes:WaitForChild("NpcDialog", 60)
    BaristaRemote   = remotes:WaitForChild("Barista",   60)
    if not BaristaRemote then
        warn("[Barista] Remote not found!")
        AutofarmBarista.Running = false
        return
    end

    attachListener()

    local ws = getWorkspaceRefs()

    AutofarmBarista.CurrentStep = "Starting Barista job at Manager..."
    print("[Barista] Going to NPC Manager...")

    if ws.NpcManager then
        local head = ws.NpcManager:FindFirstChild("Head")
        if head then
            tweenTo(head, 4)
            task.wait(0.5)
            local dialogPrompt = head:FindFirstChild("DialogPrompt")
                or head:FindFirstChildWhichIsA("ProximityPrompt", true)
            if dialogPrompt then fireProximityPrompt(dialogPrompt) end
        end
    end

    task.wait(2)
    if NpcDialogRemote then
        firesignal(NpcDialogRemote.OnClientEvent, "Start", {
            lines = { "Welcome back!", "Counter is yours." },
            jobId = "Barista",
            first = false,
            npc   = ws.NpcManager,
        })
    end
    task.wait(0.5)
    for _ = 1, 6 do
        VirtualUser:ClickButton2(Vector2.new(0, 0))
        task.wait(0.8)
    end

    AutofarmBarista.CurrentStep = "Tanya Pesanan"
    task.wait(3)

    if ws.Telephone then
        tweenTo(ws.Telephone)
        task.wait(0.5)
        local phonePrompt = ws.Telephone:FindFirstChild("BaristaPhonePrompt")
            or ws.Telephone:FindFirstChildWhichIsA("ProximityPrompt", true)
        if phonePrompt then fireProximityPrompt(phonePrompt) end
        task.wait(1)
        firesignal(BaristaRemote.OnClientEvent, "Tutorial")
        task.wait(0.3)
        for _ = 1, 26 do
            VirtualUser:ClickButton2(Vector2.new(0, 0))
            task.wait(0.5)
        end
    end

    task.wait(2)

    local orderIndex = 1
    while AutofarmBarista.Running do
        AutofarmBarista.CurrentStep = "Waiting for customer..."
        print("[Barista] Waiting for customer...")

        local target  = nil
        local elapsed = 0
        while not target and elapsed < 30 and AutofarmBarista.Running do
            if ws.BaristaCustomers then
                for _, c in ipairs(ws.BaristaCustomers:GetChildren()) do
                    local cHRP = c:FindFirstChild("HumanoidRootPart")
                    if cHRP and cHRP:FindFirstChild("BaristaServePrompt") then
                        target = c; break
                    end
                end
            end
            task.wait(1); elapsed += 1
        end

        if not target then task.wait(2); continue end

        local orderData = takeOrderFromCustomer(target, ws, orderIndex)
        if not orderData then
            warn("[Barista] No order data for order #" .. orderIndex)
            orderIndex += 1; task.wait(1); continue
        end

        local result = makeDrink(orderData, ws)
        print("[Barista] Make result: " .. tostring(result))

        if result ~= "timeout" then
            serveCustomer(target, ws)
        end

        orderIndex += 1
        task.wait(0.5)
    end

    if baristaConn then baristaConn:Disconnect() end
    AutofarmBarista.CurrentStep = "Idle"
    print("[Barista] Autofarm stopped.")
end

-- ── Main Tab UI — pakai Section:Element() bukan Tab:CreateX() ─
local farmSection = mainTab:Section({
    Title  = "Autofarm Barista",
    Opened = true,
})

local statusLabel = farmSection:Paragraph({ Title = "Status",        Desc = "Idle" })
local stepLabel   = farmSection:Paragraph({ Title = "Current Step",  Desc = "Idle" })
local statsLabel  = farmSection:Paragraph({ Title = "Session Stats", Desc = "Orders: 0 | Salary: Rp 0" })

farmSection:Toggle({
    Title    = "Barista Autofarm",
    Desc     = "Auto complete barista orders",
    Default  = false,
    Flag     = "AutofarmBarista",
    Callback = function(state)
        AutofarmBarista.Running = state
        ConfigManager.Flags.AutofarmBarista = state
        if state then
            WindUI:Notify({ Title = "Barista Autofarm", Content = "CDID BARISTA AUTOFARM LOADED!", Duration = 3, Icon = "coffee" })
            AutofarmBarista.Thread = task.spawn(function()
                local ok, err = pcall(startJob)
                if not ok then
                    warn("[Barista] Error: " .. tostring(err))
                    WindUI:Notify({ Title = "Error", Content = tostring(err), Duration = 5 })
                    AutofarmBarista.Running = false
                end
            end)
        else
            if AutofarmBarista.Thread then
                task.cancel(AutofarmBarista.Thread)
                AutofarmBarista.Thread = nil
            end
            if baristaConn then baristaConn:Disconnect() end
            AutofarmBarista.CurrentStep = "Idle"
            WindUI:Notify({ Title = "Barista Autofarm", Content = "Stopped.", Duration = 2 })
        end
    end,
})

farmSection:Toggle({
    Title    = "Only Mobile",
    Desc     = "Use mobile-only input method",
    Default  = false,
    Flag     = "OnlyMobile",
    Callback = function(state)
        ConfigManager.Flags.OnlyMobile = state
    end,
})

-- Status update loop
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            statusLabel:SetDesc(AutofarmBarista.Running and "Running" or "Idle")
            stepLabel:SetDesc(AutofarmBarista.CurrentStep or "Idle")
            statsLabel:SetDesc(fmtStats())
        end)
    end
end)

-- ── Settings Tab ──────────────────────────────────────────────
local settingsTab = FarmingSection:Tab({ Title = "Settings", Icon = "settings" })

local cfgSection = settingsTab:Section({ Title = "Configuration", Opened = true })

cfgSection:Input({
    Title       = "Config Name",
    Desc        = "New config name",
    Placeholder = "Enter config name...",
    Flag        = "ConfigNameInput",
    Callback    = function(v) ConfigManager.Flags.ConfigNameInput = v end,
})

cfgSection:Button({
    Title    = "Save Config",
    Desc     = "Save current settings to new config",
    Icon     = "save",
    Callback = function()
        ConfigManager:CreateConfig(ConfigManager.Flags.ConfigNameInput)
    end,
})

local loadSection = settingsTab:Section({ Title = "Load / Delete Config", Opened = true })

local configDropdown = loadSection:Dropdown({
    Title  = "Select Config",
    Desc   = "Choose saved config",
    Values = ConfigManager.AllConfigs,
    Multi  = false,
    Flag   = "SelectedConfigDropdown",
    Callback = function(v)
        ConfigManager.Flags.SelectedConfigDropdown = v
    end,
})

loadSection:Button({
    Title    = "Load Config",
    Desc     = "Load selected config",
    Icon     = "arrow-right",
    Callback = function()
        ConfigManager:Load(ConfigManager.Flags.SelectedConfigDropdown)
    end,
})

loadSection:Button({
    Title    = "Rewrite Config",
    Desc     = "Rewrite selected config",
    Callback = function()
        ConfigManager:Save(ConfigManager.Flags.SelectedConfigDropdown)
    end,
})

loadSection:Button({
    Title    = "Delete Config",
    Desc     = "Delete selected config",
    Callback = function()
        ConfigManager:Delete(ConfigManager.Flags.SelectedConfigDropdown)
        configDropdown:Refresh(ConfigManager.AllConfigs)
    end,
})

loadSection:Toggle({
    Title    = "Set Auto Load",
    Desc     = "Automatically load selected config on start",
    Default  = false,
    Flag     = "AutoLoad",
    Callback = function(state)
        ConfigManager:SetAutoLoad(ConfigManager.Flags.SelectedConfigDropdown, state)
    end,
})

-- ── Theme Tab ─────────────────────────────────────────────────
local themeTab = FarmingSection:Tab({ Title = "Theme", Icon = "palette" })
local themeSection = themeTab:Section({ Title = "Select Theme", Opened = true })

themeSection:Dropdown({
    Title    = "Choose UI Theme",
    Values   = {
        "Dark", "Light", "Midnight", "Emerald", "Crimson",
        "Indigo", "Amber", "Violet", "Rose", "Sky",
        "Rainbow", "Monokai Pro",
    },
    Default  = "Dark",
    Flag     = "SelectedTheme",
    Callback = function(val)
        Window:SetTheme(val)
        ConfigManager.Flags.SelectedTheme = val
    end,
})

-- ── Info Tab ──────────────────────────────────────────────────
local infoTab = FarmingSection:Tab({ Title = "Information", Icon = "info" })
local infoSection = infoTab:Section({ Title = "Script Hub", Opened = true })

infoSection:Paragraph({ Title = "Hub",     Desc = "DX-SR Hub" })
infoSection:Paragraph({ Title = "Script",  Desc = "Autofarm Barista" })
infoSection:Paragraph({ Title = "Version", Desc = "v0.0.0.3" })
infoSection:Paragraph({ Title = "Author",  Desc = "DX-SR" })
infoSection:Paragraph({ Title = "Theme",   Desc = "WindUI" })

-- ── Open Button — ikut DDS ────────────────────────────────────
Window:EditOpenButton({
    Title         = "DX-SR Hub",
    Icon          = "coffee",
    CornerRadius  = UDim.new(0, 16),
    StrokeThickness = 2,
    Color         = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    OnlyMobile    = false,
    Enabled       = true,
})

-- ── Notify + Auto load ────────────────────────────────────────
WindUI:Notify({
    Title    = "DX-SR Hub",
    Content  = "Barista Autofarm v0.0.0.3 loaded! Press V to toggle UI.",
    Duration = 5,
    Icon     = "coffee",
})

ConfigManager:Refresh()
if ConfigManager.AutoLoad and ConfigManager.Flags.SelectedConfigDropdown then
    ConfigManager:Load(ConfigManager.Flags.SelectedConfigDropdown)
end