// import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zikzak_share_handler_windows/zikzak_share_handler_windows.dart';

void main() {
  // const channel = MethodChannel('zikzak_share_handler');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // channel.setMockMethodCallHandler((MethodCall methodCall) async => '42');
  });

  tearDown(() {
    // channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await ShareHandlerWindowsPlatform.platformVersion, '42');
  });
}
