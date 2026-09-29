-- DX-SR Hub | Barista Autofarm v0.0.0.6 | WindUI
-- Startup flow:
-- Auto ON -> exact CFrame teleport to NPC_BARISTA_MANAGER
-- -> interact -> skip dialog -> get Barista job

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local VIM                = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local T0          = os.clock()

-- =========================================================
-- DEBUG
-- =========================================================

local Debug = {
    Enabled = true,
    Buffer = {},
    Max = 300
}

local function dbg(tag, ...)
    local parts = table.pack(...)

    for i = 1, parts.n do
        parts[i] = tostring(parts[i])
    end

    local line = string.format(
        "[%7.2f][%s] %s",
        os.clock() - T0,
        tag,
        table.concat(parts, " ", 1, parts.n)
    )

    table.insert(Debug.Buffer, line)

    if #Debug.Buffer > Debug.Max then
        table.remove(Debug.Buffer, 1)
    end

    if Debug.Enabled then
        print(line)
    end
end

-- =========================================================
-- WINDUI
-- =========================================================

local okUI, WindUI = pcall(function()
    return loadstring(
        game:HttpGet(
            "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
        )
    )()
end)

if not okUI or type(WindUI) ~= "table" then
    warn("[Barista] WindUI failed to load: " .. tostring(WindUI))
    return
end

dbg("BOOT", "WindUI loaded")

local function notify(title, content, duration, icon)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3,
            Icon = icon
        })
    end)
end

-- =========================================================
-- CONFIG
-- =========================================================

local FOLDER   = "DXSR_Barista"
local EXT      = ".json"
local AUTOLOAD = FOLDER .. "/autoload.txt"

local hasFS =
    type(writefile) == "function"
    and type(readfile) == "function"
    and type(isfile) == "function"
    and type(makefolder) == "function"
    and type(isfolder) == "function"

if hasFS and not isfolder(FOLDER) then
    pcall(makefolder, FOLDER)
end

local Flags = {
    AutofarmBarista = false,
    OnlyMobile = false,
    SelectedTheme = "Dark"
}

local ConfigManager = {}

function ConfigManager.List()
    local names = {}

    if hasFS and type(listfiles) == "function" then
        local ok, files = pcall(listfiles, FOLDER)

        if ok then
            for _, path in ipairs(files) do
                local name = path:match("([^/\\]+)%.json$")

                if name then
                    table.insert(names, name)
                end
            end
        end
    end

    table.sort(names)

    return names
end

function ConfigManager.Save(name)
    if not hasFS then
        notify("Config", "Executor has no file API.")
        return false
    end

    if not name or name == "" then
        notify("Config", "Enter or select a config name first!")
        return false
    end

    local ok, err = pcall(
        writefile,
        FOLDER .. "/" .. name .. EXT,
        HttpService:JSONEncode(Flags)
    )

    if not ok then
        dbg("CONFIG", "save failed:", err)
        notify("Config", "Save failed: " .. tostring(err))
        return false
    end

    dbg("CONFIG", "saved", name)
    notify("Config", "'" .. name .. "' saved!")

    return true
end

function ConfigManager.Load(name)
    if not hasFS then
        return false
    end

    if not name or name == "" then
        notify("Config", "Select a config first!")
        return false
    end

    local path = FOLDER .. "/" .. name .. EXT

    if not isfile(path) then
        notify("Config", "'" .. name .. "' not found!")
        return false
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not ok or type(decoded) ~= "table" then
        dbg("CONFIG", "load failed:", decoded)
        notify("Config", "Failed to load: " .. name)
        return false
    end

    for k, v in pairs(decoded) do
        Flags[k] = v
    end

    dbg("CONFIG", "loaded", name)
    notify("Config", "'" .. name .. "' loaded!")

    return true
end

function ConfigManager.Delete(name)
    if not hasFS or not name or name == "" then
        notify("Config", "Select a config first!")
        return false
    end

    local path = FOLDER .. "/" .. name .. EXT

    if isfile(path) and type(delfile) == "function" then
        pcall(delfile, path)

        dbg("CONFIG", "deleted", name)
        notify("Config", "'" .. name .. "' deleted!")

        return true
    end

    return false
end

function ConfigManager.SetAutoLoad(name, state)
    if not hasFS then
        return
    end

    if state and name and name ~= "" then
        pcall(writefile, AUTOLOAD, name)
        notify("Config", "Auto load set to '" .. name .. "'")
    else
        if isfile(AUTOLOAD) and type(delfile) == "function" then
            pcall(delfile, AUTOLOAD)
        end

        notify("Config", "Auto load disabled")
    end
end

-- =========================================================
-- STATS
-- =========================================================

local Stats = {
    Orders = 0,
    Salary = 0,
    XP = 0
}

local function fmtSalary(n)
    local s = tostring(math.floor(tonumber(n) or 0))

    local out = s:reverse()
        :gsub("(%d%d%d)", "%1.")
        :reverse()

    out = out:gsub("^%.", "")

    return "Rp " .. out
end

local function fmtStats()
    return "Orders: "
        .. Stats.Orders
        .. " | Salary: "
        .. fmtSalary(Stats.Salary)
end

-- =========================================================
-- AUTOFARM STATE
-- =========================================================

local AutofarmBarista = {
    Running = false,
    Thread = nil,
    CurrentStep = "Idle"
}

local BaristaRemote
local NpcDialogRemote
local JobRemote

local lastCupState
local lastOrderData
local baristaConn

-- =========================================================
-- EXACT BARISTA MANAGER CFRAME
-- =========================================================

local BARISTA_MANAGER_CFRAME = CFrame.new(
    -13.505,
    23.252,
    8451.661,
    0.891,
    -0.000,
    -0.454,
    0.000,
    1.000,
    -0.000,
    0.454,
    0.000,
    0.891
)

