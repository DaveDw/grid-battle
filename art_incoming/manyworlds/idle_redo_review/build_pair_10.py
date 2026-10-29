"""Reef Bulwark / Reed Runner clean-base cut-out idles. No Godot.

Only the specified pincer rotation, soft throat pouch and eye effects depart
from whole-pixel translations. No old idle pixels are carried into the art.
"""
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
from build_pair_07 import shift, poly, rect, stamp, backing, cyan, brighten, count_diff, matte
from build_pair_09 import rotate

BREATH=[0,1,1,2,2,1,1,0]
OFFSETS={"reef_bulwark":(124,2),"reed_runner":(148,2)}


def reef_masks(a):
    ink=a[:,:,3]>0;shape=ink.shape;y,x=np.indices(shape)
    shield=ink&poly(shape,[(449,78),(463,89),(477,107),(493,141),
        (501,198),(492,241),(471,285),(451,311),(432,325),(422,290),
        (419,266),(413,238),(410,211),(411,191),(419,178),(422,140),
        (432,117),(439,100)])
    right_leg=ink&poly(shape,[(358,202),(372,203),(386,218),(402,237),
        (415,250),(420,284),(405,312),(408,329),(445,349),(453,373),
        (277,373),(282,352),(317,327),(336,321),(337,312),(327,306),
        (327,281),(337,268),(344,256),(334,248),(346,232),(346,211)])
    left_leg=ink&poly(shape,[(125,319),(173,317),(194,330),(201,350),
        (200,373),(125,373)])
    # Include both isolated black sole-edge pixels in the fixed cut-out.
    legs=((right_leg|left_leg)&~shield)|(ink&(y>=355))
    body=ink&~legs
    # The narrow upper red jaw and its cap are one cut-out, hinged at the palm.
    jaw=body&poly(shape,[(223,278),(239,273),(250,280),(259,291),
        (267,299),(270,307),(277,315),(283,329),(280,338),(267,337),
        (261,329),(254,322),(247,317),(239,315),(235,310),(231,302),
        (226,294)])
    shell=body&poly(shape,[(126,22),(292,22),(325,90),(324,156),
        (294,182),(233,184),(173,165),(127,199)])
    eyes=body&cyan(a)&rect(shape,308,61,388,101)
    return {"body":body,"legs":legs,"shield":shield,"shell":shell,
            "jaw":jaw,"eyes":eyes,"feet":legs&(y>=355)}


def runner_masks(a):
    ink=a[:,:,3]>0;shape=ink.shape;y,x=np.indices(shape)
    tail=ink&poly(shape,[(147,158),(219,153),(230,164),(224,176),
        (211,184),(189,197),(166,218),(173,244),(155,240),(145,222)])
    torso=ink&(y<164)&~tail
    rifle=ink&poly(shape,[(262,94),(325,101),(353,114),(405,144),
        (445,157),(451,188),(442,195),(419,187),(408,184),(401,175),
        (380,179),(364,173),(358,163),(331,159),(327,164),(311,159),
        (292,163),(271,150),(258,132)])
    pouches=ink&(poly(shape,[(211,132),(246,135),(246,162),(237,182),
        (220,185),(208,175)])|poly(shape,[(289,146),(325,148),(325,206),(291,206)]))
    body=torso|rifle|pouches
    legs=ink&~body
    pouch=body&poly(shape,[(317,60),(353,60),(356,63),(352,69),
        (345,75),(331,76),(322,71)])
    rgb=a[:,:,:3].astype(float)
    # Keep the purple scarf out of the soft-skin deformation mask.
    purple=(rgb[:,:,2]>rgb[:,:,0]*1.05)&(rgb[:,:,0]>rgb[:,:,1]*1.1)
    pouch &= ~purple
    scarf=body&purple&rect(shape,170,20,362,145)
    orange=(rgb[:,:,0]>100)&(rgb[:,:,0]>rgb[:,:,1]*1.3)&(rgb[:,:,1]>rgb[:,:,2]*1.2)
    eyes=np.zeros(shape,dtype=bool)
    # Fill the iris rows across their pupils, leaving the exterior eye rim.
    for x0,y0,x1,y1 in [(318,20,354,51),(369,22,385,45)]:
        for yy in range(y0,y1):
            xx=np.where(orange[yy,x0:x1])[0]+x0
            if len(xx):eyes[yy,xx.min():xx.max()+1]=True
    eyes &= body
    return {"body":body,"legs":legs,"tail":tail&legs,"rifle_and_hands":rifle,
            "pouches":pouches,"pouch":pouch,"scarf":scarf,"eyes":eyes,
            "feet":legs&(y>=280)}


