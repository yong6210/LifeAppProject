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
        return ShortcutInvocation.fromJson(Map<String, dynamic>.from(raw));
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

  // TODO(shortcut-mock): Persist registered shortcuts or surface them from
  // storage so the UI can reflect real OS state.
  // 현재는 목업 서비스가 단축키 목록을 저장하지 않아 사용자가 등록한 내용이
  // 앱을 재시작하면 모두 사라지고 실제 로컬 데이터와 일치하지 않습니다.
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
    // TODO(shortcut-web): Provide a web-compatible shortcut integration
    // instead of defaulting to the no-op mock service.
    // 현재 웹 환경에서는 단축키가 실제로 등록되지 않아 자동화 기능이 동작하지
    // 않습니다.
    return MockShortcutAutomationService();
  }
  if (Platform.isIOS || Platform.isAndroid) {
    return MethodChannelShortcutAutomationService();
  }
  // TODO(shortcut-desktop): Add native desktop shortcut wiring or disable the
  // feature gracefully when unsupported.
  // 데스크톱 빌드에서도 아직 OS 단축키와 연결되지 않아 Mock 서비스만 동작하며
  // 사용자 설정/DB 데이터가 반영되지 않습니다.
  return MockShortcutAutomationService();
}
