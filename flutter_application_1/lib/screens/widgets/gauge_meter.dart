import 'dart:math';
import 'package:flutter/material.dart';

class GaugeMeter extends StatelessWidget {
  final double score; // 0 to 100
  final String status; // 'Safe', 'Warning', 'Danger'

  const GaugeMeter({
    super.key,
    required this.score,
    required this.status,
  });

  Color _getStatusColor() {
    if (status == 'Safe') return const Color(0xFF10B981); // Emerald Green
    if (status == 'Warning') return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Coral Red
  }

  String _getShortStatus() {
    if (status == 'Safe') return 'SAFE';
    if (status == 'Warning') return 'CAUTION';
    return 'DANGER';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();

    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _GaugePainter(
              score: score,
              arcColor: statusColor,
              trackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WATER INDEX',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                score.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getShortStatus(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color arcColor;
  final Color trackColor;

  _GaugePainter({
    required this.score,
    required this.arcColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    
    // We draw a semi-circular arc from 135 degrees to 45 degrees (clockwise)
    const startAngle = 135 * (pi / 180);
    const totalSweep = 270 * (pi / 180);
    
    // 1. Draw Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // 2. Draw Color Indicator Arc
    final sweepAngle = totalSweep * (score / 100);
    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // 3. Draw Dots/Ticks around the arc (subtle indicator)
    final tickPaint = Paint()
      ..color = arcColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Small dot at the end of progress
    if (score > 0) {
      final currentAngle = startAngle + sweepAngle;
      final dx = center.dx + radius * cos(currentAngle);
      final dy = center.dy + radius * sin(currentAngle);
      canvas.drawCircle(Offset(dx, dy), 3.0, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.arcColor != arcColor || oldDelegate.trackColor != trackColor;
  }
}
