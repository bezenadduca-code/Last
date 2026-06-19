-- ══════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════
local playersService    = game:GetService("Players")
local userInputService  = game:GetService("UserInputService")
local runService        = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspaceService  = game:GetService("Workspace")
local statsService      = game:GetService("Stats")
local debrisService     = game:GetService("Debris")
local tweenService      = game:GetService("TweenService")
local soundService      = game:GetService("SoundService")

local clientPlayer = playersService.LocalPlayer
local PlayerGui    = clientPlayer:WaitForChild("PlayerGui", 10)

-- ══════════════════════════════════════════════
--  CONFIG SYSTEM
-- ══════════════════════════════════════════════
local fs = {
    hasFolder  = isfolder   or function() return false end,
    makeFolder = makefolder or function() end,
    write      = writefile  or function() end,
    hasFile    = isfile     or function() return false end,
    read       = readfile   or function() return "" end,
}
local cfg = {}
do
    local DIR  = "V1rpBlock"
    local FILE = DIR .. "/config.json"
    local hs   = game:GetService("HttpService")
    local function prep() if not fs.hasFolder(DIR) then fs.makeFolder(DIR) end end
    function cfg.load()
        prep()
        if not fs.hasFile(FILE) then return end
        local raw = fs.read(FILE)
        if not raw or raw == "" then return end
        local ok, t = pcall(hs.JSONDecode, hs, raw)
        if ok and type(t) == "table" then
            for k, v in pairs(t) do cfg._data[k] = v end
        end
    end
    function cfg.save()
        prep()
        local ok, s = pcall(hs.JSONEncode, hs, cfg._data)
        if ok and s and s ~= "" then pcall(fs.write, FILE, s) end
    end
    function cfg.get(k, default)
        local v = cfg._data[k]
        if v == nil then return default end
        return v
    end
    function cfg.set(k, v) cfg._data[k] = v; cfg.save() end
    cfg._data = {}
    cfg.load()
end

-- ══════════════════════════════════════════════
--  WIND UI + THEME
-- ══════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then error("WindUI failed to load") end

WindUI:AddTheme({
    Name = "RedGoldBlack",
    Accent = Color3.fromRGB(255, 215, 0),
    Background = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0,
    Outline = Color3.fromRGB(255, 215, 0),
    Text = Color3.fromRGB(255, 255, 255),
    Placeholder = Color3.fromRGB(200, 200, 200),
    Button = Color3.fromRGB(139, 0, 0),
    Icon = Color3.fromRGB(255, 215, 0),
    Hover = Color3.fromRGB(255, 215, 0),
    WindowBackground = Color3.fromRGB(0, 0, 0),
    WindowShadow = Color3.fromRGB(20, 20, 20),
    DialogBackground = Color3.fromRGB(0, 0, 0),
    DialogBackgroundTransparency = 0,
    DialogTitle = Color3.fromRGB(255, 215, 0),
    DialogContent = Color3.fromRGB(255, 255, 255),
    DialogIcon = Color3.fromRGB(255, 215, 0),
    WindowTopbarButtonIcon = Color3.fromRGB(255, 215, 0),
    WindowTopbarTitle = Color3.fromRGB(255, 255, 255),
    WindowTopbarAuthor = Color3.fromRGB(200, 200, 200),
    WindowTopbarIcon = Color3.fromRGB(255, 215, 0),
    TabBackground = Color3.fromRGB(20, 20, 20),
    TabTitle = Color3.fromRGB(255, 255, 255),
    TabIcon = Color3.fromRGB(255, 215, 0),
    ElementBackground = Color3.fromRGB(25, 25, 25),
    ElementTitle = Color3.fromRGB(255, 255, 255),
    ElementDesc = Color3.fromRGB(200, 200, 200),
    ElementIcon = Color3.fromRGB(255, 215, 0),
    PopupBackground = Color3.fromRGB(0, 0, 0),
    PopupBackgroundTransparency = 0,
    PopupTitle = Color3.fromRGB(255, 215, 0),
    PopupContent = Color3.fromRGB(255, 255, 255),
    PopupIcon = Color3.fromRGB(255, 215, 0),
    Toggle = Color3.fromRGB(139, 0, 0),
    ToggleBar = Color3.fromRGB(80, 80, 80),
    Checkbox = Color3.fromRGB(139, 0, 0),
    CheckboxIcon = Color3.fromRGB(255, 215, 0),
    Slider = Color3.fromRGB(139, 0, 0),
    SliderThumb = Color3.fromRGB(255, 215, 0),
})
WindUI:SetTheme("RedGoldBlack")

local Window = WindUI:CreateWindow({
    Title            = "V1PRBLOCK",
    Icon             = "sparkle",
    Author           = "Maintained By Viper",
    Folder           = "V1rpBlock",
    Size             = UDim2.fromOffset(420, 550),
    Transparent      = false,
    Theme            = "RedGoldBlack",
    Resizable        = true,
    SideBarWidth     = 160,
    HideSearchBar    = true,
    ScrollBarEnabled = true,
})
Window:SetToggleKey(Enum.KeyCode.K)
WindUI:SetFont("rbxasset://fonts/families/AccanthisADFStd.json")
Window:EditOpenButton({
    Title           = "V1PRBLOCK",
    Icon            = "sparkle",
    CornerRadius    = UDim.new(0, 16),
    StrokeThickness = 0,
    Color           = ColorSequence.new(Color3.fromHex("000000"), Color3.fromHex("000000")),
    OnlyMobile      = true,
    Enabled         = true,
    Draggable       = true,
})

-- ══════════════════════════════════════════════
--  VARIABLES  (cfg-backed)
-- ══════════════════════════════════════════════
local guestAutoBlockAudioOn          = cfg.get("guestAutoBlockAudioOn",          true)
local guestM1AutoBlockOn             = cfg.get("guestM1AutoBlockOn",             true)
local guestAutoPunchOn               = cfg.get("guestAutoPunchOn",               true)
local guestVerifyFacingCheckOn       = cfg.get("guestVerifyFacingCheckOn",       true)
local guestShowVisionRange           = cfg.get("guestShowVisionRange",           false)
local guestDetectionRange            = cfg.get("guestDetectionRange",            20)
local guestDetectionRangeSq          = guestDetectionRange * guestDetectionRange
local guestVisionRange               = cfg.get("guestVisionRange",               13.5)
local guestVisionAngle               = cfg.get("guestVisionAngle",               85)
local guestAimPunchActive            = cfg.get("guestAimPunchActive",            true)
local guestPunchPrediction           = cfg.get("guestPunchPrediction",           2.3)
local guestAimPunchDuration          = cfg.get("guestAimPunchDuration",          0.5)
local guestBlockCooldown             = cfg.get("guestBlockCooldown",             0.35)
local guestBlockDelay                = cfg.get("guestBlockDelay",                0)
local guestAutoPunchDelay            = cfg.get("guestAutoPunchDelay",            0.3)
local guestBetterDetectionEnabled    = cfg.get("guestBetterDetectionEnabled",    false)
local guestBetterDetectionX          = cfg.get("guestBetterDetectionX",          3)
local guestBetterDetectionY          = cfg.get("guestBetterDetectionY",          2.5)
local guestBetterDetectionZ          = cfg.get("guestBetterDetectionZ",          4)
local guestBetterDetectionMultiplier = cfg.get("guestBetterDetectionMultiplier", 2.4)
local guestBetterDetectionSegments   = cfg.get("guestBetterDetectionSegments",   14)
local guestBetterStartDist           = cfg.get("guestBetterStartDist",           2.2)
local guestBetterStepDist            = cfg.get("guestBetterStepDist",            0.05)
local guestBetterPreDelay            = cfg.get("guestBetterPreDelay",            0.15)
local guestBetterStagger             = cfg.get("guestBetterStagger",             0.03)
local guestBetterPredForward         = cfg.get("guestBetterPredForward",         1.1)
local guestBetterPredTurn            = cfg.get("guestBetterPredTurn",            1.2)
local guestReverseEnabled            = cfg.get("guestReverseEnabled",            false)
local guestLegacyFacingEnabled       = cfg.get("guestLegacyFacingEnabled",       false)
local guestLegacyVisionRange         = cfg.get("guestLegacyVisionRange",         13.5)
local guestLegacyVisionAngle         = cfg.get("guestLegacyVisionAngle",         85)
local guestLegacyShowVisionRange     = cfg.get("guestLegacyShowVisionRange",     false)
local guestCinematicTextEnabled      = cfg.get("guestCinematicTextEnabled",      false)
local guestCinematicText             = cfg.get("guestCinematicText",             "PARRY!")
local guestSmartDelayEnabled         = cfg.get("guestSmartDelayEnabled",         false)
local guestManualDragEnabled         = cfg.get("guestManualDragEnabled",         false)
local pingCheckerEnabled             = cfg.get("pingCheckerEnabled",             false)
local noHDTCooldown                  = cfg.get("noHDTCooldown",                  false)
local hdtCooldownCheckerEnabled      = cfg.get("hdtCooldownChecker",             false)
local noclipEnabled                  = cfg.get("noclipEnabled",                  false)
local noclipOnlyWhenBlockReady       = cfg.get("noclipOnlyWhenBlockReady",       false)
local fpsCounterEnabled              = cfg.get("fpsCounterEnabled",              false)
local customPunchSoundId             = cfg.get("customPunchSoundId",             0)
local punchMobilityEnabled           = cfg.get("punchMobilityEnabled",           false)
local chargeControlEnabled           = cfg.get("chargeControlEnabled",           false)
local lungeBoostEnabled              = cfg.get("lungeBoostEnabled",              false)
local lungeMultiplier                = cfg.get("lungeMultiplier",                1.0)
local chargeSpeedCapEnabled          = cfg.get("chargeSpeedCapEnabled",          false)
local chargeSpeedLimit               = cfg.get("chargeSpeedLimit",               12)
local guestHitboxDraggingOn          = cfg.get("guestHitboxDraggingOn",          false)
local guestHitboxMode                = cfg.get("guestHitboxMode",                "Blatant")
local guestHitboxFaceKiller          = cfg.get("guestHitboxFaceKiller",          false)
local guestHitboxVisual              = cfg.get("guestHitboxVisual",              false)
local guestHitboxTargetMode          = cfg.get("guestHitboxTargetMode",          "Root")
local guestHitboxDragDuration        = cfg.get("guestHitboxDragDuration",        1.0)
local guestHitboxTriggerRadius       = cfg.get("guestHitboxTriggerRadius",       15)
local guestShowHDTRange              = cfg.get("guestShowHDTRange",              false)
local hdtPredictTime                 = cfg.get("hdtPredictTime",                 0.12)
local hdtSwitchDist                  = cfg.get("hdtSwitchDist",                  8)

-- ══════════════════════════════════════════════
--  LINEBLOCK VARIABLES
-- ══════════════════════════════════════════════
local lineBlockEnabled        = cfg.get("lineBlockEnabled",        false)
local lineBlockLength         = cfg.get("lineBlockLength",         15)
local lineBlockRadius         = cfg.get("lineBlockRadius",         1.5)
local lineBlockDelay          = cfg.get("lineBlockDelay",          0.05)
local lineBlockFacingDuration = cfg.get("lineBlockFacingDuration", 0.1)
local lineBlockMinDot         = cfg.get("lineBlockMinDot",         0.5)

