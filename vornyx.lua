--[[
    Vornyx - Code Sniper
    Neon Purple Edition

    Load with:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kosaibenshi56-alt/ApexSniper/main/vornyx.lua"))()

    Features:
    - Key system (10,000 keys + owner key + online blacklist)
    - Live chat tracking (auto-grabs codes said by admins in chat)
    - Riddle solver (answers common admin riddles automatically)
    - Auto paste + instant submit (clipboard watcher)
    - Code history popup (pencil icon copies a code back into the box)
    - Discord: https://discord.gg/8ZGquBzW9N

    Toggle UI: Right Shift
]]

-------------------------------------------------
-- Services
-------------------------------------------------
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local TextChatService    = game:GetService("TextChatService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-------------------------------------------------
-- Config
-------------------------------------------------
local CONFIG = {
    DiscordLink   = "https://discord.gg/8ZGquBzW9N",
    ScriptName    = "Vornyx - Code Sniper",
    -- key system
    KeysURL       = "https://raw.githubusercontent.com/kosaibenshi56-alt/ApexSniper/main/keys.json",
    BlacklistURL  = "https://raw.githubusercontent.com/kosaibenshi56-alt/ApexSniper/main/blacklist.json",
    OwnerKey      = "kosaiisthegoat",
    KeyFile       = "VornyxKey.txt",
    -- names to watch in chat (lowercase). add more admin names here
    WatchedNames  = { "sammy" },
    TrackEveryone = true,   -- grab codes from any player, not just WatchedNames
    TrackSelf     = true,   -- also react to your own chat messages (for testing)
    SubmitDelay   = 0,      -- seconds to wait before auto submit (0 = instant)
    SubmitAfter   = 1,      -- combine this many one-word chat messages into one code
    AutoSubmit    = true,
    AutoPaste     = true,   -- watch clipboard and auto paste + submit new codes
    RiddleSolver  = true,
    RetypeInvalid = true,
    ToggleKey     = Enum.KeyCode.RightShift,
}

-------------------------------------------------
-- Theme (Neon Purple)
-------------------------------------------------
local THEME = {
    Background   = Color3.fromRGB(16, 8, 28),
    Panel        = Color3.fromRGB(26, 13, 46),
    PanelDark    = Color3.fromRGB(12, 6, 22),
    Neon         = Color3.fromRGB(174, 0, 255),
    NeonSoft     = Color3.fromRGB(200, 90, 255),
    NeonDim      = Color3.fromRGB(90, 30, 140),
    Text         = Color3.fromRGB(240, 230, 255),
    TextDim      = Color3.fromRGB(170, 150, 200),
    Success      = Color3.fromRGB(90, 255, 140),
    Fail         = Color3.fromRGB(255, 90, 120),
}

-------------------------------------------------
-- State
-------------------------------------------------
local State = {
    History        = {},   -- { {code = "ABC", from = "sammy", time = "12:00"} , ... }
    LastCode       = nil,
    Submitting     = false,
    Parts          = {},   -- captured one-word message parts
    LastPartAt        = 0,
    LastPartSource    = nil,  -- FIX: locks the buffer to one speaker so random players can't pollute it
    LastSystemToken   = nil,  -- FIX2: dedup token seen from both announcement+screen within window
    LastSystemTokenAt = 0,
    Enabled           = true, -- master switch (Scanning button)
}

-------------------------------------------------
-- Riddle solver database
-- key: pattern searched in chat message (lowercase)
-- value: the answer to type
-------------------------------------------------
local RIDDLES = {
    { q = "what has keys but can't open locks",            a = "piano" },
    { q = "what has keys but no locks",                    a = "piano" },
    { q = "what has hands but can't clap",                 a = "clock" },
    { q = "what has hands but cannot clap",                a = "clock" },
    { q = "what has a face and two hands",                 a = "clock" },
    { q = "what gets wetter the more it dries",            a = "towel" },
    { q = "what gets wetter as it dries",                  a = "towel" },
    { q = "what has to be broken before you can use it",   a = "egg" },
    { q = "what has a neck but no head",                   a = "bottle" },
    { q = "what has an eye but cannot see",                a = "needle" },
    { q = "what has one eye but can't see",                a = "needle" },
    { q = "what goes up but never comes down",             a = "age" },
    { q = "what has legs but doesn't walk",                a = "table" },
    { q = "what has legs but cannot walk",                 a = "table" },
    { q = "what has teeth but cannot bite",                a = "comb" },
    { q = "what has a head and a tail but no body",        a = "coin" },
    { q = "what can travel around the world while staying in a corner", a = "stamp" },
    { q = "what runs but never walks",                     a = "river" },
    { q = "what has a bed but never sleeps",               a = "river" },
    { q = "what can you catch but not throw",              a = "cold" },
    { q = "what is full of holes but still holds water",   a = "sponge" },
    { q = "what building has the most stories",            a = "library" },
    { q = "what month has 28 days",                        a = "all of them" },
    { q = "what goes up when rain comes down",             a = "umbrella" },
    { q = "the more you take, the more you leave behind",  a = "footsteps" },
    { q = "what belongs to you but others use it more",    a = "your name" },
    { q = "i speak without a mouth and hear without ears", a = "echo" },
    { q = "what can fly without wings",                    a = "time" },
    { q = "what flies without wings",                      a = "time" },
    { q = "what kind of room has no doors or windows",     a = "mushroom" },
    { q = "what room has no doors",                        a = "mushroom" },
    { q = "what has words but never speaks",               a = "book" },
    { q = "what has a thumb and four fingers but is not alive", a = "glove" },
    { q = "what invention lets you look right through a wall",  a = "window" },
    { q = "what is always in front of you but can't be seen",   a = "future" },
    { q = "what can you break, even if you never pick it up",   a = "promise" },
    { q = "what tastes better than it smells",             a = "tongue" },
    { q = "what has many rings but no fingers",            a = "phone" },
    { q = "what has branches but no fruit",                a = "bank" },
    { q = "what gets bigger when more is taken away",      a = "hole" },
    { q = "what gets sharper the more you use it",         a = "brain" },
    { q = "what has 88 keys",                              a = "piano" },
    { q = "what animal is the best brainrot",              a = "tralalero" },
}

-------------------------------------------------
-- Safe executor functions
-------------------------------------------------
local setclip = setclipboard or toclipboard or (syn and syn.set_clipboard) or function() end
local getclip = getclipboard or (syn and syn.get_clipboard) or function() return "" end

local function safeParent(gui)
    local ok = pcall(function()
        if gethui then
            gui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        else
            gui.Parent = CoreGui
        end
    end)
    if not ok then
        gui.Parent = PlayerGui
    end
end

-------------------------------------------------
-- Find the game's code redeem UI (Steal a Brainrot)
-- Scans PlayerGui for a TextBox that looks like a code input
-- and a submit button near it.
-------------------------------------------------
local function isOurGui(obj)
    local p = obj
    while p do
        if p.Name == "VornyxCodeSniper" then return true end
        p = p.Parent
    end
    return false
end

-- known code UI path used by Steal a Brainrot style games
local KNOWN_CODE_BOX_PATH = { "Codes", "Codes", "CodeRedeem", "TextBox" }
local REDEEM_GUID = "7d14a912-1040-4867-b005-98838eb9acc4"

local getupvals = (debug and debug.getupvalues) or getupvalues
local getconns  = getconnections or (debug and debug.getconnections)
local setupval  = (debug and debug.setupvalue) or setupvalue

local function knownCodeBox()
    local node = PlayerGui
    for _, name in ipairs(KNOWN_CODE_BOX_PATH) do
        if not node then return nil end
        node = node:FindFirstChild(name)
    end
    if node and node:IsA("TextBox") then return node end
    local gui = PlayerGui:FindFirstChild("Codes")
    if gui then
        for _, obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("TextBox") then return obj end
        end
    end
    return nil
end

local RedeemRemote
local function resolveRedeemRemote()
    if RedeemRemote and RedeemRemote.Parent then return RedeemRemote end
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    local net = packages and packages:FindFirstChild("Net")
    if not net then return nil end
    local ok, api = pcall(require, net)
    if ok and type(api) == "table" then
        local rok, rf = pcall(function() return api:RemoteFunction(REDEEM_GUID) end)
        if rok and typeof(rf) == "Instance" then RedeemRemote = rf end
    end
    return RedeemRemote
end

local function killDebounce(fn)
    if not (fn and setupval and getupvals) then return end
    local ok, ups = pcall(getupvals, fn)
    if ok and type(ups) == "table" then
        for i, v in pairs(ups) do
            if type(v) == "boolean" then pcall(setupval, fn, i, false) end
        end
    end
end

local function redeemViaBox(code)
    if not getconns then return false end
    local box = knownCodeBox()
    if not box then return false end
    local ok, conns = pcall(getconns, box.FocusLost)
    if not ok or type(conns) ~= "table" or #conns == 0 then return false end
    local fired = false
    for _, c in ipairs(conns) do
        local fn
        pcall(function() fn = c.Function end)
        killDebounce(fn)
        box.Text = code
        box.Active = true
        box.Selectable = true
        local fok = pcall(function()
            if c.Enabled ~= false then c:Fire(true) end
        end)
        fired = fired or fok
    end
    return fired
end

local function redeemViaRemote(code)
    local rf = resolveRedeemRemote()
    if not rf then return false end
    local ok = pcall(function() return rf:InvokeServer(code) end)
    return ok
end

local function findCodeBox()
    local known = knownCodeBox()
    if known then return known end
    local best, bestScore = nil, 0
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextBox") and not isOurGui(obj) then
            local hint = (obj.PlaceholderText or ""):lower() .. " " .. obj.Name:lower()
            local p = obj.Parent
            for _ = 1, 4 do
                if p and p ~= PlayerGui then
                    hint = hint .. " " .. p.Name:lower()
                    p = p.Parent
                end
            end
            local score = 0
            if hint:find("code") then score = score + 4 end
            if hint:find("redeem") then score = score + 3 end
            if hint:find("twitter") then score = score + 2 end
            if hint:find("enter") then score = score + 1 end
            if hint:find("type") then score = score + 1 end
            if hint:find("here") then score = score + 1 end
            if score > 0 then
                if obj.Visible then score = score + 2 end
                if score > bestScore then
                    best, bestScore = obj, score
                end
            end
        end
    end
    return best
end

local function findSubmitButton(codeBox)
    local searchRoots = {}
    if codeBox then
        local p = codeBox.Parent
        for _ = 1, 3 do
            if p and p:IsA("GuiObject") then
                table.insert(searchRoots, p)
                p = p.Parent
            end
        end
    end
    table.insert(searchRoots, PlayerGui)
    for _, root in ipairs(searchRoots) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local txt = ""
                if obj:IsA("TextButton") then txt = obj.Text:lower() end
                local hint = txt .. " " .. obj.Name:lower()
                if hint:find("submit") or hint:find("redeem") or hint:find("claim") or hint:find("enter") then
                    return obj
                end
            end
        end
    end
    return nil
end

local function pressButton(btn)
    if not btn then return false end
    local ok = pcall(function()
        if firesignal then
            firesignal(btn.MouseButton1Click)
        else
            for _, con in ipairs(getconnections and getconnections(btn.MouseButton1Click) or {}) do
                con:Fire()
            end
        end
    end)
    if not ok then
        pcall(function()
            local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
    end
    return true
end

-------------------------------------------------
-- MAIN SCRIPT (runs after the key check passes)
-------------------------------------------------
local function loadMain()

local Gui = Instance.new("ScreenGui")
Gui.Name = "VornyxCodeSniper"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
safeParent(Gui)

local function round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 12)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.Neon
    s.Thickness = thickness or 1.5
    s.Transparency = transparency or 0.2
    s.Parent = obj
    return s
end

-- Main window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 420, 0, 490)
Main.Position = UDim2.new(0.5, -210, 0.5, -245)
Main.BackgroundColor3 = THEME.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Gui
round(Main, 16)
stroke(Main, THEME.Neon, 2, 0.1)

