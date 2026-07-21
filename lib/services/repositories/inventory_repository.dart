import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/inventory_item_model.dart';
import '../../models/inventory_movement_model.dart';

/// Distribütöre özel stok bakiyesi ve değiştirilemez hareket defteri.
class InventoryRepository {
  InventoryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<InventoryItemModel> inventoryRef(String distributorId) =>
      _db.collection('users').doc(distributorId).collection('inventory').withConverter(
            fromFirestore: (snapshot, _) =>
                InventoryItemModel.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (model, _) => model.toMap(),
          );

  CollectionReference<InventoryMovementModel> movementRef(
    String distributorId,
  ) =>
      _db
          .collection('users')
          .doc(distributorId)
          .collection('inventoryMovements')
          .withConverter(
            fromFirestore: (snapshot, _) =>
                InventoryMovementModel.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (model, _) => model.toMap(),
          );

  Stream<List<InventoryItemModel>> watchInventory(String distributorId) =>
      inventoryRef(distributorId)
          .orderBy('productName')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Stream<List<InventoryMovementModel>> watchMovements(
    String distributorId, {
    String? productId,
  }) {
    Query<InventoryMovementModel> query = movementRef(distributorId);
    if (productId != null && productId.isNotEmpty) {
      query = query.where('productId', isEqualTo: productId);
    }
    return query
        .orderBy('occurredAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Hareketi ve stok bakiyesini aynı transaction içinde günceller.
  /// [movementId] tekrar kullanılırsa ikinci kez stok değiştirmez.
  Future<void> recordMovement(
    String distributorId,
    InventoryMovementModel movement,
  ) async {
    if (movement.quantityDelta == 0) {
      throw ArgumentError.value(movement.quantityDelta, 'quantityDelta', 'Sıfır olamaz');
    }
    if (movement.unitCost < 0) {
      throw ArgumentError.value(movement.unitCost, 'unitCost', 'Negatif olamaz');
    }

    final itemDoc = inventoryRef(distributorId).doc(movement.productId);
    final movementDoc = movementRef(distributorId).doc(movement.id);

    await _db.runTransaction((transaction) async {
      final priorMovement = await transaction.get(movementDoc);
      if (priorMovement.exists) {
        throw StateError('Bu stok hareketi daha önce işlendi.');
      }

      final itemSnapshot = await transaction.get(itemDoc);
      final previous = itemSnapshot.data();
      final oldQuantity = previous?.onHandQuantity ?? 0;
      final nextQuantity = oldQuantity + movement.quantityDelta;
      if (nextQuantity < 0) {
        throw StateError('${movement.productName} için yeterli stok yok.');
      }

      final isIncoming = movement.quantityDelta > 0;
      final nextAverageCost = isIncoming
          ? ((oldQuantity * (previous?.averageUnitCost ?? 0)) +
                  (movement.quantityDelta * movement.unitCost)) /
              nextQuantity
          : (previous?.averageUnitCost ?? movement.unitCost);

      final movementWithEffectiveCost = InventoryMovementModel(
        id: movement.id,
        productId: movement.productId,
        productName: movement.productName,
        stockNo: movement.stockNo,
        type: movement.type,
        quantityDelta: movement.quantityDelta,
        unitCost: isIncoming ? movement.unitCost : nextAverageCost,
        occurredAt: movement.occurredAt,
        createdAt: movement.createdAt,
        referenceId: movement.referenceId,
        note: movement.note,
      );
      final nextItem = InventoryItemModel(
        productId: movement.productId,
        productName: movement.productName,
        stockNo: movement.stockNo ?? previous?.stockNo,
        onHandQuantity: nextQuantity,
        averageUnitCost: nextAverageCost,
        updatedAt: Timestamp.now(),
      );

      transaction.set(itemDoc, nextItem);
      transaction.set(movementDoc, movementWithEffectiveCost);
    });
  }
}
