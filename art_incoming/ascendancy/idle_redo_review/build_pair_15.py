"""Extra pair: clean bases, rigid cut-outs, four drones and twelve crystals."""
from pathlib import Path
import argparse
import hashlib
import json
import sys
import numpy as np
from PIL import Image, ImageDraw

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
sys.path.insert(0,str(HERE))
from build_pair_07 import shift, poly, rect, stamp, backing, count_diff, matte

FACTIONS={"chief_visionary":"ascendancy","prism_elder":"manyworlds"}
OFFSETS={"chief_visionary":(143,2),"prism_elder":(34,-1)}
BREATH=[0,1,1,2,2,1,1,0]
BOB=[0,1,2,3,3,2,1,0]
HEAD=[0,0,1,1,1,0,0,0]


def geometry(a,name):
    ox,oy=OFFSETS[name];ink=a[:,:,3]>0;shape=ink.shape
    yy,xx=np.indices(shape);x,y=xx-ox,yy-oy
    def P(points):return ink&poly(shape,[(px+ox,py+oy) for px,py in points])
    def R(x0,y0,x1,y1):return ink&rect(shape,x0+ox,y0+oy,x1+ox,y1+oy)
    return ink,x,y,P,R


def components(ink):
    seen=np.zeros(ink.shape,bool);result=[]
    for y,x in zip(*np.where(ink)):
        if seen[y,x]:continue
        todo=[(y,x)];seen[y,x]=True;points=[]
        while todo:
            cy,cx=todo.pop();points.append((cy,cx))
            for dy in (-1,0,1):
                for dx in (-1,0,1):
                    ny,nx=cy+dy,cx+dx
                    if 0<=ny<ink.shape[0] and 0<=nx<ink.shape[1] and ink[ny,nx] and not seen[ny,nx]:
                        seen[ny,nx]=True;todo.append((ny,nx))
        m=np.zeros(ink.shape,bool);ys,xs=zip(*points);m[ys,xs]=True;result.append(m)
    return sorted(result,key=lambda m:int(m.sum()),reverse=True)


def chief_masks(a):
    ink,x,y,P,R=geometry(a,"chief_visionary");cc=components(ink)
    assert len(cc)==5
    objects={"drone_left_middle":cc[1],"drone_left_top":cc[2],
        "drone_right_lower":cc[3],"drone_right_top":cc[4]}
    figure=cc[0]
    left_arm=P([(86,133),(129,136),(142,176),(142,187),(136,196),
        (126,201),(116,198),(101,195),(93,184),(86,166)])&figure
    left_coat=P([(101,172),(130,172),(129,198),(125,212),(119,228),
        (118,242),(113,259),(109,274),(105,292),(94,296),(93,310),
        (57,310),(56,280),(72,249),(86,224),(101,195)])&figure
    right_coat=P([(192,169),(203,169),(209,196),(215,216),(218,244),
        (223,268),(230,289),(230,313),(218,313),(213,305),(198,302),
        (183,299),(182,277),(187,255),(189,229),(191,206)])&figure
    left_coat |= figure&(x<94)&(y>=198)&(y<312)
    right_coat |= figure&(x>=201)&(y>=179)&(y<314)
    lining=P([(157,228),(159,249),(155,267),(155,300),(146,300),
        (139,295),(132,295),(138,281),(143,266),(150,246)])&figure
    body=((figure&(y<179))|left_arm|left_coat|right_coat|lining)
    legs=figure&~body
    chin_hand=P([(173,71),(190,71),(204,79),(219,96),(220,114),
        (196,115),(180,103),(173,87)])&body
    head=P([(116,0),(212,0),(212,67),(190,69),(176,70),(172,74),
        (177,79),(169,82),(144,81),(135,78),(132,73),(118,72)])&body&~chin_hand
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    cyan=(g>70)&(g>r*1.2)&(b>r*1.2)
    lenses=np.logical_or.reduce(list(objects.values()))&cyan
    glasses=head&(R(154,49,172,65)|R(180,49,194,64))&(r>120)&(g>120)&(b>110)
    return {"body":body,"legs":legs,"head":head,"coat":(left_coat|right_coat|lining)&body,
        "left_arm":left_arm,"chin_hand":chin_hand,"lenses":lenses,"glasses":glasses,
        "feet":legs&(y>=321)},objects,[]


