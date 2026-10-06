--// PROJECT DELTA v5
--// WindUI Edition
--// Part 1/2
--// Home + WallHack + ESP Core + UI foundation

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- WIND UI
--==================================================

local WindUI

local ok, result = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)

if ok then
    WindUI = result
else
    warn("[Project Delta] WindUI failed to load:", result)
    return
end

--==================================================
-- SETTINGS
--==================================================

local Config = {
    Accent = Color3.fromRGB(145, 90, 255),

    ESP = {
        Enabled = false,

        Names = true,
        Distance = true,
        Health = true,

        TeamCheck = false,
        VisCheck = true,

        Boxes = true,
        Skeleton = false,
        Chams = true,

        MaxDistance = 1500,

        VisibleColor = Color3.fromRGB(70, 255, 110),
        HiddenColor = Color3.fromRGB(255, 65, 65),

        NameColor = Color3.fromRGB(255, 255, 255),
        BoxColor = Color3.fromRGB(145, 90, 255),
        SkeletonColor = Color3.fromRGB(255, 255, 255),
    },

    Visuals = {
        FOV = false,
        FOVRadius = 150,
        FOVColor = Color3.fromRGB(145, 90, 255),

        FullBright = false,
        NoFog = false,
    },

    Aim = {
        Enabled = false,
        TeamCheck = true,
        VisCheck = true,
        FOV = 150,
        Smoothness = 0.15,
        TargetPart = "Head",
    },

    World = {
        FPSBoost = false,
        AntiFling = false,
    },

    Menu = {
        Keybind = Enum.KeyCode.RightShift,
    },
}

--==================================================
-- RUNTIME
--==================================================

local ESPObjects = {}
local Connections = {}

local FPS = 0
local LastFPSUpdate = tick()
local FrameCounter = 0

local GameName = game.Name

pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then
        GameName = info.Name
    end
end)

--==================================================
-- HELPERS
--==================================================

local function GetPing()
    local ping = 0

    pcall(function()
        local item =
            Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")

        if item then
            ping = math.floor(item:GetValue())
        end
    end)

    return ping
end

local function GetCharacter(player)
    if not player then
        return nil
    end

    return player.Character
end

local function GetHumanoid(character)
    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function GetRoot(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function IsAlive(player)
    local character = GetCharacter(player)
    local humanoid = GetHumanoid(character)

    return character
        and humanoid
        and humanoid.Health > 0
end

local function IsEnemy(player)
    if player == LocalPlayer then
        return false
    end

    if Config.ESP.TeamCheck then
        if LocalPlayer.Team ~= nil
            and player.Team ~= nil
            and LocalPlayer.Team == player.Team then
            return false
        end
    end

    return true
end

--==================================================
-- VISIBILITY CHECK
--==================================================

local function IsVisible(player)
    local character = GetCharacter(player)

    if not character then
        return false
    end

    local points = {}

    local head = character:FindFirstChild("Head")
    local root = character:FindFirstChild("HumanoidRootPart")
    local upper = character:FindFirstChild("UpperTorso")
    local torso = character:FindFirstChild("Torso")

    if head then
        table.insert(points, head)
    end

    if upper then
        table.insert(points, upper)
    elseif torso then
        table.insert(points, torso)
    end

    if root then
        table.insert(points, root)
    end

    if #points == 0 then
        return false
    end

    for _, part in ipairs(points) do
        local ok, result = pcall(function()
            local direction = part.Position - Camera.CFrame.Position

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {
                LocalPlayer.Character
            }

            params.IgnoreWater = true

            local ray = workspace:Raycast(
                Camera.CFrame.Position,
                direction,
                params
            )

            if not ray then
                return true
            end

            return ray.Instance
                and ray.Instance:IsDescendantOf(character)
        end)

        if ok and result then
            return true
        end
    end

    return false
end

--==================================================
-- ESP FOLDER
--==================================================

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ProjectDelta_ESP"
ESPFolder.Parent = workspace

--==================================================
-- BILLBOARD ESP
--==================================================

local function CreateBillboard(player)
    if not player or player == LocalPlayer then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    local head = character:FindFirstChild("Head")

    if not head then
        return
    end

    local old = head:FindFirstChild("ProjectDeltaESP")

    if old then
        old:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProjectDeltaESP"
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(220, 70)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.MaxDistance = Config.ESP.MaxDistance
    billboard.ResetOnSpawn = false
    billboard.Parent = head

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.BackgroundTransparency = 1
    container.Size = UDim2.fromScale(1, 1)
    container.Parent = billboard

    local layout = Instance.new("UIListLayout")
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 1)
    layout.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextColor3 = Config.ESP.NameColor
    nameLabel.Text = player.DisplayName
    nameLabel.Parent = container

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "Info"
    infoLabel.BackgroundTransparency = 1
    infoLabel.Size = UDim2.new(1, 0, 0, 18)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 12
    infoLabel.TextStrokeTransparency = 0
    infoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    infoLabel.Parent = container

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "Health"
    healthLabel.BackgroundTransparency = 1
    healthLabel.Size = UDim2.new(1, 0, 0, 18)
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 11
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
    healthLabel.Parent = container

    return billboard
