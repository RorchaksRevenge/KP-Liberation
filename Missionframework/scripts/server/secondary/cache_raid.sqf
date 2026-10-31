// Cache raid: destroy the enemy weapons cache hidden near an enemy position. The marker only shows a search area.
// Success pays the base civil reputation plus a bonus for speed and for leaving the buildings around the cache undamaged, and lowers the enemy readiness.
// Failure (time out) costs civil reputation.

private _index = 5;
private _mission = KPLIB_sidemissions select _index;
private _title = localize (_mission select 0);

private _spawnMarker = [2000, 999999, false] call KPLIB_fnc_getOpforSpawnPoint;
if (_spawnMarker == "") exitWith {
    resources_intel = resources_intel + (_mission select 3);
    ["Cache raid: no suitable enemy position found right now. Your intel was refunded."] remoteExec ["hint"];
    ["Could not find position for cache raid mission", "ERROR"] call KPLIB_fnc_log;
};
used_positions pushBackUnique _spawnMarker;

private _center = [markerPos _spawnMarker, 0, 120, 8, 0, 0.35, 0] call BIS_fnc_findSafePos;
if ((_center distance2D (markerPos _spawnMarker)) > 250) then {_center = markerPos _spawnMarker;};
_center = [_center select 0, _center select 1, 0];

// The cache: a few ammunition crates
private _cache = [];
for "_i" from 1 to KPLIB_cache_crates do {
    private _box = (selectRandom ["Box_East_AmmoVeh_F", "Box_East_Wps_F", "Box_East_WpsLaunch_F", "Box_East_Support_F"]) createVehicle (_center getPos [2 + (random 6), random 360]);
    _box setVariable ["KPLIB_cacheCrate", true, true];
    _cache pushBack _box;
};

// Guards
private _guards = [_center, 2, [75, 50, 15]] call KPLIB_fnc_sideMissionGuards;

// Buildings around the cache, for the collateral damage score
private _buildings = nearestObjects [_center, ["House"], 150];
private _intactAtStart = {damage _x < 0.5} count _buildings;

// Announce: the marker only shows a search area around the cache
secondary_objective_position = _center;
[
    _index, _center getPos [500, random 360], "STR_SIDEMISSION_CACHE_DESC",
    [markerText ([10000, _center] call KPLIB_fnc_getNearestSector), count _cache, round (KPLIB_cache_time / 60)],
    [1200, "ColorRed", "hd_unknown"]
] call KPLIB_fnc_sideMissionStart;

[format ["Cache raid started - position: %1, crates: %2, guards and vehicles: %3, buildings: %4", _center, count _cache, count _guards, count _buildings], "SIDEMISSION"] call KPLIB_fnc_log;

// Wait until the whole cache is destroyed or the time is up
private _start = time;
private _result = -1;
private _reason = "";

while {_result < 0} do {
    sleep 5;

    if ((_cache findIf {!isNull _x && {alive _x}}) == -1) exitWith {_result = 1;};
    if ((time - _start) > KPLIB_cache_time) exitWith {_result = 0; _reason = "STR_SIDEMISSION_REASON_TIME";};
};

// Quality: speed and buildings left standing
private _quality = 0;
if (_result == 1) then {
    private _timeScore = 0 max (1 - ((time - _start) / KPLIB_cache_time));
    private _buildingScore = 1;
    if (_intactAtStart > 0) then {
        _buildingScore = ({damage _x < 0.5} count _buildings) / _intactAtStart;
    };
    _quality = (0.5 * _timeScore) + (0.5 * _buildingScore);

    KPLIB_enemyReadiness = round (KPLIB_enemyReadiness * (1 - KPLIB_cache_readiness_impact));
};

[_index, _result == 1, _quality, _reason] call KPLIB_fnc_sideMissionEnd;
