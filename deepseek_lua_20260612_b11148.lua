-- ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
--  GUEST 1337 - HUTAO COMBAT SYSTEM (STANDALONE)
--  Pure Hutao auto-block, HDT, aim punch, detection circles, and facing check
-- ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

-- ============================================================================
-- SERVICES
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StatsService = game:GetService("Stats")
local DebrisService = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

-- ============================================================================
-- REMOTE EVENT
-- ============================================================================
local RemoteEvent = ReplicatedStorage:FindFirstChild("Modules")
    and ReplicatedStorage.Modules:FindFirstChild("Network")
    and ReplicatedStorage.Modules.Network:FindFirstChild("Network")
    and ReplicatedStorage.Modules.Network.Network:FindFirstChild("RemoteEvent")

if not RemoteEvent then
    pcall(function()
        RemoteEvent = ReplicatedStorage:WaitForChild("Modules", 10)
            :WaitForChild("Network", 10)
            :WaitForChild("Network", 10)
            :WaitForChild("RemoteEvent", 10)
    end)
end

-- ============================================================================
-- WINDUI
-- ============================================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then error("WindUI failed to load") end

-- Theme
WindUI:AddTheme({
    Name = "HutaoTheme",
    Accent = Color3.fromRGB(232, 25, 75),
    Background = Color3.fromRGB(45, 10, 20),
    Outline = Color3.fromRGB(232, 25, 75),
    Text = Color3.fromRGB(255, 179, 198),
    Toggle = Color3.fromRGB(232, 25, 75),
    ToggleBar = Color3.fromRGB(139, 0, 36),
    Checkbox = Color3.fromRGB(232, 25, 75),
    CheckboxIcon = Color3.fromRGB(255, 179, 198),
    Slider = Color3.fromRGB(232, 25, 75),
    SliderThumb = Color3.fromRGB(255, 179, 198),
    WindowBackground = Color3.fromRGB(26, 6, 16),
})
WindUI:SetTheme("HutaoTheme")

-- Window
local Window = WindUI:CreateWindow({
    Title = "Guest 1337 | Hutao Combat",
    Icon = "shield",
    Author = "Hutao Combat System",
    Folder = "Guest1337",
    Size = UDim2.fromOffset(450, 550),
    Transparent = false,
    Theme = "HutaoTheme",
    Resizable = true,
    SideBarWidth = 160,
    HideSearchBar = true,
    ScrollBarEnabled = true,
})

Window:SetToggleKey(Enum.KeyCode.L)
WindUI:SetFont("rbxasset://fonts/families/AccanthisADFStd.json")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local combatS = {
    autoBlockOn = false,
    blockType = "Block",
    detectionRange = 18,
    blockDelay = 0,
    doubleBlock = true,
    antiBait = false,
    abMissChance = 0,
    autoPunchOn = false,
    hdtEnabled = false,
    hdtMoveSpeed = 26,
    hdtDuration = 1.0,
    hdtMissChance = 0,
    killerCircles = false,
    facingCheck = true,
    facingVisual = false,
    facingVisRadius = 3,
    aimPunchActive = false,
    punchPrediction = 2.3,
    aimPunchDuration = 0.5,
}

