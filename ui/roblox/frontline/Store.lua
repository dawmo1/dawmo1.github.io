-- FRONTLINE / Store: featured bundle with a large weapon preview, rotating offers, currency packs.
return function(K, parent: Instance, P: { [string]: any })
	K.use("frontline")
	local T = K.T
	local g, root = K.screen("FL_Store", parent)
	K.backdrop(root, { glow = K.RARITY.legendary[1], glowAt = UDim2.fromScale(0.33, 0.48), glowSize = 1500, glowStrength = 0.84 })
	K.topbar(root, "FRONTLINE", { "Play", "Loadout", "Armory", "Store", "Pass" }, 4,
		{ { "coins", "84,210", T.accent, false }, { "gem", "2,400", T.accent2, true } }, P)

	-- featured bundle
	local leg = K.RARITY.legendary[1]
	local feat = K.panel(root, { Position = UDim2.fromOffset(56, 124), Size = UDim2.fromOffset(1100, 860), ClipsDescendants = true }, { alpha = 0.1, color = T.surface2, chamfer = 22, corners = "tl br", borderColor = leg, borderAlpha = 0.5 })
	local tint = K.new("Frame", feat, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BackgroundColor3 = leg })
	K.grad(tint, { leg, leg }, 120, { 0.78, 1 })
	for i = 1, 12 do -- hazard stripes along the bottom edge
		K.new("Frame", feat, { Position = UDim2.new(0, i * 60 - 80, 1, -14), Size = UDim2.fromOffset(26, 60), Rotation = 35, BackgroundTransparency = 0.82, BackgroundColor3 = leg })
	end
	K.pill(feat, "Featured bundle  ·  4 items", leg, { Position = UDim2.fromOffset(44, 40) }, true)
	K.text(feat, "GILDED\nOUTLAW", "display", { TextSize = 84, Position = UDim2.fromOffset(40, 80), LineHeight = 0.92 })
	K.text(feat, "Engraved Magnum .44, a matching holster and a\nkill-cam finisher. Leaves the store in 3 days.", "body", { Position = UDim2.fromOffset(44, 262), TextColor3 = T.muted, TextSize = 18 })
	K.art(feat, "revolver", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(700, 420), Size = UDim2.fromOffset(760, 430), Rotation = -8, ZIndex = 2 })
	local inc = K.new("Frame", feat, { Position = UDim2.fromOffset(44, 650), Size = UDim2.fromOffset(500, 90), ZIndex = 3 })
	K.list(inc, "x", 8)
	for i, s in { { "revolver", "legendary" }, { "shirt", "epic" }, { "skull", "epic" }, { "sparkles", "rare" } } do
		K.slot(inc, { Size = UDim2.fromOffset(90, 90), LayoutOrder = i }, i == 1 and { art = s[1], rarity = s[2] } or { icon = s[1], rarity = s[2], iconColor = K.RARITY[s[2]][1] })
	end
	local buy = K.new("Frame", feat, { Position = UDim2.fromOffset(44, 760), Size = UDim2.fromOffset(700, 60) })
	K.list(buy, "x", 18, "Left", "Center")
	K.button(buy, "1,800", "primary", { LayoutOrder = 0, Size = UDim2.fromOffset(220, 60) }, { icon = "gem", textSize = 24, under = T.surface2 })
	K.text(buy, "<s>2,600</s>", "mono", { TextSize = 16, TextColor3 = T.faint, LayoutOrder = 1 })
	K.pill(buy, "Save 31%", T.good, { LayoutOrder = 2 }, true)
	local timer = K.new("Frame", feat, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -40, 0, 40), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X })
	K.list(timer, "x", 8, "Right", "Center")
	K.icon(timer, "clock", 18, T.text, { LayoutOrder = 0 }); K.text(timer, "2d 21h 04m", "mono", { TextSize = 16, LayoutOrder = 1 })

	-- rotating offers
	local side = K.new("Frame", root, { Position = UDim2.fromOffset(1180, 124), Size = UDim2.fromOffset(684, 860) })
	K.header(side, "Daily rotation", { Size = UDim2.new(1, 0, 0, 22) }, "New in 09:12:44")
	local offers = K.new("Frame", side, { Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 470) })
	K.grid(offers, Vector2.new(336, 229), 12)
	for i, o in { { "launcher", "RK-7  Desert", "epic", "950" }, { "grenade", "Frag  Tiger", "rare", "400" }, { nil, "Ghillie vest", "epic", "1,100", "shirt" }, { nil, "Tracer rounds", "legendary", "1,500", "flame" } } do
		local r = K.RARITY[o[3]][1]
		local c = K.slot(offers, { LayoutOrder = i }, { rarity = o[3] })
		if o[1] then K.art(c, o[1], { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(168, 18), Size = UDim2.fromOffset(250, 110), ZIndex = 3 })
		else K.icon(c, o[5], 64, r, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(168, 36), ZIndex = 3 }) end
		K.text(c, K.RARITY[o[3]][2], "label", { Position = UDim2.fromOffset(18, 140), TextColor3 = r, TextSize = 11, ZIndex = 3 })
		K.text(c, string.upper(o[2]), "title", { Position = UDim2.fromOffset(18, 156), TextSize = 22, ZIndex = 3 })
		local p = K.new("Frame", c, { Position = UDim2.fromOffset(18, 190), Size = UDim2.fromOffset(200, 24), ZIndex = 3 })
		K.list(p, "x", 6, "Left", "Center")
		K.icon(p, "gem", 16, T.accent2, { LayoutOrder = 0, ZIndex = 3 }); K.text(p, o[4], "mono", { TextSize = 16, LayoutOrder = 1, ZIndex = 3 })
	end
	K.header(side, "Gems", { Position = UDim2.fromOffset(0, 530), Size = UDim2.new(1, 0, 0, 22) })
	local packs = K.new("Frame", side, { Position = UDim2.fromOffset(0, 566), Size = UDim2.new(1, 0, 0, 290) })
	K.grid(packs, Vector2.new(221, 140), 10)
	for i, p in { { "500", "R$ 99" }, { "1,100", "R$ 199", "+10%" }, { "2,400", "R$ 399", "+20%" }, { "5,000", "R$ 799", "+25%" }, { "12,000", "R$ 1,699", "Best value" }, { "Starter", "R$ 149", "Once" } } do
		local c = K.panel(packs, { LayoutOrder = i }, { alpha = 0.15, chamfer = 10, corners = "tl br", borderColor = i == 5 and T.accent or nil, borderAlpha = i == 5 and 0.1 or 0.88 })
		local gems = math.min(i, 5)
		for j = 1, gems do K.icon(c, "gem", 22 + j * 2, T.accent2, { Position = UDim2.fromOffset(16 + (j - 1) * 14, 18 - j), Rotation = (j - 3) * 8 }) end
		if p[3] then K.pill(c, p[3], i == 5 and T.accent or T.good, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 14) }, true) end
		K.text(c, p[1], "display", { TextSize = 26, Position = UDim2.fromOffset(16, 64) })
		K.text(c, p[2], "mono", { TextSize = 14, Position = UDim2.fromOffset(16, 104), TextColor3 = T.muted })
	end
	return g
end
