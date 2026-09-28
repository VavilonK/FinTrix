import numpy as np, cv2
from scipy.spatial import Delaunay

# (idle source coords, petting source coords)
PAIRS = [
    ((303, 33), (147, 320)),     # left ear tip
    ((1043, 213), (760, 60)),    # right ear tip
    ((657, 187), (540, 160)),    # head tuft
    ((457, 467), (527, 467)),    # left eye
    ((717, 527), (780, 373)),    # right eye
    ((563, 540), (693, 460)),    # nose
    ((550, 627), (660, 527)),    # mouth
    ((550, 693), (640, 590)),    # chin
    ((217, 467), (320, 613)),    # left cheek outer
    ((897, 640), (940, 440)),    # right cheek outer
    ((257, 373), (340, 520)),    # left ear outer/lower edge base
    ((470, 187), (407, 267)),    # left ear inner/upper base
    ((350, 200), (273, 400)),    # left ear pink centre
    ((963, 533), (867, 333)),    # right ear outer base
    ((777, 307), (660, 213)),    # right ear inner base
    ((937, 333), (780, 173)),    # right ear pink centre
    ((723, 267), (647, 220)),    # forehead
    ((390, 707), (427, 707)),    # hood left top
    ((717, 747), (827, 640)),    # hood right top
    ((550, 896), (651, 851)),    # emblem
    ((499, 820), (613, 773)),    # drawstring L
    ((590, 820), (707, 773)),    # drawstring R
    ((350, 1160), (480, 1127)),  # back paw L
    ((757, 1147), (807, 1127)),  # back paw R
    ((257, 1040), (327, 1027)),  # haunch L
    ((843, 1067), (927, 1053)),  # haunch R
    ((617, 1180), (653, 1160)),  # front paw (stays down)
    ((483, 1180), (540, 640)),   # this front paw rises to the cheek
    ((445, 1065), (505, 770)),   # its forearm
    ((1123, 733), (1167, 667)),  # tail tip
    ((1083, 1147), (1113, 1147)),# tail bottom
    ((977, 720), (953, 667)),    # tail top
    ((737, 960), (827, 987)),    # right cuff
    ((377, 960), (440, 890)),    # left cuff
    ((550, 1040), (673, 1013)),  # belly
]

def to_out(M, pts):
    pts = np.asarray(pts, np.float64)
    return pts @ M[:, :2].T + M[:, 2]

def border(W=960, n=7):
    b = []
    for v in np.linspace(-40, W + 40, n):
        b += [(v, -40), (v, W + 40), (-40, v), (W + 40, v)]
    return np.array(b)

class Morph:
    def __init__(self, pI_out, pP_out, W=960):
        self.pI = np.vstack([pI_out, border(W)]); self.pP = np.vstack([pP_out, border(W)])
        self.W = W
        yy, xx = np.mgrid[0:W, 0:W].astype(np.float64)
        self.grid = np.stack([xx.ravel(), yy.ravel()], 1)

    def maps(self, t):
        """backward maps (for the idle image and the petting image) onto the in-between shape at t"""
        D = (1 - t) * self.pI + t * self.pP
        tri = Delaunay(D)
        simp = tri.find_simplex(self.grid)
        X = tri.transform[simp, :2]; r = self.grid - tri.transform[simp, 2]
        bary = np.einsum('nij,nj->ni', X, r); bary = np.c_[bary, 1 - bary.sum(1)]
        verts = tri.simplices[simp]
        out = []
        for src in (self.pI, self.pP):
            s = np.einsum('ni,nij->nj', bary, src[verts])
            out.append((s[:, 0].reshape(self.W, self.W).astype(np.float32), s[:, 1].reshape(self.W, self.W).astype(np.float32)))
        return out
