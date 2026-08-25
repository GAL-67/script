local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local FILE_NAME = "wh.txt"

-- Mapping Rarity untuk Placed Pet
local PET_RARITY_MAP = {
    ["Unicorn"] = "DIVINE",
    ["Mosasaurus"] = "ETERNAL", ["Oni Tiger"] = "ETERNAL", ["Ice Dragon"] = "ETERNAL", ["Eternal Lunar Dragon"] = "ETERNAL",
    ["Phoenix"] = "ETERNAL", ["El Maja"] = "ETERNAL", ["Lava Dragon"] = "ETERNAL",
    ["Tralaledon"] = "SECRET", ["Stag"] = "SECRET", ["TRex"] = "SECRET", ["Cosmic Skeleton"] = "SECRET",
    ["Cosmic Dragon"] = "SECRET", ["Cerberus"] = "SECRET", ["Yeti Kraken"] = "SECRET"
}

local ALLOWED_RARITIES = { ["Divine"] = "DIVINE", ["Eternal"] = "ETERNAL", ["Secret"] = "SECRET" }
local RARITY_ORDER = {"DIVINE", "ETERNAL", "SECRET"}

-- Helper File System (Sanitasi String)
local function getSavedWebhook()
    if isfile and isfile(FILE_NAME) then
        local content = readfile(FILE_NAME)
        if content then
            content = content:gsub("[%s\r\n\t]", "")
            if #content > 10 and string.sub(content, 1, 4) == "http" then
                return content
            end
        end
    end
    return nil
end

local function saveWebhook(url)
    if writefile then
        local cleanUrl = url:gsub("[%s\r\n\t]", "")
        writefile(FILE_NAME, cleanUrl)
    end
end

-- Formatting Helper
local function formatNumber(n)
    if not n or type(n) ~= "number" then return "0" end
    local suffixes = {"", "K", "M", "B", "T", "Qd"}
    local i = 1
    while n >= 1000 and i < #suffixes do
        n = n / 1000
        i = i + 1
    end
    return i == 1 and string.format("%.0f", n) or string.format("%.1f%s", n, suffixes[i])
end

local function parseFormattedRate(rateStr)
    if not rateStr then return 0 end
    rateStr = string.upper(rateStr)
    local num = tonumber(string.match(rateStr, "[%d%.]+")) or 0
    if string.find(rateStr, "QD") then num = num * 1e15
    elseif string.find(rateStr, "T") then num = num * 1e12
    elseif string.find(rateStr, "B") then num = num * 1e9
    elseif string.find(rateStr, "M") then num = num * 1e6
    elseif string.find(rateStr, "K") then num = num * 1e3
    end
    return num
end

-- Helper Ambil Leaderstats "Money/s"
local function getLeaderstatsMoneyPerSecond()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local moneyPerSec = leaderstats:FindFirstChild("Money/s") or leaderstats:FindFirstChild("Money/sec") or leaderstats:FindFirstChild("Money / s")
        if moneyPerSec then
            return tonumber(moneyPerSec.Value) or 0
        end
    end
    return 0
end

-- Scraping Data Inventory & Sorting (Highest to Lowest Income)
local function getInventoryData()
    local categorized = { ["DIVINE"] = {}, ["ETERNAL"] = {}, ["SECRET"] = {} }
    local totalIncome, itemCount = 0, 0
    local containers = {LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character}

    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                local config = item:FindFirstChild("Configuration")
                if config then
                    local rarity = config:GetAttribute("rarity")
                    local categoryKey = ALLOWED_RARITIES[rarity]

                    if categoryKey then
                        local perSecond = tonumber(config:GetAttribute("perSecond")) or 0
                        local mutation = config:GetAttribute("mutation")

                        totalIncome = totalIncome + perSecond
                        itemCount = itemCount + 1

                        local itemLine = string.format("%s • %s/s", item.Name, formatNumber(perSecond))
                        if mutation and tostring(mutation) ~= "" then
                            itemLine = itemLine .. string.format(" (%s)", tostring(mutation))
                        end

                        table.insert(categorized[categoryKey], {
                            text = itemLine,
                            income = perSecond
                        })
                    end
                end
            end
        end
    end

    -- Sorting High to Low
    for _, group in pairs(categorized) do
        table.sort(group, function(a, b)
            return a.income > b.income
        end)
    end

    return categorized, totalIncome, itemCount
end

-- Scraping Data Placed Pet & Sorting
local function getPlacedPetData()
    local categorized = { ["DIVINE"] = {}, ["ETERNAL"] = {}, ["SECRET"] = {} }
    local itemCount = 0
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return categorized, itemCount end

    local notepadFrame = playerGui:FindFirstChild("PetList")
        and playerGui.PetList:FindFirstChild("Frame")
        and playerGui.PetList.Frame:FindFirstChild("Notepad")
        and playerGui.PetList.Frame.Notepad:FindFirstChild("ScrollingFrame")

    if notepadFrame then
        for _, child in ipairs(notepadFrame:GetChildren()) do
            if string.sub(child.Name, 1, 4) == "Pet_" then
                local mainFrame = child:FindFirstChild("Main_Frame")
                local textLabel = mainFrame and mainFrame:FindFirstChild("TextLabel")

                if textLabel and textLabel.Text ~= "" then
                    local rawText = textLabel.Text
                    local petName, rateStr = string.match(rawText, "^(.-)%s*%(([%d%.%a]+%/s)%)")
                    if not petName then petName = string.match(rawText, "^(.-)%s*%(") or rawText end

                    for baseName, categoryKey in pairs(PET_RARITY_MAP) do
                        if string.find(petName, baseName) then
                            itemCount = itemCount + 1
                            local numValue = rateStr and parseFormattedRate(rateStr) or 0

                            table.insert(categorized[categoryKey], {
                                text = rawText,
                                income = numValue
                            })
                            break
                        end
                    end
                end
            end
        end
    end

    -- Sorting High to Low
    for _, group in pairs(categorized) do
        table.sort(group, function(a, b)
            return a.income > b.income
        end)
    end

    return categorized, itemCount
