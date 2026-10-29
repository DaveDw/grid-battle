"""Mission Mother / Red Giant: clean bases, integer cut-outs, no Godot."""
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

OFFSETS={"mission_mother":(232,2),"red_giant":(235,2)}
BREATH=[0,1,1,2,2,1,1,0]
HEAVY=[0,1,2,3,3,2,1,0]


def geometry(a,name):
    ox,oy=OFFSETS[name];ink=a[:,:,3]>0;shape=ink.shape
    yy,xx=np.indices(shape);x,y=xx-ox,yy-oy
    def polygon(points):return ink&poly(shape,[(px+ox,py+oy) for px,py in points])
    def box(x0,y0,x1,y1):return ink&rect(shape,x0+ox,y0+oy,x1+ox,y1+oy)
    return ink,x,y,polygon,box


def mother_masks(a):
    ink,x,y,P,R=geometry(a,"mission_mother")
    upper_module=P([(44,0),(117,0),(117,82),(70,87),(46,71),(43,59)])
    left_tube=P([(48,53),(64,62),(32,82),(14,101),(7,121),(17,139),
        (42,147),(49,157),(25,161),(0,141),(0,103),(18,75)])
    left_drone=P([(0,147),(57,147),(65,157),(65,184),(59,198),
        (54,218),(45,225),(8,225),(0,214)])
    left=upper_module|left_tube|left_drone
    right=P([(195,13),(255,13),(264,46),(289,55),(291,104),
        (267,113),(269,128),(235,130),(231,113),(215,108),(215,76),
        (199,67),(193,48)])
    arm=P([(52,205),(98,203),(100,230),(93,248),(92,272),(79,280),
        (78,287),(62,291),(55,286),(40,286),(36,278),(37,259),(49,240)])
    bag=P([(94,210),(140,211),(141,235),(132,249),(106,252),(92,245)])
    left_coat=P([(98,234),(143,230),(145,249),(140,268),(132,279),
        (126,281),(124,305),(119,312),(114,291),(108,286),(98,291),
        (89,303),(78,323),(76,334),(65,343),(61,355),(51,363),
        (46,353),(41,361),(32,365),(25,372),(17,372),(17,361),
        (9,374),(3,375),(5,358),(15,341),(25,333),(47,313),
        (64,297),(77,280)])
    # Take the entire exterior silhouette at the torn left edge, including
    # isolated pale outline pixels. The boot lies to the right of this area.
    left_coat |= R(0,280,55,355)|R(0,355,43,379)
    right_coat=P([(172,214),(189,224),(198,245),(210,263),(232,285),
        (254,303),(274,327),(279,339),(272,341),(263,333),(263,346),
        (268,367),(266,376),(257,366),(244,356),(239,359),(235,348),
        (231,339),(230,321),(220,308),(211,291),(201,277),(188,260),
        (179,239)])
    right_coat |= R(223,308,245,358)
    lining=P([(144,264),(156,269),(164,286),(165,301),(158,323),
        (148,341),(140,354),(136,351),(132,341),(126,355),(121,365),
        (115,366),(116,356),(109,360),(110,352),(118,337),(124,325),
        (130,313),(133,296),(136,281)])
    left_knee=P([(105,301),(111,295),(123,294),(128,300),(130,306),
        (127,318),(122,327),(111,330),(103,326),(100,318),(102,308)])
    right_knee=P([(205,293),(215,290),(223,296),(225,305),(225,315),
        (221,324),(213,329),(204,328),(199,321),(199,305)])
    protected=left_knee|right_knee
    body=((ink&(y<238))|arm|bag|left_coat|right_coat|lining)&~left&~right
    body &= ~protected
    legs=ink&~body&~left&~right
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    red=(r>110)&(r>g*1.6)&(r>b*1.6)
    crosses=red&(R(29,158,61,191)|R(229,66,261,98))
    pointing_arm=P([(170,146),(234,144),(250,128),(296,127),(300,164),
        (260,188),(230,201),(199,200),(177,189)])&body
    return {"body":body,"legs":legs,"left_drone_assembly":left,
        "right_drone":right,"pointing_arm":pointing_arm,
        "coat":(left_coat|right_coat|lining)&body,"crosses":crosses,
        "left_knee":left_knee,"right_knee":right_knee,"feet":legs&(y>=379)}


