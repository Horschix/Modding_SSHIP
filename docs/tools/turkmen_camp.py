#!/usr/bin/env python3
"""Turkmen Camp + Turkmen Alps (Modding_SSHIP #11, user 15 Oct 2026).

Usage: turkmen_camp.py <repo root>     (edits the repo copies in place; refuses files that carry the marker)

  1. export_descr_buildings.txt
     - new chain turkmen_camp (turkmen_oba / turkmen_encampment / turkmen_beylik) for rum, turks, zengid,
       buildable everywhere (city + castle), trade income + population growth, more unrest (law -1/-2/-3)
     - Oghuz Horse Archers, Turcoman Javelinmen, Turkmen Cavalry and the new Turkmen Alps come ONLY from the camp
       for these three factions: their lines in stables / castle barracks are removed (other factions untouched;
       the Turkmen Cavalry lines for "all" factions get "and not factions { rum, turks, zengid, }")
     - Kurdish Javelinmen for Rum only in zengid / abbasid regions (user choice 4b)
  2. export_descr_unit.txt (data, data XII, data XIII): new unit Turkmen Alps
  3. battle_models.modeldb: turkmen_alps + turkmen_alps_ug1 (Turkish Archers meshes, sword + shield skeleton)
  4. text/export_units.txt + text/export_buildings.txt (UTF-16LE)
  5. descr_strat.txt: camp level 1 in every Rum and Seljuq (turks) settlement
"""
import os, re, sys

ROOT = sys.argv[1]
MARK = "Modding_SSHIP #11 Turkmen Camp"
NL = "\r\n"
F3 = "rum, turks, zengid,"
MOVED = ("Turkish Horse Archers", "Turkish Javelinmen", "Turkomans")
OURS = {"rum", "turks", "zengid"}


def rd(p, enc="latin-1"):
    with open(os.path.join(ROOT, p), "rb") as f:
        return f.read().decode(enc)


def wr(p, s, enc="latin-1"):
    with open(os.path.join(ROOT, p), "wb") as f:
        f.write(s.encode(enc))


def guard(s, p):
    if MARK in s:
        sys.exit(p + " already holds the Turkmen Camp - refusing")


# ---------------------------------------------------------------------------------------------- buildings
def pool(unit, a, b, c, d, cond):
    return f'\t\trecruit_pool\t"{unit}"\t\t{a}\t{b}\t{c}  {d}  requires factions {{ {F3} }}{cond}'


def level(name, smin, cost, turns, n, upgrade, pools):
    caps = [
        f"\t\ttrade_base_income_bonus bonus {n}",
        f"\t\tpopulation_growth_bonus bonus {n}",
        f"\t\tlaw_bonus bonus -{n}",
        f"\t\tcavalry_bonus {n}",
        "",
    ] + pools
    out = [f"    {name} requires factions {{ {F3} }}", "    {", "      convert_to 0" if n == 1 else f"      convert_to {n - 1}",
           "      capability", "      {"] + caps + ["      }", "      material wooden", f"      construction  {turns}",
           f"      cost  {cost}", f"      settlement_min {smin}", "      upgrades", "      {"]
    if upgrade:
        out.append(f"        {upgrade}")
    out += ["      }", "    }"]
    return out


