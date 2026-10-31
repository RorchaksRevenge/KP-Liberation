scriptName "secondary_jip";

waitUntil {
    time > 20;
};

if ( isNil "KPLIB_secondary_in_progress" ) exitWith {};
if ( KPLIB_secondary_in_progress < 0 ) exitWith {};

if ( KPLIB_secondary_in_progress == 0 ) then {
    [ 2 ] call remote_call_intel;
};

if ( KPLIB_secondary_in_progress == 2 ) then {
    [ 6 ] call remote_call_intel;
};

if ( KPLIB_secondary_in_progress == 3 ) then {
    waitUntil {!isNil "secondary_objective_position_marker" && {count secondary_objective_position_marker > 0}};
    [secondary_objective_position_marker, localize "STR_SECONDARY_MISSION3", KPLIB_aidmission_radius, false] call KPLIB_fnc_sideMissionMarker;
};
