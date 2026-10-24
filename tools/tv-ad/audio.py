"""Soundtrack for the Power-Choice TV spot: synth jingle + voices, TV speaker sound.

usage: audio.py <voice dir with l1.wav ... l9.wav> <out.wav>   (see make.sh)
"""
import wave, sys
import numpy as np

SR = 44100
LENGTH = 39.0
VOICE_DIR = sys.argv[1]
OUT = sys.argv[2]
# line, start second
CUES = [('l1', 1.0), ('l2', 4.1), ('l3', 6.8), ('l4', 9.3), ('l5', 12.4),
        ('l6', 16.6), ('l7', 21.2), ('l8', 27.4), ('l9', 30.5)]
rng = np.random.default_rng(1990)
n = int(SR * LENGTH)
t = np.arange(n) / SR

def note(name):
    names = {'C': -9, 'D': -7, 'E': -5, 'F': -4, 'G': -2, 'A': 0, 'B': 2}
    return 440.0 * 2 ** ((names[name[0]] + 12 * (int(name[-1]) - 4)) / 12)

def smooth(x, k):
    return np.convolve(x, np.ones(k) / k, mode='same')

def tone(freq, dur, kind='square', amp=0.2):
    tt = np.arange(int(SR * dur)) / SR
    ph = freq * tt
    if kind == 'square':
        w = np.sign(np.sin(2 * np.pi * ph))
    elif kind == 'saw':
        w = 2 * (ph - np.floor(ph + 0.5))
    else:
        w = np.sin(2 * np.pi * ph)
    env = np.minimum(1, tt / 0.01) * np.exp(-tt * 1.5)
    return amp * w * env

def put(buf, start, sig):
    i = int(start * SR)
    j = min(len(buf), i + len(sig))
    if j > i:
        buf[i:j] += sig[:j - i]

music = np.zeros(n)
# intro: low uneasy drone under the DOS scenes
drone = (np.sin(2 * np.pi * note('C2') * t) * 0.05 + np.sin(2 * np.pi * note('G2') * 1.003 * t) * 0.03)
fade = np.clip((t - 0.8) / 1.0, 0, 1) * np.clip((12.0 - t) / 0.3, 0, 1)
music += drone * fade
# riser into the logo
r0, r1 = 10.8, 12.0
mask = (t >= r0) & (t < r1)
noise = rng.standard_normal(n)
music[mask] += (noise[mask] - smooth(noise, 8)[mask]) * ((t[mask] - r0) / (r1 - r0)) ** 2 * 0.25

# main groove from 12.0: 120 bpm, C G Am F, one bar each
beat = 0.5
chords = [('C4', 'E4', 'G4'), ('G3', 'B3', 'D4'), ('A3', 'C4', 'E4'), ('F3', 'A3', 'C4')]
roots = ['C2', 'G2', 'A2', 'F2']
start, end = 12.0, 37.5
bar = 0
while start + bar * 4 * beat < end:
    b0 = start + bar * 4 * beat
    ch = chords[bar % 4]
    for f in ch:
        pad = sum(tone(note(f) * d, 4 * beat, 'saw', 0.045) for d in (0.997, 1.003))
        put(music, b0, smooth(pad, 12))
    for k in range(8):                                   # pumping eighth bass
        put(music, b0 + k * beat / 2, tone(note(roots[bar % 4]), beat / 2 * 0.9, 'square', 0.09))
    for k in range(4):                                   # kick on every beat
        kt = np.arange(int(SR * 0.18)) / SR
        f = 45 + 80 * np.exp(-kt * 30)
        put(music, b0 + k * beat, np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-kt * 18) * 0.5)
    for k in (1, 3):                                     # snare
        st = rng.standard_normal(int(SR * 0.16))
        st = (st - smooth(st, 6)) * np.exp(-np.arange(len(st)) / SR * 22) * 0.22
        put(music, b0 + k * beat, st)
    for k in range(8):                                   # hi-hat
        hh = rng.standard_normal(int(SR * 0.03))
        hh = (hh - smooth(hh, 2)) * np.exp(-np.arange(len(hh)) / SR * 120) * 0.06
        put(music, b0 + k * beat / 2, hh)
    bar += 1

# jingle motif on the logo and on the end card
def motif(at):
    for i, (f, d) in enumerate([('E5', 0.25), ('G5', 0.25), ('C6', 0.75)]):
        put(music, at + i * 0.25, smooth(tone(note(f), d + 0.3, 'square', 0.12), 6))
    crash = rng.standard_normal(int(SR * 1.2))
    put(music, at, (crash - smooth(crash, 3)) * np.exp(-np.arange(len(crash)) / SR * 3) * 0.12)
motif(12.0)
motif(30.2)
music *= np.clip((LENGTH - 0.8 - t) / 1.5, 0, 1)        # fade before the end static

# voices, and the music ducking under them
voice = np.zeros(n)
active = np.zeros(n)
for name, at in CUES:
    with wave.open(f'{VOICE_DIR}/{name}.wav') as w:
        v = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2') / 32768.0
    put(voice, at, v * (0.9 / max(1e-6, np.abs(v).max())))
    put(active, at - 0.1, np.ones(len(v) + int(0.2 * SR)))
duck = 1 - 0.6 * smooth(np.clip(active, 0, 1), int(0.15 * SR))
mix = voice + music * duck

# VHS static at start and end
for a, b in ((0.0, 0.8), (LENGTH - 0.8, LENGTH)):
    m = (t >= a) & (t < b)
    mix[m] = noise[m] * 0.25

# TV speaker: band-limited, slightly saturated, a little hiss
mix = mix - smooth(mix, 220)          # remove the deep bass
mix = smooth(mix, 4)                  # soften the highs
mix = np.tanh(mix * 1.6) / np.tanh(1.6)
mix += rng.standard_normal(n) * 0.004
mix *= 0.89 / np.abs(mix).max()

with wave.open(OUT, 'w') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((mix * 32767).astype('<i2').tobytes())
print(OUT, f'{LENGTH}s')
