-- Lua 5.1 | CDID | Delta / Arceus X
-- Rayfield UI | teleport + engine + ECU + turbo + supercharger + boost slider

local RS              = game:GetService("ReplicatedStorage")
local Players         = game:GetService("Players")
local LocalPlayer     = Players.LocalPlayer
local dataReplication = require(RS.Services.DataReplication)
local ModEvent        = RS.NetworkContainer.RemoteEvents.NewModification

local MODIF_CFRAME = CFrame.new(796.224, 22.347, -3836.699, 0.754, -0.000, -0.657, 0.000, 1.000, -0.000, 0.657, 0.000, 0.754)

-- ─── Scan inventory ───────────────────────────────────────────────────────
local function scanInventory()
    local vehicleData = dataReplication:GetVehicleData()
    local carList     = {}
    for carID, _ in pairs(vehicleData) do
        if RS.CarData:FindFirstChild(carID) then
            table.insert(carList, carID)
        end
    end
    table.sort(carList)
    return carList
end

-- ─── Rayfield ─────────────────────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name                = "Unlocker",
    LoadingTitle        = "Unlocker",
    LoadingSubtitle     = "CDID Engine Unlocker",
    ConfigurationSaving = { Enabled = false },
    Discord             = { Enabled = false },
    KeySystem           = false,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 1 — TELEPORT
-- ═══════════════════════════════════════════════════════════════════════════
local TpTab = Window:CreateTab("Teleport", 4483362458)

TpTab:CreateSection("Lokasi")

