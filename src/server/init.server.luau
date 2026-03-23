--[[
	Candy Run - Server Script v4
	Oversized fantasy candy, opaque hallway walls, big spawn with item capsules
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

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

-- ============================================================
-- LIGHTING
-- ============================================================

Lighting.ClockTime = 21.5  -- evening/dusk
Lighting.Brightness = 1.2
Lighting.Ambient = Color3.fromRGB(60, 40, 70)
Lighting.OutdoorAmbient = Color3.fromRGB(80, 55, 90)
Lighting.FogColor = Color3.fromRGB(120, 80, 130)
Lighting.FogEnd = 1800; Lighting.FogStart = 300

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
local HALLWAY_WIDTH = 90
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

-- Glass sheen overlay helper
local function addSheen(parent, size, position, color)
	local s = Instance.new("Part")
	s.Size = size; s.Position = position; s.Anchored = true
	s.Color = color or Color3.fromRGB(255,255,255)
	s.Material = Enum.Material.Glass
	s.Transparency = 0.82; s.CanCollide = false
	s.Parent = parent
	return s
end

-- ============================================================
-- CANDY CANE: Tall, glossy, smoothly curved with bright spiral stripes
-- ============================================================

local function buildCandyCane(index, pos, m)
	m = m or 1
	local model = Instance.new("Model"); model.Name = "CandyCane_"..index

	-- Thick main body
	local main = Instance.new("Part")
	main.Name = "Walkable"
	main.Size = Vector3.new(22*m, 5.5*m, 5.5*m)
	main.Position = pos; main.Anchored = true
	main.Color = Color3.fromRGB(230, 25, 25)
	main.Material = Enum.Material.SmoothPlastic
	main.Shape = Enum.PartType.Cylinder
	main.TopSurface = Enum.SurfaceType.Smooth
	main.BottomSurface = Enum.SurfaceType.Smooth
	main.Parent = model
	glow(main, Color3.fromRGB(255, 100, 100), 20, 0.6)

	-- Spiral white stripes (6 bands for tight spiral look)
	for i2 = -2.5, 2.5, 1 do
		local stripe = Instance.new("Part")
		stripe.Size = Vector3.new(2.5*m, 5.8*m, 5.8*m)
		stripe.Position = pos + Vector3.new(i2*3.2*m, 0, 0)
		stripe.Anchored = true; stripe.Color = Color3.fromRGB(255,255,255)
		stripe.Material = Enum.Material.SmoothPlastic
		stripe.Shape = Enum.PartType.Cylinder
		stripe.Transparency = 0.4; stripe.CanCollide = false
		stripe.Parent = model
	end

	-- Full glossy sheen overlay (polished candy look)
	local sheen = Instance.new("Part")
	sheen.Size = Vector3.new(22.5*m, 4*m, 4*m)
	sheen.Position = pos + Vector3.new(0, 1.2*m, 0)
	sheen.Anchored = true; sheen.Color = Color3.fromRGB(255, 220, 220)
	sheen.Material = Enum.Material.Glass
	sheen.Shape = Enum.PartType.Cylinder
	sheen.Transparency = 0.75; sheen.CanCollide = false
	sheen.Parent = model

	-- Curved hook (tall, with smooth curve using 5 spheres for smoother arc)
	local hookPositions = {
		{x = 11*m, y = 2*m,  z = 0,      size = 5.5*m},
		{x = 11.2*m, y = 5*m,  z = -0.8*m, size = 5.2*m},
		{x = 11*m, y = 8*m,  z = -2*m,   size = 5*m},
		{x = 10*m, y = 10.5*m, z = -3*m, size = 4.7*m},
		{x = 8.5*m, y = 11.5*m, z = -4*m, size = 4.3*m},
	}
	for _, hp in ipairs(hookPositions) do
		local ball = Instance.new("Part")
		ball.Size = Vector3.new(hp.size, hp.size, hp.size)
		ball.Position = pos + Vector3.new(hp.x, hp.y, hp.z)
		ball.Anchored = true; ball.Color = Color3.fromRGB(230, 25, 25)
		ball.Material = Enum.Material.SmoothPlastic
		ball.Shape = Enum.PartType.Ball; ball.Parent = model

		-- White accent on each hook ball
		local accent = Instance.new("Part")
		accent.Size = Vector3.new(hp.size*0.7, hp.size*0.7, hp.size*0.7)
		accent.Position = pos + Vector3.new(hp.x, hp.y, hp.z)
		accent.Anchored = true; accent.Color = Color3.fromRGB(255,255,255)
		accent.Material = Enum.Material.SmoothPlastic
		accent.Shape = Enum.PartType.Ball
		accent.Transparency = 0.45; accent.CanCollide = false
		accent.Parent = model
	end

	-- Frosted sugar crystal effect (tiny neon specks scattered on surface)
	for i2 = 1, 12 do
		local crystal = Instance.new("Part")
		crystal.Size = Vector3.new(0.3*m, 0.3*m, 0.3*m)
		crystal.Position = pos + Vector3.new(
			(math.random()-0.5)*20*m,
			(math.random()-0.5)*4*m + 0.5*m,
			(math.random()-0.5)*4*m
		)
		crystal.Anchored = true; crystal.CanCollide = false
		crystal.Color = Color3.fromRGB(255, 245, 250)
		crystal.Material = Enum.Material.Neon
		crystal.Shape = Enum.PartType.Ball
		crystal.Transparency = 0.3
		crystal.Parent = model
	end

	-- Reflection highlight stripe (thin glass strip along the top)
	local highlight = Instance.new("Part")
	highlight.Size = Vector3.new(20*m, 0.5*m, 1*m)
	highlight.Position = pos + Vector3.new(0, 2.8*m, 0)
	highlight.Anchored = true; highlight.CanCollide = false
	highlight.Color = Color3.fromRGB(255, 255, 255)
	highlight.Material = Enum.Material.Glass
	highlight.Transparency = 0.7
	highlight.Parent = model

	-- Extra ambient glow
	glow(main, Color3.fromRGB(255, 150, 150), 28, 0.35)

	-- Sparkle parts floating nearby
	for i2 = 1, 4 do
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.2*m, 0.2*m, 0.2*m)
		sparkle.Position = pos + Vector3.new(
			(math.random()-0.5)*24*m,
			3*m + math.random()*5*m,
			(math.random()-0.5)*8*m
		)
		sparkle.Anchored = true; sparkle.CanCollide = false
		sparkle.Color = Color3.fromRGB(255, 255, 255)
		sparkle.Material = Enum.Material.Neon
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Transparency = 0.1
		sparkle.Parent = model
	end

	model.Parent = mapFolder
	return main, model
end

-- ============================================================
-- CANDY CORN: Soft, rounded, waxy, semi-translucent
-- ============================================================

local function buildCandyCorn(index, pos, m)
	m = m or 1
	local model = Instance.new("Model"); model.Name = "CandyCorn_"..index

	-- Yellow base
	local base = Instance.new("Part")
	base.Name = "Walkable"
	base.Size = Vector3.new(18*m, 4.5*m, 15*m)
	base.Position = pos; base.Anchored = true
	base.Color = Color3.fromRGB(255, 225, 50)
	base.Material = Enum.Material.SmoothPlastic
	base.TopSurface = Enum.SurfaceType.Smooth
	base.BottomSurface = Enum.SurfaceType.Smooth
	base.Parent = model
	glow(base, Color3.fromRGB(255, 240, 100), 16)

	-- Orange middle with rounded edges (ball for softness)
	local mid = Instance.new("Part")
	mid.Size = Vector3.new(15*m, 5*m, 12*m)
	mid.Position = pos + Vector3.new(0, 4.5*m, 0)
	mid.Anchored = true; mid.Color = Color3.fromRGB(255, 160, 0)
	mid.Material = Enum.Material.SmoothPlastic
	mid.CanCollide = true; mid.Parent = model

	-- Rounded edge balls on corners for soft look
	for x = -1, 1, 2 do
		for z = -1, 1, 2 do
			local corner = Instance.new("Part")
			corner.Size = Vector3.new(4*m, 4*m, 4*m)
			corner.Position = pos + Vector3.new(x*6*m, 4.5*m, z*4.5*m)
			corner.Anchored = true; corner.Color = Color3.fromRGB(255, 160, 0)
			corner.Material = Enum.Material.SmoothPlastic
			corner.Shape = Enum.PartType.Ball
			corner.CanCollide = false; corner.Parent = model
		end
	end

	-- White tip (big soft sphere)
	local tip = Instance.new("Part")
	tip.Size = Vector3.new(10*m, 8*m, 10*m)
	tip.Position = pos + Vector3.new(0, 10*m, 0)
	tip.Anchored = true; tip.Color = Color3.fromRGB(255, 255, 245)
	tip.Material = Enum.Material.SmoothPlastic
	tip.Shape = Enum.PartType.Ball
	tip.CanCollide = true; tip.Parent = model

	-- Waxy semi-translucent overlay (entire piece)
	local wax = Instance.new("Part")
	wax.Size = Vector3.new(17*m, 16*m, 14*m)
	wax.Position = pos + Vector3.new(0, 5*m, 0)
	wax.Anchored = true; wax.Color = Color3.fromRGB(255, 240, 200)
	wax.Material = Enum.Material.Glass
	wax.Transparency = 0.85; wax.CanCollide = false
	wax.Parent = model

	-- Smooth blending rings
	for _, info in ipairs({{2.5, 16, Color3.fromRGB(255, 200, 30)}, {7, 13, Color3.fromRGB(255, 215, 130)}}) do
		local blend = Instance.new("Part")
		blend.Size = Vector3.new(2*m, info[2]*m, info[2]*m)
		blend.Position = pos + Vector3.new(0, info[1]*m, 0)
		blend.Anchored = true; blend.Color = info[3]
		blend.Material = Enum.Material.SmoothPlastic
		blend.Shape = Enum.PartType.Cylinder
		blend.Orientation = Vector3.new(0,0,90)
		blend.Transparency = 0.2; blend.CanCollide = false
		blend.Parent = model
	end

	model.Parent = mapFolder
	return base, model
end

-- ============================================================
-- CHOCOLATE BAR: Rich, solid, 4x2 segments, crinkled foil
-- ============================================================

local function buildChocolateBar(index, pos, m)
	m = m or 1
	local model = Instance.new("Model"); model.Name = "ChocolateBar_"..index

	local bar = Instance.new("Part")
	bar.Name = "Walkable"
	bar.Size = Vector3.new(20*m, 4*m, 14*m)
	bar.Position = pos; bar.Anchored = true
	bar.Color = Color3.fromRGB(92, 48, 20)
	bar.Material = Enum.Material.SmoothPlastic
	bar.TopSurface = Enum.SurfaceType.Smooth
	bar.BottomSurface = Enum.SurfaceType.Smooth
	bar.Parent = model
	glow(bar, Color3.fromRGB(150, 100, 60), 14, 0.4)

	-- 4x2 embossed segments with rounded tops
	for col = -1.5, 1.5, 1 do
		for row = -0.5, 0.5, 1 do
			local seg = Instance.new("Part")
			seg.Size = Vector3.new(4.2*m, 1.5*m, 5.5*m)
			seg.Position = pos + Vector3.new(col*4.5*m, 2.7*m, row*3.2*m)
			seg.Anchored = true; seg.Color = Color3.fromRGB(75, 38, 12)
			seg.Material = Enum.Material.SmoothPlastic
			seg.CanCollide = true; seg.Parent = model

			-- Rounded dome top
			local dome = Instance.new("Part")
			dome.Size = Vector3.new(4*m, 1.5*m, 5.2*m)
			dome.Position = pos + Vector3.new(col*4.5*m, 3.5*m, row*3.2*m)
			dome.Anchored = true; dome.Color = Color3.fromRGB(82, 42, 16)
			dome.Material = Enum.Material.SmoothPlastic
			dome.Shape = Enum.PartType.Ball
			dome.CanCollide = false; dome.Parent = model

			-- Groove lines between segments
			local grooveX = Instance.new("Part")
			grooveX.Size = Vector3.new(0.2*m, 2*m, 5.5*m)
			grooveX.Position = pos + Vector3.new(col*4.5*m + 2.2*m, 2.5*m, row*3.2*m)
			grooveX.Anchored = true; grooveX.Color = Color3.fromRGB(55, 28, 8)
			grooveX.Material = Enum.Material.SmoothPlastic
			grooveX.CanCollide = false; grooveX.Parent = model
		end
	end

	-- Center groove (horizontal)
	local centerGroove = Instance.new("Part")
	centerGroove.Size = Vector3.new(19*m, 0.2*m, 0.3*m)
	centerGroove.Position = pos + Vector3.new(0, 2.8*m, 0)
	centerGroove.Anchored = true; centerGroove.Color = Color3.fromRGB(55, 28, 8)
	centerGroove.Material = Enum.Material.SmoothPlastic
	centerGroove.CanCollide = false; centerGroove.Parent = model

	-- Gold foil wrapper with crinkles
	for _, side in ipairs({-1, 1}) do
		local foil = Instance.new("Part")
		foil.Size = Vector3.new(3.5*m, 5*m, 16*m)
		foil.Position = pos + Vector3.new(side*10.5*m, 0, 0)
		foil.Anchored = true; foil.Color = Color3.fromRGB(215, 185, 50)
		foil.Material = Enum.Material.Foil
		foil.CanCollide = false; foil.Transparency = 0.15
		foil.Parent = model

		-- Crinkle folds
		for z2 = -3, 3 do
			local crinkle = Instance.new("Part")
			crinkle.Size = Vector3.new(2.5*m, 1.2*m, 1.8*m)
			crinkle.Position = pos + Vector3.new(side*11.5*m, math.random()*2*m, z2*2*m)
			crinkle.Anchored = true; crinkle.Color = Color3.fromRGB(225, 200, 65)
			crinkle.Material = Enum.Material.Foil
			crinkle.Rotation = Vector3.new(math.random(-15,15), math.random(-25,25), math.random(-10,10))
			crinkle.CanCollide = false; crinkle.Transparency = 0.2
			crinkle.Parent = model
		end
	end

	-- Snap lines between segment rows (thin dark grooves)
	for col = -0.5, 0.5, 1 do
		local snapLine = Instance.new("Part")
		snapLine.Size = Vector3.new(19*m, 0.15*m, 0.2*m)
		snapLine.Position = pos + Vector3.new(0, 2.1*m, col*3.2*m)
		snapLine.Anchored = true; snapLine.CanCollide = false
		snapLine.Color = Color3.fromRGB(40, 18, 5)
		snapLine.Material = Enum.Material.SmoothPlastic
		snapLine.Parent = model
	end

	-- Cocoa powder dust particles (tiny brown specks on top)
	for i2 = 1, 10 do
		local dust = Instance.new("Part")
		dust.Size = Vector3.new(0.25*m, 0.25*m, 0.25*m)
		dust.Position = pos + Vector3.new(
			(math.random()-0.5)*18*m,
			4*m + math.random()*0.5*m,
			(math.random()-0.5)*12*m
		)
		dust.Anchored = true; dust.CanCollide = false
		dust.Color = Color3.fromRGB(120, 65, 30)
		dust.Material = Enum.Material.SmoothPlastic
		dust.Shape = Enum.PartType.Ball
		dust.Transparency = 0.3
		dust.Parent = model
	end

	-- Melted edge effect (slightly darker, larger parts at edges)
	for _, side in ipairs({-1, 1}) do
		local meltX = Instance.new("Part")
		meltX.Size = Vector3.new(1.5*m, 3.5*m, 14.5*m)
		meltX.Position = pos + Vector3.new(side*10.2*m, -0.3*m, 0)
		meltX.Anchored = true; meltX.CanCollide = false
		meltX.Color = Color3.fromRGB(60, 30, 10)
		meltX.Material = Enum.Material.SmoothPlastic
		meltX.Transparency = 0.25
		meltX.Parent = model

		local meltZ = Instance.new("Part")
		meltZ.Size = Vector3.new(20.5*m, 3.5*m, 1.5*m)
		meltZ.Position = pos + Vector3.new(0, -0.3*m, side*7.2*m)
		meltZ.Anchored = true; meltZ.CanCollide = false
		meltZ.Color = Color3.fromRGB(60, 30, 10)
		meltZ.Material = Enum.Material.SmoothPlastic
		meltZ.Transparency = 0.25
		meltZ.Parent = model
	end

	-- Subtle sheen
	addSheen(model, Vector3.new(19*m, 2*m, 13*m), pos + Vector3.new(0, 3*m, 0), Color3.fromRGB(180, 140, 90))

	-- Extra ambient glow
	glow(bar, Color3.fromRGB(160, 110, 70), 22, 0.3)

	-- Sparkle parts floating nearby
	for i2 = 1, 3 do
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.2*m, 0.2*m, 0.2*m)
		sparkle.Position = pos + Vector3.new(
			(math.random()-0.5)*22*m,
			5*m + math.random()*4*m,
			(math.random()-0.5)*16*m
		)
		sparkle.Anchored = true; sparkle.CanCollide = false
		sparkle.Color = Color3.fromRGB(255, 235, 200)
		sparkle.Material = Enum.Material.Neon
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Transparency = 0.1
		sparkle.Parent = model
	end

	model.Parent = mapFolder
	return bar, model
