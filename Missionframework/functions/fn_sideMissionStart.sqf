/*
    File: fn_sideMissionStart.sqf
    Author: YLS
    Date: 2026-10-31
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Announces a side mission from the registry (KPLIB_sidemissions): creates a task with a description for all players
        (it shows in the map's task list and survives a rejoin), publishes the objective position and shows the marker.

    Parameter(s):
        _index      - Index of the mission in KPLIB_sidemissions                                [NUMBER, defaults to -1]
        _pos        - Position of the marker and the task                                       [POSITION, defaults to []]
        _descKey    - Localisation key of the task description, with %1, %2, ... for the args   [STRING, defaults to ""]
        _descArgs   - Arguments for the description                                              [ARRAY, defaults to []]
        _marker     - Marker [radius, color, type]                                               [ARRAY, defaults to [100, "ColorGreen", "mil_objective"]]

    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_index", -1, [0]],
    ["_pos", [], [[]]],
    ["_descKey", "", [""]],
    ["_descArgs", [], [[]]],
    ["_marker", [100, "ColorGreen", "mil_objective"], [[]], 3]
];

if (!isServer || {_index < 0} || {_pos isEqualTo []}) exitWith {false};

private _title = localize ((KPLIB_sidemissions select _index) select 0);
private _description = format ([localize _descKey] + _descArgs);

secondary_objective_position_marker = _pos;
publicVariable "secondary_objective_position_marker";
KPLIB_secondary_marker_info = _marker; publicVariable "KPLIB_secondary_marker_info";
KPLIB_secondary_in_progress = _index; publicVariable "KPLIB_secondary_in_progress";

// The task: players see the description in the map's task list, and get the usual "task created" notification
// Every mission gets its own task id, so the clean-up timer of an earlier mission can't remove the task of the next one
if (isNil "KPLIB_sidemission_counter") then {KPLIB_sidemission_counter = 0;};
KPLIB_sidemission_counter = KPLIB_sidemission_counter + 1;
KPLIB_sidemission_task = format ["KPLIB_sidemission_%1", KPLIB_sidemission_counter];
[KPLIB_side_player, KPLIB_sidemission_task, [_description, _title, ""], _pos, "CREATED", 1, true, "default", true] call BIS_fnc_taskCreate;

_marker params ["_radius", "_color", "_type"];
[_pos, _title, _radius, false, _color, _type] remoteExec ["KPLIB_fnc_sideMissionMarker"];

[format ["Side mission %1 announced at %2: %3", _index, _pos, _description], "SIDEMISSION"] call KPLIB_fnc_log;

true