-- Dragging
do
    local dragging, dragStart, startPos
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 8)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = THEME.Neon
Title.Text = CONFIG.ScriptName
Title.Parent = Main

local TitleLine = Instance.new("Frame")
TitleLine.Size = UDim2.new(1, -40, 0, 2)
TitleLine.Position = UDim2.new(0, 20, 0, 50)
TitleLine.BackgroundColor3 = THEME.Neon
TitleLine.BackgroundTransparency = 0.4
TitleLine.BorderSizePixel = 0
TitleLine.Parent = Main

-- Discord button (copies link)
local Discord = Instance.new("TextButton")
Discord.Size = UDim2.new(1, -40, 0, 34)
Discord.Position = UDim2.new(0, 20, 0, 60)
Discord.BackgroundColor3 = THEME.Panel
Discord.Font = Enum.Font.GothamSemibold
Discord.TextSize = 14
Discord.TextColor3 = THEME.NeonSoft
Discord.Text = CONFIG.DiscordLink
Discord.AutoButtonColor = false
Discord.Parent = Main
round(Discord, 10)
stroke(Discord, THEME.NeonDim, 1.5, 0.3)

-- Status button ("Scanning..." = on, "Scan" = off)
local Status = Instance.new("TextButton")
Status.Size = UDim2.new(1, -40, 0, 38)
Status.Position = UDim2.new(0, 20, 0, 102)
Status.BackgroundColor3 = THEME.Panel
Status.Font = Enum.Font.GothamBold
Status.TextSize = 17
Status.TextColor3 = THEME.Text
Status.Text = "Scanning..."
Status.AutoButtonColor = false
Status.Parent = Main
round(Status, 10)
stroke(Status, THEME.Neon, 1.5, 0.25)

