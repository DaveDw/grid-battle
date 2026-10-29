"""Pair 05: deterministic cut-out idles, using imported frame-1 masters.

No Godot invocation. No writes outside art_incoming. Rigid translation is exact;
the Siege Rig's specified 2-degree barrel tick uses one nearest-neighbour rigid
rotation about a fixed pivot, never a warp or redraw.
"""
from pathlib import Path
import argparse
import hashlib
import json

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
OUT = HERE.parent
BREATH = [0, 1, 1, 2, 2, 1, 1, 0]
SETTLE = [0, 1, 2, 2, 2, 1, 1, 0]
ANGLE = [0, 0, 0, 0, 2, 2, 0, 0]
PIVOT = (196, 99)


def shift(a, dx=0, dy=0):
    h,w = a.shape[:2]
    out = np.zeros_like(a)
    out[max(0,dy):min(h,h+dy),max(0,dx):min(w,w+dx)] = a[
        max(0,-dy):min(h,h-dy),max(0,-dx):min(w,w-dx)]
    return out


def poly(shape, points):
    im = Image.new("1",(shape[1],shape[0]))
    ImageDraw.Draw(im).polygon(points,fill=1)
    return np.asarray(im,dtype=bool)


def rect(shape,x0,y0,x1,y1):
    y,x = np.indices(shape)
    return (x>=x0)&(x<x1)&(y>=y0)&(y<y1)


def stamp(dst,src,mask,dx=0,dy=0):
    m = shift(mask,dx,dy)
    dst[m] = shift(src,dx,dy)[m]
    return m


def backing(master,body,occluder):
    layer = master.copy()
    extra = np.zeros(body.shape,dtype=bool)
    for distance in (1,2,3):
        m = shift(body,dy=-distance)&occluder&~extra
        layer[m] = shift(master,dy=-distance)[m]
        extra |= m
    return layer,body|extra,extra


def rotate_layer(master,mask,angle):
    layer = np.zeros_like(master)
    layer[mask] = master[mask]
    if angle:
        layer = np.asarray(Image.fromarray(layer).rotate(
            angle,resample=Image.Resampling.NEAREST,center=PIVOT,expand=False)).copy()
    return layer,layer[:,:,3]>0


def brightened(src,mask,strength=1):
    out = src.copy()
    target = np.array([255,237,146],dtype=float)
    out[mask,:3] = np.rint(src[mask,:3]*(1-strength)+target*strength).astype(np.uint8)
    return out


def siege_masks(a):
    ink = a[:,:,3]>0
    h,w = ink.shape
    y,x = np.indices(ink.shape)
    # The two detached source smoke puffs are separate from the metal artwork.
    smoke = ink&(rect(ink.shape,142,27,156,42)|rect(ink.shape,167,34,179,46))
    barrel = ink&poly(ink.shape,[(182,67),(220,31),(255,0),(286,0),
        (309,19),(310,61),(280,86),(247,105),(197,105),(183,96)])
    barrel &= ~((x<183)&(y>60))
    center = poly(ink.shape,[(176,207),(277,207),(267,254),(252,275),
                            (181,275),(179,254)])
    cannon = poly(ink.shape,[(312,168),(350,174),(414,214),(414,252),
                            (395,265),(367,256),(340,235),(320,217),(309,205)])
    upper = ink&((y<214)|center|cannon)&~smoke
    # Keep the entire left thigh plate AND its curved upper hinge on the leg.
    # A horizontal crop at y=214 would split the top of this rigid armour plate.
    leg_cap = ink&poly(ink.shape,[(118,198),(135,195),(154,196),(166,200),
        (169,211),(178,218),(179,231),(173,233),(172,216),(163,214),(117,214)])
    upper &= ~leg_cap
    body = upper&~barrel
    legs = ink&~upper&~smoke
    front = body&rect(ink.shape,80,64,183,180)
    rgb = a[:,:,:3].astype(int)
    orange = (rgb[:,:,0]>100)&(rgb[:,:,0]>rgb[:,:,1]*1.28)&(rgb[:,:,1]>20)&(rgb[:,:,2]<85)
    boxes = [(85,100,112,116),(85,119,112,140),(115,93,143,110),
             (115,114,143,134),(145,81,181,104),(145,108,181,127)]
    bands = [body&orange&rect(ink.shape,*box) for box in boxes]
    return {"body":body,"barrel":barrel,"legs":legs,"smoke":smoke,
            "canister_foreground":front},bands


