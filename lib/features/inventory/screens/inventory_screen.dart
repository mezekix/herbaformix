import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/inventory_item_model.dart';
import '../../../models/inventory_movement_model.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../products/providers/product_provider.dart';
import '../../orders/providers/order_provider.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  static const String routeName = 'inventory';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stok ve Alışlarım')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMovementSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('İşlem Ekle'),
      ),
      body: Consumer2<InventoryProvider, OrderProvider>(
        builder: (context, inventory, orders, _) {
          if (inventory.isLoading && inventory.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (inventory.items.isEmpty) {
            return _EmptyInventory(onAdd: () => _showMovementSheet(context));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InventorySummary(inventory: inventory, orders: orders),
              const SizedBox(height: 20),
              Text(
                'Mevcut stok',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final item in inventory.items) ...[
                _InventoryCard(
                  item: item,
                  onPersonalUse: () => _showMovementSheet(
                    context,
                    type: _InventoryAction.personalUse,
                    item: item,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              Text(
                'Son stok hareketleri',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (inventory.movements.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Henüz stok hareketi bulunmuyor.'),
                  ),
                )
              else
                for (final movement in inventory.movements.take(25))
                  _MovementTile(movement: movement),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showMovementSheet(
    BuildContext context, {
    _InventoryAction? type,
    InventoryItemModel? item,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MovementSheet(initialAction: type, inventoryItem: item),
    );
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.inventory, required this.orders});
  final InventoryProvider inventory;
  final OrderProvider orders;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final deliveredOrders = orders.orders.where(
      (order) => order.status == OrderStatus.delivered,
    );
    final salesRevenue = deliveredOrders.fold<double>(
      0,
      (total, order) => total + order.totalAmount,
    );
    final receivables = deliveredOrders.fold<double>(
      0,
      (total, order) => total + (order.totalAmount - order.paidAmount),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryCard(
          label: 'Stok maliyeti',
          value: money.format(inventory.stockValue),
        ),
        _SummaryCard(
          label: 'Alış toplamı',
          value: money.format(inventory.purchaseCost),
        ),
        _SummaryCard(
          label: 'Satış maliyeti',
          value: money.format(inventory.salesCost),
        ),
        _SummaryCard(
          label: 'Teslim edilen satış',
          value: money.format(salesRevenue),
        ),
        _SummaryCard(
          label: 'Tahsil edilecek',
          value: money.format(receivables),
        ),
        _SummaryCard(
          label: 'Brüt kâr',
          value: money.format(salesRevenue - inventory.salesCost),
        ),
        _SummaryCard(
          label: 'Kişisel kullanım',
          value: money.format(inventory.personalUseCost),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: (MediaQuery.sizeOf(context).width - 48) / 2,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});
  final InventoryMovementModel movement;

  @override
  Widget build(BuildContext context) {
    final incoming = movement.quantityDelta > 0;
    return Card(
      child: ListTile(
        dense: true,
        leading: Icon(
          incoming ? Icons.south_west : Icons.north_east,
          color: incoming ? Colors.green : Colors.orange,
        ),
        title: Text(movement.productName),
        subtitle: Text(
          '${_movementLabel(movement.type)} • ${DateFormat('dd.MM.yyyy HH:mm').format(movement.occurredAt.toDate())}\n'
          'Birim maliyet: ${movement.unitCost.toStringAsFixed(2)} TL'
          '${movement.note == null ? '' : ' • ${movement.note}'}',
        ),
        isThreeLine: true,
        trailing: Text(
          '${incoming ? '+' : ''}${movement.quantityDelta}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: incoming ? Colors.green : Colors.orange,
          ),
        ),
      ),
    );
  }

  String _movementLabel(InventoryMovementType type) => switch (type) {
    InventoryMovementType.initialCount => 'Başlangıç stoğu',
    InventoryMovementType.purchase => 'Alış',
    InventoryMovementType.sale => 'Satış',
    InventoryMovementType.personalUse => 'Kişisel kullanım',
    InventoryMovementType.adjustmentIncrease => 'Sayım artışı',
    InventoryMovementType.adjustmentDecrease => 'Sayım azalışı',
    InventoryMovementType.customerReturn => 'Satış iptali/iade',
  };
}

enum _InventoryAction { initialCount, purchase, personalUse, adjustment }

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz stok kaydın yok.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Elindeki ürünleri sayıp başlangıç stoğunu ekleyerek başlayabilirsin.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Başlangıç Stoğu Ekle'),
          ),
        ],
      ),
    ),
  );
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onPersonalUse});
  final InventoryItemModel item;
  final VoidCallback onPersonalUse;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: item.isLowStock ? AppColors.papaya : AppColors.primary,
        child: Text(
          '${item.onHandQuantity}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(item.productName),
      subtitle: Text(
        'Ort. maliyet: ${item.averageUnitCost.toStringAsFixed(2)} TL',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.isLowStock)
            const Chip(
              label: Text('Düşük stok'),
              backgroundColor: Color(0xFFFFE6E2),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Kişisel kullanım',
            onPressed: onPersonalUse,
          ),
        ],
      ),
      onTap: onPersonalUse,
    ),
  );
}

