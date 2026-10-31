/*
    File: fn_sideMissionNotify.sqf
    Author: YLS
    Date: 2026-10-31
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Debrief of a finished side mission on this client: removes the mission marker and shows the result.

    Parameter(s):
        _title      - Localisation key of the mission title             [STRING, defaults to ""]
        _success    - Mission was successful                            [BOOL, defaults to false]
        _repChange  - Civil reputation change                           [NUMBER, defaults to 0]
        _intelGain  - Intel reward                                      [NUMBER, defaults to 0]
        _quality    - How well it went in percent                       [NUMBER, defaults to 0]

    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_title", "", [""]],
    ["_success", false, [false]],
    ["_repChange", 0, [0]],
    ["_intelGain", 0, [0]],
    ["_quality", 0, [0]]
];

if (!hasInterface) exitWith {false};

deleteMarkerLocal "secondarymarker";
deleteMarkerLocal "secondarymarkerzone";

private _rep = format ["%1%2", ["", "+"] select (_repChange >= 0), _repChange];
private _text = if (_success) then {
    format [localize "STR_SIDEMISSION_SUCCESS", localize _title, _quality, _rep, _intelGain]
} else {
    format [localize "STR_SIDEMISSION_FAILED", localize _title, _rep]
};

[["TaskFailed", "TaskSucceeded"] select _success, ["", _text]] call BIS_fnc_showNotification;
systemChat _text;

true
