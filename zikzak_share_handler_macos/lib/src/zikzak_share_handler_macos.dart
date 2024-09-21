import 'dart:async';

import 'package:flutter/services.dart';
import 'package:zikzak_share_handler_platform_interface/zikzak_share_handler_platform_interface.dart';

class ShareHandlerMacosPlatform extends ShareHandlerPlatform {
  static const _channel = MethodChannel('zikzak_share_handler');

  static Future<String?> get platformVersion async {
    final version = await _channel.invokeMethod<String?>('getPlatformVersion');
    return version;
  }
}