dbg(
    "CONFIG",
    "Manager CFrame:",
    tostring(BARISTA_MANAGER_CFRAME)
)

-- =========================================================
-- SIGNAL HELPER
-- =========================================================

local function safeFiresignal(signal, ...)
    if type(firesignal) ~= "function" then
        dbg("SIGNAL", "firesignal unsupported")
        return
    end

    local ok, err = pcall(firesignal, signal, ...)

    if not ok then
        dbg("SIGNAL", "firesignal failed:", err)
    end
end

-- =========================================================
-- WORKSPACE REFERENCES
-- =========================================================

local function getWorkspaceRefs()
    local ws = {
        Barista =
            workspace:FindFirstChild("Barista"),

        BaristaCustomers =
            workspace:FindFirstChild(
                "BaristaCustomers"
            ),

        NEW_JOB =
            workspace:FindFirstChild("NEW_JOB")
    }

    ws.Stations =
        ws.Barista
        and ws.Barista:FindFirstChild("Stations")

    ws.NpcManager =
        ws.Barista
        and ws.Barista:FindFirstChild(
            "NPC_BARISTA_MANAGER"
        )

    local cafe =
        ws.NEW_JOB
        and ws.NEW_JOB:FindFirstChild("Cafe")

    local kanji =
        cafe
        and cafe:FindFirstChild("Cafe_Kanji_Jawa")

    local tel =
        kanji
        and kanji:FindFirstChild("Telphone")

    ws.Telephone =
        tel
        and tel:FindFirstChild("Telephone")

    dbg(
        "WS",
        "Barista", ws.Barista ~= nil,
        "Customers", ws.BaristaCustomers ~= nil,
        "Stations", ws.Stations ~= nil,
        "Manager", ws.NpcManager ~= nil,
        "Phone", ws.Telephone ~= nil
    )

    return ws
end

-- =========================================================
-- CHARACTER
-- =========================================================

local function getHRP()
    local char = LocalPlayer.Character

    return char
        and char:FindFirstChild("HumanoidRootPart")
end

-- =========================================================
-- MOVEMENT
-- =========================================================

local function teleportTo(target)
    local hrp = getHRP()

    if not hrp then
        dbg(
            "TP",
            "HumanoidRootPart not found"
        )

        return false
    end

    local targetCFrame

    if typeof(target) == "CFrame" then

        targetCFrame = target

    elseif typeof(target) == "Vector3" then

        targetCFrame = CFrame.new(target)

    elseif typeof(target) == "Instance" then

        if target:IsA("BasePart") then
            targetCFrame = target.CFrame
        else
            local part =
                target:FindFirstChildWhichIsA(
                    "BasePart",
                    true
                )

            if part then
                targetCFrame = part.CFrame
            end
        end
    end

    if not targetCFrame then
        dbg(
            "TP",
            "Invalid teleport target"
        )

        return false
    end

    hrp.AssemblyLinearVelocity =
        Vector3.zero

    hrp.AssemblyAngularVelocity =
        Vector3.zero

    dbg(
        "TP",
        "Teleporting to",
        tostring(targetCFrame.Position)
    )

    dbg(
        "TP",
        "Rotation:",
        tostring(targetCFrame - targetCFrame.Position)
    )

    hrp.CFrame =
        targetCFrame

    task.wait(0.15)

    local distance =
        (
            hrp.Position
            - targetCFrame.Position
        ).Magnitude

    dbg(
        "TP",
        "Distance after teleport:",
        string.format(
            "%.2f",
            distance
        )
    )

    return distance < 10
end

local function tweenTo(target, duration)
    local hrp = getHRP()

    if not hrp or not target then
        return false
    end

    local pos

    if typeof(target) == "Vector3" then

        pos = target

    elseif target:IsA("BasePart") then

        pos = target.Position

    else

        local part =
            target:FindFirstChildWhichIsA(
                "BasePart",
                true
            )

        pos =
            part
            and part.Position
    end

    if not pos then
        dbg(
            "TWEEN",
            "no position for target"
        )

        return false
    end

    local tween =
        TweenService:Create(
            hrp,

            TweenInfo.new(
                duration or 0.8,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),

            {
                CFrame =
                    CFrame.new(
                        pos
                        + Vector3.new(
                            0,
                            3,
                            0
                        )
                    )
            }
        )

    tween:Play()
    tween.Completed:Wait()

    task.wait(0.3)

    return true
end

-- =========================================================
-- PROMPT
-- =========================================================

local function firePrompt(prompt)
    if not prompt then
        dbg(
            "PROMPT",
            "nil prompt"
        )

        return false
    end

    if type(fireproximityprompt) ~= "function" then
        dbg(
            "PROMPT",
            "fireproximityprompt unsupported"
        )

        return false
    end

    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 50
    end)

    local ok, err =
        pcall(
            fireproximityprompt,
            prompt
        )

    if not ok then
        dbg(
            "PROMPT",
            "fire failed:",
            err
        )

        return false
    end

    dbg(
        "PROMPT",
        "fired:",
        prompt:GetFullName()
    )

    task.wait(0.3)

    return true
end

-- =========================================================
-- FIND BARISTA MANAGER
-- =========================================================

local function findBaristaManager(ws)
    if ws and ws.NpcManager then
        return ws.NpcManager
    end

    dbg(
        "JOB",
        "Searching for NPC_BARISTA_MANAGER..."
    )

    local barista =
        workspace:FindFirstChild("Barista")

    if barista then
        local npc =
            barista:FindFirstChild(
                "NPC_BARISTA_MANAGER"
            )

        if npc then
            dbg(
                "JOB",
                "Manager found:",
                npc:GetFullName()
            )

            return npc
        end
    end

    -- Fallback recursive search.
    local found =
        workspace:FindFirstChild(
            "NPC_BARISTA_MANAGER",
            true
        )

    if found then
        dbg(
            "JOB",
            "Manager found recursively:",
            found:GetFullName()
        )

        return found
    end

    dbg(
        "JOB",
        "NPC_BARISTA_MANAGER not found"
    )

    return nil
