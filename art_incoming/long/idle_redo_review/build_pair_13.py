"""Cinder Scout / Captain Everafter: native base pixels and integer cut-outs."""
from pathlib import Path
import argparse
import hashlib
import json
import sys
import numpy as np
from PIL import Image, ImageDraw

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
sys.path.insert(0,str(ROOT/"art_incoming/ascendancy/idle_redo_review"))
from build_pair_07 import shift, poly, rect, stamp, backing, count_diff, matte

OFFSETS={"cinder_scout":(170,2),"captain_everafter":(231,2)}
BREATH=[0,1,1,2,2,1,1,0]


def geometry(a,name):
    ox,oy=OFFSETS[name];ink=a[:,:,3]>0;shape=ink.shape
    yy,xx=np.indices(shape);x,y=xx-ox,yy-oy
    def polygon(points):return ink&poly(shape,[(px+ox,py+oy) for px,py in points])
    def box(x0,y0,x1,y1):return ink&rect(shape,x0+ox,y0+oy,x1+ox,y1+oy)
    return ink,x,y,polygon,box


def scout_masks(a):
    ink,x,y,P,R=geometry(a,"cinder_scout")
    knife=P([(51,173),(61,165),(75,165),(79,174),(87,178),(98,183),
        (108,189),(118,194),(126,200),(134,205),(139,210),(141,217),
        (118,218),(111,215),(102,214),(98,211),(88,210),(84,207),
        (76,205),(69,202),(62,200),(54,199),(49,192)])
    # The warm orange triangle below the blade belongs to the fixed thigh.
    # Do not include it even where the dark knife outline touches the cloth.
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    orange=(r>75)&(r>g*1.6)&(g>b*1.8)&(b<60)
    knife &= ~(orange&(y>=195)&(x<113))
    left_arm=P([(0,121),(62,121),(70,148),(68,158),(80,165),(77,174),
        (69,182),(65,195),(59,199),(51,197),(48,190),(42,190),
        (40,185),(29,187),(20,182),(12,176),(0,177)])
    left_arm &= ~(orange&(y>=195))
    right_arm=P([(173,114),(202,122),(214,131),(235,130),(264,139),
        (264,158),(255,166),(244,173),(228,174),(215,169),(202,171),
        (191,167),(184,156),(181,144)])
    belt=P([(59,142),(145,139),(147,151),(144,161),(137,166),
        (127,168),(120,165),(105,168),(94,165),(75,164),(64,162)])
    # Native fire/ember pixels only. The irregular lower boundary follows
    # the flame above the rigid glove, not the cream-and-gold fingers.
    fire=P([(210,73),(275,73),(275,139),(266,147),(259,146),
        (258,139),(251,137),(248,140),(243,140),(240,137),(236,140),
        (229,141),(224,145),(218,147),(215,151),(210,149),(208,143),
        (204,141),(208,129),(208,108)])
    embers=R(214,30,270,73)
    body=((ink&(y<154))|left_arm|right_arm|belt|knife)&~fire&~embers
    legs=ink&~body&~fire&~embers
    thigh=P([(49,211),(67,205),(81,210),(92,214),(102,220),(103,239),
        (91,260),(78,266),(53,259),(27,250),(25,238)])&legs
    right_knee=P([(174,193),(198,191),(212,205),(214,222),(204,233),
        (184,235),(168,226),(164,209)])&legs
    helmet=P([(106,0),(204,0),(208,86),(192,110),(141,108),
        (114,87),(102,55)])&body
    glass=P([(144,23),(169,17),(188,29),(195,43),(194,76),
        (182,86),(161,86),(146,74),(137,54),(139,36)])&helmet
    return {"body":body,"legs":legs,"knife":knife&body,
        "left_arm":left_arm&body,"right_arm":right_arm&body,
        "fire":fire,"embers":embers,"helmet":helmet,"glass":glass,
        "thigh":thigh,"right_knee":right_knee,"feet":legs&(y>=293)}


