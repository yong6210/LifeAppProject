# Audio Assets License Summary

All bundled ambience loops and noise layers were synthesized in-house for the Life App demo build. No third-party samples are included.

| Asset | Source | Notes |
| ----- | ------ | ----- |
| white_noise_loop.wav | Internal synthesis | Generated with Python script (Gaussian noise, 44.1kHz mono masters, 22.05kHz app copy) |
| pink_noise_loop.wav | Internal synthesis | Filtered noise based on Voss-McCartney approximation |
| brown_noise_loop.wav | Internal synthesis | Integrated noise with amplitude clamp |
| rain_light_loop.wav | Internal synthesis | Low-pass filtered noise with exponential droplet envelopes |
| rain_heavy_loop.wav | Internal synthesis | Layered noise with brown-noise rumble modulation |
| forest_birds_loop.wav | Internal synthesis | Brown noise bed plus procedurally generated chirp envelopes |
| ocean_waves_loop.wav | Internal synthesis | Filtered noise with multi-rate sinusoidal swell envelope |
| fireplace_cozy_loop.wav | Internal synthesis | Brown noise foundation with short decay crackle bursts |

To regenerate assets, run `python3 tool/synthesize_audio.py` to rebuild masters and `dart run tool/encode_audio.dart --format=m4a` (requires ffmpeg or afconvert) to transcode smaller app-bundled copies.
