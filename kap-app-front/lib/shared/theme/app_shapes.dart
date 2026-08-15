import 'package:flutter/material.dart';

class BlobPainter extends CustomPainter {
  final Color color;
  final double opacity;

  BlobPainter({
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80); // Glow blur

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.2);
    
    path.cubicTo(
      size.width * 0.4, size.height * 0.05,
      size.width * 0.7, size.height * 0.1,
      size.width * 0.85, size.height * 0.35,
    );
    path.cubicTo(
      size.width * 0.95, size.height * 0.6,
      size.width * 0.8, size.height * 0.85,
      size.width * 0.5, size.height * 0.9,
    );
    path.cubicTo(
      size.width * 0.2, size.height * 0.95,
      size.width * 0.05, size.height * 0.7,
      size.width * 0.1, size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.12, size.height * 0.3,
      size.width * 0.08, size.height * 0.25,
      size.width * 0.15, size.height * 0.2,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