def giant_masks(a):
    ink,x,y,P,R=geometry(a,"red_giant")
    fist=P([(0,137),(110,137),(151,166),(151,184),(157,195),
        (169,208),(174,226),(169,238),(171,245),(173,271),(170,288),
        (165,302),(159,309),(147,314),(128,315),(121,321),(101,321),
        (96,314),(90,317),(83,321),(56,321),(50,318),(44,313),
        (42,307),(28,307),(16,302),(9,289),(7,274),(0,267)])
    rock_arm=(ink&(x<159)&(y<196))|fist
    right_arm=P([(278,158),(326,161),(343,189),(355,215),(356,283),
        (346,296),(312,298),(301,282),(293,271),(291,248),(280,231),
        (269,219),(267,198),(272,182)])
    front_tabard=P([(168,204),(233,205),(233,217),(224,229),
        (221,250),(217,267),(216,277),(207,282),(205,272),
        (202,270),(199,288),(195,296),(189,293),(184,282),
        (177,281),(174,270),(172,251),(165,248),(162,223)])
    tails=P([(162,272),(178,273),(183,282),(194,297),(202,282),
        (217,273),(228,283),(234,290),(231,298),(225,299),
        (220,305),(214,318),(208,325),(202,321),(198,315),
        (192,311),(185,316),(181,323),(174,331),(169,338),
        (162,351),(155,355),(149,340),(148,331),(144,323),
        (139,326),(134,339),(130,343),(125,337),(129,321),
        (137,312),(154,305),(162,292)])
    left_knee=P([(42,333),(75,332),(99,337),(117,343),(128,353),
        (140,368),(141,414),(0,414),(0,362),(30,344)])
    right_knee=P([(243,258),(282,255),(303,270),(309,295),(298,315),
        (285,322),(267,319),(253,309),(244,293)])
    right_strap=P([(222,294),(240,295),(243,304),(236,318),(234,326),
        (231,331),(221,333),(210,326),(213,315)])
    left_thigh=R(62,328,115,335)
    right_thigh=P([(232,224),(254,230),(283,246),(278,255),
        (260,260),(244,275),(229,283),(223,276),(222,244)])
    guard=left_knee|right_knee|right_strap|left_thigh|right_thigh
    body=((ink&(y<208))|rock_arm|right_arm|front_tabard|tails)&~guard
    legs=ink&~body
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    candidate=rock_arm&body&(((r>210)&(g>35)&(r>2*b)&(g>1.3*b))|
        ((r>245)&(g>210)&(b<230)))
    # Keep the connected molten fissures; isolated tan highlights on rock
    # and metallic knuckles must retain their source pixels.
    lava=np.zeros(ink.shape,dtype=bool);seen=np.zeros(ink.shape,dtype=bool)
    for yy,xx in zip(*np.where(candidate)):
        if seen[yy,xx]:continue
        queue=[(yy,xx)];seen[yy,xx]=True;component=[]
        while queue:
            cy,cx=queue.pop();component.append((cy,cx))
            for sy in (-1,0,1):
                for sx in (-1,0,1):
                    ny,nx=cy+sy,cx+sx
                    if 0<=ny<ink.shape[0] and 0<=nx<ink.shape[1] and candidate[ny,nx] and not seen[ny,nx]:
                        seen[ny,nx]=True;queue.append((ny,nx))
        if len(component)>=60:
            ys,xs=zip(*component);lava[ys,xs]=True
    return {"body":body,"legs":legs,"rock_arm":rock_arm&body,
        "fist":fist&body,"right_arm":right_arm&body,
        "tabard":(front_tabard|tails)&body,"lava":lava,
        "left_knee":left_knee,"right_knee":right_knee,
        "right_leg_strap":right_strap,"left_thigh":left_thigh,
        "right_thigh":right_thigh,"feet":legs&(y>=375)}


