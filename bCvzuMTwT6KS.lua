-- SAKIWARE | Guest 1337 Standalone
-- maintained by mitsuki
local svc = {
    Players        = game:GetService("Players"),
    Run            = game:GetService("RunService"),
    Input          = game:GetService("UserInputService"),
    RS             = game:GetService("ReplicatedStorage"),
    WS             = game:GetService("Workspace"),
    TweenService   = game:GetService("TweenService"),
}

local lp  = svc.Players.LocalPlayer

local function getTeamFolder(name)
    local root = svc.WS:FindFirstChild("Players")
    return root and root:FindFirstChild(name)
end

local ui = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local win = ui:CreateWindow({
    Title          = "Guest 1337",
    Icon           = "shield",
    Author         = "mitsuki",
    Folder         = "SAKIWARE",
    Size           = UDim2.fromOffset(350, 300),
    Transparent    = false,
    Theme          = "Dark",
    Resizable      = false,
    SideBarWidth   = 150,
    HideSearchBar  = true,
    ScrollBarEnabled = false,
})

win:SetToggleKey(Enum.KeyCode.L)

-- Replace tab reference so sections attach to this window
local tabGuest1337 = win:Tab({ Title = "Guest 1337", Icon = "shield" })
local _g1337AbToggle = nil

------------------------------------------------------------------------
------------------------------------------------------------------------
-- TAB: GUEST 1337
------------------------------------------------------------------------
------------------------------------------------------------------------
-- tabGuest1337 defined above

-- GUEST1337 — Auto Block & Combat
------------------------------------------------------------------------
local sec_015 = tabGuest1337:Section({ Title = "Auto Block & Combat", Opened = true })

-- Settings
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
    hdtFlickSpeed = 22,
    hdtFlickDuration = 1.0,
    hdtMissChance = 0,
    hdtMoveSpeed = 26,
    killerCircles = false,
    facingCheck = true,
    facingVisual = false,
    facingVisRadius = 3,
    aimPunchActive   = false,
    punchPrediction  = 2.3,
    aimPunchDuration = 0.5,
}

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
    ["116468089135195"]=true,["112809109188560"]=true,["106727013904874"]=true,
}

-- Block anim IDs for HDT detection
local BLOCK_ANIMS = {
    ["72722244508749"]=true,["96959123077498"]=true,["95802026624883"]=true,
    ["100926346851492"]=true,["120748030255574"]=true,
    ["127040663332045"]=true,
}

local BAIT_KILLERS = {"John Doe","Slasher","c00lkidd","Jason","1x1x1x1","Noli","Sixer","Nosferatu"}
local STRICT_FACING_DOT = 0.70
local _cachedAnimator = nil

local function combatIsFacing(myRoot, targetRoot, killerName)
    if not combatS.facingCheck then return true end
    if not myRoot or not targetRoot then return false end
    local diff = myRoot.Position - targetRoot.Position
    if diff.Magnitude < 0.01 then return true end
    local dir = diff.Unit
    local dot = targetRoot.CFrame.LookVector:Dot(dir)
    local bait = false
    if killerName then
        for _, n in ipairs(BAIT_KILLERS) do
            if killerName:find(n) then bait = true; break end
        end
    end
    if bait then
        local vel = Vector3.zero
        pcall(function() vel = targetRoot.AssemblyLinearVelocity end)
        if vel.Magnitude < 0.01 then pcall(function() vel = targetRoot.Velocity end) end
        local side = math.abs(vel:Dot(targetRoot.CFrame.RightVector))
        if side > 3 then return false end
        return dot > STRICT_FACING_DOT + 0.05
    end
    return dot > STRICT_FACING_DOT
end

-- Helper functions
local function combatGetKillersFolder()
    local p = svc.WS:FindFirstChild("Players")
    return p and p:FindFirstChild("Killers")
end

local function combatGetNearestKiller()
    local char = lp.Character; if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart"); if not myRoot then return nil end
    local kf = combatGetKillersFolder(); if not kf then return nil end
    local best, bestD = nil, math.huge
    for _, k in pairs(kf:GetChildren()) do
        local hrp = k:FindFirstChild("HumanoidRootPart")
        if hrp then
            local d = (hrp.Position - myRoot.Position).Magnitude
            if d < bestD then best, bestD = k, d end
        end
    end
    return best