def captain_masks(a):
    ink,x,y,P,R=geometry(a,"captain_everafter")
    blade=P([(234,0),(353,0),(353,220),(294,222),(293,198),
        (311,163),(306,136),(286,118),(266,112),(261,91),(272,66),
        (260,37),(244,28)])
    pole=P([(261,87),(287,91),(283,114),(267,127),(254,147),
        (247,170),(235,187),(217,218),(198,250),(179,283),
        (160,315),(145,338),(136,347),(139,353),(139,364),
        (133,375),(123,380),(114,378),(110,369),(111,361),
        (106,361),(108,353),(115,342),(124,330),(137,308),
        (156,277),(175,245),(194,213),(213,181),(230,150),
        (242,128),(253,108)])
    # The pole's brown end stops above the blue ground shadow.
    pole &= y<=375
    # This near-black pocket is the gap beside the boot, not pole material.
    pole &= ~R(0,364,116,383)
    left_arm=P([(96,171),(124,174),(128,191),(144,197),(154,208),
        (157,223),(152,237),(141,243),(123,241),(111,236),
        (107,221),(100,210),(96,195)])
    left_coat=P([(0,145),(106,145),(114,178),(114,203),(110,220),
        (107,242),(103,256),(99,270),(92,285),(86,304),(79,324),
        (75,334),(66,350),(0,359)])
    lining=P([(159,168),(200,168),(205,191),(204,211),(200,230),
        (200,252),(200,272),(196,293),(195,310),(189,321),
        (189,335),(185,350),(178,348),(173,329),(169,319),
        (162,330),(157,343),(151,343),(145,326),(143,312),
        (149,283),(155,251),(156,219)])
    lining |= R(140,310,194,353)
    right_coat=P([(224,197),(241,210),(256,225),(274,247),(294,272),
        (323,303),(349,341),(353,361),(341,362),(330,348),
        (322,339),(316,342),(309,352),(300,346),(299,330),
        (290,323),(279,323),(273,330),(270,339),(264,333),
        (260,322),(257,309),(252,296),(252,282),(249,267),
        (242,253),(238,242),(233,227)])
    left_coat |= R(0,333,59,358)
    # Entire exterior torn tips belong to the cape, including dark outlines.
    right_coat |= R(263,180,353,341)|R(275,341,353,355)|R(300,355,353,369)
    left_knee=P([(118,251),(135,249),(149,256),(155,270),(154,282),
        (147,290),(130,295),(117,287),(110,275),(111,261)])
    right_knee=P([(226,249),(239,247),(251,250),(255,262),(255,281),
        (248,289),(236,290),(224,284),(219,276),(218,261)])
    # Cloth passes behind the pads; complete pad pixels are fixed foreground.
    left_boot=R(61,366,116,383)
    right_boot=R(209,346,260,383)|R(260,360,292,383)
    protected=left_knee|right_knee|left_boot|right_boot
    body=((ink&(y<180))|blade|pole|left_arm|left_coat|lining|right_coat)&~protected
    legs=ink&~body
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    violet=(b>90)&(b>g*1.25)&(b>r*1.05)
    white=(r>195)&(g>180)&(b>210)
    edge=blade&(violet|white)&body
    # Only the rim band, not the broad dark rigid blade interior.
    rim=P([(238,0),(353,0),(353,220),(297,220),(308,195),
        (319,171),(326,144),(328,108),(319,75),(305,53),
        (281,34),(253,26)])
    edge &= rim
    helmet=P([(100,0),(210,0),(212,85),(192,91),(126,92),
        (104,72),(99,43)])&body
    glass=P([(146,24),(165,18),(186,26),(199,39),(202,62),
        (194,79),(180,85),(159,82),(144,69),(137,51),(139,36)])&helmet
    return {"body":body,"legs":legs,"scythe":(blade|pole)&body,
        "pole":pole&body,"blade":blade&body,"blade_edge":edge,
        "left_arm":left_arm&body,"coat":(left_coat|lining|right_coat)&body,
        "left_knee":left_knee,"right_knee":right_knee,
        "left_boot":left_boot,"right_boot":right_boot,
        "helmet":helmet,"glass":glass,"feet":legs&(y>=378)}


