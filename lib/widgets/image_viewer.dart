import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageViewer extends StatefulWidget {
  final String imageUrl;

  const ImageViewer({super.key, required this.imageUrl});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  Size? _screenSize;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  @override
  Widget build(BuildContext context) {
    // Исправляем двойной URL
    final url = widget.imageUrl.startsWith('http') 
        ? widget.imageUrl 
        : 'https://listo4ek.tech/${widget.imageUrl}';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onDoubleTapDown: (details) {
          _doubleTapPosition = details.localPosition;
        },
        onDoubleTap: () {
          setState(() {
            if (_scale > 1.0) {
              _scale = 1.0;
              _offset = Offset.zero;
            } else {
              final newScale = 3.0;
              final tap = _doubleTapPosition;
              final scaleFactor = newScale / _scale;
              _offset = (_offset - tap) * scaleFactor + tap;
              _scale = newScale;
              _clampOffset();
            }
          });
        },
        onScaleStart: (details) {
          _previousScale = _scale;
          _previousOffset = _offset;
        },
        onScaleUpdate: (details) {
          if (_screenSize == null) return;
          setState(() {
            final newScale = (_previousScale * details.scale).clamp(1.0, 5.0);
            final focalPoint = details.focalPoint;

            if (newScale != _scale) {
              final scaleFactor = newScale / _scale;
              _offset = (_offset - focalPoint) * scaleFactor + focalPoint;
              _scale = newScale;
            } else if (_scale > 1.0) {
              _offset += details.focalPointDelta;
            }
            _clampOffset();
          });
        },
        onScaleEnd: (details) {
          _clampOffset();
        },
        child: Center(
          child: Transform(
            transform: Matrix4.identity()
              ..translate(_offset.dx, _offset.dy)
              ..scale(_scale),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clampOffset() {
    if (_screenSize == null) return;
    if (_scale <= 1.0) {
      _offset = Offset.zero;
      return;
    }
    final maxX = (_screenSize!.width * (_scale - 1)) / 2;
    final maxY = (_screenSize!.height * (_scale - 1)) / 2;
    _offset = Offset(
      _offset.dx.clamp(-maxX, maxX),
      _offset.dy.clamp(-maxY, maxY),
    );
  }
}