-------------------------------------------------
-- Toggle / setting row helpers
-------------------------------------------------
local function makePanel(x, y, w, h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, w, 0, h)
    f.Position = UDim2.new(0, x, 0, y)
    f.BackgroundColor3 = THEME.Panel
    f.BorderSizePixel = 0
    f.Parent = Main
    round(f, 10)
    stroke(f, THEME.NeonDim, 1.5, 0.35)
    return f
end

local function makeToggle(panel, labelText, initial, onChange)
    local api = {}
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -66, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = THEME.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Parent = panel

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 46, 0, 22)
    btn.Position = UDim2.new(1, -54, 0.5, -11)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = panel
    round(btn, 11)

    local value = initial
    local function render()
        btn.Text = value and "ON" or "OFF"
        btn.BackgroundColor3 = value and THEME.Neon or THEME.PanelDark
        btn.TextColor3 = value and Color3.new(1, 1, 1) or THEME.TextDim
    end
    render()
    btn.MouseButton1Click:Connect(function()
        value = not value
        render()
        onChange(value)
    end)
    function api.Set(v)
        value = v
        render()
    end
    return api
end

local HistoryFrame -- forward declaration (created below)

-- Row 1: Auto submit | Riddle solver
local p1 = makePanel(20, 152, 185, 46)
makeToggle(p1, "Auto submit", CONFIG.AutoSubmit, function(v) CONFIG.AutoSubmit = v end)

local p2 = makePanel(215, 152, 185, 46)
makeToggle(p2, "Riddle solver", CONFIG.RiddleSolver, function(v) CONFIG.RiddleSolver = v end)

-- Row 2: History | Submit after msgs
local p3 = makePanel(20, 206, 185, 46)
local HistoryToggle = makeToggle(p3, "History", false, function(v)
    if HistoryFrame then
        HistoryFrame.Visible = v
    end
end)

local p4 = makePanel(215, 206, 185, 46)
do
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 90, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = THEME.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "Submit after msgs"
    label.Parent = p4

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 22, 0, 22)
    minus.Position = UDim2.new(1, -80, 0.5, -11)
    minus.BackgroundColor3 = THEME.PanelDark
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 14
    minus.TextColor3 = THEME.Text
    minus.Text = "-"
    minus.Parent = p4
    round(minus, 6)

    local num = Instance.new("TextLabel")
    num.Size = UDim2.new(0, 26, 0, 22)
    num.Position = UDim2.new(1, -56, 0.5, -11)
    num.BackgroundTransparency = 1
    num.Font = Enum.Font.GothamBold
    num.TextSize = 16
    num.TextColor3 = THEME.NeonSoft
    num.Text = tostring(CONFIG.SubmitAfter)
    num.Parent = p4

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 22, 0, 22)
    plus.Position = UDim2.new(1, -30, 0.5, -11)
    plus.BackgroundColor3 = THEME.PanelDark
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 14
    plus.TextColor3 = THEME.Text
    plus.Text = "+"
    plus.Parent = p4
    round(plus, 6)

    minus.MouseButton1Click:Connect(function()
        CONFIG.SubmitAfter = math.max(1, CONFIG.SubmitAfter - 1)
        num.Text = tostring(CONFIG.SubmitAfter)
        State.Parts = {}
    end)
    plus.MouseButton1Click:Connect(function()
        CONFIG.SubmitAfter = math.min(10, CONFIG.SubmitAfter + 1)
        num.Text = tostring(CONFIG.SubmitAfter)
        State.Parts = {}
    end)
end

-------------------------------------------------
-- Code input + Paste + Submit + History
-------------------------------------------------
local CodeBox = Instance.new("TextBox")
CodeBox.Size = UDim2.new(1, -40, 0, 38)
CodeBox.Position = UDim2.new(0, 20, 0, 370)
CodeBox.BackgroundColor3 = THEME.PanelDark
CodeBox.Font = Enum.Font.Code
CodeBox.TextSize = 16
CodeBox.TextColor3 = THEME.Text
CodeBox.PlaceholderText = "enter / paste code here..."
CodeBox.PlaceholderColor3 = THEME.TextDim
CodeBox.Text = ""
CodeBox.ClearTextOnFocus = false
-- hidden: codes go straight into the game's own code box
round(CodeBox, 10)

-------------------------------------------------
-- Log console
-------------------------------------------------
local Console = Instance.new("ScrollingFrame")
Console.Size = UDim2.new(1, -40, 0, 210)
Console.Position = UDim2.new(0, 20, 0, 260)
Console.BackgroundColor3 = THEME.PanelDark
Console.BorderSizePixel = 0
Console.ScrollBarThickness = 5
Console.ScrollBarImageColor3 = THEME.Neon
Console.CanvasSize = UDim2.new(0, 0, 0, 0)
Console.AutomaticCanvasSize = Enum.AutomaticSize.Y
Console.Parent = Main
round(Console, 10)
stroke(Console, THEME.Neon, 1.5, 0.35)

local ConsoleLayout = Instance.new("UIListLayout")
ConsoleLayout.SortOrder = Enum.SortOrder.LayoutOrder
ConsoleLayout.Padding = UDim.new(0, 2)
ConsoleLayout.Parent = Console

