# Firestore Smoke Test – Staging (`users/{uid}` path)

- **Run date:** YYYY-MM-DD
- **Tester:** Name
- **Environment:** staging
- **App build:** commit SHA / build number
- **Device(s):** e.g. Pixel 7 (Android 14), iPhone 15 (iOS 17)
- **Account / UID:** test-user@example.com / abc123

## Steps Performed
1. Clean install of staging build
2. Sleep mixer preset changed to:
3. Timer session executed:
4. Sync waiting period:

## Observations
- Root document present at `users/{uid}`: ✅ / ❌
- Sleep mixer fields (`sleepMixerPresetId`, `sleepMixerVolume`): ✅ / ❌
- Daily summary bucket (`users/{uid}/daily_summaries/<date>`): ✅ / ❌
- Cloud Functions / Crashlytics errors: ✅ / ❌ (include details if any)

## Evidence
- Firestore document screenshot: link/path
- Console export / CLI output snippet:
  ```
  firebase firestore:documents:get users/<uid>
  ```

## Notes & Follow-ups
- 

## Result
- ✅ Pass / ❌ Fail

