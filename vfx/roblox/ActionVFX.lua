--!strict
-- ActionVFX: layered ability effects built from the portfolio's flipbook sheets.
-- Run on the client (fire a RemoteEvent from the server with positions). Every ability layers
-- 4-8 elements: flash, flipbooks, shockwave, sparks, smoke, light, camera shake, debris.
--
--   local VFX = require(ReplicatedStorage.ActionVFX)
--   VFX.Fireball(handPosition, targetPosition)
--   VFX.LightningStrike(position)
--   VFX.DashSlash(character.HumanoidRootPart)
--   VFX.GroundSlam(position)
--   VFX.ChargeBurst(position)
--   VFX.Portal(cframe)
--   VFX.Display(name, cframe)   -- looping, frozen-in-time version for showcases / thumbnails

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local TEX: { [string]: string } = {
	SlashArc = "rbxassetid://86129308012184", HitSpark = "rbxassetid://119631336650897", EmberFire = "rbxassetid://123238074413869",
	HatchFlash = "rbxassetid://122805611612984", Shockwave = "rbxassetid://72311840515392", Sparkle = "rbxassetid://98239994939869",
	SmokePuff = "rbxassetid://76838484093424", Lightning = "rbxassetid://139735096555350", FireBurst = "rbxassetid://106936772842122",
	SpeedLines = "rbxassetid://102528327473182", ChargeGather = "rbxassetid://97480718788903", PortalSwirl = "rbxassetid://132926981391130",
	ImpactStar = "rbxassetid://118208055226281", BeamEnergy = "rbxassetid://89494262872232", Glow = "rbxassetid://124463122880813",
	GroundCrack = "rbxassetid://93912127860447", Trail = "rbxassetid://98959886869117",
}

local function folder(): Folder
	local f = Workspace:FindFirstChild("ActionVFX_Runtime") :: Folder?
	if not f then
		local nf = Instance.new("Folder"); nf.Name = "ActionVFX_Runtime"; nf.Parent = Workspace; f = nf
	end
	return f :: Folder
end

local function seq(...: number): NumberSequence
	local a = { ... }; local k = {}
	for i = 1, #a, 2 do table.insert(k, NumberSequenceKeypoint.new(a[i], a[i + 1])) end
	return NumberSequence.new(k)
end
local function col(c0: Color3, c1: Color3?): ColorSequence return ColorSequence.new(c0, c1 or c0) end

-- invisible anchored holder part so emitters can be placed anywhere
local function holder(cf: CFrame, size: Vector3?, life: number?): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Transparency = 1
	p.Size = size or Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = cf
	p.Parent = folder()
	if life then Debris:AddItem(p, life) end
	return p
end

type EmitOpts = {
	tex: string, color: ColorSequence, size: NumberSequence, life: NumberRange,
	speed: NumberRange?, loop: boolean?, rate: number?, fps: number?, light: number?, bright: number?,
	orient: Enum.ParticleOrientation?, dir: Enum.NormalId?, rot: NumberRange?, rotSpeed: NumberRange?,
	spread: Vector2?, accel: Vector3?, transp: NumberSequence?, locked: boolean?, z: number?, drag: number?,
	layout: Enum.ParticleFlipbookLayout?,
}
local function emitter(parent: Instance, o: EmitOpts): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = o.tex
	e.FlipbookLayout = o.layout or Enum.ParticleFlipbookLayout.Grid4x4
	e.FlipbookMode = if o.loop then Enum.ParticleFlipbookMode.Loop else Enum.ParticleFlipbookMode.OneShot
	e.FlipbookFramerate = NumberRange.new(o.fps or 24)
	e.FlipbookStartRandom = o.loop == true
	e.Color, e.Size, e.Lifetime = o.color, o.size, o.life
	e.Speed = o.speed or NumberRange.new(0)
	e.LightEmission = o.light or 1
	e.LightInfluence = 0
	e.Brightness = o.bright or 2
	e.Orientation = o.orient or Enum.ParticleOrientation.FacingCamera
	e.EmissionDirection = o.dir or Enum.NormalId.Top
	e.Rotation = o.rot or NumberRange.new(0, 360)
	e.RotSpeed = o.rotSpeed or NumberRange.new(0)
	e.SpreadAngle = o.spread or Vector2.zero
	e.Acceleration = o.accel or Vector3.zero
	e.Drag = o.drag or 0
	e.Transparency = o.transp or seq(0, 0, 1, 0)
	e.LockedToPart = o.locked == true
	e.ZOffset = o.z or 0
	e.Rate = if o.loop then (o.rate or 10) else 0
	e.Parent = parent
	return e
