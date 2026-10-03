-- JawaDeobfucate Instance _ 28852 | Executor Project Nigger lol v.1.
-- Syntax is Luau JIT (uses `continue`).
repeat
    task.wait()
until game:IsLoaded()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local localplayer = Players.LocalPlayer
local value
local function fn(arg1)
    if getconnections then
        for k, v in getconnections(arg1.Idled) do
            pcall(function()
                v:Disable()
            end)
            pcall(function()
                v:Disconnect()
            end)
        end
    end
    pcall(function()
        value:Disconnect()
    end)
    value = arg1.Idled:Connect(function()
        local virtualinputmanager = Instance.new("VirtualInputManager")
        virtualinputmanager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        virtualinputmanager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        virtualinputmanager:Destroy()
    end)
end
local function fn2()
    if value then
        value:Disconnect()
        value = nil
    end
end
fn(localplayer)
local trafficfolder = Workspace:WaitForChild("TrafficFolder", 15)
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local updatespeedbridge = ReplicatedStorage:FindFirstChild("UpdateSpeedBridge")
local spawncarevent = remotes:FindFirstChild("SpawnCarEvent")
local num = 70000
pcall(function()
    local module = require(ReplicatedStorage:WaitForChild("Controllers", 10):WaitForChild("PoliceBustedController", 10):WaitForChild("PoliceConfig", 10))
    if module and tonumber(module.MaxCashPerRun) then
        num = tonumber(module.MaxCashPerRun)
    end
end)
local list = {}
local function fn3(arg1)
    if not arg1 or list[arg1] then
        return
    end
    list[arg1] = true
    pcall(function()
        for i, v in ipairs(arg1:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
                v.CanTouch = false
                v.CastShadow = false
                continue
            end
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            else
                if not v:IsA("Light") then
                    continue
                end
                v.Enabled = false
            end
        end
    end)
end
local function fn4(arg1)
    list[arg1] = nil
end
if trafficfolder then
    trafficfolder.ChildAdded:Connect(function(arg1)
        task.defer(function()
            fn3(arg1)
        end)
    end)
    trafficfolder.ChildRemoved:Connect(fn4)
    for i, v in ipairs(trafficfolder:GetChildren()) do
        fn3(v)
    end
end
local list2 = {}
local function fn5(arg1)
    if arg1 and arg1:IsA("Model") then
        if CollectionService:HasTag(arg1, "PoliceAI") or arg1:GetAttribute("IsPoliceAI") or arg1.Name:lower():find("police") then
            list2[arg1] = true
            fn3(arg1)
        end
    end
end
CollectionService:GetInstanceAddedSignal("PoliceAI"):Connect(fn5)
CollectionService:GetInstanceRemovedSignal("PoliceAI"):Connect(function(arg1)
    list2[arg1] = nil
    fn4(arg1)
end)
Workspace.ChildAdded:Connect(function(arg1)
    task.defer(function()
        fn5(arg1)
        if arg1.Name == "PoliceHelicopters" then
            arg1.ChildAdded:Connect(function(arg1_2)
                task.defer(function()
                    fn3(arg1_2)
                end)
            end)
            for i2, v2 in ipairs(arg1:GetChildren()) do
                fn3(v2)
            end
        end
    end)
end)
Workspace.ChildRemoved:Connect(function(arg1)
    list2[arg1] = nil
    fn4(arg1)
end)
for i2, v2 in ipairs(CollectionService:GetTagged("PoliceAI")) do
    fn5(v2)
end
for i3, v3 in ipairs(Workspace:GetChildren()) do
    fn5(v3)
end
local policehelicopters = Workspace:FindFirstChild("PoliceHelicopters")
if policehelicopters then
    policehelicopters.ChildAdded:Connect(function(arg1)
        task.defer(function()
            fn3(arg1)
        end)
    end)
    for i4, v4 in ipairs(policehelicopters:GetChildren()) do
        fn3(v4)
    end
end
local function fn6()
    pcall(function()
        localplayer:SetAttribute("MobilePerfMode", false)
        localplayer:SetAttribute("LowGraphicsMode", true)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9000000000
        for i5, v5 in ipairs(Lighting:GetChildren()) do
            if not (v5:IsA("DepthOfFieldEffect") or v5:IsA("SunRaysEffect") or v5:IsA("BloomEffect")) then
                continue
            end
            v5.Enabled = false
        end
        if settings and settings().Rendering then
            settings().Rendering.QualityLevel = 1
        end
        local UserGameSettings = UserSettings():GetService("UserGameSettings")
        if UserGameSettings then
            UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end
    end)
end
local inputheartbeat
pcall(function()
    local remotes2 = ReplicatedStorage:FindFirstChild("AC6Shared") and ReplicatedStorage.AC6Shared:FindFirstChild("Remotes")
    inputheartbeat = remotes2 and remotes2:FindFirstChild("InputHeartbeat")
end)
local inputheartbeat2
pcall(function()
    local module = require(ReplicatedStorage.Packages.Remotes)
    inputheartbeat2 = module and module.InputHeartbeat
end)
local module
pcall(function()
    module = require(ReplicatedStorage.Controllers.InputHeartbeatController)
end)
local function fn7()
    pcall(function()
        if inputheartbeat then
            inputheartbeat:FireServer()
        end
        if inputheartbeat2 then
            inputheartbeat2:FireServer()
        end
        if module then
            module.pending = true
        end
    end)
end
pcall(function()
    localplayer.Idled:Connect(fn7)
end)
task.spawn(function()
    while true do
        task.wait(3.5)
        fn7()
    end
end)
local chunk = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local window = chunk:CreateWindow({
    Title = "Ghost Driver",
    Icon = "car",
    Author = "DX-SR HUB",
    Folder = "GhostDriver",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.V,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false,
})
window:Tag({Title = "v0.0.0.5", Icon = "github", Color = Color3.fromHex("#30ff6a"), Radius = 13})
window:Tag({Title = "DX-SR", Icon = "code", Color = Color3.fromHex("#1E3A8A"), Radius = 13})
local function fn8(arg1, arg2, arg3)
    if not arg1 then
        return
    end
    pcall(function()
        if arg1.SetDesc then
            arg1:SetDesc(arg2)
            if arg3 and arg1.SetTitle then
                arg1:SetTitle(arg3)
            end
        elseif arg1.Set then
            local config = {Desc = arg2}
            if arg3 then
                config.Title = arg3
            end
            arg1:Set(config)
        end
    end)
end
local function fn9(arg1)
    if not arg1 or arg1 ~= arg1 then
        return "0"
    end
    local reverse = tostring(math.floor(arg1)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if reverse:sub(1, 1) == "," then
        reverse = reverse:sub(2)
    end
    return reverse
end
local config = {
    AutoFarm = false,
    Speed = 110,
    SelectedCar = "Weinchen V20",
    SelectedMode = "Normal",
    PoliceStars = 3,
    ZeroLag = true,
    TotalOvertakes = 0,
    StartCash = 0,
    LaneWidth = 13.5,
    LookAheadDist = 220,
    WeaveLerpSpeed = 8.5,
}
pcall(function()
    local leaderstats = localplayer:WaitForChild("leaderstats", 5)
    if leaderstats and leaderstats:FindFirstChild("Cash") then
        config.StartCash = leaderstats.Cash.Value
    end
end)
pcall(function()
    local swerveuibridge = ReplicatedStorage:FindFirstChild("SwerveUIBridge")
    if swerveuibridge then
        swerveuibridge.Event:Connect(function()
            config.TotalOvertakes = config.TotalOvertakes + 1
        end)
    end
end)
local function fn10()
    local character = localplayer.Character
    if not character then
        return nil, nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not humanoid.SeatPart or not humanoid.SeatPart:IsA("VehicleSeat") then
        return nil, nil
    end
    local seatpart = humanoid.SeatPart
    local model = seatpart:FindFirstAncestorOfClass("Model")
    if model and model.Name == "Body" then
        model = model.Parent
    end
    return model, seatpart
end
local function fn11()
    local list3 = {}
    local flag = false
    pcall(function()
        local requestgaragedata = remotes:FindFirstChild("RequestGarageData")
        if requestgaragedata and requestgaragedata:IsA("RemoteFunction") then
            local invokeserver = requestgaragedata:InvokeServer()
            if type(invokeserver) == "table" then
                for k, v5 in pairs(invokeserver) do
                    table.insert(list3, tostring(k))
                end
                if #list3 > 0 then
                    flag = true
                end
            end
        end
    end)
    if not flag and #list3 == 0 then
        list3 = {"Weinchen V20", "Wulfbrecht RZ7", "Kitsuni LX", "Sorg Varkis", "StarterCar"}
    else
        table.sort(list3)
    end
    return list3, flag
end
local function fn12()
    local waypoints
    local getmapcachefunc = ReplicatedStorage:FindFirstChild("GetMapCacheFunc", true)
    if getmapcachefunc and getmapcachefunc:IsA("RemoteFunction") then
        local invokeserver = getmapcachefunc:InvokeServer()
        if invokeserver and type(invokeserver) == "table" then
            if invokeserver.Lane2 and invokeserver.Lane2.Waypoints then
                waypoints = invokeserver.Lane2.Waypoints
            else
                for k, v5 in pairs(invokeserver) do
                    if v5.Waypoints and #v5.Waypoints > 50 then
                        waypoints = v5.Waypoints
                        break
                    end
                end
            end
        end
    end
    if not waypoints and getgc then
        local huge = math.huge
        for i5, v6 in ipairs(getgc(true)) do
            if not (type(v6) == "table" and type(rawget(v6, "Waypoints")) == "table" and rawget(v6, "TotalLength")) then
                continue
            end
            local num2 = math.abs(v6.TotalLength - 95465)
            if not (num2 < huge) then
                continue
            end
            huge = num2
            waypoints = v6.Waypoints
        end
    end
    if not waypoints then
        return nil
    end
    local cond = #waypoints == 412 and 411 or #waypoints
    local list3 = {}
    for i6 = 1, cond do
        local entry = waypoints[i6]
        local entry2 = waypoints[i6 % cond + 1]
        local magnitude = (entry2 - entry).Magnitude
        table.insert(list3, entry)
        if not (magnitude > 350) then
            continue
        end
        local num3 = math.floor(magnitude / 220)
        for i7 = 1, num3 do
            table.insert(list3, entry:Lerp(entry2, i7 / (num3 + 1)))
        end
    end
    return list3
end
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
local lastValue
local lastValue2
local function fn13(arg1, arg2)
    local character = localplayer.Character
    if arg2 ~= lastValue or character ~= lastValue2 then
        lastValue = arg2
        lastValue2 = character
        raycastParams.FilterDescendantsInstances = {arg2, character}
    end
    local raycast = Workspace:Raycast(arg1 + Vector3.new(0, 15, 0), Vector3.new(0, -35, 0), raycastParams)
    if raycast and not raycast.Instance.Name:lower():find("fence") and not raycast.Instance.Name:lower():find("wall") and not raycast.Instance.Name:lower():find("shield") then
        return raycast.Position.Y + 1.15
    end
    return arg1.Y
end
local function fn14(arg1, arg2, arg3)
    local result = arg3 - arg2
    local dot = result:Dot(result)
    if dot < 0.0001 then
        return arg2, 0
    end
    local num2 = math.clamp((arg1 - arg2):Dot(result) / dot, 0, 1)
    return arg2 + result * num2, num2
end
local function fn15(arg1, arg2)
    local position = arg2.Position
    if position.Y < 80 and (position.X < -3800 or position.Z < -850) then
        return true
    end
    local list3 = {
        position,
        Vector3.new(-3541.03, 138, -150),
        Vector3.new(-3541.03, 120, -500),
        Vector3.new(-3541.03, 90, -1000),
        Vector3.new(-3541.03, 63.5, -1490),
        Vector3.new(-3499.6, 63.3, -1580),
    }
    local num2 = 135
    for i5 = 1, #list3 - 1 do
        local entry = list3[i5]
        local entry2 = list3[i5 + 1]
        local magnitude = (entry2 - entry).Magnitude
        local result = magnitude / num2
        local clock = os.clock()
        local unit = (entry2 - entry).Unit
        while os.clock() - clock < result do
            if not config.AutoFarm then
                return false
            end
            local num3 = math.clamp((os.clock() - clock) / result, 0, 1)
            local lerp = entry:Lerp(entry2, num3)
            local result2 = fn13(lerp, arg1)
            local vector3 = Vector3.new(lerp.X, result2, lerp.Z)
            local lookat = CFrame.lookAt(vector3, vector3 + unit)
            arg1:PivotTo(lookat)
            arg2.AssemblyLinearVelocity = unit * num2
            task.wait(0.02)
        end
    end
    task.wait(0.2)
    return true
end
local list3 = {
    Vector3.new(-3498, 63.3, 1600),
    Vector3.new(-3520, 63.3, 1500),
    Vector3.new(-3541, 63.3, 1350),
    Vector3.new(-3541, 70, 1150),
    Vector3.new(-3541, 95, 900),
    Vector3.new(-3541, 120, 650),
    Vector3.new(-3541, 137.5, 400),
    Vector3.new(-3541, 138, 100),
    Vector3.new(-3541, 138, -150),
}
local function fn16(arg1, arg2)
    local num2 = 135
    for i5 = 1, #list3 - 1 do
        local entry = list3[i5]
        local entry2 = list3[i5 + 1]
        local magnitude = (entry2 - entry).Magnitude
        local result = magnitude / num2
        local clock = os.clock()
        local unit = (entry2 - entry).Unit
        while os.clock() - clock < result do
            if not config.AutoFarm then
                return false
            end
            local num3 = math.clamp((os.clock() - clock) / result, 0, 1)
            local lerp = entry:Lerp(entry2, num3)
            local result2 = fn13(lerp, arg1)
            local vector3 = Vector3.new(lerp.X, result2, lerp.Z)
            local lookat = CFrame.lookAt(vector3, vector3 + unit)
            arg1:PivotTo(lookat)
            arg2.AssemblyLinearVelocity = unit * num2
            task.wait(0.02)
        end
    end
    return true
end
local function fn17()
    local ingamehud = localplayer.PlayerGui:FindFirstChild("InGameHUD")
    local comboui = ingamehud and ingamehud:FindFirstChild("ComboUI")
    local streak = comboui and comboui:FindFirstChild("Streak")
    if not streak or not streak.Visible then
        return false
    end
    local message = streak:FindFirstChild("Message")
    if message and (message.Text:find("0X") or message.Text:find("LOST") or message.Text:find("CRASHED")) then
        return false
    end
    return true
end
local function fn18(arg1, arg2)
    local cond = tonumber(localplayer:GetAttribute("Wanted")) or 0
    if cond > 0 then
        return true
    end
    local policepad = Workspace:FindFirstChild("PoliceSystem") and Workspace.PoliceSystem:FindFirstChild("PolicePad")
    local position = policepad and policepad.Position or Vector3.new(-3639.55, 137.83, -188.56)
    local list4 = {arg2.Position, Vector3.new(-3639.55, 138, -188.56)}
    local num2 = 80
    for i5 = 1, #list4 - 1 do
        local entry = list4[i5]
        local entry2 = list4[i5 + 1]
        local magnitude = (entry2 - entry).Magnitude
        if magnitude < 5 then
            continue
        end
        local result = magnitude / num2
        local clock = os.clock()
        local unit = (entry2 - entry).Unit
        while os.clock() - clock < result do
            if not config.AutoFarm then
                return false
            end
            local num3 = math.clamp((os.clock() - clock) / result, 0, 1)
            local lerp = entry:Lerp(entry2, num3)
            local result2 = fn13(lerp, arg1)
            local vector3 = Vector3.new(lerp.X, result2, lerp.Z)
            arg1:PivotTo(CFrame.lookAt(vector3, vector3 + unit))
            arg2.AssemblyLinearVelocity = unit * num2
            task.wait(0.02)
        end
    end
    arg1:PivotTo(CFrame.new(position + Vector3.new(0, 2, 0)))
    arg2.AssemblyLinearVelocity = Vector3.zero
    task.wait(1)
    local copchasedifficulty
    pcall(function()
        copchasedifficulty = localplayer.PlayerGui:FindFirstChild("CopChaseDifficulty")
        if not copchasedifficulty then
            copchasedifficulty = localplayer.PlayerGui:FindFirstChild("MainGameMenu")
            copchasedifficulty = copchasedifficulty and copchasedifficulty:FindFirstChild("CopChaseDifficulty")
        end
    end)
    local clock2 = os.clock()
    while os.clock() - clock2 < 8 do
        if not config.AutoFarm then
            return false
        end
        arg2.AssemblyLinearVelocity = Vector3.zero
        arg1:PivotTo(CFrame.new(position + Vector3.new(0, 2, 0)))
        local flag = false
        pcall(function()
            local copchasedifficulty2 = localplayer.PlayerGui:FindFirstChild("CopChaseDifficulty")
            if copchasedifficulty2 then
                for i6, v5 in ipairs(copchasedifficulty2:GetChildren()) do
                    if v5:IsA("Frame") and v5.Visible then
                        flag = true
                        break
                    end
                end
                if not flag and copchasedifficulty2:IsA("ScreenGui") and copchasedifficulty2.Enabled then
                    flag = true
                end
            end
            if not flag then
                local maingamemenu = localplayer.PlayerGui:FindFirstChild("MainGameMenu")
                local copchasedifficulty3 = maingamemenu and maingamemenu:FindFirstChild("CopChaseDifficulty")
                if copchasedifficulty3 and copchasedifficulty3.Visible then
                    flag = true
                end
            end
        end)
        if flag then
            break
        end
        task.wait(0.25)
    end
    task.wait(0.3)
    pcall(function()
        local policedifficultycontroll = ReplicatedStorage:FindFirstChild("Controllers") and ReplicatedStorage.Controllers:FindFirstChild("PoliceDifficultyController")
        if policedifficultycontroll then
            local module2 = require(policedifficultycontroll)
            if module2 then
                module2.selected = tonumber(config.PoliceStars) or 5
                pcall(function()
                    module2:Paint()
                end)
            end
        end
    end)
    pcall(function()
        local copchasedifficulty2 = localplayer.PlayerGui:FindFirstChild("CopChaseDifficulty")
        local copchasedifficulty3 = copchasedifficulty2 and (copchasedifficulty2:FindFirstChild("CopChaseDifficulty") or copchasedifficulty2)
        if copchasedifficulty3 then
            local findfirstchild = copchasedifficulty3:FindFirstChild("Star" .. tostring(config.PoliceStars))
            if findfirstchild and findfirstchild:IsA("GuiButton") then
                firesignal(findfirstchild.Activated)
            end
            local buy = copchasedifficulty3:FindFirstChild("Buy")
            if buy and buy:IsA("GuiButton") then
                firesignal(buy.Activated)
            end
        end
    end)
    pcall(function()
        local policeremotes = ReplicatedStorage:FindFirstChild("Controllers") and ReplicatedStorage.Controllers:FindFirstChild("PoliceRemotes")
        if policeremotes then
            local module2 = require(policeremotes)
            if module2 and module2.PoliceDifficultyPick then
                local v5 = module2.PoliceDifficultyPick
                local v6 = tonumber(config.PoliceStars) or 5
                v5:FireServer(v6)
            end
        end
    end)
    pcall(function()
        local policedifficultycontroll = ReplicatedStorage:FindFirstChild("Controllers") and ReplicatedStorage.Controllers:FindFirstChild("PoliceDifficultyController")
        if policedifficultycontroll then
            local module2 = require(policedifficultycontroll)
            if module2 and module2.Hide then
                module2:Hide()
            end
        end
    end)
    local clock3 = os.clock()
    while os.clock() - clock3 < 10 do
        if not config.AutoFarm then
            return false
        end
        local cond2 = tonumber(localplayer:GetAttribute("Wanted")) or 0
        if cond2 > 0 then
            task.wait(0.5)
            return true
        end
        task.wait(0.25)
    end
    return false
end
local section = window:Section({Title = "Main", Icon = "home", Opened = true})
local tab = section:Tab({Title = "Farming", Icon = "sparkles"})
local section2 = tab:Section({Title = "Auto Farming", Opened = true})
pcall(function()
    tab:Space()
end)
local toggle = tab:Toggle({
    Title = "Start Farming",
    Default = false,
    Callback = function(arg1)
        config.AutoFarm = arg1
        if arg1 and config.ZeroLag then
            fn6()
        end
    end,
})
tab:Toggle({
    Title = "Zero Lag Mode",
    Default = true,
    Callback = function(arg1)
        config.ZeroLag = arg1
        if arg1 then
            fn6()
        end
    end,
})
task.defer(function()
    if config.ZeroLag then
        fn6()
    end
end)
tab:Slider({
    Title = "Speed (MPH)",
    Step = 5,
    Value = {Min = 60, Max = 250, Default = 110},
    Callback = function(arg1)
        config.Speed = arg1
    end,
})
local dropdown = tab:Dropdown({
    Title = "Select Car",
    Multi = false,
    Value = config.SelectedCar,
    Values = fn11(),
    Callback = function(arg1)
        config.SelectedCar = arg1
    end,
})
local result = fn11()
local function fn19(arg1, arg2)
    if not arg1 or not arg2 or #arg1 ~= #arg2 then
        return false
    end
    for i5 = 1, #arg1 do
        if arg1[i5] ~= arg2[i5] then
            return false
        end
    end
    return true
end
local function fn20()
    local result2, v5 = fn11()
    if v5 and #result2 > 0 and not fn19(result, result2) then
        result = result2
        pcall(function()
            if dropdown and dropdown.Refresh then
                dropdown:Refresh(result2)
                if table.find(result2, config.SelectedCar) then
                    dropdown:Select(config.SelectedCar)
                else
                    config.SelectedCar = result2[1]
                    dropdown:Select(result2[1])
                end
            end
        end)
    end
end
task.defer(fn20)
pcall(function()
    local addcar = remotes:FindFirstChild("AddCar")
    if addcar and addcar:IsA("RemoteEvent") then
        addcar.OnClientEvent:Connect(function()
            task.wait(0.5)
            fn20()
        end)
    end
    local removecar = remotes:FindFirstChild("RemoveCar")
    if removecar and removecar:IsA("RemoteEvent") then
        removecar.OnClientEvent:Connect(function()
            task.wait(0.5)
            fn20()
        end)
    end
end)
task.spawn(function()
    while true do
        task.wait(4)
        pcall(fn20)
    end
end)
tab:Dropdown({
    Title = "Select Mode",
    Multi = false,
    Value = config.SelectedMode,
    Values = {"Normal", "Police Chase"},
    Callback = function(arg1)
        config.SelectedMode = arg1
    end,
})
tab:Dropdown({
    Title = "Police Stars",
    Multi = false,
    Value = tostring(config.PoliceStars),
    Values = {"1", "2", "3", "4", "5"},
    Callback = function(arg1)
        config.PoliceStars = tonumber(arg1) or 3
    end,
})
local section3 = tab:Section({Title = "Information", Opened = true})
pcall(function()
    tab:Space()
end)
local paragraph = tab:Paragraph({Title = "Total Earning", Desc = "$0"})
local paragraph2 = tab:Paragraph({Title = "Total Point", Desc = "0 PTS"})
local paragraph3 = tab:Paragraph({Title = "Current Rank", Desc = "-"})
local paragraph4 = tab:Paragraph({Title = "Current Level", Desc = "0"})
local paragraph5 = tab:Paragraph({Title = "Current XP", Desc = "0 / 0"})
local paragraph6 = tab:Paragraph({Title = "Total Overtake", Desc = "0"})
local tab2 = window:Tab({Title = "Configuration", Icon = "settings"})
local section4 = tab2:Section({Title = "Theme"})
pcall(function()
    tab2:Space()
end)
local list4 = {}
pcall(function()
    local themes = chunk:GetThemes()
    if themes then
        for k, v5 in pairs(themes) do
            if type(v5) == "string" then
                table.insert(list4, v5)
            else
                if type(k) ~= "string" then
                    continue
                end
                table.insert(list4, k)
            end
        end
    end
end)
if #list4 == 0 then
    list4 = {
        "Dark",
        "Light",
        "Rose",
        "Plant",
        "Red",
        "Indigo",
        "Sky",
        "Violet",
        "Amber",
        "Emerald",
        "Midnight",
        "Crimson",
        "Monokai Pro",
        "Cotton Candy",
        "Mellowsi",
        "Rainbow",
    }
end
local v5 = {
    Title = "Select Theme",
    Multi = false,
    Value = chunk:GetCurrentTheme() or "Dark",
    Values = list4,
    Callback = function(arg1)
        pcall(function()
            chunk:SetTheme(arg1)
        end)
    end,
}
tab2:Dropdown(v5)
local section5 = tab2:Section({Title = "Config"})
pcall(function()
    tab2:Space()
end)
local text = ""
local text2 = ""
local function fn21()
    local list5 = {}
    pcall(function()
        local allconfigs = window.ConfigManager:AllConfigs()
        if allconfigs then
            for i5, v6 in ipairs(allconfigs) do
                table.insert(list5, v6)
            end
        end
    end)
    return list5
end
local dropdown2 = tab2:Dropdown({
    Title = "Select Config",
    Multi = false,
    Value = "",
    Values = fn21(),
    Callback = function(arg1)
        text = arg1
    end,
})
tab2:Input({
    Title = "Config Name",
    PlaceholderText = "Enter config name...",
    Callback = function(arg1)
        text2 = arg1
    end,
})
tab2:Button({
    Title = "Save Config",
    Callback = function()
        if text2 == "" then
            chunk:Notify({Title = "Config", Content = "Enter config name first!", Duration = 3})
            return
        end
        pcall(function()
            text = text2
            pcall(function()
                dropdown2:Select(text2)
            end)
            local config2 = window.ConfigManager:CreateConfig(text2)
            config2:Save()
        end)
        chunk:Notify({Title = "Config", Content = "Config '" .. text2 .. "' saved successfully!", Duration = 3})
        pcall(function()
            dropdown2:Refresh(fn21())
            dropdown2:Select(text2)
        end)
    end,
})
tab2:Button({
    Title = "Load Config",
    Callback = function()
        if text == "" or text == "--" then
            chunk:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local config2 = window.ConfigManager:CreateConfig(text)
            config2:Load()
            pcall(function()
                dropdown2:Select(text)
            end)
        end)
        chunk:Notify({Title = "Config", Content = "Config '" .. text .. "' loaded successfully!", Duration = 3})
    end,
})
tab2:Button({
    Title = "Rewrite Config",
    Callback = function()
        if text == "" or text == "--" then
            chunk:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        local v6 = window.Folder or "GhostDriver"
        local text3 = "WindUI/" .. v6 .. "/config/" .. text .. ".json"
        local flag = false
        local list5 = {}
        if isfile and isfile(text3) and readfile then
            pcall(function()
                local jsondecode = HttpService:JSONDecode(readfile(text3))
                if type(jsondecode) == "table" then
                    flag = jsondecode.__autoload or false
                    list5 = jsondecode.__custom or {}
                end
            end)
        end
        local ok, v7 = pcall(function()
            pcall(function()
                dropdown2:Select(text)
            end)
            local list6 = {}
            local parser = window.ConfigManager.Parser
            local pendingflags = window.PendingFlags or window.Flags or {}
            for k, v8 in pairs(pendingflags) do
                if not (v8 and v8.__type and parser and parser[v8.__type]) then
                    continue
                end
                pcall(function()
                    list6[tostring(k)] = parser[v8.__type].Save(v8)
                end)
            end
            local config2 = {__version = 1.2, __elements = list6, __autoload = flag, __custom = list5}
            if writefile then
                writefile(text3, HttpService:JSONEncode(config2))
            end
            if window.ConfigManager and window.ConfigManager.Configs and window.ConfigManager.Configs[text] then
                local entry = window.ConfigManager.Configs[text]
                entry.AutoLoad = flag
                entry.CustomData = list5
                if pendingflags then
                    for k2, v9 in pairs(pendingflags) do
                        entry:Register(k2, v9)
                    end
                end
            end
        end)
        if ok then
            chunk:Notify({
                Title = "Config",
                Content = "Config '" .. text .. "' rewritten successfully!",
                Duration = 3,
            })
        else
            chunk:Notify({
                Title = "Config",
                Content = "Failed to rewrite config: " .. tostring(v7),
                Duration = 3,
            })
        end
    end,
})
tab2:Button({
    Title = "Delete Config",
    Callback = function()
        if text == "" or text == "--" then
            chunk:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local config2 = window.ConfigManager:CreateConfig(text)
            config2:Delete()
        end)
        chunk:Notify({Title = "Config", Content = "Config '" .. text .. "' deleted successfully!", Duration = 3})
        text = ""
        pcall(function()
            dropdown2:Refresh(fn21())
            dropdown2:Select("")
        end)
    end,
})
tab2:Button({
    Title = "Set Auto Load",
    Callback = function()
        if text == "" or text == "--" then
            chunk:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local allconfigs = window.ConfigManager:AllConfigs()
            if allconfigs and isfile and readfile and writefile then
                local folder
                for i5, v6 in ipairs(allconfigs) do
                    folder = window.Folder or "GhostDriver"
                    local text3 = "WindUI/" .. folder .. "/config/" .. v6 .. ".json"
                    if not isfile(text3) then
                        continue
                    end
                    pcall(function()
                        local jsondecode = HttpService:JSONDecode(readfile(text3))
                        if type(jsondecode) == "table" then
                            jsondecode.__autoload = v6 == text
                            writefile(text3, HttpService:JSONEncode(jsondecode))
                        end
                    end)
                end
            end
            pcall(function()
                dropdown2:Select(text)
            end)
            if window.ConfigManager and window.ConfigManager.Configs then
                for k, v7 in pairs(window.ConfigManager.Configs) do
                    if not (v7 and v7.SetAutoLoad) then
                        continue
                    end
                    v7:SetAutoLoad(k == text)
                end
            end
        end)
        chunk:Notify({Title = "Config", Content = "Auto load set to '" .. text .. "'!", Duration = 3})
    end,
})
pcall(function()
    local allconfigs = window.ConfigManager:AllConfigs()
    if allconfigs and readfile and isfile then
        local folder
        for k, v6 in pairs(allconfigs) do
            folder = window.Folder or "GhostDriver"
            local text3 = "WindUI/" .. folder .. "/config/" .. v6 .. ".json"
            if not isfile(text3) then
                continue
            end
            local ok, v7 = pcall(function()
                return HttpService:JSONDecode(readfile(text3))
            end)
            if ok and type(v7) == "table" and v7.__autoload then
                local config2 = window.ConfigManager:CreateConfig(v6)
                config2:Load()
                text = v6
                task.defer(function()
                    pcall(function()
                        dropdown2:Select(v6)
                    end)
                end)
                break
            end
        end
    end
end)
window:EditOpenButton({
    Title = "Open UI",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            local leaderstats = localplayer:FindFirstChild("leaderstats")
            local cond = leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value or 0
            local cond2 = leaderstats and leaderstats:FindFirstChild("Rank") and leaderstats.Rank.Value or "-"
            local cond3 = leaderstats and leaderstats:FindFirstChild("Level") and leaderstats.Level.Value or 0
            local cond4 = localplayer:FindFirstChild("XP") and localplayer.XP.Value or 0
            local cond5 = localplayer:FindFirstChild("MaxXP") and localplayer.MaxXP.Value or 0
            local attribute = localplayer:GetAttribute("TrafficRunPoints") or 0
            local attribute2 = localplayer:GetAttribute("DrivingCombo") or 0
            local attribute3 = localplayer:GetAttribute("PoliceChaseCash") or 0
            local num2 = math.max(0, cond - config.StartCash)
            if config.SelectedMode == "Police Chase" and attribute3 > 0 then
                fn8(paragraph, "+$" .. fn9(num2) .. " (Chase: $" .. fn9(attribute3) .. ")")
            else
                fn8(paragraph, "+$" .. fn9(num2) .. " (Total: $" .. fn9(cond) .. ")")
            end
            fn8(paragraph2, fn9(attribute) .. " PTS (" .. tostring(attribute2) .. "X Combo)")
            fn8(paragraph3, tostring(cond2))
            fn8(paragraph4, "Level " .. tostring(cond3))
            fn8(paragraph5, fn9(cond4) .. " / " .. fn9(cond5))
            fn8(paragraph6, tostring(attribute2))
        end)
    end
end)
task.spawn(function()
    local result2 = fn12()
    local num2 = 0
    while true do
        if not result2 and num2 < 25 then
            task.wait(0.5)
            result2 = fn12()
            num2 = num2 + 1
        else
            break
        end
    end
    if not result2 then
        return
    end
    local function fn22(arg1)
        local num3 = 1
        local huge = math.huge
        for i5 = 1, #result2 do
            local entry = result2[i5]
            local entry2 = result2[i5 % #result2 + 1]
            local result3 = fn14(arg1, entry, entry2)
            local magnitude = (arg1 - result3).Magnitude
            if not (magnitude < huge) then
                continue
            end
            huge = magnitude
            num3 = i5
        end
        return num3
    end
    local function fn23(arg1)
        local lastValue3
        local huge = math.huge
        for k in pairs(list2) do
            if k.Parent then
                local primarypart = k.PrimaryPart or k:FindFirstChild("CollisionShell") or k:FindFirstChild("DriveSeat")
                if not primarypart then
                    continue
                end
                local magnitude = (primarypart.Position - arg1).Magnitude
                if not (magnitude < huge) then
                    continue
                end
                huge = magnitude
                lastValue3 = k
            else
                list2[k] = nil
                fn4(k)
            end
        end
        return lastValue3, huge
    end
    local function fn24(arg1)
        local aChassisTune = arg1 and arg1:FindFirstChild("A-Chassis Tune")
        aChassisTune = aChassisTune and aChassisTune:FindFirstChild("A-Chassis Interface")
        return aChassisTune and aChassisTune:FindFirstChild("Values")
    end
    local function fn25()
        pcall(function()
            local policebustedui = localplayer.PlayerGui:FindFirstChild("PoliceBustedUI")
            if policebustedui and policebustedui.Enabled then
                local skip = policebustedui:FindFirstChild("Skip", true)
                if skip and skip:IsA("GuiButton") and skip.Visible then
                    firesignal(skip.Activated)
                end
                local close = policebustedui:FindFirstChild("Close", true)
                if close and close:IsA("GuiButton") and close.Visible then
                    firesignal(close.Activated)
                end
            end
        end)
    end
    local num3 = 1
    local num4 = 0
    local num5 = 0
    local num6 = 0
    local idle = "IDLE"
    local num7 = 0
    local num8 = 0
    local num9 = 0
    local num10 = 1
    while true do
        if not config.AutoFarm then
            task.wait(0.4)
            continue
        end
        local result3, v6 = fn10()
        if not result3 or not v6 then
            if spawncarevent then
                spawncarevent:FireServer(config.SelectedCar)
                task.wait(2)
                result3, v6 = fn10()
            end
            if not result3 or not v6 then
                task.wait(0.5)
                continue
            end
        end
        if v6.Position.Y > 80 and v6.Position.X > -3800 then
            while fn17() do
                if not config.AutoFarm then
                    break
                end
                v6.AssemblyLinearVelocity = Vector3.zero
                num6 = 0
                task.wait(0.5)
            end
            if config.SelectedMode == "Police Chase" then
                local result4 = fn18(result3, v6)
                if not result4 then
                    task.wait(0.5)
                    continue
                end
                task.wait(1)
                result3, v6 = fn10()
                if not result3 or not v6 then
                    task.wait(0.5)
                    continue
                end
                idle = "WAITING_POLICE"
                num7 = os.clock()
                num8 = 0
                num9 = os.clock()
                num6 = 0
            end
            local result5 = fn15(result3, v6)
            if not result5 then
                task.wait(0.5)
                continue
            end
            num3 = fn22(v6.Position)
        end
        if config.SelectedMode == "Police Chase" then
            local attribute = localplayer:GetAttribute("PoliceStatus")
            local cond = tonumber(localplayer:GetAttribute("Wanted")) or 0
            if attribute ~= "CHASE" and cond == 0 and v6.Position.Y < 80 then
                idle = "IDLE"
                num6 = 0
                v6.AssemblyLinearVelocity = Vector3.zero
                fn25()
                local attribute2 = localplayer:GetAttribute("PoliceBustedScreenActive")
                if attribute2 then
                    local clock = os.clock()
                    while true do
                        if not (localplayer:GetAttribute("PoliceBustedScreenActive") and os.clock() - clock < 6) then
                            break
                        end
                        if not config.AutoFarm then
                            break
                        end
                        fn25()
                        task.wait(0.5)
                    end
                    task.wait(1.5)
                end
                while fn17() do
                    if not config.AutoFarm then
                        break
                    end
                    v6.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.5)
                end
                fn16(result3, v6)
                task.wait(1)
                continue
            end
        end
        local position = v6.Position
        if not (config.SelectedMode ~= "Police Chase" and num3 > 500 and position.Z <= 1650 and position.Z >= 1350 and position.X > -3530 and position.X < -3470) then
            local speed = config.Speed
            local v7
            local huge = math.huge
            if config.SelectedMode == "Police Chase" then
                if config.ZeroLag then
                    fn6()
                end
                v7, huge = fn23(v6.Position)
                if idle == "WAITING_POLICE" then
                    speed = 18
                    local cond2 = tonumber(localplayer:GetAttribute("Busted")) or 0
                    if cond2 > 0.01 or huge < 85 or os.clock() - num7 > 8 then
                        idle = "CHASING"
                    end
                elseif idle == "CHASING" or idle == "ESCAPING" then
                    local cond3 = tonumber(localplayer:GetAttribute("PoliceChaseCash")) or 0
                    if cond3 > num8 then
                        num8 = cond3
                        num9 = os.clock()
                    end
                    local ok = cond3 >= num or cond3 >= 70000 or cond3 >= 4000 and os.clock() - num9 > 6
                    if idle == "ESCAPING" or ok or cond3 >= num or cond3 >= 70000 then
                        idle = "ESCAPING"
                        speed = 250
                    else
                        local cond4 = tonumber(localplayer:GetAttribute("Busted")) or 0
                        local cond5 = tonumber(localplayer:GetAttribute("PoliceEvadeProgress")) or 0
                        local num11 = math.clamp(config.Speed, 75, 105)
                        if cond5 > 0.03 then
                            if cond5 > 0.4 then
                                speed = 35
                            elseif cond5 > 0.2 then
                                speed = 50
                            elseif cond5 > 0.08 then
                                speed = 65
                            else
                                speed = 75
                            end
                        elseif cond4 > 0.03 then
                            if cond4 > 0.4 then
                                speed = 160
                            elseif cond4 > 0.2 then
                                speed = 135
                            elseif cond4 > 0.08 then
                                speed = 115
                            else
                                speed = 100
                            end
                        else
                            speed = num11
                            if huge < 45 then
                                speed = num11 + 12
                            elseif huge > 160 and huge < math.huge then
                                speed = num11 - 12
                            end
                        end
                    end
                end
            end
            local entry = result2[num3]
            local entry2 = result2[num3 % #result2 + 1]
            local result6, v8 = fn14(position, entry, entry2)
            if (position - result6).Magnitude > 45 then
                num3 = fn22(position)
                entry = result2[num3]
                entry2 = result2[num3 % #result2 + 1]
                result6, v8 = fn14(position, entry, entry2)
            end
            local result7 = entry2 - entry
            local magnitude = result7.Magnitude
            local unit = result7.Unit
            local unit2 = Vector3.new(-unit.Z, 0, unit.X).Unit
            local num12 = 0.02
            local num13 = 50
            local num14 = 80
            local result8 = fn24(result3)
            if num6 < speed then
                num6 = math.min(speed, num6 + num13 * num12)
                pcall(function()
                    v6.Throttle = 1
                    v6.ThrottleFloat = 1
                    if result8 and result8:FindFirstChild("Throttle") then
                        result8.Throttle.Value = 1
                    end
                    if result8 and result8:FindFirstChild("Brake") then
                        result8.Brake.Value = 0
                    end
                end)
            elseif num6 > speed then
                num6 = math.max(speed, num6 - num14 * num12)
                pcall(function()
                    v6.Throttle = 0
                    v6.ThrottleFloat = 0
                    if result8 and result8:FindFirstChild("Throttle") then
                        result8.Throttle.Value = 0
                    end
                    if result8 and result8:FindFirstChild("Brake") then
                        result8.Brake.Value = 0.4
                    end
                end)
            else
                pcall(function()
                    v6.Throttle = 0.7
                    v6.ThrottleFloat = 0.7
                    if result8 and result8:FindFirstChild("Throttle") then
                        result8.Throttle.Value = 0.7
                    end
                end)
            end
            local result9 = num6 * 1.76
            local result10 = v8 * magnitude
            local result11 = result10 + result9 * num12
            while true do
                if result11 >= magnitude and magnitude > 0.01 then
                    num3 = num3 % #result2 + 1
                    entry = result2[num3]
                    entry2 = result2[num3 % #result2 + 1]
                    result7 = entry2 - entry
                    result11 = result11 - magnitude
                    magnitude = result7.Magnitude
                    unit = result7.Unit
                    unit2 = Vector3.new(-unit.Z, 0, unit.X).Unit
                else
                    break
                end
            end
            local result12 = entry + unit * math.clamp(result11, 0, magnitude)
            if config.SelectedMode == "Police Chase" then
                local cond6 = tonumber(localplayer:GetAttribute("PoliceChaseCash")) or 0
                local ok2 = cond6 >= num or cond6 >= 70000 or cond6 >= 4000 and os.clock() - num9 > 6
                if idle == "ESCAPING" or ok2 or cond6 >= num or cond6 >= 70000 then
                    pcall(function()
                        for i5, v9 in ipairs(CollectionService:GetTagged("PoliceAI")) do
                            if not v9:IsA("Model") then
                                continue
                            end
                            v9:PivotTo(CFrame.new(v6.Position - unit * 3500))
                            local primarypart = v9.PrimaryPart or v9:FindFirstChild("CollisionShell") or v9:FindFirstChild("DriveSeat")
                            if not primarypart then
                                continue
                            end
                            primarypart.AssemblyLinearVelocity = Vector3.zero
                        end
                        for k in pairs(list2) do
                            if not (k.Parent and k:IsA("Model")) then
                                continue
                            end
                            k:PivotTo(CFrame.new(v6.Position - unit * 3500))
                            local primarypart2 = k.PrimaryPart or k:FindFirstChild("CollisionShell") or k:FindFirstChild("DriveSeat")
                            if not primarypart2 then
                                continue
                            end
                            primarypart2.AssemblyLinearVelocity = Vector3.zero
                        end
                    end)
                elseif idle == "CHASING" then
                    local v7_2 = v7
                    if v7_2 and v7_2:IsA("Model") and v7_2.Parent then
                        if not list[v7_2] then
                            fn3(v7_2)
                        end
                        pcall(function()
                            local result13 = v6.Position - unit * 45
                            local vector3 = Vector3.new(result13.X, v6.Position.Y, result13.Z)
                            v7_2:PivotTo(CFrame.lookAt(vector3, vector3 + unit))
                            local primarypart = v7_2.PrimaryPart or v7_2:FindFirstChild("CollisionShell") or v7_2:FindFirstChild("DriveSeat")
                            if primarypart and primarypart:IsA("BasePart") then
                                primarypart.AssemblyLinearVelocity = v6.AssemblyLinearVelocity
                            end
                        end)
                    end
                end
            end
            local huge2 = math.huge
            local huge3 = math.huge
            local huge4 = math.huge
            local flag = false
            local flag2 = false
            local flag3 = false
            if trafficfolder then
                for i5, v9 in ipairs(trafficfolder:GetChildren()) do
                    if not list[v9] then
                        fn3(v9)
                    end
                    local corehitbox = v9:FindFirstChild("CoreHitbox") or v9.PrimaryPart
                    if not corehitbox then
                        continue
                    end
                    local result13 = corehitbox.Position - position
                    local dot = result13:Dot(unit)
                    if not (dot > -30 and dot < config.LookAheadDist) then
                        continue
                    end
                    local dot2 = (corehitbox.Position - result12):Dot(unit2)
                    if dot2 < -6.5 then
                        if dot > 0 and dot < huge2 then
                            huge2 = dot
                        end
                        if not (dot >= -28 and dot <= 30) then
                            continue
                        end
                        flag = true
                        continue
                    end
                    if dot2 > 6.5 then
                        if dot > 0 and dot < huge4 then
                            huge4 = dot
                        end
                        if not (dot >= -28 and dot <= 30) then
                            continue
                        end
                        flag3 = true
                    else
                        if dot > 0 and dot < huge3 then
                            huge3 = dot
                        end
                        if not (dot >= -28 and dot <= 30) then
                            continue
                        end
                        flag2 = true
                    end
                end
            end
            local ok3 = not flag and huge2 > 30
            local ok4 = not flag2 and huge3 > 30
            local ok5 = not flag3 and huge4 > 30
            local lanewidth = config.LaneWidth
            local num15 = math.clamp(num6 * 0.45, 52, 75)
            local result14 = num15 + 18
            if num5 > 6.5 then
                if huge4 < num15 then
                    if ok4 then
                        num5 = 0
                    elseif ok3 and huge2 > huge3 then
                        num5 = -lanewidth
                        num10 = -1
                    end
                elseif ok4 and huge3 > result14 and huge4 > result14 then
                    num5 = 0
                end
            elseif num5 < -6.5 then
                if huge2 < num15 then
                    if ok4 then
                        num5 = 0
                    elseif ok5 and huge4 > huge3 then
                        num5 = lanewidth
                        num10 = 1
                    end
                elseif ok4 and huge3 > result14 and huge2 > result14 then
                    num5 = 0
                end
            elseif huge3 < num15 then
                if ok3 and ok5 then
                    if huge2 > num15 and huge4 > num15 then
                        num10 = -num10
                        num5 = num10 * lanewidth
                    elseif huge2 > huge4 then
                        num5 = -lanewidth
                        num10 = -1
                    elseif huge4 > huge2 then
                        num5 = lanewidth
                        num10 = 1
                    else
                        num10 = -num10
                        num5 = num10 * lanewidth
                    end
                elseif ok3 then
                    num5 = -lanewidth
                    num10 = -1
                elseif ok5 then
                    num5 = lanewidth
                    num10 = 1
                end
            else
                num5 = 0
            end
            num4 = num4 + (num5 - num4) * math.clamp(num12 * config.WeaveLerpSpeed, 0, 1)
            local result15 = result12 + unit2 * num4
            local result16 = fn13(result15, result3)
            local vector3 = Vector3.new(result15.X, result16, result15.Z)
            local lookat = CFrame.lookAt(vector3, vector3 + unit)
            result3:PivotTo(lookat)
            v6.AssemblyLinearVelocity = unit * result9
            if updatespeedbridge then
                updatespeedbridge:Fire(math.floor(num6))
            end
            task.wait(num12)
            continue
        end
        fn16(result3, v6)
        local result17 = fn15(result3, v6)
        if not result17 then
            task.wait(0.5)
        else
            num3 = fn22(v6.Position)
        end
    end
end)