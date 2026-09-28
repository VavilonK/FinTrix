"""PET_HUNGRY: HUNGRY_IDLE anchor -> brief warm reaction to petting -> HUNGRY_IDLE anchor.
The idle rig runs one full cycle over the clip (tau 0 -> 2pi), so first and last frames equal hungry idle frame 0."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else 'frames_pethungry'
_s = open(os.path.join(HERE, 'anim.py')).read().replace("os.path.dirname(os.path.abspath(__file__))", repr(HERE))
_s = _s.replace("OUT = sys.argv[1] if len(sys.argv) > 1 else 'frames'", "OUT = %r" % OUT)
exec(_s[:_s.index('def frame(i):')])
H_, W_ = img.shape[:2]
NP = 210; f = np.arange(NP, dtype=float); D = np.deg2rad
_rgb8 = (np.clip(img[..., :3], 0, 1) * 255).astype(np.uint8)
_gyy, _gxx = np.mgrid[0:H_, 0:W_].astype(np.float32)
# fur grain from plain forehead fur
_hp = img[..., :3] - cv2.GaussianBlur(img[..., :3], (0, 0), 2.5)
_grain_src = _hp[140:245, 560:690]
LIDS = []
for (mm, x0, x1, top, bot, tex) in EYEM:
    mb = cv2.dilate((mm > 0.3).astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (17, 13)))
    mb = cv2.dilate(mb, np.ones((10, 5), np.uint8), anchor=(2, 9))
    ys_, xs_ = np.nonzero(mb); x0, x1 = xs_.min(), xs_.max(); y0, y1 = ys_.min(), ys_.max()
    top2 = np.full(W_, np.nan); bot2 = np.full(W_, np.nan)
    for x in range(x0, x1 + 1):
        col = np.nonzero(mb[:, x])[0]; top2[x], bot2[x] = col.min(), col.max()
    fm = cv2.dilate(mb, np.ones((5, 5), np.uint8))
    memb = cv2.inpaint(_rgb8, fm * 255, 25, cv2.INPAINT_TELEA).astype(np.float32) / 255
    memb = cv2.GaussianBlur(memb, (0, 0), 9)
    lid = img[..., :3].copy()
    gh, gw = y1 - y0 + 1, x1 - x0 + 1
    g = cv2.resize(_grain_src, (gw, gh), interpolation=cv2.INTER_LINEAR)
    lid[y0:y1 + 1, x0:x1 + 1] = memb[y0:y1 + 1, x0:x1 + 1] + 0.9 * g
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2; rx, ry = (x1 - x0) / 2, (y1 - y0) / 2
    rr = ((_gxx - cx) / rx) ** 2 + ((_gyy - cy) / ry) ** 2
    lid *= np.clip(1.04 - 0.08 * rr, 0.92, 1.05)[..., None]          # gentle roundness
    LIDS.append(dict(m=cv2.GaussianBlur(mb.astype(np.float32), (0, 0), 2.0), x0=x0, x1=x1, y0=y0, y1=y1,
                     top=top2, bot=bot2, lid=np.clip(lid, 0, 1), cx=cx, cy=cy, rx=rx, ry=ry))
TILT = np.arctan2(LIDS[1]['cy'] - LIDS[0]['cy'], LIDS[1]['cx'] - LIDS[0]['cx'])   # face tilt

def lid_edge(L, x, c):
    uu = np.clip((x - L['cx']) / L['rx'], -1, 1); sq = np.sqrt(1 - uu ** 2)
    return L['cy'] + L['ry'] * (2 * c - 1) * sq + c * L['ry'] * (1 - sq)

def curve_pts(L, close, bend, n=60):
    u = np.linspace(-1, 1, n)
    kx = 0.9
    xs = L['cx'] + u * L['rx'] * kx
    y_edge = lid_edge(L, xs, close) - 2 * close
    # happy arc (rotated with the face): narrower, bows upward
    k = 0.80
    ax_ = L['cx'] + u * L['rx'] * k * np.cos(TILT) - 0 * np.sin(TILT)
    base = L['cy'] + 0.22 * L['ry'] - 0.46 * L['ry'] * (1 - u ** 2)
    ay_ = base + u * L['rx'] * k * np.sin(TILT)
    X = xs + (ax_ - xs) * bend; Y = y_edge + (ay_ - y_edge) * bend
    return X, Y, u

def stroke(L, X, Y, u, strength, bend, outer_right):
    """anti-aliased tapered dark stroke (+ lashes on the outer corner) drawn at 4x, returns alpha in the eye box"""
    pad = 30; ox, oy = L['x0'] - pad, L['y0'] - pad - 40
    Wb, Hb = (L['x1'] - L['x0'] + 2 * pad), (L['y1'] - L['y0'] + 2 * pad + 40)
    SS = 4; can = np.zeros((Hb * SS, Wb * SS), np.uint8)
    th = (2.2 + 8.5 * bend) * np.clip(1 - np.abs(u) ** 2.5, 0.12, 1) + 0.8
    P = np.stack([(X - ox) * SS, (Y - oy) * SS], 1)
    for i in range(len(u) - 1):
        cv2.line(can, tuple(np.int32(P[i])), tuple(np.int32(P[i + 1])), 255, max(1, int(th[i] * SS)), cv2.LINE_AA)
    if bend > 0.3:                                             # three little lashes at the outer end
        e = len(u) - 1 if outer_right else 0
        sgn = 1 if outer_right else -1
        ex, ey = P[e]
        for j, (ang, ln) in enumerate([(-35, 13), (-10, 15), (15, 11)]):
            a = np.deg2rad(ang) * sgn + (0 if outer_right else np.pi)
            d = np.array([np.cos(a), -np.sin(a) * 1.0]) * ln * SS * min(1, (bend - 0.3) / 0.5)
            st = np.array([ex, ey]) - np.array([sgn * (6 + 5 * j), 2 * j]) * SS
            cv2.line(can, tuple(np.int32(st)), tuple(np.int32(st + d)), 255, int(2.2 * SS), cv2.LINE_AA)
    a_ = cv2.resize(can, (Wb, Hb), interpolation=cv2.INTER_AREA).astype(np.float32) / 255 * strength
    return a_, ox, oy

def paint_eyes(pm_, close, bend):
    out = pm_.copy()
    for k_, L in enumerate(LIDS):
        x0, x1 = L['x0'], L['x1']
        sl = slice(x0 - 4, x1 + 5)
        c1 = min(1.0, close * 1.08)
        yL = lid_edge(L, np.arange(x0 - 4, x1 + 5, dtype=float), c1) + 3 * c1
        lidm = (np.clip((yL[None, :] - YS) / 2.0 + 0.5, 0, 1) * L['m'][:, sl] * min(1.0, close * 8))[..., None]
        o = out[:, sl]
        sh = (np.clip(1 - (YS - yL[None, :]) / 12.0, 0, 1) * (YS > yL[None, :]) * L['m'][:, sl] * 0.3 * (1 - close))[..., None]
        o[..., :3] *= (1 - sh)
        lidc = np.concatenate([L['lid'][:, sl] * o[..., 3:4], o[..., 3:4]], -1)
        o[:] = o * (1 - lidm) + lidc * lidm
        X, Y, u = curve_pts(L, min(1.0, close * 1.08), bend)
        a_, ox, oy = stroke(L, X, Y, u, min(1.0, close * 3) ** 2, bend, outer_right=(k_ == 1))
        Hb, Wb = a_.shape
        reg = out[oy:oy + Hb, ox:ox + Wb]
        dark = np.array([0.10, 0.06, 0.05], np.float32)
        al = a_[..., None] * (reg[..., 3:4] > 0.5)
        reg[..., :3] = reg[..., :3] * (1 - al) + dark * reg[..., 3:4] * al
    return out


# wider tail weight for the swish, so the tail tip is never left behind when it swings up
tail_w2 = ss(810, 900, X0) * np.maximum(ss(600, 700, Y0), ss(500, 580, Y0) * ss(965, 1010, X0)) * ss(60, 420, d_tail)
from PIL import ImageDraw as _IDraw
_tp = Image.new('L', (img.shape[1], img.shape[0]), 0)
_IDraw.Draw(_tp).polygon([(752, 740), (790, 672), (860, 662), (912, 618), (960, 592), (1150, 580), (1150, 1250), (752, 1250)], fill=255)
_tm = (np.array(_tp) > 0) & ~(img[..., 2] > img[..., 0] + 0.1)
_tailsrc = cv2.GaussianBlur(((np.array(_tp) > 0) & (_gyy_ := np.mgrid[0:img.shape[0], 0:img.shape[1]][0] > 676)).astype(np.float32), (0, 0), 1.5)
_facesrc = cv2.GaussianBlur(((_gyy_ <= 690) & (np.array(_tp) == 0) & (img[..., 3] > 0.05)).astype(np.float32), (0, 0), 1.5)
GAPZONE = (ss(770, 735, Y0) * ss(700, 740, X0)).astype(np.float32)
TZ = cv2.remap(cv2.GaussianBlur(_tm.astype(np.float32), (0, 0), 3), X0.astype(np.float32), Y0.astype(np.float32), cv2.INTER_LINEAR)
# ---- reaction timeline ----
PHI = 2 * np.pi * ss(52, 116, np.arange(210, dtype=float))
CLOSE = ss(24, 44, f) * (1 - ss(146, 166, f))
BEND = ss(37, 50, f) * (1 - ss(138, 151, f))
R = ss(16, 52, f) * (1 - ss(140, 186, f))                     # overall "warmth" envelope
nuz = np.sin(2 * np.pi * (f - 52) / 50) * ss(52, 70, f) * (1 - ss(118, 140, f))
HEAD_R = D(-7.5) * R + D(1.2) * nuz                          # leans into the hand
HEAD_UP = 7.0 * R                                            # perks up a little
CHEST = 5.0 * R                                              # sits a bit taller
LEAR_R = D(6.0) * R - D(1.0) * nuz                           # ears lift / relax outward
REAR_R = D(-6.0) * R + D(1.0) * nuz
_sw = (f - 60) / 50.0                                         # one happy swish, toward the back (stays in frame)
TAIL_R = D(-12.0) * np.sin(np.pi * np.clip(_sw, 0, 1)) ** 2 + 0 * D(2.0) * np.sin(2 * np.pi * np.clip(_sw - 0.6, 0, 0.4) / 0.4) * (np.clip(_sw - 0.6, 0, 0.4) > 0) * ss(1.0, 0.6, _sw) 
DAMP = 1 - 0.6 * R
TIPCALM = ss(40, 62, f) * (1 - ss(112, 140, f))                # tip curl rests during the swish                                           # hungry idle motion calms while enjoying it

def frame(i):
    tau = 2 * np.pi * i / (NP - 1)
    dmp = float(DAMP[i])
    X, Y = X0.copy(), Y0.copy()
    br = np.sin(2 * tau)
    Y = Y + 6.5 * br * breath_up
    cx = 565
    X = cx + (X - cx) / (1 + 0.016 * br * chest_w)
    Y = Y + CHEST[i] * breath_up
    ang_b = np.deg2rad(1.6 * np.sin(tau + 0.3))
    Xb, Yb = rot(X, Y, 565, 1120, -ang_b)
    X = X + (Xb - X) * breath_up; Y = Y + (Yb - Y) * breath_up
    ang_h = np.deg2rad(2.8 * np.sin(tau + 0.6)) * dmp + (1 - dmp) * np.deg2rad(2.8 * np.sin(0.6))
    Xh, Yh = rot(X, Y, 560, 690, -ang_h)
    X = X + (Xh - X) * head_w; Y = Y + (Yh - Y) * head_w
    Y = Y + (2.5 * np.sin(2 * tau - 0.9) * dmp) * head_w
    # reaction head motion: same head, but the tail never follows it
    hx = head_w * (1 - TZ)
    Xh, Yh = rot(X, Y, 560, 690, -HEAD_R[i])
    X = X + (Xh - X) * hx; Y = Y + (Yh - Y) * hx
    Y = Y + HEAD_UP[i] * hx
    HX = hx
    ang_re = np.deg2rad(3.0 * np.sin(tau + 1.7)) * dmp + (1 - dmp) * np.deg2rad(3.0 * np.sin(1.7)) + REAR_R[i]
    Xe, Ye = rot(X, Y, 895, 395, -ang_re)
    X = X + (Xe - X) * rear_w; Y = Y + (Ye - Y) * rear_w
    ang_le = np.deg2rad(-2.6 * np.sin(tau + 2.4)) * dmp + (1 - dmp) * np.deg2rad(-2.6 * np.sin(2.4)) + LEAR_R[i]
    Xe, Ye = rot(X, Y, 345, 340, -ang_le)
    X = X + (Xe - X) * lear_w; Y = Y + (Ye - Y) * lear_w
    # happy tail swish = the idle tail does one extra full swing (same shapes as hungry idle, nothing new)
    tt = tau + PHI[i]
    ang_t = np.deg2rad(7.0 * np.sin(tt - 0.8) + 1.5 * np.sin(2 * tt + 0.3))
    Xt, Yt = rot(X, Y, 870, 1090, -ang_t)
    X = X + (Xt - X) * tail_w; Y = Y + (Yt - Y) * tail_w

    ang_tip = np.deg2rad(6.0 * np.sin(tt - 1.9))
    tip_w = tail_w ** 2.2
    Xt, Yt = rot(X, Y, 950, 870, -ang_tip)
    X = X + (Xt - X) * tip_w; Y = Y + (Yt - Y) * tip_w
    c_, bd = float(CLOSE[i]), float(BEND[i])
    srcim = paint_eyes(pm, c_, bd) if c_ > 0 else pm
    out = cv2.remap(srcim, X.astype(np.float32), Y.astype(np.float32), cv2.INTER_CUBIC,
                    borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
    out = np.clip(out, 0, 1)
    kk = min(1.0, float(R[i]) * 20)
    if kk > 0:                             # no ghost copies across the chin/tail gap
        Xf_, Yf_ = X.astype(np.float32), Y.astype(np.float32)
        ts = cv2.remap(_tailsrc, Xf_, Yf_, cv2.INTER_LINEAR)
        fs_ = cv2.remap(_facesrc, Xf_, Yf_, cv2.INTER_LINEAR)
        ghost = np.clip(ts * np.clip(HX * 30, 0, 1) + fs_ * np.clip(TZ * 2 - 0.4, 0, 1), 0, 1) * kk
        ghost = ghost * GAPZONE              # only in the chin/tail gap, never on the body or paws
        out = out * (1 - ghost[..., None])
    al = out[..., 3:4]
    rgb = np.where(al > 1e-4, out[..., :3] / np.maximum(al, 1e-4), 0)
    return (np.concatenate([np.clip(rgb, 0, 1), al], -1) * 255 + 0.5).astype(np.uint8)

os.makedirs(OUT, exist_ok=True)
idx = [int(x) for x in os.environ['ONLY'].split(',')] if os.environ.get('ONLY') else range(NP)
for i in idx:
    Image.fromarray(frame(i)).save(f'{OUT}/f{i:04d}.png')
print('done')
