# Staging Smoke Test – Firestore `users/{uid}` Sync Path

This procedure validates that the updated Firestore document layout using the root `users/{uid}` document correctly synchronises settings and daily summaries when run against the staging backend.

## Prerequisites
- Flutter environment set up with the staging flavor (Gradle/Xcode configs already committed).
- Staging Firebase configuration files:
  - `lib/firebase_options.dart` generated via `flutterfire configure --project <staging-project>`.
  - `android/app/google-services.json` for staging.
  - `ios/Runner/GoogleService-Info.plist` for staging.
- Test account credentials (or ability to sign in anonymously) with access to the staging project.
- Firebase CLI authenticated against the staging project (`firebase login` + `firebase use <staging-project>`).
- Optional: Firestore emulator or console access to inspect documents.

## Smoke Test Steps

### Automated Smoke Harness (optional)
- Once Firebase configs and rules are in place, you can rerun the checks with `flutter run --target tool/staging_firestore_smoke_app.dart --no-resident -d <device-id>`.
- The harness signs in anonymously, writes the expected sleep mixer settings, and posts a 1-minute sleep summary.
- After the app exits, capture the structured results via `adb logcat -d -v raw | grep SMOKE_RESULT` and archive the JSON alongside manual evidence.
- Update the run log and checklist the same way as a manual execution.

1. **Prepare the environment**
   - Run `flutter clean`.
   - Ensure the staging flavor is selected (e.g. `flutter run --flavor staging -t lib/main_staging.dart`).
   - Delete the app from the test device/simulator to clear cached local data.
2. **Launch the app**
   - Install and start the staging build.
   - Stay on the timer screen long enough for the initial anonymous sign-in and pull to complete (watch logs for `FirestoreSyncService pullInitialData` if running via `flutter run`).
3. **Trigger settings sync**
   - Navigate to the sleep mixer preset UI.
   - Select a non-default preset (e.g. "Ocean Evening").
   - Return to the timer screen; this should enqueue a settings change log entry.
4. **Trigger daily summary sync**
   - Start a short focus timer (e.g. 1 minute) and let it complete.
   - Stop the timer so the local summary is written.
5. **Force sync**
   - Keep the app in foreground for ~30 seconds to allow the sync queue to flush, or manually trigger via the debug sync button if available.
6. **Verify Firestore document**
   - In the Firestore console (staging project) or using the CLI, inspect `users/{uid}` for the signed-in user.
   - Confirm the document now contains the expected root-level fields, including `sleepMixerPresetId`, `sleepMixerVolume`, and existing smart alarm fields.
   - Inspect `users/{uid}/daily_summaries/<YYYYMMDD>` and verify the `buckets.<deviceId>` map reflects the completed timer session.
7. **Cross-device check (optional)**
   - Install the staging app on a second device/simulator, sign in with the same account, and confirm the sleep preset auto-selects based on the root document.

## Validation Criteria
- Root document at `users/{uid}` exists after the first sync.
- Sleep mixer fields persist in the root document and match the selected preset.
- Daily summary document uses the new path and includes the device bucket.
- No security rule errors appear in the Firebase console during the test.

## Recording Results
- Capture a screenshot of the Firestore document or export JSON via the console.
- Update `docs/implementation_checklist.md` line 127 to `[x]` once the staging test passes.
- Log findings (including timestamps and device IDs) in `docs/testing/runs/` (create a new entry like `2025-03-xx_firestore_smoke.md`).

## Troubleshooting
- If writes fail with `permission-denied`, confirm the updated Firestore rules referencing `users/{uid}` were deployed.
- If the document structure is incorrect, inspect app logs for sync errors and verify `FirestorePaths.settingsDoc` returns `users/$uid`.
- For repeatable automated checks, consider adding an integration test using FakeFirebase mirroring these steps before future releases.
