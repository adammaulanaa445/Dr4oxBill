/// Layar backup dan restore database dan foto produk.
library backup_screen;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/backup_service.dart';
import '../core/database/app_database.dart';
import '../widgets/sidebar.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backup Database',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E79),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Backup mencakup database SQLite, semua foto produk, dan metadata validasi.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.backup),
                label: const Text('Buat Backup'),
                onPressed: _isProcessing ? null : _createBackup,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Restore Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E79),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Restore akan mengganti data aktif saat ini. Pastikan Anda telah memilih file backup yang valid.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Pilih File Backup & Restore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: _isProcessing ? null : _restoreBackup,
              ),
            ),
            const SizedBox(height: 24),
            if (_statusMessage != null) ...[
              Card(
                color: _isSuccess! ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess! ? Icons.check_circle : Icons.error,
                        color: _isSuccess! ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_statusMessage!)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan File Backup',
        fileName:
            'dr4ox_bill_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
        allowedExtensions: ['zip'],
      );

      if (result == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final backupService = BackupService();
      final backupResult = await backupService.createBackup(result!);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = backupResult.success;
        _statusMessage = backupResult.success
            ? 'Backup berhasil disimpan di ${backupResult.data}'
            : backupResult.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Gagal membuat backup: $e';
      });
    }
  }

  Future<void> _restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Backup',
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) return;

    final backupPath = result.files.single.path!;

    // Konfirmasi restore.
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Konfirmasi Restore'),
            content: const Text(
              'Restore akan mengganti semua data aktif saat ini dengan data dari backup. '
              'Data aktif akan di-backup terlebih dahulu sebagai langkah keselamatan. Lanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Restore'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final backupService = BackupService();
      final restoreResult = await backupService.restoreBackup(
        backupPath: backupPath,
        confirm: true,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = restoreResult.success;
        _statusMessage = restoreResult.success
            ? 'Restore berhasil. Silakan restart aplikasi.'
            : restoreResult.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Gagal restore: $e';
      });
    }
  }
}
