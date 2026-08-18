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
    -- if true, codes from ANY player are grabbed. if false, only WatchedNames
    TrackEveryone = false,
    SubmitDelay   = 0,      -- seconds to wait before auto submit (0 = instant)
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
    History     = {},   -- { {code = "ABC", from = "sammy", time = "12:00"} , ... }
    LastCode    = nil,
    Submitting  = false,
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
local function findCodeBox()
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextBox") then
            local hint = (obj.PlaceholderText or ""):lower() .. " " .. obj.Name:lower()
            if hint:find("code") or hint:find("enter") then
                return obj
            end
        end
    end
    return nil
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
Main.Size = UDim2.new(0, 420, 0, 562)
Main.Position = UDim2.new(0.5, -210, 0.5, -281)
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

-- Status bar ("Scanning...")
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -40, 0, 38)
Status.Position = UDim2.new(0, 20, 0, 102)
Status.BackgroundColor3 = THEME.Panel
Status.Font = Enum.Font.GothamBold
Status.TextSize = 17
Status.TextColor3 = THEME.Text
Status.Text = "Scanning..."
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

-- Row 2: Retype invalid | Submit after
local p3 = makePanel(20, 206, 185, 46)
makeToggle(p3, "Retype invalid", CONFIG.RetypeInvalid, function(v) CONFIG.RetypeInvalid = v end)

-- Row 3: Auto paste | History
local p5 = makePanel(20, 260, 185, 46)
makeToggle(p5, "Auto paste", CONFIG.AutoPaste, function(v) CONFIG.AutoPaste = v end)

local p6 = makePanel(215, 260, 185, 46)
local HistoryToggle = makeToggle(p6, "History", false, function(v)
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
    label.Text = "Submit after"
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
    num.Text = tostring(CONFIG.SubmitDelay)
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
        CONFIG.SubmitDelay = math.max(0, CONFIG.SubmitDelay - 1)
        num.Text = tostring(CONFIG.SubmitDelay)
    end)
    plus.MouseButton1Click:Connect(function()
        CONFIG.SubmitDelay = math.min(30, CONFIG.SubmitDelay + 1)
        num.Text = tostring(CONFIG.SubmitDelay)
    end)
end

-------------------------------------------------
-- Code input + Paste + Submit + History
-------------------------------------------------
local CodeBox = Instance.new("TextBox")
CodeBox.Size = UDim2.new(1, -40, 0, 38)
CodeBox.Position = UDim2.new(0, 20, 0, 316)
CodeBox.BackgroundColor3 = THEME.PanelDark
CodeBox.Font = Enum.Font.Code
CodeBox.TextSize = 16
CodeBox.TextColor3 = THEME.Text
CodeBox.PlaceholderText = "enter / paste code here..."
CodeBox.PlaceholderColor3 = THEME.TextDim
CodeBox.Text = ""
CodeBox.ClearTextOnFocus = false
CodeBox.Parent = Main
round(CodeBox, 10)
stroke(CodeBox, THEME.Neon, 1.5, 0.3)

-------------------------------------------------
-- Log console
-------------------------------------------------
local Console = Instance.new("ScrollingFrame")
Console.Size = UDim2.new(1, -40, 0, 180)
Console.Position = UDim2.new(0, 20, 0, 362)
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
    Status.Text = text
    Status.TextColor3 = color or THEME.Text
end

local function submitCode(code, source)
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

        local gameBox = findCodeBox()
        local submitted = false

        if gameBox then
            -- extra fast: set text directly then fire the submit button
            pcall(function()
                gameBox.Text = code
                gameBox:CaptureFocus()
                task.wait()
                gameBox.Text = code
                gameBox:ReleaseFocus(true) -- enter pressed
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
        else
            log("code UI not found - copied '" .. code .. "' to clipboard", THEME.Fail)
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
        if CONFIG.AutoPaste then
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

local function onChat(speakerName, message)
    if speakerName == LocalPlayer.Name then return end

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

    -- code sniping from watched admins
    if isWatched(speakerName) then
        local code = extractCode(message)
        if code and code ~= State.LastCode then
            log("code from " .. speakerName .. ": " .. code, THEME.Success)
            setclip(code)
            CodeBox.Text = code
            if CONFIG.AutoSubmit then
                submitCode(code, speakerName)
            end
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
