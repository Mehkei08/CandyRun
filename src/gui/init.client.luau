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
titleMusic.SoundId = "rbxassetid://1848354536"  -- Upbeat whistling happy tune
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
-- MENU BUTTON HELPER
-- ============================================================

local function createMenuButton(text, color, strokeColor, hoverColor, hoverStroke, yPos, delay_time)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(0, 0)
	btn.Position = UDim2.fromScale(0.5, yPos)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true; btn.Font = Enum.Font.FredokaOne
	btn.BorderSizePixel = 0; btn.AutoButtonColor = false
	btn.Parent = screenGui

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 18)

	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor; stroke.Thickness = 3
	stroke.Parent = btn

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = btn

	task.delay(delay_time, function()
		TweenService:Create(btn, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.28, 0.075),
		}):Play()
	end)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = hoverColor,
			Size = UDim2.fromScale(0.31, 0.082),
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.25), {Color = hoverStroke}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			BackgroundColor3 = color,
			Size = UDim2.fromScale(0.28, 0.075),
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.25), {Color = strokeColor}):Play()
	end)

	return btn
end

-- ============================================================
-- PLAY BUTTON
-- ============================================================

local playButton = createMenuButton(
	"🍭  PLAY  🍭",
	Color3.fromRGB(80, 220, 120), Color3.fromRGB(40, 180, 80),
	Color3.fromRGB(100, 255, 150), Color3.fromRGB(60, 200, 100),
	0.46, 0.8
)

-- Play button breathe animation
task.delay(1.5, function()
	while playButton and playButton.Parent do
		TweenService:Create(playButton, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = UDim2.fromScale(0.30, 0.08),
		}):Play()
		task.wait(1)
		TweenService:Create(playButton, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = UDim2.fromScale(0.28, 0.075),
		}):Play()
		task.wait(1)
	end
end)

-- ============================================================
-- SHOP BUTTON
-- ============================================================

local shopButton = createMenuButton(
	"🛒  SHOP  🛒",
	Color3.fromRGB(220, 160, 40), Color3.fromRGB(180, 120, 20),
	Color3.fromRGB(255, 200, 60), Color3.fromRGB(200, 150, 30),
	0.56, 1.0
)

-- ============================================================
-- CREDITS BUTTON
-- ============================================================

local creditsButton = createMenuButton(
	"⭐  CREDITS  ⭐",
	Color3.fromRGB(160, 80, 220), Color3.fromRGB(120, 50, 180),
	Color3.fromRGB(190, 110, 255), Color3.fromRGB(150, 70, 210),
	0.66, 1.2
)

-- ============================================================
-- SHOP SCREEN
-- ============================================================

local purchaseEvent = ReplicatedStorage:WaitForChild("PurchaseItem", 10)

-- Shop items: items you can buy with candy (matches server ITEM_PRICES)
local SHOP_ITEMS = {
	{name = "Speed Coil", price = 5, icon = "⚡", desc = "Run 2x faster!"},
	{name = "Gravity Coil", price = 8, icon = "🌀", desc = "Float with low gravity!"},
	{name = "Fusion Coil", price = 15, icon = "💫", desc = "Speed + gravity combined!"},
	{name = "Grapple Gun", price = 12, icon = "🪝", desc = "Swing between candies!"},
	{name = "Magic Carpet", price = 20, icon = "🧞", desc = "Fly on a magic carpet!"},
}

-- Gamepasses: real Roblox gamepasses (placeholder IDs — replace with real ones)
local GAMEPASSES = {
	{name = "Boombox", passId = 0, price = "R$ 29", icon = "📻", desc = "Get a boombox to play any song!"},
	{name = "2x Candy", passId = 0, price = "R$ 49", icon = "🍬", desc = "Earn double candy forever!"},
	{name = "VIP", passId = 0, price = "R$ 99", icon = "👑", desc = "VIP badge + golden trail!"},
}

local shopGui = Instance.new("ScreenGui")
shopGui.Name = "ShopScreen"
shopGui.ResetOnSpawn = false
shopGui.IgnoreGuiInset = true
shopGui.Enabled = false
shopGui.Parent = playerGui

-- Shop backdrop
local shopBg = Instance.new("Frame")
shopBg.Size = UDim2.fromScale(1, 1)
shopBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shopBg.BackgroundTransparency = 0.35
shopBg.Parent = shopGui

