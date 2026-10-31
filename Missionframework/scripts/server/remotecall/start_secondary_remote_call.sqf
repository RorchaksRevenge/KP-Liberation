if (!isServer) exitWith {false};

params [
    ["_mission_index", -1, [0]]
];

private _mission = KPLIB_sidemissions param [_mission_index, []];
if (_mission isEqualTo []) exitWith {false};

if (isNil "KPLIB_secondary_starting") then { KPLIB_secondary_starting = false;};
if (KPLIB_secondary_starting) exitWith {["Multiple calls to start secondary mission : shouldn't be possible, isn't allowed", "ERROR"] call KPLIB_fnc_log;};
if (!isNil "KPLIB_secondary_in_progress" && {KPLIB_secondary_in_progress >= 0}) exitWith {false};
if (isNil "used_positions") then {used_positions = [];};

// Not enough intel (the dialog only checks this on the client)
if (resources_intel < (_mission select 3)) exitWith {false};

KPLIB_secondary_starting = true; publicVariable "KPLIB_secondary_starting";

resources_intel = resources_intel - (_mission select 3);

[] spawn (missionNamespace getVariable [_mission select 4, {}]);

KPLIB_secondary_starting = false; publicVariable "KPLIB_secondary_starting";

true
