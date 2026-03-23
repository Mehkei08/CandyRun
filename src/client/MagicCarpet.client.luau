--[[
	Magic Carpet - Client Flight Controller
	Equip carpet tool → press M1 (click) → mount animation → sit + fly.
	Press M1 again to dismount.
	WASD = horizontal, Space = ascend, LeftControl = descend.
	Leaves a rainbow trail behind.
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
local carpetEquipped = false
local FLY_SPEED = 80
local FLY_ASCEND_SPEED = 50
local FLY_DESCEND_SPEED = 45
local MOUNT_DURATION = 1.2

-- Track input
local keysDown = {}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	keysDown[input.KeyCode] = true
end)

UserInputService.InputEnded:Connect(function(input)
	keysDown[input.KeyCode] = nil
end)

local flyConnection = nil
local trailPart = nil
local trail = nil

-- ============================================================
-- TRAIL (rainbow trail behind the carpet)
-- ============================================================

local function createTrail(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Trail attachment points
	local att0 = Instance.new("Attachment")
	att0.Name = "CarpetTrailAtt0"
	att0.Position = Vector3.new(0, -2, 2)
	att0.Parent = rootPart

	local att1 = Instance.new("Attachment")
	att1.Name = "CarpetTrailAtt1"
	att1.Position = Vector3.new(0, -2, -2)
	att1.Parent = rootPart

	trail = Instance.new("Trail")
	trail.Name = "CarpetTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 1.5
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.LightEmission = 0.5
	trail.LightInfluence = 0.3
	trail.Enabled = true

	-- Rainbow color
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 160, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 255, 50)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(50, 150, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(130, 50, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 255)),
	})

	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})

	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})

	trail.Parent = rootPart
	return att0, att1
end

local function destroyTrail(character)
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local t = rootPart:FindFirstChild("CarpetTrail")
		if t then t:Destroy() end
		local a0 = rootPart:FindFirstChild("CarpetTrailAtt0")
		if a0 then a0:Destroy() end
		local a1 = rootPart:FindFirstChild("CarpetTrailAtt1")
		if a1 then a1:Destroy() end
	end
	trail = nil
end

-- ============================================================
-- MOUNT ANIMATION
-- ============================================================

local function playMountAnimation()
	isMounting = true

	local character = player.Character
	if not character then isMounting = false; return false end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then isMounting = false; return false end

	-- Force sit
	humanoid.Sit = true
	local origSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	-- Anti-gravity during mount
	local mountForce = Instance.new("BodyForce")
	mountForce.Name = "MountAntiGrav"
	local mass = 0
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then mass += part:GetMass() end
	end
	mountForce.Force = Vector3.new(0, mass * workspace.Gravity, 0)
	mountForce.Parent = rootPart

	-- Gentle rise
	local mountVel = Instance.new("BodyVelocity")
	mountVel.Name = "MountVelocity"
	mountVel.MaxForce = Vector3.new(50000, 50000, 50000)
	mountVel.Velocity = Vector3.new(0, 5, 0)
	mountVel.Parent = rootPart

	-- Gyro for orientation
	local mountGyro = Instance.new("BodyGyro")
	mountGyro.Name = "MountGyro"
	mountGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
	mountGyro.P = 5000; mountGyro.D = 300
	mountGyro.Parent = rootPart

	-- Mount sparkles
	local mountParticles = Instance.new("ParticleEmitter")
	mountParticles.Name = "MountParticles"
	mountParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
	})
	mountParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0),
	})
	mountParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1),
	})
	mountParticles.Lifetime = NumberRange.new(0.4, 0.8)
	mountParticles.Rate = 50; mountParticles.Speed = NumberRange.new(3, 8)
	mountParticles.SpreadAngle = Vector2.new(180, 180)
	mountParticles.Parent = rootPart

	-- Animate over mount duration
	local steps = math.ceil(MOUNT_DURATION * 30)
	for step = 1, steps do
		if not isMounting then break end
		local t = step / steps
		local camLook = camera.CFrame.LookVector
		local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
		if flatLook.Magnitude > 0.1 then
			mountGyro.CFrame = CFrame.lookAt(Vector3.zero, flatLook.Unit)
		end
		mountVel.Velocity = Vector3.new(0, 5 * (1 - t * 0.8), 0)
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

	humanoid.WalkSpeed = origSpeed
	isMounting = false
	return true
end

-- ============================================================
-- FLIGHT
-- ============================================================

