--!strict
-- ServerStorage.PortfolioAnimations.Build
-- Turns one table from animation/studio/*.luau (made by tools/rbxanim_to_luau.py) into an R15 KeyframeSequence.
--
-- Usage:
--   local build = require(ServerStorage.PortfolioAnimations.Build)
--   local seq = build("Sword", data, false, Enum.AnimationPriority.Action)
--   seq.Parent = ServerStorage.PortfolioAnimations
--
-- data rows: { time, {qx,qy,qz,qw[,x,y,z]} x 15 R15 parts in the order of P below }.
-- For a looping clip, append a copy of the first row at the loop period so the seam is exact.

local P = {"LowerTorso","UpperTorso","Head","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand",
	"LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
local PARENT = {LowerTorso="HumanoidRootPart", UpperTorso="LowerTorso", Head="UpperTorso", LeftUpperArm="UpperTorso", LeftLowerArm="LeftUpperArm",
	LeftHand="LeftLowerArm", RightUpperArm="UpperTorso", RightLowerArm="RightUpperArm", RightHand="RightLowerArm", LeftUpperLeg="LowerTorso",
	LeftLowerLeg="LeftUpperLeg", LeftFoot="LeftLowerLeg", RightUpperLeg="LowerTorso", RightLowerLeg="RightUpperLeg", RightFoot="RightLowerLeg"}

return function(name: string, data: {any}, loop: boolean, priority: Enum.AnimationPriority): KeyframeSequence
	local seq = Instance.new("KeyframeSequence")
	seq.Name = name; seq.Loop = loop; seq.Priority = priority
	for _, row in data do
		local kf = Instance.new("Keyframe"); kf.Time = row[1]
		local root = Instance.new("Pose"); root.Name = "HumanoidRootPart"; root.Weight = 0
		local poses: {[string]: Pose} = {HumanoidRootPart = root}
		for i, part in P do
			local v = row[i + 1]
			local pose = Instance.new("Pose"); pose.Name = part
			pose.EasingStyle = Enum.PoseEasingStyle.Linear -- keys are baked at 30 fps, so linear between them is exact
			pose.CFrame = CFrame.new(v[5] or 0, v[6] or 0, v[7] or 0, v[1], v[2], v[3], v[4])
			poses[part] = pose
		end
		for _, part in P do
			local parentName = PARENT[part]
			poses[part].Parent = poses[parentName]
		end
		root.Parent = kf
		kf.Parent = seq
	end
	return seq
end
