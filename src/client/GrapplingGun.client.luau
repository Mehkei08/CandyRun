--[[
	Grapple Gun - Client Controller
	When the Grapple Gun tool is equipped + activated (click/tap),
	fires GrappleShoot to server with origin + look direction.
	Visual feedback: crosshair, cooldown indicator, hit flash.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local grappleShootEvent = ReplicatedStorage:WaitForChild("GrappleShoot")
local grappleHitEvent = ReplicatedStorage:WaitForChild("GrappleHit")

-- ============================================================
-- COOLDOWN STATE
-- ============================================================

local COOLDOWN = 2
local lastFireTime = 0

-- ============================================================
-- CROSSHAIR UI (only visible when grapple gun equipped)
-- ============================================================

local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name = "GrappleCrosshair"
crosshairGui.ResetOnSpawn = false
crosshairGui.IgnoreGuiInset = false
crosshairGui.Enabled = false
crosshairGui.Parent = playerGui

local crosshair = Instance.new("TextLabel")
crosshair.Size = UDim2.fromOffset(30, 30)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.BackgroundTransparency = 1
crosshair.Text = "◎"
crosshair.TextColor3 = Color3.fromRGB(255, 80, 80)
crosshair.TextSize = 28
crosshair.Font = Enum.Font.GothamBold
crosshair.Parent = crosshairGui

local cooldownBar = Instance.new("Frame")
cooldownBar.Size = UDim2.fromScale(0.08, 0.006)
cooldownBar.Position = UDim2.fromScale(0.46, 0.54)
cooldownBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
cooldownBar.BackgroundTransparency = 0.3
cooldownBar.Parent = crosshairGui
Instance.new("UICorner", cooldownBar).CornerRadius = UDim.new(0, 3)

-- ============================================================
-- TOOL DETECTION
-- ============================================================

local grappleEquipped = false

local function onCharacterAdded(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Grapple Gun" then
			grappleEquipped = true
			crosshairGui.Enabled = true

			child.Activated:Connect(function()
				if not grappleEquipped then return end
				if tick() - lastFireTime < COOLDOWN then return end
				lastFireTime = tick()

				-- Get aim direction from camera
				local camCF = camera.CFrame
				local origin = camCF.Position + camCF.LookVector * 3
				local direction = camCF.LookVector

				-- Fire to server
				grappleShootEvent:FireServer(origin, direction)

				-- Visual feedback: crosshair flash
				crosshair.TextColor3 = Color3.fromRGB(255, 255, 100)
				TweenService:Create(crosshair, TweenInfo.new(0.3), {
					TextColor3 = Color3.fromRGB(255, 80, 80),
				}):Play()

				-- Cooldown bar animation
				cooldownBar.Size = UDim2.fromScale(0.08, 0.006)
				cooldownBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				TweenService:Create(cooldownBar, TweenInfo.new(COOLDOWN, Enum.EasingStyle.Linear), {
					Size = UDim2.fromScale(0.08, 0.006),
					BackgroundColor3 = Color3.fromRGB(255, 80, 80),
				}):Play()
				-- Shrink then grow back
				cooldownBar.Size = UDim2.fromScale(0, 0.006)
				TweenService:Create(cooldownBar, TweenInfo.new(COOLDOWN, Enum.EasingStyle.Linear), {
					Size = UDim2.fromScale(0.08, 0.006),
				}):Play()
			end)

			child.Unequipped:Connect(function()
				grappleEquipped = false
				crosshairGui.Enabled = false
			end)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Grapple Gun" then
			grappleEquipped = false
			crosshairGui.Enabled = false
		end
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

-- ============================================================
-- HIT FEEDBACK
-- ============================================================

grappleHitEvent.OnClientEvent:Connect(function(status, data)
	if status == "hit" then
		-- Screen flash on successful grapple
		local flash = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = Color3.fromRGB(255, 220, 100)
		flash.BackgroundTransparency = 0.7
		flash.ZIndex = 50
		flash.Parent = crosshairGui

		TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.5, function() flash:Destroy() end)

		-- Crosshair goes green briefly
		crosshair.TextColor3 = Color3.fromRGB(100, 255, 100)
		TweenService:Create(crosshair, TweenInfo.new(0.5), {
			TextColor3 = Color3.fromRGB(255, 80, 80),
		}):Play()
	end
end)

print("[CandyRun] Grapple Gun client controller loaded!")
