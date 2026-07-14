import 'dart:io';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/avatar_color_helper.dart';
import '../../../../models/user_profile_model.dart';
import '../../../auth/providers/auth_provider.dart';

import '../../../products/providers/product_provider.dart';
import '../../../products/providers/recipe_provider.dart';
import '../../../products/widgets/recipe_detail_sheet.dart';
import '../../../../models/recipe_model.dart';

import '../../../profile/screens/profile_screen.dart';
import '../../providers/home_provider.dart';
import '../../../../models/user_role.dart';
import '../../../../models/daily_routine_model.dart';
import '../../../../models/product_model.dart';
import '../../../../services/routine_service.dart';
import '../../../program/screens/create_program_screen.dart';
import '../../../water_tracker/screens/water_tracker_screen.dart';
import '../../../water_tracker/providers/water_provider.dart';
import '../../../calorie_tracker/screens/calorie_tracker_screen.dart';
import '../../../calorie_tracker/providers/calorie_provider.dart';
import '../../../calorie_tracker/widgets/food_search_sheet.dart';
import '../../../step_tracker/providers/step_tracker_provider.dart';
import '../../../step_tracker/screens/step_tracker_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/motivation_widget.dart';
import '../../widgets/daily_compact_success_card.dart';
import '../../widgets/animated_water_glass.dart';
import '../../../../services/exercise_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/cloudinary_helper.dart';

class CustomerDashboardView extends StatefulWidget {
  final Stream<List<DailyRoutineModel>>? routinesStream;
  final VoidCallback onNavigateToProgram;

  const CustomerDashboardView({
    super.key,
    required this.routinesStream,
    required this.onNavigateToProgram,
  });

  @override
  State<CustomerDashboardView> createState() => _CustomerDashboardViewState();
}

