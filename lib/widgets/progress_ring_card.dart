import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ProgressRingCard extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;
  final int todayEvents;
  final int totalNotes;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;

  const ProgressRingCard({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
    required this.todayEvents,
    required this.totalNotes,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
  });

  double get _progress {
    if (totalTasks == 0) return 0;
    return (completedTasks / totalTasks).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricInfo('Selesai', '$completedTasks/$totalTasks', Icons.check_circle),
      _MetricInfo('Acara hari ini', '$todayEvents', Icons.calendar_today),
      _MetricInfo('Catatan', '$totalNotes', Icons.description),
    ];
    final selected = items[selectedIndex.clamp(0, items.length - 1)];

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -100) {
          onSelectedIndexChanged((selectedIndex + 1) % items.length);
        } else if (velocity > 100) {
          onSelectedIndexChanged(
            (selectedIndex - 1 + items.length) % items.length,
          );
        }
      },
      onDoubleTap: () => onSelectedIndexChanged(0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _ProgressRingPainter(progress: _progress),
                child: Center(
                  child: Text(
                    '${(_progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress Hari Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(selected.icon, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selected.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected.value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricInfo {
  final String label;
  final String value;
  final IconData icon;

  const _MetricInfo(this.label, this.value, this.icon);
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  const _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, Color(0xFF2E7D32)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