def embers(shape,frame,occupied):
    layer=np.zeros((*shape,4),dtype=np.uint8)
    if frame not in (2,3,4,5):return layer
    ox,oy=OFFSETS["red_giant"];age=frame-2
    strength=[135,240,175,65][age]
    seeds=[(23,94,-1),(3,159,-1),(101,45,-1)]
    for j,(px,py,drift) in enumerate(seeds):
        cx=ox+px+drift*age;cy=oy+py-3-age*3
        for dy in (-1,0,1):
            for dx in (-1,0,1):
                if abs(dx)+abs(dy)>1:continue
                xx,yy=cx+dx,cy+dy
                if 0<=xx<shape[1] and 0<=yy<shape[0] and not occupied[yy,xx]:
                    layer[yy,xx]=(255,190 if j%2 else 137,40,
                        strength if dx==0 and dy==0 else round(strength*.55))
    return layer


def build(name,a):
    mother=name=="mission_mother"
    masks=(mother_masks if mother else giant_masks)(a)
    body,legs=masks["body"],masks["legs"]
    guards=("left_knee","right_knee") if mother else ("left_knee","right_knee","right_leg_strap","left_thigh","right_thigh")
    protected=np.logical_or.reduce([masks[k] for k in guards])
    base,seam=backing(a,body,legs)
    fixed,fixed_seam=backing(a,legs,body)
    y,x=np.indices(body.shape);ly=y-OFFSETS[name][1]
    frames=[];checks=[];motion=[];effects=[];seams=[]
    for i,dy in enumerate(BREATH if mother else HEAVY):
        moving=base.copy();effect=np.zeros(body.shape,dtype=bool)
        glow=0 if mother else [0,.1,.45,1,.8,.3,.1,0][i]
        if glow:
            m=masks["lava"]
            # Heat the bright cores more than the dim orange halo so the
            # source gradients remain intact instead of becoming flat paint.
            weight=(glow*.78*(a[m,1].astype(float)/255)**1.4)[:,None]
            moving[m,:3]=np.rint(a[m,:3]*(1-weight)+np.array([255,255,220])*weight).astype(np.uint8)
            effect|=shift(m,dy=dy)
        f=a.copy();f[body]=0
        if dy:f[fixed_seam]=fixed[fixed_seam]
        extra=shift(seam,dy=dy)&~legs
        f[extra]=shift(moving,dy=dy)[extra]
        placed=stamp(f,moving,body,dy=dy)
        # The pads and leg strap are in front of hanging cloth, never part of
        # its moving cut-out. Preserve their complete source pixels.
        f[protected]=a[protected]
        c={};moved_special=np.zeros(body.shape,dtype=bool);old_special=np.zeros(body.shape,dtype=bool)
        drone_motion={}
        if mother:
            for k,direction in (("left_drone_assembly",-1),("right_drone",1)):
                old_special|=masks[k]
            f[old_special]=0
            for k,direction in (("left_drone_assembly",-1),("right_drone",1)):
                bob=direction*[0,1,2,3,3,2,1,0][i]
                drone=a.copy();cross=masks[k]&masks["crosses"]
                blink=(k=="left_drone_assembly" and i in (2,3)) or (k=="right_drone" and i in (4,5))
                if blink:
                    drone[cross,:3]=np.rint(a[cross,:3]*.18+np.array([34,3,3])).clip(0,255).astype(np.uint8)
                dm=stamp(f,drone,masks[k],dy=bob);moved_special|=dm
                light=shift(cross,dy=bob) if blink else np.zeros(body.shape,dtype=bool)
                effect|=light
                c[k+"_rigid_mismatches"]=count_diff(f,shift(a,dy=bob),dm&~light)
                c[k+"_clipped_pixels"]=int(masks[k].sum()-dm.sum())
                drone_motion[k]={"dxy":[0,bob],"cross_dimmed":blink}
        else:
            sparks=embers(body.shape,i,f[:,:,3]>0);sm=sparks[:,:,3]>0
            f[sm]=sparks[sm];effect|=sm;moved_special|=sm
            c["ember_pixels"]=int(sm.sum())
        seam_visible=(extra|(fixed_seam if dy else False))&~placed&~moved_special&~protected
        c.update({"rigid_body_mismatches":count_diff(f,shift(a,dy=dy),placed&~effect&~moved_special&~protected),
            "visible_legs_mismatches":count_diff(f,a,legs&~placed&~extra&~moved_special),
            "feet_region_mismatches":count_diff(f,a,ly>=(379 if mother else 375)),
            "body_clipped_pixels":int(body.sum()-placed.sum()),
            "visible_seam_pixels":int(seam_visible.sum())})
        for k in (("pointing_arm","coat") if mother else ("rock_arm","fist","right_arm","tabard")):
            c[k+"_rigid_mismatches"]=count_diff(f,shift(a,dy=dy),shift(masks[k],dy=dy)&~effect&~moved_special&~protected)
        for k in guards:
            c[k+"_fixed_mismatches"]=count_diff(f,a,masks[k])
        allowed=body|placed|seam_visible|effect|old_special|moved_special
        c["unexplained_pixel_mismatches"]=count_diff(f,a,~allowed)
        frames.append(f);checks.append(c);effects.append(effect|moved_special);seams.append(seam_visible)
        motion.append({"frame":i+1,"body_dxy":[0,dy],"legs_dxy":[0,0],
            "drones":drone_motion,"lava_glow":glow,"ember_age":i-2 if not mother and 2<=i<=5 else None})
    return frames,masks,checks,motion,effects,seams


