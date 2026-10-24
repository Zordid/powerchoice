"""Power-Choice TV spot, 1990 style (a 2026 homage that never aired).

usage: ad.py <repo> <font.bin> <soundtrack.wav> <out.mp4>
       ad.py <repo> <font.bin> --preview <out-prefix> <second>...

font.bin is the 8x16 VGA font as dumped by tools/scrdump.asm (FONT.BIN).
Scenes are drawn at 640x480, then a CRT pass adds curved glass, scan lines,
glow, colour bleed and noise. Needs numpy, Pillow and ffmpeg.
"""
import math, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO, FONTBIN = sys.argv[1], sys.argv[2]
W, H = 640, 480                  # picture as composed
OW, OH = 960, 720                # picture after the CRT pass
FPS = 30
LENGTH = 39.0
SUP = '/System/Library/Fonts/Supplemental/'
rng = np.random.default_rng(1990)

def font(name, size, index=0):
    return ImageFont.truetype(SUP + name, size, index=index)

# ---------------------------------------------------------------- DOS text
VGA = open(FONTBIN, 'rb').read()
PAL = [(0, 0, 0), (0, 0, 170), (0, 170, 0), (0, 170, 170), (170, 0, 0), (170, 0, 170), (170, 85, 0), (170, 170, 170),
       (85, 85, 85), (85, 85, 255), (85, 255, 85), (85, 255, 255), (255, 85, 85), (255, 85, 255), (255, 255, 85), (255, 255, 255)]
GLYPHS = {}

def glyph(ch, fg, bg):
    key = (ch, fg, bg)
    if key not in GLYPHS:
        im = Image.new('RGB', (8, 16), PAL[bg])
        px = im.load()
        for y in range(16):
            bits = VGA[ch * 16 + y]
            for x in range(8):
                if bits & (0x80 >> x):
                    px[x, y] = PAL[fg]
        GLYPHS[key] = im
    return GLYPHS[key]

def dos_screen(lines, cursor=None, attr=0x07):
    """80x25 text screen as a 640x480 picture (text area 640x400, overscan)."""
    im = Image.new('RGB', (W, H), (0, 0, 0))
    fg, bg = attr & 15, attr >> 4
    for r, line in enumerate(lines[:25]):
        for c, ch in enumerate(line.encode('cp437')[:80]):
            if ch != 32 or bg:
                im.paste(glyph(ch, fg, bg), (c * 8, 40 + r * 16))
    if cursor:
        r, c = cursor
        ImageDraw.Draw(im).rectangle([c * 8, 40 + r * 16 + 13, c * 8 + 7, 40 + r * 16 + 14], fill=PAL[fg])
    return im

def zoom_view(im, z, cx, cy):
    """Crop around (cx, cy) by factor z, keeping the crop inside the picture."""
    w, h = W / z, H / z
    x0 = min(max(cx - w / 2, 0), W - w)
    y0 = min(max(cy - h / 2, 0), H - h)
    return im.crop((x0, y0, x0 + w, y0 + h)).resize((W, H), Image.BICUBIC)

def typed(text, t, t0, t1):
    """The part of text typed by time t, typing irregularly between t0 and t1."""
    if t < t0:
        return ''
    k = len(text)
    steps = np.cumsum(np.random.default_rng(len(text)).uniform(0.5, 1.5, k))
    steps = t0 + (t1 - t0) * steps / steps[-1]
    return text[:int(np.searchsorted(steps, t, side='right'))]

def blink(t):
    return int(t * 3.75) % 2 == 0

# ---------------------------------------------------------------- graphics
def gradient(w, h, stops):
    """Vertical gradient image from [(pos, (r,g,b)), ...]."""
    ys = np.linspace(0, 1, h)
    cols = np.zeros((h, 3))
    for i in range(3):
        cols[:, i] = np.interp(ys, [p for p, _ in stops], [c[i] for _, c in stops])
    return Image.fromarray(np.repeat(cols[:, None, :], w, axis=1).astype(np.uint8))

CHROME = [(0, (40, 60, 160)), (0.35, (200, 230, 255)), (0.5, (255, 255, 255)),
          (0.52, (70, 40, 30)), (0.7, (180, 120, 70)), (1, (255, 230, 170))]
HOT = [(0, (255, 255, 120)), (0.5, (255, 170, 0)), (1, (220, 0, 0))]

