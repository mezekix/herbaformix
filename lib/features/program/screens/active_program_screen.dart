import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/products/providers/product_provider.dart';
import '../../../features/products/providers/recipe_provider.dart';
import '../../../features/products/widgets/recipe_card.dart';
import '../../../models/daily_routine_model.dart';
import '../../../models/product_model.dart';
import '../../../services/routine_service.dart';
import '../models/program_model.dart';
import '../providers/program_provider.dart';
import '../services/notification_service.dart';
import '../screens/create_program_screen.dart';
import '../widgets/water_step_tile.dart';

class ActiveProgramScreen extends StatelessWidget {
  const ActiveProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        context.read<AuthProvider>().firebaseUser?.uid ?? '';

    return StreamBuilder<ProgramModel?>(
      stream: context.read<ProgramProvider>().watchActiveProgram(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final program = snap.data;
        if (program == null) return _NoProgramView(userId: userId);
        return _ActiveView(program: program, userId: userId);
      },
    );
  }
}

// ── Program Yok ───────────────────────────────────────────────────────────────

class _NoProgramView extends StatelessWidget {
  final String userId;
  const _NoProgramView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Henüz programın yok',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky)),
            const SizedBox(height: 8),
            Text(
              'Hedefine göre kişisel bir program oluştur.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Program Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () =>
                  context.goNamed(CreateProgramScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Aktif Program ─────────────────────────────────────────────────────────────

class _ActiveView extends StatelessWidget {
  final ProgramModel program;
  final String userId;

  const _ActiveView({required this.program, required this.userId});

  @override
  Widget build(BuildContext context) {
    final goalLabels = {
      'weight_loss': '🔥 Kilo Ver',
      'healthy_living': '🌿 Sağlıklı Yaşa',
      'weight_gain': '💪 Kilo Al',
    };

    return StreamBuilder<List<DailyRoutineModel>>(
      stream: context
          .read<RoutineService>()
          .getDailyRoutines(userId, DateTime.now()),
      builder: (context, snap) {
        final rawRoutines = snap.data ?? [];
        final incompleteRoutines = rawRoutines.where((r) => !r.isCompleted).toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        final completedRoutines = rawRoutines.where((r) => r.isCompleted).toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        
        final routines = [...incompleteRoutines, ...completedRoutines];
        
        final completed = rawRoutines.where((r) => r.isCompleted).length;
        final total = rawRoutines.length;
        final progress = total > 0 ? completed / total : 0.0;

        return CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.nightSky],
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goalLabels[program.userGoal] ?? 'Programım',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${program.durationMonths} aylık program • ${program.remainingDays} gün kaldı',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Ürün ekle butonu
                            _HeaderBtn(
                              icon: Icons.add,
                              tooltip: 'Ürün/Öğün Ekle',
                              onTap: () =>
                                  _showAddSlotSheet(context),
                            ),
                            const SizedBox(width: 8),
                            // Yeni program
                            _HeaderBtn(
                              icon: Icons.refresh,
                              tooltip: 'Yeni Program',
                              onTap: () => _confirmNewProgram(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$completed / $total tamamlandı',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text('${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Tarih başlığı ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('d MMMM, EEEE', 'tr_TR')
                          .format(DateTime.now()),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nightSky),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Rutin listesi ────────────────────────────────────────────
            if (snap.connectionState == ConnectionState.waiting)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (routines.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Bugün için rutin bulunamadı.',
                          style:
                              TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverImplicitlyAnimatedList<DailyRoutineModel>(
                  items: routines,
                  areItemsTheSame: (a, b) => a.id == b.id,
                  itemBuilder: (context, animation, routine, i) {
                    final isLast = i == routines.length - 1;
                    Widget child;

                    if (routine.isWaterStep) {
                      child = WaterStepTile(
                        routine: routine,
                        userId: userId,
                        isLast: isLast,
                      );
                    } else if (routine.isNormalMealStep) {
                      child = _ProductTile(
                        routine: routine,
                        product: ProductModel(
                          id: '',
                          name: routine.productId, // label metni
                          vp: 0,
                        ),
                        userId: userId,
                        userGoal: program.userGoal,
                        isLast: isLast,
                        isNormalMeal: true,
                      );
                    } else {
                      final product = context
                          .read<ProductProvider>()
                          .products
                          .firstWhere(
                            (p) => p.id == routine.productId,
                            orElse: () => ProductModel(
                                id: '', name: 'Silinmiş Ürün', vp: 0),
                          );

                      child = _ProductTile(
                        routine: routine,
                        product: product,
                        userId: userId,
                        userGoal: program.userGoal,
                        isLast: isLast,
                      );
                    }

                    return SizeFadeTransition(
                      sizeFraction: 0.7,
                      curve: Curves.easeInOut,
                      animation: animation,
                      child: child,
                    );
                  },
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  void _confirmNewProgram(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Program Oluştur'),
        content: const Text(
            'Mevcut programın silinecek. Devam etmek istiyor musun?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ProgramProvider>().deleteProgram(userId);
              if (context.mounted) {
                context.goNamed(CreateProgramScreen.routeName);
              }
            },
            child: const Text('Devam Et',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAddSlotSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddSlotSheet(
        program: program,
        userId: userId,
      ),
    );
  }
}

// ── Slot Ekleme Sheet (program başladıktan sonra) ─────────────────────────────

class _AddSlotSheet extends StatefulWidget {
  final ProgramModel program;
  final String userId;

  const _AddSlotSheet({required this.program, required this.userId});

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  String _slotLabel = 'Ara Öğün';
  String _slotTime = '10:30';
  String? _selectedProductId;
  bool _isPermanent = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final allProducts = context.read<ProductProvider>().products;
    final visibleProducts = allProducts
        .where((p) =>
            p.category == 'İç Beslenme' || p.category == 'Dış Beslenme')
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Programa Ekle',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nightSky)),
          const SizedBox(height: 16),

          // Öğün adı
          TextFormField(
            initialValue: _slotLabel,            decoration: InputDecoration(
              labelText: 'Öğün Adı',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (v) => setState(() => _slotLabel = v),
          ),
          const SizedBox(height: 12),

          // Saat
          GestureDetector(
            onTap: () async {
              final parts = _slotTime.split(':');
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: int.parse(parts[0]),
                    minute: int.parse(parts[1])),
              );
              if (picked != null) {
                setState(() => _slotTime =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Saat: $_slotTime',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Ürün seç
          DropdownButtonFormField<String>(
            initialValue: _selectedProductId,
            hint: const Text('Ürün seç (opsiyonel)'),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            items: visibleProducts
                .map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name,
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _selectedProductId = v),
          ),
          const SizedBox(height: 12),

          // Kalıcı / Sadece Bugün seçimi
          SwitchListTile(
            title: const Text('Tüm Programıma Ekle', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              _isPermanent
                  ? 'Her gün tekrarlanır.'
                  : 'Sadece bugünün rutinlerine eklenir.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            value: _isPermanent,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _isPermanent = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    final product = _selectedProductId != null
                        ? visibleProducts.firstWhere(
                            (p) => p.id == _selectedProductId)
                        : null;

                    final newSlot = MealSlot(
                      id: 'snack_${DateTime.now().millisecondsSinceEpoch}',
                      kind: MealSlotKind.snack,
                      label: _slotLabel,
                      scheduledTime: _slotTime,
                      isNormalMeal: product == null,
                      products: product != null
                          ? [
                              MealProduct(
                                  productId: product.id,
                                  productName: product.name)
                            ]
                          : [],
                    );

                    final allProds =
                        context.read<ProductProvider>().products;
                        
                    if (_isPermanent) {
                      await context
                          .read<ProgramProvider>()
                          .addSlotToActiveProgram(
                              widget.userId, newSlot, allProds);
                    } else {
                      final timeParts = _slotTime.split(':');
                      final hour = int.tryParse(timeParts[0]) ?? 0;
                      final minute = int.tryParse(timeParts[1]) ?? 0;
                      final now = DateTime.now();
                      final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
                      
                      final routine = DailyRoutineModel(
                        id: '',
                        productId: product != null ? product.id : (_slotLabel.isEmpty ? 'Ara Öğün' : _slotLabel),
                        scheduledTime: scheduledTime,
                        isCompleted: false,
                        stepType: product != null ? RoutineStepType.product : RoutineStepType.normalMeal,
                      );
                      final newId = await context.read<RoutineService>().addSingleRoutine(widget.userId, routine);
                      
                      // Tek seferlik öğün için bildirim ayarla
                      final notifId = newId.hashCode.abs() % 100000;
                      String title = '⏰ ${_slotLabel.isEmpty ? 'Ara Öğün' : _slotLabel} Zamanı!';
                      String body = 'Öğününüzü/Ürününüzü almayı unutmayın.';
                      
                      if (product != null) {
                        title = '🥤 ${_slotLabel.isEmpty ? 'Ara Öğün' : _slotLabel} Zamanı!';
                        body = '${product.name} kullanmayı unutmayın.';
                      } else {
                        title = '🍎 ${_slotLabel.isEmpty ? 'Ara Öğün' : _slotLabel} Zamanı!';
                        body = 'Ara öğün zamanı geldi, atıştırmalığınızı unutmayın.';
                      }
                      
                      await NotificationService().scheduleMealNotification(
                        notificationId: notifId,
                        title: title,
                        body: body,
                        scheduledTime: _slotTime,
                        isOneTime: true,
                      );
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Ekle',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Ürün Rutin Kartı ──────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final DailyRoutineModel routine;
  final ProductModel product;
  final String userId;
  final String userGoal;
  final bool isLast;
  final bool isNormalMeal;

  const _ProductTile({
    required this.routine,
    required this.product,
    required this.userId,
    required this.userGoal,
    required this.isLast,
    this.isNormalMeal = false,
  });

  void _showDeleteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Rutin İşlemleri',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Sadece Bugün İçin Sil', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<RoutineService>().deleteRoutine(userId, routine.id);
                },
              ),
              if (routine.slotId != null)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Tüm Programdan Kaldır', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Bu öğün artık hiçbir gün tekrarlanmaz.', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final allProds = context.read<ProductProvider>().products;
                    await context.read<ProgramProvider>().removeSlotFromActiveProgram(userId, routine.slotId!, allProds);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    const accent = Color(0xFF22C55E);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: routine.isCompleted ? accent : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: routine.isCompleted
                          ? accent
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: routine.isCompleted
                        ? [
                            BoxShadow(
                                color: accent.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: Icon(
                    routine.isCompleted ? Icons.check : Icons.local_drink,
                    size: 16,
                    color: routine.isCompleted
                        ? Colors.white
                        : Colors.grey.shade400,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showInstruction(context),
              onLongPress: () => _showDeleteDialog(context),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: routine.isCompleted
                      ? const Color(0xFFF0FDF4)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: routine.isCompleted
                        ? const Color(0xFF86EFAC)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: routine.isCompleted
                                  ? const Color(0xFF166534)
                                  : AppColors.nightSky,
                              fontSize: 14,
                              decoration: routine.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 12,
                                  color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                timeFormat.format(routine.scheduledTime),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.touch_app_outlined,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text('Nasıl Kullanılır?',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: routine.isCompleted,
                      activeColor: accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) async {
                        if (val != null) {
                          await context
                              .read<RoutineService>()
                              .updateRoutineStatus(
                                  userId, routine.id, val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstruction(BuildContext context) {
    final instruction =
        product.instructionsByGoal?[userGoal] ?? product.usageInfo;

    // Eğer tarif varsa instruction boş olsa bile gösterebilmeliyiz.
    final recipes = context.read<RecipeProvider>().getRecipesForProduct(product.id);
    final hasInstruction = instruction != null && instruction.isNotEmpty;
    
    if (!hasInstruction && recipes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (hasInstruction)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Text(instruction,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade800,
                        height: 1.5)),
              ),
            if (recipes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '🥤 Bu ürün için ${recipes.length} tarif var',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              RecipeCard(recipe: recipes.first, isCompact: true),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('Anladım'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
