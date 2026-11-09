--!strict
-- VFXPresets: builds the portfolio's flipbook effects as ParticleEmitters / Beams.
-- Upload each sheet in vfx/sheets (and vfx/textures) through the Asset Manager, then put the
-- returned ids in TEXTURES below. Sheets are white + alpha, so Color tints them.
--
-- Best practice: call these from a LocalScript (fire a RemoteEvent from the server with the
-- position). On the server, bursts are emitted a moment after the emitter replicates.
--
--   local VFX = require(path.to.VFXPresets)
--   VFX.burst("HitSpark", attachment)              -- one-shot: emits, then cleans itself up
--   local aura = VFX.loop("EmberFire", attachment)  -- looping: Destroy() it to stop
--   VFX.beam(muzzleAttachment, hitAttachment)

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local TEXTURES: { [string]: string } = {
	SlashArc = "rbxassetid://0",   -- sheets/slash_arc_4x4.png
	HitSpark = "rbxassetid://0",   -- sheets/hit_spark_4x4.png
	EmberFire = "rbxassetid://0",  -- sheets/ember_fire_4x4.png
	HatchFlash = "rbxassetid://0", -- sheets/hatch_flash_4x4.png
	Shockwave = "rbxassetid://0",  -- sheets/shockwave_4x4.png
	Sparkle = "rbxassetid://0",    -- sheets/sparkle_4x4.png
	SmokePuff = "rbxassetid://0",  -- sheets/smoke_puff_4x4.png
	BeamEnergy = "rbxassetid://0", -- textures/beam_energy_tile.png
}

type Preset = {
	color: ColorSequence,
	size: NumberSequence,
	lifetime: NumberRange,
	speed: NumberRange,
	loop: boolean,
	count: number?,                        -- one-shot: particles per burst
	rate: number?,                         -- looping: particles per second
	framerate: number?,                    -- looping: flipbook frames per second
	lightEmission: number,
	brightness: number?,
	orientation: Enum.ParticleOrientation?,
	direction: Enum.NormalId?,
	rotation: NumberRange?,
	spread: Vector2?,
	acceleration: Vector3?,
	transparency: NumberSequence?,
	lockedToPart: boolean?,
}

local function seq(...: number): NumberSequence
	local args = { ... }
	local keys = {}
	for i = 1, #args, 2 do
		table.insert(keys, NumberSequenceKeypoint.new(args[i], args[i + 1]))
	end
	return NumberSequence.new(keys)
end

local PRESETS: { [string]: Preset } = {
	SlashArc = {
		color = ColorSequence.new(Color3.fromRGB(150, 240, 255), Color3.fromRGB(60, 200, 255)),
		size = seq(0, 6, 1, 6.5), lifetime = NumberRange.new(0.3), speed = NumberRange.new(0.01),
		count = 1, loop = false, lightEmission = 1, brightness = 2,
		-- faces along the attachment's look direction instead of spinning with the camera
		orientation = Enum.ParticleOrientation.VelocityPerpendicular, direction = Enum.NormalId.Front,
		rotation = NumberRange.new(-15, 15), lockedToPart = true,
	},
	HitSpark = {
		color = ColorSequence.new(Color3.fromRGB(255, 235, 170), Color3.fromRGB(255, 150, 40)),
		size = seq(0, 3, 1, 3.5), lifetime = NumberRange.new(0.25), speed = NumberRange.new(0),
		count = 1, loop = false, lightEmission = 1, brightness = 3, rotation = NumberRange.new(0, 360),
	},
	EmberFire = {
		color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 80, 20)),
		size = seq(0, 2.2, 1, 2.2), lifetime = NumberRange.new(1.2), speed = NumberRange.new(0),
		rate = 2, framerate = 24, loop = true, lightEmission = 0.8, brightness = 1.5,
		transparency = seq(0, 1, 0.15, 0, 0.85, 0, 1, 1), lockedToPart = true,
	},
	HatchFlash = {
		color = ColorSequence.new(Color3.fromRGB(235, 210, 255), Color3.fromRGB(180, 110, 255)),
		size = seq(0, 6, 1, 6), lifetime = NumberRange.new(0.55), speed = NumberRange.new(0), -- the texture does the growing
		count = 1, loop = false, lightEmission = 1, brightness = 3,
	},
	Shockwave = {
		color = ColorSequence.new(Color3.fromRGB(150, 240, 255)),
		size = seq(0, 12, 1, 12), lifetime = NumberRange.new(0.45), speed = NumberRange.new(0.01),
		count = 1, loop = false, lightEmission = 1, brightness = 2,
		-- lies flat on the ground: velocity points up, particle plane is perpendicular to it
		orientation = Enum.ParticleOrientation.VelocityPerpendicular, direction = Enum.NormalId.Top,
	},
	Sparkle = {
		color = ColorSequence.new(Color3.fromRGB(255, 230, 140)),
		size = seq(0, 0.7, 1, 0.9), lifetime = NumberRange.new(0.6, 1.0), speed = NumberRange.new(0.2, 0.6),
		rate = 6, framerate = 20, loop = true, lightEmission = 1, brightness = 2,
		spread = Vector2.new(180, 180), rotation = NumberRange.new(0, 360),
	},
	SmokePuff = {
		color = ColorSequence.new(Color3.fromRGB(200, 200, 210)),
		size = seq(0, 2, 1, 4), lifetime = NumberRange.new(0.8, 1.1), speed = NumberRange.new(1, 2.5),
		count = 6, loop = false, lightEmission = 0, spread = Vector2.new(70, 70),
		acceleration = Vector3.new(0, 1.5, 0), rotation = NumberRange.new(0, 360),
	},
}

