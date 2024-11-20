-- xeno/lua/weapons/config/settings.lua

SWEP.ClassName = "weapon_ttt_xeno"
SWEP.Base = "weapon_tttbase"

SWEP.PrintName = "Project X.E.N.O"
SWEP.Author = "DennisVanDante"
SWEP.Contact = "https://steamcommunity.com/id/dennisvandante"
SWEP.Purpose = "Summon X.E.N.O to unleash chaos upon innocent players."
SWEP.Instructions = "Left-click to throw the awakening core and summon X.E.N.O."
SWEP.Category = "Traitor Weapons"

SWEP.HoldType = "grenade"
SWEP.Weight = 5
SWEP.Slot = 3
SWEP.Icon = "VGUI/ttt/icon_xeno"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AutoSpawnable = false

SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = false
SWEP.AllowDrop = true
SWEP.IsSilent = false

SWEP.ViewModel = "models/weapons/v_bugbait.mdl"
SWEP.WorldModel = "models/weapons/w_bugbait.mdl"
SWEP.Primary.Delay = 0.5
SWEP.Primary.Automatic = false
SWEP.NoSights = true
SWEP.UseHands = true
SWEP.ThrowForce = 800

SWEP.EquipMenuData = {
	type = "Weapon",
	desc = [[
===== WARNING: HIGHLY EXPLOSIVE! =====

Throw an Core to summon X.E.N.O the bomber.
X.E.N.O will automatically search for the nearest
innocent player, causing chaos and destruction!
]]
}

if CLIENT then
	SWEP.Icon = "vgui/ttt/icon_xeno"
	killicon.Add("weapon_ttt_xeno", "vgui/ttt/icon_xeno", Color(255, 255, 255, 255))
end

function SWEP:Initialize()
	self:SetHoldType("grenade")
end

function SWEP:Deploy()
	self:SetHoldType("grenade")
	return true
end
