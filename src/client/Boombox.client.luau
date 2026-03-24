--[[
	Boombox Client - Song ID interface
	When the Boombox tool is equipped and LMB is clicked, opens a small UI
	to type a Roblox song ID. Sends the ID to the server to play.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local boomboxEvent = ReplicatedStorage:WaitForChild("BoomboxPlay", 10)

local boomboxEquipped = false
local boomboxUiOpen = false
local currentGui = nil

-- ============================================================
-- BUILD THE BOOMBOX UI
-- ============================================================

local function createBoomboxUI()
	if currentGui then currentGui:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BoomboxUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	-- Small centered panel
	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(0.26, 0.18)
	panel.Position = UDim2.fromScale(0.37, 0.4)
	panel.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
	panel.BackgroundTransparency = 0.05
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(255, 80, 200); panelStroke.Thickness = 2
	panelStroke.Parent = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(0.8, 0.22)
	title.Position = UDim2.fromScale(0.1, 0.02)
	title.BackgroundTransparency = 1
	title.Text = "📻 BOOMBOX"
	title.TextColor3 = Color3.fromRGB(255, 120, 220)
	title.TextScaled = true; title.Font = Enum.Font.FredokaOne
	title.Parent = panel

	-- Song ID input box
	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.fromScale(0.7, 0.25)
	inputBox.Position = UDim2.fromScale(0.05, 0.3)
	inputBox.BackgroundColor3 = Color3.fromRGB(50, 40, 60)
	inputBox.Text = ""
	inputBox.PlaceholderText = "Enter Song ID..."
	inputBox.PlaceholderColor3 = Color3.fromRGB(140, 120, 160)
	inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	inputBox.TextScaled = true; inputBox.Font = Enum.Font.GothamBold
	inputBox.ClearTextOnFocus = true
	inputBox.Parent = panel
	Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)

	-- Play button
	local playBtn = Instance.new("TextButton")
	playBtn.Size = UDim2.fromScale(0.2, 0.25)
	playBtn.Position = UDim2.fromScale(0.77, 0.3)
	playBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 100)
	playBtn.Text = "▶"
	playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	playBtn.TextScaled = true; playBtn.Font = Enum.Font.FredokaOne
	playBtn.AutoButtonColor = false
	playBtn.Parent = panel
	Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 8)

	-- Stop button
	local stopBtn = Instance.new("TextButton")
	stopBtn.Size = UDim2.fromScale(0.44, 0.22)
	stopBtn.Position = UDim2.fromScale(0.05, 0.62)
	stopBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	stopBtn.Text = "⏹ Stop"
	stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopBtn.TextScaled = true; stopBtn.Font = Enum.Font.FredokaOne
	stopBtn.AutoButtonColor = false
	stopBtn.Parent = panel
	Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromScale(0.44, 0.22)
	closeBtn.Position = UDim2.fromScale(0.53, 0.62)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 70, 100)
	closeBtn.Text = "✕ Close"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextScaled = true; closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = panel
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	-- Status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.fromScale(0.9, 0.12)
	statusLabel.Position = UDim2.fromScale(0.05, 0.87)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
	statusLabel.TextScaled = true; statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = panel

	-- Hover effects
	local function hoverEffect(btn, normalColor, hoverColor)
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normalColor}):Play()
		end)
	end
	hoverEffect(playBtn, Color3.fromRGB(80, 200, 100), Color3.fromRGB(100, 240, 130))
	hoverEffect(stopBtn, Color3.fromRGB(200, 60, 60), Color3.fromRGB(240, 80, 80))
	hoverEffect(closeBtn, Color3.fromRGB(80, 70, 100), Color3.fromRGB(110, 95, 140))

	-- Play
	playBtn.MouseButton1Click:Connect(function()
		local text = inputBox.Text:gsub("%s", "")
		local songId = tonumber(text)
		if songId and songId > 0 then
			if boomboxEvent then
				boomboxEvent:FireServer(songId)
			end
			statusLabel.Text = "🎵 Playing ID: " .. text
			statusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
			TweenService:Create(playBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 255, 100)}):Play()
			task.wait(0.15)
			TweenService:Create(playBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 200, 100)}):Play()
		else
			statusLabel.Text = "❌ Enter a valid number!"
			statusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
	end)

	-- Also play on Enter key in the text box
	inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			playBtn.MouseButton1Click:Fire()
		end
	end)

	-- Stop
	stopBtn.MouseButton1Click:Connect(function()
		if boomboxEvent then
			boomboxEvent:FireServer(0)
		end
		statusLabel.Text = "⏹ Stopped"
		statusLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
	end)

	-- Close
	closeBtn.MouseButton1Click:Connect(function()
		boomboxUiOpen = false
		gui:Destroy()
		currentGui = nil
	end)

	-- Animate in
	panel.Size = UDim2.fromScale(0, 0)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.26, 0.18),
		Position = UDim2.fromScale(0.37, 0.4),
	}):Play()

	currentGui = gui
	boomboxUiOpen = true
end

-- ============================================================
-- TOOL DETECTION
-- ============================================================

local function onCharacterAdded(char)
	-- Watch for boombox equip/unequip
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Boombox" then
			boomboxEquipped = true
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Boombox" then
			boomboxEquipped = false
			-- Close UI when unequipped
			if currentGui then
				boomboxUiOpen = false
				currentGui:Destroy()
				currentGui = nil
			end
		end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

-- Listen for Activated on any Boombox tool (fires on LMB click while equipped)
local function watchForBoombox()
	local function hookTool(tool)
		if tool:IsA("Tool") and tool.Name == "Boombox" then
			tool.Activated:Connect(function()
				if boomboxUiOpen then
					-- Toggle off
					boomboxUiOpen = false
					if currentGui then currentGui:Destroy(); currentGui = nil end
				else
					createBoomboxUI()
				end
			end)
		end
	end

	-- Hook existing tools
	for _, item in player.Backpack:GetChildren() do hookTool(item) end
	player.Backpack.ChildAdded:Connect(hookTool)

	if player.Character then
		for _, item in player.Character:GetChildren() do hookTool(item) end
		player.Character.ChildAdded:Connect(hookTool)
	end
	player.CharacterAdded:Connect(function(char)
		char.ChildAdded:Connect(hookTool)
	end)
end

watchForBoombox()

print("[CandyRun] Boombox client loaded!")
