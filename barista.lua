-- JawaDeobf_Instace298_$?# Bypassed API EXECUTE
-- LOLER VM

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")
local VIM          = game:GetService("VirtualInputManager")

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

Window:Tag({ Title="v0.0.0.4",  Icon="github",      Color=Color3.fromHex("#30ff6a"), Radius=13 })
Window:Tag({ Title="DX-SR Hub", Icon="text-cursor", Color=Color3.fromHex("#1E3A8A"), Radius=13 })

-- ── Tabs ──────────────────────────────────────────────────────
local FarmSection = Window:Section({ Title="Farming", Icon="coffee", Opened=true })
local mainTab     = FarmSection:Tab({ Title="Barista",     Icon="coffee"   })
local debugTab    = FarmSection:Tab({ Title="Debug",       Icon="terminal" })
local settingsTab = FarmSection:Tab({ Title="Settings",    Icon="settings" })
local themeTab    = FarmSection:Tab({ Title="Theme",       Icon="palette"  })
local infoTab     = FarmSection:Tab({ Title="Information", Icon="info"     })

-- ── State ─────────────────────────────────────────────────────
local baristaEnabled = false
local jobCount       = 0
local stuckCount     = 0
local currentStep    = "Idle"
local currentOrder   = ""

-- ── CFrames (dari user) ───────────────────────────────────────
local CF_START_NPC  = CFrame.new(-7.123, 23.449, 8428.728, 0.964, 0.000, -0.267, -0.000, 1.000, -0.000, 0.267, 0.000, 0.964)
local CF_PHONE      = CFrame.new(-7.123, 23.449, 8428.728, 0.964, 0.000, -0.267, -0.000, 1.000, 0.000, 0.267, -0.000, 0.964)
local CF_ORDER_NPC  = CFrame.new(-31.310, 23.449, 8424.950, 0.720, 0.000, 0.694, 0.000, 1.000, -0.000, -0.694, 0.000, 0.720)
local CF_CUP_RACK   = CFrame.new(-13.293, 23.452, 8411.473, 0.914, 0.000, -0.407, -0.000, 1.000, 0.000, 0.407, -0.000, 0.914)

-- ── Debug log ─────────────────────────────────────────────────
local debugLog     = {}
local debugEnabled = false

local function dlog(msg)
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
    print(line)
    table.insert(debugLog, 1, line)
    if #debugLog > 50 then table.remove(debugLog) end
end

-- ── Core functions (pola BCA) ─────────────────────────────────
local function teleportPlayer(cf)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function firePrompt(prompt)
    if not prompt then return end
    local oldLoS  = prompt.RequiresLineOfSight
    local oldDist = prompt.MaxActivationDistance
    prompt.RequiresLineOfSight   = false
    prompt.MaxActivationDistance = 60
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait((prompt.HoldDuration or 0) + 0.1)
        prompt:InputHoldEnd()
    end
    task.delay(0.5, function()
        if prompt and prompt.Parent then
            prompt.RequiresLineOfSight   = oldLoS
            prompt.MaxActivationDistance = oldDist
        end
    end)
end

-- Cari ProximityPrompt terdekat dari posisi
local function findPromptNear(pos, radius, keywords)
    local best, bestDist = nil, (radius or 10)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local dist = (part.Position - pos).Magnitude
                if dist < bestDist then
                    if keywords then
                        local at = (obj.ActionText or ""):lower()
                        local nm = (obj.Name or ""):lower()
                        for _, kw in ipairs(keywords) do
                            if at:find(kw:lower()) or nm:find(kw:lower()) then
                                best = obj; bestDist = dist; break
                            end
                        end
                    else
                        best = obj; bestDist = dist
                    end
                end
            end
        end
    end
    return best
end

-- Baca teks "Next:" dari job UI
local function getJobNextText()
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
            local t = obj.Text or ""
            if t:find("Next:") or t:find("Grab") or t:find("Load") or t:find("Pour") 
               or t:find("Add") or t:find("Place") or t:find("Serve") then
                return t
            end
        end
    end
    return ""
end