def camp_chain():
    era_ha = [("not event_counter ISLAM_BARID 1", 0.0),
              ("event_counter ISLAM_BARID 1 and not event_counter KANKAN_MUSA 1", 0.02),
              ("event_counter KANKAN_MUSA 1", 0.04)]
    era_tk = [("not event_counter the_mongols_emerge 1", 1.0), ("event_counter the_mongols_emerge 1", 0.5)]
    ai = " and not event_counter is_the_player 1 and event_counter leap_year_counter_1 1"

    def ha(base, cap):
        return [pool("Turkish Horse Archers", 1, round(base - d, 3), cap, 0, " and " + c) for c, d in era_ha]

    def tk(base, cap):
        return [pool("Turkomans", 1, round(base * m, 3), cap, 0, " and " + c) for c, m in era_tk]

    p1 = ha(0.10, 2) + [pool("Turkish Javelinmen", 1, 0.15, 2, 0, "")]
    p2 = (ha(0.14, 2) + [pool("Turkish Javelinmen", 1, 0.2, 3, 0, ""),
                        pool("Turkmen Alps", 1, 0.1, 2, 0, "")] + tk(0.06, 2)
          + ["", "\t\t; AI support (every 4 turns)", pool("Turkish Horse Archers", 0, 0.2, 0, 0, ai),
             pool("Turkmen Alps", 0, 0.15, 0, 0, ai)])
    p3 = (ha(0.18, 3) + [pool("Turkish Javelinmen", 1, 0.25, 3, 0, ""),
                        pool("Turkmen Alps", 1, 0.14, 3, 0, "")] + tk(0.09, 2)
          + ["", "\t\t; AI support (every 4 turns)", pool("Turkish Horse Archers", 0, 0.3, 0, 0, ai),
             pool("Turkmen Alps", 0, 0.2, 0, 0, ai)])
    lines = [
        "", ";" + "=" * 114,
        f";---- Turkmen Camp ({MARK}, user 15 Oct 2026) -------------------------------------------",
        "; Rum, Seljuqs (turks) and Zengids: buildable everywhere. The ONLY source of Oghuz Horse Archers, Turcoman",
        "; Javelinmen, Turkmen Cavalry and Turkmen Alps for these three factions. Trade income and growth, but unrest.",
        "; No link to farms / builders / town halls (unlike the Cuman grasslands chain).",
        ";" + "=" * 114,
        "building turkmen_camp", "{", "  convert_to turkmen_camp",
        "  levels turkmen_oba turkmen_encampment turkmen_beylik", "  {"]
    lines += level("turkmen_oba", "village", 1000, 6, 1, "turkmen_encampment", p1)
    lines += level("turkmen_encampment", "town", 3000, 10, 2, "turkmen_beylik", p2)
    lines += level("turkmen_beylik", "large_town", 6000, 12, 3, None, p3)
    lines += ["  }", "  plugins", "  {", "  }", "}", ""]
    return lines


def fix_factions(line):
    """Drop rum/turks/zengid from a moved unit's recruit line. Returns new line or None (delete)."""
    m = re.search(r"factions\s*\{([^}]*)\}", line)
    if not m:
        return line
    facs = [f.strip() for f in m.group(1).split(",") if f.strip()]
    if "all" in facs:
        if "not factions { rum, turks, zengid, }" in line:
            return line
        return line[:m.end()] + " and not factions { rum, turks, zengid, }" + line[m.end():]
    keep = [f for f in facs if f not in OURS]
    if len(keep) == len(facs):
        return line
    if not keep:
        return None
    return line[:m.start()] + "factions { " + ", ".join(keep) + ", }" + line[m.end():]


def buildings():
    p = "data/export_descr_buildings.txt"
    s = rd(p)
    guard(s, p)
    lines = s.split(NL)
    out, removed, changed, kurd = [], 0, 0, 0
    chain = None
    for ln in lines:
        mb = re.match(r"building (\S+)", ln)
        if mb:
            chain = mb.group(1)
        st = ln.lstrip()
        if st.startswith("recruit_pool") and chain in ("equestrian", "castle_barracks", "barracks"):
            mu = re.match(r'recruit_pool\s+"([^"]+)"', st)
            unit = mu.group(1) if mu else None
            if unit in MOVED:
                new = fix_factions(ln)
                if new is None:
                    removed += 1
                    continue
                if new != ln:
                    changed += 1
                out.append(new)
                continue
            if unit == "Kurdish Javelinmen" and "factions { moors, egypt, rum, turks," in ln:
                out.append(ln.replace("factions { moors, egypt, rum, turks,", "factions { moors, egypt, turks,"))
                ind = ln[:len(ln) - len(st)]
                out.append(ind + 'recruit_pool\t"Kurdish Javelinmen"\t\t1\t0.05\t2  0  requires factions { rum, } '
                           'and hidden_resource zengid or hidden_resource abbasid\t; Rum: Kurdish lands only (' + MARK + ')')
                kurd += 1
                continue
        out.append(ln)
    # insert the new chain before the Builders section header
    idx = next(i for i, l in enumerate(out) if l.startswith(";---- Builders"))
    while idx > 0 and out[idx - 1].startswith(";="):
        idx -= 1
    out[idx:idx] = camp_chain()
    s2 = NL.join(out)
    n = re.search(r"CURRENTLY:\s+(\d+) BUILDINGS", s2)
    s2 = s2.replace(n.group(0), n.group(0).replace(n.group(1), str(int(n.group(1)) + 1)), 1)
    wr(p, s2)
    print(f"{p}: removed {removed}, changed {changed}, kurdish {kurd}, chains now {s2.count(NL + 'building ')}")
    for u in MOVED:
        left = [l for l in s2.split(NL) if f'"{u}"' in l and "requires" in l and "turkmen" not in l]
        bad = [l for l in left if re.search(r"factions\s*\{[^}]*\b(rum|turks|zengid)\b", l) and "not factions" not in l]
        print(f"  {u}: {len(bad)} old lines still name rum/turks/zengid")


