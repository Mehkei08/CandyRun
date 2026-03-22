--[[
	Candy Run - Client HUD & Game Feel v3
	Timer starts/restarts on spawn & respawn, smooth effects, respawn overlay
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local timerEvent = ReplicatedStorage:WaitForChild("TimerUpdate")
local candyCollectedEvent = ReplicatedStorage:WaitForChild("CandyCollected")
local respawnEvent = ReplicatedStorage:WaitForChild("RespawnTimer")
local timerStartEvent = ReplicatedStorage:WaitForChild("TimerStart")

-- ============================================================
-- HUD
-- ============================================================

local hudGui = Instance.new("ScreenGui")
hudGui.Name = "CandyRunHUD"
hudGui.ResetOnSpawn = false
hudGui.IgnoreGuiInset = false
hudGui.Enabled = false
hudGui.Parent = playerGui

local timerFrame = Instance.new("Frame")
timerFrame.Size = UDim2.fromScale(0.18, 0.055)
timerFrame.Position = UDim2.fromScale(0.41, 0.02)
timerFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
timerFrame.BackgroundTransparency = 0.4
timerFrame.Parent = hudGui

Instance.new("UICorner", timerFrame).CornerRadius = UDim.new(0, 12)

local timerStroke = Instance.new("UIStroke")
timerStroke.Color = Color3.fromRGB(255, 150, 200)
timerStroke.Thickness = 1.5; timerStroke.Transparency = 0.3
timerStroke.Parent = timerFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.fromScale(0.9, 0.8)
timerLabel.Position = UDim2.fromScale(0.05, 0.1)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "⏱️ 0:00.0"
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.FredokaOne
timerLabel.Parent = timerFrame

local candyFrame = Instance.new("Frame")
candyFrame.Size = UDim2.fromScale(0.12, 0.055)
candyFrame.Position = UDim2.fromScale(0.86, 0.02)
candyFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
candyFrame.BackgroundTransparency = 0.4
candyFrame.Parent = hudGui

Instance.new("UICorner", candyFrame).CornerRadius = UDim.new(0, 12)

local candyStroke = Instance.new("UIStroke")
candyStroke.Color = Color3.fromRGB(255, 200, 100)
candyStroke.Thickness = 1.5; candyStroke.Transparency = 0.3
candyStroke.Parent = candyFrame

local candyLabel = Instance.new("TextLabel")
candyLabel.Size = UDim2.fromScale(0.9, 0.8)
candyLabel.Position = UDim2.fromScale(0.05, 0.1)
candyLabel.BackgroundTransparency = 1
candyLabel.Text = "🍬 0"
candyLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
candyLabel.TextScaled = true
candyLabel.Font = Enum.Font.FredokaOne
candyLabel.Parent = candyFrame

-- ============================================================
-- TIMER STATE
-- ============================================================

local gameStarted = false
local startTime = 0
local candiesCollected = 0
local hasWon = false
local timerRunning = false

local function startTimer()
	startTime = tick()
	candiesCollected = 0
	candyLabel.Text = "🍬 0"
	hasWon = false
	gameStarted = true
	hudGui.Enabled = true

	if not timerRunning then
		timerRunning = true
		task.spawn(function()
			while gameStarted do
				local elapsed = tick() - startTime
				local minutes = math.floor(elapsed / 60)
				local seconds = elapsed % 60
				timerLabel.Text = string.format("⏱️ %d:%04.1f", minutes, seconds)
				task.wait(0.05)
			end
			timerRunning = false
		end)
	end
end

-- Timer starts when server tells us (play button or respawn)
timerStartEvent.OnClientEvent:Connect(function()
	startTime = tick()
	if not gameStarted then
		startTimer()
	end
end)

-- Also start when start screen disappears
task.spawn(function()
	while playerGui:FindFirstChild("CandyRunStartScreen") do
		task.wait(0.1)
	end
	-- Start screen gone = ready
	if not gameStarted then
		startTimer()
	end

	-- HUD slide in
	timerFrame.Position = UDim2.fromScale(0.41, -0.08)
	candyFrame.Position = UDim2.fromScale(0.86, -0.08)
	TweenService:Create(timerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.41, 0.02),
	}):Play()
	TweenService:Create(candyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.1), {
		Position = UDim2.fromScale(0.86, 0.02),
	}):Play()
end)

-- ============================================================
-- CANDY COLLECTION
-- ============================================================

candyCollectedEvent.OnClientEvent:Connect(function()
	candiesCollected += 1
	candyLabel.Text = "🍬 " .. candiesCollected

	TweenService:Create(candyFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.15, 0.07),
		BackgroundColor3 = Color3.fromRGB(255, 220, 50),
	}):Play()
	task.wait(0.08)
	TweenService:Create(candyFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.12, 0.055),
		BackgroundColor3 = Color3.fromRGB(20, 10, 30),
	}):Play()

	local plusOne = Instance.new("TextLabel")
	plusOne.Size = UDim2.fromScale(0.06, 0.04)
	plusOne.Position = UDim2.fromScale(0.89, 0.07)
	plusOne.BackgroundTransparency = 1
	plusOne.Text = "+1"
	plusOne.TextColor3 = Color3.fromRGB(255, 220, 100)
	plusOne.TextScaled = true
	plusOne.Font = Enum.Font.FredokaOne
	plusOne.Parent = hudGui

	TweenService:Create(plusOne, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.89, -0.02),
		TextTransparency = 1,
	}):Play()
	task.delay(0.7, function() plusOne:Destroy() end)
