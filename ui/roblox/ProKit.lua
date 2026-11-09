--!strict
-- ProKit: the design system behind the racing (APEX) and shooter (FRONTLINE) UI kits.
-- Every screen is laid out on a 1920x1080 canvas and scaled to the player's screen with one UIScale,
-- so spacing, type and strokes stay pixel-exact at any resolution.

local K = {}

-- Lucide icon atlas (ISC licence), 128px cells; set K.ATLAS to the uploaded asset id before building
K.ATLAS = "rbxassetid://0"
K.RADIAL = "rbxassetid://83055659488836" -- soft radial falloff used for backdrop glows
K.CORNER = "rbxassetid://95256345496103" -- right triangle filling the top-left corner, used for chamfers
K.ICON = {
	settings = { 0, 0 }, x = { 128, 0 }, lock = { 256, 0 }, coins = { 384, 0 }, gem = { 512, 0 }, cart = { 640, 0 }, backpack = { 768, 0 }, trophy = { 896, 0 },
	flag = { 0, 128 }, timer = { 128, 128 }, gauge = { 256, 128 }, zap = { 384, 128 }, wrench = { 512, 128 }, paint = { 640, 128 }, crosshair = { 768, 128 }, skull = { 896, 128 },
	heart = { 0, 256 }, shield = { 128, 256 }, star = { 256, 256 }, check = { 384, 256 }, left = { 512, 256 }, right = { 640, 256 }, gift = { 768, 256 }, calendar = { 896, 256 },
	volume = { 0, 384 }, monitor = { 128, 384 }, gamepad = { 256, 384 }, keyboard = { 384, 384 }, user = { 512, 384 }, users = { 640, 384 }, map = { 768, 384 }, box = { 896, 384 },
	crown = { 0, 512 }, sparkles = { 128, 512 }, flame = { 256, 512 }, target = { 384, 512 }, bomb = { 512, 512 }, swords = { 640, 512 }, medal = { 768, 512 }, clock = { 896, 512 },
	undo = { 0, 640 }, info = { 128, 640 }, search = { 256, 640 }, sliders = { 384, 640 }, home = { 512, 640 }, play = { 640, 640 }, car = { 768, 640 }, fuel = { 896, 640 },
	dial = { 0, 768 }, pointer = { 128, 768 }, hand = { 256, 768 }, eye = { 384, 768 }, bell = { 512, 768 }, award = { 640, 768 }, ticket = { 768, 768 }, shirt = { 896, 768 },
	plus = { 0, 896 }, minus = { 128, 896 }, arrow = { 256, 896 }, trend = { 384, 896 }, signal = { 512, 896 }, wifi = { 640, 896 }, mic = { 768, 896 }, headphones = { 896, 896 },
}
K.IMG = {} :: { [string]: string } -- rendered model art (car and weapon renders), filled in by the build script

local function rgb(h: number): Color3
	return Color3.fromRGB(bit32.rshift(h, 16) % 256, bit32.rshift(h, 8) % 256, h % 256)
end
K.rgb = rgb

local function fam(name: string, w: Enum.FontWeight?): Font
	return Font.new("rbxasset://fonts/families/" .. name .. ".json", w or Enum.FontWeight.Regular)
end

type Theme = {
	bg: Color3, surface: Color3, surface2: Color3, raised: Color3, text: Color3, muted: Color3, faint: Color3,
	accent: Color3, accentInk: Color3, accent2: Color3, good: Color3, warn: Color3, bad: Color3,
	radius: number, chamfer: number, display: Font, title: Font, body: Font, bodyBold: Font, mono: Font, caps: boolean, track: number,
}

