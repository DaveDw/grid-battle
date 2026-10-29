"""Spore Keeper / Glasswing: clean-base cut-outs, nearest rotations, no Godot."""
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
from build_pair_09 import rotate

BREATH=[0,1,1,2,2,1,1,0]
OFFSETS={"spore_keeper":(185,2),"glasswing":(254,4)}
WINGS={"wing_ul":((369,103),-3),"wing_ll":((359,129),-3),
       "wing_ur":((454,132),3),"wing_lr":((437,157),3)}
ANTENNAE={"antenna_left":((460,68),-3),"antenna_right":((470,73),3)}


def spore_masks(a):
    ink=a[:,:,3]>0;shape=ink.shape;y,x=np.indices(shape)
    orbs=ink&(rect(shape,506,174,536,204)|rect(shape,506,220,536,244)|rect(shape,503,208,512,218))
    upper=ink&(y<277)
    hand=ink&poly(shape,[(277,246),(327,247),(342,259),(341,282),
        (330,294),(303,294),(286,282)])
    left_rag=ink&poly(shape,[(194,263),(234,262),(235,284),(225,298),
        (226,307),(215,318),(197,315),(190,298)])
    left_rag |= ink&poly(shape,[(231,265),(255,265),(255,276),
        (251,282),(251,298),(243,300),(235,294),(234,282),(229,276)])
    middle_rag=ink&poly(shape,[(329,265),(398,265),(403,283),(395,304),
        (378,308),(379,332),(366,350),(344,352),(340,342),(330,334),(328,314),
        (314,304),(314,289)])
    right_rag=ink&poly(shape,[(483,272),(507,267),(527,293),(542,326),
        (541,342),(524,333),(507,350),(486,357),(466,351),(459,338),
        (474,331),(479,314),(479,285)])
    launcher=ink&poly(shape,[(303,221),(441,217),(469,226),(484,245),
        (498,267),(486,289),(461,294),(428,287),(384,282),(344,279),
        (313,277),(299,257)])
    rgb=a[:,:,:3].astype(float)
    green=(rgb[:,:,1]>100)&(rgb[:,:,1]>rgb[:,:,0]*1.22)&(rgb[:,:,1]>rgb[:,:,2]*1.18)
    energy=ink&green&rect(shape,465,235,539,294)
    body=(upper|hand|left_rag|middle_rag|right_rag|launcher|energy)&~orbs
    legs=ink&~body&~orbs
    glow=body&green&rect(shape,455,235,539,294)
    return {"body":body,"legs":legs,"orbs":orbs,"launcher":launcher&body,
        "caps":body&(y<112),"cloth":left_rag|middle_rag|right_rag,
        "glow":glow,"feet":legs&(y>=360)}


