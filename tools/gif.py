"""Turn a directory of SCRDUMP screen dumps into an animated GIF.

usage: python3 gif.py <dumpdir> <out.gif> [--rate TICKS] [--from N] [--to N]
                      [--hold SECONDS] [--skip-row0]

  --rate   timer ticks between dumps, as assembled into SCRDUMP (default 18)
  --from   first dump number to use, --to last one (inclusive)
  --hold   extra time on the last frame (default 3 seconds)
  --skip-row0  ignore the top row when merging identical frames, so a
               running clock does not keep every frame alive

Identical consecutive frames are merged into one longer frame. Needs Pillow.
"""
import os, sys
from PIL import Image
from render import PAL, load, pixels

args = sys.argv[1:]
def opt(name, default):
    if name in args:
        i = args.index(name)
        val = args[i + 1]
        del args[i:i + 2]
        return val
    return default
rate = int(opt('--rate', 18))
first = int(opt('--from', 0))
last = int(opt('--to', 999))
hold = float(opt('--hold', 3))
skip_row0 = '--skip-row0' in args
if skip_row0:
    args.remove('--skip-row0')
dumpdir, out = args

font = open(os.path.join(dumpdir, 'FONT.BIN'), 'rb').read()
palette = [v for rgb in PAL for v in rgb]
frames, durations, prev = [], [], None
tick_ms = rate * 1000 / 18.2
for name in sorted(os.listdir(dumpdir)):
    if not (name.startswith('S') and name.endswith('.BIN')):
        continue
    n = int(name[1:4])
    if not first <= n <= last:
        continue
    cols, rows, cells = load(os.path.join(dumpdir, name))
    key = cells[cols * 2:] if skip_row0 else cells
    if key == prev:
        durations[-1] += tick_ms
        continue
    prev = key
    im = Image.frombytes('P', (cols * 8, rows * 16), b''.join(pixels(font, cols, rows, cells)))
    im.putpalette(palette)
    frames.append(im)
    durations.append(tick_ms)
durations[-1] += hold * 1000
frames[0].save(out, save_all=True, append_images=frames[1:], loop=0,
               duration=[round(d) for d in durations], optimize=False, disposal=1)
print(f'{len(frames)} frames, {sum(durations) / 1000:.1f}s, {os.path.getsize(out) // 1024} KB')
