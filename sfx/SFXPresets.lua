--!strict
-- SFXPresets: plays the portfolio's sound set through SoundGroup buses (UI, SFX, Vehicle, Ambience).
-- The game mix is already baked into the .ogg files (see mix.txt), so per-sound Volume stays at 1
-- and the buses are what a settings menu should expose as sliders.
-- Upload each file in sfx/ogg through the Asset Manager and paste the ids below.
--
--   local SFX = require(path.to.SFXPresets)
--   SFX.play("ui_click")                    -- 2D, for UI
--   SFX.playAt("sword_hit", hitPosition)     -- 3D, positioned in the world (picks a random variation)
--   local engine = SFX.loop("kart_engine_loop", kart.PrimaryPart)
--   engine.PlaybackSpeed = 0.8 + speed / 60  -- rev with the kart's speed

local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

type Def = { ids: { string }, bus: string, pitch: number?, loop: boolean? }

local function ids(n: number): { string }
	local t = {}
	for i = 1, n do t[i] = "rbxassetid://0" end -- one id per variation file (name_1, name_2, ...)
	return t
end

local SOUNDS: { [string]: Def } = {
	ui_click         = { ids = ids(1), bus = "UI", pitch = 0.04 },
	ui_hover         = { ids = ids(1), bus = "UI" },
	ui_denied        = { ids = ids(1), bus = "UI" },
	notification_pop = { ids = ids(1), bus = "UI" },
	coin_pickup      = { ids = ids(3), bus = "SFX", pitch = 0.03 },
	reward_jingle    = { ids = ids(1), bus = "SFX" },
	egg_crack        = { ids = ids(3), bus = "SFX" },
	egg_hatch        = { ids = ids(1), bus = "SFX" },
	blaster_shot     = { ids = ids(3), bus = "SFX", pitch = 0.04 },
	sword_swing      = { ids = ids(3), bus = "SFX", pitch = 0.05 },
	sword_hit        = { ids = ids(3), bus = "SFX", pitch = 0.04 },
	explosion        = { ids = ids(1), bus = "SFX", pitch = 0.05 },
	footstep_stone   = { ids = ids(3), bus = "SFX", pitch = 0.06 },
	footstep_grass   = { ids = ids(3), bus = "SFX", pitch = 0.06 },
	jump             = { ids = ids(1), bus = "SFX", pitch = 0.05 },
	kart_engine_loop = { ids = ids(1), bus = "Vehicle", loop = true },
	door_knock       = { ids = ids(1), bus = "Ambience" },
}

local BUS_VOLUME = { UI = 0.8, SFX = 1.0, Vehicle = 0.9, Ambience = 1.0 }

-- Buses are best created once in Studio. As a fallback, the server creates any that are missing
-- and clients wait for them to replicate, so both sides never race to create duplicates.
local buses: { [string]: SoundGroup } = {}
for name, vol in BUS_VOLUME do
	local g = SoundService:FindFirstChild(name) :: SoundGroup?
	if not g then
		if RunService:IsServer() then
			local ng = Instance.new("SoundGroup")
			ng.Name = name
			ng.Volume = vol
			ng.Parent = SoundService
			g = ng
		else
			g = SoundService:WaitForChild(name, 5) :: SoundGroup?
		end
	end
	if g then buses[name] = g end
end

local rng = Random.new()
local lastVariant: { [string]: number } = {}

local function pick(name: string, d: Def): string
	if #d.ids == 1 then return d.ids[1] end
	local i = rng:NextInteger(1, #d.ids)
	if i == lastVariant[name] then i = i % #d.ids + 1 end -- never the same take twice in a row
	lastVariant[name] = i
	return d.ids[i]
end

local function make(name: string, parent: Instance): Sound
	local d = SOUNDS[name]
	assert(d, `Unknown sound "{name}"`)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = pick(name, d)
	s.Volume = 1
	s.Looped = d.loop == true
	s.SoundGroup = buses[d.bus]
	if d.pitch then
		s.PlaybackSpeed = 1 + rng:NextNumber(-d.pitch, d.pitch)
	end
	s.Parent = parent
	return s
end

local SFX = {}

function SFX.play(name: string): Sound
	local s = make(name, SoundService)
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
	Debris:AddItem(s, 10) -- fallback if the asset never loads and Ended never fires
	return s
end

function SFX.playAt(name: string, position: Vector3): Sound
	local holder = Instance.new("Attachment")
	holder.Parent = workspace.Terrain -- parent first, then position
	holder.WorldPosition = position
	local s = make(name, holder)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = 120
	s:Play()
	Debris:AddItem(holder, 10)
	return s
end

function SFX.loop(name: string, parent: Instance): Sound
	local s = make(name, parent)
	s.Looped = true
	s:Play()
	return s
end

return SFX
