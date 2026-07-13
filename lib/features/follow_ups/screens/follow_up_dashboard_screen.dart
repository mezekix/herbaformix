import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/scheduled_follow_up_model.dart';
import '../../../models/customer_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/follow_up_dashboard_provider.dart';
import '../widgets/customer_filter_dropdown.dart';
import '../widgets/follow_up_card.dart';
import '../widgets/follow_up_summary_cards.dart';

/// Müşteri Takipleri ana ekranı.
/// Tüm müşterilerin planlanmış takiplerini merkezi olarak yönetir.
class FollowUpDashboardScreen extends StatefulWidget {
  static const routeName = 'follow-ups';

  const FollowUpDashboardScreen({super.key});

  @override
  State<FollowUpDashboardScreen> createState() => _FollowUpDashboardScreenState();
}

class _FollowUpDashboardScreenState extends State<FollowUpDashboardScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowUpDashboardProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: _buildAppBar(provider),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(provider),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddEditBottomSheet(context, provider),
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.nightSky,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Takip'),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(FollowUpDashboardProvider provider) {
    if (_isSearching) {
      return AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textOnPrimary),
          decoration: const InputDecoration(
            hintText: 'Müşteri veya takip ara...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: provider.setSearchQuery,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _isSearching = false);
            _searchController.clear();
            provider.setSearchQuery('');
          },
        ),
      );
    }

    return AppBar(
      title: const Text('Müşteri Takipleri'),
      actions: [
        if (provider.overdueCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Badge(
              label: Text(provider.overdueCount.toString()),
              backgroundColor: AppColors.error,
              child: IconButton(
                icon: const Icon(Icons.warning_amber_rounded),
                tooltip: '${provider.overdueCount} gecikmiş takip',
                onPressed: () => provider.setFilter(FollowUpFilter.overdue),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
      ],
    );
  }

  Widget _buildBody(FollowUpDashboardProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 12),

        // Özet kartları
        FollowUpSummaryCards(
          provider: provider,
          onFilterTap: (filter) {
            if (provider.activeFilter == filter) {
              provider.setFilter(FollowUpFilter.all);
            } else {
              provider.setFilter(filter);
            }
          },
        ),

        const SizedBox(height: 12),

        // Müşteri filtresi
        CustomerFilterDropdown(
          customers: provider.uniqueCustomers,
          selectedCustomerId: provider.selectedCustomerId,
          onChanged: provider.setSelectedCustomer,
        ),

        const SizedBox(height: 8),

        // Filtre chip'leri
        _buildFilterChips(provider),

        const SizedBox(height: 4),

        // Takip listesi
        Expanded(
          child: provider.filteredFollowUps.isEmpty
              ? _buildEmptyState(provider)
              : _buildFollowUpList(provider),
        ),
      ],
    );
  }

  Widget _buildFilterChips(FollowUpDashboardProvider provider) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: FollowUpFilter.values.map((filter) {
          final isActive = provider.activeFilter == filter;
          final label = switch (filter) {
            FollowUpFilter.all => 'Tümü (${provider.pendingCount})',
            FollowUpFilter.overdue => 'Gecikmiş (${provider.overdueCount})',
            FollowUpFilter.today => 'Bugün (${provider.todayCount})',
            FollowUpFilter.thisWeek => 'Bu Hafta (${provider.thisWeekCount})',
            FollowUpFilter.completed => 'Tamamlanan (${provider.completedCount})',
          };

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isActive,
              onSelected: (_) => provider.setFilter(filter),
              selectedColor: AppColors.primary.withAlpha(30),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(FollowUpDashboardProvider provider) {
    final isFiltered = provider.activeFilter != FollowUpFilter.all ||
        provider.searchQuery.isNotEmpty ||
        provider.selectedCustomerId != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_list_off : Icons.assignment_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'Bu filtreye uygun takip bulunamadı'
                : 'Henüz takip bulunmuyor',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Filtreleri Temizle'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowUpList(FollowUpDashboardProvider provider) {
    final followUps = provider.filteredFollowUps;
    final customerProvider = context.read<CustomerProvider>();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: followUps.length,
      itemBuilder: (context, index) {
        final followUp = followUps[index];
        
        // Müşteri telefonunu bul
        final customer = customerProvider.customers.cast<CustomerModel?>().firstWhere(
          (c) => c != null && (c.id == followUp.customerId || (c.linkedUserId != null && c.linkedUserId == followUp.customerId)),
          orElse: () => null,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FollowUpCard(
            followUp: followUp,
            phoneNumber: customer?.phoneNumber,
            onComplete: () => _completeFollowUp(provider, followUp),
            onSnooze: () => _showSnoozeOptions(context, provider, followUp),
            onEdit: () => _showAddEditBottomSheet(context, provider, followUp: followUp),
            onDelete: () => _deleteFollowUp(provider, followUp),
          ),
        );
      },
    );
  }

  // ── Aksiyonlar ──────────────────────────────────────────────────────────

  Future<void> _completeFollowUp(
    FollowUpDashboardProvider provider,
    ScheduledFollowUpModel followUp,
  ) async {
    final success = await provider.completeFollowUp(followUp.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Takip tamamlandı' : 'Hata oluştu'),
          backgroundColor: success ? AppColors.secondary : AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteFollowUp(
    FollowUpDashboardProvider provider,
    ScheduledFollowUpModel followUp,
  ) async {
    final success = await provider.deleteFollowUp(followUp.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Takip silindi' : 'Hata oluştu'),
          backgroundColor: success ? AppColors.secondary : AppColors.error,
        ),
      );
    }
  }

  Future<void> _showSnoozeOptions(
    BuildContext context,
    FollowUpDashboardProvider provider,
    ScheduledFollowUpModel followUp,
  ) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 9);

    final result = await showModalBottomSheet<DateTime?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.wb_sunny, color: AppColors.accent),
              title: const Text('Yarına Ertele'),
              subtitle: const Text('Yarın sabah 09:00'),
              onTap: () => Navigator.of(ctx).pop(tomorrow),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: AppColors.primary),
              title: const Text('Tarih Seç'),
              onTap: () async {
                Navigator.of(ctx).pop(); // BottomSheet'i kapat
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: followUp.dueDate.toDate().isAfter(now)
                      ? followUp.dueDate.toDate()
                      : now.add(const Duration(days: 1)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  final snoozeDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    9,
                  );
                  await provider.snoozeFollowUp(followUp.id, snoozeDate);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Takip ertelendi'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result != null) {
      final success = await provider.snoozeFollowUp(followUp.id, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Takip ertelendi' : 'Hata oluştu'),
            backgroundColor: success ? AppColors.secondary : AppColors.error,
          ),
        );
      }
    }
  }

  /// Takip ekleme/düzenleme BottomSheet'i gösterir.
  Future<void> _showAddEditBottomSheet(
    BuildContext context,
    FollowUpDashboardProvider provider, {
    ScheduledFollowUpModel? followUp,
  }) async {
    final isEditing = followUp != null;
    final authProvider = context.read<AuthProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final productProvider = context.read<ProductProvider>();
    final userId = authProvider.firebaseUser?.uid ?? '';

    final titleController = TextEditingController(text: followUp?.title ?? '');
    final notesController = TextEditingController(text: followUp?.notes ?? '');
    DateTime selectedDate = followUp?.dueDate.toDate() ?? DateTime.now().add(const Duration(days: 1));
    String? selectedCustomerId = followUp?.customerId;
    String? selectedCustomerFirstName = followUp?.customerFirstName;
    String? selectedCustomerLastName = followUp?.customerLastName;
    
    // Otomatik plan modu için durum değişkenleri
    bool isAutoPlanMode = false;
    String? selectedProductName;

    List<CustomerModel> customers;
    try {
      customers = await _loadSelectableCustomers(customerProvider);
    } catch (_) {
      customers = customerProvider.customers;
    }
    if (!mounted) {
      titleController.dispose();
      notesController.dispose();
      return;
    }
    final products = productProvider.products;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Başlık çubuğu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Takip Düzenle' : 'Yeni Takip Ekle',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mod seçimi (sadece yeni eklerken)
                    if (!isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Tekil Takip')),
                              selected: !isAutoPlanMode,
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    isAutoPlanMode = false;
                                  });
                                }
                              },
                              selectedColor: AppColors.primary.withAlpha(40),
                              labelStyle: TextStyle(
                                color: !isAutoPlanMode ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: !isAutoPlanMode ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Ürüne Göre Plan')),
                              selected: isAutoPlanMode,
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    isAutoPlanMode = true;
                                  });
                                }
                              },
                              selectedColor: AppColors.primary.withAlpha(40),
                              labelStyle: TextStyle(
                                color: isAutoPlanMode ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: isAutoPlanMode ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Müşteri seçimi (sadece yeni eklerken)
                    if (!isEditing) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedCustomerId,
                        decoration: const InputDecoration(
                          labelText: 'Müşteri Seçin',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: customers.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.firstName} ${c.lastName}'.trim()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedCustomerId = value;
                            final customer = customers.firstWhere((c) => c.id == value);
                            selectedCustomerFirstName = customer.firstName;
                            selectedCustomerLastName = customer.lastName;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      // Düzenleme modunda müşteri bilgisini göster
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              followUp.customerFullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Mod tipine göre alanlar
                    if (isAutoPlanMode) ...[
                      // Ürün seçimi
                      DropdownButtonFormField<String>(
                        initialValue: selectedProductName,
                        decoration: const InputDecoration(
                          labelText: 'Ürün Seçin',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: products.map((p) {
                          return DropdownMenuItem(
                            value: p.name,
                            child: Text(p.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedProductName = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Başlangıç Tarihi seçimi
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Plan Başlangıç Tarihi',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${selectedDate.day.toString().padLeft(2, '0')}.'
                            '${selectedDate.month.toString().padLeft(2, '0')}.'
                            '${selectedDate.year}',
                          ),
                        ),
                      ),
                    ] else ...[
                      // Başlık
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Başlık',
                          hintText: 'Örn: Haftalık kontrol',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tarih seçimi
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tarih',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${selectedDate.day.toString().padLeft(2, '0')}.'
                            '${selectedDate.month.toString().padLeft(2, '0')}.'
                            '${selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Notlar
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notlar (opsiyonel)',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Kaydet butonu
                    FilledButton.icon(
                      onPressed: () async {
                        if (!isEditing && selectedCustomerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen bir müşteri seçin')),
                          );
                          return;
                        }

                        bool success;
                        if (isEditing) {
                          final updated = followUp.copyWith(
                            title: titleController.text.trim(),
                            dueDate: Timestamp.fromDate(selectedDate),
                            notes: notesController.text.trim(),
                          );
                          success = await provider.updateFollowUp(updated);
                        } else if (isAutoPlanMode) {
                          if (selectedProductName == null || selectedProductName!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lütfen bir ürün seçin')),
                            );
                            return;
                          }
                          success = await provider.generateFollowUpPlan(
                            customerId: selectedCustomerId!,
                            customerFirstName: selectedCustomerFirstName ?? '',
                            customerLastName: selectedCustomerLastName ?? '',
                            productName: selectedProductName!,
                            startDate: selectedDate,
                          );
                        } else {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Başlık boş bırakılamaz')),
                            );
                            return;
                          }
                          final newFollowUp = ScheduledFollowUpModel(
                            id: '',
                            consultantId: userId,
                            customerId: selectedCustomerId!,
                            customerFirstName: selectedCustomerFirstName ?? '',
                            customerLastName: selectedCustomerLastName ?? '',
                            dueDate: Timestamp.fromDate(selectedDate),
                            title: titleController.text.trim(),
                            isCompleted: false,
                            notes: notesController.text.trim().isNotEmpty
                                ? notesController.text.trim()
                                : null,
                            createdAt: Timestamp.now(),
                            isAutoGenerated: false,
                          );
                          success = await provider.addManualFollowUp(newFollowUp);
                        }

                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? (isEditing
                                      ? 'Takip güncellendi'
                                      : (isAutoPlanMode
                                          ? 'Otomatik takip planı oluşturuldu'
                                          : 'Takip eklendi'))
                                  : 'Hata oluştu'),
                              backgroundColor: success ? AppColors.secondary : AppColors.error,
                            ),
                          );
                        }
                      },
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      label: Text(isEditing ? 'Güncelle' : 'Kaydet'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    notesController.dispose();
  }

  Future<List<CustomerModel>> _loadSelectableCustomers(
    CustomerProvider customerProvider,
  ) async {
    final combinedCustomers = await customerProvider.getCombinedCustomers();
    final resolved = <CustomerModel>[];
    final addedIds = <String>{};

    for (final entry in combinedCustomers) {
      final customer = entry.customerRecord ??
          await customerProvider.getLinkedCustomerFallback(entry);
      if (customer == null || addedIds.contains(customer.id)) continue;
      resolved.add(customer);
      addedIds.add(customer.id);
    }

    if (resolved.isEmpty) {
      for (final customer in customerProvider.customers) {
        if (addedIds.contains(customer.id)) continue;
        resolved.add(customer);
        addedIds.add(customer.id);
      }
    }

    resolved.sort((a, b) {
      final aName = '${a.firstName} ${a.lastName}'.trim();
      final bName = '${b.firstName} ${b.lastName}'.trim();
      return aName.compareTo(bName);
    });
    return resolved;
  }
}
