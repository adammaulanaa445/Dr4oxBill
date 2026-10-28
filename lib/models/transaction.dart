/// Model data transaksi penjualan.
library transaction;

import 'transaction_item.dart';

class Transaction {
  final int? id;
  final String transactionNumber;
  final DateTime transactionDate;
  final int subtotal;
  final int discount;
  final int total;
  final int cashReceived;
  final int changeAmount;
  final String paymentMethod;
  final String status; // 'completed' atau 'cancelled'
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final List<TransactionItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.transactionNumber,
    required this.transactionDate,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.cashReceived,
    required this.changeAmount,
    required this.paymentMethod,
    this.status = 'completed',
    this.cancellationReason,
    this.cancelledAt,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Apakah transaksi sudah dibatalkan.
  bool get isCancelled => status == 'cancelled';

  /// Buat Transaction dari map hasil query database (tanpa items).
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      transactionNumber: map['transaction_number'] as String,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      subtotal: map['subtotal'] as int,
      discount: map['discount'] as int,
      total: map['total'] as int,
      cashReceived: map['cash_received'] as int,
      changeAmount: map['change_amount'] as int,
      paymentMethod: map['payment_method'] as String,
      status: map['status'] as String,
      cancellationReason: map['cancellation_reason'] as String?,
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.parse(map['cancelled_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Konversi ke map untuk disimpan ke database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_number': transactionNumber,
      'transaction_date': transactionDate.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'cash_received': cashReceived,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'status': status,
      'cancellation_reason': cancellationReason,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Konversi ke map untuk insert (tanpa id).
  Map<String, dynamic> toMapForInsert() {
    return {
      'transaction_number': transactionNumber,
      'transaction_date': transactionDate.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'cash_received': cashReceived,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'status': status,
      'cancellation_reason': cancellationReason,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Transaction(id: $id, number: $transactionNumber, total: $total)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