end

-- =========================================================
-- FIND MANAGER PROMPT
-- =========================================================

local function findManagerPrompt(npc)
    if not npc then
        return nil
    end

    local root =
        npc:FindFirstChild(
            "HumanoidRootPart"
        )
        or npc:FindFirstChild(
            "Head"
        )

    if root then
        local namedPrompt =
            root:FindFirstChild(
                "DialogPrompt"
            )

        if namedPrompt then
            return namedPrompt
        end

        local proximityPrompt =
            root:FindFirstChildWhichIsA(
                "ProximityPrompt",
                true
            )

        if proximityPrompt then
            return proximityPrompt
        end
    end

    local namedPrompt =
        npc:FindFirstChild(
            "DialogPrompt",
            true
        )

    if namedPrompt then
        return namedPrompt
    end

    local proximityPrompt =
        npc:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )

    if proximityPrompt then
        return proximityPrompt
    end

    return nil
end

-- =========================================================
-- BARISTA NPC JOB ACQUISITION
-- =========================================================

local function getBaristaJob(ws, jobRemote)

    if not AutofarmBarista.Running then
        return false
    end

    AutofarmBarista.CurrentStep =
        "Going to Barista Manager..."

    dbg(
        "JOB",
        "Starting Barista Manager teleport"
    )

    -- =====================================================
    -- FORCE EXACT TELEPORT
    -- =====================================================

    local success =
        teleportTo(
            BARISTA_MANAGER_CFRAME
        )

    if not success then
        dbg(
            "JOB",
            "Manager teleport verification failed"
        )
    else
        dbg(
            "JOB",
            "Manager teleport successful"
        )
    end

    task.wait(0.8)

    if not AutofarmBarista.Running then
        return false
    end

    -- =====================================================
    -- FIND NPC
    -- =====================================================

    local npc =
        findBaristaManager(ws)

    if not npc then
        dbg(
            "JOB",
            "Manager model unavailable after teleport"
        )

        return false
    end

    dbg(
        "JOB",
        "Manager model:",
        npc:GetFullName()
    )

    -- =====================================================
    -- FIND PROMPT
    -- =====================================================

    local prompt =
        findManagerPrompt(npc)

    if not prompt then

        dbg(
            "JOB",
            "DialogPrompt not found"
        )

        for _, obj in ipairs(
            npc:GetDescendants()
        ) do

            if obj:IsA("ProximityPrompt") then
                dbg(
                    "JOB",
                    "Prompt found:",
                    obj:GetFullName()
                )
            end
        end

        return false
    end

    dbg(
        "JOB",
        "Using prompt:",
        prompt:GetFullName()
    )

    -- =====================================================
    -- INTERACT
    -- =====================================================

    AutofarmBarista.CurrentStep =
        "Interacting with Manager..."

    dbg(
        "JOB",
        "Interacting with Barista Manager"
    )

    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 50
        prompt.HoldDuration = 0
    end)

    local interacted = false

    if type(fireproximityprompt) == "function" then

        local ok, err =
            pcall(
                fireproximityprompt,
                prompt
            )

        interacted = ok

        if not ok then
            dbg(
                "JOB",
                "fireproximityprompt failed:",
                err
            )
        end

    else

        dbg(
            "JOB",
            "fireproximityprompt unavailable"
        )

        pcall(function()
            prompt:InputHoldBegin()

            task.wait(
                math.max(
                    prompt.HoldDuration,
                    0
                ) + 0.1
            )

            prompt:InputHoldEnd()

            interacted = true
        end)
    end

    if not interacted then
        dbg(
            "JOB",
            "NPC interaction failed"
        )

        return false
    end

    dbg(
        "JOB",
        "NPC interaction fired"
    )

    task.wait(0.8)

    -- =====================================================
    -- SKIP NPC DIALOG
    -- =====================================================

    AutofarmBarista.CurrentStep =
        "Skipping Manager dialog..."

    dbg(
        "JOB",
        "Advancing NPC dialog"
    )

    for i = 1, 10 do

        if not AutofarmBarista.Running then
            return false
        end

        VIM:SendKeyEvent(
            true,
            Enum.KeyCode.Return,
            false,
            game
        )

        task.wait(0.05)

        VIM:SendKeyEvent(
            false,
            Enum.KeyCode.Return,
            false,
            game
        )

        task.wait(0.25)
    end

    task.wait(0.8)

    -- =====================================================
    -- CHECK JOB
    -- =====================================================

    local gotJob = false
    local jobConnection

    if jobRemote
        and jobRemote:IsA("RemoteEvent") then

        jobConnection =
            jobRemote.OnClientEvent:Connect(
                function(action, jobName)

                    dbg(
                        "JOB_EVENT",
                        tostring(action),
                        tostring(jobName)
                    )

                    if action == "SetJob"
                        and tostring(jobName)
                            == "Barista" then

                        gotJob = true
                    end
                end
            )
    end

    local startTime =
        os.clock()

    while
        AutofarmBarista.Running
        and os.clock() - startTime < 10
    do

        -- Job GUI.
        local jobGui =
            PlayerGui:FindFirstChild(
                "Job"
            )

        local baristaGui =
            jobGui
            and jobGui:FindFirstChild(
                "Barista"
            )

        if baristaGui then
            gotJob = true
            break
        end

        -- Character Job value.
        local character =
            LocalPlayer.Character

        if character then

            local jobValue =
                character:FindFirstChild(
                    "Job"
                )

            if jobValue
                and jobValue:IsA(
                    "StringValue"
                )
                and jobValue.Value
                    == "Barista" then

                gotJob = true
                break
            end
        end

        task.wait(0.2)
    end

    if jobConnection then
        jobConnection:Disconnect()
        jobConnection = nil
    end

    if gotJob then

        AutofarmBarista.CurrentStep =
            "Barista Job Acquired"

        dbg(
            "JOB",
            "Barista job acquired successfully"
        )

        task.wait(1)

        return true
    end

    dbg(
        "JOB",
        "Job confirmation not detected"
    )

    -- Keep existing permissive behavior.
    task.wait(1)

    return true