end)

-- ============================================================
-- VICTORY
-- ============================================================

timerEvent.OnClientEvent:Connect(function(status)
	if status ~= "WIN" or not gameStarted or hasWon then return end
	hasWon = true
	gameStarted = false

	local elapsed = tick() - startTime
	local minutes = math.floor(elapsed / 60)
	local seconds = elapsed % 60
	local timeStr = string.format("%d:%04.1f", minutes, seconds)

	local victoryGui = Instance.new("ScreenGui")
	victoryGui.Name = "VictoryScreen"
	victoryGui.IgnoreGuiInset = true; victoryGui.Parent = playerGui

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1,1)
	overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	overlay.BackgroundTransparency = 1; overlay.Parent = victoryGui

	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.45}):Play()

	-- Confetti
	for i = 1, 30 do
		local confetti = Instance.new("TextLabel")
		confetti.Text = ({"🍬","🍭","🍫","🧁","✨","🎉"})[math.random(1,6)]
		confetti.TextSize = math.random(18,36)
		confetti.BackgroundTransparency = 1
		confetti.Size = UDim2.fromOffset(40,40)
		confetti.Position = UDim2.fromScale(0.5, 0.4)
		confetti.ZIndex = 10; confetti.Parent = victoryGui

		local angle = math.random()*math.pi*2
		local dist = math.random(20,60)/100
		TweenService:Create(confetti, TweenInfo.new(math.random(8,15)/10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5+math.cos(angle)*dist, 0.4+math.sin(angle)*dist),
			TextTransparency = 0.8,
			Rotation = math.random(-360,360),
		}):Play()
	end

	local victoryTitle = Instance.new("TextLabel")
	victoryTitle.Size = UDim2.fromScale(0,0)
	victoryTitle.Position = UDim2.fromScale(0.5, 0.18)
	victoryTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	victoryTitle.BackgroundTransparency = 1
	victoryTitle.Text = "🎉 YOU WIN! 🎉"
	victoryTitle.TextColor3 = Color3.fromRGB(255,215,0)
	victoryTitle.TextScaled = true; victoryTitle.Font = Enum.Font.FredokaOne
	victoryTitle.ZIndex = 20; victoryTitle.Parent = victoryGui

	local vStroke = Instance.new("UIStroke")
	vStroke.Color = Color3.fromRGB(200,150,0); vStroke.Thickness = 3
	vStroke.Parent = victoryTitle

	task.delay(0.3, function()
		TweenService:Create(victoryTitle, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.7, 0.12),
		}):Play()
	end)

	local statsCard = Instance.new("Frame")
	statsCard.Size = UDim2.fromScale(0.35, 0.25)
	statsCard.Position = UDim2.fromScale(0.5, 0.42)
	statsCard.AnchorPoint = Vector2.new(0.5, 0.5)
	statsCard.BackgroundColor3 = Color3.fromRGB(30,15,40)
	statsCard.BackgroundTransparency = 0.3
	statsCard.ZIndex = 20; statsCard.Parent = victoryGui

	Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 16)
	local scStroke = Instance.new("UIStroke")
	scStroke.Color = Color3.fromRGB(255,200,100); scStroke.Thickness = 2
	scStroke.Parent = statsCard

	local statsText = Instance.new("TextLabel")
	statsText.Size = UDim2.fromScale(0.85, 0.85)
	statsText.Position = UDim2.fromScale(0.075, 0.075)
	statsText.BackgroundTransparency = 1
	statsText.Text = string.format("⏱️  Time: %s\n\n🍬  Candies: %d\n\n✨  Sweet victory!", timeStr, candiesCollected)
	statsText.TextColor3 = Color3.fromRGB(255,255,255)
	statsText.TextScaled = true; statsText.Font = Enum.Font.GothamBold
	statsText.TextYAlignment = Enum.TextYAlignment.Center
	statsText.ZIndex = 21; statsText.Parent = statsCard

	local playAgain = Instance.new("TextButton")
	playAgain.Size = UDim2.fromScale(0,0)
	playAgain.Position = UDim2.fromScale(0.5, 0.68)
	playAgain.AnchorPoint = Vector2.new(0.5, 0.5)
	playAgain.BackgroundColor3 = Color3.fromRGB(80,220,120)
	playAgain.Text = "🍭  Play Again"
	playAgain.TextColor3 = Color3.fromRGB(255,255,255)
	playAgain.TextScaled = true; playAgain.Font = Enum.Font.FredokaOne
	playAgain.AutoButtonColor = false
	playAgain.ZIndex = 20; playAgain.Parent = victoryGui

	Instance.new("UICorner", playAgain).CornerRadius = UDim.new(0, 14)

	task.delay(0.8, function()
		TweenService:Create(playAgain, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.22, 0.07),
		}):Play()
	end)

	playAgain.MouseEnter:Connect(function()
		TweenService:Create(playAgain, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100,255,150)}):Play()
	end)
	playAgain.MouseLeave:Connect(function()
		TweenService:Create(playAgain, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80,220,120)}):Play()
	end)

	playAgain.MouseButton1Click:Connect(function()
		playAgain.Active = false
		TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
		task.wait(0.35)
		victoryGui:Destroy()
		-- Don't go back to title — just respawn and restart timer
		hasWon = false
		startTime = tick()
		gameStarted = true
		candiesCollected = 0
		candyLabel.Text = "🍬 0"
		if not timerRunning then
			timerRunning = true
			task.spawn(function()
				while gameStarted do
					local elapsed2 = tick() - startTime
					local min2 = math.floor(elapsed2 / 60)
					local sec2 = elapsed2 % 60
					timerLabel.Text = string.format("⏱️ %d:%04.1f", min2, sec2)
					task.wait(0.05)
				end
				timerRunning = false
			end)
		end
		-- Fire server to reset checkpoint and teleport to spawn
		local startEvt = ReplicatedStorage:FindFirstChild("StartGame")
		if startEvt then startEvt:FireServer() end
	end)
