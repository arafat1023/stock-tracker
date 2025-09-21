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
  });

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
    return DeliveryItem(
      id: map['id']?.toInt(),
      deliveryId: map['delivery_id']?.toInt() ?? 0,
      productId: map['product_id']?.toInt() ?? 0,
      quantity: map['quantity']?.toDouble() ?? 0.0,
      unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      totalPrice: map['total_price']?.toDouble() ?? 0.0,
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