-- Baca order customer dari speech bubble / UI
local function getCustomerOrderText()
    -- Cek PlayerGui dulu
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local t = obj.Text or ""
            if t:lower():find("like a") or t:lower():find("i want") 
               or t:lower():find("coffee") or t:lower():find("milk")
               or t:lower():find("tea") or t:lower():find("cappuc")
               or t:lower():find("please") then
                return t
            end
        end
    end
    -- Cek BillboardGui di workspace (speech bubble NPC)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") then
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") then
                    local t = child.Text or ""
                    if t:lower():find("like a") or t:lower():find("please")
                       or t:lower():find("coffee") or t:lower():find("milk") then
                        return t
                    end
                end
            end
        end
    end
    return ""
end

-- Cari orange waypoint (warna oren, downward arrow)
local function findOrangeWaypoint()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local best, bestDist = nil, math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local c = obj.Color
            -- Orange: R tinggi, G medium, B rendah
            local isOrange = c.R > 0.75 and c.G > 0.2 and c.G < 0.7 and c.B < 0.15
            if isOrange then
                local n = obj.Name:lower()
                -- Prioritas kalau namanya kayak waypoint/arrow
                local isWaypoint = n:find("arrow") or n:find("waypoint") or n:find("target")
                    or n:find("point") or n:find("indicator") or n:find("marker")
                    or obj.Size.Y < 1.5
                if isWaypoint or obj.Transparency < 0.8 then
                    local dist = hrp and (obj.Position - hrp.Position).Magnitude or 0
                    if dist < bestDist then
                        best = obj; bestDist = dist
                    end
                end
            end
        end
        -- Cek juga BillboardGui oren
        if obj:IsA("BillboardGui") then
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Frame") or child:IsA("ImageLabel") then
                    local c = child.BackgroundColor3
                    local isOrange = c.R > 0.75 and c.G > 0.2 and c.G < 0.7 and c.B < 0.15
                    if isOrange and obj.Parent and obj.Parent:IsA("BasePart") then
                        local dist = hrp and (obj.Parent.Position - hrp.Position).Magnitude or 0
                        if dist < bestDist then
                            best = obj.Parent; bestDist = dist
                        end
                    end
                end
            end
        end
    end
    return best, bestDist
end

-- Cari station di workspace berdasar nama
local function findStationObject(name)
    local nameL = name:lower()
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find(nameL) then
            local prompt = obj:IsA("BasePart")
                and obj:FindFirstChildWhichIsA("ProximityPrompt")
                or (obj:IsA("Model") and obj:FindFirstChildWhichIsA("ProximityPrompt", true))
            if prompt then
                local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                return pos, prompt
            end
        end
    end
    return nil, nil
end

-- Parse nama station dari teks "Next: ... at Coffee Maker (E)"
local function parseStation(text)
    -- "Next: Load Beans - at Coffee Maker (E)"
    local station = text:match("at (.+)%(")
        or text:match("at (.+)$")
        or text:match("from the (.+)%(")
        or text:match("from the (.+)$")
    if station then return station:gsub("%s+$",""):gsub("^%s+","") end
    return nil
end

-- Handle syrup/topping selection GUI
local function handleSelectionGUI(orderText)
    task.wait(0.3)
    local order = orderText:lower()
    -- Cari GUI yang muncul setelah interact
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextButton") and obj.Visible then
            local t = obj.Text:lower()
            -- Cocokkan dengan order customer
            if order:find("grape") and t:find("grape") then
                dlog("Pilih: " .. obj.Text)
                fireclick(obj); return
            elseif order:find("vanilla") and t:find("vanilla") then
                dlog("Pilih: " .. obj.Text)
                fireclick(obj); return
            elseif order:find("caramel") and t:find("caramel") then
                dlog("Pilih: " .. obj.Text)
                fireclick(obj); return
            elseif order:find("strawberry") and t:find("strawberry") then
                dlog("Pilih: " .. obj.Text)
                fireclick(obj); return
            elseif order:find("hazelnut") and t:find("hazelnut") then
                dlog("Pilih: " .. obj.Text)
                fireclick(obj); return
            end
        end
    end
end

-- Wait sampai next text berubah
local function waitNextChange(oldText, timeout)
    local t0 = os.clock()
    while baristaEnabled and (os.clock()-t0) < (timeout or 5) do
        local newText = getJobNextText()
        if newText ~= oldText and newText ~= "" then return newText end
        task.wait(0.2)
    end
    return getJobNextText()
