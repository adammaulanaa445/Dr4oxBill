/// Layanan untuk mengelola direktori dan file aplikasi.
library file_service;

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';

/// Hasil operasi file.
class FileResult {
  final String? path;
  final String? error;
  final bool success;

  FileResult._({this.path, this.error, this.success = false});

  factory FileResult.success(String path) {
    return FileResult._(path: path, success: true);
  }

  factory FileResult.error(String error) {
    return FileResult._(error: error, success: false);
  }
}

class FileService {
  /// Mendapatkan direktori data aplikasi Windows (%APPDATA% atau lokal).
  static Future<String> getAppDataDir() async {
  if (kIsWeb) {
    // Browser tidak memiliki Documents Directory.
    return 'web_storage';
  }

  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}

  /// Mendapatkan direktori untuk menyimpan foto produk.
  static Future<String> getPhotosDir() async {
    final appDir = await getAppDataDir();
    final photosDir = Directory('$appDir/${photosFolderName}');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir.path;
  }

  /// Salin file foto dari sumber ke direktori foto aplikasi dengan nama unik.
  /// Mengembalikan path file baru atau error.
  static Future<FileResult> saveProductPhoto(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        return FileResult.error('File foto tidak ditemukan.');
      }

      final photosDirPath = await getPhotosDir();
      final ext = sourcePath.split('.').last.toLowerCase();

      // Validasi tipe file.
      final allowedTypes = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];
      if (!allowedTypes.contains(ext)) {
        return FileResult.error('Tipe file gambar tidak didukung ($ext).');
      }

      // Validasi ukuran (maksimal 5 MB).
      final fileSize = await source.length();
      if (fileSize > 5 * 1024 * 1024) {
        return FileResult.error('Ukuran file terlalu besar (maksimal 5 MB).');
      }

      // Nama file unik: timestamp + random.
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}.$ext';
      final dest = File('$photosDirPath/$fileName');

      await source.copy(dest.path);

      return FileResult.success(dest.path);
    } catch (e) {
      return FileResult.error('Gagal menyimpan foto: $e');
    }
  }

  /// Hapus file foto jika tidak lagi digunakan oleh produk mana pun.
  static Future<bool> deletePhotoIfUnused(
      String photoPath, List<String> activePaths) async {
    if (photoPath.isEmpty) return false;
    if (activePaths.contains(photoPath)) return false;

    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      // Abaikan error hapus file.
    }
    return false;
  }

  /// Generate string acak untuk nama file.
  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final result = StringBuffer();
    for (var i = 0; i < length; i++) {
      result.write(
          chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length]);
    }
    return result.toString();
  }

  /// Mendapatkan direktori untuk menyimpan file PDF struk dan laporan.
  static Future<String> getDocumentsDir() async {
    final appDir = await getAppDataDir();
    final docsDir = Directory('$appDir/documents');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir.path;
  }
}
