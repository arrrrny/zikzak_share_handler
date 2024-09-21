// import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zikzak_share_handler_macos/zikzak_share_handler_macos.dart';

void main() {
  // const channel = MethodChannel('zikzak_share_handler');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // channel.setMockMethodCallHandler((MethodCall methodCall) async {
    //   return '42';
    // });
  });

  tearDown(() {
    // channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await ShareHandlerMacosPlatform.platformVersion, '42');
  });
}
