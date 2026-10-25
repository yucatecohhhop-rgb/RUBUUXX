--[[
    Script: The Maze - Full Edition v2
    Executor: Delta
    Librería: Rayfield
]]

-- 1. Cargar Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 2. Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 3. Ventana Principal
local Window = Rayfield:CreateWindow({
    Name = "The Maze | v2",
    LoadingTitle = "Cargando...",
    LoadingSubtitle = "by tu compa",
    ConfigurationSaving = { Enabled = true, FolderName = "TheMaze", FileName = "Config" },
    KeySystem = false
})

-- =========================================================
-- VISUALES (Monstruos con color, Jugadores verde fijo)
-- =========================================================
local VisualTab = Window:CreateTab("Visuales 👿", 4483362458)

local ESP_Enabled = false
local ESP_Monsters = false
local ESP_Players = false

local ColorSeguro = Color3.fromRGB(0, 255, 0)
local ColorCerca = Color3.fromRGB(255, 255, 0)
local ColorPeligro = Color3.fromRGB(255, 0, 0)
local ColorJugador = Color3.fromRGB(0, 255, 0) -- Verde fijo para jugadores

local DistanciaCerca = 50
local DistanciaPeligro = 20

local ESPObjects = {}

local function GetColorByDistance(dist)
    if dist <= DistanciaPeligro then return ColorPeligro end
    if dist <= DistanciaCerca then return ColorCerca end
    return ColorSeguro
end

local function UpdateESP(character, isMonster)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local espData = ESPObjects[character]
    if not espData then
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Transparency = 1
        
        local nameText = Drawing.new("Text")
        nameText.Size = 14
        nameText.Center = true
        nameText.Outline = true
        nameText.Font = 2
        
        local distText = Drawing.new("Text")
        distText.Size = 12
        distText.Center = true
        distText.Outline = true
        
        local highlight = Instance.new("Highlight")
        highlight.Parent = character
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        espData = { Line = line, NameText = nameText, DistText = distText, Highlight = highlight, IsMonster = isMonster }
        ESPObjects[character] = espData
    end
end

RunService.RenderStepped:Connect(function()
    if not ESP_Enabled then
        for _, data in pairs(ESPObjects) do
            data.Line.Visible = false
            data.NameText.Visible = false
            data.DistText.Visible = false
            if data.Highlight then data.Highlight.Enabled = false end
        end
        return
    end

    -- Actualizar jugadores (solo si está activado)
    if ESP_Players then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                UpdateESP(player.Character, false)
            end
        end
    end

    -- Actualizar monstruos
    if ESP_Monsters then
        for _, obj in pairs(Workspace:GetChildren()) do
            local nameLower = obj.Name:lower()
            if (nameLower:find("orotund") or nameLower:find("cajoler") or nameLower:find("monster")) and obj:FindFirstChild("HumanoidRootPart") then
                UpdateESP(obj, true)
            end
        end
    end

    -- Renderizar
    for char, data in pairs(ESPObjects) do
        if not char or not char.Parent then
            data.Line:Remove()
            data.NameText:Remove()
            data.DistText:Remove()
            if data.Highlight then data.Highlight:Destroy() end
            ESPObjects[char] = nil
            continue
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end
        local dist = (root.Position - myRoot.Position).Magnitude

        local shouldShow = false
        if data.IsMonster and ESP_Monsters then shouldShow = true end
        if not data.IsMonster and ESP_Players then shouldShow = true end
        if not shouldShow then
            data.Line.Visible = false
            data.NameText.Visible = false
            data.DistText.Visible = false
            if data.Highlight then data.Highlight.Enabled = false end
            continue
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            data.Line.Visible = false
            data.NameText.Visible = false
            data.DistText.Visible = false
            if data.Highlight then data.Highlight.Enabled = false end
            continue
        end

        -- Color: Monstruos cambian por distancia, Jugadores verde fijo
        local color
        if data.IsMonster then
            color = GetColorByDistance(dist)
        else
            color = ColorJugador
        end

        local screenSize = Camera.ViewportSize
        data.Line.From = Vector2.new(screenSize.X / 2, screenSize.Y)
        data.Line.To = Vector2.new(screenPos.X, screenPos.Y)
        data.Line.Color = color
        data.Line.Visible = true

        local displayName = data.IsMonster and ("👿 " .. char.Name) or ("👤 " .. char.Name)
        data.NameText.Text = displayName
        data.NameText.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
        data.NameText.Color = color
        data.NameText.Visible = true

        data.DistText.Text = string.format("[%d m]", math.floor(dist))
        data.DistText.Position = Vector2.new(screenPos.X, screenPos.Y - 10)
        data.DistText.Color = color
        data.DistText.Visible = true

        if data.Highlight then
            data.Highlight.FillColor = color
            data.Highlight.OutlineColor = color
            data.Highlight.Enabled = true
        end
    end
end)

