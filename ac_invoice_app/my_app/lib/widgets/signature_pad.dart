import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A simple finger-drawing "whiteboard" for capturing a signature on the
/// phone. Pops with the PNG bytes of the drawing, or null if cancelled.
class SignaturePadScreen extends StatefulWidget {
  const SignaturePadScreen({super.key});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<Offset?> _points = [];

  void _clear() => setState(() => _points.clear());

  bool get _hasDrawing => _points.any((p) => p != null);

  Future<void> _save() async {
    if (!_hasDrawing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature first')),
      );
      return;
    }
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      if (!mounted) return;
      Navigator.pop<Uint8List>(context, bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save signature: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Signature'),
        actions: [
          IconButton(onPressed: _clear, icon: const Icon(Icons.refresh), tooltip: 'Clear'),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Sign inside the white board below using your finger',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: double.infinity,
                  child: Listener(
                    onPointerDown: (e) => setState(() => _points.add(e.localPosition)),
                    onPointerMove: (e) => setState(() => _points.add(e.localPosition)),
                    onPointerUp: (e) => setState(() => _points.add(null)),
                    child: CustomPaint(
                      painter: _SignaturePainter(_points),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save Signature'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
