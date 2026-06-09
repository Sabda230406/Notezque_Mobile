import 'package:flutter/material.dart';

import '../features/notifikasi/screens/reminder_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../utils/constants.dart';

class TopNavActions extends StatelessWidget {
  const TopNavActions({super.key});

  void _openReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReminderScreen()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Reminder acara',
          icon: const Icon(Icons.notifications, color: AppColors.white),
          onPressed: () => _openReminders(context),
        ),
        IconButton(
          tooltip: 'Profile',
          icon: const Icon(Icons.person, color: AppColors.white),
          onPressed: () => _openProfile(context),
        ),
      ],
    );
  }
}
