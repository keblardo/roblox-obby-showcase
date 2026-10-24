-- © 2026 Cristian Luis Celie. All rights reserved. Portfolio excerpt from Obby 99 (Roblox prototype): shared for review only, not licensed for use, copying or redistribution.
--[[
  JobChaser.server.lua
  REEMPLAZA el contenido completo de tu script "JobChaser" existente por este.
  Poner en: ServerScriptService (Script)

  Del nivel 20 al 29, una "Solicitud de Empleo" persigue al jugador y lo mata si lo toca.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local function getPlayerLevel(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local z = -hrp.Position.Z
	local level = math.floor(z / Config.LEVEL_SPACING + 0.5)
	return math.clamp(level, 0, Config.TOTAL_LEVELS)
end

local chasersFolder = Instance.new("Folder")
chasersFolder.Name = "JobChasers"
chasersFolder.Parent = Workspace

local function createChaser(player)
	local model = Instance.new("Model")
	model.Name = "SolicitudDeEmpleo_" .. player.Name
	model.Parent = chasersFolder

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Parent = model

	local paper = Instance.new("Part")
	paper.Name = "Paper"
	paper.Size = Vector3.new(4, 5, 0.3)
	paper.Color = Color3.fromRGB(255, 255, 240)
	paper.Material = Enum.Material.SmoothPlastic
	paper.CanCollide = true
	paper.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = paper
	weld.Parent = root
	paper.CFrame = root.CFrame

	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/face.png"
	decal.Face = Enum.NormalId.Front
	decal.Parent = paper

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	model.PrimaryPart = root

	model:SetAttribute("OwnerPlayer", player.UserId)

	return model
end

local activeChasers = {}

local function killPlayer(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

RunService.Heartbeat:Connect(function(dt)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local level = getPlayerLevel(character)
			local inChaseZone = level and level >= Config.CHASER_START_LEVEL and level <= Config.CHASER_END_LEVEL

			if inChaseZone then
				local chaser = activeChasers[player]
				if not chaser or not chaser.Parent then
					chaser = createChaser(player)
					activeChasers[player] = chaser
					local hrp = character.HumanoidRootPart
					chaser:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0, 0, 15))
				end

				local root = chaser:FindFirstChild("HumanoidRootPart")
				local targetHrp = character.HumanoidRootPart
				if root then
					local direction = (targetHrp.Position - root.Position)
					local distance = direction.Magnitude
					if distance > 0.5 then
						local speed = 12
						local step = direction.Unit * math.min(speed * dt, distance)
						root.CFrame = CFrame.new(root.Position + step, root.Position + step + direction)
						chaser:SetPrimaryPartCFrame(root.CFrame)
					end

					if distance <= 3 then
						killPlayer(player)
					end
				end
			else
				local chaser = activeChasers[player]
				if chaser then
					chaser:Destroy()
					activeChasers[player] = nil
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local chaser = activeChasers[player]
	if chaser then
		chaser:Destroy()
		activeChasers[player] = nil
	end
end)
