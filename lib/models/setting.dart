/// Model data pengaturan aplikasi (key-value).
library setting;

class Setting {
  final String key;
  final String value;
  final DateTime updatedAt;

  Setting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  /// Buat Setting dari map hasil query database.
  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(
      key: map['key'] as String,
      value: map['value'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Konversi ke map untuk disimpan ke database.
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Setting(key: $key, value: $value)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Setting && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;
}
