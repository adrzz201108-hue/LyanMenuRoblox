-- [Core] LYAN MENU v6.0 | Ultimate Universal Mod Menu
-- [Build] Solara Compatible | Precision Aimbot & Troll Functions

-- ================================================================
-- [Security] AntiCheat Hook & Solara Optimizations
-- ================================================================
pcall(function()
    if hookmetamethod and getnamecallmethod then
        local oldNamecall
        local function isLocalScript()
            if checkcaller then return checkcaller() end
            if iscclosure then
                local callingScript = getfenv(2).script
                return callingScript and callingScript:IsDescendantOf(Player)
            end
            return false
        end
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            
            -- Silent Aim & Wallbang (Raycast Interception)
            if (Configs.SilentAim or Configs.Wallbang) and (method == "Raycast" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
                local target = nil
                -- Achar alvo
                local dist = math.huge
                for _, v in pairs(game:GetService("Players"):GetPlayers()) do
                    if v ~= Player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                        local hrp = v.Character.HumanoidRootPart
                        local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
                            local d = (Vector2.new(vector.X, vector.Y) - mousePos).Magnitude
                            if d < Configs.Fov and d < dist then
                                target = v
                                dist = d
                            end
                        end
                    end
                end
                
                if target and target.Character and target.Character:FindFirstChild("Head") then
                    local args = {...}
                    if method == "Raycast" then
                        local origin = args[1]
                        local dir = args[2]
                        local params = args[3]
                        if Configs.SilentAim then
                            dir = (target.Character.Head.Position - origin).Unit * (dir.Magnitude > 10 and dir.Magnitude or 1000)
                        end
                        if Configs.Wallbang then
                            if not params then params = RaycastParams.new() end
                            params.FilterType = Enum.RaycastFilterType.Include
                            local whitelist = {}
                            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                                if p ~= Player and p.Character then table.insert(whitelist, p.Character) end
                            end
                            params.FilterDescendantsInstances = whitelist
                        end
                        args[2] = dir
                        args[3] = params
                        return oldNamecall(self, unpack(args))
                    elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                        local ray = args[1]
                        if Configs.SilentAim then
                            ray = Ray.new(ray.Origin, (target.Character.Head.Position - ray.Origin).Unit * (ray.Direction.Magnitude > 10 and ray.Direction.Magnitude or 1000))
                            args[1] = ray
                        end
                        -- We can't perfectly wallbang legacy rays easily without changing ignore lists deeply, so we just redirect
                        return oldNamecall(self, unpack(args))
                    end
                end
            end

            -- Weapon Hit FireServer Hook (Silent Aim for server-hit games)
            if method == "FireServer" and (Configs.SilentAim or Configs.Wallbang) then
                if self.Name == "Hit" or self.Name == "Damage" or self.Name == "Shoot" or self.Name == "Fire" or self.Name == "WeaponHit" or self.Name == "BulletHit" then
                    local target = nil
                    local dist = math.huge
                    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
                        if v ~= Player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                            local hrp = v.Character.HumanoidRootPart
                            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                local mousePos = game:GetService("UserInputService"):GetMouseLocation()
                                local d = (Vector2.new(vector.X, vector.Y) - mousePos).Magnitude
                                if d < Configs.Fov and d < dist then
                                    target = v
                                    dist = d
                                end
                            end
                        end
                    end
                    if target and target.Character and target.Character:FindFirstChild("Head") then
                        local args = {...}
                        for i, v in ipairs(args) do
                            if typeof(v) == "Instance" and v:IsA("BasePart") then
                                args[i] = target.Character.Head
                            elseif typeof(v) == "Vector3" then
                                args[i] = target.Character.Head.Position
                            end
                        end
                        return oldNamecall(self, unpack(args))
                    end
                end
            end

            if not isLocalScript() then
                if method == "Kick" or method == "kick" or method == "Ban" then return end -- Block Kick/Ban calls
                -- Anti-Screenshot for AntiCheats
                if Configs.AntiScreenshot and (method == "GetScreenshotAsPng" or method == "TakeScreenshot" or method == "CaptureScreenshot" or method == "CaptureRecord") then
                    return -- Block screenshot attempts from server/game scripts
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

-- Check for native mouse movement
local hasMouseMoverel = (mousemoverel ~= nil)

-- [Mobile Support] Detection & Responsive Sizing
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MenuWidth = isMobile and 500 or 650
local MenuHeight = isMobile and 320 or 440
local SidebarWidth = isMobile and 120 or 150

-- [Config] Runtime state table
local Configs = {
    -- Aimbot
    Aimbot = false, Hotkey = "MouseButton2", LockPart = "Head", TargetDead = false,
    StickyAimbot = false, Smoothing = true, Smoothness = 0.3, MaxDistance = 1000,
    Fov = 150, MissChance = false, MissChancePercent = 30, UseMouse = false,
    -- Visuals
    ESP = false, EspTracers = false, EspBoxes = false, EspNames = false, TeamColor = false,
    -- Combat
    TriggerBot = false, HitboxExpander = false, HitboxSize = 5,
    -- Weapons
    NoRecoil = false, NoSpread = false, InfiniteAmmo = false, FullAuto = false,
    -- Physics/Player
    WalkSpeedActive = false, WalkSpeedValue = 16, JumpPowerActive = false, JumpPowerValue = 50,
    InfJump = false, Noclip = false, Fly = false, FlySpeed = 50, ClickTP = false, GodMode = false,
    -- Cars
    CarFly = false, CarFlySpeed = 50, CarSpeed = false, CarSpeedValue = 0, CarBrake = false, CarNoclip = false, UnlockCars = false, UnlockAura = false, LockAura = false,
    -- Trolls
    SpinFling = false, FlingSpeed = 100, CarFling = false, ChatSpam = false, SpamMessage = "Lyan Menu owns you!", SpamDelay = 2,
    Twerk = false, TpSpam = false, Annoy = false, Invisible = false, FakeLag = false, FakeLagIntensity = 10,
    Seizure = false, HeadFling = false, CrashServer = false,
    -- Aimbot Extra
    AimPrediction = false, PredictionStrength = 0.165, AimWallCheck = false,
    AutoSwitchTarget = false, DynamicPart = false, SilentAim = false,
    -- Combat Extra
    KillAura = false, KillAuraRadius = 10, AutoParry = false, ParryDistance = 15,
    AntiAim = false, ReachIncrease = false, ReachSize = 20, Backtrack = false,
    -- Visuals Extra
    EspHealthBar = false, EspDistance = false, EspSkeleton = false,
    Crosshair = false, HitMarker = false, LowPerformance = false,
    -- Player/Exploits Extra
    AntiAfk = false, AntiVoid = false, SpiderWalk = false, AutoBhop = false,
    Dash = false, DashKey = "Q", DashForce = 120,
    StaminaBypass = false, MagNet = false, MagNetRadius = 20,
    WalkOnWater = false, GravityMod = false, GravityValue = 196.2,
    AutoClicker = false,
    -- Cars Extra
    CarTpToPlayer = false, AntiFlip = false, CarStrong = false, CarSuspension = false, AntiFall = false, BringCars = false,
    -- Trolls Extra
    EmoteSpam = false, BringPlayer = false, FreezePlayer = false,
    RainbowChar = false, SizeChar = false, CharSize = 1.0,
    FakeKick = false,
    -- Utility/Server
    Watermark = false, PanicButton = "End", GameDetector = false,
    LogKills = false, AutoFarm = false, FarmKeyword = "Coin",
    StreamMode = false, StreamModeKey = "F4", AntiScreenshot = false,
    -- Guns Extra
    SilentAim = false, Wallbang = false,
    AutoReEquip = false, AutoEquip = true, LogWeaponRemotes = false,
    -- Menu Settings
    MenuKeybind = "Zero", ThemeColor = "Vermelho",
}

-- [Persist]
local function saveConfig()
    if writefile then pcall(function() writefile("LyanMenu_Config.json", HttpService:JSONEncode(Configs)) end) end
end
local function loadConfig()
    if readfile and isfile and isfile("LyanMenu_Config.json") then
        pcall(function()
            local dec = HttpService:JSONDecode(readfile("LyanMenu_Config.json"))
            for k, v in pairs(dec) do Configs[k] = v end
        end)
    end
end
local DefaultConfigs = {}
for k, v in pairs(Configs) do DefaultConfigs[k] = v end

-- [Forward Declarations]
local SelectedTrollTarget = nil
local function resetConfig()
    for k, v in pairs(DefaultConfigs) do Configs[k] = v end
    saveConfig()
end

-- [Theme Colors] Liquid Glass Dark Edition
local Colors = {
    Background = Color3.fromRGB(0, 0, 0), Sidebar = Color3.fromRGB(0, 0, 0), Panel = Color3.fromRGB(5, 5, 5),
    Border = Color3.fromRGB(40, 40, 40), Accent = Color3.fromRGB(239, 68, 68), -- Red
    TextMain = Color3.fromRGB(230, 230, 240), TextDim = Color3.fromRGB(120, 120, 140),
    SwitchBgOff = Color3.fromRGB(20, 20, 20), SwitchKnobOff = Color3.fromRGB(120, 120, 120)
}

local TweenPresets = {
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slide = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Pop = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
}

-- ================================================================
-- [GUI] Window Setup & Hide Toggle
-- ================================================================
local targetGuiParent = (gethui and gethui()) or game:GetService("CoreGui")
if not pcall(function() local x = targetGuiParent.Name end) then
    targetGuiParent = Player:WaitForChild("PlayerGui")
end

local oldGui = targetGuiParent:FindFirstChild("LyanMenuSystem")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LyanMenuSystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function()
    ScreenGui.Parent = targetGuiParent
end)
if ScreenGui.Parent == nil then
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")
end

-- ================================================================



local isMenuOpen = true

-- [Solara Fallback] FOV Circle without Drawing API
local NativeFOVRing = Instance.new("Frame")
NativeFOVRing.BackgroundTransparency = 1
NativeFOVRing.BorderSizePixel = 0
NativeFOVRing.AnchorPoint = Vector2.new(0.5, 0.5)
NativeFOVRing.Visible = false
NativeFOVRing.ZIndex = 0
NativeFOVRing.Parent = ScreenGui

local NativeFOVStroke = Instance.new("UIStroke", NativeFOVRing)
NativeFOVStroke.Color = Colors.Accent
NativeFOVStroke.Thickness = 1.5
NativeFOVStroke.Transparency = 0.5
Instance.new("UICorner", NativeFOVRing).CornerRadius = UDim.new(1, 0)

-- ================================================================
-- [Toast] Slide-in notification system
-- ================================================================
local toastQueue = {}
local toastBusy = false
local ToastHolder = Instance.new("Frame")
ToastHolder.Size = UDim2.new(0, 260, 0, 50)
ToastHolder.Position = UDim2.new(1, -270, 1, -70)
ToastHolder.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
ToastHolder.BorderSizePixel = 0
ToastHolder.AnchorPoint = Vector2.new(0, 0)
ToastHolder.BackgroundTransparency = 1
ToastHolder.ZIndex = 20
ToastHolder.Parent = ScreenGui
local ToastBar = Instance.new("Frame")
ToastBar.Size = UDim2.new(0, 4, 1, 0)
ToastBar.BackgroundColor3 = Colors.Accent
ToastBar.BorderSizePixel = 0
ToastBar.ZIndex = 21
ToastBar.Parent = ToastHolder
local ToastIcon = Instance.new("TextLabel")
ToastIcon.Size = UDim2.new(0, 34, 1, 0)
ToastIcon.Position = UDim2.new(0, 10, 0, 0)
ToastIcon.BackgroundTransparency = 1
ToastIcon.Text = "⚡"
ToastIcon.TextColor3 = Colors.Accent
ToastIcon.Font = Enum.Font.GothamBold
ToastIcon.TextSize = 18
ToastIcon.ZIndex = 21
ToastIcon.Parent = ToastHolder
local ToastLabel = Instance.new("TextLabel")
ToastLabel.Size = UDim2.new(1, -52, 0, 18)
ToastLabel.Position = UDim2.new(0, 46, 0, 8)
ToastLabel.BackgroundTransparency = 1
ToastLabel.Text = ""
ToastLabel.TextColor3 = Colors.TextMain
ToastLabel.Font = Enum.Font.GothamSemibold
ToastLabel.TextSize = 13
ToastLabel.TextStrokeTransparency = 0.75
ToastLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
ToastLabel.TextXAlignment = Enum.TextXAlignment.Left
ToastLabel.ZIndex = 21
ToastLabel.Parent = ToastHolder
local ToastSub = Instance.new("TextLabel")
ToastSub.Size = UDim2.new(1, -52, 0, 14)
ToastSub.Position = UDim2.new(0, 46, 0, 28)
ToastSub.BackgroundTransparency = 1
ToastSub.Text = ""
ToastSub.TextColor3 = Colors.TextDim
ToastSub.Font = Enum.Font.Gotham
ToastSub.TextSize = 11
ToastSub.TextStrokeTransparency = 0.8
ToastSub.TextStrokeColor3 = Color3.new(0, 0, 0)
ToastSub.TextXAlignment = Enum.TextXAlignment.Left
ToastSub.ZIndex = 21
ToastSub.Parent = ToastHolder
Instance.new("UICorner", ToastHolder).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", ToastHolder).Color = Colors.Border

local function showToast(title, sub, isOn)
    ToastLabel.Text = title
    ToastSub.Text = sub or ""
    ToastBar.BackgroundColor3 = isOn and Color3.fromRGB(34, 197, 94) or Colors.Accent
    ToastIcon.TextColor3 = isOn and Color3.fromRGB(34, 197, 94) or Colors.Accent
    ToastIcon.Text = isOn and "✔" or "✖"
    ToastHolder.BackgroundTransparency = 0
    ToastHolder.Position = UDim2.new(1, 10, 1, -70)
    TweenService:Create(ToastHolder, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -270, 1, -70)}):Play()
    task.delay(2.2, function()
        TweenService:Create(ToastHolder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -70), BackgroundTransparency = 1}):Play()
    end)
end

local MainFrame = Instance.new("Frame")


UserInputService.InputBegan:Connect(function(input, gP)
    local bindName = Configs.MenuKeybind
    if not Configs.StreamMode and typeof(bindName) == "string" and bindName ~= "" then
        local success, keyEnum = pcall(function() return Enum.KeyCode[bindName] end)
        if success and input.KeyCode == keyEnum and not gP then
            isMenuOpen = not isMenuOpen
            if isMenuOpen then
                MainFrame.Visible = true
                MainFrame.Position = UDim2.new(0.5, -MenuWidth/2, 0.5, -MenuHeight/2)
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -MenuWidth/2, 0.5, -MenuHeight/2)}):Play()
            else
                TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -MenuWidth/2, 0.5, -MenuHeight/2 + 20)}):Play()
                task.delay(0.2, function() if not isMenuOpen then MainFrame.Visible = false end end)
            end
        end
    end
    if not gP and input.UserInputType == Enum.UserInputType.MouseButton1 and Configs.ClickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local mouse = Player:GetMouse()
        if mouse.Target and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)
