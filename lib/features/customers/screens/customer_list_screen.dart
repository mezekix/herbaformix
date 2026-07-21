import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/customer_model.dart';
import '../../../models/user_profile_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import './add_edit_customer_screen.dart';
import './customer_detail_screen.dart';
import 'package:herbaformix/core/app_colors.dart';

class CustomerListScreen extends StatefulWidget {
  static const String routeName = '/customers';
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<CombinedCustomerEntry> _combinedCustomers = [];
  bool _isCombinedLoading = true;
  String? _combinedError;

  // CustomerProvider'ın son bilinen müşteri sayısı — değişince listeyi yenile
  int _lastKnownCustomerCount = -1;
  StreamSubscription<List<UserProfileModel>>? _profileSubscription;
  Timer? _profileReloadDebounce;
  String? _subscribedDistributorId;

  @override
  void initState() {
    super.initState();
    _loadCombinedCustomers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToProfileChanges();
    // CustomerProvider'daki müşteri sayısı değişince (ekle/sil) listeyi yenile
    final count = context.watch<CustomerProvider>().customers.length;
    if (count != _lastKnownCustomerCount && _lastKnownCustomerCount != -1) {
      _lastKnownCustomerCount = count;
      _loadCombinedCustomers();
    } else {
      _lastKnownCustomerCount = count;
    }
  }

  void _subscribeToProfileChanges() {
    final distributorId = context.read<AuthProvider>().firebaseUser?.uid;
    if (distributorId == _subscribedDistributorId) return;

    _profileSubscription?.cancel();
    _subscribedDistributorId = distributorId;
    if (distributorId == null) return;

    _profileSubscription = context
        .read<FirestoreService>()
        .getCustomersByDistributorId(distributorId)
        .skip(1)
        .listen((_) {
          _profileReloadDebounce?.cancel();
          _profileReloadDebounce = Timer(const Duration(milliseconds: 150), () {
            if (mounted) _loadCombinedCustomers(showLoading: false);
          });
        });
  }

  Future<void> _loadCombinedCustomers({bool showLoading = true}) async {
    final customerProvider = context.read<CustomerProvider>();
    try {
      if (!mounted) return;
      setState(() {
        if (showLoading) _isCombinedLoading = true;
        _combinedError = null;
      });
      final result = await customerProvider.getCombinedCustomers();
      if (mounted) {
        setState(() {
          _combinedCustomers = result;
          _isCombinedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _combinedError = e.toString();
          _isCombinedLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _profileReloadDebounce?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // isLoading durumu için izle — didChangeDependencies zaten count değişimini yakalıyor
    final customerProvider = context.watch<CustomerProvider>();
    final inviteCodeCustomers = _combinedCustomers
        .where((c) => c.connectionType == 'davet_kodu')
        .toList();
    final manualCustomers = _combinedCustomers
        .where((c) => c.connectionType == 'manuel')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşterilerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _loadCombinedCustomers,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Yeni Müşteri Ekle',
            onPressed: () => context.goNamed(AddEditCustomerScreen.routeName),
          ),
        ],
      ),
      body: customerProvider.isLoading || _isCombinedLoading
          ? const Center(child: CircularProgressIndicator())
          : _combinedError != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Müşteri listesi yüklenirken hata oluştu:\n$_combinedError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                    onPressed: _loadCombinedCustomers,
                  ),
                ],
              ),
            )
          : inviteCodeCustomers.isEmpty && manualCustomers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Henüz müşteriniz bulunmuyor.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('İlk Müşterinizi Ekleyin'),
                    onPressed: () =>
                        context.goNamed(AddEditCustomerScreen.routeName),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                _SectionHeader(
                  title: 'Davet Koduyla Bağlı Müşteriler',
                  count: inviteCodeCustomers.length,
                ),
                if (inviteCodeCustomers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Davet koduyla bağlı müşteri bulunmuyor.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...inviteCodeCustomers.map(
                    (entry) => _CombinedCustomerCard(
                      entry: entry,
                      onDelete: (entry) async {
                        final success = await customerProvider
                            .deleteCombinedCustomer(entry);
                        if (success) {
                          _loadCombinedCustomers();
                        }
                      },
                    ),
                  ),
                const Divider(height: 24, thickness: 1),
                _SectionHeader(
                  title: 'Manuel Eklenen Müşteriler',
                  count: manualCustomers.length,
                ),
                if (manualCustomers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Manuel eklenen müşteri bulunmuyor.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...manualCustomers.map(
                    (entry) => _ManualCustomerCard(
                      entry: entry,
                      onDelete: (customer) async {
                        final success = await customerProvider.deleteCustomer(
                          customer.id,
                        );
                        if (success) {
                          _loadCombinedCustomers();
                        }
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CombinedCustomerCard extends StatelessWidget {
  final CombinedCustomerEntry entry;
  final Future<void> Function(CombinedCustomerEntry entry) onDelete;

  const _CombinedCustomerCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final canOpenDetails =
        entry.customerRecord != null || entry.isLinkedCustomer;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
          ),
        ),
        title: Text(entry.name.isNotEmpty ? entry.name : 'İsimsiz Müşteri'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.phoneNumber.isNotEmpty
                  ? entry.phoneNumber
                  : 'İletişim bilgisi yok',
            ),
            const SizedBox(height: 4),
            _ConnectionBadge(connectionType: entry.connectionType),
            if (entry.distributorRequestStatus == 'pending') ...[
              const SizedBox(height: 4),
              const _DistributorRequestBadge(),
            ],
            if (entry.isDistributor) ...[
              const SizedBox(height: 4),
              const _DistributorRoleBadge(),
            ],
            if (entry.isRecentlyActivated) ...[
              const SizedBox(height: 4),
              const _NewActivationBadge(),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Müşteriyi Sil / Bağlantıyı Kes',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Müşteriyi Sil'),
                    content: Text(
                      '"${entry.name}" adlı müşteriyi silmek ve distribütör bağlantısını kesmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
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
                if (confirmed == true) {
                  await onDelete(entry);
                }
              },
            ),
            if (canOpenDetails) const Icon(Icons.chevron_right),
          ],
        ),
        onTap: canOpenDetails
            ? () async {
                if (entry.customerRecord != null) {
                  context.goNamed(
                    CustomerDetailScreen.routeName,
                    extra: entry.customerRecord,
                  );
                  return;
                }

                final customerProvider = context.read<CustomerProvider>();
                final linkedCustomer = await customerProvider
                    .getLinkedCustomerFallback(entry);

                if (!context.mounted) return;

                if (linkedCustomer != null) {
                  context.goNamed(
                    CustomerDetailScreen.routeName,
                    extra: linkedCustomer,
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Müşteri detay kaydı bulunamadı. Lütfen sayfayı yenileyin.',
                    ),
                  ),
                );
              }
            : () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu müşteri henüz detay ekranına hazır değil.'),
                ),
              ),
      ),
    );
  }
}