end

-- ── Main Barista Logic ────────────────────────────────────────
local function runBarista()
    -- Step 1: Teleport ke Start NPC, mulai job
    currentStep = "Start Job NPC"
    dlog("=== BARISTA START ===")
    dlog("Teleport ke Start NPC")
    teleportPlayer(CF_START_NPC)
    task.wait(0.8)

    local startPrompt = findPromptNear(CF_START_NPC.Position, 8)
    if startPrompt then
        dlog("Fire start prompt: " .. (startPrompt.ActionText or "?"))
        firePrompt(startPrompt)
        task.wait(1.5)
    else
        dlog("WARN: start prompt tidak ditemukan")
    end

    -- Step 2: Teleport ke phone
    currentStep = "Phone"
    dlog("Teleport ke Phone")
    teleportPlayer(CF_PHONE)
    task.wait(0.8)

    -- Tunggu phone prompt muncul
    local t0 = os.clock()
    local phoneFired = false
    while baristaEnabled and (os.clock()-t0) < 8 do
        local phonePrompt = findPromptNear(CF_PHONE.Position, 8,
            {"pick up","answer","phone","angkat","telephone","pickup"})
        if phonePrompt then
            dlog("Fire phone: " .. (phonePrompt.ActionText or "?"))
            firePrompt(phonePrompt)
            task.wait(1)
            phoneFired = true
            break
        end
        -- Coba prompt apapun yang ada di sana
        local anyPrompt = findPromptNear(CF_PHONE.Position, 5)
        if anyPrompt then
            dlog("Fire any prompt at phone: " .. (anyPrompt.ActionText or "?"))
            firePrompt(anyPrompt)
            task.wait(1)
            phoneFired = true
            break
        end
        task.wait(0.3)
    end

    if not phoneFired then
        dlog("WARN: phone prompt timeout")
    end

    task.wait(1)

    -- ── Order loop ────────────────────────────────────────────
    while baristaEnabled do
        currentStep = "Waiting Customer"

        -- Step 3: Detect orange waypoint → customer
        dlog("Cari orange waypoint...")
        local wp, wpDist = nil, math.huge
        t0 = os.clock()
        while baristaEnabled and (os.clock()-t0) < 12 do
            wp, wpDist = findOrangeWaypoint()
            if wp then
                dlog("Waypoint: " .. wp:GetFullName() .. " dist:" .. math.floor(wpDist))
                break
            end
            task.wait(0.5)
        end

        if wp then
            -- Teleport ke waypoint
            currentStep = "Go to Waypoint"
            dlog("Teleport ke waypoint pos: " .. tostring(wp.Position))
            teleportPlayer(CFrame.new(wp.Position + Vector3.new(0, 3, 0)))
            task.wait(0.5)

            -- Fire prompt di area waypoint
            local wpPrompt = findPromptNear(wp.Position, 8)
            if wpPrompt then
                dlog("Fire waypoint prompt: " .. (wpPrompt.ActionText or "?"))
                firePrompt(wpPrompt)
                task.wait(0.5)
            end
        end

        -- Step 3b: Ke Order NPC
        currentStep = "Order NPC"
        dlog("Teleport ke Order NPC")
        teleportPlayer(CF_ORDER_NPC)
        task.wait(0.5)

        local orderPrompt = findPromptNear(CF_ORDER_NPC.Position, 8)
        if orderPrompt then
            dlog("Fire order prompt: " .. (orderPrompt.ActionText or "?"))
            firePrompt(orderPrompt)
            task.wait(1)
        end

        -- Baca order customer
        task.wait(0.5)
        currentOrder = getCustomerOrderText()
        dlog("Customer order: " .. currentOrder)

        -- Step 4: Ke Cup Rack
        currentStep = "Cup Rack"
        dlog("Teleport ke Cup Rack")
        teleportPlayer(CF_CUP_RACK)
        task.wait(0.5)

        local cupPrompt = findPromptNear(CF_CUP_RACK.Position, 8)
        if cupPrompt then
            dlog("Fire cup rack: " .. (cupPrompt.ActionText or "?"))
            firePrompt(cupPrompt)
            task.wait(0.8)
        end

        -- Step 5: Ikutin "Next:" dari job UI
        currentStep = "Making Drink"
        local maxSteps = 25
        local step = 0
        local lastNextText = ""

        while baristaEnabled and step < maxSteps do
            step += 1
            task.wait(0.4)

            local nextText = getJobNextText()
            dlog("[Step "..step.."] Next: " .. nextText)

            if nextText == "" then
                -- Cek apakah ada serve prompt (sudah selesai buat minuman)
                local servePrompt = findPromptNear(CF_ORDER_NPC.Position, 15,
                    {"serve","antar","deliver","kasih"})
                if servePrompt then
                    currentStep = "Serving"
                    dlog("Serve prompt ditemukan!")
                    teleportPlayer(CF_ORDER_NPC)
                    task.wait(0.5)
                    firePrompt(servePrompt)
                    task.wait(1)
                    break
                end
                -- Detect orange waypoint (serve ke customer)
                local servWp = findOrangeWaypoint()
                if servWp then
                    dlog("Serve waypoint: " .. servWp:GetFullName())
                    teleportPlayer(CFrame.new(servWp.Position + Vector3.new(0,3,0)))
                    task.wait(0.5)
                    local servPrompt = findPromptNear(servWp.Position, 8)
                    if servPrompt then
                        dlog("Fire serve: " .. (servPrompt.ActionText or "?"))
                        firePrompt(servPrompt)
                        task.wait(1)
                    end
                    break
                end
                task.wait(0.5)
                continue
            end

            -- Skip kalau teks sama
            if nextText == lastNextText then
                -- Mungkin lagi nunggu animasi — coba fire lagi
                task.wait(0.5)
                continue
            end
            lastNextText = nextText

            -- Parse nama station
            local stationName = parseStation(nextText)
            local moved = false

            if stationName then
                dlog("Station: " .. stationName)
                local stPos, stPrompt = findStationObject(stationName)
                if stPos then
                    dlog("Teleport ke " .. stationName)
                    teleportPlayer(CFrame.new(stPos + Vector3.new(0,3,0)))
                    task.wait(0.4)
                    if stPrompt then
                        dlog("Fire station prompt: " .. (stPrompt.ActionText or "?"))
                        firePrompt(stPrompt)
                        task.wait(0.5)
                        -- Handle syrup/topping GUI kalau muncul
                        handleSelectionGUI(currentOrder)
                    end
                    moved = true
                end
            end

            -- Kalau station tidak ketemu by name, pakai orange waypoint
            if not moved then
                local owp = findOrangeWaypoint()
                if owp then
                    dlog("Waypoint fallback: " .. owp:GetFullName())
                    teleportPlayer(CFrame.new(owp.Position + Vector3.new(0,3,0)))
                    task.wait(0.4)
                    local owpPrompt = findPromptNear(owp.Position, 8)
                    if owpPrompt then
                        dlog("Fire waypoint prompt: " .. (owpPrompt.ActionText or "?"))
                        firePrompt(owpPrompt)
                        task.wait(0.5)
                        handleSelectionGUI(currentOrder)
                    end
                else
                    dlog("WARN: tidak ada waypoint maupun station")
                    stuckCount += 1
                    task.wait(1)
                end
            end
        end

        -- Order selesai
        jobCount += 1
        currentStep = "Done #" .. jobCount
        dlog("Order #" .. jobCount .. " selesai! Order: " .. currentOrder)
        WindUI:Notify({
            Title   = "Barista",
            Content = "Order #" .. jobCount .. " selesai!",
            Duration = 2,
            Icon    = "coffee",
        })

        currentOrder = ""
        task.wait(1)
    end

    currentStep = "Idle"
    dlog("=== BARISTA STOP ===")