def fancy_text(text, fnt, stops, outline=(10, 10, 40), depth=8, shear=0.18):
    """Chrome-style lettering: gradient fill, outline, extrusion, italic shear."""
    l, t, r, b = fnt.getbbox(text)
    w, h = r - l + 40, b - t + 40 + depth
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).text((20 - l, 20 - t), text, font=fnt, fill=255)
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    for d in range(depth, 0, -1):                       # extrusion
        shade = Image.new('RGBA', (w, h), outline + (255,))
        out.paste(shade, (d, d), mask)
    edge = mask.filter(ImageFilter.MaxFilter(5))
    out.paste(Image.new('RGBA', (w, h), outline + (255,)), (0, 0), edge)
    fill = gradient(w, h, [(p * (b - t) / h + 20 / h, c) for p, c in stops]).convert('RGBA')
    out.paste(fill, (0, 0), mask)
    if shear:
        out = out.transform((w + int(h * shear), h), Image.AFFINE, (1, shear, -h * shear, 0, 1, 0), Image.BICUBIC)
    return out

def paste_center(base, im, cx, cy, scale=1.0, alpha=1.0):
    if scale != 1.0:
        im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.BICUBIC)
    if alpha < 1.0:
        a = im.getchannel('A').point(lambda v: int(v * alpha))
        im = im.copy()
        im.putalpha(a)
    base.alpha_composite(im, (int(cx - im.width / 2), int(cy - im.height / 2)))

def grid_background(t):
    """1990 'cyber' backdrop: night sky, stars, perspective grid moving forward."""
    im = gradient(W, H, [(0, (5, 0, 30)), (0.55, (60, 0, 90)), (0.56, (10, 0, 30)), (1, (30, 0, 60))]).convert('RGBA')
    d = ImageDraw.Draw(im)
    srng = np.random.default_rng(7)
    for x, y, b in zip(srng.integers(0, W, 70), srng.integers(0, 250, 70), srng.integers(80, 255, 70)):
        tw = int(b * (0.6 + 0.4 * math.sin(t * 5 + x)))
        d.point((int(x), int(y)), fill=(tw, tw, tw))
    horizon = 265
    for i in range(-14, 15):                            # lines to the vanishing point
        d.line([(W / 2 + i * 8, horizon), (W / 2 + i * 120, H)], fill=(255, 40, 200), width=1)
    for k in range(12):                                 # horizontal lines rushing closer
        z = ((k + (t * 1.6) % 1) / 12) ** 2.2
        y = horizon + z * (H - horizon)
        d.line([(0, y), (W, y)], fill=(255, 40, 200), width=1 + int(z * 2))
    return im

def stripes_background(t):
    im = gradient(W, H, [(0, (0, 20, 120)), (1, (0, 0, 40))]).convert('RGBA')
    d = ImageDraw.Draw(im)
    off = int(t * 60) % 80
    for x in range(-H, W + 80, 80):
        d.polygon([(x + off, 0), (x + off + 30, 0), (x + off + 30 - H, H), (x + off - H, H)], fill=(0, 40, 160))
    return im

def starburst(r_out, r_in, n=16, color=(255, 220, 0)):
    s = r_out * 2 + 8
    im = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    pts = [(s / 2 + (r_out if i % 2 == 0 else r_in) * math.cos(math.pi * i / n),
            s / 2 + (r_out if i % 2 == 0 else r_in) * math.sin(math.pi * i / n)) for i in range(2 * n)]
    d = ImageDraw.Draw(im)
    d.polygon(pts, fill=(200, 0, 0))
    d.polygon([(s / 2 + (x - s / 2) * 0.9, s / 2 + (y - s / 2) * 0.9) for x, y in pts], fill=color)
    return im

def ease(x):
    x = min(1, max(0, x))
    return 1 - (1 - x) ** 3

def bounce(x):
    x = min(1, max(0, x))
    return 1 + 0.25 * math.sin(x * math.pi * 2.5) * (1 - x) if x > 0 else 0