end

local function burst(at: CFrame, o: EmitOpts, count: number, life: number?)
	local h = holder(at, nil, life or (o.life.Max + 0.6))
	local e = emitter(h, o)
	e:Emit(count)
	return e
end

local function flashLight(at: Vector3, color: Color3, range: number, peak: number, dur: number)
	local h = holder(CFrame.new(at), nil, dur + 0.2)
	local l = Instance.new("PointLight"); l.Color = color; l.Range = range; l.Brightness = peak; l.Shadows = false; l.Parent = h
	TweenService:Create(l, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
end

local function shake(intensity: number, dur: number)
	local cam = Workspace.CurrentCamera
	if not cam then return end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local k = intensity * (1 - (os.clock() - t0) / dur)
			cam.CFrame *= CFrame.Angles(math.rad((math.random() - 0.5) * k), math.rad((math.random() - 0.5) * k), 0)
			task.wait()
		end
	end)
end

local function crackDecal(pos: Vector3, size: number, life: number)
	local p = holder(CFrame.new(pos + Vector3.new(0, 0.03, 0)), Vector3.new(size, 0.05, size), life)
	local d = Instance.new("Decal"); d.Texture = TEX.GroundCrack; d.Face = Enum.NormalId.Top; d.Parent = p
	task.delay(life - 1, function() TweenService:Create(d, TweenInfo.new(1), { Transparency = 1 }):Play() end)
end

local function flatRing(pos: Vector3, color: Color3, size0: number, size1: number, life: number)
	burst(CFrame.new(pos + Vector3.new(0, 0.15, 0)), {
		tex = TEX.Shockwave, color = col(color), size = seq(0, size0, 1, size1), life = NumberRange.new(life),
		speed = NumberRange.new(0.01), orient = Enum.ParticleOrientation.VelocityPerpendicular, dir = Enum.NormalId.Top,
		rot = NumberRange.new(0, 360), bright = 3,
	}, 1)
end

local function rocks(pos: Vector3, n: number, color: Color3)
	for _ = 1, n do
		local r = Instance.new("Part")
		r.Size = Vector3.new(1, 1, 1) * (0.4 + math.random() * 0.8)
		r.Color = color; r.Material = Enum.Material.Slate
		r.CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * 3, 0.5, (math.random() - 0.5) * 3)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		r.CanCollide, r.CanQuery, r.CanTouch = false, false, false
		r.Parent = folder()
		r.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * 30, 25 + math.random() * 20, (math.random() - 0.5) * 30)
		r.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		TweenService:Create(r, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.9), { Size = Vector3.zero }):Play()
		Debris:AddItem(r, 1.6)
	end
end

local ORANGE, GOLD, CYAN, VIOLET, WHITE = Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 200, 80), Color3.fromRGB(110, 230, 255), Color3.fromRGB(170, 100, 255), Color3.new(1, 1, 1)

