/// Layanan untuk menghasilkan struk PDF dan laporan.
library pdf_service;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/utils/money.dart';
import '../core/utils/date_utils.dart';
import '../core/constants/app_constants.dart';

/// Detail item untuk struk PDF.
class ReceiptItem {
  final String name;
  final int quantity;
  final int subtotal;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.subtotal,
  });
}

/// Hasil operasi PDF.
class PdfResult {
  final String? filePath;
  final String? error;
  final bool success;

  PdfResult._({
    this.filePath,
    this.error,
    this.success = false,
  });

  factory PdfResult.success(String filePath) {
    return PdfResult._(
      filePath: filePath,
      success: true,
    );
  }

  factory PdfResult.error(String error) {
    return PdfResult._(
      error: error,
      success: false,
    );
  }
}

class PdfService {
  /// Membuat struk PDF.
  ///
  /// Web: PDF dibuat di memori dan dibuka melalui dialog cetak browser.
  /// Windows/Android: PDF disimpan ke direktori lokal.
  Future<PdfResult> generateReceipt({
    required String transactionNumber,
    required DateTime transactionDate,
    required int subtotal,
    required int discount,
    required int total,
    required int cashReceived,
    required int changeAmount,
    required String paymentMethod,
    required List<ReceiptItem> items,
    required String outputDir,
    String businessName = defaultBusinessName,
    String businessAddress = '',
    String businessPhone = '',
    String thankYouMessage =
        'Terima kasih telah berkunjung ke Dr4ox Motor',
  }) async {
    try {
      final fileName = 'struk_$transactionNumber.pdf';

      // Siapkan path hanya untuk platform non-Web.
      String? filePath;

      if (!kIsWeb) {
        if (outputDir.trim().isEmpty) {
          return PdfResult.error(
            'Direktori penyimpanan struk tidak tersedia.',
          );
        }

        final dir = Directory(outputDir);

        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        filePath = path.join(outputDir, fileName);
      }

      // Muat logo Dr4ox Motor dari assets.
      // Cara ini dapat digunakan di Web dan Android.
      final logoData = await rootBundle.load(
        'assets/images/dr4ox.png',
      );

      final logoImage = pw.MemoryImage(
        logoData.buffer.asUint8List(),
      );

      // Buat dokumen PDF.
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            80 * PdfPageFormat.mm,
            200 * PdfPageFormat.mm,
          ),
          margin: const pw.EdgeInsets.all(10),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo resmi Dr4ox Motor.
                pw.Image(
                  logoImage,
                  width: 55,
                  height: 55,
                  fit: pw.BoxFit.contain,
                ),

                pw.SizedBox(height: 2),

                // Nama usaha.
                pw.Text(
                  businessName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                if (businessAddress.isNotEmpty)
                  pw.Text(
                    businessAddress,
                    style: const pw.TextStyle(
                      fontSize: 8,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                if (businessPhone.isNotEmpty)
                  pw.Text(
                    businessPhone,
                    style: const pw.TextStyle(
                      fontSize: 8,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 4),

                // Informasi transaksi.
                _receiptRow(
                  'No. Transaksi',
                  transactionNumber,
                ),
                _receiptRow(
                  'Tanggal',
                  formatDateTime(transactionDate),
                ),
                _receiptRow(
                  'Metode',
                  paymentMethod.toUpperCase(),
                ),

                pw.SizedBox(height: 4),
                pw.Divider(),
                pw.SizedBox(height: 4),

                // Daftar barang atau jasa.
                ...items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 2,
                    ),
                    child: pw.Row(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            '${item.name} (${item.quantity})',
                            style: const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            formatRupiah(item.subtotal),
                            style: const pw.TextStyle(
                              fontSize: 8,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 4),
                pw.Divider(),
                pw.SizedBox(height: 4),

                // Ringkasan pembayaran.
                _receiptRow(
                  'Subtotal',
                  formatRupiah(subtotal),
                ),
                _receiptRow(
                  'Diskon',
                  '-${formatRupiah(discount)}',
                ),
                _receiptRow(
                  'Total',
                  formatRupiah(total),
                  bold: true,
                ),
                _receiptRow(
                  'Tunai',
                  formatRupiah(cashReceived),
                ),
                _receiptRow(
                  'Kembalian',
                  formatRupiah(changeAmount),
                ),

                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 4),

                // Pesan penutup.
                pw.Text(
                  thankYouMessage,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      // Hasilkan PDF dalam bentuk bytes.
      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // WEB: tidak menggunakan File atau Directory.
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: fileName,
          format: PdfPageFormat(
            80 * PdfPageFormat.mm,
            200 * PdfPageFormat.mm,
          ),
        );

        // Penanda bahwa proses PDF Web telah dijalankan.
        // Ini bukan path file lokal.
        return PdfResult.success('browser:$fileName');
      }

      // WINDOWS / ANDROID: simpan PDF ke penyimpanan lokal.
      final nativeFilePath = filePath;

      if (nativeFilePath == null) {
        return PdfResult.error(
          'Path penyimpanan PDF tidak tersedia.',
        );
      }

      final file = File(nativeFilePath);

      await file.writeAsBytes(
        pdfBytes,
        flush: true,
      );

      return PdfResult.success(nativeFilePath);
    } catch (e) {
      return PdfResult.error(
        'Gagal generate PDF: $e',
      );
    }
  }

  /// Membuat baris informasi struk.
  pw.Widget _receiptRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: bold
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: bold
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Mencetak PDF yang sudah tersimpan.
  Future<bool> printPdf(String filePath) async {
    if (kIsWeb) {
      // Pada Web, PDF sudah diproses di generateReceipt().
      return true;
    }

    try {
      return await Printing.layoutPdf(
        onLayout: (_) async {
          return File(filePath).readAsBytes();
        },
      );
    } catch (_) {
      return false;
    }
  }
}