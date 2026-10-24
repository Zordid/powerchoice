"""Plan a Power-Choice 3.1 Tetris game: a model of v3/src/PCHTETRI.PAS plus
a small AI with one piece of lookahead.

usage: python3 tetris-plan.py <pieces> <seed>
       prints key tokens for keys.py, and the predicted final field on stderr

The game seeds Turbo Pascal's Random from the DOS clock (Randomize). In
DOSBox-X with a fixed CPU speed and a set DOS time every run is identical,
so the seed can be found once (by matching a test game against all clock
values) and the whole piece sequence is known in advance:
  seed = DX shl 16 + CX of INT 21h/2Ch, Random(n) = (seed shr 16) mod n.
"""
import sys

MASKS = {1: (0x0066, 0x0066, 0x0066, 0x0066), 2: (0x0036, 0x0462, 0x0036, 0x0462),
         3: (0x0063, 0x0132, 0x0063, 0x0132), 4: (0x000F, 0x4444, 0x000F, 0x4444),
         5: (0x0074, 0x0223, 0x0170, 0x0311), 6: (0x0072, 0x0232, 0x0270, 0x0262),
         7: (0x0071, 0x0322, 0x0470, 0x0226)}
SHAPES = {n: [[(k % 4, k // 4) for k in range(16) if m >> k & 1] for m in ms] for n, ms in MASKS.items()}
W, H = 10, 20

def pieces(seed, count):
    out = []
    for _ in range(count):
        seed = (seed * 134775813 + 1) & 0xFFFFFFFF
        out.append((seed >> 16) % 7 + 1)
    return out

def fits(field, num, rot, c, line):
    for x, y in SHAPES[num][rot]:
        cx, row = c + x, line + y
        if not (0 <= cx < W and row <= H) or (row >= 1 and field[row - 1][cx]):
            return False
    return True

def place(field, num, rot, c):
    """Rotate at spawn, shift, drop. Returns (new field, lines) or None."""
    line = 1
    if not fits(field, num, 0, 3, line):
        return None
    for r in range(rot):
        if not fits(field, num, r + 1, 3, line):
            return None
    step = 1 if c > 3 else -1
    for cc in range(3 + step, c + step, step) if c != 3 else []:
        if not fits(field, num, rot, cc, line):
            return None
    while fits(field, num, rot, c, line + 1):
        line += 1
    new = [row[:] for row in field]
    for x, y in SHAPES[num][rot]:
        new[line + y - 1][c + x] = num
    full = [i for i, row in enumerate(new) if all(row)]
    for i in full:
        del new[i]
        new.insert(0, [0] * W)
    return new, len(full)

def score(field, lines):
    heights = [next((H - r for r in range(H) if field[r][c]), 0) for c in range(W)]
    holes = sum(1 for c in range(W) for r in range(H - heights[c], H) if not field[r][c])
    bump = sum(abs(heights[i] - heights[i + 1]) for i in range(W - 1))
    return -0.51 * sum(heights) + 0.76 * lines - 0.36 * holes - 0.18 * bump - 0.4 * max(heights)

def moves(field, num):
    for rot in range(4):
        for c in range(-1, W):
            r = place(field, num, rot, c)
            if r:
                yield rot, c, r

def best(field, num, nxt):
    choice, top = None, -1e9
    for rot, c, (f1, l1) in moves(field, num):
        s1 = max((score(f2, l1 + l2) for _, _, (f2, l2) in moves(f1, nxt)), default=-1e6)
        if s1 > top:
            choice, top = (rot, c, f1, l1), s1
    return choice

count, seed = int(sys.argv[1]), int(sys.argv[2])
seq = pieces(seed, count + 1)
field = [[0] * W for _ in range(H)]
keys, total = [], 0
for i in range(count):
    rot, c, field, lines = best(field, seq[i], seq[i + 1])
    total += lines
    # look at the new piece, then rotate and shift quickly, then drop
    steps = ['up'] * rot + (['right'] * (c - 3) if c > 3 else ['left'] * (3 - c))
    if not steps:
        keys += ['w:0.95', 'down']
        continue
    keys += ['w:0.6', steps[0]]
    for key in steps[1:]:
        keys += ['w:0.06', key]
    keys += ['w:0.35', 'down']
print(' '.join(keys))
print(f'pieces {seq[:count]}  lines {total}', file=sys.stderr)
for row in field:
    print(''.join(str(v) if v else '.' for v in row), file=sys.stderr)