K.THEMES = {
	-- APEX: night-garage racing. Glass panels, orange-red brand accent, cyan telemetry, wide techno numerals
	apex = {
		bg = rgb(0x06080D), surface = rgb(0x0E131D), surface2 = rgb(0x151C2A), raised = rgb(0x1D2638),
		text = rgb(0xF3F6FB), muted = rgb(0x8C97AD), faint = rgb(0x4A5468),
		accent = rgb(0xFF4B1F), accentInk = rgb(0xFFFFFF), accent2 = rgb(0x2FD8F2), good = rgb(0x3DDC84), warn = rgb(0xFFC23D), bad = rgb(0xFF3B4E),
		radius = 10, chamfer = 0,
		display = fam("Michroma"), title = fam("TitilliumWeb", Enum.FontWeight.Bold), body = fam("TitilliumWeb", Enum.FontWeight.SemiBold),
		bodyBold = fam("TitilliumWeb", Enum.FontWeight.Bold), mono = fam("TitilliumWeb", Enum.FontWeight.Bold), caps = true, track = 0,
	} :: Theme,
	-- FRONTLINE: tactical shooter. Matte olive-charcoal, chamfered plates, signal-yellow accent, condensed caps
	frontline = {
		bg = rgb(0x0A0B09), surface = rgb(0x131510), surface2 = rgb(0x1B1E17), raised = rgb(0x262A20),
		text = rgb(0xEEF0E6), muted = rgb(0x959A86), faint = rgb(0x50544A),
		accent = rgb(0xF2C230), accentInk = rgb(0x14140F), accent2 = rgb(0x8FD6B4), good = rgb(0x7BD88F), warn = rgb(0xF29B30), bad = rgb(0xE5484D),
		radius = 2, chamfer = 12,
		display = fam("Oswald", Enum.FontWeight.Bold), title = fam("Oswald", Enum.FontWeight.SemiBold), body = fam("RobotoCondensed", Enum.FontWeight.Regular),
		bodyBold = fam("RobotoCondensed", Enum.FontWeight.Bold), mono = fam("RobotoMono", Enum.FontWeight.Medium), caps = true, track = 0,
	} :: Theme,
}
K.T = K.THEMES.apex

-- rarity tiers shared by both kits
K.RARITY = {
	common = { rgb(0x9AA3B2), "COMMON" }, uncommon = { rgb(0x4ED07A), "UNCOMMON" }, rare = { rgb(0x3D9BFF), "RARE" },
	epic = { rgb(0xB15CFF), "EPIC" }, legendary = { rgb(0xFFB524), "LEGENDARY" }, mythic = { rgb(0xFF3D5A), "MYTHIC" },
}

function K.use(name: string)
	K.T = (K.THEMES :: any)[name]
end

local function apply(inst: Instance, props: { [string]: any }?)
	if props then for k, v in props do (inst :: any)[k] = v end end
end
K.apply = apply

function K.new(class: string, parent: Instance?, props: { [string]: any }?): any
	local i = Instance.new(class)
	if i:IsA("GuiObject") then (i :: any).BorderSizePixel = 0 end
	if i:IsA("Frame") or i:IsA("ImageLabel") or i:IsA("TextLabel") or i:IsA("ScrollingFrame") then (i :: any).BackgroundTransparency = 1 end
	apply(i, props)
	i.Parent = parent
	return i
end

-- ScreenGui with a 1920x1080 "Root" canvas scaled to fit the viewport
function K.screen(name: string, parent: Instance, viewport: Vector2?): (ScreenGui, Frame)
	local old = parent:FindFirstChild(name); if old then old:Destroy() end
	local g = K.new("ScreenGui", nil, { Name = name, ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	local root = K.new("Frame", g, { Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1920, 1080) })
	local vp = viewport or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
	K.new("UIScale", root, { Scale = math.min(vp.X / 1920, vp.Y / 1080) })
	g.Parent = parent
	return g, root
end

function K.corner(p: Instance, r: number?) return K.new("UICorner", p, { CornerRadius = UDim.new(0, r or K.T.radius) }) end
function K.pad(p: Instance, t: number, r: number?, b: number?, l: number?)
	local R, B, L = r or t, b or t, l or r or t
	-- padding also moves chamfer corners inward; push them back out to the plate's real corners
	for _, c in p:GetChildren() do
		if c.Name == "Chamfer" and c:IsA("GuiObject") then
			local a = c.AnchorPoint
			c.Position = UDim2.new(a.X, a.X == 0 and -L or R, a.Y, a.Y == 0 and -t or B)
		end
	end
	return K.new("UIPadding", p, { PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, R), PaddingBottom = UDim.new(0, B), PaddingLeft = UDim.new(0, L) })
