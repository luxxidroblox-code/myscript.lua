-- =========================================================
-- SERVICE
-- =========================================================
local Players             = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService        = game:GetService("TweenService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")
local CoreGui             = game:GetService("CoreGui")
local RunService          = game:GetService("RunService")
local HttpService         = game:GetService("HttpService")
local SoundService        = game:GetService("SoundService")
local LocalPlayer         = Players.LocalPlayer
local playerGui           = LocalPlayer:FindFirstChild("PlayerGui")

local Connections         = {}
local CleanupObjects      = {}
local originalMaterials   = {}
local originalShadows     = {}
local originalQualityLevel = settings().Rendering.QualityLevel

-- =========================================================
-- CONFIG
-- =========================================================
local Config = {
    DEBUG_MODE    = false,
    IS_RUNNING    = false,
    SESSION_TOKEN = nil,
}

-- =========================================================
-- AUDIO
-- =========================================================
local AudioRegistry = {
    WelcomeHub  = "rbxassetid://6112625298",
    MinimizeHub = "rbxassetid://74947743572579",
    AutoFarmBGM = "rbxassetid://86316862829978",
    ToastSFX    = "rbxassetid://129485210015224",
}
local currentBGMTrack = nil

local function playEffect(actionType, isLooping)
    if isLooping and currentBGMTrack then
        pcall(function() currentBGMTrack:Destroy() end)
        currentBGMTrack = nil
    end
    task.spawn(function()
        pcall(function()
            local snd   = Instance.new("Sound")
            snd.SoundId = AudioRegistry[actionType] or AudioRegistry.ToastSFX
            snd.Volume  = 0.8
            snd.Looped  = isLooping or false
            local holder = nil
            pcall(function() holder = gethui() end)
            if not holder then pcall(function() holder = CoreGui end) end
            if not holder then holder = SoundService end
            snd.Parent = holder
            if not snd.IsLoaded then snd.Loaded:Wait() end
            snd:Play()
            if isLooping then
                currentBGMTrack = snd
            else
                task.delay(snd.TimeLength + 0.8, function() pcall(function() snd:Destroy() end) end)
            end
        end)
    end)
end

-- =========================================================
-- HELPERS
-- =========================================================
local function debugPrint(msg) if Config.DEBUG_MODE then print("[PROJ-PRINT] " .. tostring(msg)) end end
local function debugWarn(msg)  if Config.DEBUG_MODE then warn("[PROJ-WARN] "  .. tostring(msg)) end end

