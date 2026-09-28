"""FEED_HAPPY: HAPPY_IDLE anchor -> bowl pops in, fox leans down and takes a few bites, satisfied smile,
tail swish -> bowl pops out -> exact HAPPY_IDLE anchor. Reuses the happy rig + eyes from anim_pet7."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
_s = open(os.path.join(HERE, 'anim_pet7.py')).read().replace("os.path.dirname(os.path.abspath(__file__))", repr(HERE))
exec(_s[:_s.index('def frame(i):')])

N = 306; f = np.arange(N, dtype=float); D = np.deg2rad
def bump(a, b, r): return ss(a, a + r, f) * (1 - ss(b - r, b, f))

# ---- timeline ----
LEAN = ss(26, 62, f) * (1 - ss(206, 238, f))                  # lean down to the bowl
BITES = (66, 114, 162)
BITE = sum(ss(t, t + 8, f) * (1 - ss(t + 10, t + 18, f)) for t in BITES)          # dip into the food
CHEW_ENV = sum(ss(t + 14, t + 20, f) * (1 - ss(t + 40, t + 46, f)) for t in BITES)  # lift a little and chew
CHEW_PH = sum(np.clip((f - (t + 16)) / 12.0, 0, 2.5) for t in BITES)             # ~2.5 chews per bite
FOOD = 0.3 * ss(BITES[0] + 6, BITES[0] + 14, f)             # only the first bite takes a piece       # food level goes down with each bite
SAT = ss(236, 252, f) * (1 - ss(270, 286, f))                # satisfied: eyes close into happy arcs
CLOSE = SAT
BEND = ss(243, 254, f) * (1 - ss(264, 276, f))
EARS = SAT
TAIL = (D(-2.0) + D(7.0) * np.sin(2 * np.pi * (f - 240) / 44)) * ss(238, 250, f) * (1 - ss(272, 286, f))
BODY_DOWN = 130.0; HEAD_DOWN = 60.0; BITE_DOWN = 24.0; CHEW_LIFT = 34.0

def bowl_scale(i):
    a = ss(0, 12, i) * 1.07 - 0.07 * ss(12, 22, i)            # pop in with a tiny overshoot
    return float(a * (1 - ss(288, 304, i)))                   # pop out

# ---- bowl sprite ----
_b = np.array(Image.open(os.path.join(HERE, 'food_bowl.png')).convert('RGBA')).astype(np.float32) / 255
_b = _b[222:1012, 80:1172]
BOWL_PM = np.concatenate([_b[..., :3] * _b[..., 3:4], _b[..., 3:4]], -1)
BW = 400.0; BSC = BW / BOWL_PM.shape[1]
BCX, BBOT = 477.8, float(os.environ.get('BBOT', 850.0))   # = L1 (472, 958) through the L2 placement                                     # bowl centre x and bottom (output px)

# split the bowl into: empty bowl (food painted out), food pile, and the front wall that hides sunk food
_bh, _bw = _b.shape[:2]
_gyb, _gxb = np.mgrid[0:_bh, 0:_bw].astype(np.float32)
ECX, ECY, ERX, ERY = 549.0, 262.0, 412.0, 128.0      # inner rim ellipse
OCX, OCY, ORX, ORY = 549.0, 262.0, 454.0, 165.0      # outer rim ellipse (matches the bowl silhouette)                # inner rim ellipse (in the cropped bowl sprite)
_hsvb = cv2.cvtColor((np.clip(_b[..., :3], 0, 1) * 255).astype(np.uint8), cv2.COLOR_RGB2HSV).astype(np.float32)
_food = ((_hsvb[..., 1] > 55) & (_hsvb[..., 0] < 30) & (_b[..., 3] > 0.3) & (_gyb < 400)).astype(np.uint8)
_food = cv2.morphologyEx(_food, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))
_n, _lab, _st, _ = cv2.connectedComponentsWithStats(_food)
_food = (_lab == 1 + np.argmax(_st[1:, 4])).astype(np.uint8)
_cs, _ = cv2.findContours(_food, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
_food = np.zeros_like(_food); cv2.drawContours(_food, _cs, -1, 1, -1)
_foodf = cv2.GaussianBlur(_food.astype(np.float32), (0, 0), 1.0)
# empty bowl: rebuilt rim top + inner surface where the food used to be
_rin = ((_gxb - ECX) / ERX) ** 2 + ((_gyb - ECY) / ERY) ** 2
_rout = ((_gxb - OCX) / ORX) ** 2 + ((_gyb - OCY) / ORY) ** 2
_foodreg = cv2.dilate(_food, np.ones((9, 9), np.uint8)).astype(bool)
_inner = _rin < 1
_outer = _rout < 1
_rep = (_foodreg | (_gyb < OCY)) & _outer & ~((~_foodreg) & (_gyb >= OCY))
_v = np.clip((_gyb - (ECY - ERY)) / (2 * ERY), 0, 1)                       # 0 back wall .. 1 front
_inner_col = np.array([0.93, 0.93, 0.95], np.float32)[None, None] * (0.98 - 0.16 * _v - 0.06 * np.clip(_rin, 0, 1))[..., None]
_inner_col = _inner_col * (1 - 0.10 * np.clip(1 - (ECY + ERY * np.sqrt(np.clip(1 - ((_gxb - ECX) / ERX) ** 2, 0, 1)) - _gyb) / 25, 0, 1))[..., None]  # shadow under the front lip
_rim_col = np.array([0.975, 0.975, 0.985], np.float32)[None, None] * (1 - 0.05 * np.clip((_gyb - OCY) / ORY + 1, 0, 1))[..., None]
_col = np.where(_inner[..., None], _inner_col, _rim_col)
_col = cv2.GaussianBlur(_col, (0, 0), 1.2)
_vfade = 1 - ss(OCY - 10, OCY + 70, _gyb)                          # hand over to the real bowl sides smoothly
_repw = np.maximum(_foodreg.astype(np.float32), _vfade) * _outer
_repf = cv2.GaussianBlur(_repw.astype(np.float32), (0, 0), 2.0)[..., None]
_empty = _b[..., :3] * (1 - _repf) + _col * _repf
_ea = np.where(_rep, 1.0, np.where(_foodreg & ~_outer, 0.0, _b[..., 3])).astype(np.float32)
_ea = np.where(_outer | ~_foodreg, _ea, 0.0)
_oa = cv2.GaussianBlur(_outer.astype(np.float32), (0, 0), 1.0)
_ea = np.where(_rep, _oa, _ea).astype(np.float32)
_ea = np.where((_gyb < OCY) & ~_outer, 0.0, _ea).astype(np.float32)        # nothing of the bowl above its rim
EMPTY_PM = np.concatenate([_empty * _ea[..., None], _ea[..., None]], -1)
FOOD_PM = BOWL_PM * _foodf[..., None]
_ufront = np.clip((_gxb - ECX) / ERX, -1, 1)
FRONT_Y = ECY + ERY * np.sqrt(1 - _ufront ** 2)                 # front rim line; sunk food is hidden below it
INSIDE_X = (np.abs(_gxb - ECX) < ERX - 6).astype(np.float32)

def bowl_sprite(level):
    if level <= 0: return BOWL_PM
    dy = 230.0 * level
    fd = cv2.warpAffine(FOOD_PM, np.float32([[1, 0, 0], [0, 1, dy]]), (_bw, _bh), flags=cv2.INTER_LINEAR, borderValue=(0, 0, 0, 0))
    vis = np.clip((FRONT_Y - 4 - _gyb) / 4.0, 0, 1) * INSIDE_X
    fd = fd * vis[..., None]
    return fd + EMPTY_PM * (1 - fd[..., 3:4])

ITEM = os.environ.get('ITEM', 'treats')
_CFG = {'bowl': dict(file='food_treats.png', crop=(110, 195, 1222, 1062), width=400, cuts=[195, 430, 640, 850], inside=(1, 1, 1)),
        'treats':  dict(file='food_treats.png',  crop=(110, 195, 1222, 1062), width=400, cuts=[195, 430, 640, 850],
                        inside=(0.98, 0.93, 0.78)),
        'cupcake': dict(file='food_cupcake.png', crop=(160, 20, 1104, 1234), width=240, cuts=[20, 350, 560, 760],
                        inside=(0.93, 0.78, 0.52))}[ITEM]
_it = np.array(Image.open(os.path.join(HERE, _CFG['file'])).convert('RGBA')).astype(np.float32) / 255
x0_, y0_, x1_, y1_ = _CFG['crop']; _it = _it[y0_:y1_, x0_:x1_]
_a = _it[..., 3]; _in = _a > 0.92
from scipy.ndimage import distance_transform_edt as _edt2
_, (_iy2, _ix2) = _edt2(~_in, return_indices=True)
_t2 = np.clip((_a - 0.35) / 0.55, 0, 1)[..., None]
_it[..., :3] = _it[..., :3] * _t2 + _it[_iy2, _ix2, :3] * (1 - _t2)       # clean dark fringe on the cut-out edge
ITEM_RGB = _it[..., :3]; ITEM_A = _it[..., 3]
IH, IW = ITEM_A.shape
_gyi, _gxi = np.mgrid[0:IH, 0:IW].astype(np.float32)
CUTS = [c - y0_ for c in _CFG['cuts']]
INSIDE = np.array(_CFG['inside'], np.float32)
BITE_P = 95.0 if ITEM == 'treats' else 70.0

def item_sprite(level):
    """level 0..0.9 (3 bites of 0.3): the top gets eaten away with bite-shaped scallops"""
    q = np.clip(level / 0.3, 0, 3)
    k = int(min(np.floor(q), 2)); fr = q - k
    base = CUTS[k] + (CUTS[k + 1] - CUTS[k]) * fr
    if q <= 0: return np.concatenate([ITEM_RGB * ITEM_A[..., None], ITEM_A[..., None]], -1)
    u = ((_gxi + 13 * k) % BITE_P) / BITE_P * 2 - 1
    edge = base + 0.30 * BITE_P * np.sqrt(np.clip(1 - u ** 2, 0, 1))     # round bite marks hanging down
    keep = np.clip((_gyi - edge) / 1.5 + 0.5, 0, 1)
    rim = np.clip(1 - (_gyi - edge) / 12.0, 0, 1) * keep                    # bitten surface shows the inside
    rgb = ITEM_RGB * (1 - 0.75 * rim[..., None]) + INSIDE * 0.75 * rim[..., None]
    rgb = rgb * (1 - 0.18 * np.clip(1 - np.abs(_gyi - edge - 12) / 5, 0, 1))[..., None]
    a = ITEM_A * keep
    return np.concatenate([rgb * a[..., None], a[..., None]], -1)

ISC = 0.88 * _CFG['width'] / IW                                   # same size relative to the fox as in L1
def draw_bowl(canvas, i):
    k = bowl_scale(i)
    if k <= 0.01: return canvas
    s = ISC * k
    M = np.float32([[s, 0, BCX - s * IW / 2], [0, s, BBOT - s * IH]])   # scales from the bottom centre
    lay = np.clip(cv2.warpAffine(item_sprite(float(FOOD[i])), M, (W, W), flags=cv2.INTER_AREA, borderValue=(0, 0, 0, 0)), 0, 1) * min(1.0, k * 3)
    sh = np.zeros((W, W), np.float32)
    rx = int(0.45 * _CFG['width'] * k)
    cv2.ellipse(sh, (int(BCX), int(BBOT - 6)), (rx, int(14 * k)), 0, 0, 360, 1.0, -1)
    sh = cv2.GaussianBlur(sh, (0, 0), 8) * 0.18 * min(1.0, k * 3)
    canvas = np.concatenate([canvas[..., :3] * (1 - sh[..., None]), canvas[..., 3:4]], -1)
    return lay + canvas * (1 - lay[..., 3:4])

if ITEM == 'bowl':                                          # the original bowl (food sinks with every bite)
    FOOD[:] = sum(0.3 * ss(t + 6, t + 14, f) for t in BITES)
    def draw_bowl(canvas, i):
        k = bowl_scale(i)
        if k <= 0.01: return canvas
        s = BSC * k
        h, w = BOWL_PM.shape[:2]
        M = np.float32([[s, 0, BCX - s * w / 2], [0, s, BBOT - s * h]])
        lay = np.clip(cv2.warpAffine(bowl_sprite(float(FOOD[i])), M, (W, W), flags=cv2.INTER_AREA, borderValue=(0, 0, 0, 0)), 0, 1) * min(1.0, k * 3)
        sh = np.zeros((W, W), np.float32)
        cv2.ellipse(sh, (int(BCX), int(BBOT - 6)), (int(190 * k), int(14 * k)), 0, 0, 360, 1.0, -1)
        sh = cv2.GaussianBlur(sh, (0, 0), 8) * 0.18 * min(1.0, k * 3)
        canvas = np.concatenate([canvas[..., :3] * (1 - sh[..., None]), canvas[..., 3:4]], -1)
        return lay + canvas * (1 - lay[..., 3:4])

# head as its own layer so it can dip in front of the hoodie
_gy, _gx = np.mgrid[0:H_, 0:W_].astype(np.float32)
_r8 = img[..., :3]
_hood = (_r8[..., 2] > _r8[..., 0] + 0.08) & (img[..., 3] > 0.3)
_hood = (cv2.morphologyEx(_hood.astype(np.uint8), cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (45, 45))) > 0) & (img[..., 3] > 0.3)  # drawstrings belong to the hoodie
_hm = (1 - ss(740, 770, _gy)) * (1 - cv2.GaussianBlur(cv2.dilate(_hood.astype(np.uint8), np.ones((5, 5), np.uint8)).astype(np.float32), (0, 0), 2))
_hb = _hood & (_gy > 500)
_top = np.where(_hb.any(0), np.argmax(_hb, 0), 10000).astype(np.float32)
from scipy.ndimage import minimum_filter1d
_xs = np.arange(W_, dtype=np.float32)
_cut = np.minimum(_top, 728.0 - 70.0 * np.clip((_xs - 562) / 175.0, -1.5, 1.5) ** 2)   # rounded chin                           # head = face down to the chin; chest V fur stays on the static body
_hm = _hm * (1 - ss(_cut[None, :] - 16, _cut[None, :] + 2, _gy))
_hm = cv2.GaussianBlur(_hm.astype(np.float32), (0, 0), 1.2)[..., None]
HEAD_PM = body_pm * _hm
_hd8 = cv2.dilate(_hood.astype(np.uint8), np.ones((11, 11), np.uint8)).astype(np.float32)
UNDER_PM = body_pm * (1 - cv2.GaussianBlur(_hd8, (0, 0), 1.5))[..., None]
BODYNH_PM = body_pm * (1 - _hm)
LOWFUR_PM = body_pm * (1 - cv2.GaussianBlur(_hd8, (0, 0), 3.0))[..., None] * (ss(860, 940, _gy) * (1 - ss(1120, 1160, _gy)) * np.maximum(1 - ss(420, 450, _gx), ss(640, 670, _gx)))[..., None]   # static haunch fur only (no legs/paws)
_hsoft = cv2.GaussianBlur(cv2.dilate(_hood.astype(np.uint8), np.ones((5, 5), np.uint8)).astype(np.float32), (0, 0), 1.2)
_upm = np.maximum(_hsoft, 1 - ss(905.0, 945.0, _gy))                        # hoodie (incl. sleeves) + everything above the lap
UPPER_PM = body_pm * ((1 - _hm[..., 0]) * _upm)[..., None]
_rgbL = (np.clip(img[..., :3], 0, 1) * 255).astype(np.uint8)
_holeL = cv2.dilate(_hood.astype(np.uint8), np.ones((9, 9), np.uint8)) * (_gy > 860)
_inL = cv2.inpaint(_rgbL, (_holeL * 255).astype(np.uint8), 12, cv2.INPAINT_TELEA).astype(np.float32) / 255   # fur that the sleeves hid
_aL = body_pm[..., 3] * ss(860.0, 900.0, _gy)
LOWER_PM = np.concatenate([_inL * _aL[..., None], _aL[..., None]], -1).astype(np.float32)
NECK_PM = HEAD_PM * ss(500, 560, _gy)[..., None]

def frame(i):
    L, Bt = float(LEAN[i]), float(BITE[i])
    rm = lambda im, P: np.clip(cv2.remap(im, P[0].astype(np.float32), P[1].astype(np.float32), cv2.INTER_CUBIC,
                                          borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0)), 0, 1)
    Xq, Yq = out2img(xx, yy)
    wb = weights(Xq, Yq)[0]
    down_b = BODY_DOWN * L
    wramp = ss(1165.0, 960.0, Yq)                                # all paws (y >= 1165) stay exactly put; only the forelegs shorten
    Pb = (Xq, Yq - down_b * wramp)
    if L == 0 and Bt == 0:
        # exactly the idle pipeline (anchors, and the satisfied part) + ears/eyes
        P = Pb
        _, _, wl, wr = weights(*P)
        P = lerp(P, rot(*P, LEARB, D(6.0) * EARS[i]), wl)
        P = lerp(P, rot(*P, REARB, -D(6.0) * EARS[i]), wr)
        c_, bd = float(CLOSE[i]), float(BEND[i])
        src = paint_eyes(body_pm, c_, bd) if c_ > 0 else body_pm
        B = rm(src, P)
    else:
        up = rm(UPPER_PM, (Xq, Yq - down_b))                     # upper body leans down as one rigid piece
        body = up + rm(LOWER_PM, (Xq, Yq)) * (1 - up[..., 3:4])   # legs, haunches and paws never move
        # head: whole-layer move down (+ body's own move), a touch bigger (closer to camera), tiny nod per bite
        ce = float(CHEW_ENV[i])
        dy = HEAD_DOWN * L + BITE_DOWN * Bt + down_b - CHEW_LIFT * ce
        sc = 1 + 0.03 * L
        Hx = NECK[0] + (Xq - NECK[0]) / sc
        Hy = NECK[1] + ((Yq - dy) - NECK[1]) / sc
        Ph = rot(Hx, Hy, NECK, -D(1.5) * Bt)
        if ce > 0:                                              # chewing: jaw closes/opens, cheeks puff
            J = ce * (0.55 + 0.45 * np.sin(2 * np.pi * float(CHEW_PH[i]) - np.pi / 2) * -1)
            X_, Y_ = Ph
            wx = 1 - ss(0.62, 1.0, np.abs(X_ - 560) / 125)
            wy = ss(582, 606, Y_) * (1 - ss(690, 770, Y_))    # whole lower jaw moves as one piece
            Y_ = Y_ + 56 * J * wx * wy
            for cx_, cy_ in ((465, 600), (655, 600)):
                d_ = np.hypot(X_ - cx_, Y_ - cy_); g_ = 1 - ss(20, 85, d_)
                k_ = 1 / (1 + 0.15 * J * g_)
                X_ = cx_ + (X_ - cx_) * k_; Y_ = cy_ + (Y_ - cy_) * k_
            Ph = (X_, Y_)
        _, _, wl, wr = weights(*Ph)
        Ph = lerp(Ph, rot(*Ph, LEARB, D(6.0) * EARS[i] + D(3.0) * L), wl)
        Ph = lerp(Ph, rot(*Ph, REARB, -D(6.0) * EARS[i] - D(3.0) * L), wr)
        c_, bd = float(CLOSE[i]), float(BEND[i])
        hsrc = paint_eyes(HEAD_PM, c_, bd) if c_ > 0 else HEAD_PM
        head = rm(hsrc, Ph)
        # fade between the layered pose and the exact idle render near the ends of the lean
        # neck fill: the whole fox moved with the head, laid underneath, so no gap opens below the chin
        under = rm(NECK_PM, (Hx, Hy))                              # neck fur behind the chewing jaw (no hoodie, no ears)
        B = body + under * (1 - body[..., 3:4])
        B = head + B * (1 - head[..., 3:4])
    Pt = rot(Xq, Yq, TAILB, -TAIL[i])
    Tl = rm(tail_pm, Pt)
    out = B + Tl * (1 - B[..., 3:4])
    out = draw_bowl(out, i)
    al = out[..., 3:4]
    rgb = np.where(al > 1e-4, out[..., :3] / np.maximum(al, 1e-4), 0)
    return (np.concatenate([np.clip(rgb, 0, 1), np.clip(al, 0, 1)], -1) * 255 + 0.5).astype(np.uint8)

OUT = sys.argv[1] if len(sys.argv) > 1 else 'frames_feed_'+ITEM
os.makedirs(OUT, exist_ok=True)
idx = [int(x) for x in os.environ['ONLY'].split(',')] if os.environ.get('ONLY') else range(N)
for i in idx:
    Image.fromarray(frame(i)).save(f'{OUT}/f{i:04d}.png')
print('done')
