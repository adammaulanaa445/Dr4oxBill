/// Pembuat struk PDF dan dialog cetak/pratinjau.
library receipt_service;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/utils/money.dart';

/// Satu baris item pada struk.
class ReceiptLine {
  final String name;
  final int quantity;
  final int unitPrice;
  final int subtotal;

  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}

class ReceiptService {
  /// Ukuran kertas struk. Untuk printer biasa ganti ke PdfPageFormat.a5
  /// atau PdfPageFormat.a4. Untuk thermal 58mm ganti ke PdfPageFormat.roll57.
  static const PdfPageFormat format = PdfPageFormat.roll80;

  /// Buat struk lalu tampilkan pratinjau/dialog cetak.
  /// Melempar exception bila gagal; pemanggil yang menampilkan pesan error.
  static Future<void> showReceipt({
    required String businessName,
    required String businessAddress,
    required String businessPhone,
    required String thankYouMessage,
    required String transactionNumber,
    required DateTime transactionDate,
    required int subtotal,
    required int discount,
    required int total,
    required int cashReceived,
    required int changeAmount,
    required String paymentMethod,
    required List<ReceiptLine> items,
  }) async {
    final bytes = await _build(
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      thankYouMessage: thankYouMessage,
      transactionNumber: transactionNumber,
      transactionDate: transactionDate,
      subtotal: subtotal,
      discount: discount,
      total: total,
      cashReceived: cashReceived,
      changeAmount: changeAmount,
      paymentMethod: paymentMethod,
      items: items,
    );

    await Printing.layoutPdf(
      name: transactionNumber,
      format: format,
      onLayout: (_) async => bytes,
    );
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  static String paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      default:
        return method;
    }
  }

  static Future<Uint8List> _build({
    required String businessName,
    required String businessAddress,
    required String businessPhone,
    required String thankYouMessage,
    required String transactionNumber,
    required DateTime transactionDate,
    required int subtotal,
    required int discount,
    required int total,
    required int cashReceived,
    required int changeAmount,
    required String paymentMethod,
    required List<ReceiptLine> items,
  }) async {
    final doc = pw.Document();

    pw.Widget row(String left, String right, {bool bold = false}) {
      final style = pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(left, style: style),
          pw.Text(right, style: style),
        ],
      );
    }

    pw.Widget divider() => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Divider(
            height: 1,
            thickness: 0.5,
            borderStyle: pw.BorderStyle.dashed,
          ),
        );

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                businessName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (businessAddress.trim().isNotEmpty)
                pw.Text(
                  businessAddress,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              if (businessPhone.trim().isNotEmpty)
                pw.Text(
                  businessPhone,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              divider(),
              row('No', transactionNumber),
              row('Tanggal', _formatDate(transactionDate)),
              row('Bayar', paymentLabel(paymentMethod)),
              divider(),
              ...items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.name,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      row('${item.quantity} x ${formatRupiah(item.unitPrice)}',
                          formatRupiah(item.subtotal)),
                    ],
                  ),
                );
              }),
              divider(),
              row('Subtotal', formatRupiah(subtotal)),
              if (discount > 0) row('Diskon', '-${formatRupiah(discount)}'),
              row('TOTAL', formatRupiah(total), bold: true),
              row('Uang diterima', formatRupiah(cashReceived)),
              row('Kembalian', formatRupiah(changeAmount)),
              divider(),
              pw.SizedBox(height: 4),
              pw.Text(
                thankYouMessage,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}