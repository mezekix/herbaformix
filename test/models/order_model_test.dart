import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/order_item_model.dart';
import 'package:herbaformix/models/order_model.dart';

void main() {
  group('OrderItemModel', () {
    test('fromMap doğru çevirir', () {
      final item = OrderItemModel.fromMap({
        'productId': 'p1',
        'productName': 'Formül 1',
        'quantity': 3,
        'unitPrice': 1500.0,
        'unitVp': 18.0,
      });
      expect(item.productId, 'p1');
      expect(item.productName, 'Formül 1');
      expect(item.quantity, 3);
      expect(item.unitPrice, 1500.0);
      expect(item.unitVp, 18.0);
    });

    test('eksik alanlar için varsayılan', () {
      final item = OrderItemModel.fromMap({});
      expect(item.productId, '');
      expect(item.productName, 'Bilinmeyen Ürün');
      expect(item.quantity, 0);
      expect(item.unitPrice, 0.0);
      expect(item.unitVp, 0.0);
    });

    test('int olarak gelen fiyat double\'a çevrilir', () {
      final item = OrderItemModel.fromMap({
        'productId': 'p',
        'productName': 'X',
        'quantity': 2,
        'unitPrice': 1500, // int
        'unitVp': 18, // int
      });
      expect(item.unitPrice, 1500.0);
      expect(item.unitVp, 18.0);
    });

    test('totalPrice = unitPrice * quantity', () {
      final item = OrderItemModel(
        productId: 'p',
        productName: 'X',
        quantity: 3,
        unitPrice: 1500.0,
        unitVp: 18.0,
      );
      expect(item.totalPrice, 4500.0);
    });

    test('totalVp = unitVp * quantity', () {
      final item = OrderItemModel(
        productId: 'p',
        productName: 'X',
        quantity: 3,
        unitPrice: 1500.0,
        unitVp: 18.0,
      );
      expect(item.totalVp, 54.0);
    });

    test('round-trip toMap → fromMap', () {
      final original = OrderItemModel(
        productId: 'p1',
        productName: 'Tea Mix',
        quantity: 2,
        unitPrice: 850.50,
        unitVp: 12.0,
      );
      final round = OrderItemModel.fromMap(original.toMap());
      expect(round.productId, original.productId);
      expect(round.productName, original.productName);
      expect(round.quantity, original.quantity);
      expect(round.unitPrice, original.unitPrice);
      expect(round.unitVp, original.unitVp);
    });
  });

  group('OrderModel', () {
    final testTimestamp = Timestamp.fromDate(DateTime(2026, 5, 10, 14, 0));

    Map<String, dynamic> baseMap() => {
          'userId': 'dist_1',
          'customerId': 'cust_1',
          'customerName': 'Ahmet Y.',
          'items': [
            {
              'productId': 'p1',
              'productName': 'Formül 1',
              'quantity': 2,
              'unitPrice': 1500.0,
              'unitVp': 18.0,
            },
          ],
          'orderDate': testTimestamp,
          'status': 'OrderStatus.processing',
          'totalAmount': 3000.0,
          'totalVpEarned': 36.0,
          'notes': 'Hızlı kargo',
          'shippingAddress': 'Adres satırı',
        };

    test('fromMap tüm alanları çevirir', () {
      final o = OrderModel.fromMap(baseMap(), 'order_1');
      expect(o.id, 'order_1');
      expect(o.userId, 'dist_1');
      expect(o.customerId, 'cust_1');
      expect(o.customerName, 'Ahmet Y.');
      expect(o.items.length, 1);
      expect(o.items[0].productId, 'p1');
      expect(o.orderDate, testTimestamp);
      expect(o.status, OrderStatus.processing);
      expect(o.totalAmount, 3000.0);
      expect(o.totalVpEarned, 36.0);
      expect(o.notes, 'Hızlı kargo');
      expect(o.shippingAddress, 'Adres satırı');
    });

    test('bilinmeyen status → varsayılan pending', () {
      final o = OrderModel.fromMap(baseMap()..['status'] = 'invalid', 'x');
      expect(o.status, OrderStatus.pending);
    });

    test('items boşsa boş liste döner', () {
      final o = OrderModel.fromMap({'orderDate': testTimestamp}, 'x');
      expect(o.items, isEmpty);
      expect(o.customerName, 'Bilinmeyen Müşteri');
    });

    test('eksik totalAmount → 0.0', () {
      final o = OrderModel.fromMap({'orderDate': testTimestamp}, 'x');
      expect(o.totalAmount, 0.0);
      expect(o.totalVpEarned, 0.0);
    });

    test('toMap tüm alanları yazar', () {
      final o = OrderModel(
        id: 'o',
        userId: 'dist_1',
        customerId: 'cust_1',
        customerName: 'A',
        items: [
          OrderItemModel(
            productId: 'p1',
            productName: 'F1',
            quantity: 2,
            unitPrice: 1500.0,
            unitVp: 18.0,
          ),
        ],
        orderDate: testTimestamp,
        totalAmount: 3000.0,
        totalVpEarned: 36.0,
        status: OrderStatus.delivered,
      );
      final map = o.toMap();
      expect(map['userId'], 'dist_1');
      expect(map['customerId'], 'cust_1');
      expect(map['status'], 'OrderStatus.delivered');
      expect(map['totalAmount'], 3000.0);
      expect(map['orderDate'], testTimestamp);
      expect((map['items'] as List).length, 1);
    });

    test('round-trip korunur', () {
      final original = OrderModel.fromMap(baseMap(), 'o');
      final round = OrderModel.fromMap(original.toMap(), 'o');
      expect(round.userId, original.userId);
      expect(round.customerName, original.customerName);
      expect(round.totalAmount, original.totalAmount);
      expect(round.status, original.status);
      expect(round.items.length, original.items.length);
    });
  });
}
