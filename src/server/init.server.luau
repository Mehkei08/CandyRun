--[[
	Candy Run - Server Script v4
	Oversized fantasy candy, opaque hallway walls, big spawn with item capsules
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

local startGameEvent = Instance.new("RemoteEvent")
startGameEvent.Name = "StartGame"; startGameEvent.Parent = ReplicatedStorage

local timerEvent = Instance.new("RemoteEvent")
timerEvent.Name = "TimerUpdate"; timerEvent.Parent = ReplicatedStorage

local candyCollectedEvent = Instance.new("RemoteEvent")
candyCollectedEvent.Name = "CandyCollected"; candyCollectedEvent.Parent = ReplicatedStorage

local respawnEvent = Instance.new("RemoteEvent")
respawnEvent.Name = "RespawnTimer"; respawnEvent.Parent = ReplicatedStorage

local timerStartEvent = Instance.new("RemoteEvent")
timerStartEvent.Name = "TimerStart"; timerStartEvent.Parent = ReplicatedStorage

local grappleShootEvent = Instance.new("RemoteEvent")
grappleShootEvent.Name = "GrappleShoot"; grappleShootEvent.Parent = ReplicatedStorage

local grappleHitEvent = Instance.new("RemoteEvent")
grappleHitEvent.Name = "GrappleHit"; grappleHitEvent.Parent = ReplicatedStorage

local grappleShootEvent = Instance.new("RemoteEvent")
grappleShootEvent.Name = "GrappleShoot"; grappleShootEvent.Parent = ReplicatedStorage

local grappleHitEvent = Instance.new("RemoteEvent")
grappleHitEvent.Name = "GrappleHit"; grappleHitEvent.Parent = ReplicatedStorage

local trailChestEvent = Instance.new("RemoteEvent")
trailChestEvent.Name = "TrailChestOpen"; trailChestEvent.Parent = ReplicatedStorage

local trailSpinResultEvent = Instance.new("RemoteEvent")
trailSpinResultEvent.Name = "TrailSpinResult"; trailSpinResultEvent.Parent = ReplicatedStorage

local dailySpinEvent = Instance.new("RemoteEvent")
dailySpinEvent.Name = "DailySpin"; dailySpinEvent.Parent = ReplicatedStorage

-- Interact system remote (E key interactions)
local interactEvent = Instance.new("RemoteEvent")
interactEvent.Name = "InteractPrompt"; interactEvent.Parent = ReplicatedStorage

-- ============================================================
-- LIGHTING
-- ============================================================

Lighting.ClockTime = 15     -- bright afternoon
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

-- Subtle sunrays
local sunrays = Instance.new("SunRaysEffect")
sunrays.Intensity = 0.04; sunrays.Spread = 0.3
sunrays.Parent = Lighting

-- ============================================================
-- FOLDERS & CONSTANTS
-- ============================================================

local mapFolder = Instance.new("Folder"); mapFolder.Name = "CandyMap"; mapFolder.Parent = workspace
local collectiblesFolder = Instance.new("Folder"); collectiblesFolder.Name = "Collectibles"; collectiblesFolder.Parent = workspace
local hallwayFolder = Instance.new("Folder"); hallwayFolder.Name = "Hallway"; hallwayFolder.Parent = workspace

local START_HEIGHT = 250
local HALLWAY_WIDTH = 140
local HALLWAY_HEIGHT = 130
local WALL_SEGMENT_LENGTH = 60
local DEATH_Y = 20
local checkpointPositions = {}
local playerData = {}

-- ============================================================
-- HELPERS
-- ============================================================

local function glow(part, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color or part.Color; l.Range = range or 14
	l.Brightness = brightness or 0.5; l.Parent = part
end

-- Glass sheen overlay helper — gives that polished, realistic candy shine
local function addSheen(parent, size, position, color, shape, orientation)
	local s = Instance.new("Part")
	s.Size = size; s.Position = position; s.Anchored = true
	s.Color = color or Color3.fromRGB(255,255,255)
	s.Material = Enum.Material.Glass
	s.Transparency = 0.82; s.CanCollide = false
	if shape then s.Shape = shape end
	if orientation then s.Orientation = orientation end
	s.Parent = parent
	return s
end

-- ============================================================
-- CANDY PLATFORM LOADER
-- Loads candy models from ServerStorage > CandyModels folder.
-- Loads candy models from ServerStorage > CandyPieces folder.
-- All models inside that folder are auto-discovered and used as parkour platforms.
-- The script clones them, scales them, and positions them as platforms.
-- ============================================================

-- ============================================================
-- DYNAMIC CANDY MODEL LOADER
-- Scans ServerStorage > CandyPieces for all models/meshparts.
-- Each child becomes a usable platform type.
-- ============================================================

local candyPiecesFolder = ServerStorage:FindFirstChild("CandyPieces")
	or ServerStorage:FindFirstChild("CandyModels")
	or ReplicatedStorage:FindFirstChild("CandyPieces")

-- Build list of available candy template names from the folder
local CANDY_TYPES = {}
local candyTemplates = {} -- name -> template instance

if candyPiecesFolder then
	for _, child in candyPiecesFolder:GetChildren() do
		if child:IsA("Model") or child:IsA("BasePart") or child:IsA("MeshPart") then
			local name = child.Name
			table.insert(CANDY_TYPES, name)
			candyTemplates[name] = child
			print("[CandyRun] Found candy piece: " .. name)
		end
	end
	print("[CandyRun] Loaded " .. #CANDY_TYPES .. " candy pieces from " .. candyPiecesFolder.Name)
else
	warn("[CandyRun] WARNING: No CandyPieces folder found in ServerStorage! Parkour will use fallback shapes.")
end

-- If no models found, add a fallback type so the game doesn't break
if #CANDY_TYPES == 0 then
	CANDY_TYPES = {"_fallback"}
end

-- Build a candy platform from a template model
local function buildCandyPlatform(candyName, index, pos, m)
	m = m or 1
	local model = Instance.new("Model"); model.Name = candyName .. "_" .. index

	local template = candyTemplates[candyName]
	local loaded = false

	if template then
		-- Clone the template
		local clone = template:Clone()

		-- Scale all parts by m and anchor them
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				part.Size = part.Size * m
				part.Anchored = true
			end
		end

		-- CLEANUP: Remove grey platforms/bases and tiny useless parts
		local partsToRemove = {}
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				local r, g, b = part.Color.R * 255, part.Color.G * 255, part.Color.B * 255
				local sx, sy, sz = part.Size.X, part.Size.Y, part.Size.Z
				local maxDim = math.max(sx, sy, sz)
				local minDim = math.min(sx, sy, sz)
				
				-- Grey/dark flat platform (base plate) — remove it
				-- A "platform" is grey AND one dimension is much thinner than others
				if r < 120 and g < 120 and b < 120 and (minDim < maxDim * 0.25) and maxDim > 5 then
					table.insert(partsToRemove, part)
				end
				
				-- Tiny decorative bits (all dimensions < 2 studs after scale) — remove
				if sx < 2 and sy < 2 and sz < 2 then
					table.insert(partsToRemove, part)
				end
			end
		end
		for _, part in ipairs(partsToRemove) do
			part:Destroy()
		end

		-- Move to target position while KEEPING the model's original rotation
		-- (candy pieces are oriented correctly in Studio — don't reset that)
		local originalPivot = clone:GetPivot()
		local originalRotation = originalPivot - originalPivot.Position -- extract rotation only
		
		-- Check if model is taller than it is wide (like candyfloss standing up)
		-- If so, rotate it 90 degrees on Z to lay it on its side (jumpable)
		local modelBounds = clone:GetExtentsSize()
		if modelBounds.Y > modelBounds.X * 1.5 and modelBounds.Y > modelBounds.Z * 1.5 then
			-- Model is tall and thin — rotate to lay flat
			originalRotation = originalRotation * CFrame.Angles(0, 0, math.rad(90))
		end
		
		clone:PivotTo(CFrame.new(pos) * originalRotation)

		-- Make ALL parts walkable/collidable (no invisible bases)
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end

		-- Find the largest part to label as "Walkable" for checkpoint detection
		local biggest, biggestVol = nil, 0
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				local vol = part.Size.X * part.Size.Y * part.Size.Z
				if vol > biggestVol then biggest = part; biggestVol = vol end
			end
		end
		if biggest then
			biggest.Name = "Walkable"
		end

		-- Reparent children into our model
		if clone:IsA("Model") then
			for _, child in clone:GetChildren() do
				child.Parent = model
			end
			clone:Destroy()
		else
			-- Single BasePart/MeshPart template
			clone.Name = "Walkable"
			clone.CanCollide = true
			clone.Parent = model
		end
		loaded = true
	end

	-- Fallback: pink ball if model wasn't found
	if not loaded then
		warn("[CandyRun] Missing candy model: " .. candyName .. " — using fallback shape")
		local main = Instance.new("Part")
		main.Name = "Walkable"
		main.Size = Vector3.new(14, 14, 14) * m
		main.Position = pos; main.Anchored = true
		main.Color = Color3.fromRGB(255, 100, 200)
		main.Material = Enum.Material.SmoothPlastic
		main.Shape = Enum.PartType.Ball
		main.TopSurface = Enum.SurfaceType.Smooth
		main.BottomSurface = Enum.SurfaceType.Smooth
		main.Parent = model
		glow(main, Color3.fromRGB(255, 100, 200), 22, 0.5)
	end

	model.Parent = mapFolder
	local walkable = model:FindFirstChild("Walkable")
	return walkable or model:FindFirstChildWhichIsA("BasePart"), model
end

-- Helper: pick a random candy type from the available pieces
local function randomCandy()
	return CANDY_TYPES[math.random(1, #CANDY_TYPES)]
end

-- ============================================================
-- PARKOUR PIECES — Each piece is an absolute (x, y, z) position.
-- This is a real parkour: you jump from piece to piece.
-- Pieces 1-15: single path (learn the jumps)
-- Pieces 16+: branches into LEFT / CENTER / RIGHT paths
-- z goes negative (forward away from spawn)
-- y=0 means START_HEIGHT
-- ============================================================

local PARKOUR_START_Z = -64  -- right at the spawn room exit
local BASE_Y = START_HEIGHT

-- Every single jumpable candy piece in the parkour, in order.
-- Players jump from one to the next. Each has a unique position.
local PARKOUR_PIECES = {
	-- === INTRO (pieces 1-6): Single path, learn to jump ===
	{x=0,    y=0,   z=-64,   size=2.0},   -- 1: starter, right at door
	{x=5,    y=2,   z=-90,   size=1.8},   -- 2: slight right + up
	{x=-8,   y=0,   z=-118,  size=1.7},   -- 3: left
	{x=3,    y=3,   z=-145,  size=1.6},   -- 4: right + up
	{x=-6,   y=1,   z=-172,  size=1.7},   -- 5: left
	{x=0,    y=0,   z=-200,  size=1.9, checkpoint=true},  -- 6: CHECKPOINT 1

	-- === MEDIUM (pieces 7-15): Wider jumps, starts to branch ===
	{x=10,   y=3,   z=-230,  size=1.5},   -- 7: right
	{x=-12,  y=0,   z=-255,  size=1.4},   -- 8: left
	{x=15,   y=4,   z=-282,  size=1.3},   -- 9: far right + high
	{x=-5,   y=1,   z=-310,  size=1.4},   -- 10: center-left
	{x=8,    y=-1,  z=-338,  size=1.3},   -- 11: right + low
	{x=-15,  y=3,   z=-365,  size=1.3},   -- 12: far left + high
	{x=0,    y=0,   z=-395,  size=1.6, checkpoint=true},  -- 13: CHECKPOINT 2

	-- === BRANCHING (pieces 14+): Three paths diverge ===
	-- From checkpoint, player can reach any of 3 next pieces:

	-- LEFT PATH
	{x=-30,  y=2,   z=-425,  size=1.3},   -- 14L
	{x=-35,  y=0,   z=-455,  size=1.2},   -- 15L
	{x=-28,  y=4,   z=-485,  size=1.1},   -- 16L
	{x=-32,  y=1,   z=-515,  size=1.2},   -- 17L

	-- CENTER PATH
	{x=0,    y=5,   z=-430,  size=1.2},   -- 14C (higher, harder)
	{x=5,    y=3,   z=-460,  size=1.1},   -- 15C
	{x=-3,   y=6,   z=-490,  size=1.0},   -- 16C
	{x=2,    y=4,   z=-520,  size=1.1},   -- 17C

	-- RIGHT PATH
	{x=30,   y=2,   z=-425,  size=1.3},   -- 14R
	{x=35,   y=0,   z=-455,  size=1.2},   -- 15R
	{x=28,   y=4,   z=-485,  size=1.1},   -- 16R
	{x=32,   y=1,   z=-515,  size=1.2},   -- 17R

	-- === PATHS MERGE (piece 26+) ===
	-- All three paths lead to these convergence pieces
	{x=-15,  y=2,   z=-545,  size=1.3},   -- 26: left merge
	{x=15,   y=2,   z=-545,  size=1.3},   -- 27: right merge
	{x=0,    y=0,   z=-575,  size=1.7, checkpoint=true},  -- 28: CHECKPOINT 3

	-- === HARD (pieces 29-38): Branches again, smaller, some moving ===
	-- LEFT HARD
	{x=-25,  y=3,   z=-605,  size=1.0, moving=true},  -- 29
	{x=-30,  y=0,   z=-635,  size=0.9},                -- 30
	{x=-22,  y=5,   z=-665,  size=0.9, moving=true},  -- 31

	-- CENTER HARD
	{x=0,    y=6,   z=-610,  size=0.9, moving=true},  -- 32
	{x=5,    y=3,   z=-640,  size=0.8},                -- 33
	{x=-3,   y=7,   z=-670,  size=0.8, moving=true},  -- 34

	-- RIGHT HARD
	{x=25,   y=3,   z=-605,  size=1.0, moving=true},  -- 35
	{x=30,   y=0,   z=-635,  size=0.9},                -- 36
	{x=22,   y=5,   z=-665,  size=0.9, moving=true},  -- 37

	-- === FINAL MERGE ===
	{x=-10,  y=2,   z=-695,  size=1.1},   -- 38: left merge
	{x=10,   y=2,   z=-695,  size=1.1},   -- 39: right merge
	{x=0,    y=0,   z=-725,  size=1.8, checkpoint=true},  -- 40: FINAL CHECKPOINT
}

-- ============================================================
-- COLLECTIBLE
-- ============================================================

-- Item prices (in candy)
local ITEM_PRICES = {
	["Speed Coil"] = 5,
	["Gravity Coil"] = 8,
	["Fusion Coil"] = 15,
	["Magic Carpet"] = 20,
	["Grapple Gun"] = 12,
}

-- Remote for purchase system
local purchaseEvent = Instance.new("RemoteEvent")
purchaseEvent.Name = "PurchaseItem"; purchaseEvent.Parent = ReplicatedStorage

-- Remote for boombox song changes
local boomboxEvent = Instance.new("RemoteEvent")
boomboxEvent.Name = "BoomboxPlay"; boomboxEvent.Parent = ReplicatedStorage

local candyUpdateEvent = Instance.new("RemoteEvent")
candyUpdateEvent.Name = "CandyUpdate"; candyUpdateEvent.Parent = ReplicatedStorage

-- Speed Candy collectible template (from ServerStorage)
local speedCandyTemplate = ServerStorage:FindFirstChild("speed candy")
	or ServerStorage:FindFirstChild("Speed Candy")
	or ServerStorage:FindFirstChild("SpeedCandy")
	or ServerStorage:FindFirstChild("speed_candy")

if speedCandyTemplate then
	print("[CandyRun] Found speed candy collectible model: " .. speedCandyTemplate.Name)
else
	warn("[CandyRun] WARNING: No 'speed candy' model found in ServerStorage — using fallback sphere for collectibles")
end

-- Collect sound ID (magical candy pickup)
local COLLECT_SOUND_ID = "rbxassetid://5619828673" -- sparkly collect sound

local function createCollectible(position, index)
	local model = Instance.new("Model")
	model.Name = "SpeedCandy_"..index

	local pos = position + Vector3.new(0, 8, 0)

	if speedCandyTemplate then
		-- Clone the speed candy model
		local clone = speedCandyTemplate:Clone()
		clone:PivotTo(CFrame.new(pos))
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end
		-- Reparent into our model
		if clone:IsA("Model") then
			for _, child in clone:GetChildren() do
				child.Parent = model
			end
			clone:Destroy()
		else
			clone.Parent = model
		end
	else
		-- Fallback: glowing candy sphere
		local sphere = Instance.new("Part")
		sphere.Name = "CandyBody"
		sphere.Size = Vector3.new(3, 3, 3)
		sphere.Position = pos; sphere.Anchored = true; sphere.CanCollide = false
		sphere.Color = Color3.fromRGB(255, 200, 50)
		sphere.Material = Enum.Material.Neon
		sphere.Shape = Enum.PartType.Ball
		sphere.Parent = model
	end

	-- Glow light
	local firstPart = model:FindFirstChildWhichIsA("BasePart", true)
	if firstPart then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 220, 80)
		light.Brightness = 1.5; light.Range = 14
		light.Parent = firstPart
	end

	-- Collect sound (attached to model, plays on pickup)
	local collectSound = Instance.new("Sound")
	collectSound.Name = "CollectSound"
	collectSound.SoundId = COLLECT_SOUND_ID
	collectSound.Volume = 2
	collectSound.RollOffMaxDistance = 60
	collectSound.Parent = firstPart or model

	-- Floating + spinning animation
	model.Parent = collectiblesFolder
	local bp = pos
	task.spawn(function()
		while model and model.Parent do
			local yOff = math.sin(tick()*2.5)*1.5
			model:PivotTo(CFrame.new(bp + Vector3.new(0, yOff, 0)) * CFrame.Angles(0, math.rad(tick()*60 % 360), 0))
			task.wait(0.03)
		end
	end)

	-- Touch to collect
	local touchPart = Instance.new("Part")
	touchPart.Name = "CollectTrigger"
	touchPart.Size = Vector3.new(6, 6, 6)
	touchPart.Position = pos
	touchPart.Anchored = true; touchPart.Transparency = 1; touchPart.CanCollide = false
	touchPart.Parent = model

	touchPart.Touched:Connect(function(hit)
		local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
		if plr and model.Parent then
			-- Play the collect sound before removing
			local snd = model:FindFirstChild("CollectSound", true)
			if snd then snd:Play() end

			-- Brief delay so sound plays, then hide
			task.delay(0.15, function()
				model.Parent = nil
			end)

			-- Add candy to player's balance
			local data = playerData[plr]
			if data then
				data.candies = (data.candies or 0) + 1
				candyUpdateEvent:FireClient(plr, data.candies)
			end
			candyCollectedEvent:FireClient(plr)

			-- Respawn collectible after 15 seconds
			task.delay(15, function()
				if collectiblesFolder and collectiblesFolder.Parent then
					model.Parent = collectiblesFolder
				end
			end)
		end
	end)
end

-- ============================================================
-- MOVING / CRUMBLING
-- ============================================================

local function makeMoving(model)
	task.spawn(function()
		local range = math.random(8,14); local speed = math.random(25,40)/10
		local startPivot = model:GetPivot(); local steps = math.ceil(speed*30)
		while model and model.Parent do
			for step = 1, steps do
				if not model or not model.Parent then return end
				local a = 0.5-0.5*math.cos((step/steps)*math.pi)
				model:PivotTo(CFrame.new(startPivot.Position + Vector3.new(range*a,0,0)) * startPivot.Rotation)
				task.wait(1/30)
			end
			for step = 1, steps*2 do
				if not model or not model.Parent then return end
				local a = 0.5-0.5*math.cos((step/(steps*2))*math.pi)
				local x = range*(1-2*a)
				model:PivotTo(CFrame.new(startPivot.Position + Vector3.new(x,0,0)) * startPivot.Rotation)
				task.wait(1/30)
			end
			for step = 1, steps do
				if not model or not model.Parent then return end
				local a = 0.5-0.5*math.cos((step/steps)*math.pi)
				model:PivotTo(CFrame.new(startPivot.Position + Vector3.new(-range*(1-a),0,0)) * startPivot.Rotation)
				task.wait(1/30)
			end
		end
	end)
end

local function makeCrumbling(model, walkable)
	local crumbling = false
	walkable.Touched:Connect(function(hit)
		if crumbling then return end
		local ch = hit.Parent; local hum = ch and ch:FindFirstChild("Humanoid")
		if not hum then return end; crumbling = true; task.wait(0.5)
		local parts = {}
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then table.insert(parts, {part=p, oT=p.Transparency, oC=p.CanCollide}) end
		end
		-- Quick fade out
		for step = 1,3 do
			for _, i in ipairs(parts) do i.part.Transparency = i.oT+(1-i.oT)*(step/3) end; task.wait(0.05)
		end
		for _, i in ipairs(parts) do i.part.CanCollide = false end
		-- Reappear after 2 seconds
		task.wait(2)
		for _, i in ipairs(parts) do i.part.CanCollide = i.oC end
		for step = 3,0,-1 do
			for _, i in ipairs(parts) do i.part.Transparency = i.oT+(1-i.oT)*(step/3) end; task.wait(0.05)
		end
		crumbling = false
	end)
end

-- ============================================================
-- CIRCULAR SPAWN PLATFORM (bigger, with item capsules)
-- ============================================================

-- Build a detailed coil display (spiral of rings around a central rod)
local function buildCoilDisplay(parent, position, coilColor, secondaryColor)
	-- Central rod
	local rod = Instance.new("Part")
	rod.Size = Vector3.new(0.6, 5, 0.6)
	rod.Position = position; rod.Anchored = true; rod.CanCollide = false
	rod.Color = Color3.fromRGB(180, 180, 200)
	rod.Material = Enum.Material.Metal; rod.Parent = parent

	-- Spiral rings (12 rings spiraling around the rod)
	for i = 0, 11 do
		local angle = (i / 12) * math.pi * 2 * 3 -- 3 full rotations
		local yOff = (i / 11) * 4 - 2  -- spread along rod
		local radius = 1.2
		local ring = Instance.new("Part")
		ring.Size = Vector3.new(0.8, 0.8, 0.8)
		ring.Position = position + Vector3.new(
			math.cos(angle) * radius,
			yOff,
			math.sin(angle) * radius
		)
		ring.Anchored = true; ring.CanCollide = false
		ring.Color = if i % 2 == 0 then coilColor else secondaryColor
		ring.Material = Enum.Material.Neon
		ring.Shape = Enum.PartType.Ball
		ring.Transparency = 0.1
		ring.Parent = parent
	end

	-- Top cap
	local topCap = Instance.new("Part")
	topCap.Size = Vector3.new(1.5, 0.5, 1.5)
	topCap.Position = position + Vector3.new(0, 2.8, 0)
	topCap.Anchored = true; topCap.CanCollide = false
	topCap.Color = coilColor; topCap.Material = Enum.Material.SmoothPlastic
	topCap.Shape = Enum.PartType.Cylinder
	topCap.Orientation = Vector3.new(0, 0, 90)
	topCap.Parent = parent

	-- Bottom cap
	local botCap = Instance.new("Part")
	botCap.Size = Vector3.new(1.5, 0.5, 1.5)
	botCap.Position = position + Vector3.new(0, -2.8, 0)
	botCap.Anchored = true; botCap.CanCollide = false
	botCap.Color = coilColor; botCap.Material = Enum.Material.SmoothPlastic
	botCap.Shape = Enum.PartType.Cylinder
	botCap.Orientation = Vector3.new(0, 0, 90)
	botCap.Parent = parent

	-- Glow
	local glow = Instance.new("PointLight")
	glow.Color = coilColor; glow.Brightness = 1.5; glow.Range = 15
	glow.Parent = rod

	return rod
end

-- Build a rainbow carpet display
local function buildCarpetDisplay(parent, position)
	local rainbowColors = {
		Color3.fromRGB(255, 50, 50),   -- red
		Color3.fromRGB(255, 160, 0),   -- orange
		Color3.fromRGB(255, 255, 50),  -- yellow
		Color3.fromRGB(50, 255, 50),   -- green
		Color3.fromRGB(50, 150, 255),  -- blue
		Color3.fromRGB(130, 50, 255),  -- indigo
		Color3.fromRGB(200, 50, 255),  -- violet
	}

	local carpetModel = Instance.new("Model")
	carpetModel.Name = "CarpetDisplay"; carpetModel.Parent = parent

	-- Carpet body: flat rectangle made of rainbow stripes
	local stripeWidth = 0.8
	local carpetLength = 5
	local carpetWidth = #rainbowColors * stripeWidth

	for i, color in ipairs(rainbowColors) do
		local stripe = Instance.new("Part")
		stripe.Size = Vector3.new(stripeWidth, 0.3, carpetLength)
		stripe.Position = position + Vector3.new((i - (#rainbowColors+1)/2) * stripeWidth, 0, 0)
		stripe.Anchored = true; stripe.CanCollide = false
		stripe.Color = color
		stripe.Material = Enum.Material.Fabric
		stripe.Parent = carpetModel
	end

	-- Gold fringe on edges
	for _, zOff in ipairs({-carpetLength/2 - 0.2, carpetLength/2 + 0.2}) do
		local fringe = Instance.new("Part")
		fringe.Size = Vector3.new(carpetWidth + 0.5, 0.15, 0.4)
		fringe.Position = position + Vector3.new(0, -0.1, zOff)
		fringe.Anchored = true; fringe.CanCollide = false
		fringe.Color = Color3.fromRGB(220, 180, 50)
		fringe.Material = Enum.Material.Fabric
		fringe.Parent = carpetModel
	end

	-- Gold border along sides
	for _, xOff in ipairs({-carpetWidth/2 - 0.2, carpetWidth/2 + 0.2}) do
		local border = Instance.new("Part")
		border.Size = Vector3.new(0.3, 0.15, carpetLength + 0.8)
		border.Position = position + Vector3.new(xOff, -0.1, 0)
		border.Anchored = true; border.CanCollide = false
		border.Color = Color3.fromRGB(220, 180, 50)
		border.Material = Enum.Material.Fabric
		border.Parent = carpetModel
	end

	-- Subtle glow underneath
	local glowPart = Instance.new("Part")
	glowPart.Size = Vector3.new(carpetWidth, 0.1, carpetLength)
	glowPart.Position = position + Vector3.new(0, -0.3, 0)
	glowPart.Anchored = true; glowPart.CanCollide = false
	glowPart.Color = Color3.fromRGB(255, 220, 100)
	glowPart.Material = Enum.Material.Neon
	glowPart.Transparency = 0.5
	glowPart.Parent = carpetModel

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 100)
	light.Brightness = 1; light.Range = 12
	light.Parent = glowPart

	return carpetModel
end

-- Build a grappling gun display model
local function buildGrappleDisplay(parent, position)
	local gunModel = Instance.new("Model")
	gunModel.Name = "GrappleDisplay"; gunModel.Parent = parent

	local barrel = Instance.new("Part")
	barrel.Size = Vector3.new(1.2, 1.2, 4)
	barrel.Position = position + Vector3.new(0, 0, 1)
	barrel.Anchored = true; barrel.CanCollide = false
	barrel.Color = Color3.fromRGB(80, 80, 90)
	barrel.Material = Enum.Material.Metal; barrel.Parent = gunModel

	local tip = Instance.new("Part")
	tip.Size = Vector3.new(1.4, 1.4, 0.5)
	tip.Position = position + Vector3.new(0, 0, 3.2)
	tip.Anchored = true; tip.CanCollide = false
	tip.Color = Color3.fromRGB(255, 80, 80)
	tip.Material = Enum.Material.Neon; tip.Parent = gunModel

	local grip = Instance.new("Part")
	grip.Size = Vector3.new(0.8, 2, 0.8)
	grip.Position = position + Vector3.new(0, -1.2, 0)
	grip.Anchored = true; grip.CanCollide = false
	grip.Color = Color3.fromRGB(60, 60, 65)
	grip.Material = Enum.Material.SmoothPlastic; grip.Parent = gunModel

	local hook = Instance.new("Part")
	hook.Size = Vector3.new(0.6, 0.6, 0.6)
	hook.Position = position + Vector3.new(0, 0, 3.8)
	hook.Anchored = true; hook.CanCollide = false
	hook.Color = Color3.fromRGB(255, 200, 50)
	hook.Material = Enum.Material.Neon
	hook.Shape = Enum.PartType.Ball; hook.Parent = gunModel

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 100, 100)
	light.Brightness = 1.2; light.Range = 12
	light.Parent = barrel

	return gunModel
end

-- Build a fusion coil display (alternating blue + purple)
local function buildFusionCoilDisplay(parent, position)
	buildCoilDisplay(parent, position, Color3.fromRGB(80, 200, 255), Color3.fromRGB(180, 80, 255))
end

local function createItemCapsule(position, itemName, itemColor, itemEmoji, displayType)
	local model = Instance.new("Model"); model.Name = itemName.."Capsule"

	-- Glass cylinder capsule
	local capsule = Instance.new("Part")
	capsule.Name = "CapsuleShell"
	capsule.Size = Vector3.new(10, 14, 10)
	capsule.Position = position
	capsule.Anchored = true; capsule.Color = itemColor
	capsule.Material = Enum.Material.Glass
	capsule.Shape = Enum.PartType.Cylinder
	capsule.Orientation = Vector3.new(0, 0, 90)
	capsule.Transparency = 0.55
	capsule.CanCollide = false
	capsule.Parent = model

	-- Base pedestal (non-collidable so player can walk in)
	local basePed = Instance.new("Part")
	basePed.Size = Vector3.new(2.5, 12, 12)
	basePed.Position = position + Vector3.new(0, -6.5, 0)
	basePed.Anchored = true; basePed.Color = Color3.fromRGB(60, 60, 70)
	basePed.Material = Enum.Material.SmoothPlastic
	basePed.Shape = Enum.PartType.Cylinder
	basePed.Orientation = Vector3.new(0, 0, 90)
	basePed.CanCollide = false
	basePed.Parent = model

	-- Base accent ring
	local baseAccent = Instance.new("Part")
	baseAccent.Size = Vector3.new(0.8, 13, 13)
	baseAccent.Position = position + Vector3.new(0, -5.5, 0)
	baseAccent.Anchored = true; baseAccent.Color = itemColor
	baseAccent.Material = Enum.Material.Neon
	baseAccent.Shape = Enum.PartType.Cylinder
	baseAccent.Orientation = Vector3.new(0, 0, 90)
	baseAccent.Transparency = 0.3; baseAccent.CanCollide = false
	baseAccent.Parent = model

	-- Top cap
	local topCap = Instance.new("Part")
	topCap.Size = Vector3.new(1.5, 11, 11)
	topCap.Position = position + Vector3.new(0, 7, 0)
	topCap.Anchored = true; topCap.Color = Color3.fromRGB(60, 60, 70)
	topCap.Material = Enum.Material.SmoothPlastic
	topCap.Shape = Enum.PartType.Cylinder
	topCap.Orientation = Vector3.new(0, 0, 90)
	topCap.Parent = model

	-- Display item inside
	if displayType == "speed_coil" then
		local coilParts = buildCoilDisplay(model, position, Color3.fromRGB(80, 200, 255), Color3.fromRGB(200, 240, 255))
		-- Spin
		task.spawn(function()
			local t = 0
			while model and model.Parent do
				t += 0.03
				for _, p in model:GetDescendants() do
					if p:IsA("BasePart") and p.Shape == Enum.PartType.Ball and p.Material == Enum.Material.Neon then
						-- handled by parent model spin below
					end
				end
				task.wait(0.03)
			end
		end)
	elseif displayType == "gravity_coil" then
		buildCoilDisplay(model, position, Color3.fromRGB(180, 80, 255), Color3.fromRGB(230, 180, 255))
	elseif displayType == "carpet" then
		buildCarpetDisplay(model, position)
	elseif displayType == "fusion_coil" then
		buildFusionCoilDisplay(model, position)
	elseif displayType == "grapple" then
		buildGrappleDisplay(model, position)
	end

	-- Slow rotation of display items
	task.spawn(function()
		while model and model.Parent do
			-- Rotate all non-capsule non-pedestal parts
			for _, child in model:GetChildren() do
				if child:IsA("Model") then
					child:PivotTo(child:GetPivot() * CFrame.Angles(0, math.rad(1.5), 0))
				end
			end
			task.wait(0.03)
		end
	end)

	-- Label
	local labelPart = Instance.new("Part")
	labelPart.Size = Vector3.new(1,1,1)
	labelPart.Position = position + Vector3.new(0, 10, 0)
	labelPart.Anchored = true; labelPart.Transparency = 1; labelPart.CanCollide = false
	labelPart.Parent = model

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 55); bb.AlwaysOnTop = false; bb.Parent = labelPart

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1,1); lbl.BackgroundTransparency = 1
	lbl.Text = itemEmoji.." "..itemName
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.TextScaled = true; lbl.Font = Enum.Font.FredokaOne; lbl.Parent = bb

	local stroke = Instance.new("UIStroke")
	stroke.Color = itemColor; stroke.Thickness = 2; stroke.Parent = lbl

	-- Walk-in trigger zone (tall + wide so player reliably touches it)
	local trigger = Instance.new("Part")
	trigger.Name = "Trigger_"..itemName
	trigger.Size = Vector3.new(14, 20, 14)
	trigger.Position = position + Vector3.new(0, -3, 0)
	trigger.Anchored = true; trigger.Transparency = 1; trigger.CanCollide = false
	trigger.Parent = model

	model.Parent = mapFolder
	return trigger
end

-- ============================================================
-- TRAIL COLORS (for chest shop)
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

-- ============================================================
-- DAILY SPIN REWARDS (weighted)
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

-- Apply a trail to a character
local function applyTrail(char, trailColor, isRainbow, isGalaxy, isCosmic)
	-- Clean up existing trails and particles
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
	
	-- Enhanced properties for premium trails
	if isGalaxy or isCosmic then
		trail.LightEmission = 0.8
		trail.LightInfluence = 0.2
	else
		trail.LightEmission = 0.4
		trail.LightInfluence = 0.6
	end
	
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0),
	})
	
	-- Enhanced transparency for rainbow trails
	if isRainbow and not isGalaxy and not isCosmic then
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.2), NumberSequenceKeypoint.new(0.7, 0.6), NumberSequenceKeypoint.new(1, 1),
		})
	else
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1),
		})
	end
	
	-- Color setup based on trail type
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
		-- Dark base with sparkle colors
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 0, 30)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(80, 0, 120)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(20, 0, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 100)),
		})
	elseif isCosmic then
		-- Nebula colors
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
	
	-- Add particle emitter for premium trails
	if isGalaxy or isCosmic then
		local particles = Instance.new("ParticleEmitter")
		particles.Name = "PremiumTrailParticles"
		particles.Color = ColorSequence.new(trailColor)
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		})
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		particles.Lifetime = NumberRange.new(0.5, 1.5)
		particles.Rate = 30
		particles.Speed = NumberRange.new(1, 3)
		particles.SpreadAngle = Vector2.new(30, 30)
		particles.LightEmission = 0.8
		particles.Parent = hrp
	end