def review(name,a,frames,masks,effects,seams):
    h,w=a.shape[:2];colored=a.copy()
    groups=[("legs",(75,220,110)),("body",(35,210,240))]
    groups += [("coat",(255,120,120)),("left_drone_assembly",(230,100,255)),("right_drone",(255,185,55))] if name=="mission_mother" else [("rock_arm",(255,185,55)),("tabard",(255,120,120)),("left_knee",(80,150,255)),("right_knee",(80,150,255)),("right_leg_strap",(80,150,255))]
    for key,color in groups:colored[masks[key],:3]=color
    seg=Image.new("RGB",(w*2,h+24),(31,37,44));seg.paste(matte(a),(0,24));seg.paste(matte(colored),(w,24))
    ImageDraw.Draw(seg).text((8,6),"GREEN fixed legs | CYAN body | PINK cloth | BLUE protected knee/strap | GOLD/PURPLE arm or drones",fill="white")
    seg.save(HERE/f"{name}_segmentation.png")
    for k,m in masks.items():Image.fromarray(m.astype(np.uint8)*255).save(HERE/f"{name}_mask_{k}.png")
    for i,(e,s) in enumerate(zip(effects,seams)):
        Image.fromarray(e.astype(np.uint8)*255).save(HERE/f"{name}_effect_f{i+1}.png")
        Image.fromarray(s.astype(np.uint8)*255).save(HERE/f"{name}_seam_f{i+1}.png")
    Image.blend(matte(frames[0]),matte(frames[3]),.5).save(HERE/f"{name}_blend_f1_f4.png")
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
    boxes={"left_drone":(0,139,90,227),"right_drone":(193,13,294,131),"coat_knees":(70,265,245,365)} if name=="mission_mother" else {"fist_thigh":(25,284,180,346),"tabard_knee":(125,245,310,360),"lava":(0,137,172,282)}
    ox,oy=OFFSETS[name]
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
        # The rejected/current idle contributes its canvas dimensions only.
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
    (HERE/"pair_12_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__":main()
