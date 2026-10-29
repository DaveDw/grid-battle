"""Base-clean Courtesy Android / Tide Speaker cut-out idles; no Godot.

Lossless integer translations plus the explicitly permitted 4-degree head
tilt and local soft-tip curls. All production rotations use nearest sampling.
"""
from pathlib import Path
import argparse
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw
from build_pair_07 import shift, poly, rect, stamp, backing, cyan, brighten, count_diff, matte

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
SPECS={"courtesy_android":("ascendancy",(182,2)),"tide_speaker":("manyworlds",(228,2))}
BREATH=[0,1,1,2,2,1,1,0]


def rotate(a,mask,angle,pivot):
    layer=np.zeros_like(a);layer[mask]=a[mask]
    return np.asarray(Image.fromarray(layer).rotate(angle,Image.Resampling.NEAREST,
        expand=False,center=pivot,fillcolor=(0,0,0,0)))


def android_masks(a):
    ink=a[:,:,3]>0;shape=ink.shape;y,x=np.indices(shape)
    head=ink&poly(shape,[(250,0),(315,0),(315,54),(302,61),
        (296,65),(286,66),(274,61),(266,57),(259,51),(252,41)])
    rgb=a[:,:,:3].astype(float)
    white_core=rect(shape,291,32,301,47)&(rgb.min(axis=2)>150)
    eye=head&rect(shape,285,26,305,53)&(cyan(a)|white_core)
    gun=ink&poly(shape,[(345,151),(370,145),(425,184),(428,210),
                       (402,213),(365,183),(348,176)])
    return {"head":head,"eye":eye,"gun":gun,"fixed":ink&~head,"feet":ink&(y>=313)}


def build_android(a):
    masks=android_masks(a);head=masks["head"];fixed=masks["fixed"]
    y,x=np.indices(head.shape)
    # Pivot in the neck socket: the gun, torso, neck and legs remain fixed.
    pivot=(282,64)
    neck=rect(head.shape,266,57,300,69)
    base,seam=backing(a,fixed,head&neck)
    frames,checks,motion,effects,seams=[],[],[],[],[]
    for i in range(8):
        angle=-4 if 2<=i<=5 else 0
        moving=a.copy();light=np.zeros(head.shape,dtype=bool)
        if i==4:
            moving[masks["eye"],:3]=np.rint(a[masks["eye"],:3]*.025+np.array([8,12,15])).astype(np.uint8)
            light=masks["eye"]
        rotated=rotate(moving,head,angle,pivot)
        dest=rotated[:,:,3]>0
        effect=rotate(np.where(light[:,:,None],255,0).astype(np.uint8).repeat(4,axis=2),light,angle,pivot)[:,:,3]>0
        f=a.copy();f[head]=0
        if angle: f[seam]=base[seam]
        f[dest]=rotated[dest]
        # The socket's front lip stays in front of the head at its join.
        f[fixed]=a[fixed]
        visible=dest&~fixed
        expected=rotate(a,head,angle,pivot)
        seam_visible=seam&~dest if angle else np.zeros(head.shape,dtype=bool)
        c={"rotated_head_mismatches":count_diff(f,expected,visible&~effect),
           "fixed_body_mismatches":count_diff(f,a,fixed),
           "gun_mismatches":count_diff(f,a,masks["gun"]),
           "feet_region_mismatches":count_diff(f,a,y>=313),
           "unexplained_pixel_mismatches":count_diff(f,a,~(head|dest|seam_visible)),
           "visible_seam_pixels":int(seam_visible.sum())}
        frames.append(f);checks.append(c);effects.append(effect);seams.append(seam_visible)
        motion.append({"frame":i+1,"head_degrees":angle,"pivot":list(pivot),
                       "body_dxy":[0,0],"gun_dxy":[0,0],"eye_off":i==4})
    return frames,masks,checks,motion,effects,seams