local lineBlockParts          = {}
local lineKillerFacingSince   = {}
local lineBlockPendingKillers = {}
local lineBlockAnimConns      = {}
local lineBlockLastBlockTime  = 0
-- Must be declared before guestAttemptBlockForSound so the closure captures it
local lineBlockSoundKillers   = {}

-- ══════════════════════════════════════════════
--  SOUND / ANIM ID TABLES
-- ══════════════════════════════════════════════
local guestAutoBlockTriggerSounds = {
    ["102228729296384"]=true,["140242176732868"]=true,["112809109188560"]=true,["136323728355613"]=true,
    ["115026634746636"]=true,["84116622032112"]=true, ["108907358619313"]=true,["127793641088496"]=true,
    ["86174610237192"]=true, ["95079963655241"]=true, ["101199185291628"]=true,["119942598489800"]=true,
    ["84307400688050"]=true, ["113037804008732"]=true,["105200830849301"]=true,["75330693422988"]=true,
    ["82221759983649"]=true, ["109348678063422"]=true,["81702359653578"]=true, ["85853080745515"]=true,
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
    ["136728245733659"]=true,["71310583817000"]=true, ["107444859834748"]=true,["76959687420003"]=true,
    ["72425554233832"]=true, ["96594507550917"]=true, ["139996647355899"]=true,["107345261604889"]=true,
    ["127557531826290"]=true,["108651070773439"]=true,["74842815979546"]=true, ["124397369810639"]=true,
    ["76467993976301"]=true, ["118493324723683"]=true,["78298577002481"]=true, ["116527305931161"]=true,
    ["5148302439"]=true,     ["98675142200448"]=true, ["128367348686124"]=true,["71805956520207"]=true,
    ["125213046326879"]=true,["84353899757208"]=true, ["103684883268194"]=true,["109246041199659"]=true,
    ["80540530406270"]=true, ["139523195429581"]=true,["105204810054381"]=true,["114742322778642"]=true,
    ["116468089135195"]=true,
}

local guestM1AutoBlockTriggerSounds = {
    ["112809109188560"]=true,["117173212095661"]=true,["140242176732868"]=true,["109348678063422"]=true,
    ["104910828105172"]=true,["119583605486352"]=true,["79980897195554"]=true,["80516583309685"]=true,
    ["115026634746636"]=true,
}

local guestTrackedPunchAnimations = {
    ["87259391926321"]=true,["140703210927645"]=true,["136007065400978"]=true,["129843313690921"]=true,
    ["86709774283672"]=true, ["108807732150251"]=true,["138040001965654"]=true,["86096387000557"]=true,
    ["81905101227053"]=true, ["127777649118195"]=true,["99100240941590"]=true, ["92831180929659"]=true,
    ["112081768119093"]=true,["117587689359268"]=true,["91830732867282"]=true, ["91730605416216"]=true,
    ["100184164753080"]=true,
}

local guestAimTargets = {"Slasher","c00lkidd","JohnDoe","1x1x1x1","Noli","Sixer","Nosferatu"}

-- ══════════════════════════════════════════════
--  RUNTIME STATE
-- ══════════════════════════════════════════════
local guestHumanoid, guestHRP                        = nil, nil
local guestPunchAiming                               = false
local guestPunchLastTriggerTime                      = 0
local guestOriginalWS, guestOriginalJP               = nil, nil
local guestOriginalAutoRotate                        = nil
local guestAimConnection                             = nil
local guestSoundHooks                                = {}
local guestSoundBlockedUntil                         = {}
local guestLastBlockTime                             = 0
local guestSoundBlockDuration                        = 0.5
local guestKillerState                               = {}
local cinematicGui                                   = nil
local hdtRangePart                                   = nil
local pingLabel                                      = nil
local hdtCooldownGui, hdtCooldownLabel               = nil, nil
local fpsGui, fpsLabel                               = nil, nil
local guestCenterPart, guestLeftPart, guestRightPart = nil, nil, nil
local guestLeftToKillerPart, guestRightToKillerPart  = nil, nil
local guestLeftToCenterPart, guestCenterToRightPart  = nil, nil

-- Punch controller state
local BASE_SPEED          = 12
local BASE_PUNCH_FORCE    = 40
local PUNCH_WINDUP        = 0.7
local PARRY_WINDUP        = 0.4
local isCharging          = false
local lungeActive         = false
local lungeThread         = nil
local noclipConn          = nil
local networkHooked       = false
local originalFireConn    = nil
local pinnedConns         = {}
local chargePinnedConns   = {}
local chargeCapConn       = nil
local chargeWatcher       = nil
local descendantConn      = nil

local PRED_SECONDS_FORWARD = 0.25
local PRED_SECONDS_LATERAL = 0.18
local PRED_MAX_FORWARD     = 6
local PRED_MAX_LATERAL     = 4
local ANG_TURN_MULTIPLIER  = 0.6
local SMOOTHING_LERP       = 0.22

-- FPS tracking
local lastFpsUpdate = 0
local frameCount    = 0
local fps           = 0

local guestRemoteEvent = replicatedStorage.Modules.Network.Network:FindFirstChild("RemoteEvent")
if not guestRemoteEvent then
    guestRemoteEvent = replicatedStorage.Modules.Network.Network:WaitForChild("RemoteEvent", 10)
end

-- ══════════════════════════════════════════════
--  SMALL HELPERS
-- ══════════════════════════════════════════════
local function getRootPart()
    local char = clientPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = clientPlayer.Character
    return char and char:FindFirstChild("Humanoid")
end

local function isParryMode()
    return false
end

-- ══════════════════════════════════════════════
--  BLOCK READY GATE
-- ══════════════════════════════════════════════
local function isBlockReady()
    if noHDTCooldown then return true end
    local mainUI = PlayerGui:FindFirstChild("MainUI")
    if mainUI then
        local abilityContainer = mainUI:FindFirstChild("AbilityContainer")
        if abilityContainer then
            local block = abilityContainer:FindFirstChild("Block")
            if block then
                local cooldownTime = block:FindFirstChild("CooldownTime")
                if cooldownTime and cooldownTime:IsA("TextLabel") then
                    local num = cooldownTime.Text:match("[%d%.]+")
                    if num then
                        local val = tonumber(num)
                        return not val or val <= 0
                    end
                    return true
                end
            end
        end
    end
    return tick() - guestLastBlockTime >= guestBlockCooldown
end

-- ══════════════════════════════════════════════
--  GENERAL HELPERS
-- ══════════════════════════════════════════════
local function guestExtractNumericSoundId(sound)
    if not sound then return nil end
    local sid = tostring(sound.SoundId)
    local num = sid:match("%d+")
    if num then return num end
    local hash = sid:match("[&%?]hash=([^&]+)")
    if hash then return "&hash=" .. hash end
    local path = sid:match("rbxasset://sounds/.+")
    if path then return path end
    return nil
end

local function guestGetSoundWorldPosition(sound)
    if not sound then return nil end
    if sound.Parent and sound.Parent:IsA("BasePart") then
        return sound.Parent.Position, sound.Parent
    end
    if sound.Parent and sound.Parent:IsA("Attachment")
        and sound.Parent.Parent and sound.Parent.Parent:IsA("BasePart") then
        return sound.Parent.Parent.Position, sound.Parent.Parent
    end
    local found = sound.Parent and sound.Parent:FindFirstChildWhichIsA("BasePart", true)
    if found then return found.Position, found end
    return nil, nil
end

local function guestGetCharacterFromDescendant(inst)
    if not inst then return nil end
    local model = inst:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        local killersFolder = workspaceService:FindFirstChild("Players")
            and workspaceService.Players:FindFirstChild("Killers")
        if killersFolder and model:IsDescendantOf(killersFolder) then
            return model
        end
    end
    return nil
end

local function isPointInsidePart(part, point)
    if not part or not point then return false end
    local rel  = part.CFrame:PointToObjectSpace(point)
    local half = part.Size * 0.5
    return math.abs(rel.X) <= half.X + 0.001
       and math.abs(rel.Y) <= half.Y + 0.001
       and math.abs(rel.Z) <= half.Z + 0.001
end

local function findHitboxPart(killerModel)
    local globalHitboxes = workspaceService:FindFirstChild("Hitboxes")
    if globalHitboxes then
        local bestPart, bestVol = nil, 0
        for _, child in ipairs(globalHitboxes:GetChildren()) do
            if child:IsA("BasePart") then
                local vol = child.Size.X * child.Size.Y * child.Size.Z
                if vol > bestVol then bestVol = vol; bestPart = child end
            end
        end
        if bestPart then return bestPart end
    end
    local hitboxesFolder = killerModel:FindFirstChild("Hitboxes")
    if hitboxesFolder then
        for _, child in ipairs(hitboxesFolder:GetChildren()) do
            if child:IsA("BasePart") then return child end
        end
    end
    for _, child in ipairs(killerModel:GetDescendants()) do
        if child:IsA("BasePart") and child.Name:lower():find("hitbox") then
            return child
        end
    end
    return nil
end

-- Returns the killer's QueryHitbox BasePart, or nil if absent.
-- Path: workspace.Players.Survivors.<KillerName>.QueryHitbox
local function getQueryHitbox(killerModel)
    if not killerModel then return nil end
    -- Direct child first (most common)
    local qh = killerModel:FindFirstChild("QueryHitbox")
    if qh and qh:IsA("BasePart") then return qh end
    -- Also check one level deep (some killers nest it)
    for _, child in ipairs(killerModel:GetChildren()) do
        local nested = child:FindFirstChild("QueryHitbox")
        if nested and nested:IsA("BasePart") then return nested end
    end
    return nil
end

-- Returns the best position to use for range checks for a given killer.
-- Prefers QueryHitbox; falls back to HRP.
local function getKillerDetectionPosition(killerModel)
    if not killerModel then return nil end
    local qh = getQueryHitbox(killerModel)
    if qh then return qh.Position, qh end
    local hrp = killerModel:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position, hrp end
    return nil, nil
end

-- ══════════════════════════════════════════════
--  REMOTES
-- ══════════════════════════════════════════════
local function guestFireRemoteBlock()
    if not guestRemoteEvent then return end
    guestRemoteEvent:FireServer("UseActorAbility", { [1] = buffer.fromstring("\3\5\0\0\0Block") })
end

local function guestFireRemotePunch()
    if not guestRemoteEvent then return end
    if customPunchSoundId and customPunchSoundId ~= 0 then
        pcall(function()
            local snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://" .. tostring(customPunchSoundId)
            snd.Volume = 1
            snd.Parent = soundService
            snd:Play()
            debrisService:AddItem(snd, 3)
        end)
    end
    guestRemoteEvent:FireServer("UseActorAbility", { [1] = buffer.fromstring("\3\5\0\0\0Punch") })
end