end

--==================================================
-- CHAMS
--==================================================

local function CreateChams(player)
    if not player or player == LocalPlayer then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    local old = character:FindFirstChild("ProjectDeltaChams")

    if old then
        old:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ProjectDeltaChams"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    -- IMPORTANT:
    -- These are updated every ESP tick.
    highlight.FillColor = Config.ESP.HiddenColor
    highlight.OutlineColor = Config.ESP.HiddenColor

    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0

    highlight.Enabled = Config.ESP.Enabled
        and Config.ESP.Chams

    highlight.Adornee = character
    highlight.Parent = character

    return highlight
end

--==================================================
-- ESP OBJECT
--==================================================

local function SetupPlayer(player)
    if player == LocalPlayer then
        return
    end

    ESPObjects[player] = ESPObjects[player] or {}

    task.spawn(function()
        local character = player.Character

        if not character then
            character = player.CharacterAdded:Wait()
        end

        task.wait(0.25)

        if not player.Parent then
            return
        end

        ESPObjects[player].Billboard = CreateBillboard(player)
        ESPObjects[player].Chams = CreateChams(player)
    end)
end

local function RemovePlayer(player)
    local data = ESPObjects[player]

    if data then
        if data.Billboard then
            pcall(function()
                data.Billboard:Destroy()
            end)
        end

        if data.Chams then
            pcall(function()
                data.Chams:Destroy()
            end)
        end
    end

    ESPObjects[player] = nil
end

--==================================================
-- ESP UPDATE
--==================================================

local function UpdateESP(player)
    if player == LocalPlayer then
        return
    end

    local data = ESPObjects[player]

    if not data then
        return
    end

    local character = player.Character
    local humanoid = GetHumanoid(character)
    local root = GetRoot(character)

    if not character
        or not humanoid
        or humanoid.Health <= 0
        or not root then

        if data.Billboard then
            data.Billboard.Enabled = false
        end

        if data.Chams then
            data.Chams.Enabled = false
        end

        return
    end

    if not IsEnemy(player) then
        if data.Billboard then
            data.Billboard.Enabled = false
        end

        if data.Chams then
            data.Chams.Enabled = false
        end

        return
    end

    local distance =
        (Camera.CFrame.Position - root.Position).Magnitude

    if distance > Config.ESP.MaxDistance then
        if data.Billboard then
            data.Billboard.Enabled = false
        end

        if data.Chams then
            data.Chams.Enabled = false
        end

        return
    end

    local visible = true

    if Config.ESP.VisCheck then
        visible = IsVisible(player)
    end

    local visColor

    if visible then
        visColor = Config.ESP.VisibleColor
    else
        visColor = Config.ESP.HiddenColor
    end

    --==============================================
    -- BILLBOARD
    --==============================================

    if data.Billboard then
        data.Billboard.Enabled = Config.ESP.Enabled

        local container =
            data.Billboard:FindFirstChild("Container")

        if container then
            local nameLabel =
                container:FindFirstChild("Name")

            local infoLabel =
                container:FindFirstChild("Info")

            local healthLabel =
                container:FindFirstChild("Health")

            if nameLabel then
                nameLabel.Visible = Config.ESP.Names
                nameLabel.Text = player.DisplayName
                nameLabel.TextColor3 = Config.ESP.NameColor
            end

            if infoLabel then
                infoLabel.Visible =
                    Config.ESP.Distance

                if Config.ESP.Distance then
                    infoLabel.Text =
                        string.format(
                            "%d studs",
                            math.floor(distance)
                        )
                end
            end

            if healthLabel then
                healthLabel.Visible =
                    Config.ESP.Health

                if Config.ESP.Health then
                    healthLabel.Text =
                        string.format(
                            "HP: %d",
                            math.floor(humanoid.Health)
                        )

                    healthLabel.TextColor3 =
                        visible
                        and Color3.fromRGB(100, 255, 120)
                        or Color3.fromRGB(255, 90, 90)
                end
            end
        end
    end

    --==============================================
    -- CHAMS
    --==============================================

    if data.Chams then
        data.Chams.Enabled =
            Config.ESP.Enabled
            and Config.ESP.Chams

        -- IMPORTANT:
        -- Chams follow visibility state.
        if Config.ESP.VisCheck then
            data.Chams.FillColor = visColor
            data.Chams.OutlineColor = visColor
        else
            data.Chams.FillColor = Config.ESP.BoxColor
            data.Chams.OutlineColor = Config.ESP.BoxColor
        end

        data.Chams.FillTransparency = 0.55
        data.Chams.OutlineTransparency = 0
    end
