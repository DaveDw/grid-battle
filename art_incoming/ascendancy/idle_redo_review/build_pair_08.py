"""Rigid Director Zero / Protocol Warden idles. No engine invocation.

The approved preceding pair supplies only lossless pixel utility functions.
Run without arguments for previews/checks, then --publish after visual review.
"""
from pathlib import Path
import argparse
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw
from build_pair_07 import shift, poly, rect, stamp, backing, cyan, brighten, count_diff, matte

HERE = Path(__file__).resolve().parent
OUT = HERE.parent
ROOT = HERE.parents[2]
NAMES = ("director_zero", "protocol_warden")
FLOAT = [0,-1,-3,-4,-4,-3,-1,0]
HANDS = [0]+FLOAT[:-1]
DIP = [0,0,2,2,2,0,0,0]


def restore_warden_particles(a):
    """Restore only the three old cyan squares from aligned base artwork."""
    base = Image.open(ROOT/"assets/sprites/ascendancy/protocol_warden.png").convert("RGBA")
    canvas = Image.new("RGBA",(a.shape[1],a.shape[0]))
    canvas.paste(base,(172,2))
    donor = np.asarray(canvas)
    rgb = a[:,:,:3].astype(float)
    y,x = np.indices(a.shape[:2])
    mask = (x>210)&(x<280)&(y<85)&(rgb[:,:,0]>80)&(rgb[:,:,1]>rgb[:,:,0]*1.12)&(rgb[:,:,2]>rgb[:,:,0]*1.12)
    clean = a.copy();clean[mask] = donor[mask]
    return clean,mask


def director_masks(a):
    ink = a[:,:,3]>0
    shape = ink.shape
    y,x = np.indices(shape)
    left = ink&(x<210)&(y>=145)
    right = ink&(x>320)&(y>=145)
    halo = ink&(y<145)&~rect(shape,220,56,305,145)
    blade = ink&~left&~right&~halo
    rgb = a[:,:,:3].astype(float)
    halo_light = halo&(rgb[:,:,:3].min(axis=2)>115)
    red = (rgb[:,:,0]>45)&(rgb[:,:,0]>rgb[:,:,1]*1.4)&(rgb[:,:,0]>rgb[:,:,2]*1.2)
    # The centre contains near-white highlights; they must blink off too.
    white_core = rect(shape,272,94,286,113)&(rgb[:,:,0]>150)
    eye = blade&rect(shape,267,89,290,117)&(red|white_core)
    return {"blade":blade,"halo":halo,"left_hand":left,"right_hand":right,
            "halo_light":halo_light,"eye_light":eye}


def warden_masks(a):
    ink = a[:,:,3]>0
    shape = ink.shape
    y,x = np.indices(shape)
    upper = ink&(y<200)
    sphere = ink&poly(shape,[(260,150),(449,150),(441,193),(430,201),
        (422,210),(415,216),(410,225),(401,238),(388,248),(374,252),
        (351,256),(329,255),(313,251),(302,246),(298,242),(294,237),
        (298,230),(300,217),(294,203),(284,198),(269,198)])
    left_arm = ink&poly(shape,[(174,155),(236,155),(264,208),(262,218),
        (254,221),(244,221),(232,225),(225,229),(220,239),(218,252),
        (216,267),(217,279),(225,285),(227,298),(218,302),(210,304),
        (200,301),(188,287),(181,269),(174,246)])
    left_claw = ink&poly(shape,[(226,222),(256,223),(265,224),(274,229),
        (282,240),(286,252),(292,268),(296,285),(298,301),(297,311),
        (291,320),(283,322),(283,331),(278,336),(269,337),(255,330),
        (244,321),(238,314),(232,307),(230,297),(232,285),(234,276),
        (231,270),(226,264),(222,250),(222,239)])
    right_arm = ink&poly(shape,[(460,154),(560,154),(567,320),(502,320),
        (494,312),(487,299),(485,282),(489,270),(481,260),(472,248),
        (466,230),(461,213)])
    # The hip ball housings are stationary, including their dark outer rims.
    # The foreground claw is composited in front of the left hip as in F1.
    left_hip = ink&poly(shape,[(265,203),(274,199),(287,198),(296,202),
        (302,212),(300,223),(293,233),(283,241),(276,234),(269,225),(264,215)])
    right_hip = ink&poly(shape,[(421,207),(429,208),(436,214),(439,225),
        (434,230),(414,232),(410,225),(413,214)])
    upper &= ~(left_hip|right_hip)
    sphere &= ~(left_hip|right_hip)
    body = upper|sphere|left_arm|left_claw|right_arm
    legs = ink&~body
    chest = body&cyan(a)&rect(shape,378,136,408,173)
    # Side sensor: move its pale iris as one cut-out inside the dark socket.
    rgb = a[:,:,:3].astype(float)
    pupil = body&rect(shape,300,182,322,207)&(rgb[:,:,0]>65)&(rgb[:,:,1]>60)&(rgb[:,:,0]>rgb[:,:,2]*1.05)
    side_lens = body&poly(shape,[(300,179),(315,177),(325,188),(325,205),
                               (317,211),(305,210),(298,199)])
    return {"body":body,"sphere":sphere|upper,"left_arm":left_arm,
        "left_claw":left_claw,"right_arm":right_arm,"legs":legs,
        "chest_light":chest,"side_lens":side_lens,"pupil":pupil,
        "feet":legs&(y>=350)}


