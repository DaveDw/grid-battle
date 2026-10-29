"""Ascendancy icons, matching the approved Terran pixel-grid style."""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw
import build_terran as t

OUT=Path(__file__).resolve().parent
t.PAL={'o':'#38d6e8','h':'#a6f5fa','s':'#218799','g':'#7d8b9b','l':'#e5edf1','d':'#3c495d','k':'#14161f'}
rect,poly,line=t.rect,t.poly,t.line
NAMES=['deploy_drone','issue_protocol','overclock','containment','target_lock','shield_drone','recompile','firewall','data_breach']

def drone(d,x,y,gun=False):
    rect(d,(x-4,y+5,x+1,y+8),'d');rect(d,(x-4,y+5,x-2,y+6),'o')
    poly(d,[(x+3,y),(x+10,y),(x+14,y+4),(x+14,y+10),(x+10,y+14),(x+3,y+14),(x,y+10),(x,y+4)],'g')
    poly(d,[(x+3,y),(x+10,y),(x+12,y+3),(x+12,y+8),(x+8,y+12),(x+2,y+10),(x,y+6),(x,y+4)],'l')
    poly(d,[(x+5,y+3),(x+9,y+3),(x+11,y+5),(x+11,y+9),(x+9,y+11),(x+5,y+11),(x+3,y+9),(x+3,y+5)],'d')
    rect(d,(x+5,y+5,x+9,y+8),'o');rect(d,(x+5,y+4,x+7,y+5),'h');rect(d,(x+6,y+9,x+8,y+9),'s')
    rect(d,(x+4,y+15,x+8,y+16),'d');rect(d,(x+5,y+16,x+7,y+17),'o')
    if gun:
        rect(d,(x+12,y+8,x+19,y+10),'d');rect(d,(x+14,y+8,x+18,y+8),'g');rect(d,(x+18,y+9,x+19,y+10),'o')

