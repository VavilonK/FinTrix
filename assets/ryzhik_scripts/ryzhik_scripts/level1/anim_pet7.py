"""PET_HAPPY: one-shot affectionate reaction. Starts and ends exactly on the HAPPY_IDLE anchor
(frame 0 of the happy idle = the untouched source pose). Reuses the happy-idle rig (layers, lids)."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(HERE, 'anim_happy.py')).read()
_src = _src.replace("os.path.dirname(os.path.abspath(__file__))", repr(HERE))
exec(_src[:_src.index('idx = [int(x)')])          # rig: layers, weights, lids, rot/lerp helpers

FPS = 60; DUR = 3.5; N = int(FPS * DUR)          # 210 frames
f = np.arange(N, dtype=float)
D = np.deg2rad

# --- timeline (frames) ---
Hc = ss(6, 50, f) * (1 - ss(158, 204, f))                     # lean into the petting
nuz = np.sin(2 * np.pi * (f - 50) / 55) * ss(50, 72, f) * (1 - ss(136, 158, f))   # gentle rub against the hand
HEAD = D(-8.5) * Hc + D(1.3) * nuz
HEAD_UP = -6.0 * Hc                                          # pushes up into the hand a touch
LEAN = D(-1.4) * Hc                                          # upper body follows a little
E = ss(14, 58, f) * (1 - ss(150, 200, f))                    # ears relax outward
LEAR = D(-7.0) * E + D(-1.2) * nuz
REAR = D(7.0) * E + D(1.0) * nuz
_tenv = ss(58, 78, f) * (1 - ss(140, 162, f))
TAIL = (D(-2.5) + D(7.5) * np.sin(2 * np.pi * (f - 68) / 42)) * _tenv          # two soft swishes, kept inside the frame
BODY_Y = 4.5 * np.sin(np.pi * f / (N - 1)) ** 2             # soft contented breath
BLINK = ss(20, 42, f) * (1 - ss(158, 180, f))                # eyes close ... reopen
# ---- eyes: fur eyelid + drawn happy arc (single lash curve that bends from the lid edge into the arc) ----
CLOSE = ss(20, 40, f) * (1 - ss(160, 180, f))                 # lid position 0..1
BEND = ss(33, 46, f) * (1 - ss(151, 164, f))                  # lash line -> happy arc
_rgb8 = (np.clip(img[..., :3], 0, 1) * 255).astype(np.uint8)
_gyy, _gxx = np.mgrid[0:H_, 0:W_].astype(np.float32)
# fur grain from plain forehead fur
_hp = img[..., :3] - cv2.GaussianBlur(img[..., :3], (0, 0), 2.5)
_grain_src = _hp[195:345, 475:640]
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

# ---- hearts from fox_petting_love ----
_P = np.array(Image.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'fox_petting_love.png')).convert('RGBA')).astype(np.float32) / 255
_hsv = cv2.cvtColor((_P[..., :3] * 255).astype(np.uint8), cv2.COLOR_RGB2HSV).astype(int)
_red = (((_hsv[..., 0] < 8) | (_hsv[..., 0] > 165)) & (_hsv[..., 1] > 80) & (_hsv[..., 2] > 120) & (_P[..., 3] > 0.1)).astype(np.uint8)
_n, _lab, _st, _ = cv2.connectedComponentsWithStats(_red)
HEARTS = []
for k in range(1, _n):
    x, y, w, h, a = _st[k]
    if a > 2500 and (x > 880 or (x < 300 and y > 500)):
        mk = cv2.dilate((_lab == k).astype(np.uint8), np.ones((15, 15), np.uint8))
        x0, y0, x1, y1 = x - 12, y - 12, x + w + 12, y + h + 12
        spr = _P[y0:y1, x0:x1].copy(); spr[..., 3] *= mk[y0:y1, x0:x1]
        HEARTS.append(np.concatenate([spr[..., :3] * spr[..., 3:4], spr[..., 3:4]], -1))
HEARTS.sort(key=lambda h: -h.shape[0])
# (spawn frame, sprite, start x, start y, scale, sway)
HSPAWN = [(50, 0, 845, 380, 0.85, 10), (58, 2, 105, 470, 0.9, -8), (66, 1, 880, 470, 0.9, 8),
          (84, 1, 95, 380, 0.8, 8), (92, 0, 840, 300, 0.7, -8), (104, 2, 890, 420, 0.8, -6),
          (116, 0, 110, 440, 0.75, 8), (126, 1, 850, 350, 0.8, 8)]
LIFE = 58
def draw_hearts(canvas, i):
    for (t0, k, cx, cy, sc, sway) in HSPAWN:
        a = i - t0
        if a < 0 or a > LIFE: continue
        u = a / LIFE
        s_ = sc * S * (1.18 * ss(0, 8, a) - 0.18 * ss(8, 16, a))
        if s_ <= 0.02: continue
        alpha = 1 - ss(LIFE - 16, LIFE, a)
        x = cx + sway * np.sin(2 * np.pi * u); y = cy - 95 * (1 - (1 - u) ** 1.6)
        spr = HEARTS[k]; h, w = spr.shape[:2]
        M = np.float32([[s_, 0, x - s_ * w / 2], [0, s_, y - s_ * h / 2]])
        layer = cv2.warpAffine(spr, M, (W, W), flags=cv2.INTER_LINEAR, borderValue=(0, 0, 0, 0)) * alpha
        canvas = layer + canvas * (1 - layer[..., 3:4])
    return canvas

UPPER = (575, 1150)
def frame(i):
    Xq, Yq = out2img(xx, yy)
    wb = weights(Xq, Yq)[0]
    P = (Xq, Yq + BODY_Y[i] * wb)
    P = lerp(P, rot(*P, UPPER, -LEAN[i]), wb)
    wh = weights(*P)[1]
    P = lerp(P, rot(P[0], P[1] - HEAD_UP[i], NECK, -HEAD[i]), wh)
    _, _, wl, wr = weights(*P)
    P = lerp(P, rot(*P, LEARB, -LEAR[i]), wl)
    P = lerp(P, rot(*P, REARB, -REAR[i]), wr)
    c_, bd = float(CLOSE[i]), float(BEND[i])
    src = paint_eyes(body_pm, c_, bd) if c_ > 0 else body_pm
    B = cv2.remap(src, P[0].astype(np.float32), P[1].astype(np.float32), cv2.INTER_CUBIC,
                  borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
    Pt = rot(Xq, Yq, TAILB, -TAIL[i])
    Tl = cv2.remap(tail_pm, Pt[0].astype(np.float32), Pt[1].astype(np.float32), cv2.INTER_CUBIC,
                   borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))
    B = np.clip(B, 0, 1); Tl = np.clip(Tl, 0, 1)
    out = B + Tl * (1 - B[..., 3:4])
    out = draw_hearts(out, i)
    al = out[..., 3:4]
    rgb = np.where(al > 1e-4, out[..., :3] / np.maximum(al, 1e-4), 0)
    return (np.concatenate([np.clip(rgb, 0, 1), np.clip(al, 0, 1)], -1) * 255 + 0.5).astype(np.uint8)

OUT = sys.argv[1] if len(sys.argv) > 1 else 'frames_pet7'
os.makedirs(OUT, exist_ok=True)
idx = [int(x) for x in os.environ['ONLY'].split(',')] if os.environ.get('ONLY') else range(N)
for i in idx:
    Image.fromarray(frame(i)).save(f'{OUT}/f{i:04d}.png')
print('done')
