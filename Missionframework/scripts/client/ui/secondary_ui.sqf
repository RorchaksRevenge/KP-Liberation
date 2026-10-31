scriptName "KPLIB_secondary_ui";

if ( isNil "KPLIB_secondary_starting" ) then { KPLIB_secondary_starting = false; };
if ( isNil "KPLIB_secondary_in_progress" ) then { KPLIB_secondary_in_progress = -1; };

_dialog = createDialog "liberation_secondary";
dostartsecondary = 0;

waitUntil { dialog };

{
    lbAdd [ 101, localize (_x select 0) ];
} foreach KPLIB_sidemissions;

private [ "_oldchoice", "_images", "_briefings", "_missioncost" ];

_images = KPLIB_sidemissions apply {_x select 2};
_briefings = KPLIB_sidemissions apply {_x select 1};

_oldchoice = -1;
lbSetCurSel [ 101, 0 ];

while { dialog && alive player && dostartsecondary == 0 } do {

    if ( _oldchoice != lbCurSel 101 ) then {
        _oldchoice = lbCurSel 101;
        ctrlSetText [ 106, _images select _oldchoice ];
        // What the mission pays and costs, from the registry, above the briefing
        private _m = KPLIB_sidemissions select _oldchoice;
        private _lines = [];
        if ((_m select 5) > 0) then {_lines pushBack format [localize "STR_SECONDARY_REWARD_REP", _m select 5, (_m select 5) + (_m select 6)];};
        if ((_m select 7) > 0) then {_lines pushBack format [localize "STR_SECONDARY_PENALTY_REP", _m select 7];};
        if ((_m select 8) > 0) then {_lines pushBack format [localize "STR_SECONDARY_REWARD_INTEL", _m select 8];};
        private _block = if (_lines isEqualTo []) then {""} else {"<t size='1.1' color='#80d080'>" + (_lines joinString "<br/>") + "</t><br/><br/>"};
        ((findDisplay 6842) displayCtrl (102)) ctrlSetStructuredText parseText (_block + localize (_briefings select _oldchoice));
    };

    _missioncost = KPLIB_secondary_missions_costs select _oldchoice;

    if ( ( _missioncost <= resources_intel ) && ( !KPLIB_secondary_starting ) )  then {
        ctrlEnable [ 103, true ];
        ((findDisplay 6842) displayCtrl (103)) ctrlSetTooltip "";
    } else {
        ctrlEnable [ 103, false ];
        if ( _missioncost > resources_intel ) then {
            ((findDisplay 6842) displayCtrl (103)) ctrlSetTooltip (localize "STR_SECONDARY_NOT_ENOUGH_INTEL");
        };
        if ( KPLIB_secondary_starting ) then {
            ((findDisplay 6842) displayCtrl (103)) ctrlSetTooltip (localize "STR_SECONDARY_IN_PROGRESS");
        };
    };

    if ( KPLIB_secondary_in_progress >= 0 ) then {
        lbSetCurSel [ 101, KPLIB_secondary_in_progress ];
        ctrlEnable [ 101, false ];
    } else {
        ctrlEnable [ 101, true ];
    };

    ctrlSetText [ 107, format [ localize "STR_SECONDARY_INTEL", resources_intel ] ];
    sleep 0.1;
};

if ( dostartsecondary == 1 ) then {
    private _index = lbCurSel 101;
    if (!((KPLIB_sidemissions select _index) select 9) || {!(([2000,999999,false] call KPLIB_fnc_getOpforSpawnPoint) isEqualTo "")}) then {
        [_index] remoteExec ["start_secondary_remote_call", 2];
    } else {
        hint "There is not enough enemy territory left for secondary missions.";
        uiSleep 2;
        hintSilent "";
    }
};

if ( dialog ) then {
    closeDialog 0;
};
