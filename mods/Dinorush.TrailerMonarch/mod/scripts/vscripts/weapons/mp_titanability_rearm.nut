//TODO: FIX REARM WHILE FIRING SALVO ROCKETS

global function OnWeaponPrimaryAttack_titanability_rearm
global function OnWeaponAttemptOffhandSwitch_titanability_rearm

#if SERVER
global function OnWeaponNPCPrimaryAttack_titanability_rearm
#endif

const float TRAILER_JUMP_X_VEL = 1000
const float TRAILER_JUMP_Y_VEL = 3000
const float TRAILER_GRAV_SCALE = 4.5

var function OnWeaponPrimaryAttack_titanability_rearm( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity owner = weapon.GetWeaponOwner()
	if ( !IsValid( owner ) )
		return 0

	#if SERVER
	thread TrailerJump_Think( owner )
	#endif

	weapon.SetWeaponPrimaryClipCount( 0 )//used to skip the fire animation
	return 0
}

#if SERVER
vector function GetDirectionFromInput( vector playerAngles, float xAxis, float yAxis )
{
	playerAngles.x = 0
	playerAngles.z = 0
	vector forward = AnglesToForward( playerAngles )
	vector right = AnglesToRight( playerAngles )

	vector directionVec = Vector(0,0,0)
	directionVec += right * xAxis
	directionVec += forward * yAxis

	vector directionAngles = VectorToAngles( directionVec )
	vector directionForward = AnglesToForward( directionAngles )

	return directionForward
}

void function TrailerJump_Think( entity player )
{
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )
	player.EndSignal( "DisembarkingTitan" )
	player.EndSignal( "TitanEjectionStarted" )

	string gravityScale = expect string( player.kv.gravity )
	string airSpeed = expect string( player.kv.airSpeed )
	string airAcceleration = expect string( player.kv.airAcceleration )
	OnThreadEnd(
		function() : ( player, airSpeed, airAcceleration, gravityScale )
		{
			if ( IsValid( player ) )
			{
				player.kv.airSpeed = airSpeed
				player.kv.airAcceleration = airAcceleration
				player.kv.gravity = gravityScale
				player.SetTitanDisembarkEnabled( true )
				player.Server_TurnDodgeDisabledOff()
			}
		}
	)
	player.kv.gravity = string( TRAILER_GRAV_SCALE )
	player.kv.airSpeed = "0.0"
	player.kv.airAcceleration = "0.0"
	player.SetTitanDisembarkEnabled( false )
	player.Server_TurnDodgeDisabledOn()

	vector angles = player.EyeAngles()
	float xAxis = player.GetInputAxisRight()
	float yAxis = player.GetInputAxisForward()
	vector directionForward = GetDirectionFromInput( angles, xAxis, yAxis )
	directionForward.z = 0
	player.SetVelocity( directionForward * TRAILER_JUMP_X_VEL + < 0, 0, TRAILER_JUMP_Y_VEL > )

	wait 0.3 // Some buffer so they can get off the ground first

	while( !player.IsOnGround() )
		WaitFrame()
	
	player.SetVelocity( <0, 0, 0> )
	EmitSoundOnEntityOnlyToPlayer( player, player, "core_ability_land_1p" )
	EmitSoundOnEntityExceptToPlayer( player, player, "core_ability_land_3p" )
}

var function OnWeaponNPCPrimaryAttack_titanability_rearm( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity weaponOwner = weapon.GetWeaponOwner()

	entity ordnance = weaponOwner.GetOffhandWeapon( OFFHAND_RIGHT )
	if ( IsValid( ordnance ) )
	{
		ordnance.SetWeaponPrimaryClipCount( ordnance.GetWeaponPrimaryClipCountMax() )
		if ( ordnance.IsChargeWeapon() )
			ordnance.SetWeaponChargeFractionForced( 0 )
	}
	entity defensive = weaponOwner.GetOffhandWeapon( OFFHAND_LEFT )
	if ( IsValid( defensive ) )
		defensive.SetWeaponPrimaryClipCount( defensive.GetWeaponPrimaryClipCountMax() )

	weapon.SetWeaponPrimaryClipCount( 0 )//used to skip the fire animation
	return 0
}
#endif

bool function OnWeaponAttemptOffhandSwitch_titanability_rearm( entity weapon )
{

	bool allowSwitch = true
	entity weaponOwner = weapon.GetWeaponOwner()
	if ( weaponOwner.IsPlayer() )
		return true

	entity ordnance = weaponOwner.GetOffhandWeapon( OFFHAND_RIGHT )
	entity defensive = weaponOwner.GetOffhandWeapon( OFFHAND_LEFT )

	if ( ordnance.GetWeaponPrimaryClipCount() == ordnance.GetWeaponPrimaryClipCountMax() && defensive.GetWeaponPrimaryClipCount() == defensive.GetWeaponPrimaryClipCountMax() )
		allowSwitch = false

	if ( ordnance.IsBurstFireInProgress() )
		allowSwitch = false

	if ( ordnance.IsChargeWeapon() && ordnance.GetWeaponChargeFraction() > 0.0 )
		allowSwitch = true

	//if ( weapon.HasMod( "rapid_rearm" ) )
	//{
		if ( weaponOwner.GetDodgePower() < 100 )
			allowSwitch = true
	//}

	if( !allowSwitch && IsFirstTimePredicted() )
	{
		// Play SFX and show some HUD feedback here...
		#if CLIENT
			AddPlayerHint( 1.0, 0.25, $"rui/titan_loadout/tactical/titan_tactical_rearm", "#WPN_TITANABILITY_REARM_ERROR_HINT" )
			if ( weaponOwner == GetLocalViewPlayer() )
				EmitSoundOnEntity( weapon, "titan_dryfire" )
		#endif
	}

	return allowSwitch
}

//UPDATE TO RESTORE CHARGE FOR THE MTMS