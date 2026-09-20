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

Window:Tag({ Title="v0.0.0.3",  Icon="github",      Color=Color3.fromHex("#30ff6a"), Radius=13 })
Window:Tag({ Title="DX-SR Hub", Icon="text-cursor", Color=Color3.fromHex("#1E3A8A"), Radius=13 })

WindUI:Popup({
    Title   = "DX-SR Hub",
    Icon    = "coffee",
    Content = "Barista Autofarm v0.0.0.3",
    Buttons = {{ Title="Continue", Icon="arrow-right", Callback=function() end, Variant="Primary" }},
})

-- ── Tabs ──────────────────────────────────────────────────────
local FarmingSection = Window:Section({ Title="Farming", Icon="coffee", Opened=true })
local mainTab     = FarmingSection:Tab({ Title="Barista",     Icon="coffee"   })
local debugTab    = FarmingSection:Tab({ Title="Debug",       Icon="terminal" })
local settingsTab = FarmingSection:Tab({ Title="Settings",    Icon="settings" })
local themeTab    = FarmingSection:Tab({ Title="Theme",       Icon="palette"  })
local infoTab     = FarmingSection:Tab({ Title="Information", Icon="info"     })

-- ── State ─────────────────────────────────────────────────────
local baristaEnabled = false
local baristaWorking = false
local baristaLastAct = os.clock()
local baristaStuck   = 0
local baristaJobs    = 0

-- Posisi area barista CDID — sesuaikan kalau beda
local START_POS    = Vector3.new(-4989.8, 5.5, -715)
local BREW_POS     = Vector3.new(-5000.2, 5.6, -792)
local REGISTER_POS = Vector3.new(-4997.1, 5.6, -755)
local SUPPLY_POS   = Vector3.new(-5116.8, 5.8, -670.9)
local TWEEN_MAX    = 60

-- ── Debug log ─────────────────────────────────────────────────
local debugLog     = {}
local debugEnabled = false

local function dlog(msg)
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
    print(line)
    table.insert(debugLog, 1, line)
    if #debugLog > 40 then table.remove(debugLog) end
end

-- ── Helpers ───────────────────────────────────────────────────
local function getChar() return LocalPlayer.Character end
local function getHRP()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end

-- Cari ProximityPrompt enabled terdekat dari posisi
local function findNearestPrompt(pos, radius, keywords)
    local best, bestDist = nil, radius or 15
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local dist = (part.Position - pos).Magnitude
                if dist < bestDist then
                    -- filter keyword kalau ada
                    if keywords then
                        local at = (obj.ActionText or ""):lower()
                        for _, kw in ipairs(keywords) do
                            if at:find(kw:lower()) then
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

-- Fire prompt terdekat dari posisi
local function fireNearestPrompt(pos, radius, keywords)
    local prompt = findNearestPrompt(pos, radius, keywords)
    if prompt then
        dlog("Fire prompt: " .. prompt:GetFullName() .. " | " .. (prompt.ActionText or ""))
        pcall(function()
            prompt.HoldDuration = 0
            fireproximityprompt(prompt)
        end)
        return true
    end
    dlog("Tidak ada prompt dalam radius " .. tostring(radius) .. " di " .. tostring(pos))
    return false
end

-- Seat teleport (bypass anti-teleport)
local function seatTeleport(targetCF)
    local hrp  = getHRP()
    local hum  = getHum()
    local char = getChar()
    local anim = char and char:FindFirstChild("Animate")
    if not hrp or not hum then return end
    if anim then anim.Disabled = true end

    local seat = Instance.new("Seat")
    seat.Size=Vector3.new(2,.2,2); seat.Transparency=1
    seat.CanCollide=false; seat.Anchored=true
    seat.CFrame=hrp.CFrame; seat.Parent=workspace

    hum.Sit=true; seat:Sit(hum)

    local bv=Instance.new("BodyVelocity")
    bv.MaxForce=Vector3.new(9e9,9e9,9e9)
    bv.Velocity=Vector3.zero; bv.Parent=hrp

    task.wait(0.5)
    seat.Anchored=false
    local tgt=targetCF*CFrame.new(0,.01,0)
    local mid=hrp.CFrame:Lerp(tgt,.5)
    seat.CFrame=mid; hrp.CFrame=mid
    task.wait(0.1)
    seat.CFrame=tgt; hrp.CFrame=tgt
    seat.Anchored=true
    task.wait(1.6)
    bv:Destroy()
    hum.Sit=false
    if anim then anim.Disabled=false end
    task.wait(0.3)
    seat:Destroy()
    hrp.AssemblyLinearVelocity=Vector3.zero
    workspace.CurrentCamera.CameraSubject=hum