VisualTab:CreateToggle({ Name = "Activar Visuales", CurrentValue = false, Flag = "ESP_General", Callback = function(v) ESP_Enabled = v end })
VisualTab:CreateToggle({ Name = "👿 Monstruos (Color por distancia)", CurrentValue = false, Flag = "ESP_Monsters", Callback = function(v) ESP_Monsters = v end })
VisualTab:CreateToggle({ Name = "👤 Jugadores (Verde fijo)", CurrentValue = false, Flag = "ESP_Players", Callback = function(v) ESP_Players = v end })

VisualTab:CreateSlider({ Name = "Distancia Peligro (Rojo)", Range = {5, 100}, Increment = 5, Suffix = "m", CurrentValue = 20, Flag = "DistPeligro", Callback = function(v) DistanciaPeligro = v end })
VisualTab:CreateSlider({ Name = "Distancia Cerca (Amarillo)", Range = {10, 200}, Increment = 5, Suffix = "m", CurrentValue = 50, Flag = "DistCerca", Callback = function(v) DistanciaCerca = v end })

-- =========================================================
-- SISTEMA DE TP CON BYPASS
-- =========================================================
local TPTab = Window:CreateTab("TP 📍", 4483362458)

local Waypoints = { [1] = nil, [2] = nil, [3] = nil, [4] = nil, [5] = nil }
local WaypointVisuals = {}

local function CreateWaypointVisual(slot, position)
    if WaypointVisuals[slot] then WaypointVisuals[slot]:Destroy() end
    local part = Instance.new("Part")
    part.Size = Vector3.new(2, 4, 2)
    part.Position = position + Vector3.new(0, 2, 0)
    part.Anchored = true
    part.CanCollide = false
    part.Color = Color3.fromRGB(0, 255, 255)
    part.Material = Enum.Material.Neon
    part.Transparency = 0.5
    part.Name = "WaypointVisual_" .. slot
    part.Parent = Workspace
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = "TP " .. slot
    text.TextColor3 = Color3.fromRGB(0, 255, 255)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard
    
    WaypointVisuals[slot] = part
end

local function RemoveWaypointVisual(slot)
    if WaypointVisuals[slot] then
        WaypointVisuals[slot]:Destroy()
        WaypointVisuals[slot] = nil
    end
end

local function SetWaypoint(slot)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    Waypoints[slot] = hrp.Position
    CreateWaypointVisual(slot, hrp.Position)
    Rayfield:Notify({Title = "TP " .. slot, Content = "Ubicación marcada", Duration = 2})
    UpdateFloatingButtons()
end

local function ClearWaypoint(slot)
    Waypoints[slot] = nil
    RemoveWaypointVisual(slot)
    Rayfield:Notify({Title = "TP " .. slot, Content = "Marcador eliminado", Duration = 2})
    UpdateFloatingButtons()
end

-- Bypass de Teleport (Resetea velocidad y usa Swim temporal)
local function BypassTeleport(slot)
    if not Waypoints[slot] then
        Rayfield:Notify({Title = "TP " .. slot, Content = "No hay ubicación", Duration = 2})
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if hrp and humanoid then
        -- Resetear velocidad para evitar detección
        pcall(function()
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
        end)
        
        -- Método Swim (evita que el anti-cheat te regrese)
        humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        task.wait(0.1)
        
        hrp.CFrame = CFrame.new(Waypoints[slot] + Vector3.new(0, 3, 0))
        
        task.delay(0.5, function()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
        
        Rayfield:Notify({Title = "TP " .. slot, Content = "Teletransportado (Bypass)", Duration = 2})
    end
end

for i = 1, 5 do
    TPTab:CreateButton({ Name = "Marcar TP " .. i, Callback = function() SetWaypoint(i) end })
    TPTab:CreateButton({ Name = "Borrar TP " .. i, Callback = function() ClearWaypoint(i) end })
end

-- =========================================================
-- MENÚ FLOTANTE DE TP (Con Drag)
-- =========================================================
local FloatingGui = Instance.new("ScreenGui")
FloatingGui.Name = "TP_FloatingMenu"
FloatingGui.ResetOnSpawn = false
FloatingGui.Parent = game.CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -25)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
ToggleBtn.Text = "TP"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextScaled = true
ToggleBtn.Parent = FloatingGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local FloatFrame = Instance.new("Frame")
FloatFrame.Size = UDim2.new(0, 120, 0, 220)
FloatFrame.Position = UDim2.new(0, 80, 0.5, -100)
FloatFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FloatFrame.BorderSizePixel = 0
FloatFrame.Visible = false
FloatFrame.Parent = FloatingGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = FloatFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 4)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = FloatFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "Waypoints (Arrastra)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.Parent = FloatFrame
Title.LayoutOrder = 0

