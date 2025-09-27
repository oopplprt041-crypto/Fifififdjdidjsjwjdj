--// ===== ESP Script with Box + Item ESP + Toggle GUI =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESP_ENABLED = false
local ESP_OBJECTS = {}
local ESP_CONNS = {}

-- ฟังก์ชันลบ ESP ทั้งหมด
local function ClearESP()
    for _, obj in pairs(ESP_OBJECTS) do
        if obj and obj.Parent then obj:Destroy() end
    end
    ESP_OBJECTS = {}
    for _, c in pairs(ESP_CONNS) do
        if c.Connected then c:Disconnect() end
    end
    ESP_CONNS = {}
end

-- ฟังก์ชันสร้างกล่องรอบ Part
local function CreateBox(targetPart, color)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = targetPart
    box.Size = targetPart.Size
    box.Color3 = color or Color3.fromRGB(0,255,0)
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.6
    box.Parent = game.CoreGui
    return box
end

-- ฟังก์ชันสร้าง ESP ให้ Player
local function CreateESP(player)
    if player == LocalPlayer then return end

    local function SetupChar(char)
        if not ESP_ENABLED then return end
        local head = char:WaitForChild("Head", 5)
        if not head then return end

        -- Billboard GUI
        local Billboard = Instance.new("BillboardGui")
        Billboard.Name = "ESP_"..player.Name
        Billboard.Size = UDim2.new(0,250,0,20)
        Billboard.StudsOffset = Vector3.new(0,3,0)
        Billboard.AlwaysOnTop = true

        local Label = Instance.new("TextLabel", Billboard)
        Label.Size = UDim2.new(1,0,1,0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(255,0,0)
        Label.TextStrokeTransparency = 0.5
        Label.Font = Enum.Font.GothamBold
        Label.TextScaled = true

        Billboard.Parent = head
        ESP_OBJECTS[player.Name] = Billboard

        -- กล่องรอบตัวละคร
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                ESP_OBJECTS[player.Name.."_"..part.Name] = CreateBox(part, Color3.fromRGB(0,255,0))
            end
        end

        -- อัปเดตเรียลไทม์
        local conn = RunService.RenderStepped:Connect(function()
            if ESP_ENABLED and player.Character and player.Character:FindFirstChild("Humanoid") and LocalPlayer.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if humanoid and root and localRoot then
                    local dist = (localRoot.Position - root.Position).Magnitude
                    Label.Text = string.format("%s | @%s | HP:%d/%d | %d studs",
                        player.DisplayName,
                        player.Name,
                        math.floor(humanoid.Health),
                        math.floor(humanoid.MaxHealth),
                        math.floor(dist)
                    )
                end
            else
                Label.Text = ""
            end

            -- Item ESP
            local tool = player.Character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Handle") then
                if not ESP_OBJECTS[player.Name.."_Item"] then
                    ESP_OBJECTS[player.Name.."_Item"] = CreateBox(tool.Handle, Color3.fromRGB(255,255,0))
                end
            elseif ESP_OBJECTS[player.Name.."_Item"] then
                ESP_OBJECTS[player.Name.."_Item"]:Destroy()
                ESP_OBJECTS[player.Name.."_Item"] = nil
            end
        end)
        table.insert(ESP_CONNS, conn)
    end

    if player.Character then
        SetupChar(player.Character)
    end
    player.CharacterAdded:Connect(SetupChar)
end

-- ฟังก์ชันเปิด ESP
local function EnableESP()
    ClearESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            CreateESP(p)
        end
    end
end

-- Player เข้าใหม่
Players.PlayerAdded:Connect(function(p)
    if ESP_ENABLED then
        CreateESP(p)
    end
end)

-- Player ออก
Players.PlayerRemoving:Connect(function(p)
    -- ลบ Billboard
    if ESP_OBJECTS[p.Name] then
        ESP_OBJECTS[p.Name]:Destroy()
        ESP_OBJECTS[p.Name] = nil
    end
    -- ลบ Item Box
    if ESP_OBJECTS[p.Name.."_Item"] then
        ESP_OBJECTS[p.Name.."_Item"]:Destroy()
        ESP_OBJECTS[p.Name.."_Item"] = nil
    end
    -- ลบ Box ส่วนอื่น
    for k, obj in pairs(ESP_OBJECTS) do
        if string.find(k, p.Name.."_") and obj then
            obj:Destroy()
            ESP_OBJECTS[k] = nil
        end
    end
end)

-- ===== GUI Toggle =====
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "ESP_Toggle"

local Button = Instance.new("TextButton", ScreenGui)
Button.Size = UDim2.new(0,100,0,30)
Button.Position = UDim2.new(0.05,0,0.1,0)
Button.Text = "วานลิต: ปิดอยู่"
Button.BackgroundColor3 = Color3.fromRGB(30,30,30)
Button.TextColor3 = Color3.fromRGB(255,255,255)
Button.Font = Enum.Font.GothamBold
Button.TextScaled = true
Button.BorderSizePixel = 0
Button.BackgroundTransparency = 0.4

Button.MouseEnter:Connect(function()
    Button.BackgroundTransparency = 0.1
end)
Button.MouseLeave:Connect(function()
    Button.BackgroundTransparency = 0.4
end)

Button.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    if ESP_ENABLED then
        Button.Text = "วานลิต : เปิดอยู่"
        EnableESP()
    else
        Button.Text = "วานลิต : ปิดอยู่"
        ClearESP()
    end
end)
