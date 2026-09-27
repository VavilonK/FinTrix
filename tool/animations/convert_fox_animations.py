"""Deterministic WebM (VP9 + alpha) -> Animated WebP pipeline for Home fox clips.

WebM masters are not bundled with the app:
  stage 1: assets/animations/fox/source/
  stage 2: assets/animations/fox/V2/
  stage 3: assets/animations/fox/V3/
Runtime WebP files are written to assets/animations/fox/runtime/[v2|v3/].

Every source frame is kept (native 60 fps) with integer-millisecond timings
laid out as 17/16/17 ms so the average stays exactly 1000/60 ms.

Usage: python tool/animations/convert_fox_animations.py [v1|v2|v3 ...]
Requires ffmpeg (with libvpx-vp9) on PATH and Pillow with WebP animation.
"""
import os
import struct
import subprocess
import sys
import tempfile
from concurrent.futures import ProcessPoolExecutor

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
FOX = os.path.join(ROOT, 'assets', 'animations', 'fox')

SIDE = 720  # Same canvas for every stage; see PetStageVisualConfig in Dart.
FPS = 60
QUALITY = 75
METHOD = 4

# Runtime clip name -> (source name, loops) per stage.
STAGES = {
    'v1': ('source', 'runtime', {
        'fox_happy_idle': ('fox_happy_idle.webm', True),
        'fox_hungry_idle': ('fox_hungry_idle.webm', True),
        'fox_pet_happy': ('fox_pet_happy.webm', False),
        'fox_pet_hungry': ('fox_pet_hungry.webm', False),
        'fox_feed_happy_basic': ('fox_feed_happy_basic.webm', False),
        'fox_feed_happy_healthy': ('fox_feed_happy_healthy.webm', False),
        'fox_feed_happy_treat': ('fox_feed_happy_treat.webm', False),
        'fox_feed_hungry_basic': ('fox_feed_hungry_basic.webm', False),
        'fox_feed_hungry_healthy': ('fox_feed_hungry_healthy.webm', False),
        'fox_feed_hungry_treat': ('fox_feed_hungry_treat.webm', False),
    }),
    # Stage 2/3 masters: "treats" shows the healthy snack (apple, carrot,
    # biscuits); "cupcake"/"dessert" is the treat.
    'v2': ('V2', os.path.join('runtime', 'v2'), {
        'fox_happy_idle': ('L2_happy_idle_v2_alpha.webm', True),
        'fox_hungry_idle': ('L2_hungry_idle_v3_alpha.webm', True),
        'fox_pet_happy': ('L2_pet_happy_alpha.webm', False),
        'fox_pet_hungry': ('L2_pet_hungry_alpha.webm', False),
        'fox_feed_happy_basic': ('L2_feed_happy_bowl_alpha.webm', False),
        'fox_feed_happy_healthy': ('L2_feed_happy_treats_alpha.webm', False),
        'fox_feed_happy_treat': ('L2_feed_happy_cupcake_alpha.webm', False),
        'fox_feed_hungry_basic': (
            'L2_feed_hungry_to_happy_bowl_alpha.webm', False),
        'fox_feed_hungry_healthy': (
            'L2_feed_hungry_to_happy_treats_alpha.webm', False),
        'fox_feed_hungry_treat': (
            'L2_feed_hungry_to_happy_dessert_alpha.webm', False),
    }),
    'v3': ('V3', os.path.join('runtime', 'v3'), {
        'fox_happy_idle': ('L3_happy_idle_alpha.webm', True),
        'fox_hungry_idle': ('L3_hungry_idle_alpha.webm', True),
        'fox_pet_happy': ('L3_pet_happy_alpha.webm', False),
        'fox_pet_hungry': ('L3_pet_hungry_alpha.webm', False),
        'fox_feed_happy_basic': ('L3_feed_happy_bowl_alpha.webm', False),
        'fox_feed_happy_healthy': ('L3_feed_happy_treats_alpha.webm', False),
        'fox_feed_happy_treat': ('L3_feed_happy_cupcake_alpha.webm', False),
        'fox_feed_hungry_basic': (
            'L3_feed_hungry_to_happy_bowl_alpha.webm', False),
        'fox_feed_hungry_healthy': (
            'L3_feed_hungry_to_happy_treats_alpha.webm', False),
        'fox_feed_hungry_treat': (
            'L3_feed_hungry_to_happy_dessert_alpha.webm', False),
    }),
}