local ConsolePad = Instance.new("UIPadding")
ConsolePad.PaddingLeft = UDim.new(0, 8)
ConsolePad.PaddingTop = UDim.new(0, 6)
ConsolePad.Parent = Console

local logOrder = 0
local function log(msg, color)
    logOrder += 1
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -16, 0, 16)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Code
    l.TextSize = 13
    l.TextColor3 = color or THEME.TextDim
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Text = "> " .. msg
    l.LayoutOrder = logOrder
    l.Parent = Console
    task.defer(function()
        Console.CanvasPosition = Vector2.new(0, math.max(0, ConsoleLayout.AbsoluteContentSize.Y - Console.AbsoluteSize.Y))
    end)
end

log("scanning for codes...")

Status.MouseButton1Click:Connect(function()
    State.Enabled = not State.Enabled
    if State.Enabled then
        Status.Text = "Scanning..."
        Status.TextColor3 = THEME.Text
        log("sniper ON", THEME.Success)
    else
        Status.Text = "Scan"
        Status.TextColor3 = THEME.TextDim
        log("sniper OFF", THEME.Fail)
    end
end)

-------------------------------------------------
-- History popup
-------------------------------------------------
HistoryFrame = Instance.new("Frame")
HistoryFrame.Size = UDim2.new(0, 300, 0, 380)
HistoryFrame.Position = UDim2.new(0.5, 230, 0.5, -190)
HistoryFrame.BackgroundColor3 = THEME.Background
HistoryFrame.BorderSizePixel = 0
HistoryFrame.Visible = false
HistoryFrame.Active = true
HistoryFrame.Parent = Gui
round(HistoryFrame, 14)
stroke(HistoryFrame, THEME.Neon, 2, 0.1)

local HistTitle = Instance.new("TextLabel")
HistTitle.Size = UDim2.new(1, -50, 0, 36)
HistTitle.Position = UDim2.new(0, 14, 0, 4)
HistTitle.BackgroundTransparency = 1
HistTitle.Font = Enum.Font.GothamBold
HistTitle.TextSize = 16
HistTitle.TextColor3 = THEME.Neon
HistTitle.TextXAlignment = Enum.TextXAlignment.Left
HistTitle.Text = "Code History"
HistTitle.Parent = HistoryFrame

local HistClose = Instance.new("TextButton")
HistClose.Size = UDim2.new(0, 26, 0, 26)
HistClose.Position = UDim2.new(1, -34, 0, 8)
HistClose.BackgroundColor3 = THEME.Panel
HistClose.Font = Enum.Font.GothamBold
HistClose.TextSize = 14
HistClose.TextColor3 = THEME.Fail
HistClose.Text = "X"
HistClose.Parent = HistoryFrame
round(HistClose, 8)

local HistList = Instance.new("ScrollingFrame")
HistList.Size = UDim2.new(1, -24, 1, -56)
HistList.Position = UDim2.new(0, 12, 0, 44)
HistList.BackgroundColor3 = THEME.PanelDark
HistList.BorderSizePixel = 0
HistList.ScrollBarThickness = 5
HistList.ScrollBarImageColor3 = THEME.Neon
HistList.CanvasSize = UDim2.new(0, 0, 0, 0)
HistList.AutomaticCanvasSize = Enum.AutomaticSize.Y
HistList.Parent = HistoryFrame
round(HistList, 10)

local HistLayout = Instance.new("UIListLayout")
HistLayout.SortOrder = Enum.SortOrder.LayoutOrder
HistLayout.Padding = UDim.new(0, 4)
HistLayout.Parent = HistList

local HistPad = Instance.new("UIPadding")
HistPad.PaddingLeft = UDim.new(0, 6)
HistPad.PaddingTop = UDim.new(0, 6)
HistPad.PaddingRight = UDim.new(0, 6)
HistPad.Parent = HistList

local histOrder = 0
local function addHistoryEntry(code, from)
    histOrder += 1
    table.insert(State.History, 1, { code = code, from = from })

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 34)
    row.BackgroundColor3 = THEME.Panel
    row.BorderSizePixel = 0
    row.LayoutOrder = -histOrder -- newest on top
    row.Parent = HistList
    round(row, 8)
    stroke(row, THEME.NeonDim, 1, 0.4)

    local codeLabel = Instance.new("TextLabel")
    codeLabel.Size = UDim2.new(1, -46, 1, 0)
    codeLabel.Position = UDim2.new(0, 8, 0, 0)
    codeLabel.BackgroundTransparency = 1
    codeLabel.Font = Enum.Font.Code
    codeLabel.TextSize = 14
    codeLabel.TextColor3 = THEME.Text
    codeLabel.TextXAlignment = Enum.TextXAlignment.Left
    codeLabel.TextTruncate = Enum.TextTruncate.AtEnd
    codeLabel.Text = code .. (from and ("  [" .. from .. "]") or "")
    codeLabel.Parent = row

    -- pencil button: copies code into the code box
    local pencil = Instance.new("TextButton")
    pencil.Size = UDim2.new(0, 28, 0, 24)
    pencil.Position = UDim2.new(1, -34, 0.5, -12)
    pencil.BackgroundColor3 = THEME.Neon
    pencil.Font = Enum.Font.GothamBold
    pencil.TextSize = 14
    pencil.TextColor3 = Color3.new(1, 1, 1)
    pencil.Text = utf8.char(0x270E) -- pencil symbol
    pencil.AutoButtonColor = false
    pencil.Parent = row
    round(pencil, 6)

    pencil.MouseButton1Click:Connect(function()
        CodeBox.Text = code
        setclip(code)
        log("history -> loaded code: " .. code, THEME.NeonSoft)
    end)
end

HistClose.MouseButton1Click:Connect(function()
    HistoryFrame.Visible = false
    HistoryToggle.Set(false)
end)

-------------------------------------------------
-- Discord copy
-------------------------------------------------
Discord.MouseButton1Click:Connect(function()
    setclip(CONFIG.DiscordLink)
    local old = Discord.Text
    Discord.Text = "copied to clipboard!"
    task.delay(1, function() Discord.Text = old end)
end)

-------------------------------------------------
-- Submit logic (extra fast)
-------------------------------------------------
local function setStatus(text, color)
    if not State.Enabled then return end
    Status.Text = text
    Status.TextColor3 = color or THEME.Text
end