end

-- =========================================================
-- STATION POSITIONS
-- =========================================================

local STATION_POSITIONS = {

    BeanHopper =
        Vector3.new(
            8415.3,
            23.5,
            53.8085098
        ),

    Brewer =
        Vector3.new(
            8416.7,
            23.5,
            53.8085098
        ),

    Steamer =
        Vector3.new(
            8419,
            23.5,
            53.8085098
        ),

    Milk =
        Vector3.new(
            8426.7,
            23.5,
            53.8085098
        ),

    IceMaker =
        Vector3.new(
            8431,
            23.5,
            53.8085098
        ),

    CreamDispenser =
        Vector3.new(
            8433.7,
            23.5,
            53.8085098
        ),

    Carbonator =
        Vector3.new(
            8436.2,
            23.5,
            53.8085098
        ),

    BobaPot =
        Vector3.new(
            8436.4,
            23.5,
            53.8085098
        ),

    WaterTap =
        Vector3.new(
            8436.50586,
            23.5,
            18.9660721
        ),

    TeaBox =
        Vector3.new(
            8438.5,
            23.5,
            53.8085098
        ),

    LemonBoard =
        Vector3.new(
            8441,
            23.5,
            53.8085098
        ),

    MatchaJar =
        Vector3.new(
            8441.2,
            23.5,
            53.8085098
        ),

    ChocolateJar =
        Vector3.new(
            8443.2,
            23.5,
            53.8085098
        ),

    CreamJar =
        Vector3.new(
            8443.6,
            23.5,
            53.8085098
        ),

    FlavourBottle =
        Vector3.new(
            8449,
            23.5,
            53.8085098
        ),

    CupRack =
        Vector3.new(
            8413.8,
            23.5,
            53.8085098
        ),

    Trash =
        Vector3.new(
            8409.1,
            23.5,
            53.8085098
        ),

    BrewHoldArea =
        Vector3.new(
            8415.4,
            23.5,
            53.8085098
        ),
}

-- =========================================================
-- BARISTA REMOTE LISTENER
-- =========================================================

local function attachListener()

    if baristaConn then
        baristaConn:Disconnect()
        baristaConn = nil
    end

    lastCupState = nil
    lastOrderData = nil

    if not BaristaRemote then
        return
    end

    baristaConn =
        BaristaRemote.OnClientEvent:Connect(
            function(
                action,
                data,
                extra
            )

                dbg(
                    "EVENT",
                    tostring(action),
                    type(data) == "table"
                        and "<table>"
                        or tostring(data),
                    tostring(extra)
                )

                if action == "CupState"
                    and type(data) == "table" then

                    lastCupState = data

                    AutofarmBarista.CurrentStep =
                        tostring(
                            data.nextStep
                            or data.nextStation
                            or "?"
                        )

                elseif action == "OrderTaken"
                    and not lastOrderData then

                    lastOrderData = {
                        menuId = data,
                        flavour = extra
                    }

                elseif action == "OrderDone" then

                    Stats.Orders += 1

                elseif action == "JobProgress"
                    and type(data) == "table" then

                    Stats.Salary =
                        tonumber(data.salary)
                        or Stats.Salary

                    Stats.XP =
                        tonumber(data.xp)
                        or Stats.XP

                elseif action == "LevelUpBanner" then

                    notify(
                        "Level Up!",
                        tostring(data)
                            .. " XP",
                        3,
                        "sparkles"
                    )

                elseif action == "HasClaimable" then

                    BaristaRemote:FireServer(
                        "Claim"
                    )
                end
            end
        )
end

-- =========================================================
-- BREW MINIGAME
-- =========================================================

local function autoBrewMinigame()

    local jobGui =
        PlayerGui:FindFirstChild(
            "Job"
        )

    local brewGui =
        jobGui
        and jobGui:FindFirstChild(
            "BrewMinigame"
        )

    if not brewGui
        or not brewGui.Visible then

        return false
    end

    local track =
        brewGui:FindFirstChild(
            "Track"
        )

    local zone =
        track
        and track:FindFirstChild(
            "Zone"
        )

    local needle =
        track
        and track:FindFirstChild(
            "Needle"
        )

    local result =
        brewGui:FindFirstChild(
            "ResultLabel"
        )

    if not (
        zone
        and needle
        and result
    ) then

        dbg(
            "BREW",
            "minigame elements missing"
        )

        return false
    end

    local waited = 0

    while
        zone.AbsoluteSize.X == 0
        and waited < 30
    do

        task.wait(0.05)
        waited += 1
    end

    dbg(
        "BREW",
        "minigame start"
    )

    local holding = false

    local conn =
        RunService.Heartbeat:Connect(
            function()

                if not brewGui.Visible
                    or not AutofarmBarista.Running then

                    return
                end

                local needleMid =
                    needle.AbsolutePosition.X
                    + needle.AbsoluteSize.X
                    / 2

                local zoneLeft =
                    zone.AbsolutePosition.X

                local inside =
                    needleMid > zoneLeft
                    and needleMid <
                        zoneLeft
                        + zone.AbsoluteSize.X

                if inside ~= holding then

                    holding = inside

                    VIM:SendKeyEvent(
                        inside,
                        Enum.KeyCode.Space,
                        false,
                        game
                    )
                end
            end
        )

    local ticks = 0

    while
        result.Text ~= "100%"
        and ticks < 300
        and AutofarmBarista.Running
        and brewGui.Visible
    do

        task.wait(0.1)

        ticks += 1
    end

    conn:Disconnect()

    if holding then

        VIM:SendKeyEvent(
            false,
            Enum.KeyCode.Space,
            false,
            game
        )
    end

    local success =
        result.Text == "100%"

    dbg(
        "BREW",
        "result",
        result.Text,
        "success",
        success
    )

    BaristaRemote:FireServer(
        "BrewResult",
        success and 1 or 0
    )

    task.wait(0.3)

    return success
