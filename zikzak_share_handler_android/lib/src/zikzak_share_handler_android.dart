import 'dart:async';

import 'package:flutter/services.dart';
import 'package:zikzak_share_handler_platform_interface/zikzak_share_handler_platform_interface.dart';

class ShareHandlerAndroidPlatform extends ShareHandlerPlatform {
  final ShareHandlerApi _api = ShareHandlerApi();
  static const EventChannel eventChannel =
      EventChannel("wtf.zikzak.zikzak_share_handler/sharedMediaStream");
  static Stream<SharedMedia>? _sharedMediaStream;

  static void registerWith() {
    ShareHandlerPlatform.instance = ShareHandlerAndroidPlatform();
  }

  @override
  Future<SharedMedia?> getInitialSharedMedia() async {
    final SharedMedia? result = await _api.getInitialSharedMedia();
    return result;
  }

  @override
  Future<void> recordSentMessage({
    required String conversationIdentifier,
    required String conversationName,
    String? conversationImageFilePath,
    String? serviceName,
  }) {
    return _api.recordSentMessage(SharedMedia(
      conversationIdentifier: conversationIdentifier,
      speakableGroupName: conversationName,
      serviceName: serviceName,
      imageFilePath: conversationImageFilePath,
    ));
  }

  @override
  Future<void> resetInitialSharedMedia() {
    return _api.resetInitialSharedMedia();
  }

  @override
  Stream<SharedMedia> get sharedMediaStream {
    _sharedMediaStream ??=
        eventChannel.receiveBroadcastStream().map<SharedMedia>((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      return SharedMedia.decode(map);
    });
    return _sharedMediaStream!;
  }
}
