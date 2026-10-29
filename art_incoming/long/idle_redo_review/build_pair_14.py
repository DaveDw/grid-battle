"""Deadweight and Parallax: clean-base integer cut-outs, no Godot."""
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

OFFSETS={"deadweight":(212,2),"parallax":(255,3)}
BREATH=[0,1,1,2,2,1,1,0]


def geometry(a,name):
    ox,oy=OFFSETS[name];ink=a[:,:,3]>0;shape=ink.shape
    yy,xx=np.indices(shape);x,y=xx-ox,yy-oy
    def P(points):return ink&poly(shape,[(px+ox,py+oy) for px,py in points])
    def R(x0,y0,x1,y1):return ink&rect(shape,x0+ox,y0+oy,x1+ox,y1+oy)
    return ink,x,y,P,R


def deadweight_masks(a):
    ink,x,y,P,R=geometry(a,"deadweight")
    pack=P([(0,150),(50,154),(61,169),(65,188),(63,204),(64,227),
        (53,239),(35,239),(28,239),(17,233),(9,225),(6,211),(0,207)])
    left_glove=P([(109,126),(144,120),(158,129),(161,141),(148,146),
        (143,151),(164,150),(171,160),(171,170),(163,176),(165,185),
        (160,192),(162,201),(154,210),(138,211),(129,213),(119,208),(112,196)])
    right_glove=P([(231,119),(250,120),(255,134),(250,141),(261,143),
        (264,152),(264,162),(267,168),(265,180),(258,183),(260,191),
        (252,199),(247,207),(234,208),(228,202),(227,186),(230,166),(227,147)])
    orb=P([(151,144),(156,132),(166,123),(178,117),(204,115),(217,119),
        (230,130),(238,144),(242,161),(240,180),(231,197),(218,207),
        (204,213),(179,214),(165,207),(157,201),(150,189),(147,172)])
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    # Yellow below the orb is thigh armour, not part of the halo cut-out.
    orb &= ~((y>=205)&(r>65)&(g>r*.45)&(b<g*.65))
    belt=P([(121,193),(174,195),(174,214),(158,224),(143,229),
        (127,225),(121,216)])
    left_knee=P([(66,233),(83,228),(99,232),(108,243),(108,259),
        (99,273),(80,274),(65,263),(61,248)])
    right_knee=P([(190,225),(208,224),(222,235),(226,247),
        (221,259),(211,266),(193,263),(185,250),(185,237)])
    protected=left_knee|right_knee
    body=((ink&(y<196))|pack|left_glove|right_glove|orb|belt)&~protected
    legs=ink&~body
    # The two fingers crossing the left edge must occlude the inner swirl.
    fingers=left_glove|right_glove|R(134,152,172,173)|R(134,174,172,192)|R(135,193,164,212)
    core=ink&(((x-191)/37)**2+((y-165)/37)**2<1)&~fingers
    violet=(b>55)&(b>g*1.2)&(b>r*1.05)
    pale=(r>160)&(g>145)&(b>210)
    rim=orb&~fingers&(violet|pale)&~core&body
    # This patch is a brass backpack fitting, not an emissive display.
    led=np.zeros(ink.shape,dtype=bool)
    helmet=R(103,0,218,116)&body
    return {"body":body,"legs":legs,"pack":pack&body,"belt":belt&body,
        "gloves":(left_glove|right_glove|fingers)&body,
        "orb":orb&body,"core":core&body,"rim":rim,"pack_led":led,
        "helmet":helmet,"left_knee":left_knee,"right_knee":right_knee,
        "feet":legs&(y>=292)}