local FloatingButtons = {}

function UpdateFloatingButtons()
    for i = 1, 5 do
        if Waypoints[i] then
            if not FloatingButtons[i] then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.9, 0, 0, 30)
                btn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
                btn.Text = "TP " .. i
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Font = Enum.Font.GothamBold
                btn.TextScaled = true
                btn.Parent = FloatFrame
                btn.LayoutOrder = i
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = btn
                
                btn.MouseButton1Click:Connect(function() BypassTeleport(i) end)
                FloatingButtons[i] = btn
            end
            FloatingButtons[i].Visible = true
        else
            if FloatingButtons[i] then
                FloatingButtons[i]:Destroy()
                FloatingButtons[i] = nil
            end
        end
    end
end

-- Drag para el Frame
local draggingFrame = false
local dragStartFrame = nil
local startPosFrame = nil

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFrame = true
        dragStartFrame = input.Position
        startPosFrame = FloatFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingFrame and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartFrame
        FloatFrame.Position = UDim2.new(startPosFrame.X.Scale, startPosFrame.X.Offset + delta.X, startPosFrame.Y.Scale, startPosFrame.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFrame = false
    end
end)

-- Drag para el Botón
local draggingBtn = false
local dragStartBtn = nil
local startPosBtn = nil

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBtn = true
        dragStartBtn = input.Position
        startPosBtn = ToggleBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingBtn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartBtn
        ToggleBtn.Position = UDim2.new(startPosBtn.X.Scale, startPosBtn.X.Offset + delta.X, startPosBtn.Y.Scale, startPosBtn.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBtn = false
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    FloatFrame.Visible = not FloatFrame.Visible
    if FloatFrame.Visible then UpdateFloatingButtons() end
end)

-- =========================================================
-- PESTAÑA HACKS
-- =========================================================
local HacksTab = Window:CreateTab("HACKS 💀", 4483362458)

-- 1. Speed
local speedValue = 16
HacksTab:CreateSlider({
    Name = "Velocidad (Speed)",
    Range = {16, 100},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(v)
        speedValue = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})

-- 2. Salto Infinito
local infJumpEnabled = false
HacksTab:CreateToggle({ Name = "Salto Infinito", CurrentValue = false, Flag = "InfJump", Callback = function(v) infJumpEnabled = v end })

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- 3. Noclip Mejorado
local noclipEnabled = false
HacksTab:CreateToggle({ Name = "Noclip (Atravesar paredes)", CurrentValue = false, Flag = "Noclip", Callback = function(v) noclipEnabled = v end })

RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 4. ESP de Objetos (Menos piedras)
local ObjectESPEnabled = false
local ObjectESPVisuals = {}

local function IsIgnoredObject(name)
    local lower = name:lower()
    -- Ignora piedras, partes del cuerpo y partes genéricas
    return lower:find("rock") or lower:find("stone") or lower:find("piedra") or lower == "part" or lower:find("arm") or lower:find("leg") or lower:find("torso")
end

local function CreateObjectESP(obj)
    if not obj:IsA("BasePart") then return end
    if IsIgnoredObject(obj.Name) then return end
    if ObjectESPVisuals[obj] then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = obj
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 0.5
    text.BackgroundColor3 = Color3.new(0, 0, 0)
    text.Text = obj.Name
    text.TextColor3 = Color3.fromRGB(255, 255, 0)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard
    
    ObjectESPVisuals[obj] = billboard
end

HacksTab:CreateToggle({
    Name = "ESP Objetos (Solo items útiles)",
    CurrentValue = false,
    Flag = "ObjectESP",
    Callback = function(v)
        ObjectESPEnabled = v
        if v then
            for _, obj in pairs(Workspace:GetDescendants()) do
                CreateObjectESP(obj)
            end
        else
            for obj, gui in pairs(ObjectESPVisuals) do
                gui:Destroy()
                ObjectESPVisuals[obj] = nil
            end
        end
    end
})

-- 5. Llenar Inventario de Baterías
local fillBatteriesEnabled = false
HacksTab:CreateToggle({
    Name = "Llenar Inventario de Baterías",
    CurrentValue = false,
    Flag = "FillBatteries",
    Callback = function(v) fillBatteriesEnabled = v end
})

task.spawn(function()
    while true do
        task.wait(1)
        if fillBatteriesEnabled then
            local char = LocalPlayer.Character
            if char then
                -- Busca baterías en el mapa y las mueve hacia el jugador
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name:lower():find("battery") or obj.Name:lower():find("bateria") then
                        if obj:IsA("BasePart") then
                            -- Mueve la batería al inventario (simula recogida)
                            if fireproximityprompt then
                                for _, prompt in pairs(obj:GetDescendants()) do
                                    if prompt:IsA("ProximityPrompt") then
                                        fireproximityprompt(prompt)