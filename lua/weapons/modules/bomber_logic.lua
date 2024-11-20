-- xeno/lua/weapons/modules/bomber_logic.lua

-- Function to find the nearest detective or innocent player who is still alive
function FindNearestTarget(position)
	local players = player.GetAll()
	local nearestTarget = nil
	local shortestDistance = math.huge

	for _, ply in ipairs(players) do
		if (ply:GetRole() == ROLE_DETECTIVE or ply:GetRole() == ROLE_INNOCENT) and ply:Alive() and not ply:IsSpec() then
			local distance = position:DistToSqr(ply:GetPos())
			if distance < shortestDistance then
				shortestDistance = distance
				nearestTarget = ply
			end
		end
	end

	return nearestTarget
end

-- Function to call the Combine Dropship and make it track and follow a target
function CallBomber(corePos, owner)
	if not IsValid(owner) then
		return
	end

	local target = FindNearestTarget(corePos)
	local announceTarget = GetConVar("ttt_xeno_announce_target"):GetBool() -- Check the ConVar value (Default: Disabled)

	if target and announceTarget then
		-- Send a message in chat to let all players know who the target is
		for _, plyy in ipairs(player.GetAll()) do
			player:ChatPrint(target:Nick() .. " is not having a lucky round this time.")
		end
	end

	if SERVER then
		local bomber = ents.Create("prop_dynamic")
		if not IsValid(bomber) then
			return
		end

		bomber:SetModel("models/combine_dropship.mdl") -- Use the Combine Dropship model
		bomber:SetPos(corePos)
		bomber:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		bomber:SetRenderMode(RENDERMODE_TRANSCOLOR)
		bomber:SetColor(Color(255, 255, 255, 0)) -- Make it fully invisible at first
		bomber:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) -- Set the bomber to not block other entities
		bomber:Spawn()
		bomber.isXenoActive = true

		-- Attach Combine Mine and Helicopter Bomb models to the bomber
		local function CreateAttachment(model, parent, offset, options)
			local attachment = ents.Create("prop_dynamic")
			if not IsValid(attachment) then
				return
			end

			-- Set the model, position, and rotation for the attachment
			attachment:SetModel(model)
			attachment:SetPos(parent:GetPos() + offset)
			attachment:SetAngles(Angle(parent:GetAngles().p + 180, parent:GetAngles().y, parent:GetAngles().r)) -- Rotate the attachment 180 degrees
			attachment:SetParent(parent)
			attachment:Spawn()

			-- Apply optional settings such as scaling and material
			if options then
				if options.scale then
					attachment:SetModelScale(options.scale, 0)
				end

				if options.use_parent_material then
					attachment:SetMaterial(parent:GetMaterials()[1]) -- Use the same material as the parent bomber
					attachment:SetRenderMode(RENDERMODE_NORMAL) -- Remove shiny effect
					attachment:SetColor(Color(255, 255, 255)) -- Keep the same color as the bomber
				end
			end

			attachment:SetSolid(SOLID_NONE) -- Make it non-physical
			attachment:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) -- Prevent collisions
			attachment:SetMoveType(MOVETYPE_NONE) -- Make it move with the parent

			return attachment
		end

		-- Create the Combine Mine attachment with specific scaling and material options
		local combineMine =
			CreateAttachment(
			"models/props_combine/combine_mine01.mdl",
			bomber,
			Vector(0, 0, 100),
			{scale = 2, use_parent_material = true}
		)

		-- Adjust the rotation of the Combine Mine after attaching it
		if IsValid(combineMine) then
			local newAngles = combineMine:GetAngles()
			newAngles:RotateAroundAxis(newAngles:Up(), 25) -- Rotate it slightly for a better look
			combineMine:SetAngles(newAngles)
		end

		-- Create a Helicopter Bomb attachment without modifying its scale or material
		local helicopterBomb =
			CreateAttachment("models/combine_helicopter/helicopter_bomb01.mdl", bomber, Vector(0, 0, 92))

		-- Make the Helicopter Bomb rotate continuously
		timer.Create(
			"HelicopterBombRotate" .. helicopterBomb:EntIndex(),
			0.05,
			0,
			function()
				if IsValid(helicopterBomb) then
					local angles = helicopterBomb:GetAngles()
					angles:RotateAroundAxis(angles:Up(), 10) -- Rotate 10 degrees each tick
					helicopterBomb:SetAngles(angles)
				else
					timer.Remove("HelicopterBombRotate" .. helicopterBomb:EntIndex())
				end
			end
		)

		-- Make the bomber and its attachments fade in over time
		local fadeInTime = 3
		local fadeInSteps = 255 / (fadeInTime * 10)
		local currentAlpha = 0 -- Track current alpha value for a smoother transition

		-- Set the initial transparency for the bomber and its attachments to be fully invisible
		bomber:SetRenderMode(RENDERMODE_TRANSCOLOR) -- Allow transparency changes
		bomber:SetColor(Color(255, 255, 255, currentAlpha))

		local attachments = bomber:GetChildren()
		for _, attachment in ipairs(attachments) do
			if IsValid(attachment) then
				attachment:SetRenderMode(RENDERMODE_TRANSCOLOR) -- Allow transparency changes
				attachment:SetColor(Color(255, 255, 255, currentAlpha)) -- Start fully invisible
			end
		end

		-- Create a timer to gradually fade in the bomber and its attachments
		timer.Create(
			"bomberFadeIn" .. bomber:EntIndex(),
			0.1,
			fadeInSteps,
			function()
				if IsValid(bomber) then
					-- Calculate the progress of the fade-in
					local progress = (fadeInSteps - timer.RepsLeft("bomberFadeIn" .. bomber:EntIndex())) / fadeInSteps

					-- Use a quadratic easing for a smoother, gradual fade-in
					local easedProgress = progress * progress -- Squaring the progress makes it slow down towards the end

					-- Calculate new alpha using eased progress
					local newAlpha = math.Clamp(easedProgress * 255, 0, 255)

					-- Update the alpha for the bomber
					bomber:SetColor(Color(255, 255, 255, newAlpha))

					-- Update the alpha for the attachments
					local attachments = bomber:GetChildren()
					for _, attachment in ipairs(attachments) do
						if IsValid(attachment) then
							attachment:SetRenderMode(RENDERMODE_TRANSCOLOR) -- Allow transparency changes during fading
							attachment:SetColor(Color(255, 255, 255, newAlpha))
						end
					end
				else
					-- Stop the timer if the bomber becomes invalid
					timer.Remove("bomberFadeIn" .. bomber:EntIndex())
				end
			end
		)

		bomber:EmitSound("ttt-weapon/xeno/xeno_scream.wav", 140, 100)

		-- Create an invisible damageable entity to track the health of the bomber
		local damageBomber = ents.Create("prop_physics")
		if not IsValid(damageBomber) then
			return
		end

		damageBomber:SetModel("models/combine_dropship.mdl") -- Use the same model as the bomber

		damageBomber:SetAngles(bomber:GetAngles())
		damageBomber:SetNoDraw(true)

		local scale = 1.1
		damageBomber:SetModelScale(scale, 0)

		-- Set collision bounds based on the scale factor
		local minBounds = Vector(-500, -500, -100) * scale
		local maxBounds = Vector(500, 500, 500) * scale
		damageBomber:SetCollisionBounds(minBounds, maxBounds)

		damageBomber:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		damageBomber:Spawn()

		local maxHealth = GetConVar("ttt_xeno_health"):GetInt()

		damageBomber:SetHealth(maxHealth) -- Default 800
		bomber:SetNWInt("MaxHealth", maxHealth) -- Networked Integer for client health bar
		bomber:SetNWInt("CurrentHealth", maxHealth) -- Full Life at the start

		-- Allow the damageBomber to take damage
		hook.Add(
			"EntityTakeDamage",
			"DamageBomberTakeDamage" .. damageBomber:EntIndex(),
			function(target, dmg)
				if target == damageBomber then
					if not dmg:GetAttacker():IsPlayer() or not dmg:GetAttacker():Alive() then
						return
					end

					local newHealth = damageBomber:Health() - dmg:GetDamage()
					damageBomber:SetHealth(newHealth)
					bomber:SetNWInt("CurrentHealth", newHealth) -- Update for client health bar

					-- Adjust the bomber's color to make it look damaged based on its health
					local healthFraction = newHealth / maxHealth -- Health fraction (1 = full health, 0 = no health)
					local newColorValue = math.Clamp(255 * healthFraction, 0, 255) -- Calculate new color value based on health

					if IsValid(bomber) then
						-- Set the bomber's color based on its health (fully bright at full health, dark at low health)
						bomber:SetColor(Color(newColorValue, newColorValue, newColorValue))

						-- Also apply the darkness effect to the attachments
						local attachments = bomber:GetChildren()
						for _, attachment in ipairs(attachments) do
							if IsValid(attachment) then
								attachment:SetColor(Color(newColorValue, newColorValue, newColorValue))
							end
						end
					end

					-- If health reaches zero, make the bomber perform a death animation
					if newHealth <= 0 then
						if IsValid(bomber) then
							-- Mark the bomber as dying to prevent more grenade drops
							bomber.dying = true

							-- Stop the bomber from following the player
							timer.Remove("bomberTrack" .. bomber:EntIndex())
							timer.Remove("damageBomberSync" .. damageBomber:EntIndex())

							-- Calculate the target position for the bomber to fall smoothly to the ground
							local fallTargetZ = target:GetPos().z - 300 -- Bomber should fall below the target
							local totalFallDistance = bomber:GetPos().z - fallTargetZ
							local fallTime = 4.0 -- Set the fall time to 4 seconds
							local interval = 0.05
							local fallSpeed = totalFallDistance / (fallTime / interval) -- Calculate the speed for a smooth fall

							bomber:EmitSound("ttt-weapon/xeno/xeno_kill.wav", 140, 100)

							-- Set the roll direction for the fall animation
							local rollDirection = 0.5 -- Slow rotation for dramatic effect

							-- Create a timer to manage the falling animation (fall, rotate, and fade out)
							timer.Create(
								"bomberFallAndFade" .. bomber:EntIndex(),
								interval,
								0,
								function()
									if IsValid(bomber) then
										-- Make the bomber fall down gradually, adding some random drift
										local bomberPos = bomber:GetPos()
										if bomberPos.z > fallTargetZ + 1 then -- Add a small buffer to prevent getting stuck
											-- Update bomber position with some random drift
											bomber:SetPos(
												Vector(
													bomberPos.x + math.Rand(-0.5, 0.5), -- Slight drift in the X direction
													bomberPos.y + math.Rand(-0.5, 0.5), -- Slight drift in the Y direction
													math.max(bomberPos.z - fallSpeed, fallTargetZ) -- Gradual fall in the Z direction
												)
											)

											-- Rotate the bomber to simulate a falling aircraft
											local currentAngles = bomber:GetAngles()
											local targetRollAngle = math.Clamp(currentAngles.r + rollDirection, -45, 45) -- Limit roll between -45 and 45 degrees
											local newAngles = Angle(currentAngles.p, currentAngles.y, targetRollAngle)
											bomber:SetAngles(newAngles)
										else
											-- Make sure the bomber is on the ground before starting the explosion
											bomber:SetPos(Vector(bomberPos.x, bomberPos.y, fallTargetZ))

											-- Stop the fall timer
											timer.Remove("bomberFallAndFade" .. bomber:EntIndex())

											-- Start the explosion effect after the bomber has fallen
											for i = 1, 10 do
												timer.Simple(
													(i - 1) * 0.1,
													function()
														-- Add delay between explosions for dramatic effect
														if IsValid(bomber) then
															local explode = ents.Create("env_explosion")
															if IsValid(explode) then
																explode:SetPos(
																	bomber:GetPos() +
																		Vector(
																			math.Rand(-200, 200),
																			math.Rand(-200, 200),
																			math.Rand(-100, 200)
																		)
																)
																explode:SetOwner(owner)
																explode:Spawn()
																explode:SetKeyValue(
																	"iMagnitude",
																	tostring(GetConVar("ttt_xeno_deathdamage"):GetInt())
																) -- Default 50
																explode:Fire("Explode", 0, 0)
															end
														end
													end
												)
											end

											-- Fade out and remove the bomber after the explosions
											FadeOutAndRemove(bomber)
										end
									else
										timer.Remove("bomberFallAndFade" .. bomber:EntIndex())
									end
								end
							)
						end
						-- Remove the damage bomber when its health 0
						damageBomber:Remove()
					end
				end
			end
		)

		-- Sync the damageBomber position with the visible bomber
		timer.Create(
			"damageBomberSync" .. damageBomber:EntIndex(),
			0.1,
			0,
			function()
				if IsValid(bomber) and IsValid(damageBomber) then
					local damageBomberPos = bomber:GetPos() + bomber:GetForward() * 20
					damageBomber:SetPos(Vector(damageBomberPos.x, damageBomberPos.y, bomber:GetPos().z + 100))
					damageBomber:SetAngles(bomber:GetAngles())
				else
					timer.Remove("damageBomberSync" .. damageBomber:EntIndex())
					if IsValid(damageBomber) then
						damageBomber:Remove()
					end
				end
			end
		)

		-- Make the bomber track and follow the target player
		timer.Create(
			"bomberTrack" .. bomber:EntIndex(),
			0.1,
			0,
			function()
				if IsValid(bomber) and IsValid(target) then
					local targetPos = target:GetPos() + Vector(0, 0, 300)

					-- Perform a trace upwards from the player to check for ceilings
					local traceData = {}
					traceData.start = target:GetPos() + Vector(0, 0, 10)
					traceData.endpos = traceData.start + Vector(0, 0, 1000)
					traceData.filter = target

					local trace = util.TraceLine(traceData)

					-- Adjust bomber height if there's a ceiling in the way
					if trace.Hit then
						if trace.HitPos.z < target:GetPos().z + 300 then
							targetPos.z = target:GetPos().z + 50
						end
					end

					local heightDifference = math.abs(bomber:GetPos().z - target:GetPos().z)

					-- Decide what the bomber should do based on its height compared to the target
					local currentPosition = bomber:GetPos()
					local targetDirection = (targetPos - currentPosition)
					local currentAngles = bomber:GetAngles()
					local targetAngles = targetDirection:Angle()

					-- Assuming startTime is set when the bomber is first created or begins moving
					if not bomber.startTime then
						bomber.startTime = CurTime()
					end

					local elapsedTime = CurTime() - bomber.startTime

					-- Gradually increase the lerp factor based on elapsed time
					local lerpFactor = math.Clamp(elapsedTime * 0.02, 0.01, 0.08) -- Starts small and reaches 0.08 over time

					if heightDifference > 300 then
						-- Move and rotate the bomber towards the target when at a higher altitude
						bomber:SetPos(LerpVector(lerpFactor, currentPosition, targetPos))
						bomber:SetAngles(LerpAngle(0.1, currentAngles, targetAngles))
						bomber.hovering = false
					else
						-- When the bomber is directly above the target, it starts hovering
						if not bomber.hovering then
							bomber.hovering = true
						end

						-- Keep the bomber stable above the target
						bomber:SetPos(LerpVector(lerpFactor, currentPosition, targetPos))
						targetAngles.p, targetAngles.r = 0, 0
						bomber:SetAngles(LerpAngle(0.1, currentAngles, targetAngles))
					end
				end
			end
		)

		-- Set a timer to remove the bomber after (Default: 45 seconds)
		timer.Simple(
			GetConVar("ttt_xeno_duration"):GetInt(),
			function()
				-- How long X.E.N.O will hunt his target
				if IsValid(bomber) then
					FadeOutAndRemove(bomber)
				end
				if IsValid(damageBomber) then
					damageBomber:Remove()
				end
			end
		)

		-- Drop grenades while the bomber is following the target
		if IsValid(target) then
			DropGrenades(bomber, owner)
		end
	end