end
function K.stroke(p: Instance, color: Color3?, thick: number?, transp: number?)
	return K.new("UIStroke", p, { Color = color or K.T.text, Thickness = thick or 1, Transparency = transp or 0.9, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
function K.grad(p: Instance, seq: any, rot: number?, transp: any?)
	local g = K.new("UIGradient", p, { Rotation = rot or 90 })
	g.Color = typeof(seq) == "ColorSequence" and seq or ColorSequence.new(seq[1], seq[2])
	if transp then g.Transparency = typeof(transp) == "NumberSequence" and transp or NumberSequence.new(transp[1], transp[2]) end
	return g
end
function K.list(p: Instance, dir: string, gap: number, align: string?, valign: string?)
	return K.new("UIListLayout", p, {
		FillDirection = dir == "x" and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical, Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = (Enum.HorizontalAlignment :: any)[align or "Left"], VerticalAlignment = (Enum.VerticalAlignment :: any)[valign or "Top"],
	})
end
function K.grid(p: Instance, cell: Vector2, gap: number, cols: number?)
	return K.new("UIGridLayout", p, { CellSize = UDim2.fromOffset(cell.X, cell.Y), CellPadding = UDim2.fromOffset(gap, gap), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirectionMaxCells = cols or 0 })
end

-- cut 45-degree corners off a plate with corner-triangle images in the backdrop colour (FRONTLINE plates);
-- images rather than rotated frames because ClipsDescendants does not clip rotated children
function K.chamfer(p: GuiObject, size: number?, corners: string?, under: Color3?)
	local s = size or K.T.chamfer
	if s <= 0 then return end
	local spots = { tl = { Vector2.new(0, 0), 0 }, tr = { Vector2.new(1, 0), 90 }, br = { Vector2.new(1, 1), 180 }, bl = { Vector2.new(0, 1), 270 } }
	for key in (corners or "tl br"):gmatch("%a+") do
		local a = spots[key]
		K.new("ImageLabel", p, { Name = "Chamfer", Image = K.CORNER, ImageColor3 = under or K.T.bg, AnchorPoint = a[1], Position = UDim2.fromScale(a[1].X, a[1].Y),
			Size = UDim2.fromOffset(s, s), Rotation = a[2], ZIndex = 50 })
	end
end

-- the standard surface: tinted fill, faint top highlight, hairline border
function K.panel(parent: Instance, props: { [string]: any }, opts: { [string]: any }?): Frame
	local o: any = opts or {}
	local f = K.new("Frame", parent, { BackgroundTransparency = o.alpha or 0.08, BackgroundColor3 = o.color or K.T.surface })
	apply(f, props)
	if K.T.chamfer == 0 or o.round then K.corner(f, o.radius) end
	if o.border ~= false then K.stroke(f, o.borderColor, o.borderThick, o.borderAlpha or 0.9) end
	if o.sheen ~= false then K.grad(f, { Color3.new(1, 1, 1), Color3.fromRGB(205, 210, 220) }, 90) end
	if o.chamfer then K.chamfer(f, o.chamfer == true and K.T.chamfer or o.chamfer, o.corners, o.under) end
	return f
end

local STYLE = {
	display = function(T: Theme) return T.display, 48, T.text end,
	title = function(T: Theme) return T.title, 28, T.text end,
	label = function(T: Theme) return T.bodyBold, 15, T.muted end,
	body = function(T: Theme) return T.body, 18, T.text end,
	small = function(T: Theme) return T.body, 15, T.muted end,
	mono = function(T: Theme) return T.mono, 22, T.text end,
}
function K.text(parent: Instance, text: string, style: string, props: { [string]: any }?): TextLabel
	local font, size, color = STYLE[style](K.T)
	local t = K.new("TextLabel", parent, { FontFace = font, TextSize = size, TextColor3 = color, Text = text, AutomaticSize = Enum.AutomaticSize.XY,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, RichText = true })
	if style == "label" then t.Text = string.upper(text); t:SetAttribute("Tracked", true) end
	apply(t, props)
	return t
end

function K.icon(parent: Instance, name: string, size: number, color: Color3?, props: { [string]: any }?): ImageLabel
	local c = K.ICON[name]
	local i = K.new("ImageLabel", parent, { Image = K.ATLAS, ImageRectOffset = Vector2.new(c[1], c[2]), ImageRectSize = Vector2.new(128, 128),
		Size = UDim2.fromOffset(size, size), ImageColor3 = color or K.T.text, ScaleType = Enum.ScaleType.Fit, Name = "Icon_" .. name })
	apply(i, props)
	return i
end

function K.art(parent: Instance, key: string, props: { [string]: any }?): ImageLabel
	local i = K.new("ImageLabel", parent, { Image = K.IMG[key] or key, ScaleType = Enum.ScaleType.Fit, Name = "Art_" .. key })
	apply(i, props)
	return i
end

-- keyboard hint chip, e.g. [E]
function K.key(parent: Instance, k: string, props: { [string]: any }?): Frame
	local f = K.new("Frame", parent, { Size = UDim2.fromOffset(math.max(26, 12 + #k * 10), 26), BackgroundTransparency = 0, BackgroundColor3 = K.T.raised, Name = "Key" })
	K.corner(f, 5); K.stroke(f, K.T.text, 1, 0.75)
	K.new("Frame", f, { Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundTransparency = 0.6, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 2 })
	K.text(f, k, "label", { Size = UDim2.fromScale(1, 1), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = K.T.text, TextSize = 13 })
	apply(f, props)
	return f
end

-- buttons: primary (accent fill), secondary (raised surface), ghost (outline only)
function K.button(parent: Instance, label: string, variant: string, props: { [string]: any }?, opts: { [string]: any }?): TextButton
	local o: any = opts or {}
	local T = K.T
	local fill = variant == "primary" and (o.color or T.accent) or T.raised
	local b = K.new("TextButton", parent, { AutoButtonColor = false, Text = "", BackgroundColor3 = fill, BackgroundTransparency = variant == "ghost" and 1 or 0,
		Size = UDim2.fromOffset(220, 56), Name = label:gsub("%W", "") .. "Button" })
	apply(b, props)
	if T.chamfer == 0 then K.corner(b, o.radius or T.radius) else K.chamfer(b, 10, "tl br", o.under) end
	if variant == "primary" then
		K.grad(b, { Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 215) }, 90)
	else
		K.stroke(b, variant == "ghost" and T.text or T.text, 1, variant == "ghost" and 0.7 or 0.86)
	end
	local row = K.new("Frame", b, { Size = UDim2.fromScale(1, 1), Name = "Row" })
	K.list(row, "x", 10, "Center", "Center")
	local ink = variant == "primary" and T.accentInk or T.text
	if o.icon then K.icon(row, o.icon, o.iconSize or 22, ink, { LayoutOrder = 0 }) end
	K.text(row, label, "title", { TextSize = o.textSize or 20, TextColor3 = ink, LayoutOrder = 1, FontFace = T.title, Text = T.caps and string.upper(label) or label })
	if o.key then K.key(row, o.key, { LayoutOrder = 2 }) end
	b:SetAttribute("Juicy", true)
	return b
end

-- progress / stat bar with optional ghost "upgrade preview" segment and tick marks
function K.bar(parent: Instance, props: { [string]: any }, pct: number, color: Color3?, opts: { [string]: any }?): Frame
	local o: any = opts or {}
	local track = K.new("Frame", parent, { BackgroundTransparency = 0, BackgroundColor3 = K.T.raised, Size = UDim2.fromOffset(200, 8), ClipsDescendants = true, Name = "Bar" })
	apply(track, props)
	if o.round ~= false and K.T.chamfer == 0 then K.corner(track, 999) end
	if o.preview then
		local pv = K.new("Frame", track, { BackgroundTransparency = 0.55, BackgroundColor3 = o.previewColor or K.T.good, Size = UDim2.fromScale(math.clamp(o.preview, 0, 1), 1), Name = "Preview" })
		if o.round ~= false and K.T.chamfer == 0 then K.corner(pv, 999) end
	end
	local fill = K.new("Frame", track, { BackgroundTransparency = 0, BackgroundColor3 = color or K.T.accent, Size = UDim2.fromScale(math.clamp(pct, 0, 1), 1), Name = "Fill" })
	if o.round ~= false and K.T.chamfer == 0 then K.corner(fill, 999) end
	K.grad(fill, { Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200) }, 90)
	if o.ticks then
		for i = 1, o.ticks - 1 do
			K.new("Frame", track, { BackgroundTransparency = 0, BackgroundColor3 = K.T.bg, Size = UDim2.new(0, 2, 1, 0), Position = UDim2.new(i / o.ticks, -1, 0, 0), ZIndex = 3 })
		end
	end
	return track
end

-- labelled stat row: NAME ........ 312  [=========---]
function K.stat(parent: Instance, name: string, value: string, pct: number, opts: { [string]: any }?): Frame
	local o: any = opts or {}
	local f = K.new("Frame", parent, { Size = UDim2.new(1, 0, 0, 40), Name = "Stat_" .. name, LayoutOrder = o.order or 0 })
	K.text(f, name, "label", { Position = UDim2.fromOffset(0, 0) })
	local v = K.text(f, value, "mono", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), TextSize = 16 })
	if o.delta then
		v.Text = value .. string.format('  <font color="#%s">%s</font>', (o.deltaColor or K.T.good):ToHex(), o.delta)
	end
	K.bar(f, { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 28) }, pct, o.color, { preview = o.preview, ticks = o.ticks })
	return f
end

function K.pill(parent: Instance, text: string, color: Color3, props: { [string]: any }?, solid: boolean?): Frame
	local f = K.new("Frame", parent, { BackgroundTransparency = solid and 0 or 0.82, BackgroundColor3 = color, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), Name = "Pill" })
	K.corner(f, K.T.chamfer == 0 and 999 or 2); K.pad(f, 0, 10)
	if not solid then K.stroke(f, color, 1, 0.5) end
	K.text(f, text, "label", { Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextColor3 = solid and K.T.bg or color, TextSize = 12 })
	apply(f, props)
	return f
