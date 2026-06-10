import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class CalendarSwipeCard extends StatelessWidget {
  final DateTime selectedDate;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<DateTime> onDateChanged;

  const CalendarSwipeCard({
    super.key,
    required this.selectedDate,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onDateChanged,
  });

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 220) return;

    final dayOffset = velocity < 0 ? 1 : -1;
    onDateChanged(selectedDate.add(Duration(days: dayOffset)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggleExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kalender',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(DateTimeHelper.formatDate(selectedDate.toString())),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: onToggleExpanded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
