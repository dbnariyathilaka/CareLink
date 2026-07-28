import 'dart:io';

import 'package:flutter/material.dart';

/// Drop-in replacement for `Image.file(File(source), ...)` that also
/// handles Firebase Storage download URLs — renders `Image.network` when
/// [source] is a remote URL, `Image.file` when it's still a local device
/// path (e.g. immediately after picking, before the upload completes).
class RemoteOrLocalImage extends StatelessWidget {
  const RemoteOrLocalImage({
    super.key,
    required this.source,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  final String source;
  final double width;
  final double height;
  final BoxFit fit;

  bool get _isNetwork => source.startsWith('http://') || source.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return _isNetwork
        ? Image.network(
            source,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        : Image.file(
            File(source),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
  }
}