def parallax_masks(a):
    ink,x,y,P,R=geometry(a,"parallax")
    ring=P([(15,188),(43,188),(48,204),(57,209),(66,216),(76,216),
        (83,222),(84,230),(77,238),(78,251),(78,265),(77,275),
        (71,284),(64,291),(55,299),(43,305),(25,309),(0,309),
        (0,207)])
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    # The adjacent blue kneepad is not part of the ring's outside edge.
    ring &= ~((x>=69)&(y>=238)&(b>r*1.15)&(b>g*1.05))
    ring |= ink&(x<0)&(y>=200)&(y<310)
    hand=P([(18,173),(48,173),(50,185),(46,198),(41,207),
        (39,221),(30,222),(28,212),(17,213),(13,207),(14,194)])
    right_arm=P([(183,122),(232,127),(283,143),(283,210),(263,213),
        (260,202),(250,203),(243,193),(231,185),(212,185),(195,179),
        (184,165),(178,149)])
    pouch=P([(81,167),(114,166),(121,178),(118,194),(111,212),
        (91,216),(80,211),(75,200),(76,180)])
    left_rag=P([(118,175),(134,175),(131,201),(120,223),(109,239),
        (104,250),(99,241),(97,233),(92,234),(90,242),(84,244),
        (80,239),(76,246),(69,244),(68,234),(70,217),(76,204),(96,197)])
    inner_rag=P([(128,215),(146,207),(147,231),(140,248),(141,268),
        (133,280),(137,286),(133,298),(124,292),(126,305),(122,320),
        (114,320),(112,305),(113,295),(110,285),(108,283),(105,292),
        (98,298),(98,278),(101,258),(109,240)])
    inner_rag |= R(98,287,148,322)|R(109,277,148,287)
    right_rag=P([(181,247),(202,249),(212,256),(219,268),(220,279),
        (213,280),(206,288),(204,304),(199,313),(193,313),(194,298),
        (186,291),(182,276),(178,282),(176,295),(168,302),(165,295),
        (167,281),(172,267)])
    right_rag |= R(164,272,198,314)
    left_knee=P([(87,246),(100,247),(109,256),(110,270),(104,281),
        (88,286),(78,283),(75,277),(76,263),(80,253)])
    # The two brown pixels beside the pad are the ring's outer contour.
    left_knee &= ~R(0,246,77,273)
    left_thigh_plate=P([(94,223),(105,224),(111,233),(110,242),
        (103,257),(98,260),(93,252),(92,245),(87,241),(87,229)])
    right_knee=P([(185,220),(201,223),(213,232),(218,245),(213,258),
        (199,263),(186,256),(178,244),(180,231)])
    right_shin=P([(206,289),(220,284),(232,292),(236,308),(225,324),
        (214,331),(203,323),(198,310),(199,298)])
    protected=left_knee|left_thigh_plate|right_knee|right_shin
    rags=left_rag|inner_rag|right_rag
    body=((ink&(y<177))|ring|hand|right_arm|pouch|rags)&~protected
    legs=ink&~body
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    violet=(b>75)&(b>g*1.2)&(r>g*1.3)
    white=(r>200)&(g>180)&(b>220)
    star=R(162,42,198,83)&(violet|white)&body
    helmet=R(100,0,222,111)&body
    return {"body":body,"legs":legs,"ring_staff":ring&body,
        "left_hand":hand&body,"right_arm":right_arm&body,
        "pouch":pouch&body,"rags":rags&body,"star":star,"helmet":helmet,
        "left_knee":left_knee,"left_thigh_plate":left_thigh_plate,
        "right_knee":right_knee,"right_shin":right_shin,"feet":legs&(y>=324)}


def orb_swirl(a,masks,angle):
    if not angle:return a.copy()
    _,x,y,_,_=geometry(a,"deadweight")
    cx,cy=191+OFFSETS["deadweight"][0],165+OFFSETS["deadweight"][1]
    yy,xx=np.indices(x.shape)
    full=((x-191)/37)**2+((y-165)/37)**2<1
    texture=a.copy()
    # Reconstruct the dark interior hidden by the rigid fingers using pixels
    # mirrored from the visible opposite side. No glove pixels enter the swirl.
    hidden=(((x-191)/40)**2+((y-165)/40)**2<1)&(x<191)&~masks["core"]
    hy,hx=np.where(hidden);texture[hy,hx,:3]=a[hy,2*cx-hx,:3]
    ty,tx=np.where(masks["core"]);theta=np.deg2rad(angle)
    sx=np.rint(cx+(tx-cx)*np.cos(theta)+(ty-cy)*np.sin(theta)).astype(int)
    sy=np.rint(cy-(tx-cx)*np.sin(theta)+(ty-cy)*np.cos(theta)).astype(int)
    out=a.copy();out[ty,tx,:3]=texture[sy,sx,:3]
    return out