end

-- ── Main Tab UI ───────────────────────────────────────────────
local farmSection  = mainTab:Section({ Title="Autofarm Barista", Opened=true })
local statusLabel  = farmSection:Paragraph({ Title="Status",      Desc="Idle"  })
local stepLabel    = farmSection:Paragraph({ Title="Step",        Desc="Idle"  })
local orderLabel   = farmSection:Paragraph({ Title="Order",       Desc="-"     })
local jobsLabel    = farmSection:Paragraph({ Title="Jobs Done",   Desc="0"     })
local stuckLabel   = farmSection:Paragraph({ Title="Stuck Count", Desc="0"     })

farmSection:Toggle({
    Title    = "Barista Autofarm",
    Desc     = "Jalan ke area barista dulu, baru toggle on",
    Default  = false,
    Flag     = "AutofarmBarista",
    Callback = function(state)
        baristaEnabled = state
        dlog("Toggle: " .. tostring(state))
        if state then
            WindUI:Notify({ Title="Barista", Content="AKTIF!", Duration=3, Icon="coffee" })
            task.spawn(function()
                local ok, err = pcall(runBarista)
                if not ok then
                    dlog("ERROR: " .. tostring(err))
                    WindUI:Notify({ Title="Error", Content=tostring(err), Duration=5 })
                    baristaEnabled = false
                end
            end)
        else
            WindUI:Notify({ Title="Barista", Content="Stopped.", Duration=2 })
        end
    end,
})

