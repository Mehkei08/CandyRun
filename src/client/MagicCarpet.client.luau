--[[
	Magic Carpet - Client Flight Controller
	Equip carpet → sit mount animation → then full flight.
	WASD = horizontal movement, Space = ascend, LeftControl = descend
	Click M1 to pull out, character sits on it with mount-up anim before flying.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local carpetFlyEvent = ReplicatedStorage:WaitForChild("CarpetFlyToggle")

local isFlying = false
local isMounting = false
local FLY_SPEED = 80         -- carpet speed (+20 from before)
local FLY_ASCEND_SPEED = 50
local FLY_DESCEND_SPEED = 45
local MOUNT_DURATION = 1.5   -- seconds to mount before flying

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

-- ============================================================
-- MOUNT ANIMATION
-- ============================================================

local function playMountAnimation()
	isMounting = true

	local character = player.Character
	if not character then isMounting = false; return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then isMounting = false; return end

	-- Force sit pose
	humanoid.Sit = true

	-- Freeze movement during mount
	local origSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	-- Hover effect: slowly rise 3 studs with a gentle spin
	local startPos = rootPart.Position
	local startCF = rootPart.CFrame

	-- Anti-gravity to hold in place during mount
	local mountForce = Instance.new("BodyForce")
	mountForce.Name = "MountAntiGrav"
	local mass = 0
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then mass += part:GetMass() end
	end
	mountForce.Force = Vector3.new(0, mass * workspace.Gravity, 0)
	mountForce.Parent = rootPart

	-- Gentle upward velocity during mount
	local mountVel = Instance.new("BodyVelocity")
	mountVel.Name = "MountVelocity"
	mountVel.MaxForce = Vector3.new(50000, 50000, 50000)
	mountVel.Velocity = Vector3.new(0, 4, 0) -- slow rise
	mountVel.Parent = rootPart

	-- Gyro for gentle spin
	local mountGyro = Instance.new("BodyGyro")
	mountGyro.Name = "MountGyro"
	mountGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
	mountGyro.P = 5000; mountGyro.D = 300
	mountGyro.Parent = rootPart

	-- Sparkle particles during mount
	local mountParticles = Instance.new("ParticleEmitter")
	mountParticles.Name = "MountParticles"
	mountParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 180, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
	})
	mountParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	mountParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	mountParticles.Lifetime = NumberRange.new(0.4, 0.8)
	mountParticles.Rate = 60
	mountParticles.Speed = NumberRange.new(3, 8)
	mountParticles.SpreadAngle = Vector2.new(180, 180)
	mountParticles.Rotation = NumberRange.new(-180, 180)
	mountParticles.Parent = rootPart

	-- Gentle spin animation over mount duration
	local spinSteps = math.ceil(MOUNT_DURATION * 30)
	for step = 1, spinSteps do
		if not isMounting then break end
		local t = step / spinSteps
		-- Slow spin: quarter rotation
		local spinAngle = t * math.pi * 0.5
		local camLook = camera.CFrame.LookVector
		local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
		if flatLook.Magnitude > 0.1 then
			mountGyro.CFrame = CFrame.lookAt(Vector3.zero, flatLook.Unit) * CFrame.Angles(0, spinAngle, 0)
		end
		-- Slow the rise toward end
		mountVel.Velocity = Vector3.new(0, 4 * (1 - t * 0.7), 0)
		task.wait(1/30)
	end

	-- Clean up mount forces
	if mountVel and mountVel.Parent then mountVel:Destroy() end
	if mountGyro and mountGyro.Parent then mountGyro:Destroy() end
	if mountForce and mountForce.Parent then mountForce:Destroy() end
	if mountParticles and mountParticles.Parent then
		mountParticles.Rate = 0
		task.delay(1, function()
			if mountParticles and mountParticles.Parent then mountParticles:Destroy() end
		end)
	end

	-- Restore movement
	humanoid.WalkSpeed = origSpeed

	isMounting = false
end

-- ============================================================
-- FLIGHT
-- ============================================================

local function startFlying()
	if isFlying or isMounting then return end

	-- Play mount animation first
	playMountAnimation()

	-- After mount, begin flight
	if not player.Character then return end
	isFlying = true

	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then isFlying = false; return end

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
	antigrav.Force = Vector3.new(0, mass * workspace.Gravity, 0)
	antigrav.Parent = rootPart

	-- Flight particles (subtler than mount)
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
	particles.Rate = 25
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(30, 30)
	particles.Acceleration = Vector3.new(0, -5, 0)
	particles.Parent = rootPart

	-- Keep sit pose during flight
	humanoid.Sit = true

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
		if keysDown[Enum.KeyCode.W] then tiltAngle = -0.18 end
		if keysDown[Enum.KeyCode.S] then tiltAngle = 0.12 end
		gyro.CFrame = gyro.CFrame * CFrame.Angles(tiltAngle, 0, 0)

		-- Keep sit pose
		if humanoid and not humanoid.Sit then
			humanoid.Sit = true
		end
	end)
end

local function stopFlying()
	isMounting = false -- cancel mount if in progress
	if not isFlying then return end
	isFlying = false

	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if rootPart then
		local gyro = rootPart:FindFirstChild("CarpetGyro")
		if gyro then gyro:Destroy() end
		local bv = rootPart:FindFirstChild("CarpetVelocity")
		if bv then bv:Destroy() end
		local ag = rootPart:FindFirstChild("CarpetAntiGrav")
		if ag then ag:Destroy() end
		local particles = rootPart:FindFirstChild("CarpetParticles")
		if particles then particles:Destroy() end
		-- Clean up any leftover mount forces
		local mf = rootPart:FindFirstChild("MountAntiGrav")
		if mf then mf:Destroy() end
		local mv = rootPart:FindFirstChild("MountVelocity")
		if mv then mv:Destroy() end
		local mg = rootPart:FindFirstChild("MountGyro")
		if mg then mg:Destroy() end
		local mp = rootPart:FindFirstChild("MountParticles")
		if mp then mp:Destroy() end
	end
	if humanoid then
		humanoid.Sit = false
		humanoid.JumpPower = 60
	end
end

-- Listen for server toggle
carpetFlyEvent.OnClientEvent:Connect(function(enabled)
	if enabled then
		task.spawn(startFlying) -- spawn so mount anim doesn't block
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

print("[CandyRun] Magic Carpet flight controller loaded! Speed: 80, Mount animation: ON")
