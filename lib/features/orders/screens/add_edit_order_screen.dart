import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/customer_model.dart';
import '../../../models/order_item_model.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/order_provider.dart';

class AddEditOrderScreen extends StatefulWidget {
  static const String routeName = 'add-edit-order';
  final OrderModel? order;

  const AddEditOrderScreen({super.key, this.order});

  @override
  State<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends State<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.order != null;
  bool _isLoading = false;

  // Form alanları için state'ler
  CustomerModel? _selectedCustomer;
  List<OrderItemModel> _orderItems = [];
  DateTime _selectedDate = DateTime.now();
  OrderStatus _selectedStatus = OrderStatus.pending;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _shippingAddressController =
      TextEditingController();

  // Geçici ürün seçimi için
  ProductModel? _productToSearch;
  // Dropdown ve adet field'ını programatik olarak sıfırlamak için key'ler
  Key _productDropdownKey = UniqueKey();
  final TextEditingController _quantityController = TextEditingController(text: '1');

  // Çeviri için helper metot
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

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.order != null) {
      final order = widget.order!;
      // Müşteriyi CustomerProvider'dan bulmaya çalış (ID ile eşleştir)
      final customerProvider = Provider.of<CustomerProvider>(
        context,
        listen: false,
      );
      try {
        _selectedCustomer = customerProvider.customers.firstWhere(
          (c) => c.id == order.customerId || (c.linkedUserId != null && c.linkedUserId == order.customerId),
        );
      } catch (e) {
        // Eğer müşteri listede bulunamazsa, sipariş verilerinden bir tane oluştur.
        // Bu durum, müşteri silinmişse veya liste güncel değilse olabilir.
        final names = order.customerName.split(' ');
        final firstName = names.isNotEmpty ? names.first : order.customerName;
        final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
        _selectedCustomer = CustomerModel(
          id: order.customerId,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: '', // Siparişte bu bilgi yok
          firstContactDate:
              order.orderDate, // Sipariş tarihini ilk temas kabul edebiliriz
          consultantId: order.userId,
          isActive: true, // Varsayılan olarak aktif
          notes: 'Müşteri bilgisi siparişten otomatik oluşturuldu.',
        );
      }

      _orderItems = List.from(order.items); // Kopyasını al
      _selectedDate = order.orderDate.toDate();
      _selectedStatus = order.status;
      _notesController.text = order.notes ?? '';
      _shippingAddressController.text = order.shippingAddress ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _shippingAddressController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addOrUpdateOrderItem(ProductModel product, int quantity) {
    if (quantity <= 0) return;

    final existingItemIndex = _orderItems.indexWhere(
      (item) => item.productId == product.id,
    );

    setState(() {
      if (existingItemIndex >= 0) {
        // Ürün zaten listede varsa, adedini güncelle
        _orderItems[existingItemIndex] = OrderItemModel(
          productId: product.id,
          productName: product.name,
          quantity:
              _orderItems[existingItemIndex].quantity + quantity, // Adedi artır
          unitPrice: product.price ?? 0.0, // Gerçek fiyatı al
          unitVp: product.vp,
        );
      } else {
        // Yeni ürün ekle
        _orderItems.add(
          OrderItemModel(
            productId: product.id,
            productName: product.name,
            quantity: quantity,
            unitPrice: product.price ?? 0.0,
            unitVp: product.vp,
          ),
        );
      }
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  double get _calculateTotalAmount =>
      _orderItems.fold(0, (total, item) => total + item.totalPrice);
  double get _calculateTotalVp =>
      _orderItems.fold(0, (total, item) => total + item.totalVp);

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir müşteri seçin.')),
      );
      return;
    }
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen siparişe en az bir ürün ekleyin.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.firebaseUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kullanıcı bulunamadı.')));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final orderData = OrderModel(
      id: _isEditing ? widget.order!.id : '',
      userId: currentUserId,
      customerId: _selectedCustomer!.linkedUserId ?? _selectedCustomer!.id,
      customerName:
          '${_selectedCustomer!.firstName} ${_selectedCustomer!.lastName}'
              .trim(),
      items: _orderItems,
      orderDate: Timestamp.fromDate(_selectedDate),
      status: _selectedStatus,
      totalAmount: _calculateTotalAmount,
      totalVpEarned: _calculateTotalVp,
      notes: _notesController.text.trim(),
      shippingAddress: _shippingAddressController.text.trim(),
    );

    bool success;
    if (_isEditing) {
      success = await orderProvider.updateOrder(orderData);
    } else {
      success = await orderProvider.addOrder(orderData);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sipariş başarıyla ${_isEditing ? "güncellendi" : "oluşturuldu"}!',
            ),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sipariş ${_isEditing ? "güncellenirken" : "oluşturulurken"} hata oluştu.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final customersById = {
      for (final customer in customerProvider.customers) customer.id: customer,
    };
    final selectedCustomerId = _selectedCustomer != null &&
            customersById.containsKey(_selectedCustomer!.id)
        ? _selectedCustomer!.id
        : null;
    // final orderProvider = Provider.of<OrderProvider>(context, listen: false); // Bu satır burada gerekli değil, onPressed içinde çağrılacak.

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Siparişi Görüntüle/Düzenle' : 'Yeni Sipariş Oluştur',
        ),
        actions: [
          if (_isEditing && widget.order != null)
            IconButton(
              tooltip: 'Siparişi kalıcı sil',
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Siparişi sil'),
                    content: const Text('Bu işlem geri alınamaz. Siparişi kalıcı olarak silmek istiyor musunuz?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                final success = await context.read<OrderProvider>().deleteOrder(widget.order!.id);
                if (!context.mounted) return;
                if (success) context.pop();
              },
            ),
          if (_isEditing &&
              widget.order != null) // Silme butonu sadece düzenleme modunda
            IconButton(
              tooltip: 'Siparişi iptal et',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                // Silme işlemi (genelde status 'cancelled' yapılır)
                final orderProvider =
                    Provider.of<OrderProvider>(context, listen: false);
                final router = GoRouter.of(context);

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Siparişi İptal Et"),
                    content: const Text(
                      "Bu siparişi iptal etmek istediğinizden emin misiniz?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text("Hayır"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text("Evet, İptal Et"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await orderProvider.updateOrderStatus(
                    widget.order!.id,
                    OrderStatus.cancelled,
                  );
                  if (!mounted) return;
                  router.pop();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Müşteri Seçimi
                    DropdownButtonFormField<String>(
                      initialValue: selectedCustomerId,
                      hint: const Text('Müşteri Seçin*'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_search_outlined),
                      ),
                      items: customersById.values.map((customer) {
                        return DropdownMenuItem<String>(
                          value: customer.id,
                          child: Text(
                            '${customer.firstName} ${customer.lastName}'.trim(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomer = value == null ? null : customersById[value];
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Lütfen bir müşteri seçin.' : null,
                    ),
                    const SizedBox(height: 16),

                    // Ürün Ekleme Bölümü
                    _buildProductSelection(context, productProvider),
                    const SizedBox(height: 16),

                    // Sipariş Edilen Ürünler Listesi
                    _buildOrderItemsList(),
                    const SizedBox(height: 16),

                    // Toplam Tutar ve VP
                    Text(
                      'Toplam Tutar: ${_calculateTotalAmount.toStringAsFixed(2)} TL',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Kazanılan VP: ${_calculateTotalVp.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),

                    // Sipariş Tarihi
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(
                        'Sipariş Tarihi: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ), // Gelecek bir yıla kadar
                        );
                        if (pickedDate != null && pickedDate != _selectedDate) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Sipariş Durumu (Sadece düzenleme modunda anlamlı olabilir veya varsayılan)
                    if (_isEditing)
                      DropdownButtonFormField<OrderStatus>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Sipariş Durumu',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.delivery_dining_outlined),
                        ),
                        items: OrderStatus.values.map((status) {
                          return DropdownMenuItem<OrderStatus>(
                            value: status,
                            child: Text(
                              _getStatusText(status),
                            ), // Enum ismini göster
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _shippingAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Teslimat Adresi (Opsiyonel)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Sipariş Notları (Opsiyonel)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note_add_outlined),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: Icon(
                        _isEditing
                            ? Icons.save_alt_outlined
                            : Icons.add_shopping_cart_outlined,
                      ),
                      label: Text(
                        _isEditing ? 'Siparişi Güncelle' : 'Siparişi Oluştur',
                      ),
                      onPressed: _saveOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProductSelection(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ürün Ekle', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // Ürün dropdown — key ile sıfırlanabilir
            DropdownButtonFormField<ProductModel>(
              key: _productDropdownKey,
              initialValue: _productToSearch,
              hint: const Text('Ürün Seçin'),
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: productProvider.products.map((product) {
                final price = product.price != null
                    ? '${product.price!.toStringAsFixed(2)} ₺'
                    : 'Fiyat yok';
                return DropdownMenuItem<ProductModel>(
                  value: product,
                  child: Text(
                    '${product.name}  •  $price  •  ${product.vp.toStringAsFixed(0)} VP',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _productToSearch = value;
                });
              },
            ),

            // Seçili ürün fiyat özeti
            if (_productToSearch != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Birim fiyat: ${_productToSearch!.price != null ? "${_productToSearch!.price!.toStringAsFixed(2)} ₺" : "Fiyat girilmemiş"}  |  VP: ${_productToSearch!.vp.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adet field — controller ile yönetiliyor, ana form'dan bağımsız
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Adet',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // _quantityController zaten güncel, ek state gerekmez
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Listeye Ekle'),
                      onPressed: () {
                        if (_productToSearch == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen bir ürün seçin.')),
                          );
                          return;
                        }
                        final qty = int.tryParse(_quantityController.text) ?? 1;
                        if (qty < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Adet en az 1 olmalı.')),
                          );
                          return;
                        }
                        _addOrUpdateOrderItem(_productToSearch!, qty);
                        // Dropdown ve adet field'ını sıfırla
                        setState(() {
                          _productToSearch = null;
                          _productDropdownKey = UniqueKey();
                          _quantityController.text = '1';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsList() {
    if (_orderItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: Text('Siparişe henüz ürün eklenmedi.')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Sipariş Kalemleri:",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // İç içe kaydırmayı önle
          itemCount: _orderItems.length,
          itemBuilder: (context, index) {
            final item = _orderItems[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.productName),
                subtitle: Text(
                  'Adet: ${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} TL = ${item.totalPrice.toStringAsFixed(2)} TL\nVP: ${item.quantity} x ${item.unitVp.toStringAsFixed(2)} = ${item.totalVp.toStringAsFixed(2)} VP',
                ),
                trailing: IconButton(
                  tooltip: 'Bu ürünü siparişten çıkar',
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => _removeOrderItem(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
