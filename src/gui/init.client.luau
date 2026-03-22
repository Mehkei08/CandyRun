--[[
	Candy Run - Start Screen UI v3
	Title screen with fun soundtrack, instant spawn on play
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Disable default UI during menu
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

-- Freeze character
local function freezeCharacter()
	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end
	end
end

local function unfreezeCharacter()
	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum.WalkSpeed = 28; hum.JumpPower = 60 end
	end
end

freezeCharacter()

-- ============================================================
-- TITLE SCREEN MUSIC
-- ============================================================

-- Fun upbeat candy soundtrack
-- Using Roblox library sound IDs (royalty-free game music)
local titleMusic = Instance.new("Sound")
titleMusic.Name = "TitleMusic"
titleMusic.SoundId = "rbxassetid://1837849285"  -- Fun upbeat game music
titleMusic.Volume = 0.5
titleMusic.Looped = true
titleMusic.PlaybackSpeed = 1
titleMusic.Parent = SoundService
titleMusic:Play()

-- ============================================================
-- SCREEN GUI
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CandyRunStartScreen"
screenGui.ResetOnSpawn = true
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(255, 182, 213)
background.BorderSizePixel = 0; background.Parent = screenGui

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 200)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 130, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 200, 255)),
})
bgGradient.Rotation = 45; bgGradient.Parent = background

task.spawn(function()
	while bgGradient and bgGradient.Parent do
		bgGradient.Rotation = (tick() * 15) % 360
		task.wait(0.03)
	end
end)

-- ============================================================
-- FLOATING CANDY
-- ============================================================

local candyContainer = Instance.new("Frame")
candyContainer.Name = "CandyParticles"
candyContainer.Size = UDim2.fromScale(1, 1)
candyContainer.BackgroundTransparency = 1
candyContainer.ClipsDescendants = true
candyContainer.Parent = screenGui

local candyEmojis = {"🍬", "🍭", "🍫", "🍩", "🧁", "🍪", "🎂", "🍰", "🍡", "🍮"}

local function spawnFloatingCandy()
	local candy = Instance.new("TextLabel")
	candy.Text = candyEmojis[math.random(1, #candyEmojis)]
	candy.TextSize = math.random(20, 44)
	candy.BackgroundTransparency = 1
	candy.TextTransparency = 0.4
	candy.Size = UDim2.fromOffset(50, 50)
	candy.Rotation = math.random(-20, 20)
	local startX = math.random(0, 100) / 100
	candy.Position = UDim2.fromScale(startX, 1.05)
	candy.Parent = candyContainer

	local duration = math.random(60, 120) / 10
	local endX = startX + (math.random(-10, 10) / 100)

	local floatUp = TweenService:Create(candy, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Position = UDim2.fromScale(endX, -0.1),
		Rotation = candy.Rotation + math.random(-40, 40),
		TextTransparency = 0.7,
	})
	floatUp:Play()
	floatUp.Completed:Connect(function() candy:Destroy() end)
end

task.spawn(function()
	for i = 1, 15 do
		local candy = Instance.new("TextLabel")
		candy.Text = candyEmojis[math.random(1, #candyEmojis)]
		candy.TextSize = math.random(20, 44)
		candy.BackgroundTransparency = 1; candy.TextTransparency = 0.4
		candy.Size = UDim2.fromOffset(50, 50)
		candy.Position = UDim2.fromScale(math.random(0,100)/100, math.random(0,100)/100)
		candy.Rotation = math.random(-20, 20)
		candy.Parent = candyContainer
		TweenService:Create(candy, TweenInfo.new(
			math.random(50,80)/10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
		), {
			Position = candy.Position + UDim2.fromScale(0, -0.08),
			Rotation = candy.Rotation + math.random(-10, 10),
		}):Play()
	end
	while candyContainer and candyContainer.Parent do
		spawnFloatingCandy()
		task.wait(math.random(4, 8) / 10)
	end
end)

-- ============================================================
-- TITLE
-- ============================================================

local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.fromScale(0.8, 0.22)
titleContainer.Position = UDim2.fromScale(0.1, 0.08)
titleContainer.BackgroundTransparency = 1
titleContainer.Parent = screenGui

local titleShadow = Instance.new("TextLabel")
titleShadow.Size = UDim2.fromScale(1, 1)
titleShadow.Position = UDim2.fromOffset(3, 3)
titleShadow.BackgroundTransparency = 1
titleShadow.Text = "CANDY RUN"
titleShadow.TextColor3 = Color3.fromRGB(80, 20, 60)
titleShadow.TextTransparency = 0.5
titleShadow.TextScaled = true; titleShadow.Font = Enum.Font.FredokaOne
titleShadow.Parent = titleContainer

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.fromScale(1, 1)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "CANDY RUN"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true; titleLabel.Font = Enum.Font.FredokaOne
titleLabel.Parent = titleContainer

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(200, 50, 120); titleStroke.Thickness = 3
titleStroke.Parent = titleLabel

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 180)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 220, 100)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(100, 255, 200)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 180, 255)),
})
titleGradient.Parent = titleLabel

