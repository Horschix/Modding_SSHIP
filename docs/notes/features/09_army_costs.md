# 09 (issue #7) - Army supply costs with a turn report (15 Oct 2026)

Found: SSHIP 0.98 hands out ArmyCost 1-5 / AtSeaCost 1-2 (trait rules, Very Hard only), but the money monitors are
only a comment in economy.lua (lines 218-867) - nothing charged. Armies without a general instead get SSHIP's
armiesRebelion.lua roll (distance > ~50 from the capital, +30 in foreign lands, random) - that is why it "sometimes"
fired.

User's decisions (15 Oct): SSHIP's amounts (generals 250/500/1000/1500/2000, at sea 500/1000, captain armies
1000 home / 2000 abroad), every difficulty, plus besieging and marriages; rebellion of armies without a general only
as in vanilla M2TW (SSHIP's extra roll off).

`eopData/eopScripts/sship/army_costs.lua` (require line after golden_horde). Log prefix ARMYCOST. Player only.
- turn start: generals' ArmyCost (split field / besieging by army.siege), AtSeaCost; captain-led armies outside
  settlements / forts / fleets: 1000 own region (region of the leader's tile), 2000 foreign, 2000 besieging; turn 0 free.
- marriages: onCharacterMarries 1000, onCharacterMarriesPrincess 2000 (charged at once, once per character and turn,
  2000 in all if both events fire); listed in the next turn report.
- report "The Cost of War" (historicEvent HX_ARMY_COSTS) every turn with costs: total + breakdown.
- armiesRebelion.checkArmiesLoyalty replaced by a no-op on the shared module table (main.lua keeps calling it).
- Not taken over: SSHIP's old -1000 for a new noble (NewNoble trait) and the crusade joining fee.

Status: installed 15 Oct, read back identical. Works in a running campaign (no new campaign needed). Waiting for test.

## Fix (15 Oct 2026) - generals inside a settlement
User: a general stationed in a minor settlement in foreign territory was still charged for campaigning abroad.
SSHIP's ArmyCost trait uses InEnemyLands (region owner), which a minor settlement in a foreign capital's region does
not change. Now a general inside any settlement (character.settlement or army:findInSettlement) is not charged the
ArmyCost amount; the trait itself is untouched. Log line "... not charged (inside a settlement)". Installed, read back identical.
