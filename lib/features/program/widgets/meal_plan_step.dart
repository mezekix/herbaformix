import 'package:flutter/material.dart';
import 'package:herbaformix/core/logger.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../features/products/providers/product_provider.dart';
import '../../../models/product_model.dart';
import '../models/program_model.dart';
import '../providers/program_provider.dart';

class MealPlanStep extends StatefulWidget {
  const MealPlanStep({super.key});

  @override
  State<MealPlanStep> createState() => _MealPlanStepState();
}

class _MealPlanStepState extends State<MealPlanStep> {
  bool _slotsInitialized = false;

  @override
  void initState() {
    super.initState();
    // Slotları sadece bir kez başlat — didChangeDependencies yerine
    // initState + addPostFrameCallback ile rebuild fırtınasını önle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ProgramProvider>();
      if (provider.slots.isEmpty && !_slotsInitialized) {
        provider.initSlots(provider.selectedGoal ?? 'healthy_living');
      }
      _slotsInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgramProvider>();
    final productProvider = context.watch<ProductProvider>();

    // Ürünler henüz yüklenmediyse yükleniyor göster
    if (productProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Ürünler yükleniyor...',
                style: TextStyle(color: AppColors.nightSky)),
          ],
        ),
      );
    }

    final allProducts = productProvider.products;
    final innerProducts =
        allProducts.where((p) => p.category == 'İç Beslenme').toList();
    final outerProducts =
        allProducts.where((p) => p.category == 'Dış Beslenme').toList();
    final allVisible = [...innerProducts, ...outerProducts];
    final mainProducts = innerProducts.isNotEmpty ? innerProducts : allVisible;
    final snackProducts = allVisible.isNotEmpty ? allVisible : allProducts;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Öğün Planını Oluştur',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky),
          ),
          const SizedBox(height: 6),
          Text(
            'Her öğüne ürün ekle, saatini ayarla.',
            style: TextStyle(fontSize: 14, color: AppColors.grey600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.cyan, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Her öğünden 30 dk önce 500ml su hatırlatması eklenir.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.cyan.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ...provider.slots.map((slot) {
            final products =
                slot.kind == MealSlotKind.snack ? snackProducts : mainProducts;
            return _SlotCard(
              key: ValueKey(slot.id),
              slot: slot,
              availableProducts: products,
              onTimeChanged: (t) => provider.updateSlotTime(slot.id, t),
              onToggleNormalMeal: (v) =>
                  provider.toggleSlotNormalMeal(slot.id, v),
              onAddProduct: (p) => provider.addProductToSlot(
                  slot.id, MealProduct(productId: p.id, productName: p.name)),
              onRemoveProduct: (pid) =>
                  provider.removeProductFromSlot(slot.id, pid),
              onDelete: slot.kind == MealSlotKind.snack
                  ? () => provider.removeSlot(slot.id)
                  : null,
            );
          }),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => provider.addSnackSlot(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ara Öğün Ekle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () => provider.nextStep(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Özete Geç',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slot Kartı — StatefulWidget, ürün seçim sheet'i yönetir
// ─────────────────────────────────────────────────────────────────────────────

class _SlotCard extends StatefulWidget {
  final MealSlot slot;
  final List<ProductModel> availableProducts;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<bool> onToggleNormalMeal;
  final ValueChanged<ProductModel> onAddProduct;
  final ValueChanged<String> onRemoveProduct;
  final VoidCallback? onDelete;

  const _SlotCard({
    super.key,
    required this.slot,
    required this.availableProducts,
    required this.onTimeChanged,
    required this.onToggleNormalMeal,
    required this.onAddProduct,
    required this.onRemoveProduct,
    this.onDelete,
  });

  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard> {
  void _showProductPicker() {
    final slot = widget.slot;
    final already = slot.products.map((p) => p.productId).toSet();
    final pickable = widget.availableProducts
        .where((p) => !already.contains(p.id))
        .toList();

    if (pickable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eklenecek başka ürün yok.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ürün Seç',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.nightSky)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: pickable.length,
              itemBuilder: (_, i) {
                final p = pickable[i];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_drink,
                        color: AppColors.primary, size: 18),
                  ),
                  title: Text(p.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary)),
                  subtitle: p.category != null
                      ? Text(p.category!,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    AppLogger.debug(
                        'Ürün ekleniyor: ${p.name}',
                        tag: 'MealPlanStep');
                    widget.onAddProduct(p);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final isSnack = slot.kind == MealSlotKind.snack;
    final accent = isSnack ? Colors.orange : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: slot.isNormalMeal
              ? AppColors.backgroundMuted
              : accent.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // ── Başlık ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_icon(slot.kind), color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(slot.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.nightSky)),
                ),
                // Saat chip
                GestureDetector(
                  onTap: () async {
                    final parts = slot.scheduledTime.split(':');
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1])),
                    );
                    if (picked != null) {
                      widget.onTimeChanged(
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(slot.scheduledTime,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Öğünü sil',
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textMuted),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Normal Yemek / Ürün toggle ───────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _TypeBtn(
                    label: '🥤 Ürün Ekle',
                    selected: !slot.isNormalMeal,
                    color: accent,
                    onTap: () => widget.onToggleNormalMeal(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeBtn(
                    label: '🍽️ Normal Yemek',
                    selected: slot.isNormalMeal,
                    color: AppColors.grey600,
                    onTap: () => widget.onToggleNormalMeal(true),
                  ),
                ),
              ],
            ),
          ),

          // ── Ürün bölümü ──────────────────────────────────────────────────
          if (!slot.isNormalMeal) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eklenmiş ürünler
                  if (slot.products.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: slot.products
                          .map((p) => Chip(
                                label: Text(p.productName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary)),
                                backgroundColor: AppColors.primary
                                    .withValues(alpha: 0.08),
                                side: BorderSide(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3)),
                                deleteIcon: const Icon(Icons.close,
                                    size: 14, color: AppColors.primary),
                                onDeleted: () =>
                                    widget.onRemoveProduct(p.productId),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Ürün ekle butonu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showProductPicker,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        slot.products.isEmpty
                            ? 'Ürün Ekle'
                            : 'Başka Ürün Ekle',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  // Su adımı bilgisi
                  if (slot.products.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.water_drop,
                            color: Colors.cyan, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Su: ${calculateWaterStepTime(slot.scheduledTime)}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.cyan.shade700),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _icon(MealSlotKind kind) {
    switch (kind) {
      case MealSlotKind.morning:
        return Icons.wb_sunny_outlined;
      case MealSlotKind.lunch:
        return Icons.wb_cloudy_outlined;
      case MealSlotKind.evening:
        return Icons.nights_stay_outlined;
      case MealSlotKind.snack:
        return Icons.coffee_outlined;
    }
  }
}

// ── Küçük Bileşenler ──────────────────────────────────────────────────────────

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.backgroundMutedLighter,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : AppColors.backgroundMuted,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : AppColors.grey600)),
      ),
    );
  }
}
