local success, Chloex = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/nyzxhub-rblx/NyzXUi/refs/heads/main/UI/MainUi.lua"))()
end)

-- [[ load Window ]]
local Window = Chloex:Window({
    Title   = "NateiraHub | Premium | ",                --- title
    Footer  = "V0.0.0.3",                   --- in right after title
    Image   = "84946340265305",           ---- rbxassetid (texture)
    Color   = Color3.fromRGB(255, 255, 255), --- colour text/ui
    Theme   = 84946340265305,                  ---- background for theme ui (rbxassetid)
    Version = 1,                           --- version config set as default 1 if u remake / rewrite / big update and change name name in your hub change it to 2 and config will reset
})

--- [[ Notify ]]
if Window then
    Nt("Window loaded!")
end

-- [[ Config Folder ]]
local ConfigFolder = "NateiraHub/Abyss"
if not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

local function GetFishNames()
    local fishFolder = game:GetService("ReplicatedStorage"):FindFirstChild("common")
    if not fishFolder then return {} end
    
    local assetsFolder = fishFolder:FindFirstChild("assets")
    if not assetsFolder then return {} end
    
    local fishFolder2 = assetsFolder:FindFirstChild("fish")
    if not fishFolder2 then return {} end
    
    local fishNames = {}
    for _, fish in pairs(fishFolder2:GetChildren()) do
        table.insert(fishNames, fish.Name)
    end
    table.sort(fishNames)
    return fishNames
end


local Tabs = {
    Info = Window:AddTab({ Name = "Info", Icon = "player" }),
    Player = Window:AddTab({ Name = "Player", Icon = "user" }), 
    Main = Window:AddTab({ Name = "Main", Icon = "gamepad" }),
    Exclusive = Window:AddTab({ Name = "Exclusive", Icon = "Nt" }),
    Teleport = Window:AddTab({ Name = "Teleport", Icon = "compas" }),
}

v1 = Tabs.Info:AddSection("Discord", true)

v1:AddParagraph({
    Title = "Join Our Discord",
    Content = "Join Us!",
    Icon = "discord",
    ButtonText = "Copy Discord Link",
    ButtonCallback = function()
        local link = "https://discord.gg/lexshub"
        if setclipboard then
            setclipboard(link)
            Nt("Successfully Copied!")
        end
    end
})

x1 = Tabs.Player:AddSection("Player")

local P = game:GetService("Players").LocalPlayer

local HN = "Natieira Protection"
local HL = "Lv. ???"

local S = {on = false, ui = nil}

local function setup(char)
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    local attach = hrp:WaitForChild("OverheadAttachment", 5)
    if not attach then return end

    local overhead = attach:WaitForChild("playerOverhead", 5)
    if not overhead then return end

    local header, level

    for _, v in ipairs(overhead:GetDescendants()) do
        if v:IsA("TextLabel") then
            if not header then
                header = v
            elseif not level then
                level = v
            end
        end
    end

    if not header or not level then return end

    return {
        h = header,
        l = level,
        dh = header.Text,
        dl = level.Text
    }
end

S.ui = setup(P.Character or P.CharacterAdded:Wait())

-- Re-setup kalau respawn
P.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    S.ui = setup(char)

    if S.on and S.ui then
        S.ui.h.Text = HN
        S.ui.l.Text = HL
    end
end)

x1:AddToggle({
    Title = "Hide Name & Level",
    Default = false,
    Callback = function(v)
        S.on = v
        if not S.ui then return end

        if v then
            S.ui.h.Text = HN
            S.ui.l.Text = HL
        else
            S.ui.h.Text = S.ui.dh
            S.ui.l.Text = S.ui.dl
        end
    end
})


x2 = Tabs.Main:AddSection("Main")


local fishNames = GetFishNames()
if #fishNames == 0 then
    table.insert(fishNames, "No fish found")
end

local selectedFishList = {fishNames[1] or "No fish found"}
local mappedFishUUIDs = {}
local autoFishEnabled = false
local tweenSpeed = 1
local catchCount = 2

local autoSellEnabled = false
local sellWeight = 25 

local autoOxygenEnabled = false
local savedOxygenPosition = nil

local fishDropdown = x2:AddDropdown({
    Title = "Select Fish",
    Content = "Choose fish to auto fish",
    Options = fishNames,
    CurrentOption = selectedFishList,
    Multi = true,
    Callback = function(options)
        selectedFishList = options
    end
})

