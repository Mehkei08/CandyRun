--[[
	CandyRun - BuildMap (Command Bar Script)
	Paste this into Roblox Studio's Command Bar and press Enter.
	It generates ALL static geometry once. Save the place file afterward.
	
	Run again to regenerate (it cleans up existing folders first).
]]

-- ============================================================
-- CONSTANTS (matching server script exactly)
-- ============================================================

local START_HEIGHT = 250
local HALLWAY_WIDTH = 140
local HALLWAY_HEIGHT = 130
local WALL_SEGMENT_LENGTH = 60
local DEATH_Y = 20
local BASE_Y = START_HEIGHT

local ROOM_W = 200
local ROOM_D = 120
local ROOM_H = 80

local PARKOUR_START_Z = -83

-- ============================================================
-- CANDY COLOR PALETTE
-- ============================================================

local CANDY_COLORS = {
	Color3.fromRGB(255,100,200),
	Color3.fromRGB(255,180,50),
	Color3.fromRGB(150,80,255),
	Color3.fromRGB(80,200,255),
	Color3.fromRGB(255,80,80),
	Color3.fromRGB(80,255,150),
	Color3.fromRGB(255,150,80),
	Color3.fromRGB(200,100,255),
}

-- ============================================================
-- PARKOUR STEPS (exact copy from server script)
-- ============================================================

