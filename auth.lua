-- [[ Apex - Code Sniper: Official Save-Key & Cloud System ]] --
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KeyDatabaseURL = "https://githubusercontent.com"
local SaveFileName = "ApexSniper_Key.txt" 
local MyDiscordLink = "https://discord.gg"
local AdminMasterKey = "APEX-ADMIN-OVERRIDE" -- Jouw Admin Code

-- Functie om de online keys te controleren
local function checkKeyOnline(userKey)
    if userKey == AdminMasterKey then return true end
    local success, response = pcall(function()
        return game:HttpGet(KeyDatabaseURL)
    end)
    if success then
        local validKeys = HttpService:JSONDecode(response)
        for _, k in pairs(validKeys) do
            if k == userKey then
                return true
            end
        end
    end
    return false
end

-- =========================================================================
-- HET HOOFDMENU (APEX - CODE SNIPER)
-- =========================================================================
local function loadMainScript()
    print("[Apex] Welkom terug! Licentie actief.")
    
    local CodeRemote = ReplicatedStorage:WaitForChild("RedeemCodeEvent") 
    local isCollecting = false
    local fullCode = ""
    local wordCounter = 0
    local targetWords = 3 

    local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 320, 0, 260)
    MainFrame.Position = UDim2.new(0.4, 0, 0.35, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(5, 15, 25)
    MainFrame.Active = true
    MainFrame.Draggable = true

    local MainCorner = Instance.new("UICorner", MainFrame)
    MainCorner.CornerRadius = UDim.new(0, 10)

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Color3.fromRGB(0, 220, 200) 
    MainStroke.Thickness = 2

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Text = "Apex - Code Sniper"
    Title.TextColor3 = Color3.fromRGB(0, 255, 220)
    Title.BackgroundColor3 = Color3.fromRGB(10, 35, 50)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    local TitleCorner = Instance.new("UICorner", Title)
    TitleCorner.CornerRadius = UDim.new(0, 10)

    local DiscordBox = Instance.new("TextLabel", MainFrame)
    DiscordBox.Size = UDim2.new(0, 290, 0, 25)
    DiscordBox.Position = UDim2.new(0, 15, 0, 48)
    DiscordBox.Text = MyDiscordLink
    DiscordBox.TextColor3 = Color3.fromRGB(200, 240, 245)
    DiscordBox.BackgroundColor3 = Color3.fromRGB(15, 45, 65)
    DiscordBox.Font = Enum.Font.SourceSans
    DiscordBox.TextSize = 13
    local DiscordCorner = Instance.new("UICorner", DiscordBox)
    DiscordCorner.CornerRadius = UDim.new(0, 6)

    local StatusLabel = Instance.new("TextLabel", MainFrame)
    StatusLabel.Size = UDim2.new(1, 0, 0, 30)
    StatusLabel.Position = UDim2.new(0, 0, 0, 82)
    StatusLabel.Text = "Scanning..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.SourceSansBold
    StatusLabel.TextSize = 18

    local StepperLabel = Instance.new("TextLabel", MainFrame)
    StepperLabel.Size = UDim2.new(0, 150, 0, 30)
    StepperLabel.Position = UDim2.new(0, 20, 0, 120)
    StepperLabel.Text = "Submit after words:"
    StepperLabel.TextColor3 = Color3.fromRGB(220, 240, 240)
    StepperLabel.BackgroundTransparency = 1
    StepperLabel.TextXAlignment = Enum.TextXAlignment.Left
    StepperLabel.Font = Enum.Font.SourceSans
    StepperLabel.TextSize = 15

    local StepperFrame = Instance.new("Frame", MainFrame)
    StepperFrame.Size = UDim2.new(0, 110, 0, 30)
    StepperFrame.Position = UDim2.new(0, 190, 0, 120)
    StepperFrame.BackgroundColor3 = Color3.fromRGB(15, 45, 65)
    local StepCorner = Instance.new("UICorner", StepperFrame)
    StepCorner.CornerRadius = UDim.new(0, 6)

    local MinusBtn = Instance.new("TextButton", StepperFrame)
    MinusBtn.Size = UDim2.new(0, 30, 1, 0)
    MinusBtn.Position = UDim2.new(0, 0, 0, 0)
    MinusBtn.Text = "-"
    MinusBtn.TextColor3 = Color3.fromRGB(0, 255, 220)
    MinusBtn.BackgroundTransparency = 1
    MinusBtn.Font = Enum.Font.SourceSansBold
    MinusBtn.TextSize = 18

    local NumberDisplay = Instance.new("TextLabel", StepperFrame)
    NumberDisplay.Size = UDim2.new(0, 50, 1, 0)
    NumberDisplay.Position = UDim2.new(0, 30, 0, 0)
    NumberDisplay.Text = tostring(targetWords)
    NumberDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
    NumberDisplay.BackgroundTransparency = 1
    NumberDisplay.Font = Enum.Font.SourceSansBold
    NumberDisplay.TextSize = 16

    local PlusBtn = Instance.new("TextButton", StepperFrame)
    PlusBtn.Size = UDim2.new(0, 30, 1, 0)
    PlusBtn.Position = UDim2.new(0, 80, 0, 0)
    PlusBtn.Text = "+"
    PlusBtn.TextColor3 = Color3.fromRGB(0, 255, 220)
    PlusBtn.BackgroundTransparency = 1
    PlusBtn.Font = Enum.Font.SourceSansBold
    PlusBtn.TextSize = 18

    local LogBox = Instance.new("TextLabel", MainFrame)
    LogBox.Size = UDim2.new(0, 290, 0, 75)
    LogBox.Position = UDim2.new(0, 15, 0, 165)
    LogBox.Text = "> scanning for codes...\n[setting] Target -> " .. targetWords .. " words"
    LogBox.TextColor3 = Color3.fromRGB(0, 255, 200)
    LogBox.BackgroundColor3 = Color3.fromRGB(5, 10, 20)
    LogBox.TextXAlignment = Enum.TextXAlignment.Left
    LogBox.TextYAlignment = Enum.TextYAlignment.Top
    LogBox.Font = Enum.Font.Code
    LogBox.TextSize = 13
    local LogCorner = Instance.new("UICorner", LogBox)
    LogCorner.CornerRadius = UDim.new(0, 6)
    local LogPadding = Instance.new("UIPadding", LogBox)
    LogPadding.PaddingLeft = UDim.new(0, 8)
    LogPadding.PaddingTop = UDim.new(0, 6)

    MinusBtn.MouseButton1Click:Connect(function()
        if targetWords > 1 then
            targetWords = targetWords - 1
            NumberDisplay.Text = tostring(targetWords)
            LogBox.Text = "> scanning for codes...\n[setting] Target updated -> " .. targetWords .. " words"
        end
    end)

    PlusBtn.MouseButton1Click:Connect(function()
        if targetWords < 5 then
            targetWords = targetWords + 1
            NumberDisplay.Text = tostring(targetWords)
            LogBox.Text = "> scanning for codes...\n[setting] Target updated -> " .. targetWords .. " words"
        end
    end)
    local function instantSpamRedeem(codeToSubmit)
        StatusLabel.Text = "REDEEMING!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
        LogBox.Text = "> Target reached! Executing 10x packet spam..."

        for i = 1, 10 do
            task.spawn(function()
                pcall(function()
                    if CodeRemote:IsA("RemoteEvent") then
                        CodeRemote:FireServer(codeToSubmit)
                    elseif CodeRemote:IsA("RemoteFunction") then
                        CodeRemote:InvokeServer(codeToSubmit)
                    end
                end)
            end)
        end

        StatusLabel.Text = "REDEEMED!"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        LogBox.Text = "> [SUCCESS] Code forced through bypass:\n> " .. codeToSubmit

        task.wait(4)
        fullCode = ""
        wordCounter = 0
        isCollecting = false
        StatusLabel.Text = "Scanning..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        LogBox.Text = "> scanning for codes...\n[setting] Ready for next event."
    end

    TextChatService.MessageReceived:Connect(function(textChatMessage)
        local message = textChatMessage.Text
        local lowerMessage = string.lower(message)
        
        if string.find(lowerMessage, "code is") then
            isCollecting = true
            fullCode = "" 
            wordCounter = 0
            StatusLabel.Text = "SNIPING (".. wordCounter .."/".. targetWords ..")"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            LogBox.Text = "> Trigger recognized!\n> Gathering " .. targetWords .. " words..."
            return
        end
        
        if isCollecting then
            if not string.find(message, " ") and #message > 0 then
                fullCode = fullCode .. message
                wordCounter = wordCounter + 1
                
                StatusLabel.Text = "SNIPING (".. wordCounter .."/".. targetWords ..")"
                LogBox.Text = "> Part " .. wordCounter .. " caught: " .. message .. "\n> Current string: " .. fullCode
                
                if wordCounter >= targetWords then
                    isCollecting = false
                    instantSpamRedeem(fullCode)
                end
            end
        end
    end)
end

if isfile(SaveFileName) then
    local savedKey = readfile(SaveFileName)
    if checkKeyOnline(savedKey) then
        loadMainScript()
        return
    else
        delfile(SaveFileName)
    end
end

local KeyGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local KeyFrame = Instance.new("Frame", KeyGui)
KeyFrame.Size = UDim2.new(0, 320, 0, 240)
KeyFrame.Position = UDim2.new(0.4, 0, 0.35, 0)
KeyFrame.BackgroundColor3 = Color3.fromRGB(5, 15, 25)
KeyFrame.Active = true
KeyFrame.Draggable = true

local KeyCorner = Instance.new("UICorner", KeyFrame)
KeyCorner.CornerRadius = UDim.new(0, 10)
local KeyStroke = Instance.new("UIStroke", KeyFrame)
KeyStroke.Color = Color3.fromRGB(0, 220, 200)
KeyStroke.Thickness = 2

local Layout = Instance.new("UIListLayout", KeyFrame)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 10)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local Padding = Instance.new("UIPadding", KeyFrame)
Padding.PaddingTop = UDim.new(0, 10)

