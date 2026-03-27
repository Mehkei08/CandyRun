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
local candyUpdateEvent = ReplicatedStorage:WaitForChild("CandyUpdate")
local purchaseEvent = ReplicatedStorage:WaitForChild("PurchaseItem")
local respawnEvent = ReplicatedStorage:WaitForChild("RespawnTimer")
local timerStartEvent = ReplicatedStorage:WaitForChild("TimerStart")
local dailySpinEvent = ReplicatedStorage:WaitForChild("DailySpin", 10)
local trailSpinResultEvent = ReplicatedStorage:WaitForChild("TrailSpinResult", 10)

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
-- HEALTH BAR (top center, styled like the model in ServerStorage)
-- First tries to clone the HealthBar ScreenGui/Model from ServerStorage.
-- If not found, creates a custom candy-themed health bar.
-- ============================================================

local healthBarFrame = Instance.new("Frame")
healthBarFrame.Name = "HealthBar"
healthBarFrame.Size = UDim2.fromScale(0.3, 0.035)
healthBarFrame.Position = UDim2.fromScale(0.35, 0.08)
healthBarFrame.BackgroundColor3 = Color3.fromRGB(30, 15, 15)
healthBarFrame.BackgroundTransparency = 0.3
healthBarFrame.Parent = hudGui
Instance.new("UICorner", healthBarFrame).CornerRadius = UDim.new(0, 10)

local hbStroke = Instance.new("UIStroke")
hbStroke.Color = Color3.fromRGB(200, 50, 80); hbStroke.Thickness = 2
hbStroke.Parent = healthBarFrame

-- Fill bar (green → yellow → red based on health)
local healthFill = Instance.new("Frame")
healthFill.Name = "Fill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
healthFill.Parent = healthBarFrame
Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 10)

-- Health text overlay
local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.fromScale(1, 1)
healthText.BackgroundTransparency = 1
healthText.Text = "❤️ 100/100"
healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
healthText.TextScaled = true
healthText.Font = Enum.Font.FredokaOne
healthText.Parent = healthBarFrame
Instance.new("UIStroke", healthText).Color = Color3.fromRGB(0,0,0)

-- Update health bar from humanoid
local function updateHealthBar()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
	TweenService:Create(healthFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(pct, 1),
	}):Play()

	-- Color: green → yellow → red
	local color
	if pct > 0.5 then
		local t = (pct - 0.5) * 2
		color = Color3.fromRGB(255 - t*175, 220, 80)
	else
		local t = pct * 2
		color = Color3.fromRGB(220, t*220, 80 * t)
	end
	TweenService:Create(healthFill, TweenInfo.new(0.3), {BackgroundColor3 = color}):Play()
	healthText.Text = "❤️ " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
end

