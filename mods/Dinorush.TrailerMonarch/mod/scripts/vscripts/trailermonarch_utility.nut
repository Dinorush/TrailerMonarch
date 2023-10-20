untyped
global function TrailerMonarch_Init

void function TrailerMonarch_Init()
{
	AddCallback_OnTitanGetsNewTitanLoadout( TrailerMonarch_ApplyMods )
	AddCallback_OnPlayerRespawned( TrailerMonarch_GiveMod )
}

void function TrailerMonarch_GiveMod( entity player )
{
	player.GiveExtraWeaponMod( "TrailerMonarch" )
}

void function TrailerMonarch_ApplyMods( entity titan, TitanLoadoutDef loadout )
{
	if( loadout.titanClass != "vanguard")
		return

	entity soul = titan.GetTitanSoul()
	if ( !IsValid( soul ) )
		return

	titan.GetOffhandWeapon( OFFHAND_RIGHT ).AddMod( "TrailerMonarch" )
	titan.GetOffhandWeapon( OFFHAND_LEFT ).AddMod( "energy_transfer" )
	titan.GetOffhandWeapon( OFFHAND_TITAN_CENTER ).AddMod( "TrailerMonarch" )
}