end

-- currency readout: icon, amount, optional add button
function K.currency(parent: Instance, icon: string, amount: string, color: Color3, props: { [string]: any }?, add: boolean?): Frame
	local f = K.panel(parent, { Size = UDim2.fromOffset(190, 48), AutomaticSize = Enum.AutomaticSize.X }, { alpha = 0.25, sheen = false })
	K.pad(f, 0, add and 6 or 16, 0, 14); K.list(f, "x", 10, "Left", "Center")
	K.icon(f, icon, 22, color, { LayoutOrder = 0 })
	K.text(f, amount, "mono", { TextSize = 18, LayoutOrder = 1 })
	if add then
		local p = K.new("Frame", f, { Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 0, BackgroundColor3 = color, LayoutOrder = 2 })
		if K.T.chamfer == 0 then K.corner(p, 8) end
		K.icon(p, "plus", 18, K.T.bg, { Position = UDim2.fromOffset(9, 9) })
	end
	apply(f, props)
	return f
end

-- tab strip; the active tab gets the accent underline
function K.tabs(parent: Instance, items: { string }, active: number, props: { [string]: any }?, opts: { [string]: any }?): Frame
	local o: any = opts or {}
	local f = K.new("Frame", parent, { Size = UDim2.new(1, 0, 0, 52), Name = "Tabs" })
	apply(f, props)
	K.list(f, "x", o.gap or 34, "Left", "Center")
	for i, name in items do
		local on = i == active
		local t = K.new("TextButton", f, { AutoButtonColor = false, Text = "", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = i, BackgroundTransparency = 1, Name = "Tab_" .. name })
		local row = K.new("Frame", t, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1) })
		K.list(row, "x", 8, "Left", "Center")
		if o.icons and o.icons[i] then K.icon(row, o.icons[i], 18, on and K.T.text or K.T.muted, { LayoutOrder = 0 }) end
		K.text(row, items[i], "title", { TextSize = o.size or 18, TextColor3 = on and K.T.text or K.T.muted, LayoutOrder = 1, Text = string.upper(name) })
		if on then
			K.new("Frame", t, { BackgroundTransparency = 0, BackgroundColor3 = K.T.accent, Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), Name = "Underline" })
		end
	end
	return f
