local marketplaceService = game:GetService("MarketplaceService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")
local workspace = game:GetService("Workspace")
local v1, v2 = pcall(function() return marketplaceService:GetProductInfo(game.PlaceId) end)
local name = v1 and v2.Name or ""

local f1, localPlayer, currentCamera, v3, v4, v5, v6, screenGui, f2, frame, instance, instance2,
  instance3, v7, v8, v9, v10, instance4, instance5, instance6, instance7, v11, instance8,
  instance9, instance10, v12, instance11, instance12, instance13, v13, f3

if not string.find(string.lower(name), "tr legacy") then
  local trLegacyError = Instance.new("ScreenGui")
  trLegacyError.Name = "TR_Legacy_Error"
  trLegacyError.Parent = coreGui

  local instance14 = Instance.new("Frame", trLegacyError)
  instance14.Size = UDim2.new(0, 380, 0, 110)
  instance14.Position = UDim2.new(0.5, -190, 0.5, -55)
  instance14.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
  instance14.BorderSizePixel = 0

  Instance.new("UICorner", instance14).CornerRadius = UDim.new(0, 10)

  local instance15 = Instance.new("TextLabel", instance14)
  instance15.Size = UDim2.new(1, -20, 1, 0)
  instance15.Position = UDim2.new(0, 10, 0, 0)
  instance15.BackgroundTransparency = 1

  instance15.Text = "âŒ ACCESO DENEGADO\n\nEste script solo funciona en el juego TR Legacy.\nDetectado: "
    .. (name ~= "" and name or "Desconocido") .. "\nEl script se ha detenido."

  instance15.TextColor3 = Color3.fromRGB(255, 100, 100)
  instance15.TextSize = 12
  instance15.Font = Enum.Font.GothamBold
  instance15.TextWrapped = true

  task.wait(6)
  trLegacyError:Destroy()
  return
