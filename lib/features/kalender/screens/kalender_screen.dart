import 'package:flutter/material.dart';
import '../../materi/screens/materi_explorer_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../forms/acara_form.dart';
import '../../tugas/screens/kelola_tugas_screen.dart';
import '../../catatan/screens/catatan_list_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../../services/sqlite_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/filter_dropdown_card.dart';
import '../../../utils/constants.dart';

class KalenderScreen extends StatefulWidget {
  const KalenderScreen({super.key});

  @override
  State<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends State<KalenderScreen> {
  static const String _eventFilterKey = 'calendar_event_filter';
  static const String _reminderEnabledKey = 'calendar_reminder_enabled';

  DateTime selectedDate = DateTime.now();
  List<dynamic> events = [];
  bool isLoading = true;
  String _eventFilter = 'today';
  bool _reminderEnabled = false;
  bool _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchEvents();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('calendar_selected_view');
    if (!mounted) return;

    setState(() {
      _eventFilter = prefs.getString(_eventFilterKey) ?? 'today';
      _reminderEnabled = prefs.getBool(_reminderEnabledKey) ?? false;
    });
  }

  Future<void> _saveEventFilter(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eventFilterKey, value);
    if (!mounted) return;

    setState(() => _eventFilter = value);
  }

  Future<void> _saveReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, value);
    if (!mounted) return;

    setState(() => _reminderEnabled = value);
  }

  Future<void> _fetchEvents() async {
    if (!SQLiteService.isLoggedIn) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await SQLiteService.getActivities();
      if (response.containsKey('data')) {
        setState(() {
          events = response['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching events: $e");
    }
  }

  void _addEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AcaraForm()),
    ).then((added) {
      if (added == true) {
        _fetchEvents();
      }
    });
  }

  /// Edit acara
  void _editEvent(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AcaraForm(
          activityId: event['id'],
          initialTitle: event['title'] ?? '',
          initialDate: event['date'] ?? '',
          initialTime: event['time'] ?? '',
        ),
      ),
    ).then((updated) {
      if (updated == true) {
        _fetchEvents();
      }
    });
  }

  /// Hapus acara
  Future<void> _deleteEvent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Acara"),
        content: const Text("Apakah Anda yakin ingin menghapus acara ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && SQLiteService.isLoggedIn) {
      try {
        await SQLiteService.deleteActivity(id);
        _fetchEvents();
        if (mounted) {
          _showSnackBar('Acara berhasil dihapus');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Terjadi kesalahan: $e');
        }
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildEventList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final visibleEvents = _visibleEvents;

    if (visibleEvents.isEmpty) {
      return const SizedBox(
        height: 180,
        child: EmptyState(
          icon: Icons.event_available_outlined,
          title: 'Belum ada acara',
          message: 'Tambahkan acara baru dari tombol plus.',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleEvents.length,
      itemBuilder: (context, i) {
        final e = visibleEvents[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: ListTile(
            title: Text(e["title"] ?? "No Title"),
            subtitle: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 6),
                Text(DateTimeHelper.formatDate(e['date'] ?? '-')),
                const SizedBox(width: 12),
                SvgPicture.asset(
                  'assets/icons/clock.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 6),
                Text(DateTimeHelper.formatTime(e['time'] ?? '-')),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editEvent(e),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEvent(e['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<dynamic> get _visibleEvents {
    return events.where((event) {
      final date = _parseEventDate(event['date']);
      if (date == null) return false;

      final eventDay = DateTime(date.year, date.month, date.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      switch (_eventFilter) {
        case 'past':
          return eventDay.isBefore(today);
        case 'upcoming':
          return eventDay.isAfter(today);
        case 'today':
        default:
          return _isSameDay(eventDay, today);
      }
    }).toList();
  }

  DateTime? _parseEventDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  Widget _buildPreferenceControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          FilterDropdownCard(
            label: 'Filter acara',
            value: _eventFilter,
            items: const [
              DropdownMenuItem(value: 'past', child: Text('Yang lalu')),
              DropdownMenuItem(value: 'today', child: Text('Hari ini')),
              DropdownMenuItem(
                value: 'upcoming',
                child: Text('Yang akan datang'),
              ),
            ],
            onChanged: _saveEventFilter,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reminder acara'),
            value: _reminderEnabled,
            onChanged: _saveReminderEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
              ),
              title: const Text('Kalender'),
              subtitle: Text(
                DateTimeHelper.formatDate(selectedDate.toString()),
              ),
              trailing: IconButton(
                icon: Icon(
                  _isCalendarExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: () {
                  setState(() {
                    _isCalendarExpanded = !_isCalendarExpanded;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _isCalendarExpanded = !_isCalendarExpanded;
                });
              },
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (d) => setState(() => selectedDate = d),
            ),
            crossFadeState: _isCalendarExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "List Acara",
        showBackButton: false,
        showLogoutButton: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            _buildCalendarPanel(),
            _buildPreferenceControls(),
            const Divider(),
            _buildEventList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const KelolaTugasScreen(),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MateriExplorerScreen(),
                ),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CatatanListScreen(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: ''),
        ],
      ),
    );
  }
}