end

function K.toggle(parent: Instance, on: boolean, props: { [string]: any }?): Frame
	local f = K.new("Frame", parent, { Size = UDim2.fromOffset(52, 28), BackgroundTransparency = 0, BackgroundColor3 = on and K.T.accent or K.T.raised, Name = "Toggle" })
	K.corner(f, K.T.chamfer == 0 and 999 or 3)
	if not on then K.stroke(f, K.T.text, 1, 0.8) end
	local knob = K.new("Frame", f, { Size = UDim2.fromOffset(22, 22), Position = on and UDim2.new(1, -25, 0, 3) or UDim2.fromOffset(3, 3), BackgroundTransparency = 0,
		BackgroundColor3 = on and K.T.accentInk or K.T.muted })
	K.corner(knob, K.T.chamfer == 0 and 999 or 2)
	apply(f, props)
	return f
end

function K.slider(parent: Instance, pct: number, props: { [string]: any }?): Frame
	local f = K.new("Frame", parent, { Size = UDim2.fromOffset(260, 28), Name = "Slider" })
	apply(f, props)
	K.bar(f, { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3) }, pct)
	local knob = K.new("Frame", f, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(pct, 0.5), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 0, BackgroundColor3 = K.T.text })
	K.corner(knob, K.T.chamfer == 0 and 999 or 2); K.stroke(knob, K.T.accent, 3, 0)
	return f
