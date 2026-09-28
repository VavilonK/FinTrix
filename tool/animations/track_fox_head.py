"""Per-frame eye positions for every Home fox clip (accessory placement).

Each frame is registered (SIFT + RANSAC similarity) against the stage's happy
and hungry anchor poses; the better match carries the anchor's pupil centres
into the frame. Clips start and end on an anchor pose, so first/last frames
are pinned to the exact anchor values and the track is lightly smoothed.

Usage: python tool/animations/track_fox_head.py FRAMES_ROOT [v1 v2 v3]
FRAMES_ROOT/<dir>/*.png are decoded 960px RGBA frames of the WebM masters
(see FRAMES for the directory names).
Writes assets/animations/fox/runtime/[v2|v3/]<clip>.pose.json
"""
import json
import os
import sys
from concurrent.futures import ProcessPoolExecutor

import cv2
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter1d

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
RUNTIME = os.path.join(ROOT, 'assets', 'animations', 'fox', 'runtime')
SIDE = 960

# Pupil centres of the anchor poses (960px canvas), measured on frame 0 of
# each idle loop.
ANCHORS = {
    'v1': {'happy': [(401.8, 398.7), (571.2, 434.3)],
           'hungry': [(433.9, 358.6), (591.1, 407.4)]},
    'v2': {'happy': [(417.9, 351.1), (558.2, 379.9)],
           'hungry': [(448.3, 317.7), (584.4, 357.8)]},
    'v3': {'happy': [(429.2, 347.2), (562.3, 379.7)],
           'hungry': [(441.0, 326.0), (582.3, 363.7)]},
}

# runtime clip -> (start pose, end pose)
CLIPS = {
    'fox_happy_idle': ('happy', 'happy'),
    'fox_hungry_idle': ('hungry', 'hungry'),
    'fox_pet_happy': ('happy', 'happy'),
    'fox_pet_hungry': ('hungry', 'hungry'),
    'fox_feed_happy_basic': ('happy', 'happy'),
    'fox_feed_happy_healthy': ('happy', 'happy'),
    'fox_feed_happy_treat': ('happy', 'happy'),
    'fox_feed_hungry_basic': ('hungry', 'happy'),
    'fox_feed_hungry_healthy': ('hungry', 'happy'),
    'fox_feed_hungry_treat': ('hungry', 'happy'),
}

FRAMES = {
    'v1': {'fox_happy_idle': 'happy_idle', 'fox_hungry_idle': 'hungry_idle',
           'fox_pet_happy': 'pet_happy', 'fox_pet_hungry': 'pet_hungry',
           'fox_feed_happy_basic': 'feed_happy',
           'fox_feed_happy_healthy': 'feed_treats',
           'fox_feed_happy_treat': 'feed_cupcake',
           'fox_feed_hungry_basic': 'h2h_bowl',
           'fox_feed_hungry_healthy': 'h2h_v6',
           'fox_feed_hungry_treat': 'h2h_dessert'},
    'v2': {'fox_happy_idle': 'g/L2_happy_idle_v2_alpha',
           'fox_hungry_idle': 'g/L2_hungry_idle_v3_alpha',
           'fox_pet_happy': 'g/L2_pet_happy_alpha',
           'fox_pet_hungry': 'g/L2_pet_hungry_alpha',
           'fox_feed_happy_basic': 'g/L2_feed_happy_bowl_alpha',
           'fox_feed_happy_healthy': 'g/L2_feed_happy_treats_alpha',
           'fox_feed_happy_treat': 'g/L2_feed_happy_cupcake_alpha',
           'fox_feed_hungry_basic': 'g/L2_feed_hungry_to_happy_bowl_alpha',
           'fox_feed_hungry_healthy': 'g/L2_feed_hungry_to_happy_treats_alpha',
           'fox_feed_hungry_treat': 'g/L2_feed_hungry_to_happy_dessert_alpha'},
}
FRAMES['v3'] = {k: v.replace('L2_', 'L3_').replace('_v2_alpha', '_alpha')
                .replace('_v3_alpha', '_alpha') for k, v in FRAMES['v2'].items()}


def gray(path):
    rgba = np.asarray(Image.open(path).convert('RGBA')).astype(np.float32)
    a = rgba[..., 3:] / 255
    g = (rgba[..., :3] * a + 128 * (1 - a)).mean(-1)
    return np.clip(g, 0, 255).astype(np.uint8)