local PARKOUR_STEPS = {
	{x=0,    y=0,   z=-90,    size=6.0},
	{x=0,    y=0,   z=-140,   size=5.5},
	{x=10,   y=0,   z=-190,   size=5.0},
	{x=-12,  y=1,   z=-240,   size=5.0},
	{x=14,   y=0,   z=-290,   size=4.5},
	{x=-10,  y=1,   z=-340,   size=5.0},
	{x=16,   y=0,   z=-395,   size=4.5},
	{x=-14,  y=2,   z=-450,   size=5.0},
	{x=8,    y=0,   z=-505,   size=4.5},
	{x=-10,  y=1,   z=-560,   size=5.5},
	{x=0,    y=0,   z=-620,   size=6.0, checkpoint=true},
	{x=18,   y=2,   z=-680,   size=5.0},
	{x=-22,  y=0,   z=-740,   size=4.5},
	{x=24,   y=1,   z=-800,   size=5.5},
	{x=-18,  y=2,   z=-860,   size=4.5},
	{x=22,   y=0,   z=-920,   size=5.0},
	{x=-24,  y=1,   z=-980,   size=5.5},
	{x=20,   y=2,   z=-1040,  size=4.5},
	{x=-16,  y=0,   z=-1100,  size=5.0},
	{x=18,   y=1,   z=-1160,  size=5.5},
	{x=0,    y=0,   z=-1225,  size=6.0, checkpoint=true},
	{x=-45,  y=1,   z=-1280,  size=5.0},
	{x=-50,  y=0,   z=-1335,  size=4.5},
	{x=-42,  y=2,   z=-1390,  size=5.5},
	{x=-48,  y=0,   z=-1445,  size=5.0},
	{x=-40,  y=1,   z=-1500,  size=4.5},
	{x=-45,  y=2,   z=-1555,  size=5.0},
	{x=0,    y=4,   z=-1285,  size=4.5},
	{x=8,    y=2,   z=-1340,  size=4.5},
	{x=-6,   y=5,   z=-1395,  size=5.0},
	{x=7,    y=3,   z=-1450,  size=4.5},
	{x=-5,   y=4,   z=-1505,  size=5.0},
	{x=6,    y=3,   z=-1560,  size=4.5},
	{x=45,   y=1,   z=-1280,  size=5.0},
	{x=50,   y=0,   z=-1335,  size=4.5},
	{x=42,   y=2,   z=-1390,  size=5.5},
	{x=48,   y=0,   z=-1445,  size=5.0},
	{x=40,   y=1,   z=-1500,  size=4.5},
	{x=45,   y=2,   z=-1555,  size=5.0},
	{x=-20,  y=1,   z=-1615,  size=5.0},
	{x=20,   y=1,   z=-1615,  size=5.0},
	{x=0,    y=0,   z=-1675,  size=6.0, checkpoint=true},
	{x=-40,  y=2,   z=-1735,  size=4.5, moving=true},
	{x=-46,  y=0,   z=-1795,  size=4.5},
	{x=-38,  y=3,   z=-1855,  size=5.0, moving=true},
	{x=-44,  y=1,   z=-1915,  size=4.5},
	{x=0,    y=4,   z=-1740,  size=4.5, moving=true},
	{x=8,    y=2,   z=-1800,  size=4.5},
	{x=-6,   y=5,   z=-1860,  size=5.0, moving=true},
	{x=5,    y=3,   z=-1920,  size=4.5},
	{x=40,   y=2,   z=-1735,  size=4.5, moving=true},
	{x=46,   y=0,   z=-1795,  size=4.5},
	{x=38,   y=3,   z=-1855,  size=5.0, moving=true},
	{x=44,   y=1,   z=-1915,  size=4.5},
	{x=-18,  y=1,   z=-1975,  size=5.0},
	{x=18,   y=1,   z=-1975,  size=5.0},
	{x=0,    y=0,   z=-2040,  size=6.0, checkpoint=true},
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

local function glow(part, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color or part.Color
	l.Range = range or 14
	l.Brightness = brightness or 0.5
	l.Parent = part
end

local function candyColor(index)
	return CANDY_COLORS[((index - 1) % #CANDY_COLORS) + 1]
end

-- ============================================================
-- CLEANUP EXISTING
-- ============================================================

print("[BuildMap] Cleaning up existing folders...")
for _, name in ipairs({"CandyMap", "Collectibles", "Hallway"}) do
	local existing = workspace:FindFirstChild(name)
	if existing then existing:Destroy() end
end
-- Clean up loose death floor parts
for _, child in workspace:GetChildren() do
	if child.Name == "DeathFloor" or (child:IsA("BasePart") and child.Position.Y < DEATH_Y + 10 and child.Position.Y > DEATH_Y - 25) then
		if child:IsA("BasePart") and child.Material == Enum.Material.Neon and child.Color.R > 0.7 then
			child:Destroy()
		end
	end
end
local existingDeath = workspace:FindFirstChild("DeathFloor")
if existingDeath then existingDeath:Destroy() end

task.wait()

-- ============================================================
-- CREATE FOLDERS
-- ============================================================

local mapFolder = Instance.new("Folder"); mapFolder.Name = "CandyMap"; mapFolder.Parent = workspace
local collectiblesFolder = Instance.new("Folder"); collectiblesFolder.Name = "Collectibles"; collectiblesFolder.Parent = workspace
local hallwayFolder = Instance.new("Folder"); hallwayFolder.Name = "Hallway"; hallwayFolder.Parent = workspace

print("[BuildMap] Folders created.")

-- ============================================================
-- BUILD SPAWN ROOM
-- ============================================================

print("[BuildMap] Building spawn room...")

local spawnRoom = Instance.new("Model"); spawnRoom.Name = "SpawnRoom"

local floorY = START_HEIGHT
local tileSize = 10

-- Floor (checkerboard)
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
		tile.Parent = spawnRoom
	end
end

-- Walls
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
backWall.Material = Enum.Material.SmoothPlastic; backWall.Parent = spawnRoom

-- Left wall (-X)
local leftWall = Instance.new("Part")
leftWall.Size = Vector3.new(wallThickness, ROOM_H, ROOM_D+wallThickness*2)
leftWall.Position = Vector3.new(-ROOM_W/2-wallThickness/2, floorY+ROOM_H/2, 0)
leftWall.Anchored = true; leftWall.Color = wallColors[2]
leftWall.Material = Enum.Material.SmoothPlastic; leftWall.Parent = spawnRoom

-- Right wall (+X)
local rightWall = Instance.new("Part")
rightWall.Size = Vector3.new(wallThickness, ROOM_H, ROOM_D+wallThickness*2)
rightWall.Position = Vector3.new(ROOM_W/2+wallThickness/2, floorY+ROOM_H/2, 0)
rightWall.Anchored = true; rightWall.Color = wallColors[3]
rightWall.Material = Enum.Material.SmoothPlastic; rightWall.Parent = spawnRoom

-- Front wall (-Z) with door opening
local doorW = 30
local frontWallL = Instance.new("Part")
frontWallL.Size = Vector3.new((ROOM_W-doorW)/2+wallThickness, ROOM_H, wallThickness)
frontWallL.Position = Vector3.new(-(doorW/2 + frontWallL.Size.X/2) + wallThickness/2, floorY+ROOM_H/2, -ROOM_D/2-wallThickness/2)
frontWallL.Anchored = true; frontWallL.Color = wallColors[4]
frontWallL.Material = Enum.Material.SmoothPlastic; frontWallL.Parent = spawnRoom

local frontWallR = Instance.new("Part")
frontWallR.Size = Vector3.new((ROOM_W-doorW)/2+wallThickness, ROOM_H, wallThickness)
frontWallR.Position = Vector3.new((doorW/2 + frontWallR.Size.X/2) - wallThickness/2, floorY+ROOM_H/2, -ROOM_D/2-wallThickness/2)
frontWallR.Anchored = true; frontWallR.Color = wallColors[4]
frontWallR.Material = Enum.Material.SmoothPlastic; frontWallR.Parent = spawnRoom

-- Door arch
local archTop = Instance.new("Part")
archTop.Size = Vector3.new(doorW+4, 8, wallThickness+2)
archTop.Position = Vector3.new(0, floorY+ROOM_H-4, -ROOM_D/2-wallThickness/2)
archTop.Anchored = true; archTop.Color = Color3.fromRGB(255,100,150)
archTop.Material = Enum.Material.Neon; archTop.Transparency = 0.2
archTop.CanCollide = false; archTop.Parent = spawnRoom

-- Ceiling (checkerboard)
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
		ct.Parent = spawnRoom
	end
end

-- Candy cane pillars along walls
for i = 1, 10 do
	for _, side in ipairs({-1, 1}) do
		local px = side * (ROOM_W/2 - 3)
		local pz = -ROOM_D/2 + i * (ROOM_D / 11)
		local pillar = Instance.new("Part")
		pillar.Size = Vector3.new(3, ROOM_H-5, 3)
		pillar.Position = Vector3.new(px, floorY+ROOM_H/2, pz)
		pillar.Anchored = true; pillar.Color = Color3.fromRGB(255,30,30)
		pillar.Material = Enum.Material.SmoothPlastic; pillar.Parent = spawnRoom

		local pStripe = Instance.new("Part")
		pStripe.Size = Vector3.new(2.5, ROOM_H-4, 2.5)
		pStripe.Position = Vector3.new(px, floorY+ROOM_H/2, pz)
		pStripe.Anchored = true; pStripe.Color = Color3.fromRGB(255,255,255)
		pStripe.Transparency = 0.35; pStripe.CanCollide = false
		pStripe.Material = Enum.Material.SmoothPlastic; pStripe.Parent = spawnRoom

		local topBall = Instance.new("Part")
		topBall.Size = Vector3.new(4,4,4)
		topBall.Position = Vector3.new(px, floorY+ROOM_H-3, pz)
		topBall.Anchored = true; topBall.Color = Color3.fromRGB(255,30,30)
		topBall.Shape = Enum.PartType.Ball; topBall.Material = Enum.Material.SmoothPlastic
		topBall.CanCollide = false; topBall.Parent = spawnRoom
	end
end

-- Sprinkles on floor
local sprColors = {Color3.fromRGB(255,80,80),Color3.fromRGB(80,255,80),Color3.fromRGB(80,80,255),Color3.fromRGB(255,255,80),Color3.fromRGB(255,80,255)}
for i = 1, 80 do
	local spr = Instance.new("Part")
	spr.Size = Vector3.new(0.5,0.5,1.6)
	spr.Position = Vector3.new(math.random(-85,85), floorY+2, math.random(-50,50))
	spr.Rotation = Vector3.new(0, math.random(0,360), 0)
	spr.Anchored = true; spr.CanCollide = false
	spr.Color = sprColors[math.random(1,#sprColors)]
	spr.Material = Enum.Material.SmoothPlastic
	spr.Parent = spawnRoom
end

-- Neon accent strips along floor edges
for _, side in ipairs({-1, 1}) do
	local strip = Instance.new("Part")
	strip.Size = Vector3.new(ROOM_W, 0.5, 1)
	strip.Position = Vector3.new(0, floorY+1.8, side*ROOM_D/2)
	strip.Anchored = true; strip.Color = Color3.fromRGB(200,130,255)
	strip.Material = Enum.Material.Neon; strip.Transparency = 0.3
	strip.CanCollide = false; strip.Parent = spawnRoom

	local strip2 = Instance.new("Part")
	strip2.Size = Vector3.new(1, 0.5, ROOM_D)
	strip2.Position = Vector3.new(side*ROOM_W/2, floorY+1.8, 0)
	strip2.Anchored = true; strip2.Color = Color3.fromRGB(200,130,255)
	strip2.Material = Enum.Material.Neon; strip2.Transparency = 0.3
	strip2.CanCollide = false; strip2.Parent = spawnRoom
end

-- "CANDY RUN" sign above door
local sign = Instance.new("Part")
sign.Size = Vector3.new(30, 7, 2)
sign.Position = Vector3.new(0, floorY+ROOM_H-10, -ROOM_D/2)
sign.Anchored = true; sign.Color = Color3.fromRGB(255,100,150)
sign.Material = Enum.Material.Neon; sign.Parent = spawnRoom

local sGui = Instance.new("SurfaceGui"); sGui.Face = Enum.NormalId.Back; sGui.Parent = sign
local sT = Instance.new("TextLabel")
sT.Size = UDim2.fromScale(1,1); sT.BackgroundTransparency = 1
sT.Text = "🍬 CANDY RUN 🍬"; sT.TextColor3 = Color3.fromRGB(255,255,255)
sT.TextScaled = true; sT.Font = Enum.Font.FredokaOne; sT.Parent = sGui

local sGui2 = Instance.new("SurfaceGui"); sGui2.Face = Enum.NormalId.Front; sGui2.Parent = sign
local sT2 = Instance.new("TextLabel")
sT2.Size = UDim2.fromScale(1,1); sT2.BackgroundTransparency = 1
sT2.Text = "🍬 CANDY RUN 🍬"; sT2.TextColor3 = Color3.fromRGB(255,255,255)
sT2.TextScaled = true; sT2.Font = Enum.Font.FredokaOne; sT2.Parent = sGui2

-- Ceiling lights
for i = 1, 8 do
	local lz = -ROOM_D/2 + i * (ROOM_D / 9)
	local rod = Instance.new("Part")
	rod.Size = Vector3.new(0.5, 8, 0.5)
	rod.Position = Vector3.new(0, ceilY-4, lz)
	rod.Anchored = true; rod.Color = Color3.fromRGB(240,230,200)
	rod.Material = Enum.Material.SmoothPlastic; rod.CanCollide = false
	rod.Parent = spawnRoom

	local lamp = Instance.new("Part")
	lamp.Size = Vector3.new(3, 8, 8)
	lamp.Position = Vector3.new(0, ceilY-10, lz)
	lamp.Anchored = true; lamp.Color = Color3.fromRGB(255,200,230)
	lamp.Material = Enum.Material.Neon; lamp.Shape = Enum.PartType.Cylinder
	lamp.Orientation = Vector3.new(0,0,90)
	lamp.CanCollide = false; lamp.Transparency = 0.1
	lamp.Parent = spawnRoom

	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255,220,240); pl.Brightness = 1.5; pl.Range = 40
	pl.Parent = lamp
end

spawnRoom.Parent = mapFolder

-- SpawnLocation
local spawn = Instance.new("SpawnLocation")
spawn.Name = "MainSpawn"; spawn.Size = Vector3.new(12,1,12)
spawn.Position = Vector3.new(0, floorY+3, 20)
spawn.Anchored = true; spawn.Transparency = 1
spawn.CanCollide = false; spawn.Neutral = true
spawn.Parent = mapFolder

print("[BuildMap] Spawn room done.")

-- ============================================================
-- BUILD ITEM CAPSULES
-- ============================================================

print("[BuildMap] Building item capsules...")

local ITEM_CAPSULES = {
	{name="Speed Coil",   color=Color3.fromRGB(80,200,255),  emoji="⚡", pos=Vector3.new(-60, floorY+8, -30)},
	{name="Gravity Coil", color=Color3.fromRGB(180,80,255),  emoji="🌀", pos=Vector3.new(-30, floorY+8, -30)},
	{name="Fusion Coil",  color=Color3.fromRGB(100,220,255), emoji="💫", pos=Vector3.new(0,   floorY+8, -30)},
	{name="Magic Carpet",  color=Color3.fromRGB(255,100,100), emoji="🧞", pos=Vector3.new(30,  floorY+8, -30)},
	{name="Grapple Gun",  color=Color3.fromRGB(255,200,50),  emoji="🪝", pos=Vector3.new(60,  floorY+8, -30)},
}

for _, item in ipairs(ITEM_CAPSULES) do
	local model = Instance.new("Model"); model.Name = item.name.."Capsule"
	local position = item.pos

	-- Glass cylinder capsule
	local capsule = Instance.new("Part")
	capsule.Name = "CapsuleShell"
	capsule.Size = Vector3.new(10, 14, 10)
	capsule.Position = position
	capsule.Anchored = true; capsule.Color = item.color
	capsule.Material = Enum.Material.Glass
	capsule.Shape = Enum.PartType.Cylinder
	capsule.Orientation = Vector3.new(0, 0, 90)
	capsule.Transparency = 0.55
	capsule.CanCollide = false
	capsule.Parent = model

	-- Base pedestal
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
	baseAccent.Anchored = true; baseAccent.Color = item.color
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

	-- Display item inside (colored sphere + cylinder decoration)
	local displayBall = Instance.new("Part")
	displayBall.Name = "DisplayItem"
	displayBall.Size = Vector3.new(4, 4, 4)
	displayBall.Position = position
	displayBall.Anchored = true; displayBall.CanCollide = false
	displayBall.Color = item.color
	displayBall.Material = Enum.Material.Neon
	displayBall.Shape = Enum.PartType.Ball
	displayBall.Parent = model
	glow(displayBall, item.color, 15, 1.5)

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
	lbl.Text = item.emoji.." "..item.name
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.TextScaled = true; lbl.Font = Enum.Font.FredokaOne; lbl.Parent = bb

	local stroke = Instance.new("UIStroke")
	stroke.Color = item.color; stroke.Thickness = 2; stroke.Parent = lbl

	-- Trigger zone
	local trigger = Instance.new("Part")
	trigger.Name = "Trigger_"..item.name
	trigger.Size = Vector3.new(14, 20, 14)
	trigger.Position = position + Vector3.new(0, -3, 0)
	trigger.Anchored = true; trigger.Transparency = 1; trigger.CanCollide = false
	trigger.Parent = model

	model.Parent = mapFolder
end

print("[BuildMap] Item capsules done.")

-- ============================================================
-- BUILD TRAIL CHESTS
-- ============================================================

print("[BuildMap] Building trail chests...")

local function buildTrailChest(position, name, labelText, promptAction, promptObject)
	local chestModel = Instance.new("Model"); chestModel.Name = name

	local base = Instance.new("Part")
	base.Name = "ChestBase"
	base.Size = Vector3.new(6, 4, 5)
	base.Position = position; base.Anchored = true
	base.Color = if name == "PremiumTrailChest" then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(160, 100, 40)
	base.Material = if name == "PremiumTrailChest" then Enum.Material.Neon else Enum.Material.SmoothPlastic
	base.Parent = chestModel

	local lid = Instance.new("Part")
	lid.Size = Vector3.new(6.2, 3, 5.2)
	lid.Position = position + Vector3.new(0, 3.5, 0)
	lid.Anchored = true
	lid.Color = if name == "PremiumTrailChest" then Color3.fromRGB(255, 200, 0) else Color3.fromRGB(180, 120, 50)
	lid.Material = if name == "PremiumTrailChest" then Enum.Material.Neon else Enum.Material.SmoothPlastic
	lid.Shape = Enum.PartType.Ball; lid.Parent = chestModel

	local trim = Instance.new("Part")
	trim.Size = Vector3.new(6.4, 0.5, 5.4)
	trim.Position = position + Vector3.new(0, 2, 0)
	trim.Anchored = true
	trim.Color = if name == "PremiumTrailChest" then Color3.fromRGB(255, 255, 150) else Color3.fromRGB(255, 215, 0)
	trim.Material = Enum.Material.Neon; trim.CanCollide = false; trim.Parent = chestModel

	local lock = Instance.new("Part")
	lock.Size = Vector3.new(1.2, 1.2, 0.5)
	lock.Position = position + Vector3.new(0, 2, -2.8)
	lock.Anchored = true
	lock.Color = if name == "PremiumTrailChest" then Color3.fromRGB(150, 255, 255) else Color3.fromRGB(255, 215, 0)
	lock.Material = if name == "PremiumTrailChest" then Enum.Material.Neon else Enum.Material.Metal
	lock.Shape = Enum.PartType.Ball
	lock.CanCollide = false; lock.Parent = chestModel

	local gl = Instance.new("PointLight")
	gl.Color = Color3.fromRGB(255, 200, 50)
	gl.Brightness = if name == "PremiumTrailChest" then 2.5 else 1.5
	gl.Range = if name == "PremiumTrailChest" then 25 else 20
	gl.Parent = base

	-- Label
	local labelP = Instance.new("Part")
	labelP.Size = Vector3.new(1,1,1); labelP.Position = position + Vector3.new(0, 8, 0)
	labelP.Anchored = true; labelP.Transparency = 1; labelP.CanCollide = false; labelP.Parent = chestModel
	local bbg = Instance.new("BillboardGui")
	bbg.Size = UDim2.fromOffset(200, 60); bbg.AlwaysOnTop = false; bbg.Parent = labelP
	local lblt = Instance.new("TextLabel")
	lblt.Size = UDim2.fromScale(1,1); lblt.BackgroundTransparency = 1
	lblt.Text = labelText
	lblt.TextColor3 = Color3.fromRGB(255, 220, 80)
	lblt.TextScaled = true; lblt.Font = Enum.Font.FredokaOne; lblt.Parent = bbg
	Instance.new("UIStroke", lblt).Color = if name == "PremiumTrailChest" then Color3.fromRGB(200, 160, 20) else Color3.fromRGB(160, 100, 20)

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = promptAction
	prompt.ObjectText = promptObject
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = base

	chestModel.Parent = mapFolder
end

buildTrailChest(
	Vector3.new(-40, floorY + 4, -15),
	"TrailChest",
	"🎁 Trail Chest - 10 🍬",
	"Open",
	"Trail Chest (10 🍬)"
)

buildTrailChest(
	Vector3.new(-40, floorY + 4, 15),
	"PremiumTrailChest",
	"👑 Premium Chest - R$29",
	"Buy",
	"Premium Trail Chest (R$29)"
)

print("[BuildMap] Trail chests done.")

-- ============================================================
-- BUILD LEADERBOARD PLACEHOLDER
-- ============================================================

print("[BuildMap] Building leaderboard placeholder...")

local lbSign = Instance.new("Part")
lbSign.Name = "LeaderboardSign"
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

local lbGlow = Instance.new("PointLight")
lbGlow.Color = Color3.fromRGB(255, 200, 80); lbGlow.Brightness = 1; lbGlow.Range = 20
lbGlow.Parent = lbSign

print("[BuildMap] Leaderboard done.")

-- ============================================================
-- BUILD PARKOUR PLATFORMS
-- ============================================================

print("[BuildMap] Building parkour platforms...")

local checkpointCount = 0
local lastStepPos = Vector3.new(0, BASE_Y, PARKOUR_START_Z)

for i, step in ipairs(PARKOUR_STEPS) do
	local stepCenter = Vector3.new(step.x, BASE_Y + (step.y or 0), step.z)
	local color = candyColor(i)
	local secondaryColor = candyColor(i + 3)
	local scale = step.size or 5.0

	local model = Instance.new("Model")
	model.Name = "CandyPlatform_" .. i

	-- Main walkable ball
	local main = Instance.new("Part")
	main.Name = "Walkable"
	main.Size = Vector3.new(14, 14, 14) * (scale / 5.0)
	main.Position = stepCenter
	main.Anchored = true
	main.Color = color
	main.Material = Enum.Material.SmoothPlastic
	main.Shape = Enum.PartType.Ball
	main.TopSurface = Enum.SurfaceType.Smooth
	main.BottomSurface = Enum.SurfaceType.Smooth
	main.Parent = model
	glow(main, color, 22, 0.5)

	-- Decorative smaller sphere on top
	local topDeco = Instance.new("Part")
	topDeco.Name = "TopDecoration"
	topDeco.Size = Vector3.new(5, 5, 5) * (scale / 5.0)
	topDeco.Position = stepCenter + Vector3.new(0, 7 * (scale / 5.0), 0)
	topDeco.Anchored = true
	topDeco.Color = secondaryColor
	topDeco.Material = Enum.Material.Neon
	topDeco.Shape = Enum.PartType.Ball
	topDeco.CanCollide = false
	topDeco.Transparency = 0.3
	topDeco.Parent = model

	-- Decorative cylinder ring around the middle
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Size = Vector3.new(2, 16, 16) * (scale / 5.0)
	ring.Position = stepCenter
	ring.Anchored = true
	ring.Color = Color3.fromRGB(255, 255, 255)
	ring.Material = Enum.Material.SmoothPlastic
	ring.Shape = Enum.PartType.Cylinder
	ring.Orientation = Vector3.new(0, 0, 90)
	ring.CanCollide = false
	ring.Transparency = 0.6
	ring.Parent = model

	-- Tag moving platforms
	if step.moving then
		local isMoving = Instance.new("BoolValue")
		isMoving.Name = "IsMoving"
		isMoving.Value = true
		isMoving.Parent = model
	end

	-- Tag checkpoints
	if step.checkpoint then
		checkpointCount = checkpointCount + 1

		local isCp = Instance.new("BoolValue")
		isCp.Name = "IsCheckpoint"
		isCp.Value = true
		isCp.Parent = model

		local cpIdx = Instance.new("IntValue")
		cpIdx.Name = "CheckpointIndex"
		cpIdx.Value = checkpointCount
		cpIdx.Parent = model

		-- Green glow on checkpoint
		local cpLight = Instance.new("PointLight")
		cpLight.Color = Color3.fromRGB(80, 255, 130)
		cpLight.Brightness = 2.5; cpLight.Range = 45
		cpLight.Parent = main

		-- Checkpoint sign floating above
		local cpSign = Instance.new("Part")
		cpSign.Name = "CheckpointSign"
		cpSign.Size = Vector3.new(14, 5, 1.5)
		cpSign.Position = stepCenter + Vector3.new(0, 22, 0)
		cpSign.Anchored = true; cpSign.Color = Color3.fromRGB(60,150,90)
		cpSign.Material = Enum.Material.Neon; cpSign.Parent = model

		local csGui = Instance.new("SurfaceGui"); csGui.Face = Enum.NormalId.Front; csGui.Parent = cpSign
		local csLbl = Instance.new("TextLabel"); csLbl.Size = UDim2.fromScale(1,1); csLbl.BackgroundTransparency = 1
		csLbl.Text = "✓ CHECKPOINT " .. checkpointCount; csLbl.TextColor3 = Color3.fromRGB(255,255,255)
		csLbl.TextScaled = true; csLbl.Font = Enum.Font.FredokaOne; csLbl.Parent = csGui
		local csGui2 = Instance.new("SurfaceGui"); csGui2.Face = Enum.NormalId.Back; csGui2.Parent = cpSign
		local csLbl2 = csLbl:Clone(); csLbl2.Parent = csGui2

		-- Checkpoint trigger zone
		local cpt = Instance.new("Part")
		cpt.Name = "CheckpointTrigger"
		cpt.Size = Vector3.new(30,20,30)
		cpt.Position = stepCenter + Vector3.new(0,10,0)
		cpt.Anchored = true; cpt.Transparency = 1; cpt.CanCollide = false
		cpt.Parent = model
	end

	-- Step number label
	local np = Instance.new("Part")
	np.Name = "StepLabel"
	np.Size = Vector3.new(1,1,1); np.Position = stepCenter + Vector3.new(0,14,0)
	np.Anchored = true; np.Transparency = 1; np.CanCollide = false; np.Parent = model
	local ng = Instance.new("BillboardGui"); ng.Size = UDim2.fromOffset(50,35); ng.AlwaysOnTop = false; ng.Parent = np
	local nl = Instance.new("TextLabel"); nl.Size = UDim2.fromScale(1,1); nl.BackgroundTransparency = 1
	nl.Text = tostring(i); nl.TextColor3 = Color3.fromRGB(255,255,255)
	nl.TextTransparency = 0.4; nl.TextScaled = true; nl.Font = Enum.Font.FredokaOne; nl.Parent = ng
	local ns = Instance.new("UIStroke"); ns.Color = Color3.fromRGB(200,100,150); ns.Thickness = 2; ns.Parent = nl

	model.Parent = mapFolder
	lastStepPos = stepCenter

	if i % 10 == 0 then
		print("[BuildMap] Placed " .. i .. "/" .. #PARKOUR_STEPS .. " platforms...")
	end
end

print("[BuildMap] All " .. #PARKOUR_STEPS .. " platforms placed. " .. checkpointCount .. " checkpoints.")

-- ============================================================
-- BUILD COLLECTIBLES (every 5 steps, not on checkpoints)
-- ============================================================

print("[BuildMap] Building collectibles...")

local collectibleCount = 0
for i, step in ipairs(PARKOUR_STEPS) do
	if i % 5 == 0 and not step.checkpoint then
		collectibleCount = collectibleCount + 1
		local stepCenter = Vector3.new(step.x, BASE_Y + (step.y or 0), step.z)
		local pos = stepCenter + Vector3.new(0, 8, 0)

		local model = Instance.new("Model")
		model.Name = "SpeedCandy_" .. i

		-- Glowing candy sphere
		local sphere = Instance.new("Part")
		sphere.Name = "CandyBody"
		sphere.Size = Vector3.new(3, 3, 3)
		sphere.Position = pos; sphere.Anchored = true; sphere.CanCollide = false
		sphere.Color = Color3.fromRGB(255, 200, 50)
		sphere.Material = Enum.Material.Neon
		sphere.Shape = Enum.PartType.Ball
		sphere.Parent = model

		-- Glow light
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 220, 80)
		light.Brightness = 1.5; light.Range = 14
		light.Parent = sphere

		-- Collect trigger
		local touchPart = Instance.new("Part")
		touchPart.Name = "CollectTrigger"
		touchPart.Size = Vector3.new(6, 6, 6)
		touchPart.Position = pos
		touchPart.Anchored = true; touchPart.Transparency = 1; touchPart.CanCollide = false
		touchPart.Parent = model

		model.Parent = collectiblesFolder
	end
end

print("[BuildMap] " .. collectibleCount .. " collectibles placed.")

-- ============================================================
-- BUILD FINISH LINE
-- ============================================================

print("[BuildMap] Building finish line...")

local finishZ = lastStepPos.Z - 30
local finishY = BASE_Y

local finishArchL = Instance.new("Part")
finishArchL.Name = "FinishArchLeft"
finishArchL.Size = Vector3.new(4, 40, 4)
finishArchL.Position = Vector3.new(-20, finishY + 20, finishZ)
finishArchL.Anchored = true; finishArchL.Color = Color3.fromRGB(255, 215, 0)
finishArchL.Material = Enum.Material.Neon; finishArchL.Parent = mapFolder

local finishArchR = Instance.new("Part")
finishArchR.Name = "FinishArchRight"
finishArchR.Size = Vector3.new(4, 40, 4)
finishArchR.Position = Vector3.new(20, finishY + 20, finishZ)
finishArchR.Anchored = true; finishArchR.Color = Color3.fromRGB(255, 215, 0)
finishArchR.Material = Enum.Material.Neon; finishArchR.Parent = mapFolder

local finishArchTop = Instance.new("Part")
finishArchTop.Name = "FinishArchTop"
finishArchTop.Size = Vector3.new(44, 4, 4)
finishArchTop.Position = Vector3.new(0, finishY + 41, finishZ)
finishArchTop.Anchored = true; finishArchTop.Color = Color3.fromRGB(255, 215, 0)
finishArchTop.Material = Enum.Material.Neon; finishArchTop.Parent = mapFolder

-- FINISH sign
local finishSign = Instance.new("Part")
finishSign.Name = "FinishSign"
finishSign.Size = Vector3.new(30, 8, 1)
finishSign.Position = Vector3.new(0, finishY + 35, finishZ - 2)
finishSign.Anchored = true; finishSign.Color = Color3.fromRGB(255, 50, 50)
finishSign.Material = Enum.Material.Neon; finishSign.Parent = mapFolder

local fGui = Instance.new("SurfaceGui"); fGui.Face = Enum.NormalId.Front; fGui.Parent = finishSign
local fLbl = Instance.new("TextLabel"); fLbl.Size = UDim2.fromScale(1,1); fLbl.BackgroundTransparency = 1
fLbl.Text = "🏆 FINISH 🏆"; fLbl.TextColor3 = Color3.fromRGB(255,255,255)
fLbl.TextScaled = true; fLbl.Font = Enum.Font.FredokaOne; fLbl.Parent = fGui
local fGui2 = Instance.new("SurfaceGui"); fGui2.Face = Enum.NormalId.Back; fGui2.Parent = finishSign
local fLbl2 = fLbl:Clone(); fLbl2.Parent = fGui2

-- Goal platform
local goalModel = Instance.new("Model")
goalModel.Name = "GoalPlatform"
local goalBall = Instance.new("Part")
goalBall.Name = "Walkable"
goalBall.Size = Vector3.new(42, 42, 42)
goalBall.Position = Vector3.new(0, finishY, finishZ - 15)
goalBall.Anchored = true; goalBall.Color = Color3.fromRGB(255, 215, 0)
goalBall.Material = Enum.Material.SmoothPlastic
goalBall.Shape = Enum.PartType.Ball
goalBall.Parent = goalModel

local goalLight = Instance.new("PointLight")
goalLight.Color = Color3.fromRGB(255, 215, 0)
goalLight.Brightness = 3; goalLight.Range = 50
goalLight.Parent = goalBall

goalModel.Parent = mapFolder

-- Victory zone
local vz = Instance.new("Part"); vz.Name = "VictoryZone"
vz.Size = Vector3.new(50, 30, 50)
vz.Position = Vector3.new(0, finishY + 15, finishZ - 15)
vz.Anchored = true; vz.Transparency = 1; vz.CanCollide = false; vz.Parent = mapFolder

print("[BuildMap] Finish line done.")

-- ============================================================
-- BUILD HALLWAY
-- ============================================================

print("[BuildMap] Building hallway...")

local minPieceZ = PARKOUR_START_Z
for _, step in ipairs(PARKOUR_STEPS) do
	if step.z < minPieceZ then minPieceZ = step.z end
end
local minZ = minPieceZ - 400
local maxZ = math.min(PARKOUR_START_Z + 30, -65)
local totalLen = maxZ - minZ
local numSeg = math.ceil(totalLen / WALL_SEGMENT_LENGTH)
local halfW = HALLWAY_WIDTH / 2

local hallwayWallColors = {
	Color3.fromRGB(255,180,210), Color3.fromRGB(220,170,255),
	Color3.fromRGB(180,220,255), Color3.fromRGB(255,220,180),
	Color3.fromRGB(200,255,210),
}

for seg = 0, numSeg do
	local segZ = maxZ - seg * WALL_SEGMENT_LENGTH
	local color = hallwayWallColors[(seg % #hallwayWallColors) + 1]

	-- Opaque walls
	for _, side in ipairs({-1, 1}) do
		local wall = Instance.new("Part")
		wall.Size = Vector3.new(4, HALLWAY_HEIGHT*3, WALL_SEGMENT_LENGTH+2)
		wall.Position = Vector3.new(side*halfW, START_HEIGHT-20, segZ-WALL_SEGMENT_LENGTH/2)
		wall.Anchored = true; wall.Color = color
		wall.Material = Enum.Material.SmoothPlastic
		wall.Transparency = 0
		wall.Parent = hallwayFolder

		-- Candy stripe decoration
		local stripe = Instance.new("Part")
		stripe.Size = Vector3.new(1.5, 5, WALL_SEGMENT_LENGTH+2)
		stripe.Position = Vector3.new(side*(halfW-2), START_HEIGHT + (seg*4)%25, segZ-WALL_SEGMENT_LENGTH/2)
		stripe.Anchored = true; stripe.Color = Color3.fromRGB(255,255,255)
		stripe.Material = Enum.Material.SmoothPlastic
		stripe.Transparency = 0.3; stripe.CanCollide = false
		stripe.Parent = hallwayFolder

		local stripe2 = Instance.new("Part")
		stripe2.Size = Vector3.new(1, 3, WALL_SEGMENT_LENGTH+2)
		stripe2.Position = Vector3.new(side*(halfW-2), START_HEIGHT + (seg*4+12)%25, segZ-WALL_SEGMENT_LENGTH/2)
		stripe2.Anchored = true; stripe2.Color = Color3.fromRGB(255,200,220)
		stripe2.Material = Enum.Material.SmoothPlastic
		stripe2.Transparency = 0.4; stripe2.CanCollide = false
		stripe2.Parent = hallwayFolder
	end

	-- Ceiling: candy checkerboard
	local hallCeilY = START_HEIGHT + HALLWAY_HEIGHT
	local tilesPerRow = math.ceil(HALLWAY_WIDTH / 10)
	for tx = 0, tilesPerRow - 1 do
		local tileX = -halfW + tx*10 + 5
		local tileColor = if (seg+tx)%2==0 then Color3.fromRGB(255,180,210) else Color3.fromRGB(255,255,255)
		local tile = Instance.new("Part")
		tile.Size = Vector3.new(10.1, 2, WALL_SEGMENT_LENGTH+0.1)
		tile.Position = Vector3.new(tileX, hallCeilY, segZ-WALL_SEGMENT_LENGTH/2)
		tile.Anchored = true; tile.Color = tileColor
		tile.Material = Enum.Material.SmoothPlastic
		tile.TopSurface = Enum.SurfaceType.Smooth
		tile.BottomSurface = Enum.SurfaceType.Smooth
		tile.Parent = hallwayFolder
	end

	-- Ceiling lights
	local ls = Instance.new("Part")
	ls.Size = Vector3.new(0.8,12,0.8)
	ls.Position = Vector3.new(0, hallCeilY-6, segZ-WALL_SEGMENT_LENGTH/2)
	ls.Anchored = true; ls.Color = Color3.fromRGB(240,230,200)
	ls.Material = Enum.Material.SmoothPlastic; ls.CanCollide = false
	ls.Parent = hallwayFolder

	local lt = Instance.new("Part")
	lt.Size = Vector3.new(3, 8, 8)
	lt.Position = Vector3.new(0, hallCeilY-14, segZ-WALL_SEGMENT_LENGTH/2)
	lt.Anchored = true; lt.Color = hallwayWallColors[(seg % #hallwayWallColors) + 1]
	lt.Material = Enum.Material.Neon; lt.Shape = Enum.PartType.Cylinder
	lt.Orientation = Vector3.new(0,0,90)
	lt.CanCollide = false; lt.Transparency = 0.1
	lt.Parent = hallwayFolder

	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255,220,240); pl.Brightness = 2; pl.Range = 50
	pl.Parent = lt

	-- Wall candy canes every 3 segments
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

	if seg % 10 == 0 then
		print("[BuildMap] Hallway segment " .. seg .. "/" .. numSeg)
	end
end

print("[BuildMap] Hallway done.")

-- ============================================================
-- BUILD DEATH FLOOR
-- ============================================================

print("[BuildMap] Building death floor...")

local df = Instance.new("Part")
df.Name = "DeathFloor"
df.Size = Vector3.new(HALLWAY_WIDTH+20, 8, 3000)
df.Position = Vector3.new(0, DEATH_Y, -700)
df.Anchored = true; df.Color = Color3.fromRGB(200,20,20)
df.Material = Enum.Material.Neon; df.Transparency = 0.1
df.CanCollide = false; df.Parent = mapFolder

-- Backup kill part
local bk = Instance.new("Part")
bk.Name = "DeathFloorBackup"
bk.Size = Vector3.new(2000,1,3000); bk.Position = Vector3.new(0,DEATH_Y-20,-700)
bk.Anchored = true; bk.Transparency = 1; bk.CanCollide = false; bk.Parent = mapFolder

-- Scattered neon debris
for i = 1, 35 do
	local p = Instance.new("Part")
	p.Name = "DeathDebris_" .. i
	p.Size = Vector3.new(math.random(12,35), 1.5, math.random(12,35))
	p.Position = Vector3.new(math.random(-40,40), DEATH_Y+4.5, math.random(-1600,100))
	p.Anchored = true; p.Color = Color3.fromRGB(255, math.random(30,80), math.random(20,50))
	p.Material = Enum.Material.Neon; p.Transparency = 0.25; p.CanCollide = false
	p.Parent = mapFolder
end

print("[BuildMap] Death floor done.")

-- ============================================================
-- DONE!
-- ============================================================

print("============================================")
print("[BuildMap] ✅ BUILD COMPLETE!")
print("[BuildMap] Folders created:")
print("[BuildMap]   - CandyMap (" .. #mapFolder:GetChildren() .. " objects)")
print("[BuildMap]   - Collectibles (" .. #collectiblesFolder:GetChildren() .. " objects)")
print("[BuildMap]   - Hallway (" .. #hallwayFolder:GetChildren() .. " objects)")
print("[BuildMap] Now SAVE the place file (Ctrl+S)!")
print("============================================")