-- Shop panel
local shopPanel = Instance.new("Frame")
shopPanel.Size = UDim2.fromScale(0.7, 0.8)
shopPanel.Position = UDim2.fromScale(0.15, 0.1)
shopPanel.BackgroundColor3 = Color3.fromRGB(40, 20, 50)
shopPanel.BackgroundTransparency = 0.1
shopPanel.Parent = shopGui
Instance.new("UICorner", shopPanel).CornerRadius = UDim.new(0, 20)

local shopPanelStroke = Instance.new("UIStroke")
shopPanelStroke.Color = Color3.fromRGB(255, 200, 60); shopPanelStroke.Thickness = 3
shopPanelStroke.Parent = shopPanel

local shopPanelGradient = Instance.new("UIGradient")
shopPanelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 25, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 15, 45)),
})
shopPanelGradient.Rotation = 90
shopPanelGradient.Parent = shopPanel

-- Shop title
local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.fromScale(0.6, 0.08)
shopTitle.Position = UDim2.fromScale(0.2, 0.01)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "🛒 CANDY SHOP 🛒"
shopTitle.TextColor3 = Color3.fromRGB(255, 220, 80)
shopTitle.TextScaled = true; shopTitle.Font = Enum.Font.FredokaOne
shopTitle.Parent = shopPanel

local shopTitleStroke = Instance.new("UIStroke")
shopTitleStroke.Color = Color3.fromRGB(200, 140, 20); shopTitleStroke.Thickness = 2
shopTitleStroke.Parent = shopTitle

-- Close button
local shopClose = Instance.new("TextButton")
shopClose.Size = UDim2.fromScale(0.06, 0.06)
shopClose.Position = UDim2.fromScale(0.92, 0.01)
shopClose.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
shopClose.Text = "✕"
shopClose.TextColor3 = Color3.fromRGB(255, 255, 255)
shopClose.TextScaled = true; shopClose.Font = Enum.Font.FredokaOne
shopClose.AutoButtonColor = false
shopClose.Parent = shopPanel
Instance.new("UICorner", shopClose).CornerRadius = UDim.new(0, 10)

shopClose.MouseButton1Click:Connect(function()
	shopGui.Enabled = false
end)

-- Items section header
local itemsHeader = Instance.new("TextLabel")
itemsHeader.Size = UDim2.fromScale(0.9, 0.05)
itemsHeader.Position = UDim2.fromScale(0.05, 0.1)
itemsHeader.BackgroundTransparency = 1
itemsHeader.Text = "🍬 ITEMS (Buy with Candy)"
itemsHeader.TextColor3 = Color3.fromRGB(255, 180, 255)
itemsHeader.TextScaled = true; itemsHeader.Font = Enum.Font.GothamBold
itemsHeader.TextXAlignment = Enum.TextXAlignment.Left
itemsHeader.Parent = shopPanel

-- Items scroll frame
local itemsScroll = Instance.new("ScrollingFrame")
itemsScroll.Size = UDim2.fromScale(0.9, 0.35)
itemsScroll.Position = UDim2.fromScale(0.05, 0.16)
itemsScroll.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
itemsScroll.BackgroundTransparency = 0.5
itemsScroll.ScrollBarThickness = 6
itemsScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 60)
itemsScroll.CanvasSize = UDim2.fromScale(0, 0)
itemsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemsScroll.Parent = shopPanel
Instance.new("UICorner", itemsScroll).CornerRadius = UDim.new(0, 12)

local itemsLayout = Instance.new("UIListLayout")
itemsLayout.Padding = UDim.new(0, 6)
itemsLayout.FillDirection = Enum.FillDirection.Vertical
itemsLayout.Parent = itemsScroll

local itemsPad = Instance.new("UIPadding")
itemsPad.PaddingTop = UDim.new(0, 6); itemsPad.PaddingBottom = UDim.new(0, 6)
itemsPad.PaddingLeft = UDim.new(0, 6); itemsPad.PaddingRight = UDim.new(0, 6)
itemsPad.Parent = itemsScroll

for _, item in ipairs(SHOP_ITEMS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(50, 30, 65)
	row.BackgroundTransparency = 0.3
	row.Parent = itemsScroll
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromOffset(44, 44)
	icon.Position = UDim2.fromOffset(6, 6)
	icon.BackgroundTransparency = 1
	icon.Text = item.icon; icon.TextScaled = true
	icon.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 160, 0, 24)
	nameLabel.Position = UDim2.fromOffset(56, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true; nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0, 240, 0, 20)
	descLabel.Position = UDim2.fromOffset(56, 28)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = item.desc
	descLabel.TextColor3 = Color3.fromRGB(200, 180, 220)
	descLabel.TextScaled = true; descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = row

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 110, 0, 36)
	buyBtn.Position = UDim2.new(1, -120, 0.5, -18)
	buyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 100)
	buyBtn.Text = "🍬 " .. item.price
	buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.TextScaled = true; buyBtn.Font = Enum.Font.FredokaOne
	buyBtn.AutoButtonColor = false
	buyBtn.Parent = row
	Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 240, 130)}):Play()
	end)
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 200, 100)}):Play()
	end)

	buyBtn.MouseButton1Click:Connect(function()
		if purchaseEvent then
			purchaseEvent:FireServer(item.name)
		end
		-- Flash feedback
		TweenService:Create(buyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 255, 100)}):Play()
		task.wait(0.15)
		TweenService:Create(buyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 200, 100)}):Play()
	end)
