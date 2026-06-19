-- v1prware | maintained by V1PR | original by Glovsaken

print("v1prware loaded")

------------------------------------------------------------------------
-- services
------------------------------------------------------------------------
local svc = {
    Players        = game:GetService("Players"),
    Run            = game:GetService("RunService"),
    Input          = game:GetService("UserInputService"),
    RS             = game:GetService("ReplicatedStorage"),
    WS             = game:GetService("Workspace"),
    TweenService   = game:GetService("TweenService"),
    TextChat       = game:GetService("TextChatService"),
    Http           = game:GetService("HttpService"),
    SoundService   = game:GetService("SoundService"),
}

local lp  = svc.Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui", 10)

------------------------------------------------------------------------
-- filesystem shims
------------------------------------------------------------------------
local fs = {
    hasFolder = isfolder     or function() return false end,
    makeFolder= makefolder   or function() end,
    write     = writefile    or function() end,
    hasFile   = isfile       or function() return false end,
    read      = readfile     or function() return "" end,
    asset     = getcustomasset or function(p) return p end,
}

------------------------------------------------------------------------
-- config
------------------------------------------------------------------------
local cfg = {}
do
    local DIR  = "Viperware"
    local FILE = DIR .. "/config.json"
    local pendingSave = false
    local SAVE_DEBOUNCE = 2

    local function prep()
        if not fs.hasFolder(DIR) then fs.makeFolder(DIR) end
    end
    function cfg.load()
        prep()
        if not fs.hasFile(FILE) then return end
        local content = fs.read(FILE)
        if content == "" then return end
        local ok, t = pcall(svc.Http.JSONDecode, svc.Http, content)
        if ok and type(t) == "table" then cfg._data = t end
    end
    function cfg.save()
        prep()
        local ok, s = pcall(svc.Http.JSONEncode, svc.Http, cfg._data)
        if ok then
            local writeOk, writeErr = pcall(function() fs.write(FILE, s) end)
            if not writeOk then warn("[v1prware] Config save failed: " .. tostring(writeErr)) end
        end
    end
    function cfg.get(k, default)
        local v = cfg._data[k]
        return v ~= nil and v or default
    end
    function cfg.set(k, v)
        cfg._data[k] = v
        if not pendingSave then
            pendingSave = true
            task.delay(SAVE_DEBOUNCE, function() cfg.save(); pendingSave = false end)
        end
    end
    cfg._data = {}
    cfg.load()
end

------------------------------------------------------------------------
-- WindUI
------------------------------------------------------------------------
local WIND_DIR  = "Viperware"
local WIND_FILE = WIND_DIR .. "/WindUI.lua"
local WIND_URL  = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"

local function loadWindUI()
    if not fs.hasFolder(WIND_DIR) then fs.makeFolder(WIND_DIR) end
    if fs.hasFile(WIND_FILE) then
        local src = fs.read(WIND_FILE)
        if src and #src > 100 then
            local ok, result = pcall(loadstring, src)
            if ok and result then
                local ok2, ui = pcall(result)
                if ok2 and ui then return ui end
            end
        end
        pcall(function() fs.write(WIND_FILE, "") end)
    end
    local src = game:HttpGet(WIND_URL)
    pcall(function() fs.write(WIND_FILE, src) end)
    return loadstring(src)()
end

local ui = loadWindUI()

local win = ui:CreateWindow({
    Title          = "V1PRWARE",
    Icon           = "sparkles",
    Author         = "V1PR / Glovsaken",
    Folder         = "Viperware",
    Size           = UDim2.fromOffset(350, 300),
    Transparent    = false,
    Theme          = "Dark",
    Resizable      = false,
    SideBarWidth   = 150,
    HideSearchBar  = true,
    ScrollBarEnabled = false,
})

win:SetToggleKey(Enum.KeyCode.L)
ui:SetFont("rbxasset://fonts/families/AccanthisADFStd.json")

win:EditOpenButton({
    Title          = "V1PRWARE",
    Icon           = "sparkles",
    CornerRadius   = UDim.new(0, 16),
    StrokeThickness = 0,
    Color = ColorSequence.new(Color3.fromHex("000000"), Color3.fromHex("000000")),
    OnlyMobile = true,
    Enabled    = true,
    Draggable  = true,
})

-- ConfigManager (EXACT same as Hutao)
local ConfigManager = win.ConfigManager
local viperConfig = ConfigManager:CreateConfig("viperware-forsaken")

------------------------------------------------------------------------
-- helpers
------------------------------------------------------------------------
local function getTeamFolder(name)
    local root = svc.WS:FindFirstChild("Players")
    return root and root:FindFirstChild(name)
end
local function getIngame()
    local m = svc.WS:FindFirstChild("Map")
    return m and m:FindFirstChild("Ingame")
end
local function getMapContent()
    local ig = getIngame()
    return ig and ig:FindFirstChild("Map")
end

local _networkModule = nil
local function getNetwork()
    if _networkModule then return _networkModule end
    local ok, m = pcall(function() return require(svc.RS.Modules.Network.Network) end)
    if ok and m then _networkModule = m end
    return _networkModule
end

------------------------------------------------------------------------
-- TAB: SETTINGS (with Flags)
------------------------------------------------------------------------
local tabSettings = win:Tab({ Title = "Setting", Icon = "settings" })
local secInterface = tabSettings:Section({ Title = "Interface", Opened = true })

local spoofActive = false
local spoofText   = "V1PRWARE"
local spoofCache  = {}
local spoofConns  = {}

local function spoofApply(lbl)
    if not (lbl:IsA("TextLabel") or lbl:IsA("TextButton")) then return end
    if lbl.Name ~= "Username" then return end
    if not spoofCache[lbl] then spoofCache[lbl] = lbl.Text end
    if spoofActive then lbl.Text = spoofText end
end
local function spoofRevert()
    for lbl, orig in pairs(spoofCache) do if lbl and lbl.Parent then lbl.Text = orig end end
    spoofCache = {}
end
local function spoofScan()
    local pg = lp:FindFirstChild("PlayerGui"); if not pg then return end
    task.defer(function()
        for _, root in ipairs({ pg:FindFirstChild("MainUI"), pg:FindFirstChild("TemporaryUI") }) do
            if root then for _, obj in ipairs(root:GetDescendants()) do spoofApply(obj) end end
        end
    end)
end
local function spoofWatch(root)
    if not root then return end
    table.insert(spoofConns, root.DescendantAdded:Connect(function(obj)
        if spoofActive then task.defer(spoofApply, obj) end
    end))
end
local function spoofStart()
    for _, c in ipairs(spoofConns) do if c.Connected then c:Disconnect() end end
    spoofConns = {}
    local pg = lp:FindFirstChild("PlayerGui"); if not pg then return end
    spoofScan()
    spoofWatch(pg:FindFirstChild("MainUI"))
    spoofWatch(pg:FindFirstChild("TemporaryUI"))
    table.insert(spoofConns, pg.ChildAdded:Connect(function(child)
        if (child.Name == "MainUI" or child.Name == "TemporaryUI") and spoofActive then
            task.delay(0.1, spoofScan); spoofWatch(child)
        end
    end))
end
local function spoofStop()
    for _, c in ipairs(spoofConns) do if c.Connected then c:Disconnect() end end
    spoofConns = {}; spoofRevert()
end

secInterface:Toggle({
    Title = "Spoof Usernames", 
    Type = "Checkbox", 
    Flag = "spoofActive",
    Default = false,
    Callback = function(on) 
        spoofActive = on
        if on then spoofStart() else spoofStop() end 
    end
})

local chatForceEnabled = false
local chatForceConn    = nil
local function enforceChatOn()
    if not chatForceEnabled then return end
    local cw = svc.TextChat:FindFirstChild("ChatWindowConfiguration")
    local ci = svc.TextChat:FindFirstChild("ChatInputBarConfiguration")
    if cw and not cw.Enabled then cw.Enabled = true end
    if ci and not ci.Enabled then ci.Enabled = true end
end
secInterface:Toggle({
    Title = "Show Chat Logs", 
    Type = "Checkbox",
    Flag = "chatForceEnabled",
    Default = false,
    Callback = function(on)
        chatForceEnabled = on
        if chatForceConn then chatForceConn:Disconnect(); chatForceConn = nil end
        if on then
            enforceChatOn()
            chatForceConn = svc.Run.Heartbeat:Connect(enforceChatOn)
            for _, key in ipairs({ "ChatWindowConfiguration", "ChatInputBarConfiguration" }) do
                local obj = svc.TextChat:FindFirstChild(key)
                if obj then obj:GetPropertyChangedSignal("Enabled"):Connect(enforceChatOn) end
            end
        end
    end
})

local timerSide = "Middle"
local function applyTimerPos()
    local rt = lp.PlayerGui:FindFirstChild("RoundTimer")
    local m  = rt and rt:FindFirstChild("Main")
    if m then m.Position = UDim2.new(timerSide == "Middle" and 0.5 or 0.9, 0, m.Position.Y.Scale, m.Position.Y.Offset) end
end
applyTimerPos()
secInterface:Dropdown({
    Title = "Timer Position", 
    Values = { "Middle", "Right" },
    Flag = "timerSide",
    Value = "Middle",
    Callback = function(v) timerSide = v; applyTimerPos() end
})
lp.CharacterAdded:Connect(function()
    task.delay(1, function() if spoofActive then spoofStart() end; applyTimerPos() end)
end)

local secPlatform = tabSettings:Section({ Title = "Platform Spoofer", Opened = true })
local platEnabled = false
local platDevice  = "Console"
local platLoop    = nil
local platConn    = nil

local function platPush()
    if not platEnabled then return end
    local net = getNetwork()
    if net then pcall(function() net:FireServerConnection("SetDevice", "REMOTE_EVENT", platDevice) end) end
end
local function platStart()
    if platLoop then return end; platPush()
    if platConn then platConn:Disconnect() end
    platConn = svc.Input.LastInputTypeChanged:Connect(function() if platEnabled then platPush() end end)
    platLoop = task.spawn(function() while platEnabled do platPush(); task.wait(1) end; platLoop = nil end)
end
local function platStop()
    platEnabled = false
    if platLoop then task.cancel(platLoop); platLoop = nil end
    if platConn then platConn:Disconnect(); platConn = nil end
end
secPlatform:Toggle({ 
    Title = "Enable Spoofer", 
    Type = "Checkbox",
    Flag = "platEnabled",
    Default = false,
    Callback = function(on) 
        platEnabled = on
        if on then platStart() else platStop() end 
    end 
})
secPlatform:Dropdown({ 
    Title = "Device", 
    Values = { "PC", "Mobile", "Console" },
    Flag = "platDevice",
    Value = "Console",
    Callback = function(v) platDevice = v; if platEnabled then platPush() end end 
})
lp.CharacterAdded:Connect(function() task.delay(1, function() if platEnabled then platPush() end end) end)

------------------------------------------------------------------------
-- TAB: GLOBAL (with Flags)
------------------------------------------------------------------------
local tabGlobal  = win:Tab({ Title = "Global", Icon = "globe" })
local secStamina = tabGlobal:Section({ Title = "Stamina", Opened = true })

local stam = {
    on      = false,
    loss    = 10,
    gain    = 20,
    max     = 100,
    current = 100,
    noLoss  = false,
    thread  = nil,
}

local function stamModule()
    local ok, m = pcall(function() return require(svc.RS.Systems.Character.Game.Sprinting) end)
    return ok and m or nil
end
local function stamIsKiller()
    local ch = lp.Character; if not ch then return false end
    local kf = getTeamFolder("Killers")
    return kf and ch:IsDescendantOf(kf)
end
local function stamApply()
    local m = stamModule(); if not m then return end
    if not m.DefaultsSet then pcall(function() m.Init() end) end
    local forceNoLoss = stam.noLoss or stamIsKiller()
    m.StaminaLoss = stam.loss; m.StaminaGain = stam.gain
    local abilityCapActive = type(m.StaminaCap) == "number" and m.StaminaCap < (m.MaxStamina or math.huge)
    if not abilityCapActive then
        m.MaxStamina = stam.max
        if type(m.StaminaCap) == "number" then m.StaminaCap = stam.max end
    end
    m.StaminaLossDisabled = forceNoLoss
    if m.Stamina and m.Stamina > stam.max then m.Stamina = stam.current end
    pcall(function() if m.__staminaChangedEvent then m.__staminaChangedEvent:Fire() end end)
end
local function stamStart()
    if stam.thread then return end
    stam.thread = task.spawn(function()
        while stam.on do
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then stamApply() end
            task.wait(0.5)
        end; stam.thread = nil
    end)
end
local function stamStop()
    stam.on = false
    if stam.thread then task.cancel(stam.thread); stam.thread = nil end
end

secStamina:Toggle({ 
    Title = "Custom Stamina", 
    Type = "Checkbox",
    Flag = "stamOn",
    Default = false,
    Callback = function(on) 
        stam.on = on
        if on then stamStart() else stamStop() end 
    end 
})
secStamina:Slider({ 
    Title = "Loss Rate",     
    Flag = "stamLoss",
    Step = 1, 
    Value = { Min = 0,  Max = 50,  Default = 10 },
    Callback = function(v) stam.loss = v end 
})
secStamina:Slider({ 
    Title = "Gain Rate",     
    Flag = "stamGain",
    Step = 1, 
    Value = { Min = 0,  Max = 50,  Default = 20 },
    Callback = function(v) stam.gain = v end 
})
secStamina:Slider({ 
    Title = "Max Pool",      
    Flag = "stamMax",
    Step = 1, 
    Value = { Min = 50, Max = 500, Default = 100 },
    Callback = function(v) stam.max = v end 
})
secStamina:Slider({ 
    Title = "Current Value", 
    Flag = "stamCurrent",
    Step = 1, 
    Value = { Min = 0,  Max = 500, Default = 100 },
    Callback = function(v) stam.current = v end 
})
secStamina:Toggle({ 
    Title = "Infinite Stamina", 
    Type = "Checkbox",
    Flag = "stamNoLoss",
    Default = false,
    Callback = function(on)
        stam.noLoss = on
        stamApply()
        if on and not stam.on then stam.on = true; stamStart() end
    end
})
if stam.on then stamStart() end
lp.CharacterAdded:Connect(function()
    task.delay(1.5, function()
        if stam.on then stamApply(); if not stam.thread then stamStart() end end
    end)
end)

