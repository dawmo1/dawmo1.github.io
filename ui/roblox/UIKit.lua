--!strict
-- UIKit: the shared building blocks for the portfolio's Roblox UI (chunky stroked text,
-- gradient buttons with a pressable lip, panels, icons, bars). Every screen is built from these,
-- so the whole set keeps one visual language.

local UIKit = {}

UIKit.IMG = {
	heart = "rbxassetid://115505062976013", gem = "rbxassetid://134951790169084", cash = "rbxassetid://80572717018336",
	coin = "rbxassetid://72930248697588", gift = "rbxassetid://71208848680824", lock = "rbxassetid://132183212338860",
	plus = "rbxassetid://139131640399061", shield = "rbxassetid://87903716926063", wave = "rbxassetid://90674144631908",
	star = "rbxassetid://115610420202137", skull = "rbxassetid://75782050076632", sword = "rbxassetid://93436515502911",
	egg_grass = "rbxassetid://92441927604380", egg_frost = "rbxassetid://130798992144703", egg_inferno = "rbxassetid://98523933885533",
	egg_void = "rbxassetid://110976766365481", pet_slime = "rbxassetid://94583254512105", pet_blockpup = "rbxassetid://112435948109069",
	pet_emberfox = "rbxassetid://78786581577109", avatar_kaiyo = "rbxassetid://138220555157971", head_kaiyo = "rbxassetid://133745327321297",
	head_red = "rbxassetid://107323497919211", head_wren = "rbxassetid://77604366341633", sword_ui = "rbxassetid://102855746544454",
	blaster_ui = "rbxassetid://133021929788484", chest_hero = "rbxassetid://125269597224216",
	ability_fire = "rbxassetid://138158465217106", ability_lightning = "rbxassetid://122524622680560", ability_slash = "rbxassetid://125544322705284",
	ability_charge = "rbxassetid://113533532118932", ability_impact = "rbxassetid://119701617904196", ability_portal = "rbxassetid://88739813248237",
}

UIKit.C = {
	ink = Color3.fromRGB(26, 16, 24), white = Color3.new(1, 1, 1),
	green = { Color3.fromRGB(140, 242, 91), Color3.fromRGB(47, 181, 42) },
	blue = { Color3.fromRGB(90, 216, 255), Color3.fromRGB(31, 141, 224) },
	purple = { Color3.fromRGB(201, 139, 255), Color3.fromRGB(138, 63, 224) },
	red = { Color3.fromRGB(255, 107, 107), Color3.fromRGB(214, 31, 44) },
	gold = { Color3.fromRGB(255, 228, 92), Color3.fromRGB(255, 176, 0) },
	orange = { Color3.fromRGB(255, 178, 94), Color3.fromRGB(255, 106, 43) },
	dark = { Color3.fromRGB(58, 62, 78), Color3.fromRGB(32, 34, 46) },
}

local function apply(inst: Instance, props: { [string]: any }?)
	if props then
		for k, v in props do (inst :: any)[k] = v end
	end
end

function UIKit.screen(name: string, parent: Instance): ScreenGui
	local old = parent:FindFirstChild(name); if old then old:Destroy() end
	local g = Instance.new("ScreenGui")
	g.Name = name; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = parent
	return g
end

function UIKit.corner(parent: Instance, r: number)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = parent
end
function UIKit.stroke(parent: Instance, thick: number, color: Color3?, mode: Enum.ApplyStrokeMode?)
	local s = Instance.new("UIStroke"); s.Thickness = thick; s.Color = color or UIKit.C.ink
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border; s.LineJoinMode = Enum.LineJoinMode.Round; s.Parent = parent
	return s
end
function UIKit.gradient(parent: Instance, c0: Color3, c1: Color3, rot: number?)
	local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(c0, c1); g.Rotation = rot or 90; g.Parent = parent
	return g
end

-- rounded panel with a thick dark border
function UIKit.panel(parent: Instance, props: { [string]: any }, fill: { Color3 }?, radius: number?, border: number?): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0; f.BackgroundColor3 = UIKit.C.white
	apply(f, props)
	UIKit.corner(f, radius or 18)
	UIKit.stroke(f, border or 4)
	if fill then UIKit.gradient(f, fill[1], fill[2]) end
	f.Parent = parent
	return f
end