-- ══════════════════════════════════════════════
--  CINEMATIC TEXT
-- ══════════════════════════════════════════════
local function showCinematicText()
    if not guestCinematicTextEnabled then return end
    if cinematicGui then cinematicGui:Destroy(); cinematicGui = nil end
    local gui = Instance.new("ScreenGui")
    gui.Name = "CinematicText"; gui.Parent = PlayerGui
    gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 10000
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 100)
    lbl.Position = UDim2.new(0, 0, 0.4, -50)
    lbl.BackgroundTransparency = 1
    lbl.Text = guestCinematicText
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 0.3
    lbl.TextSize = 60; lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true; lbl.RichText = true; lbl.Parent = gui
    cinematicGui = gui
    task.delay(1.5, function()
        if cinematicGui then cinematicGui:Destroy(); cinematicGui = nil end
    end)
end

-- ══════════════════════════════════════════════
--  HITBOX DRAGGING (HDT) — Improved
-- ══════════════════════════════════════════════
--  Improvements:
--   • Per-frame velocity prediction so the drag always leads the target
--   • "Smart" mode auto-selects Legit vs Blatant based on distance
--   • Blatant uses AssemblyLinearVelocity instead of BodyVelocity for
--     smoother physics and less jitter
--   • Face-killer torque uses CFrame lerp rather than hard-snap
--   • Beam visual is rebuilt only when needed (no recreation each frame)
--   • OVERRIDE mode: locks all movements to drag into killer only
--   • BLOCK validation: invalidates drag if no block within 26.5 seconds
-- ══════════════════════════════════════════════
local function guestPerformHitboxDrag(killerModel)
    if not guestHitboxDraggingOn or not killerModel then return end

    -- Wait until block cooldown is completely over before starting HDT
    if not isBlockReady() then
        task.spawn(function()
            local maxWait = 0
            while not isBlockReady() and maxWait < 30 do
                task.wait(0.1)
                maxWait = maxWait + 0.1
            end
            if isBlockReady() and guestHitboxDraggingOn and killerModel.Parent then
                guestPerformHitboxDrag(killerModel)
            end
        end)
        return
    end

    local dragMode   = guestHitboxMode
    local faceKiller = guestHitboxFaceKiller
    local visual     = guestHitboxVisual
    local targetMode = guestHitboxTargetMode
    local duration   = guestHitboxDragDuration

    -- Resolve target part
    local targetPart
    if dragMode == "Hitbox" then
        targetPart = findHitboxPart(killerModel)
        if not targetPart then dragMode = "Blatant" end
    end

    if not targetPart then
        if targetMode == "Arms" or targetMode == "Random" then
            local armNames = {
                "Right Arm","Left Arm","RightHand","LeftHand",
                "RightUpperArm","LeftUpperArm"
            }
            local arms = {}
            for _, name in ipairs(armNames) do
                local arm = killerModel:FindFirstChild(name)
                if arm and arm:IsA("BasePart") then table.insert(arms, arm) end
            end
            if #arms > 0 then
                if targetMode == "Arms" then
                    targetPart = arms[1]
                else
                    local root = killerModel:FindFirstChild("HumanoidRootPart")
                        or killerModel:FindFirstChild("Torso")
                    targetPart = (math.random() < 0.5) and root or arms[math.random(#arms)]
                end
            end
        end
        if not targetPart then
            targetPart = killerModel:FindFirstChild("HumanoidRootPart")
                      or killerModel:FindFirstChild("Torso")
        end
        if not targetPart then
            for _, child in ipairs(killerModel:GetDescendants()) do
                if child:IsA("BasePart") then targetPart = child; break end
            end
        end
    end
    if not targetPart then return end

    local myChar     = clientPlayer.Character
    local myHumanoid = myChar and myChar:FindFirstChild("Humanoid")
    local myRoot     = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHumanoid or not myRoot then return end

    -- Auto-select mode when set to Smart
    local resolvedMode = dragMode
    if resolvedMode == "Smart" then
        local dist = (targetPart.Position - myRoot.Position).Magnitude
        resolvedMode = (dist <= hdtSwitchDist) and "Legit" or "Blatant"
    end

    -- Shared: save state
    local origWS = myHumanoid.WalkSpeed
    local origAR = myHumanoid.AutoRotate

    -- Beam helper (shared)
    local beam
    local function makeBeam()
        if not visual then return end
        beam = Instance.new("Part")
        beam.Size        = Vector3.new(0.3, 0.3, 1)
        beam.Anchored    = true
        beam.CanCollide  = false
        beam.Material    = Enum.Material.Neon
        beam.Transparency = 0.3
        beam.Color       = Color3.fromRGB(255, 215, 0)
        beam.Parent      = workspaceService
        debrisService:AddItem(beam, duration + 0.15)
    end
    local function updateBeam()
        if not beam or not beam.Parent then return end
        if not myRoot or not myRoot.Parent or not targetPart.Parent then return end
        local p1, p2 = myRoot.Position, targetPart.Position
        local mid     = (p1 + p2) * 0.5
        local dist    = (p2 - p1).Magnitude
        beam.Size     = Vector3.new(0.3, 0.3, dist)
        beam.CFrame   = CFrame.new(mid, p2)
    end

    local startTime = tick()
    local blockCheckTime = 26.5
    local hasBlockedDuringDrag = false
    local lastBlockTimeSnapshot = guestLastBlockTime

    if resolvedMode == "Legit" then
        local legitSpeed = cfg.get("hdtLegitSpeed", 140)
        myHumanoid.AutoRotate = false
        myHumanoid.WalkSpeed  = legitSpeed
        makeBeam()
        WindUI:Notify({Title="HDT (Legit)", Content="Duration: "..duration.."s", Duration=2})

        local conn
        conn = runService.Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            
            -- Check if block occurred during this drag
            if guestLastBlockTime > lastBlockTimeSnapshot then
                hasBlockedDuringDrag = true
            end
            
            -- Block validation: if 26.5 seconds passed with no block, invalidate drag
            if elapsed >= blockCheckTime and not hasBlockedDuringDrag then
                conn:Disconnect()
                myHumanoid.WalkSpeed  = origWS
                myHumanoid.AutoRotate = origAR
                WindUI:Notify({Title="HDT Invalidated", Content="No block detected in 26.5s", Duration=2})
                return
            end
            
            if elapsed >= duration
               or not guestHitboxDraggingOn
               or not targetPart.Parent
               or not myHumanoid.Parent
            then
                conn:Disconnect()
                myHumanoid.WalkSpeed  = origWS
                myHumanoid.AutoRotate = origAR
                return
            end
            
            -- OVERRIDE: Force movement toward killer only
            local state   = guestKillerState[killerModel]
            local predVel = state and state.vel or Vector3.zero
            local predPos = targetPart.Position + predVel * hdtPredictTime
            local dirToTarget = (predPos - myRoot.Position)
            
            -- Override all horizontal movement to drag direction
            if dirToTarget.Magnitude > 0.1 then
                local dragDir = dirToTarget.Unit
                -- Force movement exclusively toward killer (no other input)
                myHumanoid:MoveTo(predPos)
            end
            
            if faceKiller then
                local dir = (targetPart.Position - myRoot.Position)
                if dir.Magnitude > 0.1 then
                    myRoot.CFrame = myRoot.CFrame:Lerp(
                        CFrame.new(myRoot.Position, myRoot.Position + dir.Unit), 0.35)
                end
            end
            updateBeam()
        end)

    else -- Blatant / Hitbox → use AssemblyLinearVelocity (smoother than BodyVelocity)
        local blatantSpeed = cfg.get("hdtBlatantSpeed", 150)
        myHumanoid.WalkSpeed  = 0
        myHumanoid.AutoRotate = false
        makeBeam()
        WindUI:Notify({Title="HDT (Blatant)", Content="Duration: "..duration.."s", Duration=2})

        local conn
        conn = runService.Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            
            -- Check if block occurred during this drag
            if guestLastBlockTime > lastBlockTimeSnapshot then
                hasBlockedDuringDrag = true
            end
            
            -- Block validation: if 26.5 seconds passed with no block, invalidate drag
            if elapsed >= blockCheckTime and not hasBlockedDuringDrag then
                conn:Disconnect()
                myRoot.AssemblyLinearVelocity = Vector3.zero
                myHumanoid.WalkSpeed          = origWS
                myHumanoid.AutoRotate         = origAR
                WindUI:Notify({Title="HDT Invalidated", Content="No block detected in 26.5s", Duration=2})
                return
            end
            
            if elapsed >= duration
               or not guestHitboxDraggingOn
               or not targetPart.Parent
               or not myHumanoid.Parent
               or not myRoot.Parent
            then
                conn:Disconnect()
                myRoot.AssemblyLinearVelocity = Vector3.zero
                myHumanoid.WalkSpeed          = origWS
                myHumanoid.AutoRotate         = origAR
                return
            end
            
            -- OVERRIDE: Force all movement toward killer
            local state   = guestKillerState[killerModel]
            local predVel = state and state.vel or Vector3.zero
            local predPos = targetPart.Position + predVel * hdtPredictTime
            local dir     = (predPos - myRoot.Position)
            
            if dir.Magnitude > 0.1 then
                -- Scale speed down as we get close to avoid overshooting
                local dist    = dir.Magnitude
                local speed   = math.min(blatantSpeed, dist * 12)
                local curVel  = myRoot.AssemblyLinearVelocity
                local desired = dir.Unit * speed
                
                -- OVERRIDE: Force horizontal velocity ONLY toward target, preserve Y velocity
                -- This locks the player into dragging motion, overriding any other input
                myRoot.AssemblyLinearVelocity = Vector3.new(
                    desired.X, curVel.Y, desired.Z)
            else
                -- At target: stop horizontal movement, preserve gravity
                myRoot.AssemblyLinearVelocity = Vector3.new(
                    0, myRoot.AssemblyLinearVelocity.Y, 0)
            end
            
            if faceKiller then
                local fd = (targetPart.Position - myRoot.Position)
                if fd.Magnitude > 0.1 then
                    myRoot.CFrame = myRoot.CFrame:Lerp(
                        CFrame.new(myRoot.Position, myRoot.Position + fd.Unit), 0.4)
                end
            end
            updateBeam()
        end)
    end
end