MainFrame.Size = UDim2.new(0, MenuWidth, 0, MenuHeight)
MainFrame.Position = UDim2.new(0.5, -MenuWidth/2, 0.5, -MenuHeight/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

-- ================================================================
-- [Mobile Support] Floating Buttons
-- ================================================================
local mobileAimHeld = false

if isMobile then
    -- Floating toggle button (draggable circle)
    local MobileToggleBtn = Instance.new("TextButton")
    MobileToggleBtn.Size = UDim2.new(0, 48, 0, 48)
    MobileToggleBtn.Position = UDim2.new(0, 8, 0.4, 0)
    MobileToggleBtn.BackgroundColor3 = Colors.Accent
    MobileToggleBtn.BackgroundTransparency = 0.25
    MobileToggleBtn.Text = "L"
    MobileToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    MobileToggleBtn.Font = Enum.Font.GothamBlack
    MobileToggleBtn.TextSize = 20
    MobileToggleBtn.BorderSizePixel = 0
    MobileToggleBtn.ZIndex = 50
    MobileToggleBtn.Active = true
    MobileToggleBtn.Draggable = true
    MobileToggleBtn.Parent = ScreenGui
    Instance.new("UICorner", MobileToggleBtn).CornerRadius = UDim.new(1, 0)
    local toggleStroke = Instance.new("UIStroke", MobileToggleBtn)
    toggleStroke.Color = Color3.fromRGB(255, 255, 255)
    toggleStroke.Thickness = 1.5
    toggleStroke.Transparency = 0.5

    MobileToggleBtn.MouseButton1Click:Connect(function()
        isMenuOpen = not isMenuOpen
        if isMenuOpen then
            MainFrame.Visible = true
            TweenService:Create(MobileToggleBtn, TweenPresets.Fast, {BackgroundTransparency = 0.25}):Play()
            MobileToggleBtn.Text = "X"
        else
            MainFrame.Visible = false
            TweenService:Create(MobileToggleBtn, TweenPresets.Fast, {BackgroundTransparency = 0.5}):Play()
            MobileToggleBtn.Text = "L"
        end
    end)

    -- Floating Aimbot activation button (hold to aim)
    local MobileAimBtn = Instance.new("TextButton")
    MobileAimBtn.Size = UDim2.new(0, 64, 0, 64)
    MobileAimBtn.Position = UDim2.new(1, -74, 0.55, 0)
    MobileAimBtn.BackgroundColor3 = Colors.Accent
    MobileAimBtn.BackgroundTransparency = 0.5
    MobileAimBtn.Text = "AIM"
    MobileAimBtn.TextColor3 = Color3.new(1, 1, 1)
    MobileAimBtn.Font = Enum.Font.GothamBlack
    MobileAimBtn.TextSize = 14
    MobileAimBtn.BorderSizePixel = 0
    MobileAimBtn.ZIndex = 50
    MobileAimBtn.Active = true
    MobileAimBtn.Draggable = true
    MobileAimBtn.Parent = ScreenGui
    Instance.new("UICorner", MobileAimBtn).CornerRadius = UDim.new(1, 0)
    local aimStroke = Instance.new("UIStroke", MobileAimBtn)
    aimStroke.Color = Color3.fromRGB(255, 255, 255)
    aimStroke.Thickness = 2
    aimStroke.Transparency = 0.4

    MobileAimBtn.MouseButton1Down:Connect(function()
        mobileAimHeld = true
        TweenService:Create(MobileAimBtn, TweenPresets.Fast, {BackgroundTransparency = 0.1, Size = UDim2.new(0, 70, 0, 70)}):Play()
        TweenService:Create(aimStroke, TweenPresets.Fast, {Color = Color3.fromRGB(255, 100, 100)}):Play()
    end)
    MobileAimBtn.MouseButton1Up:Connect(function()
        mobileAimHeld = false
        TweenService:Create(MobileAimBtn, TweenPresets.Fast, {BackgroundTransparency = 0.5, Size = UDim2.new(0, 64, 0, 64)}):Play()
        TweenService:Create(aimStroke, TweenPresets.Fast, {Color = Color3.fromRGB(255, 255, 255)}):Play()
    end)
    -- Also release when touch ends anywhere (safety)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if mobileAimHeld then
                mobileAimHeld = false
                TweenService:Create(MobileAimBtn, TweenPresets.Fast, {BackgroundTransparency = 0.5, Size = UDim2.new(0, 64, 0, 64)}):Play()
                TweenService:Create(aimStroke, TweenPresets.Fast, {Color = Color3.fromRGB(255, 255, 255)}):Play()
            end
        end
    end)

    -- Floating Fly button (quick toggle)
    local MobileFlyBtn = Instance.new("TextButton")
    MobileFlyBtn.Size = UDim2.new(0, 48, 0, 48)
    MobileFlyBtn.Position = UDim2.new(1, -58, 0.55, 80)
    MobileFlyBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    MobileFlyBtn.BackgroundTransparency = 0.5
    MobileFlyBtn.Text = "FLY"
    MobileFlyBtn.TextColor3 = Color3.new(1, 1, 1)
    MobileFlyBtn.Font = Enum.Font.GothamBlack
    MobileFlyBtn.TextSize = 11
    MobileFlyBtn.BorderSizePixel = 0
    MobileFlyBtn.ZIndex = 50
    MobileFlyBtn.Active = true
    MobileFlyBtn.Draggable = true
    MobileFlyBtn.Parent = ScreenGui
    Instance.new("UICorner", MobileFlyBtn).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", MobileFlyBtn).Color = Color3.fromRGB(255, 255, 255)

    MobileFlyBtn.MouseButton1Click:Connect(function()
        Configs.Fly = not Configs.Fly
        if Configs.Fly then
            MobileFlyBtn.BackgroundTransparency = 0.1
            showToast("FLY", "ENABLED", true)
        else
            MobileFlyBtn.BackgroundTransparency = 0.5
            showToast("FLY", "DISABLED", false)
        end
        saveConfig()
    end)

    -- Floating ESP toggle button
    local MobileEspBtn = Instance.new("TextButton")
    MobileEspBtn.Size = UDim2.new(0, 48, 0, 48)
    MobileEspBtn.Position = UDim2.new(1, -58, 0.55, 140)
    MobileEspBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    MobileEspBtn.BackgroundTransparency = 0.5
    MobileEspBtn.Text = "ESP"
    MobileEspBtn.TextColor3 = Color3.new(1, 1, 1)
    MobileEspBtn.Font = Enum.Font.GothamBlack
    MobileEspBtn.TextSize = 11
    MobileEspBtn.BorderSizePixel = 0
    MobileEspBtn.ZIndex = 50
    MobileEspBtn.Active = true
    MobileEspBtn.Draggable = true
    MobileEspBtn.Parent = ScreenGui
    Instance.new("UICorner", MobileEspBtn).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", MobileEspBtn).Color = Color3.fromRGB(255, 255, 255)

    MobileEspBtn.MouseButton1Click:Connect(function()
        Configs.ESP = not Configs.ESP
        if Configs.ESP then
            MobileEspBtn.BackgroundTransparency = 0.1
            showToast("ESP", "ENABLED", true)
        else
            MobileEspBtn.BackgroundTransparency = 0.5
            showToast("ESP", "DISABLED", false)
        end
        saveConfig()
    end)

    -- Floating Speed toggle button
    local MobileSpeedBtn = Instance.new("TextButton")
    MobileSpeedBtn.Size = UDim2.new(0, 48, 0, 48)
    MobileSpeedBtn.Position = UDim2.new(1, -58, 0.55, 200)
    MobileSpeedBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    MobileSpeedBtn.BackgroundTransparency = 0.5
    MobileSpeedBtn.Text = "SPD"
    MobileSpeedBtn.TextColor3 = Color3.new(1, 1, 1)
    MobileSpeedBtn.Font = Enum.Font.GothamBlack
    MobileSpeedBtn.TextSize = 11
    MobileSpeedBtn.BorderSizePixel = 0
    MobileSpeedBtn.ZIndex = 50
    MobileSpeedBtn.Active = true
    MobileSpeedBtn.Draggable = true
    MobileSpeedBtn.Parent = ScreenGui
    Instance.new("UICorner", MobileSpeedBtn).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", MobileSpeedBtn).Color = Color3.fromRGB(255, 255, 255)

    MobileSpeedBtn.MouseButton1Click:Connect(function()
        Configs.WalkSpeedActive = not Configs.WalkSpeedActive
        if Configs.WalkSpeedActive then
            MobileSpeedBtn.BackgroundTransparency = 0.1
            showToast("SPEED", "ENABLED (" .. Configs.WalkSpeedValue .. ")", true)
        else
            MobileSpeedBtn.BackgroundTransparency = 0.5
            showToast("SPEED", "DISABLED", false)
        end
        saveConfig()
    end)
end

-- Removed liquid glass

local outline = Instance.new("UIStroke", MainFrame)
outline.Color = Color3.fromRGB(50, 50, 50)
outline.Thickness = 1.5
-- Removed UICorner from MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, SidebarWidth, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Sidebar.BackgroundTransparency = 0
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
-- Removed UICorner from Sidebar
-- Sidebar right border line
local sidebarLine = Instance.new("Frame")
sidebarLine.Size = UDim2.new(0, 1, 1, 0)
sidebarLine.Position = UDim2.new(1, -1, 0, 0)
sidebarLine.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sidebarLine.BackgroundTransparency = 0.5
sidebarLine.BorderSizePixel = 0
sidebarLine.Parent = Sidebar

local LogoImg = Instance.new("ImageLabel")
LogoImg.Size = UDim2.new(1, -40, 0, 45)
LogoImg.Position = UDim2.new(0, 20, 0, 20)
LogoImg.BackgroundTransparency = 1
LogoImg.Image = ""
LogoImg.ScaleType = Enum.ScaleType.Fit
LogoImg.Parent = Sidebar

task.spawn(function()
    local success, customAsset = pcall(function()
        local imgData = game:HttpGet("https://blob.stormapplications.com/blobs/1424256771610116136/6a1f9d6a403c5983a2b56ea5.png")
        if writefile then
            writefile("LyanMenu_Logo.png", imgData)
            return (getcustomasset or getsynasset)("LyanMenu_Logo.png")
        end
        return nil
    end)
    if success and customAsset then
        LogoImg.Image = customAsset
    else
        -- Fallback
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.Text = "SACRACIA"
        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        txt.Font = Enum.Font.GothamBlack
        txt.TextSize = isMobile and 18 or 24
        txt.Parent = LogoImg
    end
end)

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 1, -90)
TabContainer.Position = UDim2.new(0, 0, 0, 90)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar
local TabLayout = Instance.new("UIListLayout")
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 8)
TabLayout.Parent = TabContainer

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -(SidebarWidth + 10), 1, 0)
ContentArea.Position = UDim2.new(0, SidebarWidth + 10, 0, 0)
ContentArea.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ContentArea.BackgroundTransparency = 0.4
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainFrame

local Breadcrumb = Instance.new("TextLabel")
Breadcrumb.Size = UDim2.new(1, -40, 0, 35)
Breadcrumb.Position = UDim2.new(0, 30, 0, 18)
Breadcrumb.BackgroundTransparency = 1
Breadcrumb.Text = "LYAN > AIMBOT"
Breadcrumb.TextColor3 = Colors.TextDim
Breadcrumb.Font = Enum.Font.GothamSemibold
Breadcrumb.TextSize = isMobile and 11 or 14
Breadcrumb.TextStrokeTransparency = 0.75
Breadcrumb.TextStrokeColor3 = Color3.new(0, 0, 0)
Breadcrumb.TextXAlignment = Enum.TextXAlignment.Left
Breadcrumb.Parent = ContentArea

local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, 0, 1, -60)
PageContainer.Position = UDim2.new(0, 0, 0, 60)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = ContentArea

-- ================================================================
-- [Components] Micro-animated Controls
-- ================================================================
local function createPanel(parent, title, size, pos)
    local panel = Instance.new("Frame")
    panel.Size = size
    panel.Position = pos
    panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    panel.BackgroundTransparency = 0.6
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = parent
    -- Auto expand canvas if parent is ScrollingFrame
    if parent:IsA("ScrollingFrame") then
        local yEnd = (pos.Y.Offset or 0) + (size.Y.Offset or 0) + (pos.Y.Scale or 0) * 520 + (size.Y.Scale or 0) * 520
        local needed = yEnd + 30
        if parent.CanvasSize.Y.Offset < needed then
            parent.CanvasSize = UDim2.new(0, 0, 0, needed)
        end
    end
    -- Removed UICorner from panel
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = Color3.fromRGB(50, 50, 50)
    stroke.Thickness = 1
    -- glass shimmer top line
    local shimmer = Instance.new("Frame")
    shimmer.Size = UDim2.new(1, 0, 0, 1)
    shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shimmer.BackgroundTransparency = 0.7
    shimmer.BorderSizePixel = 0
    shimmer.Parent = panel

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -30, 0, 30)
    lbl.Position = UDim2.new(0, 15, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Colors.TextDim
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextStrokeTransparency = 0.75
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = panel

    local layContainer = Instance.new("Frame")
    layContainer.Size = UDim2.new(1, -30, 1, -35)
    layContainer.Position = UDim2.new(0, 15, 0, 35)
    layContainer.BackgroundTransparency = 1
    layContainer.Parent = panel

    panel.MouseEnter:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Accent}):Play() TweenService:Create(lbl, TweenPresets.Fast, {TextColor3 = Colors.TextMain}):Play() end)
    panel.MouseLeave:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Border}):Play() TweenService:Create(lbl, TweenPresets.Fast, {TextColor3 = Colors.TextDim}):Play() end)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 12)
    layout.Parent = layContainer

    panel.MouseEnter:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Color3.fromRGB(50, 40, 40)}):Play() end)
    panel.MouseLeave:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Border}):Play() end)

    -- Auto-resize panel based on its UIListLayout content + update parent canvas
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local needed = layout.AbsoluteContentSize.Y + 50  -- 35 título + 15 folga
        panel.Size = UDim2.new(size.X.Scale, size.X.Offset, 0, needed)
        if parent:IsA("ScrollingFrame") then
            local yEnd = (pos.Y.Offset or 0) + needed + (pos.Y.Scale or 0) * 520
            local total = yEnd + 30
            if parent.CanvasSize.Y.Offset < total then
                parent.CanvasSize = UDim2.new(0, 0, 0, total)
            end
        end
    end)

    return layContainer
end

local function createSwitch(parent, text, subtext, configKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0, 17)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.TextMain
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextStrokeTransparency = 0.75
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    if subtext then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(0.7, 0, 0, 14)
        sub.Position = UDim2.new(0, 0, 0, 17)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextColor3 = Colors.TextDim
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 11
        sub.TextStrokeTransparency = 0.8
        sub.TextStrokeColor3 = Color3.new(0, 0, 0)
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = frame
    end
    local switchBg = Instance.new("TextButton")
    switchBg.Size = UDim2.new(0, 36, 0, 18)
    switchBg.Position = UDim2.new(1, -36, 0.5, -9)
    switchBg.BackgroundColor3 = Configs[configKey] and Colors.Accent or Colors.SwitchBgOff
    switchBg.BorderSizePixel = 0
    switchBg.Text = ""
    switchBg.Parent = frame
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = Configs[configKey] and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    knob.BackgroundColor3 = Configs[configKey] and Color3.fromRGB(255, 255, 255) or Colors.SwitchKnobOff
    knob.BorderSizePixel = 0
    knob.Parent = switchBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function updateVisuals()
        local tInfo = TweenPresets.Fast
        if Configs[configKey] then
            TweenService:Create(switchBg, tInfo, {BackgroundColor3 = Colors.Accent}):Play()
            TweenService:Create(knob, tInfo, {Position = UDim2.new(1, -15, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            TweenService:Create(label, tInfo, {TextColor3 = Colors.TextMain}):Play()
        else
            TweenService:Create(switchBg, tInfo, {BackgroundColor3 = Colors.SwitchBgOff}):Play()
            TweenService:Create(knob, tInfo, {Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = Colors.SwitchKnobOff}):Play()
            TweenService:Create(label, tInfo, {TextColor3 = Colors.TextDim}):Play()
        end
    end
    switchBg.MouseEnter:Connect(function() if not Configs[configKey] then TweenService:Create(switchBg, TweenPresets.Fast, {BackgroundColor3 = Color3.fromRGB(40, 35, 45)}):Play() end end)
    switchBg.MouseLeave:Connect(function() if not Configs[configKey] then TweenService:Create(switchBg, TweenPresets.Fast, {BackgroundColor3 = Colors.SwitchBgOff}):Play() end end)
    switchBg.MouseButton1Click:Connect(function()
        Configs[configKey] = not Configs[configKey]
        updateVisuals()
        showToast(text, Configs[configKey] and "ENABLED" or "DISABLED", Configs[configKey])
        saveConfig()
        if callback then callback(Configs[configKey]) end
    end)
end

local function createButton(parent, text, subtext, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 17)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.TextMain
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextStrokeTransparency = 0.75
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    if subtext then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(0.6, 0, 0, 14)
        sub.Position = UDim2.new(0, 0, 0, 17)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextColor3 = Colors.TextDim
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 11
        sub.TextStrokeTransparency = 0.8
        sub.TextStrokeColor3 = Color3.new(0, 0, 0)
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = frame
    end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 24)
    btn.Position = UDim2.new(1, -80, 0.5, -12)
    btn.BackgroundColor3 = Colors.SwitchBgOff
    btn.BorderSizePixel = 0
    btn.Text = "EXECUTAR"
    btn.TextColor3 = Colors.TextDim
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.Parent = frame
    -- Removed UICorner from btn
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Colors.Border
    stroke.Thickness = 1
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenPresets.Fast, {BackgroundColor3 = Color3.fromRGB(40, 35, 45)}):Play() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Accent}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenPresets.Fast, {BackgroundColor3 = Colors.SwitchBgOff, Size = UDim2.new(0, 80, 0, 24)}):Play() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Border}):Play() end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenPresets.Fast, {Size = UDim2.new(0, 76, 0, 22), BackgroundColor3 = Colors.Accent, TextColor3 = Color3.new(0,0,0)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenPresets.Fast, {Size = UDim2.new(0, 80, 0, 24), BackgroundColor3 = Color3.fromRGB(40, 35, 45), TextColor3 = Colors.TextDim}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
end

local function createSlider(parent, text, min, max, configKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 17)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.TextDim
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextStrokeTransparency = 0.75
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.5, 0, 0, 17)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(Configs[configKey])
    valueLabel.TextColor3 = Colors.TextMain
    valueLabel.Font = Enum.Font.GothamSemibold
    valueLabel.TextSize = 12
    valueLabel.TextStrokeTransparency = 0.75
    valueLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    local trackBg = Instance.new("TextButton")
    trackBg.Size = UDim2.new(1, 0, 0, 14)
    trackBg.Position = UDim2.new(0, 0, 0, 18)
    trackBg.BackgroundColor3 = Colors.SwitchBgOff
    trackBg.BackgroundTransparency = 0
    trackBg.BorderSizePixel = 0
    trackBg.Text = ""
    trackBg.AutoButtonColor = false
    trackBg.Active = true
    trackBg.Parent = frame
    local trackInner = Instance.new("Frame")
    trackInner.Size = UDim2.new(1, 0, 0, 4)
    trackInner.Position = UDim2.new(0, 0, 0.5, -2)
    trackInner.BackgroundColor3 = Colors.SwitchBgOff
    trackInner.BorderSizePixel = 0
    trackInner.Parent = trackBg
    trackBg.BackgroundTransparency = 1
    local fill = Instance.new("Frame")
    local pct = (Configs[configKey] - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel = 0
    fill.Parent = trackInner
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = Colors.Background
    knob.BorderSizePixel = 0
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.Active = true
    knob.Parent = trackBg
    local kStroke = Instance.new("UIStroke", knob)
    kStroke.Color = Colors.Accent
    kStroke.Thickness = 3

    local dragging = false
    local function updateVal(inputX)
        local absPos = trackBg.AbsolutePosition.X
        local absSize = trackBg.AbsoluteSize.X
        if absSize == 0 then return end
        local p = math.clamp((inputX - absPos) / absSize, 0, 1)
        local raw = min + p * (max - min)
        local fin = (max - min > 10) and math.round(raw) or (math.round(raw * 10) / 10)
        Configs[configKey] = fin
        valueLabel.Text = tostring(fin)
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, -7, 0.5, -7)
        saveConfig()
        if callback then callback(fin) end
    end
    trackBg.MouseButton1Down:Connect(function(x)
        dragging = true
        updateVal(x)
    end)
    knob.MouseEnter:Connect(function() TweenService:Create(kStroke, TweenPresets.Fast, {Color = Color3.fromRGB(255, 100, 100)}):Play() end)
    knob.MouseLeave:Connect(function() TweenService:Create(kStroke, TweenPresets.Fast, {Color = Colors.Accent}):Play() end)
    knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateVal(input.Position.X) end end)
end

local function createHotkey(parent, text, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Colors.Border
    stroke.Thickness = 1
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.TextDim
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextStrokeTransparency = 0.75
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, 0, 1, 0)
    btn.Position = UDim2.new(0.5, 0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = Configs[configKey] == "MouseButton2" and "RMB" or (Configs[configKey] == "MouseButton1" and "LMB" or tostring(Configs[configKey]))
    btn.TextColor3 = Colors.Accent
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextStrokeTransparency = 0.75
    btn.TextStrokeColor3 = Color3.new(0, 0, 0)
    btn.TextXAlignment = Enum.TextXAlignment.Right
    btn.Parent = frame
    Instance.new("UIPadding", btn).PaddingRight = UDim.new(0, 10)

    btn.MouseEnter:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Accent}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Border}):Play() end)

    local listening = false
    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            local key = nil
            if input.UserInputType == Enum.UserInputType.Keyboard then key = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then key = "MouseButton1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then key = "MouseButton2" end
            if key then
                Configs[configKey] = key
                btn.Text = key == "MouseButton2" and "RMB" or (key == "MouseButton1" and "LMB" or key)
                listening = false
                conn:Disconnect()
                saveConfig()
            end
        end)
    end)
