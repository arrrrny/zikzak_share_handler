import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zikzak_share_handler/zikzak_share_handler.dart';

class MockShareHandlerPlatform extends Mock implements ShareHandlerPlatform {}

void main() {
  group('ShareHandler', () {
    test('can be instantiated', () {
      expect(
        ShareHandler.instance,
        isNotNull,
      );
    });
  });
}
