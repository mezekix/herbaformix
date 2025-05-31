import 'package:cloud_firestore/cloud_firestore.dart';
import './order_item_model.dart'; // OrderItemModel'i import et

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

class OrderModel {
  final String id; // Firestore doküman ID'si
  final String userId; // Bu siparişin hangi distribütöre ait olduğu (Auth User ID)
  final String customerId; // Siparişi veren müşteri ID'si
  final String customerName; // Müşteri adı (denormalized)
  final List<OrderItemModel> items; // Siparişteki ürünler
  final Timestamp orderDate;
  OrderStatus status;
  final double totalAmount; // Siparişin toplam tutarı
  final double totalVpEarned; // Siparişten kazanılan toplam VP
  String? notes; // Siparişle ilgili notlar
  String? shippingAddress; // Teslimat adresi (müşteriden farklı olabilir)

  OrderModel({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.orderDate,
    this.status = OrderStatus.pending,
    required this.totalAmount,
    required this.totalVpEarned,
    this.notes,
    this.shippingAddress,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    var itemsList = (map['items'] as List<dynamic>?)
            ?.map((itemMap) => OrderItemModel.fromMap(itemMap as Map<String, dynamic>))
            .toList() ??
        [];

    return OrderModel(
      id: documentId,
      userId: map['userId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'Bilinmeyen Müşteri',
      items: itemsList,
      orderDate: map['orderDate'] as Timestamp? ?? Timestamp.now(),
      status: OrderStatus.values.firstWhere(
          (e) => e.toString() == map['status'],
          orElse: () => OrderStatus.pending),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      totalVpEarned: (map['totalVpEarned'] ?? 0.0).toDouble(),
      notes: map['notes'] as String?,
      shippingAddress: map['shippingAddress'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'orderDate': orderDate,
      'status': status.toString(),
      'totalAmount': totalAmount,
      'totalVpEarned': totalVpEarned,
      'notes': notes,
      'shippingAddress': shippingAddress,
    };
  }
}