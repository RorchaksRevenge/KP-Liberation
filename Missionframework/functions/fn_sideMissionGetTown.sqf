/*
    File: fn_sideMissionGetTown.sqf
    Author: YLS
    Date: 2026-10-31
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Picks the town for a side mission: a city or capital that isn't ours, at a fair distance from the nearest FOB and
        not used by an earlier side mission in this session. Falls back to any town that isn't ours.

    Parameter(s):
        _distance   - Distance of the town from the nearest FOB [min, max]    [ARRAY, defaults to [1500, 6000]]

    Returns:
        [town marker, safe position in the town] or [] if there is no town or no FOB [ARRAY]
*/

params [
    ["_distance", [1500, 6000], [[]], 2]
];

if (!isServer || {KPLIB_sectors_fob isEqualTo []}) exitWith {[]};

if (isNil "KPLIB_sidemission_used_towns") then {KPLIB_sidemission_used_towns = [];};

private _all = (KPLIB_sectors_city + KPLIB_sectors_capital) select {!(_x in KPLIB_sectors_player)};
private _towns = _all select {
    private _tPos = markerPos _x;
    private _nearest = selectMin (KPLIB_sectors_fob apply {_x distance2D _tPos});
    !(_x in KPLIB_sidemission_used_towns) && {_nearest >= (_distance select 0)} && {_nearest <= (_distance select 1)}
};
if (_towns isEqualTo []) then {_towns = _all;};
if (_towns isEqualTo []) exitWith {[]};

private _town = selectRandom _towns;
KPLIB_sidemission_used_towns pushBackUnique _town;

private _townPos = markerPos _town;
private _pos = [_townPos, 5, 80, 6, 0, 0.35, 0] call BIS_fnc_findSafePos;
if ((_pos distance2D _townPos) > 200) then {_pos = _townPos;};

[_town, [_pos select 0, _pos select 1, 0]]
