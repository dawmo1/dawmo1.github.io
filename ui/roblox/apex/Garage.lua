-- APEX / Garage: car select. Car list on the left, hero car centre stage, performance + upgrades + paint on the right.
return function(K, parent: Instance, P: { [string]: any })
	K.use("apex")
	local T = K.T
	local g, root = K.screen("APEX_Garage", parent)
	K.backdrop(root, { glow = T.accent, glowAt = UDim2.fromScale(0.5, 0.6), glowSize = 1700, glowStrength = 0.8, floor = T.surface2 })
	K.topbar(root, "APEX", { "Garage", "Race", "Dealership", "Events", "Club" }, 1,
		{ { "coins", "2,480,150", T.warn, false }, { "gem", "1,240", T.accent2, true } }, P)

	-- left: owned cars
	local left = K.new("Frame", root, { Position = UDim2.fromOffset(56, 132), Size = UDim2.fromOffset(380, 760), Name = "CarList" })
	K.list(left, "y", 12)
	K.header(left, "My garage", { LayoutOrder = 0 }, "3 / 24")
	local cars = {
		{ "supercar", "Veloce R", "S1", 912, T.accent, true },
		{ "mudrunner", "Muddog 8", "B", 641, T.good },
		{ "donk", "Boulevard '78", "A", 744, T.accent2 },
	}
	for i, c in cars do
		local sel = c[6]
		local card = K.panel(left, { Size = UDim2.new(1, 0, 0, 132), LayoutOrder = i }, { alpha = sel and 0.02 or 0.25, color = sel and T.raised or T.surface,
			borderColor = sel and T.accent or nil, borderAlpha = sel and 0 or 0.9, borderThick = sel and 2 or 1 })
		if sel then K.new("Frame", card, { BackgroundTransparency = 0, BackgroundColor3 = T.accent, Size = UDim2.new(0, 4, 1, -24), Position = UDim2.fromOffset(0, 12) }); end
		K.art(card, c[1], { Size = UDim2.fromOffset(190, 108), Position = UDim2.fromOffset(176, 12) })
		K.text(card, c[2], "title", { TextSize = 22, Position = UDim2.fromOffset(20, 18) })
		local row = K.new("Frame", card, { Position = UDim2.fromOffset(20, 54), Size = UDim2.fromOffset(150, 24) })
		K.list(row, "x", 8, "Left", "Center")
		K.pill(row, c[3], c[5], { LayoutOrder = 0 }, true)
		K.text(row, tostring(c[4]), "mono", { TextSize = 14, LayoutOrder = 1, TextColor3 = T.muted })
		K.text(card, sel and "SELECTED" or "OWNED", "label", { Position = UDim2.fromOffset(20, 98), TextSize = 12, TextColor3 = sel and T.accent or T.faint })
	end
	local empty = K.panel(left, { Size = UDim2.new(1, 0, 0, 84), LayoutOrder = 9 }, { alpha = 0.7, sheen = false, borderAlpha = 0.8 })
	K.icon(empty, "plus", 22, T.muted, { Position = UDim2.fromOffset(20, 31) })
	K.text(empty, "Visit the dealership", "body", { Position = UDim2.fromOffset(56, 20), TextColor3 = T.text })
	K.text(empty, "21 cars to unlock", "small", { Position = UDim2.fromOffset(56, 44), TextSize = 14 })

	-- centre: hero car
	local title = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 150), Size = UDim2.fromOffset(900, 150) })
	K.text(title, "VELOCE R", "display", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), TextSize = 64, TextXAlignment = Enum.TextXAlignment.Center })
	local sub = K.new("Frame", title, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(450, 92), Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X })
	K.list(sub, "x", 14, "Center", "Center")
	K.pill(sub, "S1 · 912", T.accent, { LayoutOrder = 0 }, true)
	K.text(sub, "Mid-engine hypercar  ·  V10  ·  AWD", "body", { LayoutOrder = 1, TextColor3 = T.muted })
	local shadow = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(960, 772), Size = UDim2.fromOffset(820, 90), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 1 })
	K.corner(shadow, 999); K.grad(shadow, { Color3.new(0, 0, 0), Color3.new(0, 0, 0) }, 0, NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1) }))
	K.art(root, "supercar", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(960, 800), Size = UDim2.fromOffset(980, 520), ZIndex = 2 })
	-- turntable hint
	local spin = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 812), Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X })
	K.list(spin, "x", 10, "Center", "Center")
	K.icon(spin, "left", 18, T.faint, { LayoutOrder = 0 }); K.text(spin, "Drag to rotate", "label", { LayoutOrder = 1, TextColor3 = T.faint, TextSize = 12 }); K.icon(spin, "right", 18, T.faint, { LayoutOrder = 2 })

	-- right: performance, upgrades, paint
	local right = K.panel(root, { Position = UDim2.fromOffset(1484, 132), Size = UDim2.fromOffset(380, 600), Name = "Spec" }, { alpha = 0.2 })
	K.pad(right, 26, 24)
	local col = K.new("Frame", right, { Size = UDim2.fromScale(1, 1) })
	K.list(col, "y", 14)
	K.header(col, "Performance", { LayoutOrder = 0 }, "Stage 3")
	local stats = { { "Top speed", "342 km/h", 0.92, 0.95, "+9" }, { "0 – 100", "2.6 s", 0.88 }, { "Handling", "8.4", 0.84, 0.9, "+0.5" }, { "Braking", "7.9", 0.79 }, { "Nitro", "6.1", 0.61 } }
	for i, s in stats do K.stat(col, s[1], s[2], s[3], { order = i, preview = s[4], delta = s[5], ticks = 10 }) end
	K.new("Frame", col, { Size = UDim2.new(1, 0, 0, 6), LayoutOrder = 9 })
	K.header(col, "Upgrades", { LayoutOrder = 10 }, "11 / 20")
	local ups = K.new("Frame", col, { Size = UDim2.new(1, 0, 0, 96), LayoutOrder = 11 })
	K.grid(ups, Vector2.new(77, 96), 6)
	for i, u in { { "zap", "Engine", 4 }, { "dial", "Tires", 3 }, { "flame", "Nitro", 2 }, { "wrench", "Chassis", 2 } } do
		local t = K.panel(ups, { LayoutOrder = i }, { alpha = 0.1, color = T.surface2, sheen = false })
		K.icon(t, u[1], 24, u[3] == 5 and T.accent or T.text, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(38, 14) })
		K.text(t, u[2], "label", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(38, 46), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center })
		local pips = K.new("Frame", t, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(38, 72), Size = UDim2.fromOffset(55, 5) })
		K.list(pips, "x", 3)
		for p = 1, 5 do K.new("Frame", pips, { Size = UDim2.fromOffset(8.6, 5), BackgroundTransparency = 0, BackgroundColor3 = p <= u[3] and T.accent or T.raised, LayoutOrder = p }) end
	end
	K.new("Frame", col, { Size = UDim2.new(1, 0, 0, 6), LayoutOrder = 19 })
	K.header(col, "Paint", { LayoutOrder = 20 }, "Pearl white")
	local sw = K.new("Frame", col, { Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 21 })
	K.list(sw, "x", 9, "Left", "Center")
	for i, c in { 0xEDEFF2, 0x15171C, 0xC8102E, 0xFF6A13, 0xF4C430, 0x1F7A4D, 0x1E4FD8, 0x7A2BD9 } do
		local s = K.new("Frame", sw, { Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 0, BackgroundColor3 = K.rgb(c), LayoutOrder = i })
		K.corner(s, 999)
		K.stroke(s, i == 1 and T.accent or T.text, i == 1 and 3 or 1, i == 1 and 0 or 0.8)
		K.grad(s, { Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150) }, 135)
	end

	-- bottom actions
	local act = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -64), Size = UDim2.fromOffset(0, 64), AutomaticSize = Enum.AutomaticSize.X })
	K.list(act, "x", 14, "Center", "Center")
	K.button(act, "Customize", "secondary", { LayoutOrder = 0, Size = UDim2.fromOffset(220, 60) }, { icon = "paint", key = "C" })
	K.button(act, "Upgrade", "secondary", { LayoutOrder = 1, Size = UDim2.fromOffset(220, 60) }, { icon = "trend", key = "U" })
	K.button(act, "Race", "primary", { LayoutOrder = 2, Size = UDim2.fromOffset(300, 64) }, { icon = "flag", key = "Enter", textSize = 24 })
	K.hints(root, { { "Q", "Prev car" }, { "E", "Next car" }, { "Esc", "Back" } }, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 56, 1, -28) })
	return g
end