end

-- Function to fade out the bomber and remove it, along with anything attached to it
function FadeOutAndRemove(bomber)
	-- If the bomber is not valid, stop the function
	if not IsValid(bomber) then
		return
	end

	local fadeOutTime = 1.5 -- Time to fully fade out the bomber
	local fadeOutStep = 255 / (fadeOutTime * 10) -- How much to reduce the alpha each step

	if not bomber.dying then
		bomber:EmitSound("ttt-weapon/xeno/xeno_end.wav", 140, 100)
	end

	-- Get all attached parts of the bomber
	local attachments = bomber:GetChildren()

	-- Timer to handle fading out
	timer.Create(
		"bomberFadeOut" .. bomber:EntIndex(),
		0.1,
		fadeOutTime * 10,
		function()
			if IsValid(bomber) then
				-- Reduce the bombers transparency
				local currentColor = bomber:GetColor()
				local newAlpha = math.max(currentColor.a - fadeOutStep, 0)
				bomber:SetColor(Color(currentColor.r, currentColor.g, currentColor.b, newAlpha))

				-- Make any attached parts fade out as well
				for _, attachment in ipairs(attachments) do
					if IsValid(attachment) then
						attachment:SetColor(Color(currentColor.r, currentColor.g, currentColor.b, newAlpha))
					end
				end

				-- If bomber is not dying, make it float up while fading
				if not bomber.dying then
					local ascendStep = Vector(0, 0, 20) -- How much to move upwards each time
					bomber:SetPos(bomber:GetPos() + ascendStep)
				end

				-- When fully faded out, remove the bomber and all its attachments
				if newAlpha <= 0 then
					-- Remove all attached parts
					for _, attachment in ipairs(attachments) do
						if IsValid(attachment) then
							attachment:Remove()
						end
					end
					-- Finally remove the bomber itself
					bomber:Remove()
				end
			end
		end
	)
end