end

local function combatRollMiss(chance)
    if chance <= 0 then return false end
    if chance >= 100 then return true end
    return math.random(1, 100) <= chance
end

local function combatFireAbility(abilityType)
    local rem = hbGetRemote()
    if not rem then return end
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
    pcall(function() rem:FireServer("UseActorAbility", {[1] = buf}) end)
    pcall(function() rem:FireServer(abilityType) end)
end

-- Forward declaration (used by HDT)
local combatGetKillerHRP

-- Punch animation IDs to trigger aim lock (from V1PRBLOCK)
local combatTrackedPunchAnimations = {
    ["87259391926321"]=true,["140703210927645"]=true,["136007065400978"]=true,["129843313690921"]=true,
    ["86709774283672"]=true, ["108807732150251"]=true,["138040001965654"]=true,["86096387000557"]=true,
    ["81905101227053"]=true, ["127777649118195"]=true,["99100240941590"]=true, ["92831180929659"]=true,
    ["112081768119093"]=true,["117587689359268"]=true,["91830732867282"]=true, ["91730605416216"]=true,
    ["100184164753080"]=true,
    ["72007882634344"]=true,
}

-- Aim Punch state
local combatPunchAiming          = false
local combatPunchLastTriggerTime = 0
local combatOriginalAutoRotate   = nil
local combatOriginalHRPRotY      = nil   -- saved Y rotation before aim punch snaps HRP
local combatOriginalHRPCFrame    = nil   -- saved full CFrame before aim punch
local combatAimConnection        = nil

