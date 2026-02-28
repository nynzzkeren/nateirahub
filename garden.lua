if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")

local UI
local libPaths = {"nateirahub/lib.lua", "lib.lua"}
if readfile and isfile then
    for _, path in ipairs(libPaths) do
        if isfile(path) then
            local ok, lib = pcall(function()
                return loadstring(readfile(path))()
            end)
            if ok and lib then
                UI = lib
                break
            end
        end
    end
end
if not UI then
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/nynzzkeren/uiNynzz/refs/heads/main/nateguiee.lua", true))()
    end)
    if ok and lib then UI = lib end
end
if not UI then
    warn("Garden Horizon: Gagal memuat UI")
    return
end

local Window = UI:CreateWindow({
    Title = "Nateira Hub | Garden Horizon",
    Description = "Premium",
    ["Tab Width"] = 150,
    SizeUi = UDim2.fromOffset(590, 355)
})

local Tabs = {
    Info = Window:CreateTab({ Name = "Info", Icon = "" }),
    Main = Window:CreateTab({ Name = "Main", Icon = "" }),
    Shop = Window:CreateTab({ Name = "Shop", Icon = "" }),
    Settings = Window:CreateTab({ Name = "Settings", Icon = "" })
}

local Config = {
    AutoPlant = false,
    RandomPosition = false,
    PlantSpeed = 0.1,
    SelectPlant = "Carrot",
    AutoHarvest = false,
    AutoSell = false,
    AutoSellDelay = 2,
    AutoBuySeedHabis = false,
    AutoBuySeedAmount = false,
    SelectSeed = "Carrot Seed",
    SelectSeedAmount = 1,
    SelectSeedMulti = {},
    SeedPerBuyDelay = 0.1,
    AutoBuyGearHabis = false,
    AutoBuyGearAmount = false,
    SelectGear = "Watering Can",
    SelectGearAmount = 1,
    AutoBuyGearDelay = 2,
    GearPerBuyDelay = 0.1,
    AutoFavorite = false,
    AutoFavoriteItem = "Carrot Seed",
    AntiAFK = false
}

local PlantList = {"Carrot", "Tomato", "Rose", "Wheat", "Corn", "Onion", "strawberry", "Mushroom", "Beetreot", "Potato", "Plum", "Banana", "Cabbage", "Cherry"}
local SeedList = {}
for _, p in ipairs(PlantList) do table.insert(SeedList, p .. " Seed") end
local GearList = {"Watering Can", "Basic Sprinkler", "Harves Bell", "Turbo Sprinkler", "Favorite Tools", "Super Sprinkler"}
local AllItemsList = {}
for _, v in ipairs(PlantList) do table.insert(AllItemsList, v) end
for _, v in ipairs(SeedList) do table.insert(AllItemsList, v) end
for _, v in ipairs(GearList) do table.insert(AllItemsList, v) end

local slotKeys = {
    ["1"] = Enum.KeyCode.One, ["2"] = Enum.KeyCode.Two, ["3"] = Enum.KeyCode.Three,
    ["4"] = Enum.KeyCode.Four, ["5"] = Enum.KeyCode.Five, ["6"] = Enum.KeyCode.Six,
    ["7"] = Enum.KeyCode.Seven, ["8"] = Enum.KeyCode.Eight, ["9"] = Enum.KeyCode.Nine,
    ["0"] = Enum.KeyCode.Zero
}

local SeedShopCFrame = CFrame.new(176.70369, 204.017975, 672, -1, 7.25501863e-08, -2.51582582e-13, 7.25501863e-08, 1, -6.53980834e-08, 2.46837923e-13, -6.53980834e-08, -1)
local GearShopCFrame = CFrame.new(211.851807, 204.016006, 608.169617, 0.0603427328, 6.06159078e-09, -0.998177707, 1.02625384e-08, 1, 6.69305722e-09, 0.998177707, -1.06477147e-08, 0.0603427328)
local SellCFrame = CFrame.new(149.3974, 204.011993, 671.999878, -1, -4.46418298e-08, -5.54518725e-13, -4.46418298e-08, 1, 8.40681409e-08, 5.50765759e-13, 8.40681409e-08, -1)

local function GetMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for i = 1, 6 do
        local plot = plots:FindFirstChild("Plot" .. i)
        if plot and plot:FindFirstChild("Owner") and plot.Owner.Value == Player.Name then
            return plot
        end
    end
    return nil