TpTab:CreateButton({
    Name     = "Teleport To Modification",
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = MODIF_CFRAME
        Rayfield:Notify({
            Title    = "Teleport",
            Content  = "Sampai di tempat modifikasi.",
            Duration = 3,
        })
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 2 — UNLOCKER
-- ═══════════════════════════════════════════════════════════════════════════
local Tab = Window:CreateTab("Engine", 4483362458)

-- ─── State ────────────────────────────────────────────────────────────────
local fullCarList    = scanInventory()
local selectedCar    = fullCarList[1] or ""

-- toggle flags
local toggleEngine      = false
local toggleECU         = false
local toggleTurbo       = false
local toggleSuperCharger = false

-- selected values
local selectedEngineStage  = "Stage3"
local selectedECUStage     = "Stage3"
local selectedTurboType    = "SingleTurbo"
local selectedTurboBoost   = 25
local selectedSuperBoost   = 25

-- ─── Status ───────────────────────────────────────────────────────────────
Tab:CreateSection("Status")

local StatusParagraph = Tab:CreateParagraph({
    Title   = "Status",
    Content = string.format("Idle. %d mobil di inventory.", #fullCarList)
})

local function SetStatus(text)
    StatusParagraph:Set({ Title = "Status", Content = text })
end

-- ─── Car select ───────────────────────────────────────────────────────────
Tab:CreateSection("Select Car")

local CarDropdown = Tab:CreateDropdown({
    Name          = "Car List (" .. #fullCarList .. " mobil)",
    Options       = fullCarList,
    CurrentOption = { fullCarList[1] or "" },
    Flag          = "SelectedCar",
    Callback      = function(val)
        selectedCar = val[1]
    end
})

Tab:CreateInput({
    Name                     = "Search",
    PlaceholderText          = "Ketik nama mobil...",
    RemoveTextAfterFocusLost = false,
    Flag                     = "SearchQuery",
    Callback                 = function(query)
        local lower    = query:lower()
        local filtered = {}
        for _, carID in ipairs(fullCarList) do
            if carID:lower():find(lower, 1, true) then
                table.insert(filtered, carID)
            end
        end
        if #filtered == 0 then
            SetStatus("Tidak ada hasil: " .. query)
            return
        end
        CarDropdown:Refresh(filtered, true)
        CarDropdown:Set(filtered[1])
        selectedCar = filtered[1]
        SetStatus(string.format("%d hasil untuk '%s'", #filtered, query))
    end
})

Tab:CreateButton({
    Name     = "Scan Inventory",
    Callback = function()
        SetStatus("Scanning...")
        fullCarList = scanInventory()
        if #fullCarList == 0 then
            SetStatus("Tidak ada mobil.")
            return
        end
        CarDropdown:Refresh(fullCarList, true)
        CarDropdown:Set(fullCarList[1])
        selectedCar = fullCarList[1]
        SetStatus(string.format("Scan selesai — %d mobil.", #fullCarList))
        Rayfield:Notify({ Title = "Unlocker", Content = #fullCarList .. " mobil ditemukan.", Duration = 3 })
    end
})

-- ─── Engine Internals ─────────────────────────────────────────────────────
Tab:CreateSection("Engine Internals")

Tab:CreateToggle({
    Name     = "Unlock Engine Internals",
    Flag     = "ToggleEngine",
    Callback = function(val)
        toggleEngine = val
    end
})

Tab:CreateDropdown({
    Name          = "Engine Stage",
    Options       = { "Stage1", "Stage2", "Stage3" },
    CurrentOption = { "Stage3" },
    Flag          = "EngineStage",
    Callback      = function(val)
        selectedEngineStage = val[1]
    end
})

-- ─── ECU ──────────────────────────────────────────────────────────────────
Tab:CreateSection("ECU Remap")

Tab:CreateToggle({
    Name     = "Unlock ECU",
    Flag     = "ToggleECU",
    Callback = function(val)
        toggleECU = val
    end
})

Tab:CreateDropdown({
    Name          = "ECU Stage",
    Options       = { "Stage1", "Stage2", "Stage3" },
    CurrentOption = { "Stage3" },
    Flag          = "ECUStage",
    Callback      = function(val)
        selectedECUStage = val[1]
    end
})

-- ─── Turbo ────────────────────────────────────────────────────────────────
Tab:CreateSection("Turbocharger")

Tab:CreateToggle({
    Name     = "Unlock Turbo",
    Flag     = "ToggleTurbo",
    Callback = function(val)
        toggleTurbo = val
    end
})

Tab:CreateDropdown({
    Name          = "Turbo Type",
    Options       = { "NoTurbo", "SingleTurbo", "TwinTurbo" },
    CurrentOption = { "SingleTurbo" },
    Flag          = "TurboType",
    Callback      = function(val)
        selectedTurboType = val[1]
    end
})

Tab:CreateSlider({
    Name         = "Turbo Boost (0–38)",
    Range        = { 0, 38 },
    Increment    = 1,
    CurrentValue = 25,
    Flag         = "TurboBoost",
    Callback     = function(val)
        selectedTurboBoost = val
    end
})

-- ─── Supercharger ─────────────────────────────────────────────────────────
Tab:CreateSection("Supercharger")

Tab:CreateToggle({
    Name     = "Unlock Supercharger",
    Flag     = "ToggleSuperCharger",
    Callback = function(val)
        toggleSuperCharger = val
    end
})

Tab:CreateSlider({
    Name         = "Super Boost (0–38)",
    Range        = { 0, 38 },
    Increment    = 1,
    CurrentValue = 25,
    Flag         = "SuperBoost",
    Callback     = function(val)
        selectedSuperBoost = val
    end
})

-- ─── Apply ────────────────────────────────────────────────────────────────
Tab:CreateSection("Apply")

local function applyUnlock(carID)
    local mods = {}

    if toggleEngine then
        mods.EngineInternals = selectedEngineStage
    end
    if toggleECU then
        mods.ECU = selectedECUStage
    end
    if toggleTurbo then
        mods.TurboCharger = selectedTurboType
        mods.TurboBoost   = selectedTurboBoost
    end
    if toggleSuperCharger then
        mods.SuperCharger = "SuperCharger"
        mods.SuperBoost   = selectedSuperBoost
    end

    if next(mods) == nil then
        return false, "Tidak ada toggle yang aktif."
    end

    local ok, err = pcall(function()
        ModEvent:FireServer(carID, mods)
    end)

    return ok, err
end

Tab:CreateButton({
    Name     = "Apply To Selected Car",
    Callback = function()
        if selectedCar == "" then
            SetStatus("Pilih mobil dulu.")
            return
        end

        local ok, err = applyUnlock(selectedCar)

        if ok then
            SetStatus("Applied: " .. selectedCar)
            Rayfield:Notify({ Title = "Unlocker", Content = "Applied → " .. selectedCar, Duration = 4 })
        else
            SetStatus("ERROR: " .. tostring(err))
        end
    end
})

Tab:CreateButton({
    Name     = "Apply To All Cars",
    Callback = function()
        local total   = #fullCarList
        local success = 0
        local failed  = 0

        if total == 0 then
            SetStatus("Tidak ada mobil.")
            return
        end

        for i, carID in ipairs(fullCarList) do
            SetStatus(string.format("[%d/%d] %s...", i, total, carID))
            local ok, err = applyUnlock(carID)
            if ok then
                success += 1
            else
                failed  += 1
                warn(string.format("[Unlocker] %s: %s", carID, tostring(err)))
            end
            task.wait(0.35)
        end

        SetStatus(string.format("Done — %d berhasil, %d gagal.", success, failed))
        Rayfield:Notify({ Title = "Unlocker", Content = string.format("%d/%d applied.", success, total), Duration = 5 })
    end
})