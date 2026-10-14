# #5 Historic invasion armies

Spawned armies for SSHIP's historic events, like the host of the Mordor ring quest in EUR.
Script: `eopData/eopScripts/sship/historic_invasions.lua`, loaded by the last line of `luaPluginScript.lua`
(`require('sship.historic_invasions')`). No SSHIP file is changed. Log prefix `HXINV` in `full.log`.

## Where SSHIP's historic events live (looked at 15 Oct 2026)
- Live code is Lua in `eopData/eopScripts/sship/`: `crusades.lua` (crusades 2-5 at turns 32 / 114 / 140 / 170,
  Constantinople jihad, `veniceSacksConstantinople`), `mongols.lua` (Mongol armies, spawn + `siegeSettlement`),
  `aiSupport.lua` (random scripted AI sieges with `spawnAndSiege`), `globalEvents.lua` (table of timed historic events).
- `data/world/maps/campaign/imperial_campaign/invasions.lua`, `raidsAndRebellions.lua`, `contestedProvinces.lua` are old
  campaign_script code inside `--[[ ]]` - NOT active. `campaign_script.txt` has no `spawn_army` any more.
- `factionsEvolutions.lua` is also mostly old commented campaign_script.
- `crusades.historicCalltoHolyWar()` runs at the PLAYER's faction turn end (main.lua `onFactionTurnEnd`).
- SSHIP's crusade cleanup: `onGeneralTakesCrusadeTarget` -> `crusades.disbandCrusadeUnits` kills every Religious Fanatics,
  Flagellants, Crusader Knights / Sergeants, Dismounted Crusader Knights, Great Cross of every Catholic faction except
  the winner and Jerusalem, in every army.

## Fourth Crusade (decided by the user, 15 Oct 2026)
- Stage 1, turn 140: Enrico Dandolo (age 90, label `hx4c_zara`) with one combined stack at Zara.
- Stage 2, turn 145: Bonifacio del Monferrato (age 52, label `hx4c_const`) with one combined stack at Constantinople,
  only if an orthodox faction other than Venice holds it. Zara is skipped if Venice already holds it.
- Stacks: 19 units + SE Bodyguard general; Venetian Heavy Infantry, Pavise Crossbow Militia, Venetian Archers,
  Italian MAA / Pavise Spear Militia (Zara) or Feudal Knights (Constantinople), Crusader Knights / Sergeants,
  Dismounted Crusader Knights, 2 NE Trebuchets. Mixed experience. Spawn tile: free land tile in the target's own
  region (keeps Constantinople's army on the European shore).
- Player Venice: SSHIP's question `CONSTANTINOPLE_SACK_CRUSADE` with a new text (SSHIP's turn-140 branch rebuilt:
  crusade on Jerusalem if none, war Venice-Hungary). YES (main.lua calls `crusades.veniceSacksConstantinople`, which we
  replace) = excommunication at once + both armies under player control, no forced moves. NO = state 9, nothing.
- AI Venice: excommunicated when the Zara stage starts; spawn + `siegeSettlement(sett, false)` + move points 0;
  from the next turn on, at Venice's `onFactionTurnStart`, `siegeSettlement(sett, true)` (forced assault) for up to 6
  turns while the town is not Venetian and the general lives.
- War is declared on the target's owner. Other players get a news event (`CRUSADE`), the attacked player a
  `SCRIPTED_INVASION_INFO` event with the location.
- Crusader cleanup: `crusades.disbandCrusadeUnits` replaced by a copy that skips generals whose label starts `hx4c_`.
- State in script counters: `HXINV_4C_STATE` (0 / 1 running / 2 done / 9 cancelled), `HXINV_4C_ZARA_SPAWN`,
  `HXINV_4C_CONST_SPAWN` (spawn turn + 1).

## Status
- 15 Oct 2026: TEST version installed (`TEST = true`: stages at turns 2 and 5, no crusade call / Hungary war),
  read back identical. Simulated with a mocked API (AI and player flows). NEW campaign not required for the hooks,
  but the test turns need one (turn 2).
- Next: user test (as Byzantium for the AI flow, as Venice for the question), then `TEST = false`.
- Open: remove or narrow SSHIP's crusade cleanup (user wants e.g. an England that took Aleppo to keep its crusaders).
- Later candidates: Third Crusade (Barbarossa vs Rum 1190, Richard at Acre), Second Crusade (Lisbon), Fifth Crusade
  (Damietta), Hattin (Saladin vs Jerusalem), Norman sack of Thessalonica (1185).
