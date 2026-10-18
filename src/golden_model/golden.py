import random, sys

N, K, NCH = 16, 3, 3
OUT = (N - K + 1) // 2          # 7

def conv(img, ker):
    n = N - K + 1
    return [[sum(img[r+i][c+j] * ker[i][j] for i in range(K) for j in range(K))
             for c in range(n)] for r in range(n)]

def pool(m):
    return [[max(m[2*r][2*c], m[2*r][2*c+1], m[2*r+1][2*c], m[2*r+1][2*c+1])
             for c in range(len(m[0]) // 2)] for r in range(len(m) // 2)]

SHIFT = 0

def relu_sat(v):
    return 0 if v < 0 else min(v >> SHIFT, 255)

def golden(img, kers):
    chans = [[[relu_sat(v) for v in row] for row in pool(conv(img, k))] for k in kers]
    return [[[chans[ch][r][c] for ch in range(NCH)] for c in range(OUT)] for r in range(OUT)]

def gen(mode):
    rk = lambda: [[[random.randint(-128, 127) for _ in range(K)] for _ in range(K)] for _ in range(NCH)]
    if mode == "zeros":
        img = [[0]*N for _ in range(N)]; kers = rk()
    elif mode == "max_pos":
        img = [[255]*N for _ in range(N)]; kers = [[[127]*K for _ in range(K)] for _ in range(NCH)]
    elif mode == "max_neg":
        img = [[255]*N for _ in range(N)]; kers = [[[-128]*K for _ in range(K)] for _ in range(NCH)]
    elif mode == "mid":         # small values so results land inside 0..255 (no saturation)
        img = [[random.randint(0, 40) for _ in range(N)] for _ in range(N)]
        kers = [[[random.randint(-2, 4) for _ in range(K)] for _ in range(K)] for _ in range(NCH)]
    elif mode == "checker":
        img = [[255 if (r + c) % 2 else 0 for c in range(N)] for r in range(N)]
        kers = [[[random.choice([-128, -1, 0, 1, 127]) for _ in range(K)] for _ in range(K)] for _ in range(NCH)]
    else:
        img = [[random.randint(0, 255) for _ in range(N)] for _ in range(N)]; kers = rk()
    return img, kers

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "random"
    random.seed(int(sys.argv[2]) if len(sys.argv) > 2 else 1)
    SHIFT = int(sys.argv[3]) if len(sys.argv) > 3 else 0

    patch = [[10,20,30],[50,60,70],[90,100,110]]
    k1 = [[1,0,-1]]*3
    k2 = [[0,1,0],[1,-4,1],[0,1,0]]
    k3 = [[1,1,1],[0,0,0],[-1,-1,-1]]
    for name, k in (("k1", k1), ("k2", k2), ("k3", k3)):
        print(name, sum(patch[i][j]*k[i][j] for i in range(3) for j in range(3)))

    img, kers = gen(mode)
    out = golden(img, kers)

    with open("image.hex", "w") as f:
        for row in img:
            for p in row: f.write(f"{p:02x}\n")
    with open("kernel.hex", "w") as f:
        for k in kers:
            for row in k:
                for v in row: f.write(f"{v & 0xFF:02x}\n")
    with open("expected.hex", "w") as f:
        for r in range(OUT):
            for c in range(OUT):
                o = out[r][c]
                f.write(f"{(o[2] << 16) | (o[1] << 8) | o[0]:06x}\n")
    print(f"mode={mode}: wrote image.hex, kernel.hex, expected.hex")