def hexagon(d,x,y,w=8,h=9):
    poly(d,[(x+w//2,y),(x+w,y+2),(x+w,y+h-2),(x+w//2,y+h),(x,y+h-2),(x,y+2)],'s')
    poly(d,[(x+w//2,y+1),(x+w-1,y+3),(x+w-1,y+h-3),(x+w//2,y+h-1),(x+1,y+h-3),(x+1,y+3)],'d')
    line(d,[(x,y+5),(x,y+2),(x+w//2,y),(x+w-1,y+2)],'o')
    rect(d,(x+1,y+2,x+2,y+2),'h')

def draw(name):
    im,d=t.canvas()
    if name=='deploy_drone':
        drone(d,8,8,True)
        rect(d,(12,5,13,7),'g');rect(d,(11,4,14,4),'o')
    elif name=='issue_protocol':
        poly(d,[(7,4),(20,4),(25,9),(25,27),(7,27)],'g')
        poly(d,[(7,4),(19,4),(19,10),(23,10),(23,25),(7,25)],'l')
        poly(d,[(20,4),(25,9),(20,9)],'o');line(d,[(20,10),(24,10)],'d')
        poly(d,[(10,16),(16,11),(21,16),(21,20),(16,15),(10,20)],'o')
        line(d,[(11,19),(16,15),(20,19)],'s');rect(d,(11,23,20,24),'d')
    elif name=='overclock':
        poly(d,[(4,13),(7,7),(12,4),(20,4),(25,8),(28,14),(28,23),(24,27),(8,27),(4,23)],'g')
        poly(d,[(6,13),(9,8),(13,6),(19,6),(24,10),(26,15),(26,23),(23,25),(9,25),(6,22)],'d')
        line(d,[(6,13),(9,8),(13,6),(19,6)],'l',2)
        d.polygon([(21,7),(25,10),(27,15),(23,15),(21,11)],fill='#e8742a')
        rect(d,(9,13,10,15),'g');rect(d,(14,9,15,11),'g')
        poly(d,[(14,20),(23,11),(19,22),(16,23)],'o');rect(d,(14,21,17,23),'l')
    elif name=='containment':
        poly(d,[(16,4),(26,10),(26,23),(16,28),(6,23),(6,10)],'s')
        poly(d,[(16,7),(23,11),(23,21),(16,25),(9,21),(9,11)],'d')
        line(d,[(6,22),(6,10),(16,4),(26,10)],'o',2)
        line(d,[(7,11),(16,16),(25,11)],'h')
        for x,top,bot in ((11,9,23),(16,6,26),(21,9,23)):
            rect(d,(x,top,x+1,bot),'o');line(d,[(x,top),(x,bot-1)],'h')
        rect(d,(5,21,8,23),'g');rect(d,(24,21,27,23),'g');rect(d,(14,26,18,28),'l')
    elif name=='target_lock':
        for pts in [[(5,12),(5,5),(12,5)],[(20,5),(27,5),(27,12)],[(27,20),(27,27),(20,27)],[(12,27),(5,27),(5,20)]]:line(d,pts,'g',2)
        line(d,[(5,11),(5,5),(11,5)],'l')
        poly(d,[(15,10),(21,15),(21,17),(16,22),(10,17),(10,15)],'s')
        poly(d,[(15,12),(19,16),(16,20),(12,16)],'o');rect(d,(15,15,17,17),'h')
        for box in ((15,4,16,9),(23,15,28,16),(15,23,16,28),(4,15,9,16)):rect(d,box,'o')
    elif name=='shield_drone':
        poly(d,[(5,5),(15,3),(26,5),(26,17),(23,23),(16,28),(8,23),(5,17)],'s')
        poly(d,[(7,7),(15,5),(24,7),(24,16),(21,21),(16,25),(10,21),(7,16)],'d')
        line(d,[(5,17),(5,5),(15,3),(25,5)],'o');line(d,[(6,6),(14,4)],'h')
        drone(d,10,8,False)
    elif name=='recompile':
        rect(d,(12,8,24,24),'g');rect(d,(9,11,21,26),'d');rect(d,(6,14,18,28),'l')
        rect(d,(8,17,15,18),'g');rect(d,(8,21,13,22),'o')
        poly(d,[(5,10),(5,7),(9,3),(20,3),(25,7),(25,12),(22,12),(22,8),(19,6),(10,6),(8,8),(8,10)],'o')
        poly(d,[(19,10),(27,10),(23,15)],'o');line(d,[(8,5),(10,3),(19,3)],'h')
        line(d,[(24,7),(24,10)],'s')
    elif name=='firewall':
        rect(d,(4,25,28,27),'g');rect(d,(5,25,27,25),'l');rect(d,(7,27,25,28),'d')
        for x,y in ((5,6),(15,6),(10,15),(20,15)):
            hexagon(d,x,y,8,9)
        rect(d,(4,23,6,24),'o');rect(d,(26,23,28,24),'o')
    elif name=='data_breach':
        poly(d,[(8,16),(8,8),(12,4),(19,4),(23,8),(23,11),(20,11),(20,9),(18,7),(13,7),(11,9),(11,16)],'g')
        line(d,[(8,14),(8,8),(12,4),(18,4)],'l')
        rect(d,(21,13,23,16),'g')
        rect(d,(6,16,25,27),'s');rect(d,(6,16,23,25),'o');line(d,[(7,16),(23,16)],'h')
        poly(d,[(17,16),(14,20),(18,21),(14,27),(18,27),(21,21),(17,19),(20,16)],'k')
        line(d,[(25,8),(27,6)],'o');rect(d,(26,12,28,12),'h')
    a=np.array(im);mask=a[:,:,3]>0;outline=np.zeros(mask.shape,bool)
    for dy,dx in ((-1,0),(1,0),(0,-1),(0,1)):
        shifted=np.zeros_like(mask);shifted[max(0,dy):min(32,32+dy),max(0,dx):min(32,32+dx)]=mask[max(0,-dy):min(32,32-dy),max(0,-dx):min(32,32-dx)];outline|=shifted
    a[outline&~mask]=[20,22,31,255]
    return Image.fromarray(a)

def main():
    native=OUT/'source_32';native.mkdir(exist_ok=True);report={}
    sheet=Image.new('RGB',(600,690),'#222832');sd=ImageDraw.Draw(sheet)
    for i,name in enumerate(NAMES):
        im=draw(name);a=np.array(im);unique=np.unique(a[a[:,:,3]>0],axis=0)
        assert 5<=len(unique)<=7,(name,len(unique))
        assert set(np.unique(a[:,:,3]))=={0,255}
        assert not (a[0,:,3].any() or a[-1,:,3].any() or a[:,0,3].any() or a[:,-1,3].any()),name
        im.save(native/(name+'.png'));large=im.resize((128,128),Image.Resampling.NEAREST);large.save(OUT/(name+'.png'))
        decoded=np.array(Image.open(OUT/(name+'.png')));assert np.array_equal(decoded,np.repeat(np.repeat(a,4,axis=0),4,axis=1))
        x=(i%3)*200;y=(i//3)*230
        for xx,yy,size in ((x+34,y+12,128),(x+82,y+153,32)):
            for cy in range(0,size,8):
                for cx in range(0,size,8):sd.rectangle((xx+cx,yy+cy,xx+cx+7,yy+cy+7),fill='#303946' if (cy//8+cx//8)%2 else '#384351')
        sheet.paste(large,(x+34,y+12),large);sheet.paste(im,(x+82,y+153),im);sd.text((x+100,y+204),name,fill='#ebedf0',anchor='mm')
        report[name]={'size':[128,128],'native_size':[32,32],'opaque_colours_including_outline':len(unique),'bbox':im.getbbox(),'exact_4x_blocks':True,'transparent':True}
    sheet.save(OUT/'review_ascendancy.png');(OUT/'ascendancy_checks.json').write_text(json.dumps(report,indent=2)+'\n')
    print('9 Ascendancy cards: palette, margins, transparency and exact 4x block checks passed')
if __name__=='__main__':main()
