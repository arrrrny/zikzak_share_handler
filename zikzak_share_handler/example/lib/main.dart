import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zikzak_share_handler/zikzak_share_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SharedMedia? _media;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    final handler = ShareHandler.instance;
    final initialMedia = await handler.getInitialSharedMedia();
    if (initialMedia != null && mounted) {
      setState(() => _media = initialMedia);
    }

    handler.sharedMediaStream.listen((SharedMedia sharedMedia) {
      if (!mounted) return;
      setState(() => _media = sharedMedia);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share Handler Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Share Handler'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: _media == null
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.share, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Share content to this app',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_media!.content != null) ...[
                    const Text(
                      'Content:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _media!.content!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Divider(),
                  ],
                  if (_media!.subject != null) ...[
                    const Text(
                      'Subject:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(_media!.subject!),
                    const Divider(),
                  ],
                  if (_media!.attachments != null && _media!.attachments!.isNotEmpty) ...[
                    const Text(
                      'Attachments:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ..._media!.attachments!.map(
                      (attachment) => Card(
                        child: ListTile(
                          leading: _isImage(attachment.path)
                              ? Image.file(
                                  File(attachment.path),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.insert_drive_file),
                                )
                              : Icon(_iconForType(attachment.type)),
                          title: Text(
                            attachment.path.split('/').last,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(attachment.type.name),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp');
  }

  IconData _iconForType(SharedAttachmentType type) {
    switch (type) {
      case SharedAttachmentType.image:
        return Icons.image;
      case SharedAttachmentType.video:
        return Icons.videocam;
      case SharedAttachmentType.audio:
        return Icons.audiotrack;
      case SharedAttachmentType.file:
        return Icons.insert_drive_file;
    }
  }
}