local function combatSetupAimPunch(char)
    if combatAimConnection then combatAimConnection:Disconnect(); combatAimConnection = nil end
    local hum  = char:FindFirstChild("Humanoid")
    local anim = hum and hum:FindFirstChildOfClass("Animator")
    if not anim or not combatS.aimPunchActive then return end
    combatAimConnection = anim.AnimationPlayed:Connect(function(track)
        local animId = track.Animation.AnimationId:match("%d+")
        if combatS.aimPunchActive and combatTrackedPunchAnimations[animId] then
            local c = lp.Character
            local h = c and c:FindFirstChild("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            -- Only save if not already mid-punch so we don't overwrite the original rotation
            if h and r and not combatPunchAiming then
                combatOriginalAutoRotate = h.AutoRotate
                combatOriginalHRPCFrame  = r.CFrame
                combatOriginalHRPRotY    = select(2, r.CFrame:ToEulerAnglesYXZ())
            end
            combatPunchLastTriggerTime = tick()
            combatPunchAiming = true
        end
    end)
end

-- Aim-punch RenderStepped (aims toward nearest killer while punch animation plays)
svc.Run.RenderStepped:Connect(function()
    if not combatS.aimPunchActive then
        if combatPunchAiming then
            combatPunchAiming = false
            local char = lp.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and combatOriginalHRPCFrame ~= nil then
                hrp.CFrame = CFrame.new(hrp.Position) * combatOriginalHRPCFrame.Rotation
                hrp.AssemblyAngularVelocity = Vector3.zero
                combatOriginalHRPCFrame = nil
                combatOriginalHRPRotY = nil
            end
            if hum then
                hum.AutoRotate = combatOriginalAutoRotate ~= nil and combatOriginalAutoRotate or true
                combatOriginalAutoRotate = nil
            end
        end
        return
    end
    if not combatPunchAiming then return end
    local elapsed = tick() - combatPunchLastTriggerTime
    local char = lp.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then combatPunchAiming = false; return end
    if elapsed > combatS.aimPunchDuration then
        combatPunchAiming = false
        if hrp and combatOriginalHRPCFrame ~= nil then
            hrp.CFrame = CFrame.new(hrp.Position) * combatOriginalHRPCFrame.Rotation
            hrp.AssemblyAngularVelocity = Vector3.zero
            combatOriginalHRPCFrame = nil
            combatOriginalHRPRotY = nil
        end
        if hum then
            hum.AutoRotate = combatOriginalAutoRotate ~= nil and combatOriginalAutoRotate or true
            combatOriginalAutoRotate = nil
        end
        return
    end
    hum.AutoRotate = false
    hrp.AssemblyAngularVelocity = Vector3.zero
    local kf = svc.WS:FindFirstChild("Players") and svc.WS.Players:FindFirstChild("Killers")
    if kf then
        local bestDist, targetHRP = math.huge, nil
        for _, killer in ipairs(kf:GetChildren()) do
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

-- Auto Block (Audio-based) — event-driven hook system
local combatSoundHooks        = {}
local combatSoundBlockedUntil = {}
local combatLastBlockTime     = 0
local BLOCK_CD                = 0.1

local function combatExtractSoundId(sound)
    if not sound then return nil end
    return tostring(sound.SoundId):match("%d+")
end

local function combatTryBlockFromSound(sound, preId)
    if not combatS.autoBlockOn then return end
    if not sound or not sound:IsA("Sound") then return end

    local id = preId or combatExtractSoundId(sound)
    if not id or not TRIGGER_SOUNDS[id] then return end

    local now = tick()
    if now - combatLastBlockTime < BLOCK_CD then return end
    if combatSoundBlockedUntil[sound] and now < combatSoundBlockedUntil[sound] then return end

    local char = lp.Character; if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart"); if not myRoot then return end

    -- Resolve killer from the sound's parent part
    local soundPart
    if sound.Parent and sound.Parent:IsA("BasePart") then
        soundPart = sound.Parent
    elseif sound.Parent and sound.Parent:IsA("Attachment")
        and sound.Parent.Parent and sound.Parent.Parent:IsA("BasePart") then
        soundPart = sound.Parent.Parent
    else
        soundPart = sound.Parent and sound.Parent:FindFirstChildWhichIsA("BasePart", true)
    end

    local killerModel = nil
    if soundPart then
        local model = soundPart:FindFirstAncestorOfClass("Model")
        if model and model:FindFirstChildOfClass("Humanoid") then
            local kf = combatGetKillersFolder()
            if kf and model:IsDescendantOf(kf) then
                killerModel = model
            end
        end
    end

    -- Fallback: nearest killer in range
    if not killerModel then
        killerModel = combatGetNearestKiller()
    end
    if not killerModel then return end

    local hrp = killerModel:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local dist = (hrp.Position - myRoot.Position).Magnitude
    if dist > combatS.detectionRange then return end

    if not combatIsFacing(myRoot, hrp, killerModel.Name) then return end

    if combatS.antiBait then
        local vel = Vector3.zero
        pcall(function() vel = hrp.AssemblyLinearVelocity end)
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

    if combatRollMiss(combatS.abMissChance) then return end
    combatLastBlockTime = now
    combatSoundBlockedUntil[sound] = now + 0.3

    local function doFire()
        if combatS.blockType == "Block" then
            combatFireAbility("Block")
            if combatS.doubleBlock then combatFireAbility("Punch") end
        elseif combatS.blockType == "Charge" then
            combatFireAbility("Charge")
        elseif combatS.blockType == "7n7 Clone" then
            combatFireAbility("Clone")
        end
    end

    if combatS.blockDelay > 0 then
        task.delay(combatS.blockDelay, doFire)
    else
        doFire()
    end
end

local function combatHookSound(sound)
    if not sound or not sound:IsA("Sound") or combatSoundHooks[sound] then return end
    local preId = combatExtractSoundId(sound)
    if not preId then return end

    local playedConn = sound.Played:Connect(function()
        if combatS.autoBlockOn then task.spawn(combatTryBlockFromSound, sound, preId) end
    end)
    local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying and combatS.autoBlockOn then
            task.spawn(combatTryBlockFromSound, sound, preId)
        end
    end)
    local destroyConn; destroyConn = sound.Destroying:Connect(function()
        pcall(function()
            playedConn:Disconnect(); propConn:Disconnect(); destroyConn:Disconnect()
        end)
        combatSoundHooks[sound]        = nil
        combatSoundBlockedUntil[sound] = nil
    end)
    combatSoundHooks[sound] = { playedConn, propConn, destroyConn }
    if sound.IsPlaying then task.spawn(combatTryBlockFromSound, sound, preId) end
end

local function combatHookExistingSounds()
    local kf = combatGetKillersFolder(); if not kf then return end
    for _, killer in pairs(kf:GetChildren()) do
        for _, desc in pairs(killer:GetDescendants()) do
            if desc:IsA("Sound") then pcall(combatHookSound, desc) end
        end
    end
end

local function combatSetupSoundWatcher()
    task.spawn(function()
        local playersFolder = svc.WS:FindFirstChild("Players")
        if not playersFolder then
            playersFolder = svc.WS:WaitForChild("Players", 30)
        end
        if not playersFolder then return end

        local kf = playersFolder:FindFirstChild("Killers")
        if not kf then kf = playersFolder:WaitForChild("Killers", 30) end
        if not kf then return end

        combatHookExistingSounds()

        kf.DescendantAdded:Connect(function(desc)
            if desc:IsA("Sound") then pcall(combatHookSound, desc) end
        end)
        kf.ChildAdded:Connect(function(killer)
            task.wait(0.1)
            for _, desc in pairs(killer:GetDescendants()) do
                if desc:IsA("Sound") then pcall(combatHookSound, desc) end
            end
        end)
    end)
end

-- HDT (Hitbox Dragging Tech) - activates on block animation
-- Uses improved beginDragIntoKiller logic (from FINAL_AUTO_BLOCK) with v1prware BLOCK_ANIMS IDs
local combatHDTLastTime = 0
local HDT_CD = 0.5
local _combatHDTDebounce = false

-- Helper to resolve the killer's root part (mirrors getKillerHRP from FINAL_AUTO_BLOCK)
combatGetKillerHRP = function(killerModel)
    if not killerModel then return nil end
    local hrp = killerModel:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp end
    if killerModel.PrimaryPart then return killerModel.PrimaryPart end
    return killerModel:FindFirstChildWhichIsA("BasePart", true)
end

local combatHDTDragging = false

local function combatHDTBeginDrag(killerModel, blockTrack)
    pcall(function()
        if combatHDTDragging then return end
        if combatRollMiss(combatS.hdtMissChance) then return end

        combatHDTDragging = true

        local char = lp.Character
        if not char or not killerModel then
            combatHDTDragging = false
            return
        end

        local hrp        = char:FindFirstChild("HumanoidRootPart")
        local hum        = char:FindFirstChildOfClass("Humanoid")
        local killerRoot = killerModel:FindFirstChild("HumanoidRootPart") or killerModel.PrimaryPart

        if not hrp or not hum or not killerRoot then
            combatHDTDragging = false
            return
        end

        -- Save and zero locomotion so player input contributes no force
        local origSpeed = hum.WalkSpeed
        local origJump  = hum.JumpPower

        -- Freeze sprint module so it cannot write WalkSpeed back
        local sprintMod = nil
        local origSprintSpeed, origMaxSprint
        pcall(function()
            sprintMod = require(svc.RS.Systems.Character.Game.Sprinting)
            origSprintSpeed = sprintMod.SprintSpeed
            origMaxSprint   = sprintMod.MaxSprintSpeed
            sprintMod.SprintSpeed    = 0
            sprintMod.MaxSprintSpeed = 0
        end)

        local stopped = false

        local function stopMove()
            if stopped then return end
            stopped = true
            pcall(function()
                if sprintMod then
                    sprintMod.SprintSpeed    = origSprintSpeed or 26
                    sprintMod.MaxSprintSpeed = origMaxSprint   or 26
                end
            end)
            hum.WalkSpeed = origSpeed
            hum.JumpPower = origJump
            hum:MoveTo(hrp.Position)
            combatHDTDragging = false
        end

        -- Stop when block animation ends
        if blockTrack then
            blockTrack.Stopped:Connect(stopMove)
        end

        -- MoveTo now runs completely unopposed
        hum.WalkSpeed = combatS.hdtMoveSpeed
        hum:MoveTo(killerRoot.Position)

        -- Safety fallback
        task.spawn(function()
            hum.MoveToFinished:Wait()
            stopMove()
        end)
    end)
end

-- Triggered by AnimationPlayed (event-driven, not polled)
-- Uses File 1's BLOCK_ANIMS IDs:
--   72722244508749, 96959123077498, 95802026624883, 100926346851492, 120748030255574
local function combatOnBlockAnim(track)
    pcall(function()
        local id = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+")
        if not id or not BLOCK_ANIMS[id] then return end

        -- HDT
        if combatS.hdtEnabled and not combatHDTDragging then
            local now = tick(); if now - combatHDTLastTime >= HDT_CD then
                combatHDTLastTime = now
                local nearest = combatGetNearestKiller()
                if nearest then
                    task.spawn(function()
                        combatHDTBeginDrag(nearest, track)
                    end)
                end
            end
        end

        -- Auto Punch: fires after block duration (0.1s) so block registers first
        if combatS.autoPunchOn then
            task.delay(0.12, function()
                combatFireAbility("Punch")
            end)
        end
    end)
end

-- Detection Circles
local combatCircles = {}
local function combatUpdateCircles()
    local kf = combatGetKillersFolder(); if not kf then return end
    for _, k in pairs(kf:GetChildren()) do
        local hrp = k:FindFirstChild("HumanoidRootPart")
        if hrp then
            if combatS.killerCircles then
                if not combatCircles[k] then
                    pcall(function()
                        local c = Instance.new("CylinderHandleAdornment")
                        c.Name="CombatCircle"; c.Adornee=hrp
                        c.Color3=Color3.fromRGB(255,140,170); c.AlwaysOnTop=true; c.ZIndex=1; c.Transparency=0.6
                        c.Radius=combatS.detectionRange; c.Height=0.12
                        c.CFrame=CFrame.new(0,-(hrp.Size.Y/2+0.05),0)*CFrame.Angles(math.rad(90),0,0)
                        c.Parent=hrp; combatCircles[k]=c
                    end)
                else
                    combatCircles[k].Radius = combatS.detectionRange
                end
            else
                if combatCircles[k] then combatCircles[k]:Destroy(); combatCircles[k]=nil end
            end
        end
    end
    -- Cleanup
    for k, c in pairs(combatCircles) do
        if not k.Parent or not k:FindFirstChild("HumanoidRootPart") then
            pcall(function() c:Destroy() end); combatCircles[k]=nil
        end
    end
end

-- Facing Visual (floor circle under killer)
local combatFacingVisuals = {}
local function combatUpdateFacing()
    local kf = combatGetKillersFolder(); if not kf then return end
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    for _, k in pairs(kf:GetChildren()) do
        local hrp = k:FindFirstChild("HumanoidRootPart")
        if hrp then
            if combatS.facingVisual then
                if not combatFacingVisuals[k] then
                    pcall(function()
                        local v = Instance.new("CylinderHandleAdornment")
                        v.Name = "FacingVis"; v.Adornee = hrp
                        v.AlwaysOnTop = true; v.ZIndex = 2
                        v.Radius = combatS.facingVisRadius; v.Height = 0.08
                        v.CFrame = CFrame.new(0, -(hrp.Size.Y / 2 + 0.04), -combatS.facingVisRadius) * CFrame.Angles(math.rad(90), 0, 0)
                        v.Color3 = Color3.fromRGB(120, 255, 120); v.Transparency = 0.3
                        v.Parent = hrp
                        combatFacingVisuals[k] = v
                    end)
                end
                local vis = combatFacingVisuals[k]
                if vis and vis.Parent then
                    vis.Radius = combatS.facingVisRadius
                    vis.CFrame = CFrame.new(0, -(hrp.Size.Y / 2 + 0.04), -combatS.facingVisRadius) * CFrame.Angles(math.rad(90), 0, 0)
                    local inRange, facing = false, false
                    if myRoot then
                        inRange = (hrp.Position - myRoot.Position).Magnitude <= combatS.detectionRange
                        if inRange then facing = combatIsFacing(myRoot, hrp, k.Name) end
                    end
                    if inRange and facing then
                        vis.Color3 = Color3.fromRGB(120, 255, 120); vis.Transparency = 0.3
                    elseif inRange then
                        vis.Color3 = Color3.fromRGB(255, 120, 120); vis.Transparency = 0.4
                    else
                        vis.Color3 = Color3.fromRGB(255, 255, 120); vis.Transparency = 0.7
                    end
                end
            else
                if combatFacingVisuals[k] then combatFacingVisuals[k]:Destroy(); combatFacingVisuals[k] = nil end
            end
        end
    end
end

-- Main loops
local combatSoundTickConn = nil
local combatVisualTickConn = nil

local function combatStartLoops()
    -- Sound cleanup tick (detection is now event-driven via combatHookSound)
    if combatSoundTickConn then combatSoundTickConn:Disconnect() end
    combatSoundTickConn = svc.Run.Heartbeat:Connect(function()
        if not combatS.autoBlockOn then return end
        -- Clean up stale entries from the blocked table
        local now = tick()
        for sound, t in pairs(combatSoundBlockedUntil) do
            if now > t then combatSoundBlockedUntil[sound] = nil end
        end
    end)

    -- Visual tick
    if combatVisualTickConn then combatVisualTickConn:Disconnect() end
    combatVisualTickConn = svc.Run.Heartbeat:Connect(function()
        combatUpdateCircles()
        combatUpdateFacing()
    end)
end

local function combatStopLoops()
    if combatSoundTickConn then combatSoundTickConn:Disconnect(); combatSoundTickConn = nil end
    if combatVisualTickConn then combatVisualTickConn:Disconnect(); combatVisualTickConn = nil end
    -- Cleanup visuals
    for k, c in pairs(combatCircles) do pcall(function() c:Destroy() end) end
    for k, v in pairs(combatFacingVisuals) do pcall(function() v:Destroy() end) end
    combatCircles = {}
    combatFacingVisuals = {}
end

-- Animator hook for HDT
local function combatRefreshAnimator()
    local c = lp.Character; if not c then _cachedAnimator = nil; return end
    local h = c:FindFirstChildOfClass("Humanoid")
    _cachedAnimator = h and h:FindFirstChildOfClass("Animator") or nil
    if _cachedAnimator then
        _cachedAnimator.AnimationPlayed:Connect(combatOnBlockAnim)
    end
end

-- Character handlers
lp.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    combatRefreshAnimator()
    combatSetupAimPunch(char)
    if combatS.autoBlockOn then combatSetupSoundWatcher() end
    if combatS.autoBlockOn or combatS.killerCircles or combatS.facingVisual then
        combatStartLoops()
    end
end)

