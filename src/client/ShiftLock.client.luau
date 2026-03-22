--[[
	Candy Run - Shift Lock Toggle
	Press Left Shift to toggle mouse-lock (third-person over-shoulder camera).
	Shows a small UI indicator when shift lock is active.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- ============================================================
-- STATE
-- ============================================================

local shiftLocked = false
local SHIFT_LOCK_OFFSET = Vector3.new(2, 0.6, 0)  -- over-right-shoulder

-- ============================================================
-- SHIFT LOCK INDICATOR UI
-- ============================================================

local indicatorGui = Instance.new("ScreenGui")
indicatorGui.Name = "ShiftLockIndicator"
indicatorGui.ResetOnSpawn = false
indicatorGui.IgnoreGuiInset = false
indicatorGui.Parent = playerGui

local indicator = Instance.new("Frame")
indicator.Size = UDim2.fromScale(0.06, 0.04)
indicator.Position = UDim2.fromScale(0.02, 0.02)
indicator.BackgroundColor3 = Color3.fromRGB(30, 15, 40)
indicator.BackgroundTransparency = 0.5
indicator.Visible = false
indicator.Parent = indicatorGui

Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 8)

local indicatorStroke = Instance.new("UIStroke")
indicatorStroke.Color = Color3.fromRGB(255, 150, 200)
indicatorStroke.Thickness = 1.5
indicatorStroke.Parent = indicator

local indicatorLabel = Instance.new("TextLabel")
indicatorLabel.Size = UDim2.fromScale(0.9, 0.8)
indicatorLabel.Position = UDim2.fromScale(0.05, 0.1)
indicatorLabel.BackgroundTransparency = 1
indicatorLabel.Text = "🔒 Shift Lock"
indicatorLabel.TextColor3 = Color3.fromRGB(255, 200, 230)
indicatorLabel.TextScaled = true
indicatorLabel.Font = Enum.Font.GothamBold
indicatorLabel.Parent = indicator

-- Pop-in animation helper
local function showIndicator()
	indicator.Visible = true
	indicator.Size = UDim2.fromScale(0.03, 0.02)
	TweenService:Create(indicator, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.06, 0.04),
	}):Play()
	TweenService:Create(indicatorStroke, TweenInfo.new(0.2), {
		Color = Color3.fromRGB(100, 255, 150),
	}):Play()
end

local function hideIndicator()
	TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromScale(0.03, 0.02),
	}):Play()
	TweenService:Create(indicatorStroke, TweenInfo.new(0.2), {
		Color = Color3.fromRGB(255, 150, 200),
	}):Play()
	task.delay(0.2, function()
		if not shiftLocked then
			indicator.Visible = false
		end
	end)
end

-- ============================================================
-- TOGGLE ON SHIFT PRESS
-- ============================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		shiftLocked = not shiftLocked

		if shiftLocked then
			-- Lock mouse to center
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			showIndicator()
		else
			-- Unlock mouse
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			hideIndicator()
		end
	end
end)

-- ============================================================
-- SHIFT LOCK CAMERA BEHAVIOR
-- ============================================================

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	if shiftLocked then
		-- Keep mouse locked
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

		-- Offset camera to right shoulder
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(SHIFT_LOCK_OFFSET, 0.15)

		-- Rotate character to face camera direction
		local cameraLook = camera.CFrame.LookVector
		local flatLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit

		if flatLook.Magnitude > 0.1 then
			local targetCF = CFrame.lookAt(rootPart.Position, rootPart.Position + flatLook)
			rootPart.CFrame = rootPart.CFrame:Lerp(targetCF, 0.2)
		end
	else
		-- Let the character script handle camera offset (smooth bob etc.)
		-- Don't override here — the character script lerps CameraOffset
	end
end)

-- Reset mouse behavior when character respawns
player.CharacterAdded:Connect(function()
	if not shiftLocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

print("[CandyRun] Shift Lock loaded! Press Left Shift to toggle.")
