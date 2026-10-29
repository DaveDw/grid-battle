"""Terran card icons: drawn on 32px grid, six colours plus outline."""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw,ImageFont

OUT=Path(__file__).resolve().parent
PAL={'o':'#e8742a','h':'#ffb65c','s':'#a74724','g':'#66717d','l':'#c4ced3','d':'#39414e','k':'#14161f'}

def canvas():
    im=Image.new('RGBA',(32,32));return im,ImageDraw.Draw(im)
def rect(d,b,c):d.rectangle(b,fill=PAL[c])
def poly(d,pts,c):d.polygon(pts,fill=PAL[c])
def line(d,pts,c,width=1):d.line(pts,fill=PAL[c],width=width)
def tile(d,x,y,w=19):
    poly(d,[(x,y+3),(x+w//2,y),(x+w,y+3),(x+w,y+6),(x+w//2,y+9),(x,y+6)],'d')
    poly(d,[(x,y+3),(x+w//2,y),(x+w,y+3),(x+w//2,y+6)],'g')
    line(d,[(x,y+3),(x+w//2,y),(x+w,y+3)],'l')
def flag(d,x,y):
    rect(d,(x,y,x+1,y+18),'l');rect(d,(x+1,y+1,x+1,y+18),'g')
    poly(d,[(x+2,y+1),(x+12,y+1),(x+9,y+5),(x+12,y+9),(x+2,y+9)],'o')
    line(d,[(x+2,y+1),(x+12,y+1)],'h');rect(d,(x+2,y+8,x+10,y+9),'s')
def shield(d,x,y,w=14,h=19,orange=True):
    poly(d,[(x,y),(x+w,y),(x+w,y+h-7),(x+w-3,y+h-3),(x+w//2,y+h),(x+3,y+h-3),(x,y+h-7)],'o' if orange else 'g')
    line(d,[(x,y+h-8),(x,y),(x+w-1,y)],'h' if orange else 'l')
    poly(d,[(x+w-3,y+2),(x+w,y+2),(x+w,y+h-7),(x+w-3,y+h-3),(x+w//2,y+h),(x+w//2,y+h-3),(x+w-3,y+h-7)],'s' if orange else 'd')
def crate(d,x,y,w=16,h=12):
    rect(d,(x,y,x+w,y+h),'g');rect(d,(x,y,x+w,y+2),'l');rect(d,(x+w-2,y+3,x+w,y+h),'d')
    rect(d,(x+2,y+3,x+4,y+h-1),'o');rect(d,(x+w-5,y+3,x+w-3,y+h-1),'o')
    line(d,[(x+1,y+h),(x+w,y+h)],'d')

def draw(name):
    im,d=canvas()
    if name=='fortify':
        tile(d,5,19,21);shield(d,9,5,14,19)
        poly(d,[(13,9),(18,9),(18,16),(15,19),(13,16)],'l')
        rect(d,(14,11,14,12),'g')
    elif name=='claim':
        for y in (18,13,8):tile(d,5,y,15)
        flag(d,13,3)
    elif name=='stake_claim':
        tile(d,5,19,21);flag(d,11,4)
    elif name=='sandbags':
        for x,y,w in [(4,20,10),(16,20,11),(5,14,9),(16,14,10),(9,8,13)]:
            poly(d,[(x+1,y),(x+w-1,y),(x+w,y+2),(x+w,y+4),(x+w-1,y+5),(x+1,y+5),(x,y+4),(x,y+1)],'o')
            line(d,[(x+2,y),(x+w-2,y)],'h');line(d,[(x+1,y+4),(x+w-1,y+4)],'s')
            line(d,[(x+w-1,y+1),(x+w-1,y+3)],'s')
            line(d,[(x+1,y+1),(x+2,y+2)],'d')
    elif name=='barrage':
        for x,y in ((6,8),(14,15),(22,8)):
            poly(d,[(x,y),(x+4,y),(x+4,y+8),(x+2,y+10),(x,y+8)],'o')
            rect(d,(x,y+1,x+1,y+6),'h');poly(d,[(x,y+7),(x+4,y+7),(x+4,y+8),(x+2,y+10),(x,y+8)],'g')
            rect(d,(x-1,y-1,x+5,y),'d');rect(d,(x+1,y-5,x+2,y-3),'l')
    elif name=='hold_the_line':
        shield(d,4,9,7,16,False);shield(d,21,9,7,16,False)
        line(d,[(12,9),(12,24)],'k');line(d,[(20,9),(20,24)],'k')
        shield(d,11,6,10,21,True)
        poly(d,[(13,14),(16,11),(19,14),(19,17),(16,14),(13,17)],'l')
    elif name=='requisition':
        crate(d,6,13,20,14)
        poly(d,[(12,17),(16,13),(20,17),(18,17),(18,23),(14,23),(14,17)],'h')
        poly(d,[(9,10),(9,5),(18,5),(18,3),(23,7),(18,11),(18,9),(12,9),(12,10)],'o')
        line(d,[(10,5),(17,5)],'h')
    elif name=='suppressing_fire':
        for x,y in ((10,7),(14,14),(8,21)):
            rect(d,(x,y,x+11,y+3),'g');poly(d,[(x+11,y),(x+14,y+1),(x+14,y+2),(x+11,y+3)],'o')
            line(d,[(x+1,y),(x+10,y)],'l');rect(d,(x-5,y+1,x-1,y+2),'o');rect(d,(x-5,y+1,x-4,y+1),'h')
            rect(d,(x,y+1,x+1,y+2),'d')
    elif name=='supply_drop':
        line(d,[(5,13),(11,23)],'l');line(d,[(26,13),(21,23)],'g');line(d,[(15,12),(16,22)],'l')
        poly(d,[(4,12),(6,7),(10,4),(14,3),(18,3),(23,6),(26,10),(27,13),(21,11),(16,13),(10,11),(4,13)],'o')
        poly(d,[(14,3),(17,3),(20,8),(21,11),(16,13),(11,11),(12,6)],'h')
        line(d,[(24,8),(26,12),(22,11)],'s');crate(d,10,22,12,6)
    elif name=='dig_in':
        poly(d,[(5,25),(8,22),(11,24),(15,22),(18,24),(23,22),(27,25),(27,28),(5,28)],'g')
        rect(d,(7,26,25,28),'d');rect(d,(8,23,10,24),'l')
        poly(d,[(18,6),(21,8),(14,22),(11,20)],'o');line(d,[(18,7),(12,20)],'h')
        poly(d,[(9,17),(16,21),(14,26),(10,27),(7,24)],'g');line(d,[(9,18),(7,23),(10,25)],'l')
        poly(d,[(18,3),(25,7),(22,12),(18,10),(15,7)],'l')
        poly(d,[(19,5),(22,7),(20,9),(18,7)],'k')
    # One source pixel of dark outline, with no anti-aliasing.
    a=np.array(im);mask=a[:,:,3]>0;outline=np.zeros(mask.shape,bool)
    for dy,dx in ((-1,0),(1,0),(0,-1),(0,1)):
        shifted=np.zeros_like(mask);shifted[max(0,dy):min(32,32+dy),max(0,dx):min(32,32+dx)]=mask[max(0,-dy):min(32,32-dy),max(0,-dx):min(32,32-dx)];outline|=shifted
    a[outline&~mask]=[20,22,31,255]
    return Image.fromarray(a)

NAMES=['fortify','claim','stake_claim','sandbags','barrage','hold_the_line','requisition','suppressing_fire','supply_drop','dig_in']
def main():
    native=OUT/'source_32';native.mkdir(exist_ok=True);report={}
    sheet=Image.new('RGB',(1000,460),'#222832');sd=ImageDraw.Draw(sheet)
    for i,name in enumerate(NAMES):
        im=draw(name);a=np.array(im);im.save(native/(name+'.png'))
        large=im.resize((128,128),Image.Resampling.NEAREST);large.save(OUT/(name+'.png'))
        unique=np.unique(a[a[:,:,3]>0],axis=0);assert 5<=len(unique)<=7,(name,len(unique))
        decoded=np.array(Image.open(OUT/(name+'.png')))
        assert np.array_equal(decoded,np.repeat(np.repeat(a,4,axis=0),4,axis=1))
        assert set(np.unique(a[:,:,3]))=={0,255}
        x=(i%5)*200;y=(i//5)*230
        for xx,yy,size in ((x+34,y+12,128),(x+82,y+153,32)):
            for cy in range(0,size,8):
                for cx in range(0,size,8):sd.rectangle((xx+cx,yy+cy,xx+cx+7,yy+cy+7),fill='#303946' if (cy//8+cx//8)%2 else '#384351')
        sheet.paste(large,(x+34,y+12),large);sheet.paste(im,(x+82,y+153),im)
        sd.text((x+100,y+204),name,fill='#ebedf0',anchor='mm')
        report[name]={'size':[128,128],'native_size':[32,32],'opaque_colours_including_outline':len(unique),'bbox':im.getbbox(),'exact_4x_blocks':True,'transparent':True}
    sheet.save(OUT/'review_terran.png');(OUT/'terran_checks.json').write_text(json.dumps(report,indent=2)+'\n')
    print('10 Terran cards: palette, alpha and exact nearest-neighbour block checks passed')
if __name__=='__main__':main()