def build_siege(a):
    masks,bands = siege_masks(a)
    body,m = masks["body"],masks["barrel"]
    body_layer,extended,seam = backing(a,body,m)
    frames,checks,metadata,effects = [],[],[],[]
    # One old puff fades while its replacement rises into the same loop pose.
    smoke_y = [0,-1,-2,-3,-4,3,1,0]
    smoke_alpha = [255,220,160,90,20,65,170,255]
    for i,(dy,angle) in enumerate(zip(SETTLE,ANGLE)):
        f = a.copy()
        f[body|m|masks["smoke"]] = 0
        effect = np.zeros(body.shape,dtype=bool)
        layer = body_layer.copy()
        active_band = i-1 if 1<=i<=6 else None
        if active_band is not None:
            layer = brightened(layer,bands[active_band],.90)
            effect |= shift(bands[active_band],dy=dy)
        stamp(f,layer,extended,dy=dy)
        barrel,barrel_mask = rotate_layer(a,m,angle)
        moved_barrel = stamp(f,barrel,barrel_mask,dy=dy)
        front = stamp(f,layer,masks["canister_foreground"],dy=dy)
        stamp(f,a,masks["legs"])
        puff = a.copy()
        puff[masks["smoke"],3] = smoke_alpha[i]
        smoke_dest = stamp(f,puff,masks["smoke"],dy=smoke_y[i])
        effect |= smoke_dest
        moved_body = shift(body,dy=dy)&~moved_barrel&~smoke_dest&~masks["legs"]
        moved_body |= front
        body_check = moved_body&~effect
        expected_body = shift(a,dy=dy)
        barrel_check = moved_barrel&~front&~smoke_dest
        expected_barrel = shift(barrel,dy=dy)
        legs = masks["legs"]
        seam_visible = shift(seam,dy=dy)&~moved_barrel&~front&~legs
        result = {
            "body_rigid_mismatches": count_diff(f,expected_body,body_check),
            "barrel_rigid_transform_mismatches":count_diff(f,expected_barrel,barrel_check),
            "stationary_legs_mismatches":count_diff(f,a,legs),
            "feet_mismatches":count_diff(f,a,rect(body.shape,0,285,a.shape[1],a.shape[0])),
            "seam_pixels":int(seam_visible.sum())}
        frames.append(f); checks.append(result); effects.append(effect)
        metadata.append({"frame":i+1,"hull_mortar_cannon_dy":dy,
            "barrel_degrees_up":angle,"barrel_pivot":PIVOT,
            "lit_canister_band":active_band,"smoke_dy":smoke_y[i],
            "smoke_alpha":smoke_alpha[i]})
        save_mask(f"siege_rig_seam_f{i+1}",seam_visible)
    return frames,masks,checks,metadata,effects


def claim_masks(a):
    ink = a[:,:,3]>0
    shape = ink.shape
    left_leg = ink&poly(shape,[(246,181),(279,185),(282,229),(276,256),
        (280,281),(267,292),(261,316),(258,352),(168,352),(168,330),
        (179,314),(181,286),(188,266),(197,262),(201,240),
        (216,231),(216,209),(229,188)])
    right_leg = ink&poly(shape,[(344,188),(366,202),(370,231),(371,265),
        (369,283),(363,296),(361,319),(376,337),(400,352),(300,352),
        (300,333),(316,315),(320,296),(334,287),(339,269),(342,245)])
    legs = left_leg|right_leg
    body = ink&~legs
    # Glows stay inside the four gold knuckle faces, never in the silhouette.
    faces = [poly(shape,pts) for pts in [
        [(224,147),(231,148),(238,155),(237,166),(230,166),(222,158)],
        [(214,159),(221,158),(232,168),(230,178),(221,178),(213,170)],
        [(207,172),(216,174),(223,180),(222,189),(213,189),(205,182)],
        [(203,183),(212,186),(218,193),(214,200),(205,198),(199,191)]]]
    knuckles = body&np.logical_or.reduce(faces)
    rgb = a[:,:,:3].astype(int)
    # Dark ridges between fingers stay exact, so the glow does not merge fingers.
    knuckles &= (rgb[:,:,1]>95)&(rgb[:,:,0]>rgb[:,:,1]*1.12)&(rgb[:,:,2]<rgb[:,:,1]*.9)
    eyes = body&(poly(shape,[(288,37),(299,37),(299,39),(289,39)])|
                  poly(shape,[(306,37),(311,37),(310,39),(306,39)]))
    return {"body_cape_armour":body,"left_leg":left_leg,"right_leg":right_leg,
            "legs":legs,"knuckle_lights":knuckles,"blink":eyes}


