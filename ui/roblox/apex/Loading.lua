-- APEX / Loading: event key art, track card, rotating tip, progress with asset step.
return function(K, parent: Instance, P: { [string]: any })
	K.use("apex")
	local T = K.T
	local g, root = K.screen("APEX_Loading", parent)
	K.backdrop(root, { glow = T.accent, glowAt = UDim2.fromScale(0.62, 0.5), glowSize = 1900, glowStrength = 0.74, floor = T.surface })

	-- diagonal speed bands behind the car
	for i, a in { { 0.0, 0.92 }, { 0.12, 0.95 }, { 0.3, 0.9 }, { 0.46, 0.96 } } do
		local band = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.64 + a[1] * 0.25, 0.45), Size = UDim2.fromOffset(2600, 18 + i * 10), Rotation = -14,
			BackgroundTransparency = 0, BackgroundColor3 = i % 2 == 0 and T.accent or T.text, ZIndex = -6 })
		K.grad(band, { Color3.new(1, 1, 1), Color3.new(1, 1, 1) }, 0, NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, a[2]), NumberSequenceKeypoint.new(1, 1) }))
	end
	K.art(root, "supercar", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(1210, 520), Size = UDim2.fromOffset(1180, 620) })

	-- event title block
	local t = K.new("Frame", root, { Position = UDim2.fromOffset(110, 230), Size = UDim2.fromOffset(700, 400) })
	K.pill(t, "Championship  ·  Round 3 of 6", T.accent, { Position = UDim2.fromOffset(0, 0) }, true)
	K.text(t, "HARBOUR\nCIRCUIT", "display", { TextSize = 88, Position = UDim2.fromOffset(-4, 44), LineHeight = 0.95 })
	K.text(t, "Night  ·  Wet  ·  3 laps  ·  8 drivers", "body", { Position = UDim2.fromOffset(0, 254), TextColor3 = T.muted, TextSize = 20 })
	local specs = K.new("Frame", t, { Position = UDim2.fromOffset(0, 306), Size = UDim2.fromOffset(640, 70) })
	K.list(specs, "x", 40)
	for i, s in { { "Length", "4.2 km" }, { "Corners", "14" }, { "Record", "1:19.044" } } do
		local c = K.new("Frame", specs, { Size = UDim2.fromOffset(150, 70), LayoutOrder = i })
		K.text(c, s[1], "label", {})
		K.text(c, s[2], "display", { TextSize = 26, Position = UDim2.fromOffset(0, 26) })
	end

	-- tip card
	local tip = K.panel(root, { Position = UDim2.fromOffset(110, 790), Size = UDim2.fromOffset(640, 104) }, { alpha = 0.3 })
	K.icon(tip, "info", 22, T.accent2, { Position = UDim2.fromOffset(22, 22) })
	K.text(tip, "Tip  3 / 12", "label", { Position = UDim2.fromOffset(58, 22), TextColor3 = T.accent2 })
	K.text(tip, "Wet tarmac halves grip on painted kerbs. Brake before the\nwhite lines, not on them.", "body", { Position = UDim2.fromOffset(58, 46), TextSize = 17 })

	-- progress
	local prog = K.new("Frame", root, { Position = UDim2.fromOffset(110, 950), Size = UDim2.fromOffset(1700, 60) })
	K.text(prog, "Streaming track geometry", "label", { TextColor3 = T.text })
	K.text(prog, "68%", "mono", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), TextSize = 16 })
	K.bar(prog, { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.fromOffset(0, 34) }, 0.68, T.accent, { round = false })
	local steps = K.new("Frame", prog, { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 16) })
	K.list(steps, "x", 26)
	for i, s in { { "Cars", true }, { "Track", false }, { "Weather", false }, { "Audio", false } } do
		K.text(steps, (s[2] and "✓ " or "") .. s[1], "label", { TextSize = 11, TextColor3 = s[2] and T.good or (i == 2 and T.text or T.faint), LayoutOrder = i })
	end
	return g
end
