--[[
	Candy Run - Server Script v7
	Runtime-only — references static map built via tools/BuildMap.luau
	No geometry creation. All gameplay logic preserved.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- ============================================================
-- REMOTE EVENTS
-- ============================================================

local function makeRemote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name; r.Parent = ReplicatedStorage
	return r
end

local startGameEvent       = makeRemote("StartGame")
local timerEvent           = makeRemote("TimerUpdate")
local candyCollectedEvent  = makeRemote("CandyCollected")
local respawnEvent         = makeRemote("RespawnTimer")
local timerStartEvent      = makeRemote("TimerStart")
local grappleShootEvent    = makeRemote("GrappleShoot")
local grappleHitEvent      = makeRemote("GrappleHit")
local trailChestEvent      = makeRemote("TrailChestOpen")
local trailSpinResultEvent = makeRemote("TrailSpinResult")
local dailySpinEvent       = makeRemote("DailySpin")
local interactEvent        = makeRemote("InteractPrompt")
local purchaseEvent        = makeRemote("PurchaseItem")
local boomboxEvent         = makeRemote("BoomboxPlay")
local candyUpdateEvent     = makeRemote("CandyUpdate")
local carpetFlyEvent       = makeRemote("CarpetFlyToggle")
local spinRequestEvent     = makeRemote("SpinRequest")

-- ============================================================
-- LIGHTING
-- ============================================================

Lighting.ClockTime = 15
Lighting.Brightness = 2.0
Lighting.Ambient = Color3.fromRGB(120, 90, 130)
Lighting.OutdoorAmbient = Color3.fromRGB(160, 130, 170)
Lighting.FogColor = Color3.fromRGB(200, 170, 210)
Lighting.FogEnd = 2500; Lighting.FogStart = 500

local atmo = Instance.new("Atmosphere")
atmo.Density = 0.35; atmo.Offset = 0.1
atmo.Color = Color3.fromRGB(140, 90, 150)
atmo.Decay = Color3.fromRGB(100, 60, 120)
atmo.Glare = 0.05; atmo.Haze = 3.5
atmo.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.6; bloom.Size = 40; bloom.Threshold = 0.8
bloom.Parent = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Saturation = 0.4; cc.TintColor = Color3.fromRGB(230, 200, 240)
cc.Brightness = -0.05; cc.Contrast = 0.18
cc.Parent = Lighting

local sunrays = Instance.new("SunRaysEffect")
sunrays.Intensity = 0.04; sunrays.Spread = 0.3
sunrays.Parent = Lighting

-- ============================================================
-- CONSTANTS & STATE
-- ============================================================

local START_HEIGHT = 250
local DEATH_Y = 20
local COLLECT_SOUND_ID = "rbxassetid://5619828673"

local checkpointPositions = {}
local playerData = {}

-- ============================================================
-- FIND STATIC MAP FOLDERS
-- ============================================================

local mapFolder = workspace:WaitForChild("CandyMap", 10)
local collectiblesFolder = workspace:WaitForChild("Collectibles", 10)
local hallwayFolder = workspace:WaitForChild("Hallway", 10)

if not mapFolder then
	warn("[CandyRun] CandyMap folder not found! Run tools/BuildMap.luau in Studio first.")
	return
end

print("[CandyRun] Found static map. Hooking up gameplay...")

-- ============================================================
-- BUILD CHECKPOINT TABLE FROM STATIC MAP
-- ============================================================

-- Default spawn
checkpointPositions[0] = Vector3.new(0, START_HEIGHT + 5, 20)

-- Find spawn location if it exists
local mainSpawn = mapFolder:FindFirstChild("MainSpawn")
if mainSpawn and mainSpawn:IsA("SpawnLocation") then
	checkpointPositions[0] = mainSpawn.Position + Vector3.new(0, 2, 0)
end

-- Scan for checkpoint platforms
for _, child in mapFolder:GetChildren() do
	local cpVal = child:FindFirstChild("IsCheckpoint")
	local cpIdx = child:FindFirstChild("CheckpointIndex")
	if cpVal and cpVal:IsA("BoolValue") and cpVal.Value and cpIdx and cpIdx:IsA("IntValue") then
		local walkable = child:FindFirstChild("Walkable") or child:FindFirstChildWhichIsA("BasePart", true)
		if walkable then
			checkpointPositions[cpIdx.Value] = walkable.Position + Vector3.new(0, 5, 0)
			print("[CandyRun] Checkpoint " .. cpIdx.Value .. " at " .. tostring(walkable.Position))
		end
	end
end

-- ============================================================
-- CHECKPOINT TOUCH TRIGGERS
-- ============================================================

for _, child in mapFolder:GetChildren() do
	local cpVal = child:FindFirstChild("IsCheckpoint")
	local cpIdx = child:FindFirstChild("CheckpointIndex")
	if cpVal and cpVal:IsA("BoolValue") and cpVal.Value and cpIdx then
		-- Find or create a trigger zone
		local trigger = child:FindFirstChild("CheckpointTrigger")
		if not trigger then
			-- Use the walkable part as trigger
			local walkable = child:FindFirstChild("Walkable") or child:FindFirstChildWhichIsA("BasePart", true)
			if walkable then
				trigger = Instance.new("Part")
				trigger.Name = "CheckpointTrigger"
				trigger.Size = Vector3.new(30, 20, 30)
				trigger.Position = walkable.Position + Vector3.new(0, 10, 0)
				trigger.Anchored = true; trigger.Transparency = 1; trigger.CanCollide = false
				trigger.Parent = child
			end
		end
		if trigger then
			local idx = cpIdx.Value
			trigger.Touched:Connect(function(hit)
				local ch = hit.Parent
				local plr = Players:GetPlayerFromCharacter(ch)
				if plr then
					local data = playerData[plr]
					if data and (not data.checkpoint or data.checkpoint < idx) then
						data.checkpoint = idx
					end
				end
			end)
		end
	end
end

-- ============================================================
-- MOVING PLATFORMS
-- ============================================================

local function makeMoving(model)
	task.spawn(function()
		local range = math.random(8, 14)
		local speed = math.random(25, 40) / 10
		local startPivot = model:GetPivot()
		local steps = math.ceil(speed * 30)
		while model and model.Parent do
			for step = 1, steps do
				if not model or not model.Parent then return end
				local a = 0.5 - 0.5 * math.cos((step / steps) * math.pi)
				model:PivotTo(CFrame.new(startPivot.Position + Vector3.new(range * a, 0, 0)) * startPivot.Rotation)
				task.wait(1 / 30)
			end
			for step = 1, steps * 2 do
				if not model or not model.Parent then return end
				local a = 0.5 - 0.5 * math.cos((step / (steps * 2)) * math.pi)
				local x = range * (1 - 2 * a)
				model:PivotTo(CFrame.new(startPivot.Position + Vector3.new(x, 0, 0)) * startPivot.Rotation)
				task.wait(1 / 30)
			end
			for step = 1, steps do
				if not model or not model.Parent then return end
				local a = 0.5 - 0.5 * math.cos((step / steps) * math.pi)
				model:PivotTo(CFrame.new(startPivot.Position + Vector3.new(-range * (1 - a), 0, 0)) * startPivot.Rotation)
				task.wait(1 / 30)
			end
		end
	end)
end

-- Start moving any platforms tagged IsMoving
for _, child in mapFolder:GetChildren() do
	local mv = child:FindFirstChild("IsMoving")
	if mv and mv:IsA("BoolValue") and mv.Value then
		makeMoving(child)
	end
end

-- ============================================================
-- COLLECTIBLES (animate + touch handlers)
-- ============================================================

if collectiblesFolder then
	for _, model in collectiblesFolder:GetChildren() do
		if model.Name:match("^SpeedCandy_") then
			local basePos = model:GetPivot().Position

			-- Animate floating + spinning
			task.spawn(function()
				while model and model.Parent do
					local yOff = math.sin(tick() * 2.5) * 1.5
					model:PivotTo(CFrame.new(basePos + Vector3.new(0, yOff, 0)) * CFrame.Angles(0, math.rad(tick() * 60 % 360), 0))
					task.wait(0.03)
				end
			end)

			-- Touch to collect
			local trigger = model:FindFirstChild("CollectTrigger")
			if trigger then
				local collected = false
				trigger.Touched:Connect(function(hit)
					local ch = hit.Parent
					local plr = Players:GetPlayerFromCharacter(ch)
					if plr and model.Parent and not collected then
						collected = true
						local snd = model:FindFirstChild("CollectSound", true)
						if snd then snd:Play() end
						task.delay(0.15, function()
							model.Parent = nil
						end)
						local data = playerData[plr]
						if data then
							data.candies = (data.candies or 0) + 1
							candyUpdateEvent:FireClient(plr, data.candies)
						end
						candyCollectedEvent:FireClient(plr)
						task.delay(15, function()
							if collectiblesFolder and collectiblesFolder.Parent then
								model.Parent = collectiblesFolder
								collected = false
							end
						end)
					end
				end)
			end
		end
	end
end

-- ============================================================
-- DEATH FLOOR
-- ============================================================

local deathFloor = workspace:FindFirstChild("DeathFloor")
if not deathFloor and mapFolder then
	deathFloor = mapFolder:FindFirstChild("DeathFloor")
end

if deathFloor then
	-- Pulsing animation
	task.spawn(function()
		while deathFloor and deathFloor.Parent do
			TweenService:Create(deathFloor, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.25, Color = Color3.fromRGB(255, 50, 50),
			}):Play()
			task.wait(1.5)
			TweenService:Create(deathFloor, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.1, Color = Color3.fromRGB(200, 20, 20),
			}):Play()
			task.wait(1.5)
		end
	end)

	deathFloor.Touched:Connect(function(hit)
		local ch = hit.Parent
		local hum = ch and ch:FindFirstChild("Humanoid")
		if hum and hum.Health > 0 then hum.Health = 0 end
	end)