local secStatus = tabGlobal:Section({ Title = "Status", Opened = true })
local statusGroups = {
    Slowness      = { on = false, paths = { "Modules.Schematics.StatusEffects.Slowness" } },
    Hallucination = { on = false, paths = { "Modules.Schematics.StatusEffects.KillerExclusive.Hallucination" } },
    Visual        = { on = false, paths = {
        "Modules.Schematics.StatusEffects.Blindness",
        "Modules.Schematics.StatusEffects.SurvivorExclusive.Subspaced",
        "Modules.Schematics.StatusEffects.KillerExclusive.Glitched",
    }},
}
local statusBackup = {}
local function statusResolve(path)
    local node = svc.RS
    for seg in path:gmatch("[^%.]+") do node = node:FindFirstChild(seg); if not node then return nil end end
    return node
end
local function statusBlock(path)
    if statusBackup[path] then return end
    local mod = statusResolve(path); if not mod then return end
    if mod:IsA("Folder") then
        statusBackup[path] = { clone = mod:Clone(), isFolder = true, parentPath = path:match("^(.-)%.?[^%.]+$") }
        mod:Destroy()
    elseif mod:IsA("ModuleScript") or mod:IsA("LocalScript") then
        statusBackup[path] = { clone = mod:Clone(), src = mod.Source, isFolder = false }
        mod:Destroy()
    end
end
local function statusRestore(path)
    local saved = statusBackup[path]; if not saved then return end
    local existing = statusResolve(path); if existing then existing:Destroy() end
    local parentPath = saved.parentPath or path:match("^(.-)%.?[^%.]+$")
    local parent = statusResolve(parentPath)
    if parent then
        if not saved.isFolder then saved.clone.Source = saved.src end
        saved.clone.Parent = parent
    end
    statusBackup[path] = nil
end
local statusLoopThread = nil
local function statusTick()
    if statusLoopThread then return end
    statusLoopThread = task.spawn(function()
        while true do
            local any = false
            for _, g in pairs(statusGroups) do
                if g.on then any = true; for _, p in ipairs(g.paths) do local m = statusResolve(p); if m then m:Destroy() end end end
            end
            if not any then break end; task.wait(0.8)
        end; statusLoopThread = nil
    end)
end
local function statusToggle(name)
    local g = statusGroups[name]; if not g then return end; g.on = not g.on
    for _, p in ipairs(g.paths) do if g.on then statusBlock(p) else statusRestore(p) end end
    local any = false; for _, sg in pairs(statusGroups) do if sg.on then any = true; break end end
    if any then statusTick() elseif statusLoopThread then task.cancel(statusLoopThread); statusLoopThread = nil end
end
secStatus:Button({ Title = "Toggle: Slowness",       Callback = function() statusToggle("Slowness")      end })
secStatus:Button({ Title = "Toggle: Hallucination",  Callback = function() statusToggle("Hallucination") end })
secStatus:Button({ Title = "Toggle: Visual Effects", Callback = function() statusToggle("Visual")        end })
lp.CharacterAdded:Connect(function()
    statusBackup = {}; for _, g in pairs(statusGroups) do g.on = false end
    if statusLoopThread then task.cancel(statusLoopThread); statusLoopThread = nil end
end)

------------------------------------------------------------------------
-- HITBOX (with Flags)
------------------------------------------------------------------------
local secHitbox = tabGlobal:Section({ Title = "Hitbox", Opened = true })
local hb = { on = false, strength = 50, conn = nil, active = {} }

local hbAbilities = {
    Slash=1,Swing=1,Dagger=1,Punch=1,PlasmaBeam=1,Shoot=1,Behead=1,
    GashingWound=1,WalkspeedOverride=1,Stab=1,Nova=1,MassInfection=1,
    Axe=1,["INFERNALCRY"]=1,["Carving Slash"]=1,Carving=1,
}

local function hbReadName(raw)
    if typeof(raw) == "buffer" then
        local s = buffer.tostring(raw)
        local name = s:match("^[%c%z%p]*(.+)$") or s
        name = name:match("^(.-)%s*$") or name
        return name ~= "" and name or nil
    end
    return tostring(raw):gsub("\"","")
end

local function hbPush(dist)
    local ch = lp.Character; if not ch then return end
    local r  = ch:FindFirstChild("HumanoidRootPart"); if not r then return end
    local was = r.AssemblyLinearVelocity
    r.AssemblyLinearVelocity = was + r.CFrame.LookVector * dist
    svc.Run.RenderStepped:Wait()
    if ch and ch.Parent and r and r.Parent then r.AssemblyLinearVelocity = was end
end

local _hbRemote = nil
local function hbGetRemote()
    if _hbRemote and _hbRemote.Parent then return _hbRemote end
    local ok, re = pcall(function()
        return svc.RS.Modules.Network.Network:FindFirstChild("RemoteEvent")
    end)
    if ok and re then _hbRemote = re; return re end
    return nil
end

local function hbStart()
    if hb.conn then return end
    local remote = hbGetRemote()
    if not remote then warn("[v1prware] hbStart: could not find RemoteEvent for hitbox — feature disabled"); return end
    hb.conn = remote.OnClientEvent:Connect(function(action, data)
        if not hb.on or action ~= "UseActorAbility" then return end
        if typeof(data) ~= "table" or not data[1] then return end
        local name = hbReadName(data[1])
        if not name or not hbAbilities[name] or hb.active[name] then return end
        hb.active[name] = true; local t0 = tick()
        local c; c = svc.Run.Heartbeat:Connect(function()
            if tick() - t0 >= 1 then c:Disconnect(); hb.active[name] = nil; return end
            if hb.on then hbPush(hb.strength) else c:Disconnect(); hb.active[name] = nil end
        end)
    end)
end
local function hbStop()
    if hb.conn then hb.conn:Disconnect(); hb.conn = nil end
    for k in pairs(hb.active) do hb.active[k] = nil end
end
secHitbox:Toggle({ 
    Title = "Hitbox Expander", 
    Type = "Checkbox",
    Flag = "hbOn",
    Default = false,
    Callback = function(on) 
        hb.on = on
        if on then hbStart() else hbStop() end 
    end 
})
secHitbox:Slider({ 
    Title = "Strength",
    Flag = "hbStrength",
    Step = 1, 
    Value = { Min = 5, Max = 100, Default = 50 },
    Callback = function(v) hb.strength = v end 
})
lp.CharacterAdded:Connect(function()
    for k in pairs(hb.active) do hb.active[k] = nil end
    task.delay(1, function() if hb.on then hbStop(); hbStart() end end)
end)
lp.CharacterRemoving:Connect(function() for k in pairs(hb.active) do hb.active[k] = nil end end)

------------------------------------------------------------------------
-- AUTO COLLISION (with Flags)
------------------------------------------------------------------------
local ac = {
    on         = false,
    strength   = 50,
    maxDist    = 100,
    active     = {},
    chaseTarget  = nil,
    damageTarget = nil,
}

local function acGetHRP(model)
    if not model or not model.Parent then return nil end
    local h = model:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return nil end
    local r = model:FindFirstChild("HumanoidRootPart")
    return r and r.Parent and r or nil
end

local function acFindChaseTarget()
    local sf = getTeamFolder("Survivors"); if not sf then return nil end
    for _, model in ipairs(sf:GetChildren()) do
        if model ~= lp.Character and model:IsA("Model") then
            local chased = model:GetAttribute("IsChased") or model:GetAttribute("InChase")
                        or model:GetAttribute("ChasedBy") or model:GetAttribute("IsBeingChased")
            if chased and chased ~= false and chased ~= "" then
                local r = acGetHRP(model); if r then return r end
            end
        end
    end
    return nil
end

local function acPickTarget()
    if ac.chaseTarget and ac.chaseTarget.Parent then
        local model = ac.chaseTarget.Parent
        local h = model:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
            local chased = model:GetAttribute("IsChased") or model:GetAttribute("InChase")
                        or model:GetAttribute("ChasedBy") or model:GetAttribute("IsBeingChased")
            if chased and chased ~= false and chased ~= "" then return ac.chaseTarget end
        end
        ac.chaseTarget = nil
    end
    local fresh = acFindChaseTarget()
    if fresh then ac.chaseTarget = fresh; return fresh end
    if ac.damageTarget and ac.damageTarget.Parent then
        local model = ac.damageTarget.Parent
        local h = model:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then return ac.damageTarget end
        ac.damageTarget = nil
    end
    local sf = getTeamFolder("Survivors"); local myChar = lp.Character
    if not sf or not myChar then return nil end
    local origin = myChar:FindFirstChild("QueryHitbox", true) or myChar:FindFirstChild("HumanoidRootPart")
    if not origin then return nil end
    local myPos = origin.Position
    local best, bd = nil, math.huge
    for _, model in ipairs(sf:GetChildren()) do
        if model ~= myChar and model:IsA("Model") then
            local r = acGetHRP(model)
            if r then local d = (r.Position - myPos).Magnitude; if d < bd and d <= ac.maxDist then bd = d; best = r end end
        end
    end
    return best
end

local function acPickKillerTarget()
    local kf = getTeamFolder("Killers"); local myChar = lp.Character
    if not kf or not myChar then return nil end
    local origin = myChar:FindFirstChild("HumanoidRootPart"); if not origin then return nil end
    local myPos = origin.Position
    local best, bd = nil, math.huge
    for _, model in ipairs(kf:GetChildren()) do
        if model ~= myChar and model:IsA("Model") then
            local r = acGetHRP(model)
            if r then local d = (r.Position - myPos).Magnitude; if d < bd and d <= ac.maxDist then bd = d; best = r end end
        end
    end
    return best
end

local function acPush(targetRoot, facingOverrideCFrame)
    if not targetRoot or not targetRoot.Parent then return end
    local myChar = lp.Character; if not myChar then return end
    local hrp = myChar:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local dir = (targetRoot.Position - hrp.Position)
    if dir.Magnitude < 0.1 then return end
    dir = dir.Unit
    local lookDir
    if facingOverrideCFrame then
        lookDir = facingOverrideCFrame.LookVector * Vector3.new(1, 0, 1)
    else
        lookDir = dir * Vector3.new(1, 0, 1)
    end
    if lookDir.Magnitude > 0.01 then
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + lookDir.Unit)
    end
    local was = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = was + dir * ac.strength
    svc.Run.RenderStepped:Wait()
    if myChar and myChar.Parent and hrp and hrp.Parent then hrp.AssemblyLinearVelocity = was end
end

local acAttrConns = {}
local function acWatchModel(model)
    if acAttrConns[model] then return end
    acAttrConns[model] = model.AttributeChanged:Connect(function(attr)
        if attr ~= "IsChased" and attr ~= "InChase" and attr ~= "ChasedBy" and attr ~= "IsBeingChased" then return end
        local chased = model:GetAttribute(attr)
        if chased and chased ~= false and chased ~= "" then
            local r = acGetHRP(model); if r then ac.chaseTarget = r end
        else
            if ac.chaseTarget and ac.chaseTarget.Parent == model then ac.chaseTarget = nil end
        end
    end)
end
local function acStopWatchModel(model)
    if acAttrConns[model] then pcall(function() acAttrConns[model]:Disconnect() end); acAttrConns[model] = nil end
end
local function acSetupWatchers()
    local sf = getTeamFolder("Survivors"); if not sf then return end
    for _, model in ipairs(sf:GetChildren()) do if model:IsA("Model") then acWatchModel(model) end end
    sf.ChildAdded:Connect(function(child) if child:IsA("Model") then task.wait(0.1); acWatchModel(child) end end)
    sf.ChildRemoved:Connect(function(child)
        acStopWatchModel(child)
        if ac.chaseTarget  and ac.chaseTarget.Parent  == child then ac.chaseTarget  = nil end
        if ac.damageTarget and ac.damageTarget.Parent == child then ac.damageTarget = nil end
    end)
end

