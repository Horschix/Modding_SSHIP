#!/usr/bin/env python3
"""Settler units for founding outposts (Modding_SSHIP #3).

Usage: add_settlers.py <SSHIP mod folder copy> <OUT folder>
  The first folder must hold (original SSHIP files):
    data/export_descr_unit.txt, data XII/data/export_descr_unit.txt, data XIII/data/export_descr_unit.txt,
    data/export_descr_buildings.txt, data/text/export_units.txt
  Writes the changed files to OUT with the same relative paths, plus cards.txt (which picture files to copy).
Safe to re-run on the originals; refuses files that already contain the settlers.
"""
import os, re, sys

MARK = ";---------------------- Modding_SSHIP #3 settlers (found outposts from a fort) ----------------------"

# user decision 10 Oct 2026: one unit per religion group; slave and symbol (not on the map) left out
GROUPS = [
    # type name,          dictionary,           model,               factions,                                   card copied from
    ("Catholic Settlers", "Catholic_Settlers", "Peasants",
     "venice, sicily, denmark, scotland, france, hre, england, portugal, poland, spain, hungary, aragon, norway, jerusalem, pisa, papal_states",
     "hunters"),
    ("Orthodox Settlers", "Orthodox_Settlers", "Southern_Peasants",
     "byzantium, russia, kievan_rus, serbia, georgia", "slav_levies"),
    ("Muslim Settlers", "Muslim_Settlers", "ME_Spear_Militia",
     "abbasid, egypt, turks, moors, zengid, rum", "syrian_auxilliaries"),
    ("Pagan Settlers", "Pagan_Settlers", "EE_Spear_Militia",
     "cumans, lithuania", "woodsmen"),
]
NL = "\r\n"

def unit_entry(name, dic, model, factions):
    # numbers as EUR's settlers (Modding_DAC-EUR #35): 100 men in the file = 250 on huge, weakest stats,
    # cost 300, upkeep 100, no officers, not in custom battles
    lines = [
        f"type             {name}",
        f"dictionary       {dic}      ; {name} : found an outpost from a fort (Modding_SSHIP #3)",
        "category         infantry",
        "class            light",
        "voice_type       Light",
        "banner faction   main_infantry",
        "banner holy      crusade",
        f"soldier          {model}, 100, 0, 0.75",
        "attributes       sea_faring, can_withdraw, no_custom",
        "move_speed_mod	 1.03",
        "formation        1.2, 0, 2.0, 2.8, 3, square",
        "stat_health      1, 0",
        "stat_pri         1, 0, no, 0, 0, melee, melee_simple, piercing, knife, 25, 1",
        "stat_pri_attr    no",
        "stat_sec         0, 0, no, 0, 0, no, melee_simple, blunt, none, 0, 1",
        "stat_sec_attr    no",
        "stat_pri_armour  0, 0, 0, flesh",
        "stat_sec_armour  0, 0, flesh",
        "stat_heat        1",
        "stat_ground      0, 0, 0, 0",
        "stat_mental      1, low, untrained",
        "stat_charge_dist 6",
        "stat_fire_delay  0",
        "stat_food        60, 300",
        "stat_cost        1, 300, 100, 75, 75, 300, 4, 36",
        "armour_ug_levels 0",
        f"armour_ug_models {model}",
        f"ownership        {factions}",
        "info_pic_dir     merc",
        "card_pic_dir     mercs",
        "recruit_priority_offset    -100",
    ]
    return NL.join(lines) + NL

def add_units(path_in, path_out):
    s = open(path_in, encoding="latin-1", newline="").read()
    if "Catholic Settlers" in s:
        raise SystemExit(f"{path_in}: settlers already present")
    count = len(re.findall(r"(?m)^type\s", s))
    if count + len(GROUPS) > 500:
        raise SystemExit(f"{path_in}: {count} units, no room for {len(GROUPS)} more")
    block = NL + NL + MARK + NL + NL + (NL).join(unit_entry(*g[:4]) for g in GROUPS)
    s = s.rstrip("\r\n") + block
    os.makedirs(os.path.dirname(path_out), exist_ok=True)
    open(path_out, "w", encoding="latin-1", newline="").write(s)
    return count + len(GROUPS)