def build_claim(a):
    masks = claim_masks(a)
    body,legs = masks["body_cape_armour"],masks["legs"]
    base,extended,seam = backing(a,body,legs)
    glow = [0,0,.40,1.0,.75,.30,0,0]
    frames,checks,metadata,effects = [],[],[],[]
    for i,dy in enumerate(BREATH):
        f = a.copy()
        f[body] = 0
        layer = base.copy()
        effect = np.zeros(body.shape,dtype=bool)
        if glow[i]:
            mask = masks["knuckle_lights"]
            rgb = a[mask,:3].astype(float)
            lit = np.minimum(255,rgb*1.15+np.array([55,64,40]))
            layer[mask,:3] = np.rint(rgb*(1-glow[i])+lit*glow[i]).astype(np.uint8)
            effect |= shift(masks["knuckle_lights"],dy=dy)
        if i==4:
            eye = masks["blink"]
            layer[eye] = shift(a,dy=-3)[eye]
            y,x = np.indices(body.shape)
            layer[eye&(y==38)] = (89,59,42,255)
            effect |= shift(eye,dy=dy)
        stamp(f,layer,extended,dy=dy)
        # Cape is behind the legs. Their pixels are copied back without change.
        stamp(f,a,legs)
        moved = shift(body,dy=dy)&~legs
        seam_visible = shift(seam,dy=dy)&~legs
        expected = shift(a,dy=dy)
        feet = legs&rect(body.shape,0,318,a.shape[1],a.shape[0])
        result = {"body_cape_armour_rigid_mismatches":count_diff(f,expected,moved&~effect),
            "stationary_legs_mismatches":count_diff(f,a,legs),
            "feet_mismatches":count_diff(f,a,feet),"seam_pixels":int(seam_visible.sum())}
        frames.append(f); checks.append(result); effects.append(effect)
        metadata.append({"frame":i+1,"body_cape_armour_dy":dy,
            "knuckle_glow_strength":glow[i],"blink":i==4})
        save_mask(f"claim_lord_seam_f{i+1}",seam_visible)
    return frames,masks,checks,metadata,effects


def count_diff(actual,expected,mask):
    return int(np.count_nonzero(np.any(actual[mask]!=expected[mask],axis=1)))


def save_mask(name,m):
    Image.fromarray(m.astype(np.uint8)*255).save(HERE/f"{name}.png")


def matte(a):
    im = Image.fromarray(a)
    bg = Image.new("RGBA",im.size,(31,37,44,255))
    bg.alpha_composite(im)
    return bg.convert("RGB")


