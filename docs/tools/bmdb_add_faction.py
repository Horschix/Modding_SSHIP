# bmdb_add_faction.py (Modding_SSHIP, 15 Oct 2026): give battle model entries texture lines for more factions.
# usage: python3 bmdb_add_faction.py IN OUT spec.txt   (spec lines: "<model> <newfaction> <donorfaction>")
# Copies the donor's main-texture record (faction, texture, normal[, sprite]) and attachment record under the new faction name and raises both counts. Entry count of the file is unchanged.
import re,sys
src,dst,spec=sys.argv[1:4]
d=open(src,'rb').read().decode('latin-1')
L=d.split('\r\n')
heads={}
for i in range(len(L)-1):
    m=re.match(r'^(\d+) (\S+) $',L[i]); n=re.match(r'^[\d.\-]+ (\d+) $',L[i+1])
    if m and n and int(m.group(1))==len(m.group(2)): heads.setdefault(m.group(2).lower(),i)
def tok(line): return re.match(r'^\d+ (\S+)',line).group(1)
jobs={}
for l in open(spec):
    if l.strip(): mo,f,donor=l.split(); jobs.setdefault(mo.lower(),[]).append((f,donor))
inserts=[]  # (line index, new lines) and count changes
def recs(start,count):
    # a record = faction line, texture line, normal line [+ sprite line]; the sprite is inline as " 0" when empty
    out=[];k=start
    for _ in range(count):
        n=3 if re.match(r'^\d+ \S.* 0 $',L[k+2]) else 4
        out.append(L[k:k+n]); k+=n
    return out,k
for mo,lst in jobs.items():
    i=heads[mo]; nl=int(re.match(r'^[\d.\-]+ (\d+) $',L[i+1]).group(1)); p=i+2+nl
    cnt=int(L[p].strip()); main,q=recs(p+1,cnt)
    acnt=int(L[q].strip()); att,qe=recs(q+1,acnt)
    have={tok(r[0]) for r in main}
    addm=[];adda=[]
    for f,donor in lst:
        if f in have: continue
        dm=[r for r in main if tok(r[0])==donor] or [main[0]]
        da=[r for r in att if tok(r[0])==donor] or att[:1]
        fl=f"{len(f)} {f} "
        addm.append([fl]+dm[0][1:])
        if da: adda.append([fl]+da[0][1:])
        have.add(f); print(mo,'+',f,'from',tok(dm[0][0]),'att' if da else 'no-att')
    if addm: inserts.append((p,cnt+len(addm),q,addm,q,acnt+len(adda),qe,adda))
for p,nc,pe,addm,q,na,qe,adda in sorted(inserts,reverse=True):
    L[qe:qe]=[x for r in adda for x in r]; L[q]=f"{na} "
    L[pe:pe]=[x for r in addm for x in r]; L[p]=f"{nc} "
open(dst,'wb').write('\r\n'.join(L).encode('latin-1'))
