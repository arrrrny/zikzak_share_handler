import 'package:flutter_test/flutter_test.dart';
import 'package:zikzak_share_handler_linux/zikzak_share_handler_linux.dart';

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
    expect(await ShareHandlerLinuxPlatform.platformVersion, '42');
  });
}
