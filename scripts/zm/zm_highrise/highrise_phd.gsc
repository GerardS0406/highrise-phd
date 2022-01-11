#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;
#include maps/mp/zombies/_zm_perks;

main()
{
	replacefunc(maps/mp/zombies/_zm_perks::set_perk_clientfield, ::set_perk_clientfield);
	level.zombiemode_using_divetonuke_perk = 1;
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_flakjacket", "divetonuke", 2000, &"ZOMBIE_PERK_DIVETONUKE", "zombie_perk_bottle_jugg" );
	maps/mp/zombies/_zm_perks::register_perk_machine( "specialty_flakjacket", ::divetonuke_perk_machine_setup, ::divetonuke_perk_machine_think );
	spawn_PHD();
}

init()
{
	level.player_starting_points = 500000;
}

init_divetonuke() //checked matches cerberus output
{
	level.zombiemode_divetonuke_perk_func = ::divetonuke_explode;
	set_zombie_var( "zombie_perk_divetonuke_radius", 300 );
	set_zombie_var( "zombie_perk_divetonuke_min_damage", 1000 );
	set_zombie_var( "zombie_perk_divetonuke_max_damage", 5000 );
}

divetonuke_explode( attacker, origin )
{
	radius = level.zombie_vars[ "zombie_perk_divetonuke_radius" ];
	min_damage = level.zombie_vars[ "zombie_perk_divetonuke_min_damage" ];
	max_damage = level.zombie_vars[ "zombie_perk_divetonuke_max_damage" ];
	radiusdamage( origin, radius, max_damage, min_damage, attacker, "MOD_GRENADE_SPLASH" );
	attacker playsound( "zmb_phdflop_explo" );
	fx = loadfx("explosions/fx_default_explosion");
	playfx( fx, origin );
}

divetonuke_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision ) //checked matches cerberus output
{
	use_trigger.script_sound = "mus_perks_phd_jingle";
	use_trigger.script_string = "divetonuke_perk";
	use_trigger.script_label = "mus_perks_phd_sting";
	use_trigger.target = "vending_divetonuke";
	perk_machine.script_string = "divetonuke_perk";
	perk_machine.targetname = "vending_divetonuke";
	if ( isDefined( bump_trigger ) )
	{
		bump_trigger.script_string = "divetonuke_perk";
	}
}

divetonuke_perk_machine_think() //checked changed to match cerberus output
{
	init_divetonuke();
	while ( 1 )
	{
		machine = getentarray( "vending_divetonuke", "targetname" );
		machine_triggers = getentarray( "vending_divetonuke", "target" );
		for ( i = 0; i < machine.size; i++ )
		{
			machine[ i ] setmodel( "zombie_vending_nuke_on_lo" );
		}
		array_thread( machine_triggers, ::set_power_on, 0 );
		level thread do_initial_power_off_callback( machine, "divetonuke" );
		level waittill( "divetonuke_on" );
		for ( i = 0; i < machine.size; i++ )
		{
			machine[ i ] setmodel( "zombie_vending_nuke_on_lo" );
			machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machine[ i ] playsound( "zmb_perks_power_on" );
			machine[ i ] thread perk_fx( "divetonuke_light" );
			machine[ i ] thread play_loop_on_machine();
		}
		level notify( "specialty_flakjacket_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "divetonuke" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "divetonuke" ].power_on_callback );
		}
		level waittill( "divetonuke_off" );
		if ( isDefined( level.machine_assets[ "divetonuke" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "divetonuke" ].power_off_callback );
		}
		array_thread( machine, ::turn_perk_off );
	}
}

spawn_PHD()
{
	struct = spawnstruct();
	struct.origin = (1421.23, 2102.13, 3219.31);
	struct.angles = ( 0, 45, 0 );
	struct.model = "zombie_vending_nuke_on_lo";
	struct.script_noteworthy = "specialty_flakjacket";
	struct.targetname = "zm_perk_machine";
	struct.script_string = getDvar("ui_gametype") + "_perks_" + getDvar("ui_zm_mapstartlocation");
	perk = "specialty_flakjacket";
	use_trigger = Spawn( "trigger_radius_use", struct.origin + ( 0, 0, 30 ), 0, 40, 70 );
	use_trigger.targetname = "zombie_vending";			
	use_trigger.script_noteworthy = perk;
	use_trigger TriggerIgnoreTeam();
	//use_trigger thread debug_spot();

	perk_machine = Spawn( "script_model", struct.origin );
	perk_machine.angles = struct.angles;
	perk_machine SetModel( struct.model );
	if ( is_true( level._no_vending_machine_bump_trigs ) )
	{
		bump_trigger = undefined;
	}
	else
	{
		bump_trigger = spawn("trigger_radius", struct.origin, 0, 35, 64);
		bump_trigger.script_activated = 1;
		bump_trigger.script_sound = "zmb_perks_bump_bottle";
		bump_trigger.targetname = "audio_bump_trigger";
	}	
	collision = Spawn( "script_model", struct.origin, 1 );
	collision.angles = struct.angles;
	collision SetModel( "zm_collision_perks1" );
	collision.script_noteworthy = "clip";
	collision DisconnectPaths();
	
	// Connect all of the pieces for easy access.
	use_trigger.clip = collision;
	use_trigger.machine = perk_machine;
	use_trigger.bump = bump_trigger;
	//missing code found in cerberus output
	if ( isdefined( struct.blocker_model ) )
	{
		use_trigger.blocker_model = struct.blocker_model;
	}
	if ( isdefined( struct.script_int ) )
	{
		perk_machine.script_int = struct.script_int;
	}
	if ( isdefined( struct.turn_on_notify ) )
	{
		perk_machine.turn_on_notify = struct.turn_on_notify;
	}
	if ( isdefined( level._custom_perks[ perk ] ) && isdefined( level._custom_perks[ perk ].perk_machine_set_kvps ) )
	{
		[[ level._custom_perks[ perk ].perk_machine_set_kvps ]]( use_trigger, perk_machine, bump_trigger, collision );
	}
}

set_perk_clientfield( perk, state ) //checked matches cerberus output
{
	switch( perk )
	{
		case "specialty_additionalprimaryweapon":
			self setclientfieldtoplayer( "perk_additional_primary_weapon", state );
			break;
		case "specialty_deadshot":
			self setclientfieldtoplayer( "perk_dead_shot", state );
			break;
		case "specialty_flakjacket":
			if(is_true(state))
				IPrintLnBold("PHD Acquired");
			else
				IPrintLnBold("PHD Lost");
			break;
		case "specialty_rof":
			self setclientfieldtoplayer( "perk_double_tap", state );
			break;
		case "specialty_armorvest":
			self setclientfieldtoplayer( "perk_juggernaut", state );
			break;
		case "specialty_longersprint":
			self setclientfieldtoplayer( "perk_marathon", state );
			break;
		case "specialty_quickrevive":
			self setclientfieldtoplayer( "perk_quick_revive", state );
			break;
		case "specialty_fastreload":
			self setclientfieldtoplayer( "perk_sleight_of_hand", state );
			break;
		case "specialty_scavenger":
			self setclientfieldtoplayer( "perk_tombstone", state );
			break;
		case "specialty_finalstand":
			self setclientfieldtoplayer( "perk_chugabud", state );
			break;
		default:
		if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].clientfield_set ) )
		{
			self [[ level._custom_perks[ perk ].clientfield_set ]]( state );
		}
	}
}
