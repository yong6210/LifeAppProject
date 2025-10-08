# Localization Plan & Process

_Last updated: 2025-10-03_

## 1. Infrastructure
- `lib/l10n/intl_en.arb` is the fallback locale with full key coverage.
- `lib/l10n/intl_ko.arb` provides Korean copy matching the current UI.
- `lib/l10n/app_localizations.dart` loads ARB assets at runtime and merges locale maps over the English fallback.
- Loader now resolves locale hierarchies (language → script → country) so future files such as `intl_en_GB.arb` or `intl_zh_Hant_TW.arb` merge automatically with their parents.
- `pubspec.yaml` bundles the `lib/l10n/` directory as assets and enables `flutter_localizations`.

## 2. Workflow
1. Add new strings to `intl_en.arb` first with descriptive keys.
2. Provide translations in `intl_ko.arb` (and future locales) during the same change.
3. Reference strings via `context.l10n.tr('key')` with placeholders as needed.
4. Submit copy changes for review in Notion → “Localization queue” before shipping.
5. After approving translations, run `flutter gen-l10n` in CI (planned) or load-time validation warns on missing keys.


## 4. Coverage Snapshot (Oct 2025)
- Timer, Account, Paywall screens localized in EN/KR including smart alarm editor and subscription copy.
- Stats cards and home session list use shared duration helpers to keep wording consistent.
- Remaining: onboarding slides + toast strings (track in localization backlog).
## 3. Fallback / Error Handling
- Missing keys resolve to the fallback (English) string to avoid runtime crashes.
- Placeholders use `{name}` syntax; the helper replaces them using `Map<String, String>` parameters.
- Logging reports missing ARB files in debug builds via assertion.

## 4. Future Locales
- Add new ARB files (e.g., `intl_ja.arb`) and update `supportedLocales` in `AppLocalizations`.
- Provide QA checklist for each locale (layout, glyph coverage, truncated text).

## 5. Testing
- Smoke test by changing device language to ensure Korean/English switch at runtime.
- Add widget tests that verify localized strings render for known keys (todo).

_Next steps:_ expand translation coverage across remaining screens, introduce telemetry consent toggle strings, and wire `flutter gen-l10n` into CI once sandbox permissions allow running Flutter commands.

## 6. Testing Coverage
- Widget test `test/l10n/app_localizations_test.dart` ensures fallback and Korean overlays load.
- Manual smoke: switch device language to KO/EN, review Timer, Account, Paywall screens for layout & strings.
- Next: add integration test verifying paywall copy once store fixtures available.

## 7. RTL Readiness Audit (Feb 2025)
- Reviewed primary surfaces (Home, Timer, Account, Paywall, Backup) for directional assumptions. Replaced `Alignment.centerLeft` usages with `AlignmentDirectional.centerStart` so cards respect locale direction. Other paddings are symmetric, requiring no change.
- Confirmed UI builds rely on `Wrap`, `Column`, and `ListTile` which honour ambient `Directionality`. Benefit rows now use `ListBody` to maintain reading order in RTL.
- Verified localization helper gracefully falls back to English for unsupported locales; plan is to temporarily register `Locale('ar')` in debug builds for QA sessions.
- Next manual step: run an RTL device/emulator pass (Arabic/Hebrew) and capture notes in `docs/testing/runs/` once hardware access is available.
