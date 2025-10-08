# Sleep Sound Analysis PoC Plan

This document lays out the practical steps for Checklist **18. Sleep Sound Analysis PoC**.

## 1. Objectives
- Validate feasibility of on-device sleep sound analysis without relying on EEG hardware.
- Determine DSP/ML pipeline that balances accuracy, battery consumption, and privacy.
- Produce documentation required for privacy review and store submissions.

## 2. Scope & Deliverables

### Helpful classes
- `lib/services/audio/sleep_sound_recorder.dart`: handles microphone permissions, recording and amplitude polling.
- `lib/services/audio/sleep_sound_analyzer.dart`: aggregates amplitude samples into a summary (average/max loudness, estimated loud events, restful ratio, recording path).

1. **Recording Pipeline**
   - Design permission prompts for iOS/Android (foreground + background recording constraints).
   - Choose recording library (`flutter_sound`, `audio_session` + platform channels) and prototype saving PCM/WAV snippets.
   - Specify storage locations (temporary cache + optional upload) and retention policy.
2. **Signal Processing / ML Evaluation**
   - Compare FFT-based heuristic detection vs lightweight ML models (TensorFlow Lite, EdgeImpulse).
   - Collect anonymized sample audio (with consent) to benchmark detection accuracy and CPU usage.
3. **Event Detection MVP**
   - Implement prototype that logs snore/noise events and aggregates decibel levels over time.
   - Build quick UI visualizations (line chart, heat map) for QA review.
4. **Privacy & Battery Policy Draft**
   - Draft data retention schedule, consent/opt-out flows, battery impact mitigation plan.
   - Update `privacy_policy_draft.md` with new data usage clauses.
5. **Optional: Wearable Complement**
   - If combined with wearable data (HealthKit/Google Fit), document how audio events will be correlated with sleep stage summaries.

## 3. Execution Checklist
- [x] Permission flow wireframes/spec completed (including background mode explanation).
- [x] Recording prototype saves short clips and metadata locally.
- [x] DSP/ML option chosen with documented trade-offs (accuracy, CPU, storage).
- [x] MVP UI preview ready for internal testing (noise timeline + summary card).
- [x] Privacy & battery documentation reviewed with compliance notes.
- [x] Decision on wearable correlation documented (even if postponed).

## 4. Timeline & Roles (suggested)
| Phase | Owner | Est. Duration |
|-------|-------|---------------|
| Planning & permissions design | PM/UX | 3–4 days |
| Recording + signal PoC | Mobile eng. | 1–2 weeks |
| Model evaluation & tuning | ML/DSP eng. | 1–2 weeks (in parallel) |
| Privacy/battery policy draft | PM/Legal | 2–3 days |
| Internal demo & decision | Stakeholders | 2 days |

## 5. Risks & Mitigations
- **Battery drain**: adopt low sample rates, record only during sleep mode, provide manual opt-out.
- **Privacy concerns**: only store on-device unless user uploads; encrypt caches; clear data after retention window.
- **Accuracy limits**: clearly communicate feature is “sound-based estimation,” not medical-grade diagnosis.

Once the PoC is approved, a separate specification should be created for production implementation.

## 6. Permission & Recording Flow (Detailed)
### iOS (iOS 15+)
- Request `AVAudioSession` record permission up front with localized justification (sleep analysis only when user opts into Sleep mode).
- Activate session with category `playAndRecord`, mode `.videoRecording`, options `.allowBluetooth`, `.mixWithOthers` to keep white-noise playback alive.
- Enable Background Modes ▸ Audio in Xcode; display an in-app sheet explaining that Sleep mode keeps the microphone active and how to stop it.
- While recording, show a persistent “녹음 중” smart-banner with quick stop button. If the user leaves Sleep mode, call `SleepSoundAnalyzer.stop()` immediately and tear down the session.
- All files are written to `Library/Application Support/SleepSounds/<date>/` and trimmed to `.m4a` segments (one per session). Retention window defaults to 3 days (configurable).

### Android (API 26+)
- Request `RECORD_AUDIO` + `FOREGROUND_SERVICE` (Android 14 uses `FOREGROUND_SERVICE_MICROPHONE`). Use `PermissionHandler` but fall back to manual intents when denied permanently.
- Launch a dedicated foreground service with channel “수면 소리 분석” and ongoing notification (“Sleep mode active – tap to stop”).
- Respect Doze: recording stops automatically if the device remains on battery below 15% unless the user overrides in settings.
- Audio files live under `context.cacheDir/sleep_sounds/<date>/`. When retention window elapses, a maintenance task clears the folder.

### Storage & Retention
- Each session produces 1 `.m4a` clip + `sleep_summary.json` serialized from `SleepSoundSummary`.
- Default retention: 3 days or until the user confirms upload to cloud backup.
- Manual purge button sits in Settings ▸ 데이터 관리 ▸ 수면 사운드 기록.

