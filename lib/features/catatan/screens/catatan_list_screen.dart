import 'package:flutter/material.dart';
import '../forms/catatan_form.dart';
import '../../kalender/screens/kalender_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../tugas/screens/kelola_tugas_screen.dart';
import '../../../services/sqlite_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../utils/constants.dart';

class CatatanListScreen extends StatefulWidget {
  const CatatanListScreen({super.key});

  @override
  State<CatatanListScreen> createState() => _CatatanListScreenState();
}

class _CatatanListScreenState extends State<CatatanListScreen> {
  List<dynamic> _catatanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCatatan();
  }

  Future<void> _fetchCatatan() async {
    if (!SQLiteService.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await SQLiteService.getNotes();
      if (response.containsKey('data')) {
        setState(() {
          _catatanList = response['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching notes: $e");
    }
  }

  /// Tambah catatan baru
  void _tambahCatatan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CatatanForm()),
    ).then((_) => _fetchCatatan());
  }

  /// Hapus catatan
  Future<void> _hapusCatatan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Catatan"),
        content: const Text("Apakah Anda yakin ingin menghapus catatan ini?"),
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
        await SQLiteService.deleteNote(id);
        _fetchCatatan();
        if (mounted) {
          _showSnackBar('Catatan berhasil dihapus');
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

  /// Edit catatan
  void _editCatatan(Map<String, dynamic> catatan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatatanForm(
          noteId: catatan['id'],
          initialTitle: catatan['title'] ?? '',
          initialContent: catatan['content'] ?? '',
        ),
      ),
    ).then((updated) {
      if (updated == true) {
        _fetchCatatan();
      }
    });
  }

  void _showCatatanDetail(Map<String, dynamic> catatan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(catatan['title'] ?? 'Detail Catatan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((catatan['content'] ?? '').toString().isNotEmpty) ...[
                const Text(
                  'Isi:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(catatan['content']),
                const SizedBox(height: 12),
              ],
              if (catatan['created_at'] != null)
                Text(
                  'Dibuat: ${DateTimeHelper.formatDate(catatan['created_at'])}',
                ),
              if (catatan['updated_at'] != null)
                Text(
                  'Diubah: ${DateTimeHelper.formatDate(catatan['updated_at'])}',
                ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'List Catatan', showBackButton: false),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahCatatan,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _catatanList.isEmpty
          ? const Center(
              child: Text('Belum ada catatan', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              itemCount: _catatanList.length,
              itemBuilder: (context, index) {
                final catatan = _catatanList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      catatan['title'] ?? 'No Title',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(catatan['content'] ?? ''),
                    onTap: () => _showCatatanDetail(catatan),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editCatatan(catatan),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _hapusCatatan(catatan['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: ''),
        ],
        currentIndex: 3,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0: // Kalender
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const KalenderScreen()),
              );
              break;
            case 1: // Tugas
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const KelolaTugasScreen(),
                ),
              );
              break;
            case 2: // Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
              break;
            case 3: // Catatan (Current)
              break;
          }
        },
      ),
    );
  }
}
