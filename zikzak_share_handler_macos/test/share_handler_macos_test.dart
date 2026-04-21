import 'package:flutter_test/flutter_test.dart';
import 'package:zikzak_share_handler_macos/zikzak_share_handler_macos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registerWith', () {
    expect(() => ShareHandlerMacosPlatform.registerWith(), returnsNormally);
  });
}
