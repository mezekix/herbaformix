import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:herbaformix/features/customers/screens/add_edit_customer_screen.dart';
import 'package:herbaformix/features/progress/widgets/weight_chart_widget.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/customer_model.dart';
import '../../../models/invite_code_model.dart';
import '../../../models/distributor_customer_insights.dart';
import '../../../models/follow_up_model.dart';
import '../../../models/progress_entry_model.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/user_role.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../program/models/program_editor_args.dart';
import '../../program/screens/create_program_screen.dart';
import '../providers/customer_provider.dart';
import '../providers/follow_up_provider.dart';

/// Distribütörün bağlı bir müşterinin detayını görüntülediği ekran.
///
/// 3 sekmeli yapı:
/// - **Takip**: Planlanmış işler, hızlı aksiyonlar, son 7 gün özeti, gelişim grafiği.
/// - **Profil & Sağlık**: Distribütör başvurusu (varsa), iletişim, kişisel
///   bilgiler, sağlık notları, davet kodu (müşteri henüz aktive olmamışsa).
/// - **Geçmiş**: Tüm ölçümler ve geçmiş takip görüşmeleri.
///
/// Üstte sabit bir durum çubuğu (Aktif/Pasif + Riskli/Takipte) her sekmede
/// görünür kalır.
class CustomerDetailScreen extends StatelessWidget {
  static const String routeName = 'customer-detail';

  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final currentCustomer = customerProvider.customers.firstWhere(
      (c) => c.id == customer.id || (c.linkedUserId != null && c.linkedUserId == customer.id),
      orElse: () => customer,
    );

    return ChangeNotifierProvider(
      create: (ctx) => FollowUpProvider(
        authProvider: ctx.read<AuthProvider>(),
        firestoreService: ctx.read<FirestoreService>(),
        customerId: currentCustomer.id,
        linkedUserId: currentCustomer.linkedUserId,
      ),
      child: _CustomerDetailContent(customer: currentCustomer),
    );
  }
}

/// Profil + insights verilerini yükleyip [_CustomerDetailScaffold]'a iletir.
class _CustomerDetailContent extends StatelessWidget {
  final CustomerModel customer;

  const _CustomerDetailContent({required this.customer});

  @override
  Widget build(BuildContext context) {
    final hasLinkedUser =
        customer.linkedUserId != null && customer.linkedUserId!.isNotEmpty;

    if (!hasLinkedUser) {
      return _CustomerDetailScaffold(
        customer: customer,
        profile: null,
        insights: null,
      );
    }

    final firestoreService = context.read<FirestoreService>();
    return StreamBuilder<UserProfileModel?>(
      stream: firestoreService.watchUserProfile(customer.linkedUserId!),
      builder: (context, profileSnap) {
        return FutureBuilder<DistributorCustomerInsights>(
          future: firestoreService.getDistributorCustomerInsights(
            customer.linkedUserId!,
          ),
          builder: (context, insightsSnap) {
            return _CustomerDetailScaffold(
              customer: customer,
              profile: profileSnap.data,
              insights: insightsSnap.data,
              isProfileLoading:
                  profileSnap.connectionState == ConnectionState.waiting,
              isInsightsLoading:
                  insightsSnap.connectionState == ConnectionState.waiting,
            );
          },
        );
      },
    );
  }
}

/// Ana iskelet: AppBar + durum çubuğu + 3 sekmeli TabBarView.
class _CustomerDetailScaffold extends StatelessWidget {
  final CustomerModel customer;
  final UserProfileModel? profile;
  final DistributorCustomerInsights? insights;
  final bool isProfileLoading;
  final bool isInsightsLoading;