def glass_masks(a):
    ink=a[:,:,3]>0;shape=ink.shape;y,x=np.indices(shape)
    rgb=a[:,:,:3].astype(float);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    # Include the slightly warm white outlines as well as the blue interiors.
    blue=(b>=r-22)&(g>=r-22)
    regions={
        "wing_ul":[(258,46),(285,49),(339,71),(365,85),(369,90),
            (363,99),(358,108),(352,117),(342,123),(318,124),
            (292,110),(275,87),(258,65)],
        "wing_ll":[(350,121),(366,131),(376,141),(371,158),(352,175),
            (336,191),(328,199),(310,214),(280,234),(253,237),
            (253,218),(267,191),(291,160),(322,138)],
        "wing_ur":[(454,113),(481,114),(513,121),(542,127),(545,141),
            (516,155),(489,160),(464,157),(448,141)],
        "wing_lr":[(434,148),(447,156),(458,175),(482,186),(487,206),
            (479,227),(470,235),(449,220),(435,198),(424,170)]}
    masks={k:ink&blue&poly(shape,v) for k,v in regions.items()}
    # At the exposed panel ends every opaque pixel belongs to the wing,
    # including dark outlines whose hue differs from the glass interior.
    masks["wing_ul"] |= ink&poly(shape,regions["wing_ul"])&(x<350)
    masks["wing_ll"] |= ink&poly(shape,regions["wing_ll"])&(x<291)
    masks["wing_ur"] |= ink&poly(shape,regions["wing_ur"])&(x>481)
    left_arm=poly(shape,[(352,121),(371,127),(374,140),(353,153),
        (350,163),(339,178),(328,189),(328,193),(344,203),(347,215),
        (338,223),(312,222),(297,215),(295,206),(296,196),(300,185),
        (305,174),(310,160),(321,145),(337,138)])
    holster_shape=poly(shape,[(347,170),(358,171),(369,180),(369,188),
        (359,193),(357,208),(349,213),(340,209),(341,195),(341,183)])
    left_arm=left_arm&((r>=b-2)|(g<r-10))
    masks["wing_ll"] &= ~left_arm&~holster_shape
    # The cyan breastplate ornament above the lower wing is torso armour.
    masks["wing_lr"] &= ~rect(shape,420,145,439,157)
    wings=np.logical_or.reduce(list(masks.values()))
    blades=ink&(poly(shape,[(311,198),(333,199),(340,218),(351,242),
        (362,277),(376,307),(369,316),(352,302),(333,274),(322,248),
        (316,227),(309,216)])|poly(shape,[(471,204),(492,202),(504,229),
        (509,258),(518,293),(521,318),(506,317),(488,281),(477,248)])|
        poly(shape,[(514,192),(530,188),(538,209),(548,235),(564,254),
        (569,286),(553,279),(531,251),(524,228)]))
    left_leg=ink&poly(shape,[(341,191),(365,185),(387,194),(386,216),
        (372,244),(359,262),(337,275),(326,305),(321,322),(340,333),
        (339,344),(280,344),(285,321),(295,288),(304,267),(333,260),
        (338,245),(332,233),(336,210)])
    right_leg=ink&poly(shape,[(421,192),(439,194),(453,214),(477,241),
        (472,260),(452,268),(440,281),(449,304),(461,318),(486,332),
        (496,344),(426,344),(430,325),(432,315),(422,299),(413,284),
        (416,271),(431,258),(443,251),(423,243),(413,227),(408,207)])
    holster=ink&holster_shape
    legs=((left_leg|right_leg)&~wings&~blades&~holster)|(ink&(y>=320))
    legs |= ink&rect(shape,440,300,490,320)
    body=ink&~legs
    left=ink&poly(shape,[(381,0),(466,0),(466,53),(465,69),(458,69),
        (457,52),(447,40),(435,29),(417,19),(398,30),(390,43),(381,42)])
    right=ink&poly(shape,[(468,0),(495,0),(495,76),(479,82),
        (470,75),(465,69),(467,58),(470,40)])
    left |= ink&rect(shape,380,0,466,55)
    right |= ink&(rect(shape,466,0,505,55)|rect(shape,480,55,505,80))
    masks.update({"body":body,"legs":legs,"blades":blades&~wings,"holster":holster&~wings,
        "antenna_left":left,"antenna_right":right,"feet":legs&(y>=320),
        "scarf":body&~wings&poly(shape,[(366,71),(403,67),(424,96),(459,106),
            (469,122),(449,143),(419,136),(389,117),(372,96)])})
    return masks


def spore_puff(shape,frame,occupied):
    out=np.zeros((*shape,4),dtype=np.uint8)
    if frame not in (2,3,4,5):return out
    age=frame-2;opacity=[150,240,160,65][age]
    # A single emission from three caps; every particle rises and fades.
    seeds=[(300,42,0),(316,33,1),(436,50,-1),(447,48,1),(228,92,-1)]
    for j,(px,py,drift) in enumerate(seeds):
        cx=px+drift*age;cy=py-3-age*3
        rad=2 if j%2==0 else 1
        for dy in range(-rad,rad+1):
            for dx in range(-rad,rad+1):
                if abs(dx)+abs(dy)>rad:continue
                xx,yy=cx+dx,cy+dy
                if 0<=xx<shape[1] and 0<=yy<shape[0] and not occupied[yy,xx]:
                    alpha=opacity if dx==0 and dy==0 else round(opacity*.55)
                    out[yy,xx]=(210,239,102,alpha)
    return out