if lp.Character then
    task.spawn(function()
        task.wait(1)
        combatRefreshAnimator()
        combatSetupAimPunch(lp.Character)
        if combatS.autoBlockOn then combatSetupSoundWatcher() end
        if combatS.autoBlockOn or combatS.killerCircles or combatS.facingVisual then
            combatStartLoops()
        end
    end)
end

-- Auto Punch fires from combatOnBlockAnim after a successful block (0.1s delay)

-- UI Elements
local _g1337AbToggle = sec_015:Toggle({ Title = "Auto Block (Audio)", Flag = "combatAutoBlock", Default = combatS.autoBlockOn, Callback=function(on) 
        combatS.autoBlockOn=on
        abDotSetState(on)
        if on then combatSetupSoundWatcher(); combatStartLoops()
        else combatStopLoops() end
    end, Type = "Checkbox"})

sec_015:Dropdown({ Title = "Block Type", Flag = "combatBlockType", Values = {"Block","Charge","7n7 Clone"}, Default = combatS.blockType, Callback=function(v) combatS.blockType=v end 
})

sec_015:Slider({ Title = "Detection Range", Flag = "combatDetRange", Value = {Min=5,Max=50,Default=combatS.detectionRange}, Step = 1, Callback=function(v) combatS.detectionRange=v end 
})



