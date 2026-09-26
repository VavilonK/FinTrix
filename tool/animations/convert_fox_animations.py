"""Deterministic WebM (VP9 + alpha) -> Animated WebP pipeline for Home fox clips.

Source WebM masters live in assets/animations/fox/source/ and are not bundled.
Runtime WebP files are written to assets/animations/fox/runtime/.

Usage: python tool/animations/convert_fox_animations.py [clip ...]
Requires ffmpeg (with libvpx-vp9) on PATH and Pillow with WebP animation.
"""
import os
import subprocess
import sys
import tempfile
from concurrent.futures import ProcessPoolExecutor

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SOURCE = os.path.join(ROOT, 'assets', 'animations', 'fox', 'source')
RUNTIME = os.path.join(ROOT, 'assets', 'animations', 'fox', 'runtime')

SIDE = 720  # Same canvas as the previously approved Home idle WebP.
FPS = 30  # Sources are 60 fps; every clip is resampled identically.
QUALITY = 75
METHOD = 4

# runtime name -> (source name, loops)
CLIPS = {
    'fox_happy_idle': ('fox_happy_idle.webm', True),
    'fox_pet_happy': ('fox_pet_happy.webm', False),
    'fox_pet_hungry': ('fox_pet_hungry.webm', False),
    'fox_feed_happy_basic': ('fox_feed_happy_basic.webm', False),
    'fox_feed_happy_healthy': ('fox_feed_happy_healthy.webm', False),
    'fox_feed_happy_treat': ('fox_feed_happy_treat.webm', False),
    'fox_feed_hungry_basic': ('fox_feed_hungry_basic.webm', False),
    'fox_feed_hungry_healthy': ('fox_feed_hungry_healthy.webm', False),
    'fox_feed_hungry_treat': ('fox_feed_hungry_treat.webm', False),
}

# Static anchors (reduce motion / first-frame fallback / hungry idle).
# runtime name -> (source name, frame index)
STILLS = {
    'fox_happy_still': ('fox_happy_idle.webm', 0),
    'fox_hungry_still': ('fox_pet_hungry.webm', 0),
}


def decode(source, tmp):
    subprocess.run(
        ['ffmpeg', '-v', 'error', '-y', '-c:v', 'libvpx-vp9', '-i', source,
         '-pix_fmt', 'rgba', os.path.join(tmp, '%05d.png')],
        check=True,
    )
    return [os.path.join(tmp, f) for f in sorted(os.listdir(tmp))]


def pick(count, loops):
    target = (count + 1) // 2
    if loops:
        # A loop wraps from its last frame back to frame 0, so keep a uniform
        # step instead of duplicating the anchor at both ends.
        return list(range(0, count, 2))[:target]
    # One-shot clips must end on the exact final source frame (idle anchor).
    return [round(k * (count - 1) / (target - 1)) for k in range(target)]


def load(path):
    # Pillow resizes RGBA in premultiplied space, avoiding dark alpha fringes.
    return Image.open(path).convert('RGBA').resize((SIDE, SIDE), Image.LANCZOS)


def durations(frames):
    edges = [round(i * 1000 / FPS) for i in range(frames + 1)]
    return [b - a for a, b in zip(edges, edges[1:])]


def convert(name):
    source_name, loops = CLIPS[name]
    with tempfile.TemporaryDirectory() as tmp:
        paths = decode(os.path.join(SOURCE, source_name), tmp)
        frames = [load(paths[i]) for i in pick(len(paths), loops)]
    out = os.path.join(RUNTIME, name + '.webp')
    frames[0].save(
        out, save_all=True, append_images=frames[1:], duration=durations(len(frames)),
        loop=0 if loops else 1, quality=QUALITY, method=METHOD, alpha_quality=100,
        lossless=False, minimize_size=False, allow_mixed=False,
    )
    return name, len(frames), sum(durations(len(frames))), os.path.getsize(out)


def still(name):
    source_name, index = STILLS[name]
    with tempfile.TemporaryDirectory() as tmp:
        frame = load(decode(os.path.join(SOURCE, source_name), tmp)[index])
    out = os.path.join(RUNTIME, name + '.webp')
    frame.save(out, quality=90, method=6, alpha_quality=100)
    return name, 1, 0, os.path.getsize(out)


if __name__ == '__main__':
    os.makedirs(RUNTIME, exist_ok=True)
    wanted = sys.argv[1:] or [*CLIPS, *STILLS]
    with ProcessPoolExecutor() as pool:
        jobs = [pool.submit(convert if n in CLIPS else still, n) for n in wanted]
        for job in jobs:
            name, frames, ms, size = job.result()
            print(f'{name:26s} frames={frames:3d} duration={ms}ms size={size / 1e6:.2f}MB')
