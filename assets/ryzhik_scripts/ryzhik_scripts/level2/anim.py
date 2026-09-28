import numpy as np, cv2, sys, os
from PIL import Image

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'fox_hungry.png')
OUT = sys.argv[1] if len(sys.argv) > 1 else 'frames'
DEBUG = os.environ.get('DEBUG')
os.makedirs(OUT, exist_ok=True)

img = np.array(Image.open(SRC)).astype(np.float32) / 255.0

# --- clean the cut-out edge: semi-transparent rim pixels take the colour of the solid fur next to them
from scipy.ndimage import distance_transform_edt as _edt
_al = img[..., 3]; _inner = _al > 0.92
_, (_iy, _ix) = _edt(~_inner, return_indices=True)
_t = np.clip((_al - 0.35) / 0.55, 0, 1)[..., None]
img[..., :3] = img[..., :3] * _t + img[_iy, _ix, :3] * (1 - _t)
img[..., 3] = np.clip((_al - 0.02) / 0.98, 0, 1)
a = img[..., 3:4]
pm = np.concatenate([img[..., :3] * a, a], -1)  # premultiplied

W = 960; FPS = 60; DUR = 5.0; N = int(FPS * DUR)
S = 0.686400; OX, OY = 94.0800, 57.3600  # placement in output frame (matches reference framing)

yy, xx = np.mgrid[0:W, 0:W].astype(np.float32)
X0 = (xx - OX) / S; Y0 = (yy - OY) / S  # output pixel -> source coords (rest pose)

def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)

def bump(t, t0, t1, rise):  # smooth 0->1->0 envelope
    return float(ss(t0, t0 + rise, t) * (1 - ss(t1 - rise, t1, t)))

def rot(X, Y, px, py, ang):  # rotate points around pivot by ang (per-pixel array ok)
    c, s = np.cos(ang), np.sin(ang); dx, dy = X - px, Y - py
    return px + c * dx - s * dy, py + s * dx + c * dy

# ---------- static masks (in source coords) ----------
head_w = 1 - ss(600, 720, Y0)                                  # head + ears
tail_w = ss(800, 900, X0) * ss(560, 660, Y0) * (1 - head_w * (X0 < 1000))
tail_w = ss(810, 900, X0) * ss(575, 645, Y0)
d_tail = np.hypot(X0 - 870, Y0 - 1090)
tail_w = tail_w * ss(60, 420, d_tail)
rear_w = ss(880, 960, X0) * (1 - ss(440, 520, Y0)) * ss(300, 340, Y0)   # right ear
lear_w = (1 - ss(320, 380, X0)) * (1 - ss(420, 480, Y0))               # left ear
breath_up = ss(1110, 700, Y0)          # 0 at paws -> 1 at chest and above
chest_w = ss(1060, 820, Y0) * (1 - ss(620, 700, Y0)) + 0 * X0

EYES = [  # cx, cy, a (half-width), b (half-height), tilt(rad)
    (479.5, 386.5, 70.0, 64.0, np.deg2rad(8)),
    (720.5, 438.5, 72.0, 64.0, np.deg2rad(8)),
]