task.spawn(function()
    local remote = hbGetRemote()
    if not remote then warn("[v1prware] AutoCollision: could not find RemoteEvent — feature disabled"); return end
    task.spawn(acSetupWatchers)
    remote.OnClientEvent:Connect(function(action, data)
        if not ac.on then return end
        if action ~= "UseActorAbility" then return end
        if typeof(data) ~= "table" or not data[1] then return end
        local name = hbReadName(data[1])
        if not name or not hbAbilities[name] then return end
        if ac.active[name] then return end
        local myChar = lp.Character
        local killerFolder   = getTeamFolder("Killers")
        local survivorFolder = getTeamFolder("Survivors")
        local amKiller   = killerFolder   and myChar and myChar:IsDescendantOf(killerFolder)
        local amSurvivor = survivorFolder and myChar and myChar:IsDescendantOf(survivorFolder)
        if amKiller and data[2] and typeof(data[2]) == "Instance" then
            local hrpTarget = nil
            if data[2]:IsA("Model") then
                hrpTarget = data[2]:FindFirstChild("HumanoidRootPart")
            elseif data[2]:IsA("BasePart") then
                local model = data[2]:FindFirstAncestorOfClass("Model")
                if model then hrpTarget = model:FindFirstChild("HumanoidRootPart") end
            end
            if hrpTarget and hrpTarget.Parent then
                local sf = getTeamFolder("Survivors")
                if sf and hrpTarget.Parent:IsDescendantOf(sf) then
                    local h = hrpTarget.Parent:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then ac.damageTarget = hrpTarget end
                end
            end
        end
        ac.active[name] = true
        local t0 = tick()
        local conn; conn = svc.Run.Heartbeat:Connect(function()
            if tick() - t0 >= 1 or not ac.on then conn:Disconnect(); ac.active[name] = nil; return end
            local target
            local facingOverride = nil
            if amKiller then
                target = acPickTarget()
            elseif amSurvivor then
                target = acPickKillerTarget()
                if target and target.Parent and target.Parent.Name == "TwoTime" and name == "Stab" then
                    facingOverride = target.CFrame
                end
            end
            if target then task.spawn(acPush, target, facingOverride) end
        end)
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if ac.on then local fresh = acFindChaseTarget(); if fresh then ac.chaseTarget = fresh end end
    end
end)

lp.CharacterAdded:Connect(function()
    for k in pairs(ac.active) do ac.active[k] = nil end
    ac.chaseTarget = nil; ac.damageTarget = nil
end)
lp.CharacterRemoving:Connect(function()
    for k in pairs(ac.active) do ac.active[k] = nil end
    ac.chaseTarget = nil; ac.damageTarget = nil
end)

local secAutoCollision = tabGlobal:Section({ Title = "Auto Collision", Opened = true })
secAutoCollision:Toggle({
    Title = "Push Hitbox on Ability", 
    Type = "Checkbox",
    Flag = "acOn",
    Default = false,
    Callback = function(on)
        ac.on = on
        if not on then for k in pairs(ac.active) do ac.active[k] = nil end; ac.chaseTarget = nil; ac.damageTarget = nil end
    end
})
secAutoCollision:Slider({ 
    Title = "Push Strength",
    Flag = "acStrength",
    Step = 1, 
    Value = { Min = 5,  Max = 100, Default = 50 },
    Callback = function(v) ac.strength = v end 
})
secAutoCollision:Slider({ 
    Title = "Max Distance",
    Flag = "acMaxDist",
    Step = 5, 
    Value = { Min = 20, Max = 200, Default = 100 },
    Callback = function(v) ac.maxDist = v end 
})

------------------------------------------------------------------------
-- TAB: GENERATOR (with Flags)
------------------------------------------------------------------------
local tabGen     = win:Tab({ Title = "Generator", Icon = "circuit-board" })
local secGenAuto = tabGen:Section({ Title = "Auto Solve", Opened = true })

local flow = { on = false, nodeDelay = 0.04, lineDelay = 0.60 }
local function flowKey(n) return n.row.."-"..n.col end
local function flowNeighbour(r1,c1,r2,c2)
    if r2==r1-1 and c2==c1 then return"up" end; if r2==r1+1 and c2==c1 then return"down" end
    if r2==r1 and c2==c1-1 then return"left" end; if r2==r1 and c2==c1+1 then return"right" end; return false
end
local function flowOrder(path, endpoints)
    if not path or #path == 0 then return path end
    local lookup = {}
    for _, n in ipairs(path) do lookup[flowKey(n)] = n end
    local start
    for _, ep in ipairs(endpoints or {}) do
        for _, n in ipairs(path) do
            if n.row == ep.row and n.col == ep.col then start = { row = ep.row, col = ep.col }; break end
        end
        if start then break end
    end
    if not start then
        for _, n in ipairs(path) do
            local nb = 0
            for _, d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
                if lookup[(n.row+d[1]).."-"..(n.col+d[2])] then nb += 1 end
            end
            if nb == 1 then start = { row = n.row, col = n.col }; break end
        end
    end
    if not start then start = { row = path[1].row, col = path[1].col } end
    local pool, ordered = {}, {}
    for _, n in ipairs(path) do pool[flowKey(n)] = { row = n.row, col = n.col } end
    local cur = start
    table.insert(ordered, { row = cur.row, col = cur.col }); pool[flowKey(cur)] = nil
    while next(pool) do
        local moved = false
        for k, node in pairs(pool) do
            if flowNeighbour(cur.row, cur.col, node.row, node.col) then
                table.insert(ordered, { row = node.row, col = node.col })
                pool[k] = nil; cur = node; moved = true; break
            end
        end
        if not moved then break end
    end
    return ordered
end
local function flowSolve(puzzle)
    if not puzzle or not puzzle.Solution then return end
    local indices = {}
    for i = 1, #puzzle.Solution do indices[i] = i end
    for i = #indices, 2, -1 do local j = math.random(1, i); indices[i], indices[j] = indices[j], indices[i] end
    for _, ci in ipairs(indices) do
        local solution = puzzle.Solution[ci]; if not solution then continue end
        local ordered = flowOrder(solution, puzzle.targetPairs[ci])
        if not ordered or #ordered == 0 then continue end
        puzzle.paths[ci] = {}
        for _, node in ipairs(ordered) do
            table.insert(puzzle.paths[ci], { row = node.row, col = node.col })
            puzzle:updateGui(); task.wait(flow.nodeDelay)
        end
        task.wait(flow.lineDelay); puzzle:checkForWin()
    end
end
do
    local modFolder  = svc.RS:FindFirstChild("Modules")
    local miniFolder = modFolder and modFolder:FindFirstChild("Minigames")
    local fgFolder   = miniFolder and miniFolder:FindFirstChild("FlowGameManager")
    local fgModule   = fgFolder and fgFolder:FindFirstChild("FlowGame")
    if fgModule then
        local ok, FG = pcall(require, fgModule)
        if ok and FG and FG.new then
            local orig = FG.new
            FG.new = function(...)
                local p = orig(...)
                if flow.on then task.spawn(function() task.wait(0.3); flowSolve(p) end) end
                return p
            end
        else warn("[v1prware] FlowGame: failed to require FlowGame module — auto-solve disabled") end
    else warn("[v1prware] FlowGame: FlowGame not found — auto-solve disabled") end
end
secGenAuto:Toggle({ 
    Title = "Auto Solve", 
    Type = "Checkbox",
    Flag = "flowOn",
    Default = false,
    Callback = function(on) flow.on = on end 
})
secGenAuto:Slider({ 
    Title = "Node Speed",
    Flag = "flowNodeDelay",
    Step = 0.02, 
    Value = { Min = 0.01, Max = 0.50, Default = 0.04 },
    Callback = function(v) flow.nodeDelay = v end 
})
secGenAuto:Slider({ 
    Title = "Line Pause",
    Flag = "flowLineDelay",
    Step = 0.10, 
    Value = { Min = 0.00, Max = 1.00, Default = 0.60 },
    Callback = function(v) flow.lineDelay = v end 
})

------------------------------------------------------------------------
-- TAB: KILLER (with Flags)
------------------------------------------------------------------------
local tabKiller = win:Tab({ Title = "Killer", Icon = "crosshair" })

-- AIMBOT SECTION
local secAimbot = tabKiller:Section({ Title = "Aimbot", Opened = true })

local aim = {
    on=false, cooldown=0.3, lockTime=0.4,
    maxDist=30, smooth=0.35,
    targeting=false, target=nil, deathConn=nil, autoRotate=nil, lastFired=0,
    hum=nil, hrp=nil, cache={}, cacheTime=0, cacheLife=0.5,
}
local function aimAmIKiller() local ch=lp.Character; if not ch then return false end; local kf=getTeamFolder("Killers"); return kf and ch:IsDescendantOf(kf) end
local function aimRefreshChar(ch) aim.hum=ch:FindFirstChildOfClass("Humanoid"); aim.hrp=ch:FindFirstChild("HumanoidRootPart") end
local function aimRefreshTargets()
    local now=tick(); if now-aim.cacheTime<aim.cacheLife then return end; aim.cacheTime=now; aim.cache={}
    local sf=getTeamFolder("Survivors"); if not sf then return end
    for _,model in ipairs(sf:GetChildren()) do if model~=lp.Character and model:IsA("Model") then local h=model:FindFirstChildOfClass("Humanoid"); local r=model:FindFirstChild("HumanoidRootPart"); if h and r and h.Health>0 then table.insert(aim.cache,r) end end end
end
local function aimNearest()
    aimRefreshTargets(); if not aim.hrp or #aim.cache==0 then return nil end
    local best,bd=nil,math.huge; for _,r in ipairs(aim.cache) do local d=(r.Position-aim.hrp.Position).Magnitude; if d<bd and d<=aim.maxDist then bd=d; best=r end end; return best
end
local function aimUnlock()
    if not aim.targeting then return end
    if aim.deathConn then aim.deathConn:Disconnect(); aim.deathConn=nil end
    if aim.autoRotate~=nil and aim.hum and aim.hum.Parent then pcall(function() aim.hum.AutoRotate=aim.autoRotate end) end
    aim.targeting=false; aim.target=nil
end
local function aimLock(r)
    if not r or not r.Parent or not aim.hum or not aim.hrp then return end
    if aim.targeting and aim.target==r then return end
    aimUnlock(); aim.target=r; aim.targeting=true; aim.autoRotate=aim.hum.AutoRotate; aim.hum.AutoRotate=false
    local th=r.Parent:FindFirstChildOfClass("Humanoid"); if th then aim.deathConn=th.Died:Connect(aimUnlock) end
    task.delay(aim.lockTime, function() if aim.target==r then aimUnlock() end end)
end
svc.Run.RenderStepped:Connect(function()
    if not aim.on or not aim.targeting or not aim.hrp or not aim.target then return end
    if not aim.target.Parent then aimUnlock(); return end
    local th=aim.target.Parent:FindFirstChildOfClass("Humanoid"); if not th or th.Health<=0 then aimUnlock(); return end
    local flat=Vector3.new(aim.target.Position.X-aim.hrp.Position.X,0,aim.target.Position.Z-aim.hrp.Position.Z).Unit
    if flat.Magnitude>0 then aim.hrp.CFrame=aim.hrp.CFrame:Lerp(CFrame.new(aim.hrp.Position,aim.hrp.Position+flat),aim.smooth) end
end)
task.spawn(function()
    local remote = hbGetRemote()
    if not remote then warn("[v1prware] Aimbot: could not find RemoteEvent — aimbot trigger disabled"); return end
    remote.OnClientEvent:Connect(function(...)
        if not aim.on then return end
        local a={...}; if typeof(a[1])~="string" then return end; local n=a[1]
        if not (n:match("Ability") or n:match("[QER]") or n=="Slash" or n=="Dagger" or n=="Charge") then return end
        if tick()-aim.lastFired<aim.cooldown then return end; aim.lastFired=tick()
        if aimAmIKiller() then local t=aimNearest(); if t then aimLock(t) end end
    end)
end)
lp.CharacterAdded:Connect(function(ch) task.wait(0.5); aimRefreshChar(ch) end)
if lp.Character then aimRefreshChar(lp.Character) end

secAimbot:Toggle({ 
    Title="Enable Aimbot",
    Flag="aimOn",
    Type="Checkbox",
    Default=false,
    Callback=function(on) aim.on=on; if not on then aimUnlock() end end 
})
secAimbot:Slider({ 
    Title="Cooldown (s)",
    Flag="aimCooldown",
    Step=0.05,
    Value={Min=0.1, Max=2.0, Default=0.3},
    Callback=function(v) aim.cooldown=v end 
})
secAimbot:Slider({ 
    Title="Lock Time (s)",
    Flag="aimLockTime",
    Step=0.1,
    Value={Min=0.1, Max=3.0, Default=0.4},
    Callback=function(v) aim.lockTime=v end 
})
secAimbot:Slider({ 
    Title="Max Distance",
    Flag="aimMaxDist",
    Step=5,
    Value={Min=5, Max=100, Default=30},
    Callback=function(v) aim.maxDist=v end 
})
secAimbot:Slider({ 
    Title="Rotation Smoothing",
    Flag="aimSmooth",
    Step=0.05,
    Value={Min=0.05,Max=1.0, Default=0.35},
    Callback=function(v) aim.smooth=v end 
})

-- ANTI-BACKSTAB SECTION
local secABS = tabKiller:Section({ Title = "Anti-Backstab", Opened = true })
local abs = { on=false, range=40, duration=1.5, locked=false, soundConn=nil, scanThread=nil, rings={} }
local absTriggerSounds = { ["86710781315432"]=true, ["99820161736138"]=true }
local absScreenGui = nil
local function absGui()
    if absScreenGui and absScreenGui.Parent then return absScreenGui end
    local pg=lp:FindFirstChild("PlayerGui"); if not pg then return nil end
    absScreenGui=Instance.new("ScreenGui"); absScreenGui.Name="AbsGui"; absScreenGui.ResetOnSpawn=false; absScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; absScreenGui.Parent=pg; return absScreenGui
end
local function absShowLabel(show)
    local g=absGui(); if not g then return end; local lbl=g:FindFirstChild("AbsTaunt")
    if not lbl then lbl=Instance.new("TextLabel"); lbl.Name="AbsTaunt"; lbl.Size=UDim2.new(0,500,0,50); lbl.Position=UDim2.new(0.5,-250,0.38,0); lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.new(1,1,1); lbl.TextStrokeTransparency=0.4; lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.Text="At least they tried 😂"; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=36; lbl.TextTransparency=1; lbl.Parent=g end
    pcall(function() svc.TweenService:Create(lbl,TweenInfo.new(show and 0.15 or 0.5),{TextTransparency=show and 0 or 1}):Play() end)
end
local function absAddRing(model)
    local hrp=model:FindFirstChild("HumanoidRootPart"); if not hrp or abs.rings[model] then return end
    pcall(function()
        local ring=Instance.new("Part"); ring.Name="AbsRing"; ring.Shape=Enum.PartType.Cylinder; ring.Size=Vector3.new(0.1,abs.range*2,abs.range*2); ring.Color=Color3.fromRGB(220,50,50); ring.Material=Enum.Material.ForceField; ring.Transparency=0.5; ring.CanCollide=false; ring.CanTouch=false; ring.CFrame=hrp.CFrame*CFrame.Angles(0,0,math.rad(90)); ring.Parent=hrp
        local w=Instance.new("WeldConstraint"); w.Part0=hrp; w.Part1=ring; w.Parent=ring; abs.rings[model]=ring
    end)
end
local function absRemoveRing(model) local r=abs.rings[model]; if r then pcall(function()r:Destroy()end); abs.rings[model]=nil end end
local function absResizeRings() for _,r in pairs(abs.rings) do if r and r.Parent then r.Size=Vector3.new(0.1,abs.range*2,abs.range*2) end end end
local function absCleanRings() for m in pairs(abs.rings) do absRemoveRing(m) end end
local function absFindTwoTime() local players=svc.WS:FindFirstChild("Players"); if not players then return nil end; for _,folder in ipairs(players:GetChildren()) do local tt=folder:FindFirstChild("TwoTime"); if tt then return tt end end; return nil end
local function absTrigger()
    if abs.locked then return end; local ch=lp.Character; local myRoot=ch and ch:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    local ttModel=absFindTwoTime(); if not ttModel then return end; local ttRoot=ttModel:FindFirstChild("HumanoidRootPart"); if not ttRoot then return end
    if (myRoot.Position-ttRoot.Position).Magnitude>abs.range then return end
    abs.locked=true; absShowLabel(true)
    task.spawn(function()
        local deadline=tick()+abs.duration
        while tick()<deadline do if not abs.on then break end; local ch2=lp.Character; local r2=ch2 and ch2:FindFirstChild("HumanoidRootPart"); if not r2 or not ttRoot.Parent then break end; r2.CFrame=CFrame.lookAt(r2.Position,Vector3.new(ttRoot.Position.X,r2.Position.Y,ttRoot.Position.Z)); svc.Run.RenderStepped:Wait() end
        abs.locked=false; absShowLabel(false)
    end)
end
local function absHookSounds()
    if abs.soundConn then abs.soundConn:Disconnect(); abs.soundConn=nil end
    local function checkSound(obj)
        if not abs.on or not obj:IsA("Sound") then return end
        local id = obj.SoundId:match("%d+")
        if id and absTriggerSounds[id] then absTrigger() end
    end
    abs.soundConn=svc.WS.DescendantAdded:Connect(function(obj)
        if obj:IsA("Sound") then
            checkSound(obj)
            obj:GetPropertyChangedSignal("SoundId"):Connect(function() checkSound(obj) end)
        end
    end)
end
local function absStartScan()
    if abs.scanThread then return end
    abs.scanThread=task.spawn(function()
        while abs.on do
            local players=svc.WS:FindFirstChild("Players")
            if players then for _,folder in ipairs(players:GetChildren()) do for _,model in ipairs(folder:GetChildren()) do if model.Name=="TwoTime" then absAddRing(model) end end end end
            for m in pairs(abs.rings) do if not m.Parent then absRemoveRing(m) end end; task.wait(1)
        end; abs.scanThread=nil
    end)
end
local function absStart() absHookSounds(); absStartScan() end
local function absStop() abs.on=false; if abs.soundConn then abs.soundConn:Disconnect(); abs.soundConn=nil end; if abs.scanThread then task.cancel(abs.scanThread); abs.scanThread=nil end; absCleanRings(); abs.locked=false; absShowLabel(false) end
lp.CharacterAdded:Connect(function() abs.locked=false; if abs.on then absStart() end end)
task.spawn(function()
    while true do
        task.wait(10)
        local deadRings = {}
        for model, ring in pairs(abs.rings) do
            if not model or not model.Parent or not ring or not ring.Parent then table.insert(deadRings, model) end
        end
        for _, model in ipairs(deadRings) do abs.rings[model] = nil end
    end
end)

secABS:Toggle({ 
    Title="Enable Anti-Backstab",
    Flag="absOn",
    Type="Checkbox",
    Default=false,
    Callback=function(on) abs.on=on; if on then absStart() else absStop() end end 
})
secABS:Slider({ 
    Title="Detection Range",
    Flag="absRange",
    Step=5,
    Value={Min=10,Max=120,Default=40},
    Callback=function(v) abs.range=v; absResizeRings() end 
})
secABS:Slider({ 
    Title="Look Duration (s)",
    Flag="absDur",
    Step=0.1,
    Value={Min=0.3,Max=5.0,Default=1.5},
    Callback=function(v) abs.duration=v end 
})

-- SIXER AIR STRAFE
local sixerStrafeOn = false
local SIXER_BIND    = "LunawareSixerStrafe"
svc.Run:BindToRenderStep(SIXER_BIND, Enum.RenderPriority.Character.Value + 2, function()
    if not sixerStrafeOn then return end
    local char = lp.Character; if not char then return end
    if char:GetAttribute("PursuitState") ~= "Dashing" then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if hum.FloorMaterial ~= Enum.Material.Air then return end
    local cam  = svc.WS.CurrentCamera
    local flat = cam.CFrame.LookVector * Vector3.new(1, 0, 1)
    if flat.Magnitude < 0.01 then return end
    flat = flat.Unit
    local vel   = hrp.AssemblyLinearVelocity
    local hVel  = Vector3.new(vel.X, 0, vel.Z)
    local hSpeed= hVel.Magnitude
    if hSpeed < 0.1 then return end
    local newH = hVel:Lerp(flat * hSpeed, 1)
    hrp.AssemblyLinearVelocity = Vector3.new(newH.X, vel.Y, newH.Z)
end)

-- C00LKIDD DASH TURN
local coolkidWSOOn = false
local function coolkidGetInputDir()
    local cf       = svc.WS.CurrentCamera.CFrame
    local camFwd   = Vector3.new(cf.LookVector.X,  0, cf.LookVector.Z)
    local camRight = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
    local x, z = 0, 0
    if svc.Input:IsKeyDown(Enum.KeyCode.W) or svc.Input:IsKeyDown(Enum.KeyCode.Up)    then z = z - 1 end
    if svc.Input:IsKeyDown(Enum.KeyCode.S) or svc.Input:IsKeyDown(Enum.KeyCode.Down)  then z = z + 1 end
    if svc.Input:IsKeyDown(Enum.KeyCode.A) or svc.Input:IsKeyDown(Enum.KeyCode.Left)  then x = x - 1 end
    if svc.Input:IsKeyDown(Enum.KeyCode.D) or svc.Input:IsKeyDown(Enum.KeyCode.Right) then x = x + 1 end
    local dir = camFwd * -z + camRight * x
    if dir.Magnitude > 0.01 then return dir.Unit end
    if camFwd.Magnitude > 0.01 then return camFwd.Unit end
    return Vector3.new(0, 0, -1)
end
svc.Run.RenderStepped:Connect(function(dt)
    if not coolkidWSOOn then return end
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then return end
    if char:GetAttribute("FootstepsMuted") ~= true then return end
    local dir = coolkidGetInputDir()
    local lv  = hrp:FindFirstChildWhichIsA("LinearVelocity")
    if lv then lv.LineDirection = dir end
    if dir.Magnitude > 0.01 then
        local targetRot = CFrame.new(hrp.Position, hrp.Position + dir).Rotation
        hrp.CFrame = CFrame.new(hrp.Position) * hrp.CFrame.Rotation:Lerp(targetRot, math.min(dt * 16, 1))
    end
end)

-- NOLI VOID RUSH
local noliVoidRushOn     = false
local noliOverrideActive = false
local noliOrigWalkSpeed  = nil
local noliConn           = nil
local function noliStop()
    if not noliOverrideActive then return end
    noliOverrideActive = false
    local char = lp.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed=noliOrigWalkSpeed or 16; hum.AutoRotate=true; pcall(function() hum:Move(Vector3.new(0,0,0)) end) end
    noliOrigWalkSpeed = nil
    if noliConn then noliConn:Disconnect(); noliConn = nil end
end
local function noliStart()
    if noliOverrideActive then return end
    noliOverrideActive = true
    noliConn = svc.Run.RenderStepped:Connect(function()
        local char = lp.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if not noliOrigWalkSpeed then noliOrigWalkSpeed = hum.WalkSpeed end
        hum.WalkSpeed=60; hum.AutoRotate=false
        local horiz = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
        if horiz.Magnitude > 0 then hum:Move(horiz.Unit) end
    end)
end
svc.Run.RenderStepped:Connect(function()
    if not noliVoidRushOn then if noliOverrideActive then noliStop() end; return end
    local char = lp.Character; if not char then return end
    if char:GetAttribute("VoidRushState") == "Dashing" then noliStart() else noliStop() end
end)
lp.CharacterAdded:Connect(function() noliStop(); noliOrigWalkSpeed = nil end)

-- KILLER ABILITIES SECTION
local secKillerAbilities = tabKiller:Section({ Title = "Killer Abilities", Opened = true })
secKillerAbilities:Toggle({ 
    Title="Sixer — Air Strafe",
    Flag="sixerStrafeOn",
    Type="Checkbox",
    Default=false,
    Callback=function(on) sixerStrafeOn=on end 
})
secKillerAbilities:Toggle({ 
    Title="c00lkidd — Dash Turn",
    Flag="coolkidWSOOn",
    Type="Checkbox",
    Default=false,
    Callback=function(on) coolkidWSOOn=on end 
})
secKillerAbilities:Toggle({ 
    Title="Noli — Void Rush Control",
    Flag="noliVoidRushOn",
    Type="Checkbox",
    Default=false,
    Callback=function(on) noliVoidRushOn=on; if not on then noliStop() end end 
})

------------------------------------------------------------------------
-- TAB: VISUAL (with Flags)
------------------------------------------------------------------------
local tabVisual = win:Tab({ Title = "Visual", Icon = "eye" })
local secDisplay = tabVisual:Section({ Title = "Entity Tracking", Opened = true })

local displaySystem = {
    showKillers    = false,
    showSurvivors  = false,
    showGenerators = false,
    showItems      = false,
    showBuildings  = false,
    activeDisplays    = {},
    eventListeners    = {},
    healthListeners   = {},
    progressListeners = {},
    lifecycleTrackers = {},
    highlightMonitors = {},
    updateThread  = nil,
    initialized   = false,
}

local DISPLAY_CONFIG = {
    STARTUP_DELAY = 2, SPAWN_CHECK_DELAY = 0.1, HEALTH_UPDATE_INTERVAL = 0,
    MAX_CHARACTER_DISTANCE = 2500, MAX_OBJECT_DISTANCE = 1000,
    HIGHLIGHT_OPACITY = 0.8, OUTLINE_VISIBILITY = 0,
    DISPLAY_MODE = Enum.HighlightDepthMode.AlwaysOnTop,
    LABEL_WIDTH = 150, LABEL_HEIGHT = 65, TEXT_SCALE = 13,
    ENTITY_COLORS = {
        THREAT    = Color3.fromRGB(255, 50,  50),
        TEAMMATE  = Color3.fromRGB(255, 255, 50),
        OBJECTIVE = Color3.fromRGB(255, 105, 180),
        LOOT      = Color3.fromRGB(0,   255, 200),
        STRUCTURE = Color3.fromRGB(255, 100, 0),
    }
}

local function removeOverlay(obj, identifier)
    if not obj or not identifier then return end
    pcall(function() if displaySystem.healthListeners[obj] then displaySystem.healthListeners[obj]:Disconnect(); displaySystem.healthListeners[obj] = nil end end)
    pcall(function() if displaySystem.progressListeners[obj] then displaySystem.progressListeners[obj]:Disconnect(); displaySystem.progressListeners[obj] = nil end end)
    pcall(function() if displaySystem.lifecycleTrackers[obj] then displaySystem.lifecycleTrackers[obj]:Disconnect(); displaySystem.lifecycleTrackers[obj] = nil end end)
    pcall(function() if displaySystem.highlightMonitors and displaySystem.highlightMonitors[obj] then if displaySystem.highlightMonitors[obj].Connected then displaySystem.highlightMonitors[obj]:Disconnect() end; displaySystem.highlightMonitors[obj] = nil end end)
    pcall(function() local v = obj:FindFirstChild(identifier .. "_Visual"); if v and v.Parent then v:Destroy() end end)
    pcall(function() local l = obj:FindFirstChild(identifier .. "_Label");  if l and l.Parent then l:Destroy() end end)
    displaySystem.activeDisplays[obj] = nil
end

local function attachOverlay(obj, identifier, overlayColor, isCharacter)
    if not obj or not obj.Parent then return end
    removeOverlay(obj, identifier)
    local anchorPoint = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") or obj:FindFirstChild("Base") or obj:FindFirstChild("Main")
    if not anchorPoint then for _, part in ipairs(obj:GetDescendants()) do if part:IsA("BasePart") then anchorPoint = part; break end end end
    if not anchorPoint then return end
    local visualHighlight = Instance.new("Highlight")
    visualHighlight.Name = identifier .. "_Visual"; visualHighlight.FillColor = overlayColor; visualHighlight.FillTransparency = DISPLAY_CONFIG.HIGHLIGHT_OPACITY
    visualHighlight.OutlineColor = overlayColor; visualHighlight.OutlineTransparency = DISPLAY_CONFIG.OUTLINE_VISIBILITY
    visualHighlight.DepthMode = DISPLAY_CONFIG.DISPLAY_MODE; visualHighlight.Adornee = obj; visualHighlight.Parent = obj
    local labelDisplay = Instance.new("BillboardGui")
    labelDisplay.Name = identifier .. "_Label"; labelDisplay.Adornee = anchorPoint
    labelDisplay.Size = UDim2.new(0, DISPLAY_CONFIG.LABEL_WIDTH, 0, DISPLAY_CONFIG.LABEL_HEIGHT)
    labelDisplay.StudsOffset = Vector3.new(0, isCharacter and 4.0 or 4.3, 0); labelDisplay.AlwaysOnTop = true
    labelDisplay.MaxDistance = isCharacter and DISPLAY_CONFIG.MAX_CHARACTER_DISTANCE or DISPLAY_CONFIG.MAX_OBJECT_DISTANCE
    labelDisplay.Parent = obj
    local container = Instance.new("Frame"); container.Name = "Container"; container.Size = UDim2.new(1,0,1,0); container.BackgroundTransparency = 1; container.Parent = labelDisplay
    local nameLabel = Instance.new("TextLabel"); nameLabel.Name = "NameLabel"; nameLabel.Size = UDim2.new(1,0,0.4,0); nameLabel.Position = UDim2.new(0,0,0,0); nameLabel.BackgroundTransparency = 1; nameLabel.TextColor3 = overlayColor; nameLabel.TextStrokeTransparency = 0.4; nameLabel.TextStrokeColor3 = Color3.new(0,0,0); nameLabel.TextSize = DISPLAY_CONFIG.TEXT_SCALE; nameLabel.Font = Enum.Font.GothamBold; nameLabel.Text = obj.Name; nameLabel.Parent = container
    local barBg = Instance.new("Frame"); barBg.Name = "HPBarBg"; barBg.Size = UDim2.new(0.85,0,0.08,0); barBg.Position = UDim2.new(0.075,0,0.45,0); barBg.BackgroundColor3 = Color3.fromRGB(30,30,30); barBg.BorderSizePixel = 0; barBg.Visible = isCharacter; barBg.Parent = container
    local barFill = Instance.new("Frame"); barFill.Name = "HPBarFill"; barFill.Size = UDim2.new(1,0,1,0); barFill.BackgroundColor3 = Color3.fromRGB(0,255,0); barFill.BorderSizePixel = 0; barFill.Parent = barBg
    local bottomRow = Instance.new("Frame"); bottomRow.Name = "BottomRow"; bottomRow.Size = UDim2.new(1,0,0.4,0); bottomRow.Position = UDim2.new(0,0,0.6,0); bottomRow.BackgroundTransparency = 1; bottomRow.Parent = container
    local hpLabel = Instance.new("TextLabel"); hpLabel.Name = "HPLabel"; hpLabel.Size = UDim2.new(0.5,-5,1,0); hpLabel.Position = UDim2.new(0,8,0,0); hpLabel.BackgroundTransparency = 1; hpLabel.TextColor3 = Color3.fromRGB(245,245,245); hpLabel.TextStrokeTransparency = 0.5; hpLabel.TextStrokeColor3 = Color3.new(0,0,0); hpLabel.TextSize = 11; hpLabel.Font = Enum.Font.GothamBold; hpLabel.TextXAlignment = Enum.TextXAlignment.Left; hpLabel.Parent = bottomRow
    local studsLabel = Instance.new("TextLabel"); studsLabel.Name = "StudsLabel"; studsLabel.Size = UDim2.new(0.5,-5,1,0); studsLabel.Position = UDim2.new(0.5,-3,0,0); studsLabel.BackgroundTransparency = 1; studsLabel.TextColor3 = Color3.fromRGB(220,220,220); studsLabel.TextStrokeTransparency = 0.5; studsLabel.TextStrokeColor3 = Color3.new(0,0,0); studsLabel.TextSize = 11; studsLabel.Font = Enum.Font.GothamBold; studsLabel.TextXAlignment = Enum.TextXAlignment.Right; studsLabel.Text = "0s"; studsLabel.Parent = bottomRow
    local function refreshDisplay()
        if not obj or not obj.Parent then return end
        if isCharacter then
            local hc = obj:FindFirstChildOfClass("Humanoid")
            if hc then
                local hp = math.floor(hc.Health); local mhp = math.floor(hc.MaxHealth)
                local ratio = mhp > 0 and (hc.Health / mhp) or 0
                hpLabel.Text = hp .. " HP"
                barFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
                local clr; if ratio > 0.5 then local t=(ratio-0.5)/0.5; clr=Color3.new(1-t,1,0) else local t=ratio/0.5; clr=Color3.new(1,t,0) end
                barFill.BackgroundColor3 = clr
                if not displaySystem.healthListeners[obj] then displaySystem.healthListeners[obj] = hc.HealthChanged:Connect(refreshDisplay) end
            end
        else
            local ct = obj:FindFirstChild("Progress")
            if ct and ct:IsA("NumberValue") then
                hpLabel.Text = math.floor(ct.Value) .. "%"
                if not displaySystem.progressListeners[obj] then displaySystem.progressListeners[obj] = ct.Changed:Connect(refreshDisplay) end
            else hpLabel.Text = "" end
        end
    end
    refreshDisplay()
    if displaySystem.lifecycleTrackers[obj] then displaySystem.lifecycleTrackers[obj]:Disconnect() end
    displaySystem.lifecycleTrackers[obj] = obj.AncestryChanged:Connect(function() if not obj.Parent then removeOverlay(obj, identifier) end end)
    local storedIdentifier = identifier; local storedColor = overlayColor
    if displaySystem.highlightMonitors[obj] then pcall(function() displaySystem.highlightMonitors[obj]:Disconnect() end); displaySystem.highlightMonitors[obj] = nil end
    local lastCheck = tick()
    displaySystem.highlightMonitors[obj] = svc.Run.Heartbeat:Connect(function()
        if not obj or not obj.Parent then pcall(function() if displaySystem.highlightMonitors[obj] then displaySystem.highlightMonitors[obj]:Disconnect(); displaySystem.highlightMonitors[obj] = nil end end); return end
        local now = tick(); if now - lastCheck < 0.033 then return end; lastCheck = now
        local ourHL = pcall(function() return obj:FindFirstChild(storedIdentifier .. "_Visual") end) and obj:FindFirstChild(storedIdentifier .. "_Visual") or nil
        if not ourHL then
            pcall(function() local nh=Instance.new("Highlight"); nh.Name=storedIdentifier.."_Visual"; nh.FillColor=storedColor; nh.FillTransparency=DISPLAY_CONFIG.HIGHLIGHT_OPACITY; nh.OutlineColor=storedColor; nh.OutlineTransparency=DISPLAY_CONFIG.OUTLINE_VISIBILITY; nh.DepthMode=DISPLAY_CONFIG.DISPLAY_MODE; nh.Adornee=obj; nh.Parent=obj end)
        else
            pcall(function() for _, child in ipairs(obj:GetChildren()) do if child:IsA("Highlight") and child.Name ~= storedIdentifier.."_Visual" then child:Destroy() end end end)
        end
    end)
    displaySystem.activeDisplays[obj] = { identifier = identifier, isCharacter = isCharacter, anchorPoint = anchorPoint }
end

local function updateThreatDisplay(enable)
    local f = getTeamFolder("Killers"); if not f then return end
    for _, e in ipairs(f:GetChildren()) do if e:IsA("Model") then if enable then attachOverlay(e,"disp_threat",DISPLAY_CONFIG.ENTITY_COLORS.THREAT,true) else removeOverlay(e,"disp_threat") end end end
end
local function updateTeammateDisplay(enable)
    local f = getTeamFolder("Survivors"); if not f then return end
    for _, e in ipairs(f:GetChildren()) do if e:IsA("Model") and e ~= lp.Character then if enable then attachOverlay(e,"disp_teammate",DISPLAY_CONFIG.ENTITY_COLORS.TEAMMATE,true) else removeOverlay(e,"disp_teammate") end end end
end
local function updateObjectiveDisplay(enable)
    local m = getMapContent(); if not m then return end
    for _, e in ipairs(m:GetChildren()) do if e.Name=="Generator" then if enable then attachOverlay(e,"disp_objective",DISPLAY_CONFIG.ENTITY_COLORS.OBJECTIVE,false) else removeOverlay(e,"disp_objective") end end end
end
local function updateLootDisplay(enable)
    for _, e in ipairs(svc.WS:GetDescendants()) do if e.Name=="BloxyCola" or e.Name=="Medkit" then if enable then attachOverlay(e,"disp_loot",DISPLAY_CONFIG.ENTITY_COLORS.LOOT,false) else removeOverlay(e,"disp_loot") end end end
end
local function updateStructureDisplay(enable)
    local ig = getIngame(); if not ig then return end
    for _, e in ipairs(ig:GetChildren()) do if e.Name=="BuildermanSentry" or e.Name=="SubspaceTripmine" or e.Name=="BuildermanDispenser" then if enable then attachOverlay(e,"disp_structure",DISPLAY_CONFIG.ENTITY_COLORS.STRUCTURE,false) else removeOverlay(e,"disp_structure") end end end
end

local function initializeTracking()
    for _, l in ipairs(displaySystem.eventListeners) do if l.Connected then l:Disconnect() end end
    displaySystem.eventListeners = {}
    local tf = getTeamFolder("Killers"); local sf2 = getTeamFolder("Survivors")
    if tf then
        table.insert(displaySystem.eventListeners, tf.ChildAdded:Connect(function(c) task.wait(0.2); if displaySystem.showKillers and c:IsA("Model") then attachOverlay(c,"disp_threat",DISPLAY_CONFIG.ENTITY_COLORS.THREAT,true) end end))
        table.insert(displaySystem.eventListeners, tf.ChildRemoved:Connect(function(c) removeOverlay(c,"disp_threat") end))
    end
    if sf2 then
        table.insert(displaySystem.eventListeners, sf2.ChildAdded:Connect(function(c) task.wait(0.2); if displaySystem.showSurvivors and c:IsA("Model") then attachOverlay(c,"disp_teammate",DISPLAY_CONFIG.ENTITY_COLORS.TEAMMATE,true) end end))
        table.insert(displaySystem.eventListeners, sf2.ChildRemoved:Connect(function(c) removeOverlay(c,"disp_teammate") end))
    end
    table.insert(displaySystem.eventListeners, svc.WS.DescendantAdded:Connect(function(obj)
        task.wait(DISPLAY_CONFIG.SPAWN_CHECK_DELAY); if not obj or not obj.Parent then return end
        if displaySystem.showGenerators and obj.Name=="Generator" then attachOverlay(obj,"disp_objective",DISPLAY_CONFIG.ENTITY_COLORS.OBJECTIVE,false) end
        if displaySystem.showItems and (obj.Name=="BloxyCola" or obj.Name=="Medkit") then attachOverlay(obj,"disp_loot",DISPLAY_CONFIG.ENTITY_COLORS.LOOT,false) end
        if displaySystem.showBuildings and (obj.Name=="BuildermanSentry" or obj.Name=="SubspaceTripmine" or obj.Name=="BuildermanDispenser") then attachOverlay(obj,"disp_structure",DISPLAY_CONFIG.ENTITY_COLORS.STRUCTURE,false) end
    end))
end

task.spawn(function()
    while true do
        task.wait(0.1)
        local char = lp.Character; local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if myRoot then
            local myPos = myRoot.Position
            for obj, info in pairs(displaySystem.activeDisplays) do
                if typeof(obj) == "Instance" and obj.Parent and info.anchorPoint and info.anchorPoint.Parent then
                    local label = obj:FindFirstChild(info.identifier .. "_Label")
                    if label then local c=label:FindFirstChild("Container"); local br=c and c:FindFirstChild("BottomRow"); local sl=br and br:FindFirstChild("StudsLabel"); if sl then sl.Text=math.floor((info.anchorPoint.Position-myPos).Magnitude).."s" end end
                else displaySystem.activeDisplays[obj] = nil end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        local dead = {}
        for obj, monitor in pairs(displaySystem.highlightMonitors) do if not obj or not obj.Parent or not monitor or not monitor.Connected then table.insert(dead, obj) end end
        for _, obj in ipairs(dead) do pcall(function() if displaySystem.highlightMonitors[obj] and displaySystem.highlightMonitors[obj].Connected then displaySystem.highlightMonitors[obj]:Disconnect() end end); displaySystem.highlightMonitors[obj] = nil end
        local deadD = {}
        for obj, info in pairs(displaySystem.activeDisplays) do
            if not obj or not obj.Parent then table.insert(deadD, {obj, info.identifier})
            else local lbl = pcall(function() return obj:FindFirstChild(info.identifier.."_Label") end) and obj:FindFirstChild(info.identifier.."_Label") or nil; if not lbl then table.insert(deadD, {obj, info.identifier}) end end
        end
        for _, item in ipairs(deadD) do
            local obj, identifier = item[1], item[2]; removeOverlay(obj, identifier)
            task.spawn(function()
                task.wait(0.1)
                if obj and obj.Parent then
                    local colorKey = identifier:match("disp_(%a+)")
                    local colorMap = { threat=DISPLAY_CONFIG.ENTITY_COLORS.THREAT, teammate=DISPLAY_CONFIG.ENTITY_COLORS.TEAMMATE, objective=DISPLAY_CONFIG.ENTITY_COLORS.OBJECTIVE, loot=DISPLAY_CONFIG.ENTITY_COLORS.LOOT, structure=DISPLAY_CONFIG.ENTITY_COLORS.STRUCTURE }
                    attachOverlay(obj, identifier, colorMap[colorKey] or Color3.new(1,1,1), (identifier=="disp_threat" or identifier=="disp_teammate"))
                end
            end)
        end
    end
end)

secDisplay:Toggle({ 
    Title="Threats",
    Flag="displayKillers",
    Type="Checkbox",
    Default=false,
    Callback=function(on) displaySystem.showKillers=on; task.spawn(function() updateThreatDisplay(on) end) end 
})
secDisplay:Toggle({ 
    Title="Teammates",
    Flag="displaySurvivors",
    Type="Checkbox",
    Default=false,
    Callback=function(on) displaySystem.showSurvivors=on; task.spawn(function() updateTeammateDisplay(on) end) end 
})
secDisplay:Toggle({ 
    Title="Objectives",
    Flag="displayGenerators",
    Type="Checkbox",
    Default=false,
    Callback=function(on) displaySystem.showGenerators=on; task.spawn(function() updateObjectiveDisplay(on) end) end 
})
secDisplay:Toggle({ 
    Title="Resources",
    Flag="displayItems",
    Type="Checkbox",
    Default=false,
    Callback=function(on) displaySystem.showItems=on; task.spawn(function() updateLootDisplay(on) end) end 
})
secDisplay:Toggle({ 
    Title="Structures",
    Flag="displayBuildings",
    Type="Checkbox",
    Default=false,
    Callback=function(on) displaySystem.showBuildings=on; task.spawn(function() updateStructureDisplay(on) end) end 
})

------------------------------------------------------------------------
-- Minion + Puddle ESP (with Flags)
------------------------------------------------------------------------
local secMinion = tabVisual:Section({ Title = "Minion & Ability ESP", Opened = true })
local mset = { pizza=false, zombie=false, puddle=false, transparency=0.25 }
local tracked = { pizza={}, zombie={}, puddle={} }

local function isRealPlayer(obj)
    for _, plr in ipairs(svc.Players:GetPlayers()) do
        if plr.Character == obj then return true end
        if plr.Character and obj:IsDescendantOf(plr.Character) then return true end
    end
    return false
end
local function addHighlight(obj, color, tag, label, offset)
    if not obj or tracked[tag][obj] then return end; if isRealPlayer(obj) then return end
    tracked[tag][obj] = true
    local root = obj
    if obj:IsA("Model") then root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart; if not root then for _, child in ipairs(obj:GetChildren()) do if child:IsA("BasePart") then root=child; break end end end end
    local hl = Instance.new("Highlight"); hl.Name=tag.."_HL"; hl.FillColor=color; hl.FillTransparency=mset.transparency; hl.OutlineColor=color; hl.OutlineTransparency=0.1; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee=obj; hl.Parent=obj
    if root then
        local bb = Instance.new("BillboardGui"); bb.Name=tag.."_BB"; bb.Adornee=root; bb.Size=UDim2.new(0,130,0,24); bb.StudsOffset=Vector3.new(0,offset or 3,0); bb.AlwaysOnTop=true; bb.Parent=obj
        local lbl2 = Instance.new("TextLabel"); lbl2.Size=UDim2.new(1,0,1,0); lbl2.BackgroundTransparency=1; lbl2.Text=label; lbl2.TextColor3=color; lbl2.TextStrokeColor3=Color3.new(0,0,0); lbl2.TextStrokeTransparency=0.2; lbl2.TextSize=12; lbl2.Font=Enum.Font.GothamBold; lbl2.Parent=bb
    end
    local conn; conn = obj.AncestryChanged:Connect(function() if obj.Parent then return end; conn:Disconnect(); hl:Destroy(); local bb2=obj:FindFirstChild(tag.."_BB"); if bb2 then bb2:Destroy() end; tracked[tag][obj]=nil end)
end
local function updateTransparency()
    for tag, tbl in pairs(tracked) do for obj in pairs(tbl) do local hl=obj:FindFirstChild(tag.."_HL"); if hl then hl.FillTransparency=mset.transparency end end end
end
local function clearTag(tag)
    for obj in pairs(tracked[tag]) do local hl=obj:FindFirstChild(tag.."_HL"); if hl then hl:Destroy() end; local bb=obj:FindFirstChild(tag.."_BB"); if bb then bb:Destroy() end; if tag=="puddle" then local h=obj:FindFirstChild("PuddleHolder"); if h then h:Destroy() end end end
    tracked[tag]={}
end
local function addPuddleHighlight(part, color, tag, label)
    if not part or tracked[tag][part] then return end; if isRealPlayer(part) then return end
    tracked[tag][part] = true
    local hl = Instance.new("Highlight"); hl.Name=tag.."_HL"; hl.FillColor=color; hl.FillTransparency=mset.transparency; hl.OutlineColor=color; hl.OutlineTransparency=0.1; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee=part; hl.Parent=part
    task.wait(0.05)
    local puddleSize=math.max(part.Size.X,part.Size.Z); local radius=math.max(puddleSize*0.5,3)
    local holder=Instance.new("Part"); holder.Name="PuddleHolder"; holder.Size=Vector3.new(1,0.1,1); holder.Transparency=1; holder.CanCollide=false; holder.Anchored=true; holder.Position=part.Position+Vector3.new(0,0.05,0); holder.Parent=part
    local bc=Instance.new("CylinderHandleAdornment"); bc.Name="PuddleBlack"; bc.Adornee=holder; bc.Color3=Color3.fromRGB(0,0,0); bc.Transparency=0.2; bc.Radius=radius; bc.Height=0.02; bc.CFrame=CFrame.Angles(math.rad(90),0,0); bc.ZIndex=5; bc.AlwaysOnTop=true; bc.Parent=holder
    local ro=Instance.new("CylinderHandleAdornment"); ro.Name="PuddleRed"; ro.Adornee=holder; ro.Color3=Color3.fromRGB(255,0,0); ro.Transparency=0.4; ro.Radius=radius+0.8; ro.Height=0.02; ro.CFrame=CFrame.Angles(math.rad(90),0,0); ro.ZIndex=4; ro.AlwaysOnTop=true; ro.Parent=holder
    local bb=Instance.new("BillboardGui"); bb.Name=tag.."_BB"; bb.Adornee=holder; bb.Size=UDim2.new(0,140,0,20); bb.StudsOffset=Vector3.new(0,1.5,0); bb.AlwaysOnTop=true; bb.Parent=holder
    local lbl2=Instance.new("TextLabel"); lbl2.Size=UDim2.new(1,0,1,0); lbl2.BackgroundTransparency=1; lbl2.Text=label; lbl2.TextColor3=Color3.fromRGB(255,255,255); lbl2.TextStrokeColor3=Color3.fromRGB(255,0,0); lbl2.TextStrokeTransparency=0.1; lbl2.TextSize=11; lbl2.Font=Enum.Font.GothamBold; lbl2.Parent=bb
    local connections = {}
    local sizeConn; sizeConn = part:GetPropertyChangedSignal("Size"):Connect(function()
        if not part or not part.Parent then if sizeConn and sizeConn.Connected then sizeConn:Disconnect() end; return end
        local nr=math.max(math.max(part.Size.X,part.Size.Z)*0.5,3); pcall(function() bc.Radius=nr end); pcall(function() ro.Radius=nr+0.8 end)
    end); table.insert(connections, sizeConn)
    local ac2; ac2 = part.AncestryChanged:Connect(function()
        if part and part.Parent then return end
        for _, conn in ipairs(connections) do pcall(function() if conn and conn.Connected then conn:Disconnect() end end) end
        pcall(function() if hl and hl.Parent then hl:Destroy() end end)
        pcall(function() if holder and holder.Parent then holder:Destroy() end end)
        tracked[tag][part]=nil
    end); table.insert(connections, ac2)
end
local function isJohnDoePuddle(obj)
    if not obj:IsA("BasePart") then return false end; if obj.Name ~= "Shadow" then return false end
    local parent = obj.Parent; return parent and parent.Name:find("Shadows$") ~= nil
end
local function scanPizza()  if not mset.pizza  then return end; for _,obj in ipairs(svc.WS:GetDescendants()) do if obj.Name=="PizzaDeliveryRig" and obj:IsA("Model") and not isRealPlayer(obj) and not tracked.pizza[obj]  then addHighlight(obj,Color3.fromRGB(255,100,0),"pizza","C00LKIDD PIZZA DELIVERY",3) end end end
local function scanZombie() if not mset.zombie then return end; for _,obj in ipairs(svc.WS:GetDescendants()) do if obj.Name=="1x1x1x1Zombie"    and obj:IsA("Model") and not isRealPlayer(obj) and not tracked.zombie[obj] then addHighlight(obj,Color3.fromRGB(80,255,120),"zombie","1X1X1X1 ZOMBIE",3) end end end
local function scanPuddles()if not mset.puddle then return end; for _,obj in ipairs(svc.WS:GetDescendants()) do if isJohnDoePuddle(obj) and not tracked.puddle[obj] then addPuddleHighlight(obj,Color3.fromRGB(255,50,50),"puddle","JOHN DOE PUDDLE") end end end
local function setupMinionWatcher()
    svc.WS.DescendantAdded:Connect(function(obj)
        task.wait(0.1); if not obj or not obj.Parent then return end
        if mset.pizza  and obj.Name=="PizzaDeliveryRig"  and obj:IsA("Model") and not isRealPlayer(obj) and not tracked.pizza[obj]  then addHighlight(obj,Color3.fromRGB(255,100,0),"pizza","C00LKIDD PIZZA DELIVERY",3) end
        if mset.zombie and obj.Name=="1x1x1x1Zombie"     and obj:IsA("Model") and not isRealPlayer(obj) and not tracked.zombie[obj] then addHighlight(obj,Color3.fromRGB(80,255,120),"zombie","1X1X1X1 ZOMBIE",3) end
        if mset.puddle and isJohnDoePuddle(obj) and not tracked.puddle[obj] then task.wait(0.15); if obj.Parent then addPuddleHighlight(obj,Color3.fromRGB(255,50,50),"puddle","JOHN DOE PUDDLE") end end
    end)
end
task.spawn(function() while true do task.wait(3); scanPizza(); scanZombie(); scanPuddles() end end)

task.spawn(function()
    task.wait(DISPLAY_CONFIG.STARTUP_DELAY); initializeTracking()
    local pf = svc.WS:FindFirstChild("Players")
    if pf then displaySystem.killerFolder=pf:FindFirstChild("Killers"); displaySystem.survivorFolder=pf:FindFirstChild("Survivors") end
    if displaySystem.showKillers    then updateThreatDisplay(true)    end
    if displaySystem.showSurvivors  then updateTeammateDisplay(true)  end
    if displaySystem.showGenerators then updateObjectiveDisplay(true) end
    if displaySystem.showItems      then updateLootDisplay(true)      end
    if displaySystem.showBuildings  then updateStructureDisplay(true) end
    setupMinionWatcher()
    if mset.pizza  then scanPizza()   end
    if mset.zombie then scanZombie()  end
    if mset.puddle then scanPuddles() end
    displaySystem.initialized = true
end)
lp.CharacterAdded:Connect(function()
    task.wait(2); if not displaySystem.initialized then return end
    initializeTracking()
    if displaySystem.showKillers    then updateThreatDisplay(true)    end
    if displaySystem.showSurvivors  then updateTeammateDisplay(true)  end
    if displaySystem.showGenerators then updateObjectiveDisplay(true) end
    if displaySystem.showItems      then updateLootDisplay(true)      end
    if displaySystem.showBuildings  then updateStructureDisplay(true) end
    if mset.pizza  then scanPizza()   end
    if mset.zombie then scanZombie()  end
    if mset.puddle then scanPuddles() end
end)

secMinion:Toggle({ 
    Title="c00lkidd Pizza Bots",
    Flag="espPizza",
    Type="Checkbox",
    Default=false,
    Callback=function(on) mset.pizza=on; if on then scanPizza() else clearTag("pizza") end end 
})
secMinion:Toggle({ 
    Title="1x1x1x1 Zombies",
    Flag="espZombie",
    Type="Checkbox",
    Default=false,
    Callback=function(on) mset.zombie=on; if on then scanZombie() else clearTag("zombie") end end 
})
secMinion:Toggle({ 
    Title="JD Digital Footprints",
    Flag="espPuddle",
    Type="Checkbox",
    Default=false,
    Callback=function(on) mset.puddle=on; if on then scanPuddles() else clearTag("puddle") end end 
})
secMinion:Slider({ 
    Title="Highlight Transparency",
    Flag="espMinionTrans",
    Step=0.05,
    Value={Min=0,Max=1,Default=0.25},
    Callback=function(v) mset.transparency=v; updateTransparency() end 
})
secMinion:Button({ Title="🔄 Force Rescan", Callback=function() clearTag("pizza"); clearTag("zombie"); clearTag("puddle"); task.wait(0.1); scanPizza(); scanZombie(); scanPuddles() end })

------------------------------------------------------------------------
-- BLOODSTAINS (with Flags)
------------------------------------------------------------------------
local secBloodstain = tabVisual:Section({ Title = "Damage Feedback", Opened = true })
local bloodstain = {
    on         = false,
    intensity  = 0.6,
    distance   = 100,
    monitored  = {},
    healthConns = {},
    screenGui  = nil,
}

local function bloodGui()
    if bloodstain.screenGui and bloodstain.screenGui.Parent then return bloodstain.screenGui end
    local pg = lp:FindFirstChild("PlayerGui"); if not pg then return nil end
    bloodstain.screenGui = Instance.new("ScreenGui")
    bloodstain.screenGui.Name = "BloodstainGui"
    bloodstain.screenGui.ResetOnSpawn = false
    bloodstain.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bloodstain.screenGui.Parent = pg
    return bloodstain.screenGui
end

local function spawnBloodstain()
    local g = bloodGui(); if not g then return end
    local splat = Instance.new("TextLabel")
    splat.Name = "Bloodstain"
    splat.Size = UDim2.new(0, 80, 0, 80)
    splat.Position = UDim2.new(math.random(0, 10) / 10, -40, math.random(0, 10) / 10, -40)
    splat.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
    splat.BackgroundTransparency = 1 - bloodstain.intensity
    splat.BorderSizePixel = 0
    splat.TextTransparency = 1
    splat.Parent = g
    local startTime = tick()
    local duration = 0.8
    local fadeStart = 0.5
    local conn; conn = svc.Run.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed > duration then
            pcall(function() splat:Destroy() end)
            if conn and conn.Connected then conn:Disconnect() end
            return
        end
        local progress = elapsed / duration
        if progress < fadeStart then
            splat.BackgroundTransparency = 1 - bloodstain.intensity
        else
            local fadeProgress = (progress - fadeStart) / (1 - fadeStart)
            splat.BackgroundTransparency = 1 - (bloodstain.intensity * (1 - fadeProgress))
        end
    end)