-- ============================================================================
-- TRIGGER SOUNDS
-- ============================================================================
local TRIGGER_SOUNDS = {
    ["140242176732868"]=true,["136323728355613"]=true,
    ["115026634746636"]=true,["84116622032112"]=true, ["108907358619313"]=true,["127793641088496"]=true,
    ["86174610237192"]=true, ["95079963655241"]=true, ["101199185291628"]=true,["119942598489800"]=true,
    ["84307400688050"]=true, ["105200830849301"]=true,["75330693422988"]=true,
    ["82221759983649"]=true, ["81702359653578"]=true, ["85853080745515"]=true,
    ["108610718831698"]=true,["112395455254818"]=true,["109431876587852"]=true,["12222216"]=true,
    ["79980897195554"]=true, ["119583605486352"]=true,["71834552297085"]=true, ["116581754553533"]=true,
    ["86833981571073"]=true, ["110372418055226"]=true,["105840448036441"]=true,["86494585504534"]=true,
    ["80516583309685"]=true, ["131406927389838"]=true,["89004992452376"]=true, ["117231507259853"]=true,
    ["101698569375359"]=true,["101553872555606"]=true,["140412278320643"]=true,["106300477136129"]=true,
    ["117173212095661"]=true,["104910828105172"]=true,["140194172008986"]=true,["85544168523099"]=true,
    ["114506382930939"]=true,["99829427721752"]=true, ["120059928759346"]=true,["104625283622511"]=true,
    ["105316545074913"]=true,["126131675979001"]=true,["82336352305186"]=true, ["93366464803829"]=true,
    ["84069821282466"]=true, ["128856426573270"]=true,["121954639447247"]=true,["128195973631079"]=true,
    ["124903763333174"]=true,["94317217837143"]=true, ["98111231282218"]=true, ["119089145505438"]=true,
    ["136728245733659"]=true,["107444859834748"]=true,["76959687420003"]=true,
    ["72425554233832"]=true, ["96594507550917"]=true, ["139996647355899"]=true,["107345261604889"]=true,
    ["127557531826290"]=true,["108651070773439"]=true,["74842815979546"]=true, ["124397369810639"]=true,
    ["76467993976301"]=true, ["118493324723683"]=true,["78298577002481"]=true, ["116527305931161"]=true,
    ["5148302439"]=true,     ["98675142200448"]=true, ["128367348686124"]=true,["71805956520207"]=true,
    ["125213046326879"]=true,["103684883268194"]=true,["109246041199659"]=true,
    ["80540530406270"]=true, ["139523195429581"]=true,["105204810054381"]=true,["114742322778642"]=true,
    ["116468089135195"]=true,["112809109188560"]=true,["109348678063422"]=true,
}

-- ============================================================================
-- BLOCK ANIMATION IDs (for HDT detection)
-- ============================================================================
local BLOCK_ANIMS = {
    ["72722244508749"]=true,["96959123077498"]=true,["95802026624883"]=true,
    ["100926346851492"]=true,["120748030255574"]=true,
    ["127040663332045"]=true,
}

-- ============================================================================
-- PUNCH ANIMATION IDs (for aim punch)
-- ============================================================================
local PUNCH_ANIMS = {
    ["87259391926321"]=true,["140703210927645"]=true,["136007065400978"]=true,["129843313690921"]=true,
    ["86709774283672"]=true, ["108807732150251"]=true,["138040001965654"]=true,["86096387000557"]=true,
    ["81905101227053"]=true, ["127777649118195"]=true,["99100240941590"]=true, ["92831180929659"]=true,
    ["112081768119093"]=true,["117587689359268"]=true,["91830732867282"]=true, ["91730605416216"]=true,
    ["100184164753080"]=true,["133475256598240"]=true,
    ["72007882634344"]=true,
}

-- ============================================================================
-- BAIT KILLERS
-- ============================================================================
local BAIT_KILLERS = {"John Doe","Slasher","c00lkidd","Jason","1x1x1x1","Noli","Sixer","Nosferatu"}
local STRICT_FACING_DOT = 0.70

-- ============================================================================
-- RUNTIME STATE
-- ============================================================================
local soundHooks = {}
local soundBlockedUntil = {}
local lastBlockTime = 0
local BLOCK_CD = 0.1
local circles = {}
local facingVisuals = {}
local hdtDragging = false
local hdtLastTime = 0
local HDT_CD = 0.5
local punchAiming = false
local punchLastTrigger = 0
local originalAutoRot = nil
local originalHRPCFrame = nil
local aimConnection = nil
local soundTickConn = nil
local visualTickConn = nil
local aimActive = false
local cachedAnimator = nil

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
local function getKillersFolder()
    local p = Workspace:FindFirstChild("Players")
    return p and p:FindFirstChild("Killers")
end

local function getNearestKiller()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local kf = getKillersFolder()
    if not kf then return nil end
    local best, bestDist = nil, math.huge
    for _, killer in pairs(kf:GetChildren()) do
        local hrp = killer:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (hrp.Position - myRoot.Position).Magnitude
            if dist < bestDist then best, bestDist = killer, dist end
        end
    end
    return best
end

