import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/customer_model.dart';
import '../../../models/user_profile_model.dart';
import '../../../widgets/app_drawer.dart'; // AppDrawer'ı import et
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
 // Navigasyon için

import '../../products/screens/product_list_screen.dart';
import '../../orders/providers/order_provider.dart';
import '../../../models/order_model.dart';

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
import 'views/consultant_dashboard_view.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _customerNavIndex = 0;
  Stream<List<DailyRoutineModel>>? _routinesStream;
  String? _lastUserId;
  DateTime? _lastSeenActivations;
  final Set<String> _knownPendingOrderIds = {};
  bool _hasLoadedOrders = false;
  bool _isOrderDialogVisible = false;

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

  void _checkForNewOrders(List<OrderModel> orders) {
    final pending = orders
        .where((order) => order.status == OrderStatus.pending)
        .toList();
    final pendingIds = pending.map((order) => order.id).toSet();
    if (!_hasLoadedOrders) {
      _knownPendingOrderIds
        ..clear()
        ..addAll(pendingIds);
      _hasLoadedOrders = true;
      return;
    }
    final newOrders = pending.where((order) => !_knownPendingOrderIds.contains(order.id)).toList();
    _knownPendingOrderIds
      ..clear()
      ..addAll(pendingIds);
    if (newOrders.isEmpty || _isOrderDialogVisible || !mounted) return;
    _isOrderDialogVisible = true;
    final order = newOrders.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Yeni sipariş geldi'),
          content: Text('${order.customerName} yeni bir sipariş talebi oluşturdu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tamam'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/home/orders');
              },
              child: const Text('Siparişe git'),
            ),
          ],
        ),
      ).whenComplete(() => _isOrderDialogVisible = false);
    });
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


    final customerProvider = Provider.of<CustomerProvider>(context);


    final bool isCustomer = userProfile.role == UserRole.customer ||
        (userProfile.role == UserRole.distributor && authProvider.isCustomerModeActive);
    final orderProvider = context.watch<OrderProvider>();
    if (!isCustomer) {
      _checkForNewOrders(orderProvider.orders);
    }

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
                    final notificationCount = newActivations.length + orderProvider.pendingOrdersCount;
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
                            if (orderProvider.pendingOrdersCount > 0) {
                              context.go('/home/orders');
                              return;
                            }
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
          return ConsultantDashboardView(
            userProfile: userProfile,
            authProvider: authProvider,
            onNavigateToCustomers: () => setState(() => _customerNavIndex = 2),
            onShowRecentActivations: () => _showRecentActivationSheet(context, customerProvider.recentlyActivatedCustomers),
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
        border: Border(top: BorderSide(color: AppColors.backgroundMutedLight)),
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
              color: isActive ? AppColors.primary : AppColors.textMutedLight,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textMutedLight,
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
              color: isActive ? AppColors.primary : AppColors.textMutedLight,
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

  void _showRecentActivationSheet(BuildContext context, List<CustomerModel> recentActivations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMutedLighter, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Yeni Aktivasyonlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: recentActivations.length,
                separatorBuilder: (ctx, i) => const Divider(height: 24),
                itemBuilder: (ctx, i) {
                  final customer = recentActivations[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        customer.firstName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('${customer.firstName} ${customer.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${customer.consultantId}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Navigate to detail
                      },
                    ),
                  );
                },
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person_add, color: Colors.white)),
              title: const Text('Yeni Müşteri Ekle'),
              onTap: () {
                Navigator.pop(ctx);
                // logic
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.secondary, child: Icon(Icons.shopping_cart, color: Colors.white)),
              title: const Text('Yeni Sipariş Oluştur'),
              onTap: () {
                Navigator.pop(ctx);
                // logic
              },
            ),
          ],
        ),
      ),
    );
  }
}
