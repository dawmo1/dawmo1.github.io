--!strict
-- ApplyPBR: run once in Studio (command bar or plugin) after importing the .fbx files in models/*/ with File > Import 3D.
-- Finds each imported MeshPart by its Blender object name, adds a SurfaceAppearance with the baked maps,
-- sets its real size in studs, turns the glow meshes into Neon parts aligned to their parent mesh,
-- and lays every model out on a display row.

local STUD = 1 / 0.28 -- studs per metre (Roblox's avatar scale)

-- Blender sizes/centres are in metres, Z-up. Roblox is Y-up: (x, y, z) -> (x, z, -y).
local function rb(v: { number }): Vector3
	return Vector3.new(v[1], v[3], -v[2]) * STUD
end

type Main = { key: string, mesh: string, size: { number }, center: { number }, maps: { [string]: string }, stand: boolean }
local MODELS: { Main } = {
	{ key = "Carbine", mesh = "CB_Carbine_Game", size = { 0.933, 0.052, 0.364 }, center = { 0.0585, 0, -0.026 }, stand = true,
		maps = { ColorMap = "rbxassetid://110246233540403", MetalnessMap = "rbxassetid://107372105022928", RoughnessMap = "rbxassetid://86685406982632", NormalMap = "rbxassetid://83695781571102" } },
	{ key = "Greatsword", mesh = "GS_Greatsword_Game", size = { 0.393, 0.045, 1.465 }, center = { 0, 0, 0.3875 }, stand = true,
		maps = { ColorMap = "rbxassetid://130681486908570", MetalnessMap = "rbxassetid://120695032209634", RoughnessMap = "rbxassetid://122865995225366", NormalMap = "rbxassetid://71502732184799" } },
	{ key = "Blaster", mesh = "BL_Blaster_Game", size = { 0.9895, 0.0691, 0.315 }, center = { 0.1098, -0.001, 0.0325 }, stand = true,
		maps = { ColorMap = "rbxassetid://92531055544504", MetalnessMap = "rbxassetid://98308464361013", RoughnessMap = "rbxassetid://112371272998447", NormalMap = "rbxassetid://110533712724700" } },
	{ key = "Chest", mesh = "CH_Chest_Game", size = { 0.8749, 0.533, 0.707 }, center = { 0, 0.0015, 0.3535 }, stand = false,
		maps = { ColorMap = "rbxassetid://129724414442978", MetalnessMap = "rbxassetid://106807358691911", RoughnessMap = "rbxassetid://85394708061436", NormalMap = "rbxassetid://130488555019520" } },
	{ key = "ChestOpen", mesh = "CH_ChestOpen_Game", size = { 0.8749, 1.0177, 0.9566 }, center = { 0, 0.07, 0.4783 }, stand = false,
		maps = { ColorMap = "rbxassetid://85747514015872", MetalnessMap = "rbxassetid://76993933811455", RoughnessMap = "rbxassetid://77088260130462", NormalMap = "rbxassetid://124991827383100" } },
	{ key = "Kart", mesh = "KT_Kart_Game", size = { 1.7579, 1.448, 0.5159 }, center = { 0.0166, 0, 0.258 }, stand = false,
		maps = { ColorMap = "rbxassetid://75828342641082", MetalnessMap = "rbxassetid://127216182911336", RoughnessMap = "rbxassetid://134478021078012", NormalMap = "rbxassetid://82828179793389" } },
}
-- glow meshes: aligned to their parent by the centre offset measured in Blender
local NEON = {
	{ parent = "Greatsword", mesh = "GS_Ember", size = { 0.0071, 0.0073, 0.66 }, center = { 0, 0, 0.5 }, color = Color3.fromRGB(255, 110, 30) },
	{ parent = "Blaster", mesh = "BL_Neon_Game", size = { 0.552, 0.065, 0.243 }, center = { 0.271, 0, 0.0615 }, color = Color3.fromRGB(60, 230, 255) },
}

local function find(name: string): MeshPart?
	for _, d in workspace:GetDescendants() do
		if d:IsA("MeshPart") and (d.Name == name or d.Name:find(name, 1, true)) and not d:FindFirstAncestor("PBR_Showcase") then return d end
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("MeshPart") and d.Name == name then return d end
	end
	return nil
end

local root = workspace:FindFirstChild("PBR_Showcase") or Instance.new("Folder")
root.Name = "PBR_Showcase"; root.Parent = workspace
local ROW_Z, SPACING = 70, 16
local placed: { [string]: MeshPart } = {}
local report = {}

for i, m in MODELS do
	local mp = find(m.mesh)
	if not mp then table.insert(report, m.key .. ": not imported yet"); continue end
	local oldModel = mp.Parent
	local model = Instance.new("Model"); model.Name = m.key; model.Parent = root
	mp.Parent = model
	if oldModel and oldModel ~= workspace and oldModel:IsA("Model") and #oldModel:GetChildren() == 0 then oldModel:Destroy() end
	for _, c in mp:GetChildren() do if c:IsA("SurfaceAppearance") then c:Destroy() end end
	local sa = Instance.new("SurfaceAppearance")
	for prop, id in m.maps do (sa :: any)[prop] = id end
	sa.Parent = mp
	mp.Size = rb(m.size):Abs()
	mp.Anchored = true; mp.CanCollide = false; mp.CastShadow = true
	local x = (i - (#MODELS + 1) / 2) * SPACING
	local groundY = 0.5
	local lift = if m.stand then 4 else 0
	if m.stand then
		local plinth = Instance.new("Part"); plinth.Name = "Plinth"; plinth.Anchored = true; plinth.Material = Enum.Material.Slate
		plinth.Color = Color3.fromRGB(32, 34, 40); plinth.Size = Vector3.new(6, 2.5, 4); plinth.CFrame = CFrame.new(x, groundY + 1.25, ROW_Z); plinth.Parent = model
		lift = 2.5 + mp.Size.Y / 2 + 0.6
	else
		lift = mp.Size.Y / 2
	end
	-- the importer flips meshes 180° around Y; turn them back so the detailed side faces +Z
	mp.CFrame = CFrame.new(x, groundY + lift, ROW_Z) * CFrame.Angles(0, math.pi, 0)
	placed[m.key] = mp
	table.insert(report, string.format("%s: %.1f x %.1f x %.1f studs", m.key, mp.Size.X, mp.Size.Y, mp.Size.Z))
end

for _, n in NEON do
	local mp = find(n.mesh); local parent = placed[n.parent]
	if not mp or not parent then table.insert(report, n.mesh .. ": skipped (missing)"); continue end
	local mainDef: Main? = nil
	for _, m in MODELS do if m.key == n.parent then mainDef = m end end
	assert(mainDef)
	local oldModel = mp.Parent
	mp.Parent = parent.Parent
	if oldModel and oldModel ~= workspace and oldModel:IsA("Model") and #oldModel:GetChildren() == 0 then oldModel:Destroy() end
	mp.Size = rb(n.size):Abs(); mp.Material = Enum.Material.Neon; mp.Color = n.color; mp.Anchored = true; mp.CanCollide = false; mp.CastShadow = false
	-- imported meshes map Blender (x, y, z) to local (-x, z, y), so the centre offset goes through the same mapping
	local dx, dy, dz = n.center[1] - mainDef.center[1], n.center[2] - mainDef.center[2], n.center[3] - mainDef.center[3]
	mp.CFrame = parent.CFrame * CFrame.new(-dx * STUD, dz * STUD, dy * STUD)
	local glowHost: BasePart = mp
	if n.mesh == "GS_Ember" then
		-- the ember ribbons are single-sided and sit flush with the steel, so Roblox hides them; use two thin Neon strips instead
		mp.Transparency = 1
		for i, sgn in { 1, -1 } do
			local strip = Instance.new("Part"); strip.Name = if i == 1 then "EmberFront" else "EmberBack"
			strip.Anchored = true; strip.CanCollide = false; strip.CastShadow = false; strip.Material = Enum.Material.Neon
			strip.Color = Color3.fromRGB(230, 70, 15); strip.Size = Vector3.new(0.045, mp.Size.Y, 0.004)
			strip.CFrame = mp.CFrame * CFrame.new(0, 0, sgn * 0.022); strip.Parent = mp.Parent
			if i == 1 then glowHost = strip end
		end
	end
	local glow = Instance.new("PointLight"); glow.Color = n.color; glow.Range = 8; glow.Brightness = 1.5; glow.Parent = glowHost
	table.insert(report, n.mesh .. ": neon aligned")
end

return table.concat(report, "\n")
