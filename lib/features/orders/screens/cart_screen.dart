import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/customer_model.dart';
import '../../../models/order_item_model.dart';
import '../../../models/order_model.dart';
import '../../../models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CustomerModel? _selectedCustomer;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(
    CartProvider cartProvider,
    OrderProvider orderProvider,
    AuthProvider authProvider,
  ) async {
    final role = authProvider.userProfile?.role;
    final isCustomer = role == UserRole.customer;

    if (isCustomer &&
        (authProvider.userProfile?.assignedDistributorId == null ||
            authProvider.userProfile!.assignedDistributorId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş talebi göndermek için önce bir yaşam koçuna bağlanmalısınız.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!isCustomer && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen siparişin ait olduğu müşteriyi seçin.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    setState(() => _isSubmitting = true);

    try {
      final customerId = isCustomer
          ? authProvider.firebaseUser!.uid
          : (_selectedCustomer!.linkedUserId ?? _selectedCustomer!.id);
      final customerName = isCustomer
          ? (authProvider.userProfile?.name ?? 'Müşteri')
          : '${_selectedCustomer!.firstName} ${_selectedCustomer!.lastName}'
                .trim();

      final orderData = OrderModel(
        id: '',
        userId: '', // OrderProvider bunu backend'de çözecek
        customerId: customerId,
        customerName: customerName,
        items: cartProvider.items.values.toList(),
        orderDate: Timestamp.now(),
        status: OrderStatus.pending, // Varsayılan durum: Beklemede
        totalAmount: cartProvider.totalAmount,
        totalVpEarned: cartProvider.totalVp,
        notes: _notesController.text.trim(),
        shippingAddress: _addressController.text.trim(),
      );

      final success = await orderProvider.addOrder(orderData);

      if (!mounted) return;

      if (success) {
        cartProvider.clearCart();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green[600],
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text('Tebrikler!'),
              ],
            ),
            content: Text(
              isCustomer
                  ? 'Sipariş talebiniz yaşam koçunuza başarıyla iletildi.'
                  : 'Sipariş başarıyla oluşturuldu ve kaydedildi.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  nav.pop(); // Sepet ekranından çık
                },
                child: const Text(
                  'Tamam',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Sipariş kaydedilirken bir hata oluştu.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final authProvider = context.read<AuthProvider>();
    final customerProvider = context.watch<CustomerProvider>();

    final role = authProvider.userProfile?.role;
    final isCustomer = role == UserRole.customer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sepetim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.nightSky,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : cartProvider.items.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Distribütör ise Müşteri Seçim Kartı
                  if (!isCustomer) ...[
                    _buildCustomerSelectionCard(customerProvider),
                    const SizedBox(height: 16),
                  ],

                  // Sepet Ürünleri Listesi
                  const Text(
                    'Sepetteki Ürünler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.nightSky,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items.values.elementAt(index);
                      return _buildCartItemCard(context, item, cartProvider);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ek Bilgiler (Not & Adres)
                  _buildAdditionalInfoCard(),
                  const SizedBox(height: 16),

                  // Sipariş Özeti Kartı
                  _buildSummaryCard(cartProvider, isCustomer),
                  const SizedBox(height: 24),

                  // Onay Butonu
                  ElevatedButton(
                    onPressed: () =>
                        _submitOrder(cartProvider, orderProvider, authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      isCustomer ? 'Koçuma İstek Gönder' : 'Siparişi Oluştur',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sepetiniz Boş',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sepetinizde henüz ürün bulunmuyor. Ürün kataloğuna göz atarak dilediğiniz ürünleri ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Alışverişe Başla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelectionCard(CustomerProvider customerProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: AppColors.backgroundMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Müşteri Seçimi*',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustomerModel>(
              initialValue: _selectedCustomer,
              hint: const Text('Sipariş kimin adına?'),
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.textMutedLighter),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.textMutedLighter),
                ),
              ),
              items: customerProvider.customers.map((c) {
                return DropdownMenuItem<CustomerModel>(
                  value: c,
                  child: Text('${c.firstName} ${c.lastName}'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedCustomer = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    OrderItemModel item,
    CartProvider cartProvider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: AppColors.backgroundMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Ürün İkonu / Küçük Görsel Arka Planı
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_pharmacy_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Ürün Detayı
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.nightSky,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.unitPrice.toStringAsFixed(2)} TL  •  ${item.unitVp.toStringAsFixed(0)} VP',
                    style: TextStyle(fontSize: 12, color: AppColors.grey600),
                  ),
                ],
              ),
            ),
            // Adet Kontrolü
            Row(
              children: [
                IconButton(
                  tooltip: 'Adeti azalt',
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () {
                    cartProvider.updateQuantity(
                      item.productId,
                      item.quantity - 1,
                    );
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  tooltip: 'Adeti artır',
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () {
                    cartProvider.updateQuantity(
                      item.productId,
                      item.quantity + 1,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: AppColors.backgroundMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sipariş Notu ve Teslimat Adresi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Sipariş Notu',
                hintText:
                    'Örn: Hızlı kargo rica ederim, shake çilekli olsun vb.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Teslimat Adresi (Opsiyonel)',
                hintText: 'Siparişin gönderileceği adres bilgisi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(CartProvider cart, bool isCustomer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.backgroundMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sipariş Özeti',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.nightSky,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Toplam Ürün', '${cart.itemCount} adet'),
          const Divider(height: 24),
          _buildSummaryRow(
            'Kazanılacak Toplam VP',
            '${cart.totalVp.toStringAsFixed(1)} VP',
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tahmini Tutar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nightSky,
                ),
              ),
              Text(
                '${cart.totalAmount.toStringAsFixed(2)} TL',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.nightSky,
          ),
        ),
      ],
    );
  }
}
