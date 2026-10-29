"""Breacher + Standard Guard: exact integer cut-outs from source frame 1.

No Godot. No edits outside art_incoming. Shared pixel operations are those used
by the approved preceding pair; its entry point is never run by this import.
"""
from pathlib import Path
import argparse
import hashlib
import json

import numpy as np
from PIL import Image, ImageDraw
from build_pair_05 import shift, poly, rect, stamp, backing, count_diff, save_mask, matte

HERE = Path(__file__).resolve().parent
OUT = HERE.parent
BREATH = [0,1,1,2,2,1,1,0]


def orange(a):
    rgb = a[:,:,:3].astype(float)
    return (rgb[:,:,0]>90)&(rgb[:,:,0]>rgb[:,:,1]*1.14)&(rgb[:,:,1]>20)&(rgb[:,:,2]<rgb[:,:,1]*.8)


def visor_orange(a):
    rgb = a[:,:,:3].astype(float)
    # Exclude warm metal reflections immediately below the visor's actual slit.
    return orange(a)&(rgb[:,:,0]>rgb[:,:,1]*1.5)&(rgb[:,:,2]<rgb[:,:,1]*.65)


def breacher_masks(a):
    ink = a[:,:,3]>0
    shape = ink.shape
    y,x = np.indices(shape)
    # Whole shield including its end caps and existing emblem-light pixels.
    shield = ink&poly(shape,[(331,58),(370,58),(416,68),(440,88),(440,329),
        (419,329),(409,326),(397,322),(384,318),(371,317),(363,314),
        (354,311),(346,306),(339,300),(335,296),(333,291),(331,284),
        (332,178),(325,151),(328,104)])
    torso = ink&poly(shape,[(95,0),(338,0),(338,171),(300,171),
        (286,157),(244,156),(226,161),(206,162),(198,176),(186,180),
        (186,210),(167,221),(139,218),(119,204),(95,174)])
    # The hanging codpiece is one armour plate attached to the belt, not a leg.
    codpiece = ink&poly(shape,[(242,148),(289,148),(289,191),(282,212),
                              (249,214),(244,194)])
    # Dark blue hanging fabric behind the hips belongs to the torso as well.
    cape_edge = ink&poly(shape,[(296,139),(327,139),(331,163),(332,194),
        (327,190),(323,181),(317,175),(309,171),(300,165),(294,160)])
    body = shield|torso|codpiece|cape_edge
    legs = ink&~body
    visor = body&visor_orange(a)&rect(shape,249,35,293,47)
    emblem = shield&orange(a)&rect(shape,344,127,435,206)
    feet = legs&(y>=315)
    return {"body":body,"legs":legs,"shield":shield,"visor":visor,
            "emblem":emblem,"feet":feet}


def guard_masks(a):
    ink = a[:,:,3]>0
    shape = ink.shape
    y,x = np.indices(shape)
    rifle = ink&poly(shape,[(216,103),(253,118),(285,125),(325,146),
        (357,157),(394,184),(399,205),(386,209),(364,200),(331,184),
        (313,179),(306,177),(301,180),(280,178),(278,171),
        (257,167),(246,168),(233,163),(218,140)])
    torso = ink&((y<165)|poly(shape,[(194,157),(249,157),(249,176),(194,176)])|
        poly(shape,[(249,159),(279,160),(279,180),(272,189),(252,188)]))
    body = torso|rifle
    legs = ink&~body
    visor = body&visor_orange(a)&rect(shape,256,34,302,48)
    rgb = a[:,:,:3].astype(float)
    cyan = (rgb[:,:,1]>75)&(rgb[:,:,1]>rgb[:,:,0]*1.2)&(rgb[:,:,2]>rgb[:,:,0]*1.2)
    rifle_light = rifle&cyan&(rect(shape,278,132,311,156)|rect(shape,278,159,304,181))
    feet = legs&(y>=278)
    return {"body":body,"legs":legs,"rifle_and_hands":rifle,"visor":visor,
            "rifle_lights":rifle_light,"feet":feet}