-- UI update loop
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            statusLabel:SetDesc(baristaEnabled and "Running" or "Idle")
            stepLabel:SetDesc(currentStep)
            orderLabel:SetDesc(currentOrder ~= "" and currentOrder or "-")
            jobsLabel:SetDesc(tostring(jobCount))
            stuckLabel:SetDesc(tostring(stuckCount))
        end)
    end
end)

-- ── Debug Tab ─────────────────────────────────────────────────
local dbgSection = debugTab:Section({ Title="Debug Log", Opened=true })
local logLabel   = dbgSection:Paragraph({ Title="Log", Desc="Waiting..." })

dbgSection:Toggle({
    Title="Live Log", Default=false, Flag="DebugLive",
    Callback=function(v) debugEnabled=v end,
})

dbgSection:Button({
    Title="Scan Semua Prompts", Desc="Dump ke console",
    Callback=function()
        dlog("=== MANUAL SCAN ===")
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local count = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                count += 1
                local part = obj.Parent
                local dist = hrp and part and part:IsA("BasePart")
                    and math.floor((part.Position - hrp.Position).Magnitude) or "?"
                dlog("["..count.."] "
                    ..(obj.ActionText or "?")
                    .." | dist:"..tostring(dist)
                    .." | "..obj:GetFullName())
            end
        end
        local wp = findOrangeWaypoint()
        dlog("Orange waypoint: " .. (wp and wp:GetFullName() or "TIDAK ADA"))
        dlog("Job next: " .. getJobNextText())
        dlog("Customer: " .. getCustomerOrderText())
        dlog("=== DONE (" .. count .. " prompts) ===")
        WindUI:Notify({ Title="Debug", Content=count.." prompts. Cek console.", Duration=3 })
    end,
})

dbgSection:Button({
    Title="Test Teleport Start NPC",
    Callback=function()
        task.spawn(function() teleportPlayer(CF_START_NPC) end)
    end,
})

dbgSection:Button({
    Title="Test Teleport Cup Rack",
    Callback=function()
        task.spawn(function() teleportPlayer(CF_CUP_RACK) end)
    end,
})