local function isFacing(myRoot, targetRoot, killerName)
    if not combatS.facingCheck then return true end
    if not myRoot or not targetRoot then return false end
    local diff = myRoot.Position - targetRoot.Position
    if diff.Magnitude < 0.01 then return true end
    local dir = diff.Unit
    local dot = targetRoot.CFrame.LookVector:Dot(dir)
    
    local isBait = false
    if killerName then
        for _, name in ipairs(BAIT_KILLERS) do
            if killerName:find(name) then isBait = true; break end
        end
    end
    
    if isBait then
        local vel = targetRoot.AssemblyLinearVelocity or Vector3.zero
        if vel.Magnitude < 0.01 then pcall(function() vel = targetRoot.Velocity end) end
        local side = math.abs(vel:Dot(targetRoot.CFrame.RightVector))
        if side > 3 then return false end
        return dot > STRICT_FACING_DOT + 0.05
    end
    return dot > STRICT_FACING_DOT
end

local function rollMiss(chance)
    if chance <= 0 then return false end
    if chance >= 100 then return true end
    return math.random(1, 100) <= chance
end

local function fireAbility(abilityType)
    if not RemoteEvent then return end
    local buf
    if abilityType == "Block" then
        buf = buffer.fromstring("\x03\x05\x00\x00\x00Block")
    elseif abilityType == "Punch" then
        buf = buffer.fromstring("\x03\x05\x00\x00\x00Punch")
    elseif abilityType == "Charge" then
        buf = buffer.fromstring("\x03\x06\x00\x00\x00Charge")
    elseif abilityType == "Clone" then
        buf = buffer.fromstring("\x03\x05\x00\x00\x00Clone")
    else
        buf = buffer.fromstring("\x03\x05\x00\x00\x00Block")
    end
    pcall(function() RemoteEvent:FireServer("UseActorAbility", {[1] = buf}) end)
end

local function extractSoundId(sound)
    if not sound then return nil end
    return tostring(sound.SoundId):match("%d+")
end

-- ============================================================================
-- AUTO BLOCK (Audio-based)
-- ============================================================================
local function tryBlockFromSound(sound, preId)
    if not combatS.autoBlockOn then return end
    if not sound or not sound:IsA("Sound") then return end

    local id = preId or extractSoundId(sound)
    if not id or not TRIGGER_SOUNDS[id] then return end

    local now = tick()
    if now - lastBlockTime < BLOCK_CD then return end
    if soundBlockedUntil[sound] and now < soundBlockedUntil[sound] then return end

    local char = LocalPlayer.Character
    if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Resolve killer from sound parent
    local soundPart
    if sound.Parent and sound.Parent:IsA("BasePart") then
        soundPart = sound.Parent
    elseif sound.Parent and sound.Parent:IsA("Attachment") and sound.Parent.Parent and sound.Parent.Parent:IsA("BasePart") then
        soundPart = sound.Parent.Parent
    else
        soundPart = sound.Parent and sound.Parent:FindFirstChildWhichIsA("BasePart", true)
    end

    local killerModel = nil
    if soundPart then
        local model = soundPart:FindFirstAncestorOfClass("Model")
        if model and model:FindFirstChildOfClass("Humanoid") then
            local kf = getKillersFolder()
            if kf and model:IsDescendantOf(kf) then
                killerModel = model
            end
        end
    end

    if not killerModel then
        killerModel = getNearestKiller()
    end
    if not killerModel then return end

    local hrp = killerModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (hrp.Position - myRoot.Position).Magnitude
    if dist > combatS.detectionRange then return end

    if not isFacing(myRoot, hrp, killerModel.Name) then return end

    -- Anti-bait check
    if combatS.antiBait then
        local vel = hrp.AssemblyLinearVelocity or Vector3.zero
        if vel.Magnitude < 0.1 then pcall(function() vel = hrp.Velocity end) end
        local toUs = myRoot.Position - hrp.Position
        if toUs.Magnitude > 0.1 then
            if vel:Dot(toUs.Unit) < -3 then return end
        end
        if dist > 13 then return end
        if dist > 6 then
            local sideSpeed = math.abs(vel:Dot(hrp.CFrame.RightVector))
            if sideSpeed > 6 and vel:Dot(toUs.Unit) < 0 then return end
        end
    end

    if rollMiss(combatS.abMissChance) then return end

    lastBlockTime = now
    soundBlockedUntil[sound] = now + 0.3

    local function doFire()
        if combatS.blockType == "Block" then
            fireAbility("Block")
            if combatS.doubleBlock then fireAbility("Punch") end
        elseif combatS.blockType == "Charge" then
            fireAbility("Charge")
        elseif combatS.blockType == "7n7 Clone" then
            fireAbility("Clone")
        end
        if combatS.autoPunchOn then
            task.delay(0.12, function() fireAbility("Punch") end)
        end
    end

    if combatS.blockDelay > 0 then
        task.delay(combatS.blockDelay, doFire)
    else
        doFire()
    end
