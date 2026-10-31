/*
    File: fn_sideMissionGuards.sqf
    Author: YLS
    Date: 2026-10-31
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Spawns the enemy guards of a side mission: a squad patrolling a square around the objective, a few sentries on it
        and, depending on the enemy readiness, some vehicles close by. Same recipe as KP's search and rescue mission.

    Parameter(s):
        _pos        - Position of the objective                                 [POSITION, defaults to [0, 0, 0]]
        _sentries   - Minimum number of sentries (up to 2 more are added)       [NUMBER, defaults to 2]
        _vehicles   - Chances in percent for up to three vehicles               [ARRAY, defaults to [75, 50, 15]]

    Returns:
        All spawned units and vehicles [ARRAY]
*/

params [
    ["_pos", [0, 0, 0], [[]], [2, 3]],
    ["_sentries", 2, [0]],
    ["_vehicles", [75, 50, 15], [[]]]
];

if (!isServer) exitWith {[]};

private _spawned = [];

// Patrol around the objective
private _patrolGroup = createGroup [KPLIB_side_enemy, true];
private _corners = [
    [(_pos select 0) - 40, (_pos select 1) - 40, 0],
    [(_pos select 0) + 40, (_pos select 1) - 40, 0],
    [(_pos select 0) + 40, (_pos select 1) + 40, 0],
    [(_pos select 0) - 40, (_pos select 1) + 40, 0]
];

{
    _spawned pushBack ([_x, _corners select 0, _patrolGroup, "PRIVATE", 0.5] call KPLIB_fnc_createManagedUnit);
} forEach ([] call KPLIB_fnc_getSquadComp);

while {(count (waypoints _patrolGroup)) != 0} do {deleteWaypoint ((waypoints _patrolGroup) select 0);};
{
    private _waypoint = _patrolGroup addWaypoint [_x, 0];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointSpeed "LIMITED";
    _waypoint setWaypointBehaviour "SAFE";
    _waypoint setWaypointCompletionRadius 5;
} forEach _corners;

private _cycle = _patrolGroup addWaypoint [_corners select 0, 0];
_cycle setWaypointType "CYCLE";
{_x doFollow (leader _patrolGroup)} forEach units _patrolGroup;

// Sentries on the objective
private _sentryGroup = createGroup [KPLIB_side_enemy, true];
for "_i" from 1 to (_sentries + (floor (random 3))) do {
    _spawned pushBack ([KPLIB_o_sentry, _pos getPos [2 + (random 8), random 360], _sentryGroup, "PRIVATE", 0.5] call KPLIB_fnc_createManagedUnit);
};
(leader _sentryGroup) setDir (random 360);

// Vehicles, heavier when the enemy is alert
private _pool = KPLIB_o_armyVehicles;
if (KPLIB_enemyReadiness < 50) then {_pool = KPLIB_o_armyVehiclesLight;};

private _toSpawn = [];
{if (random 100 < _x) then {_toSpawn pushBack (selectRandom _pool);};} forEach _vehicles;
{
    private _vehicle = [_pos getPos [30 + (random 30), random 360], _x, true] call KPLIB_fnc_spawnVehicle;
    _vehicle addMPEventHandler ["MPKilled", {
        params ["_unit", "_killer"];
        ["KPLIB_manageKills", [_unit, _killer]] call CBA_fnc_localEvent;
    }];
    _spawned pushBack _vehicle;
} forEach _toSpawn;

_spawned