end

-- segmented selector: < LOW | MED | [HIGH] | ULTRA >
function K.segmented(parent: Instance, items: { string }, active: number, props: { [string]: any }?): Frame
	local f = K.new("Frame", parent, { Size = UDim2.fromOffset(360, 36), BackgroundTransparency = 0, BackgroundColor3 = K.T.raised, Name = "Segmented" })
	K.corner(f, K.T.chamfer == 0 and 8 or 2)
	apply(f, props)
	K.pad(f, 3); K.list(f, "x", 3, "Left", "Center")
	local w = 1 / #items
	for i, s in items do
		local seg = K.new("Frame", f, { Size = UDim2.new(w, -3, 1, 0), BackgroundTransparency = i == active and 0 or 1, BackgroundColor3 = K.T.accent, LayoutOrder = i })
		K.corner(seg, K.T.chamfer == 0 and 6 or 1)
		K.text(seg, s, "label", { Size = UDim2.fromScale(1, 1), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = i == active and K.T.accentInk or K.T.muted, TextSize = 13 })
	end
	return f
end

-- inventory slot: rarity-tinted backdrop, art, count, equipped tick, rarity edge
function K.slot(parent: Instance, props: { [string]: any }, item: { [string]: any }?): Frame
	local it: any = item or {}
	local r = it.rarity and K.RARITY[it.rarity]
	local f = K.new("Frame", parent, { BackgroundTransparency = 0.15, BackgroundColor3 = K.T.surface2, Name = "Slot", ClipsDescendants = true })
	apply(f, props)
	if K.T.chamfer == 0 then K.corner(f, 8) end
	K.stroke(f, r and r[1] or K.T.text, it.selected and 2 or 1, it.selected and 0 or (r and 0.55 or 0.88))
	if r then
		local glow = K.new("Frame", f, { BackgroundTransparency = 0, BackgroundColor3 = r[1], Size = UDim2.fromScale(1, 1), Name = "RarityGlow" })
		K.grad(glow, { r[1], r[1] }, 90, { 1, 0.62 })
		if K.T.chamfer == 0 then K.corner(glow, 8) end
		K.new("Frame", f, { BackgroundTransparency = 0, BackgroundColor3 = r[1], Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), Name = "Edge" })
	end
	if it.art then K.art(f, it.art, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86 * (it.artScale or 1), 0.72 * (it.artScale or 1)), ZIndex = 2, Rotation = it.rot or 0 }) end
	if it.icon then K.icon(f, it.icon, it.iconSize or 36, it.iconColor or K.T.muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 2 }) end
	if it.count then K.text(f, it.count, "mono", { TextSize = 14, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -6), ZIndex = 3 }) end
	if it.key then K.text(f, it.key, "label", { TextSize = 12, Position = UDim2.fromOffset(8, 6), ZIndex = 3, TextColor3 = K.T.text }) end
	if it.equipped then
		local e = K.new("Frame", f, { Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -26, 0, 6), BackgroundTransparency = 0, BackgroundColor3 = K.T.accent, ZIndex = 3 })
		K.corner(e, K.T.chamfer == 0 and 999 or 2)
		K.icon(e, "check", 14, K.T.accentInk, { Position = UDim2.fromOffset(3, 3), ZIndex = 4 })
	end
	if it.badgeLock then -- visible but not owned yet: small lock in the corner instead of a dim overlay
		local b = K.new("Frame", f, { Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -30, 0, 6), BackgroundTransparency = 0.2, BackgroundColor3 = K.T.bg, ZIndex = 5 })
		K.corner(b, K.T.chamfer == 0 and 999 or 2)
		K.icon(b, "lock", 14, K.T.muted, { Position = UDim2.fromOffset(5, 5), ZIndex = 6 })
	end
	if it.locked then
		K.new("Frame", f, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.35, BackgroundColor3 = K.T.bg, ZIndex = 5 })
		K.icon(f, "lock", 22, K.T.muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 6 })
	end
	return f
