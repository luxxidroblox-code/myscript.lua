-- 🪐 ZBABO ULTIMATE ADMIN HUB (FINAL) 🪐
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- 1. EKRAN KARARMA VE PROFİL RESİMLİ GİRİŞ (WELCOME)
local Flash = Instance.new("Frame", ScreenGui)
Flash.Size = UDim2.new(1, 0, 1, 0); Flash.BackgroundColor3 = Color3.fromRGB(0, 0, 0); Flash.BackgroundTransparency = 1; Flash.ZIndex = 100

local WelcomeFrame = Instance.new("Frame", ScreenGui)
WelcomeFrame.Size = UDim2.new(0, 300, 0, 100); WelcomeFrame.Position = UDim2.new(0.5, -150, -0.2, 0)
WelcomeFrame.BackgroundColor3 = Color3.fromRGB(15, 5, 30); WelcomeFrame.BorderSizePixel = 2; WelcomeFrame.BorderColor3 = Color3.fromRGB(170, 0, 255)

local ProfileImg = Instance.new("ImageLabel", WelcomeFrame)
ProfileImg.Size = UDim2.new(0, 80, 0, 80); ProfileImg.Position = UDim2.new(0.05, 0, 0.1, 0)
ProfileImg.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. lplr.UserId .. "&width=420&height=420&format=png"; ProfileImg.BackgroundTransparency = 1

local WelcomeText = Instance.new("TextLabel", WelcomeFrame)
WelcomeText.Size = UDim2.new(0.65, 0, 1, 0); WelcomeText.Position = UDim2.new(0.3, 0, 0, 0)
WelcomeText.Text = "Welcome Back,\n" .. lplr.Name; WelcomeText.TextColor3 = Color3.fromRGB(255, 255, 255); WelcomeText.Font = Enum.Font.SourceSansBold; WelcomeText.TextSize = 22; WelcomeText.BackgroundTransparency = 1

task.spawn(function()
    Flash.BackgroundTransparency = 0.4; wait(0.1); Flash.BackgroundTransparency = 1
    WelcomeFrame:TweenPosition(UDim2.new(0.5, -150, 0.05, 0), "Out", "Bounce", 0.5)
    wait(3); WelcomeFrame:TweenPosition(UDim2.new(0.5, -150, -0.2, 0), "In", "Quad", 0.5)
end)

-- 2. ANA PANEL (İLK BEĞENDİĞİN SATÜRN TASARIMI)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 520); MainFrame.Position = UDim2.new(0.5, -160, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 5, 20); MainFrame.BorderSizePixel = 2; MainFrame.BorderColor3 = Color3.fromRGB(170, 0, 255); MainFrame.Active = true; MainFrame.Draggable = true

-- Satürn Halkası
local Ring = Instance.new("ImageLabel", MainFrame)
Ring.Size = UDim2.new(1.4, 0, 0.6, 0); Ring.Position = UDim2.new(-0.2, 0, 0.2, 0)
Ring.Image = "rbxassetid://6073752669"; Ring.BackgroundTransparency = 1; Ring.ImageColor3 = Color3.fromRGB(0, 255, 255); Ring.ZIndex = 0
spawn(function() while wait() do Ring.Rotation = Ring.Rotation + 0.1 end end)

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "✨ ZBABO ADMIN HUB ✨"; Title.Size = UDim2.new(1, 0, 0, 50); Title.BackgroundColor3 = Color3.fromRGB(30, 0, 50); Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.Font = Enum.Font.SourceSansBold; Title.TextSize = 24

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Position = UDim2.new(0, 0, 0, 55); Container.Size = UDim2.new(1, 0, 1, -55); Container.CanvasSize = UDim2.new(0, 0, 10, 0); Container.BackgroundTransparency = 1; Container.ScrollBarThickness = 4
local UIList = Instance.new("UIListLayout", Container); UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center; UIList.Padding = UDim.new(0, 12); UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- BİLDİRİM SİSTEMİ
local function notify(txt)
    local nF = Instance.new("Frame", ScreenGui); nF.Size = UDim2.new(0, 220, 0, 55); nF.Position = UDim2.new(1, -240, 1, -80); nF.BackgroundColor3 = Color3.fromRGB(30, 0, 50); nF.BorderSizePixel = 2; nF.BorderColor3 = Color3.fromRGB(170, 0, 255)
    local nL = Instance.new("TextLabel", nF); nL.Size = UDim2.new(1, 0, 1, 0); nL.Text = txt; nL.TextColor3 = Color3.fromRGB(255, 255, 255); nL.TextSize = 20; nL.Font = Enum.Font.SourceSansBold; nL.BackgroundTransparency = 1
    task.delay(1.5, function() nF:Destroy() end)
