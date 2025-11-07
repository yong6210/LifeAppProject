import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ShortcutDefinition {
  const ShortcutDefinition({
    required this.id,
    required this.action,
    required this.shortLabel,
    this.longLabel,
  });

  final String id;
  final String action;
  final String shortLabel;
  final String? longLabel;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'shortLabel': shortLabel,
      'longLabel': longLabel,
    };
  }
}

class ShortcutInvocation {
  ShortcutInvocation({required this.action});

  factory ShortcutInvocation.fromJson(Map<String, dynamic> json) {
    return ShortcutInvocation(action: json['action'] as String? ?? '');
  }

  final String action;
}

abstract class ShortcutAutomationService {
  Future<void> registerShortcuts(List<ShortcutDefinition> shortcuts);
  Future<void> clearShortcuts();
  Stream<ShortcutInvocation> watchInvocations();
}

class MethodChannelShortcutAutomationService
    implements ShortcutAutomationService {
  MethodChannelShortcutAutomationService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methodChannel =
           methodChannel ?? const MethodChannel('life_app/shortcuts'),
       _eventChannel =
           eventChannel ?? const EventChannel('life_app/shortcuts/events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<ShortcutInvocation>? _cachedStream;

  @override
  Future<void> clearShortcuts() {
    return _methodChannel.invokeMethod('clearShortcuts');
  }

  @override
  Future<void> registerShortcuts(List<ShortcutDefinition> shortcuts) {
    return _methodChannel.invokeMethod('registerShortcuts', {
      'shortcuts': shortcuts.map((shortcut) => shortcut.toJson()).toList(),
    });
  }

  @override
  Stream<ShortcutInvocation> watchInvocations() {
    _cachedStream ??= _eventChannel.receiveBroadcastStream().map((raw) {
      if (raw is Map) {
        return ShortcutInvocation.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
      return ShortcutInvocation(action: raw?.toString() ?? '');
    });
    return _cachedStream!;
  }
}

class MockShortcutAutomationService implements ShortcutAutomationService {
  MockShortcutAutomationService();

  final StreamController<ShortcutInvocation> _controller =
      StreamController<ShortcutInvocation>.broadcast();

  @override
  Future<void> clearShortcuts() async {}

  @override
  Future<void> registerShortcuts(List<ShortcutDefinition> shortcuts) async {}

  @override
  Stream<ShortcutInvocation> watchInvocations() => _controller.stream;

  void simulateInvocation(String action) {
    _controller.add(ShortcutInvocation(action: action));
  }
}

ShortcutAutomationService createShortcutAutomationService() {
  if (kIsWeb) {
    return MockShortcutAutomationService();
  }
  if (Platform.isIOS || Platform.isAndroid) {
    return MethodChannelShortcutAutomationService();
  }
  return MockShortcutAutomationService();
}