local function hookHealthBar(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		hum.HealthChanged:Connect(updateHealthBar)
		updateHealthBar()
	end
end

if player.Character then hookHealthBar(player.Character) end
player.CharacterAdded:Connect(hookHealthBar)

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

-- Sync candy balance from server
candyUpdateEvent.OnClientEvent:Connect(function(newBalance)
	candiesCollected = newBalance
	candyLabel.Text = "🍬 " .. candiesCollected
end)

-- Purchase feedback
purchaseEvent.OnClientEvent:Connect(function(status, itemName, price, balance)
	if status == "success" then
		-- Green flash + text
		local msg = Instance.new("TextLabel")
		msg.Size = UDim2.fromScale(0.3, 0.06)
		msg.Position = UDim2.fromScale(0.35, 0.45)
		msg.BackgroundColor3 = Color3.fromRGB(30, 100, 40)
		msg.BackgroundTransparency = 0.3
		msg.Text = "✅ Bought " .. itemName .. "! (-" .. price .. " 🍬)"
		msg.TextColor3 = Color3.fromRGB(100, 255, 120)
		msg.TextScaled = true; msg.Font = Enum.Font.FredokaOne
		msg.Parent = hudGui
		Instance.new("UICorner", msg).CornerRadius = UDim.new(0, 10)
		TweenService:Create(msg, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.35, 0.38),
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
		task.delay(2.2, function() msg:Destroy() end)
	elseif status == "fail" then
		-- Red flash
		local msg = Instance.new("TextLabel")
		msg.Size = UDim2.fromScale(0.3, 0.06)
		msg.Position = UDim2.fromScale(0.35, 0.45)
		msg.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
		msg.BackgroundTransparency = 0.3
		msg.Text = "❌ Need " .. price .. " 🍬 for " .. itemName .. " (have " .. balance .. ")"
		msg.TextColor3 = Color3.fromRGB(255, 100, 100)
		msg.TextScaled = true; msg.Font = Enum.Font.FredokaOne
		msg.Parent = hudGui
		Instance.new("UICorner", msg).CornerRadius = UDim.new(0, 10)
		TweenService:Create(msg, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.35, 0.38),
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
		task.delay(2.7, function() msg:Destroy() end)
	end
end)

-- ============================================================
-- DAILY SPIN RESULT
-- ============================================================

-- ============================================================
-- DAILY SPIN GUI
-- ============================================================

local spinRequestEvent = ReplicatedStorage:WaitForChild("SpinRequest", 10)

if dailySpinEvent then
	local spinGuiOpen = false
	local spinGui = nil

	local SPIN_REWARDS_CLIENT = {
		{name = "50 Candy", icon = "🍬", color = Color3.fromRGB(255, 200, 50)},
		{name = "2x Speed 15m", icon = "⚡", color = Color3.fromRGB(80, 200, 255)},
		{name = "25 Candy", icon = "🍬", color = Color3.fromRGB(200, 255, 100)},
		{name = "Low Gravity 10m", icon = "🌀", color = Color3.fromRGB(180, 80, 255)},
		{name = "100 Candy", icon = "💰", color = Color3.fromRGB(255, 215, 0)},
		{name = "Trail: Rainbow", icon = "🌈", color = Color3.fromRGB(255, 100, 200)},
		{name = "500 Candy", icon = "💎", color = Color3.fromRGB(100, 255, 255)},
		{name = "JACKPOT: VIP", icon = "👑", color = Color3.fromRGB(255, 50, 50)},
	}

	local function createSpinGui()
		if spinGui then spinGui:Destroy() end

		spinGui = Instance.new("ScreenGui")
		spinGui.Name = "DailySpinGui"; spinGui.IgnoreGuiInset = true
		spinGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; spinGui.Parent = playerGui

		-- Dark overlay
		local overlay = Instance.new("Frame"); overlay.Size = UDim2.fromScale(1,1)
		overlay.BackgroundColor3 = Color3.fromRGB(0,0,0); overlay.BackgroundTransparency = 0.45
		overlay.ZIndex = 100; overlay.Parent = spinGui

		-- Main popup (large, takes most of the screen)
		local popup = Instance.new("Frame"); popup.Name = "Popup"
		popup.Size = UDim2.fromScale(0.65, 0.88)
		popup.AnchorPoint = Vector2.new(0.5, 0.5)
		popup.Position = UDim2.fromScale(0.5, 0.5)
		popup.BackgroundColor3 = Color3.fromRGB(35, 10, 55); popup.BorderSizePixel = 0
		popup.ZIndex = 101; popup.Parent = spinGui
		Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 24)
		local pStroke = Instance.new("UIStroke"); pStroke.Color = Color3.fromRGB(255,180,50)
		pStroke.Thickness = 4; pStroke.Parent = popup

		-- Title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.fromScale(0.7, 0.06)
		title.AnchorPoint = Vector2.new(0.5, 0)
		title.Position = UDim2.fromScale(0.5, 0.015)
		title.BackgroundTransparency = 1
		title.Text = "🎡 DAILY SPIN 🎡"
		title.TextColor3 = Color3.fromRGB(255,220,80); title.TextScaled = true
		title.Font = Enum.Font.FredokaOne; title.ZIndex = 102; title.Parent = popup
		Instance.new("UIStroke", title).Color = Color3.fromRGB(200,140,20)

		-- Close button (red X)
		local closeBtn = Instance.new("TextButton")
		closeBtn.Size = UDim2.fromOffset(40, 40)
		closeBtn.Position = UDim2.new(1, -48, 0, 8)
		closeBtn.BackgroundColor3 = Color3.fromRGB(200,40,40); closeBtn.Text = "✕"
		closeBtn.TextColor3 = Color3.fromRGB(255,255,255); closeBtn.TextSize = 24
		closeBtn.Font = Enum.Font.GothamBold; closeBtn.ZIndex = 103; closeBtn.Parent = popup
		Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 20)
		closeBtn.MouseButton1Click:Connect(function()
			spinGui:Destroy(); spinGui = nil; spinGuiOpen = false
		end)

		-- ========== BIG WHEEL (takes up most of the popup) ==========
		-- Square container for the wheel
		local wheelContainer = Instance.new("Frame"); wheelContainer.Name = "WheelContainer"
		wheelContainer.Size = UDim2.fromScale(0.72, 0.72)
		wheelContainer.AnchorPoint = Vector2.new(0.5, 0)
		wheelContainer.Position = UDim2.fromScale(0.5, 0.08)
		wheelContainer.BackgroundTransparency = 1; wheelContainer.ZIndex = 102
		wheelContainer.SizeConstraint = Enum.SizeConstraint.RelativeXX -- square based on width
		wheelContainer.Parent = popup

		-- Outer rim ring (static, gold circle behind the wheel)
		local outerRing = Instance.new("Frame")
		outerRing.Size = UDim2.fromScale(1.06, 1.06)
		outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
		outerRing.Position = UDim2.fromScale(0.5, 0.5)
		outerRing.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		outerRing.ZIndex = 102; outerRing.Parent = wheelContainer
		Instance.new("UICorner", outerRing).CornerRadius = UDim.new(1, 0)

		-- Wheel disc background (static, darker circle)
		local discBg = Instance.new("Frame")
		discBg.Size = UDim2.fromScale(0.97, 0.97)
		discBg.AnchorPoint = Vector2.new(0.5, 0.5)
		discBg.Position = UDim2.fromScale(0.5, 0.5)
		discBg.BackgroundColor3 = Color3.fromRGB(30, 10, 45)
		discBg.ZIndex = 103; discBg.Parent = wheelContainer
		Instance.new("UICorner", discBg).CornerRadius = UDim.new(1, 0)

		-- Rotating part (segments + labels spin inside)
		local wheelRotator = Instance.new("Frame"); wheelRotator.Name = "WheelRotator"
		wheelRotator.Size = UDim2.fromScale(0.94, 0.94)
		wheelRotator.AnchorPoint = Vector2.new(0.5, 0.5)
		wheelRotator.Position = UDim2.fromScale(0.5, 0.5)
		wheelRotator.BackgroundTransparency = 1; wheelRotator.ZIndex = 104
		wheelRotator.Parent = wheelContainer

		-- Build wide wedge segments with icon + reward name text
		local numSegs = #SPIN_REWARDS_CLIENT
		local segAngle = 360 / numSegs
		for i, rw in ipairs(SPIN_REWARDS_CLIENT) do
			local angle = (i - 1) * segAngle

			-- Each segment = wide colored bar radiating from center
			-- Width = proportional to the arc at that radius
			local segFrame = Instance.new("Frame")
			segFrame.Size = UDim2.fromScale(0.22, 0.46) -- wide enough for text
			segFrame.AnchorPoint = Vector2.new(0.5, 1)
			segFrame.Position = UDim2.fromScale(0.5, 0.5)
			segFrame.Rotation = angle
			segFrame.BackgroundColor3 = rw.color; segFrame.BorderSizePixel = 0
			segFrame.ZIndex = 105; segFrame.Parent = wheelRotator
			Instance.new("UICorner", segFrame).CornerRadius = UDim.new(0, 6)

			-- Dark border between segments
			local segStroke = Instance.new("UIStroke")
			segStroke.Color = Color3.fromRGB(25, 8, 40); segStroke.Thickness = 1.5
			segStroke.Parent = segFrame

			-- Icon (top of segment, near rim)
			local iconLbl = Instance.new("TextLabel")
			iconLbl.Size = UDim2.fromScale(1, 0.3)
			iconLbl.Position = UDim2.fromScale(0, 0.02)
			iconLbl.BackgroundTransparency = 1; iconLbl.Text = rw.icon
			iconLbl.TextScaled = true; iconLbl.Font = Enum.Font.FredokaOne
			iconLbl.TextColor3 = Color3.fromRGB(255,255,255)
			iconLbl.ZIndex = 106; iconLbl.Parent = segFrame

			-- Reward name text (below icon, written into the segment)
			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.fromScale(0.95, 0.55)
			nameLbl.Position = UDim2.fromScale(0.025, 0.32)
			nameLbl.BackgroundTransparency = 1; nameLbl.Text = rw.name
			nameLbl.TextScaled = true; nameLbl.Font = Enum.Font.FredokaOne
			nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
			nameLbl.TextWrapped = true; nameLbl.ZIndex = 106; nameLbl.Parent = segFrame
			local nameStroke = Instance.new("UIStroke")
			nameStroke.Color = Color3.fromRGB(0,0,0); nameStroke.Thickness = 1.5
			nameStroke.Parent = nameLbl
		end

		-- Center hub (gold circle)
		local hub = Instance.new("Frame")
		hub.Size = UDim2.fromScale(0.14, 0.14)
		hub.AnchorPoint = Vector2.new(0.5, 0.5)
		hub.Position = UDim2.fromScale(0.5, 0.5)
		hub.BackgroundColor3 = Color3.fromRGB(255, 215, 0); hub.ZIndex = 108
		hub.Parent = wheelContainer
		Instance.new("UICorner", hub).CornerRadius = UDim.new(1, 0)
		local hubStroke = Instance.new("UIStroke")
		hubStroke.Color = Color3.fromRGB(180, 140, 30); hubStroke.Thickness = 3
		hubStroke.Parent = hub
		local hubText = Instance.new("TextLabel")
		hubText.Size = UDim2.fromScale(1,1); hubText.BackgroundTransparency = 1
		hubText.Text = "SPIN"; hubText.TextColor3 = Color3.fromRGB(80, 40, 10)
		hubText.TextScaled = true; hubText.Font = Enum.Font.FredokaOne
		hubText.ZIndex = 109; hubText.Parent = hub

		-- Pointer (red arrow at top, static, outside the wheel)
		local pointerFrame = Instance.new("Frame")
		pointerFrame.Size = UDim2.fromOffset(40, 50)
		pointerFrame.AnchorPoint = Vector2.new(0.5, 1)
		pointerFrame.Position = UDim2.fromScale(0.5, 0.01)
		pointerFrame.BackgroundTransparency = 1; pointerFrame.ZIndex = 110
		pointerFrame.Parent = wheelContainer
		local pointerLbl = Instance.new("TextLabel")
		pointerLbl.Size = UDim2.fromScale(1,1); pointerLbl.BackgroundTransparency = 1
		pointerLbl.Text = "🔻"; pointerLbl.TextScaled = true
		pointerLbl.Font = Enum.Font.GothamBold; pointerLbl.ZIndex = 110
		pointerLbl.Parent = pointerFrame

		-- ========== IDLE ROTATION ==========
		local idleConnection
		local wheelAngle = 0
		idleConnection = RunService.Heartbeat:Connect(function(dt)
			if not spinGui or not spinGui.Parent then
				if idleConnection then idleConnection:Disconnect() end; return
			end
			wheelAngle = (wheelAngle + dt * 12) % 360
			wheelRotator.Rotation = wheelAngle
		end)

		-- ========== BUTTONS ==========
		local btnFrame = Instance.new("Frame")
		btnFrame.Size = UDim2.fromScale(0.85, 0.1)
		btnFrame.AnchorPoint = Vector2.new(0.5, 0)
		btnFrame.Position = UDim2.fromScale(0.5, 0.87)
		btnFrame.BackgroundTransparency = 1; btnFrame.ZIndex = 102; btnFrame.Parent = popup

		local freeBtn = Instance.new("TextButton")
		freeBtn.Size = UDim2.fromScale(0.47, 1)
		freeBtn.Position = UDim2.fromScale(0, 0)
		freeBtn.BackgroundColor3 = Color3.fromRGB(60, 190, 70)
		freeBtn.Text = "🎁 Free Spin"; freeBtn.TextColor3 = Color3.fromRGB(255,255,255)
		freeBtn.TextScaled = true; freeBtn.Font = Enum.Font.FredokaOne
		freeBtn.ZIndex = 103; freeBtn.Parent = btnFrame
		Instance.new("UICorner", freeBtn).CornerRadius = UDim.new(0, 16)
		Instance.new("UIStroke", freeBtn).Color = Color3.fromRGB(40, 140, 40)

		local paidBtn = Instance.new("TextButton")
		paidBtn.Size = UDim2.fromScale(0.47, 1)
		paidBtn.Position = UDim2.fromScale(0.53, 0)
		paidBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 40)
		paidBtn.Text = "💎 Spin (R$49)"; paidBtn.TextColor3 = Color3.fromRGB(255,255,255)
		paidBtn.TextScaled = true; paidBtn.Font = Enum.Font.FredokaOne
		paidBtn.ZIndex = 103; paidBtn.Parent = btnFrame
		Instance.new("UICorner", paidBtn).CornerRadius = UDim.new(0, 16)
		Instance.new("UIStroke", paidBtn).Color = Color3.fromRGB(200, 120, 20)

		-- Result bar (hidden until spin)
		local resultFrame = Instance.new("Frame"); resultFrame.Name = "ResultFrame"
		resultFrame.Size = UDim2.fromScale(0.85, 0.06)
		resultFrame.AnchorPoint = Vector2.new(0.5, 0)
		resultFrame.Position = UDim2.fromScale(0.5, 0.8)
		resultFrame.BackgroundColor3 = Color3.fromRGB(25, 8, 40); resultFrame.BackgroundTransparency = 0.2
		resultFrame.Visible = false; resultFrame.ZIndex = 102; resultFrame.Parent = popup
		Instance.new("UICorner", resultFrame).CornerRadius = UDim.new(0, 12)
		local resultLbl = Instance.new("TextLabel")
		resultLbl.Size = UDim2.fromScale(1,1); resultLbl.BackgroundTransparency = 1
		resultLbl.TextColor3 = Color3.fromRGB(255,220,80); resultLbl.TextScaled = true
		resultLbl.Font = Enum.Font.FredokaOne; resultLbl.ZIndex = 103; resultLbl.Parent = resultFrame

		-- Confetti
		local function showConfetti()
			for ci = 1, 50 do
				local c = Instance.new("TextLabel")
				c.Text = ({"🍬","🎉","✨","⭐","🌈","💎","🎊","🏆"})[math.random(1,8)]
				c.TextSize = math.random(18, 34); c.BackgroundTransparency = 1
				c.Size = UDim2.fromOffset(34,34)
				c.Position = UDim2.fromScale(0.5, 0.45); c.ZIndex = 112; c.Parent = popup
				local a = math.random() * math.pi * 2
				local d = math.random(20, 50) / 100
				TweenService:Create(c, TweenInfo.new(math.random(10,18)/10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.fromScale(0.5+math.cos(a)*d, 0.45+math.sin(a)*d),
					TextTransparency = 1, Rotation = math.random(-360,360),
				}):Play()
				task.delay(2.5, function() if c then c:Destroy() end end)
			end
		end

		-- Win sound
		local winSound = Instance.new("Sound")
		winSound.SoundId = "rbxassetid://5619828673"; winSound.Volume = 1.5; winSound.Parent = playerGui

		-- Tick sound
		local tickSound = Instance.new("Sound")
		tickSound.SoundId = "rbxassetid://6732690176"; tickSound.Volume = 0.6; tickSound.Parent = playerGui

		-- ========== SPIN ANIMATION ==========
		local spinning = false
		local function doSpinAnimation(winIdx, rewardName, rewardIcon)
			if spinning then return end
			spinning = true
			freeBtn.Active = false; freeBtn.BackgroundTransparency = 0.5
			paidBtn.Active = false; paidBtn.BackgroundTransparency = 0.5
			resultFrame.Visible = false

			if idleConnection then idleConnection:Disconnect(); idleConnection = nil end

			local segDeg = 360 / #SPIN_REWARDS_CLIENT
			local targetAngle = (winIdx - 1) * segDeg + segDeg / 2
			local startAngle = wheelAngle
			local totalSpin = math.random(6, 9) * 360 + targetAngle
			local duration = 5.5
			local startT = tick()
			local lastSegIdx = -1

			while true do
				local elapsed = tick() - startT
				if elapsed >= duration then break end
				local t = elapsed / duration
				local eased = 1 - (1 - t) ^ 4 -- quartic for smoother deceleration
				wheelAngle = startAngle + totalSpin * eased
				wheelRotator.Rotation = wheelAngle

				-- Tick sound on segment change
				local segIdx = math.floor(wheelAngle / segDeg) % #SPIN_REWARDS_CLIENT
				if segIdx ~= lastSegIdx then
					lastSegIdx = segIdx
					tickSound:Play()
				end
				task.wait(0.016)
			end

			wheelAngle = startAngle + totalSpin
			wheelRotator.Rotation = wheelAngle

			-- Settle wobble
			for w = 1, 3 do
				local amt = 4 / w
				TweenService:Create(wheelRotator, TweenInfo.new(0.12, Enum.EasingStyle.Sine), {
					Rotation = wheelAngle + amt
				}):Play(); task.wait(0.12)
				TweenService:Create(wheelRotator, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
					Rotation = wheelAngle - amt * 0.4
				}):Play(); task.wait(0.15)
			end
			TweenService:Create(wheelRotator, TweenInfo.new(0.1), {Rotation = wheelAngle}):Play()
			task.wait(0.15)

			-- Show result
			resultFrame.Visible = true
			resultLbl.Text = rewardIcon .. " You won: " .. rewardName .. "! " .. rewardIcon
			winSound:Play(); showConfetti()

			task.delay(2.5, function()
				spinning = false
				if freeBtn and freeBtn.Parent then
					freeBtn.Active = true; freeBtn.BackgroundTransparency = 0
					paidBtn.Active = true; paidBtn.BackgroundTransparency = 0
				end
				if spinGui and spinGui.Parent and not idleConnection then
					idleConnection = RunService.Heartbeat:Connect(function(dt)
						if not spinGui or not spinGui.Parent then
							if idleConnection then idleConnection:Disconnect() end; return
						end
						wheelAngle = (wheelAngle + dt * 12) % 360
						wheelRotator.Rotation = wheelAngle
					end)
				end
			end)
		end

		freeBtn.MouseButton1Click:Connect(function()
			if spinning then return end
			if spinRequestEvent then spinRequestEvent:FireServer("free") end
		end)
		paidBtn.MouseButton1Click:Connect(function()
			if spinning then return end
			if spinRequestEvent then spinRequestEvent:FireServer("paid") end
		end)

		return {doSpinAnimation = doSpinAnimation}
	end

	-- Handle server messages
	local guiHandlers = nil
	dailySpinEvent.OnClientEvent:Connect(function(msgType, ...)
		if msgType == "open" then
			-- Open the GUI
			if not spinGuiOpen then
				spinGuiOpen = true
				guiHandlers = createSpinGui()
			end
		elseif msgType == "result" then
			-- Spin result from server
			local winIdx, rewardName, rewardIcon = ...
			if guiHandlers and guiHandlers.doSpinAnimation then
				guiHandlers.doSpinAnimation(winIdx, rewardName, rewardIcon)
			else
				-- GUI not open, show quick notification
				local msg = Instance.new("TextLabel")
				msg.Size = UDim2.fromScale(0.4, 0.1)
				msg.Position = UDim2.fromScale(0.3, 0.35)
				msg.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
				msg.BackgroundTransparency = 0.15
				msg.Text = "🎡 " .. (rewardIcon or "🎁") .. " " .. (rewardName or "Prize") .. "! 🎡"
				msg.TextColor3 = Color3.fromRGB(255, 220, 80)
				msg.TextScaled = true; msg.Font = Enum.Font.FredokaOne
				msg.Parent = hudGui
				Instance.new("UICorner", msg).CornerRadius = UDim.new(0, 14)
				task.delay(3, function()
					TweenService:Create(msg, TweenInfo.new(1), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
					task.delay(1.2, function() msg:Destroy() end)
				end)
			end
		elseif msgType == "cooldown" then
			local timeLeft = ...
			if spinGui and spinGui.Parent then
				-- Show cooldown in the GUI
				local popup = spinGui:FindFirstChild("Popup")
				if popup then
					local rf = popup:FindFirstChild("ResultFrame")
					if rf then
						rf.Visible = true
						rf:FindFirstChildWhichIsA("TextLabel").Text = "⏰ Next free spin in: " .. (timeLeft or "?")
					end
				end
			end
		end
	end)
end

-- ============================================================
-- TRAIL SPIN RESULT
-- ============================================================

if trailSpinResultEvent then
	trailSpinResultEvent.OnClientEvent:Connect(function(trailName, colorRGB)
		local msg = Instance.new("TextLabel")
		msg.Size = UDim2.fromScale(0.35, 0.07)
		msg.Position = UDim2.fromScale(0.325, 0.48)
		msg.BackgroundColor3 = Color3.fromRGB(50, 30, 20)
		msg.BackgroundTransparency = 0.2
		msg.Text = "🎁 Trail: " .. (trailName or "???") .. "!"
		msg.TextColor3 = Color3.fromRGB(255, 200, 150)
		msg.TextScaled = true; msg.Font = Enum.Font.FredokaOne
		msg.Parent = hudGui
		Instance.new("UICorner", msg).CornerRadius = UDim.new(0, 10)

		TweenService:Create(msg, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.325, 0.4),
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
		task.delay(2.7, function() msg:Destroy() end)
	end)
end

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