def light_mix(layer,mask,target,strength):
    if not np.any(mask): return
    rgb = layer[mask,:3].astype(float)
    # Retain shading in the source light surface, including at peak brightness.
    lit = np.minimum(255,rgb*.25+np.asarray(target)*.85)
    weights = np.asarray(strength)
    if weights.ndim:
        weights = weights[mask,None]
    layer[mask,:3] = np.rint(rgb*(1-weights)+lit*weights).astype(np.uint8)


def build(name,a):
    masks = breacher_masks(a) if name=="breacher" else guard_masks(a)
    body,legs = masks["body"],masks["legs"]
    # Only hidden 1-3px seam backing may be copied; original rigid pixels win.
    layer,extended,seam = backing(a,body,legs)
    # Breacher's source shield reaches the last cell row. Reversing the 2px
    # breath avoids clipping it; fixed leg backing covers the revealed waist.
    fixed_layer,fixed_extended,fixed_seam = backing(a,legs,body)
    offsets = [-n for n in BREATH] if name=="breacher" else BREATH
    frames,checks,metadata,effects,seams = [],[],[],[],[]
    y,x = np.indices(body.shape)
    sweep_centers = [None,None,254,265,277,288,None,None] if name=="breacher" else [None,None,260,272,284,296,None,None]
    for i,dy in enumerate(offsets):
        f = a.copy()
        f[body] = 0
        if dy<0:
            stamp(f,fixed_layer,fixed_extended)
        moving = layer.copy()
        effect = np.zeros(body.shape,dtype=bool)
        center = sweep_centers[i]
        if center is not None:
            distance = np.abs(x-center)
            patch = masks["visor"]&(distance<=6)
            strength = np.clip((7-distance)/3,0,1)*.95
            light_mix(moving,patch,(255,235,120),strength)
            effect |= shift(patch,dy=dy)
        pulse = 0
        if name=="breacher" and i in (3,4):
            pulse = .90 if i==3 else .75
            light_mix(moving,masks["emblem"],(255,234,135),pulse)
            effect |= shift(masks["emblem"],dy=dy)
        if name=="standard_guard" and i in (1,5):
            pulse = .95
            light_mix(moving,masks["rifle_lights"],(190,255,255),pulse)
            effect |= shift(masks["rifle_lights"],dy=dy)
        moved_original = stamp(f,moving,body,dy=dy)
        extra_dest = shift(seam,dy=dy)&~legs&~moved_original
        f[extra_dest] = shift(moving,dy=dy)[extra_dest]
        moved = moved_original|extra_dest
        assert int(moved_original.sum())==int(body.sum()),(name,i+1,"clipped body pixels")
        expected = shift(a,dy=dy)
        visible_legs = legs&~moved
        seam_visible = extra_dest.copy()
        if dy<0:
            seam_visible |= fixed_seam&~moved
        part = "shield" if name=="breacher" else "rifle_and_hands"
        rigid_part = shift(masks[part],dy=dy)&~effect
        c = {"body_rigid_mismatches":count_diff(f,expected,moved_original&~effect),
             "shield_or_rifle_rigid_mismatches":count_diff(f,expected,rigid_part),
             "stationary_visible_legs_mismatches":count_diff(f,a,visible_legs),
             "feet_mismatches":count_diff(f,a,masks["feet"]),
             "seam_pixels":int(seam_visible.sum()),"clipped_rigid_pixels":0}
        frames.append(f); checks.append(c); effects.append(effect); seams.append(seam_visible)
        metadata.append({"frame":i+1,"whole_upper_body_dxy":[0,dy],
            "shield_or_rifle_dxy":[0,dy],"visor_light_center_source_x":center,
            "emblem_pulse" if name=="breacher" else "cyan_rifle_flash":pulse})
    return frames,masks,checks,metadata,effects,seams