end

local function bloodStartMonitoring()
    if not bloodstain.on then return end
    local myChar = lp.Character; if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    local function checkAndMonitor(model)
        if not model or bloodstain.monitored[model] then return end
        if model == lp.Character then return end
        local h = model:FindFirstChildOfClass("Humanoid"); if not h then return end
        local root = model:FindFirstChild("HumanoidRootPart"); if not root then return end
        if (root.Position - myRoot.Position).Magnitude > bloodstain.distance then return end
        bloodstain.monitored[model] = true
        local lastHealth = h.Health
        local healthConn; healthConn = h.HealthChanged:Connect(function(newHealth)
            if not bloodstain.on or not myChar or not myChar.Parent then
                if healthConn and healthConn.Connected then healthConn:Disconnect() end
                bloodstain.monitored[model] = nil; return
            end
            if newHealth < lastHealth then spawnBloodstain() end
            lastHealth = newHealth
        end)
        bloodstain.healthConns[model] = healthConn
    end
    for _, folder in ipairs({ getTeamFolder("Killers"), getTeamFolder("Survivors") }) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") then checkAndMonitor(model) end
            end
        end
    end
end

local function bloodStopMonitoring()
    for model, conn in pairs(bloodstain.healthConns) do
        if conn and conn.Connected then conn:Disconnect() end
        bloodstain.monitored[model] = nil
    end
    bloodstain.healthConns = {}
