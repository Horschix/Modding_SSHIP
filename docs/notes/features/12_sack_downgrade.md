# 12 - Sack / exterminate lowers the settlement level (15 Oct 2026)

Script `eopData/eopScripts/sship/sack_downgrade.lua`, require line at the end of `luaPluginScript.lua`. Log prefix `SACKDOWN`.

## User's design (15 Oct 2026)
- Sack: 25% chance the settlement drops one level. Exterminate: always (100%).
- Lowest: a town can drop to a village; a village cannot drop; a castle stops at motte and bailey.
- Every building that can be replaced drops one level with it (tier 1 stays). Never touched: wonders,
  holy_sepulchre, guild_*, convert_to_*, hidden_temporary_buildings. Damage (hp) carried over.
- Player and AI. Message ("A City Despoiled" / "A City Laid Waste") to the player who sacks or is sacked.
- Population is left alone.

## How it works
- Hooks `onSackSettlement` / `onExterminatePopulation` (EOP: eventData has character, faction, targetFaction,
  regionID - no settlement). Settlement = the capturing general's `character.settlement`, else tile, else region
  (only if the region has one settlement - #4 put several in many regions).
- EOP has `upgrade()` but no downgrade: the script writes `sett.level = level - 1` and swaps the core wall building
  (destroyBuilding + createBuilding of the level below; on failure the old one is rebuilt). Same for all other chains.
- One drop per settlement per turn (both events can fire for one capture).

## Status
- TEST version installed 15 Oct (TEST = true: sack always drops), read back identical. Check in one siege: settlement
  panel / level name, walls, building browser, save + load, and the SACKDOWN log lines. Then TEST = false (25%).
- Risk to watch: writing `level` directly may not refresh everything the engine caches (e.g. the strat-map model,
  the settlement name card, or the max-population threshold). If that shows, the log line is the first thing to read.

## Dropped (user, 15 Oct 2026)
- Deleting minor settlements on sack / exterminate (chance by tier). EOP has no way to remove a settlement (only
  addSettlement; deleteFort exists because the engine itself removes forts). A "ruins" substitute was offered and
  declined - the user scratched the deletion part.