# Anchor frames (reduce motion, first paint): first frame of each idle loop.
STILLS = {
    'fox_happy_still': 'fox_happy_idle',
    'fox_hungry_still': 'fox_hungry_idle',
}


def decode(source, tmp):
    subprocess.run(
        ['ffmpeg', '-v', 'error', '-y', '-c:v', 'libvpx-vp9', '-i', source,
         '-pix_fmt', 'rgba', os.path.join(tmp, '%05d.png')],
        check=True,
    )
    return [os.path.join(tmp, f) for f in sorted(os.listdir(tmp))]


def load(path):
    # Pillow resizes RGBA in premultiplied space, avoiding dark alpha fringes.
    return Image.open(path).convert('RGBA').resize((SIDE, SIDE), Image.LANCZOS)


def durations(frames):
    # 17, 16, 17, 17, 16, 17, ... ms: integer timings averaging 1000/60 ms.
    edges = [round(i * 1000 / FPS) for i in range(frames + 1)]
    return [b - a for a, b in zip(edges, edges[1:])]


def merged_frames(expected, written):
    """Indices of source frames libwebp folded into their predecessor: with
    lossy encoding it treats near-identical frames as unchanged."""
    merged, i, j = [], 0, 0
    while i < len(expected) and j < len(written):
        total, k = expected[i], i + 1
        while total < written[j] and k < len(expected):
            merged.append(k)
            total += expected[k]
            k += 1
        i, j = k, j + 1
    return merged


def mark(frame, index):
    """Give the fully transparent corner pixel an alpha of 2-4/255 (invisible)
    so the lossy encoder no longer treats the frame as unchanged."""
    r, g, b, a = frame.getpixel((0, 0))
    assert a == 0, 'corner pixel must be transparent'
    frame.putpixel((0, 0), (0, 0, 0, 2 + 2 * (index % 2)))


def webp_frames(path):
    """Frame count and per-frame durations read straight from ANMF chunks."""
    with open(path, 'rb') as f:
        data = f.read()
    pos, found = 12, []
    while pos + 8 <= len(data):
        tag, size = data[pos:pos + 4], struct.unpack('<I', data[pos + 4:pos + 8])[0]
        if tag == b'ANMF':
            payload = data[pos + 8:pos + 8 + 16]
            found.append(int.from_bytes(payload[12:15], 'little'))
        pos += 8 + size + (size & 1)
    return found


def convert(job):
    stage, name = job
    source_dir, runtime_dir, clips = STAGES[stage]
    source_name, loops = clips[name]
    with tempfile.TemporaryDirectory() as tmp:
        paths = decode(os.path.join(FOX, source_dir, source_name), tmp)
        frames = [load(p) for p in paths]
        out_dir = os.path.join(FOX, runtime_dir)
        os.makedirs(out_dir, exist_ok=True)
        out = os.path.join(out_dir, name + '.webp')
        expected = durations(len(frames))
        # Every source frame must survive: re-encode, marking folded frames,
        # until the runtime file has exactly the source frame count.
        for _ in range(6):
            frames[0].save(
                out, save_all=True, append_images=frames[1:],
                duration=expected, loop=0 if loops else 1,
                quality=QUALITY, method=METHOD, alpha_quality=100,
                lossless=False, minimize_size=False, allow_mixed=False,
                exact=True,
            )
            merged = merged_frames(expected, webp_frames(out))
            if not merged:
                break
            for index in merged:
                mark(frames[index], index)
        for still, idle in STILLS.items():
            if idle == name:
                frames[0].save(
                    os.path.join(out_dir, still + '.webp'),
                    quality=90, method=6, alpha_quality=100,
                )
    written = webp_frames(out)
    return stage, name, len(paths), len(written), sum(written), os.path.getsize(out)


if __name__ == '__main__':
    stages = sys.argv[1:] or list(STAGES)
    jobs = [(stage, name) for stage in stages for name in STAGES[stage][2]]
    # Each 60 fps clip holds ~300 decoded 720px frames (~600 MB) in memory.
    with ProcessPoolExecutor(max_workers=3) as pool:
        for stage, name, src, out, ms, size in pool.map(convert, jobs):
            fps = out * 1000 / ms if ms else 0
            flag = '' if src == out else '  FRAME COUNT MISMATCH'
            print(f'{stage} {name:24s} source={src} runtime={out} '
                  f'duration={ms}ms fps={fps:.3f} size={size / 1e6:.2f}MB{flag}')