local function submitCode(code, source)
    if not State.Enabled then return end
    if State.Submitting then return end
    if not code or code == "" then
        log("nothing to submit", THEME.Fail)
        return
    end
    State.Submitting = true
    State.LastCode = code
    CodeBox.Text = code
    addHistoryEntry(code, source)

    task.spawn(function()
        if CONFIG.SubmitDelay > 0 then
            setStatus("Submitting in " .. CONFIG.SubmitDelay .. "s...", THEME.NeonSoft)
            task.wait(CONFIG.SubmitDelay)
        end
        setStatus("Submitting...", THEME.NeonSoft)

        local submitted = false

        -- Retry loop: poll for up to 8 seconds so codes auto-submit even if the game's
        -- code UI isn't open yet when the word fires. Each tick also re-pastes the code
        -- into the box (bug 3 — immediate paste on every detected word).
        local deadline = os.clock() + 8
        while not submitted and os.clock() < deadline do
            -- fastest path: fire the code box's own FocusLost handler (kills debounce)
            if redeemViaBox(code) then
                submitted = true
                log("submitted '" .. code .. "' via code box handler", THEME.Success)
                break
            end
            -- second path: invoke the redeem RemoteFunction directly
            if redeemViaRemote(code) then
                submitted = true
                log("submitted '" .. code .. "' via redeem remote", THEME.Success)
                break
            end
            -- third path: find the visible TextBox and fire it
            local gameBox = findCodeBox()
            if gameBox then
                log("game code box: " .. gameBox:GetFullName(), THEME.TextDim)
                -- Immediately paste code text (bug 3: instant paste the moment box is found)
                pcall(function()
                    gameBox.Text = code
                    gameBox:CaptureFocus()
                    task.wait()
                    gameBox.Text = code
                    gameBox:ReleaseFocus(true) -- triggers enter / submit
                end)
                local btn = findSubmitButton(gameBox)
                if btn then
                    pressButton(btn)
                    submitted = true
                    log("submitted '" .. code .. "' via " .. btn.Name, THEME.Success)
                else
                    submitted = true
                    log("submitted '" .. code .. "' via enter key", THEME.Success)
                end
                break
            end
            -- box not found yet — keep code live in clipboard and keep polling
            setclip(code)
            task.wait(0.15)
        end

        if not submitted then
            log("code box not found after 8s - open Codes menu, '" .. code .. "' is on clipboard", THEME.Fail)
            setclip(code)
        end

        if submitted then
            setStatus("Submitted: " .. code, THEME.Success)
            -- retype invalid: retry once after a moment
            if CONFIG.RetypeInvalid then
                task.delay(1.5, function()
                    local box = findCodeBox()
                    if box and box.Text ~= "" and box.Text ~= code then
                        -- game likely cleared / rejected; retype
                        pcall(function()
                            box.Text = code
                            box:ReleaseFocus(true)
                        end)
                        local btn = findSubmitButton(box)
                        if btn then pressButton(btn) end
                        log("retyped invalid code: " .. code, THEME.NeonSoft)
                    end
                end)
            end
        else
            setStatus("Scanning...", THEME.Text)
        end

        task.wait(0.5)
        State.Submitting = false
        task.delay(2, function()
            if not State.Submitting then setStatus("Scanning...", THEME.Text) end
        end)
    end)
end

CodeBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and CodeBox.Text ~= "" then
        submitCode(CodeBox.Text, "manual")
    end
end)

-------------------------------------------------
-- Auto paste: clipboard watcher
-- the moment you copy a code anywhere, it gets
-- pasted into the box and submitted automatically
-------------------------------------------------
task.spawn(function()
    local lastClip = ""
    pcall(function() lastClip = getclip() or "" end)
    while true do
        task.wait(0.15)
        if CONFIG.AutoPaste and State.Enabled then
            local clip
            pcall(function() clip = getclip() end)
            if clip and clip ~= "" and clip ~= lastClip then
                lastClip = clip
                -- ignore huge text / links that clearly are not codes
                if #clip <= 40 and not clip:find("http") and not clip:find("\n") then
                    local code = clip:match("^%s*(.-)%s*$")
                    if code ~= "" and code ~= State.LastCode then
                        log("auto-paste from clipboard: " .. code, THEME.NeonSoft)
                        CodeBox.Text = code
                        if CONFIG.AutoSubmit then
                            submitCode(code, "auto-paste")
                        end
                    end
                end
            end
        end
    end
end)

-------------------------------------------------
-- Chat tracking
-------------------------------------------------
local function isWatched(name)
    if CONFIG.TrackEveryone then return true end
    local lower = name:lower()
    for _, watched in ipairs(CONFIG.WatchedNames) do
        if lower:find(watched:lower(), 1, true) then
            return true
        end
    end
    return false
end

-- Checks WatchedNames only — deliberately ignores TrackEveryone.
-- Used for multi-part collection so random players can never pollute the buffer.
local function isWatchedExplicit(name)
    local lower = name:lower()
    for _, w in ipairs(CONFIG.WatchedNames) do
        if lower:find(w:lower(), 1, true) then return true end
    end
    return false
end

-- try to pull a code out of a chat message
local function extractCode(msg)
    -- explicit "code: XXXX" / "code is XXXX" / "code = XXXX"
    local explicit = msg:match("[Cc][Oo][Dd][Ee]%s*[:=]?%s*[Ii]?[Ss]?%s*([%w_%-]+)")
    if explicit and #explicit >= 3 and explicit:lower() ~= "is" then
        return explicit
    end
    -- quoted "XXXX"
    local quoted = msg:match('"([%w_%-]+)"') or msg:match("'([%w_%-]+)'")
    if quoted and #quoted >= 3 then
        return quoted
    end
    -- a lone token that looks like a code (has digits, or 4+ uppercase)
    for token in msg:gmatch("[%w_%-]+") do
        if #token >= 4 and (token:match("%d") and token:match("%a")) then
            return token
        end
        if #token >= 4 and token == token:upper() and token:match("^%u+%d*$") then
            return token
        end
    end
    return nil
end

local function solveRiddle(msg)
    local lower = msg:lower()
    for _, riddle in ipairs(RIDDLES) do
        if lower:find(riddle.q, 1, true) then
            return riddle.a
        end
    end
    return nil
end

