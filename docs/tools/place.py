import numpy as np
from PIL import Image
B='/home/claude/modding_sship/data/world/maps/base/'
reg=Image.open(B+'map_regions.tga').convert('RGB'); W,H=reg.size; rp=reg.load()
gr=Image.open(B+'map_ground_types.tga').convert('RGB'); gp=gr.load()
hm=np.array(Image.open(B+'map_heights.tga').convert('L')).astype(int)
fe=Image.open(B+'map_features.tga').convert('RGB'); fp=fe.load()
GH=gr.size[1]
setts={}
for l in open(__import__('os').path.join(__import__('os').path.dirname(__file__),'all_setts.txt')):
    x,y,r,s,o=l.split(); setts[s]=(int(x),int(y),r,o)
anchors={'Constantinople':(41.008,28.978),'Adrianople':(41.677,26.556),'Thessalonica':(40.640,22.944),
'Sredets':(42.698,23.322),'Tarnovo':(43.081,25.629),'Ras':(43.14,20.52),'Skadar':(42.068,19.512),
'Durazzo':(41.323,19.441),'Arta':(39.160,20.985),'Corinth':(37.906,22.879),'Ragusa':(42.650,18.094),'Vrhbosna':(43.856,18.413),
'Chandax':(35.339,25.144),'Nicaea':(40.429,29.721),'Smyrna':(38.42,27.14)}
import sys
if '-a' in sys.argv:  # optional anchor file: "settlement lat lon" per line (default: Balkan anchors above)
    anchors={}
    for l in open(sys.argv[sys.argv.index('-a')+1]):
        if l.strip(): n,la,lo=l.split(); anchors[n]=(float(la),float(lo))
A=[];X=[];Y=[]
for s,(la,lo) in anchors.items():
    x,y,_,_=setts[s]; A.append([lo,la,1]); X.append(x); Y.append(y)
A=np.array(A); cx=np.linalg.lstsq(A,X,rcond=None)[0]; cy=np.linalg.lstsq(A,Y,rcond=None)[0]
res={s:(X[i]-A[i]@cx, Y[i]-A[i]@cy) for i,s in enumerate(anchors)}
import sys
if '-r' in sys.argv:
    for s,r in res.items(): print(s, round(r[0],1), round(r[1],1))
def gps2tile(la,lo):
    x=np.array([lo,la,1])@cx; y=np.array([lo,la,1])@cy
    ws=0;dx=0;dy=0
    for i,s in enumerate(anchors):
        d=((A[i][0]-lo)**2+(A[i][1]-la)**2)**0.5+0.05; w=1/d**2; ws+=w; dx+=w*res[s][0]; dy+=w*res[s][1]
    return x+dx/ws, y+dy/ws
GNAME={(96,160,64):'fert',(101,124,0):'fert',(0,128,128):'fert',(128,128,64):'hills',(0,128,0):'wood',(0,0,0):'wild',
(0,64,0):'DENSE',(98,65,65):'LOWMT',(196,128,128):'HIGHMT',(0,255,128):'SWAMP',(255,255,255):'BEACH',(64,64,64):'IMP'}
def ground(x,y):
    return GNAME.get(gp[2*x+1,GH-1-(2*y+1)],'SEA')
def relief(x,y):
    r0=GH-1-(2*y+2); b=hm[r0:r0+3,2*x:2*x+3]; return int(b.max()-b.min())
def river(x,y):
    return fp[x,H-1-y][2]==255 and fp[x,H-1-y][0]==0
def regionof(x,y):
    return rp[x,H-1-y]
colreg={}
for s,(x,y,r,o) in setts.items():
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
        c=rp[x+dx,H-1-y-dy]
        if c!=(0,0,0) and c!=(255,255,255): colreg[c]=(r,s,o); break
def ok(x,y):
    if ground(x,y) not in ('fert','hills','wood','wild'): return False
    if river(x,y) or relief(x,y)>30: return False
    if rp[x,H-1-y] in ((0,0,0),(255,255,255)) or rp[x,H-1-y] not in colreg: return False
    if min(max(abs(x-sx),abs(y-sy)) for sx,sy,_,_ in setts.values())<3: return False
    n=sum(1 for dx in (-1,0,1) for dy in (-1,0,1) if (dx or dy) and ground(x+dx,y+dy) in ('fert','hills','wood','wild'))
    return n>=7
def place(name,la,lo):
    fx,fy=gps2tile(la,lo); x0,y0=int(round(fx)),int(round(fy))
    best=None
    for d in range(0,6):
        for x in range(x0-d,x0+d+1):
            for y in range(y0-d,y0+d+1):
                if max(abs(x-x0),abs(y-y0))==d and ok(x,y):
                    dd=(x-fx)**2+(y-fy)**2
                    if best is None or dd<best[0]: best=(dd,x,y)
        if best: break
    r=colreg.get(rp[x0,H-1-y0],('?','?','?'))
    if not best: return f"{name:14s} GPS {x0},{y0} {ground(x0,y0)} region {r[1]} -> NO OPEN TILE"
    _,x,y=best; r=colreg[rp[x,H-1-y]]
    return f"{name:14s} GPS {x0},{y0} {ground(x0,y0):6s} -> {x},{y} {ground(x,y):5s} rel {relief(x,y):2d} region {r[1]} ({r[2]})"
if __name__=='__main__':
    for l in open([a for i,a in enumerate(sys.argv[1:],1) if a not in ('-r','-a') and sys.argv[i-1]!='-a'][0]):
        n,la,lo=l.split(); print(place(n,float(la),float(lo)))
