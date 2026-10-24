"""Make the GitHub social preview: a 160x40 text screen, 1280x640 pixels.

usage: python3 -I social-preview.py <font.bin> <out.png>

font.bin is the 8x16 VGA font as dumped by scrdump. The big title is drawn
from the same font, one half-block character per font pixel.
"""
import sys
from render import PAL, pixels
from PIL import Image

COLS, ROWS = 160, 40
BLUE, CYAN, GRAY, WHITE, YELLOW, BLACK, LBLUE, LCYAN = 1, 3, 7, 15, 14, 0, 9, 11
font = open(sys.argv[1], 'rb').read()
cells = bytearray([0x20, BLUE << 4 | WHITE] * COLS * ROWS)

def put(x, y, s, fg, bg):
    for i, ch in enumerate(s.replace('↑', '\x18').replace('↓', '\x19').encode('cp437')):
        if 0 <= x + i < COLS:
            cells[(y * COLS + x + i) * 2:(y * COLS + x + i) * 2 + 2] = bytes([ch, bg << 4 | fg])

def center(y, s, fg, bg=BLUE):
    put((COLS - len(s)) // 2, y, s, fg, bg)

def fill(x, y, w, h, bg):
    for r in range(y, y + h):
        put(x, r, ' ' * w, WHITE, bg)

def box(x, y, w, h, title, fg, bg):
    fill(x + 2, y + 1, w, h, BLACK)                                  # shadow
    fill(x, y, w, h, bg)
    put(x, y, '╔' + '═' * (w - 2) + '╗', fg, bg)
    for r in range(y + 1, y + h - 1):
        put(x, r, '║', fg, bg); put(x + w - 1, r, '║', fg, bg)
    put(x, y + h - 1, '╚' + '═' * (w - 2) + '╝', fg, bg)
    put(x + 3, y, f' {title} ', fg, bg)

def big(y, s, fg, shadow):
    """The text in the 8x16 font, two font rows per character row."""
    bits = [[font[ord(ch) * 16 + fy] & (0x80 >> fx) for ch in s for fx in range(8)] for fy in range(16)]
    w = len(s) * 8
    x0 = (COLS - w) // 2
    for layer, (dx, dy, col) in enumerate(((1, 1, shadow), (0, 0, fg))):
        for r in range(8):
            for c in range(w):
                top, bottom = bits[2 * r][c], bits[2 * r + 1][c]
                if not (top or bottom):
                    continue
                i = ((y + r + dy) * COLS + x0 + c + dx) * 2
                old_fg = cells[i + 1] & 15
                if layer == 0 or cells[i] == 0x20:
                    ch = 0xDB if top and bottom else 0xDF if top else 0xDC
                    cells[i:i + 2] = bytes([ch, BLUE << 4 | col])
                else:                                                # title over its own shadow
                    ch = 0xDB if top and bottom else 0xDF if top else 0xDC
                    cells[i:i + 2] = bytes([ch, (old_fg if ch != 0xDB else BLUE) << 4 | col])

# title bar and status line, as in Power-Choice 1.0e
fill(0, 0, COLS, 1, CYAN)
put(2, 0, '05/18/90', BLACK, CYAN)
center(0, '* * *   P O W E R - C H O I C E   Ver 1.0e   * * *', BLACK, CYAN)
put(COLS - 12, 0, '5:00:07 pm', BLACK, CYAN)
fill(0, ROWS - 1, COLS, 1, CYAN)
put(2, ROWS - 1, 'Use ↑↓ to choose.  Enter-Run, F2-Edit, Esc-DOS', BLACK, CYAN)
put(COLS - 34, ROWS - 1, 'github.com/Zordid/powerchoice', BLACK, CYAN)

big(4, 'POWER-CHOICE', YELLOW, BLACK)
center(14, 'The Ultimate Menu System for MS-DOS', LCYAN)
center(16, 'by Olaf Gottschalk  ·  1989 - 1994', WHITE)

bx, by, bw = 38, 20, 84
box(bx, by, bw, 13, 'Main Group', WHITE, CYAN)
items = [('A', 'Version 1.0e', 'Softwhere Associates, Evanston, Wyoming, 1990'),
         ('B', 'Version 3.1 ', 'Bartels Computer Systeme, Germany, 1993'),
         ('C', 'The story   ', 'flyer, ad, manual, photos and a look back'),
         ('D', 'Play it     ', 'both versions, running in your browser')]
for n, (key, name, text) in enumerate(items):
    y = by + 2 + n * 2
    line = f' {key}» {name}  {text}'.ljust(bw - 6)
    if n == 0:
        put(bx + 3, y, line, WHITE, BLUE)
    else:
        put(bx + 3, y, line, BLACK, CYAN)
        put(bx + 4, y, key, YELLOW, CYAN)
put(bx + 3, by + 11, 'Source code, rebuilt binaries and a 1990 TV ad. Almost.'.center(bw - 6), BLUE, CYAN)

center(36, 'The English version of 1990, rebuilt from its original source in 2026.', GRAY)

rows = pixels(font, COLS, ROWS, cells)
img = Image.frombytes('P', (COLS * 8, ROWS * 16), b''.join(rows))
img.putpalette([v for rgb in PAL for v in rgb])
img.convert('RGB').save(sys.argv[2], optimize=True)
print(sys.argv[2], img.size)
