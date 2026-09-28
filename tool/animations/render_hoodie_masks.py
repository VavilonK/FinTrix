"""Per-frame hoodie masks for every Home fox clip (hoodie colour variants).

The approved scripts in assets/ryzhik_scripts/ryzhik_scripts are deterministic.
They are run twice on copies of each level folder whose fox images have the
hoodie's green channel forced to 1 and to 0 (the scripts find the hoodie with
blue/red only, so geometry is unchanged). The per-pixel green difference of
the two renders is exactly the visible hoodie coverage, including food and
paws drawn over it.

Masks are written as animated WebP (white RGB, coverage in alpha) at MASK_SIDE
next to the runtime clips: assets/animations/fox/runtime/[v2|v3/]<clip>.hoodie.webp

Usage: python tool/animations/render_hoodie_masks.py WORK_DIR [clip ...]
Requires the script dependencies (numpy, opencv-python, pillow, scipy).
"""
import os
import shutil
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SCRIPTS = os.path.join(ROOT, 'assets', 'ryzhik_scripts', 'ryzhik_scripts')
RUNTIME = os.path.join(ROOT, 'assets', 'animations', 'fox', 'runtime')
MASK_SIDE = 320
FPS = 60

# (level folder, runtime dir, clip, script, env)
JOBS = []
for level, out in (('level1', ''), ('level2', 'v2'), ('level3', 'v3')):
    for clip, script, env in (
        ('fox_happy_idle', 'anim_happy.py', {}),
        ('fox_hungry_idle', 'anim.py', {}),
        ('fox_pet_happy', 'anim_pet7.py', {}),
        ('fox_pet_hungry', 'anim_pethungry.py', {}),
        ('fox_feed_happy_basic', 'anim_feed_v4.py', {}),
        ('fox_feed_happy_healthy', 'anim_feed_items.py', {'ITEM': 'treats'}),
        ('fox_feed_happy_treat', 'anim_feed_items.py', {'ITEM': 'cupcake'}),
        ('fox_feed_hungry_basic', 'anim_feed_h2h.py', {'ITEM': 'bowl'}),
        ('fox_feed_hungry_healthy', 'anim_feed_h2h.py', {'ITEM': 'treats'}),
        ('fox_feed_hungry_treat', 'anim_feed_h2h.py', {'ITEM': 'cupcake'}),
    ):
        JOBS.append((level, out, clip, script, env))

FOX_IMAGES = ('fox_happy.png', 'fox_hungry.png', 'fox_petting_love.png')


def hoodie(rgba):
    """The scripts' own hoodie test (blue clearly above red), opaque only."""
    return (rgba[..., 2] > rgba[..., 0] + 0.08) & (rgba[..., 3] > 0.3)


def keyed_level(work, level, green):
    dst = os.path.join(work, f'{level}_g{green}')
    if os.path.isdir(dst):
        return dst
    tmp = dst + '_tmp'
    shutil.rmtree(tmp, ignore_errors=True)
    shutil.copytree(os.path.join(SCRIPTS, level), tmp,
                    ignore=shutil.ignore_patterns('__pycache__', 'originals'))
    for name in FOX_IMAGES:
        path = os.path.join(tmp, name)
        img = Image.open(path)
        mode = img.mode
        a = np.asarray(img.convert('RGBA')).astype(np.float32) / 255
        m = hoodie(a)
        a[..., 1][m] = float(green)
        out = Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8), 'RGBA')
        (out if mode == 'RGBA' else out.convert(mode)).save(path)
    os.replace(tmp, dst)
    return dst


def render(level_dir, script, env, out):
    if os.path.isdir(out) and os.path.exists(os.path.join(out, 'DONE')):
        return
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    subprocess.run([sys.executable, script, out], cwd=level_dir, check=True,
                   env={**os.environ, **env}, stdout=subprocess.DEVNULL)
    open(os.path.join(out, 'DONE'), 'w').close()


def run(job):
    work, (level, out_dir, clip, script, env) = job
    renders = []
    for green in (1, 0):
        out = os.path.join(work, 'renders', f'{level}_{clip}_g{green}')
        render(keyed_level(work, level, green), script, env, out)
        renders.append(out)
    n, size = build_mask(work, level, out_dir, clip)
    for out in renders:
        shutil.rmtree(out, ignore_errors=True)
    return level, clip, n, size


def build_mask(work, level, out_dir, clip):
    d1 = os.path.join(work, 'renders', f'{level}_{clip}_g1')
    d0 = os.path.join(work, 'renders', f'{level}_{clip}_g0')
    files = sorted(f for f in os.listdir(d1) if f.endswith('.png'))
    frames = []
    for f in files:
        g1 = np.asarray(Image.open(os.path.join(d1, f)).convert('RGBA')).astype(np.float32)
        g0 = np.asarray(Image.open(os.path.join(d0, f)).convert('RGBA')).astype(np.float32)
        # Unpremultiplied green difference times alpha = hoodie coverage.
        cover = np.clip((g1[..., 1] - g0[..., 1]) / 255 * (g1[..., 3] / 255), 0, 1)
        m = Image.fromarray((cover * 255 + 0.5).astype(np.uint8), 'L')
        m = m.resize((MASK_SIDE, MASK_SIDE), Image.BOX)
        frame = Image.new('RGBA', m.size, (255, 255, 255, 0))
        frame.putalpha(m)
        frames.append(frame)
    target = os.path.join(RUNTIME, out_dir, clip + '.hoodie.webp')
    save_mask(frames, target)
    return len(frames), os.path.getsize(target)


def save_mask(frames, target):
    """Animated mask with exactly one image per clip frame. The encoder
    merges identical neighbours (a still hoodie), so every other repeat gets
    an alpha of 1/255 in its corner pixel, which is invisible."""
    frames = [f.copy() for f in frames]
    previous = None
    for index, frame in enumerate(frames):
        if previous is not None and frame.tobytes() == previous:
            r, g, b, a = frame.getpixel((0, 0))
            frame.putpixel((0, 0), (r, g, b, 1 if a == 0 else a - 1))
        previous = frame.tobytes()
    edges = [round(i * 1000 / FPS) for i in range(len(frames) + 1)]
    durations = [b - a for a, b in zip(edges, edges[1:])]
    frames[0].save(target, save_all=True, append_images=frames[1:],
                   duration=durations, loop=0, lossless=True, method=4,
                   minimize_size=False, allow_mixed=False, exact=True)


if __name__ == '__main__':
    work = sys.argv[1]
    wanted = set(sys.argv[2:])
    jobs = [j for j in JOBS if not wanted or f'{j[0]}/{j[2]}' in wanted]
    os.makedirs(os.path.join(work, 'renders'), exist_ok=True)
    for level in {j[0] for j in jobs}:
        for green in (0, 1):
            keyed_level(work, level, green)
    with ProcessPoolExecutor(max_workers=10) as pool:
        for level, clip, n, size in pool.map(run, [(work, j) for j in jobs]):
            print(f'mask {level} {clip} frames={n} size={size / 1e3:.0f}KB',
                  flush=True)