-- =========================================================
-- LIFECYCLE
-- =========================================================
local function destroyHub(reason)
    debugPrint("Cleaning up... Reason: " .. tostring(reason or "Manual"))
    Config.IS_RUNNING = false
    for name, conn in pairs(Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    table.clear(Connections)
    for name, obj in pairs(CleanupObjects) do
        if obj and obj.Parent then pcall(function() obj:Destroy() end) end
    end
    table.clear(CleanupObjects)
end

Connections["PlayerLeave"] = LocalPlayer.AncestryChanged:Connect(function(_, parent)
    destroyHub("Player Close The Game")
end)

-- =========================================================
-- RAYFIELD
-- =========================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- =========================================================
-- MAIN
-- =========================================================
local function mainScreen()
    Config.IS_RUNNING = true

    local Window = Rayfield:CreateWindow({
        Name                   = ".projectsion",
        Icon                   = 0,
        LoadingTitle           = ".projectsion",
        LoadingSubtitle        = "Car Driving Indonesia | Barista",
        Theme                  = "Default",
        DisableRayfieldPrompts = false,
        DisableBuildWarnings   = false,
        ConfigurationSaving    = { Enabled = false },
        KeySystem              = false,
    })

    -- HOME TAB
    local HomeTab = Window:CreateTab("Home", "home")

    HomeTab:CreateSection("Profile")
    HomeTab:CreateLabel("Username: "     .. LocalPlayer.Name)
    HomeTab:CreateLabel("Display Name: " .. LocalPlayer.DisplayName)
    HomeTab:CreateLabel("User ID: "      .. tostring(LocalPlayer.UserId))

    HomeTab:CreateSection("Stats")
    local sessionLabel = HomeTab:CreateLabel("Session: 00:00:00")
    local fpsLabel     = HomeTab:CreateLabel("FPS: 0")
    local pingLabel    = HomeTab:CreateLabel("Ping: 0 MS")

    local sessionStartTick = tick()
    local countedFrames    = 0
    local timerTick        = tick()

    Connections["FPS_RS"] = RunService.RenderStepped:Connect(function()
        countedFrames += 1
    end)

    task.spawn(function()
        while task.wait(0.5) do
            local now     = tick()
            local dt      = now - timerTick
            local elapsed = math.floor(now - sessionStartTick)
            pcall(function()
                sessionLabel.Label.Text = string.format("Session: %02d:%02d:%02d",
                    math.floor(elapsed / 3600),
                    math.floor((elapsed % 3600) / 60),
                    elapsed % 60)
            end)
            if dt > 0 then
                local fps = math.floor(countedFrames / dt + 0.5)
                timerTick     = now
                countedFrames = 0
                pcall(function() fpsLabel.Label.Text = "FPS: " .. fps end)
            end
            pcall(function()
                local stats    = game:GetService("Stats")
                local pingItem = stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
                if pingItem then
                    pingLabel.Label.Text = "Ping: " .. math.floor(pingItem:GetValue()) .. " MS"
                end
            end)
        end
    end)

    HomeTab:CreateSection("Links")
    HomeTab:CreateButton({
        Name     = "Copy Discord",
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/KeNubYZzeB")
                Rayfield:Notify({ Title = ".projectsion", Content = "Discord link copied!", Duration = 3 })
            end
        end,
    })

    -- BARISTA TAB
    local BaristaTab = Window:CreateTab("Barista", "coffee")
    BaristaTab:CreateSection("Auto Barista")

    local statusLabel   = BaristaTab:CreateLabel("Status: ● STOPPED")
    local ordersLabel   = BaristaTab:CreateLabel("Orders Completed: 0")
    local elapsedLabel  = BaristaTab:CreateLabel("Elapsed: 00:00:00")
    local progressLabel = BaristaTab:CreateLabel("Info: Idle / Waiting to start...")
    local menuLabel     = BaristaTab:CreateLabel("Menu: -")
    local flavourLabel  = BaristaTab:CreateLabel("Flavour: -")

    -- BARISTA STATE
    local autoBarista          = false
    local startTime            = 0
    local ordersCompletedCount = 0
    local BaristaMenu          = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BaristaMenu"))
    local currentOrder         = nil

    local function updateStatus(msg)
        pcall(function() progressLabel.Label.Text = "Info: " .. msg end)
    end

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
        local char     = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local root     = char and char:FindFirstChild("HumanoidRootPart")
        local targetCF = nil

        if typeof(destination) == "CFrame" then
            targetCF = destination
        elseif type(destination) == "string" then
            local obj = workspace:FindFirstChild(destination, true)
            if obj then
                if obj:IsA("BasePart") then targetCF = obj.CFrame * CFrame.new(0, 0, -3)
                elseif obj:IsA("Model") then targetCF = obj:GetPivot() * CFrame.new(0, 0, -3) end
            end
        end

        if not targetCF then return end

        if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
            local seat    = humanoid.SeatPart
            local vehicle = seat.Parent
            if vehicle and vehicle:IsA("Model") then
                seat.AssemblyLinearVelocity  = Vector3.zero
                seat.AssemblyAngularVelocity = Vector3.zero
                vehicle:PivotTo(targetCF)
                task.wait(0.05)
                seat.AssemblyLinearVelocity  = Vector3.zero
                seat.AssemblyAngularVelocity = Vector3.zero
            end
        else
            if root then root.CFrame = targetCF end
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

    -- tunggu NpcDialog muncul dan punya text, return textnya
    local function waitForDialog(timeout)
        timeout = timeout or 8
        local deadline = os.clock() + timeout
        repeat
            local dlg = playerGui:FindFirstChild("NpcDialog")
            if dlg then
                local textObj = dlg
                if not (dlg:IsA("TextLabel") or dlg:IsA("TextButton") or dlg:IsA("TextBox")) then
                    textObj = dlg:FindFirstChildWhichIsA("TextLabel", true)
                end
                if textObj and textObj.Text and textObj.Text ~= "" then
                    return dlg, textObj.Text
                end
            end
            task.wait(0.1)
        until os.clock() > deadline
        return nil, nil
    end

    -- skip semua halaman dialog sampai NpcDialog hilang
    local function skipDialog(timeout)
        timeout = timeout or 6
        local deadline = os.clock() + timeout
        repeat
            pressSpaceKey(1, 0.15)
            task.wait(0.2)
        until not playerGui:FindFirstChild("NpcDialog") or os.clock() > deadline
        task.wait(0.3)
    end

    local function clickGuiButton(btn)
        if not btn then return end
        if firesignal then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            pcall(function() firesignal(btn.MouseButton1Down)  end)
            pcall(function() firesignal(btn.Activated)         end)
            return
        end
        if getconnections then
            local fired = false
            for _, event in ipairs({ btn.MouseButton1Click, btn.MouseButton1Down, btn.Activated }) do
                for _, conn in pairs(getconnections(event)) do
                    if conn.Fire     then pcall(function() conn:Fire()     end) fired = true
                    elseif conn.Function then pcall(function() conn:Function() end) fired = true end
                end
            end
            if fired then return end
        end
        if btn:IsA("GuiButton") then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:Button1Down(Vector2.new(0, 0))
                vu:Button1Up(Vector2.new(0, 0))
            end)
        end
    end

    local function runAutoBrew()
        local BrewGui = playerGui:WaitForChild("Job"):WaitForChild("BrewMinigame")
        local Track   = BrewGui:WaitForChild("Track")
        local Zone    = Track:WaitForChild("Zone")
        local Needle  = Track:WaitForChild("Needle")

        local deadline = os.clock() + 10
        while not BrewGui.Visible and os.clock() < deadline do task.wait(0.05) end
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
            local now = os.clock()
            local dt  = now - lastTime
            if dt > 0 then
                local needleX  = Needle.Position.X.Scale
                local zoneX    = Zone.Position.X.Scale
                local zoneW    = Zone.Size.X.Scale
                local targetX  = zoneX + (zoneW / 2)
                local velocity = (needleX - lastX) / dt
                local predTime = velocity > 0 and 0.30 or 0.08
                local predX    = needleX + (velocity * predTime)
                local err      = targetX - predX
                local tol      = 0.012
                if err > tol then setHold(true)
                elseif err < -tol then setHold(false)
                else setHold(false) end
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
        local dlg, text = waitForDialog(5)
        if not dlg or not text then return nil end

        local menuName, flavour
        menuName, flavour = text:match("[Pp]esan%s+(.+),%s*[Rr]asa%s+(.+)%s+[Yy]a")
        if not menuName then menuName = text:match("[Pp]esan%s+(.+)%s+[Yy]a") end
        if not menuName then return nil end

        menuName = menuName:gsub("^%s+", ""):gsub("%s+$", "")
        if flavour then flavour = flavour:gsub("^%s+", ""):gsub("%s+$", "") end

        local menuId = getMenuIdFromName(menuName)
        if not menuId then return nil end

        currentOrder = { Menu = menuName, MenuId = menuId, Flavour = flavour, RawText = text }
        pcall(function()
            menuLabel.Label.Text    = "Menu: "    .. (currentOrder.Menu    or "-")
            flavourLabel.Label.Text = "Flavour: " .. (currentOrder.Flavour or "-")
        end)
        return currentOrder
    end

    local function selectCurrentFlavour()
        local flavourName = currentOrder and currentOrder.Flavour
        if not flavourName or flavourName == "" then return false end
        local choicePicker = playerGui and playerGui:FindFirstChild("Job") and playerGui.Job:FindFirstChild("ChoicePicker")
        local flavourGrid  = choicePicker and choicePicker:FindFirstChild("Grid")
        local flavourBtn   = nil
        if flavourGrid then
            flavourBtn = flavourGrid:FindFirstChild(flavourName)
            if not flavourBtn then
                for _, btn in ipairs(flavourGrid:GetChildren()) do
                    if btn.Name:lower() == flavourName:lower() or btn.Name:find(flavourName) then
                        flavourBtn = btn break
                    end
                end
            end
        end
        if flavourBtn then clickGuiButton(flavourBtn) task.wait(1) return true end
        return false
    end

    -- DRINK CONSTRUCTORS
    local function stations() return workspace.Barista.Stations end

    local function doKopiHitam()
        updateStatus("Getting Coffee Beans...")
        smartTeleportTo(CFrame.new(-27.46021270751953, 24.607194900512695, 8416.7197265625)) task.wait(1)
        firePrompt(stations().BeanHopper.BaristaStationPrompt) task.wait(1)
        updateStatus("Loading Beans into Brewer...")
        firePrompt(stations().Brewer.BaristaStationPrompt) task.wait(0.2)
        updateStatus("Brewing Coffee...")
        if not runAutoBrew() then updateStatus("Brewing Failed!") return false end
        task.wait(1) return true
    end

    local function doCappuccino()
        if not doKopiHitam() then return false end
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(stations().Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Flavour...")
        smartTeleportTo(CFrame.new(-25.904417037963867, 24.565404891967773, 8441.203125)) task.wait(1)
        firePrompt(stations().FlavourBottle.BaristaStationPrompt) task.wait(1)
        updateStatus("Selecting Flavour...")
        if not selectCurrentFlavour() then updateStatus("Failed to Select Flavour!") return false end task.wait(1)
        updateStatus("Steaming Milk...")
        smartTeleportTo(CFrame.new(-23.854318618774414, 24.607194900512695, 8413.7763671875)) task.wait(1)
        firePrompt(stations().Steamer.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doEsKopiSusu()
        if not doKopiHitam() then return false end
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(stations().Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Flavour...")
        smartTeleportTo(CFrame.new(-25.904417037963867, 24.565404891967773, 8441.203125)) task.wait(1)
        firePrompt(stations().FlavourBottle.BaristaStationPrompt) task.wait(1)
        updateStatus("Selecting Flavour...")
        if not selectCurrentFlavour() then updateStatus("Failed to Select Flavour!") return false end task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(stations().IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doAmericano()
        if not doKopiHitam() then return false end
        updateStatus("Filling Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(stations().WaterTap.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doLatte()
        if not doKopiHitam() then return false end
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(stations().Milk.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doHotChocolate()
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(stations().Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Chocolate...")
        smartTeleportTo(CFrame.new(-20.886396408081055, 24.565404891967773, 8436.17578125)) task.wait(1)
        firePrompt(stations().ChocolateJar.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doMocha()
        if not doKopiHitam() then return false end
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(stations().Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Chocolate...")
        smartTeleportTo(CFrame.new(-20.886396408081055, 24.565404891967773, 8436.17578125)) task.wait(1)
        firePrompt(stations().ChocolateJar.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doMacchiato()
        if not doKopiHitam() then return false end
        updateStatus("Steaming Milk...")
        smartTeleportTo(CFrame.new(-23.854318618774414, 24.607194900512695, 8413.7763671875)) task.wait(1)
        firePrompt(stations().Steamer.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doFrappuccino()
        if not doKopiHitam() then return false end
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(stations().Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Adding Whipped Cream...")
        smartTeleportTo(CFrame.new(-34.13874053955078, 24.565404891967773, 8443.1826171875)) task.wait(1)
        firePrompt(stations().CreamDispenser.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(stations().IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doTea()
        updateStatus("Filling Hot Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(stations().WaterTap.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Tea Bag...")
        smartTeleportTo(CFrame.new(-16.10846519470215, 24.565404891967773, 8431.048828125)) task.wait(1)
        firePrompt(stations().TeaBox.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doThaiTea()
        if not doTea() then return false end
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(stations().Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(stations().IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doMatcha()
        updateStatus("Filling Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(stations().WaterTap.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Matcha Powder...")
        smartTeleportTo(CFrame.new(-18.60329246520996, 24.565404891967773, 8433.6748046875)) task.wait(1)
        firePrompt(stations().MatchaJar.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(stations().Milk.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doBubbleTea()
        if not doTea() then return false end
        updateStatus("Getting Milk...")
        smartTeleportTo(CFrame.new(-13.959260940551758, 24.011192321777344, 8427.1953125)) task.wait(1)
        firePrompt(stations().Milk.BaristaStationPrompt) task.wait(1)
        updateStatus("Adding Boba...")
        smartTeleportTo(CFrame.new(-23.343908309936523, 24.565404891967773, 8438.5400390625)) task.wait(1)
        firePrompt(stations().BobaPot.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(stations().IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doSoda()
        updateStatus("Filling Water...")
        smartTeleportTo(CFrame.new(-41.08833312988281, 23.017559051513672, 8436.4150390625)) task.wait(1)
        firePrompt(stations().WaterTap.BaristaStationPrompt) task.wait(1)
        updateStatus("Adding Carbonated Water...")
        smartTeleportTo(CFrame.new(-36.2972526550293, 24.565404891967773, 8441.0244140625)) task.wait(1)
        firePrompt(stations().Carbonator.BaristaStationPrompt) task.wait(1)
        updateStatus("Getting Ice Cubes...")
        smartTeleportTo(CFrame.new(-5.728482246398926, 24.632293701171875, 8415.39453125)) task.wait(1)
        firePrompt(stations().IceMaker.BaristaStationPrompt) task.wait(1)
        return true
    end

    local function doLemonade()
        if not doSoda() then return false end
        updateStatus("Cutting Lemon...")
        smartTeleportTo(CFrame.new(-28.2451171875, 24.565404891967773, 8443.5751953125)) task.wait(1)
        firePrompt(stations().LemonBoard.BaristaStationPrompt) task.wait(1)
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
        local cashierCF = CFrame.new(-32.88235092163086, 23.811004638671875, 8422.7119140625)

        updateStatus("Moving to Cashier...")
        smartTeleportTo(cashierCF)
        task.wait(1)

        -- scan customer
        updateStatus("Waiting for Customer...")
        local customers       = workspace:FindFirstChild("BaristaCustomers")
        local scanStart       = os.clock()
        local servePrompt     = nil
        local currentCustomer = nil

        while not servePrompt and os.clock() - scanStart < 30 do
            if customers then
                local closestDist = 6
                for _, cust in ipairs(customers:GetChildren()) do
                    local hrp = cust:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local prompt = hrp:FindFirstChild("BaristaServePrompt")
                        if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            local dist = (hrp.Position - cashierCF.Position).Magnitude
                            if dist <= closestDist then
                                closestDist     = dist
                                servePrompt     = prompt
                                currentCustomer = cust
                            end
                        end
                    end
                end
            end
            if not servePrompt then task.wait(0.2) end
        end

        if not servePrompt then
            updateStatus("Customer Not Found!")
            return
        end

        -- fire prompt ke customer
        updateStatus("Talking to Customer...")
        firePrompt(servePrompt)

        -- tunggu dialog muncul dan ada text
        updateStatus("Waiting for Dialog...")
        local dlg, dialogText = waitForDialog(8)
        if not dlg then
            updateStatus("Dialog Not Found!")
            return
        end

        -- scan order dari dialog yang sedang visible
        updateStatus("Reading Order...")
        currentOrder = nil
        local order = scanCurrentOrder()
        if not order then
            updateStatus("Order Not Found!")
            return
        end

        -- skip semua halaman dialog sampai hilang
        updateStatus("Confirming Order...")
        skipDialog(6)

        -- ambil cup
        updateStatus("Getting Cup...")
        smartTeleportTo(CFrame.new(-11.643688201904297, 24.607194900512695, 8409.1103515625))
        task.wait(1)

        ReplicatedStorage
            :WaitForChild("NetworkContainer")
            :WaitForChild("RemoteEvents")
            :WaitForChild("Barista")
            :FireServer("Station", "CupRack")

        local choicePicker = playerGui:WaitForChild("Job", 5):WaitForChild("ChoicePicker", 5)
        task.wait(1)

        local menuId  = currentOrder and currentOrder.MenuId
        if not menuId or menuId == "" then updateStatus("Invalid Menu!") return end

        local cupGrid = choicePicker and choicePicker:WaitForChild("Grid", 5)
        local cupBtn  = nil

        if cupGrid then
            cupBtn = cupGrid:FindFirstChild(menuId)
            if not cupBtn then
                for _, btn in ipairs(cupGrid:GetChildren()) do
                    if btn.Name:lower() == menuId:lower() or btn.Name:find(menuId) then
                        cupBtn = btn break
                    end
                end
            end
        end

        if cupBtn then
            clickGuiButton(cupBtn)
        else
            updateStatus("Cup Not Found: " .. tostring(menuId))
            task.wait(2)
            return
        end
        task.wait(1)

        -- buat minuman
        updateStatus("Making: " .. currentOrder.MenuId)
        local drinkFn = DRINK_MAP[currentOrder.MenuId]
        if not drinkFn then updateStatus("Menu Not Supported: " .. currentOrder.MenuId) return end
        if not drinkFn() then updateStatus("Drink Preparation Failed!") return end

        -- kembali ke kasir
        updateStatus("Returning to Cashier...")
        smartTeleportTo(cashierCF)
        task.wait(1)

        if not (currentCustomer and currentCustomer.Parent) then
            updateStatus("Customer Disappeared!")
            return
        end

        -- tunggu customer balik ke kasir
        local serveStart   = os.clock()
        local servePrompt2 = nil

        updateStatus("Waiting Customer at Cashier...")
        while not servePrompt2 and os.clock() - serveStart < 30 do
            if not (currentCustomer and currentCustomer.Parent) then break end
            local hrp = currentCustomer:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - cashierCF.Position).Magnitude
                if dist <= 6 then
                    local p = hrp:FindFirstChild("BaristaServePrompt")
                    if p and p:IsA("ProximityPrompt") and p.Enabled then
                        servePrompt2 = p
                    end
                end
            end
            if not servePrompt2 then task.wait(0.2) end
        end

        if servePrompt2 then
            updateStatus("Serving Order...")
            firePrompt(servePrompt2)
            task.wait(0.5)
            ordersCompletedCount += 1
            pcall(function()
                ordersLabel.Label.Text  = "Orders Completed: " .. tostring(ordersCompletedCount)
                menuLabel.Label.Text    = "Menu: -"
                flavourLabel.Label.Text = "Flavour: -"
            end)
            updateStatus("Order Completed!")
        else
            updateStatus("Customer Timeout / Lost!")
        end
        task.wait(1)
    end

    -- TOGGLE
    BaristaTab:CreateToggle({
        Name         = "Auto Barista",
        CurrentValue = false,
        Flag         = "AutoBaristaToggle",
        Callback     = function(value)
            autoBarista = value

            if autoBarista then
                pcall(function() statusLabel.Label.Text = "Status: ● RUNNING" end)
                startTime = os.time()
                updateStatus("Starting Auto Barista...")
                Rayfield:Notify({ Title = ".projectsion", Content = "Auto Barista Started!", Duration = 3 })

                task.spawn(function()
                    while autoBarista do
                        local elapsed = os.time() - startTime
                        pcall(function()
                            elapsedLabel.Label.Text = string.format("Elapsed: %02d:%02d:%02d",
                                math.floor(elapsed / 3600),
                                math.floor((elapsed % 3600) / 60),
                                elapsed % 60)
                        end)
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
                        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                            or obj:IsA("Smoke") or obj:IsA("Fire") then
                            obj.Enabled = false
                        elseif obj:IsA("PostEffect") then
                            obj.Enabled = false
                        end
                    end
                end)

                updateStatus("Going to Barista Manager...")
                for i = 1, 5 do smartTeleportTo("NPC_BARISTA_MANAGER") task.wait(0.2) end
                task.wait(1)

                updateStatus("Starting Job Process...")
                local initStart = os.clock()
                while os.clock() - initStart < 1 do
                    firePrompt(workspace.Barista.NPC_BARISTA_MANAGER.Head.DialogPrompt)
                    task.wait(0.5)
                end

                -- tunggu dan skip dialog manager
                local mgrDlg = waitForDialog(5)
                if mgrDlg then skipDialog(5) end
                task.wait(0.5)

                task.spawn(function()
                    while autoBarista do
                        runAutoBarista()
                        task.wait(0.1)
                    end
                end)

            else
                pcall(function() statusLabel.Label.Text = "Status: ● STOPPED" end)
                updateStatus("Stopped")
                pcall(function()
                    menuLabel.Label.Text    = "Menu: -"
                    flavourLabel.Label.Text = "Flavour: -"
                end)

                pcall(function()
                    settings().Rendering.QualityLevel = originalQualityLevel
                    for obj, mat in pairs(originalMaterials) do
                        if obj and obj.Parent then
                            obj.Material = mat
                            if originalShadows[obj] ~= nil then obj.CastShadow = originalShadows[obj] end
                        end
                    end
                    table.clear(originalMaterials)
                    table.clear(originalShadows)
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                            or obj:IsA("Smoke") or obj:IsA("Fire") then
                            obj.Enabled = true
                        elseif obj:IsA("PostEffect") then
                            obj.Enabled = true
                        end
                    end
                end)

                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Health = 0 end
                        char:BreakJoints()
                    end
                end)
            end
        end,
    })
end

-- =========================================================
-- ENTRY
-- =========================================================
mainScreen()