import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../../models/product_model.dart';
import '../models/program_model.dart';
import '../models/program_template_model.dart';
import '../providers/program_template_provider.dart';

/// Yeni şablon oluşturma veya mevcut şablonu düzenleme ekranı.
///
/// Routing: `extra` olarak [ProgramTemplateModel] gelirse düzenleme modu,
/// gelmezse yeni şablon modu.
class EditProgramTemplateScreen extends StatefulWidget {
  static const String routeName = 'edit-program-template';
  final ProgramTemplateModel? existing;

  const EditProgramTemplateScreen({super.key, this.existing});

  @override
  State<EditProgramTemplateScreen> createState() =>
      _EditProgramTemplateScreenState();
}

class _EditProgramTemplateScreenState extends State<EditProgramTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _userGoal;
  late int _durationMonths;
  late List<MealSlot> _slots;
  bool _isSaving = false;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final tpl = widget.existing;
    _nameController = TextEditingController(text: tpl?.name ?? '');
    _descriptionController =
        TextEditingController(text: tpl?.description ?? '');
    _userGoal = tpl?.userGoal ?? 'healthy_living';
    _durationMonths = tpl?.defaultDurationMonths ?? 1;
    _slots = tpl != null
        ? List<MealSlot>.from(tpl.slots)
        : buildDefaultSlots(_userGoal);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onGoalChanged(String? newGoal) {
    if (newGoal == null || newGoal == _userGoal) return;
    setState(() {
      _userGoal = newGoal;
      // İskelet sıfırlanmaz — kullanıcının düzenlediği slot'lar korunur.
      // Ama öğle "normal yemek" işareti hedef değişimine bağlı olduğu için
      // sadece yeni şablonsa otomatik güncelle.
      if (!_isEditMode) {
        _slots = buildDefaultSlots(newGoal);
      }
    });
  }

  void _updateSlotTime(String slotId, String newTime) {
    setState(() {
      _slots = _slots
          .map((s) =>
              s.id == slotId ? s.copyWith(scheduledTime: newTime) : s)
          .toList();
    });
  }

  void _toggleSlotNormalMeal(String slotId, bool isNormalMeal) {
    setState(() {
      _slots = _slots
          .map((s) => s.id == slotId
              ? s.copyWith(
                  isNormalMeal: isNormalMeal,
                  products: isNormalMeal ? [] : s.products,
                )
              : s)
          .toList();
    });
  }

  void _addProductToSlot(String slotId, ProductModel product) {
    setState(() {
      _slots = _slots.map((s) {
        if (s.id != slotId) return s;
        if (s.products.any((p) => p.productId == product.id)) return s;
        return s.copyWith(
          products: [
            ...s.products,
            MealProduct(productId: product.id, productName: product.name),
          ],
        );
      }).toList();
    });
  }

  void _removeProductFromSlot(String slotId, String productId) {
    setState(() {
      _slots = _slots.map((s) {
        if (s.id != slotId) return s;
        return s.copyWith(
          products:
              s.products.where((p) => p.productId != productId).toList(),
        );
      }).toList();
    });
  }

  void _addSnackSlot() {
    final snackCount =
        _slots.where((s) => s.kind == MealSlotKind.snack).length;
    final newSlot = MealSlot(
      id: 'snack_${DateTime.now().millisecondsSinceEpoch}',
      kind: MealSlotKind.snack,
      label: 'Ara Öğün ${snackCount + 1}',
      scheduledTime: '10:30',
      products: const [],
    );
    setState(() => _slots = [..._slots, newSlot]);
  }

  void _removeSlot(String slotId) {
    setState(() => _slots = _slots.where((s) => s.id != slotId).toList());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final distributorId = auth.firebaseUser?.uid;
    if (distributorId == null) {
      _showSnackBar('Kullanıcı bulunamadı.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<ProgramTemplateProvider>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();

    bool ok;
    if (_isEditMode) {
      final updated = widget.existing!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        userGoal: _userGoal,
        defaultDurationMonths: _durationMonths,
        slots: _slots,
        updatedAt: now,
      );
      ok = await provider.update(updated);
    } else {
      final newTpl = ProgramTemplateModel(
        id: '', // create() add() üzerinden ID alacak
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        userGoal: _userGoal,
        defaultDurationMonths: _durationMonths,
        slots: _slots,
        createdBy: distributorId,
        createdAt: now,
        updatedAt: now,
      );
      final newId = await provider.create(newTpl);
      ok = newId != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isEditMode
            ? 'Şablon güncellendi.'
            : 'Şablon kaydedildi.'),
      ));
      router.pop();
    } else {
      _showSnackBar(
        provider.errorMessage ?? 'Şablon kaydedilemedi.',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final allProducts = productProvider.products;
    final mainProducts = allProducts
        .where((p) => p.category == 'İç Beslenme')
        .toList();
    final visibleMain = mainProducts.isNotEmpty ? mainProducts : allProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Şablonu Düzenle' : 'Yeni Şablon'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Şablon adı
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Şablon Adı *',
                hintText: 'Örn: "Başlangıç — Kilo Verme 1 Ay"',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Şablon adı zorunlu.';
                }
                if (v.trim().length < 3) return 'En az 3 karakter olmalı.';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Açıklama
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (opsiyonel)',
                hintText: 'Şablon ne için, hangi durumda uygulanır?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),

            // Hedef
            DropdownButtonFormField<String>(
              initialValue: _userGoal,
              decoration: const InputDecoration(
                labelText: 'Hedef',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'weight_loss', child: Text('Kilo Verme')),
                DropdownMenuItem(
                    value: 'healthy_living', child: Text('Sağlıklı Yaşam')),
                DropdownMenuItem(
                    value: 'weight_gain', child: Text('Kilo Alma')),
              ],
              onChanged: _onGoalChanged,
            ),
            const SizedBox(height: 14),

            // Varsayılan süre
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.calendar_month_outlined,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text('Varsayılan Süre:',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.nightSky)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _durationMonths,
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m ay'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _durationMonths = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Öğün Planı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Müşteriye uygularken bu yapı kopyalanır. Her slot için '
              'saat ve ürünleri ayarla.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),

            // Slot kartları
            ..._slots.map((slot) {
              return _TemplateSlotCard(
                key: ValueKey(slot.id),
                slot: slot,
                availableProducts: visibleMain,
                onTimeChanged: (t) => _updateSlotTime(slot.id, t),
                onToggleNormalMeal: (v) =>
                    _toggleSlotNormalMeal(slot.id, v),
                onAddProduct: (p) => _addProductToSlot(slot.id, p),
                onRemoveProduct: (pid) =>
                    _removeProductFromSlot(slot.id, pid),
                onDelete: slot.kind == MealSlotKind.snack
                    ? () => _removeSlot(slot.id)
                    : null,
              );
            }),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addSnackSlot,
              icon: const Icon(Icons.add),
              label: const Text('Ara Öğün Ekle'),
            ),
            const SizedBox(height: 22),

            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_alt_outlined),
                    label: Text(_isEditMode
                        ? 'Değişiklikleri Kaydet'
                        : 'Şablonu Oluştur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slot kartı — MealPlanStep'teki kartın sadeleştirilmiş kopyası
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateSlotCard extends StatelessWidget {
  final MealSlot slot;
  final List<ProductModel> availableProducts;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<bool> onToggleNormalMeal;
  final ValueChanged<ProductModel> onAddProduct;
  final ValueChanged<String> onRemoveProduct;
  final VoidCallback? onDelete;

  const _TemplateSlotCard({
    super.key,
    required this.slot,
    required this.availableProducts,
    required this.onTimeChanged,
    required this.onToggleNormalMeal,
    required this.onAddProduct,
    required this.onRemoveProduct,
    this.onDelete,
  });

  Future<void> _pickTime(BuildContext context) async {
    final parts = slot.scheduledTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
    );
    if (picked != null) {
      onTimeChanged(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _pickProduct(BuildContext context) async {
    final already = slot.products.map((p) => p.productId).toSet();
    final pickable =
        availableProducts.where((p) => !already.contains(p.id)).toList();

    if (pickable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eklenecek başka ürün yok.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ProductModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ürün Seç',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pickable.length,
                  itemBuilder: (_, i) {
                    final p = pickable[i];
                    return ListTile(
                      leading: const Icon(Icons.local_drink,
                          color: AppColors.primary),
                      title: Text(p.name),
                      subtitle: p.category != null ? Text(p.category!) : null,
                      onTap: () => Navigator.of(ctx).pop(p),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null) onAddProduct(selected);
  }

  IconData get _icon {
    switch (slot.kind) {
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

  Color get _accent =>
      slot.kind == MealSlotKind.snack ? Colors.orange : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: slot.isNormalMeal
              ? Colors.grey.shade200
              : _accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
            child: Row(
              children: [
                Icon(_icon, color: _accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slot.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.nightSky,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _pickTime(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          slot.scheduledTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Öğünü sil',
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.grey),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _TypeBtn(
                    label: '🥤 Ürün',
                    selected: !slot.isNormalMeal,
                    color: _accent,
                    onTap: () => onToggleNormalMeal(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeBtn(
                    label: '🍽️ Normal Yemek',
                    selected: slot.isNormalMeal,
                    color: Colors.grey.shade600,
                    onTap: () => onToggleNormalMeal(true),
                  ),
                ),
              ],
            ),
          ),
          if (!slot.isNormalMeal) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (slot.products.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: slot.products
                          .map((p) => Chip(
                                label: Text(p.productName,
                                    style:
                                        const TextStyle(fontSize: 11)),
                                deleteIcon:
                                    const Icon(Icons.close, size: 13),
                                onDeleted: () =>
                                    onRemoveProduct(p.productId),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.08),
                                side: BorderSide(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3)),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  if (slot.products.isNotEmpty) const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickProduct(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        slot.products.isEmpty
                            ? 'Ürün Ekle'
                            : 'Başka Ürün Ekle',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        side: BorderSide(color: _accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
