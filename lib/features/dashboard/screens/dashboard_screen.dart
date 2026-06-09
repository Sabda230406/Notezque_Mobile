import 'package:flutter/material.dart';
import '../../materi/screens/materi_explorer_screen.dart';
import '../../catatan/screens/catatan_list_screen.dart';
import '../../kalender/screens/kalender_screen.dart';
import '../../tugas/screens/kelola_tugas_screen.dart';
import '../../../services/sqlite_service.dart';
import '../../../utils/constants.dart';

/// Dashboard utama aplikasi NotezQue
/// Menampilkan ringkasan aktivitas pengguna
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _todayEvents = 0;
  int _totalNotes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!SQLiteService.isLoggedIn) {
      setState(() {
        _isLoading = false;
        _error = 'Pengguna belum login. Silakan login kembali.';
      });
      return;
    }

    try {
      final results = await Future.wait([
        SQLiteService.getTasks(),
        SQLiteService.getActivities(),
        SQLiteService.getNotes(),
      ]);

      final tasks = (results[0]['data'] as List?) ?? [];
      final activities = (results[1]['data'] as List?) ?? [];
      final notes = (results[2]['data'] as List?) ?? [];

      final completed = tasks
          .where((t) => (t['status'] ?? '') == 'completed')
          .length;
      final today = DateTime.now();
      final todayStr =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayEvents = activities
          .where((a) => (a['date'] ?? '').toString().startsWith(todayStr))
          .length;

      setState(() {
        _isLoading = false;
        _totalTasks = tasks.length;
        _completedTasks = completed;
        _todayEvents = todayEvents;
        _totalNotes = notes.length;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat data: $e';
      });
    }
  }

  /// Navigasi ke halaman berdasarkan index bottom navigation
  void _navigate(BuildContext context, int index) {
    final pages = [
      const KalenderScreen(),
      const KelolaTugasScreen(),
      null, // Home (tidak pindah)
      const MateriExplorerScreen(),
      const CatatanListScreen(),
    ];

    if (pages[index] != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => pages[index]!),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // AppBar
      appBar: AppBar(
        toolbarHeight: AppSizes.appBarHeight,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            SizedBox(
              width: AppSizes.logoSize,
              height: AppSizes.logoSize,
              child: Image.asset(
                'assets/image/logoNotezQue.png',
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.task_alt, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Dashboard",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppSizes.borderRadius),
          ),
        ),
        actions: const [
          Icon(Icons.notifications, color: AppColors.white),
          SizedBox(width: 10),
          Icon(Icons.person, color: AppColors.white),
          SizedBox(width: 10),
        ],
      ),

      // Body
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!, textAlign: TextAlign.center))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat datang!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.spacing),
                  const Text("Ringkasan aktivitas kamu hari ini"),
                  const SizedBox(height: 20),

                  // Grid Cards untuk statistik
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSizes.cardPadding,
                      mainAxisSpacing: AppSizes.cardPadding,
                      children: [
                        DashboardCard(
                          "Total Tugas",
                          _totalTasks.toString(),
                          Icons.task,
                        ),
                        DashboardCard(
                          "Tugas Selesai",
                          _completedTasks.toString(),
                          Icons.check_circle,
                        ),
                        DashboardCard(
                          "Jadwal Hari Ini",
                          _todayEvents.toString(),
                          Icons.calendar_today,
                        ),
                        DashboardCard(
                          "Catatan",
                          _totalNotes.toString(),
                          Icons.description,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) => _navigate(context, index),
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

/// Widget card untuk menampilkan statistik di dashboard
class DashboardCard extends StatelessWidget {
  final String title, value;
  final IconData icon;

  const DashboardCard(this.title, this.value, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardPadding),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
