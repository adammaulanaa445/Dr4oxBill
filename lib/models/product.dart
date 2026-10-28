/// Model data produk atau jasa.
library product;

import '../core/constants/app_constants.dart';

class Product {
  final int? id;
  final String name;
  final String sku;
  final int? categoryId;
  final String itemType; // 'goods' atau 'service'
  final int costPrice; // dalam Rupiah (integer)
  final int sellingPrice; // dalam Rupiah (integer)
  final int stock;
  final int minStock;
  final String? photoPath;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.sku,
    this.categoryId,
    required this.itemType,
    this.costPrice = 0,
    required this.sellingPrice,
    this.stock = 0,
    this.minStock = 0,
    this.photoPath,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Apakah produk adalah barang fisik (memiliki stok).
  bool get isGoods => itemType == itemTypeGoods;

  /// Apakah produk adalah jasa (tidak memiliki stok fisik).
  bool get isService => itemType == itemTypeService;

  /// Apakah stok menipis (di bawah atau sama dengan batas minimum).
  bool get isLowStock => stock <= minStock;

  /// Buat Product dari map hasil query database.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      sku: map['sku'] as String,
      categoryId: map['category_id'] as int?,
      itemType: map['item_type'] as String,
      costPrice: map['cost_price'] as int,
      sellingPrice: map['selling_price'] as int,
      stock: map['stock'] as int,
      minStock: map['min_stock'] as int,
      photoPath: map['photo_path'] as String?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Konversi ke map untuk disimpan ke database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category_id': categoryId,
      'item_type': itemType,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'min_stock': minStock,
      'photo_path': photoPath,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Konversi ke map untuk insert (tanpa id).
  Map<String, dynamic> toMapForInsert() {
    return {
      'name': name,
      'sku': sku,
      'category_id': categoryId,
      'item_type': itemType,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'min_stock': minStock,
      'photo_path': photoPath,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, sku: $sku)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
