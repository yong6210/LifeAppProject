# Project TODO

This file captures upcoming work items and open tasks for the project.
Source: README.md "Roadmap & Open Work" and current build/test context.

## Release Readiness
- [x] Set up code signing for macOS and iOS builds
- [x] Define flavor builds (dev/staging/prod) and verify configuration
- [x] Expand CI to run `flutter analyze`, `flutter test`, and platform builds

## Product Features
- [ ] Guided sessions experience
- [ ] AI recommendations (scope and data pipeline)
- [ ] Home screen widgets (behavior, data, and refresh policy)

## Community Challenges
- [ ] User profile integration (beyond `ownerId` stubs)
- [ ] Premium rewards for challenges

## Privacy & Policy
- [x] Document sleep sound analysis data handling and privacy policy

## Design Review
- [x] UI review notes captured for all screens

## Design Follow-ups
- [x] Align typography, card elevation, and icon style across Home/Timer/Workout/Sleep tabs
- [x] Define a default background treatment and reserve gradients for hero surfaces
- [x] Standardize primary CTA placement per screen (top-right, bottom CTA, or FAB)
- [x] Localize remaining hard-coded strings (ensure consistent casing)
- [x] Add a clearer “Next action” tile on Home and a stronger anchor for the current workout step

## Build/Run Health
- [x] Ensure macOS Firebase options are configured (FlutterFire for macOS)
- [x] Re-run macOS app launch after Firebase configuration

## Verification Checklist (when shipping)
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `flutter run -d macos`
