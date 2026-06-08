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
import '../../../models/scheduled_follow_up_model.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/user_role.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../program/models/program_editor_args.dart';
import '../../program/screens/create_program_screen.dart';
import '../providers/customer_provider.dart';
import '../providers/follow_up_provider.dart';

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
      child: Consumer<FollowUpProvider>(
        builder: (context, followUpProvider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${currentCustomer.firstName} ${currentCustomer.lastName}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Müşteriyi Düzenle',
                  onPressed: () {
                    context.goNamed(
                      AddEditCustomerScreen.routeName,
                      extra: currentCustomer,
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerHeader(context, currentCustomer),
                  const SizedBox(height: 16),
                  Text(
                    'Sağlık Bilgileri',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildHealthSection(context, currentCustomer),
                  const SizedBox(height: 12),
                  if (currentCustomer.linkedUserId != null &&
                      currentCustomer.linkedUserId!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.goNamed(
                            CreateProgramScreen.routeName,
                            extra: ProgramEditorArgs(
                              targetUserId: currentCustomer.linkedUserId!,
                              targetCustomerName:
                                  '${currentCustomer.firstName} ${currentCustomer.lastName}'.trim(),
                              isDistributorMode: true,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('Bu Müşteri İçin Program Yaz'),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Planlanmış Takipler (Yapılacaklar)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  if (followUpProvider.isLoading &&
                      followUpProvider.pendingScheduledFollowUps.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (!followUpProvider.isLoading &&
                      followUpProvider.pendingScheduledFollowUps.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text('Yaklaşan planlanmış takip görevi yok.'),
                      ),
                    ),
                  if (followUpProvider.pendingScheduledFollowUps.isNotEmpty)
                    _buildScheduledFollowUpsList(
                      context,
                      followUpProvider.pendingScheduledFollowUps,
                      followUpProvider,
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Geçmiş Görüşmeler',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  if (followUpProvider.isLoading &&
                      followUpProvider.followUps.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (!followUpProvider.isLoading &&
                      followUpProvider.followUps.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text('Henüz takip görüşmesi eklenmemiş.'),
                      ),
                    ),
                  if (followUpProvider.followUps.isNotEmpty)
                    _buildFollowUpsList(context, followUpProvider.followUps),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _showAddFollowUpSheet(context, currentCustomer, followUpProvider);
              },
              tooltip: 'Plansız Takip Ekle',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
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

  Widget _buildCustomerHeader(BuildContext context, CustomerModel customer) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 28,
                child: Text(
                  customer.firstName.isNotEmpty ? customer.firstName[0] : '?',
                ),
              ),
              title: Text(
                '${customer.firstName} ${customer.lastName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(customer.phoneNumber),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(customer.email ?? 'E-posta yok')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 8),
                Text(
                  'İlk Temas: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(customer.firstContactDate.toDate())}',
                ),
              ],
            ),
            if (customer.activatedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Aktive Oldu: ${DateFormat('dd MMMM yyyy HH:mm', 'tr_TR').format(customer.activatedAt!.toDate())}',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  customer.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 16,
                  color: customer.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(customer.isActive ? 'Aktif Müşteri' : 'Pasif Müşteri'),
              ],
            ),
            if (customer.notes != null && customer.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Notlar',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(customer.notes!)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSection(BuildContext context, CustomerModel customer) {
    if (customer.linkedUserId == null || customer.linkedUserId!.isEmpty) {
      final firestoreService = context.read<FirestoreService>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoMessage(
            icon: Icons.link_off_outlined,
            color: Colors.orange,
            text:
                'Bu müşteri henüz hesabını aktive etmedi. Sağlık verileri ve günlük takip bilgileri aktivasyondan sonra görünür.',
          ),
          const SizedBox(height: 16),
          FutureBuilder<InviteCodeModel?>(
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
                  text: 'Bu müşteri için oluşturulmuş bir davet kodu bulunamadı.',
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
          ),
        ],
      );
    }

    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<UserProfileModel?>(
      stream: firestoreService.watchUserProfile(customer.linkedUserId!),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = profileSnapshot.data;
        if (profile == null) {
          return _buildInfoMessage(
            icon: Icons.info_outline,
            color: Colors.blue,
            text: 'Bağlı müşteri profili bulunamadı.',
          );
        }

        return FutureBuilder<DistributorCustomerInsights>(
          future: firestoreService.getDistributorCustomerInsights(
            customer.linkedUserId!,
          ),
          builder: (context, insightsSnapshot) {
            if (insightsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final insights = insightsSnapshot.data;
            if (insights == null) {
              return _buildInfoMessage(
                icon: Icons.error_outline,
                color: Colors.red,
                text: 'Müşteri içgörüleri yüklenemedi.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (profile.distributorRequestStatus == 'pending') ...[
                  _buildDistributorRequestCard(context, profile),
                  const SizedBox(height: 12),
                ],
                _buildProfileSummaryCard(context, profile),
                const SizedBox(height: 12),
                _buildInsightsCard(context, profile, insights),
                const SizedBox(height: 12),
                _buildProgressSection(context, profile, insights),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfileSummaryCard(
    BuildContext context,
    UserProfileModel profile,
  ) {
    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDataChip(Icons.person_outline, profile.name ?? 'İsim yok'),
                _buildDataChip(
                  Icons.phone_outlined,
                  profile.phoneNumber ?? 'Telefon yok',
                ),
                _buildDataChip(
                  Icons.straighten,
                  profile.height != null
                      ? '${profile.height!.toStringAsFixed(0)} cm'
                      : 'Boy yok',
                ),
                _buildDataChip(
                  Icons.monitor_weight_outlined,
                  profile.weight != null
                      ? '${profile.weight!.toStringAsFixed(1)} kg'
                      : 'Kilo yok',
                ),
                _buildDataChip(
                  Icons.flag_outlined,
                  _formatGoal(profile.userGoal),
                ),
                _buildDataChip(
                  Icons.cake_outlined,
                  profile.age != null ? '${profile.age} yaş' : 'Yaş yok',
                ),
              ],
            ),
            if ((profile.healthNotes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Sağlık Notu',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(profile.healthNotes!.trim()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    UserProfileModel profile,
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
                const Icon(Icons.trending_down, color: AppColors.primary, size: 20),
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

            if (!hasEntries) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Henüz ölçüm kaydı yok.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ] else ...[
              // Kilo değişim grafiği
              WeightChartWidget(
                entries: entries,
                targetWeight: profile.targetWeight,
                initialWeight: profile.weight,
              ),

              // Toplam değişim
              if (entries.length >= 2) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildChangeChip(
                      'Kilo',
                      insights.totalWeightChange,
                      'kg',
                    ),
                    if (entries.any((e) => e.waist != null))
                      _buildChangeChip(
                        'Bel',
                        _calcChange(entries, (e) => e.waist),
                        'cm',
                      ),
                    if (entries.any((e) => e.hip != null))
                      _buildChangeChip(
                        'Kalça',
                        _calcChange(entries, (e) => e.hip),
                        'cm',
                      ),
                    if (entries.any((e) => e.chest != null))
                      _buildChangeChip(
                        'Göğüs',
                        _calcChange(entries, (e) => e.chest),
                        'cm',
                      ),
                  ],
                ),
              ],

              // Son 5 ölçüm listesi
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'Son Ölçümler',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...entries.reversed.take(5).map((entry) => _buildEntryRow(entry)),
            ],
          ],
        ),
      ),
    );
  }

  double? _calcChange(List<ProgressEntryModel> entries, double? Function(ProgressEntryModel) getter) {
    final first = entries.firstWhere((e) => getter(e) != null, orElse: () => entries.first);
    final last = entries.lastWhere((e) => getter(e) != null, orElse: () => entries.last);
    final firstVal = getter(first);
    final lastVal = getter(last);
    if (firstVal == null || lastVal == null) return null;
    return lastVal - firstVal;
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
                _entryChip('${entry.weight.toStringAsFixed(1)} kg', Icons.monitor_weight_outlined),
                if (entry.waist != null)
                  _entryChip('${entry.waist!.toStringAsFixed(1)} cm', Icons.straighten),
                if (entry.hip != null)
                  _entryChip('${entry.hip!.toStringAsFixed(1)} cm', Icons.straighten),
                if (entry.chest != null)
                  _entryChip('${entry.chest!.toStringAsFixed(1)} cm', Icons.straighten),
                if (entry.bodyFat != null)
                  _entryChip('%${entry.bodyFat!.toStringAsFixed(1)}', Icons.water_drop_outlined),
                if (entry.muscleMass != null)
                  _entryChip('${entry.muscleMass!.toStringAsFixed(1)} kg', Icons.fitness_center),
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

  Widget _buildInsightsCard(
    BuildContext context,
    UserProfileModel profile,
    DistributorCustomerInsights insights,
  ) {
    final latestProgress = insights.latestProgress;
    final waterPercent =
        insights.waterGoalMl == 0 ? 0.0 : insights.todayWaterMl / insights.waterGoalMl;
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
                Expanded(
                  child: Text(
                    'Son 7 Gün Özeti',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: insights.isAtRisk
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    insights.isAtRisk ? 'Riskli' : 'Takipte',
                    style: TextStyle(
                      color: insights.isAtRisk
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                    ),
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
                      : (profile.weight != null
                          ? '${profile.weight!.toStringAsFixed(1)} kg'
                          : 'Yok'),
                  subtitle: latestProgress != null
                      ? DateFormat('dd.MM').format(latestProgress.date)
                      : 'Kayıt yok',
                ),
                _buildMetricCard(
                  context,
                  title: 'Su Takibi',
                  value: '${insights.todayWaterMl}/${insights.waterGoalMl} ml',
                  subtitle: '%${(waterPercent * 100).clamp(0, 100).round()}',
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

  Widget _buildDataChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green.shade800),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
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

  String _formatGoal(String? goal) {
    switch (goal) {
      case 'weight_loss':
        return 'Zayıflama';
      case 'weight_gain':
        return 'Kilo Alma';
      case 'healthy_living':
        return 'Sağlıklı Yaşam';
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

  Widget _buildScheduledFollowUpsList(
    BuildContext context,
    List<ScheduledFollowUpModel> scheduledFollowUps,
    FollowUpProvider provider,
  ) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: scheduledFollowUps.length,
      itemBuilder: (context, index) {
        final scheduledFollowUp = scheduledFollowUps[index];
        final isOverdue = scheduledFollowUp.dueDate.toDate().isBefore(
          DateTime.now(),
        );

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
                  provider,
                  scheduledFollowUpId: scheduledFollowUp.id,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowUpsList(
    BuildContext context,
    List<FollowUpModel> followUps,
  ) {
    final followUpProvider = context.read<FollowUpProvider>();

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
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

  Widget _buildDistributorRequestCard(BuildContext context, UserProfileModel profile) {
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
                const Icon(Icons.business_center, color: AppColors.primary, size: 28),
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

  Future<void> _approveDistributorRequest(BuildContext context, UserProfileModel profile) async {
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

      final updatedProfile = UserProfileModel(
        id: profile.id,
        email: profile.email,
        role: UserRole.distributor,
        name: profile.name,
        distributorLevel: profile.distributorLevel,
        monthlyVPTarget: profile.monthlyVPTarget,
        isOnboarded: profile.isOnboarded,
        age: profile.age,
        phoneNumber: profile.phoneNumber,
        weight: profile.weight,
        height: profile.height,
        targetWeight: profile.targetWeight,
        programStartDate: profile.programStartDate,
        userGoal: profile.userGoal,
        wakeTime: profile.wakeTime,
        lunchTime: profile.lunchTime,
        sleepTime: profile.sleepTime,
        birthDate: profile.birthDate,
        gender: profile.gender,
        healthNotes: profile.healthNotes,
        allergies: profile.allergies,
        medications: profile.medications,
        assignedDistributorId: profile.assignedDistributorId,
        profilePhotoUrl: profile.profilePhotoUrl,
        profilePhotoUpdatedAt: profile.profilePhotoUpdatedAt,
        earnedBadges: profile.earnedBadges,
        waterDailyGoal: profile.waterDailyGoal,
        waterMinLimit: profile.waterMinLimit,
        waterMaxLimit: profile.waterMaxLimit,
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
}

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