local KeyTitle = Instance.new("TextLabel", KeyFrame)
KeyTitle.Size = UDim2.new(0, 290, 0, 35)
KeyTitle.LayoutOrder = 1
KeyTitle.Text = "Apex Sniper - Activation Required"
KeyTitle.TextColor3 = Color3.fromRGB(0, 255, 220)
KeyTitle.BackgroundColor3 = Color3.fromRGB(10, 35, 50)
KeyTitle.Font = Enum.Font.SourceSansBold
KeyTitle.TextSize = 16
local KeyTitleCorner = Instance.new("UICorner", KeyTitle)
KeyTitleCorner.CornerRadius = UDim.new(0, 6)

local KeyInput = Instance.new("TextBox", KeyFrame)
KeyInput.Size = UDim2.new(0, 290, 0, 35)
KeyInput.LayoutOrder = 2
KeyInput.PlaceholderText = "Enter your key here..."
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.BackgroundColor3 = Color3.fromRGB(15, 45, 65)
local InputCorner = Instance.new("UICorner", KeyInput)
InputCorner.CornerRadius = UDim.new(0, 6)

local ButtonContainer = Instance.new("Frame", KeyFrame)
ButtonContainer.Size = UDim2.new(0, 290, 0, 35)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.LayoutOrder = 3

