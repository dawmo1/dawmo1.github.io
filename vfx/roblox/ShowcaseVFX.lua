--!strict
-- ShowcaseVFX: five layered abilities built on the v2 texture set (tools/make_vfx2.py).
-- Each ability is a function that builds its effect at a CFrame and returns the Folder it made, so a game
-- can call it on a cast and Debris it, and the portfolio can freeze it mid-play for a still.

local V = {}

V.TEX = {
	fire = "rbxassetid://118605743296988", smoke = "rbxassetid://87257747488657", explosion = "rbxassetid://139324612019136",
	shock = "rbxassetid://103810731867194", flare = "rbxassetid://114270824293690", slash = "rbxassetid://136818098804102",
	portal = "rbxassetid://84738106043775", spark = "rbxassetid://84897398954550", scorch = "rbxassetid://92749992355621",
	glow = "rbxassetid://83055659488836", beamGlow = "rbxassetid://100984551727881",
	arcs = { "rbxassetid://134002228284238", "rbxassetid://117162767731571", "rbxassetid://109631786602216", "rbxassetid://138221954269165" },
}

local function seq(...): ColorSequence
	local args = { ... }
	if #args == 1 then return ColorSequence.new(args[1]) end
	local kp = {}
	for i, c in args do table.insert(kp, ColorSequenceKeypoint.new((i - 1) / (#args - 1), c)) end
	return ColorSequence.new(kp)
end
local function nums(pairs_: { { number } }): NumberSequence
	local kp = {}
	for _, p in pairs_ do table.insert(kp, NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0)) end
	if #kp == 1 then table.insert(kp, NumberSequenceKeypoint.new(1, kp[1].Value, kp[1].Envelope)) end -- a constant still needs two keypoints
	return NumberSequence.new(kp)
end
V.seq, V.nums = seq, nums

local function anchor(folder: Instance, cf: CFrame, size: Vector3?): Part
	local p = Instance.new("Part")
	p.Name = "Emitter"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = size or Vector3.new(0.2, 0.2, 0.2); p.CFrame = cf; p.Parent = folder
	return p
end

-- particle emitter with sensible VFX defaults (additive glow, no world lighting, flipbook-ready)
local function pe(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1; e.LightInfluence = 0; e.Rate = 0; e.Speed = NumberRange.new(0)
	e.Lifetime = NumberRange.new(1); e.Rotation = NumberRange.new(0, 360); e.Orientation = Enum.ParticleOrientation.FacingCamera
	for k, v in props do (e :: any)[k] = v end
	e.Parent = parent
	return e
end

local function groundDecal(folder: Instance, pos: Vector3, size: number, tex: string, color: Color3, alpha: number): Part
	local p = anchor(folder, CFrame.new(pos), Vector3.new(size, 0.05, size))
	local d = Instance.new("Decal"); d.Face = Enum.NormalId.Top; d.Texture = tex; d.Color3 = color; d.Transparency = alpha; d.Parent = p
	return p
end

local function light(parent: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight"); l.Color = color; l.Range = range; l.Brightness = brightness; l.Shadows = false; l.Parent = parent
end

local function newFolder(name: string, parent: Instance?): Folder
	local f = Instance.new("Folder"); f.Name = name; f.Parent = parent or workspace
	return f
end

-- 1. INFERNO BLAST: fireball detonation. Colour-baked explosion core, rolling smoke, flame tongues, sparks, shock ring, scorch.
function V.inferno(cf: CFrame, parent: Instance?): Folder
	local f = newFolder("VFX_Inferno", parent)
	local c = anchor(f, cf * CFrame.new(0, 7.5, 0)) -- high enough that the biggest puffs never cut into the floor
	pe(c, { Name = "Core", Texture = V.TEX.explosion, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Rate = 34, Lifetime = NumberRange.new(0.9, 1.2), Size = nums({ { 0, 9 }, { 1, 17 } }), SpreadAngle = Vector2.new(180, 180), Speed = NumberRange.new(2, 6),
		LightEmission = 0.35, Brightness = 2.2, Color = seq(Color3.new(1, 1, 1)), Transparency = nums({ { 0, 0 }, { 1, 0 } }), RotSpeed = NumberRange.new(-30, 30) })
	pe(c, { Name = "Smoke", Texture = V.TEX.smoke, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Rate = 12, Lifetime = NumberRange.new(1.6, 2.4), Size = nums({ { 0, 5 }, { 1, 12 } }), SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(8, 13),
		Acceleration = Vector3.new(0, 4, 0), Drag = 2.5, LightEmission = 0, LightInfluence = 0.6, Color = seq(Color3.fromRGB(70, 58, 52), Color3.fromRGB(30, 28, 28)),
		Transparency = nums({ { 0, 0.75 }, { 0.4, 0.65 }, { 1, 1 } }), ZOffset = -1, RotSpeed = NumberRange.new(-20, 20) })
	local base = anchor(f, cf * CFrame.new(0, 0.6, 0))
	pe(base, { Name = "Tongues", Texture = V.TEX.fire, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.Loop, FlipbookFramerate = NumberRange.new(24),
		Rate = 40, Lifetime = NumberRange.new(0.5, 0.8), Size = nums({ { 0, 3 }, { 0.5, 4.5 }, { 1, 1.5 } }), Rotation = NumberRange.new(-8, 8), Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, 8, 0), Brightness = 3, Color = seq(Color3.fromRGB(255, 220, 140), Color3.fromRGB(255, 110, 30), Color3.fromRGB(180, 30, 10)),
		Transparency = nums({ { 0, 0.2 }, { 0.7, 0.3 }, { 1, 1 } }) })
	pe(c, { Name = "Sparks", Texture = V.TEX.spark, Orientation = Enum.ParticleOrientation.VelocityParallel, Rate = 120, Lifetime = NumberRange.new(0.4, 0.9),
		Size = nums({ { 0, 0.35 }, { 1, 0.05 } }), Squash = nums({ { 0, 2.5 } }), SpreadAngle = Vector2.new(180, 180), Speed = NumberRange.new(30, 60), Drag = 2,
		Acceleration = Vector3.new(0, -30, 0), Brightness = 6, Color = seq(Color3.fromRGB(255, 230, 160), Color3.fromRGB(255, 120, 30)), Rotation = NumberRange.new(0) })
	local ring = anchor(f, cf * CFrame.new(0, 0.3, 0) * CFrame.Angles(math.rad(90), 0, 0))
	pe(ring, { Name = "ShockRing", Texture = V.TEX.shock, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Speed = NumberRange.new(0.01), EmissionDirection = Enum.NormalId.Front,
		Rate = 2.5, Lifetime = NumberRange.new(0.7), Size = nums({ { 0, 6 }, { 1, 30 } }), Brightness = 4, Color = seq(Color3.fromRGB(255, 170, 70)), Rotation = NumberRange.new(0, 360) })
		groundDecal(f, cf.Position + Vector3.new(0, 0.08, 0), 34, V.TEX.glow, Color3.fromRGB(255, 120, 40), 0.55)
	light(c, Color3.fromRGB(255, 140, 60), 26, 2.2)
	return f
end

-- 2. STORM STRIKE: jagged bolts built from chained beam segments (real zigzag geometry, arc texture on top for
-- micro-detail), forked branches, a soft glow pass, impact flare, cyan shock ring, sparks and scorched ground.
local function boltPath(rng: Random, from: Vector3, to: Vector3, depth: number, spread: number): { Vector3 }
	local pts = { from, to }
	for d = 1, depth do
		local nxt = {}
		local amp = spread / (1.8 ^ (d - 1))
		for k = 1, #pts - 1 do
			local a, b = pts[k], pts[k + 1]
			local mid = (a + b) / 2 + Vector3.new(rng:NextNumber(-amp, amp), rng:NextNumber(-amp, amp) * 0.3, rng:NextNumber(-amp, amp))
			table.insert(nxt, a); table.insert(nxt, mid)
		end
		table.insert(nxt, pts[#pts])
		pts = nxt
	end
	return pts
end

local function drawBolt(f: Instance, pts: { Vector3 }, width: number, color: Color3, bright: number, rng: Random)
	local holder = anchor(f, CFrame.new(pts[1]))
	local atts = {}
	for k, p in pts do
		local a = Instance.new("Attachment"); a.Parent = holder; a.WorldPosition = p; atts[k] = a -- parent first, or WorldPosition is read as local
	end
	for k = 1, #atts - 1 do
		local core = Instance.new("Beam")
		core.Attachment0 = atts[k]; core.Attachment1 = atts[k + 1]; core.FaceCamera = true; core.Segments = 2
		core.Texture = V.TEX.beamGlow; core.TextureMode = Enum.TextureMode.Stretch -- continuous across joints (the arc sheets fade at their ends)
		core.Width0 = width * 0.5; core.Width1 = width * 0.5; core.LightEmission = 1; core.LightInfluence = 0; core.Brightness = bright
		core.Color = seq(Color3.new(1, 1, 1)); core.Transparency = nums({ { 0, 0 } }); core.Parent = holder
		local glow = Instance.new("Beam")
		glow.Attachment0 = atts[k]; glow.Attachment1 = atts[k + 1]; glow.FaceCamera = true; glow.Segments = 2
		glow.Texture = V.TEX.beamGlow; glow.TextureMode = Enum.TextureMode.Stretch
		glow.Width0 = width * 3; glow.Width1 = width * 3; glow.LightEmission = 1; glow.LightInfluence = 0; glow.Brightness = 1.5
		glow.Color = seq(color); glow.Transparency = nums({ { 0, 0.4 } }); glow.Parent = holder
	end
end

function V.storm(cf: CFrame, parent: Instance?): Folder
	local f = newFolder("VFX_Storm", parent)
	local rng = Random.new(5)
	local strike = cf.Position + Vector3.new(0, 0.4, 0)
	local cyan = Color3.fromRGB(90, 190, 255)
	for i = 1, 2 do
		local top = strike + Vector3.new(rng:NextNumber(-6, 6), 75, rng:NextNumber(-6, 6))
		local pts = boltPath(rng, top, strike, 5, 12)
		drawBolt(f, pts, i == 1 and 1.4 or 0.8, cyan, i == 1 and 6 or 3.5, rng)
		for b = 1, (i == 1 and 4 or 2) do -- forks peel off the main channel and die out
			local k = rng:NextInteger(math.floor(#pts * 0.2), math.floor(#pts * 0.8))
			local from = pts[k]
			local to = from + Vector3.new(rng:NextNumber(-14, 14), -rng:NextNumber(8, 20), rng:NextNumber(-14, 14))
			drawBolt(f, boltPath(rng, from, to, 4, 4), 0.5, cyan, 2.5, rng)
		end
	end
	local ground = anchor(f, CFrame.new(strike))
	pe(ground, { Name = "Flare", Texture = V.TEX.flare, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Rate = 8, Lifetime = NumberRange.new(0.35), Size = nums({ { 0, 12 }, { 1, 16 } }), Rotation = NumberRange.new(0), Brightness = 2.5, Color = seq(Color3.fromRGB(190, 235, 255)) })
	pe(ground, { Name = "Sparks", Texture = V.TEX.spark, Orientation = Enum.ParticleOrientation.VelocityParallel, Rate = 140, Lifetime = NumberRange.new(0.25, 0.6),
		Size = nums({ { 0, 0.5 }, { 1, 0.1 } }), Squash = nums({ { 0, 3 } }), SpreadAngle = Vector2.new(75, 75), EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(30, 60), Drag = 3,
		Acceleration = Vector3.new(0, -45, 0), Brightness = 5, Color = seq(Color3.fromRGB(220, 245, 255), cyan), Rotation = NumberRange.new(0) })
	pe(ground, { Name = "Dust", Texture = V.TEX.smoke, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Rate = 10, Lifetime = NumberRange.new(1.2, 1.8), Size = nums({ { 0, 4 }, { 1, 10 } }), SpreadAngle = Vector2.new(90, 10), EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(8, 14), Drag = 3, LightEmission = 0, LightInfluence = 0.5, Color = seq(Color3.fromRGB(70, 82, 104)), Transparency = nums({ { 0, 0.55 }, { 1, 1 } }), ZOffset = -1 })
	local ring = anchor(f, cf * CFrame.new(0, 0.3, 0) * CFrame.Angles(math.rad(90), 0, 0))
	pe(ring, { Name = "ShockRing", Texture = V.TEX.shock, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Speed = NumberRange.new(0.01), EmissionDirection = Enum.NormalId.Front,
		Rate = 2.5, Lifetime = NumberRange.new(0.6), Size = nums({ { 0, 5 }, { 1, 30 } }), Brightness = 2.5, Color = seq(Color3.fromRGB(120, 210, 255)) })
	groundDecal(f, cf.Position + Vector3.new(0, 0.08, 0), 30, V.TEX.glow, cyan, 0.55)
	light(ground, Color3.fromRGB(140, 210, 255), 28, 2.5)
	return f
end

-- 3. VOID PORTAL: rotating swirl disc emitted from a single point so it stays centred, a dark core, a breaking rim,
-- inward-drawn motes, ground glow and low purple mist.
function V.portal(cf: CFrame, parent: Instance?): Folder
	local f = newFolder("VFX_Portal", parent)
	local center = anchor(f, cf * CFrame.new(0, 14, 0))
	local violet = Color3.fromRGB(170, 110, 255)
	for _, face in { Enum.NormalId.Front } do -- flat particles render from both sides, so one face is enough
		-- VelocityPerpendicular lays each particle flat against the emission direction, so the swirl sits in the disc plane
		pe(center, { Name = "Swirl" .. face.Name, Texture = V.TEX.portal, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
			FlipbookFramerate = NumberRange.new(14), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = face, Speed = NumberRange.new(0.001),
			Rate = 1.2, Lifetime = NumberRange.new(2), Size = nums({ { 0, 12 }, { 1, 13 } }), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60),
			Brightness = 1.1, Color = seq(Color3.fromRGB(215, 160, 255), Color3.fromRGB(140, 80, 255)), Transparency = nums({ { 0, 1 }, { 0.25, 0.1 }, { 0.75, 0.1 }, { 1, 1 } }) })
		pe(center, { Name = "Rim" .. face.Name, Texture = V.TEX.shock, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
			FlipbookFramerate = NumberRange.new(8), Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = face, Speed = NumberRange.new(0.001),
			Rate = 0.8, Lifetime = NumberRange.new(2.5), Size = nums({ { 0, 15 }, { 1, 15 } }), RotSpeed = NumberRange.new(25), Brightness = 1.4,
			Color = seq(violet), Transparency = nums({ { 0, 1 }, { 0.3, 0.45 }, { 0.7, 0.45 }, { 1, 1 } }) })
	end
	pe(center, { Name = "DarkCore", Texture = V.TEX.glow, Rate = 4, Lifetime = NumberRange.new(1.2), Size = nums({ { 0, 5 }, { 1, 5 } }), LightEmission = 0,
		Color = seq(Color3.fromRGB(10, 4, 24)), Transparency = nums({ { 0, 1 }, { 0.5, 0.25 }, { 1, 1 } }), ZOffset = 1 })
	local motes = anchor(f, cf * CFrame.new(0, 14, 0), Vector3.new(24, 20, 4))
	local m = pe(motes, { Name = "Motes", Texture = V.TEX.spark, Orientation = Enum.ParticleOrientation.VelocityParallel, Rate = 60, Lifetime = NumberRange.new(0.6, 1.0),
		Size = nums({ { 0, 0.3 }, { 1, 0.05 } }), Squash = nums({ { 0, 2 } }), Speed = NumberRange.new(-14, -8), Brightness = 4,
		Color = seq(Color3.fromRGB(240, 210, 255), violet), Rotation = NumberRange.new(0) })
	m.Shape = Enum.ParticleEmitterShape.Sphere; m.ShapeInOut = Enum.ParticleEmitterShapeInOut.InAndOut; m.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	local mist = anchor(f, cf * CFrame.new(0, 3.2, 0), Vector3.new(18, 0.2, 10)) -- high enough that mist puffs never slice into the floor
	local ms = pe(mist, { Name = "Mist", Texture = V.TEX.smoke, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Rate = 8, Lifetime = NumberRange.new(2.5, 3.5), Size = nums({ { 0, 5 }, { 1, 9 } }), Speed = NumberRange.new(0.5, 1.5), LightEmission = 0.4,
		Color = seq(Color3.fromRGB(110, 60, 200)), Transparency = nums({ { 0, 1 }, { 0.3, 0.7 }, { 1, 1 } }), ZOffset = -2 })
	ms.Shape = Enum.ParticleEmitterShape.Box
	groundDecal(f, cf.Position + Vector3.new(0, 0.08, 0), 26, V.TEX.glow, violet, 0.6)
	light(center, violet, 22, 1.6)
	return f
end

-- 4. BLADE DASH: crossing slash arcs, speed streaks along the path, impact flare and sparks at the end.
function V.dash(cf: CFrame, parent: Instance?): Folder
	local f = newFolder("VFX_Dash", parent)
	local hit = anchor(f, cf * CFrame.new(0, 9, -6))
	for i, ang in { -25, 40, 90 } do
		local s = anchor(f, hit.CFrame * CFrame.Angles(0, 0, math.rad(ang)))
		pe(s, { Name = "Slash" .. i, Texture = V.TEX.slash, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Rate = 5, Lifetime = NumberRange.new(0.5), Size = nums({ { 0, 8.5 - i * 0.6 }, { 1, 10 - i * 0.6 } }), Rotation = NumberRange.new(ang + 180), Brightness = 2.4,
			Color = seq(i == 2 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 230, 255)) })
	end
	pe(hit, { Name = "Flare", Texture = V.TEX.flare, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Rate = 4, Lifetime = NumberRange.new(0.3), Size = nums({ { 0, 4 }, { 1, 6 } }), Rotation = NumberRange.new(-10, 10), Brightness = 2, Color = seq(Color3.fromRGB(200, 240, 255)) })
	pe(hit, { Name = "Sparks", Texture = V.TEX.spark, Orientation = Enum.ParticleOrientation.VelocityParallel, Rate = 90, Lifetime = NumberRange.new(0.25, 0.5),
		Size = nums({ { 0, 0.25 }, { 1, 0.03 } }), SpreadAngle = Vector2.new(180, 180), Speed = NumberRange.new(25, 50), Drag = 4, Brightness = 7,
		Color = seq(Color3.fromRGB(230, 250, 255), Color3.fromRGB(110, 200, 255)), Rotation = NumberRange.new(0) })
	-- speed streaks behind the dash path
	local path = anchor(f, cf * CFrame.new(0, 3.5, 8), Vector3.new(4, 5, 22))
	local st = pe(path, { Name = "Streaks", Texture = V.TEX.spark, Orientation = Enum.ParticleOrientation.VelocityParallel, Rate = 60, Lifetime = NumberRange.new(0.2, 0.35),
		Size = nums({ { 0, 0.5 }, { 1, 0.1 } }), Squash = nums({ { 0, 3 } }), EmissionDirection = Enum.NormalId.Front, Speed = NumberRange.new(60, 90), Brightness = 3,
		Color = seq(Color3.fromRGB(170, 230, 255)), Transparency = nums({ { 0, 0.3 }, { 1, 1 } }), Rotation = NumberRange.new(0) })
	st.Shape = Enum.ParticleEmitterShape.Box
	light(hit, Color3.fromRGB(150, 220, 255), 20, 1.4)
	return f
end

-- 5. GROUND SLAM: dust wall ring, flying rock debris, impact flare, crack decal.
function V.slam(cf: CFrame, parent: Instance?): Folder
	local f = newFolder("VFX_Slam", parent)
	local c = anchor(f, cf * CFrame.new(0, 2.2, 0), Vector3.new(4, 0.2, 4)) -- lifted so the dust wall never slices into the floor
	local d = pe(c, { Name = "DustWall", Texture = V.TEX.smoke, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Rate = 70, Lifetime = NumberRange.new(1, 1.6), Size = nums({ { 0, 3 }, { 1, 9 } }), SpreadAngle = Vector2.new(5, 180), EmissionDirection = Enum.NormalId.Right,
		Speed = NumberRange.new(22, 32), Drag = 3.5, Acceleration = Vector3.new(0, 3, 0), LightEmission = 0, LightInfluence = 0.7,
		Color = seq(Color3.fromRGB(150, 135, 120)), Transparency = nums({ { 0, 0.2 }, { 1, 1 } }), ZOffset = -1 })
	pe(c, { Name = "Flare", Texture = V.TEX.flare, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Rate = 4, Lifetime = NumberRange.new(0.3), Size = nums({ { 0, 14 }, { 1, 18 } }), Rotation = NumberRange.new(0), Brightness = 3, Color = seq(Color3.fromRGB(255, 220, 170)) })
	local ring = anchor(f, cf * CFrame.new(0, 0.3, 0) * CFrame.Angles(math.rad(90), 0, 0))
	pe(ring, { Name = "ShockRing", Texture = V.TEX.shock, FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Speed = NumberRange.new(0.01), EmissionDirection = Enum.NormalId.Front,
		Rate = 2.5, Lifetime = NumberRange.new(0.6), Size = nums({ { 0, 4 }, { 1, 30 } }), Brightness = 3, Color = seq(Color3.fromRGB(255, 220, 170)) })
	-- debris: real wedges of the floor material thrown outward (frozen mid-flight for the still)
	local rng = Random.new(9)
	for i = 1, 22 do
		local a = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(2, 11)
		local h = rng:NextNumber(0.5, 7) * (1 - dist / 14)
		local w = Instance.new("WedgePart")
		w.Anchored = true; w.CanCollide = false; w.Material = Enum.Material.Slate; w.Color = Color3.fromRGB(78, 74, 72)
		w.Size = Vector3.new(rng:NextNumber(0.6, 1.8), rng:NextNumber(0.4, 1.2), rng:NextNumber(0.6, 1.8))
		w.CFrame = cf * CFrame.new(math.cos(a) * dist, h + 0.4, math.sin(a) * dist) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6))
		w.Parent = f
	end
	-- raised cracked slabs around the impact
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Slate; p.Color = Color3.fromRGB(64, 62, 62)
		p.Size = Vector3.new(rng:NextNumber(2.5, 4), 0.7, rng:NextNumber(1.5, 2.5))
		p.CFrame = cf * CFrame.new(math.cos(a) * 3.2, 0.25, math.sin(a) * 3.2) * CFrame.Angles(0, -a, math.rad(rng:NextNumber(14, 30)))
		p.Parent = f
	end
	light(c, Color3.fromRGB(255, 210, 160), 24, 3)
	return f
end

return V
