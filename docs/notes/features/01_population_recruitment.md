# Recruitment costs population (10 Oct 2026) - how it works

Moved out of `docs/HANDOVER.md` on 13 Oct 2026 (unchanged). Read only when working on this issue.
User wish: port the population cost for recruitment from EUR (Modding_DAC-EUR issue #5) to SSHIP.
Minimums stay 400 (player) / 1000 (AI) - user decision.
- INSTALLED 10 Oct, read back and compared byte for byte. WORKS in game (user, 13 Oct: queue / cancel seen in the log):
  `eopData\eopScripts\sship\population_recruitment.lua` (log prefix `POPREC`, lands in `mods\sship\full.log`) and one
  `require('sship.population_recruitment')` line at the END of `eopData\eopScripts\luaPluginScript.lua`
  (after `require('sship.main')`, which defines the event and save/load functions the script wraps).
- Revert: delete the require line (original loader in `backups/2026-10-10_original/`).
- Rules (same as EUR): queue = minus the unit's soldiers 1:1, cancel = refund, retraining = only the missing men,
  too few people = unit greyed out, player disband = men back to the settlement, state saved with the savegame.
- Differences to the EUR script (all else is comments): EXEMPT_TYPES is empty; garrison rule is a name that STARTS
  with "garrison " (SSHIP's `Garrison spear / sword / archers / crossbowmen`, in no recruit_pool of the building
  file = script-only). Free: ships, agents, bodyguards, those four. Elephants and siege cost their crew.
- Findings: SSHIP runs on the same M2TWEOP, its LuaDocs list every function used; SSHIP's own Lua uses none of the
  queue / trained / disbanded events (`populationCap.lua` is an unfinished army cap). 199 settlements start with
  800-101000 people (median 7900; 3 below 1000, 13 below 1500); units 20-80 soldiers in the unit file.
- NOT checked: whether SSHIP scripts disband or replace PLAYER units (would refund men never charged); whether an
  existing SSHIP save loads cleanly (state simply starts empty). Passes `loadfile` with the session's Lua 5.1.
