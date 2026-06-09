import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/materi_model.dart';
import '../../../services/sqlite_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/top_nav_actions.dart';
import '../../catatan/screens/catatan_list_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../kalender/screens/kalender_screen.dart';
import '../../tugas/screens/kelola_tugas_screen.dart';

class MateriExplorerScreen extends StatefulWidget {
  const MateriExplorerScreen({super.key});

  @override
  State<MateriExplorerScreen> createState() => _MateriExplorerScreenState();
}

class _MateriExplorerScreenState extends State<MateriExplorerScreen> {
  bool _isLoading = true;
  List<MateriFolder> _folders = [];
  List<MateriFile> _files = [];

  final List<MateriFolder> _breadcrumb = [];

  int? get currentFolderId =>
      _breadcrumb.isNotEmpty ? _breadcrumb.last.id : null;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!SQLiteService.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final foldersData = await SQLiteService.getFolders(
        parentId: currentFolderId,
      );
      final filesData = await SQLiteService.getFiles(currentFolderId);

      setState(() {
        _folders = foldersData.map((e) => MateriFolder.fromJson(e)).toList();
        _files = filesData.map((e) => MateriFile.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _navigate(int index) {
    if (index == 3) return;
    final pages = [
      const KalenderScreen(),
      const KelolaTugasScreen(),
      const DashboardScreen(),
      null,
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

  void _openFolder(MateriFolder folder) {
    setState(() {
      _breadcrumb.add(folder);
    });
    _fetchData();
  }

  void _navigateToBreadcrumb(int index) {
    if (index == -1) {
      setState(() {
        _breadcrumb.clear();
      });
    } else {
      setState(() {
        _breadcrumb.removeRange(index + 1, _breadcrumb.length);
      });
    }
    _fetchData();
  }

  Future<void> _showCreateFolderDialog() async {
    final titleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Folder Baru'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Nama Folder'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      await SQLiteService.createFolder(
        titleController.text.trim(),
        parentId: currentFolderId,
      );
      _fetchData();
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withReadStream: false,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ukuran file melebihi 10MB')),
            );
          }
          return;
        }

        await SQLiteService.createFile(
          file.name,
          file.size,
          file.extension ?? 'unknown',
          file.path ?? '',
          folderId: currentFolderId,
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  void _showMateriActionSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.create_new_folder,
                  color: AppColors.primary,
                ),
                title: const Text('Folder Baru'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCreateFolderDialog();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.upload_file,
                  color: AppColors.primary,
                ),
                title: const Text('Upload File'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFolder(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Folder'),
        content: const Text(
          'Apakah Anda yakin? Semua isinya juga akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SQLiteService.deleteFolder(id);
      _fetchData();
    }
  }

  Future<void> _deleteFile(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus File'),
        content: const Text('Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SQLiteService.deleteFile(id);
      _fetchData();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    double size = bytes.toDouble();
    int index = 0;
    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[index]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Materi & File',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder, color: Colors.white),
            onPressed: _showCreateFolderDialog,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            onPressed: _pickFile,
          ),
        ],
=======
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Materi & File',
        showLogoutButton: true,
        actions: [TopNavActions()],
>>>>>>> 2fc8af6 (terbaru25)
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _navigateToBreadcrumb(-1),
                    child: const Row(
                      children: [
                        Icon(Icons.home, size: 20, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Root',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._breadcrumb.asMap().entries.map((entry) {
                    final index = entry.key;
                    final folder = entry.value;
                    return Row(
                      children: [
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Colors.grey,
                        ),
                        InkWell(
                          onTap: () => _navigateToBreadcrumb(index),
                          child: Text(
                            folder.name,
                            style: TextStyle(
                              fontWeight: index == _breadcrumb.length - 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: index == _breadcrumb.length - 1
                                  ? Colors.black
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_folders.isEmpty && _files.isEmpty)
                ? const Center(child: Text('Folder kosong'))
                : ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      ..._folders.map(
                        (folder) => Card(
                          elevation: 1,
                          child: ListTile(
                            leading: const Icon(
                              Icons.folder,
                              color: Colors.amber,
                              size: 40,
                            ),
                            title: Text(
                              folder.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text('Folder'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFolder(folder.id),
                            ),
                            onTap: () => _openFolder(folder),
                          ),
                        ),
                      ),
                      ..._files.map(
                        (file) => Card(
                          elevation: 1,
                          child: ListTile(
                            leading: const Icon(
                              Icons.insert_drive_file,
                              color: AppColors.primary,
                              size: 40,
                            ),
                            title: Text(
                              file.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatBytes(file.size)} • ${file.type.toUpperCase()}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFile(file.id),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _navigate,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: ''),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMateriActionSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