# ---------------------------------------------------------------------------------------------- units
UNIT = """type             Turkmen Alps
dictionary       Turkmen_Alps      ; Turkmen Alps : tribal sword and shield warriors ({mark})
category         infantry
class            light
voice_type       Light
accent         Arabic
banner faction   main_infantry
banner holy      crusade
soldier          Turkmen_Alps, 48, 0, 1
officer          Seljuks_Captain
attributes       sea_faring, hide_forest, hardy, can_withdraw
move_speed_mod	 1.02
formation        1.2, 1.2, 2.4, 2.4, 3, square
stat_health      1, 2
stat_pri         7, 4, no, 0, 0, melee, melee_blade, piercing, sword, 25, 1
stat_pri_attr    no
stat_sec         0, 0, no, 0, 0, no, melee_simple, blunt, none, 0, 1
stat_sec_attr    no
stat_pri_armour  5, 5, 4, flesh
stat_sec_armour  0, 0, flesh
stat_heat        3
stat_ground      1, 1, 0, -1
stat_mental      9, normal, trained
stat_charge_dist 6
stat_fire_delay  0
stat_food        60, 300
stat_cost        2, 1900, 700, 65, 700, 700, 2, 200
armour_ug_levels 1, 2
armour_ug_models Turkmen_Alps, Turkmen_Alps_ug1
ownership        rum, turks, zengid, slave
era 0            rum, turks, zengid
era 1            rum, turks, zengid
recruit_priority_offset    0
""".replace("{mark}", MARK)


def units():
    for p in ("data/export_descr_unit.txt", "data XII/data/export_descr_unit.txt", "data XIII/data/export_descr_unit.txt"):
        s = rd(p)
        guard(s, p)
        if not s.endswith(NL):
            s += NL
        s += NL + UNIT.replace("\n", NL)
        wr(p, s)
        print(p, "unit added")


# ---------------------------------------------------------------------------------------------- model
def model_entry(name, quality):
    q = quality  # "light" / "medium"
    mesh = f"unit_models/_Units/turkoman/turkomans_eastern_{q}_shield_lod"
    tex = f"unit_models/_Units/turkoman/textures/turkoman_eastern_{q}_1.texture"
    nrm = f"unit_models/_Units/turkoman/textures/turkoman_eastern_{q}_normal_1.texture"
    spr = f"unit_sprites/turks_Turkish_Archers{'' if q == 'light' else '_ug1'}_sprite.spr"
    sd = "unit_models/_Units/turkoman/textures/turkoman_big_round_shield_diff.texture"
    sn = "unit_models/_Units/turkoman/textures/turkoman_big_round_shield_norm.texture"

    def L(x):
        return f"{len(x)} {x}"
    rows = [L(name), "1 3"]
    for i, dist in enumerate((121, 1225, 12000)):
        rows.append(f"{L(mesh + str(i) + '.mesh')} {dist}")
    rows += ["1", L("merc"), L(tex), L(nrm), L(spr), "1", L("merc"), L(sd), f"{L(sn)} 0",
             "1", L("None"), f"{L('MTW2_Swordsman')} 0", "2", L("MTW2_Sword_Primary"), f"{L('fs_test_shield')} 0",
             "16 -0.090000004 0 0 -0.34999999 0.80000001 0.60000002"]
    return "".join(r + " " + NL for r in rows)


def model():
    p = "data/unit_models/battle_models.modeldb"
    s = rd(p)
    if "turkmen_alps" in s:
        sys.exit(p + " already holds turkmen_alps - refusing")
    head, rest = s.split(NL, 1)
    parts = head.split(" ")
    # "22 serialization::archive 3 0 0 0 0 <count> 0 0 "
    cnt = int(parts[7])
    parts[7] = str(cnt + 2)
    new = model_entry("turkmen_alps", "light") + model_entry("turkmen_alps_ug1", "medium")
    # insert directly after the turkish_archers_ug1 entry = before the next entry header line ("16 ottoman_infantry")
    i = rest.find("15 turkish_archers_ug1 ")
    if i < 0:
        i = rest.find("19 turkish_archers_ug1 ")
    j = rest.find(NL + "16 ottoman_infantry ", i)
    assert i >= 0 and j > i, "anchor not found"
    rest = rest[:j + 2] + new + rest[j + 2:]
    wr(p, " ".join(parts) + NL + rest)
    print(p, f"models {cnt} -> {cnt + 2}")