# ---------------------------------------------------------------- assets
F_LOGO = font('Arial Black.ttf', 74)
F_BIG = font('Impact.ttf', 150)
F_SLOGAN = font('Futura.ttc', 30, 2)
F_LINE = font('Futura.ttc', 38, 4)
F_SMALL = font('Futura.ttc', 22, 0)
F_PRICE = font('Impact.ttf', 64)
F_BUG = font('Futura.ttc', 15, 2)
LOGO = fancy_text('POWER-CHOICE', F_LOGO, CHROME, depth=9)
FAST = fancy_text('FAST!', F_BIG, HOT, outline=(60, 0, 0), depth=10)
SCREENS = {n: Image.open(f'{REPO}/docs/screenshots/1.0e/{n}.png').convert('RGB')
           for n in ('menu', 'edit', 'info', 'install')}
PACKAGE = Image.open(f'{REPO}/docs/1990/package.jpg').convert('RGBA')

def text_img(text, fnt, fill=(255, 255, 255), shadow=(0, 0, 0)):
    l, t, r, b = fnt.getbbox(text)
    im = Image.new('RGBA', (r - l + 8, b - t + 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.text((4 - l + 3, 4 - t + 3), text, font=fnt, fill=shadow)
    d.text((4 - l, 4 - t), text, font=fnt, fill=fill)
    return im

# ---------------------------------------------------------------- scenes
def scene_dos(t):
    m = '   '                                             # keep clear of the curved glass
    lines = ['', m + 'C:\\>' + typed('wordperfect', t, 1.4, 3.6)]
    cur = (1, len(lines[1]))
    if t >= 4.0:
        lines += [m + 'Bad command or file name', '', m + 'C:\\>' + typed('cd \\wp51', t, 4.9, 5.6)]
        cur = (4, len(lines[4]))
    if t >= 5.9:
        lines[4] = m + 'C:\\>cd \\wp51'
        lines += [m + 'Invalid directory', '', m + 'C:\\>']
        cur = (7, len(m) + 4)
    im = dos_screen(lines, cur if blink(t) else None)
    z = 2.0 + 0.5 * ease((t - 4.0) / 0.6)                # big text, push in on the error
    return zoom_view(im, z, 0, 40 + 4 * 16).convert('RGBA')

def scene_batch(t):
    box = ['', '', '        ╔══════════════════════════════╗',
           '        ║          MAIN  MENU          ║',
           '        ║                              ║',
           '        ║   1. WordPerfect             ║',
           '        ║   2. Lotus 1-2-3             ║',
           '        ║   3. dBASE III               ║',
           '        ║   4. Exit to DOS             ║',
           '        ╚══════════════════════════════╝', '',
           '        Enter your choice (1-4): ' + ('5' if t >= 8.3 else '')]
    if t >= 8.6:
        box += ['', '        INVALID CHOICE!  Press any key...']
    im = dos_screen(box, (11, 37 if t >= 8.3 else 36) if blink(t) else None)
    return zoom_view(im, 1.45, 270, 40 + 8 * 16).convert('RGBA')

def scene_fast(t):
    im = Image.new('RGBA', (W, H), (0, 0, 40, 255))
    words = [('GET', 9.4), ('WITH', 9.7), ('THE', 9.95), ('PROGRAM...', 10.2)]
    x = 60
    for w, at in words:
        if t >= at:
            ti = text_img(w, F_LINE)
            im.alpha_composite(ti, (x, int(150 + 20 * (1 - ease((t - at) / 0.2)))))
        x += F_LINE.getbbox(w + ' ')[2]
    if t >= 11.1:
        d = ImageDraw.Draw(im)
        for i in range(24):                               # speed lines
            a = i / 24 * 2 * math.pi + t
            d.line([(W / 2 + math.cos(a) * 140, 330 + math.sin(a) * 60),
                    (W / 2 + math.cos(a) * 700, 330 + math.sin(a) * 300)], fill=(255, 200, 0), width=2)
        k = ease((t - 11.1) / 0.25)
        shake = (rng.integers(-6, 7), rng.integers(-6, 7)) if t < 11.6 else (0, 0)
        paste_center(im, FAST, W / 2 + shake[0], 330 + shake[1], scale=3 - 2 * k)
    return im

def scene_logo(t, at=12.0, y=200, size=0.86):
    im = grid_background(t)
    k = ease((t - at) / 0.6)
    paste_center(im, LOGO, W / 2, y, scale=(0.15 + 0.85 * k) * size, alpha=min(1, k * 2))
    if t >= at + 1.4:
        s = text_img('The Ultimate Menu System for PCs!', F_SLOGAN, fill=(255, 255, 90), shadow=(80, 0, 80))
        paste_center(im, s, W / 2, y + 80 * size, scale=size, alpha=ease((t - at - 1.4) / 0.4))
    if at <= t < at + 0.25:                               # flash
        im.alpha_composite(Image.new('RGBA', (W, H), (255, 255, 255, int(255 * (1 - (t - at) / 0.25)))))
    sp = t - (at + 2.4)
    if 0 <= sp < 0.8:                                     # sparkle running over the logo
        d = ImageDraw.Draw(im)
        sx, sy = 150 + sp / 0.8 * 340, y - 22 * size
        for a in range(4):
            ang = a * math.pi / 4
            d.line([(sx - math.cos(ang) * 22, sy - math.sin(ang) * 22),
                    (sx + math.cos(ang) * 22, sy + math.sin(ang) * 22)], fill=(255, 255, 255), width=2)
    return im

def scene_screens(t):
    seq = [('menu', 16.4), ('install', 17.6), ('edit', 18.8), ('info', 19.9)]
    name = [n for n, at in seq if t >= at][-1]
    at = dict(seq)[name]
    im = Image.new('RGBA', (W, H), (0, 0, 0, 255))
    shot = SCREENS[name]
    z = 0.9 + 0.05 * (t - at)                            # slow push-in
    sw, sh = int(W * z), int(400 * z)
    im.paste(shot.resize((sw, sh), Image.BICUBIC), (int((W - sw) / 2), int((H - sh) / 2)))
    if t - at < 0.12:                                     # quick white cut
        im.alpha_composite(Image.new('RGBA', (W, H), (255, 255, 255, int(200 * (1 - (t - at) / 0.12)))))
    return im

def scene_features(t):
    im = stripes_background(t)
    paste_center(im, LOGO, W / 2, 70, scale=0.55)
    items = [('EASY INSTALLATION', 21.3), ('PASSWORD PROTECTION', 22.7), ('CLOCK', 24.5), ('SCREEN SAVER', 25.5)]
    for i, (txt, at) in enumerate(items):
        if t < at:
            continue
        x = int(90 + 700 * (1 - ease((t - at) / 0.35)))
        y = 150 + i * 70
        d = ImageDraw.Draw(im)
        d.rectangle([x, y + 4, x + 38, y + 42], fill=(0, 170, 0), outline=(255, 255, 255), width=2)
        d.line([(x + 8, y + 22), (x + 16, y + 32), (x + 32, y + 10)], fill=(255, 255, 255), width=5)
        im.alpha_composite(text_img(txt, F_LINE), (x + 56, y))
    return im

def scene_price(t):
    im = stripes_background(t)
    pk = PACKAGE.resize((250, 340), Image.BICUBIC).rotate(4 * math.sin(t * 1.5), Image.BICUBIC, expand=True)
    im.alpha_composite(pk, (40, 70))
    if t >= 27.6:
        b = bounce((t - 27.6) / 0.6)
        star = starburst(150, 118)
        paste_center(im, star, 450, 240, scale=b, )
        s = Image.new('RGBA', (300, 200), (0, 0, 0, 0))
        d = ImageDraw.Draw(s)
        d.text((150, 55), 'ONLY', font=F_SLOGAN, fill=(200, 0, 0), anchor='mm')
        d.text((150, 115), '$29.95!', font=F_PRICE, fill=(200, 0, 0), anchor='mm')
        paste_center(im, s.rotate(-8, Image.BICUBIC), 450, 245, scale=b)
    return im

def scene_end(t):
    im = scene_logo(t, at=30.2, y=88, size=0.7)
    lines = [('SOFTWHERE ASSOCIATES', F_LINE, (255, 255, 255), 30.8, 222),
             ('Evanston, Wyoming', F_SLOGAN, (200, 200, 255), 31.2, 266),
             ('CALL TOLL-FREE  1-800-555-0190', F_SLOGAN, (255, 255, 90), 31.8, 318),
             ('The Bottom Line in Quality Software!', F_SLOGAN, (255, 160, 255), 34.3, 370)]
    for txt, fnt, col, at, y in lines:
        if t >= at:
            paste_center(im, text_img(txt, fnt, fill=col), W / 2, y, alpha=ease((t - at) / 0.3))
    paste_center(im, text_img('A 2026 homage  ·  this ad never aired  ·  phone number fictional', F_BUG,
                              fill=(170, 170, 200)), W / 2, 438)
    return im

def static(t):
    a = rng.integers(0, 255, (H // 2, W // 2), dtype=np.uint8)
    return Image.fromarray(a).resize((W, H)).convert('RGBA')

def frame(t):
    if t < 0.8 or t >= 38.2:
        im = static(t)
    elif t < 6.6:
        im = scene_dos(t)
    elif t < 9.2:
        im = scene_batch(t)
    elif t < 12.0:
        im = scene_fast(t)
    elif t < 16.4:
        im = scene_logo(t)
    elif t < 21.0:
        im = scene_screens(t)
    elif t < 27.2:
        im = scene_features(t)
    elif t < 30.2:
        im = scene_price(t)
    else:
        im = scene_end(t)
    if 0.8 <= t < 38.2:                                   # station-style corner bug
        im.alpha_composite(text_img('2026 HOMAGE', F_BUG, fill=(230, 230, 230), shadow=(30, 30, 30)), (W - 150, 26))
    return im.convert('RGB')

# ---------------------------------------------------------------- CRT pass
yy, xx = np.mgrid[0:OH, 0:OW].astype(np.float32)
nx, ny = xx / OW * 2 - 1, yy / OH * 2 - 1
r2 = nx * nx + ny * ny
bend = 1 + 0.07 * r2                                      # barrel distortion
sx = ((nx * bend + 1) / 2 * (OW - 1)).round().astype(np.int32)
sy = ((ny * bend + 1) / 2 * (OH - 1)).round().astype(np.int32)
inside = (sx >= 0) & (sx < OW) & (sy >= 0) & (sy < OH)
sx, sy = np.clip(sx, 0, OW - 1), np.clip(sy, 0, OH - 1)
vignette = np.clip(1.15 - 0.55 * r2, 0, 1)[..., None]
corner = (np.abs(nx * bend) ** 8 + np.abs(ny * bend) ** 8) ** (1 / 8)
mask = (np.clip((1.0 - corner) * 60, 0, 1) * inside)[..., None]
scan = np.where((np.arange(OH) % 3) == 2, 0.72, 1.0).astype(np.float32)[:, None, None]

def crt(im, t):
    big = im.resize((OW, OH), Image.BILINEAR)
    a = np.asarray(big, dtype=np.float32)
    glow = np.asarray(big.filter(ImageFilter.GaussianBlur(7)), dtype=np.float32)
    a = a * 0.85 + glow * 0.4                             # bloom
    a[..., 0] = np.roll(a[..., 0], 2, axis=1)             # colour bleed
    a[..., 2] = np.roll(a[..., 2], -2, axis=1)
    a = a * scan + 14
    a = a[sy, sx] * vignette * mask
    band = 0.06 * np.exp(-((np.arange(OH) - (t * 120) % (OH * 1.6)) / 40) ** 2)[:, None, None]
    grain = rng.normal(0, 3, (OH // 2, OW // 2, 1)).repeat(2, 0).repeat(2, 1)
    a = a * (1 + band) + grain
    if t < 1.1 or t > 37.9:                               # tracking trouble
        for _ in range(6):
            y0 = int(rng.integers(0, OH - 20))
            a[y0:y0 + 14] = np.roll(a[y0:y0 + 14], int(rng.integers(-40, 40)), axis=1)
    return np.clip(a, 0, 255).astype(np.uint8)

if sys.argv[3] == '--preview':
    prefix = sys.argv[4]
    for s in sys.argv[5:]:
        t = float(s)
        Image.fromarray(crt(frame(t), t)).save(f'{prefix}-{s}.png')
    sys.exit()

audio, out = sys.argv[3], sys.argv[4]
ff = subprocess.Popen(['ffmpeg', '-loglevel', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
                       '-s', f'{OW}x{OH}', '-r', str(FPS), '-i', '-', '-i', audio,
                       '-c:v', 'libx264', '-preset', 'slow', '-crf', '27', '-pix_fmt', 'yuv420p',
                       '-c:a', 'aac', '-b:a', '96k', '-shortest', '-movflags', '+faststart', out],
                      stdin=subprocess.PIPE)
for i in range(int(LENGTH * FPS)):
    t = i / FPS
    ff.stdin.write(crt(frame(t), t).tobytes())
    if i % 150 == 0:
        print(f'{t:5.1f}s', flush=True)
ff.stdin.close()
ff.wait()