local function explosionAt(pos: Vector3, scale: number)
	local cf = CFrame.new(pos)
	burst(cf, { tex = TEX.ImpactStar, color = col(WHITE, GOLD), size = seq(0, 7 * scale, 1, 9 * scale), life = NumberRange.new(0.22), bright = 4, z = 2 }, 1)
	burst(cf, { tex = TEX.FireBurst, color = col(Color3.fromRGB(255, 210, 120), ORANGE), size = seq(0, 6 * scale, 1, 10 * scale),
		life = NumberRange.new(0.7, 0.9), speed = NumberRange.new(4, 9), spread = Vector2.new(180, 180), drag = 4, bright = 3, z = 1 }, 5)
	burst(cf, { tex = TEX.HitSpark, color = col(GOLD, ORANGE), size = seq(0, 5 * scale, 1, 6 * scale), life = NumberRange.new(0.25), bright = 4 }, 1)
	burst(cf, { tex = TEX.SmokePuff, color = col(Color3.fromRGB(70, 60, 60), Color3.fromRGB(40, 38, 40)), size = seq(0, 5 * scale, 1, 10 * scale),
		life = NumberRange.new(1.3, 1.7), speed = NumberRange.new(3, 7), spread = Vector2.new(180, 180), drag = 3, light = 0,
		accel = Vector3.new(0, 4, 0), transp = seq(0, 0.2, 0.6, 0.4, 1, 1), z = -1 }, 7)
	flatRing(pos - Vector3.new(0, pos.Y - math.max(pos.Y - 2, 0.6), 0), ORANGE, 4 * scale, 22 * scale, 0.5)
	flashLight(pos, ORANGE, 30 * scale, 8, 0.6)
	shake(1.6 * scale, 0.35)
end

local VFX = {}

function VFX.Fireball(from: Vector3, to: Vector3)
	local dir = (to - from)
	local orb = holder(CFrame.lookAt(from, to), Vector3.new(1.2, 1.2, 1.2), 3)
	orb.Transparency = 0; orb.Shape = Enum.PartType.Ball; orb.Material = Enum.Material.Neon; orb.Color = Color3.fromRGB(255, 170, 70)
	emitter(orb, { tex = TEX.FireBurst, color = col(Color3.fromRGB(255, 200, 110), ORANGE), size = seq(0, 3, 1, 1), life = NumberRange.new(0.35),
		loop = true, rate = 40, fps = 30, speed = NumberRange.new(0.5), bright = 3 })
	emitter(orb, { tex = TEX.SmokePuff, color = col(Color3.fromRGB(80, 60, 50)), size = seq(0, 1, 1, 3), life = NumberRange.new(0.6),
		loop = true, rate = 25, light = 0, transp = seq(0, 0.3, 1, 1), z = -1 })
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.6, 0); a0.Parent = orb
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.6, 0); a1.Parent = orb
	local tr = Instance.new("Trail"); tr.Attachment0, tr.Attachment1 = a0, a1; tr.Texture = TEX.Trail; tr.Lifetime = 0.25
	tr.Color = col(Color3.fromRGB(255, 220, 140), ORANGE); tr.LightEmission = 1; tr.LightInfluence = 0; tr.Brightness = 3
	tr.Transparency = seq(0, 0, 1, 1); tr.FaceCamera = true; tr.Parent = orb
	local l = Instance.new("PointLight"); l.Color = ORANGE; l.Range = 14; l.Brightness = 3; l.Parent = orb
	local travel = math.clamp(dir.Magnitude / 60, 0.25, 0.8)
	local tw = TweenService:Create(orb, TweenInfo.new(travel, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.lookAt(to, to + dir) })
	tw:Play()
	tw.Completed:Wait()
	orb:Destroy()
	explosionAt(to, 1)
end