end

local function bloodSetupWatchers()
    local function watchFolder(folder)
        if not folder then return end
        folder.ChildAdded:Connect(function(child)
            if not bloodstain.on or not child:IsA("Model") then return end
            task.wait(0.1)
            local h = child:FindFirstChildOfClass("Humanoid"); if not h then return end
            bloodstain.monitored[child] = true
            local lastHealth = h.Health
            local healthConn; healthConn = h.HealthChanged:Connect(function(newHealth)
                if not bloodstain.on or not lp.Character or not lp.Character.Parent then
                    if healthConn and healthConn.Connected then healthConn:Disconnect() end
                    bloodstain.monitored[child] = nil; return
                end
                if newHealth < lastHealth then spawnBloodstain() end
                lastHealth = newHealth
            end)
            bloodstain.healthConns[child] = healthConn
        end)
        folder.ChildRemoved:Connect(function(child)
            if bloodstain.healthConns[child] then
                bloodstain.healthConns[child]:Disconnect()
                bloodstain.healthConns[child] = nil
            end
            bloodstain.monitored[child] = nil
        end)
    end
    watchFolder(getTeamFolder("Killers"))
    watchFolder(getTeamFolder("Survivors"))
end
task.spawn(bloodSetupWatchers)

secBloodstain:Toggle({
    Title = "Bloodstains on Damage",
    Flag = "bloodOn",
    Type = "Checkbox",
    Default = false,
    Callback = function(on)
        bloodstain.on = on
        if on then
            bloodStartMonitoring()
        else
            bloodStopMonitoring()
            local g = bloodGui()
            if g then for _, splat in ipairs(g:GetChildren()) do pcall(function() splat:Destroy() end) end end
        end
    end
})
secBloodstain:Slider({ 
    Title = "Opacity",
    Flag = "bloodIntensity",
    Step = 0.05,
    Value = { Min = 0.2, Max = 1.0, Default = 0.6 },
    Callback = function(v) bloodstain.intensity = v end 
})
secBloodstain:Slider({ 
    Title = "Detection Range",
    Flag = "bloodDistance",
    Step = 5,
    Value = { Min = 20,  Max = 500, Default = 100 },
    Callback = function(v) bloodstain.distance = v end 
})