end

-- Backup kill part
local backupKill = workspace:FindFirstChild("DeathBackup")
if not backupKill and mapFolder then backupKill = mapFolder:FindFirstChild("DeathBackup") end
if backupKill then
	backupKill.Touched:Connect(function(hit)
		local ch = hit.Parent
		local hum = ch and ch:FindFirstChild("Humanoid")
		if hum and hum.Health > 0 then hum.Health = 0 end
	end)
end

-- ============================================================
-- VICTORY ZONE
-- ============================================================

local victoryZone = mapFolder:FindFirstChild("VictoryZone")
if victoryZone then
	local winners = {}
	victoryZone.Touched:Connect(function(hit)
		local ch = hit.Parent
		local plr = Players:GetPlayerFromCharacter(ch)
		if plr and not winners[plr] then
			winners[plr] = true
			timerEvent:FireClient(plr, "WIN")
			task.delay(5, function() winners[plr] = nil end)
		end
	end)
end

-- ============================================================
-- TRAIL SYSTEM
-- ============================================================

local TRAIL_COLORS = {
	{name = "Ruby Red", color = Color3.fromRGB(255, 50, 50)},
	{name = "Ocean Blue", color = Color3.fromRGB(50, 120, 255)},
	{name = "Emerald Green", color = Color3.fromRGB(50, 220, 80)},
	{name = "Royal Purple", color = Color3.fromRGB(160, 50, 255)},
	{name = "Sunset Orange", color = Color3.fromRGB(255, 140, 30)},
	{name = "Cotton Candy", color = Color3.fromRGB(255, 150, 220)},
	{name = "Golden", color = Color3.fromRGB(255, 215, 0)},
	{name = "Neon Cyan", color = Color3.fromRGB(0, 255, 255)},
	{name = "Hot Pink", color = Color3.fromRGB(255, 0, 150)},
	{name = "Midnight", color = Color3.fromRGB(30, 30, 80)},
}

