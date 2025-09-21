class Return {
  final int? id;
  final int shopId;
  final int productId;
  final double quantity;
  final DateTime returnDate;
  final String reason;

  Return({
    this.id,
    required this.shopId,
    required this.productId,
    required this.quantity,
    required this.returnDate,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'product_id': productId,
      'quantity': quantity,
      'return_date': returnDate.toIso8601String(),
      'reason': reason,
    };
  }

  factory Return.fromMap(Map<String, dynamic> map) {
    return Return(
      id: map['id']?.toInt(),
      shopId: map['shop_id']?.toInt() ?? 0,
      productId: map['product_id']?.toInt() ?? 0,
      quantity: map['quantity']?.toDouble() ?? 0.0,
      returnDate: DateTime.parse(map['return_date']),
      reason: map['reason'] ?? '',
    );
  }

  Return copyWith({
    int? id,
    int? shopId,
    int? productId,
    double? quantity,
    DateTime? returnDate,
    String? reason,
  }) {
    return Return(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      returnDate: returnDate ?? this.returnDate,
      reason: reason ?? this.reason,
    );
  }

  @override
  String toString() {
    return 'Return(id: $id, shopId: $shopId, productId: $productId, quantity: $quantity, returnDate: $returnDate, reason: $reason)';
  }
}