end)

-- ============================================================
-- DEATH EFFECT
-- ============================================================

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		local deathOverlay = Instance.new("Frame")
		deathOverlay.Size = UDim2.fromScale(1,1)
		deathOverlay.BackgroundColor3 = Color3.fromRGB(200,30,30)
		deathOverlay.BackgroundTransparency = 0.6
		deathOverlay.ZIndex = 50; deathOverlay.Parent = hudGui

		TweenService:Create(deathOverlay, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
		task.delay(1.1, function() if deathOverlay then deathOverlay:Destroy() end end)
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

-- ============================================================
-- 3-SECOND RESPAWN OVERLAY
-- ============================================================

respawnEvent.OnClientEvent:Connect(function(seconds)
	local rGui = Instance.new("ScreenGui")
	rGui.Name = "RespawnOverlay"
	rGui.IgnoreGuiInset = true
	rGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	rGui.Parent = playerGui

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1,1)
	overlay.BackgroundColor3 = Color3.fromRGB(40,0,0)
	overlay.BackgroundTransparency = 0.4
	overlay.Parent = rGui

	local fellText = Instance.new("TextLabel")
	fellText.Size = UDim2.fromScale(0.6, 0.1)
	fellText.Position = UDim2.fromScale(0.2, 0.28)
	fellText.BackgroundTransparency = 1
	fellText.Text = "💀 YOU FELL!"
	fellText.TextColor3 = Color3.fromRGB(255,80,80)
	fellText.TextScaled = true; fellText.Font = Enum.Font.FredokaOne
	fellText.Parent = rGui

	local fStroke = Instance.new("UIStroke")
	fStroke.Color = Color3.fromRGB(100,0,0); fStroke.Thickness = 3
	fStroke.Parent = fellText

	fellText.TextTransparency = 1
	TweenService:Create(fellText, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Size = UDim2.fromScale(0.2, 0.2)
	countdownLabel.Position = UDim2.fromScale(0.4, 0.42)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = tostring(seconds)
	countdownLabel.TextColor3 = Color3.fromRGB(255,255,255)
	countdownLabel.TextScaled = true; countdownLabel.Font = Enum.Font.FredokaOne
	countdownLabel.Parent = rGui

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(255,100,100); cStroke.Thickness = 3
	cStroke.Parent = countdownLabel

	local respawnText = Instance.new("TextLabel")
	respawnText.Size = UDim2.fromScale(0.4, 0.05)
	respawnText.Position = UDim2.fromScale(0.3, 0.65)
	respawnText.BackgroundTransparency = 1
	respawnText.Text = "Respawning..."
	respawnText.TextColor3 = Color3.fromRGB(255,200,200)
	respawnText.TextTransparency = 0.3
	respawnText.TextScaled = true; respawnText.Font = Enum.Font.GothamBold
	respawnText.Parent = rGui

	for i = seconds, 1, -1 do
		countdownLabel.Text = tostring(i)

		countdownLabel.Size = UDim2.fromScale(0.15, 0.15)
		TweenService:Create(countdownLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.2, 0.2),
		}):Play()

		countdownLabel.TextColor3 = Color3.fromRGB(255,100,100)
		TweenService:Create(countdownLabel, TweenInfo.new(0.5), {
			TextColor3 = Color3.fromRGB(255,255,255),
		}):Play()

		task.wait(1)
	end

	TweenService:Create(overlay, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
	TweenService:Create(fellText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
	TweenService:Create(countdownLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
	TweenService:Create(respawnText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
	task.delay(0.5, function() rGui:Destroy() end)
end)

print("[CandyRun] Client HUD loaded!")
