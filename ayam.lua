-- Lua 5.1 | CDID | Delta / Arceus X
-- Rayfield UI | dataReplication:GetVehicleData() → NewModification

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

-- ─── Status label ─────────────────────────────────────────────────────────
local StatusSection = Tab:CreateSection("Status")

local StatusParagraph = Tab:CreateParagraph({
    Title   = "Status",
    Content = "Idle."
})

local function SetStatus(text)
    StatusParagraph:Set({
        Title   = "Status",
        Content = text
    })
end

-- ─── Stage dropdown ───────────────────────────────────────────────────────
local selectedStage = "Stage3"

Tab:CreateDropdown({
    Name    = "Engine Stage",
    Options = { "Stage1", "Stage2", "Stage3" },
    CurrentOption = { "Stage3" },
    Flag    = "EngineStage",
    Callback = function(val)
        selectedStage = val[1]
    end
})

-- ─── Delay slider ─────────────────────────────────────────────────────────
local fireDelay = 0.35

Tab:CreateSlider({
    Name    = "Fire Delay (s)",
    Range   = { 0.1, 2.0 },
    Increment = 0.05,
    CurrentValue = 0.35,
    Flag    = "FireDelay",
    Callback = function(val)
        fireDelay = val
    end
})

-- ─── Unlock button ────────────────────────────────────────────────────────
Tab:CreateButton({
    Name     = "Unlock All Cars",
    Callback = function()
        SetStatus("Fetching garage...")

        local vehicleData = dataReplication:GetVehicleData()

        if type(vehicleData) ~= "table" then
            SetStatus("ERROR: GetVehicleData() tidak return table.")
            return
        end

        local carList = {}

        for carID, _ in pairs(vehicleData) do
            if RS.CarData:FindFirstChild(carID) then
                table.insert(carList, carID)
            end
        end

        if #carList == 0 then
            SetStatus("Tidak ada mobil ditemukan di garage.")
            return
        end

        SetStatus(string.format("Unlocking %d mobil...", #carList))

        local success, failed = 0, 0

        for _, carID in ipairs(carList) do
            local ok, err = pcall(function()
                ModEvent:FireServer(carID, {
                    EngineInternals = selectedStage
                })
            end)

            if ok then
                success += 1
            else
                failed += 1
                warn(string.format("[Unlocker] %s gagal: %s", carID, tostring(err)))
            end

            SetStatus(string.format(
                "Progress: %d / %d (gagal: %d)",
                success + failed, #carList, failed
            ))

            task.wait(fireDelay)
        end

        SetStatus(string.format(
            "Done — %d berhasil, %d gagal.",
            success, failed
        ))

        Rayfield:Notify({
            Title    = "Unlocker",
            Content  = string.format("%d mobil unlocked ke %s", success, selectedStage),
            Duration = 5,
        })
    end
})

-- ─── Single car unlock ────────────────────────────────────────────────────
Tab:CreateSection("Manual")

local manualCarID = ""

Tab:CreateInput({
    Name        = "Car ID",
    PlaceholderText = "e.g. 2021GTBlackSeries",
    RemoveTextAfterFocusLost = false,
    Flag        = "ManualCarID",
    Callback    = function(val)
        manualCarID = val
    end
})

Tab:CreateButton({
    Name     = "Unlock This Car",
    Callback = function()
        if manualCarID == "" then
            SetStatus("ERROR: Car ID kosong.")
            return
        end

        local ok, err = pcall(function()
            ModEvent:FireServer(manualCarID, {
                EngineInternals = selectedStage
            })
        end)

        if ok then
            SetStatus(string.format("Unlocked: %s → %s", manualCarID, selectedStage))
            Rayfield:Notify({
                Title    = "Unlocker",
                Content  = manualCarID .. " → " .. selectedStage,
                Duration = 4,
            })
        else
            SetStatus("ERROR: " .. tostring(err))
        end
    end
})