function VFX.LightningStrike(pos: Vector3)
	burst(CFrame.new(pos + Vector3.new(0, 0.2, 0)), { tex = TEX.ChargeGather, color = col(CYAN), size = seq(0, 10, 1, 4), life = NumberRange.new(0.5),
		speed = NumberRange.new(0.01), orient = Enum.ParticleOrientation.VelocityPerpendicular, bright = 3 }, 1)
	task.wait(0.45)
	for _ = 1, 3 do -- triple strike, each bolt a tall camera-facing flipbook
		local off = Vector3.new((math.random() - 0.5) * 1.5, 0, (math.random() - 0.5) * 1.5)
		burst(CFrame.new(pos + off + Vector3.new(0, 20, 0)), { tex = TEX.Lightning, color = col(WHITE, CYAN),
			size = seq(0, 40, 1, 40), life = NumberRange.new(0.28), bright = 6, rot = NumberRange.new(-6, 6), z = 3 }, 1)
		flashLight(pos + Vector3.new(0, 6, 0), CYAN, 60, 12, 0.25)
		task.wait(0.09)
	end
	burst(CFrame.new(pos + Vector3.new(0, 1, 0)), { tex = TEX.ImpactStar, color = col(WHITE, CYAN), size = seq(0, 9, 1, 11), life = NumberRange.new(0.2), bright = 5, z = 2 }, 1)
	burst(CFrame.new(pos + Vector3.new(0, 1, 0)), { tex = TEX.HitSpark, color = col(WHITE, CYAN), size = seq(0, 7, 1, 8), life = NumberRange.new(0.25), bright = 5 }, 2)
	flatRing(pos, CYAN, 6, 26, 0.5)
	crackDecal(pos, 14, 4)
	shake(2.2, 0.45)
end

function VFX.DashSlash(root: BasePart)
	local cf = root.CFrame
	burst(cf, { tex = TEX.SpeedLines, color = col(WHITE), size = seq(0, 18, 1, 22), life = NumberRange.new(0.3),
		transp = seq(0, 0.3, 1, 1), bright = 1.5, z = -2 }, 1)
	for i, ang in ipairs({ -35, 35 }) do -- two crossing slashes facing forward
		task.delay(0.06 * (i - 1), function()
			burst(cf * CFrame.new(0, 0.5, -3) * CFrame.Angles(0, 0, math.rad(ang)), { tex = TEX.SlashArc, color = col(WHITE, CYAN),
				size = seq(0, 9, 1, 10), life = NumberRange.new(0.28), speed = NumberRange.new(0.01),
				orient = Enum.ParticleOrientation.VelocityPerpendicular, dir = Enum.NormalId.Front, rot = NumberRange.new(ang), bright = 4, z = 1 }, 1)
		end)
	end
	task.delay(0.12, function()
		burst(cf * CFrame.new(0, 0.5, -5), { tex = TEX.HitSpark, color = col(WHITE, CYAN), size = seq(0, 4, 1, 5), life = NumberRange.new(0.25), bright = 4 }, 2)
	end)
	burst(cf * CFrame.new(0, -2.6, 1.5), { tex = TEX.SmokePuff, color = col(Color3.fromRGB(200, 200, 210)), size = seq(0, 1.5, 1, 4),
		life = NumberRange.new(0.6, 0.9), speed = NumberRange.new(2, 5), spread = Vector2.new(60, 60), light = 0, drag = 3, transp = seq(0, 0.3, 1, 1) }, 6)
	shake(0.8, 0.2)
end

function VFX.GroundSlam(pos: Vector3)
	burst(CFrame.new(pos + Vector3.new(0, 1.5, 0)), { tex = TEX.ImpactStar, color = col(WHITE, GOLD), size = seq(0, 8, 1, 10), life = NumberRange.new(0.2), bright = 4, z = 2 }, 1)
	flatRing(pos, GOLD, 4, 26, 0.45)
	task.delay(0.12, function() flatRing(pos, WHITE, 2, 16, 0.4) end)
	crackDecal(pos, 16, 5)
	rocks(pos, 10, Color3.fromRGB(110, 100, 95))
	burst(CFrame.new(pos + Vector3.new(0, 0.5, 0)), { tex = TEX.SmokePuff, color = col(Color3.fromRGB(190, 175, 160)), size = seq(0, 3, 1, 8),
		life = NumberRange.new(0.9, 1.3), speed = NumberRange.new(10, 16), spread = Vector2.new(90, 5), dir = Enum.NormalId.Top,
		drag = 4, light = 0, transp = seq(0, 0.2, 1, 1) }, 14)
	flashLight(pos + Vector3.new(0, 3, 0), GOLD, 26, 5, 0.4)
	shake(2.4, 0.5)