end

-- Gamepasses section header
local passHeader = Instance.new("TextLabel")
passHeader.Size = UDim2.fromScale(0.9, 0.05)
passHeader.Position = UDim2.fromScale(0.05, 0.53)
passHeader.BackgroundTransparency = 1
passHeader.Text = "👑 GAMEPASSES (Robux)"
passHeader.TextColor3 = Color3.fromRGB(255, 220, 100)
passHeader.TextScaled = true; passHeader.Font = Enum.Font.GothamBold
passHeader.TextXAlignment = Enum.TextXAlignment.Left
passHeader.Parent = shopPanel

-- Gamepasses scroll frame
local passScroll = Instance.new("ScrollingFrame")
passScroll.Size = UDim2.fromScale(0.9, 0.35)
passScroll.Position = UDim2.fromScale(0.05, 0.59)
passScroll.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
passScroll.BackgroundTransparency = 0.5
passScroll.ScrollBarThickness = 6
passScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 60)
passScroll.CanvasSize = UDim2.fromScale(0, 0)
passScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
passScroll.Parent = shopPanel
Instance.new("UICorner", passScroll).CornerRadius = UDim.new(0, 12)

local passLayout = Instance.new("UIListLayout")
passLayout.Padding = UDim.new(0, 6)
passLayout.FillDirection = Enum.FillDirection.Vertical
passLayout.Parent = passScroll

local passPad = Instance.new("UIPadding")
passPad.PaddingTop = UDim.new(0, 6); passPad.PaddingBottom = UDim.new(0, 6)
passPad.PaddingLeft = UDim.new(0, 6); passPad.PaddingRight = UDim.new(0, 6)
passPad.Parent = passScroll

local MarketplaceService = game:GetService("MarketplaceService")

for _, pass in ipairs(GAMEPASSES) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
	row.BackgroundTransparency = 0.3
	row.Parent = passScroll
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromOffset(44, 44)
	icon.Position = UDim2.fromOffset(6, 6)
	icon.BackgroundTransparency = 1
	icon.Text = pass.icon; icon.TextScaled = true
	icon.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 160, 0, 24)
	nameLabel.Position = UDim2.fromOffset(56, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = pass.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true; nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0, 240, 0, 20)
	descLabel.Position = UDim2.fromOffset(56, 28)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = pass.desc
	descLabel.TextColor3 = Color3.fromRGB(200, 190, 160)
	descLabel.TextScaled = true; descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = row

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 110, 0, 36)
	buyBtn.Position = UDim2.new(1, -120, 0.5, -18)
	buyBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 220)
	buyBtn.Text = pass.price
	buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.TextScaled = true; buyBtn.Font = Enum.Font.FredokaOne
	buyBtn.AutoButtonColor = false
	buyBtn.Parent = row
	Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 190, 255)}):Play()
	end)
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 160, 220)}):Play()
	end)

	buyBtn.MouseButton1Click:Connect(function()
		if pass.passId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, pass.passId)
		else
			-- Placeholder: flash to show it's not yet configured
			TweenService:Create(buyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}):Play()
			task.wait(0.2)
			TweenService:Create(buyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 160, 220)}):Play()
		end
	end)
end

-- Wire shop button
shopButton.MouseButton1Click:Connect(function()
	shopGui.Enabled = true
end)

-- ============================================================
-- CREDITS SCREEN
-- ============================================================

local creditsGui = Instance.new("ScreenGui")
creditsGui.Name = "CreditsScreen"
creditsGui.ResetOnSpawn = false
creditsGui.IgnoreGuiInset = true
creditsGui.Enabled = false
creditsGui.Parent = playerGui

local creditsBg = Instance.new("Frame")
creditsBg.Size = UDim2.fromScale(1, 1)
creditsBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
creditsBg.BackgroundTransparency = 0.35
creditsBg.Parent = creditsGui