class _ManualCustomerCard extends StatelessWidget {
  final CombinedCustomerEntry entry;
  final Future<void> Function(CustomerModel customer) onDelete;

  const _ManualCustomerCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final customer = entry.customerRecord!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            customer.firstName.isNotEmpty
                ? customer.firstName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text('${customer.firstName} ${customer.lastName}'.trim()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              customer.phoneNumber.isNotEmpty
                  ? customer.phoneNumber
                  : 'İletişim bilgisi yok',
            ),
            const SizedBox(height: 2),
            Text(
              'İlk Temas: ${DateFormat('dd.MM.yyyy').format(customer.firstContactDate.toDate())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            const _ConnectionBadge(connectionType: 'manuel'),
            if (entry.isRecentlyActivated) ...[
              const SizedBox(height: 4),
              const _NewActivationBadge(),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Düzenle',
              onPressed: () {
                context.goNamed(
                  AddEditCustomerScreen.routeName,
                  extra: customer,
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Sil',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Müşteriyi Sil'),
                    content: Text(
                      '"${customer.firstName} ${customer.lastName}" adlı müşteriyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
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
                if (confirmed == true) {
                  await onDelete(customer);
                }
              },
            ),
          ],
        ),
        onTap: () {
          context.goNamed(CustomerDetailScreen.routeName, extra: customer);
        },
      ),
    );
  }
}

class _NewActivationBadge extends StatelessWidget {
  const _NewActivationBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Yeni Aktive Oldu',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.orange.shade900,
        ),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final String connectionType;

  const _ConnectionBadge({required this.connectionType});

  @override
  Widget build(BuildContext context) {
    final isInvite = connectionType == 'davet_kodu';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isInvite ? Colors.green.shade100 : AppColors.backgroundMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isInvite ? 'Davet Kodu' : 'Manuel',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isInvite ? Colors.green.shade800 : AppColors.grey700,
        ),
      ),
    );
  }
}

class _DistributorRequestBadge extends StatelessWidget {
  const _DistributorRequestBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          'Distribütörlük başvurusu bekliyor',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DistributorRoleBadge extends StatelessWidget {
  const _DistributorRoleBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          'Distribütör',
          style: TextStyle(
            color: Colors.green.shade800,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
