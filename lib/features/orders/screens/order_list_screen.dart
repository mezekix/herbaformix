import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için EKLENDİ
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/order_provider.dart';
import './add_edit_order_screen.dart';
import '../../../models/order_model.dart';

class OrderListScreen extends StatelessWidget {
  static const String routeName = '/orders';
  const OrderListScreen({super.key});

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Beklemede';
      case OrderStatus.processing: return 'Hazırlanıyor';
      case OrderStatus.shipped: return 'Kargolandı';
      case OrderStatus.delivered: return 'Teslim Edildi';
      case OrderStatus.cancelled: return 'İptal Edildi';
      }
  }

  Color _getStatusColor(OrderStatus status, BuildContext context) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.processing: return Colors.blue;
      case OrderStatus.shipped: return Colors.purple;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      }
  }


  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = orderProvider.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişlerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Yeni Sipariş Oluştur',
            onPressed: () {
              context.goNamed(AddEditOrderScreen.routeName);
            },
          ),
        ],
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Henüz siparişiniz bulunmuyor.', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('İlk Siparişinizi Oluşturun'),
                        onPressed: () => context.goNamed(AddEditOrderScreen.routeName),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      child: ListTile(
                        title: Text('Sipariş ID: ...${order.id.substring(order.id.length - 6)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Müşteri: ${order.customerName}'),
                            Text('Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(order.orderDate.toDate())}'),
                            Text('Toplam: ${order.totalAmount.toStringAsFixed(2)} TL | VP: ${order.totalVpEarned.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status, context).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(order.status),
                            style: TextStyle(color: _getStatusColor(order.status, context), fontWeight: FontWeight.bold),
                          ),
                        ),
                        onTap: () {
                           context.goNamed(AddEditOrderScreen.routeName, extra: order);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}