# ---------------------------------------------------------------------------------------------- texts
def utf16_append(p, block):
    raw = open(os.path.join(ROOT, p), "rb").read()
    assert raw[:2] == b"\xff\xfe"
    s = raw[2:].decode("utf-16-le")
    guard(s, p)
    if not s.endswith(NL):
        s += NL
    s += block.replace("\n", NL)
    open(os.path.join(ROOT, p), "wb").write(b"\xff\xfe" + s.encode("utf-16-le"))
    print(p, "text added")


UNIT_TXT = f"""
¬ {MARK}
{{Turkmen_Alps}}Turkmen Alps
{{Turkmen_Alps_descr_short}}Turkmen tribal warriors with sword and round shield, raised from the nomad camps.
{{Turkmen_Alps_descr}}Quality: Good.\\nType: Tribal (raised from the Turkmen camps).\\n\\nAn alp was a hero among the Turkic peoples - a warrior who had proven himself in raids and feuds. The Turkmen clans that moved into Anatolia and Syria brought such men with them, fighting on foot with a curved sword and a light round shield when their horses could not be used. They are tough and dependable in melee, better than common militia, though without the armour of professional soldiers.\\n\\nRecruited only from the Turkmen Camp (level 2 and higher).
"""

BLD_TXT = f"""
¬ {MARK}
{{turkmen_camp_name}}Turkmen Camp

{{turkmen_oba}}Turkmen Oba
{{turkmen_oba_desc}}An oba is the camp of a Turkmen clan - tents, herds and horses on the pastures outside the settlement. Welcoming the nomads brings trade in horses, wool and meat, and new people settle with them, but the clans keep their own ways and quarrel with the townsfolk.\\n\\nRecruits Oghuz Horse Archers and Turcoman Javelinmen. Rum, the Seljuqs and the Zengids can raise these troops only from Turkmen camps.
{{turkmen_oba_desc_short}}A Turkmen clan camp: trade and growth, but more unrest. Recruits Oghuz Horse Archers and Turcoman Javelinmen.

{{turkmen_encampment}}Turkmen Encampment
{{turkmen_encampment_desc}}Several clans now graze their herds around the settlement, under a bey who answers to the sultan. Their horsemen and foot warriors are ready to ride out for plunder and pay, though the restless tribes make the settlement harder to govern.\\n\\nRecruits Oghuz Horse Archers, Turcoman Javelinmen, Turkmen Alps and Turkmen Cavalry.
{{turkmen_encampment_desc_short}}A large Turkmen encampment: more trade and growth, more unrest. Adds Turkmen Alps and Turkmen Cavalry.

{{turkmen_beylik}}Beylik Camp
{{turkmen_beylik_desc}}The seat of a Turkmen beylik - a great camp where many clans gather under their bey. It is a rich source of horses, trade and warriors, and the tribes' independence makes it a constant source of trouble for the governor.\\n\\nRecruits Oghuz Horse Archers, Turcoman Javelinmen, Turkmen Alps and Turkmen Cavalry in greater numbers.
{{turkmen_beylik_desc_short}}The camp of a Turkmen beylik: the most trade, growth and warriors - and the most unrest.
"""


# ---------------------------------------------------------------------------------------------- descr_strat
def strat():
    p = "data/world/maps/campaign/imperial_campaign/descr_strat.txt"
    s = rd(p)
    guard(s, p)
    lines = s.split(NL)
    out, fac, n, pending = [], None, 0, False
    for ln in lines:
        m = re.match(r"faction\s+(\w+),", ln)
        if m:
            fac = m.group(1)
        if ln.strip() == "settlement" or ln.strip().startswith("settlement castle"):
            pending = fac in ("rum", "turks")
        if pending and ln.strip() == "building":
            out += ["\tbuilding", "\t{", f"\t\ttype turkmen_camp turkmen_oba\t; {MARK}", "\t}"]
            n += 1
            pending = False
        out.append(ln)
    wr(p, NL.join(out))
    print(p, f"camp added to {n} settlements")


if __name__ == "__main__":
    buildings()
    units()
    model()
    utf16_append("data/text/export_units.txt", UNIT_TXT)
    utf16_append("data/text/export_buildings.txt", BLD_TXT)
    strat()