def review(name,a,frames,masks,effects,seams):
    h,w = a.shape[:2]
    colored = a.copy()
    for key,color in [("legs",(75,220,110)),("body",(35,210,240)),
                      ("shield" if name=="breacher" else "rifle_and_hands",(255,185,55))]:
        colored[masks[key],:3] = color
    seg = Image.new("RGB",(w*2,h+28),(31,37,44))
    seg.paste(matte(a),(0,28)); seg.paste(matte(colored),(w,28))
    ImageDraw.Draw(seg).text((8,7),"CYAN: body | GOLD: shield / rifle | GREEN: fixed legs",fill="white")
    seg.save(HERE/f"{name}_segmentation.png")
    foot_check = a.copy()
    bad = masks["feet"]&np.any(frames[3]!=a,axis=2)
    foot_check[bad] = (255,0,80,255)
    matte(foot_check).save(HERE/f"{name}_foot_check.png")
    for key,m in masks.items(): save_mask(f"{name}_mask_{key}",m)
    for i,(e,s) in enumerate(zip(effects,seams)):
        save_mask(f"{name}_effect_f{i+1}",e); save_mask(f"{name}_seam_f{i+1}",s)
    plate = Image.new("RGB",(w*4,(h+24)*2),(31,37,44))
    for i,f in enumerate(frames):
        px,py=i%4*w,i//4*(h+24)
        plate.paste(matte(f),(px,py+24))
        ImageDraw.Draw(plate).text((px+8,py+6),f"F{i+1}",fill="white")
    plate.save(HERE/f"{name}_contact.png")
    Image.blend(matte(frames[0]),matte(frames[3]),.5).save(HERE/f"{name}_blend_f1_f4.png")
    for tag,scale in [("native",1),("scale037",.37)]:
        views=[]
        for i,f in enumerate(frames):
            im=matte(f)
            if scale!=1: im=im.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST)
            v=Image.new("RGB",(im.width,im.height+24),(31,37,44)); v.paste(im,(0,24))
            ImageDraw.Draw(v).text((8,6),f"F{i+1}",fill="white"); views.append(v)
        views[0].save(HERE/f"{name}_{tag}.gif",save_all=True,append_images=views[1:],
                      duration=[120,130]*4,loop=0,disposal=2)
        if scale!=1:
            contact=Image.new("RGB",(views[0].width*8,views[0].height),(31,37,44))
            for i,v in enumerate(views): contact.paste(v,(i*v.width,0))
            contact.save(HERE/f"{name}_{tag}_contact.png")
    boxes = {"visor":(225,25,302,57),"waist":(160,140,335,220),"shield":(332,120,437,215)} if name=="breacher" else {
        "visor":(247,29,310,54),"rifle":(230,125,397,208),"waist":(185,155,327,215)}
    for label,b in boxes.items():
        dw,dh=(b[2]-b[0])*4,(b[3]-b[1])*4
        plate=Image.new("RGB",(dw*3,dh+20),(31,37,44))
        for j,i in enumerate((0,3,5)):
            plate.paste(matte(frames[i]).crop(b).resize((dw,dh),Image.Resampling.NEAREST),(j*dw,20))
            ImageDraw.Draw(plate).text((j*dw+5,4),f"F{i+1}",fill="white")
        plate.save(HERE/f"{name}_detail_{label}.png")


def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--publish",action="store_true"); args=ap.parse_args()
    report={}
    for name in ("breacher","standard_guard"):
        a=np.array(Image.open(HERE/f"{name}_master.png").convert("RGBA"))
        frames,masks,checks,metadata,effects,seams=build(name,a)
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches"): assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 changed")
        assert np.array_equal(frames[7],a),(name,"F8 changed")
        strip=np.concatenate(frames,axis=1)
        Image.fromarray(strip).save(HERE/f"{name}_idle.png")
        assert np.array_equal(np.array(Image.open(HERE/f"{name}_idle.png")),strip)
        if args.publish:
            Image.fromarray(strip).save(OUT/f"{name}_idle.png")
            assert np.array_equal(np.array(Image.open(OUT/f"{name}_idle.png")),strip)
        review(name,a,frames,masks,effects,seams)
        (HERE/f"{name}_motion.json").write_text(json.dumps(metadata,indent=2)+"\n")
        report[name]={"source":f"assets/sprites/terran/{name}_idle.png",
            "source_master_sha256":hashlib.sha256(a.tobytes()).hexdigest(),
            "strip_size":[strip.shape[1],strip.shape[0]],"frame_1_exact":True,
            "frame_8_exact":True,"frames":checks,"godot_run":False}
        print(f"{name}: rigid/feet checks PASS; {strip.shape[1]}x{strip.shape[0]}; published={args.publish}")
    (HERE/"pair_06_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__": main()