end

local function hookSound(sound)
    if not sound or not sound:IsA("Sound") or soundHooks[sound] then return end
    local preId = extractSoundId(sound)
    if not preId then return end

    local playedConn = sound.Played:Connect(function()
        if combatS.autoBlockOn then task.spawn(tryBlockFromSound, sound, preId) end
    end)
    local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying and combatS.autoBlockOn then
            task.spawn(tryBlockFromSound, sound, preId)
        end
    end)
    local destroyConn; destroyConn = sound.Destroying:Connect(function()
        pcall(function()
            playedConn:Disconnect(); propConn:Disconnect(); destroyConn:Disconnect()
        end)
        soundHooks[sound] = nil
        soundBlockedUntil[sound] = nil
    end)
    soundHooks[sound] = { playedConn, propConn, destroyConn }
    if sound.IsPlaying then task.spawn(tryBlockFromSound, sound, preId) end
end

local function hookExistingSounds()
    local kf = getKillersFolder()
    if not kf then return end
    for _, killer in pairs(kf:GetChildren()) do
        for _, desc in pairs(killer:GetDescendants()) do
            if desc:IsA("Sound") then pcall(hookSound, desc) end
        end
    end
end

local function setupSoundWatcher()
    task.spawn(function()
        local playersFolder = Workspace:FindFirstChild("Players")
        if not playersFolder then
            playersFolder = Workspace:WaitForChild("Players", 30)
        end
        if not playersFolder then return end

        local kf = playersFolder:FindFirstChild("Killers")
        if not kf then kf = playersFolder:WaitForChild("Killers", 30) end
        if not kf then return end

        hookExistingSounds()

        kf.DescendantAdded:Connect(function(desc)
            if desc:IsA("Sound") then pcall(hookSound, desc) end
        end)
        kf.ChildAdded:Connect(function(killer)
            task.wait(0.1)
            for _, desc in pairs(killer:GetDescendants()) do
                if desc:IsA("Sound") then pcall(hookSound, desc) end
            end
        end)
    end)
end

-- ============================================================================
-- HDT (Hitbox Dragging)
-- ============================================================================
local HDT_ANIM_ID = "rbxassetid://136252471123500"

local function stopAim()
    aimActive = false
end

local function startAim()
    stopAim()
    aimActive = true
    task.spawn(function()
        local char = LocalPlayer.Character
        if not char then aimActive = false; return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        if hum then pcall(function() hum.AutoRotate = false end) end
        while aimActive do
            char = LocalPlayer.Character
            if not char then break end
            hum = char:FindFirstChildOfClass("Humanoid")
            myRoot = char:FindFirstChild("HumanoidRootPart")
            if not myRoot then break end
            local killerModel = getNearestKiller()
            local targetHRP = killerModel and killerModel:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                pcall(function()
                    myRoot.CFrame = CFrame.lookAt(myRoot.Position, targetHRP.Position)
                end)
            end
            task.wait()
        end
        if hum then pcall(function() hum.AutoRotate = true end) end
        aimActive = false
    end)
end

local function playHDTAnim()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = HDT_ANIM_ID
    local success, track = pcall(function()
        return hum:LoadAnimation(anim)
    end)
    if success and track then
        track:Play()
        task.delay(2.0, function()
            pcall(function()
                if track and track.IsPlaying then track:Stop() end
            end)
        end)
    end
end