def review(name,a,frames,masks,effects):
    h,w = a.shape[:2]
    palette = [(30,210,240),(255,175,45),(65,225,110),(220,90,200),
               (100,140,250),(220,220,220)]
    annotated = a.copy()
    groups = [k for k in masks if k not in ("legs","canister_foreground","knuckle_lights","blink")]
    for i,key in enumerate(groups):
        annotated[masks[key],:3] = palette[i%len(palette)]
    seg = Image.new("RGB",(w*2,h+32),(31,37,44))
    seg.paste(matte(a),(0,32)); seg.paste(matte(annotated),(w,32))
    for i,key in enumerate(groups):
        ImageDraw.Draw(seg).text((8+i*170,8),key,fill=palette[i%len(palette)])
    seg.save(HERE/f"{name}_segmentation.png")
    for key,m in masks.items(): save_mask(f"{name}_mask_{key}",m)
    for i,m in enumerate(effects): save_mask(f"{name}_effect_f{i+1}",m)
    plate = Image.new("RGB",(w*4,(h+24)*2),(31,37,44))
    for i,f in enumerate(frames):
        px,py = i%4*w,i//4*(h+24)
        plate.paste(matte(f),(px,py+24))
        ImageDraw.Draw(plate).text((px+8,py+5),f"F{i+1}",fill="white")
    plate.save(HERE/f"{name}_contact.png")
    Image.blend(matte(frames[0]),matte(frames[3]),.5).save(HERE/f"{name}_blend_f1_f4.png")
    Image.blend(matte(frames[0]),matte(frames[4]),.5).save(HERE/f"{name}_blend_f1_f5.png")
    for tag,scale in [("native",1),("scale037",.37)]:
        rendered = []
        for i,f in enumerate(frames):
            sprite = matte(f)
            if scale!=1: sprite = sprite.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST)
            canvas = Image.new("RGB",(sprite.width,sprite.height+24),(31,37,44))
            canvas.paste(sprite,(0,24))
            ImageDraw.Draw(canvas).text((8,6),f"F{i+1}",fill="white")
            rendered.append(canvas)
        rendered[0].save(HERE/f"{name}_{tag}.gif",save_all=True,append_images=rendered[1:],
                         duration=[120,130]*4,loop=0,disposal=2)
        contact = Image.new("RGB",(rendered[0].width*8,rendered[0].height),(31,37,44))
        for i,im in enumerate(rendered): contact.paste(im,(i*im.width,0))
        if scale!=1: contact.save(HERE/f"{name}_{tag}_contact.png")
    details = {"hip":(110,185,190,235),"mortar_joint":(170,65,270,115)} if name=="siege_rig" else {
        "face":(255,10,320,75),"gauntlet":(135,123,252,208),"cape_leg":(170,180,285,326)}
    for label,b in details.items():
        dw,dh = (b[2]-b[0])*4,(b[3]-b[1])*4
        out = Image.new("RGB",(dw*3,dh+20),(31,37,44))
        for j,i in enumerate((0,3,4)):
            detail = matte(frames[i]).crop(b).resize((dw,dh),Image.Resampling.NEAREST)
            out.paste(detail,(j*dw,20))
            ImageDraw.Draw(out).text((j*dw+5,5),f"Frame {i+1}",fill="white")
        out.save(HERE/f"{name}_detail_{label}.png")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--publish",action="store_true")
    args = ap.parse_args()
    reports = {}
    for name,builder in [("siege_rig",build_siege),("claim_lord",build_claim)]:
        a = np.array(Image.open(HERE/f"{name}_master.png").convert("RGBA"))
        frames,masks,checks,metadata,effects = builder(a)
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches"): assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 changed")
        assert np.array_equal(frames[7],a),(name,"F8 changed")
        strip = np.concatenate(frames,axis=1)
        destination = HERE/f"{name}_idle.png"
        Image.fromarray(strip).save(destination)
        assert np.array_equal(np.array(Image.open(destination)),strip)
        if args.publish:
            Image.fromarray(strip).save(OUT/f"{name}_idle.png")
            assert np.array_equal(np.array(Image.open(OUT/f"{name}_idle.png")),strip)
        review(name,a,frames,masks,effects)
        (HERE/f"{name}_motion.json").write_text(json.dumps(metadata,indent=2)+"\n")
        reports[name] = {"source":f"assets/sprites/terran/{name}_idle.png",
            "master_sha256":hashlib.sha256(a.tobytes()).hexdigest(),
            "strip_size":[strip.shape[1],strip.shape[0]],"frame_1_exact":True,
            "frame_8_exact":True,"frames":checks,"godot_run":False,
            "effect_mask_pixels_at_037":[int(np.count_nonzero(np.array(Image.fromarray(e.astype(np.uint8)*255).resize(
                (round(a.shape[1]*.37),round(a.shape[0]*.37)),Image.Resampling.NEAREST)))) for e in effects]}
        print(f"{name}: all rigid/feet checks PASS; source cell {a.shape[1]}x{a.shape[0]}; published={args.publish}")
    (HERE/"pair_05_self_check.json").write_text(json.dumps(reports,indent=2)+"\n")


if __name__=="__main__": main()