end

-- full-bleed backdrop: base colour, radial-ish light falloff, scanline texture of thin bands, edge vignette
function K.backdrop(root: Instance, opts: { [string]: any }?): Frame
	local o: any = opts or {}
	if root.Parent and root.Parent:IsA("ScreenGui") then -- fill the letterbox on screens wider or taller than 16:9
		K.new("Frame", root.Parent, { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundTransparency = o.alpha or 0, BackgroundColor3 = K.T.bg, ZIndex = -20 })
	end
	local bg = K.new("Frame", root, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = o.alpha or 0, BackgroundColor3 = K.T.bg, Name = "Backdrop", ZIndex = -10 })
	if o.glow then
		K.new("ImageLabel", bg, { AnchorPoint = Vector2.new(0.5, 0.5), Position = o.glowAt or UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(o.glowSize or 1500, (o.glowSize or 1500) * 0.6),
			Image = K.RADIAL, ImageColor3 = o.glow, ImageTransparency = (o.glowStrength or 0.72) - 0.25, ZIndex = -9, Name = "Glow" })
	end
	if o.floor then
		local fl = K.new("Frame", bg, { Size = UDim2.new(1, 0, 0.42, 0), Position = UDim2.fromScale(0, 0.58), BackgroundTransparency = 0, BackgroundColor3 = o.floor, ZIndex = -9, Name = "Floor" })
		K.grad(fl, { o.floor, o.floor }, 90, { 0.4, 1 })
		for i = 1, 9 do -- perspective floor lines
			K.new("Frame", fl, { BackgroundTransparency = 0.93 + i * 0.005, BackgroundColor3 = K.T.text, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, (i / 10) ^ 1.8), ZIndex = -8 })
		end
	end
	local v = K.new("Frame", bg, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = -7, Name = "VignetteX" })
	K.grad(v, { Color3.new(0, 0, 0), Color3.new(0, 0, 0) }, 0, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(0.2, 1), NumberSequenceKeypoint.new(0.8, 1), NumberSequenceKeypoint.new(1, 0.25) }))
	local v2 = K.new("Frame", bg, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = -7, Name = "VignetteY" })
	K.grad(v2, { Color3.new(0, 0, 0), Color3.new(0, 0, 0) }, 90, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.18, 1), NumberSequenceKeypoint.new(0.85, 1), NumberSequenceKeypoint.new(1, 0.2) }))
	return bg
end

-- section header: small accent tick, tracked label, optional right-hand meta text
function K.header(parent: Instance, text: string, props: { [string]: any }?, meta: string?): Frame
	local f = K.new("Frame", parent, { Size = UDim2.new(1, 0, 0, 22), Name = "Header" })
	apply(f, props)
	K.new("Frame", f, { BackgroundTransparency = 0, BackgroundColor3 = K.T.accent, Size = UDim2.fromOffset(3, 14), Position = UDim2.fromOffset(0, 4) })
	K.text(f, text, "label", { Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(0, 22), TextColor3 = K.T.text })
	if meta then K.text(f, meta, "small", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(0, 22), TextSize = 14 }) end
	return f
end