def tide_masks(a):
    ink=a[:,:,3]>0;shape=ink.shape;y,x=np.indices(shape)
    orb=ink&rect(shape,238,37,325,119)
    # Only water from the clean base, never the previous idle's particles.
    water=ink&cyan(a)&(rect(shape,510,115,545,176)|
        rect(shape,274,119,290,134)|rect(shape,276,240,290,260))
    head=ink&poly(shape,[(333,0),(465,0),(466,109),(473,115),
        (475,140),(463,146),(463,165),(450,177),(444,189),(425,191),
        (411,185),(405,171),(400,159),(396,145),(377,141),(359,135),
        (356,116),(379,113),(391,105),(334,105)])
    bowl=ink&poly(shape,[(335,204),(340,198),(354,198),(368,205),(368,216),
        (397,219),(422,222),(451,219),(456,199),(470,198),(482,201),(500,207),
        (510,210),(516,217),(517,238),(512,247),(503,251),(491,252),(482,266),(468,280),
        (448,291),(427,297),(403,297),(381,294),(369,289),(359,285),(347,272),
        (339,258),(332,242),(330,226)])
    # Foreground purple skin overlaps the brass lip and clamps. Protect its
    # highlights and dark outline too; none of these fragments belong to metal.
    rgb=a[:,:,:3].astype(float)
    purple=(rgb[:,:,2]>rgb[:,:,0]*1.05)&(rgb[:,:,0]>rgb[:,:,1]*1.12)&(rgb[:,:,2]>40)
    skin_neighbourhood=np.zeros(shape,dtype=bool)
    for sy in range(-2,3):
        for sx in range(-2,3):skin_neighbourhood|=shift(purple,dx=sx,dy=sy)
    brass=(rgb[:,:,0]>rgb[:,:,2]*1.15)&(rgb[:,:,1]>rgb[:,:,2]*1.1)
    bowl &= ~(skin_neighbourhood&~brass)
    # Only distal 10-15px sections curl; every long shaft stays in place.
    tips=[
        ("upper_right",(516,84,535,101),(533,85),-4,False),
        ("left_middle",(273,207,288,225),(279,224),4,False),
        ("left_lower",(229,272,244,288),(234,273),-4,False),
        ("right_middle",(542,170,558,185),(557,181),4,False),
        ("right_lower",(546,301,558,318),(553,316),-4,False),
        ("right_bottom",(497,327,512,342),(510,331),4,False),
        ("bottom_middle",(371,357,386,371),(376,369),-4,False),
        ("crest",(350,3,365,18),(350,10),4,True),
        ("face_left",(359,112,376,130),(375,127),4,True),
        ("face_right",(461,121,475,138),(462,124),-4,True),
        ("face_front_left",(410,149,425,166),(419,150),4,True),
        ("face_front_right",(438,150,453,168),(444,151),-4,True)]
    tip_union=np.zeros(shape,dtype=bool);tip_specs=[]
    for name,box,pivot,angle,on_head in tips:
        m=ink&rect(shape,*box)
        if on_head: m&=head
        # Exclude unrelated neighbouring bronze from the tip rectangles.
        m &= ~((rgb[:,:,0]>rgb[:,:,2]*1.3)&(rgb[:,:,1]>rgb[:,:,2]*1.05))
        tip_union|=m
        tip_specs.append((name,m,pivot,angle,on_head))
    body=head|bowl
    fixed=ink&~body&~orb&~water&~tip_union
    masks={"head":head,"bowl":bowl,"body":body,"orb":orb,"water":water,
           "tips":tip_union,"fixed":fixed,"feet":fixed&(y>=373)}
    for name,m,_,_,_ in tip_specs: masks["tip_"+name]=m
    return masks,tip_specs


