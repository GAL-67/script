-- Roblox ULTIMATE POTATO MODE (OPTIMIZED FOR MOBILE / EXECUTOR)
-- Clean, Event-Driven, Zero Stutter

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

-- 1. SETTING GRAFIS TERENDAH
pcall(function()
    sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
end)
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04

Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 1

for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("Clouds") then
        v:Destroy()
    end
end

local Terrain = Workspace:FindFirstChildOfClass("Terrain")
if Terrain then
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0
    pcall(function() sethiddenproperty(Terrain, "Decoration", false) end)
end

-- 2. FUNGSI STRIPPER
local function StripObject(v)
    if v:IsA("Decal") or v:IsA("Texture") 
    or v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") 
    or v:IsA("Beam") or v:IsA("Trail") or v:IsA("Light") or v:IsA("Highlight") 
    or v:IsA("Explosion") or v:IsA("Sound") or v:IsA("BillboardGui") or v:IsA("SurfaceGui") 
    or v:IsA("Clothing") or v:IsA("ShirtGraphic") then
        v:Destroy()
        
    elseif v:IsA("BasePart") then
        v.Material = Enum.Material.SmoothPlastic
        v.Reflectance = 0
        v.CastShadow = false
        
        if v:IsA("MeshPart") then
            v.TextureID = ""
            v.RenderFidelity = Enum.RenderFidelity.Performance
        end
    elseif v:IsA("SpecialMesh") then
        v.TextureId = ""
    end
end

-- 3. HAPUS ANIMASI & BLOKIR ANIMATOR SECARA EFEKTIF
local function DisableAnimation(char)
    if not char then return end

    -- Destroy script Animate
    local animateScript = char:FindFirstChild("Animate")
    if animateScript then animateScript:Destroy() end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        -- Stop track saat ini
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
            
            -- Hook saat ada animasi baru dicoba diputar
            animator.AnimationPlayed:Connect(function(track)
                track:Stop(0)
            end)
        end
        
        -- Deteksi jika Animator baru dimasukkan
        humanoid.ChildAdded:Connect(function(child)
            if child:IsA("Animator") then
                child.AnimationPlayed:Connect(function(track)
                    track:Stop(0)
                end)
            end
        end)
    end
end

-- 4. SCAN MASA AWAL (1x JALAN)
for _, v in ipairs(Workspace:GetDescendants()) do
    StripObject(v)
end

-- Setup player animation disabler
local function SetupPlayer(player)
    if player.Character then DisableAnimation(player.Character) end
    player.CharacterAdded:Connect(DisableAnimation)
end

for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end
Players.PlayerAdded:Connect(SetupPlayer)

-- 5. REAL-TIME CLEANER (EVENT-DRIVEN MURNI, TANPA LOOPING)
Workspace.DescendantAdded:Connect(StripObject)
