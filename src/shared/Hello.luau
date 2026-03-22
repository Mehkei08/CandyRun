--[[
	Candy Run - Shared Utilities
]]

local CandyRunUtils = {}

-- Format time as M:SS.s
function CandyRunUtils.formatTime(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%04.1f", mins, secs)
end

-- Get a random candy color
function CandyRunUtils.randomCandyColor(): Color3
	local colors = {
		Color3.fromRGB(255, 100, 130),  -- Strawberry
		Color3.fromRGB(100, 140, 255),  -- Blueberry
		Color3.fromRGB(255, 240, 100),  -- Lemon
		Color3.fromRGB(100, 255, 200),  -- Mint
		Color3.fromRGB(200, 100, 255),  -- Grape
		Color3.fromRGB(255, 180, 80),   -- Orange
		Color3.fromRGB(255, 180, 220),  -- Cotton Candy
	}
	return colors[math.random(1, #colors)]
end

-- Lerp between two values
function CandyRunUtils.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

return CandyRunUtils