end

local function createBtn(text, order)
    local b = Instance.new("TextButton", Container); b.Size = UDim2.new(0.85, 0, 0, 45); b.Text = text; b.LayoutOrder = order; b.BackgroundColor3 = Color3.fromRGB(45, 0, 70); b.TextColor3 = Color3.fromRGB(255, 255, 255); b.Font = Enum.Font.SourceSansBold; b.TextSize = 20; return b
end

local function createInp(placeholder, order)
    local i = Instance.new("TextBox", Container); i.Size = UDim2.new(0.85, 0, 0, 40); i.PlaceholderText = placeholder; i.Text = ""; i.BackgroundColor3 = Color3.fromRGB(35, 35, 35); i.TextColor3 = Color3.fromRGB(170, 0, 255); i.Font = Enum.Font.SourceSansBold; i.TextSize = 18; i.LayoutOrder = order; return i
end

-- --- ÖZELLİKLER (SIRALI VE TAM) ---

-- SPEED
local spdBtn = createBtn("Speed", 1); local spdIn = createInp("Enter Speed Value", 2)
spdBtn.MouseButton1Click:Connect(function() lplr.Character.Humanoid.WalkSpeed = tonumber(spdIn.Text) or 16; notify("Speed Enabled") end)

-- FLY
local flyBtn = createBtn("Fly", 3); local flying = false; local flyIn = createInp("Enter Fly Speed", 4)
flyBtn.MouseButton1Click:Connect(function()
    flying = not flying; flyBtn.BackgroundColor3 = flying and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(45, 0, 70); notify(flying and "Fly Enabled" or "Fly Disabled")
    local root = lplr.Character.HumanoidRootPart
    if flying then
        local bv = Instance.new("BodyVelocity", root); bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); local bg = Instance.new("BodyGyro", root); bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
            while flying do
                local cam = workspace.CurrentCamera; local fs = (tonumber(flyIn.Text) or 1) * 50; local v = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then v = v + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then v = v - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then v = v - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then v = v + cam.CFrame.RightVector end
                bv.Velocity = v * fs; bg.CFrame = cam.CFrame; RunService.RenderStepped:Wait()
            end
            bv:Destroy(); bg:Destroy()
        end)
    end
end)

-- SPIN
local spinBtn = createBtn("Spin", 5); local spinning = false; local spinIn = createInp("Enter Spin Speed", 6)
spinBtn.MouseButton1Click:Connect(function() spinning = not spinning; spinBtn.BackgroundColor3 = spinning and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(45, 0, 70); notify(spinning and "Spin Enabled" or "Spin Disabled") end)
RunService.RenderStepped:Connect(function() if spinning and lplr.Character then lplr.Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(tonumber(spinIn.Text) or 20), 0) end end)

-- HITBOX (Kalıcı ve Büyük)
local hbing = false; local hbBtn = createBtn("Hitbox", 7); local hbIn = createInp("Enter Hitbox Size (Max 50)", 8)
hbBtn.MouseButton1Click:Connect(function() hbing = not hbing; hbBtn.BackgroundColor3 = hbing and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(45, 0, 70); notify(hbing and "Hitbox Enabled" or "Hitbox Disabled") end)
task.spawn(function()
    while wait(0.5) do
        if hbing then
            local s = tonumber(hbIn.Text) or 10
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lplr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.Size = Vector3.new(s,s,s); p.Character.HumanoidRootPart.Transparency = 0.7; p.Character.HumanoidRootPart.CanCollide = false
                end
            end
        end
    end
end)

