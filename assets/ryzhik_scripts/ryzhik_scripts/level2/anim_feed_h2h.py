"""FEED_HUNGRY_TO_HAPPY: the HUNGRY fox eats (bowl, lean, bites, chewing, food goes down), raises his head and
closes his eyes contentedly -> (morph hungry -> happy while eyes are closed) -> happy tail swish, opens eyes ->
exact HAPPY_IDLE anchor. First frame = HUNGRY_IDLE anchor, last frame = HAPPY_IDLE anchor."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else 'frames_h2h'
sys.argv = [sys.argv[0], '/tmp/_unused_out']

def load(fn, cut):
    s = open(os.path.join(HERE, fn)).read().replace("os.path.dirname(os.path.abspath(__file__))", repr(HERE))
    g = {'__name__': 'x', '__file__': os.path.join(HERE, fn)}
    exec(s[:s.index(cut)], g)
    return g

HN = load('anim_pethungry.py', 'os.makedirs(OUT, exist_ok=True)')
os.environ.setdefault('ITEM', 'treats')
PN = load('anim_feed_items_for_h2h.py', "OUT = sys.argv[1]")
cv2, Image, ss = PN['cv2'], PN['Image'], PN['ss']
D = np.deg2rad

J_SWAP = 256; T_M = 24
NPV = PN['N']; NT = J_SWAP + T_M + (NPV - J_SWAP)
jf = np.arange(NPV, dtype=float)

# ---------------- hungry feeding rig (hungry source coords) ----------------
pm = HN['pm']; X0 = HN['X0']; Y0 = HN['Y0']; img = HN['img']; S_H = HN['S']
H_, W_ = img.shape[:2]
gy, gx = np.mgrid[0:H_, 0:W_].astype(np.float32)
hood = (img[..., 2] > img[..., 0] + 0.08) & (img[..., 3] > 0.3)
hm = (1 - ss(720, 760, gy)) * (1 - cv2.GaussianBlur(cv2.dilate(hood.astype(np.uint8), np.ones((13, 13), np.uint8)).astype(np.float32), (0, 0), 1.5))
_hb = hood.copy(); _hb[:600] = False
_top = np.full(W_, 10 ** 6, np.float32)
for _x in range(W_):
    _c = np.nonzero(_hb[:, _x])[0]
    if len(_c): _top[_x] = _c.min()
_top = np.minimum.accumulate(np.minimum(_top, 10 ** 6))  if False else _top
# columns inside the V-neck: the hood outline is the silhouette of the collar; fill V with the lower envelope
from scipy.ndimage import grey_closing
_top = grey_closing(np.where(_top > 5000, 5000, _top), size=1)
hm = hm * ss(_top[None, :] - 6, _top[None, :] - 22, gy) + hm * (_top[None, :] > 4000)   # head never covers the collar
hm = np.clip(hm, 0, 1)
from PIL import ImageDraw as _ID
_tpi = Image.new('L', (W_, H_), 0)
_ID.Draw(_tpi).polygon([(752, 740), (790, 672), (840, 652), (912, 630), (960, 605), (1254, 560), (1254, 1300), (752, 1300)], fill=255)
TAILSRC = cv2.GaussianBlur(((np.array(_tpi) > 0) & ~hood).astype(np.float32), (0, 0), 2.0)
hm = hm * (1 - TAILSRC)                                        # the whole tail is never part of the head
hm = cv2.GaussianBlur(hm.astype(np.float32), (0, 0), 1.2)[..., None]
HEAD_PM = pm * hm; BODY_PM = pm * (1 - hm) / np.maximum(1 - pm[..., 3:4] * hm, 1e-3)   # 'over' is exact at rest
_hd8 = cv2.dilate(hood.astype(np.uint8), np.ones((9, 9), np.uint8)).astype(np.float32)
UNDER_PM = pm * (1 - cv2.GaussianBlur(_hd8, (0, 0), 1.5))[..., None]      # neck fill = fur only, never a 2nd hoodie
_fa = (img[..., 3] > 0.5).astype(np.uint8); _fa[780:] = 1
EDGE_D = cv2.distanceTransform(_fa, cv2.DIST_L2, 5).astype(np.float32)
NECK_H = (560.0, 700.0)
TAILW = np.maximum(np.clip(HN['tail_w'] * 1.6, 0, 1), cv2.remap(TAILSRC, X0.astype(np.float32), Y0.astype(np.float32), cv2.INTER_LINEAR)).astype(np.float32)
NECKZONE = ((1 - TAILW) * (ss(280, 340, X0) * (1 - ss(780, 840, X0)) * ss(480, 560, Y0) * (1 - ss(900, 960, Y0)))).astype(np.float32)[..., None]
def mouth_y(X):
    # the frown line of the hungry mouth (source coords): up from the left corner to the middle, down to the right
    return np.where(X < 565, 560 - 9 * np.clip((X - 523) / 42, 0, 1), 551 + 26 * np.clip((X - 565) / 38, 0, 1) ** 1.2)
def rotp(X, Y, p, a): return HN['rot'](X, Y, p[0], p[1], a)
def lear_w(X, Y): return (1 - ss(300, 360, X)) * (1 - ss(420, 480, Y))
def rear_w(X, Y): return ss(880, 960, X) * (1 - ss(440, 520, Y)) * ss(300, 340, Y)
def lerp(P, Q, w): return P[0] + (Q[0] - P[0]) * w, P[1] + (Q[1] - P[1]) * w
def rm(im, P):
    return np.clip(cv2.remap(im, P[0].astype(np.float32), P[1].astype(np.float32), cv2.INTER_CUBIC,
                             borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0)), 0, 1)

# timeline (same beats as FEED_HAPPY v4, index j)
PERK = ss(14, 34, jf)                                   # notices the food: ears and head lift a little
LEAN = PN['LEAN']; BITE = PN['BITE']; CHEW_ENV = PN['CHEW_ENV']; CHEW_PH = PN['CHEW_PH']
H_CLOSE = ss(218, 232, jf); H_BEND = ss(224, 236, jf)    # content, eyes close after eating
BODY_DOWN, HEAD_DOWN, BITE_DOWN, CHEW_LIFT = 156.0, 72.0, 24.0, 34.0

def hungry_fox(j):
    L, Bt, ce = float(LEAN[j]), float(BITE[j]), float(CHEW_ENV[j])
    wb = ss(1110, 700, Y0) * (1 - TAILW)                  # the tail stays where it is
    down_b = BODY_DOWN * L
    Pb = (X0, Y0 - down_b * wb - 3.0 * PERK[j] * wb)
    body = rm(BODY_PM, Pb)
    dy = HEAD_DOWN * L + BITE_DOWN * Bt + down_b - CHEW_LIFT * ce - 3.0 * PERK[j]
    sc = 1 + 0.03 * L
    Hx = NECK_H[0] + (X0 - NECK_H[0]) / sc
    Hy = NECK_H[1] + ((Y0 - dy) - NECK_H[1]) / sc
    Ph = rotp(Hx, Hy, NECK_H, -D(1.5) * Bt)
    ang_l = D(9.0) * PERK[j]; ang_r = -D(9.0) * PERK[j]
    Ph = lerp(Ph, rotp(*Ph, (345, 340), -ang_l), lear_w(*Ph))
    Ph = lerp(Ph, rotp(*Ph, (895, 395), -ang_r), rear_w(*Ph))
    Ph0 = Ph
    MOUTH = None
    if ce > 0:                                            # chewing: lower jaw drops, the mouth opens and closes
        Jw = ce * (0.55 - 0.45 * np.sin(2 * np.pi * float(CHEW_PH[j]) - np.pi / 2))
        X_, Y_ = Ph
        ym = mouth_y(X_)
        env = np.clip(1 - ((X_ - 563) / 42) ** 2, 0, 1) ** 0.5          # opening shape across the mouth
        op = 36.0 * Jw * env
        wx = ss(4, 60, cv2.remap(EDGE_D, X_.astype(np.float32), Y_.astype(np.float32), cv2.INTER_LINEAR))
        below = Y_ > ym
        fall = (1 - ss(ym + 30, ym + 170, Y_)) * wx
        drop = 36.0 * Jw * np.clip(np.maximum(env, 0.55 * (1 - ss(40, 110, np.abs(X_ - 563)))), 0, 1) * fall
        inside = below & (Y_ < ym + op)
        v = np.clip((Y_ - ym) / np.maximum(op, 1e-3), 0, 1)
        Y_ = np.where(below & ~inside, Y_ - drop, Y_)
        MOUTH = (inside.astype(np.float32) * np.clip(op / 3.0, 0, 1), v)
        for cx_, cy_ in ((478, 565), (660, 585)):
            d_ = np.hypot(X_ - cx_, Y_ - cy_); g_ = 1 - ss(20, 85, d_)
            k_ = 1 / (1 + 0.10 * Jw * g_)
            X_ = cx_ + (X_ - cx_) * k_; Y_ = cy_ + (Y_ - cy_) * k_
        Ph = (X_, Y_)
    c_, bd = float(H_CLOSE[j]), float(H_BEND[j])
    hsrc = HN['paint_eyes'](HEAD_PM, c_, bd) if c_ > 0 else HEAD_PM
    head = rm(hsrc, Ph)
    if MOUTH is not None:
        mk, v = MOUTH
        mk = cv2.GaussianBlur(mk, (0, 0), 0.8)[..., None]
        v = v[..., None]
        col = np.array([0.30, 0.09, 0.08], np.float32) * (1 - v) + np.array([0.78, 0.36, 0.40], np.float32) * ss(0.45, 1.0, v)
        col = col * (1 - 0.35 * np.clip(1 - v / 0.25, 0, 1))
        m_ = mk * head[..., 3:4]
        head = np.concatenate([head[..., :3] * (1 - m_) + col * m_, head[..., 3:4]], -1)
    if ce > 0:
        h0 = rm(hsrc, Ph0); head = head + h0 * (1 - head[..., 3:4])
    under = rm(UNDER_PM, (Hx, Hy)) * NECKZONE                   # neck fill: no gap below the chin
    hb = head + body * (1 - head[..., 3:4])
    return hb + under * (1 - hb[..., 3:4])

def bowl_on(pm_, k, food):
    old = PN['bowl_scale']; PN['bowl_scale'] = (lambda i, k=k: k)
    PN['FOOD'][0] = food
    o = PN['draw_bowl'](pm_, 0)
    PN['bowl_scale'] = old
    return o
FOOD = PN['FOOD'].copy()
def bowl_k(j): return float(ss(0, 12, j) * 1.07 - 0.07 * ss(12, 22, j))

def to_u8(out):
    al = out[..., 3:4]
    rgb = np.where(al > 1e-4, out[..., :3] / np.maximum(al, 1e-4), 0)
    return (np.concatenate([np.clip(rgb, 0, 1), np.clip(al, 0, 1)], -1) * 255 + 0.5).astype(np.uint8)

# ---------------- morph hungry (content, eyes closed) -> happy ----------------
LM = [((205, 290), (300, 88)), ((330, 210), (385, 190)), ((265, 330), (263, 175)), ((790, 400), (765, 178)), ((645, 235), (640, 228)), ((735, 400), (750, 270)), ((529, 135), (554, 181)), ((430, 324), (411, 358)), ((591, 364), (567, 386)), ((498, 408), (481, 420)), ((491, 451), (472, 462)), ((497, 496), (470, 517)), ((283, 384), (259, 378)), ((719, 444), (700, 462)), ((483, 567), (469, 581)), ((447, 627), (435, 652)), ((478, 617), (470, 640)), ((357, 818), (321, 852)), ((432, 829), (420, 856)), ((527, 829), (510, 856)), ((612, 810), (615, 848)), ((514, 630), (502, 651)), ((479, 692), (468, 718)), ((846, 543), (860, 574)), ((823, 758), (852, 795)), ((497, 207), (511, 247)), ((265, 240), (345, 125)), ((255, 295), (315, 175)), ((715, 300), (705, 192)), ((720, 350), (718, 250)), ((348, 493), (343, 519)), ((338, 521), (337, 546)), ((618, 522), (589, 544)), ((338, 549), (331, 572)), ((620, 550), (597, 571)), ((351, 577), (349, 599)), ((609, 578), (586, 598)), ((346, 604), (343, 626)), ((612, 604), (588, 625)), ((342, 632), (340, 652)), ((619, 632), (593, 652)), ((328, 661), (336, 680)), ((629, 660), (601, 679)), ((348, 688), (335, 706)), ((615, 688), (600, 705)), ((360, 719), (343, 744)), ((602, 719), (580, 742)), ((382, 469), (374, 496)), ((320, 345), (270, 265)), ((680, 395), (730, 330))]
from morphlib import Morph
PH = np.array([a for a, b in LM], float); PP = np.array([b for a, b in LM], float)
_hd = list(range(14)) + [25, 26, 27, 28, 29]
PH[_hd, 1] -= 3.0 * S_H
MORPH = Morph(PH, PP)

J0, J1 = 236, 288                                          # hungry -> happy after the last bite, eyes closed
NT = PN['N']
_jj = np.arange(NT, dtype=float)
_win = ss(210, 224, _jj) * (1 - ss(284, 298, _jj))
PN['CLOSE'][:] = np.maximum(PN['CLOSE'], _win); PN['BEND'][:] = np.maximum(PN['BEND'], _win)
def happy_fox(j):
    old = PN['bowl_scale']; PN['bowl_scale'] = lambda i: 0.0
    u = PN['frame'](j).astype(np.float32) / 255
    PN['bowl_scale'] = old
    return np.concatenate([u[..., :3] * u[..., 3:4], u[..., 3:4]], -1)
def pose_shift(pts, j):
    L, Bt, ce = float(LEAN[j]), float(BITE[j]), float(CHEW_ENV[j])
    q = pts.copy()
    body = BODY_DOWN * L * S_H
    head = (HEAD_DOWN * L + BITE_DOWN * Bt - CHEW_LIFT * ce) * S_H + body
    q[_hd, 1] += head
    q[[14, 15, 16, 21, 22], 1] += body * 0.8
    return q
PH0 = np.array([a for a, b in LM], float); PH0[_hd, 1] -= 3.0 * S_H
def _earmask(u8, cx, cy, rx, ry):
    a = u8[..., 3].astype(np.float32) / 255
    yy_, xx_ = np.mgrid[0:960, 0:960].astype(np.float32)
    out = ((((xx_ - cx) / rx) ** 2 + ((yy_ - cy) / ry) ** 2) > 1) & (yy_ < cy + 60) & (a > 0.05)
    return cv2.GaussianBlur(out.astype(np.float32), (0, 0), 6)
EAR_H = _earmask(HN['frame'](0), 505, 360, 215, 165)
_ob = PN['bowl_scale']; PN['bowl_scale'] = lambda i: 0.0
EAR_P = _earmask(PN['frame'](NT - 1), 490, 385, 215, 165)
PN['bowl_scale'] = _ob

def frame(i):
    if i == 0: return HN['frame'](0)                     # exact hungry anchor
    k = PN['bowl_scale'](i)
    if i < J0:
        return to_u8(bowl_on(hungry_fox(i), k, float(FOOD[i])))
    if i < J1:
        t = float(ss(J0, J1, i))
        m = Morph(pose_shift(PH0, i), pose_shift(PP, i))
        (ax, ay), (bx, by) = m.maps(t)
        A = cv2.remap(hungry_fox(i), ax, ay, cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
        B = cv2.remap(happy_fox(i), bx, by, cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
        w = float(ss(0.15, 0.85, t)); we = 1.0 if t >= 0.5 else 0.0       # ears swap quickly: no double ears
        eA = cv2.remap(EAR_H, ax, ay, cv2.INTER_LINEAR); eB = cv2.remap(EAR_P, bx, by, cv2.INTER_LINEAR)
        e = np.clip(np.maximum(eA, eB), 0, 1)[..., None]
        wm = w * (1 - e) + we * e
        return to_u8(bowl_on(A * (1 - wm) + B * wm, k, float(FOOD[i])))
    return PN['frame'](i)

os.makedirs(OUT, exist_ok=True)
idx = [int(x) for x in os.environ['ONLY'].split(',')] if os.environ.get('ONLY') else range(NT)
for i in idx:
    Image.fromarray(frame(i)).save(f'{OUT}/f{i:04d}.png')
print('done', NT)
