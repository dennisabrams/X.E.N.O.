-- xeno/lua/weapons/weapon_ttt_xeno.lua

AddCSLuaFile("config/settings.lua")
include("config/settings.lua")

-- Server-side initialization and setup
if SERVER then

	-- Make necessary files available to the client
	AddCSLuaFile("client/healthbar.lua")

	-- Server ConVars to control game settings
	CreateConVar("ttt_xeno_max_active", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum number of active X.E.N.O.'s allowed in the round")
	CreateConVar("ttt_xeno_announce_target", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Set to 1 to announce the target in chat, 0 to keep silent.")
	CreateConVar("ttt_xeno_health", "800", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Set the health of X.E.N.O.")
	CreateConVar("ttt_xeno_duration", "45", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Set the duration in seconds for how long X.E.N.O stays active.")
	CreateConVar("ttt_xeno_spawndamage", "100", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Set the damage dealt by X.E.N.O upon spawn.")
	CreateConVar("ttt_xeno_deathdamage", "50", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Set the damage dealt by X.E.N.O upon death.")
	CreateConVar("ttt_xeno_grenade_damage", "70", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Set the explosion damage of grenades dropped by X.E.N.O.")
	CreateConVar("ttt_xeno_grenade_interval_min", "0.1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Set the minimum interval duration in seconds for dropping grenades.")
	CreateConVar("ttt_xeno_grenade_interval_max", "0.8", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Set the maximum interval duration in seconds for dropping grenades.")
	CreateConVar("ttt_xeno_grenade_drop_radius", "100", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Adjust the drop radius and spread of grenades dropped by X.E.N.O. The larger the ConVar value, the greater the spread. The smaller the value, the tighter the spread.")

	-- Include server-side scripts
	include("resources/resource.lua")        -- Handles resource allocation
	include("modules/core_logic.lua")        -- Core functions needed for spawning X.E.N.O
	include("modules/bomber_logic.lua")      -- X.E.N.O bomber-specific functionality
	include("modules/grenade_logic.lua")     -- Handles grenade-dropping mechanics

end

if CLIENT then
	-- Client ConVars to control game settings
	CreateConVar("ttt_xeno_healthbar", "0", FCVAR_ARCHIVE, "Set to 1 to display the health bar from X.E.N.O.")
	include("client/healthbar.lua")
end
