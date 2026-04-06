import 'dart:typed_data';

import 'package:flutter/material.dart';

class SmartShopImage extends StatelessWidget {
  const SmartShopImage({
    required this.source,
    super.key,
    this.memoryBytes,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String? source;
  final Uint8List? memoryBytes;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (memoryBytes != null) {
      return Image.memory(
        memoryBytes!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    final value = (source ?? '').trim();
    if (value.isEmpty) return _fallback();

    if (_isNetwork(value)) {
      return Image.network(
        value,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    final assetPath = value.startsWith('assets/')
        ? value
        : 'assets/images/$value';
    return Image.asset(
      assetPath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  bool _isNetwork(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('gs://');
  }

  Widget _fallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFF7F7F7)),
      child: Center(
        child: Icon(Icons.image, size: 24, color: Color(0xFFCCCCCC)),
      ),
    );
  }
}