lp.CharacterAdded:Connect(function()
    bloodStopMonitoring()
    task.delay(1, function() if bloodstain.on then bloodStartMonitoring() end end)
end)

------------------------------------------------------------------------
-- TAB: MUSIC (with Flags)
------------------------------------------------------------------------
local tabMusic = win:Tab({ Title = "Music", Icon = "music" })
local secLMS   = tabMusic:Section({ Title = "LMS Music", Opened = true })

local music = {
    on            = false,
    selected      = "CondemnedLMS",
    cached        = {},
    origId        = nil,
    thread        = nil,
    lastSoundCheck= 0,
    cachedSound   = nil,
    loadingTracks = {},
    lmsState      = false,
    lmsConn       = nil,
    lmsHealthConns= {},
    manualPlay    = false,
}

local musicDir = "Viperware/LMS_Songs"
if not fs.hasFolder("Viperware") then fs.makeFolder("Viperware") end
if not fs.hasFolder(musicDir) then fs.makeFolder(musicDir) end

local ghBase = "https://raw.githubusercontent.com/r3take/lmsstuff/main/"
local musicTracks = {
    ["AbberantLMS"]             = ghBase.."AbberantLMS.mp3",
    ["OvertimeLMS"]             = ghBase.."OvertimeLMS.mp3",
    ["PhotoshopLMS"]            = ghBase.."PhotoshopLMS.mp3",
    ["JX1DX1LMS"]               = ghBase.."JX1DX1LMS.mp3",
    ["CondemnedLMS"]            = ghBase.."CondemnedLMS.mp3",
    ["GeometryLMS"]             = ghBase.."GeometryLMS.mp3",
    ["SixerVsNoobLMS"]          = ghBase.."SixerVsNoobLMS.mp3",
    ["Milestone4LMS"]           = ghBase.."MS4LMS.mp3",
    ["BluududLMS"]              = ghBase.."BluududLMS.mp3",
    ["JohnDoeLMS"]              = ghBase.."JohnDoeLMS.mp3",
    ["EternalIShallEndure"]     = ghBase.."EternallShallEndure.mp3",
    ["ChanceVSMafiosoLMS"]      = ghBase.."ChanceVSMafioso.mp3",
    ["MafiosoVsChanceLMS"]      = ghBase.."ChanceVSMafioso.mp3",
    ["JohnVsJaneLMS"]           = ghBase.."JohnVSJaneLMS.mp3",
    ["SynonymsForEternity"]     = ghBase.."synonymsforeternity.mp3",
    ["EternityEpicfied"]        = ghBase.."EternityEpicfied.mp3",
    ["EternalHopeEternalFight"] = ghBase.."EternalHopeEternalFight.mp3",
    ["SlasherVSGuest"]          = ghBase.."slashervguestlms.mp3",
    ["Debth"]                   = ghBase.."Debth.mp3",
    ["ShatteredHopes"]          = ghBase.."ShatteredHopesLMS.mp3",
    ["EmberRageLMS"]            = ghBase.."emberragelms.mp3",
    ["SprunkinLMS"]             = ghBase.."SPRUNKINLMS.mp3",
    ["AzureVSTwoTimeLMS"]       = ghBase.."azurevstwotimelms.mp3",
    ["AshleLMS"]                = ghBase.."Ashlelms.mp3",
    ["MeetYourMaking"]          = ghBase.."MeetYourMaking.mp3",
    ["ReceadingLifespan"]       = ghBase.."ReceadingLifespan.mp3",
    ["PhoenixLMS"]              = ghBase.."phoenixlms.mp3",
    ["JerseyDebth"]             = ghBase.."JerseyDebth.mp3",
}
local musicList = {}; for k in pairs(musicTracks) do table.insert(musicList, k) end; table.sort(musicList)