sec_015:Slider({ Title = "Block Delay (s)", Flag = "combatBlockDelay", Value = {Min=0,Max=0.5,Default=combatS.blockDelay}, Step = 0.01, Callback=function(v) combatS.blockDelay=v end 
})

sec_015:Toggle({ Title = "Double Block Tech", Flag = "combatDoubleBlock", Default = combatS.doubleBlock, Callback=function(on) combatS.doubleBlock=on end, Type = "Checkbox"})

sec_015:Toggle({ Title = "Anti-Bait", Flag = "combatAntiBait", Default = combatS.antiBait, Callback=function(on) combatS.antiBait=on end, Type = "Checkbox"})

sec_015:Slider({ Title = "Block Miss Chance %", Flag = "combatMissChance", Value = {Min=0,Max=100,Default=combatS.abMissChance}, Step = 1, Callback=function(v) combatS.abMissChance=v end 
})

local sec_016 = tabGuest1337:Section({ Title = "Auto Punch", Opened = true })

sec_016:Toggle({ Title = "Auto Punch", Flag = "combatAutoPunch", Default = combatS.autoPunchOn, Callback=function(on) combatS.autoPunchOn=on end, Type = "Checkbox"})

local sec_017 = tabGuest1337:Section({ Title = "HDT (Hitbox Dragging)", Opened = true })


