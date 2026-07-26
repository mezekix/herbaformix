import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/inventory_movement_model.dart';
import 'package:herbaformix/models/order_item_model.dart';
import 'package:herbaformix/models/order_model.dart';
import 'package:herbaformix/services/repositories/inventory_repository.dart';

void main() {
  const distributorId = 'dist-1';

  InventoryMovementModel movement({
    required String id,
    required InventoryMovementType type,
    required int delta,
    required double cost,
  }) => InventoryMovementModel(
    id: id,
    productId: 'product-1',
    productName: 'Formula 1',
    type: type,
    quantityDelta: delta,
    unitCost: cost,
    occurredAt: Timestamp.now(),
    createdAt: Timestamp.now(),
  );

  OrderModel order({
    required String id,
    required OrderStatus status,
    List<OrderItemModel>? items,
    int inventoryCycle = 0,
  }) => OrderModel(
    id: id,
    userId: distributorId,
    customerId: 'customer-1',
    customerName: 'Test Customer',
    items:
        items ??
        [
          OrderItemModel(
            productId: 'product-1',
            productName: 'Formula 1',
            quantity: 2,
            unitPrice: 500,
            unitVp: 10,
          ),
        ],
    orderDate: Timestamp.now(),
    status: status,
    totalAmount: 1000,
    totalVpEarned: 20,
    inventoryCycle: inventoryCycle,
  );

  test('purchases calculate weighted average cost', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = InventoryRepository(firestore: firestore);

    await repository.recordMovement(
      distributorId,
      movement(
        id: 'purchase-1',
        type: InventoryMovementType.purchase,
        delta: 2,
        cost: 100,
      ),
    );
    await repository.recordMovement(
      distributorId,
      movement(
        id: 'purchase-2',
        type: InventoryMovementType.purchase,
        delta: 2,
        cost: 200,
      ),
    );

    final item = await repository
        .inventoryRef(distributorId)
        .doc('product-1')
        .get();
    expect(item.data()!.onHandQuantity, 4);
    expect(item.data()!.averageUnitCost, 150);
  });

  test(
    'personal use preserves average cost and rejects negative stock',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = InventoryRepository(firestore: firestore);
      await repository.recordMovement(
        distributorId,
        movement(
          id: 'initial',
          type: InventoryMovementType.initialCount,
          delta: 3,
          cost: 125,
        ),
      );
      await repository.recordMovement(
        distributorId,
        movement(
          id: 'personal',
          type: InventoryMovementType.personalUse,
          delta: -1,
          cost: 0,
        ),
      );

      final item = await repository
          .inventoryRef(distributorId)
          .doc('product-1')
          .get();
      expect(item.data()!.onHandQuantity, 2);
      expect(item.data()!.averageUnitCost, 125);
      final personalMovement = await repository
          .movementRef(distributorId)
          .doc('personal')
          .get();
      expect(personalMovement.data()!.unitCost, 125);

      await expectLater(
        repository.recordMovement(
          distributorId,
          movement(
            id: 'too-many',
            type: InventoryMovementType.personalUse,
            delta: -3,
            cost: 0,
          ),
        ),
        throwsStateError,
      );
    },
  );

  test('delivery and cancellation update order and stock atomically', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = InventoryRepository(firestore: firestore);
    await repository.recordMovement(
      distributorId,
      movement(
        id: 'initial',
        type: InventoryMovementType.initialCount,
        delta: 5,
        cost: 100,
      ),
    );
    final pending = order(id: 'order-1', status: OrderStatus.pending);
    await firestore
        .collection('users')
        .doc(distributorId)
        .collection('orders')
        .doc(pending.id)
        .set(pending.toMap());

    final delivered = await repository.updateOrderWithInventory(
      distributorId,
      order(id: pending.id, status: OrderStatus.delivered),
    );
    expect(delivered.inventoryCycle, 1);
    var item = await repository
        .inventoryRef(distributorId)
        .doc('product-1')
        .get();
    expect(item.data()!.onHandQuantity, 3);

    final cancelled = await repository.updateOrderWithInventory(
      distributorId,
      order(
        id: pending.id,
        status: OrderStatus.cancelled,
        inventoryCycle: delivered.inventoryCycle,
      ),
    );
    expect(cancelled.inventoryCycle, 1);
    item = await repository.inventoryRef(distributorId).doc('product-1').get();
    expect(item.data()!.onHandQuantity, 5);
  });

  test(
    'failed multi-product delivery leaves every stock balance unchanged',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = InventoryRepository(firestore: firestore);
      for (final product in const [
        ('product-1', 'Formula 1'),
        ('product-2', 'Tea'),
      ]) {
        await repository.recordMovement(
          distributorId,
          InventoryMovementModel(
            id: 'initial-${product.$1}',
            productId: product.$1,
            productName: product.$2,
            type: InventoryMovementType.initialCount,
            quantityDelta: product.$1 == 'product-1' ? 5 : 1,
            unitCost: 100,
            occurredAt: Timestamp.now(),
            createdAt: Timestamp.now(),
          ),
        );
      }
      final pending = order(
        id: 'order-atomic',
        status: OrderStatus.pending,
        items: [
          OrderItemModel(
            productId: 'product-1',
            productName: 'Formula 1',
            quantity: 2,
            unitPrice: 500,
            unitVp: 10,
          ),
          OrderItemModel(
            productId: 'product-2',
            productName: 'Tea',
            quantity: 2,
            unitPrice: 300,
            unitVp: 5,
          ),
        ],
      );
      await firestore
          .collection('users')
          .doc(distributorId)
          .collection('orders')
          .doc(pending.id)
          .set(pending.toMap());

      await expectLater(
        repository.updateOrderWithInventory(
          distributorId,
          order(
            id: pending.id,
            status: OrderStatus.delivered,
            items: pending.items,
          ),
        ),
        throwsStateError,
      );
      final product1 = await repository
          .inventoryRef(distributorId)
          .doc('product-1')
          .get();
      final product2 = await repository
          .inventoryRef(distributorId)
          .doc('product-2')
          .get();
      expect(product1.data()!.onHandQuantity, 5);
      expect(product2.data()!.onHandQuantity, 1);
    },
  );

  test('delivered order items require cancellation before editing', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = InventoryRepository(firestore: firestore);
    await repository.recordMovement(
      distributorId,
      movement(
        id: 'initial',
        type: InventoryMovementType.initialCount,
        delta: 5,
        cost: 100,
      ),
    );
    final pending = order(id: 'locked-order', status: OrderStatus.pending);
    await firestore
        .collection('users')
        .doc(distributorId)
        .collection('orders')
        .doc(pending.id)
        .set(pending.toMap());
    final delivered = await repository.updateOrderWithInventory(
      distributorId,
      order(id: pending.id, status: OrderStatus.delivered),
    );

    await expectLater(
      repository.updateOrderWithInventory(
        distributorId,
        order(
          id: pending.id,
          status: OrderStatus.delivered,
          inventoryCycle: delivered.inventoryCycle,
          items: [
            OrderItemModel(
              productId: 'product-1',
              productName: 'Formula 1',
              quantity: 3,
              unitPrice: 500,
              unitVp: 10,
            ),
          ],
        ),
      ),
      throwsStateError,
    );
    final stock = await repository
        .inventoryRef(distributorId)
        .doc('product-1')
        .get();
    expect(stock.data()!.onHandQuantity, 3);
  });
}
