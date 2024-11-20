-- xeno/lua/weapons/resources/resource.lua

if SERVER then
	local resources = {
		"sound/ttt-weapon/xeno/xeno_spawn.wav",
		"sound/ttt-weapon/xeno/xeno_scream.wav",
		"sound/ttt-weapon/xeno/xeno_kill.wav",
		"sound/ttt-weapon/xeno/xeno_end.wav",
		"materials/VGUI/ttt/icon_xeno.vmt"
	}

	for _, resourcePath in ipairs(resources) do
		resource.AddFile(resourcePath)
	end
end
