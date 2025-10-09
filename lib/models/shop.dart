class Shop {
  final int? id;
  final String name;
  final String address;
  final String contact;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shop({
    this.id,
    required this.name,
    required this.address,
    required this.contact,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(name.isNotEmpty, 'Shop name cannot be empty'),
       assert(address.isNotEmpty, 'Shop address cannot be empty');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contact': contact,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    // Validate required fields
    final name = map['name'] as String?;
    final address = map['address'] as String?;

    if (name == null || name.isEmpty) {
      throw ArgumentError('Shop name cannot be null or empty');
    }
    if (address == null || address.isEmpty) {
      throw ArgumentError('Shop address cannot be null or empty');
    }

    return Shop(
      id: map['id']?.toInt(),
      name: name,
      address: address,
      contact: map['contact'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Shop copyWith({
    int? id,
    String? name,
    String? address,
    String? contact,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Shop(id: $id, name: $name, address: $address, contact: $contact)';
  }
}