/// Utilitas perhitungan uang dalam satuan Rupiah (integer).
///
/// Semua nilai uang disimpan sebagai integer dalam satuan Rupiah terkecil
/// untuk menghindari kesalahan presisi floating-point.
library money;

import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Format nilai integer Rupiah menjadi string tampilan, misal "Rp 15.000".
String formatRupiah(int amount) {
  final formatter = NumberFormat('#,##0', 'id_ID');
  return '$currencySymbol ${formatter.format(amount)}';
}

/// Format nilai integer Rupiah menjadi string tanpa simbol, misal "15.000".
String formatRupiahPlain(int amount) {
  final formatter = NumberFormat('#,##0', 'id_ID');
  return formatter.format(amount);
}

/// Parse string input pengguna (misal "15.000" atau "15000") menjadi integer.
/// Mengembalikan null jika input tidak valid.
int? parseRupiah(String? input) {
  if (input == null || input.trim().isEmpty) {
    return null;
  }

  // Hapus simbol Rp, titik pemisah ribuan, dan spasi.
  String cleaned = input
      .replaceAll('Rp', '')
      .replaceAll('rp', '')
      .replaceAll('.', '')
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .trim();

  if (cleaned.isEmpty) {
    return null;
  }

  final value = int.tryParse(cleaned);
  return value;
}

/// Hitung kembalian: uang diterima dikurangi total harus dibayar.
/// Mengembalikan null jika uang diterima kurang dari total.
int? calculateChange(int cashReceived, int total) {
  if (cashReceived < total) {
    return null;
  }
  return cashReceived - total;
}

/// Hitung subtotal item: harga satuan dikurangi diskon, dikalikan kuantitas.
int calculateItemSubtotal(int unitPrice, int quantity, int discount) {
  final unitAfterDiscount = (unitPrice - discount).clamp(0, unitPrice);
  return unitAfterDiscount * quantity;
}

/// Hitung total keseluruhan dari daftar subtotal item.
int calculateGrandTotal(List<int> subtotals) {
  return subtotals.fold(0, (sum, subtotal) => sum + subtotal);
}

/// Hitung total setelah diskon transaksi.
int calculateTotalAfterDiscount(int grandTotal, int discount) {
  return (grandTotal - discount).clamp(0, grandTotal);
}