task.spawn(function()
	while titleContainer and titleContainer.Parent do
		local t = tick()
		local yOffset = math.sin(t * 1.5) * 0.012
		titleContainer.Position = UDim2.fromScale(0.1, 0.08 + yOffset)
		titleGradient.Offset = Vector2.new(math.sin(t * 0.8) * 0.3, 0)
		task.wait(0.016)
	end
end)

-- Candy icons
local leftCandy = Instance.new("TextLabel")
leftCandy.Size = UDim2.fromScale(0.12, 1)
leftCandy.Position = UDim2.fromScale(-0.13, 0)
leftCandy.BackgroundTransparency = 1; leftCandy.Text = "🍬"
leftCandy.TextScaled = true; leftCandy.Parent = titleContainer

local rightCandy = Instance.new("TextLabel")
rightCandy.Size = UDim2.fromScale(0.12, 1)
rightCandy.Position = UDim2.fromScale(1.01, 0)
rightCandy.BackgroundTransparency = 1; rightCandy.Text = "🍬"
rightCandy.TextScaled = true; rightCandy.Parent = titleContainer

task.spawn(function()
	while leftCandy and leftCandy.Parent do
		local t = tick()
		leftCandy.Rotation = math.sin(t * 2) * 15
		rightCandy.Rotation = math.sin(t * 2 + 1) * -15
		task.wait(0.016)
	end
end)

-- ============================================================
-- SUBTITLE
-- ============================================================

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.fromScale(0.5, 0.04)
subtitle.Position = UDim2.fromScale(0.25, 0.31)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Jump from candy to candy... don't fall!"
subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
subtitle.TextTransparency = 1; subtitle.TextScaled = true
subtitle.Font = Enum.Font.GothamBold; subtitle.Parent = screenGui

local subStroke = Instance.new("UIStroke")
subStroke.Color = Color3.fromRGB(100, 50, 80); subStroke.Thickness = 1.5
subStroke.Transparency = 1; subStroke.Parent = subtitle

task.delay(0.5, function()
	TweenService:Create(subtitle, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0.15,
	}):Play()
	TweenService:Create(subStroke, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 0,
	}):Play()
end)

-- ============================================================
-- PLAY BUTTON
-- ============================================================

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.Size = UDim2.fromScale(0, 0)
playButton.Position = UDim2.fromScale(0.5, 0.52)
playButton.AnchorPoint = Vector2.new(0.5, 0.5)
playButton.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
playButton.Text = "🍭  PLAY  🍭"
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.TextScaled = true; playButton.Font = Enum.Font.FredokaOne
playButton.BorderSizePixel = 0; playButton.AutoButtonColor = false
playButton.Parent = screenGui

Instance.new("UICorner", playButton).CornerRadius = UDim.new(0, 18)

local playStroke = Instance.new("UIStroke")
playStroke.Color = Color3.fromRGB(40, 180, 80); playStroke.Thickness = 3
playStroke.Parent = playButton

local playPadding = Instance.new("UIPadding")
playPadding.PaddingLeft = UDim.new(0, 20)
playPadding.PaddingRight = UDim.new(0, 20)
playPadding.Parent = playButton

task.delay(0.8, function()
	TweenService:Create(playButton, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.28, 0.09),
	}):Play()
end)

task.delay(1.5, function()
	while playButton and playButton.Parent do
		TweenService:Create(playButton, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = UDim2.fromScale(0.30, 0.095),
		}):Play()
		task.wait(1)
		TweenService:Create(playButton, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = UDim2.fromScale(0.28, 0.09),
		}):Play()
		task.wait(1)
	end
end)

playButton.MouseEnter:Connect(function()
	TweenService:Create(playButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		BackgroundColor3 = Color3.fromRGB(100, 255, 150),
		Size = UDim2.fromScale(0.31, 0.098),
	}):Play()
	TweenService:Create(playStroke, TweenInfo.new(0.25), {Color = Color3.fromRGB(60, 200, 100)}):Play()
end)

playButton.MouseLeave:Connect(function()
	TweenService:Create(playButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		BackgroundColor3 = Color3.fromRGB(80, 220, 120),
		Size = UDim2.fromScale(0.28, 0.09),
	}):Play()
	TweenService:Create(playStroke, TweenInfo.new(0.25), {Color = Color3.fromRGB(40, 180, 80)}):Play()
