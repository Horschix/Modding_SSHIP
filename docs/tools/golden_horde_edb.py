# golden_horde_edb.py (Modding_SSHIP, 15 Oct 2026) - building-file changes for the Golden Horde / Ilkhanate feature.
# usage: python3 golden_horde_edb.py IN OUT
#  A) every Mongol-only recruit line (factions { mongols, }, except the dhow) gets copies for the Cumans after the
#     Golden Horde event: "factions { cumans, } and event_counter golden_horde 1 and <rest>". A line with " or " is split
#     into one copy per or-part (safe whether the engine reads and-before-or or left to right).
#  B) Muslim units for both steppe factions after their conversion: copies of one donor faction's lines with
#     "factions { F, } and event_counter <F>_islam 1" (mongols_islam / cumans_islam). Muslim Settlers only for the
#     Cumans (player-only unit; the Mongols are AI-only).
#  C) mosques: "factions { cumans, } and event_counter cumans_islam 1 or " in front; Tengri: Cumans only while pagan.
import re,sys
src,dst=sys.argv[1:3]
L=open(src,encoding='latin-1',newline='').read().split('\r\n')
MARK='golden_horde 1'
assert not any(MARK in l for l in L), 'already applied'
rx=re.compile(r'^(\s*recruit_pool\s+"([^"]+)"\s+[\d.]+\s+[\d.]+\s+[\d.]+\s+[\d.]+\s+requires\s+)(.*?)\s*$')
DONORS={  # unit -> (donor faction-clause regex, targets)
 'Mutatawwi Warriors': (r'factions \{ turks, rum, abbasid, moors, zengid, egypt, \}', ['mongols','cumans']),
 'Ahdath Militia':     (r'factions \{ abbasid, zengid, \}', ['mongols','cumans']),
 'Naffatun':           (r'factions \{ egypt, zengid, rum, turks, abbasid, \}', ['mongols','cumans']),
 'Ghulams':            (r'factions \{ (turks, rum|rum, turks), \}', ['mongols','cumans']),
 'Dismounted Ghulams': (r'factions \{ (turks, rum|rum, turks), \}', ['mongols','cumans']),
 'Muslim Settlers':    (r'factions \{ turks, \} and event_counter hx_player_turks 1', ['cumans']),
}
out=[];stats={'A':0,'B':0,'C':0}
for l in L:
    out.append(l)
    m=rx.match(l)
    if m:
        head,unit,req=m.groups()
        if req.startswith('factions { mongols, }') and unit!='dhow':
            parts=req.split(' or ')
            first=parts[0][len('factions { mongols, }'):].strip()
            rests=[first[4:] if first.startswith('and ') else first]+parts[1:]
            for r in rests:
                assert 'factions' not in r, l
                out.append(head+'factions { cumans, } and event_counter golden_horde 1'+(' and '+r if r else '')); stats['A']+=1
        elif unit in DONORS:
            drx,targets=DONORS[unit]
            if re.match(drx,req):
                assert ' or ' not in req, l
                for f in targets:
                    if unit=='Muslim Settlers':
                        new='factions { cumans, } and event_counter cumans_islam 1 and event_counter hx_player_cumans 1'
                    else:
                        new=re.sub('^'+drx,'factions { %s, } and event_counter %s_islam 1'%(f,f),req)
                    out.append(head+new); stats['B']+=1
    # C) mosques and Tengri temples (level requirement lines)
    if re.match(r'^\s{4}\S+ (city|castle) requires factions \{ mongols, \} and event_counter mongols_islam 1 or ',l):
        out[-1]=l.replace('requires factions { mongols, }','requires factions { cumans, } and event_counter cumans_islam 1 or factions { mongols, }',1); stats['C']+=1
    elif 'or factions { cumans, } and hidden_resource tartars' in l and 'requires' in l:
        out[-1]=l.replace('or factions { cumans, } and hidden_resource tartars','or factions { cumans, } and not event_counter cumans_islam 1 and hidden_resource tartars'); stats['C']+=1
open(dst,'w',encoding='latin-1',newline='').write('\r\n'.join(out))
print(stats)