end

function VFX.ChargeBurst(pos: Vector3)
	local h = holder(CFrame.new(pos), nil, 2.2)
	local g = emitter(h, { tex = TEX.ChargeGather, color = col(CYAN, WHITE), size = seq(0, 3, 1, 8), life = NumberRange.new(1.2), loop = true, rate = 1.5, fps = 24, bright = 3 })
	local l = Instance.new("PointLight"); l.Color = CYAN; l.Range = 4; l.Brightness = 1; l.Parent = h
	TweenService:Create(l, TweenInfo.new(1.1), { Range = 18, Brightness = 5 }):Play()
	task.wait(1.1)
	g.Enabled = false
	burst(CFrame.new(pos), { tex = TEX.HatchFlash, color = col(WHITE, CYAN), size = seq(0, 14, 1, 14), life = NumberRange.new(0.5), bright = 5, z = 2 }, 1)
	burst(CFrame.new(pos), { tex = TEX.ImpactStar, color = col(WHITE, CYAN), size = seq(0, 10, 1, 12), life = NumberRange.new(0.2), bright = 5, z = 3 }, 1)
	burst(CFrame.new(pos), { tex = TEX.Sparkle, color = col(Color3.fromRGB(200, 250, 255)), size = seq(0, 1, 1, 1.5), life = NumberRange.new(0.6, 1),
		speed = NumberRange.new(12, 22), spread = Vector2.new(180, 180), drag = 3, loop = true, fps = 20 }, 24)
	flatRing(pos - Vector3.new(0, 2.5, 0), CYAN, 4, 20, 0.45)
	flashLight(pos, CYAN, 40, 10, 0.5)
	shake(1.8, 0.35)
end

function VFX.Portal(cf: CFrame, duration: number?)
	local life = duration or 4
	local h = holder(cf, nil, life)
	emitter(h, { tex = TEX.PortalSwirl, color = col(VIOLET, Color3.fromRGB(230, 200, 255)), size = seq(0, 9, 1, 9), life = NumberRange.new(life),
		loop = true, rate = 0, fps = 16, speed = NumberRange.new(0.01), orient = Enum.ParticleOrientation.VelocityPerpendicular,
		dir = Enum.NormalId.Front, rotSpeed = NumberRange.new(-60), bright = 3 }):Emit(1)
	emitter(h, { tex = TEX.Sparkle, color = col(Color3.fromRGB(230, 200, 255)), size = seq(0, 0.6, 1, 1), life = NumberRange.new(0.8, 1.3),
		loop = true, rate = 14, fps = 20, speed = NumberRange.new(1, 3), spread = Vector2.new(180, 180) })
	burst(cf, { tex = TEX.HatchFlash, color = col(WHITE, VIOLET), size = seq(0, 10, 1, 10), life = NumberRange.new(0.5), bright = 4 }, 1)
	local l = Instance.new("PointLight"); l.Color = VIOLET; l.Range = 20; l.Brightness = 3; l.Parent = h
end

