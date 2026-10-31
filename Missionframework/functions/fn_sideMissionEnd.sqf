/*
    File: fn_sideMissionEnd.sqf
    Author: YLS
    Date: 2026-10-31
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Finishes a side mission from the registry (KPLIB_sidemissions): pays or takes the civil reputation, pays the intel
        reward, frees the mission slot, tells all players and saves.
        On success the civil reputation changes by the mission's base gain plus its bonus scaled by the quality.
        On failure it drops by the mission's failure loss. Civilians dying during the mission never cost civil reputation here.

    Parameter(s):
        _index      - Index of the mission in KPLIB_sidemissions                [NUMBER, defaults to -1]
        _success    - Mission was successful                                    [BOOL, defaults to false]
        _quality    - How well the mission went from 0 to 1 (success only)      [NUMBER, defaults to 0]

    Returns:
        Civil reputation change [NUMBER]
*/

params [
    ["_index", -1, [0]],
    ["_success", false, [false]],
    ["_quality", 0, [0]]
];

if (!isServer) exitWith {0};
if (_index < 0 || {_index >= count KPLIB_sidemissions}) exitWith {0};

(KPLIB_sidemissions select _index) params ["_title", "", "", "", "", "_baseRep", "_bonusRep", "_failRep", "_intelReward"];

_quality = 0 max (_quality min 1);

private _repChange = 0;
private _intelGain = 0;

if (_success) then {
    _repChange = _baseRep + round (_bonusRep * _quality);
    _intelGain = _intelReward;
    resources_intel = resources_intel + _intelGain;
    stats_secondary_objectives = stats_secondary_objectives + 1;
} else {
    _repChange = -_failRep;
};

if (_repChange != 0) then {
    [abs _repChange, _repChange < 0] call F_cr_changeCR;
};

[format ["Side mission %1 ended - success: %2, quality: %3, civil rep: %4, intel: %5", _index, _success, _quality, _repChange, _intelGain], "SIDEMISSION"] call KPLIB_fnc_log;

KPLIB_secondary_in_progress = -1; publicVariable "KPLIB_secondary_in_progress";
secondary_objective_position_marker = []; publicVariable "secondary_objective_position_marker";

[_title, _success, _repChange, _intelGain, round (_quality * 100)] remoteExec ["KPLIB_fnc_sideMissionNotify"];

sleep 1;
[] spawn KPLIB_fnc_doSave;

_repChange