end

-- Apply spin reward to a player
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
			hum.WalkSpeed = 56
			task.delay(reward.value * 60, function()
				if hum and hum.Parent then hum.WalkSpeed = 28 end
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

local function createSpawnRoom()
	print("[CandyRun] Creating spawn room...")
	local model = Instance.new("Model"); model.Name = "SpawnRoom"

	-- Room dimensions
	local ROOM_W = 200  -- X width
	local ROOM_D = 120  -- Z depth
	local ROOM_H = 80   -- Y height
	local floorY = START_HEIGHT

	-- ============================================================
	-- FLOOR (candy tile checkerboard)
	-- ============================================================
	local tileSize = 10
	for tx = 0, math.ceil(ROOM_W/tileSize)-1 do
		for tz = 0, math.ceil(ROOM_D/tileSize)-1 do
			local tile = Instance.new("Part")
			tile.Size = Vector3.new(tileSize, 3, tileSize)
			tile.Position = Vector3.new(
				-ROOM_W/2 + tx*tileSize + tileSize/2,
				floorY,
				-ROOM_D/2 + tz*tileSize + tileSize/2
			)
			tile.Anchored = true
			tile.Color = if (tx+tz)%2==0 then Color3.fromRGB(255,180,210) else Color3.fromRGB(255,235,245)
			tile.Material = Enum.Material.SmoothPlastic
			tile.TopSurface = Enum.SurfaceType.Smooth
			tile.BottomSurface = Enum.SurfaceType.Smooth
			tile.Parent = model
		end
	end

	-- ============================================================
	-- WALLS (opaque, candy-colored, decorated)
	-- ============================================================
	local wallThickness = 5
	local wallColors = {
		Color3.fromRGB(255,160,200), Color3.fromRGB(220,150,255),
		Color3.fromRGB(180,210,255), Color3.fromRGB(255,210,170),
	}

	-- Back wall (+Z)
	local backWall = Instance.new("Part")
	backWall.Size = Vector3.new(ROOM_W+wallThickness*2, ROOM_H, wallThickness)
	backWall.Position = Vector3.new(0, floorY+ROOM_H/2, ROOM_D/2+wallThickness/2)
	backWall.Anchored = true; backWall.Color = wallColors[1]
	backWall.Material = Enum.Material.SmoothPlastic; backWall.Parent = model

	-- Left wall (-X)
	local leftWall = Instance.new("Part")
	leftWall.Size = Vector3.new(wallThickness, ROOM_H, ROOM_D+wallThickness*2)
	leftWall.Position = Vector3.new(-ROOM_W/2-wallThickness/2, floorY+ROOM_H/2, 0)
	leftWall.Anchored = true; leftWall.Color = wallColors[2]
	leftWall.Material = Enum.Material.SmoothPlastic; leftWall.Parent = model

	-- Right wall (+X)
	local rightWall = Instance.new("Part")
	rightWall.Size = Vector3.new(wallThickness, ROOM_H, ROOM_D+wallThickness*2)
	rightWall.Position = Vector3.new(ROOM_W/2+wallThickness/2, floorY+ROOM_H/2, 0)
	rightWall.Anchored = true; rightWall.Color = wallColors[3]
	rightWall.Material = Enum.Material.SmoothPlastic; rightWall.Parent = model

	-- Front wall (-Z) with opening for the course
	local doorW = 30
	local frontWallL = Instance.new("Part")
	frontWallL.Size = Vector3.new((ROOM_W-doorW)/2+wallThickness, ROOM_H, wallThickness)
	frontWallL.Position = Vector3.new(-(doorW/2 + frontWallL.Size.X/2) + wallThickness/2, floorY+ROOM_H/2, -ROOM_D/2-wallThickness/2)
	frontWallL.Anchored = true; frontWallL.Color = wallColors[4]
	frontWallL.Material = Enum.Material.SmoothPlastic; frontWallL.Parent = model

	local frontWallR = Instance.new("Part")
	frontWallR.Size = Vector3.new((ROOM_W-doorW)/2+wallThickness, ROOM_H, wallThickness)
	frontWallR.Position = Vector3.new((doorW/2 + frontWallR.Size.X/2) - wallThickness/2, floorY+ROOM_H/2, -ROOM_D/2-wallThickness/2)
	frontWallR.Anchored = true; frontWallR.Color = wallColors[4]
	frontWallR.Material = Enum.Material.SmoothPlastic; frontWallR.Parent = model

	-- Door arch
	local archTop = Instance.new("Part")
	archTop.Size = Vector3.new(doorW+4, 8, wallThickness+2)
	archTop.Position = Vector3.new(0, floorY+ROOM_H-4, -ROOM_D/2-wallThickness/2)
	archTop.Anchored = true; archTop.Color = Color3.fromRGB(255,100,150)
	archTop.Material = Enum.Material.Neon; archTop.Transparency = 0.2
	archTop.CanCollide = false; archTop.Parent = model

	-- ============================================================
	-- CEILING (candy checkerboard)
	-- ============================================================
	local ceilY = floorY + ROOM_H
	for tx = 0, math.ceil(ROOM_W/tileSize)-1 do
		for tz = 0, math.ceil(ROOM_D/tileSize)-1 do
			local ct = Instance.new("Part")
			ct.Size = Vector3.new(tileSize, 2, tileSize)
			ct.Position = Vector3.new(
				-ROOM_W/2 + tx*tileSize + tileSize/2,
				ceilY,
				-ROOM_D/2 + tz*tileSize + tileSize/2
			)
			ct.Anchored = true
			ct.Color = if (tx+tz)%2==0 then Color3.fromRGB(220,170,255) else Color3.fromRGB(255,255,255)
			ct.Material = Enum.Material.SmoothPlastic
			ct.TopSurface = Enum.SurfaceType.Smooth
			ct.BottomSurface = Enum.SurfaceType.Smooth
			ct.Parent = model
		end
	end

	-- ============================================================
	-- WALL DECORATIONS (candy cane pillars along walls, stripes)
	-- ============================================================
	for i = 1, 10 do
		for _, side in ipairs({-1, 1}) do
			local px = side * (ROOM_W/2 - 3)
			local pz = -ROOM_D/2 + i * (ROOM_D / 11)
			local pillar = Instance.new("Part")
			pillar.Size = Vector3.new(3, ROOM_H-5, 3)
			pillar.Position = Vector3.new(px, floorY+ROOM_H/2, pz)
			pillar.Anchored = true; pillar.Color = Color3.fromRGB(255,30,30)
			pillar.Material = Enum.Material.SmoothPlastic; pillar.Parent = model

			local pStripe = Instance.new("Part")
			pStripe.Size = Vector3.new(2.5, ROOM_H-4, 2.5)
			pStripe.Position = Vector3.new(px, floorY+ROOM_H/2, pz)
			pStripe.Anchored = true; pStripe.Color = Color3.fromRGB(255,255,255)
			pStripe.Transparency = 0.35; pStripe.CanCollide = false
			pStripe.Material = Enum.Material.SmoothPlastic; pStripe.Parent = model

			local topBall = Instance.new("Part")
			topBall.Size = Vector3.new(4,4,4)
			topBall.Position = Vector3.new(px, floorY+ROOM_H-3, pz)
			topBall.Anchored = true; topBall.Color = Color3.fromRGB(255,30,30)
			topBall.Shape = Enum.PartType.Ball; topBall.Material = Enum.Material.SmoothPlastic
			topBall.CanCollide = false; topBall.Parent = model
		end
	end

	-- Sprinkles scattered on floor
	local sprColors = {Color3.fromRGB(255,80,80),Color3.fromRGB(80,255,80),Color3.fromRGB(80,80,255),Color3.fromRGB(255,255,80),Color3.fromRGB(255,80,255)}
	for i = 1, 80 do
		local spr = Instance.new("Part")
		spr.Size = Vector3.new(0.5,0.5,1.6)
		spr.Position = Vector3.new(math.random(-85,85), floorY+2, math.random(-50,50))
		spr.Rotation = Vector3.new(0, math.random(0,360), 0)
		spr.Anchored = true; spr.CanCollide = false
		spr.Color = sprColors[math.random(1,#sprColors)]
		spr.Material = Enum.Material.SmoothPlastic
		spr.Parent = model
	end

	-- Neon accent strip along floor edges
	for _, side in ipairs({-1, 1}) do
		local strip = Instance.new("Part")
		strip.Size = Vector3.new(ROOM_W, 0.5, 1)
		strip.Position = Vector3.new(0, floorY+1.8, side*ROOM_D/2)
		strip.Anchored = true; strip.Color = Color3.fromRGB(200,130,255)
		strip.Material = Enum.Material.Neon; strip.Transparency = 0.3
		strip.CanCollide = false; strip.Parent = model

		local strip2 = Instance.new("Part")
		strip2.Size = Vector3.new(1, 0.5, ROOM_D)
		strip2.Position = Vector3.new(side*ROOM_W/2, floorY+1.8, 0)
		strip2.Anchored = true; strip2.Color = Color3.fromRGB(200,130,255)
		strip2.Material = Enum.Material.Neon; strip2.Transparency = 0.3
		strip2.CanCollide = false; strip2.Parent = model
	end

	-- ============================================================
	-- SIGN (above door)
	-- ============================================================
	local sign = Instance.new("Part")
	sign.Size = Vector3.new(30, 7, 2)
	sign.Position = Vector3.new(0, floorY+ROOM_H-10, -ROOM_D/2)
	sign.Anchored = true; sign.Color = Color3.fromRGB(255,100,150)
	sign.Material = Enum.Material.Neon; sign.Parent = model
	local sGui = Instance.new("SurfaceGui"); sGui.Face = Enum.NormalId.Back; sGui.Parent = sign
	local sT = Instance.new("TextLabel")
	sT.Size = UDim2.fromScale(1,1); sT.BackgroundTransparency = 1
	sT.Text = "🍬 CANDY RUN 🍬"; sT.TextColor3 = Color3.fromRGB(255,255,255)
	sT.TextScaled = true; sT.Font = Enum.Font.FredokaOne; sT.Parent = sGui

	-- Also on front side
	local sGui2 = Instance.new("SurfaceGui"); sGui2.Face = Enum.NormalId.Front; sGui2.Parent = sign
	local sT2 = Instance.new("TextLabel")
	sT2.Size = UDim2.fromScale(1,1); sT2.BackgroundTransparency = 1
	sT2.Text = "🍬 CANDY RUN 🍬"; sT2.TextColor3 = Color3.fromRGB(255,255,255)
	sT2.TextScaled = true; sT2.Font = Enum.Font.FredokaOne; sT2.Parent = sGui2

	-- Ceiling lights (row down center of room)
	for i = 1, 8 do
		local lz = -ROOM_D/2 + i * (ROOM_D / 9)
		local rod = Instance.new("Part")
		rod.Size = Vector3.new(0.5, 8, 0.5)
		rod.Position = Vector3.new(0, ceilY-4, lz)
		rod.Anchored = true; rod.Color = Color3.fromRGB(240,230,200)
		rod.Material = Enum.Material.SmoothPlastic; rod.CanCollide = false
		rod.Parent = model

		local lamp = Instance.new("Part")
		lamp.Size = Vector3.new(3, 8, 8)
		lamp.Position = Vector3.new(0, ceilY-10, lz)
		lamp.Anchored = true; lamp.Color = Color3.fromRGB(255,200,230)
		lamp.Material = Enum.Material.Neon; lamp.Shape = Enum.PartType.Cylinder
		lamp.Orientation = Vector3.new(0,0,90)
		lamp.CanCollide = false; lamp.Transparency = 0.1
		lamp.Parent = model

		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255,220,240); pl.Brightness = 1.5; pl.Range = 40
		pl.Parent = lamp
	end

	model.Parent = mapFolder

	-- ============================================================
	-- SPAWN LOCATION
	-- ============================================================
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"; spawn.Size = Vector3.new(12,1,12)
	spawn.Position = Vector3.new(0, floorY+3, 20)
	spawn.Anchored = true; spawn.Transparency = 1
	spawn.CanCollide = false; spawn.Neutral = true
	spawn.Parent = mapFolder

	checkpointPositions[0] = Vector3.new(0, floorY+5, 20)

	-- ============================================================
	-- ITEM SHOP AREA (right side, separated by one long divider wall)
	-- ============================================================
	local InsertService = game:GetService("InsertService")

	-- One long divider wall (pushed back halfway, matching spawn room style)
	local divX = 50 -- halfway across the room
	local divWallColor = wallColors[2] -- same as spawn room left wall color
	local divWallThick = wallThickness -- same thickness as spawn room walls (5)
	local doorWidth = 25
	local doorHeight = 25

	-- Wall above the doorway
	local divWallTop = Instance.new("Part")
	divWallTop.Size = Vector3.new(divWallThick, ROOM_H - doorHeight, ROOM_D)
	divWallTop.Position = Vector3.new(divX, floorY + doorHeight + (ROOM_H - doorHeight)/2, 0)
	divWallTop.Anchored = true; divWallTop.Color = divWallColor
	divWallTop.Material = Enum.Material.SmoothPlastic; divWallTop.Parent = model

	-- Wall segments on either side of doorway
	local doorSegLen = (ROOM_D - doorWidth) / 2
	for _, zs in ipairs({-1, 1}) do
		local segZ = zs * (doorWidth/2 + doorSegLen/2)
		local seg = Instance.new("Part")
		seg.Size = Vector3.new(divWallThick, doorHeight, doorSegLen)
		seg.Position = Vector3.new(divX, floorY + doorHeight/2, segZ)
		seg.Anchored = true; seg.Color = divWallColor
		seg.Material = Enum.Material.SmoothPlastic; seg.Parent = model
	end

	-- Neon archway over doorway
	local doorArch = Instance.new("Part")
	doorArch.Size = Vector3.new(divWallThick + 2, 3, doorWidth + 4)
	doorArch.Position = Vector3.new(divX, floorY + doorHeight + 1, 0)
	doorArch.Anchored = true; doorArch.Color = Color3.fromRGB(255, 180, 50)
	doorArch.Material = Enum.Material.Neon; doorArch.Transparency = 0.2
	doorArch.CanCollide = false; doorArch.Parent = model

	-- "OBBY GAMEPASSES" sign above doorway
	local shopSignP = Instance.new("Part")
	shopSignP.Size = Vector3.new(1,1,1)
	shopSignP.Position = Vector3.new(divX - 3, floorY + doorHeight + 6, 0)
	shopSignP.Anchored = true; shopSignP.Transparency = 1; shopSignP.CanCollide = false; shopSignP.Parent = model
	local shopSignBB = Instance.new("BillboardGui")
	shopSignBB.Size = UDim2.fromOffset(200, 60); shopSignBB.AlwaysOnTop = false; shopSignBB.Parent = shopSignP
	local shopSignLbl = Instance.new("TextLabel")
	shopSignLbl.Size = UDim2.fromScale(1,1); shopSignLbl.BackgroundTransparency = 1
	shopSignLbl.Text = "💎 OBBY GAMEPASSES 💎"
	shopSignLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
	shopSignLbl.TextScaled = true; shopSignLbl.Font = Enum.Font.FredokaOne; shopSignLbl.Parent = shopSignBB
	Instance.new("UIStroke", shopSignLbl).Color = Color3.fromRGB(200, 140, 20)

	-- Item display helper: pedestal + try to load toolbox model, fallback to simple display
	-- Pre-made Roblox toolbox asset IDs for display models
	local TOOLBOX_MODELS = {
		["Speed Coil"]   = 79169137,   -- Speed Coil model
		["Gravity Coil"] = 16437814,   -- Gravity Coil model
		["Fusion Coil"]  = 79169137,   -- Uses speed coil base (recolored)
		["Magic Carpet"] = 452552847,  -- Magic Carpet model
		["Grapple Gun"]  = 88714214,   -- Grappling Hook model
	}

	local function buildGamepassDisplay(position, itemName, itemColor, itemEmoji, robuxPrice, gamepassId)
		local dModel = Instance.new("Model"); dModel.Name = itemName .. "_Display"

		-- Pedestal block
		local ped = Instance.new("Part")
		ped.Name = "Pedestal"
		ped.Size = Vector3.new(10, 4, 10)
		ped.Position = position; ped.Anchored = true
		ped.Color = Color3.fromRGB(60, 50, 70)
		ped.Material = Enum.Material.SmoothPlastic
		ped.TopSurface = Enum.SurfaceType.Smooth; ped.BottomSurface = Enum.SurfaceType.Smooth
		ped.Parent = dModel

		-- Neon accent ring on pedestal
		local ring = Instance.new("Part")
		ring.Size = Vector3.new(2, 11, 11)
		ring.Position = position + Vector3.new(0, 0.5, 0)
		ring.Anchored = true; ring.Color = itemColor
		ring.Material = Enum.Material.Neon; ring.Transparency = 0.4
		ring.Shape = Enum.PartType.Cylinder; ring.Orientation = Vector3.new(0,0,90)
		ring.CanCollide = false; ring.Parent = dModel

		-- Try to load pre-made model from toolbox
		local assetId = TOOLBOX_MODELS[itemName]
		if assetId then
			local ok, toolboxModel = pcall(function()
				return InsertService:LoadAsset(assetId)
			end)
			if ok and toolboxModel then
				-- Position the loaded model on top of the pedestal
				toolboxModel:PivotTo(CFrame.new(position + Vector3.new(0, 6, 0)))
				-- Anchor all parts and disable collision for display
				for _, part in toolboxModel:GetDescendants() do
					if part:IsA("BasePart") then
						part.Anchored = true
						part.CanCollide = false
					end
				end
				toolboxModel.Name = "ToolboxDisplay"
				toolboxModel.Parent = dModel
			end
		end

		-- Glow
		local gl = Instance.new("PointLight")
		gl.Color = itemColor; gl.Brightness = 1.5; gl.Range = 18; gl.Parent = ped

		-- Label (name + price)
		local labelP = Instance.new("Part")
		labelP.Size = Vector3.new(1,1,1); labelP.Position = position + Vector3.new(0, 12, 0)
		labelP.Anchored = true; labelP.Transparency = 1; labelP.CanCollide = false; labelP.Parent = dModel
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(160, 55); bb.AlwaysOnTop = false; bb.Parent = labelP
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 0.55); lbl.BackgroundTransparency = 1
		lbl.Text = itemEmoji .. " " .. itemName
		lbl.TextColor3 = Color3.fromRGB(255,255,255)
		lbl.TextScaled = true; lbl.Font = Enum.Font.FredokaOne; lbl.Parent = bb
		Instance.new("UIStroke", lbl).Color = itemColor
		local priceLbl = Instance.new("TextLabel")
		priceLbl.Size = UDim2.fromScale(1, 0.4); priceLbl.Position = UDim2.fromScale(0, 0.6)
		priceLbl.BackgroundTransparency = 1
		priceLbl.Text = "R$" .. robuxPrice
		priceLbl.TextColor3 = Color3.fromRGB(255, 220, 100)
		priceLbl.TextScaled = true; priceLbl.Font = Enum.Font.GothamBold; priceLbl.Parent = bb

		-- ProximityPrompt (hold E to buy)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Buy"
		prompt.ObjectText = itemName .. " (R$" .. robuxPrice .. ")"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = ped

		dModel.Parent = mapFolder
		return prompt, gamepassId
	end

	-- All 5 gamepasses lined up parallel against the far right wall
	local itemX = 85  -- close to the right wall (wall is at X=100)
	local itemStartZ = -35
	local itemSpacing = 16

	local speedPrompt, speedGamepassId = buildGamepassDisplay(
		Vector3.new(itemX, floorY + 4, itemStartZ),
		"Speed Coil", Color3.fromRGB(80, 200, 255), "⚡", 49, 1001
	)
	local gravityPrompt, gravityGamepassId = buildGamepassDisplay(
		Vector3.new(itemX, floorY + 4, itemStartZ + itemSpacing),
		"Gravity Coil", Color3.fromRGB(180, 80, 255), "🌀", 79, 1002
	)
	local fusionPrompt, fusionGamepassId = buildGamepassDisplay(
		Vector3.new(itemX, floorY + 4, itemStartZ + itemSpacing*2),
		"Fusion Coil", Color3.fromRGB(130, 140, 255), "💫", 149, 1003
	)
	local carpetPrompt, carpetGamepassId = buildGamepassDisplay(
		Vector3.new(itemX, floorY + 4, itemStartZ + itemSpacing*3),
		"Magic Carpet", Color3.fromRGB(255, 180, 50), "🧞", 199, 1004
	)
	local grapplePrompt, grappleGamepassId = buildGamepassDisplay(
		Vector3.new(itemX, floorY + 4, itemStartZ + itemSpacing*4),
		"Grapple Gun", Color3.fromRGB(255, 80, 80), "🪝", 99, 1005
	)

	-- ============================================================
	-- TRAIL CHEST SHOPS (left side, near front)
	-- ============================================================
	local function buildTrailChest(position)
		local chestModel = Instance.new("Model"); chestModel.Name = "TrailChest"

		-- Chest base
		local base = Instance.new("Part")
		base.Name = "ChestBase"
		base.Size = Vector3.new(6, 4, 5)
		base.Position = position; base.Anchored = true
		base.Color = Color3.fromRGB(160, 100, 40)
		base.Material = Enum.Material.SmoothPlastic; base.Parent = chestModel

		-- Lid
		local lid = Instance.new("Part")
		lid.Size = Vector3.new(6.2, 3, 5.2)
		lid.Position = position + Vector3.new(0, 3.5, 0)
		lid.Anchored = true; lid.Color = Color3.fromRGB(180, 120, 50)
		lid.Material = Enum.Material.SmoothPlastic
		lid.Shape = Enum.PartType.Ball; lid.Parent = chestModel

		-- Gold trim
		local trim = Instance.new("Part")
		trim.Size = Vector3.new(6.4, 0.5, 5.4)
		trim.Position = position + Vector3.new(0, 2, 0)
		trim.Anchored = true; trim.Color = Color3.fromRGB(255, 215, 0)
		trim.Material = Enum.Material.Neon; trim.CanCollide = false; trim.Parent = chestModel

		-- Lock
		local lock = Instance.new("Part")
		lock.Size = Vector3.new(1.2, 1.2, 0.5)
		lock.Position = position + Vector3.new(0, 2, -2.8)
		lock.Anchored = true; lock.Color = Color3.fromRGB(255, 215, 0)
		lock.Material = Enum.Material.Metal; lock.Shape = Enum.PartType.Ball
		lock.CanCollide = false; lock.Parent = chestModel

		local gl = Instance.new("PointLight")
		gl.Color = Color3.fromRGB(255, 200, 50); gl.Brightness = 1.5; gl.Range = 20; gl.Parent = base

		-- Label
		local labelP = Instance.new("Part")
		labelP.Size = Vector3.new(1,1,1); labelP.Position = position + Vector3.new(0, 8, 0)
		labelP.Anchored = true; labelP.Transparency = 1; labelP.CanCollide = false; labelP.Parent = chestModel
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(200, 60); bb.AlwaysOnTop = false; bb.Parent = labelP
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1,1); lbl.BackgroundTransparency = 1
		lbl.Text = "🎁 Trail Chest - 10 🍬"
		lbl.TextColor3 = Color3.fromRGB(255, 220, 80)
		lbl.TextScaled = true; lbl.Font = Enum.Font.FredokaOne; lbl.Parent = bb
		Instance.new("UIStroke", lbl).Color = Color3.fromRGB(160, 100, 20)

		-- ProximityPrompt (hold E)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = "Trail Chest (10 🍬)"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = base

		chestModel.Parent = mapFolder
		return prompt
	end

	-- Create normal trail chest (left position)
	local chestPromptL = buildTrailChest(Vector3.new(-40, floorY + 4, -15))
	
	-- Create premium trail chest (right position, golden appearance)
	local function buildPremiumTrailChest(position)
		local chestModel = Instance.new("Model"); chestModel.Name = "PremiumTrailChest"

		-- Chest base (gold)
		local base = Instance.new("Part")
		base.Name = "ChestBase"
		base.Size = Vector3.new(6, 4, 5)
		base.Position = position; base.Anchored = true
		base.Color = Color3.fromRGB(255, 215, 0)
		base.Material = Enum.Material.Neon; base.Parent = chestModel

		-- Lid (gold)
		local lid = Instance.new("Part")
		lid.Size = Vector3.new(6.2, 3, 5.2)
		lid.Position = position + Vector3.new(0, 3.5, 0)
		lid.Anchored = true; lid.Color = Color3.fromRGB(255, 200, 0)
		lid.Material = Enum.Material.Neon
		lid.Shape = Enum.PartType.Ball; lid.Parent = chestModel

		-- Premium trim (bright gold)
		local trim = Instance.new("Part")
		trim.Size = Vector3.new(6.4, 0.5, 5.4)
		trim.Position = position + Vector3.new(0, 2, 0)
		trim.Anchored = true; trim.Color = Color3.fromRGB(255, 255, 150)
		trim.Material = Enum.Material.Neon; trim.CanCollide = false; trim.Parent = chestModel

		-- Diamond lock
		local lock = Instance.new("Part")
		lock.Size = Vector3.new(1.2, 1.2, 0.5)
		lock.Position = position + Vector3.new(0, 2, -2.8)
		lock.Anchored = true; lock.Color = Color3.fromRGB(150, 255, 255)
		lock.Material = Enum.Material.Neon; lock.Shape = Enum.PartType.Ball
		lock.CanCollide = false; lock.Parent = chestModel

		-- Bright glow
		local gl = Instance.new("PointLight")
		gl.Color = Color3.fromRGB(255, 220, 80); gl.Brightness = 2.5; gl.Range = 25; gl.Parent = base

		-- Premium label
		local labelP = Instance.new("Part")
		labelP.Size = Vector3.new(1,1,1); labelP.Position = position + Vector3.new(0, 8, 0)
		labelP.Anchored = true; labelP.Transparency = 1; labelP.CanCollide = false; labelP.Parent = chestModel
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(200, 60); bb.AlwaysOnTop = false; bb.Parent = labelP
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1,1); lbl.BackgroundTransparency = 1
		lbl.Text = "👑 Premium Chest - R$29"
		lbl.TextColor3 = Color3.fromRGB(255, 220, 80)
		lbl.TextScaled = true; lbl.Font = Enum.Font.FredokaOne; lbl.Parent = bb
		Instance.new("UIStroke", lbl).Color = Color3.fromRGB(200, 160, 20)

		-- ProximityPrompt (hold E)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Buy"
		prompt.ObjectText = "Premium Trail Chest (R$29)"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = base

		chestModel.Parent = mapFolder
		return prompt
	end
	
	local premiumChestPrompt = buildPremiumTrailChest(Vector3.new(-40, floorY + 4, 15))

	-- Trail chest purchase handlers
	local trailDebounces = {}
	local function handleNormalTrailChest(plr)
		if not plr then return end
		local key = plr.UserId .. "trail"
		if trailDebounces[key] then return end
		trailDebounces[key] = true
		task.delay(3, function() trailDebounces[key] = nil end)

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

	local function handlePremiumTrailChest(plr)
		if not plr then return end
		local key = plr.UserId .. "premiumtrail"
		if trailDebounces[key] then return end
		trailDebounces[key] = true
		task.delay(3, function() trailDebounces[key] = nil end)

		-- Use MarketplaceService to prompt dev product purchase
		MarketplaceService:PromptProductPurchase(plr, 2001)
	end

	chestPromptL.Triggered:Connect(function(plr) handleNormalTrailChest(plr) end)
	premiumChestPrompt.Triggered:Connect(function(plr) handlePremiumTrailChest(plr) end)

	-- Handle premium trail purchase completion
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
	-- DAILY SPIN WHEEL (front-left, carnival style, VERTICAL facing -Z)
	-- Pizza-slice segments with black text labels, slow idle rotation,
	-- carnival ribbons, no floating 3D objects
	-- Players view the wheel from the front (looking at the -Z face)
	-- ============================================================
	local SPIN_X = -55
	local SPIN_Z = -40
	local WHEEL_RADIUS = 16
	local NUM_SEGMENTS = #SPIN_REWARDS
	local wheelModel = Instance.new("Model"); wheelModel.Name = "DailySpinWheel"

	-- Wheel center: raised so the wheel face is at eye level
	local WHEEL_CENTER_Y = floorY + WHEEL_RADIUS + 6
	local wheelCenterY = WHEEL_CENTER_Y

	-- ---- CARNIVAL BOOTH FRAME (striped pillars + canopy + ribbons) ----
	for _, sx in ipairs({-1, 1}) do
		local pillar = Instance.new("Part")
		pillar.Size = Vector3.new(3, 50, 3)
		pillar.Position = Vector3.new(SPIN_X + sx * 22, floorY + 25, SPIN_Z + 2)
		pillar.Anchored = true; pillar.Color = Color3.fromRGB(255, 40, 40)
		pillar.Material = Enum.Material.SmoothPlastic; pillar.Parent = wheelModel
		local pStripe = Instance.new("Part")
		pStripe.Size = Vector3.new(2.5, 50, 2.5)
		pStripe.Position = pillar.Position; pStripe.Anchored = true
		pStripe.Color = Color3.fromRGB(255,255,255); pStripe.Transparency = 0.4
		pStripe.Material = Enum.Material.SmoothPlastic; pStripe.CanCollide = false; pStripe.Parent = wheelModel
	end
	local canopy = Instance.new("Part")
	canopy.Size = Vector3.new(48, 3, 12)
	canopy.Position = Vector3.new(SPIN_X, floorY + 51, SPIN_Z + 2)
	canopy.Anchored = true; canopy.Color = Color3.fromRGB(255, 220, 50)
	canopy.Material = Enum.Material.Fabric; canopy.Parent = wheelModel
	local canopyStripe = Instance.new("Part")
	canopyStripe.Size = Vector3.new(48, 1, 12)
	canopyStripe.Position = Vector3.new(SPIN_X, floorY + 52.5, SPIN_Z + 2)
	canopyStripe.Anchored = true; canopyStripe.Color = Color3.fromRGB(255, 50, 50)
	canopyStripe.Material = Enum.Material.Fabric; canopyStripe.CanCollide = false; canopyStripe.Parent = wheelModel

	-- ---- CARNIVAL RIBBONS ----
	local ribbonColors = {
		Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 200, 50),
		Color3.fromRGB(80, 200, 255), Color3.fromRGB(255, 100, 200),
		Color3.fromRGB(100, 255, 150), Color3.fromRGB(200, 100, 255),
	}
	for ri = 1, 12 do
		local ribbonX = SPIN_X - 22 + (ri - 1) * 4
		local ribbon = Instance.new("Part")
		ribbon.Size = Vector3.new(0.6, math.random(8, 16), 0.15)
		ribbon.Position = Vector3.new(ribbonX, floorY + 51 - ribbon.Size.Y / 2, SPIN_Z - 4)
		ribbon.Anchored = true
		ribbon.Color = ribbonColors[(ri % #ribbonColors) + 1]
		ribbon.Material = Enum.Material.Fabric
		ribbon.CanCollide = false
		ribbon.Rotation = Vector3.new(0, 0, math.random(-8, 8))
		ribbon.Parent = wheelModel
	end
	for _, sx in ipairs({-1, 1}) do
		for ci = 1, 3 do
			local cornerRibbon = Instance.new("Part")
			cornerRibbon.Size = Vector3.new(0.8, math.random(14, 22), 0.2)
			cornerRibbon.Position = Vector3.new(
				SPIN_X + sx * 22 + ci * sx * 1.5,
				floorY + 50 - cornerRibbon.Size.Y / 2,
				SPIN_Z - 2
			)
			cornerRibbon.Anchored = true
			cornerRibbon.Color = ribbonColors[(ci + (if sx == -1 then 0 else 3)) % #ribbonColors + 1]
			cornerRibbon.Material = Enum.Material.Fabric
			cornerRibbon.CanCollide = false
			cornerRibbon.Rotation = Vector3.new(math.random(-5, 5), 0, math.random(-12, 12))
			cornerRibbon.Parent = wheelModel
		end
	end

	-- ---- BACK WALL (behind the wheel, so you see the wheel face from front) ----
	local wheelBackWall = Instance.new("Part")
	wheelBackWall.Size = Vector3.new(WHEEL_RADIUS * 2 + 10, WHEEL_RADIUS * 2 + 10, 2)
	wheelBackWall.Position = Vector3.new(SPIN_X, wheelCenterY, SPIN_Z + 3)
	wheelBackWall.Anchored = true; wheelBackWall.Color = Color3.fromRGB(40, 20, 50)
	wheelBackWall.Material = Enum.Material.SmoothPlastic; wheelBackWall.CanCollide = true
	wheelBackWall.Parent = wheelModel

	-- ---- PEDESTAL (base under the wheel) ----
	local pedestal = Instance.new("Part")
	pedestal.Name = "SpinPedestal"
	pedestal.Size = Vector3.new(8, 5, 8)
	pedestal.Position = Vector3.new(SPIN_X, floorY + 4, SPIN_Z)
	pedestal.Anchored = true; pedestal.Color = Color3.fromRGB(80, 30, 30)
	pedestal.Material = Enum.Material.Wood
	pedestal.Parent = wheelModel

	-- ---- SPINNING WHEEL SUB-MODEL (all rotating parts go here) ----
	local spinningParts = Instance.new("Model")
	spinningParts.Name = "SpinningWheel"
	spinningParts.Parent = wheelModel

	-- Main wheel disc (VERTICAL, facing -Z so players see it from the front)
	-- Cylinder axis = Y by default. We rotate 90° on X to make it vertical (face -Z/+Z)
	local wheelDisc = Instance.new("Part")
	wheelDisc.Name = "WheelDisc"
	wheelDisc.Size = Vector3.new(WHEEL_RADIUS * 2 + 2, 2, WHEEL_RADIUS * 2 + 2)
	wheelDisc.CFrame = CFrame.new(SPIN_X, wheelCenterY, SPIN_Z) * CFrame.Angles(math.rad(90), 0, 0)
	wheelDisc.Anchored = true; wheelDisc.Color = Color3.fromRGB(245, 235, 220)
	wheelDisc.Material = Enum.Material.SmoothPlastic
	wheelDisc.Shape = Enum.PartType.Cylinder
	wheelDisc.Parent = spinningParts

	-- Gold neon outer rim (vertical)
	local rim = Instance.new("Part")
	rim.Size = Vector3.new(WHEEL_RADIUS * 2 + 6, 3, WHEEL_RADIUS * 2 + 6)
	rim.CFrame = CFrame.new(SPIN_X, wheelCenterY, SPIN_Z + 0.5) * CFrame.Angles(math.rad(90), 0, 0)
	rim.Anchored = true; rim.Color = Color3.fromRGB(255, 215, 0)
	rim.Material = Enum.Material.Neon; rim.Transparency = 0.3
	rim.Shape = Enum.PartType.Cylinder
	rim.CanCollide = false; rim.Parent = spinningParts

	-- Carnival lights around the rim (vertical circle on XY plane)
	for i = 1, 16 do
		local bAngle = (i / 16) * math.pi * 2
		local bulb = Instance.new("Part")
		bulb.Size = Vector3.new(1.5, 1.5, 1.5)
		bulb.Position = Vector3.new(
			SPIN_X + math.cos(bAngle) * (WHEEL_RADIUS + 4),
			wheelCenterY + math.sin(bAngle) * (WHEEL_RADIUS + 4),
			SPIN_Z - 1
		)
		bulb.Anchored = true; bulb.Shape = Enum.PartType.Ball
		bulb.Color = if i % 2 == 0 then Color3.fromRGB(255, 50, 50) else Color3.fromRGB(255, 255, 80)
		bulb.Material = Enum.Material.Neon; bulb.CanCollide = false; bulb.Parent = spinningParts
	end

	-- ---- PIE-CUT SEGMENTS (vertical, on the XY plane) ----
	local altColors = {
		Color3.fromRGB(255, 200, 50),  Color3.fromRGB(80, 200, 255),
		Color3.fromRGB(255, 100, 200), Color3.fromRGB(100, 255, 150),
		Color3.fromRGB(255, 140, 60),  Color3.fromRGB(180, 80, 255),
		Color3.fromRGB(255, 220, 100), Color3.fromRGB(100, 220, 220),
	}

	for i, reward in ipairs(SPIN_REWARDS) do
		local angle = ((i - 1) / NUM_SEGMENTS) * math.pi * 2
		local midAngle = angle + math.pi / NUM_SEGMENTS
		local segColor = altColors[((i - 1) % #altColors) + 1]

		-- Pie slice radiating from center (vertical, on XY plane)
		local seg = Instance.new("Part")
		seg.Name = "Segment_" .. i
		seg.Size = Vector3.new(5.5, WHEEL_RADIUS * 0.85, 1.8)
		seg.CFrame = CFrame.new(
			SPIN_X + math.cos(midAngle) * (WHEEL_RADIUS * 0.42),
			wheelCenterY + math.sin(midAngle) * (WHEEL_RADIUS * 0.42),
			SPIN_Z - 0.2
		) * CFrame.Angles(0, 0, midAngle - math.pi / 2)
		seg.Anchored = true; seg.Color = segColor
		seg.Material = Enum.Material.SmoothPlastic; seg.CanCollide = false
		seg.Parent = spinningParts

		-- Pizza-cut divider line (vertical)
		local divider = Instance.new("Part")
		divider.Size = Vector3.new(0.3, WHEEL_RADIUS * 0.95, 2)
		divider.CFrame = CFrame.new(
			SPIN_X + math.cos(angle) * (WHEEL_RADIUS * 0.45),
			wheelCenterY + math.sin(angle) * (WHEEL_RADIUS * 0.45),
			SPIN_Z - 0.3
		) * CFrame.Angles(0, 0, angle - math.pi / 2)
		divider.Anchored = true; divider.Color = Color3.fromRGB(40, 25, 50)
		divider.Material = Enum.Material.SmoothPlastic; divider.CanCollide = false
		divider.Parent = spinningParts

		-- Reward NAME label (BLACK text on a vertical SurfaceGui facing -Z)
		local segLblP = Instance.new("Part")
		segLblP.Name = "SegLabel_" .. i
		segLblP.Size = Vector3.new(5, 2.5, 0.1)
		segLblP.CFrame = CFrame.new(
			SPIN_X + math.cos(midAngle) * (WHEEL_RADIUS * 0.55),
			wheelCenterY + math.sin(midAngle) * (WHEEL_RADIUS * 0.55),
			SPIN_Z - 1.2
		) * CFrame.Angles(0, 0, midAngle - math.pi / 2)
		segLblP.Anchored = true; segLblP.Transparency = 0.95; segLblP.CanCollide = false
		segLblP.Parent = spinningParts

		local sGui = Instance.new("SurfaceGui")
		sGui.Face = Enum.NormalId.Back; sGui.Parent = segLblP
		local segLbl = Instance.new("TextLabel")
		segLbl.Size = UDim2.fromScale(1, 1); segLbl.BackgroundTransparency = 1
		segLbl.Text = reward.name
		segLbl.TextColor3 = Color3.fromRGB(0, 0, 0) -- BLACK text
		segLbl.TextScaled = true; segLbl.Font = Enum.Font.FredokaOne
		segLbl.Parent = sGui
	end

	-- Center hub (gold, vertical)
	local hub = Instance.new("Part")
	hub.Size = Vector3.new(5, 5, 3)
	hub.CFrame = CFrame.new(SPIN_X, wheelCenterY, SPIN_Z - 0.5) * CFrame.Angles(math.rad(90), 0, 0)
	hub.Anchored = true; hub.Color = Color3.fromRGB(255, 215, 0)
	hub.Material = Enum.Material.Metal; hub.Shape = Enum.PartType.Cylinder
	hub.Parent = spinningParts

	-- ---- STATIC PARTS (pointer, label) ----
	-- Pointer arrow at TOP of wheel (does NOT rotate) — points down at winning segment
	local pointer = Instance.new("Part")
	pointer.Name = "SpinPointer"
	pointer.Size = Vector3.new(3, 5, 3)
	pointer.Position = Vector3.new(SPIN_X, wheelCenterY + WHEEL_RADIUS + 3, SPIN_Z - 2)
	pointer.Anchored = true; pointer.Color = Color3.fromRGB(255, 50, 50)
	pointer.Material = Enum.Material.Neon; pointer.Shape = Enum.PartType.Ball
	pointer.Parent = wheelModel

	-- "DAILY SPIN" billboard label above the wheel
	local spinLabelP = Instance.new("Part")
	spinLabelP.Size = Vector3.new(1, 1, 1)
	spinLabelP.Position = Vector3.new(SPIN_X, wheelCenterY + WHEEL_RADIUS + 10, SPIN_Z)
	spinLabelP.Anchored = true; spinLabelP.Transparency = 1; spinLabelP.CanCollide = false
	spinLabelP.Parent = wheelModel
	local spinBB = Instance.new("BillboardGui")
	spinBB.Size = UDim2.fromOffset(250, 70); spinBB.AlwaysOnTop = false; spinBB.Parent = spinLabelP
	local spinLbl = Instance.new("TextLabel")
	spinLbl.Size = UDim2.fromScale(1, 1); spinLbl.BackgroundTransparency = 1
	spinLbl.Text = "\xF0\x9F\x8E\xA1 DAILY SPIN \xF0\x9F\x8E\xA1"
	spinLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
	spinLbl.TextScaled = true; spinLbl.Font = Enum.Font.FredokaOne; spinLbl.Parent = spinBB
	Instance.new("UIStroke", spinLbl).Color = Color3.fromRGB(200, 140, 20)

	-- ProximityPrompt on pedestal
	local spinPrompt = Instance.new("ProximityPrompt")
	spinPrompt.ActionText = "Spin"
	spinPrompt.ObjectText = "Daily Spin (Hold E)"
	spinPrompt.KeyboardKeyCode = Enum.KeyCode.E
	spinPrompt.HoldDuration = 0.8
	spinPrompt.MaxActivationDistance = 15
	spinPrompt.RequiresLineOfSight = false
	spinPrompt.Parent = pedestal

	wheelModel.Parent = mapFolder

	-- ---- SLOW IDLE ROTATION (spins around Z axis for vertical wheel) ----
	local wheelSpinning = false
	local idleAngle = 0
	local IDLE_SPEED = 0.3 -- degrees per frame (~9 deg/sec)
	local wheelPivot = CFrame.new(SPIN_X, wheelCenterY, SPIN_Z)

	task.spawn(function()
		while wheelModel and wheelModel.Parent do
			if not wheelSpinning then
				idleAngle = (idleAngle + IDLE_SPEED) % 360
				spinningParts:PivotTo(wheelPivot * CFrame.Angles(0, 0, math.rad(idleAngle)))
			end
			task.wait(0.03)
		end
	end)

	-- ---- SPIN LOGIC ----
	spinPrompt.Triggered:Connect(function(plr)
		if wheelSpinning then return end
		local data = playerData[plr]
		if not data then return end

		-- 24h cooldown
		if data.dailySpinTime and (os.time() - data.dailySpinTime) < 86400 then
			local remaining = 86400 - (os.time() - data.dailySpinTime)
			local hours = math.floor(remaining / 3600)
			local mins = math.floor((remaining % 3600) / 60)
			dailySpinEvent:FireClient(plr, 0, "cooldown", hours .. "h " .. mins .. "m")
			return
		end

		data.dailySpinTime = os.time()
		wheelSpinning = true
		local winIdx, reward = weightedSpinPick()

		local targetSegAngle = ((winIdx - 1) / NUM_SEGMENTS) * 360
		local totalRotation = (math.random(4, 7) * 360) + targetSegAngle
		local spinDuration = 5
		local startAngle = idleAngle
		local startT = tick()

		task.spawn(function()
			while true do
				local elapsed = tick() - startT
				if elapsed >= spinDuration then break end
				local eased = 1 - (1 - elapsed / spinDuration) ^ 3
				local currentAngle = startAngle + totalRotation * eased
				spinningParts:PivotTo(wheelPivot * CFrame.Angles(0, 0, math.rad(currentAngle)))
				task.wait(0.03)
			end

			local finalAngle = startAngle + totalRotation
			spinningParts:PivotTo(wheelPivot * CFrame.Angles(0, 0, math.rad(finalAngle)))
			idleAngle = finalAngle % 360

			applySpinReward(plr, reward)
			dailySpinEvent:FireClient(plr, winIdx, reward.name, reward.icon)
			wheelSpinning = false
		end)
	end)

	dailySpinEvent.OnServerEvent:Connect(function(plr)
		-- Handled by ProximityPrompt
	end)

	-- Build a coil-shaped tool handle
	local function makeCoilHandle(tool, coilColor, secondaryColor)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.5, 3, 0.5)
		handle.Color = Color3.fromRGB(180, 180, 200)
		handle.Material = Enum.Material.Metal
		handle.Parent = tool

		-- Spiral coil rings around the handle
		for i = 0, 8 do
			local angle = (i / 8) * math.pi * 2 * 2.5
			local yOff = (i / 8) * 2.5 - 1.25
			local ring = Instance.new("Part")
			ring.Name = "CoilRing"
			ring.Size = Vector3.new(0.5, 0.5, 0.5)
			ring.Shape = Enum.PartType.Ball
			ring.Color = if i % 2 == 0 then coilColor else secondaryColor
			ring.Material = Enum.Material.Neon
			ring.CanCollide = false
			ring.Parent = tool

			local weld = Instance.new("Weld")
			weld.Part0 = handle; weld.Part1 = ring
			weld.C0 = CFrame.new(math.cos(angle)*0.8, yOff, math.sin(angle)*0.8)
			weld.Parent = ring
		end

		-- Top/bottom caps
		for _, yOff in ipairs({-1.6, 1.6}) do
			local cap = Instance.new("Part")
			cap.Name = "Cap"
			cap.Size = Vector3.new(1, 0.3, 1)
			cap.Color = coilColor
			cap.Material = Enum.Material.SmoothPlastic
			cap.Shape = Enum.PartType.Cylinder
			cap.Orientation = Vector3.new(0, 0, 90)
			cap.CanCollide = false
			cap.Parent = tool

			local weld = Instance.new("Weld")
			weld.Part0 = handle; weld.Part1 = cap
			weld.C0 = CFrame.new(0, yOff, 0)
			weld.Parent = cap
		end

		return handle
	end

	-- Build a rainbow carpet tool handle
	local function makeCarpetHandle(tool)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(5, 0.3, 7)
		handle.Color = Color3.fromRGB(255, 100, 100)
		handle.Material = Enum.Material.Fabric
		handle.Parent = tool

		-- Rainbow stripes welded to handle
		local rainbowColors = {
			Color3.fromRGB(255, 50, 50),
			Color3.fromRGB(255, 160, 0),
			Color3.fromRGB(255, 255, 50),
			Color3.fromRGB(50, 255, 50),
			Color3.fromRGB(50, 150, 255),
			Color3.fromRGB(130, 50, 255),
			Color3.fromRGB(200, 50, 255),
		}

		local stripeW = 5 / #rainbowColors
		for i, color in ipairs(rainbowColors) do
			local stripe = Instance.new("Part")
			stripe.Name = "Stripe"..i
			stripe.Size = Vector3.new(stripeW, 0.35, 7)
			stripe.Color = color
			stripe.Material = Enum.Material.Fabric
			stripe.CanCollide = false
			stripe.Parent = tool

			local weld = Instance.new("Weld")
			weld.Part0 = handle; weld.Part1 = stripe
			weld.C0 = CFrame.new((i - (#rainbowColors+1)/2) * stripeW, 0.02, 0)
			weld.Parent = stripe
		end

		-- Gold fringe
		for _, zOff in ipairs({-3.6, 3.6}) do
			local fringe = Instance.new("Part")
			fringe.Name = "Fringe"
			fringe.Size = Vector3.new(5.5, 0.15, 0.4)
			fringe.Color = Color3.fromRGB(220, 180, 50)
			fringe.Material = Enum.Material.Fabric
			fringe.CanCollide = false; fringe.Parent = tool

			local weld = Instance.new("Weld")
			weld.Part0 = handle; weld.Part1 = fringe
			weld.C0 = CFrame.new(0, -0.1, zOff)
			weld.Parent = fringe
		end

		-- Glow underneath
		local glow = Instance.new("Part")
		glow.Name = "CarpetGlow"
		glow.Size = Vector3.new(4.5, 0.1, 6.5)
		glow.Color = Color3.fromRGB(255, 220, 100)
		glow.Material = Enum.Material.Neon
		glow.Transparency = 0.5
		glow.CanCollide = false; glow.Parent = tool

		local weld = Instance.new("Weld")
		weld.Part0 = handle; weld.Part1 = glow
		weld.C0 = CFrame.new(0, -0.3, 0)
		weld.Parent = glow

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 220, 100)
		light.Brightness = 0.8; light.Range = 10
		light.Parent = glow

		return handle
	end

	-- Remote event for magic carpet flight (client handles controls)
	local carpetFlyEvent = Instance.new("RemoteEvent")
	carpetFlyEvent.Name = "CarpetFlyToggle"
	carpetFlyEvent.Parent = ReplicatedStorage

	-- Item give logic
	local function giveItem(player, itemName)
		print("[CandyRun] Giving item:", itemName, "to", player.Name)
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		if not hum then return end

		-- Remove existing tool of same name
		for _, tool in player.Backpack:GetChildren() do
			if tool.Name == itemName then tool:Destroy() end
		end
		for _, tool in char:GetChildren() do
			if tool:IsA("Tool") and tool.Name == itemName then tool:Destroy() end
		end

		local tool = Instance.new("Tool")
		tool.Name = itemName
		tool.CanBeDropped = false
		tool.RequiresHandle = true

		-- Hotbar icon textures
		local TOOL_ICONS = {
			["Speed Coil"]   = "rbxassetid://131544131",
			["Gravity Coil"] = "rbxassetid://131544479",
			["Fusion Coil"]  = "rbxassetid://131544131",
			["Magic Carpet"] = "rbxassetid://152980561",
			["Grapple Gun"]  = "rbxassetid://95146531",
			["Boombox"]      = "rbxassetid://130113146",
		}
		if TOOL_ICONS[itemName] then
			tool.TextureId = TOOL_ICONS[itemName]
		end

		if itemName == "Speed Coil" then
			makeCoilHandle(tool, Color3.fromRGB(80, 200, 255), Color3.fromRGB(200, 240, 255))
			tool.Equipped:Connect(function()
				if hum then hum.WalkSpeed = hum.WalkSpeed + 30 end
			end)
			tool.Unequipped:Connect(function()
				if hum then hum.WalkSpeed = math.max(hum.WalkSpeed - 30, 28) end
			end)

		elseif itemName == "Gravity Coil" then
			makeCoilHandle(tool, Color3.fromRGB(180, 80, 255), Color3.fromRGB(230, 180, 255))
			-- Gravity coil: reduce gravity to float (+20 jump, lower gravity feel)
			tool.Equipped:Connect(function()
				if hum then
					hum.JumpPower = hum.JumpPower + 20
				end
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if rootPart then
					-- BodyForce to counteract some gravity (makes you float)
					local bf = Instance.new("BodyForce")
					bf.Name = "GravityReducer"
					-- Counteract ~60% of gravity: mass * gravity * 0.6
					local mass = 0
					for _, part in char:GetDescendants() do
						if part:IsA("BasePart") then mass += part:GetMass() end
					end
					bf.Force = Vector3.new(0, mass * workspace.Gravity * 0.6, 0)
					bf.Parent = rootPart
				end
			end)
			tool.Unequipped:Connect(function()
				if hum then
					hum.JumpPower = math.max(hum.JumpPower - 20, 60)
				end
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local bf = rootPart:FindFirstChild("GravityReducer")
					if bf then bf:Destroy() end
				end
			end)

		elseif itemName == "Magic Carpet" then
			makeCarpetHandle(tool)
			-- Carpet: tell client carpet is equipped (M1 to mount/dismount)
			tool.Equipped:Connect(function()
				carpetFlyEvent:FireClient(player, true)
				-- Don't force sit here — client handles mount on M1
			end)
			tool.Unequipped:Connect(function()
				carpetFlyEvent:FireClient(player, false)
				if hum then
					hum.Sit = false
				end
				-- Clean up any flight forces
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if rootPart then
					for _, name in ipairs({"CarpetGyro","CarpetVelocity","CarpetAntiGrav","MountAntiGrav","MountVelocity","MountGyro"}) do
						local obj = rootPart:FindFirstChild(name)
						if obj then obj:Destroy() end
					end
				end
			end)

		elseif itemName == "Fusion Coil" then
			makeCoilHandle(tool, Color3.fromRGB(80, 200, 255), Color3.fromRGB(180, 80, 255))
			-- Fusion: speed + gravity combined
			tool.Equipped:Connect(function()
				if hum then hum.WalkSpeed = hum.WalkSpeed + 25 end
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local bf = Instance.new("BodyForce")
					bf.Name = "FusionGravityReducer"
					local mass = 0
					for _, part in char:GetDescendants() do
						if part:IsA("BasePart") then mass += part:GetMass() end
					end
					bf.Force = Vector3.new(0, mass * workspace.Gravity * 0.5, 0)
					bf.Parent = rootPart
				end
			end)
			tool.Unequipped:Connect(function()
				if hum then hum.WalkSpeed = math.max(hum.WalkSpeed - 25, 28) end
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local bf = rootPart:FindFirstChild("FusionGravityReducer")
					if bf then bf:Destroy() end
				end
			end)

		elseif itemName == "Grapple Gun" then
			-- Gun-shaped handle
			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(0.6, 1.2, 2.5)
			handle.Color = Color3.fromRGB(80, 80, 90)
			handle.Material = Enum.Material.Metal
			handle.Parent = tool

			-- Barrel tip
			local tipPart = Instance.new("Part")
			tipPart.Name = "BarrelTip"
			tipPart.Size = Vector3.new(0.7, 0.7, 0.3)
			tipPart.Color = Color3.fromRGB(255, 80, 80)
			tipPart.Material = Enum.Material.Neon
			tipPart.CanCollide = false; tipPart.Parent = tool
			local tw = Instance.new("Weld")
			tw.Part0 = handle; tw.Part1 = tipPart
			tw.C0 = CFrame.new(0, 0, -1.4); tw.Parent = tipPart

			-- Grip
			local gripPart = Instance.new("Part")
			gripPart.Name = "Grip"
			gripPart.Size = Vector3.new(0.5, 1.2, 0.5)
			gripPart.Color = Color3.fromRGB(60, 60, 65)
			gripPart.Material = Enum.Material.SmoothPlastic
			gripPart.CanCollide = false; gripPart.Parent = tool
			local gw = Instance.new("Weld")
			gw.Part0 = handle; gw.Part1 = gripPart
			gw.C0 = CFrame.new(0, -1, 0.3); gw.Parent = gripPart

			tool.CanBeDropped = false
			tool.RequiresHandle = true

			-- Grapple activation: client fires GrappleShoot, server creates projectile
			-- (client-side script handles the actual input)

		elseif itemName == "Boombox" then
			-- Boombox handle: a chunky radio shape
			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(2.4, 1.6, 1)
			handle.Color = Color3.fromRGB(40, 40, 45)
			handle.Material = Enum.Material.SmoothPlastic
			handle.Parent = tool

			-- Speaker cones (left + right)
			for _, side in ipairs({-1, 1}) do
				local speaker = Instance.new("Part")
				speaker.Name = "Speaker"
				speaker.Size = Vector3.new(0.8, 0.8, 0.2)
				speaker.Color = Color3.fromRGB(60, 60, 65)
				speaker.Material = Enum.Material.Metal
				speaker.Shape = Enum.PartType.Cylinder
				speaker.CanCollide = false; speaker.Parent = tool
				local sw = Instance.new("Weld")
				sw.Part0 = handle; sw.Part1 = speaker
				sw.C0 = CFrame.new(side * 0.7, 0, -0.55) * CFrame.Angles(0, 0, math.rad(90))
				sw.Parent = speaker
			end

			-- Carry handle bar
			local bar = Instance.new("Part")
			bar.Name = "CarryBar"
			bar.Size = Vector3.new(1.2, 0.2, 0.2)
			bar.Color = Color3.fromRGB(180, 180, 185)
			bar.Material = Enum.Material.Metal
			bar.CanCollide = false; bar.Parent = tool
			local bw = Instance.new("Weld")
			bw.Part0 = handle; bw.Part1 = bar
			bw.C0 = CFrame.new(0, 1, 0); bw.Parent = bar

			-- Neon accent strip
			local strip = Instance.new("Part")
			strip.Name = "NeonStrip"
			strip.Size = Vector3.new(1.8, 0.15, 0.15)
			strip.Color = Color3.fromRGB(255, 80, 200)
			strip.Material = Enum.Material.Neon
			strip.CanCollide = false; strip.Parent = tool
			local nw = Instance.new("Weld")
			nw.Part0 = handle; nw.Part1 = strip
			nw.C0 = CFrame.new(0, -0.5, -0.55); nw.Parent = strip

			-- Sound object that plays the music (attached to handle)
			local boomSound = Instance.new("Sound")
			boomSound.Name = "BoomboxSound"
			boomSound.Volume = 1.5
			boomSound.Looped = true
			boomSound.RollOffMaxDistance = 80
			boomSound.RollOffMinDistance = 10
			boomSound.Parent = handle

			tool.CanBeDropped = false
			tool.RequiresHandle = true
		end

		tool.Parent = player.Backpack
	end

	-- Gamepass purchase system
	local debounces = {}

	speedPrompt.Triggered:Connect(function(plr) 
		MarketplaceService:PromptGamePassPurchase(plr, speedGamepassId) 
	end)
	gravityPrompt.Triggered:Connect(function(plr) 
		MarketplaceService:PromptGamePassPurchase(plr, gravityGamepassId) 
	end)
	fusionPrompt.Triggered:Connect(function(plr) 
		MarketplaceService:PromptGamePassPurchase(plr, fusionGamepassId) 
	end)
	carpetPrompt.Triggered:Connect(function(plr) 
		MarketplaceService:PromptGamePassPurchase(plr, carpetGamepassId) 
	end)
	grapplePrompt.Triggered:Connect(function(plr) 
		MarketplaceService:PromptGamePassPurchase(plr, grappleGamepassId) 
	end)

	-- Handle gamepass purchase completion
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, gamepassId, wasPurchased)
		if not wasPurchased then return end
		
		local itemName = ""
		if gamepassId == speedGamepassId then
			itemName = "Speed Coil"
		elseif gamepassId == gravityGamepassId then
			itemName = "Gravity Coil"
		elseif gamepassId == fusionGamepassId then
			itemName = "Fusion Coil"
		elseif gamepassId == carpetGamepassId then
			itemName = "Magic Carpet"
		elseif gamepassId == grappleGamepassId then
			itemName = "Grapple Gun"
		end
		
		if itemName ~= "" then
			giveItem(plr, itemName)
			purchaseEvent:FireClient(plr, "success", itemName, 0, 0)
		end
	end)

	-- Boombox: server handles song ID changes (validates & sets the Sound)
	boomboxEvent.OnServerEvent:Connect(function(plr, songId)
		if type(songId) ~= "number" or songId < 0 or songId > 99999999999 then return end
		-- Find the player's boombox tool
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
			sound:Stop()
			sound:Play()
		end
	end)

	-- ============================================================
	-- LEADERBOARD (Top Donations) — clone from ServerStorage if available
	-- ============================================================
	local leaderboardTemplate = ServerStorage:FindFirstChild("LeaderboardModel")
		or ServerStorage:FindFirstChild("Leaderboard")
		or ServerStorage:FindFirstChild("TopDonations")
		or ServerStorage:FindFirstChild("DonationBoard")
	if leaderboardTemplate then
		local lb = leaderboardTemplate:Clone()
		-- Position in spawn room — left side, near the back wall
		lb:PivotTo(CFrame.new(Vector3.new(-40, floorY + 5, 45)))
		for _, part in lb:GetDescendants() do
			if part:IsA("BasePart") then part.Anchored = true end
		end
		lb.Parent = mapFolder
		print("[CandyRun] Leaderboard model placed in spawn room")
	else
		-- Create a placeholder leaderboard sign
		local lbSign = Instance.new("Part")
		lbSign.Size = Vector3.new(20, 15, 2)
		lbSign.Position = Vector3.new(-40, floorY + 12, 55)
		lbSign.Anchored = true; lbSign.Color = Color3.fromRGB(40, 25, 50)
		lbSign.Material = Enum.Material.SmoothPlastic; lbSign.Parent = mapFolder

		local lbGui = Instance.new("SurfaceGui"); lbGui.Face = Enum.NormalId.Front; lbGui.Parent = lbSign
		local lbTitle = Instance.new("TextLabel")
		lbTitle.Size = UDim2.fromScale(1, 0.25); lbTitle.BackgroundTransparency = 1
		lbTitle.Text = "🏆 TOP DONATIONS 🏆"
		lbTitle.TextColor3 = Color3.fromRGB(255, 220, 80)
		lbTitle.TextScaled = true; lbTitle.Font = Enum.Font.FredokaOne; lbTitle.Parent = lbGui

		local lbBody = Instance.new("TextLabel")
		lbBody.Size = UDim2.fromScale(1, 0.75); lbBody.Position = UDim2.fromScale(0, 0.25)
		lbBody.BackgroundTransparency = 1
		lbBody.Text = "Place your LeaderboardModel\nin ServerStorage to\nenable this board!"
		lbBody.TextColor3 = Color3.fromRGB(200, 180, 220)
		lbBody.TextScaled = true; lbBody.Font = Enum.Font.GothamBold; lbBody.Parent = lbGui

		-- Glow
		local lbGlow = Instance.new("PointLight")
		lbGlow.Color = Color3.fromRGB(255, 200, 80); lbGlow.Brightness = 1; lbGlow.Range = 20
		lbGlow.Parent = lbSign
	end

	-- ============================================================
	-- HEALTH BAR MODEL — clone from ServerStorage for reference
	-- (The actual HUD health bar is handled client-side, but if they
	-- added a 3D health bar model, we note it's being used as reference)
	-- ============================================================
	local healthBarModel = ServerStorage:FindFirstChild("HealthBar")
		or ServerStorage:FindFirstChild("HealthBarModel")
		or ServerStorage:FindFirstChild("Health Bar")
	if healthBarModel then
		print("[CandyRun] Found HealthBar model in ServerStorage — client HUD will use matching style")
	end

	print("[CandyRun] Spawn room created! Item Shop + Daily Spin + Trail Chests + Leaderboard (E to interact), floorY=" .. tostring(START_HEIGHT))
end

-- ============================================================
-- HALLWAY (opaque walls, candy ceiling)
-- ============================================================

local function createHallway()
	hallwayFolder:ClearAllChildren()
	-- Calculate Z range from parkour piece positions
	local minPieceZ = PARKOUR_START_Z
	for _, piece in ipairs(PARKOUR_PIECES) do
		if piece.z < minPieceZ then minPieceZ = piece.z end
	end
	local minZ = minPieceZ - 400  -- extend past the final hallway
	local maxZ = math.min(PARKOUR_START_Z + 30, -65)

	local totalLen = maxZ - minZ
	local numSeg = math.ceil(totalLen / WALL_SEGMENT_LENGTH)
	local halfW = HALLWAY_WIDTH / 2

	local wallColors = {
		Color3.fromRGB(255,180,210), Color3.fromRGB(220,170,255),
		Color3.fromRGB(180,220,255), Color3.fromRGB(255,220,180),
		Color3.fromRGB(200,255,210),
	}

	for seg = 0, numSeg do
		local segZ = maxZ - seg * WALL_SEGMENT_LENGTH
		local color = wallColors[(seg % #wallColors) + 1]

		-- OPAQUE walls (NO transparency)
		for _, side in ipairs({-1, 1}) do
			local wall = Instance.new("Part")
			wall.Size = Vector3.new(4, HALLWAY_HEIGHT*3, WALL_SEGMENT_LENGTH+2)
			wall.Position = Vector3.new(side*halfW, START_HEIGHT-20, segZ-WALL_SEGMENT_LENGTH/2)
			wall.Anchored = true; wall.Color = color
			wall.Material = Enum.Material.SmoothPlastic
			wall.Transparency = 0  -- FULLY OPAQUE
			wall.Parent = hallwayFolder

			-- Candy stripe decoration
			local stripe = Instance.new("Part")
			stripe.Size = Vector3.new(1.5, 5, WALL_SEGMENT_LENGTH+2)
			stripe.Position = Vector3.new(side*(halfW-2), START_HEIGHT + (seg*4)%25, segZ-WALL_SEGMENT_LENGTH/2)
			stripe.Anchored = true; stripe.Color = Color3.fromRGB(255,255,255)
			stripe.Material = Enum.Material.SmoothPlastic
			stripe.Transparency = 0.3; stripe.CanCollide = false
			stripe.Parent = hallwayFolder

			-- Second stripe
			local stripe2 = Instance.new("Part")
			stripe2.Size = Vector3.new(1, 3, WALL_SEGMENT_LENGTH+2)
			stripe2.Position = Vector3.new(side*(halfW-2), START_HEIGHT + (seg*4+12)%25, segZ-WALL_SEGMENT_LENGTH/2)
			stripe2.Anchored = true; stripe2.Color = Color3.fromRGB(255,200,220)
			stripe2.Material = Enum.Material.SmoothPlastic
			stripe2.Transparency = 0.4; stripe2.CanCollide = false
			stripe2.Parent = hallwayFolder
		end

		-- Ceiling: candy checkerboard
		local ceilY = START_HEIGHT + HALLWAY_HEIGHT
		local tilesPerRow = math.ceil(HALLWAY_WIDTH / 10)
		for tx = 0, tilesPerRow - 1 do
			local tileX = -halfW + tx*10 + 5
			local tileColor = if (seg+tx)%2==0 then Color3.fromRGB(255,180,210) else Color3.fromRGB(255,255,255)
			local tile = Instance.new("Part")
			tile.Size = Vector3.new(10.1, 2, WALL_SEGMENT_LENGTH+0.1)
			tile.Position = Vector3.new(tileX, ceilY, segZ-WALL_SEGMENT_LENGTH/2)
			tile.Anchored = true; tile.Color = tileColor
			tile.Material = Enum.Material.SmoothPlastic
			tile.TopSurface = Enum.SurfaceType.Smooth
			tile.BottomSurface = Enum.SurfaceType.Smooth
			tile.Parent = hallwayFolder
		end

		-- Centered ceiling lights (straight line down the middle)
		local ls = Instance.new("Part")
		ls.Size = Vector3.new(0.8,12,0.8)
		ls.Position = Vector3.new(0, ceilY-6, segZ-WALL_SEGMENT_LENGTH/2)
		ls.Anchored = true; ls.Color = Color3.fromRGB(240,230,200)
		ls.Material = Enum.Material.SmoothPlastic; ls.CanCollide = false
		ls.Parent = hallwayFolder

		local lt = Instance.new("Part")
		lt.Size = Vector3.new(3, 8, 8)
		lt.Position = Vector3.new(0, ceilY-14, segZ-WALL_SEGMENT_LENGTH/2)
		lt.Anchored = true; lt.Color = wallColors[(seg % #wallColors) + 1]
		lt.Material = Enum.Material.Neon; lt.Shape = Enum.PartType.Cylinder
		lt.Orientation = Vector3.new(0,0,90)
		lt.CanCollide = false; lt.Transparency = 0.1
		lt.Parent = hallwayFolder

		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255,220,240); pl.Brightness = 2; pl.Range = 50
		pl.Parent = lt

		-- Wall candy canes
		if seg % 3 == 0 then
			for _, side in ipairs({-halfW+4, halfW-4}) do
				local cane = Instance.new("Part")
				cane.Size = Vector3.new(18,2,2)
				cane.Position = Vector3.new(side, START_HEIGHT+35, segZ-WALL_SEGMENT_LENGTH/2)
				cane.Anchored = true; cane.Color = Color3.fromRGB(255,40,40)
				cane.Material = Enum.Material.SmoothPlastic
				cane.Shape = Enum.PartType.Cylinder; cane.CanCollide = false
				cane.Parent = hallwayFolder
			end
		end
	end
end

-- ============================================================
-- DEATH FLOOR
-- ============================================================

local function createDeathFloor()
	local df = Instance.new("Part")
	df.Name = "DeathFloor"
	df.Size = Vector3.new(HALLWAY_WIDTH+20, 8, 3000)
	df.Position = Vector3.new(0, DEATH_Y, -700)
	df.Anchored = true; df.Color = Color3.fromRGB(200,20,20)
	df.Material = Enum.Material.Neon; df.Transparency = 0.1
	df.CanCollide = false; df.Parent = workspace

	for i = 1, 35 do
		local p = Instance.new("Part")
		p.Size = Vector3.new(math.random(12,35), 1.5, math.random(12,35))
		p.Position = Vector3.new(math.random(-40,40), DEATH_Y+4.5, math.random(-1600,100))
		p.Anchored = true; p.Color = Color3.fromRGB(255, math.random(30,80), math.random(20,50))
		p.Material = Enum.Material.Neon; p.Transparency = 0.25; p.CanCollide = false
		p.Parent = workspace
	end

	task.spawn(function()
		while df and df.Parent do
			TweenService:Create(df, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.25, Color = Color3.fromRGB(255,50,50),
			}):Play(); task.wait(1.5)
			TweenService:Create(df, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.1, Color = Color3.fromRGB(200,20,20),
			}):Play(); task.wait(1.5)
		end
	end)

	local em = Instance.new("ParticleEmitter")
	em.Color = ColorSequence.new(Color3.fromRGB(255,50,50))
	em.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,4),NumberSequenceKeypoint.new(1,0)})
	em.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(1,1)})
	em.Lifetime = NumberRange.new(1.5,3); em.Rate = 45
	em.Speed = NumberRange.new(3,8); em.SpreadAngle = Vector2.new(50,50)
	em.Acceleration = Vector3.new(0,5,0); em.Parent = df

	df.Touched:Connect(function(hit)
		local ch = hit.Parent; local hum = ch and ch:FindFirstChild("Humanoid")
		if hum and hum.Health > 0 then hum.Health = 0 end
	end)

	local bk = Instance.new("Part")
	bk.Size = Vector3.new(2000,1,3000); bk.Position = Vector3.new(0,DEATH_Y-20,-700)
	bk.Anchored = true; bk.Transparency = 1; bk.CanCollide = false; bk.Parent = workspace
	bk.Touched:Connect(function(hit)
		local ch = hit.Parent; local hum = ch and ch:FindFirstChild("Humanoid")
		if hum and hum.Health > 0 then hum.Health = 0 end
	end)
end

-- ============================================================
-- MAP GENERATION
-- ============================================================

local function generateMap()
	mapFolder:ClearAllChildren(); collectiblesFolder:ClearAllChildren()
	checkpointPositions = {}; createSpawnRoom()

	local checkpointCount = 0
	local lastPiecePos = Vector3.new(0, BASE_Y, PARKOUR_START_Z)

	-- Build every parkour piece
	for i, piece in ipairs(PARKOUR_PIECES) do
		local piecePos = Vector3.new(piece.x, BASE_Y + (piece.y or 0), piece.z)

		-- Each piece gets a random candy model
		local candyName = piece.candy or randomCandy()
		local walkable, mdl = buildCandyPlatform(candyName, i, piecePos, piece.size)

		-- Moving platforms
		if piece.moving then makeMoving(mdl) end

		-- Piece number label (floating above)
		local np = Instance.new("Part")
		np.Size = Vector3.new(1,1,1); np.Position = piecePos + Vector3.new(0,14,0)
		np.Anchored = true; np.Transparency = 1; np.CanCollide = false; np.Parent = mapFolder
		local ng = Instance.new("BillboardGui"); ng.Size = UDim2.fromOffset(50,35); ng.AlwaysOnTop = false; ng.Parent = np
		local nl = Instance.new("TextLabel"); nl.Size = UDim2.fromScale(1,1); nl.BackgroundTransparency = 1
		nl.Text = tostring(i); nl.TextColor3 = Color3.fromRGB(255,255,255)
		nl.TextTransparency = 0.4; nl.TextScaled = true; nl.Font = Enum.Font.FredokaOne; nl.Parent = ng
		local ns = Instance.new("UIStroke"); ns.Color = Color3.fromRGB(200,100,150); ns.Thickness = 2; ns.Parent = nl

		-- Checkpoint handling
		if piece.checkpoint then
			checkpointCount = checkpointCount + 1
			checkpointPositions[checkpointCount] = piecePos + Vector3.new(0,5,0)

			-- Checkpoint glow on the piece itself
			local cpFirstPart = mdl:FindFirstChildWhichIsA("BasePart", true)
			if cpFirstPart then
				local cpLight = Instance.new("PointLight")
				cpLight.Color = Color3.fromRGB(80, 255, 130)
				cpLight.Brightness = 2.5; cpLight.Range = 45
				cpLight.Parent = cpFirstPart
			end

			-- Checkpoint sign floating above
			local cpSign = Instance.new("Part")
			cpSign.Size = Vector3.new(14, 5, 1.5)
			cpSign.Position = piecePos + Vector3.new(0, 22, 0)
			cpSign.Anchored = true; cpSign.Color = Color3.fromRGB(60,150,90)
			cpSign.Material = Enum.Material.Neon; cpSign.Parent = mapFolder
			local sGui = Instance.new("SurfaceGui"); sGui.Face = Enum.NormalId.Front; sGui.Parent = cpSign
			local sLbl = Instance.new("TextLabel"); sLbl.Size = UDim2.fromScale(1,1); sLbl.BackgroundTransparency = 1
			sLbl.Text = "✓ CHECKPOINT " .. checkpointCount; sLbl.TextColor3 = Color3.fromRGB(255,255,255)
			sLbl.TextScaled = true; sLbl.Font = Enum.Font.FredokaOne; sLbl.Parent = sGui
			local sGui2 = Instance.new("SurfaceGui"); sGui2.Face = Enum.NormalId.Back; sGui2.Parent = cpSign
			local sLbl2 = sLbl:Clone(); sLbl2.Parent = sGui2

			-- Trigger zone (invisible, sets spawn point)
			local cpt = Instance.new("Part"); cpt.Size = Vector3.new(30,20,30)
			cpt.Position = piecePos + Vector3.new(0,10,0); cpt.Anchored = true
			cpt.Transparency = 1; cpt.CanCollide = false; cpt.Parent = mapFolder
			local cpIdx = checkpointCount
			cpt.Touched:Connect(function(hit)
				local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
				if plr then
					local data = playerData[plr]
					if data and (not data.checkpoint or data.checkpoint < cpIdx) then data.checkpoint = cpIdx end
				end
			end)
		end

		-- Collectible every 5 pieces
		if i % 5 == 0 and not piece.checkpoint then
			createCollectible(piecePos, i)
		end

		lastPiecePos = piecePos
	end

	-- ============================================================
	-- FINAL HALLWAY RUN (disappearing tiles before finish)
	-- ============================================================
	local hallwayStart = lastPiecePos + Vector3.new(0, 0, -20)
	local FINAL_W = 20     -- narrow corridor width
	local FINAL_H = 40     -- corridor height
	local FINAL_LEN = 300  -- corridor length
	local TILE_SIZE = 6    -- tile dimensions
	local TILES_X = math.floor(FINAL_W / TILE_SIZE)
	local TILES_Z = math.floor(FINAL_LEN / TILE_SIZE)

	-- Corridor walls
	local fhWallColors = {Color3.fromRGB(255,120,160), Color3.fromRGB(200,100,255)}
	for _, side in ipairs({-1, 1}) do
		local wall = Instance.new("Part")
		wall.Size = Vector3.new(4, FINAL_H, FINAL_LEN)
		wall.Position = hallwayStart + Vector3.new(side*(FINAL_W/2+2), FINAL_H/2, -FINAL_LEN/2)
		wall.Anchored = true; wall.Color = fhWallColors[if side==-1 then 1 else 2]
		wall.Material = Enum.Material.SmoothPlastic; wall.Parent = mapFolder

		-- Candy stripes on walls
		for s = 1, 8 do
			local stripe = Instance.new("Part")
			stripe.Size = Vector3.new(1.5, 4, FINAL_LEN)
			stripe.Position = hallwayStart + Vector3.new(side*(FINAL_W/2), s*5, -FINAL_LEN/2)
			stripe.Anchored = true; stripe.Color = Color3.fromRGB(255,255,255)
			stripe.Material = Enum.Material.SmoothPlastic
			stripe.Transparency = 0.3; stripe.CanCollide = false
			stripe.Parent = mapFolder
		end
	end

	-- Corridor ceiling
	local fhCeil = Instance.new("Part")
	fhCeil.Size = Vector3.new(FINAL_W+8, 3, FINAL_LEN)
	fhCeil.Position = hallwayStart + Vector3.new(0, FINAL_H, -FINAL_LEN/2)
	fhCeil.Anchored = true; fhCeil.Color = Color3.fromRGB(220,170,255)
	fhCeil.Material = Enum.Material.SmoothPlastic; fhCeil.Parent = mapFolder

	-- Ceiling lights down center of final hallway
	for lIdx = 1, math.floor(FINAL_LEN / 20) do
		local lz = hallwayStart.Z - lIdx * 20
		local rod = Instance.new("Part")
		rod.Size = Vector3.new(0.6, 8, 0.6)
		rod.Position = Vector3.new(hallwayStart.X, hallwayStart.Y + FINAL_H - 4, lz)
		rod.Anchored = true; rod.Color = Color3.fromRGB(240,230,200)
		rod.Material = Enum.Material.SmoothPlastic; rod.CanCollide = false
		rod.Parent = mapFolder

		local lamp = Instance.new("Part")
		lamp.Size = Vector3.new(2.5, 6, 6)
		lamp.Position = Vector3.new(hallwayStart.X, hallwayStart.Y + FINAL_H - 10, lz)
		lamp.Anchored = true; lamp.Color = Color3.fromRGB(255,80,80)
		lamp.Material = Enum.Material.Neon; lamp.Shape = Enum.PartType.Cylinder
		lamp.Orientation = Vector3.new(0,0,90)
		lamp.CanCollide = false; lamp.Transparency = 0.1
		lamp.Parent = mapFolder

		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255,150,150); pl.Brightness = 2; pl.Range = 35
		pl.Parent = lamp
	end

	-- "FINAL RUN" sign at entrance
	local frSign = Instance.new("Part")
	frSign.Size = Vector3.new(FINAL_W, 5, 1.5)
	frSign.Position = hallwayStart + Vector3.new(0, FINAL_H-5, 2)
	frSign.Anchored = true; frSign.Color = Color3.fromRGB(255,50,50)
	frSign.Material = Enum.Material.Neon; frSign.Parent = mapFolder
	local frGui = Instance.new("SurfaceGui"); frGui.Face = Enum.NormalId.Back; frGui.Parent = frSign
	local frLbl = Instance.new("TextLabel"); frLbl.Size = UDim2.fromScale(1,1); frLbl.BackgroundTransparency = 1
	frLbl.Text = "⚡ FINAL RUN ⚡"; frLbl.TextColor3 = Color3.fromRGB(255,255,255)
	frLbl.TextScaled = true; frLbl.Font = Enum.Font.FredokaOne; frLbl.Parent = frGui

	-- DISAPPEARING TILES
	local tileColors = {
		Color3.fromRGB(255,180,210), Color3.fromRGB(200,160,255),
		Color3.fromRGB(160,210,255), Color3.fromRGB(255,210,160),
	}

	for tz = 0, TILES_Z - 1 do
		for tx = 0, TILES_X - 1 do
			local tile = Instance.new("Part")
			tile.Name = "DisappearTile"
			tile.Size = Vector3.new(TILE_SIZE - 0.3, 1.5, TILE_SIZE - 0.3)
			tile.Position = hallwayStart + Vector3.new(
				-FINAL_W/2 + tx*TILE_SIZE + TILE_SIZE/2,
				-0.5,
				-(tz*TILE_SIZE + TILE_SIZE/2)
			)
			tile.Anchored = true
			tile.Color = tileColors[((tx+tz) % #tileColors) + 1]
			tile.Material = Enum.Material.SmoothPlastic
			tile.TopSurface = Enum.SurfaceType.Smooth
			tile.BottomSurface = Enum.SurfaceType.Smooth
			tile.Parent = mapFolder

			-- Disappear logic: 0.5s after touch, tile vanishes instantly
			local tileActive = true
			local tileFading = false
			tile.Touched:Connect(function(hit)
				if tileFading or not tileActive then return end
				local ch = hit.Parent; local hum = ch and ch:FindFirstChild("Humanoid")
				if not hum then return end
				tileFading = true

				-- Instant red flash + crack particles
				tile.Color = Color3.fromRGB(255, 50, 50)
				local crack = Instance.new("ParticleEmitter")
				crack.Color = ColorSequence.new(Color3.fromRGB(255,100,100))
				crack.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.8),NumberSequenceKeypoint.new(1,0)})
				crack.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(1,1)})
				crack.Lifetime = NumberRange.new(0.3,0.6); crack.Rate = 60
				crack.Speed = NumberRange.new(3,8); crack.SpreadAngle = Vector2.new(60,60)
				crack.Parent = tile

				-- Disappear after 0.5 seconds
				task.wait(0.5)
				crack:Destroy()
				tileActive = false
				tile.CanCollide = false
				TweenService:Create(tile, TweenInfo.new(0.15), {Transparency = 1}):Play()

				-- Respawn after 4 seconds
				task.wait(4)
				tile.Color = tileColors[((tx+tz) % #tileColors) + 1]
				tile.Transparency = 0
				tile.CanCollide = true
				tileActive = true
				tileFading = false
			end)
		end
	end

	-- Collectibles floating in final hallway
	for ci = 1, 10 do
		createCollectible(
			hallwayStart + Vector3.new(math.random(-8,8), 5, -(ci*28)),
			100 + ci
		)
	end

	-- ============================================================
	-- FINISH (at end of final hallway)
	-- ============================================================
	local fp = hallwayStart + Vector3.new(0, 0, -FINAL_LEN - 20)
	local fb = Instance.new("Part"); fb.Name = "FinishPlatform"
	fb.Size = Vector3.new(6,40,40); fb.Position = fp; fb.Anchored = true
	fb.Color = Color3.fromRGB(255,215,0); fb.Material = Enum.Material.Neon
	fb.Shape = Enum.PartType.Cylinder; fb.Orientation = Vector3.new(0,0,90); fb.Parent = mapFolder

	local ts = Instance.new("Part"); ts.Size = Vector3.new(2.5,22,2.5)
	ts.Position = fp+Vector3.new(0,14,0); ts.Anchored = true
	ts.Color = Color3.fromRGB(245,235,210); ts.Material = Enum.Material.SmoothPlastic; ts.Parent = mapFolder

	local tt = Instance.new("Part"); tt.Size = Vector3.new(6,16,16)
	tt.Position = fp+Vector3.new(0,29,0); tt.Anchored = true
	tt.Color = Color3.fromRGB(255,215,0); tt.Material = Enum.Material.Neon
	tt.Shape = Enum.PartType.Cylinder; tt.Orientation = Vector3.new(0,0,90)
	tt.CanCollide = false; tt.Parent = mapFolder

	task.spawn(function()
		local r = 0
		while tt and tt.Parent do r += 2; tt.Orientation = Vector3.new(0,r%360,90); task.wait(0.03) end
	end)

	local vz = Instance.new("Part"); vz.Name = "VictoryZone"
	vz.Size = Vector3.new(40,30,40); vz.Position = fp+Vector3.new(0,18,0)
	vz.Anchored = true; vz.Transparency = 1; vz.CanCollide = false; vz.Parent = mapFolder

	local wp = {}
	vz.Touched:Connect(function(hit)
		local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
		if plr and not wp[plr] then
			wp[plr] = true; timerEvent:FireClient(plr, "WIN")
			task.delay(5, function() wp[plr] = nil end)
		end
	end)
end

-- ============================================================
-- PLAYER / RESPAWN
-- ============================================================

local function getSpawnPosition(player)
	local data = playerData[player]
	if data and data.checkpoint then return checkpointPositions[data.checkpoint] or checkpointPositions[0] end
	return checkpointPositions[0] or Vector3.new(0, START_HEIGHT+7, 0)
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
			if rootPart then task.wait(0.1); rootPart.CFrame = CFrame.new(getSpawnPosition(player)) end
			timerStartEvent:FireClient(player)
		end)
	end
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function() onPlayerDied(player) end)
end

