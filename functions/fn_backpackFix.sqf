// Migrated from DRO_fnc_backpackFix — M3 CfgFunctions migration
// Set backpacks manually as a workaround for a bug with setUnitLoadout	
	_backpackContents = (backpackItems player) + (backpackMagazines player);	
	_backpackClass = backpack player;
	removeBackpackGlobal player;
	player addBackpackGlobal _backpackClass;
	{player addItemToBackpack _x} forEach _backpackContents;
