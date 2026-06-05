import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final bool isRecording;
  final double progress;
  final Color color;

  WaveformPainter({required this.isRecording, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final barCount = 40;
    final barWidth = size.width / barCount * 0.6;
    final gap = size.width / barCount * 0.4;
    final centerY = size.height / 2;
    final rng = Random(42);

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap) + gap / 2;
      double heightFactor;

      if (isRecording) {
        heightFactor = 0.15 + rng.nextDouble() * 0.85 * (0.5 + 0.5 * sin(progress * pi * 2 + i * 0.3));
      } else {
        heightFactor = 0.05 + 0.1 * sin(progress * pi * 2 + i * 0.2);
      }

      final barHeight = size.height * heightFactor;
      final opacity = isRecording ? 0.4 + 0.6 * heightFactor : 0.2 + 0.3 * heightFactor;

      paint.color = color.withValues(alpha: opacity);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + barWidth / 2, centerY), width: barWidth, height: barHeight),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) => true;
}
