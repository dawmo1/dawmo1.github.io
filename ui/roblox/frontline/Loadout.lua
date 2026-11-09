-- FRONTLINE / Loadout: operator preview (the player's real avatar), loadout slots, selected weapon stats + attachments.
-- P.viewport (optional) is a ViewportFrame builder that puts the posed avatar into a given frame.
return function(K, parent: Instance, P: { [string]: any })
	K.use("frontline")
	local T = K.T
	local g, root = K.screen("FL_Loadout", parent)
	K.backdrop(root, { glow = T.accent, glowAt = UDim2.fromScale(0.2, 0.62), glowSize = 1200, glowStrength = 0.86, floor = T.surface2 })
	K.topbar(root, "FRONTLINE", { "Play", "Loadout", "Armory", "Store", "Pass" }, 2,
		{ { "coins", "84,210", T.accent, false }, { "gem", "2,400", T.accent2, true } }, P)

	-- operator
	local op = K.new("Frame", root, { Position = UDim2.fromOffset(56, 120), Size = UDim2.fromOffset(620, 880), Name = "Operator" })
	if P.viewport then P.viewport(K.new("Frame", op, { Position = UDim2.fromOffset(0, 110), Size = UDim2.new(1, 0, 1, -110), Name = "AvatarHolder", ZIndex = 2 })) else K.new("ImageLabel", op, { Image = P.fullbody or "", Size = UDim2.fromScale(1, 0.9), ScaleType = Enum.ScaleType.Fit }) end
	K.text(op, "OPERATOR", "label", { Position = UDim2.fromOffset(0, 0), TextColor3 = T.accent })
	K.text(op, string.upper(P.name), "display", { Position = UDim2.fromOffset(0, 18), TextSize = 44 })
	local tagrow = K.new("Frame", op, { Position = UDim2.fromOffset(0, 80), Size = UDim2.fromOffset(500, 24) })
	K.list(tagrow, "x", 8)
	K.pill(tagrow, "Lv 47", T.accent, { LayoutOrder = 0 }, true)
	K.pill(tagrow, "Assault", T.text, { LayoutOrder = 1 })
	K.pill(tagrow, "Prestige II", T.accent2, { LayoutOrder = 2 })
	local base = K.new("Frame", op, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 690), Size = UDim2.fromOffset(440, 60), BackgroundTransparency = 0, BackgroundColor3 = T.accent })
	K.corner(base, 999); K.grad(base, { T.accent, T.accent }, 0, NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.7), NumberSequenceKeypoint.new(1, 1) }))
	local ring = K.new("Frame", op, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 690), Size = UDim2.fromOffset(380, 44) })
	K.corner(ring, 999); K.stroke(ring, T.accent, 2, 0.4)

	-- loadout slots
	local slots = K.new("Frame", root, { Position = UDim2.fromOffset(700, 128), Size = UDim2.fromOffset(520, 860) })
	K.list(slots, "y", 10)
	K.header(slots, "Loadout  A", { LayoutOrder = 0 }, "Slot 1 / 5")
	local function slot(order: number, kind: string, name: string, art: string?, icon: string?, rarity: string, lvl: string, sel: boolean?)
		local h = sel and 150 or 118
		local r = K.RARITY[rarity][1]
		local s = K.panel(slots, { Size = UDim2.new(1, 0, 0, h), LayoutOrder = order, ClipsDescendants = true }, { alpha = sel and 0.02 or 0.2, color = sel and T.raised or T.surface,
			borderColor = sel and T.accent or nil, borderAlpha = sel and 0 or 0.88, borderThick = sel and 2 or 1, chamfer = 14, corners = "tl br" })
		K.new("Frame", s, { BackgroundTransparency = 0, BackgroundColor3 = r, Size = UDim2.new(0, 4, 1, 0), Name = "Rarity" })
		local glow = K.new("Frame", s, { Size = UDim2.fromScale(0.6, 1), Position = UDim2.fromScale(0.4, 0), BackgroundTransparency = 0, BackgroundColor3 = r })
		K.grad(glow, { r, r }, 0, { 1, 0.8 })
		K.text(s, kind, "label", { Position = UDim2.fromOffset(22, 16), TextColor3 = sel and T.accent or T.muted })
		K.text(s, string.upper(name), "title", { Position = UDim2.fromOffset(22, 36), TextSize = sel and 30 or 24 })
		K.text(s, K.RARITY[rarity][2] .. "  ·  " .. lvl, "label", { Position = UDim2.fromOffset(22, sel and 78 or 70), TextColor3 = r, TextSize = 12 })
		if art then K.art(s, art, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(sel and 250 or 210, h - 24), ZIndex = 2 }) end
		if icon then K.icon(s, icon, 52, r, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -60, 0.5, 0), ZIndex = 2 }) end
		if sel then K.key(s, "1", { Position = UDim2.new(0, 22, 1, -40) }) end
	end
	slot(1, "Primary", "RK-7 Launcher", "launcher", nil, "epic", "Lv 12")
	slot(2, "Secondary", "Magnum .44", "revolver", nil, "legendary", "Lv 30", true)
	slot(3, "Lethal", "Frag M67", "grenade", nil, "rare", "×2")
	slot(4, "Tactical", "Flashbang", nil, "sparkles", "uncommon", "×2")
	local perks = K.new("Frame", slots, { Size = UDim2.new(1, 0, 0, 100), LayoutOrder = 5 })
	K.list(perks, "x", 10)
	for i, p in { { "shield", "Tough", "rare" }, { "eye", "Tracker", "epic" }, { "zap", "Quick fix", "common" } } do
		local c = K.panel(perks, { Size = UDim2.new(1 / 3, -7, 1, 0), LayoutOrder = i }, { alpha = 0.2, chamfer = 10, corners = "tl br" })
		K.icon(c, p[1], 28, K.RARITY[p[3]][1], { Position = UDim2.fromOffset(18, 18) })
		K.text(c, "Perk " .. i, "label", { Position = UDim2.fromOffset(18, 56), TextSize = 11 })
		K.text(c, string.upper(p[2]), "title", { Position = UDim2.fromOffset(18, 70), TextSize = 18 })
	end

	-- selected weapon detail
	local det = K.panel(root, { Position = UDim2.fromOffset(1244, 128), Size = UDim2.fromOffset(620, 760) }, { alpha = 0.15, chamfer = 18, corners = "tr bl" })
	K.pad(det, 26, 28)
	K.text(det, "MAGNUM .44", "display", { TextSize = 38 })
	K.text(det, "Double-action revolver  ·  6 rounds  ·  ventilated rib", "body", { Position = UDim2.fromOffset(0, 54), TextColor3 = T.muted, TextSize = 17 })
	K.art(det, "revolver", { Position = UDim2.fromOffset(40, 96), Size = UDim2.fromOffset(480, 250) })
	local st = K.new("Frame", det, { Position = UDim2.fromOffset(0, 366), Size = UDim2.new(1, 0, 0, 230) })
	K.list(st, "y", 6)
	for i, s in { { "Damage", "92", 0.92, nil, nil }, { "Fire rate", "140 rpm", 0.32 }, { "Range", "38 m", 0.58, 0.66, "+8" }, { "Mobility", "84", 0.84 }, { "Control", "41", 0.41, 0.5, "+9" } } do
		K.stat(st, s[1], s[2], s[3], { order = i, preview = s[4], delta = s[5], ticks = 10 })
	end
	K.header(det, "Attachments", { Position = UDim2.fromOffset(0, 604) }, "3 / 5")
	local att = K.new("Frame", det, { Position = UDim2.fromOffset(0, 636), Size = UDim2.new(1, 0, 0, 72) })
	K.list(att, "x", 8)
	for i, a in { { "crosshair", "rare" }, { "target", "epic" }, { "hand", "uncommon" }, { "plus" }, { "lock" } } do
		K.slot(att, { Size = UDim2.fromOffset(104, 72), LayoutOrder = i }, { icon = a[1], rarity = a[2], iconColor = a[2] and K.RARITY[a[2]][1] or T.faint, iconSize = 28 })
	end

	local act = K.new("Frame", root, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -56, 1, -44), Size = UDim2.fromOffset(0, 60), AutomaticSize = Enum.AutomaticSize.X })
	K.list(act, "x", 12, "Right", "Center")
	K.button(act, "Customize", "secondary", { LayoutOrder = 0, Size = UDim2.fromOffset(230, 56) }, { icon = "wrench", key = "C" })
	K.button(act, "Ready up", "primary", { LayoutOrder = 1, Size = UDim2.fromOffset(280, 60) }, { icon = "play", key = "Enter", textSize = 22 })
	return g
end
