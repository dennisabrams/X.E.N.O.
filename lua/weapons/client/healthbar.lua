-- xeno/lua/weapons/client/healthbar.lua

if not CLIENT then
	return
end

local xenoEntities = {}
local xenoHealthData = {}

-- Turn on/off the health bar based on the ConVar value
local function UpdateHealthBar()
	if GetConVar("ttt_xeno_healthbar"):GetBool() then
		-- Add hooks to track new entities and draw the health bar
		hook.Add(
			"OnEntityCreated",
			"TrackXenoEntities",
			function(ent)
				timer.Simple(
					0.1,
					function()
						-- Wait a bit to make sure the entity is ready
						if
							IsValid(ent) and ent:GetClass() == "prop_dynamic" and
								ent:GetModel() == "models/combine_dropship.mdl"
						 then
							table.insert(xenoEntities, ent)
							xenoHealthData[ent] = {
								targetHealth = ent:GetNWInt("CurrentHealth", 800),
								currentHealth = ent:GetNWInt("CurrentHealth", 800)
							}
						end
					end
				)
			end
		)

		hook.Add(
			"Think",
			"SmoothHealthUpdate",
			function()
				-- Make sure xenoHealthData is always a table
				if not xenoHealthData then
					xenoHealthData = {}
				end

				for xeno, data in pairs(xenoHealthData) do
					if IsValid(xeno) then
						local targetHealth = xeno:GetNWInt("CurrentHealth", 800)
						if targetHealth ~= data.targetHealth then
							data.targetHealth = targetHealth
						end

						-- Slowly adjust current health towards target health
						data.currentHealth = Lerp(FrameTime() * 5, data.currentHealth, data.targetHealth) -- Speed controlled by multiplier (5)

						-- If health is zero or less, stop rendering this entity
						if data.currentHealth <= 0 then
							xenoHealthData[xeno] = nil -- Remove health info
							table.RemoveByValue(xenoEntities, xeno) -- Remove from entity list
						end
					else
						xenoHealthData[xeno] = nil -- Remove invalid entities
					end
				end
			end
		)

		hook.Add(
			"HUDPaint",
			"DrawXenoHealthBar",
			function()
				-- Make sure xenoEntities is always a table
				if not xenoEntities then
					xenoEntities = {}
				end

				for index, xeno in ipairs(xenoEntities) do
					if IsValid(xeno) then
						local healthData = xenoHealthData[xeno]
						if healthData then -- Instead of using 'continue', only proceed if healthData is valid
							-- Get health values
							local maxHealth = xeno:GetNWInt("MaxHealth", 800)
							local currentHealth = healthData.currentHealth
							local healthFraction = math.Clamp(currentHealth / maxHealth, 0, 1)

							-- Get screen position above the entity for drawing the health bar
							local pos = xeno:GetPos() + Vector(0, 0, 150)
							local screenPos = pos:ToScreen()

							if screenPos.visible then
								-- Define health bar size
								local barWidth = 150
								local barHeight = 15

								-- Draw health bar background
								surface.SetDrawColor(0, 0, 0, 50)
								surface.DrawRect(screenPos.x - barWidth / 2, screenPos.y, barWidth, barHeight)

								-- Draw the health bar with a gradient from red to green
								surface.SetDrawColor(255 * (1 - healthFraction), 255 * healthFraction, 0, 50)
								surface.DrawRect(
									screenPos.x - barWidth / 2,
									screenPos.y,
									barWidth * healthFraction,
									barHeight
								)

								-- Draw the health text
								draw.SimpleText(
									"X.E.N.O. HP: " .. math.ceil(currentHealth) .. " / " .. math.ceil(maxHealth),
									"DermaDefaultBold",
									screenPos.x,
									screenPos.y - barHeight - 5,
									Color(255, 255, 255, 100),
									TEXT_ALIGN_CENTER
								)
							end
						end
					else
						-- Remove invalid entity from the list
						table.remove(xenoEntities, index)
						xenoHealthData[xeno] = nil -- Remove health info
					end
				end
			end
		)
	else
		-- Remove hooks if the health bar is turned off
		hook.Remove("OnEntityCreated", "TrackXenoEntities")
		hook.Remove("Think", "SmoothHealthUpdate")
		hook.Remove("HUDPaint", "DrawXenoHealthBar")

		-- Clear all entities and health info
		xenoEntities = {}
		xenoHealthData = {}
	end
end

-- First update of hooks based on current ConVar
UpdateHealthBar()

-- Add a callback to turn health bar on/off based on changes
cvars.AddChangeCallback(
	"ttt_xeno_healthbar",
	function(convar_name, oldValue, newValue)
		UpdateHealthBar()
	end
)

-- Create a gradient material
local gradientMaterial = Material("vgui/gradient-d") -- Gradient used for drawing