  const _CustomerDetailScaffold({
    required this.customer,
    required this.profile,
    required this.insights,
    this.isProfileLoading = false,
    this.isInsightsLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final followUpProvider = context.watch<FollowUpProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${customer.firstName} ${customer.lastName}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Müşteriyi Düzenle',
              onPressed: () {
                context.goNamed(
                  AddEditCustomerScreen.routeName,
                  extra: customer,
                );
              },
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white.withValues(alpha: 0.65),
            indicatorColor: AppColors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.event_available_outlined), text: 'Takip'),
              Tab(icon: Icon(Icons.person_outline), text: 'Profil & Sağlık'),
              Tab(icon: Icon(Icons.history), text: 'Geçmiş'),
            ],
          ),
        ),
        body: Column(
          children: [
            _StatusBar(customer: customer, insights: insights),
            Expanded(
              child: TabBarView(
                children: [
                  _FollowUpTab(
                    customer: customer,
                    profile: profile,
                    insights: insights,
                    followUpProvider: followUpProvider,
                    isInsightsLoading: isInsightsLoading,
                  ),
                  _ProfileHealthTab(
                    customer: customer,
                    profile: profile,
                    isProfileLoading: isProfileLoading,
                  ),
                  _HistoryTab(
                    customer: customer,
                    insights: insights,
                    followUpProvider: followUpProvider,
                    isInsightsLoading: isInsightsLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Her sekmenin üstünde sabit duran ince durum çubuğu.
///
/// Sol: Aktif/Pasif. Sağ: Riskli/Takipte (sadece aktive olmuş müşteride) veya
/// "Aktivasyon bekleniyor" (aktive olmamışsa).
class _StatusBar extends StatelessWidget {
  final CustomerModel customer;
  final DistributorCustomerInsights? insights;

  const _StatusBar({required this.customer, required this.insights});

  @override
  Widget build(BuildContext context) {
    final hasLinkedUser =
        customer.linkedUserId != null && customer.linkedUserId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          _statusChip(
            icon: customer.isActive
                ? Icons.check_circle
                : Icons.cancel_outlined,
            label: customer.isActive ? 'Aktif Müşteri' : 'Pasif Müşteri',
            color: customer.isActive ? Colors.green : Colors.grey,
          ),
          const Spacer(),
          if (!hasLinkedUser)
            _statusChip(
              icon: Icons.hourglass_empty,
              label: 'Aktivasyon bekleniyor',
              color: Colors.orange,
            )
          else if (insights != null)
            _statusChip(
              icon: insights!.isAtRisk
                  ? Icons.warning_amber_outlined
                  : Icons.trending_up,
              label: insights!.isAtRisk ? 'Riskli' : 'Takipte',
              color: insights!.isAtRisk ? Colors.red : Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Tab 1 — Takip (varsayılan açılan)
// ============================================================================

class _FollowUpTab extends StatelessWidget {
  final CustomerModel customer;
  final UserProfileModel? profile;
  final DistributorCustomerInsights? insights;
  final FollowUpProvider followUpProvider;
  final bool isInsightsLoading;

  const _FollowUpTab({
    required this.customer,
    required this.profile,
    required this.insights,
    required this.followUpProvider,
    required this.isInsightsLoading,
  });

  @override
  Widget build(BuildContext context) {
    final hasLinkedUser =
        customer.linkedUserId != null && customer.linkedUserId!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) Planlanmış takipler (en önemli — en üstte)
          _sectionTitle(context, 'Planlanmış Takipler', Icons.calendar_today_outlined),
          const SizedBox(height: 8),
          _buildScheduledFollowUps(context),
          const SizedBox(height: 24),

          // 2) Hızlı aksiyonlar — Plansız Takip Ekle her zaman; Program/Motivasyon
          //    yalnızca müşteri aktive olduysa
          _sectionTitle(context, 'Hızlı Aksiyon', Icons.bolt_outlined),
          const SizedBox(height: 8),
          _buildQuickActions(context, hasLinkedUser),
          const SizedBox(height: 24),

          // 3) Müşteri aktive olmamışsa burada dur
          if (!hasLinkedUser) ...[
            _buildInfoMessage(
              icon: Icons.link_off_outlined,
              color: Colors.orange,
              text:
                  'Müşteri henüz hesabını aktive etmedi. Aktivasyon sonrası gelişim takibi ve son 7 gün özeti burada görünür. Davet kodunu Profil sekmesinde bulabilirsin.',
            ),
            const SizedBox(height: 16),
          ] else ...[
            // 4) Son 7 Gün Özeti — profile stream'den geç gelse bile insights'la
            //    birlikte gösteririz (profile sadece kilo fallback için).
            if (insights != null)
              _buildInsightsCard(context, profile, insights!)
            else if (isInsightsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            const SizedBox(height: 12),

            // 5) Gelişim grafiği + toplam değişim
            if (insights != null)
              _buildProgressChartCard(context, profile, insights!),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduledFollowUps(BuildContext context) {
    if (followUpProvider.isLoading &&
        followUpProvider.pendingScheduledFollowUps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (followUpProvider.pendingScheduledFollowUps.isEmpty) {
      return _buildInfoMessage(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        text: 'Yaklaşan planlanmış takip görevi yok.',
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: followUpProvider.pendingScheduledFollowUps.length,
      itemBuilder: (context, index) {
        final scheduledFollowUp =
            followUpProvider.pendingScheduledFollowUps[index];
        final isOverdue =
            scheduledFollowUp.dueDate.toDate().isBefore(DateTime.now());

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          color: isOverdue ? Colors.orange.shade50 : null,
          child: ListTile(
            leading: Icon(
              Icons.calendar_month_outlined,
              color: isOverdue
                  ? Colors.orange.shade800
                  : Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              scheduledFollowUp.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOverdue ? Colors.orange.shade900 : null,
              ),
            ),
            subtitle: Text(
              'Tarih: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(scheduledFollowUp.dueDate.toDate())}',
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Görüşme Ekle'),
              onPressed: () {
                _showAddFollowUpSheet(
                  context,
                  customer,
                  followUpProvider,
                  scheduledFollowUpId: scheduledFollowUp.id,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, bool hasLinkedUser) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (hasLinkedUser)
          _actionButton(
            icon: Icons.edit_calendar_outlined,
            label: 'Program Yaz',
            onPressed: () {
              context.goNamed(
                CreateProgramScreen.routeName,
                extra: ProgramEditorArgs(
                  targetUserId: customer.linkedUserId!,
                  targetCustomerName:
                      '${customer.firstName} ${customer.lastName}'.trim(),
                  isDistributorMode: true,
                ),
              );
            },
            filled: true,
          ),
        if (hasLinkedUser)
          _actionButton(
            icon: Icons.favorite_outline,
            label: 'Motivasyon Mesajı',
            onPressed: () => _showMotivationMessageSheet(
              context,
              customer.linkedUserId!,
              '${customer.firstName} ${customer.lastName}'.trim(),
            ),
          ),
        _actionButton(
          icon: Icons.add_task_outlined,
          label: 'Plansız Takip Ekle',
          onPressed: () =>
              _showAddFollowUpSheet(context, customer, followUpProvider),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _buildInsightsCard(
    BuildContext context,
    UserProfileModel? profile,
    DistributorCustomerInsights insights,
  ) {
    final latestProgress = insights.latestProgress;
    final waterPercent = insights.waterGoalMl == 0
        ? 0.0
        : insights.todayWaterMl / insights.waterGoalMl;
    final lastActivityText = insights.lastActivityAt == null
        ? 'Aktivite yok'
        : DateFormat('dd.MM.yyyy HH:mm').format(insights.lastActivityAt!);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Son 7 Gün Özeti',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMetricCard(
                  context,
                  title: 'Son Kilo',
                  value: latestProgress != null
                      ? '${latestProgress.weight.toStringAsFixed(1)} kg'
                      : (profile?.weight != null
                          ? '${profile!.weight!.toStringAsFixed(1)} kg'
                          : 'Yok'),
                  subtitle: latestProgress != null
                      ? DateFormat('dd.MM').format(latestProgress.date)
                      : 'Kayıt yok',
                ),
                _buildMetricCard(
                  context,
                  title: 'Su Takibi',
                  value: '${insights.todayWaterMl}/${insights.waterGoalMl} ml',
                  subtitle:
                      '%${(waterPercent * 100).clamp(0, 100).round()}',
                ),
                _buildMetricCard(
                  context,
                  title: 'Öğün Tamamlama',
                  value:
                      '${insights.completedRoutinesLast7Days}/${insights.totalRoutinesLast7Days}',
                  subtitle:
                      '%${(insights.completionRate * 100).clamp(0, 100).round()}',
                ),
                _buildMetricCard(
                  context,
                  title: 'Son Aktivite',
                  value: lastActivityText,
                  subtitle: insights.lastActivityAt == null
                      ? 'Henüz yok'
                      : _relativeTime(insights.lastActivityAt!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChartCard(
    BuildContext context,
    UserProfileModel? profile,
    DistributorCustomerInsights insights,
  ) {
    final entries = insights.progressEntries;
    final hasEntries = entries.isNotEmpty;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_down,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Gelişim Takibi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasEntries)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Henüz ölçüm kaydı yok.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else ...[
              WeightChartWidget(
                entries: entries,
                targetWeight: profile?.targetWeight,
                initialWeight: profile?.weight,
              ),
              if (entries.length >= 2) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildChangeChip('Kilo', insights.totalWeightChange, 'kg'),
                    if (entries.any((e) => e.waist != null))
                      _buildChangeChip(
                          'Bel', _calcChange(entries, (e) => e.waist), 'cm'),
                    if (entries.any((e) => e.hip != null))
                      _buildChangeChip(
                          'Kalça', _calcChange(entries, (e) => e.hip), 'cm'),
                    if (entries.any((e) => e.chest != null))
                      _buildChangeChip(
                          'Göğüs', _calcChange(entries, (e) => e.chest), 'cm'),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    DefaultTabController.of(context).animateTo(2);
                  },
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Tüm ölçümleri gör'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Tab 2 — Profil & Sağlık
// ============================================================================

class _ProfileHealthTab extends StatelessWidget {
  final CustomerModel customer;
  final UserProfileModel? profile;
  final bool isProfileLoading;

  const _ProfileHealthTab({
    required this.customer,
    required this.profile,
    required this.isProfileLoading,
  });

  @override
  Widget build(BuildContext context) {
    final hasLinkedUser =
        customer.linkedUserId != null && customer.linkedUserId!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distribütör başvuru kartı — pending ise en üstte (aksiyon gerektirir)
          if (hasLinkedUser && profile?.distributorRequestStatus == 'pending') ...[
            _buildDistributorRequestCard(context, profile!),
            const SizedBox(height: 16),
          ],

          // İletişim
          _sectionTitle(context, 'İletişim', Icons.contact_mail_outlined),
          const SizedBox(height: 8),
          _buildContactCard(context),
          const SizedBox(height: 20),

          // Kişisel & sağlık — yalnızca aktive olmuş müşteride
          if (hasLinkedUser) ...[
            if (isProfileLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (profile != null) ...[
              _sectionTitle(context, 'Kişisel Bilgiler', Icons.person_outline),
              const SizedBox(height: 8),
              _buildPersonalCard(context, profile!),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Sağlık Bilgileri',
                  Icons.medical_information_outlined),
              const SizedBox(height: 8),
              _buildHealthCard(context, profile!),
              const SizedBox(height: 20),
            ],
          ] else
            // Müşteri aktive olmamışsa davet kodu kartı
            _buildInviteCodeSection(context),

          // Distribütörün kendi notu (her durumda gösterilir)
          if (customer.notes != null && customer.notes!.trim().isNotEmpty) ...[
            _sectionTitle(context, 'Distribütör Notu', Icons.notes_outlined),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(customer.notes!),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.phone_outlined, 'Telefon', customer.phoneNumber),
            const SizedBox(height: 10),
            _infoRow(Icons.email_outlined, 'E-posta',
                customer.email ?? 'Belirtilmemiş'),
            const SizedBox(height: 10),
            _infoRow(
              Icons.calendar_today_outlined,
              'İlk Temas',
              DateFormat('dd MMMM yyyy', 'tr_TR')
                  .format(customer.firstContactDate.toDate()),
            ),
            if (customer.activatedAt != null) ...[
              const SizedBox(height: 10),
              _infoRow(
                Icons.verified_user_outlined,
                'Aktive Olduğu Tarih',
                DateFormat('dd MMMM yyyy HH:mm', 'tr_TR')
                    .format(customer.activatedAt!.toDate()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalCard(BuildContext context, UserProfileModel profile) {
    // İkon + ufak başlık + büyük değer formatında ölçü tile'ları.
    // Ad ve telefon iletişim kartında zaten var; burada tekrarlanmaz.
    final tiles = <_DataTile>[
      _DataTile(
        icon: Icons.height,
        label: 'Boy',
        value: profile.height != null
            ? '${profile.height!.toStringAsFixed(0)} cm'
            : '—',
      ),
      _DataTile(
        icon: Icons.monitor_weight_outlined,
        label: 'Kilo',
        value: profile.weight != null
            ? '${profile.weight!.toStringAsFixed(1)} kg'
            : '—',
      ),
      _DataTile(
        icon: Icons.cake_outlined,
        label: 'Yaş',
        value: profile.age != null ? '${profile.age}' : '—',
      ),
      if (profile.gender != null && profile.gender!.isNotEmpty)
        _DataTile(
          icon: Icons.wc_outlined,
          label: 'Cinsiyet',
          value: profile.gender!,
        ),
      if (profile.targetWeight != null)
        _DataTile(
          icon: Icons.flag_outlined,
          label: 'Hedef Kilo',
          value: '${profile.targetWeight!.toStringAsFixed(1)} kg',
          highlight: true,
        ),
      _DataTile(
        icon: Icons.track_changes_outlined,
        label: 'Hedef',
        value: _formatGoal(profile.userGoal),
        highlight: true,
      ),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final tileWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: tiles
                  .map(
                    (t) => SizedBox(
                      width: tileWidth,
                      child: _personalTile(context, t),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _personalTile(BuildContext context, _DataTile tile) {
    final accent = tile.highlight ? AppColors.primary : Colors.grey.shade700;
    final bg = tile.highlight
        ? AppColors.primary.withValues(alpha: 0.06)
        : Colors.grey.shade50;
    final border = tile.highlight
        ? AppColors.primary.withValues(alpha: 0.25)
        : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(tile.icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tile.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tile.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context, UserProfileModel profile) {
    final notes = (profile.healthNotes ?? '').trim();
    final allergies = (profile.allergies ?? '').trim();
    final meds = (profile.medications ?? '').trim();

    if (notes.isEmpty && allergies.isEmpty && meds.isEmpty) {
      return _buildInfoMessage(
        icon: Icons.info_outline,
        color: Colors.blue,
        text: 'Müşteri henüz sağlık bilgisi girmedi.',
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notes.isNotEmpty)
              _labeledBlock('Sağlık Notu', notes, Icons.note_alt_outlined),
            if (allergies.isNotEmpty) ...[
              if (notes.isNotEmpty) const SizedBox(height: 14),
              _labeledBlock('Alerjiler', allergies, Icons.warning_amber_outlined,
                  color: Colors.orange.shade700),
            ],
            if (meds.isNotEmpty) ...[
              if (notes.isNotEmpty || allergies.isNotEmpty)
                const SizedBox(height: 14),
              _labeledBlock(
                'Kullandığı İlaçlar',
                meds,
                Icons.medication_outlined,
                color: Colors.deepPurple.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _labeledBlock(String label, String value, IconData icon,
      {Color? color}) {
    final iconColor = color ?? Colors.grey.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCodeSection(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    return FutureBuilder<InviteCodeModel?>(
      future: firestoreService.getInviteCodeForCustomer(customer.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final invite = snapshot.data;
        if (invite == null) {
          return _buildInfoMessage(
            icon: Icons.info_outline,
            color: Colors.blue,
            text:
                'Bu müşteri için oluşturulmuş bir davet kodu bulunamadı.',
          );
        }

        return Card(
          elevation: 0,
          color: AppColors.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Müşteri Aktivasyon Kodu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Müşterinizin sizinle bağlantı kurması için uygulamaya kaydolurken aşağıdaki kodu girmesi gerekmektedir:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        invite.code,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Kopyala'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: invite.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Davet kodu kopyalandı!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Kişisel bilgiler grid'inde tek bir hücreyi tanımlar.
class _DataTile {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _DataTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

// ============================================================================
// Tab 3 — Geçmiş
// ============================================================================

class _HistoryTab extends StatelessWidget {
  final CustomerModel customer;
  final DistributorCustomerInsights? insights;
  final FollowUpProvider followUpProvider;
  final bool isInsightsLoading;

  const _HistoryTab({
    required this.customer,
    required this.insights,
    required this.followUpProvider,
    required this.isInsightsLoading,
  });

  @override
  Widget build(BuildContext context) {
    final hasLinkedUser =
        customer.linkedUserId != null && customer.linkedUserId!.isNotEmpty;
    final entries = insights?.progressEntries ?? const <ProgressEntryModel>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tüm ölçümler
          if (hasLinkedUser) ...[
            _sectionTitle(
                context, 'Tüm Ölçümler', Icons.straighten),
            const SizedBox(height: 8),
            if (isInsightsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (entries.isEmpty)
              _buildInfoMessage(
                icon: Icons.info_outline,
                color: Colors.blue,
                text: 'Henüz ölçüm kaydı yok.',
              )
            else
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: entries.reversed
                        .map((entry) => _buildEntryRow(entry))
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],

          // Geçmiş görüşmeler
          _sectionTitle(context, 'Geçmiş Görüşmeler', Icons.chat_outlined),
          const SizedBox(height: 8),
          if (followUpProvider.isLoading && followUpProvider.followUps.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (followUpProvider.followUps.isEmpty)
            _buildInfoMessage(
              icon: Icons.info_outline,
              color: Colors.blue,
              text: 'Henüz takip görüşmesi eklenmemiş.',
            )
          else
            _buildFollowUpsList(context, followUpProvider.followUps),
        ],
      ),
    );
  }

  Widget _buildFollowUpsList(
    BuildContext context,
    List<FollowUpModel> followUps,
  ) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: followUps.length,
      itemBuilder: (context, index) {
        final followUp = followUps[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            onTap: () {
              _showAddFollowUpSheet(
                context,
                customer,
                followUpProvider,
                followUp: followUp,
              );
            },
            leading: _getFollowUpIcon(followUp.type),
            title: Text(
              '${DateFormat('dd.MM.yyyy HH:mm').format(followUp.date.toDate())} - ${followUp.type.name}',
            ),
            subtitle: Text(
              followUp.notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Bu Kaydı Sil',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Kaydı Sil'),
                    content: const Text(
                      'Bu takip kaydını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('İptal'),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                      TextButton(
                        child: const Text(
                          'Sil',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final success =
                      await followUpProvider.deleteFollowUp(followUp.id);
                  if (context.mounted && !success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kayıt silinirken bir hata oluştu.'),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Ortak yardımcılar (top-level — tüm tab widget'larından erişilebilir)
// ============================================================================

Widget _sectionTitle(BuildContext context, String text, IconData icon) {
  return Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    ],
  );
}

Widget _buildInfoMessage({
  required IconData icon,
  required MaterialColor color,
  required String text,
}) {
  return Container(
    decoration: BoxDecoration(
      color: color.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.shade100),
    ),
    padding: const EdgeInsets.all(16.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color.shade700, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color.shade800, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMetricCard(
  BuildContext context, {
  required String title,
  required String value,
  required String subtitle,
}) {
  return Container(
    width: 150,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

Widget _buildChangeChip(String label, double? change, String unit) {
  final isPositive = (change ?? 0) >= 0;
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      ),
      const SizedBox(height: 4),
      Text(
        change != null
            ? '${isPositive ? '+' : ''}${change.toStringAsFixed(1)} $unit'
            : '—',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: change != null && change < 0 ? AppColors.primary : Colors.red,
        ),
      ),
    ],
  );
}

Widget _buildEntryRow(ProgressEntryModel entry) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            DateFormat('dd.MM.yy').format(entry.date),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _entryChip('${entry.weight.toStringAsFixed(1)} kg',
                  Icons.monitor_weight_outlined),
              if (entry.waist != null)
                _entryChip(
                    '${entry.waist!.toStringAsFixed(1)} cm', Icons.straighten),
              if (entry.hip != null)
                _entryChip(
                    '${entry.hip!.toStringAsFixed(1)} cm', Icons.straighten),
              if (entry.chest != null)
                _entryChip(
                    '${entry.chest!.toStringAsFixed(1)} cm', Icons.straighten),
              if (entry.bodyFat != null)
                _entryChip('%${entry.bodyFat!.toStringAsFixed(1)}',
                    Icons.water_drop_outlined),
              if (entry.muscleMass != null)
                _entryChip('${entry.muscleMass!.toStringAsFixed(1)} kg',
                    Icons.fitness_center),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _entryChip(String text, IconData icon) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: Colors.grey.shade400),
      const SizedBox(width: 2),
      Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
    ],
  );
}

double? _calcChange(List<ProgressEntryModel> entries,
    double? Function(ProgressEntryModel) getter) {
  final first = entries.firstWhere((e) => getter(e) != null,
      orElse: () => entries.first);
  final last = entries.lastWhere((e) => getter(e) != null,
      orElse: () => entries.last);
  final firstVal = getter(first);
  final lastVal = getter(last);
  if (firstVal == null || lastVal == null) return null;
  return lastVal - firstVal;
}

Widget _getFollowUpIcon(FollowUpType type) {
  switch (type) {
    case FollowUpType.phoneCall:
      return const Icon(Icons.phone_in_talk_outlined);
    case FollowUpType.whatsappMessage:
      return const Icon(Icons.chat_outlined);
    case FollowUpType.email:
      return const Icon(Icons.alternate_email_outlined);
    case FollowUpType.inPerson:
      return const Icon(Icons.people_alt_outlined);
  }
}

String _formatGoal(String? goal) {
  switch (goal) {
    case 'weight_loss':
      return 'Zayıflama';
    case 'weight_gain':
      return 'Kilo Alma';
    case 'healthy_living':
      return 'Sağlıklı Yaşam';
    case 'skin_care':
      return 'Cilt & Kişisel Bakım';
    default:
      return goal == null || goal.isEmpty ? 'Hedef yok' : goal;
  }
}

String _relativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inDays >= 1) return '${difference.inDays} gün önce';
  if (difference.inHours >= 1) return '${difference.inHours} saat önce';
  if (difference.inMinutes >= 1) return '${difference.inMinutes} dk önce';
  return 'Az önce';
}

void _showAddFollowUpSheet(
  BuildContext context,
  CustomerModel customer,
  FollowUpProvider provider, {
  FollowUpModel? followUp,
  String? scheduledFollowUpId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (builderContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(builderContext).viewInsets.bottom,
        ),
        child: _AddFollowUpSheet(
          customer: customer,
          followUpProvider: provider,
          followUp: followUp,
          scheduledFollowUpId: scheduledFollowUpId,
        ),
      );
    },
  );
}

void _showMotivationMessageSheet(
  BuildContext context,
  String customerUserId,
  String customerName,
) {
  final firestoreService = context.read<FirestoreService>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (builderContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(builderContext).viewInsets.bottom,
        ),
        child: _MotivationMessageSheet(
          customerUserId: customerUserId,
          customerName: customerName,
          firestoreService: firestoreService,
        ),
      );
    },
  );
}

Widget _buildDistributorRequestCard(
    BuildContext context, UserProfileModel profile) {
  return Card(
    elevation: 4,
    shadowColor: AppColors.primary.withValues(alpha: 0.2),
    color: AppColors.primary.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.business_center,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribütörlük Başvurusu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.nightSky,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.name ?? 'Müşteri'} distribütör olmak için başvuruda bulundu.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _approveDistributorRequest(context, profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check),
              label: const Text(
                'Distribütör Yap ve Onayla',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _approveDistributorRequest(
    BuildContext context, UserProfileModel profile) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Başvuruyu Onayla'),
      content: Text(
        '${profile.name ?? 'Müşteri'} isimli müşteriyi distribütör olarak onaylamak istediğinizden emin misiniz? '
        'Bu işlem geri alınamaz.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Onayla'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    final firestoreService = context.read<FirestoreService>();
    final updatedProfile = profile.copyWith(
      role: UserRole.distributor,
      distributorRequestStatus: 'approved',
    );
    await firestoreService.setUserProfile(updatedProfile);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Müşteri başarıyla distribütör olarak onaylandı.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Onaylama sırasında hata oluştu: ${e.toString().replaceFirst('Exception: ', '')}',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ============================================================================
// Modal sheet'ler (değişmedi — eski sürümle aynı)
// ============================================================================

class _AddFollowUpSheet extends StatefulWidget {
  final CustomerModel customer;
  final FollowUpProvider followUpProvider;
  final FollowUpModel? followUp;
  final String? scheduledFollowUpId;

  const _AddFollowUpSheet({
    required this.customer,
    required this.followUpProvider,
    this.followUp,
    this.scheduledFollowUpId,
  });

  @override
  _AddFollowUpSheetState createState() => _AddFollowUpSheetState();
}

class _AddFollowUpSheetState extends State<_AddFollowUpSheet> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.followUp != null;
  bool _isLoading = false;

  FollowUpType _type = FollowUpType.phoneCall;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final followUp = widget.followUp!;
      _type = followUp.type;
      _date = followUp.date.toDate();
      _time = TimeOfDay.fromDateTime(_date);
      _notesController.text = followUp.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    final followUpProvider = widget.followUpProvider;
    final authProvider = context.read<AuthProvider>();
    final finalDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final followUpData = FollowUpModel(
      id: _isEditing ? widget.followUp!.id : '',
      customerId: widget.customer.id,
      consultantId: _isEditing
          ? widget.followUp!.consultantId
          : authProvider.firebaseUser?.uid ?? '',
      date: Timestamp.fromDate(finalDateTime),
      type: _type,
      status: _isEditing ? widget.followUp!.status : FollowUpStatus.completed,
      notes: _notesController.text.trim(),
    );

    try {
      bool success;
      if (_isEditing) {
        success = await followUpProvider.updateFollowUp(followUpData);
      } else {
        success = await followUpProvider.addFollowUp(
          followUpData,
          completedScheduledFollowUpId: widget.scheduledFollowUpId,
        );
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Takip kaydı başarıyla ${_isEditing ? 'güncellendi' : 'eklendi'}!',
            ),
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem sırasında bir hata oluştu.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Takibi Düzenle' : 'Yeni Takip Ekle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Müşteri: ${widget.customer.firstName} ${widget.customer.lastName}',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Görüşme Notları',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 4,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Not alanı zorunludur.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FollowUpType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Görüşme Türü',
                border: OutlineInputBorder(),
              ),
              items: FollowUpType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Kaydet'),
                onPressed: _isLoading ? null : _saveForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotivationMessageSheet extends StatefulWidget {
  final String customerUserId;
  final String customerName;
  final FirestoreService firestoreService;

  const _MotivationMessageSheet({
    required this.customerUserId,
    required this.customerName,
    required this.firestoreService,
  });

  @override
  State<_MotivationMessageSheet> createState() =>
      _MotivationMessageSheetState();
}

class _MotivationMessageSheetState extends State<_MotivationMessageSheet> {
  final _messageController = TextEditingController();
  bool _isLoadingExisting = true;
  bool _isSaving = false;
  bool _hadExisting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingMessage();
  }

  Future<void> _loadExistingMessage() async {
    try {
      final existing = await widget.firestoreService
          .getDistributorMotivationMessage(widget.customerUserId);
      if (!mounted) return;
      setState(() {
        if (existing != null && existing.trim().isNotEmpty) {
          _messageController.text = existing;
          _hadExisting = true;
        }
        _isLoadingExisting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingExisting = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj boş olamaz.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.firestoreService.saveDistributorMotivationMessage(
        widget.customerUserId,
        text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hadExisting
                ? 'Motivasyon mesajı güncellendi.'
                : 'Motivasyon mesajı gönderildi.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydetme hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Günün Motivasyon Mesajı',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Alıcı: ${widget.customerName}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          if (_isLoadingExisting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            TextField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 500,
              autofocus: !_hadExisting,
              decoration: InputDecoration(
                labelText: 'Mesaj',
                hintText: _hadExisting
                    ? 'Bugünkü mesajı düzenle…'
                    : 'Müşterine bugün için kısa bir motivasyon mesajı yaz…',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.message_outlined),
              ),
            ),
            const SizedBox(height: 8),
            if (_hadExisting)
              Text(
                'Bugün zaten bir mesaj göndermişsin. Kaydedersen mevcut mesajın üzerine yazılır.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                    ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_hadExisting ? 'Güncelle' : 'Gönder'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
