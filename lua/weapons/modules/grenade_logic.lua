-- xeno/lua/weapons/modules/grenade_logic.lua

-- Function to drop combine rifle ammo from the dropship, behaving like ttt_firegrenade_proj
function DropGrenades(bomber, target, owner)
	if not IsValid(bomber) or not IsValid(target) then
		return
	end

	if SERVER then
		-- Get ConVar to adjust drop radius
		local dropRadiusMultiplier = GetConVar("ttt_xeno_grenade_drop_radius"):GetFloat() / 100

		-- Start a loop to keep spawning grenades at variable times
		local function SpawnAndDropGrenade()
			if not IsValid(bomber) or bomber.dying or not IsValid(target) or not target:Alive() then
				return
			end

			-- Create the grenade as a dynamic entity
			local grenade = ents.Create("prop_dynamic")

			if not IsValid(grenade) then
				return
			end

			grenade:SetModel("models/items/combine_rifle_ammo01.mdl")
			grenade:SetOwner(owner)
			grenade:SetPos(bomber:GetPos() + bomber:GetUp() * 75) -- Spawn the grenade below the bomber at z = 75 relative to bomber's up direction
			grenade:SetAngles(bomber:GetAngles()) -- Set the grenade angle to match the bomber
			grenade:SetModelScale(1.4, 0) -- Scale up the grenade a bit
			grenade:SetParent(bomber) -- Attach the grenade to the bomber to follow it
			grenade:SetRenderMode(RENDERMODE_TRANSCOLOR) -- Allow transparency changes
			grenade:SetColor(Color(255, 255, 255, 0)) -- Start fully transparent
			grenade:Spawn()

			-- Randomly set interval duration between (default) 0.1 and (default) 0.8 seconds for each grenade
			local descentDuration =
				math.Rand(
				GetConVar("ttt_xeno_grenade_interval_min"):GetFloat(),
				GetConVar("ttt_xeno_grenade_interval_max"):GetFloat()
			)

			-- Descent duration and step variables
			local targetZ = 67 -- Target z position
			local startTime = CurTime() -- Start time of the descent

			-- Simple descent and fade-in effect
			timer.Create(
				"GrenadeDescent" .. grenade:EntIndex(),
				0.05,
				0,
				function()
					if not IsValid(grenade) or not IsValid(bomber) or not IsValid(target) or not target:Alive() then
						timer.Remove("GrenadeDescent" .. grenade:EntIndex())
						return
					end

					-- Calculate the elapsed time and progress
					local elapsed = CurTime() - startTime
					local descentProgress = math.Clamp(elapsed / descentDuration, 0, 1)

					-- Calculate the current z position
					local startZ = 75
					local newZ = Lerp(descentProgress, startZ, targetZ)
					grenade:SetLocalPos(Vector(0, 0, newZ))

					-- Set the transparency based on descent progress
					local newAlpha = math.Clamp(255 * descentProgress, 0, 255)
					grenade:SetColor(Color(255, 255, 255, newAlpha))

					-- Stop descent once target is reached
					if descentProgress >= 1 then
						timer.Remove("GrenadeDescent" .. grenade:EntIndex())
					end
				end
			)

			-- Remove the grenade after descentDuration and spawn a TTT grenade that falls and explodes
			timer.Simple(
				descentDuration,
				function()
					if not IsValid(bomber) or bomber.dying or not IsValid(target) or not target:Alive() then
						return
					end

					if IsValid(grenade) then
						local grenadePos = grenade:GetPos() -- Store the position before removal
						grenade:Remove()

						-- Spawn a TTT grenade at the previous position
						local tttGrenade = ents.Create("ttt_firegrenade_proj")
						if not IsValid(tttGrenade) then
							return
						end

						tttGrenade:SetPos(grenadePos) -- Set the position to where the previous grenade was
						tttGrenade:SetOwner(owner)
						tttGrenade:SetModelScale(1.4, 0) -- Scale up the grenade to match the decorative grenade
						tttGrenade:Spawn()
						tttGrenade:Activate()

						-- Override model to Combine Rifle Ammo after spawning
						if IsValid(tttGrenade) then
							tttGrenade:SetModel("models/items/combine_rifle_ammo01.mdl")
						end

						-- Make the grenade fall naturally
						local phys = tttGrenade:GetPhysicsObject()
						if IsValid(phys) then
							phys:Wake()

							local adjustedForward = 700 * dropRadiusMultiplier
							local forwardDirection = bomber:GetForward() * math.Rand(0, adjustedForward)

							local adjustedOffsetMin = -350 * dropRadiusMultiplier
							local adjustedOffsetMax = 350 * dropRadiusMultiplier
							local randomOffset = Vector(math.Rand(adjustedOffsetMin, adjustedOffsetMax), math.Rand(adjustedOffsetMin, adjustedOffsetMax), -300)

							local velocity = forwardDirection + randomOffset
							phys:SetVelocity(velocity)

							-- Set the grenades angle to make the tail look at the spawn point realistically
							local directionToSpawn = (bomber:GetPos() - tttGrenade:GetPos()):GetNormalized() -- Vector pointing towards the spawn point
							local grenadeAngle = velocity:Angle()

							-- Adjust the pitch to ensure the back of the grenade faces the original spawn direction
							grenadeAngle.p = directionToSpawn:Angle().p
							tttGrenade:SetAngles(grenadeAngle)
						end

						-- Manually create an explosion after a few seconds
						timer.Simple(
							3,
							function()
								if IsValid(tttGrenade) then
									local explode = ents.Create("env_explosion")
									if not IsValid(explode) then
										return
									end
									explode:SetPos(tttGrenade:GetPos())
									explode:SetOwner(owner)
									explode:Spawn()
									explode:SetKeyValue(
										"iMagnitude",
										tostring(GetConVar("ttt_xeno_grenade_damage"):GetInt())
									)
									explode:Fire("Explode", 0, 0)
									tttGrenade:Remove()
								end
							end
						)
					end
				end
			)

			-- Schedule the next grenade drop after the descent duration
			timer.Simple(
				descentDuration,
				function()
					if IsValid(target) and target:IsPlayer() and target:Alive() then
						SpawnAndDropGrenade()
					else
						FadeOutAndRemove(bomber)
					end
				end
			)
		end

		-- Start the first grenade drop
		SpawnAndDropGrenade()
	end
end