local function makeEmitter(name: string, parent: Instance): ParticleEmitter
	local p = PRESETS[name]
	assert(p, `Unknown VFX preset "{name}"`)
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = TEXTURES[name]
	e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	-- OneShot plays the 16 frames over each particle's lifetime; Loop uses FlipbookFramerate (default is 1 fps)
	e.FlipbookMode = if p.loop then Enum.ParticleFlipbookMode.Loop else Enum.ParticleFlipbookMode.OneShot
	e.FlipbookFramerate = NumberRange.new(p.framerate or 24)
	e.FlipbookStartRandom = p.loop
	e.Color = p.color
	e.Size = p.size
	e.Transparency = p.transparency or seq(0, 0, 1, 0)
	e.Lifetime = p.lifetime
	e.Speed = p.speed
	e.LightEmission = p.lightEmission
	e.LightInfluence = 0 -- glow stays bright at night
	e.Brightness = p.brightness or 1
	e.Orientation = p.orientation or Enum.ParticleOrientation.FacingCamera
	e.EmissionDirection = p.direction or Enum.NormalId.Top
	e.Rotation = p.rotation or NumberRange.new(0)
	e.SpreadAngle = p.spread or Vector2.zero
	e.Acceleration = p.acceleration or Vector3.zero
	e.LockedToPart = p.lockedToPart == true
	e.Rate = if p.loop then (p.rate or 10) else 0
	e.Parent = parent
	return e
end

local VFX = {}

-- One-shot effect: emits once, then removes itself after its lifetime.
function VFX.burst(name: string, parent: Attachment | BasePart): ParticleEmitter
	local e = makeEmitter(name, parent)
	local count = PRESETS[name].count or 1
	if RunService:IsServer() then
		-- give the new emitter time to replicate before emitting, or clients never see it
		task.delay(0.1, function() e:Emit(count) end)
	else
		e:Emit(count)
	end
	Debris:AddItem(e, e.Lifetime.Max + 0.5)
	return e
end

-- Looping effect (auras, fire, ambient sparkles). Destroy it to stop.
function VFX.loop(name: string, parent: Attachment | BasePart): ParticleEmitter
	return makeEmitter(name, parent)
end

-- Scrolling energy beam between two attachments (e.g. the Volt Blaster's muzzle and the hit point).
function VFX.beam(a0: Attachment, a1: Attachment, color: Color3?): Beam
	local b = Instance.new("Beam")
	b.Attachment0, b.Attachment1 = a0, a1
	b.Texture = TEXTURES.BeamEnergy
	b.TextureMode = Enum.TextureMode.Wrap
	b.TextureLength = 4
	b.TextureSpeed = 3
	b.Width0, b.Width1 = 0.6, 0.35
	b.LightEmission = 1
	b.LightInfluence = 0
	b.Brightness = 2
	b.Transparency = NumberSequence.new(0)
	b.FaceCamera = true
	b.Color = ColorSequence.new(color or Color3.fromRGB(120, 235, 255))
	b.Parent = a0
	return b
end

return VFX
