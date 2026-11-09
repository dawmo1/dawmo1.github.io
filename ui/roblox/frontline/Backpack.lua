-- FRONTLINE / Backpack: in-match bag with weight limit, equipment paper-doll, grid with a dragged item, and a compare tooltip.
return function(K, parent: Instance, P: { [string]: any })
	K.use("frontline")
	local T = K.T
	local g, root = K.screen("FL_Backpack", parent)
	K.backdrop(root, { alpha = 0.12, glow = T.accent, glowAt = UDim2.fromScale(0.5, 0.5), glowSize = 1600, glowStrength = 0.93 })

	K.text(root, "BACKPACK", "display", { TextSize = 40, Position = UDim2.fromOffset(96, 60) })
	K.tabs(root, { "Backpack", "Stash", "Crafting" }, 1, { Position = UDim2.fromOffset(96, 110), Size = UDim2.fromOffset(600, 48) }, { size = 16 })

	-- equipment column
	local eq = K.panel(root, { Position = UDim2.fromOffset(96, 180), Size = UDim2.fromOffset(420, 780) }, { alpha = 0.2, chamfer = 16, corners = "tl br" })
	K.pad(eq, 24)
	K.header(eq, "Equipped", { Size = UDim2.new(1, 0, 0, 22) })
	if P.viewport then P.viewport(K.new("Frame", eq, { Position = UDim2.fromOffset(84, 40), Size = UDim2.fromOffset(204, 440), Name = "AvatarHolder" }), 10, 1.05)
	else K.new("ImageLabel", eq, { Image = P.fullbody or "", Position = UDim2.fromOffset(60, 40), Size = UDim2.fromOffset(250, 420), ScaleType = Enum.ScaleType.Fit }) end
	local function gear(x: number, y: number, icon: string, name: string, rarity: string?)
		local s = K.slot(eq, { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(84, 84) }, { icon = icon, rarity = rarity, iconColor = rarity and K.RARITY[rarity][1] or T.faint, iconSize = 30 })
		K.text(eq, name, "label", { Position = UDim2.fromOffset(x, y + 88), TextSize = 10, TextColor3 = T.muted })
	end
	gear(0, 60, "user", "Helmet", "rare"); gear(288, 60, "shirt", "Vest", "epic")
	gear(0, 210, "backpack", "Bag", "uncommon"); gear(288, 210, "hand", "Gloves")
	gear(0, 360, "box", "Utility"); gear(288, 360, "shield", "Plates", "rare")
	local wt = K.new("Frame", eq, { Position = UDim2.fromOffset(0, 500), Size = UDim2.new(1, 0, 0, 60) })
	K.text(wt, "Carry weight", "label", { TextColor3 = T.text })
	K.text(wt, '24.6<font color="#959A86"> / 30 kg</font>', "mono", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), TextSize = 15 })
	K.bar(wt, { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.fromOffset(0, 30) }, 0.82, T.warn, { round = false, ticks = 6 })
	K.text(wt, "Over 25 kg: sprint speed −8%", "small", { Position = UDim2.fromOffset(0, 46), TextSize = 13, TextColor3 = T.warn })
	local quick = K.new("Frame", eq, { Position = UDim2.fromOffset(0, 600), Size = UDim2.new(1, 0, 0, 120) })
	K.header(quick, "Quick slots", { Size = UDim2.new(1, 0, 0, 22) })
	local qs = K.new("Frame", quick, { Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 84) })
	K.list(qs, "x", 8)
	for i, q in { { "heart", "3", "uncommon", "×3" }, { "zap", "4", "rare", "×1" }, { "grenade", "5", "rare", "×2", true }, { "plus", "6" } } do
		K.slot(qs, { Size = UDim2.fromOffset(84, 84), LayoutOrder = i }, { icon = not q[5] and q[1] or nil, art = q[5] and q[1] or nil, key = q[2], rarity = q[3], count = q[4], iconColor = q[3] and K.RARITY[q[3]][1] or T.faint, iconSize = 30 })
	end

	-- grid
	local bag = K.panel(root, { Position = UDim2.fromOffset(540, 180), Size = UDim2.fromOffset(820, 780) }, { alpha = 0.2 })
	K.pad(bag, 24)
	K.header(bag, "Bag", { Size = UDim2.new(1, 0, 0, 22) }, "23 / 48 slots")
	local grid = K.new("Frame", bag, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40) })
	K.grid(grid, Vector2.new(90, 90), 6, 8)
	local items = {
		{ art = "revolver", rarity = "legendary", equipped = true }, { art = "launcher", rarity = "epic", equipped = true }, { art = "grenade", rarity = "rare", count = "2" },
		{ icon = "heart", rarity = "uncommon", count = "3" }, { icon = "box", rarity = "common", count = "120" }, { icon = "box", rarity = "common", count = "36" }, { icon = "zap", rarity = "rare" },
		{ icon = "sparkles", rarity = "uncommon", count = "2" }, { icon = "crosshair", rarity = "rare" }, { icon = "target", rarity = "epic", selected = true }, { icon = "hand", rarity = "uncommon" },
		{ icon = "key" }, { icon = "map", rarity = "common" }, { icon = "fuel", rarity = "common", count = "1" }, { icon = "wrench", rarity = "uncommon" }, { icon = "bomb", rarity = "epic" },
		{ icon = "medal", rarity = "legendary" }, { icon = "ticket", rarity = "rare", count = "4" }, { icon = "eye", rarity = "rare" }, { icon = "bell", rarity = "common" }, { icon = "gift", rarity = "mythic" },
		{ icon = "coins", rarity = "common", count = "880" }, { icon = "shield", rarity = "rare" },
	}
	for i = 1, 56 do
		local it = items[i]
		if it then
			if it.icon == "key" then it.icon = "lock" end
			it.iconColor = it.rarity and K.RARITY[it.rarity][1] or T.muted
			it.iconSize = 34
			K.slot(grid, { LayoutOrder = i }, it)
		else
			K.slot(grid, { LayoutOrder = i, BackgroundTransparency = 0.6 }, i > 48 and { locked = true } or nil)
		end
	end
	-- an item mid-drag, lifted and tilted with a drop shadow
	local sh = K.new("Frame", root, { Position = UDim2.fromOffset(1012, 668), Size = UDim2.fromOffset(96, 96), BackgroundTransparency = 0.55, BackgroundColor3 = Color3.new(0, 0, 0), Rotation = -6, ZIndex = 29 })
	local drag = K.slot(root, { Position = UDim2.fromOffset(1000, 654), Size = UDim2.fromOffset(96, 96), Rotation = -6, ZIndex = 30, BackgroundTransparency = 0 }, { icon = "bomb", rarity = "epic", iconColor = K.RARITY.epic[1], iconSize = 36, selected = true })
	for _, d in drag:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex += 30 end end
	K.icon(root, "pointer", 30, T.text, { Position = UDim2.fromOffset(1060, 714), ZIndex = 40 })

	-- tooltip for the selected scope, with compare vs equipped
	local tip = K.panel(root, { Position = UDim2.fromOffset(1384, 180), Size = UDim2.fromOffset(440, 780) }, { alpha = 0.05, color = T.surface2, chamfer = 16, corners = "tr bl", borderColor = K.RARITY.epic[1], borderAlpha = 0.4 })
	local band = K.new("Frame", tip, { Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 0, BackgroundColor3 = K.RARITY.epic[1] })
	K.grad(band, { K.RARITY.epic[1], K.RARITY.epic[1] }, 90, { 0.7, 1 })
	K.icon(tip, "target", 96, K.RARITY.epic[1], { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(220, 46) })
	K.pad(tip, 0, 26)
	K.pill(tip, "Epic  ·  Optic", K.RARITY.epic[1], { Position = UDim2.fromOffset(0, 214) }, true)
	K.text(tip, "HOLOSIGHT X4", "display", { TextSize = 32, Position = UDim2.fromOffset(0, 250) })
	K.text(tip, "Variable 2–4× zoom with an amber reticle that\nstays readable against bright sky.", "body", { Position = UDim2.fromOffset(0, 296), TextColor3 = T.muted, TextSize = 16 })
	K.header(tip, "Compared to Red dot", { Position = UDim2.fromOffset(0, 362), Size = UDim2.new(1, 0, 0, 22) })
	local cmp = K.new("Frame", tip, { Position = UDim2.fromOffset(0, 398), Size = UDim2.new(1, 0, 0, 200) })
	K.list(cmp, "y", 6)
	for i, s in { { "Zoom", "4.0×", 0.8, nil, "+2.5×" }, { "ADS speed", "0.28 s", 0.55, nil, "−0.06 s", T.bad }, { "Range", "48 m", 0.7, nil, "+10 m" }, { "Sway", "Low", 0.3 } } do
		K.stat(cmp, s[1], s[2], s[3], { order = i, delta = s[5], deltaColor = s[6], color = K.RARITY.epic[1] })
	end
	local actions = K.new("Frame", tip, { Position = UDim2.new(0, 0, 1, -150), Size = UDim2.new(1, 0, 0, 130) })
	K.list(actions, "y", 10)
	K.button(actions, "Equip on Magnum", "primary", { Size = UDim2.new(1, 0, 0, 56), LayoutOrder = 0 }, { key = "F", textSize = 18, under = T.surface2 })
	local row = K.new("Frame", actions, { Size = UDim2.new(1, 0, 0, 52), LayoutOrder = 1 })
	K.list(row, "x", 10)
	K.button(row, "Drop", "secondary", { Size = UDim2.new(0.5, -5, 1, 0), LayoutOrder = 0 }, { key = "X", textSize = 16, under = T.surface2 })
	K.button(row, "Scrap", "secondary", { Size = UDim2.new(0.5, -5, 1, 0), LayoutOrder = 1 }, { icon = "wrench", iconSize = 16, textSize = 16, under = T.surface2 })
	K.hints(root, { { "Tab", "Close" }, { "RMB", "Quick move" }, { "Shift", "Split stack" } }, {})
	return g
end