def elder_masks(a):
    ink,x,y,P,R=geometry(a,"prism_elder");cc=components(ink)
    assert len(cc)==24
    names=["crystal_left_large","crystal_left_lower","crystal_right_lower",
        "crystal_right_upper","crystal_left_spear","crystal_left_upper",
        "crystal_left_middle","crystal_gold_star","crystal_right_small"]
    objects={n:cc[i+1] for i,n in enumerate(names)}
    connected=cc[0]
    objects["crystal_right_large"]=P([(200,93),(228,113),(249,135),(264,144),
        (263,173),(253,191),(245,220),(232,214),(219,189),(208,165),(202,140)])&connected
    objects["crystal_front_left"]=P([(102,168),(111,173),(119,175),(126,179),
        (135,182),(141,188),(148,192),(155,200),(159,204),(159,212),
        (156,217),(155,229),(148,234),(140,231),(130,223),(120,216),
        (113,212),(111,207),(106,205),(105,199),(104,183)])&connected
    objects["crystal_front_right"]=P([(165,177),(179,164),(193,161),(212,179),
        (207,195),(195,206),(178,204),(170,194)])&connected
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    purple=(b>r*1.05)&(r>g*1.3)&(b>35)
    connector=P([(212,186),(223,185),(226,190),(224,199),(222,205),
        (216,209),(214,207),(214,199),(211,196)])&connected&~purple
    connector |= R(211,184,227,211)&connected&~purple
    objects["crystal_right_large"] |= connector
    objects["crystal_front_left"] &= ~purple
    floating=np.logical_or.reduce(list(objects.values()))
    body=connected&~floating
    head=body&(y<191)
    coat=body&~head
    rgb=a[:,:,:3].astype(float);r,g,b=np.moveaxis(rgb,2,0)
    core=head&(g>45)&(g>r*1.18)&(b>r*1.18)
    emblem=coat&R(170,240,218,290)&(g>150)&(b>180)&(g>r*.95)
    return {"body":body,"legs":np.zeros(ink.shape,bool),"head":head,"coat":coat,
        "core":core,"emblem":emblem,"feet":np.zeros(ink.shape,bool)},objects,cc[10:]


def pulse_rgb(source,dst,mask,amount,target):
    if not amount:return
    brightness=np.max(source[mask,:3],axis=1).astype(float)/255
    # Preserve the dim halo; brighten luminous cores rather than making the
    # opaque dark fringe into a flat, pale blob.
    weight=(amount*brightness**1.8)[:,None]
    dst[mask,:3]=np.rint(source[mask,:3]*(1-weight)+np.array(target)*weight).clip(0,255).astype(np.uint8)


