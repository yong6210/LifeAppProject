# Open-Source & Asset Licensing Audit

_Last updated: 2025-10-03_

## 1. Dart / Flutter Packages
| Package | License | Notes |
| --- | --- | --- |
| Flutter SDK | BSD-3-Clause | Built-in. `flutter` includes license registry automatically. |
| flutter_riverpod | MIT | No obligations beyond notice. |
| isar | MIT | Include copyright in acknowledgments. |
| firebase_* packages | Apache-2.0 | Attribution in OSS screen. |
| flutter_local_notifications | BSD-3-Clause | Covered by Flutter license page. |
| purchases_flutter (RevenueCat) | MIT | Attribution required. |
| shared_preferences | BSD-3-Clause | Included via Flutter license page. |
| file_picker, share_plus | BSD-style | Already in license registry. |
| cryptography | BSD-3-Clause | — |

> Action: rely on Flutter’s `LicenseRegistry` and expose “Open-Source Licenses” entry in app settings.

## 2. Native Dependencies
- Android / iOS Firebase SDKs: Apache-2.0, handled via Google’s amended terms.
- RevenueCat native SDKs: MIT.

## 3. Media Assets
| Asset | Source | License | Notes |
| --- | --- | --- | --- |
| White/Pink/Brown noise loops | Pixabay (placeholder) | CC0 | Verify final file URLs before launch; keep metadata in `assets/audio/README.md` (todo). |
| UI icons | Material Icons | Apache-2.0 (via Flutter) | Already bundled. |

> Action: maintain `assets/audio/README.md` with links, ensure CC0 confirmation stored in repo.

## 4. Documentation & Next Steps
1. Add in-app link to Flutter’s license viewer (implemented via `showLicensePage`).
2. Keep this document updated when adding packages/assets.
3. On release candidate, export license list (`flutter pub run flutter_oss_licenses` optional).