Players.PlayerAdded:Connect(function(player)
	playerData[player] = {startTime=nil, candies=0, checkpoint=nil, respawning=false}
	player.CharacterAdded:Connect(function(character) onCharacterAdded(player, character) end)
	if player.Character then onCharacterAdded(player, player.Character) end
end)

startGameEvent.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if data then data.startTime = tick(); data.candies = 0; data.checkpoint = nil end
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then rootPart.CFrame = CFrame.new(0, START_HEIGHT+5, 20) end
	end
	timerStartEvent:FireClient(player)
end)

-- ============================================================
-- GRAPPLE GUN SERVER HANDLER
-- ============================================================

local grappleCooldowns = {}

grappleShootEvent.OnServerEvent:Connect(function(player, origin, direction)
	-- Validate
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return end
	if grappleCooldowns[player] then return end
	grappleCooldowns[player] = true
	task.delay(2, function() grappleCooldowns[player] = nil end)

	local char = player.Character
	if not char then return end
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Ensure they have the grapple gun equipped
	local hasGrapple = false
	for _, tool in char:GetChildren() do
		if tool:IsA("Tool") and tool.Name == "Grapple Gun" then hasGrapple = true; break end
	end
	if not hasGrapple then grappleCooldowns[player] = nil; return end

	-- Normalize direction
	direction = direction.Unit

	-- Create projectile
	local projectile = Instance.new("Part")
	projectile.Name = "GrappleProjectile"
	projectile.Size = Vector3.new(1.5, 1.5, 1.5)
	projectile.Shape = Enum.PartType.Ball
	projectile.Color = Color3.fromRGB(255, 200, 50)
	projectile.Material = Enum.Material.Neon
	projectile.CFrame = CFrame.new(origin)
	projectile.Anchored = false
	projectile.CanCollide = false
	projectile.Parent = workspace

	-- Glow
	local pLight = Instance.new("PointLight")
	pLight.Color = Color3.fromRGB(255, 200, 50)
	pLight.Brightness = 2; pLight.Range = 15
	pLight.Parent = projectile

	-- Launch it
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = direction * 150
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Parent = projectile

	-- Beam (rope visual) from player to projectile
	local att0 = Instance.new("Attachment"); att0.Parent = rootPart
	local att1 = Instance.new("Attachment"); att1.Parent = projectile
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0; beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100))
	beam.Width0 = 0.3; beam.Width1 = 0.3
	beam.FaceCamera = true; beam.Parent = rootPart

	-- Tell client about the projectile for visual tracking
	grappleHitEvent:FireClient(player, "fired", projectile)

	local hitSomething = false

	projectile.Touched:Connect(function(hit)
		if hitSomething then return end
		if hit:IsDescendantOf(char) then return end
		if hit.Name == "GrappleProjectile" then return end
		hitSomething = true

		-- Stick projectile
		bv:Destroy()
		projectile.Anchored = true
		local hitPos = projectile.Position

		-- Boost player toward hit point + UP 5 blocks (25 studs)
		local pullDir = (hitPos - rootPart.Position).Unit
		local boostForce = pullDir * 60 + Vector3.new(0, 70, 0) -- upward + toward

		rootPart.AssemblyLinearVelocity = boostForce

		-- Tell client
		grappleHitEvent:FireClient(player, "hit", hitPos)

		-- Clean up after brief delay
		task.delay(0.8, function()
			if beam then beam:Destroy() end
			if att0 then att0:Destroy() end
			if att1 then att1:Destroy() end
			if projectile and projectile.Parent then projectile:Destroy() end
		end)
	end)

	-- Auto-destroy if it doesn't hit anything after 2 seconds
	task.delay(2, function()
		if not hitSomething then
			if beam then beam:Destroy() end
			if att0 then att0:Destroy() end
			if att1 then att1:Destroy() end
			if projectile and projectile.Parent then projectile:Destroy() end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player) playerData[player] = nil end)

-- ============================================================
-- INIT
-- ============================================================

local ok, err = pcall(generateMap)
if not ok then warn("[CandyRun] ERROR in generateMap: " .. tostring(err)) end

local ok2, err2 = pcall(createHallway)
if not ok2 then warn("[CandyRun] ERROR in createHallway: " .. tostring(err2)) end

local ok3, err3 = pcall(createDeathFloor)
if not ok3 then warn("[CandyRun] ERROR in createDeathFloor: " .. tostring(err3)) end

print("[CandyRun] Server v6 initialized! Huge spawn room, fusion coil, grapple gun, final hallway run.")
