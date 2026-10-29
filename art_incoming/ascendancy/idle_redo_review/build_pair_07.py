"""Synapse Brute / Field Scholar, integer cut-outs from the source first frame.

Run without arguments to stage previews and pixel checks; --publish writes the
reviewed strips to art_incoming/ascendancy. Never invokes Godot.
"""
from pathlib import Path
import argparse
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
OUT = HERE.parent
ROOT = HERE.parents[2]
BREATH = [0, 1, 1, 2, 2, 1, 1, 0]
NAMES = ("synapse_brute", "field_scholar")


def shift(a, dx=0, dy=0):
    h, w = a.shape[:2]
    out = np.zeros_like(a)
    out[max(0,dy):min(h,h+dy), max(0,dx):min(w,w+dx)] = a[max(0,-dy):min(h,h-dy), max(0,-dx):min(w,w-dx)]
    return out


def poly(shape, points):
    im = Image.new("1", (shape[1],shape[0]))
    ImageDraw.Draw(im).polygon(points, fill=1)
    return np.asarray(im, dtype=bool)


def rect(shape, x0, y0, x1, y1):
    y,x = np.indices(shape)
    return (x>=x0)&(x<x1)&(y>=y0)&(y<y1)


def stamp(dst, src, mask, dx=0, dy=0):
    m = shift(mask,dx,dy)
    dst[m] = shift(src,dx,dy)[m]
    return m


def backing(master, moving, occluder):
    layer = master.copy()
    extra = np.zeros(moving.shape,dtype=bool)
    for distance in (1,2,3):
        m = shift(moving,dy=-distance)&occluder&~extra
        layer[m] = shift(master,dy=-distance)[m]
        extra |= m
    return layer, extra


def cyan(a):
    rgb = a[:,:,:3].astype(float)
    return (rgb[:,:,1]>60)&(rgb[:,:,1]>rgb[:,:,0]*1.35)&(rgb[:,:,2]>rgb[:,:,0]*1.35)


def brute_masks(a):
    ink = a[:,:,3]>0
    shape = ink.shape
    y,x = np.indices(shape)
    upper = ink&(y<190)
    # Entire circular cannon silhouette, ending in front of the fixed thigh.
    cannon = ink&poly(shape,[(128,130),(300,130),(328,183),(341,193),
        (337,206),(340,216),(347,222),(348,227),(353,232),(353,243),
        (350,251),(347,258),(345,264),(339,271),(336,278),(329,283),
        (319,285),(312,290),(302,289),(291,287),(285,283),(274,282),
        (268,278),(261,274),(254,268),(249,264),(244,261),(237,258),
        (230,253),(223,250),(218,248),(211,243),(199,235),(182,231),
        (170,230),(148,225),(132,213)])
    # Existing energy glyph on the right rim overlaps the fixed leg behind it.
    energy = ink&cyan(a)&rect(shape,278,215,367,280)
    cannon |= energy
    cables = ink&poly(shape,[(147,220),(211,220),(221,240),(213,251),
        (213,269),(211,280),(211,291),(204,299),(189,299),(178,292),
        (162,285),(153,273),(151,255)])
    # The small outer knee plate is a leg part (matching the right knee),
    # even though the back cable passes immediately behind it.
    left_knee = ink&poly(shape,[(194,268),(203,268),(209,273),(212,283),
        (208,294),(203,301),(194,302),(187,297),(185,287),(187,279)])
    cables &= ~left_knee
    fist = ink&poly(shape,[(374,144),(412,150),(468,190),(470,241),
        (450,251),(426,251),(418,241),(414,229),(402,219),(390,209),
        (379,192),(374,181)])
    # Belt is attached to the torso; the pale diagonal thigh plate is fixed.
    belt = ink&poly(shape,[(285,175),(336,175),(341,188),(335,193),
        (335,205),(329,207),(321,199),(309,195),(294,193)])
    body = upper|cannon|cables|fist|belt
    legs = ink&~body
    glasses = body&cyan(a)&(rect(shape,338,34,348,43)|rect(shape,358,34,364,44))
    core = cannon&cyan(a)&rect(shape,278,215,367,279)
    return {"body":body,"legs":legs,"cannon":cannon,"cables":cables,
            "fist":fist,"core":core,"glasses":glasses,"feet":legs&(y>=315)}


