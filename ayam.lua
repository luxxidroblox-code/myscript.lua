-- Lua 5.1 | CDID | Delta / Arceus X
-- Rayfield UI | garage → dropdown raw ActualName → unlock

local RS              = game:GetService("ReplicatedStorage")
local dataReplication = require(RS.Services.DataReplication)
local ModEvent        = RS.NetworkContainer.RemoteEvents.NewModification

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

local Window = Rayfield:CreateWindow({
    Name             = "Unlocker",
    LoadingTitle     = "Unlocker",
    LoadingSubtitle  = "CDID Engine Unlocker",
    ConfigurationSaving = { Enabled = false },
    Discord          = { Enabled = false },
    KeySystem        = false,
})

local Tab = Window:CreateTab("Engine", 4483362458)

-- ─── Fetch garage ─────────────────────────────────────────────────────────
local vehicleData = dataReplication:GetVehicleData()
local carList     = {}

for carID, _ in pairs(vehicleData) do
    if RS.CarData:FindFirstChild(carID) then
        table.insert(carList, carID)
    end
end

table.sort(carList)

-- ─── State ────────────────────────────────────────────────────────────────
local selectedCar   = carList[1] or ""
local selectedStage = "Stage3"

-- ─── Status ───────────────────────────────────────────────────────────────
Tab:CreateSection("Status")

local StatusParagraph = Tab:CreateParagraph({
    Title   = "Status",
    Content = "Idle."
})

local function SetStatus(text)
    StatusParagraph:Set({ Title = "Status", Content = text })
end

-- ─── Car dropdown ─────────────────────────────────────────────────────────
Tab:CreateSection("Select Car")

Tab:CreateDropdown({
    Name          = "Car List (" .. #carList .. " mobil)",
    Options       = carList,
    CurrentOption = { carList[1] },
    Flag          = "SelectedCar",
    Callback      = function(val)
        selectedCar = val[1]
    end
})

-- ─── Stage dropdown ───────────────────────────────────────────────────────
Tab:CreateDropdown({
    Name          = "Engine Stage",
    Options       = { "Stage1", "Stage2", "Stage3" },
    CurrentOption = { "Stage3" },
    Flag          = "EngineStage",
    Callback      = function(val)
        selectedStage = val[1]
    end
})

-- ─── Unlock selected ──────────────────────────────────────────────────────
Tab:CreateButton({
    Name     = "Unlock Selected Car",
    Callback = function()
        if selectedCar == "" then
            SetStatus("Pilih mobil dulu.")
            return
        end

        local ok, err = pcall(function()
            ModEvent:FireServer(selectedCar, {
                EngineInternals = selectedStage
            })
        end)

        if ok then
            SetStatus(string.format("Unlocked: %s → %s", selectedCar, selectedStage))
            Rayfield:Notify({
                Title    = "Unlocker",
                Content  = selectedCar .. " → " .. selectedStage,
                Duration = 4,
            })
        else
            SetStatus("ERROR: " .. tostring(err))
        end
    end
})

-- ─── Unlock all ───────────────────────────────────────────────────────────
Tab:CreateButton({
    Name     = "Unlock All Cars",
    Callback = function()
        local total   = #carList
        local success = 0
        local failed  = 0

        SetStatus(string.format("Unlocking %d mobil...", total))

        for _, carID in ipairs(carList) do
            local ok, err = pcall(function()
                ModEvent:FireServer(carID, {
                    EngineInternals = selectedStage
                })
            end)

            if ok then
                success += 1
            else
                failed  += 1
                warn(string.format("[Unlocker] %s: %s", carID, tostring(err)))
            end

            SetStatus(string.format("Progress: %d / %d", success + failed, total))
            task.wait(0.35)
        end

        SetStatus(string.format("Done — %d berhasil, %d gagal.", success, failed))
        Rayfield:Notify({
            Title    = "Unlocker",
            Content  = string.format("%d/%d unlocked ke %s", success, total, selectedStage),
            Duration = 5,
        })
    end
})