def build_director(a):
    masks = director_masks(a)
    frames,checks,motion,effects,seams = [],[],[],[],[]
    for i,(dy,hand_dy) in enumerate(zip(FLOAT,HANDS)):
        moving = a.copy()
        local_effect = np.zeros(masks["blade"].shape,dtype=bool)
        dim,bright = [(1,0),(.55,0),(.76,.15),(1,.8),(1,.95),(.84,.2),(.94,0),(1,0)][i]
        if i not in (0,7):
            light = masks["halo_light"]
            moving[light,:3] = np.rint(moving[light,:3]*dim).astype(np.uint8)
            brighten(moving,light,(215,255,255),bright)
            local_effect |= light
        if i==4:
            eye = masks["eye_light"]
            moving[eye,:3] = np.rint(a[eye,:3]*.035+np.array([9,11,15])).astype(np.uint8)
            local_effect |= eye
        f = np.zeros_like(a)
        effect = shift(local_effect,dy=dy)
        c = {}
        for part,offset in [("blade",dy),("halo",dy),("left_hand",hand_dy),("right_hand",hand_dy)]:
            placed = stamp(f,moving,masks[part],dy=offset)
            c[part+"_clipped_pixels"] = int(masks[part].sum()-placed.sum())
            c[part+"_rigid_mismatches"] = count_diff(f,shift(a,dy=offset),placed&~effect)
        c["alpha_shape_mismatches"] = int(np.count_nonzero(f[:,:,3] != (
            shift(np.where((masks["blade"]|masks["halo"]),a[:,:,3],0),dy=dy)+
            shift(np.where((masks["left_hand"]|masks["right_hand"]),a[:,:,3],0),dy=hand_dy))))
        frames.append(f);checks.append(c);effects.append(effect);seams.append(np.zeros(effect.shape,dtype=bool))
        motion.append({"frame":i+1,"blade_and_halo_dxy":[0,dy],
            "both_hands_dxy":[0,hand_dy],"halo_source_multiplier":dim,
            "halo_bright_mix":bright,"red_eye_off":i==4})
    return frames,masks,checks,motion,effects,seams


def build_warden(a):
    masks = warden_masks(a)
    body,legs = masks["body"],masks["legs"]
    layer,seam = backing(a,body,legs)
    fixed,fixed_seam = backing(a,legs,body)
    frames,checks,motion,effects,seams = [],[],[],[],[]
    pupil = masks["pupil"]
    y,x = np.indices(body.shape)
    for i,dy in enumerate(DIP):
        moving = layer.copy()
        local_effect = np.zeros(body.shape,dtype=bool)
        # Light only: the lens rim, sphere plating and arms stay exact.
        pulse = [0,0,.35,.85,1,.45,0,0][i]
        if pulse:
            brighten(moving,masks["chest_light"],(155,255,255),pulse)
            local_effect |= masks["chest_light"]
        pupil_dx = [0,0,1,2,1,-1,0,0][i]
        if pupil_dx:
            dest = shift(pupil,dx=pupil_dx)
            assert not np.any(dest&~masks["side_lens"]),"Pupil leaves lens"
            exposed = pupil&~dest
            # Only 1-2 uncovered columns are filled from neighbouring glass.
            for yy,xx in zip(*np.where(exposed)):
                direction = -1 if pupil_dx>0 else 1
                candidates = [xx+direction*d for d in range(1,5)]
                donor = next((q for q in candidates if 0<=q<a.shape[1] and not pupil[yy,q]),None)
                assert donor is not None,(yy,xx,"no glass backing")
                moving[yy,xx] = a[yy,donor]
            stamp(moving,a,pupil,dx=pupil_dx)
            local_effect |= pupil|dest
        f = a.copy();f[body] = 0
        if dy: f[fixed_seam] = fixed[fixed_seam]
        moved = stamp(f,moving,body,dy=dy)
        extra = shift(seam,dy=dy)&~legs&~moved
        f[extra] = shift(moving,dy=dy)[extra]
        effect = shift(local_effect,dy=dy)
        seam_visible = extra|((fixed_seam if dy else np.zeros(body.shape,dtype=bool))&~moved)
        c = {"body_rigid_mismatches":count_diff(f,shift(a,dy=dy),moved&~effect),
            "visible_legs_mismatches":count_diff(f,a,legs&~moved&~extra),
            "feet_mismatches":count_diff(f,a,masks["feet"]),
            "entire_foot_region_mismatches":count_diff(f,a,y>=350),
            "body_clipped_pixels":int(body.sum()-moved.sum()),
            "visible_seam_pixels":int(seam_visible.sum()),
            "pupil_rigid_mismatches":count_diff(f,shift(a,dx=pupil_dx,dy=dy),shift(pupil,dx=pupil_dx,dy=dy))}
        for key in ("sphere","left_arm","left_claw","right_arm"):
            c[key+"_rigid_mismatches"] = count_diff(f,shift(a,dy=dy),shift(masks[key],dy=dy)&~effect)
        c["unexplained_pixel_mismatches"] = count_diff(f,a,~(body|moved|effect|seam_visible))
        frames.append(f);checks.append(c);effects.append(effect);seams.append(seam_visible)
        motion.append({"frame":i+1,"sphere_and_arms_dxy":[0,dy],
            "legs_dxy":[0,0],"chest_bright_mix":pulse,"side_pupil_extra_dxy":[pupil_dx,0]})
    return frames,masks,checks,motion,effects,seams


