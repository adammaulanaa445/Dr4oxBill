/// Layanan untuk ekspor data ke format CSV.
library csv_service;

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;

import '../core/utils/date_utils.dart';
import '../core/utils/money.dart';
import 'file_service.dart';

/// Hasil ekspor CSV.
class CsvExportResult {
  final String? filePath;
  final String? error;
  final bool success;

  CsvExportResult._({this.filePath, this.error, this.success = false});

  factory CsvExportResult.success(String filePath) {
    return CsvExportResult._(filePath: filePath, success: true);
  }

  factory CsvExportResult.error(String error) {
    return CsvExportResult._(error: error, success: false);
  }
}

class CsvService {
  /// Ekspor daftar transaksi ke file CSV.
  ///
  /// [transactions] data transaksi dalam bentuk map.
  /// [items] detail item per transaksi (opsional, untuk ekspor detail).
  /// [outputDir] direktori tujuan.
  Future<CsvResult> exportTransactions({
    required List<Map<String, dynamic>> transactions,
    required String outputDir,
  }) async {
    try {
      final dir = Directory(outputDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final fileName =
          'laporan_transaksi_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = path.join(outputDir, fileName);

      final rows = <List<dynamic>>[
        [
          'No. Transaksi',
          'Tanggal',
          'Subtotal',
          'Diskon',
          'Total',
          'Tunai',
          'Kembalian',
          'Metode',
          'Status',
        ],
      ];

      for (final t in transactions) {
        rows.add([
          t['transaction_number'] ?? '',
          formatDateTime(parseDbDateTime(t['transaction_date'])),
          formatRupiah(t['subtotal'] ?? 0),
          formatRupiah(t['discount'] ?? 0),
          formatRupiah(t['total'] ?? 0),
          formatRupiah(t['cash_received'] ?? 0),
          formatRupiah(t['change_amount'] ?? 0),
          t['payment_method'] ?? '',
          t['status'] ?? '',
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final file = File(filePath);
      await file.writeAsString(csv);

      return CsvResult.success(filePath);
    } catch (e) {
      return CsvResult.error('Gagal ekspor CSV: $e');
    }
  }

  /// Ekspor pergerakan stok ke file CSV.
  Future<CsvResult> exportStockMovements({
    required List<Map<String, dynamic>> movements,
    required String outputDir,
  }) async {
    try {
      final dir = Directory(outputDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final fileName =
          'laporan_stok_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = path.join(outputDir, fileName);

      final rows = <List<dynamic>>[
        [
          'Produk',
          'Tanggal',
          'Jenis',
          'Perubahan',
          'Stok Sebelum',
          'Stok Sesudah',
          'Alasan',
        ],
      ];

      for (final m in movements) {
        rows.add([
          m['product_name'] ?? '',
          formatDateTime(parseDbDateTime(m['created_at'])),
          m['movement_type'] ?? '',
          m['quantity_change'] ?? 0,
          m['stock_before'] ?? 0,
          m['stock_after'] ?? 0,
          m['reason'] ?? '',
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final file = File(filePath);
      await file.writeAsString(csv);

      return CsvResult.success(filePath);
    } catch (e) {
      return CsvResult.error('Gagal ekspor CSV: $e');
    }
  }
}

/// Alias untuk kompatibilitas nama kelas.
typedef CsvResult = CsvExportResult;