end

-- Send Webhook Function
local function sendInventoryWebhook(url)
    local invData, invIncome, invCount = getInventoryData()
    local placedData, placedCount = getPlacedPetData()
    local placedIncome = getLeaderstatsMoneyPerSecond() -- Ambil dari leaderstats "Money/s"
    local totalPetIncome = invIncome + placedIncome
    
    local contentLines = {}

    -- Inventory Section
    table.insert(contentLines, string.format("*%s's Inventory [%d]*\n", LocalPlayer.Name, invCount))
    local hasInv = false
    for _, rarityGroup in ipairs(RARITY_ORDER) do
        local items = invData[rarityGroup]
        if items and #items > 0 then
            hasInv = true
            table.insert(contentLines, string.format("*%s*", rarityGroup))
            for _, itemObj in ipairs(items) do 
                table.insert(contentLines, itemObj.text) 
            end
            table.insert(contentLines, "")
        end
    end
    if not hasInv then table.insert(contentLines, "_No Divine, Eternal, or Secret items in inventory._\n") end

    -- Placed Pet Section
    table.insert(contentLines, string.format("*Placed Pet [%d]*\n", placedCount))
    local hasPlaced = false
    for _, rarityGroup in ipairs(RARITY_ORDER) do
        local items = placedData[rarityGroup]
        if items and #items > 0 then
            hasPlaced = true
            table.insert(contentLines, string.format("*%s*", rarityGroup))
            for _, itemObj in ipairs(items) do 
                table.insert(contentLines, itemObj.text) 
            end
            table.insert(contentLines, "")
        end
    end
    if not hasPlaced then table.insert(contentLines, "_No Divine, Eternal, or Secret pets placed._\n") end

    -- Separate Total Income Summaries
    table.insert(contentLines, string.format("*Total Placed Pet: %s*", formatNumber(placedIncome)))
    table.insert(contentLines, string.format("*Total Inventory: %s*", formatNumber(invIncome)))
    table.insert(contentLines, string.format("*Total Pet Income: %s*", formatNumber(totalPetIncome)))

    local payload = HttpService:JSONEncode({
        embeds = {{
            title = string.format("%s's Inventory Overview", LocalPlayer.Name),
            description = "```text\n" .. table.concat(contentLines, "\n") .. "\n```",
            color = 16777215,
            timestamp = DateTime.now():ToIsoDate()
        }}
    })

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or fluxus.request or request
    if httpRequest then
        httpRequest({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end
end

-- Create ScreenGUI UI
local function createUI()
    if CoreGui:FindFirstChild("WebhookSaverUI") then
        CoreGui.WebhookSaverUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WebhookSaverUI"
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 300, 0, 130)
    MainFrame.Position = UDim2.new(0.5, -150, 0.4, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.Text = "Enter Webhook URL"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Parent = MainFrame

    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(0.9, 0, 0, 35)
    TextBox.Position = UDim2.new(0.05, 0, 0.28, 0)
    TextBox.PlaceholderText = "Paste Webhook URL Here..."
    TextBox.Text = ""
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TextBox.BorderSizePixel = 0
    TextBox.ClearTextOnFocus = false
    TextBox.TextWrapped = true
    TextBox.Font = Enum.Font.SourceSans
    TextBox.TextSize = 12
    TextBox.Parent = MainFrame

    local TextCorner = Instance.new("UICorner")
    TextCorner.CornerRadius = UDim.new(0, 5)
    TextCorner.Parent = TextBox

    local SaveBtn = Instance.new("TextButton")
    SaveBtn.Size = UDim2.new(0.9, 0, 0, 30)
    SaveBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
    SaveBtn.Text = "Save & Send"
    SaveBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
    SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveBtn.Font = Enum.Font.SourceSansBold
    SaveBtn.TextSize = 13
    SaveBtn.Parent = MainFrame

    local SaveCorner = Instance.new("UICorner")
    SaveCorner.CornerRadius = UDim.new(0, 5)
    SaveCorner.Parent = SaveBtn

    SaveBtn.MouseButton1Click:Connect(function()
        local inputUrl = TextBox.Text:gsub("[%s\r\n\t]", "")
        if #inputUrl > 10 and string.sub(inputUrl, 1, 4) == "http" then
            saveWebhook(inputUrl)
            sendInventoryWebhook(inputUrl)
            ScreenGui:Destroy()
        else
            SaveBtn.Text = "Invalid Webhook URL!"
            task.wait(1)
            SaveBtn.Text = "Save & Send"
        end
    end)
end

-- Entry Point
local savedUrl = getSavedWebhook()

if savedUrl then
    sendInventoryWebhook(savedUrl)
else
    createUI()
end
