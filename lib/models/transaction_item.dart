/// Model data detail item dalam suatu transaksi.
library transaction_item;

class TransactionItem {
  final int? id;
  final int transactionId;
  final int? productId;
  final String sku;
  final String name;
  final String itemType; // 'goods' atau 'service'
  final int quantity;
  final int unitPrice; // harga pada saat transaksi (historical)
  final int subtotal;
  final int discount;

  TransactionItem({
    this.id,
    required this.transactionId,
    this.productId,
    required this.sku,
    required this.name,
    required this.itemType,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.discount = 0,
  });

  /// Buat TransactionItem dari map hasil query database.
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int,
      productId: map['product_id'] as int?,
      sku: map['sku'] as String,
      name: map['name'] as String,
      itemType: map['item_type'] as String,
      quantity: map['quantity'] as int,
      unitPrice: map['unit_price'] as int,
      subtotal: map['subtotal'] as int,
      discount: map['discount'] as int,
    );
  }

  /// Konversi ke map untuk disimpan ke database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'sku': sku,
      'name': name,
      'item_type': itemType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'discount': discount,
    };
  }

  /// Konversi ke map untuk insert (tanpa id).
  Map<String, dynamic> toMapForInsert() {
    return {
      'transaction_id': transactionId,
      'product_id': productId,
      'sku': sku,
      'name': name,
      'item_type': itemType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'discount': discount,
    };
  }

  @override
  String toString() {
    return 'TransactionItem(id: $id, name: $name, qty: $quantity)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
