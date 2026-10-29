"""Apply only the approved Warden shoulder-particle correction."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
import build_pair_08 as b

HERE = Path(__file__).resolve().parent
path = HERE.parent/"protocol_warden_idle.png"
backup = HERE/"protocol_warden_before_particle_fix.png"
if not backup.exists():
    Image.open(path).save(backup)
old = np.asarray(Image.open(backup).convert("RGBA"))
old_frames = list(np.split(old,8,axis=1))
master,mask = b.restore_warden_particles(old_frames[0])
assert int(mask.sum())==466
fixed = []
for i,(frame,dy) in enumerate(zip(old_frames,b.DIP)):
    f=frame.copy();m=b.shift(mask,dy=dy);donor=b.shift(master,dy=dy)
    f[m]=donor[m]
    assert not np.any(np.any(f!=frame,axis=2)&~m)
    fixed.append(f)
frames,masks,checks,motion,effects,seams = b.build_warden(master)
assert all(np.array_equal(f,g) for f,g in zip(frames,fixed))
for c in checks:
    assert all(v==0 for k,v in c.items() if k.endswith("mismatches") or k.endswith("clipped_pixels"))
result=np.concatenate(fixed,axis=1)
Image.fromarray(result).save(path)
Image.fromarray(result).save(HERE/"protocol_warden_idle.png")
Image.fromarray(master).save(HERE/"protocol_warden_master.png")
b.review("protocol_warden",master,frames,masks,effects,seams)
assert np.array_equal(np.asarray(Image.open(path)),result)
(HERE/"protocol_warden_particle_fix_check.json").write_text(json.dumps({
    "restored_pixels_per_frame":466,"changed_outside_particle_masks":0,
    "base_translation":[172,2],"motion_unchanged":True,"godot_run":False,
    "frames":checks},indent=2)+"\n")
print("protocol_warden: 466 particle pixels restored per frame; zero other changes; saved")
