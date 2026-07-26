import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/inventory_item_model.dart';
import '../../models/inventory_movement_model.dart';
import '../../models/order_item_model.dart';
import '../../models/order_model.dart';

/// Distribütöre özel stok bakiyesi ve değiştirilemez hareket defteri.
class InventoryRepository {
  InventoryRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<InventoryItemModel> inventoryRef(String distributorId) =>
      _db
          .collection('users')
          .doc(distributorId)
          .collection('inventory')
          .withConverter(
            fromFirestore: (snapshot, _) =>
                InventoryItemModel.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (model, _) => model.toMap(),
          );

  CollectionReference<InventoryMovementModel> movementRef(
    String distributorId,
  ) => _db
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

  Stream<List<InventoryMovementModel>> watchMovements(String distributorId) {
    return movementRef(distributorId)
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
      throw ArgumentError.value(
        movement.quantityDelta,
        'quantityDelta',
        'Sıfır olamaz',
      );
    }
    if (movement.unitCost < 0) {
      throw ArgumentError.value(
        movement.unitCost,
        'unitCost',
        'Negatif olamaz',
      );
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

      final isIncomingWithCost =
          movement.quantityDelta > 0 &&
          (movement.type == InventoryMovementType.initialCount ||
              movement.type == InventoryMovementType.purchase);
      final nextAverageCost = isIncomingWithCost
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
        unitCost: isIncomingWithCost ? movement.unitCost : nextAverageCost,
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

  /// Sipariş durumunu ve bu duruma bağlı tüm stok hareketlerini tek transaction
  /// içinde kaydeder. Herhangi bir üründe stok yetersizse hiçbir belge değişmez.
  Future<OrderModel> updateOrderWithInventory(
    String distributorId,
    OrderModel requestedOrder,
  ) async {
    final orderRef = _db
        .collection('users')
        .doc(distributorId)
        .collection('orders')
        .doc(requestedOrder.id)
        .withConverter<OrderModel>(
          fromFirestore: (snapshot, _) =>
              OrderModel.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (model, _) => model.toMap(),
        );

    return _db.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final previousOrder = orderSnapshot.data();
      if (previousOrder == null) {
        throw StateError('Sipariş bulunamadı.');
      }

      final wasDelivered = previousOrder.status == OrderStatus.delivered;
      final willBeDelivered = requestedOrder.status == OrderStatus.delivered;
      final isDelivery = !wasDelivered && willBeDelivered;
      final isReversal = wasDelivered && !willBeDelivered;
      if (wasDelivered &&
          willBeDelivered &&
          !_hasSameInventoryItems(previousOrder.items, requestedOrder.items)) {
        throw StateError(
          'Teslim edilmiş siparişin ürünleri değiştirilemez. '
          'Önce siparişi iptal ederek stoğu geri alın.',
        );
      }
      final cycle = isDelivery
          ? previousOrder.inventoryCycle + 1
          : previousOrder.inventoryCycle;
      final sourceItems = isReversal
          ? previousOrder.items
          : requestedOrder.items;

      final effectiveOrder = OrderModel(
        id: requestedOrder.id,
        userId: requestedOrder.userId,
        customerId: requestedOrder.customerId,
        customerName: requestedOrder.customerName,
        items: requestedOrder.items,
        orderDate: requestedOrder.orderDate,
        status: requestedOrder.status,
        totalAmount: requestedOrder.totalAmount,
        totalVpEarned: requestedOrder.totalVpEarned,
        notes: requestedOrder.notes,
        shippingAddress: requestedOrder.shippingAddress,
        paymentStatus: requestedOrder.paymentStatus,
        paidAmount: requestedOrder.paidAmount,
        paymentMethod: requestedOrder.paymentMethod,
        inventoryCycle: cycle,
      );

      if (!isDelivery && !isReversal) {
        transaction.set(orderRef, effectiveOrder);
        return effectiveOrder;
      }

      final seenProductIds = <String>{};
      for (final item in sourceItems) {
        if (!seenProductIds.add(item.productId)) {
          throw StateError('Siparişte aynı ürün birden fazla satırda olamaz.');
        }
      }

      final itemRefs = [
        for (final item in sourceItems)
          inventoryRef(distributorId).doc(item.productId),
      ];
      final movementRefs = [
        for (final item in sourceItems)
          movementRef(distributorId).doc(
            '${isDelivery ? 'sale' : 'return'}_${requestedOrder.id}_${cycle}_${item.productId}',
          ),
      ];

      final movementSnapshots = <DocumentSnapshot<InventoryMovementModel>>[];
      for (final ref in movementRefs) {
        movementSnapshots.add(await transaction.get(ref));
      }
      if (movementSnapshots.any((snapshot) => snapshot.exists)) {
        throw StateError('Bu siparişin stok hareketi daha önce işlendi.');
      }

      final itemSnapshots = <DocumentSnapshot<InventoryItemModel>>[];
      for (final ref in itemRefs) {
        itemSnapshots.add(await transaction.get(ref));
      }

      final now = Timestamp.now();
      final nextItems = <InventoryItemModel>[];
      final movements = <InventoryMovementModel>[];
      for (var index = 0; index < sourceItems.length; index++) {
        final orderItem = sourceItems[index];
        final previousItem = itemSnapshots[index].data();
        final oldQuantity = previousItem?.onHandQuantity ?? 0;
        final delta = isDelivery ? -orderItem.quantity : orderItem.quantity;
        final nextQuantity = oldQuantity + delta;
        if (nextQuantity < 0) {
          throw StateError('${orderItem.productName} için yeterli stok yok.');
        }
        final averageCost = previousItem?.averageUnitCost ?? 0;
        nextItems.add(
          InventoryItemModel(
            productId: orderItem.productId,
            productName: orderItem.productName,
            stockNo: previousItem?.stockNo,
            onHandQuantity: nextQuantity,
            averageUnitCost: averageCost,
            updatedAt: now,
          ),
        );
        movements.add(
          InventoryMovementModel(
            id: movementRefs[index].id,
            productId: orderItem.productId,
            productName: orderItem.productName,
            stockNo: previousItem?.stockNo,
            type: isDelivery
                ? InventoryMovementType.sale
                : InventoryMovementType.customerReturn,
            quantityDelta: delta,
            unitCost: averageCost,
            occurredAt: now,
            createdAt: now,
            referenceId: requestedOrder.id,
          ),
        );
      }
      for (var index = 0; index < sourceItems.length; index++) {
        transaction.set(itemRefs[index], nextItems[index]);
        transaction.set(movementRefs[index], movements[index]);
      }
      transaction.set(orderRef, effectiveOrder);
      return effectiveOrder;
    });
  }

  bool _hasSameInventoryItems(
    List<OrderItemModel> previous,
    List<OrderItemModel> requested,
  ) {
    if (previous.length != requested.length) return false;
    final quantities = <String, int>{};
    for (final item in previous) {
      if (quantities.containsKey(item.productId)) return false;
      quantities[item.productId] = item.quantity;
    }
    for (final item in requested) {
      if (quantities[item.productId] != item.quantity) return false;
    }
    return true;
  }
}