# ---------- eyelids (painted in rest pose, then warped with the head) ----------
_em = np.load(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'eyemasks.npy'))
EYEM = []
for m in _em:
    cs, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    hull = cv2.convexHull(np.vstack(cs)); mm = np.zeros_like(m); cv2.fillPoly(mm, [hull], 1)
    mm = cv2.dilate(mm, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (13, 13)))
    ys, xs = np.nonzero(mm); x0, x1 = xs.min(), xs.max()
    top = np.full(img.shape[1], np.nan); bot = np.full(img.shape[1], np.nan)
    for x in range(x0, x1 + 1):
        col = np.nonzero(mm[:, x])[0]; top[x], bot[x] = col.min(), col.max()
    # lid colour: robust per-column median of fur above the eye, smoothed -> soft cartoon lid
    cols = np.zeros((img.shape[1], 4), np.float32)
    for x in range(x0, x1 + 1):
        band = pm[int(top[x]) - 30:int(top[x]) - 6, x]
        lum = band[:, :3].sum(1); keep = band[lum > np.percentile(lum, 40)]
        cols[x] = np.median(keep, 0)
    for x in range(x0): cols[x] = cols[x0]
    for x in range(x1 + 1, len(cols)): cols[x] = cols[x1]
    cols = cv2.GaussianBlur(cols[None], (0, 0), sigmaX=16)[0]
    tex = np.repeat(cols[None], img.shape[0], 0)
    # add a hint of the original fur grain above the eye so it isn't flat
    grain = pm - cv2.GaussianBlur(pm, (0, 0), 3)
    gsh = np.zeros_like(pm)
    for x in range(x0, x1 + 1):
        t0, b0 = int(top[x]), int(bot[x]); yy_ = np.arange(t0, b0 + 1)
        k_ = (yy_ - t0) % 40; k_ = np.where(k_ < 20, k_, 39 - k_)   # mirror-tile the fur just above the lid
        gsh[yy_, x] = grain[t0 - 26 + k_, x]
    tex = tex * np.array([1.0, 0.93, 0.86, 1.0], np.float32)
    # rounded eyelid: soft spherical shading with a gentle highlight up top
    ecx, ecy = (x0 + x1) / 2, (np.nanmin(top) + np.nanmax(bot)) / 2
    rx, ry = (x1 - x0) / 2, (np.nanmax(bot) - np.nanmin(top)) / 2
    gy, gx = np.mgrid[0:img.shape[0], 0:img.shape[1]].astype(np.float32)
    rr = ((gx - ecx) / rx) ** 2 + ((gy - ecy) / ry) ** 2
    hl = np.exp(-(((gx - ecx) / (0.45 * rx)) ** 2 + ((gy - (ecy - 0.35 * ry)) / (0.35 * ry)) ** 2))
    shade_ = np.clip(1.0 - 0.16 * rr + 0.06 * hl, 0.75, 1.08)
    tex[..., :3] *= shade_[..., None]
    mmf = cv2.GaussianBlur(mm.astype(np.float32), (0, 0), 1.6)
    EYEM.append((cv2.GaussianBlur(mm.astype(np.float32), (0, 0), 2.6), x0, x1, top, bot, tex))