end

local function createDropdown(parent, text, options, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Colors.Border
    stroke.Thickness = 1
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text .. " : " .. tostring(Configs[configKey])
    btn.TextColor3 = Colors.TextMain
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextStrokeTransparency = 0.75
    btn.TextStrokeColor3 = Color3.new(0, 0, 0)
    btn.Parent = frame
    
    btn.MouseEnter:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Accent}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Border}):Play() end)

    local index = 1
    for i, v in ipairs(options) do if v == Configs[configKey] then index = i break end end
    btn.MouseButton1Click:Connect(function()
        index = index + 1
        if index > #options then index = 1 end
        Configs[configKey] = options[index]
        btn.Text = text .. " : " .. tostring(Configs[configKey])
        saveConfig()
    end)
end

local function createInputBlock(parent, text, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Colors.Border
    stroke.Thickness = 1
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.TextDim
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextStrokeTransparency = 0.75
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.6, -10, 1, 0)
    box.Position = UDim2.new(0.4, 0, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = tostring(Configs[configKey])
    box.TextColor3 = Colors.Accent
    box.Font = Enum.Font.GothamSemibold
    box.TextSize = 12
    box.TextStrokeTransparency = 0.75
    box.TextStrokeColor3 = Color3.new(0, 0, 0)
    box.TextXAlignment = Enum.TextXAlignment.Right
    box.ClearTextOnFocus = false
    box.Parent = frame
    box.FocusLost:Connect(function()
        Configs[configKey] = box.Text
        saveConfig()
    end)
    box.MouseEnter:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Accent}):Play() end)
    box.MouseLeave:Connect(function() if not box:IsFocused() then TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Border}):Play() end end)
    box.Focused:Connect(function() TweenService:Create(stroke, TweenPresets.Fast, {Color = Colors.Accent}):Play() end)
end

-- ================================================================
-- [Page Router]
-- ================================================================
local Pages = {}
local TabButtons = {}
local ActiveLine = Instance.new("Frame")
ActiveLine.Size = UDim2.new(0, 3, 0, 25)
ActiveLine.Position = UDim2.new(1, -3, 0, 0)
ActiveLine.BackgroundColor3 = Colors.Accent
ActiveLine.BorderSizePixel = 0
ActiveLine.ZIndex = 5
ActiveLine.Parent = TabContainer

local AllPages = {}
local function createPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 6
    p.ScrollBarImageColor3 = Colors.Accent
    p.ScrollBarImageTransparency = 0
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.ScrollingDirection = Enum.ScrollingDirection.Y
    p.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    p.Active = true
    p.Visible = false
    p.ClipsDescendants = true
    p.Parent = PageContainer
    table.insert(AllPages, p)
    return p
end

-- Auto-resize canvas based on actual child panel positions/sizes (uses offsets)
local function refreshPageCanvas(p)
    local maxY = 0
    local viewH = p.AbsoluteSize.Y > 0 and p.AbsoluteSize.Y or 520
    for _, child in pairs(p:GetChildren()) do
        if child:IsA("GuiObject") then
            local yOff = child.Position.Y.Offset + child.Position.Y.Scale * viewH
            local hOff = child.Size.Y.Offset + child.Size.Y.Scale * viewH
            local bottom = yOff + hOff
            if bottom > maxY then maxY = bottom end
        end
    end
    p.CanvasSize = UDim2.new(0, 0, 0, math.max(maxY + 30, viewH))
end

local PgAimbot = createPage()
local PgCombat = createPage()
local PgVisuals = createPage()
local PgExploits = createPage()
local PgTroll = createPage()
local PgPlayersList = createPage()
local PgCars = createPage()
local PgGuns = createPage()
local PgConfig = createPage()
local PgServer = createPage()

local tabIndex = 1
local function createTab(pageName, targetPage)
    local btnWrapper = Instance.new("TextButton")
    btnWrapper.Name = string.format("%02d_%s", tabIndex, pageName)
    btnWrapper.LayoutOrder = tabIndex
    tabIndex = tabIndex + 1
    btnWrapper.Size = UDim2.new(1, 0, 0, isMobile and 30 or 38)
    btnWrapper.BackgroundTransparency = 1
    btnWrapper.Text = ""
    btnWrapper.Parent = TabContainer
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 1, 0)
    titleLbl.Position = UDim2.new(0, 20, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = string.upper(pageName)
    titleLbl.TextColor3 = Colors.TextDim
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = isMobile and 11 or 14
    titleLbl.TextStrokeTransparency = 0.7
    titleLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = btnWrapper
    
    Pages[pageName] = targetPage
    TabButtons[pageName] = {Title = titleLbl}

    btnWrapper.MouseEnter:Connect(function() 
        TweenService:Create(btnWrapper, TweenPresets.Fast, {BackgroundColor3 = Color3.fromRGB(12, 12, 12)}):Play()
        TweenService:Create(titleLbl, TweenPresets.Pop, {Position = UDim2.new(0, 28, 0, 0)}):Play()
        if not Pages[pageName].Visible then TweenService:Create(titleLbl, TweenPresets.Fast, {TextColor3 = Colors.TextMain}):Play() end 
    end)
    btnWrapper.MouseLeave:Connect(function() 
        TweenService:Create(btnWrapper, TweenPresets.Fast, {BackgroundColor3 = Color3.fromRGB(5, 5, 5)}):Play()
        TweenService:Create(titleLbl, TweenPresets.Pop, {Position = UDim2.new(0, 20, 0, 0)}):Play()
        if not Pages[pageName].Visible then TweenService:Create(titleLbl, TweenPresets.Fast, {TextColor3 = Colors.TextDim}):Play() end 
    end)
    btnWrapper.MouseButton1Click:Connect(function()
        for nm, pg in pairs(Pages) do
            if nm == pageName then
                pg.Visible = true
                pg.Position = UDim2.new(0, 15, 0, 0)
                TweenService:Create(pg, TweenPresets.Slide, {Position = UDim2.new(0, 0, 0, 0)}):Play()
                task.defer(function() refreshPageCanvas(pg) end)
            else
                pg.Visible = false
            end
        end
        Breadcrumb.Text = "LYAN > " .. string.upper(pageName)
        for nm, tbl in pairs(TabButtons) do 
            local clr = (nm == pageName) and Colors.Accent or Colors.TextDim
            TweenService:Create(tbl.Title, TweenPresets.Fast, {TextColor3 = clr}):Play() 
        end
        local targetY = btnWrapper.AbsolutePosition.Y - TabContainer.AbsolutePosition.Y + (btnWrapper.AbsoluteSize.Y/2) - (25/2)
        TweenService:Create(ActiveLine, TweenPresets.Pop, {Position = UDim2.new(1, -3, 0, targetY)}):Play()
    end)
    btnWrapper.MouseButton1Down:Connect(function() TweenService:Create(titleLbl, TweenPresets.Fast, {TextSize = isMobile and 10 or 12}):Play() end)
    btnWrapper.MouseButton1Up:Connect(function() TweenService:Create(titleLbl, TweenPresets.Pop, {TextSize = isMobile and 11 or 14}):Play() end)
    return btnWrapper
end

local tAimbot = createTab("Aimbot", PgAimbot)
createTab("Combat", PgCombat)
createTab("Visuals", PgVisuals)
createTab("Exploits", PgExploits)
createTab("Troll", PgTroll)
createTab("Players", PgPlayersList)
createTab("Cars", PgCars)
createTab("Guns", PgGuns)
createTab("Server", PgServer)
createTab("Config", PgConfig)

TabButtons["Aimbot"].Title.TextColor3 = Colors.Accent

-- LOADING PAGE
local PgLoading = createPage()
PgLoading.Visible = true
PgAimbot.Visible = false

local loadImg = Instance.new("ImageLabel")
loadImg.Size = UDim2.new(0, 100, 0, 100)
loadImg.Position = UDim2.new(0.5, -50, 0.4, -50)
loadImg.BackgroundTransparency = 1
loadImg.Image = "rbxassetid://1424256771610116136" -- fallback se der
loadImg.Parent = PgLoading

local loadSub = Instance.new("TextLabel")
loadSub.Size = UDim2.new(1, 0, 0, 20)
loadSub.Position = UDim2.new(0, 0, 0.4, 60)
loadSub.BackgroundTransparency = 1
loadSub.Text = "CARREGANDO SISTEMA..."
loadSub.TextColor3 = Colors.Accent
loadSub.Font = Enum.Font.GothamBold
loadSub.TextSize = 14
loadSub.Parent = PgLoading

-- Get logo dynamically
task.spawn(function()
    local success, asset = pcall(function() return (getcustomasset or getsynasset)("LyanMenu_Logo.png") end)
    if success and asset then loadImg.Image = asset else loadImg.Image = "" end
end)

-- Loading Sequence
task.spawn(function()
    task.wait(0.5)
    loadSub.Text = "CARREGANDO MÓDULOS..."
    task.wait(0.6)
    loadSub.Text = "BYPASSANDO..."
    task.wait(0.7)
    loadSub.Text = "PRONTO!"
    loadSub.TextColor3 = Color3.fromRGB(34, 197, 94)
    task.wait(0.4)
    PgLoading.Visible = false
    PgAimbot.Visible = true
    -- Refresh layout just in case
    refreshPageCanvas(PgAimbot)
end)

task.defer(function()
    task.wait(0.1)
    local targetY = tAimbot.AbsolutePosition.Y - TabContainer.AbsolutePosition.Y + (tAimbot.AbsoluteSize.Y/2) - (25/2)
    ActiveLine.Position = UDim2.new(1, -3, 0, targetY)
    -- Refresh canvas size for all pages
    for _, pg in pairs(AllPages) do refreshPageCanvas(pg) end
end)

-- ================================================================
-- [Panels Population]
-- ================================================================

-- Aimbot Tab  (Switch=34, Hotkey=34, Dropdown=34, Slider=40 → total per item ~38-44)
-- A1: title(30) + switch(34) + hotkey(34) + dropdown(34) + slider(40) + slider(40) + padding(12*5=60) + margins = ~310
local A1 = createPanel(PgAimbot, "NÚCLEO AIMBOT", UDim2.new(0.45, 0, 0, 315), UDim2.new(0.02, 0, 0.05, 0))
createSwitch(A1, "ATIVAR AIMBOT", "INTERRUPTOR GERAL", "Aimbot", function(s) NativeFOVRing.Visible = s end)
createHotkey(A1, "TECLA DO AIMBOT", "Hotkey")
createDropdown(A1, "PARTE DO CORPO", {"Head", "HumanoidRootPart", "Torso"}, "LockPart")
createSlider(A1, "RAIO DO FOV", 10, 800, "Fov", function(v)
    NativeFOVRing.Size = UDim2.new(0, v*2, 0, v*2)
end)
createSlider(A1, "SUAVIDADE", 0.01, 1.0, "Smoothness")

-- A2: title(30) + 6 switches(34*6=204) + padding(12*5=60) + margins = ~310
local A2 = createPanel(PgAimbot, "AIMBOT AVANÇADO", UDim2.new(0.45, 0, 0, 310), UDim2.new(0.5, 0, 0.05, 0))
createSwitch(A2, "MOVIMENTO DO MOUSE", "USAR MOUSE RELATIVO", "UseMouse")
createSwitch(A2, "MIRAR EM MORTOS", "ALVEJAR MORTOS", "TargetDead")
createSwitch(A2, "AIMBOT PEGAJOSO", "SEGURAR ALVO ATUAL", "StickyAimbot")
createSwitch(A2, "CHANCE DE ERRO", "ERROS FALSOS", "MissChance")
createSwitch(A2, "SILENT AIM (MAGIA)", "TIRO VAI PRO ALVO SOZINHO", "SilentAim")
createSwitch(A2, "WALLBANG", "VARAR PAREDE COM TIROS", "Wallbang")

-- A3: AIMBOT PRO
local A3 = createPanel(PgAimbot, "AIMBOT PRO", UDim2.new(0.93, 0, 0, 240), UDim2.new(0.02, 0, 0, 380))
createSwitch(A3, "PREDIÇÃO", "COMPENSAR VELOCIDADE DO ALVO", "AimPrediction")
createSlider(A3, "FORÇA DA PREDIÇÃO", 0.05, 0.5, "PredictionStrength")
createSwitch(A3, "WALLCHECK", "SÓ MIRAR EM VISÍVEIS", "AimWallCheck")
createSwitch(A3, "AUTO TROCAR ALVO", "TROCA AO PERDER VISTA/MORTE", "AutoSwitchTarget")
createSwitch(A3, "PARTE DINÂMICA", "HEAD PERTO, TORSO LONGE", "DynamicPart")

-- Combat Tab
-- C1: title(30) + 4 switches(34*4=136) + padding(12*3=36) + margins = ~230
local C1 = createPanel(PgCombat, "MODS DE ARMA (EQUIPE PARA ATIVAR)", UDim2.new(0.45, 0, 0, 235), UDim2.new(0.02, 0, 0.05, 0))
createSwitch(C1, "SEM RECUO", "0 RECUO", "NoRecoil")
createSwitch(C1, "SEM DISPERSÃO", "TIRO RETO", "NoSpread")
createSwitch(C1, "MUNIÇÃO INFINITA", "PENTE INFINITO", "InfiniteAmmo")
createSwitch(C1, "TIRO AUTOMÁTICO", "SEGURAR CLIQUE", "FullAuto")

-- C2: title(30) + 2 switches(34*2=68) + slider(40) + padding(12*2=24) + margins = ~200
local C2 = createPanel(PgCombat, "ASSISTÊNCIA DE COMBATE", UDim2.new(0.45, 0, 0, 200), UDim2.new(0.5, 0, 0.05, 0))
createSwitch(C2, "TRIGGERBOT", "ATIRAR AUTOMÁTICO", "TriggerBot")
createSwitch(C2, "EXPANDIR HITBOX", "AUMENTAR INIMIGOS", "HitboxExpander")
createSlider(C2, "TAMANHO DA HITBOX", 2, 30, "HitboxSize")

-- C3: COMBAT PRO
local C3 = createPanel(PgCombat, "COMBAT PRO", UDim2.new(0.93, 0, 0, 360), UDim2.new(0.02, 0, 0, 280))
createSwitch(C3, "KILL AURA", "ATAQUE AUTOMÁTICO EM RAIO", "KillAura")
createSlider(C3, "RAIO DA AURA", 5, 50, "KillAuraRadius")
createSwitch(C3, "AUTO PARRY", "BLADE BALL / SWORDS", "AutoParry")
createSlider(C3, "DISTÂNCIA DO PARRY", 5, 50, "ParryDistance")
createSwitch(C3, "ANTI AIM", "ROTACIONAR HRP", "AntiAim")
createSwitch(C3, "AUMENTAR REACH", "HITBOX DE ARMA BRANCA", "ReachIncrease")
createSlider(C3, "TAMANHO DO REACH", 5, 50, "ReachSize")
createSwitch(C3, "BACKTRACK", "ATIRAR ONDE INIMIGO ESTAVA", "Backtrack")

-- Visuals Tab
-- V1: title(30) + 5 switches(34*5=170) + padding(12*4=48) + margins = ~285
local V1 = createPanel(PgVisuals, "WALLHACK", UDim2.new(0.45, 0, 0, 285), UDim2.new(0.02, 0, 0.05, 0))
createSwitch(V1, "ATIVAR ESP", "CHAMS DOS JOGADORES", "ESP")
createSwitch(V1, "DESENHAR CAIXAS", "MOSTRAR CAIXAS", "EspBoxes")
createSwitch(V1, "DESENHAR NOMES", "MOSTRAR NOMES", "EspNames")
createSwitch(V1, "DESENHAR LINHAS", "LINHAS PARA INIMIGOS", "EspTracers")
createSwitch(V1, "COR DO TIME", "ALIADO VS INIMIGO", "TeamColor")

-- V2: ESP PRO
local V2 = createPanel(PgVisuals, "ESP PRO", UDim2.new(0.45, 0, 0, 285), UDim2.new(0.5, 0, 0.05, 0))
createSwitch(V2, "BARRA DE VIDA", "HEALTH BAR ESP", "EspHealthBar")
createSwitch(V2, "DISTÂNCIA", "MOSTRAR DISTÂNCIA EM METROS", "EspDistance")
createSwitch(V2, "ESQUELETO", "LINHAS DE OSSOS", "EspSkeleton")
createSwitch(V2, "MIRA NO CENTRO", "CROSSHAIR CUSTOM", "Crosshair")
createSwitch(V2, "HIT MARKER", "MARCAR ACERTO", "HitMarker")
createSwitch(V2, "BAIXO DESEMPENHO", "REDUZ TAXA DE UPDATE ESP", "LowPerformance")

-- Exploits Tab (formerly Player)
-- P1: title(30) + 2 switches(34*2=68) + 2 sliders(40*2=80) + switch(34) + padding(12*4=48) + margins = ~295
local P1 = createPanel(PgExploits, "MOVIMENTO", UDim2.new(0.45, 0, 0, 295), UDim2.new(0.02, 0, 0.05, 0))
createSwitch(P1, "VELOCIDADE", "SPEED HACK", "WalkSpeedActive")
createSlider(P1, "SPEED", 16, 300, "WalkSpeedValue")
createSwitch(P1, "FORÇA DO PULO", "SUPER PULO", "JumpPowerActive")
createSlider(P1, "PULO", 50, 500, "JumpPowerValue")
createSwitch(P1, "TELEPORTE CLICK", "CTRL+CLICK PARA TP", "ClickTP")

-- P2: title(30) + 3 switches(34*3=102) + slider(40) + switch(34) + padding(12*4=48) + margins = ~295
local P2 = createPanel(PgExploits, "MUNDO E FÍSICA", UDim2.new(0.45, 0, 0, 295), UDim2.new(0.5, 0, 0.05, 0))
createSwitch(P2, "NOCLIP", "ATRAVESSAR PAREDES", "Noclip")
createSwitch(P2, "PULO INFINITO", "MÚLTIPLOS PULOS", "InfJump")
createSwitch(P2, "VOAR", "ATIVAR VOO", "Fly")
createSlider(P2, "VELOCIDADE VOO", 10, 300, "FlySpeed")
createSwitch(P2, "MODO DEUS", "VIDA INFINITA", "GodMode")

-- P3: EXPLOITS EXTRA
local P3 = createPanel(PgExploits, "EXTRAS", UDim2.new(0.93, 0, 0, 520), UDim2.new(0.02, 0, 0, 330))
createSwitch(P3, "ANTI AFK", "NUNCA KICK POR AFK", "AntiAfk")
createSwitch(P3, "ANTI VOID", "VOLTA AO CAIR DO MAPA", "AntiVoid")
createSwitch(P3, "SPIDER WALK", "ANDAR EM PAREDES", "SpiderWalk")
createSwitch(P3, "AUTO BHOP", "PULA AO TOCAR CHÃO", "AutoBhop")
createSwitch(P3, "DASH", "AVANÇO RÁPIDO COM TECLA", "Dash")
createHotkey(P3, "TECLA DO DASH", "DashKey")
createSlider(P3, "FORÇA DO DASH", 50, 500, "DashForce")
createSwitch(P3, "STAMINA INFINITA", "ZERA VALORES DE STAMINA", "StaminaBypass")
createSwitch(P3, "MAG-NET", "PUXAR ITENS PRÓXIMOS", "MagNet")
createSlider(P3, "RAIO DO MAG-NET", 5, 80, "MagNetRadius")
createSwitch(P3, "AUTO CLICKER", "CLIQUES RÁPIDOS CONSTANTES", "AutoClicker")
createSwitch(P3, "ANDAR NA ÁGUA", "JESUS MODE", "WalkOnWater")
createSwitch(P3, "MUDAR GRAVIDADE", "REDUZ GRAVIDADE", "GravityMod")
createSlider(P3, "FORÇA GRAVIDADE", 0, 196, "GravityValue")

-- Troll Tab
-- T1: title(30) + switch(34) + slider(40) + 3 switches(34*3=102) + slider(40) + padding(12*5=60) + margins = ~360
local T1 = createPanel(PgTroll, "FLING E CAOS", UDim2.new(0.45, 0, 0, 360), UDim2.new(0.02, 0, 0.05, 0))
createSwitch(T1, "FLING GIRATÓRIO", "VOAR EM CIMA DELES", "SpinFling")
createSlider(T1, "FORÇA DO FLING", 50, 5000, "FlingSpeed")
createSwitch(T1, "FLING DE CABEÇA", "LANÇAR CABEÇA NELES", "HeadFling")
createSwitch(T1, "TERREMOTO", "TREMER PERSONAGEM", "Seizure")
createSwitch(T1, "LAG FALSO", "MOVIMENTO TRAVADO", "FakeLag")
createSlider(T1, "INTENSIDADE", 1, 30, "FakeLagIntensity")

-- T2: title(30) + 7 switches(34*7=238) + input(34) + slider(40) + padding(12*8=96) + margins = ~475
local T2 = createPanel(PgTroll, "IRRITAR E TROLLAR", UDim2.new(0.45, 0, 0, 475), UDim2.new(0.5, 0, 0.05, 0))
createSwitch(T2, "SARRAR", "CROUCH SPAM", "Twerk")
createSwitch(T2, "SPAM DE TP", "TELEPORTAR INFINITO", "TpSpam")
createSwitch(T2, "IRRITAR", "ORBITAR JOGADOR", "Annoy")
createSwitch(T2, "NUKAR SERVIDOR", "DERRUBAR TODOS", "NukeAll")
createSwitch(T2, "CRASH SERVIDOR", "SOBRECARREGAR O MAPA", "CrashServer")
createSwitch(T2, "INVISÍVEL", "QUEBRAR SEU CORPO", "Invisible")
createSwitch(T2, "SPAM NO CHAT", "FLOODAR CHAT", "ChatSpam")
createInputBlock(T2, "MENSAGEM DE SPAM", "SpamMessage")
createSlider(T2, "DELAY DO SPAM", 0.5, 10, "SpamDelay")

-- T3: TROLLS PRO
local T3 = createPanel(PgTroll, "TROLLS PRO", UDim2.new(0.93, 0, 0, 285), UDim2.new(0.02, 0, 0, 520))
createSwitch(T3, "SPAM DE EMOTE", "DANÇA INFINITA", "EmoteSpam")
createSwitch(T3, "TRAZER ALVO", "FLING PUXANDO O ALVO", "BringPlayer")
createSwitch(T3, "CONGELAR ALVO", "ANCHOR LOCAL DO ALVO", "FreezePlayer")
createSwitch(T3, "PERSONAGEM RAINBOW", "CICLO DE CORES", "RainbowChar")
createSwitch(T3, "ALTERAR TAMANHO", "GIGANTE/MINI", "SizeChar")
createSlider(T3, "TAMANHO", 0.2, 5.0, "CharSize")
createSwitch(T3, "TELA DE KICK FALSA", "MOSTRA BAN FAKE PRA VOCÊ", "FakeKick")

-- Cars Tab
-- Ca1: title(30) + 3 switches(34*3=102) + slider(40) + padding(12*4=48) + margins = ~260
local Ca1 = createPanel(PgCars, "CONTROLES BÁSICOS", UDim2.new(0.45, 0, 0, 260), UDim2.new(0.02, 0, 0.05, 0))
createSwitch(Ca1, "AUMENTAR VELOCIDADE", "MAIS RÁPIDO NO 'W'", "CarSpeed")
createSlider(Ca1, "VELOCIDADE ADICIONAL", 0, 100, "CarSpeedValue")
createSwitch(Ca1, "SUPER FREIO", "FREAR NO 'S'", "CarBrake")
createSwitch(Ca1, "IGNORAR COLISÕES", "ATRAVESSAR OBJETOS", "CarNoclip")

-- Ca2: title(30) + 5 switches(34*5=170) + slider(40) + padding(12*6=72) + margins = ~315
local Ca2 = createPanel(PgCars, "EXPLOITS CARS", UDim2.new(0.45, 0, 0, 315), UDim2.new(0.5, 0, 0.05, 0))
createSwitch(Ca2, "CAR FLY", "VOAR COM VEÍCULO", "CarFly")
createSlider(Ca2, "VELOCIDADE DO VOO", 10, 300, "CarFlySpeed")
createSwitch(Ca2, "FLING DE CARRO", "TORNADO VEICULAR", "CarFling")
createSwitch(Ca2, "DESTRANCAR TODOS", "TENTAR GLOBAL", "UnlockCars")
createSwitch(Ca2, "DESTRANCAR PERTO", "AURA DESBLOQUEIO", "UnlockAura")
createSwitch(Ca2, "TRANCAR PERTO", "AURA DE BLOQUEIO", "LockAura")

-- Ca3: CARROS PRO
local Ca3 = createPanel(PgCars, "CARROS PRO", UDim2.new(0.93, 0, 0, 260), UDim2.new(0.02, 0, 0, 380))
createButton(Ca3, "TP CARRO AO ALVO", "TELEPORTAR VEÍCULO PRO TARGET", function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.SeatPart) then showToast("CAR TP", "Você não está em um veículo", false) return end
    local target = (SelectedTrollTarget and SelectedTrollTarget.Character and SelectedTrollTarget.Character:FindFirstChild("HumanoidRootPart")) and SelectedTrollTarget or nil
    if not target then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then target = p; break end
        end
    end
    if target and target.Character then
        local seat = hum.SeatPart
        local veh = seat.AssemblyRootPart or seat
        veh.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 5, -8)
        showToast("CAR TP", "Levado pro " .. target.DisplayName, true)
    end