sec_017:Toggle({ Title = "Enable HDT", Flag = "combatHDT", Default = combatS.hdtEnabled, Callback=function(on) combatS.hdtEnabled=on end, Type = "Checkbox"})

sec_017:Slider({ Title = "Sprint Speed", Flag = "combatHDTMoveSpeed", Value = {Min=1,Max=100,Default=combatS.hdtMoveSpeed}, Step = 1, Callback=function(v) combatS.hdtMoveSpeed=v end
})

sec_017:Slider({ Title = "Move Duration (s)", Flag = "combatHDTFlickDur", Value = {Min=0.1,Max=3.0,Default=combatS.hdtFlickDuration}, Step = 0.1, Callback=function(v) combatS.hdtFlickDuration=v end
})

sec_017:Slider({ Title = "HDT Miss Chance %", Flag = "combatHDTMiss", Value = {Min=0,Max=100,Default=combatS.hdtMissChance}, Step = 1, Callback=function(v) combatS.hdtMissChance=v end
})

local sec_018 = tabGuest1337:Section({ Title = "Vision", Opened = true })

sec_018:Toggle({ Title = "Detection Circles", Flag = "combatCircles", Default = combatS.killerCircles, Callback=function(on) 
        combatS.killerCircles=on
        if on then combatStartLoops() else combatUpdateCircles() end
    end, Type = "Checkbox"})