local function hdtBeginDrag(killerModel)
    if hdtDragging then return end
    if not killerModel or not killerModel.Parent then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local tHRP = killerModel:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end

    if rollMiss(combatS.hdtMissChance) then return end

    hdtDragging = true
    local oldW = hum.WalkSpeed
    hum.WalkSpeed = 0
    startAim()
    playHDTAnim()

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 0, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not hdtDragging or tick() - startTime >= combatS.hdtDuration then
            conn:Disconnect()
            if bv and bv.Parent then bv:Destroy() end
            if hum and hum.Parent then hum.WalkSpeed = oldW end
            stopAim()
            hdtDragging = false
            return
        end

        if not (char and char.Parent) or not (killerModel and killerModel.Parent) then
            hdtDragging = false
            return
        end

        local curTHRP = killerModel:FindFirstChild("HumanoidRootPart")
        if not curTHRP then
            hdtDragging = false
            return
        end

        local to = curTHRP.Position - hrp.Position
        local h2 = Vector3.new(to.X, 0, to.Z)
        if h2.Magnitude > 0.01 then
            bv.Velocity = h2.Unit * combatS.hdtMoveSpeed
        else
            bv.Velocity = Vector3.zero
        end

        if to.Magnitude <= 2.0 then
            hdtDragging = false
        end
    end)
end

local function onBlockAnim(track)
    pcall(function()
        local id = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+")
        if not id or not BLOCK_ANIMS[id] then return end

        if combatS.hdtEnabled and not hdtDragging then
            local now = tick()
            if now - hdtLastTime >= HDT_CD then
                hdtLastTime = now
                local nearest = getNearestKiller()
                if nearest then
                    task.spawn(function()
                        hdtBeginDrag(nearest)
                    end)
                end
            end
        end

        if combatS.autoPunchOn then
            task.delay(0.12, function()
                fireAbility("Punch")
            end)
        end
    end)
end

-- ============================================================================
-- AIM PUNCH
-- ============================================================================
local function setupAimPunch(char)
    if aimConnection then aimConnection:Disconnect(); aimConnection = nil end
    local hum = char and char:FindFirstChild("Humanoid")
    local anim = hum and hum:FindFirstChildOfClass("Animator")
    if not anim or not combatS.aimPunchActive then return end

    aimConnection = anim.AnimationPlayed:Connect(function(track)
        local animId = track.Animation.AnimationId:match("%d+")
        if combatS.aimPunchActive and PUNCH_ANIMS[animId] then
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChild("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if h and r and not punchAiming then
                originalAutoRot = h.AutoRotate
                originalHRPCFrame = r.CFrame
            end
            punchLastTrigger = tick()
            punchAiming = true
        end
    end)
end

-- Aim punch render loop
RunService.RenderStepped:Connect(function()
    if not combatS.aimPunchActive then
        if punchAiming then
            punchAiming = false
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and originalHRPCFrame then
                hrp.CFrame = CFrame.new(hrp.Position) * originalHRPCFrame.Rotation
                hrp.AssemblyAngularVelocity = Vector3.zero
                originalHRPCFrame = nil
            end
            if hum then
                hum.AutoRotate = originalAutoRot ~= nil and originalAutoRot or true
                originalAutoRot = nil
            end
        end
        return
    end

    if not punchAiming then return end

    local elapsed = tick() - punchLastTrigger
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hum or not hrp then
        punchAiming = false
        return
    end

    if elapsed > combatS.aimPunchDuration then
        punchAiming = false
        if hrp and originalHRPCFrame then
            hrp.CFrame = CFrame.new(hrp.Position) * originalHRPCFrame.Rotation
            hrp.AssemblyAngularVelocity = Vector3.zero
            originalHRPCFrame = nil
        end
        hum.AutoRotate = originalAutoRot ~= nil and originalAutoRot or true
        originalAutoRot = nil
        return
    end

    hum.AutoRotate = false
    hrp.AssemblyAngularVelocity = Vector3.zero

    local kf = getKillersFolder()
    if kf then
        local bestDist, targetHRP = math.huge, nil
        for _, killer in pairs(kf:GetChildren()) do
            local khrp = killer:FindFirstChild("HumanoidRootPart")
            if khrp then
                local d = (khrp.Position - hrp.Position).Magnitude
                if d < bestDist then bestDist = d; targetHRP = khrp end
            end
        end
        if targetHRP then
            local vel = targetHRP.AssemblyLinearVelocity or Vector3.zero
            local predictPos = vel.Magnitude > 0.5
                and (targetHRP.Position + vel * (combatS.punchPrediction / 60))
                or targetHRP.Position
            local dir = (predictPos - hrp.Position) * Vector3.new(1, 0, 1)
            if dir.Magnitude > 0.01 then
                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir.Unit)
            end
        end
    end
end)

