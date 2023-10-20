global function TrailerMonarch_Init

void function TrailerMonarch_Init()
{
	AddCallback_OnTitanGetsNewTitanLoadout( TrailerMonarch_ApplyMods )
}

void function TrailerMonarch_ApplyMods( entity titan, TitanLoadoutDef loadout )
{
	if( loadout.titanClass != "vanguard")
		return

	entity soul = titan.GetTitanSoul()
	if ( !IsValid( soul ) )
		return

	titan.GetOffhandWeapon( OFFHAND_RIGHT ).AddMod( "Trailer" )
	titan.GetOffhandWeapon( OFFHAND_LEFT ).AddMod( "energy_transfer" )
	titan.GetOffhandWeapon( OFFHAND_TITAN_CENTER ).AddMod( "Trailer" )
}