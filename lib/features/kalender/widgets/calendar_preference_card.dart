import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../widgets/filter_dropdown_card.dart';

class CalendarPreferenceCard extends StatelessWidget {
  final String eventFilter;
  final ValueChanged<String> onEventFilterChanged;

  const CalendarPreferenceCard({
    super.key,
    required this.eventFilter,
    required this.onEventFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilterDropdownCard(
          label: 'Filter acara',
          value: eventFilter,
          items: const [
            DropdownMenuItem(value: 'past', child: Text('Yang lalu')),
            DropdownMenuItem(value: 'today', child: Text('Hari ini')),
            DropdownMenuItem(
              value: 'upcoming',
              child: Text('Yang akan datang'),
            ),
          ],
          onChanged: onEventFilterChanged,
        ),
      ),
    );
  }
}
