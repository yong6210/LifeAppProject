import 'package:flutter/services.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_native_timezone');
  final defaultMessenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    defaultMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => '42',
    );
  });

  tearDown(() {
    defaultMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getLocalTimezone', () async {
    expect(await FlutterNativeTimezone.getLocalTimezone(), '42');
  });
}
