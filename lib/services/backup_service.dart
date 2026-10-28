/// Layanan untuk backup dan restore database serta foto produk.
///
/// Backup mencakup database SQLite, semua foto produk, dan metadata manifest.
library backup_service;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../core/database/app_database.dart';
import 'file_service.dart';

/// Hasil operasi backup/restore generik.
class BackupResult<T> {
  final T? data;
  final String? error;
  final bool success;

  BackupResult._({this.data, this.error, this.success = false});

  factory BackupResult.success(T data) {
    return BackupResult._(data: data, success: true);
  }

  factory BackupResult.error(String error) {
    return BackupResult._(error: error, success: false);
  }
}

/// Metadata backup untuk validasi.
class BackupManifest {
  final String appName;
  final String appVersion;
  final int databaseVersion;
  final DateTime createdAt;
  final List<String> photoFiles;
  final int photoCount;
  final int databaseSize;

  BackupManifest({
    required this.appName,
    required this.appVersion,
    required this.databaseVersion,
    required this.createdAt,
    required this.photoFiles,
    required this.photoCount,
    required this.databaseSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'app_version': appVersion,
      'database_version': databaseVersion,
      'created_at': createdAt.toIso8601String(),
      'photo_files': photoFiles,
      'photo_count': photoCount,
      'database_size': databaseSize,
    };
  }

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      appName: json['app_name'] ?? '',
      appVersion: json['app_version'] ?? '',
      databaseVersion: json['database_version'] ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      photoFiles: List<String>.from(json['photo_files'] ?? []),
      photoCount: json['photo_count'] ?? 0,
      databaseSize: json['database_size'] ?? 0,
    );
  }
}

class BackupService {
  final AppDatabase _db = AppDatabase();

  /// Nama file manifest dalam arsip backup.
  static const String manifestFileName = 'manifest.json';
  static const String databaseFileNameInArchive = 'dr4ox_bill.db';
  static const String photosFolderInArchive = 'photos';

  /// Buat backup ke file ZIP yang dipilih pengguna.
  ///
  /// [outputPath] path file ZIP tujuan.
  Future<BackupResult<String>> createBackup(String outputPath) async {
    try {
      final db = await _db.database;

      // Salin database ke file temporer untuk diarsipkan.
      final dbPath = await _getDbPath();
      final tempDb = File('${Directory.systemTemp.path}/dr4ox_bill_backup.db');
      await File(dbPath).copy(tempDb.path);

      // Kumpulkan semua file foto.
      final photosDirPath = await FileService.getPhotosDir();
      final photosDir = Directory(photosDirPath);
      final List<String> photoFiles = [];
      if (await photosDir.exists()) {
        final files = photosDir.listSync();
        for (final file in files) {
          if (file is File) {
            photoFiles.add(file.path);
          }
        }
      }

      // Buat arsip ZIP.
      final archive = Archive();

      // Tambahkan database.
      final dbBytes = await tempDb.readAsBytes();
      archive.addFile(
        ArchiveFile(
          databaseFileNameInArchive,
          dbBytes.length,
          dbBytes,
        ),
      );

      // Tambahkan foto-foto.
      for (final photoPath in photoFiles) {
        final photoFile = File(photoPath);
        final photoBytes = await photoFile.readAsBytes();
        final relativePath =
            '${photosFolderInArchive}/${path.basename(photoPath)}';
        archive.addFile(
          ArchiveFile(relativePath, photoBytes.length, photoBytes),
        );
      }

      // Tambahkan manifest.
      final manifest = BackupManifest(
        appName: appName,
        appVersion: appVersion,
        databaseVersion: databaseVersion,
        createdAt: DateTime.now(),
        photoFiles: photoFiles.map((p) => path.basename(p)).toList(),
        photoCount: photoFiles.length,
        databaseSize: dbBytes.length,
      );
      final manifestJson = jsonEncode(manifest.toJson());
      archive.addFile(
        ArchiveFile(
          manifestFileName,
          manifestJson.length,
          utf8.encode(manifestJson),
        ),
      );

      // Encode ke ZIP dan simpan.
      final zipBytes = ZipEncoder().encode(archive);
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(zipBytes!);

      // Bersihkan file temporer.
      await tempDb.delete();

      return BackupResult.success(outputPath);
    } catch (e) {
      return BackupResult.error('Gagal membuat backup: $e');
    }
  }