end)
createSwitch(Ca3, "PUXAR CARROS (MAGNET)", "TRAZ VEÍCULOS VAZIOS PRA PERTO", "BringCars")
createSwitch(Ca3, "ANTI FLIP", "MANTÉM O CARRO EM PÉ", "AntiFlip")
createSwitch(Ca3, "NUNCA CAIR DA MOTO/CARRO", "NÃO DEIXA TE DERRUBAREM", "AntiFall")
createSwitch(Ca3, "CARRO REFORÇADO", "MASSA AUMENTADA", "CarStrong")
createSwitch(Ca3, "SUSPENSÃO TUNADA", "REDUZ ATRITO E RIGIDEZ", "CarSuspension")

-- Guns Tab
-- G1: SISTEMA DE ARMAS (panel grande, ~340)
local G1 = createPanel(PgGuns, "SISTEMA DE ARMAS", UDim2.new(0.93, 0, 0, 340), UDim2.new(0.02, 0, 0.05, 0))

-- Padrões comuns de Remotes que dão armas (jogos variados)
local weaponRemotePatterns = {
    "givetool","givegun","giveweapon","giveitem","getweapon","getgun","gettool",
    "equipweapon","equipgun","equiptool","spawnweapon","spawngun","spawntool",
    "buygun","buyweapon","buytool","requestweapon","requesttool","requestgun",
    "weaponrequest","toolrequest","loadweapon","loadgun","loadtool",
    "addtool","additem","grant"
}

local function isWeaponRemote(name)
    local lo = string.lower(name)
    for _, pat in ipairs(weaponRemotePatterns) do
        if string.find(lo, pat, 1, true) then return true end
    end
    return false
end

local function autoEquipFirst()
    local bp = Player:FindFirstChild("Backpack")
    local char = Player.Character
    if not (bp and char) then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local tool = bp:FindFirstChildOfClass("Tool")
    if tool then pcall(function() hum:EquipTool(tool) end) end
end

-- 1) Puxar Armas (Clone Local)
createButton(G1, "PUXAR ARMAS (LOCAL)", "CLONA TOOLS - SÓ VISUAL", function()
    local count = 0
    local bp = Player:FindFirstChild("Backpack")
    if not bp then return end
    local function copyTool(obj)
        if obj:IsA("Tool") and not bp:FindFirstChild(obj.Name) then
            local clone = obj:Clone()
            clone.Parent = bp
            count = count + 1
        end
    end
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do copyTool(obj) end
    if count == 0 then
        for _, obj in pairs(workspace:GetDescendants()) do copyTool(obj) end
    end
    autoEquipFirst()
    showToast("ARMAS", count .. " armas cloned (local)", true)
end)

-- 2) Tentar pegar via Remotes (FUNCIONAL no server)
createButton(G1, "TENTAR REMOTES", "DISPARA REMOTES DE ARMA", function()
    local count = 0
    local tried = {}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and isWeaponRemote(obj.Name) and not tried[obj] then
            tried[obj] = true
            -- Tenta nomes comuns como argumento
            local guesses = {"All","Gun","Sword","Knife","M4","AK47","Pistol",1,true}
            pcall(function()
                if obj:IsA("RemoteEvent") then
                    obj:FireServer()
                    for _, g in ipairs(guesses) do pcall(function() obj:FireServer(g) end) end
                else
                    pcall(function() obj:InvokeServer() end)
                    for _, g in ipairs(guesses) do pcall(function() obj:InvokeServer(g) end) end
                end
            end)
            count = count + 1
        end
    end
    -- Procura também no workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and isWeaponRemote(obj.Name) and not tried[obj] then
            tried[obj] = true
            pcall(function()
                if obj:IsA("RemoteEvent") then obj:FireServer() else obj:InvokeServer() end
            end)
            count = count + 1
        end
    end
    task.wait(0.5)
    autoEquipFirst()
    showToast("ARMAS", "Disparei " .. count .. " remotes. Verifica o inventário!", true)
end)

-- 3) Pegar armas dropadas (workspace) via TP
createButton(G1, "PEGAR DROPS DO MAPA", "TP NAS TOOLS NO CHÃO", function()
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then showToast("ARMAS", "Sem personagem", false) return end
    local count = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Parent == workspace then
            local h = obj:FindFirstChild("Handle")
            if h then
                local original = hrp.CFrame
                hrp.CFrame = h.CFrame
                task.wait(0.15)
                hrp.CFrame = original
                count = count + 1
                if count >= 30 then break end
            end
        end
    end
    autoEquipFirst()
    showToast("ARMAS", "Tentei pegar " .. count .. " drops", true)
end)

-- 4) Switch: Auto Re-Equip
createSwitch(G1, "AUTO RE-EQUIP", "RE-PUXAR APÓS MORRER", "AutoReEquip")
createSwitch(G1, "AUTO EQUIP", "EQUIPA PRIMEIRA AUTOMATICO", "AutoEquip")
createSwitch(G1, "LISTAR REMOTES NO CONSOLE", "DEBUG", "LogWeaponRemotes")

-- Logic: AutoReEquip on respawn
Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Configs.AutoReEquip then
        -- Re-puxa armas locais
        local bp = Player:WaitForChild("Backpack", 3)
        if bp then
            for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("Tool") and not bp:FindFirstChild(obj.Name) then
                    pcall(function() obj:Clone().Parent = bp end)
                end
            end
        end
        -- E também tenta remotes
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and isWeaponRemote(obj.Name) then
                pcall(function()
                    if obj:IsA("RemoteEvent") then obj:FireServer() else obj:InvokeServer() end
                end)
            end
        end
    end
    if Configs.AutoEquip then
        task.wait(0.5)
        autoEquipFirst()
    end
end)

-- Log weapon remotes for debug
task.spawn(function()
    while task.wait(2) do
        if Configs.LogWeaponRemotes then
            print("[LYAN] === REMOTES DE ARMA ENCONTRADOS ===")
            for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and isWeaponRemote(obj.Name) then
                    print("  " .. obj:GetFullName())
                end
            end
            Configs.LogWeaponRemotes = false
        end
    end
end)

-- Config Tab
-- Cf1: title(30) + hotkey(34) + dropdown(34) + padding(12*2=24) + save btn + load btn + margins
local Cf1 = createPanel(PgConfig, "CONFIGURAÇÕES DO MENU", UDim2.new(0.45, 0, 0, 360), UDim2.new(0.02, 0, 0.05, 0))
createHotkey(Cf1, "TECLA DE ABRIR/FECHAR", "MenuKeybind")
createDropdown(Cf1, "COR DE DESTAQUE", {"Vermelho", "Azul", "Verde", "Roxo", "Branco"}, "ThemeColor")

local function updateThemeColor()
    local colorMap = {
        ["Vermelho"] = Color3.fromRGB(239, 68, 68),
        ["Azul"] = Color3.fromRGB(59, 130, 246),
        ["Verde"] = Color3.fromRGB(34, 197, 94),
        ["Roxo"] = Color3.fromRGB(168, 85, 247),
        ["Branco"] = Color3.fromRGB(255, 255, 255),
    }
    local oldColor = Colors.Accent
    local newColor = colorMap[Configs.ThemeColor] or colorMap["Vermelho"]
    if newColor ~= oldColor then
        Colors.Accent = newColor
        for _, obj in pairs(ScreenGui:GetDescendants()) do
            if obj:IsA("Frame") and obj.BackgroundColor3 == oldColor then
                obj.BackgroundColor3 = newColor
            elseif obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                if obj.TextColor3 == oldColor then
                    obj.TextColor3 = newColor
                end
                if obj.BackgroundColor3 == oldColor then
                    obj.BackgroundColor3 = newColor
                end
            elseif obj:IsA("UIStroke") and obj.Color == oldColor then
                obj.Color = newColor
            end
        end
    end
end
task.spawn(function()
    while task.wait(0.5) do 
        pcall(updateThemeColor) 
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if Configs.UnlockCars or Configs.UnlockAura or Configs.LockAura then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                    if Configs.UnlockCars then
                        obj.Disabled = false
                    elseif hrp then
                        local dist = (obj.Position - hrp.Position).Magnitude
                        if dist <= 30 then
                            if Configs.UnlockAura then obj.Disabled = false end
                            if Configs.LockAura then obj.Disabled = true end
                        end
                    end
                end
            end
        end
    end
end)

local btnSave = Instance.new("TextButton")
btnSave.Size = UDim2.new(1, -20, 0, 30)
btnSave.Position = UDim2.new(0, 10, 0, 100)
btnSave.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
btnSave.Text = "SALVAR CONFIGURAÇÃO"
btnSave.TextColor3 = Colors.TextMain
btnSave.Font = Enum.Font.GothamBold
btnSave.TextSize = 12
btnSave.Parent = Cf1:FindFirstChild("Content") or Cf1
-- Removed UICorner from btnSave
btnSave.MouseButton1Click:Connect(function() saveConfig() showToast("Configuração", "Configurações Salvas!") end)
btnSave.MouseEnter:Connect(function() TweenService:Create(btnSave, TweenPresets.Fast, {BackgroundColor3 = Colors.Accent, TextColor3 = Color3.new(0,0,0)}):Play() end)
btnSave.MouseLeave:Connect(function() TweenService:Create(btnSave, TweenPresets.Fast, {BackgroundColor3 = Color3.fromRGB(25, 25, 25), TextColor3 = Colors.TextMain, Size = UDim2.new(1, -20, 0, 30)}):Play() end)
btnSave.MouseButton1Down:Connect(function() TweenService:Create(btnSave, TweenPresets.Fast, {Size = UDim2.new(1, -24, 0, 26)}):Play() end)
btnSave.MouseButton1Up:Connect(function() TweenService:Create(btnSave, TweenPresets.Fast, {Size = UDim2.new(1, -20, 0, 30)}):Play() end)

local btnLoad = Instance.new("TextButton")
btnLoad.Size = UDim2.new(1, -20, 0, 30)
btnLoad.Position = UDim2.new(0, 10, 0, 140)
btnLoad.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
btnLoad.Text = "CARREGAR CONFIGURAÇÃO"
btnLoad.TextColor3 = Colors.TextMain
btnLoad.Font = Enum.Font.GothamBold
btnLoad.TextSize = 12
btnLoad.Parent = Cf1:FindFirstChild("Content") or Cf1
-- Removed UICorner from btnLoad
btnLoad.MouseButton1Click:Connect(function() loadConfig() showToast("Configuração", "Configurações Carregadas!") end)
btnLoad.MouseEnter:Connect(function() TweenService:Create(btnLoad, TweenPresets.Fast, {BackgroundColor3 = Colors.Border}):Play() end)
btnLoad.MouseLeave:Connect(function() TweenService:Create(btnLoad, TweenPresets.Fast, {BackgroundColor3 = Color3.fromRGB(25, 25, 25), Size = UDim2.new(1, -20, 0, 30)}):Play() end)
btnLoad.MouseButton1Down:Connect(function() TweenService:Create(btnLoad, TweenPresets.Fast, {Size = UDim2.new(1, -24, 0, 26)}):Play() end)
btnLoad.MouseButton1Up:Connect(function() TweenService:Create(btnLoad, TweenPresets.Fast, {Size = UDim2.new(1, -20, 0, 30)}):Play() end)