def scholar_masks(a):
    ink = a[:,:,3]>0
    shape = ink.shape
    y,x = np.indices(shape)
    upper = ink&(y<174)
    coat_left = ink&poly(shape,[(212,150),(307,150),(305,174),
        (302,183),(298,192),(294,204),(290,215),(286,229),
        (281,242),(277,255),(272,263),(257,265),(217,258),(211,244)])
    coat_right = ink&poly(shape,[(330,157),(347,157),(362,226),(365,261),
        (354,262),(350,243),(347,229),(344,214),(340,196),(336,180)])
    lining = ink&poly(shape,[(294,202),(302,215),(309,229),(315,240),
        (321,255),(278,255),(282,232)])
    body = upper|coat_left|coat_right|lining
    head = body&poly(shape,[(269,0),(356,0),(356,62),(340,62),
        (337,68),(332,73),(329,77),(323,77),(320,80),(307,80),
        (299,77),(293,74),(289,71),(287,67),(286,63),(276,62),(270,56)])
    legs = ink&~body
    pistol = body&poly(shape,[(366,81),(449,72),(449,113),(418,119),
        (409,131),(403,142),(370,143),(369,114)])
    tablet = body&poly(shape,[(259,102),(302,105),(311,116),
        (301,133),(294,145),(270,143),(249,134),(249,123)])
    # A conservative screen inset, clear of the bezel and foreground glove.
    screen = tablet&poly(shape,[(266,112),(288,114),(296,116),(294,121),
        (286,120),(280,124),(275,131),(259,130),(261,118)])
    glasses = head&(rect(shape,310,47,320,54)|rect(shape,332,47,338,54))
    return {"body":body,"head":head,"legs":legs,"pistol_and_hand":pistol,
        "tablet":tablet,"screen":screen,"glasses":glasses,
        "coat":coat_left|coat_right|lining,"feet":legs&(y>=290)}


def brighten(layer, mask, target, strength):
    rgb = layer[mask,:3].astype(float)
    light = np.minimum(255,rgb*.25+np.asarray(target)*.85)
    layer[mask,:3] = np.rint(rgb*(1-strength)+light*strength).astype(np.uint8)


def count_diff(a,b,m):
    return int(np.count_nonzero(np.any(a!=b,axis=2)&m))


