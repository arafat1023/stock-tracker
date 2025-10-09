class Product {
  final int? id;
  final String name;
  final String unit;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(name.isNotEmpty, 'Product name cannot be empty'),
       assert(unit.isNotEmpty, 'Unit cannot be empty'),
       assert(price > 0, 'Price must be positive');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    // Validate required fields
    final name = map['name'] as String?;
    final unit = map['unit'] as String?;
    final price = map['price']?.toDouble();

    if (name == null || name.isEmpty) {
      throw ArgumentError('Product name cannot be null or empty');
    }
    if (unit == null || unit.isEmpty) {
      throw ArgumentError('Product unit cannot be null or empty');
    }
    if (price == null || price <= 0) {
      throw ArgumentError('Product price must be positive, got: $price');
    }

    return Product(
      id: map['id']?.toInt(),
      name: name,
      unit: unit,
      price: price,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? unit,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, unit: $unit, price: $price)';
  }
}