-- ══════════════════════════════════════════════
--  BETTER DETECTION  (fixed — no preset system,
--  simple X/Y/Z * multiplier like script 2)
-- ══════════════════════════════════════════════
local function guestSpawnBetterDetection(killerModel)
    if not killerModel or not guestBetterDetectionEnabled then return end
    local hrp = killerModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local state = guestKillerState[killerModel]
    if not state then return end

    local size  = Vector3.new(
        guestBetterDetectionX,
        guestBetterDetectionY,
        guestBetterDetectionZ
    ) * guestBetterDetectionMultiplier
    local count = math.max(1, guestBetterDetectionSegments)

    -- Use QueryHitbox as the forward-cast origin if present
    local qh      = getQueryHitbox(killerModel)
    local origin  = qh or hrp

    local vel    = state.vel    or Vector3.zero
    local angVel = state.angVel or 0
    local snapPos = origin.Position
    local snapCF  = origin.CFrame

    local fwdSpd = vel:Dot(snapCF.LookVector)
    local latSpd = vel:Dot(snapCF.RightVector)
    local trnLat = angVel * ANG_TURN_MULTIPLIER * guestBetterPredTurn

    local fwdPred = math.clamp(
        fwdSpd * PRED_SECONDS_FORWARD * guestBetterPredForward,
        -PRED_MAX_FORWARD, PRED_MAX_FORWARD)
    local latPred = math.clamp(
        (latSpd * PRED_SECONDS_LATERAL + trnLat) * guestBetterPredForward,
        -PRED_MAX_LATERAL, PRED_MAX_LATERAL)

    task.spawn(function()
        if guestBetterPreDelay > 0 then task.wait(guestBetterPreDelay) end
        for i = 1, count do
            if not origin or not origin.Parent then break end
            local t        = (i - 1) / math.max(count - 1, 1)
            local dist     = guestBetterStartDist + (i - 1) * guestBetterStepDist + fwdPred
            local lerpPos  = snapPos:Lerp(origin.Position, t * 0.4)
            local spawnPos = lerpPos
                           + snapCF.LookVector  * dist
                           + snapCF.RightVector * latPred

            local part = Instance.new("Part")
            part.Name         = "BetterDetection"
            part.Size         = size
            part.Anchored     = true
            part.CanCollide   = false
            part.CanTouch     = true
            part.Transparency = 0.75
            part.Color        = Color3.fromRGB(0, 150, 255)
            part.Material     = Enum.Material.ForceField
            part.CFrame       = CFrame.lookAt(spawnPos, lerpPos)
            part.Parent       = workspaceService
            debrisService:AddItem(part, 0.15)

            if guestHRP and isPointInsidePart(part, guestHRP.Position) then
                guestFireRemoteBlock()
                guestLastBlockTime = tick()
                if guestAutoPunchOn then task.delay(guestAutoPunchDelay, guestFireRemotePunch) end
                showCinematicText()
                break
            end

            if i < count and guestBetterStagger > 0 then task.wait(guestBetterStagger) end
        end
    end)
end

-- ══════════════════════════════════════════════
--  BLOCK LOGIC  (no block box, no sphere)
-- ══════════════════════════════════════════════
local function guestAttemptBlock(killerModel)
    if not guestAutoBlockAudioOn then return end
    if not isBlockReady() then return end

    local myChar = clientPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not killerModel then return end

    -- Require at least an HRP to validate the killer is still alive
    if not killerModel:FindFirstChild("HumanoidRootPart") then return end

    task.delay(guestBlockDelay, function()
        if not myChar:FindFirstChild("HumanoidRootPart") or not killerModel.Parent then return end
        if not isBlockReady() then return end

        -- Use QueryHitbox if available, otherwise fall back to HRP
        local detPos = getKillerDetectionPosition(killerModel)
        if not detPos then return end

        local dist = (detPos - myRoot.Position).Magnitude
        if dist > guestDetectionRange then return end

        -- HDT trigger
        if guestHitboxDraggingOn and dist <= guestHitboxTriggerRadius then
            guestPerformHitboxDrag(killerModel)
        end

        guestFireRemoteBlock()
        guestLastBlockTime = tick()
        if guestAutoPunchOn then task.delay(guestAutoPunchDelay, guestFireRemotePunch) end
        showCinematicText()
    end)
end

local function guestAttemptBlockForSound(sound, preId)
    if not guestAutoBlockAudioOn and not guestM1AutoBlockOn then return end
    if not sound or not sound:IsA("Sound") then return end

    local id = preId or guestExtractNumericSoundId(sound)
    local isNormalBlock = guestAutoBlockAudioOn and guestAutoBlockTriggerSounds[id]
    local isM1Block = guestM1AutoBlockOn and guestM1AutoBlockTriggerSounds[id]
    
    if not id or (not isNormalBlock and not isM1Block) then return end

    if not isBlockReady() then return end
    if guestSoundBlockedUntil[sound] and tick() < guestSoundBlockedUntil[sound] then return end

    local myChar = clientPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local _, soundPart = guestGetSoundWorldPosition(sound)
    if not soundPart then return end

    local killerModel = guestGetCharacterFromDescendant(soundPart)
    if not killerModel then return end

    -- Mark this killer for lineblock's sound window
    lineBlockSoundKillers[killerModel] = tick()
    task.delay(0.35, function()
        if lineBlockSoundKillers[killerModel]
            and tick() - lineBlockSoundKillers[killerModel] >= 0.35 then
            lineBlockSoundKillers[killerModel] = nil
        end
    end)

    local hrp = killerModel:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Use QueryHitbox for distance check if available
    local detPos = getKillerDetectionPosition(killerModel) or hrp.Position
    local distSq   = (detPos - myRoot.Position).Magnitude ^ 2
    local pingComp       = 0.2 * guestDetectionRange
    local effectiveRange = guestDetectionRange + pingComp

    if distSq > effectiveRange * effectiveRange then return end

    if guestVerifyFacingCheckOn then
        local ok, result = pcall(function()
            local dirToPlayer = (myRoot.Position - hrp.Position).Unit
            local dot         = hrp.CFrame.LookVector:Dot(dirToPlayer)
            local cosAngle    = math.cos(math.rad(guestVisionAngle / 2))
            return distSq < 25 or dot >= cosAngle
        end)
        if not ok or not result then return end
    end

    -- Use better detection OR normal block — never both
    if guestBetterDetectionEnabled then
        guestLastBlockTime = tick()
        guestSpawnBetterDetection(killerModel)
    else
        guestAttemptBlock(killerModel)
    end

    guestSoundBlockedUntil[sound] = tick() + guestSoundBlockDuration
end

-- ══════════════════════════════════════════════
--  SOUND HOOKS
-- ══════════════════════════════════════════════
local function guestHookSound(sound)
    if not sound or not sound:IsA("Sound") or guestSoundHooks[sound] then return end
    local preId = guestExtractNumericSoundId(sound)
    if not preId then return end

    local playedConn = sound.Played:Connect(function()
        if guestAutoBlockAudioOn then task.spawn(guestAttemptBlockForSound, sound, preId) end
    end)
    local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying and guestAutoBlockAudioOn then
            task.spawn(guestAttemptBlockForSound, sound, preId)
        end
    end)
    local destroyConn; destroyConn = sound.Destroying:Connect(function()
        pcall(function()
            playedConn:Disconnect(); propConn:Disconnect(); destroyConn:Disconnect()
        end)
        guestSoundHooks[sound]        = nil
        guestSoundBlockedUntil[sound] = nil
    end)
    guestSoundHooks[sound] = {playedConn, propConn, destroyConn, id = preId}
    if sound.IsPlaying then task.spawn(guestAttemptBlockForSound, sound, preId) end
end

local function guestHookExistingSounds()
    local kf = workspaceService:FindFirstChild("Players")
        and workspaceService.Players:FindFirstChild("Killers")
    if kf then
        for _, killer in pairs(kf:GetChildren()) do
            for _, desc in pairs(killer:GetDescendants()) do
                if desc:IsA("Sound") then pcall(guestHookSound, desc) end
            end
        end
    end
end

local function guestSetupSoundHooks()
    task.spawn(function()
        local playersFolder = workspaceService:FindFirstChild("Players")
        if not playersFolder then
            playersFolder = workspaceService:WaitForChild("Players", 30)
        end
        if not playersFolder then return end

        local kf = playersFolder:FindFirstChild("Killers")
        if not kf then kf = playersFolder:WaitForChild("Killers", 30) end
        if not kf then return end

        guestHookExistingSounds()

        kf.DescendantAdded:Connect(function(desc)
            if desc:IsA("Sound") then pcall(guestHookSound, desc) end
        end)
        kf.ChildAdded:Connect(function(killer)
            task.wait(0.1)
            for _, desc in pairs(killer:GetDescendants()) do
                if desc:IsA("Sound") then pcall(guestHookSound, desc) end
            end
        end)
    end)
end

-- ══════════════════════════════════════════════
--  VISUAL UPDATERS
-- ══════════════════════════════════════════════
local function updateHDTRange()
    if not guestShowHDTRange or not guestHRP then
        if hdtRangePart then hdtRangePart:Destroy(); hdtRangePart = nil end
        return
    end
    if not hdtRangePart then
        hdtRangePart = Instance.new("Part")
        hdtRangePart.Anchored     = true
        hdtRangePart.CanCollide   = false
        hdtRangePart.Shape        = Enum.PartType.Ball
        hdtRangePart.Transparency = 0.5
        hdtRangePart.Color        = Color3.fromRGB(255, 255, 0)
        hdtRangePart.Material     = Enum.Material.ForceField
        hdtRangePart.Parent       = workspaceService
    end
    local r = guestHitboxTriggerRadius
    hdtRangePart.Size   = Vector3.new(r * 2, r * 2, r * 2)
    hdtRangePart.CFrame = CFrame.new(guestHRP.Position)
end

local function updatePingChecker()
    if not pingCheckerEnabled then
        if pingLabel then pingLabel.Parent.Parent:Destroy(); pingLabel = nil end
        return
    end
    if not pingLabel then
        local sg = Instance.new("ScreenGui")
        sg.Name = "PingChecker"; sg.Parent = PlayerGui
        sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder = 9998
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(0, 150, 0, 40); fr.Position = UDim2.new(0, 10, 1, -50)
        fr.BackgroundColor3 = Color3.fromRGB(0, 0, 0); fr.BackgroundTransparency = 0.5
        fr.BorderSizePixel = 0; fr.Parent = sg
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -10, 1, -10); tl.Position = UDim2.new(0, 5, 0, 5)
        tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.fromRGB(255, 255, 255)
        tl.Text = "Ping: 0ms"; tl.Font = Enum.Font.GothamBold; tl.TextSize = 18; tl.Parent = fr
        pingLabel = tl
    end
    local ping = statsService.Network.ServerStatsItem["Data Ping"]:GetValue()
    pingLabel.Text = "Ping: " .. math.floor(ping) .. "ms"
end

local function updateHDTCooldownChecker()
    if not hdtCooldownCheckerEnabled then
        if hdtCooldownGui then hdtCooldownGui:Destroy(); hdtCooldownGui = nil end
        return
    end
    if not hdtCooldownGui then
        local sg = Instance.new("ScreenGui")
        sg.Name = "HDTCooldownChecker"; sg.Parent = PlayerGui
        sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder = 9998
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(0, 150, 0, 40); fr.Position = UDim2.new(0, 10, 0, 100)
        fr.BackgroundColor3 = Color3.fromRGB(0, 0, 0); fr.BackgroundTransparency = 0.5
        fr.BorderSizePixel = 0; fr.Parent = sg
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -10, 1, -10); tl.Position = UDim2.new(0, 5, 0, 5)
        tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.fromRGB(255, 255, 255)
        tl.Text = "Block CD: ?"; tl.Font = Enum.Font.GothamBold; tl.TextSize = 18; tl.Parent = fr
        hdtCooldownGui = sg; hdtCooldownLabel = tl
    end
    local mainUI = PlayerGui:FindFirstChild("MainUI")
    if mainUI then
        local ac = mainUI:FindFirstChild("AbilityContainer")
        if ac then
            local bl = ac:FindFirstChild("Block")
            if bl then
                local ct = bl:FindFirstChild("CooldownTime")
                if ct and ct:IsA("TextLabel") then
                    hdtCooldownLabel.Text = "Block CD: " .. ct.Text; return
                end
            end
        end
    end
    hdtCooldownLabel.Text = "Block CD: ?"
end

