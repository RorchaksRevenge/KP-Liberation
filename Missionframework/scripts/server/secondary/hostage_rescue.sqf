// Hostage rescue: civilians are held in a compound in a town, watched by enemy guards. Free them all.
// Success pays the base civil reputation plus a bonus for hostages kept alive and for speed. Failure (all hostages dead or time out) costs civil reputation.
// Hostages belong to the mission, so their death costs no civil reputation, it only lowers the bonus.

private _index = 4;
private _mission = KPLIB_sidemissions select _index;
private _title = localize (_mission select 0);

private _refund = {
    resources_intel = resources_intel + (_mission select 3);
    ["Hostage rescue: no suitable town found right now. Your intel was refunded."] remoteExec ["hint"];
};

private _found = [KPLIB_aidmission_distance] call KPLIB_fnc_sideMissionGetTown;
if (_found isEqualTo []) exitWith {call _refund; ["Hostage rescue: no town or FOB available", "SIDEMISSION"] call KPLIB_fnc_log;};
_found params ["_town", "_dest"];

// Hostages, kneeling in the compound
private _hostageGroup = createGroup [KPLIB_side_civilian, true];
private _hostages = [];
for "_i" from 1 to KPLIB_hostage_count do {
    private _hostage = _hostageGroup createUnit [selectRandom KPLIB_c_units, _dest getPos [1 + (random 5), (_i * (360 / KPLIB_hostage_count))], [], 0, "NONE"];
    _hostage setVariable ["KPLIB_missionCivilian", true, true];
    _hostage setVariable ["KPLIB_hostageFreed", false, true];
    _hostage disableAI "MOVE";
    _hostage disableAI "ANIM";
    _hostage setBehaviour "CARELESS";
    [_hostage, "Acts_ExecutionVictim_Loop"] remoteExec ["switchMove"];
    [_hostage, [
        "<t color='#00ff00'>Free hostage</t>",
        "[_target, _caller] remoteExec ['KPLIB_fnc_freeHostage', 2];",
        [], 6, true, true, "",
        "alive _target && {!(_target getVariable ['KPLIB_hostageFreed', false])} && {(_this distance _target) < 3}",
        3
    ]] remoteExec ["addAction", 0, _hostage];
    _hostages pushBack _hostage;
};

KPLIB_sidemission_hostages = _hostages;

// Guards
private _guards = [_dest, 3, [60, 35, 10]] call KPLIB_fnc_sideMissionGuards;

// Announce
secondary_objective_position = _dest;
[
    _index, _dest, "STR_SIDEMISSION_HOSTAGE_DESC",
    [markerText _town, count _hostages, round (KPLIB_hostage_time / 60)],
    [150, "ColorBlue", "mil_unknown"]
] call KPLIB_fnc_sideMissionStart;

[format ["Hostage rescue started - town: %1, position: %2, hostages: %3, guards and vehicles: %4", _town, _dest, count _hostages, count _guards], "SIDEMISSION"] call KPLIB_fnc_log;

// Wait until every surviving hostage is free, or none is left, or the time is up
private _start = time;
private _result = -1;
private _reason = "";

while {_result < 0} do {
    sleep 5;

    private _alive = _hostages select {alive _x};
    if (_alive isEqualTo []) exitWith {_result = 0; _reason = "STR_SIDEMISSION_REASON_HOSTAGES";};
    if ((time - _start) > KPLIB_hostage_time) exitWith {_result = 0; _reason = "STR_SIDEMISSION_REASON_TIME";};
    if ((_alive findIf {!(_x getVariable ["KPLIB_hostageFreed", false])}) == -1) exitWith {_result = 1;};
};

// Quality: hostages alive and speed
private _quality = 0;
if (_result == 1) then {
    private _aliveScore = ({alive _x} count _hostages) / (1 max (count _hostages));
    private _timeScore = 0 max (1 - ((time - _start) / KPLIB_hostage_time));
    _quality = (0.6 * _aliveScore) + (0.4 * _timeScore);
};

[_index, _result == 1, _quality, _reason] call KPLIB_fnc_sideMissionEnd;

// Clean up after the players had time to see the result
sleep 120;
{deleteVehicle _x;} forEach _hostages;
deleteGroup _hostageGroup;
