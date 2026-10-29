"""Deterministic cut-out pilot. All coordinates are native 384px-cell pixels.

Only writes inside this review directory unless called with --publish.
Master PNGs are unmodified frame 1 from the incoming strips before this redo.
No resampling, rotation, or palette changes touch rigid art.
"""
from pathlib import Path
import argparse
import json
import math
import hashlib

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ART = HERE.parent
SIZE = 384
BG = np.array([255, 0, 255, 255], dtype=np.uint8)
BREATH = [0, 1, 1, 2, 2, 1, 1, 0]
HEAD = [0, 0, 0, 1, 1, 1, 0, 0]
YY, XX = np.indices((SIZE, SIZE))


def polygon(points):
    image = Image.new("1", (SIZE, SIZE))
    ImageDraw.Draw(image).polygon(points, fill=1)
    return np.asarray(image, dtype=bool)


def rect(x0, y0, x1, y1):
    return (XX >= x0) & (XX < x1) & (YY >= y0) & (YY < y1)


def shift(array, dx=0, dy=0):
    result = np.zeros_like(array)
    result[max(0, dy):min(SIZE, SIZE+dy), max(0, dx):min(SIZE, SIZE+dx)] = array[
        max(0, -dy):min(SIZE, SIZE-dy), max(0, -dx):min(SIZE, SIZE-dx)]
    return result


def stamp(canvas, source, mask, dx=0, dy=0):
    moved_mask = shift(mask, dx, dy)
    canvas[moved_mask] = shift(source, dx, dy)[moved_mask]
    return moved_mask


def load_master(name):
    a = np.asarray(Image.open(HERE / f"{name}_master.png").convert("RGBA")).copy()
    assert a.shape == (384, 384, 4)
    # Preserve every original pixel, including the existing solid key background.
    return a, np.any(a[:, :, :3] != BG[:3], axis=2) & (a[:, :, 3] > 0)


def marshal_masks(ink, master):
    # Flag cloth starts to the right of the pole and its metal fasteners.
    flag = ink & rect(228, 74, 310, 218)
    pole = ink & (rect(217, 50, 228, 348) | rect(214, 50, 228, 84)
                  | rect(214, 100, 228, 116) | rect(214, 131, 228, 149)
                  | rect(214, 165, 228, 179))
    tassel = ink & polygon([(228, 260), (242, 281), (242, 307), (228, 307)])
    # Both grips and sword stay in the exact frame-1 pose. Left cuff is the seam.
    sword = ink & polygon([
        (108, 268), (119, 268), (132, 274), (133, 281), (145, 280),
        (145, 289), (161, 306), (181, 328), (199, 355), (197, 359),
        (188, 357), (171, 343), (149, 322), (132, 301), (125, 300),
        (121, 294), (113, 290), (111, 280), (108, 277)])
    # Trace the bright blade's contiguous run, plus its 1-2px dark outline.
    # This avoids freezing a broad diagonal strip of the coat beside the sword.
    rgb = master[:,:,:3].astype(int)
    pale = (rgb.min(axis=2)>105) & ((rgb.max(axis=2)-rgb.min(axis=2))<50)
    for y in range(290, 343):
        sword[y,132:] = False
        middle = round(136+(y-290)*0.84)
        assert pale[y,middle], (y,middle)
        left = right = middle
        while pale[y,left-1]:
            left -= 1
        while pale[y,right+1]:
            right += 1
        sword[y,left-2:right+2] = True
    sword &= ink
    flag_grip = ink & polygon([(211, 220), (227, 218), (234, 222),
                              (234, 238), (216, 241), (210, 233)])
    # Full coat hem, epaulettes, arms, cap, head and torso form one rigid cut-out.
    coat_body = ink & polygon([(70, 150), (211, 150), (214, 217),
        (220, 244), (219, 259), (216, 274), (219, 342),
        (149, 342), (147, 340), (116, 340), (70, 318)])
    fixed = pole | tassel | sword | flag_grip
    body = coat_body & ~fixed & ~flag
    return {"body": body, "flag": flag, "pole": pole, "tassel": tassel,
            "sword_and_grip": sword, "flag_grip": flag_grip,
            "fixed": fixed, "legs": ink & ~body & ~flag & ~fixed}


