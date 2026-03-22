--[[
	Candy Run - Character Scripts v3
	Speed 48, jump 60, DOUBLE JUMP, smooth camera, coyote time, particles
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = script.Parent.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

local function isShiftLocked(): boolean
	return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end

-- ============================================================
-- MOVEMENT TUNING
-- ============================================================

local WALK_SPEED = 28        -- normal walking speed
local SPRINT_SPEED = 48      -- sprint speed (hold Left Ctrl)
humanoid.WalkSpeed = WALK_SPEED
humanoid.JumpPower = 60      -- strong jumps
humanoid.HipHeight = 2.2
local isSprinting = false

-- ============================================================
-- SPRINT (Hold Left Ctrl or W+Left Shift alternative)
-- ============================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftControl then
		isSprinting = true
		if humanoid then humanoid.WalkSpeed = SPRINT_SPEED end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftControl then
		isSprinting = false
		if humanoid then humanoid.WalkSpeed = WALK_SPEED end
	end
end)

-- ============================================================
-- DOUBLE JUMP
-- ============================================================

local MAX_JUMPS = 2
local jumpsLeft = MAX_JUMPS
local canDoubleJump = false
local hasDoubleJumped = false

-- Reset jumps when landing
humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Landed then
		jumpsLeft = MAX_JUMPS
		canDoubleJump = false
		hasDoubleJumped = false
	elseif newState == Enum.HumanoidStateType.Jumping then
		-- After first jump, allow double jump after a brief delay
		jumpsLeft -= 1
		if jumpsLeft > 0 then
			canDoubleJump = false
			task.delay(0.15, function()
				canDoubleJump = true
			end)
		end
	elseif newState == Enum.HumanoidStateType.Freefall then
		-- If walked off edge (didn't jump), still allow one air jump
		if jumpsLeft == MAX_JUMPS then
			jumpsLeft = 1
			canDoubleJump = true
		end
	end
end)

-- Listen for jump input while in air
UserInputService.JumpRequest:Connect(function()
	if humanoid.FloorMaterial == Enum.Material.Air and canDoubleJump and jumpsLeft > 0 and not hasDoubleJumped then
		hasDoubleJumped = true
		canDoubleJump = false
		jumpsLeft -= 1

		-- Apply upward velocity for double jump
		rootPart.AssemblyLinearVelocity = Vector3.new(
			rootPart.AssemblyLinearVelocity.X,
			humanoid.JumpPower * 1.1,  -- slightly stronger than normal jump
			rootPart.AssemblyLinearVelocity.Z
		)

		-- Double jump particles (burst of candy sparkles)
		if doubleJumpBurst then
			doubleJumpBurst:Emit(15)
		end

		-- Subtle spin effect on camera
		if not isShiftLocked() then
			task.spawn(function()
				for i = 1, 5 do
					humanoid.CameraOffset = Vector3.new(0, 0.3 * (5-i)/5, 0)
					task.wait(0.03)
				end
			end)
		end
	end
end)

-- ============================================================
-- SMOOTH CAMERA
-- ============================================================

local baseFOV = 70
local sprintFOV = 78 -- wider for faster speed

RunService.RenderStepped:Connect(function(dt)
	if not rootPart or not rootPart.Parent then return end

	local velocity = rootPart.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

	local targetFOV = baseFOV + math.clamp(horizontalSpeed / 50, 0, 1) * (sprintFOV - baseFOV)
	camera.FieldOfView += (targetFOV - camera.FieldOfView) * math.min(dt * 6, 1)

	if not isShiftLocked() then
		if humanoid.FloorMaterial ~= Enum.Material.Air and horizontalSpeed > 3 then
			local bobAmount = math.sin(tick() * 12) * 0.06
			local lateralBob = math.cos(tick() * 6) * 0.03
			humanoid.CameraOffset = humanoid.CameraOffset:Lerp(
				Vector3.new(lateralBob, bobAmount, 0), math.min(dt * 8, 1)
			)
		else
			humanoid.CameraOffset = humanoid.CameraOffset:Lerp(
				Vector3.new(0, 0, 0), math.min(dt * 5, 1)
			)
		end
	end
end)

-- ============================================================
-- LANDING SQUASH
-- ============================================================

local wasInAir = false
local airTime = 0

RunService.Heartbeat:Connect(function(dt)
	if not rootPart or not rootPart.Parent then return end

	local inAir = humanoid.FloorMaterial == Enum.Material.Air

	if inAir then
		airTime += dt
		wasInAir = true
	elseif wasInAir then
		local landingForce = math.clamp(airTime * 2, 0.1, 1)
		if not isShiftLocked() then
			humanoid.CameraOffset = Vector3.new(0, -landingForce * 0.6, 0)
		end
		airTime = 0
		wasInAir = false
	end
end)

-- ============================================================
-- COYOTE TIME + JUMP BUFFER
-- ============================================================

local COYOTE_TIME = 0.12
local JUMP_BUFFER_TIME = 0.15
local lastGroundedTime = 0
local lastJumpPressTime = -1
local hasUsedCoyote = false

UserInputService.JumpRequest:Connect(function()
	lastJumpPressTime = tick()
end)

RunService.Heartbeat:Connect(function()
	if not humanoid or not humanoid.Parent then return end

	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

	if grounded then
		lastGroundedTime = tick()
		hasUsedCoyote = false
	end

	local timeSinceGrounded = tick() - lastGroundedTime
	local timeSinceJumpPress = tick() - lastJumpPressTime

	if not grounded and not hasUsedCoyote
		and timeSinceGrounded < COYOTE_TIME
		and timeSinceJumpPress < JUMP_BUFFER_TIME
	then
		hasUsedCoyote = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		lastJumpPressTime = -1
	end

	if grounded and timeSinceJumpPress < JUMP_BUFFER_TIME then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		lastJumpPressTime = -1
	end
end)

-- ============================================================
-- CANDY TRAIL
-- ============================================================

local trail = Instance.new("ParticleEmitter")
trail.Name = "CandyTrail"
trail.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 200)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 130, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 200, 255)),
})
trail.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.4),
	NumberSequenceKeypoint.new(0.5, 0.2),
	NumberSequenceKeypoint.new(1, 0),
})
trail.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.4),
	NumberSequenceKeypoint.new(0.5, 0.6),
	NumberSequenceKeypoint.new(1, 1),
})
trail.Lifetime = NumberRange.new(0.3, 0.7)
trail.Rate = 0
trail.Speed = NumberRange.new(0.5, 2)
trail.SpreadAngle = Vector2.new(15, 15)
trail.Rotation = NumberRange.new(-180, 180)
trail.RotSpeed = NumberRange.new(-60, 60)
trail.Acceleration = Vector3.new(0, -2, 0)
trail.Parent = rootPart

