import 'package:flutter/material.dart';
import '../../materi/screens/materi_explorer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../forms/catatan_form.dart';
import '../../kalender/screens/kalender_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../tugas/screens/kelola_tugas_screen.dart';
import '../../../services/sqlite_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/filter_dropdown_card.dart';
import '../../../widgets/note_preview_card.dart';
import '../../../utils/constants.dart';

class CatatanListScreen extends StatefulWidget {
  const CatatanListScreen({super.key});

  @override
  State<CatatanListScreen> createState() => _CatatanListScreenState();
}

class _CatatanListScreenState extends State<CatatanListScreen> {
  static const String _sortOrderKey = 'notes_sort_order';
  static const String _lastSearchKey = 'notes_last_search';

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _catatanList = [];
  bool _isLoading = true;
  String _sortOrder = 'newest';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchCatatan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _sortOrder = prefs.getString(_sortOrderKey) ?? 'newest';
      _searchController.text = prefs.getString(_lastSearchKey) ?? '';
    });
  }

  Future<void> _saveSortOrder(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortOrderKey, value);
    if (!mounted) return;

    setState(() => _sortOrder = value);
  }

  Future<void> _saveLastSearch(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSearchKey, value);
    if (!mounted) return;

    setState(() {});
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

  List<dynamic> get _visibleCatatanList {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _catatanList.where((catatan) {
      if (query.isEmpty) return true;

      final title = (catatan['title'] ?? '').toString().toLowerCase();
      final content = (catatan['content'] ?? '').toString().toLowerCase();
      return title.contains(query) || content.contains(query);
    }).toList();

    filtered.sort((left, right) {
      switch (_sortOrder) {
        case 'oldest':
          return (left['created_at'] ?? '').toString().compareTo(
            (right['created_at'] ?? '').toString(),
          );
        case 'title':
          return (left['title'] ?? '').toString().toLowerCase().compareTo(
            (right['title'] ?? '').toString().toLowerCase(),
          );
        case 'newest':
        default:
          return (right['created_at'] ?? '').toString().compareTo(
            (left['created_at'] ?? '').toString(),
          );
      }
    });

    return filtered;
  }

  Widget _buildPreferenceControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _saveLastSearch,
            decoration: InputDecoration(
              labelText: 'Cari catatan',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          FilterDropdownCard(
            label: 'Urutkan catatan',
            value: _sortOrder,
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Terbaru')),
              DropdownMenuItem(value: 'oldest', child: Text('Terlama')),
              DropdownMenuItem(value: 'title', child: Text('Judul')),
            ],
            onChanged: _saveSortOrder,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'List Catatan',
        showBackButton: false,
        showLogoutButton: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahCatatan,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPreferenceControls(),
                Expanded(
                  child: _visibleCatatanList.isEmpty
                      ? const EmptyState(
                          icon: Icons.description_outlined,
                          title: 'Belum ada catatan',
                          message:
                              'Tambahkan catatan pertama dari tombol plus.',
                        )
                      : ListView.builder(
                          itemCount: _visibleCatatanList.length,
                          itemBuilder: (context, index) {
                            final catatan = _visibleCatatanList[index];
                            return NotePreviewCard(
                              title: catatan['title'] ?? 'No Title',
                              content: catatan['content'] ?? '',
                              onOpen: () => _showCatatanDetail(catatan),
                              onEdit: () => _editCatatan(catatan),
                              onDelete: () => _hapusCatatan(catatan['id']),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: ''),
        ],
        currentIndex: 4,
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
<<<<<<< HEAD
            case 3: // Folder (belum dibuat)
=======
            case 3: // Folder
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MateriExplorerScreen(),
                ),
              );
>>>>>>> 5be0cffe97f98b9f25f481b754aa14f99fc44ac8
              break;
            case 4: // Catatan (Current)
              break;
          }
        },
      ),
    );
  }
}
