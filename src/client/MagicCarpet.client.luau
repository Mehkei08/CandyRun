--[[
	Magic Carpet - Client Flight Controller
	Full directional flight when carpet is equipped.
	WASD = horizontal movement, Space = ascend, LeftShift (while flying) = descend
	Increased speed, smooth controls, sit animation on carpet.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local carpetFlyEvent = ReplicatedStorage:WaitForChild("CarpetFlyToggle")

local isFlying = false
local FLY_SPEED = 60        -- fast carpet
local FLY_ASCEND_SPEED = 40
local FLY_DESCEND_SPEED = 35

-- Track input
local keysDown = {}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	keysDown[input.KeyCode] = true
end)

UserInputService.InputEnded:Connect(function(input)
	keysDown[input.KeyCode] = nil
end)

-- Flight connection
local flyConnection = nil

local function startFlying()
	if isFlying then return end
	isFlying = true

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then return end

	-- Create BodyGyro to keep upright
	local gyro = Instance.new("BodyGyro")
	gyro.Name = "CarpetGyro"
	gyro.MaxTorque = Vector3.new(400000, 400000, 400000)
	gyro.P = 10000
	gyro.D = 500
	gyro.Parent = rootPart

	-- Create BodyVelocity for movement
	local bv = Instance.new("BodyVelocity")
	bv.Name = "CarpetVelocity"
	bv.MaxForce = Vector3.new(100000, 100000, 100000)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.P = 5000
	bv.Parent = rootPart

	-- Disable normal gravity effect
	local antigrav = Instance.new("BodyForce")
	antigrav.Name = "CarpetAntiGrav"
	local mass = 0
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then mass += part:GetMass() end
	end
	antigrav.Force = Vector3.new(0, mass * workspace.Gravity, 0) -- full anti-gravity
	antigrav.Parent = rootPart

	-- Carpet particles
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "CarpetParticles"
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 20
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(30, 30)
	particles.Acceleration = Vector3.new(0, -5, 0)
	particles.Parent = rootPart

	-- Flight update loop
	flyConnection = RunService.Heartbeat:Connect(function()
		if not isFlying or not rootPart or not rootPart.Parent then return end

		local camCF = camera.CFrame
		local lookVector = camCF.LookVector
		local rightVector = camCF.RightVector

		-- Flatten for horizontal movement
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
		local flatRight = Vector3.new(rightVector.X, 0, rightVector.Z).Unit

		local moveDir = Vector3.new(0, 0, 0)

		-- WASD horizontal
		if keysDown[Enum.KeyCode.W] then moveDir += flatLook end
		if keysDown[Enum.KeyCode.S] then moveDir -= flatLook end
		if keysDown[Enum.KeyCode.D] then moveDir += flatRight end
		if keysDown[Enum.KeyCode.A] then moveDir -= flatRight end

		-- Vertical
		if keysDown[Enum.KeyCode.Space] then
			moveDir += Vector3.new(0, 1, 0) * (FLY_ASCEND_SPEED / FLY_SPEED)
		end
		if keysDown[Enum.KeyCode.LeftControl] then
			moveDir -= Vector3.new(0, 1, 0) * (FLY_DESCEND_SPEED / FLY_SPEED)
		end

		-- Normalize and apply speed
		if moveDir.Magnitude > 0.01 then
			moveDir = moveDir.Unit * FLY_SPEED
		else
			moveDir = Vector3.new(0, 0, 0)
		end

		bv.Velocity = moveDir

		-- Point gyro in movement direction (or camera direction if stationary)
		if moveDir.Magnitude > 1 then
			local flatMove = Vector3.new(moveDir.X, 0, moveDir.Z)
			if flatMove.Magnitude > 0.1 then
				gyro.CFrame = CFrame.lookAt(Vector3.zero, flatMove)
			end
		else
			local flatCamLook = Vector3.new(lookVector.X, 0, lookVector.Z)
			if flatCamLook.Magnitude > 0.1 then
				gyro.CFrame = CFrame.lookAt(Vector3.zero, flatCamLook)
			end
		end

		-- Slight tilt in movement direction for visual flair
		local tiltAngle = 0
		if keysDown[Enum.KeyCode.W] then tiltAngle = -0.15 end
		if keysDown[Enum.KeyCode.S] then tiltAngle = 0.1 end
		gyro.CFrame = gyro.CFrame * CFrame.Angles(tiltAngle, 0, 0)
	end)
end

local function stopFlying()
	if not isFlying then return end
	isFlying = false

	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local gyro = rootPart:FindFirstChild("CarpetGyro")
		if gyro then gyro:Destroy() end
		local bv = rootPart:FindFirstChild("CarpetVelocity")
		if bv then bv:Destroy() end
		local ag = rootPart:FindFirstChild("CarpetAntiGrav")
		if ag then ag:Destroy() end
		local particles = rootPart:FindFirstChild("CarpetParticles")
		if particles then particles:Destroy() end
	end
end

-- Listen for server toggle
carpetFlyEvent.OnClientEvent:Connect(function(enabled)
	if enabled then
		startFlying()
	else
		stopFlying()
	end
end)

-- Clean up on death
local function onCharacterAdded(character)
	character:WaitForChild("Humanoid").Died:Connect(function()
		stopFlying()
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

print("[CandyRun] Magic Carpet flight controller loaded!")