end

-- ============================================================
-- LOLLIPOP: Vibrant swirl disc, glass-like, bold colors
-- ============================================================

local function buildLollipop(index, pos, m)
	m = m or 1
	local palettes = {
		{Color3.fromRGB(255,60,140), Color3.fromRGB(255,200,220)},
		{Color3.fromRGB(130,60,255), Color3.fromRGB(220,180,255)},
		{Color3.fromRGB(60,180,255), Color3.fromRGB(180,230,255)},
		{Color3.fromRGB(255,140,30), Color3.fromRGB(255,220,160)},
	}
	local pal = palettes[math.random(1, #palettes)]
	local model = Instance.new("Model"); model.Name = "Lollipop_"..index

	-- Thick stick
	local stick = Instance.new("Part")
	stick.Size = Vector3.new(3*m, 16*m, 3*m)
	stick.Position = pos + Vector3.new(0, -9*m, 0)
	stick.Anchored = true; stick.Color = Color3.fromRGB(245, 235, 210)
	stick.Material = Enum.Material.SmoothPlastic
	stick.Parent = model

	-- Main disc (walkable) — BIG vibrant
	local disc = Instance.new("Part")
	disc.Name = "Walkable"
	disc.Size = Vector3.new(4.5*m, 18*m, 18*m)
	disc.Position = pos; disc.Anchored = true
	disc.Color = pal[1]
	disc.Material = Enum.Material.SmoothPlastic
	disc.Shape = Enum.PartType.Cylinder
	disc.Orientation = Vector3.new(0,0,90)
	disc.TopSurface = Enum.SurfaceType.Smooth
	disc.BottomSurface = Enum.SurfaceType.Smooth
	disc.Parent = model
	glow(disc, pal[1], 22, 0.6)

	-- Swirl rings (8 alternating layers for tight spiral look)
	local swirlSizes = {16.5, 15, 13, 11, 9, 7, 5, 2.5}
	for i2, sz in ipairs(swirlSizes) do
		local swirl = Instance.new("Part")
		swirl.Size = Vector3.new((4.5 + 0.15*i2)*m, sz*m, sz*m)
		swirl.Position = pos + Vector3.new(0, 0.06*i2*m, 0)
		swirl.Anchored = true
		swirl.Color = if i2 % 2 == 0 then pal[2] else Color3.fromRGB(255,255,255)
		swirl.Material = Enum.Material.SmoothPlastic
		swirl.Shape = Enum.PartType.Cylinder
		swirl.Orientation = Vector3.new(0,0,90)
		swirl.Transparency = 0.3; swirl.CanCollide = false
		swirl.Parent = model
	end

	-- Glass-like shiny top surface
	local glass = Instance.new("Part")
	glass.Size = Vector3.new(1.5*m, 16*m, 16*m)
	glass.Position = pos + Vector3.new(0, 2.5*m, 0)
	glass.Anchored = true; glass.Color = Color3.fromRGB(255,255,255)
	glass.Material = Enum.Material.Glass
	glass.Shape = Enum.PartType.Cylinder
	glass.Orientation = Vector3.new(0,0,90)
	glass.Transparency = 0.8; glass.CanCollide = false
	glass.Parent = model

	-- Wrapper/cellophane effect at the base of the disc (transparent crinkled parts)
	for i2 = 1, 8 do
		local angle = (i2/8)*math.pi*2
		local wrapper = Instance.new("Part")
		wrapper.Size = Vector3.new(2.5*m, 3*m, 1.5*m)
		wrapper.Position = pos + Vector3.new(
			math.cos(angle)*9.5*m,
			-1*m,
			math.sin(angle)*9.5*m
		)
		wrapper.Rotation = Vector3.new(math.random(-20,20), math.deg(angle), math.random(-15,15))
		wrapper.Anchored = true; wrapper.CanCollide = false
		wrapper.Color = Color3.fromRGB(255, 240, 250)
		wrapper.Material = Enum.Material.Glass
		wrapper.Transparency = 0.6
		wrapper.Parent = model
	end

	-- Tiny bow on the stick
	for _, side in ipairs({-1, 1}) do
		local bowLoop = Instance.new("Part")
		bowLoop.Size = Vector3.new(2*m, 1.2*m, 1.2*m)
		bowLoop.Position = pos + Vector3.new(side*1.2*m, -14*m, 0)
		bowLoop.Anchored = true; bowLoop.CanCollide = false
		bowLoop.Color = pal[1]
		bowLoop.Material = Enum.Material.SmoothPlastic
		bowLoop.Shape = Enum.PartType.Ball
		bowLoop.Parent = model
	end
	local bowKnot = Instance.new("Part")
	bowKnot.Size = Vector3.new(0.8*m, 0.8*m, 0.8*m)
	bowKnot.Position = pos + Vector3.new(0, -14*m, 0)
	bowKnot.Anchored = true; bowKnot.CanCollide = false
	bowKnot.Color = pal[2]
	bowKnot.Material = Enum.Material.SmoothPlastic
	bowKnot.Shape = Enum.PartType.Ball
	bowKnot.Parent = model

	-- Extra ambient glow
	glow(disc, pal[1], 30, 0.4)

	-- Sparkle parts floating nearby
	for i2 = 1, 4 do
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.2*m, 0.2*m, 0.2*m)
		sparkle.Position = pos + Vector3.new(
			(math.random()-0.5)*20*m,
			3*m + math.random()*6*m,
			(math.random()-0.5)*20*m
		)
		sparkle.Anchored = true; sparkle.CanCollide = false
		sparkle.Color = Color3.fromRGB(255, 255, 255)
		sparkle.Material = Enum.Material.Neon
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Transparency = 0.1
		sparkle.Parent = model
	end

	model.Parent = mapFolder
	return disc, model
end

-- ============================================================
-- GUMMY BEAR: Squishy, semi-transparent, rounded features
-- ============================================================

local function buildGummyBear(index, pos, m)
	m = m or 1
	local gummyColors = {
		Color3.fromRGB(255,50,50), Color3.fromRGB(50,220,50),
		Color3.fromRGB(255,200,50), Color3.fromRGB(255,120,0),
		Color3.fromRGB(200, 50, 200),
	}
	local color = gummyColors[math.random(1, #gummyColors)]
	local model = Instance.new("Model"); model.Name = "GummyBear_"..index

	-- Squishy body (rounded block)
	local body = Instance.new("Part")
	body.Name = "Walkable"
	body.Size = Vector3.new(16*m, 7*m, 12*m)
	body.Position = pos; body.Anchored = true; body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Transparency = 0.18
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model
	glow(body, color, 16, 0.4)

	-- Rounded body edges (spheres at corners for squishy look)
	for x = -1, 1, 2 do
		for z = -1, 1, 2 do
			local edge = Instance.new("Part")
			edge.Size = Vector3.new(5*m, 7*m, 5*m)
			edge.Position = pos + Vector3.new(x*5.5*m, 0, z*3.5*m)
			edge.Anchored = true; edge.Color = color
			edge.Material = Enum.Material.SmoothPlastic
			edge.Shape = Enum.PartType.Ball
			edge.Transparency = 0.18; edge.CanCollide = false
			edge.Parent = model
		end
	end

	-- Big round head
	local head = Instance.new("Part")
	head.Size = Vector3.new(10*m, 8*m, 8*m)
	head.Position = pos + Vector3.new(0, 7.5*m, 0)
	head.Anchored = true; head.Color = color
	head.Material = Enum.Material.SmoothPlastic
	head.Shape = Enum.PartType.Ball
	head.Transparency = 0.18; head.CanCollide = true
	head.Parent = model

	-- Chubby ears
	for _, side in ipairs({-1, 1}) do
		local ear = Instance.new("Part")
		ear.Size = Vector3.new(3*m, 3.5*m, 3*m)
		ear.Position = pos + Vector3.new(side*3.5*m, 12*m, 0)
		ear.Anchored = true; ear.Color = color
		ear.Shape = Enum.PartType.Ball
		ear.Material = Enum.Material.SmoothPlastic
		ear.Transparency = 0.18; ear.CanCollide = false
		ear.Parent = model
	end

	-- Arms (stubby, squishy)
	for _, side in ipairs({-1, 1}) do
		local arm = Instance.new("Part")
		arm.Size = Vector3.new(3*m, 4.5*m, 3*m)
		arm.Position = pos + Vector3.new(side*8*m, 1*m, 0)
		arm.Anchored = true; arm.Color = color
		arm.Material = Enum.Material.SmoothPlastic
		arm.Shape = Enum.PartType.Ball
		arm.Transparency = 0.18; arm.CanCollide = false
		arm.Parent = model
	end

	-- Cute eyes (with highlights)
	for _, side in ipairs({-1, 1}) do
		local eye = Instance.new("Part")
		eye.Size = Vector3.new(1.2*m, 1.2*m, 1.2*m)
		eye.Position = pos + Vector3.new(side*1.8*m, 8.5*m, 4.2*m)
		eye.Anchored = true; eye.Color = Color3.fromRGB(15, 15, 15)
		eye.Shape = Enum.PartType.Ball; eye.Material = Enum.Material.SmoothPlastic
		eye.CanCollide = false; eye.Parent = model

		local hl = Instance.new("Part")
		hl.Size = Vector3.new(0.5*m, 0.5*m, 0.5*m)
		hl.Position = pos + Vector3.new(side*1.5*m, 9*m, 4.5*m)
		hl.Anchored = true; hl.Color = Color3.fromRGB(255,255,255)
		hl.Shape = Enum.PartType.Ball; hl.Material = Enum.Material.Neon
		hl.CanCollide = false; hl.Parent = model
	end

	-- Smile
	local smile = Instance.new("Part")
	smile.Size = Vector3.new(3*m, 0.6*m, 0.6*m)
	smile.Position = pos + Vector3.new(0, 6.8*m, 4.2*m)
	smile.Anchored = true; smile.Color = Color3.fromRGB(30, 15, 15)
	smile.Material = Enum.Material.SmoothPlastic
	smile.CanCollide = false; smile.Parent = model

	-- Internal glass sheen for gummy translucence (enhanced gradient)
	local innerGlow = Instance.new("Part")
	innerGlow.Size = Vector3.new(12*m, 10*m, 9*m)
	innerGlow.Position = pos + Vector3.new(0, 3*m, 0)
	innerGlow.Anchored = true; innerGlow.Color = color
	innerGlow.Material = Enum.Material.Glass
	innerGlow.Transparency = 0.6; innerGlow.CanCollide = false
	innerGlow.Parent = model

	-- Deeper translucency core (visible gradient center)
	local innerCore = Instance.new("Part")
	innerCore.Size = Vector3.new(8*m, 6*m, 6*m)
	innerCore.Position = pos + Vector3.new(0, 2*m, 0)
	innerCore.Anchored = true; innerCore.Color = color
	innerCore.Material = Enum.Material.Glass
	innerCore.Transparency = 0.45; innerCore.CanCollide = false
	innerCore.Parent = model

	-- Sugar coating effect (tiny white neon specks on surface)
	for i2 = 1, 16 do
		local sugar = Instance.new("Part")
		sugar.Size = Vector3.new(0.25*m, 0.25*m, 0.25*m)
		sugar.Position = pos + Vector3.new(
			(math.random()-0.5)*15*m,
			(math.random()-0.5)*6*m + 1*m,
			(math.random()-0.5)*11*m
		)
		sugar.Anchored = true; sugar.CanCollide = false
		sugar.Color = Color3.fromRGB(255, 255, 255)
		sugar.Material = Enum.Material.Neon
		sugar.Shape = Enum.PartType.Ball
		sugar.Transparency = 0.2
		sugar.Parent = model
	end

	-- Belly button detail (small dark sphere)
	local bellyButton = Instance.new("Part")
	bellyButton.Size = Vector3.new(1*m, 1*m, 1*m)
	bellyButton.Position = pos + Vector3.new(0, 0, 6.2*m)
	bellyButton.Anchored = true; bellyButton.CanCollide = false
	bellyButton.Color = Color3.new(color.R*0.5, color.G*0.5, color.B*0.5)
	bellyButton.Material = Enum.Material.SmoothPlastic
	bellyButton.Shape = Enum.PartType.Ball
	bellyButton.Transparency = 0.1
	bellyButton.Parent = model

	-- Extra ambient glow
	glow(body, color, 24, 0.35)
	glow(head, color, 16, 0.3)

	-- Sparkle parts floating nearby
	for i2 = 1, 4 do
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.2*m, 0.2*m, 0.2*m)
		sparkle.Position = pos + Vector3.new(
			(math.random()-0.5)*20*m,
			5*m + math.random()*10*m,
			(math.random()-0.5)*14*m
		)
		sparkle.Anchored = true; sparkle.CanCollide = false
		sparkle.Color = Color3.fromRGB(255, 255, 255)
		sparkle.Material = Enum.Material.Neon
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Transparency = 0.1
		sparkle.Parent = model
	end

	model.Parent = mapFolder
	return body, model
end

-- ============================================================
-- DONUT: Glossy frosting, drips, sprinkles, bakery look
-- ============================================================

local function buildDonut(index, pos, m)
	m = m or 1
	local frostColors = {
		Color3.fromRGB(255,140,190), Color3.fromRGB(190,120,255),
		Color3.fromRGB(120,190,255), Color3.fromRGB(255,210,120),
	}
	local frostColor = frostColors[math.random(1, #frostColors)]
	local model = Instance.new("Model"); model.Name = "Donut_"..index

	-- Big dough ring
	local ring = Instance.new("Part")
	ring.Name = "Walkable"
	ring.Size = Vector3.new(5*m, 20*m, 20*m)
	ring.Position = pos; ring.Anchored = true
	ring.Color = Color3.fromRGB(215, 175, 105)
	ring.Material = Enum.Material.SmoothPlastic
	ring.Shape = Enum.PartType.Cylinder
	ring.Orientation = Vector3.new(0,0,90)
	ring.TopSurface = Enum.SurfaceType.Smooth
	ring.BottomSurface = Enum.SurfaceType.Smooth
	ring.Parent = model
	glow(ring, Color3.fromRGB(235, 205, 145), 14, 0.4)

	-- Glossy frosting layer
	local frost = Instance.new("Part")
	frost.Size = Vector3.new(2.5*m, 19*m, 19*m)
	frost.Position = pos + Vector3.new(0, 1.5*m, 0)
	frost.Anchored = true; frost.Color = frostColor
	frost.Material = Enum.Material.SmoothPlastic
	frost.Shape = Enum.PartType.Cylinder
	frost.Orientation = Vector3.new(0,0,90)
	frost.CanCollide = false; frost.Parent = model

	-- Glossy sheen on frosting
	local frostGlass = Instance.new("Part")
	frostGlass.Size = Vector3.new(1*m, 18*m, 18*m)
	frostGlass.Position = pos + Vector3.new(0, 2.5*m, 0)
	frostGlass.Anchored = true; frostGlass.Color = Color3.fromRGB(255,255,255)
	frostGlass.Material = Enum.Material.Glass
	frostGlass.Shape = Enum.PartType.Cylinder
	frostGlass.Orientation = Vector3.new(0,0,90)
	frostGlass.Transparency = 0.82; frostGlass.CanCollide = false
	frostGlass.Parent = model

	-- Frosting drips around edge
	for i2 = 1, 10 do
		local angle = (i2/10)*math.pi*2
		local drip = Instance.new("Part")
		drip.Size = Vector3.new(2*m, 2.5 + math.random()*2*m, 2*m)
		drip.Position = pos + Vector3.new(math.cos(angle)*8.5*m, 0, math.sin(angle)*8.5*m)
		drip.Anchored = true; drip.Color = frostColor
		drip.Material = Enum.Material.SmoothPlastic
		drip.Shape = Enum.PartType.Ball
		drip.CanCollide = false; drip.Parent = model
	end

	-- Sprinkles (lots of them - 25 for full coverage)
	local sprColors = {Color3.fromRGB(255,70,70),Color3.fromRGB(70,255,70),Color3.fromRGB(70,70,255),Color3.fromRGB(255,255,70),Color3.fromRGB(255,70,255),Color3.fromRGB(70,255,255)}
	for i2 = 1, 25 do
		local angle = (i2/25)*math.pi*2 + math.random()*0.3
		local radius = (3 + math.random()*4.5)*m
		local spr = Instance.new("Part")
		spr.Size = Vector3.new(0.4*m, 0.4*m, 1.4*m)
		spr.Position = pos + Vector3.new(math.cos(angle)*radius, 3*m, math.sin(angle)*radius)
		spr.Rotation = Vector3.new(math.random(-15,15), math.random(0,360), math.random(-15,15))
		spr.Anchored = true; spr.CanCollide = false
		spr.Color = sprColors[math.random(1,#sprColors)]
		spr.Material = Enum.Material.SmoothPlastic
		spr.Parent = model
	end

	-- Bite mark (wedge-shaped dark transparent cutout)
	local bite = Instance.new("Part")
	bite.Size = Vector3.new(5*m, 6*m, 5*m)
	bite.Position = pos + Vector3.new(9*m, 0, 0)
	bite.Anchored = true; bite.CanCollide = false
	bite.Color = Color3.fromRGB(30, 20, 10)
	bite.Material = Enum.Material.SmoothPlastic
	bite.Transparency = 0.3
	bite.Parent = model

	-- Cream filling visible at the bite mark
	local cream = Instance.new("Part")
	cream.Size = Vector3.new(3*m, 4*m, 3.5*m)
	cream.Position = pos + Vector3.new(8.5*m, 0, 0)
	cream.Anchored = true; cream.CanCollide = false
	cream.Color = Color3.fromRGB(255, 250, 220)
	cream.Material = Enum.Material.SmoothPlastic
	cream.Shape = Enum.PartType.Ball
	cream.Parent = model

	local creamDrip = Instance.new("Part")
	creamDrip.Size = Vector3.new(1.5*m, 2*m, 1.5*m)
	creamDrip.Position = pos + Vector3.new(9.5*m, -1.5*m, 0)
	creamDrip.Anchored = true; creamDrip.CanCollide = false
	creamDrip.Color = Color3.fromRGB(255, 250, 225)
	creamDrip.Material = Enum.Material.SmoothPlastic
	creamDrip.Shape = Enum.PartType.Ball
	creamDrip.Parent = model

	-- Extra ambient glow
	glow(ring, Color3.fromRGB(255, 225, 170), 22, 0.35)

	-- Glass sheen overlay for candy shine
	local donutGlass = Instance.new("Part")
	donutGlass.Size = Vector3.new(4*m, 18*m, 18*m)
	donutGlass.Position = pos + Vector3.new(0, 1*m, 0)
	donutGlass.Anchored = true; donutGlass.CanCollide = false
	donutGlass.Color = Color3.fromRGB(255, 255, 255)
	donutGlass.Material = Enum.Material.Glass
	donutGlass.Shape = Enum.PartType.Cylinder
	donutGlass.Orientation = Vector3.new(0,0,90)
	donutGlass.Transparency = 0.88
	donutGlass.Parent = model

	-- Sparkle parts floating nearby
	for i2 = 1, 4 do
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.2*m, 0.2*m, 0.2*m)
		sparkle.Position = pos + Vector3.new(
			(math.random()-0.5)*22*m,
			4*m + math.random()*5*m,
			(math.random()-0.5)*22*m
		)
		sparkle.Anchored = true; sparkle.CanCollide = false
		sparkle.Color = Color3.fromRGB(255, 255, 255)
		sparkle.Material = Enum.Material.Neon
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Transparency = 0.1
		sparkle.Parent = model
	end

	model.Parent = mapFolder
	return ring, model
end

-- ============================================================
-- CUPCAKE: Detailed, layered frosting, sprinkles, wrapper ridges, cherry
-- ============================================================

local function buildCupcake(index, pos, m)
	m = m or 1
	local model = Instance.new("Model"); model.Name = "Cupcake_"..index

	-- Wrapper
	local wrapper = Instance.new("Part")
	wrapper.Name = "Walkable"
	wrapper.Size = Vector3.new(16*m, 7*m, 16*m)
	wrapper.Position = pos; wrapper.Anchored = true
	wrapper.Color = Color3.fromRGB(225, 185, 100)
	wrapper.Material = Enum.Material.SmoothPlastic
	wrapper.TopSurface = Enum.SurfaceType.Smooth
	wrapper.BottomSurface = Enum.SurfaceType.Smooth
	wrapper.Parent = model
	glow(wrapper, Color3.fromRGB(255, 225, 155), 12, 0.3)

	-- Wrapper ridges (vertical strips)
	for i2 = 1, 12 do
		local angle = (i2/12)*math.pi*2
		local ridge = Instance.new("Part")
		ridge.Size = Vector3.new(0.5*m, 7*m, 1.2*m)
		ridge.Position = pos + Vector3.new(math.cos(angle)*8*m, 0, math.sin(angle)*8*m)
		ridge.Rotation = Vector3.new(0, math.deg(angle), 0)
		ridge.Anchored = true; ridge.Color = Color3.fromRGB(205, 165, 80)
		ridge.Material = Enum.Material.SmoothPlastic
		ridge.CanCollide = false; ridge.Transparency = 0.15
		ridge.Parent = model
	end

	-- Cake visible above wrapper
	local cake = Instance.new("Part")
	cake.Size = Vector3.new(14*m, 2*m, 14*m)
	cake.Position = pos + Vector3.new(0, 4.5*m, 0)
	cake.Anchored = true; cake.Color = Color3.fromRGB(240, 210, 160)
	cake.Material = Enum.Material.SmoothPlastic
	cake.CanCollide = true; cake.Parent = model

	-- Big frosting swirl (layered balls)
	local frostBig = Instance.new("Part")
	frostBig.Size = Vector3.new(12*m, 6*m, 12*m)
	frostBig.Position = pos + Vector3.new(0, 7*m, 0)
	frostBig.Anchored = true; frostBig.Color = Color3.fromRGB(255, 175, 215)
	frostBig.Material = Enum.Material.SmoothPlastic
	frostBig.Shape = Enum.PartType.Ball
	frostBig.CanCollide = true; frostBig.Parent = model

	local frostMid = Instance.new("Part")
	frostMid.Size = Vector3.new(9*m, 4*m, 9*m)
	frostMid.Position = pos + Vector3.new(0, 10*m, 0)
	frostMid.Anchored = true; frostMid.Color = Color3.fromRGB(255, 200, 230)
	frostMid.Material = Enum.Material.SmoothPlastic
	frostMid.Shape = Enum.PartType.Ball
	frostMid.CanCollide = false; frostMid.Parent = model

	local frostTop = Instance.new("Part")
	frostTop.Size = Vector3.new(5*m, 3*m, 5*m)
	frostTop.Position = pos + Vector3.new(0, 12.5*m, 0)
	frostTop.Anchored = true; frostTop.Color = Color3.fromRGB(255, 220, 240)
	frostTop.Material = Enum.Material.SmoothPlastic
	frostTop.Shape = Enum.PartType.Ball
	frostTop.CanCollide = false; frostTop.Parent = model

	-- Frosting gloss
	addSheen(model, Vector3.new(11*m, 8*m, 11*m), pos + Vector3.new(0, 8*m, 0), Color3.fromRGB(255,230,240))

	-- Cherry on top
	local cherry = Instance.new("Part")
	cherry.Size = Vector3.new(3*m, 3*m, 3*m)
	cherry.Position = pos + Vector3.new(0, 14*m, 0)
	cherry.Anchored = true; cherry.Color = Color3.fromRGB(220, 15, 15)
	cherry.Material = Enum.Material.SmoothPlastic
	cherry.Shape = Enum.PartType.Ball; cherry.CanCollide = false
	cherry.Parent = model

	local chl = Instance.new("Part")
	chl.Size = Vector3.new(1*m, 1*m, 1*m)
	chl.Position = pos + Vector3.new(0.7*m, 15*m, 0.7*m)
	chl.Anchored = true; chl.Color = Color3.fromRGB(255,200,200)
	chl.Shape = Enum.PartType.Ball; chl.Material = Enum.Material.Neon
	chl.CanCollide = false; chl.Transparency = 0.3; chl.Parent = model

	local stem = Instance.new("Part")
	stem.Size = Vector3.new(0.4*m, 3*m, 0.4*m)
	stem.Position = pos + Vector3.new(0, 16*m, 0)
	stem.Anchored = true; stem.Color = Color3.fromRGB(45, 110, 25)
	stem.Material = Enum.Material.SmoothPlastic
	stem.CanCollide = false; stem.Parent = model

	model.Parent = mapFolder
	return wrapper, model
end

-- ============================================================
-- JAWBREAKER: Smooth, shiny, bright striped sphere
-- ============================================================

local function buildJawbreaker(index, pos, m)
	m = m or 1
	local model = Instance.new("Model"); model.Name = "Jawbreaker_"..index

	local layers = {
		{size = 16, color = Color3.fromRGB(255, 65, 65), trans = 0},
		{size = 13, color = Color3.fromRGB(255, 200, 65), trans = 0.15},
		{size = 10, color = Color3.fromRGB(65, 200, 255), trans = 0.2},
		{size = 7,  color = Color3.fromRGB(200, 65, 255), trans = 0.25},
		{size = 4,  color = Color3.fromRGB(255, 255, 255), trans = 0.3},
	}

	local walkable
	for i2, layer in ipairs(layers) do
		local sphere = Instance.new("Part")
		sphere.Size = Vector3.new(layer.size*m, layer.size*m, layer.size*m)
		sphere.Position = pos; sphere.Anchored = true
		sphere.Color = layer.color
		sphere.Material = Enum.Material.SmoothPlastic
		sphere.Shape = Enum.PartType.Ball
		sphere.Transparency = layer.trans
		sphere.CanCollide = (i2 == 1)
		sphere.Parent = model
		if i2 == 1 then
			sphere.Name = "Walkable"
			walkable = sphere
			glow(sphere, layer.color, 18, 0.5)
		end
	end

	-- Glossy sheen
	local glass = Instance.new("Part")
	glass.Size = Vector3.new(16.5*m, 16.5*m, 16.5*m)
	glass.Position = pos; glass.Anchored = true
	glass.Color = Color3.fromRGB(255,255,255)
	glass.Material = Enum.Material.Glass
	glass.Shape = Enum.PartType.Ball
	glass.Transparency = 0.88; glass.CanCollide = false
	glass.Parent = model

	model.Parent = mapFolder
	return walkable, model
end

local BUILDERS = {
	candycane = buildCandyCane, candycorn = buildCandyCorn,
	chocolate = buildChocolateBar, lollipop = buildLollipop,
	gummy = buildGummyBear, donut = buildDonut,
	cupcake = buildCupcake, jawbreaker = buildJawbreaker,
}

-- ============================================================
-- LEVELS (50)
-- ============================================================

-- extra = {{dx,dy,dz,candy,size}, ...} — additional candy blocks relative to the main one
local LEVELS = {
	-- ====== PHASE 1: WARM-UP (1-15) ======
	{offset={0,-1,-24},candy="chocolate",size=1.4,
		extra={{13,3,-16,"candycorn",1.0},{-11,1,-28,"gummy",1.1}}},
	{offset={4,0,-22},candy="candycorn",size=1.3,
		extra={{-15,1,-20,"lollipop",1.0},{6,-1,-32,"donut",1.1}}},
	{offset={-6,1,-25},candy="donut",size=1.3,
		extra={{11,3,-18,"chocolate",1.0}}},
	{offset={3,-1,-20},candy="gummy",size=1.2,
		extra={{-8,1,-22,"cupcake",1.0},{13,3,-36,"candycane",1.1}}},
	{offset={-5,2,-24},candy="cupcake",size=1.3,
		extra={{8,-1,-20,"jawbreaker",1.0}}},
	{offset={7,0,-22},candy="lollipop",size=1.2,
		extra={{-13,1,-24,"gummy",1.0},{-4,-2,-40,"candycorn",1.1}}},
	{offset={-4,-2,-25},candy="jawbreaker",size=1.2,
		extra={{11,1,-20,"chocolate",1.0}}},
	{offset={2,1,-20},candy="candycane",size=1.3,
		extra={{-11,-2,-22,"donut",0.95},{8,1,-36,"lollipop",1.0}}},
	{offset={-6,0,-24},candy="chocolate",size=1.2,
		extra={{15,-1,-20,"cupcake",1.0}}},
	{offset={5,2,-22},candy="gummy",size=1.1,
		extra={{-13,-2,-24,"jawbreaker",1.0},{-4,3,-40,"candycane",1.0}}},
	{offset={-3,-1,-25},candy="lollipop",size=1.2,
		extra={{11,1,-18,"candycorn",0.95}}},
	{offset={7,1,-20},candy="donut",size=1.1,
		extra={{-11,-2,-24,"gummy",1.0},{-17,1,-40,"cupcake",1.0}}},
	{offset={-8,0,-24},candy="cupcake",size=1.2,
		extra={{13,-1,-20,"chocolate",1.0}}},
	{offset={5,2,-22},candy="candycorn",size=1.1,
		extra={{-8,-2,-22,"lollipop",0.95},{-15,3,-36,"jawbreaker",1.0}}},
	{offset={0,-1,-25},candy="jawbreaker",size=1.3,checkpoint=true}, -- 15: CHECKPOINT

	-- ====== PHASE 2: MIXED PATHS (16-30) ======
	{offset={-6,3,-26},candy="candycane",size=1.1,
		extra={{11,-1,-20,"gummy",0.85},{17,1,-36,"lollipop",0.9}}},
	{offset={8,-2,-24},candy="lollipop",size=1.0,
		extra={{-13,3,-20,"chocolate",0.85},{-6,-2,-34,"candycorn",0.9}}},
	{offset={-5,4,-25},candy="gummy",size=0.95,
		extra={{13,-1,-22,"donut",0.85},{6,3,-38,"cupcake",0.9}}},
	{offset={7,-3,-28},candy="chocolate",size=1.0,
		extra={{-11,3,-18,"jawbreaker",0.8}}},
	-- Staircase 20-22
	{offset={-3,3,-16},candy="candycorn",size=0.95,
		extra={{-4,4,-20,"candycane",0.85},{0,4,-36,"lollipop",0.85}}},
	{offset={-2,4,-15},candy="candycane",size=0.9,
		extra={{8,-1,-18,"gummy",0.8}}},
	{offset={0,4,-16},candy="lollipop",size=0.9,
		extra={{-11,-3,-20,"chocolate",0.8},{11,1,-34,"donut",0.85}}},
	{offset={4,-6,-28},candy="cupcake",size=0.95,moving=true,
		extra={{-13,4,-20,"jawbreaker",0.8}}},
	{offset={-7,3,-26},candy="jawbreaker",size=0.9,
		extra={{13,-3,-22,"candycorn",0.8},{6,1,-36,"gummy",0.85}}},
	{offset={8,-4,-25},candy="gummy",size=0.85,crumbling=true,
		extra={{-15,4,-20,"cupcake",0.8}}},
	{offset={-6,5,-28},candy="donut",size=0.9,moving=true,
		extra={{11,-3,-22,"lollipop",0.8},{17,3,-36,"candycane",0.85}}},
	{offset={5,-3,-24},candy="chocolate",size=0.95,
		extra={{-13,3,-20,"jawbreaker",0.8}}},
	{offset={-8,4,-26},candy="candycane",size=0.9,crumbling=true,
		extra={{15,-4,-22,"gummy",0.8},{8,1,-36,"chocolate",0.85}}},
	{offset={7,-5,-28},candy="lollipop",size=0.85,moving=true,
		extra={{-13,4,-20,"donut",0.8}}},
	{offset={0,2,-25},candy="cupcake",size=1.2,checkpoint=true}, -- 30: CHECKPOINT

	-- ====== PHASE 3: GAUNTLET (31-45) ======
	{offset={-8,3,-30},candy="jawbreaker",size=0.8,moving=true,
		extra={{13,-3,-20,"candycorn",0.65},{22,1,-36,"gummy",0.7}}},
	{offset={10,-4,-28},candy="candycorn",size=0.75,
		extra={{-17,4,-20,"chocolate",0.65},{-11,-1,-34,"lollipop",0.7}}},
	{offset={-9,5,-30},candy="gummy",size=0.7,crumbling=true,
		extra={{15,-4,-20,"cupcake",0.6},{8,3,-32,"candycane",0.65}}},
	{offset={8,-6,-26},candy="chocolate",size=0.75,moving=true,
		extra={{-15,6,-22,"donut",0.6}}},
	-- Combo chain 35-38
	{offset={-4,-5,-14},candy="lollipop",size=0.65,
		extra={{8,4,-16,"jawbreaker",0.55},{-6,-3,-28,"candycorn",0.6}}},
	{offset={5,6,-13},candy="candycane",size=0.6,
		extra={{-11,-4,-18,"gummy",0.55},{8,6,-30,"chocolate",0.6}}},
	{offset={-6,-5,-12},candy="donut",size=0.65,crumbling=true,
		extra={{13,3,-18,"cupcake",0.55}}},
	{offset={7,7,-15},candy="cupcake",size=0.6,moving=true,
		extra={{-13,-6,-20,"lollipop",0.55},{-6,4,-32,"jawbreaker",0.6}}},
	-- Height rollercoaster 39-42
	{offset={-8,8,-30},candy="jawbreaker",size=0.7,moving=true,
		extra={{13,-4,-20,"candycane",0.6}}},
	{offset={6,-10,-28},candy="gummy",size=0.65,crumbling=true,
		extra={{-11,6,-20,"donut",0.55},{-17,1,-34,"candycorn",0.6}}},
	{offset={-5,9,-26},candy="candycorn",size=0.7,moving=true,
		extra={{13,-6,-20,"chocolate",0.55}}},
	{offset={8,-8,-30},candy="chocolate",size=0.65,crumbling=true,
		extra={{-15,7,-20,"gummy",0.55},{-6,3,-34,"lollipop",0.6}}},
	-- Zigzag
	{offset={-10,5,-28},candy="lollipop",size=0.7,moving=true,
		extra={{17,-4,-20,"cupcake",0.55}}},
	{offset={10,-4,-26},candy="candycane",size=0.65,crumbling=true,
		extra={{-17,6,-20,"jawbreaker",0.55},{-11,-3,-32,"donut",0.6}}},
	{offset={0,2,-28},candy="donut",size=1.2,checkpoint=true}, -- 45: CHECKPOINT

	-- ====== PHASE 4: EXTREME (46-60) ======
	{offset={-8,-4,-30},candy="cupcake",size=0.65,moving=true,
		extra={{13,4,-18,"lollipop",0.5},{22,-1,-32,"jawbreaker",0.55}}},
	{offset={10,6,-28},candy="jawbreaker",size=0.6,crumbling=true,
		extra={{-17,-4,-20,"candycorn",0.5}}},
	{offset={-7,-8,-32},candy="gummy",size=0.55,moving=true,
		extra={{15,6,-20,"chocolate",0.5},{8,-3,-34,"candycane",0.5}}},
	{offset={9,7,-28},candy="candycorn",size=0.6,crumbling=true,
		extra={{-15,-4,-20,"donut",0.5}}},
	{offset={-8,-6,-30},candy="chocolate",size=0.6,moving=true,
		extra={{13,6,-18,"cupcake",0.5},{19,-3,-32,"gummy",0.5}}},
	-- Rapid fire 51-56
	{offset={5,-5,-13},candy="lollipop",size=0.5,moving=true,
		extra={{-8,4,-16,"jawbreaker",0.4}}},
	{offset={-6,6,-12},candy="candycane",size=0.55,crumbling=true,
		extra={{11,-4,-18,"candycorn",0.45},{6,3,-30,"chocolate",0.5}}},
	{offset={7,-7,-14},candy="donut",size=0.5,moving=true,
		extra={{-13,6,-16,"gummy",0.4}}},
	{offset={-5,5,-11},candy="cupcake",size=0.55,crumbling=true,
		extra={{11,-6,-18,"lollipop",0.45}}},
	{offset={6,-6,-13},candy="jawbreaker",size=0.5,moving=true,
		extra={{-11,4,-18,"candycane",0.4},{-6,-3,-30,"donut",0.45}}},
	{offset={-7,7,-15},candy="gummy",size=0.5,crumbling=true,
		extra={{13,-6,-16,"cupcake",0.4}}},
	{offset={4,-9,-30},candy="candycorn",size=0.55,moving=true,
		extra={{-11,7,-20,"chocolate",0.45},{-17,-2,-34,"lollipop",0.5}}},
	{offset={-6,8,-28},candy="chocolate",size=0.55,crumbling=true,
		extra={{15,-6,-18,"gummy",0.45}}},
	{offset={8,-7,-32},candy="lollipop",size=0.5,moving=true,
		extra={{-13,4,-20,"candycane",0.4},{-19,1,-34,"jawbreaker",0.45}}},
	{offset={0,2,-26},candy="candycane",size=1.2,checkpoint=true}, -- 60: CHECKPOINT

	-- ====== PHASE 5: NIGHTMARE (61-75) ======
	{offset={-9,-5,-32},candy="donut",size=0.5,moving=true,
		extra={{15,4,-18,"gummy",0.4},{22,-3,-32,"candycorn",0.4}}},
	{offset={10,7,-30},candy="cupcake",size=0.45,crumbling=true,
		extra={{-17,-6,-18,"jawbreaker",0.35},{-11,3,-30,"chocolate",0.4}}},
	{offset={-8,-9,-32},candy="jawbreaker",size=0.45,moving=true,
		extra={{15,7,-18,"lollipop",0.35}}},
	{offset={9,8,-28},candy="gummy",size=0.5,crumbling=true,
		extra={{-15,-4,-20,"candycane",0.4},{-22,3,-32,"donut",0.4}}},
	{offset={-10,-7,-34},candy="candycorn",size=0.45,moving=true,
		extra={{17,6,-18,"cupcake",0.35}}},
	{offset={8,6,-30},candy="chocolate",size=0.5,crumbling=true,
		extra={{-13,-4,-20,"lollipop",0.35},{-19,1,-32,"jawbreaker",0.4}}},
	{offset={-7,-10,-32},candy="lollipop",size=0.45,moving=true,
		extra={{13,7,-18,"gummy",0.35}}},
	{offset={9,9,-28},candy="candycane",size=0.45,crumbling=true,
		extra={{-15,-7,-20,"chocolate",0.35},{-22,4,-32,"candycorn",0.4}}},
	{offset={-10,-8,-34},candy="donut",size=0.4,moving=true,
		extra={{17,6,-18,"cupcake",0.3}}},
	{offset={8,7,-30},candy="cupcake",size=0.45,crumbling=true,
		extra={{-15,-4,-20,"jawbreaker",0.35},{-22,3,-32,"gummy",0.35}}},
	{offset={-9,-10,-32},candy="jawbreaker",size=0.4,moving=true,
		extra={{15,7,-18,"lollipop",0.3}}},
	{offset={10,8,-30},candy="gummy",size=0.4,crumbling=true,
		extra={{-17,-6,-18,"candycane",0.3},{-11,3,-30,"chocolate",0.35}}},
	{offset={-8,-9,-34},candy="candycorn",size=0.4,moving=true,
		extra={{15,6,-18,"donut",0.3}}},
	{offset={9,10,-28},candy="chocolate",size=0.4,crumbling=true,
		extra={{-17,-7,-20,"cupcake",0.3},{-11,4,-32,"lollipop",0.35}}},
	{offset={0,0,-30},candy="cupcake",size=1.4,checkpoint=true}, -- 75: FINAL CHECKPOINT
}

-- ============================================================
-- COLLECTIBLE
-- ============================================================

local function createCollectible(position, index)
	local cols = {Color3.fromRGB(255,100,150),Color3.fromRGB(150,100,255),Color3.fromRGB(100,200,255),Color3.fromRGB(255,200,100)}
	local c = Instance.new("Part")
	c.Name = "Collectible_"..index; c.Size = Vector3.new(2.5,2.5,2.5)
	c.Position = position + Vector3.new(0,8,0)
	c.Anchored = true; c.CanCollide = false; c.Shape = Enum.PartType.Ball
	c.Color = cols[math.random(1,#cols)]; c.Material = Enum.Material.Neon
	c.Parent = collectiblesFolder
	local light = Instance.new("PointLight"); light.Color = c.Color; light.Brightness = 1; light.Range = 10; light.Parent = c
	local bp = c.Position
	task.spawn(function()
		while c and c.Parent do
			c.Orientation += Vector3.new(0,4,0)
			c.Position = bp + Vector3.new(0, math.sin(tick()*2.5)*1.5, 0)
			task.wait(0.03)
		end
	end)
	c.Touched:Connect(function(hit)
		local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
		if plr and c.Parent then c.Parent = nil; candyCollectedEvent:FireClient(plr) end
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
	-- ITEM CAPSULES (5 items, arranged in an arc)
	-- ============================================================
	local capsuleZ = 35  -- behind spawn
	local capsuleSpacing = 22

	local speedTrigger = createItemCapsule(
		Vector3.new(-capsuleSpacing*2, floorY + 10, capsuleZ),
		"Speed Coil", Color3.fromRGB(80, 200, 255), "⚡", "speed_coil"
	)

	local gravityTrigger = createItemCapsule(
		Vector3.new(-capsuleSpacing, floorY + 10, capsuleZ),
		"Gravity Coil", Color3.fromRGB(180, 80, 255), "🌀", "gravity_coil"
	)

	local fusionTrigger = createItemCapsule(
		Vector3.new(0, floorY + 10, capsuleZ),
		"Fusion Coil", Color3.fromRGB(130, 140, 255), "💫", "fusion_coil"
	)

	local carpetTrigger = createItemCapsule(
		Vector3.new(capsuleSpacing, floorY + 10, capsuleZ),
		"Magic Carpet", Color3.fromRGB(255, 180, 50), "🧞", "carpet"
	)

	local grappleTrigger = createItemCapsule(
		Vector3.new(capsuleSpacing*2, floorY + 10, capsuleZ),
		"Grapple Gun", Color3.fromRGB(255, 80, 80), "🪝", "grapple"
	)

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
			-- Carpet: tell client to enable flight mode
			tool.Equipped:Connect(function()
				carpetFlyEvent:FireClient(player, true)
				-- Sit on carpet: force sit
				if hum then
					hum.Sit = true
				end
			end)
			tool.Unequipped:Connect(function()
				carpetFlyEvent:FireClient(player, false)
				if hum then
					hum.Sit = false
				end
				-- Clean up any flight forces
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local bg = rootPart:FindFirstChild("CarpetGyro")
					if bg then bg:Destroy() end
					local bv = rootPart:FindFirstChild("CarpetVelocity")
					if bv then bv:Destroy() end
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
		end

		tool.Parent = player.Backpack
	end

	-- Touch detection for capsules
	local debounces = {}

	speedTrigger.Touched:Connect(function(hit)
		local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
		if plr and not debounces[plr.UserId.."speed"] then
			debounces[plr.UserId.."speed"] = true
			giveItem(plr, "Speed Coil")
			task.delay(2, function() debounces[plr.UserId.."speed"] = nil end)
		end
	end)

	gravityTrigger.Touched:Connect(function(hit)
		local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
		if plr and not debounces[plr.UserId.."gravity"] then
			debounces[plr.UserId.."gravity"] = true
			giveItem(plr, "Gravity Coil")
			task.delay(2, function() debounces[plr.UserId.."gravity"] = nil end)
		end
	end)

	fusionTrigger.Touched:Connect(function(hit)
		local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
		if plr and not debounces[plr.UserId.."fusion"] then
			debounces[plr.UserId.."fusion"] = true
			giveItem(plr, "Fusion Coil")
			task.delay(2, function() debounces[plr.UserId.."fusion"] = nil end)
		end
	end)

	carpetTrigger.Touched:Connect(function(hit)
		local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
		if plr and not debounces[plr.UserId.."carpet"] then
			debounces[plr.UserId.."carpet"] = true
			giveItem(plr, "Magic Carpet")
			task.delay(2, function() debounces[plr.UserId.."carpet"] = nil end)
		end
	end)

	grappleTrigger.Touched:Connect(function(hit)
		local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
		if plr and not debounces[plr.UserId.."grapple"] then
			debounces[plr.UserId.."grapple"] = true
			giveItem(plr, "Grapple Gun")
			task.delay(2, function() debounces[plr.UserId.."grapple"] = nil end)
		end
	end)
	print("[CandyRun] Spawn room created! Capsules placed at Z=35, floorY=" .. tostring(START_HEIGHT))
end

-- ============================================================
-- HALLWAY (opaque walls, candy ceiling)
-- ============================================================

local function createHallway()
	hallwayFolder:ClearAllChildren()
	local minZ, maxZ = 100, 0
	local testPos = Vector3.new(0, START_HEIGHT, -65) -- match generateMap start
	for _, level in ipairs(LEVELS) do
		testPos = testPos + Vector3.new(level.offset[1], level.offset[2], level.offset[3])
		if testPos.Z < minZ then minZ = testPos.Z end
		if testPos.Z > maxZ then maxZ = testPos.Z end
	end
	minZ -= 80
	-- Cap maxZ so hallway doesn't overlap with the spawn room (room extends to Z=-60)
	maxZ = math.min(maxZ + 30, -65)

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

	local currentPos = Vector3.new(0, START_HEIGHT, -65) -- further out since spawn room is bigger
	local maxX = HALLWAY_WIDTH/2 - 12

	for i, level in ipairs(LEVELS) do
		local off = level.offset
		currentPos = currentPos + Vector3.new(off[1], off[2], off[3])
		if currentPos.Y < DEATH_Y+15 then currentPos = Vector3.new(currentPos.X, DEATH_Y+20, currentPos.Z) end
		if currentPos.Y > START_HEIGHT+30 then currentPos = Vector3.new(currentPos.X, START_HEIGHT, currentPos.Z) end
		currentPos = Vector3.new(math.clamp(currentPos.X, -maxX, maxX), currentPos.Y, currentPos.Z)

		local builder = BUILDERS[level.candy] or buildChocolateBar
		local walkable, mdl = builder(i, currentPos, level.size)

		local np = Instance.new("Part")
		np.Size = Vector3.new(1,1,1); np.Position = currentPos + Vector3.new(0,16,0)
		np.Anchored = true; np.Transparency = 1; np.CanCollide = false; np.Parent = mapFolder
		local ng = Instance.new("BillboardGui"); ng.Size = UDim2.fromOffset(60,40); ng.AlwaysOnTop = false; ng.Parent = np
		local nl = Instance.new("TextLabel"); nl.Size = UDim2.fromScale(1,1); nl.BackgroundTransparency = 1
		nl.Text = tostring(i); nl.TextColor3 = Color3.fromRGB(255,255,255)
		nl.TextTransparency = 0.3; nl.TextScaled = true; nl.Font = Enum.Font.FredokaOne; nl.Parent = ng
		local ns = Instance.new("UIStroke"); ns.Color = Color3.fromRGB(200,100,150); ns.Thickness = 2; ns.Parent = nl

		if level.moving then makeMoving(mdl) end
		if level.crumbling then makeCrumbling(mdl, walkable) end

		-- 40% chance: make this main block permeable (disappear/reappear)
		if not level.checkpoint and math.random() < 0.4 then
			makeCrumbling(mdl, walkable)
		end

		-- Spawn extra candy blocks for this level (multi-block paths)
		if level.extra then
			for ei, ex in ipairs(level.extra) do
				local exPos = currentPos + Vector3.new(ex[1], ex[2], ex[3])
				local exCandy = ex[4] or "chocolate"
				local exSize = ex[5] or 0.8
				local exBuilder = BUILDERS[exCandy] or buildChocolateBar
				local exWalkable, exMdl = exBuilder(i*100+ei, exPos, exSize)
				-- 40% of extra blocks are also permeable
				if math.random() < 0.4 then
					makeCrumbling(exMdl, exWalkable)
				end
			end
		end

		if level.checkpoint then
			checkpointPositions[i] = currentPos + Vector3.new(0,5,0)

			-- ============================================================
			-- CHECKPOINT PLATFORM: Large decorated candy spawn pad
			-- ============================================================

			-- Main platform (big, solid, safe landing)
			local cpBase = Instance.new("Part")
			cpBase.Name = "CheckpointBase_"..i
			cpBase.Size = Vector3.new(5, 40, 40)
			cpBase.Position = currentPos + Vector3.new(0, 0, 0)
			cpBase.Anchored = true; cpBase.Color = Color3.fromRGB(255, 220, 180)
			cpBase.Material = Enum.Material.SmoothPlastic
			cpBase.Shape = Enum.PartType.Cylinder
			cpBase.Orientation = Vector3.new(0,0,90)
			cpBase.TopSurface = Enum.SurfaceType.Smooth
			cpBase.BottomSurface = Enum.SurfaceType.Smooth
			cpBase.Parent = mapFolder

			-- Frosting top layer
			local cpFrost = Instance.new("Part")
			cpFrost.Size = Vector3.new(2.5, 38, 38)
			cpFrost.Position = currentPos + Vector3.new(0, 3, 0)
			cpFrost.Anchored = true; cpFrost.Color = Color3.fromRGB(255, 180, 220)
			cpFrost.Material = Enum.Material.SmoothPlastic
			cpFrost.Shape = Enum.PartType.Cylinder
			cpFrost.Orientation = Vector3.new(0,0,90)
			cpFrost.CanCollide = true; cpFrost.Parent = mapFolder

			-- Neon ring border
			local cpRing = Instance.new("Part")
			cpRing.Size = Vector3.new(1.5, 44, 44)
			cpRing.Position = currentPos + Vector3.new(0, -1, 0)
			cpRing.Anchored = true; cpRing.Color = Color3.fromRGB(100, 255, 150)
			cpRing.Material = Enum.Material.Neon
			cpRing.Shape = Enum.PartType.Cylinder
			cpRing.Orientation = Vector3.new(0,0,90)
			cpRing.Transparency = 0.2; cpRing.CanCollide = false
			cpRing.Parent = mapFolder

			-- Inner glow ring
			local cpGlow = Instance.new("Part")
			cpGlow.Size = Vector3.new(0.5, 30, 30)
			cpGlow.Position = currentPos + Vector3.new(0, 4, 0)
			cpGlow.Anchored = true; cpGlow.Color = Color3.fromRGB(255, 255, 200)
			cpGlow.Material = Enum.Material.Neon
			cpGlow.Shape = Enum.PartType.Cylinder
			cpGlow.Orientation = Vector3.new(0,0,90)
			cpGlow.Transparency = 0.5; cpGlow.CanCollide = false
			cpGlow.Parent = mapFolder

			-- Bright light
			local cpLight = Instance.new("PointLight")
			cpLight.Color = Color3.fromRGB(100, 255, 150)
			cpLight.Brightness = 3; cpLight.Range = 60
			cpLight.Parent = cpBase

			-- 4 candy cane pillars around the checkpoint
			for pi = 1, 4 do
				local angle = (pi/4)*math.pi*2
				local px = math.cos(angle)*18
				local pz = math.sin(angle)*18
				local pillar = Instance.new("Part")
				pillar.Size = Vector3.new(2, 20, 2)
				pillar.Position = currentPos + Vector3.new(px, 12, pz)
				pillar.Anchored = true; pillar.Color = Color3.fromRGB(255,30,30)
				pillar.Material = Enum.Material.SmoothPlastic; pillar.Parent = mapFolder

				local pStripe = Instance.new("Part")
				pStripe.Size = Vector3.new(1.5, 20.5, 1.5)
				pStripe.Position = currentPos + Vector3.new(px, 12, pz)
				pStripe.Anchored = true; pStripe.Color = Color3.fromRGB(255,255,255)
				pStripe.Transparency = 0.35; pStripe.CanCollide = false
				pStripe.Material = Enum.Material.SmoothPlastic; pStripe.Parent = mapFolder

				local topBall = Instance.new("Part")
				topBall.Size = Vector3.new(3,3,3)
				topBall.Position = currentPos + Vector3.new(px, 23, pz)
				topBall.Anchored = true; topBall.Color = Color3.fromRGB(100,255,150)
				topBall.Shape = Enum.PartType.Ball
				topBall.Material = Enum.Material.Neon
				topBall.CanCollide = false; topBall.Parent = mapFolder
			end

			-- Sprinkles on platform
			local sprCols = {Color3.fromRGB(255,80,80),Color3.fromRGB(80,255,80),Color3.fromRGB(80,80,255),Color3.fromRGB(255,255,80)}
			for si = 1, 20 do
				local sa = (si/20)*math.pi*2
				local sr = math.random(3, 16)
				local spr = Instance.new("Part")
				spr.Size = Vector3.new(0.4,0.4,1.4)
				spr.Position = currentPos + Vector3.new(math.cos(sa)*sr, 4.5, math.sin(sa)*sr)
				spr.Rotation = Vector3.new(0, math.random(0,360), 0)
				spr.Anchored = true; spr.CanCollide = false
				spr.Color = sprCols[math.random(1,#sprCols)]
				spr.Material = Enum.Material.SmoothPlastic
				spr.Parent = mapFolder
			end

			-- Checkpoint sign
			local cpSign = Instance.new("Part")
			cpSign.Size = Vector3.new(14, 5, 1.5)
			cpSign.Position = currentPos + Vector3.new(0, 26, -18)
			cpSign.Anchored = true; cpSign.Color = Color3.fromRGB(100,255,150)
			cpSign.Material = Enum.Material.Neon; cpSign.Parent = mapFolder
			local sGui = Instance.new("SurfaceGui"); sGui.Face = Enum.NormalId.Front; sGui.Parent = cpSign
			local sLbl = Instance.new("TextLabel"); sLbl.Size = UDim2.fromScale(1,1); sLbl.BackgroundTransparency = 1
			sLbl.Text = "✓ CHECKPOINT " .. i; sLbl.TextColor3 = Color3.fromRGB(255,255,255)
			sLbl.TextScaled = true; sLbl.Font = Enum.Font.FredokaOne; sLbl.Parent = sGui
			-- Back face too
			local sGui2 = Instance.new("SurfaceGui"); sGui2.Face = Enum.NormalId.Back; sGui2.Parent = cpSign
			local sLbl2 = Instance.new("TextLabel"); sLbl2.Size = UDim2.fromScale(1,1); sLbl2.BackgroundTransparency = 1
			sLbl2.Text = "✓ CHECKPOINT " .. i; sLbl2.TextColor3 = Color3.fromRGB(255,255,255)
			sLbl2.TextScaled = true; sLbl2.Font = Enum.Font.FredokaOne; sLbl2.Parent = sGui2

			-- Trigger zone (sets spawn point)
			local cpt = Instance.new("Part"); cpt.Size = Vector3.new(40,20,40)
			cpt.Position = currentPos + Vector3.new(0,10,0); cpt.Anchored = true
			cpt.Transparency = 1; cpt.CanCollide = false; cpt.Parent = mapFolder
			cpt.Touched:Connect(function(hit)
				local ch = hit.Parent; local plr = Players:GetPlayerFromCharacter(ch)
				if plr then
					local data = playerData[plr]
					if data and (not data.checkpoint or data.checkpoint < i) then data.checkpoint = i end
				end
			end)
		end

		if i % 3 == 0 then createCollectible(currentPos, i) end
	end

	-- ============================================================
	-- FINAL HALLWAY RUN (disappearing tiles before finish)
	-- ============================================================
	local hallwayStart = currentPos + Vector3.new(0, 0, -20)
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
