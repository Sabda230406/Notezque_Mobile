import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../../utils/constants.dart';

/// Form untuk Create dan Edit Acara
/// Mode ditentukan berdasarkan parameter activityId (null = create, ada nilai = edit)
class AcaraForm extends StatefulWidget {
  final int? activityId;
  final String? initialTitle;
  final String? initialDate;
  final String? initialTime;

  const AcaraForm({
    super.key,
    this.activityId,
    this.initialTitle,
    this.initialDate,
    this.initialTime,
  });

  @override
  State<AcaraForm> createState() => _AcaraFormState();
}

class _AcaraFormState extends State<AcaraForm> {
  late TextEditingController _judulController;
  late TextEditingController _tanggalController;
  late TextEditingController _jamController;
  bool _isLoading = false;
  
  bool get isEditMode => widget.activityId != null;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.initialTitle ?? '');
    _tanggalController = TextEditingController(
      text: widget.initialDate ?? DateTime.now().toString().split(' ')[0],
    );
    _jamController = TextEditingController(text: widget.initialTime ?? '08:00');
  }

  @override
  void dispose() {
    _judulController.dispose();
    _tanggalController.dispose();
    _jamController.dispose();
    super.dispose();
  }

  Future<void> _simpanAcara() async {
    if (_judulController.text.isEmpty) {
      _showSnackBar('Nama acara harus diisi');
      return;
    }

    if (ApiService.token == null) {
      _showSnackBar('Token tidak ditemukan');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditMode) {
        // Update acara
        await ApiService.updateActivity(
          ApiService.token!,
          widget.activityId!,
          _judulController.text,
          _tanggalController.text,
          _jamController.text,
        );
        _showSnackBar('Acara berhasil diperbarui');
      } else {
        // Create acara
        await ApiService.createActivity(
          ApiService.token!,
          _judulController.text,
          _tanggalController.text,
          _jamController.text,
        );
        _showSnackBar('Acara berhasil ditambahkan');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_tanggalController.text),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text = picked.toString().split(' ')[0];
      });
    }
  }

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_jamController.text.split(':')[0]),
        minute: int.parse(_jamController.text.split(':')[1]),
      ),
    );
    if (picked != null) {
      setState(() {
        _jamController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isEditMode ? 'Edit Acara' : 'Tambah Acara',
          style: const TextStyle(color: AppColors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  TextField(
                    controller: _judulController,
                    decoration: InputDecoration(
                      hintText: 'Nama Acara',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tanggalController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                      hintText: 'Tanggal',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _jamController,
                    readOnly: true,
                    onTap: _selectTime,
                    decoration: InputDecoration(
                      hintText: 'Jam',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _simpanAcara,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      isEditMode ? 'UPDATE ACARA' : 'SIMPAN ACARA',
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
    );
  }
}
