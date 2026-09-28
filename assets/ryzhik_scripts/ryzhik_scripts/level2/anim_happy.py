"""Happy idle: re-renders the reference clip's motion on the sharp source image.
Motion (body / head / ears / tail similarity transforms + blink curve) is tracked
from the reference video (track.py -> tracks.npy, open.npy) and made loopable."""
import numpy as np, cv2, sys, os
from PIL import Image
from scipy.ndimage import gaussian_filter1d

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'fox_happy.png')
OUT = sys.argv[1] if len(sys.argv) > 1 else 'frames_happy'
os.makedirs(OUT, exist_ok=True)

img = np.array(Image.open(SRC)).astype(np.float32) / 255.0

# --- clean the cut-out edge: semi-transparent rim pixels take the colour of the solid fur next to them
from scipy.ndimage import distance_transform_edt as _edt
_al = img[..., 3]; _inner = _al > 0.92
_, (_iy, _ix) = _edt(~_inner, return_indices=True)
_t = np.clip((_al - 0.35) / 0.55, 0, 1)[..., None]
img[..., :3] = img[..., :3] * _t + img[_iy, _ix, :3] * (1 - _t)
img[..., 3] = np.clip((_al - 0.02) / 0.98, 0, 1)
pm = np.concatenate([img[..., :3] * img[..., 3:4], img[..., 3:4]], -1)
H_, W_ = img.shape[:2]

W = 960
T = np.load(os.path.join(HERE, 'tracks.npy'), allow_pickle=True).item()
OPEN = np.load(os.path.join(HERE, 'open.npy'))
N = len(OPEN)

# placement: image -> output (= reference frame coords); body aligned to the reference
S = 0.677600; AX, AY = 550, 870; BX, BY = 468.9600, 633.7600
def img2out(x, y): return BX + (x - AX) * S, BY + (y - AY) * S
def out2img(x, y): return AX + (x - BX) / S, AY + (y - BY) / S

def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)

# ---- motion curves: clean rotations only (tracking noise removed), loopable ----
from scipy.ndimage import median_filter
def clean(x, med=11, sig=4.0):
    x = median_filter(x, med, mode='nearest'); x = gaussian_filter1d(x, sig, mode='nearest')
    x = x - ss(N - 95, N - 1, np.arange(N)) * x[-1]
    return x - (1 - ss(0, 6, np.arange(N))) * x[0]
ROT = {k: np.arctan2(v[:, 1, 0], v[:, 0, 0]) for k, v in T.items()}
b_ = T['body']; BODY_Y = clean(b_[:, 1, 0] * 490 + b_[:, 1, 1] * 700 + b_[:, 1, 2] - 700, 9, 3.0) / S
HEAD = clean(ROT['head'])
LEAR = clean(ROT['lear'] - ROT['head'], 9, 3.0)
REAR = clean(ROT['rear'] - ROT['head'], 9, 3.0)
TAIL = clean(ROT['tail'], 9, 3.5)
# clean synthetic blink curves (no tracking noise), timed like the reference
_f = np.arange(N, dtype=float)
_b1 = np.where(_f < 62, ss(55, 62, _f), 1 - ss(66, 77, _f)) * (_f >= 55) * (_f <= 77)   # short 1st blink
_b2 = np.where(_f < 185, ss(171, 185, _f), 1 - ss(187, 201, _f)) * (_f >= 171) * (_f <= 201)  # 2nd, as in ref
blink_curve = np.maximum(_b1, _b2)

def rot(X, Y, p, ang):
    c, s_ = np.cos(ang), np.sin(ang); dx, dy = X - p[0], Y - p[1]
    return p[0] + c * dx - s_ * dy, p[1] + s_ * dx + c * dy
NECK, LEARB, REARB, TAILB = (575, 700), (385, 310), (835, 395), (830, 1150)

def weights(Xi, Yi):
    body = ss(1260, 960, Yi)
    head = 1 - ss(660, 745, Yi)
    lear = (1 - ss(390, 450, Xi)) * (1 - ss(285, 350, Yi))
    rear = ss(800, 860, Xi) * (1 - ss(430, 500, Yi))
    return body, head, lear, rear

