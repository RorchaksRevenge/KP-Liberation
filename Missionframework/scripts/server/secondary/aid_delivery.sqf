// Aid delivery: bring an aid crate from a FOB to a town and hand it to the civilians waiting there.
// Success pays the base civil reputation plus a bonus for speed, undamaged aid and civilians still alive. Failure costs civil reputation.

private _index = 3;
private _mission = KPLIB_sidemissions select _index;
private _title = localize (_mission select 0);

if (isNil "KPLIB_aid_used_towns") then {KPLIB_aid_used_towns = [];};

private _refund = {
    resources_intel = resources_intel + (_mission select 3);
    ["Aid delivery: no suitable town or FOB found right now. Your intel was refunded."] remoteExec ["hint"];
};

if (KPLIB_sectors_fob isEqualTo []) exitWith {call _refund; [format ["Aid delivery: no FOB available"], "SIDEMISSION"] call KPLIB_fnc_log;};

// Town: a city or capital that isn't ours, at a fair distance from the nearest FOB, not used before in this session
private _distance = KPLIB_aidmission_distance;
private _towns = (KPLIB_sectors_city + KPLIB_sectors_capital) select {
    private _town = _x;
    private _tPos = markerPos _town;
    private _nearest = selectMin (KPLIB_sectors_fob apply {_x distance2D _tPos});
    !(_town in KPLIB_sectors_player) && {!(_town in KPLIB_aid_used_towns)} && {_nearest >= (_distance select 0)} && {_nearest <= (_distance select 1)}
};
if (_towns isEqualTo []) then {_towns = (KPLIB_sectors_city + KPLIB_sectors_capital) select {!(_x in KPLIB_sectors_player)};};
if (_towns isEqualTo []) exitWith {call _refund; ["Aid delivery: no town found", "SIDEMISSION"] call KPLIB_fnc_log;};

private _town = selectRandom _towns;
KPLIB_aid_used_towns pushBackUnique _town;
private _townPos = markerPos _town;
private _dest = [_townPos, 5, 80, 6, 0, 0.35, 0] call BIS_fnc_findSafePos;
if ((_dest distance2D _townPos) > 200) then {_dest = _townPos;};
_dest = [_dest select 0, _dest select 1, 0];

// Aid crate at the FOB nearest to the town
private _fobs = KPLIB_sectors_fob apply {[_x distance2D _dest, _x]};
_fobs sort true;
private _fob = (_fobs select 0) select 1;
private _cratePos = _fob findEmptyPosition [8, 60, KPLIB_b_crateSupply];
if (_cratePos isEqualTo []) then {_cratePos = _fob getPos [15, random 360];};
private _crate = [KPLIB_b_crateSupply, 0, _cratePos] call KPLIB_fnc_createCrate;
if (isNull _crate) exitWith {call _refund; ["Aid delivery: could not create the aid crate", "ERROR"] call KPLIB_fnc_log;};
_crate setVariable ["KPLIB_aidCrate", true, true];

private _crateMarker = createMarker ["aid_crate_marker", getPosATL _crate];
_crateMarker setMarkerType "mil_box";
_crateMarker setMarkerColor "ColorGreen";
_crateMarker setMarkerText "Aid crate";

// Civilians waiting for the aid. They belong to the mission, so their death costs no civil reputation.
private _civGroup = createGroup [KPLIB_side_civilian, true];
private _recipients = [];
for "_i" from 1 to KPLIB_aidmission_recipients do {
    private _civ = _civGroup createUnit [selectRandom KPLIB_c_units, _dest getPos [3 + (random 9), random 360], [], 0, "NONE"];
    _civ setVariable ["KPLIB_missionCivilian", true, true];
    _recipients pushBack _civ;
};
_civGroup setBehaviour "SAFE";

// Announce
secondary_objective_position = _dest;
secondary_objective_position_marker = _dest;
publicVariable "secondary_objective_position_marker";
KPLIB_secondary_in_progress = _index; publicVariable "KPLIB_secondary_in_progress";
[_dest, _title, KPLIB_aidmission_radius, true] remoteExec ["KPLIB_fnc_sideMissionMarker"];

[format ["Aid delivery started - town: %1, destination: %2, FOB: %3, crate at: %4", _town, _dest, _fob, _cratePos], "SIDEMISSION"] call KPLIB_fnc_log;

// Wait for the delivery: crate within the radius, on the ground and still for two checks in a row
private _start = time;
private _result = -1;
private _hold = 0;

while {_result < 0} do {
    sleep 5;

    if (isNull _crate || {!alive _crate}) exitWith {_result = 0;};
    if ((time - _start) > KPLIB_aidmission_time) exitWith {_result = 0;};

    _crateMarker setMarkerPos (getPosATL _crate);

    if (
        ((_crate distance2D _dest) < KPLIB_aidmission_radius) &&
        {isNull (attachedTo _crate)} &&
        {isNull (isVehicleCargo _crate)} &&
        {speed _crate < 2} &&
        {((getPosATL _crate) select 2) < 3}
    ) then {
        _hold = _hold + 1;
    } else {
        _hold = 0;
    };

    if (_hold >= 2) exitWith {_result = 1;};
};

// Quality: speed, undamaged aid and civilians still alive
private _quality = 0;
if (_result == 1) then {
    private _timeScore = 0 max (1 - ((time - _start) / KPLIB_aidmission_time));
    private _civScore = ({alive _x} count _recipients) / (1 max (count _recipients));
    private _crateScore = 1 - (damage _crate);
    _quality = (0.4 * _timeScore) + (0.4 * _civScore) + (0.2 * _crateScore);
};

deleteMarker _crateMarker;
[_index, _result == 1, _quality] call KPLIB_fnc_sideMissionEnd;

// Clean up after the players had time to see the result
sleep 120;
{deleteVehicle _x;} forEach _recipients;
deleteGroup _civGroup;
if (!isNull _crate) then {deleteVehicle _crate;};
