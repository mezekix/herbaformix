import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/avatar_color_helper.dart';
import '../../../models/user_profile_model.dart';
import '../../../widgets/app_drawer.dart'; // AppDrawer'ı import et
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../customers/screens/add_edit_customer_screen.dart';
import '../../customers/screens/customer_detail_screen.dart'; // Navigasyon için
import '../../customers/screens/customer_list_screen.dart';
import '../../orders/providers/order_provider.dart';
import '../../orders/screens/add_edit_order_screen.dart';

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

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _customerNavIndex = 0;
  Stream<List<DailyRoutineModel>>? _routinesStream;

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
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final UserProfileModel? userProfile = authProvider.userProfile;
    final bool isCustomer = userProfile?.role == UserRole.customer;

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
          backgroundColor: const Color(0xFFF7F8F6),
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
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
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
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
                            Text(prefix, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
                          Text(
                            prefix.isNotEmpty ? rest : greeting,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.nightSky),
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
            Stack(
              children: [
                Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_outlined, color: Colors.grey.shade700, size: 22),
                    padding: EdgeInsets.zero,
                  ),
                ),
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
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildCustomerHeroProgress(context),
              const SizedBox(height: 16),
              _buildCustomerWaterTracker(context),
              const SizedBox(height: 16),
              _buildCustomerDailyChecklist(context),
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
          errorBuilder: (_, _, _) => _buildInitialsWidget(initials, bgColor, textColor),
        );
      } else if (!photoUrl.startsWith('/') && !photoUrl.startsWith('file://')) {
        avatar = Image.network(
          photoUrl, fit: BoxFit.cover, width: 44, height: 44,
          errorBuilder: (_, _, _) => _buildInitialsWidget(initials, bgColor, textColor),
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildStitchHeader(context, userProfile, authProvider),
          const SizedBox(height: 8),
          _buildKPICarousel(
            context,
            activeCustomers: customerProvider.customersCount,
            vpEarned: vpEarnedThisMonth,
            vpProgress: vpProgress,
            targetVp: monthlyVPTarget,
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
          final progress = hasProgram ? completedCount / totalCount : 0.0;
          final progressPct = (progress * 100).round();

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

          // Program varsa normal progress kartı
          final motivationText = progressPct >= 80
              ? 'Muhteşem Gidiyorsun! 🔥'
              : progressPct >= 50
                  ? 'Bugün Harika\nGidiyorsun!'
                  : progressPct > 0
                      ? 'Devam Et, Yapabilirsin!'
                      : 'Güne Başlayalım!';

          return Container(
            padding: const EdgeInsets.all(24),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Gün X" badge
                      GestureDetector(
                        onTap: () => setState(() => _customerNavIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      const SizedBox(height: 12),
                      Text(
                        motivationText,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.nightSky,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hedeflerinin %$progressPct\'i tamamlandı',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Text(
                          '%$progressPct',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.nightSky),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              final routines = snapshot.data ?? [];
              final completedCount = routines.where((r) => r.isCompleted).length;
              final totalCount = routines.length;

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

    return Column(
      children: routines.map((routine) {
        // Su adımı için özel tile
        if (routine.isWaterStep) {
          return _buildStitchChecklistTile(
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
        if (routine.isNormalMealStep) {
          return _buildStitchChecklistTile(
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
        }

        // Ürün adımı
        final product = context.read<ProductProvider>().products.firstWhere(
          (p) => p.id == routine.productId,
          orElse: () => ProductModel(id: '', name: 'Silinmiş Ürün', vp: 0),
        );

        return _buildStitchChecklistTile(
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
                ?? 'Özel bir tarif bulunamadı.';
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
      }).toList(),
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
                        onTap: () => context.goNamed(WaterTrackerScreen.routeName),
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
                  onTap: () => context.goNamed(WaterTrackerScreen.routeName),
                  child: _WaterGlassWidget(progress: progress),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStitchHeader(BuildContext context, UserProfileModel? userProfile, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  image: const DecorationImage(
                    image: NetworkImage('https://ui-avatars.com/api/?name=Distributor&background=random'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final rawName = userProfile?.name ?? authProvider.firebaseUser?.email?.split('@')[0] ?? '';
                      final firstName = rawName.trim().split(' ').first;
                      final streak = context.watch<HomeProvider>().completionStreak;
                      final greeting = _getGreeting(firstName, userProfile: userProfile, streak: streak);
                      final (prefix, rest) = _splitGreeting(greeting);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (prefix.isNotEmpty)
                            Text(prefix, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(
                            prefix.isNotEmpty ? rest : greeting,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.nightSky),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(Icons.notifications_outlined, color: Colors.grey.shade700, size: 22),
              ),
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPICarousel(BuildContext context, {required int activeCustomers, required double vpEarned, required double vpProgress, required int targetVp}) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildKPICard(context, icon: Icons.group, value: '$activeCustomers', title: 'Müşteri', color: AppColors.primary, badgeText: '+5'),
          const SizedBox(width: 12),
          _buildKPICard(context, icon: Icons.payments, value: '${vpEarned.toStringAsFixed(0)} VP', title: 'Bu Ayki VP', color: AppColors.rosemary),
          const SizedBox(width: 12),
          _buildKPICard(context, icon: Icons.emoji_events, value: '%${(vpProgress * 100).toStringAsFixed(0)}', title: 'Hedef Başarısı', color: AppColors.grass),
          const SizedBox(width: 12),
          _buildKPICard(context, icon: Icons.warning_amber_rounded, value: '0', title: 'Riskli Müşteri', color: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildKPICard(BuildContext context, {required IconData icon, required String value, required String title, required Color color, String? badgeText}) {
    return Container(
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
    );
  }

  Widget _buildActionFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Riskli', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                  ],
                ),
              ),
            ),
            Expanded(child: Container(alignment: Alignment.center, child: Text('İade Riski', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)))),
            Expanded(child: Container(alignment: Alignment.center, child: Text('Ölçüm', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)))),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchKritikAksiyonlarList(BuildContext context, HomeProvider provider, CustomerProvider customerProvider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.upcomingFollowUps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Harika! Şu an için kritik bir aksiyon yok.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.upcomingFollowUps.length,
      itemBuilder: (context, index) {
        final task = provider.upcomingFollowUps[index];
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
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${task.customerFirstName}+${task.customerLastName}&background=random'),
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
                  try {
                    final customer = customerProvider.customers.firstWhere((c) => c.id == task.customerId);
                    context.goNamed(CustomerDetailScreen.routeName, extra: customer);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Müşteri bulunamadı.')));
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
          _buildQuickActionCard(context, icon: Icons.person_add, label: 'Yeni Müşteri', color: AppColors.primary, onTap: () => context.goNamed(AddEditCustomerScreen.routeName)),
          _buildQuickActionCard(context, icon: Icons.inventory_2, label: 'Stok Ekle', color: AppColors.rosemary, onTap: () => context.goNamed(AddEditOrderScreen.routeName)),
          _buildQuickActionCard(context, icon: Icons.edit_calendar, label: 'Program Yaz', color: AppColors.grass, onTap: () => context.goNamed(CustomerListScreen.routeName.substring(1))),
          _buildQuickActionCard(context, icon: Icons.broadcast_on_personal, label: 'Toplu Mesaj', color: Colors.grey.shade600, onTap: () => context.goNamed(CustomerListScreen.routeName.substring(1))),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color == Colors.grey.shade600 ? Colors.grey.shade100 : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
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