local MUSIC_DIR = "Viperware/Music"
local function musicTrackPath(name) return MUSIC_DIR .. "/" .. name .. ".mp3" end
local function musicSidecarPath(name) return MUSIC_DIR .. "/" .. name .. ".meta" end

local function musicHttpGet(url)
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if ok and data and #data > 0 then return data end
    return nil
end

local function musicWriteSidecar(name)
    pcall(function() fs.write(musicSidecarPath(name), tostring(os.time())) end)
end

local function musicCacheValid(name)
    return fs.hasFile(musicTrackPath(name))
end

local function musicFetch(name)
    if music.cached[name] then return music.cached[name] end
    local url = musicTracks[name]; if not url then return nil end
    if not fs.hasFolder(MUSIC_DIR) then fs.makeFolder(MUSIC_DIR) end
    local path = musicTrackPath(name)
    if not fs.hasFile(path) then
        local data = musicHttpGet(url)
        if not data then return nil end
        local ok = pcall(function() fs.write(path, data) end)
        if not ok then return nil end
        musicWriteSidecar(name)
    end
    local ok, asset = pcall(function() return fs.asset(path) end)
    if ok and asset then music.cached[name] = asset; return asset end
    return nil
end

local musicFetchInFlight = {}
local function musicFetchAsync(name, callback)
    if music.cached[name] then if callback then callback(music.cached[name]) end; return end
    if musicFetchInFlight[name] then return end
    musicFetchInFlight[name] = true
    task.spawn(function()
        local asset = musicFetch(name)
        musicFetchInFlight[name] = nil
        if asset and callback then callback(asset) end
    end)
end

local function musicGetSound()
    local now = tick()
    if music.cachedSound and music.cachedSound.Parent and (now - music.lastSoundCheck) < 0.5 then
        return music.cachedSound
    end
    music.lastSoundCheck = now
    local themes = workspace:FindFirstChild("Themes")
    if themes then
        local snd = themes:FindFirstChild("LastSurvivor")
        if snd and snd:IsA("Sound") then music.cachedSound = snd; return snd end
    end
    local snd = workspace:FindFirstChild("LastSurvivor", true)
        or game:GetService("SoundService"):FindFirstChild("LastSurvivor", true)
    if snd and snd:IsA("Sound") then music.cachedSound = snd; return snd end
    music.cachedSound = nil
    return nil
end

local function musicPlay(name)
    local snd = musicGetSound(); if not snd then return false end
    if not music.origId then music.origId = snd.SoundId end
    local asset = musicFetch(name); if not asset then return false end
    if snd.SoundId ~= asset then
        snd.SoundId = asset; snd:Stop(); task.wait(0.05); snd:Play()
    elseif not snd.IsPlaying then
        snd:Play()
    end
    return true
end

local function musicReset()
    local snd = musicGetSound()
    if snd and music.origId then
        snd.SoundId = music.origId; snd:Stop(); task.wait(0.05); snd:Play()
    end
    music.manualPlay = false
end

local function musicCountAlive(sf)
    local alive = 0
    for _, model in ipairs(sf:GetChildren()) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 and hum.Health == hum.Health then alive += 1 end
    end
    return alive
end

local function musicUpdateLMSState()
    local sf = getTeamFolder("Survivors")
    if not sf then music.lmsState = false; return end
    music.lmsState = musicCountAlive(sf) == 2
end

local function musicMonitor()
    while music.on do
        local snd = musicGetSound()
        if snd then
            local asset = music.cached[music.selected]
            if asset then
                if snd.SoundId ~= asset then
                    if not music.origId then music.origId = snd.SoundId end
                    snd.SoundId = asset
                    snd:Stop()
                    task.wait(0.05)
                    snd:Play()
                elseif not snd.IsPlaying then
                    snd:Play()
                end
            else
                musicFetchAsync(music.selected, function(loadedAsset)
                    local s = musicGetSound()
                    if s then
                        if not music.origId then music.origId = s.SoundId end
                        s.SoundId = loadedAsset
                        s:Stop(); task.wait(0.05); s:Play()
                    end
                end)
            end
        end
        task.wait(1)
    end
end

secLMS:Toggle({ 
    Title="Auto-Play on LMS",
    Flag="musicOn",
    Type="Checkbox",
    Default=false,
    Callback=function(on)
        music.on = on
        if on then
            musicFetchAsync(music.selected)
            music.thread = task.spawn(musicMonitor)
        else
            if music.thread then task.cancel(music.thread); music.thread = nil end
            music.manualPlay = false
            musicReset()
        end
    end 
})
secLMS:Dropdown({ 
    Title="Track",
    Flag="musicSel",
    Values=musicList,
    Value="CondemnedLMS",
    Callback=function(sel)
        music.selected = type(sel)=="table" and sel[1] or sel
        task.spawn(function() musicFetchAsync(music.selected) end)
    end 
})
secLMS:Button({ Title="▶  Play",  Callback=function() music.manualPlay = true;  musicPlay(music.selected) end })
secLMS:Button({ Title="■  Stop",  Callback=function() music.manualPlay = false; musicReset() end })
secLMS:Button({ Title="↓  Preload LMS", Callback=function()
    task.spawn(function() for name in pairs(musicTracks) do musicFetchAsync(name); task.wait(0.05) end end)
end })