local ButtonLayout = Instance.new("UIListLayout", ButtonContainer)
ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder
ButtonLayout.Padding = UDim.new(0, 10)

local NextBtn = Instance.new("TextButton", ButtonContainer)
NextBtn.Size = UDim2.new(0, 140, 1, 0)
NextBtn.LayoutOrder = 1
NextBtn.Text = "Next"
NextBtn.TextColor3 = Color3.fromRGB(5, 15, 25)
NextBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 220)
NextBtn.Font = Enum.Font.SourceSansBold
NextBtn.TextSize = 16
local NextCorner = Instance.new("UICorner", NextBtn)
NextCorner.CornerRadius = UDim.new(0, 6)

local CopyBtn = Instance.new("TextButton", ButtonContainer)
CopyBtn.Size = UDim2.new(0, 140, 1, 0)
CopyBtn.LayoutOrder = 2
CopyBtn.Text = "Copy Discord"
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.BackgroundColor3 = Color3.fromRGB(15, 45, 65)
CopyBtn.Font = Enum.Font.SourceSansBold
CopyBtn.TextSize = 15
local CopyCorner = Instance.new("UICorner", CopyBtn)
CopyCorner.CornerRadius = UDim.new(0, 6)
local CopyStroke = Instance.new("UIStroke", CopyBtn)
CopyStroke.Color = Color3.fromRGB(0, 220, 200)

local DiscordLinkText = Instance.new("TextLabel", KeyFrame)
DiscordLinkText.Size = UDim2.new(0, 290, 0, 25)
DiscordLinkText.LayoutOrder = 4
DiscordLinkText.Text = "Need a key? Join Tyler & Tym's rewards!"
DiscordLinkText.TextColor3 = Color3.fromRGB(130, 200, 220)
DiscordLinkText.BackgroundTransparency = 1
DiscordLinkText.Font = Enum.Font.SourceSansItalic
DiscordLinkText.TextSize = 14

NextBtn.MouseButton1Click:Connect(function()
    local enteredKey = KeyInput.Text
    if enteredKey == AdminMasterKey or checkKeyOnline(enteredKey) then
        writefile(SaveFileName, enteredKey)
        KeyGui:Destroy()
        loadMainScript()
    else
        KeyInput.Text = ""
        KeyInput.PlaceholderText = "INVALID OR BLACKLISTED KEY!"
    end
end)

CopyBtn.MouseButton1Click:Connect(function()
    setclipboard(MyDiscordLink) 
    CopyBtn.Text = "Copied! ✅"
    task.wait(2)
    CopyBtn.Text = "Copy Discord"
end)
