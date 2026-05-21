import 'package:flutter/material.dart';
import '../../../../services/sqlite_service.dart';
import '../../../../utils/constants.dart';

/// Form untuk Create dan Edit Catatan
/// Mode ditentukan berdasarkan parameter noteId (null = create, ada nilai = edit)
class CatatanForm extends StatefulWidget {
  final int? noteId;
  final String? initialTitle;
  final String? initialContent;

  const CatatanForm({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<CatatanForm> createState() => _CatatanFormState();
}

class _CatatanFormState extends State<CatatanForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _isiController;
  bool _isLoading = false;

  bool get isEditMode => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.initialTitle ?? '');
    _isiController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  Future<void> _simpanCatatan() async {
    if (!_formKey.currentState!.validate()) return;

    if (!SQLiteService.isLoggedIn) {
      _showSnackBar('Pengguna belum login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditMode) {
        // Update catatan
        await SQLiteService.updateNote(
          widget.noteId!,
          _judulController.text,
          _isiController.text,
        );
        _showSnackBar('Catatan berhasil diperbarui');
      } else {
        // Create catatan
        await SQLiteService.createNote(
          _judulController.text,
          _isiController.text,
        );
        _showSnackBar('Catatan berhasil ditambahkan');
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
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isEditMode ? 'Edit Catatan' : 'Tambah Catatan',
          style: const TextStyle(color: AppColors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.white),
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
                        hintText: 'Judul Catatan',
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
                      controller: _isiController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText: 'Isi Catatan',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Isi catatan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _simpanCatatan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        isEditMode ? 'UPDATE CATATAN' : 'SIMPAN CATATAN',
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
