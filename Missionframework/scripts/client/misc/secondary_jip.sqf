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

// Missions from the registry with their own marker (aid delivery, hostage rescue, cache raid)
if ( KPLIB_secondary_in_progress >= 3 ) then {
    waitUntil {!isNil "secondary_objective_position_marker" && {count secondary_objective_position_marker > 0} && {!isNil "KPLIB_secondary_marker_info"}};
    KPLIB_secondary_marker_info params ["_radius", "_color", "_type"];
    [
        secondary_objective_position_marker,
        localize ((KPLIB_sidemissions select KPLIB_secondary_in_progress) select 0),
        _radius,
        false,
        _color,
        _type
    ] call KPLIB_fnc_sideMissionMarker;
};