local PREMIUM_TRAIL_COLORS = {
	{name = "Galaxy Swirl", color = Color3.fromRGB(20, 0, 80), isGalaxy = true},
	{name = "Cosmic Nebula", color = Color3.fromRGB(80, 0, 120), isCosmic = true},
	{name = "Rainbow Pulse", color = Color3.fromRGB(255, 100, 200), isRainbow = true},
	{name = "Stardust", color = Color3.fromRGB(255, 230, 150), isCosmic = true},
	{name = "Aurora Borealis", color = Color3.fromRGB(0, 255, 180), isCosmic = true},
	{name = "Void Walker", color = Color3.fromRGB(10, 0, 30), isGalaxy = true},
	{name = "Supernova", color = Color3.fromRGB(255, 50, 0), isCosmic = true},
	{name = "Prismatic", color = Color3.fromRGB(200, 100, 255), isRainbow = true},
}

local function applyTrail(char, trailColor, isRainbow, isGalaxy, isCosmic)
	for _, d in char:GetDescendants() do
		if d:IsA("Trail") and d.Name == "CandyTrail" then d:Destroy() end
		if d:IsA("ParticleEmitter") and d.Name == "PremiumTrailParticles" then d:Destroy() end
	end
	for _, d in char:GetDescendants() do
		if d:IsA("Attachment") and (d.Name == "TrailTop" or d.Name == "TrailBot") then d:Destroy() end
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	if not hrp or not head then return end
	local a0 = Instance.new("Attachment"); a0.Name = "TrailTop"; a0.Parent = head
	local a1 = Instance.new("Attachment"); a1.Name = "TrailBot"; a1.Parent = hrp
	local trail = Instance.new("Trail")
	trail.Name = "CandyTrail"
	trail.Attachment0 = a0; trail.Attachment1 = a1
	trail.Lifetime = 1.5; trail.MinLength = 0.1

	if isGalaxy or isCosmic then
		trail.LightEmission = 0.8; trail.LightInfluence = 0.2
	else
		trail.LightEmission = 0.4; trail.LightInfluence = 0.6
	end

	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0),
	})

	if isRainbow and not isGalaxy and not isCosmic then
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.6), NumberSequenceKeypoint.new(1, 1),
		})
	else
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1),
		})
	end

	if isRainbow then
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,50,50)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,165,0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255,255,50)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50,255,50)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(50,150,255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(150,50,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,50,200)),
		})
	elseif isGalaxy then
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 0, 30)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(80, 0, 120)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(20, 0, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 100)),
		})
	elseif isCosmic then
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 0, 120)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 100, 200)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 255, 180)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 150)),
		})
	else
		trail.Color = ColorSequence.new(trailColor)
	end
	trail.Parent = hrp

	if isGalaxy or isCosmic then
		local particles = Instance.new("ParticleEmitter")
		particles.Name = "PremiumTrailParticles"
		particles.Color = ColorSequence.new(trailColor)
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0),
		})
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1),
		})
		particles.Lifetime = NumberRange.new(0.5, 1.5)
		particles.Rate = 30; particles.Speed = NumberRange.new(1, 3)
		particles.SpreadAngle = Vector2.new(30, 30)
		particles.LightEmission = 0.8; particles.Parent = hrp
	end
end

-- ============================================================
-- DAILY SPIN SYSTEM
-- ============================================================

local SPIN_REWARDS = {
	{name = "50 Candy", icon = "🍬", color = Color3.fromRGB(255, 200, 50), weight = 25, type = "candy", value = 50},
	{name = "2x Speed 15m", icon = "⚡", color = Color3.fromRGB(80, 200, 255), weight = 20, type = "speed_boost", value = 15},
	{name = "25 Candy", icon = "🍬", color = Color3.fromRGB(200, 255, 100), weight = 20, type = "candy", value = 25},
	{name = "Low Gravity 10m", icon = "🌀", color = Color3.fromRGB(180, 80, 255), weight = 15, type = "gravity_boost", value = 10},
	{name = "100 Candy", icon = "💰", color = Color3.fromRGB(255, 215, 0), weight = 8, type = "candy", value = 100},
	{name = "Trail: Rainbow", icon = "🌈", color = Color3.fromRGB(255, 100, 200), weight = 6, type = "trail", value = "rainbow"},
	{name = "500 Candy", icon = "💎", color = Color3.fromRGB(100, 255, 255), weight = 5, type = "candy", value = 500},
	{name = "JACKPOT: VIP", icon = "👑", color = Color3.fromRGB(255, 50, 50), weight = 1, type = "jackpot", value = "vip"},
}

