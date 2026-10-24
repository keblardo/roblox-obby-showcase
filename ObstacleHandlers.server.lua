-- © 2026 Cristian Luis Celie. All rights reserved. Portfolio excerpt from Obby 99 (Roblox prototype): shared for review only, not licensed for use, copying or redistribution.
--[[
  ObstacleHandlers.server.lua
  ARCHIVO NUEVO. Poner en: ServerScriptService (Script)

  Anima las partes especiales que ObbyBuilder etiquetó:
  - "Spinner": barras que giran sin parar (te empujan si te tocan)
  - "DisappearingPlatform": plataformas que desaparecen un rato al pisarlas
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- ===== Spinners =====
RunService.Heartbeat:Connect(function(dt)
	for _, part in ipairs(CollectionService:GetTagged("Spinner")) do
		part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(90) * dt, 0)
	end
end)

-- ===== Plataformas que desaparecen =====
local cooling = {}

local function setupDisappearing(part)
	part.Touched:Connect(function(hit)
		if cooling[part] then return end
		local character = hit.Parent
		if not character or not character:FindFirstChildOfClass("Humanoid") then return end

		cooling[part] = true
		task.delay(0.6, function()
			if not part or not part.Parent then return end
			local tween = TweenService:Create(part, TweenInfo.new(0.3), { Transparency = 1 })
			tween:Play()
			part.CanCollide = false
			task.delay(2, function()
				if not part or not part.Parent then return end
				part.CanCollide = true
				TweenService:Create(part, TweenInfo.new(0.3), { Transparency = 0 }):Play()
				cooling[part] = false
			end)
		end)
	end)
end

for _, part in ipairs(CollectionService:GetTagged("DisappearingPlatform")) do
	setupDisappearing(part)
end
CollectionService:GetInstanceAddedSignal("DisappearingPlatform"):Connect(setupDisappearing)