# ---- split into layers: tail (behind) and everything else ----
from PIL import ImageDraw
TOP = [(735, 800), (760, 762), (800, 736), (850, 718), (900, 710), (1000, 700), (1200, 695)]
poly = TOP + [(1210, 1295), (865, 1265), (835, 1205), (838, 1100), (835, 1015), (795, 985), (752, 995), (733, 900)]
p2 = Image.new('L', (W_, H_), 0); ImageDraw.Draw(p2).polygon([(690, 840)] + TOP + [(1210, 1295), (690, 1295)], fill=255)
below_top = np.array(p2) > 0
pim = Image.new('L', (W_, H_), 0); ImageDraw.Draw(pim).polygon(poly, fill=255)
tailm = np.array(pim) > 0
r8 = (img[..., :3] * 255).astype(int)
blue = (r8[..., 2] > r8[..., 0] + 30) & (img[..., 3] > 0.3)
tailm &= ~blue                                          # never take hoodie pixels
from scipy.ndimage import distance_transform_edt
core = tailm & ~cv2.dilate(blue.astype(np.uint8), np.ones((9, 9), np.uint8)).astype(bool) & (img[..., 3] > 0.9)
core = cv2.erode(core.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool) | (tailm & (img[..., 3] <= 0.9))
tailf = cv2.GaussianBlur(tailm.astype(np.float32), (0, 0), 0.7)
body_pm = pm * (1 - tailf[..., None])
# tail layer: everything around the tail that is hidden behind the body is filled with the nearest tail fur
ext = cv2.dilate(tailm.astype(np.uint8), np.ones((121, 121), np.uint8)) > 0
ext &= (img[..., 3] > 0.5) & below_top
fill = (ext | tailm) & ~core
_, (iy, ix) = distance_transform_edt(~core, return_indices=True)
trgb = img[..., :3].copy()
trgb[fill] = img[iy[fill], ix[fill], :3]
trgb = np.where(fill[..., None], cv2.GaussianBlur(trgb, (0, 0), 2.0), trgb)
ta = np.where(fill, np.maximum(img[..., 3], ext.astype(np.float32)), img[..., 3] * tailf)
ta = np.where(tailm | ext, ta, 0).astype(np.float32)
tail_pm = np.concatenate([trgb * ta[..., None], ta[..., None]], -1).astype(np.float32)

yy, xx = np.mgrid[0:W, 0:W].astype(np.float32)

# ---- eyelids ----
EYEM = []
for m in np.load(os.path.join(HERE, 'eyemasks_happy.npy')):
    mm = cv2.dilate(m, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (13, 13)))
    ys, xs = np.nonzero(mm); x0, x1 = xs.min(), xs.max()
    top = np.full(W_, np.nan); bot = np.full(W_, np.nan)
    for x in range(x0, x1 + 1):
        col = np.nonzero(mm[:, x])[0]; top[x], bot[x] = col.min(), col.max()
    cols = np.zeros((W_, 4), np.float32)
    for x in range(x0, x1 + 1):
        band = pm[int(top[x]) - 30:int(top[x]) - 6, x]
        lum = band[:, :3].sum(1); keep = band[lum > np.percentile(lum, 40)]
        cols[x] = np.median(keep, 0)
    cols[:x0] = cols[x0]; cols[x1 + 1:] = cols[x1]
    cols = cv2.GaussianBlur(cols[None], (0, 0), sigmaX=16)[0]
    tex = np.repeat(cols[None], H_, 0)
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
    gy, gx = np.mgrid[0:H_, 0:W_].astype(np.float32)
    rr = ((gx - ecx) / rx) ** 2 + ((gy - ecy) / ry) ** 2
    hl = np.exp(-(((gx - ecx) / (0.45 * rx)) ** 2 + ((gy - (ecy - 0.35 * ry)) / (0.35 * ry)) ** 2))
    shade_ = np.clip(1.0 - 0.16 * rr + 0.06 * hl, 0.75, 1.08)
    tex[..., :3] *= shade_[..., None]
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
    lid = _inp.copy()
    _px0, _py0, _px1, _py1 = (525, 320, 595, 400)                                   # plain fur between the eyes
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
    _new.append((cv2.GaussianBlur((mm_ > 0.05).astype(np.float32), (0, 0), 3.5), x0_, x1_, top_, bot_, tex2))
