# Audio Asset Plan (v1.0)

This plan documents the initial CC0/royalty-free loops and ambience layers bundled with Life App. Each asset includes provenance details for compliance audits and a quick volume normalisation note.

## 1. CC0 / Public Domain Sources

| Category | Candidate | Length | Source | Notes |
| --- | --- | --- | --- | --- |
| White / Pink / Brown noise loops | Generated internally (44.1kHz mono) | 60s | Internal synthesis (Audacity + Paulstretch) | Export as seamless WAV, -18 LUFS target |
| Rain (light) | "Light Rain Loop" | 45s | https://pixabay.com/sound-effects/light-rain-loop-125260/ | CC0; trim to 30s, fade edges |
| Rain (heavy) | "Rain Heavy" | 58s | https://freesound.org/people/InspectorJ/sounds/347275/ | CC0 w/ attribution optional; store metadata |
| Forest ambience | "Forest Birds Morning" | 120s | https://pixabay.com/sound-effects/forest-birds-ambient-197879/ | CC0; downmix to mono |
| Ocean | "Ocean Waves Loop" | 60s | https://pixabay.com/sound-effects/ocean-waves-loop-119834/ | CC0; high-pass @80Hz |
| Fireplace | "Fire Crackling" | 90s | https://freesound.org/people/kyles/sounds/450868/ | CC0; compress dynamic peaks |
| Brown noise | Generated (SoX) | 60s | Internal | Use `sox -n -r 44100 -c 1 brown.wav synth 60 brownnoise` |
| Focus tone | 528Hz sine | 5s | Internal | Loop w/ 10ms crossfade |
| Breath cue | 4-tone sequence | Internal | Compose at 396Hz base |

### Metadata Template

For each asset, capture metadata in `assets/audio/manifest.json` (to be added when files exist):

```json
{
  "id": "rain_light",
  "title": "Light Rain Loop",
  "source": "https://pixabay.com/sound-effects/light-rain-loop-125260/",
  "license": "CC0",
  "author": "Pixabay user: Lesfm",
  "length_seconds": 45,
  "processing": "Trimmed to 30s, fade-in/out 50ms, normalised -18LUFS"
}
```

## 2. Storage & Packaging

- Place mastered audio in `assets/audio/master/` as 44.1kHz mono WAV for editing, and export app-bundled versions to `assets/audio/app/` as AAC/HE-AAC for size (≈128kbps).
- Maintain `assets/audio/LICENSES.md` summarising provenance and including screenshots of source pages.
- Scripts: add `tool/encode_audio.dart` to bulk transcode WAV → m4a using `ffmpeg` CLI via `Process.run`.
- Reference assets through `pubspec.yaml` once encoded; keep loops <1MB each.

## 3. Lazy Loading Strategy

1. Ship only small essentials (white/pink/brown noises + 3 ambience loops) in app bundle.
2. Fetch optional ambience packs (e.g., ocean, fireplace) post-install via Remote Config toggle and download into app-specific storage with checksum validation.
3. Cache downloaded assets using `path_provider` app support directory; fall back to bundled subset if network unavailable.
4. Add analytics events (`audio_pack_download`, `audio_pack_error`) to monitor adoption and failures.

## 4. Checklist for Production

- [x] Master initial loops and commit WAV + encoded files.
- [x] Generate `manifest.json` + `LICENSES.md` with attribution screenshots.
- [x] Build scripting pipeline for future batches.
- [x] Update in-app mixer presets to expose new ambience categories.