def build_tide(a):
    masks,tip_specs=tide_masks(a)
    body,orb,water,fixed=masks["body"],masks["orb"],masks["water"],masks["fixed"]
    body_main=body&~masks["tips"]
    layer,seam=backing(a,body_main,fixed)
    still,still_seam=backing(a,fixed,body_main)
    # Also back the gap below the stationary torso as the bowl settles down.
    # This copies at most three adjacent rows behind the moving cut-out.
    for distance in (1,2,3):
        below=shift(fixed,dy=distance)&body_main&~still_seam
        still[below]=shift(a,dy=distance)[below]
        still_seam|=below
    y,x=np.indices(body.shape)
    frames,checks,motion,effects,seams=[],[],[],[],[]
    for i,dy in enumerate(BREATH):
        orb_dy=[0,-1,-2,-3,-3,-2,-1,0][i]
        pulse=[0,.15,.45,.85,1,.55,.2,0][i]
        f=a.copy();f[body|orb|water|masks["tips"]]=0
        if dy: f[still_seam]=still[still_seam]
        moved=stamp(f,layer,body_main,dy=dy)
        extra=shift(seam,dy=dy)&~fixed&~moved
        f[extra]=shift(layer,dy=dy)[extra]
        glowing=a.copy()
        orb_light=orb&cyan(a)
        gain=[1,.72,.9,1.20,1.35,1.10,.94,1][i]
        if pulse:
            # Exposure preserves the dark aura and concentric ring shading.
            # A flat colour mix would turn these into a solid bright disc.
            rgb=a[orb_light,:3].astype(float)
            lit=rgb*gain
            lit[:,0]+=70*pulse*(rgb[:,1]/255)**3
            glowing[orb_light,:3]=np.rint(np.clip(lit,0,255)).astype(np.uint8)
        orb_dest=stamp(f,glowing,orb,dy=orb_dy)
        effect=shift(orb_light,dy=orb_dy) if pulse else np.zeros(body.shape,dtype=bool)
        # Small water streaks/sparkles twinkle in phases and drift one pixel.
        water_dy=[0,0,-1,-1,-1,-1,0,0][i]
        water_layer=a.copy()
        if i not in (0,7):
            strength=np.where(((x//9+y//11+i)%3)==0,.2,1.)
            water_layer[water,:3]=np.rint(a[water,:3]*strength[water,None]).astype(np.uint8)
            bright=water&(((x//9+y//11+i)%3)==1)
            brighten(water_layer,bright,(195,255,255),.7)
        water_dest=stamp(f,water_layer,water,dy=water_dy)
        effect|=water_dest
        tip_dest=np.zeros(body.shape,dtype=bool)
        tip_checks={};tip_angles={};tip_expected={};tip_roots=np.zeros(body.shape,dtype=bool)
        for name,m,pivot,target,on_head in tip_specs:
            angle=target if 2<=i<=5 else 0
            td=dy if on_head else 0
            rotated=rotate(a,m,angle,pivot)
            root=m&((x-pivot[0])**2+(y-pivot[1])**2<=9)
            if angle: tip_roots|=stamp(f,a,root,dy=td)
            placed=stamp(f,rotated,rotated[:,:,3]>0,dy=td)
            tip_dest|=placed
            tip_expected[name]=(shift(rotated,dy=td),placed)
            tip_angles[name]=angle
        # Whole original stationary parts win at their existing occlusion edges.
        f[fixed]=a[fixed]
        for name,(expected,placed) in tip_expected.items():
            tip_checks["tip_"+name+"_mismatches"]=count_diff(f,expected,placed&~fixed)
        seam_visible=extra|((still_seam if dy else np.zeros(body.shape,dtype=bool))&~moved&~tip_dest&~fixed)
        visible_body=moved&~fixed&~tip_dest
        c={"body_rigid_mismatches":count_diff(f,shift(a,dy=dy),visible_body),
           "bowl_rigid_mismatches":count_diff(f,shift(a,dy=dy),shift(masks["bowl"],dy=dy)&visible_body),
           "fixed_shafts_and_metal_mismatches":count_diff(f,a,fixed),
           "orb_rigid_mismatches":count_diff(f,shift(a,dy=orb_dy),orb_dest&~effect),
           "orb_alpha_mismatches":int(np.count_nonzero(f[:,:,3][orb_dest]!=shift(a,dy=orb_dy)[:,:,3][orb_dest])),
           "feet_region_mismatches":count_diff(f,a,y>=373),
           "body_clipped_pixels":int(body_main.sum()-moved.sum()),
           "orb_clipped_pixels":int(orb.sum()-orb_dest.sum()),
           "visible_seam_pixels":int(seam_visible.sum())}
        allowed=body|orb|water|masks["tips"]|moved|orb_dest|water_dest|tip_dest|tip_roots|seam_visible
        c["unexplained_pixel_mismatches"]=count_diff(f,a,~allowed)
        c.update(tip_checks)
        frames.append(f);checks.append(c);effects.append(effect|tip_dest);seams.append(seam_visible)
        motion.append({"frame":i+1,"head_and_bowl_dxy":[0,dy],"orb_dxy":[0,orb_dy],
            "orb_pulse":pulse,"orb_exposure":gain,"water_dxy":[0,water_dy],"tip_degrees":tip_angles,
            "long_shafts_and_stand_dxy":[0,0]})
    return frames,masks,checks,motion,effects,seams


def review(folder,name,a,frames,masks,effects,seams):
    h,w=a.shape[:2];colored=a.copy()
    groups=[("fixed",(75,220,110)),("head",(35,210,240))]
    groups += [("gun",(255,185,55))] if name=="courtesy_android" else [("bowl",(255,185,55)),("orb",(230,100,255)),("tips",(255,100,100)),("water",(210,255,255))]
    for key,color in groups:colored[masks[key],:3]=color
    seg=Image.new("RGB",(w*2,h+24),(31,37,44));seg.paste(matte(a),(0,24));seg.paste(matte(colored),(w,24))
    ImageDraw.Draw(seg).text((8,6),"GREEN fixed | CYAN head | GOLD bowl / fixed gun | PURPLE orb | RED tip cuts",fill="white")
    seg.save(folder/f"{name}_segmentation.png")
    for key,m in masks.items():Image.fromarray(m.astype(np.uint8)*255).save(folder/f"{name}_mask_{key}.png")
    for i,(e,s) in enumerate(zip(effects,seams)):
        Image.fromarray(e.astype(np.uint8)*255).save(folder/f"{name}_effect_f{i+1}.png")
        Image.fromarray(s.astype(np.uint8)*255).save(folder/f"{name}_seam_f{i+1}.png")
    Image.blend(matte(frames[0]),matte(frames[3]),.5).save(folder/f"{name}_blend_f1_f4.png")
    for tag,scale in [("native",1),("scale037",.37)]:
        views=[]
        for i,f in enumerate(frames):
            im=matte(f)
            if scale!=1:im=im.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST)
            v=Image.new("RGB",(im.width,im.height+24),(31,37,44));v.paste(im,(0,24))
            ImageDraw.Draw(v).text((8,6),f"F{i+1}",fill="white");views.append(v)
        views[0].save(folder/f"{name}_{tag}.gif",save_all=True,append_images=views[1:],duration=[120,130]*4,loop=0,disposal=2)
        cols=4 if scale==1 else 8;rows=2 if scale==1 else 1
        plate=Image.new("RGB",(views[0].width*cols,views[0].height*rows),(31,37,44))
        for i,v in enumerate(views):plate.paste(v,((i%cols)*v.width,(i//cols)*v.height))
        plate.save(folder/f"{name}_{tag}_contact.png")
    boxes={"head_neck":(252,4,317,85)} if name=="courtesy_android" else {"head":(351,102,477,197),"bowl":(325,202,514,314),"orb":(238,36,326,135),"lower_tips":(366,323,517,374)}
    for label,b in boxes.items():
        dw,dh=(b[2]-b[0])*3,(b[3]-b[1])*3
        plate=Image.new("RGB",(dw*3,dh+20),(31,37,44))
        for j,i in enumerate((0,3,4)):
            plate.paste(matte(frames[i]).crop(b).resize((dw,dh),Image.Resampling.NEAREST),(j*dw,20))
            ImageDraw.Draw(plate).text((j*dw+5,4),f"F{i+1}",fill="white")
        plate.save(folder/f"{name}_detail_{label}.png")


def main():
    ap=argparse.ArgumentParser();ap.add_argument("--publish",action="store_true");args=ap.parse_args()
    report={}
    for name,(faction,offset) in SPECS.items():
        folder=ROOT/"art_incoming"/faction/"idle_redo_review";folder.mkdir(exist_ok=True)
        source=ROOT/"assets"/"sprites"/faction/f"{name}.png"
        source_strip=Image.open(source.with_name(name+"_idle.png"))
        master=Image.new("RGBA",(source_strip.width//8,source_strip.height))
        master.paste(Image.open(source).convert("RGBA"),offset)
        a=np.asarray(master);master.save(folder/f"{name}_master.png")
        result=build_android(a) if name=="courtesy_android" else build_tide(a)
        frames,masks,checks,motion,effects,seams=result
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches") or key.endswith("clipped_pixels"):
                    assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 not clean base")
        assert np.array_equal(frames[7],a),(name,"F8 changed")
        strip=np.concatenate(frames,axis=1)
        assert (strip.shape[1],strip.shape[0])==source_strip.size
        Image.fromarray(strip).save(folder/f"{name}_idle.png")
        assert np.array_equal(np.asarray(Image.open(folder/f"{name}_idle.png")),strip)
        review(folder,name,a,frames,masks,effects,seams)
        if args.publish:
            Image.fromarray(strip).save(folder.parent/f"{name}_idle.png")
            assert np.array_equal(np.asarray(Image.open(folder.parent/f"{name}_idle.png")),strip)
        (folder/f"{name}_motion.json").write_text(json.dumps(motion,indent=2)+"\n")
        report[name]={"source":str(source.relative_to(ROOT)),"base_offset":list(offset),
            "master_sha256":hashlib.sha256(a.tobytes()).hexdigest(),
            "strip_size":[strip.shape[1],strip.shape[0]],"frame_1_exact_clean_base":True,
            "frame_8_exact":True,"old_idle_pixels_used":False,"frames":checks,
            "godot_run":False,"published":args.publish}
        (folder/f"{name}_self_check.json").write_text(json.dumps(report[name],indent=2)+"\n")
        print(f"{name}: rigid/feet/loop checks PASS; {strip.shape[1]}x{strip.shape[0]}; published={args.publish}")
    (HERE/"pair_09_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__":main()