local function startFlying()
	if isFlying or isMounting then return end

	-- Mount animation first
	local mounted = playMountAnimation()
	if not mounted then return end
	if not player.Character then return end

	isFlying = true

	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then isFlying = false; return end

	-- Keep sitting
	humanoid.Sit = true

	-- BodyGyro
	local gyro = Instance.new("BodyGyro")
	gyro.Name = "CarpetGyro"
	gyro.MaxTorque = Vector3.new(400000, 400000, 400000)
	gyro.P = 10000; gyro.D = 500
	gyro.Parent = rootPart

	-- BodyVelocity
	local bv = Instance.new("BodyVelocity")
	bv.Name = "CarpetVelocity"
	bv.MaxForce = Vector3.new(100000, 100000, 100000)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.P = 5000
	bv.Parent = rootPart

	-- Anti-gravity
	local antigrav = Instance.new("BodyForce")
	antigrav.Name = "CarpetAntiGrav"
	local mass = 0
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then mass += part:GetMass() end
	end
	antigrav.Force = Vector3.new(0, mass * workspace.Gravity, 0)
	antigrav.Parent = rootPart

	-- Flight particles
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "CarpetParticles"
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 20; particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(30, 30)
	particles.Acceleration = Vector3.new(0, -5, 0)
	particles.Parent = rootPart

	-- Create rainbow trail
	createTrail(character)

	-- Flight loop
	flyConnection = RunService.Heartbeat:Connect(function()
		if not isFlying or not rootPart or not rootPart.Parent then return end

		local camCF = camera.CFrame
		local lookVector = camCF.LookVector
		local rightVector = camCF.RightVector

		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
		local flatRight = Vector3.new(rightVector.X, 0, rightVector.Z).Unit

		local moveDir = Vector3.new(0, 0, 0)

		if keysDown[Enum.KeyCode.W] then moveDir += flatLook end
		if keysDown[Enum.KeyCode.S] then moveDir -= flatLook end
		if keysDown[Enum.KeyCode.D] then moveDir += flatRight end
		if keysDown[Enum.KeyCode.A] then moveDir -= flatRight end

		-- Space = ascend, LeftControl = descend
		if keysDown[Enum.KeyCode.Space] then
			moveDir += Vector3.new(0, 1, 0) * (FLY_ASCEND_SPEED / FLY_SPEED)
		end
		if keysDown[Enum.KeyCode.LeftControl] then
			moveDir -= Vector3.new(0, 1, 0) * (FLY_DESCEND_SPEED / FLY_SPEED)
		end

		if moveDir.Magnitude > 0.01 then
			moveDir = moveDir.Unit * FLY_SPEED
		else
			moveDir = Vector3.new(0, 0, 0)
		end

		bv.Velocity = moveDir

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

		-- Tilt for visual flair
		local tiltAngle = 0
		if keysDown[Enum.KeyCode.W] then tiltAngle = -0.18 end
		if keysDown[Enum.KeyCode.S] then tiltAngle = 0.12 end
		gyro.CFrame = gyro.CFrame * CFrame.Angles(tiltAngle, 0, 0)

		-- Keep sit
		if humanoid and not humanoid.Sit then humanoid.Sit = true end
	end)
end

local function stopFlying()
	isMounting = false
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

	-- Destroy trail
	destroyTrail(character)

	if rootPart then
		for _, name in ipairs({"CarpetGyro","CarpetVelocity","CarpetAntiGrav","CarpetParticles","MountAntiGrav","MountVelocity","MountGyro","MountParticles"}) do
			local obj = rootPart:FindFirstChild(name)
			if obj then obj:Destroy() end
		end
	end
	if humanoid then
		humanoid.Sit = false
		humanoid.JumpPower = 60
	end
end

-- ============================================================
-- M1 TOGGLE: Click to mount/dismount (server sends equip event)
-- ============================================================

-- Server fires CarpetFlyToggle(true) on equip, (false) on unequip.
-- We intercept: on equip, DON'T fly yet — wait for M1 click.
-- On unequip, always stop.

local waitingForClick = false

carpetFlyEvent.OnClientEvent:Connect(function(enabled)
	if enabled then
		-- Carpet equipped — wait for M1 to mount
		carpetEquipped = true
		waitingForClick = true
		-- Don't start flying yet
	else
		-- Carpet unequipped — stop everything
		carpetEquipped = false
		waitingForClick = false
		stopFlying()
	end
end)

-- Listen for M1 click while carpet is equipped
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not carpetEquipped then return end

	if waitingForClick and not isFlying and not isMounting then
		-- M1 pressed with carpet equipped: mount and fly
		waitingForClick = false
		task.spawn(startFlying)
	elseif isFlying then
		-- M1 pressed while flying: dismount
		stopFlying()
		waitingForClick = true -- can click again to remount
	end
end)

-- Clean up on death
local function onCharacterAdded(character)
	character:WaitForChild("Humanoid").Died:Connect(function()
		stopFlying()
		carpetEquipped = false
		waitingForClick = false
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

print("[CandyRun] Magic Carpet loaded! M1 to mount/dismount, speed 80, rainbow trail.")
