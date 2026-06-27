import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/order_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/order_provider.dart';
import './add_edit_order_screen.dart';

class OrderListScreen extends StatelessWidget {
  static const String routeName = '/orders';
  const OrderListScreen({super.key});

  // ── Durum yardımcıları ──────────────────────────────────────────────────

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Beklemede';
      case OrderStatus.processing:
        return 'Hazırlanıyor';
      case OrderStatus.shipped:
        return 'Kargolandı';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule_outlined;
      case OrderStatus.processing:
        return Icons.sync_outlined;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade700;
      case OrderStatus.processing:
        return AppColors.laguna;
      case OrderStatus.shipped:
        return AppColors.blueberry;
      case OrderStatus.delivered:
        return AppColors.grass;
      case OrderStatus.cancelled:
        return AppColors.papaya;
    }
  }

  // ── Silme dialog ──────────────────────────────────────────────────────

  void _deleteOrder(
    BuildContext context,
    OrderProvider provider,
    OrderModel order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.papaya),
            const SizedBox(width: 8),
            const Text('Siparişi Sil'),
          ],
        ),
        content: Text(
          '${order.customerName} adlı müşteriye ait bu siparişi kalıcı olarak silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Sil'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.papaya,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      if (!context.mounted) return;
      try {
        await provider.deleteOrder(order.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sipariş başarıyla silindi.'),
            backgroundColor: AppColors.grass,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppColors.papaya,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = orderProvider.orders;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCustomer = authProvider.userProfile?.role == UserRole.customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişlerim'),
        actions: [
          if (!isCustomer)
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
              ? _buildEmptyState(context, isCustomer)
              : _buildOrderList(context, orders, orderProvider, isCustomer),
    );
  }

  // ── Boş durum ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, bool isCustomer) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.primary.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz siparişiniz yok',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir sipariş oluşturarak başlayın.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!isCustomer)
              FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('İlk Siparişi Oluştur'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () =>
                    context.goNamed(AddEditOrderScreen.routeName),
              ),
          ],
        ),
      ),
    );
  }

  // ── Sipariş listesi ───────────────────────────────────────────────────

  Widget _buildOrderList(
    BuildContext context,
    List<OrderModel> orders,
    OrderProvider orderProvider,
    bool isCustomer,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, order, orderProvider, isCustomer);
      },
    );
  }

  // ── Sipariş kartı ────────────────────────────────────────────────────

  Widget _buildOrderCard(
    BuildContext context,
    OrderModel order,
    OrderProvider orderProvider,
    bool isCustomer,
  ) {
    final statusColor = _getStatusColor(order.status);
    final formattedDate =
        DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(order.orderDate.toDate());
    final itemCount = order.items.length;
    final productSummary = order.items
        .take(3)
        .map((item) => '${item.productName} ×${item.quantity}')
        .join(', ');
    final hasMore = itemCount > 3;

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isCustomer
              ? null
              : () {
                  context.goNamed(
                    AddEditOrderScreen.routeName,
                    extra: order,
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Üst satır: Müşteri adı + Durum badge ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Müşteri avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: statusColor.withAlpha(30),
                      child: Text(
                        order.customerName.isNotEmpty
                            ? order.customerName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // İsim ve tarih
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 13,
                                color: AppColors.textSecondary.withAlpha(150),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppColors.textSecondary.withAlpha(180),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Durum chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(order.status),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(order.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Ürün özeti ──
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppColors.textSecondary.withAlpha(150),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$productSummary${hasMore ? ' +${itemCount - 3} ürün daha' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Alt satır: Tutar + VP ──
                Row(
                  children: [
                    // Tutar
                    _buildInfoChip(
                      icon: Icons.payments_outlined,
                      label:
                          '${order.totalAmount.toStringAsFixed(2)} ₺',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    // VP
                    _buildInfoChip(
                      icon: Icons.star_outline_rounded,
                      label:
                          '${order.totalVpEarned.toStringAsFixed(1)} VP',
                      color: AppColors.mango,
                      textColor: AppColors.mangoDeep,
                    ),
                    const Spacer(),
                    // Ürün sayısı
                    Text(
                      '$itemCount ürün',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withAlpha(150),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isCustomer) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textSecondary.withAlpha(100),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Distribütör ise swipe-to-delete
    if (!isCustomer) {
      return Dismissible(
        key: ValueKey(order.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          _deleteOrder(context, orderProvider, order);
          return false; // Dialog kendi yönetir
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.papaya,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text(
                'Sil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        child: card,
      );
    }

    return card;
  }

  // ── Bilgi chip widget'ı ──────────────────────────────────────────────

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
  }) {
    final effectiveTextColor = textColor ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveTextColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: effectiveTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