task.spawn(function()
    while true do
        task.wait(1)
        if not debugEnabled then continue end
        pcall(function()
            local lines = {}
            for i = 1, math.min(10, #debugLog) do table.insert(lines, debugLog[i]) end
            logLabel:SetDesc(table.concat(lines, "\n"))
        end)
    end
end)

-- ── Settings Tab ──────────────────────────────────────────────
local CONFIG_DIR = "/config/"
local CONFIG_EXT = ".json"
local ConfigManager = { Flags={}, AllConfigs={} }

function ConfigManager:Refresh()
    self.AllConfigs={}
    if not isfolder(CONFIG_DIR) then return end
    for _, entry in ipairs(listfiles(CONFIG_DIR)) do
        local f=entry:match("([^/\\]+)$")
        if f then
            local stem=f:match("^(.+)"..CONFIG_EXT.."$")
            if stem then table.insert(self.AllConfigs,stem) end
        end
    end
end

function ConfigManager:Save(name)
    if not name or name=="" then
        WindUI:Notify({Title="Config",Content="Masukkan nama!",Duration=3}); return
    end
    if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
    writefile(CONFIG_DIR..name..CONFIG_EXT, HttpService:JSONEncode(self.Flags))
    WindUI:Notify({Title="Config",Content="'"..name.."' disimpan!",Duration=3})
    self:Refresh()
end

function ConfigManager:Load(name)
    if not name or name=="" then
        WindUI:Notify({Title="Config",Content="Pilih config!",Duration=3}); return
    end
    local path=CONFIG_DIR..name..CONFIG_EXT
    if not isfile(path) then
        WindUI:Notify({Title="Config",Content="Tidak ditemukan!",Duration=3}); return
    end
    local ok,data=pcall(HttpService.JSONDecode,HttpService,readfile(path))
    if ok then
        for k,v in pairs(data) do self.Flags[k]=v end
        WindUI:Notify({Title="Config",Content="'"..name.."' dimuat!",Duration=3})
    end
end

function ConfigManager:Delete(name)
    if not name or name=="" then
        WindUI:Notify({Title="Config",Content="Pilih config!",Duration=3}); return
    end
    local path=CONFIG_DIR..name..CONFIG_EXT
    if isfile(path) then
        delfile(path)
        WindUI:Notify({Title="Config",Content="'"..name.."' dihapus!",Duration=3})
        self:Refresh()
    end
end

local cfgSec  = settingsTab:Section({ Title="Configuration",       Opened=true })
local loadSec = settingsTab:Section({ Title="Load / Delete Config", Opened=true })

cfgSec:Input({
    Title="Config Name", Placeholder="Nama config...", Flag="ConfigNameInput",
    Callback=function(v) ConfigManager.Flags.ConfigNameInput=v end,
})
cfgSec:Button({
    Title="Save Config", Icon="save",
    Callback=function() ConfigManager:Save(ConfigManager.Flags.ConfigNameInput) end,
})

ConfigManager:Refresh()

local cfgDD = loadSec:Dropdown({
    Title="Select Config", Values=ConfigManager.AllConfigs,
    Multi=false, Flag="SelectedConfig",
    Callback=function(v) ConfigManager.Flags.SelectedConfig=v end,
})
loadSec:Button({
    Title="Load Config", Icon="arrow-right",
    Callback=function() ConfigManager:Load(ConfigManager.Flags.SelectedConfig) end,
})
loadSec:Button({
    Title="Delete Config",
    Callback=function()
        ConfigManager:Delete(ConfigManager.Flags.SelectedConfig)
        cfgDD:Refresh(ConfigManager.AllConfigs)
    end,
})

-- ── Theme Tab ─────────────────────────────────────────────────
themeTab:Section({Title="Select Theme",Opened=true}):Dropdown({
    Title="Choose Theme",
    Values={"Dark","Light","Midnight","Emerald","Crimson","Indigo","Amber","Violet","Rose","Sky","Rainbow","Monokai Pro"},
    Default="Dark", Flag="Theme",
    Callback=function(v) Window:SetTheme(v) end,
})

-- ── Info Tab ──────────────────────────────────────────────────
local iSec = infoTab:Section({Title="Script Hub",Opened=true})
iSec:Paragraph({Title="Hub",     Desc="DX-SR Hub"            })
iSec:Paragraph({Title="Script",  Desc="Autofarm Barista"     })
iSec:Paragraph({Title="Version", Desc="v0.0.0.4"             })
iSec:Paragraph({Title="Author",  Desc="DX-SR"                })
iSec:Paragraph({Title="Game",    Desc="Car Driving Indonesia" })

-- ── Open Button ───────────────────────────────────────────────
Window:EditOpenButton({
    Title="DX-SR Hub", Icon="coffee",
    CornerRadius=UDim.new(0,16), StrokeThickness=2,
    Color=ColorSequence.new(Color3.fromHex("FF0F7B"),Color3.fromHex("F89B29")),
    OnlyMobile=false, Enabled=true,
})

WindUI:Notify({
    Title="DX-SR Hub", Content="v0.0.0.4 loaded! V = toggle UI.",
    Duration=5, Icon="coffee",
})