sec_018:Toggle({ Title = "Facing Check", Flag = "combatFacingCheck", Default = combatS.facingCheck, Callback=function(on) combatS.facingCheck=on end, Type = "Checkbox"})

sec_018:Toggle({ Title = "Facing Visual", Flag = "combatFacingVis", Default = combatS.facingVisual, Callback=function(on)
        combatS.facingVisual=on
        if on then combatStartLoops() end
    end, Type = "Checkbox"})

sec_018:Slider({ Title = "Facing Visual Size", Flag = "combatFacingSize", Value = {Min=1,Max=10,Default=combatS.facingVisRadius}, Step = 0.5, Callback=function(v)
        combatS.facingVisRadius=v
        for _, vis in pairs(combatFacingVisuals) do
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

local sec_019 = tabGuest1337:Section({ Title = "Aim Punch Lock", Opened = true })

sec_019:Toggle({ Title = "Aim Punch", Flag = "combatAimPunch", Default = combatS.aimPunchActive,
    Callback = function(on)
        combatS.aimPunchActive = on
        if on and lp.Character then combatSetupAimPunch(lp.Character) end
        if not on and combatAimConnection then combatAimConnection:Disconnect(); combatAimConnection = nil end
    end, Type = "Checkbox"})

sec_019:Slider({ Title = "Punch Prediction", Flag = "combatPunchPred", Step = 0.1,
    Value = { Min = 0, Max = 10, Default = combatS.punchPrediction },
    Callback = function(v) combatS.punchPrediction = v end })

sec_019:Slider({ Title = "Aim Duration (s)", Flag = "combatAimDur", Step = 0.05,
    Value = { Min = 0.1, Max = 2.0, Default = combatS.aimPunchDuration },
    Callback = function(v) combatS.aimPunchDuration = v end })

-- End of Guest1337 Combat Section