def build_spore(a):
    masks=spore_masks(a);body,legs,orbs=[masks[k] for k in ("body","legs","orbs")]
    moving,seam=backing(a,body,legs);fixed,fixed_seam=backing(a,legs,body)
    y,x=np.indices(body.shape);frames=[];checks=[];motion=[];effects=[];seams=[]
    for i,dy in enumerate(BREATH):
        part=moving.copy();pulse=[0,.15,.55,.85,.65,.3,.1,0][i]
        if pulse:
            # Exposure preserves each glow's source texture and rim.
            g=masks["glow"]
            part[g,:3]=np.minimum(255,np.rint(a[g,:3]*(1+pulse*.6))).astype(np.uint8)
        f=a.copy();f[body|orbs]=0
        if dy:f[fixed_seam]=fixed[fixed_seam]
        extra=shift(seam,dy=dy)&~legs
        f[extra]=shift(part,dy=dy)[extra]
        placed=stamp(f,part,body,dy=dy)
        orb_dy=-[0,1,2,3,3,2,1,0][i]
        orb_dest=stamp(f,a,orbs,dy=orb_dy)
        puff=spore_puff(body.shape,i,f[:,:,3]>0);p=puff[:,:,3]>0;f[p]=puff[p]
        glow=shift(masks["glow"],dy=dy) if pulse else np.zeros(body.shape,dtype=bool)
        seam_visible=(extra|(fixed_seam if dy else False))&~placed&~orb_dest
        c={"rigid_body_mismatches":count_diff(f,shift(a,dy=dy),placed&~glow),
            "visible_legs_mismatches":count_diff(f,a,legs&~placed&~extra),
            "feet_region_mismatches":count_diff(f,a,y>=360),
            "orbs_translation_mismatches":count_diff(f,shift(a,dy=orb_dy),orb_dest),
            "body_clipped_pixels":int(body.sum()-placed.sum()),
            "orb_clipped_pixels":int(orbs.sum()-orb_dest.sum()),
            "visible_seam_pixels":int(seam_visible.sum()),"puff_pixels":int(p.sum())}
        for name in ("caps","launcher","cloth"):
            c[name+"_rigid_mismatches"]=count_diff(f,shift(a,dy=dy),shift(masks[name],dy=dy)&~glow)
        allowed=body|orbs|placed|orb_dest|seam_visible|p
        c["unexplained_pixel_mismatches"]=count_diff(f,a,~allowed)
        frames.append(f);checks.append(c);effects.append(glow|orb_dest|p);seams.append(seam_visible)
        motion.append({"frame":i+1,"body_dxy":[0,dy],"legs_dxy":[0,0],
            "orb_dxy":[0,orb_dy],"launcher_glow":pulse,"puff_age":i-2 if 2<=i<=5 else None})
    return frames,masks,checks,motion,effects,seams


