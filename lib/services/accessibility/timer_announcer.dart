import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/timer/timer_state.dart';
import 'package:life_app/l10n/app_localizations.dart';

final timerAnnouncerProvider = Provider<TimerAnnouncer>((ref) {
  return TimerAnnouncer();
});

class TimerAnnouncer {
  TimerAnnouncer({
    this.minInterval = const Duration(seconds: 30),
    Future<void> Function(FlutterView, String, TextDirection)? sendAnnouncement,
  }) : _sendAnnouncement =
            sendAnnouncement ?? SemanticsService.sendAnnouncement;

  final Duration minInterval;
  final Future<void> Function(FlutterView, String, TextDirection)
      _sendAnnouncement;
  DateTime? _lastAnnouncedAt;
  String? _lastSegmentId;

  void maybeAnnounce({
    required BuildContext context,
    required TimerState state,
    required AppLocalizations l10n,
  }) {
    if (!state.isRunning) {
      return;
    }
    final features =
        SchedulerBinding.instance.platformDispatcher.accessibilityFeatures;
    final spokenFeedback =
        features.accessibleNavigation || features.disableAnimations;
    if (!spokenFeedback) {
      return;
    }

    final now = DateTime.now();
    final segmentId = state.currentSegment.id;
    final elapsed = _lastAnnouncedAt == null
        ? minInterval
        : now.difference(_lastAnnouncedAt!);
    final shouldAnnounceSegment = _lastSegmentId != segmentId;
    if (!shouldAnnounceSegment && elapsed < minInterval) {
      return;
    }

    final minutes = state.segmentRemainingSeconds ~/ 60;
    final seconds = state.segmentRemainingSeconds % 60;
    final segmentLabel = state.currentSegment.labelFor(l10n);
    final timeLabel = minutes > 0
        ? l10n.tr('timer_announcer_minutes_seconds', {
            'minutes': '$minutes',
            'seconds': seconds.toString().padLeft(2, '0'),
          })
        : l10n.tr('timer_announcer_seconds_only', {'seconds': '$seconds'});

    final message = l10n.tr('timer_announcer_segment', {
      'segment': segmentLabel,
      'time': timeLabel,
    });
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final view = View.of(context);
    unawaited(_sendAnnouncement(view, message, textDirection));
    _lastAnnouncedAt = now;
    _lastSegmentId = segmentId;
  }

  void reset() {
    _lastAnnouncedAt = null;
    _lastSegmentId = null;
  }
}