end

-- Tween teleport halus (jarak dekat dalam area barista)
local function baristaTeleport(targetCF)
    local hrp  = getHRP()
    local hum  = getHum()
    local char = getChar()
    if not hrp or not hum then return end

    local tgtPos   = targetCF.Position
    local curPos   = hrp.Position
    local distFlat = (Vector3.new(tgtPos.X,0,tgtPos.Z)-Vector3.new(curPos.X,0,curPos.Z)).Magnitude
    local dist3D   = (tgtPos-curPos).Magnitude

    if dist3D < 3.5 or distFlat < 2.5 then return end
    if hum.Sit then hum.Sit=false; task.wait(0.02) end

    hum.AutoRotate=false
    hrp.AssemblyLinearVelocity=Vector3.zero
    hrp.AssemblyAngularVelocity=Vector3.zero

    local y=tgtPos.Y
    local startPos=Vector3.new(hrp.Position.X,y,hrp.Position.Z)
    local endPos=Vector3.new(tgtPos.X,y,tgtPos.Z)

    local seat=Instance.new("Seat")
    seat.Name="barista_tp"; seat.Size=Vector3.new(1,1,1)
    seat.Transparency=1; seat.CanCollide=false
    seat.CFrame=CFrame.new(startPos)*targetCF.Rotation
    seat.Parent=workspace

    local weld=Instance.new("WeldConstraint")
    weld.Part0=seat; weld.Part1=hrp; weld.Parent=seat

    local bv=Instance.new("BodyVelocity")
    bv.MaxForce=Vector3.new(1e9,1e9,1e9)
    bv.Velocity=Vector3.zero; bv.Parent=seat

    local origCollide={}
    local seatConn=RunService.Stepped:Connect(function()
        if hrp then
            hrp.AssemblyLinearVelocity=Vector3.zero
            hrp.AssemblyAngularVelocity=Vector3.zero
        end
        if seat and seat.Parent then
            seat.AssemblyLinearVelocity=Vector3.zero
            seat.AssemblyAngularVelocity=Vector3.zero
        end
        if hum.SeatPart~=seat then hum.Sit=true; seat:Sit(hum) end
    end)
    local colConn=RunService.Stepped:Connect(function()
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide=false; origCollide[p]=true
                end
            end
        end
    end)

    local duration=math.clamp(distFlat/TWEEN_MAX,.02,1)
    local t0=os.clock()
    while baristaEnabled and hrp and char and char.Parent
        and (os.clock()-t0)<duration do
        local alpha=math.min((os.clock()-t0)/duration,1)
        local pos=startPos:Lerp(endPos,alpha)
        local cf=CFrame.new(pos)*targetCF.Rotation
        seat.CFrame=cf; hrp.CFrame=cf
        task.wait()
    end

    seatConn:Disconnect(); colConn:Disconnect()
    for part in pairs(origCollide) do
        if typeof(part)=="Instance" and part:IsA("BasePart") and part.Parent then
            part.CanCollide=true
        end
    end
    bv:Destroy()
    hrp.AssemblyLinearVelocity=Vector3.zero
    hrp.AssemblyAngularVelocity=Vector3.zero
    hum.Sit=false; seat:Destroy()
    hum.AutoRotate=true
    hum:ChangeState(Enum.HumanoidStateType.Running)
    hrp.CFrame=CFrame.new(endPos)*targetCF.Rotation
    hrp.AssemblyLinearVelocity=Vector3.zero
    hrp.AssemblyAngularVelocity=Vector3.zero
end

