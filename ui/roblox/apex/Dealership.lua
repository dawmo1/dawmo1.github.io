-- APEX / Dealership: filterable car catalogue with a featured offer and a purchase confirm panel.
return function(K, parent: Instance, P: { [string]: any })
	K.use("apex")
	local T = K.T
	local g, root = K.screen("APEX_Dealership", parent)
	K.backdrop(root, { glow = T.accent2, glowAt = UDim2.fromScale(0.3, 0.45), glowSize = 1500, glowStrength = 0.86 })
	K.topbar(root, "APEX", { "Garage", "Race", "Dealership", "Events", "Club" }, 3,
		{ { "coins", "2,480,150", T.warn, false }, { "gem", "1,240", T.accent2, true } }, P)

	-- featured offer banner
	local feat = K.panel(root, { Position = UDim2.fromOffset(56, 124), Size = UDim2.fromOffset(1120, 330), ClipsDescendants = true }, { alpha = 0.05, color = T.surface2 })
	local tint = K.new("Frame", feat, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BackgroundColor3 = T.accent2 })
	K.grad(tint, { T.accent2, T.accent2 }, 0, { 0.82, 1 }); K.corner(tint, T.radius)
	K.art(feat, "donk", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 10, 0.55, 0), Size = UDim2.fromOffset(640, 340), ZIndex = 2 })
	K.pill(feat, "Featured  ·  ends in 2d 14h", T.accent2, { Position = UDim2.fromOffset(40, 36) })
	K.text(feat, "BOULEVARD '78", "display", { TextSize = 50, Position = UDim2.fromOffset(40, 78) })
	K.text(feat, "Wire-spoke 26s, chrome egg-crate grille and a 7.4L big-block.\nThe slow-roll king of the boulevard.", "body", { Position = UDim2.fromOffset(40, 150), TextColor3 = T.muted, TextWrapped = true, Size = UDim2.fromOffset(470, 0), AutomaticSize = Enum.AutomaticSize.Y })
	local pr = K.new("Frame", feat, { Position = UDim2.fromOffset(40, 236), Size = UDim2.fromOffset(500, 60) })
	K.list(pr, "x", 18, "Left", "Center")
	K.button(pr, "Buy", "primary", { LayoutOrder = 0, Size = UDim2.fromOffset(180, 56) }, { icon = "cart" })
	local price = K.new("Frame", pr, { Size = UDim2.fromOffset(0, 56), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 1 })
	K.text(price, "<s>480,000</s>", "mono", { TextSize = 14, TextColor3 = T.faint, Position = UDim2.fromOffset(0, 2) })
	local now = K.new("Frame", price, { Position = UDim2.fromOffset(0, 22), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X })
	K.list(now, "x", 8, "Left", "Center")
	K.icon(now, "coins", 20, T.warn, { LayoutOrder = 0 }); K.text(now, "360,000", "display", { TextSize = 22, LayoutOrder = 1 })
	K.pill(pr, "−25%", T.good, { LayoutOrder = 2 }, true)

	-- side: daily deals
	local deals = K.panel(root, { Position = UDim2.fromOffset(1196, 124), Size = UDim2.fromOffset(668, 330) }, { alpha = 0.2 })
	K.pad(deals, 22, 24)
	K.header(deals, "Daily deals", { Size = UDim2.new(1, 0, 0, 22) }, "Refresh in 06:42:10")
	local dl = K.new("Frame", deals, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40) })
	K.grid(dl, Vector2.new(198, 238), 12)
	for i, d in { { "paint", "Chrome wrap", "Cosmetic", "rare", "45 gems" }, { "dial", "Track slicks", "Tires · +0.4 grip", "epic", "120,000" }, { "flame", "Twin nitro", "Nitro · +15%", "legendary", "290 gems" } } do
		local c = K.slot(dl, { LayoutOrder = i }, { rarity = d[4] })
		K.icon(c, d[1], 46, K.RARITY[d[4]][1], { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(99, 34), ZIndex = 3 })
		K.text(c, d[2], "title", { TextSize = 18, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(99, 106), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
		K.text(c, d[3], "small", { TextSize = 13, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(99, 134), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
		local b = K.button(c, d[5], "secondary", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(166, 40), ZIndex = 3 }, { icon = string.find(d[5], "gems") and "gem" or "coins", iconSize = 16, textSize = 15 })
	end

	-- catalogue
	local tabs = K.new("Frame", root, { Position = UDim2.fromOffset(56, 478), Size = UDim2.fromOffset(1808, 48) })
	K.tabs(tabs, { "All", "Hypercars", "Muscle", "Lowriders", "Off-road", "Classics" }, 1, { Size = UDim2.fromOffset(1000, 48) }, { size = 16 })
	local sort = K.new("Frame", tabs, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(0, 48), AutomaticSize = Enum.AutomaticSize.X })
	K.list(sort, "x", 10, "Right", "Center")
	local search = K.panel(sort, { Size = UDim2.fromOffset(260, 40), LayoutOrder = 0 }, { alpha = 0.3, sheen = false })
	K.icon(search, "search", 18, T.muted, { Position = UDim2.fromOffset(14, 11) })
	K.text(search, "Search 24 cars", "small", { Position = UDim2.fromOffset(42, 0), Size = UDim2.fromOffset(0, 40) })
	K.button(sort, "Price ↓", "secondary", { LayoutOrder = 1, Size = UDim2.fromOffset(140, 40) }, { icon = "sliders", iconSize = 16, textSize = 15 })
	K.new("Frame", tabs, { BackgroundTransparency = 0.9, BackgroundColor3 = T.text, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0) })

	local grid = K.new("Frame", root, { Position = UDim2.fromOffset(56, 546), Size = UDim2.fromOffset(1808, 440) })
	K.grid(grid, Vector2.new(442, 210), 13)
	local cat = {
		{ "supercar", "Veloce R", "S1", T.accent, "Owned", nil, true },
		{ "mudrunner", "Muddog 8", "B", T.good, "Owned", nil, true },
		{ "donk", "Boulevard '78", "A", T.accent2, "360,000", "−25%" },
		{ "supercar", "Veloce R  Track", "X", T.bad, "Lv 40", nil, false, true },
		{ "mudrunner", "Muddog 8  Baja", "A", T.accent2, "295,000" },
		{ "donk", "Boulevard  Gold", "S1", T.accent, "1,450 gems" },
		{ "supercar", "Veloce  Spyder", "S2", T.warn, "2,100,000" },
		{ "mudrunner", "Muddog  Rally", "A", T.accent2, "Club rank 5", nil, false, true },
	}
	for i, c in cat do
		local card = K.panel(grid, { LayoutOrder = i, ClipsDescendants = true }, { alpha = 0.18, borderColor = i == 3 and T.accent2 or nil, borderAlpha = i == 3 and 0 or 0.9, borderThick = i == 3 and 2 or 1 })
		K.art(card, c[1], { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.42, 0), Size = UDim2.fromOffset(270, 150), ImageTransparency = c[8] and 0.55 or 0, ImageColor3 = c[8] and Color3.fromRGB(120, 120, 130) or Color3.new(1, 1, 1) })
		K.pill(card, c[3], c[4], { Position = UDim2.fromOffset(20, 20) }, true)
		K.text(card, c[2], "title", { TextSize = 20, Position = UDim2.fromOffset(20, 56) })
		local foot = K.new("Frame", card, { Position = UDim2.new(0, 20, 1, -50), Size = UDim2.new(1, -40, 0, 34) })
		K.list(foot, "x", 8, "Left", "Center")
		if c[7] then
			K.icon(foot, "check", 18, T.good, { LayoutOrder = 0 }); K.text(foot, "Owned", "label", { TextColor3 = T.good, LayoutOrder = 1 })
		elseif c[8] then
			K.icon(foot, "lock", 18, T.muted, { LayoutOrder = 0 }); K.text(foot, c[5], "label", { TextColor3 = T.muted, LayoutOrder = 1 })
		else
			K.icon(foot, string.find(c[5], "gems") and "gem" or "coins", 18, string.find(c[5], "gems") and T.accent2 or T.warn, { LayoutOrder = 0 })
			K.text(foot, string.gsub(c[5], " gems", ""), "mono", { TextSize = 16, LayoutOrder = 1 })
			if c[6] then K.pill(foot, c[6], T.good, { LayoutOrder = 2 }, true) end
		end
	end
	return g
end