def build_glass(a):
    masks=glass_masks(a);body,legs=masks["body"],masks["legs"]
    wings=np.logical_or.reduce([masks[k] for k in WINGS])
    antennae=masks["antenna_left"]|masks["antenna_right"]
    rigid=body&~wings&~antennae
    moving,seam=backing(a,rigid,legs);fixed,fixed_seam=backing(a,legs,body)
    # Extend the visible wing cut-outs at most three source pixels underneath
    # the foreground limbs. These copied joint pixels remain hidden at rest.
    # No exterior wing edge, vein or visible source pixel is repainted.
    wing_layers={};wing_seams={}
    for k in WINGS:
        layer=np.zeros_like(a);layer[masks[k]]=a[masks[k]]
        grown=masks[k].copy();joint=np.zeros(body.shape,dtype=bool)
        for distance in range(3):
            old=grown.copy();old_layer=layer.copy()
            for dx,dy in ((0,-1),(0,1),(-1,0),(1,0)):
                m=shift(old,dx,dy)&(rigid|legs)&~grown
                layer[m]=shift(old_layer,dx,dy)[m];grown|=m;joint|=m
        wing_layers[k]=layer;wing_seams[k]=joint
        masks[k+"_joint_seam"]=joint
        assert count_diff(layer,a,masks[k])==0,(k,"source wing changed")
    y,x=np.indices(body.shape);frames=[];checks=[];motion=[];effects=[];seams=[]
    for i,dy in enumerate(BREATH):
        f=a.copy();f[body]=0
        if dy:f[fixed_seam]=fixed[fixed_seam]
        transformed={};dest={};angles={}
        for k,(pivot,angle) in WINGS.items():
            angles[k]=angle if i%2 else 0
            transformed[k]=rotate(wing_layers[k],wing_layers[k][:,:,3]>0,angles[k],pivot)
            dest[k]=stamp(f,transformed[k],transformed[k][:,:,3]>0,dy=dy)
        f[legs]=a[legs]
        extra=shift(seam,dy=dy)&~legs
        f[extra]=shift(moving,dy=dy)[extra]
        placed=stamp(f,moving,rigid,dy=dy)
        for k,(pivot,angle) in ANTENNAE.items():
            angles[k]=angle if 2<=i<=4 else 0
            transformed[k]=rotate(a,masks[k],angles[k],pivot)
            dest[k]=stamp(f,transformed[k],transformed[k][:,:,3]>0,dy=dy)
        special_dest=np.logical_or.reduce(list(dest.values()))
        ant_dest=dest["antenna_left"]|dest["antenna_right"]
        seam_visible=(extra|(fixed_seam if dy else False))&~placed&~special_dest
        wing_joint_visible=np.zeros(body.shape,dtype=bool)
        for k,(pivot,_) in WINGS.items():
            joint_layer=np.zeros_like(a);joint_layer[wing_seams[k]]=a[wing_seams[k]]
            rotated_joint=rotate(joint_layer,wing_seams[k],angles[k],pivot)
            wing_joint_visible |= shift(rotated_joint[:,:,3]>0,dy=dy)&~placed&~legs&~ant_dest
        seam_visible |= wing_joint_visible
        visible_legs=legs&~placed&~special_dest&~extra
        c={"rigid_body_mismatches":count_diff(f,shift(a,dy=dy),placed&~ant_dest),
            "visible_legs_mismatches":count_diff(f,a,visible_legs),
            "feet_region_mismatches":count_diff(f,a,y>=320),
            "body_clipped_pixels":int(rigid.sum()-placed.sum()),
            "visible_seam_pixels":int(seam_visible.sum())}
        for j,k in enumerate(dest):
            above=np.logical_or.reduce(list(dest.values())[j+1:]) if j+1<len(dest) else np.zeros(body.shape,dtype=bool)
            visible=dest[k]&~above
            if k in WINGS:visible &= ~placed&~extra&~legs
            c[k+"_transform_mismatches"]=count_diff(f,shift(transformed[k],dy=dy),visible)
        for k in ("blades","holster","scarf"):
            c[k+"_rigid_mismatches"]=count_diff(f,shift(a,dy=dy),shift(masks[k],dy=dy)&~ant_dest)
        allowed=body|placed|special_dest|seam_visible
        c["unexplained_pixel_mismatches"]=count_diff(f,a,~allowed)
        frames.append(f);checks.append(c);effects.append(special_dest);seams.append(seam_visible)
        motion.append({"frame":i+1,"body_dxy":[0,dy],"legs_dxy":[0,0],"angles_degrees":angles})
    return frames,masks,checks,motion,effects,seams


