import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:herbaformix/features/customers/screens/add_edit_customer_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/customer_model.dart';
import '../../../models/follow_up_model.dart';
import '../../../models/scheduled_follow_up_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/follow_up_provider.dart';

/// Bir müşterinin detay bilgilerini ve takip geçmişini gösteren ekran.
/// Bu ekran, kendi state'ini yönetmek ve veri sağlamak için
/// bir `ChangeNotifierProvider` ile sarmalanır.
class CustomerDetailScreen extends StatelessWidget {
  /// Rota adı, go_router tarafından kullanılır.
  static const String routeName = 'customer-detail';

  /// Görüntülenecek olan müşteri nesnesi.
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => FollowUpProvider(
        authProvider: ctx.read<AuthProvider>(),
        firestoreService: ctx.read<FirestoreService>(),
        customerId: customer.id,
      ),
      child: Consumer<FollowUpProvider>(
        builder: (context, followUpProvider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${customer.firstName} ${customer.lastName}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Müşteriyi Düzenle',
                  onPressed: () {
                    // Müşteri düzenleme sayfasına yönlendirme.
                    // Müşteri nesnesini `extra` parametresi ile gönderiyoruz.
                    context.goNamed(
                      AddEditCustomerScreen.routeName,
                      extra: customer,
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
                  _buildCustomerHeader(context),
                  const SizedBox(height: 16),

                  // --- SAĞLIK BİLGİLERİ BÖLÜMÜ ---
                  Text(
                    'Sağlık Bilgileri',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildHealthInfoCard(context),
                  const SizedBox(height: 24),

                  // --- YENİ BÖLÜM: PLANLANMIŞ TAKİPLER ---
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

                  // --- MEVCUT BÖLÜM: GEÇMİŞ GÖRÜŞMELER ---
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
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                // `completedScheduledFollowUpId` olmadan çağırıyoruz.
                _showAddFollowUpSheet(context, customer, followUpProvider);
              },
              label: const Text('Plansız Takip Ekle'),
              icon: const Icon(Icons.add_comment_outlined),
            ),
          );
        },
      ),
    );
  }

  /// Provider ve context'i parametre olarak alacak şekilde güncellendi.
  void _showAddFollowUpSheet(
    BuildContext context,
    CustomerModel customer,
    FollowUpProvider provider, {
    FollowUpModel? followUp,
    String? scheduledFollowUpId, // Planlanmış görevin ID'si
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
            scheduledFollowUpId: scheduledFollowUpId, // ID'yi forma iletiyoruz.
          ),
        );
      },
    );
  }

  /// Müşterinin temel bilgilerini gösteren bir kart widget'ı oluşturur.
  Widget _buildCustomerHeader(BuildContext context) {
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
            // Müşterinin diğer bilgilerini gösteren satırlar.
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
            // Notlar alanı — yalnızca dolu ise göster
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
                  Expanded(
                    child: Text(customer.notes!),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Sağlık Bilgileri" bilgi kartını oluşturur.
  Widget _buildHealthInfoCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu müşteri uygulamaya kayıtlıysa sağlık bilgileri profilinde görünür.',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Planlanmış takip görevlerini listeleyen bir widget oluşturur.
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
                // Görüşme ekleme formunu, bu görevin ID'si ile birlikte aç.
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

  /// Takip görüşmelerini listeleyen bir widget oluşturur.
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
              // Düzenleme için formu aç
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
                // Silme onayı için bir dialog göster.
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

                // Eğer kullanıcı "Sil" butonuna bastıysa...
                if (confirmed == true && context.mounted) {
                  final success = await followUpProvider.deleteFollowUp(
                    followUp.id,
                  );
                  if (context.mounted && !success) {
                    // Başarısız olursa kullanıcıya bilgi ver.
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

  /// Takip türüne göre bir ikon döndürür.
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
}

/// Form widget'ı artık opsiyonel bir FollowUpModel alıyor.
class _AddFollowUpSheet extends StatefulWidget {
  final CustomerModel customer;
  final FollowUpProvider followUpProvider;
  final FollowUpModel? followUp; // Düzenleme modu için
  final String? scheduledFollowUpId; // Tamamlanan görev ID'si için

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
  bool get _isEditing => widget.followUp != null; // Düzenleme modunda mıyız?
  bool _isLoading = false;

  // Form alanları için state değişkenleri
  FollowUpType _type = FollowUpType.phoneCall;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Eğer düzenleme modundaysak, form alanlarını gelen veriyle doldur.
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

  /// Formu kaydeden metot
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

    // Yeni veya güncellenmiş modeli oluştur.
    final followUpData = FollowUpModel(
      id: _isEditing
          ? widget.followUp!.id
          : '', // Düzenlemede mevcut ID'yi koru.
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
        // Düzenleme modundaysak güncelle.
        success = await followUpProvider.updateFollowUp(followUpData);
      } else {
        // Ekleme modundaysak ekle.
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
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
              _isEditing
                  ? 'Takibi Düzenle'
                  : 'Yeni Takip Ekle', // Duruma göre başlığı değiştir.
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