def review(name,a,frames,masks,effects,seams):
    h,w = a.shape[:2]
    colored = a.copy()
    groups = [("blade",(35,210,240)),("halo",(210,100,255)),("left_hand",(255,185,55)),("right_hand",(255,185,55))] if name=="director_zero" else [("legs",(75,220,110)),("body",(35,210,240)),("left_arm",(255,185,55)),("left_claw",(255,185,55)),("right_arm",(255,185,55)),("pupil",(255,90,90))]
    for key,color in groups: colored[masks[key],:3] = color
    seg = Image.new("RGB",(w*2,h+24),(31,37,44));seg.paste(matte(a),(0,24));seg.paste(matte(colored),(w,24))
    ImageDraw.Draw(seg).text((8,6),"CYAN body | GOLD arms / hands | PURPLE halo | GREEN fixed legs | RED pupil",fill="white")
    seg.save(HERE/f"{name}_segmentation.png")
    for key,m in masks.items(): Image.fromarray(m.astype(np.uint8)*255).save(HERE/f"{name}_mask_{key}.png")
    for i,(e,s) in enumerate(zip(effects,seams)):
        Image.fromarray(e.astype(np.uint8)*255).save(HERE/f"{name}_effect_f{i+1}.png")
        Image.fromarray(s.astype(np.uint8)*255).save(HERE/f"{name}_seam_f{i+1}.png")
    Image.blend(matte(frames[0]),matte(frames[3]),.5).save(HERE/f"{name}_blend_f1_f4.png")
    contact = Image.new("RGB",(w*4,(h+24)*2),(31,37,44))
    for i,f in enumerate(frames):
        px,py = i%4*w,i//4*(h+24)
        contact.paste(matte(f),(px,py+24));ImageDraw.Draw(contact).text((px+8,py+6),f"F{i+1}",fill="white")
    contact.save(HERE/f"{name}_contact.png")
    for tag,scale in [("native",1),("scale037",.37)]:
        views=[]
        for i,f in enumerate(frames):
            im=matte(f)
            if scale!=1: im=im.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST)
            v=Image.new("RGB",(im.width,im.height+24),(31,37,44));v.paste(im,(0,24))
            ImageDraw.Draw(v).text((8,6),f"F{i+1}",fill="white");views.append(v)
        views[0].save(HERE/f"{name}_{tag}.gif",save_all=True,append_images=views[1:],duration=[120,130]*4,loop=0,disposal=2)
        if scale!=1:
            plate=Image.new("RGB",(views[0].width*8,views[0].height),(31,37,44))
            for i,v in enumerate(views): plate.paste(v,(i*v.width,0))
            plate.save(HERE/f"{name}_{tag}_contact.png")
    boxes = {"eye":(263,85,294,119),"halo":(163,0,352,145)} if name=="director_zero" else {"left_claw_leg":(189,205,302,349),"sphere_legs":(265,193,445,260),"pupil":(291,173,330,215),"chest":(370,130,414,180)}
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
        if name=="protocol_warden": a,_=restore_warden_particles(a)
        Image.fromarray(a).save(HERE/f"{name}_master.png")
        result=build_director(a) if name=="director_zero" else build_warden(a)
        frames,masks,checks,motion,effects,seams=result
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches") or key.endswith("clipped_pixels"):
                    assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 changed")
        if name=="protocol_warden": assert np.array_equal(frames[7],a),(name,"F8 changed")
        else:
            loop=np.zeros_like(a)
            stamp(loop,a,masks["blade"]|masks["halo"])
            stamp(loop,a,masks["left_hand"]|masks["right_hand"],dy=-1)
            assert np.array_equal(frames[7],loop),(name,"F8 lag discontinuity")
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
            "frame_8_exact":bool(np.array_equal(frames[7],a)),
            "loop_hand_return_px":1 if name=="director_zero" else 0,
            "frames":checks,"godot_run":False,"published":args.publish}
        print(f"{name}: rigid/feet/loop checks PASS; {strip.shape[1]}x{strip.shape[0]}; published={args.publish}")
    (HERE/"pair_08_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__": main()