end

local function GetSpawnPlotCFrame()
    local plot = GetMyPlot()
    if not plot then return nil end
    local spawn = plot:FindFirstChild("Spawn")
    if not spawn then return nil end
    if spawn:IsA("BasePart") then return spawn.CFrame end
    if spawn:IsA("Model") then
        local ok, cf = pcall(function() return spawn:GetPivot() end)
        if ok and cf then return cf end
        if spawn.PrimaryPart then return spawn.PrimaryPart.CFrame end
        local cf, size = spawn:GetBoundingBox()
        if cf then return cf end
    end
    local part = spawn:FindFirstChildWhichIsA("BasePart")
    return part and part.CFrame or nil
end

local function getUuidFromModel(model)
    if not model then return nil end
    local uuid = model:GetAttribute("Uuid")
    if type(uuid) == "string" and #uuid > 0 then return uuid end
    local uv = model:FindFirstChild("Uuid") or model:FindFirstChild("UUID")
    if uv and uv:IsA("StringValue") and uv.Value and #uv.Value > 0 then return uv.Value end
    return nil
end

local function nameEndsWithSeed(name)
    if type(name) ~= "string" or #name < 4 then return false end
    return string.lower(string.sub(name, -4)) == "seed"
end

local function EquipSeedFromHotbar(seedName)
    pcall(function()
        local hotbar = Player.PlayerGui:FindFirstChild("BackpackGui")
        if hotbar and hotbar:FindFirstChild("Backpack") and hotbar.Backpack:FindFirstChild("Hotbar") then
            for _, slot in pairs(hotbar.Backpack.Hotbar:GetChildren()) do
                if slotKeys[slot.Name] and slot:FindFirstChild("ToolName") then
                    local tName = slot.ToolName.Text or slot.ToolName.Value
                    if type(tName) == "string" and nameEndsWithSeed(tName) and string.find(string.lower(tName), string.lower(seedName)) then
                        VIM:SendKeyEvent(true, slotKeys[slot.Name], false, game)
                        task.wait(0.05)
                        VIM:SendKeyEvent(false, slotKeys[slot.Name], false, game)
                        break
                    end
                end
            end
        end
    end)
end

local InfoSec = Tabs.Info:AddSection("Community Support", true)
InfoSec:AddButton({
    Title = "Discord",
    Content = "click to copy link",
    Icon = "rbxassetid://7733919427",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/vorahub")
            if UI and UI.SetNotification then
                UI:SetNotification({Title = "Discord", Description = "Link copied!", Content = "", Time = 0.3, Delay = 2})
            end
        end
    end
})
InfoSec:AddParagraph({Title = "Update", Content = "Every time there is a game update or someone reports something, I will fix it as soon as possible."})

local PlantSec = Tabs.Main:AddSection("Plant Settings", true)
PlantSec:AddDropdown({
    Title = "Select Plant",
    Content = "",
    Multi = false,
    Options = PlantList,
    Default = {"Carrot"},
    Callback = function(v)
        if type(v) == "table" and v[1] then Config.SelectPlant = v[1]
        elseif type(v) == "string" then Config.SelectPlant = v end
    end
})
PlantSec:AddToggle({Title = "Auto Plant", Content = "", Default = false, Mode = "Toggle", Callback = function(v) Config.AutoPlant = v end})
PlantSec:AddToggle({Title = "Random Position", Content = "", Default = false, Mode = "Toggle", Callback = function(v) Config.RandomPosition = v end})
PlantSec:AddInput({
    Title = "Plant Speed",
    Content = "Delay",
    Default = "0.1",
    Callback = function(v)
        local n = tonumber(v)
        if n and n >= 0 and n <= 10 then Config.PlantSpeed = n end
    end
})

local HarvestSec = Tabs.Main:AddSection("Harvest Settings", true)
HarvestSec:AddToggle({
    Title = "Auto Harvest",
    Content = "Harvest satu per satu (Safe)",
    Default = false,
    Mode = "Toggle",
    Callback = function(v) Config.AutoHarvest = v end
})