class _CustomerDashboardViewState extends State<CustomerDashboardView>
    with SingleTickerProviderStateMixin {
  // ── Su kartı konfeti + pulse animasyonu ────────────────────────────────
  late final ConfettiController _waterConfettiController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _hasPlayedWaterConfetti = false;

  @override
  void initState() {
    super.initState();
    _loadLastSeenActivations();

    // Konfeti controller
    _waterConfettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Pulse animasyonu — "+200ml Ekle" butonu için
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waterConfettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSeenActivations() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('last_seen_activations');
    if (ms != null) {
      setState(() {
      });
    }
  }


  /// Özel gün, streak ve saate göre selamlama metni döndürür.
  /// [firstName] boşsa sadece "Merhaba!" döner.
  String _getAppBarGreeting(String firstName, {UserProfileModel? userProfile}) {
    if (firstName.isEmpty) return 'Merhaba!';
    final now = DateTime.now();
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      return 'Günaydın, $firstName! ☀️';
    } else if (hour >= 12 && hour < 18) {
      return 'İyi günler, $firstName! 👋';
    } else if (hour >= 18 && hour < 22) {
      return 'İyi akşamlar, $firstName! 🌙';
    } else {
      return 'İyi geceler, $firstName! 🌟';
    }
  }

  String _getDailyComment({UserProfileModel? userProfile, int streak = 0}) {
    final now = DateTime.now();

    // 1. Doğum günü kontrolü
    if (userProfile?.birthDate != null) {
      final bd = userProfile!.birthDate!;
      if (bd.month == now.month && bd.day == now.day) {
        return 'Bugün kendinle gurur duy. 🎂';
      }
    }

    // 2. Programa başlama yıl dönümü
    if (userProfile?.programStartDate != null) {
      final start = userProfile!.programStartDate!;
      if (start.day == now.day && start.month != now.month) {
        final months = (now.year - start.year) * 12 + (now.month - start.month);
        if (months > 0) {
          return 'Tam $months aydır bu yoldasın! 🏆';
        }
      }
    }

    // 3. Seri kontrolü
    if (streak >= 3) {
      return '$streak günlük seridesin! Durma. 🔥';
    }

    // 4. Standart yorumlar
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      return 'Bugün harika görünüyorsun. ✨';
    } else if (hour >= 12 && hour < 18) {
      return 'Enerjin nasıl? 💪';
    } else if (hour >= 18 && hour < 22) {
      return 'Bugünü değerlendirme zamanı. 🌙';
    } else {
      return 'Dinlenmeyi unutma. 🌟';
    }
  }

  /// Selamlama metnini iki parçaya böler: ön ek (gri) ve geri kalan (kalın).
  /// Örn: "Günaydın, Ali! Bugün harika görünüyorsun. ✨"
  ///   → prefix: "Günaydın,"  |  rest: "Ali! Bugün harika görünüyorsun. ✨"
  (String prefix, String rest) _splitGreeting(String greeting) {
    final commaIdx = greeting.indexOf(',');
    if (commaIdx != -1) {
      return (greeting.substring(0, commaIdx + 1), greeting.substring(commaIdx + 1).trim());
    }
    return ('', greeting);
  }




  @override
  Widget build(BuildContext context) {
    return _buildCustomerDashboard(context);
  }
  Widget _buildCustomerDashboard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final photoUrl = userProfile?.profilePhotoUrl;
    final name = userProfile?.name ?? '';
    final firstName = name.trim().split(' ').first;
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: false,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 2,
          toolbarHeight: 64,
          title: Row(
            children: [
              GestureDetector(
                onTap: () => context.goNamed(ProfileScreen.routeName),
                child: Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
                      ),
                      child: ClipOval(
                        child: _buildHeaderAvatar(photoUrl, initials, userProfile?.id, userProfile?.profilePhotoUpdatedAt),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: GestureDetector(
                  onTap: () => context.goNamed(ProfileScreen.routeName),
                  child: Builder(
                    builder: (context) {
                      final greeting = _getAppBarGreeting(firstName, userProfile: userProfile);
                      final (prefix, rest) = _splitGreeting(greeting);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (prefix.isNotEmpty)
                            Text(prefix, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w500)),
                          Text(
                            prefix.isNotEmpty ? rest : greeting,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis, maxLines: 1,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (userProfile?.role == UserRole.distributor && authProvider.isCustomerModeActive)
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    authProvider.toggleCustomerMode();
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 22),
                  tooltip: 'Distribütör Paneli',
                  padding: EdgeInsets.zero,
                ),
              ),
            StreamBuilder<List<DailyRoutineModel>>(
              stream: widget.routinesStream ?? const Stream.empty(),
              builder: (context, snapshot) {
                final routines = snapshot.data ?? [];
                final now = DateTime.now();
                
                // Sadece saati gelmiş veya geçmiş tamamlanmamış rutinler
                final hasDueIncomplete = routines.any((r) =>
                    !r.isCompleted &&
                    r.scheduledTime.isBefore(now.add(const Duration(minutes: 15))));
                
                final waterProgress = context.watch<WaterProvider>().progress;
                // Su düşükse ve en az bir su adımının saati geldiyse uyarı ver
                final hasDueWaterStep = routines.any((r) =>
                    r.isWaterStep && !r.isCompleted &&
                    r.scheduledTime.isBefore(now.add(const Duration(minutes: 15))));
                final hasWaterAlert = waterProgress < 0.5 && hasDueWaterStep;
                
                final showBadge = hasDueIncomplete || hasWaterAlert;

                return Stack(
                  children: [
                    Container(
                      width: 40, height: 40,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => _showNotificationPanel(context, routines),
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    if (showBadge)
                      Positioned(
                        right: 18, top: 8,
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              _buildCustomerHeroProgress(context),
              const SizedBox(height: 10),
              _buildCustomerDailyChecklist(context),
              const SizedBox(height: 10),
              _buildCustomerWaterTracker(context),
              const SizedBox(height: 10),
              _buildCustomerCalorieTracker(context),
              const SizedBox(height: 10),
              _buildExerciseToggleCard(context),
              const SizedBox(height: 10),
              _buildStepTrackerCard(context),
              const SizedBox(height: 10),
              const MotivationWidget(),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderAvatar(String? photoUrl, String initials, String? userId, DateTime? photoUpdatedAt) {
    final bgColor = AvatarColorHelper.forUser(userId);
    final textColor = AvatarColorHelper.textColorFor(bgColor);

    // 90 gün sarı halka kontrolü
    final isStale = photoUrl != null &&
        photoUrl.isNotEmpty &&
        photoUpdatedAt != null &&
        DateTime.now().difference(photoUpdatedAt).inDays > 90;

    Widget avatar;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if ((photoUrl.startsWith('/') || photoUrl.startsWith('file://')) && !kIsWeb) {
        avatar = Image.file(
          File(photoUrl.replaceFirst('file://', '')),
          fit: BoxFit.cover, width: 44, height: 44,
          errorBuilder: (context, error, stackTrace) => _buildInitialsWidget(initials, bgColor, textColor),
        );
      } else if (!photoUrl.startsWith('/') && !photoUrl.startsWith('file://')) {
        avatar = Image.network(
          photoUrl, fit: BoxFit.cover, width: 44, height: 44,
          errorBuilder: (context, error, stackTrace) => _buildInitialsWidget(initials, bgColor, textColor),
        );
      } else {
        avatar = _buildInitialsWidget(initials, bgColor, textColor);
      }
    } else {
      avatar = _buildInitialsWidget(initials, bgColor, textColor);
    }

    return Tooltip(
      message: isStale ? 'Fotoğrafını güncelle' : '',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isStale ? Colors.amber.shade400 : AppColors.primary,
            width: isStale ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isStale
                  ? Colors.amber.withAlpha(80)
                  : AppColors.primary.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(child: avatar),
      ),
    );
  }

  Widget _buildInitialsWidget(String initials, Color bgColor, Color textColor) {
    return Container(
      width: 44,
      height: 44,
      color: bgColor,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }


  /// Kritik aksiyonlar listesindeki müşteri satırı için
  /// isimden üretilen renkli baş harf avatar'ı.

  /// Danışman (Supervisor/Distributor) için Stitch tasarımlı dashboard
  Widget _buildCustomerHeroProgress(BuildContext context) {
    final userProfile = context.read<AuthProvider>().userProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<List<DailyRoutineModel>>(
        stream: widget.routinesStream ?? const Stream.empty(),
        builder: (context, snapshot) {
          final rawRoutines = snapshot.data ?? [];
          final routines = rawRoutines.where((r) => !r.isWaterStep).toList();
          final completedCount = routines.where((r) => r.isCompleted).length;
          final totalCount = routines.length;
          final hasProgram = totalCount > 0;
          final productProgress = hasProgram ? completedCount / totalCount : 0.0;

          // Su ilerleme oranı
          final waterProgress = context.watch<WaterProvider>().progress;

          // Egzersiz ilerleme oranı
          final exerciseProgress = context.watch<ExerciseService>().progress;

          // Streak ve Günlük yorum
          final streak = context.watch<HomeProvider>().completionStreak;
          final dailyComment = _getDailyComment(userProfile: userProfile, streak: streak);

          // Gün sayısı: programStartDate'ten itibaren
          final startDate = userProfile?.programStartDate;
          final dayNumber = startDate != null
              ? DateTime.now().difference(startDate).inDays + 1
              : 1;

          // Program yoksa teşvik kartı göster
          if (!hasProgram && snapshot.connectionState != ConnectionState.waiting) {
            return GestureDetector(
              onTap: () => context.goNamed(CreateProgramScreen.routeName),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rocket_launch_outlined, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Programını Başlat!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.nightSky),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hedeflerine ulaşmak için programını oluştur.',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }

          if (userProfile == null) return const SizedBox.shrink();

          // Program varsa — Yeni Kompakt Başarı Kartı
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst satır: "Gün X" badge ve Günlük Yorum
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => widget.onNavigateToProgram(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'GÜN $dayNumber',
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
                  ),
                  if (dailyComment.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        dailyComment,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.garden,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              DailyCompactSuccessCard(
                productProgress: productProgress,
                waterProgress: waterProgress.clamp(0.0, 1.0),
                exerciseProgress: exerciseProgress,
              ),
            ],
          );
        },
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
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCompleted
                    ? const [
                        Color(0xFFFFEAD2), // Tamamlanmış sıcak turuncu geçişi
                        Color(0xFFFFFFFF),
                      ]
                    : const [
                        Color(0xFFFFF8F2), // Tamamlanmamış hafif turuncu geçişi
                        Color(0xFFFFFFFF),
                      ],
              ),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFFF97316).withValues(alpha: 0.3)
                    : const Color(0xFFF97316).withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                          color: isCompleted
                              ? const Color(0xFFF97316)
                              : const Color(0xFFF97316).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_rounded
                              : Icons.fitness_center_rounded,
                          color: isCompleted
                              ? Colors.white
                              : const Color(0xFFF97316),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCompleted ? 'Egzersiz Tamamlandı! 🎉' : 'Bugünkü Egzersiz',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isCompleted
                                    ? const Color(0xFFC2410C)
                                    : AppColors.nightSky,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCompleted
                                  ? 'Geri almak için dokunun'
                                  : 'Tamamlamak için dokunun',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          key: ValueKey(isCompleted),
                          color: isCompleted
                              ? const Color(0xFFF97316)
                              : AppColors.textMutedLighter,
                          size: 28,
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

  Widget _buildCustomerDailyChecklist(BuildContext context) {
    final userProfile = context.read<AuthProvider>().userProfile;
    if (userProfile == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<List<DailyRoutineModel>>(
        stream: widget.routinesStream ?? const Stream.empty(),
        builder: (context, snapshot) {
          final rawRoutines = snapshot.data ?? [];
          final incompleteRoutines = rawRoutines.where((r) => !r.isCompleted).toList()
            ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
            
          // Tüm rutinler tamamlandıysa widget'ı tamamen gizle
          if (rawRoutines.isNotEmpty && incompleteRoutines.isEmpty) {
            return const SizedBox.shrink();
          }

          final routines = <DailyRoutineModel>[];
          if (incompleteRoutines.isNotEmpty) {
            routines.add(incompleteRoutines.first);
          }

          final completedCount = rawRoutines.where((r) => r.isCompleted).length;
          final totalCount = rawRoutines.length;
          final activeRoutine = incompleteRoutines.firstOrNull;
          final activeRoutineTimeStr = activeRoutine != null ? DateFormat('HH:mm').format(activeRoutine.scheduledTime) : null;

          final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

          return Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDCF2CE), // Taze fıstık yeşili
                  Color(0xFFE8F5E9), // Soft mint
                  Color(0xFFFFFFFF), // Beyaz
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              // İlerlemeye göre yoğunlaşan glow
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06 + progress * 0.12),
                  blurRadius: 14 + progress * 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              // Glassmorphism border
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.08 + progress * 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      // Başlık ikonu
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          color: Color(0xFF1B5E20),
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Öğün Takibi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const Spacer(),
                      // Saat — primary renk, sade rakam, simgesiz
                      if (activeRoutineTimeStr != null && activeRoutine != null)
                        GestureDetector(
                          onTap: () async {
                            final newTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(activeRoutine.scheduledTime),
                            );
                            if (!context.mounted || newTime == null) return;
                            final now = DateTime.now();
                            await context.read<RoutineService>().updateRoutineTime(
                              userProfile.id, activeRoutine.id,
                              DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute),
                            );
                          },
                          child: Text(
                            activeRoutineTimeStr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Segmented Progress Bar
                if (totalCount > 0) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildSegmentedProgressBar(completedCount, totalCount),
                  ),
                ],
                const SizedBox(height: 14),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (rawRoutines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _buildEmptyRoutineContent(context),
                  )
                else if (incompleteRoutines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _buildAllCompletedContent(context, rawRoutines.length),
                  )
                else
                  _buildStitchChecklistItems(context, routines, userProfile),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tüm öğünler tamamlandığında gösterilen tebrik içeriği
  Widget _buildAllCompletedContent(BuildContext context, int totalCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6E9), // Hafif yeşil arka plan
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 44, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text(
            'Tüm Öğünler Tamamlandı! 🎉',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.nightSky,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Bugünkü $totalCount öğünün hepsini başarıyla tamamladın. Harika bir gün!',
            style: TextStyle(color: AppColors.grey600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Program yokken gösterilen boş durum içeriği
  Widget _buildEmptyRoutineContent(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Icon(Icons.event_note_outlined, size: 48, color: AppColors.textMutedLighter),
        const SizedBox(height: 12),
        const Text(
          'Bugün için program yok.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Program Oluştur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => context.goNamed(CreateProgramScreen.routeName),
        ),
      ],
    );
  }

  /// Checklist — akıllı başlık + tarif fotoğrafı
  Widget _buildStitchChecklistItems(
    BuildContext context,
    List<DailyRoutineModel> routines,
    UserProfileModel userProfile,
  ) {
    return ImplicitlyAnimatedList<DailyRoutineModel>(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      items: routines,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: (context, animation, routine, i) {
        Widget child;
        // Su adımı
        if (routine.isWaterStep) {
          child = _buildStitchChecklistTile(
            context: context,
            title: 'Su İç (500 ml)',
            isCompleted: routine.isCompleted,
            isNext: !routine.isCompleted && routines
                .where((r) => !r.isCompleted)
                .firstOrNull
                ?.id == routine.id,
            isLast: i == routines.length - 1,
            onChanged: (val) async {
              if (val != null) {
                final routineService = context.read<RoutineService>();
                final waterProvider = context.read<WaterProvider>();
                
                await routineService.updateRoutineStatus(
                  userProfile.id, routine.id, val,
                );
                
                if (val) {
                  waterProvider.addWater(500);
                } else {
                  waterProvider.removeWater(500);
                }
              }
            },
          );
        }
        // Normal Öğün adımı
        else if (routine.isNormalMealStep) {
          child = _buildStitchChecklistTile(
            context: context,
            title: _getMealDisplayTitle(routine.productId),
            isCompleted: routine.isCompleted,
            isNext: !routine.isCompleted && routines
                .where((r) => !r.isCompleted)
                .firstOrNull
                ?.id == routine.id,
            isLast: i == routines.length - 1,
            onChanged: (val) async {
              if (val != null) {
                final routineService = context.read<RoutineService>();
                await routineService.updateRoutineStatus(
                  userProfile.id, routine.id, val,
                );
              }
            },
          );
        } else {
          // Ürün adımı
          final product = context.read<ProductProvider>().products.firstWhere(
            (p) => p.id == routine.productId,
            orElse: () => ProductModel(id: '', name: 'Silinmiş Ürün', vp: 0),
          );

          // Tarif fotoğrafı (shake ise)
          String? recipeImageUrl;
          RecipeModel? dailyRecipe;
          final isShake = _isShakeMeal(product.name);
          if (isShake) {
            dailyRecipe = context.read<RecipeProvider>().getRecipeForRoutine(userProfile.userGoal, routine.id);
            if (dailyRecipe != null) {
              recipeImageUrl = dailyRecipe.imageUrl;
            }
          }

          child = _buildStitchChecklistTile(
            context: context,
            title: _getMealDisplayTitle(product.name),
            isCompleted: routine.isCompleted,
            isNext: !routine.isCompleted && routines
                .where((r) => !r.isCompleted)
                .firstOrNull
                ?.id == routine.id,
            isLast: i == routines.length - 1,
            recipeImageUrl: recipeImageUrl,
            onChanged: (val) async {
              if (val != null) {
                final routineService = context.read<RoutineService>();
                await routineService.updateRoutineStatus(
                  userProfile.id, routine.id, val,
                );
              }
            },
            onTap: dailyRecipe != null ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RecipeDetailPage(recipe: dailyRecipe!),
                ),
              );
            } : () {
              // Tarif göster (ürün bilgisi)
              final instruction = product.instructionsByGoal?[userProfile.userGoal ?? '']
                  ?? product.usageInfo
                  ?? 'Kullanım bilgisi bulunamadı.';
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (ctx) => DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.5,
                  minChildSize: 0.3,
                  maxChildSize: 0.85,
                  builder: (_, scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.textMutedLighter,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(product.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.nightSky),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(instruction,
                              style: TextStyle(fontSize: 15, color: Colors.orange.shade900),
                              textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Anladım'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            animation: animation,
            child: child,
          );
        },
    );
  }

  /// Premium checklist tile — pulse rounded rect buton + tarif fotoğrafı
  Widget _buildStitchChecklistTile({
    required BuildContext context,
    required String title,
    required bool isCompleted,
    required bool isNext,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onTap,
    String? recipeImageUrl,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol: başlık + buton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Öğün başlığı
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isCompleted ? const Color(0xFF8CAF8F) : AppColors.primary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Tamamla butonu — nabız glow + ✓ ikonu
                      _PulseGlowButton(
                        isCompleted: isCompleted,
                        onTap: () => onChanged(!isCompleted),
                      ),
                    ],
                  ),
                ),
                // Sağ: tarif fotoğrafı (varsa)
                if (recipeImageUrl != null && recipeImageUrl.isNotEmpty) ...[
                  const SizedBox(width: 14),
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: CloudinaryHelper.optimizeImage(recipeImageUrl, width: 200) ?? recipeImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              child: const Center(
                                child: Icon(Icons.blender, color: AppColors.primary, size: 28),
                              ),
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              child: const Center(
                                child: Icon(Icons.blender, color: AppColors.primary, size: 28),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tarifi gör →',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.primary.withAlpha(35),
              ),
            ),
        ],
      ),
    );
  }

  /// Ürün adından akıllı başlık üretir
  String _getMealDisplayTitle(String name) {
    final n = name.toLowerCase();
    if (n.contains('formül 1') || n.contains('formul 1') ||
        n.contains('shake') || n.contains('f1') || n.contains('mama')) {
      return 'Shake Zamanı';
    }
    if (n.contains('çay') || n.contains('tea') || n.contains('herbal tea')) {
      return 'Çay Zamanı';
    }
    if (n.contains('aloe')) {
      return 'Aloe Zamanı';
    }
    if (n.contains('protein') || n.contains('bar')) {
      return 'Protein Zamanı';
    }
    if (n.contains('tabak') || n.contains('yemek') || n.contains('öğün') || n.contains('sağlıklı')) {
      return 'Öğün Zamanı';
    }
    // Bilinmeyen → ürün adı + Zamanı
    return '$name Zamanı';
  }

  /// Segmented Progress Bar — her öğün için bir segment
  Widget _buildSegmentedProgressBar(int completed, int total) {
    return Row(
      children: List.generate(total, (index) {
        final isFilled = index < completed;
        final isLast = index == total - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: isFilled ? 1.0 : 0.0),
              duration: Duration(milliseconds: 500 + index * 100),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: const Color(0xFFE0E0E0),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7AC144),
                            Color(0xFF22C55E),
                          ],
                        ),
                        boxShadow: value > 0.5
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
  Widget _buildCustomerWaterTracker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Consumer<WaterProvider>(
        builder: (context, waterProvider, _) {
          final consumed = waterProvider.totalConsumed; // ml
          final goal = waterProvider.dailyGoal; // ml
          final progress = waterProvider.progress; // 0.0 - 1.0
          final consumedL = (consumed / 1000).toStringAsFixed(1);
          final goalL = (goal / 1000).toStringAsFixed(1);

          const blueAccent = Color(0xFF26B0EF); // #26b0ef
          const blueTextDark = Color(0xFF1E3A8A); // Koyu lacivert başlık/yazı

          // %100 konfeti tetikleme
          if (progress >= 1.0 && !_hasPlayedWaterConfetti) {
            _hasPlayedWaterConfetti = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _waterConfettiController.play();
            });
          } else if (progress < 1.0) {
            _hasPlayedWaterConfetti = false;
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Ana kart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  // Açık tema gradient
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEBF3FF), // Yumuşak açık mavi
                      Color(0xFFF0F9FF), // Daha açık mavi
                      Color(0xFFFFFFFF), // Beyaz
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  // Glassmorphism border
                  border: Border.all(
                    color: blueAccent.withValues(alpha: 0.12 + progress * 0.15),
                  ),
                  // Su seviyesine göre yoğunlaşan glow
                  boxShadow: [
                    BoxShadow(
                      color: blueAccent.withValues(alpha: 0.06 + progress * 0.1),
                      blurRadius: 16 + progress * 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Sol: metin + buton
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Başlık
                          Row(
                            children: [
                              // Animasyonlu su damlası ikonu
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: progress),
                                duration: const Duration(milliseconds: 800),
                                builder: (context, value, child) {
                                  return ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        blueAccent,
                                        blueAccent.withValues(alpha: 0.4),
                                      ],
                                      stops: [value, value + 0.01],
                                    ).createShader(bounds),
                                    child: const Icon(
                                      Icons.water_drop,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Su Tüketimi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: blueTextDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Miktar
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${consumedL}L',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: blueTextDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ ${goalL}L',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: blueTextDark.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // "200ml Ekle" butonu — pulse animasyonlu
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: child,
                              );
                            },
                            child: GestureDetector(
                              onTap: () {
                                waterProvider.addWater(200);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF26B0EF),
                                      Color(0xFF1A8FD1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: blueAccent.withValues(alpha: 0.3),
                                      blurRadius: 10,
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // "Tüm Kayıtlar" text butonu
                          GestureDetector(
                            onTap: () => context.pushNamed(WaterTrackerScreen.routeName),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tüm Kayıtlar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: blueAccent,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right, color: blueAccent, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sağ: 3D animasyonlu su bardağı (tıklanabilir)
                    GestureDetector(
                      onTap: () => context.pushNamed(WaterTrackerScreen.routeName),
                      child: AnimatedWaterGlass(progress: progress),
                    ),
                  ],
                ),
              ),
              // Konfeti — kart üzerinden patlar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _waterConfettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    numberOfParticles: 20,
                    maxBlastForce: 12,
                    minBlastForce: 4,
                    emissionFrequency: 0.06,
                    gravity: 0.12,
                    colors: const [
                      Color(0xFF26B0EF), // Cyan
                      Color(0xFF3B82F6), // Mavi
                      Color(0xFF7DD3FC), // Açık mavi
                      Color(0xFF22C55E), // Yeşil
                      Color(0xFFFBBF24), // Altın
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Müşteri dashboard'ında bugünün kalori durumunu gösteren kart.
  /// Su kartıyla aynı kalıp, sıcak (peach) tonda.
  Widget _buildCustomerCalorieTracker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Consumer<CalorieProvider>(
        builder: (context, calorie, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              final userProfile = context.read<AuthProvider>().userProfile;
              final exerciseLevel =
                  context.read<WaterProvider>().todaySummary?.exerciseLevel ??
                      'moderate';
              calorie.recomputeIfAuto(
                profile: userProfile,
                exerciseLevel: exerciseLevel,
              );
            }
          });

          final consumed = calorie.totalCalories;
          final goal = calorie.calorieGoal;
          final progress = calorie.progress.clamp(0.0, 1.0);
          final overGoal = consumed > goal;
          final accent = overGoal
              ? const Color(0xFFE65100) // koyu turuncu — hedef aşımı
              : const Color(0xFFFE9836); // #fe9836
          final orangeTextDark = overGoal ? const Color(0xFF7C2D12) : const Color(0xFF9A3412); // Koyu kahve/turuncu tonları

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF1E0), // Açık şeftali tonu
                  Color(0xFFFFFFFF), // Beyaz
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFFE9836).withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol: başlık + miktar + butonlar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              color: accent, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Kalori Takibi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: orangeTextDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$consumed',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: orangeTextDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ $goal kcal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: orangeTextDark.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                      if (overGoal) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Hedefi ${consumed - goal} kcal aştın',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Öğün ekle butonu — inline dialog açar
                      GestureDetector(
                        onTap: () => _showCalorieAddDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.25),
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
                                'Öğün Ekle',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => context
                            .pushNamed(CalorieTrackerScreen.routeName),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tüm Kayıtlar',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: accent),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right,
                                color: accent, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Sağ: progress halkası
                GestureDetector(
                  onTap: () =>
                      context.pushNamed(CalorieTrackerScreen.routeName),
                  child: _CalorieProgressRing(
                    progress: progress,
                    consumed: consumed,
                    goal: goal,
                    accent: accent,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Dashboard'dan hızlı kalori girişi — FoodSearchSheet'i açar.
  /// CalorieTrackerScreen'deki sheet ile aynı widget, kullanıcı ekran
  /// değiştirmek zorunda kalmadan ana ekrandan ekleyebilir.
  Future<void> _showCalorieAddDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FoodSearchSheet(),
    );
  }




  // ───── Kritik Aksiyon satır eylemleri ─────────────────────────────────

  /// Follow-up satırından "Ara" tıklandığında çağrılır. Müşterinin
  /// telefon numarasını normalize edip `tel:` URL ile arar.

  /// Follow-up satırından "WhatsApp" tıklandığında çağrılır. Hazır
  /// selamlama mesajıyla wa.me deep link'ini açar.


  /// Follow-up'ı tamamlanmış olarak işaretler.




  /// Tek bir kritik aksiyon satırı: üstte avatar + müşteri + görev,
  /// altta 3 mini aksiyon (Ara / WhatsApp / Ertele).




  void _showNotificationPanel(BuildContext context, List<DailyRoutineModel> routines) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Consumer<WaterProvider>(
            builder: (context, waterProvider, _) {
              final waterProgress = waterProvider.progress;
              return _buildNotificationContent(
                context: context,
                routines: routines,
                waterProgress: waterProgress,
              );
            },
          ),
        );
      },
    );
  }

  /// Bildirim panelinin asıl içeriğini oluşturur.
  /// _showNotificationPanel'den ayrıldı ki stream null olduğunda da çağrılabilsin.
  Widget _buildNotificationContent({
    required BuildContext context,
    required List<DailyRoutineModel> routines,
    required double waterProgress,
  }) {
    final now = DateTime.now();
    final completedCount = routines.where((r) => r.isCompleted).length;
    final totalCount = routines.length;
    final dueIncompleteRoutines = routines.where((r) =>
        !r.isCompleted && r.scheduledTime.isBefore(now.add(const Duration(minutes: 15)))).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final waterPercent = (waterProgress * 100).round();
    final hasDueWaterStep = routines.any((r) =>
        r.isWaterStep && !r.isCompleted &&
        r.scheduledTime.isBefore(now.add(const Duration(minutes: 15))));
    final waterLow = waterProgress < 0.5 && hasDueWaterStep;

    final List<_NotificationItem> items = [];

    if (waterLow) {
      items.add(_NotificationItem(
        icon: Icons.water_drop_outlined,
        color: Colors.blue,
        title: 'Su içmeyi unutma!',
        subtitle: 'Bugün hedefinin yalnızca %$waterPercent\'ini tamamladın.',
        isAlert: true,
        actionType: NotificationActionType.waterAlert,
      ));
    }

    if (totalCount == 0) {
      items.add(const _NotificationItem(
        icon: Icons.event_note_outlined,
        color: AppColors.textMuted,
        title: 'Bugün için program yok',
        subtitle: 'Danışmanın henüz program oluşturmadı.',
        actionType: NotificationActionType.info,
      ));
    } else {
      if (dueIncompleteRoutines.isNotEmpty) {
        final shown = dueIncompleteRoutines.take(3).toList();
        for (final r in shown) {
          final timeFormat = DateFormat('HH:mm');
          NotificationActionType actionType;
          String? titleText;
          
          if (r.isWaterStep) {
            actionType = NotificationActionType.waterRoutine;
            titleText = 'Su İç (500 ml)';
          } else if (r.isNormalMealStep) {
            actionType = NotificationActionType.mealRoutine;
            titleText = r.productId;
          } else {
            actionType = NotificationActionType.productRoutine;
            final product = context.read<ProductProvider>().products.firstWhere(
              (p) => p.id == r.productId,
              orElse: () => ProductModel(id: '', name: 'Silinmiş Ürün', vp: 0),
            );
            titleText = product.name;
          }

          final isOverdue = r.scheduledTime.isBefore(now);
          items.add(_NotificationItem(
            icon: r.isWaterStep ? Icons.water_drop_outlined : Icons.schedule_outlined,
            color: r.isWaterStep ? Colors.blue : (isOverdue ? AppColors.error : AppColors.primary),
            title: titleText,
            subtitle: isOverdue
                ? '${timeFormat.format(r.scheduledTime)} saatinde planlanmıştı — gecikmiş!'
                : '${timeFormat.format(r.scheduledTime)} saatinde planlandı',
            isAlert: true,
            actionType: actionType,
            routineId: r.id,
            productId: r.productId,
            routine: r,
          ));
        }
        if (dueIncompleteRoutines.length > 3) {
          items.add(_NotificationItem(
            icon: Icons.more_horiz,
            color: AppColors.textMuted,
            title: '+${dueIncompleteRoutines.length - 3} görev daha bekliyor',
            subtitle: 'Programını görüntülemek için tıkla',
            actionType: NotificationActionType.info,
          ));
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bildirimler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.nightSky,
                    ),
                  ),
                if (totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$completedCount/$totalCount Tamamlandı',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Şu an için bildirim yok. 🎉',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                  ),
                ),
              )
            else
              ...items.map((item) => _buildNotificationTile(context, item)),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, _NotificationItem item) {
    final userProfile = context.read<AuthProvider>().userProfile;
    final hasActions = item.actionType != NotificationActionType.info;
    final isMoreItem = item.icon == Icons.more_horiz;

    Widget tileContent = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isAlert
            ? item.color.withValues(alpha: 0.06)
            : AppColors.backgroundMutedLighter,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isAlert
              ? item.color.withValues(alpha: 0.2)
              : AppColors.backgroundMutedLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: item.isAlert ? AppColors.nightSky : AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isAlert)
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          if (hasActions && userProfile != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // İncele / Detay Butonu
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (item.actionType == NotificationActionType.waterAlert || item.actionType == NotificationActionType.waterRoutine) {
                      context.pushNamed(WaterTrackerScreen.routeName);
                    } else if (item.actionType == NotificationActionType.productRoutine || item.actionType == NotificationActionType.mealRoutine) {
                      setState(() {
                      });
                    }
                  },
                  icon: Icon(Icons.open_in_new, size: 14, color: item.color),
                  label: Text(
                    'İncele',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.color,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                // Tamam Butonu
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context); // Bildirimi kapat
                    
                    if (item.actionType == NotificationActionType.waterAlert) {
                      context.read<WaterProvider>().addWater(250);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('250 ml su eklendi! 💧'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else if (item.actionType == NotificationActionType.waterRoutine && item.routineId != null) {
                      final routineService = context.read<RoutineService>();
                      final waterProvider = context.read<WaterProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      await routineService.updateRoutineStatus(
                        userProfile.id,
                        item.routineId!,
                        true,
                      );
                      waterProvider.addWater(500);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Su adımı tamamlandı ve 500 ml su eklendi! 💧'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else if (item.routineId != null) {
                      final routineService = context.read<RoutineService>();
                      final messenger = ScaffoldMessenger.of(context);
                      await routineService.updateRoutineStatus(
                        userProfile.id,
                        item.routineId!,
                        true,
                      );

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('${item.title} tamamlandı! 🎉'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 14, color: Colors.white),
                  label: const Text(
                    'Tamam',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.color,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (isMoreItem) {
      return InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(14),
        child: tileContent,
      );
    }

    return tileContent;
  }

}

// ─── Notification Item Model ─────────────────────────────────────────────────

enum NotificationActionType {
  waterAlert,
  waterRoutine,
  mealRoutine,
  productRoutine,
  info,
}

class _NotificationItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isAlert;
  final NotificationActionType actionType;
  final String? routineId;
  final String? productId;
  final DailyRoutineModel? routine;

  const _NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isAlert = false,
    this.actionType = NotificationActionType.info,
    this.routineId,
    this.productId,
    this.routine,
  });
}