def review(name,a,frames,masks,effects,seams):
    h,w=a.shape[:2];colored=a.copy()
    groups=[("legs",(75,220,110)),("body",(35,210,240))]
    groups += [("orbs",(230,100,255)),("launcher",(255,185,55)),("cloth",(255,120,120))] if name=="spore_keeper" else [("wing_ul",(220,90,255)),("wing_ll",(170,80,230)),("wing_ur",(255,130,230)),("wing_lr",(220,50,160)),("blades",(255,185,55)),("antenna_left",(255,120,120)),("antenna_right",(255,120,120))]
    for key,color in groups:colored[masks[key],:3]=color
    seg=Image.new("RGB",(w*2,h+24),(31,37,44));seg.paste(matte(a),(0,24));seg.paste(matte(colored),(w,24))
    ImageDraw.Draw(seg).text((8,6),"GREEN fixed legs | CYAN body | GOLD weapon | PURPLE moving special | PINK cloth / antennae",fill="white")
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
    boxes={"waist":(204,260,493,343),"orbs":(453,171,542,297),"caps":(212,6,463,112)} if name=="spore_keeper" else {"left_wings":(254,46,379,236),"right_wings":(420,108,549,238),"antennae":(384,0,497,91),"waist":(328,174,466,250)}
    for label,b in boxes.items():
        dw,dh=(b[2]-b[0])*3,(b[3]-b[1])*3
        plate=Image.new("RGB",(dw*3,dh+20),(31,37,44))
        for j,i in enumerate((0,3,4)):
            plate.paste(matte(frames[i]).crop(b).resize((dw,dh),Image.Resampling.NEAREST),(j*dw,20))
            ImageDraw.Draw(plate).text((j*dw+5,4),f"F{i+1}",fill="white")
        plate.save(HERE/f"{name}_detail_{label}.png")


def main():
    ap=argparse.ArgumentParser();ap.add_argument("--publish",action="store_true");args=ap.parse_args();report={}
    for name,offset in OFFSETS.items():
        source=ROOT/"assets/sprites/manyworlds"/f"{name}.png"
        old_strip=Image.open(source.with_name(name+"_idle.png"))
        master=Image.new("RGBA",(old_strip.width//8,old_strip.height))
        master.paste(Image.open(source).convert("RGBA"),offset)
        a=np.asarray(master);master.save(HERE/f"{name}_master.png")
        frames,masks,checks,motion,effects,seams=(build_spore if name=="spore_keeper" else build_glass)(a)
        review(name,a,frames,masks,effects,seams)
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches") or key.endswith("clipped_pixels"):assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 not clean base")
        if name=="spore_keeper":assert np.array_equal(frames[7],a),(name,"F8 changed")
        strip=np.concatenate(frames,axis=1);assert (strip.shape[1],strip.shape[0])==old_strip.size
        Image.fromarray(strip).save(HERE/f"{name}_idle.png")
        assert np.array_equal(np.asarray(Image.open(HERE/f"{name}_idle.png")),strip)
        if args.publish:
            Image.fromarray(strip).save(HERE.parent/f"{name}_idle.png")
            assert np.array_equal(np.asarray(Image.open(HERE.parent/f"{name}_idle.png")),strip)
        (HERE/f"{name}_motion.json").write_text(json.dumps(motion,indent=2)+"\n")
        report[name]={"source":str(source.relative_to(ROOT)),"base_offset":list(offset),
            "master_sha256":hashlib.sha256(a.tobytes()).hexdigest(),"strip_size":[strip.shape[1],strip.shape[0]],
            "frame_1_exact_clean_base":True,"old_idle_pixels_used":False,"frames":checks,
            "loop":"F8 exact F1" if name=="spore_keeper" else "F8/F1 continues alternating wing buzz; body and antennae return to base",
            "godot_run":False,"published":args.publish}
        print(f"{name}: rigid/feet/loop checks PASS; {strip.shape[1]}x{strip.shape[0]}; published={args.publish}")
    (HERE/"pair_11_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__":main()
