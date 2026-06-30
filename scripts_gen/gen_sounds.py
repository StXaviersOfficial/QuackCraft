#!/usr/bin/env python3
"""
QuackCraft - Sound effects generator
Generates simple, original .wav sound effects procedurally.
"""
import os
import struct
import math
import wave
import random

random.seed(1337)

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       'assets', 'sounds')
os.makedirs(OUT_DIR, exist_ok=True)

SAMPLE_RATE = 22050  # 22kHz is enough for SFX and keeps file size small


def write_wav(filename, samples):
    """Write a list of float samples (-1..1) to a 16-bit PCM WAV file."""
    path = os.path.join(OUT_DIR, filename)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        # Convert floats to int16
        frames = bytearray()
        for s in samples:
            s = max(-1.0, min(1.0, s))
            frames.extend(struct.pack('<h', int(s * 32767)))
        w.writeframes(bytes(frames))
    print(f'  wrote {filename} ({len(samples)/SAMPLE_RATE:.2f}s)')


def envelope(t, attack=0.005, decay=0.1, sustain=0.0, release=0.1, total=0.2):
    """Simple ADSR envelope. Returns amplitude 0..1 at time t."""
    if t < attack:
        return t / attack
    elif t < attack + decay:
        return 1.0 - (1.0 - sustain) * (t - attack) / decay
    elif t < total - release:
        return sustain
    else:
        return max(0.0, sustain * (1.0 - (t - (total - release)) / release))


def gen_noise(duration, amplitude=1.0):
    return [amplitude * (random.random() * 2 - 1) for _ in range(int(duration * SAMPLE_RATE))]


def gen_tone(freq, duration, amplitude=1.0, decay=True):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        a = amplitude * (math.exp(-t * 8) if decay else 1.0)
        out.append(a * math.sin(2 * math.pi * freq * t))
    return out


def gen_sweep(f0, f1, duration, amplitude=1.0):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        ratio = t / duration
        f = f0 + (f1 - f0) * ratio
        a = amplitude * (1.0 - ratio * 0.7)
        out.append(a * math.sin(2 * math.pi * f * t))
    return out


def gen_footstep(duration=0.12, base_freq=120):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 25)
        noise = random.random() * 2 - 1
        tone = math.sin(2 * math.pi * base_freq * t)
        out.append(env * (0.4 * noise + 0.6 * tone) * 0.4)
    return out


def gen_dig(duration=0.18):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 12)
        noise = random.random() * 2 - 1
        tone = math.sin(2 * math.pi * 90 * t) + 0.5 * math.sin(2 * math.pi * 180 * t)
        out.append(env * (0.6 * noise + 0.4 * tone) * 0.5)
    return out


def gen_place(duration=0.15):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 18)
        tone = math.sin(2 * math.pi * 220 * t) + 0.4 * math.sin(2 * math.pi * 440 * t)
        out.append(env * tone * 0.4)
    return out


def gen_hurt(duration=0.25):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 6)
        tone = math.sin(2 * math.pi * 200 * t) + 0.3 * math.sin(2 * math.pi * 80 * t)
        out.append(env * tone * 0.5)
    return out


def gen_chew(duration=0.18):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 15) * (1.0 - math.exp(-t * 50))
        tone = math.sin(2 * math.pi * 100 * t) * 0.5 + random.random() * 0.5
        out.append(env * tone * 0.4)
    return out


def gen_attack(duration=0.15):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 15)
        noise = random.random() * 2 - 1
        out.append(env * (0.5 * noise + 0.5 * math.sin(2 * math.pi * 400 * t)) * 0.4)
    return out


def gen_explosion(duration=0.6):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 4)
        noise = random.random() * 2 - 1
        low = math.sin(2 * math.pi * 60 * t)
        out.append(env * (0.7 * noise + 0.5 * low) * 0.7)
    return out


def gen_pickup(duration=0.2):
    return gen_sweep(440, 880, duration, 0.4)


def gen_splash(duration=0.3):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 8)
        noise = random.random() * 2 - 1
        out.append(env * noise * 0.4)
    return out


def gen_ambient_biome(duration=2.0):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # Bird-like chirp every ~1 sec
        chirp = 0.0
        for k in range(3):
            phase = (t - k * 0.4) % 2.0
            if 0 < phase < 0.15:
                f = 1800 + 400 * math.sin(2 * math.pi * 30 * phase)
                chirp += 0.15 * math.exp(-phase * 12) * math.sin(2 * math.pi * f * phase)
        out.append(chirp)
    return out


def gen_furnace_loop(duration=0.5):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        noise = random.random() * 2 - 1
        rumble = math.sin(2 * math.pi * 80 * t) * 0.3
        out.append((noise * 0.3 + rumble) * 0.3)
    return out


def gen_door(duration=0.4):
    return gen_sweep(150, 350, duration, 0.3)


def gen_chest_open(duration=0.3):
    return gen_sweep(200, 400, duration, 0.3)


def gen_bow_draw(duration=0.3):
    return gen_sweep(80, 200, duration, 0.2)


def gen_bow_release(duration=0.15):
    n = int(duration * SAMPLE_RATE)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 15)
        noise = random.random() * 2 - 1
        sweep = math.sin(2 * math.pi * (800 - 1500 * t) * t)
        out.append(env * (0.4 * noise + 0.6 * sweep) * 0.3)
    return out


def gen_step_stone():
    return gen_footstep(0.10, 200)


def gen_step_wood():
    return gen_footstep(0.10, 160)


def gen_step_sand():
    return gen_footstep(0.10, 90)


def gen_step_snow():
    return gen_footstep(0.12, 110)


def main():
    print('Generating QuackCraft sound effects...')
    # Footsteps
    write_wav('footstep_dirt.wav', gen_footstep(0.12, 110))
    write_wav('footstep_stone.wav', gen_step_stone())
    write_wav('footstep_wood.wav', gen_step_wood())
    write_wav('footstep_sand.wav', gen_step_sand())
    write_wav('footstep_snow.wav', gen_step_snow())
    # Block interactions
    write_wav('dig.wav', gen_dig())
    write_wav('place.wav', gen_place())
    # Combat
    write_wav('hurt.wav', gen_hurt())
    write_wav('attack.wav', gen_attack())
    write_wav('explosion.wav', gen_explosion())
    # Misc
    write_wav('chew.wav', gen_chew())
    write_wav('pickup.wav', gen_pickup())
    write_wav('splash.wav', gen_splash())
    write_wav('door.wav', gen_door())
    write_wav('chest_open.wav', gen_chest_open())
    write_wav('bow_draw.wav', gen_bow_draw())
    write_wav('bow_release.wav', gen_bow_release())
    write_wav('furnace_loop.wav', gen_furnace_loop())
    # Ambient
    write_wav('ambient_plains.wav', gen_ambient_biome(2.0))
    write_wav('ambient_forest.wav', gen_ambient_biome(2.0))
    print('Done!')


if __name__ == '__main__':
    main()
