-- © 2026 Cristian Luis Celie. All rights reserved. Portfolio excerpt from Obby 99 (Roblox prototype): shared for review only, not licensed for use, copying or redistribution.
--[[
  ObbyBuilder.server.lua
  REEMPLAZA el contenido completo de tu script "obbybuilder" existente por este.
  Poner en: ServerScriptService (Script)

  Genera: Lobby (con 3 puestos + ruleta decorativa) + 99 niveles coloridos y variados +
  zona zen en el nivel 50 + números de nivel visibles + sin suelo (usa VoidKill.server.lua
  para matar si caes).
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

-- ===== Limpieza de restos de plantillas anteriores =====
local oldBaseplate = Workspace:FindFirstChild("Baseplate")
if oldBaseplate and oldBaseplate:IsA("BasePart") then
	oldBaseplate:Destroy()
end

-- ===== Cielo / iluminación =====
Lighting.Brightness = 3
Lighting.Ambient = Color3.fromRGB(150, 170, 200)
Lighting.OutdoorAmbient = Color3.fromRGB(180, 190, 210)
Lighting.ClockTime = 13
Lighting.FogEnd = 100000

local obbyFolder = Instance.new("Folder")
obbyFolder.Name = "Obby"
obbyFolder.Parent = Workspace

local checkpointsFolder = Instance.new("Folder")
checkpointsFolder.Name = "Checkpoints"
checkpointsFolder.Parent = obbyFolder

local LEVEL_SPACING = Config.LEVEL_SPACING
local BASE_Y = Config.BASE_Y
local HEIGHT_LEVEL_STEP = Config.HEIGHT_LEVEL_STEP

local function makePart(name, size, cframe, color, parent, canCollide, transparency, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Anchored = true
	p.CanCollide = canCollide ~= false
	p.Transparency = transparency or 0
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function makeKillDot(cframe, parent)
	local kill = makePart("KillDot", Vector3.new(2, 1, 2), cframe, Color3.fromRGB(255, 30, 30), parent, true, 0, Enum.Material.Neon)
	kill.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)
	return kill
end

local function makeLevelSign(levelNumber, cframe, parent)
	local signPart = Instance.new("Part")
	signPart.Name = "LevelSign"
	signPart.Size = Vector3.new(1, 1, 1)
	signPart.CFrame = cframe
	signPart.Anchored = true
	signPart.CanCollide = false
	signPart.Transparency = 1
	signPart.Parent = parent

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = signPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "NIVEL " .. tostring(levelNumber)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromHSV((levelNumber % 20) / 20, 0.8, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard

	return signPart
end

-- ===== Checkpoints =====
local CheckpointPositions = {}

local function makeCheckpoint(index, cframe)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Checkpoint" .. index
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = cframe
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromHSV((index % 30) / 30, 0.6, 1)
	spawn.Material = Enum.Material.Neon
	spawn.Enabled = (index == 0)
	spawn.Parent = checkpointsFolder

	spawn.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			for _, cp in ipairs(checkpointsFolder:GetChildren()) do
				if cp:IsA("SpawnLocation") then
					cp.Enabled = false
				end
			end
			spawn.Enabled = true
			player:SetAttribute("LastCheckpointY", spawn.Position.Y)
			player:SetAttribute("LastCheckpointLevel", index)
		end
	end)

	CheckpointPositions[index] = spawn.Position
	return spawn
end

-- ===== Obstáculos reutilizables =====
local function buildJumpPlatforms(originCFrame, hue, parent)
	for step = 1, 4 do
		local offsetX = (step % 2 == 0) and 7 or -7
		local cf = originCFrame * CFrame.new(offsetX, 0, -step * 9)
		makePart("Jump" .. step, Vector3.new(6, 1, 6), cf, Color3.fromHSV(hue, 0.7, 1), parent)
	end
end

local function buildNarrowBridge(originCFrame, hue, parent)
	local bridge = makePart("Bridge", Vector3.new(4, 1, 34), originCFrame * CFrame.new(0, 0, -18), Color3.fromHSV(hue, 0.7, 1), parent)
	for i = 1, 6 do
		local side = (i % 2 == 0) and 4 or -4
		makeKillDot(originCFrame * CFrame.new(side, 1, -i * 5), parent)
	end
end

local function buildZigzagStairs(originCFrame, hue, parent)
	for step = 1, 5 do
		local offsetX = (step % 2 == 0) and 6 or -6
		local cf = originCFrame * CFrame.new(offsetX, step * 1.5, -step * 7)
		makePart("Stair" .. step, Vector3.new(6, 1, 6), cf, Color3.fromHSV(hue, 0.7, 1), parent)
	end
end

local function buildDisappearingRun(originCFrame, hue, parent)
	for step = 1, 4 do
		local cf = originCFrame * CFrame.new(0, 0, -step * 8)
		local plat = makePart("Vanish" .. step, Vector3.new(6, 1, 6), cf, Color3.fromHSV(hue, 0.9, 1), parent, true, 0, Enum.Material.Neon)
		CollectionService:AddTag(plat, "DisappearingPlatform")
	end
end

local function buildSpinnerSection(originCFrame, hue, parent)
	makePart("SpinnerBase1", Vector3.new(8, 1, 8), originCFrame * CFrame.new(0, 0, -10), Color3.fromHSV(hue, 0.7, 1), parent)
	local spinner = makePart("Spinner", Vector3.new(14, 1, 3), originCFrame * CFrame.new(0, 2, -20), Color3.fromRGB(255, 140, 0), parent, true, 0, Enum.Material.Neon)
	CollectionService:AddTag(spinner, "Spinner")
	makePart("SpinnerBase2", Vector3.new(8, 1, 8), originCFrame * CFrame.new(0, 0, -30), Color3.fromHSV(hue, 0.7, 1), parent)
end

local OBSTACLE_TYPES = { buildJumpPlatforms, buildNarrowBridge, buildZigzagStairs, buildDisappearingRun, buildSpinnerSection }

-- ===== Lobby =====
local function buildStall(name, cframe, color, parent)
	local booth = makePart(name .. "_Booth", Vector3.new(10, 6, 8), cframe, color, parent)
	booth.Transparency = 0.2

	local npc = Instance.new("Model")
	npc.Name = name .. "_NPC"
	npc.Parent = parent

	local torso = makePart("Torso", Vector3.new(2, 3, 1), cframe * CFrame.new(0, 2, -5), Color3.fromRGB(50, 50, 50), npc)
	local head = makePart("Head", Vector3.new(1.5, 1.5, 1.5), cframe * CFrame.new(0, 4.2, -5), Color3.fromRGB(255, 224, 189), npc)
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 150, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = billboard
end

local function buildLobby()
	local lobbyCFrame = CFrame.new(0, BASE_Y, 0)
	makePart("LobbyFloor", Vector3.new(60, 2, 60), lobbyCFrame, Color3.fromRGB(120, 200, 255), obbyFolder, true, 0, Enum.Material.Neon)

	buildStall("Tienda", lobbyCFrame * CFrame.new(-20, 4, 15), Color3.fromRGB(80, 200, 120), obbyFolder)
	buildStall("Mejoras", lobbyCFrame * CFrame.new(0, 4, 15), Color3.fromRGB(200, 160, 60), obbyFolder)
	buildStall("Armas", lobbyCFrame * CFrame.new(20, 4, 15), Color3.fromRGB(200, 60, 60), obbyFolder)

	-- Ruleta decorativa (funcionalidad en fase 2)
	local wheel = makePart("Ruleta", Vector3.new(10, 2, 10), lobbyCFrame * CFrame.new(0, 3, -15), Color3.fromRGB(255, 215, 0), obbyFolder, true, 0, Enum.Material.Neon)
	local wheelSign = Instance.new("BillboardGui")
	wheelSign.Size = UDim2.new(0, 200, 0, 50)
	wheelSign.StudsOffset = Vector3.new(0, 3, 0)
	wheelSign.AlwaysOnTop = true
	wheelSign.Parent = wheel
	local wheelLabel = Instance.new("TextLabel")
	wheelLabel.Size = UDim2.new(1, 0, 1, 0)
	wheelLabel.BackgroundTransparency = 1
	wheelLabel.Text = "Ruleta (próximamente)"
	wheelLabel.TextScaled = true
	wheelLabel.Font = Enum.Font.GothamBold
	wheelLabel.TextColor3 = Color3.new(1, 1, 1)
	wheelLabel.TextStrokeTransparency = 0
	wheelLabel.Parent = wheelSign

	makeCheckpoint(0, lobbyCFrame + Vector3.new(0, 3, 0))
	makeLevelSign(0, lobbyCFrame + Vector3.new(0, 8, 20), obbyFolder)
end

-- ===== Zona Zen (nivel 50) =====
local function buildZenZone(z, y)
	local zenCFrame = CFrame.new(0, y, -z)
	local floor = makePart("ZenFloor", Vector3.new(50, 2, 50), zenCFrame, Color3.fromRGB(255, 205, 220), obbyFolder, true, 0, Enum.Material.Pebble)

	-- Marcador de zona (para que scripts futuros de PvP sepan que aquí no hay daño)
	local marker = Instance.new("Part")
	marker.Name = "ZenZoneMarker"
	marker.Transparency = 1
	marker.CanCollide = false
	marker.Anchored = true
	marker.Size = Vector3.new(1, 1, 1)
	marker.CFrame = zenCFrame
	marker.Parent = obbyFolder
	marker:SetAttribute("MinZ", -(z + 25))
	marker:SetAttribute("MaxZ", -(z - 25))
	CollectionService:AddTag(marker, "ZenZone")

	-- Torii decorativo
	makePart("ToriiLeft", Vector3.new(1.5, 12, 1.5), zenCFrame * CFrame.new(-8, 6, 20), Color3.fromRGB(200, 60, 40), obbyFolder)
	makePart("ToriiRight", Vector3.new(1.5, 12, 1.5), zenCFrame * CFrame.new(8, 6, 20), Color3.fromRGB(200, 60, 40), obbyFolder)
	makePart("ToriiTop", Vector3.new(20, 1.5, 1.5), zenCFrame * CFrame.new(0, 12, 20), Color3.fromRGB(200, 60, 40), obbyFolder)

	-- Bancas
	for i = -1, 1, 2 do
		makePart("Banca" .. i, Vector3.new(6, 1, 2), zenCFrame * CFrame.new(i * 12, 1.5, 0), Color3.fromRGB(120, 80, 50), obbyFolder, true, 0, Enum.Material.Wood)
	end

	makeLevelSign(Config.ZEN_LEVEL, zenCFrame + Vector3.new(0, 10, 22), obbyFolder)
	makeCheckpoint(Config.ZEN_LEVEL, zenCFrame + Vector3.new(0, 3, 0))
end

-- ===== Zona de descanso (niveles pares en Config.REST_LEVELS) =====
local function buildRestZone(level, z, y, hue)
	local cf = CFrame.new(0, y, -z)
	makePart("RestFloor" .. level, Vector3.new(40, 2, 40), cf, Color3.fromHSV(hue, 0.4, 1), obbyFolder, true, 0, Enum.Material.Neon)
	buildStall("Tienda", cf * CFrame.new(-12, 4, 12), Color3.fromRGB(80, 200, 120), obbyFolder)
	buildStall("Mejoras", cf * CFrame.new(12, 4, 12), Color3.fromRGB(200, 160, 60), obbyFolder)
	makeLevelSign(level, cf + Vector3.new(0, 8, 15), obbyFolder)
	makeCheckpoint(level, cf + Vector3.new(0, 3, 0))
end

local function isRestLevel(level)
	for _, l in ipairs(Config.REST_LEVELS) do
		if l == level then return true end
	end
	return false
end

-- ===== Construcción =====
buildLobby()

for level = 1, Config.TOTAL_LEVELS do
	local z = level * LEVEL_SPACING
	local y = BASE_Y
	local isHeightLevel = level >= Config.CHASER_START_LEVEL and level <= Config.CHASER_END_LEVEL
	if isHeightLevel then
		y = BASE_Y + (level - (Config.CHASER_START_LEVEL - 1)) * HEIGHT_LEVEL_STEP
	end

	local hue = (level % 30) / 30

	if level == Config.ZEN_LEVEL then
		buildZenZone(z, y)
	elseif isRestLevel(level) then
		buildRestZone(level, z, y, hue)
	else
		local platformCFrame = CFrame.new(0, y, -z)
		makePart("Platform" .. level, Vector3.new(12, 2, 12), platformCFrame, Color3.fromHSV(hue, 0.75, 1), obbyFolder, true, 0, Enum.Material.Neon)

		-- Obstáculo variado (determinístico por nivel, no aleatorio distinto cada vez que reinicia el server)
		local rng = Random.new(level)
		local obstacleFn = OBSTACLE_TYPES[rng:NextInteger(1, #OBSTACLE_TYPES)]
		obstacleFn(platformCFrame, hue, obbyFolder)

		-- Kill dots extra al azar en algunos niveles (precisión)
		if rng:NextNumber() < 0.4 then
			for i = 1, rng:NextInteger(1, 3) do
				makeKillDot(platformCFrame * CFrame.new(rng:NextInteger(-6, 6), 1, -rng:NextInteger(5, 30)), obbyFolder)
			end
		end

		makeLevelSign(level, platformCFrame + Vector3.new(0, 6, 8), obbyFolder)
		makeCheckpoint(level, platformCFrame + Vector3.new(0, 2, 0))
	end
end

-- ===== Meta final =====
local finalZ = (Config.TOTAL_LEVELS + 1) * LEVEL_SPACING
local finalY = BASE_Y + 10 * HEIGHT_LEVEL_STEP
local finalPad = makePart("MetaFinal", Vector3.new(20, 2, 20), CFrame.new(0, finalY, -finalZ), Color3.fromRGB(255, 215, 0), obbyFolder, true, 0, Enum.Material.Neon)
makeLevelSign(Config.TOTAL_LEVELS + 1, CFrame.new(0, finalY + 6, -finalZ), obbyFolder)

local obbyData = ReplicatedStorage:FindFirstChild("ObbyData") or Instance.new("Folder")
obbyData.Name = "ObbyData"
obbyData.Parent = ReplicatedStorage

local ObbyCompletedBindable = obbyData:FindFirstChild("ObbyCompletedBindable") or Instance.new("BindableEvent")
ObbyCompletedBindable.Name = "ObbyCompletedBindable"
ObbyCompletedBindable.Parent = obbyData

local debounce = {}
finalPad.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if player and not debounce[player] then
		debounce[player] = true
		ObbyCompletedBindable:Fire(player)
		task.delay(3, function()
			debounce[player] = nil
		end)
	end
end)

print("[ObbyBuilder] Obby generado: " .. Config.TOTAL_LEVELS .. " niveles + lobby + zona zen.")
