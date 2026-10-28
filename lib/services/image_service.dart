/// Layanan untuk memproses dan memvalidasi gambar produk.
library image_service;

import 'dart:io';

import 'package:image/image.dart' as img;

import 'file_service.dart';

/// Hasil validasi gambar.
class ImageValidationResult {
  final bool isValid;
  final String? error;
  final int width;
  final int height;

  ImageValidationResult._({
    required this.isValid,
    this.error,
    required this.width,
    required this.height,
  });

  factory ImageValidationResult.valid({int width = 0, int height = 0}) {
    return ImageValidationResult._(
      isValid: true,
      error: null,
      width: width,
      height: height,
    );
  }

  factory ImageValidationResult.invalid(String error) {
    return ImageValidationResult._(
      isValid: false,
      error: error,
      width: 0,
      height: 0,
    );
  }
}

class ImageService {
  /// Validasi file gambar: tipe dan ukuran.
  static Future<ImageValidationResult> validateImage(File file) async {
    if (!await file.exists()) {
      return ImageValidationResult.invalid('File gambar tidak ditemukan.');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final allowedTypes = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];
    if (!allowedTypes.contains(ext)) {
      return ImageValidationResult.invalid(
        'Tipe file gambar tidak didukung ($ext). Gunakan JPG, PNG, atau WEBP.',
      );
    }

    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      return ImageValidationResult.invalid(
        'Ukuran gambar terlalu besar (maksimal 5 MB).',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return ImageValidationResult.invalid(
            'File gambar rusak atau tidak dapat dibaca.');
      }
      return ImageValidationResult.valid(
          width: image.width, height: image.height);
    } catch (e) {
      return ImageValidationResult.invalid('Gagal membaca file gambar: $e');
    }
  }

  /// Cek apakah file gambar masih ada di disk.
  static Future<bool> imageExists(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return false;
    return await File(photoPath).exists();
  }
}