-- Handler start/end shift — cari prompt di sekitar startPos
local function handleShiftPrompt()
    local hrp = getHRP()
    if not hrp then return false end

    -- Cari prompt bertulisan shift dalam radius 8 dari START_POS
    local prompt = findNearestPrompt(START_POS, 8, {"shift","start","barista","begin","mulai"})
    if not prompt then
        -- Coba radius lebih lebar tanpa filter keyword
        prompt = findNearestPrompt(START_POS, 12)
    end
    if not prompt then
        dlog("handleShiftPrompt: tidak ada prompt di sekitar START_POS")
        return false
    end

    dlog("Shift prompt: " .. (prompt.ActionText or "?") .. " | " .. prompt:GetFullName())
    prompt.HoldDuration = 0

    -- End Shift dulu kalau ada
    if prompt.ActionText == "End Shift" then
        local t0, lastClick = os.clock(), 0
        while baristaEnabled and (os.clock()-t0)<6 do
            if not prompt.Parent then break end
            if prompt.ActionText == "Start Shift" then break end
            if (os.clock()-lastClick)>1.2 then
                lastClick=os.clock()
                pcall(function() prompt.HoldDuration=0; fireproximityprompt(prompt) end)
            end
            task.wait(0.2)
        end
        task.wait(0.3)
        if not prompt.Parent then return false end
    end

    -- Start Shift
    if prompt.ActionText == "Start Shift" or not prompt.ActionText:find("End") then
        local t0, lastClick = os.clock(), 0
        while baristaEnabled and (os.clock()-t0)<6 do
            if not prompt.Parent then break end
            if prompt.ActionText == "End Shift" then break end
            if (os.clock()-lastClick)>1.2 then
                lastClick=os.clock()
                pcall(function() prompt.HoldDuration=0; fireproximityprompt(prompt) end)
            end
            task.wait(0.2)
        end
        task.wait(0.3)
    end

    if not prompt.Parent then return false end
    return prompt.ActionText == "End Shift"
end

