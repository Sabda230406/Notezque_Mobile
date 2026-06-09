import 'package:flutter/material.dart';

import '../../../services/sqlite_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      SQLiteService.getNotificationReminders(),
      SQLiteService.getActivities(),
    ]);

    if (!mounted) return;

    setState(() {
      _reminders = ((results[0]['data'] as List?) ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      _activities = ((results[1]['data'] as List?) ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _showReminderDialog({Map<String, dynamic>? reminder}) async {
    final titleController = TextEditingController(
      text: reminder == null ? '' : (reminder['title'] ?? '').toString(),
    );
    int? selectedActivityId = reminder?['activity_id'] as int?;
    bool isEnabled = ((reminder?['is_enabled'] ?? 1) as int) == 1;
    DateTime remindAt =
        DateTime.tryParse((reminder?['remind_at'] ?? '').toString()) ??
        DateTime.now().add(const Duration(hours: 1));

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDate() async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: remindAt,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (pickedDate == null || !context.mounted) return;

            setDialogState(() {
              remindAt = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                remindAt.hour,
                remindAt.minute,
              );
            });
          }

          Future<void> pickTime() async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(remindAt),
            );
            if (pickedTime == null || !context.mounted) return;

            setDialogState(() {
              remindAt = DateTime(
                remindAt.year,
                remindAt.month,
                remindAt.day,
                pickedTime.hour,
                pickedTime.minute,
              );
            });
          }

          return AlertDialog(
            title: Text(reminder == null ? 'Tambah Reminder' : 'Edit Reminder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _activityExists(selectedActivityId)
                        ? selectedActivityId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Acara terkait',
                      border: OutlineInputBorder(),
                    ),
                    items: _activities
                        .map(
                          (activity) => DropdownMenuItem<int>(
                            value: activity['id'] as int,
                            child: Text(activity['title'] ?? 'Acara'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedActivityId = value;
                        if (titleController.text.trim().isEmpty) {
                          final activity = _activities.firstWhere(
                            (item) => item['id'] == value,
                            orElse: () => {},
                          );
                          final activityTitle = activity['title'];
                          if (activityTitle != null) {
                            titleController.text = 'Reminder: $activityTitle';
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul reminder',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            DateTimeHelper.formatDate(remindAt.toString()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            TimeOfDay.fromDateTime(remindAt).format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktif'),
                    value: isEnabled,
                    onChanged: (value) {
                      setDialogState(() => isEnabled = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.batal),
              ),
              ElevatedButton(
                onPressed: () async {
                  final response = reminder == null
                      ? await SQLiteService.createNotificationReminder(
                          selectedActivityId,
                          titleController.text,
                          remindAt.toIso8601String(),
                          isEnabled: isEnabled,
                        )
                      : await SQLiteService.updateNotificationReminder(
                          reminder['id'] as int,
                          selectedActivityId,
                          titleController.text,
                          remindAt.toIso8601String(),
                          isEnabled: isEnabled,
                        );

                  if (!context.mounted) return;
                  _showSnackBar(
                    (response['message'] ?? 'Reminder berhasil disimpan')
                        .toString(),
                  );
                  Navigator.pop(context, response['success'] == true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    titleController.dispose();
    if (saved == true) {
      await _loadData();
    }
  }

  bool _activityExists(int? activityId) {
    if (activityId == null) return false;
    return _activities.any((activity) => activity['id'] == activityId);
  }

  Future<void> _toggleReminder(
    Map<String, dynamic> reminder,
    bool value,
  ) async {
    final response = await SQLiteService.toggleNotificationReminder(
      reminder['id'] as int,
      value,
    );
    if (!mounted) return;

    _showSnackBar((response['message'] ?? 'Status reminder diubah').toString());
    await _loadData();
  }

  Future<void> _deleteReminder(Map<String, dynamic> reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Reminder'),
        content: Text('Hapus "${reminder['title'] ?? 'reminder'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await SQLiteService.deleteNotificationReminder(
      reminder['id'] as int,
    );
    if (!mounted) return;

    _showSnackBar((response['message'] ?? 'Reminder dihapus').toString());
    await _loadData();
  }

  String _formatReminderTime(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;

    return '${DateTimeHelper.formatDate(date.toString())} - ${TimeOfDay.fromDateTime(date).format(context)}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Reminder Acara', showBackButton: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_active_outlined,
              title: 'Belum ada reminder',
              message: 'Tambahkan reminder untuk acara dari tombol plus.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.cardPadding),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                final isEnabled = ((reminder['is_enabled'] ?? 1) as int) == 1;
                final activityTitle = reminder['activity_title'];

                return Card(
                  child: ListTile(
                    leading: Icon(
                      isEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: isEnabled ? AppColors.primary : Colors.grey,
                    ),
                    title: Text(
                      reminder['title'] ?? 'Reminder',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      [
                        _formatReminderTime(
                          (reminder['remind_at'] ?? '').toString(),
                        ),
                        if (activityTitle != null) 'Acara: $activityTitle',
                      ].join('\n'),
                    ),
                    isThreeLine: activityTitle != null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isEnabled,
                          onChanged: (value) =>
                              _toggleReminder(reminder, value),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: AppColors.primary,
                          ),
                          onPressed: () =>
                              _showReminderDialog(reminder: reminder),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteReminder(reminder),
                          tooltip: 'Hapus',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReminderDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