-- ============================================================================
-- VISUAL UPDATERS (Circles & Facing Visual)
-- ============================================================================
local function updateCircles()
    local kf = getKillersFolder()
    if not kf then return end

    for _, killer in pairs(kf:GetChildren()) do
        local hrp = killer:FindFirstChild("HumanoidRootPart")
        if hrp then
            if combatS.killerCircles then
                if not circles[killer] then
                    pcall(function()
                        local c = Instance.new("CylinderHandleAdornment")
                        c.Name = "CombatCircle"
                        c.Adornee = hrp
                        c.Color3 = Color3.fromRGB(255, 140, 170)
                        c.AlwaysOnTop = true
                        c.ZIndex = 1
                        c.Transparency = 0.6
                        c.Radius = combatS.detectionRange
                        c.Height = 0.12
                        c.CFrame = CFrame.new(0, -(hrp.Size.Y / 2 + 0.05), 0) * CFrame.Angles(math.rad(90), 0, 0)
                        c.Parent = hrp
                        circles[killer] = c
                    end)
                else
                    circles[killer].Radius = combatS.detectionRange
                end
            else
                if circles[killer] then
                    pcall(function() circles[killer]:Destroy() end)
                    circles[killer] = nil
                end
            end
        end
    end

    for killer, circle in pairs(circles) do
        if not killer.Parent or not killer:FindFirstChild("HumanoidRootPart") then
            pcall(function() circle:Destroy() end)
            circles[killer] = nil
        end
    end
end

local function updateFacingVisual()
    local kf = getKillersFolder()
    if not kf then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for _, killer in pairs(kf:GetChildren()) do
        local hrp = killer:FindFirstChild("HumanoidRootPart")
        if hrp then
            if combatS.facingVisual then
                if not facingVisuals[killer] then
                    pcall(function()
                        local v = Instance.new("CylinderHandleAdornment")
                        v.Name = "FacingVis"
                        v.Adornee = hrp
                        v.AlwaysOnTop = true
                        v.ZIndex = 2
                        v.Radius = combatS.facingVisRadius
                        v.Height = 0.08
                        v.CFrame = CFrame.new(0, -(hrp.Size.Y / 2 + 0.04), -combatS.facingVisRadius) * CFrame.Angles(math.rad(90), 0, 0)
                        v.Color3 = Color3.fromRGB(120, 255, 120)
                        v.Transparency = 0.3
                        v.Parent = hrp
                        facingVisuals[killer] = v
                    end)
                end
                local vis = facingVisuals[killer]
                if vis and vis.Parent then
                    vis.Radius = combatS.facingVisRadius
                    vis.CFrame = CFrame.new(0, -(hrp.Size.Y / 2 + 0.04), -combatS.facingVisRadius) * CFrame.Angles(math.rad(90), 0, 0)

                    local inRange, facing = false, false
                    if myRoot then
                        inRange = (hrp.Position - myRoot.Position).Magnitude <= combatS.detectionRange
                        if inRange then facing = isFacing(myRoot, hrp, killer.Name) end
                    end
                    if inRange and facing then
                        vis.Color3 = Color3.fromRGB(120, 255, 120)
                        vis.Transparency = 0.3
                    elseif inRange then
                        vis.Color3 = Color3.fromRGB(255, 120, 120)
                        vis.Transparency = 0.4
                    else
                        vis.Color3 = Color3.fromRGB(255, 255, 120)
                        vis.Transparency = 0.7
                    end
                end
            else
                if facingVisuals[killer] then
                    pcall(function() facingVisuals[killer]:Destroy() end)
                    facingVisuals[killer] = nil
                end
            end
        end
    end
end

