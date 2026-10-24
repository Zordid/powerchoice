"""Compile a key script into KEYS.BIN for SCRDUMP.COM.

usage: python3 -I keys.py <out.bin> <token>...
tokens: enter esc tab bksp space up down left right home end pgup pgdn
        ins del f1..f10 alt-f1..alt-f10 alt-<letter> "t:<text>" (typed text)
        "w:<seconds>" sets the delay before the following keys (default 1.5s)
Each entry is <key word><delay ticks before this key>.
"""
import sys, struct

SPECIAL = {'enter': 0x1C0D, 'esc': 0x011B, 'tab': 0x0F09, 'bksp': 0x0E08, 'space': 0x3920,
           'up': 0x4800, 'down': 0x5000, 'left': 0x4B00, 'right': 0x4D00, 'home': 0x4700,
           'end': 0x4F00, 'pgup': 0x4900, 'pgdn': 0x5100, 'ins': 0x5200, 'del': 0x5300}
for i in range(10):
    SPECIAL[f'f{i+1}'] = (0x3B + i) << 8
    SPECIAL[f'alt-f{i+1}'] = (0x68 + i) << 8
ROWS = ['1234567890-=', 'qwertyuiop[]', "asdfghjkl;'", 'zxcvbnm,./']
STARTS = [0x02, 0x10, 0x1E, 0x2C]
SCAN = {}
for row, st in zip(ROWS, STARTS):
    for i, ch in enumerate(row):
        SCAN[ch] = st + i
SCAN['space'] = 0x39
SCAN['\\'] = 0x2B
SHIFTED = dict(zip('!@#$%^&*()_+{}:"<>?', '1234567890-=[];\',./'))

def char(c):
    if c == ' ':
        return 0x3920
    base = c.lower() if c.isalpha() else SHIFTED.get(c, c)
    return (SCAN[base] << 8) | ord(c)

out, entries, delay = sys.argv[1], [], 1.5
for tok in sys.argv[2:]:
    if tok.startswith('w:'):
        delay = float(tok[2:]); continue
    if tok.startswith('t:'):
        keys = [char(c) for c in tok[2:]]
        if not keys:
            continue
        entries += [(keys[0], delay)] + [(k, 0.055) for k in keys[1:]]
        continue
    if tok in SPECIAL:
        k = SPECIAL[tok]
    elif tok.startswith('alt-'):
        k = SCAN[tok[4:]] << 8
    else:
        raise SystemExit(f'unknown key {tok}')
    entries.append((k, delay))
data = b''.join(struct.pack('<HH', k, max(1, round(d * 18.2))) for k, d in entries)
open(out, 'wb').write(data)
print(f'{len(entries)} keys, {sum(d for _, d in entries):.0f}s')