-- ── Main Barista Loop — pure proximity, no BaristaJob path ───
task.spawn(function()
    while task.wait(0.1) do
        if not baristaEnabled then continue end

        local char = getChar()
        local hrp  = getHRP()
        local hum  = getHum()
        if not char or not hrp or not hum or hum.Health<=0 then
            task.wait(0.5); continue
        end

        local hrpPos   = hrp.Position
        local distToDrop  = (Vector3.new(-5000,0,-760)-Vector3.new(hrpPos.X,0,hrpPos.Z)).Magnitude
        local distToStart = (Vector3.new(START_POS.X,0,START_POS.Z)-Vector3.new(hrpPos.X,0,hrpPos.Z)).Magnitude

        -- Kalau terlalu jauh dari area barista → seatTeleport
        if distToDrop > 80 then
            dlog("Terlalu jauh (" .. math.floor(distToDrop) .. ") — seatTeleport ke START_POS")
            seatTeleport(CFrame.new(START_POS))
            task.wait(0.5)
            continue
        end

        -- Belum working → ke start, fire shift prompt
        if not baristaWorking then
            if distToStart > 6 then
                dlog("Ke START_POS untuk shift")
                baristaTeleport(CFrame.new(START_POS))
                task.wait(0.3)
            end
            dlog("handleShiftPrompt...")
            local ok = handleShiftPrompt()
            dlog("Shift result: " .. tostring(ok))
            if not ok then task.wait(0.5); continue end
            baristaWorking = true
            baristaLastAct = os.clock()
            baristaTeleport(CFrame.new(BREW_POS))
            task.wait(0.08)
            continue
        end

        -- Supply — cari prompt di sekitar SUPPLY_POS
        local supplyPrompt = findNearestPrompt(SUPPLY_POS, 10,
            {"supply","restock","refill","stock","bahan"})
        if supplyPrompt and supplyPrompt.Enabled then
            dlog("SUPPLY — teleport & fire")
            baristaLastAct = os.clock()
            seatTeleport(CFrame.new(SUPPLY_POS))
            task.wait(0.4)
            pcall(function()
                supplyPrompt.HoldDuration=0
                fireproximityprompt(supplyPrompt)
            end)
            task.wait(0.6)
            seatTeleport(CFrame.new(BREW_POS))
            task.wait(0.4)
            continue
        end

        -- Register — cari prompt di sekitar REGISTER_POS
        local registerPrompt = findNearestPrompt(REGISTER_POS, 10,
            {"serve","register","deliver","antar","selesai","kasir"})
        if registerPrompt and registerPrompt.Enabled then
            dlog("REGISTER — serve order")
            baristaLastAct = os.clock()
            baristaTeleport(CFrame.new(REGISTER_POS))
            task.wait(0.08)
            pcall(function()
                registerPrompt.HoldDuration=0
                fireproximityprompt(registerPrompt)
            end)
            task.wait(0.1)
            baristaJobs += 1
            WindUI:Notify({ Title="Barista", Content="Order #"..baristaJobs.." selesai!", Duration=2, Icon="coffee" })
            baristaTeleport(CFrame.new(BREW_POS))
            task.wait(0.08)
            continue
        end

        -- Machine — cari prompt di sekitar BREW_POS
        local machinePrompt = findNearestPrompt(BREW_POS, 10,
            {"brew","machine","mesin","kopi","make","buat","coffee"})
        if machinePrompt and machinePrompt.Enabled then
            dlog("MACHINE — brew")
            baristaLastAct = os.clock()
            local distBrew=(BREW_POS-hrpPos).Magnitude
            if distBrew>3 then baristaTeleport(CFrame.new(BREW_POS)); task.wait(0.08) end
            pcall(function()
                machinePrompt.HoldDuration=0
                fireproximityprompt(machinePrompt)
            end)
            local t0=os.clock()
            while baristaEnabled and (os.clock()-t0)<6 do
                baristaLastAct=os.clock()
                local rp=findNearestPrompt(REGISTER_POS,10,{"serve","register","deliver","antar","selesai","kasir"})
                if rp and rp.Enabled then break end
                local bGui=PlayerGui:FindFirstChild("BaristaGUI")
                local bMini=bGui and bGui:FindFirstChild("MinigameFrame")
                if not(bMini and bMini.Visible) and (os.clock()-t0)>1 then break end
                task.wait(0.08)
            end
            continue
        end

        -- Idle — drift ke brew
        if (Vector3.new(BREW_POS.X,0,BREW_POS.Z)-Vector3.new(hrpPos.X,0,hrpPos.Z)).Magnitude > 3.5 then
            baristaTeleport(CFrame.new(BREW_POS))
        end

        -- Stuck 18 detik
        if (os.clock()-baristaLastAct)>18 then
            baristaLastAct=os.clock()
            baristaStuck+=1
            dlog("STUCK #"..baristaStuck.." — refresh shift")
            WindUI:Notify({ Title="Barista", Content="Stuck #"..baristaStuck.." — refresh", Duration=3, Icon="coffee" })
            baristaTeleport(CFrame.new(START_POS))
            task.wait(0.3)
            baristaWorking=false
            local ok=handleShiftPrompt()
            if not ok then task.wait(0.5); continue end
            baristaWorking=true
            baristaLastAct=os.clock()
            baristaTeleport(CFrame.new(BREW_POS))
            task.wait(0.08)
        end
    end
end)