local SPIN_TOTAL_WEIGHT = 0
for _, r in ipairs(SPIN_REWARDS) do SPIN_TOTAL_WEIGHT += r.weight end

local function weightedSpinPick()
	local roll = math.random() * SPIN_TOTAL_WEIGHT
	local cumulative = 0
	for i, r in ipairs(SPIN_REWARDS) do
		cumulative += r.weight
		if roll <= cumulative then return i, r end
	end
	return #SPIN_REWARDS, SPIN_REWARDS[#SPIN_REWARDS]
end

local function applySpinReward(plr, reward)
	local data = playerData[plr]
	if not data then return end
	local char = plr.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if reward.type == "candy" then
		data.candies = (data.candies or 0) + reward.value
		candyUpdateEvent:FireClient(plr, data.candies)
	elseif reward.type == "speed_boost" then
		if hum then
			hum.WalkSpeed = 76
			task.delay(reward.value * 60, function()
				if hum and hum.Parent then hum.WalkSpeed = 100 end
			end)
		end
	elseif reward.type == "gravity_boost" then
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local bf = Instance.new("BodyForce"); bf.Name = "SpinGravityBoost"
				local mass = 0
				for _, part in char:GetDescendants() do
					if part:IsA("BasePart") then mass += part:GetMass() end
				end
				bf.Force = Vector3.new(0, mass * workspace.Gravity * 0.6, 0)
				bf.Parent = hrp
				task.delay(reward.value * 60, function()
					if bf and bf.Parent then bf:Destroy() end
				end)
			end
		end
	elseif reward.type == "trail" then
		if char then applyTrail(char, nil, true, false, false) end
	elseif reward.type == "jackpot" then
		print("[CandyRun] JACKPOT! " .. plr.Name .. " won VIP!")
	end
end

-- ============================================================
-- ITEM SYSTEM (tool creation)
-- ============================================================

local ITEM_PRICES = {
	["Speed Coil"] = 5,
	["Gravity Coil"] = 8,
	["Fusion Coil"] = 15,
	["Magic Carpet"] = 20,
	["Grapple Gun"] = 12,
}

local TOOL_ICONS = {
	["Speed Coil"]   = "rbxassetid://131544131",
	["Gravity Coil"] = "rbxassetid://131544479",
	["Fusion Coil"]  = "rbxassetid://131544131",
	["Magic Carpet"] = "rbxassetid://152980561",
	["Grapple Gun"]  = "rbxassetid://95146531",
	["Boombox"]      = "rbxassetid://130113146",
}

local function makeCoilHandle(tool, coilColor, secondaryColor)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 3, 0.5)
	handle.Color = Color3.fromRGB(180, 180, 200)
	handle.Material = Enum.Material.Metal
	handle.Parent = tool

	for i = 0, 8 do
		local angle = (i / 8) * math.pi * 2 * 2.5
		local yOff = (i / 8) * 2.5 - 1.25
		local ring = Instance.new("Part")
		ring.Name = "CoilRing"; ring.Size = Vector3.new(0.5, 0.5, 0.5)
		ring.Shape = Enum.PartType.Ball
		ring.Color = if i % 2 == 0 then coilColor else secondaryColor
		ring.Material = Enum.Material.Neon; ring.CanCollide = false; ring.Parent = tool
		local weld = Instance.new("Weld")
		weld.Part0 = handle; weld.Part1 = ring
		weld.C0 = CFrame.new(math.cos(angle) * 0.8, yOff, math.sin(angle) * 0.8)
		weld.Parent = ring
	end

	for _, yOff in ipairs({-1.6, 1.6}) do
		local cap = Instance.new("Part"); cap.Name = "Cap"
		cap.Size = Vector3.new(1, 0.3, 1); cap.Color = coilColor
		cap.Material = Enum.Material.SmoothPlastic
		cap.Shape = Enum.PartType.Cylinder; cap.Orientation = Vector3.new(0, 0, 90)
		cap.CanCollide = false; cap.Parent = tool
		local weld = Instance.new("Weld")
		weld.Part0 = handle; weld.Part1 = cap; weld.C0 = CFrame.new(0, yOff, 0); weld.Parent = cap
	end

	return handle
end

