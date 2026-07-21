import 'package:cloud_firestore/cloud_firestore.dart';

/// Distribütörün bir üründen elinde bulunan güncel fiziksel stoğu.
class InventoryItemModel {
  const InventoryItemModel({
    required this.productId,
    required this.productName,
    required this.onHandQuantity,
    required this.averageUnitCost,
    required this.updatedAt,
    this.stockNo,
  });

  final String productId;
  final String productName;
  final String? stockNo;
  final int onHandQuantity;
  final double averageUnitCost;
  final Timestamp updatedAt;

  bool get isLowStock => onHandQuantity < 3;

  factory InventoryItemModel.fromMap(Map<String, dynamic> map, String id) {
    return InventoryItemModel(
      productId: id,
      productName: map['productName'] as String? ?? 'Bilinmeyen Ürün',
      stockNo: map['stockNo'] as String?,
      onHandQuantity: (map['onHandQuantity'] as num? ?? 0).toInt(),
      averageUnitCost: (map['averageUnitCost'] as num? ?? 0).toDouble(),
      updatedAt: map['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'productName': productName,
        'stockNo': stockNo,
        'onHandQuantity': onHandQuantity,
        'averageUnitCost': averageUnitCost,
        'updatedAt': updatedAt,
      };
}
