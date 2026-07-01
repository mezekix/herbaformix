import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/daily_routine_model.dart';
import '../../../models/product_model.dart';
import '../../../services/routine_service.dart';
import '../../../services/exercise_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../program/providers/program_provider.dart';
import '../../program/screens/create_program_screen.dart';
import '../../water_tracker/providers/water_provider.dart';
import '../../water_tracker/screens/water_tracker_screen.dart';
import '../widgets/motivation_widget.dart';
import '../widgets/daily_success_ring.dart';
import '../../program/services/notification_service.dart';
import '../../../services/fcm_service.dart';
import 'package:herbaformix/core/logger.dart';

class DistributorProductUsageScreen extends StatefulWidget {
  static const String routeName = 'distributor-usage';
  const DistributorProductUsageScreen({super.key});

  @override
  State<DistributorProductUsageScreen> createState() => _DistributorProductUsageScreenState();
}

class _DistributorProductUsageScreenState extends State<DistributorProductUsageScreen> {
  Stream<List<DailyRoutineModel>>? _routinesStream;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      await NotificationService().requestPermission();
      await FcmService().requestPermission();
    } catch (e) {
      AppLogger.error('[DistributorUsage] Notification permission error: $e', tag: 'DistributorProductUsageScreen', error: e);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.read<AuthProvider>().userProfile;
    if (userProfile != null && _routinesStream == null) {
      _routinesStream = context.read<RoutineService>().getDailyRoutines(userProfile.id, DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    if (userProfile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kişisel Ürün Kullanımım'),
      ),
      body: StreamBuilder<List<DailyRoutineModel>>(
        stream: _routinesStream ?? const Stream.empty(),
        builder: (context, snapshot) {
          final routines = snapshot.data ?? [];
          final hasProgram = routines.isNotEmpty;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!hasProgram) {
            return _buildEmptyProgramView(context);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeroProgress(context, routines),
                    const SizedBox(height: 16),
                    _buildDailyChecklist(context, routines, userProfile),
                    const SizedBox(height: 12),
                    _buildExerciseToggleCard(context),
                    const SizedBox(height: 16),
                    _buildWaterTracker(context),
                    const SizedBox(height: 16),
                    const MotivationWidget(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Program yokken gösterilen yönlendirme ekranı
  Widget _buildEmptyProgramView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_outlined, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kendine Rol Model Ol! 🌟',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.nightSky),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Kendi hedeflerini belirleyip ürün kullanımını takip ederek müşterilerine ilham verebilirsin. "Ürün ürünün sonucudur" felsefesini bugün başlat!',
              style: TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'Kişisel Programını Başlat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: () => context.goNamed(CreateProgramScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }

  /// Bugünkü İlerleme Özeti (DailySuccessRing)
  Widget _buildHeroProgress(BuildContext context, List<DailyRoutineModel> routines) {
    final userProfile = context.read<AuthProvider>().userProfile;
    final completedCount = routines.where((r) => r.isCompleted).length;
    final totalCount = routines.length;
    final productProgress = totalCount > 0 ? completedCount / totalCount : 0.0;

    final waterProgress = context.watch<WaterProvider>().progress;
    final exerciseProgress = context.watch<ExerciseService>().progress;

    final startDate = userProfile?.programStartDate;
    final dayNumber = startDate != null ? DateTime.now().difference(startDate).inDays + 1 : 1;

    String activeTaskLabel = '';
    final nextRoutine = routines.where((r) => !r.isCompleted).toList();
    if (nextRoutine.isNotEmpty) {
      final r = nextRoutine.first;
      String taskName = '';
      if (r.isWaterStep) {
        taskName = 'Su İç';
      } else if (r.isNormalMealStep) {
        taskName = r.productId;
      } else {
        final product = context.read<ProductProvider>().products.firstWhere(
              (p) => p.id == r.productId,
              orElse: () => ProductModel(id: '', name: 'Ürün', vp: 0),
            );
        taskName = product.name;
      }
      activeTaskLabel = '$taskName tamamla';
    } else if (waterProgress < 1.0) {
      activeTaskLabel = 'Su içmeyi tamamla 💧';
    } else if (exerciseProgress < 1.0) {
      activeTaskLabel = 'Egzersizini tamamla 🏋️';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'KİŞİSEL GÜN $dayNumber',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DailySuccessRing(
              productProgress: productProgress,
              waterProgress: waterProgress.clamp(0.0, 1.0),
              exerciseProgress: exerciseProgress,
              activeTaskLabel: activeTaskLabel,
              hasProgram: true,
              size: 140,
            ),
          ],
        ),
      ),
    );
  }

  /// Egzersiz tamamla/geri al toggle kartı
  Widget _buildExerciseToggleCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Consumer<ExerciseService>(
        builder: (context, exerciseService, _) {
          final isCompleted = exerciseService.todayCompleted;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFFFF7ED) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isCompleted ? const Color(0xFFF97316).withValues(alpha: 0.3) : AppColors.backgroundMuted,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => exerciseService.toggleExercise(!isCompleted),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFFF97316) : const Color(0xFFF97316).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : Icons.fitness_center_rounded,
                          color: isCompleted ? Colors.white : const Color(0xFFF97316),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCompleted ? 'Bugünkü Egzersiz Tamamlandı! 🎉' : 'Bugünkü Egzersizim',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isCompleted ? const Color(0xFFC2410C) : AppColors.nightSky,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCompleted ? 'Geri almak için dokun' : 'Tamamlamak için dokun',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Su takip modülü
  Widget _buildWaterTracker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Consumer<WaterProvider>(
        builder: (context, waterProvider, _) {
          final consumed = waterProvider.totalConsumed;
          final goal = waterProvider.dailyGoal;
          final progress = waterProvider.progress;
          final consumedL = (consumed / 1000).toStringAsFixed(1);
          final goalL = (goal / 1000).toStringAsFixed(1);

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF6E9),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water_drop, color: AppColors.primary, size: 20),
                          const SizedBox(width: 6),
                          const Text(
                            'Kişisel Su Tüketimim',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.nightSky),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${consumedL}L',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.nightSky),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ ${goalL}L',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          waterProvider.addWater(200);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('200ml su eklendi!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                '200ml Ekle',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => context.pushNamed(WaterTrackerScreen.routeName),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tüm Kayıtlar',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => context.pushNamed(WaterTrackerScreen.routeName),
                  child: _WaterGlassWidget(progress: progress),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Günlük Checklist (Rutinler)
  Widget _buildDailyChecklist(BuildContext context, List<DailyRoutineModel> rawRoutines, UserProfileModel userProfile) {
    final userId = userProfile.id;

    final incompleteRoutines = rawRoutines.where((r) => !r.isCompleted).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final completedRoutines = rawRoutines.where((r) => r.isCompleted).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    final routines = <DailyRoutineModel>[];
    if (incompleteRoutines.isNotEmpty) {
      routines.add(incompleteRoutines.first);
    }
    routines.addAll(completedRoutines);

    final completedCount = rawRoutines.where((r) => r.isCompleted).length;
    final totalCount = rawRoutines.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Kişisel Öğün Takibim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.nightSky),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  if (totalCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$completedCount/$totalCount Tamamlandı',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: 'Programı Sil',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Programı Sıfırla'),
                            content: const Text('Kişisel programın ve bugünkü rutinlerin tamamen silinecek. Emin misin?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Sıfırla', style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await context.read<ProgramProvider>().deleteProgram(userId);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      tooltip: 'Programı Düzenle',
                      onPressed: () => context.goNamed(CreateProgramScreen.routeName),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStitchChecklistItems(context, routines, userProfile),
        ],
      ),
    );
  }

  Widget _buildStitchChecklistItems(BuildContext context, List<DailyRoutineModel> routines, UserProfileModel userProfile) {
    final timeFormat = DateFormat('HH:mm');

    return ImplicitlyAnimatedList<DailyRoutineModel>(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      items: routines,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: (context, animation, routine, i) {
        Widget child;
        if (routine.isWaterStep) {
          child = _buildStitchChecklistTile(
            context: context,
            timeLabel: timeFormat.format(routine.scheduledTime),
            title: 'Su İç (500 ml)',
            isCompleted: routine.isCompleted,
            isNext: !routine.isCompleted && routines.where((r) => !r.isCompleted).firstOrNull?.id == routine.id,
            onChanged: (val) async {
              if (val != null && context.mounted) {
                await context.read<RoutineService>().updateRoutineStatus(userProfile.id, routine.id, val);
                if (context.mounted) {
                  if (val) {
                    context.read<WaterProvider>().addWater(500);
                  } else {
                    context.read<WaterProvider>().removeWater(500);
                  }
                }
              }
            },
            onTimeTap: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(routine.scheduledTime),
              );
              if (!context.mounted || newTime == null) return;
              final now = DateTime.now();
              await context.read<RoutineService>().updateRoutineTime(
                    userProfile.id,
                    routine.id,
                    DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute),
                  );
            },
          );
        } else if (routine.isNormalMealStep) {
          child = _buildStitchChecklistTile(
            context: context,
            timeLabel: timeFormat.format(routine.scheduledTime),
            title: routine.productId,
            isCompleted: routine.isCompleted,
            isNext: !routine.isCompleted && routines.where((r) => !r.isCompleted).firstOrNull?.id == routine.id,
            onChanged: (val) async {
              if (val != null) {
                final routineService = context.read<RoutineService>();
                await routineService.updateRoutineStatus(userProfile.id, routine.id, val);
              }
            },
            onTimeTap: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(routine.scheduledTime),
              );
              if (!context.mounted || newTime == null) return;
              final now = DateTime.now();
              await context.read<RoutineService>().updateRoutineTime(
                    userProfile.id,
                    routine.id,
                    DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute),
                  );
            },
          );
        } else {
          final product = context.read<ProductProvider>().products.firstWhere(
                (p) => p.id == routine.productId,
                orElse: () => ProductModel(id: '', name: 'Silinmiş Ürün', vp: 0),
              );

          child = _buildStitchChecklistTile(
            context: context,
            timeLabel: timeFormat.format(routine.scheduledTime),
            title: product.name,
            isCompleted: routine.isCompleted,
            isNext: !routine.isCompleted && routines.where((r) => !r.isCompleted).firstOrNull?.id == routine.id,
            onChanged: (val) async {
              if (val != null) {
                final routineService = context.read<RoutineService>();
                await routineService.updateRoutineStatus(userProfile.id, routine.id, val);
              }
            },
            onTimeTap: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(routine.scheduledTime),
              );
              if (!context.mounted || newTime == null) return;
              final now = DateTime.now();
              await context.read<RoutineService>().updateRoutineTime(
                    userProfile.id,
                    routine.id,
                    DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute),
                  );
            },
            onTap: () {
              final instruction = product.instructionsByGoal?[userProfile.userGoal ?? ''] ??
                  product.usageInfo ??
                  'Kullanım bilgisi bulunamadı.';
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.menu_book, color: AppColors.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.nightSky),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ürün Hazırlanışı ve Kullanımı',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.backgroundMuted),
                            ),
                            child: Text(
                              instruction,
                              style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.nightSky),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Anladım', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }

        return SizeFadeTransition(
          animation: animation,
          child: child,
        );
      },
    );
  }

  Widget _buildStitchChecklistTile({
    required BuildContext context,
    required String timeLabel,
    required String title,
    required bool isCompleted,
    required bool isNext,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onTimeTap,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNext ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => onChanged(!isCompleted),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? AppColors.primary : AppColors.textMutedLighter,
                    width: 2,
                  ),
                ),
                child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: onTimeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCompleted
                          ? AppColors.backgroundMutedLight
                          : isNext
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.backgroundMutedLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? AppColors.textMutedLight
                        : isNext
                            ? AppColors.primary
                            : AppColors.grey600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? AppColors.textMutedLight : AppColors.nightSky,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterGlassWidget extends StatelessWidget {
  final double progress;

  const _WaterGlassWidget({required this.progress});

  @override
  Widget build(BuildContext context) {
    final fillHeight = (progress * 100).clamp(5.0, 100.0);

    return Container(
      width: 88,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              height: 120 * (fillHeight / 100),
              decoration: BoxDecoration(
                color: Colors.blue.shade400.withValues(alpha: 0.8),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 8,
                      color: Colors.blue.shade300.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120 * (fillHeight / 100) * 0.3,
            left: 20,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 120 * (fillHeight / 100) * 0.6,
            right: 22,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: progress > 0.5 ? Colors.white : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