end

-- =========================================================
-- CUP STATE
-- =========================================================

local function waitForCupState(timeout)

    local ticks = 0

    local limit =
        (timeout or 5) * 10

    while
        not lastCupState
        and ticks < limit
        and AutofarmBarista.Running
    do

        task.wait(0.1)

        ticks += 1
    end

    local state =
        lastCupState

    lastCupState = nil

    return state
end

-- =========================================================
-- USE STATION
-- =========================================================

local function useStation(
    ws,
    stationName
)

    local stationPos =
        STATION_POSITIONS[
            stationName
        ]

    if stationPos then

        teleportTo(
            stationPos
        )

    else

        local obj =
            ws.Stations
            and ws.Stations:FindFirstChild(
                stationName
            )

        if obj then
            tweenTo(obj)
        end
    end

    task.wait(0.4)

    local obj =
        ws.Stations
        and ws.Stations:FindFirstChild(
            stationName
        )

    local prompt =
        obj
        and obj:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )

    if prompt then

        firePrompt(prompt)

    else

        BaristaRemote:FireServer(
            "Station",
            stationName
        )
    end

    task.wait(0.3)
end

-- =========================================================
-- STATION LOOP
-- =========================================================

local function runStationLoop(ws)

    for step = 1, 30 do

        if not AutofarmBarista.Running then
            break
        end

        local state =
            waitForCupState(8)

        if not state then

            dbg(
                "LOOP",
                "CupState timeout at step",
                step
            )

            break
        end

        if state.ruined then

            AutofarmBarista.CurrentStep =
                "Cup ruined, discarding..."

            notify(
                "Barista",
                "Cup ruined, discarding...",
                2
            )

            return "ruined"
        end

        if state.doneCount
            and state.stepCount
            and state.doneCount
                >= state.stepCount then

            AutofarmBarista.CurrentStep =
                "Ready to serve!"

            return "done"
        end

        local stationName =
            state.nextStation

        if not stationName then

            dbg(
                "LOOP",
                "no nextStation at step",
                step
            )

            break
        end

        AutofarmBarista.CurrentStep =
            "Step: "
            .. tostring(
                state.nextStep
                or stationName
            )

        dbg(
            "LOOP",
            "step",
            step,
            "->",
            stationName
        )

        useStation(
            ws,
            stationName
        )

        task.wait(0.2)

        autoBrewMinigame()
    end

    return "timeout"
end

-- =========================================================
-- TAKE CUSTOMER ORDER
-- =========================================================

local function takeOrderFromCustomer(
    customer,
    orderIndex
)

    local hrp =
        customer:FindFirstChild(
            "HumanoidRootPart"
        )

    if not hrp then
        return nil
    end

    AutofarmBarista.CurrentStep =
        "Taking order #"
        .. orderIndex

    tweenTo(hrp)

    lastOrderData = nil

    BaristaRemote:FireServer(
        "TakeOrder",
        orderIndex
    )

    task.wait(0.5)

    local servePrompt =
        hrp:FindFirstChild(
            "BaristaServePrompt"
        )

    if servePrompt then
        firePrompt(
            servePrompt
        )
    end

    local ticks = 0

    while
        not lastOrderData
        and ticks < 150
        and AutofarmBarista.Running
    do

        task.wait(0.1)

        ticks += 1
    end

    dbg(
        "ORDER",
        "data",
        lastOrderData
            and lastOrderData.menuId
            or "nil"
    )

    return lastOrderData
end

-- =========================================================
-- GRAB CUP
-- =========================================================

local function grabCup(ws)

    teleportTo(
        STATION_POSITIONS.CupRack
    )

    task.wait(0.4)

    lastCupState = nil

    local rack =
        ws.Stations
        and ws.Stations:FindFirstChild(
            "CupRack"
        )

    local prompt =
        rack
        and rack:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )

    if prompt then

        firePrompt(prompt)

    else

        BaristaRemote:FireServer(
            "Station",
            "CupRack"
        )
    end

    task.wait(0.5)
end

-- =========================================================
-- DISCARD CUP
-- =========================================================

local function discardCup(ws)

    teleportTo(
        STATION_POSITIONS.Trash
    )

    task.wait(0.3)

    local obj =
        ws.Stations
        and ws.Stations:FindFirstChild(
            "Trash"
        )

    local prompt =
        obj
        and obj:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )

    if prompt then

        firePrompt(prompt)

    else

        BaristaRemote:FireServer(
            "Station",
            "Trash"
        )
    end

    task.wait(0.5)
end

-- =========================================================
-- MAKE DRINK
-- =========================================================

