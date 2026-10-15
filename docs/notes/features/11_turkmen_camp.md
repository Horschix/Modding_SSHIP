# 11 - Turkmen Camp + Turkmen Alps (board issue #11)

Installed 15 Oct 2026, all 24 files read back identical. Build tool: `docs/tools/turkmen_camp.py <repo root>`
(edits the repo copies in place, refuses files that already carry the marker `Modding_SSHIP #11 Turkmen Camp`).
Originals: `backups/2026-10-15_before_turkmen_camp/`.

## User decisions (15 Oct 2026)
- The Cuman building is SSHIP's `grasslands` chain. It is a nomad alternative economy: it blocks farms 2-6,
  builders 1-4 and town hall upgrades, and needs low farms + the tartars/cumans resource. The user picked
  version (a): a NEW chain for Rum, Seljuqs (`turks`) and Zengids, buildable everywhere, no farm / town hall link.
- Effects: trade income and population growth, but more unrest (law).
- Oghuz Guard (`Imperial Guard`, Seljuqs, stables after CANNONS) stays as it was.
- Kurdish Javelinmen for Rum only in Kurdish lands = regions with the `zengid` or `abbasid` hidden resource (4b).
- Turkmen Alps from camp level 2.
- Camp level 1 in the starting settlements of Rum and the Seljuqs.

## Why Rum had Kurdish but not Turcoman javelins (answered)
- Kurdish Javelinmen: every level of city AND castle barracks, factions incl. rum, in any region with the
  rum / zengid / abbasid / turks resource (= practically all of Anatolia and the Middle East).
- Turcoman Javelinmen (`Turkish Javelinmen`): castle barracks only, garrison quarters and up, good pool only in
  rum / turks regions (+0.05 trickle elsewhere). Most 1132 towns are cities -> never seen.

## What was built
- EDB chain `turkmen_camp` (120 of 128 chains), levels `turkmen_oba` (village, 1000, 6 turns),
  `turkmen_encampment` (town, 3000, 10), `turkmen_beylik` (large_town, 6000, 12). Requires factions rum, turks,
  zengid only. Per level n: trade_base_income +n, population_growth +n, law -n, cavalry_bonus n.
  Recruitment (rate per turn, cap):
  - Oghuz HA: 0.10/2, 0.14/2, 0.18/3, minus 0.02 after ISLAM_BARID and 0.04 after KANKAN_MUSA (SSHIP's own decline)
  - Turcoman Javelinmen: 0.15/2, 0.2/3, 0.25/3
  - Turkmen Alps: level 2 0.1/2, level 3 0.14/3
  - Turkmen Cavalry: level 2 0.06/2, level 3 0.09/2, halved after the_mongols_emerge
  - AI support (not the player, every 4 turns via leap_year_counter_1): HA and Alps on levels 2 and 3
- Removed for rum / turks / zengid: 98 old recruit lines of those three units in stables, castle barracks
  and city barracks; 16 lines with mixed faction lists lost only these factions; the 6 Turkomans lines for
  `{ all, }` got `and not factions { rum, turks, zengid, }`. Egypt, Abbasids, Moors, Mongols, Cumans, rebels and
  the European AoR lines are unchanged.
- Kurdish Javelinmen: rum removed from the Muslim line on all 12 barracks levels; a rum line added after each
  (`hidden_resource zengid or hidden_resource abbasid`).
- Turkmen Alps (EDU in data, data XII, data XIII, identical entry): 48 men, sword attack 7 / charge 4, armour 5,
  defence 5, shield 4, morale 9 normal trained, hardy, 2 turns, cost 1900, upkeep 700, light infantry; ownership
  rum, turks, zengid, slave; custom battle eras 0-1. Upgrades: Turkmen_Alps / Turkmen_Alps_ug1.
- battle_models.modeldb (972 -> 974): `turkmen_alps` (light shield mesh) and `turkmen_alps_ug1` (medium shield
  mesh) = the Turkish Archers meshes / textures / sprites with a single `MTW2_Swordsman` skeleton,
  `MTW2_Sword_Primary` + `fs_test_shield` (format copied from hungaryn_infantry). Inserted after
  turkish_archers_ug1.
- Texts appended: export_units.txt (Turkmen_Alps), export_buildings.txt (chain + 3 levels).
- Pictures (on the PC only, copies): building pics from the grasslands / nomad levels under
  `ui/middle_eastern/buildings` (+ `_constructed`, + `construction/`); unit card from `ui/units/rum/#Turkish_Archers.tga`
  and info from `ui/unit_info/merc/Turkish_Archers_info.tga` to `ui/units|unit_info/{rum,turks,zengid}/`.
  (Zengid has no own Turkish Archers / HA cards - those units are mercenary_unit and use the merc folder.)
- descr_strat.txt: `turkmen_camp turkmen_oba` in all 10 starting settlements of rum (2) and turks (8).
- starting_settlements.lua: script-added settlements owned by rum or turks get camp level 1 at creation
  (log line `turkmen camp hxstart_...`).

## Needs a NEW campaign (descr_strat). map.rwm does not need deleting.

## To watch in the test
- Camp buildable in towns and castles, pictures and texts show, pools as above.
- Turkmen Alps: card, model (round shield, sword, no bow), stats; custom battle.
- Stables / castle barracks of Rum no longer offer the three units; Kurdish javelins only in the east.
- Whether AI Rum / Seljuqs / Zengids build camps (otherwise their horse archers dry up).