def add_texts(path_in, path_out):
    t = open(path_in, encoding="utf-16", newline="").read()
    if "{Catholic_Settlers}" in t:
        raise SystemExit(f"{path_in}: settler texts already present")
    nl = "\r\n" if "\r\n" in t else "\n"
    people = {"Catholic": "Catholic", "Orthodox": "Orthodox", "Muslim": "Muslim", "Pagan": "pagan"}
    add = []
    for name, dic, *_ in GROUPS:
        who = people[name.split()[0]]
        add.append(f"{{{dic}}}{name}")
        add.append(f"{{{dic}_descr_short}}{who.capitalize() if who == 'pagan' else who} families ready to settle new land. Bring 500 of them with a general into one of your forts to found an outpost.")
        add.append(f"{{{dic}_descr}}Quality: None.\\nType: Settlers (not soldiers).\\n\\nFarmers, craftsmen and their families who have left their homes to settle new land. "
                   f"They are not meant to fight. Lead 500 settlers with a general into one of your forts and found an outpost there for 5000 gold: "
                   f"the fort becomes a small town and the settlers become its people.")
    t = t.rstrip("\r\n") + nl + nl.join(add) + nl
    os.makedirs(os.path.dirname(path_out), exist_ok=True)
    open(path_out, "w", encoding="utf-16", newline="").write(t)

def add_recruitment(path_in, path_out):
    s = open(path_in, encoding="latin-1", newline="").read()
    if '"Catholic Settlers"' in s:
        raise SystemExit(f"{path_in}: settler recruitment already present")
    lines = s.split("\r\n")
    out, building, levels, depth_seen, added = [], None, 0, False, 0
    want = {"core_building", "core_castle_building"}
    i = 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"^building\s+(\S+)", line)
        if m:
            building = m.group(1)
        out.append(line)
        # first "capability" + "{" of every level of the two town / castle core buildings
        if building in want and line.strip() == "capability" and i + 1 < len(lines) and lines[i + 1].strip() == "{":
            out.append(lines[i + 1])
            i += 1
            out.append(";--- Modding_SSHIP #3: settlers, player only")
            for name, dic, model, factions, card in GROUPS:
                # refill 1 per turn (13 Oct 2026): SSHIP sets is_the_player only at each faction's turn start
                # (globalEvents.isPlayer in onPreFactionTurnStart), so a new campaign begins with stock 0, not 2;
                # with 0.1 per turn the first unit only appeared after 10 turns
                out.append(f'        recruit_pool "{name}"  2   1   2  0  requires factions {{ {factions}, }} and event_counter is_the_player 1')
            added += 1
        i += 1
    if added != 10:
        raise SystemExit(f"expected 10 levels (5 town + 5 castle), found {added}")
    os.makedirs(os.path.dirname(path_out), exist_ok=True)
    open(path_out, "w", encoding="latin-1", newline="").write("\r\n".join(out))
    return added

def main():
    src, out = sys.argv[1], sys.argv[2]
    for rel in ("data/export_descr_unit.txt", "data XII/data/export_descr_unit.txt", "data XIII/data/export_descr_unit.txt"):
        n = add_units(os.path.join(src, rel), os.path.join(out, rel))
        print(rel, "->", n, "units")
    add_texts(os.path.join(src, "data/text/export_units.txt"), os.path.join(out, "data/text/export_units.txt"))
    print("levels with recruitment:", add_recruitment(os.path.join(src, "data/export_descr_buildings.txt"),
                                                       os.path.join(out, "data/export_descr_buildings.txt")))
    with open(os.path.join(out, "cards.txt"), "w") as f:
        for name, dic, model, factions, card in GROUPS:
            f.write(f"data/ui/units/mercs/#{card}.tga -> data/ui/units/mercs/#{dic.lower()}.tga\n")
            f.write(f"data/ui/unit_info/merc/{card}_info.tga -> data/ui/unit_info/merc/{dic.lower()}_info.tga\n")

if __name__ == "__main__":
    main()