  /// Validasi arsip backup sebelum restore.
  ///
  /// Mengembalikan manifest jika valid, error jika tidak.
  Future<BackupResult<BackupManifest>> validateBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        return BackupResult.error('File backup tidak ditemukan.');
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Cek file manifest ada.
      final manifestFile =
          archive.files.where((f) => f.name == manifestFileName).firstOrNull;
      if (manifestFile == null) {
        return BackupResult.error(
            'Arsip backup tidak valid: manifest tidak ditemukan.');
      }

      // Cek database ada.
      final dbFile = archive.files
          .where((f) => f.name == databaseFileNameInArchive)
          .firstOrNull;
      if (dbFile == null) {
        return BackupResult.error(
            'Arsip backup tidak valid: database tidak ditemukan.');
      }

      // Parse manifest.
      final manifestJson =
          jsonDecode(utf8.decode(manifestFile.content as List<int>));
      final manifest = BackupManifest.fromJson(manifestJson);

      // Validasi versi database kompatibel.
      if (manifest.databaseVersion > databaseVersion) {
        return BackupResult.error(
          'Versi database backup lebih baru dan tidak kompatibel.',
        );
      }

      return BackupResult.success(manifest);
    } catch (e) {
      return BackupResult.error('Gagal memvalidasi backup: $e');
    }
  }

  /// Restore data dari arsip backup.
  ///
  /// [backupPath] path file ZIP backup.
  /// [confirm] konfirmasi pengguna untuk mengganti data aktif.
  Future<BackupResult<String>> restoreBackup({
    required String backupPath,
    required bool confirm,
  }) async {
    if (!confirm) {
      return BackupResult.error('Restore dibatalkan oleh pengguna.');
    }

    // Validasi backup terlebih dahulu.
    final validation = await validateBackup(backupPath);
    if (!validation.success) {
      return BackupResult.error(validation.error ?? 'Backup tidak valid.');
    }

    final tempDir = Directory(
        '${Directory.systemTemp.path}/dr4ox_restore_${DateTime.now().millisecondsSinceEpoch}');
    await tempDir.create(recursive: true);

    try {
      final file = File(backupPath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Ekstrak database.
      final dbFile = archive.files
          .where((f) => f.name == databaseFileNameInArchive)
          .firstOrNull;
      if (dbFile == null) {
        return BackupResult.error('Database tidak ditemukan dalam backup.');
      }

      final restoredDb = File('${tempDir.path}/dr4ox_bill.db');
      await restoredDb.writeAsBytes(dbFile.content as List<int>);

      // Backup data aktif sebelum replace (safety backup).
      final currentDbPath = await _getDbPath();
      final safetyBackup = File('${tempDir.path}/safety_backup.db');
      if (await File(currentDbPath).exists()) {
        await File(currentDbPath).copy(safetyBackup.path);
      }

      // Ganti database aktif.
      await File(currentDbPath).delete();
      await restoredDb.copy(currentDbPath);

      // Ekstrak dan restore foto.
      final photosDirPath = await FileService.getPhotosDir();
      for (final archivedFile in archive.files) {
        if (archivedFile.name.startsWith('${photosFolderInArchive}/')) {
          final fileName = path.basename(archivedFile.name);
          final destFile = File('$photosDirPath/$fileName');
          await destFile.writeAsBytes(archivedFile.content as List<int>);
        }
      }

      // Bersihkan direktori temporer.
      await tempDir.delete(recursive: true);

      return BackupResult.success('Restore berhasil.');
    } catch (e) {
      // Coba pulihkan dari safety backup jika ada.
      final safetyBackup = File('${tempDir.path}/safety_backup.db');
      if (await safetyBackup.exists()) {
        try {
          final currentDbPath = await _getDbPath();
          await safetyBackup.copy(currentDbPath);
        } catch (_) {
          // Abaikan.
        }
      }

      await tempDir.delete(recursive: true);
      return BackupResult.error('Gagal restore backup: $e');
    }
  }

  /// Dapatkan path database SQLite saat ini.
  Future<String> _getDbPath() async {
    final appDir = await FileService.getAppDataDir();
    return path.join(appDir, databaseFileName);
  }

  /// Hapus file backup.
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {
      // Abaikan.
    }
    return false;
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final element in this) {
      return element;
    }
    return null;
  }
}

// Konstanta aplikasi.
const String appName = 'Dr4oxBill';
const String appVersion = '1.0.0';
const int databaseVersion = 1;
const String databaseFileName = 'dr4ox_bill.db';