RunService.Heartbeat:Connect(function()
	if not rootPart or not rootPart.Parent then return end
	local velocity = rootPart.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	trail.Rate = if speed > 4 then math.clamp(speed * 0.6, 0, 25) else 0
end)

-- ============================================================
-- JUMP PARTICLES
-- ============================================================

local jumpBurst = Instance.new("ParticleEmitter")
jumpBurst.Name = "JumpBurst"
jumpBurst.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100))
jumpBurst.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
jumpBurst.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
jumpBurst.Lifetime = NumberRange.new(0.2, 0.4)
jumpBurst.Rate = 0
jumpBurst.Speed = NumberRange.new(5, 10)
jumpBurst.SpreadAngle = Vector2.new(60, 60)
jumpBurst.Acceleration = Vector3.new(0, -20, 0)
jumpBurst.Parent = rootPart

humanoid.Jumping:Connect(function()
	jumpBurst:Emit(8)
end)

-- ============================================================
-- DOUBLE JUMP PARTICLES (distinct from regular jump)
-- ============================================================

doubleJumpBurst = Instance.new("ParticleEmitter")
doubleJumpBurst.Name = "DoubleJumpBurst"
doubleJumpBurst.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255)),
})
doubleJumpBurst.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0)})
doubleJumpBurst.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
doubleJumpBurst.Lifetime = NumberRange.new(0.3, 0.5)
doubleJumpBurst.Rate = 0
doubleJumpBurst.Speed = NumberRange.new(8, 15)
doubleJumpBurst.SpreadAngle = Vector2.new(80, 80)
doubleJumpBurst.Acceleration = Vector3.new(0, -25, 0)
doubleJumpBurst.Parent = rootPart

-- ============================================================
-- LAND PARTICLES
-- ============================================================

local landBurst = Instance.new("ParticleEmitter")
landBurst.Name = "LandBurst"
landBurst.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 220)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 130, 255)),
})
landBurst.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
landBurst.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
landBurst.Lifetime = NumberRange.new(0.3, 0.5)
landBurst.Rate = 0
landBurst.Speed = NumberRange.new(3, 8)
landBurst.SpreadAngle = Vector2.new(80, 80)
landBurst.Acceleration = Vector3.new(0, -15, 0)
landBurst.Parent = rootPart

humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Landed then
		landBurst:Emit(12)
	end
end)

print("[CandyRun] Character loaded! Speed: 48, Double Jump: ON")