-- ── Scan awal ─────────────────────────────────────────────────
task.spawn(function()
    task.wait(3)
    dlog("=== SCAN AWAL ===")
    dlog("Team: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "NIL"))
    dlog("BaristaJob: " .. (workspace:FindFirstChild("BaristaJob") and "ADA" or "TIDAK ADA"))

    -- Dump semua ProximityPrompt di workspace
    local count=0
    for _, c in ipairs(workspace:GetDescendants()) do
        if c:IsA("ProximityPrompt") then
            count+=1
            dlog("PROMPT: " .. c:GetFullName() .. " | " .. (c.ActionText or "") .. " | enabled:" .. tostring(c.Enabled))
        end
    end
    dlog("Total ProximityPrompt: " .. count)
    dlog("=== SCAN SELESAI ===")
end)

-- ── Main Tab UI ───────────────────────────────────────────────
local farmSection = mainTab:Section({ Title="Autofarm Barista", Opened=true })
local statusLabel = farmSection:Paragraph({ Title="Status",      Desc="Idle" })
local jobsLabel   = farmSection:Paragraph({ Title="Jobs Done",   Desc="0"    })
local stuckLabel  = farmSection:Paragraph({ Title="Stuck Count", Desc="0"    })

farmSection:Toggle({
    Title    = "Barista Autofarm",
    Desc     = "Auto barista CDID",
    Default  = false,
    Flag     = "AutofarmBarista",
    Callback = function(state)
        baristaEnabled = state
        baristaWorking = false
        baristaLastAct = os.clock()
        dlog("Toggle: " .. tostring(state))
        if state then
            WindUI:Notify({ Title="Barista Autofarm", Content="AKTIF! Teleport ke area...", Duration=3, Icon="coffee" })
            task.spawn(function()
                task.wait(0.3)
                dlog("seatTeleport START_POS")
                seatTeleport(CFrame.new(START_POS))
                dlog("Arrived at START_POS")
            end)
        else
            WindUI:Notify({ Title="Barista Autofarm", Content="Stopped.", Duration=2 })
        end
    end,
})

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            statusLabel:SetDesc(baristaEnabled and "Running" or "Idle")
            jobsLabel:SetDesc(tostring(baristaJobs))
            stuckLabel:SetDesc(tostring(baristaStuck))
        end)
    end
end)

-- ── Debug Tab ─────────────────────────────────────────────────
local dbgSection = debugTab:Section({ Title="Live Debug Log", Opened=true })
local logLabel   = dbgSection:Paragraph({ Title="Log", Desc="Waiting..." })

dbgSection:Toggle({
    Title="Live Log", Desc="Update log di UI", Default=false, Flag="DebugLiveLog",
    Callback=function(v) debugEnabled=v end,
})

