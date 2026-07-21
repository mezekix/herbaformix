import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryMovementType {
  initialCount,
  purchase,
  sale,
  personalUse,
  adjustmentIncrease,
  adjustmentDecrease,
  customerReturn,
}

/// Stok değişikliklerinin değiştirilmeyen denetim kaydı.
class InventoryMovementModel {
  const InventoryMovementModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantityDelta,
    required this.unitCost,
    required this.occurredAt,
    required this.createdAt,
    this.stockNo,
    this.referenceId,
    this.note,
  });

  final String id;
  final String productId;
  final String productName;
  final String? stockNo;
  final InventoryMovementType type;
  final int quantityDelta;
  final double unitCost;
  final Timestamp occurredAt;
  final Timestamp createdAt;
  final String? referenceId;
  final String? note;

  factory InventoryMovementModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    final typeName = map['type'] as String? ?? InventoryMovementType.purchase.name;
    return InventoryMovementModel(
      id: id,
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? 'Bilinmeyen Ürün',
      stockNo: map['stockNo'] as String?,
      type: InventoryMovementType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => InventoryMovementType.purchase,
      ),
      quantityDelta: (map['quantityDelta'] as num? ?? 0).toInt(),
      unitCost: (map['unitCost'] as num? ?? 0).toDouble(),
      occurredAt: map['occurredAt'] as Timestamp? ?? Timestamp.now(),
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      referenceId: map['referenceId'] as String?,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'stockNo': stockNo,
        'type': type.name,
        'quantityDelta': quantityDelta,
        'unitCost': unitCost,
        'occurredAt': occurredAt,
        'createdAt': createdAt,
        'referenceId': referenceId,
        'note': note,
      };
}