# --- L2: eyelids made of the surrounding fur (inpainted) instead of a flat tone ---
_rgb8L = (np.clip(img[..., :3], 0, 1) * 255).astype(np.uint8)
_allm = np.zeros(img.shape[:2], np.uint8)
for _e in EYEM: _allm |= (_e[0] > 0.05).astype(np.uint8)
_allm = cv2.dilate(_allm, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15)))
_inp = cv2.inpaint(_rgb8L, _allm * 255, 21, cv2.INPAINT_TELEA).astype(np.float32) / 255
_inp = np.where(_allm[..., None] > 0, cv2.GaussianBlur(_inp, (0, 0), 12), _inp)
_hp = img[..., :3] - cv2.GaussianBlur(img[..., :3], (0, 0), 2.0)
_new = []
for (mm_, x0_, x1_, top_, bot_, tex_) in EYEM:
    ys_, xs_ = np.nonzero(mm_ > 0.05); y0_, y1_ = ys_.min(), ys_.max()
    _fm = (mm_ > 0.05).astype(np.uint8)
    _gyy2, _gxx2 = np.mgrid[0:img.shape[0], 0:img.shape[1]].astype(np.float32)
    _ymid = (y0_ + y1_) / 2
    _ring = (cv2.dilate(_fm, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (61, 61))) > 0) & (_fm == 0)
    _tp = img[..., :3][_ring & (_gyy2 < _ymid)]
    _ok = (_tp.mean(-1) > 150 / 255) & (_tp[:, 0] - _tp[:, 2] > 0.25)
    _c = np.median(_tp[_ok], 0)
    _bp = img[..., :3][_ring & (_gyy2 > _ymid + 0.25 * (y1_ - y0_))]
    _bok = _bp.mean(-1) > 170 / 255
    _cb = np.median(_bp[_bok], 0) if _bok.sum() > 20 else _c
    _vy = (_gyy2 - y0_) / max(y1_ - y0_, 1)
    _t = ss(0.55, 1.05, _vy)[..., None]
    lid = (_c[None, None, :] * (1 - _t) + _cb[None, None, :] * _t) * (1.02 - 0.04 * np.clip(_vy, 0, 1))[..., None]
    _px0, _py0, _px1, _py1 = (545, 290, 615, 360)                                   # plain fur between the eyes
    _g = _hp[_py0:_py1, _px0:_px1]
    _g = np.concatenate([_g, _g[:, ::-1]], 1); _g = np.concatenate([_g, _g[::-1]], 0)
    _T = np.tile(_g, (img.shape[0] // _g.shape[0] + 1, img.shape[1] // _g.shape[1] + 1, 1))[:img.shape[0], :img.shape[1]]
    _rng = np.random.default_rng(3)
    _n = cv2.GaussianBlur(_rng.normal(0, 1, img.shape[:2]).astype(np.float32), (0, 0), 0.8)
    _n = cv2.GaussianBlur(_n, (0, 0), sigmaX=0.6, sigmaY=2.5)            # short vertical fur strokes
    lid = lid + 0.035 * _n[..., None]
    cx_, cy_ = (x0_ + x1_) / 2, (y0_ + y1_) / 2; rx_, ry_ = (x1_ - x0_) / 2, (y1_ - y0_) / 2
    gy_, gx_ = np.mgrid[0:img.shape[0], 0:img.shape[1]].astype(np.float32)
    rr_ = ((gx_ - cx_) / rx_) ** 2 + ((gy_ - cy_) / ry_) ** 2
    lid *= np.clip(1.02 - 0.06 * rr_, 0.9, 1.03)[..., None]          # a hint of the round eyeball under the lid
    tex2 = np.concatenate([np.clip(lid, 0, 1), np.ones_like(lid[..., :1])], -1)
    _new.append((cv2.GaussianBlur((mm_ > 0.05).astype(np.float32), (0, 0), 5.0), x0_, x1_, top_, bot_, tex2))
EYEM = _new
YS = np.arange(img.shape[0], dtype=np.float32)[:, None]

def paint_lids(pm_, blink):
    out = pm_.copy()
    blink = min(1.0, blink * 1.15)
    for (mm, x0, x1, top, bot, tex) in EYEM:
        sl = slice(x0 - 4, x1 + 5)
        tp, bt = top[sl], bot[sl]
        tp = np.where(np.isnan(tp), np.nanmean(top), tp); bt = np.where(np.isnan(bt), tp, bt)
        yL = tp + 2 + blink * (bt - tp + 2)          # fully closed at blink = 1
        yLash = yL - 6 * blink                      # lid edge per column
        m = mm[:, sl]
        lidm = np.clip((yL[None, :] - YS) / 2.0 + 0.5, 0, 1) * m   # soft edge
        # soft shading toward the lid edge
        shade = 1 - 0.10 * np.clip(1 - (yL[None, :] - YS) / 25.0, 0, 1)
        T = tex[:, sl] * np.concatenate([np.repeat(shade[..., None], 3, -1), np.ones_like(shade[..., None])], -1)
        o = out[:, sl]
        o[:] = o * (1 - lidm[..., None]) + T * lidm[..., None]
        # lash line along lid edge, tapered at the eye corners
        w = tp.shape[0]; uu = np.linspace(-1, 1, w)
        thick = (2.0 + 3.5 * blink) * np.clip(1 - uu ** 4, 0, 1)
        d = np.abs(YS - yLash[None, :]) - thick[None, :]
        lash = np.clip(0.5 - d / 1.5, 0, 1) * min(1, blink * 6) * (np.abs(uu) < 0.97)[None, :]
        dark = np.array([0.16, 0.09, 0.06, 1.0], np.float32) * np.maximum(o[..., 3:4], 1e-3)
        dark[..., 3] = o[..., 3]
        o[:] = o * (1 - lash[..., None]) + dark * lash[..., None]
    return out

def frame(i):
    t = i / N; tau = 2 * np.pi * t
    X, Y = X0.copy(), Y0.copy()

    # --- gaze toward stomach (with head dip / small hunch) ---
    g = bump(t, 0.20, 0.52, 0.08)
    # --- side glance later in the loop ---
    sg = bump(t, 0.76, 0.94, 0.05)
    # --- two blinks ---
    def blink_at(t0):
        tb = (t - t0) * DUR
        if 0 <= tb < 0.08: return float(ss(0, 0.08, tb))
        if 0.08 <= tb < 0.14: return 1.0
        if 0.14 <= tb < 0.28: return float(1 - ss(0.14, 0.28, tb))
        return 0.0
    blink = max(blink_at(0.06), blink_at(0.66))
    # --- ear twitches ---
    tw = bump(t, 0.56, 0.64, 0.03)     # right ear
    tw2 = bump(t, 0.36, 0.44, 0.03)    # left ear

    # breathing (2 cycles per loop), clearly visible
    br = np.sin(2 * tau)
    Y = Y + 6.5 * br * breath_up
    cx = 565
    X = cx + (X - cx) / (1 + 0.016 * br * chest_w)
    # hunch a little while looking at the tummy
    Y = Y + 6.0 * g * breath_up

    # whole upper body sways gently side to side (paws stay planted)
    ang_b = np.deg2rad(1.6 * np.sin(tau + 0.3))
    Xb, Yb = rot(X, Y, 565, 1120, -ang_b)
    X = X + (Xb - X) * breath_up; Y = Y + (Yb - Y) * breath_up

    # head: tilt sway, bob lagging the breath, dip toward tummy, tilt on side glance
    ang_h = np.deg2rad(2.8 * np.sin(tau + 0.6) - 3.5 * g + 3.0 * sg)
    Xh, Yh = rot(X, Y, 560, 690, -ang_h)
    X = X + (Xh - X) * head_w; Y = Y + (Yh - Y) * head_w
    Y = Y + (-9.0 * g + 2.5 * np.sin(2 * tau - 0.9)) * head_w
    X = X + (5.0 * sg) * head_w

    # ears: soft drift + a twitch each
    ang_re = np.deg2rad(3.0 * np.sin(tau + 1.7) + 10.0 * tw * np.sin(np.pi * 2 * min(1, max(0, (t - 0.56) / 0.08))) + 2.0 * g)
    Xe, Ye = rot(X, Y, 895, 395, -ang_re)
    X = X + (Xe - X) * rear_w; Y = Y + (Ye - Y) * rear_w
    ang_le = np.deg2rad(-2.6 * np.sin(tau + 2.4) - 8.0 * tw2 - 2.0 * g)
    Xe, Ye = rot(X, Y, 345, 340, -ang_le)
    X = X + (Xe - X) * lear_w; Y = Y + (Ye - Y) * lear_w

    # tail: bigger sway plus a lagging curl toward the tip
    ang_t = np.deg2rad(7.0 * np.sin(tau - 0.8) + 1.5 * np.sin(2 * tau + 0.3))
    Xt, Yt = rot(X, Y, 870, 1090, -ang_t)
    X = X + (Xt - X) * tail_w; Y = Y + (Yt - Y) * tail_w
    ang_tip = np.deg2rad(6.0 * np.sin(tau - 1.9))
    tip_w = tail_w ** 2.2
    Xt, Yt = rot(X, Y, 950, 870, -ang_tip)
    X = X + (Xt - X) * tip_w; Y = Y + (Yt - Y) * tip_w

    # eyes (in rest-pose coords, so they ride along with the head)
    for (ecx, ecy, ea, eb, et) in EYES:
        c, s = np.cos(et), np.sin(et)
        u = (X - ecx) * c + (Y - ecy) * s
        v = -(X - ecx) * s + (Y - ecy) * c
        inside = np.clip(1 - (u / ea) ** 2, 0, 1)
        h = eb * np.sqrt(inside) + 1e-3
        u2, v2 = u.copy(), v.copy()
        # gaze: shift iris/pupil down-left inside the eye with falloff
        if g > 0 or sg > 0:
            r = np.hypot(u / ea, v / eb)
            fall = (1 - ss(0.55, 1.0, r))
            u2 = u2 - (-4.0 * g + 11.0 * sg) * fall
            v2 = v2 - (12.0 * g - 3.0 * sg) * fall
        X = ecx + u2 * c - v2 * s
        Y = ecy + u2 * s + v2 * c

    src = paint_lids(pm, blink) if blink > 0 else pm
    out = cv2.remap(src, X.astype(np.float32), Y.astype(np.float32), cv2.INTER_CUBIC,
                    borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
    out = np.clip(out, 0, 1)
    al = out[..., 3:4]
    rgb = np.where(al > 1e-4, out[..., :3] / np.maximum(al, 1e-4), 0)
    rgba = np.concatenate([np.clip(rgb, 0, 1), al], -1)
    return (rgba * 255 + 0.5).astype(np.uint8)

idx = [int(x) for x in os.environ['ONLY'].split(',')] if os.environ.get('ONLY') else range(N)
for i in idx:
    Image.fromarray(frame(i)).save(f'{OUT}/f{i:04d}.png')
print('done')