def pathfinder_masks(ink):
    # The entire rifle, both hands, scarf, armour and pouches belong to the torso.
    upper = ink & polygon([(40, 70), (290, 70), (290, 268), (245, 260),
        (224, 253), (213, 243), (199, 240), (180, 238), (159, 238),
        (143, 237), (140, 261), (78, 266), (40, 240)])
    head = ink & polygon([(140, 77), (224, 77), (224, 135), (203, 135),
        (203, 143), (201, 147), (197, 149), (188, 149), (181, 147),
        (175, 144), (171, 142), (167, 138), (164, 133), (159, 132),
        (153, 130), (151, 128), (148, 126), (140, 126)])
    head &= upper
    return {"body": upper & ~head, "head": head, "upper": upper,
            "legs": ink & ~upper}


def seam_extension(master, body_mask, occluder, dx=0, dy=0):
    """Extend hidden art at most 2px into a foreground cut-out, using exact
    neighbouring master pixels. Only a 1-2px reveal seam can become visible.
    """
    layer = master.copy()
    extra = np.zeros((SIZE, SIZE), dtype=bool)
    for distance in (1, 2):
        nearby = shift(body_mask, dx*distance, dy*distance)
        add = nearby & occluder & ~extra & ~body_mask
        layer[add] = shift(master, dx*distance, dy*distance)[add]
        extra |= add
    return layer, body_mask | extra, extra