dbgSection:Button({
    Title="Scan Prompts Sekarang", Desc="Dump semua ProximityPrompt ke console",
    Callback=function()
        dlog("=== MANUAL SCAN ===")
        dlog("Team: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "NIL"))
        local hrp=getHRP()
        dlog("HRP: " .. tostring(hrp and hrp.Position or "NIL"))
        local count=0
        for _, c in ipairs(workspace:GetDescendants()) do
            if c:IsA("ProximityPrompt") then
                count+=1
                local part=c.Parent
                local dist=hrp and part and part:IsA("BasePart") and math.floor((part.Position-hrp.Position).Magnitude) or "?"
                dlog("["..count.."] " .. (c.ActionText or "?") .. " | dist:"..tostring(dist) .. " | " .. c:GetFullName())
            end
        end
        dlog("Total: " .. count)
        dlog("=== DONE ===")
        WindUI:Notify({ Title="Debug", Content=count.." prompts ditemukan", Duration=3 })
    end,
})

dbgSection:Button({
    Title="Test Teleport START_POS", Desc="Manual test seatTeleport",
    Callback=function()
        task.spawn(function()
            dlog("Manual test seatTeleport")
            seatTeleport(CFrame.new(START_POS))
            dlog("Done")
        end)
    end,
})

task.spawn(function()
    while true do
        task.wait(1)
        if not debugEnabled then continue end
        pcall(function()
            local lines={}
            for i=1,math.min(10,#debugLog) do table.insert(lines,debugLog[i]) end
            logLabel:SetDesc(table.concat(lines,"\n"))
        end)
    end
end)

-- ── Settings Tab ──────────────────────────────────────────────
local CONFIG_DIR="/config/"
local CONFIG_EXT=".json"
local ConfigManager={Flags={},AllConfigs={}}

function ConfigManager:Refresh()
    self.AllConfigs={}
    if not isfolder(CONFIG_DIR) then return end
    for _,entry in ipairs(listfiles(CONFIG_DIR)) do
        local f=entry:match("([^/\\]+)$")
        if f then
            local stem=f:match("^(.+)"..CONFIG_EXT.."$")
            if stem then table.insert(self.AllConfigs,stem) end
        end
    end
end

function ConfigManager:Save(name)
    if not name or name=="" then WindUI:Notify({Title="Config",Content="Masukkan nama!",Duration=3}); return end
    if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
    writefile(CONFIG_DIR..name..CONFIG_EXT, HttpService:JSONEncode(self.Flags))
    WindUI:Notify({Title="Config",Content="'"..name.."' disimpan!",Duration=3})
    self:Refresh()
end

function ConfigManager:Load(name)
    if not name or name=="" then WindUI:Notify({Title="Config",Content="Pilih config!",Duration=3}); return end
    local path=CONFIG_DIR..name..CONFIG_EXT
    if not isfile(path) then WindUI:Notify({Title="Config",Content="Tidak ditemukan!",Duration=3}); return end
    local ok,data=pcall(HttpService.JSONDecode,HttpService,readfile(path))
    if ok then
        for k,v in pairs(data) do self.Flags[k]=v end
        WindUI:Notify({Title="Config",Content="'"..name.."' dimuat!",Duration=3})
    end
end

function ConfigManager:Delete(name)
    if not name or name=="" then WindUI:Notify({Title="Config",Content="Pilih config!",Duration=3}); return end
    local path=CONFIG_DIR..name..CONFIG_EXT
    if isfile(path) then
        delfile(path)
        WindUI:Notify({Title="Config",Content="'"..name.."' dihapus!",Duration=3})
        self:Refresh()
    end
end

local cfgSection  = settingsTab:Section({ Title="Configuration",       Opened=true })
local loadSection = settingsTab:Section({ Title="Load / Delete Config", Opened=true })

cfgSection:Input({
    Title="Config Name", Placeholder="Nama config...", Flag="ConfigNameInput",
    Callback=function(v) ConfigManager.Flags.ConfigNameInput=v end,
})
cfgSection:Button({
    Title="Save Config", Icon="save",
    Callback=function() ConfigManager:Save(ConfigManager.Flags.ConfigNameInput) end,
})

ConfigManager:Refresh()

local configDropdown=loadSection:Dropdown({
    Title="Select Config", Values=ConfigManager.AllConfigs, Multi=false, Flag="SelectedConfigDropdown",
    Callback=function(v) ConfigManager.Flags.SelectedConfigDropdown=v end,
})
loadSection:Button({
    Title="Load Config", Icon="arrow-right",
    Callback=function() ConfigManager:Load(ConfigManager.Flags.SelectedConfigDropdown) end,
})
loadSection:Button({
    Title="Delete Config",
    Callback=function()
        ConfigManager:Delete(ConfigManager.Flags.SelectedConfigDropdown)
        configDropdown:Refresh(ConfigManager.AllConfigs)
    end,
})

-- ── Theme Tab ─────────────────────────────────────────────────
themeTab:Section({Title="Select Theme",Opened=true}):Dropdown({
    Title="Choose Theme",
    Values={"Dark","Light","Midnight","Emerald","Crimson","Indigo","Amber","Violet","Rose","Sky","Rainbow","Monokai Pro"},
    Default="Dark", Flag="SelectedTheme",
    Callback=function(val) Window:SetTheme(val) end,
})

-- ── Info Tab ──────────────────────────────────────────────────
local infoSec=infoTab:Section({Title="Script Hub",Opened=true})
infoSec:Paragraph({Title="Hub",     Desc="DX-SR Hub"            })
infoSec:Paragraph({Title="Script",  Desc="Autofarm Barista"     })
infoSec:Paragraph({Title="Version", Desc="v0.0.0.3"             })
infoSec:Paragraph({Title="Author",  Desc="DX-SR"                })
infoSec:Paragraph({Title="Game",    Desc="Car Driving Indonesia" })

-- ── Open Button ───────────────────────────────────────────────
Window:EditOpenButton({
    Title="DX-SR Hub", Icon="coffee",
    CornerRadius=UDim.new(0,16), StrokeThickness=2,
    Color=ColorSequence.new(Color3.fromHex("FF0F7B"),Color3.fromHex("F89B29")),
    OnlyMobile=false, Enabled=true,
})

WindUI:Notify({
    Title="DX-SR Hub", Content="v0.0.0.3 loaded! V = toggle UI.",
    Duration=5, Icon="coffee",
})