else
  localPlayer = players.LocalPlayer
  currentCamera = workspace.CurrentCamera

  v3 = {
    TurboEnabled = false,
    TurboForce = 5,
    BrakeEnabled = false,
    BrakeForce = 5,
    NoclipEnabled = false,
    TurboKey = Enum.KeyCode.E,
    IsBindingKey = false,
    BetterHandling = false,
    ESPBox = false,
    ESPTracer = false,
    ESPHealth = false,
    ESPInfo = false,
    SelectedPlayer = nil,
    IsSpectating = false,
  }

  v4 = false
  v5 = {}
  v6 = nil

  screenGui = Instance.new("ScreenGui")
  screenGui.Name = "TRLegacyMenu_" .. tostring(math.random(1000, 9999))

  if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = coreGui
  elseif gethui then
    screenGui.Parent = gethui()
  else
    screenGui.Parent = coreGui
  end

  screenGui.ResetOnSpawn = false
  screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

  function f2(parent, p1)
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, p1 or 8)
    uiCorner.Parent = parent

    return uiCorner
  end

  frame = Instance.new("Frame")
  frame.Size = UDim2.new(0, 520, 0, 480)
  frame.Position = UDim2.new(0.5, -260, 0.5, -240)
  frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
  frame.BorderSizePixel = 0
  frame.Active = true
  frame.Draggable = true
  frame.Parent = screenGui

  f2(frame, 12)

  local instance16 = Instance.new("Frame", frame)
  instance16.Size = UDim2.new(1, 0, 0, 40)
  instance16.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
  instance16.BorderSizePixel = 0

  f2(instance16, 12)

  local instance17 = Instance.new("TextLabel", instance16)
  instance17.Size = UDim2.new(1, -90, 1, 0)
  instance17.Position = UDim2.new(0, 15, 0, 0)
  instance17.BackgroundTransparency = 1
  instance17.Text = "âš™ï¸ TR Legacy MENU + Noclip Vehicular con Colisiones"
  instance17.TextColor3 = Color3.fromRGB(255, 255, 255)
  instance17.TextSize = 13
  instance17.Font = Enum.Font.GothamBold
  instance17.TextXAlignment = Enum.TextXAlignment.Left

  local instance18 = Instance.new("TextButton", instance16)
  instance18.Size = UDim2.new(0, 30, 0, 30)
  instance18.Position = UDim2.new(1, -35, 0.5, -15)
  instance18.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
  instance18.Text = "X"
  instance18.TextColor3 = Color3.fromRGB(255, 255, 255)
  instance18.TextSize = 12
  instance18.Font = Enum.Font.GothamBold

  f2(instance18, 6)

  instance = Instance.new("Frame", frame)
  instance.Size = UDim2.new(1, 0, 0, 35)
  instance.Position = UDim2.new(0, 0, 0, 40)
  instance.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
  instance.BorderSizePixel = 0

  instance2 = Instance.new("Frame", frame)
  instance2.Size = UDim2.new(1, -20, 1, -95)
  instance2.Position = UDim2.new(0, 10, 0, 85)
  instance2.BackgroundTransparency = 1

  instance3 = Instance.new("TextButton", instance16)
  instance3.Size = UDim2.new(0, 30, 0, 30)
  instance3.Position = UDim2.new(1, -70, 0.5, -15)
  instance3.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
  instance3.Text = "-"
  instance3.TextColor3 = Color3.fromRGB(255, 255, 255)
  instance3.TextSize = 14
  instance3.Font = Enum.Font.GothamBold

  f2(instance3, 6)
  v7 = false

  instance3.MouseButton1Click:Connect(function()
    v7 = not v7

    if v7 then
      instance3.Text = "+"
      frame.Size = UDim2.new(0, 520, 0, 40)
      instance.Visible = false
      instance2.Visible = false
    else
      instance3.Text = "-"
      frame.Size = UDim2.new(0, 520, 0, 480)
      instance.Visible = true
      instance2.Visible = true
    end
  end)

  instance18.MouseButton1Click:Connect(function()
    if v6 then
      for index, value in ipairs(v6:GetDescendants()) do
        if value:IsA("BasePart") then
          value.CanCollide = true
        end
      end
    end

    screenGui:Destroy()

    for key, value2 in pairs(v5) do
      for key2, value3 in pairs(value2) do
        local v14 = value3
        pcall(function() v14:Remove() end)
      end
    end
  end)

  local v15 = { "VehÃ­culo & Turbo", "ESP Profesional", "Lista de Jugadores" }
  v8 = {}
  v9 = {}
  v10 = "VehÃ­culo & Turbo"

  for index2, value4 in ipairs(v15) do
    local v16 = value4

    local instance19 = Instance.new("TextButton", instance)
    instance19.Size = UDim2.new(1 / #v15, 0, 1, 0)
    instance19.Position = UDim2.new((index2 - 1) * (1 / #v15), 0, 0, 0)

    instance19.BackgroundColor3 = v16 == v10 and Color3.fromRGB(40, 40, 50)
      or Color3.fromRGB(25, 25, 30)

    instance19.Text = v16
    instance19.TextColor3 = Color3.fromRGB(220, 220, 220)
    instance19.TextSize = 11
    instance19.Font = Enum.Font.Gotham
    instance19.BorderSizePixel = 0
    instance19.AutoButtonColor = false

    v8[v16] = instance19

    local instance20 = Instance.new("ScrollingFrame", instance2)
    instance20.Size = UDim2.new(1, 0, 1, 0)
    instance20.BackgroundTransparency = 1
    instance20.Visible = v16 == v10
    instance20.CanvasSize = UDim2.new(0, 0, 0, 0)
    instance20.AutomaticCanvasSize = Enum.AutomaticSize.Y
    instance20.ScrollBarThickness = 4

    local instance21 = Instance.new("UIListLayout", instance20)
    instance21.SortOrder = Enum.SortOrder.LayoutOrder
    instance21.Padding = UDim.new(0, 10)

    v9[v16] = instance20

    instance19.MouseButton1Click:Connect(function()
      v10 = v16

      for key3, value5 in pairs(v8) do
        value5.BackgroundColor3 = key3 == v16 and Color3.fromRGB(40, 40, 50)
          or Color3.fromRGB(25, 25, 30)
      end

      for key4, value6 in pairs(v9) do
        value6.Visible = key4 == v16
      end
    end)
  end

  local function f4(parent2, text)
    local frame2 = Instance.new("Frame")
    frame2.Size = UDim2.new(1, 0, 0, 140)
    frame2.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame2.BorderSizePixel = 0
    frame2.Parent = parent2

    f2(frame2, 8)

    local instance22 = Instance.new("TextLabel", frame2)
    instance22.Size = UDim2.new(1, -15, 0, 30)
    instance22.Position = UDim2.new(0, 15, 0, 0)
    instance22.BackgroundTransparency = 1
    instance22.Text = text
    instance22.TextColor3 = Color3.fromRGB(150, 150, 150)
    instance22.TextSize = 11
    instance22.Font = Enum.Font.GothamBold
    instance22.TextXAlignment = Enum.TextXAlignment.Left

    local instance23 = Instance.new("UIListLayout", frame2)
    instance23.SortOrder = Enum.SortOrder.LayoutOrder
    instance23.Padding = UDim.new(0, 8)

    return frame2
  end

  local function f5(p2, text2, fn)
    local instance24 = Instance.new("Frame", p2)
    instance24.Size = UDim2.new(1, -30, 0, 30)
    instance24.BackgroundTransparency = 1

    local instance25 = Instance.new("TextLabel", instance24)
    instance25.Size = UDim2.new(0.7, 0, 1, 0)
    instance25.BackgroundTransparency = 1
    instance25.Text = text2
    instance25.TextColor3 = Color3.fromRGB(220, 220, 220)
    instance25.TextSize = 11
    instance25.Font = Enum.Font.Gotham
    instance25.TextXAlignment = Enum.TextXAlignment.Left

    local instance26 = Instance.new("TextButton", instance24)
    instance26.Size = UDim2.new(0, 40, 0, 22)
    instance26.Position = UDim2.new(1, -40, 0.5, -11)
    instance26.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    instance26.Text = ""
    instance26.AutoButtonColor = false

    f2(instance26, 11)

    local instance27 = Instance.new("Frame", instance26)
    instance27.Size = UDim2.new(0, 18, 0, 18)
    instance27.Position = UDim2.new(0, 2, 0.5, -9)
    instance27.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

    f2(instance27, 9)
    local v17 = false

    instance26.MouseButton1Click:Connect(function()
      v17 = not v17

      instance26.BackgroundColor3 = v17 and Color3.fromRGB(100, 200, 100)
        or Color3.fromRGB(60, 60, 60)

      instance27.Position = v17 and UDim2.new(0, 20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
      fn(v17)
    end)
  end

  local v18 = f4(v9["VehÃ­culo & Turbo"], "CONFIGURACIÃ“N DE TURBO, FRENO Y NOCLIP")
  v18.Size = UDim2.new(1, 0, 0, 410)

  f5(v18, "Activar Turbo en VehÃ­culos", function(turboEnabled)
    v3.TurboEnabled = turboEnabled
  end)

  f5(v18, "Activar Freno Inverso (Tecla S)", function(brakeEnabled)
    v3.BrakeEnabled = brakeEnabled
  end)

  f5(v18, "Manejo Pro (Giro Ultra)", function(betterHandling)
    v3.BetterHandling = betterHandling
  end)

  f5(v18, "Noclip con VehÃ­culo (Shift corre mÃ¡s)", function(p3)
    v3.NoclipEnabled = p3

    if not p3 and v6 then
      for index3, value7 in ipairs(v6:GetDescendants()) do
        if value7:IsA("BasePart") then
          value7.CanCollide = true
        end
      end

      v6 = nil
    end
  end)

  local instance28 = Instance.new("Frame", v18)
  instance28.Size = UDim2.new(1, -30, 0, 30)
  instance28.BackgroundTransparency = 1

  local instance29 = Instance.new("TextLabel", instance28)
  instance29.Size = UDim2.new(0.6, 0, 1, 0)
  instance29.BackgroundTransparency = 1
  instance29.Text = "Tecla de Turbo"
  instance29.TextColor3 = Color3.fromRGB(220, 220, 220)
  instance29.TextSize = 11
  instance29.Font = Enum.Font.Gotham
  instance29.TextXAlignment = Enum.TextXAlignment.Left

  instance4 = Instance.new("TextButton", instance28)
  instance4.Size = UDim2.new(0, 90, 0, 24)
  instance4.Position = UDim2.new(1, -90, 0.5, -12)
  instance4.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
  instance4.Text = v3.TurboKey.Name
  instance4.TextColor3 = Color3.fromRGB(255, 255, 255)
  instance4.TextSize = 11
  instance4.Font = Enum.Font.GothamBold

  f2(instance4, 6)

  instance4.MouseButton1Click:Connect(function()
    v3.IsBindingKey = true
    instance4.Text = "..."
  end)

  userInputService.InputBegan:Connect(function(input, p4)
    if v3.IsBindingKey and input.UserInputType == Enum.UserInputType.Keyboard then
      v3.TurboKey = input.KeyCode
      instance4.Text = input.KeyCode.Name
      v3.IsBindingKey = false
    end
  end)

  local instance30 = Instance.new("Frame", v18)
  instance30.Size = UDim2.new(1, -30, 0, 45)
  instance30.BackgroundTransparency = 1

  local instance31 = Instance.new("TextLabel", instance30)
  instance31.Size = UDim2.new(0.7, 0, 0, 20)
  instance31.BackgroundTransparency = 1
  instance31.Text = "Fuerza del Turbo"
  instance31.TextColor3 = Color3.fromRGB(220, 220, 220)
  instance31.TextSize = 11
  instance31.Font = Enum.Font.Gotham
  instance31.TextXAlignment = Enum.TextXAlignment.Left

  instance5 = Instance.new("TextLabel", instance30)
  instance5.Size = UDim2.new(0.3, 0, 0, 20)
  instance5.Position = UDim2.new(0.7, 0, 0, 0)
  instance5.BackgroundTransparency = 1
  instance5.Text = tostring(v3.TurboForce) .. "x"
  instance5.TextColor3 = Color3.fromRGB(150, 150, 150)
  instance5.TextSize = 11
  instance5.Font = Enum.Font.Gotham
  instance5.TextXAlignment = Enum.TextXAlignment.Right

  instance6 = Instance.new("TextButton", instance30)
  instance6.Size = UDim2.new(1, 0, 0, 6)
  instance6.Position = UDim2.new(0, 0, 0, 25)
  instance6.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
  instance6.Text = ""
  instance6.AutoButtonColor = false

  f2(instance6, 3)

  instance7 = Instance.new("Frame", instance6)
  instance7.Size = UDim2.new((v3.TurboForce - 1) / 19, 0, 1, 0)
  instance7.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
  instance7.BorderSizePixel = 0

  f2(instance7, 3)
  v11 = false

  instance6.InputBegan:Connect(function(input2)
    if input2.UserInputType == Enum.UserInputType.MouseButton1 then
      v11 = true
    end
  end)

  userInputService.InputEnded:Connect(function(input3)
    if input3.UserInputType == Enum.UserInputType.MouseButton1 then
      v11 = false
    end
  end)

  userInputService.InputChanged:Connect(function(input4)
    if v11 and input4.UserInputType == Enum.UserInputType.MouseMovement then
      local v19 = math.clamp((input4.Position.X - instance6.AbsolutePosition.X)
        / instance6.AbsoluteSize.X, 0, 1)

      v3.TurboForce = math.floor(1 + 19 * v19)
      instance7.Size = UDim2.new(v19, 0, 1, 0)
      instance5.Text = tostring(v3.TurboForce) .. "x"
    end
  end)

  local instance32 = Instance.new("Frame", v18)
  instance32.Size = UDim2.new(1, -30, 0, 45)
  instance32.BackgroundTransparency = 1

  local instance33 = Instance.new("TextLabel", instance32)
  instance33.Size = UDim2.new(0.7, 0, 0, 20)
  instance33.BackgroundTransparency = 1
  instance33.Text = "Fuerza de Freno Inverso (Tecla S)"
  instance33.TextColor3 = Color3.fromRGB(220, 220, 220)
  instance33.TextSize = 11
  instance33.Font = Enum.Font.Gotham
  instance33.TextXAlignment = Enum.TextXAlignment.Left

  instance8 = Instance.new("TextLabel", instance32)
  instance8.Size = UDim2.new(0.3, 0, 0, 20)
  instance8.Position = UDim2.new(0.7, 0, 0, 0)
  instance8.BackgroundTransparency = 1
  instance8.Text = tostring(v3.BrakeForce) .. "x"
  instance8.TextColor3 = Color3.fromRGB(150, 150, 150)
  instance8.TextSize = 11
  instance8.Font = Enum.Font.Gotham
  instance8.TextXAlignment = Enum.TextXAlignment.Right

  instance9 = Instance.new("TextButton", instance32)
  instance9.Size = UDim2.new(1, 0, 0, 6)
  instance9.Position = UDim2.new(0, 0, 0, 25)
  instance9.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
  instance9.Text = ""
  instance9.AutoButtonColor = false

  f2(instance9, 3)

  instance10 = Instance.new("Frame", instance9)
  instance10.Size = UDim2.new((v3.BrakeForce - 1) / 19, 0, 1, 0)
  instance10.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
  instance10.BorderSizePixel = 0

  f2(instance10, 3)
  v12 = false

  instance9.InputBegan:Connect(function(input5)
    if input5.UserInputType == Enum.UserInputType.MouseButton1 then
      v12 = true
    end
  end)

  userInputService.InputEnded:Connect(function(input6)
    if input6.UserInputType == Enum.UserInputType.MouseButton1 then
      v12 = false
    end
  end)

  userInputService.InputChanged:Connect(function(input7)
    if v12 and input7.UserInputType == Enum.UserInputType.MouseMovement then
      local v20 = math.clamp((input7.Position.X - instance9.AbsolutePosition.X)
        / instance9.AbsoluteSize.X, 0, 1)

      v3.BrakeForce = math.floor(1 + 19 * v20)
      instance10.Size = UDim2.new(v20, 0, 1, 0)
      instance8.Text = tostring(v3.BrakeForce) .. "x"
    end
  end)

  local v21 = f4(v9["ESP Profesional"], "OPCIONES DE ESP")
  v21.Size = UDim2.new(1, 0, 0, 180)

  f5(v21, "Caja 2D (Box ESP)", function(espBox) v3.ESPBox = espBox end)
  f5(v21, "LÃ­neas de Rastreo (Tracers)", function(espTracer) v3.ESPTracer = espTracer end)
  f5(v21, "Barra de Vida (Health Bar)", function(espHealth) v3.ESPHealth = espHealth end)
  f5(v21, "Nombre y Distancia", function(espInfo) v3.ESPInfo = espInfo end)

  local listaDeJugadores = v9["Lista de Jugadores"]

  local instance34 = Instance.new("Frame", listaDeJugadores)
  instance34.Size = UDim2.new(1, 0, 0, 95)
  instance34.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
  instance34.BorderSizePixel = 0

  f2(instance34, 8)

  local instance35 = Instance.new("TextLabel", instance34)
  instance35.Size = UDim2.new(1, -20, 0, 25)
  instance35.Position = UDim2.new(0, 10, 0, 5)
  instance35.BackgroundTransparency = 1
  instance35.Text = "OBJETIVO SELECCIONADO:"
  instance35.TextColor3 = Color3.fromRGB(150, 150, 150)
  instance35.TextSize = 10
  instance35.Font = Enum.Font.GothamBold
  instance35.TextXAlignment = Enum.TextXAlignment.Left

  instance11 = Instance.new("TextLabel", instance34)
  instance11.Size = UDim2.new(1, -20, 0, 25)
  instance11.Position = UDim2.new(0, 10, 0, 25)
  instance11.BackgroundTransparency = 1
  instance11.Text = "Ninguno (Selecciona abajo)"
  instance11.TextColor3 = Color3.fromRGB(100, 150, 255)
  instance11.TextSize = 13
  instance11.Font = Enum.Font.GothamBold
  instance11.TextXAlignment = Enum.TextXAlignment.Left

  local instance36 = Instance.new("Frame", instance34)
  instance36.Size = UDim2.new(1, -20, 0, 32)
  instance36.Position = UDim2.new(0, 10, 0, 55)
  instance36.BackgroundTransparency = 1

  local instance37 = Instance.new("TextButton", instance36)
  instance37.Size = UDim2.new(0.48, 0, 1, 0)
  instance37.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
  instance37.Text = "âš¡ Teleportarse"
  instance37.TextColor3 = Color3.fromRGB(255, 255, 255)
  instance37.TextSize = 11
  instance37.Font = Enum.Font.GothamBold

  f2(instance37, 6)

  instance12 = Instance.new("TextButton", instance36)
  instance12.Size = UDim2.new(0.48, 0, 1, 0)
  instance12.Position = UDim2.new(0.52, 0, 0, 0)
  instance12.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
  instance12.Text = "ðŸ‘ï¸ Espectear"
  instance12.TextColor3 = Color3.fromRGB(255, 255, 255)
  instance12.TextSize = 11
  instance12.Font = Enum.Font.GothamBold

  f2(instance12, 6)

  instance37.MouseButton1Click:Connect(function()
    if v3.SelectedPlayer and v3.SelectedPlayer.Character
      and v3.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
      local humanoidRootPart = localPlayer.Character
        and localPlayer.Character:FindFirstChild("HumanoidRootPart")

      if humanoidRootPart then
        humanoidRootPart.CFrame = v3.SelectedPlayer.Character.HumanoidRootPart.CFrame
          + Vector3.new(0, 3, 0)
      end
    end
  end)

  instance12.MouseButton1Click:Connect(function()
    v3.IsSpectating = not v3.IsSpectating

    if v3.IsSpectating and v3.SelectedPlayer and v3.SelectedPlayer.Character then
      local humanoid = v3.SelectedPlayer.Character:FindFirstChildOfClass("Humanoid")

      if humanoid then
        currentCamera.CameraSubject = humanoid
        instance12.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        instance12.Text = "ðŸ‘ï¸ Especteando (Activo)"
      end
    else
      if localPlayer.Character then
        local humanoid2 = localPlayer.Character:FindFirstChildOfClass("Humanoid")

        if humanoid2 then
          currentCamera.CameraSubject = humanoid2
        end
      end

      instance12.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
      instance12.Text = "ðŸ‘ï¸ Espectear"

      v3.IsSpectating = false
    end
  end)

  local instance38 = Instance.new("Frame", listaDeJugadores)
  instance38.Size = UDim2.new(1, 0, 0, 210)
  instance38.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
  instance38.BorderSizePixel = 0

  f2(instance38, 8)

  local instance39 = Instance.new("TextLabel", instance38)
  instance39.Size = UDim2.new(1, -15, 0, 30)
  instance39.Position = UDim2.new(0, 15, 0, 0)
  instance39.BackgroundTransparency = 1
  instance39.Text = "JUGADORES EN LÃNEA (Haz clic para seleccionar)"
  instance39.TextColor3 = Color3.fromRGB(150, 150, 150)
  instance39.TextSize = 10
  instance39.Font = Enum.Font.GothamBold
  instance39.TextXAlignment = Enum.TextXAlignment.Left

  instance13 = Instance.new("ScrollingFrame", instance38)
  instance13.Size = UDim2.new(1, -16, 1, -35)
  instance13.Position = UDim2.new(0, 8, 0, 30)
  instance13.BackgroundTransparency = 1
  instance13.CanvasSize = UDim2.new(0, 0, 0, 0)
  instance13.AutomaticCanvasSize = Enum.AutomaticSize.Y
  instance13.ScrollBarThickness = 3

  local instance40 = Instance.new("UIListLayout", instance13)
  instance40.SortOrder = Enum.SortOrder.LayoutOrder
  instance40.Padding = UDim.new(0, 5)

  v13 = {}

  function f3()
    for key5, value8 in pairs(v13) do
      value8:Destroy()
    end

    table.clear(v13)

    for index4, value9 in ipairs(players:GetPlayers()) do
      local v22 = value9

      if v22 ~= localPlayer then
        local instance41 = Instance.new("TextButton", instance13)
        instance41.Size = UDim2.new(1, -5, 0, 32)

        instance41.BackgroundColor3 = v3.SelectedPlayer == v22 and Color3.fromRGB(50, 80, 130)
          or Color3.fromRGB(35, 35, 42)

        instance41.Text = "  " .. v22.Name .. " (@" .. v22.DisplayName .. ")"
        instance41.TextColor3 = Color3.fromRGB(220, 220, 220)
        instance41.TextSize = 11
        instance41.Font = Enum.Font.Gotham
        instance41.TextXAlignment = Enum.TextXAlignment.Left
        instance41.AutoButtonColor = false

        f2(instance41, 6)

        instance41.MouseButton1Click:Connect(function()
          v3.SelectedPlayer = v22
          instance11.Text = v22.Name .. " (@" .. v22.DisplayName .. ")"
          f3()
        end)

        v13[v22] = instance41
      end
    end
  end

  function f1(p5)
    if not v5[p5] then
      v5[p5] = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        HealthBar = Drawing.new("Square"),
        HealthBarInner = Drawing.new("Square"),
        Info = Drawing.new("Text"),
      }

      local v23 = v5[p5]
      v23.Box.Thickness = 1.5
      v23.Box.Filled = false
      v23.Box.Color = Color3.fromRGB(0, 255, 150)
      v23.Tracer.Thickness = 1
      v23.Tracer.Color = Color3.fromRGB(0, 255, 150)
      v23.HealthBar.Thickness = 1
      v23.HealthBar.Filled = true
      v23.HealthBar.Color = Color3.fromRGB(0, 0, 0)
      v23.HealthBarInner.Thickness = 1
      v23.HealthBarInner.Filled = true
      v23.HealthBarInner.Color = Color3.fromRGB(0, 255, 0)
      v23.Info.Size = 12
      v23.Info.Center = true
      v23.Info.Outline = true
      v23.Info.Color = Color3.fromRGB(255, 255, 255)
    end

    return v5[p5]
  end

  players.PlayerAdded:Connect(f3)
  players.PlayerRemoving:Connect(f3)

  f3()

  players.PlayerRemoving:Connect(function(player)
    if v5[player] then
      for key6, value10 in pairs(v5[player]) do
        local v24 = value10
        pcall(function() v24:Remove() end)
      end

      v5[player] = nil
    end

    if v3.SelectedPlayer == player then
      v3.SelectedPlayer = nil
    end
  end)

  runService.RenderStepped:Connect(function()
    if localPlayer.Character then
      local humanoid3 = localPlayer.Character:FindFirstChildOfClass("Humanoid")

      if humanoid3 and humanoid3.SeatPart
        and (humanoid3.SeatPart:IsA("VehicleSeat") or humanoid3.SeatPart:IsA("Seat")) then
        local parent3 = humanoid3.SeatPart.Parent

        local primaryPart = parent3.PrimaryPart or parent3:FindFirstChild("HumanoidRootPart")
          or humanoid3.SeatPart

        if primaryPart then
          if v3.NoclipEnabled then
            v6 = parent3

            for index5, value11 in ipairs(parent3:GetDescendants()) do
              if value11:IsA("BasePart") then
                value11.CanCollide = false
              end
            end

            local cframe = currentCamera.CFrame
            local vector = Vector3.new()

            if userInputService:IsKeyDown(Enum.KeyCode.W) then
              vector = vector + cframe.LookVector
            end

            if userInputService:IsKeyDown(Enum.KeyCode.S) then
              vector = vector - cframe.LookVector
            end

            if userInputService:IsKeyDown(Enum.KeyCode.A) then
              vector = vector - cframe.RightVector
            end

            if userInputService:IsKeyDown(Enum.KeyCode.D) then
              vector = vector + cframe.RightVector
            end

            local v25 = 65

            if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
              v25 = 160
            end

            if vector.Magnitude > 0 then
              primaryPart.AssemblyLinearVelocity = vector.Unit * v25
              primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            else
              primaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
              primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
          else
            if v6 then
              for index6, value12 in ipairs(v6:GetDescendants()) do
                if value12:IsA("BasePart") then
                  value12.CanCollide = true
                end
              end

              v6 = nil
            end

            if v3.TurboEnabled and v4 then
              primaryPart.AssemblyLinearVelocity = primaryPart.AssemblyLinearVelocity
                + primaryPart.CFrame.LookVector * (v3.TurboForce * 3)
            end

            if v3.BrakeEnabled and userInputService:IsKeyDown(Enum.KeyCode.S) then
              primaryPart.AssemblyLinearVelocity = primaryPart.AssemblyLinearVelocity
                - primaryPart.CFrame.LookVector * (v3.BrakeForce * 3)
            end

            if v3.BetterHandling then
              local steer = humanoid3.Steer

              if steer ~= 0 then
                primaryPart.AssemblyAngularVelocity = Vector3.new(primaryPart.AssemblyAngularVelocity.X, primaryPart.AssemblyAngularVelocity.Y
                  + steer * 8.5, primaryPart.AssemblyAngularVelocity.Z)
              else
                primaryPart.AssemblyAngularVelocity = Vector3.new(primaryPart.AssemblyAngularVelocity.X, primaryPart.AssemblyAngularVelocity.Y
                  * 0.9, primaryPart.AssemblyAngularVelocity.Z)
              end
            end
          end
        end
      elseif v6 then
        for index7, value13 in ipairs(v6:GetDescendants()) do
          if value13:IsA("BasePart") then
            value13.CanCollide = true
          end
        end

        v6 = nil
      end
    end

    for index8, value14 in ipairs(players:GetPlayers()) do
      if value14 ~= localPlayer then
        local v26 = f1(value14)
        local character = value14.Character

        local humanoidRootPart2 = character
        humanoidRootPart2 = character and character:FindFirstChild("HumanoidRootPart")

        local humanoid4 = character
        humanoid4 = character and character:FindFirstChildOfClass("Humanoid")

        local v27 = false

        if character and humanoidRootPart2 and humanoid4 and humanoid4.Health > 0 then
          local v28, v29 = currentCamera:WorldToViewportPoint(humanoidRootPart2.Position)

          if v29 then
            v27 = true
            local head = character:FindFirstChild("Head")

            local worldToViewportPoint = head and currentCamera:WorldToViewportPoint(head.Position + Vector3.new(
              0, 0.5, 0
            )) or v28

            local worldToViewportPoint2 = currentCamera:WorldToViewportPoint(humanoidRootPart2.Position
              - Vector3.new(0, 3, 0))

            local v30 = math.abs(worldToViewportPoint.Y - worldToViewportPoint2.Y)
            local v31 = v30 / 2

            if v3.ESPBox then
              v26.Box.Visible = true
              v26.Box.Size = Vector2.new(v31, v30)
              v26.Box.Position = Vector2.new(v28.X - v31 / 2, worldToViewportPoint.Y)
            else
              v26.Box.Visible = false
            end

            if v3.ESPTracer then
              v26.Tracer.Visible = true

              v26.Tracer.From = Vector2.new(
                currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y
              )

              v26.Tracer.To = Vector2.new(v28.X, worldToViewportPoint2.Y)
            else
              v26.Tracer.Visible = false
            end

            if v3.ESPHealth then
              local v32 = math.clamp(humanoid4.Health / humanoid4.MaxHealth, 0, 1)
              local v33 = v30 * v32

              v26.HealthBar.Visible = true
              v26.HealthBar.Size = Vector2.new(3, v30)
              v26.HealthBar.Position = Vector2.new(v28.X - v31 / 2 - 6, worldToViewportPoint.Y)
              v26.HealthBarInner.Visible = true
              v26.HealthBarInner.Size = Vector2.new(1, v33)

              v26.HealthBarInner.Position = Vector2.new(
                v28.X - v31 / 2 - 5, worldToViewportPoint.Y + (v30 - v33)
              )

              v26.HealthBarInner.Color = Color3.fromRGB(255 * (1 - v32), 255 * v32, 0)
            else
              v26.HealthBar.Visible = false
              v26.HealthBarInner.Visible = false
            end

            if v3.ESPInfo then
              local v34 = math.floor((currentCamera.CFrame.Position - humanoidRootPart2.Position).Magnitude)

              v26.Info.Visible = true
              v26.Info.Text = value14.Name .. " [" .. v34 .. "m]"
              v26.Info.Position = Vector2.new(v28.X, worldToViewportPoint.Y - 18)
            else
              v26.Info.Visible = false
            end
          end
        end

        if not v27 then
          v26.Box.Visible = false
          v26.Tracer.Visible = false
          v26.HealthBar.Visible = false
          v26.HealthBarInner.Visible = false
          v26.Info.Visible = false
        end
      end
    end
  end)

  userInputService.InputBegan:Connect(function(input8, p6)
    if p6 or v3.IsBindingKey then
      return
    end

    if input8.KeyCode == v3.TurboKey then
      v4 = true
    end
  end)

  userInputService.InputEnded:Connect(function(input9)
    if input9.KeyCode == v3.TurboKey then
      v4 = false
    end
  end)

  return
end