-- top bar used by every APEX/FRONTLINE menu: brand mark, nav, currencies, profile
function K.topbar(root: Instance, brand: string, nav: { string }, active: number, currencies: { { any } }, player: { [string]: any }): Frame
	local bar = K.new("Frame", root, { Size = UDim2.new(1, 0, 0, 88), Name = "TopBar", ZIndex = 20 })
	local shade = K.new("Frame", bar, { Size = UDim2.new(1, 0, 1, 40), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 19 })
	K.grad(shade, { Color3.new(0, 0, 0), Color3.new(0, 0, 0) }, 90, { 0.35, 1 })
	K.pad(bar, 0, 56)
	local mark = K.new("Frame", bar, { Size = UDim2.fromOffset(0, 88), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 20 })
	K.list(mark, "x", 12, "Left", "Center")
	local logo = K.new("Frame", mark, { Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 0, BackgroundColor3 = K.T.accent, Rotation = K.T.chamfer == 0 and 0 or 45, ZIndex = 20 })
	if K.T.chamfer == 0 then
		K.corner(logo, 8); K.text(logo, "A", "display", { TextSize = 18, TextColor3 = K.T.accentInk, Size = UDim2.fromScale(1, 1), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 21 })
	else
		logo.Size = UDim2.fromOffset(24, 24)
		K.new("Frame", logo, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 0, BackgroundColor3 = K.T.bg, ZIndex = 21 })
	end
	K.text(mark, brand, "display", { TextSize = 24, ZIndex = 20 })
	local navf = K.new("Frame", bar, { Position = UDim2.fromOffset(250, 0), Size = UDim2.fromOffset(900, 88), ZIndex = 20 })
	K.tabs(navf, nav, active, { Size = UDim2.fromScale(1, 1), ZIndex = 20 }, { size = 17, gap = 40 })
	local right = K.new("Frame", bar, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(0, 88), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 20 })
	K.list(right, "x", 12, "Right", "Center")
	for i, c in currencies do K.currency(right, c[1], c[2], c[3], { LayoutOrder = i }, c[4]) end
	local prof = K.new("Frame", right, { Size = UDim2.fromOffset(0, 52), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 10 })
	K.list(prof, "x", 12, "Left", "Center"); K.pad(prof, 0, 0, 0, 16)
	local av = K.new("ImageLabel", prof, { Size = UDim2.fromOffset(46, 46), Image = player.thumb or "", BackgroundTransparency = 0, BackgroundColor3 = K.T.raised, LayoutOrder = 1 })
	K.corner(av, K.T.chamfer == 0 and 999 or 3); K.stroke(av, K.T.accent, 2, 0)
	local who = K.new("Frame", prof, { Size = UDim2.fromOffset(0, 46), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2 })
	K.text(who, player.name, "title", { TextSize = 17, Position = UDim2.fromOffset(0, 2) })
	K.text(who, player.sub, "small", { TextSize = 13, Position = UDim2.fromOffset(0, 24) })
	return bar
end

-- bottom hint row: [Esc] Back  [Enter] Select ...
function K.hints(root: Instance, items: { { string } }, props: { [string]: any }?): Frame
	local f = K.new("Frame", root, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -56, 1, -28), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, Name = "Hints", ZIndex = 20 })
	apply(f, props)
	K.list(f, "x", 24, "Right", "Center")
	for i, h in items do
		local r = K.new("Frame", f, { Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i })
		K.list(r, "x", 8, "Left", "Center")
		K.key(r, h[1], { LayoutOrder = 0 })
		K.text(r, h[2], "label", { LayoutOrder = 1, TextColor3 = K.T.muted, TextSize = 13 })
	end
	return f
end

-- hover/press motion; call from a LocalScript once the ScreenGui is in PlayerGui
function K.juice(gui: Instance)
	local TS = game:GetService("TweenService")
	local quick = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	for _, b in gui:GetDescendants() do
		if b:IsA("GuiButton") and b:GetAttribute("Juicy") then
			local sc = K.new("UIScale", b, {})
			b.MouseEnter:Connect(function() TS:Create(sc, quick, { Scale = 1.03 }):Play() end)
			b.MouseLeave:Connect(function() TS:Create(sc, quick, { Scale = 1 }):Play() end)
			b.MouseButton1Down:Connect(function() TS:Create(sc, TweenInfo.new(0.06), { Scale = 0.97 }):Play() end)
			b.MouseButton1Up:Connect(function() TS:Create(sc, quick, { Scale = 1.03 }):Play() end)
		end
	end
end

return K
