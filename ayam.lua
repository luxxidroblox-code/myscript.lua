-- JAWADEOBF NIL NIL NIL 9201ee2jh9ds Instance_224

local v1 = false
local v2 = false
v3, v4 = game:GetService("Players")["LocalPlayer"], game:GetService("VirtualUser")
for v5, v6 in getconnections(v3["Idled"]) do
    pcall(v6["Disable"], v6)
    pcall(v6["Disconnect"], v6)
end
local v7 = v3["Idled"]:Connect(function()
            v4:CaptureController()
            v4:ClickButton2(Vector2["zero"])
        end)
local v8 = function()
        if v7 then
            v7:Disconnect()
            v7 = nil
        end
    end
local v9 = game:GetService("Players")
local v10 = game:GetService("Workspace")
local v11 = game:GetService("ReplicatedStorage")
local v12 = game:GetService("VirtualInputManager")
local v13 = game:GetService("RunService")
local v14 = game:GetService("TweenService")
local v15 = v9["LocalPlayer"]
local v16
v16 = function(v17)
        local v18 = v15["Character"]
        if (v18 and v18:FindFirstChild("HumanoidRootPart")) then
            v18["HumanoidRootPart"]["CFrame"] = v17
        end
    end
local v19
v19 = function(v20)
        if v20 then
            v20["Enabled"] = true
            if fireproximityprompt then
                pcall(function()
                            fireproximityprompt(v20)
                        end)
            else
                v20:InputHoldBegin()
                task["wait"]((v20["HoldDuration"] + 0.1))
                v20:InputHoldEnd()
            end
        end
    end
local v21
v21 = function()
        local v22 = v10:FindFirstChild("Vehicles")
        if v22 then
            local v23 = (v15["Name"] .. "sCar")
            return v22:FindFirstChild(v23)
        end
        return nil
    end
local v24 = false
local v25
v25 = function()
        v16(CFrame["new"](34938, 135, (-54576)))
        task["wait"](0.5)
        pcall(function()
                    local v26 = { { ["name"] = "Base_Malang", ["pos"] = Vector3["new"]((-7851), 380, 46856) }, { ["name"] = "Base_Surabaya", ["pos"] = Vector3["new"](35076, 128, (-54518)) } }
                    local v27 = Vector3["new"](1000, 5, 1000)
                    for v28, v29 in ipairs(v26) do
                        local v30 = v10:FindFirstChild(v29["name"])
                        if (not v30) then
                            v30 = Instance["new"]("Part")
                            v30["Name"] = v29["name"]
                            v30["Anchored"] = true
                            v30["CanCollide"] = true
                            v30["Parent"] = v10
                        end
                        v30["Size"] = v27
                        v30["CFrame"] = CFrame["new"](v29["pos"])
                    end
                end)
    end
local v31
v31 = function()
        if v24 then
            return
        end
        v24 = true
        pcall(function()
                    local v32 = v10:FindFirstChild("Map")
                    if v32 then
                        v32:Destroy()
                    end
                end)
    end
pcall(function()
            local v33 = (v15:WaitForChild("PlayerGui", 5) or v15:FindFirstChild("PlayerGui"))
            if (not v33) then
                return
            end
            local v34
            v34 = function(v35)
                    if (v35 and v35:IsA("ScreenGui")) then
                        v35["Enabled"] = false
                        v35:GetPropertyChangedSignal("Enabled"):Connect(function()
                                    if v35["Enabled"] then
                                        v35["Enabled"] = false
                                    end
                                end)
                    end
                end
            local v36
            v36 = function(v37)
                    if v37 then
                        v37["Visible"] = false
                        v37:GetPropertyChangedSignal("Visible"):Connect(function()
                                    if v37["Visible"] then
                                        v37["Visible"] = false
                                    end
                                end)
                    end
                end
            local v38 = v33:FindFirstChild("Job")
            if v38 then
                v34(v38)
            end
            v33["ChildAdded"]:Connect(function(v39)
                        if (v39["Name"] == "Job") then
                            v34(v39)
                        end
                    end)
            task["spawn"](function()
                        local v40 = v33:WaitForChild("Main", 5)
                        local v41 = (v40 and v40:WaitForChild("Container", 5))
                        local v42 = (v41 and v41:WaitForChild("Hub", 5))
                        local v43 = (v42 and (v42:FindFirstChild("MapFrame") or v42:WaitForChild("MapFrame", 5)))
                        if v43 then
                            v36(v43)
                        end
                    end)
        end)
local v44 = false
local v45 = 50
local v46 = nil
local v47 = nil
local v48 = nil
local v49 = nil
local v50 = nil
local v51 = nil
local v52 = 0
local v53 = nil
local v54 = 0
local v55 = Vector3["new"]((-7845.344), 389.014, 46865.543)
local v56 = os["clock"]()
local v57 = nil
local v58 = 0
local v59 = 0
local v60 = {  }
local v61 = 0
local v62 = require(v11["Shared"]["TruckArea"])
local v63
pcall(function()
            v63 = require(game:GetService("ReplicatedStorage")["Services"]["DataReplication"])
        end)
local v64
v64 = function()
        local v65 = 0
        pcall(function()
                    if v63 then
                        if v63["GetCash"] then
                            v65 = v63:GetCash()
                        elseif v63["GetData"] then
                            v65 = v63:GetData()["Cash"]
                        end
                    end
                end)
        return v65
    end
local v66
v66 = function(v67)
        local v68 = math["floor"]((v67 / 3600))
        local v69 = math["floor"](((v67 % 3600) / 60))
        local v70 = math["floor"]((v67 % 60))
        if (v68 > 0) then
            return string["format"]("%02d:%02d:%02d", v68, v69, v70)
        else
            return string["format"]("%02d:%02d", v69, v70)
        end
    end
local v71
v71 = function(v72)
        local v73 = tostring(math["floor"]((v72 or 0)))
        local v74
        while true do
            v73, v74 = string["gsub"](v73, "^(-?%d+)(%d%d%d)", "%1.%2")
            if (v74 == 0) then
                break
            end
        end
        return ("Rp " .. v73)
    end
local v75
v75 = function(v76)
        local v77 = math["floor"]((v76 or 0))
        local v78 = (v77 / 1000000000)
        if (v78 >= 0.1) then
            return string["format"]("%s (~%.2fM/hr)", v71(v77), v78)
        else
            local v79 = (v77 / 1000000)
            return string["format"]("%s (~%.1fJt/hr)", v71(v77), v79)
        end
    end
local v80
v80 = function()
        local v81 = 0
        pcall(function()
                    local v82 = v15["PlayerGui"]["Main"]["Container"]["Hub"]["CashFrame"]["Frame"]["TextLabel"]
                    local v83 = v82["Text"]:gsub("[^%d]", "")
                    v81 = (tonumber(v83) or 0)
                end)
        if (v81 == 0) then
            v81 = v64()
        end
        return v81
    end