def build(name,a):
    dead=name=="deadweight"
    masks=(deadweight_masks if dead else parallax_masks)(a)
    ink,x,y,P,R=geometry(a,name)
    body,legs=masks["body"],masks["legs"]
    guard_names=("left_knee","right_knee") if dead else ("left_knee","left_thigh_plate","right_knee","right_shin")
    protected=np.logical_or.reduce([masks[k] for k in guard_names])
    base,seam=backing(a,body,legs);fixed,fixed_seam=backing(a,legs,body)
    frames=[];real_frames=[];checks=[];motion=[];effects=[];seams=[]
    for i,dy in enumerate(BREATH):
        moving=base.copy();local_effect=np.zeros(body.shape,dtype=bool)
        angle=[0,0,60,140,220,300,0,0][i] if dead else 0
        pulse=([0,0,.45,1,.65,.20,0,0] if dead else [0,0,.35,.85,.45,.12,0,0])[i]
        if dead:
            if angle:
                swirled=orb_swirl(a,masks,angle);core=masks["core"]
                moving[core,:3]=swirled[core,:3];local_effect|=core
            if pulse:
                rim=masks["rim"]
                weight=(pulse*.70*(.25+.75*a[rim,2].astype(float)/255))[:,None]
                moving[rim,:3]=np.rint(a[rim,:3]*(1-weight)+np.array([240,202,255])*weight).astype(np.uint8)
                local_effect|=rim
            led=masks["pack_led"]
            if i in (2,3):
                moving[led,:3]=np.rint(a[led,:3]*.15).astype(np.uint8);local_effect|=led
            elif i in (4,5):
                moving[led,:3]=np.rint(a[led,:3]*.3+np.array([255,237,133])*.7).astype(np.uint8);local_effect|=led
        elif pulse:
            star=masks["star"]
            moving[star,:3]=np.rint(a[star,:3]*(1-pulse*.7)+np.array([239,225,255])*pulse*.7).astype(np.uint8)
            local_effect|=star
        f=a.copy();f[body]=0
        if dy:f[fixed_seam]=fixed[fixed_seam]
        extra=shift(seam,dy=dy)&~legs
        f[extra]=shift(moving,dy=dy)[extra]
        placed=stamp(f,moving,body,dy=dy)
        f[protected]=a[protected]
        # The held ring is in front of the leg. Retain its complete translated
        # edge where it overlaps the fixed pad by one or two pixels.
        held_front=np.zeros(body.shape,dtype=bool)
        if not dead:held_front=stamp(f,moving,masks["ring_staff"],dy=dy)
        real=f.copy();real_frames.append(real)
        effect=shift(local_effect,dy=dy)
        ghost_visible=np.zeros(body.shape,dtype=bool)
        ghost_dx=0;ghost_opacity=0
        if not dead and i in (2,3,4,5):
            ghost_dx=[-6,-8,-10,-10][i-2];ghost_opacity=[.35,.35,.23,.10][i-2]
            ghost=real.copy()
            # Exclude only the flat ground-shadow bridge between the feet.
            ghost[(y>=352)&(x>78)&(x<207)]=0
            gi=ghost[:,:,3]>0
            ghost[gi,:3]=np.rint(ghost[gi,:3]*.35+np.array([62,137,255])*.65).clip(0,255).astype(np.uint8)
            ghost[gi,3]=np.rint(ghost[gi,3].astype(float)*ghost_opacity).astype(np.uint8)
            ghost=shift(ghost,dx=ghost_dx)
            ghost_visible=(ghost[:,:,3]>0)&(real[:,:,3]==0)
            f[ghost_visible]=ghost[ghost_visible];effect|=ghost_visible
        seam_visible=(extra|(fixed_seam if dy else False))&~placed&~protected
        c={"rigid_body_mismatches":count_diff(real,shift(a,dy=dy),placed&~shift(local_effect,dy=dy)&~protected),
            "visible_legs_mismatches":count_diff(real,a,legs&~placed&~extra),
            "real_feet_region_mismatches":count_diff(real,a,y>=(292 if dead else 324)),
            "original_feet_pixels_mismatches":count_diff(f,a,masks["feet"]),
            "body_clipped_pixels":int(body.sum()-placed.sum()),
            "visible_seam_pixels":int(seam_visible.sum()),"afterimage_visible_pixels":int(ghost_visible.sum())}
        for k in (("gloves","helmet","pack","belt") if dead else ("ring_staff","left_hand","right_arm","rags","helmet","pouch")):
            c[k+"_rigid_mismatches"]=count_diff(real,shift(a,dy=dy),shift(masks[k],dy=dy)&~shift(local_effect,dy=dy)&~protected)
        k="gloves" if dead else "ring_staff"
        c["complete_held_part_rigid_mismatches"]=count_diff(real,shift(a,dy=dy),shift(masks[k],dy=dy)&~shift(local_effect,dy=dy))
        for k in guard_names:
            c[k+"_fixed_mismatches"]=count_diff(f,a,masks[k]&~held_front)
            c[k+"_pixels_occluded_by_ring"]=int((masks[k]&held_front).sum())
        c["afterimage_foreground_mismatches"]=count_diff(f,real,real[:,:,3]>0)
        c["unexplained_pixel_mismatches"]=count_diff(f,a,~(body|placed|seam_visible|effect))
        frames.append(f);checks.append(c);effects.append(effect);seams.append(seam_visible)
        motion.append({"frame":i+1,"body_and_held_part_dxy":[0,dy],"legs_dxy":[0,0],
            "orb_inner_rotation_degrees":angle,"light_pulse":pulse,
            "pack_light":"dim" if dead and i in (2,3) else "bright" if dead and i in (4,5) else "base",
            "afterimage_dxy":[ghost_dx,0],"afterimage_opacity":ghost_opacity})
    return frames,real_frames,masks,checks,motion,effects,seams