local btnReset = Instance.new("TextButton")
btnReset.Size = UDim2.new(1, -20, 0, 30)
btnReset.Position = UDim2.new(0, 10, 0, 180)
btnReset.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
btnReset.Text = "RESETAR CONFIGURAÇÃO"
btnReset.TextColor3 = Colors.TextMain
btnReset.Font = Enum.Font.GothamBold
btnReset.TextSize = 12
btnReset.Parent = Cf1:FindFirstChild("Content") or Cf1
-- Removed UICorner from btnReset
btnReset.MouseButton1Click:Connect(function() resetConfig() showToast("Configuração", "Tudo foi resetado!") end)
btnReset.MouseEnter:Connect(function() TweenService:Create(btnReset, TweenPresets.Fast, {BackgroundColor3 = Color3.fromRGB(239, 68, 68), TextColor3 = Color3.new(0,0,0)}):Play() end)
btnReset.MouseLeave:Connect(function() TweenService:Create(btnReset, TweenPresets.Fast, {BackgroundColor3 = Color3.fromRGB(25, 25, 25), TextColor3 = Colors.TextMain, Size = UDim2.new(1, -20, 0, 30)}):Play() end)
btnReset.MouseButton1Down:Connect(function() TweenService:Create(btnReset, TweenPresets.Fast, {Size = UDim2.new(1, -24, 0, 26)}):Play() end)
btnReset.MouseButton1Up:Connect(function() TweenService:Create(btnReset, TweenPresets.Fast, {Size = UDim2.new(1, -20, 0, 30)}):Play() end)

-- Cf2: UTILITY
local Cf2 = createPanel(PgConfig, "UTILITY & SERVER", UDim2.new(0.45, 0, 0, 480), UDim2.new(0.5, 0, 0.05, 0))
createSwitch(Cf2, "WATERMARK", "FPS/PING/NICK NO CANTO", "Watermark")
createSwitch(Cf2, "MODO STREAM (OBS BYPASS)", "OCULTA TODOS OS VISUAIS", "StreamMode", function(state)
    ScreenGui.Enabled = not state
    if state then showToast("Stream Mode", "Menu oculto! Pressione a tecla configurada para voltar.", true) end
end)
createHotkey(Cf2, "TECLA MODO STREAM", "StreamModeKey")
createSwitch(Cf2, "ANTI SCREENSHOT", "ESCONDE UI NO PRTSCR/F12", "AntiScreenshot")
createSwitch(Cf2, "LOG DE KILLS", "PRINT NO CONSOLE", "LogKills")
createSwitch(Cf2, "DETECTOR DE JOGO", "MOSTRA NOME DO GAME", "GameDetector")
createSwitch(Cf2, "AUTO FARM", "ANDA EM PARTS COM PALAVRA", "AutoFarm")
createInputBlock(Cf2, "PALAVRA CHAVE", "FarmKeyword")
createHotkey(Cf2, "PÂNICO (DESLIGA TUDO)", "PanicButton")
createButton(Cf2, "REJOIN", "ENTRAR DE NOVO NO SERVIDOR", function()
    pcall(function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, Player)
    end)
end)
createButton(Cf2, "SERVER HOP", "PULAR PRO PRÓXIMO SERVIDOR", function()
    pcall(function()
        local TeleportService = game:GetService("TeleportService")
        local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
        if req then
            local res = req({Url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100", Method="GET"})
            local body = HttpService:JSONDecode(res.Body or res.body or "{}")
            for _, srv in ipairs(body.data or {}) do
                if srv.playing and srv.maxPlayers and srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, Player)
                    return
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, Player)
    end)
end)
createButton(Cf2, "SCREENSHOT", "COPIAR CONFIG PRO CLIPBOARD", function()
    if setclipboard then setclipboard(HttpService:JSONEncode(Configs)) showToast("CLIPBOARD", "Config copiada", true) end
end)

-- ================================================================
-- [Server Tab] Players + Vehicles
-- ================================================================
PgServer.ScrollingEnabled = false  -- sub-páginas controlam scroll

-- SubTab Bar
local SubTabBar = Instance.new("Frame")
SubTabBar.Size = UDim2.new(1, -20, 0, 36)
SubTabBar.Position = UDim2.new(0, 10, 0, 10)
SubTabBar.BackgroundColor3 = Colors.Panel
SubTabBar.BorderSizePixel = 0
SubTabBar.Parent = PgServer
-- Removed UICorner from SubTabBar
local stb = Instance.new("UIStroke", SubTabBar)
stb.Color = Colors.Border
stb.Thickness = 1

local function makeSubTabBtn(label, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -2, 1, -4)
    b.Position = UDim2.new(x, 2, 0, 2)
    b.BackgroundColor3 = Colors.Background
    b.BorderSizePixel = 0
    b.Text = label
    b.TextColor3 = Colors.TextDim
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.AutoButtonColor = false
    b.Parent = SubTabBar
    -- Removed UICorner from b (makeSubTabBtn)
    b.MouseButton1Down:Connect(function() TweenService:Create(b, TweenPresets.Fast, {TextSize = 11}):Play() end)
    b.MouseButton1Up:Connect(function() TweenService:Create(b, TweenPresets.Pop, {TextSize = 13}):Play() end)
    return b
end
local btnPlayers = makeSubTabBtn("PLAYERS", 0)
local btnVeiculos = makeSubTabBtn("VEÍCULOS", 0.5)

-- Sub Pages
local function makeSubPage()
    local sp = Instance.new("Frame")
    sp.Size = UDim2.new(1, -20, 1, -56)
    sp.Position = UDim2.new(0, 10, 0, 50)
    sp.BackgroundTransparency = 1
    sp.Visible = false
    sp.Parent = PgServer
    return sp
end
local SubPgPlayers = makeSubPage()
local SubPgVeiculos = makeSubPage()
SubPgPlayers.Visible = true

local function activateSub(active)
    if active == "players" then
        SubPgPlayers.Visible = true
        SubPgVeiculos.Visible = false
        btnPlayers.BackgroundColor3 = Colors.Accent
        btnPlayers.TextColor3 = Color3.new(0,0,0)
        btnVeiculos.BackgroundColor3 = Colors.Background
        btnVeiculos.TextColor3 = Colors.TextDim
    else
        SubPgPlayers.Visible = false
        SubPgVeiculos.Visible = true
        btnVeiculos.BackgroundColor3 = Colors.Accent
        btnVeiculos.TextColor3 = Color3.new(0,0,0)
        btnPlayers.BackgroundColor3 = Colors.Background
        btnPlayers.TextColor3 = Colors.TextDim
    end
end
btnPlayers.MouseButton1Click:Connect(function() activateSub("players") end)
btnVeiculos.MouseButton1Click:Connect(function() activateSub("veiculos") end)
activateSub("players")

-- ====== Players Sub-page ======
local PlayersScroll = Instance.new("ScrollingFrame")
PlayersScroll.Size = UDim2.new(1, 0, 1, 0)
PlayersScroll.BackgroundTransparency = 1
PlayersScroll.BorderSizePixel = 0
PlayersScroll.ScrollBarThickness = 6
PlayersScroll.ScrollBarImageColor3 = Colors.Accent
PlayersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayersScroll.Active = true
PlayersScroll.Parent = SubPgPlayers
local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 6)
plLayout.Parent = PlayersScroll
plLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PlayersScroll.CanvasSize = UDim2.new(0, 0, 0, plLayout.AbsoluteContentSize.Y + 10)
end)

-- Helpers de veículos (declarados antes pra serem usados por buildPlayerRow)
local function findVehicles()
    local list = {}
    local seen = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("VehicleSeat") or (v:IsA("Seat") and v.Parent and (v.Parent:FindFirstChildWhichIsA("VehicleSeat", true) or v.Parent.Name:lower():find("car") or v.Parent.Name:lower():find("vehicle") or v.Parent.Name:lower():find("bike"))) then
            local model = v:FindFirstAncestorOfClass("Model")
            if model and not seen[model] then
                seen[model] = true
                table.insert(list, {Model = model, Seat = v:IsA("VehicleSeat") and v or v.Parent:FindFirstChildWhichIsA("VehicleSeat", true) or v})
            end
        end
    end
    return list
end

local function findVehicleOfPlayer(p)
    if not (p.Character) then return nil end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        local model = hum.SeatPart:FindFirstAncestorOfClass("Model")
        return model, hum.SeatPart
    end
    return nil
end

local function tpVehicleTo(model, cf)
    if not model then return end
    local prim = model.PrimaryPart or model:FindFirstChildWhichIsA("VehicleSeat", true) or model:FindFirstChildWhichIsA("BasePart", true)
    if not prim then return end
    pcall(function()
        if model.PrimaryPart then
            model:PivotTo(cf)
        else
            local offset = cf * prim.CFrame:Inverse()
            for _, p in pairs(model:GetDescendants()) do
                if p:IsA("BasePart") then p.CFrame = offset * p.CFrame end
            end
        end
    end)
end

local function sitInVehicle(seat)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and seat then
        hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.1)
        hrp.CFrame = seat.CFrame + Vector3.new(0, 1, 0)
    end
end

-- Estado global de espectar
local SpectatingPlayer = nil
local function stopSpectate()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then Camera.CameraSubject = hum end
    SpectatingPlayer = nil
end

-- Bring player até mim (fling-style — funciona em não-FE; em FE depende do jogo)
local function bringPlayerToMe(target)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not (hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then return end
    local thrp = target.Character.HumanoidRootPart
    -- Tentativa direta (não-FE)
    pcall(function() thrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -3) end)
    -- Tentativa via velocidade (network ownership pode permitir parcialmente)
    local dir = (hrp.Position - thrp.Position)
    if dir.Magnitude > 0 then
        pcall(function() thrp.AssemblyLinearVelocity = dir.Unit * 250 + Vector3.new(0, 50, 0) end)
    end
end

local playerRows = {}
local function buildPlayerRow(p)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 56)
    row.BackgroundColor3 = Colors.Panel
    row.BorderSizePixel = 0
    row.Parent = PlayersScroll
    -- Removed UICorner from row
    local rs = Instance.new("UIStroke", row); rs.Color = Colors.Border; rs.Thickness = 1

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0.4, 0, 0, 22)
    nameLbl.Position = UDim2.new(0, 12, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = p.DisplayName .. "  (@" .. p.Name .. ")"
    nameLbl.TextColor3 = Colors.TextMain
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = row

    local distLbl = Instance.new("TextLabel")
    distLbl.Size = UDim2.new(0.4, 0, 0, 18)
    distLbl.Position = UDim2.new(0, 12, 0, 30)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "Distância: --"
    distLbl.TextColor3 = Colors.TextDim
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 11
    distLbl.TextXAlignment = Enum.TextXAlignment.Left
    distLbl.Parent = row

    local function smallBtn(label, xRight, w, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, w, 0, 26)
        b.Position = UDim2.new(1, -xRight - w, 0.5, -13)
        b.BackgroundColor3 = Colors.Background
        b.BorderSizePixel = 0
        b.Text = label
        b.TextColor3 = Colors.TextMain
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.AutoButtonColor = false
        b.Parent = row
        -- Removed UICorner from b (smallBtn)
        local bs = Instance.new("UIStroke", b); bs.Color = Colors.Border
        b.MouseEnter:Connect(function() bs.Color = Colors.Accent end)
        b.MouseLeave:Connect(function() bs.Color = Colors.Border end)
        b.MouseButton1Click:Connect(fn)
        return b
    end

    -- Botões da direita pra esquerda: ALVO | CARRO | TRAZER | ESPEC. | TP
    -- xRight = distância da borda direita até o lado direito do botão
    local btnTP = smallBtn("TP", 290, 50, function()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        local thrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp and thrp then hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 3) end
    end)
    local btnSpec = smallBtn("ESPEC.", 230, 55, function() end)
    btnSpec.MouseButton1Click:Connect(function()
        if SpectatingPlayer == p then
            stopSpectate()
            btnSpec.Text = "ESPEC."
            btnSpec.BackgroundColor3 = Colors.Background
            btnSpec.TextColor3 = Colors.TextMain
            showToast("ESPECTAR", "Voltou pra você", true)
        else
            -- atualiza outros botões
            for _, r in pairs(playerRows) do
                if r.SpecBtn then r.SpecBtn.Text = "ESPEC."; r.SpecBtn.BackgroundColor3 = Colors.Background; r.SpecBtn.TextColor3 = Colors.TextMain end
            end
            if p.Character and p.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = p.Character.Humanoid
                SpectatingPlayer = p
                btnSpec.Text = "PARAR"
                btnSpec.BackgroundColor3 = Colors.Accent
                btnSpec.TextColor3 = Color3.new(0,0,0)
                showToast("ESPECTAR", "Vendo " .. p.DisplayName, true)
            end
        end
    end)
    smallBtn("TRAZER", 170, 55, function()
        bringPlayerToMe(p)
        showToast("TRAZER", "Trazendo " .. p.DisplayName, true)
    end)
    smallBtn("CARRO", 110, 55, function()
        local model, seat = findVehicleOfPlayer(p)
        if not model then showToast("CARRO", p.DisplayName .. " não está em veículo", false) return end
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            tpVehicleTo(model, hrp.CFrame * CFrame.new(0, 3, -8))
            showToast("CARRO", "Carro de " .. p.DisplayName .. " puxado", true)
        end
    end)
    smallBtn("ALVO", 5, 50, function()
        SelectedTrollTarget = p
        showToast("ALVO", "Alvo: " .. p.DisplayName, true)
    end)

    -- Auto-restore do botão se o player que estava sendo espectado spawnar
    return {Row = row, Dist = distLbl, SpecBtn = btnSpec, Player = p}
end

local function rebuildPlayers()
    for _, r in pairs(playerRows) do r.Row:Destroy() end
    playerRows = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player then playerRows[p] = buildPlayerRow(p) end
    end
end
rebuildPlayers()
Players.PlayerAdded:Connect(rebuildPlayers)
Players.PlayerRemoving:Connect(function(p)
    if playerRows[p] then playerRows[p].Row:Destroy(); playerRows[p] = nil end
    if SpectatingPlayer == p then stopSpectate() end
end)

-- Re-attach camera quando jogador espectado respawna
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        if SpectatingPlayer == p then
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then Camera.CameraSubject = hum end
        end
    end)
end)
for _, p in pairs(Players:GetPlayers()) do
    if p ~= Player then
        p.CharacterAdded:Connect(function(char)
            if SpectatingPlayer == p then
                local hum = char:WaitForChild("Humanoid", 5)
                if hum then Camera.CameraSubject = hum end
            end
        end)
    end
end

-- Distance refresher
task.spawn(function()
    while task.wait(0.5) do
        if PgServer.Visible and SubPgPlayers.Visible and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local me = Player.Character.HumanoidRootPart.Position
            for p, r in pairs(playerRows) do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (p.Character.HumanoidRootPart.Position - me).Magnitude
                    r.Dist.Text = string.format("Distância: %d studs  |  HP: %d", math.floor(d),
                        p.Character:FindFirstChildOfClass("Humanoid") and math.floor(p.Character:FindFirstChildOfClass("Humanoid").Health) or 0)
                else
                    r.Dist.Text = "Distância: respawnando..."
                end
            end
        end
    end
end)

-- ====== Veículos Sub-page ======
-- Top: action buttons
local VehTopBar = Instance.new("Frame")
VehTopBar.Size = UDim2.new(1, 0, 0, 38)
VehTopBar.BackgroundTransparency = 1
VehTopBar.Parent = SubPgVeiculos

local function topBtn(label, x, w, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 1, -4)
    b.Position = UDim2.new(0, x, 0, 2)
    b.BackgroundColor3 = Colors.Accent
    b.BorderSizePixel = 0
    b.Text = label
    b.TextColor3 = Color3.new(0,0,0)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.AutoButtonColor = false
    b.Parent = VehTopBar
    -- Removed UICorner from b (vTopBtn)
    b.MouseButton1Click:Connect(fn)
    return b
end

local VehiculosScroll = Instance.new("ScrollingFrame")
VehiculosScroll.Size = UDim2.new(1, 0, 1, -44)
VehiculosScroll.Position = UDim2.new(0, 0, 0, 44)
VehiculosScroll.BackgroundTransparency = 1
VehiculosScroll.BorderSizePixel = 0
VehiculosScroll.ScrollBarThickness = 6
VehiculosScroll.ScrollBarImageColor3 = Colors.Accent
VehiculosScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
VehiculosScroll.Active = true
VehiculosScroll.Parent = SubPgVeiculos
local vLayout = Instance.new("UIListLayout")
vLayout.Padding = UDim.new(0, 6)
vLayout.Parent = VehiculosScroll
vLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    VehiculosScroll.CanvasSize = UDim2.new(0, 0, 0, vLayout.AbsoluteContentSize.Y + 10)
end)

-- (helpers de veículo já declarados acima)