def glass_glint(moving,mask,x,y,i,name):
    light=np.zeros(mask.shape,dtype=bool)
    if i not in (2,3,4,5):return light
    center=([144,157,171,185] if name=="cinder_scout" else [144,159,175,190])[i-2]
    stripe=mask&(abs(x-center-(y-45)*.20)<3.0)&(y>=28)&(y<76)
    strength=[.18,.34,.30,.12][i-2]
    target=np.array([255,235,185] if name=="cinder_scout" else [225,210,255])
    moving[stripe,:3]=np.rint(moving[stripe,:3]*(1-strength)+target*strength).astype(np.uint8)
    light|=stripe
    return light


def fire_frame(a,masks,i):
    """Fire alone can flicker; glove, knife, helmet and armour never warp."""
    layer=np.zeros_like(a);fire=masks["fire"];source=a.copy()
    yy,xx=np.indices(fire.shape);x=xx-OFFSETS["cinder_scout"][0];y=yy-OFFSETS["cinder_scout"][1]
    if i in (0,7):
        layer[fire]=a[fire]
        layer[masks["embers"]]=a[masks["embers"]]
        return layer
    # Stretch only the soft fire above y=132, anchored at the hand. Inverse
    # nearest-row sampling keeps the flame connected without gaps between
    # tongues. The entire dark halo belongs to fire too, not to the torso.
    flutter=[0,1,-1,2,-2,1,-1,0][i]
    flicker=[0,.08,.22,.40,.23,.10,.04,0][i]
    weight=(flicker*.55*(source[fire,1].astype(float)/255)**1.3)[:,None]
    source[fire,:3]=np.rint(source[fire,:3]*(1-weight)+np.array([255,250,155])*weight).astype(np.uint8)
    bottom=fire&(y>=132);layer[bottom]=source[bottom]
    top=73;anchor=132;height=anchor-top
    stretch=[0,1,3,4,2,-1,-1,0][i]
    ox,oy=OFFSETS["cinder_scout"]
    for dest_y in range(top-stretch,anchor):
        src_y=round(anchor-(anchor-dest_y)*height/(height+stretch))
        src_y=min(anchor-1,max(top,src_y))
        dx=round(flutter*np.sin((dest_y-73)/15)*min(1,(anchor-dest_y)/12))
        xs=np.where(fire[src_y+oy])[0]
        layer[dest_y+oy,xs+dx]=source[src_y+oy,xs]
    # Every ember already present in the clean base rises too: no frozen old
    # particles remain. It fades before the cycle respawns at the base pose.
    ember=a.copy();em=masks["embers"]
    fade=[1,.92,.82,.72,.57,.36,.13,1][i]
    ember[em,3]=np.rint(a[em,3].astype(float)*fade).astype(np.uint8)
    stamp(layer,ember,em,dx=[0,0,1,1,2,2,2,0][i],dy=-2*i)
    # Two fresh small rising sparks, only during the central beat.
    if i in (2,3,4,5):
        ox,oy=OFFSETS["cinder_scout"];age=i-2
        for j,(px,py) in enumerate(((218,101),(266,88))):
            cx=ox+px+(-age if j==0 else age);cy=oy+py-age*3
            for dy,dx in ((0,0),(0,-1),(0,1),(-1,0),(1,0)):
                layer[cy+dy,cx+dx]=(255,192,54,[150,235,165,65][age])
    return layer


