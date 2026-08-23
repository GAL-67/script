local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local FILE_NAME = "whs.txt"

-- Fungsi untuk mengirim webhook Discord
local function sendWebhook(webhookUrl)
    if not webhookUrl or webhookUrl == "" then return end

    local placeId = game.PlaceId
    local jobid = game.JobId
    local playerName = Players.LocalPlayer.Name

    -- Format Deep Link Server Roblox
    local serverLink = string.format("https://www.roblox.com/games/start?placeId=%s&instanceId=%s", tostring(placeId), jobid)
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    -- Fix Clickable Link: Gunakan format <URL> agar Discord mengenali protokol deeplink
    local descriptionText = string.format("🔗 **Click to Join:**\n<%s>\n\n📋 **Copy Link (Mobile):**\n`%s`", serverLink, serverLink)

    -- Format Payload Embed Discord (Warna Putih: 16777215)
    local payload = {
        embeds = {
            {
                title = playerName,
                description = descriptionText,
                color = 16777215,
                timestamp = timestamp
            }
        }
    }

    -- HTTP Request kompatibel dengan Delta
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request

    if requestFunc then
        requestFunc({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    else
        warn("Executor tidak mendukung HTTP request.")
    end
end

-- Mengecek apakah wh.txt sudah ada di workspace executor
if isfile and isfile(FILE_NAME) then
    local savedUrl = readfile(FILE_NAME)
    if savedUrl and savedUrl ~= "" then
        sendWebhook(savedUrl)
        return
    end
end

-- Jika wh.txt belum ada, buat GUI untuk input Webhook
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Title = Instance.new("TextLabel")
local WebhookBox = Instance.new("TextBox")
local BoxCorner = Instance.new("UICorner")
local SubmitBtn = Instance.new("TextButton")
local BtnCorner = Instance.new("UICorner")

-- Parent GUI ke CoreGui / PlayerGui
ScreenGui.Name = "WebhookLoaderUI"
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

-- Frame Utama
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 180)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Title
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "Enter Discord Webhook"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Parent = MainFrame

-- Input Box (TextBox)
WebhookBox.Name = "WebhookBox"
WebhookBox.Size = UDim2.new(0.88, 0, 0, 40)
WebhookBox.Position = UDim2.new(0.06, 0, 0.3, 0)
WebhookBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
WebhookBox.BorderSizePixel = 0
WebhookBox.Font = Enum.Font.Gotham
WebhookBox.PlaceholderText = "Paste Webhook URL Here..."
WebhookBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
WebhookBox.Text = ""
WebhookBox.TextColor3 = Color3.fromRGB(255, 255, 255)
WebhookBox.TextSize = 12
WebhookBox.ClearTextOnFocus = false
WebhookBox.Parent = MainFrame

BoxCorner.CornerRadius = UDim.new(0, 8)
BoxCorner.Parent = WebhookBox

-- Submit Button
SubmitBtn.Name = "SubmitBtn"
SubmitBtn.Size = UDim2.new(0.88, 0, 0, 38)
SubmitBtn.Position = UDim2.new(0.06, 0, 0.65, 0)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.BorderSizePixel = 0
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.Text = "SAVE & SEND"
SubmitBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
SubmitBtn.TextSize = 13
SubmitBtn.Parent = MainFrame

BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = SubmitBtn

-- Event Listener saat Tombol Submit Diklik
SubmitBtn.MouseButton1Click:Connect(function()
    local inputUrl = WebhookBox.Text:match("^%s*(.-)%s*$")
    
    if inputUrl and inputUrl ~= "" then
        if writefile then
            writefile(FILE_NAME, inputUrl)
        end
        
        ScreenGui:Destroy()
        sendWebhook(inputUrl)
    end
end)