local vehicleRows = {}
local function rebuildVehicles()
    for _, r in pairs(vehicleRows) do r:Destroy() end
    vehicleRows = {}
    local vehicles = findVehicles()
    for _, vData in ipairs(vehicles) do
        local model = vData.Model
        local seat = vData.Seat
        if not model:IsDescendantOf(workspace) then continue end

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 56)
        row.BackgroundColor3 = Colors.Panel
        row.BorderSizePixel = 0
        row.Parent = VehiculosScroll
        -- Removed UICorner from row (VehiculosScroll)
        Instance.new("UIStroke", row).Color = Colors.Border

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(0.45, 0, 0, 22)
        nm.Position = UDim2.new(0, 12, 0, 6)
        nm.BackgroundTransparency = 1
        nm.Text = model.Name
        nm.TextColor3 = Colors.TextMain
        nm.Font = Enum.Font.GothamBold
        nm.TextSize = 13
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.Parent = row

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(0.45, 0, 0, 18)
        info.Position = UDim2.new(0, 12, 0, 30)
        info.BackgroundTransparency = 1
        info.TextColor3 = Colors.TextDim
        info.Font = Enum.Font.Gotham
        info.TextSize = 11
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.Parent = row
        local function updateInfo()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local prim = model.PrimaryPart or seat or model:FindFirstChildWhichIsA("BasePart", true)
            if hrp and prim then
                local d = (prim.Position - hrp.Position).Magnitude
                local owner = "Vazio"
                if seat and seat.Occupant then
                    local op = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
                    owner = op and op.DisplayName or "Bot"
                end
                info.Text = string.format("%d studs  |  %s", math.floor(d), owner)
            else
                info.Text = "..."
            end
        end
        updateInfo()
        row:GetAttributeChangedSignal("Refresh"):Connect(updateInfo)
        task.spawn(function()
            while row.Parent do
                if PgServer.Visible and SubPgVeiculos.Visible then updateInfo() end
                task.wait(0.5)
            end
        end)

        local function vBtn(label, x, w, fn)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, w, 0, 26)
            b.Position = UDim2.new(1, x, 0.5, -13)
            b.BackgroundColor3 = Colors.Background
            b.BorderSizePixel = 0
            b.Text = label
            b.TextColor3 = Colors.TextMain
            b.Font = Enum.Font.GothamBold
            b.TextSize = 10
            b.AutoButtonColor = false
            b.Parent = row
            -- Removed UICorner from b (vRowBtn)
            local bs = Instance.new("UIStroke", b); bs.Color = Colors.Border
            b.MouseEnter:Connect(function() bs.Color = Colors.Accent end)
            b.MouseLeave:Connect(function() bs.Color = Colors.Border end)
            b.MouseButton1Click:Connect(fn)
            return b
        end

        vBtn("SENTAR", -260, 60, function() sitInVehicle(seat) end)
        vBtn("TRAZER", -195, 60, function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then tpVehicleTo(model, hrp.CFrame * CFrame.new(0, 3, -8)) end
            showToast("VEÍCULO", "Trazendo " .. model.Name, true)
        end)
        vBtn("IR ATÉ", -130, 60, function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local prim = model.PrimaryPart or seat
            if hrp and prim then hrp.CFrame = prim.CFrame * CFrame.new(0, 3, 0) end
        end)
        vBtn("ROUBAR", -65, 60, function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                tpVehicleTo(model, hrp.CFrame * CFrame.new(0, 3, -5))
                task.wait(0.1)
                if seat and seat.Occupant then
                    -- Tenta ejetar empurrando o ocupante
                    pcall(function() seat.Occupant.Parent.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 100, 0) end)
                    task.wait(0.3)
                end
                sitInVehicle(seat)
                showToast("ROUBO", "Tentando roubar " .. model.Name, true)
            end
        end)

        table.insert(vehicleRows, row)
    end
    showToast("VEÍCULOS", "Achei " .. #vehicles .. " no servidor", true)
end

topBtn("ATUALIZAR", 0, 100, rebuildVehicles)
topBtn("PUXAR TODOS", 110, 120, function()
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local vehicles = findVehicles()
    for i, vData in ipairs(vehicles) do
        local angle = (i / #vehicles) * math.pi * 2
        local offset = CFrame.new(math.cos(angle) * 15, 3, math.sin(angle) * 15)
        tpVehicleTo(vData.Model, hrp.CFrame * offset)
    end
    showToast("VEÍCULOS", "Puxei " .. #vehicles .. " carros!", true)
end)
topBtn("PUXAR DO ALVO", 240, 130, function()
    if not SelectedTrollTarget then showToast("ROUBO", "Selecione um alvo na aba Players/Server", false) return end
    local model, seat = findVehicleOfPlayer(SelectedTrollTarget)
    if not model then showToast("ROUBO", SelectedTrollTarget.DisplayName .. " não está em veículo", false) return end
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        tpVehicleTo(model, hrp.CFrame * CFrame.new(0, 3, -5))
        task.wait(0.15)
        sitInVehicle(seat)
        showToast("ROUBO", "Roubei o " .. model.Name, true)
    end
end)

-- Auto-rebuild when subpage opens
SubPgVeiculos:GetPropertyChangedSignal("Visible"):Connect(function()
    if SubPgVeiculos.Visible then rebuildVehicles() end
end)

-- Players List Tab (Troll Targets)
-- SelectedTrollTarget forward-declared above

local PlrPanel = Instance.new("Frame")
PlrPanel.Size = UDim2.new(0.95, 0, 0.9, 0)
PlrPanel.Position = UDim2.new(0.02, 0, 0.05, 0)
PlrPanel.BackgroundColor3 = Colors.Panel
PlrPanel.BorderSizePixel = 0
PlrPanel.Parent = PgPlayersList
local pStroke = Instance.new("UIStroke", PlrPanel)
pStroke.Color = Colors.Border
pStroke.Thickness = 1

local PlrHeader = Instance.new("TextLabel")
PlrHeader.Size = UDim2.new(1, -30, 0, 30)
PlrHeader.Position = UDim2.new(0, 15, 0, 5)
PlrHeader.BackgroundTransparency = 1
PlrHeader.Text = "SELECT TROLL TARGET (OR LEAVE EMPTY FOR NEAREST)"
PlrHeader.TextColor3 = Colors.TextDim
PlrHeader.Font = Enum.Font.GothamSemibold
PlrHeader.TextSize = 10
PlrHeader.TextXAlignment = Enum.TextXAlignment.Left
PlrHeader.Parent = PlrPanel

local SelectedLbl = Instance.new("TextLabel")
SelectedLbl.Size = UDim2.new(1, -30, 0, 30)
SelectedLbl.Position = UDim2.new(0, 15, 0, 5)
SelectedLbl.BackgroundTransparency = 1
SelectedLbl.Text = "TARGET: NONE"
SelectedLbl.TextColor3 = Colors.Accent
SelectedLbl.Font = Enum.Font.GothamBold
SelectedLbl.TextSize = 10
SelectedLbl.TextXAlignment = Enum.TextXAlignment.Right
SelectedLbl.Parent = PlrPanel

local PlrScroll = Instance.new("ScrollingFrame")
PlrScroll.Size = UDim2.new(1, -20, 1, -45)
PlrScroll.Position = UDim2.new(0, 10, 0, 35)
PlrScroll.BackgroundTransparency = 1
PlrScroll.BorderSizePixel = 0
PlrScroll.ScrollBarThickness = 4
PlrScroll.ScrollBarImageColor3 = Colors.Accent
PlrScroll.Parent = PlrPanel
local PlrGrid = Instance.new("UIGridLayout")
PlrGrid.CellSize = UDim2.new(0, 100, 0, 120)
PlrGrid.CellPadding = UDim2.new(0, 10, 0, 10)
PlrGrid.SortOrder = Enum.SortOrder.Name
PlrGrid.Parent = PlrScroll

local function refreshPlayers()
    for _, c in pairs(PlrScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    
    local clrBtn = Instance.new("TextButton")
    clrBtn.Size = UDim2.new(0, 100, 0, 30)
    clrBtn.Position = UDim2.new(0, 15, 1, -35)
    clrBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    clrBtn.Text = "CLEAR TARGET"
    clrBtn.TextColor3 = Colors.TextMain
    clrBtn.Font = Enum.Font.GothamBold
    clrBtn.TextSize = 9
    clrBtn.Parent = PlrPanel
    -- Removed UICorner from clrBtn
    clrBtn.MouseButton1Click:Connect(function()
        SelectedTrollTarget = nil
        SelectedLbl.Text = "TARGET: NONE"
        showToast("TROLL TARGET", "Target cleared (Using nearest)", true)
    end)
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player then
            local pFrame = Instance.new("Frame")
            pFrame.Name = p.Name
            pFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            pFrame.BorderSizePixel = 0
            pFrame.Parent = PlrScroll
            local pfStroke = Instance.new("UIStroke", pFrame)
            pfStroke.Color = Colors.Border
            -- Removed UICorner from pFrame
            
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(0, 60, 0, 60)
            img.Position = UDim2.new(0.5, -30, 0, 10)
            img.BackgroundTransparency = 1
            img.Image = "rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=150&h=150"
            img.Parent = pFrame
            -- Removed UICorner from img
            
            local nmLbl = Instance.new("TextLabel")
            nmLbl.Size = UDim2.new(1, 0, 0, 20)
            nmLbl.Position = UDim2.new(0, 0, 0, 75)
            nmLbl.BackgroundTransparency = 1
            nmLbl.Text = p.DisplayName
            nmLbl.TextColor3 = Colors.TextMain
            nmLbl.Font = Enum.Font.GothamSemibold
            nmLbl.TextSize = 10
            nmLbl.TextScaled = true
            nmLbl.Parent = pFrame
            
            local selBtn = Instance.new("TextButton")
            selBtn.Size = UDim2.new(1, -10, 0, 20)
            selBtn.Position = UDim2.new(0, 5, 0, 95)
            selBtn.BackgroundColor3 = Colors.SwitchBgOff
            selBtn.Text = "TARGET"
            selBtn.TextColor3 = Colors.TextDim
            selBtn.Font = Enum.Font.GothamBold
            selBtn.TextSize = 9
            selBtn.Parent = pFrame
            -- Removed UICorner from selBtn
            
            selBtn.MouseButton1Click:Connect(function()
                SelectedTrollTarget = p
                SelectedLbl.Text = "TARGET: " .. string.upper(p.DisplayName)
                showToast("TROLL TARGET", "Selected " .. p.DisplayName, true)
            end)
        end
    end
    PlrScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#Players:GetPlayers() / 6) * 130)
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
task.spawn(refreshPlayers)



-- ================================================================
-- [Engine] Aimbot, Combat, Visuals, Trolls
-- ================================================================
NativeFOVRing.Size = UDim2.new(0, Configs.Fov*2, 0, Configs.Fov*2)

local function isPartVisible(part, character)
    local ignoreList = {Player.Character, character, Camera}
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = ignoreList
    return workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, raycastParams) == nil
end

local lastTarget = nil
local function pickAimPart(char)
    if Configs.DynamicPart and char and char:FindFirstChild("HumanoidRootPart") and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local d = (char.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude
        if d < 30 and char:FindFirstChild("Head") then return "Head"
        elseif d < 80 and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")) then
            return char:FindFirstChild("Torso") and "Torso" or "UpperTorso"
        else return "HumanoidRootPart" end
    end
    return Configs.LockPart
end
local function getClosestPlayer()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    if Configs.StickyAimbot and not Configs.AutoSwitchTarget and lastTarget and lastTarget.Character then
        local part = pickAimPart(lastTarget.Character)
        if lastTarget.Character:FindFirstChild(part) and lastTarget.Character:FindFirstChild("Humanoid") and lastTarget.Character.Humanoid.Health > 0 then
            local screenPoint, onScreen = Camera:WorldToViewportPoint(lastTarget.Character[part].Position)
            if onScreen and screenPoint.Z > 0 and (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude <= Configs.Fov then
                return lastTarget
            end
        end
    end
    local target, closestDistance = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= Player and v.Character and v.Character:FindFirstChild("Humanoid") and (not Configs.TargetDead or v.Character.Humanoid.Health > 0) then
            if not Configs.TeamCheck or v.Team ~= Player.Team then
                local partName = pickAimPart(v.Character)
                local targetPart = v.Character:FindFirstChild(partName)
                if targetPart then
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen and screenPoint.Z > 0 then
                        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
                        if distance <= Configs.Fov and distance < closestDistance then
                            if not Configs.AimWallCheck or isPartVisible(targetPart, v.Character) then
                                closestDistance = distance
                                target = v
                            end
                        end
                    end
                end
            end
        end
    end
    lastTarget = target
    return target
end

local function isHotkeyHeld()
    if isMobile and mobileAimHeld then return true end
    local key = Configs.Hotkey
    if key == "MouseButton1" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif key == "MouseButton2" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    else
        local ok, code = pcall(function() return Enum.KeyCode[key] end)
        if ok and code then return UserInputService:IsKeyDown(code) end
    end
    return false
end

-- Weapon Scan
local weaponScanPatterns = { recoil={"Recoil","Kick","CameraRecoil"}, spread={"Spread","Accuracy"}, ammo={"Ammo","MagSize","Clip"}, firemode={"Auto","SemiAuto"} }
local injectedTools = {}
local function scanAndInject(tool)
    if not tool or injectedTools[tool] then return end
    for _, child in pairs(tool:GetDescendants()) do
        if child:IsA("ModuleScript") then
            local ok, mod = pcall(function() return require(child) end)
            if ok and type(mod) == "table" then
                if Configs.NoRecoil then for _, k in pairs(weaponScanPatterns.recoil) do if mod[k] and type(mod[k])=="number" then mod[k]=0 end end end
                if Configs.NoSpread then for _, k in pairs(weaponScanPatterns.spread) do if mod[k] and type(mod[k])=="number" then mod[k]=0 end end end
                if Configs.InfiniteAmmo then for _, k in pairs(weaponScanPatterns.ammo) do if mod[k] and type(mod[k])=="number" then mod[k]=9999 end end end
                if Configs.FullAuto then for _, k in pairs(weaponScanPatterns.firemode) do if mod[k]~=nil then mod[k]= type(mod[k])=="boolean" and false or "Automatic" end end end
            end
        elseif child:IsA("NumberValue") or child:IsA("IntValue") then
            if Configs.NoRecoil then for _, k in pairs(weaponScanPatterns.recoil) do if child.Name==k then child.Value=0 end end end
            if Configs.NoSpread then for _, k in pairs(weaponScanPatterns.spread) do if child.Name==k then child.Value=0 end end end
            if Configs.InfiniteAmmo then for _, k in pairs(weaponScanPatterns.ammo) do if child.Name==k then child.Value=9999 end end end
        end
    end
    injectedTools[tool] = true
end

-- Trolls Variables
local spinForce = nil
local lastSpam = 0
local twerkTick = 0
local fakeLagTick = 0
local orbitAngle = 0

local flyVel, flyGyro, flyingState = nil, nil, false

-- [Anti-Reset] WalkSpeed & JumpPower bypass via property signal
local antiResetConns = {}
local function hookAntiReset(character)
    for _, c in pairs(antiResetConns) do pcall(function() c:Disconnect() end) end
    antiResetConns = {}
    local hum = character:WaitForChild("Humanoid", 5)
    if not hum then return end
    table.insert(antiResetConns, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if Configs.WalkSpeedActive and hum.WalkSpeed ~= Configs.WalkSpeedValue then
            hum.WalkSpeed = Configs.WalkSpeedValue
        end
    end))
    table.insert(antiResetConns, hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if Configs.JumpPowerActive and hum.JumpPower ~= Configs.JumpPowerValue then
            hum.UseJumpPower = true
            hum.JumpPower = Configs.JumpPowerValue
        end
    end))
    table.insert(antiResetConns, hum.HealthChanged:Connect(function(hp)
        if Configs.GodMode and hp < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end))
end
if Player.Character then hookAntiReset(Player.Character) end
Player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    hookAntiReset(char)
end)

-- [Helper] Get nearest player or selected target
local function getTrollTarget()
    if SelectedTrollTarget and SelectedTrollTarget.Parent and SelectedTrollTarget.Character and SelectedTrollTarget.Character:FindFirstChild("HumanoidRootPart") and SelectedTrollTarget.Character:FindFirstChild("Humanoid") and SelectedTrollTarget.Character.Humanoid.Health > 0 then
        return SelectedTrollTarget
    end
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = Player.Character.HumanoidRootPart.Position
    local nearest, dist = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= Player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local d = (v.Character.HumanoidRootPart.Position - myPos).Magnitude
            if d < dist then nearest = v; dist = d end
        end
    end
    return nearest
end

local lastSeat = nil

RunService.RenderStepped:Connect(function(dt)
    -- Native FOV Position Update
    if NativeFOVRing.Visible and not Configs.StreamMode then
        local mouse = UserInputService:GetMouseLocation()
        NativeFOVRing.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
    elseif Configs.StreamMode then
        NativeFOVRing.Visible = false
    end

    -- Precision Aimbot Logic
    if Configs.Aimbot and isHotkeyHeld() then
        local target = getClosestPlayer()
        local partName = target and pickAimPart(target.Character) or Configs.LockPart
        if target and target.Character and target.Character:FindFirstChild(partName) then
            local aimPart = target.Character[partName]
            local targetPos = aimPart.Position
            if Configs.AimPrediction then
                local vel = aimPart.AssemblyLinearVelocity or Vector3.new()
                targetPos = targetPos + vel * Configs.PredictionStrength
            end
            if Configs.Backtrack then
                local hist = _G.LyanBacktrack and _G.LyanBacktrack[target] or nil
                if hist and #hist >= 3 then targetPos = hist[#hist - 2] end
            end
            if Configs.MissChance and math.random(1, 100) <= Configs.MissChancePercent then targetPos = targetPos + Vector3.new(math.random(-1,1), math.random(-1,1), math.random(-1,1)) end
            
            if Configs.UseMouse and hasMouseMoverel then
                local screenPoint = Camera:WorldToViewportPoint(targetPos)
                local mouseLoc = UserInputService:GetMouseLocation()
                local moveX = (screenPoint.X - mouseLoc.X) * Configs.Smoothness
                local moveY = (screenPoint.Y - mouseLoc.Y) * Configs.Smoothness
                pcall(mousemoverel, moveX, moveY)
            else
                local targetLook = CFrame.lookAt(Camera.CFrame.Position, targetPos)
                Camera.CFrame = Configs.Smoothing and Camera.CFrame:Lerp(targetLook, Configs.Smoothness) or targetLook
            end
        end
    end

    -- Physics & Trolls
    if Player.Character then
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if hum then
            -- Speed/Jump are handled by anti-reset signals; just init if just enabled
            if Configs.WalkSpeedActive and hum.WalkSpeed ~= Configs.WalkSpeedValue then hum.WalkSpeed = Configs.WalkSpeedValue end
            if Configs.JumpPowerActive and hum.JumpPower ~= Configs.JumpPowerValue then hum.UseJumpPower = true hum.JumpPower = Configs.JumpPowerValue end
        end

        local tool = Player.Character:FindFirstChildOfClass("Tool")
        if tool and not injectedTools[tool] then scanAndInject(tool) end

        -- Fly
        if Configs.Fly and hrp and hum then
            if not flyingState then
                flyingState = true
                hum.PlatformStand = true
                flyVel = Instance.new("BodyVelocity", hrp)
                flyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                flyGyro = Instance.new("BodyGyro", hrp)
                flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                flyGyro.P = 10000
            end
            local moveDir = Vector3.new()
            if isMobile then
                local md = hum.MoveDirection
                if md.Magnitude > 0.1 then
                    moveDir = moveDir + Vector3.new(md.X, 0, md.Z).Unit
                end
                if UserInputService.JumpRequest then moveDir = moveDir + Vector3.new(0, 0.6, 0) end
            else
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            end
            flyVel.Velocity = moveDir * Configs.FlySpeed
            flyGyro.CFrame = Camera.CFrame
        elseif flyingState then
            flyingState = false
            if hum then hum.PlatformStand = false end
            if flyVel then flyVel:Destroy() flyVel = nil end
            if flyGyro then flyGyro:Destroy() flyGyro = nil end
        end

        -- Car Logic (Fly, Fling, Speed, Brake, Noclip)
        if hum and hum.SeatPart then
            local seat = hum.SeatPart
            local vehModel = seat.Parent

            -- Car Fly
            if Configs.CarFly then
                if not seat:FindFirstChild("CarFlyVel") then
                    local cv = Instance.new("BodyVelocity", seat)
                    cv.Name = "CarFlyVel"
                    cv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    local cg = Instance.new("BodyGyro", seat)
                    cg.Name = "CarFlyGyro"
                    cg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    cg.P = 9e4
                    cg.D = 1000
                end
                local moveDir = Vector3.new()
                if isMobile then
                    local md = hum.MoveDirection
                    if md.Magnitude > 0.1 then
                        moveDir = moveDir + Vector3.new(md.X, 0, md.Z).Unit
                    end
                else
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                end
                seat.CarFlyVel.Velocity = moveDir * Configs.CarFlySpeed
                local _, yRot, _ = Camera.CFrame:ToEulerAnglesYXZ()
                seat.CarFlyGyro.CFrame = CFrame.Angles(0, yRot, 0)
            else
                if seat:FindFirstChild("CarFlyVel") then seat.CarFlyVel:Destroy() end
                if seat:FindFirstChild("CarFlyGyro") then seat.CarFlyGyro:Destroy() end
            end

            -- Car Fling
            if Configs.CarFling then
                if not seat:FindFirstChild("CarFlingForce") then
                    local sf = Instance.new("BodyAngularVelocity", seat)
                    sf.Name = "CarFlingForce"
                    sf.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                end
                seat.CarFlingForce.AngularVelocity = Vector3.new(0, Configs.FlingSpeed, 0)
            else
                if seat:FindFirstChild("CarFlingForce") then seat.CarFlingForce:Destroy() end
            end

            -- Car Speed
            local isAccelerating = isMobile and (hum.MoveDirection.Magnitude > 0.1) or UserInputService:IsKeyDown(Enum.KeyCode.W)
            if Configs.CarSpeed and Configs.CarSpeedValue > 0 and isAccelerating then
                -- Adiciona velocidade mantendo a física do jogo em vez de sobrescrever
                seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + (seat.CFrame.LookVector * (Configs.CarSpeedValue / 5))
            end

            -- Car Brake
            local isBraking = isMobile and false or UserInputService:IsKeyDown(Enum.KeyCode.S)
            if Configs.CarBrake and isBraking then
                seat.AssemblyLinearVelocity = Vector3.new(0, seat.AssemblyLinearVelocity.Y, 0)
                seat.AssemblyAngularVelocity = Vector3.new(0, 0, 0) -- Evita rodopiar e empinar
            end

            -- Car Noclip
            if Configs.CarNoclip and vehModel then
                for _, part in pairs(vehModel:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end

        -- Spin Fling
        if Configs.SpinFling and hrp then
            if not spinForce then
                spinForce = Instance.new("BodyAngularVelocity", hrp)
                spinForce.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            end
            spinForce.AngularVelocity = Vector3.new(0, Configs.FlingSpeed, 0)
        elseif not Configs.SpinFling and spinForce then spinForce:Destroy() spinForce = nil end

        -- Car Fling
        if Configs.CarFling and hum and hum.SeatPart then
            local seat = hum.SeatPart
            if not seat:FindFirstChild("CarFlingForce") then
                local sf = Instance.new("BodyAngularVelocity", seat)
                sf.Name = "CarFlingForce"
                sf.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            end
            seat.CarFlingForce.AngularVelocity = Vector3.new(0, Configs.FlingSpeed, 0)
        else
            if hum and hum.SeatPart and hum.SeatPart:FindFirstChild("CarFlingForce") then
                hum.SeatPart.CarFlingForce:Destroy()
            end
        end

        -- Head Fling (stretch neck insanely)
        if Configs.HeadFling and hrp then
            local neck = Player.Character:FindFirstChild("Head")
            if neck then
                neck.CanCollide = true
                neck.Size = Vector3.new(5, 5, 5)
                neck.Massless = false
            end
        end

        -- Seizure (rapid shake)
        if Configs.Seizure and hrp then
            hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-2, 2), math.random(0, 1), math.random(-2, 2))
        end

        -- Fake Lag (rubber banding)
        if Configs.FakeLag and hrp then
            fakeLagTick = fakeLagTick + 1
            if fakeLagTick % Configs.FakeLagIntensity == 0 then
                hrp.Anchored = not hrp.Anchored
            end
        else
            if hrp and hrp.Anchored and not Configs.Fly then hrp.Anchored = false end
        end

        -- Twerk / Sarrar (crouch spam near target player)
        if Configs.Twerk and hum and hrp then
            local target = getTrollTarget()
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local targetHrp = target.Character.HumanoidRootPart
                -- Face the victim
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetHrp.Position.X, hrp.Position.Y, targetHrp.Position.Z))
                -- Stay close behind them
                local behindPos = targetHrp.CFrame * CFrame.new(0, 0, 2.5)
                hrp.CFrame = CFrame.lookAt(Vector3.new(behindPos.Position.X, hrp.Position.Y, behindPos.Position.Z), Vector3.new(targetHrp.Position.X, hrp.Position.Y, targetHrp.Position.Z))
                -- Rapid crouch/uncrouch
                twerkTick = twerkTick + 1
                if twerkTick % 4 < 2 then
                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                    hum.HipHeight = -1.5
                else
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    hum.HipHeight = 0
                end
            end
        else
            if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
                pcall(function() 
                    local h = Player.Character:FindFirstChildOfClass("Humanoid")
                    if h.RigType == Enum.HumanoidRigType.R15 then
                        h.HipHeight = 2 -- Default average R15 height
                    else
                        h.HipHeight = 0 -- Default R6 height
                    end
                end)
            end
        end

        -- TP Spam (teleport on top of target player rapidly)
        if Configs.TpSpam and hrp then
            local target = getTrollTarget()
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(math.random(-3,3), math.random(0,5), math.random(-3,3))
            end
        end

        -- Annoy (orbit around target player)
        if Configs.Annoy and hrp then
            local target = getTrollTarget()
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                orbitAngle = orbitAngle + 5
                local rad = math.rad(orbitAngle)
                local targetPos = target.Character.HumanoidRootPart.Position
                hrp.CFrame = CFrame.new(targetPos + Vector3.new(math.cos(rad) * 6, 2, math.sin(rad) * 6), targetPos)
            end
        end

        -- Nuke Server (rapid teleport to all players with spinfling)
        if Configs.NukeAll and hrp then
            local plrs = Players:GetPlayers()
            local validTargets = {}
            for _, p in pairs(plrs) do
                if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    table.insert(validTargets, p)
                end
            end
            if #validTargets > 0 then
                local randTarget = validTargets[math.random(1, #validTargets)]
                hrp.CFrame = randTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                -- Force spin to ensure fling
                if not spinForce then
                    spinForce = Instance.new("BodyAngularVelocity", hrp)
                    spinForce.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                end
                spinForce.AngularVelocity = Vector3.new(0, 8000, 0)
            end
        end

        -- Invisible (break joints to vanish locally)
        if Configs.Invisible then
            for _, part in pairs(Player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 1
                    part.CanCollide = false
                end
                if part:IsA("Decal") or part:IsA("Texture") then part.Transparency = 1 end
            end
        end
    end

    -- Chat Spam
    if Configs.ChatSpam and tick() - lastSpam > Configs.SpamDelay then
        lastSpam = tick()
        pcall(function()
            local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatRemote and chatRemote:FindFirstChild("SayMessageRequest") then
                chatRemote.SayMessageRequest:FireServer(Configs.SpamMessage, "All")
            end
        end)
    end
end)

-- ESP / Noclip / Aimbot Highlight loop
local espCache = {}

local function createEspDrawing(v)
    local hasDrawing = pcall(function() Drawing.new("Square") end)
    if not hasDrawing then return nil end
    local d = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        HealthBg = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Distance = Drawing.new("Text"),
    }
    d.Box.Thickness = 1.5
    d.Box.Filled = false
    d.Box.Transparency = 1
    d.Name.Size = 18
    d.Name.Center = true
    d.Name.Outline = true
    d.Tracer.Thickness = 1.5
    d.Tracer.Transparency = 1
    d.HealthBg.Filled = true; d.HealthBg.Color = Color3.fromRGB(0,0,0); d.HealthBg.Transparency = 0.7
    d.HealthBar.Filled = true; d.HealthBar.Color = Color3.fromRGB(0,255,0); d.HealthBar.Transparency = 1
    d.Distance.Size = 14; d.Distance.Center = true; d.Distance.Outline = true
    -- Skeleton lines (limbs)
    d.Skeleton = {}
    for i = 1, 6 do
        local ln = Drawing.new("Line")
        ln.Thickness = 1
        ln.Transparency = 1
        ln.Color = Color3.fromRGB(255,255,255)
        d.Skeleton[i] = ln
    end
    espCache[v] = d
    return d
end

RunService.Stepped:Connect(function()
    -- Noclip
    if Configs.Noclip and Player.Character then
        for _, v in pairs(Player.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end

    -- Hitbox & Full ESP Updater
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= Player then
            -- Highlight
            local hl = v.Character and v.Character:FindFirstChild("ESP_Highlight")
            if v.Character and not hl then
                hl = Instance.new("Highlight", v.Character)
                hl.Name = "ESP_Highlight"
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0.1
            end
            if hl then
                hl.Enabled = Configs.ESP
                if Configs.TeamColor and v.Team then
                    hl.FillColor = v.TeamColor.Color
                    hl.OutlineColor = Color3.new(1,1,1)
                else
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                end
            end

            -- Drawing ESP (Boxes, Names, Tracers)
            local drawings = espCache[v]
            if drawings == nil then
                drawings = createEspDrawing(v)
            end

            if drawings then
                if Configs.StreamMode then
                    for k, d in pairs(drawings) do
                        if k == "Skeleton" then
                            for _, ln in pairs(d) do ln.Visible = false end
                        else
                            d.Visible = false
                        end
                    end
                elseif v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                    local hrp = v.Character.HumanoidRootPart
                    local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    
                    local cColor = (Configs.TeamColor and v.Team) and v.TeamColor.Color or Color3.fromRGB(255, 50, 50)
                    
                    if onScreen then
                        -- Hitbox Expander (while we iterate players)
                        if Configs.HitboxExpander then
                            hrp.Size = Vector3.new(Configs.HitboxSize, Configs.HitboxSize, Configs.HitboxSize)
                            hrp.Transparency = 0.6
                            hrp.Color = Color3.fromRGB(0, 0, 255)
                            hrp.CanCollide = false
                        end

                        -- Box
                        if Configs.EspBoxes then
                            local sizeX = 2000 / vector.Z
                            local sizeY = 3000 / vector.Z
                            drawings.Box.Size = Vector2.new(sizeX, sizeY)
                            drawings.Box.Position = Vector2.new(vector.X - sizeX / 2, vector.Y - sizeY / 2)
                            drawings.Box.Color = cColor
                            drawings.Box.Visible = true
                        else drawings.Box.Visible = false end

                        -- Name
                        if Configs.EspNames then
                            drawings.Name.Text = v.DisplayName
                            drawings.Name.Position = Vector2.new(vector.X, vector.Y - (3000 / vector.Z) / 2 - 18)
                            drawings.Name.Color = cColor
                            drawings.Name.Visible = true
                        else drawings.Name.Visible = false end

                        -- Tracer
                        if Configs.EspTracers then
                            drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            drawings.Tracer.To = Vector2.new(vector.X, vector.Y + (3000 / vector.Z) / 2)
                            drawings.Tracer.Color = cColor
                            drawings.Tracer.Visible = true
                        else drawings.Tracer.Visible = false end

                        -- HealthBar
                        if Configs.EspHealthBar then
                            local sizeY = 3000 / vector.Z
                            local sizeX = 2000 / vector.Z
                            local hpPct = math.clamp(v.Character.Humanoid.Health / v.Character.Humanoid.MaxHealth, 0, 1)
                            local barH = sizeY
                            local barX = vector.X - sizeX/2 - 6
                            local barY = vector.Y - sizeY/2
                            drawings.HealthBg.Size = Vector2.new(3, barH)
                            drawings.HealthBg.Position = Vector2.new(barX, barY)
                            drawings.HealthBar.Size = Vector2.new(3, barH * hpPct)
                            drawings.HealthBar.Position = Vector2.new(barX, barY + barH * (1 - hpPct))
                            drawings.HealthBar.Color = Color3.fromRGB(math.floor(255*(1-hpPct)), math.floor(255*hpPct), 0)
                            drawings.HealthBg.Visible = true
                            drawings.HealthBar.Visible = true
                        else
                            drawings.HealthBg.Visible = false
                            drawings.HealthBar.Visible = false
                        end

                        -- Distance
                        if Configs.EspDistance and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (hrp.Position - Player.Character.HumanoidRootPart.Position).Magnitude
                            drawings.Distance.Text = string.format("[%d m]", math.floor(d))
                            drawings.Distance.Position = Vector2.new(vector.X, vector.Y + (3000 / vector.Z) / 2 + 4)
                            drawings.Distance.Color = cColor
                            drawings.Distance.Visible = true
                        else drawings.Distance.Visible = false end

                        -- Skeleton
                        if Configs.EspSkeleton then
                            local char = v.Character
                            local bones = {
                                {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                                {"UpperTorso", "LeftUpperArm"}, {"UpperTorso", "RightUpperArm"},
                                {"LowerTorso", "LeftUpperLeg"}, {"LowerTorso", "RightUpperLeg"},
                            }
                            for i, pair in ipairs(bones) do
                                local a = char:FindFirstChild(pair[1])
                                local b = char:FindFirstChild(pair[2])
                                local ln = drawings.Skeleton[i]
                                if a and b and ln then
                                    local va, oa = Camera:WorldToViewportPoint(a.Position)
                                    local vb, ob = Camera:WorldToViewportPoint(b.Position)
                                    if oa and ob then
                                        ln.From = Vector2.new(va.X, va.Y)
                                        ln.To = Vector2.new(vb.X, vb.Y)
                                        ln.Color = cColor
                                        ln.Visible = true
                                    else ln.Visible = false end
                                elseif ln then ln.Visible = false end
                            end
                        else
                            for _, ln in ipairs(drawings.Skeleton) do ln.Visible = false end
                        end
                    else
                        drawings.Box.Visible = false
                        drawings.Name.Visible = false
                        drawings.Tracer.Visible = false
                        drawings.HealthBg.Visible = false
                        drawings.HealthBar.Visible = false
                        drawings.Distance.Visible = false
                        for _, ln in ipairs(drawings.Skeleton) do ln.Visible = false end
                    end
                else
                    drawings.Box.Visible = false
                    drawings.Name.Visible = false
                    drawings.Tracer.Visible = false
                    drawings.HealthBg.Visible = false
                    drawings.HealthBar.Visible = false
                    drawings.Distance.Visible = false
                    for _, ln in ipairs(drawings.Skeleton) do ln.Visible = false end
                end
            else
                -- Fallback for hitbox expander if Drawing API is unsupported
                if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                    local hrp = v.Character.HumanoidRootPart
                    if Configs.HitboxExpander then
                        hrp.Size = Vector3.new(Configs.HitboxSize, Configs.HitboxSize, Configs.HitboxSize)
                        hrp.Transparency = 0.6
                        hrp.Color = Color3.fromRGB(0, 0, 255)
                        hrp.CanCollide = false
                    end
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if espCache[p] then
        for k, d in pairs(espCache[p]) do
            if k == "Skeleton" then
                for _, ln in pairs(d) do pcall(function() ln:Remove() end) end
            else
                pcall(function() d:Remove() end)
            end
        end
        espCache[p] = nil
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Configs.InfJump and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
        Player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if Configs.TriggerBot and Player.Character and Player.Character:FindFirstChildOfClass("Tool") then
            local target = Player:GetMouse().Target
            if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
                local p = Players:GetPlayerFromCharacter(target.Parent)
                if p and p ~= Player and (not Configs.TeamCheck or p.Team ~= Player.Team) then
                    local tool = Player.Character:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() task.wait(0.1) end
                end
            end
        end
    end
end)

-- ================================================================
-- [Engine v2] Novas Features
-- ================================================================

-- ---- GUI Extras: Crosshair, Watermark, HitMarker, FakeKick ----
local CrosshairGui = Instance.new("Frame")
CrosshairGui.Size = UDim2.new(0, 14, 0, 14)
CrosshairGui.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairGui.Position = UDim2.new(0.5, 0, 0.5, 0)
CrosshairGui.BackgroundTransparency = 1
CrosshairGui.Visible = false
CrosshairGui.ZIndex = 30
CrosshairGui.Parent = ScreenGui
local function chLine(w, h, ax, ay)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, w, 0, h)
    f.AnchorPoint = Vector2.new(ax, ay)
    f.Position = UDim2.new(0.5, 0, 0.5, 0)
    f.BackgroundColor3 = Colors.Accent
    f.BorderSizePixel = 0
    f.ZIndex = 30
    f.Parent = CrosshairGui
end
chLine(10, 2, 0.5, 0.5)
chLine(2, 10, 0.5, 0.5)

local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(0, 240, 0, 22)
Watermark.Position = UDim2.new(0, 10, 0, 10)
Watermark.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
Watermark.BackgroundTransparency = 0.3
Watermark.BorderSizePixel = 0
Watermark.Text = "LYAN MENU"
Watermark.TextColor3 = Colors.Accent
Watermark.Font = Enum.Font.GothamBold
Watermark.TextSize = 12
Watermark.Visible = false
Watermark.ZIndex = 30
Watermark.Parent = ScreenGui
-- Removed UICorner from Watermark
local wmStroke = Instance.new("UIStroke", Watermark)
wmStroke.Color = Colors.Accent
wmStroke.Thickness = 1

local HitMarker = Instance.new("Frame")
HitMarker.Size = UDim2.new(0, 24, 0, 24)
HitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
HitMarker.Position = UDim2.new(0.5, 0, 0.5, 0)
HitMarker.BackgroundTransparency = 1
HitMarker.Visible = false
HitMarker.ZIndex = 31
HitMarker.Parent = ScreenGui
local function hmLine(rot)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 12, 0, 2)
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Position = UDim2.new(0.5, 0, 0.5, 0)
    f.Rotation = rot
    f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    f.BorderSizePixel = 0
    f.ZIndex = 31
    f.Parent = HitMarker
end
hmLine(45) hmLine(-45)

local function showHitMarker()
    if Configs.StreamMode then return end
    HitMarker.Visible = true
    task.delay(0.15, function() HitMarker.Visible = false end)
end

local FakeKickGui = Instance.new("Frame")
FakeKickGui.Size = UDim2.new(1, 0, 1, 0)
FakeKickGui.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FakeKickGui.BackgroundTransparency = 0.2
FakeKickGui.Visible = false
FakeKickGui.ZIndex = 100
FakeKickGui.Parent = ScreenGui
local fkTxt = Instance.new("TextLabel")
fkTxt.Size = UDim2.new(1, 0, 0, 80)
fkTxt.Position = UDim2.new(0, 0, 0.4, 0)
fkTxt.BackgroundTransparency = 1
fkTxt.Text = "You were kicked from this experience:\nBanned by Roblox Anti-Cheat"
fkTxt.TextColor3 = Color3.fromRGB(255, 80, 80)
fkTxt.Font = Enum.Font.GothamBold
fkTxt.TextSize = 22
fkTxt.ZIndex = 101
fkTxt.Parent = FakeKickGui
local fkBtn = Instance.new("TextButton")
fkBtn.Size = UDim2.new(0, 120, 0, 36)
fkBtn.Position = UDim2.new(0.5, -60, 0.55, 0)
fkBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
fkBtn.Text = "Leave"
fkBtn.TextColor3 = Color3.new(1,1,1)
fkBtn.Font = Enum.Font.GothamBold
fkBtn.TextSize = 14
fkBtn.ZIndex = 101
fkBtn.Parent = FakeKickGui
-- Removed UICorner from fkBtn
fkBtn.MouseButton1Click:Connect(function() Configs.FakeKick = false FakeKickGui.Visible = false end)

-- ---- AntiAFK via VirtualUser ----
local VirtualUser = game:GetService("VirtualUser")
Player.Idled:Connect(function()
    if Configs.AntiAfk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ---- Panic Button & Stream Mode ----
UserInputService.InputBegan:Connect(function(input, gP)
    if gP then return end
    
    -- Stream Mode Hotkey
    local streamKey = Configs.StreamModeKey
    local streamOk, streamKe = pcall(function() return Enum.KeyCode[streamKey] end)
    if streamOk and streamKe and input.KeyCode == streamKe then
        Configs.StreamMode = not Configs.StreamMode
        ScreenGui.Enabled = not Configs.StreamMode
        showToast("Stream Mode", Configs.StreamMode and "ATIVADO (UI Oculta)" or "DESATIVADO", Configs.StreamMode)
        return
    end

    -- Anti-Screenshot (PrintScreen / F12)
    if Configs.AntiScreenshot and (input.KeyCode == Enum.KeyCode.PrintScreen or input.KeyCode == Enum.KeyCode.F12) then
        local wasStream = Configs.StreamMode
        if not wasStream then
            Configs.StreamMode = true
            ScreenGui.Enabled = false
            -- Pular a notificação Toast no print pra garantir que a tela fique 100% limpa pra foto real
            task.delay(1.5, function()
                Configs.StreamMode = false
                ScreenGui.Enabled = isMenuOpen
                showToast("Anti-Screenshot", "Interface foi restaurada após a captura.", true)
            end)
        end
    end

    -- Panic Button Hotkey
    local key = Configs.PanicButton
    local ok, ke = pcall(function() return Enum.KeyCode[key] end)
    if ok and ke and input.KeyCode == ke then
        for k, _ in pairs(Configs) do
            if type(DefaultConfigs[k]) == "boolean" and DefaultConfigs[k] == false then
                Configs[k] = false
            end
        end
        showToast("PÂNICO", "Tudo desligado!", false)
    end
    -- Dash
    if Configs.Dash then
        local dkOk, dkEnum = pcall(function() return Enum.KeyCode[Configs.DashKey] end)
        if dkOk and dkEnum and input.KeyCode == dkEnum then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Camera.CFrame.LookVector * Configs.DashForce + Vector3.new(0, 5, 0)
            end
        end
    end
end)

-- ---- Game Detector ----
task.spawn(function()
    if Configs.GameDetector then
        pcall(function()
            local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            if info then showToast("GAME", info.Name or "Desconhecido", true) end
        end)
    end
end)

-- ---- Kill Log ----
for _, p in pairs(Players:GetPlayers()) do
    if p ~= Player then
        p.CharacterAdded:Connect(function(c)
            local h = c:WaitForChild("Humanoid", 5)
            if h then
                h.Died:Connect(function()
                    if Configs.LogKills then print("[LYAN] " .. p.Name .. " morreu") end
                end)
            end
        end)
    end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        local h = c:WaitForChild("Humanoid", 5)
        if h then
            h.Died:Connect(function()
                if Configs.LogKills then print("[LYAN] " .. p.Name .. " morreu") end
            end)
        end
    end)
end)