class _MovementSheet extends StatefulWidget {
  const _MovementSheet({this.initialAction, this.inventoryItem});
  final _InventoryAction? initialAction;
  final InventoryItemModel? inventoryItem;

  @override
  State<_MovementSheet> createState() => _MovementSheetState();
}

class _MovementSheetState extends State<_MovementSheet> {
  late _InventoryAction _action;
  final _quantityController = TextEditingController(text: '1');
  final _costController = TextEditingController();
  final _noteController = TextEditingController();
  ProductModel? _product;
  DateTime _occurredAt = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction ?? _InventoryAction.initialCount;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    ProductModel? selected = _product;
    if (widget.inventoryItem != null) {
      final matches = products
          .where((product) => product.id == widget.inventoryItem!.productId)
          .toList();
      selected = matches.isEmpty ? null : matches.first;
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<_InventoryAction>(
              key: ValueKey(_action),
              initialValue: _action,
              decoration: const InputDecoration(labelText: 'İşlem türü'),
              items: const [
                DropdownMenuItem(
                  value: _InventoryAction.initialCount,
                  child: Text('Başlangıç stoğu'),
                ),
                DropdownMenuItem(
                  value: _InventoryAction.purchase,
                  child: Text('Alış ekle'),
                ),
                DropdownMenuItem(
                  value: _InventoryAction.personalUse,
                  child: Text('Kişisel kullanım'),
                ),
                DropdownMenuItem(
                  value: _InventoryAction.adjustment,
                  child: Text('Stok düzeltmesi'),
                ),
              ],
              onChanged: widget.initialAction == null
                  ? (value) => setState(() => _action = value!)
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductModel>(
              key: ValueKey(selected?.id),
              initialValue: selected,
              decoration: const InputDecoration(labelText: 'Ürün'),
              items: products
                  .map(
                    (product) => DropdownMenuItem(
                      value: product,
                      child: Text(product.name),
                    ),
                  )
                  .toList(),
              onChanged: widget.inventoryItem == null
                  ? (value) => setState(() => _product = value)
                  : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('İşlem tarihi'),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(_occurredAt)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _action == _InventoryAction.adjustment
                    ? 'Fark adedi (+/-)'
                    : 'Adet',
              ),
            ),
            if (_action == _InventoryAction.initialCount ||
                _action == _InventoryAction.purchase) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Birim maliyet (TL)',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: _action == _InventoryAction.adjustment
                    ? 'Düzeltme nedeni'
                    : 'Not (isteğe bağlı)',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : () => _save(selected),
              child: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  String get _title => switch (_action) {
    _InventoryAction.initialCount => 'Başlangıç Stoğu Ekle',
    _InventoryAction.purchase => 'Alış Ekle',
    _InventoryAction.personalUse => 'Kişisel Ürün Kullanımı',
    _InventoryAction.adjustment => 'Stok Düzelt',
  };

  Future<void> _save(ProductModel? product) async {
    final quantity = int.tryParse(_quantityController.text.trim());
    final cost = double.tryParse(
      _costController.text.trim().replaceAll(',', '.'),
    );
    final needsPositiveQuantity =
        _action == _InventoryAction.initialCount ||
        _action == _InventoryAction.purchase ||
        _action == _InventoryAction.personalUse;
    if (product == null ||
        quantity == null ||
        quantity == 0 ||
        (needsPositiveQuantity && quantity < 0) ||
        ((_action == _InventoryAction.initialCount ||
                _action == _InventoryAction.purchase) &&
            (cost == null || cost < 0)) ||
        (_action == _InventoryAction.adjustment &&
            _noteController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen zorunlu alanları doğru girin.')),
      );
      return;
    }
    setState(() => _saving = true);
    final inventory = context.read<InventoryProvider>();
    try {
      switch (_action) {
        case _InventoryAction.initialCount:
          await inventory.addInitialCount(
            product: product,
            quantity: quantity,
            unitCost: cost!,
            note: _noteController.text,
            occurredAt: _occurredAt,
          );
          break;
        case _InventoryAction.purchase:
          await inventory.addPurchase(
            product: product,
            quantity: quantity,
            unitCost: cost!,
            note: _noteController.text,
            occurredAt: _occurredAt,
          );
          break;
        case _InventoryAction.personalUse:
          await inventory.recordPersonalUse(
            product: product,
            quantity: quantity.abs(),
            note: _noteController.text,
            occurredAt: _occurredAt,
          );
          break;
        case _InventoryAction.adjustment:
          await inventory.adjustStock(
            product: product,
            quantityDelta: quantity,
            note: _noteController.text.trim(),
            occurredAt: _occurredAt,
          );
          break;
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) {
      setState(() => _occurredAt = selected);
    }
  }
}
