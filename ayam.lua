local MarketplaceService = game:GetService("MarketplaceService")
local u2 = MarketplaceService
local ok, result = pcall(function()
    return u2:GetProductInfo(game.PlaceId)
end)
local v5 = ok and result.Name or ""
if not string.find(string.lower(v5), "tr legacy") then
    local CoreGui = game:GetService("CoreGui")
    local ScreenGui = Instance.new("ScreenGui")

    ScreenGui.Name = "TR_Legacy_Error"
    ScreenGui.Parent = CoreGui

    local Frame = Instance.new("Frame", ScreenGui)

    Frame.Size = UDim2.new(0, 380, 0, 110)
    Frame.Position = UDim2.new(0.5, -190, 0.5, -55)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

    local TextLabel = Instance.new("TextLabel", Frame)

    TextLabel.Size = UDim2.new(1, -20, 1, 0)
    TextLabel.Position = UDim2.new(0, 10, 0, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = "âŒ ACCESO DENEGADO\n\nEste script solo funciona en el juego TR Legacy.\nDetectado: " .. (v5 ~= "" and v5 or "Desconocido") .. "\nEl script se ha detenido."
    TextLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    TextLabel.TextSize = 12
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextWrapped = true
    task.wait(6)
    ScreenGui:Destroy()

    return
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera
local E = Enum.KeyCode.E
local t1 = {
	TurboEnabled = false,
	TurboForce = 5,
	BrakeEnabled = false,
	BrakeForce = 5,
	NoclipEnabled = false,
	TurboKey = E,
	IsBindingKey = false,
	BetterHandling = false,
	ESPBox = false,
	ESPTracer = false,
	ESPHealth = false,
	ESPInfo = false,
	SelectedPlayer = nil,
	IsSpectating = false
}
local t2 = {}
local u20
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TRLegacyMenu_" .. tostring(math.random(1000, 9999))
local _syn = syn
if _syn then
    _syn = syn.protect_gui
end
if _syn then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local function v23(p1, p2)
    local UICorner = Instance.new("UICorner")

    UICorner.CornerRadius = UDim.new(0, p2 or 8)
    UICorner.Parent = p1

    return UICorner
end
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 520, 0, 480)
Frame.Position = UDim2.new(0.5, -260, 0.5, -240)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
v23(Frame, 12)
local Frame2 = Instance.new("Frame", Frame)
Frame2.Size = UDim2.new(1, 0, 0, 40)
Frame2.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Frame2.BorderSizePixel = 0
v23(Frame2, 12)
local TextLabel = Instance.new("TextLabel", Frame2)
TextLabel.Size = UDim2.new(1, -90, 1, 0)
TextLabel.Position = UDim2.new(0, 15, 0, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.Text = "âš™\239\184\143 TR Legacy MENU + Noclip Vehicular con Colisiones"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 13
TextLabel.Font = Enum.Font.GothamBold
TextLabel.TextXAlignment = Enum.TextXAlignment.Left
local TextButton = Instance.new("TextButton", Frame2)
TextButton.Size = UDim2.new(0, 30, 0, 30)
TextButton.Position = UDim2.new(1, -35, 0.5, -15)
TextButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
TextButton.Text = "X"
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.TextSize = 12
TextButton.Font = Enum.Font.GothamBold
v23(TextButton, 6)
local Frame3 = Instance.new("Frame", Frame)
Frame3.Size = UDim2.new(1, 0, 0, 35)
Frame3.Position = UDim2.new(0, 0, 0, 40)
Frame3.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Frame3.BorderSizePixel = 0
local Frame4 = Instance.new("Frame", Frame)
Frame4.Size = UDim2.new(1, -20, 1, -95)
Frame4.Position = UDim2.new(0, 10, 0, 85)
Frame4.BackgroundTransparency = 1
local TextButton2 = Instance.new("TextButton", Frame2)
TextButton2.Size = UDim2.new(0, 30, 0, 30)
TextButton2.Position = UDim2.new(1, -70, 0.5, -15)
TextButton2.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
TextButton2.Text = "-"
TextButton2.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton2.TextSize = 14
TextButton2.Font = Enum.Font.GothamBold
v23(TextButton2, 6)
local u31 = false
TextButton2.MouseButton1Click:Connect(function()
    u31 = not u31

    if u31 then
        TextButton2.Text = "+"
        Frame.Size = UDim2.new(0, 520, 0, 40)
        Frame3.Visible = false
        Frame4.Visible = false

        return
    end

    TextButton2.Text = "-"
    Frame.Size = UDim2.new(0, 520, 0, 480)
    Frame3.Visible = true
    Frame4.Visible = true
end)
TextButton.MouseButton1Click:Connect(function()
    if u20 then
        for _, descendant in ipairs(u20:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.CanCollide = true
            end
        end
    end

    ScreenGui:Destroy()

    for _, v in pairs(t2) do
        for _, v2 in pairs(v) do
            local v85 = v2

            pcall(function()
                v85:Remove()
            end)
        end
    end
end)
local t3 = {
	"VehÃ­culo & Turbo",
	"ESP Profesional",
	"Lista de Jugadores"
}
local t4 = {}
local t5 = {}
local s1 = "VehÃ­culo & Turbo"
for i, v in ipairs(t3) do
    local v38 = v
    local TextButton3 = Instance.new("TextButton", Frame3)

    TextButton3.Size = UDim2.new(1 / #t3, 0, 1, 0)
    TextButton3.Position = UDim2.new((i - 1) * (1 / #t3), 0, 0, 0)

    local v40 = v38 == s1

    if v40 then
        v40 = Color3.fromRGB(40, 40, 50)
    end

    if not v40 then
        v40 = Color3.fromRGB(25, 25, 30)
    end

    TextButton3.BackgroundColor3 = v40
    TextButton3.Text = v38
    TextButton3.TextColor3 = Color3.fromRGB(220, 220, 220)
    TextButton3.TextSize = 11
    TextButton3.Font = Enum.Font.Gotham
    TextButton3.BorderSizePixel = 0
    TextButton3.AutoButtonColor = false
    t4[v38] = TextButton3

    local ScrollingFrame = Instance.new("ScrollingFrame", Frame4)

    ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.Visible = v38 == s1
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollingFrame.ScrollBarThickness = 4

    local UIListLayout = Instance.new("UIListLayout", ScrollingFrame)

    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 10)
    t5[v38] = ScrollingFrame
    TextButton3.MouseButton1Click:Connect(function()
        s1 = v38
        for v88, v89 in pairs(t4) do

            local v90 = v88 == v38

            if v90 then
                v90 = Color3.fromRGB(40, 40, 50)
            end

            if not v90 then
                v90 = Color3.fromRGB(25, 25, 30)
            end

            v89.BackgroundColor3 = v90
        end
        for k, v3 in pairs(t5) do
            v3.Visible = k == v38
        end
    end)
end
local function v43(p3, p4)
    local Frame5 = Instance.new("Frame")

    Frame5.Size = UDim2.new(1, 0, 0, 140)
    Frame5.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Frame5.BorderSizePixel = 0
    Frame5.Parent = p3
    v23(Frame5, 8)

    local TextLabel2 = Instance.new("TextLabel", Frame5)

    TextLabel2.Size = UDim2.new(1, -15, 0, 30)
    TextLabel2.Position = UDim2.new(0, 15, 0, 0)
    TextLabel2.BackgroundTransparency = 1
    TextLabel2.Text = p4
    TextLabel2.TextColor3 = Color3.fromRGB(150, 150, 150)
    TextLabel2.TextSize = 11
    TextLabel2.Font = Enum.Font.GothamBold
    TextLabel2.TextXAlignment = Enum.TextXAlignment.Left

    local UIListLayout = Instance.new("UIListLayout", Frame5)

    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 8)

    return Frame5
end
local function v44(p5, p6, p7)
    local Frame6 = Instance.new("Frame", p5)

    Frame6.Size = UDim2.new(1, -30, 0, 30)
    Frame6.BackgroundTransparency = 1

    local TextLabel3 = Instance.new("TextLabel", Frame6)

    TextLabel3.Size = UDim2.new(0.7, 0, 1, 0)
    TextLabel3.BackgroundTransparency = 1
    TextLabel3.Text = p6
    TextLabel3.TextColor3 = Color3.fromRGB(220, 220, 220)
    TextLabel3.TextSize = 11
    TextLabel3.Font = Enum.Font.Gotham
    TextLabel3.TextXAlignment = Enum.TextXAlignment.Left

    local TextButton4 = Instance.new("TextButton", Frame6)

    TextButton4.Size = UDim2.new(0, 40, 0, 22)
    TextButton4.Position = UDim2.new(1, -40, 0.5, -11)
    TextButton4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TextButton4.Text = ""
    TextButton4.AutoButtonColor = false
    v23(TextButton4, 11)

    local Frame7 = Instance.new("Frame", TextButton4)

    Frame7.Size = UDim2.new(0, 18, 0, 18)
    Frame7.Position = UDim2.new(0, 2, 0.5, -9)
    Frame7.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    v23(Frame7, 9)

    local u105 = false

    TextButton4.MouseButton1Click:Connect(function()
        u105 = not u105

        local v194 = TextButton4
        local v195 = u105

        if v195 then
            v195 = Color3.fromRGB(100, 200, 100)
        end

        if not v195 then
            v195 = Color3.fromRGB(60, 60, 60)
        end

        v194.BackgroundColor3 = v195

        local v196 = Frame7
        local v197 = u105

        if v197 then
            v197 = UDim2.new(0, 20, 0.5, -9)
        end

        if not v197 then
            v197 = UDim2.new(0, 2, 0.5, -9)
        end

        v196.Position = v197
        p7(u105)
    end)
end
local v45 = v43(t5["VehÃ­culo & Turbo"], "CONFIGURACIÃ“N DE TURBO, FRENO Y NOCLIP")
v45.Size = UDim2.new(1, 0, 0, 410)
v44(v45, "Activar Turbo en VehÃ­culos", function(p8)
    t1.TurboEnabled = p8
end)
v44(v45, "Activar Freno Inverso (Tecla S)", function(p9)
    t1.BrakeEnabled = p9
end)
v44(v45, "Manejo Pro (Giro Ultra)", function(p10)
    t1.BetterHandling = p10
end)
v44(v45, "Noclip con VehÃ­culo (Shift corre mÃ¡s)", function(p11)
    t1.NoclipEnabled = p11

    if not p11 and u20 then
        for _, descendant in ipairs(u20:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.CanCollide = true
            end
        end

        u20 = nil
    end
end)
local Frame8 = Instance.new("Frame", v45)
Frame8.Size = UDim2.new(1, -30, 0, 30)
Frame8.BackgroundTransparency = 1
local TextLabel4 = Instance.new("TextLabel", Frame8)
TextLabel4.Size = UDim2.new(0.6, 0, 1, 0)
TextLabel4.BackgroundTransparency = 1
TextLabel4.Text = "Tecla de Turbo"
TextLabel4.TextColor3 = Color3.fromRGB(220, 220, 220)
TextLabel4.TextSize = 11
TextLabel4.Font = Enum.Font.Gotham
TextLabel4.TextXAlignment = Enum.TextXAlignment.Left
local TextButton5 = Instance.new("TextButton", Frame8)
TextButton5.Size = UDim2.new(0, 90, 0, 24)
TextButton5.Position = UDim2.new(1, -90, 0.5, -12)
TextButton5.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
TextButton5.Text = t1.TurboKey.Name
TextButton5.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton5.TextSize = 11
TextButton5.Font = Enum.Font.GothamBold
v23(TextButton5, 6)
TextButton5.MouseButton1Click:Connect(function()
    t1.IsBindingKey = true
    TextButton5.Text = "..."
end)
UserInputService.InputBegan:Connect(function(input, _)
    local IsBindingKey = t1.IsBindingKey

    if IsBindingKey then
        IsBindingKey = input.UserInputType == Enum.UserInputType.Keyboard
    end

    if IsBindingKey then
        t1.TurboKey = input.KeyCode
        TextButton5.Text = input.KeyCode.Name
        t1.IsBindingKey = false
    end
end)
local Frame9 = Instance.new("Frame", v45)
Frame9.Size = UDim2.new(1, -30, 0, 45)
Frame9.BackgroundTransparency = 1
local TextLabel5 = Instance.new("TextLabel", Frame9)
TextLabel5.Size = UDim2.new(0.7, 0, 0, 20)
TextLabel5.BackgroundTransparency = 1
TextLabel5.Text = "Fuerza del Turbo"
TextLabel5.TextColor3 = Color3.fromRGB(220, 220, 220)
TextLabel5.TextSize = 11
TextLabel5.Font = Enum.Font.Gotham
TextLabel5.TextXAlignment = Enum.TextXAlignment.Left
local TextLabel6 = Instance.new("TextLabel", Frame9)
TextLabel6.Size = UDim2.new(0.3, 0, 0, 20)
TextLabel6.Position = UDim2.new(0.7, 0, 0, 0)
TextLabel6.BackgroundTransparency = 1
TextLabel6.Text = tostring(t1.TurboForce) .. "x"
TextLabel6.TextColor3 = Color3.fromRGB(150, 150, 150)
TextLabel6.TextSize = 11
TextLabel6.Font = Enum.Font.Gotham
TextLabel6.TextXAlignment = Enum.TextXAlignment.Right
local TextButton6 = Instance.new("TextButton", Frame9)
TextButton6.Size = UDim2.new(1, 0, 0, 6)
TextButton6.Position = UDim2.new(0, 0, 0, 25)
TextButton6.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TextButton6.Text = ""
TextButton6.AutoButtonColor = false
v23(TextButton6, 3)
local Frame10 = Instance.new("Frame", TextButton6)
Frame10.Size = UDim2.new((t1.TurboForce - 1) / 19, 0, 1, 0)
Frame10.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
Frame10.BorderSizePixel = 0
v23(Frame10, 3)
local u54 = false
TextButton6.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        u54 = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        u54 = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    local v118 = u54

    if v118 then
        v118 = input.UserInputType == Enum.UserInputType.MouseMovement
    end

    if v118 then
        local v119 = math.clamp((input.Position.X - TextButton6.AbsolutePosition.X) / TextButton6.AbsoluteSize.X, 0, 1)

        t1.TurboForce = math.floor(1 + 19 * v119)
        Frame10.Size = UDim2.new(v119, 0, 1, 0)
        TextLabel6.Text = tostring(t1.TurboForce) .. "x"
    end
end)
local Frame11 = Instance.new("Frame", v45)
Frame11.Size = UDim2.new(1, -30, 0, 45)
Frame11.BackgroundTransparency = 1
local TextLabel7 = Instance.new("TextLabel", Frame11)
TextLabel7.Size = UDim2.new(0.7, 0, 0, 20)
TextLabel7.BackgroundTransparency = 1
TextLabel7.Text = "Fuerza de Freno Inverso (Tecla S)"
TextLabel7.TextColor3 = Color3.fromRGB(220, 220, 220)
TextLabel7.TextSize = 11
TextLabel7.Font = Enum.Font.Gotham
TextLabel7.TextXAlignment = Enum.TextXAlignment.Left
local TextLabel8 = Instance.new("TextLabel", Frame11)
TextLabel8.Size = UDim2.new(0.3, 0, 0, 20)
TextLabel8.Position = UDim2.new(0.7, 0, 0, 0)
TextLabel8.BackgroundTransparency = 1
TextLabel8.Text = tostring(t1.BrakeForce) .. "x"
TextLabel8.TextColor3 = Color3.fromRGB(150, 150, 150)
TextLabel8.TextSize = 11
TextLabel8.Font = Enum.Font.Gotham
TextLabel8.TextXAlignment = Enum.TextXAlignment.Right
local TextButton7 = Instance.new("TextButton", Frame11)
TextButton7.Size = UDim2.new(1, 0, 0, 6)
TextButton7.Position = UDim2.new(0, 0, 0, 25)
TextButton7.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TextButton7.Text = ""
TextButton7.AutoButtonColor = false
v23(TextButton7, 3)
local Frame12 = Instance.new("Frame", TextButton7)
Frame12.Size = UDim2.new((t1.BrakeForce - 1) / 19, 0, 1, 0)
Frame12.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
Frame12.BorderSizePixel = 0
v23(Frame12, 3)
local u60 = false
TextButton7.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        u60 = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        u60 = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    local v123 = u60

    if v123 then
        v123 = input.UserInputType == Enum.UserInputType.MouseMovement
    end

    if v123 then
        local v124 = input.Position.X - TextButton7.AbsolutePosition.X
        local AbsoluteSizeX = TextButton7.AbsoluteSize.X
        local v126 = math.clamp(v124 / AbsoluteSizeX, 0, 1)

        t1.BrakeForce = math.floor(1 + 19 * v126)
        Frame12.Size = UDim2.new(v126, 0, 1, 0)
        TextLabel8.Text = tostring(t1.BrakeForce) .. "x"
    end
end)
local v61 = v43(t5["ESP Profesional"], "OPCIONES DE ESP")
v61.Size = UDim2.new(1, 0, 0, 180)
v44(v61, "Caja 2D (Box ESP)", function(p13)
    t1.ESPBox = p13
end)
v44(v61, "LÃ­neas de Rastreo (Tracers)", function(p14)
    t1.ESPTracer = p14
end)
v44(v61, "Barra de Vida (Health Bar)", function(p15)
    t1.ESPHealth = p15
end)
v44(v61, "Nombre y Distancia", function(p16)
    t1.ESPInfo = p16
end)
local v62 = t5["Lista de Jugadores"]
local Frame13 = Instance.new("Frame", v62)
Frame13.Size = UDim2.new(1, 0, 0, 95)
Frame13.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Frame13.BorderSizePixel = 0
v23(Frame13, 8)
local TextLabel9 = Instance.new("TextLabel", Frame13)
TextLabel9.Size = UDim2.new(1, -20, 0, 25)
TextLabel9.Position = UDim2.new(0, 10, 0, 5)
TextLabel9.BackgroundTransparency = 1
TextLabel9.Text = "OBJETIVO SELECCIONADO:"
TextLabel9.TextColor3 = Color3.fromRGB(150, 150, 150)
TextLabel9.TextSize = 10
TextLabel9.Font = Enum.Font.GothamBold
TextLabel9.TextXAlignment = Enum.TextXAlignment.Left
local TextLabel10 = Instance.new("TextLabel", Frame13)
TextLabel10.Size = UDim2.new(1, -20, 0, 25)
TextLabel10.Position = UDim2.new(0, 10, 0, 25)
TextLabel10.BackgroundTransparency = 1
TextLabel10.Text = "Ninguno (Selecciona abajo)"
TextLabel10.TextColor3 = Color3.fromRGB(100, 150, 255)
TextLabel10.TextSize = 13
TextLabel10.Font = Enum.Font.GothamBold
TextLabel10.TextXAlignment = Enum.TextXAlignment.Left
local Frame14 = Instance.new("Frame", Frame13)
Frame14.Size = UDim2.new(1, -20, 0, 32)
Frame14.Position = UDim2.new(0, 10, 0, 55)
Frame14.BackgroundTransparency = 1
local TextButton8 = Instance.new("TextButton", Frame14)
TextButton8.Size = UDim2.new(0.48, 0, 1, 0)
TextButton8.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
TextButton8.Text = "âš¡ Teleportarse"
TextButton8.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton8.TextSize = 11
TextButton8.Font = Enum.Font.GothamBold
v23(TextButton8, 6)
local TextButton9 = Instance.new("TextButton", Frame14)
TextButton9.Size = UDim2.new(0.48, 0, 1, 0)
TextButton9.Position = UDim2.new(0.52, 0, 0, 0)
TextButton9.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
TextButton9.Text = "ðŸ‘\239\184\143 Espectear"
TextButton9.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton9.TextSize = 11
TextButton9.Font = Enum.Font.GothamBold
v23(TextButton9, 6)
TextButton8.MouseButton1Click:Connect(function()
    local SelectedPlayer = t1.SelectedPlayer

    if SelectedPlayer then
        SelectedPlayer = t1.SelectedPlayer.Character

        if SelectedPlayer then
            SelectedPlayer = t1.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
    end

    if SelectedPlayer then
        local Character = LocalPlayer.Character

        if Character then
            Character = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end

        if Character then
            Character.CFrame = t1.SelectedPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
    end
end)
TextButton9.MouseButton1Click:Connect(function()
    t1.IsSpectating = not t1.IsSpectating

    local IsSpectating = t1.IsSpectating

    if IsSpectating then
        IsSpectating = t1.SelectedPlayer

        if IsSpectating then
            IsSpectating = t1.SelectedPlayer.Character
        end
    end

    if IsSpectating then
        local Humanoid = t1.SelectedPlayer.Character:FindFirstChildOfClass("Humanoid")

        if Humanoid then
            CurrentCamera.CameraSubject = Humanoid
            TextButton9.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            TextButton9.Text = "ðŸ‘\239\184\143 Especteando (Activo)"

            return
        end
    else
        if LocalPlayer.Character then
            local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

            if Humanoid then
                CurrentCamera.CameraSubject = Humanoid
            end
        end

        TextButton9.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
        TextButton9.Text = "ðŸ‘\239\184\143 Espectear"
        t1.IsSpectating = false
    end
end)
local Frame15 = Instance.new("Frame", v62)
Frame15.Size = UDim2.new(1, 0, 0, 210)
Frame15.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Frame15.BorderSizePixel = 0
v23(Frame15, 8)
local TextLabel11 = Instance.new("TextLabel", Frame15)
TextLabel11.Size = UDim2.new(1, -15, 0, 30)
TextLabel11.Position = UDim2.new(0, 15, 0, 0)
TextLabel11.BackgroundTransparency = 1
TextLabel11.Text = "JUGADORES EN LÃNEA (Haz clic para seleccionar)"
TextLabel11.TextColor3 = Color3.fromRGB(150, 150, 150)
TextLabel11.TextSize = 10
TextLabel11.Font = Enum.Font.GothamBold
TextLabel11.TextXAlignment = Enum.TextXAlignment.Left
local ScrollingFrame = Instance.new("ScrollingFrame", Frame15)
ScrollingFrame.Size = UDim2.new(1, -16, 1, -35)
ScrollingFrame.Position = UDim2.new(0, 8, 0, 30)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollingFrame.ScrollBarThickness = 3
local UIListLayout = Instance.new("UIListLayout", ScrollingFrame)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
local t6 = {}
local function u74()

    for v138, v139 in pairs(t6) do

        v139:Destroy()
    end
    table.clear(t6)
    for _, player in ipairs(Players:GetPlayers()) do
        local v142 = player

        if v142 ~= LocalPlayer then
            local TextButton10 = Instance.new("TextButton", ScrollingFrame)

            TextButton10.Size = UDim2.new(1, -5, 0, 32)

            local v144 = v142 == t1.SelectedPlayer

            if v144 then
                v144 = Color3.fromRGB(50, 80, 130)
            end

            if not v144 then
                v144 = Color3.fromRGB(35, 35, 42)
            end

            TextButton10.BackgroundColor3 = v144
            TextButton10.Text = "  " .. v142.Name .. " (@" .. v142.DisplayName .. ")"
            TextButton10.TextColor3 = Color3.fromRGB(220, 220, 220)
            TextButton10.TextSize = 11
            TextButton10.Font = Enum.Font.Gotham
            TextButton10.TextXAlignment = Enum.TextXAlignment.Left
            TextButton10.AutoButtonColor = false
            v23(TextButton10, 6)
            TextButton10.MouseButton1Click:Connect(function()
                t1.SelectedPlayer = v142
                TextLabel10.Text = v142.Name .. " (@" .. v142.DisplayName .. ")"
                u74()
            end)
            t6[v142] = TextButton10
        end
    end
end
Players.PlayerAdded:Connect(u74)
Players.PlayerRemoving:Connect(u74)
u74()
local function v75(p17)
    if not t2[p17] then
        local v146 = t2
        local drawing = Drawing.new("Square")
        local drawing2 = Drawing.new("Line")
        local drawing3 = Drawing.new("Square")
        local drawing4 = Drawing.new("Square")
        local drawing5 = Drawing.new("Text")

        v146[p17] = {
			Box = drawing,
			Tracer = drawing2,
			HealthBar = drawing3,
			HealthBarInner = drawing4,
			Info = drawing5
		}

        local v152 = t2[p17]

        v152.Box.Thickness = 1.5
        v152.Box.Filled = false
        v152.Box.Color = Color3.fromRGB(0, 255, 150)
        v152.Tracer.Thickness = 1
        v152.Tracer.Color = Color3.fromRGB(0, 255, 150)
        v152.HealthBar.Thickness = 1
        v152.HealthBar.Filled = true
        v152.HealthBar.Color = Color3.fromRGB(0, 0, 0)
        v152.HealthBarInner.Thickness = 1
        v152.HealthBarInner.Filled = true
        v152.HealthBarInner.Color = Color3.fromRGB(0, 255, 0)
        v152.Info.Size = 12
        v152.Info.Center = true
        v152.Info.Outline = true
        v152.Info.Color = Color3.fromRGB(255, 255, 255)
    end

    return t2[p17]
end
Players.PlayerRemoving:Connect(function(player)
    if t2[player] then
        for _, v in pairs(t2[player]) do
            local v156 = v

            pcall(function()
                v156:Remove()
            end)
        end

        t2[player] = nil
    end

    if player == t1.SelectedPlayer then
        t1.SelectedPlayer = nil
    end
end)
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character then
        local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local v158 = Humanoid

        if Humanoid then
            v158 = Humanoid.SeatPart

            if v158 then
                v158 = Humanoid.SeatPart:IsA("VehicleSeat")

                if not v158 then
                    v158 = Humanoid.SeatPart:IsA("Seat")
                end
            end
        end

        if v158 then
            local SeatPartParent = Humanoid.SeatPart.Parent
            local PrimaryPart = SeatPartParent.PrimaryPart

            if not PrimaryPart then
                PrimaryPart = SeatPartParent:FindFirstChild("HumanoidRootPart") or Humanoid.SeatPart
            end

            if PrimaryPart then
                if t1.NoclipEnabled then
                    u20 = SeatPartParent

                    local GetDescendants = SeatPartParent.GetDescendants

                    for _, v in ipairs(GetDescendants(SeatPartParent)) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end

                    local CurrentCameraCFrame = CurrentCamera.CFrame
                    local vector3 = Vector3.new()

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        vector3 += CurrentCameraCFrame.LookVector
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        vector3 -= CurrentCameraCFrame.LookVector
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        vector3 -= CurrentCameraCFrame.RightVector
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        vector3 += CurrentCameraCFrame.RightVector
                    end

                    local n1 = 65

                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        n1 = 160
                    end

                    if vector3.Magnitude > 0 then
                        PrimaryPart.AssemblyLinearVelocity = vector3.Unit * n1
                        PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    else
                        PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end
                else
                    if u20 then
                        for _, descendant in ipairs(u20:GetDescendants()) do
                            if descendant:IsA("BasePart") then
                                descendant.CanCollide = true
                            end
                        end

                        u20 = nil
                    end

                    if t1.TurboEnabled and false then
                        PrimaryPart.AssemblyLinearVelocity = PrimaryPart.AssemblyLinearVelocity + PrimaryPart.CFrame.LookVector * (t1.TurboForce * 3)
                    end

                    local BrakeEnabled = t1.BrakeEnabled

                    if BrakeEnabled then
                        BrakeEnabled = UserInputService:IsKeyDown(Enum.KeyCode.S)
                    end

                    if BrakeEnabled then
                        PrimaryPart.AssemblyLinearVelocity = PrimaryPart.AssemblyLinearVelocity - PrimaryPart.CFrame.LookVector * (t1.BrakeForce * 3)
                    end

                    if t1.BetterHandling then
                        local Steer = Humanoid.Steer

                        if Steer ~= 0 then
                            PrimaryPart.AssemblyAngularVelocity = Vector3.new(PrimaryPart.AssemblyAngularVelocity.X, PrimaryPart.AssemblyAngularVelocity.Y + Steer * 8.5, PrimaryPart.AssemblyAngularVelocity.Z)
                        else
                            PrimaryPart.AssemblyAngularVelocity = Vector3.new(PrimaryPart.AssemblyAngularVelocity.X, PrimaryPart.AssemblyAngularVelocity.Y * 0.9, PrimaryPart.AssemblyAngularVelocity.Z)
                        end
                    end
                end
            end
        elseif u20 then
            for _, descendant in ipairs(u20:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.CanCollide = true
                end
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local v175 = v75(player)
            local Character = player.Character
            local v177 = Character and Character:FindFirstChild("HumanoidRootPart")
            local v178 = Character

            if Character then
                v178 = Character:FindFirstChildOfClass("Humanoid")
            end

            local v179 = false
            local v180 = Character

            if Character then
                v180 = v177

                if v177 then
                    v180 = v178 and v178.Health > 0
                end
            end

            if v180 then
                local v182, t7Result = CurrentCamera:WorldToViewportPoint(v177.Position)
                if t7Result then
                    v179 = true

                    local Head = Character:FindFirstChild("Head")

                    if Head then
                        Head = CurrentCamera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
                    end

                    local v184 = Head or v182
                    local v185 = CurrentCamera:WorldToViewportPoint(v177.Position - Vector3.new(0, 3, 0))
                    local v186 = math.abs(v184.Y - v185.Y)
                    local v187 = v186 / 2

                    if t1.ESPBox then
                        v175.Box.Visible = true
                        v175.Box.Size = Vector2.new(v187, v186)
                        v175.Box.Position = Vector2.new(v182.X - v187 / 2, v184.Y)
                    else
                        v175.Box.Visible = false
                    end

                    if t1.ESPTracer then
                        v175.Tracer.Visible = true
                        v175.Tracer.From = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
                        v175.Tracer.To = Vector2.new(v182.X, v185.Y)
                    else
                        v175.Tracer.Visible = false
                    end

                    if t1.ESPHealth then
                        local v188 = math.clamp(v178.Health / v178.MaxHealth, 0, 1)
                        local v189 = v186 * v188

                        v175.HealthBar.Visible = true
                        v175.HealthBar.Size = Vector2.new(3, v186)
                        v175.HealthBar.Position = Vector2.new(v182.X - v187 / 2 - 6, v184.Y)
                        v175.HealthBarInner.Visible = true
                        v175.HealthBarInner.Size = Vector2.new(1, v189)
                        v175.HealthBarInner.Position = Vector2.new(v182.X - v187 / 2 - 5, v184.Y + (v186 - v189))
                        v175.HealthBarInner.Color = Color3.fromRGB(255 * (1 - v188), 255 * v188, 0)
                    else
                        v175.HealthBar.Visible = false
                        v175.HealthBarInner.Visible = false
                    end

                    if t1.ESPInfo then
                        local v190 = math.floor((CurrentCamera.CFrame.Position - v177.Position).Magnitude)

                        v175.Info.Visible = true
                        v175.Info.Text = player.Name .. " [" .. v190 .. "m]"
                        v175.Info.Position = Vector2.new(v182.X, v184.Y - 18)
                    else
                        v175.Info.Visible = false
                    end
                end
            end

            if not v179 then
                v175.Box.Visible = false
                v175.Tracer.Visible = false
                v175.HealthBar.Visible = false
                v175.HealthBarInner.Visible = false
                v175.Info.Visible = false
            end
        end
    end
end)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        gameProcessed = t1.IsBindingKey
    end

    if gameProcessed then
        return
    end

    if input.KeyCode ~= t1.TurboKey then
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode ~= t1.TurboKey then
    end
end)