local function makeCarpetHandle(tool)
	local handle = Instance.new("Part"); handle.Name = "Handle"
	handle.Size = Vector3.new(5, 0.3, 7)
	handle.Color = Color3.fromRGB(255, 100, 100)
	handle.Material = Enum.Material.Fabric; handle.Parent = tool

	local rainbowColors = {
		Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 160, 0),
		Color3.fromRGB(255, 255, 50), Color3.fromRGB(50, 255, 50),
		Color3.fromRGB(50, 150, 255), Color3.fromRGB(130, 50, 255),
		Color3.fromRGB(200, 50, 255),
	}
	local stripeW = 5 / #rainbowColors
	for i, color in ipairs(rainbowColors) do
		local stripe = Instance.new("Part"); stripe.Name = "Stripe" .. i
		stripe.Size = Vector3.new(stripeW, 0.35, 7); stripe.Color = color
		stripe.Material = Enum.Material.Fabric; stripe.CanCollide = false; stripe.Parent = tool
		local weld = Instance.new("Weld")
		weld.Part0 = handle; weld.Part1 = stripe
		weld.C0 = CFrame.new((i - (#rainbowColors + 1) / 2) * stripeW, 0.02, 0); weld.Parent = stripe
	end

	for _, zOff in ipairs({-3.6, 3.6}) do
		local fringe = Instance.new("Part"); fringe.Name = "Fringe"
		fringe.Size = Vector3.new(5.5, 0.15, 0.4)
		fringe.Color = Color3.fromRGB(220, 180, 50)
		fringe.Material = Enum.Material.Fabric; fringe.CanCollide = false; fringe.Parent = tool
		local weld = Instance.new("Weld")
		weld.Part0 = handle; weld.Part1 = fringe; weld.C0 = CFrame.new(0, -0.1, zOff); weld.Parent = fringe
	end

	local glow = Instance.new("Part"); glow.Name = "CarpetGlow"
	glow.Size = Vector3.new(4.5, 0.1, 6.5)
	glow.Color = Color3.fromRGB(255, 220, 100)
	glow.Material = Enum.Material.Neon; glow.Transparency = 0.5
	glow.CanCollide = false; glow.Parent = tool
	local weld = Instance.new("Weld")
	weld.Part0 = handle; weld.Part1 = glow; weld.C0 = CFrame.new(0, -0.3, 0); weld.Parent = glow

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 100)
	light.Brightness = 0.8; light.Range = 10; light.Parent = glow

	return handle
end

local function giveItem(player, itemName)
	print("[CandyRun] Giving item:", itemName, "to", player.Name)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	for _, tool in player.Backpack:GetChildren() do
		if tool.Name == itemName then tool:Destroy() end
	end
	for _, tool in char:GetChildren() do
		if tool:IsA("Tool") and tool.Name == itemName then tool:Destroy() end
	end

	local tool = Instance.new("Tool")
	tool.Name = itemName; tool.CanBeDropped = false; tool.RequiresHandle = true
	if TOOL_ICONS[itemName] then tool.TextureId = TOOL_ICONS[itemName] end

	if itemName == "Speed Coil" then
		makeCoilHandle(tool, Color3.fromRGB(80, 200, 255), Color3.fromRGB(200, 240, 255))
		tool.Equipped:Connect(function()
			if hum then hum.WalkSpeed = hum.WalkSpeed + 30 end
		end)
		tool.Unequipped:Connect(function()
			if hum then hum.WalkSpeed = math.max(hum.WalkSpeed - 30, 100) end
		end)

	elseif itemName == "Gravity Coil" then
		makeCoilHandle(tool, Color3.fromRGB(180, 80, 255), Color3.fromRGB(230, 180, 255))
		tool.Equipped:Connect(function()
			if hum then hum.JumpPower = hum.JumpPower + 20 end
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local bf = Instance.new("BodyForce"); bf.Name = "GravityReducer"
				local mass = 0
				for _, part in char:GetDescendants() do
					if part:IsA("BasePart") then mass += part:GetMass() end
				end
				bf.Force = Vector3.new(0, mass * workspace.Gravity * 0.6, 0)
				bf.Parent = rootPart
			end
		end)
		tool.Unequipped:Connect(function()
			if hum then hum.JumpPower = math.max(hum.JumpPower - 20, 60) end
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local bf = rootPart:FindFirstChild("GravityReducer")
				if bf then bf:Destroy() end
			end
		end)

	elseif itemName == "Fusion Coil" then
		makeCoilHandle(tool, Color3.fromRGB(80, 200, 255), Color3.fromRGB(180, 80, 255))
		tool.Equipped:Connect(function()
			if hum then hum.WalkSpeed = hum.WalkSpeed + 25 end
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local bf = Instance.new("BodyForce"); bf.Name = "FusionGravityReducer"
				local mass = 0
				for _, part in char:GetDescendants() do
					if part:IsA("BasePart") then mass += part:GetMass() end
				end
				bf.Force = Vector3.new(0, mass * workspace.Gravity * 0.5, 0)
				bf.Parent = rootPart
			end
		end)
		tool.Unequipped:Connect(function()
			if hum then hum.WalkSpeed = math.max(hum.WalkSpeed - 25, 100) end
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local bf = rootPart:FindFirstChild("FusionGravityReducer")
				if bf then bf:Destroy() end
			end
		end)

	elseif itemName == "Magic Carpet" then
		makeCarpetHandle(tool)
		tool.Equipped:Connect(function()
			carpetFlyEvent:FireClient(player, true)
		end)
		tool.Unequipped:Connect(function()
			carpetFlyEvent:FireClient(player, false)
			if hum then hum.Sit = false end
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if rootPart then
				for _, name in ipairs({"CarpetGyro", "CarpetVelocity", "CarpetAntiGrav", "MountAntiGrav", "MountVelocity", "MountGyro"}) do
					local obj = rootPart:FindFirstChild(name)
					if obj then obj:Destroy() end
				end
			end
		end)

	elseif itemName == "Grapple Gun" then
		local handle = Instance.new("Part"); handle.Name = "Handle"
		handle.Size = Vector3.new(0.6, 1.2, 2.5)
		handle.Color = Color3.fromRGB(80, 80, 90)
		handle.Material = Enum.Material.Metal; handle.Parent = tool

		local tipPart = Instance.new("Part"); tipPart.Name = "BarrelTip"
		tipPart.Size = Vector3.new(0.7, 0.7, 0.3)
		tipPart.Color = Color3.fromRGB(255, 80, 80)
		tipPart.Material = Enum.Material.Neon; tipPart.CanCollide = false; tipPart.Parent = tool
		local tw = Instance.new("Weld"); tw.Part0 = handle; tw.Part1 = tipPart
		tw.C0 = CFrame.new(0, 0, -1.4); tw.Parent = tipPart

		local gripPart = Instance.new("Part"); gripPart.Name = "Grip"
		gripPart.Size = Vector3.new(0.5, 1.2, 0.5)
		gripPart.Color = Color3.fromRGB(60, 60, 65)
		gripPart.Material = Enum.Material.SmoothPlastic; gripPart.CanCollide = false; gripPart.Parent = tool
		local gw = Instance.new("Weld"); gw.Part0 = handle; gw.Part1 = gripPart
		gw.C0 = CFrame.new(0, -1, 0.3); gw.Parent = gripPart

	elseif itemName == "Boombox" then
		local handle = Instance.new("Part"); handle.Name = "Handle"
		handle.Size = Vector3.new(2.4, 1.6, 1)
		handle.Color = Color3.fromRGB(40, 40, 45)
		handle.Material = Enum.Material.SmoothPlastic; handle.Parent = tool

		for _, side in ipairs({-1, 1}) do
			local speaker = Instance.new("Part"); speaker.Name = "Speaker"
			speaker.Size = Vector3.new(0.8, 0.8, 0.2)
			speaker.Color = Color3.fromRGB(60, 60, 65)
			speaker.Material = Enum.Material.Metal
			speaker.Shape = Enum.PartType.Cylinder
			speaker.CanCollide = false; speaker.Parent = tool
			local sw = Instance.new("Weld"); sw.Part0 = handle; sw.Part1 = speaker
			sw.C0 = CFrame.new(side * 0.7, 0, -0.55) * CFrame.Angles(0, 0, math.rad(90)); sw.Parent = speaker
		end

		local bar = Instance.new("Part"); bar.Name = "CarryBar"
		bar.Size = Vector3.new(1.2, 0.2, 0.2)
		bar.Color = Color3.fromRGB(180, 180, 185)
		bar.Material = Enum.Material.Metal; bar.CanCollide = false; bar.Parent = tool
		local bw = Instance.new("Weld"); bw.Part0 = handle; bw.Part1 = bar
		bw.C0 = CFrame.new(0, 1, 0); bw.Parent = bar

		local strip = Instance.new("Part"); strip.Name = "NeonStrip"
		strip.Size = Vector3.new(1.8, 0.15, 0.15)
		strip.Color = Color3.fromRGB(255, 80, 200)
		strip.Material = Enum.Material.Neon; strip.CanCollide = false; strip.Parent = tool
		local nw = Instance.new("Weld"); nw.Part0 = handle; nw.Part1 = strip
		nw.C0 = CFrame.new(0, -0.5, -0.55); nw.Parent = strip

		local boomSound = Instance.new("Sound"); boomSound.Name = "BoomboxSound"
		boomSound.Volume = 1.5; boomSound.Looped = true
		boomSound.RollOffMaxDistance = 80; boomSound.RollOffMinDistance = 10
		boomSound.Parent = handle
	end

	tool.Parent = player.Backpack
end

-- ============================================================
-- ITEM CAPSULE PURCHASE SYSTEM (find existing triggers)
-- ============================================================

local debounces = {}

local function setupCapsuleTrigger(triggerPart, itemName)
	local prompt = triggerPart:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Buy"
		prompt.ObjectText = itemName .. " (" .. (ITEM_PRICES[itemName] or "?") .. " 🍬)"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = triggerPart
	end

	prompt.Triggered:Connect(function(plr)
		local key = plr.UserId .. itemName
		if debounces[key] then return end
		debounces[key] = true
		task.delay(2, function() debounces[key] = nil end)

		local data = playerData[plr]
		if not data then return end
		local cost = ITEM_PRICES[itemName]
		if not cost then return end

		if (data.candies or 0) < cost then
			purchaseEvent:FireClient(plr, "fail", itemName, cost, data.candies or 0)
			return
		end

		data.candies = data.candies - cost
		candyUpdateEvent:FireClient(plr, data.candies)
		giveItem(plr, itemName)
		purchaseEvent:FireClient(plr, "success", itemName, cost, data.candies)
	end)
end

-- Find capsule triggers in the map
for _, itemName in ipairs({"Speed Coil", "Gravity Coil", "Fusion Coil", "Magic Carpet", "Grapple Gun"}) do
	local trigger = mapFolder:FindFirstChild("Trigger_" .. itemName, true)
	if trigger then
		setupCapsuleTrigger(trigger, itemName)
		print("[CandyRun] Hooked capsule trigger: " .. itemName)
	else
		warn("[CandyRun] Capsule trigger not found: Trigger_" .. itemName)
	end
end

-- ============================================================
-- TRAIL CHEST PURCHASE HANDLERS
-- ============================================================

local trailDebounces = {}

local function hookTrailChest(chestModel, isPremium)
	if not chestModel then return end
	local base = chestModel:FindFirstChild("ChestBase")
	if not base then
		base = chestModel:FindFirstChildWhichIsA("BasePart", true)
	end
	if not base then return end

	local prompt = base:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then return end

	prompt.Triggered:Connect(function(plr)
		if not plr then return end
		local key = plr.UserId .. (isPremium and "premiumtrail" or "trail")
		if trailDebounces[key] then return end
		trailDebounces[key] = true
		task.delay(3, function() trailDebounces[key] = nil end)

		if isPremium then
			MarketplaceService:PromptProductPurchase(plr, 2001)
		else
			local data = playerData[plr]
			if not data then return end
			local cost = 10
			if (data.candies or 0) < cost then
				purchaseEvent:FireClient(plr, "fail", "Trail Chest", cost, data.candies or 0)
				return
			end
			data.candies = data.candies - cost
			candyUpdateEvent:FireClient(plr, data.candies)
			local pick = TRAIL_COLORS[math.random(1, #TRAIL_COLORS)]
			local char = plr.Character
			if char then applyTrail(char, pick.color, false, false, false) end
			trailSpinResultEvent:FireClient(plr, pick.name, {pick.color.R, pick.color.G, pick.color.B})
			purchaseEvent:FireClient(plr, "success", "Trail: " .. pick.name, cost, data.candies)
		end
	end)
end

-- Find trail chests in map
local normalChest = mapFolder:FindFirstChild("TrailChest", true)
local premiumChest = mapFolder:FindFirstChild("PremiumTrailChest", true)
hookTrailChest(normalChest, false)
hookTrailChest(premiumChest, true)

-- Premium trail purchase completion
MarketplaceService.PromptProductPurchaseFinished:Connect(function(plr, productId, isPurchased)
	if productId == 2001 and isPurchased then
		local pick = PREMIUM_TRAIL_COLORS[math.random(1, #PREMIUM_TRAIL_COLORS)]
		local char = plr.Character
		if char then
			applyTrail(char, pick.color, pick.isRainbow or false, pick.isGalaxy or false, pick.isCosmic or false)
		end
		trailSpinResultEvent:FireClient(plr, pick.name, {pick.color.R, pick.color.G, pick.color.B})
		purchaseEvent:FireClient(plr, "success", "Premium Trail: " .. pick.name, 29, 0)
	end
end)

-- ============================================================
-- DAILY SPIN
-- ============================================================

-- Find daily spin model if it exists in map
local spinModel = mapFolder:FindFirstChild("DailySpin", true)
if spinModel then
	local spinTrigger = spinModel:FindFirstChildWhichIsA("BasePart", true)
	if spinTrigger then
		local openPrompt = spinTrigger:FindFirstChildWhichIsA("ProximityPrompt")
		if not openPrompt then
			openPrompt = Instance.new("ProximityPrompt")
			openPrompt.ActionText = "Open"; openPrompt.ObjectText = "Daily Spin"
			openPrompt.KeyboardKeyCode = Enum.KeyCode.E; openPrompt.HoldDuration = 0
			openPrompt.MaxActivationDistance = 14; openPrompt.RequiresLineOfSight = false
			openPrompt.Parent = spinTrigger
		end
		openPrompt.Triggered:Connect(function(plr)
			dailySpinEvent:FireClient(plr, "open")
		end)
	end
end

local PAID_SPIN_PRODUCT_ID = 2002

spinRequestEvent.OnServerEvent:Connect(function(plr, spinType)
	local data = playerData[plr]
	if not data then return end

	if spinType == "free" then
		if data.dailySpinTime and (os.time() - data.dailySpinTime) < 86400 then
			local remaining = 86400 - (os.time() - data.dailySpinTime)
			local hours = math.floor(remaining / 3600)
			local mins = math.floor((remaining % 3600) / 60)
			dailySpinEvent:FireClient(plr, "cooldown", hours .. "h " .. mins .. "m")
			return
		end
		data.dailySpinTime = os.time()
	elseif spinType == "paid" then
		MarketplaceService:PromptProductPurchase(plr, PAID_SPIN_PRODUCT_ID)
		return
	else
		return
	end

	local winIdx, reward = weightedSpinPick()
	applySpinReward(plr, reward)
	dailySpinEvent:FireClient(plr, "result", winIdx, reward.name, reward.icon)
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local plr = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not plr then return Enum.ProductPurchaseDecision.NotProcessedYet end

	if receiptInfo.ProductId == PAID_SPIN_PRODUCT_ID then
		local data = playerData[plr]
		if data then
			local winIdx, reward = weightedSpinPick()
			applySpinReward(plr, reward)
			dailySpinEvent:FireClient(plr, "result", winIdx, reward.name, reward.icon)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if receiptInfo.ProductId == 2001 then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ============================================================
-- BOOMBOX
-- ============================================================

boomboxEvent.OnServerEvent:Connect(function(plr, songId)
	if type(songId) ~= "number" or songId < 0 or songId > 99999999999 then return end
	local function findBoombox()
		local char = plr.Character
		if char then
			for _, child in char:GetChildren() do
				if child:IsA("Tool") and child.Name == "Boombox" then return child end
			end
		end
		for _, child in plr.Backpack:GetChildren() do
			if child.Name == "Boombox" then return child end
		end
		return nil
	end
	local boombox = findBoombox()
	if not boombox then return end
	local handle = boombox:FindFirstChild("Handle")
	if not handle then return end
	local sound = handle:FindFirstChild("BoomboxSound")
	if not sound then return end
	if songId == 0 then
		sound:Stop()
	else
		sound.SoundId = "rbxassetid://" .. tostring(math.floor(songId))
		sound:Stop(); sound:Play()
	end
end)

-- ============================================================
-- GRAPPLE GUN SERVER HANDLER
-- ============================================================

local grappleCooldowns = {}

grappleShootEvent.OnServerEvent:Connect(function(player, origin, direction)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return end
	if grappleCooldowns[player] then return end
	grappleCooldowns[player] = true
	task.delay(2, function() grappleCooldowns[player] = nil end)

	local char = player.Character
	if not char then return end
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local hasGrapple = false
	for _, tool in char:GetChildren() do
		if tool:IsA("Tool") and tool.Name == "Grapple Gun" then hasGrapple = true; break end
	end
	if not hasGrapple then grappleCooldowns[player] = nil; return end

	direction = direction.Unit

	local projectile = Instance.new("Part")
	projectile.Name = "GrappleProjectile"
	projectile.Size = Vector3.new(1.5, 1.5, 1.5)
	projectile.Shape = Enum.PartType.Ball
	projectile.Color = Color3.fromRGB(255, 200, 50)
	projectile.Material = Enum.Material.Neon
	projectile.CFrame = CFrame.new(origin)
	projectile.Anchored = false; projectile.CanCollide = false
	projectile.Parent = workspace

	local pLight = Instance.new("PointLight")
	pLight.Color = Color3.fromRGB(255, 200, 50)
	pLight.Brightness = 2; pLight.Range = 15; pLight.Parent = projectile

	local bv = Instance.new("BodyVelocity")
	bv.Velocity = direction * 150
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6); bv.Parent = projectile

	local att0 = Instance.new("Attachment"); att0.Parent = rootPart
	local att1 = Instance.new("Attachment"); att1.Parent = projectile
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0; beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100))
	beam.Width0 = 0.3; beam.Width1 = 0.3
	beam.FaceCamera = true; beam.Parent = rootPart

	grappleHitEvent:FireClient(player, "fired", projectile)

	local hitSomething = false
	projectile.Touched:Connect(function(hit)
		if hitSomething then return end
		if hit:IsDescendantOf(char) then return end
		if hit.Name == "GrappleProjectile" then return end
		hitSomething = true

		bv:Destroy(); projectile.Anchored = true
		local hitPos = projectile.Position
		local pullDir = (hitPos - rootPart.Position).Unit
		rootPart.AssemblyLinearVelocity = pullDir * 60 + Vector3.new(0, 70, 0)

		grappleHitEvent:FireClient(player, "hit", hitPos)

		task.delay(0.8, function()
			if beam then beam:Destroy() end
			if att0 then att0:Destroy() end
			if att1 then att1:Destroy() end
			if projectile and projectile.Parent then projectile:Destroy() end
		end)
	end)

	task.delay(2, function()
		if not hitSomething then
			if beam then beam:Destroy() end
			if att0 then att0:Destroy() end
			if att1 then att1:Destroy() end
			if projectile and projectile.Parent then projectile:Destroy() end
		end
	end)
end)

-- ============================================================
-- PLAYER / RESPAWN
-- ============================================================

local function getSpawnPosition(player)
	local data = playerData[player]
	if data and data.checkpoint then
		return checkpointPositions[data.checkpoint] or checkpointPositions[0]
	end
	return checkpointPositions[0] or Vector3.new(0, START_HEIGHT + 7, 0)
end

local function onPlayerDied(player)
	local data = playerData[player]
	if not data or data.respawning then return end
	data.respawning = true
	respawnEvent:FireClient(player, 3)
	task.wait(3)
	if player.Parent then
		player:LoadCharacter()
		data.respawning = false
		task.spawn(function()
			local character = player.Character or player.CharacterAdded:Wait()
			local rootPart = character:WaitForChild("HumanoidRootPart", 5)
			if rootPart then
				task.wait(0.1)
				rootPart.CFrame = CFrame.new(getSpawnPosition(player))
			end
			timerStartEvent:FireClient(player)
		end)
	end
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = 100
	humanoid.Died:Connect(function() onPlayerDied(player) end)
end

Players.PlayerAdded:Connect(function(player)
	playerData[player] = {startTime = nil, candies = 0, checkpoint = nil, respawning = false}
	player.CharacterAdded:Connect(function(character) onCharacterAdded(player, character) end)
	if player.Character then onCharacterAdded(player, player.Character) end
end)

Players.PlayerRemoving:Connect(function(player) playerData[player] = nil end)

startGameEvent.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if data then data.startTime = tick(); data.candies = 0; data.checkpoint = nil end
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then rootPart.CFrame = CFrame.new(0, START_HEIGHT + 5, 20) end
	end
	timerStartEvent:FireClient(player)
end)

-- ============================================================
-- INIT
-- ============================================================

print("[CandyRun] Server v7 initialized — static map mode.")
print("[CandyRun] Checkpoints found: " .. tostring(#checkpointPositions))