-- ---- Backtrack History ----
_G.LyanBacktrack = {}
RunService.Heartbeat:Connect(function()
    if Configs.Backtrack then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                _G.LyanBacktrack[p] = _G.LyanBacktrack[p] or {}
                table.insert(_G.LyanBacktrack[p], p.Character.HumanoidRootPart.Position)
                if #_G.LyanBacktrack[p] > 10 then table.remove(_G.LyanBacktrack[p], 1) end
            end
        end
    end
end)

-- ---- KillAura / AutoParry / AntiAim / Reach / AntiVoid / AutoBhop / SpiderWalk / StaminaBypass / MagNet ----
local lastBhop = 0
local antiAimAngle = 0
local rainbowHue = 0
local emoteAnim = nil
RunService.Heartbeat:Connect(function(dt)
    if not Player.Character then return end
    local hum = Player.Character:FindFirstChildOfClass("Humanoid")
    local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not hum then return end

    -- AntiVoid
    if Configs.AntiVoid and hrp.Position.Y < -300 then
        hrp.CFrame = CFrame.new(0, 50, 0)
    end

    -- AutoBhop
    if Configs.AutoBhop and tick() - lastBhop > 0.15 then
        if hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            lastBhop = tick()
        end
    end

    -- SpiderWalk
    if Configs.SpiderWalk then
        local dir = hum.MoveDirection
        if dir.Magnitude > 0.1 then
            local rc = workspace:Raycast(hrp.Position, dir * 4, RaycastParams.new())
            if rc then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end

    -- AntiAim
    if Configs.AntiAim then
        antiAimAngle = antiAimAngle + 0.5
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, antiAimAngle, 0)
    end

    -- KillAura
    if Configs.KillAura then
        local tool = Player.Character:FindFirstChildOfClass("Tool")
        if tool then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d <= Configs.KillAuraRadius then
                        pcall(function() tool:Activate() end)
                    end
                end
            end
        end
    end

    -- AutoParry (procura "Ball" no workspace)
    if Configs.AutoParry then
        local ball = workspace:FindFirstChild("Balls") and workspace.Balls:FindFirstChildWhichIsA("BasePart") or workspace:FindFirstChild("Ball")
        if ball then
            local d = (ball.Position - hrp.Position).Magnitude
            if d <= Configs.ParryDistance then
                pcall(function()
                    local re = ReplicatedStorage:FindFirstChild("Parry", true) or ReplicatedStorage:FindFirstChild("ParryButtonPress", true)
                    if re and re:IsA("RemoteEvent") then re:FireServer() end
                end)
            end
        end
    end

    -- Reach
    if Configs.ReachIncrease then
        local tool = Player.Character:FindFirstChildOfClass("Tool")
        if tool then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                handle.Size = Vector3.new(Configs.ReachSize, Configs.ReachSize, Configs.ReachSize)
                handle.Transparency = 0.85
                handle.CanCollide = false
                handle.Massless = true
            end
        end
    end

    -- StaminaBypass (zera valores chamados Stamina)
    if Configs.StaminaBypass then
        for _, v in pairs(Player.Character:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) and string.find(string.lower(v.Name), "stamina") then
                v.Value = v.MaxValue and v.MaxValue or 9999
            end
        end
    end

    -- MagNet (Tools)
    if Configs.MagNet then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj.Parent == workspace then
                local h = obj:FindFirstChild("Handle")
                if h then
                    local d = (h.Position - hrp.Position).Magnitude
                    if d <= Configs.MagNetRadius then
                        h.CFrame = hrp.CFrame
                    end
                end
            end
        end
    end

    -- Bring Cars (Car Magnet)
    if Configs.BringCars then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                if not obj.Occupant then
                    local vehRoot = obj.AssemblyRootPart or obj
                    local d = (vehRoot.Position - hrp.Position).Magnitude
                    if d < 500 and d > 15 then
                        vehRoot.CFrame = hrp.CFrame * CFrame.new(math.random(-15, 15), 5, math.random(-15, 15))
                        if vehRoot:IsA("BasePart") then vehRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) end
                    end
                end
            end
        end
    end
    
    -- Gravity Mod
    if Configs.GravityMod then
        workspace.Gravity = Configs.GravityValue
    else
        workspace.Gravity = 196.2
    end
    
    -- Auto Clicker
    if Configs.AutoClicker and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if VirtualUser then pcall(function() VirtualUser:ClickButton1(Vector2.new()) end) end
    end
    
    -- Walk On Water (Requires checking terrain and parts, so better handled via Collision or Raycast, but for simplicity we create a platform under player if above water)
    if Configs.WalkOnWater then
        local minPos = hrp.Position - Vector3.new(0, 3, 0)
        local mat, _ = workspace.Terrain:ReadVoxels(Region3.new(minPos - Vector3.new(1,1,1), minPos + Vector3.new(1,1,1)), 4)
        if mat[1][1][1] == Enum.Material.Water then
            local waterPart = workspace:FindFirstChild("WaterWalkPart_LYAN")
            if not waterPart then
                waterPart = Instance.new("Part")
                waterPart.Name = "WaterWalkPart_LYAN"
                waterPart.Size = Vector3.new(5, 1, 5)
                waterPart.Transparency = 1
                waterPart.Anchored = true
                waterPart.Parent = workspace
            end
            waterPart.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
        else
            local waterPart = workspace:FindFirstChild("WaterWalkPart_LYAN")
            if waterPart then waterPart:Destroy() end
        end
    else
        local waterPart = workspace:FindFirstChild("WaterWalkPart_LYAN")
        if waterPart then waterPart:Destroy() end
    end

    -- Size Char
    if Configs.SizeChar then
        for _, v in pairs(Player.Character:GetChildren()) do
            if v:IsA("NumberValue") and string.find(v.Name, "Scale") then v.Value = Configs.CharSize end
        end
        if hum:FindFirstChild("BodyHeightScale") then
            hum.BodyHeightScale.Value = Configs.CharSize
            hum.BodyWidthScale.Value = Configs.CharSize
            hum.BodyDepthScale.Value = Configs.CharSize
            hum.HeadScale.Value = Configs.CharSize
        end
    end

    -- Rainbow Char
    if Configs.RainbowChar then
        rainbowHue = (rainbowHue + dt * 0.5) % 1
        local c = Color3.fromHSV(rainbowHue, 1, 1)
        for _, part in pairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.Color = c end
        end
    end

    -- Freeze Player (local only)
    if Configs.FreezePlayer then
        local t = SelectedTrollTarget
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            t.Character.HumanoidRootPart.Anchored = true
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.HumanoidRootPart.Anchored then
                p.Character.HumanoidRootPart.Anchored = false
            end
        end
    end

    -- Bring Player (fling alvo até você)
    if Configs.BringPlayer then
        local t = SelectedTrollTarget
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            local thrp = t.Character.HumanoidRootPart
            local dir = (hrp.Position - thrp.Position).Unit
            pcall(function() thrp.AssemblyLinearVelocity = dir * 200 end)
        end
    end

    -- Emote Spam
    if Configs.EmoteSpam then
        if not emoteAnim or emoteAnim.Parent ~= hum then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://3360689775"
            emoteAnim = hum:LoadAnimation(anim)
            emoteAnim.Looped = true
            emoteAnim:Play()
        end
    elseif emoteAnim then
        emoteAnim:Stop() emoteAnim = nil
    end

    -- Car Mods (AntiFlip / CarStrong / CarSuspension / AntiFall)
    if hum.SeatPart then
        lastSeat = hum.SeatPart
        local seat = hum.SeatPart
        local veh = seat.Parent
        if Configs.AntiFlip and seat.AssemblyRootPart then
            local root = seat.AssemblyRootPart
            local _, y, _ = root.CFrame:ToEulerAnglesYXZ()
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, y, 0)
        end
        if Configs.CarStrong and veh then
            for _, p in pairs(veh:GetDescendants()) do
                if p:IsA("BasePart") and not p.Massless then
                    p.CustomPhysicalProperties = PhysicalProperties.new(20, 0.5, 1, 1, 1)
                end
            end
        end
        if Configs.CarSuspension and veh then
            for _, c in pairs(veh:GetDescendants()) do
                if c:IsA("SpringConstraint") then c.Damping = 50 c.Stiffness = 4500 end
                if c:IsA("CylindricalConstraint") then c.InclinationAngle = 0 end
            end
        end
        -- Prevent jumping out if AntiFall is on and we didn't press space
        if Configs.AntiFall and not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            -- Many games delete the SeatWeld when they want to throw you off. Let's enforce the SeatWeld.
            local weld = seat:FindFirstChild("SeatWeld")
            if not weld and hrp then
                -- Recreate the weld instantly
                local newWeld = Instance.new("Weld")
                newWeld.Name = "SeatWeld"
                newWeld.Part0 = seat
                newWeld.Part1 = hrp
                newWeld.C0 = CFrame.new(0, seat.Size.Y/2 + hrp.Size.Y/2, 0)
                newWeld.Parent = seat
            end
        end
    else
        -- Anti Fall logic recovery
        if Configs.AntiFall and lastSeat and lastSeat.Parent and hum.Health > 0 and not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            -- Fallback fallback: teleport exactly back and enforce weld
            hrp.CFrame = lastSeat.CFrame * CFrame.new(0, lastSeat.Size.Y/2 + hrp.Size.Y/2, 0)
            local newWeld = Instance.new("Weld")
            newWeld.Name = "SeatWeld"
            newWeld.Part0 = lastSeat
            newWeld.Part1 = hrp
            newWeld.C0 = CFrame.new(0, lastSeat.Size.Y/2 + hrp.Size.Y/2, 0)
            newWeld.Parent = lastSeat
            hum.Sit = true
        else
            if not Configs.AntiFall or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                lastSeat = nil
            end
        end
    end

    -- FakeKick GUI sync
    FakeKickGui.Visible = Configs.FakeKick

    -- Crosshair sync
    CrosshairGui.Visible = Configs.Crosshair and not Configs.StreamMode
