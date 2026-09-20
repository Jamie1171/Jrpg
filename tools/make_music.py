"""Generate the prototype's original, quiet village theme. Python standard library only."""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
BEAT = 0.625
LENGTH = BEAT * 64
data = [0.0] * int(RATE * LENGTH)

def note(midi, start, length, volume, pluck=True):
    frequency = 440 * 2 ** ((midi - 69) / 12)
    for i in range(int(length * RATE)):
        t = i / RATE
        attack = min(1, t / 0.016)
        release = min(1, max(0, (length - t) / 0.15))
        decay = math.exp(-t * (3 if pluck else 0.7))
        signal = math.sin(2 * math.pi * frequency * t)
        signal += 0.22 * math.sin(2 * math.pi * frequency * 2 * t)
        index = int(start * RATE) + i
        if index < len(data):
            data[index] += signal * attack * release * decay * volume

chords = [(48, 55, 60, 64), (45, 52, 57, 60), (41, 48, 53, 57), (43, 50, 55, 59)]
melodies = [
    [72, 76, 79, 76, 74, 72, 67, 69],
    [72, 76, 81, 79, 76, 74, 72, 69],
    [69, 72, 77, 76, 72, 69, 67, 65],
    [67, 71, 74, 79, 76, 74, 71, 72],
]
for bar in range(8):
    chord = chords[bar % 4]
    note(chord[0], bar * 8 * BEAT, 4 * BEAT, 0.10, False)
    for step in range(8):
        note(chord[1 + step % 3], (bar * 8 + step) * BEAT, 1.8, 0.07)
        if step in [0, 1, 3, 4, 6, 7]:
            note(melodies[bar % 4][step], (bar * 8 + step) * BEAT + 0.018, 1.5, 0.105)

path = Path(__file__).resolve().parents[1] / "game/assets/audio/brackenford.wav"
path.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(path), "wb") as out:
    out.setnchannels(1)
    out.setsampwidth(2)
    out.setframerate(RATE)
    out.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, sample)) * 28000)) for sample in data))
import subprocess
subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(path), "-c:a", "libvorbis", "-q:a", "4", str(path.with_suffix(".ogg"))], check=True)
path.unlink()
print(path.with_suffix(".ogg"))
