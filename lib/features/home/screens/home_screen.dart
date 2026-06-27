import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_colors.dart';
import '../../../core/avatar_color_helper.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../models/customer_model.dart';
import '../../../models/scheduled_follow_up_model.dart';
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
import '../../products/screens/product_list_screen.dart';

import '../../profile/screens/profile_screen.dart';
import '../providers/home_provider.dart';
import '../../../models/user_role.dart';
import '../../../models/daily_routine_model.dart';
import '../../../services/routine_service.dart';
import '../../program/screens/active_program_screen.dart';
import 'customer_progress_screen.dart';
import 'customer_support_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/customer_dashboard_view.dart';
import '../widgets/vp_pulse_card.dart';
import '../widgets/today_actions_strip.dart';
import '../widgets/customer_pipeline_bar.dart';
import '../widgets/recent_activity_feed.dart';
import '../widgets/critical_actions_states.dart';

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
  String? _lastUserId;
  DateTime? _lastSeenActivations;

  @override
  void initState() {
    super.initState();
    _loadLastSeenActivations();
  }

  Future<void> _loadLastSeenActivations() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('last_seen_activations');
    if (ms != null) {
      setState(() {
        _lastSeenActivations = DateTime.fromMillisecondsSinceEpoch(ms);
      });
    }
  }

  Future<void> _markActivationsAsSeen() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_seen_activations', now.millisecondsSinceEpoch);
    if (mounted) {
      setState(() {
        _lastSeenActivations = now;
      });
    }
  }

  /// Özel gün, streak ve saate göre selamlama metni döndürür.
  /// [firstName] boşsa sadece "Merhaba!" döner.


  /// Selamlama metnini iki parçaya böler: ön ek (gri) ve geri kalan (kalın).
  /// Örn: "Günaydın, Ali! Bugün harika görünüyorsun. ✨"
  ///   → prefix: "Günaydın,"  |  rest: "Ali! Bugün harika görünüyorsun. ✨"



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = Provider.of<AuthProvider>(context).userProfile;
    if (userProfile != null && (userProfile.id != _lastUserId || _routinesStream == null)) {
      _lastUserId = userProfile.id;
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
              toolbarHeight: 66,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      final rawName = (userProfile.name?.isNotEmpty ?? false) ? userProfile.name! : (authProvider.firebaseUser?.email?.split('@')[0] ?? '');
                      final firstName = rawName.trim().split(' ').first;
                      return Text(
                        'Merhaba, $firstName',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      final totalDays = DateTime(now.year, now.month + 1, 0).day;
                      final daysLeft = totalDays - now.day;
                      final dateText = DateFormat('d MMMM', 'tr_TR').format(now);
                      final tail = daysLeft > 0
                          ? 'Ay sonuna $daysLeft gün'
                          : 'Ayın son günü';
                      return Text(
                        '$dateText · $tail',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    },
                  ),
                ],
              ),
              actions: [
                Builder(
                  builder: (context) {
                    final recentActivations = customerProvider.recentlyActivatedCustomers;
                    final newActivations = recentActivations.where((c) {
                      if (_lastSeenActivations == null) return true;
                      final activated = c.activatedAt?.toDate();
                      if (activated == null) return false;
                      return activated.isAfter(_lastSeenActivations!);
                    }).toList();
                    final notificationCount = newActivations.length;
                    return Center(
                      child: Badge(
                        isLabelVisible: notificationCount > 0,
                        backgroundColor: AppColors.error,
                        label: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                          onPressed: () {
                            if (notificationCount > 0) {
                              _markActivationsAsSeen();
                            }
                            _showRecentActivationSheet(context, recentActivations);
                          },
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(width: 8),
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
              child: const Icon(Icons.add, color: Colors.white),
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
        return const ProductListScreen();
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
    return CustomerDashboardView(
      routinesStream: _routinesStream,
      onNavigateToProgram: () => setState(() => _customerNavIndex = 1),
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

    return RefreshIndicator(
      onRefresh: () => _refreshConsultantDashboard(userProfile),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 16),
          VpPulseCard(
            vpEarned: vpEarnedThisMonth,
            vpTarget: monthlyVPTarget,
            onTap: () => context.goNamed(OrderListScreen.routeName.substring(1)),
            onSetTarget: () => context.goNamed(ProfileScreen.routeName),
          ),
          const SizedBox(height: 16),
          TodayActionsStrip(
            dueTodayCount: homeProvider.dueTodayCount,
            overdueCount: homeProvider.overdueCount,
            pendingOrdersCount: orderProvider.pendingOrdersCount,
            onDueTodayTap: () =>
                homeProvider.setFilter(ActionFilter.all),
            onOverdueTap: () =>
                homeProvider.setFilter(ActionFilter.overdue),
            onPendingOrdersTap: () =>
                context.goNamed(OrderListScreen.routeName.substring(1)),
          ),
          const SizedBox(height: 16),
          FutureBuilder<int>(
            future: _riskCountFuture,
            builder: (context, snapshot) {
              return CustomerPipelineBar(
                newCount: customerProvider.newCustomersCount,
                activeCount: customerProvider.activeCustomersCount,
                riskCount: snapshot.connectionState == ConnectionState.waiting
                    ? null
                    : (snapshot.data ?? 0),
                passiveCount: customerProvider.passiveCustomersCount,
                onNewTap: () => _showRecentActivationSheet(
                    context, customerProvider.recentlyActivatedCustomers),
                onActiveTap: () =>
                    context.goNamed(CustomerListScreen.routeName.substring(1)),
                onRiskTap: () =>
                    context.goNamed(CustomerListScreen.routeName.substring(1)),
                onPassiveTap: () =>
                    context.goNamed(CustomerListScreen.routeName.substring(1)),
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
          RecentActivityFeed(
            orders: orderProvider.orders,
            customers: customerProvider.customers,
          ),
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
      ),
    );
  }

  /// Pull-to-refresh: müşterileri, siparişleri ve risk sayımını yeniden
  /// çeker. Follow-up'lar zaten stream tabanlı, otomatik güncel.
  Future<void> _refreshConsultantDashboard(UserProfileModel? userProfile) async {
    final userId = userProfile?.id;
    if (userId == null || userId.isEmpty) return;

    if (!mounted) return;
    context.read<CustomerProvider>().fetchCustomers(userId);
    context.read<OrderProvider>().fetchOrders(userId);

    setState(() {
      _riskCountFuture =
          context.read<FirestoreService>().getAtRiskCustomerCount(userId);
    });

    // Kısa bir gecikme — kullanıcı yenilemenin gerçekleştiğini hissetsin.
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }


  /// Egzersiz tamamla/geri al toggle kartı


  /// Tüm öğünler tamamlandığında gösterilen tebrik içeriği

  /// Program yokken gösterilen boş durum içeriği

  /// Stitch HTML'ine sadık checklist — sade checkbox + zaman etiketi + öğün adı

  /// Stitch HTML'ine sadık tek checklist satırı

  /// Müşteri dashboard'ında bugünün kalori durumunu gösteren kart.
  /// Su kartıyla aynı kalıp, sıcak (peach) tonda.

  /// Dashboard'dan hızlı kalori girişi — FoodSearchSheet'i açar.
  /// CalorieTrackerScreen'deki sheet ile aynı widget, kullanıcı ekran
  /// değiştirmek zorunda kalmadan ana ekrandan ekleyebilir.

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

  // ───── Kritik Aksiyon satır eylemleri ─────────────────────────────────

  /// Follow-up satırından "Ara" tıklandığında çağrılır. Müşterinin
  /// telefon numarasını normalize edip `tel:` URL ile arar.
  Future<void> _callFollowUpCustomer(
    BuildContext context,
    CustomerModel? customer,
  ) async {
    final phone = customer?.phoneNumber;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu müşteri için telefon numarası yok.')),
      );
      return;
    }
    final normalized = normalizePhoneForWhatsApp(phone);
    final dialNumber = normalized != null ? '+$normalized' : phone;
    final uri = Uri.parse('tel:$dialNumber');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama başlatılamadı.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama hatası: $e')),
        );
      }
    }
  }

  /// Follow-up satırından "WhatsApp" tıklandığında çağrılır. Hazır
  /// selamlama mesajıyla wa.me deep link'ini açar.
  Future<void> _whatsAppFollowUpCustomer(
    BuildContext context,
    CustomerModel? customer,
    ScheduledFollowUpModel task,
  ) async {
    final phone = customer?.phoneNumber;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu müşteri için telefon numarası yok.')),
      );
      return;
    }
    final normalized = normalizePhoneForWhatsApp(phone);
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefon numarası geçersiz.')),
      );
      return;
    }
    final firstName = task.customerFirstName.trim();
    final greeting = firstName.isEmpty ? 'Merhaba!' : 'Merhaba $firstName!';
    final message = '$greeting\nMüsait olduğunda kısaca konuşabilir miyiz?';
    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp açılamadı.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp hatası: $e')),
        );
      }
    }
  }

  Future<void> _snoozeFollowUp(
    BuildContext context,
    ScheduledFollowUpModel task,
  ) async {
    final firestore = context.read<FirestoreService>();
    final originalDate = task.dueDate.toDate();
    final newDate = originalDate.add(const Duration(days: 1));
    try {
      await firestore.snoozeScheduledFollowUp(task.id, newDate);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Takip yarına ertelendi.'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () async {
              try {
                await firestore.snoozeScheduledFollowUp(task.id, originalDate);
              } catch (_) {/* sessiz */}
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erteleme hatası: $e')),
      );
    }
  }

  /// Follow-up'ı tamamlanmış olarak işaretler.
  Future<void> _completeFollowUp(
    BuildContext context,
    ScheduledFollowUpModel task,
  ) async {
    final firestore = context.read<FirestoreService>();
    try {
      await firestore.markScheduledFollowUpAsCompleted(task.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Takip tamamlandı.'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () async {
              try {
                await firestore.scheduledFollowUpsRef().doc(task.id).update({'isCompleted': false});
              } catch (_) {/* sessiz */}
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tamamlama hatası: $e')),
      );
    }
  }

  /// Follow-up customerId'sine karşılık gelen CustomerModel'i provider
  /// listesinden çözer. Bulunmazsa null döner (silinmiş müşteri).
  CustomerModel? _resolveFollowUpCustomer(
    CustomerProvider provider,
    String customerId,
  ) {
    try {
      return provider.customers.firstWhere(
        (c) =>
            c.id == customerId ||
            (c.linkedUserId != null && c.linkedUserId == customerId),
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildStitchKritikAksiyonlarList(BuildContext context, HomeProvider provider, CustomerProvider customerProvider) {
    if (provider.isLoading) return const CriticalActionsSkeleton();

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
      return const CriticalActionsEmptyState();
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return _buildCriticalActionTile(context, task, customerProvider);
      },
    );
  }

  /// Tek bir kritik aksiyon satırı: üstte avatar + müşteri + görev,
  /// altta 3 mini aksiyon (Ara / WhatsApp / Ertele).
  Widget _buildCriticalActionTile(
    BuildContext context,
    ScheduledFollowUpModel task,
    CustomerProvider customerProvider,
  ) {
    final isOverdue = task.dueDate.toDate().isBefore(DateTime.now());
    final color = isOverdue ? AppColors.papaya : AppColors.laguna;
    final customer = _resolveFollowUpCustomer(customerProvider, task.customerId);
    final hasPhone =
        customer != null && customer.phoneNumber.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
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
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final target = customer ??
                CustomerModel(
                  id: task.customerId,
                  consultantId: '',
                  firstName: task.customerFirstName,
                  lastName: task.customerLastName,
                  phoneNumber: '',
                  firstContactDate: task.dueDate,
                  isActive: false,
                  notes: 'Bu müşteri kaydı silinmiş veya erişilemiyor.',
                );
            context.goNamed(CustomerDetailScreen.routeName, extra: target);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCustomerInitialsAvatar(
                      task.customerFirstName,
                      task.customerLastName,
                      task.customerId,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${task.customerFirstName} ${task.customerLastName}'
                                .trim(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.nightSky,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOverdue
                                ? 'Gecikmiş: ${task.title}'
                                : task.title,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      color: AppColors.primary,
                      tooltip: 'Tamamlandı olarak işaretle',
                      onPressed: () => _completeFollowUp(context, task),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniActionButton(
                        icon: Icons.call_outlined,
                        label: 'Ara',
                        color: AppColors.lake,
                        enabled: hasPhone,
                        onTap: () => _callFollowUpCustomer(context, customer),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MiniActionButton(
                        icon: Icons.chat_outlined,
                        label: 'WhatsApp',
                        color: AppColors.grass,
                        enabled: hasPhone,
                        onTap: () => _whatsAppFollowUpCustomer(
                            context, customer, task),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MiniActionButton(
                        icon: Icons.schedule_outlined,
                        label: 'Ertele',
                        color: AppColors.mangoDeep,
                        enabled: true,
                        onTap: () => _snoozeFollowUp(context, task),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStitchQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: [
          _buildQuickActionCard(
            context,
            icon: Icons.person_add,
            label: 'Yeni Müşteri',
            color: AppColors.primary,
            onTap: () => context.goNamed(AddEditCustomerScreen.routeName),
          ),
          _buildQuickActionCard(
            context,
            icon: Icons.receipt_long,
            label: 'Yeni Sipariş',
            color: AppColors.laguna,
            onTap: () => context.goNamed(AddEditOrderScreen.routeName),
          ),
          _buildQuickActionCard(
            context,
            icon: Icons.people_alt_outlined,
            label: 'Müşterilerim',
            color: AppColors.lake,
            onTap: () => context.goNamed(CustomerListScreen.routeName.substring(1)),
          ),
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
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
            ],
          ),
        );
      },
    );
  }


  /// Bildirim panelinin asıl içeriğini oluşturur.
  /// _showNotificationPanel'den ayrıldı ki stream null olduğunda da çağrılabilsin.


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
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    'Yeni Aktive Olan Müşteriler (${recentActivations.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.nightSky,
                    ),
                  ),
                ),
                Flexible(
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
                ),
              ],
            ),
          ),
        );
      },
    );
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


// ─── Water Glass Widget ───────────────────────────────────────────────────────

/// Stitch HTML'indeki animasyonlu su bardağı görseli

/// Kalori kartının sağında gösterilen dairesel ilerleme halkası.
/// Su bardağı widget'ının kalori karşılığı.

/// Kritik Aksiyonlar listesindeki satır içi 3 mini buton (Ara / WA / Ertele).
/// Kompakt, ikonlu, renk-vurgulu. Disabled state için soluk gri.
class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.grey.shade400;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.25)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: effectiveColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: effectiveColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