-- ============================================================================
-- MAIN LOOPS
-- ============================================================================
local function startLoops()
    if soundTickConn then soundTickConn:Disconnect() end
    soundTickConn = RunService.Heartbeat:Connect(function()
        if not combatS.autoBlockOn then return end
        local now = tick()
        for sound, t in pairs(soundBlockedUntil) do
            if now > t then soundBlockedUntil[sound] = nil end
        end
    end)

    if visualTickConn then visualTickConn:Disconnect() end
    local visualThrottle = 0
    visualTickConn = RunService.Heartbeat:Connect(function()
        visualThrottle = visualThrottle + 1
        if visualThrottle < 10 then return end
        visualThrottle = 0
        if combatS.killerCircles then updateCircles() end
        if combatS.facingVisual then updateFacingVisual() end
    end)
end

local function stopLoops()
    if soundTickConn then soundTickConn:Disconnect(); soundTickConn = nil end
    if visualTickConn then visualTickConn:Disconnect(); visualTickConn = nil end
    for killer, circle in pairs(circles) do pcall(function() circle:Destroy() end) end
    for killer, vis in pairs(facingVisuals) do pcall(function() vis:Destroy() end) end
    circles = {}
    facingVisuals = {}
end

-- Animation watcher
local function refreshAnimator()
    local char = LocalPlayer.Character
    if not char then cachedAnimator = nil; return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    cachedAnimator = hum and hum:FindFirstChildOfClass("Animator") or nil
    if cachedAnimator then
        cachedAnimator.AnimationPlayed:Connect(onBlockAnim)
    end
end

-- ============================================================================
-- CHARACTER HANDLERS
-- ============================================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    refreshAnimator()
    setupAimPunch(char)
    if combatS.autoBlockOn then setupSoundWatcher() end
    if combatS.autoBlockOn or combatS.killerCircles or combatS.facingVisual then
        startLoops()
    end
end)

if LocalPlayer.Character then
    task.spawn(function()
        task.wait(1)
        refreshAnimator()
        setupAimPunch(LocalPlayer.Character)
        if combatS.autoBlockOn then setupSoundWatcher() end
        if combatS.autoBlockOn or combatS.killerCircles or combatS.facingVisual then
            startLoops()
        end
    end)
end

-- ============================================================================
-- UI SECTIONS
-- ============================================================================

-- Auto Block Section
local secAutoBlock = Guest1337Tab:Section({ Title = "Auto Block (Audio)", Opened = true })

secAutoBlock:Toggle({ 
    Title = "Auto Block", 
    Type = "Checkbox", 
    Default = combatS.autoBlockOn, 
    Callback = function(on) 
        combatS.autoBlockOn = on
        if on then 
            setupSoundWatcher() 
            startLoops()
        else 
            stopLoops() 
        end 
    end 
})

secAutoBlock:Dropdown({ 
    Title = "Block Type", 
    Values = {"Block", "Charge", "7n7 Clone"}, 
    Default = combatS.blockType, 
    Callback = function(v) combatS.blockType = v end 
})

secAutoBlock:Slider({ 
    Title = "Detection Range", 
    Step = 1, 
    Value = {Min = 5, Max = 50, Default = combatS.detectionRange}, 
    Callback = function(v) combatS.detectionRange = v end 
})

secAutoBlock:Slider({ 
    Title = "Block Delay (s)", 
    Step = 0.01, 
    Value = {Min = 0, Max = 0.5, Default = combatS.blockDelay}, 
    Callback = function(v) combatS.blockDelay = v end 
})

secAutoBlock:Toggle({ 
    Title = "Double Block Tech", 
    Type = "Checkbox", 
    Default = combatS.doubleBlock, 
    Callback = function(on) combatS.doubleBlock = on end 
})

secAutoBlock:Toggle({ 
    Title = "Anti-Bait", 
    Type = "Checkbox", 
    Default = combatS.antiBait, 
    Callback = function(on) combatS.antiBait = on end 
})

secAutoBlock:Slider({ 
    Title = "Block Miss Chance %", 
    Step = 1, 
    Value = {Min = 0, Max = 100, Default = combatS.abMissChance}, 
    Callback = function(v) combatS.abMissChance = v end 
})

-- Auto Punch Section
local secAutoPunch = Guest1337Tab:Section({ Title = "Auto Punch", Opened = true })