-- Frozen showcase versions: looping emitters that keep the most readable moment on screen.
function VFX.Display(name: string, cf: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Display_" .. name
	local function hold(at: CFrame): Part
		local p = holder(at); p.Parent = m; return p
	end
	local function light(parent: Instance, color: Color3, range: number, bright: number)
		local l = Instance.new("PointLight"); l.Color = color; l.Range = range; l.Brightness = bright; l.Parent = parent
	end
	local glowOpts = function(color: Color3, size: number, rate: number): EmitOpts
		return { tex = TEX.Glow, layout = Enum.ParticleFlipbookLayout.None, color = col(color), size = seq(0, size, 1, size * 1.1),
			life = NumberRange.new(0.6), loop = true, rate = rate, bright = 2, transp = seq(0, 0.6, 0.5, 0.3, 1, 1), z = -1 }
	end
	if name == "Fireball" then
		-- projectile flying right, trail streaming left behind it, impact on the right
		local orb = hold(cf * CFrame.new(-7, 4, 0)); orb.Transparency = 0; orb.Shape = Enum.PartType.Ball; orb.Size = Vector3.new(1.6, 1.6, 1.6)
		orb.Material = Enum.Material.Neon; orb.Color = Color3.fromRGB(255, 240, 200)
		emitter(orb, glowOpts(ORANGE, 4, 12))
		emitter(orb, { tex = TEX.FireBurst, color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 140)), ColorSequenceKeypoint.new(0.5, ORANGE), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 10)) }),
			size = seq(0, 2.6, 1, 0.6), life = NumberRange.new(0.5), loop = true, rate = 60, fps = 30, speed = NumberRange.new(16, 20), dir = Enum.NormalId.Left,
			spread = Vector2.new(8, 8), bright = 1.5 })
		emitter(orb, { tex = TEX.SmokePuff, color = col(Color3.fromRGB(60, 50, 50)), size = seq(0, 1.5, 1, 4), life = NumberRange.new(1), loop = true, rate = 20,
			fps = 14, speed = NumberRange.new(3, 5), dir = Enum.NormalId.Left, spread = Vector2.new(15, 15), light = 0, transp = seq(0, 0.1, 1, 1), z = -2 })
		light(orb, ORANGE, 16, 3)
		local boom = hold(cf * CFrame.new(6, 3, 0))
		emitter(boom, { tex = TEX.FireBurst, color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 170)), ColorSequenceKeypoint.new(0.6, ORANGE), ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 30, 10)) }),
			size = seq(0, 7, 1, 10), life = NumberRange.new(0.9), loop = true, rate = 4, fps = 18, light = 0.5, speed = NumberRange.new(1, 3), spread = Vector2.new(180, 180), bright = 1 })
		emitter(boom, glowOpts(Color3.fromRGB(255, 150, 60), 6, 3))
		emitter(boom, { tex = TEX.SmokePuff, color = col(Color3.fromRGB(55, 48, 48)), size = seq(0, 6, 1, 11), life = NumberRange.new(1.6), loop = true, rate = 6,
			fps = 12, speed = NumberRange.new(2, 4), spread = Vector2.new(180, 180), light = 0, transp = seq(0, 0.1, 1, 1), accel = Vector3.new(0, 2, 0), z = -2 })
		light(boom, ORANGE, 30, 4)
	elseif name == "LightningStrike" then
		local b = hold(cf * CFrame.new(0, 15, 0))
		emitter(b, { tex = TEX.Lightning, color = col(WHITE, CYAN), size = seq(0, 30, 1, 30), life = NumberRange.new(0.3), loop = true, rate = 8, fps = 30,
			bright = 6, rot = NumberRange.new(-5, 5), z = 3 })
		local g = hold(cf * CFrame.new(0, 0.6, 0))
		emitter(g, { tex = TEX.Shockwave, color = col(CYAN), size = seq(0, 6, 1, 22), life = NumberRange.new(0.7), loop = true, rate = 2, fps = 24,
			speed = NumberRange.new(0.01), orient = Enum.ParticleOrientation.VelocityPerpendicular, bright = 3 })
		emitter(g, { tex = TEX.ImpactStar, color = col(WHITE, CYAN), size = seq(0, 7, 1, 8), life = NumberRange.new(0.25), loop = true, rate = 3, fps = 40, bright = 4, z = 2 })
		emitter(g, { tex = TEX.HitSpark, color = col(WHITE, CYAN), size = seq(0, 6, 1, 7), life = NumberRange.new(0.3), loop = true, rate = 5, fps = 40, bright = 4 })
		emitter(g, { tex = TEX.Sparkle, color = col(Color3.fromRGB(200, 250, 255)), size = seq(0, 0.7, 1, 0.3), life = NumberRange.new(0.6, 1), loop = true, rate = 25,
			fps = 20, speed = NumberRange.new(4, 9), spread = Vector2.new(70, 70), accel = Vector3.new(0, -10, 0) })
		local crack = hold(cf * CFrame.new(0, 0.53, 0)); crack.Size = Vector3.new(14, 0.05, 14)
		local d = Instance.new("Decal"); d.Texture = TEX.GroundCrack; d.Face = Enum.NormalId.Top; d.Parent = crack
		light(g, CYAN, 40, 6)
	elseif name == "GroundSlam" then
		local g = hold(cf * CFrame.new(0, 0.6, 0))
		emitter(g, { tex = TEX.Shockwave, color = col(GOLD), size = seq(0, 4, 1, 24), life = NumberRange.new(0.8), loop = true, rate = 2.5, fps = 20,
			speed = NumberRange.new(0.01), orient = Enum.ParticleOrientation.VelocityPerpendicular, bright = 3 })
		emitter(g, { tex = TEX.SmokePuff, color = col(Color3.fromRGB(190, 175, 160)), size = seq(0, 3, 1, 7), life = NumberRange.new(1.2), loop = true,
			rate = 18, fps = 14, speed = NumberRange.new(8, 12), spread = Vector2.new(90, 5), drag = 3, light = 0, transp = seq(0, 0.1, 1, 1) })
		emitter(g, { tex = TEX.ImpactStar, color = col(WHITE, GOLD), size = seq(0, 6, 1, 7), life = NumberRange.new(0.25), loop = true, rate = 2, fps = 40, bright = 3, z = 2 })
		local crack = hold(cf * CFrame.new(0, 0.53, 0)); crack.Size = Vector3.new(16, 0.05, 16)
		local d = Instance.new("Decal"); d.Texture = TEX.GroundCrack; d.Face = Enum.NormalId.Top; d.Parent = crack
		local rr = Random.new(4)
		for _ = 1, 12 do -- debris frozen mid-flight
			local r = hold(cf * CFrame.new(rr:NextNumber(-7, 7), rr:NextNumber(1.5, 7), rr:NextNumber(-7, 7)) * CFrame.Angles(rr:NextNumber(0, 6), rr:NextNumber(0, 6), 0))
			r.Transparency = 0; r.Size = Vector3.new(1, 1, 1) * rr:NextNumber(0.5, 1.3); r.Material = Enum.Material.Slate; r.Color = Color3.fromRGB(110, 100, 95)
		end
		light(g, GOLD, 26, 3)
	elseif name == "ChargeBurst" then
		local c = hold(cf * CFrame.new(0, 4.5, 0))
		emitter(c, glowOpts(CYAN, 5, 10))
		emitter(c, { tex = TEX.ChargeGather, color = col(CYAN, WHITE), size = seq(0, 9, 1, 9), life = NumberRange.new(1.2), loop = true, rate = 1.6, fps = 24, bright = 3 })
		emitter(c, { tex = TEX.Sparkle, color = col(Color3.fromRGB(200, 250, 255)), size = seq(0, 0.9, 1, 0.2), life = NumberRange.new(0.8), loop = true, rate = 30,
			fps = 20, speed = NumberRange.new(-7, -5), spread = Vector2.new(180, 180) }) -- negative speed pulls sparkles inward
		local g = hold(cf * CFrame.new(0, 0.6, 0))
		emitter(g, { tex = TEX.Shockwave, color = col(CYAN), size = seq(0, 12, 1, 4), life = NumberRange.new(1), loop = true, rate = 1.5, fps = 16,
			speed = NumberRange.new(0.01), orient = Enum.ParticleOrientation.VelocityPerpendicular, bright = 2 }) -- ground ring shrinking inward
		light(c, CYAN, 22, 4)
	elseif name == "Portal" then
		local p = hold(cf * CFrame.new(0, 6.5, 0))
		local core = hold(cf * CFrame.new(0, 6.5, 0.2)); core.Transparency = 0; core.Shape = Enum.PartType.Cylinder; core.Size = Vector3.new(0.1, 6, 6)
		core.CFrame = cf * CFrame.new(0, 6.5, 0.3) * CFrame.Angles(0, math.rad(90), 0); core.Color = Color3.fromRGB(14, 6, 30); core.Material = Enum.Material.SmoothPlastic
		emitter(p, { tex = TEX.PortalSwirl, color = col(VIOLET, Color3.fromRGB(230, 200, 255)), size = seq(0, 9, 1, 9), life = NumberRange.new(2),
			loop = true, rate = 0.6, fps = 16, speed = NumberRange.new(0.01), orient = Enum.ParticleOrientation.VelocityPerpendicular,
			dir = Enum.NormalId.Front, rotSpeed = NumberRange.new(-60), bright = 3, transp = seq(0, 1, 0.15, 0, 0.85, 0, 1, 1) })
		emitter(p, { tex = TEX.Sparkle, color = col(Color3.fromRGB(230, 200, 255)), size = seq(0, 0.6, 1, 0.2), life = NumberRange.new(1),
			loop = true, rate = 22, fps = 20, speed = NumberRange.new(-4, -2), spread = Vector2.new(180, 180) })
		local g = hold(cf * CFrame.new(0, 0.6, 0))
		emitter(g, glowOpts(VIOLET, 14, 3))
		light(p, VIOLET, 22, 3)
	elseif name == "DashSlash" then
		local s = hold(cf * CFrame.new(0, 4, 1))
		emitter(s, { tex = TEX.SlashArc, color = col(WHITE, CYAN), size = seq(0, 9, 1, 10), life = NumberRange.new(0.45), loop = true, rate = 3, fps = 32,
			speed = NumberRange.new(0.01), rot = NumberRange.new(-25, 25), bright = 4 })
		emitter(s, { tex = TEX.HitSpark, color = col(WHITE, CYAN), size = seq(0, 5, 1, 6), life = NumberRange.new(0.3), loop = true, rate = 4, fps = 40, bright = 4, z = 2 })
		-- directional streaks along the dash line instead of a camera-facing sunburst
		local tail = hold(cf * CFrame.new(-9, 3, 3))
		emitter(tail, { tex = TEX.Trail, layout = Enum.ParticleFlipbookLayout.None, color = col(WHITE, CYAN), size = seq(0, 1.2, 1, 0.2), life = NumberRange.new(0.4),
			loop = true, rate = 40, speed = NumberRange.new(30, 40), dir = Enum.NormalId.Right, spread = Vector2.new(2, 6), orient = Enum.ParticleOrientation.VelocityParallel,
			bright = 2, transp = seq(0, 0.2, 1, 1) })
		local a0 = Instance.new("Attachment"); a0.Parent = tail; local endp = hold(cf * CFrame.new(4, 1.2, 1)); local a1 = Instance.new("Attachment"); a1.Parent = endp
		local beam = Instance.new("Beam"); beam.Attachment0, beam.Attachment1 = a0, a1; beam.Texture = TEX.Trail; beam.Width0, beam.Width1 = 0.2, 3
		beam.LightEmission = 1; beam.LightInfluence = 0; beam.Brightness = 2; beam.Color = col(CYAN, WHITE); beam.Transparency = seq(0, 0.6, 1, 0); beam.Parent = tail
		emitter(endp, { tex = TEX.SmokePuff, color = col(Color3.fromRGB(200, 200, 210)), size = seq(0, 1.5, 1, 4), life = NumberRange.new(0.8), loop = true, rate = 10,
			fps = 14, speed = NumberRange.new(2, 4), dir = Enum.NormalId.Left, spread = Vector2.new(40, 40), light = 0, transp = seq(0, 0.3, 1, 1) })
		light(s, CYAN, 18, 2)
	end
	m.Parent = folder()
	return m
end

return VFX
