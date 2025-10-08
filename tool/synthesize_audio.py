import math
import os
import random
import wave

OUTPUTS = [
    "white_noise_loop",
    "pink_noise_loop",
    "brown_noise_loop",
    "rain_light_loop",
    "rain_heavy_loop",
    "forest_birds_loop",
    "ocean_waves_loop",
    "fireplace_cozy_loop",
]

DURATION = 8  # seconds
MASTER_RATE = 44100
APP_RATE = 22050

random.seed(42)


def clamp(value: float, minimum: float = -1.0, maximum: float = 1.0) -> float:
    return max(minimum, min(maximum, value))


def write_wave(path: str, samples, sample_rate: int) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as wf:
      wf.setnchannels(1)
      wf.setsampwidth(2)
      wf.setframerate(sample_rate)
      frames = bytearray()
      for sample in samples:
          value = int(clamp(sample) * 32767)
          frames += value.to_bytes(2, byteorder="little", signed=True)
      wf.writeframes(frames)


def generate_white_noise(length: int) -> list[float]:
    return [random.uniform(-0.6, 0.6) for _ in range(length)]


def generate_pink_noise(length: int) -> list[float]:
    state = 0.0
    samples = []
    for _ in range(length):
        white = random.uniform(-1.0, 1.0)
        state = 0.94 * state + 0.06 * white
        samples.append((state + white) * 0.45)
    return samples


def generate_brown_noise(length: int) -> list[float]:
    state = 0.0
    samples = []
    for _ in range(length):
        white = random.uniform(-1.0, 1.0)
        state = clamp(state + white * 0.02)
        samples.append(state * 0.6)
    return samples


def low_pass_filter(samples, alpha: float) -> list[float]:
    filtered = []
    prev = 0.0
    for sample in samples:
        prev = alpha * sample + (1 - alpha) * prev
        filtered.append(prev)
    return filtered


def generate_rain_light(length: int) -> list[float]:
    base = low_pass_filter(generate_white_noise(length), 0.3)
    drops = [0.0] * length
    for _ in range(length // 700):
        pos = random.randrange(length)
        decay = random.randint(200, 600)
        amplitude = random.uniform(0.2, 0.4)
        for i in range(decay):
            idx = pos + i
            if idx >= length:
                break
            drops[idx] += amplitude * math.exp(-i / (decay / 6))
    return [clamp(b * 0.7 + d * 0.5) for b, d in zip(base, drops)]


def generate_rain_heavy(length: int) -> list[float]:
    base = low_pass_filter(generate_white_noise(length), 0.6)
    rumble = generate_brown_noise(length)
    heavy = []
    for i in range(length):
        mod = 0.2 * math.sin(2 * math.pi * i / (MASTER_RATE * 0.7))
        heavy.append(clamp(base[i] * 0.8 + rumble[i] * 0.5 + mod))
    return heavy


def generate_forest_birds(length: int) -> list[float]:
    ambience = generate_brown_noise(length)
    samples = ambience[:]
    i = 0
    while i < length:
        if random.random() < 0.002:
            chirp_len = random.randint(800, 2000)
            freq = random.uniform(1200, 2400)
            for j in range(chirp_len):
                idx = i + j
                if idx >= length:
                    break
                env = math.exp(-j / (chirp_len / 4))
                samples[idx] += 0.25 * env * math.sin(2 * math.pi * freq * j / MASTER_RATE)
        i += 1
    return [clamp(s) for s in samples]


def generate_ocean_waves(length: int) -> list[float]:
    white = generate_white_noise(length)
    envelope = []
    for i in range(length):
        slow = (math.sin(2 * math.pi * i / (MASTER_RATE * 5)) + 1) / 2
        swell = (math.sin(2 * math.pi * i / (MASTER_RATE * 12)) + 1) / 2
        envelope.append(0.5 * slow + 0.5 * swell)
    filtered = low_pass_filter(white, 0.5)
    return [clamp(filtered[i] * 0.6 * envelope[i]) for i in range(length)]


def generate_fireplace_cozy(length: int) -> list[float]:
    base = generate_brown_noise(length)
    crackles = [0.0] * length
    for _ in range(length // 400):
        pos = random.randrange(length)
        burst = random.randint(100, 400)
        amp = random.uniform(0.3, 0.6)
        pitch = random.uniform(2000, 4000)
        for j in range(burst):
            idx = pos + j
            if idx >= length:
                break
            env = math.exp(-j / (burst / 5))
            crackles[idx] += amp * env * math.sin(2 * math.pi * pitch * j / MASTER_RATE)
    combined = []
    for b, c in zip(base, crackles):
        combined.append(clamp(b * 0.5 + c * 0.5))
    return combined


GENERATORS = {
    "white_noise_loop": generate_white_noise,
    "pink_noise_loop": generate_pink_noise,
    "brown_noise_loop": generate_brown_noise,
    "rain_light_loop": generate_rain_light,
    "rain_heavy_loop": generate_rain_heavy,
    "forest_birds_loop": generate_forest_birds,
    "ocean_waves_loop": generate_ocean_waves,
    "fireplace_cozy_loop": generate_fireplace_cozy,
}


def downsample(samples, factor: int) -> list[float]:
    if factor <= 1:
        return samples
    return [samples[i] for i in range(0, len(samples), factor)]


def main():
    length = DURATION * MASTER_RATE
    master_root = "assets/audio/master"
    app_root = "assets/audio/app"
    os.makedirs(master_root, exist_ok=True)
    os.makedirs(app_root, exist_ok=True)

    for name, generator in GENERATORS.items():
        samples = generator(length)
        master_path = os.path.join(master_root, f"{name}.wav")
        app_path = os.path.join(app_root, f"{name}.wav")
        write_wave(master_path, samples, MASTER_RATE)
        write_wave(app_path, downsample(samples, MASTER_RATE // APP_RATE), APP_RATE)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
