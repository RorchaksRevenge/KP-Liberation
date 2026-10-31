// Aid delivery: bring an aid crate from a FOB to a town and hand it to the civilians waiting there.
// Success pays the base civil reputation plus a bonus for speed, undamaged aid and civilians still alive. Failure costs civil reputation.

private _index = 3;
private _mission = KPLIB_sidemissions select _index;
private _title = localize (_mission select 0);

private _refund = {
    resources_intel = resources_intel + (_mission select 3);
    ["Aid delivery: no suitable town or FOB found right now. Your intel was refunded."] remoteExec ["hint"];
};

private _found = [KPLIB_aidmission_distance] call KPLIB_fnc_sideMissionGetTown;
if (_found isEqualTo []) exitWith {call _refund; ["Aid delivery: no town or FOB available", "SIDEMISSION"] call KPLIB_fnc_log;};
_found params ["_town", "_dest"];

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
[
    _index, _dest, "STR_SIDEMISSION_AID_DESC",
    [markerText _town, [_fob] call KPLIB_fnc_getFobName, round (KPLIB_aidmission_time / 60)],
    [KPLIB_aidmission_radius, "ColorGreen", "mil_objective"]
] call KPLIB_fnc_sideMissionStart;

[format ["Aid delivery started - town: %1, destination: %2, FOB: %3, crate at: %4", _town, _dest, _fob, _cratePos], "SIDEMISSION"] call KPLIB_fnc_log;

// Wait for the delivery: crate within the radius, on the ground and still for two checks in a row
private _start = time;
private _result = -1;
private _hold = 0;
private _reason = "";

while {_result < 0} do {
    sleep 5;

    if (isNull _crate || {!alive _crate}) exitWith {_result = 0; _reason = "STR_SIDEMISSION_REASON_CRATE";};
    if ((time - _start) > KPLIB_aidmission_time) exitWith {_result = 0; _reason = "STR_SIDEMISSION_REASON_TIME";};

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
[_index, _result == 1, _quality, _reason] call KPLIB_fnc_sideMissionEnd;

// Clean up after the players had time to see the result
sleep 120;
{deleteVehicle _x;} forEach _recipients;
deleteGroup _civGroup;
if (!isNull _crate) then {deleteVehicle _crate;};
