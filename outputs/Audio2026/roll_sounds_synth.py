# Roll sounds generator (Claude, 2026-10-01). Run: python roll_sounds_synth.py (needs numpy + scipy).
# Writes RollTick.wav (46 ms soft 'tok' per reel item) and RollLand.wav (0.62 s two-note chime when the reel stops).
# Fixed seed -> identical output every run. Convert for Roblox: ffmpeg -i RollTick.wav -c:a libvorbis -q:a 6 RollTick.ogg
import numpy as np
from scipy.signal import butter, sosfilt
from scipy.io import wavfile
SR = 44100
rng = np.random.default_rng(20261001)

def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], btype="band", fs=SR, output="sos"), x)
def hp(x, f, order=2):
    return sosfilt(butter(order, f, btype="high", fs=SR, output="sos"), x)
def lp(x, f, order=2):
    return sosfilt(butter(order, f, btype="low", fs=SR, output="sos"), x)
def fade(x, ms_in=0.3, ms_out=3.0):
    n_in, n_out = int(SR * ms_in / 1000), int(SR * ms_out / 1000)
    x = x.copy()
    if n_in > 0: x[:n_in] *= np.linspace(0, 1, n_in) ** 2
    if n_out > 0: x[-n_out:] *= np.linspace(1, 0, n_out) ** 2
    return x
def normalize(x, peak_db):
    return x / np.max(np.abs(x)) * (10 ** (peak_db / 20))

# ---------- TICK: soft plastic "tok" (prize-wheel flapper on a peg) ----------
def tick(dur=0.046):
    n = int(SR * dur); t = np.arange(n) / SR
    # pitch-gliding body (1650 -> 1380 Hz), rounded decay
    f0 = 1380 + 270 * np.exp(-t / 0.006)
    body = np.sin(2 * np.pi * np.cumsum(f0) / SR) * np.exp(-t / 0.0075)
    # bright upper partial, decays fast
    bright = 0.35 * np.sin(2 * np.pi * 3150 * t + 0.7) * np.exp(-t / 0.0028)
    # low thump for roundness
    thump = 0.55 * np.sin(2 * np.pi * 360 * t) * np.exp(-t / 0.0065)
    # tiny noise transient = the "click"
    noise = rng.standard_normal(n) * np.exp(-t / 0.0007)
    click = 0.6 * bp(noise, 2200, 6500)
    x = body + bright + thump + click
    x = np.tanh(1.6 * x) / np.tanh(1.6)          # gentle warmth
    x = lp(hp(x, 140), 8500)                      # no rumble, no fizz
    return normalize(fade(x, 0.25, 4.0), -3.0)

# ---------- LAND: bright two-note bell chime + sparkle ----------
def bell(freq, dur, start, amp, tau):
    n = int(SR * dur); t = np.arange(n) / SR
    out = np.zeros(n)
    tt = t - start; m = tt >= 0; tt = tt[m]
    partials = [(1.0, 1.0, 1.0), (2.0, 0.35, 0.55), (2.76, 0.22, 0.35), (5.4, 0.07, 0.2)]
    for ratio, a, tscale in partials:
        out[m] += a * np.sin(2 * np.pi * freq * ratio * tt) * np.exp(-tt / (tau * tscale))
    out[m] *= 1 - np.exp(-tt / 0.0015)           # 1.5 ms soft attack
    return amp * out
def land(dur=0.62):
    n = int(SR * dur); t = np.arange(n) / SR
    x = bell(1318.5, dur, 0.0, 0.85, 0.16) + bell(1975.5, dur, 0.045, 0.7, 0.2)   # E6 then B6
    sparkle = rng.standard_normal(n) * np.exp(-np.maximum(t - 0.045, 0) / 0.05) * (t >= 0.045)
    x += 0.10 * bp(sparkle, 6000, 11000)
    pop = 0.4 * np.sin(2 * np.pi * 520 * t) * np.exp(-t / 0.012)                  # soft "pop" under it
    x += pop
    x = np.tanh(1.2 * x) / np.tanh(1.2)
    x = hp(x, 120)
    return normalize(fade(x, 0.3, 40.0), -3.0)

for name, sig in (("RollTick", tick()), ("RollLand", land())):
    wavfile.write(f"{name}.wav", SR, (sig * 32767).astype(np.int16))
    spec = np.abs(np.fft.rfft(sig)); freqs = np.fft.rfftfreq(len(sig), 1 / SR)
    centroid = float((spec * freqs).sum() / spec.sum())
    print(f"{name}: {len(sig)/SR*1000:.0f} ms | peak {20*np.log10(np.max(np.abs(sig))):.1f} dBFS | RMS {20*np.log10(np.sqrt(np.mean(sig**2))):.1f} dBFS | spectral centroid {centroid:.0f} Hz | starts at sample {int(np.argmax(np.abs(sig) > 0.05))}")
