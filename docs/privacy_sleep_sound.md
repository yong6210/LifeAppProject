# Sleep Sound Analysis Privacy Notes

This document describes how the app records and analyzes sleep sounds.

## What Data Is Collected
- Microphone audio while a sleep sound session is active.
- Derived metrics: average amplitude, max amplitude, loud event counts, and a
  simple "restful" score.
- Session timing metadata (start/end, duration).

## Where Processing Happens
- Audio processing and scoring are performed on-device in
  `lib/services/audio/sleep_sound_analyzer.dart`.
- No server-side analysis is required for the current implementation.

## Where Data Is Stored
- The raw recording is saved locally:
  - iOS: application documents directory
  - Other platforms: temporary directory
- The latest summary is stored in
  `sleep_summaries/latest_summary.json` via
  `lib/services/audio/sleep_sound_store.dart`.

## Data Sharing
- The app does not upload sleep sound recordings or summary metrics by default.
- If cloud sync is enabled in the future, this document must be updated.

## Retention & Deletion
- Only the latest summary is persisted.
- Users can delete local data by clearing app data or deleting the recording.
- Add a UI affordance if explicit deletion is required for policy compliance.

## Permissions
- Microphone permission is requested only when starting a sleep sound session.
- The feature does not run in the background unless the user starts it.

## Open Policy Items
- [ ] Confirm whether recordings should be retained or deleted after analysis
- [ ] Add an in-app disclosure explaining on-device processing
- [ ] Update the public privacy policy to include this feature