local function updateFpsCounter()
    if not fpsCounterEnabled then
        if fpsGui then fpsGui:Destroy(); fpsGui = nil; fpsLabel = nil end
        return
    end
    if not fpsGui then
        local sg = Instance.new("ScreenGui")
        sg.Name = "FpsCounter"; sg.Parent = PlayerGui
        sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder = 9999
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(0, 100, 0, 30); fr.Position = UDim2.new(0, 10, 0, 150)
        fr.BackgroundColor3 = Color3.fromRGB(0, 0, 0); fr.BackgroundTransparency = 0.5
        fr.BorderSizePixel = 0; fr.Parent = sg
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -10, 1, -10); tl.Position = UDim2.new(0, 5, 0, 5)
        tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.fromRGB(255, 255, 255)
        tl.Text = "FPS: 0"; tl.Font = Enum.Font.GothamBold; tl.TextSize = 16; tl.Parent = fr
        fpsGui = sg; fpsLabel = tl
        lastFpsUpdate = tick(); frameCount = 0; fps = 0
    end
    frameCount = frameCount + 1
    local now = tick()
    if now - lastFpsUpdate >= 1 then
        fps = frameCount; frameCount = 0; lastFpsUpdate = now
        fpsLabel.Text = "FPS: " .. fps
    end
end

-- ══════════════════════════════════════════════
--  LEGACY VISION CONE
-- ══════════════════════════════════════════════
local function guestCreateVisionPart()
    local p = Instance.new("Part"); p.Size = Vector3.new(1, 1, 1)
    p.Shape = Enum.PartType.Ball; p.Anchored = true; p.CanCollide = false
    p.Transparency = 0.5; p.Color = Color3.fromRGB(255, 0, 0); p.Parent = workspaceService
    return p
end
local function guestCreateConnectionPart()
    local p = Instance.new("Part"); p.Size = Vector3.new(0.1, 0.1, 1)
    p.Anchored = true; p.CanCollide = false; p.Transparency = 0.3
    p.Color = Color3.fromRGB(255, 0, 0); p.Parent = workspaceService
    return p
end
local function guestCleanupVisionCone()
    if guestCenterPart        then guestCenterPart:Destroy();        guestCenterPart        = nil end
    if guestLeftPart          then guestLeftPart:Destroy();          guestLeftPart          = nil end
    if guestRightPart         then guestRightPart:Destroy();         guestRightPart         = nil end
    if guestLeftToKillerPart  then guestLeftToKillerPart:Destroy();  guestLeftToKillerPart  = nil end
    if guestRightToKillerPart then guestRightToKillerPart:Destroy(); guestRightToKillerPart = nil end
    if guestLeftToCenterPart  then guestLeftToCenterPart:Destroy();  guestLeftToCenterPart  = nil end
    if guestCenterToRightPart then guestCenterToRightPart:Destroy(); guestCenterToRightPart = nil end
end

local function guestUpdateVisionCone()
    local showCone = guestShowVisionRange or guestLegacyShowVisionRange
    if not showCone then
        if guestCenterPart then guestCleanupVisionCone() end
        return
    end
    local myChar = clientPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then guestCleanupVisionCone(); return end

    local originHRP
    if guestReverseEnabled or guestLegacyFacingEnabled then
        originHRP = myRoot
    else
        local kf = workspaceService:FindFirstChild("Players")
            and workspaceService.Players:FindFirstChild("Killers")
        if not kf then guestCleanupVisionCone(); return end
        for _, name in ipairs(guestAimTargets) do
            local t = kf:FindFirstChild(name)
            if t and t:FindFirstChild("HumanoidRootPart") then
                originHRP = t.HumanoidRootPart; break
            end
        end
        if not originHRP then guestCleanupVisionCone(); return end
    end

    local vRange  = guestLegacyShowVisionRange and guestLegacyVisionRange or guestVisionRange
    local vAngle  = guestLegacyShowVisionRange and guestLegacyVisionAngle or guestVisionAngle
    local fwd     = originHRP.CFrame.LookVector
    local halfRad = math.rad(vAngle / 2)
    local right   = Vector3.new(-fwd.Z, 0, fwd.X).Unit
    local leftDir  = (fwd * math.cos(halfRad) + right * math.sin(halfRad)).Unit
    local rightDir = (fwd * math.cos(halfRad) - right * math.sin(halfRad)).Unit
    local centerPos = originHRP.Position + fwd      * vRange
    local leftPos   = originHRP.Position + leftDir  * vRange
    local rightPos  = originHRP.Position + rightDir * vRange

    if not guestCenterPart        then guestCenterPart        = guestCreateVisionPart()     end
    if not guestLeftPart          then guestLeftPart          = guestCreateVisionPart()     end
    if not guestRightPart         then guestRightPart         = guestCreateVisionPart()     end
    if not guestLeftToKillerPart  then guestLeftToKillerPart  = guestCreateConnectionPart() end
    if not guestRightToKillerPart then guestRightToKillerPart = guestCreateConnectionPart() end
    if not guestLeftToCenterPart  then guestLeftToCenterPart  = guestCreateConnectionPart() end
    if not guestCenterToRightPart then guestCenterToRightPart = guestCreateConnectionPart() end

    guestCenterPart.Position = centerPos
    guestLeftPart.Position   = leftPos
    guestRightPart.Position  = rightPos

    local function updateLine(part, p1, p2)
        local mid  = (p1 + p2) / 2
        local dist = (p2 - p1).Magnitude
        part.Size   = Vector3.new(0.1, 0.1, dist)
        part.CFrame = CFrame.new(mid, p2)
    end
    updateLine(guestLeftToKillerPart,  originHRP.Position, leftPos)
    updateLine(guestRightToKillerPart, originHRP.Position, rightPos)
    updateLine(guestLeftToCenterPart,  leftPos,            centerPos)
    updateLine(guestCenterToRightPart, centerPos,          rightPos)
end

-- ══════════════════════════════════════════════
--  CHARACTER SETUP
-- ══════════════════════════════════════════════
local function guestSetupCharacter(char)
    guestHumanoid = char:FindFirstChild("Humanoid")
    guestHRP      = char:FindFirstChild("HumanoidRootPart")
    if guestAimConnection then guestAimConnection:Disconnect(); guestAimConnection = nil end
    local animator = guestHumanoid and guestHumanoid:FindFirstChildOfClass("Animator")
    if animator and guestAimPunchActive then
        guestAimConnection = animator.AnimationPlayed:Connect(function(track)
            local animId = track.Animation.AnimationId:match("%d+")
            if guestAimPunchActive and guestTrackedPunchAnimations[animId] then
                guestPunchLastTriggerTime = tick(); guestPunchAiming = true
            end
        end)
    end
end