EYEM = _new
YS = np.arange(H_, dtype=np.float32)[:, None]

def paint_lids(pm_, blink):
    out = pm_.copy()
    blink = min(1.0, blink * 1.15)
    for (mm, x0, x1, top, bot, tex) in EYEM:
        sl = slice(x0 - 4, x1 + 5)
        tp, bt = top[sl], bot[sl]
        tp = np.where(np.isnan(tp), np.nanmean(top), tp); bt = np.where(np.isnan(bt), tp, bt)
        yL = tp + 2 + blink * (bt - tp + 2)          # fully closed at blink = 1
        yLash = yL - 6 * blink
        m = mm[:, sl]
        lidm = np.clip((yL[None, :] - YS) / 2.0 + 0.5, 0, 1) * m
        shade = 1 - 0.10 * np.clip(1 - (yL[None, :] - YS) / 25.0, 0, 1)
        Tt = tex[:, sl] * np.concatenate([np.repeat(shade[..., None], 3, -1), np.ones_like(shade[..., None])], -1)
        o = out[:, sl]
        o[:] = o * (1 - lidm[..., None]) + Tt * lidm[..., None]
        w = tp.shape[0]; uu = np.linspace(-1, 1, w)
        thick = (2.0 + 3.5 * blink) * np.clip(1 - uu ** 4, 0, 1)
        d = np.abs(YS - yLash[None, :]) - thick[None, :]
        lash = np.clip(0.5 - d / 1.5, 0, 1) * min(1, blink * 6) * (np.abs(uu) < 0.97)[None, :]
        dark = np.array([0.16, 0.09, 0.06, 1.0], np.float32) * np.maximum(o[..., 3:4], 1e-3)
        dark[..., 3] = o[..., 3]
        o[:] = o * (1 - lash[..., None]) + dark * lash[..., None]
    return out

def lerp(P, Q, w): return P[0] + (Q[0] - P[0]) * w, P[1] + (Q[1] - P[1]) * w

def frame(i):
    Xq, Yq = out2img(xx, yy)
    wb = weights(Xq, Yq)[0]
    P = (Xq, Yq + BODY_Y[i] * wb)                       # breathing (paws stay planted)
    wh = weights(*P)[1]
    P = lerp(P, rot(*P, NECK, -HEAD[i]), wh)            # head
    _, _, wl, wr = weights(*P)
    P = lerp(P, rot(*P, LEARB, -LEAR[i]), wl)           # ears, relative to head
    P = lerp(P, rot(*P, REARB, -REAR[i]), wr)
    b = float(blink_curve[i])
    src = paint_lids(body_pm, b) if b > 0 else body_pm
    B = cv2.remap(src, P[0].astype(np.float32), P[1].astype(np.float32), cv2.INTER_CUBIC,
                  borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
    Pt = rot(Xq, Yq, TAILB, -TAIL[i])                   # tail: rigid swing about its base
    Tl = cv2.remap(tail_pm, Pt[0].astype(np.float32), Pt[1].astype(np.float32), cv2.INTER_CUBIC,
                   borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
    B = np.clip(B, 0, 1); Tl = np.clip(Tl, 0, 1)
    out = B + Tl * (1 - B[..., 3:4])
    al = out[..., 3:4]
    rgb = np.where(al > 1e-4, out[..., :3] / np.maximum(al, 1e-4), 0)
    return (np.concatenate([np.clip(rgb, 0, 1), np.clip(al, 0, 1)], -1) * 255 + 0.5).astype(np.uint8)

idx = [int(x) for x in os.environ['ONLY'].split(',')] if os.environ.get('ONLY') else range(N)
for i in idx:
    Image.fromarray(frame(i)).save(f'{OUT}/f{i:04d}.png')
print('done')