local function makeDrink(
    orderData,
    ws
)

    local menuId =
        orderData.menuId
        or "?"

    local flavour =
        orderData.flavour
        or "?"

    dbg(
        "DRINK",
        "preparing",
        menuId,
        "flavour",
        flavour
    )

    AutofarmBarista.CurrentStep =
        "Taking cup for "
        .. tostring(menuId)

    notify(
        "Barista",
        "Preparing "
            .. tostring(menuId)
            .. " (Flavour: "
            .. tostring(flavour)
            .. ")",
        3,
        "coffee"
    )

    BaristaRemote:FireServer(
        "Pick",
        "Menu",
        menuId
    )

    task.wait(0.5)

    grabCup(ws)

    local result =
        runStationLoop(ws)

    if result == "ruined"
        and AutofarmBarista.Running then

        discardCup(ws)

        BaristaRemote:FireServer(
            "Pick",
            "Menu",
            menuId
        )

        task.wait(0.5)

        grabCup(ws)

        result =
            runStationLoop(ws)
    end

    return result
end

-- =========================================================
-- SERVE CUSTOMER
-- =========================================================

local function serveCustomer(
    customer
)

    local hrp =
        customer:FindFirstChild(
            "HumanoidRootPart"
        )

    if not hrp then
        return
    end

    AutofarmBarista.CurrentStep =
        "Serving drink..."

    tweenTo(hrp)

    local servePrompt =
        hrp:FindFirstChild(
            "BaristaServePrompt"
        )

    if servePrompt then

        firePrompt(
            servePrompt
        )

    else

        BaristaRemote:FireServer(
            "Serve",
            customer.Name
        )
    end

    task.wait(0.5)

    notify(
        "Barista",
        "Order done! "
            .. fmtStats(),
        3,
        "coffee"
    )
end

-- =========================================================
-- MAIN JOB
-- =========================================================

local function startJob()

    dbg(
        "JOB",
        "start"
    )

    local container =
        ReplicatedStorage:WaitForChild(
            "NetworkContainer",
            30
        )

    local remotes =
        container
        and container:WaitForChild(
            "RemoteEvents",
            30
        )

    if not remotes then

        dbg(
            "JOB",
            "RemoteEvents not found"
        )

        AutofarmBarista.Running =
            false

        return
    end

    -- =====================================================
    -- GET REMOTES
    -- =====================================================

    JobRemote =
        remotes:WaitForChild(
            "Job",
            30
        )

    NpcDialogRemote =
        remotes:WaitForChild(
            "NpcDialog",
            60
        )

    BaristaRemote =
        remotes:WaitForChild(
            "Barista",
            60
        )

    dbg(
        "REMOTE",
        "Job:",
        JobRemote ~= nil,
        "NpcDialog:",
        NpcDialogRemote ~= nil,
        "Barista:",
        BaristaRemote ~= nil
    )

    if not BaristaRemote then

        dbg(
            "JOB",
            "Barista remote not found"
        )

        AutofarmBarista.Running =
            false

        return
    end

    -- =====================================================
    -- WORKSPACE
    -- =====================================================

    local ws =
        getWorkspaceRefs()

    -- =====================================================
    -- GET BARISTA JOB
    -- =====================================================

    local jobStarted =
        getBaristaJob(
            ws,
            JobRemote
        )

    if not jobStarted then

        dbg(
            "JOB",
            "Failed to acquire Barista job"
        )

        AutofarmBarista.Running =
            false

        return
    end

    -- =====================================================
    -- LISTENER
    -- =====================================================

    attachListener()

    task.wait(1)

    -- =====================================================
    -- PHONE / NORMAL BARISTA SETUP
    -- =====================================================

    AutofarmBarista.CurrentStep =
        "Barista job active..."

    task.wait(2)

    if ws.Telephone then

        AutofarmBarista.CurrentStep =
            "Opening Barista phone..."

        tweenTo(
            ws.Telephone
        )

        task.wait(0.5)

        local phonePrompt =
            ws.Telephone:FindFirstChild(
                "BaristaPhonePrompt"
            )
            or ws.Telephone:FindFirstChildWhichIsA(
                "ProximityPrompt",
                true
            )

        if phonePrompt then
            firePrompt(
                phonePrompt
            )
        end

        task.wait(1)

        safeFiresignal(
            BaristaRemote.OnClientEvent,
            "Tutorial"
        )

        task.wait(0.3)

        for _ = 1, 26 do

            if not AutofarmBarista.Running then
                break
            end

            VirtualUser:ClickButton2(
                Vector2.new(0, 0)
            )

            task.wait(0.5)
        end

    else

        dbg(
            "JOB",
            "Telephone missing"
        )
    end

    task.wait(2)

    -- =====================================================
    -- REFRESH WORKSPACE REFERENCES
    -- =====================================================

    ws =
        getWorkspaceRefs()

    -- =====================================================
    -- CUSTOMER LOOP
    -- =====================================================

    local orderIndex = 1

    while AutofarmBarista.Running do

        AutofarmBarista.CurrentStep =
            "Waiting for customer..."

        local target
        local elapsed = 0

        while
            not target
            and elapsed < 30
            and AutofarmBarista.Running
        do

            if ws.BaristaCustomers then

                for _, customer
                    in ipairs(
                        ws.BaristaCustomers:GetChildren()
                    )
                do

                    local hrp =
                        customer:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    if hrp
                        and hrp:FindFirstChild(
                            "BaristaServePrompt"
                        ) then

                        target =
                            customer

                        break
                    end
                end
            else

                -- Customer container may have loaded late.
                ws.BaristaCustomers =
                    workspace:FindFirstChild(
                        "BaristaCustomers"
                    )
            end

            if not target then

                task.wait(1)

                elapsed += 1
            end
        end

        if not target then

            dbg(
                "JOB",
                "no customer after 30s"
            )

            task.wait(2)

            continue
        end

        -- =================================================
        -- TAKE ORDER
        -- =================================================

        local orderData =
            takeOrderFromCustomer(
                target,
                orderIndex
            )

        if not orderData then

            dbg(
                "JOB",
                "no order data for #"
                    .. orderIndex
            )

            orderIndex += 1

            task.wait(1)

            continue
        end

        lastOrderData = nil

        -- =================================================
        -- MAKE DRINK
        -- =================================================

        local result =
            makeDrink(
                orderData,
                ws
            )

        dbg(
            "JOB",
            "make result",
            result
        )

        -- =================================================
        -- SERVE
        -- =================================================

        if result == "done" then

            serveCustomer(
                target
            )
        end

        orderIndex += 1

        task.wait(0.5)
    end

    -- =====================================================
    -- CLEANUP
    -- =====================================================

    if baristaConn then

        baristaConn:Disconnect()

        baristaConn = nil
    end

    AutofarmBarista.CurrentStep =
        "Idle"

    dbg(
        "JOB",
        "stopped"
    )
