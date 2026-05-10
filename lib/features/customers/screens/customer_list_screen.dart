import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/customer_provider.dart';
import './add_edit_customer_screen.dart';
import './customer_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCombinedCustomers();
  }

  Future<void> _loadCombinedCustomers() async {
    final customerProvider = context.read<CustomerProvider>();
    try {
      setState(() {
        _isCombinedLoading = true;
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
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final manualCustomers = customerProvider.customers;
    final inviteCodeCustomers = _combinedCustomers
        .where((c) => c.connectionType == 'davet_kodu')
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
            onPressed: () {
              context.goNamed(AddEditCustomerScreen.routeName);
            },
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
                    onPressed: () {
                      context.goNamed(AddEditCustomerScreen.routeName);
                    },
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                // --- Davet Koduyla Bağlı Müşteriler Bölümü ---
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
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...inviteCodeCustomers.map(
                    (entry) => _CombinedCustomerCard(entry: entry),
                  ),

                const Divider(height: 24, thickness: 1),

                // --- Manuel Eklenen Müşteriler Bölümü ---
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
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...manualCustomers.map(
                    (customer) => Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 5.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Text(
                            customer.firstName.isNotEmpty
                                ? customer.firstName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(
                          '${customer.firstName} ${customer.lastName}'.trim(),
                        ),
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
                            _ConnectionBadge(connectionType: 'manuel'),
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
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                      ),
                                      TextButton(
                                        child: const Text(
                                          'Sil',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await customerProvider.deleteCustomer(
                                    customer.id,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          context.goNamed(
                            CustomerDetailScreen.routeName,
                            extra: customer,
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

/// Bölüm başlığı widget'ı
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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

/// Davet koduyla bağlı müşteri kartı
class _CombinedCustomerCard extends StatelessWidget {
  final CombinedCustomerEntry entry;

  const _CombinedCustomerCard({required this.entry});

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}

/// Bağlanma yöntemi badge'i
class _ConnectionBadge extends StatelessWidget {
  final String connectionType;

  const _ConnectionBadge({required this.connectionType});

  @override
  Widget build(BuildContext context) {
    final isInvite = connectionType == 'davet_kodu';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isInvite ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isInvite ? 'Davet Kodu' : 'Manuel',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isInvite ? Colors.green.shade800 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