// ─── Water Glass Widget ───────────────────────────────────────────────────────

/// Stitch HTML'indeki animasyonlu su bardağı görseli
// _WaterGlassWidget kaldırıldı — yerine AnimatedWaterGlass kullanılıyor
// (lib/features/home/widgets/animated_water_glass.dart)

/// Kalori kartının sağında gösterilen dairesel ilerleme halkası.
/// Su bardağı widget'ının kalori karşılığı.
class _CalorieProgressRing extends StatelessWidget {
  final double progress; // 0.0 - 1.0 (clamp'lı)
  final int consumed;
  final int goal;
  final Color accent;

  const _CalorieProgressRing({
    required this.progress,
    required this.consumed,
    required this.goal,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              Text(
                goal > 0 ? 'hedef' : '-',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

Widget _buildStepTrackerCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<StepTrackerProvider>(
        builder: (context, tracker, _) {
          final ready = tracker.isReady;
          final progressText = ready
              ? '${NumberFormat.decimalPattern('tr_TR').format(tracker.todaySteps)} / ${NumberFormat.decimalPattern('tr_TR').format(tracker.dailyGoal)} adım'
              : 'Adımlarını takip etmek için dokun';
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => context.pushNamed(StepTrackerScreen.routeName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1FBF7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.aqua.withValues(alpha: 0.24)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: AppColors.aqua, shape: BoxShape.circle),
                      child: const Icon(Icons.directions_walk_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Günlük Adımlarım', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.nightSky)),
                          const SizedBox(height: 3),
                          Text(progressText, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.aqua),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
}

/// Kritik Aksiyonlar listesindeki satır içi 3 mini buton (Ara / WA / Ertele).
/// Kompakt, ikonlu, renk-vurgulu. Disabled state için soluk gri.

bool _isShakeMeal(String name) {
  final n = name.toLowerCase();
  return n.contains('formül 1') ||
      n.contains('formul 1') ||
      n.contains('shake') ||
      n.contains('şek') ||
      n.contains('mama') ||
      n.contains('f1');
}

/// Nabız glow efektli tamamla butonu
/// Sürekli atan pulse glow ring + tıklayınca bounce ile dolma
class _PulseGlowButton extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  const _PulseGlowButton({
    required this.isCompleted,
    required this.onTap,
  });

  @override
  State<_PulseGlowButton> createState() => _PulseGlowButtonState();
}

class _PulseGlowButtonState extends State<_PulseGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (!widget.isCompleted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PulseGlowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _pulseController.stop();
    } else if (!widget.isCompleted && oldWidget.isCompleted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = _pulseController.value;
          final isCompleted = widget.isCompleted;
          final scale = isCompleted ? 1.0 : 0.96 + (pulse * 0.08);

          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isCompleted
                    ? AppColors.primary
                    : Colors.white,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.primary
                      : AppColors.primary.withValues(
                          alpha: 0.5 + pulse * 0.5,
                        ),
                  width: isCompleted ? 1.5 : 1.5 + pulse * 0.5,
                ),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: 0.05 + pulse * 0.15,
                          ),
                          blurRadius: 4 + pulse * 8,
                          spreadRadius: pulse * 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Text(
                isCompleted ? '✓ Tamamlandı' : 'Tamamla',
                style: TextStyle(
                  color: isCompleted ? Colors.white : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