-- shared part collector: every captured one-word token is appended here.
-- when SubmitAfter parts are collected they get combined and submitted.
local function handleToken(token, source)
    if not State.Enabled then return end
    local now = os.clock()

    -- Global dedup: same token from ANY source within 2s is a duplicate.
    -- Covers announcement→screen, chat→announcement, multi-RemoteEvent double-fire,
    -- and multi-listener chat paths (TextChatService + legacy + GUI watcher all at once).
    -- 2s window is wide enough to catch all async paths; real repeated code words from
    -- an admin are spaced further apart than that.
    if State.LastSystemToken == token and (now - State.LastSystemTokenAt) < 2.0 then
        return  -- silent drop
    end
    State.LastSystemToken   = token
    State.LastSystemTokenAt = now

    local isSystemSrc = (source == "screen" or source == "announcement")

    -- Source locking: reset buffer on timeout or if a different non-system speaker injects.
    -- Screen + announcement are one unified system source so they freely share the buffer.
    local prevSys    = (State.LastPartSource == "screen" or State.LastPartSource == "announcement")
    local sameSource = (State.LastPartSource == nil)
                    or (source == State.LastPartSource)
                    or (isSystemSrc and prevSys)

    if (now - State.LastPartAt > 20) or not sameSource then
        State.Parts          = {}
        State.LastPartSource = nil
    end

    State.LastPartAt     = now
    State.LastPartSource = source
    table.insert(State.Parts, token)
    local combined = table.concat(State.Parts)
    CodeBox.Text = combined

    -- Paste partial code into the GAME's input box immediately on every word detected,
    -- not just when all parts are collected. Box is already primed when submit fires.
    pcall(function()
        local gameBox = findCodeBox()
        if gameBox then gameBox.Text = combined end
    end)

    log("part " .. #State.Parts .. "/" .. CONFIG.SubmitAfter .. " from " .. source .. ": " .. token, THEME.NeonSoft)

    -- Bug 3 fix: paste the partial (or full) code into the game's input box THE MOMENT
    -- each word lands, not just at final submit. Uses task.spawn + brief retry so a
    -- temporarily-closed code UI doesn't silently swallow the paste.
    local partialCode = combined
    task.spawn(function()
        local deadline = os.clock() + 1.5  -- try for 1.5s to find the box
        while os.clock() < deadline do
            local gameBox = findCodeBox()
            if gameBox then
                pcall(function() gameBox.Text = partialCode end)
                break
            end
            task.wait(0.08)
        end
    end)

    if #State.Parts >= CONFIG.SubmitAfter then
        State.Parts          = {}
        State.LastPartSource = nil
        setclip(combined)
        log("combined code: " .. combined, THEME.Success)
        if CONFIG.AutoSubmit then
            submitCode(combined, source)
        end
    end
end

local chatHookConfirmed = false
local seenChatMsg = {}   -- dedup: prevents TextChatService + legacy + GUI watcher all firing onChat for the same msg
local function onChat(speakerName, message)
    if not State.Enabled then return end
    if not chatHookConfirmed then
        chatHookConfirmed = true
        log("chat hook active (heard " .. speakerName .. ")", THEME.NeonSoft)
    end
    if speakerName == LocalPlayer.Name and not CONFIG.TrackSelf then return end
    -- Deduplicate across multiple listener paths: TextChatService, legacy chat, GUI watcher
    -- all independently call onChat for the same message; only let the first one through.
    local chatKey = speakerName:lower() .. "\0" .. message:lower()
    if seenChatMsg[chatKey] then return end
    seenChatMsg[chatKey] = true
    task.delay(1.5, function() seenChatMsg[chatKey] = nil end)

    -- riddle solver: check every message for a known riddle
    if CONFIG.RiddleSolver then
        local answer = solveRiddle(message)
        if answer then
            log("riddle detected from " .. speakerName .. " -> answer: " .. answer, THEME.NeonSoft)
            setclip(answer)
            if CONFIG.AutoSubmit then
                submitCode(answer, speakerName .. " (riddle)")
            else
                CodeBox.Text = answer
            end
            return
        end
    end

    local allowed = isWatched(speakerName) or (speakerName == LocalPlayer.Name and CONFIG.TrackSelf)

    -- multi-part codes: admins split a code over several one-word messages
    -- ("code is" -> "vor" -> "nyx"). collect SubmitAfter parts, then submit.
    -- FIX: use isWatchedExplicit here instead of `allowed`.
    -- `allowed` is true for EVERYONE when TrackEveryone=true, which lets random players
    -- like "11" send "48" "49" "50" and corrupt the buffer.
    -- Multi-part collection must be locked to names in WatchedNames only.
    local token = message:match("^%s*([%w_%-]+)%s*$")
    local isExplicit = isWatchedExplicit(speakerName) or (speakerName == LocalPlayer.Name and CONFIG.TrackSelf)
    -- Was `> 1` which silently dropped single-word messages when SubmitAfter=1.
    -- Changed to `>= 1` so all single-word messages from watched names go through
    -- handleToken, which collects them and auto-submits once SubmitAfter parts land.
    if token and isExplicit and CONFIG.SubmitAfter >= 1 then
        handleToken(token, speakerName)
        return
    end

    -- code sniping from watched admins
    local code = extractCode(message)
    if code then
        if allowed then
            if code ~= State.LastCode then
                log("code from " .. speakerName .. ": " .. code, THEME.Success)
                setclip(code)
                CodeBox.Text = code
                if CONFIG.AutoSubmit then
                    submitCode(code, speakerName)
                end
            end
        else
            log("ignored code from " .. speakerName .. " (not watched - turn on Track everyone)", THEME.TextDim)
        end
    end
end

-- new TextChatService
pcall(function()
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        local source = textChatMessage.TextSource
        if source then
            local player = Players:GetPlayerByUserId(source.UserId)
            local name = player and player.Name or tostring(source.Name)
            onChat(name, textChatMessage.Text)
        end
    end)
end)

-- legacy chat
pcall(function()
    local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if events then
        local onMessage = events:FindFirstChild("OnMessageDoneFiltering")
        if onMessage then
            onMessage.OnClientEvent:Connect(function(data)
                if data and data.FromSpeaker and data.Message then
                    onChat(data.FromSpeaker, data.Message)
                end
            end)
        end
    end
end)

-- fallback: player.Chatted (works in some games)
pcall(function()
    local function hook(player)
        player.Chatted:Connect(function(msg)
            onChat(player.Name, msg)
        end)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then hook(player) end
    end
    Players.PlayerAdded:Connect(hook)
end)