def puff_pouch(a,mask,amount):
    if not amount:
        layer=np.zeros_like(a);layer[mask]=a[mask];return layer
    y,x=np.indices(mask.shape)
    # Anchor the top at the jaw; only the soft throat skin swells below it.
    sx=np.rint(334+(x-334)/(1+.02*amount)).astype(int)
    sy=np.rint(60+(y-60)/(1+.08*amount)).astype(int)
    sx=np.clip(sx,0,a.shape[1]-1);sy=np.clip(sy,0,a.shape[0]-1)
    dest=mask[sy,sx]
    layer=np.zeros_like(a);layer[dest]=a[sy[dest],sx[dest]]
    return layer


def build(name,a):
    is_reef=name=="reef_bulwark"
    masks=reef_masks(a) if is_reef else runner_masks(a)
    body,legs=masks["body"],masks["legs"]
    special=masks["jaw"] if is_reef else masks["pouch"]
    rigid=body&~special
    # Fill the pincer hinge only: padding the tip would leave a ghost of its
    # old outline when the jaw rotates away from the open gap.
    joint_seam=special&rect(body.shape,215,265,247,308) if is_reef else special
    moving_base,seam=backing(a,rigid,legs|joint_seam)
    fixed,fixed_seam=backing(a,legs,body)
    y,x=np.indices(body.shape)
    frames,checks,motion,effects,seams=[],[],[],[],[]
    for i,dy in enumerate(BREATH):
        moving=moving_base.copy();local_effect=np.zeros(body.shape,dtype=bool)
        angle=4 if is_reef and 2<=i<=4 else 0
        amount=0 if is_reef else [0,0,1,2,2,1,0,0][i]
        eye_glow=[0,.15,.65,1,.85,.4,.1,0][i] if is_reef else 0
        blink=not is_reef and i==4
        if eye_glow:
            brighten(moving,masks["eyes"],(175,255,255),eye_glow)
            local_effect|=masks["eyes"]
        if blink:
            # Copy mottled cheek skin over the irises, retaining the dark eye
            # rims. Both lids close with a narrow curved crease.
            for yy,xx in zip(*np.where(masks["eyes"])):
                near=xx<360
                cx,cy,rx,ry=(335,35,16,16) if near else (379,33,6,11)
                u=(xx-cx)/rx;v=(yy-cy)/ry
                sample_x=int(round(307+u*7));sample_y=int(round(47+v*6))
                moving[yy,xx,:3]=a[sample_y,sample_x,:3]
                crease=cy+1+int(round(2*(1-u*u)))
                if yy in (crease,crease+1):moving[yy,xx,:3]=a[70,340,:3]
            local_effect|=masks["eyes"]
        f=a.copy();f[body]=0
        if dy:f[fixed_seam]=fixed[fixed_seam]
        extra=shift(seam,dy=dy)&~legs
        f[extra]=shift(moving,dy=dy)[extra]
        if is_reef:
            pivot=(229,286)
            transformed=rotate(a,special,angle,pivot)
            joint=special&(((x-pivot[0])**2+(y-pivot[1])**2)<=16)
            if angle:stamp(f,a,joint,dy=dy)
            placed=stamp(f,moving,rigid,dy=dy)
            special_dest=stamp(f,transformed,transformed[:,:,3]>0,dy=dy)
        else:
            transformed=puff_pouch(a,special,amount)
            special_dest=stamp(f,transformed,transformed[:,:,3]>0,dy=dy)
            placed=stamp(f,moving,rigid,dy=dy)
            # The original mouth line and scarf cover the pouch at their edges.
            special_dest &= ~placed
        effect=shift(local_effect,dy=dy)
        visible_rigid=placed&~special_dest&~effect
        extra &= ~placed&~special_dest
        seam_visible=extra|((fixed_seam if dy else np.zeros(body.shape,dtype=bool))&~placed&~special_dest)
        visible_legs=legs&~placed&~special_dest&~extra
        expected=shift(a,dy=dy)
        foot_y=355 if is_reef else 280
        c={"rigid_body_mismatches":count_diff(f,expected,visible_rigid),
           "visible_legs_mismatches":count_diff(f,a,visible_legs),
           "feet_region_mismatches":count_diff(f,a,y>=foot_y),
           "rigid_body_clipped_pixels":int(rigid.sum()-placed.sum()),
           "special_transform_mismatches":count_diff(f,shift(transformed,dy=dy),special_dest),
           "visible_seam_pixels":int(seam_visible.sum())}
        for part in (("shield","shell") if is_reef else ("rifle_and_hands","scarf","pouches")):
            m=shift(masks[part],dy=dy)&~special_dest&~effect
            c[part+"_rigid_mismatches"]=count_diff(f,expected,m)
        allowed=body|placed|special_dest|seam_visible|effect
        c["unexplained_pixel_mismatches"]=count_diff(f,a,~allowed)
        frames.append(f);checks.append(c);effects.append(effect|special_dest);seams.append(seam_visible)
        motion.append({"frame":i+1,"body_dxy":[0,dy],"legs_dxy":[0,0],
            "upper_jaw_degrees":angle,"pouch_inflate_step":amount,"eye_glow":eye_glow,"blink":blink})
    return frames,masks,checks,motion,effects,seams


