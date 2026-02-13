import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:life_app/l10n/app_localizations.dart';

/// Speaks short text-to-speech prompts when workout intervals change.
class WorkoutCueService {
  WorkoutCueService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;
  Future<void>? _initializing;

  Future<void> _ensureInitialized() {
    if (_initialized) {
      return Future.value();
    }
    if (_initializing != null) {
      return _initializing!;
    }
    _initializing = () async {
      try {
        await _tts.awaitSpeakCompletion(true);
        // Provide a neutral speech configuration; platform voices adjust per locale.
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.52);
      } on MissingPluginException {
        // Tests that run without plugin bindings should silently ignore.
      } on PlatformException {
        // Ignore platform configuration failures; fall back to defaults.
      }
      _initialized = true;
      _initializing = null;
    }();
    return _initializing!;
  }

  Future<void> speakRoundStart({
    required AppLocalizations l10n,
    required int round,
    required int totalRounds,
  }) async {
    final message = l10n.tr('timer_workout_tts_round_start', {
      'round': '$round',
      'total': '$totalRounds',
    });
    await _speak(message);
  }

  Future<void> speakRest({
    required AppLocalizations l10n,
    required int seconds,
  }) async {
    final message = l10n.tr('timer_workout_tts_rest', {'seconds': '$seconds'});
    await _speak(message);
  }

  Future<void> speakComplete({required AppLocalizations l10n}) async {
    await _speak(l10n.tr('timer_workout_tts_complete'));
  }

  Future<void> speakNavigatorCue(String message) async {
    await _speak(message);
  }

  Future<void> speakGuidedStepStart({
    required AppLocalizations l10n,
    required int step,
    required int totalSteps,
    required String mode,
    required int minutes,
  }) async {
    await _speak(
      l10n.tr('guided_session_voice_step_start', {
        'step': '$step',
        'total': '$totalSteps',
        'mode': mode,
        'minutes': '$minutes',
      }),
    );
  }

  Future<void> speakGuidedComplete({required AppLocalizations l10n}) async {
    await _speak(l10n.tr('guided_session_voice_complete'));
  }

  Future<void> _speak(String message) async {
    if (message.trim().isEmpty) return;
    await _ensureInitialized();
    try {
      await _tts.stop();
      await _tts.speak(message);
    } on MissingPluginException {
      // Ignore when TTS plugin is unavailable (e.g., unit tests).
    } on PlatformException {
      // Ignore runtime TTS failures so timers continue uninterrupted.
    }
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } on MissingPluginException {
      // no-op
    } on PlatformException {
      // no-op
    }
  }
}