-- ESP (BOX)
local espBtn = createBtn("ESP (Box)", 9); local espping = false
espBtn.MouseButton1Click:Connect(function()
    espping = not espping; espBtn.BackgroundColor3 = espping and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(45, 0, 70); notify(espping and "ESP Enabled" or "ESP Disabled")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character then
            if espping then
                local b = Instance.new("BoxHandleAdornment", p.Character); b.Name = "ZE"; b.Size = p.Character:GetExtentsSize(); b.Adornee = p.Character; b.AlwaysOnTop = true; b.Transparency = 0.5; b.Color3 = Color3.fromRGB(170, 0, 255)
            else if p.Character:FindFirstChild("ZE") then p.Character.ZE:Destroy() end end
        end
    end
end)

-- DİĞERLERİ
createBtn("Get BTools", 10).MouseButton1Click:Connect(function() for i = 1, 4 do Instance.new("HopperBin", lplr.Backpack).BinType = i end; notify("BTools Enabled") end)
createBtn("Get ZBABO TP Tool", 11).MouseButton1Click:Connect(function() local t = Instance.new("Tool"); t.Name = "ZBABO TP"; t.RequiresHandle = false; t.Parent = lplr.Backpack; t.Activated:Connect(function() lplr.Character:MoveTo(lplr:GetMouse().Hit.p + Vector3.new(0,3,0)) end); notify("TP Tool Enabled") end)
createBtn("Sit", 12).MouseButton1Click:Connect(function() lplr.Character.Humanoid.Sit = true; notify("Sitting") end)
createBtn("Infinite Jump", 13).MouseButton1Click:Connect(function() local ij = true; UserInputService.JumpRequest:Connect(function() if ij then lplr.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end end); notify("Inf Jump Enabled") end)
createBtn("Noclip", 14).MouseButton1Click:Connect(function() _G.NC = not _G.NC; notify("Noclip Toggled") end)
createBtn("Respawn", 15).MouseButton1Click:Connect(function() lplr.Character:BreakJoints() end)
createBtn("Rejoin", 16).MouseButton1Click:Connect(function() game:GetService("TeleportService"):Teleport(game.PlaceId, lplr) end)

-- GOTO LIST
local ref = createBtn("Refresh & Choose Player (GOTO)", 17); local PF = Instance.new("Frame", Container); PF.Size = UDim2.new(1, 0, 0, 100); PF.BackgroundTransparency = 1; PF.LayoutOrder = 18; Instance.new("UIListLayout", PF).HorizontalAlignment = Enum.HorizontalAlignment.Center
ref.MouseButton1Click:Connect(function()
    for _, v in pairs(PF:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do if p ~= lplr then
        local b = Instance.new("TextButton", PF); b.Size = UDim2.new(0.8, 0, 0, 35); b.Text = p.Name; b.BackgroundColor3 = Color3.fromRGB(60, 0, 90); b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 16
        b.MouseButton1Click:Connect(function() lplr.Character:PivotTo(p.Character.HumanoidRootPart.CFrame); notify("Teleported") end)
    end end
end)

-- HIDE GUI
local H = Instance.new("TextButton", ScreenGui); H.Size = UDim2.new(0, 120, 0, 40); H.Position = UDim2.new(0, 10, 0, 10); H.Text = "HIDE GUI"; H.BackgroundColor3 = Color3.fromRGB(30, 0, 50); H.TextColor3 = Color3.fromRGB(255, 255, 255); H.Font = Enum.Font.SourceSansBold; H.TextSize = 18
H.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible; H.Text = MainFrame.Visible and "HIDE GUI" or "SHOW GUI" end)