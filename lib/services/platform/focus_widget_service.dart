import 'package:flutter/services.dart';

class FocusWidgetSnapshot {
  const FocusWidgetSnapshot({
    required this.mode,
    required this.segmentTitle,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isPaused,
    this.upNextSegment,
  });

  final String mode;
  final String segmentTitle;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isPaused;
  final String? upNextSegment;

  Map<String, dynamic> toMap() => {
    'mode': mode,
    'segmentTitle': segmentTitle,
    'remainingSeconds': remainingSeconds,
    'totalSeconds': totalSeconds,
    'isPaused': isPaused,
    if (upNextSegment != null) 'upNext': upNextSegment,
  };
}

class FocusWidgetService {
  const FocusWidgetService();

  static const MethodChannel _channel = MethodChannel('life_app/focus_widget');

  Future<bool> supportsWidgets() async {
    try {
      final result = await _channel.invokeMethod<bool>('supports');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> update(FocusWidgetSnapshot snapshot) async {
    try {
      await _channel.invokeMethod<bool>('update', snapshot.toMap());
    } on PlatformException {
      // Ignore: widget may not be active.
    }
  }

  Future<void> clear() async {
    try {
      await _channel.invokeMethod<bool>('clear');
    } on PlatformException {
      // Ignore failures.
    }
  }
}
