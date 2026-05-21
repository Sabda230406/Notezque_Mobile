import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../forms/acara_form.dart';
import '../../tugas/screens/kelola_tugas_screen.dart';
import '../../catatan/screens/catatan_list_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../../services/sqlite_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../utils/constants.dart';

class KalenderScreen extends StatefulWidget {
  const KalenderScreen({super.key});

  @override
  State<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends State<KalenderScreen> {
  DateTime selectedDate = DateTime.now();
  List<dynamic> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
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

    if (events.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada acara",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, i) {
        final e = events[i];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "List Acara", showBackButton: false),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (d) => setState(() => selectedDate = d),
            ),
          ),
          const Divider(),
          Expanded(child: _buildEventList()),
        ],
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
          BottomNavigationBarItem(icon: Icon(Icons.description), label: ''),
        ],
      ),
    );
  }
}