local function FindFishUUID(fishName, ignoredTable)
    if not fishName or fishName == "" then
        return nil
    end
    
    local fishClient = workspace:FindFirstChild("Game")
    if not fishClient then return nil end
    
    fishClient = fishClient:FindFirstChild("Fish")
    if not fishClient then return nil end
    
    fishClient = fishClient:FindFirstChild("client")
    if not fishClient then return nil end
    
    local debugLog = "Searching for: '" .. fishName .. "'\n"
    local foundMatches = {}
    
    for _, uuidFolder in pairs(fishClient:GetChildren()) do
        local head = uuidFolder:FindFirstChild("Head")
        if head then
            local stats = head:FindFirstChild("stats")
            if stats then
                local fish = stats:FindFirstChild("Fish")
                if fish then
                    local fishValue = ""
                    
                    if fish:IsA("TextLabel") then
                        fishValue = fish.Text
                    elseif fish:IsA("StringValue") then
                        fishValue = fish.Value
                    elseif fish:IsA("ObjectValue") then
                        local obj = fish.Value
                        if obj then
                            fishValue = obj.Name
                        end
                    end
                    
                    debugLog = debugLog .. "  UUID: " .. uuidFolder.Name .. " = '" .. fishValue .. "' (Type: " .. fish.ClassName .. ")\n"
                    
                    if fishValue == fishName then
                         if not ignoredTable or not ignoredTable[uuidFolder.Name] then
                            table.insert(foundMatches, uuidFolder.Name)
                         end
                    end
                end
            end
        end
    end
    
    pcall(function()
        writefile(ConfigFolder .. "/find_uuid_debug.txt", debugLog .. "\nMatches found: " .. #foundMatches)
    end)
    
    if #foundMatches > 0 then
        return foundMatches[1]
    end
    return nil
end

local function GetClosestFishPosition(selectedFishArray, ignoredTable)
    local player = game.Players.LocalPlayer
    if not player or not player.Character then return nil end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local playerPosition = humanoidRootPart.Position
    local closestFish = nil
    local closestDistance = math.huge
    
    if type(selectedFishArray) == "string" then
        selectedFishArray = {selectedFishArray}
    end
    
    for _, fishName in ipairs(selectedFishArray) do
        local uuid = FindFishUUID(fishName, ignoredTable)
        if uuid then
            local fishFolder = workspace:FindFirstChild("Game")
            if fishFolder then
                fishFolder = fishFolder:FindFirstChild("Fish")
                if fishFolder then
                    fishFolder = fishFolder:FindFirstChild("client")
                    if fishFolder then
                        local fishUUIDFolder = fishFolder:FindFirstChild(uuid)
                        if fishUUIDFolder then
                            local fishPosition
                            local head = fishUUIDFolder:FindFirstChild("Head")
                            if head then
                                fishPosition = head.Position
                            else
                                fishPosition = fishUUIDFolder.Position
                            end
                            
                            local distance = (playerPosition - fishPosition).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestFish = {
                                    uuid = uuid,
                                    position = fishPosition
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestFish
end

local function CatchFish(uuid)
    local fishFolder = workspace:FindFirstChild("Game")
    if not fishFolder then return end
    
    fishFolder = fishFolder:FindFirstChild("Fish")
    if not fishFolder then return end
    
    fishFolder = fishFolder:FindFirstChild("client")
    if not fishFolder then return end
    
    local fishInstance = fishFolder:FindFirstChild(uuid)
    if fishInstance then
        fishInstance:SetAttribute("Speed", 99999)
    end

    local HarpoonService = game:GetService("ReplicatedStorage").common.packages.Knit.Services.HarpoonService
    if HarpoonService then
        local RF = HarpoonService:FindFirstChild("RF")
        if RF then
            local StartCatching = RF:FindFirstChild("StartCatching")
            if StartCatching then
                for i = 1, catchCount do
                    pcall(function()
                        StartCatching:InvokeServer(uuid)
                    end)
                    task.wait(0.2)
                end
            end
        end
    end
end

local function CompleteProgress()
    local MinigameService = game:GetService("ReplicatedStorage").common.packages.Knit.Services.MinigameService
    if MinigameService then
        local RF = MinigameService:FindFirstChild("RF")
        if RF then
            local Update = RF:FindFirstChild("Update")
            if Update then
                pcall(function()
                    Update:InvokeServer(
                        "ProgressUpdate",
                        {
                            progress = 1,
                            rewards = {}
                        }
                    )
                end)
            end
        end
    end
end

local oxygenThreshold = 10
local safeZonePosition = Vector3.new(1, 4883, 73)

local function GetOxygenLevel()
    local gui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        local main = gui:FindFirstChild("Main")
        if main then
            local oxygenFrame = main:FindFirstChild("Oxygen")
            if oxygenFrame then
                local canvas = oxygenFrame:FindFirstChild("CanvasGroup")
                if canvas then
                    local textStats = canvas:FindFirstChild("Oxygen")
                    if textStats then
                         return tonumber(textStats.Text) or 100
                    end
                end
            end
        end
    end
    return 100
end

local moveSpeed = 500 

local function SafeTween(object, targetCFrame, speedParam)
    if not object or not targetCFrame then return end
    
    local speed = speedParam or moveSpeed
    local startPos = object.Position
    local targetPos = targetCFrame.Position
    local distance = (targetPos - startPos).Magnitude
    
    local TweenService = game:GetService("TweenService")
    local segmentDistance = 50
    if distance > segmentDistance then
        -- Calculate segments
        local direction = (targetPos - startPos).Unit
        local segments = math.ceil(distance / segmentDistance)
        
        for i = 1, segments do
            local currentTarget
            if i == segments then
                currentTarget = targetCFrame
            else
                currentTarget = CFrame.new(startPos + (direction * (segmentDistance * i)))
            end
            
            local segmentDist = (object.Position - currentTarget.Position).Magnitude
            local time = segmentDist / speed
            
            local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(object, ti, {CFrame = currentTarget})
            tween:Play()
            tween.Completed:Wait()
            
            if i < segments then
                task.wait(0.01) 
            end
        end
    else
        -- Short distance, direct tween
        local time = distance / speed
        local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(object, ti, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
    end
end

local function RefillOxygen()
    local player = game.Players.LocalPlayer
    if not player or not player.Character then return end
    
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local startPos = root.Position
    
    Nt("Oxygen Low - Refilling oxygen...")
    
    -- Tween to Safe Zone
    SafeTween(root, CFrame.new(safeZonePosition), moveSpeed)
    
    task.wait(2) -- Wait for refill
    
    -- Tween Back
    SafeTween(root, CFrame.new(startPos), moveSpeed)
end

local fishEverythingEnabled = false

local function GetClosestAnyFishPosition(ignoredTable)
    local player = game.Players.LocalPlayer
    if not player or not player.Character then return nil end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local fishFolder = workspace:FindFirstChild("Game")
    if fishFolder then
        fishFolder = fishFolder:FindFirstChild("Fish")
        if fishFolder then
            fishFolder = fishFolder:FindFirstChild("client")
            if fishFolder then
                local playerPosition = humanoidRootPart.Position
                local closestFish = nil
                local closestDistance = math.huge
                local fishCount = 0
                
                for _, fishUUIDFolder in pairs(fishFolder:GetChildren()) do
                    if not ignoredTable or not ignoredTable[fishUUIDFolder.Name] then
                        local fishPosition
                        local head = fishUUIDFolder:FindFirstChild("Head")
                        if head then
                            fishPosition = head.Position
                        else
                            -- Fallback logic
                            if fishUUIDFolder:IsA("BasePart") then
                                fishPosition = fishUUIDFolder.Position
                            elseif fishUUIDFolder:IsA("Model") then
                                fishPosition = fishUUIDFolder:GetPivot().Position
                            end
                        end
                        
                        if fishPosition then
                            fishCount = fishCount + 1
                            local distance = (playerPosition - fishPosition).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestFish = {
                                    uuid = fishUUIDFolder.Name,
                                    position = fishPosition
                                }
                            end
                        end
                    end
                end
                
                if not closestFish and fishCount == 0 then
                    -- print("No fish found in client folder")
                end
                return closestFish
            end
        end
    end
    return nil
end

local function AutoFishingLoop()
    local ignoredFish = {}
    local currentFishUUID = nil
    local fishStuckTime = 0

    while autoFishEnabled do
        local shouldFish = false
        if fishEverythingEnabled then
            shouldFish = true
        elseif fishDropdown and fishDropdown.Value and type(fishDropdown.Value) == "table" and #fishDropdown.Value > 0 then
            local hasValidFish = false
            for _, fishName in ipairs(fishDropdown.Value) do
                if fishName ~= "No fish found" then
                    hasValidFish = true
                    break
                end
            end
            shouldFish = hasValidFish
        end
        
        if not shouldFish then
            task.wait(0.1)
        else
            -- Check Oxygen First
            local oxygen = GetOxygenLevel()
            if oxygen <= oxygenThreshold then
                RefillOxygen()
            end

            local closestFish = nil
            
            if fishEverythingEnabled then
                closestFish = GetClosestAnyFishPosition(ignoredFish)
            else
                local selectedFishArray = fishDropdown.Value
                if type(selectedFishArray) == "string" then
                    selectedFishArray = {selectedFishArray}
                end
                if selectedFishArray and #selectedFishArray > 0 then
                    closestFish = GetClosestFishPosition(selectedFishArray, ignoredFish)
                end
            end
                
            if closestFish then
                if currentFishUUID == closestFish.uuid then
                    if tick() - fishStuckTime > 8 then
                        ignoredFish[closestFish.uuid] = true
                        currentFishUUID = nil
                        fishStuckTime = 0
                        -- Try finding next fish immediately
                        if fishEverythingEnabled then
                            closestFish = GetClosestAnyFishPosition(ignoredFish)
                        else
                            local selectedFishArray = fishDropdown.Value
                            if type(selectedFishArray) == "string" then
                                selectedFishArray = {selectedFishArray}
                            end
                            closestFish = GetClosestFishPosition(selectedFishArray, ignoredFish)
                        end
                    end
                else
                    currentFishUUID = closestFish.uuid
                    fishStuckTime = tick()
                end
            else
                currentFishUUID = nil
                fishStuckTime = 0
            end
            
            if closestFish then
                local player = game.Players.LocalPlayer
                if player and player.Character then
                    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        
                        local offsetPosition = closestFish.position + Vector3.new(0, 2, 0)
                        SafeTween(humanoidRootPart, CFrame.new(offsetPosition), moveSpeed)

                            task.wait(0.15)
                        CatchFish(closestFish.uuid)
                        task.wait(0.55)
                        CompleteProgress()
                    end
                end
            else
                -- If no fish found, return to Safe Zone
                local player = game.Players.LocalPlayer
                if player and player.Character then
                    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        SafeTween(humanoidRootPart, CFrame.new(safeZonePosition), moveSpeed)
                    end
                end
            end

            task.wait(0.8)
        end
    end
end

x2:AddButton({
    Title = "Refresh Fish List",
    Content = "Refresh the fish dropdown",
    Callback = function()
        local updatedFishNames = GetFishNames()
        fishDropdown:Refresh(updatedFishNames)
    end
})


x2:AddInput({
    Title = "Oxygen Threshold",
    Content = "Refill oxygen below this value",
    Value = "10",
    Placeholder = "10",
    Callback = function(text)
        local val = tonumber(text)
        if val then
            oxygenThreshold = val
        end
    end
})



local autoClaimEnabled = false
local function AutoClaimLoop()
    while autoClaimEnabled do
        pcall(function()
            local player = game.Players.LocalPlayer
            if player and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local closest = nil
                    local minDst = 15
                    
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.Enabled then
                            local pos
                            if v.Parent:IsA("BasePart") then
                                pos = v.Parent.Position
                            elseif v.Parent:IsA("Model") then
                                pos = v.Parent:GetPivot().Position
                            elseif v.Parent:IsA("Attachment") then
                                pos = v.Parent.WorldPosition
                            end
                            
                            if pos then
                                local dst = (root.Position - pos).Magnitude
                                if dst < minDst then
                                    minDst = dst
                                    closest = v
                                end
                            end
                        end
                    end
                    
                    if closest then
                        fireproximityprompt(closest)
                    end
                end
            end
        end)
        task.wait(0.1)
    end
end

x2:AddToggle({
    Title = "Auto Claim Fish",
    Value = false,
    Callback = function(state)
        autoClaimEnabled = state
        if state then
            task.spawn(AutoClaimLoop)
        end
    end
})


x2:AddToggle({
    Title = "Auto Fish Instant",
    Content = "Enable auto fishing loop",
    Value = false,
    Callback = function(state)
        autoFishEnabled = state
        if state then
            task.spawn(AutoFishingLoop)
        else
        end
    end
})

x2:AddToggle({
    Title = "Fish Everything",
    Content = "Target any fish (ignores selection)",
    Value = false,
    Callback = function(state)
        fishEverythingEnabled = state
        if state and not autoFishEnabled then
            Nt("Enable 'Auto Fish Instant' to start fishing")
        end
    end
})

x2:AddDivider()

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local player = Players.LocalPlayer

    local EquipRemote = ReplicatedStorage
        :WaitForChild("common")
        :WaitForChild("packages")
        :WaitForChild("Knit")
        :WaitForChild("Services")
        :WaitForChild("BackpackService")
        :WaitForChild("RF")
        :WaitForChild("Equip")

    local SLOT = "1"
    local AutoEquip = false
    local loopThread

    local function equip()
        pcall(function()
            EquipRemote:InvokeServer(SLOT)
        end)
    end

    local function start()
        if loopThread then return end
        AutoEquip = true

        loopThread = task.spawn(function()
            while AutoEquip do
                task.wait(0.3)

                local char = player.Character
                if char then
                    local hasTool = false

                    for _, v in ipairs(char:GetChildren()) do
                        if v:IsA("Tool") then
                            hasTool = true
                            break
                        end
                    end

                    if not hasTool then
                        equip()
                    end
                end
            end
        end)
    end

    local function stop()
        AutoEquip = false
        if loopThread then
            task.cancel(loopThread)
            loopThread = nil
        end
    end

    x2:AddToggle({
        Title = "Auto Equip Gun",
        Default = false,
        Callback = function(state)
            if state then
                start()
            else
                stop()
            end
        end
    })
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local RespawnRemote = ReplicatedStorage
    :WaitForChild("common")
    :WaitForChild("packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("MovementService")
    :WaitForChild("RF")
    :WaitForChild("Respawn")

local AutoRespawn = false
local deathConnection

local function hookCharacter(char)
    local hum = char:WaitForChild("Humanoid")

    if deathConnection then
        deathConnection:Disconnect()
        deathConnection = nil
    end

    deathConnection = hum.Died:Connect(function()
        if not AutoRespawn then return end
        
        task.wait(0.5)

        pcall(function()
            RespawnRemote:InvokeServer("free")
        end)
    end)
end

-- first load
if Player.Character then
    hookCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(char)
    hookCharacter(char)
end)

x2:AddToggle({
    Title = "Auto Respawn",
    Default = false,
    Callback = function(v)
        AutoRespawn = v
    end
})

--//
x3 = Tabs.Main:AddSection("Sell")


local function GetWeight()
    local gui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        local main = gui:FindFirstChild("Main")
        if main then
            local rightStats = main:WaitForChild("Oxygen", 1):WaitForChild("RightStats", 1)
            if rightStats then
                local frame = rightStats:WaitForChild("Frame", 1)
                if frame then
                    local weight = frame:WaitForChild("Weight", 1)
                    if weight then
                        local wght = weight:FindFirstChild("Wght")
                        if wght then
                            -- Assuming format like "10/50" or just "10"
                            local text = wght.Text
                            local currentWeight = text:match("^(%d+)")
                            return tonumber(currentWeight) or 0
                        end
                    end
                end
            end
        end
    end
    return 0
end


local autoSellEnabled = false
local sellWeight = 25 -- Default sell at 25kg
local SafeSell = Vector3.new(1, 4883, 73)
local function AutoSellLoop()
    while autoSellEnabled do
        pcall(function()
            local currentWeight = GetWeight()
            
            
            if currentWeight >= sellWeight then
                local player = game.Players.LocalPlayer
                if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    SafeTween(game.Players.LocalPlayer.Character.HumanoidRootPart, CFrame.new(SafeSell), 500)
                end
                task.wait(0.5)
                local SellService = game:GetService("ReplicatedStorage").common.packages.Knit.Services.SellService
                if SellService then
                    local RF = SellService:FindFirstChild("RF")
                    if RF then
                        local SellInventory = RF:FindFirstChild("SellInventory")
                        if SellInventory then
                            for i = 1, 5 do
                                SellInventory:InvokeServer()
                            end
                        end
                    end
                end
                
                task.wait(1)
            end
        end)
        task.wait(1) 
    end
end

x3:AddInput({
    Title = "Sell Weight",
    Content = "Sell when weight reaches (kg)",
    Value = "25",
    Placeholder = "25",
    Callback = function(text)
        local val = tonumber(text)
        if val then
            sellWeight = val
            Nt("Sell threshold set to: " .. val .. "kg")
        end
    end
})

x3:AddToggle({
    Title = "Auto Sell",
    Content = "Enable auto sell loop (Weight Based)",
    Value = false,
    Callback = function(state)
        autoSellEnabled = state
        if state then
            Nt("Auto Sell Started - Selling at " .. sellWeight .. "kg")
            task.spawn(AutoSellLoop)
        else
            Nt("Auto Sell Stopped")
        end
    end
})

x3 = Tabs.Exclusive:AddSection("Exclusive")

x3:AddParagraph({
    Title = "Gun/Tube Op?????",
    Content = "PATCHED",
    Icon = "question",
})

x4 = Tabs.Teleport:AddSection("Teleport")

local PS = game:GetService("Players")
local LP = PS.LocalPlayer
local selectedPlayer = ""

local function getPlayerList()
    local players = {}
    for _, player in pairs(PS:GetPlayers()) do
        if player ~= LP then
            table.insert(players, player.Name)
        end
    end
    return players
end

local playerDropdown = x4:AddDropdown({
    Title = "Select Player",
    Content = "Choose player to teleport to",
    Options = getPlayerList(),
    CurrentOption = {},
    Multi = false,
    Callback = function(value)
        if value and value ~= "" then
            if type(value) == "table" then
                selectedPlayer = value[1] or ""
            else
                selectedPlayer = value
            end
        end
    end
})

x4:AddButton({
    Title = "Refresh Player List",
    Content = "Update player list",
    Callback = function()
        local players = getPlayerList()
        if playerDropdown and playerDropdown.Refresh then
            playerDropdown:Refresh(players)
        end
        Nt("Player list refreshed")
    end
})

x4:AddButton({
    Title = "Teleport to Player",
    Content = "Teleport to selected player",
    Callback = function()
        if selectedPlayer ~= "" then
            local targetPlayer = PS:FindFirstChild(selectedPlayer)
            if targetPlayer then
                local targetChar = targetPlayer.Character
                local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                local localChar = LP.Character
                local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
                
                if targetHRP and localHRP then
                    localHRP.CFrame = targetHRP.CFrame
                    Nt("Teleported to " .. selectedPlayer)
                else
                    Nt("Error: Cannot teleport to player")
                end
            else
                Nt("Error: Player not found")
            end
        else
            Nt("Error: Please select a player first")
        end
    end
})

task.spawn(function()
    task.wait(2)
    local players = getPlayerList()
    if playerDropdown and playerDropdown.Refresh then
        playerDropdown:Refresh(players)
    end
end)


    

local IslandList = {
    ["Ancient Sands"] = Vector3.new(-1785, 4708, 89),
    ["Spirit Roots"] = Vector3.new(1624, 4032, -1882),
    ["Forgotten Deep"] = Vector3.new(1, 4883, 73)
}

local selectedIsland = "Ancient Sands"

local islandDropdown = x4:AddDropdown({
    Title = "Select Island",
    Content = "Choose island to teleport to",
    Options = {"Ancient Sands", "Spirit Roots", "Forgotten Deep"},
    CurrentOption = {selectedIsland},
    Multi = false,
    Callback = function(val)
        if type(val) == "table" then
            selectedIsland = val[1] or "Ancient Sands"
        else
            selectedIsland = val
        end
    end
})

x4:AddButton({
    Title = "Teleport to Island",
    Content = "Tween to selected island",
    Callback = function()
        if selectedIsland and IslandList[selectedIsland] then
            local player = game.Players.LocalPlayer
            if player and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    Nt("Teleporting to " .. selectedIsland)
                    SafeTween(root, CFrame.new(IslandList[selectedIsland]), moveSpeed)
                end
            end
        end
    end
})


do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local SetAfkRemote = ReplicatedStorage
        :WaitForChild("common")
        :WaitForChild("packages")
        :WaitForChild("Knit")
        :WaitForChild("Services")
        :WaitForChild("CharacterService")
        :WaitForChild("RF")
        :WaitForChild("SetAfk")

    task.spawn(function()
        while true do
            pcall(function()
                SetAfkRemote:InvokeServer(false)
            end)
            task.wait(0.5)
        end
    end)
end

   
local VIM = game:GetService("VirtualInputManager")
task.spawn(function()
    while true do
        task.wait(math.random(600, 700))
        local k = {
            {Enum.KeyCode.LeftShift, Enum.KeyCode.E},
            {Enum.KeyCode.LeftControl, Enum.KeyCode.F},
            {Enum.KeyCode.LeftShift, Enum.KeyCode.Q},
            {Enum.KeyCode.E, Enum.KeyCode.F}
        }
        local c = k[math.random(#k)]
        pcall(function()
            for _, x in pairs(c) do
                VIM:SendKeyEvent(true, x, false, nil)
            end
            task.wait(.1)
            for _, x in pairs(c) do
                VIM:SendKeyEvent(false, x, false, nil)
            end
        end)
    end
end)

if Window then
    Nt("Thank For Using NateiraHub Premium!")
end
