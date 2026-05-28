import 'dart:io';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/avatar_color_helper.dart';
import '../../../models/customer_model.dart';
import '../../../models/user_profile_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/app_drawer.dart'; // AppDrawer'ı import et
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../customers/screens/add_edit_customer_screen.dart';
import '../../customers/screens/customer_detail_screen.dart'; // Navigasyon için
import '../../customers/screens/customer_list_screen.dart';
import '../../orders/providers/order_provider.dart';
import '../../orders/screens/add_edit_order_screen.dart';
import '../../orders/screens/order_list_screen.dart';

import '../../products/providers/product_provider.dart';
import '../../products/screens/add_edit_product_screen.dart';

import '../../profile/screens/profile_screen.dart';
import '../providers/home_provider.dart';
import '../../../models/user_role.dart';
import '../../../models/daily_routine_model.dart';
import '../../../models/product_model.dart';
import '../../../services/routine_service.dart';
import '../../program/screens/active_program_screen.dart';
import 'customer_progress_screen.dart';
import 'customer_products_screen.dart';
import 'customer_support_screen.dart';
import '../../program/screens/create_program_screen.dart';
import '../../program/providers/program_provider.dart';
import '../../water_tracker/screens/water_tracker_screen.dart';
import '../../water_tracker/providers/water_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/motivation_widget.dart';
import '../widgets/daily_success_ring.dart';
import '../../../services/exercise_service.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _customerNavIndex = 0;
  Stream<List<DailyRoutineModel>>? _routinesStream;
  Future<int>? _riskCountFuture;

  /// Özel gün, streak ve saate göre selamlama metni döndürür.
  /// [firstName] boşsa sadece "Merhaba!" döner.
  String _getGreeting(String firstName, {UserProfileModel? userProfile, int streak = 0}) {
    if (firstName.isEmpty) return 'Merhaba!';

    final now = DateTime.now();

    // 1. Doğum günü kontrolü
    if (userProfile?.birthDate != null) {
      final bd = userProfile!.birthDate!;
      if (bd.month == now.month && bd.day == now.day) {
        return 'Mutlu yıllar, $firstName! 🎂 Bugün kendinle gurur duy.';
      }
    }

    // 2. Programa başlama yıl dönümü (tam ay sayısı)
    if (userProfile?.programStartDate != null) {
      final start = userProfile!.programStartDate!;
      if (start.day == now.day && start.month != now.month) {
        final months = (now.year - start.year) * 12 + (now.month - start.month);
        if (months > 0) {
          return 'Tam $months aydır bu yoldasın, $firstName! Gurur verici. 🏆';
        }
      }
    }

    // 3. 7 günlük seri kontrolü
    if (streak >= 7) {
      return '7 günlük seride koşuyorsun, $firstName! Durma. 🔥';
    }

    // 4. Saat bazlı selamlama
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      return 'Günaydın, $firstName! Bugün harika görünüyorsun. ✨';
    } else if (hour >= 12 && hour < 18) {
      return 'İyi günler, $firstName! Enerjin nasıl? 💪';
    } else if (hour >= 18 && hour < 22) {
      return 'İyi akşamlar, $firstName! Bugünü değerlendirme zamanı. 🌙';
    } else {
      return 'Gece geç saatte varsın, $firstName. Dinlenmeyi unutma. 🌟';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.read<AuthProvider>().userProfile;
    if (userProfile != null && _routinesStream == null) {
      _routinesStream = context.read<RoutineService>().getDailyRoutines(userProfile.id, DateTime.now());
    }
    if (userProfile != null &&
        userProfile.role == UserRole.distributor &&
        _riskCountFuture == null) {
      _riskCountFuture = context
          .read<FirestoreService>()
          .getAtRiskCustomerCount(userProfile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserProfileModel? userProfile = authProvider.userProfile;

    if (userProfile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final orderProvider = Provider.of<OrderProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final bool isCustomer = userProfile.role == UserRole.customer ||
        (userProfile.role == UserRole.distributor && authProvider.isCustomerModeActive);

    return Scaffold(
      drawer: isCustomer ? null : const AppDrawer(),
      appBar: isCustomer
          ? null
          : AppBar(
              title: const Text('HerbaForm Panel'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  tooltip: 'Profilim',
                  onPressed: () {
                    context.goNamed(ProfileScreen.routeName);
                  },
                ),
              ],
            ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          if (isCustomer) {
            return _buildCustomerBody(context, authProvider, userProfile);
          }
          return _buildConsultantDashboard(
            context,
            userProfile,
            authProvider,
            orderProvider,
            customerProvider,
            productProvider,
            homeProvider,
          );
        },
      ),
      bottomNavigationBar: isCustomer
          ? _buildCustomerBottomNav(context)
          : null,
      floatingActionButton: isCustomer
          ? null
          : FloatingActionButton(
              onPressed: () {
                _showQuickAddMenu(context);
              },
              tooltip: 'Hızlı Ekle',
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildCustomerBody(BuildContext context, AuthProvider authProvider, UserProfileModel? userProfile) {
    switch (_customerNavIndex) {
      case 0:
        return _buildCustomerDashboard(context);
      case 1:
        return const ActiveProgramScreen();
      case 2:
        return const CustomerProgressScreen();
      case 3:
        return const CustomerProductsScreen();
      case 4:
        return const CustomerSupportScreen();
      default:
        return _buildCustomerDashboard(context);
    }
  }

  Widget _buildCustomerBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Ana Sayfa'),
                    _buildNavItem(1, Icons.list_alt_rounded, Icons.list_alt_outlined, 'Programım'),
                    const SizedBox(width: 64), // Orta buton için boşluk
                    _buildNavItem(3, Icons.school_rounded, Icons.school_outlined, 'Ürünler'),
                    _buildNavItem(4, Icons.support_agent_rounded, Icons.support_agent_outlined, 'Destek'),
                  ],
                ),
              ),
              // Orta Gelişim Butonu - Stitch HTML'ine sadık
              Positioned(
                top: -24,
                left: 0,
                right: 0,
                child: _buildNavCenterItem(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final bool isActive = _customerNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _customerNavIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.primary : Colors.grey.shade400,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.primary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCenterItem() {
    final bool isActive = _customerNavIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _customerNavIndex = 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF7F8F6), width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            'Gelişim',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  /// Müşteri (Customer) için özel dashboard
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
                      final streak = context.watch<HomeProvider>().completionStreak;
                      final greeting = _getGreeting(firstName, userProfile: userProfile, streak: streak);
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Distribütör paneline geri dönüldü.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 22),
                  tooltip: 'Distribütör Paneli',
                  padding: EdgeInsets.zero,
                ),
              ),
            StreamBuilder<List<DailyRoutineModel>>(
              stream: _routinesStream ?? const Stream.empty(),
              builder: (context, snapshot) {
                final routines = snapshot.data ?? [];
                final hasIncomplete = routines.any((r) => !r.isCompleted);
                final waterProgress = context.watch<WaterProvider>().progress;
                final hasWaterAlert = waterProgress < 0.5;
                final showBadge = hasIncomplete || hasWaterAlert;

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
                        onPressed: () => _showNotificationPanel(context, routines, waterProgress),
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
              const SizedBox(height: 16),
              _buildCustomerHeroProgress(context),
              const SizedBox(height: 12),
              _buildExerciseToggleCard(context),
              const SizedBox(height: 16),
              _buildCustomerWaterTracker(context),
              const SizedBox(height: 16),
              _buildCustomerDailyChecklist(context),
              const SizedBox(height: 16),
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

  /// Distributor header için avatar — gerçek fotoğraf varsa göster,
  /// yoksa isimden üretilen renkli baş harf dairesi.
  Widget _buildDistributorAvatar(BuildContext context, UserProfileModel? userProfile) {
    final name = userProfile?.name ?? '';
    final photoUrl = userProfile?.profilePhotoUrl;
    final userId = userProfile?.id;
    final photoUpdatedAt = userProfile?.profilePhotoUpdatedAt;

    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bgColor = AvatarColorHelper.forUser(userId);
    final textColor = AvatarColorHelper.textColorFor(bgColor);

    final isStale = photoUrl != null &&
        photoUrl.isNotEmpty &&
        photoUpdatedAt != null &&
        DateTime.now().difference(photoUpdatedAt).inDays > 90;

    Widget avatarContent;
    if (photoUrl != null && photoUrl.isNotEmpty &&
        !photoUrl.startsWith('/') && !photoUrl.startsWith('file://')) {
      avatarContent = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: 44,
        height: 44,
        errorBuilder: (context, error, stackTrace) => _buildInitialsWidget(initials, bgColor, textColor),
      );
    } else if (photoUrl != null && photoUrl.isNotEmpty &&
        !kIsWeb && (photoUrl.startsWith('/') || photoUrl.startsWith('file://'))) {
      avatarContent = Image.file(
        File(photoUrl.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        width: 44,
        height: 44,
        errorBuilder: (context, error, stackTrace) => _buildInitialsWidget(initials, bgColor, textColor),
      );
    } else {
      avatarContent = _buildInitialsWidget(initials, bgColor, textColor);
    }

    return Tooltip(
      message: isStale ? 'Profil fotoğrafını güncelle' : 'Profilim',
      child: GestureDetector(
        onTap: () => context.goNamed(ProfileScreen.routeName),
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
          child: ClipOval(child: avatarContent),
        ),
      ),
    );
  }

  /// Kritik aksiyonlar listesindeki müşteri satırı için
  /// isimden üretilen renkli baş harf avatar'ı.
  Widget _buildCustomerInitialsAvatar(
    String firstName,
    String lastName,
    String customerId,
  ) {
    final fullName = '$firstName $lastName'.trim();
    final initials = fullName.split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bgColor = AvatarColorHelper.forUser(customerId);
    final textColor = AvatarColorHelper.textColorFor(bgColor);

    return CircleAvatar(
      radius: 24,
      backgroundColor: bgColor,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// Danışman (Supervisor/Distributor) için Stitch tasarımlı dashboard
  Widget _buildConsultantDashboard(
    BuildContext context,
    UserProfileModel? userProfile,
    AuthProvider authProvider,
    OrderProvider orderProvider,
    CustomerProvider customerProvider,
    ProductProvider productProvider,
    HomeProvider homeProvider,
  ) {
    final monthlyVPTarget = userProfile?.monthlyVPTarget ?? 0;
    final vpEarnedThisMonth = orderProvider.totalVpEarnedThisMonth;
    final vpProgress = monthlyVPTarget > 0 ? (vpEarnedThisMonth / monthlyVPTarget) : 0.0;
    final recentActivations = customerProvider.recentlyActivatedCustomers;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildStitchHeader(
            context,
            userProfile,
            authProvider,
            recentActivations.length,
            recentActivations,
          ),
          const SizedBox(height: 8),
          FutureBuilder<int>(
            future: _riskCountFuture,
            builder: (context, snapshot) {
              return _buildKPICarousel(
                context,
                activeCustomers: customerProvider.customersCount,
                vpEarned: vpEarnedThisMonth,
                vpProgress: vpProgress,
                targetVp: monthlyVPTarget,
                riskCount: snapshot.data ?? 0,
              );
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Kritik Aksiyonlar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          _buildActionFilters(context),
          const SizedBox(height: 12),
          _buildStitchKritikAksiyonlarList(context, homeProvider, customerProvider),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Hızlı İşlemler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          _buildStitchQuickActions(context),
          const SizedBox(height: 80), // Fab için alt boşluk
        ],
      ),
    );
  }

  Widget _buildCustomerHeroProgress(BuildContext context) {
    final userProfile = context.read<AuthProvider>().userProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<List<DailyRoutineModel>>(
        stream: _routinesStream ?? const Stream.empty(),
        builder: (context, snapshot) {
          final routines = snapshot.data ?? [];
          final completedCount = routines.where((r) => r.isCompleted).length;
          final totalCount = routines.length;
          final hasProgram = totalCount > 0;
          final productProgress = hasProgram ? completedCount / totalCount : 0.0;

          // Su ilerleme oranı
          final waterProgress = context.watch<WaterProvider>().progress;

          // Egzersiz ilerleme oranı
          final exerciseProgress = context.watch<ExerciseService>().progress;

          // Gün sayısı: programStartDate'ten itibaren
          final startDate = userProfile?.programStartDate;
          final dayNumber = startDate != null
              ? DateTime.now().difference(startDate).inDays + 1
              : 1;

          // Aktif görev metni — ilk tamamlanmamış rutin
          String activeTaskLabel = '';
          if (hasProgram) {
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
          }

          // Program yoksa teşvik kartı göster
          if (!hasProgram && snapshot.connectionState != ConnectionState.waiting) {
            return GestureDetector(
              onTap: () => context.goNamed(CreateProgramScreen.routeName),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
                        color: AppColors.primary.withValues(alpha: 0.1),
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
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
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

          // Program varsa — Günlük Başarı Halkası
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Üst satır: "Gün X" badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _customerNavIndex = 1),
                      child: Container(
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
                  ],
                ),
                const SizedBox(height: 12),
                // Halka
                DailySuccessRing(
                  productProgress: productProgress,
                  waterProgress: waterProgress.clamp(0.0, 1.0),
                  exerciseProgress: exerciseProgress,
                  activeTaskLabel: activeTaskLabel,
                  hasProgram: hasProgram,
                  size: 200,
                ),
              ],
            ),
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
              color: isCompleted
                  ? const Color(0xFFFFF7ED) // açık turuncu
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFFF97316).withValues(alpha: 0.3)
                    : Colors.grey.shade200,
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
                                color: Colors.grey.shade500,
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
                              : Colors.grey.shade300,
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
    final userId = userProfile.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<List<DailyRoutineModel>>(
            stream: _routinesStream ?? const Stream.empty(),
            builder: (context, snapshot) {
              final rawRoutines = snapshot.data ?? [];
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık — Stitch: "Öğün Takibi" + "3/5 Tamamlandı" badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Öğün Takibi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nightSky,
                        ),
                      ),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          // Program yönetim butonları
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
                                    title: const Text('Programı Sil'),
                                    content: const Text('Aktif programın ve tüm rutinlerin silinecek. Emin misin?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: AppColors.error))),
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
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              tooltip: 'Program Oluştur',
                              onPressed: () => context.goNamed(CreateProgramScreen.routeName),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (routines.isEmpty)
                    _buildEmptyRoutineCard(context)
                  else
                    _buildStitchChecklistItems(context, routines, userProfile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Program yokken gösterilen boş durum kartı
  Widget _buildEmptyRoutineCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.event_note_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'Bugün için program yok.',
            style: TextStyle(color: Colors.grey, fontSize: 15),
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
      ),
    );
  }

  /// Stitch HTML'ine sadık checklist — sade checkbox + zaman etiketi + öğün adı
  Widget _buildStitchChecklistItems(
    BuildContext context,
    List<DailyRoutineModel> routines,
    UserProfileModel userProfile,
  ) {
    final timeFormat = DateFormat('HH:mm');

    return ImplicitlyAnimatedList<DailyRoutineModel>(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      items: routines,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: (context, animation, routine, i) {
        Widget child;
        // Su adımı için özel tile
        if (routine.isWaterStep) {
          child = _buildStitchChecklistTile(
            context: context,
            timeLabel: timeFormat.format(routine.scheduledTime),
            title: 'Su İç (500 ml)',
            isCompleted: routine.isCompleted,
            isNext: !routine.isCompleted && routines
                .where((r) => !r.isCompleted)
                .firstOrNull
                ?.id == routine.id,
            onChanged: (val) async {
              if (val != null && context.mounted) {
                await context.read<RoutineService>().updateRoutineStatus(
                  userProfile.id, routine.id, val,
                );
                if (context.mounted) {
                  if (val) {
                    context.read<WaterProvider>().addWater(500);
                  } else {
                    // İşareti kaldırınca su miktarını geri al
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
                userProfile.id, routine.id,
                DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute),
              );
            },
          );
        }

        // Normal Öğün adımı (Sağlıklı Tabak, vs.)
        else if (routine.isNormalMealStep) {
          child = _buildStitchChecklistTile(
            context: context,
            timeLabel: timeFormat.format(routine.scheduledTime),
            title: routine.productId, // Biz burada "Sağlıklı Tabak" vb. etiketi productId'de saklıyoruz.
            isCompleted: routine.isCompleted,
            isNext: !routine.isCompleted && routines
                .where((r) => !r.isCompleted)
                .firstOrNull
                ?.id == routine.id,
            onChanged: (val) async {
              if (val != null && context.mounted) {
                await context.read<RoutineService>().updateRoutineStatus(
                  userProfile.id, routine.id, val,
                );
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
                userProfile.id, routine.id,
                DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute),
              );
            },
            onTap: () {
              // Opsiyonel olarak, normal öğün için de tavsiyeler vb. gösterilebilir.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${routine.productId} zamanı!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        } else {

          // Ürün adımı
          final product = context.read<ProductProvider>().products.firstWhere(
            (p) => p.id == routine.productId,
            orElse: () => ProductModel(id: '', name: 'Silinmiş Ürün', vp: 0),
          );

          child = _buildStitchChecklistTile(
            context: context,
            timeLabel: timeFormat.format(routine.scheduledTime),
            title: product.name,
            isCompleted: routine.isCompleted,
            isNext: !routine.isCompleted && routines
                .where((r) => !r.isCompleted)
                .firstOrNull
                ?.id == routine.id,
            onChanged: (val) async {
              if (val != null && context.mounted) {
                await context.read<RoutineService>().updateRoutineStatus(
                  userProfile.id, routine.id, val,
                );
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
                userProfile.id, routine.id,
                DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute),
              );
            },
            onTap: () {
              // Tarif göster
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
                      // Sürükleme çubuğu
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
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

  /// Stitch HTML'ine sadık tek checklist satırı
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
            color: isNext
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
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
                    color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zaman etiketi
                  GestureDetector(
                    onTap: onTimeTap,
                    child: Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isCompleted
                            ? Colors.grey.shade400
                            : isNext
                                ? AppColors.primary
                                : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Öğün adı
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.grey.shade400 : AppColors.nightSky,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Stitch: bg-[#eef6e9] — açık yeşil
              color: const Color(0xFFEEF6E9),
              borderRadius: BorderRadius.circular(32),
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
                          const Icon(Icons.water_drop, color: AppColors.primary, size: 20),
                          const SizedBox(width: 6),
                          const Text(
                            'Su Tüketimi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.nightSky,
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
                              color: AppColors.nightSky,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ ${goalL}L',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // "200ml Ekle" butonu
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
                      // "Tüm Kayıtlar" text butonu
                      GestureDetector(
                        onTap: () => context.pushNamed(WaterTrackerScreen.routeName),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tüm Kayıtlar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
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
                // Sağ: animasyonlu su bardağı (tıklanabilir)
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

  Widget _buildStitchHeader(
    BuildContext context,
    UserProfileModel? userProfile,
    AuthProvider authProvider,
    int notificationCount,
    List<CustomerModel> recentActivations,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Distributor avatar — gerçek profil fotoğrafı veya baş harf
              _buildDistributorAvatar(context, userProfile),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final rawName = userProfile?.name ?? authProvider.firebaseUser?.email?.split('@')[0] ?? '';
                      final firstName = rawName.trim().split(' ').first;
                      return Text(
                        'Merhaba, $firstName',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.nightSky),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showRecentActivationSheet(context, recentActivations),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(Icons.notifications_outlined, color: Colors.grey.shade700, size: 22),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPICarousel(
    BuildContext context, {
    required int activeCustomers,
    required double vpEarned,
    required double vpProgress,
    required int targetVp,
    required int riskCount,
  }) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildKPICard(
            context,
            icon: Icons.group,
            value: '$activeCustomers',
            title: 'Müşteri',
            color: AppColors.primary,
            badgeText: '+5',
            onTap: () => context.goNamed(CustomerListScreen.routeName.substring(1)),
          ),
          const SizedBox(width: 12),
          _buildKPICard(
            context,
            icon: Icons.payments,
            value: '${vpEarned.toStringAsFixed(0)} VP',
            title: 'Bu Ayki VP',
            color: AppColors.rosemary,
            onTap: () => context.goNamed(OrderListScreen.routeName.substring(1)),
          ),
          const SizedBox(width: 12),
          _buildKPICard(
            context,
            icon: Icons.emoji_events,
            value: '%${(vpProgress * 100).toStringAsFixed(0)}',
            title: 'Hedef Başarısı',
            color: AppColors.grass,
            onTap: () => context.goNamed(ProfileScreen.routeName),
          ),
          const SizedBox(width: 12),
          _buildKPICard(
            context,
            icon: Icons.warning_amber_rounded,
            value: '$riskCount',
            title: 'Riskli Müşteri',
            color: AppColors.error,
            onTap: () => context.goNamed(CustomerListScreen.routeName.substring(1)),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String title,
    required Color color,
    String? badgeText,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (onTap != null && badgeText == null)
                  const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionFilters(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final active = homeProvider.activeFilter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            _buildFilterTab(
              context,
              label: 'Tümü',
              count: homeProvider.allCount,
              isActive: active == ActionFilter.all,
              activeColor: AppColors.primary,
              onTap: () => homeProvider.setFilter(ActionFilter.all),
            ),
            _buildFilterDivider(),
            _buildFilterTab(
              context,
              label: 'Riskli',
              count: homeProvider.overdueCount,
              isActive: active == ActionFilter.overdue,
              activeColor: AppColors.error,
              onTap: () => homeProvider.setFilter(ActionFilter.overdue),
            ),
            _buildFilterDivider(),
            _buildFilterTab(
              context,
              label: 'Ölçüm',

              count: homeProvider.measurementCount,
              isActive: active == ActionFilter.measurement,
              activeColor: Colors.teal,
              onTap: () => homeProvider.setFilter(ActionFilter.measurement),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context, {
    required String label,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildStitchKritikAksiyonlarList(BuildContext context, HomeProvider provider, CustomerProvider customerProvider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    final customerCounts = <String, int>{};
    final filteredTasks = provider.upcomingFollowUps.where((task) {
      final count = customerCounts[task.customerId] ?? 0;
      if (count < 2) {
        customerCounts[task.customerId] = count + 1;
        return true;
      }
      return false;
    }).toList();

    if (filteredTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Harika! Şu an için kritik bir aksiyon yok.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        final isOverdue = task.dueDate.toDate().isBefore(DateTime.now());
        final color = isOverdue ? AppColors.error : AppColors.laguna;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildCustomerInitialsAvatar(
              task.customerFirstName,
              task.customerLastName,
              task.customerId,
            ),
            title: Text('${task.customerFirstName} ${task.customerLastName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.nightSky), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(isOverdue ? 'Gecikmiş: ${task.title}' : task.title,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Container(
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.green.shade100)),
              child: IconButton(
                icon: Icon(Icons.chat, color: Colors.green.shade600, size: 20),
                onPressed: () {
                  // Önce provider'daki müşteri listesinde ara
                  final CustomerModel? found = () {
                    try {
                      return customerProvider.customers
                          .firstWhere((c) => c.id == task.customerId);
                    } catch (_) {
                      return null;
                    }
                  }();

                  if (found != null) {
                    context.goNamed(CustomerDetailScreen.routeName, extra: found);
                  } else {
                    // Müşteri listede yok — geçici bir CustomerModel ile detay ekranını aç
                    // (linkedUserId olmadığı için sağlık verileri görünmez ama takip notları eklenebilir)
                    final fallback = CustomerModel(
                      id: task.customerId,
                      consultantId: '',
                      firstName: task.customerFirstName,
                      lastName: task.customerLastName,
                      phoneNumber: '',
                      firstContactDate: task.dueDate,
                      isActive: false,
                      notes: 'Bu müşteri kaydı silinmiş veya erişilemiyor.',
                    );
                    context.goNamed(CustomerDetailScreen.routeName, extra: fallback);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStitchQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          // Yeni müşteri ekle → AddEditCustomerScreen
          _buildQuickActionCard(
            context,
            icon: Icons.person_add,
            label: 'Yeni Müşteri',
            color: AppColors.primary,
            onTap: () => context.goNamed(AddEditCustomerScreen.routeName),
          ),
          // Yeni sipariş oluştur → AddEditOrderScreen (etiket düzeltildi: "Stok Ekle" → "Yeni Sipariş")
          _buildQuickActionCard(
            context,
            icon: Icons.receipt_long,
            label: 'Yeni Sipariş',
            color: AppColors.rosemary,
            onTap: () => context.goNamed(AddEditOrderScreen.routeName),
          ),
          // Program yazmak için önce müşteri seçilmeli → CustomerListScreen
          _buildQuickActionCard(
            context,
            icon: Icons.people_alt_outlined,
            label: 'Müşterilerim',
            color: AppColors.grass,
            onTap: () => context.goNamed(CustomerListScreen.routeName.substring(1)),
          ),
          // Toplu mesaj henüz hazır değil → bilgilendirici snackbar
          _buildQuickActionCard(
            context,
            icon: Icons.broadcast_on_personal,
            label: 'Toplu Mesaj',
            color: Colors.grey.shade400,
            isDisabled: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toplu mesaj özelliği yakında geliyor.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap, bool isDisabled = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: isDisabled
              ? []
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.shade100
                    : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDisabled ? Colors.grey.shade400 : color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isDisabled)
              Text(
                'Yakında',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Yeni Müşteri Ekle'),
                onTap: () {
                  Navigator.pop(context);
                  context.goNamed(AddEditCustomerScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_checkout),
                title: const Text('Yeni Sipariş Oluştur'),
                onTap: () {
                  Navigator.pop(context);
                  context.goNamed(AddEditOrderScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_shopping_cart),
                title: const Text('Yeni Ürün Ekle'),
                onTap: () {
                  Navigator.pop(context);
                  context.goNamed(AddEditProductScreen.routeName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationPanel(
    BuildContext context,
    List<DailyRoutineModel> routines,
    double waterProgress,
  ) {
    final completedCount = routines.where((r) => r.isCompleted).length;
    final totalCount = routines.length;
    final incompleteRoutines = routines.where((r) => !r.isCompleted).toList();
    final waterPercent = (waterProgress * 100).round();
    final waterGoalMet = waterProgress >= 1.0;
    final waterLow = waterProgress < 0.5;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        // Bildirim öğelerini oluştur
        final List<_NotificationItem> items = [];

        // Su bildirimi
        if (waterGoalMet) {
          items.add(_NotificationItem(
            icon: Icons.water_drop,
            color: Colors.blue,
            title: 'Su hedefine ulaştın! 💧',
            subtitle: 'Günlük su hedefini tamamladın. Harika!',
          ));
        } else if (waterLow) {
          items.add(_NotificationItem(
            icon: Icons.water_drop_outlined,
            color: Colors.orange,
            title: 'Su içmeyi unutma!',
            subtitle: 'Bugün hedefinin yalnızca %$waterPercent\'ini tamamladın.',
            isAlert: true,
          ));
        }

        // Program bildirimleri
        if (totalCount == 0) {
          items.add(_NotificationItem(
            icon: Icons.event_note_outlined,
            color: Colors.grey,
            title: 'Bugün için program yok',
            subtitle: 'Danışmanın henüz program oluşturmadı.',
          ));
        } else if (completedCount == totalCount) {
          items.add(_NotificationItem(
            icon: Icons.check_circle_outline,
            color: AppColors.primary,
            title: 'Tüm öğünler tamamlandı! 🎉',
            subtitle: 'Bugünkü $totalCount öğünün hepsini tamamladın.',
          ));
        } else {
          // Tamamlanmamış öğünleri listele (max 3)
          final shown = incompleteRoutines.take(3).toList();
          for (final r in shown) {
            final timeFormat = DateFormat('HH:mm');
            items.add(_NotificationItem(
              icon: Icons.schedule_outlined,
              color: AppColors.primary,
              title: r.productId,
              subtitle: '${timeFormat.format(r.scheduledTime)} saatinde planlandı',
              isAlert: true,
            ));
          }
          if (incompleteRoutines.length > 3) {
            items.add(_NotificationItem(
              icon: Icons.more_horiz,
              color: Colors.grey,
              title: '+${incompleteRoutines.length - 3} öğün daha bekliyor',
              subtitle: 'Programını görüntülemek için tıkla',
            ));
          }
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
                else
                  ...items.map((item) => _buildNotificationTile(item)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(_NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isAlert
            ? item.color.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isAlert
              ? item.color.withValues(alpha: 0.2)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
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
                    color: item.isAlert ? AppColors.nightSky : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
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
    );
  }

  void _showRecentActivationSheet(
    BuildContext context,
    List<CustomerModel> recentActivations,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        if (recentActivations.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Yeni aktive olan müşteri bulunmuyor.'),
            ),
          );
        }

        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: recentActivations.length,
            separatorBuilder: (_, separatorIndex) =>
                const Divider(height: 1),
            itemBuilder: (sheetContext, index) {
              final customer = recentActivations[index];
              final activatedAt = customer.activatedAt?.toDate();
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text('${customer.firstName} ${customer.lastName}'.trim()),
                subtitle: Text(
                  activatedAt == null
                      ? 'Aktive tarihi yok'
                      : 'Aktive oldu: ${DateFormat('dd.MM.yyyy HH:mm').format(activatedAt)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.goNamed(
                    CustomerDetailScreen.routeName,
                    extra: customer,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Notification Item Model ─────────────────────────────────────────────────

class _NotificationItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isAlert;

  const _NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isAlert = false,
  });
}

// ─── Water Glass Widget ───────────────────────────────────────────────────────

/// Stitch HTML'indeki animasyonlu su bardağı görseli
class _WaterGlassWidget extends StatelessWidget {
  final double progress; // 0.0 - 1.0

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
          // Su dolum animasyonu
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
                  // Üst dalga efekti
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
          // Cam yansıması
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
          // Küçük baloncuklar
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
          // Yüzde etiketi
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
