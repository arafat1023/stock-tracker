class DeliveryItem {
  final int? id;
  final int deliveryId;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  DeliveryItem({
    this.id,
    required this.deliveryId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  }) : assert(quantity > 0, 'Quantity must be positive'),
       assert(unitPrice > 0, 'Unit price must be positive'),
       assert(totalPrice >= 0, 'Total price must be non-negative');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory DeliveryItem.fromMap(Map<String, dynamic> map) {
    // Validate required numeric fields to prevent assertion failures
    final quantity = map['quantity']?.toDouble();
    final unitPrice = map['unit_price']?.toDouble();
    final totalPrice = map['total_price']?.toDouble();

    if (quantity == null || quantity <= 0) {
      throw ArgumentError('DeliveryItem quantity must be positive, got: $quantity');
    }
    if (unitPrice == null || unitPrice <= 0) {
      throw ArgumentError('DeliveryItem unitPrice must be positive, got: $unitPrice');
    }
    if (totalPrice == null || totalPrice < 0) {
      throw ArgumentError('DeliveryItem totalPrice must be non-negative, got: $totalPrice');
    }

    return DeliveryItem(
      id: map['id']?.toInt(),
      deliveryId: map['delivery_id']?.toInt() ?? 0,
      productId: map['product_id']?.toInt() ?? 0,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }

  DeliveryItem copyWith({
    int? id,
    int? deliveryId,
    int? productId,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return DeliveryItem(
      id: id ?? this.id,
      deliveryId: deliveryId ?? this.deliveryId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  String toString() {
    return 'DeliveryItem(id: $id, deliveryId: $deliveryId, productId: $productId, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice)';
  }
}