end)

-- ============================================================
-- VOLUME / MUTE BUTTON
-- ============================================================

local muteButton = Instance.new("TextButton")
muteButton.Size = UDim2.fromScale(0.04, 0.05)
muteButton.Position = UDim2.fromScale(0.94, 0.92)
muteButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
muteButton.BackgroundTransparency = 0.6
muteButton.Text = "🔊"
muteButton.TextScaled = true; muteButton.Font = Enum.Font.GothamBold
muteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
muteButton.AutoButtonColor = false
muteButton.Parent = screenGui

Instance.new("UICorner", muteButton).CornerRadius = UDim.new(0, 8)

local muted = false
muteButton.MouseButton1Click:Connect(function()
	muted = not muted
	if muted then
		TweenService:Create(titleMusic, TweenInfo.new(0.3), {Volume = 0}):Play()
		muteButton.Text = "🔇"
	else
		TweenService:Create(titleMusic, TweenInfo.new(0.3), {Volume = 0.5}):Play()
		muteButton.Text = "🔊"
	end
end)

-- ============================================================
-- STATS
-- ============================================================

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.fromScale(0.4, 0.06)
statsFrame.Position = UDim2.fromScale(0.3, 0.66)
statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statsFrame.BackgroundTransparency = 0.65; statsFrame.Parent = screenGui

Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 12)

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.fromScale(0.9, 0.8)
statsLabel.Position = UDim2.fromScale(0.05, 0.1)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "🏆 Best Time: --:--  ·  🍬 Candies: 0"
statsLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
statsLabel.TextScaled = true; statsLabel.Font = Enum.Font.GothamBold
statsLabel.Parent = statsFrame

-- ============================================================
-- VERSION
-- ============================================================

local credits = Instance.new("TextLabel")
credits.Size = UDim2.fromScale(0.2, 0.03)
credits.Position = UDim2.fromScale(0.4, 0.93)
credits.BackgroundTransparency = 1
credits.Text = "v1.0  ·  Made with 🍫"
credits.TextColor3 = Color3.fromRGB(255, 255, 255)
credits.TextTransparency = 0.5; credits.TextScaled = true
credits.Font = Enum.Font.Gotham; credits.Parent = screenGui

-- ============================================================
-- PLAY BUTTON CLICK → INSTANT SPAWN
-- ============================================================

local startGameEvent = ReplicatedStorage:WaitForChild("StartGame", 10)

playButton.MouseButton1Click:Connect(function()
	playButton.Active = false

	-- Click feedback
	TweenService:Create(playButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromScale(0.26, 0.08),
		BackgroundColor3 = Color3.fromRGB(255, 220, 80),
	}):Play()
	task.wait(0.1)
	TweenService:Create(playButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.35, 0.12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 1,
	}):Play()
	task.wait(0.15)

	-- Fade out music
	TweenService:Create(titleMusic, TweenInfo.new(0.5), {Volume = 0}):Play()

	-- White flash
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 1; flash.ZIndex = 100
	flash.Parent = screenGui

	TweenService:Create(flash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 0,
	}):Play()
	task.wait(0.35)

	-- Fire server (spawns character + starts timer)
	if startGameEvent then
		startGameEvent:FireServer()
	end

	-- Unfreeze and re-enable core GUI
	unfreezeCharacter()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

	task.wait(0.2)

	-- Transition overlay
	local transitionGui = Instance.new("ScreenGui")
	transitionGui.Name = "TransitionOverlay"
	transitionGui.IgnoreGuiInset = true; transitionGui.Parent = playerGui

	local newFlash = Instance.new("Frame")
	newFlash.Size = UDim2.fromScale(1, 1)
	newFlash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	newFlash.BackgroundTransparency = 0; newFlash.Parent = transitionGui

	-- Stop title music and start gameplay music
	titleMusic:Stop()
	titleMusic:Destroy()

	-- Gameplay soundtrack (different from title)
	local gameMusic = Instance.new("Sound")
	gameMusic.Name = "GameplayMusic"
	gameMusic.SoundId = "rbxassetid://1839879277"  -- Upbeat adventure/platformer music
	gameMusic.Volume = 0
	gameMusic.Looped = true
	gameMusic.PlaybackSpeed = 1
	gameMusic.Parent = SoundService
	gameMusic:Play()
	TweenService:Create(gameMusic, TweenInfo.new(1), {Volume = 0.4}):Play()

	screenGui:Destroy()

	TweenService:Create(newFlash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	task.wait(0.7)
	transitionGui:Destroy()
end)

print("[CandyRun] Start screen loaded with music!")
