/// Model data riwayat pergerakan stok produk.
library stock_movement;

class StockMovement {
  final int? id;
  final int productId;
  final String movementType; // 'in', 'out', 'adjustment', 'sale', 'return'
  final int quantityChange;
  final int stockBefore;
  final int stockAfter;
  final String? reason;
  final String? referenceType;
  final int? referenceId;
  final DateTime createdAt;

  StockMovement({
    this.id,
    required this.productId,
    required this.movementType,
    required this.quantityChange,
    required this.stockBefore,
    required this.stockAfter,
    this.reason,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  /// Buat StockMovement dari map hasil query database.
  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      movementType: map['movement_type'] as String,
      quantityChange: map['quantity_change'] as int,
      stockBefore: map['stock_before'] as int,
      stockAfter: map['stock_after'] as int,
      reason: map['reason'] as String?,
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Konversi ke map untuk disimpan ke database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'movement_type': movementType,
      'quantity_change': quantityChange,
      'stock_before': stockBefore,
      'stock_after': stockAfter,
      'reason': reason,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Konversi ke map untuk insert (tanpa id).
  Map<String, dynamic> toMapForInsert() {
    return {
      'product_id': productId,
      'movement_type': movementType,
      'quantity_change': quantityChange,
      'stock_before': stockBefore,
      'stock_after': stockAfter,
      'reason': reason,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'StockMovement(id: $id, productId: $productId, type: $movementType, change: $quantityChange)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
