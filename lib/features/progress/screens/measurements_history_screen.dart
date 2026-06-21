import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/progress_entry_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/progress_provider.dart';

/// Tüm kilo ve vücut ölçümü kayıtlarını tablo halinde gösteren ekran.
/// Kayıtlar düzenlenebilir ve silinebilir.
class MeasurementsHistoryScreen extends StatelessWidget {
  static const String routeName = 'measurements-history';

  const MeasurementsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ölçüm Geçmişi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.nightSky,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.nightSky),
      ),
      body: Consumer<ProgressProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.entries.isEmpty) {
            return _buildEmptyState(context);
          }

          // En yeniden eskiye sırala
          final entries = [...provider.entries]
            ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              // Özet banner
              _buildSummaryBanner(context, provider),
              // Tablo başlığı
              _buildTableHeader(),
              // Kayıtlar
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return _buildEntryRow(context, entries[index], provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Yeni Ölçüm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryBanner(BuildContext context, ProgressProvider provider) {
    final change = provider.totalWeightChange;
    final latest = provider.latestWeight;
    final count = provider.entries.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildBannerStat(
            label: 'Toplam Kayıt',
            value: '$count',
            color: AppColors.nightSky,
          ),
          _buildDivider(),
          _buildBannerStat(
            label: 'Son Kilo',
            value: latest != null ? '${latest.toStringAsFixed(1)} kg' : '—',
            color: AppColors.nightSky,
          ),
          _buildDivider(),
          _buildBannerStat(
            label: 'Toplam Değişim',
            value: change == 0
                ? '0.0 kg'
                : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
            color: change < 0 ? AppColors.primary : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Tarih',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Kilo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Bel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Göbek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Kalça',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Göğüs',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Kol/Bacak',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 48), // işlem butonları için yer
        ],
      ),
    );
  }

  Widget _buildEntryRow(
    BuildContext context,
    ProgressEntryModel entry,
    ProgressProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                DateFormat('d MMM yy', 'tr_TR').format(entry.date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.nightSky,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.weight.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.nightSky,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.waist != null ? entry.waist!.toStringAsFixed(1) : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: entry.waist != null
                    ? AppColors.nightSky
                    : Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.belly != null ? entry.belly!.toStringAsFixed(1) : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: entry.belly != null
                    ? AppColors.nightSky
                    : Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.hip != null ? entry.hip!.toStringAsFixed(1) : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: entry.hip != null
                    ? AppColors.nightSky
                    : Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.chest != null
                  ? entry.chest!.toStringAsFixed(1)
                  : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: entry.chest != null
                    ? AppColors.nightSky
                    : Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.arm != null || entry.thigh != null
                  ? '${entry.arm?.toStringAsFixed(1) ?? "—"}/${entry.thigh?.toStringAsFixed(1) ?? "—"}'
                  : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: entry.arm != null || entry.thigh != null
                    ? AppColors.nightSky
                    : Colors.grey.shade400,
              ),
            ),
          ),
          // İşlem butonları
          SizedBox(
            width: 48,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
              onSelected: (value) {
                if (value == 'edit') {
                  _openEditSheet(context, entry, provider);
                } else if (value == 'delete') {
                  _confirmDelete(context, entry, provider);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Text('Sil',
                          style: TextStyle(color: Colors.red.shade400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_weight_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Henüz ölçüm kaydı yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk ölçümünü ekleyerek başla',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openAddSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Ölçüm Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddEditMeasurementSheet(),
    );
  }

  Future<void> _openEditSheet(
    BuildContext context,
    ProgressEntryModel entry,
    ProgressProvider provider,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditMeasurementSheet(entry: entry),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProgressEntryModel entry,
    ProgressProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kaydı Sil'),
        content: Text(
          '${DateFormat('d MMMM yyyy', 'tr_TR').format(entry.date)} tarihli '
          '${entry.weight.toStringAsFixed(1)} kg kaydını silmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sil',
                style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final userId = context.read<AuthProvider>().firebaseUser?.uid;
      if (userId != null) {
        await context.read<ProgressProvider>().deleteEntry(userId, entry.id);
      }
    }
  }
}

// ── Ekleme / Düzenleme Bottom Sheet ──────────────────────────────────────────

class _AddEditMeasurementSheet extends StatefulWidget {
  final ProgressEntryModel? entry; // null → yeni kayıt, dolu → düzenleme

  const _AddEditMeasurementSheet({this.entry});

  @override
  State<_AddEditMeasurementSheet> createState() =>
      _AddEditMeasurementSheetState();
}

class _AddEditMeasurementSheetState extends State<_AddEditMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightCtrl;
  late final TextEditingController _waistCtrl;
  late final TextEditingController _bellyCtrl;
  late final TextEditingController _hipCtrl;
  late final TextEditingController _chestCtrl;
  late final TextEditingController _armCtrl;
  late final TextEditingController _thighCtrl;
 
  bool _showMeasurements = true;
  bool _isSaving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _weightCtrl = TextEditingController(
        text: e?.weight != null ? e!.weight.toString() : '');
    _waistCtrl = TextEditingController(
        text: e?.waist != null ? e!.waist.toString() : '');
    _bellyCtrl = TextEditingController(
        text: e?.belly != null ? e!.belly.toString() : '');
    _hipCtrl =
        TextEditingController(text: e?.hip != null ? e!.hip.toString() : '');
    _chestCtrl = TextEditingController(
        text: e?.chest != null ? e!.chest.toString() : '');
    _armCtrl =
        TextEditingController(text: e?.arm != null ? e!.arm.toString() : '');
    _thighCtrl = TextEditingController(
        text: e?.thigh != null ? e!.thigh.toString() : '');
    // Düzenleme modunda ölçümler doluysa aç
    if (_isEditing &&
        (widget.entry!.waist != null ||
            widget.entry!.belly != null ||
            widget.entry!.hip != null ||
            widget.entry!.chest != null ||
            widget.entry!.arm != null ||
            widget.entry!.thigh != null)) {
      _showMeasurements = true;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _bellyCtrl.dispose();
    _hipCtrl.dispose();
    _chestCtrl.dispose();
    _armCtrl.dispose();
    _thighCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    final entry = ProgressEntryModel(
      id: _isEditing ? widget.entry!.id : '',
      date: _isEditing ? widget.entry!.date : DateTime.now(),
      weight: double.parse(_weightCtrl.text.replaceAll(',', '.')),
      waist: _waistCtrl.text.isNotEmpty
          ? double.tryParse(_waistCtrl.text.replaceAll(',', '.'))
          : null,
      belly: _bellyCtrl.text.isNotEmpty
          ? double.tryParse(_bellyCtrl.text.replaceAll(',', '.'))
          : null,
      hip: _hipCtrl.text.isNotEmpty
          ? double.tryParse(_hipCtrl.text.replaceAll(',', '.'))
          : null,
      chest: _chestCtrl.text.isNotEmpty
          ? double.tryParse(_chestCtrl.text.replaceAll(',', '.'))
          : null,
      arm: _armCtrl.text.isNotEmpty
          ? double.tryParse(_armCtrl.text.replaceAll(',', '.'))
          : null,
      thigh: _thighCtrl.text.isNotEmpty
          ? double.tryParse(_thighCtrl.text.replaceAll(',', '.'))
          : null,
    );

    try {
      if (_isEditing) {
        await progressProvider.updateEntry(userId, entry);
      } else {
        await progressProvider.addEntry(
            userId, entry, authProvider.userProfile);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt işlemi başarısız. Tekrar dene.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEditing ? 'Ölçümü Düzenle' : 'Yeni Ölçüm Ekle',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nightSky,
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMMM yyyy', 'tr_TR')
                      .format(widget.entry!.date),
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
              const SizedBox(height: 24),
              _buildField(
                controller: _weightCtrl,
                label: 'Kilo (kg)',
                hint: 'Örn: 72.5',
                icon: Icons.monitor_weight_outlined,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () =>
                    setState(() => _showMeasurements = !_showMeasurements),
                child: Row(
                  children: [
                    Icon(
                      _showMeasurements
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vücut Ölçümleri (opsiyonel)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showMeasurements) ...[
                const SizedBox(height: 16),
                _buildField(
                  controller: _chestCtrl,
                  label: 'Göğüs (cm)',
                  hint: 'Örn: 96',
                  icon: Icons.straighten,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _bellyCtrl,
                  label: 'Göbek (cm)',
                  hint: 'Örn: 86',
                  icon: Icons.straighten,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _waistCtrl,
                  label: 'Bel (cm)',
                  hint: 'Örn: 82',
                  icon: Icons.straighten,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _hipCtrl,
                  label: 'Kalça (cm)',
                  hint: 'Örn: 104',
                  icon: Icons.straighten,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _armCtrl,
                  label: 'Kol (cm)',
                  hint: 'Örn: 32',
                  icon: Icons.straighten,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _thighCtrl,
                  label: 'Bacak (cm)',
                  hint: 'Örn: 58',
                  icon: Icons.straighten,
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: isRequired
          ? (v) {
              if (v == null || v.trim().isEmpty) return 'Kilo zorunludur';
              final val = double.tryParse(v.replaceAll(',', '.'));
              if (val == null || val <= 0) return 'Geçerli bir değer girin';
              return null;
            }
          : (v) {
              if (v != null && v.isNotEmpty) {
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Geçerli bir değer girin';
              }
              return null;
            },
    );
  }
}
