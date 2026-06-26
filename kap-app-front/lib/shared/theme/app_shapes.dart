import 'package:flutter/material.dart';

/// A CustomPainter that renders organic, smooth background blobs using cubic bezier curves.
class BlobPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double scale;
  final Offset offset;

  BlobPainter({
    required this.color,
    this.opacity = 0.15,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Center of the blob calculation incorporating dynamic offset
    final center = Offset(size.width / 2, size.height / 2) + offset;
    final radius = (size.width < size.height ? size.width : size.height) / 2 * scale;

    // Core organic shape nodes
    final p1 = Offset(center.dx, center.dy - radius * 0.95);
    final p2 = Offset(center.dx + radius * 0.85, center.dy - radius * 0.15);
    final p3 = Offset(center.dx + radius * 0.45, center.dy + radius * 0.85);
    final p4 = Offset(center.dx - radius * 0.85, center.dy + radius * 0.25);

    path.moveTo(p1.dx, p1.dy);

    // Segment 1: Upper-right curve
    path.cubicTo(
      center.dx + radius * 0.5,
      center.dy - radius * 0.95,
      center.dx + radius * 0.85,
      center.dy - radius * 0.6,
      p2.dx,
      p2.dy,
    );

    // Segment 2: Lower-right curve
    path.cubicTo(
      center.dx + radius * 0.85,
      center.dy + radius * 0.3,
      center.dx + radius * 0.7,
      center.dy + radius * 0.75,
      p3.dx,
      p3.dy,
    );

    // Segment 3: Lower-left curve
    path.cubicTo(
      center.dx + radius * 0.2,
      center.dy + radius * 0.95,
      center.dx - radius * 0.55,
      center.dy + radius * 0.75,
      p4.dx,
      p4.dy,
    );

    // Segment 4: Upper-left curve back to start
    path.cubicTo(
      center.dx - radius * 0.95,
      center.dy - radius * 0.25,
      center.dx - radius * 0.4,
      center.dy - radius * 0.95,
      p1.dx,
      p1.dy,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BlobPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}
