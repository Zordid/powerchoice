"""Render SCRDUMP text-screen dumps to PNG using the dumped VGA font.

usage: python3 -I render.py <font.bin> <out.png> <dump.bin> [scale]
       python3 -I render.py --text <dump.bin>     (print screen as text)
"""
import sys, zlib, struct

PAL = [(0,0,0),(0,0,170),(0,170,0),(0,170,170),(170,0,0),(170,0,170),(170,85,0),(170,170,170),
       (85,85,85),(85,85,255),(85,255,85),(85,255,255),(255,85,85),(255,85,255),(255,255,85),(255,255,255)]

def load(path):
    b = open(path, 'rb').read()
    cols, rows, mode = b[0], b[1], b[2]
    return cols, rows, b[3:3 + cols * rows * 2]

def text(path):
    cols, rows, cells = load(path)
    for r in range(rows):
        line = bytes(cells[(r * cols + c) * 2] for c in range(cols))
        print(line.decode('cp437'))

def png(fontp, outp, path, scale=1):
    font = open(fontp, 'rb').read()
    cols, rows, cells = load(path)
    w, h = cols * 8, rows * 16
    raw = bytearray()
    for y in range(h):
        r, fy = divmod(y, 16)
        line = bytearray()
        for c in range(cols):
            ch, at = cells[(r * cols + c) * 2], cells[(r * cols + c) * 2 + 1]
            fg, bg = PAL[at & 15], PAL[at >> 4]
            bits = font[ch * 16 + fy]
            for x in range(8):
                px = fg if bits & (0x80 >> x) else bg
                line += bytes(px) * scale
        for _ in range(scale):
            raw += b'\0' + line
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
    data = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w * scale, h * scale, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b''))
    open(outp, 'wb').write(data)

def pixels(font, cols, rows, cells):
    """Rendered screen as rows of palette indices (8x16 pixels per cell)."""
    out = []
    for y in range(rows * 16):
        r, fy = divmod(y, 16)
        line = bytearray()
        for c in range(cols):
            ch, at = cells[(r * cols + c) * 2], cells[(r * cols + c) * 2 + 1]
            bits = font[ch * 16 + fy]
            for x in range(8):
                line.append(at & 15 if bits & (0x80 >> x) else at >> 4)
        out.append(bytes(line))
    return out

if __name__ == '__main__':
    if sys.argv[1] == '--text':
        text(sys.argv[2])
    else:
        png(sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]) if len(sys.argv) > 4 else 1)