local creditsPanel = Instance.new("Frame")
creditsPanel.Size = UDim2.fromScale(0.5, 0.6)
creditsPanel.Position = UDim2.fromScale(0.25, 0.2)
creditsPanel.BackgroundColor3 = Color3.fromRGB(35, 15, 50)
creditsPanel.BackgroundTransparency = 0.05
creditsPanel.Parent = creditsGui
Instance.new("UICorner", creditsPanel).CornerRadius = UDim.new(0, 20)

local creditsPanelStroke = Instance.new("UIStroke")
creditsPanelStroke.Color = Color3.fromRGB(200, 120, 255); creditsPanelStroke.Thickness = 3
creditsPanelStroke.Parent = creditsPanel

local creditsTitle = Instance.new("TextLabel")
creditsTitle.Size = UDim2.fromScale(0.8, 0.12)
creditsTitle.Position = UDim2.fromScale(0.1, 0.03)
creditsTitle.BackgroundTransparency = 1
creditsTitle.Text = "⭐ CREDITS ⭐"
creditsTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
creditsTitle.TextScaled = true; creditsTitle.Font = Enum.Font.FredokaOne
creditsTitle.Parent = creditsPanel

local creditsTitleStroke = Instance.new("UIStroke")
creditsTitleStroke.Color = Color3.fromRGB(200, 160, 40); creditsTitleStroke.Thickness = 2
creditsTitleStroke.Parent = creditsTitle

local creditsBody = Instance.new("TextLabel")
creditsBody.Size = UDim2.fromScale(0.8, 0.6)
creditsBody.Position = UDim2.fromScale(0.1, 0.18)
creditsBody.BackgroundTransparency = 1
creditsBody.Text = "🍬 Candy Run 🍬\n\nDeveloped by: You!\n\nArt & Design: You!\n\nMusic: Roblox Library\n\nSpecial Thanks:\nEveryone who played!\n\n🍭 Thanks for playing! 🍭"
creditsBody.TextColor3 = Color3.fromRGB(230, 210, 255)
creditsBody.TextScaled = true; creditsBody.Font = Enum.Font.GothamBold
creditsBody.TextWrapped = true
creditsBody.Parent = creditsPanel

local creditsClose = Instance.new("TextButton")
creditsClose.Size = UDim2.fromScale(0.3, 0.1)
creditsClose.Position = UDim2.fromScale(0.35, 0.84)
creditsClose.BackgroundColor3 = Color3.fromRGB(160, 80, 220)
creditsClose.Text = "BACK"
creditsClose.TextColor3 = Color3.fromRGB(255, 255, 255)
creditsClose.TextScaled = true; creditsClose.Font = Enum.Font.FredokaOne
creditsClose.AutoButtonColor = false
creditsClose.Parent = creditsPanel
Instance.new("UICorner", creditsClose).CornerRadius = UDim.new(0, 12)

creditsClose.MouseButton1Click:Connect(function()
	creditsGui.Enabled = false
end)

creditsButton.MouseButton1Click:Connect(function()
	creditsGui.Enabled = true
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
statsFrame.Size = UDim2.fromScale(0.4, 0.05)
statsFrame.Position = UDim2.fromScale(0.3, 0.76)
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

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.fromScale(0.2, 0.03)
versionLabel.Position = UDim2.fromScale(0.4, 0.93)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1.1  ·  Made with 🍫"
versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
versionLabel.TextTransparency = 0.5; versionLabel.TextScaled = true
versionLabel.Font = Enum.Font.Gotham; versionLabel.Parent = screenGui

-- ============================================================
-- PLAY BUTTON CLICK → INSTANT SPAWN
-- ============================================================

local startGameEvent = ReplicatedStorage:WaitForChild("StartGame", 10)

playButton.MouseButton1Click:Connect(function()
	playButton.Active = false

	-- Close shop/credits if open
	shopGui.Enabled = false
	creditsGui.Enabled = false

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
	gameMusic.SoundId = "rbxassetid://9043887091"  -- Fun adventure music
	gameMusic.Volume = 0
	gameMusic.Looped = true
	gameMusic.PlaybackSpeed = 1
	gameMusic.Parent = SoundService
	gameMusic:Play()
	TweenService:Create(gameMusic, TweenInfo.new(1), {Volume = 0.4}):Play()

	screenGui:Destroy()
	shopGui:Destroy()
	creditsGui:Destroy()

	TweenService:Create(newFlash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	task.wait(0.7)
	transitionGui:Destroy()
end)

print("[CandyRun] Start screen loaded with music!")