-- ══════════════════════════════════════════════
--  NOCLIP
-- ══════════════════════════════════════════════
local function enableNoclip()
    if not clientPlayer.Character then return end
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = runService.Stepped:Connect(function()
        if not noclipEnabled then noclipConn:Disconnect(); noclipConn = nil; return end
        if noclipOnlyWhenBlockReady and not isBlockReady() then return end
        if not clientPlayer.Character then return end
        for _, part in ipairs(clientPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

local function disableNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = clientPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

-- ══════════════════════════════════════════════
--  PUNCH CONTROLLER
-- ══════════════════════════════════════════════
local function hookNetwork()
    if networkHooked then return end
    pcall(function()
        local Network = require(replicatedStorage.Modules.Network)
        originalFireConn = Network.FireConnection
        Network.FireConnection = function(self, name, ...)
            if punchMobilityEnabled and name == "DisableSprinting" then return end
            return originalFireConn(self, name, ...)
        end
        networkHooked = true
    end)
end

local function unhookNetwork()
    if not networkHooked then return end
    pcall(function()
        local Network = require(replicatedStorage.Modules.Network)
        if originalFireConn then Network.FireConnection = originalFireConn end
    end)
    networkHooked = false; originalFireConn = nil
end

local function pinValue(v)
    if not v or not v:IsA("NumberValue") then return end
    if v.Value > 1.01 then return end
    pcall(function() v.Value = 1; tweenService:Create(v, TweenInfo.new(0), {Value=1}):Play() end)
    local conn
    conn = v:GetPropertyChangedSignal("Value"):Connect(function()
        if not punchMobilityEnabled then pcall(function() conn:Disconnect() end); return end
        if v.Value < 1 then pcall(function() v.Value = 1 end) end
    end)
    table.insert(pinnedConns, conn)
end

local function stopPunchOverride()
    pcall(function() runService:UnbindFromRenderStep("PunchMobility") end)
    pcall(function() runService:UnbindFromRenderStep("LungeBoost") end)
    lungeActive = false
    for _, conn in pairs(pinnedConns) do pcall(function() conn:Disconnect() end) end
    pinnedConns = {}
    if descendantConn then descendantConn:Disconnect(); descendantConn = nil end
    if lungeThread then task.cancel(lungeThread); lungeThread = nil end
end

local function applyLunge()
    if not lungeBoostEnabled then return end
    if lungeActive then return end
    local rootPart = getRootPart()
    if not rootPart then return end
    local lv  = rootPart.CFrame.LookVector
    local dir = Vector3.new(lv.X, 0, lv.Z)
    if dir.Magnitude == 0 then return end
    dir = dir.Unit
    lungeActive = true
    local speed    = BASE_PUNCH_FORCE * lungeMultiplier
    local DURATION = 0.3
    local elapsed  = 0
    pcall(function() runService:UnbindFromRenderStep("LungeBoost") end)
    runService:BindToRenderStep("LungeBoost", Enum.RenderPriority.Character.Value + 20, function(dt)
        elapsed = elapsed + dt
        local rp = getRootPart()
        if not rp or elapsed >= DURATION then
            pcall(function() runService:UnbindFromRenderStep("LungeBoost") end)
            lungeActive = false; return
        end
        local t = 1 - (elapsed / DURATION)
        local currentY = rp.AssemblyLinearVelocity.Y
        rp.AssemblyLinearVelocity = dir * (speed * t) + Vector3.new(0, currentY, 0)
    end)
end

local function startPunchOverride()
    stopPunchOverride()
    local char = clientPlayer.Character
    if not char then return end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("NumberValue") then pinValue(desc) end
    end
    descendantConn = char.DescendantAdded:Connect(function(desc)
        if not punchMobilityEnabled then return end
        if desc:IsA("NumberValue") then
            task.defer(function()
                if desc.Name == "PunchAbility" then
                    if lungeBoostEnabled then
                        if lungeThread then task.cancel(lungeThread) end
                        local delay = isParryMode() and PARRY_WINDUP or PUNCH_WINDUP
                        lungeThread = task.delay(delay, function()
                            lungeThread = nil; applyLunge()
                        end)
                    end
                end
                pinValue(desc)
            end)
        end
    end)
    runService:BindToRenderStep("PunchMobility", Enum.RenderPriority.Character.Value + 10, function()
        if lungeActive then return end
        local hum = getHumanoid()
        if not hum then return end
        if hum.WalkSpeed < BASE_SPEED then hum.WalkSpeed = BASE_SPEED end
    end)
end

local function pinChargeValue(v)
    if not v or not v:IsA("NumberValue") then return end
    if v.Value <= 1.01 then return end
    pcall(function() v.Value = 1; tweenService:Create(v, TweenInfo.new(0), {Value=1}):Play() end)
    local conn
    conn = v:GetPropertyChangedSignal("Value"):Connect(function()
        if not isCharging or not chargeSpeedCapEnabled then
            pcall(function() conn:Disconnect() end); return
        end
        if v.Value > 1 then pcall(function() v.Value = 1 end) end
    end)
    table.insert(chargePinnedConns, conn)
end

local function stopChargeCap()
    pcall(function() runService:UnbindFromRenderStep("ChargeCap") end)
    if chargeCapConn then chargeCapConn:Disconnect(); chargeCapConn = nil end
    for _, c in pairs(chargePinnedConns) do pcall(function() c:Disconnect() end) end
    chargePinnedConns = {}
end

local function startChargeCap()
    stopChargeCap()
    local char = clientPlayer.Character
    if not char then return end
    for _, desc in ipairs(char:GetDescendants()) do pinChargeValue(desc) end
    chargeCapConn = char.DescendantAdded:Connect(function(desc)
        if not isCharging or not chargeSpeedCapEnabled then return end
        if desc:IsA("NumberValue") then task.defer(function() pinChargeValue(desc) end) end
    end)
    runService:BindToRenderStep("ChargeCap", Enum.RenderPriority.Character.Value + 20, function()
        if not isCharging or not chargeSpeedCapEnabled then
            pcall(function() runService:UnbindFromRenderStep("ChargeCap") end); return
        end
        local hum = getHumanoid()
        if hum and hum.WalkSpeed > BASE_SPEED then hum.WalkSpeed = BASE_SPEED end
    end)
end

local function stopLock()
    isCharging = false
    pcall(function() runService:UnbindFromRenderStep("ChargeLock") end)
    pcall(function() runService:UnbindFromRenderStep("ChargeSpeedLimit") end)
    stopChargeCap()
end

local function startLock()
    pcall(function() runService:UnbindFromRenderStep("ChargeLock") end)
    pcall(function() runService:UnbindFromRenderStep("ChargeSpeedLimit") end)
    isCharging = true
    runService:BindToRenderStep("ChargeLock", Enum.RenderPriority.Character.Value + 2, function()
        local hum = getHumanoid()
        if not hum then return end
        local cam = workspaceService.CurrentCamera.CFrame.LookVector
        local dir = Vector3.new(cam.X, 0, cam.Z)
        if dir.Magnitude > 0 then hum:Move(dir.Unit) end
    end)
    runService:BindToRenderStep("ChargeSpeedLimit", Enum.RenderPriority.Character.Value + 20, function()
        if not isCharging then
            pcall(function() runService:UnbindFromRenderStep("ChargeSpeedLimit") end); return
        end
        local hum = getHumanoid()
        if hum and hum.WalkSpeed ~= chargeSpeedLimit then hum.WalkSpeed = chargeSpeedLimit end
    end)
    if chargeSpeedCapEnabled then startChargeCap() end
end

local function setupChargeWatcher(character)
    if chargeWatcher then chargeWatcher:Disconnect(); chargeWatcher = nil end
    stopLock(); stopPunchOverride()
    chargeWatcher = character:GetAttributeChangedSignal("GuestCharging"):Connect(function()
        if not chargeControlEnabled then return end
        if character:GetAttribute("GuestCharging") then startLock() else stopLock() end
    end)
end

-- ══════════════════════════════════════════════
--  KILLER VELOCITY TRACKING
-- ══════════════════════════════════════════════
runService.RenderStepped:Connect(function(dt)
    for killer in pairs(guestKillerState) do
        if not killer.Parent then guestKillerState[killer] = nil end
    end
    local kf = workspaceService:FindFirstChild("Players")
        and workspaceService.Players:FindFirstChild("Killers")
    if not kf then return end
    for _, killer in ipairs(kf:GetChildren()) do
        local hrp = killer:FindFirstChild("HumanoidRootPart")
        if hrp then
            local s = guestKillerState[killer]
                   or {prevPos=hrp.Position, prevLook=hrp.CFrame.LookVector,
                        vel=Vector3.new(), angVel=0}
            local newVel = (hrp.Position - s.prevPos) / math.max(dt, 1e-6)
            s.vel  = s.vel:Lerp(newVel, SMOOTHING_LERP)
            local look = hrp.CFrame.LookVector
            local dot  = math.clamp(s.prevLook:Dot(look), -1, 1)
            local ang  = math.acos(dot)
            local sign = (s.prevLook:Cross(look).Y >= 0) and 1 or -1
            local newA = (ang / math.max(dt, 1e-6)) * sign
            s.angVel   = s.angVel * (1 - SMOOTHING_LERP) + newA * SMOOTHING_LERP
            s.prevPos  = hrp.Position; s.prevLook = look
            guestKillerState[killer] = s
        end
    end
end)

-- ══════════════════════════════════════════════
--  MAIN RENDER LOOP
-- ══════════════════════════════════════════════
runService.RenderStepped:Connect(function()
    -- Aim punch rotation lock
    if guestAimPunchActive and guestHumanoid and guestHRP and guestPunchAiming then
        local elapsed = tick() - guestPunchLastTriggerTime
        if elapsed > guestAimPunchDuration then
            guestPunchAiming = false
            if guestOriginalWS then
                guestHumanoid.WalkSpeed  = guestOriginalWS
                guestHumanoid.JumpPower  = guestOriginalJP
                guestHumanoid.AutoRotate = guestOriginalAutoRotate
                guestOriginalWS = nil; guestOriginalJP = nil; guestOriginalAutoRotate = nil
            end
        else
            if not guestOriginalWS then
                guestOriginalWS         = guestHumanoid.WalkSpeed
                guestOriginalJP         = guestHumanoid.JumpPower
                guestOriginalAutoRotate = guestHumanoid.AutoRotate
            end
            guestHumanoid.AutoRotate         = false
            guestHRP.AssemblyAngularVelocity = Vector3.zero
            local kf = workspaceService:FindFirstChild("Players")
                and workspaceService.Players:FindFirstChild("Killers")
            if kf and guestHRP then
                local bestDist, targetHRP = math.huge, nil
                for _, killer in ipairs(kf:GetChildren()) do
                    local hrp = killer:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - guestHRP.Position).Magnitude
                        if d < bestDist then bestDist = d; targetHRP = hrp end
                    end
                end
                if targetHRP then
                    local pred = guestPunchPrediction
                    local vel        = targetHRP.AssemblyLinearVelocity
                    local predictPos = vel.Magnitude > 0.5
                        and (targetHRP.Position + vel * (pred / 60))
                        or targetHRP.Position
                    local dir = (predictPos - guestHRP.Position) * Vector3.new(1, 0, 1)
                    if dir.Magnitude > 0.01 then
                        guestHRP.CFrame = CFrame.new(guestHRP.Position, guestHRP.Position + dir.Unit)
                    end
                end
            end
        end
    end

    -- Always-on visual updaters
    updateHDTRange()
    pcall(guestUpdateVisionCone)
    pcall(updatePingChecker)
    pcall(updateHDTCooldownChecker)
    pcall(updateFpsCounter)
end)

-- ══════════════════════════════════════════════
--  LINEBLOCK
-- ══════════════════════════════════════════════
local function linePointInCylinder(origin, lookVec, length, radius, point)
    local offset = point - origin
    local depth  = offset:Dot(lookVec)
    if depth < 0 or depth > length then return false end
    local perp = (offset - lookVec * depth).Magnitude
    return perp <= radius
end

local function lineBlockHookKillerAnim(killer)
    if lineBlockAnimConns[killer] then return end
    local hum  = killer:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local anim = hum:FindFirstChildOfClass("Animator")
    if not anim then return end

    lineBlockAnimConns[killer] = anim.AnimationPlayed:Connect(function(track)
        local id = track.Animation.AnimationId:match("%d+")
        if id and guestTrackedPunchAnimations[id] then
            lineBlockPendingKillers[killer] = true
            task.delay(0.6, function()
                lineBlockPendingKillers[killer] = nil
            end)
        end
    end)
end

local function lineBlockCleanKiller(killer)
    if lineBlockParts[killer] then
        pcall(function() lineBlockParts[killer]:Destroy() end)
        lineBlockParts[killer] = nil
    end
    lineKillerFacingSince[killer]   = nil
    lineBlockPendingKillers[killer] = nil
    lineBlockSoundKillers[killer]   = nil
    if lineBlockAnimConns[killer] then
        pcall(function() lineBlockAnimConns[killer]:Disconnect() end)
        lineBlockAnimConns[killer] = nil
    end
end

local function updateLineBlock()
    local myChar = clientPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local now    = tick()

    for killer in pairs(lineBlockParts) do
        if not killer.Parent then lineBlockCleanKiller(killer) end
    end

    if not lineBlockEnabled then
        for killer in pairs(lineBlockParts) do lineBlockCleanKiller(killer) end
        for killer in pairs(lineBlockAnimConns) do lineBlockCleanKiller(killer) end
        return
    end

    if not myRoot then return end

    local kf = workspaceService:FindFirstChild("Players")
        and workspaceService.Players:FindFirstChild("Killers")
    if not kf then return end

    for _, killer in ipairs(kf:GetChildren()) do
        local hrp = killer:FindFirstChild("HumanoidRootPart")
        if not hrp then
            lineBlockCleanKiller(killer)
        else
            lineBlockHookKillerAnim(killer)

            local part = lineBlockParts[killer]
            if not part or not part.Parent then
                part = Instance.new("Part")
                part.Anchored     = true
                part.CanCollide   = false
                part.Material     = Enum.Material.Neon
                part.Transparency = 0.45
                part.Parent       = workspaceService
                lineBlockParts[killer] = part
            end

            -- Prefer QueryHitbox as the attack origin; fall back to HRP
            local qh      = getQueryHitbox(killer)
            local origin  = qh or hrp          -- BasePart used as cylinder start
            local look    = origin.CFrame.LookVector
            local halfLen = lineBlockLength / 2
            local midPt   = origin.Position + look * halfLen
            local diam    = lineBlockRadius * 2

            part.Size   = Vector3.new(diam, diam, lineBlockLength)
            part.CFrame = CFrame.new(midPt, midPt + look)

            local guestOnLine = linePointInCylinder(
                origin.Position, look,
                lineBlockLength, lineBlockRadius,
                myRoot.Position
            )

            -- Facing check: is the origin looking toward the player?
            local toGuest   = myRoot.Position - origin.Position
            local dist      = toGuest.Magnitude
            local facingDot = dist > 0.1 and look:Dot(toGuest.Unit) or 0

            if facingDot >= lineBlockMinDot then
                if not lineKillerFacingSince[killer] then
                    lineKillerFacingSince[killer] = now
                end
            else
                lineKillerFacingSince[killer] = nil
            end

            local facedFor = lineKillerFacingSince[killer]
                and (now - lineKillerFacingSince[killer]) or 0

            local soundActive = lineBlockSoundKillers[killer]
                and (now - lineBlockSoundKillers[killer]) <= 0.35

            -- Color feedback
            if guestOnLine then
                part.Color = Color3.fromRGB(255, 40, 40)
            elseif lineBlockPendingKillers[killer] or soundActive then
                part.Color = Color3.fromRGB(255, 215, 0)
            else
                part.Color = Color3.fromRGB(235, 235, 255)
            end

            -- Block condition
            if guestOnLine
                and (lineBlockPendingKillers[killer] or soundActive)
                and facedFor >= lineBlockFacingDuration
                and (now - lineBlockLastBlockTime) >= guestBlockCooldown
                and (now - guestLastBlockTime) >= guestBlockCooldown
                and isBlockReady()
            then
                lineBlockLastBlockTime = now
                guestLastBlockTime     = now

                local snapKiller = killer
                local snapChar   = myChar

                task.delay(lineBlockDelay, function()
                    local myR2    = snapChar:FindFirstChild("HumanoidRootPart")
                    local hrp2    = snapKiller:FindFirstChild("HumanoidRootPart")
                    if not myR2 or not hrp2 then return end

                    local qh2     = getQueryHitbox(snapKiller)
                    local origin2 = qh2 or hrp2

                    if linePointInCylinder(
                        origin2.Position,
                        origin2.CFrame.LookVector,
                        lineBlockLength,
                        lineBlockRadius,
                        myR2.Position
                    ) then
                        guestFireRemoteBlock()
                        if guestAutoPunchOn then
                            task.delay(guestAutoPunchDelay, guestFireRemotePunch)
                        end
                        showCinematicText()
                    end
                end)
            end
        end
    end
end

runService.RenderStepped:Connect(function()
    pcall(updateLineBlock)
end)

-- ══════════════════════════════════════════════
--  INITIAL HOOKS
-- ══════════════════════════════════════════════
guestSetupSoundHooks()

clientPlayer.CharacterAdded:Connect(function(char)
    task.delay(0.5, function()
        guestCleanupVisionCone()
        guestSetupCharacter(char)
        setupChargeWatcher(char)
        if noclipEnabled then enableNoclip() end
        if punchMobilityEnabled then startPunchOverride() end
    end)
end)

if clientPlayer.Character then
    guestSetupCharacter(clientPlayer.Character)
    setupChargeWatcher(clientPlayer.Character)
end

if noclipEnabled        then enableNoclip()                   end
if punchMobilityEnabled then hookNetwork(); startPunchOverride() end

-- ══════════════════════════════════════════════════════════════════════
--  UI  (WindUI)
-- ══════════════════════════════════════════════════════════════════════

-- ── SENTINEL TAB ────────────────────────────────────────────────────
local SentinelTab  = Window:Tab({ Title = "Sentinel",  Icon = "shield" })
local GuestSection = SentinelTab:Section({ Title = "Core Block", Opened = true })

GuestSection:Toggle({ Title="Auto Block", Type="Checkbox", Default=guestAutoBlockAudioOn,
    Callback=function(v) guestAutoBlockAudioOn=v; cfg.set("guestAutoBlockAudioOn",v) end })
GuestSection:Toggle({ Title="M1 Auto Block", Type="Checkbox", Default=guestM1AutoBlockOn,
    Callback=function(v) guestM1AutoBlockOn=v; cfg.set("guestM1AutoBlockOn",v) end })
GuestSection:Slider({ Title="Block Delay", Step=0.05, Value={Min=0,Max=2,Default=guestBlockDelay},
    Callback=function(v) guestBlockDelay=v; cfg.set("guestBlockDelay",v) end })
GuestSection:Slider({ Title="Auto Block Radius", Step=1, Value={Min=1,Max=50,Default=guestDetectionRange},
    Callback=function(v) guestDetectionRange=v; guestDetectionRangeSq=v*v; cfg.set("guestDetectionRange",v) end })
GuestSection:Toggle({ Title="Verify Facing Check", Type="Checkbox", Default=guestVerifyFacingCheckOn,
    Callback=function(v) guestVerifyFacingCheckOn=v; cfg.set("guestVerifyFacingCheckOn",v) end })
GuestSection:Slider({ Title="Vision Range", Step=0.5, Value={Min=1,Max=20,Default=guestVisionRange},
    Callback=function(v) guestVisionRange=v; cfg.set("guestVisionRange",v) end })
GuestSection:Slider({ Title="Vision Angle", Step=1, Value={Min=1,Max=200,Default=guestVisionAngle},
    Callback=function(v) guestVisionAngle=v; cfg.set("guestVisionAngle",v) end })
GuestSection:Toggle({ Title="Show Vision Cone", Type="Checkbox", Default=guestShowVisionRange,
    Callback=function(v) guestShowVisionRange=v; cfg.set("guestShowVisionRange",v)
        if not v then guestCleanupVisionCone() end end })
GuestSection:Toggle({ Title="No HDT Cooldown", Type="Checkbox", Default=noHDTCooldown,
    Callback=function(v) noHDTCooldown=v; cfg.set("noHDTCooldown",v) end })
GuestSection:Toggle({ Title="Block Cooldown Checker", Type="Checkbox", Default=hdtCooldownCheckerEnabled,
    Callback=function(v) hdtCooldownCheckerEnabled=v; cfg.set("hdtCooldownChecker",v)
        if not v and hdtCooldownGui then hdtCooldownGui:Destroy(); hdtCooldownGui=nil end end })
GuestSection:Slider({ Title="Block Cooldown (s)", Step=0.05, Value={Min=0.05,Max=2,Default=guestBlockCooldown},
    Callback=function(v) guestBlockCooldown=v; cfg.set("guestBlockCooldown",v) end })
GuestSection:Slider({ Title="Auto Punch Delay (s)", Step=0.05, Value={Min=0,Max=2,Default=guestAutoPunchDelay},
    Callback=function(v) guestAutoPunchDelay=v; cfg.set("guestAutoPunchDelay",v) end })

-- HDT Section
local HDTSection = SentinelTab:Section({ Title = "Hitbox Dragging (HDT)", Opened = false })
HDTSection:Toggle({ Title="Enable HDT", Type="Checkbox", Default=guestHitboxDraggingOn,
    Callback=function(v) guestHitboxDraggingOn=v; cfg.set("guestHitboxDraggingOn",v) end })
HDTSection:Dropdown({ Title="HDT Mode", Values={"Blatant","Legit","Hitbox","Smart"}, Default=guestHitboxMode,
    Callback=function(v) guestHitboxMode=v; cfg.set("guestHitboxMode",v) end })
HDTSection:Paragraph({ Title="Smart Mode",
    Content="Smart auto-switches between Legit (close) and Blatant (far) based on Switch Distance." })
HDTSection:Slider({ Title="Switch Distance (Smart)", Step=1, Value={Min=2,Max=20,Default=hdtSwitchDist},
    Callback=function(v) hdtSwitchDist=v; cfg.set("hdtSwitchDist",v) end })
HDTSection:Slider({ Title="Blatant Speed", Step=1, Value={Min=1,Max=125,Default=cfg.get("hdtBlatantSpeed",150)},
    Callback=function(v) cfg.set("hdtBlatantSpeed",v) end })
HDTSection:Slider({ Title="Legit Speed", Step=1, Value={Min=10,Max=100,Default=cfg.get("hdtLegitSpeed",140)},
    Callback=function(v) cfg.set("hdtLegitSpeed",v) end })
HDTSection:Slider({ Title="Prediction Time (s)", Step=0.01, Value={Min=0,Max=0.5,Default=hdtPredictTime},
    Callback=function(v) hdtPredictTime=v; cfg.set("hdtPredictTime",v) end })
HDTSection:Toggle({ Title="Face Killer During HDT", Type="Checkbox", Default=guestHitboxFaceKiller,
    Callback=function(v) guestHitboxFaceKiller=v; cfg.set("guestHitboxFaceKiller",v) end })
HDTSection:Toggle({ Title="HDT Visual (Beam)", Type="Checkbox", Default=guestHitboxVisual,
    Callback=function(v) guestHitboxVisual=v; cfg.set("guestHitboxVisual",v) end })
HDTSection:Slider({ Title="Drag Duration", Step=0.05, Value={Min=0.05,Max=2,Default=guestHitboxDragDuration},
    Callback=function(v) guestHitboxDragDuration=v; cfg.set("guestHitboxDragDuration",v) end })
HDTSection:Slider({ Title="Trigger Radius", Step=1, Value={Min=0,Max=30,Default=guestHitboxTriggerRadius},
    Callback=function(v) guestHitboxTriggerRadius=v; cfg.set("guestHitboxTriggerRadius",v) end })
HDTSection:Dropdown({ Title="Target Mode", Values={"Root","Arms","Random"}, Default=guestHitboxTargetMode,
    Callback=function(v) guestHitboxTargetMode=v; cfg.set("guestHitboxTargetMode",v) end })
HDTSection:Toggle({ Title="Show HDT Range", Type="Checkbox", Default=guestShowHDTRange,
    Callback=function(v) guestShowHDTRange=v; cfg.set("guestShowHDTRange",v) end })

-- Better Detection
local BetterSection = SentinelTab:Section({ Title = "Better Detection", Opened = false })
BetterSection:Toggle({ Title="Enable Better Detection", Type="Checkbox", Default=guestBetterDetectionEnabled,
    Callback=function(v) guestBetterDetectionEnabled=v; cfg.set("guestBetterDetectionEnabled",v) end })
BetterSection:Input({ Title="Hitbox X", Placeholder=tostring(guestBetterDetectionX),
    Callback=function(v) local n=tonumber(v); if n then guestBetterDetectionX=n; cfg.set("guestBetterDetectionX",n) end end })
BetterSection:Input({ Title="Hitbox Y", Placeholder=tostring(guestBetterDetectionY),
    Callback=function(v) local n=tonumber(v); if n then guestBetterDetectionY=n; cfg.set("guestBetterDetectionY",n) end end })
BetterSection:Input({ Title="Hitbox Z (forward)", Placeholder=tostring(guestBetterDetectionZ),
    Callback=function(v) local n=tonumber(v); if n then guestBetterDetectionZ=n; cfg.set("guestBetterDetectionZ",n) end end })
BetterSection:Input({ Title="Multiplier", Placeholder=tostring(guestBetterDetectionMultiplier),
    Callback=function(v) local n=tonumber(v); if n then guestBetterDetectionMultiplier=n; cfg.set("guestBetterDetectionMultiplier",n) end end })
BetterSection:Input({ Title="Segments", Placeholder=tostring(guestBetterDetectionSegments),
    Callback=function(v) local n=tonumber(v); if n then n=math.max(1,math.floor(n)); guestBetterDetectionSegments=n; cfg.set("guestBetterDetectionSegments",n) end end })
BetterSection:Input({ Title="Start Distance", Placeholder=tostring(guestBetterStartDist),
    Callback=function(v) local n=tonumber(v); if n then guestBetterStartDist=n; cfg.set("guestBetterStartDist",n) end end })
BetterSection:Input({ Title="Step Distance", Placeholder=tostring(guestBetterStepDist),
    Callback=function(v) local n=tonumber(v); if n then guestBetterStepDist=n; cfg.set("guestBetterStepDist",n) end end })
BetterSection:Input({ Title="Pre-Delay (s)", Placeholder=tostring(guestBetterPreDelay),
    Callback=function(v) local n=tonumber(v); if n then guestBetterPreDelay=n; cfg.set("guestBetterPreDelay",n) end end })
BetterSection:Input({ Title="Stagger (s)", Placeholder=tostring(guestBetterStagger),
    Callback=function(v) local n=tonumber(v); if n then guestBetterStagger=n; cfg.set("guestBetterStagger",n) end end })
BetterSection:Input({ Title="Prediction Forward", Placeholder=tostring(guestBetterPredForward),
    Callback=function(v) local n=tonumber(v); if n then guestBetterPredForward=n; cfg.set("guestBetterPredForward",n) end end })
BetterSection:Input({ Title="Prediction Turn", Placeholder=tostring(guestBetterPredTurn),
    Callback=function(v) local n=tonumber(v); if n then guestBetterPredTurn=n; cfg.set("guestBetterPredTurn",n) end end })

-- ── LINEBLOCK TAB ────────────────────────────────────────────────────
local LineTab     = Window:Tab({ Title = "Lineblock", Icon = "minus" })
local LineSection = LineTab:Section({ Title = "Line Block", Opened = true })

LineSection:Toggle({
    Title = "Enable Lineblock", Type = "Checkbox", Default = lineBlockEnabled,
    Callback = function(v) lineBlockEnabled=v; cfg.set("lineBlockEnabled",v) end,
})
LineSection:Slider({
    Title = "Line Length", Step = 1, Value = {Min=2,Max=40,Default=lineBlockLength},
    Callback = function(v) lineBlockLength=v; cfg.set("lineBlockLength",v) end,
})
LineSection:Slider({
    Title = "Line Radius", Step = 0.5, Value = {Min=0.5,Max=10,Default=lineBlockRadius},
    Callback = function(v) lineBlockRadius=v; cfg.set("lineBlockRadius",v) end,
})
LineSection:Slider({
    Title = "Block Delay (x0.05s)", Step = 1,
    Value = {Min=0,Max=20,Default=math.floor(lineBlockDelay/0.05+0.5)},
    Callback = function(v) lineBlockDelay=v*0.05; cfg.set("lineBlockDelay",lineBlockDelay) end,
})
LineSection:Slider({
    Title = "Anti-Bait Hold (x0.01s)", Step = 1,
    Value = {Min=0,Max=50,Default=math.floor(lineBlockFacingDuration/0.01+0.5)},
    Callback = function(v) lineBlockFacingDuration=v*0.01; cfg.set("lineBlockFacingDuration",lineBlockFacingDuration) end,
})
LineSection:Slider({
    Title = "Facing Sensitivity", Step = 1, Value = {Min=1,Max=10,Default=math.floor(lineBlockMinDot*10+0.5)},
    Callback = function(v) lineBlockMinDot=v/10; cfg.set("lineBlockMinDot",lineBlockMinDot) end,
})
LineSection:Paragraph({
    Title = "Color Guide",
    Content = "White = idle  |  Yellow = punch anim or sound detected  |  Red = you're on the line (block fires)",
})

-- ── PUNCH TAB ────────────────────────────────────────────────────────
local PunchTab     = Window:Tab({ Title = "Punch", Icon = "zap" })
local PunchSection = PunchTab:Section({ Title = "Auto Punch", Opened = true })
PunchSection:Toggle({ Title="Auto Punch", Type="Checkbox", Default=guestAutoPunchOn,
    Callback=function(v) guestAutoPunchOn=v; cfg.set("guestAutoPunchOn",v) end })
PunchSection:Toggle({ Title="Aim Punch", Type="Checkbox", Default=guestAimPunchActive,
    Callback=function(v) guestAimPunchActive=v; cfg.set("guestAimPunchActive",v)
        if v and clientPlayer.Character then guestSetupCharacter(clientPlayer.Character) end end })
PunchSection:Slider({ Title="Punch Prediction", Step=0.1, Value={Min=0,Max=10,Default=guestPunchPrediction},
    Callback=function(v) guestPunchPrediction=v; cfg.set("guestPunchPrediction",v) end })
PunchSection:Input({ Title="Custom Punch Sound ID", Placeholder=tostring(customPunchSoundId),
    Callback=function(v) local n=tonumber(v); customPunchSoundId=n or 0; cfg.set("customPunchSoundId",customPunchSoundId) end })

local MobilitySection = PunchTab:Section({ Title = "Punch Mobility", Opened = false })
MobilitySection:Toggle({ Title="Enable Punch Mobility", Type="Checkbox", Default=punchMobilityEnabled,
    Callback=function(v) punchMobilityEnabled=v; cfg.set("punchMobilityEnabled",v)
        if v then hookNetwork(); startPunchOverride() else unhookNetwork(); stopPunchOverride() end end })
MobilitySection:Toggle({ Title="Lunge Boost", Type="Checkbox", Default=lungeBoostEnabled,
    Callback=function(v) lungeBoostEnabled=v; cfg.set("lungeBoostEnabled",v)
        if not v then
            if lungeThread then task.cancel(lungeThread); lungeThread=nil end
            pcall(function() runService:UnbindFromRenderStep("LungeBoost") end)
            lungeActive=false
        end end })
MobilitySection:Slider({ Title="Lunge Multiplier", Step=0.1, Value={Min=0.5,Max=5,Default=lungeMultiplier},
    Callback=function(v) lungeMultiplier=v; cfg.set("lungeMultiplier",v) end })
MobilitySection:Toggle({ Title="Charge Control", Type="Checkbox", Default=chargeControlEnabled,
    Callback=function(v) chargeControlEnabled=v; cfg.set("chargeControlEnabled",v)
        if not v then stopLock() end end })
MobilitySection:Slider({ Title="Charge Speed Limit", Step=1, Value={Min=1,Max=50,Default=chargeSpeedLimit},
    Callback=function(v) chargeSpeedLimit=v; cfg.set("chargeSpeedLimit",v) end })
MobilitySection:Toggle({ Title="Charge Speed Cap", Type="Checkbox", Default=chargeSpeedCapEnabled,
    Callback=function(v) chargeSpeedCapEnabled=v; cfg.set("chargeSpeedCapEnabled",v)
        if isCharging and v then startChargeCap() elseif not v then stopChargeCap() end end })

local CineSection = PunchTab:Section({ Title = "Cinematic Text", Opened = false })
CineSection:Toggle({ Title="Enable Cinematic Text", Type="Checkbox", Default=guestCinematicTextEnabled,
    Callback=function(v) guestCinematicTextEnabled=v; cfg.set("guestCinematicTextEnabled",v) end })
CineSection:Input({ Title="Text Content", Placeholder=guestCinematicText,
    Callback=function(v) if v ~= "" then guestCinematicText=v; cfg.set("guestCinematicText",v) end end })
PunchSection:Slider({ Title="Aim Lock Duration (s)", Step=0.05, Value={Min=0.1,Max=2,Default=guestAimPunchDuration},
    Callback=function(v) guestAimPunchDuration=v; cfg.set("guestAimPunchDuration",v) end })

-- ── REVERSE TAB ──────────────────────────────────────────────────────
local ReverseTab     = Window:Tab({ Title = "Reverse", Icon = "refresh-cw" })
local ReverseSection = ReverseTab:Section({ Title = "Reverse Block", Opened = true })
ReverseSection:Toggle({ Title="Enable Reverse", Type="Checkbox", Default=guestReverseEnabled,
    Callback=function(v) guestReverseEnabled=v; cfg.set("guestReverseEnabled",v) end })
ReverseSection:Paragraph({ Title="Info",
    Content="When enabled, the block zone is centered on YOU instead of the killer." })

-- ── LEGACY TAB ───────────────────────────────────────────────────────
local LegacyTab     = Window:Tab({ Title = "Legacy", Icon = "clock" })
local LegacySection = LegacyTab:Section({ Title = "Legacy Facing", Opened = true })
LegacySection:Toggle({ Title="Enable Legacy Facing", Type="Checkbox", Default=guestLegacyFacingEnabled,
    Callback=function(v) guestLegacyFacingEnabled=v; cfg.set("guestLegacyFacingEnabled",v) end })
LegacySection:Slider({ Title="Vision Range", Step=0.5, Value={Min=1,Max=20,Default=guestLegacyVisionRange},
    Callback=function(v) guestLegacyVisionRange=v; cfg.set("guestLegacyVisionRange",v) end })
LegacySection:Slider({ Title="Vision Angle", Step=1, Value={Min=1,Max=200,Default=guestLegacyVisionAngle},
    Callback=function(v) guestLegacyVisionAngle=v; cfg.set("guestLegacyVisionAngle",v) end })
LegacySection:Toggle({ Title="Show Vision Range", Type="Checkbox", Default=guestLegacyShowVisionRange,
    Callback=function(v) guestLegacyShowVisionRange=v; cfg.set("guestLegacyShowVisionRange",v) end })

-- ── PING TAB ─────────────────────────────────────────────────────────
local PingTab     = Window:Tab({ Title = "Ping", Icon = "activity" })
local PingSection = PingTab:Section({ Title = "Ping Checker", Opened = true })
PingSection:Toggle({ Title="Enable Ping Checker", Type="Checkbox", Default=pingCheckerEnabled,
    Callback=function(v) pingCheckerEnabled=v; cfg.set("pingCheckerEnabled",v)
        if not v and pingLabel then pingLabel.Parent.Parent:Destroy(); pingLabel=nil end end })
PingSection:Paragraph({ Title="Info",
    Content="Displays a small on-screen ping counter in the bottom-left corner." })

-- ── MISC TAB ─────────────────────────────────────────────────────────
local MiscTab     = Window:Tab({ Title = "Misc", Icon = "settings" })
local MiscSection = MiscTab:Section({ Title = "Misc", Opened = true })
MiscSection:Toggle({ Title="Smart Delay", Type="Checkbox", Default=guestSmartDelayEnabled,
    Callback=function(v) guestSmartDelayEnabled=v; cfg.set("guestSmartDelayEnabled",v) end })
MiscSection:Toggle({ Title="Manual Drag", Type="Checkbox", Default=guestManualDragEnabled,
    Callback=function(v) guestManualDragEnabled=v; cfg.set("guestManualDragEnabled",v) end })
MiscSection:Toggle({ Title="Noclip", Type="Checkbox", Default=noclipEnabled,
    Callback=function(v) noclipEnabled=v; cfg.set("noclipEnabled",v)
        if v then enableNoclip() else disableNoclip() end end })
MiscSection:Toggle({ Title="Noclip Only When Block Ready", Type="Checkbox", Default=noclipOnlyWhenBlockReady,
    Callback=function(v) noclipOnlyWhenBlockReady=v; cfg.set("noclipOnlyWhenBlockReady",v) end })
MiscSection:Toggle({ Title="FPS Counter", Type="Checkbox", Default=fpsCounterEnabled,
    Callback=function(v) fpsCounterEnabled=v; cfg.set("fpsCounterEnabled",v)
        if not v and fpsGui then fpsGui:Destroy(); fpsGui=nil; fpsLabel=nil end end })

-- ── INTERFACE TAB ────────────────────────────────────────────────────
local InterfaceTab = Window:Tab({ Title = "Interface", Icon = "scan" })
InterfaceTab:Button({ Title="Close UI", Locked=false,
    Callback=function()
        local ok = pcall(function() Window:Destroy() end)
        if not ok then pcall(function() Window:Close() end) end
    end })

print("V1rpBlock loaded")