local SellSec = Tabs.Main:AddSection("Sell Settings", true)
SellSec:AddToggle({Title = "Auto Sell", Content = "", Default = false, Mode = "Toggle", Callback = function(v) Config.AutoSell = v end})
SellSec:AddInput({
    Title = "Auto Sell Delay",
    Content = "Seconds",
    Default = "2",
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then Config.AutoSellDelay = n end
    end
})

local FavSec = Tabs.Main:AddSection("Favorite Settings", true)
FavSec:AddDropdown({
    Title = "Select Item to Favorite",
    Content = "",
    Multi = false,
    Options = AllItemsList,
    Default = {"Carrot Seed"},
    Callback = function(v)
        if type(v) == "table" and v[1] then Config.AutoFavoriteItem = v[1]
        elseif type(v) == "string" then Config.AutoFavoriteItem = v end
    end
})
FavSec:AddToggle({Title = "Auto Favorite Item", Content = "", Default = false, Mode = "Toggle", Callback = function(v) Config.AutoFavorite = v end})

local SeedShopSec = Tabs.Shop:AddSection("Seed Shop", true)
SeedShopSec:AddDropdown({
    Title = "Select Seed",
    Content = "",
    Multi = false,
    Options = SeedList,
    Default = {"Carrot Seed"},
    Callback = function(v)
        if type(v) == "table" and v[1] then Config.SelectSeed = v[1]
        elseif type(v) == "string" then Config.SelectSeed = v end
    end
})
SeedShopSec:AddDropdown({
    Title = "Select Seeds Multi",
    Content = "",
    Multi = true,
    Options = SeedList,
    Default = {},
    Callback = function(v) Config.SelectSeedMulti = type(v) == "table" and v or {} end
})
SeedShopSec:AddInput({Title = "Amount to Buy", Content = "", Default = "1", Callback = function(v) local n = tonumber(v) if n then Config.SelectSeedAmount = n end end})
SeedShopSec:AddInput({Title = "Per Buy Delay", Content = "Seconds", Default = "0.1", Callback = function(v) local n = tonumber(v) if n and n >= 0 then Config.SeedPerBuyDelay = n end end})
SeedShopSec:AddButton({
    Title = "Buy Seed Now",
    Content = "",
    Icon = "",
    Callback = function()
        task.spawn(function()
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            hrp.CFrame = SeedShopCFrame
            task.wait(0.3)
            for i = 1, Config.SelectSeedAmount do
                ReplicatedStorage.RemoteEvents.PurchaseShopItem:InvokeServer("SeedShop", Config.SelectSeed)
                if Config.SeedPerBuyDelay and Config.SeedPerBuyDelay > 0 then task.wait(Config.SeedPerBuyDelay) end
            end
            task.wait(1)
            local spawnCf = GetSpawnPlotCFrame()
            if spawnCf then hrp.CFrame = spawnCf end
        end)
    end
})
SeedShopSec:AddToggle({Title = "Auto Buy Seed (Sampai Habis)", Content = "", Default = false, Mode = "Toggle", Callback = function(v) Config.AutoBuySeedHabis = v end})
SeedShopSec:AddToggle({Title = "Auto Buy Seed (With Amount)", Content = "", Default = false, Mode = "Toggle", Callback = function(v) Config.AutoBuySeedAmount = v end})

local GearShopSec = Tabs.Shop:AddSection("Gear Shop", true)
GearShopSec:AddDropdown({
    Title = "Select Gear",
    Content = "",
    Multi = false,
    Options = GearList,
    Default = {"Watering Can"},
    Callback = function(v)
        if type(v) == "table" and v[1] then Config.SelectGear = v[1]
        elseif type(v) == "string" then Config.SelectGear = v end
    end
})
GearShopSec:AddInput({Title = "Amount to Buy", Content = "", Default = "1", Callback = function(v) local n = tonumber(v) if n then Config.SelectGearAmount = n end end})
GearShopSec:AddInput({Title = "Per Buy Delay", Content = "Seconds", Default = "0.1", Callback = function(v) local n = tonumber(v) if n and n >= 0 then Config.GearPerBuyDelay = n end end})
GearShopSec:AddInput({Title = "Auto Buy Gear Delay", Content = "Seconds", Default = "2", Callback = function(v) local n = tonumber(v) if n and n > 0 then Config.AutoBuyGearDelay = n end end})
GearShopSec:AddButton({
    Title = "Buy Gear Now",
    Content = "",
    Icon = "",
    Callback = function()
        task.spawn(function()
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            hrp.CFrame = GearShopCFrame
            task.wait(0.3)
            for i = 1, Config.SelectGearAmount do
                ReplicatedStorage.RemoteEvents.PurchaseShopItem:InvokeServer("GearShop", Config.SelectGear)
                if Config.GearPerBuyDelay and Config.GearPerBuyDelay > 0 then task.wait(Config.GearPerBuyDelay) end
            end
            task.wait(1)
            local spawnCf = GetSpawnPlotCFrame()
            if spawnCf then hrp.CFrame = spawnCf end
        end)
    end
})
GearShopSec:AddToggle({Title = "Auto Buy Gear (Sampai Habis)", Content = "", Default = false, Mode = "Toggle", Callback = function(v) Config.AutoBuyGearHabis = v end})
GearShopSec:AddToggle({Title = "Auto Buy Gear (With Amount)", Content = "", Default = false, Mode = "Toggle", Callback = function(v) Config.AutoBuyGearAmount = v end})

