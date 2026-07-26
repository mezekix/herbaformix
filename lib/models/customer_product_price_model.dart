import 'package:cloud_firestore/cloud_firestore.dart';

/// Bir distribütörün belirli müşteriye belirli ürün için tanımladığı gizli fiyat.
class CustomerProductPriceModel {
  const CustomerProductPriceModel({
    required this.customerId,
    required this.productId,
    required this.price,
    required this.updatedAt,
  });

  final String customerId;
  final String productId;
  final double price;
  final Timestamp updatedAt;

  String get id => '${customerId}_$productId';

  factory CustomerProductPriceModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) => CustomerProductPriceModel(
    customerId: map['customerId'] as String? ?? '',
    productId: map['productId'] as String? ?? '',
    price: (map['price'] as num? ?? 0).toDouble(),
    updatedAt: map['updatedAt'] as Timestamp? ?? Timestamp.now(),
  );

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'productId': productId,
    'price': price,
    'updatedAt': updatedAt,
  };
}