-------------------------------------------------
-- Custom / global chat GUI watcher
-- Some games render their own "live chat" in the
-- GUI instead of using Roblox chat. This reads any
-- new "name: message" label that appears on screen.
-------------------------------------------------
pcall(function()
    local function stripRichText(text)
        return (text:gsub("<[^>]->", ""))
    end

    local seenGuiMsgs = {}
    local function parseChatLabel(text)
        text = stripRichText(text)
        -- match "name: message" (also "[name]: message" / "name] message")
        local name, msg = text:match("^%s*%[?([%w_]+)%]?%s*[:%]]%s*(.+)$")
        if name and msg and #msg > 0 then
            return name, msg
        end
        return nil
    end

    -- big on-screen announcement words ("CODES" "ARE" "VORNYX"...)
    -- each giant label is one part of the code; feed it into the combiner.
    local seenAnnounceWords = {}
    local function announceToken(text)
        text = stripRichText(text)
        local token = text:match("^[^%w]*([%w_%-]+)[^%w]*$")
        if not token or #token < 2 then return end
        if seenAnnounceWords[token] then return end
        seenAnnounceWords[token] = true
        task.delay(1.25, function() seenAnnounceWords[token] = nil end)
        handleToken(token, "screen")
    end

    local function handleLabel(obj, isNew)
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
        if isOurGui(obj) then return end
        local pending = 0
        local function process()
            local text = obj.Text
            if not text or text == "" then return end
            local name, msg = parseChatLabel(text)
            if name then
                local key = name .. "\0" .. msg
                if seenGuiMsgs[key] then return end
                seenGuiMsgs[key] = true
                task.delay(5, function() seenGuiMsgs[key] = nil end)
                onChat(name, msg)
                return
            end
            -- announcement words: only labels that appeared after startup,
            -- rendered big on screen. debounce so typewriter animations
            -- only produce the final word.
            if isNew and obj:IsA("TextLabel") then
                pending = pending + 1
                local my = pending
                task.delay(0.4, function()
                    if my ~= pending then return end
                    if not obj.Parent or not obj.Visible then return end
                    local h = obj.AbsoluteSize.Y
                    if h < 35 then return end
                    pcall(announceToken, obj.Text)
                end)
            end
        end
        process()
        obj:GetPropertyChangedSignal("Text"):Connect(process)
    end

    PlayerGui.DescendantAdded:Connect(function(obj)
        task.wait(0.04)
        pcall(handleLabel, obj, true)
    end)
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        pcall(handleLabel, obj, false)
    end
    log("GUI chat + screen announcement watcher active", THEME.TextDim)
end)

-------------------------------------------------
-- Announcement sniping (Steal a Brainrot style)
-- Admin codes come through the game's notification
-- remote, not the chat - this listens to it directly.
-------------------------------------------------
local NOTIF_POSITIONS = {
    Top = true, Bottom = true, Center = true, Middle = true,
    Left = true, Right = true, TopRight = true, TopLeft = true,
    BottomRight = true, BottomLeft = true,
}

local function remotesFromFunction(fn)
    if not getupvals then return {} end
    local remotes = {}
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    local net = packages and packages:FindFirstChild("Net")
    local ok, values = pcall(getupvals, fn)
    if ok and type(values) == "table" then
        for _, value in pairs(values) do
            if typeof(value) == "Instance"
            and (value:IsA("RemoteEvent")
                or value:IsA("RemoteFunction")
                or value:IsA("UnreliableRemoteEvent"))
            and net and value.Parent == net then
                table.insert(remotes, value)
            end
        end
    end
    return remotes
end

local function resolveNotifyRemote()
    local module = nil
    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
    if controllers then
        module = controllers:FindFirstChild("NotificationController", true)
    end
    if not module then
        module = ReplicatedStorage:FindFirstChild("NotificationController", true)
    end
    if module and module:IsA("ModuleScript") then
        local ok, controller = pcall(require, module)
        if ok and type(controller) == "table" and type(controller.Start) == "function" then
            local remote = remotesFromFunction(controller.Start)[1]
            if remote then return remote end
        end
    end
    return nil
end

local function isAnnouncement(...)
    local args = table.pack(...)
    if args.n == 0 or typeof(args[1]) ~= "string" then return false end
    for index = 2, args.n do
        local value = args[index]
        if typeof(value) == "string"
        and (value:find("Sounds%.")
            or value:find("rbxassetid")
            or NOTIF_POSITIONS[value]) then
            return true
        end
    end
    return false
end

local function stripRich(text)
    if type(text) ~= "string" then return tostring(text) end
    return (text:gsub("<[^>]->", ""))
end

local seenAnnounced = {}
local function onAnnouncement(...)
    if not State.Enabled then return end
    local text = stripRich(tostring((...) or ""))
    text = text:match("^%s*(.-)%s*$") or ""
    if text == "" then return end
    -- announcements with spaces are normal sentences, not codes
    if text:find("%s") then return end
    local code = text:match("[%w_%-]+")
    if not code or code == "" or seenAnnounced[code] then return end
    seenAnnounced[code] = true
    task.delay(1.25, function() seenAnnounced[code] = nil end)
    handleToken(code, "announcement")
end

pcall(function()
    local notifyRemote = resolveNotifyRemote()
    if notifyRemote then
        notifyRemote.OnClientEvent:Connect(function(...)
            if isAnnouncement(...) then
                pcall(onAnnouncement, ...)
            end
        end)
        log("announcement sniper hooked: " .. notifyRemote.Name, THEME.NeonSoft)
        return
    end

    -- fallback: listen to every RemoteEvent in the game and filter
    -- for announcement-style payloads
    local hookedCount = 0
    local hookedRemotes = {}
    local function hookRemote(obj)
        if hookedRemotes[obj] then return end
        if obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") then
            hookedRemotes[obj] = true
            hookedCount += 1
            obj.OnClientEvent:Connect(function(...)
                if isAnnouncement(...) then
                    pcall(onAnnouncement, ...)
                end
            end)
        end
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        pcall(hookRemote, obj)
    end
    ReplicatedStorage.DescendantAdded:Connect(function(obj)
        pcall(hookRemote, obj)
    end)
    log("announcement sniper: listening on " .. hookedCount .. " remotes", THEME.NeonSoft)
end)

-------------------------------------------------
-- Toggle UI keybind
-------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CONFIG.ToggleKey then
        Main.Visible = not Main.Visible
        if not Main.Visible then
            HistoryFrame.Visible = false
        end
    end
