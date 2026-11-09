-- APEX / Race results: podium placement, full classification, rewards with XP level-up bar.
return function(K, parent: Instance, P: { [string]: any })
	K.use("apex")
	local T = K.T
	local g, root = K.screen("APEX_Results", parent)
	K.backdrop(root, { glow = T.warn, glowAt = UDim2.fromScale(0.27, 0.55), glowSize = 1400, glowStrength = 0.8, floor = T.surface2 })

	-- left: placement hero
	local hero = K.new("Frame", root, { Position = UDim2.fromOffset(96, 80), Size = UDim2.fromOffset(820, 900) })
	K.pill(hero, "Harbour Circuit  ·  Round 3", T.text, { Position = UDim2.fromOffset(0, 0) })
	-- TextSize caps at 100, so the big numeral is TextScaled inside a fixed box
	K.text(hero, "1", "display", { AutomaticSize = Enum.AutomaticSize.None, TextScaled = true, Size = UDim2.fromOffset(120, 190), Position = UDim2.fromOffset(-8, 44), TextColor3 = T.warn })
	K.text(hero, "ST", "display", { TextSize = 56, Position = UDim2.fromOffset(122, 70), TextColor3 = T.warn })
	K.text(hero, "VICTORY", "display", { TextSize = 46, Position = UDim2.fromOffset(4, 250) })
	K.text(hero, "You led 2 of 3 laps and set the fastest lap.", "body", { Position = UDim2.fromOffset(4, 312), TextColor3 = T.muted, TextSize = 20 })
	K.art(hero, "supercar", { Position = UDim2.fromOffset(-30, 360), Size = UDim2.fromOffset(860, 450) })
	local tags = K.new("Frame", hero, { Position = UDim2.fromOffset(4, 830), Size = UDim2.fromOffset(800, 30) })
	K.list(tags, "x", 10)
	K.pill(tags, "Fastest lap  0:39.774", T.accent2, { LayoutOrder = 0 }, true)
	K.pill(tags, "Clean race", T.good, { LayoutOrder = 1 }, true)
	K.pill(tags, "New PB  −1.20 s", T.warn, { LayoutOrder = 2 }, true)

	-- right: classification
	local cls = K.panel(root, { Position = UDim2.fromOffset(980, 80), Size = UDim2.fromOffset(844, 520) }, { alpha = 0.18 })
	K.pad(cls, 22, 26)
	K.header(cls, "Classification", { Size = UDim2.new(1, 0, 0, 22) }, "3 laps  ·  12.6 km")
	local cols = K.new("Frame", cls, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 24) })
	for _, c in { { "Pos", 0 }, { "Driver", 60 }, { "Car", 340 }, { "Best lap", 540 }, { "Gap", 700 } } do K.text(cols, c[1], "label", { Position = UDim2.fromOffset(c[2], 0), TextSize = 11, TextColor3 = T.faint }) end
	local list = K.new("Frame", cls, { Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 1, -70) })
	K.list(list, "y", 2)
	local rows = { { P.name, "Veloce R", "0:39.774", "1:58.902", true }, { "NOVA_X", "Veloce Spyder", "0:39.981", "+0.418" }, { "driftking77", "Boulevard '78", "0:40.660", "+2.04" },
		{ "turbo_tess", "Muddog Baja", "0:41.002", "+5.71" }, { "Ploopz", "Veloce R", "0:41.390", "+7.10" }, { "R1V3R", "Muddog 8", "0:42.118", "+9.33" }, { "mxlo", "Boulevard Gold", "0:42.940", "+12.8" }, { "slowpoke", "Muddog 8", "0:45.001", "DNF" } }
	for i, r in rows do
		local me = r[5]
		local row = K.new("Frame", list, { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = me and 0.82 or (i % 2 == 0 and 0.97 or 1), BackgroundColor3 = me and T.warn or T.text, LayoutOrder = i })
		K.corner(row, 6)
		local medal = ({ T.warn, Color3.fromRGB(200, 208, 220), Color3.fromRGB(205, 127, 50) })[i]
		K.text(row, tostring(i), "display", { TextSize = 18, Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(0, 48), TextColor3 = medal or T.muted })
		K.text(row, r[1], "body", { Position = UDim2.fromOffset(60, 0), Size = UDim2.fromOffset(0, 48), FontFace = me and T.bodyBold or T.body })
		K.text(row, r[2], "small", { Position = UDim2.fromOffset(340, 0), Size = UDim2.fromOffset(0, 48) })
		K.text(row, r[3], "mono", { Position = UDim2.fromOffset(540, 0), Size = UDim2.fromOffset(0, 48), TextSize = 14, TextColor3 = i == 1 and T.accent2 or T.text })
		K.text(row, r[4], "mono", { Position = UDim2.fromOffset(700, 0), Size = UDim2.fromOffset(0, 48), TextSize = 14, TextColor3 = r[4] == "DNF" and T.bad or T.muted })
	end

	-- rewards
	local rew = K.panel(root, { Position = UDim2.fromOffset(980, 620), Size = UDim2.fromOffset(844, 260) }, { alpha = 0.18 })
	K.pad(rew, 22, 26)
	K.header(rew, "Rewards", { Size = UDim2.new(1, 0, 0, 22) })
	local items = K.new("Frame", rew, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 104) })
	K.list(items, "x", 12)
	for i, r in { { "coins", "+42,500", "Race payout", T.warn }, { "zap", "+1,840", "Driver XP", T.accent2 }, { "trophy", "+25", "Champ. points", T.accent }, { "gift", "Rare crate", "1st place drop", K.RARITY.rare[1] } } do
		local c = K.panel(items, { Size = UDim2.fromOffset(188, 104), LayoutOrder = i }, { alpha = 0.1, color = T.surface2, sheen = false })
		K.icon(c, r[1], 26, r[4], { Position = UDim2.fromOffset(18, 18) })
		K.text(c, r[2], "display", { TextSize = 20, Position = UDim2.fromOffset(18, 52) })
		K.text(c, r[3], "label", { Position = UDim2.fromOffset(18, 78), TextSize = 11 })
	end
	local lvl = K.new("Frame", rew, { Position = UDim2.fromOffset(0, 162), Size = UDim2.new(1, 0, 0, 50) })
	K.text(lvl, 'Driver level <font color="#2FD8F2">23 → 24</font>', "body", { FontFace = T.bodyBold })
	K.text(lvl, "620 / 4,000 XP", "mono", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), TextSize = 14, TextColor3 = T.muted })
	K.bar(lvl, { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.fromOffset(0, 34) }, 0.155, T.accent2, { preview = 0.155 })

	local act = K.new("Frame", root, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -96, 1, -56), Size = UDim2.fromOffset(0, 60), AutomaticSize = Enum.AutomaticSize.X })
	K.list(act, "x", 12, "Right", "Center")
	K.button(act, "Replay", "secondary", { LayoutOrder = 0, Size = UDim2.fromOffset(190, 56) }, { icon = "play", key = "R" })
	K.button(act, "Garage", "secondary", { LayoutOrder = 1, Size = UDim2.fromOffset(190, 56) }, { icon = "home", key = "G" })
	K.button(act, "Next race", "primary", { LayoutOrder = 2, Size = UDim2.fromOffset(260, 60) }, { icon = "flag", key = "Enter" })
	return g
end
