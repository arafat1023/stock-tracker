enum DeliveryStatus { pending, completed, cancelled }

class Delivery {
  final int? id;
  final int shopId;
  final DateTime deliveryDate;
  final double totalAmount;
  final DeliveryStatus status;
  final String notes;

  Delivery({
    this.id,
    required this.shopId,
    required this.deliveryDate,
    required this.totalAmount,
    required this.status,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'delivery_date': deliveryDate.toIso8601String(),
      'total_amount': totalAmount,
      'status': status.name,
      'notes': notes,
    };
  }

  factory Delivery.fromMap(Map<String, dynamic> map) {
    return Delivery(
      id: map['id']?.toInt(),
      shopId: map['shop_id']?.toInt() ?? 0,
      deliveryDate: DateTime.parse(map['delivery_date']),
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      notes: map['notes'] ?? '',
    );
  }

  Delivery copyWith({
    int? id,
    int? shopId,
    DateTime? deliveryDate,
    double? totalAmount,
    DeliveryStatus? status,
    String? notes,
  }) {
    return Delivery(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Delivery(id: $id, shopId: $shopId, deliveryDate: $deliveryDate, totalAmount: $totalAmount, status: $status)';
  }
}