import 'package:flutter/material.dart';
import '../../../services/sqlite_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/top_nav_actions.dart';

/// Form untuk Create dan Edit Tugas
/// Mode ditentukan berdasarkan parameter taskId (null = create, ada nilai = edit)
class TugasForm extends StatefulWidget {
  final int? taskId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialPriority;

  const TugasForm({
    super.key,
    this.taskId,
    this.initialTitle,
    this.initialDescription,
    this.initialPriority,
  });

  @override
  State<TugasForm> createState() => _TugasFormState();
}

class _TugasFormState extends State<TugasForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _deskripsiController;
  late String _priority;
  bool _isLoading = false;

  bool get isEditMode => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.initialTitle ?? '');
    _deskripsiController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _priority = widget.initialPriority ?? 'medium';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _simpanTugas() async {
    if (!_formKey.currentState!.validate()) return;

    if (!SQLiteService.isLoggedIn) {
      _showSnackBar('Pengguna belum login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditMode) {
        // Update tugas
        await SQLiteService.updateTask(
          widget.taskId!,
          _judulController.text,
          _deskripsiController.text,
        );
        _showSnackBar('Tugas berhasil diperbarui');
      } else {
        // Create tugas
        await SQLiteService.createTask(_judulController.text, _priority);
        _showSnackBar('Tugas berhasil ditambahkan');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: isEditMode ? 'Edit Tugas' : 'Tambah Tugas',
        showBackButton: true,
        showLogoutButton: true,
        actions: const [TopNavActions()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _judulController,
                      decoration: InputDecoration(
                        hintText: 'Judul Tugas',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Deskripsi (opsional)',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pilih Prioritas:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Rendah'),
                            selected: _priority == 'low',
                            onSelected: (selected) {
                              setState(() => _priority = 'low');
                            },
                            selectedColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Sedang'),
                            selected: _priority == 'medium',
                            onSelected: (selected) {
                              setState(() => _priority = 'medium');
                            },
                            selectedColor: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Tinggi'),
                            selected: _priority == 'high',
                            onSelected: (selected) {
                              setState(() => _priority = 'high');
                            },
                            selectedColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _simpanTugas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        isEditMode ? 'UPDATE TUGAS' : 'SIMPAN TUGAS',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