------------------------------------------------------------------------
-- TAB: CHARACTER
------------------------------------------------------------------------
local tabChar      = win:Tab({ Title = "Character", Icon = "user" })
local secKillers   = tabChar:Section({ Title = "Killers",   Opened = false })
secKillers:Button({ Title="Slasher", Locked=true, Callback=function() end })
local secSurvivors = tabChar:Section({ Title = "Survivors", Opened = true })
secSurvivors:Button({ Title="Veeronica", Locked=true, Callback=function() end })
local secSentinels = tabChar:Section({ Title = "Sentinels", Opened = true })
secSentinels:Button({ Title="Guest1337", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/r3take/Forsakan/refs/heads/main/Guest"))() end })
secSentinels:Button({ Title="Shedletsky (just use autocollision lol)", Locked=true, Callback=function() end })
secSentinels:Button({ Title="Chance", Callback=function() loadstring(game:HttpGet("https://pastebin.com/raw/XnXQY5VD"))() end })
secSentinels:Button({ Title="TwoTime", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/r3take/Forsakan/refs/heads/main/viperstab"))() end })
secSentinels:Button({ Title="Jane Doe", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/bezenadduca-code/Ok/refs/heads/main/Jane%20doe"))() end })
local secSupports  = tabChar:Section({ Title = "Supports", Opened = true })
secSupports:Button({ Title="Dusekkar", Callback=function() loadstring(game:HttpGet("https://pastebin.com/raw/ugJKrDyw"))() end })
secSupports:Button({ Title="Elliot",   Callback=function() loadstring(game:HttpGet("https://pastebin.com/raw/cD2nYPxE"))() end })

------------------------------------------------------------------------
-- TAB: INTERFACE (with Config Share - ULTRA COMPACT)
------------------------------------------------------------------------
local tabInterface   = win:Tab({ Title = "Interface", Icon = "scan" })
local secUIFunctions = tabInterface:Section({ Title = "UI Functions", Opened = true })
secUIFunctions:Button({ Title = "Close UI", Callback = function()
    local ok = pcall(function() win:Destroy() end)
    if not ok then pcall(function() win:Close() end) end
end })

------------------------------------------------------------------------
-- ULTRA-COMPACT CONFIG SHARE (TINY STRINGS FOR DISCORD - ~20-30 chars)
------------------------------------------------------------------------
local secConfigShare = tabInterface:Section({ Title = "Config Share", Opened = true })

local CONFIG_PATH = "Viperware/config.json"

-- Map feature names to single characters
local FEATURE_MAP = {
    spoofActive = "A", chatForceEnabled = "B", platEnabled = "C", platDevice = "D", timerSide = "E",
    stamOn = "F", stamLoss = "G", stamGain = "H", stamMax = "I", stamCurrent = "J", stamNoLoss = "K",
    hbOn = "L", hbStrength = "M",
    acOn = "N", acStrength = "O", acMaxDist = "P",
    flowOn = "Q", flowNodeDelay = "R", flowLineDelay = "S",
    aimOn = "T", aimCooldown = "U", aimLockTime = "V", aimMaxDist = "W", aimSmooth = "X",
    absOn = "Y", absRange = "Z", absDur = "a",
    sixerStrafeOn = "b", coolkidWSOOn = "c", noliVoidRushOn = "d",
    displayKillers = "e", displaySurvivors = "f", displayGenerators = "g", displayItems = "h", displayBuildings = "i",
    espPizza = "j", espZombie = "k", espPuddle = "l", espMinionTrans = "m",
    bloodOn = "n", bloodIntensity = "o", bloodDistance = "p",
    musicOn = "q", musicSel = "r",
}

-- Reverse map for decoding
local REVERSE_MAP = {}
for k, v in pairs(FEATURE_MAP) do REVERSE_MAP[v] = k end

-- Default values for type detection
local DEFAULTS = {
    spoofActive = false, chatForceEnabled = false, platEnabled = false, platDevice = "Console", timerSide = "Middle",
    stamOn = false, stamLoss = 10, stamGain = 20, stamMax = 100, stamCurrent = 100, stamNoLoss = false,
    hbOn = false, hbStrength = 50,
    acOn = false, acStrength = 50, acMaxDist = 100,
    flowOn = false, flowNodeDelay = 0.04, flowLineDelay = 0.60,
    aimOn = false, aimCooldown = 0.3, aimLockTime = 0.4, aimMaxDist = 30, aimSmooth = 0.35,
    absOn = false, absRange = 40, absDur = 1.5,
    sixerStrafeOn = false, coolkidWSOOn = false, noliVoidRushOn = false,
    displayKillers = false, displaySurvivors = false, displayGenerators = false, displayItems = false, displayBuildings = false,
    espPizza = false, espZombie = false, espPuddle = false, espMinionTrans = 0.25,
    bloodOn = false, bloodIntensity = 0.6, bloodDistance = 100,
    musicOn = false, musicSel = "CondemnedLMS",
}

-- Compress config to tiny string
function compressConfig(data)
    local parts = {}
    for k, v in pairs(data) do
        local keyChar = FEATURE_MAP[k]
        if keyChar then
            local valStr
            if type(v) == "boolean" then
                valStr = v and "1" or "0"
            elseif type(v) == "number" then
                valStr = string.format("%.2f", v):gsub("%.?0+$", "")
                if valStr == "" then valStr = "0" end
            else
                valStr = tostring(v)
            end
            parts[#parts + 1] = keyChar .. valStr
        end
    end
    return table.concat(parts, ",")
end

-- Decompress tiny config string
function decompressConfig(str)
    local data = {}
    for part in str:gmatch("[^,]+") do
        local keyChar = part:sub(1, 1)
        local valStr = part:sub(2)
        local key = REVERSE_MAP[keyChar]
        if key then
            local default = DEFAULTS[key]
            if type(default) == "boolean" then
                data[key] = valStr == "1"
            elseif type(default) == "number" then
                data[key] = tonumber(valStr) or default
            else
                data[key] = valStr
            end
        end
    end
    return data
end

-- Base64 URL-safe encode (even smaller)
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
function toBase64(str)
    local result = {}
    local bytes = {string.byte(str, 1, #str)}
    for i = 1, #bytes, 3 do
        local b1, b2, b3 = bytes[i] or 0, bytes[i+1] or 0, bytes[i+2] or 0
        local n = b1 * 65536 + b2 * 256 + b3
        result[#result+1] = B64_CHARS:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
        result[#result+1] = B64_CHARS:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
        if bytes[i+1] then
            result[#result+1] = B64_CHARS:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1)
        else
            result[#result+1] = "="
        end
        if bytes[i+2] then
            result[#result+1] = B64_CHARS:sub(n%64+1, n%64+1)
        else
            result[#result+1] = "="
        end
    end
    return table.concat(result)
end

function fromBase64(str)
    local lookup = {}
    for i = 1, #B64_CHARS do lookup[B64_CHARS:sub(i,i)] = i-1 end
    local bytes = {}
    for i = 1, #str, 4 do
        local c1 = lookup[str:sub(i,i)] or 0
        local c2 = lookup[str:sub(i+1,i+1)] or 0
        local c3 = lookup[str:sub(i+2,i+2)] or 0
        local c4 = lookup[str:sub(i+3,i+3)] or 0
        local n = c1*262144 + c2*4096 + c3*64 + c4
        bytes[#bytes+1] = string.char(math.floor(n/65536)%256)
        if str:sub(i+2,i+2) ~= "=" then
            bytes[#bytes+1] = string.char(math.floor(n/256)%256)
        end
        if str:sub(i+3,i+3) ~= "=" then
            bytes[#bytes+1] = string.char(n%256)
        end
    end
    return table.concat(bytes)
end

-- Get current config as tiny string
function getTinyConfig()
    local data = {}
    for k in pairs(FEATURE_MAP) do
        local val
        if k == "stamOn" then val = stam and stam.on
        elseif k == "stamLoss" then val = stam and stam.loss
        elseif k == "stamGain" then val = stam and stam.gain
        elseif k == "stamMax" then val = stam and stam.max
        elseif k == "stamCurrent" then val = stam and stam.current
        elseif k == "stamNoLoss" then val = stam and stam.noLoss
        elseif k == "hbOn" then val = hb and hb.on
        elseif k == "hbStrength" then val = hb and hb.strength
        elseif k == "acOn" then val = ac and ac.on
        elseif k == "acStrength" then val = ac and ac.strength
        elseif k == "acMaxDist" then val = ac and ac.maxDist
        elseif k == "flowOn" then val = flow and flow.on
        elseif k == "flowNodeDelay" then val = flow and flow.nodeDelay
        elseif k == "flowLineDelay" then val = flow and flow.lineDelay
        elseif k == "aimOn" then val = aim and aim.on
        elseif k == "aimCooldown" then val = aim and aim.cooldown
        elseif k == "aimLockTime" then val = aim and aim.lockTime
        elseif k == "aimMaxDist" then val = aim and aim.maxDist
        elseif k == "aimSmooth" then val = aim and aim.smooth
        elseif k == "absOn" then val = abs and abs.on
        elseif k == "absRange" then val = abs and abs.range
        elseif k == "absDur" then val = abs and abs.duration
        elseif k == "sixerStrafeOn" then val = sixerStrafeOn
        elseif k == "coolkidWSOOn" then val = coolkidWSOOn
        elseif k == "noliVoidRushOn" then val = noliVoidRushOn
        elseif k == "displayKillers" then val = displaySystem and displaySystem.showKillers
        elseif k == "displaySurvivors" then val = displaySystem and displaySystem.showSurvivors
        elseif k == "displayGenerators" then val = displaySystem and displaySystem.showGenerators
        elseif k == "displayItems" then val = displaySystem and displaySystem.showItems
        elseif k == "displayBuildings" then val = displaySystem and displaySystem.showBuildings
        elseif k == "espPizza" then val = mset and mset.pizza
        elseif k == "espZombie" then val = mset and mset.zombie
        elseif k == "espPuddle" then val = mset and mset.puddle
        elseif k == "espMinionTrans" then val = mset and mset.transparency
        elseif k == "bloodOn" then val = bloodstain and bloodstain.on
        elseif k == "bloodIntensity" then val = bloodstain and bloodstain.intensity
        elseif k == "bloodDistance" then val = bloodstain and bloodstain.distance
        elseif k == "musicOn" then val = music and music.on
        elseif k == "musicSel" then val = music and music.selected
        elseif k == "spoofActive" then val = spoofActive
        elseif k == "chatForceEnabled" then val = chatForceEnabled
        elseif k == "platEnabled" then val = platEnabled
        elseif k == "platDevice" then val = platDevice
        elseif k == "timerSide" then val = timerSide
        else val = nil
        end
        if val ~= nil then data[k] = val end
    end
    return toBase64(compressConfig(data))
end

-- Apply tiny config (properly loads all flags and calls callbacks)
function applyTinyConfig(encoded)
    local compressed = fromBase64(encoded)
    local data = decompressConfig(compressed)
    
    for k, v in pairs(data) do
        if k == "stamOn" then stam.on = v
        elseif k == "stamLoss" then stam.loss = v
        elseif k == "stamGain" then stam.gain = v
        elseif k == "stamMax" then stam.max = v
        elseif k == "stamCurrent" then stam.current = v
        elseif k == "stamNoLoss" then stam.noLoss = v
        elseif k == "hbOn" then hb.on = v; if v then hbStart() else hbStop() end
        elseif k == "hbStrength" then hb.strength = v
        elseif k == "acOn" then ac.on = v
        elseif k == "acStrength" then ac.strength = v
        elseif k == "acMaxDist" then ac.maxDist = v
        elseif k == "flowOn" then flow.on = v
        elseif k == "flowNodeDelay" then flow.nodeDelay = v
        elseif k == "flowLineDelay" then flow.lineDelay = v
        elseif k == "aimOn" then aim.on = v; if not v then aimUnlock() end
        elseif k == "aimCooldown" then aim.cooldown = v
        elseif k == "aimLockTime" then aim.lockTime = v
        elseif k == "aimMaxDist" then aim.maxDist = v
        elseif k == "aimSmooth" then aim.smooth = v
        elseif k == "absOn" then abs.on = v; if v then absStart() else absStop() end
        elseif k == "absRange" then abs.range = v; absResizeRings()
        elseif k == "absDur" then abs.duration = v
        elseif k == "sixerStrafeOn" then sixerStrafeOn = v
        elseif k == "coolkidWSOOn" then coolkidWSOOn = v
        elseif k == "noliVoidRushOn" then noliVoidRushOn = v; if not v then noliStop() end
        elseif k == "displayKillers" then displaySystem.showKillers = v; task.spawn(function() updateThreatDisplay(v) end)
        elseif k == "displaySurvivors" then displaySystem.showSurvivors = v; task.spawn(function() updateTeammateDisplay(v) end)
        elseif k == "displayGenerators" then displaySystem.showGenerators = v; task.spawn(function() updateObjectiveDisplay(v) end)
        elseif k == "displayItems" then displaySystem.showItems = v; task.spawn(function() updateLootDisplay(v) end)
        elseif k == "displayBuildings" then displaySystem.showBuildings = v; task.spawn(function() updateStructureDisplay(v) end)
        elseif k == "espPizza" then mset.pizza = v; if v then scanPizza() else clearTag("pizza") end
        elseif k == "espZombie" then mset.zombie = v; if v then scanZombie() else clearTag("zombie") end
        elseif k == "espPuddle" then mset.puddle = v; if v then scanPuddles() else clearTag("puddle") end
        elseif k == "espMinionTrans" then mset.transparency = v; updateTransparency()
        elseif k == "bloodOn" then bloodstain.on = v; if v then bloodStartMonitoring() else bloodStopMonitoring() end
        elseif k == "bloodIntensity" then bloodstain.intensity = v
        elseif k == "bloodDistance" then bloodstain.distance = v
        elseif k == "musicOn" then music.on = v; if v then music.thread = task.spawn(musicMonitor) else if music.thread then task.cancel(music.thread); music.thread = nil end end
        elseif k == "musicSel" then music.selected = v
        elseif k == "spoofActive" then spoofActive = v; if v then spoofStart() else spoofStop() end
        elseif k == "chatForceEnabled" then chatForceEnabled = v; if v then enforceChatOn() end
        elseif k == "platEnabled" then platEnabled = v; if v then platStart() else platStop() end
        elseif k == "platDevice" then platDevice = v
        elseif k == "timerSide" then timerSide = v; applyTimerPos()
        end
    end
    
    -- Start/stop features based on state
    if stam.on then stamStart() else stamStop() end
    if music.on then musicFetchAsync(music.selected) end
end

-- Copy config (tiny!)
secConfigShare:Button({
    Title = "📋 Copy Config (Tiny!)",
    Icon = "copy",
    Callback = function()
        local ok, err = pcall(function()
            local tiny = getTinyConfig()
            setclipboard("vw:" .. tiny)
        end)
        if ok then
            ui:Notify({ Title = "Config Copied!", Content = "Tiny string! Paste anywhere!", Icon = "copy", Duration = 3 })
        else
            ui:Notify({ Title = "Copy Failed", Content = tostring(err), Icon = "x", Duration = 3 })
        end
    end
})

local loadConfigStr = ""
secConfigShare:Input({
    Title = "Paste Config String",
    Icon = "clipboard",
    Placeholder = "vw:... (tiny string)",
    Callback = function(val)
        loadConfigStr = val
    end
})

secConfigShare:Button({
    Title = "📥 Load Config",
    Icon = "download",
    Callback = function()
        if loadConfigStr == "" or not loadConfigStr:match("^vw:") then
            ui:Notify({ Title = "Invalid Config", Content = "String must start with vw:", Icon = "x", Duration = 3 })
            return
        end
        local ok, err = pcall(function()
            local tiny = loadConfigStr:sub(4)
            applyTinyConfig(tiny)
            -- Also save to disk for persistence
            local fullData = {}
            for k in pairs(FEATURE_MAP) do
                local val
                if k == "stamOn" then val = stam.on
                elseif k == "stamLoss" then val = stam.loss
                elseif k == "stamGain" then val = stam.gain
                elseif k == "stamMax" then val = stam.max
                elseif k == "stamCurrent" then val = stam.current
                elseif k == "stamNoLoss" then val = stam.noLoss
                elseif k == "hbOn" then val = hb.on
                elseif k == "hbStrength" then val = hb.strength
                elseif k == "acOn" then val = ac.on
                elseif k == "acStrength" then val = ac.strength
                elseif k == "acMaxDist" then val = ac.maxDist
                elseif k == "flowOn" then val = flow.on
                elseif k == "flowNodeDelay" then val = flow.nodeDelay
                elseif k == "flowLineDelay" then val = flow.lineDelay
                elseif k == "aimOn" then val = aim.on
                elseif k == "aimCooldown" then val = aim.cooldown
                elseif k == "aimLockTime" then val = aim.lockTime
                elseif k == "aimMaxDist" then val = aim.maxDist
                elseif k == "aimSmooth" then val = aim.smooth
                elseif k == "absOn" then val = abs.on
                elseif k == "absRange" then val = abs.range
                elseif k == "absDur" then val = abs.duration
                elseif k == "sixerStrafeOn" then val = sixerStrafeOn
                elseif k == "coolkidWSOOn" then val = coolkidWSOOn
                elseif k == "noliVoidRushOn" then val = noliVoidRushOn
                elseif k == "displayKillers" then val = displaySystem.showKillers
                elseif k == "displaySurvivors" then val = displaySystem.showSurvivors
                elseif k == "displayGenerators" then val = displaySystem.showGenerators
                elseif k == "displayItems" then val = displaySystem.showItems
                elseif k == "displayBuildings" then val = displaySystem.showBuildings
                elseif k == "espPizza" then val = mset.pizza
                elseif k == "espZombie" then val = mset.zombie
                elseif k == "espPuddle" then val = mset.puddle
                elseif k == "espMinionTrans" then val = mset.transparency
                elseif k == "bloodOn" then val = bloodstain.on
                elseif k == "bloodIntensity" then val = bloodstain.intensity
                elseif k == "bloodDistance" then val = bloodstain.distance
                elseif k == "musicOn" then val = music.on
                elseif k == "musicSel" then val = music.selected
                elseif k == "spoofActive" then val = spoofActive
                elseif k == "chatForceEnabled" then val = chatForceEnabled
                elseif k == "platEnabled" then val = platEnabled
                elseif k == "platDevice" then val = platDevice
                elseif k == "timerSide" then val = timerSide
                else val = nil
                end
                if val ~= nil then fullData[k] = val end
            end
            writefile(CONFIG_PATH, svc.Http:JSONEncode(fullData))
            viperConfig:Load()
        end)
        if ok then
            ui:Notify({ Title = "Config Loaded!", Content = "All settings applied!", Icon = "check", Duration = 4 })
        else
            ui:Notify({ Title = "Load Failed", Content = "Invalid config string.", Icon = "x", Duration = 3 })
        end
    end
})

secConfigShare:Button({
    Title = "📊 Config Size",
    Icon = "info",
    Callback = function()
        local tiny = getTinyConfig()
        ui:Notify({ Title = "Config Size", Content = "Length: " .. #tiny .. " chars\nFormat: vw:" .. tiny:sub(1, 10) .. "...", Icon = "info", Duration = 5 })
    end
})

------------------------------------------------------------------------
-- Auto-save loop
------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function() cfg.save() end)
    end
end)

print("v1prware ready")