def build(name,a):
    scout=name=="cinder_scout"
    masks=(scout_masks if scout else captain_masks)(a)
    body,legs=masks["body"],masks["legs"]
    guards=("thigh","right_knee") if scout else ("left_knee","right_knee","left_boot","right_boot")
    protected=np.logical_or.reduce([masks[k] for k in guards])
    base,seam=backing(a,body,legs);fixed,fixed_seam=backing(a,legs,body)
    yy,xx=np.indices(body.shape);x=xx-OFFSETS[name][0];y=yy-OFFSETS[name][1]
    old_fire=(masks["fire"]|masks["embers"]) if scout else np.zeros(body.shape,dtype=bool)
    frames=[];checks=[];motion=[];effects=[];seams=[]
    for i,dy in enumerate(BREATH):
        moving=base.copy();local_effect=glass_glint(moving,masks["glass"],x,y,i,name)
        glow=0 if scout else [0,0,.50,1,.65,0,0,0][i]
        if glow:
            edge=masks["blade_edge"]
            weight=(glow*.75*(.30+.70*a[edge,2].astype(float)/255))[:,None]
            moving[edge,:3]=np.rint(a[edge,:3]*(1-weight)+np.array([246,218,255])*weight).astype(np.uint8)
            local_effect|=edge
        f=a.copy();f[body|old_fire]=0
        if dy:f[fixed_seam]=fixed[fixed_seam]
        extra=shift(seam,dy=dy)&~legs
        f[extra]=shift(moving,dy=dy)[extra]
        placed=stamp(f,moving,body,dy=dy)
        f[protected]=a[protected]
        effect=shift(local_effect,dy=dy)
        fire_dest=np.zeros(body.shape,dtype=bool)
        if scout:
            flame=shift(fire_frame(a,masks,i),dy=dy)
            fire_dest=(flame[:,:,3]>0)&~placed&~legs
            f[fire_dest]=flame[fire_dest];effect|=fire_dest
        seam_visible=(extra|(fixed_seam if dy else False))&~placed&~protected&~fire_dest
        c={"rigid_body_mismatches":count_diff(f,shift(a,dy=dy),placed&~effect&~protected),
            "visible_legs_mismatches":count_diff(f,a,legs&~placed&~extra),
            "feet_region_mismatches":count_diff(f,a,y>=(293 if scout else 378)),
            "body_clipped_pixels":int(body.sum()-placed.sum()),
            "visible_seam_pixels":int(seam_visible.sum())}
        for k in (("knife","left_arm","right_arm","helmet") if scout else ("scythe","pole","blade","left_arm","coat","helmet")):
            c[k+"_rigid_mismatches"]=count_diff(f,shift(a,dy=dy),shift(masks[k],dy=dy)&~effect&~protected)
        for k in guards:c[k+"_fixed_mismatches"]=count_diff(f,a,masks[k])
        weapon="knife" if scout else "scythe"
        c["complete_weapon_rigid_mismatches"]=count_diff(f,shift(a,dy=dy),shift(masks[weapon],dy=dy)&~effect)
        allowed=body|placed|seam_visible|effect|old_fire
        c["unexplained_pixel_mismatches"]=count_diff(f,a,~allowed)
        frames.append(f);checks.append(c);effects.append(effect);seams.append(seam_visible)
        motion.append({"frame":i+1,"body_and_weapon_dxy":[0,dy],"legs_dxy":[0,0],
            "glass_glint":i in (2,3,4,5),"blade_glow":glow,
            "ember_dxy":([0,0] if i in (0,7) else [[0,0,1,1,2,2,2,0][i],-2*i+dy]) if scout else None})
    return frames,masks,checks,motion,effects,seams


