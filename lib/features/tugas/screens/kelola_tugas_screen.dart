import 'package:flutter/material.dart';
import '../../materi/screens/materi_explorer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../forms/tugas_form.dart';
import '../../kalender/screens/kalender_screen.dart';
import '../../catatan/screens/catatan_list_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../../services/sqlite_service.dart';
import '../../../models/tugas_model.dart';
import '../../../widgets/task_card.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../utils/constants.dart';

class KelolaTugasScreen extends StatefulWidget {
  const KelolaTugasScreen({super.key});

  @override
  State<KelolaTugasScreen> createState() => _KelolaTugasScreenState();
}

class _KelolaTugasScreenState extends State<KelolaTugasScreen> {
  static const String _statusFilterKey = 'tasks_filter_status';
  static const String _priorityFilterKey = 'tasks_filter_priority';

  List<Tugas> _listTugas = [];
  bool _isLoading = true;
  String _statusFilter = 'all';
  String _priorityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchTugas();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _statusFilter = prefs.getString(_statusFilterKey) ?? 'all';
      _priorityFilter = prefs.getString(_priorityFilterKey) ?? 'all';
    });
  }

  Future<void> _saveStatusFilter(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusFilterKey, value);
    if (!mounted) return;

    setState(() => _statusFilter = value);
  }

  Future<void> _savePriorityFilter(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_priorityFilterKey, value);
    if (!mounted) return;

    setState(() => _priorityFilter = value);
  }

  /// Mengambil data tugas dari SQLite lokal
  Future<void> _fetchTugas() async {
    if (!SQLiteService.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await SQLiteService.getTasks();
      if (response.containsKey('data')) {
        final List data = response['data'];
        setState(() {
          _listTugas = data.map((item) => Tugas.fromJson(item)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching tasks: $e");
    }
  }

  /// Menampilkan dialog untuk mengedit tugas
  void _showEditDialog(Tugas tugas) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TugasForm(
          taskId: tugas.id,
          initialTitle: tugas.judul,
          initialDescription: tugas.deskripsi,
          initialPriority: tugas.prioritas ?? 'medium',
        ),
      ),
    ).then((_) => _fetchTugas());
  }

  /// Menghapus tugas berdasarkan ID
  Future<void> _deleteTask(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Tugas"),
        content: const Text("Apakah Anda yakin ingin menghapus tugas ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true && SQLiteService.isLoggedIn) {
      try {
        await SQLiteService.deleteTask(id);
        _fetchTugas();
        if (mounted) {
          _showSnackBar('Tugas berhasil dihapus');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Terjadi kesalahan: $e');
        }
      }
    }
  }

  void _showTaskDetail(Tugas tugas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tugas.judul),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tugas.deskripsi.isNotEmpty) ...[
              const Text(
                'Deskripsi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(tugas.deskripsi),
              const SizedBox(height: 12),
            ],
            Text('Status: ${tugas.status}'),
            Text('Prioritas: ${tugas.prioritas ?? '-'}'),
            if (tugas.tenggatWaktu.isNotEmpty)
              Text('Tenggat: ${DateTimeHelper.formatDate(tugas.tenggatWaktu)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  /// Toggle status tugas (completed/pending)
  Future<void> _toggleTaskStatus(Tugas tugas) async {
    if (!SQLiteService.isLoggedIn) return;

    final newStatus = tugas.status == 'completed' ? 'pending' : 'completed';

    try {
      await SQLiteService.toggleTaskStatus(tugas.id, newStatus);
      _fetchTugas();
      if (mounted) {
        _showSnackBar(
          newStatus == 'completed'
              ? 'Tugas ditandai selesai'
              : 'Tugas ditandai belum selesai',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal mengubah status: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<Tugas> get _visibleTasks {
    return _listTugas.where((tugas) {
      final statusMatches =
          _statusFilter == 'all' || tugas.status == _statusFilter;
      final priorityMatches =
          _priorityFilter == 'all' || tugas.prioritas == _priorityFilter;

      return statusMatches && priorityMatches;
    }).toList();
  }

  Widget _buildPreferenceControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'completed', child: Text('Selesai')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _saveStatusFilter(value);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _priorityFilter,
              decoration: InputDecoration(
                labelText: 'Prioritas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua')),
                DropdownMenuItem(value: 'low', child: Text('Rendah')),
                DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                DropdownMenuItem(value: 'high', child: Text('Tinggi')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _savePriorityFilter(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: AppStrings.listTugas,
        showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPreferenceControls(),
                Expanded(
                  child: _visibleTasks.isEmpty
                      ? const Center(child: Text(AppStrings.belumAdaTugas))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: Column(
                            children: _visibleTasks
                                .map(
                                  (tugas) => TaskCard(
                                    tugas: tugas,
                                    onEdit: () => _showEditDialog(tugas),
                                    onDelete: () => _deleteTask(tugas.id),
                                    onToggleStatus: () =>
                                        _toggleTaskStatus(tugas),
                                    onTap: () => _showTaskDetail(tugas),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TugasForm()),
          ).then((_) => _fetchTugas());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: ''),
        ],
        currentIndex: 1,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const KalenderScreen()),
              );
              break;
            case 1:
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
      ),
    );
  }
}
