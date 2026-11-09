-- APEX / Race HUD: position + standings, lap timer with live delta, minimap, speedometer with rev arc, gear and nitro.
return function(K, parent: Instance, P: { [string]: any })
	K.use("apex")
	local T = K.T
	local g, root = K.screen("APEX_RaceHUD", parent)
	local glass = { alpha = 0.35, color = T.bg, sheen = false, borderAlpha = 0.86 }

	-- top-left: position, lap, standings
	local pos = K.new("Frame", root, { Position = UDim2.fromOffset(48, 40), Size = UDim2.fromOffset(340, 120) })
	K.text(pos, '2<font size="40" color="#8C97AD">/8</font>', "display", { TextSize = 92, Position = UDim2.fromOffset(0, -8) })
	K.text(pos, "Position", "label", { Position = UDim2.fromOffset(4, 98), TextColor3 = T.muted })
	local lap = K.new("Frame", root, { Position = UDim2.fromOffset(250, 52), Size = UDim2.fromOffset(150, 80) })
	K.text(lap, "Lap", "label", { Position = UDim2.fromOffset(0, 0) })
	K.text(lap, '2<font color="#8C97AD">/3</font>', "display", { TextSize = 34, Position = UDim2.fromOffset(0, 22) })

	local board = K.panel(root, { Position = UDim2.fromOffset(48, 180), Size = UDim2.fromOffset(330, 0), AutomaticSize = Enum.AutomaticSize.Y }, glass)
	K.pad(board, 10, 0)
	K.list(board, "y", 2)
	local racers = { { "NOVA_X", "Leader" }, { P.name, "+0.84" }, { "driftking77", "+1.20" }, { "Ploopz", "+3.05" }, { "turbo_tess", "+4.71" }, { "R1V3R", "+6.02" }, { "mxlo", "+8.88" }, { "slowpoke", "+14.3" } }
	for i, r in racers do
		local me = i == 2
		local row = K.new("Frame", board, { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = me and 0.1 or 1, BackgroundColor3 = T.accent, LayoutOrder = i })
		K.text(row, tostring(i), "mono", { TextSize = 14, Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(20, 30), AutomaticSize = Enum.AutomaticSize.None, TextColor3 = me and T.accentInk or T.muted })
		K.text(row, r[1], "body", { TextSize = 16, Position = UDim2.fromOffset(48, 0), Size = UDim2.fromOffset(0, 30), TextColor3 = me and T.accentInk or T.text, FontFace = me and T.bodyBold or T.body })
		K.text(row, r[2], "mono", { TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 0), Size = UDim2.fromOffset(0, 30), TextColor3 = me and T.accentInk or T.muted })
	end

	-- top-centre: timer with sector delta
	local timer = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 36), Size = UDim2.fromOffset(420, 120) })
	K.text(timer, "1:24.381", "display", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), TextSize = 46, TextXAlignment = Enum.TextXAlignment.Center })
	local sub = K.new("Frame", timer, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(210, 66), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X })
	K.list(sub, "x", 16, "Center", "Center")
	K.text(sub, "Best  0:41.902", "label", { LayoutOrder = 0, TextColor3 = T.muted })
	K.pill(sub, "S2  −0.214", T.good, { LayoutOrder = 1 }, true)
	-- sector bar
	local sec = K.new("Frame", timer, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(210, 104), Size = UDim2.fromOffset(300, 4) })
	K.list(sec, "x", 4)
	for i, c in { T.good, T.good, T.accent2 } do
		local s = K.new("Frame", sec, { Size = UDim2.new(1 / 3, -3, 1, 0), BackgroundTransparency = i == 3 and 0.6 or 0, BackgroundColor3 = c, LayoutOrder = i })
		K.corner(s, 999)
	end

	-- top-right: minimap (track drawn as a dotted closed curve)
	local map = K.new("Frame", root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -48, 0, 40), Size = UDim2.fromOffset(280, 280), BackgroundTransparency = 0.35, BackgroundColor3 = T.bg, ClipsDescendants = true })
	K.corner(map, 999); K.stroke(map, T.text, 2, 0.8)
	local function track(t: number): Vector2
		local a = t * math.pi * 2
		local r = 92 + 26 * math.sin(a * 3) + 10 * math.cos(a * 2)
		return Vector2.new(140 + math.cos(a) * r * 1.05, 140 + math.sin(a) * r * 0.82)
	end
	for i = 0, 179 do
		local p = track(i / 180)
		K.new("Frame", map, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p.X, p.Y), Size = UDim2.fromOffset(6, 6), BackgroundTransparency = 0.25, BackgroundColor3 = T.text })
	end
	local function dot(t: number, c: Color3, s: number)
		local p = track(t)
		local d = K.new("Frame", map, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p.X, p.Y), Size = UDim2.fromOffset(s, s), BackgroundTransparency = 0, BackgroundColor3 = c, ZIndex = 3 })
		K.corner(d, 999); K.stroke(d, T.bg, 2, 0)
	end
	for _, t in { 0.31, 0.22, 0.18, 0.09, 0.05, 0.93, 0.88 } do dot(t, T.muted, 10) end
	dot(0.27, T.accent, 16)
	local sf = track(0.6)
	K.new("Frame", map, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(sf.X, sf.Y), Size = UDim2.fromOffset(4, 18), BackgroundTransparency = 0, BackgroundColor3 = T.good, ZIndex = 2, Rotation = 30 })
	K.text(root, "Harbour Circuit  ·  4.2 km", "label", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -48, 0, 330), TextColor3 = T.muted })

	-- bottom-right: speedometer
	local gauge = K.new("Frame", root, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -60, 1, -50), Size = UDim2.fromOffset(330, 330), Name = "Speedo" })
	local plate = K.new("Frame", gauge, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.3, BackgroundColor3 = T.bg })
	K.corner(plate, 999); K.stroke(plate, T.text, 1, 0.85)
	local n, a0, a1, rpm = 46, 135, 405, 0.82
	for i = 0, n - 1 do
		local f = i / (n - 1)
		local ang = math.rad(a0 + (a1 - a0) * f)
		local red = f > 0.85
		local lit = f <= rpm
		local len = (i % 5 == 0) and 22 or 13
		local r = 148 - len / 2
		K.new("Frame", gauge, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(165 + math.cos(ang) * r, 165 + math.sin(ang) * r), Size = UDim2.fromOffset(len, i % 5 == 0 and 4 or 3),
			Rotation = math.deg(ang), BackgroundTransparency = lit and 0 or 0.75, BackgroundColor3 = red and T.bad or (lit and (f > 0.7 and T.accent or T.text) or T.text), ZIndex = 2 })
	end
	for i = 0, 8 do
		local ang = math.rad(a0 + (a1 - a0) * i / 8)
		K.text(gauge, tostring(i), "mono", { TextSize = 13, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(165 + math.cos(ang) * 112, 165 + math.sin(ang) * 112), TextColor3 = i >= 7 and T.bad or T.muted, ZIndex = 2 })
	end
	K.text(gauge, "287", "display", { TextSize = 78, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(165, 158), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
	K.text(gauge, "km/h", "label", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(165, 204), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
	local gear = K.new("Frame", gauge, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(165, 238), Size = UDim2.fromOffset(46, 46), BackgroundTransparency = 0, BackgroundColor3 = T.accent, ZIndex = 3 })
	K.corner(gear, 8)
	K.text(gear, "5", "display", { TextSize = 26, Size = UDim2.fromScale(1, 1), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.accentInk, ZIndex = 4 })
	K.text(gauge, "×1000 rpm", "small", { TextSize = 12, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(165, 98), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3, TextColor3 = T.faint })

	-- nitro: segmented vertical bar beside the gauge
	local nitro = K.new("Frame", root, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -412, 1, -66), Size = UDim2.fromOffset(40, 290) })
	K.icon(nitro, "flame", 24, T.accent2, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0) })
	local segs = K.new("Frame", nitro, { Size = UDim2.new(1, 0, 1, -36) })
	K.list(segs, "y", 4, "Center", "Bottom")
	for i = 1, 10 do
		local on = i > 3
		local s = K.new("Frame", segs, { Size = UDim2.new(0, 22, 0.1, -4), BackgroundTransparency = on and 0 or 0.8, BackgroundColor3 = T.accent2, LayoutOrder = i })
		K.corner(s, 3)
	end
	K.key(root, "Shift", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(1, -432, 1, -34) })

	-- bottom-left: score feed
	local feed = K.new("Frame", root, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 48, 1, -56), Size = UDim2.fromOffset(420, 200) })
	K.list(feed, "y", 8, "Left", "Bottom")
	for i, e in { { "Clean overtake", "+500", T.text, 0.45 }, { "Slipstream", "+250", T.text, 0.3 }, { "Drift chain ×4", "+1,240", T.accent, 0 } } do
		local chip = K.panel(feed, { Size = UDim2.fromOffset(0, 46), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i, BackgroundTransparency = 0.35 + e[4] }, { alpha = 0.35 + e[4], color = T.bg, sheen = false })
		K.pad(chip, 0, 18); K.list(chip, "x", 14, "Left", "Center")
		K.text(chip, e[1], "title", { TextSize = 18, LayoutOrder = 0, TextTransparency = e[4] })
		K.text(chip, e[2], "display", { TextSize = 20, TextColor3 = e[3] == T.accent and T.accent or T.accent2, LayoutOrder = 1, TextTransparency = e[4] })
	end
	local total = K.text(root, "SKILL  18,420", "display", { TextSize = 22, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 48, 1, -260), TextColor3 = T.text })
	total.TextTransparency = 0
	return g
end
