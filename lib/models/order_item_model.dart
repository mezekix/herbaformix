class OrderItemModel {
  final String productId; // Satılan ürünün ID'si
  final String
  productName; // Satılan ürünün adı (denormalized for easy display)
  final int quantity; // Adet
  final double unitPrice; // Birim fiyat (satış anındaki)
  final double unitVp; // Birim VP (satış anındaki)

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitVp,
  });

  // Toplam fiyatı hesapla
  double get totalPrice => unitPrice * quantity;
  // Toplam VP'yi hesapla
  double get totalVp => unitVp * quantity;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? 'Bilinmeyen Ürün',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      unitVp: (map['unitVp'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitVp': unitVp,
    };
  }
}
