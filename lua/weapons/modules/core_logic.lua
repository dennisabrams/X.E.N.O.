-- xeno/lua/weapons/modules/core_logic.lua

-- Function to count the number of active Xeno bombers in the game
local function GetActiveXenoCount()
	local xenoCount = 0
	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent) and ent.isXenoActive then -- Checks how many cores were thrown
			xenoCount = xenoCount + 1
		end
	end
	return xenoCount
end

-- Handles throwing the core and summoning the xenobomber
function SWEP:PrimaryAttack()
	local ply = self:GetOwner()
	if not IsValid(ply) then
		return
	end

	-- Check if the number of active Xeno bombers is below the limit
	local maxXenos = GetConVar("ttt_xeno_max_active"):GetInt()
	if GetActiveXenoCount() >= maxXenos then
		ply:ChatPrint("Cannot throw the core. Maximum number of active X.E.N.O.'s reached (Max: " .. 
			maxXenos .. "). Please wait until an active X.E.N.O. disappears before trying again.")
		return
	end

	-- Create the bugbait core
	if SERVER then
		local core = ents.Create("prop_physics")
		if not IsValid(core) then
			return
		end

		core:SetModel("models/weapons/w_bugbait.mdl")
		core:SetPos(ply:GetShootPos() + (ply:GetAimVector() * 16))
		core:SetAngles(ply:EyeAngles())
		core:SetOwner(ply)
		core:Spawn()
		core.isXenoActive = true
		core:Activate()

		-- Make the core act like it's being thrown
		local phys = core:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetVelocity(ply:GetAimVector() * self.ThrowForce + ply:GetVelocity())
		end

		-- Remove the weapon from the player after throwing
		ply:StripWeapon(self:GetClass())

		-- Start transforming the core either when it stops moving or after 10 seconds
		timer.Create(
			"CoreTransformTimer" .. core:EntIndex(),
			0.1,
			100,
			function()
				if not IsValid(core) then
					timer.Remove("CoreTransformTimer" .. core:EntIndex())
					return
				end

				local phys = core:GetPhysicsObject()
				if IsValid(phys) and phys:GetVelocity():Length() < 0.1 then
					timer.Remove("CoreTransformTimer" .. core:EntIndex())
					TransformCore(core, ply)
				end
			end
		)

		-- If the core is still active after 10 seconds, transform it
		timer.Simple(
			10,
			function()
				if IsValid(core) then
					timer.Remove("CoreTransformTimer" .. core:EntIndex())
					TransformCore(core, ply)
				end
			end
		)
	end
end