def head_mask(eyes):
    (lx, ly), (rx, ry) = eyes
    d = np.hypot(rx - lx, ry - ly)
    cx, cy = (lx + rx) / 2, (ly + ry) / 2 + 0.25 * d
    m = np.zeros((SIDE, SIDE), np.uint8)
    cv2.ellipse(m, (int(cx), int(cy)), (int(1.55 * d), int(1.25 * d)),
                0, 0, 360, 255, -1)
    return m


class Reference:
    def __init__(self, path, eyes, sift):
        self.eyes = np.array(eyes, np.float64)
        self.kp, self.des = sift.detectAndCompute(gray(path), head_mask(eyes))


def register(matcher, ref, kp, des):
    if des is None or len(kp) < 8:
        return None, 0
    pairs = matcher.knnMatch(ref.des, des, k=2)
    good = [p[0] for p in pairs
            if len(p) == 2 and p[0].distance < 0.75 * p[1].distance]
    if len(good) < 8:
        return None, 0
    src = np.float32([ref.kp[m.queryIdx].pt for m in good])
    dst = np.float32([kp[m.trainIdx].pt for m in good])
    M, inl = cv2.estimateAffinePartial2D(
        src, dst, method=cv2.RANSAC, ransacReprojThreshold=3.0, maxIters=4000)
    if M is None:
        return None, 0
    return M, int(inl.sum())


def track(job):
    frames_root, stage, clip = job
    start, end = CLIPS[clip]
    anchors = ANCHORS[stage]
    sift = cv2.SIFT_create(nfeatures=3000)
    matcher = cv2.BFMatcher(cv2.NORM_L2)
    refs = {}
    for pose, key in (('happy', 'fox_happy_idle'), ('hungry', 'fox_hungry_idle')):
        d = os.path.join(frames_root, FRAMES[stage][key])
        refs[pose] = Reference(os.path.join(d, sorted(os.listdir(d))[0]),
                               anchors[pose], sift)
    folder = os.path.join(frames_root, FRAMES[stage][clip])
    files = sorted(os.listdir(folder))
    n = len(files)
    eyes = np.full((n, 4), np.nan)
    quality = np.zeros(n)
    for i, f in enumerate(files):
        kp, des = sift.detectAndCompute(gray(os.path.join(folder, f)), None)
        best = (None, 0, None)
        for ref in refs.values():
            M, inliers = register(matcher, ref, kp, des)
            if inliers > best[1]:
                best = (M, inliers, ref)
        M, inliers, ref = best
        quality[i] = inliers
        if M is not None:
            eyes[i] = (ref.eyes @ M[:, :2].T + M[:, 2]).ravel()
    raw_last = eyes[-1].copy()
    # Weak registrations are re-filled from their neighbours.
    bad = (quality < 25) | np.isnan(eyes).any(1)
    idx = np.arange(n)
    if (~bad).any():
        for c in range(4):
            eyes[:, c] = np.interp(idx, idx[~bad], eyes[~bad, c])
    eyes = gaussian_filter1d(eyes, 1.2, axis=0, mode='nearest')
    first = np.array(anchors[start]).ravel()
    last = np.array(anchors[end]).ravel()
    error_last = float(np.abs(raw_last - last).max())
    # Pin the anchor frames exactly, blending the pin in over a few frames.
    w0 = np.clip(1 - idx / 6, 0, 1)[:, None]
    w1 = np.clip(1 - (n - 1 - idx) / 6, 0, 1)[:, None]
    eyes = eyes * (1 - w0) + first * w0
    eyes = eyes * (1 - w1) + last * w1
    out_dir = RUNTIME if stage == 'v1' else os.path.join(RUNTIME, stage)
    data = {
        'canvas': SIDE,
        'frames': n,
        # Per frame: left pupil x, y, right pupil x, y, normalised to canvas.
        'eyes': [[round(v / SIDE, 5) for v in row] for row in eyes],
    }
    with open(os.path.join(out_dir, clip + '.pose.json'), 'w') as f:
        json.dump(data, f, separators=(',', ':'))
    return stage, clip, n, int(bad.sum()), int(quality.min()), error_last


if __name__ == '__main__':
    root = sys.argv[1]
    stages = sys.argv[2:] or ['v1', 'v2', 'v3']
    jobs = [(root, s, c) for s in stages for c in CLIPS]
    with ProcessPoolExecutor(max_workers=5) as pool:
        for stage, clip, n, bad, qmin, err in pool.map(track, jobs):
            print(f'{stage} {clip:24s} frames={n} weak={bad} '
                  f'min_inliers={qmin} last_frame_error={err:.1f}px')