end)

log("Vornyx loaded - watching chat for codes", THEME.Neon)
log("watching: " .. table.concat(CONFIG.WatchedNames, ", "), THEME.TextDim)

end -- loadMain

-------------------------------------------------
-- KEY SYSTEM
-- 10,000 keys live in keys.json on GitHub.
-- blacklist.json is checked every launch, so a
-- leaked key can be killed by adding it there.
-------------------------------------------------
local HttpService = game:GetService("HttpService")

local function fetchList(url)
    local ok, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if ok and type(result) == "table" then
        return result
    end
    return nil
end

local function isBlacklisted(key)
    local list = fetchList(CONFIG.BlacklistURL)
    if list then
        for _, k in ipairs(list) do
            if k == key then return true end
        end
    end
    return false
end

local function isValidKey(key)
    if not key or key == "" then return false end
    if isBlacklisted(key) then return false end
    if key == CONFIG.OwnerKey then return true end
    local keys = fetchList(CONFIG.KeysURL)
    if keys then
        for _, k in ipairs(keys) do
            if k == key then return true end
        end
    end
    return false
end

local function saveKey(key)
    pcall(function()
        if writefile then writefile(CONFIG.KeyFile, key) end
    end)
end

local function loadSavedKey()
    local key
    pcall(function()
        if isfile and readfile and isfile(CONFIG.KeyFile) then
            key = readfile(CONFIG.KeyFile)
        end
    end)
    return key
end

local function showKeyGui()
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "VornyxKeySystem"
    KeyGui.ResetOnSpawn = false
    safeParent(KeyGui)

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 340, 0, 230)
    Frame.Position = UDim2.new(0.5, -170, 0.5, -115)
    Frame.BackgroundColor3 = THEME.Background
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = KeyGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = Frame
    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = THEME.Neon
    frameStroke.Thickness = 2
    frameStroke.Transparency = 0.1
    frameStroke.Parent = Frame

    local KTitle = Instance.new("TextLabel")
    KTitle.Size = UDim2.new(1, -20, 0, 34)
    KTitle.Position = UDim2.new(0, 10, 0, 10)
    KTitle.BackgroundTransparency = 1
    KTitle.Font = Enum.Font.GothamBold
    KTitle.TextSize = 18
    KTitle.TextColor3 = THEME.Neon
    KTitle.Text = CONFIG.ScriptName
    KTitle.Parent = Frame

    local KSub = Instance.new("TextLabel")
    KSub.Size = UDim2.new(1, -20, 0, 20)
    KSub.Position = UDim2.new(0, 10, 0, 42)
    KSub.BackgroundTransparency = 1
    KSub.Font = Enum.Font.Gotham
    KSub.TextSize = 13
    KSub.TextColor3 = THEME.TextDim
    KSub.Text = "Activation required - enter your key"
    KSub.Parent = Frame

    local KInput = Instance.new("TextBox")
    KInput.Size = UDim2.new(1, -40, 0, 38)
    KInput.Position = UDim2.new(0, 20, 0, 72)
    KInput.BackgroundColor3 = THEME.PanelDark
    KInput.Font = Enum.Font.Code
    KInput.TextSize = 15
    KInput.TextColor3 = THEME.Text
    KInput.PlaceholderText = "Enter your key here..."
    KInput.PlaceholderColor3 = THEME.TextDim
    KInput.Text = ""
    KInput.ClearTextOnFocus = false
    KInput.Parent = Frame
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 10)
    inputCorner.Parent = KInput
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = THEME.Neon
    inputStroke.Thickness = 1.5
    inputStroke.Transparency = 0.3
    inputStroke.Parent = KInput

    local function keyButton(x, w, text, filled)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, w, 0, 36)
        b.Position = UDim2.new(0, x, 0, 124)
        b.BackgroundColor3 = filled and THEME.Neon or THEME.Panel
        b.Font = Enum.Font.GothamBold
        b.TextSize = 14
        b.TextColor3 = filled and Color3.new(1, 1, 1) or THEME.NeonSoft
        b.Text = text
        b.AutoButtonColor = false
        b.Parent = Frame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 10)
        c.Parent = b
        if not filled then
            local s = Instance.new("UIStroke")
            s.Color = THEME.NeonDim
            s.Thickness = 1.5
            s.Transparency = 0.3
            s.Parent = b
        end
        return b
    end

    local DiscordBtn = keyButton(20, 145, "Copy Discord", false)
    local NextBtn    = keyButton(175, 145, "Next", true)

    local KStatus = Instance.new("TextLabel")
    KStatus.Size = UDim2.new(1, -40, 0, 40)
    KStatus.Position = UDim2.new(0, 20, 0, 172)
    KStatus.BackgroundTransparency = 1
    KStatus.Font = Enum.Font.Gotham
    KStatus.TextSize = 13
    KStatus.TextColor3 = THEME.TextDim
    KStatus.TextWrapped = true
    KStatus.Text = "Need a key? Join our Discord!"
    KStatus.Parent = Frame

    DiscordBtn.MouseButton1Click:Connect(function()
        setclip(CONFIG.DiscordLink)
        DiscordBtn.Text = "Copied!"
        task.delay(1.5, function() DiscordBtn.Text = "Copy Discord" end)
    end)

    local checking = false
    NextBtn.MouseButton1Click:Connect(function()
        if checking then return end
        checking = true
        local enteredKey = KInput.Text:gsub("%s+", "")
        KStatus.Text = "Checking key..."
        KStatus.TextColor3 = THEME.NeonSoft
        task.spawn(function()
            if isValidKey(enteredKey) then
                saveKey(enteredKey) -- remembered: it won't ask again
                KeyGui:Destroy()
                loadMain()
            else
                KInput.Text = ""
                KStatus.Text = "INVALID OR BLACKLISTED KEY!"
                KStatus.TextColor3 = THEME.Fail
            end
            checking = false
        end)
    end)
end

-------------------------------------------------
-- ENTRY: saved key skips the popup entirely
-------------------------------------------------
task.spawn(function()
    local saved = loadSavedKey()
    if saved and saved ~= "" and isValidKey(saved) then
        loadMain()
    else
        pcall(function()
            if delfile and isfile and isfile(CONFIG.KeyFile) then
                delfile(CONFIG.KeyFile)
            end
        end)
        showKeyGui()
    end
end)