end

-- =========================================================
-- STOP FARM
-- =========================================================

local function stopFarm()

    AutofarmBarista.Running =
        false

    if AutofarmBarista.Thread then

        pcall(
            task.cancel,
            AutofarmBarista.Thread
        )

        AutofarmBarista.Thread =
            nil
    end

    if baristaConn then

        baristaConn:Disconnect()

        baristaConn = nil
    end

    AutofarmBarista.CurrentStep =
        "Idle"
end

-- =========================================================
-- RESTORE CONFIG
-- =========================================================

local savedAutoLoad

if hasFS
    and isfile(AUTOLOAD) then

    local ok, name =
        pcall(
            readfile,
            AUTOLOAD
        )

    if ok
        and name
        and name ~= "" then

        savedAutoLoad =
            name

        ConfigManager.Load(
            name
        )
    end
end

-- =========================================================
-- WINDOW
-- =========================================================

local Window =
    WindUI:CreateWindow({

        Title =
            "DX-SR Hub",

        Icon =
            "coffee",

        Author =
            "Barista Autofarm v0.0.0.6",

        Folder =
            FOLDER,

        Size =
            UDim2.fromOffset(
                580,
                400
            ),

        Theme =
            Flags.SelectedTheme,

        Resizable =
            true,

        SideBarWidth =
            200,

        ScrollBarEnabled =
            true,

        HideSearchBar =
            false,

        ToggleKey =
            Enum.KeyCode.V,
    })

-- =========================================================
-- MAIN TAB
-- =========================================================

local mainTab =
    Window:Tab({

        Title = "Main",

        Icon = "home"
    })

mainTab:Section({

    Title =
        "Autofarm Barista"
})

local statusPara =
    mainTab:Paragraph({

        Title =
            "Status",

        Desc =
            "Idle"
    })

local stepPara =
    mainTab:Paragraph({

        Title =
            "Current Step",

        Desc =
            "Idle"
    })

local statsPara =
    mainTab:Paragraph({

        Title =
            "Session Stats",

        Desc =
            fmtStats()
    })

local farmToggle

farmToggle =
    mainTab:Toggle({

        Title =
            "Barista Autofarm",

        Desc =
            "Auto complete barista orders",

        Value =
            false,

        Callback =
            function(state)

                Flags.AutofarmBarista =
                    state

                if state then

                    if AutofarmBarista.Running then
                        return
                    end

                    AutofarmBarista.Running =
                        true

                    notify(
                        "Barista Autofarm",
                        "Started",
                        3,
                        "coffee"
                    )

                    AutofarmBarista.Thread =
                        task.spawn(
                            function()

                                local ok, err =
                                    pcall(
                                        startJob
                                    )

                                if not ok then

                                    dbg(
                                        "ERROR",
                                        err
                                    )

                                    warn(
                                        "[Barista] Error: "
                                            .. tostring(err)
                                    )

                                    notify(
                                        "Error",
                                        tostring(err),
                                        5
                                    )

                                    stopFarm()

                                    if farmToggle then

                                        pcall(
                                            function()

                                                farmToggle:Set(
                                                    false
                                                )
                                            end
                                        )
                                    end
                                end
                            end
                        )

                else

                    stopFarm()

                    notify(
                        "Barista Autofarm",
                        "Stopped.",
                        2
                    )
                end
            end
    })

mainTab:Toggle({

    Title =
        "Only Mobile",

    Desc =
        "Use mobile-only input method",

    Value =
        false,

    Callback =
        function(state)

            Flags.OnlyMobile =
                state
        end
})

-- =========================================================
-- STATUS UPDATE
-- =========================================================

task.spawn(
    function()

        while task.wait(0.5) do

            pcall(
                function()

                    statusPara:SetDesc(
                        AutofarmBarista.Running
                            and "Running"
                            or "Idle"
                    )

                    stepPara:SetDesc(
                        tostring(
                            AutofarmBarista.CurrentStep
                        )
                    )

                    statsPara:SetDesc(
                        fmtStats()
                    )
                end
            )
        end
    end
)

-- =========================================================
-- SETTINGS
-- =========================================================

local settingsTab =
    Window:Tab({

        Title =
            "Settings",

        Icon =
            "settings"
    })

settingsTab:Section({

    Title =
        "Configuration"
})

local configName = ""
local selectedConfig = nil

settingsTab:Input({

    Title =
        "Config Name",

    Placeholder =
        "Enter config name...",

    Callback =
        function(text)

            configName =
                text
        end
})

local configDropdown

local function refreshConfigs()

    if configDropdown then

        pcall(
            function()

                configDropdown:Refresh(
                    ConfigManager.List()
                )
            end
        )
    end
end

settingsTab:Button({

    Title =
        "Save Config",

    Desc =
        "Save current settings to a new config",

    Callback =
        function()

            if ConfigManager.Save(
                configName
            ) then

                refreshConfigs()
            end
        end
})

settingsTab:Section({

    Title =
        "Load / Delete Config"
})