secAutoPunch:Toggle({ 
    Title = "Auto Punch", 
    Type = "Checkbox", 
    Default = combatS.autoPunchOn, 
    Callback = function(on) combatS.autoPunchOn = on end 
})

-- HDT Section
local secHDT = Guest1337Tab:Section({ Title = "HDT (Hitbox Dragging)", Opened = false })

secHDT:Toggle({ 
    Title = "Enable HDT", 
    Type = "Checkbox", 
    Default = combatS.hdtEnabled, 
    Callback = function(on) combatS.hdtEnabled = on end 
})

secHDT:Slider({ 
    Title = "Drag Speed", 
    Step = 1, 
    Value = {Min = 1, Max = 100, Default = combatS.hdtMoveSpeed}, 
    Callback = function(v) combatS.hdtMoveSpeed = v end 
})

secHDT:Slider({ 
    Title = "Drag Duration (s)", 
    Step = 0.1, 
    Value = {Min = 0.1, Max = 3.0, Default = combatS.hdtDuration}, 
    Callback = function(v) combatS.hdtDuration = v end 
})

secHDT:Slider({ 
    Title = "HDT Miss Chance %", 
    Step = 1, 
    Value = {Min = 0, Max = 100, Default = combatS.hdtMissChance}, 
    Callback = function(v) combatS.hdtMissChance = v end 
})

-- Vision Section
local secVision = Guest1337Tab:Section({ Title = "Vision", Opened = true })

secVision:Toggle({ 
    Title = "Detection Circles", 
    Type = "Checkbox", 
    Default = combatS.killerCircles, 
    Callback = function(on) 
        combatS.killerCircles = on
        if on then startLoops() else updateCircles() end
    end 
})

secVision:Toggle({ 
    Title = "Facing Check", 
    Type = "Checkbox", 
    Default = combatS.facingCheck, 
    Callback = function(on) combatS.facingCheck = on end 
})

secVision:Toggle({ 
    Title = "Facing Visual", 
    Type = "Checkbox", 
    Default = combatS.facingVisual, 
    Callback = function(on)
        combatS.facingVisual = on
        if on then startLoops() else updateFacingVisual() end
    end 
})

secVision:Slider({ 
    Title = "Facing Visual Size", 
    Step = 0.5, 
    Value = {Min = 1, Max = 10, Default = combatS.facingVisRadius}, 
    Callback = function(v)
        combatS.facingVisRadius = v
        for _, vis in pairs(facingVisuals) do
            if vis and vis.Parent then
                vis.Radius = v
                local adornee = vis.Adornee
                if adornee then
                    vis.CFrame = CFrame.new(0, -(adornee.Size.Y / 2 + 0.04), -v) * CFrame.Angles(math.rad(90), 0, 0)
                end
            end
        end
    end
})

-- Aim Punch Section
local secAimPunch = Guest1337Tab:Section({ Title = "Aim Punch Lock", Opened = true })

secAimPunch:Toggle({ 
    Title = "Aim Punch", 
    Type = "Checkbox", 
    Default = combatS.aimPunchActive,
    Callback = function(on)
        combatS.aimPunchActive = on
        if on and LocalPlayer.Character then setupAimPunch(LocalPlayer.Character) end
        if not on and aimConnection then aimConnection:Disconnect(); aimConnection = nil end
    end
})

secAimPunch:Slider({ 
    Title = "Punch Prediction", 
    Step = 0.1,
    Value = {Min = 0, Max = 10, Default = combatS.punchPrediction},
    Callback = function(v) combatS.punchPrediction = v end 
})

secAimPunch:Slider({ 
    Title = "Aim Duration (s)", 
    Step = 0.05,
    Value = {Min = 0.1, Max = 2.0, Default = combatS.aimPunchDuration},
    Callback = function(v) combatS.aimPunchDuration = v end 
})

-- Interface Section
local secInterface = Guest1337Tab:Section({ Title = "Interface", Opened = true })

secInterface:Button({ 
    Title = "Close UI", 
    Locked = false,
    Callback = function()
        local ok = pcall(function() Window:Destroy() end)
        if not ok then pcall(function() Window:Close() end) end
    end 
})

print("Guest 1337 - Hutao Combat System loaded")