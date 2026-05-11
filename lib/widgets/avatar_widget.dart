import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? base64Image;
  final double radius;
  final String? fallbackLetter;

  const AppAvatar({
    super.key,
    this.base64Image,
    this.radius = 20,
    this.fallbackLetter,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: _buildImage(),
      backgroundColor: Colors.transparent,
    );
  }

  ImageProvider? _buildImage() {
    if (base64Image != null && base64Image!.isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(base64Image!);
        return MemoryImage(bytes);
      } catch (_) {}
    }
    // Дефолтная аватарка
    return const AssetImage('assets/default.png');
  }
}