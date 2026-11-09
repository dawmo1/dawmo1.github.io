-- FRONTLINE / Combat HUD: compass, objective score, kill feed, minimap, health + armour, ammo, weapon wheel slots, hit marker, damage direction.
return function(K, parent: Instance, P: { [string]: any })
	K.use("frontline")
	local T = K.T
	local g, root = K.screen("FL_CombatHUD", parent)
	local plate = { alpha = 0.4, color = T.bg, sheen = false, borderAlpha = 0.88 }

	-- top-centre: compass strip
	local comp = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 28), Size = UDim2.fromOffset(640, 40), ClipsDescendants = true })
	local fade = K.new("Frame", comp, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BackgroundColor3 = T.bg })
	K.grad(fade, { T.bg, T.bg }, 0, NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1) }))
	local heading = 248
	for d = heading - 60, heading + 60, 5 do
		local x = 320 + (d - heading) * 5.2
		local dd = d % 360
		local major = dd % 15 == 0
		K.new("Frame", comp, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(x, 40), Size = UDim2.fromOffset(2, major and 12 or 6), BackgroundTransparency = major and 0.1 or 0.5, BackgroundColor3 = T.text })
		local lbl = ({ [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SW", [270] = "W", [315] = "NW" })[dd]
		if lbl or (major and dd % 30 == 0) then
			K.text(comp, lbl or tostring(dd), lbl and "title" or "mono", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(x, 0), TextSize = lbl and 18 or 12, TextColor3 = lbl and T.text or T.muted })
		end
	end
	K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 70), Size = UDim2.fromOffset(2, 10), BackgroundTransparency = 0, BackgroundColor3 = T.accent })
	K.text(root, tostring(heading), "mono", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 80), TextSize = 13, TextColor3 = T.accent })
	-- objective marker on the compass
	local ob = K.new("Frame", comp, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(320 + 22 * 5.2, 20), Size = UDim2.fromOffset(22, 22), Rotation = 45, BackgroundTransparency = 0, BackgroundColor3 = T.accent, ZIndex = 3 })
	K.text(comp, "B", "title", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(320 + 22 * 5.2, 20), TextSize = 14, TextColor3 = T.accentInk, ZIndex = 4 })

	-- top-centre below compass: team score + zone status
	local sc = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 112), Size = UDim2.fromOffset(520, 60) })
	local function side(x: number, anchor: number, score: string, color: Color3, pct: number, flip: boolean)
		local s = K.new("Frame", sc, { AnchorPoint = Vector2.new(anchor, 0), Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(200, 60) })
		K.text(s, score, "display", { TextSize = 32, AnchorPoint = Vector2.new(flip and 1 or 0, 0), Position = UDim2.fromScale(flip and 1 or 0, 0), TextColor3 = color })
		local b = K.bar(s, { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.fromOffset(0, 46), Rotation = flip and 180 or 0 }, pct, color, { round = false })
	end
	side(220, 1, "142", T.accent2, 0.71, true)
	side(300, 0, "118", T.bad, 0.59, false)
	K.text(sc, "4:12", "mono", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(260, 6), TextSize = 20 })
	local zones = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 180), Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X })
	K.list(zones, "x", 10, "Center", "Center")
	for i, z in { { "A", T.accent2, 1 }, { "B", T.accent, 0.62 }, { "C", T.bad, 1 } } do
		local f = K.new("Frame", zones, { Size = UDim2.fromOffset(40, 40), LayoutOrder = i })
		local d = K.new("Frame", f, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 28), Rotation = 45, BackgroundTransparency = 0.25, BackgroundColor3 = z[2] })
		K.stroke(d, z[2], i == 2 and 2 or 0, 0)
		K.text(f, z[1], "title", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), TextSize = 16, TextColor3 = T.accentInk, ZIndex = 3 })
	end
	K.text(root, "CAPTURING B  ·  62%", "label", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 226), TextColor3 = T.accent })

	-- top-right: kill feed
	local feed = K.new("Frame", root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -40, 0, 32), Size = UDim2.fromOffset(460, 200) })
	K.list(feed, "y", 6, "Right")
	for i, k in { { P.name, "revolver", "NOVA_X", true, true }, { "turbo_tess", "grenade", "Ploopz", false }, { "R1V3R", "launcher", "mxlo", false } } do
		local row = K.panel(feed, { Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i }, { alpha = k[4] and 0.2 or 0.45, color = k[4] and T.raised or T.bg, sheen = false,
			borderColor = k[4] and T.accent or nil, borderAlpha = k[4] and 0.2 or 0.9 })
		K.pad(row, 0, 14); K.list(row, "x", 10, "Right", "Center")
		K.text(row, k[1], "body", { TextSize = 16, FontFace = T.bodyBold, TextColor3 = k[4] and T.accent or T.accent2, LayoutOrder = 0 })
		K.art(row, k[2], { Size = UDim2.fromOffset(56, 26), LayoutOrder = 1 })
		if k[5] then K.icon(row, "crosshair", 16, T.bad, { LayoutOrder = 2 }) end
		K.text(row, k[3], "body", { TextSize = 16, FontFace = T.bodyBold, TextColor3 = T.bad, LayoutOrder = 3 })
	end

	-- top-left: minimap with view cone and pings
	local map = K.panel(root, { Position = UDim2.fromOffset(40, 32), Size = UDim2.fromOffset(280, 280), ClipsDescendants = true }, { alpha = 0.35, color = T.bg, sheen = false, chamfer = 16, corners = "tl br" })
	for i = 1, 9 do
		K.new("Frame", map, { BackgroundTransparency = 0.93, BackgroundColor3 = T.text, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, i * 28) })
		K.new("Frame", map, { BackgroundTransparency = 0.93, BackgroundColor3 = T.text, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromOffset(i * 28, 0) })
	end
	for _, b in { { 30, 40, 70, 50 }, { 150, 30, 90, 60 }, { 60, 150, 50, 90 }, { 170, 170, 80, 70 }, { 120, 110, 30, 30 } } do
		local blk = K.new("Frame", map, { Position = UDim2.fromOffset(b[1], b[2]), Size = UDim2.fromOffset(b[3], b[4]), BackgroundTransparency = 0.82, BackgroundColor3 = T.text })
		K.stroke(blk, T.text, 1, 0.7)
	end
	local cone = K.new("Frame", map, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(140, 140), Size = UDim2.fromOffset(140, 120), BackgroundTransparency = 0, BackgroundColor3 = T.text, Rotation = -22 })
	K.grad(cone, { T.text, T.text }, 90, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.95), NumberSequenceKeypoint.new(1, 0.75) }))
	local me = K.new("Frame", map, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(140, 140), Size = UDim2.fromOffset(14, 14), Rotation = 23, BackgroundTransparency = 0, BackgroundColor3 = T.accent, ZIndex = 3 })
	for _, p in { { 110, 168, T.accent2 }, { 96, 120, T.accent2 }, { 214, 70, T.bad } } do
		local d = K.new("Frame", map, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p[1], p[2]), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 0, BackgroundColor3 = p[3], ZIndex = 3 })
		K.corner(d, 999)
	end
	local zb = K.new("Frame", map, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(190, 96), Size = UDim2.fromOffset(18, 18), Rotation = 45, BackgroundTransparency = 0, BackgroundColor3 = T.accent, ZIndex = 3 })
	K.text(root, "DOCKYARD  ·  SQUAD 3", "label", { Position = UDim2.fromOffset(44, 320), TextColor3 = T.muted })

	-- crosshair + hit marker
	for i = 0, 3 do
		local a = math.rad(i * 90)
		K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(960 + math.cos(a) * 14, 540 + math.sin(a) * 14), Size = i % 2 == 0 and UDim2.fromOffset(10, 2) or UDim2.fromOffset(2, 10), BackgroundTransparency = 0.1, BackgroundColor3 = T.text })
	end
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(960 + math.cos(a) * 24, 540 + math.sin(a) * 24), Size = UDim2.fromOffset(14, 3), Rotation = 45 + i * 90, BackgroundTransparency = 0, BackgroundColor3 = T.bad })
	end
	K.text(root, "92", "display", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(1000, 500), TextSize = 26, TextColor3 = T.accent })
	K.text(root, "HEADSHOT", "label", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(1002, 526), TextColor3 = T.accent })

	-- damage direction arc (hit from the left)
	local dmg = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(760, 560), Size = UDim2.fromOffset(16, 170), Rotation = 8, BackgroundTransparency = 0, BackgroundColor3 = T.bad })
	K.corner(dmg, 999); K.grad(dmg, { T.bad, T.bad }, 90, NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 1) }))
	local edge = K.new("Frame", root, { Size = UDim2.fromOffset(260, 1080), BackgroundTransparency = 0, BackgroundColor3 = T.bad, ZIndex = -1 })
	K.grad(edge, { T.bad, T.bad }, 0, { 0.78, 1 })

	-- bottom-left: health, armour, squad
	local vit = K.new("Frame", root, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 40, 1, -40), Size = UDim2.fromOffset(440, 200) })
	local squad = K.new("Frame", vit, { Size = UDim2.new(1, 0, 0, 92) })
	K.list(squad, "y", 4)
	for i, s in { { "Ploopz", 0.8, T.accent2 }, { "turbo_tess", 0.35, T.accent2 }, { "R1V3R", 0, T.bad } } do
		local r = K.new("Frame", squad, { Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i })
		K.text(r, s[1], "body", { TextSize = 15, Size = UDim2.fromOffset(0, 28), TextColor3 = s[2] > 0 and T.text or T.faint })
		if s[2] > 0 then K.bar(r, { Size = UDim2.fromOffset(120, 4), Position = UDim2.fromOffset(130, 12) }, s[2], s[2] < 0.4 and T.warn or T.text, { round = false })
		else K.text(r, "DOWN  ·  REVIVE", "label", { Position = UDim2.fromOffset(130, 0), Size = UDim2.fromOffset(0, 28), TextColor3 = T.bad, TextSize = 11 }) end
	end
	local hp = K.panel(vit, { Position = UDim2.fromOffset(0, 104), Size = UDim2.fromOffset(440, 96) }, { alpha = 0.4, color = T.bg, sheen = false, chamfer = 12, corners = "tl br" })
	K.icon(hp, "heart", 26, T.text, { Position = UDim2.fromOffset(20, 20) })
	K.text(hp, "78", "display", { TextSize = 40, Position = UDim2.fromOffset(58, 6) })
	K.bar(hp, { Size = UDim2.fromOffset(300, 10), Position = UDim2.fromOffset(120, 26) }, 0.78, T.text, { round = false, ticks = 5 })
	K.icon(hp, "shield", 22, T.accent2, { Position = UDim2.fromOffset(22, 60) })
	K.bar(hp, { Size = UDim2.fromOffset(300, 6), Position = UDim2.fromOffset(120, 68) }, 0.4, T.accent2, { round = false, ticks = 3 })
	K.text(hp, "40", "mono", { TextSize = 14, Position = UDim2.fromOffset(58, 58), TextColor3 = T.accent2 })

	-- bottom-right: ammo + weapon slots
	local wp = K.new("Frame", root, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -40, 1, -40), Size = UDim2.fromOffset(520, 220) })
	local am = K.panel(wp, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(520, 120) }, { alpha = 0.4, color = T.bg, sheen = false, chamfer = 12, corners = "tr bl" })
	K.art(am, "revolver", { Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(170, 90) })
	K.text(am, '4<font size="28" color="#959A86"> / 18</font>', "display", { TextSize = 60, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 2) })
	local rounds = K.new("Frame", am, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 86), Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X })
	K.list(rounds, "x", 4, "Right")
	for i = 1, 6 do K.new("Frame", rounds, { Size = UDim2.fromOffset(8, 16), BackgroundTransparency = i <= 4 and 0 or 0.8, BackgroundColor3 = T.accent, LayoutOrder = i }) end
	K.text(am, "MAGNUM .44  ·  SEMI", "label", { Position = UDim2.fromOffset(200, 88), TextSize = 11 })
	local hot = K.new("Frame", wp, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(0, 84), AutomaticSize = Enum.AutomaticSize.X })
	K.list(hot, "x", 8, "Right", "Bottom")
	for i, s in { { "launcher", "1", "epic" }, { "revolver", "2", "legendary", true }, { "grenade", "G", "rare", false, "×2" }, { nil, "F", "uncommon", false, "×2", "sparkles" } } do
		K.slot(hot, { Size = UDim2.fromOffset(s[4] and 128 or 100, s[4] and 84 or 70), LayoutOrder = i }, { art = s[1], key = s[2], rarity = s[3], selected = s[4], count = s[5], icon = s[6], iconColor = K.RARITY.uncommon[1] })
	end

	-- interaction prompt
	local prompt = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 700), Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X })
	K.list(prompt, "x", 10, "Center", "Center")
	K.key(prompt, "E", { LayoutOrder = 0, Size = UDim2.fromOffset(32, 32) })
	K.text(prompt, "Hold to pick up  <b>Frag M67</b>", "body", { LayoutOrder = 1, TextSize = 18 })
	return g
end