configDropdown =
    settingsTab:Dropdown({

        Title =
            "Select Config",

        Values =
            ConfigManager.List(),

        Multi =
            false,

        Callback =
            function(value)

                selectedConfig =
                    value
            end
    })

settingsTab:Button({

    Title =
        "Load Config",

    Callback =
        function()

            if ConfigManager.Load(
                selectedConfig
            ) then

                pcall(
                    function()

                        WindUI:SetTheme(
                            Flags.SelectedTheme
                        )
                    end
                )
            end
        end
})

settingsTab:Button({

    Title =
        "Rewrite Config",

    Callback =
        function()

            ConfigManager.Save(
                selectedConfig
            )
        end
})

settingsTab:Button({

    Title =
        "Delete Config",

    Callback =
        function()

            if ConfigManager.Delete(
                selectedConfig
            ) then

                selectedConfig =
                    nil

                refreshConfigs()
            end
        end
})

settingsTab:Toggle({

    Title =
        "Set Auto Load",

    Desc =
        "Load the selected config on start",

    Value =
        savedAutoLoad ~= nil,

    Callback =
        function(state)

            ConfigManager.SetAutoLoad(
                selectedConfig,
                state
            )
        end
})

-- =========================================================
-- THEME
-- =========================================================

local themeTab =
    Window:Tab({

        Title =
            "Theme",

        Icon =
            "palette"
    })

themeTab:Section({

    Title =
        "Select Theme"
})

local themeNames = {}

local okThemes, themeTable =
    pcall(
        function()

            return WindUI:GetThemes()
        end
    )

if okThemes
    and type(themeTable) == "table" then

    for name in pairs(themeTable) do

        table.insert(
            themeNames,
            name
        )
    end

    table.sort(
        themeNames
    )
end

if #themeNames == 0 then

    themeNames = {

        "Dark",
        "Light",
        "Rose",
        "Indigo",
        "Sky",
        "Violet",
        "Amber",
        "Emerald",
        "Midnight",
        "Crimson"
    }
end

themeTab:Dropdown({

    Title =
        "Choose UI Theme",

    Values =
        themeNames,

    Value =
        Flags.SelectedTheme,

    Callback =
        function(value)

            Flags.SelectedTheme =
                value

            pcall(
                function()

                    WindUI:SetTheme(
                        value
                    )
                end
            )
        end
})

-- =========================================================
-- DEBUG TAB
-- =========================================================

local debugTab =
    Window:Tab({

        Title =
            "Debug",

        Icon =
            "bug"
    })

debugTab:Section({

    Title =
        "Logging"
})

debugTab:Toggle({

    Title =
        "Console Logging",

    Desc =
        "Print debug lines to the executor console",

    Value =
        Debug.Enabled,

    Callback =
        function(state)

            Debug.Enabled =
                state
        end
})

debugTab:Button({

    Title =
        "Copy Log",

    Desc =
        "Copy the last "
            .. Debug.Max
            .. " lines to the clipboard",

    Callback =
        function()

            if type(setclipboard)
                == "function" then

                setclipboard(
                    table.concat(
                        Debug.Buffer,
                        "\n"
                    )
                )

                notify(
                    "Debug",
                    "Log copied ("
                        .. #Debug.Buffer
                        .. " lines)"
                )

            else

                notify(
                    "Debug",
                    "setclipboard unsupported"
                )
            end
        end
})

debugTab:Button({

    Title =
        "Clear Log",

    Callback =
        function()

            table.clear(
                Debug.Buffer
            )

            notify(
                "Debug",
                "Log cleared"
            )
        end
})

debugTab:Button({

    Title =
        "Dump State",

    Desc =
        "Log running state, remotes and executor capabilities",

    Callback =
        function()

            dbg(
                "STATE",
                "running",
                AutofarmBarista.Running,
                "step",
                AutofarmBarista.CurrentStep
            )

            dbg(
                "STATE",
                "BaristaRemote",
                BaristaRemote ~= nil,
                "NpcDialog",
                NpcDialogRemote ~= nil,
                "Job",
                JobRemote ~= nil
            )

            dbg(
                "STATE",
                "orders",
                Stats.Orders,
                "salary",
                Stats.Salary,
                "xp",
                Stats.XP
            )

            dbg(
                "STATE",
                "Manager CFrame",
                tostring(
                    BARISTA_MANAGER_CFRAME
                )
            )

            dbg(
                "STATE",
                "fireproximityprompt",
                type(
                    fireproximityprompt
                ) == "function",

                "firesignal",
                type(
                    firesignal
                ) == "function",

                "writefile",
                type(
                    writefile
                ) == "function",

                "listfiles",
                type(
                    listfiles
                ) == "function",

                "setclipboard",
                type(
                    setclipboard
                ) == "function"
            )

            notify(
                "Debug",
                "State dumped to log"
            )
        end
})

-- =========================================================
-- INFORMATION
-- =========================================================

local infoTab =
    Window:Tab({

        Title =
            "Information",

        Icon =
            "info"
    })

infoTab:Section({

    Title =
        "Script Hub"
})

infoTab:Paragraph({

    Title =
        "Hub",

    Desc =
        "DX-SR Hub"
})

infoTab:Paragraph({

    Title =
        "Script",

    Desc =
        "Autofarm Barista"
})

infoTab:Paragraph({

    Title =
        "Version",

    Desc =
        "v0.0.0.6"
})

infoTab:Paragraph({

    Title =
        "Author",

    Desc =
        "DX-SR"
})

infoTab:Paragraph({

    Title =
        "UI",

    Desc =
        "WindUI"
})

-- =========================================================
-- LOADED
-- =========================================================

notify(
    "DX-SR Hub",
    "Barista Autofarm v0.0.0.6 loaded! Press V to toggle UI.",
    5,
    "coffee"
)

dbg(
    "BOOT",
    "UI ready"
)