def save_masks(name, master, masks):
    colors = [(35, 215, 245), (255, 185, 50), (70, 240, 100),
              (230, 90, 200), (80, 120, 250), (240, 85, 65), (185,185,185)]
    groups = [k for k in masks if k not in ("fixed", "upper")]
    panel = Image.new("RGB", (768, 440), (24, 28, 35))
    panel.paste(Image.fromarray(master).convert("RGB"), (0, 56))
    colorized = master.copy()
    draw = ImageDraw.Draw(panel)
    for i, key in enumerate(groups):
        mask = masks[key]
        Image.fromarray(mask.astype(np.uint8)*255).save(HERE / f"{name}_mask_{key}.png")
        colorized[mask, :3] = colors[i % len(colors)]
        draw.text((10+(i%3)*250, 5+(i//3)*15), key, fill=colors[i%len(colors)])
    panel.paste(Image.fromarray(colorized).convert("RGB"), (384, 56))
    panel.save(HERE / f"{name}_segmentation.png")


def build_marshal(master, ink):
    masks = marshal_masks(ink, master)
    save_masks("banner_marshal", master, masks)
    body_layer, body_extended, seam = seam_extension(
        master, masks["body"], masks["fixed"], dy=-1)
    frames, metadata, effect_masks, seam_masks = [], [], [], []
    for i, dy in enumerate(BREATH):
        frame = master.copy()
        frame[masks["body"] | masks["flag"]] = BG
        # Whole columns of CLOTH only translate vertically; the pole never moves.
        # Smooth periodic travelling wave, subtracting phase-zero so F1 is master.
        offsets = []
        cloth_dest = np.zeros((SIZE, SIZE), dtype=bool)
        for x in range(228, 310):
            amplitude = 2.0 * min(1.0, (x-228)/62.0)
            phase = 2*math.pi*(i/7.0 - (x-228)/100.0)
            baseline = 2*math.pi*(-(x-228)/100.0)
            offset = round(amplitude*(math.sin(phase)-math.sin(baseline)))
            offsets.append(offset)
            part = masks["flag"] & (XX == x)
            cloth_dest |= stamp(frame, master, part, dy=offset)
        stamp(frame, body_layer, body_extended, dy=dy)
        # All stationary pixels (including any occluding weapons) have priority.
        stamp(frame, master, masks["fixed"])
        visible_seam = shift(seam, dy=dy) & ~masks["fixed"]
        if i == 0:
            assert np.array_equal(frame, master), "Marshal F1 drift"
        frames.append(frame)
        effect_masks.append(cloth_dest | masks["flag"])
        seam_masks.append(visible_seam)
        metadata.append({"frame": i+1, "body_dy": dy, "pole_sword_grips_dxy": [0,0],
                         "flag_column_dy": offsets,
                         "flag_occupied_column_range_dy": [min(offsets[x-228] for x in range(228,310) if masks["flag"][:,x].any()),
                                                           max(offsets[x-228] for x in range(228,310) if masks["flag"][:,x].any())],
                         "seam_pixels": int(visible_seam.sum())})
    return frames, masks, metadata, effect_masks, seam_masks


def pathfinder_face(master, i, head):
    face = master.copy()
    changed = np.zeros((SIZE, SIZE), dtype=bool)
    # Screen pixels are the only helmet pixels permitted to change.
    lens = polygon([(192, 91), (200, 92), (205, 97), (209, 101),
                    (208, 105), (196, 105), (193, 102)]) & head
    if i in (3,4,5):
        sweep_x = [197,201,205][i-3]
        glint = lens & (np.abs(XX-sweep_x) <= 1)
        face[glint] = (198, 251, 255, 255)
        changed |= glint
    # Exposed eye whites/iris only, no changes to helmet, brow or face outline.
    rgb = master[:,:,:3].astype(int)
    eye_area = (rect(181,116,191,123) | rect(201,116,208,123)) & head
    eyes = eye_area & (rgb[:,:,1]>rgb[:,:,0]*1.15) & (rgb[:,:,2]>rgb[:,:,0]*1.10)
    if i in (3,5):
        # Translate the existing cyan iris pixels 1px inside the unchanged brow.
        face[eyes] = (42,37,28,255)
        shifted_eyes = shift(eyes,dx=1) & eye_area
        face[shifted_eyes] = shift(master,dx=1)[shifted_eyes]
        changed |= eyes | shifted_eyes
    if i == 4:
        face[eyes] = (136, 88, 54, 255)
        lid = eyes & (YY == 120)
        face[lid] = (42, 37, 28, 255)
        changed |= eyes
    return face, changed


def build_pathfinder(master, ink):
    masks = pathfinder_masks(ink)
    save_masks("pathfinder", master, masks)
    # A narrow hidden scarf/neck backing prevents a hole when the head steps right.
    torso_layer, torso_extended, neck_seam = seam_extension(
        master, masks["body"], masks["head"], dy=-1)
    frames, metadata, effect_masks, seam_masks = [], [], [], []
    for i, (dy, dx) in enumerate(zip(BREATH, HEAD)):
        frame = master.copy()
        frame[masks["upper"]] = BG
        stamp(frame, torso_layer, torso_extended, dy=dy)
        face, changed = pathfinder_face(master, i, masks["head"])
        stamp(frame, face, masks["head"], dx=dx, dy=dy)
        visible_seam = shift(neck_seam, dy=dy) & ~shift(masks["head"], dx=dx, dy=dy)
        if i == 0:
            assert np.array_equal(frame, master), "Pathfinder F1 drift"
        frames.append(frame)
        effect_masks.append(shift(changed, dx=dx, dy=dy))
        seam_masks.append(visible_seam)
        metadata.append({"frame": i+1, "torso_rifle_scarf_dxy": [0,dy],
                         "head_dxy": [dx,dy], "eyes": "blink" if i==4 else "right" if i in (3,5) else "master",
                         "visor_glint": i in (3,4,5), "seam_pixels": int(visible_seam.sum())})
    return frames, masks, metadata, effect_masks, seam_masks


def previews(name, frames):
    # Full native-size plates plus actual game heights (98px leader, 86px light).
    plate = Image.new("RGB", (384*4, 410*2), (24, 28, 35))
    d = ImageDraw.Draw(plate)
    for i, frame in enumerate(frames):
        x, y = (i%4)*384, (i//4)*410
        d.text((x+10, y+5), f"Frame {i+1}", fill="white")
        plate.paste(Image.fromarray(frame).convert("RGB"), (x,y+26))
    plate.save(HERE / f"{name}_contact.png")
    # Cyan = F1 only; orange = F4 only; unchanged pixels retain their colours.
    a, b = frames[0], frames[3]
    changed = np.any(a != b, axis=2)
    overlay = a.copy()
    in_a = np.any(a[:,:,:3] != BG[:3],axis=2)
    in_b = np.any(b[:,:,:3] != BG[:3],axis=2)
    overlay[changed & in_a] = (30,210,255,255)
    overlay[changed & in_b] = (255,160,35,255)
    overlay[changed & in_a & in_b] = (225,225,230,255)
    Image.fromarray(overlay).save(HERE / f"{name}_overlay_f1_f4.png")
    Image.blend(Image.fromarray(a),Image.fromarray(b),0.5).save(HERE / f"{name}_blend_f1_f4.png")
    for label, scale in [("native",1.0),("game", 98/314 if name=="banner_marshal" else 86/286)]:
        rendered = []
        for i, frame in enumerate(frames):
            rgba = frame.copy()
            rgba[np.all(rgba[:,:,:3] == BG[:3],axis=2),3] = 0
            sprite = Image.fromarray(rgba)
            if scale != 1:
                s = round(384*scale)
                sprite = sprite.resize((s,s),Image.Resampling.NEAREST)
            backdrop = Image.new("RGB", (sprite.width, sprite.height+20), (31,37,44))
            backdrop.paste(sprite,(0,20),sprite)
            ImageDraw.Draw(backdrop).text((8,4),f"F{i+1}",fill=(190,200,215))
            rendered.append(backdrop)
        rendered[0].save(HERE/f"{name}_{label}.gif",save_all=True,append_images=rendered[1:],duration=[120,130]*4,loop=0,disposal=2)
        if label == "game":
            game_contact = Image.new("RGB",(rendered[0].width*8,rendered[0].height),(31,37,44))
            for j, rendered_frame in enumerate(rendered):
                game_contact.paste(rendered_frame,(j*rendered[0].width,0))
            game_contact.save(HERE/f"{name}_game_contact.png")
    box = (104,255,225,365) if name=="banner_marshal" else (142,80,222,157)
    w,h = (box[2]-box[0])*5,(box[3]-box[1])*5
    detail = Image.new("RGB",(w*3,h+20),(24,28,35))
    for j,index in enumerate((0,3,4)):
        detail.paste(Image.fromarray(frames[index]).convert("RGB").crop(box).resize((w,h),Image.Resampling.NEAREST),(j*w,20))
        ImageDraw.Draw(detail).text((j*w+5,3),f"Frame {index+1}",fill="white")
    detail.save(HERE/f"{name}_detail.png")


def validate(name, master, frames, masks, metadata, effect_masks, seam_masks):
    feet_y = 348 if name == "banner_marshal" else 326
    report = {"master_sha256": hashlib.sha256(master.tobytes()).hexdigest(),
              "frame_1_exact": bool(np.array_equal(master,frames[0])),
              "frame_8_exact_loop_close": bool(np.array_equal(master,frames[7])),
              "feet_identical": all(np.array_equal(master[feet_y:,:],f[feet_y:,:]) for f in frames),
              "feet_lock_region_y": [feet_y,383],
              "native_cell_size": [384,384], "frames": []}
    for i, frame in enumerate(frames):
        dy = BREATH[i]
        checks = {}
        if name == "banner_marshal":
            for k in ("pole", "tassel", "sword_and_grip", "flag_grip"):
                checks[k] = int(np.count_nonzero(np.any(frame[masks[k]] != master[masks[k]],axis=1)))
            moved = shift(masks["body"],dy=dy) & ~masks["fixed"]
            expected = shift(master,dy=dy)
            checks["rigid_body_visible"] = int(np.count_nonzero(np.any(frame[moved]!=expected[moved],axis=1)))
            legs = masks["legs"] & ~shift(masks["body"],dy=dy)
        else:
            dx = HEAD[i]
            moved_head = shift(masks["head"],dx=dx,dy=dy)
            moved_body = shift(masks["body"],dy=dy) & ~moved_head
            expected = shift(master,dy=dy)
            checks["torso_rifle_scarf"] = int(np.count_nonzero(np.any(frame[moved_body]!=expected[moved_body],axis=1)))
            rigid_head = moved_head & ~effect_masks[i]
            expected = shift(master,dx=dx,dy=dy)
            checks["head_except_eyes_screen"] = int(np.count_nonzero(np.any(frame[rigid_head]!=expected[rigid_head],axis=1)))
            legs = masks["legs"] & ~moved_body & ~moved_head
        legs &= ~seam_masks[i]  # A 1-2px hidden-body reveal can occlude the leg top.
        checks["stationary_legs_visible"] = int(np.count_nonzero(np.any(frame[legs]!=master[legs],axis=1)))
        foot_diff = np.count_nonzero(np.any(master[feet_y:] != frame[feet_y:],axis=2))
        checks["feet_region"] = int(foot_diff)
        for key,count in checks.items():
            assert count==0, f"{name} F{i+1} {key}: {count} pixels changed"
        Image.fromarray(seam_masks[i].astype(np.uint8)*255).save(HERE/f"{name}_seam_f{i+1}.png")
        Image.fromarray(effect_masks[i].astype(np.uint8)*255).save(HERE/f"{name}_effect_f{i+1}.png")
        report["frames"].append({"frame":i+1, "unexpected_pixel_changes":checks,
                                   "permitted_seam_pixels": int(seam_masks[i].sum())})
    assert report["frame_1_exact"] and report["frame_8_exact_loop_close"] and report["feet_identical"]
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--publish",action="store_true")
    args = parser.parse_args()
    reports = {}
    preview_frames = []
    for name, builder in [("banner_marshal",build_marshal),("pathfinder",build_pathfinder)]:
        master, ink = load_master(name)
        frames, masks, metadata, effect_masks, seams = builder(master,ink)
        report = validate(name,master,frames,masks,metadata,effect_masks,seams)
        strip = np.concatenate(frames,axis=1)
        dest = HERE / f"{name}_idle.png"
        Image.fromarray(strip).save(dest)
        # Re-open the actual PNG to ensure serialization did not alter pixels.
        decoded = np.asarray(Image.open(dest).convert("RGBA"))
        assert np.array_equal(decoded,strip)
        previews(name,frames)
        (HERE/f"{name}_motion.json").write_text(json.dumps(metadata,indent=2)+"\n")
        reports[name] = report
        if args.publish:
            Image.fromarray(strip).save(ART/f"{name}_idle.png")
            assert np.array_equal(np.asarray(Image.open(ART/f"{name}_idle.png").convert("RGBA")),strip)
        preview_frames.append(frames)
        print(f"{name}: pixel checks PASS; {dest.name}; published={args.publish}")
    (HERE/"self_check.json").write_text(json.dumps(reports,indent=2)+"\n")
    combined = []
    for i in range(8):
        canvas = Image.new("RGB",(768,408),(31,37,44))
        for j, frames in enumerate(preview_frames):
            a = frames[i].copy()
            a[np.all(a[:,:,:3] == BG[:3],axis=2),3] = 0
            sprite = Image.fromarray(a)
            canvas.paste(sprite,(j*384,24),sprite)
            ImageDraw.Draw(canvas).text((j*384+12,7),f"{'BANNER MARSHAL' if j==0 else 'PATHFINDER'}  /  F{i+1}",fill=(210,220,230))
        combined.append(canvas)
    combined[0].save(HERE/"pilot_preview.gif",save_all=True,append_images=combined[1:],duration=[120,130]*4,loop=0,disposal=2)


if __name__ == "__main__":
    main()
