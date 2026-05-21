/*
 * DRO_fnc_chooseMissionMusic
 *
 * Builds day/night/extract music arrays (base A3 + SOG PF VN variants),
 * selects tracks based on timeOfDay and worldName.
 *
 * Globals set:   musicMain, musicExtract, musicMainVNHeli, musicVNExtract
 * Globals read:  timeOfDay, worldName
 */

// Intro Music
_musicArrayDay = [
	"LeadTrack02_F_EXP",
	"AmbientTrack03_F",
	"LeadTrack02_F_EPA",
	"LeadTrack01_F_EPA",
	"LeadTrack03_F_EPA",
	"LeadTrack01_F_EPB",
	"LeadTrack06_F",
	"BackgroundTrack02_F_EPC",
	"LeadTrack03_F_Mark",
	"LeadTrack02_F_EPB"	
];
_musicArrayNight = [
	"AmbientTrack04_F",
	"AmbientTrack04a_F",
	"AmbientTrack01_F_EPB",
	"AmbientTrack01b_F",
	"AmbientTrack01_F_EXP",
	"LeadTrack03_F_EPA",
	"LeadTrack03_F_EPC",
	"BackgroundTrack04_F_EPC",
	"EventTrack03_F_EPC"
];
_musicArrayExtract = [
	"LeadTrack02_F_Mark",
	"LeadTrack05_F_Tank",
	"LeadTrack02_F_EPC",
	"LeadTrack02_F_EPA"
];
musicMain = nil;
if (timeOfDay <= 2) then {
	musicMain = selectRandom _musicArrayDay;
} else {
	musicMain = selectRandom _musicArrayNight;
};
musicExtract = selectRandom _musicArrayExtract;
//added for VN missions
_musicArrayVNHeli = [
	"vn_dont_cry_baby",
	"vn_there_it_is",
	"vn_voodoo_girl",
	"vn_trippin",
	"vn_drafted"
];
_musicArrayVNDay = [
	"vn_another_life",
	"vn_unsung_heroes",
	"vn_cover_blown",
	"vn_prairie_fire",
	"vn_prayer_for_the_fallen",
	"vn_the_village",
	"vn_deadly_jungle"
];
_musicArrayVNNight = [
	"vn_calm_before_the_storm",
	"vn_behind_enemy_lines",
	"vn_enemy_territory",
	"vn_stealth_mode",
	"vn_shadows_of_the_forest",
	"vn_deadly_jungle"
];
_musicArrayVNExtract = [
	"vn_contact",
	"vn_time_to_leave",
	"vn_imminent_attack",
	"vn_hell_on_earth"
];
musicMainVNHeli = nil;
musicVNExtract = nil;
if (worldName in ["Cam_Lao_Nam","vn_khe_sanh","vn_the_bra"]) then {
	musicMainVNHeli = selectRandom _musicArrayVNHeli;
	musicVNExtract = selectRandom _musicArrayVNExtract;
	if (timeOfDay <= 2) then {
		musicMain = selectRandom _musicArrayVNDay;
	} else {
		musicMain = selectRandom _musicArrayVNNight;
	};
};
