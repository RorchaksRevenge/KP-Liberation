/*
    File: fn_sideMissionMarker.sqf
    Author: YLS
    Date: 2026-10-31
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Shows the marker of an active side mission on this client and optionally the "task created" notification.
        Used when a mission starts and for players who join while it runs.

    Parameter(s):
        _pos        - Position of the objective                     [POSITION, defaults to []]
        _text       - Marker text                                   [STRING, defaults to ""]
        _radius     - Radius of the area around the objective       [NUMBER, defaults to 100]
        _announce   - Show the notification                         [BOOL, defaults to true]
        _color      - Marker color                                  [STRING, defaults to "ColorGreen"]
        _type       - Marker type                                   [STRING, defaults to "mil_objective"]

    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_pos", [], [[]]],
    ["_text", "", [""]],
    ["_radius", 100, [0]],
    ["_announce", true, [false]],
    ["_color", "ColorGreen", [""]],
    ["_type", "mil_objective", [""]]
];

if (!hasInterface || {_pos isEqualTo []}) exitWith {false};

deleteMarkerLocal "secondarymarker";
deleteMarkerLocal "secondarymarkerzone";

private _marker = createMarkerLocal ["secondarymarker", _pos];
_marker setMarkerTypeLocal _type;
_marker setMarkerColorLocal _color;
_marker setMarkerTextLocal _text;

private _zone = createMarkerLocal ["secondarymarkerzone", _pos];
_zone setMarkerShapeLocal "ELLIPSE";
_zone setMarkerColorLocal _color;
_zone setMarkerBrushLocal "FDiagonal";
_zone setMarkerSizeLocal [_radius, _radius];

if (_announce) then {
    ["TaskCreated", ["", _text]] call BIS_fnc_showNotification;
};

true
