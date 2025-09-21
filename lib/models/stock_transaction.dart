enum StockTransactionType { stockIn, stockOut, adjustment }

class StockTransaction {
  final int? id;
  final int productId;
  final StockTransactionType type;
  final double quantity;
  final String reference;
  final DateTime date;

  StockTransaction({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.reference,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'type': type.name,
      'quantity': quantity,
      'reference': reference,
      'date': date.toIso8601String(),
    };
  }

  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id']?.toInt(),
      productId: map['product_id']?.toInt() ?? 0,
      type: StockTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StockTransactionType.stockIn,
      ),
      quantity: map['quantity']?.toDouble() ?? 0.0,
      reference: map['reference'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }

  StockTransaction copyWith({
    int? id,
    int? productId,
    StockTransactionType? type,
    double? quantity,
    String? reference,
    DateTime? date,
  }) {
    return StockTransaction(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reference: reference ?? this.reference,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'StockTransaction(id: $id, productId: $productId, type: $type, quantity: $quantity, reference: $reference)';
  }
}