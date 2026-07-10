import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/avatar_color_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../models/customer_model.dart';
import '../../../../models/scheduled_follow_up_model.dart';
import '../../../../models/user_profile_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../customers/providers/customer_provider.dart';
import '../../../customers/screens/add_edit_customer_screen.dart';
import '../../../customers/screens/customer_detail_screen.dart';
import '../../../customers/screens/customer_list_screen.dart';
import '../../../orders/providers/order_provider.dart';
import '../../../orders/screens/add_edit_order_screen.dart';
import '../../../orders/screens/order_list_screen.dart';
import '../../../products/providers/product_provider.dart';
import '../../../profile/screens/profile_screen.dart';
import '../../providers/home_provider.dart';
import '../../widgets/critical_actions_states.dart';
import '../../widgets/customer_pipeline_bar.dart';
import '../../widgets/recent_activity_feed.dart';
import '../../widgets/today_actions_strip.dart';
import '../../widgets/vp_pulse_card.dart';

class ConsultantDashboardView extends StatefulWidget {
  final UserProfileModel? userProfile;
  final AuthProvider authProvider;
  final VoidCallback onNavigateToCustomers;
  final VoidCallback onShowRecentActivations;

  const ConsultantDashboardView({
    super.key,
    required this.userProfile,
    required this.authProvider,
    required this.onNavigateToCustomers,
    required this.onShowRecentActivations,
  });

  @override
  State<ConsultantDashboardView> createState() =>
      _ConsultantDashboardViewState();
}

class _ConsultantDashboardViewState extends State<ConsultantDashboardView> {
  // We can just paste the extracted methods here, but we need to remove the method signature of _buildConsultantDashboard
  // and put its body inside the build() method!

  Future<int>? _riskCountFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.userProfile != null && _riskCountFuture == null) {
      _riskCountFuture = context
          .read<FirestoreService>()
          .getAtRiskCustomerCount(widget.userProfile!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final productProvider = context.watch<ProductProvider>();
    final homeProvider = context.watch<HomeProvider>();
    final userProfile = widget.userProfile;
    final authProvider = widget.authProvider;

    // Paste original _buildConsultantDashboard body here
    // Wait, the original _buildConsultantDashboard has its own parameters. Let's just create a dummy method for it and call it from build.
    return _buildConsultantDashboard(
      context,
      userProfile,
      authProvider,
      orderProvider,
      customerProvider,
      productProvider,
      homeProvider,
    );
  }

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
              onTap: () =>
                  context.goNamed(OrderListScreen.routeName.substring(1)),
              onSetTarget: () => context.goNamed(ProfileScreen.routeName),
            ),
            const SizedBox(height: 16),
            TodayActionsStrip(
              dueTodayCount: homeProvider.dueTodayCount,
              overdueCount: homeProvider.overdueCount,
              pendingOrdersCount: orderProvider.pendingOrdersCount,
              onDueTodayTap: () => homeProvider.setFilter(ActionFilter.all),
              onOverdueTap: () => homeProvider.setFilter(ActionFilter.overdue),
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
                  onNewTap: () => widget.onShowRecentActivations(),
                  onActiveTap: () => context.goNamed(
                    CustomerListScreen.routeName.substring(1),
                  ),
                  onRiskTap: () => context.goNamed(
                    CustomerListScreen.routeName.substring(1),
                  ),
                  onPassiveTap: () => context.goNamed(
                    CustomerListScreen.routeName.substring(1),
                  ),
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
            _buildStitchKritikAksiyonlarList(
              context,
              homeProvider,
              customerProvider,
            ),
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
  Future<void> _refreshConsultantDashboard(
    UserProfileModel? userProfile,
  ) async {
    final userId = userProfile?.id;
    if (userId == null || userId.isEmpty) return;

    if (!mounted) return;
    context.read<CustomerProvider>().fetchCustomers(userId);
    context.read<OrderProvider>().fetchOrders(userId);

    setState(() {
      _riskCountFuture = context
          .read<FirestoreService>()
          .getAtRiskCustomerCount(userId);
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
          border: Border.all(color: AppColors.backgroundMuted),
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
            color: isActive
                ? activeColor.withValues(alpha: 0.1)
                : Colors.transparent,
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
                  color: isActive ? activeColor : AppColors.textMuted,
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
                    color: isActive ? activeColor : AppColors.textMutedLighter,
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
    return Container(width: 1, height: 20, color: AppColors.backgroundMuted);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Arama başlatılamadı.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Arama hatası: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('WhatsApp açılamadı.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('WhatsApp hatası: $e')));
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
              } catch (_) {
                /* sessiz */
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erteleme hatası: $e')));
    }
  }

  /// Follow-up'ı tamamlanmış olarak işaretler.
  Future<void> _completeFollowUp(
    BuildContext context,
    ScheduledFollowUpModel task,
  ) async {
    final firestore = context.read<FirestoreService>();
    // ScaffoldMessenger'ı önceden al (async işlem sonrası context değişebilir)
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // Önceki SnackBar'ları temizle (birikmesini önle)
      scaffoldMessenger.clearSnackBars();
      await firestore.markScheduledFollowUpAsCompleted(task.id);
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Takip tamamlandı.'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () async {
              try {
                await firestore.scheduledFollowUpsRef().doc(task.id).update({
                  'isCompleted': false,
                });
              } catch (_) {
                /* sessiz */
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Tamamlama hatası: $e'),
          duration: const Duration(seconds: 3),
        ),
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

  Widget _buildStitchKritikAksiyonlarList(
    BuildContext context,
    HomeProvider provider,
    CustomerProvider customerProvider,
  ) {
    if (provider.isLoading) return const CriticalActionsSkeleton();

    final filteredTasks = provider.upcomingFollowUps;

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
    final customer = _resolveFollowUpCustomer(
      customerProvider,
      task.customerId,
    );
    final hasPhone = customer != null && customer.phoneNumber.trim().isNotEmpty;

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
            final target =
                customer ??
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
            context.pushNamed(CustomerDetailScreen.routeName, extra: target);
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
                            isOverdue ? 'Gecikmiş: ${task.title}' : task.title,
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
                      child: _buildMiniActionButton(
                        icon: Icons.call_outlined,
                        label: 'Ara',
                        color: AppColors.lake,
                        enabled: hasPhone,
                        onTap: () => _callFollowUpCustomer(context, customer),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildMiniActionButton(
                        icon: Icons.chat_outlined,
                        label: 'WhatsApp',
                        color: AppColors.grass,
                        enabled: hasPhone,
                        onTap: () =>
                            _whatsAppFollowUpCustomer(context, customer, task),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildMiniActionButton(
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
            onTap: () =>
                context.goNamed(CustomerListScreen.routeName.substring(1)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final effectiveColor = enabled ? color : AppColors.textMutedLight;
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
                : AppColors.backgroundMutedLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.25)
                  : AppColors.backgroundMuted,
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

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
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
                color: AppColors.grey800,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInitialsAvatar(
    String firstName,
    String lastName,
    String customerId,
  ) {
    final fullName = '$firstName $lastName'.trim();
    final initials = fullName
        .split(' ')
        .take(2)
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
}