def review(name,a,frames,masks,effects,seams):
    h,w=a.shape[:2];colored=a.copy()
    groups=[("legs",(75,220,110)),("body",(35,210,240))]
    groups += [("shield",(255,185,55)),("jaw",(230,100,255))] if name=="reef_bulwark" else [("rifle_and_hands",(255,185,55)),("pouch",(230,100,255)),("scarf",(255,120,120))]
    for key,color in groups:colored[masks[key],:3]=color
    seg=Image.new("RGB",(w*2,h+24),(31,37,44));seg.paste(matte(a),(0,24));seg.paste(matte(colored),(w,24))
    ImageDraw.Draw(seg).text((8,6),"GREEN fixed legs | CYAN body | GOLD shield / rifle | PURPLE jaw / throat | PINK scarf",fill="white")
    seg.save(HERE/f"{name}_segmentation.png")
    for key,m in masks.items():Image.fromarray(m.astype(np.uint8)*255).save(HERE/f"{name}_mask_{key}.png")
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
    boxes={"jaw":(208,264,287,347),"waist":(298,182,421,263),"left_foot":(125,307,208,373),"eyes":(311,62,386,101)} if name=="reef_bulwark" else {"pouch":(311,49,366,88),"eyes":(315,15,386,54),"waist":(208,146,369,218)}
    for label,b in boxes.items():
        dw,dh=(b[2]-b[0])*4,(b[3]-b[1])*4
        plate=Image.new("RGB",(dw*3,dh+20),(31,37,44))
        for j,i in enumerate((0,3,4)):
            plate.paste(matte(frames[i]).crop(b).resize((dw,dh),Image.Resampling.NEAREST),(j*dw,20))
            ImageDraw.Draw(plate).text((j*dw+5,4),f"F{i+1}",fill="white")
        plate.save(HERE/f"{name}_detail_{label}.png")


def main():
    ap=argparse.ArgumentParser();ap.add_argument("--publish",action="store_true");args=ap.parse_args()
    report={}
    for name,offset in OFFSETS.items():
        source=ROOT/"assets/sprites/manyworlds"/f"{name}.png"
        old_strip=Image.open(source.with_name(name+"_idle.png"))
        master=Image.new("RGBA",(old_strip.width//8,old_strip.height))
        master.paste(Image.open(source).convert("RGBA"),offset)
        a=np.asarray(master);master.save(HERE/f"{name}_master.png")
        frames,masks,checks,motion,effects,seams=build(name,a)
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches") or key.endswith("clipped_pixels"):
                    assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 not clean base")
        assert np.array_equal(frames[7],a),(name,"F8 changed")
        strip=np.concatenate(frames,axis=1)
        assert (strip.shape[1],strip.shape[0])==old_strip.size
        Image.fromarray(strip).save(HERE/f"{name}_idle.png")
        assert np.array_equal(np.asarray(Image.open(HERE/f"{name}_idle.png")),strip)
        review(name,a,frames,masks,effects,seams)
        if args.publish:
            Image.fromarray(strip).save(HERE.parent/f"{name}_idle.png")
            assert np.array_equal(np.asarray(Image.open(HERE.parent/f"{name}_idle.png")),strip)
        (HERE/f"{name}_motion.json").write_text(json.dumps(motion,indent=2)+"\n")
        report[name]={"source":str(source.relative_to(ROOT)),"base_offset":list(offset),
            "master_sha256":hashlib.sha256(a.tobytes()).hexdigest(),"strip_size":[strip.shape[1],strip.shape[0]],
            "frame_1_exact_clean_base":True,"frame_8_exact":True,"old_idle_pixels_used":False,
            "frames":checks,"godot_run":False,"published":args.publish}
        print(f"{name}: rigid/feet/loop checks PASS; {strip.shape[1]}x{strip.shape[0]}; published={args.publish}")
    (HERE/"pair_10_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__":main()
