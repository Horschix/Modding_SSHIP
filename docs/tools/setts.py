import re,sys
from PIL import Image
R='/mnt/user-data/uploads/mods/sship/data/world/maps/base/descr_regions.txt'
lines=[l.split(';')[0].rstrip() for l in open(R,encoding='latin-1')]
lines=[l for l in lines if l.strip()]
regs={}
i=0
while i<len(lines):
    if not lines[i].startswith((' ','\t')):
        name=lines[i].strip(); sett=lines[i+1].strip(); col=tuple(int(c) for c in lines[i+5].split()) if False else None
        # find the colour line: 3 ints
        j=i+1; vals=[]
        while j<len(lines) and lines[j].startswith((' ','\t')):
            vals.append(lines[j].strip()); j+=1
        c=[v for v in vals if re.fullmatch(r'\d+\s+\d+\s+\d+',v)]
        regs[tuple(map(int,c[0].split()))]=(name,vals[0])
        i=j
    else: i+=1
im=Image.open('/home/claude/modding_sship/data/world/maps/base/map_regions.tga').convert('RGB')
W,H=im.size; px=im.load()
own={}
cur=None
for l in open('/home/claude/modding_sship/data/world/maps/campaign/imperial_campaign/descr_strat.txt',encoding='latin-1'):
    m=re.match(r'\s*faction\s+(\w+)',l)
    if m: cur=m.group(1)
    m=re.match(r'\s*region\s+(\w+)',l)
    if m: own[m.group(1)]=cur
for y in range(H):
    for x in range(W):
        if px[x,y]==(0,0,0):
            # region from neighbours
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                c=px[x+dx,y+dy]
                if c in regs: break
            rn,sn=regs.get(c,('?','?'))
            print(x,H-1-y,rn,sn,own.get(rn,'?'))
