getgenv().AutoTicket = true
getgenv().AutoClaim = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Remote & UI References
local ticketLabel = LocalPlayer:WaitForChild("PlayerGui")
    :WaitForChild("ScreenSeasonPass")
    :WaitForChild("Root")
    :WaitForChild("Lottery")
    :WaitForChild("Season")
    :WaitForChild("TextLabel")

local lotteryRemote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("LotteryRE")
local dinoEventRemote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("DinoEventRE")

-- Helper: Membaca angka dari teks tiket
local function getTicketCount()
    local text = ticketLabel.Text
    local count = tonumber(text:match("%d+"))
    return count or 0
end

-- Thread 1: Auto Spin
task.spawn(function()
    while getgenv().AutoTicket do
        local tickets = getTicketCount()
        
        if tickets >= 1 then
            local spinArgs = {
                {
                    event = "lottery",
                    count = 1
                }
            }
            lotteryRemote:FireServer(unpack(spinArgs))
            task.wait(0.5) -- Delay antar spin (sesuaikan jika perlu)
        else
            -- TUNGGU SAMPAI TIKET > 0 KEMBALI
            repeat
                task.wait(1)
            until getTicketCount() >= 1 or not getgenv().AutoTicket
        end
    end
end)

-- Thread 2: Auto Claim Reward
task.spawn(function()
    while getgenv().AutoClaim do
        local claimArgs = {
            {
                event = "claimreward",
                id = "Task_8"
            }
        }
        dinoEventRemote:FireServer(unpack(claimArgs))
        task.wait(2) -- Delay klaim (mencegah spam remote)
    end
end)