def review(name,a,frames,real_frames,masks,effects,seams):
    h,w=a.shape[:2];colored=a.copy()
    groups=[("legs",(75,220,110)),("body",(35,210,240))]
    groups += [("gloves",(255,180,55)),("orb",(220,85,245)),("core",(135,95,255))] if name=="deadweight" else [("rags",(255,120,120)),("ring_staff",(255,180,55))]
    groups += [("left_knee",(75,130,255)),("right_knee",(75,130,255))]
    for key,color in groups:colored[masks[key],:3]=color
    seg=Image.new("RGB",(w*2,h+24),(31,37,44));seg.paste(matte(a),(0,24));seg.paste(matte(colored),(w,24))
    ImageDraw.Draw(seg).text((8,6),"GREEN fixed legs | CYAN body | PINK rags | GOLD held parts | BLUE knees | PURPLE orb",fill="white")
    seg.save(HERE/f"{name}_segmentation.png")
    for k,m in masks.items():Image.fromarray(m.astype(np.uint8)*255).save(HERE/f"{name}_mask_{k}.png")
    for i,(e,s) in enumerate(zip(effects,seams)):
        Image.fromarray(e.astype(np.uint8)*255).save(HERE/f"{name}_effect_f{i+1}.png")
        Image.fromarray(s.astype(np.uint8)*255).save(HERE/f"{name}_seam_f{i+1}.png")
    Image.blend(matte(real_frames[0]),matte(real_frames[3]),.5).save(HERE/f"{name}_blend_f1_f4.png")
    ox,oy=OFFSETS[name]
    for tag,scale in [("native",1),("scale037",.37)]:
        views=[]
        for i,f in enumerate(frames):
            im=matte(f)
            if scale!=1:im=im.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST)
            v=Image.new("RGB",(im.width,im.height+24),(31,37,44));v.paste(im,(0,24))
            ImageDraw.Draw(v).text((8,6),f"F{i+1}",fill="white");views.append(v)
        views[0].save(HERE/f"{name}_{tag}.gif",save_all=True,append_images=views[1:],duration=[120,130]*4,loop=0,disposal=2)
        cols,rows=(4,2)
        plate=Image.new("RGB",(views[0].width*cols,views[0].height*rows),(31,37,44))
        for i,v in enumerate(views):plate.paste(v,((i%cols)*v.width,(i//cols)*v.height))
        plate.save(HERE/f"{name}_{tag}_contact.png")
    boxes={"orb_gloves":(111,112,268,225),"waist_knees":(0,188,236,279),"pack_light":(61,26,101,62)} if name=="deadweight" else {"ring_leg":(0,199,114,317),"rags_knees":(65,187,242,324),"visor":(147,30,211,91)}
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
        with Image.open(source.with_name(name+"_idle.png")) as old:canvas=old.size
        master=Image.new("RGBA",(canvas[0]//8,canvas[1]));master.paste(Image.open(source).convert("RGBA"),offset)
        a=np.asarray(master);master.save(HERE/f"{name}_master.png")
        if name=="parallax":
            # The extracted base cuts off the astrolabe at its left boundary.
            # Complete that missing arc from its intact opposite arc, using
            # exact reflected source pixels only in previously empty space.
            a=a.copy();ring=parallax_masks(a)["ring_staff"]
            ox,oy=offset;yy,xx=np.where(ring)
            reflected=2*(ox+30)-xx
            keep=(reflected<ox)&(reflected>=0)&(yy>=oy+200)&(yy<oy+310)
            colors=a[yy,xx,:3].astype(float)
            gold=(colors[:,0]>colors[:,2]*1.15)&(colors[:,1]>colors[:,2]*.8)
            outline=np.max(colors,axis=1)<25
            keep &= gold|outline
            a[yy[keep],reflected[keep]]=a[yy[keep],xx[keep]]
            master=Image.fromarray(a);master.save(HERE/f"{name}_master.png")
        frames,real_frames,masks,checks,motion,effects,seams=build(name,a)
        review(name,a,frames,real_frames,masks,effects,seams)
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches") or key.endswith("clipped_pixels"):assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 not clean base")
        assert np.array_equal(frames[7],a),(name,"F8 differs from F1")
        strip=np.concatenate(frames,axis=1);assert (strip.shape[1],strip.shape[0])==canvas
        Image.fromarray(strip).save(HERE/f"{name}_idle.png")
        Image.fromarray(np.concatenate(real_frames,axis=1)).save(HERE/f"{name}_real_only.png")
        assert np.array_equal(np.asarray(Image.open(HERE/f"{name}_idle.png")),strip)
        if args.publish:
            Image.fromarray(strip).save(HERE.parent/f"{name}_idle.png")
            assert np.array_equal(np.asarray(Image.open(HERE.parent/f"{name}_idle.png")),strip)
        (HERE/f"{name}_motion.json").write_text(json.dumps(motion,indent=2)+"\n")
        report[name]={"source":str(source.relative_to(ROOT)),"base_offset":list(offset),
            "master_sha256":hashlib.sha256(a.tobytes()).hexdigest(),"strip_size":[strip.shape[1],strip.shape[0]],
            "frame_1_exact_clean_base":True,"frame_8_exact_frame_1":True,"old_idle_pixels_used":False,
            "frames":checks,"godot_run":False,"published":args.publish}
        print(f"{name}: rigid/feet/knee/loop checks PASS; {strip.shape[1]}x{strip.shape[0]}; published={args.publish}")
    (HERE/"pair_14_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__":main()