def review(name,a,frames,masks,effects,seams):
    h,w=a.shape[:2];colored=a.copy()
    groups=[("legs",(75,220,110)),("body",(35,210,240))]
    groups += [("knife",(235,90,240)),("fire",(255,170,55)),("embers",(255,170,55)),("thigh",(80,150,255))] if name=="cinder_scout" else [("coat",(255,120,120)),("scythe",(235,90,240)),("left_knee",(80,150,255)),("right_knee",(80,150,255))]
    for key,color in groups:colored[masks[key],:3]=color
    seg=Image.new("RGB",(w*2,h+24),(31,37,44));seg.paste(matte(a),(0,24));seg.paste(matte(colored),(w,24))
    ImageDraw.Draw(seg).text((8,6),"GREEN fixed legs | CYAN body | PINK cloth | PURPLE weapon | BLUE fixed thigh/knee | GOLD fire",fill="white")
    seg.save(HERE/f"{name}_segmentation.png")
    for k,m in masks.items():Image.fromarray(m.astype(np.uint8)*255).save(HERE/f"{name}_mask_{k}.png")
    for i,(e,s) in enumerate(zip(effects,seams)):
        Image.fromarray(e.astype(np.uint8)*255).save(HERE/f"{name}_effect_f{i+1}.png")
        Image.fromarray(s.astype(np.uint8)*255).save(HERE/f"{name}_seam_f{i+1}.png")
    Image.blend(matte(frames[0]),matte(frames[3]),.5).save(HERE/f"{name}_blend_f1_f4.png")
    ox,oy=OFFSETS[name]
    for tag,scale in [("native",1),("scale037",.37)]:
        views=[]
        for i,f in enumerate(frames):
            im=matte(f)
            if scale!=1:im=im.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST)
            v=Image.new("RGB",(im.width,im.height+24),(31,37,44));v.paste(im,(0,24))
            ImageDraw.Draw(v).text((8,6),f"F{i+1}",fill="white");views.append(v)
        views[0].save(HERE/f"{name}_{tag}.gif",save_all=True,append_images=views[1:],duration=[120,130]*4,loop=0,disposal=2)
        cols,rows=(4,2) if scale==1 else (8,1)
        plate=Image.new("RGB",(views[0].width*cols,views[0].height*rows),(31,37,44))
        for i,v in enumerate(views):plate.paste(v,((i%cols)*v.width,(i//cols)*v.height))
        plate.save(HERE/f"{name}_{tag}_contact.png")
    boxes={"knife_thigh":(40,160,148,238),"fire_glove":(195,31,275,177),"glass":(129,13,203,92)} if name=="cinder_scout" else {"cloak_knees":(62,180,265,355),"pole_boot":(90,315,150,383),"blade":(240,0,353,221),"glass":(132,14,210,91)}
    for label,b in boxes.items():
        b=(b[0]+ox,b[1]+oy,b[2]+ox,b[3]+oy);dw,dh=(b[2]-b[0])*3,(b[3]-b[1])*3
        plate=Image.new("RGB",(dw*3,dh+20),(31,37,44))
        for j,i in enumerate((0,3,4)):
            plate.paste(matte(frames[i]).crop(b).resize((dw,dh),Image.Resampling.NEAREST),(j*dw,20))
            ImageDraw.Draw(plate).text((j*dw+5,4),f"F{i+1}",fill="white")
        plate.save(HERE/f"{name}_detail_{label}.png")


def main():
    ap=argparse.ArgumentParser();ap.add_argument("--publish",action="store_true");args=ap.parse_args();report={}
    for name,offset in OFFSETS.items():
        source=ROOT/"assets/sprites/long"/f"{name}.png"
        # Existing idles supply dimensions only; not one of their pixels is used.
        with Image.open(source.with_name(name+"_idle.png")) as old:canvas=old.size
        master=Image.new("RGBA",(canvas[0]//8,canvas[1]));master.paste(Image.open(source).convert("RGBA"),offset)
        a=np.asarray(master);master.save(HERE/f"{name}_master.png")
        frames,masks,checks,motion,effects,seams=build(name,a)
        review(name,a,frames,masks,effects,seams)
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches") or key.endswith("clipped_pixels"):assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 not clean base")
        assert np.array_equal(frames[7],a),(name,"F8 differs from F1")
        strip=np.concatenate(frames,axis=1);assert (strip.shape[1],strip.shape[0])==canvas
        Image.fromarray(strip).save(HERE/f"{name}_idle.png")
        assert np.array_equal(np.asarray(Image.open(HERE/f"{name}_idle.png")),strip)
        if args.publish:
            Image.fromarray(strip).save(HERE.parent/f"{name}_idle.png")
            assert np.array_equal(np.asarray(Image.open(HERE.parent/f"{name}_idle.png")),strip)
        (HERE/f"{name}_motion.json").write_text(json.dumps(motion,indent=2)+"\n")
        report[name]={"source":str(source.relative_to(ROOT)),"base_offset":list(offset),
            "master_sha256":hashlib.sha256(a.tobytes()).hexdigest(),"strip_size":[strip.shape[1],strip.shape[0]],
            "frame_1_exact_clean_base":True,"frame_8_exact_frame_1":True,
            "old_idle_pixels_used":False,"frames":checks,"godot_run":False,"published":args.publish}
        print(f"{name}: rigid/feet/knee/loop checks PASS; {strip.shape[1]}x{strip.shape[0]}; published={args.publish}")
    (HERE/"pair_13_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__":main()
