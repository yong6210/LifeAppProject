import 'dart:async';

import 'package:flutter/services.dart';

class FocusLiveActivitySnapshot {
  const FocusLiveActivitySnapshot({
    required this.sessionId,
    required this.mode,
    required this.segmentTitle,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isPaused,
    this.upNextSegment,
  });

  final String sessionId;
  final String mode;
  final String segmentTitle;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isPaused;
  final String? upNextSegment;

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'mode': mode,
        'segmentTitle': segmentTitle,
        'remainingSeconds': remainingSeconds,
        'totalSeconds': totalSeconds,
        'isPaused': isPaused,
        if (upNextSegment != null) 'upNext': upNextSegment,
      };
}

class FocusLiveActivityService {
  const FocusLiveActivityService();

  static const MethodChannel _channel = MethodChannel('life_app/focus_live_activity');

  Future<bool> supportsLiveActivities() async {
    try {
      final response = await _channel.invokeMethod<bool>('supportsLiveActivities');
      return response ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> start(FocusLiveActivitySnapshot snapshot) async {
    try {
      final response = await _channel.invokeMethod<bool>('start', snapshot.toMap());
      return response ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> update(FocusLiveActivitySnapshot snapshot) async {
    try {
      await _channel.invokeMethod<bool>('update', snapshot.toMap());
    } on PlatformException {
      // Ignore; activity may not be running.
    }
  }

  Future<void> end(String sessionId, {bool immediate = true}) async {
    try {
      await _channel.invokeMethod<bool>('end', {
        'sessionId': sessionId,
        'immediate': immediate,
      });
    } on PlatformException {
      // Ignore.
    }
  }
}
