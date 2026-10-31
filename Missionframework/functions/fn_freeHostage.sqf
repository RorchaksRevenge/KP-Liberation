/*
    File: fn_freeHostage.sqf
    Author: YLS
    Date: 2026-10-31
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Frees a hostage of the hostage rescue mission: ends the kneeling pose, gives the AI back its movement and sends
        the hostage away from the compound. Called on the server from the "Free hostage" action.

    Parameter(s):
        _hostage    - The hostage       [OBJECT, defaults to objNull]
        _caller     - The player freeing the hostage [OBJECT, defaults to objNull]

    Returns:
        Hostage was freed [BOOL]
*/

params [
    ["_hostage", objNull, [objNull]],
    ["_caller", objNull, [objNull]]
];

if (!isServer) exitWith {false};
if (isNull _hostage || {!alive _hostage} || {_hostage getVariable ["KPLIB_hostageFreed", false]}) exitWith {false};

_hostage setVariable ["KPLIB_hostageFreed", true, true];

[_hostage, ""] remoteExec ["switchMove"];
_hostage remoteExec ["removeAllActions"];
_hostage enableAI "MOVE";
_hostage enableAI "ANIM";
_hostage setBehaviour "CARELESS";
_hostage setSpeedMode "FULL";
_hostage doMove (_hostage getPos [150 + (random 100), (_hostage getDir _caller) + 180]);

true
