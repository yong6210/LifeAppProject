# Changelog

All notable changes to the Life App project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- iOS-style time picker for Sleep and Focus modes
  - CupertinoPicker with looping support for continuous scrolling
  - 12-hour format with AM/PM selection positioned on the left
  - Dual mode: duration-based (0-24 hours) or target time selection
  - Automatic hour adjustment when scrolling through minute boundaries (59→0, 0→59)
  - AM/PM auto-toggle when crossing 11h↔12h boundary in both directions
  - Tap-to-edit functionality for direct time input via dialog
  - Proper 12-hour to 24-hour conversion handling (12 AM = 0h, 12 PM = 12h)
- Background sound selection modal for sleep mode
  - Modal bottom sheet with list of sound presets
  - Currently selected sound displayed on selection button
- Minute-based time calculation for remaining time display
  - Excludes seconds to prevent "23h 59m" display when setting current time as target
  - Shows "0분 남음" instead of "24시간 0분 남음" for same-time targets

### Changed
- Sleep page time picker redesigned with iOS native feel
- Focus/Timer page time picker updated to match Sleep page UX
- Time remaining calculation now rounds to nearest minute for accuracy

### Technical Details
- Implemented `FixedExtentScrollController` for precise picker control
- Added state synchronization between hour, minute, and AM/PM pickers
- Handles edge cases: looping boundaries, AM/PM transitions, 12-hour conversion
- Files modified:
  - `lib/features/sleep/figma_sleep_tab.dart`
  - `lib/features/timer/figma_timer_tab.dart`