-- chunky text: bold font, white fill, dark outline stroke (the Roblox look)
function UIKit.text(parent: Instance, text: string, props: { [string]: any }, size: number?, strokeT: number?): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Text = text; t.Font = Enum.Font.FredokaOne; t.TextColor3 = UIKit.C.white
	t.TextSize = size or 24; t.Size = UDim2.new(1, 0, 0, (size or 24) + 6)
	apply(t, props)
	UIKit.stroke(t, strokeT or 3, UIKit.C.ink, Enum.ApplyStrokeMode.Contextual)
	t.Parent = parent
	return t
end

function UIKit.image(parent: Instance, key: string, props: { [string]: any }): ImageLabel
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1; i.Image = UIKit.IMG[key] or key; i.ScaleType = Enum.ScaleType.Fit
	apply(i, props)
	i.Parent = parent
	return i
end

-- gradient button with a darker "lip" under it, so it reads as pressable; marked Juicy for hover/press tweens
function UIKit.button(parent: Instance, label: string, props: { [string]: any }, fill: { Color3 }, textSize: number?): TextButton
	local holder = Instance.new("Frame"); holder.BackgroundTransparency = 1; holder.Name = label:gsub("%s", "") .. "Button"
	apply(holder, props)
	local lip = Instance.new("Frame"); lip.Name = "Lip"; lip.Size = UDim2.new(1, 0, 1, 0); lip.Position = UDim2.fromOffset(0, 6)
	lip.BackgroundColor3 = UIKit.C.ink; lip.BorderSizePixel = 0; UIKit.corner(lip, 16); lip.Parent = holder
	local b = Instance.new("TextButton"); b.Name = "Face"; b.Size = UDim2.fromScale(1, 1); b.BackgroundColor3 = UIKit.C.white
	b.AutoButtonColor = false; b.Text = label; b.Font = Enum.Font.FredokaOne; b.TextSize = textSize or 26; b.TextColor3 = UIKit.C.white
	b.BorderSizePixel = 0; UIKit.corner(b, 16); UIKit.stroke(b, 4); UIKit.gradient(b, fill[1], fill[2])
	local ts = Instance.new("UIStroke"); ts.Thickness = 3; ts.Color = UIKit.C.ink; ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual; ts.Parent = b
	b:SetAttribute("Juicy", true)
	b.Parent = holder
	holder.Parent = parent
	return b
end

-- progress bar: dark track with a rounded gradient fill
function UIKit.bar(parent: Instance, props: { [string]: any }, pct: number, fill: { Color3 }): Frame
	local track = UIKit.panel(parent, props, UIKit.C.dark, 999, 3)
	local f = Instance.new("Frame"); f.Name = "Fill"; f.BorderSizePixel = 0; f.BackgroundColor3 = UIKit.C.white
	f.Size = UDim2.new(pct, 0, 1, 0); UIKit.corner(f, 999); UIKit.gradient(f, fill[1], fill[2]); f.Parent = track
	return track
end

-- currency pill: icon + amount + green plus button
function UIKit.currency(parent: Instance, icon: string, amount: string, props: { [string]: any }): Frame
	local p = UIKit.panel(parent, props, { Color3.fromRGB(40, 22, 30), Color3.fromRGB(26, 14, 20) }, 999, 4)
	UIKit.image(p, icon, { Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, -8, 0.5, -22) })
	UIKit.text(p, amount, { Size = UDim2.new(1, -86, 1, 0), Position = UDim2.fromOffset(40, 0), TextXAlignment = Enum.TextXAlignment.Left }, 24)
	local plus = UIKit.panel(p, { Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -40, 0.5, -17) }, UIKit.C.green, 999, 3)
	UIKit.image(plus, "plus", { Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.15) })
	return p
end

-- hover grows a button 6%, press squashes it; attach once per ScreenGui from a LocalScript
function UIKit.juice(gui: Instance)
	local TweenService = game:GetService("TweenService")
	for _, b in ipairs(gui:GetDescendants()) do
		if b:IsA("GuiButton") and b:GetAttribute("Juicy") then
			local sc = Instance.new("UIScale"); sc.Parent = b
			local function to(s: number) TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = s }):Play() end
			b.MouseEnter:Connect(function() to(1.06) end)
			b.MouseLeave:Connect(function() to(1) end)
			b.MouseButton1Down:Connect(function() to(0.94) end)
			b.MouseButton1Up:Connect(function() to(1.06) end)
		end
	end
end

return UIKit
