/*
    File: fn_sideMissionNotify.sqf
    Author: YLS
    Date: 2026-10-31
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Debrief of a finished side mission on this client: removes the mission marker and shows the result, the reason for
        a failure and what it did to the civil reputation. The "task succeeded / failed" popup comes from the task itself.

    Parameter(s):
        _title      - Localisation key of the mission title             [STRING, defaults to ""]
        _success    - Mission was successful                            [BOOL, defaults to false]
        _repChange  - Civil reputation change                           [NUMBER, defaults to 0]
        _intelGain  - Intel reward                                      [NUMBER, defaults to 0]
        _quality    - How well it went in percent                       [NUMBER, defaults to 0]
        _reason     - Localisation key of why it failed                 [STRING, defaults to ""]

    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_title", "", [""]],
    ["_success", false, [false]],
    ["_repChange", 0, [0]],
    ["_intelGain", 0, [0]],
    ["_quality", 0, [0]],
    ["_reason", "", [""]]
];

if (!hasInterface) exitWith {false};

deleteMarkerLocal "secondarymarker";
deleteMarkerLocal "secondarymarkerzone";

private _rep = format ["%1%2", ["", "+"] select (_repChange >= 0), _repChange];
private _text = if (_success) then {
    format [localize "STR_SIDEMISSION_SUCCESS", localize _title, _quality, _rep, _intelGain]
} else {
    if (_reason isEqualTo "") then {
        format [localize "STR_SIDEMISSION_FAILED", localize _title, _rep]
    } else {
        format [localize "STR_SIDEMISSION_FAILED_REASON", localize _title, _rep, localize _reason]
    };
};

systemChat _text;
hint parseText format ["<t size='1.2' color='%1'>%2</t><br/>%3", ["#ff4040", "#80ff80"] select _success, localize _title, _text];

true