end

--==================================================
-- PLAYER CONNECTIONS
--==================================================

for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)

    player.CharacterAdded:Connect(function()
        task.wait(0.5)

        RemovePlayer(player)
        SetupPlayer(player)
    end)
end

Players.PlayerAdded:Connect(function(player)
    SetupPlayer(player)

    player.CharacterAdded:Connect(function()
        task.wait(0.5)

        RemovePlayer(player)
        SetupPlayer(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemovePlayer(player)
end)

--==================================================
-- FPS COUNTER
--==================================================

RunService.RenderStepped:Connect(function()
    FrameCounter += 1

    if tick() - LastFPSUpdate >= 1 then
        FPS = FrameCounter
        FrameCounter = 0
        LastFPSUpdate = tick()
    end
end)

--==================================================
-- ESP LOOP
--==================================================

task.spawn(function()
    while task.wait(0.08) do
        if Config.ESP.Enabled then
            for player in pairs(ESPObjects) do
                pcall(function()
                    UpdateESP(player)
                end)
            end
        else
            for _, data in pairs(ESPObjects) do
                if data.Billboard then
                    data.Billboard.Enabled = false
                end

                if data.Chams then
                    data.Chams.Enabled = false
                end
            end
        end
    end
end)

--==================================================
-- WINDOW
--==================================================

local Window = WindUI:CreateWindow({
    Title = "Project Delta",
    Icon = "zap",
    Author = "v5",
    Folder = "ProjectDelta",
    Size = UDim2.fromOffset(650, 520),
    Transparent = true,
    Theme = "Dark",
    Acrylic = true,
    HideSearchBar = false,
})

--==================================================
-- HOME TAB
--==================================================

local HomeTab = Window:Tab({
    Title = "Home",
    Icon = "house",
})

HomeTab:Paragraph({
    Title = "Project Delta",
    Desc = "Universal Roblox control panel",
})

HomeTab:Paragraph({
    Title = "Player",
    Desc = LocalPlayer.DisplayName
        .. "  @" .. LocalPlayer.Name,
})

HomeTab:Paragraph({
    Title = "Game",
    Desc = GameName,
})

HomeTab:Paragraph({
    Title = "Server",
    Desc = "Players: "
        .. tostring(#Players:GetPlayers())
        .. "\nPing: "
        .. tostring(GetPing())
        .. " ms"
        .. "\nFPS: "
        .. tostring(FPS),
})

--==================================================
-- WALLHACK TAB
--==================================================

local WallHackTab = Window:Tab({
    Title = "WallHack",
    Icon = "scan",
})

WallHackTab:Section({
    Title = "ESP",
})

WallHackTab:Toggle({
    Title = "Enable ESP",
    Desc = "Основной ESP",
    Value = Config.ESP.Enabled,
    Callback = function(value)
        Config.ESP.Enabled = value
    end,
})

WallHackTab:Toggle({
    Title = "Names",
    Value = Config.ESP.Names,
    Callback = function(value)
        Config.ESP.Names = value
    end,
})

WallHackTab:Toggle({
    Title = "Distance",
    Value = Config.ESP.Distance,
    Callback = function(value)
        Config.ESP.Distance = value
    end,
})

WallHackTab:Toggle({
    Title = "Health",
    Value = Config.ESP.Health,
    Callback = function(value)
        Config.ESP.Health = value
    end,
})

WallHackTab:Toggle({
    Title = "Team Check",
    Value = Config.ESP.TeamCheck,
    Callback = function(value)
        Config.ESP.TeamCheck = value
    end,
})

WallHackTab:Toggle({
    Title = "Vis Check",
    Desc = "Зелёный = виден, красный = за стеной",
    Value = Config.ESP.VisCheck,
    Callback = function(value)
        Config.ESP.VisCheck = value
    end,
})

WallHackTab:Toggle({
    Title = "Chams",
    Desc = "Chams автоматически меняют цвет по Vis Check",
    Value = Config.ESP.Chams,
    Callback = function(value)
        Config.ESP.Chams = value
    end,
})

WallHackTab:Slider({
    Title = "Max Distance",
    Desc = "Максимальная дистанция ESP",
    Step = 50,
    Value = {
        Min = 100,
        Max = 5000,
        Default = Config.ESP.MaxDistance,
    },
    Callback = function(value)
        Config.ESP.MaxDistance = tonumber(value) or 1500
    end,
})

WallHackTab:Section({
    Title = "ESP Colors",
})

WallHackTab:Colorpicker({
    Title = "Visible Color",
    Default = Config.ESP.VisibleColor,
    Callback = function(color)
        Config.ESP.VisibleColor = color
    end,
})

WallHackTab:Colorpicker({
    Title = "Hidden Color",
    Default = Config.ESP.HiddenColor,
    Callback = function(color)
        Config.ESP.HiddenColor = color
    end,
})

WallHackTab:Colorpicker({
    Title = "Name Color",
    Default = Config.ESP.NameColor,
    Callback = function(color)
        Config.ESP.NameColor = color
    end,
})

WallHackTab:Colorpicker({
    Title = "Box Color",
    Default = Config.ESP.BoxColor,
    Callback = function(color)
        Config.ESP.BoxColor = color
    end,
})

--==================================================
-- PART 1 END
--==================================================

print("======================================")
print(" Project Delta v5")
print(" Part 1/2 loaded")
print(" WindUI: OK")
print(" ESP Core: OK")
print(" Chams VisCheck: OK")
print("======================================")
--==================================================
-- PROJECT DELTA v5
-- PART 2/2
-- Visuals + Aim + World + Settings + Configs
--==================================================

--==================================================
-- VISUALS TAB
--==================================================

local VisualsTab = Window:Tab({
    Title = "Visuals",
    Icon = "eye",
})

VisualsTab:Section({
    Title = "Visual Settings",
})

VisualsTab:Toggle({
    Title = "Full Bright",
    Desc = "Убирает затемнение карты",
    Value = Config.Visuals.FullBright,

    Callback = function(value)
        Config.Visuals.FullBright = value

        if value then
            pcall(function()
                game:GetService("Lighting").Brightness = 3
                game:GetService("Lighting").ClockTime = 14
                game:GetService("Lighting").FogEnd = 100000
                game:GetService("Lighting").GlobalShadows = false
                game:GetService("Lighting").ExposureCompensation = 0.3
            end)
        end
    end,
})

VisualsTab:Toggle({
    Title = "No Fog",
    Desc = "Убирает туман",

    Value = Config.Visuals.NoFog,

    Callback = function(value)
        Config.Visuals.NoFog = value

        pcall(function()
            local Lighting = game:GetService("Lighting")

            if value then
                Lighting.FogEnd = 100000
                Lighting.FogStart = 100000
            end
        end)
    end,
})

VisualsTab:Section({
    Title = "FOV Circle",
})

VisualsTab:Toggle({
    Title = "FOV Circle",
    Value = Config.Visuals.FOV,

    Callback = function(value)
        Config.Visuals.FOV = value
    end,
})

VisualsTab:Slider({
    Title = "FOV Radius",

    Step = 5,

    Value = {
        Min = 25,
        Max = 500,
        Default = Config.Visuals.FOVRadius,
    },

    Callback = function(value)
        Config.Visuals.FOVRadius = tonumber(value) or 150
    end,
})

VisualsTab:Colorpicker({
    Title = "FOV Color",

    Default = Config.Visuals.FOVColor,

    Callback = function(color)
        Config.Visuals.FOVColor = color
    end,
})

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle

pcall(function()
    FOVCircle = Drawing.new("Circle")

    FOVCircle.Visible = false
    FOVCircle.Filled = false
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 80
    FOVCircle.Radius = Config.Visuals.FOVRadius
    FOVCircle.Color = Config.Visuals.FOVColor
    FOVCircle.Transparency = 1
end)

RunService.RenderStepped:Connect(function()
    if not FOVCircle then
        return
    end

    FOVCircle.Position =
        Vector2.new(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )

    FOVCircle.Radius = Config.Visuals.FOVRadius
    FOVCircle.Color = Config.Visuals.FOVColor

    FOVCircle.Visible =
        Config.Visuals.FOV
end)

--==================================================
-- AIM TAB
--==================================================

local AimTab = Window:Tab({
    Title = "Aim",
    Icon = "crosshair",
})

AimTab:Section({
    Title = "Aim Assist",
})

AimTab:Toggle({
    Title = "Enable Aim Assist",
    Desc = "Наводится на ближайшую цель в FOV",

    Value = Config.Aim.Enabled,

    Callback = function(value)
        Config.Aim.Enabled = value
    end,
})

AimTab:Toggle({
    Title = "Team Check",

    Value = Config.Aim.TeamCheck,

    Callback = function(value)
        Config.Aim.TeamCheck = value
    end,
})

AimTab:Toggle({
    Title = "Visibility Check",

    Value = Config.Aim.VisCheck,

    Callback = function(value)
        Config.Aim.VisCheck = value
    end,
})

AimTab:Slider({
    Title = "Aim FOV",

    Step = 5,

    Value = {
        Min = 25,
        Max = 500,
        Default = Config.Aim.FOV,
    },

    Callback = function(value)
        Config.Aim.FOV = tonumber(value) or 150
    end,
})

AimTab:Slider({
    Title = "Smoothness",

    Step = 0.01,

    Value = {
        Min = 0.01,
        Max = 1,
        Default = Config.Aim.Smoothness,
    },

    Callback = function(value)
        Config.Aim.Smoothness =
            tonumber(value) or 0.15
    end,
})

AimTab:Dropdown({
    Title = "Target Part",

    Values = {
        "Head",
        "UpperTorso",
        "HumanoidRootPart",
    },

    Value = Config.Aim.TargetPart,

    Callback = function(value)
        Config.Aim.TargetPart = value
    end,
})

--==================================================
-- AIM HELPERS
--==================================================

local function GetAimPart(character)
    if not character then
        return nil
    end

    return character:FindFirstChild(Config.Aim.TargetPart)
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end

local function GetClosestTarget()
    local closestPlayer = nil
    local closestDistance = Config.Aim.FOV

    local center =
        Vector2.new(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )

    for _, player in ipairs(Players:GetPlayers()) do

        if player ~= LocalPlayer
            and IsAlive(player) then

            if Config.Aim.TeamCheck then
                if LocalPlayer.Team ~= nil
                    and player.Team ~= nil
                    and LocalPlayer.Team == player.Team then

                    continue
                end
            end

            local character = player.Character
            local part = GetAimPart(character)

            if part then

                if Config.Aim.VisCheck then
                    if not IsVisible(player) then
                        continue
                    end
                end

                local screenPosition, onScreen =
                    Camera:WorldToViewportPoint(part.Position)

                if onScreen then

                    local distance =
                        (
                            Vector2.new(
                                screenPosition.X,
                                screenPosition.Y
                            ) - center
                        ).Magnitude

                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

--==================================================
-- AIM LOOP
--==================================================

RunService.RenderStepped:Connect(function()

    if not Config.Aim.Enabled then
        return
    end

    local target = GetClosestTarget()

    if not target then
        return
    end

    local character = target.Character
    local part = GetAimPart(character)

    if not part then
        return
    end

    local cameraPosition = Camera.CFrame.Position

    local targetCFrame =
        CFrame.new(
            cameraPosition,
            part.Position
        )

    local smooth =
        math.clamp(
            Config.Aim.Smoothness,
            0.01,
            1
        )

    Camera.CFrame =
        Camera.CFrame:Lerp(
            targetCFrame,
            smooth
        )
end)

--==================================================
-- WORLD TAB
--==================================================

local WorldTab = Window:Tab({
    Title = "World",
    Icon = "globe",
})

WorldTab:Section({
    Title = "Performance",
})

WorldTab:Toggle({
    Title = "FPS Boost",

    Desc = "Упрощает некоторые визуальные эффекты",

    Value = Config.World.FPSBoost,

    Callback = function(value)

        Config.World.FPSBoost = value

        if value then

            pcall(function()

                for _, object in ipairs(
                    workspace:GetDescendants()
                ) do

                    if object:IsA("ParticleEmitter")
                        or object:IsA("Trail")
                        or object:IsA("Smoke")
                        or object:IsA("Fire") then

                        object.Enabled = false
                    end

                end

                settings().Rendering.QualityLevel =
                    Enum.QualityLevel.Level01
            end)

        end
    end,
})

WorldTab:Toggle({
    Title = "Anti Fling",

    Desc = "Защита от локального физического fling",

    Value = Config.World.AntiFling,

    Callback = function(value)

        Config.World.AntiFling = value

    end,
})

--==================================================
-- ANTI FLING
--==================================================

RunService.Heartbeat:Connect(function()

    if not Config.World.AntiFling then
        return
    end

    local character = LocalPlayer.Character

    if not character then
        return
    end

    for _, object in ipairs(
        character:GetDescendants()
    ) do

        if object:IsA("BasePart") then

            if object.AssemblyLinearVelocity.Magnitude > 250 then
                object.AssemblyLinearVelocity =
                    Vector3.zero
            end

            if object.AssemblyAngularVelocity.Magnitude > 250 then
                object.AssemblyAngularVelocity =
                    Vector3.zero
            end

        end
    end
end)

--==================================================
-- SETTINGS TAB
--==================================================

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

SettingsTab:Section({
    Title = "Menu",
})

SettingsTab:Keybind({
    Title = "Toggle Menu",

    Value = Config.Menu.Keybind,

    Callback = function(value)
        Config.Menu.Keybind = value
    end,
})

SettingsTab:Colorpicker({
    Title = "Accent Color",

    Default = Config.Accent,

    Callback = function(color)

        Config.Accent = color

        pcall(function()
            WindUI:SetTheme({
                Accent = color,
            })
        end)

    end,
})

--==================================================
-- CONFIG SYSTEM
--==================================================

local ConfigFolder = "ProjectDelta"

local ConfigCache = {}

local function CanUseFiles()
    return
        isfolder ~= nil
        and makefolder ~= nil
        and writefile ~= nil
        and readfile ~= nil
        and isfile ~= nil
end

pcall(function()

    if CanUseFiles() then

        if not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        end

    end

end)

local function SafeConfigName(name)

    name = tostring(name or "default")

    name = name:gsub(
        "[^%w_%-%s]",
        ""
    )

    name = name:gsub(
        "%s+",
        "_"
    )

    if name == "" then
        name = "default"
    end

    return name
end

local function SerializeConfig()

    local data = {
        Accent = {
            R = Config.Accent.R,
            G = Config.Accent.G,
            B = Config.Accent.B,
        },

        ESP = {
            Enabled = Config.ESP.Enabled,
            Names = Config.ESP.Names,
            Distance = Config.ESP.Distance,
            Health = Config.ESP.Health,
            TeamCheck = Config.ESP.TeamCheck,
            VisCheck = Config.ESP.VisCheck,
            Boxes = Config.ESP.Boxes,
            Skeleton = Config.ESP.Skeleton,
            Chams = Config.ESP.Chams,
            MaxDistance = Config.ESP.MaxDistance,

            VisibleColor = {
                R = Config.ESP.VisibleColor.R,
                G = Config.ESP.VisibleColor.G,
                B = Config.ESP.VisibleColor.B,
            },

            HiddenColor = {
                R = Config.ESP.HiddenColor.R,
                G = Config.ESP.HiddenColor.G,
                B = Config.ESP.HiddenColor.B,
            },

            NameColor = {
                R = Config.ESP.NameColor.R,
                G = Config.ESP.NameColor.G,
                B = Config.ESP.NameColor.B,
            },

            BoxColor = {
                R = Config.ESP.BoxColor.R,
                G = Config.ESP.BoxColor.G,
                B = Config.ESP.BoxColor.B,
            },
        },

        Visuals = {
            FOV = Config.Visuals.FOV,
            FOVRadius = Config.Visuals.FOVRadius,
            FullBright = Config.Visuals.FullBright,
            NoFog = Config.Visuals.NoFog,
        },

        Aim = {
            Enabled = Config.Aim.Enabled,
            TeamCheck = Config.Aim.TeamCheck,
            VisCheck = Config.Aim.VisCheck,
            FOV = Config.Aim.FOV,
            Smoothness = Config.Aim.Smoothness,
            TargetPart = Config.Aim.TargetPart,
        },

        World = {
            FPSBoost = Config.World.FPSBoost,
            AntiFling = Config.World.AntiFling,
        },
    }

    return data
end

local function ColorFromData(data, fallback)

    if type(data) ~= "table" then
        return fallback
    end

    return Color3.new(
        tonumber(data.R) or fallback.R,
        tonumber(data.G) or fallback.G,
        tonumber(data.B) or fallback.B
    )
end

local function ApplyConfig(data)

    if type(data) ~= "table" then
        return false
    end

    if data.Accent then
        Config.Accent =
            ColorFromData(
                data.Accent,
                Config.Accent
            )
    end

    if data.ESP then

        for key, value in pairs(data.ESP) do

            if key ~= "VisibleColor"
                and key ~= "HiddenColor"
                and key ~= "NameColor"
                and key ~= "BoxColor" then

                if Config.ESP[key] ~= nil then
                    Config.ESP[key] = value
                end

            end
        end

        Config.ESP.VisibleColor =
            ColorFromData(
                data.ESP.VisibleColor,
                Config.ESP.VisibleColor
            )

        Config.ESP.HiddenColor =
            ColorFromData(
                data.ESP.HiddenColor,
                Config.ESP.HiddenColor
            )

        Config.ESP.NameColor =
            ColorFromData(
                data.ESP.NameColor,
                Config.ESP.NameColor
            )

        Config.ESP.BoxColor =
            ColorFromData(
                data.ESP.BoxColor,
                Config.ESP.BoxColor
            )
    end

    if data.Visuals then

        for key, value in pairs(data.Visuals) do

            if Config.Visuals[key] ~= nil then
                Config.Visuals[key] = value
            end

        end
    end

    if data.Aim then

        for key, value in pairs(data.Aim) do

            if Config.Aim[key] ~= nil then
                Config.Aim[key] = value
            end

        end
    end

    if data.World then

        for key, value in pairs(data.World) do

            if Config.World[key] ~= nil then
                Config.World[key] = value
            end

        end
    end

    return true
end

--==================================================
-- CONFIG NAME
--==================================================

local CurrentConfigName = "default"

SettingsTab:Input({
    Title = "Config Name",

    Placeholder = "my_config",

    Value = CurrentConfigName,

    Callback = function(value)

        if value and value ~= "" then
            CurrentConfigName =
                SafeConfigName(value)
        end

    end,
})

--==================================================
-- SAVE CONFIG
--==================================================

SettingsTab:Button({
    Title = "Save Config",

    Desc = "Сохранить текущие настройки",

    Callback = function()

        local name =
            SafeConfigName(CurrentConfigName)

        local data =
            SerializeConfig()

        local success = false

        if CanUseFiles() then

            success = pcall(function()

                writefile(
                    ConfigFolder
                    .. "/"
                    .. name
                    .. ".json",

                    HttpService:JSONEncode(data)
                )

            end)

        else

            ConfigCache[name] = data
            success = true

        end

        if success then
            print(
                "[Project Delta] Config saved:",
                name
            )
        else
            warn(
                "[Project Delta] Failed to save config"
            )
        end

    end,
})

--==================================================
-- LOAD CONFIG
--==================================================

SettingsTab:Button({
    Title = "Load Config",

    Desc = "Загрузить сохранённую конфигурацию",

    Callback = function()

        local name =
            SafeConfigName(CurrentConfigName)

        local data = nil

        if CanUseFiles() then

            local success, result =
                pcall(function()

                    local path =
                        ConfigFolder
                        .. "/"
                        .. name
                        .. ".json"

                    if not isfile(path) then
                        return nil
                    end

                    return HttpService:JSONDecode(
                        readfile(path)
                    )

                end)

            if success then
                data = result
            end

        else

            data = ConfigCache[name]

        end

        if data then

            if ApplyConfig(data) then

                print(
                    "[Project Delta] Config loaded:",
                    name
                )

            end

        else

            warn(
                "[Project Delta] Config not found:",
                name
            )

        end

    end,
})

--==================================================
-- CREATE CONFIG
--==================================================

SettingsTab:Button({
    Title = "Create Config",

    Desc = "Создать новый пустой конфиг",

    Callback = function()

        local name =
            SafeConfigName(CurrentConfigName)

        local data =
            SerializeConfig()

        if CanUseFiles() then

            pcall(function()

                writefile(
                    ConfigFolder
                    .. "/"
                    .. name
                    .. ".json",

                    HttpService:JSONEncode(data)
                )

            end)

        else

            ConfigCache[name] = data

        end

        print(
            "[Project Delta] Config created:",
            name
        )

    end,
})

--==================================================
-- DELETE CONFIG
--==================================================

SettingsTab:Button({
    Title = "Delete Config",

    Desc = "Удалить текущий конфиг",

    Callback = function()

        local name =
            SafeConfigName(CurrentConfigName)

        if CanUseFiles() then

            pcall(function()

                local path =
                    ConfigFolder
                    .. "/"
                    .. name
                    .. ".json"

                if isfile(path) then
                    delfile(path)
                end

            end)

        else

            ConfigCache[name] = nil

        end

        print(
            "[Project Delta] Config deleted:",
            name
        )

    end,
})

--==================================================
-- RESET
--==================================================

SettingsTab:Button({
    Title = "Reset ESP",

    Desc = "Сбросить основные ESP настройки",

    Callback = function()

        Config.ESP.Enabled = false
        Config.ESP.Names = true
        Config.ESP.Distance = true
        Config.ESP.Health = true
        Config.ESP.TeamCheck = false
        Config.ESP.VisCheck = true
        Config.ESP.Chams = true
        Config.ESP.MaxDistance = 1500

        print(
            "[Project Delta] ESP reset"
        )

    end,
})

--==================================================
-- MENU KEY
--==================================================

UserInputService.InputBegan:Connect(
    function(input, processed)

        if processed then
            return
        end

        if input.KeyCode == Config.Menu.Keybind then

            pcall(function()

                if Window then

                    Window:Toggle()

                end

            end)

        end

    end
)

--==================================================
-- CHARACTER RESPAWN REBUILD
--==================================================

LocalPlayer.CharacterAdded:Connect(
    function()

        task.wait(1)

        for player in ipairs(Players:GetPlayers()) do

            if player ~= LocalPlayer then

                task.spawn(function()

                    RemovePlayer(player)
                    SetupPlayer(player)

                end)

            end

        end

    end
)

--==================================================
-- LIGHTING UPDATE
--==================================================

local Lighting = game:GetService("Lighting")

RunService.Heartbeat:Connect(function()

    if Config.Visuals.FullBright then

        pcall(function()

            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.ExposureCompensation = 0.3

        end)

    end

    if Config.Visuals.NoFog then

        pcall(function()

            Lighting.FogStart = 100000
            Lighting.FogEnd = 100000

        end)

    end

end)

--==================================================
-- WINDOW START
--==================================================

pcall(function()

    Window:SelectTab(1)

end)

print("======================================")
print(" Project Delta v5")
print(" FULL VERSION LOADED")
print(" WindUI       : OK")
print(" Home         : OK")
print(" WallHack     : OK")
print(" Visuals      : OK")
print(" Aim          : OK")
print(" World        : OK")
print(" Settings     : OK")
print(" Configs      : OK")
print(" Chams        : OK")
print(" VisCheck     : OK")
print("======================================")