local SettingsSec = Tabs.Settings:AddSection("Player Settings", true)
SettingsSec:AddSlider({
    Title = "WalkSpeed",
    Content = "",
    Increment = 1,
    Min = 16,
    Max = 500,
    Default = 16,
    Callback = function(v)
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.WalkSpeed = v
        end
    end
})
SettingsSec:AddSlider({
    Title = "JumpPower",
    Content = "",
    Increment = 1,
    Min = 50,
    Max = 500,
    Default = 50,
    Callback = function(v)
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.UseJumpPower = true
            Player.Character.Humanoid.JumpPower = v
        end
    end
})
Tabs.Settings:AddSection("Miscellaneous", true):AddToggle({
    Title = "Anti AFK",
    Content = "",
    Default = false,
    Mode = "Toggle",
    Callback = function(v) Config.AntiAFK = v end
})

task.spawn(function()
    while task.wait(math.max(0.01, Config.PlantSpeed)) do
        if Config.AutoPlant then
            pcall(function()
                local myPlot = GetMyPlot()
                if myPlot and myPlot:FindFirstChild("PlantableArea") then
                    local plantArea = myPlot.PlantableArea
                    local plantParts = {}
                    local p1, p2 = plantArea:FindFirstChild("Part1"), plantArea:FindFirstChild("Part2")
                    if p1 and p1:IsA("BasePart") then table.insert(plantParts, p1) end
                    if p2 and p2:IsA("BasePart") then table.insert(plantParts, p2) end
                    if #plantParts == 0 then
                        for _, obj in pairs(plantArea:GetDescendants()) do
                            if obj:IsA("BasePart") then table.insert(plantParts, obj) end
                        end
                        table.sort(plantParts, function(a, b)
                            local pa, pb = a.Position, b.Position
                            if math.abs(pa.X - pb.X) > 0.01 then return pa.X < pb.X end
                            if math.abs(pa.Y - pb.Y) > 0.01 then return pa.Y < pb.Y end
                            return pa.Z < pb.Z
                        end)
                        if plantParts[1] then plantParts[1].Name = "Part1" end
                        if plantParts[2] then plantParts[2].Name = "Part2" end
                    end
                    if #plantParts > 0 then
                        local char = Player.Character
                        local equippedTool = char and char:FindFirstChildOfClass("Tool")
                        local isEquipped = equippedTool and nameEndsWithSeed(equippedTool.Name) and string.find(string.lower(equippedTool.Name), string.lower(Config.SelectPlant))
                        if not isEquipped then
                            EquipSeedFromHotbar(Config.SelectPlant)
                            task.wait(0.1)
                        end
                        local targetPart = plantParts[math.random(1, #plantParts)]
                        local sizeX, sizeZ = targetPart.Size.X, targetPart.Size.Z
                        local randomOffsetX = math.random() * sizeX - (sizeX / 2)
                        local randomOffsetZ = math.random() * sizeZ - (sizeZ / 2)
                        local finalCFrame = targetPart.CFrame * CFrame.new(randomOffsetX, targetPart.Size.Y / 2, randomOffsetZ)
                        local plantPos = finalCFrame.Position
                        if not Config.RandomPosition then
                            plantPos = (targetPart.CFrame * CFrame.new(0, targetPart.Size.Y / 2, 0)).Position
                        end
                        ReplicatedStorage.RemoteEvents.PlantSeed:InvokeServer(Config.SelectPlant, plantPos)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    local harvestIndex = 0
    while task.wait(0.2) do
        if Config.AutoHarvest then
            pcall(function()
                local clientPlants = workspace:FindFirstChild("ClientPlants")
                if not clientPlants then return end
                local children = clientPlants:GetChildren()
                if #children == 0 then return end
                harvestIndex = (harvestIndex % #children) + 1
                local child = children[harvestIndex]
                if not child then return end
                local hb = child:FindFirstChild("HarvestBoundingPart", true)
                local prompt = hb and hb:FindFirstChild("HarvestPrompt", true)
                if not prompt then
                    for _, desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") and desc.Name == "HarvestPrompt" then
                            prompt = desc
                            break
                        end
                    end
                end
                if prompt and prompt:IsA("ProximityPrompt") then
                    fireproximityprompt(prompt)
                else
                    local evFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
                    local harvestEvent = evFolder and evFolder:FindFirstChild("HarvestFruit")
                    if harvestEvent then
                        local uuid = getUuidFromModel(child)
                        if not uuid then
                            for _, sub in ipairs(child:GetChildren()) do
                                uuid = getUuidFromModel(sub)
                                if uuid then break end
                            end
                        end
                        if uuid then harvestEvent:FireServer({{Uuid = uuid}}) end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(Config.AutoSellDelay) do
        if Config.AutoSell then
            pcall(function()
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                hrp.CFrame = SellCFrame
                task.wait(0.3)
                ReplicatedStorage.RemoteEvents.SellItems:InvokeServer("SellAll")
                task.wait(1)
                local spawnCf = GetSpawnPlotCFrame()
                if spawnCf then hrp.CFrame = spawnCf end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if Config.AutoBuySeedHabis or Config.AutoBuySeedAmount then
            pcall(function()
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                hrp.CFrame = SeedShopCFrame
                task.wait(0.3)
                if Config.AutoBuySeedHabis then
                    local seeds = Config.SelectSeedMulti
                    if type(seeds) ~= "table" or #seeds == 0 then seeds = {Config.SelectSeed} end
                    for _, seedName in ipairs(seeds) do
                        ReplicatedStorage.RemoteEvents.PurchaseShopItem:InvokeServer("SeedShop", seedName)
                    end
                end
                if Config.AutoBuySeedAmount then
                    local seeds = Config.SelectSeedMulti
                    if type(seeds) ~= "table" or #seeds == 0 then seeds = {Config.SelectSeed} end
                    for _, seedName in ipairs(seeds) do
                        for i = 1, Config.SelectSeedAmount do
                            ReplicatedStorage.RemoteEvents.PurchaseShopItem:InvokeServer("SeedShop", seedName)
                        end
                    end
                end
                task.wait(1)
                local spawnCf = GetSpawnPlotCFrame()
                if spawnCf then hrp.CFrame = spawnCf end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(Config.AutoBuyGearDelay) do
        if Config.AutoBuyGearHabis or Config.AutoBuyGearAmount then
            pcall(function()
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                hrp.CFrame = GearShopCFrame
                task.wait(0.3)
                if Config.AutoBuyGearHabis then
                    ReplicatedStorage.RemoteEvents.PurchaseShopItem:InvokeServer("GearShop", Config.SelectGear)
                end
                if Config.AutoBuyGearAmount then
                    for i = 1, Config.SelectGearAmount do
                        ReplicatedStorage.RemoteEvents.PurchaseShopItem:InvokeServer("GearShop", Config.SelectGear)
                    end
                end
                task.wait(1)
                local spawnCf = GetSpawnPlotCFrame()
                if spawnCf then hrp.CFrame = spawnCf end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(3) do
        if Config.AutoFavorite then
            pcall(function()
                local favItem = Player.Backpack:FindFirstChild(Config.AutoFavoriteItem)
                if favItem then ReplicatedStorage.RemoteEvents.ToggleFavorite:FireServer(favItem) end
            end)
        end
    end
end)

Player.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

pcall(function()
    if UI and UI.SetNotification then
        UI:SetNotification({
            Title = "Nateira Hub",
            Description = "Ready",
            Content = "Garden Horizon loaded",
            Time = 0.4,
            Delay = 3
        })
    end
end)