def build(name,a):
    chief=name=="chief_visionary"
    masks,objects,particles=(chief_masks if chief else elder_masks)(a)
    ink,x,y,P,R=geometry(a,name);body,head,legs=masks["body"],masks["head"],masks["legs"]
    floating=np.logical_or.reduce(list(objects.values()))
    ambient=np.logical_or.reduce(particles) if particles else np.zeros(ink.shape,bool)
    assert not np.any(body&floating)
    assert np.array_equal(body|legs|floating|ambient,ink)
    masks.update(objects);masks["ambient"]=ambient
    base,seam=backing(a,body,legs);fixed,fixed_seam=backing(a,legs,body)
    frames=[];checks=[];motion=[];effects=[];seams=[]
    for i,dy in enumerate(BREATH):
        hx=HEAD[i];moving=base.copy();local_effect=np.zeros(ink.shape,bool)
        pulse=[0,0,.35,1,.65,.25,0,0][i]
        if chief:
            if pulse:
                pulse_rgb(a,moving,masks["glasses"],pulse*.32,[235,249,255]);local_effect|=masks["glasses"]
        elif pulse:
            pulse_rgb(a,moving,masks["core"],pulse*.58,[180,255,255])
            pulse_rgb(a,moving,masks["emblem"],pulse*.45,[219,247,255])
            local_effect|=masks["core"]|masks["emblem"]
        f=a.copy();f[body|floating|ambient]=0
        if dy:f[fixed_seam]=fixed[fixed_seam]
        extra=shift(seam,dy=dy)&~legs
        f[extra]=shift(moving,dy=dy)[extra]
        torso_dest=stamp(f,moving,body&~head,dy=dy)
        neck_fill=np.zeros(ink.shape,bool)
        if chief and hx:
            neck=rect(ink.shape,137+OFFSETS[name][0],73+OFFSETS[name][1],177+OFFSETS[name][0],87+OFFSETS[name][1]+dy)
            neck_fill=shift(head,dy=dy)&shift(body&~head,dx=hx,dy=dy)&neck
            f[neck_fill]=shift(moving,dx=hx,dy=dy)[neck_fill]
        head_dest=stamp(f,moving,head,dx=hx,dy=dy)
        hand_dest=np.zeros(ink.shape,bool)
        if chief:hand_dest=stamp(f,moving,masks["chin_hand"],dy=dy)
        placed=torso_dest|head_dest
        effect=shift(local_effect&~head,dy=dy)|shift(local_effect&head,dx=hx,dy=dy)
        object_dest=np.zeros(ink.shape,bool);c={};object_motion={}
        for j,(key,m) in enumerate(objects.items()):
            direction=1 if j%2==0 else -1
            ody=direction*BOB[i]
            odx=(j%3-1)*[0,0,1,1,1,1,0,0][i]
            layer=a.copy();light=np.zeros(ink.shape,bool)
            if chief:
                eye=m&masks["lenses"]
                lp=([0,0,.5,1,.5,0,0,0] if direction==1 else [0,0,0,.25,.7,1,.2,0])[i]
                if lp:pulse_rgb(a,layer,eye,lp*.72,[180,255,255]);light=shift(eye,dx=odx,dy=ody)
            dm=stamp(f,layer,m,dx=odx,dy=ody);object_dest|=dm;effect|=light
            c[key+"_rigid_mismatches"]=count_diff(f,shift(a,dx=odx,dy=ody),dm&~light)
            c[key+"_clipped_pixels"]=int(m.sum()-dm.sum())
            object_motion[key]=[odx,ody]
        particle_dest=np.zeros(ink.shape,bool)
        for j,m in enumerate(particles):
            layer=a.copy()
            # Every isolated source spark moves and twinkles; none is frozen.
            pdx=(1 if j%2 else -1)*[0,0,1,1,1,1,0,0][i]
            pdy=-[0,1,2,3,3,2,1,0][i]
            opacity=([1,.75,.42,.7,1,.55,.8,1] if j%2 else [1,.7,1,.5,.3,.75,.55,1])[i]
            layer[m,3]=np.rint(a[m,3].astype(float)*opacity).astype(np.uint8)
            dm=shift(m,dx=pdx,dy=pdy)&(f[:,:,3]==0)
            shifted=shift(layer,dx=pdx,dy=pdy);f[dm]=shifted[dm];particle_dest|=dm
        effect|=particle_dest
        for key,m in objects.items():
            odx,ody=object_motion[key]
            exempt=shift(m&masks["lenses"],dx=odx,dy=ody) if chief else np.zeros(ink.shape,bool)
            c[key+"_final_rigid_mismatches"]=count_diff(f,shift(a,dx=odx,dy=ody),shift(m,dx=odx,dy=ody)&~exempt)
        visible_seam=(extra|(fixed_seam if dy else False)|neck_fill)&~placed&~object_dest&~particle_dest
        c.update({"torso_rigid_mismatches":count_diff(f,shift(a,dy=dy),torso_dest&~head_dest&~effect&~object_dest),
            "head_rigid_mismatches":count_diff(f,shift(a,dx=hx,dy=dy),head_dest&~effect&~hand_dest&~object_dest),
            "coat_rigid_mismatches":count_diff(f,shift(a,dy=dy),shift(masks["coat"],dy=dy)&~effect&~object_dest),
            "visible_legs_mismatches":count_diff(f,a,legs&~placed&~extra&~object_dest),
            "feet_pixels_mismatches":count_diff(f,a,masks["feet"]),
            "feet_region_mismatches":count_diff(f,a,y>=321) if chief else 0,
            "body_clipped_pixels":int((body&~head).sum()-torso_dest.sum()+head.sum()-head_dest.sum()),
            "visible_seam_pixels":int(visible_seam.sum()),"ambient_particle_pixels":int(particle_dest.sum())})
        allowed=body|placed|head_dest|floating|object_dest|ambient|effect|visible_seam
        c["unexplained_pixel_mismatches"]=count_diff(f,a,~allowed)
        frames.append(f);checks.append(c);effects.append(effect);seams.append(visible_seam)
        motion.append({"frame":i+1,"body_dxy":[0,dy],"head_dxy":[hx,dy],
            "legs_dxy":[0,0] if chief else None,"floating_objects":object_motion,
            "glow_pulse":pulse,"all_ambient_sparks_animated":not chief})
    return frames,masks,objects,checks,motion,effects,seams