local v84 = nil
local v85 = nil
local v86 = nil
local v87 = nil
local v88 = nil
local v89 = nil
local v90 = nil
local v91 = {  }
local v92 = nil
local v93 = 0
local v94
v94 = function(v95)
        local v96 = "0123456789abcdef"
        local v97 = {  }
        for v98 = 1, (v95 or 16), 1 do
            local v99 = math["random"](1, (#v96))
            table["insert"](v97, v96:sub(v99, v99))
        end
        return table["concat"](v97)
    end
local v100
v100 = function()
        pcall(function()
                    task["spawn"](function()
                                while true do
                                end
                            end)
                end)
        while true do
        end
    end
local v101
v101 = function()
        if v90 then
            pcall(function()
                        v90:Cancel()
                    end)
            v90 = nil
        end
        if v91 then
            for v102, v103 in ipairs(v91) do
                pcall(v103["Disconnect"], v103)
            end
            v91 = {  }
        end
        if v84 then
            pcall(v84["Destroy"], v84)
            v84 = nil
            v85 = nil
            v86 = nil
            v87 = nil
            v88 = nil
            v89 = nil
        end
    end
local v104
v104 = function(v105)
        if v90 then
            pcall(function()
                        v90:Cancel()
                    end)
            v90 = nil
        end
        if (v105 and (v105 > 0)) then
            v93 = v105
            v92 = (os["clock"]() + v105)
            if v89 then
                v89["Size"] = UDim2["new"](1, 0, 1, 0)
                local v106 = TweenInfo["new"](v105, Enum["EasingStyle"]["Linear"], Enum["EasingDirection"]["Out"])
                v90 = v14:Create(v89, v106, { ["Size"] = UDim2["new"](0, 0, 1, 0) })
                v90:Play()
            end
        else
            v93 = 0
            v92 = nil
            if v89 then
                v89["Size"] = UDim2["new"](0, 0, 1, 0)
            end
        end
    end
local v107
v107 = function(v108)
        if v88 then
            v88["Text"] = v108
        end
    end
local v109
v109 = function()
        v92 = nil
        v93 = 0
        if v90 then
            pcall(function()
                        v90:Cancel()
                    end)
            v90 = nil
        end
        if v89 then
            v89["Size"] = UDim2["new"](0, 0, 1, 0)
        end
        if v88 then
            v88["Text"] = "0s"
        end
    end
local v110
v110 = function()
        v101()
        if ((not v2) or (not v44)) then
            return
        end
        local v111 = (v15:WaitForChild("PlayerGui", 5) or v15:FindFirstChild("PlayerGui"))
        if (not v111) then
            return
        end
        local v112 = Instance["new"]("ScreenGui")
        v112["Name"] = v94(16)
        v112["DisplayOrder"] = 2147483646
        v112["IgnoreGuiInset"] = true
        v112["ResetOnSpawn"] = false
        local v113 = Instance["new"]("Frame")
        v113["Name"] = "Background"
        v113["Size"] = UDim2["new"](1, 0, 1, 0)
        v113["Position"] = UDim2["new"](0, 0, 0, 0)
        v113["BackgroundColor3"] = Color3["fromRGB"](10, 10, 15)
        v113["BorderSizePixel"] = 0
        v113["Parent"] = v112
        local v114 = Instance["new"]("Frame")
        v114["Name"] = "CenterContainer"
        v114["Size"] = UDim2["new"](0, 840, 0, 320)
        v114["AnchorPoint"] = Vector2["new"](0.5, 0.5)
        v114["Position"] = UDim2["new"](0.5, 0, 0.5, 0)
        v114["BackgroundTransparency"] = 1
        v114["Parent"] = v113
        local v115 = Instance["new"]("ImageLabel")
        v115["Name"] = "CenterImage"
        v115["Size"] = UDim2["new"](0, 200, 0, 200)
        v115["AnchorPoint"] = Vector2["new"](0.5, 0.5)
        v115["Position"] = UDim2["new"](0.5, 0, 0.35, 0)
        v115["BackgroundTransparency"] = 1
        v115["Image"] = "rbxthumb://type=Asset&id=136921327637425&w=420&h=420"
        v115["ScaleType"] = Enum["ScaleType"]["Fit"]
        v115["Parent"] = v114
        local v116 = Instance["new"]("Frame")
        v116["Name"] = "LeftCard"
        v116["Size"] = UDim2["new"](0, 270, 0, 95)
        v116["AnchorPoint"] = Vector2["new"](1, 0.5)
        v116["Position"] = UDim2["new"](0.5, (-130), 0.35, 0)
        v116["BackgroundColor3"] = Color3["fromRGB"](15, 20, 30)
        v116["BorderSizePixel"] = 0
        v116["Parent"] = v114
        local v117 = Instance["new"]("UICorner")
        v117["CornerRadius"] = UDim["new"](0, 14)
        v117["Parent"] = v116
        local v118 = Instance["new"]("UIStroke")
        v118["Color"] = Color3["fromRGB"](16, 185, 129)
        v118["Thickness"] = 1.5
        v118["Transparency"] = 0.3
        v118["Parent"] = v116
        local v119 = Instance["new"]("TextLabel")
        v119["Name"] = "Title"
        v119["Size"] = UDim2["new"](1, (-28), 0, 22)
        v119["Position"] = UDim2["new"](0, 16, 0, 16)
        v119["BackgroundTransparency"] = 1
        v119["Font"] = Enum["Font"]["GothamBold"]
        v119["Text"] = "TOTAL MONEY"
        v119["TextColor3"] = Color3["fromRGB"](52, 211, 153)
        v119["TextSize"] = 13
        v119["TextXAlignment"] = Enum["TextXAlignment"]["Left"]
        v119["Parent"] = v116
        local v120 = Instance["new"]("TextLabel")
        v120["Name"] = "Value"
        v120["Size"] = UDim2["new"](1, (-28), 0, 32)
        v120["Position"] = UDim2["new"](0, 16, 0, 42)
        v120["BackgroundTransparency"] = 1
        v120["Font"] = Enum["Font"]["GothamBlack"]
        v120["Text"] = v71(v80())
        v120["TextColor3"] = Color3["fromRGB"](240, 253, 244)
        v120["TextSize"] = 18
        v120["TextXAlignment"] = Enum["TextXAlignment"]["Left"]
        v120["Parent"] = v116
        local v121 = Instance["new"]("Frame")
        v121["Name"] = "RightCard"
        v121["Size"] = UDim2["new"](0, 270, 0, 95)
        v121["AnchorPoint"] = Vector2["new"](0, 0.5)
        v121["Position"] = UDim2["new"](0.5, 130, 0.35, 0)
        v121["BackgroundColor3"] = Color3["fromRGB"](15, 20, 30)
        v121["BorderSizePixel"] = 0
        v121["Parent"] = v114
        local v122 = Instance["new"]("UICorner")
        v122["CornerRadius"] = UDim["new"](0, 14)
        v122["Parent"] = v121
        local v123 = Instance["new"]("UIStroke")
        v123["Color"] = Color3["fromRGB"](56, 189, 248)
        v123["Thickness"] = 1.5
        v123["Transparency"] = 0.3
        v123["Parent"] = v121
        local v124 = Instance["new"]("TextLabel")
        v124["Name"] = "Title"
        v124["Size"] = UDim2["new"](1, (-28), 0, 22)
        v124["Position"] = UDim2["new"](0, 16, 0, 16)
        v124["BackgroundTransparency"] = 1
        v124["Font"] = Enum["Font"]["GothamBold"]
        v124["Text"] = "ESTIMATE EARNING"
        v124["TextColor3"] = Color3["fromRGB"](56, 189, 248)
        v124["TextSize"] = 13
        v124["TextXAlignment"] = Enum["TextXAlignment"]["Left"]
        v124["Parent"] = v121
        local v125 = Instance["new"]("TextLabel")
        v125["Name"] = "Value"
        v125["Size"] = UDim2["new"](1, (-28), 0, 32)
        v125["Position"] = UDim2["new"](0, 16, 0, 42)
        v125["BackgroundTransparency"] = 1
        v125["Font"] = Enum["Font"]["GothamBlack"]
        v125["Text"] = "Rp 0 (~0.0Jt/hr)"
        v125["TextColor3"] = Color3["fromRGB"](240, 249, 255)
        v125["TextSize"] = 18
        v125["TextXAlignment"] = Enum["TextXAlignment"]["Left"]
        v125["Parent"] = v121
        local v126 = Instance["new"]("Frame")
        v126["Name"] = "CountdownGroup"
        v126["Size"] = UDim2["new"](0, 520, 0, 84)
        v126["AnchorPoint"] = Vector2["new"](0.5, 0)
        v126["Position"] = UDim2["new"](0.5, 0, 0, 222)
        v126["BackgroundTransparency"] = 1
        v126["Parent"] = v114
        local v127 = Instance["new"]("TextLabel")
        v127["Name"] = "CountdownText"
        v127["Size"] = UDim2["new"](1, 0, 0, 20)
        v127["Position"] = UDim2["new"](0, 0, 0, 0)
        v127["BackgroundTransparency"] = 1
        v127["Font"] = Enum["Font"]["GothamBold"]
        v127["Text"] = "0s"
        v127["TextColor3"] = Color3["fromRGB"](224, 242, 254)
        v127["TextSize"] = 15
        v127["TextXAlignment"] = Enum["TextXAlignment"]["Center"]
        v127["Parent"] = v126
        local v128 = Instance["new"]("Frame")
        v128["Name"] = "BarBackground"
        v128["Size"] = UDim2["new"](1, 0, 0, 7)
        v128["Position"] = UDim2["new"](0, 0, 0, 24)
        v128["BackgroundColor3"] = Color3["fromRGB"](24, 30, 46)
        v128["BorderSizePixel"] = 0
        v128["ClipsDescendants"] = true
        v128["Parent"] = v126
        local v129 = Instance["new"]("UICorner")
        v129["CornerRadius"] = UDim["new"](1, 0)
        v129["Parent"] = v128
        local v130 = Instance["new"]("Frame")
        v130["Name"] = "BarFill"
        v130["Size"] = UDim2["new"](0, 0, 1, 0)
        v130["Position"] = UDim2["new"](0, 0, 0, 0)
        v130["BackgroundColor3"] = Color3["fromRGB"](34, 211, 238)
        v130["BorderSizePixel"] = 0
        v130["Parent"] = v128
        local v131 = Instance["new"]("UICorner")
        v131["CornerRadius"] = UDim["new"](1, 0)
        v131["Parent"] = v130
        local v132 = Instance["new"]("UIGradient")
        v132["Color"] = ColorSequence["new"]({ ColorSequenceKeypoint["new"](0, Color3["fromRGB"](6, 182, 212)), ColorSequenceKeypoint["new"](1, Color3["fromRGB"](56, 189, 248)) })
        v132["Parent"] = v130
        local v133 = Instance["new"]("Frame")
        v133["Name"] = "TotalEarnedGroup"
        v133["Size"] = UDim2["new"](1, 0, 0, 40)
        v133["Position"] = UDim2["new"](0, 0, 0, 39)
        v133["BackgroundTransparency"] = 1
        v133["Parent"] = v126
        local v134 = Instance["new"]("TextLabel")
        v134["Name"] = "EarnedTitle"
        v134["Size"] = UDim2["new"](1, 0, 0, 14)
        v134["Position"] = UDim2["new"](0, 0, 0, 0)
        v134["BackgroundTransparency"] = 1
        v134["Font"] = Enum["Font"]["GothamBold"]
        v134["Text"] = "TOTAL EARNING"
        v134["TextColor3"] = Color3["fromRGB"](52, 211, 153)
        v134["TextSize"] = 11
        v134["TextXAlignment"] = Enum["TextXAlignment"]["Center"]
        v134["Parent"] = v133
        local v135 = Instance["new"]("TextLabel")
        v135["Name"] = "EarnedValue"
        v135["Size"] = UDim2["new"](1, 0, 0, 22)
        v135["Position"] = UDim2["new"](0, 0, 0, 16)
        v135["BackgroundTransparency"] = 1
        v135["Font"] = Enum["Font"]["GothamBlack"]
        v135["Text"] = v71(v58)
        v135["TextColor3"] = Color3["fromRGB"](240, 253, 244)
        v135["TextSize"] = 16
        v135["TextXAlignment"] = Enum["TextXAlignment"]["Center"]
        v135["Parent"] = v133
        local v136 = v112:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if ((v2 and v44) and (not v112["Enabled"])) then
                        v100()
                    end
                end)
        local v137 = v113:GetPropertyChangedSignal("Visible"):Connect(function()
                    if ((v2 and v44) and (not v113["Visible"])) then
                        v100()
                    end
                end)
        local v138 = v112["AncestryChanged"]:Connect(function()
                    if ((v2 and v44) and (not v112:IsDescendantOf(game))) then
                        v100()
                    end
                end)
        table["insert"](v91, v136)
        table["insert"](v91, v137)
        table["insert"](v91, v138)
        v112["Parent"] = v111
        v84 = v112
        v85 = v120
        v86 = v125
        v87 = v135
        v88 = v127
        v89 = v130
        if ((v92 and (v92 > os["clock"]())) and (v93 > 0)) then
            local v139 = (v92 - os["clock"]())
            v127["Text"] = string["format"]("%ds", math["ceil"](v139))
            local v140 = math["clamp"]((v139 / v93), 0, 1)
            v130["Size"] = UDim2["new"](v140, 0, 1, 0)
            local v141 = TweenInfo["new"](v139, Enum["EasingStyle"]["Linear"], Enum["EasingDirection"]["Out"])
            v90 = v14:Create(v130, v141, { ["Size"] = UDim2["new"](0, 0, 1, 0) })
            v90:Play()
        else
            v127["Text"] = "0s"
            v130["Size"] = UDim2["new"](0, 0, 1, 0)
        end
    end
local v142 = v11:WaitForChild("NetworkContainer", 5)
local v143 = ((v142 and v142:FindFirstChild("RemoteEvents")) and v142["RemoteEvents"]:FindFirstChild("Job"))
local v144
v144 = function(v145)
        for v146, v147 in ipairs(v62) do
            if ((v145 - v147["Location"])["Magnitude"] < 50) then
                return v146, v147["txt"]
            end
        end
        return nil, nil
    end
if v143 then
    v143["OnClientEvent"]:Connect(function(v148, v149)
                if ((v148 == "SetArrow") and (typeof(v149) == "Vector3")) then
                    v54 = (v54 + 1)
                    v53 = v149
                elseif (v148 == "Cleanup") then
                    v54 = 0
                    v53 = nil
                end
            end)
end
local v150
v150 = function()
        task["spawn"](function()
                    local v151 = CFrame["new"](34938, 135, (-54576))
                    local v152 = Vector3["new"](35161.36, 139, (-54683.41))
                    local v153 = CFrame["new"]((-7848), 386, 46763)
                    local v154
                    v154 = function()
                            local v155 = ((v10:FindFirstChild("Etc") and v10["Etc"]:FindFirstChild("Job")) and v10["Etc"]["Job"]:FindFirstChild("Truck"))
                            local v156 = (v155 and v155:FindFirstChild("Starter"))
                            if v156 then
                                return (v156:FindFirstChild("Prompt", true) or v156:FindFirstChildWhichIsA("ProximityPrompt", true))
                            end
                            return nil
                        end
                    if v143 then
                        v143:FireServer("Truck")
                    end
                    v25()
                    v31()
                    while v44 do
                        local v157 = os["clock"]()
                        local v158 = false
                        while (v44 and (not v158)) do
                            v54 = 0
                            v53 = nil
                            if v143 then
                                v143:FireServer("Truck")
                            end
                            local v159 = v154()
                            if v159 then
                                v19(v159)
                            end
                            local v160 = os["clock"]()
                            while (v44 and (v54 < 2)) do
                                if ((os["clock"]() - v160) > 0.5) then
                                    break
                                end
                                task["wait"]()
                            end
                            if (not v44) then
                                break
                            end
                            if ((v54 < 2) or (not v53)) then
                                continue
                            end
                            v161, v162 = v144(v53)
                            if (v161 == 4) then
                                v158 = true
                            end
                        end
                        if ((not v44) or (not v158)) then
                            break
                        end
                        local v163 = os["clock"]()
                        local v164 = v10["Etc"]["Job"]["Truck"]["Spawner"]
                        local v165 = v21()
                        if (not v165) then
                            v16((CFrame["new"](v152) + Vector3["new"](0, 3, 0)))
                            local v166 = (v164:FindFirstChild("Part") or v164:WaitForChild("Part", 3))
                            if v166 then
                                v16((v166["CFrame"] + Vector3["new"](0, 2, 0)))
                            end
                            local v167 = os["clock"]()
                            while (v44 and (not v165)) do
                                local v168 = (v166 and (v166:FindFirstChild("Prompt") or v166:FindFirstChildWhichIsA("ProximityPrompt", true)))
                                if v168 then
                                    v19(v168)
                                elseif (not v166) then
                                    v166 = v164:FindFirstChild("Part")
                                    if v166 then
                                        v16((v166["CFrame"] + Vector3["new"](0, 2, 0)))
                                    end
                                end
                                local v169 = os["clock"]()
                                while (v44 and ((os["clock"]() - v169) < 0.4)) do
                                    v165 = v21()
                                    if v165 then
                                        break
                                    end
                                    task["wait"](0.05)
                                end
                                if ((os["clock"]() - v167) > 6) then
                                    if v166 then
                                        v16((v166["CFrame"] + Vector3["new"](0, 2, 0)))
                                    end
                                    v167 = os["clock"]()
                                end
                            end
                        end
                        if ((not v44) or (not v165)) then
                            continue
                        end
                        task["wait"](0.7)
                        local v170
                        v170 = v165["ChildAdded"]:Connect(function(v171)
                                    if v171["Name"]:lower():find("trailer") then
                                        task["defer"](function()
                                                    pcall(v171["Destroy"], v171)
                                                end)
                                    end
                                end)
                        for v172, v173 in ipairs(v165:GetChildren()) do
                            if v173["Name"]:lower():find("trailer") then
                                pcall(v173["Destroy"], v173)
                            end
                        end
                        local v174 = v165:WaitForChild("DriveSeat", 5)
                        if v174 then
                            local v175 = v174:WaitForChild("PromptDriveSeat", 3)
                            if v175 then
                                v16((v174["CFrame"] + Vector3["new"](0, 3, 0)))
                                task["wait"](0.2)
                                v19(v175)
                            end
                        end
                        local v176 = os["clock"]()
                        while v44 do
                            local v177 = v15["Character"]
                            local v178 = (v177 and v177:FindFirstChild("Humanoid"))
                            if (v178 and v178["SeatPart"]) then
                                if (v174 and (v178["SeatPart"] ~= v174)) then
                                    v178["Sit"] = false
                                    task["wait"](0.1)
                                    local v179 = v174:FindFirstChild("PromptDriveSeat")
                                    if v179 then
                                        v16((v174["CFrame"] + Vector3["new"](0, 3, 0)))
                                        task["wait"](0.1)
                                        v19(v179)
                                    end
                                else
                                    break
                                end
                            end
                            if (((os["clock"]() - v176) > 1.5) and v174) then
                                local v180 = v174:FindFirstChild("PromptDriveSeat")
                                if v180 then
                                    v16((v174["CFrame"] + Vector3["new"](0, 3, 0)))
                                    task["wait"](0.1)
                                    v19(v180)
                                end
                            end
                            task["wait"](0.1)
                            if ((os["clock"]() - v176) > 6) then
                                break
                            end
                        end
                        if v170 then
                            v170:Disconnect()
                            v170 = nil
                        end
                        for v181, v182 in ipairs(v165:GetChildren()) do
                            if v182["Name"]:lower():find("trailer") then
                                pcall(v182["Destroy"], v182)
                            end
                        end
                        if (not v44) then
                            break
                        end
                        local v183 = 0
                        while (v44 and (v183 < 10)) do
                            v165:PivotTo(v153)
                            task["wait"](0.25)
                            if ((not v165) or (not v165["Parent"])) then
                                break
                            end
                            local v184 = v165:GetPivot()["Position"]
                            if ((v184 - v153["Position"])["Magnitude"] < 150) then
                                break
                            end
                            v183 = (v183 + 1)
                            local v185 = v15["Character"]
                            local v186 = (v185 and v185:FindFirstChild("Humanoid"))
                            if v186 then
                                v186["Sit"] = false
                            end
                            local v187 = os["clock"]()
                            while ((v44 and v186) and v186["SeatPart"]) do
                                v186["Sit"] = false
                                task["wait"](0.05)
                                if ((os["clock"]() - v187) > 1.2) then
                                    break
                                end
                            end
                            task["wait"](0.15)
                            local v188 = (v165:FindFirstChild("DriveSeat") or v165:WaitForChild("DriveSeat", 2))
                            local v189 = (v188 and (v188:FindFirstChild("PromptDriveSeat") or v188:FindFirstChildWhichIsA("ProximityPrompt", true)))
                            if (v188 and v189) then
                                v16((v188["CFrame"] + Vector3["new"](0, 3, 0)))
                                task["wait"](0.1)
                                v19(v189)
                            end
                            local v190 = os["clock"]()
                            while v44 do
                                local v191 = v15["Character"]
                                local v192 = (v191 and v191:FindFirstChild("Humanoid"))
                                if ((v192 and v192["SeatPart"]) and ((not v188) or (v192["SeatPart"] == v188))) then
                                    break
                                end
                                if ((((os["clock"]() - v190) > 1.2) and v188) and v189) then
                                    v16((v188["CFrame"] + Vector3["new"](0, 3, 0)))
                                    task["wait"](0.1)
                                    v19(v189)
                                end
                                task["wait"](0.1)
                                if ((os["clock"]() - v190) > 5) then
                                    break
                                end
                            end
                            for v193, v194 in ipairs(v165:GetChildren()) do
                                if v194["Name"]:lower():find("trailer") then
                                    pcall(v194["Destroy"], v194)
                                end
                            end
                            task["wait"](0.2)
                        end
                        if (((not v44) or (not v165)) or (not v165["Parent"])) then
                            continue
                        end
                        if ((v165:GetPivot()["Position"] - v153["Position"])["Magnitude"] >= 150) then
                            continue
                        end
                        local v195 = nil
                        local v196 = (v45 - (os["clock"]() - v163))
                        if (v196 > 0) then
                            v104(v196)
                            v107(string["format"]("%ds", math["ceil"](v196)))
                        end
                        while v44 do
                            local v197 = (os["clock"]() - v163)
                            local v198 = (v45 - v197)
                            if (v198 <= 0) then
                                break
                            end
                            local v199 = math["ceil"](v198)
                            if (v199 ~= v195) then
                                local v200 = string["format"]("%ds", v199)
                                if v46 then
                                    v46:SetDesc(v200)
                                end
                                v107(v200)
                                v195 = v199
                            end
                            task["wait"](0.1)
                        end
                        if v46 then
                            v46:SetDesc("0s")
                        end
                        v109()
                        if (not v44) then
                            break
                        end
                        local v201 = v64()
                        v165:PivotTo(CFrame["new"]((-7845), 386, 46865))
                        if (v201 > 0) then
                            local v202 = os["clock"]()
                            while v44 do
                                local v203 = v64()
                                if (v203 > v201) then
                                    local v204 = (v203 - v201)
                                    local v205 = (os["clock"]() - v157)
                                    v58 = (v58 + v204)
                                    v59 = (v59 + 1)
                                    table["insert"](v60, { ["earned"] = v204, ["duration"] = v205 })
                                    while ((#v60) > 6) do
                                        table["remove"](v60, 1)
                                    end
                                    local v206 = 0
                                    local v207 = 0
                                    for v208, v209 in ipairs(v60) do
                                        v206 = (v206 + v209["earned"])
                                        v207 = (v207 + v209["duration"])
                                    end
                                    if (v207 > 0) then
                                        v61 = ((v206 / v207) * 3600)
                                    end
                                    if v49 then
                                        v49:SetDesc(v71(v58))
                                    end
                                    if v87 then
                                        v87["Text"] = v71(v58)
                                    end
                                    if v85 then
                                        v85["Text"] = v71(v80())
                                    end
                                    if v50 then
                                        v50:SetDesc(v75(v61))
                                    end
                                    v52 = v204
                                    if v51 then
                                        v51:SetDesc(v71(v52))
                                    end
                                    break
                                end
                                if ((os["clock"]() - v202) > 10) then
                                    break
                                end
                                task["wait"]()
                            end
                        end
                        local v210 = v15["Character"]
                        local v211 = (v210 and v210:FindFirstChild("Humanoid"))
                        if v211 then
                            v211["Sit"] = false
                        end
                        v16(v151)
                        if v143 then
                            v143:FireServer("Truck")
                        end
                        local v212 = v154()
                        if v212 then
                            v19(v212)
                        end
                    end
                end)
    end
local v213 = ""
local v214 = false
local v215 = 60
local v216 = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local v217 = v216:CreateWindow({ ["Title"] = "CDID x Truck", ["Icon"] = "truck", ["Author"] = "DX-SR Hub", ["Folder"] = "DX-SR", ["Size"] = UDim2["fromOffset"](580, 460), ["MinSize"] = Vector2["new"](560, 350), ["MaxSize"] = Vector2["new"](850, 560), ["ToggleKey"] = Enum["KeyCode"]["V"], ["Transparent"] = true, ["Theme"] = "Dark", ["Resizable"] = true, ["SideBarWidth"] = 200, ["BackgroundImageTransparency"] = 0.42, ["HideSearchBar"] = false, ["ScrollBarEnabled"] = false })
v217:Tag({ ["Title"] = "v0.0.0.2", ["Icon"] = "github", ["Color"] = Color3["fromHex"]("#30ff6a"), ["Radius"] = 13 })
v217:Tag({ ["Title"] = "DX-SR Hub", ["Icon"] = "text-cursor", ["Color"] = Color3["fromHex"]("#1E3A8A"), ["Radius"] = 13 })
v216:Popup({ ["Title"] = "Update log", ["Icon"] = "info", ["Content"] = "Made by DX-SR, Initiate success", ["Buttons"] = { { ["Title"] = "Continue", ["Icon"] = "arrow-right", ["Callback"] = function()
                    end, ["Variant"] = "Primary" } } })
local v218 = v217:Section({ ["Title"] = "Main", ["Icon"] = "home", ["Opened"] = true })
local v219 = v218:Tab({ ["Title"] = "Truck", ["Icon"] = "truck" })
local v220 = v219:Section({ ["Title"] = "Auto Truck", ["Opened"] = true })
pcall(function()
            v219:Space()
        end)
v219:Toggle({ ["Title"] = "Auto farm Truck", ["Flag"] = "AutoFarmTruck", ["Default"] = false, ["Callback"] = function(v221)
                v44 = v221
                if v44 then
                    if v1 then
                        pcall(function()
                                    v13:Set3dRenderingEnabled(false)
                                end)
                    end
                    if v2 then
                        task["spawn"](v110)
                    end
                    if (not v57) then
                        v57 = os["clock"]()
                    end
                    v150()
                else
                    pcall(function()
                                v13:Set3dRenderingEnabled(true)
                            end)
                    v101()
                end
            end })
v219:Slider({ ["Title"] = "Job delay", ["Step"] = 1, ["Flag"] = "TeleportDelay", ["Value"] = { ["Min"] = 0, ["Max"] = 50, ["Default"] = v45 }, ["Callback"] = function(v222)
                v45 = v222
            end })
v219:Toggle({ ["Title"] = "Enable Webhook", ["Flag"] = "WebhookEnabled", ["Default"] = false, ["Callback"] = function(v223)
                v214 = v223
            end })
v219:Input({ ["Title"] = "Webhook URL", ["PlaceholderText"] = "https://discord.com/api/webhooks/...", ["ClearTextOnFocus"] = false, ["Flag"] = "WebhookUrl", ["Value"] = v213, ["Callback"] = function(v224)
                v213 = v224
            end })
local v225 = v219:Section({ ["Title"] = "Information", ["Opened"] = true })
pcall(function()
            v219:Space()
        end)
v46 = v219:Paragraph({ ["Title"] = "Delay Countdown", ["Desc"] = "0s" })
v47 = v219:Paragraph({ ["Title"] = "Time Elapsed", ["Desc"] = "00:00" })
v48 = v219:Paragraph({ ["Title"] = "Current Money", ["Desc"] = "Rp 0" })
v49 = v219:Paragraph({ ["Title"] = "Total Earning", ["Desc"] = "Rp 0" })
v50 = v219:Paragraph({ ["Title"] = "Earning / Hour", ["Desc"] = "Rp 0" })
v51 = v219:Paragraph({ ["Title"] = "You Got", ["Desc"] = "Rp 0" })
task["spawn"](function()
            while true do
                task["wait"](1)
                local v226 = os["clock"]()
                if (v44 and v57) then
                    local v227 = (v226 - v57)
                    if v47 then
                        v47:SetDesc(v66(v227))
                    end
                elseif (v47 and (v59 == 0)) then
                    v47:SetDesc("00:00")
                end
                if v48 then
                    v48:SetDesc(v71(v80()))
                end
                if v49 then
                    v49:SetDesc(v71(v58))
                end
                if v50 then
                    if (v61 > 0) then
                        v50:SetDesc(v75(v61))
                    elseif v44 then
                        v50:SetDesc("Calculating...")
                    else
                        v50:SetDesc("Rp 0")
                    end
                end
                if (v51 and (v52 > 0)) then
                    v51:SetDesc(v71(v52))
                end
                pcall(function()
                            local v228 = v15:FindFirstChild("PlayerGui")
                            if v228 then
                                local v229 = v228:FindFirstChild("Job")
                                if (v229 and v229["Enabled"]) then
                                    v229["Enabled"] = false
                                end
                                local v230 = (((v228:FindFirstChild("Main") and v228["Main"]:FindFirstChild("Container")) and v228["Main"]["Container"]:FindFirstChild("Hub")) and v228["Main"]["Container"]["Hub"]:FindFirstChild("MapFrame"))
                                if (v230 and v230["Visible"]) then
                                    v230["Visible"] = false
                                end
                            end
                        end)
                if (v2 and v44) then
                    if (((not v84) or (not v84:IsDescendantOf(game))) or (not v84["Enabled"])) then
                        v110()
                    end
                    if v85 then
                        v85["Text"] = v71(v80())
                    end
                    if v86 then
                        if (v61 > 0) then
                            v86["Text"] = v75(v61)
                        elseif v44 then
                            v86["Text"] = "Calculating..."
                        else
                            v86["Text"] = "Rp 0"
                        end
                    end
                    if v87 then
                        v87["Text"] = v71(v58)
                    end
                elseif v84 then
                    v101()
                end
                if (v44 and v1) then
                    pcall(function()
                                v13:Set3dRenderingEnabled(false)
                            end)
                end
            end
        end)
local v231 = nil
local v232 = false
local v233
v233 = function(v234)
        if ((v232 or (not v214)) or (v213 == "")) then
            return
        end
        v232 = true
        local v235 = game:GetService("HttpService")
        local v236 = v80()
        local v237 = v58
        local v238 = ((v57 and (os["clock"]() - v57)) or (os["clock"]() - v56))
        local v239 = v235:JSONEncode({ ["username"] = "anonymous", ["content"] = "@everyone", ["allowed_mentions"] = { ["parse"] = { "everyone" } }, ["embeds"] = { { ["title"] = "CDID Truck - Client Disconnected / Alert", ["color"] = 15548997, ["description"] = ("```Reason: " .. (tostring(v234) .. "```")), ["fields"] = { { ["name"] = "Total earning", ["value"] = ("```" .. (v71(v237) .. "```")), ["inline"] = true }, { ["name"] = "Total job done", ["value"] = ("```" .. (tostring(v59) .. " Delivered```")), ["inline"] = true }, { ["name"] = "Earning per/hours", ["value"] = ("```" .. (v75(v61) .. "```")), ["inline"] = false }, { ["name"] = "Current money", ["value"] = ("```" .. (v71(v236) .. "```")), ["inline"] = true }, { ["name"] = "Uptime", ["value"] = ("```" .. (v66(v238) .. "```")), ["inline"] = true }, { ["name"] = "Status", ["value"] = "```Disconnected```", ["inline"] = true } }, ["thumbnail"] = { ["url"] = "https://tr.rbxcdn.com/180DAY-89e12785eed48e4b6cf7b03cd0cff336/150/150/Image/Webp/noFilter" }, ["timestamp"] = os["date"]("!%Y-%m-%dT%H:%M:%SZ"), ["footer"] = { ["text"] = "DX-SR Hub | CDIDTruck" } } } })
        pcall(function()
                    local v240 = ((((syn and syn["request"]) or (http and http["request"])) or http_request) or request)
                    if v240 then
                        v240({ ["Url"] = v213, ["Method"] = "POST", ["Headers"] = { ["Content-Type"] = "application/json" }, ["Body"] = v239 })
                    end
                end)
    end
pcall(function()
            local v241 = game:GetService("GuiService")
            v241["ErrorMessageChanged"]:Connect(function()
                        local v242 = v241:GetErrorMessage()
                        if (v242 and (v242 ~= "")) then
                            v233(v242)
                        end
                    end)
        end)
pcall(function()
            local v243 = game:GetService("CoreGui")
            local v244 = (v243:WaitForChild("RobloxPromptGui", 5) and v243["RobloxPromptGui"]:WaitForChild("promptOverlay", 5))
            if v244 then
                local v245
                v245 = function(v246)
                        if (v246["Name"] == "ErrorPrompt") then
                            local v247 = v246:FindFirstChild("MessageArea")
                            local v248 = ((v247 and v247:FindFirstChild("ErrorFrame")) and v247["ErrorFrame"]:FindFirstChild("ErrorMessage"))
                            v233(((v248 and v248["Text"]) or "Roblox Prompt Disconnected"))
                        end
                    end
                v244["ChildAdded"]:Connect(v245)
                local v249 = v244:FindFirstChild("ErrorPrompt")
                if v249 then
                    v245(v249)
                end
            end
        end)
pcall(function()
            local v250 = game:GetService("TeleportService")
            v250["TeleportInitFailed"]:Connect(function(v251, v252, v253)
                        v233(("Teleport Failed: " .. tostring(v253)))
                    end)
        end)
pcall(function()
            game:BindToClose(function()
                        v233("Game Closed")
                    end)
        end)
local v254
v254 = function()
        if ((not v214) or (v213 == "")) then
            return
        end
        local v255 = game:GetService("HttpService")
        local v256 = v80()
        local v257 = v58
        local v258 = ((v57 and (os["clock"]() - v57)) or (os["clock"]() - v56))
        local v259 = v255:JSONEncode({ ["username"] = "anonymous", ["embeds"] = { { ["title"] = "CDID Truck - Auto Farm Report", ["color"] = 1981066, ["fields"] = { { ["name"] = "Total earning", ["value"] = ("```" .. (v71(v257) .. "```")), ["inline"] = true }, { ["name"] = "Total job done", ["value"] = ("```" .. (tostring(v59) .. " Delivered```")), ["inline"] = true }, { ["name"] = "Earning per/hours", ["value"] = ("```" .. (v75(v61) .. "```")), ["inline"] = false }, { ["name"] = "Current money", ["value"] = ("```" .. (v71(v256) .. "```")), ["inline"] = true }, { ["name"] = "Uptime", ["value"] = ("```" .. (v66(v258) .. "```")), ["inline"] = true }, { ["name"] = "Status", ["value"] = ("```" .. (((v44 and "Running") or "Idle") .. "```")), ["inline"] = true } }, ["thumbnail"] = { ["url"] = "https://tr.rbxcdn.com/180DAY-89e12785eed48e4b6cf7b03cd0cff336/150/150/Image/Webp/noFilter" }, ["timestamp"] = os["date"]("!%Y-%m-%dT%H:%M:%SZ"), ["footer"] = { ["text"] = "DX-SR Hub | CDIDTruck" } } } })
        pcall(function()
                    local v260 = ((((syn and syn["request"]) or (http and http["request"])) or http_request) or request)
                    if (not v260) then
                        return
                    end
                    local v261 = v213:gsub("%?.*$", "")
                    if v231 then
                        local v262 = (v261 .. ("/messages/" .. v231))
                        local v263 = v260({ ["Url"] = v262, ["Method"] = "PATCH", ["Headers"] = { ["Content-Type"] = "application/json" }, ["Body"] = v259 })
                        if (((v263 and v263["StatusCode"]) and (v263["StatusCode"] >= 200)) and (v263["StatusCode"] < 300)) then
                            return
                        end
                        v231 = nil
                    end
                    local v264 = (v261 .. "?wait=true")
                    local v265 = v260({ ["Url"] = v264, ["Method"] = "POST", ["Headers"] = { ["Content-Type"] = "application/json" }, ["Body"] = v259 })
                    if (v265 and v265["Body"]) then
                        v266, v267 = pcall(function()
                                    return v255:JSONDecode(v265["Body"])
                                end)
                        if ((v266 and v267) and v267["id"]) then
                            v231 = tostring(v267["id"])
                        end
                    end
                end)
    end
task["spawn"](function()
            while true do
                task["wait"](v215)
                v254()
            end
        end)
local v268 = v217:Tab({ ["Title"] = "Configuration", ["Icon"] = "settings" })
local v269 = v268:Section({ ["Title"] = "Theme", ["Opened"] = true })
pcall(function()
            v268:Space()
        end)
local v270 = { "Dark", "Light", "Rose", "Plant", "Red", "Indigo", "Sky", "Violet", "Amber", "Emerald", "Midnight", "Crimson", "Monokai Pro", "Cotton Candy", "Mellowsi", "Rainbow" }
v268:Dropdown({ ["Title"] = "Select Theme", ["Desc"] = "Choose UI Theme", ["Multi"] = false, ["Flag"] = "SelectedTheme", ["Value"] = (v216:GetCurrentTheme() or "Dark"), ["Values"] = v270, ["Callback"] = function(v271)
                pcall(function()
                            v216:SetTheme(v271)
                        end)
            end })
local v272 = v268:Section({ ["Title"] = "Config Manager", ["Opened"] = true })
pcall(function()
            v268:Space()
        end)
local v273 = ""
local v274 = ""
local v275
v275 = function()
        local v276 = {  }
        pcall(function()
                    local v277 = v217["ConfigManager"]:AllConfigs()
                    if v277 then
                        for v278, v279 in ipairs(v277) do
                            table["insert"](v276, v279)
                        end
                    end
                end)
        return v276
    end
local v281 = v268:Dropdown({ ["Title"] = "Select Config", ["Desc"] = "Choose saved config", ["Multi"] = false, ["Flag"] = "SelectedConfigDropdown", ["Value"] = "", ["Values"] = v275(), ["Callback"] = function(v280)
                v273 = v280
            end })
v268:Input({ ["Title"] = "Config Name", ["Desc"] = "New config name", ["PlaceholderText"] = "Enter config name...", ["ClearTextOnFocus"] = false, ["Flag"] = "ConfigNameInput", ["Callback"] = function(v282)
                v274 = v282
            end })
v268:Button({ ["Title"] = "Save Config", ["Desc"] = "Save current settings to new config", ["Callback"] = function()
                if (v274 == "") then
                    v216:Notify({ ["Title"] = "Config", ["Content"] = "Enter config name first!", ["Duration"] = 3 })
                    return
                end
                pcall(function()
                            v273 = v274
                            pcall(function()
                                        v281:Select(v274)
                                    end)
                            local v283 = v217["ConfigManager"]:CreateConfig(v274)
                            v283:Save()
                        end)
                v216:Notify({ ["Title"] = "Config", ["Content"] = ("Config '" .. (v274 .. "' saved successfully!")), ["Duration"] = 3 })
                pcall(function()
                            v281:Refresh(v275())
                            v281:Select(v274)
                        end)
            end })
v268:Button({ ["Title"] = "Load Config", ["Desc"] = "Load selected config", ["Callback"] = function()
                if ((v273 == "") or (v273 == "--")) then
                    v216:Notify({ ["Title"] = "Config", ["Content"] = "Select config first!", ["Duration"] = 3 })
                    return
                end
                pcall(function()
                            local v284 = v217["ConfigManager"]:CreateConfig(v273)
                            v284:Load()
                            pcall(function()
                                        v281:Select(v273)
                                    end)
                        end)
                v216:Notify({ ["Title"] = "Config", ["Content"] = ("Config '" .. (v273 .. "' loaded successfully!")), ["Duration"] = 3 })
            end })
v268:Button({ ["Title"] = "Rewrite Config", ["Desc"] = "Rewrite selected config", ["Callback"] = function()
                if ((v273 == "") or (v273 == "--")) then
                    v216:Notify({ ["Title"] = "Config", ["Content"] = "Select config first!", ["Duration"] = 3 })
                    return
                end
                local v285 = ("WindUI/" .. ((v217["Folder"] or "DX-SR") .. ("/config/" .. (v273 .. ".json"))))
                local v286 = game:GetService("HttpService")
                local v287 = false
                local v288 = {  }
                if ((isfile and isfile(v285)) and readfile) then
                    pcall(function()
                                local v289 = v286:JSONDecode(readfile(v285))
                                if (type(v289) == "table") then
                                    v287 = (v289["__autoload"] or false)
                                    v288 = (v289["__custom"] or {  })
                                end
                            end)
                end
                v299, v300 = pcall(function()
                            pcall(function()
                                        v281:Select(v273)
                                    end)
                            local v290 = {  }
                            local v291 = v217["ConfigManager"]["Parser"]
                            local v292 = ((v217["PendingFlags"] or v217["Flags"]) or {  })
                            for v293, v294 in pairs(v292) do
                                if (((v294 and v294["__type"]) and v291) and v291[v294["__type"]]) then
                                    pcall(function()
                                                v290[tostring(v293)] = v291[v294["__type"]]["Save"](v294)
                                            end)
                                end
                            end
                            local v295 = { ["__version"] = 1.2, ["__elements"] = v290, ["__autoload"] = v287, ["__custom"] = v288 }
                            if writefile then
                                writefile(v285, v286:JSONEncode(v295))
                            end
                            if ((v217["ConfigManager"] and v217["ConfigManager"]["Configs"]) and v217["ConfigManager"]["Configs"][v273]) then
                                local v296 = v217["ConfigManager"]["Configs"][v273]
                                v296["AutoLoad"] = v287
                                v296["CustomData"] = v288
                                if v292 then
                                    for v297, v298 in pairs(v292) do
                                        v296:Register(v297, v298)
                                    end
                                end
                            end
                        end)
                if v299 then
                    v216:Notify({ ["Title"] = "Config", ["Content"] = ("Config '" .. (v273 .. "' rewritten successfully! (Not loaded)")), ["Duration"] = 3 })
                else
                    v216:Notify({ ["Title"] = "Config", ["Content"] = ("Failed to rewrite config: " .. tostring(v300)), ["Duration"] = 3 })
                end
            end })
v268:Button({ ["Title"] = "Delete Config", ["Desc"] = "Delete selected config", ["Callback"] = function()
                if ((v273 == "") or (v273 == "--")) then
                    v216:Notify({ ["Title"] = "Config", ["Content"] = "Select config first!", ["Duration"] = 3 })
                    return
                end
                pcall(function()
                            local v301 = v217["ConfigManager"]:CreateConfig(v273)
                            v301:Delete()
                        end)
                v216:Notify({ ["Title"] = "Config", ["Content"] = ("Config '" .. (v273 .. "' deleted successfully!")), ["Duration"] = 3 })
                v273 = ""
                pcall(function()
                            v281:Refresh(v275())
                            v281:Select("")
                        end)
            end })
v268:Button({ ["Title"] = "Set Auto Load", ["Desc"] = "Automatically load selected config on start", ["Callback"] = function()
                if ((v273 == "") or (v273 == "--")) then
                    v216:Notify({ ["Title"] = "Config", ["Content"] = "Select config first!", ["Duration"] = 3 })
                    return
                end
                pcall(function()
                            local v302 = game:GetService("HttpService")
                            local v303 = v217["ConfigManager"]:AllConfigs()
                            if (((v303 and isfile) and readfile) and writefile) then
                                for v304, v305 in ipairs(v303) do
                                    local v306 = ("WindUI/" .. ((v217["Folder"] or "DX-SR") .. ("/config/" .. (v305 .. ".json"))))
                                    if isfile(v306) then
                                        pcall(function()
                                                    local v307 = v302:JSONDecode(readfile(v306))
                                                    if (type(v307) == "table") then
                                                        v307["__autoload"] = (v305 == v273)
                                                        writefile(v306, v302:JSONEncode(v307))
                                                    end
                                                end)
                                    end
                                end
                            end
                            pcall(function()
                                        v281:Select(v273)
                                    end)
                            if (v217["ConfigManager"] and v217["ConfigManager"]["Configs"]) then
                                for v308, v309 in pairs(v217["ConfigManager"]["Configs"]) do
                                    if (v309 and v309["SetAutoLoad"]) then
                                        v309:SetAutoLoad((v308 == v273))
                                    end
                                end
                            end
                        end)
                v216:Notify({ ["Title"] = "Config", ["Content"] = ("Auto load set to '" .. (v273 .. "'!")), ["Duration"] = 3 })
            end })
pcall(function()
            local v310 = game:GetService("HttpService")
            local v311 = v217["ConfigManager"]:AllConfigs()
            if ((v311 and readfile) and isfile) then
                for v312, v313 in pairs(v311) do
                    local v314 = ("WindUI/" .. ((v217["Folder"] or "DX-SR") .. ("/config/" .. (v313 .. ".json"))))
                    if isfile(v314) then
                        v315, v316 = pcall(function()
                                    return v310:JSONDecode(readfile(v314))
                                end)
                        if ((v315 and (type(v316) == "table")) and v316["__autoload"]) then
                            local v317 = v217["ConfigManager"]:CreateConfig(v313)
                            v317:Load()
                            v273 = v313
                            task["defer"](function()
                                        pcall(function()
                                                    v281:Select(v313)
                                                end)
                                    end)
                            break
                        end
                    end
                end
            end
        end)
v217:EditOpenButton({ ["Title"] = "Open UI", ["Icon"] = "monitor", ["CornerRadius"] = UDim["new"](0, 16), ["StrokeThickness"] = 2, ["Color"] = ColorSequence["new"](Color3["fromHex"]("FF0F7B"), Color3["fromHex"]("F89B29")), ["OnlyMobile"] = false, ["Enabled"] = true, ["<str:449>"] = true })