end)

-- ---- Watermark FPS loop ----
local lastFrame = tick()
local fps = 60
RunService.RenderStepped:Connect(function(dt)
    fps = math.floor(1/dt + 0.5)
    if Configs.Watermark and not Configs.StreamMode then
        Watermark.Visible = true
        local ping = math.floor(Player:GetNetworkPing() * 1000)
        Watermark.Text = string.format("LYAN | %s | %d FPS | %d ms", Player.DisplayName, fps, ping)
    else
        Watermark.Visible = false
    end
end)

-- ---- HitMarker via local damage detection ----
local lastHealths = {}
RunService.Heartbeat:Connect(function()
    if not Configs.HitMarker then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("Humanoid") then
            local h = p.Character.Humanoid.Health
            if lastHealths[p] and h < lastHealths[p] then showHitMarker() end
            lastHealths[p] = h
        end
    end
end)

-- ---- AutoFarm ----
task.spawn(function()
    while task.wait(0.3) do
        if Configs.AutoFarm and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = Player.Character.HumanoidRootPart
            local kw = string.lower(Configs.FarmKeyword or "")
            if kw ~= "" then
                local closest, cd = nil, math.huge
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(string.lower(obj.Name), kw) then
                        local d = (obj.Position - hrp.Position).Magnitude
                        if d < cd then cd = d; closest = obj end
                    end
                end
                if closest then hrp.CFrame = closest.CFrame + Vector3.new(0, 3, 0) end
            end
        end
    end
end)

-- ---- Low Performance ESP throttle ----
-- (já implementado via Stepped; quando LowPerformance ligado, skip ticks alternados)
local lpTick = 0
RunService.Stepped:Connect(function()
    lpTick = lpTick + 1
end)
-- nota: para efeito real, futuras chamadas ESP podem ser puladas usando lpTick%4 ~= 0

-- ---- Silent Aim Hook (best-effort) ----
pcall(function()
    if hookmetamethod and getnamecallmethod then
        local oldNc
        oldNc = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            if Configs.SilentAim and (m == "FindPartOnRayWithIgnoreList" or m == "Raycast") and checkcaller and not checkcaller() then
                -- não interceptamos por segurança — apenas placeholder
            end
            return oldNc(self, ...)
        end)
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if Configs.CrashServer then
            -- Server Crash Logic using Chat spam bypass or RemoteEvent flooding if available
            pcall(function()
                if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
                    for i = 1, 50 do
                        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("CRASHING SERVER WITH LYAN MENU "..string.rep("▤", 50), "All")
                    end
                else
                    game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("CRASHING SERVER WITH LYAN MENU "..string.rep("▤", 50))
                end
                
                -- Lag physics if tool is equipped
                if Player.Character and Player.Character:FindFirstChildOfClass("Tool") then
                    for i = 1, 100 do
                        Player.Character:FindFirstChildOfClass("Tool"):Activate()
                    end
                end
                
                -- Extreme latency induction (Roblox will eventually disconnect everyone if sustained)
                for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        v:FireServer(string.rep("A", 10000))
                    end
                end
            end)
        end
    end
end)