## 7. DSP / ML Option Evaluation
| Candidate | Pros | Cons | Decision |
|-----------|------|------|----------|
| **FFT + heuristics (현재 구현)** | 0 dependency, minimal CPU, works offline | Limited classification (no snore vs cough), sensitive to thresholds | ✅ 유지 (PoC 단계)
| Lightweight TF Lite model (~150KB) | Detect specific patterns (snore, cough, ambient) | Requires labeled dataset, more CPU (~7–9% on A15) | 추후 데이터 확보 후 재평가
| EdgeImpulse on-device classifier | Cloud pipeline, auto data augmentation | Vendor lock-in, monthly cost, still needs labeled audio | 보류 (PoC 범위 밖)

결론: PoC 단계에서는 FFT 기반 이벤트 탐지를 유지하되, 실사용 로그가 쌓이면 TF Lite 모델 학습을 검토한다.

## 8. Event Detection MVP Implementation
- `SleepSoundAnalyzer`가 연속적인 큰소리를 `SleepNoiseEvent` 리스트로 저장하도록 확장. 각 이벤트에는 시작 오프셋, 지속 시간, 샘플 수, 최대 음량이 포함된다.
- `SleepSoundSummary` 및 영속 스토어(`SleepSoundSummaryStore`)가 이벤트 리스트를 JSON으로 직렬화/역직렬화한다.
- 홈 대시보드 ▸ “수면 요약” 카드가 마지막 세션의 소음 이벤트를 3개까지 표시하고, 자세한 요약은 ‘수면 기록 백업’ 화면에서 열람.
- UI는 `SleepSection` 내부에 카드로 배치해 QA가 즉시 확인 가능.

## 9. Privacy & Battery Policy Draft (요약)
- **데이터 범위**: 마이크 원본은 로컬 캐시에만 저장, 기본 retention 3일. 사용자가 “클라우드 백업”을 켠 경우에만 Firebase Storage로 업로드.
- **옵트인/옵트아웃**: Sleep 모드 최초 실행 시 “소리 기반 분석” 동의 팝업, 언제든 설정에서 기능 끌 수 있음. 백업/업로드 로그는 `Settings` 탭에서 열람.
- **암호화**: iOS에서 `NSFileProtectionCompleteUntilFirstUserAuthentication`, Android는 `MODE_PRIVATE` + 앱 암호화 키로 AES-256 적용.
- **배터리**: 충전 중 Sleep 모드를 권장, 배터리 15% 미만일 때 자동 종료. Foreground notification에 배터리 영향 문구 포함.
- **법적 고지**: 개인정보 처리방침 초안 `privacy_policy_draft.md`에 오디오 데이터 섹션 추가 완료.

## 10. Wearable Correlation Notes
- HealthKit: `HKCategoryTypeIdentifier.sleepAnalysis`, `HKQuantityTypeIdentifier.heartRate`, `HKQuantityTypeIdentifier.heartRateVariabilitySDNN`를 30분 간격으로 동기화.
- Google Fit: `Sessions` API로 sleep segments, `DataType.TYPE_HEART_RATE_BPM`, `TYPE_HEART_RATE_VARIABILITY` 추출.
- 오디오 이벤트와 웨어러블 데이터를 동일 UTC 타임라인으로 병합 → 홈 대시보드의 “수면 요약” 카드에서 “코골이 이벤트 이후 HRV 하락” 같은 문장을 노출.
- 앤드투엔드 구현은 Wearable Integration(체크리스트 21)과 병행 예정, PoC 단계에서는 동기화 API 호출 플로우만 문서화.

### Example usage snippet
```dart
final analyzer = SleepSoundAnalyzer();

Future<void> runSession() async {
  final started = await analyzer.start();
  if (!started) return;

  // Optional: listen to raw amplitudes via sleepSoundRecorder.amplitudeStream.
  final sub = sleepSoundRecorder.amplitudeStream.listen((amp) {
    debugPrint('current amplitude: \${amp.toStringAsFixed(3)}');
  });

  await Future.delayed(const Duration(minutes: 5));

  final summary = await analyzer.stop();
  await sub.cancel();

  debugPrint('Loud events: \${summary.loudEventCount}');
  debugPrint('Restful ratio: \${(summary.restfulSampleRatio * 100).toStringAsFixed(1)}%');
}
```

## 11. Immediate Next Actions
1. [x] **Permissions UX polish** (UX): finalize copy/screens for microphone + background usage, sync localization strings (`lib/l10n/intl_en.arb`, `intl_ko.arb`).
2. [x] **Android foreground service PoC** (Mobile): implement the notification + lifecycle stop logic guarded by a feature flag (`sleep_sound_enabled`).
3. [ ] **Amplitude labeling session** (QA): record 30 minutes of controlled snore/ambient samples to feed into threshold tuning spreadsheet (`docs/features/sleep_sound_analysis_samples.xlsx`).
4. [ ] **Privacy policy update** (PM/Legal): merge the drafted audio-data section into `privacy_policy_draft.md` and schedule stakeholder review.
5. [ ] **Wearable sync spike** (Mobile/Backend): produce API sketch for merging HealthKit/Google Fit data (even if execution is deferred) so roadmap estimates remain accurate.
