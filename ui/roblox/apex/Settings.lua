-- APEX / Settings: category rail, grouped controls (segmented, sliders, toggles, keybinds), live preview card, apply bar.
return function(K, parent: Instance, P: { [string]: any })
	K.use("apex")
	local T = K.T
	local g, root = K.screen("APEX_Settings", parent)
	K.backdrop(root, { glow = T.accent, glowAt = UDim2.fromScale(0.85, 0.2), glowSize = 1300, glowStrength = 0.9 })

	K.text(root, "SETTINGS", "display", { TextSize = 40, Position = UDim2.fromOffset(96, 64) })
	K.text(root, "Changes preview live. Nothing is saved until you apply.", "body", { Position = UDim2.fromOffset(96, 120), TextColor3 = T.muted })
	local close = K.panel(root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -96, 0, 64), Size = UDim2.fromOffset(52, 52) }, { alpha = 0.2 })
	K.icon(close, "x", 24, T.text, { Position = UDim2.fromOffset(14, 14) })

	-- category rail
	local rail = K.new("Frame", root, { Position = UDim2.fromOffset(96, 184), Size = UDim2.fromOffset(300, 700) })
	K.list(rail, "y", 6)
	for i, c in { { "monitor", "Graphics" }, { "volume", "Audio" }, { "gamepad", "Controls" }, { "keyboard", "Keybinds" }, { "eye", "Accessibility" }, { "users", "Privacy" }, { "wifi", "Network" } } do
		local on = i == 1
		local row = K.new("Frame", rail, { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = on and 0.05 or 1, BackgroundColor3 = T.raised, LayoutOrder = i })
		K.corner(row, T.radius)
		if on then K.new("Frame", row, { BackgroundTransparency = 0, BackgroundColor3 = T.accent, Size = UDim2.fromOffset(4, 28), Position = UDim2.fromOffset(0, 14) }) end
		K.icon(row, c[1], 22, on and T.accent or T.muted, { Position = UDim2.fromOffset(22, 17) })
		K.text(row, c[2], "title", { TextSize = 19, Position = UDim2.fromOffset(60, 0), Size = UDim2.fromOffset(0, 56), TextColor3 = on and T.text or T.muted })
	end

	-- main options
	local main = K.panel(root, { Position = UDim2.fromOffset(420, 184), Size = UDim2.fromOffset(880, 770) }, { alpha = 0.15 })
	K.pad(main, 30, 36)
	local col = K.new("Frame", main, { Size = UDim2.fromScale(1, 1) })
	K.list(col, "y", 0)
	local function row(order: number, name: string, desc: string?, build: (Frame) -> ())
		local r = K.new("Frame", col, { Size = UDim2.new(1, 0, 0, 60), LayoutOrder = order })
		K.text(r, name, "body", { Position = UDim2.fromOffset(0, desc and 6 or 0), Size = UDim2.fromOffset(0, desc and 24 or 60), FontFace = T.bodyBold, TextSize = 18 })
		if desc then K.text(r, desc, "small", { Position = UDim2.fromOffset(0, 32), TextSize = 14 }) end
		local ctl = K.new("Frame", r, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(380, 40) })
		build(ctl)
		K.new("Frame", r, { BackgroundTransparency = 0.93, BackgroundColor3 = T.text, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1) })
	end
	local function group(order: number, name: string)
		local h = K.new("Frame", col, { Size = UDim2.new(1, 0, 0, 48), LayoutOrder = order })
		K.header(h, name, { Position = UDim2.fromOffset(0, 16) })
	end
	group(0, "Display")
	row(1, "Quality preset", "Sets every option below", function(c) K.segmented(c, { "Low", "Med", "High", "Ultra" }, 3, { Size = UDim2.fromScale(1, 1) }) end)
	row(2, "Field of view", nil, function(c)
		K.slider(c, 0.62, { Size = UDim2.new(1, -70, 1, 0) })
		K.text(c, "84°", "mono", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), TextSize = 16 })
	end)
	row(3, "Motion blur", "Speed-scaled, off in photo mode", function(c) K.toggle(c, true, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5) }) end)
	row(4, "Camera shake", nil, function(c)
		K.slider(c, 0.35, { Size = UDim2.new(1, -70, 1, 0) })
		K.text(c, "35%", "mono", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), TextSize = 16 })
	end)
	group(5, "Effects")
	row(6, "Reflections", nil, function(c) K.segmented(c, { "Off", "Screen", "Full" }, 2, { Size = UDim2.fromScale(1, 1) }) end)
	row(7, "Tyre smoke and sparks", nil, function(c) K.toggle(c, true, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5) }) end)
	row(8, "Speed lines", "Screen-edge streaks above 200 km/h", function(c) K.toggle(c, false, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5) }) end)
	group(9, "HUD")
	row(10, "Units", nil, function(c) K.segmented(c, { "km/h", "mph" }, 1, { Size = UDim2.fromScale(1, 1) }) end)
	row(11, "HUD scale", nil, function(c)
		K.slider(c, 0.5, { Size = UDim2.new(1, -70, 1, 0) })
		K.text(c, "100%", "mono", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), TextSize = 16 })
	end)

	-- right: preview + perf estimate
	local side = K.new("Frame", root, { Position = UDim2.fromOffset(1324, 184), Size = UDim2.fromOffset(500, 740) })
	local prev = K.panel(side, { Size = UDim2.fromOffset(500, 300), ClipsDescendants = true }, { alpha = 0.05, color = T.surface2 })
	local tint = K.new("Frame", prev, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BackgroundColor3 = T.accent })
	K.grad(tint, { T.accent, T.accent }, 90, { 1, 0.8 })
	K.art(prev, "supercar", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.52, 0.58), Size = UDim2.fromOffset(440, 240) })
	K.pill(prev, "Live preview  ·  High", T.text, { Position = UDim2.fromOffset(16, 16) })
	local perf = K.panel(side, { Position = UDim2.fromOffset(0, 320), Size = UDim2.fromOffset(500, 230) }, { alpha = 0.15 })
	K.pad(perf, 22, 24)
	K.header(perf, "Estimated performance", {})
	K.text(perf, '118<font size="22" color="#8C97AD"> fps</font>', "display", { TextSize = 54, Position = UDim2.fromOffset(0, 40) })
	K.text(perf, "Target 60 · this device", "small", { Position = UDim2.fromOffset(0, 112) })
	K.stat(perf, "GPU load", "64%", 0.64, { order = 0, color = T.good }).Position = UDim2.fromOffset(0, 138)
	local note = K.panel(side, { Position = UDim2.fromOffset(0, 570), Size = UDim2.fromOffset(500, 90) }, { alpha = 0.6, sheen = false, borderColor = T.warn, borderAlpha = 0.5 })
	K.icon(note, "info", 22, T.warn, { Position = UDim2.fromOffset(20, 20) })
	K.text(note, "Ultra reflections need a restart on some mobile\ndevices. You'll be asked before it happens.", "small", { Position = UDim2.fromOffset(56, 18), TextColor3 = T.text, TextSize = 15 })

	-- footer actions
	local foot = K.new("Frame", root, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -96, 1, -40), Size = UDim2.fromOffset(0, 56), AutomaticSize = Enum.AutomaticSize.X })
	K.list(foot, "x", 12, "Right", "Center")
	K.button(foot, "Reset to default", "ghost", { LayoutOrder = 0, Size = UDim2.fromOffset(230, 52) }, { icon = "undo", iconSize = 18, textSize = 16 })
	K.button(foot, "Apply", "primary", { LayoutOrder = 1, Size = UDim2.fromOffset(200, 52) }, { key = "Enter", textSize = 18 })
	K.hints(root, { { "Esc", "Back" }, { "Tab", "Next section" } }, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 96, 1, -52) })
	return g
end