-- Transforms the core into a dynamic version and starts the hover/explosion sequence
function TransformCore(core, ply)
	if not IsValid(core) then
		return
	end

	-- Save the current position of the core
	local corePos = core:GetPos()

	-- Remove the old physics core
	core:Remove()

	-- Create a new dynamic core at the same spot
	local newCore = ents.Create("prop_dynamic_override")
	if not IsValid(newCore) then
		return
	end

	newCore:SetModel("models/weapons/w_bugbait.mdl")
	newCore:SetPos(corePos)
	newCore:SetAngles(Angle(0, 0, 0))
	newCore:SetOwner(ply)
	newCore:SetModelScale(1, 0) -- Start with the initial size
	newCore:Spawn()
	newCore.isXenoActive = true

	newCore:EmitSound("ttt-weapon/xeno/xeno_spawn.wav", 140, 100)

	-- Settings for how the core will hover and grow
	local hoverUpPos = corePos + Vector(0, 0, 70)
	local hoverDownPos = corePos + Vector(0, 0, 50)
	local hoverTime = 1 -- Time it takes to hover up or down
	local hoverCycles = 3 -- Number of times it will hover up and down
	local finalScale = 30 -- Final size of the core
	local finalRotationSpeed = 40 -- Final rotation speed

	-- Time when scaling starts
	local scaleStartTime = CurTime()
	local scaleDuration = hoverTime * hoverCycles * 2 -- Total time for scaling up

	-- Function to make the core hover up and down
	local function HoverCore(goingUp, cyclesRemaining)
		if cyclesRemaining <= 0 then
			if IsValid(newCore) then
				-- Trigger explosions around the core
				for i = 1, 5 do
					local explode = ents.Create("env_explosion")
					if IsValid(explode) then
						explode:SetPos(
							newCore:GetPos() + Vector(math.Rand(-50, 50), math.Rand(-50, 50), math.Rand(-20, 20))
						)
						explode:SetOwner(ply)
						explode:Spawn()
						explode:SetKeyValue("iMagnitude", tostring(GetConVar("ttt_xeno_spawndamage"):GetInt()))
						explode:Fire("Explode", 0, 0)
					end
				end

				-- Call the bomber and remove the core
				CallBomber(newCore:GetPos(), ply)
				newCore:Remove()
			end
			return
		end

		local startPos = goingUp and hoverDownPos or hoverUpPos
		local targetPos = goingUp and hoverUpPos or hoverDownPos
		local cycleStartTime = CurTime()

		-- Move the core smoothly between start and target positions
		timer.Create(
			"CoreHoverMovementTimer" .. newCore:EntIndex(),
			0.05,
			hoverTime * 20,
			function()
				if not IsValid(newCore) then
					timer.Remove("CoreHoverMovementTimer" .. newCore:EntIndex())
					return
				end

				local elapsedTime = CurTime() - cycleStartTime
				local progress = math.Clamp(elapsedTime / hoverTime, 0, 1)
				newCore:SetPos(LerpVector(progress, startPos, targetPos))

				-- Gradually increase the size of the core
				local totalElapsedTime = CurTime() - scaleStartTime
				local scaleProgress = math.Clamp(totalElapsedTime / scaleDuration, 0, 1)
				local newScale = Lerp(scaleProgress, 1, finalScale)
				newCore:SetModelScale(newScale, 0)

				-- Rotate the core for a visual effect
				local rotationSpeed = Lerp(scaleProgress, 5, finalRotationSpeed)
				local currentAngles = newCore:GetAngles()
				currentAngles:RotateAroundAxis(Vector(0, 0, 1), rotationSpeed)
				newCore:SetAngles(currentAngles)

				-- Randomly emit a blood effect during the hover
				if math.random() < 0.7 then
					local bloodEffect = EffectData()

					local totalElapsedTime = CurTime() - scaleStartTime
					local scaleProgress = math.Clamp(totalElapsedTime / scaleDuration, 0, 1)

					local maxOffset = 50
					local currentOffset = maxOffset * scaleProgress -- Increase offset from 0 to 50

					-- Add a random offset to the position
					local randomOffset =
						Vector(
						math.Rand(-currentOffset, currentOffset),
						math.Rand(-currentOffset, currentOffset),
						math.Rand(-currentOffset, currentOffset)
					)

					bloodEffect:SetOrigin(newCore:GetPos() + randomOffset)
					util.Effect("BloodImpact", bloodEffect)
				end

				-- Reverse the direction after reaching the target position
				if progress >= 1 then
					timer.Remove("CoreHoverMovementTimer" .. newCore:EntIndex())
					HoverCore(not goingUp, cyclesRemaining - 1)
				end
			end
		)
	end

	local initialTargetHeight = hoverUpPos
	local initialStartTime = CurTime()

	-- Handle the initial rising of the core before it starts hovering
	timer.Create(
		"CoreInitialRiseTimer" .. newCore:EntIndex(),
		0.05,
		hoverTime * 20,
		function()
			if not IsValid(newCore) then
				timer.Remove("CoreInitialRiseTimer" .. newCore:EntIndex())
				return
			end

			local elapsedTime = CurTime() - initialStartTime
			local progress = math.Clamp(elapsedTime / hoverTime, 0, 1)
			newCore:SetPos(LerpVector(progress, corePos, initialTargetHeight))

			-- Scale up during the initial rise
			local scaleProgress = math.Clamp(elapsedTime / scaleDuration, 0, 1)
			newCore:SetModelScale(Lerp(scaleProgress, 1, finalScale), 0)

			-- Rotate during the initial rise
			local rotationSpeed = Lerp(scaleProgress, 5, finalRotationSpeed)
			local currentAngles = newCore:GetAngles()
			currentAngles:RotateAroundAxis(Vector(0, 0, 1), rotationSpeed)
			newCore:SetAngles(currentAngles)

			-- Once the rise is complete, start hovering
			if progress >= 1 then
				timer.Remove("CoreInitialRiseTimer" .. newCore:EntIndex())
				HoverCore(false, hoverCycles * 2)
			end
		end
	)
end