def build(name,a):
    masks = brute_masks(a) if name=="synapse_brute" else scholar_masks(a)
    body,legs = masks["body"],masks["legs"]
    head = masks.get("head",np.zeros(body.shape,dtype=bool))
    torso = body&~head
    layer,seam = backing(a,torso,legs|head)
    # Fixed 1-3px backing under the foreground cut-outs closes hidden seams.
    fixed,fixed_seam = backing(a,legs,body)
    frames,checks,motion,effects,seams = [],[],[],[],[]
    y,x = np.indices(body.shape)
    for i,dy in enumerate(BREATH):
        dip = int(name=="field_scholar" and 2<=i<=4)
        moving = layer.copy()
        head_layer = a.copy()
        local_effect = np.zeros(body.shape,dtype=bool)
        head_effect = np.zeros(body.shape,dtype=bool)
        if name=="synapse_brute":
            # Baseline -> dim -> medium -> bright -> peak -> fade -> baseline.
            factor,glow = [(1,0),(.30,0),(.60,0),(.90,.35),(1,.95),
                           (1,.45),(1,.12),(1,0)][i]
            if i not in (0,7):
                moving[masks["core"],:3] = np.rint(moving[masks["core"],:3]*factor).astype(np.uint8)
                brighten(moving,masks["core"],(125,255,255),glow)
                local_effect |= masks["core"]
            centers = [None,None,340,344,360,None,None,None]
            if centers[i] is not None:
                glint = masks["glasses"]&(np.abs(x-centers[i])<=3)
                brighten(moving,glint,(235,255,255),.95)
                local_effect |= glint
        else:
            factor,glow = 1,0
            if 1<=i<=6:
                screen = masks["screen"]
                # Scroll data rows through the inset screen; bezel never changes.
                rows = ((y-i*2)%9<2)&(x>=265)&(x<=287)
                data = screen&rows&(((x+y//9)%13)<9)
                moving[data,:3] = (80,232,245)
                local_effect |= data
            centers = [None,None,312,317,334,None,None,None]
            if centers[i] is not None:
                glint = masks["glasses"]&(np.abs(x-centers[i]-(y-50)//2)<=2)
                brighten(head_layer,glint,(220,255,255),.95)
                head_effect |= glint
        f = a.copy()
        f[body] = 0
        # Backing is underneath both original legs and the translated artwork.
        if dy:
            f[fixed_seam] = fixed[fixed_seam]
        moved = stamp(f,moving,torso,dy=dy)
        extra = shift(seam,dy=dy)&~legs&~moved
        f[extra] = shift(moving,dy=dy)[extra]
        head_dest = stamp(f,head_layer,head,dy=dy+dip)
        effect = shift(local_effect,dy=dy)|shift(head_effect,dy=dy+dip)
        seam_visible = (extra|((fixed_seam if dy else np.zeros(body.shape,dtype=bool))&~moved))&~head_dest
        body_expected = shift(a,dy=dy)
        head_expected = shift(a,dy=dy+dip)
        visible_body = moved&~head_dest&~effect
        visible_legs = legs&~moved&~head_dest&~extra
        rigid_parts = ("cannon","cables","fist") if name=="synapse_brute" else ("pistol_and_hand","tablet","coat")
        c = {"body_rigid_mismatches":count_diff(f,body_expected,visible_body),
             "head_rigid_mismatches":count_diff(f,head_expected,head_dest&~effect),
             "stationary_visible_legs_mismatches":count_diff(f,a,visible_legs),
             "feet_mismatches":count_diff(f,a,masks["feet"]),
             "entire_foot_region_mismatches":count_diff(f,a,y>=(315 if name=="synapse_brute" else 290)),
             "clipped_body_pixels":int(torso.sum()-moved.sum()),
             "clipped_head_pixels":int(head.sum()-head_dest.sum()),
             "visible_seam_pixels":int(seam_visible.sum())}
        for key in rigid_parts:
            part = shift(masks[key]&~head,dy=dy)&~head_dest&~effect
            c[key+"_rigid_mismatches"] = count_diff(f,body_expected,part)
        # Every changed pixel must be a translated cut-out, an allowed light,
        # or copied backing no more than three pixels from the original seam.
        allowed = body|moved|head_dest|seam_visible|effect
        c["unexplained_pixel_mismatches"] = count_diff(f,a,~allowed)
        frames.append(f); checks.append(c); effects.append(effect); seams.append(seam_visible)
        motion.append({"frame":i+1,"whole_body_dxy":[0,dy],"head_extra_dxy":[0,dip],
            "glasses_glint_center_source_x":centers[i],
            "core_source_multiplier":factor,"core_bright_mix":glow,
            "tablet_data_scroll_px":i*2 if name=="field_scholar" and 1<=i<=6 else None})
    return frames,masks,checks,motion,effects,seams


def matte(a):
    src = Image.fromarray(a)
    bg = Image.new("RGBA",src.size,(31,37,44,255))
    bg.alpha_composite(src)
    return bg.convert("RGB")


def review(name,a,frames,masks,effects,seams):
    h,w = a.shape[:2]
    colored = a.copy()
    groups = [("legs",(75,220,110)),("body",(35,210,240))]
    groups += [("cannon",(255,185,55)),("cables",(210,100,255)),("fist",(255,185,55))] if name=="synapse_brute" else [("head",(210,100,255)),("pistol_and_hand",(255,185,55)),("coat",(80,160,255)),("screen",(255,80,80))]
    for key,color in groups: colored[masks[key],:3] = color
    seg = Image.new("RGB",(w*2,h+24),(31,37,44))
    seg.paste(matte(a),(0,24));seg.paste(matte(colored),(w,24))
    ImageDraw.Draw(seg).text((8,6),"GREEN fixed legs | CYAN body | GOLD weapon | PURPLE cables / head | BLUE coat",fill="white")
    seg.save(HERE/f"{name}_segmentation.png")
    for key,m in masks.items(): Image.fromarray(m.astype(np.uint8)*255).save(HERE/f"{name}_mask_{key}.png")
    for i,(e,s) in enumerate(zip(effects,seams)):
        Image.fromarray(e.astype(np.uint8)*255).save(HERE/f"{name}_effect_f{i+1}.png")
        Image.fromarray(s.astype(np.uint8)*255).save(HERE/f"{name}_seam_f{i+1}.png")
    Image.blend(matte(frames[0]),matte(frames[3]),.5).save(HERE/f"{name}_blend_f1_f4.png")
    plate = Image.new("RGB",(w*4,(h+24)*2),(31,37,44))
    for i,f in enumerate(frames):
        px,py=i%4*w,i//4*(h+24)
        plate.paste(matte(f),(px,py+24))
        ImageDraw.Draw(plate).text((px+8,py+6),f"F{i+1}",fill="white")
    plate.save(HERE/f"{name}_contact.png")
    for tag,scale in [("native",1),("scale037",.37)]:
        views=[]
        for i,f in enumerate(frames):
            im=matte(f)
            if scale!=1: im=im.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST)
            v=Image.new("RGB",(im.width,im.height+24),(31,37,44));v.paste(im,(0,24))
            ImageDraw.Draw(v).text((8,6),f"F{i+1}",fill="white");views.append(v)
        views[0].save(HERE/f"{name}_{tag}.gif",save_all=True,append_images=views[1:],
            duration=[120,130]*4,loop=0,disposal=2)
        if scale!=1:
            contact=Image.new("RGB",(views[0].width*8,views[0].height),(31,37,44))
            for i,v in enumerate(views): contact.paste(v,(i*v.width,0))
            contact.save(HERE/f"{name}_{tag}_contact.png")
    boxes = {"cannon_legs":(280,184,407,296),"cable_leg":(150,225,240,307),"glasses":(333,29,369,48)} if name=="synapse_brute" else {"neck":(275,60,344,92),"screen":(250,102,310,138),"coat":(215,163,367,268)}
    for label,b in boxes.items():
        dw,dh=(b[2]-b[0])*3,(b[3]-b[1])*3
        plate=Image.new("RGB",(dw*3,dh+20),(31,37,44))
        for j,i in enumerate((0,3,4)):
            plate.paste(matte(frames[i]).crop(b).resize((dw,dh),Image.Resampling.NEAREST),(j*dw,20))
            ImageDraw.Draw(plate).text((j*dw+5,4),f"F{i+1}",fill="white")
        plate.save(HERE/f"{name}_detail_{label}.png")


def main():
    ap=argparse.ArgumentParser();ap.add_argument("--publish",action="store_true");args=ap.parse_args()
    report={}
    for name in NAMES:
        source=ROOT/"assets"/"sprites"/"ascendancy"/f"{name}_idle.png"
        strip_source=Image.open(source).convert("RGBA")
        a=np.asarray(strip_source.crop((0,0,strip_source.width//8,strip_source.height)))
        Image.fromarray(a).save(HERE/f"{name}_master.png")
        frames,masks,checks,motion,effects,seams=build(name,a)
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches") or key.startswith("clipped_"):
                    assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 changed")
        assert np.array_equal(frames[7],a),(name,"F8 changed")
        strip=np.concatenate(frames,axis=1)
        assert (strip.shape[1],strip.shape[0])==strip_source.size
        Image.fromarray(strip).save(HERE/f"{name}_idle.png")
        assert np.array_equal(np.asarray(Image.open(HERE/f"{name}_idle.png")),strip)
        review(name,a,frames,masks,effects,seams)
        if args.publish:
            Image.fromarray(strip).save(OUT/f"{name}_idle.png")
            assert np.array_equal(np.asarray(Image.open(OUT/f"{name}_idle.png")),strip)
        (HERE/f"{name}_motion.json").write_text(json.dumps(motion,indent=2)+"\n")
        report[name]={"source":str(source.relative_to(ROOT)),
            "master_sha256":hashlib.sha256(a.tobytes()).hexdigest(),
            "strip_size":[strip.shape[1],strip.shape[0]],"frame_1_exact":True,
            "frame_8_exact":True,"frames":checks,"godot_run":False,"published":args.publish}
        print(f"{name}: rigid/feet checks PASS; {strip.shape[1]}x{strip.shape[0]}; published={args.publish}")
    (HERE/"pair_07_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__": main()
