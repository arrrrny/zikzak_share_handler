import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:zikzak_share_handler/zikzak_share_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  SharedMedia? media;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandler.instance;
    media = await handler.getInitialSharedMedia();

    handler.sharedMediaStream.listen((SharedMedia media) {
      if (!mounted) return;
      setState(() {
        this.media = media;
      });
    });
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Share Handler'),
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              Text("Conversation Identifier: ${media?.conversationIdentifier}"),
              const SizedBox(height: 10),
              Text("Shared text: ${media?.content}"),
              const SizedBox(height: 10),
              Text("Shared files: ${media?.attachments?.length}"),
              ...(media?.attachments ?? []).map((attachment) {
                final _path = attachment?.path;
                if (_path != null &&
                    attachment?.type == SharedAttachmentType.image) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ShareHandlerPlatform.instance.recordSentMessage(
                            conversationIdentifier:
                                "custom-conversation-identifier",
                            conversationName: "John Doe",
                            conversationImageFilePath: _path,
                            serviceName: "custom-service-name",
                          );
                        },
                        child: const Text("Record message"),
                      ),
                      const SizedBox(height: 10),
                      Image.file(File(_path)),
                    ],
                  );
                } else {
                  return Text(
                      "${attachment?.type} Attachment: ${attachment?.path}");
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