def review(out,name,a,frames,masks,objects,effects,seams):
    h,w=a.shape[:2];colored=a.copy()
    for key,color in [("legs",(75,220,110)),("body",(35,210,240)),("coat",(255,120,120)),("head",(110,160,255)),("ambient",(255,255,100))]:colored[masks[key],:3]=color
    colors=[(255,180,55),(220,90,240),(110,230,155),(240,230,70)]
    for j,m in enumerate(objects.values()):colored[m,:3]=colors[j%4]
    seg=Image.new("RGB",(w*2,h+24),(31,37,44));seg.paste(matte(a),(0,24));seg.paste(matte(colored),(w,24))
    ImageDraw.Draw(seg).text((8,6),"GREEN legs | CYAN torso | PINK coat | BLUE head | separate colours: rigid floating pieces",fill="white")
    seg.save(out/f"{name}_segmentation.png")
    for k,m in masks.items():Image.fromarray(m.astype(np.uint8)*255).save(out/f"{name}_mask_{k}.png")
    for i,(e,s) in enumerate(zip(effects,seams)):
        Image.fromarray(e.astype(np.uint8)*255).save(out/f"{name}_effect_f{i+1}.png")
        Image.fromarray(s.astype(np.uint8)*255).save(out/f"{name}_seam_f{i+1}.png")
    Image.blend(matte(frames[0]),matte(frames[3]),.5).save(out/f"{name}_blend_f1_f4.png")
    for tag,scale in [("native",1),("scale037",.37)]:
        views=[]
        for i,f in enumerate(frames):
            im=matte(f)
            if scale!=1:im=im.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST)
            v=Image.new("RGB",(im.width,im.height+24),(31,37,44));v.paste(im,(0,24))
            ImageDraw.Draw(v).text((8,6),f"F{i+1}",fill="white");views.append(v)
        views[0].save(out/f"{name}_{tag}.gif",save_all=True,append_images=views[1:],duration=[120,130]*4,loop=0,disposal=2)
        plate=Image.new("RGB",(views[0].width*4,views[0].height*2),(31,37,44))
        for i,v in enumerate(views):plate.paste(v,((i%4)*v.width,(i//4)*v.height))
        plate.save(out/f"{name}_{tag}_contact.png")
    boxes={"head_hand":(118,5,225,118),"coat_legs":(59,170,233,330),"drones":(0,0,105,160)} if name=="chief_visionary" else {"crystals_cloak":(100,159,268,244),"core":(91,75,205,193),"cloak_tip":(157,315,268,384)}
    ox,oy=OFFSETS[name]
    for label,b in boxes.items():
        b=(b[0]+ox,b[1]+oy,b[2]+ox,b[3]+oy);dw,dh=(b[2]-b[0])*3,(b[3]-b[1])*3
        plate=Image.new("RGB",(dw*3,dh+20),(31,37,44))
        for j,i in enumerate((0,3,4)):
            plate.paste(matte(frames[i]).crop(b).resize((dw,dh),Image.Resampling.NEAREST),(j*dw,20))
            ImageDraw.Draw(plate).text((j*dw+5,4),f"F{i+1}",fill="white")
        plate.save(out/f"{name}_detail_{label}.png")


def main():
    ap=argparse.ArgumentParser();ap.add_argument("--publish",action="store_true");args=ap.parse_args();report={}
    for name,faction in FACTIONS.items():
        out=ROOT/"art_incoming"/faction/"idle_redo_review";out.mkdir(exist_ok=True)
        source=ROOT/"assets/sprites"/faction/f"{name}.png"
        with Image.open(source.with_name(name+"_idle.png")) as old:canvas=old.size
        master=Image.new("RGBA",(canvas[0]//8,canvas[1]));master.paste(Image.open(source).convert("RGBA"),OFFSETS[name])
        a=np.asarray(master);master.save(out/f"{name}_master.png")
        assert int((a[:,:,3]>0).sum())==int((np.array(Image.open(source).convert("RGBA"))[:,:,3]>0).sum())
        frames,masks,objects,checks,motion,effects,seams=build(name,a)
        review(out,name,a,frames,masks,objects,effects,seams)
        for i,c in enumerate(checks):
            for key,value in c.items():
                if key.endswith("mismatches") or key.endswith("clipped_pixels"):assert value==0,(name,i+1,key,value)
        assert np.array_equal(frames[0],a),(name,"F1 not clean base")
        assert np.array_equal(frames[7],a),(name,"F8 differs from F1")
        strip=np.concatenate(frames,axis=1);assert (strip.shape[1],strip.shape[0])==canvas
        Image.fromarray(strip).save(out/f"{name}_idle.png")
        assert np.array_equal(np.asarray(Image.open(out/f"{name}_idle.png")),strip)
        if args.publish:
            Image.fromarray(strip).save(out.parent/f"{name}_idle.png")
            assert np.array_equal(np.asarray(Image.open(out.parent/f"{name}_idle.png")),strip)
        (out/f"{name}_motion.json").write_text(json.dumps(motion,indent=2)+"\n")
        report[name]={"source":str(source.relative_to(ROOT)),"base_offset":list(OFFSETS[name]),
            "master_sha256":hashlib.sha256(a.tobytes()).hexdigest(),"strip_size":[strip.shape[1],strip.shape[0]],
            "frame_1_exact_clean_base":True,"frame_8_exact_frame_1":True,"old_idle_pixels_used":False,
            "visible_feet_in_source":name=="chief_visionary","frames":checks,"godot_run":False,"published":args.publish}
        print(f"{name}: rigid/feet/loop checks PASS; {strip.shape[1]}x{strip.shape[0]}; published={args.publish}")
    (HERE/"pair_15_self_check.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__":main()
